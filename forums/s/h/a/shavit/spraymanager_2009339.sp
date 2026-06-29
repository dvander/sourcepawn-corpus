#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <spraymanager>
#include <smlib>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#pragma semicolon 1

#define PLUGIN_VERSION "1.5.1"

#define MAX_CONNECTIONS 5

new Handle:gH_Enabled = INVALID_HANDLE;
new bool:gB_Enabled;

new Handle:gH_Location = INVALID_HANDLE;
new gI_Location;

new Handle:gH_AntiOverlap = INVALID_HANDLE;
new Float:gF_AntiOverlap;

new Handle:gH_Auth = INVALID_HANDLE;
new gI_Auth;

new Handle:gH_SQL = INVALID_HANDLE;
new gI_Connections;

new bool:gB_Spraybanned[MAXPLAYERS+1];
new Float:gF_SprayVector[MAXPLAYERS+1][3];
new String:gS_Auth[MAXPLAYERS+1][128];

new Handle:gH_HUD = INVALID_HANDLE;

new Handle:gH_AdminMenu = INVALID_HANDLE;

new Handle:gH_BanForward = INVALID_HANDLE;
new Handle:gH_UnbanForward = INVALID_HANDLE;

new bool:gB_Late;

public Plugin:myinfo = 
{
	name = "Spray Manager",
	description = "Allows to see who owns each spray and banning players from spraying.",
	author = "shavit",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=163134"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("SprayManager_BanClient", Native_BanClient);
	CreateNative("SprayManager_UnbanClient", Native_UnbanClient);
	CreateNative("SprayManager_IsBanned", Native_IsBanned);
	
	RegPluginLibrary("spraymanager");
	
	gB_Late = late;
	
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	
	RegAdminCmd("sm_sprayban", Command_Sprayban, ADMFLAG_BAN, "Usage: sm_sprayban <target>");
	RegAdminCmd("sm_sban", Command_Sprayban, ADMFLAG_BAN, "Usage: sm_sban <target>");
	
	RegAdminCmd("sm_offlinesprayban", Command_OfflineSprayban, ADMFLAG_BAN, "Usage: sm_offlinesprayban <steamid> [name]");
	RegAdminCmd("sm_offlinesban", Command_OfflineSprayban, ADMFLAG_BAN, "Usage: sm_offlinesban <steamid> [name]");
	
	RegAdminCmd("sm_sprayunban", Command_Sprayunban, ADMFLAG_UNBAN, "Usage: sm_sprayunban <target>");
	RegAdminCmd("sm_sunban", Command_Sprayunban, ADMFLAG_UNBAN, "Usage: sm_sunban <target>");
	
	RegAdminCmd("sm_sbans", Command_Spraybans, ADMFLAG_GENERIC, "Shows a list of all connected spray banned players.");
	RegAdminCmd("sm_spraybans", Command_Spraybans, ADMFLAG_GENERIC, "Shows a list of all connected spray banned players.");
	
	RegAdminCmd("sm_allsbans", Command_AllSpraybans, ADMFLAG_GENERIC, "Shows a list of all spray banned players, even if they're not in-game.");
	RegAdminCmd("sm_offlinesbans", Command_AllSpraybans, ADMFLAG_GENERIC, "Shows a list of all spray banned players, even if they're not in-game.");
	
	CreateConVar("sm_spraymanager_version", PLUGIN_VERSION, "Spray Manager version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	gH_Enabled = CreateConVar("sm_spraymanager_enabled", "1", "Enable \"Spray Manager\"?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gB_Enabled = GetConVarBool(gH_Enabled);
	
	gH_Location = CreateConVar("sm_spraymanager_textloc", "1", "Where players will see the owner of the spray that they're aiming at?\n0 - Disabled\n1 - Hud hint\n2 - Hint text (like sm_hsay)\n3 - Center text (like sm_csay)\n4 - HUD (if supported by the game)\n5 - Top left (like sm_tsay)", FCVAR_PLUGIN, true, 0.0, true, 5.0);
	gI_Location = GetConVarInt(gH_Location);
	
	gH_AntiOverlap = CreateConVar("sm_spraymanager_overlap", "0", "Prevent spray-on-spray overlapping?\nIf enabled, specify an amount of units that another player spray's distance from the new spray needs to be it or more, recommended value is 75.", FCVAR_PLUGIN, true, 0.0);
	gF_AntiOverlap = GetConVarFloat(gH_AntiOverlap);
	
	gH_Auth = CreateConVar("sm_spraymanager_auth", "1", "Which authentication identifiers should be seen in the HUD?\n- This is a \"math\" cvar, add the proper numbers for your likings. (Example: 1 + 4 = 5/Name + IP address)\n1 - Name\n2 - SteamID\n4 - IP address", FCVAR_PLUGIN, true, 1.0);
	gI_Auth = GetConVarInt(gH_Auth);
	
	HookConVarChange(gH_Enabled, OnConVarChanged);
	HookConVarChange(gH_Location, OnConVarChanged);
	HookConVarChange(gH_AntiOverlap, OnConVarChanged);
	HookConVarChange(gH_Auth, OnConVarChanged);
	
	AutoExecConfig(true, "spraymanager");
	
	gH_BanForward = CreateGlobalForward("SprayManager_OnBan", ET_Event, Param_Cell);
	gH_UnbanForward = CreateGlobalForward("SprayManager_OnUnban", ET_Event, Param_Cell);
	
	AddTempEntHook("Player Decal", Player_Decal);
	
	CreateTimer(0.5, Timer_ShowSprays, INVALID_HANDLE, TIMER_REPEAT);
	
	gH_HUD = CreateHudSynchronizer();
	
	if(gH_HUD == INVALID_HANDLE && gI_Location == 4)
	{
		SetConVarInt(gH_Location, 1, true);
		
		LogError("[Spray Manager] This game can't use HUD messages, value of \"sm_spraymanager_textloc\" forced to 1.");
	}
	
	if(LibraryExists("adminmenu") && ((gH_AdminMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(gH_AdminMenu);
		
		AddItems();
	}
	
	SQL_Connector();
}

void:SQL_Connector()
{
	if(gH_SQL != INVALID_HANDLE)
	{
		CloseHandle(gH_SQL);
	}
	
	gH_SQL = INVALID_HANDLE;
	
	if(SQL_CheckConfig("spraymanager"))
	{
		SQL_TConnect(SQL_ConnectorCallback, "spraymanager");
	}
	
	else
	{
		SetFailState("PLUGIN STOPPED - Reason: No config entry found for 'spraymanager' in databases.cfg - PLUGIN STOPPED");
	}
}

public SQL_ConnectorCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Connection to SQL database has failed, reason: %s", error);
		
		gI_Connections++;
		
		SQL_Connector();
		
		if(gI_Connections > MAX_CONNECTIONS)
		{
			SetFailState("Connection to SQL database has failed too many times (%d), plugin unloaded to prevent spam.", MAX_CONNECTIONS);
		}
		
		return;
	}
	
	new String:driver[16];
	SQL_GetDriverIdent(owner, driver, 16);
	
	gH_SQL = CloneHandle(hndl);
	
	if(StrEqual(driver, "mysql", false))
	{
		SQL_LockDatabase(gH_SQL);
		SQL_FastQuery(gH_SQL, "SET NAMES \"UTF8\""); 
		SQL_UnlockDatabase(gH_SQL);
		
		SQL_TQuery(gH_SQL, SQL_CreateTableCallback, "CREATE TABLE IF NOT EXISTS `spraymanager` (`auth` VARCHAR(32) NOT NULL, `name` VARCHAR(32) DEFAULT '<unknown>', PRIMARY KEY (`auth`)) ENGINE = InnoDB CHARACTER SET utf8 COLLATE utf8_general_ci;");
	}
	
	else if(StrEqual(driver, "sqlite", false))
	{
		SQL_TQuery(gH_SQL, SQL_CreateTableCallback, "CREATE TABLE IF NOT EXISTS `spraymanager` (`auth` VARCHAR(32) NOT NULL, `name` VARCHAR(32) DEFAULT '<unknown>', PRIMARY KEY (`auth`));");
	}
	
	CloseHandle(hndl);
}

public SQL_CreateTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(owner == INVALID_HANDLE)
	{
		LogError(error);
		
		SQL_Connector();
		
		return;
	}
	
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQL Error on SQL_ConnectorCallback: %s", error);
		
		return;
	}
	
	if(gB_Late)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				OnClientPutInServer(i);
			}
		}
		
		CheckBans();
	}
}

