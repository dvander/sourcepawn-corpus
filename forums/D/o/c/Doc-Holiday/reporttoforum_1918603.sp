/*  Plugin Created by Request from Lyric
 *  Created by SavSin
 */
#pragma semicolon 1

#include <sourcemod>
#include <adminmenu>
#include <updater>
#include <dbi>

new const String:PLUGIN_VERSION[] = "1.1.3q";
new const String:UPDATE_URL[] = "http://betascripts.norcalbots.com/report-to-forums-beta/raw/default/rtfupdate.txt";

enum ServerBoards
{
	FORUM_UNSUPPORTED,
	FORUM_VB4,
	FORUM_MYBB,
	FORUM_SMF,
	FORUM_PHPBB,
	FORUM_WBBLITE,
	FORUM_AEF,
	FORUM_FLUXBB,
	FORUM_PHORUM,
	FORUM_USEBB,
	FORUM_XMB,
	FORUM_IPBOARDS
}

new const String:g_szForumDescription[ServerBoards][] =
{
	"",
	"vBulletin 4",
	"MyBB",
	"Small Machine Forums",
	"phpBB",
	"WoltLab Burning Board Lite",
	"Advanced Electron Forums",
	"FluxBB",
	"Phorum",
	"useBB",
	"XMB",
	"Invision Power Board"
};

new const String:g_szSQLSettings[ServerBoards][] =
{
	"",
	"rtfsettings_vb4",
	"rtfsettings_mybb",
	"rtfsettings_smf",
	"rtfsettings_phpbb",
	"rtfsettings_wbblite",
	"rtfsettings_aef",
	"rtfsettings_fluxbb",
	"rtfsettings_phorum",
	"rtfsettings_usebb",
	"rtfsettings_xmb",
	"rtfsettings_ipboards"
};

new const String:g_szDebugFriles[ServerBoards][] =
{
	"",
	"rtf_debug_vb4",
	"rtf_debug_mybb",
	"rtf_debug_smf",
	"rtf_debug_phpbb",
	"rtf_debug_wbblite",
	"rtf_debug_aef",
	"rtf_debug_fluxbb",
	"rtf_debug_phorum",
	"rtf_debug_usebb",
	"rtf_debug_xmb",
	"rtf_debug_ipboards"
};

/* Valve ConVars */
new Handle:g_Cvar_HostName = INVALID_HANDLE;
new Handle:g_Cvar_ServerIP = INVALID_HANDLE;
new Handle:g_Cvar_ServerPort = INVALID_HANDLE;

/* Menu ConVars */
new Handle:g_Cvar_MainMenuTitle = INVALID_HANDLE;
new Handle:g_Cvar_ReportReasonTitle = INVALID_HANDLE;

/* Settings ConVars */
new Handle:g_Cvar_AllowCustomReport = INVALID_HANDLE;
new Handle:g_Cvar_ForumSupport = INVALID_HANDLE;
new Handle:g_Cvar_ReportCoolDown = INVALID_HANDLE;
new Handle:g_Cvar_AdvertInterval = INVALID_HANDLE;
new Handle:g_Cvar_ChatPrefix = INVALID_HANDLE;
new Handle:g_Cvar_Debug = INVALID_HANDLE;

/* SQL ConVars */
new Handle:g_Cvar_ReporterID = INVALID_HANDLE;
new Handle:g_Cvar_ReporterUserName = INVALID_HANDLE;
new Handle:g_Cvar_ReporterEmail = INVALID_HANDLE;
new Handle:g_Cvar_ForumID = INVALID_HANDLE;
new Handle:g_Cvar_TablePrefix = INVALID_HANDLE;

/* Admin Cvars */
new Handle:g_Cvar_AdminAlert = INVALID_HANDLE;
new Handle:g_Cvar_AlertAdminBlockPost = INVALID_HANDLE;

/* Data Handlers */
new Handle:g_hSQLDatabase = INVALID_HANDLE;
new Handle:g_aReportReason = INVALID_HANDLE;
new Handle:g_hReasonDescription = INVALID_HANDLE;
new Handle:g_hReasonMenu = INVALID_HANDLE;
new Handle:g_hDebugArray[MAXPLAYERS+1] = {INVALID_HANDLE, ...};

/* Target Variables */
new g_iTarget [MAXPLAYERS+1];
new String:g_szSafeTargetName[MAXPLAYERS+1][MAX_NAME_LENGTH * 2 + 1];
new String:g_szTargetName[MAXPLAYERS+1][MAX_NAME_LENGTH];
new String:g_szTargetAuthId[MAXPLAYERS+1][32];
new String:g_szTargetIP[MAXPLAYERS+1][32];
new String:g_szThreadTitle[MAXPLAYERS+1][256];
new g_iReason[MAXPLAYERS+1];

