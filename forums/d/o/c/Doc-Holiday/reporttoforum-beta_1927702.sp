#include <sourcemod>
#include <adminmenu>
#include <regex>
//#include <reporttoforum>
//#include <updater>
#include <dbi>

new const String:PLUGIN_VERSION[] = "1.1.6-Beta";
//new const String:UPDATE_URL[] = "http://scripts.norcalbots.com/report-to-forums/raw/default/rtfupdate.txt";
const MAX_CATEGORIES = 5;

enum SupportedForums
{
	FORUM_UNSUPPORTED,
	FORUM_VB4,
	FORUM_MYBB,
	FORUM_SMF,
	FORUM_PHPBB,
	FORUM_WBBLITE,
	FORUM_AEF,
	FORUM_USEBB,
	FORUM_XMB,
	FORUM_IPBOARDS
}

/* File Paths */
new const String:g_szRootPath[] = "cfg/rtf_configs";
new String:g_szBlackListPath[PLATFORM_MAX_PATH];
new String:g_szRulesPath[PLATFORM_MAX_PATH];
new String:g_szConfigPath[PLATFORM_MAX_PATH];

/* Valve ConVars */
new Handle:g_Cvar_HostName = INVALID_HANDLE;
new Handle:g_Cvar_ServerPort = INVALID_HANDLE;
new Handle:g_Cvar_ServerIP = INVALID_HANDLE;

/* Menu ConVars */
new Handle:g_Cvar_TargetMenuTitle = INVALID_HANDLE;
new Handle:g_Cvar_MainMenuTitle = INVALID_HANDLE;
new Handle:g_Cvar_SubMenuTitle = INVALID_HANDLE;

/* Settings ConVars */
new Handle:g_Cvar_AllowCustomReports = INVALID_HANDLE;
new Handle:g_Cvar_ForumSoftwareID = INVALID_HANDLE;
new Handle:g_Cvar_ReportCmdCoolDown = INVALID_HANDLE;
new Handle:g_Cvar_AdvertInterval = INVALID_HANDLE;
new Handle:g_Cvar_ChatPrefix = INVALID_HANDLE;
new Handle:g_Cvar_AutoUpdate = INVALID_HANDLE;
new Handle:g_Cvar_Debug = INVALID_HANDLE;

/* Post Headings ConVars */
new Handle:g_Cvar_ReporterTitle = INVALID_HANDLE;
new Handle:g_Cvar_ReportedTitle = INVALID_HANDLE;
new Handle:g_Cvar_ServerInfoTitle = INVALID_HANDLE;

/* SQL ConVars */
new Handle:g_Cvar_ReporterID = INVALID_HANDLE;
new Handle:g_Cvar_ReporterUserName = INVALID_HANDLE;
new Handle:g_Cvar_ReporterEmail = INVALID_HANDLE;
new Handle:g_Cvar_ForumID = INVALID_HANDLE;
new Handle:g_Cvar_TablePrefix = INVALID_HANDLE;

/* Admin ConVars */
new Handle:g_Cvar_AdminAlert = INVALID_HANDLE;
new Handle:g_Cvar_AlertAdminNoPost = INVALID_HANDLE;

/* Menu Settings */
new g_iCategoryCount;

/* SQL Handle */
new Handle:g_hSQLDatabase = INVALID_HANDLE;

/* Menu Handles */
new Handle:g_hMainMenu = INVALID_HANDLE;
new Handle:g_hSubMenu[MAX_CATEGORIES] = {INVALID_HANDLE, ...};

/* Menu Titles */
new String:g_szMainMenuTitle[32];
new String:g_szSubMenuTitle[32];

/* Misc Data Handles */
new Handle:g_hDebugArray[MAXPLAYERS+1] = {INVALID_HANDLE, ...};
new Handle:g_hAdvertisementTimer = INVALID_HANDLE;

/* Post Heading Titles */
new String:g_szReporterTitle[64];
new String:g_szReportedTitle[64];
new String:g_szServerInfoTitle[64];

/* Target Variables */
new g_iTarget[MAXPLAYERS+1];
new String:g_szSafeTargetName[MAXPLAYERS+1][MAX_NAME_LENGTH * 2 + 1];
new String:g_szTargetName[MAXPLAYERS+1][MAX_NAME_LENGTH];
new String:g_szTargetAuthID[MAXPLAYERS+1][32];
new String:g_szTargetIP[MAXPLAYERS+1][32];
new g_iTimeStamp[MAXPLAYERS+1];

/* Post Info */
new String:g_szThreadTitle[MAXPLAYERS+1][256];
new String:g_szReason[MAXPLAYERS+1][32];
new String:g_szCategory[MAXPLAYERS+1][256];
new String:g_szSafeDescription[MAXPLAYERS+1][1024];

/* Server Info Variables */
new String:g_szMapName[32];
new String:g_szHostName[200];
new String:g_szServerPort[10];
new String:g_szServerIP[32];

/* Forum Info */
new SupportedForums:g_iForumSoftwareID;
new g_iForumID, g_iUserID;
new g_iThreadID[MAXPLAYERS+1];
new g_iPostID[MAXPLAYERS+1];
new String:g_szTablePrefix[32];
new String:g_szUserName[32];
new String:g_szEmailAddress[64];

/* Misc Variables */
new String:g_szPrefix[32];
new bool:g_bIsUserAdmin[MAXPLAYERS+1];
new g_iAdminCount;

public Plugin:myinfo = 
{
	name = "Report To Forums Beta",
	author = "SavSin",
	description = "Report players to your forums from your game server.",
	version = PLUGIN_VERSION,
	url = "http://www.norcalbots.com/"
};