void:CheckBans()
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			new bool:fetched;
			
			new String:auth[32];
			GetClientAuthString(i, auth, 32);
			
			decl String:sQuery[256];
			FormatEx(sQuery, 256, "SELECT * FROM spraymanager WHERE auth = '%s'", auth);
			
			SQL_LockDatabase(gH_SQL);
			new Handle:hQuery = SQL_Query(gH_SQL, sQuery);
			
			while(SQL_FetchRow(hQuery))
			{
				fetched = true;
			}
			
			SQL_UnlockDatabase(gH_SQL);
			CloseHandle(hQuery);
			
			gB_Spraybanned[i] = fetched;
		}
	}
}

public AddItems()
{
	AddToTopMenu(gH_AdminMenu, "Spray Manager", TopMenuObject_Category, CategoryHandler, INVALID_TOPMENUOBJECT);
	
	new TopMenuObject:player_commands = FindTopMenuCategory(gH_AdminMenu, ADMINMENU_PLAYERCOMMANDS);
	
	if(player_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	AddToTopMenu(gH_AdminMenu, "sm_sprayban", TopMenuObject_Item, AdminMenu_SprayBan, player_commands, "sm_sprayban", ADMFLAG_BAN);
	AddToTopMenu(gH_AdminMenu, "sm_sprayunban", TopMenuObject_Item, AdminMenu_SprayUnban, player_commands, "sm_sprayunban", ADMFLAG_UNBAN);
	AddToTopMenu(gH_AdminMenu, "sm_spraybans", TopMenuObject_Item, AdminMenu_SprayBans, player_commands, "sm_spraybans", ADMFLAG_GENERIC);
}

public AdminMenu_SprayBan(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "Spray Ban");
	}
	
	else if(action == TopMenuAction_SelectOption)
	{
		new Handle:menu = CreateMenu(MenuHandler_SprayBan);
		SetMenuTitle(menu, "Spray Ban:");
		
		new count;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(!gB_Spraybanned[i])
				{
					new String:info[8];
					new String:name[MAX_NAME_LENGTH];
					
					IntToString(GetClientUserId(i), info, 8);
					GetClientName(i, name, MAX_NAME_LENGTH);
					
					AddMenuItem(menu, info, name);
					
					count++;
				}
			}
		}
		
		if(!count)
		{
			AddMenuItem(menu, "none", "No matching players found");
		}
		
		SetMenuExitBackButton(menu, true);
		
		DisplayMenu(menu, param, 20);
	}
}

