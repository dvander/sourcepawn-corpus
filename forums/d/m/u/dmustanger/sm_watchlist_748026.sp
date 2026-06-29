#include <sourcemod>
#include "dbi.inc"
#include <sdktools>
native IRC_PrivMsg(const String:destination[], const String:message[], any:...);
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = 
{
	name = "WatchList",
	author = "Recon edited by Dmustanger",
	description = "Sets players to a WatchList.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=588456"
}

new Handle:CVar_IRCChan = INVALID_HANDLE;
new Handle:Database = INVALID_HANDLE;
new Handle:CVar_WL_Sound = INVALID_HANDLE;
new Handle:CVar_WL_showthewatch = INVALID_HANDLE;
new Handle:WatchlistPrint = INVALID_HANDLE;
new Handle:cvar_watch_announce_interval = INVALID_HANDLE;
new Handle:hTopMenu = INVALID_HANDLE;
new Handle:CVar_WL_Log = INVALID_HANDLE;

new targets[MAXPLAYERS];
new String:logFile[1024];
new const String:watch_sound[] = "resource/warning.wav";

new bool:HasIRC = false;
new bool:LogsEnabled = false;

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	MarkNativeAsOptional("IRC_PrivMsg");
	return true;
}

public OnPluginStart()
{
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/watchlist.log");
	CreateConVar("watchlist_version", PLUGIN_VERSION, "WatchList version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SQL_TConnect(GotDatabase, "watchlist");
	CVar_IRCChan = CreateConVar("wl_irc_channel", "", "Channel to broadcast WatchList messages on. Set to nothing to disable.");
	CVar_WL_Sound = CreateConVar("wl_sound_enabled", "0", "Plays a warning sound to admins when a WatchList player is announced.");
	CVar_WL_Log = CreateConVar("wl_log_enabled", "0", "Enables loging.");
	CVar_WL_showthewatch = CreateConVar("wl_showthewatch", "1", "Should we show the watch.");
	cvar_watch_announce_interval = CreateConVar("watch_announce_interval", "1.0",
												"Controls how often users on the watchlist \
												who are currently on the server are announced. \
												The time is specified in whole minutes (1.0...10.0).",
												FCVAR_NONE,	true, 1.0, true, 10.0);
	HookConVarChange(cvar_watch_announce_interval, OnWatchAnnounceIntervalChange);
	RegAdminCmd("sm_add_watch", Command_Add_Watch, ADMFLAG_GENERIC,
				"sm_add_watch steam_id | #userid \"reason\"",
				"Adds a player to the watchlist. If the client \
				is already on the list, the old entry will be overwritten.");
	RegAdminCmd("sm_remove_watch", Command_Remove_Watch, ADMFLAG_GENERIC,
				"sm_remove_watch steam_id | #userid",
				"Removes a player from the watchlist.");
	RegAdminCmd("sm_query_watch", Command_Query_Watch, ADMFLAG_GENERIC,
				"sm_query_watch steam_id | #userid",
				"Querys a player to see if they are on the watchlist.");
}

public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed GotDatabase Could not connect to the Database: %s", error);
	}
	else 
	{
		Database = hndl;
		InsertDB();
	}	
}

InsertDB()
{
	decl String:driver[64];
	SQL_ReadDriver(Database, driver, sizeof(driver));
	decl String:query[1024];
	if(strcmp(driver, "sqlite", false) == 0)
	{
		query = "CREATE TABLE IF NOT EXISTS player_watchlist ( \
					clientisingame INTEGER NOT NULL, \
					server TEXT NOT NULL, \
					steam TEXT PRIMARY KEY ON CONFLICT REPLACE, \
					reason TEXT NOT NULL);";
	}
	else
	{
		query = "CREATE TABLE IF NOT EXISTS player_watchlist ( \
					clientisingame INT UNSIGNED NOT NULL DEFAULT '0', \
					server VARCHAR(50) NOT NULL DEFAULT 'noserver', \
					steam VARCHAR(50) NOT NULL , \
					reason TEXT NOT NULL , \
				 PRIMARY KEY (steam) ) \
				 ENGINE = InnoDB;";
	}			
	SQL_TQuery(Database, T_Generic, query);	
}