/* Server Info Variables */
new String:g_szMapName[32];
new String:g_szHostName[200];

/* Forum Settings */
new ServerBoards:g_iForumSoftware;
new g_iTimeStamp[MAXPLAYERS+1];
new g_iThreadID[MAXPLAYERS+1];
new g_iPostID[MAXPLAYERS+1];
new g_iForumID, g_iUserID;
new String:g_szTablePrefix[32];
new String:g_szUserName[32];

/* Misc Variables */
new g_iAdminCount;
new bool:g_bIsUserAdmin[MAXPLAYERS+1];
new g_iTotalReasons = -1;
new String:g_szPrefix[32];
new String:g_szFilePath[PLATFORM_MAX_PATH];

public Plugin:myinfo =
{
	name = "Report To Forums",
	author = "SavSin",
	description = "Report a player from within game.",
	version = PLUGIN_VERSION,
	url = "www.norcalbots.com"
};

public OnPluginStart()
{
	/* Plugin ConVar for Server Tracking */
	CreateConVar("rtf_version", PLUGIN_VERSION, "Version of report to forums", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	/* Register Console Command to report */
	RegConsoleCmd("sm_report", CMD_SMReport, "Report a user with this command");
	
	/* Board Setting */
	g_Cvar_ForumSupport = CreateConVar("rtf_board", "", "Which Board? [1 = vb4] [2 = mybb] [3 = smf] [4 = phpbb] [5 = WBB Lite]");
	
	/* Table Names */
	g_Cvar_TablePrefix = CreateConVar("rtf_table_prefix", "", "Table prefix.");
	
	/* Forum and User Id's */
	g_Cvar_ForumID = CreateConVar("rtf_forumid", "", "forum id to make the post in.");
	g_Cvar_ReporterID = CreateConVar("rtf_reporterid", "", "userid to make the post under.");
	g_Cvar_ReporterUserName = CreateConVar("rtf_reporter_username", "", "Username from your forum");
	g_Cvar_ReporterEmail = CreateConVar("rtf_reporter_email", "", "Email address for report bot");
	
	/* Title ConVars */
	g_Cvar_MainMenuTitle = CreateConVar("rtf_mainmenu_title", "", "Title to the target menu");
	g_Cvar_ReportReasonTitle = CreateConVar("rtf_submenu_title", "", "Title for the sub menu where the reasons are");
	
	/* Settings ConVars */
	g_Cvar_AllowCustomReport = CreateConVar("rtf_allow_custom_report", "", "Allow Users to create custom reports");
	g_Cvar_ChatPrefix = CreateConVar("rtf_prefix", "", "Prefix for chat messages from the plugin. <Default: Reporter>");
	g_Cvar_ReportCoolDown = CreateConVar("rtf_cooldown", "", "Time in seconds between reports per user. <Default: 30>");
	g_Cvar_AdvertInterval = CreateConVar("rtf_advertisement_frequency", "", "Time in seconds to display the advertisement 0 Turns it off. <Default: 180>");
	g_Cvar_Debug = CreateConVar("rtf_debug", "", "Enable this if you are having trouble.");
	
	/*Admin ConVars */
	g_Cvar_AdminAlert = CreateConVar("rtf_admin_alert", "", "Alert in game admins of the player that was reported");
	g_Cvar_AlertAdminBlockPost = CreateConVar("rtf_admin_nopost", "", "Block Posts to the forum if there is an admin");
	
	/* Valve ConVars */
	g_Cvar_HostName = FindConVar("hostname");
	g_Cvar_ServerIP = FindConVar("ip");
	g_Cvar_ServerPort = FindConVar("hostport");
	
	/* Execute Config File */
	if(FileExists("cfg/sourcemod/rtfsettings.cfg"))
		AutoExecConfig(false, "rtfsettings");
	else
	SetFailState("Missing rtfsettings.cfg. Check your cfg/sourcemod folder");
	
	/* Add Update */
	if(LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

/* Updater Settings On Late Load */
public OnLibraryAdded(const String:szName[])
{
	if(StrEqual(szName, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public Action:Updater_OnPluginChecking()
{
	PrintToServer("[UPDATER] Checking for update using URL: %s", UPDATE_URL);
}

public OnConfigsExecuted()
{
	/* Set the Forum Software ID */
	switch(GetConVarInt(g_Cvar_ForumSupport))
	{
		case 1: g_iForumSoftware = FORUM_VB4;
		case 2:	g_iForumSoftware = FORUM_MYBB;
		case 3:	g_iForumSoftware = FORUM_SMF;
		case 4:	g_iForumSoftware = FORUM_PHPBB;
		case 5: g_iForumSoftware = FORUM_WBBLITE;
		case 6: g_iForumSoftware = FORUM_AEF;
		case 7: g_iForumSoftware = FORUM_FLUXBB;
		case 8: g_iForumSoftware = FORUM_PHORUM;
		case 9: g_iForumSoftware = FORUM_USEBB;
		case 10: g_iForumSoftware = FORUM_XMB;
		case 11: g_iForumSoftware = FORUM_IPBOARDS;
		default: g_iForumSoftware = FORUM_UNSUPPORTED;
	}
	
	/* Connect To Database */
	if(g_iForumSoftware != FORUM_UNSUPPORTED)
	{
		if(!SQL_CheckConfig(g_szSQLSettings[g_iForumSoftware]))
		LogError("SQL Config not found. Check your databases.cfg");	
		else
		SQL_TConnect(MySQL_ConnectionCallback, g_szSQLSettings[g_iForumSoftware]);
		
		/* Display Which Forum Is Enabled */
		PrintToServer("[Report To Forums] Loading Settings for %s", g_szForumDescription[g_iForumSoftware]);
	}
	else
	{
		LogError("Invalid Value: rtf_board 1-4.");
	}
	
	/* Get the Prefix Name */
	GetConVarString(g_Cvar_ChatPrefix, g_szPrefix, sizeof(g_szPrefix));
	
	/* Get Table Prefix */
	GetConVarString(g_Cvar_TablePrefix, g_szTablePrefix, sizeof(g_szTablePrefix));
	
	/* Get Report Bot UserName */
	GetConVarString(g_Cvar_ReporterUserName, g_szUserName, sizeof(g_szUserName));
	
	/* Get Report Bot's UserID */
	g_iUserID = GetConVarInt(g_Cvar_ReporterID);
	
	/* Get the correct ForumID */
	g_iForumID = GetConVarInt(g_Cvar_ForumID);
	
	/* Builds a path to addons/sourcemod/configs */
	BuildPath(Path_SM, g_szFilePath, sizeof(g_szFilePath), "configs");
	Format(g_szFilePath, sizeof(g_szFilePath), "%s/rtf_rules.txt", g_szFilePath);
	
	/* Find the file and create the rules array */
	if(FileExists(g_szFilePath))
		CreateReasonArray();
	else
		LogError("Missing rtf_rules.txt. Please check your sourcemod configs folder.");
	
	/* Get the Server Name for Logging */
	GetConVarString(g_Cvar_HostName, g_szHostName, sizeof(g_szHostName));
	
	/* Get current map name for logging */
	GetCurrentMap(g_szMapName, sizeof(g_szMapName));
	if(StrContains(g_szMapName, "workshop", false) != -1)
	{
		decl String:szWorkShopID[32];
		GetCurrentWorkshopMap(g_szMapName, sizeof(g_szMapName), szWorkShopID, sizeof(szWorkShopID));
	}
}

public OnClientPostAdminCheck(iClient)
{
	if(CheckCommandAccess(iClient, "ThisIsNotUsedBro", ADMFLAG_KICK, true))
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

public MySQL_ConnectionCallback(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase != INVALID_HANDLE)
		g_hSQLDatabase = hDatabase;
	else
		LogError("Failed To Connect: %s", szError);
}

public OnMapStart()
{	
	/* Advertisement */
	if(GetConVarInt(g_Cvar_AdvertInterval))
		CreateTimer(GetConVarFloat(g_Cvar_AdvertInterval), Timer_ShowAdvertisement, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ShowAdvertisement(Handle:hTimer, any:data)
{
	/* Advertisement Text */
	PrintToChatAll("[%s] Type !report in chat or sm_report in console to report a player for breaking the rules.", g_szPrefix);
}

public Action:CMD_SMReport(iClient, iArgs)
{
	/* Get a unix timestamp (for checking the cool down and post date/time) */
	new iCurTime = GetTime();
	
	/* Compare the current time and the last time a player used the report function to see if the cooldown timer has elapsed */
	if((iCurTime - g_iTimeStamp[iClient]) < GetConVarInt(g_Cvar_ReportCoolDown))
	{
		new iTimeLeft = (GetConVarInt(g_Cvar_ReportCoolDown) - (iCurTime - g_iTimeStamp[iClient]));
		PrintToChat(iClient, "[%s] You must wait %d more seconds to use this command again.", g_szPrefix, iTimeLeft);
	}
	else
	{
		/* Check Debug Settings */
		if(GetConVarInt(g_Cvar_Debug) && g_hDebugArray[iClient] == INVALID_HANDLE)
			g_hDebugArray[iClient] = CreateArray(1024);
		
		/* Check If users can enter a Custom Command. */
		new bool:bShowMenus;
		if(iArgs >= 1)
		{
			decl String:szTargetName[MAX_TARGET_LENGTH], String:szArg[MAX_NAME_LENGTH];
			new iTargetCount, iTargetList[MAXPLAYERS], bool:tn_is_ml;
			
			GetCmdArg(1, szArg, sizeof(szArg));
			
			/* Process Target String */
			iTargetCount = ProcessTargetString(szArg, iClient, iTargetList, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_BOTS, szTargetName, sizeof(szTargetName), tn_is_ml);
			
			if(iTargetCount <= 0)
			{
				PrintToChat(iClient, "[ERROR] No users matching %s", g_szPrefix, szArg);
				return Plugin_Handled;
			}
			if(iTargetCount > 1)
			{
				PrintToChat(iClient, "[ERROR] More than 1 users matching %s", g_szPrefix, szArg);
				return Plugin_Handled;
			}
			
			/* Get Target Info */
			g_iTimeStamp[iClient] = GetTime();
			
			g_iTarget[iClient] = iTargetList[0];
			strcopy(g_szTargetName[iClient], sizeof(g_szTargetName[]), szTargetName);
			ParsePlayerName(szTargetName, g_szSafeTargetName[iClient], sizeof(g_szSafeTargetName[]));
			GetClientAuthString(g_iTarget[iClient], g_szTargetAuthId[iClient], sizeof(g_szTargetAuthId[]));
			GetClientIP(g_iTarget[iClient], g_szTargetIP[iClient], sizeof(g_szTargetIP[]));
			
			if(iArgs >= 2 && GetConVarInt(g_Cvar_AllowCustomReport))
			{
				decl String:szReason[256], String:szSafeReason[1024];
				GetCmdArg(2, szReason, sizeof(szReason));
				SQL_EscapeString(g_hSQLDatabase, szReason, szSafeReason, sizeof(szSafeReason));
				SetTrieString(g_hReasonDescription, "Custom", szSafeReason);
				g_iReason[iClient] = 0;
				CreateReportThread(iClient);
				bShowMenus = false;
				
				return Plugin_Handled;
			}
			
			if(g_iTotalReasons > -1)
			{
				DisplayMenu(g_hReasonMenu, iClient, MENU_TIME_FOREVER); //Checks to see if there are any rules added.
			}
			else
			{
				PrintToChat(iClient, "[%s] There are no reasons to choose from.", g_szPrefix);
				ClearTargetData(iClient);
			}
			bShowMenus = false;
		}
		else
		{
			bShowMenus = true;
		}
		
		if(bShowMenus)
		{
			/* Set up and Display the Target Menu */
			decl String:szMenuTitle[32];
			GetConVarString(g_Cvar_MainMenuTitle, szMenuTitle, sizeof(szMenuTitle));
			new Handle:hMenu = CreateMenu(Menu_SelectTarget);
			SetMenuTitle(hMenu, szMenuTitle);
			AddTargetsToMenu2(hMenu, iClient, COMMAND_FILTER_NO_IMMUNITY | COMMAND_FILTER_ALIVE | COMMAND_FILTER_NO_BOTS);
			SetMenuExitButton(hMenu, true);
			DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
		}
	}
	
	return Plugin_Handled;
}

public Menu_SelectTarget(Handle:hMenu, MenuAction:iAction, iClient, iItem)
{
	/* Handle the Selection */
	if(iAction == MenuAction_Select)
	{
		decl String:szMenuItem[32];
		GetMenuItem(hMenu, iItem, szMenuItem, sizeof(szMenuItem));
		g_iTarget[iClient] = GetClientOfUserId(StringToInt(szMenuItem)); //Get the Target selected from the menu
		
		GetClientName(g_iTarget[iClient], g_szTargetName[iClient], sizeof(g_szTargetName[])); //Gets the Targets Name
		GetClientAuthString(g_iTarget[iClient], g_szTargetAuthId[iClient], sizeof(g_szTargetAuthId[])); //Gets the Targets SteamID
		GetClientIP(g_iTarget[iClient], g_szTargetIP[iClient], sizeof(g_szTargetIP[])); //Gets the Targets IP
		ParsePlayerName(g_szTargetName[iClient], g_szSafeTargetName[iClient], sizeof(g_szSafeTargetName[]));
		
		if(g_iTotalReasons > -1)
		{
			DisplayMenu(g_hReasonMenu, iClient, MENU_TIME_FOREVER); //Checks to see if there are any rules added.
		}
		else
		{
			PrintToChat(iClient, "[%s] There are no reasons to choose from.", g_szPrefix);
			ClearTargetData(iClient);
		}
			
	}
	else if(iAction == MenuAction_End)
	{
		ClearTargetData(iClient);
	}
}

public Menu_ReportPlayer(Handle:hMenu, MenuAction:iAction, iClient, iItem)
{
	if(iAction == MenuAction_Select)
	{
		decl String:szMenuItem[32];
		GetMenuItem(hMenu, iItem, szMenuItem, sizeof(szMenuItem));
		g_iReason[iClient] = StringToInt(szMenuItem); //Set the Reason for reporting a player to the selection from the menu.
		g_iTimeStamp[iClient] = GetTime();
		
		if(GetConVarInt(g_Cvar_AlertAdminBlockPost))
		{
			if(g_iAdminCount)
			{
				/* Display Message to player saying player was reported. */
				decl String:szReason[32];
				GetArrayString(g_aReportReason, g_iReason[iClient], szReason, sizeof(szReason)); //Grab the reason from the array
				PrintToChat(iClient, "[%s] %s has been reported for %s", g_szPrefix, g_szSafeTargetName[iClient], szReason);
				AlertAdmins(iClient, szReason);
			}
			else
			{
				CreateReportThread(iClient);
			}
		}
		else
		{
			CreateReportThread(iClient);
		}
	}
	else if(iAction == MenuAction_End)
	{
		g_iTimeStamp[iClient] = g_iTimeStamp[0];
		ClearTargetData(iClient);
	}
}

/* Creates the Thread in which the report will be made */
public CreateReportThread(iClient)
{
	/* Format the Thread Title */
	decl String:szReason[32];
	GetArrayString(g_aReportReason, g_iReason[iClient], szReason, sizeof(szReason));
	Format(g_szThreadTitle[iClient], sizeof(g_szThreadTitle[]), "%s - %s", g_szSafeTargetName[iClient], szReason);
	
	/* Format SQL Query */
	decl String:szSQLQuery[512];
	
	switch(g_iForumSoftware)
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
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sforums (topic, t_bid, t_status, t_mem_id, t_approved) VALUES ('%s', '%d', '1', '%d', '1');", g_szTablePrefix, g_szThreadTitle[iClient], g_iForumID, g_iUserID);
		}
		case FORUM_FLUXBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %stopics (poster, subject, posted, last_post, last_poster, forum_id) VALUES ('%s', '%s', '%d', '%d', '%s', '%d');", g_szTablePrefix, g_szUserName, g_szThreadTitle[iClient], g_iTimeStamp[iClient], g_iTimeStamp[iClient], g_szUserName, g_iForumID);
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
			decl String:szSafeTitle[1024], String:szSafePosterName[1024];
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
	
	switch(g_iForumSoftware)
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
		case FORUM_FLUXBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT id FROM %stopics;", g_szTablePrefix);
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
	/* Create the Variables for the Thread Title and Content of the new post */
	new String:szContent[1024], String:szServerIP[32], String:szServerPort[32], String:szReason[32], String:szDescription[128];
	new String:szReporterName[MAX_NAME_LENGTH], String:szSafeReporterName[MAX_NAME_LENGTH * 2 + 1], String:szReporterIP[32], String:szReporterAuthID[32], String:szPosterEmail[32];
	
	/* Set the values for the above Variables */
	GetConVarString(g_Cvar_ServerIP, szServerIP, sizeof(szServerIP));
	GetConVarString(g_Cvar_ServerPort, szServerPort, sizeof(szServerPort));
	GetConVarString(g_Cvar_ReporterEmail, szPosterEmail, sizeof(szPosterEmail));
	GetClientAuthString(iClient, szReporterAuthID, sizeof(szReporterAuthID)); //Get the Reporting Parties IP address
	GetClientIP(iClient, szReporterIP, sizeof(szReporterIP)); //Get the IP of the reporting party
	GetClientName(iClient, szReporterName, sizeof(szReporterName)); //Get the name of the reporting party.
	ParsePlayerName(szReporterName, szSafeReporterName, sizeof(szSafeReporterName));
	
	/* Insert the Post Information found above */
	decl String:szSQLQuery[1024];
	
	GetArrayString(g_aReportReason, g_iReason[iClient], szReason, sizeof(szReason)); //Grab the reason from the array
	GetTrieString(g_hReasonDescription, szReason, szDescription, sizeof(szDescription)); //Get the description from the trie
	
	switch(g_iForumSoftware)
	{
		case FORUM_VB4:
		{
			Format(szContent, sizeof(szContent), "[b]Server Info[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]Offending Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]Reporting Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szSafeTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %spost (threadid, username, userid, title, dateline, pagetext, allowsmilie, visible, htmlstate) VALUES ('%d', '%s', '%d', '%s', '%d', '%s', '1', '1', 'on_nl2br');", g_szTablePrefix, g_iThreadID[iClient], g_szUserName, g_iUserID, g_szThreadTitle[iClient], g_iTimeStamp[iClient], szContent);			
		}
		case FORUM_MYBB:
		{
			Format(szContent, sizeof(szContent), "[b]Server Info[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]Offending Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]Reporting Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [color=#ff0000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szSafeTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (tid, fid, subject, uid, username, dateline, message, ipaddress, visible) VALUES ('%d', '%d', '%s', '%d', '%s', '%d', '%s', '%s', '1');", g_szTablePrefix, g_iThreadID[iClient], g_iForumID, g_szThreadTitle[iClient], g_iUserID, g_szUserName, g_iTimeStamp[iClient], szContent, szReporterIP);			
		}
		case FORUM_SMF:
		{
			Format(szContent, sizeof(szContent), "[b]Server Info[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]Offending Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]Reporting Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [color=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szSafeTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %smessages (id_topic, id_board, poster_time, id_member, subject, poster_name, poster_email, poster_ip, body, approved) VALUES ('%d', '%d', '%d', '%d', '%s', '%s', '%s', '%s', '%s', '1');", g_szTablePrefix, g_iThreadID[iClient], g_iForumID, g_iTimeStamp[iClient], g_iUserID, g_szThreadTitle[iClient], g_szUserName, szPosterEmail, szReporterIP, szContent);			
		}
		case FORUM_PHPBB:
		{
			/* Reformat the phpBB Version due to the bb code not working properly. */
			Format(szContent, sizeof(szContent), "Server Info - \nName: %s \nIP: %s:%s \nMap: %s \n\nOffending Party - \nName: %s \nSteamID: %s \nIP: %s \nReason: %s \nDescription: %s \n\nReporting Party - \nName: %s \nSteamID: %s \nIP: %s \n\nPost auto generated with \"Report to Forums\" by =NcB= SavSin", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szSafeTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (topic_id, forum_id, poster_id, poster_ip, post_time, post_approved, post_subject, post_text, post_postcount) VALUES ('%d', '%d', '%d', '%s', '%d', '1', '%s', '%s', '1');", g_szTablePrefix, g_iThreadID[iClient], g_iForumID, g_iUserID, g_szTargetIP[iClient], g_iTimeStamp[iClient], g_szThreadTitle[iClient], szContent);
		}
		case FORUM_WBBLITE:
		{
			Format(szContent, sizeof(szContent), "[b]Server Info[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]Offending Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]Reporting Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=10]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szSafeTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %spost (threadID, userID, username, message, time, enableSmilies, enableBBCodes, ipAddress) VALUES ('%d', '%d', '%s', '%s', '%d', '0', '1', '%s');", g_szTablePrefix, g_iThreadID[iClient], g_iUserID, g_szUserName, szContent, g_iTimeStamp[iClient], szReporterIP);
		}
		case FORUM_AEF:
		{
			Format(szContent, sizeof(szContent), "[b]Server Info[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]Offending Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]Reporting Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szSafeTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (post_tid, post_fid, ptime, poster_id, poster_ip, post, use_smileys, p_approved) VALUES ('%d', '%d', '%d', '%d', '%s', '%s', '0', '1');", g_szTablePrefix, g_iThreadID[iClient], g_iForumID, g_iTimeStamp[iClient], g_iUserID, szReporterIP, szContent);
		}
		case FORUM_FLUXBB:
		{
			Format(szContent, sizeof(szContent), "[b]Server Info[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]Offending Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]Reporting Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szSafeTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (poster, poster_id, poster_ip, poster_email, message, posted, topic_id) VALUES ('%s', '%d', '%s', '%s', '%s', '%d', '%d');", g_szTablePrefix, g_szUserName, g_iUserID, szReporterIP, szPosterEmail, szContent, g_iTimeStamp[iClient], g_iThreadID[iClient]);
		}
		case FORUM_USEBB:
		{
			Format(szContent, sizeof(szContent), "[b]Server Info[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]Offending Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]Reporting Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szSafeTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (topic_id, poster_id, poster_ip_addr, content, post_time, enable_smilies) VALUES ('%d', '%d', '%s', '%s', '%d', '0');", g_szTablePrefix, g_iThreadID[iClient], g_iUserID, szReporterIP, szContent, g_iTimeStamp[iClient]);
		}
		case FORUM_XMB:
		{
			Format(szContent, sizeof(szContent), "[b]Server Info[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]Offending Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]Reporting Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szSafeTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
			Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %sposts (fid, tid, author, message, subject, dateline, useip, bbcodeoff, smileyoff) VALUES ('%d', '%d', '%s', '%s', '%s', '%d', '%s', 'no', 'yes');", g_szTablePrefix, g_iForumID, g_iThreadID[iClient], g_szUserName, szContent, g_szThreadTitle[iClient], g_iTimeStamp[iClient]);
		}
		case FORUM_IPBOARDS:
		{
			Format(szContent, sizeof(szContent), "[b]Server Info[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]Offending Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]Reporting Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n\n [COLOR=#800000][SIZE=1]Post auto generated with \"Report to Forums\" by =NcB= SavSin[/size][/color]", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szSafeTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szSafeReporterName, szReporterAuthID, szReporterIP);			
			
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
		LogError("Failed: %s", szError);
	else
	{
		if(g_iForumSoftware != FORUM_MYBB)
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
	
	switch(g_iForumSoftware)
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
		case FORUM_FLUXBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT id FROM %sposts WHERE posted='%d';", g_szTablePrefix, g_iTimeStamp[iClient]);
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
		LogError("Failed To Select tid: %s", szError);
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
	
	switch(g_iForumSoftware)
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
		case FORUM_FLUXBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %stopics SET last_post_id=%d WHERE id=%d;", g_szTablePrefix, g_iPostID[iClient], g_iThreadID[iClient]);
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
		LogError("Failed To Select tid: %s", szError);
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
	
	switch(g_iForumSoftware)
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
		case FORUM_FLUXBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT num_posts, num_topics FROM %sforums WHERE id='%d';", g_szTablePrefix, g_iForumID);
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
		LogError("Failed To Select posts: %s", szError);
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
	
	switch(g_iForumSoftware)
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
		case FORUM_FLUXBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %sforums SET num_topics='%d', num_posts='%d', last_post='%d', last_post_id='%d', last_poster='%s' WHERE id='%d';", g_szTablePrefix, iThreadCount, iPostCount, g_iTimeStamp[iClient], g_iPostID[iClient], g_szUserName, g_iForumID);
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
	
	switch(g_iForumSoftware)
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
		case FORUM_FLUXBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "SELECT num_posts FROM %susers WHERE id='%d';", g_szTablePrefix, g_iUserID);
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
	
	switch(g_iForumSoftware)
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
		case FORUM_FLUXBB:
		{
			Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %susers SET last_post='%d', num_posts='%d' WHERE id=%d;", g_szTablePrefix, g_iTimeStamp[iClient], iPostCount, g_iUserID);
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
		decl String:szReason[32];
		GetArrayString(g_aReportReason, g_iReason[data], szReason, sizeof(szReason)); /* Grab the reason from the array */
		
		PrintToChat(data, "[%s] %s has been reported:%s", g_szPrefix, g_szTargetName[data], szReason);
		
		if(GetConVarInt(g_Cvar_Debug))
		{
			CreateDebugFile(data);
			ClearArray(g_hDebugArray[data]);
		}
		
		if(GetConVarInt(g_Cvar_AdminAlert))
			AlertAdmins(data, szReason);
		else
			ClearTargetData(data);
	}
}

public CreateDebugFile(iClient)
{
	decl String:szBuffer[1024], String:szDebugFile[PLATFORM_MAX_PATH];
	new iArraySize = GetArraySize(g_hDebugArray[iClient]);
	Format(szDebugFile, sizeof(szDebugFile), "addons/sourcemod/logs/%s%d.log", g_szDebugFriles[g_iForumSoftware], GetTime());
	new Handle:hFile = OpenFile(szDebugFile, "w");
	for(new i=0; i < iArraySize; i++)
	{
		GetArrayString(g_hDebugArray[iClient], i, szBuffer, sizeof(szBuffer));
		WriteFileLine(hFile, szBuffer);
		WriteFileLine(hFile, "");
	}
	CloseHandle(hFile);
}

/* Alert Admins if any of reported player */
stock AlertAdmins(iClient, const String:szReason[])
{
	decl String:szName[32];
	GetClientName(iClient, szName, sizeof(szName));
	for(new i=1; i<MaxClients;i++)
	{
		if(g_bIsUserAdmin[i] && iClient != i)
		{
			/* Display Message to admin saying player was reported. */
			PrintToChat(i, "[%s] %s has been reported: %s by %s", g_szPrefix, g_szTargetName[iClient], szReason, szName);
		}
	}
}

/* Clear Target Variables */
stock ClearTargetData(iClient)
{
	g_iTarget [iClient] = -1;
	g_szTargetName[iClient] = g_szTargetName[0];
	g_szTargetAuthId[iClient] = g_szTargetName[0];
	g_szTargetIP[iClient] = g_szTargetName[0];
	g_szThreadTitle[iClient] = g_szThreadTitle[0];
	g_iReason[iClient] = -1;
}

/* Creates the Rules array and Trie from the specified file */
stock CreateReasonArray()
{
	if(g_aReportReason == INVALID_HANDLE)
		g_aReportReason = CreateArray(128);
	
	if(g_hReasonDescription == INVALID_HANDLE)
		g_hReasonDescription = CreateTrie();
		
	decl String:szBuffer[128], String:szBufferSplit[2][128], String:szMenuTitle[32], String:szIndex[10];
	new iRuleCount = 0;
	GetConVarString(g_Cvar_ReportReasonTitle, szMenuTitle, sizeof(szMenuTitle));
	g_hReasonMenu = CreateMenu(Menu_ReportPlayer);
	SetMenuTitle(g_hReasonMenu, szMenuTitle);
	SetMenuExitButton(g_hReasonMenu, true);
	
	/* Add Custom Report */
	PushArrayString(g_aReportReason, "Custom");
	
	new Handle:hReportReasons = OpenFile(g_szFilePath, "r");
	while(ReadFileLine(hReportReasons, szBuffer, sizeof(szBuffer)))
	{
		if(!ParseLineOfText(szBuffer, false))
			continue;
			
		ExplodeString(szBuffer, "\" \"", szBufferSplit, 2, 127);
		ReplaceString(szBufferSplit[0], 127, "\"", "", false); 
		ReplaceString(szBufferSplit[1], 127, "\"", "", false);
		g_iTotalReasons = PushArrayString(g_aReportReason, szBufferSplit[0]);
		SetTrieString(g_hReasonDescription, szBufferSplit[0], szBufferSplit[1]);
		IntToString(iRuleCount, szIndex, sizeof(szIndex));
		AddMenuItem(g_hReasonMenu, szIndex, szBufferSplit[0]);
		++iRuleCount;
	}
	
	CloseHandle(hReportReasons);
}

stock ParsePlayerName(const String:szString[], String:szBuffer[], len)
{
	SQL_EscapeString(g_hSQLDatabase, szString, szBuffer, len);
	ReplaceString(szBuffer, len, "}", "");
	ReplaceString(szBuffer, len, "{", "");
}

stock GetWebSafeString(const String:szString[], String:szBuffer[], len)
{
	strcopy(szBuffer, len, szString);	
	ReplaceString(szBuffer, len, " ", "-");
}

stock bool:ParseLineOfText(String:szString[], bool:bStripQuotes)
{
	if((szString[0] == '/' && szString[1] == '/') //Check for // type comment
	|| szString[0] == ';' //check for ; type comment
	|| strlen(szString) <= 2 //Make sure its not just a blank line
	|| IsCharSpace(szString[0])) //checks for a space as the first character.
	return false;
	
	TrimString(szString); //remove the new line characters.
	
	if(bStripQuotes)
		StripQuotes(szString); //Strip the quotes from the file.
	
	return true;
}

//Returns the correct map for CSGO
stock GetCurrentWorkshopMap(String:szMap[], iMapBuf, String:szWorkShopID[], iWorkShopBuf)
{
	decl String:szCurMapSplit[2][64];
	
	ReplaceString(szMap, iMapBuf, "workshop/", "", false);
	ExplodeString(szMap, "/", szCurMapSplit, 2, 64);
	
	strcopy(szMap, iMapBuf, szCurMapSplit[1]);
	strcopy(szWorkShopID, iWorkShopBuf, szCurMapSplit[0]);
}