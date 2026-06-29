// Signal

// 1.1.0
//	Added translations
//	Improved auto-add friend system

// 1.1.1
//	Minor bugfix (inbox appearance)

// 1.1.2
//	Client-specific translations

// 1.1.3
//	Added CVAR "signalpm_pollinterval"
//	Minor bugfix in reconnect after DB failure

// 1.1.4
//	Added console commands for all chat triggers

// 1.1.5
//	Tidied up the code a bit :)

// 1.1.6
//	Added lower limit for poll interval

// 1.2.0
//	Added groups functionality
//	Added an outbox (messages are now retained and flagged deleted)

// 1.2.1
//	Added online/offline indicator in friend/recipient list
//	Player names now visible in outbox
//	Commands for managing auto-add/server friends added
//	Command for adding friends by SteamID added
//	Player names stored on connect for more reliable identification

// 1.2.2
//	Bugfix to stop multiple poll timers being created

// 1.3.0
//	SQLite support

// 1.3.1
//	Option to show new message notification as hint text

// 1.3.2
//	Now uses "0" key to close all panels (consistency)

// 1.3.3
//  Ignores bots
//  Some SQL bugs fixed

// 1.4.0
//  Several SQL bugs fixed
//  Some back options fixed on menus
//  Fixed online indicator

// 1.4.1
//  Applied workarounds for L4D2 panel bug

// 1.4.2
//  Fixed problems with client 0 (console) running pmaddserverfriend
//  MySQL tables now use primary keys instead of unique keys by default
//  Removed invalid char from received message view

// TODO :: Ignore STEAM_X: part of SteamID (start at char 8)

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define PLUGIN_VERSION "1.4.2"
#pragma semicolon 1

#define OP_SENDPM 1

new Handle:g_cvar_database;
new Handle:g_cvar_table;
new String:table_e[32];
new Handle:g_cvar_floodlimit;
new Handle:g_cvar_pollinterval;
new Handle:g_cvar_notifytype;

new String:g_SteamIdQueryList[(MAXPLAYERS + 1) * 32];
new String:g_SteamId_cache[MAXPLAYERS + 1][32];
new g_messageLastViewed[MAXPLAYERS + 1];
new String:g_userIdLastViewed[MAXPLAYERS + 1][32];
new String:g_userNameLastViewed[MAXPLAYERS + 1][64];
new String:g_messageToSend[MAXPLAYERS + 1][256];
new g_messagesSentInTheLastMin[MAXPLAYERS + 1];
new g_groupsCreatedInTheLastMin[MAXPLAYERS + 1];
new bool:g_userHasGroups[MAXPLAYERS + 1]; // Used for recipient list query

new Handle:db;
new bool:g_lastPollUnsuccessful = false;
new g_lastDBattempt = 0;
new Handle:g_operationqueue;
new bool:g_isSQLite = false;

new Handle:g_pollTimer;

public Plugin:myinfo = {
	name = "Signal",
	author = "Scone",
	description = "In-game PM System",
	version = PLUGIN_VERSION,
	url = "http://scone.ws/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
   CreateNative("SendPrivateMessage", Native_SendPrivateMessage);
   return APLRes_Success;
}

public OnPluginStart() {
	// Server variables
	g_cvar_table = CreateConVar("signalpm_table", "signal", "The MySQL table name to use", FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_PROTECTED);
	g_cvar_database = CreateConVar("signalpm_database", "default", "The SourceMod database configuration to use", FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_PROTECTED);
	g_cvar_floodlimit = CreateConVar("signalpm_floodlimit_onemin", "5", "The number of messages a user can send every minute", FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_PROTECTED);
	g_cvar_pollinterval = CreateConVar("signalpm_pollinterval", "12", "The number of seconds to wait between checking for new messages", FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_PROTECTED);
	g_cvar_notifytype = CreateConVar("signalpm_notifytype", "0", "Where to show the new message notification. 0:Chat, 1:Hint", FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_PROTECTED);

	// Set up the operation queue (well, stack)
	g_operationqueue = CreateStack();
	CreateTimer(20.0, Timer_FlushQueue, _, TIMER_REPEAT);
	
	// Reset the flood limit
	CreateTimer(60.0, Timer_ResetFloodLimit, _, TIMER_REPEAT);
	
	// User commands
	RegConsoleCmd("say", 			Command_Say);
	RegConsoleCmd("say_team", 		Command_Say);
	
	RegConsoleCmd("pm", 				Command_Pm, 				"Opens the Signal main menu");
	RegConsoleCmd("pmsend", 			Command_PmSend, 			"Send a PM to someone in your friends list");
	RegConsoleCmd("pmreply", 		Command_PmReply, 		"Reply to the last PM you viewed");
	RegConsoleCmd("pmcreategroup", 	Command_PmCreateGroup, "Create a group");
	RegConsoleCmd("pmaddfriend", 	Command_PmAddFriend, 	"Add a friend by SteamID");
	RegConsoleCmd("pmdeletegroup", 	Command_PmDeleteGroup, "Delete a group");
	RegConsoleCmd("pmfriends", 		Command_PmFriends, 		"View your friends list");
	RegConsoleCmd("pmblocks", 		Command_PmBlocks, 		"View your block list");
	RegConsoleCmd("pmgroups", 		Command_PmGroups, 		"View your groups");
	RegConsoleCmd("pminbox", 		Command_PmInbox, 		"View your inbox");
	RegConsoleCmd("pmoutbox", 		Command_PmOutbox, 		"View your outbox");
	RegConsoleCmd("pmhelp", 			Command_PmHelp, 			"View the Signal help menu");
	
	RegAdminCmd("pmaddserverfriend", 	Command_PmAddServerFriend, 		ADMFLAG_ROOT, "Add a global server friend");
	RegAdminCmd("pmdeleteserverfriend", 	Command_PmDeleteServerFriend, 	ADMFLAG_ROOT, "Delete a global server friend");
	
	// Build SteamID cache
	for(new client = 1; client <= MaxClients; client++)
		if(IsClientInGame(client))
			GetClientAuthString(client, g_SteamId_cache[client], sizeof(g_SteamId_cache[]));
	
	// Generate some configs
	AutoExecConfig(true, "signal");
	
	// Load the translations
	LoadTranslations("signal.phrases");
}

public Action:Timer_ResetFloodLimit(Handle:timer) {
	for(new client = 1; client <= MaxClients; client++) {
		g_messagesSentInTheLastMin[client] = 0;
		g_groupsCreatedInTheLastMin[client] = 0;
	}
}

public Action:Command_Pm(client, args) {
	if(AtServerConsole(client)) return Plugin_Continue;
	showMenu_Main(client);
	return Plugin_Handled;
}

public Action:Command_PmFriends(client, args) {
	if(AtServerConsole(client)) return Plugin_Continue;
	showMenu_Friends(client);
	return Plugin_Handled;
}

public Action:Command_PmBlocks(client, args) {
	if(AtServerConsole(client)) return Plugin_Continue;
	showMenu_Blocklist(client);
	return Plugin_Handled;
}

public Action:Command_PmGroups(client, args) {
	if(AtServerConsole(client)) return Plugin_Continue;
	showMenu_Groups(client);
	return Plugin_Handled;
}

public Action:Command_PmInbox(client, args) {
	if(AtServerConsole(client)) return Plugin_Continue;
	showMenu_Inbox(client);
	return Plugin_Handled;
}

public Action:Command_PmOutbox(client, args) {
	if(AtServerConsole(client)) return Plugin_Continue;
	showMenu_Outbox(client);
	return Plugin_Handled;
}

public Action:Command_PmHelp(client, args) {
	if(AtServerConsole(client)) return Plugin_Continue;
	showMenu_Help(client);
	return Plugin_Handled;
}

public Action:Command_PmSend(client, args) {
	
	if(AtServerConsole(client)) return Plugin_Continue;
	
	new floodlimit = GetConVarInt(g_cvar_floodlimit);
	if(g_messagesSentInTheLastMin[client] >= floodlimit) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "Message limit reached", client, floodlimit);
		return Plugin_Handled;
	}
	
	if(args < 1) {
		PrintToChat(client, "\x04[Signal]\x01 %T: pmsend <%T>", "Usage", client, "Sample message text", client);
		return Plugin_Handled;
	}
	
	decl String:message[256];
	GetCmdArgString(message, sizeof(message));
	
	strcopy(g_messageToSend[client], sizeof(g_messageToSend[]), message);
	showMenu_Recipient(client);
	return Plugin_Handled;
}

public Action:Command_PmReply(client, args) {
	
	if(AtServerConsole(client)) return Plugin_Continue;

	new floodlimit = GetConVarInt(g_cvar_floodlimit);
	if(g_messagesSentInTheLastMin[client] >= floodlimit) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "Message limit reached", client, floodlimit);
		return Plugin_Handled;
	}
	
	if(args < 1) {
		PrintToChat(client, "\x04[Signal]\x01 %T: pmreply <%T>", "Usage", client, "Sample message text", client);
		return Plugin_Handled;
	}
	
	decl String:message[256];
	GetCmdArgString(message, sizeof(message));
	
	if(strlen(g_userIdLastViewed[client]) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "No message viewed", client);
		return Plugin_Handled;
	}
	
	decl String:sourceName[64];
	GetClientName(client, sourceName, sizeof(sourceName));
	
	SendPM(sourceName, g_SteamId_cache[client], g_userIdLastViewed[client], message);
	processOperationQueue();
	PrintToChat(client, "\x04[Signal]\x01 %T", "Message sent.", client);
	g_messagesSentInTheLastMin[client]++;
	return Plugin_Handled;
}

public Action:Command_PmCreateGroup(client, args) {

	if(AtServerConsole(client)) return Plugin_Continue;
	
	if(g_groupsCreatedInTheLastMin[client] >= 3) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "Group creation limit reached", client);
		return Plugin_Handled;
	}
	
	if(args < 1) {
		PrintToChat(client, "\x04[Signal]\x01 %T: pmcreategroup <%T>", "Usage", client, "Sample group name", client);
		return Plugin_Handled;
	}
	
	decl String:groupName[64];
	GetCmdArgString(groupName, sizeof(groupName));
	
	CreateGroup(groupName, g_SteamId_cache[client], client);
	g_groupsCreatedInTheLastMin[client]++;
	return Plugin_Handled;
}

public Action:Command_PmDeleteGroup(client, args) {
	if(AtServerConsole(client)) return Plugin_Continue;
	showMenu_DelGroup(client);
	return Plugin_Handled;
}

public Action:Command_PmAddFriend(client, args) {

	if(AtServerConsole(client)) return Plugin_Continue;
	
	if(args != 1) {
		ReplyToCommand(client, "[Signal] %T: pmaddfriend \"SteamID\"", "Usage", client);
		return Plugin_Handled;
	}
	
	decl String:friendId[32];
	GetCmdArg(1, friendId, sizeof(friendId));
	AddFriendDetectName(g_SteamId_cache[client], friendId, client);
	
	return Plugin_Handled;
}

public Action:Command_PmAddServerFriend(client, args) {
	
	if(args != 1) {
		ReplyToCommand(client, "[Signal] %T: pmaddserverfriend \"SteamID\"", "Usage", client);
		return Plugin_Handled;
	}
	
	decl String:friendId[32];
	GetCmdArg(1, friendId, sizeof(friendId));
	AddFriendDetectName("all", friendId, client);
	
	return Plugin_Handled;
}

public Action:Command_PmDeleteServerFriend(client, args) {
	
	if(args != 1) {
		ReplyToCommand(client, "[Signal] %T: pmdeleteserverfriend \"SteamID\"", "Usage", client);
		return Plugin_Handled;
	}
	
	decl String:friendId[32];
	GetCmdArg(1, friendId, sizeof(friendId));
	
	RemoveFriend("all", friendId, client);
	
	return Plugin_Handled;
}