public MenuHandler_SprayBan(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[8];
		GetMenuItem(menu, param2, info, 8);
		
		FakeClientCommand(param1, "sm_sprayban #%d", StringToInt(info));
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			RedisplayAdminMenu(gH_AdminMenu, param1);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public AdminMenu_SprayUnban(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "Spray Unban");
	}
	
	else if(action == TopMenuAction_SelectOption)
	{
		new Handle:menu = CreateMenu(MenuHandler_SprayUnban);
		SetMenuTitle(menu, "Spray Unban:");
		
		new count;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(gB_Spraybanned[i])
				{
					new String:info[8];
					new String:name[MAX_NAME_LENGTH];
					
					IntToString(GetClientUserId(i), info, 8);
					GetClientName(i, name, MAX_NAME_LENGTH);
					
					AddMenuItem(menu, info, name);
					
					count++;
				}
			}
		}
		
		if(!count)
		{
			AddMenuItem(menu, "none", "No matching players found");
		}
		
		SetMenuExitBackButton(menu, true);
		
		DisplayMenu(menu, param, 20);
	}
}

public AdminMenu_SprayBans(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "Spray Ban List");
	}
	
	else if(action == TopMenuAction_SelectOption)
	{
		new Handle:menu = CreateMenu(MenuHandler_DoNothing2);
		SetMenuTitle(menu, "------------------------\nSpray Banned Players:\n------------------------");
		
		new count;
		
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsValidClient(i))
			{
				if(gB_Spraybanned[i])
				{
					new String:Display[MAX_NAME_LENGTH];
					GetClientName(i, Display, MAX_NAME_LENGTH);
					
					AddMenuItem(menu, "none", Display);
					
					count++;
				}
			}
		}
		
		if(!count)
		{
			AddMenuItem(menu, "none", "No spray banned players are connected.");
		}
		
		SetMenuExitBackButton(menu, true);
		
		DisplayMenu(menu, param, 20);
	}
}