public T_Generic(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_generic: %s", error);
	}
}

public OnConfigsExecuted()
{
	decl Handle:t_ConVar;
	t_ConVar = FindConVar("irc_version");
	if ( t_ConVar != INVALID_HANDLE )
	{
		HasIRC = true;
		CloseHandle(t_ConVar);
	}
	if (GetConVarInt(CVar_WL_Log) == 1)
	{
		LogsEnabled = true;
	}
	if (GetConVarInt(CVar_WL_showthewatch) == 1)
	{
		WatchlistPrint = CreateTimer(60.0, ShowWatch, INVALID_HANDLE, TIMER_REPEAT);
	}
}

public OnAllPluginsLoaded() 
{
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);	
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		hTopMenu = INVALID_HANDLE;
	}
}

public OnMapStart()
{
	PrecacheSound(watch_sound, true);
	
}

PrintToAdmins(String:text[])
{
	new maxclients = GetMaxClients();
	for(new i = 1; i <= maxclients; i++)
	{
		if(IsClientInGame(i) && GetUserFlagBits(i) & ADMFLAG_GENERIC)
		{
			PrintToChat(i, "%s", text);
			if (GetConVarInt(CVar_WL_Sound) == 1)
			{
				EmitSoundToClient(i, watch_sound);
			}
		}
	}
	if (HasIRC)
	{
		decl String:ircChan[64];
		GetConVarString(CVar_IRCChan, ircChan, sizeof(ircChan));
		if (strlen(ircChan) > 0)
		{
			IRC_PrivMsg(ircChan, "%s", text);
		}
	}
}

public OnClientPostAdminCheck(client)
{	
	if(GetUserFlagBits(client) & ADMFLAG_ROOT)
	{
		CreateTimer(10.0, ShowAdmin);
	}
	else
	{	
		decl String:steam[100];
		decl String:q_steam[200];
		decl String:query[256];
		GetClientAuthString(client, steam, sizeof(steam));
		SQL_EscapeString(Database, steam, q_steam, sizeof(q_steam));
		Format(query, sizeof(query), "SELECT clientisingame, server, reason FROM player_watchlist WHERE steam = '%s'", q_steam);
		SQL_TQuery(Database, T_CheckUser, query, client);
		if (LogsEnabled)
		{
			LogToFile(logFile, "Checking database for steam id %s", q_steam);
		}
	}
}

public Action:ShowAdmin(Handle:timer)
{
	decl String:query[256];
	decl String:servername[50];
	decl String:d_servername[100];
	GetClientName(0, servername, sizeof(servername));
	SQL_EscapeString(Database, servername, d_servername, sizeof(d_servername));
	Format(query, sizeof(query), "SELECT * FROM player_watchlist WHERE server = '%s'", d_servername);
	SQL_TQuery(Database, T_ShowWatch, query);
}
		
public T_CheckUser(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_CheckUser: %s", error);
		return;
	}
	if (SQL_FetchRow(hndl))
	{
		decl String:name[50];	
		decl String:steam[100];
		decl String:reason[513];
		decl String:d_steam[201];
		decl String:query[256];
		decl String:text[256];
		decl String:servername[50];
		decl String:d_servername[100];
		GetClientName(0, servername, sizeof(servername));
		GetClientName(data, name, sizeof(name));
		GetClientAuthString(data, steam, sizeof(steam));
		SQL_FetchString(hndl, 2, reason, sizeof(reason));
		SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
		SQL_EscapeString(Database, servername, d_servername, sizeof(d_servername));
		if (LogsEnabled)
		{
			LogToFile(logFile, "%s is on the watchlist for %s", d_steam, reason);
		}
		Format(query, sizeof(query), "UPDATE player_watchlist SET clientisingame = %i, server = '%s' WHERE steam = '%s'", data, d_servername, d_steam);
		SQL_TQuery(Database, T_Generic, query);
		Format(text, sizeof(text), "[Watchlist] Player %s [%s] is on the watchlist for %s", name, steam, reason);
		PrintToAdmins(text);
	}
	else
	{
		if (LogsEnabled)
		{
			decl String:steam[100];
			GetClientAuthString(data, steam, sizeof(steam));
			LogToFile(logFile, "%s is not on the watchlist", steam);
		}
	}
}

