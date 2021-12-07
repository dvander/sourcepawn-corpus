/**
* sourcebans.sp
*
* This file contains all Source Server Plugin Functions
* @author SteamFriends Development Team
* @version 0.0.0.$Rev: 108 $
* @copyright SteamFriends (www.steamfriends.com)
* @package SourceBans
* @link http://www.sourcebans.net
*/

#pragma semicolon 1
#include <sourcemod>
#include <sourcebans>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#include "dbi.inc"

public Plugin:myinfo =
{
	name = "SourceBans",
	author = "SteamFriends Development Team",
	description = "Advanced ban management for source",
	version = SB_VERSION,
	url = "http://www.sourcebans.net"
};


//GLOBAL DEFINES
#define YELLOW				0x01
#define NAMECOLOR			0x02
#define TEAMCOLOR			0x03
#define GREEN				0x04

#define DISABLE_ADDBAN		1
#define DISABLE_UNBAN		2

new g_BanTarget[MAXPLAYERS+1] = {-1, ...};
new g_BanTime[MAXPLAYERS+1] = {-1, ...};

enum State /* ConfigState */
{
	ConfigStateNone = 0,
	ConfigStateConfig,
	ConfigStateReasons,
	ConfigStateHacking
}

new State:ConfigState;
new Handle:ConfigParser;
new ConfigCounter;
new HackingConfigCounter;

new Handle:hTopMenu = INVALID_HANDLE;

new const String:SB_VERSION[] = "1.0.0 RC2";
new const String:BLANK[] = "";
new const String:Prefix[] = "[SourceBans] ";

new Handle:pluginHandle;

new bool:useHostIp = true;
new String:ServerIp[24];
new String:ServerPort[7];
new String:DatabasePrefix[10] = "sb";
new String:WebsiteAddress[128];

/* Admin Stuff*/
new AdminCachePart:loadPart;
new bool:loadAdmins;
new bool:loadGroups;
new bool:loadOverrides;
new curLoading=0;
new bool:isDirty[MAXPLAYERS+1];
new AdminFlag:g_FlagLetters[26];

/* Admin KeyValues */
new Handle:groupsKV;
new Handle:adminsKV;
new String:groupsLoc[128];
new String:adminsLoc[128];
	
/* Cvar handle*/
new Handle:CvarHostIp;
new Handle:CvarPort;

/* Database handle */
new Handle:Database;
new Handle:SQLiteDB;

/* Menu file globals */
new Handle:ReasonMenuHandle;
new Handle:HackingMenuHandle;

/* Datapack and Timer handles */
new Handle:PlayerRecheck[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};
new Handle:PlayerDataPack[MAXPLAYERS + 1] = {INVALID_HANDLE, ...};

/* Player ban check status */
new bool:PlayerStatus[MAXPLAYERS + 1];

/* Disable of addban and unban */
new CommandDisable;
new bool:backupConfig = true;
new bool:enableAdmins = true;

/* Log Stuff */
new String:logFile[256];

new MaxSlots;
new Float:RetryTime = 15.0;
new ProcessQueueTime = 5;
new bool:LateLoaded;
new bool:AutoAdd;





/*********************************************************
 * Ban Player from server
 *
 * @param client	The client index of the player to ban
 * @param time		The time to ban the player for (in minutes, 0 = permanent)
 * @param reason	The reason to ban the player from the server
 * @noreturn		
 *********************************************************/
public Native_SBBanPlayer(Handle:plugin, numParams)
{
	
	new time = GetNativeCell(3);
	new client = GetNativeCell(1);
	new target = GetNativeCell(2);
	decl String:adminSteam[64];
	decl String:reason[64];
	new bool:hasAdmin = false;
	GetClientAuthString(client, adminSteam, sizeof(adminSteam));
	
	GetNativeString(4, reason, 64);
	
	if(reason[0] == '\0')
		strcopy(reason, sizeof(reason), "Banned by SourceBans");
	
	new AdminId:aid = FindAdminByIdentity(AUTHMETHOD_STEAM, adminSteam);
	if(aid == INVALID_ADMIN_ID)
	{
		ThrowNativeError(1, "Ban Error: Player is not an admin.");
		return 0;
	}
	
	hasAdmin = GetAdminFlag(aid, Admin_Ban);
	
	if(!hasAdmin)
	{
		ThrowNativeError(2, "Ban Error: Player does not have BAN flag.");
		return 0;
	}
	
	PrepareBan(client, target, time, reason, sizeof(reason));
	return true;
}




public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	CreateNative("SBBanPlayer", Native_SBBanPlayer);
	LateLoaded = late;
	return true;
}

public OnPluginStart()
{
	pluginHandle = GetMyHandle();
		
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.basecommands");
	LoadTranslations("sourcebans.phrases");
	loadAdmins = loadGroups = loadOverrides = false;
	
	CvarHostIp = FindConVar("hostip");
	CvarPort = FindConVar("hostport");
	CreateConVar("sb_version", SB_VERSION, _, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegServerCmd("sm_rehash",sm_rehash,"Reload SQL admins");	
	RegAdminCmd("sm_ban", CommandBan, ADMFLAG_BAN, "sm_ban <#userid|name> <minutes|0> [reason]");
	RegAdminCmd("sm_banip", CommandAddBan, ADMFLAG_BAN, "sm_banip <time> <ip|#userid|name> [reason]");
	RegAdminCmd("sm_addban", CommandAddBan, ADMFLAG_RCON, "sm_addban <time> <steamid> <name> [reason]");
	RegAdminCmd("sm_unban", CommandUnban, ADMFLAG_UNBAN, "sm_unban <steamid>");
	RegAdminCmd("sb_reload",
				_CmdReload,
				ADMFLAG_RCON,
				"Reload sourcebans config and ban reason menu options",
				BLANK);

	if((ReasonMenuHandle = CreateMenu(ReasonSelected)) != INVALID_HANDLE)
	{
		SetMenuPagination(ReasonMenuHandle, MENU_NO_PAGINATION);
		SetMenuExitButton(ReasonMenuHandle, false);
	}

	if((HackingMenuHandle = CreateMenu(HackingSelected)) != INVALID_HANDLE)
	{
		SetMenuPagination(HackingMenuHandle, MENU_NO_PAGINATION);
		SetMenuExitButton(HackingMenuHandle, false);
	}
	
	g_FlagLetters['a'-'a'] = Admin_Reservation;
	g_FlagLetters['b'-'a'] = Admin_Generic;
	g_FlagLetters['c'-'a'] = Admin_Kick;
	g_FlagLetters['d'-'a'] = Admin_Ban;
	g_FlagLetters['e'-'a'] = Admin_Unban;
	g_FlagLetters['f'-'a'] = Admin_Slay;
	g_FlagLetters['g'-'a'] = Admin_Changemap;
	g_FlagLetters['h'-'a'] = Admin_Convars;
	g_FlagLetters['i'-'a'] = Admin_Config;
	g_FlagLetters['j'-'a'] = Admin_Chat;
	g_FlagLetters['k'-'a'] = Admin_Vote;
	g_FlagLetters['l'-'a'] = Admin_Password;
	g_FlagLetters['m'-'a'] = Admin_RCON;
	g_FlagLetters['n'-'a'] = Admin_Cheats;
	g_FlagLetters['o'-'a'] = Admin_Custom1;
	g_FlagLetters['p'-'a'] = Admin_Custom2;
	g_FlagLetters['q'-'a'] = Admin_Custom3;
	g_FlagLetters['r'-'a'] = Admin_Custom4;
	g_FlagLetters['s'-'a'] = Admin_Custom5;
	g_FlagLetters['t'-'a'] = Admin_Custom6;
	g_FlagLetters['z'-'a'] = Admin_Root;
	
	SQL_TConnect(GotDatabase, "sourcebans");
	
	
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/sourcebans.log");
		
	BuildPath(Path_SM,groupsLoc,sizeof(groupsLoc),"configs/admin_groups.cfg");
	groupsKV = CreateKeyValues("Groups");
	
	BuildPath(Path_SM,adminsLoc,sizeof(adminsLoc),"configs/admins.cfg");
	adminsKV = CreateKeyValues("Admins");

	InitializeBackupDB();
	
	// This timer is what processes the SQLite queue when the database is unavailable
	CreateTimer(float(ProcessQueueTime * 60), ProcessQueue);
	
	if(LateLoaded)
	{
		decl String:auth[30];
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(IsClientConnected(i) && !IsFakeClient(i))
			{
				PlayerStatus[i] = false;
			}
			if(IsClientInGame(i) && !IsFakeClient(i))
			{
				GetClientAuthString(i, auth, sizeof(auth));
				OnClientAuthorized(i, auth);
			}
		}
	}
		/* Account for late loading */
	
}

