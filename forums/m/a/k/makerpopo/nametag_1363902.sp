//=========================================================
//		Preprocessor
//=========================================================

#pragma semicolon 1

//=========================================================
//		Includes
//=========================================================

#include <sourcemod>
#include <colors>

#define AUTOLOAD_EXTENSIONS
#define REQUIRE_EXTENSIONS
#include <steamtools>

//=========================================================
//		Constants
//=========================================================

// Plugin version
#define PL_VERSION "1.51"

// Escape symbols
#define CHAT_SYMBOL '@'
#define TRADE_SYMBOL '#'
#define TRIGGER_SYMBOL1 '!'
#define TRIGGER_SYMBOL2 '/'

// Nametag settings
#define MAX_TAGS 256
#define MAX_LENGTH 32

// Et cetera
#define CHAR_NULL "\0"

//=========================================================
//		Variables
//=========================================================

// Convars
new Handle:cvar_admin = INVALID_HANDLE;
new Handle:cvar_admin_immunity = INVALID_HANDLE;
new Handle:cvar_enabled = INVALID_HANDLE;
new Handle:cvar_chatmode = INVALID_HANDLE;

// Default Configs
new bool:cfg_admin = false;
new bool:cfg_admin_immunity = true;
new bool:cfg_enabled = true;
new bool:cfg_chatmode = true;

// SQL connect setting
new Handle:m_database = INVALID_HANDLE;
new bool:isSQLite = false;

// Nametag
new kv_tag_count;
new String:kv_tag_name[MAX_TAGS][MAX_LENGTH];
new String:kv_tag_achievement[MAX_TAGS][256];
new String:kv_tag_nametag[MAX_TAGS][MAX_LENGTH];
new String:kv_tag_description[MAX_TAGS][256];

// Nametag per each clients
new String:client_tag[MAXPLAYERS+1][MAX_LENGTH];
new bool:client_achieved[MAXPLAYERS+1][MAX_TAGS];
new bool:havestat[MAXPLAYERS+1];

// Menu
new Handle:menu_tag = INVALID_HANDLE;

new bool:connecting[MAXPLAYERS+1];

//=========================================================
//		Plugin information
//=========================================================

public Plugin:myinfo = 
{
	name = "Nametag",
	author = "Makerpopo",
	description = "Nametag",
	version = PL_VERSION,
	url = CHAR_NULL
};

//=========================================================
//		OnPluginStart()
//=========================================================