public MenuHandler_SprayUnban(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[8];
		GetMenuItem(menu, param2, info, 8);
		
		FakeClientCommand(param1, "sm_sprayunban #%d", StringToInt(info));
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			RedisplayAdminMenu(gH_AdminMenu, param1);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}


public CategoryHandler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if(action == TopMenuAction_DisplayTitle)
	{
		FormatEx(buffer, maxlength, "Spray Manager administration:");
	}
	
	else if(action == TopMenuAction_DisplayOption)
	{
		FormatEx(buffer, maxlength, "Spray Manager administration");
	}
}

public OnLibraryRemoved(const String:name[])
{
	if(StrEqual(name, "adminmenu"))
	{
		gH_AdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if(topmenu == gH_AdminMenu)
	{
		return;
	}
}

public OnConVarChanged(Handle:cvar, const String:oldval[], const String:newval[])
{
	if(cvar == gH_Enabled)
	{
		gB_Enabled = bool:StringToInt(newval);
	}
	
	else if(cvar == gH_Location)
	{
		gI_Location = StringToInt(newval);
	}
	
	else if(cvar == gH_AntiOverlap)
	{
		gF_AntiOverlap = StringToFloat(newval);
	}
	
	else if(cvar == gH_Auth)
	{
		gI_Auth = StringToInt(newval);
	}
}

public OnClientPutInServer(client)
{
	gF_SprayVector[client] = Float:{0.0, 0.0, 0.0};
}

public Action:Player_Decal(const String:name[], const clients[], count, Float:delay)
{
	if(!gB_Enabled)
	{
		return Plugin_Continue;
	}
	
	new client = TE_ReadNum("m_nPlayer");
	
	if(IsValidClient(client))
	{
		if(gB_Spraybanned[client])
		{
			return Plugin_Handled;
		}
		
		new Float:fSprayVector[3];
		TE_ReadVector("m_vecOrigin", fSprayVector);
		
		if(gF_AntiOverlap > 0)
		{
			for(new i = 1; i <= MaxClients; i++)
			{
				if(IsValidClient(i) && i != client)
				{
					if(GetVectorDistance(fSprayVector, gF_SprayVector[i]) <= gF_AntiOverlap)
					{
						PrintToChat(client, "\x04[Spray Manager]\x01 Your spray is too close to \x05%N\x01's spray.", i);
						
						return Plugin_Handled;
					}
				}
			}
		}
		
		gF_SprayVector[client] = fSprayVector;
		
		strcopy(gS_Auth[client], 128, "");
		
		if(gI_Auth & 1)
		{
			Format(gS_Auth[client], 128, "%s%N", gS_Auth[client], client);
		}
		
		if(gI_Auth & 2)
		{
			new String:auth[32];
			GetClientAuthString(client, auth, 32);
			
			Format(gS_Auth[client], 128, "%s%s(%s)", gS_Auth[client], gI_Auth & 1? "\n":"", auth);
		}
		
		if(gI_Auth & 4)
		{
			new String:IP[32];
			GetClientIP(client, IP, 32);
			
			Format(gS_Auth[client], 128, "%s%s(%s)", gS_Auth[client], gI_Auth & (1|2)? "\n":"", IP);
		}
	}
	
	return Plugin_Continue;
}

public Action:Command_Sprayban(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "[SM] This plugin is currently disabled.");
		
		return Plugin_Handled;
	}
	
	if(!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sprayban <target>");
		
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg1, MAX_TARGET_LENGTH);
	
	new target = FindTarget(client, arg1);
	
	if(target == -1)
	{
		return Plugin_Handled;
	}
	
	if(gB_Spraybanned[target])
	{
		ReplyToCommand(client, "[SM] Unable to spray ban %N, reason - already spray banned.", target);
		
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "[SM] Successfully spray banned %N.", target);
	PrintToChat(target, "\x04[Spray Manager]\x01 You've been spray banned.");
	
	new String:auth[32];
	GetClientAuthString(target, auth, 32);
	
	decl String:targetName[MAX_NAME_LENGTH];
	GetClientName(target, targetName, MAX_NAME_LENGTH);
	
	decl String:targetSafeName[2 * strlen(targetName) + 1];
	SQL_LockDatabase(gH_SQL);
	SQL_EscapeString(gH_SQL, targetName, targetSafeName, 2 * strlen(targetName) + 1);
	SQL_UnlockDatabase(gH_SQL);
	
	decl String:sQuery[256];
	FormatEx(sQuery, 256, "INSERT INTO spraymanager (auth, name) VALUES ('%s', '%s');", auth,  targetSafeName);
	
	SQL_LockDatabase(gH_SQL);
	SQL_FastQuery(gH_SQL, sQuery);
	SQL_UnlockDatabase(gH_SQL);
	
	LogAction(client, target, "Spray banned.");
	ShowActivity(client, "Spray banned %N", target);
	
	gF_SprayVector[target] = Float:{0.0, 0.0, 0.0};
	
	TE_Start("Player Decal");
	TE_WriteVector("m_vecOrigin", Float:{0.0, 0.0, 0.0});
	TE_WriteNum("m_nEntity", 0);
	TE_WriteNum("m_nPlayer", target);
	TE_SendToAll();
	
	gB_Spraybanned[target] = true;
	
	Call_StartForward(gH_BanForward);
	Call_PushCell(target);
	Call_Finish();
	
	return Plugin_Handled;
}