public OnAllPluginsLoaded()
{
	new Handle:topmenu;
	if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "OnAllPluginsLoaded()");
		
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(topmenu);
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "OnAdminMenuReady()");

	/* Block us from being called twice */
	if (topmenu == hTopMenu)
	{
		return;
	}
		
	/* Save the Handle */
	hTopMenu = topmenu;
	
	/* Find the "Player Commands" category */
	new TopMenuObject:player_commands = FindTopMenuCategory(hTopMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		new String:temp[125];
		new TopMenuObject:res = AddToTopMenu(hTopMenu,
							"sm_ban", 		// Name
							TopMenuObject_Item,	// We are a submenu
							AdminMenu_Ban,		// Handler function
							player_commands,	// We are a submenu of Player Commands
							"sm_ban",		// The command to be finally called (Override checks)
							ADMFLAG_BAN);		// What flag do we need to see the menu option
		if(IsPluginDebugging(pluginHandle))
		{
			Format(temp, 125, "Result of AddToTopMenu: %d", res);
			LogToFile(logFile, temp);
			LogToFile(logFile, "Added Ban option to admin menu");
		}
	}
}

public AdminMenu_Ban(Handle:topmenu, 
					TopMenuAction:action,	// Action being performed
					TopMenuObject:object_id,// The object ID (if used)
					param,			// client idx of admin who chose the option (if used)
					String:buffer[],	// Output buffer (if used)
					maxlength)		// Output buffer (if used)
{
	if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "AdminMenu_Ban()");
	if (action == TopMenuAction_DisplayOption)	// We are only being displayed, We only need to show the option name
	{
		//Format(buffer, maxlength, "%T", "Ban player", param);
		Format(buffer, maxlength, "Ban player", param);	// Show the menu option
		if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "AdminMenu_Ban() -> Formatted the Ban option text");
	}
	else if (action == TopMenuAction_SelectOption)
	{
		DisplayBanTargetMenu(param);	// Someone chose to ban someone, show the list of users menu
		if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "AdminMenu_Ban() -> DisplayBanTargetMenu()");
	}
}

DisplayBanTargetMenu(client)
{
	if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "DisplayBanTargetMenu()");
	new Handle:menu = CreateMenu(MenuHandler_BanPlayerList);// Create a new menu, pass it the handler.
	
	decl String:title[100];
	//Format(title, sizeof(title), "%T:", "Ban player", client);
	
	Format(title, sizeof(title), "Ban player", client);	// Create the title of the menu
	SetMenuTitle(menu, title);				// Set the title
	SetMenuExitBackButton(menu, true);			// Yes we want back/exit
	
	AddTargetsToMenu(menu, 					// Add clients to our menu
			client, 				// The client that called the display
			false, 					// We want to see people connecting
			false);					// And dead people
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);		// Show the menu to the client FOREVER!
}

public MenuHandler_BanPlayerList(Handle:menu, MenuAction:action, param1, param2)
{
	if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "MenuHandler_BanPlayerList()");
	if (action == MenuAction_End)
	{
		CloseHandle(menu);				// Chose to close the menu
	}
	else if (action == MenuAction_Cancel)
	{
		if (param2 == MenuCancel_ExitBack && hTopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(hTopMenu, param1, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)			// Chose someone!
	{
		decl String:info[32], String:name[32];
		new userid, target;
		
		GetMenuItem(menu, param2, info, sizeof(info), _, name, sizeof(name));
		userid = StringToInt(info);

		if ((target = GetClientOfUserId(userid)) == 0)
		{
			PrintToChat(param1, "[SM] %t", "Player no longer available");
		}
		else if (!CanUserTarget(param1, target))
		{
			PrintToChat(param1, "[SM] %t", "Unable to target");
		}
		else
		{
			g_BanTarget[param1] = target;
			DisplayBanTimeMenu(param1);
		}
	}
}

DisplayBanTimeMenu(client)
{
	if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "DisplayBanTimeMenu()");
		
	new Handle:menu = CreateMenu(MenuHandler_BanTimeList);
	
	decl String:title[100];
	//Format(title, sizeof(title), "%T:", "Ban player", client);
	Format(title, sizeof(title), "Ban player", client);
	SetMenuTitle(menu, title);
	SetMenuExitBackButton(menu, true);
	
	AddMenuItem(menu, "0", "Permanent");
	AddMenuItem(menu, "10", "10 Minutes");
	AddMenuItem(menu, "30", "30 Minutes");
	AddMenuItem(menu, "60", "1 Hour");
	AddMenuItem(menu, "240", "4 Hours");
	AddMenuItem(menu, "1440", "1 Day");
	AddMenuItem(menu, "10080", "1 Week");
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public MenuHandler_BanTimeList(Handle:menu, MenuAction:action, param1, param2)
{
	if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "MenuHandler_BanTimeList()");
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
		decl String:info[32];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		g_BanTime[param1] = StringToInt(info);
		
		//DisplayBanReasonMenu(param1);
		DisplayMenu(ReasonMenuHandle, param1, MENU_TIME_FOREVER);
	}
}


public MenuHandler_BanReasonList(Handle:menu, MenuAction:action, param1, param2)
{
	if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "MenuHandler_BanReasonList()");
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
		decl String:info[64];
		
		GetMenuItem(menu, param2, info, sizeof(info));
		PrepareBan(param1, g_BanTarget[param1], g_BanTime[param1], info, sizeof(info));
	}
}

PrepareBan(client, target, time, String:reason[], size)
{
	if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "PrepareBan()");
	decl String:authid[64], String:name[32];
	GetClientAuthString(target, authid, sizeof(authid));
	GetClientName(target, name, sizeof(name));

	
	if(CreateBan(client, target, time, reason))
	{
		if (!time)
		{
			if (reason[0] == '\0')
			{
				ShowActivity(client, "%t", "Permabanned player", name);
			} else {
				ShowActivity(client, "%t", "Permabanned player reason", name, reason);
			}
		} else {
			if (reason[0] == '\0')
			{
				ShowActivity(client, "%t", "Banned player", name, time);
			} else {
				ShowActivity(client, "%t", "Banned player reason", name, time, reason);
			}
		}
		LogAction(client, target, "\"%L\" banned \"%L\" (minutes \"%d\") (reason \"%s\")", client, target, time, reason);
		if (reason[0] == '\0')
		{
			strcopy(reason, size, "Banned");
		}
		
		if(time > 5)
			time = 5;
		
		BanClient(target, time, BANFLAG_AUTO, reason, reason, "sm_ban", client);
	}
	
	g_BanTarget[client] = -1;
	g_BanTime[client] = -1;
}

public OnPluginEnd()
{
	CloseHandle(groupsKV);
	CloseHandle(adminsKV);
}