public OnPluginStart()
{
	/* Public Version Convar */
	CreateConVar("rtf_version", PLUGIN_VERSION, "Version of Report to Forums", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	/* Register Console Command */
	RegConsoleCmd("sm_report", Command_SMReport, "Report a player to the forums.");
	
	/* Register Admin Commands */
	RegAdminCmd("rtf_blacklist", Command_Blacklist, ADMFLAG_BAN, "Blacklist a player using the sm_report command.");
	RegAdminCmd("rtf_unblacklist", Command_UnBlacklist, ADMFLAG_UNBAN, "unblacklist a player.");
	RegAdminCmd("rtf_send_report", Command_SendReport, ADMFLAG_BAN, "Sends the report menu to a player.");
	
	/* Board Settings */
	g_Cvar_ForumSoftwareID = CreateConVar("rtf_forum_software_id", "", "Which board you use? Visit https://bitbucket.org/norcalbots/report-to-forums/wiki/Supported%20Forums");
	
	/*Forum Info */
	g_Cvar_TablePrefix = CreateConVar("rtf_table_prefix", "", "Table prefix.");
	g_Cvar_ForumID = CreateConVar("rtf_forum_id", "", "Forum ID to the specific forum you want the reports sent to.");
	g_Cvar_ReporterID = CreateConVar("rtf_reporter_id", "", "Userid for the Reporter User.");
	g_Cvar_ReporterUserName = CreateConVar("rtf_reporter_username", "", "Username for the reporter.");
	g_Cvar_ReporterEmail = CreateConVar("rtf_reporter_email", "", "E-Mail address for the reporter.");
	
	/* Menu Titles */
	g_Cvar_TargetMenuTitle = CreateConVar("rtf_targetmenu_title", "", "Title to the target menu.");
	g_Cvar_MainMenuTitle = CreateConVar("rtf_mainmenu_title", "", "Title to the main category menu.");
	g_Cvar_SubMenuTitle = CreateConVar("rtf_submenu_title", "", "Title to the reason selection menu.");
	
	/* Settings */
	g_Cvar_AllowCustomReports = CreateConVar("rtf_allow_custom_reports", "", "Allow users to create custom reports using sm_report <name|steamid|ip> <reason>.");
	g_Cvar_ChatPrefix = CreateConVar("rtf_prefix", "", "Prefix added to the beging of the plugin generated say messages.");
	g_Cvar_ReportCmdCoolDown = CreateConVar("rtf_cmd_cooldown", "", "Time in seconds between reports (per user).");
	g_Cvar_AdvertInterval = CreateConVar("rtf_advertisement_frequency", "", "Time in seconds to display the advertisement. 0 turns off the advertisement.");
	g_Cvar_AutoUpdate = CreateConVar("rtf_auto_update", "", "Use updater to keep the plugin uptodate.");
	g_Cvar_Debug = CreateConVar("rtf_debug", "", "Enables this if you are having trouble.");
	
	/* Post Headings */
	g_Cvar_ReporterTitle = CreateConVar("rtf_reporter_title", "", "Reporter Heading");
	g_Cvar_ReportedTitle = CreateConVar("rtf_reported_title", "", "Reported Heading");
	g_Cvar_ServerInfoTitle = CreateConVar("rtf_serverinfo_title", "", "Server Info Heading");
	
	/* Admin Settings */
	g_Cvar_AdminAlert = CreateConVar("rtf_admin_alert", "", "Alert in game of the player that was reported and the reason");
	g_Cvar_AlertAdminNoPost = CreateConVar("rtf_admin_nopost", "", "Block posts to the forum if there is an admin in game.");
	
	/* Valve ConVars */
	g_Cvar_HostName = FindConVar("hostname");
	g_Cvar_ServerPort = FindConVar("hostport");
	g_Cvar_ServerIP = FindConVar("ip");
	
	/* Format File Paths */
	Format(g_szBlackListPath, sizeof(g_szBlackListPath), "%s/rtf-blacklist.txt", g_szRootPath);
	Format(g_szRulesPath, sizeof(g_szRulesPath), "%s/rtf-rules.txt", g_szRootPath);
	Format(g_szConfigPath, sizeof(g_szConfigPath), "%s/rtfsettings.cfg", g_szRootPath);
	
	/* Hook Advertisement ConVar */
	HookConVarChange(g_Cvar_AdvertInterval, OnAdvertisementChange);
	
	/* Hook Autoupdater ConVar */
	//HookConVarChange(g_Cvar_AutoUpdate, OnAutoUpdateChange);
	
	/* Create Menu Handles */
	g_hMainMenu = CreateMenu(MainMenuHandler);
	
	for(new i=0; i < MAX_CATEGORIES; i++)
	{
		g_hSubMenu[i] = CreateMenu(SubMenuHandler);
	}
	
	if(FileExists(g_szConfigPath))
		ServerCommand("exec rtf_configs/rtfsettings.cfg");
	else
		LogError("Settings Config is Missing.");
		
	/* Connect to the Database */
	if(!SQL_CheckConfig("rtfsettings"))
		LogError("SQL Config not found. Check your databses.cfg");
	else
		SQL_TConnect(MySQL_ConnectionCallback, "rtfsettings");
		
	/* Read The Rules File and Genearte the menus */
	if(FileExists(g_szRulesPath))
	{
		new Handle:smc = SMC_CreateParser();
		SMC_SetReaders(smc, NewSection, KeyValue, EndSection);
		new SMCError:error = SMC_ParseFile(smc, g_szRulesPath);
		
		g_iCategoryCount = 0;
		
		if(error != SMCError_Okay)
		{
			new String:szBuffer[255];
			if(SMC_GetErrorString(error, szBuffer, sizeof(szBuffer)))
			{
				LogError("%s", szBuffer);
			}
		}
		
		CloseHandle(smc);
	}
	else
	{
		LogError("Missing rtf-rules.txt. Check Dir: %s", g_szRootPath);
	}
}

/* Updater Settings On Late Load 
public OnLibraryAdded(const String:szName[])
{
	if(StrEqual(szName, "updater") && GetConVarBool(g_Cvar_AutoUpdate))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}*/

public OnConfigsExecuted()
{
	/* Add Auto Updater URL
	if(LibraryExists("updater") && GetConVarBool(g_Cvar_AutoUpdate))
	{
		Updater_AddPlugin(UPDATE_URL);
	}*/
	
	/* Set the Forum Software ID */
	g_iForumSoftwareID = SupportedForums:GetConVarInt(g_Cvar_ForumSoftwareID);
		
	/* Get Prefix Name */
	GetConVarString(g_Cvar_ChatPrefix, g_szPrefix, sizeof(g_szPrefix));
	
	/* Get Table Prefix */
	GetConVarString(g_Cvar_TablePrefix, g_szTablePrefix, sizeof(g_szTablePrefix));
	
	/* Get Reporter UserName */
	GetConVarString(g_Cvar_ReporterUserName, g_szUserName, sizeof(g_szUserName));
	
	/* Get Reporter Email Address */
	GetConVarString(g_Cvar_ReporterEmail, g_szEmailAddress, sizeof(g_szEmailAddress));
	
	/* Get Heading Names */
	GetConVarString(g_Cvar_ReporterTitle, g_szReporterTitle, sizeof(g_szReporterTitle));
	GetConVarString(g_Cvar_ReportedTitle, g_szReportedTitle, sizeof(g_szReportedTitle));
	GetConVarString(g_Cvar_ServerInfoTitle, g_szServerInfoTitle, sizeof(g_szServerInfoTitle));
	
	/* Cache Reporter Id */
	g_iUserID = GetConVarInt(g_Cvar_ReporterID);
	
	/* Cache ForumID */
	g_iForumID = GetConVarInt(g_Cvar_ForumID);
	
	/* Cache Hostname */
	GetConVarString(g_Cvar_HostName, g_szHostName, sizeof(g_szHostName));
	
	/* Cache Map Name */
	GetCurrentMap(g_szMapName, sizeof(g_szMapName));
	
	/* Cache Server IP */
	GetConVarString(g_Cvar_ServerIP, g_szServerIP, sizeof(g_szServerIP));
	
	/* Cache Server Port */
	GetConVarString(g_Cvar_ServerPort, g_szServerPort, sizeof(g_szServerPort));
	
	/* Format Menu Titles */
	GetConVarString(g_Cvar_MainMenuTitle, g_szMainMenuTitle, sizeof(g_szMainMenuTitle));
	GetConVarString(g_Cvar_SubMenuTitle, g_szSubMenuTitle, sizeof(g_szSubMenuTitle));
	
	/* Set Menu Titles */
	SetMenuTitle(g_hMainMenu, g_szMainMenuTitle);
	
	for(new i=0; i < MAX_CATEGORIES; i++)
	{
		SetMenuTitle(g_hSubMenu[i], g_szSubMenuTitle);
	}
	
	if(StrContains(g_szMapName, "workshop", false) != -1)
	{
		decl String:szWorkShopID[32];
		GetCurrentWorkshopMap(g_szMapName, sizeof(g_szMapName), szWorkShopID, sizeof(szWorkShopID));
	}
	
	/* Start Advertisement Timer */
	if(GetConVarBool(g_Cvar_AdvertInterval) && g_hAdvertisementTimer == INVALID_HANDLE)
	{
		g_hAdvertisementTimer = CreateTimer(GetConVarFloat(g_Cvar_AdvertInterval), Timer_ShowAdvertisement, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public OnAdvertisementChange(Handle:hConVar, const String:szOldValue[], const String:szNewValue[])
{
	new Float:flAdvertInterval = StringToFloat(szNewValue);
	
	if(flAdvertInterval > 0)
	{
		g_hAdvertisementTimer = CreateTimer(flAdvertInterval, Timer_ShowAdvertisement, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		KillTimer(g_hAdvertisementTimer);
		g_hAdvertisementTimer = INVALID_HANDLE;
	}
}
/*
public OnAutoUpdateChange(Handle:hConVar, const String:szOldValue[], const String:szNewValue[])
{
	new iNewValue = StringToInt(szNewValue);
	
	if(iNewValue)
	{
		Updater_AddPlugin(UPDATE_URL);
	}
	else
	{
		Updater_RemovePlugin();
	}
}
*/
public OnMapEnd()
{
	g_hAdvertisementTimer = INVALID_HANDLE;
}

public Action:Timer_ShowAdvertisement(Handle:hTimer, any:data)
{
	/* Advertisement Text */
	PrintToChatAll("[%s] Type !report in chat or sm_report in console to report a player for breaking the rules.", g_szPrefix);
}

public OnClientPostAdminCheck(iClient)
{
	if(CheckCommandAccess(iClient, "sm_report", ADMFLAG_KICK, true))
	{
		++g_iAdminCount;
		g_bIsUserAdmin[iClient] = true;
	}
}

public OnClientDisconnect(iClient)
{
	if(g_bIsUserAdmin[iClient])
	{
		--g_iAdminCount;
		g_bIsUserAdmin[iClient] = false;
	}
}

public Action:Command_SendReport(iClient, iArgs)
{
	decl String:szTargetName[MAX_NAME_LENGTH], String:szArgTarget[MAX_NAME_LENGTH];
	new iTargetCount, iTargetList[MAXPLAYERS], bool:tn_is_ml;
	
	if(iArgs < 1)
	{
		ReplyToCommand(iClient, "[%s] ERROR Usage: rtf_send_report <name>", g_szPrefix);
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, szArgTarget, sizeof(szArgTarget));
		iTargetCount = ProcessTargetString(szArgTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS, szTargetName, sizeof(szTargetName), tn_is_ml);
		
		if(iTargetCount <= 0)
		{
			ReplyToCommand(iClient, "[%s] No target matching %s", g_szPrefix, szArgTarget);
			return Plugin_Handled;
		}
		else if(iTargetCount > 1)
		{
			ReplyToCommand(iClient, "[%s] More than 1 targets matching %s", g_szPrefix, szArgTarget);
			return Plugin_Handled;
		}
	}
	
	if(!CanUserTarget(iClient, iTargetList[0]))
	{
		ReplyToCommand(iClient, "[%s] You cannot target this client.", g_szPrefix);
		return Plugin_Handled;
	}
	
	DisplayTargetSelectionMenu(iTargetList[0]);
	ReplyToCommand(iClient, "[%s] Sucessfully sent the menu to %s.", szTargetName);
	return Plugin_Handled;
}
	

public Action:Command_ReloadRules(iClient, iArgs)
{
	/* Clear All Menu Items */
	RemoveAllMenuItems(g_hMainMenu);
	
	for(new i=0; i < MAX_CATEGORIES; i++)
	{
		RemoveAllMenuItems(g_hSubMenu[i]);
	}
	
	/* Read The Rules File and regenearte the menus */
	if(FileExists(g_szRulesPath))
	{
		new Handle:smc = SMC_CreateParser();
		SMC_SetReaders(smc, NewSection, KeyValue, EndSection);
		new SMCError:error = SMC_ParseFile(smc, g_szRulesPath);
		
		g_iCategoryCount = 0;
		
		if(error != SMCError_Okay)
		{
			new String:szBuffer[255];
			if(SMC_GetErrorString(error, szBuffer, sizeof(szBuffer)))
			{
				LogError("%s", szBuffer);
			}
		}
		
		CloseHandle(smc);
	}
	else
	{
		LogError("Missing rtf-rules.txt. Check Dir: %s", g_szRootPath);
	}
	
	ReplyToCommand(iClient, "[%s] Menu's Have been reloaded", g_szPrefix);
}

public Action:Command_Blacklist(iClient, iArgs)
{
	decl String:szTargetName[MAX_NAME_LENGTH], String:szArgTarget[MAX_NAME_LENGTH], String:szArgReason[256];
	new iTargetCount, iTargetList[MAXPLAYERS], bool:tn_is_ml;
	
	if(iArgs >= 2)
	{
		GetCmdArg(1, szArgTarget, sizeof(szArgTarget));
		GetCmdArg(2, szArgReason, sizeof(szArgReason));
		iTargetCount = ProcessTargetString(szArgTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS, szTargetName, sizeof(szTargetName), tn_is_ml);
		
		if(iTargetCount <= 0)
		{
			if(StrContains(szArgTarget, "STEAM_", false))
			{
				AddPlayerToBlackList(szArgTarget, "", szArgReason);
				ReplyToCommand(iClient, "[%s] Added STEAM_ID %s to the black list.", g_szPrefix, szArgTarget);
				return Plugin_Handled;
			}
			else
			{
				ReplyToCommand(iClient, "[%s] No target matching %s", g_szPrefix, szArgTarget);
				return Plugin_Handled;
			}
		}
		else if(iTargetCount > 1)
		{
			ReplyToCommand(iClient, "[%s] More than 1 targets matching %s", g_szPrefix, szArgTarget);
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(iClient, "[%s] ERROR Usage: rtf_blacklist <name|steamid|ip> <reason>", g_szPrefix);
		return Plugin_Handled;
	}
	
	if(!CanUserTarget(iClient, iTargetList[0]))
	{
		ReplyToCommand(iClient, "[%s] You cannot target this client.", g_szPrefix);
		return Plugin_Handled;
	}
	
	decl String:szAuthID[32];
	GetClientAuthString(iTargetList[0], szAuthID, sizeof(szAuthID));
	AddPlayerToBlackList(szAuthID, szTargetName, szArgReason);
	
	ShowActivity2(iClient, "[SM] ", "%N Added %s to the blacklist", iClient, szTargetName);
	return Plugin_Handled;
}

public Action:Command_UnBlacklist(iClient, iArgs)
{
	decl String:szTargetName[MAX_NAME_LENGTH], String:szArgTarget[MAX_NAME_LENGTH];
	new iTargetCount, iTargetList[MAXPLAYERS], bool:tn_is_ml;
	
	if(iArgs >= 1)
	{
		GetCmdArg(1, szArgTarget, sizeof(szArgTarget));
		iTargetCount = ProcessTargetString(szArgTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS, szTargetName, sizeof(szTargetName), tn_is_ml);
		
		if(iTargetCount <= 0)
		{
			if(StrContains(szArgTarget, "STEAM_", false))
			{
				RemPlayerToBlackList(szArgTarget);
				ReplyToCommand(iClient, "[%s] Removed STEAM_ID %s from the black list.", g_szPrefix, szArgTarget);
				return Plugin_Handled;
			}
			else
			{
				ReplyToCommand(iClient, "[%s] No target matching %s", g_szPrefix, szArgTarget);
				return Plugin_Handled;
			}
		}
		else if(iTargetCount > 1)
		{
			ReplyToCommand(iClient, "[%s] More than 1 targets matching %s", g_szPrefix, szArgTarget);
			return Plugin_Handled;
		}
	}
	else
	{
		ReplyToCommand(iClient, "[%s] ERROR Usage: rtf_unblacklist <name|steamid|ip>", g_szPrefix);
		return Plugin_Handled;
	}
	
	decl String:szAuthID[32];
	GetClientAuthString(iTargetList[0], szAuthID, sizeof(szAuthID));
	
	if(RemPlayerToBlackList(szAuthID))
	{
		ShowActivity2(iClient, "[SM] ", "%N Removed %s to the blacklist", iClient, szTargetName);
	}
	else
	{
		ReplyToCommand(iClient, "[%s] Error removing client from the blacklist", g_szPrefix);
	}
	
	return Plugin_Handled;
}

public Action:Command_SMReport(iClient, iArgs)
{
	decl String:szAuthID[32];
	GetClientAuthString(iClient, szAuthID, sizeof(szAuthID));
	
	if(IsUserBlacklisted(szAuthID))
	{
		ReplyToCommand(iClient, "[%s] You have been baned from using this command.", g_szPrefix);
		return Plugin_Handled;
	}
	
	new iCurTime = GetTime();
	if((iCurTime - g_iTimeStamp[iClient]) < GetConVarInt(g_Cvar_ReportCmdCoolDown))
	{
		new iTimeLeft = (GetConVarInt(g_Cvar_ReportCmdCoolDown) - (iCurTime - g_iTimeStamp[iClient]));
		PrintToChat(iClient, "[%s] You must wait %d more seconds to use this command again.", g_szPrefix, iTimeLeft);
	}
	else
	{
		/* Check Debug Settings */
		if(GetConVarBool(g_Cvar_Debug) && g_hDebugArray[iClient] == INVALID_HANDLE)
			g_hDebugArray[iClient] = CreateArray(1024);
			
		if(iArgs >= 1)
		{
			decl String:szTargetName[MAX_NAME_LENGTH], String:szArgTarget[MAX_NAME_LENGTH];
			new iTargetCount, iTargetList[MAXPLAYERS], bool:tn_is_ml;
			
			GetCmdArg(1, szArgTarget, sizeof(szArgTarget));
			
			/* Process the Target */
			iTargetCount = ProcessTargetString(szArgTarget, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS, szTargetName, sizeof(szTargetName), tn_is_ml);
			
			if(iTargetCount <= 0)
			{
				ReplyToCommand(iClient, "[%s] No target matching %s", g_szPrefix, szArgTarget);
				return Plugin_Handled;
			}
			else if(iTargetCount > 1)
			{
				ReplyToCommand(iClient, "[%s] More than 1 targets matching %s", g_szPrefix, szArgTarget);
				return Plugin_Handled;
			}
			
			/* Get Target Info */
			g_iTimeStamp[iClient] = GetTime();
			g_iTarget[iClient] = iTargetList[0];
			ParsePlayerName(szTargetName, g_szSafeTargetName[iClient], sizeof(g_szSafeTargetName[]));
			GetClientAuthString(g_iTarget[iClient], g_szTargetAuthID[iClient], sizeof(g_szTargetAuthID[]));
			GetClientIP(g_iTarget[iClient], g_szTargetIP[iClient], sizeof(g_szTargetIP[]));
			
			if(iArgs >= 2 && GetConVarBool(g_Cvar_AllowCustomReports))
			{
				decl String:szReason[256];
				GetCmdArg(2, szReason, sizeof(szReason));
				SQL_EscapeString(g_hSQLDatabase, szReason, g_szSafeDescription[iClient], sizeof(g_szSafeDescription[]));
				strcopy(g_szReason[iClient], sizeof(g_szReason[]), "Custom Report");
				
				if(GetConVarBool(g_Cvar_AdminAlert))
				{
					AlertAdmins(iClient);
				}
				
				if(!GetConVarBool(g_Cvar_AlertAdminNoPost) && GetConVarBool(g_Cvar_AdminAlert))
					CreateReportThread(iClient);
					
				return Plugin_Handled;
			}
			
			DisplayMenu(g_hMainMenu, iClient, MENU_TIME_FOREVER);
		}
		else
		{
			DisplayTargetSelectionMenu(iClient);
		}
	}
	return Plugin_Handled;
}

public DisplayTargetSelectionMenu(iClient)
{
	/* Set up and Display the Target Menu */
	decl String:szMenuTitle[32];
	GetConVarString(g_Cvar_TargetMenuTitle, szMenuTitle, sizeof(szMenuTitle));
	new Handle:hMenu = CreateMenu(TargetMenuHandler);
	SetMenuTitle(hMenu, szMenuTitle);
	AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS);
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public MySQL_ConnectionCallback(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase != INVALID_HANDLE)
		g_hSQLDatabase = hDatabase;
	else
		LogError("Failed To Connect: %s", szError);
}

public SMC_ParseStart(Handle:smc)
{
}

public SMCResult:NewSection(Handle:smc, const String:szSection[], bool:opt_quotes)
{
	/* Get the Section names of each SubSection*/
	if(!StrEqual("Report To Forums", szSection, false))
	{
		decl String:szTempString[1024];
		Format(szTempString, sizeof(szTempString), "%d|%s", g_iCategoryCount, szSection);
		AddMenuItem(g_hMainMenu, szTempString, szSection);
	}
}

public SMCResult:KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	decl String:szTempString[1024];
	Format(szTempString, sizeof(szTempString), "%s|%s", key, value);
	AddMenuItem(g_hSubMenu[g_iCategoryCount], szTempString, key);
}

/* Increase the Category ID when before going to the next category. */
public SMCResult:EndSection(Handle:smc)
{
	++g_iCategoryCount;
}

public TargetMenuHandler(Handle:hMenu, MenuAction:iAction, iClient, iItem)
{
	if(iAction == MenuAction_Select)
	{
		decl String:szMenuItem[3];
		GetMenuItem(hMenu, iItem, szMenuItem, sizeof(szMenuItem));
		g_iTarget[iClient] = GetClientOfUserId(StringToInt(szMenuItem));
		
		/* Get Target Info */
		decl String:szTargetName[MAX_NAME_LENGTH];
		g_iTimeStamp[iClient] = GetTime();
		GetClientName(g_iTarget[iClient], szTargetName, sizeof(szTargetName));
		ParsePlayerName(szTargetName, g_szSafeTargetName[iClient], sizeof(g_szSafeTargetName[]));
		GetClientAuthString(g_iTarget[iClient], g_szTargetAuthID[iClient], sizeof(g_szTargetAuthID[]));
		GetClientIP(g_iTarget[iClient], g_szTargetIP[iClient], sizeof(g_szTargetIP[]));
		
		/* Display Main Menu */
		DisplayMenu(g_hMainMenu, iClient, MENU_TIME_FOREVER);
	}
}

 public MainMenuHandler(Handle:hMenu, MenuAction:iAction, iClient, iItem)
 {
	if(iAction == MenuAction_Select)
	{
		decl String:szMenuItem[1024], String:szMenuItemsSplit[2][1024];
		GetMenuItem(hMenu, iItem, szMenuItem, sizeof(szMenuItem));
		ExplodeString(szMenuItem, "|", szMenuItemsSplit, 2, sizeof(szMenuItemsSplit[]));
		
		if(StrContains(szMenuItemsSplit[1], "admin", false) != -1 && !g_bIsUserAdmin[g_iTarget[iClient]])
		{
			PrintToChat(iClient, "[%s] The target you selected is not an admin.", g_szPrefix);
			DisplayMenu(g_hMainMenu, iClient, MENU_TIME_FOREVER);
		}
		else
		{
			strcopy(g_szCategory[iClient], sizeof(g_szCategory[]), szMenuItemsSplit[1]);
			DisplayMenu(g_hSubMenu[StringToInt(szMenuItemsSplit[0])], iClient, MENU_TIME_FOREVER);
		}
	}
 }
 
 public SubMenuHandler(Handle:hMenu, MenuAction:iAction, iClient, iItem)
 {
	if(iAction == MenuAction_Select)
	{
		decl String:szMenuItem[1024], String:szMenuItemsSplit[2][1024];
		GetMenuItem(hMenu, iItem, szMenuItem, sizeof(szMenuItem));
		ExplodeString(szMenuItem, "|", szMenuItemsSplit, 2, sizeof(szMenuItemsSplit[]));
		
		strcopy(g_szReason[iClient], sizeof(g_szReason[]), szMenuItemsSplit[0]);
		strcopy(g_szSafeDescription[iClient], sizeof(g_szSafeDescription[]), szMenuItemsSplit[1]);
		
		if(!GetConVarBool(g_Cvar_AlertAdminNoPost) && GetConVarBool(g_Cvar_AdminAlert))
			CreateReportThread(iClient);
		else
			AlertAdmins(iClient);
	}
 }
 
 /* SQL Stuff */
public CreateReportThread(iClient)
{
	Format(g_szThreadTitle[iClient], sizeof(g_szThreadTitle[]), "%s - %s", g_szTargetAuthID[iClient], g_szReason[iClient]);
	
	decl String:szSQLQuery[512];
	
	SQL_TQuery(g_hSQLDatabase, MySQL_SetCharSet, "SET NAMES 'utf8'");
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sthread (title, lastpost, forumid, open, postusername, postuserid, lastposter, lastposterid, dateline, visible) VALUES ('%s', '%d', '%d', '1', '%s', '%d', '%s', '%d', '%d', '1');", g_szTablePrefix, g_szThreadTitle[iClient], g_iTimeStamp[iClient], g_iForumID, g_szUserName, g_iUserID, g_szUserName, g_iUserID, g_iTimeStamp[iClient]);
		}
		case FORUM_MYBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sthreads (fid, subject, uid, username, dateline, firstpost, lastpost, visible) VALUES ('%d', '%s', '%d', '%s', '%d', '1', '%d', '1');", g_szTablePrefix, g_iForumID, g_szThreadTitle[iClient], g_iUserID, g_szUserName, g_iTimeStamp[iClient], g_iTimeStamp[iClient]);			
		}
		case FORUM_SMF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (id_board, approved) VALUES ('%d', '1');", g_szTablePrefix, g_iForumID);
		}
		case FORUM_PHPBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (forum_id, topic_approved, topic_title, topic_poster, topic_time, topic_views, topic_first_poster_name, topic_first_poster_colour, topic_last_poster_id, topic_last_poster_name, topic_last_post_subject, topic_last_post_time, topic_last_view_time) VALUES ('%d', '1', '%s', '%d', '%d', '1', '%s', 'AA0000', '%d', '%s', '%s', '%d', '%d');", g_szTablePrefix, g_iForumID, g_szThreadTitle[iClient], g_iUserID, g_iTimeStamp[iClient], g_szUserName, g_iUserID, g_szUserName, g_szThreadTitle[iClient], g_iTimeStamp[iClient], g_iTimeStamp[iClient]);
		}
		case FORUM_WBBLITE:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sthread (boardID, topic, time, userID, username, lastPostTime, lastPosterID, lastPoster) VALUES ('%d', '%s', '%d', '%d', '%s', '%d', '%d', '%s');", g_szTablePrefix, g_iForumID, g_szThreadTitle[iClient], g_iTimeStamp[iClient], g_iUserID, g_szUserName, g_iTimeStamp[iClient], g_iUserID, g_szUserName);
		}
		case FORUM_AEF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (topic, t_bid, t_status, t_mem_id, t_approved) VALUES ('%s', '%d', '1', '%d', '1');", g_szTablePrefix, g_szThreadTitle[iClient], g_iForumID, g_iUserID);
		}
		case FORUM_USEBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (forum_id, topic_title) VALUES ('%d', '%s');", g_szTablePrefix, g_iForumID, g_szThreadTitle);
		}
		case FORUM_XMB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sthreads (fid, subject, author) VALUES ('%d', '%s', '%s');", g_szTablePrefix, g_iForumID, g_szThreadTitle[iClient], g_szUserName);
		}
		case FORUM_IPBOARDS:
		{
			decl String:szSafeTitle[1024], String:szSafePosterName[2 * MAX_NAME_LENGTH + 1];
			GetWebSafeString(g_szThreadTitle[iClient], szSafeTitle, sizeof(szSafeTitle));
			GetWebSafeString(g_szUserName, szSafePosterName, sizeof(szSafePosterName));
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (title, state, posts, starter_id, start_date, last_poster_id, last_post, starter_name, last_poster_name, poll_state, last_vote, views, forum_id, approved, author_mode, pinned, title_seo, seo_first_name, seo_last_name, last_real_post) VALUES ('%s', 'open', '1', '%d', '%d', '%d', '%d', '%s', '%s', '0', '0', '1', '%d', '1', '1', '0', '%s', '%s', '%s', '%d');", g_szTablePrefix, g_szThreadTitle[iClient], g_iUserID, g_iTimeStamp[iClient], g_iUserID, g_iTimeStamp[iClient], g_szUserName, g_szUserName, g_iForumID, szSafeTitle, szSafePosterName, szSafePosterName, g_iTimeStamp[iClient]);
		}
	}
	
	if(GetConVarInt(g_Cvar_Debug))
		PushArrayString(g_hDebugArray[iClient], szSQLQuery);
	
	SQL_TQuery(g_hSQLDatabase, MySQL_InsertReport, szSQLQuery, iClient);
}