public OnClientDisconnect(client)
{
	decl String:steam[100];
	decl String:d_steam[201];
	decl String:query[256];
	GetClientAuthString(client, steam, sizeof(steam));
	SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
	Format(query, sizeof(query), "UPDATE player_watchlist SET clientisingame = 0, server = 'noserver' WHERE steam = '%s'", d_steam);
	SQL_TQuery(Database, T_Generic, query);
}

public Action:ShowWatch(Handle:timer, Handle:pack)
{
	decl String:servername[50];
	decl String:d_servername[100];
	decl String:query[256];
	GetClientName(0, servername, sizeof(servername));
	SQL_EscapeString(Database, servername, d_servername, sizeof(d_servername));
	Format(query, sizeof(query), "SELECT * FROM player_watchlist WHERE server = '%s'", d_servername);
	SQL_TQuery(Database, T_ShowWatch, query);
}

public T_ShowWatch(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_ShowWatch: %s", error);
		return;
	}
	while (SQL_FetchRow(hndl))
	{
		decl client;
		decl String:name[50];
		decl String:reason[256];
		decl String:text[256];
		decl String:steam[100];
		client = SQL_FetchInt(hndl, 0);
		GetClientAuthString(client, steam, sizeof(steam));
		GetClientName(client, name, sizeof(name));
		SQL_FetchString(hndl, 3, reason, sizeof(reason));
		Format(text, sizeof(text), "[Watchlist] Player %s [%s] is on the watchlist for %s", name, steam, reason);
		PrintToAdmins(text);
	}
}

public OnWatchAnnounceIntervalChange(Handle:cvar, const String:oldVal[], const String:newVal[]) 
{
	if (GetConVarInt(CVar_WL_showthewatch) == 1)
	{
		CloseHandle(WatchlistPrint);
		WatchlistPrint = CreateTimer(StringToInt(newVal) * 60.0, ShowWatch, INVALID_HANDLE, TIMER_REPEAT);
	}
}

public Action:Command_Add_Watch (client, args) 
{
	decl String:player_id[50];
	decl String:steam[100];
	decl String:reason[256];
	new target = -1;
	if (GetCmdArgs() < 2) 
	{
		ReplyToCommand(client, "You must provide a (steamid or userid) AND a reason");
		return Plugin_Handled;
	}
	GetCmdArg(1, player_id, sizeof(player_id));
	if (player_id[0] == '#') 
	{
		target = GetClientOfUserId(StringToInt(player_id[1]));
		if (target != 0)
		{
			GetClientAuthString(client, steam, sizeof(steam));	
		}
		else 
		{
			ReplyToTargetError(client, COMMAND_TARGET_NOT_IN_GAME);
			return Plugin_Handled;
		}
	}
	else
	{
		steam = player_id;
	}
	GetCmdArg(2, reason, sizeof(reason));
	AddWatch(client, target, steam, reason);
	return Plugin_Handled;

}

AddWatch(client, target, String:steam[], String:reason[]) 
{
	decl String:d_steam[201];
	decl String:quoted_reason[513];
	decl String:query[512];
	decl String:servername[50];
	decl String:d_servername[101];
	GetClientName(0, servername, sizeof(servername));
	SQL_EscapeString(Database, servername, d_servername, sizeof(d_servername));
	SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
	SQL_EscapeString(Database, reason, quoted_reason, sizeof(quoted_reason));
	Format(query, sizeof(query), "INSERT INTO player_watchlist (clientisingame, server, steam, reason) VALUES (%i, '%s', '%s', '%s')", target, d_servername, d_steam, quoted_reason);
	SQL_TQuery(Database, T_AddWatch, query, client);
	if (target > 0) 
	{
		decl String:player_name[50];
		decl String:text[256];
		GetClientName(target, player_name, sizeof(player_name));
		Format(text, sizeof(text), "[Watchlist] Added player %s to the watchlist for %s", player_name, reason);
		PrintToAdmins(text);
	}
	if (LogsEnabled)
	{
		LogToFile(logFile, "Added player %s to the watchlist for %s", steam, reason);
	}	
}