public Action:Command_Say(client, args) {

	decl String:arguments[256], String:command[64];

	if (GetCmdArgString(arguments, sizeof(arguments)) < 1)
		return Plugin_Handled;
		
	new start = 0;
	new lastchar = strlen(arguments) - 1;

	if (arguments[lastchar] == '"') {
		arguments[lastchar] = '\0';
		start = 1;
	}
	
	start += BreakString(arguments[start], command, sizeof(command));
	
	if(StrEqual(command, "pm", false) || StrEqual(command, "signal", false))
		showMenu_Main(client);
	
	else if(StrEqual(command, "pminbox", false))
		showMenu_Inbox(client);
		
	else if(StrEqual(command, "pmoutbox", false))
		showMenu_Outbox(client);
	
	else if(StrEqual(command, "pmfriends", false))
		showMenu_Friends(client);
	
	else if(StrEqual(command, "pmblocks", false))
		showMenu_Blocklist(client);
		
	else if(StrEqual(command, "pmgroups", false))
		showMenu_Groups(client);
	
	else if(StrEqual(command, "pmsend", false) || StrEqual(command, "sendpm", false)) {
	
		new floodlimit = GetConVarInt(g_cvar_floodlimit);
		
		if(g_messagesSentInTheLastMin[client] >= floodlimit) {
			PrintToChat(client, "\x04[Signal]\x01 %T", "Message limit reached", client, floodlimit);
			return Plugin_Handled;
		}
		
		if(start <= 3) {
			PrintToChat(client, "\x04[Signal]\x01 %T: pmsend <%T>", "Usage", client, "Sample message text", client);
			return Plugin_Handled;
		}
		
		strcopy(g_messageToSend[client], sizeof(g_messageToSend[]), arguments[start]);
		showMenu_Recipient(client);
		return Plugin_Handled;
		
	} else if(StrEqual(command, "pmreply", false)) {
	
		new floodlimit = GetConVarInt(g_cvar_floodlimit);
	
		if(g_messagesSentInTheLastMin[client] >= floodlimit) {
			PrintToChat(client, "\x04[Signal]\x01 %T", "Message limit reached", client, floodlimit);
			return Plugin_Handled;
		}
		
		if(start <= 3) {
			PrintToChat(client, "\x04[Signal]\x01 %T: pmreply <%T>", "Usage", client, "Sample message text", client);
			return Plugin_Handled;
		}
		
		if(strlen(g_userIdLastViewed[client]) == 0) {
			PrintToChat(client, "\x04[Signal]\x01 %T", "No message viewed", client);
			return Plugin_Handled;
		}
		
		decl String:sourceName[64];
		GetClientName(client, sourceName, sizeof(sourceName));
		SendPM(sourceName, g_SteamId_cache[client], g_userIdLastViewed[client], arguments[start]);
		processOperationQueue();
		PrintToChat(client, "\x04[Signal]\x01 %T", "Message sent.", client);
		g_messagesSentInTheLastMin[client]++;
		return Plugin_Handled;
		
	} else if(StrEqual(command, "pmcreategroup", false)) {
	
		if(g_groupsCreatedInTheLastMin[client] >= 3) {
			PrintToChat(client, "\x04[Signal]\x01 %T", "Group creation limit reached", client);
			return Plugin_Handled;
		}
		
		if(start <= 3) {
			PrintToChat(client, "\x04[Signal]\x01 %T: pmcreategroup <%T>", "Usage", client, "Sample group name", client);
			return Plugin_Handled;
		}
		
		decl String:groupName[64];
		strcopy(groupName, sizeof(groupName), arguments[start]);
		CreateGroup(groupName, g_SteamId_cache[client], client);
		g_groupsCreatedInTheLastMin[client]++;
		return Plugin_Handled;
		
	} else if(StrEqual(command, "pmdeletegroup", false)) {
		showMenu_DelGroup(client);
		return Plugin_Handled;
	
	} else if(StrEqual(command, "pmaddfriend", false)) {
		
		if(start <= 3) {
			PrintToChat(client, "\x04[Signal]\x01 %T: pmaddfriend \"SteamID\"", "Usage", client);
			return Plugin_Handled;
		}
		
		decl String:friendId[32];
		GetCmdArg(1, friendId, sizeof(friendId));
		AddFriendDetectName(g_SteamId_cache[client], arguments[start], client);
		
		return Plugin_Handled;
	
	} else if(StrEqual(command, "pmhelp", false)) {
		showMenu_Help(client);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public OnConfigsExecuted() {	
	// Poll for new messages (don't worry, it's threaded!)
	if(g_pollTimer != INVALID_HANDLE) CloseHandle(g_pollTimer);
	new Float:seconds = 0.0 + GetConVarInt(g_cvar_pollinterval);
	if(seconds < 12.0) seconds = 12.0;
	g_pollTimer = CreateTimer(seconds, Timer_PollForNewMessages, _, TIMER_REPEAT);
	
	// Get DB connection
	refreshDatabaseConnection();
	
	// Make sure the version convar is correct (sometimes it's automatically added to the configs)
	new Handle:version = CreateConVar("signalpm_version", PLUGIN_VERSION, "Signal PM system version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	SetConVarString(version, PLUGIN_VERSION);
}

public OnClientPostAdminCheck(client) {

	if(IsFakeClient(client)) return;

	GetClientAuthString(client, g_SteamId_cache[client], sizeof(g_SteamId_cache[]));
	ResetClientData(client);
	
	decl String:name[64];
	GetClientName(client, name, sizeof(name));
	UpdatePlayerNameInDatabase(name, g_SteamId_cache[client]);
}

public OnClientDisconnect_Post(client) {
	strcopy(g_SteamId_cache[client], sizeof(g_SteamId_cache[]), "");
	ResetClientData(client);
}

ResetClientData(client) {
	RefreshSteamIDQueryList();
	g_messageLastViewed[client] = -1;
	strcopy(g_userIdLastViewed[client], sizeof(g_userIdLastViewed[]), "");
	strcopy(g_userNameLastViewed[client], sizeof(g_userNameLastViewed[]), "");
	g_messagesSentInTheLastMin[client] = 0;
}

// Poll for new messages

public Action:Timer_PollForNewMessages(Handle:timer) {

	if(GetClientCount() > 0 && db != INVALID_HANDLE && !g_lastPollUnsuccessful) {
	
		g_lastPollUnsuccessful = true;
	
		decl String:query[sizeof(g_SteamIdQueryList) + 256];
		Format(query, sizeof(query), "SELECT destId, COUNT(*) FROM `%s` WHERE unread = 1 AND deleted = 0 AND destId IN ('%s') GROUP BY destId", table_e, g_SteamIdQueryList);
		SQL_TQuery(db, PollForNewMessages_callback, query);
		
		UpdateOnlineStatusInDatabase();
		
		g_lastPollUnsuccessful = false;
	
	} else if(db == INVALID_HANDLE || g_lastPollUnsuccessful) {
		refreshDatabaseConnection();
		g_lastPollUnsuccessful = false;
	}
}

public PollForNewMessages_callback(Handle:owner, Handle:hQuery, const String:error[], any:data) {
	
	if(hQuery == INVALID_HANDLE) {
		ErrMsg("Database Query", error);
		refreshDatabaseConnection();
		return;
	}
	
	new unreadCount = 0, client = 0;
	decl String:destId[32];
	
	while(SQL_FetchRow(hQuery)) {
		SQL_FetchString(hQuery, 0, destId, sizeof(destId));
		unreadCount = SQL_FetchInt(hQuery, 1);
		client = getClientFromAuthId(destId);
		if(client > 0) {
			if(GetConVarInt(g_cvar_notifytype) == 1) {
				if(unreadCount == 1)
					PrintHintText(client, "\x04[Signal]\x01 %T", "One unread", client);
				else
					PrintHintText(client, "\x04[Signal]\x01 %T", "Multiple unread", client, unreadCount);
			} else {
				if(unreadCount == 1)
					PrintToChat(client, "\x04[Signal]\x01 %T", "One unread", client);
				else
					PrintToChat(client, "\x04[Signal]\x01 %T", "Multiple unread", client, unreadCount);
			}
		}
	}
}

// Surely there's a nicer way of doing this?
getClientFromAuthId(const String:authId[]) {
	
	for(new i = 1; i < MaxClients; i++)
		if(IsClientInGame(i) && StrEqual(authId[7], g_SteamId_cache[i][7], false))
			return i;
	
	return -1;
}

// Database

refreshDatabaseConnection() {
	
	if(g_lastDBattempt < GetTime() - 10) {
		decl String:database[64];
		GetConVarString(g_cvar_database, database, sizeof(database));
		SQL_TConnect(refreshDatabaseConnection_gotDB, database);
		
		g_lastDBattempt = GetTime();
	}
}

public refreshDatabaseConnection_gotDB(Handle:owner, Handle:new_db, const String:error[], any:data) {
	
	if (new_db == INVALID_HANDLE) {
		ErrMsg("Database Connection", error);
		PrintToChatAll("\x04[Signal]\x01 %T %T", "Check DB settings", LANG_SERVER, "Error in logs", LANG_SERVER);
	}
	
	else {
		if(db != INVALID_HANDLE) CloseHandle(db);
		db = new_db;
		PrintToServer("[Signal] %T", "Got DB conn", LANG_SERVER);
		
		// Detect SQLite/MySQL
		decl String:driverIdent[10];
		SQL_ReadDriver(db, driverIdent, sizeof(driverIdent));
		g_isSQLite = StrEqual(driverIdent, "sqlite", false);
		
		// Get the table name
		decl String:table[64];	
		GetConVarString(g_cvar_table, table, sizeof(table));
		SQL_EscapeString(db, table, table_e, sizeof(table_e));
		
		setupTable();
	}
}

// Query Building

RefreshSteamIDQueryList() {
	strcopy(g_SteamIdQueryList, sizeof(g_SteamIdQueryList), "");
	for (new client = 1; client <= MaxClients; client++)
		if(IsClientInGame(client) && !IsFakeClient(client))
			Format(g_SteamIdQueryList, sizeof(g_SteamIdQueryList), "%s','%s", g_SteamIdQueryList, g_SteamId_cache[client]);
}

// Interface :: Inbox

showMenu_Inbox(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	if(g_isSQLite)
		Format(query, sizeof(query), "SELECT id, unread, sourceName, (%d - time) as timeago FROM `%s` WHERE destId = '%s' AND deleted = 0 ORDER BY time DESC LIMIT 1024", GetTime(), table_e, g_SteamId_cache[client]);
	else
		Format(query, sizeof(query), "SELECT id, unread, sourceName, (UNIX_timestamp(CURRENT_TIMESTAMP) - UNIX_timestamp(time)) as timeago FROM `%s` WHERE destId = '%s' AND deleted = 0 ORDER BY time DESC LIMIT 1024", table_e, g_SteamId_cache[client]);
 
	SQL_TQuery(db, callback_showMenu_Inbox, query, GetClientUserId(client));
}

public callback_showMenu_Inbox(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "No messages to view", client);
		return;
	}
	
	new Handle:menu = CreateMenu(handleMenu_Inbox);
	
	decl String:translatedText[64];
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Inbox", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, true);
	
	decl String:sourceName[64];
	decl String:inbox_item[100];
	decl String:inbox_info[10];
	decl String:ur_text[32];
	decl String:ago_text[32];
	new unread, timeago, id;
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 2, sourceName, sizeof(sourceName));
		timeago = SQL_FetchInt(hQuery, 3);
		id = SQL_FetchInt(hQuery, 0);
		unread = SQL_FetchInt(hQuery, 1);
		
		if(unread) Format(ur_text, sizeof(ur_text), " | %T", "Unread", client);
		else Format(ur_text, sizeof(ur_text), "");
			
		if(timeago < 120) 			Format(ago_text, sizeof(ago_text), "%d %T", timeago, "SecondsShort", client);
		else if(timeago < 7200) 	Format(ago_text, sizeof(ago_text), "%d %T", timeago / 60, "MinutesShort", client);
		else if(timeago < 86400) 	Format(ago_text, sizeof(ago_text), "%d %T", timeago / 3600, "HoursShort", client);
		else 						Format(ago_text, sizeof(ago_text), "%d %T", timeago / 86400, "DaysShort", client);
		
		Format(inbox_item, sizeof(inbox_item), "[#%d%s] %s (%T)", id, ur_text, sourceName, "X ago", client, ago_text);
		Format(inbox_info, sizeof(inbox_info), "%d", id);
		
		AddMenuItem(menu, inbox_info, inbox_item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_Inbox(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	
	else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_Main(param1);
			
	} else if (action == MenuAction_Select) {
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new messageId = StringToInt(info);
		showMenu_Message(param1, messageId);
	}
}

// Interface :: Outbox

showMenu_Outbox(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	if(g_isSQLite)
		Format(query, sizeof(query), "SELECT id, destId, (%d - time) AS timeago, lastName FROM `%s` LEFT OUTER JOIN `%s_players` ON steamId = destId WHERE sourceId = '%s' ORDER BY time DESC LIMIT 1024", GetTime(), table_e, table_e, g_SteamId_cache[client]);
	else
		Format(query, sizeof(query), "SELECT id, destId, (UNIX_timestamp(CURRENT_TIMESTAMP) - UNIX_timestamp(time)) AS timeago, lastName FROM `%s` LEFT JOIN `%s_players` ON steamId = destId WHERE sourceId = '%s' ORDER BY time DESC LIMIT 1024", table_e, table_e, g_SteamId_cache[client]);
 
	SQL_TQuery(db, callback_showMenu_Outbox, query, GetClientUserId(client));
}

public callback_showMenu_Outbox(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "No sent messages to view", client);
		return;
	}
	
	new Handle:menu = CreateMenu(handleMenu_Outbox);
	
	decl String:translatedText[64];
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Outbox", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, true);
	
	decl String:destId[32], String:destName[64];
	decl String:inbox_item[100];
	decl String:inbox_info[10];
	decl String:ago_text[32];
	new timeago, id;
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 1, destId, sizeof(destId));
		SQL_FetchString(hQuery, 3, destName, sizeof(destName));
		timeago = SQL_FetchInt(hQuery, 2);
		id = SQL_FetchInt(hQuery, 0);
		
		if(!strlen(destName)) strcopy(destName, sizeof(destName), "Unnamed");
		
		if(timeago < 120) 		Format(ago_text, sizeof(ago_text), "%d %T", timeago, "SecondsShort", client);
		else if(timeago < 7200) 	Format(ago_text, sizeof(ago_text), "%d %T", timeago / 60, "MinutesShort", client);
		else if(timeago < 86400) 	Format(ago_text, sizeof(ago_text), "%d %T", timeago / 3600, "HoursShort", client);
		else 						Format(ago_text, sizeof(ago_text), "%d %T", timeago / 86400, "DaysShort", client);
		
		Format(inbox_item, sizeof(inbox_item), "[#%d] %s <%s> (%T)", id, destName, destId, "X ago", client, ago_text);
		Format(inbox_info, sizeof(inbox_info), "%d", id);
		
		AddMenuItem(menu, inbox_info, inbox_item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_Outbox(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	
	else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_Main(param1);
			
	} else if (action == MenuAction_Select) {
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		new messageId = StringToInt(info);
		showMenu_SentMessage(param1, messageId);
	}
}