public MySQL_InsertReport(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed To Create Thread: %s", szError);
	else
		FindCorrectThread(data);
}

/* Finds the Thread ID for the thread we just created */
public FindCorrectThread(iClient)
{
	/* Search mybb_threads for the most recent Thread to get the ID */
	decl String:szSQLQuery[512];
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT threadid FROM %sthread WHERE dateline='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_MYBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT tid FROM %sthreads WHERE dateline='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_SMF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT MAX(id_topic) FROM %stopics;", g_szTablePrefix);
		}
		case FORUM_PHPBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT topic_id FROM %stopics WHERE topic_time='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_WBBLITE:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT threadID FROM %sthread WHERE time='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_AEF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT MAX(tid) FROM %stopics;", g_szTablePrefix); 
		}
		case FORUM_USEBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT MAX(id) FROM %stopics;", g_szTablePrefix);
		}
		case FORUM_XMB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT tid FROM %stopics WHERE lastpost='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_IPBOARDS:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT tid FROM %stopics WHERE last_post='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
	}
	
	if(GetConVarInt(g_Cvar_Debug))
		PushArrayString(g_hDebugArray[iClient], szSQLQuery);
	
	SQL_TQuery(g_hSQLDatabase, MySQL_SelectTid, szSQLQuery, iClient);
}