public OnPluginStart()
{
	// Translations
	LoadTranslations("nametag.phrases");
	LoadTranslations("common.phrases");
	
	// Create Convars
	CreateConVar("sm_nametag_version", PL_VERSION, "Nametag Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvar_admin = CreateConVar("sm_nametag_admin", "0", "Use nametag for admins only", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_admin_immunity = CreateConVar("sm_nametag_admin_immunity", "1", "If 1, admins are not effected by sm_settag", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_enabled = CreateConVar("sm_nametag_enable", "1", "Enable / Disable", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_chatmode = CreateConVar("sm_nametag_chatmode", "1", "If 1, any clients who have data on database can use nametag", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	// Add commands
	AddCommandListener(Command_SayTeam, "say_team");
	AddCommandListener(Command_Say, "say");
	
	RegConsoleCmd("sm_nametag",Command_TagMenu);
	RegConsoleCmd("sm_settag", Command_SetTag);
	RegConsoleCmd("sm_cleartag", Command_ClearTag);
	
	// Hook cvars
	HookConVarChange(cvar_admin, OnCvarChanged);
	HookConVarChange(cvar_admin_immunity, OnCvarChanged);
	HookConVarChange(cvar_enabled, OnCvarChanged);
	HookConVarChange(cvar_chatmode, OnCvarChanged);
	
	// Hook events
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	HookEvent("player_connect", Event_PlayerConnect);
	HookEvent("achievement_earned", Event_AchievementEarned);

	// Auto config
	AutoExecConfig(true, "nametag");
	
	// Connect to SQL
	decl String:error[255];
	if (SQL_CheckConfig("nametag"))
	{
		m_database = SQL_Connect("nametag", true, error, sizeof(error));
	}
	else
	{
		m_database= SQLite_UseDatabase("nametag", error, sizeof(error));
		isSQLite = true;
	}
	
	if(m_database != INVALID_HANDLE)
	{
		SQL_FastQuery(m_database, "SET NAMES UTF8");
		
		if (!isSQLite)
		{
			SQL_FastQuery(m_database, "CREATE TABLE IF NOT EXISTS `nametag` (`tag` varchar(32) NOT NULL DEFAULT '', `name` varchar(64) NOT NULL, `steam_id` varchar(25) NOT NULL DEFAULT '0', UNIQUE (`steam_id`)) ENGINE=MyISAM DEFAULT CHARSET=utf8;");
		}
		else
		{
			SQL_FastQuery(m_database, "CREATE TABLE IF NOT EXISTS `nametag` (`tag` varchar(32), `name` varchar(64), `steam_id` varchar(25) PRIMARY KEY)");
		}
	} 
	else 
	{
		PrintToServer("Connection Failed for nametag: %s", error);
	}
}

//=========================================================
//		OnCvarChanged();
//=========================================================

public OnCvarChanged(Handle:convar, const String:oldvalue[], const String:newvalue[]) {
	if (convar == cvar_admin) { cfg_admin = GetConVarBool(cvar_admin); }
	else if (convar == cvar_admin_immunity) { cfg_admin_immunity = GetConVarBool(cvar_admin_immunity); }
	else if (convar == cvar_chatmode) { cfg_chatmode = GetConVarBool(cvar_chatmode); }
	else if (convar == cvar_enabled)
	{
		cfg_enabled = GetConVarBool(cvar_enabled);
		
		if (cfg_enabled)
		{
			AddCommandListener(Command_SayTeam, "say_team");
			AddCommandListener(Command_Say, "say");
		}
		else
		{
			RemoveCommandListener(Command_SayTeam, "say_team");
			RemoveCommandListener(Command_Say, "say");
		}
	}
}

//=========================================================
//		OnMapStart();
//=========================================================

public OnMapStart() {
	ParseTags();
	menu_tag = BuildTagMenu();
	
	for (new i = 1; i <= MAXPLAYERS+1; i++)
	{
		havestat[i] = false;
	}
}

public OnMapEnd()
{
	if (menu_tag != INVALID_HANDLE)
	{
		CloseHandle(menu_tag);
		menu_tag = INVALID_HANDLE;
	}
}

//=========================================================
//		Action:Command_Say()
//=========================================================

public Action:Command_Say(client, const String:command[], args)
{
	// Check if client is valid
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		new flags = GetUserFlagBits(client);
		if (!cfg_admin || cfg_chatmode || (flags & ADMFLAG_CHAT) || (flags & ADMFLAG_ROOT))
		{
			decl String:message[1024];
			GetCmdArgString(message, sizeof(message));
			if (!(StrEqual(client_tag[client], CHAR_NULL)) && !((message[1] == CHAT_SYMBOL) || (message[1] == TRADE_SYMBOL) || (message[1] == CHAT_SYMBOL) || (message[1] == TRIGGER_SYMBOL1) || (message[1] == TRIGGER_SYMBOL2)))
			{		
				SendMessage(client, message, false);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

//=========================================================
//		Action:Command_SayTeam()
//=========================================================

public Action:Command_SayTeam(client, const String:command[], args)
{	
	// Check if client is valid
	if (IsClientInGame(client) && !IsFakeClient(client))
	{
		new flags = GetUserFlagBits(client);
		if (!cfg_admin || cfg_chatmode || (flags & ADMFLAG_CHAT) || (flags & ADMFLAG_ROOT))
		{	
			decl String:message[1024];
			GetCmdArgString(message, sizeof(message));
			
			if (!(StrEqual(client_tag[client], CHAR_NULL)) && !((message[1] == CHAT_SYMBOL) || (message[1] == TRADE_SYMBOL) || (message[1] == CHAT_SYMBOL) || (message[1] == TRIGGER_SYMBOL1) || (message[1] == TRIGGER_SYMBOL2)))
			{		
				SendMessage(client, message, true);
				return Plugin_Handled;
			}
		}
	}
	return Plugin_Continue;
}

//=========================================================
//		Action:Command_TagMenu()
//=========================================================

public Action:Command_TagMenu(client, args)
{
	if (cfg_enabled)
	{		
		new flags = GetUserFlagBits(client);
		if (!cfg_admin || (flags & ADMFLAG_CHAT) || (flags & ADMFLAG_ROOT))
		{
			DisplayMenu(menu_tag, client, MENU_TIME_FOREVER);
		}
		else
		{
			ReplyToCommand(client, "%t", "NoAdmin");	
		}
	}
	else
	{
		ReplyToCommand(client, "%t", "Disabled");
	}
	return Plugin_Handled;
}

//=========================================================
//		Menu_TagManager()
//=========================================================

public Menu_TagManager(Handle:menu, MenuAction:action, client, item)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			if (client_achieved[client][item])
			{
				client_tag[client] = kv_tag_nametag[item];
				CPrintToChatEx(client, client, "%t", "Tag_Set", kv_tag_nametag[item]);
			
				SetNameTag(client, client_tag[client]);
			}
			else
			{
				CPrintToChat(client, "%t", "Menu_NotAchieved", kv_tag_description[item]);
			}
		}
	}
}

//=========================================================
//		Handle:BuildTagMenu()
//=========================================================

Handle:BuildTagMenu()
{
	new Handle:p_menu = CreateMenu(Menu_TagManager);
	
	// Getting achievements
	for (new i = 0; i < kv_tag_count; i++)
	{
		AddMenuItem(p_menu, kv_tag_name[i], kv_tag_name[i]);
	}
	
	SetMenuTitle(p_menu, "%t", "Menu_Select");
	return p_menu;
}

//=========================================================
//		Action:Command_ClearTag()
//=========================================================

public Action:Command_ClearTag(client, args)
{
	if (cfg_enabled)
	{
		new flags = GetUserFlagBits(client);
		if (!cfg_admin || (flags & ADMFLAG_CHAT) || (flags & ADMFLAG_ROOT))
		{			
			client_tag[client] = CHAR_NULL;
			PrintToChat(client, "%t", "Tag_SettoDefault");
			
			SetNameTag(client, client_tag[client]);
		}
		else
		{
			ReplyToCommand(client, "%t", "NoAdmin");	
		}
	}
	else
	{
		ReplyToCommand(client, "%t", "Disabled");
	}
	return Plugin_Handled;
}

//=========================================================
//		Action:Command_SetTag()
//=========================================================

public Action:Command_SetTag(client, args)
{
	if (cfg_enabled)
	{
		new flags = GetUserFlagBits(client);
		if ((flags & ADMFLAG_CHAT) || (flags & ADMFLAG_ROOT))
		{
			if (IsClientInGame(client) && !IsFakeClient(client) && m_databaseIntact())
			{
				decl String:arguments[256], String:target[MAX_NAME_LENGTH];
				GetCmdArgString(arguments, sizeof(arguments));
				
				new len = BreakString(arguments, target, sizeof(target));
				
				if (len == -1)
				{
					len = 0;
					arguments[0] = '\0';
				}
				
				decl String:tag_client[32];
				Format(tag_client, sizeof(tag_client), arguments[len]);
					
				decl String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
				if ((target_count = ProcessTargetString(target, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) > 0)
				{
					if (tag_client[0] == '\0')
					{
						for (new i = 0; i < target_count; i++)
						{
							new target_list_int = target_list[i];
							if (target_list_int != client)
							{
								new target_flags = GetUserFlagBits(target_list_int);
								if (!(cfg_admin_immunity && (target_flags & ADMFLAG_CHAT)))
								{
									client_tag[target_list_int] = CHAR_NULL;
									PrintToChat(target_list_int, "%t", "Tag_SettoDefaultbyAdmin", target_name);
									
									SetNameTag(target_list_int, client_tag[target_list_int]);
								}
								PrintToChat(client, "%t", "Tag_SettoDefault_Admin", target_name);
							}
							else
							{
								client_tag[client] = CHAR_NULL;
								PrintToChat(client, "%t", "Tag_SettoDefault");
								
								SetNameTag(client, client_tag[client]);
							}
						}
					}
					else
					{
						for (new i = 0; i < target_count; i++)
						{
							new target_list_int = target_list[i];
							if (target_list_int != client)
							{
								new target_flags = GetUserFlagBits(target_list_int);
								if (!(cfg_admin_immunity && (target_flags & ADMFLAG_CHAT)))
								{
									client_tag[target_list_int] = tag_client;
									CPrintToChat(target_list_int, "%t", "Tag_SetbyAdmin", target_name, tag_client);
									
									SetNameTag(target_list_int, client_tag[target_list_int]);
								}
								CPrintToChat(client, "%t", "Tag_Set_Admin", target_name, tag_client);
							}
							else
							{
								client_tag[client] = tag_client;
								CPrintToChatEx(client, client, "%t", "Tag_Set", tag_client);
								
								SetNameTag(client, client_tag[client]);
							}
						}
					}
				}
				else
				{
					ReplyToTargetError(client, target_count);
				}
			}
		}
		else
		{
			ReplyToCommand(client, "%t", "NoAdmin");	
		}
	}
	else
	{
		ReplyToCommand(client, "%t", "Disabled");
	}
	return Plugin_Handled;
}

//=========================================================
//		OnClientPostAdminCheck()
//=========================================================

public OnClientPostAdminCheck(client)
{
	if (!IsFakeClient(client))
	{
		// SQL query sending part
		decl String:client_auth_call[32], String:query[1024];

		GetClientAuthString(client, client_auth_call, sizeof(client_auth_call));
		
		client_tag[client] = CHAR_NULL;
		
		Format(query, sizeof(query), "SELECT * FROM `nametag` WHERE `steam_id`='%s'",client_auth_call);
		SQL_TQuery(m_database, sql_tagQuery, query, client);
		
		if (connecting[client])
		{
			GetStat(client);
			connecting[client] = false;
		}
	}
}

//=========================================================
//		Steam_StatsReceived()
//=========================================================

public Steam_StatsReceived(client)
{
	// Getting achievements
	for (new i = 0; i < kv_tag_count; i++)
	{
		client_achieved[client][i] = client_achieved[client][i] || Steam_IsAchieved(client, kv_tag_achievement[i]);
		if (StrEqual(kv_tag_achievement[i], CHAR_NULL)) {
			client_achieved[client][i] = true;
		}
	}
	havestat[client] = true;
	return;
}

//=========================================================
//		Event_AchievementEarned()
//=========================================================

public Event_AchievementEarned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	Steam_RequestStats(client);
}

//=========================================================
//		OnClientDisconnect()
//=========================================================

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	for (new i = 0; i < kv_tag_count; i++)
	{
		client_achieved[client][i] = false;
	}
	havestat[client] = false;
}