public Action:Command_OfflineSprayban(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "[SM] This plugin is currently disabled.");
		
		return Plugin_Handled;
	}
	
	if(!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_offlinesprayban <\"steamid\"> [name]");
		
		return Plugin_Handled;
	}
	
	new String:auth[MAX_STEAMAUTH_LENGTH];
	GetCmdArg(1, auth, MAX_STEAMAUTH_LENGTH);
	
	if(args == 1 && !StrEqual(auth, "STEAM_"))
	{
		ReplyToCommand(client, "[SM] Invalid SteamID. Valid SteamIDs are formmated in this way - STEAM_A:B:XXXXXXX.");
		
		return Plugin_Handled;
	}
	
	new String:targetName[MAX_NAME_LENGTH];
	FormatEx(targetName, MAX_NAME_LENGTH, "<unknown>");
	
	if(args >= 2)
	{
		GetCmdArg(2, targetName, MAX_NAME_LENGTH);
	}
	
	decl String:targetSafeName[2 * strlen(targetName) + 1];
	SQL_LockDatabase(gH_SQL);
	SQL_EscapeString(gH_SQL, targetName, targetSafeName, 2 * strlen(targetName) + 1);
	SQL_UnlockDatabase(gH_SQL);
	
	decl String:sQuery[256];
	FormatEx(sQuery, 256, "INSERT INTO spraymanager (auth, name) VALUES ('%s', '%s') ON DUPLICATE KEY UPDATE name = '%s';", auth,  targetSafeName, targetSafeName);
	
	SQL_LockDatabase(gH_SQL);
	SQL_FastQuery(gH_SQL, sQuery);
	SQL_UnlockDatabase(gH_SQL);
	
	ShowActivity(client, "Spray banned %s. (%s)", targetSafeName, auth);
	
	new target = -1;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			new String:sAuth[32];
			GetClientAuthString(i, sAuth, 32);
			
			if(StrEqual(sAuth, auth))
			{
				target = i;
				
				break;
			}
		}
	}
	
	if(target != -1)
	{
		gF_SprayVector[target] = Float:{0.0, 0.0, 0.0};
		
		TE_Start("Player Decal");
		TE_WriteVector("m_vecOrigin", Float:{0.0, 0.0, 0.0});
		TE_WriteNum("m_nEntity", 0);
		TE_WriteNum("m_nPlayer", target);
		TE_SendToAll();
		
		gB_Spraybanned[target] = true;
		
		Call_StartForward(gH_BanForward);
		Call_PushCell(target);
		Call_Finish();
		
		LogAction(client, target, "Spray banned.");
		
		PrintToChat(target, "\x04[Spray Manager]\x01 You've been spray banned.");
	}
	
	return Plugin_Handled;
}