// Interface :: Message view

showMenu_Message(client, messageId) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	if(g_isSQLite)
		Format(query, sizeof(query), "SELECT message, sourceId, sourceName, (%d - time) as timeago, id FROM `%s` WHERE id = %d ORDER BY time DESC LIMIT 1024", GetTime(), table_e, messageId);
	else
		Format(query, sizeof(query), "SELECT message, sourceId, sourceName, (UNIX_timestamp(CURRENT_TIMESTAMP) - UNIX_timestamp(time)) as timeago, id FROM `%s` WHERE id = %d ORDER BY time DESC LIMIT 1024", table_e, messageId);
	
	SQL_TQuery(db, callback_showMenu_Message, query, GetClientUserId(client));
}

public callback_showMenu_Message(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "Message doesn't exist", client);
		return;
	}
	
	new Handle:panel = CreatePanel();
	
	decl String:sourceName[64];
	decl String:sourceId[32];
	decl String:message[256];
	decl String:panelText[96];
	decl String:ago_text[20];
	new timeago, id;
	
	SQL_FetchRow(hQuery);
	
	SQL_FetchString(hQuery, 0, message, sizeof(message));
	SQL_FetchString(hQuery, 1, sourceId, sizeof(sourceId));
	SQL_FetchString(hQuery, 2, sourceName, sizeof(sourceName));
	timeago = SQL_FetchInt(hQuery, 3);
	id = SQL_FetchInt(hQuery, 4);
		
	if(timeago < 120) 		Format(ago_text, sizeof(ago_text), "%d %T", timeago, "SecondsShort", client);
	else if(timeago < 7200) 	Format(ago_text, sizeof(ago_text), "%d %T", timeago / 60, "MinutesShort", client);
	else if(timeago < 86400) 	Format(ago_text, sizeof(ago_text), "%d %T", timeago / 3600, "HoursShort", client);
	else 						Format(ago_text, sizeof(ago_text), "%d %T", timeago / 86400, "DaysShort", client);
	
	
	Format(panelText, sizeof(panelText), "Signal: %T", "Viewing message #X", client, id);	
	SetPanelTitle(panel, panelText);
	
	Format(panelText, sizeof(panelText), "%T: %T", "Received time", client, "X ago", client, ago_text);	
	DrawPanelText(panel, panelText);
	
	Format(panelText, sizeof(panelText), "%T: \"%s\" <%s>", "From", client, sourceName, sourceId);	
	DrawPanelItem(panel, panelText);
	
	DrawPanelText(panel, " ");
	
	// Split the message into lines
	new l = strlen(message);
	new offset = 0;
	
	for(new i = 0; i < l; i++) {
		if(i > 80 && message[i + offset] == ' ') {
			message[i + offset] = '\n';
			
			// Workaround for L4D2 panel issue :(
			if(i + 1 < l) {
				if(message[i + offset + 1] == '[') {
					message[i + offset + 1] = ' ';
				}
			}
			
			offset += i;
			l -= i;
			i = 0;
		}
	}
	
	DrawPanelText(panel, message);
	DrawPanelDivider(panel);	
	
	DrawPanelTranslatedText(panel, "Reply prompt", client);
	DrawPanelTranslatedItem(panel, "Delete message", client);
	DrawPanelTranslatedItem(panel, "Back to Inbox", client);
	DrawPanelBlankLine(panel);
	SetPanelCurrentKey(panel, 10);
	DrawPanelTranslatedItem(panel, "Close", client);
	
	SendPanelToClient(panel, client, handleMenu_Message, MENU_TIME_FOREVER);
	g_messageLastViewed[client] = id;
	strcopy(g_userIdLastViewed[client], sizeof(g_userIdLastViewed[]), sourceId);
	MessageMarkRead(id, client);
	
}

public handleMenu_Message(Handle:menu, MenuAction:action, param1, param2) {

	if (action == MenuAction_End) {
		CloseHandle(menu);
		showMenu_Inbox(param1);
	
	} else if (action == MenuAction_Cancel)
		showMenu_Inbox(param1);
	
	else if (action == MenuAction_Select) {

		if(param2 == 1) {
			showMenu_User(param1, g_userIdLastViewed[param1]);
		} else if(param2 == 2) {
			MessageDelete(g_messageLastViewed[param1], param1);
			showMenu_Inbox(param1);
		} else if(param2 == 3) {
			showMenu_Inbox(param1);
		}
	}
}

// Interface :: Sent Message view

showMenu_SentMessage(client, messageId) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	if(g_isSQLite)
		Format(query, sizeof(query), "SELECT message, destId, (%d - time) as timeago, id FROM `%s` WHERE id = %d ORDER BY time DESC LIMIT 1024", GetTime(), table_e, messageId);
	else
		Format(query, sizeof(query), "SELECT message, destId, (UNIX_timestamp(CURRENT_TIMESTAMP) - UNIX_timestamp(time)) as timeago, id FROM `%s` WHERE id = %d ORDER BY time DESC LIMIT 1024", table_e, messageId);
 
	SQL_TQuery(db, callback_showMenu_SentMessage, query, GetClientUserId(client));
}

public callback_showMenu_SentMessage(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "Message doesn't exist", client);
		return;
	}
	
	new Handle:panel = CreatePanel();
	
	decl String:destId[32];
	decl String:message[256];
	decl String:panelText[96];
	decl String:ago_text[20];
	new timeago, id;
	
	SQL_FetchRow(hQuery);
	
	SQL_FetchString(hQuery, 0, message, sizeof(message));
	SQL_FetchString(hQuery, 1, destId, sizeof(destId));
	timeago = SQL_FetchInt(hQuery, 2);
	id = SQL_FetchInt(hQuery, 3);
		
	if(timeago < 120) 		Format(ago_text, sizeof(ago_text), "%d %T", timeago, "SecondsShort", client);
	else if(timeago < 7200) 	Format(ago_text, sizeof(ago_text), "%d %T", timeago / 60, "MinutesShort", client);
	else if(timeago < 86400) 	Format(ago_text, sizeof(ago_text), "%d %T", timeago / 3600, "HoursShort", client);
	else 						Format(ago_text, sizeof(ago_text), "%d %T", timeago / 86400, "DaysShort", client);
	
	
	Format(panelText, sizeof(panelText), "Signal: %T", "Viewing message #X", client, id);	
	SetPanelTitle(panel, panelText);
	
	Format(panelText, sizeof(panelText), "%T: %T", "Sent time", client, "X ago", client, ago_text);	
	DrawPanelText(panel, panelText);
	
	Format(panelText, sizeof(panelText), "%T: <%s>", "To", client, destId);	
	DrawPanelItem(panel, panelText);
	
	DrawPanelText(panel, " ");
	
	// Split the message into lines
	new l = strlen(message);
	new offset = 0;
	
	for(new i = 0; i < l; i++) {
		if(i > 80 && message[i + offset] == ' ') {
			message[i + offset] = '\n';
			
			// Workaround for L4D2 panel issue :(
			if(i + 1 < l) {
				if(message[i + offset + 1] == '[') {
					message[i + offset + 1] = ' ';
				}
			}
			
			offset += i;
			l -= i;
			i = 0;
		}
	}
	
	DrawPanelText(panel, message);
	DrawPanelDivider(panel);	
	
	SetPanelCurrentKey(panel, 9);
	DrawPanelTranslatedItem(panel, "Back to outbox", client);
	DrawPanelTranslatedItem(panel, "Close", client);
	
	SendPanelToClient(panel, client, handleMenu_SentMessage, MENU_TIME_FOREVER);
	g_messageLastViewed[client] = id;
	strcopy(g_userIdLastViewed[client], sizeof(g_userIdLastViewed[]), destId);	
}