public MySQL_SelectTid(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed To Select tid: %s", szError);
	else
	{
		if(SQL_GetRowCount(hDatabase))
		{
			SQL_FetchRow(hDatabase);
			g_iThreadID[data] = SQL_FetchInt(hDatabase, 0);
			CreateThreadPost(data);
		}
	}
}

/* Creates the Post (message) for the thread we created */
public CreateThreadPost(iClient)
{
	decl String:szContent[1024];
	decl String:szReporterName[MAX_NAME_LENGTH], String:szSafeReporterName[MAX_NAME_LENGTH * 2 + 1], String:szReporterAuthID[32], String:szReporterIP[32];
	
	GetClientName(iClient, szReporterName, sizeof(szReporterName));
	ParsePlayerName(szReporterName, szSafeReporterName, sizeof(szSafeReporterName));
	GetClientAuthString(iClient, szReporterAuthID, sizeof(szReporterAuthID));
	GetClientIP(iClient, szReporterIP, sizeof(szReporterIP));
	
	SQL_TQuery(g_hSQLDatabase, MySQL_SetCharSet, "SET NAMES 'utf8'");
	
	decl String:szSQLQuery[1024];
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
		{
			Format(szContent, sizeof(szContent), "[b]%s[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Category[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szServerInfoTitle, g_szHostName, g_szServerIP, g_szServerPort, g_szMapName, g_szReportedTitle, g_szSafeTargetName[iClient], g_szTargetAuthID[iClient], g_szTargetIP[iClient], g_szCategory[iClient], g_szReason[iClient], g_szSafeDescription[iClient], g_szReporterTitle, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %spost (threadid, username, userid, title, dateline, pagetext, allowsmilie, visible, htmlstate) VALUES ('%d', '%s', '%d', '%s', '%d', '%s', '1', '1', 'on_nl2br');", g_szTablePrefix, g_iThreadID[iClient], g_szUserName, g_iUserID, g_szThreadTitle[iClient], g_iTimeStamp[iClient], szContent);			
		}
		case FORUM_MYBB:
		{
			Format(szContent, sizeof(szContent), "[b]%s[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Category[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [color=#ff0000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szServerInfoTitle, g_szHostName, g_szServerIP, g_szServerPort, g_szMapName, g_szReportedTitle, g_szSafeTargetName[iClient], g_szTargetAuthID[iClient], g_szTargetIP[iClient], g_szCategory[iClient], g_szReason[iClient], g_szSafeDescription[iClient], g_szReporterTitle, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (tid, fid, subject, uid, username, dateline, message, ipaddress, visible) VALUES ('%d', '%d', '%s', '%d', '%s', '%d', '%s', '%s', '1');", g_szTablePrefix, g_iThreadID[iClient], g_iForumID, g_szThreadTitle[iClient], g_iUserID, g_szUserName, g_iTimeStamp[iClient], szContent, szReporterIP);			
		}
		case FORUM_SMF:
		{
			Format(szContent, sizeof(szContent), "[b]%s[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Category[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [color=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szServerInfoTitle, g_szHostName, g_szServerIP, g_szServerPort, g_szMapName, g_szReportedTitle, g_szSafeTargetName[iClient], g_szTargetAuthID[iClient], g_szTargetIP[iClient], g_szCategory[iClient], g_szReason[iClient], g_szSafeDescription[iClient], g_szReporterTitle, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %smessages (id_topic, id_board, poster_time, id_member, subject, poster_name, poster_email, poster_ip, body, approved) VALUES ('%d', '%d', '%d', '%d', '%s', '%s', '%s', '%s', '%s', '1');", g_szTablePrefix, g_iThreadID[iClient], g_iForumID, g_iTimeStamp[iClient], g_iUserID, g_szThreadTitle[iClient], g_szUserName, g_szEmailAddress, szReporterIP, szContent);			
		}
		case FORUM_PHPBB:
		{
			Format(szContent, sizeof(szContent), "%s - \nName: %s \nIP: %s:%s \nMap: %s \n\n%s - \nName: %s \nSteamID: %s \nIP: %s \nCategory: %s \nReason: %s \nDescription: %s \n\n%s - \nName: %s \nSteamID: %s \nIP: %s \n\nPost auto generated with \"Report to Forums\" by =NcB= SavSin", g_szServerInfoTitle, g_szHostName, g_szServerIP, g_szServerPort, g_szMapName, g_szReportedTitle, g_szSafeTargetName[iClient], g_szTargetAuthID[iClient], g_szTargetIP[iClient], g_szCategory[iClient], g_szReason[iClient], g_szSafeDescription[iClient], g_szReporterTitle, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (topic_id, forum_id, poster_id, poster_ip, post_time, post_approved, post_subject, post_text, post_postcount) VALUES ('%d', '%d', '%d', '%s', '%d', '1', '%s', '%s', '1');", g_szTablePrefix, g_iThreadID[iClient], g_iForumID, g_iUserID, g_szTargetIP[iClient], g_iTimeStamp[iClient], g_szThreadTitle[iClient], szContent);
		}
		case FORUM_WBBLITE:
		{
			Format(szContent, sizeof(szContent), "[b]%s[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Category[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=10]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szServerInfoTitle, g_szHostName, g_szServerIP, g_szServerPort, g_szMapName, g_szReportedTitle, g_szSafeTargetName[iClient], g_szTargetAuthID[iClient], g_szTargetIP[iClient], g_szCategory[iClient], g_szReason[iClient], g_szSafeDescription[iClient], g_szReporterTitle, szSafeReporterName, szReporterAuthID, szReporterIP);		
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %spost (threadID, userID, username, message, time, enableSmilies, enableBBCodes, ipAddress) VALUES ('%d', '%d', '%s', '%s', '%d', '0', '1', '%s');", g_szTablePrefix, g_iThreadID[iClient], g_iUserID, g_szUserName, szContent, g_iTimeStamp[iClient], szReporterIP);
		}
		case FORUM_AEF:
		{
			Format(szContent, sizeof(szContent), "[b]%s[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Category[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szServerInfoTitle, g_szHostName, g_szServerIP, g_szServerPort, g_szMapName, g_szReportedTitle, g_szSafeTargetName[iClient], g_szTargetAuthID[iClient], g_szTargetIP[iClient], g_szCategory[iClient], g_szReason[iClient], g_szSafeDescription[iClient], g_szReporterTitle, szSafeReporterName, szReporterAuthID, szReporterIP);
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (post_tid, post_fid, ptime, poster_id, poster_ip, post, use_smileys, p_approved) VALUES ('%d', '%d', '%d', '%d', '%s', '%s', '0', '1');", g_szTablePrefix, g_iThreadID[iClient], g_iForumID, g_iTimeStamp[iClient], g_iUserID, szReporterIP, szContent);
		}
		case FORUM_USEBB:
		{
			Format(szContent, sizeof(szContent), "[b]%s[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Category[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szServerInfoTitle, g_szHostName, g_szServerIP, g_szServerPort, g_szMapName, g_szReportedTitle, g_szSafeTargetName[iClient], g_szTargetAuthID[iClient], g_szTargetIP[iClient], g_szCategory[iClient], g_szReason[iClient], g_szSafeDescription[iClient], g_szReporterTitle, szSafeReporterName, szReporterAuthID, szReporterIP);
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (topic_id, poster_id, poster_ip_addr, content, post_time, enable_smilies) VALUES ('%d', '%d', '%s', '%s', '%d', '0');", g_szTablePrefix, g_iThreadID[iClient], g_iUserID, szReporterIP, szContent, g_iTimeStamp[iClient]);
		}
		case FORUM_XMB:
		{
			Format(szContent, sizeof(szContent), "[b]%s[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Category[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szServerInfoTitle, g_szHostName, g_szServerIP, g_szServerPort, g_szMapName, g_szReportedTitle, g_szSafeTargetName[iClient], g_szTargetAuthID[iClient], g_szTargetIP[iClient], g_szCategory[iClient], g_szReason[iClient], g_szSafeDescription[iClient], g_szReporterTitle, szSafeReporterName, szReporterAuthID, szReporterIP);
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (fid, tid, author, message, subject, dateline, useip, bbcodeoff, smileyoff) VALUES ('%d', '%d', '%s', '%s', '%s', '%d', '%s', 'no', 'yes');", g_szTablePrefix, g_iForumID, g_iThreadID[iClient], g_szUserName, szContent, g_szThreadTitle[iClient], g_iTimeStamp[iClient]);
		}
		case FORUM_IPBOARDS:
		{
			Format(szContent, sizeof(szContent), "[b]%s[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Category[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]%s[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szServerInfoTitle, g_szHostName, g_szServerIP, g_szServerPort, g_szMapName, g_szReportedTitle, g_szSafeTargetName[iClient], g_szTargetAuthID[iClient], g_szTargetIP[iClient], g_szCategory[iClient], g_szReason[iClient], g_szSafeDescription[iClient], g_szReporterTitle, szSafeReporterName, szReporterAuthID, szReporterIP);
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (author_id, author_name, ip_address, post_date, post, topic_id, new_topic) VALUES ('%d', '%s', '%s', '%d', '%s', '%d', '1');", g_szTablePrefix, g_iUserID, g_szUserName, szReporterIP, g_iTimeStamp[iClient], szContent, g_iThreadID[iClient]);
		}
	}
	
	if(GetConVarInt(g_Cvar_Debug))
		PushArrayString(g_hDebugArray[iClient], szSQLQuery);
	
	SQL_TQuery(g_hSQLDatabase, MySQL_InsertPostContent, szSQLQuery, iClient);
}

public MySQL_InsertPostContent(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed insert post message: %s", szError);
	else
	{
		if(g_iForumSoftwareID != FORUM_MYBB)
			GetPostId(data);
		else
			GetCurrentForumPostData(data);
	}
}

/* Finds the Post ID for the thread we just created */
public GetPostId(iClient)
{
	/* Search posts table for the most recent post to get the ID */
	decl String:szSQLQuery[512];
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT postid FROM %spost WHERE dateline='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_SMF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT id_msg FROM %smessages WHERE poster_time='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_PHPBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT post_id FROM %sposts WHERE post_time='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_WBBLITE:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT postID FROM %spost WHERE time='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_AEF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT pid FROM %sposts WHERE ptime='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_USEBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT id FROM %sposts WHERE post_time='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_XMB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SLECT pid FROM %sposts WHERE dateline='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
		case FORUM_IPBOARDS:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT pid FROM %sposts WHERE post_date='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
		}
	}
	
	if(GetConVarInt(g_Cvar_Debug))
		PushArrayString(g_hDebugArray[iClient], szSQLQuery);
	
	SQL_TQuery(g_hSQLDatabase, MySQL_SelectPid, szSQLQuery, iClient);
}

public MySQL_SelectPid(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed To Select post id: %s", szError);
	else
	{
		if(SQL_GetRowCount(hDatabase))
		{
			SQL_FetchRow(hDatabase);
			g_iPostID[data] = SQL_FetchInt(hDatabase, 0);
			SetPostId(data);
		}
	}
}

/* Sets the Post ID for the thread we just created */
public SetPostId(iClient)
{
	/* Update The thread with the correct post data */
	decl String:szSQLQuery[512];
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sthread SET firstpostid=%d, lastpostid=%d WHERE threadid=%d;", g_szTablePrefix, g_iPostID[iClient], g_iPostID[iClient], g_iThreadID[iClient]);
		}
		case FORUM_SMF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET id_first_msg=%d, id_last_msg=%d WHERE id_topic=%d;", g_szTablePrefix, g_iPostID[iClient], g_iPostID[iClient], g_iThreadID[iClient]);
		}
		case FORUM_PHPBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET topic_first_post_id=%d, topic_last_post_id=%d WHERE topic_id=%d;", g_szTablePrefix, g_iPostID[iClient], g_iPostID[iClient], g_iThreadID[iClient]);
		}
		case FORUM_WBBLITE:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sthread SET firstPostID=%d WHERE threadID=%d;", g_szTablePrefix, g_iPostID[iClient], g_iThreadID[iClient]);
		}
		case FORUM_AEF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET first_post_id=%d, last_post_id=%d, mem_id_last_post=%d WHERE tid=%d;", g_szTablePrefix, g_iPostID[iClient], g_iPostID[iClient], g_iUserID, g_iThreadID[iClient]);
		}
		case FORUM_USEBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET first_post_id=%d, last_post_id=%d WHERE id=%d;", g_szTablePrefix, g_iPostID[iClient], g_iPostID[iClient], g_iThreadID[iClient]);
		}
		case FORUM_XMB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sthreads SET lastpost='%d|%s|%d' WHERE tid=%d;", g_szTablePrefix, g_iTimeStamp[iClient], g_szUserName, g_iPostID[iClient], g_iThreadID[iClient]);
		}
		case FORUM_IPBOARDS:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET topic_firstpost='%d' WHERE last_post='%d';", g_szTablePrefix, g_iPostID[iClient], g_iTimeStamp[iClient]);
		}
	}
	
	if(GetConVarInt(g_Cvar_Debug))
		PushArrayString(g_hDebugArray[iClient], szSQLQuery);
	
	SQL_TQuery(g_hSQLDatabase, MySQL_UpdatetPid, szSQLQuery, iClient);
}

