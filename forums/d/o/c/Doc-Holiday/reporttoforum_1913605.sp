/*  Plugin Created by Request from Lyric
 *  Created by SavSin
 */
#pragma semicolon 1

#include <sourcemod>
#include <dbi>

new const String:PLUGIN_VERSION[] = "1.1.0";

/* Valve ConVars */
new Handle:g_Cvar_HostName = INVALID_HANDLE;
new Handle:g_Cvar_ServerIP = INVALID_HANDLE;
new Handle:g_Cvar_ServerPort = INVALID_HANDLE;

/* Menu ConVars */
new Handle:g_Cvar_MainMenuTitle = INVALID_HANDLE;
new Handle:g_Cvar_ReportReasonTitle = INVALID_HANDLE;

/* Settings ConVars */
new Handle:g_Cvar_ReportCoolDown = INVALID_HANDLE;
new Handle:g_Cvar_AdvertInterval = INVALID_HANDLE;
new Handle:g_Cvar_ChatPrefix = INVALID_HANDLE;

/* SQL ConVars */
new Handle:g_Cvar_ReporterID = INVALID_HANDLE;
new Handle:g_Cvar_ReporterUserName = INVALID_HANDLE;
new Handle:g_Cvar_ForumID = INVALID_HANDLE;
new Handle:g_Cvar_ThreadTableName = INVALID_HANDLE;
new Handle:g_Cvar_PostTableName = INVALID_HANDLE;
new Handle:g_Cvar_ForumTableName = INVALID_HANDLE;
new Handle:g_Cvar_UserTableName = INVALID_HANDLE;

/* Data Handlers */
new Handle:g_hSQLDatabase = INVALID_HANDLE;
new Handle:g_aReportReason = INVALID_HANDLE;
new Handle:g_hReasonDescription = INVALID_HANDLE;
new Handle:g_hReasonMenu = INVALID_HANDLE;

/* Target Variables */
new g_iTarget [MAXPLAYERS+1];
new String:g_szTargetName[MAXPLAYERS+1][32];
new String:g_szTargetAuthId[MAXPLAYERS+1][32];
new String:g_szTargetIP[MAXPLAYERS+1][32];
new g_iReason[MAXPLAYERS+1];

/* Server Info Variables */
new String:g_szMapName[32];
new String:g_szHostName[32];