public handleMenu_SentMessage(Handle:menu, MenuAction:action, param1, param2) {

	if (action == MenuAction_End) {
		CloseHandle(menu);
		showMenu_Outbox(param1);
	
	} else if (action == MenuAction_Cancel)
		showMenu_Outbox(param1);
	
	else if (action == MenuAction_Select) {

		if(param2 == 1) {
			showMenu_User(param1, g_userIdLastViewed[param1]);
		} else if(param2 == 9) {
			showMenu_Outbox(param1);
		}
	}
}

// Interface :: Friends

showMenu_Friends(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	if(g_isSQLite)
		Format(query, sizeof(query), "SELECT friendName, friendId, lastName, (%d - lastSeen < 30) as isonline FROM `%s_friends` LEFT OUTER JOIN `%s_players` ON friendId = steamId WHERE userId = '%s' OR userId = 'all' ORDER BY (userId = 'all') DESC, isonline DESC, friendName ASC, lastName ASC LIMIT 1024", GetTime(), table_e, table_e, g_SteamId_cache[client]);
	else
		Format(query, sizeof(query), "SELECT friendName, friendId, lastName, (UNIX_timestamp(CURRENT_TIMESTAMP) - UNIX_timestamp(lastSeen) < 30) as isonline FROM `%s_friends` LEFT JOIN `%s_players` ON friendId = steamId WHERE userId = '%s' OR userId = 'all' ORDER BY (userId = 'all') DESC, isonline DESC, friendName ASC, lastName ASC LIMIT 1024", table_e, table_e, g_SteamId_cache[client]);
 
	SQL_TQuery(db, callback_showMenu_Friends, query, GetClientUserId(client));
}

public callback_showMenu_Friends(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	decl String:translatedText[64];
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	new Handle:menu = CreateMenu(handleMenu_Friends);
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Friends", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, true);
	
	Format(translatedText, sizeof(translatedText), ">> %T", "Add friend", client);
	AddMenuItem(menu, "add", translatedText);
	
	decl String:friendName[32], String:friendId[32], String:lastName[32];
	new bool:isOnline;
	decl String:item[128], String:item_info[32], String:onlineText[16];
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 0, friendName, sizeof(friendName));
		SQL_FetchString(hQuery, 1, friendId, sizeof(friendId));
		SQL_FetchString(hQuery, 2, lastName, sizeof(lastName));
		isOnline = bool:SQL_FetchInt(hQuery, 3);
		
		if(isOnline) Format(onlineText, sizeof(onlineText), "[%T] ", "Online", client);
		else strcopy(onlineText, sizeof(onlineText), "");
		
		if(!strlen(friendName)) {
			if(strlen(lastName)) strcopy(friendName, sizeof(friendName), lastName);
			else strcopy(friendName, sizeof(friendName), "Unnamed");
		}
		
		Format(item, sizeof(item), "%s%s <%s>", onlineText, friendName, friendId);	
		Format(item_info, sizeof(item_info), "%s", friendId);
		AddMenuItem(menu, item_info, item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_Friends(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	
	else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_Main(param1);
	
	} else if (action == MenuAction_Select) {
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if(StrEqual(info, "add"))
			showMenu_AddFriend(param1);
		else {
			showMenu_User(param1, info);
		}
	}
}

// Interface :: Blocklist

showMenu_Blocklist(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	Format(query, sizeof(query), "SELECT blockedName, blockedId FROM `%s_blocks` WHERE userId = '%s' ORDER BY blockedName ASC LIMIT 1024", table_e, g_SteamId_cache[client]);
 
	SQL_TQuery(db, callback_showMenu_Blocklist, query, GetClientUserId(client));
}

public callback_showMenu_Blocklist(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	decl String:translatedText[64];
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "No blocks to view", client);
		return;
	}
	
	new Handle:menu = CreateMenu(handleMenu_Blocklist);
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Blocklist", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, true);
	
	decl String:blockedName[32]; // Truncated (on purpose)
	decl String:blockedId[32];
	decl String:item[128], String:item_info[32];
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 0, blockedName, sizeof(blockedName));
		SQL_FetchString(hQuery, 1, blockedId, sizeof(blockedId));
		
		Format(item, sizeof(item), "%s <%s>", blockedName, blockedId);	
		Format(item_info, sizeof(item_info), "%s", blockedId);
		AddMenuItem(menu, item_info, item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_Blocklist(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	
	else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_Main(param1);
	
	} else if (action == MenuAction_Select) {
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		showMenu_User(param1, info);
	}
}


// Interface :: Groups

showMenu_Groups(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	Format(query, sizeof(query), "SELECT groupName, groupId FROM `%s_groups` WHERE ownerId = '%s' OR ownerId = 'all' ORDER BY (ownerId = 'all') DESC, groupName ASC LIMIT 1024", table_e, g_SteamId_cache[client]);
 
	SQL_TQuery(db, callback_showMenu_Groups, query, GetClientUserId(client));
}

public callback_showMenu_Groups(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	decl String:translatedText[64];
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) < 1) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "Create group hint", client);
	}
	
	new Handle:menu = CreateMenu(handleMenu_Groups);
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Groups", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, true);

	decl String:groupName[32]; // Truncated (purposely!)
	new groupId;
	
	decl String:item[128], String:item_info[32];
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 0, groupName, sizeof(groupName));
		groupId = SQL_FetchInt(hQuery, 1);
		
		Format(item, sizeof(item), "%s <#%d>", groupName, groupId);	
		Format(item_info, sizeof(item_info), "%d", groupId);
		AddMenuItem(menu, item_info, item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_Groups(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	
	else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_Main(param1);
	
	} else if (action == MenuAction_Select) {
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		showMenu_Group(param1, StringToInt(info));
	}
}

// Interface :: Group

showMenu_Group(client, groupId) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	Format(query, sizeof(query), "SELECT memberName, memberId FROM `%s_groupmembers` WHERE groupId = %d ORDER BY memberName ASC LIMIT 1024", table_e, groupId);
 
	SQL_TQuery(db, callback_showMenu_Group, query, GetClientUserId(client));
}

public callback_showMenu_Group(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	decl String:translatedText[64];
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) < 1) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "No users in group.", client);
	}
	
	new Handle:menu = CreateMenu(handleMenu_Group);
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Group Members", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, true);
	
	decl String:memberName[32]; // Truncated (purposely!)
	decl String:memberId[32];
	decl String:item[128], String:item_info[32];
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 0, memberName, sizeof(memberName));
		SQL_FetchString(hQuery, 1, memberId, sizeof(memberId));
		
		Format(item, sizeof(item), "%s <%s>", memberName, memberId);	
		Format(item_info, sizeof(item_info), "%s", memberId);
		AddMenuItem(menu, item_info, item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_Group(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	
	else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_Main(param1);
	
	} else if (action == MenuAction_Select) {
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		showMenu_User(param1, info);
	}
}

// Interface :: Remove last user from group

showMenu_DelLastUserFromGroup(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1024];
	Format(query, sizeof(query), "SELECT groupName, `%s_groups`.groupId FROM `%s_groups`, `%s_groupmembers` WHERE `%s_groups`.groupId = `%s_groupmembers`.groupId AND ownerId = '%s' AND memberId = '%s' ORDER BY groupName ASC LIMIT 1024", table_e, table_e, table_e, table_e, table_e, g_SteamId_cache[client], g_userIdLastViewed[client]);
 
	SQL_TQuery(db, callback_sMenu_DelLastFromGroup, query, GetClientUserId(client));
}

public callback_sMenu_DelLastFromGroup(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	decl String:translatedText[64];
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "User not part of your groups.", client);
		return;
	}
	
	new Handle:menu = CreateMenu(handleMenu_DelLastUserFromGroup);
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Select group to remove from", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, true);
	
	decl String:groupName[32]; // Truncated (purposely!)
	new groupId;
	
	decl String:item[128], String:item_info[32];
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 0, groupName, sizeof(groupName));
		groupId = SQL_FetchInt(hQuery, 1);
		
		Format(item, sizeof(item), "%s <#%d>", groupName, groupId);	
		Format(item_info, sizeof(item_info), "%d", groupId);
		AddMenuItem(menu, item_info, item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_DelLastUserFromGroup(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	
	else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_User(param1, g_userIdLastViewed[param1]);
	
	} else if (action == MenuAction_Select) {
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		RemoveUserFromGroup(g_userIdLastViewed[param1], StringToInt(info), param1);
	}
}

// Interface :: Select recipient

showMenu_Recipient(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[512];
	Format(query, sizeof(query), "SELECT COUNT(*) FROM `%s_groups` WHERE ownerId = '%s' OR ownerId = 'all'", table_e, g_SteamId_cache[client]);
	
	SQL_TQuery(db, callback_showMenu_Recipient_One, query, GetClientUserId(client));
}

public callback_showMenu_Recipient_One(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_FetchRow(hQuery))
		g_userHasGroups[client] = bool:SQL_FetchInt(hQuery, 0);
	else
		g_userHasGroups[client] = false;
	
	decl String:query[1000];
	if(g_isSQLite)
		Format(query, sizeof(query), "SELECT friendName, friendId, lastName, (%d - lastSeen < 30) as isonline FROM `%s_friends` LEFT OUTER JOIN `%s_players` ON friendId = steamId WHERE userId = '%s' OR userId = 'all' ORDER BY (userId = 'all') DESC, isonline DESC, friendName ASC, lastName ASC LIMIT 1024", GetTime(), table_e, table_e, g_SteamId_cache[client]);
	else
		Format(query, sizeof(query), "SELECT friendName, friendId, lastName, (UNIX_timestamp(CURRENT_TIMESTAMP) - UNIX_timestamp(lastSeen) < 30) as isonline FROM `%s_friends` LEFT JOIN `%s_players` ON friendId = steamId WHERE userId = '%s' OR userId = 'all' ORDER BY (userId = 'all') DESC, isonline DESC, friendName ASC, lastName ASC LIMIT 1024", table_e, table_e, g_SteamId_cache[client]);
		

	SQL_TQuery(db, callback_showMenu_Recipient_Two, query, GetClientUserId(client));
}

public callback_showMenu_Recipient_Two(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	new bool:wehavegroups = g_userHasGroups[client];
	decl String:translatedText[64];
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
		
	if(SQL_GetRowCount(hQuery) == 0 && !wehavegroups) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "Need friends first", client);
		return;
	}
	
	new Handle:menu = CreateMenu(handleMenu_Recipient);
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Choose a recipient", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, false);
	
	if(wehavegroups)
		AddMenuTranslatedItem(menu, "group", "Choose group recipient", client);
	
	decl String:friendName[32], String:friendId[32], String:lastName[32], String:onlineText[16];
	decl String:item[128], String:item_info[32];
	new bool:isonline;
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 0, friendName, sizeof(friendName));
		SQL_FetchString(hQuery, 1, friendId, sizeof(friendId));
		SQL_FetchString(hQuery, 2, lastName, sizeof(lastName));
		isonline = bool:SQL_FetchInt(hQuery, 3);
		
		if(isonline) Format(onlineText, sizeof(onlineText), "[%T] ", "Online", client);
		else strcopy(onlineText, sizeof(onlineText), "");
		
		if(!strlen(friendName)) {
			if(strlen(lastName)) strcopy(friendName, sizeof(friendName), lastName);
			else strcopy(friendName, sizeof(friendName), "Unnamed");
		}
		
		Format(item, sizeof(item), "%s%s <%s>", onlineText, friendName, friendId);	
		Format(item_info, sizeof(item_info), "%s", friendId);
		AddMenuItem(menu, item_info, item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_Recipient(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		if(StrEqual(info, "group")) {
			showMenu_RecipientGroup(param1);
			return;
		}
		
		decl String:sourceName[64], String:sourceId[32];
		GetClientName(param1, sourceName, sizeof(sourceName));
		GetClientAuthString(param1, sourceId, sizeof(sourceId));
		
		SendPM(sourceName, sourceId, info, g_messageToSend[param1]);
		PrintToChat(param1, "\x04[Signal]\x01 %T", "Message sent.", param1);
		processOperationQueue();
		g_messagesSentInTheLastMin[param1]++;
	}
}