public Action:sm_rehash(args)
{
	if(enableAdmins)
		DumpAdminCache(AdminCache_Groups,true);
	return Plugin_Handled;   
}

public OnRebuildAdminCache(AdminCachePart:part)
{
	loadPart = part;
	switch(loadPart)
	{
		case AdminCache_Overrides:
		loadOverrides = true;
		case AdminCache_Groups:
			loadGroups = true;
		case AdminCache_Admins:
			loadAdmins = true;
	}
	if(enableAdmins)
	{
		if(Database == INVALID_HANDLE)
			SQL_TConnect(GotDatabase,"sourcebans");
		else
			GotDatabase(Database,Database,"",0);
	}
}

public OnMapStart()
{
	MaxSlots = GetMaxClients();
	ResetSettings();
}

public OnMapEnd()
{
	for(new i = 0; i <= MaxSlots; i++)
	{
		if(PlayerDataPack[i] != INVALID_HANDLE)
		{
			/* Need to close reason pack */
			CloseHandle(PlayerDataPack[i]);
			PlayerDataPack[i] = INVALID_HANDLE;
		}
	}
}

ResetSettings()
{
	CommandDisable = 0;
	ConfigCounter = 0;
	HackingConfigCounter = 0;

	ResetMenu();
	ReadConfig();
}


public GotDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Database failure: %s", error);
		return;
	}
	
	Database = hndl;
	InsertServerInfo();
	
	//CreateTimer(900.0, PruneBans);
	
	new String:query[1024];
	if(loadOverrides)
	{
		loadOverrides = false;
	}
	
	if(loadGroups && enableAdmins)
	{
		FormatEx(query,1024,"SELECT name, flags, immunity, groups_immune   \
					FROM %s_srvgroups ORDER BY id",DatabasePrefix);
		curLoading++;
		SQL_TQuery(Database,GroupsDone,query);
		
		if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "Fetching Group List\n");
		loadGroups = false;
	}
	
	if(loadAdmins && enableAdmins)
	{
		FormatEx(query,1024,"SELECT authid, srv_password , srv_group, srv_flags, user, immunity  \
					FROM %s_admins_servers_groups AS asg \
					LEFT JOIN %s_admins AS a ON a.aid = asg.admin_id \
					WHERE (server_id = (SELECT `sid` FROM `%s_servers` WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1)  \
					OR srv_group_id = ANY (	SELECT group_id	FROM %s_servers_groups	WHERE server_id = (SELECT `sid` FROM `%s_servers` WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1))) \
					GROUP BY aid, authid, srv_password, srv_group, srv_flags, user",
				DatabasePrefix,DatabasePrefix, DatabasePrefix, ServerIp, ServerPort,DatabasePrefix, DatabasePrefix, ServerIp, ServerPort);				
		curLoading++;
		SQL_TQuery(Database,AdminsDone,query);
		
		if(IsPluginDebugging(pluginHandle))
		{
			LogToFile(logFile, "Fetching Admin List\n");
			LogToFile(logFile, query);
		}
		loadAdmins = false;
	}
	
}