/* Misc Variables */
new g_iTimeStamp[MAXPLAYERS+1];
new g_iThreadID[MAXPLAYERS+1];
new String:g_szThreadTitle[MAXPLAYERS+1][64];
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
	/* Register Console Command to report */
	RegConsoleCmd("sm_report", CMD_SMReport, "Report a user with this command");
	
	/* Table Names */
	g_Cvar_ThreadTableName = CreateConVar("rtf_thread_table", "mybb_threads", "Table to modify for threads.");
	g_Cvar_PostTableName = CreateConVar("rtf_post_table", "mybb_posts", "Table name for the posts");
	g_Cvar_ForumTableName = CreateConVar("rtf_forum_table", "mybb_forums", "Table name for the posts");
	g_Cvar_UserTableName = CreateConVar("rtf_user_table", "mybb_users", "Table name for the posts");
	
	/* Forum and User Id's */
	g_Cvar_ForumID = CreateConVar("rtf_forumid", "2", "forum id to make the post in.");
	g_Cvar_ReporterID = CreateConVar("rtf_reporterid", "2", "userid to make the post under.");
	g_Cvar_ReporterUserName = CreateConVar("rtf_reporter_username", "Reporter", "Username from your forum");
	
	/* Title ConVars */
	g_Cvar_MainMenuTitle = CreateConVar("rtf_mainmenu_title", "Select a Player", "Title to the target menu");
	g_Cvar_ReportReasonTitle = CreateConVar("rtf_submenu_title", "Select a Reason.", "Title for the sub menu where the reasons are");
	
	/* Settings ConVars */
	g_Cvar_ChatPrefix = CreateConVar("sm_prefix", "Sourcemod", "Prefix for chat messages from the plugin. <Default: Sourcemod>");
	g_Cvar_ReportCoolDown = CreateConVar("rtf_cooldown", "30", "Time in seconds between reports per user. <Default: 30>");
	g_Cvar_AdvertInterval = CreateConVar("rtf_advertisement_frequency", "180", "Time in seconds to display the advertisement. <Default: 180>");
	
	/* Valve ConVars */
	g_Cvar_HostName = FindConVar("hostname");
	g_Cvar_ServerIP = FindConVar("ip");
	g_Cvar_ServerPort = FindConVar("hostport");
	
	/* Get the Prefix Name */
	GetConVarString(g_Cvar_ChatPrefix, g_szPrefix, sizeof(g_szPrefix));
	
	/* Connect To Database */
	SQL_TConnect(MySQL_ConnectionCallback, "rtfsettings");
	if(!SQL_CheckConfig("rtfsettings"))
		LogError("SQL Config not found. Check your databases.cfg");
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
	/* Read the file and load up the reasons */
	BuildPath(Path_SM, g_szFilePath, sizeof(g_szFilePath), "configs");
	Format(g_szFilePath, sizeof(g_szFilePath), "%s/rtf_rules.txt", g_szFilePath);
	
	if(FileExists(g_szFilePath))
		CreateReasonArray();
	else
		LogError("Missing rtf_rules.txt. Please check your sourcemod configs folder.");
	
	/* Get current map name for logging */
	GetCurrentMap(g_szMapName, sizeof(g_szMapName));
	if(StrContains(g_szMapName, "workshop", false) != -1)
	{
		decl String:szWorkShopID[32];
		GetCurrentWorkshopMap(g_szMapName, sizeof(g_szMapName), szWorkShopID, sizeof(szWorkShopID));
	}
	
	/* Get the Server Name for Logging */
	GetConVarString(g_Cvar_HostName, g_szHostName, sizeof(g_szHostName));
	
	/* Advertisement */
	CreateTimer(GetConVarFloat(g_Cvar_AdvertInterval), Timer_ShowAdvertisement, INVALID_HANDLE, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_ShowAdvertisement(Handle:hTimer, any:data)
{
	/* Advertisement Text */
	PrintToChatAll("\x01\x02[%s] \x01Type \x04!report\x01 in chat or \x04sm_report\x01 in console to report a player for breaking the rules.", g_szPrefix);
}

public Action:CMD_SMReport(iClient, iArgs)
{
	/* Get a unix timestamp (for checking the cool down and post date/time) */
	new iCurTime = GetTime();
	
	/* Compare the current time and the last time a player used the report function to see if the cooldown timer has elapsed */
	if((iCurTime - g_iTimeStamp[iClient]) < GetConVarInt(g_Cvar_ReportCoolDown))
	{
		new iTimeLeft = (GetConVarInt(g_Cvar_ReportCoolDown) - (iCurTime - g_iTimeStamp[iClient]));
		PrintToChat(iClient, "\x01\x02[%s] \x01You must wait \x04%d \x01 more seconds to use this command again.", g_szPrefix, iTimeLeft);
	}
	else
	{
		/* Set up and Display the Target Menu */
		decl String:szMenuTitle[32];
		GetConVarString(g_Cvar_MainMenuTitle, szMenuTitle, sizeof(szMenuTitle));
		new Handle:hMenu = CreateMenu(Menu_SelectTarget);
		SetMenuTitle(hMenu, szMenuTitle);
		AddPlayersToMenu(hMenu); // AddPlayersToMenu(Handle:menu, bIncludeBots=false);
		SetMenuExitButton(hMenu, true);
		DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
		g_iTimeStamp[iClient] = iCurTime;
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
		
		GetClientName(g_iTarget[iClient], g_szTargetName[iClient], 31); //Gets the Targets Name
		GetClientAuthString(g_iTarget[iClient], g_szTargetAuthId[iClient], 31); //Gets the Targets SteamID
		GetClientIP(g_iTarget[iClient], g_szTargetIP[iClient], 31); //Gets the Targets IP
		
		if(g_iTotalReasons > -1)
		{
			DisplayMenu(g_hReasonMenu, iClient, MENU_TIME_FOREVER); //Checks to see if there are any rules added.
		}
		else
		{
			PrintToChat(iClient, "\x01 \x02[%s] \x01There are no reasons to choose from.", g_szPrefix);
			g_iTimeStamp[iClient] = 0;
		}
			
	}
	else if(iAction == MenuAction_End)
	{
		g_iTimeStamp[iClient] = 0;
	}
}

public Menu_ReportPlayer(Handle:hMenu, MenuAction:iAction, iClient, iItem)
{
	if(iAction == MenuAction_Select)
	{
		decl String:szMenuItem[32];
		GetMenuItem(hMenu, iItem, szMenuItem, sizeof(szMenuItem));
		g_iReason[iClient] = StringToInt(szMenuItem); //Set the Reason for reporting a player to the selection from the menu.
		CreateReportThread(iClient);
	}
	else if(iAction == MenuAction_End)
	{
		g_iTimeStamp[iClient] = 0;
	}
}

/* Creates the Thread in which the report will be made */
public CreateReportThread(iClient)
{
	/* Variables for the Thread */
	decl String:szThreadTitle[64], String:szReason[32];
	
	/* Get The Reason for the Report */
	GetArrayString(g_aReportReason, g_iReason[iClient], szReason, sizeof(szReason));
	
	/* Variables for the 'threads table' */
	decl String:szThreadTable[32], String:szUserName[32];
	new iForumID, iReporterID;
	GetConVarString(g_Cvar_ThreadTableName, szThreadTable, sizeof(szThreadTable)); //mybb_threads
	GetConVarString(g_Cvar_ReporterUserName, szUserName, sizeof(szUserName)); //username
	iForumID = GetConVarInt(g_Cvar_ForumID); //fid
	iReporterID = GetConVarInt(g_Cvar_ReporterID); //uid
	
	/* Format the Thread Title */
	Format(szThreadTitle, sizeof(szThreadTitle), "%s - %s",g_szTargetName[iClient], szReason);
	
	/* Format SQL Query */
	decl String:szSQLQuery[512];
	Format(szSQLQuery, sizeof(szSQLQuery), "INSERT INTO %s (fid, subject, uid, username, dateline, firstpost, lastpost, visible) VALUES ('%d', '%s', '%d', '%s', '%d', '1', '%d', '1');", szThreadTable, iForumID, szThreadTitle, iReporterID, szUserName, g_iTimeStamp[iClient], g_iTimeStamp[iClient]);
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
	decl String:szSQLQuery[512], String:szThreadTable[32];
	GetConVarString(g_Cvar_ThreadTableName, szThreadTable, sizeof(szThreadTable)); //mybb_threads
	Format(szSQLQuery, sizeof(szSQLQuery), "SELECT tid FROM %s WHERE dateline='%d';", szThreadTable, g_iTimeStamp[iClient]);
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
	decl String:szContent[512], String:szServerIP[32], String:szServerPort[32], String:szReason[32], String:szDescription[128];
	decl String:szReporterName[32], String:szReporterIP[32], String:szReporterAuthID[32];
	decl String:szPostTitle[32];
	
	/* Set the values for the above Variables */
	GetConVarString(g_Cvar_ServerIP, szServerIP, sizeof(szServerIP));
	GetConVarString(g_Cvar_ServerPort, szServerPort, sizeof(szServerPort));
	GetArrayString(g_aReportReason, g_iReason[iClient], szReason, sizeof(szReason)); //Grab the reason from the array
	GetTrieString(g_hReasonDescription, szReason, szDescription, sizeof(szDescription)); //Get the description from the trie
	GetClientAuthString(iClient, szReporterAuthID, sizeof(szReporterAuthID)); //Get the Reporting Parties IP address
	GetClientIP(iClient, szReporterIP, sizeof(szReporterIP)); //Get the IP of the reporting party
	GetClientName(iClient, szReporterName, sizeof(szReporterName)); //Get the name of the reporting party.
	
	Format(szPostTitle, sizeof(szPostTitle), "%s - %s",g_szTargetName[iClient], szReason);
	strcopy(g_szThreadTitle[iClient], 63, szPostTitle);
	
	Format(szContent, sizeof(szContent), "[b]Server Info[/b] - \n[b]Name[/b]: %s \n[b]IP[/b]: %s:%s \n[b]Map[/b]: %s \n\n[b]Offending Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s \n[b]Reason[/b]: %s \n[b]Description[/b]: %s \n\n[b]Reporting Party[/b] - \n[b]Name[/b]: %s \n[b]SteamID[/b]: %s \n[b]IP[/b]: %s", g_szHostName, szServerIP, szServerPort, g_szMapName, g_szTargetName[iClient], g_szTargetAuthId[iClient], g_szTargetIP[iClient], szReason, szDescription, szReporterName, szReporterAuthID, szReporterIP);
	
	/* Insert the Post Information found above */
	decl String:szPostTable[32], String:szReporterUserName[32], String:szSQLInsertContentQuery[1024];
	GetConVarString(g_Cvar_PostTableName, szPostTable, sizeof(szPostTable));
	GetConVarString(g_Cvar_ReporterUserName, szReporterUserName, sizeof(szReporterUserName)); //Username of the Report-Bot
	
	Format(szSQLInsertContentQuery, sizeof(szSQLInsertContentQuery), "INSERT INTO %s (tid, fid, subject, uid, username, dateline, message, ipaddress, visible) VALUES ('%d', '%d', '%s', '%d', '%s', '%d', '%s', '%s', '1');", szPostTable, g_iThreadID[iClient], GetConVarInt(g_Cvar_ForumID), szPostTitle, GetConVarInt(g_Cvar_ReporterID), szReporterUserName, g_iTimeStamp[iClient], szContent, szReporterIP);
	SQL_TQuery(g_hSQLDatabase, MySQL_InsertPostContent, szSQLInsertContentQuery, iClient);
}

public MySQL_InsertPostContent(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed: %s", szError);
	else
	{
		decl String:szReason[32];
		GetArrayString(g_aReportReason, g_iReason[data], szReason, sizeof(szReason)); //Grab the reason from the array
		PrintToChat(data, "\x01\x02[%s] \x04%s \x01has been reported for \x04%s", g_szPrefix, g_szTargetName[data], szReason);
		GetCurrentForumPostData(data);
	}
}

/* Gets the Current Post and Thread count for the specified thread */
public GetCurrentForumPostData(iClient)
{
	/* Search mybb_forums to retrieve the post count */
	decl String:szSQLQuery[512], String:szForumTable[32];
	GetConVarString(g_Cvar_ForumTableName, szForumTable, sizeof(szForumTable)); //mybb_forums
	Format(szSQLQuery, sizeof(szSQLQuery), "SELECT posts, threads FROM %s WHERE fid='%d';", szForumTable, GetConVarInt(g_Cvar_ForumID));
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
	decl String:szSQLQuery[1024], String:szForumTable[32], String:szReporterUserName[32];
	GetConVarString(g_Cvar_ForumTableName, szForumTable, sizeof(szForumTable)); //mybb_forums
	GetConVarString(g_Cvar_ReporterUserName, szReporterUserName, sizeof(szReporterUserName));
	Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %s SET threads='%d', posts='%d', lastpost='%d', lastposter='%s', lastposteruid='%d', lastposttid='%d', lastpostsubject='%s' WHERE fid='%d';", szForumTable, iThreadCount, iPostCount, g_iTimeStamp[iClient], szReporterUserName, GetConVarInt(g_Cvar_ReporterID), g_iThreadID[iClient], g_szThreadTitle[iClient], GetConVarInt(g_Cvar_ForumID));
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
	decl String:szSQLQuery[512], String:szUserTable[32];
	GetConVarString(g_Cvar_UserTableName, szUserTable, sizeof(szUserTable)); //mybb_users
	Format(szSQLQuery, sizeof(szSQLQuery), "SELECT postnum FROM %s WHERE uid='%d';", szUserTable, GetConVarInt(g_Cvar_ReporterID));
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
	decl String:szSQLQuery[512], String:szUserTable[32];
	GetConVarString(g_Cvar_UserTableName, szUserTable, sizeof(szUserTable)); //mybb_users
	Format(szSQLQuery, sizeof(szSQLQuery), "UPDATE %s SET postnum=%d WHERE uid=%d;", szUserTable, iPostCount, GetConVarInt(g_Cvar_ReporterID));
	SQL_TQuery(g_hSQLDatabase, MySQL_UpdateUserPostCount, szSQLQuery, iClient);
}

public MySQL_UpdateUserPostCount(Handle:hOwner, Handle:hDatabase, const String:szError[], any:data)
{
	if(hDatabase == INVALID_HANDLE)
		LogError("Failed To Update User Post Data: %s", szError);
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
		LogMessage("Added Rule: %s", szBufferSplit[0]);
		++iRuleCount;
	}
	
	CloseHandle(hReportReasons);
}

stock AddPlayersToMenu(Handle:hMenu, bool:bIncludeBots = false)
{
	decl String:szUserId[3], String:szPlayerName[32];
	for(new i=1; i <= MaxClients; i++)
	{
		if(!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		IntToString(GetClientUserId(i), szUserId, sizeof(szUserId));
		GetClientName(i, szPlayerName, sizeof(szPlayerName));
		AddMenuItem(hMenu, szUserId, szPlayerName);
	}
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