public Action:Command_Sprayunban(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "[SM] This plugin is currently disabled.");
		
		return Plugin_Handled;
	}
	
	if(!args)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sprayunban <target>");
		
		return Plugin_Handled;
	}
	
	new String:arg1[MAX_TARGET_LENGTH];
	GetCmdArg(1, arg1, MAX_TARGET_LENGTH);
	
	new target = FindTarget(client, arg1);
	
	if(target == -1)
	{
		return Plugin_Handled;
	}
	
	if(!gB_Spraybanned[target])
	{
		ReplyToCommand(client, "[SM] Unable to spray unban %N, reason - not spray banned.", target);
		
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "[SM] Successfully spray unbanned %N.", target);
	PrintToChat(target, "\x04[Spray Manager]\x01 You've been spray unbanned.");
	
	gB_Spraybanned[target] = false;
	
	new String:auth[32];
	GetClientAuthString(target, auth, 32);
	
	decl String:sQuery[256];
	FormatEx(sQuery, 256, "DELETE FROM spraymanager WHERE auth = '%s';", auth);
	
	SQL_LockDatabase(gH_SQL);
	SQL_FastQuery(gH_SQL, sQuery);
	SQL_UnlockDatabase(gH_SQL);
	
	LogAction(client, target, "Spray unbanned.");
	ShowActivity(client, "Spray unbanned %N", target);
	
	Call_StartForward(gH_UnbanForward);
	Call_PushCell(target);
	Call_Finish();
	
	return Plugin_Handled;
}

public Action:Command_Spraybans(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "[SM] This plugin is currently disabled.");
		
		return Plugin_Handled;
	}
	
	new Handle:menu = CreateMenu(MenuHandler_DoNothing);
	SetMenuTitle(menu, "------------------------\nSpray Banned Players:\n------------------------");
	
	new count;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(gB_Spraybanned[i])
			{
				new String:Display[MAX_NAME_LENGTH];
				GetClientName(i, Display, MAX_NAME_LENGTH);
				
				AddMenuItem(menu, "none", Display);
				
				count++;
			}
		}
	}
	
	if(!count)
	{
		AddMenuItem(menu, "none", "No spray banned players are connected.");
	}
	
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 20);
	
	return Plugin_Handled;
}

public Action:Command_AllSpraybans(client, args)
{
	if(!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	if(!gB_Enabled)
	{
		ReplyToCommand(client, "[SM] This plugin is currently disabled.");
		
		return Plugin_Handled;
	}
	
	SQL_TQuery(gH_SQL, AllSprayBansCallback, "SELECT * FROM spraymanager", GetClientSerial(client));
	
	return Plugin_Handled;
}

public AllSprayBansCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQL error in Command_AllSpraybans: %s", error);
		
		return;
	}
	
	new client = GetClientFromSerial(data);
	
	if(!IsValidClient(client))
	{
		CloseHandle(hndl);
		
		return;
	}
	
	new Handle:menu = CreateMenu(MenuHandler_AllSpraybans);
	SetMenuTitle(menu, "------------------------\nSpray Banned Players:\n------------------------");
	
	while(SQL_FetchRow(hndl))
	{
		decl String:auth[MAX_STEAMAUTH_LENGTH];
		SQL_FetchString(hndl, 0, auth, MAX_STEAMAUTH_LENGTH);
		
		decl String:auth2[MAX_STEAMAUTH_LENGTH];
		FormatEx(auth2, MAX_STEAMAUTH_LENGTH, auth);
		ReplaceString(auth2, MAX_STEAMAUTH_LENGTH, "STEAM_", "", false);
		
		decl String:name[MAX_NAME_LENGTH];
		SQL_FetchString(hndl, 1, name, MAX_NAME_LENGTH);
		ReplaceString(name, MAX_NAME_LENGTH, ";", "", false);
		
		decl String:Display[128];
		FormatEx(Display, 128, "%s - %s", auth, name);
		
		decl String:info[64];
		FormatEx(info, 64, "%s;%s", name, auth);
		
		// debug
		// PrintToChat(client, "%s", info);
		
		AddMenuItem(menu, info, Display);
	}
	
	if(!GetMenuItemCount(menu))
	{
		AddMenuItem(menu, "none", "There are no spray banned players.");
	}
	
	SetMenuExitButton(menu, true);
	
	DisplayMenu(menu, client, 20);
	
	CloseHandle(hndl);
}