public MySQL_UpdatetPid(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed To update thread with post id: %s", szError);
	else
	{		
		GetCurrentForumPostData(data);
	}
}

/* Gets the Current Post and Thread count for the specified thread */
public GetCurrentForumPostData(iClient)
{
	/* Search mybb_forums to retrieve the post count */
	decl String:szSQLQuery[512];
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT replycount, threadcount FROM %sforum WHERE forumid='%d';", g_szTablePrefix, g_iForumID);
		}
		case FORUM_MYBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, threads FROM %sforums WHERE fid='%d';", g_szTablePrefix, g_iForumID);
		}
		case FORUM_SMF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT num_posts, num_topics FROM %sboards WHERE id_board='%d';", g_szTablePrefix, g_iForumID);
		}
		case FORUM_PHPBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT forum_posts, forum_topics FROM %sforums WHERE forum_id='%d';", g_szTablePrefix, g_iForumID);
		}
		case FORUM_WBBLITE:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, threads FROM %sboard WHERE boardID='%d';", g_szTablePrefix, g_iForumID);
		}
		case FORUM_AEF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT nposts, ntopic FROM %sforums WHERE fid='%d';", g_szTablePrefix, g_iForumID);
		}
		case FORUM_USEBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, topics FROM %sforums WHERE id='%d';", g_szTablePrefix, g_iForumID);
		}
		case FORUM_XMB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, threads FROM %sforums WHERE fid='%d';", g_szTablePrefix, g_iForumID);
		}
		case FORUM_IPBOARDS:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, topics FROM %sforums WHERE id='%d';", g_szTablePrefix, g_iForumID);
		}
	}
	
	if(GetConVarInt(g_Cvar_Debug))
		PushArrayString(g_hDebugArray[iClient], szSQLQuery);
	
	SQL_TQuery(g_hSQLDatabase, MySQL_SelectForumThreadInfo, szSQLQuery, iClient);
}