// Interface :: Select recipient group

showMenu_RecipientGroup(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	Format(query, sizeof(query), "SELECT groupName, groupId FROM `%s_groups` WHERE ownerId = '%s' OR ownerId = 'all' ORDER BY (ownerId = 'all') DESC, groupId ASC LIMIT 1024", table_e, g_SteamId_cache[client]);

	SQL_TQuery(db, callback_showMenu_RecipGroup, query, GetClientUserId(client));
}

public callback_showMenu_RecipGroup(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	decl String:translatedText[64];
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "Need groups first", client);
		return;
	}
	
	new Handle:menu = CreateMenu(handleMenu_RecipientGroup);
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Choose a recipient", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, false);
	
	decl String:groupName[32]; // Truncated (on purpose!)
	new groupId;
	decl String:item[128], String:item_info[32];
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 0, groupName, sizeof(groupName));
		groupId = SQL_FetchInt(hQuery, 1);
		
		Format(item, sizeof(item), "%s <%d>", groupName, groupId);	
		Format(item_info, sizeof(item_info), "%d", groupId);
		AddMenuItem(menu, item_info, item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_RecipientGroup(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Select)
	{
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		
		decl String:query[1000];
		Format(query, sizeof(query), "SELECT memberId FROM `%s_groupmembers` WHERE groupId = %d", table_e, StringToInt(info));

		SQL_TQuery(db, callback_hMenu_RecipGroup, query, GetClientUserId(param1));
	}
}

public callback_hMenu_RecipGroup(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	
	decl String:destId[32], String:sourceId[32], String:sourceName[32];
	GetClientName(client, sourceName, sizeof(sourceName));
	GetClientAuthString(client, sourceId, sizeof(sourceId));
	
	if(SQL_GetRowCount(hQuery) < 1) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "No users in group.", client);
		return;
	}
	
	while (SQL_FetchRow(hQuery)) {
		SQL_FetchString(hQuery, 0, destId, sizeof(destId));		
		SendPM(sourceName, sourceId, destId, g_messageToSend[client]);
		g_messagesSentInTheLastMin[client]++;
	}
	
	processOperationQueue();	
	PrintToChat(client, "\x04[Signal]\x01 %T", "Message sent.", client);
}

// Interface :: Add Friend

showMenu_AddFriend(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	new Handle:menu = CreateMenu(handleMenu_AddFriend);
	
	decl String:translatedText[64];
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Add Friend Title", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, true);
	AddTargetsToMenu2(menu, 0, COMMAND_FILTER_NO_BOTS|COMMAND_FILTER_CONNECTED);	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_AddFriend(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	
	else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_Main(param1);
	
	} else if (action == MenuAction_Select) {
		
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		new target = GetClientOfUserId(StringToInt(info));
		
		if(target <= 0)
			PrintToChat(param1, "\x04[Signal]\x01 %T", "User doesn't exist", param1);
			
		else {
			decl String:friendName[64];
			GetClientName(target, friendName, sizeof(friendName));
			AddFriend(g_SteamId_cache[param1], g_SteamId_cache[target], friendName, param1);
			showMenu_Friends(param1);
		}
	}
}

// Interface :: User Menu

showMenu_User(client, const String:targetId[]) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:targetId_e[65];
	decl String:userId_e[65];
	SQL_EscapeString(db, targetId, targetId_e, sizeof(targetId_e));
	SQL_EscapeString(db, g_SteamId_cache[client], userId_e, sizeof(userId_e));
	
	decl String:queryPartOne[4096];
	Format(queryPartOne, sizeof(queryPartOne), "SELECT \
		(SELECT sourceName FROM `%s` WHERE destId = '%s' AND sourceId = '%s' ORDER BY time DESC LIMIT 1) AS lastname, \
		(SELECT friendName FROM `%s_friends` WHERE (userId = '%s' OR userId = 'all') AND friendId = '%s' LIMIT 1) as friendname, \
		(SELECT blockedName FROM `%s_blocks` WHERE userId = '%s' AND blockedId = '%s' LIMIT 1) as blockedname, \
		(SELECT memberName FROM `%s_groupmembers`, `%s_groups` WHERE `%s_groupmembers`.groupId = `%s_groups`.groupId AND ownerId = '%s' AND memberId = '%s' ORDER BY `%s_groups`.groupId DESC LIMIT 1) as membername, \
		(SELECT lastName FROM `%s_players` WHERE steamId = '%s'), \
		'%s' AS targetid, ",
		table_e, userId_e, targetId_e,
		table_e, userId_e, targetId_e,
		table_e, userId_e, targetId_e,
		table_e, table_e, table_e, table_e, userId_e, targetId_e, table_e,
		table_e, targetId_e,
		targetId_e);
		
	decl String:queryPartTwo[2048];
	
	if(g_isSQLite)
		Format(queryPartTwo, sizeof(queryPartTwo), " \
		(SELECT COUNT(*) FROM `%s_blocks` WHERE userId = '%s' AND blockedId = '%s') AS isblocked, \
		(SELECT COUNT(*) FROM `%s_friends` WHERE userId = '%s' AND friendId = '%s') AS isfriend, \
		(SELECT COUNT(*) FROM `%s_friends` WHERE userId = 'all' AND friendId = '%s') AS isautoadd, \
		(SELECT COUNT(*) FROM `%s_groups` WHERE ownerId = '%s') AS wehavegroups, \
		(SELECT COUNT(*) FROM `%s_groupmembers`, `%s_groups` WHERE `%s_groupmembers`.groupId = `%s_groups`.groupId AND ownerId = '%s' AND memberId = '%s') AS isingroup, \
		(SELECT (%d - lastSeen < 30) AS isonline FROM `%s_players` WHERE steamId = '%s') AS isonline", 
		table_e, userId_e, targetId_e,
		table_e, userId_e, targetId_e,
		table_e, targetId_e,
		table_e, userId_e,
		table_e, table_e, table_e, table_e, userId_e, targetId_e,
		GetTime(), table_e, targetId_e);
	else
		Format(queryPartTwo, sizeof(queryPartTwo), " \
		(SELECT COUNT(*) FROM `%s_blocks` WHERE userId = '%s' AND blockedId = '%s') AS isblocked, \
		(SELECT COUNT(*) FROM `%s_friends` WHERE userId = '%s' AND friendId = '%s') AS isfriend, \
		(SELECT COUNT(*) FROM `%s_friends` WHERE userId = 'all' AND friendId = '%s') AS isautoadd, \
		(SELECT COUNT(*) FROM `%s_groups` WHERE ownerId = '%s') AS wehavegroups, \
		(SELECT COUNT(*) FROM `%s_groupmembers`, `%s_groups` WHERE `%s_groupmembers`.groupId = `%s_groups`.groupId AND ownerId = '%s' AND memberId = '%s') AS isingroup, \
		(SELECT (UNIX_timestamp(CURRENT_TIMESTAMP) - UNIX_timestamp(lastSeen) < 30) AS isonline FROM `%s_players` WHERE steamId = '%s') AS isonline", 
		table_e, userId_e, targetId_e,
		table_e, userId_e, targetId_e,
		table_e, targetId_e,
		table_e, userId_e,
		table_e, table_e, table_e, table_e, userId_e, targetId_e,
		table_e, targetId_e);
		
	StrCat(queryPartOne, sizeof(queryPartOne), queryPartTwo);
 
	SQL_TQuery(db, callback_showMenu_User, queryPartOne, GetClientUserId(client));
}

public callback_showMenu_User(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	decl String:translatedText[64];
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "User doesn't exist in DB", client);
		return;
	}
	
	new Handle:panel = CreatePanel();
	decl String:panelText[128];
	
	decl String:targetId[32], String:targetLastRecName[64], String:targetFriendName[64],
		String:targetBlockedName[64], String:targetMemberName[64], String:targetLastName[64];
	new bool:isblocked, bool:isfriend, bool:isautoadd, bool:wehavegroups, bool:isingroup, bool:isonline;
	
	SQL_FetchRow(hQuery);
	
	SQL_FetchString(hQuery, 0, targetLastRecName, sizeof(targetLastRecName));
	SQL_FetchString(hQuery, 1, targetFriendName, sizeof(targetFriendName));
	SQL_FetchString(hQuery, 2, targetBlockedName, sizeof(targetBlockedName));
	SQL_FetchString(hQuery, 3, targetMemberName, sizeof(targetMemberName));
	SQL_FetchString(hQuery, 4, targetLastName, sizeof(targetLastName));
	SQL_FetchString(hQuery, 5, targetId, sizeof(targetId));
	isblocked = bool:SQL_FetchInt(hQuery, 6);
	isfriend = bool:SQL_FetchInt(hQuery, 7);
	isautoadd = bool:SQL_FetchInt(hQuery, 8);
	wehavegroups = bool:SQL_FetchInt(hQuery, 9);
	isingroup = bool:SQL_FetchInt(hQuery, 10);
	isonline = bool:SQL_FetchInt(hQuery, 11);
		
	decl String:actualName[64];
	if((isfriend || isautoadd) && strlen(targetFriendName))
		strcopy(actualName, sizeof(actualName), targetFriendName);
	else if(isblocked  && strlen(targetBlockedName))
		strcopy(actualName, sizeof(actualName), targetBlockedName);
	else if(isingroup && strlen(targetMemberName))
		strcopy(actualName, sizeof(actualName), targetMemberName);
	else if(strlen(targetLastRecName))
		strcopy(actualName, sizeof(actualName), targetLastRecName);
	else if(strlen(targetLastName))
		strcopy(actualName, sizeof(actualName), targetLastName);
	else if(strlen(g_userNameLastViewed[client]))
		strcopy(actualName, sizeof(actualName), g_userNameLastViewed[client]);
	else
		strcopy(actualName, sizeof(actualName), "Unnamed");
	
	Format(translatedText, sizeof(translatedText), "Signal: %T", "User Menu", client);
	SetPanelTitle(panel, translatedText);
	
	Format(panelText, sizeof(panelText), "%T: \"%s\"", "Name", client, actualName);
	DrawPanelText(panel, panelText);
	
	Format(panelText, sizeof(panelText), "SteamID: <%s>", targetId);	
	DrawPanelText(panel, panelText);
	
	if(isblocked) {
		Format(translatedText, sizeof(translatedText), "(%T)", "Blocked", client);
		DrawPanelText(panel, translatedText);
	}
	
	if(isautoadd) {
		Format(translatedText, sizeof(translatedText), "(%T)", "Autoadd", client);
		DrawPanelText(panel, translatedText);
	}
	
	if(isfriend && isonline) {
		Format(translatedText, sizeof(translatedText), "(%T | %T)", "Friend", client, "Online", client);
		DrawPanelText(panel, translatedText);
	} else if(isfriend && !isonline) {
		Format(translatedText, sizeof(translatedText), "(%T)", "Friend", client);
		DrawPanelText(panel, translatedText);
	} else if(!isfriend && isonline) {
		Format(translatedText, sizeof(translatedText), "(%T)", "Online", client);
		DrawPanelText(panel, translatedText);
	}
	
	DrawPanelBlankLine(panel);
	
	DrawPanelTranslatedItem(panel, "Block user", client, (isblocked || isautoadd));
	DrawPanelTranslatedItem(panel, "Unblock user", client, (!isblocked || isautoadd));	
	DrawPanelBlankLine(panel);
	DrawPanelTranslatedItem(panel, "Add friend", client, (isfriend || isautoadd));
	DrawPanelTranslatedItem(panel, "Remove friend", client, (!isfriend || isautoadd)); 
	DrawPanelBlankLine(panel);
	DrawPanelTranslatedItem(panel, "Add to group", client, !wehavegroups);
	DrawPanelTranslatedItem(panel, "Remove from group", client, !isingroup);
	DrawPanelBlankLine(panel);
	DrawPanelTranslatedItem(panel, "Delete all", client);
	DrawPanelBlankLine(panel);
	SetPanelCurrentKey(panel, 9);
	DrawPanelTranslatedItem(panel, "Back to Main Menu", client);
	DrawPanelTranslatedItem(panel, "Close", client);
	
	strcopy(g_userIdLastViewed[client], sizeof(g_userIdLastViewed[]), targetId);
	strcopy(g_userNameLastViewed[client], sizeof(g_userNameLastViewed[]), actualName);
	SendPanelToClient(panel, client, handleMenu_User, MENU_TIME_FOREVER);
}