public Action:OnClientPreAdminCheck(client)
{
	if (curLoading > 0)
	{
		isDirty[client] = true;
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

CheckLoadAdmins()
{
	for(new i = 1; i <= MAXPLAYERS; i++)
	{
		if(isDirty[i])
		{
			isDirty[i] = false;
			if(i <= GetMaxClients() && IsClientInGame(i))
			{
				RunAdminCacheChecks(i);
				NotifyPostAdminCheck(i);
			}
		}   
	}    
}

InsertServerInfo()
{
	if(Database == INVALID_HANDLE || !useHostIp)
	{
		return;
	}
	
	decl String:query[100], pieces[4];
	new longip = GetConVarInt(CvarHostIp);
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	FormatEx(ServerIp, sizeof(ServerIp), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	GetConVarString(CvarPort, ServerPort, sizeof(ServerPort));
	
	if(AutoAdd != false)
	{
		FormatEx(query, sizeof(query), "SELECT sid FROM `%s_servers` WHERE `ip` = '%s' AND `port` = '%s'", DatabasePrefix, ServerIp, ServerPort);
		SQL_TQuery(Database, ServerInfoCallback, query);
	}
}

public ServerInfoCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(error[0])
	{
		LogToFile(logFile, "%sQuery failed! %s", Prefix, error);
		return;
	}

	if(hndl	== INVALID_HANDLE || SQL_GetRowCount(hndl)==0)
	{	
		// get the game folder name used to determine the mod
		decl String:desc[64], String:query[200];
		GetGameFolderName(desc, sizeof(desc));
		FormatEx(query, sizeof(query), "INSERT INTO `%s_servers` (`ip`, `port`, `modid`, `rcon`) VALUES ('%s', '%s', (SELECT `mid` FROM `sb_mods` WHERE `modfolder` = '%s'), '')", DatabasePrefix, ServerIp, ServerPort, desc);
		SQL_TQuery(Database, ErrorCheckCallback, query);
	}
}

public Action:_CmdReload(client, args)
{
	ResetSettings();
	return Plugin_Handled;
}

public bool:OnClientConnect(client, String:rejectmsg[], maxlen)
{
	PlayerStatus[client] = false;
	return true;
}

public OnClientAuthorized(client, const String:auth[])
{
	/* Do not check bots nor check player with lan steamid. */
	if(auth[0] == 'B' || auth[9] == 'L' || Database == INVALID_HANDLE)
	{
		PlayerStatus[client] = true;
		return;
	}

	decl String:Query[256];
	FormatEx(Query, sizeof(Query), "SELECT * FROM `%s_bans` WHERE `authid` = '%s' AND (`length` = '0' OR `ends` > UNIX_TIMESTAMP())", DatabasePrefix, auth);
	
	if(IsPluginDebugging(pluginHandle))
		LogToFile(logFile, "%sChecking ban for:  %s\n", Prefix, auth);

	SQL_TQuery(Database, VerifyBan, Query, GetClientUserId(client), DBPrio_High);
}

public ErrorCheckCallback(Handle:owner, Handle:hndle, const String:error[], any:data)
{
	if(error[0])
	{
		LogError("%sQuery failed! %s", Prefix, error);
		LogToFile(logFile, "[ERROR] Query Failed: %s\n", error);
	}
}

public VerifyBan(Handle:owner, Handle:hndl, const String:error[], any:userid)
{
	decl String:clientName[64];
	decl String:clientAuth[64];

	/* Same player that started the query. */
	new client = GetClientOfUserId(userid);
	
	if(!client)
	{
		return;
	}
	
	/* Failure happen. Do retry with delay */
	if(hndl == INVALID_HANDLE)
	{
		LogMessage("%sQuery failed! %s", Prefix, error);
		LogToFile(logFile, "[ERROR] Query Failed: %s\n", error);
		PlayerRecheck[client] = CreateTimer(RetryTime, ClientRecheck, client);
		return;
	}
	GetClientAuthString(client, clientAuth, sizeof(clientAuth));
	GetClientName(client, clientName, sizeof(clientName));
	if(SQL_GetRowCount(hndl) > 0)
	{
		decl String:buffer[40];
		decl String:Query[512];
		FormatEx(Query, sizeof(Query), "INSERT INTO `%s_banlog` (`sid` ,`time` ,`name` ,`bid`) VALUES ((SELECT `sid` FROM `%s_servers` WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), UNIX_TIMESTAMP(), \"%s\", (SELECT bid FROM `%s_bans` WHERE `authid` = '%s' LIMIT 0,1))", DatabasePrefix, DatabasePrefix, ServerIp, ServerPort, clientName, DatabasePrefix, clientAuth);
		SQL_TQuery(Database, ErrorCheckCallback, Query, any:client, DBPrio_High);
		FormatEx(buffer, sizeof(buffer), "banid 5 %s", clientAuth);
		ServerCommand(buffer);
		KickClient(client, "%t", "Banned Check Site", WebsiteAddress);
		return;
	}
	LogMessage("%s%s is NOT banned.\n", Prefix, clientAuth);
	if(IsPluginDebugging(pluginHandle))
		LogToFile(logFile, "%s%s is NOT banned.\n", Prefix, clientAuth);
		
	PlayerStatus[client] = true;
}

public Action:ClientRecheck(Handle:timer, any:client)
{
	if(!PlayerStatus[client] && IsClientConnected(client))
	{
		decl String:Authid[64];
		GetClientAuthString(client, Authid, sizeof(Authid));
		OnClientAuthorized(client, Authid);
	}

	PlayerRecheck[client] =  INVALID_HANDLE;
	return Plugin_Stop;
}


public bool:CreateBan(client, target, time, String:reason[])
{
	decl String:adminIp[24], String:adminAuth[64];
	new admin = client;
	
	// The server is the one calling the ban
	if(!admin)
	{
		if(reason[0] == '\0')
		{
			// We cannot pop the reason menu if the command was issued from the server
			PrintToServer("%s%T", Prefix, "Include Reason", LANG_SERVER);
			return false;
		}

		// setup dummy adminAuth and adminIp for server
		strcopy(adminAuth, sizeof(adminAuth), "STEAM_ID_SERVER");
		strcopy(adminIp, sizeof(adminIp), ServerIp);
	} else {
		GetClientIP(admin, adminIp, sizeof(adminIp));
		GetClientAuthString(admin, adminAuth, sizeof(adminAuth));
	}

	// target information
	decl String:ip[24], String:auth[64], String:name[64];

	GetClientName(target, name, sizeof(name));
	GetClientIP(target, ip, sizeof(ip));
	GetClientAuthString(target, auth, sizeof(auth));

	new userid = admin ? GetClientUserId(admin) : 0;

	// Pack everything into a data pack so we can retain it
	new Handle:dataPack = CreateDataPack();
	new Handle:reasonPack = CreateDataPack();
	WritePackString(reasonPack, reason);

	WritePackCell(dataPack, admin);
	WritePackCell(dataPack, target);
	WritePackCell(dataPack, userid);
	WritePackCell(dataPack, GetClientUserId(target));
	WritePackCell(dataPack, time);
	WritePackCell(dataPack, _:reasonPack);
	WritePackString(dataPack, name);
	WritePackString(dataPack, auth);
	WritePackString(dataPack, ip);
	WritePackString(dataPack, adminAuth);
	WritePackString(dataPack, adminIp);

	ResetPack(dataPack);
	ResetPack(reasonPack);

	if(reason[0] != '\0')
	{
		// if we have a valid reason pass move forward with the ban
		if(Database != INVALID_HANDLE)
		{
			UTIL_InsertBan(time, name, auth, ip, reason, adminAuth, adminIp, dataPack);
		} else {
			UTIL_InsertTempBan(time, name, auth, ip, reason, adminAuth, adminIp, dataPack);
		}
	} else {
		// We need a reason so offer the administrator a menu of reasons
		PlayerDataPack[admin] = dataPack;
		DisplayMenu(ReasonMenuHandle, admin, MENU_TIME_FOREVER);
		ReplyToCommand(admin, "%c[%cSourceBans%c]%c %t", GREEN, NAMECOLOR, GREEN, NAMECOLOR, "Check Menu");
	}
	
	return true;
}


public Action:CommandBan(client, args)
{
	if(args < 2)
	{
		ReplyToCommand(client, "Usage: sm_ban <#userid|name> <time|0> [reason]");
		return Plugin_Handled;
	}

	// This is mainly for me sanity since client used to be called admin and target used to be called client
	new admin = client;
	
	// Get the target, find target returns a message on failure so we do not
	decl String:buffer[100];
	GetCmdArg(1, buffer, sizeof(buffer));
	new target = FindTarget(client, buffer, true);
	if(target == -1)
	{
		return Plugin_Handled;
	}

	// Get the ban time
	GetCmdArg(2, buffer, sizeof(buffer));
	new time = StringToInt(buffer);

	// Get the reason
	new String:reason[40];
	if(args >= 3)
	{
		GetCmdArg(3, reason, sizeof(reason));
	}

	if(!PlayerStatus[target])
	{
		// The target has not been banned verify. It must be completed before you can ban anyone.
		ReplyToCommand(admin, "%c[%cSourceBans%c]%c %t", GREEN, NAMECOLOR, GREEN, NAMECOLOR, "Ban Not Verified");
		return Plugin_Handled;
	}

	
	CreateBan(client, target, time, reason);
	return Plugin_Handled;
}

/**
 * From what I see it 8 * (Number of cells - 1) 4 * 8 = 32 for time position.
 */

public Action:BanFromMenu(Handle:timer, Handle:Pack)
{
	SetPackPosition(Pack, 32); /* Set pack position to the time position.*/
	new time = ReadPackCell(Pack);
	new Handle:ReasonPack = Handle:ReadPackCell(Pack);

	decl String:Name[64], String:Reason[128], String:Authid[64], String:Ip[24], String:AdminAuthid[64], String:AdminIp[24];
	ReadPackString(Pack, Name, sizeof(Name));
	ReadPackString(ReasonPack, Reason, sizeof(Reason));
	ReadPackString(Pack, Authid, sizeof(Authid));
	ReadPackString(Pack, Ip, sizeof(Ip));
	ReadPackString(Pack, AdminAuthid, sizeof(AdminAuthid));
	ReadPackString(Pack, AdminIp, sizeof(AdminIp));

	ResetPack(ReasonPack);
	ResetPack(Pack);

	decl String:QuotedName[129], String:QuotedReason[257];
	SQL_QuoteString(Database, Name, QuotedName, sizeof(QuotedName));
	SQL_QuoteString(Database, Reason, QuotedReason, sizeof(QuotedReason));
	UTIL_InsertBan(time, Name, Authid, Ip, Reason, AdminAuthid, AdminIp, Pack);

	return Plugin_Stop;
}

UTIL_InsertBan(time, const String:Name[], const String:Authid[], const String:Ip[], const String:Reason[], const String:AdminAuthid[], const String:AdminIp[], Handle:Pack)
{
	//new Handle:dummy;
	//PruneBans(dummy);
	decl String:Query[1024];
	FormatEx(Query, sizeof(Query), "INSERT INTO `%s_bans` (`ip`, `authid`, `name`, `created`, `ends`, `length`, `reason`, `aid`, `adminIp`, `sid`, `country`) VALUES ('%s', '%s', \"%s\", UNIX_TIMESTAMP(), UNIX_TIMESTAMP() + %d, '%d', '%s', (SELECT `aid` FROM `%s_admins` WHERE `authid` = '%s'), '%s', (SELECT `sid` FROM `%s_servers` WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1), ' ')", DatabasePrefix, Ip, Authid, Name, (time*60), (time*60), Reason, DatabasePrefix, AdminAuthid, AdminIp, DatabasePrefix, ServerIp, ServerPort);

	SQL_TQuery(Database, VerifyInsert, Query, Pack, DBPrio_High);
}

UTIL_InsertTempBan(time, const String:name[], const String:auth[], const String:ip[], const String:reason[], const String:adminAuth[], const String:adminIp[], Handle:dataPack)
{
	ReadPackCell(dataPack);
	new client = ReadPackCell(dataPack);
	SetPackPosition(dataPack, 40);
	new Handle:reasonPack = Handle:ReadPackCell(dataPack);
	if(reasonPack != INVALID_HANDLE)
	{
		CloseHandle(reasonPack);
	}
	CloseHandle(dataPack);
	
	// we add a temporary ban and then add the record into the queue to be processed when the database is available
	decl String:buffer[50];
	Format(buffer, sizeof(buffer), "banid %d %s", ProcessQueueTime, auth);
	ServerCommand(buffer);
	KickClient(client, "%t", "Banned Check Site", WebsiteAddress);
	
	decl String:query[512];
	FormatEx(	query, sizeof(query), "INSERT INTO queue VALUES ('%s', %i, %i, '%s', '%s', '%s', '%s', '%s')", 
				auth, time, GetTime(), reason, name, ip, adminAuth, adminIp);
	SQL_TQuery(SQLiteDB, ErrorCheckCallback, query);
}

public VerifyInsert(Handle:owner, Handle:hndl, const String:error[], any:dataPack)
{
	if(dataPack == INVALID_HANDLE)
	{
		LogMessage("%sBan Failed! %s", Prefix);
		return;
	}
	
	if(hndl == INVALID_HANDLE || error[0])
	{
		LogMessage("%sQuery failed! %s", Prefix, error);
		new admin = ReadPackCell(dataPack);
		SetPackPosition(dataPack, 32);
		new time = ReadPackCell(dataPack);
		new Handle:reasonPack = Handle:ReadPackCell(dataPack);
		decl String:reason[50];
		ReadPackString(reasonPack, reason, sizeof(reason));
		decl String:name[50];
		ReadPackString(dataPack, name, sizeof(name));
		decl String:auth[30];
		ReadPackString(dataPack, auth, sizeof(auth));
		decl String:ip[20];
		ReadPackString(dataPack, ip, sizeof(ip));
		decl String:adminAuth[30];
		ReadPackString(dataPack, adminAuth, sizeof(adminAuth));
		decl String:adminIp[20];
		ReadPackString(dataPack, adminIp, sizeof(adminIp));
		ResetPack(dataPack);
		ResetPack(reasonPack);

		PlayerDataPack[admin] = INVALID_HANDLE;
		UTIL_InsertTempBan(time, name, auth, ip, reason, adminAuth, adminIp, Handle:dataPack);
		return;
	}

	new admin = ReadPackCell(dataPack);
	new client = ReadPackCell(dataPack);
	SetPackPosition(dataPack, 24);
	new UserId = ReadPackCell(dataPack);
	new time = ReadPackCell(dataPack);
	new Handle:ReasonPack = Handle:ReadPackCell(dataPack);

	decl String:Name[64], String:Reason[128];

	ReadPackString(dataPack, Name, sizeof(Name));
	ReadPackString(ReasonPack, Reason, sizeof(Reason));

	if (!time)
	{
		if (Reason[0] == '\0')
		{
			ShowActivityEx(admin, Prefix, "%t", "Permabanned player", Name);
		} else {
			ShowActivityEx(admin, Prefix, "%t","Permabanned player reason", Name, Reason);
		}
	} else {
		if (Reason[0] == '\0')
		{
			ShowActivityEx(admin, Prefix, "%t", "Banned player", Name, time);
		} else {
			ShowActivityEx(admin, Prefix, "%t", "Banned player reason", Name, time, Reason);
		}
	}

	LogMessage("\"%L\" banned \"%L\" (minutes \"%d\") (reason \"%s\")", admin, client, time, Reason);

	if(PlayerDataPack[admin] != INVALID_HANDLE)
	{
		CloseHandle(PlayerDataPack[admin]);
		CloseHandle(ReasonPack);
		PlayerDataPack[admin] = INVALID_HANDLE;
	}

	// Kick player
	if(GetClientUserId(client) == UserId)
	{
		KickClient(client, "%t", "Banned Check Site", WebsiteAddress);
	}
}

public Action:CommandUnban(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "%ssm_unban <steamid>", Prefix);
		return Plugin_Handled;
	}
	
	if(CommandDisable & DISABLE_UNBAN)
	{
        // They must go to the website to unban people
        ReplyToCommand(client, "%s%t", Prefix, "Can Not Unban",WebsiteAddress);
        return Plugin_Handled;
	}
	
	decl String:auth[30];
	GetCmdArg(1, auth, sizeof(auth));
	
	decl String:query[200];
	Format(query, sizeof(query), "SELECT ip, authid, name, created, ends, length, reason, aid, adminIp, sid FROM %s_bans WHERE authid = '%s' AND (length = '0' OR ends > UNIX_TIMESTAMP())", DatabasePrefix, auth);
	SQL_TQuery(Database, SelectUnbanCallback, query, client);
	return Plugin_Handled;
}

public SelectUnbanCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// The index of the admin who issued the command is in data
	new admin = data;
	
	// If error is not an empty string the query failed
	if(error[0] != '\0')
	{
		LogToFile(logFile, "%sUnban Query Failed: %s", Prefix, error);
		if(admin && IsClientInGame(admin))
		{
			PrintToChat(admin, "sm_unban failed");
		}
		return;
	}
	
	// If there was no results then a ban does not exist for that id
	if(hndl == INVALID_HANDLE || !SQL_GetRowCount(hndl))
	{
		if(admin && IsClientInGame(admin))
		{
			PrintToChat(admin, "No active bans found for that steam id");
		} else {
			PrintToServer("No active bans found for that steam id");
		}
		return;
	}
	
	// There is ban
	if(SQL_FetchRow(hndl))
	{
		// Get the values from the existing ban record
		decl String:ip[20], String:auth[30], String:name[50], created, ends, length, String:reason[100], aid, String:adminIp[20], sid;
		SQL_FetchString(hndl, 0, ip, sizeof(ip));
		SQL_FetchString(hndl, 1, auth, sizeof(auth));
		SQL_FetchString(hndl, 2, name, sizeof(name));
		created = SQL_FetchInt(hndl, 3);
		ends = SQL_FetchInt(hndl, 4);
		length = SQL_FetchInt(hndl, 5);
		SQL_FetchString(hndl, 6, reason, sizeof(reason));
		aid = SQL_FetchInt(hndl, 7);
		SQL_FetchString(hndl, 8, adminIp, sizeof(adminIp));
		sid = SQL_FetchInt(hndl, 9);
		
		// Get the auth string for the unbanner
		decl String:unbanAuth[30];
		if(admin && IsClientInGame(admin))
		{
			GetClientAuthString(admin, unbanAuth, sizeof(unbanAuth));
		} else {
			unbanAuth = "STEAM_ID_SERVER";
		}
		
		// build a query string for the insert into banhistory
		decl String:query[1000];
		Format(query, sizeof(query), 
			"INSERT INTO %s_banhistory (type, removedon, removedby, ip, authid, name, `created`, ends, `length`, reason, adminid, adminip, sid, `country`) \
			VALUES ('U', UNIX_TIMESTAMP(), (SELECT `aid` FROM `%s_admins` WHERE `authid` = '%s'), '%s', '%s', '%s', %d, %d, %d, '%s', %d, '%s', %d, '')",
			DatabasePrefix, DatabasePrefix, unbanAuth, ip, auth, name, created, ends, length, reason, aid, adminIp, sid);
			
		// pack up the data we are going to need in the callback
		new Handle:dataPack = CreateDataPack();
		WritePackCell(dataPack, admin);
		WritePackString(dataPack, auth);
		ResetPack(dataPack);
		SQL_TQuery(Database, InsertUnbanCallback, query, dataPack);
	}
	return;
}

public InsertUnbanCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	// if the pack is good unpack it and close the handle
	new admin;
	decl String:auth[30];
	if(data != INVALID_HANDLE)
	{
		admin = ReadPackCell(data);
		ReadPackString(data, auth, sizeof(auth));
		CloseHandle(data);
	} else {
		// Technically this should not be possible
		ThrowError("Invalid Handle in InsertUnbanCallback");
	}
	
	// If error is not an empty string the query failed
	if(error[0] != '\0')
	{
		LogToFile(logFile, "%sUnban History Insert Failed: %s", Prefix, error);
		if(admin && IsClientInGame(admin))
		{
			PrintToChat(admin, "sm_unban failed");
		}
		return;
	}
	
	// If there is no error then we proceed with the delete
	decl String:query[200];
	Format(query, sizeof(query), "DELETE FROM %s_bans WHERE authid = '%s'", DatabasePrefix, auth);
	SQL_TQuery(Database, ErrorCheckCallback, query);
	if(admin && IsClientInGame(admin))
	{
		PrintToChat(admin, "%s successfully unbanned", auth);
	} else {
		PrintToServer("%s successfully unbanned", auth);
	}
}

public Action:CommandAddBan(client, args)
{
	// Block admin_and tell them they must insert it via web interface
	ReplyToCommand(client, "%s%t", Prefix, "Can Not Add Ban", WebsiteAddress);
	return Plugin_Handled;
}

static InitializeConfigParser()
{
	if (ConfigParser == INVALID_HANDLE)
	{
		ConfigParser = SMC_CreateParser();
		SMC_SetReaders(ConfigParser, ReadConfig_NewSection, ReadConfig_KeyValue, ReadConfig_EndSection);
	}
}

ReadConfig()
{
	InitializeConfigParser();

	if (ConfigParser == INVALID_HANDLE)
	{
		return;
	}

	decl String:ConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigFile, sizeof(ConfigFile), "configs/sourcebans/sourcebans.cfg");

	if(FileExists(ConfigFile))
	{
		InternalReadConfig(ConfigFile);
		PrintToServer("[SourceBans] Loading configs/sourcebans.cfg config file");
	} else {
		decl String:Error[PLATFORM_MAX_PATH + 64];
		FormatEx(Error, sizeof(Error), "%sFATAL *** ERROR *** can not find %s", Prefix, ConfigFile);
		LogToFile(logFile, "%sFATAL *** ERROR *** can not find %s", Prefix, ConfigFile);
		SetFailState(Error);
	}
}

static InternalReadConfig(const String:path[])
{
	ConfigState = ConfigStateNone;

	new SMCError:err = SMC_ParseFile(ConfigParser, path);

	if (err != SMCError_Okay)
	{
		decl String:buffer[64];
		if (SMC_GetErrorString(err, buffer, sizeof(buffer)))
		{
			PrintToServer("%s", buffer);
		} else {
			PrintToServer("Fatal parse error");
		}
	}
}

public SMCResult:ReadConfig_NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	if(name[0])
	{
		if(strcmp("Config", name, false) == 0)
		{
			ConfigState = ConfigStateConfig;
		} else if(strcmp("BanReasons", name, false) == 0) {
			ConfigState = ConfigStateReasons;
		} else if(strcmp("HackingReasons", name, false) == 0) {
			ConfigState = ConfigStateHacking;
		}
	}
	return SMCParse_Continue;
}

public SMCResult:ReadConfig_KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if(!key[0])
		return SMCParse_Continue;

	switch(ConfigState)
	{
		case ConfigStateConfig:
		{
			if(strcmp("website", key, false) == 0)
			{
				strcopy(WebsiteAddress, sizeof(WebsiteAddress), value);
			} else if(strcmp("Addban", key, false) == 0) 
			{
				if(StringToInt(value) == 0)
				{
					CommandDisable |= DISABLE_ADDBAN;
				}
			}
			else if(strcmp("AutoAddServer", key, false) == 0)
			{
				if(StringToInt(value) == 1)
					AutoAdd = true;
				else
					AutoAdd = false;
			} else if(strcmp("Unban", key, false) == 0) 
			{
				if(StringToInt(value) == 0)
				{
					CommandDisable |= DISABLE_UNBAN;
				}
			}
			else if( strcmp("IgnoreHostIp", key, false) == 0 )
			{
				if(StringToInt(value) == 1)
				{
					useHostIp = false;
				}
				else
				{
					useHostIp = true;
				}

			}
			else if(strcmp("ServerIP", key, false) == 0) 
			{
				strcopy(ServerIp, sizeof(ServerIp), value);

			} 
			else if(strcmp("ServerPort", key, false) == 0) 
			{
				strcopy(ServerPort, sizeof(ServerPort), value);
			}
			else if(strcmp("DatabasePrefix", key, false) == 0) 
			{
				strcopy(DatabasePrefix, sizeof(DatabasePrefix), value);

				if(DatabasePrefix[0] == '\0')
				{
					DatabasePrefix = "sb";
				}
			} 
			else if(strcmp("RetryTime", key, false) == 0) 
			{
				RetryTime	= StringToFloat(value);
				if(RetryTime < 16.0)
				{
					RetryTime = 15.0;
				} else if(RetryTime > 60.0) {
					RetryTime = 60.0;
				}
			} 
			else if(strcmp("ProcessQueueTime", key, false) == 0) 
			{
				ProcessQueueTime = StringToInt(value);
			}
			else if(strcmp("BackupConfigs", key, false) == 0)
			{
				if(StringToInt(value) == 1)
					backupConfig = true;
				else
					backupConfig = false;
			}
			else if(strcmp("EnableAdmins", key, false) == 0)
			{
				if(StringToInt(value) == 1)
					enableAdmins = true;
				else
					enableAdmins = false;
			}
		}

		case ConfigStateReasons:
		{
			if(ReasonMenuHandle != INVALID_HANDLE && ConfigCounter++ < 10)
			{
				AddMenuItem(ReasonMenuHandle, key, value);
			}
		}
		case ConfigStateHacking:
		{
			if(HackingMenuHandle != INVALID_HANDLE && HackingConfigCounter++ < 10)
			{
				AddMenuItem(HackingMenuHandle, key, value);
			}
		}
	}
	return SMCParse_Continue;
}

public SMCResult:ReadConfig_EndSection(Handle:smc)
{
	return SMCParse_Continue;
}

ResetMenu()
{
	if(ReasonMenuHandle != INVALID_HANDLE)
	{
		RemoveAllMenuItems(ReasonMenuHandle);
	}
}

public ReasonSelected(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[128];
		decl String:key[64];
		GetMenuItem(menu, param2, key, sizeof(key), _, info, sizeof(info));

		if(g_BanTarget[param1] != -1)
			PrepareBan(param1, g_BanTarget[param1], g_BanTime[param1], info, sizeof(info));

			
		if(StrEqual("Hacking", key))
		{
			DisplayMenu(HackingMenuHandle, param1, MENU_TIME_FOREVER);
			return;
		}
		
		new Handle:Pack = PlayerDataPack[param1];

		if(Pack == INVALID_HANDLE)
		{
			PrintToChat(param1, "%sFailure to ban the client. Please retry to ban the client.", Prefix);
			return;
		}

		SetPackPosition(Pack, 40);
		new Handle:ReasonPack = Handle:ReadPackCell(Pack);
		ResetPack(Pack);

		WritePackString(ReasonPack, info);
		ResetPack(ReasonPack);

		/* Pack */
		BanFromMenu(INVALID_HANDLE, Pack);

	} else if (action == MenuAction_Cancel && param2 == MenuCancel_Disconnected) {

		new Handle:Pack = PlayerDataPack[param1];

		if(Pack != INVALID_HANDLE)
		{
			SetPackPosition(Pack, 40);
			new Handle:ReasonPack = Handle:ReadPackCell(Pack);

			if(ReasonPack != INVALID_HANDLE)
			{
				CloseHandle(ReasonPack);
			}

			CloseHandle(Pack);
			PlayerDataPack[param1] = INVALID_HANDLE;
		}
	}
}