public MenuHandler_AllSpraybans(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select && CheckCommandAccess(param1, "sm_unban", ADMFLAG_UNBAN))
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, 32);
		
		if(!StrEqual(info, "none"))
		{
			decl String:tokens[64][64];
			ExplodeString(info, ";", tokens, sizeof(tokens), sizeof(tokens[]));  
			
			new Handle:menu2 = CreateMenu(MenuHandler_AllSpraybans_Ban);
			SetMenuTitle(menu2, "Are you sure you want to spray un-ban %s (%s)?", tokens[0], tokens[1]);
			
			AddMenuItem(menu2, tokens[1], "Yes");
			AddMenuItem(menu2, "none", "No");
			
			SetMenuExitBackButton(menu2, true);
			
			DisplayMenu(menu2, param1, 20);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public MenuHandler_AllSpraybans_Ban(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new String:info[32];
		GetMenuItem(menu, param2, info, 32);
		
		if(!StrEqual(info, "none"))
		{
			decl String:sQuery[128];
			FormatEx(sQuery, 128, "DELETE FROM spraymanager WHERE auth = '%s'", info);
			
			new Handle:pack = CreateDataPack();
			WritePackCell(pack, GetClientSerial(param1));
			WritePackString(pack, info);
			
			SQL_TQuery(gH_SQL, Offlinebans_UnbanCallback, sQuery, pack);
		}
	}
	
	else if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			Command_AllSpraybans(param1, -1);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public Offlinebans_UnbanCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("SQL error in MenuHandler_AllSpraybans_Ban: %s", error);
		
		return;
	}
	
	ResetPack(data);
	
	new client = GetClientFromSerial(ReadPackCell(data));
	
	new String:auth[MAX_STEAMAUTH_LENGTH];
	ReadPackString(data, auth, MAX_STEAMAUTH_LENGTH);
	
	CloseHandle(data);
	
	if(!IsValidClient(client))
	{
		CloseHandle(hndl);
		
		return;
	}
	
	LogToFile("addons/sourcemod/logs/spraymanager.log", "%L: Spray unbanned %s.", client, auth);
	
	new target = -1;
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			new String:sAuth[32];
			GetClientAuthString(i, sAuth, 32);
			
			if(StrEqual(sAuth, auth))
			{
				target = i;
				
				break;
			}
		}
	}
	
	if(target != -1)
	{
		gB_Spraybanned[target] = false;
		
		Call_StartForward(gH_UnbanForward);
		Call_PushCell(target);
		Call_Finish();
		
		PrintToChat(target, "\x04[Spray Manager]\x01 You've been spray unbanned.");
	}
	
	CloseHandle(hndl);
}

public MenuHandler_DoNothing(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public MenuHandler_DoNothing2(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Cancel)
	{
		if(param2 == MenuCancel_ExitBack)
		{
			RedisplayAdminMenu(gH_AdminMenu, param1);
		}
	}
	
	else if(action == MenuAction_End)
	{
		CloseHandle(menu);
	}
	
	return 0;
}

public Action:Timer_ShowSprays(Handle:Timer)
{
	if(!gB_Enabled || !gI_Location)
	{
		return Plugin_Continue;
	}
	
	new Float:fVector[3];
	
	for(new i = 1; i <= MaxClients; i++)
	{
		if(GetClientEyeEndLocation(i, fVector))
		{
			new String:Text[64];
			
			FormatEx(Text, 64, "");
			
			if(IsValidClient(i) && !IsFakeClient(i))
			{
				for(new j = 1; j <= MaxClients; j++)
				{
					if(IsValidClient(j))
					{
						if(GetVectorDistance(fVector, gF_SprayVector[j]) <= 50.0)
						{
							FormatEx(Text, 64, "Sprayed by:\n%s", gS_Auth[j]);
						}
					}
				}
				
				if(strlen(Text) >= 8)
				{
					switch(gI_Location)
					{
						case 1: Client_PrintKeyHintText(i, Text);
						case 2: Client_PrintHintText(i, Text);
						case 3: PrintCenterText(i, Text);
						
						case 4:
						{
							if(gH_HUD != INVALID_HANDLE)
							{
								SetHudTextParams(0.04, 0.8, 0.55, 125, 75, 100, 255);
								ShowSyncHudText(i, gH_HUD, Text);
							}
						}
						
						case 5: Client_TopText(i, Text);
						
						default: continue;
					}
				}
			}
		}
	}
	
	return Plugin_Continue;
}