public handleMenu_User(Handle:menu, MenuAction:action, param1, param2) {

	if (action == MenuAction_End) {
		CloseHandle(menu);
		showMenu_Main(param1);
	
	} else if (action == MenuAction_Cancel)
		showMenu_Main(param1);
	
	else if (action == MenuAction_Select) {

		decl String:userId[32];
		GetClientAuthString(param1, userId, sizeof(userId));
	
		switch(param2) {
			case 1: {
				BlockUser(userId, g_userIdLastViewed[param1], g_userNameLastViewed[param1], param1);
				showMenu_User(param1, g_userIdLastViewed[param1]);
			}
			case 2: {
				UnblockUser(userId, g_userIdLastViewed[param1], param1);
				showMenu_User(param1, g_userIdLastViewed[param1]);
			}
			case 3: {
				AddFriend(userId, g_userIdLastViewed[param1], g_userNameLastViewed[param1], param1);
				showMenu_User(param1, g_userIdLastViewed[param1]);
			}
			case 4: {
				RemoveFriend(userId, g_userIdLastViewed[param1], param1);
				showMenu_User(param1, g_userIdLastViewed[param1]);
			}
			case 5: {
				showMenu_AddLastUserToGroup(param1);
			}
			case 6: {
				showMenu_DelLastUserFromGroup(param1);
			}
			case 7: {
				MessageDeleteAllFromUser(g_userIdLastViewed[param1], userId, param1);
				showMenu_Inbox(param1);
			}
			case 9: {
				showMenu_Main(param1);
			}
		}
	}
}

// Interface :: Add last viewed user to group

showMenu_AddLastUserToGroup(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	Format(query, sizeof(query), "SELECT groupName, groupId FROM `%s_groups` WHERE ownerId = '%s' ORDER BY groupId ASC LIMIT 1024", table_e, g_SteamId_cache[client]);

	SQL_TQuery(db, callback_sMenu_AddLastToGroup, query, GetClientUserId(client));
}

public callback_sMenu_AddLastToGroup(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	decl String:translatedText[64];
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "Need groups first", client);
		return;
	}
	
	new Handle:menu = CreateMenu(handleMenu_AddLastUserToGroup);
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Choose a group", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, false);
	
	new groupId;
	decl String:item[128], String:item_info[32], String:groupName[32];
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 0, groupName, sizeof(groupName));
		groupId = SQL_FetchInt(hQuery, 1);
		
		Format(item, sizeof(item), "%s <%d>", groupName, groupId);	
		Format(item_info, sizeof(item_info), "%d", groupId);
		AddMenuItem(menu, item_info, item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_AddLastUserToGroup(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	
	else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_Main(param1);
	
	} else if (action == MenuAction_Select) {
		
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		new groupId = StringToInt(info);
		
		AddUserToGroup(g_userIdLastViewed[param1], g_userNameLastViewed[param1], groupId, param1);
		showMenu_Group(param1, groupId);
	}
}

// Interface :: Delete group

showMenu_DelGroup(client) {

	if(!CheckDBBeforeAction(client)) return;
	if(!IsClientConnected(client)) return;
	
	decl String:query[1000];
	Format(query, sizeof(query), "SELECT groupName, groupId FROM `%s_groups` WHERE ownerId = '%s' ORDER BY groupId ASC LIMIT 1024", table_e, g_SteamId_cache[client]);

	SQL_TQuery(db, callback_showMenu_DelGroup, query, GetClientUserId(client));
}

public callback_showMenu_DelGroup(Handle:owner, Handle:hQuery, const String:error[], any:userId) {

	new client = GetClientOfUserId(userId);
	decl String:translatedText[64];
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		PrintToChat(client, "\x04[Signal]\x01 %T", "Need groups first", client);
		return;
	}
	
	new Handle:menu = CreateMenu(handleMenu_DelGroup);
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Choose a group", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, false);
	
	decl String:groupName[32]; // Truncated (on purpose!)
	new groupId;
	decl String:item[128], String:item_info[32];
	
	while (SQL_FetchRow(hQuery)) {
		
		SQL_FetchString(hQuery, 0, groupName, sizeof(groupName));
		groupId = SQL_FetchInt(hQuery, 1);
		
		Format(item, sizeof(item), "%s <%d>", groupName, groupId);	
		Format(item_info, sizeof(item_info), "%d", groupId);
		AddMenuItem(menu, item_info, item);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_DelGroup(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	
	else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_Main(param1);
	
	} else if (action == MenuAction_Select) {
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
		new groupId = StringToInt(info);
		DeleteGroup(groupId, param1);
		showMenu_Groups(param1);
	}
}

// Interface :: Main Menu

showMenu_Main(client) {

	if(db == INVALID_HANDLE) {
		ErrMsg("Database Connection", "No connection is present");
		refreshDatabaseConnection();
	}
	
	if(!IsClientConnected(client)) return;
	
	new Handle:menu = CreateMenu(handleMenu_Main);
	SetMenuTitle(menu, "Signal PM System");
	
	SetMenuExitBackButton(menu, false);
	
	AddMenuTranslatedItem(menu, "inbox", 		"Inbox", client);
	AddMenuTranslatedItem(menu, "outbox", 	"Outbox", client);
	AddMenuTranslatedItem(menu, "friends", 	"Friends", client);
	AddMenuTranslatedItem(menu, "blocklist", 	"Blocklist", client);
	AddMenuTranslatedItem(menu, "groups", 	"Groups", client);
	AddMenuTranslatedItem(menu, "help", 		"Help", client);
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_Main(Handle:menu, MenuAction:action, param1, param2) {
	if (action == MenuAction_End) CloseHandle(menu);
	else if (action == MenuAction_Select) {
		decl String:info[64];
		GetMenuItem(menu, param2, info, sizeof(info));
	
		if(StrEqual(info, "inbox"))			showMenu_Inbox(param1);
		else if(StrEqual(info, "outbox"))	showMenu_Outbox(param1);
		else if(StrEqual(info, "friends")) 	showMenu_Friends(param1);
		else if(StrEqual(info, "blocklist")) showMenu_Blocklist(param1);
		else if(StrEqual(info, "groups")) 	showMenu_Groups(param1);
		else if(StrEqual(info, "help")) 		showMenu_Help(param1);
	}
}

// Interface :: Help

showMenu_Help(client) {
	
	new Handle:menu = CreateMenu(handleMenu_Help);
	decl String:translatedText[32];
	Format(translatedText, sizeof(translatedText), "Signal: %T", "Help", client);
	SetMenuTitle(menu, translatedText);
	
	SetMenuExitBackButton(menu, true);
	
	decl String:helpTitleKey[32], String:helpTitle[64];
	for(new i = 1; i <= 12; i++) {
		Format(helpTitleKey, sizeof(helpTitleKey), "Help%d", i);
		Format(helpTitle, sizeof(helpTitle), "%T", helpTitleKey, client);
		AddMenuItem(menu, helpTitleKey, helpTitle);
	}
	
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public handleMenu_Help(Handle:menu, MenuAction:action, param1, param2) {
	
	if (action == MenuAction_End) {
		CloseHandle(menu);
	
	} else if (action == MenuAction_Cancel) {
		if(param2 == MenuCancel_ExitBack)
			showMenu_Main(param1);
			
	} else if (action == MenuAction_Select) {
	
		decl String:helpTitleKey[32], String:helpTextKey[32];
		GetMenuItem(menu, param2, helpTitleKey, sizeof(helpTitleKey));
		Format(helpTextKey, sizeof(helpTextKey), "%sText", helpTitleKey);
		
		decl String:helpTitle[64], String:helpText[256];
		Format(helpTitle, sizeof(helpTitle), "%T", helpTitleKey, param1);
		Format(helpText, sizeof(helpText), "%T", helpTextKey, param1);
		
		SendHelpMessage(param1, helpTitle, helpText);
	}
}

SendHelpMessage(client, const String:title[], const String:inputmessage[], bool:trim=true, bool:fromHelpMenu=true) {
	
	decl String:message[256];
	Format(message, sizeof(message), "%s", inputmessage);
	
	new Handle:panel = CreatePanel();
	
	SetPanelTitle(panel, title);
	DrawPanelBlankLine(panel);
	
	new l = strlen(message);
	new offset = 0;
	
	// Split into lines
	if(trim) {
		for(new i = 0; i < l; i++) {
			if(i > 45 && message[i + offset] == ' ') {
				message[i + offset] = '\n';
				
				// Workaround for L4D2 panel issue :(
				if(i + 1 < l) {
					if(message[i + offset + 1] == '[') {
						message[i + offset + 1] = ' ';
					}
				}
				
				offset += i;
				l -= i;
				i = 0;
			}
		}
	}

	DrawPanelText(panel, message);
	DrawPanelText(panel, " ");
	SetPanelCurrentKey(panel, 10);
	if(fromHelpMenu) DrawPanelTranslatedItem(panel, "Back to help", client);
	else DrawPanelTranslatedItem(panel, "Go to help menu", client);
	
	SendPanelToClient(panel, client, handleMenu_HelpPanel, MENU_TIME_FOREVER);
	
	CloseHandle(panel);
}

public handleMenu_HelpPanel(Handle:menu, MenuAction:action, param1, param2) {

	if (action == MenuAction_End)
		CloseHandle(menu);
	
	else if (action == MenuAction_Select)
		showMenu_Help(param1);
}


// Natives

public Native_SendPrivateMessage(Handle:plugin, numParams) {
	
	new len;
	
	GetNativeStringLength(1, len);
	decl String:sourceName[len + 1];
	GetNativeString(1, sourceName, len + 1);
	
	GetNativeStringLength(2, len);
	decl String:sourceId[len + 1];
	GetNativeString(2, sourceId, len + 1);

	GetNativeStringLength(3, len);
	decl String:destId[len + 1];
	GetNativeString(3, destId, len + 1);
	
	GetNativeStringLength(4, len);
	decl String:message[len + 1];
	GetNativeString(4, message, len + 1);
	
	// The message is queued and may take up to 20s to send.
	SendPM(sourceName, sourceId, destId, message);
}

// Helpers

SendPM(const String:sourceName[], const String:sourceId[], const String:destId[], const String:message[]) {
	
	// Add this message to the stack
	new Handle:thismessage = CreateDataPack();
	WritePackCell(thismessage, OP_SENDPM);
	WritePackString(thismessage, sourceName);
	WritePackString(thismessage, sourceId);
	WritePackString(thismessage, destId);
	WritePackString(thismessage, message);
	PushStackCell(g_operationqueue, thismessage);	
}

MessageDelete(messageId, client) {
	
	if(!CheckDBBeforeAction(client)) return;
	
	decl String:query[512];
	Format(query, sizeof(query), "UPDATE `%s` SET deleted = 1 WHERE id = %d", table_e, messageId);
	
	// This is high because we want it to happen before they get back to their inbox
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "Message deleted.", client); // we hope...
}

MessageMarkRead(messageId, client) {
	
	if(!CheckDBBeforeAction(client)) return;
	
	decl String:query[512];
	Format(query, sizeof(query), "UPDATE `%s` SET unread = 0 WHERE id = %d", table_e, messageId);
	
	// This is high because we want it to happen before they get back to their inbox
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
}

// SWEET JESUS, USE THIS FUNCTION WITH CARE
MessageDeleteAllFromUser(const String:sourceId[], const String:destId[], client) {
	
	if(!CheckDBBeforeAction(client)) return;
	
	decl String:sourceId_e[65];
	decl String:destId_e[65];
	SQL_EscapeString(db, sourceId, sourceId_e, sizeof(sourceId_e));
	SQL_EscapeString(db, destId, destId_e, sizeof(destId_e));
	
	decl String:query[512];
	Format(query, sizeof(query), "UPDATE `%s` SET deleted = 1 WHERE sourceId = '%s' AND destId = '%s'", table_e, sourceId_e, destId_e);
	
	// This is high because we want it to happen before they get back to their inbox
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "Messages deleted.", client); // we hope...
}