//=========================================================
//		OnClientConnect()
//=========================================================

public Event_PlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	connecting[client] = true;
}

//=========================================================
//		GetStat()
//=========================================================

public GetStat(client)
{
	if (!havestat[client])
	{
		Steam_RequestStats(client);
	}
}

//=========================================================
//		sql_tagQuery()
//=========================================================

public sql_tagQuery(Handle:owner, Handle:result, const String:error[], any:client)
{
	if(result != INVALID_HANDLE)
	{
		if (SQL_FetchRow(result))
		{
			SQL_FetchString(result, 0, client_tag[client], 32);
		}
	}
	else
	{
		LogToGame("[Nametag] QUERY FAILED: %s", error);
	}
}

//=========================================================
//		m_databaseIntact()
//=========================================================

public m_databaseIntact()
{
	if (m_database != INVALID_HANDLE)
	{
		return true;
	} 
	else 
	{
		return false;
	}	
}

//=========================================================
//		sql_ErrorOnly()
//=========================================================

public sql_ErrorOnly(Handle:owner, Handle:result, const String:error[], any:client)
{
	if (result == INVALID_HANDLE)
	{
		LogError("[Nametag] SQL ERROR (error: %s)", error);
		PrintToChatAll("* SQL ERROR (error: %s)", error);
	}
}