public MySQL_SelectForumThreadInfo(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed To Select post and thread count: %s", szError);
	else
	{
		if(SQL_GetRowCount(hDatabase))
		{
			SQL_FetchRow(hDatabase);
			new iForumPostCount = (SQL_FetchInt(hDatabase, 0) + 1);
			new iForumThreadCount = (SQL_FetchInt(hDatabase, 1) + 1);
			UpdateForumPostCount(data, iForumPostCount, iForumThreadCount);
		}
	}
}

/* Increase the Thread and Post count accordingly */
public UpdateForumPostCount(iClient, iPostCount, iThreadCount)
{
	decl String:szSQLQuery[1024];
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforum SET threadcount='%d', replycount='%d', lastpost='%d', lastposter='%s', lastposterid='%d', lastpostid='%d', lastthread='%s', lastthreadid='%d' WHERE forumid='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iTimeStamp[iClient], g_szUserName, g_iUserID, g_iPostID[iClient], g_szThreadTitle[iClient], g_iThreadID[iClient], g_iForumID);			
		}
		case FORUM_MYBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET threads='%d', posts='%d', lastpost='%d', lastposter='%s', lastposteruid='%d', lastposttid='%d', lastpostsubject='%s' WHERE fid='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iTimeStamp[iClient], g_szUserName, g_iUserID, g_iThreadID[iClient], g_szThreadTitle[iClient], g_iForumID);			
		}
		case FORUM_SMF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sboards SET num_topics='%d', num_posts='%d', id_last_msg='%d', id_msg_updated='%d' WHERE id_board='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iPostID[iClient], g_iPostID[iClient], g_iForumID);			
		}
		case FORUM_PHPBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET forum_topics='%d', forum_topics_real='%d', forum_posts='%d', forum_last_post_id='%d', forum_last_post_subject='%s', forum_last_post_time='%d', forum_last_poster_name='%s' WHERE forum_id='%d';", g_szTablePrefix, iThreadCount, iThreadCount, iPostCount, g_iPostID[iClient], g_szThreadTitle[iClient], g_iTimeStamp[iClient], g_szUserName, g_iForumID);			
		}
		case FORUM_WBBLITE:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sboard SET threads='%d', posts='%d' WHERE boardID='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iForumID);
		}
		case FORUM_AEF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET ntopic='%d', nposts='%d', f_last_pid='%d' WHERE fid ='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iPostID[iClient], g_iForumID);
		}
		case FORUM_USEBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET topics='%d', posts='%d', last_topic_id='%d' WHERE id='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iThreadID[iClient], g_iForumID);
		}
		case FORUM_XMB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET lastpost='%d', posts='%d', threads='%d' WHERE fid='%d';", g_szTablePrefix, g_iTimeStamp[iClient], iPostCount, iThreadCount, g_iForumID);
		}
		case FORUM_IPBOARDS:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET topics='%d', posts='%d', last_post='%d', last_poster_id='%d', last_poster_name='%s', last_title='%s', last_id='%d', newest_title='%s', newest_id='%d' WHERE id='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iTimeStamp[iClient], g_iUserID, g_szUserName, g_szThreadTitle[iClient], g_iPostID, g_szThreadTitle[iClient], g_iPostID, g_iForumID);
		}
	}
	
	if(GetConVarInt(g_Cvar_Debug))
		PushArrayString(g_hDebugArray[iClient], szSQLQuery);
	
	SQL_TQuery(g_hSQLDatabase, MySQL_UpdateForumPostCount, szSQLQuery, iClient);
}