AddFriend(const String:userId[], const String:friendId[], const String:friendName[], client=0) {

	if(!CheckDBBeforeAction(client)) return;
	
	decl String:userId_e[65];
	decl String:friendId_e[65];
	decl String:friendName_e[129];
	SQL_EscapeString(db, userId, userId_e, sizeof(userId_e));
	SQL_EscapeString(db, friendId, friendId_e, sizeof(friendId_e));
	SQL_EscapeString(db, friendName, friendName_e, sizeof(friendName_e));
	
	decl String:query[1024];
	if(g_isSQLite)
		Format(query, sizeof(query), "INSERT OR REPLACE INTO `%s_friends` (userId, friendId, friendName) VALUES ('%s','%s','%s')", table_e, userId_e, friendId_e, friendName_e);
	else
		Format(query, sizeof(query), "INSERT INTO `%s_friends` (userId, friendId, friendName) VALUES ('%s','%s','%s') ON DUPLICATE KEY UPDATE friendName = '%s'", table_e, userId_e, friendId_e, friendName_e, friendName_e);
	
	// This is high because we want it to happen before they view anything else
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "Friend added.", client);
}

AddFriendDetectName(const String:steamId[], const String:friendId[], client=0) {
	if(!CheckDBBeforeAction(client)) return;
	if(client != 0 && !IsClientConnected(client)) return;
	
	decl String:friendId_e[65];
	SQL_EscapeString(db, friendId, friendId_e, sizeof(friendId_e));
	
	decl String:query[512];
	Format(query, sizeof(query), "SELECT lastName FROM `%s_players` WHERE steamId = '%s'", table_e, friendId_e);

	new userId = 0;
	if(client) userId = GetClientUserId(client);
	
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, userId);
	WritePackString(pack, steamId);
	WritePackString(pack, friendId);
	
	SQL_TQuery(db, callback_AddFriendDetectName, query, pack);
}

public callback_AddFriendDetectName(Handle:owner, Handle:hQuery, const String:error[], any:pack) {

	ResetPack(pack);
	new userId = ReadPackCell(pack);
	decl String:steamId[32], String:friendId[32], String:friendName[64];
	ReadPackString(pack, steamId, sizeof(steamId));
	ReadPackString(pack, friendId, sizeof(friendId));
	CloseHandle(pack);
	
	new client = 0;
	if(userId) client = GetClientOfUserId(userId);
	
	if(!CheckQueryBeforeAction(hQuery, error, client)) return;
	
	if(SQL_GetRowCount(hQuery) == 0) {
		if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "User doesn't exist in DB", client);
		else PrintToServer("[Signal] %T", "User doesn't exist in DB", LANG_SERVER);
		return;
	}
	
	SQL_FetchRow(hQuery);
	SQL_FetchString(hQuery, 0, friendName, sizeof(friendName));
	
	AddFriend(steamId, friendId, friendName, client);
}

RemoveFriend(const String:userId[], const String:friendId[], client) {

	if(!CheckDBBeforeAction(client)) return;
	
	decl String:userId_e[65];
	decl String:friendId_e[65];
	SQL_EscapeString(db, userId, userId_e, sizeof(userId_e));
	SQL_EscapeString(db, friendId, friendId_e, sizeof(friendId_e));
	
	decl String:query[1024];
	Format(query, sizeof(query), "DELETE FROM `%s_friends` WHERE userId = '%s' AND friendId = '%s'", table_e, userId_e, friendId_e);
	
	// This is high because we want it to happen before they view anything else
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "Friend removed.", client);
}

BlockUser(const String:userId[], const String:blockedId[], const String:blockedName[], client) {

	if(!CheckDBBeforeAction(client)) return;
	
	decl String:userId_e[65];
	decl String:blockedId_e[65];
	decl String:blockedName_e[129];
	SQL_EscapeString(db, userId, userId_e, sizeof(userId_e));
	SQL_EscapeString(db, blockedId, blockedId_e, sizeof(blockedId_e));
	SQL_EscapeString(db, blockedName, blockedName_e, sizeof(blockedName_e));
	
	decl String:query[1024];
	if(g_isSQLite)
		Format(query, sizeof(query), "INSERT OR REPLACE INTO `%s_blocks` (userId, blockedId, blockedName) VALUES ('%s','%s','%s')", table_e, userId_e, blockedId_e, blockedName_e);
	else
		Format(query, sizeof(query), "INSERT INTO `%s_blocks` (userId, blockedId, blockedName) VALUES ('%s','%s','%s') ON DUPLICATE KEY UPDATE blockedName = '%s'", table_e, userId_e, blockedId_e, blockedName_e, blockedName_e);
		
	
	// This is high because we want it to happen before they view anything else
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "User blocked.", client);
}

UnblockUser(const String:userId[], const String:blockedId[], client=0) {

	if(!CheckDBBeforeAction(client)) return;
	
	decl String:userId_e[65];
	decl String:blockedId_e[65];
	SQL_EscapeString(db, userId, userId_e, sizeof(userId_e));
	SQL_EscapeString(db, blockedId, blockedId_e, sizeof(blockedId_e));
	
	decl String:query[1024];
	Format(query, sizeof(query), "DELETE FROM `%s_blocks` WHERE userId = '%s' AND blockedId = '%s'", table_e, userId_e, blockedId_e);
	
	// This is high because we want it to happen before they view anything else
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "User unblocked.", client);
}

AddUserToGroup(const String:memberId[], const String:memberName[], groupId, client) {
	if(!CheckDBBeforeAction(client)) return;
	
	decl String:memberId_e[65];
	decl String:memberName_e[129];
	SQL_EscapeString(db, memberId, memberId_e, sizeof(memberId_e));
	SQL_EscapeString(db, memberName, memberName_e, sizeof(memberName_e));
	
	decl String:query[1024];
	if(g_isSQLite)
		Format(query, sizeof(query), "INSERT OR REPLACE INTO `%s_groupmembers` (groupId, memberId, memberName) VALUES ('%d','%s','%s')", table_e, groupId, memberId_e, memberName_e);
	else
		Format(query, sizeof(query), "INSERT INTO `%s_groupmembers` (groupId, memberId, memberName) VALUES ('%d','%s','%s') ON DUPLICATE KEY UPDATE memberName = '%s'", table_e, groupId, memberId_e, memberName_e, memberName_e);
	
	// This is high because we want it to happen before they view anything else
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "Member added.", client);
}

CreateGroup(const String:groupName[], const String:ownerId[], client=0) {
	if(!CheckDBBeforeAction(client)) return;
	
	decl String:ownerId_e[65];
	decl String:groupName_e[129];
	SQL_EscapeString(db, ownerId, ownerId_e, sizeof(ownerId_e));
	SQL_EscapeString(db, groupName, groupName_e, sizeof(groupName_e));
	
	decl String:query[1024];
	if(g_isSQLite)
		Format(query, sizeof(query), "INSERT OR REPLACE INTO `%s_groups` (groupName, ownerId) VALUES ('%s','%s')", table_e, groupName_e, ownerId_e);
	else
		Format(query, sizeof(query), "INSERT INTO `%s_groups` (groupName, ownerId) VALUES ('%s','%s') ON DUPLICATE KEY UPDATE groupName = '%s'", table_e, groupName_e, ownerId_e, groupName_e);
	
	// This is high because we want it to happen before they view anything else
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "Group created.", client);
}

RemoveUserFromGroup(const String:memberId[], groupId, client=0) {
	if(!CheckDBBeforeAction(client)) return;
	
	decl String:memberId_e[65];
	SQL_EscapeString(db, memberId, memberId_e, sizeof(memberId_e));
	
	decl String:query[1024];
	Format(query, sizeof(query), "DELETE FROM `%s_groupmembers` WHERE groupId = %d AND memberId = '%s'", table_e, groupId, memberId);
	
	// This is high because we want it to happen before they view anything else
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "Group member removed.", client);
}

DeleteGroup(groupId, client=0) {
	if(!CheckDBBeforeAction(client)) return;
	
	decl String:query[1024];
	Format(query, sizeof(query), "DELETE FROM `%s_groups` WHERE groupId = %d", table_e, groupId);
	
	// This is high because we want it to happen before they view anything else
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "Group removed.", client);
}

stock DeleteGroupByName(const String:groupName[], const String:ownerId[], client=0) {
	if(!CheckDBBeforeAction(client)) return;
	
	decl String:groupName_e[65];
	decl String:ownerId_e[65];
	SQL_EscapeString(db, groupName, groupName_e, sizeof(groupName_e));
	SQL_EscapeString(db, ownerId, ownerId_e, sizeof(ownerId_e));
	
	decl String:query[1024];
	Format(query, sizeof(query), "DELETE FROM `%s_groups` WHERE ownerId = '%s' AND groupName = '%s'", table_e, ownerId, groupName);
	
	// This is high because we want it to happen before they view anything else
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "Group removed.", client);
}

stock SetGroupOwner(groupId, const String:ownerId[], client=0) {
	if(!CheckDBBeforeAction(client)) return;
	
	decl String:ownerId_e[65];
	SQL_EscapeString(db, ownerId, ownerId_e, sizeof(ownerId_e));
	
	decl String:query[1024];
	Format(query, sizeof(query), "UPDATE `%s_groups` SET ownerId = '%s' WHERE groupId = %d", table_e, ownerId_e, groupId);
	
	// This is high because we want it to happen before they view anything else
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_High);
	
	if(client) PrintToChat(client, "\x04[Signal]\x01 %T", "Group owner changed.", client);
}

UpdatePlayerNameInDatabase(const String:name[], const String:steamId[]) {
	
	if(db == INVALID_HANDLE) return;
	
	decl String:name_e[129], String:steamId_e[65];
	SQL_EscapeString(db, name, name_e, sizeof(name_e));
	SQL_EscapeString(db, steamId, steamId_e, sizeof(steamId_e));

	decl String:query[1024];
	if(g_isSQLite)
		Format(query, sizeof(query), "INSERT OR REPLACE INTO `%s_players` (lastName, steamId, lastSeen) VALUES ('%s', '%s', %d)", table_e, name_e, steamId_e, GetTime());
	else
		Format(query, sizeof(query), "INSERT INTO `%s_players` (lastName, steamId, lastSeen) VALUES ('%s', '%s', CURRENT_TIMESTAMP) ON DUPLICATE KEY UPDATE lastName = '%s', lastSeen = CURRENT_TIMESTAMP", table_e, name_e, steamId_e, name_e);
		
	
	SQL_TQuery(db, callback_ignoreresult, query, 0, DBPrio_Normal);
}