public T_AddWatch(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE) 
	{
		LogToFile(logFile, "Query Failed T_AddWatch: %s", error);
		PrintToChat(data, "Unable to add watch: %s", error);		
	}
}

public Action:Command_Remove_Watch (client, args) 
{
	decl String:player_id[50];
	decl String:steam[100];
	new target = -1;
	GetCmdArg(1, player_id, sizeof(player_id));
	if (player_id[0] == '#') 
	{
		target = GetClientOfUserId(StringToInt(player_id[1]));
		if (target != 0)
		{
			GetClientAuthString(client, steam, sizeof(steam));	
		}
		else 
		{
			ReplyToTargetError(client, COMMAND_TARGET_NOT_IN_GAME);
			return Plugin_Handled;
		}
	}
	else
	{
		steam = player_id;
	}
	RemoveWatch(client, target, steam);
	return Plugin_Handled;
}

RemoveWatch(client, target, String:steam[]) 
{
	decl String:d_steam[201];
	decl String:query[256];
	SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
	Format(query, sizeof(query), "DELETE FROM player_watchlist WHERE steam = '%s'", d_steam);	
	SQL_TQuery(Database, T_RemoveWatch, query, client);
	LogAction(client, target, "Removed player %s from the watchlist", steam);
	if (LogsEnabled)
	{
		LogToFile(logFile, "Removed player %s from the watchlist", steam);
	}
}

public T_RemoveWatch(Handle:owner, Handle:hndl, const String:error[], any:data) 
{
	if (hndl == INVALID_HANDLE) 
	{
		decl String:c_text[256];
		LogToFile(logFile, "Query Failed T_RemoveWatch: %s", error);
		Format(c_text, sizeof(c_text), "[Watchlist] Unable to remove watch: %s", error);
		PrintToChat(data, c_text);
	}
	else 
	{
		decl String:text[256];
		Format(text, sizeof(text), "[Watchlist] Removed player from watchlist.");
		PrintToAdmins(text);
	}
}

public Action:Command_Query_Watch (client, args)
{
	decl String:player_id[50];
	decl String:steam[100];
	new target = -1;
	GetCmdArg(1, player_id, sizeof(player_id));
	if (player_id[0] == '#') 
	{
		target = GetClientOfUserId(StringToInt(player_id[1]));
		if (target != 0)
		{
			GetClientAuthString(client, steam, sizeof(steam));	
		}
		else 
		{
			ReplyToTargetError(client, COMMAND_TARGET_NOT_IN_GAME);
			return Plugin_Handled;
		}
	}
	else
	{
		steam = player_id;
	}
	QueryWatch(client, steam);
	return Plugin_Handled;
}

QueryWatch(client, String:steam[])
{
	decl String:d_steam[201];
	decl String:query[256];
	SQL_EscapeString(Database, steam, d_steam, sizeof(d_steam));
	Format(query, sizeof(query), "SELECT * FROM player_watchlist WHERE steam = '%s'", d_steam);
	SQL_TQuery(Database, T_QueryWatch, query, client);
}

public T_QueryWatch(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_QueryWatch: %s", error);
		return;
	}
	if (SQL_FetchRow(hndl))
	{
		decl String:server[101];
		decl String:steam[101];
		decl String:reason[513];
		SQL_FetchString(hndl, 1, server, sizeof(server));
		SQL_FetchString(hndl, 2, steam, sizeof(steam));
		SQL_FetchString(hndl, 3, reason, sizeof(reason));
		PrintToChat(data, "%s is on the watchlist for %s and is on %s", steam, reason, server);
	}
	else
	{
		PrintToChat(data, "That steamid is not on the watchlist");
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == hTopMenu)
	{
		return;
	}
	hTopMenu = topmenu;
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);
	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(hTopMenu, "watchlist_add", TopMenuObject_Item, mnuAddWatch, player_commands, "sm_add_watch");		 
		AddToTopMenu(hTopMenu, "watchlist_remove", TopMenuObject_Item, mnuRemoveWatch, player_commands, "sm_remove_watch");
	}
}