public MySQL_UpdateForumPostCount(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed To Update Thread and Post Count: %s", szError);
	else
	{
		GetUserPostInfo(data);
	}
}

/* Get the Users post count */
public GetUserPostInfo(iClient)
{
	decl String:szSQLQuery[512];
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %suser WHERE userid='%d';", g_szTablePrefix, g_iUserID);
		}
		case FORUM_MYBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT postnum FROM %susers WHERE uid='%d';", g_szTablePrefix, g_iUserID);
		}
		case FORUM_SMF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %smembers WHERE id_member='%d';", g_szTablePrefix, g_iUserID);
		}
		case FORUM_PHPBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT user_posts FROM %susers WHERE user_id='%d';", g_szTablePrefix, g_iUserID);
		}
		case FORUM_WBBLITE:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %suser WHERE userID='%d';", g_szTablePrefix, g_iUserID);
		}
		case FORUM_AEF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %susers WHERE id='%d';", g_szTablePrefix, g_iUserID);
		}
		case FORUM_USEBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %smembers WHERE id='%d';", g_szTablePrefix, g_iUserID);
		}
		case FORUM_XMB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT postnum FROM %smembers WHERE uid='%d';", g_szTablePrefix, g_iUserID);
		}
		case FORUM_IPBOARDS:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts FROM %smembers WHERE member_id='%d';", g_szTablePrefix, g_iUserID);
		}
	}
	
	if(GetConVarInt(g_Cvar_Debug))
		PushArrayString(g_hDebugArray[iClient], szSQLQuery);
	
	SQL_TQuery(g_hSQLDatabase, MySQL_GetUserPostCount, szSQLQuery, iClient);
}