UpdateOnlineStatusInDatabase() {	
	decl String:query[sizeof(g_SteamIdQueryList) + 256];
	if(g_isSQLite)
		Format(query, sizeof(query), "UPDATE `%s_players` SET lastSeen = %d WHERE steamId IN ('%s')", table_e, GetTime(), g_SteamIdQueryList);
	else
		Format(query, sizeof(query), "UPDATE `%s_players` SET lastSeen = CURRENT_TIMESTAMP WHERE steamId IN ('%s')", table_e, g_SteamIdQueryList);
	
	SQL_TQuery(db, callback_ignoreresult, query);
}

// Operation Queue

public Action:Timer_FlushQueue(Handle:timer) {
	if(!IsStackEmpty(g_operationqueue))
		processOperationQueue();
}

processOperationQueue() {
	
	if(db == INVALID_HANDLE) {
		// Doesn't matter, we'll be back here soon
		ErrMsg("Database Connection", "Invalid database connection");
		refreshDatabaseConnection();
		return;
	}
	
	while(!IsStackEmpty(g_operationqueue)) {
		new Handle:operationPack;
		PopStackCell(g_operationqueue, operationPack);
		ResetPack(operationPack);
		new operationType = ReadPackCell(operationPack);
		
		if(operationType == OP_SENDPM)
			processOperationQueue_handlePM(operationPack);
	}
}

processOperationQueue_handlePM(Handle:operationPack) {

	decl String:sourceId[32], String:sourceId_e[65];
	decl String:destId[32], String:destId_e[65];
	decl String:junk[128];
	
	ResetPack(operationPack);
	ReadPackCell(operationPack);
	ReadPackString(operationPack, junk, sizeof(junk));
	ReadPackString(operationPack, sourceId, sizeof(sourceId));
	ReadPackString(operationPack, destId, sizeof(destId));
	
	SQL_EscapeString(db, sourceId, sourceId_e, sizeof(sourceId_e));
	SQL_EscapeString(db, destId, destId_e, sizeof(destId_e));
	
	decl String:query[512];
	Format(query, sizeof(query), "\
		SELECT blockedId FROM `%s_blocks` WHERE userId = '%s' AND blockedId = '%s'",
		table_e, destId_e, sourceId_e);
	
	SQL_TQuery(db, handlePM_callback_blockcheck, query, operationPack);
}

public handlePM_callback_blockcheck(Handle:owner, Handle:hQuery, const String:error[], any:operationPack) {

	if(hQuery == INVALID_HANDLE) {
		ErrMsg("Database Query", error);
		PushStackCell(g_operationqueue, operationPack);
		refreshDatabaseConnection();
	}
	
	decl String:sourceName[64], String:sourceName_e[129];
	decl String:sourceId[32], String:sourceId_e[65];
	decl String:destId[32], String:destId_e[65];
	decl String:message[256], String:message_e[513];
	
	ResetPack(operationPack);
	ReadPackCell(operationPack);
	ReadPackString(operationPack, sourceName, sizeof(sourceName));
	ReadPackString(operationPack, sourceId, sizeof(sourceId));
	ReadPackString(operationPack, destId, sizeof(destId));
	ReadPackString(operationPack, message, sizeof(message));
	
	if(SQL_GetRowCount(hQuery) != 0) {
		new client = getClientFromAuthId(sourceId);
		if(client > 0)
			PrintToChat(client, "\x04[Signal]\x01 %T", "Blocked by ID", client, destId);
		CloseHandle(operationPack);
		return;
	}
	
	SQL_EscapeString(db, sourceName, sourceName_e, sizeof(sourceName_e));
	SQL_EscapeString(db, sourceId, sourceId_e, sizeof(sourceId_e));
	SQL_EscapeString(db, destId, destId_e, sizeof(destId_e));
	SQL_EscapeString(db, message, message_e, sizeof(message_e));
	
	// Build the query string
	decl String:query[1024];
	if(g_isSQLite)
		Format(query, sizeof(query), "\
			INSERT INTO `%s` (sourceName, sourceId, destId, message, time, unread, deleted) VALUES ('%s', '%s', '%s', '%s', %d, 1, 0)", 
			table_e, sourceName_e, sourceId_e, destId_e, message_e, GetTime());
	else
		Format(query, sizeof(query), "\
			INSERT INTO `%s` (sourceName, sourceId, destId, message, time, unread, deleted) VALUES ('%s', '%s', '%s', '%s', CURRENT_TIMESTAMP, 1, 0)", 
			table_e, sourceName_e, sourceId_e, destId_e, message_e);
	
	// Send it off
	SQL_TQuery(db, handlePM_callback_final, query, operationPack);
}

public handlePM_callback_final(Handle:owner, Handle:hQuery, const String:error[], any:operationPack) {
	
	if(hQuery == INVALID_HANDLE) {
		ErrMsg("Database Query", error);
		PushStackCell(g_operationqueue, operationPack);
		refreshDatabaseConnection();
	}
	
	else CloseHandle(operationPack);
}

// Other

ErrMsg(const String:type[], const String:message[]) {
	LogAction(0, -1, "[Signal] %T %T: '%s'", type, LANG_SERVER, "Error", LANG_SERVER, message);
	PrintToServer("[Signal] %T %T: '%s'", type, LANG_SERVER, "Error", LANG_SERVER, message);
}

bool:CheckDBBeforeAction(client=0) {
	if(db == INVALID_HANDLE) {
		ErrMsg("Database Connection", "No connection is present");
		refreshDatabaseConnection();
		if(client > 0) PrintToChat(client, "\x04[Signal]\x01 %T", "Action not performed", client);
		return false;
	}
	
	return true;
}

bool:CheckQueryBeforeAction(Handle:hQuery, const String:error[], client=0) {
	if(hQuery == INVALID_HANDLE) {
		ErrMsg("Database Query", error);
		refreshDatabaseConnection();
		if(client > 0) PrintToChat(client, "\x04[Signal]\x01 %T", "Action not performed", client);
		return false;
	}
	
	return true;
}

bool:AtServerConsole(client) {
	if(client <= 0) {
		PrintToServer("[Signal] %T", "Restricted to in-game", LANG_SERVER);
		return true;
	}
	else return false;
}

public callback_ignoreresult(Handle:owner, Handle:hQuery, const String:error[], any:data) {
	if(hQuery == INVALID_HANDLE) {
		if(!data) refreshDatabaseConnection();
		ErrMsg("Database Query", error);
	}
}

public callback_ignoreresult_expecterr(Handle:owner, Handle:hQuery, const String:error[], any:data) {
	// Well, nothing to do here then...
}

AddMenuTranslatedItem(Handle:menu, const String:info[], const String:translation[], client) {
	decl String:translatedText[128];
	Format(translatedText, sizeof(translatedText), "%T", translation, client);
	AddMenuItem(menu, info, translatedText);
}

DrawPanelTranslatedItem(Handle:panel, const String:translation[], client, bool:disabled=false) {
	decl String:translatedText[128];
	Format(translatedText, sizeof(translatedText), "%T", translation, client);
	DrawPanelItem(panel, translatedText, (disabled ? ITEMDRAW_DISABLED : ITEMDRAW_DEFAULT));
}

DrawPanelTranslatedText(Handle:panel, const String:translation[], client) {
	decl String:translatedText[128];
	Format(translatedText, sizeof(translatedText), "%T", translation, client);
	DrawPanelText(panel, translatedText);
}

DrawPanelBlankLine(Handle:panel) {
	DrawPanelText(panel, " ");
}

DrawPanelDivider(Handle:panel) {
	DrawPanelText(panel, "------------------");
}

// Installation

setupTable() {

	decl String:query[1024];

	// SQLite queries
	if(g_isSQLite) {
	
		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s` (id INTEGER PRIMARY KEY, destId TEXT, sourceId TEXT, sourceName TEXT, message TEXT, \
	unread INTEGER, deleted INTEGER, time INTEGER)", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);
		
		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s_friends` (userId TEXT, friendId TEXT, friendName TEXT, PRIMARY KEY (userId, friendId))", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);

		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s_blocks` (userId TEXT, blockedId TEXT, blockedName TEXT, PRIMARY KEY (userId, blockedId))", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);
		
		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s_groups` (groupId INTEGER PRIMARY KEY, ownerId TEXT, groupName TEXT, UNIQUE(ownerId, groupName))", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);

		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s_groupmembers` (groupId INTEGER, memberId TEXT, memberName TEXT, PRIMARY KEY (groupId, memberId))", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);
		
		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s_players` (steamId TEXT PRIMARY KEY, lastName TEXT, lastSeen INTEGER)", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);
	
	// MySQL queries
	} else {
		
		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s` ( \
		`id` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, \
		`destId` VARCHAR(31) NOT NULL, \
		`sourceId` VARCHAR(31) NOT NULL, \
		`sourceName` VARCHAR(63) NOT NULL, \
		`message` VARCHAR(255) NOT NULL, \
		`unread` BOOL NOT NULL, \
		`time` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP \
	) ENGINE = MYISAM;", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);
		
		// This keeps updates seamless. Added in v1.2.0
		Format(query, sizeof(query), "ALTER TABLE `%s` ADD `deleted` BOOL NOT NULL", table_e);
		SQL_TQuery(db, callback_ignoreresult_expecterr, query, 1, DBPrio_High);
		
		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s_friends` ( \
		`userId` VARCHAR(31) NOT NULL, \
		`friendId` VARCHAR(31) NOT NULL, \
		`friendName` VARCHAR(63) NOT NULL, \
		PRIMARY KEY (`userId` (31), `friendId` (31)) \
	) ENGINE = MYISAM;", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);

		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s_blocks` ( \
		`userId` VARCHAR(31) NOT NULL, \
		`blockedId` VARCHAR(31) NOT NULL, \
		`blockedName` VARCHAR(63) NOT NULL, \
		PRIMARY KEY (`userId` (31), `blockedId` (31)) \
	) ENGINE = MYISAM;", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);
		
		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s_groups` ( \
		`groupId` INT NOT NULL AUTO_INCREMENT PRIMARY KEY, \
		`ownerId` VARCHAR(31) NOT NULL, \
		`groupName` VARCHAR(63) NOT NULL, \
		UNIQUE `OwnerGroupNamePair` (`ownerId` (31), `groupName` (63)) \
	) ENGINE = MYISAM;", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);

		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s_groupmembers` ( \
		`groupId` INT NOT NULL, \
		`memberId` VARCHAR(31) NOT NULL, \
		`memberName` VARCHAR(63) NOT NULL, \
		PRIMARY KEY (`groupId`, `memberId` (31)) \
	) ENGINE = MYISAM;", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);
		
		Format(query, sizeof(query), "\
	CREATE TABLE IF NOT EXISTS `%s_players` ( \
		`steamId` VARCHAR(31) NOT NULL PRIMARY KEY, \
		`lastName` VARCHAR(63) NOT NULL, \
		`lastSeen` TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP \
	) ENGINE = MYISAM;", table_e);
		SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);
	
	}
	
	// Both MySQL and SQLite
	
	// Perform some cleanup
	// Not doing this as soon as the group is deleted means admins have
	// a short window in which to restore mistakenly deleted groups
	Format(query, sizeof(query), "DELETE FROM `%s_groupmembers` WHERE groupId NOT IN (SELECT groupId FROM `%s_groups`)", table_e, table_e);
	SQL_TQuery(db, callback_ignoreresult, query, 1, DBPrio_High);
}