//=========================================================
//		SendMessage()
//=========================================================

SendMessage(client, String:h_strMessage[1024], bool:teamchat)
{
	decl String:name[MAX_NAME_LENGTH], String:chatMsg[1280];
	
	GetClientName(client, name, sizeof(name));
	
	CRemoveTags(h_strMessage, sizeof(h_strMessage));
	StripQuotes(h_strMessage);

	Format(chatMsg, sizeof(chatMsg), "{default}%s {teamcolor}%s {default}: %s", client_tag[client], name, h_strMessage);

	if (teamchat)
	{
		new team = GetClientTeam(client);

		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == team)
			{
				if (GetClientTeam(client) == 1)
				{
					CPrintToChatEx(i, client, "%t %s", "Spec_Team", chatMsg);
				}
				else if (IsPlayerAlive(client))
				{
					CPrintToChatEx(i, client, "%t %s", "Team", chatMsg);
				}
				else
				{
					CPrintToChatEx(i, client, "%t%t %s", "Dead", "Team", chatMsg);
				}
			}
		}
	}
	else
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			{
				if (GetClientTeam(client) == 1)
				{
					CPrintToChatEx(i, client, "%t %s", "Spec", chatMsg);
				}
				else if (IsPlayerAlive(client))
				{
					CPrintToChatEx(i, client, "%s", chatMsg);
				}
				else
				{
					CPrintToChatEx(i, client, "%t %s", "Dead", chatMsg);
				}
			}
		}
	}
}