public MySQL_GetUserPostCount(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed To Select User Post Data: %s", szError);
	else
	{
		if(SQL_GetRowCount(hDatabase))
		{
			SQL_FetchRow(hDatabase);
			new iUserPostCount = (SQL_FetchInt(hDatabase, 0) + 1);
			UpdateUserPostCount(data, iUserPostCount);
		}
	}
}

/* Increase the users post count accordingly */
public UpdateUserPostCount(iClient, iPostCount)
{
	decl String:szSQLQuery[512];
	
	switch(g_iForumSoftwareID)
	{
		case FORUM_VB4:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %suser SET posts='%d', lastvisit='%d', lastactivity='%d', lastpost='%d', lastpostid='%d' WHERE userid=%d;", g_szTablePrefix, iPostCount, g_iTimeStamp[iClient], g_iTimeStamp[iClient], g_iTimeStamp[iClient], g_iPostID[iClient], g_iUserID);			
		}
		case FORUM_MYBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %susers SET postnum='%d' WHERE uid='%d';", g_szTablePrefix, iPostCount, g_iUserID);
		}
		case FORUM_SMF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %smembers SET posts='%d', last_login='%d' WHERE id_member=%d;", g_szTablePrefix, iPostCount, g_iTimeStamp[iClient], g_iUserID);
		}
		case FORUM_PHPBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %susers SET user_posts='%d', user_lastpost_time='%d' WHERE user_id=%d;", g_szTablePrefix, iPostCount, g_iTimeStamp[iClient], g_iUserID);			
		}
		case FORUM_WBBLITE:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %suser SET posts='%d', boardLastVisitTime='%d', boardLastActivityTime='%d' WHERE userID=%d;", g_szTablePrefix, iPostCount, g_iTimeStamp[iClient], g_iTimeStamp[iClient], g_iUserID);
		}
		case FORUM_AEF:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %susers SET lastlogin='%d', lastlogin_1='%d', posts='%d' WHERE id=%d;", g_szTablePrefix, g_iTimeStamp[iClient], g_iTimeStamp[iClient], iPostCount, g_iUserID);
		}
		case FORUM_USEBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %smembers SET last_login='%d', last_pageview='%d', posts='%d' WHERE id=%d;", g_szTablePrefix, g_iTimeStamp[iClient], g_iTimeStamp[iClient], iPostCount, g_iUserID);
		}
		case FORUM_XMB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %smembers SET postnum='%d', lastvisit='%d';", g_szTablePrefix, iPostCount, g_iTimeStamp[iClient]);
		}
		case FORUM_IPBOARDS:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %smembers SET posts='%d', last_post='%d', last_visit='%d', last_activity='%d' WHERE member_id=%d;", g_szTablePrefix, iPostCount, g_iTimeStamp[iClient], g_iTimeStamp[iClient], g_iTimeStamp[iClient], g_iUserID);
		}
	}
	
	if(GetConVarInt(g_Cvar_Debug))
		PushArrayString(g_hDebugArray[iClient], szSQLQuery);
	
	SQL_TQuery(g_hSQLDatabase, MySQL_UpdateUserPostCount, szSQLQuery, iClient);
}

public MySQL_UpdateUserPostCount(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed To Update User Post Data: %s", szError);
	else
	{
		/* Display Message to player saying player was reported. */		
		PrintToChat(data, "[%s] %s has been reported: %s", g_szPrefix, g_szTargetName[data], g_szReason[data]);
		
		if(GetConVarInt(g_Cvar_Debug))
		{
			CreateDebugFile(data);
			ClearArray(g_hDebugArray[data]);
		}
		
		if(GetConVarInt(g_Cvar_AdminAlert))
			AlertAdmins(data);
	}
}

public MySQL_SetCharSet(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed to SetCharSet: %s", szError);
}

stock bool:AddPlayerToBlackList(const String:szAuthID[], const String:szTargetName[], const String:szArgReason[])
{
	new Handle:kv = CreateKeyValues("Blacklist");
	FileToKeyValues(kv, g_szBlackListPath);
	if(KvJumpToKey(kv, szAuthID, true))
	{
		KvSetString(kv, "name", szTargetName);
		KvSetString(kv, "reason", szArgReason);
		KvRewind(kv);
		KeyValuesToFile(kv, g_szBlackListPath);
		CloseHandle(kv);
		return true;
	}
	
	CloseHandle(kv);
	return false;
}

stock bool:RemPlayerToBlackList(const String:szAuthID[])
{
	new Handle:kv = CreateKeyValues("Blacklist");
	FileToKeyValues(kv, g_szBlackListPath);
	
	if(KvJumpToKey(kv, szAuthID))
	{
		if(KvDeleteThis(kv))
		{
			KvRewind(kv);
			KeyValuesToFile(kv, g_szBlackListPath);
			CloseHandle(kv);
			return true;
		}
	}
	
	CloseHandle(kv);
	return false;
}

stock bool:IsUserBlacklisted(const String:szAuthID[])
{
	new Handle:kv = CreateKeyValues("Blacklist");
	FileToKeyValues(kv, g_szBlackListPath);
	
	if(KvJumpToKey(kv, szAuthID))
	{
		CloseHandle(kv);
		return true;
	}
	
	CloseHandle(kv);
	
	return false;
}

//Returns the correct map for CSGO
 stock GetCurrentWorkshopMap(String:szMap[], iMapBuf, String:szWorkShopID[], iWorkShopBuf)
 {
	decl String:szCurMapSplit[2][64];
	
	ReplaceString(szMap, iMapBuf, "workshop/", "", false);
	ExplodeString(szMap, "/", szCurMapSplit, 2, sizeof(szCurMapSplit[]));
	
	strcopy(szMap, iMapBuf, szCurMapSplit[1]);
	strcopy(szWorkShopID, iWorkShopBuf, szCurMapSplit[0]);
 }
 
 stock GetWebSafeString(const String:szString[], String:szBuffer[], len)
{
	strcopy(szBuffer, len, szString);	
	ReplaceString(szBuffer, len, " ", "-");
}
 
 stock ParsePlayerName(const String:szString[], String:szBuffer[], len)
{
	SQL_EscapeString(g_hSQLDatabase, szString, szBuffer, len);
	ReplaceString(szBuffer, len, "}", "");
	ReplaceString(szBuffer, len, "{", "");
	ReplaceString(szBuffer, len, "|", "");
}

/* Alert Admins if any of reported player */
stock AlertAdmins(iClient)
{
	for(new i=1; i<MaxClients;i++)
	{
		if(g_bIsUserAdmin[i] && iClient != i)
		{
			/* Display Message to admin saying player was reported. */
			PrintToChat(i, "[%s] 5 has been reported: %s by %N", g_szPrefix, g_szTargetName[iClient], g_szReason[iClient], iClient);
		}
	}
}

public CreateDebugFile(iClient)
{
	decl String:szBuffer[1024], String:szDebugFile[PLATFORM_MAX_PATH], String:szTime[10];
	new iArraySize = GetArraySize(g_hDebugArray[iClient]);
	FormatTime(szTime, sizeof(szTime), "%j-%H%M", GetTime());
	Format(szDebugFile, sizeof(szDebugFile), "addons/sourcemod/logs/rtf-%s.log", szTime);
	new Handle:hFile = OpenFile(szDebugFile, "w");
	for(new i=0; i < iArraySize; i++)
	{
		GetArrayString(g_hDebugArray[iClient], i, szBuffer, sizeof(szBuffer));
		WriteFileLine(hFile, szBuffer);
		WriteFileLine(hFile, "");
	}
	CloseHandle(hFile);
}