public mnuAddWatch(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)	
	{
		Format(buffer, maxlength, "Add player to watchlist", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayAddWatchTargetMenu(param);
	}
}

DisplayAddWatchTargetMenu(client) 
{
	new Handle:menu = CreateMenu(mnuAddWatchTarget);
	decl String:title[100];
	Format(title, sizeof(title), "Add player to watchlist", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu(menu, client, false, false);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public mnuAddWatchTarget (Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:info[32], String:name[32];
		new userid, target;
		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
		userid = StringToInt(info);
		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[Watchlist] Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[Watchlist] Player no longer available");
		}
		else
		{
			targets[param1] = target;
			DisplayWatchReasonMenu(param1);
		}
	}
}

DisplayWatchReasonMenu(client) 
{
	new Handle:menu = CreateMenu(mnuAddWatchReason);
	decl String:title[100];
	Format(title, sizeof(title), "Add player to watchlist", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "Cheating / Hacking", "Cheating");
	AddMenuItem(menu, "Mic Spam", "Mic Spam");
	AddMenuItem(menu, "Tking", "TKing");
	AddMenuItem(menu, "Breaking server rules", "Breaking server rules");
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public mnuAddWatchReason (Handle:menu, MenuAction:action, param1, param2) 
{	
	if (action == MenuAction_End)
	{		
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:reason[256];
		decl String:reason_name[256];
		decl String:steam[100];
		new target = targets[param1];
		GetClientAuthString(target, steam, sizeof(steam));
		GetMenuItem(menu, param2, reason, sizeof(reason), _, reason_name, sizeof(reason_name));
		AddWatch(param1, target, steam, reason_name);
	}	
}

public mnuRemoveWatch(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		Format(buffer, maxlength, "Remove player from watchlist", param);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayRemoveWatchTargetMenu(param);
	}
}

DisplayRemoveWatchTargetMenu(client) 
{
	new Handle:menu = CreateMenu(mnuRemoveWatchTarget);
	decl String:title[100];
	Format(title, sizeof(title), "Remove player from watchlist", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, menu);
	WritePackCell(pack, client);
	SQL_TQuery(Database, T_DisplayRemoveWatchTargetMenu, "SELECT * FROM player_watchlist WHERE clientisingame > 0", pack);
}

public T_DisplayRemoveWatchTargetMenu(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE) 
	{
		LogToFile(logFile, "Query Failed T_DisplayRemoveWatchTargetMenu: %s", error);
		return;
	}
	ResetPack(data);
	new Handle:menu = ReadPackCell(data);
	new client = ReadPackCell(data);
	CloseHandle(data);
	new bool:noClients = true;
	while (SQL_FetchRow(hndl))
	{
		decl String:steam[100];
		decl String:ingame_steam[100];
		decl String:target_s[10];
		new target = SQL_FetchInt(hndl, 0);
		IntToString(target, target_s, sizeof(target_s));
		SQL_FetchString(hndl, 2, steam, sizeof(steam));
		GetClientAuthString(target, ingame_steam, sizeof(ingame_steam));
		if (strcmp(steam, ingame_steam) == 0) 
		{
			decl String:name[50];
			GetClientName(target, name, sizeof(name));
			AddMenuItem(menu, target_s, name);
			if (noClients)
			{
				noClients = false;
			}
		}
	}
	if (noClients)
	{
		AddMenuItem(menu, "noClients", "No one in the server is on the watchlist.");
	}
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public mnuRemoveWatchTarget(Handle:menu, MenuAction:action, param1, param2) 
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		decl String:steam[100];
		decl String:target_s[30];
		decl String:junk[256];
		decl target;
		GetMenuItem(menu, param2, target_s, sizeof(target_s), _, junk, sizeof(junk));
		if (strcmp(target_s, "noClients", true) == 0) 
		{
			return;
		}
		target = StringToInt(target_s);
		GetClientAuthString(target, steam, sizeof(steam));
		RemoveWatch(param1, target, steam);
	}
}