public HackingSelected(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:info[128];
		decl String:key[64];
		GetMenuItem(menu, param2, key, sizeof(key), _, info, sizeof(info));

		new Handle:Pack = PlayerDataPack[param1];

		if(Pack == INVALID_HANDLE)
		{
			PrintToChat(param1, "%sFailure to ban the client. Please retry to ban the client.", Prefix);
			return;
		}

		SetPackPosition(Pack, 40);
		new Handle:ReasonPack = Handle:ReadPackCell(Pack);
		ResetPack(Pack);

		WritePackString(ReasonPack, info);
		ResetPack(ReasonPack);

		/* Pack */
		BanFromMenu(INVALID_HANDLE, Pack);

	} else if (action == MenuAction_Cancel && param2 == MenuCancel_Disconnected) {

		new Handle:Pack = PlayerDataPack[param1];

		if(Pack != INVALID_HANDLE)
		{
			SetPackPosition(Pack, 40);
			new Handle:ReasonPack = Handle:ReadPackCell(Pack);

			if(ReasonPack != INVALID_HANDLE)
			{
				CloseHandle(ReasonPack);
			}

			CloseHandle(Pack);
			PlayerDataPack[param1] = INVALID_HANDLE;
		}
	}
}

public OnClientDisconnect(client)
{
	if(PlayerRecheck[client] != INVALID_HANDLE)
	{
		KillTimer(PlayerRecheck[client]);
		PlayerRecheck[client] = INVALID_HANDLE;
	}
}

public Action:PruneBans(Handle:timer)
{
	decl String:Query[512];
	FormatEx(Query, sizeof(Query), "INSERT INTO `%s_banhistory` (`Type` , `RemovedOn` , `RemovedBy` , `IP` , `AuthId` , `Name` , `Created` , `Ends` , `Length` , `Reason` , `AdminId` , `AdminIp` , `SId`) SELECT 'E', UNIX_TIMESTAMP(), '0', `ip` , `authid` , `name` , `Created` , `Ends` , `Length` , `Reason` , `aid` , `adminIp` , `sid` FROM `%s_bans` WHERE `Length` != '0' AND `Ends` < UNIX_TIMESTAMP()", DatabasePrefix, DatabasePrefix);
	SQL_TQuery(Database, DoBanPrune, Query);

	return Plugin_Continue;
}

public DoBanPrune(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogMessage("%sQuery failed! %s", Prefix, error);
		LogToFile(logFile, "Query failed! %s", error);
		return;
	}

	decl String:Query[512];
	FormatEx(Query, sizeof(Query), "DELETE FROM `%s_bans` WHERE `Length` != '0' AND `Ends` < UNIX_TIMESTAMP()", DatabasePrefix);
	SQL_TQuery(Database, ErrorCheckCallback, Query);
}

public AdminsDone(Handle:owner, Handle:hndl, const String:error[], any:data)
{
 	//SELECT authid, srv_password , srv_group, srv_flags, user
	if (hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogMessage("Failed to retrieve admins from the database, %s",error);
		LogToFile(logFile, "Failed to retrieve admins from the database %s", error);
		return;
	}
	new String:authType[] = "steam";
	new String:identity[66];
	new String:password[66];
	new String:groups[256];
	new String:flags[32];
	new String:name[66];
	new admCount=0;
	new Immunity=0;
	new AdminId:curAdm = INVALID_ADMIN_ID;
	
	while (SQL_MoreRows(hndl))
	{
		SQL_FetchRow(hndl);
		if(SQL_IsFieldNull(hndl, 0))
			continue;  // Sometimes some rows return NULL due to some setups
			
		SQL_FetchString(hndl,0,identity,66);
		SQL_FetchString(hndl,1,password,66);
		SQL_FetchString(hndl,2,groups,256);
		SQL_FetchString(hndl,3,flags,32);
		SQL_FetchString(hndl,4,name,66);

		Immunity = SQL_FetchInt(hndl,5);
		
		TrimString(name);
		TrimString(identity);
		TrimString(groups);
		TrimString(flags);

		// Disable writing to file if they chose to
		if(backupConfig)
		{
			KvSetSectionName(adminsKV, "Admins");
			KvJumpToKey(adminsKV, name, true);
			
			KvSetString(adminsKV, "auth", "steam");
			KvSetString(adminsKV, "identity", identity);
			
			if(strlen(flags) > 1)
				KvSetString(adminsKV, "flags", flags);
			
			if(strlen(groups) > 1)
				KvSetString(adminsKV, "group", groups);
		
			if(strlen(password) > 1)
				KvSetString(adminsKV, "password", password);
			
			KvSetNum(adminsKV, "immunity", Immunity);
			
			KvRewind(adminsKV);
			KeyValuesToFile(adminsKV, adminsLoc);
		}
		
		curAdm = CreateAdmin(name);       
		BindAdminIdentity(curAdm,authType,identity);

		SetAdminImmunityLevel(curAdm, Immunity);
		LogMessage("Admin %s (%s) has %d immunity\n", name, identity, Immunity);
		
		if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "Given %s (%s) admin", name, identity);
		
		new String:grp[64];
		new curPos = 0;
		new nextPos = 0;
		new GroupId:curGrp = INVALID_GROUP_ID;
		while ((nextPos = SplitString(groups[curPos],",",grp,64)) != -1)
		{
			curPos += nextPos;
			curGrp = FindAdmGroup(grp);
			if (curGrp == INVALID_GROUP_ID)
			{
				LogMessage("Unknown group \"%s\"",grp);
				LogToFile(logFile, "Unknown group %s",grp);
			}
			else
			{
				if (!AdminInheritGroup(curAdm,curGrp))
				{
					LogMessage("Unable to inherit group \"%s\"",grp);
					LogToFile(logFile, "Unable to inherit group \"%s\"",grp);
				}
			}
		}
		
		curGrp = FindAdmGroup(groups[curPos]);
		if (curGrp == INVALID_GROUP_ID)
		{
			LogMessage("Unknown group \"%s\"",groups[curPos]);
			LogToFile(logFile, "Unknown group \"%s\"",groups[curPos]);
		}
		else
		{
			if (!AdminInheritGroup(curAdm,curGrp))
			{
				LogMessage("Unable to inherit group \"%s\"",groups[curPos]);
				LogToFile(logFile, "Unable to inherit group \"%s\"",groups[curPos]);
			}
		}
        
		if (strlen(password) > 0)
			SetAdminPassword(curAdm, password);
        
		for (new i=0;i<strlen(flags);++i)
		{
			if (flags[i] < 'a' || flags[i] > 'z')
				continue;
				
			if (!g_FlagLetters[flags[i] - 'a'])
				continue;
				
			SetAdminFlag(curAdm, g_FlagLetters[flags[i] - 'a'],true);
		}
		++admCount;
	}
	
	if(IsPluginDebugging(pluginHandle))
		LogToFile(logFile, "[SourceBans] Finished loading %i admins.",admCount);
	LogMessage("[SourceBans] Finished loading %i admins.",admCount);
	--curLoading;
	CheckLoadAdmins();
}