//=========================================================
//		SetNameTag()
//=========================================================

SetNameTag(client, String:tag_client[32])
{
	decl String:client_name[MAX_NAME_LENGTH], String:client_auth[32], String:client_tag_esc[64], String:client_name_esc[128], String:client_auth_esc[128], String:query[1024];
	
	GetClientName(client, client_name, sizeof(client_name));
	GetClientAuthString(client, client_auth, sizeof(client_auth));
	
	SQL_EscapeString(m_database, tag_client, client_tag_esc, sizeof(client_tag_esc));
	SQL_EscapeString(m_database, client_name, client_name_esc, sizeof(client_name_esc));
	SQL_EscapeString(m_database, client_auth, client_auth_esc, sizeof(client_auth_esc));
	
	if (StrEqual(tag_client, CHAR_NULL))
	{
		Format(query, sizeof(query), "DELETE FROM `nametag` WHERE `steam_id`='%s';",client_auth_esc);
	}
	else
	{
		if (!isSQLite)
		{
			Format(query, sizeof(query), "INSERT INTO `nametag` (`tag`, `name`, `steam_id`) VALUES ('%s', '%s', '%s') ON DUPLICATE KEY UPDATE `tag`='%s', `name`='%s'",client_tag_esc ,client_name_esc, client_auth_esc, client_tag_esc ,client_name_esc);
		}
		else
		{
			Format(query, sizeof(query), "REPLACE INTO `nametag` (`tag`, `name`, `steam_id`) VALUES ('%s', '%s', '%s')",client_tag_esc ,client_name_esc, client_auth_esc);
		}
	}
	SQL_TQuery(m_database, sql_ErrorOnly, query);
}

//=========================================================
//		ParseTags()
//=========================================================

ParseTags()
{	
	new Handle:kv_nametags = CreateKeyValues("Nametags");
	new String:path[256];

	BuildPath(Path_SM, path, sizeof(path), "configs/nametag.cfg");
	FileToKeyValues(kv_nametags, path);

	if (!KvGotoFirstSubKey(kv_nametags))
	{
		SetFailState("* ERROR: Can't read nametags from %s", path);
		return;
	}
	
	kv_tag_count = 0;

	do
	{
		KvGetSectionName(kv_nametags, kv_tag_name[kv_tag_count], MAX_LENGTH);
		KvGetString(kv_nametags, "nametag", kv_tag_nametag[kv_tag_count], MAX_LENGTH);
		KvGetString(kv_nametags, "achievement", kv_tag_achievement[kv_tag_count], 256);
		if (StrEqual(kv_tag_achievement[kv_tag_count], CHAR_NULL))
		{
			for (new i = 0; i < MAXPLAYERS+1; i++)
			{
				client_achieved[i][kv_tag_count] = true;
			}
		}
		else
		{
			KvGetString(kv_nametags, "description", kv_tag_description[kv_tag_count], 256);
		}
		
		
		kv_tag_count++;
	}
	while (KvGotoNextKey(kv_nametags));

	CloseHandle(kv_nametags);
}