public Native_BanClient(Handle:handler, numParams)
{
	new client = GetNativeCell(1);
	
	if(!IsValidClient(client))
	{
		ThrowError("Player index %d is invalid.", client);
	}
	
	if(gB_Spraybanned[client])
	{
		ThrowError("Player index %d is already spray banned.", client);
	}
	
	new String:auth[32];
	GetClientAuthString(client, auth, 32);
	
	decl String:sQuery[256];
	FormatEx(sQuery, 256, "INSERT INTO spraymanager (auth, name) VALUES ('%s', '%N');", auth,  client);
	
	SQL_LockDatabase(gH_SQL);
	SQL_FastQuery(gH_SQL, sQuery);
	SQL_UnlockDatabase(gH_SQL);
	
	if(bool:GetNativeCell(2))
	{
		TE_Start("Player Decal");
		TE_WriteVector("m_vecOrigin", Float:{0.0, 0.0, 0.0});
		TE_WriteNum("m_nEntity", 0);
		TE_WriteNum("m_nPlayer", client);
		TE_SendToAll();
		
		gF_SprayVector[client] = Float:{0.0, 0.0, 0.0};
	}
	
	gB_Spraybanned[client] = true;
	
	PrintToChat(client, "\x04[Spray Manager]\x01 You've been spray banned.");
}

public Native_UnbanClient(Handle:handler, numParams)
{
	new client = GetNativeCell(1);
	
	if(!IsValidClient(client))
	{
		ThrowError("Player index %d is invalid.", client);
	}
	
	if(!gB_Spraybanned[client])
	{
		ThrowError("Player index %d is not spray banned.", client);
	}
	
	new String:auth[32];
	GetClientAuthString(client, auth, 32);
	
	decl String:sQuery[256];
	FormatEx(sQuery, 256, "DELETE FROM spraymanager WHERE auth = '%s';", auth);
	
	SQL_LockDatabase(gH_SQL);
	SQL_FastQuery(gH_SQL, sQuery);
	SQL_UnlockDatabase(gH_SQL);
	
	gB_Spraybanned[client] = false;
	
	PrintToChat(client, "\x04[Spray Manager]\x01 You've been spray unbanned.");
}

public Native_IsBanned(Handle:handler, numParams)
{
	new client = GetNativeCell(1);
	
	if(!IsValidClient(client))
	{
		return ThrowError("Player index %d is invalid.", client);
	}
	
	return gB_Spraybanned[client];
}


/**
* Checks if client is valid, ingame and safe to use.
*
* @param client			Client index.
* @return				True if the user is valid, false otherwise.
*/
stock bool:IsValidClient(client)
{
	return (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client));
}

stock Client_TopText(client, const String:message[])
{
	if(!IsValidClient(client))
	{
		return;
	}
	
	new Handle:kv = CreateKeyValues("Stuff", "title", message);
	KvSetColor(kv, "color", 255, 255, 255, 255);
	KvSetNum(kv, "level", 1);
	KvSetNum(kv, "time", 1);
	
	CreateDialog(client, kv, DialogType_Msg);
	
	CloseHandle(kv);	
}

public bool:GetClientEyeEndLocation(client, Float:vector[3])
{
	if(!IsValidClient(client))
	{
		return false;
	}
	
	new Float:vOrigin[3];
	new Float:vAngles[3];

	GetClientEyePosition(client, vOrigin);
	GetClientEyeAngles(client, vAngles);

	new Handle:hTraceRay = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, ValidSpray);

	if(TR_DidHit(hTraceRay))
	{
		TR_GetEndPosition(vector, hTraceRay);
		CloseHandle(hTraceRay);
		
		return true;
	}

	CloseHandle(hTraceRay);
	
	return false;
}

public bool:ValidSpray(entity, contentsmask)
{
	return entity > MaxClients;
}