public GroupsDone(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Failed to retrieve groups from the database, %s",error);
		return;
	}
	new String:grpName[128];
	new String:grpFlags[32];
	new Immunity;
	new bool:reparse = false;
	new grpCount = 0;
	
	KvRewind(groupsKV);
    
	new GroupId:curGrp = INVALID_GROUP_ID;
	while (SQL_MoreRows(hndl))
	{	
		SQL_FetchRow(hndl);
		if(SQL_IsFieldNull(hndl, 0))
			continue;  // Sometimes some rows return NULL due to some setups
		SQL_FetchString(hndl,0,grpName,128);
		SQL_FetchString(hndl,1,grpFlags,32);
		Immunity = SQL_FetchInt(hndl,2);

 		TrimString(grpName);
		TrimString(grpFlags);   
		
		if(!strcmp(grpName, " "))
			continue;
		
		curGrp = CreateAdmGroup(grpName);
		
		if(backupConfig)
		{
			KvSetSectionName(groupsKV, "Groups");
			KvJumpToKey(groupsKV, grpName, true);
			KvSetString(groupsKV, "flags", grpFlags);
			KvSetNum(groupsKV, "immunity", Immunity);
			KvRewind(groupsKV);
			KeyValuesToFile(groupsKV, groupsLoc);
		}
		
		if (curGrp == INVALID_GROUP_ID)
		{   //This occurs when the group already exists
			curGrp = FindAdmGroup(grpName);   
		}
        
		for (new i=0;i<strlen(grpFlags);++i)
		{
			if (grpFlags[i] < 'a' || grpFlags[i] > 'z')
				continue;
				
			if (!g_FlagLetters[grpFlags[i] - 'a'])
				continue;
				
			SetAdmGroupAddFlag(curGrp, g_FlagLetters[grpFlags[i] - 'a'], true);
		}
			
		SetAdmGroupImmunityLevel(curGrp, Immunity);
		LogMessage("Group %s has %d immunity\n", grpName, Immunity);
		
		if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "Loaded group: \"%s\"",grpName);
		grpCount++;
	}
	
	LogMessage("[SourceBans] Finished loading %i groups.",grpCount);
	if(IsPluginDebugging(pluginHandle))
		LogToFile(logFile, "[SourceBans] Finished loading %i groups.",grpCount);
	
	if (reparse)
	{
		new String:query[512];
		FormatEx(query,512,"SELECT name, immunity, groups_immune FROM %s_srvgroups ORDER BY id",DatabasePrefix);
		SQL_TQuery(Database,GroupsSecondPass,query);
	}
	else
	{
		curLoading--;
		CheckLoadAdmins();
	}
}

public GroupsSecondPass(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Failed to retrieve groups from the database, %s",error);
		return;
	}
	new String:grpName[128];
	new Immunity;
    
	new GroupId:curGrp = INVALID_GROUP_ID;
	while (SQL_MoreRows(hndl))
	{
		SQL_FetchRow(hndl);
		if(SQL_IsFieldNull(hndl, 0))
			continue;  // Sometimes some rows return NULL due to some setups
		SQL_FetchString(hndl,0,grpName,128);
 		TrimString(grpName);
		if(!strcmp(grpName, " "))
			continue;
		Immunity = SQL_FetchInt(hndl,1);
        
		curGrp = FindAdmGroup(grpName);
		if (curGrp == INVALID_GROUP_ID)
			curGrp = CreateAdmGroup(grpName); 
		
		SetAdmGroupImmunityLevel(curGrp, Immunity);
		LogMessage("Group %s has %d immunity\n", grpName, Immunity);
		
		if(IsPluginDebugging(pluginHandle))
			LogToFile(logFile, "Loaded group: \"%s\"",grpName);
		
	}
	--curLoading;
	CheckLoadAdmins();
}

public InitializeBackupDB()
{
	new String:error[255];
	
	SQLiteDB = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "sourcebans-queue", error, sizeof(error), true, 0);
	if(SQLiteDB == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	
		
	SQL_LockDatabase(SQLiteDB);
	SQL_FastQuery(SQLiteDB, "CREATE TABLE IF NOT EXISTS queue (steam_id TEXT PRIMARY KEY ON CONFLICT REPLACE, time INTEGER, start_time INTEGER, reason TEXT, name TEXT, ip TEXT, admin_id TEXT, admin_ip TEXT);");
	SQL_UnlockDatabase(SQLiteDB);
}

public Action:ProcessQueue(Handle:timer, any:data)
{
	decl String:buffer[512];
	Format(buffer, sizeof(buffer), "SELECT steam_id, time, start_time, reason, name, ip, admin_id, admin_ip FROM queue");
	SQL_TQuery(SQLiteDB, ProcessQueueCallback, buffer);
}

// ProcessQueueCallback is called as the result of selecting all the rows from the queue table
public ProcessQueueCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:auth[30];
	decl time;
	decl startTime;
	decl String:reason[50];
	decl String:name[40];
	decl String:ip[20];
	decl String:adminAuth[30];
	decl String:adminIp[20];
	decl String:query[1024];
	while(hndl != INVALID_HANDLE && SQL_FetchRow(hndl))
	{
		// if we get to here then there are rows in the queue pending processing
		SQL_FetchString(hndl, 0, auth, sizeof(auth));
		time = SQL_FetchInt(hndl, 1);
		startTime = SQL_FetchInt(hndl, 2);
		SQL_FetchString(hndl, 3, reason, sizeof(reason));
		SQL_FetchString(hndl, 4, name, sizeof(name));
		SQL_FetchString(hndl, 5, ip, sizeof(ip));
		SQL_FetchString(hndl, 6, adminAuth, sizeof(adminAuth));
		SQL_FetchString(hndl, 7, adminIp, sizeof(adminIp));
		if(startTime + time * 60 > GetTime())
		{
			// This ban is still valid and should be entered into the db
			FormatEx(query, sizeof(query), 
					"INSERT INTO `%s_bans` (`ip`, `authid`, `name`, `created`, `ends`, `length`, `reason`, `aid`, `adminIp`, `sid`) VALUES ('%s', '%s', \"%s\", %d, %d, '%d', '%s', (SELECT `aid` FROM `%s_admins` WHERE `authid` = '%s'), '%s', (SELECT `sid` FROM `%s_servers` WHERE `ip` = '%s' AND `port` = '%s' LIMIT 0,1))", 
					DatabasePrefix, ip, auth, name, startTime, startTime + time * 60, time * 60, reason, DatabasePrefix, adminAuth, adminIp, DatabasePrefix, ServerIp, ServerPort);
			new Handle:authPack = CreateDataPack();
			WritePackString(authPack, auth);
			ResetPack(authPack);
			SQL_TQuery(Database, AddedFromSQLiteCallback, query, authPack);
		} else {
			// The ban is no longer valid and shuld be deleted from the queue
			FormatEx(query, sizeof(query), "DELETE FROM queue WHERE steam_id = '%s'", auth);
			SQL_TQuery(SQLiteDB, ErrorCheckCallback, query);
		}
	}
	// We have finished processing the queue but should process again in ProcessQueueTime minutes
	CreateTimer(float(ProcessQueueTime * 60), ProcessQueue);
}

public AddedFromSQLiteCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:buffer[512];
	decl String:auth[40];
	ReadPackString(data, auth, sizeof(auth));
	if(error[0] == '\0')
	{
		// The insert was successful so delete the record from the queue
		FormatEx(buffer, sizeof(buffer), "DELETE FROM queue WHERE steam_id = '%s'", auth);
		SQL_TQuery(SQLiteDB, ErrorCheckCallback, buffer);
		
		// They are added to main banlist, so remove the temp ban
		RemoveBan(auth, BANFLAG_AUTO);
		
	} else {
		// the insert failed so we leave the record in the queue and increase our temporary ban
		FormatEx(buffer, sizeof(buffer), "banid %d %s", ProcessQueueTime, auth);
		ServerCommand(buffer);
	}
	CloseHandle(data);
}

public OnConfigsExecuted()
{
	decl String:filename[200];
	BuildPath(Path_SM, filename, sizeof(filename), "plugins/basebans.smx");
	if(FileExists(filename))
	{
		ServerCommand("sm plugins unload basebans");
		//SetFailState("SourceBans failed to load, plugins/basebans.smx must be moved to plugins/disables/basebans.smx");
	}
}

//Yarr!

