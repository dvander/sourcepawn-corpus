#pragma semicolon 1
#include <sourcemod>
#include <socket>

#define PLUGIN_VERSION "1.0"

#define LOGIN_SERVER "login.icq.com"
#define LOGIN_PORT 5190

// does not work.
//#define USE_MD5_LOGIN 1
#if defined USE_MD5_LOGIN
#include <md5>
#endif

// Set this to your icq number and password
new String:g_sUID[] = "";
new String:g_sPassword[] = "";

// Random client information about "this" client
#define CLIENT_ID_STRING "sourcemod icq client 1.00"
#define CLIENT_ID 266
#define CLIENT_MAJOR 5
#define CLIENT_MINOR 2
#define CLIENT_LESSER 1
#define CLIENT_BUILD 5000
#define CLIENT_LANGUAGE "en"
#define CLIENT_COUNTRY "us"

// Status FLAGS (used to determine status of other users)
#define STATUS_ONLINE 0x0000
#define STATUS_AWAY 0x0001
#define STATUS_DND 0x0002
#define STATUS_NA 0x0004
#define STATUS_OCCUPIED 0x0010
#define STATUS_FREE4CHAT 0x0020
#define STATUS_INVISIBLE 0x0100

// Status values (used to set own status)
#define STATUS_SET_ONLINE 0x0000
#define STATUS_SET_AWAY 0x0001
#define STATUS_SET_DND 0x0005
#define STATUS_SET_NA 0x0011
#define STATUS_SET_OCCUPIED 0x0013
#define STATUS_SET_FREE4CHAT 0x0020
#define STATUS_SET_INVISIBLE 0x0100

#define STATUFLAG_WEBAWARE 0x0001 // Status webaware flag
#define STATUSFLAG_SHOWIP 0x0002 // Status show ip flag
#define STATUSFLAG_BIRTHDAY 0x0008 // User birthday flag
#define STATUSFLAG_WEBFRONT 0x0020 // User active webfront flag
#define STATUSFLAG_DCDISABLED 0x0100 // Direct connection not supported
#define STATUSFLAG_DCAUTH 0x1000 // Direct connection upon authorization
#define STATUSFLAG_DCCONT 0x2000 // DC only with contact users

#define USERCLASS_UNCONFIRMED 0x0001 // AOL unconfirmed user flag
#define USERCLASS_ADMINISTRATOR 0x0002 // AOL administrator flag
#define USERCLASS_AOL 0x0004 // AOL staff user flag
#define USERCLASS_COMMERCIAL 0x0008 // AOL commercial account flag
#define USERCLASS_FREE 0x0010 // ICQ non-commercial account flag
#define USERCLASS_AWAY 0x0020 // Away status flag
#define USERCLASS_ICQ 0x0040 // ICQ user sign
#define USERCLASS_WIRELESS 0x0080 // ICQ user sign
#define USERCLASS_UNKNOWN100 0x0100 // Unknown bit
#define USERCLASS_UNKNOWN200 0x0200 // Unknown bit
#define USERCLASS_UNKNOWN400 0x0400 // Unknown bit
#define USERCLASS_UNKNOWN800 0x0800 // Unknown bit

#define MTYPE_PLAIN 0x01 // Plain text (simple) message
#define MTYPE_CHAT 0x02 // Chat request message
#define MTYPE_FILEREQ 0x03 // File request / file ok message
#define MTYPE_URL 0x04 // URL message (0xFE formatted)
#define MTYPE_AUTHREQ 0x06 // Authorization request message (0xFE formatted)
#define MTYPE_AUTHDENY 0x07 // Authorization denied message (0xFE formatted)
#define MTYPE_AUTHOK 0x08 // Authorization given message (empty)
#define MTYPE_SERVER 0x09 // Message from OSCAR server (0xFE formatted)
#define MTYPE_ADDED 0x0C // "You-were-added" message (0xFE formatted)
#define MTYPE_WWP 0x0D // Web pager message (0xFE formatted)
#define MTYPE_EEXPRESS 0x0E // Email express message (0xFE formatted)
#define MTYPE_CONTACTS 0x13 // Contact list message
#define MTYPE_PLUGIN 0x1A // Plugin message described by text string
#define MTYPE_AUTOAWAY 0xE8 // Auto away message 
#define MTYPE_AUTOBUSY 0xE9 // Auto occupied message
#define MTYPE_AUTONA 0xEA // Auto not available message 
#define MTYPE_AUTODND 0xEB // Auto do not disturb message 
#define MTYPE_AUTOFFC 0xEC // Auto free for chat message

#define MFLAG_NORMAL 0x01 // Normal message
#define MFLAG_AUTO 0x03 // Auto-message flag
#define MFLAG_MULTI 0x80 // This is multiple recipients message

// Typing notification statuses
#define MTN_FINISHED 0x0000
#define MTN_TYPED 0x0001
#define MTN_BEGUN 0x0002
#define MTN_WINDOW_CLOSED 0x000F


// MOTD types list
#define MTD_MTD_UPGRADE 0x001 // Mandatory upgrade needed notice
#define MTD_ADV_UPGRAGE 0x002 // Advisable upgrade notice
#define MTD_SYS_BULLETIN 0x003 // AIM/ICQ service system announcements
#define MTD_NORMAL 0x004 // Standart notice
#define MTD_NEWS 0x006 // Some news from AOL service

#define ERR_SNAC_INVALID 0x01 // Invalid SNAC header.
#define ERR_SRV_RATE_EXCEED 0x02 // Server rate limit exceeded
#define ERR_CLI_RATE_EXCEED 0x03 // Client rate limit exceeded
#define ERR_RECP_NOT_LOGGED 0x04 // Recipient is not logged in
#define ERR_SRVC_UN_AVAILABLE 0x05 // Requested service unavailable
#define ERR_SRVC_NOT_DEFINED 0x06 // Requested service not defined
#define ERR_SNAC_OBSOLETE 0x07 // You sent obsolete SNAC
#define ERR_SRV_NOT_SUPP 0x08 // Not supported by server
#define ERR_CLI_NOT_SUPP 0x09 // Not supported by client
#define ERR_CLI_REFUSED 0x0A // Refused by client
#define ERR_REPLY_TOO_BIG 0x0B // Reply too big
#define ERR_RESPS_LOST 0x0C // Responses lost
#define ERR_REQ_DENIED 0x0D // Request denied
#define ERR_SNAC_FORMAT 0x0E // Incorrect SNAC format
#define ERR_INSUFF_RIGHTS 0x0F // Insufficient rights
#define ERR_SNAC_LOCAL_DENY 0x10 // In local permit/deny (recipient blocked)
#define ERR_SENDER_TOO_EVIL 0x11 // Sender too evil
#define ERR_RECVER_TOO_EVIL 0x12 // Receiver too evil
#define ERR_USER_TEMP_UNAVAIL 0x13 // User temporarily unavailable
#define ERR_NO_MATCH 0x14 // No match
#define ERR_LIST_OVERFLOW 0x15 // List overflow
#define ERR_REQ_AMBIQUOUS 0x16 // Request ambiguous
#define ERR_SRV_QUEUE_FULL 0x17 // Server queue full
#define ERR_NOT_WHILE 0x18 // Not while on AOL

// FLAP Channel list
enum FLAP_Channel {
	FLAP_LOGIN = 1,
	FLAP_SNAC,
	FLAP_ERROR,
	FLAP_LOGOUT,
	FLAP_KEEPALIVE
}

enum Login_State {
	Login_NotLoggedIn = 0,
	Login_LoginSent,
	Login_Migrating,
	Login_LoggedIn
}

enum Rate_Class {
	Class_ID = 0,
	Window_Size,
	Clear_Level,
	Alert_Level,
	Limit_Level,
	Disconnect_Level,
	Current_Level,
	Max_Level,
	Last_Time,
	Current_State
}

new Login_State:g_iLoginState = Login_NotLoggedIn;

new Handle:g_hSocket;

new String:g_sOwnNickname[64];
new String:g_sOwnFirstname[64];
new String:g_sOwnLastname[64];

new g_iIncomingSequence = -1;
new g_iOutgoingSequence = -1;
new g_iMetaSequence = 2;
new bool:g_bConnected = false;
new bool:g_bPause = false;

// Current package to write to
new String:g_sTempCurrentPackage[8192];
new g_iTempCurrentPackageLength = 0;

new String:g_sTempMetaPackage[8192];
new g_iTempMetaPackageLength = 0;

new String:g_sServiceServerIP[33];
new g_iServiceServerPort;
new String:g_sCookie[512];
new g_iCookieLength = 0;

// xor with password
new const g_iXORSeq[] = {0xF3, 0x26, 0x81, 0xC4, 0x39, 0x86, 0xDB, 0x92, 0x71, 0xA3, 0xB9, 0xE6, 0x53, 0x7A, 0x95, 0x7C};

// Contact status
new g_iStatus = STATUS_ONLINE;
new g_iStatusFlags = STATUSFLAG_DCDISABLED;

new Handle:g_hRequests;

new Handle:g_hMetaRequests;

new Handle:g_hBuddyUINs;
new Handle:g_hContactList;
new Handle:g_hContactGroups;

new Handle:g_hSupportedFamilies;
new Handle:g_hRateClasses;
new Handle:g_hRateGroups;

new Handle:g_hSettings;

// filetransfer proxy stuff
new Handle:g_hProxyInfo;

new Handle:g_hDatabase;
new g_iOwnDBID = -1;

new String:g_sLastMessageFrom[64];

public Plugin:myinfo = 
{
	name = "ICQ Client",
	author = "Jannik \"Peace-Maker\" Hartung",
	description = "ICQ Instant Messenger",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	if(strlen(g_sUID) == 0 || strlen(g_sPassword) == 0)
		SetFailState("You need to set the UIN and password first before compiling.");
	
	new Handle:hVersion = CreateConVar("sm_icq_version", PLUGIN_VERSION, "ICQ Instant Messenger", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	RegServerCmd("sm_sendicq", SrvCmd_SendMsg, "Sends a message to an icq buddy. Usage: sm_sendicq <uin> <message>");
	RegServerCmd("sm_reply", SrvCmd_Reply, "Sends a message to the last person, which sent the last message in this session. Usage: sm_reply <message>");
	RegServerCmd("sm_listbuddies", SrvCmd_ListBuddies, "Lists all known buddies");
	RegServerCmd("sm_setstatus", SrvCmd_SetStatus, "Sets the status: online, away, dnd, na, occupied, free4chat, invisible");
	
	RegServerCmd("sm_removebuddy", SrvCmd_RemoveBuddy, "Removes a buddy from your contact list.");
	RegServerCmd("sm_addbuddy", SrvCmd_AddBuddy, "Adds a buddy to your contact list.");
	
	g_hRequests = CreateArray();
	g_hBuddyUINs = CreateArray(ByteCountToCells(33));
	g_hContactList = CreateTrie();
	g_hContactGroups = CreateArray(2);
	
	g_hSupportedFamilies = CreateArray(2);
	g_hRateClasses = CreateArray(10);
	g_hRateGroups = CreateArray();
	
	g_hMetaRequests = CreateArray(2);
	g_hSettings = CreateTrie();
	
	g_hProxyInfo = CreateArray();
	
	decl String:sError[33];
	g_hDatabase = SQLite_UseDatabase("icq", sError, sizeof(sError));
	if(g_hDatabase == INVALID_HANDLE)
		SetFailState("Unable to open icq sqlite database: %s", sError);
	
	decl String:sQuery[256];
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS icq_clients (id INTEGER PRIMARY KEY AUTOINCREMENT, uin INTEGER NOT NULL UNIQUE, nickname VARCHAR(64), firstname VARCHAR(64), lastname VARCHAR(64));");
	if(!SQL_FastQuery(g_hDatabase, sQuery))
	{
		SQL_GetError(g_hDatabase, sError, sizeof(sError));
		SetFailState("Error creating icq_clients table: %s", sError);
	}
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS icq_buddies (id INTEGER PRIMARY KEY AUTOINCREMENT, client_id INTEGER NOT NULL, uin INTEGER NOT NULL, nickname VARCHAR(64), firstname VARCHAR(64), lastname VARCHAR(64), userclass INTEGER, member_since INTEGER);");
	if(!SQL_FastQuery(g_hDatabase, sQuery))
	{
		SQL_GetError(g_hDatabase, sError, sizeof(sError));
		SetFailState("Error creating icq_buddies table: %s", sError);
	}
	Format(sQuery, sizeof(sQuery), "CREATE TABLE IF NOT EXISTS icq_messages (id INTEGER PRIMARY KEY AUTOINCREMENT, buddy_id INTEGER NOT NULL, message VARCHAR(256) NOT NULL, time_sent INTEGER NOT NULL, read INTEGER NOT NULL DEFAULT 0);");
	if(!SQL_FastQuery(g_hDatabase, sQuery))
	{
		SQL_GetError(g_hDatabase, sError, sizeof(sError));
		SetFailState("Error creating icq_messages table: %s", sError);
	}
	
	Format(sQuery, sizeof(sQuery), "SELECT id, uin, nickname, firstname, lastname FROM icq_clients WHERE uin = \"%s\";", g_sUID);
	SQL_TQuery(g_hDatabase, Query_GetOwnInfo, sQuery);
}

public OnPluginEnd()
{
	if(g_hSocket != INVALID_HANDLE)
		CloseHandle(g_hSocket);
}

public Action:SrvCmd_SendMsg(args)
{
	if(args < 2)
	{
		PrintToServer("ICQ: Usage: sm_sendicq <uin> <message>");
		return Plugin_Handled;
	}
	
	decl String:sUIN[16];
	GetCmdArg(1, sUIN, sizeof(sUIN));
	
	new String:sMsg[512], String:sBuffer[64];
	for(new i=2;i<=args;i++)
	{
		GetCmdArg(i, sBuffer, sizeof(sBuffer));
		Format(sMsg, sizeof(sMsg), "%s %s", sMsg, sBuffer);
	}
	
	new Handle:hArgs = CreateArray(ByteCountToCells(512));
	PushArrayString(hArgs, sUIN);
	PushArrayString(hArgs, sMsg);
	SendSNAC("CLI_SEND_ICBM_CH1", hArgs);
	
	return Plugin_Handled;
}

public Action:SrvCmd_Reply(args)
{
	if(args < 1)
	{
		PrintToServer("ICQ: Usage: sm_reply <message>");
		return Plugin_Handled;
	}
	
	if(strlen(g_sLastMessageFrom) == 0)
	{
		PrintToServer("ICQ: No person to reply to..");
		return Plugin_Handled;
	}
	
	new String:sMsg[512], String:sBuffer[64];
	for(new i=1;i<=args;i++)
	{
		GetCmdArg(i, sBuffer, sizeof(sBuffer));
		Format(sMsg, sizeof(sMsg), "%s %s", sMsg, sBuffer);
	}
	
	new Handle:hArgs = CreateArray(ByteCountToCells(512));
	PushArrayString(hArgs, g_sLastMessageFrom);
	PushArrayString(hArgs, sMsg);
	SendSNAC("CLI_SEND_ICBM_CH1", hArgs);
	
	return Plugin_Handled;
}

public Action:SrvCmd_ListBuddies(args)
{
	decl String:sUIN[64];
	new iSize = GetArraySize(g_hBuddyUINs);
	PrintToServer("Listing %d buddies", iSize);
	new Handle:hBuddy, iStatus, bool:bOffline = false;
	decl String:sGroup[32], String:sNick[64], String:sFirst[64], String:sLast[64];
	new iGroupCount = GetArraySize(g_hContactGroups), iMemberCount, iBuddyID;
	new hGroupInfo[2];
	for(new g=0;g<iGroupCount;g++)
	{
		GetArrayArray(g_hContactGroups, g, hGroupInfo, 2);
		GetArrayString(Handle:hGroupInfo[1], 0, sGroup, sizeof(sGroup));
		PrintToServer("Group %d: %s", g, sGroup);
		iMemberCount = GetArraySize(Handle:hGroupInfo[1])-1;
		for(new m=0;m<iMemberCount;m++)
		{
			for(new i=0;i<iSize;i++)
			{
				GetArrayString(g_hBuddyUINs, i, sUIN, sizeof(sUIN));
				if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
				{
					PrintToServer("Can't find %s ?!", sUIN);
					continue;
				}
				
				if(!GetTrieValue(hBuddy, "buddy_id", iBuddyID))
				{
					//PrintToServer("%s got no buddy_id.", sUIN);
					continue;
				}
				else
				{
					// This one isn't in this group
					if(iBuddyID != GetArrayCell(Handle:hGroupInfo[1], m+1))
						continue;
				}
				
				sNick[0] = '\0';
				GetTrieString(hBuddy, "nickname", sNick, sizeof(sNick));
				
				sFirst[0] = '\0';
				GetTrieString(hBuddy, "firstname", sFirst, sizeof(sFirst));
				
				sLast[0] = '\0';
				GetTrieString(hBuddy, "lastname", sLast, sizeof(sLast));
				
				iStatus = 0;
				GetTrieValue(hBuddy, "user_status", iStatus);
				
				bOffline = true;
				GetTrieValue(hBuddy, "offline", bOffline);
				
				PrintToServer("%s: Nick: %s First: %s Last: %s Status: %02x Offline: %d", sUIN, sNick, sFirst, sLast, iStatus, bOffline);
			}
		}
	}
	
	return Plugin_Handled;
}

public Action:SrvCmd_SetStatus(args)
{
	if(args < 1)
	{
		PrintToServer("ICQ: Usage: sm_setstatus <online|away|dnd|na|occupied|free4chat|invisible>");
		return Plugin_Handled;
	}
	
	decl String:sStatus[16];
	GetCmdArg(1, sStatus, sizeof(sStatus));
	
	StripQuotes(sStatus);
	
	if(StrEqual(sStatus, "online"))
		g_iStatus = STATUS_SET_ONLINE;
	else if(StrEqual(sStatus, "away"))
		g_iStatus = STATUS_SET_AWAY;
	else if(StrEqual(sStatus, "dnd"))
		g_iStatus = STATUS_SET_DND;
	else if(StrEqual(sStatus, "na"))
		g_iStatus = STATUS_SET_NA;
	else if(StrEqual(sStatus, "occupied"))
		g_iStatus = STATUS_SET_OCCUPIED;
	else if(StrEqual(sStatus, "free4chat"))
		g_iStatus = STATUS_SET_FREE4CHAT;
	else if(StrEqual(sStatus, "invisible"))
		g_iStatus = STATUS_SET_INVISIBLE;
	else
	{
		PrintToServer("Unkown status..");
		return Plugin_Handled;
	}
	
	SendSNAC("CLI_SETxSTATUS");
	
	return Plugin_Handled;
}

public Action:SrvCmd_RemoveBuddy(args)
{
	if(args < 1)
	{
		PrintToServer("ICQ: Usage: sm_removebuddy <uin>");
		return Plugin_Handled;
	}
	
	decl String:sUIN[32];
	GetCmdArg(1, sUIN, sizeof(sUIN));
	StripQuotes(sUIN);
	
	SendSNAC("CLI_SSI_EDIT_BEGIN");
	new Handle:hArgs = CreateArray(ByteCountToCells(32));
	PushArrayString(hArgs, sUIN);
	SendSNAC("CLI_SSIxDELETE_BUDDY", hArgs);
	
	SendSNAC("CLI_SSI_EDIT_END");
	
	return Plugin_Handled;
}

public Action:SrvCmd_AddBuddy(args)
{
	if(args < 1)
	{
		PrintToServer("ICQ: Usage: sm_addbuddy <uin>");
		return Plugin_Handled;
	}
	
	decl String:sUIN[32];
	GetCmdArg(1, sUIN, sizeof(sUIN));
	StripQuotes(sUIN);
	
	SendSNAC("CLI_SSI_EDIT_BEGIN");
	new Handle:hArgs = CreateArray(ByteCountToCells(32));
	PushArrayString(hArgs, sUIN);
	new hGroupID[2], iSize = GetArraySize(g_hContactGroups);
	if(iSize > 0)
		GetArrayArray(g_hContactGroups, 0, hGroupID, 2);
	PushArrayCell(hArgs, hGroupID[0]);
	SendSNAC("CLI_SSIxADD_BUDDY", hArgs);
	
	SendSNAC("CLI_SSI_EDIT_END");
	
	return Plugin_Handled;
}

public Socket_OnError(Handle:socket, const errorType, const errorNum, any:arg)
{
	PrintToServer("Socket error type: %d, num: %d", errorType, errorNum);
	CloseHandle(g_hSocket);
	g_hSocket = INVALID_HANDLE;
}

public Socket_OnConnect(Handle:socket, any:arg)
{
	PrintToServer("Connected.");
}

public Socket_OnReceive(Handle:socket, const String:receiveData[], const dataSize, any:arg)
{
	//PrintToServer("Received (%d): %s", dataSize, receiveData);
	
	new iReadLength = ProcessPackage(receiveData, dataSize);
	if(iReadLength == -1)
		return;
	
	new iTemp;
	// We got more data. parse it all
	while(iReadLength < dataSize)
	{
		// Failed parsing.. don't proceed, to avoid infinite loop
		iTemp = ProcessPackage(receiveData[iReadLength], dataSize-iReadLength);
		if(iTemp == -1)
			break;
		iReadLength += iTemp;
		//PrintToServer("Recalling OnReceive.. Used length: %d, available: %d", iReadLength, dataSize);
	}
}

public Socket_OnDisconnect(Handle:socket, any:arg)
{
	PrintToServer("Disconnected.");
	CloseHandle(g_hSocket);
	g_hSocket = INVALID_HANDLE;
}

// -------------
// SQL callbacks
// -------------
public Query_GetOwnInfo(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL error fetching own client info: %s", error);
		return;
	}
	
	// first time we login with this uin!
	if(!SQL_FetchRow(hndl))
	{
		decl String:sQuery[128];
		Format(sQuery, sizeof(sQuery), "INSERT INTO icq_clients (uin) VALUES (\"%s\");", g_sUID);
		SQL_TQuery(g_hDatabase, Query_InsertOwnClient, sQuery);
		return;
	}
	
	g_iOwnDBID = SQL_FetchInt(hndl, 0);
	if(!SQL_IsFieldNull(hndl, 1))
		SQL_FetchString(hndl, 1, g_sOwnNickname, sizeof(g_sOwnNickname));
	if(!SQL_IsFieldNull(hndl, 2))
		SQL_FetchString(hndl, 2, g_sOwnFirstname, sizeof(g_sOwnFirstname));
	if(!SQL_IsFieldNull(hndl, 3))
		SQL_FetchString(hndl, 3, g_sOwnLastname, sizeof(g_sOwnLastname));
	
	if(!g_bConnected)
		ConnectToServer(LOGIN_SERVER, LOGIN_PORT);
}

public Query_InsertOwnClient(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL error inserting own uid: %s", error);
		return;
	}
	
	g_iOwnDBID = SQL_GetInsertId(owner);
	
	if(!g_bConnected)
		ConnectToServer(LOGIN_SERVER, LOGIN_PORT);
}

public Query_CheckBuddyPresence(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:sUIN[32];
	ReadPackString(data, sUIN, sizeof(sUIN));
	
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		CloseHandle(data);
		LogError("SQL error fetching buddy info: %s", error);
		return;
	}
	
	if(!SQL_FetchRow(hndl))
	{
		ResetPack(data);
		
		decl String:sQuery[128];
		Format(sQuery, sizeof(sQuery), "INSERT INTO icq_buddies (client_id, uin) VALUES (%d, \"%s\");", g_iOwnDBID, sUIN);
		SQL_TQuery(g_hDatabase, Query_InsertBuddy, sQuery, data);
		return;
	}
	
	CloseHandle(data);
	
	new iTemp = SQL_FetchInt(hndl, 0);
	
	new Handle:hBuddy;
	if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
	{
		return;
	}
	
	SetTrieValue(hBuddy, "id_in_database", iTemp);
	
	new String:sBuffer[64];
	// Cache info, if not already
	if(!SQL_IsFieldNull(hndl, 1))
	{
		SQL_FetchString(hndl, 1, sBuffer, sizeof(sBuffer));
		if(strlen(sBuffer) > 0)
			SetTrieString(hBuddy, "nickname", sBuffer, false);
	}
	
	if(!SQL_IsFieldNull(hndl, 2))
	{
		SQL_FetchString(hndl, 2, sBuffer, sizeof(sBuffer));
		SetTrieString(hBuddy, "firstname", sBuffer, false);
	}
	
	if(!SQL_IsFieldNull(hndl, 3))
	{
		SQL_FetchString(hndl, 3, sBuffer, sizeof(sBuffer));
		SetTrieString(hBuddy, "lastname", sBuffer, false);
	}
	
	if(!SQL_IsFieldNull(hndl, 4))
	{
		iTemp = SQL_FetchInt(hndl, 4);
		SetTrieValue(hBuddy, "userclass", iTemp);
	}
	
	if(!SQL_IsFieldNull(hndl, 5))
	{
		iTemp = SQL_FetchInt(hndl, 5);
		SetTrieValue(hBuddy, "member_since", iTemp);
	}
	
	// Maybe we got new info from the server in this session? Update the database.
	SaveBuddyInfoInDb(sUIN);
}

public Query_InsertBuddy(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	decl String:sUIN[32];
	ReadPackString(data, sUIN, sizeof(sUIN));
	CloseHandle(data);
	
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL error inserting buddy: %s", error);
		return;
	}
	
	new iTemp = SQL_GetInsertId(owner);
	
	new Handle:hBuddy;
	if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
	{
		return;
	}
	
	SetTrieValue(hBuddy, "id_in_database", iTemp);
	
	SaveBuddyInfoInDb(sUIN);
}

public Query_DoNothing(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE || strlen(error) > 0)
	{
		LogError("SQL error: %s", error);
		return;
	}
}

UpdateBuddyInfo(const String:sUIN[])
{
	decl String:sQuery[256];
	// Save own info?
	if(StrEqual(sUIN, g_sUID))
	{
		Format(sQuery, sizeof(sQuery), "UPDATE icq_clients SET nickname = \"%s\", firstname = \"%s\", lastname = \"%s\" WHERE id = %d;", g_sOwnNickname, g_sOwnFirstname, g_sOwnLastname, g_iOwnDBID);
		SQL_TQuery(g_hDatabase, Query_DoNothing, sQuery);
		return;
	}
	
	new Handle:hBuddy;
	// We don't have that guy saved? That should never happen, as we only call this function after we did so, but well..
	if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
	{
		return;
	}
	
	new iTemp;
	// Already got the id from the database.
	if(GetTrieValue(hBuddy, "id_in_database", iTemp))
	{
		SaveBuddyInfoInDb(sUIN);
		return;
	}
	
	Format(sQuery, sizeof(sQuery),  "SELECT id, nickname, firstname, lastname, userclass, member_since FROM icq_buddies WHERE client_id = %d AND uin = \"%s\";", g_iOwnDBID, sUIN);
	new Handle:hData = CreateDataPack();
	WritePackString(hData, sUIN);
	ResetPack(hData);
	SQL_TQuery(g_hDatabase, Query_CheckBuddyPresence, sQuery, hData);
}

SaveBuddyInfoInDb(const String:sUIN[])
{
	new Handle:hBuddy;
	if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
	{
		return;
	}
	
	new iBuddyID;
	if(!GetTrieValue(hBuddy, "id_in_database", iBuddyID))
	{
		return;
	}
	
	decl String:sQuery[512];
	Format(sQuery, sizeof(sQuery), "UPDATE icq_buddies SET ");
	
	decl String:sBuffer[64], String:sEscape[129];
	new bool:bAddComma = false;
	decl iTemp;
	if(GetTrieString(hBuddy, "nickname", sBuffer, sizeof(sBuffer)))
	{
		SQL_EscapeString(g_hDatabase, sBuffer, sEscape, sizeof(sEscape));
		Format(sQuery, sizeof(sQuery), "%snickname = \"%s\"", sQuery, sEscape);
		bAddComma = true;
	}
	else
	{
		// Request nickname etc, if not already here.
		if(!GetTrieValue(hBuddy, "short_info_requested", iTemp))
		{
			SetTrieValue(hBuddy, "short_info_requested", 1);
			new Handle:hArgs = CreateArray(ByteCountToCells(64));
			PushArrayString(hArgs, "USER_INFO");
			PushArrayString(hArgs, "CLI_SHORTINFO_REQUEST");
			PushArrayString(hArgs, sUIN);
			SendSNAC("CLI_META", hArgs);
		}
	}
	
	if(GetTrieString(hBuddy, "firstname", sBuffer, sizeof(sBuffer)))
	{
		SQL_EscapeString(g_hDatabase, sBuffer, sEscape, sizeof(sEscape));
		Format(sQuery, sizeof(sQuery), "%s%sfirstname = \"%s\"", sQuery, (bAddComma?", ":""), sEscape);
		bAddComma = true;
	}
	
	if(GetTrieString(hBuddy, "lastname", sBuffer, sizeof(sBuffer)))
	{
		SQL_EscapeString(g_hDatabase, sBuffer, sEscape, sizeof(sEscape));
		Format(sQuery, sizeof(sQuery), "%s%slastname = \"%s\"", sQuery, (bAddComma?", ":""), sEscape);
		bAddComma = true;
	}
	
	if(GetTrieValue(hBuddy, "userclass", iTemp))
	{
		Format(sQuery, sizeof(sQuery), "%s%suserclass = %d", sQuery, (bAddComma?", ":""), iTemp);
		bAddComma = true;
	}
	
	if(GetTrieValue(hBuddy, "member_since", iTemp))
	{
		Format(sQuery, sizeof(sQuery), "%s%smember_since = %d", sQuery, (bAddComma?", ":""), iTemp);
		bAddComma = true;
	}
	
	if(bAddComma)
	{
		Format(sQuery, sizeof(sQuery), "%s WHERE id = %d;", sQuery, iBuddyID);
		SQL_TQuery(g_hDatabase, Query_DoNothing, sQuery);
	}
}

// -------------
// OSCAR protocol stuff
// -------------
ProcessPackage(const String:receiveData[], dataSize)
{
	if(dataSize < 6)
	{
		PrintToServer("Received invalid FLAP packet..");
		return -1;
	}
	
	new FLAP_Channel:iChannel, iDataLength;
	if(!ParseFLAP(receiveData, iChannel, iDataLength))
	{
		PrintToServer("Failed parsing the FLAP header.");
		for(new i=0;i<dataSize;i++)
		{
			PrintToServer("%02x (%d): %08b", _:receiveData[i]&0xff, _:receiveData[i]&0xff, _:receiveData[i]&0xff);
		}
		return -1;
	}
	
	//PrintToServer("FLAP Channel: %d, Length: %d", iChannel, iDataLength);
	
	new String:sData[iDataLength+1];
	//Format(sData, iLength+1, "%s", receiveData[6]);
	for(new i=0;i<iDataLength;i++)
	{
		//if(_:receiveData[i+6] > 0)
		sData[i] = receiveData[i+6]&0xff;
		//PrintToServer("%d (%d): %08b", i, _:receiveData[i+6]&0xff, _:receiveData[i+6]&0xff);
		//Format(sData, iLength+1, "%s%d", sData, _:receiveData[i+6]&0xff);
	}
	sData[iDataLength] = '\0';
	/*for(new i=0;i<iLength;i++)
	{
		PrintToServer("%02x (%d): %08b", _:sData[i]&0xff, _:sData[i]&0xff, _:sData[i]&0xff);
	}*/
	
	if(!g_bConnected)
	{
		decl String:sBuffer[128];
		new iLength = Int2Bytes(2, 0x01, sBuffer, sizeof(sBuffer));
		
		// Not connected yet? Waiting for the server to send the hello package.
		if((iChannel != FLAP_LOGIN || strncmp(sData, sBuffer, iLength)))
		{
			PrintToServer("Connection failed. SRV_HELLO not received.");
			DisconnectFromServer();
			return iDataLength+6;
		}
		else
			g_bConnected = true;
	}
	
	// Not logged in?
	if(g_iLoginState != Login_LoggedIn)
	{
		if(!g_bConnected)
		{
			PrintToServer("Can't login, if socket is not connected.");
			return iDataLength+6;
		}
		
		g_iOutgoingSequence = GetRandomInt(0x0001, 0x8000);
		
		switch(g_iLoginState)
		{
			// Send the login package
			case Login_NotLoggedIn:
			{
				PrintToServer("Logging in..");
#if defined USE_MD5_LOGIN
				SendSNAC("CLI_AUTH_REQUEST");
#else
				SendSNAC("CLI_LOGIN");
#endif
				g_iLoginState = Login_LoginSent;
			}
			case Login_LoginSent:
			{
				new Handle:hTLV = CreateArray();
				
				if(iChannel == FLAP_LOGOUT)
				{
					ParseTLV(hTLV, sData, iDataLength);
					
					/*new iSize = GetArraySize(hTLV);
					new Handle:hPart, String:sBuffer[64], iTemp, iType;
					PrintToServer("TLV size: %d", iSize);
					for(new i=0;i<iSize;i++)
					{
						hPart = GetArrayCell(hTLV, i);
						iType = GetArrayCell(hPart, 0);
						GetTLVString(hTLV, iType, sBuffer, sizeof(sBuffer), iTemp);
						PrintToServer("%02x: %s (%d)", iType, sBuffer, iTemp);
					}*/
					
					decl String:sServer[64], String:sCookie[512];
					new iLength;
					if(GetTLVString(hTLV, 0x05, sServer, sizeof(sServer), iLength)
					&& GetTLVString(hTLV, 0x06, sCookie, sizeof(sCookie), iLength))
					{
						CloseTLVArray(hTLV);
						
						// Migrate to the other server!
						MigrateToServer(sServer, sCookie, iLength);
					}
					// Login failed?
					else
					{
						new String:sError[256];
						GetTLVString(hTLV, 0x08, sError, sizeof(sError), iLength);
						
						// See AUTHERROR_ defines
						GetAuthErrorString(Bytes2Int(sError, 2), sError, sizeof(sError));
						PrintToServer("Authorization failed: %s", sError);
						DisconnectFromServer();
					}
				}
			}
			case Login_Migrating:
			{
				SendSNAC("CLI_COOKIE");
				
				g_iLoginState = Login_LoggedIn;
			}
		}
		
		return iDataLength+6;
	}
	
	if(iChannel == FLAP_SNAC)
	{
		new iFamily = Bytes2Int(sData, 2);
		new iSubFamily = Bytes2Int(sData, 2, 2);
		new iFlags = Bytes2Int(sData, 2, 4);
		new iReqID = Bytes2Int(sData, 4, 6);
		
		decl String:sSubData[iDataLength-10];
		for(new i=0;i<iDataLength-10;i++)
			sSubData[i] = sData[i+10];
		
		//PrintToServer("Incoming SNAC: family: %x, subfamily: %x, flags: %x, reqid: %x", iFamily, iSubFamily, iFlags, iReqID);
		
		// Generic service controls (01)
		if(iSubFamily == 0x01) // SRV_ERROR
		{
			new iErrorCode = Bytes2Int(sSubData, 2);
			PrintToServer("SRV_ERROR: family: %x, err.code: %x", iFamily, iErrorCode);
		}
		else if(iFamily == 0x01 && iSubFamily == 0x03) // SRV_FAMILIES
		{
			PrintToServer("SRV_FAMILIES");
			
			PrintToServer("Supported families: %d", (iDataLength-10)/2);
			new iFamilyPair[2];
			for(new i=0;i<(iDataLength-10)/2;i++)
			{
				iFamilyPair[0] = Bytes2Int(sSubData, 2, i*2);
				//PrintToServer("Family: %04x", iFamilyPair[0]);
				PushArrayArray(g_hSupportedFamilies, iFamilyPair, 2);
			}
			
			SendSNAC("CLI_FAMILIES_VERSIONS");
			SendSNAC("CLI_RATES_REQUEST");
		}
		else if(iFamily == 0x01 && iSubFamily == 0x07) // SRV_RATE_LIMIT_INFO
		{
			PrintToServer("SRV_RATE_LIMIT_INFO");
			
			new iNumRateClasses = Bytes2Int(sSubData, 2);
			PrintToServer("Num rate classes: %d", iNumRateClasses);
			new iRateClass[Rate_Class];
			for(new i=0; i<iNumRateClasses; i++)
			{
				iRateClass[Class_ID] = Bytes2Int(sSubData, 2, i*35+2);
				iRateClass[Window_Size] = Bytes2Int(sSubData, 4, i*35+4);
				iRateClass[Clear_Level] = Bytes2Int(sSubData, 4, i*35+8);
				iRateClass[Alert_Level] = Bytes2Int(sSubData, 4, i*35+12);
				iRateClass[Limit_Level] = Bytes2Int(sSubData, 4, i*35+16);
				iRateClass[Disconnect_Level] = Bytes2Int(sSubData, 4, i*35+20);
				iRateClass[Current_Level] = Bytes2Int(sSubData, 4, i*35+24);
				iRateClass[Max_Level] = Bytes2Int(sSubData, 4, i*35+28);
				iRateClass[Last_Time] = Bytes2Int(sSubData, 4, i*35+32);
				iRateClass[Current_State] = Bytes2Int(sSubData, 1, i*35+36);
				
				PushArrayArray(g_hRateClasses, iRateClass, 10);
				
				/*PrintToServer("%d: classid: %04x, windowsize: %08x, clearlevel: %08x, alertlevel: %08x, limitlevel: %08x, disconnectlevel: %08x, currentlevel: %08x, maxlevel: %08x, lasttime: %08x, currentstate: %x", 
				i, iRateClass[Class_ID], iRateClass[Window_Size], iRateClass[Clear_Level], iRateClass[Alert_Level],
				iRateClass[Limit_Level], iRateClass[Disconnect_Level], iRateClass[Current_Level], iRateClass[Max_Level],
				iRateClass[Last_Time], iRateClass[Current_State]);*/
			}
			
			new Handle:hRateGroup, iGroupPair[2], iNumPairsInGroup;
			for(new i=iNumRateClasses*35+2; i<iDataLength-10;)
			{
				hRateGroup = CreateArray(2);
				iGroupPair[0] = Bytes2Int(sSubData, 2, i); // rate group ID
				i+=2;
				iNumPairsInGroup = iGroupPair[1] = Bytes2Int(sSubData, 2, i); // num pairs in group
				i+=2;
				
				// First pair is always the groupid
				PushArrayArray(hRateGroup, iGroupPair, 2);
				
				PrintToServer("Rate group ID: %02x. Num of pairs in group: %d", iGroupPair[0], iGroupPair[1]);
				for(new g=0;g<iNumPairsInGroup;g++)
				{
					iGroupPair[0] = Bytes2Int(sSubData, 2, i); // family
					i+=2;
					iGroupPair[1] = Bytes2Int(sSubData, 2, i); // subtype
					i+=2;
					
					//PrintToServer("%d: Family: %02x, subtype: %02x", g, iGroupPair[0], iGroupPair[1]);
					PushArrayArray(hRateGroup, iGroupPair, 2);
				}
				//i += iNumPairsInGroup*4;
				PushArrayCell(g_hRateGroups, hRateGroup);
			}
			
			// ACK the rategroups
			SendSNAC("CLI_RATES_ACK");
			
			
			SendSNAC("CLI_REQ_SELFINFO");
			
			// Client ask server for SSI service limitations
			SendSNAC("CLI_SSI_RIGHTS_REQUEST");
			SendSNAC("CLI_SSI_REQUEST");
			
			// Client ask server location service limitations
			SendSNAC("CLI_LOCATION_RIGHTS_REQ"); 
			
			// Request rights information for buddy service.
			SendSNAC("CLI_BUDDYLIST_RIGHTS_REQ");
			
			SendSNAC("CLI_ICBM_PARAM_REQ");
			
			// Client request buddylist service parameters and limitations
			SendSNAC("CLI_PRIVACY_RIGHTS_REQ");
			
			// tell the server we don't want direct connections
			new Handle:hArgs = CreateArray(ByteCountToCells(64));
			PushArrayString(hArgs, "USER_INFO");
			PushArrayString(hArgs, "SET_PERMS");
			SendSNAC("CLI_META", hArgs);
			
			// Get the offline messages!
			hArgs = CreateArray(ByteCountToCells(64));
			PushArrayString(hArgs, "CLI_OFFLINE_MESSAGE_REQ");
			SendSNAC("CLI_META", hArgs);
		}
		else if(iFamily == 0x01 && iSubFamily == 0x0A) // SRV_RATE_LIMIT_WARN
		{
			PrintToServer("SRV_RATE_LIMIT_WARN");
			
			new iMsgCode = Bytes2Int(sSubData, 2);
			PrintToServer("MessageCode: %04x", iMsgCode);
			
			new iRateClassID = Bytes2Int(sSubData, 2, 2);
			
			new iRateClass[Rate_Class];
			new iSize = GetArraySize(g_hRateClasses);
			for(new i=0;i<iSize;i++)
			{
				GetArrayArray(g_hRateClasses, i, iRateClass, 10);
				if(iRateClass[Class_ID] == iRateClassID)
				{
					iRateClass[Class_ID] = iRateClassID;
					iRateClass[Window_Size] = Bytes2Int(sSubData, 4, 4);
					iRateClass[Clear_Level] = Bytes2Int(sSubData, 4, 8);
					iRateClass[Alert_Level] = Bytes2Int(sSubData, 4, 12);
					iRateClass[Limit_Level] = Bytes2Int(sSubData, 4, 16);
					iRateClass[Disconnect_Level] = Bytes2Int(sSubData, 4, 20);
					iRateClass[Current_Level] = Bytes2Int(sSubData, 4, 24);
					iRateClass[Max_Level] = Bytes2Int(sSubData, 4, 28);
					iRateClass[Last_Time] = Bytes2Int(sSubData, 4, 32);
					iRateClass[Current_State] = Bytes2Int(sSubData, 1, 36);
					
					SetArrayArray(g_hRateClasses, i, iRateClass, 10);
					
					break;
				}
			}
		}
		else if(iFamily == 0x01 && iSubFamily == 0x0B) // SRV_PAUSE
		{
			PrintToServer("SRV_PAUSE");
			
			SendSNAC("CLI_PAUSE_ACK");
			g_bPause = true;
		}
		else if(iFamily == 0x01 && iSubFamily == 0x0D) // SRV_RESUME
		{
			PrintToServer("SRV_RESUME");
			g_bPause = false;
		}
		else if(iFamily == 0x01 && iSubFamily == 0x0F) // SRV_ONLINE_INFO
		{
			PrintToServer("SRV_ONLINE_INFO");
			
			new iOffset = 1;
			new String:sUIN[sSubData[0]+1];
			Format(sUIN, sSubData[0]+1, "%s", sSubData[iOffset]);
			iOffset += sSubData[0];
			//new iWarnLevel = Bytes2Int(sSubData, 2, iOffset); // unused in icq
			iOffset += 2;
			//new iTLVnum = Bytes2Int(sSubData, 2, iOffset);
			iOffset += 2;
			
			// Get info array of that user
			new Handle:hBuddy;
			if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
			{
				hBuddy = CreateTrie();
				SetTrieValue(g_hContactList, sUIN, hBuddy);
				PushArrayString(g_hBuddyUINs, sUIN);
			}
			
			new String:sNick[64];
			if(!StrEqual(sUIN, g_sUID))
			{
				GetTrieString(hBuddy, "nickname", sNick, sizeof(sNick));
				PrintToServer("Buddy: %s (%s)", sNick, sUIN);
			}
			else
			{
				PrintToServer("Myself: %s (%s)", g_sOwnNickname, g_sUID);
			}
			
			// This buddy is online!
			SetTrieValue(hBuddy, "offline", false);
			
			new Handle:hTLV = CreateArray();
			ParseTLV(hTLV, sSubData[iOffset], iDataLength-10-iOffset);
			
			decl String:sBuffer[64], iLength;
			if(GetTLVString(hTLV, 0x01, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "userclass", Bytes2Int(sBuffer, 2));
			if(GetTLVString(hTLV, 0x02, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "create_time", Bytes2Int(sBuffer, 4));
			if(GetTLVString(hTLV, 0x03, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "signon_time", Bytes2Int(sBuffer, 4));
			if(GetTLVString(hTLV, 0x04, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "idle_time", Bytes2Int(sBuffer, 2));
			if(GetTLVString(hTLV, 0x05, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "acc_create_time", Bytes2Int(sBuffer, 4));
			if(GetTLVString(hTLV, 0x06, sBuffer, sizeof(sBuffer), iLength))
			{
				SetTrieValue(hBuddy, "status_flags", Bytes2Int(sBuffer, 2));
				SetTrieValue(hBuddy, "user_status", Bytes2Int(sBuffer, 2, 2));
			}
			if(GetTLVString(hTLV, 0x0A, sBuffer, sizeof(sBuffer), iLength))
			{
				decl String:sIP[17];
				Format(sIP, sizeof(sIP), "%d.%d.%d.%d", Bytes2Int(sBuffer, 1), Bytes2Int(sBuffer, 1, 1), Bytes2Int(sBuffer, 1, 2), Bytes2Int(sBuffer, 1, 3));
				SetTrieString(hBuddy, "external_ip", sIP);
				PrintToServer("external_ip: %s", sIP);
			}
			if(GetTLVString(hTLV, 0x0C, sBuffer, sizeof(sBuffer), iLength))
				SetTrieString(hBuddy, "direct_connection_info", sBuffer);
			if(GetTLVString(hTLV, 0x0D, sBuffer, sizeof(sBuffer), iLength))
				SetTrieString(hBuddy, "capabilities", sBuffer);
			if(GetTLVString(hTLV, 0x0F, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "online_time", Bytes2Int(sBuffer, 4));
			
			CloseTLVArray(hTLV);
			
			// Update/insert the info in the database..
			UpdateBuddyInfo(sUIN);
			
			if(StrEqual(sUIN, g_sUID))
			{
				if(GetTrieValue(hBuddy, "userclass", iLength))
					PrintToServer("userclass: %02x", iLength);
				
				if(GetTrieValue(hBuddy, "create_time", iLength))
					PrintToServer("create_time: %d", iLength);
				
				if(GetTrieValue(hBuddy, "signon_time", iLength))
					PrintToServer("signon_time: %d", iLength);
				
				if(GetTrieValue(hBuddy, "idle_time", iLength))
					PrintToServer("idle_time: %d", iLength);
				
				if(GetTrieValue(hBuddy, "acc_create_time", iLength))
					PrintToServer("acc_create_time: %d", iLength);
				
				if(GetTrieValue(hBuddy, "status_flags", iLength))
					PrintToServer("status_flags: %02x", iLength);
				
				if(GetTrieValue(hBuddy, "user_status", iLength))
					PrintToServer("user_status: %02x", iLength);
				
				if(GetTrieValue(hBuddy, "online_time", iLength))
					PrintToServer("online_time: %d", iLength);
			}
		}
		else if(iFamily == 0x01 && iSubFamily == 0x12) // SRV_MIGRATION
		{
			PrintToServer("SRV_MIGRATION");
			new Handle:hTLV = CreateArray();
			ParseTLV(hTLV, sSubData, iDataLength-10);
			
			/*new iSize = GetArraySize(hTLV);
			new Handle:hPart;
			PrintToServer("TLV size: %d", iSize);
			for(new i=0;i<iSize;i++)
			{
				hPart = GetArrayCell(hTLV, i);
				PrintToServer("%02x", GetArrayCell(hPart, 0));
			}*/
			
			// No longer pause sending SNACs
			g_bPause = false;
			
			decl String:sServer[64], String:sCookie[512], iCookieLength;
			if(GetTLVString(hTLV, 0x05, sServer, sizeof(sServer), iCookieLength)
			&& GetTLVString(hTLV, 0x06, sCookie, sizeof(sCookie), iCookieLength))
			{
				CloseTLVArray(hTLV);
				
				// Migrate to the other server!
				MigrateToServer(sServer, sCookie, iCookieLength);
			}
		}
		else if(iFamily == 0x01 && iSubFamily == 0x13) // SRV_MOTD
		{
			PrintToServer("SRV_MOTD");
			
			new iMOTDType = Bytes2Int(sSubData, 2);
			
			new Handle:hTLV = CreateArray();
			ParseTLV(hTLV, sSubData[2], iDataLength-12);
			
			new iMOTDLength;
			decl String:sMOTD[64];
			GetTLVString(hTLV, 0x0B, sMOTD, sizeof(sMOTD), iMOTDLength);
			PrintToServer("MOTD (type: %04x): %s", iMOTDType, sMOTD);
			
			CloseTLVArray(hTLV);
		}
		else if(iFamily == 0x01 && iSubFamily == 0x15) // SRV_WELL_KNOWN_URLS
		{
			PrintToServer("SRV_WELL_KNOWN_URLS");
		}
		else if(iFamily == 0x01 && iSubFamily == 0x18) // SRV_FAMILIES_VERSIONS
		{
			PrintToServer("SRV_FAMILIES_VERSIONS");
			
			PrintToServer("Supported families: %d", (iDataLength-10)/4);
			new iFamilyPair[2];
			for(new i=0;i<(iDataLength-10)/4;i++)
			{
				iFamilyPair[0] = Bytes2Int(sSubData, 2, i*4);
				iFamilyPair[1] = Bytes2Int(sSubData, 2, i*4+2);
				//PrintToServer("Family: %04x, version: %04x", iFamilyPair[0], iFamilyPair[1]);
				PushArrayArray(g_hSupportedFamilies, iFamilyPair, 2);
			}
			
			
		}
		else if(iFamily == 0x01 && iSubFamily == 0x21) // SRV_EXT_STATUS
		{
			PrintToServer("SRV_EXT_STATUS");
			
			new iExtendedStatusType = Bytes2Int(sSubData, 2);
			new iExtendedStatusFlags = Bytes2Int(sSubData, 1, 2);
			new iExtendedStatusLength = Bytes2Int(sSubData, 1, 3);
			new String:sStatusData[iExtendedStatusLength*2+1];
			for(new i=0;i<iExtendedStatusLength;i++)
			{
				Format(sStatusData, iExtendedStatusLength*2+1, "%s%02x", sStatusData, Bytes2Int(sSubData, 1, 4+i));
			}
			
			PrintToServer("statustype: %04x, flags: %02x, length: %d, data: %s", iExtendedStatusType, iExtendedStatusFlags, iExtendedStatusLength, sStatusData);
		}
		// END - Generic service controls (01)
		
		// Location services (02)
		// Server replies with this SNAC to SNAC(02,02) - client service parameters request. 
		else if(iFamily == 0x02 && iSubFamily == 0x03) // SRV_LOCATION_RIGHTS_REPLY
		{
			PrintToServer("SRV_LOCATION_RIGHTS_REPLY");
			
			new Handle:hTLV = CreateArray();
			ParseTLV(hTLV, sSubData, iDataLength-10);
			
			new iMaxProfileLength, iMaxCapabilities;
			
			decl String:sBuffer[64], iLength;
			if(GetTLVString(hTLV, 0x01, sBuffer, sizeof(sBuffer), iLength))
			{
				iMaxProfileLength = Bytes2Int(sBuffer, 2);
			}
			if(GetTLVString(hTLV, 0x02, sBuffer, sizeof(sBuffer), iLength))
			{
				iMaxCapabilities = Bytes2Int(sBuffer, 2);
			}
			CloseTLVArray(hTLV);
			
			PrintToServer("Max profile length: %d, max capabilities: %d", iMaxProfileLength, iMaxCapabilities);
			
			//SendSNAC("CLI_SET_LOCATION_INFO");
		}
		else if(iFamily == 0x02 && iSubFamily == 0x06) // SRV_USER_ONLINE_INFO
		{
			PrintToServer("SRV_USER_ONLINE_INFO");
		}
		// END - Location services (02)
		
		// Buddy List management service (03)
		else if(iFamily == 0x03 && iSubFamily == 0x03) // SRV_REPLYBUDDY
		{
			PrintToServer("SRV_REPLYBUDDY");
			new Handle:hTLV = CreateArray();
			ParseTLV(hTLV, sSubData, iDataLength-10);
			
			decl String:sBuffer[64], iLength;
			if(GetTLVString(hTLV, 0x01, sBuffer, sizeof(sBuffer), iLength))
				PrintToServer("Max UINs in buddy list: %d", Bytes2Int(sBuffer, 2));
			if(GetTLVString(hTLV, 0x02, sBuffer, sizeof(sBuffer), iLength))
				PrintToServer("Max people with your UIN in their buddy list (watcher): %d", Bytes2Int(sBuffer, 2));
			if(GetTLVString(hTLV, 0x03, sBuffer, sizeof(sBuffer), iLength))
				PrintToServer("Max online notifications: %d", Bytes2Int(sBuffer, 2));
		}
		else if(iFamily == 0x03 && iSubFamily == 0x0A) // SRV_NOTIFICATION_REJECTED
		{
			PrintToServer("SRV_NOTIFICATION_REJECTED");
			new iOffset = 0;
			while(iOffset < (iDataLength-10))
			{
				decl String:sRejectedUIN[sSubData[iOffset]+1];
				Format(sRejectedUIN, sSubData[iOffset]+1, sSubData[iOffset+1]);
				iOffset += sSubData[iOffset]+1;
				PrintToServer("UIN: %s", sRejectedUIN);
			}
		}
		else if(iFamily == 0x03 && iSubFamily == 0x0B) // SRV_USER_ONLINE
		{
			PrintToServer("SRV_USER_ONLINE");
			new iOffset = 1;
			new String:sUIN[sSubData[0]+1];
			Format(sUIN, sSubData[0]+1, "%s", sSubData[iOffset]);
			iOffset += sSubData[0];
			//new iWarnLevel = Bytes2Int(sSubData, 2, iOffset); // unused in icq
			iOffset += 2;
			//new iTLVnum = Bytes2Int(sSubData, 2, iOffset);
			iOffset += 2;
			
			// Get info array of that user
			new Handle:hBuddy;
			if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
			{
				hBuddy = CreateTrie();
				SetTrieValue(g_hContactList, sUIN, hBuddy);
				PushArrayString(g_hBuddyUINs, sUIN);
			}
			
			new String:sNick[64];
			GetTrieString(hBuddy, "nickname", sNick, sizeof(sNick));
			PrintToServer("Buddy: %s (%s)", sNick, sUIN);
			
			// This buddy is online!
			new bool:bOffline;
			if(!GetTrieValue(hBuddy, "offline", bOffline) || bOffline)
				PrintToServer("%s just went online.", sNick);
			SetTrieValue(hBuddy, "offline", false);
			
			new Handle:hTLV = CreateArray();
			ParseTLV(hTLV, sSubData[iOffset], iDataLength-10-iOffset);
			
			decl String:sBuffer[64], iLength;
			if(GetTLVString(hTLV, 0x01, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "userclass", Bytes2Int(sBuffer, 2));
			if(GetTLVString(hTLV, 0x02, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "create_time", Bytes2Int(sBuffer, 4));
			if(GetTLVString(hTLV, 0x03, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "signon_time", Bytes2Int(sBuffer, 4));
			if(GetTLVString(hTLV, 0x04, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "idle_time", Bytes2Int(sBuffer, 2));
			if(GetTLVString(hTLV, 0x05, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "acc_create_time", Bytes2Int(sBuffer, 4));
			if(GetTLVString(hTLV, 0x06, sBuffer, sizeof(sBuffer), iLength))
			{
				new iUserStatus = Bytes2Int(sBuffer, 2, 2);
				new iCurrentUserStatus;
				if(GetTrieValue(hBuddy, "user_status", iCurrentUserStatus)
				&& iCurrentUserStatus != iUserStatus)
				{
					PrintToServer("%s changed his status from %04x to %04x.", sNick, iCurrentUserStatus, iUserStatus);
				}
				
				SetTrieValue(hBuddy, "status_flags", Bytes2Int(sBuffer, 2));
				SetTrieValue(hBuddy, "user_status", iUserStatus);
			}
			if(GetTLVString(hTLV, 0x0A, sBuffer, sizeof(sBuffer), iLength))
			{
				decl String:sIP[17];
				Format(sIP, sizeof(sIP), "%d.%d.%d.%d", Bytes2Int(sBuffer, 1), Bytes2Int(sBuffer, 1, 1), Bytes2Int(sBuffer, 1, 2), Bytes2Int(sBuffer, 1, 3));
				SetTrieString(hBuddy, "external_ip", sIP);
				//PrintToServer("external_ip: %s", sIP);
			}
			//if(GetTLVString(hTLV, 0x0C, sBuffer, sizeof(sBuffer), iLength))
			//	SetTrieString(hBuddy, "direct_connection_info", sBuffer);
			if(GetTLVString(hTLV, 0x0D, sBuffer, sizeof(sBuffer), iLength))
				SetTrieString(hBuddy, "capabilities", sBuffer);
			if(GetTLVString(hTLV, 0x0F, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "online_time", Bytes2Int(sBuffer, 4));
			
			// Update/insert the info in the database..
			UpdateBuddyInfo(sUIN);
			
			/*if(GetTrieValue(hBuddy, "userclass", iLength))
				PrintToServer("userclass: %d", iLength);
			
			if(GetTrieValue(hBuddy, "create_time", iLength))
				PrintToServer("create_time: %d", iLength);
			
			if(GetTrieValue(hBuddy, "signon_time", iLength))
				PrintToServer("signon_time: %d", iLength);
			
			if(GetTrieValue(hBuddy, "idle_time", iLength))
				PrintToServer("idle_time: %d", iLength);
			
			if(GetTrieValue(hBuddy, "acc_create_time", iLength))
				PrintToServer("acc_create_time: %d", iLength);
			
			if(GetTrieValue(hBuddy, "status_flags", iLength))
				PrintToServer("status_flags: %d", iLength);
			
			if(GetTrieValue(hBuddy, "user_status", iLength))
				PrintToServer("user_status: %d", iLength);
			
			if(GetTrieValue(hBuddy, "online_time", iLength))
				PrintToServer("online_time: %d", iLength);*/
			
			/*new iSize = GetArraySize(hTLV);
			new Handle:hPart, String:sBuffer[64], iTemp, iType;
			PrintToServer("TLV size: %d", iSize);
			for(new i=0;i<iSize;i++)
			{
				hPart = GetArrayCell(hTLV, i);
				iType = GetArrayCell(hPart, 0);
				GetTLVString(hTLV, iType, sBuffer, sizeof(sBuffer), iTemp);
				PrintToServer("%02x: %s (%d)", iType, sBuffer, iTemp);
			}*/
			CloseTLVArray(hTLV);
		}
		else if(iFamily == 0x03 && iSubFamily == 0x0C) // SRV_USER_OFFLINE
		{
			PrintToServer("SRV_USER_OFFLINE");
			new iOffset = 1;
			new String:sUIN[sSubData[0]+1];
			Format(sUIN, sSubData[0]+1, "%s", sSubData[iOffset]);
			iOffset += sSubData[0];
			//new iWarnLevel = Bytes2Int(sSubData, 2, iOffset); // unused in icq
			iOffset += 2;
			//new iTLVnum = Bytes2Int(sSubData, 2, iOffset);
			iOffset += 2;
			
			// Get info array of that user
			new Handle:hBuddy;
			if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
			{
				hBuddy = CreateTrie();
				SetTrieValue(g_hContactList, sUIN, hBuddy);
				PushArrayString(g_hBuddyUINs, sUIN);
			}
			
			new String:sNick[64];
			GetTrieString(hBuddy, "nickname", sNick, sizeof(sNick));
			PrintToServer("Buddy: %s (%s)", sNick, sUIN);
			
			// This buddy is offline now.
			SetTrieValue(hBuddy, "offline", true);
			
			// Update/insert the info in the database..
			UpdateBuddyInfo(sUIN);
		}
		// END - Buddy List management service (03)
		
		// ICBM service (04)
		else if(iFamily == 0x04 && iSubFamily == 0x01) // SRV_ICBM_ERROR
		{
			PrintToServer("SRV_ICBM_ERROR");
			// 0x04 - you are trying to send message to offline client ("")
			// 0x09 - message not supported by client
			// 0x0E - your message is invalid (incorrectly formated)
			// 0x10 - receiver/sender blocked
			PrintToServer("err.code: %04x", Bytes2Int(sSubData, 2));
		}
		else if(iFamily == 0x04 && iSubFamily == 0x05) // SRV_ICBM_PARAMS
		{
			PrintToServer("SRV_ICBM_PARAMS");
			
			new iMsgChannel = Bytes2Int(sSubData, 2);
			new iMessageFlags = Bytes2Int(sSubData, 4, 2);
			new iMaxMessageSNACSize = Bytes2Int(sSubData, 2, 6);
			new iMaxSenderWarningLevel = Bytes2Int(sSubData, 2, 8);
			new iMaxReceiverWarningLevel = Bytes2Int(sSubData, 2, 10);
			new iMinimumMsgInterval = Bytes2Int(sSubData, 2, 12);
			new iUnknown = Bytes2Int(sSubData, 2, 14);
			
			PrintToServer("channel: %04x, msgflags: %08x, max message snac size: %d, max sender warning level: %d, max receiver warning level: %d, minimum message interval (msec): %d, unknown: %04x", 
			iMsgChannel, iMessageFlags, iMaxMessageSNACSize, iMaxSenderWarningLevel, iMaxReceiverWarningLevel, iMinimumMsgInterval, iUnknown);
		}
		else if(iFamily == 0x04 && iSubFamily == 0x07) // SRV_CLIENT_ICBM
		{
			PrintToServer("SRV_CLIENT_ICBM");
			
			new iOffset = 0;
			iOffset += 8; // msg cookie
			
			new iMsgChannel = Bytes2Int(sSubData, 2, iOffset);
			iOffset += 2;
			
			decl String:sUIN[sSubData[10]+1];
			Format(sUIN, sSubData[10]+1, "%s", sSubData[11]);
			iOffset += sSubData[10]+1;
			
			//new iWarningLevel = Bytes2Int(sSubData, 2, iOffset);
			iOffset += 2;
			
			//new iNumTLV = Bytes2Int(sSubData, 2, iOffset);
			iOffset += 2;
			
			// We got some new info about this buddy here either..
			new Handle:hBuddy;
			if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
			{
				hBuddy = CreateTrie();
				SetTrieValue(g_hContactList, sUIN, hBuddy);
				PushArrayString(g_hBuddyUINs, sUIN);
			}
			
			// This buddy is online!
			SetTrieValue(hBuddy, "offline", false);
			
			new Handle:hTLV = CreateArray();
			ParseTLV(hTLV, sSubData[iOffset], iDataLength-10-iOffset);
			
			decl String:sBuffer[512], iLength;
			if(GetTLVString(hTLV, 0x01, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "userclass", Bytes2Int(sBuffer, 2));
			if(GetTLVString(hTLV, 0x03, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "acc_create_time", Bytes2Int(sBuffer, 4));
			if(GetTLVString(hTLV, 0x06, sBuffer, sizeof(sBuffer), iLength))
			{
				SetTrieValue(hBuddy, "status_flags", Bytes2Int(sBuffer, 2));
				SetTrieValue(hBuddy, "user_status", Bytes2Int(sBuffer, 2, 2));
			}
			if(GetTLVString(hTLV, 0x0F, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "idle_time", Bytes2Int(sBuffer, 4));
			if(GetTLVString(hTLV, 0x05, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(hBuddy, "member_since", Bytes2Int(sBuffer, 4));
			
			// Update/insert the info in the database..
			UpdateBuddyInfo(sUIN);
			
			new bool:bAutoResponse = GetTLVString(hTLV, 0x04, sBuffer, sizeof(sBuffer), iLength);
			
			new String:sNick[64];
			GetTrieString(hBuddy, "nickname", sNick, sizeof(sNick));
			
			PrintToServer("New message from %s (%s). (type: %04x, autoresponse: %d)", sNick, sUIN, iMsgChannel, bAutoResponse);
			strcopy(g_sLastMessageFrom, sizeof(g_sLastMessageFrom), sUIN);
			
			switch(iMsgChannel)
			{
				// Channel 1 message format (plain-text messages)
				case 1:
				{
					if(GetTLVString(hTLV, 0x02, sBuffer, sizeof(sBuffer), iLength))
					{
						
						CloseTLVArray(hTLV);
						hTLV = CreateArray();
						
						ParseTLV(hTLV, sBuffer, iLength);
						
						if(GetTLVString(hTLV, 0x0101, sBuffer, sizeof(sBuffer), iLength))
						{
							new iCharsetNumber = Bytes2Int(sBuffer, 2);
							new iCharsetSubset = Bytes2Int(sBuffer, 2, 2);
							
							if(iCharsetNumber == 0x0002 && iCharsetSubset == 0x002)
							{
								new iShorter = 0;
								for(new i=4;i<iLength;i++)
								{
									if(sBuffer[i]&0xff == 0x00)
									{
										sBuffer[i] = sBuffer[i+1];
										for(new y=i+1;y<iLength;y++)
										{
											sBuffer[y] = sBuffer[y+1];
										}
										
										iShorter++;
									}
								}
								iLength -= iShorter;
							}
							
							PrintToServer("Message content (charset: %x, subset: %x): %s", iCharsetNumber, iCharsetSubset, sBuffer[4]);
							
							TrimString(sBuffer[4]);
							
							if(strlen(sBuffer[4]) == 0)
							{
								for(new i=4;i<iLength;i++)
								{
									PrintToServer("%02x (%d): %08b", _:sBuffer[i]&0xff, _:sBuffer[i]&0xff, _:sBuffer[i]&0xff);
								}
							}
							
							// Save message to database
							new iDBID;
							if(GetTrieValue(hBuddy, "db_in_database", iDBID))
							{
								decl String:sQuery[1300], String:sEscapedMessage[1026];
								SQL_EscapeString(g_hDatabase, sBuffer[4], sEscapedMessage, sizeof(sEscapedMessage));
								Format(sQuery, sizeof(sQuery), "INSERT INTO icq_messages (buddy_id, message, sent, read) VALUES (%d, \"%s\", %d, 1);", iDBID, sEscapedMessage, GetTime());
								SQL_TQuery(g_hDatabase, Query_DoNothing, sQuery);
							}
							
							// Sample handling of messages
							if(StrContains(sBuffer[4], "RCON ", false) == 0)
							{
								decl String:sResult[512];
								ServerCommandEx(sResult, sizeof(sResult), sBuffer[9]);
								new Handle:hArgs = CreateArray(ByteCountToCells(512));
								PushArrayString(hArgs, sUIN);
								PushArrayString(hArgs, sResult);
								SendSNAC("CLI_SEND_ICBM_CH1", hArgs);
							}
						}
						else
							PrintToServer("ERROR: Unable to read message...");
					}
				}
				// Channel 2 message format (rtf messages, rendezvous)
				case 2:
				{
					if(GetTLVString(hTLV, 0x05, sBuffer, sizeof(sBuffer), iLength))
					{
						/*for(new i=0;i<iLength;i++)
						{
							PrintToServer("%02x (%d): %08b", _:sBuffer[i]&0xff, _:sBuffer[i]&0xff, _:sBuffer[i]&0xff);
						}*/
						new iSubOffset = 0;
						new iMessageType = Bytes2Int(sBuffer, 2, iSubOffset);
						iSubOffset += 2;
						// 8 bytes cookie
						new iCookie[8];
						for(new i=0;i<8;i++)
						{
							iCookie[i] = _:sBuffer[iSubOffset+i]&0xff;
						}
						iSubOffset += 8;
						
						// 16 bytes capability
						new String:sCapability[33];
						for(new i=0;i<16;i++)
						{
							Format(sCapability, sizeof(sCapability), "%s%02x", sCapability, _:sBuffer[iSubOffset+i]&0xff);
						}
						iSubOffset += 16;
						
						PrintToServer("messagetype: %04x, Capability: %s", iMessageType, sCapability);
						
						CloseTLVArray(hTLV);
						hTLV = CreateArray();
						
						ParseTLV(hTLV, sBuffer[iSubOffset], iLength-iSubOffset);
						
						switch(iMessageType)
						{
							// normal message
							case 0x0000:
							{
								// Send File
								if(StrEqual(sCapability, "094613434c7f11d18222444553540000"))
								{
									new bool:bUseProxy = false;
									decl String:sProxyIP[33], iExternalPort;
									if(GetTLVString(hTLV, 0x000A, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("Request Number: %04x", Bytes2Int(sBuffer, 2)); // 	0x0001 - normal message 0x0002 - file ack or file ok 
									}
									if(GetTLVString(hTLV, 0x000F, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("Requesting Host Check");
									}
									if(GetTLVString(hTLV, 0x000E, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("Language: %s", sBuffer);
									}
									if(GetTLVString(hTLV, 0x000D, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("Character Set: %s", sBuffer);
									}
									if(GetTLVString(hTLV, 0x000C, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("User Message: %s", sBuffer);
									}
									if(GetTLVString(hTLV, 0x0002, sBuffer, sizeof(sBuffer), iLength))
									{
										Format(sProxyIP, sizeof(sProxyIP), "%d.%d.%d.%d", Bytes2Int(sBuffer, 1), Bytes2Int(sBuffer, 1, 1), Bytes2Int(sBuffer, 1, 2), Bytes2Int(sBuffer, 1, 3));
										PrintToServer("Proxy IP: %s", sProxyIP);
									}
									if(GetTLVString(hTLV, 0x0016, sBuffer, sizeof(sBuffer), iLength))
									{
										// Just inversed.. bytes[i]^0xff
										PrintToServer("XORed Proxy IP: %d.%d.%d.%d", Bytes2Int(sBuffer, 1), Bytes2Int(sBuffer, 1, 1), Bytes2Int(sBuffer, 1, 2), Bytes2Int(sBuffer, 1, 3));
									}
									if(GetTLVString(hTLV, 0x0003, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("Client IP Address: %d.%d.%d.%d", Bytes2Int(sBuffer, 1), Bytes2Int(sBuffer, 1, 1), Bytes2Int(sBuffer, 1, 2), Bytes2Int(sBuffer, 1, 3));
									}
									if(GetTLVString(hTLV, 0x0005, sBuffer, sizeof(sBuffer), iLength))
									{
										iExternalPort = Bytes2Int(sBuffer, 2);
										PrintToServer("External Port: %d", iExternalPort);
									}
									if(GetTLVString(hTLV, 0x0017, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("XORed External Port: %d", Bytes2Int(sBuffer, 2)); // Just inversed
									}
									if(GetTLVString(hTLV, 0x0010, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("Requesting Proxy Connection");
										bUseProxy = true;
									}
									if(GetTLVString(hTLV, 0x0011, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("Requesting SSL Connection");
									}
									if(GetTLVString(hTLV, 0x0012, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("Maximum Protocol Version: %d", Bytes2Int(sBuffer, 2));
									}
									if(GetTLVString(hTLV, 0x2711, sBuffer, sizeof(sBuffer), iLength))
									{
										// A value of 0x0001 indicates that only one file is being transferred while a value of 0x0002 indicates that more than one file is being transferred.
										new iMultipleFiles = Bytes2Int(sBuffer, 2);
										// the total number of files that will be transmitted during this file transfer.
										new iFileCount = Bytes2Int(sBuffer, 2, 2);
										// the sum of the size in bytes of all files to be transferred.
										new iFileSize = Bytes2Int(sBuffer, 4, 4);
										PrintToServer("MultipleFiles: %04x, FileCount: %d, File size: %d, File name: %s", iMultipleFiles, iFileCount, iFileSize, sBuffer[8]);
									}
									if(GetTLVString(hTLV, 0x2712, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("File Name Encoding: %s", sBuffer);
									}
									if(GetTLVString(hTLV, 0x0004, sBuffer, sizeof(sBuffer), iLength))
									{
										PrintToServer("Verified IP Address: %d.%d.%d.%d", Bytes2Int(sBuffer, 1), Bytes2Int(sBuffer, 1, 1), Bytes2Int(sBuffer, 1, 2), Bytes2Int(sBuffer, 1, 3));
									}
									
									new Handle:hProxy = CreateTrie();
									SetTrieArray(hProxy, "cookie", iCookie, 8);
									SetTrieValue(hProxy, "use_oft", false);
									SetTrieString(hProxy, "target_uin", sUIN);
									SetTrieValue(hProxy, "external_port", iExternalPort);
									
									// Want to use a proxy. Connect to the proxy ip.
									if(bUseProxy)
									{
										SetTrieValue(hProxy, "stage1_proxy", true);
										new Handle:hProxySocket = SocketCreate(SOCKET_TCP, ProxySocket_OnError);
										SocketSetArg(hProxySocket, PushArrayCell(g_hProxyInfo, hProxy));
										SocketConnect(hProxySocket, ProxySocket_OnConnect, ProxySocket_OnReceive, ProxySocket_OnDisconnect, sProxyIP, 5190);
									}
									// Tell the sender, we want to use a proxy.
									else
									{
										SetTrieValue(hProxy, "stage1_proxy", false);
										new Handle:hProxySocket = SocketCreate(SOCKET_TCP, ProxySocket_OnError);
										SocketSetArg(hProxySocket, PushArrayCell(g_hProxyInfo, hProxy));
										SocketConnect(hProxySocket, ProxySocket_OnConnect, ProxySocket_OnReceive, ProxySocket_OnDisconnect, "ars.icq.com", 443);
									}
								}
							}
							// abort request
							case 0x0001:
							{
								if(GetTLVString(hTLV, 0x000B, sBuffer, sizeof(sBuffer), iLength))
								{
									PrintToServer("Cancel Reason: %04x", Bytes2Int(sBuffer, 2));
								}
							}
							// file ack
							case 0x0002:
							{
								PrintToServer("Client is ready to begin the transfer.");
							}
						}
					}
				}
			}
			CloseTLVArray(hTLV);
		}
		else if(iFamily == 0x04 && iSubFamily == 0x0A) // SRV_MSG_MISSED
		{
			PrintToServer("SRV_MSG_MISSED");
		}
		else if(iFamily == 0x04 && iSubFamily == 0x0B) // CLI_ICBM_SENDxACK
		{
			PrintToServer("CLI_ICBM_SENDxACK");
			
			new iOffset = 0;
			iOffset += 8; // msg cookie
			
			new iMsgChannel = Bytes2Int(sSubData, 2, iOffset);
			iOffset += 2;
			
			decl String:sUIN[sSubData[10]+1];
			Format(sUIN, sSubData[10]+1, "%s", sSubData[11]);
			iOffset += sSubData[10]+1;
			
			new iReason = Bytes2Int(sSubData, 2, iOffset);
			
			PrintToServer("MsgChannel: %04x, uin: %s, reason: %d", iMsgChannel, sUIN, iReason);
			if(iReason == 3)
			{
				if(iMsgChannel == 1)
				{
					
				}
			}
		}
		else if(iFamily == 0x04 && iSubFamily == 0x0C) // SRV_MSG_ACK
		{
			PrintToServer("SRV_MSG_ACK");
		}
		else if(iFamily == 0x04 && iSubFamily == 0x12) // SRV_MY_OFFLINE
		{
			PrintToServer("SRV_MY_OFFLINE");
		}
		// END - ICBM service (04)
		
		// Privacy management service (09)
		else if(iFamily == 0x09 && iSubFamily == 0x03) // SRV_PRIVACY_RIGHTS_REPLY
		{
			PrintToServer("SRV_PRIVACY_RIGHTS_REPLY");
			
			new Handle:hTLV = CreateArray();
			ParseTLV(hTLV, sSubData, iDataLength-10);
			
			decl String:sBuffer[64], iLength;
			if(GetTLVString(hTLV, 0x01, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(g_hSettings, "max_visiblelist_entries", Bytes2Int(sBuffer, 2));
			if(GetTLVString(hTLV, 0x02, sBuffer, sizeof(sBuffer), iLength))
				SetTrieValue(g_hSettings, "max_invisiblelist_entries", Bytes2Int(sBuffer, 2));
			
			CloseTLVArray(hTLV);
		}
		// END - Privacy management service (09)
		
		// Usage stats service (0B)
		else if(iFamily == 0x0B && iSubFamily == 0x02) // SRV_SET_MINxREPORTxINTERVAL
		{
			PrintToServer("SRV_SET_MINxREPORTxINTERVAL");
			
			PrintToServer("min interval between stats reports (hours): %d", Bytes2Int(sSubData, 2));
		}
		// END - Usage stats service (0B)
		
		// Server side information service  (13)
		else if(iFamily == 0x13 && iSubFamily == 0x03) // SRV_SSI_RIGHTS_REPLY
		{
			PrintToServer("SRV_SSI_RIGHTS_REPLY");
			
			new Handle:hTLV = CreateArray();
			ParseTLV(hTLV, sSubData, iDataLength-10);
			
			decl String:sBuffer[512], iLength;
			if(GetTLVString(hTLV, 0x04, sBuffer, sizeof(sBuffer), iLength))
			{
				SetTrieValue(g_hSettings, "max_contacts", Bytes2Int(sBuffer, 2));
				SetTrieValue(g_hSettings, "max_groups", Bytes2Int(sBuffer, 2, 2));
				SetTrieValue(g_hSettings, "max_visible_contacts", Bytes2Int(sBuffer, 2, 4));
				SetTrieValue(g_hSettings, "max_invisible_contacts", Bytes2Int(sBuffer, 2, 6));
				SetTrieValue(g_hSettings, "max_visinvis_bitmasks", Bytes2Int(sBuffer, 2, 8));
				SetTrieValue(g_hSettings, "max_presense_info_fields", Bytes2Int(sBuffer, 2, 10));
				/*SetTrieValue(g_hSettings, "max_itemtype_06", Bytes2Int(sBuffer, 2, 12));
				SetTrieValue(g_hSettings, "max_itemtype_07", Bytes2Int(sBuffer, 2, 14));
				SetTrieValue(g_hSettings, "max_itemtype_08", Bytes2Int(sBuffer, 2, 16));
				SetTrieValue(g_hSettings, "max_itemtype_09", Bytes2Int(sBuffer, 2, 18));
				SetTrieValue(g_hSettings, "max_itemtype_0a", Bytes2Int(sBuffer, 2, 20));
				SetTrieValue(g_hSettings, "max_itemtype_0b", Bytes2Int(sBuffer, 2, 22));
				SetTrieValue(g_hSettings, "max_itemtype_0c", Bytes2Int(sBuffer, 2, 24));
				SetTrieValue(g_hSettings, "max_itemtype_0d", Bytes2Int(sBuffer, 2, 26));*/
				SetTrieValue(g_hSettings, "max_ignorelist_entries", Bytes2Int(sBuffer, 2, 28));
				/*SetTrieValue(g_hSettings, "max_itemtype_0f", Bytes2Int(sBuffer, 2, 30));
				SetTrieValue(g_hSettings, "max_item_10", Bytes2Int(sBuffer, 2, 32));
				SetTrieValue(g_hSettings, "max_item_11", Bytes2Int(sBuffer, 2, 34));
				SetTrieValue(g_hSettings, "max_item_12", Bytes2Int(sBuffer, 2, 36));
				SetTrieValue(g_hSettings, "max_item_13", Bytes2Int(sBuffer, 2, 38));
				SetTrieValue(g_hSettings, "max_item_14", Bytes2Int(sBuffer, 2, 40));*/
			}
			
			CloseTLVArray(hTLV);
		}
		else if(iFamily == 0x13 && iSubFamily == 0x06) // SRV_SSIxREPLY
		{
			PrintToServer("SRV_SSIxREPLY");
			
			new iOffset = 0;
			new iProtocolVersion = sSubData[iOffset++];
			new iNumItems = Bytes2Int(sSubData, 2, iOffset);
			iOffset += 2;
			
			PrintToServer("protocol version: %d, numitems: %d", iProtocolVersion, iNumItems);
			
			/*for(new i=0;i<iDataLength-10;i++)
			{
				PrintToServer("%02x (%d): %08b", _:sSubData[i]&0xff, _:sSubData[i]&0xff, _:sSubData[i]&0xff);
			}*/
			
			new Handle:hTLV;
			
			decl String:sItemName[64];
			new iGroupID, iItemID, iTypeOfItemFlag, iAdditionalDataLength, iLength;
			for(new i=0;i<iNumItems;i++)
			{
				iLength = Bytes2Int(sSubData, 2, iOffset);
				iOffset += 2;
				if(iLength > 0)
				{
					Format(sItemName, iLength+1, sSubData[iOffset]);
					iOffset += iLength;
				}
				else
					Format(sItemName, sizeof(sItemName), "##no_name");
				
				iGroupID = Bytes2Int(sSubData, 2, iOffset);
				iOffset += 2;
				
				iItemID = Bytes2Int(sSubData, 2, iOffset);
				iOffset += 2;
				
				iTypeOfItemFlag = Bytes2Int(sSubData, 2, iOffset);
				iOffset += 2;
				
				iAdditionalDataLength = Bytes2Int(sSubData, 2, iOffset);
				iOffset += 2;
				
				PrintToServer("Item: %s, groupid: %04x, itemid: %04x, type of item flag: %04x, length of additional data: %d",
				sItemName, iGroupID, iItemID, iTypeOfItemFlag, iAdditionalDataLength);
				
				if(iAdditionalDataLength > 0)
				{
					hTLV = CreateArray();
					ParseTLV(hTLV, sSubData[iOffset], iAdditionalDataLength);
					
					decl String:sBuffer[1024];
					
					/*new iSize = GetArraySize(hTLV);
					new Handle:hPart, iTemp, iType;
					PrintToServer("TLV size: %d", iSize);
					for(new t=0;t<iSize;t++)
					{
						hPart = GetArrayCell(hTLV, t);
						iType = GetArrayCell(hPart, 0);
						GetTLVString(hTLV, iType, sBuffer, sizeof(sBuffer), iTemp);
						PrintToServer("0x%04x: (%d)", iType, iTemp);
					}*/
					
					
					switch(iTypeOfItemFlag)
					{
						// Buddy record (name: uin for ICQ and screenname for AIM)
						case 0x0000:
						{
							PrintToServer("Buddy record");
							if(GetTLVString(hTLV, 0x0066, sBuffer, sizeof(sBuffer), iLength))
							{
								// Awaiting authorization for this person
								/* Signifies that you are awaiting authorization for this buddy. 
								 * The client is in charge of putting this TLV, 
								 * but you will not receiving status updates for the contact 
								 * until they authorize you, regardless if this is here or not. 
								 * Meaning, this is only here to tell your client 
								 * that you are waiting for authorization for the person. 
								 * This TLV is always empty.
								 */
								 PrintToServer("Awaiting authorization for %s", sItemName);
							}
							
							// This stores the name that the contact should show up as in the contact list. 
							// It should initially be set to the contact's nick name, and can be changed to anything by the client.
							if(GetTLVString(hTLV, 0x0131, sBuffer, sizeof(sBuffer), iLength))
							{
								PrintToServer("%s is also called %s by this user.", sItemName, sBuffer);
							}
							
							if(GetTLVString(hTLV, 0x0137, sBuffer, sizeof(sBuffer), iLength))
							{
								PrintToServer("%s locally specified buddy email: %s.", sItemName, sBuffer);
							}
							
							if(GetTLVString(hTLV, 0x013A, sBuffer, sizeof(sBuffer), iLength))
							{
								PrintToServer("%s locally specified buddy SMS: %s.", sItemName, sBuffer);
							}
							
							if(GetTLVString(hTLV, 0x013C, sBuffer, sizeof(sBuffer), iLength))
							{
								PrintToServer("%s locally specified buddy comment: %s.", sItemName, sBuffer);
							}
							
							if(GetTLVString(hTLV, 0x0145, sBuffer, sizeof(sBuffer), iLength))
							{
								PrintToServer("First Time Message Sent to Buddy (Unix Timestamp): %d", Bytes2Int(sBuffer, 4));
							}
							
							/*if(GetTLVString(hTLV, 0x015C, sBuffer, sizeof(sBuffer), iLength))
							{
								PrintToServer("Unknown info 0x015C: %s", sBuffer);
							}
							
							if(GetTLVString(hTLV, 0x015D, sBuffer, sizeof(sBuffer), iLength))
							{
								PrintToServer("Unknown info 0x015D: %s", sBuffer);
							}
							
							if(GetTLVString(hTLV, 0x006D, sBuffer, sizeof(sBuffer), iLength))
							{
								PrintToServer("Unknown info 0x006D: %s", sBuffer);
							}*/
							
							new Handle:hBuddy;
							if(!GetTrieValue(g_hContactList, sItemName, hBuddy))
							{
								hBuddy = CreateTrie();
								SetTrieValue(g_hContactList, sItemName, hBuddy);
								PushArrayString(g_hBuddyUINs, sItemName);
							}
							
							SetTrieValue(hBuddy, "buddy_id", iItemID);
							SetTrieValue(hBuddy, "group_id", iGroupID);
							
							UpdateBuddyInfo(sItemName);
						}
						// Group record
						case 0x0001:
						{
							PrintToServer("Group record");
							if(GetTLVString(hTLV, 0x00C8, sBuffer, sizeof(sBuffer), iLength))
							{
								// Master group?
								if(iGroupID == 0x0000)
								{
									decl hGroupID[2];
									// List of group ids (word)
									for(new x=0;x<iLength/2;x++)
									{
										hGroupID[0] = Bytes2Int(sBuffer, 2, x*2);
										hGroupID[1] = _:CreateArray(ByteCountToCells(32));
										PushArrayString(Handle:hGroupID[1], "");
										PushArrayArray(g_hContactGroups, hGroupID, 2);
										PrintToServer("GroupID: %04x", hGroupID[0]);
									}
								}
								// Just a group!
								else
								{
									// find group array
									new hGroupID[2], iSize = GetArraySize(g_hContactGroups);
									for(new g=0;g<iSize;g++)
									{
										GetArrayArray(g_hContactGroups, g, hGroupID, 2);
										if(hGroupID[0] == iGroupID)
										{
											SetArrayString(Handle:hGroupID[1], 0, sItemName);
											
											for(new u=0;u<iLength/2;u++)
											{
												PushArrayCell(Handle:hGroupID[1], Bytes2Int(sBuffer, 2, u*2));
												PrintToServer("Buddies in group %s (group id: %d): %d", sItemName, iGroupID, Bytes2Int(sBuffer, 2, u*2));
											}
											break;
										}
									}
								}
							}
						}
						// Permit record ("Allow" list in AIM, and "Visible" list in ICQ)
						case 0x0002:
						{
							PrintToServer("Permit record");
						}
						// Deny record ("Block" list in AIM, and "Invisible" list in ICQ)
						case 0x0003:
						{
							PrintToServer("Deny record");
						}
						// Permit/deny settings or/and bitmask of the AIM classes
						case 0x0004:
						{
							PrintToServer("Permit/deny settings");
							if(GetTLVString(hTLV, 0x00CA, sBuffer, sizeof(sBuffer), iLength))
							{
								/* This is the byte that tells the AIM servers your privacy setting. 
								 * If 1, then allow all users to see you. 
								 * If 2, then block all users from seeing you. 
								 * If 3, then allow only the users in the permit list. 
								 * If 4, then block only the users in the deny list. 
								 * If 5, then allow only users on your buddy list.
								 */
								PrintToServer("Privacy setting: %d", sBuffer[0]);
							}
							
							if(GetTLVString(hTLV, 0x016E, sBuffer, sizeof(sBuffer), iLength))
							{
								// Unknown privacy byte?!
								PrintToServer("Unknown privacy setting: %d", sBuffer[0]);
							}
						}
						// Presence info (if others can see your idle status, etc) 
						case 0x0005:
						{
							if(GetTLVString(hTLV, 0x00DA, sBuffer, sizeof(sBuffer), iLength))
							{
								// Unknown presence dword?!
								PrintToServer("Unknown presence info: %010x", Bytes2Int(sBuffer, 5));
							}
							
							if(GetTLVString(hTLV, 0x00C9, sBuffer, sizeof(sBuffer), iLength))
							{
								// Unknown presence dword?!
								PrintToServer("Unknown presence info (idle state etc): %08x", Bytes2Int(sBuffer, 4));
							}
							
							if(GetTLVString(hTLV, 0x00D6, sBuffer, sizeof(sBuffer), iLength))
							{
								// Unknown presence dword?!
								PrintToServer("Unknown presence info 0x00D6: %08x", Bytes2Int(sBuffer, 4));
							}
							
							if(GetTLVString(hTLV, 0x00D7, sBuffer, sizeof(sBuffer), iLength))
							{
								// Unknown presence dword?!
								PrintToServer("Unknown presence info 0x00D7: %08x", Bytes2Int(sBuffer, 4));
							}
							
							if(GetTLVString(hTLV, 0x00D8, sBuffer, sizeof(sBuffer), iLength))
							{
								// Unknown presence dword?!
								PrintToServer("Unknown presence info 0x00D8: %08x", Bytes2Int(sBuffer, 4));
							}
						}
						// Unknown. ICQ2k shortcut bar items ?
						case 0x0009:
						{
							PrintToServer("Unknown. ICQ2k shortcut bar items ?");
						}
						// Ignore list record.
						case 0x000E:
						{
							PrintToServer("Ignore list record");
							
							// This stores the name that the contact should show up as in the contact list. 
							// It should initially be set to the contact's nick name, and can be changed to anything by the client.
							if(GetTLVString(hTLV, 0x0131, sBuffer, sizeof(sBuffer), iLength))
							{
								PrintToServer("%s is also called %s by this user.", sItemName, sBuffer);
							}
						}
						// Last update date (name: "LastUpdateDate").
						case 0x000F:
						{
							if(GetTLVString(hTLV, 0x0145, sBuffer, sizeof(sBuffer), iLength))
							{
								PrintToServer("First Time Message Sent to Buddy (Unix Timestamp): %d", Bytes2Int(sBuffer, 4));
							}
						}
						// Non-ICQ contact (to send SMS). Name: 1#EXT, 2#EXT, etc
						case 0x0010:
						{
							
						}
						// Item that contain roster import time (name: "Import time")
						case 0x0013:
						{
							
						}
						// Own icon (avatar) info. Name is an avatar id number as text
						case 0x0014:
						{
							if(GetTLVString(hTLV, 0x00D5, sBuffer, sizeof(sBuffer), iLength))
							{
								// Probably needs different reading, but we don't use it anyways, so meh
								PrintToServer("MD5SUM of Current Buddy Icon: %012x", Bytes2Int(sBuffer, iLength));
							}
						}
						// User has this account on his contactlist / granted future authorization
						case 0x0019:
						{
							
						}
					}
					iOffset += iAdditionalDataLength;
					CloseTLVArray(hTLV);
				}
			}
			
			// Last change time is only sent in the last package
			if(!(iFlags & 1))
			{
				new iLastSSIListChangeTime = Bytes2Int(sSubData, 4, iOffset);
				PrintToServer("Last SSI list change time: %d", iLastSSIListChangeTime);
				SendSNAC("CLI_SSI_ACTIVATE");
				
				SendSNAC("CLI_SET_LOCATION_INFO");
				
				// Client ask server for ICBM service parameters
				SendSNAC("CLI_SETICBM");
				
				// Set our status to online
				SendSNAC("CLI_SETxSTATUS");
				
				// Client is setup. Ready to chat!
				SendSNAC("CLI_READY");
				
				// Request rights information for buddy service.
				SendSNAC("CLI_BUDDYLIST_RIGHTS_REQ");
			}
		}
		else if(iFamily == 0x13 && iSubFamily == 0x09) // SRV_SSIxMODxACK
		{
			PrintToServer("SRV_SSIxMODxACK");
			for(new i=0;i<(iDataLength-10);i+=2)
			{
				PrintToServer("Result code for item #%d: %04x", i, Bytes2Int(sSubData, 2, i));
			}
		}
		else if(iFamily == 0x13 && iSubFamily == 0x0F) // SRV_SSI_UPxTOxDATE
		{
			PrintToServer("SRV_SSI_UPxTOxDATE");
			
			PrintToServer("Modification date/time of server SSI: %d", Bytes2Int(sSubData, 4));
			PrintToServer("Number of items in server SSI: %d", Bytes2Int(sSubData, 2, 4));
		}
		else if(iFamily == 0x13 && iSubFamily == 0x0E) // CLI_SSIxUPDATE
		{
			PrintToServer("CLI_SSIxUPDATE");
		}
		else if(iFamily == 0x13 && iSubFamily == 0x11) // CLI_SSI_EDIT_BEGIN
		{
			PrintToServer("CLI_SSI_EDIT_BEGIN");
		}
		else if(iFamily == 0x13 && iSubFamily == 0x12) // CLI_SSI_EDIT_END
		{
			PrintToServer("CLI_SSI_EDIT_END");
		}
		else if(iFamily == 0x13 && iSubFamily == 0x15) // SRV_SSI_FUTURExAUTHxGRANTED
		{
			PrintToServer("SRV_SSI_FUTURExAUTHxGRANTED");
			
			new iOffset = 0;
			new iUINLength = Bytes2Int(sSubData, 1, iOffset++);
			decl String:sUIN[iUINLength+1];
			Format(sUIN, iUINLength+1, sSubData[iOffset]);
			iOffset += iUINLength;
			new iReasonLength = Bytes2Int(sSubData, 1, iOffset++);
			decl String:sReason[iReasonLength+1];
			Format(sReason, iReasonLength+1, sSubData[iOffset]);
			iOffset += iReasonLength;
			new iUnknown = Bytes2Int(sSubData, 2, iOffset);
			
			PrintToServer("Client %s granted future authorization to you. Reason: %s (Unknown: %04x)", sUIN, sReason, iUnknown);
		}
		else if(iFamily == 0x13 && iSubFamily == 0x19) // SRV_SSI_AUTHxREQUEST
		{
			PrintToServer("SRV_SSI_AUTHxREQUEST");
			
			new iOffset = 0;
			new iUINLength = Bytes2Int(sSubData, 1, iOffset++);
			decl String:sUIN[iUINLength+1];
			Format(sUIN, iUINLength+1, sSubData[iOffset]);
			iOffset += iUINLength;
			new iReasonLength = Bytes2Int(sSubData, 1, iOffset++);
			decl String:sReason[iReasonLength+1];
			Format(sReason, iReasonLength+1, sSubData[iOffset]);
			iOffset += iReasonLength;
			new iUnknown = Bytes2Int(sSubData, 2, iOffset);
			
			PrintToServer("Client %s requested authorization to add you to his contact list. Reason: %s (Unknown: %04x)", sUIN, sReason, iUnknown);
		}
		else if(iFamily == 0x13 && iSubFamily == 0x1C) // SRV_SSI_YOU_WERE_ADDED
		{
			PrintToServer("SRV_SSI_YOU_WERE_ADDED");
			new iUINLength = Bytes2Int(sSubData, 1);
			decl String:sUIN[iUINLength+1];
			Format(sUIN, iUINLength+1, sSubData[1]);
			
			PrintToServer("Client %s added you to his contact list.", sUIN);
		}
		else if(iFamily == 0x13 && iSubFamily == 0x1B) // SRV_SSI_AUTHxREPLY
		{
			PrintToServer("SRV_SSI_AUTHxREPLY");
			
			new iOffset = 0;
			new iUINLength = Bytes2Int(sSubData, 1, iOffset++);
			decl String:sUIN[iUINLength+1];
			Format(sUIN, iUINLength+1, sSubData[iOffset]);
			iOffset += iUINLength;
			
			new iFlag = Bytes2Int(sSubData, 1, iOffset++);
			
			new iReasonLength = Bytes2Int(sSubData, 1, iOffset++);
			decl String:sReason[iReasonLength+1];
			Format(sReason, iReasonLength+1, sSubData[iOffset]);
			
			switch(iFlag)
			{
				case 0:
				{
					PrintToServer("Client %s declined your authorization request. Reason: %s", sUIN, sReason);
				}
				case 1:
				{
					PrintToServer("Client %s accepted your authorization request. Reason: %s", sUIN, sReason);
				}
				default:
				{
					PrintToServer("Unknown authorization flag: %02x. Client %s did something. Reason: %s", iFlag, sUIN, sReason);
				}
			}
		}
		// END - Server side information service  (13)
		
		// ICQ specific extensions service (15)
		else if(iFamily == 0x15 && iSubFamily == 0x03) // SRV_META
		{
			PrintToServer("SRV_META");
			
			// This is a TLV.. don't care for the tlv header (4bytes)
			new iOffset = 4;
			new iChunkSize = Bytes2Int(sSubData, 2, iOffset, true);
			iOffset += 2;
			new iUIN = Bytes2Int(sSubData, 4, iOffset, true);
			iOffset += 4;
			new iDataType = Bytes2Int(sSubData, 2, iOffset, true);
			iOffset += 2;
			new iRequestSequenceNr = Bytes2Int(sSubData, 2, iOffset, true);
			iOffset += 2;
			
			decl String:sUIN[32];
			IntToString(iUIN, sUIN, sizeof(sUIN));
			
			switch(iDataType)
			{
				// This is the server response to cli_offline_msgs_req SNAC(15,02)/003C. This snac contain single offline message that was sent by another user and buffered by server when client was offline. 
				case 0x0041:
				{
					PrintToServer("SRV_OFFLINE_MESSAGE");
					
					// message sender uin
					new iSenderUIN = Bytes2Int(sSubData, 4, iOffset, true);
					iOffset += 4;
					
					// year when message was sent
					new iYearSent = Bytes2Int(sSubData, 2, iOffset, true);
					iOffset += 2;
					
					// month when message was sent
					new iMonthSent = sSubData[iOffset++];
					
					// day when message was sent
					new iDaySent = sSubData[iOffset++];
					
					// hour (GMT) when message was sent
					new iHourSent = sSubData[iOffset++];
					
					// minute when message was sent
					new iMinuteSent = sSubData[iOffset++];
					
					// message type - see MTYPE_ defines
					new iMsgType = sSubData[iOffset++];
					
					// message flags - see MFLAG_ defines
					new iMsgFlags = sSubData[iOffset++];
					
					new iLength = Bytes2Int(sSubData, 2, iOffset, true);
					iOffset += 2;
					decl String:sMessage[iLength];
					Format(sMessage, iLength, "%s", sSubData[iOffset]);
					
					PrintToServer("Offline message by %d (type: %02x, flags: %02x) (%d.%d.%d %d:%d): %s", iSenderUIN, iMsgType, iMsgFlags, iDaySent, iMonthSent, iYearSent, iHourSent, iMinuteSent, sMessage);
				}
				// This is the last SNAC in server response to cli_offline_msgs_req SNAC(15,02)/003C. It doesn't contain message - it is only end_of_sequence marker. 
				case 0x0042:
				{
					PrintToServer("SRV_END_OF_OFFLINE_MSGS");
					
					PrintToServer("dropped messages flag: %02x", sSubData[iOffset]);
					
					// Delete offline messages after we got them.
					new Handle:hArgs = CreateArray(ByteCountToCells(64));
					PushArrayString(hArgs, "CLI_DELETE_OFFLINE_MSGS_REQ");
					SendSNAC("CLI_META", hArgs);
				}
				case 0x07DA:
				{
					new iDataSubtype = Bytes2Int(sSubData, 2, iOffset, true);
					iOffset += 2;
					
					PrintToServer("META_DATA: Data subtype: %04x", iDataSubtype);
					switch(iDataSubtype)
					{
						case 0x0001:
						{
							PrintToServer("META_PROCESSING_ERROR");
							PrintToServer("Error (%d): %s", sSubData[iOffset], sSubData[iOffset]);
						}
						case 0x0064:
						{
							PrintToServer("META_SET_HOMEINFO_ACK");
							PrintToServer("Success: %02x", sSubData[iOffset]);
						}
						case 0x006E:
						{
							PrintToServer("META_SET_WORKINFO_ACK");
							PrintToServer("Success: %02x", sSubData[iOffset]);
						}
						case 0x0078:
						{
							PrintToServer("META_SET_MOREINFO_ACK");
							PrintToServer("Success: %02x", sSubData[iOffset]);
						}
						case 0x0082:
						{
							PrintToServer("META_SET_NOTES_ACK");
							PrintToServer("Success: %02x", sSubData[iOffset]);
						}
						case 0x0087:
						{
							PrintToServer("META_SET_EMAILINFO_ACK");
							PrintToServer("Success: %02x", sSubData[iOffset]);
						}
						case 0x008C:
						{
							PrintToServer("META_SET_INTINFO_ACK");
							PrintToServer("Success: %02x", sSubData[iOffset]);
						}
						// Result for client change past/affilations-info request. 
						// If success byte equal 0x0A - operation was finished succesfully, if not - database error. 
						// Request was sent by SNAC(15,02)/07D0/041A.
						case 0x0096:
						{
							PrintToServer("META_SET_AFFINFO_ACK OR SRV_META_INFO_REPLY");
							//PrintToServer("Success: %02x", sSubData[iOffset]);
							
							// TODO
						}
						// Result for client change info request.
						case 0x00A0:
						{
							PrintToServer("META_SET_PERMS_ACK");
							PrintToServer("Success: %02x", sSubData[iOffset]);
						}
						// Result for client change info request.
						case 0x00AA:
						{
							PrintToServer("META_SET_PASSWORD_ACK");
							PrintToServer("Success: %02x", sSubData[iOffset]);
						}
						// Result for client unregistration request.
						case 0x00B4:
						{
							PrintToServer("META_UNREGISTER_ACK");
							PrintToServer("Success: %02x", sSubData[iOffset]);
						}
						// Result for client change homepage category info request.
						case 0x00BE:
						{
							PrintToServer("META_SET_HPAGECAT_ACK");
							PrintToServer("Success: %02x", sSubData[iOffset]);
						}
						case 0x00C8:
						{
							PrintToServer("META_BASIC_USERINFO");
							new iSuccess = sSubData[iOffset];
							iOffset++;
							PrintToServer("Success: %02x", iSuccess);
							
							if(iSuccess == 0x0A)
							{
								new iSize = GetArraySize(g_hMetaRequests);
								new iPair[2], bool:bFound = false;
								for(new i=0;i<iSize;i++)
								{
									GetArrayArray(g_hMetaRequests, i, iPair, 2);
									if(iPair[1] == iRequestSequenceNr)
									{
										IntToString(iPair[0], sUIN, sizeof(sUIN));
										RemoveFromArray(g_hMetaRequests, i);
										bFound = true;
										break;
									}
								}
								
								if(bFound)
								{
									new Handle:hBuddy;
									if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
									{
										hBuddy = CreateTrie();
										SetTrieValue(g_hContactList, sUIN, hBuddy);
										PushArrayString(g_hBuddyUINs, sUIN);
									}
									
									decl String:sBuffer[64];
									new iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "nickname", sBuffer);
									if(StrEqual(sUIN, g_sUID))
									{
										Format(g_sOwnNickname, sizeof(g_sOwnNickname), "%s", sBuffer);
									}
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "firstname", sBuffer);
									if(StrEqual(sUIN, g_sUID))
									{
										Format(g_sOwnFirstname, sizeof(g_sOwnFirstname), "%s", sBuffer);
									}
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "lastname", sBuffer);
									if(StrEqual(sUIN, g_sUID))
									{
										Format(g_sOwnLastname, sizeof(g_sOwnLastname), "%s", sBuffer);
									}
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "email", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "home_city", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "home_state", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "home_phone", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "home_fax", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "home_address", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "cell_phone", sBuffer);
								
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "home_zip_code", sBuffer);
									
									SetTrieValue(hBuddy, "home_country_code", Bytes2Int(sSubData, 2, iOffset, true));
									iOffset += 2;
									
									SetTrieValue(hBuddy, "gmt_offset", sSubData[iOffset]);
									iOffset += 1;
									
									UpdateBuddyInfo(sUIN);
									
									// Followed by chars:
									// authorization flag
									// webaware flag
									// direct connection permissions
									// publish primary email flag (?)
								}
							}
						}
						case 0x00D2:
						{
							PrintToServer("META_WORK_USERINFO");
							new iSuccess = sSubData[iOffset];
							iOffset++;
							PrintToServer("Success: %02x", iSuccess);
							
							if(iSuccess == 0x0A)
							{
								new iSize = GetArraySize(g_hMetaRequests);
								new iPair[2], bool:bFound = false;
								for(new i=0;i<iSize;i++)
								{
									GetArrayArray(g_hMetaRequests, i, iPair, 2);
									if(iPair[1] == iRequestSequenceNr)
									{
										IntToString(iPair[0], sUIN, sizeof(sUIN));
										RemoveFromArray(g_hMetaRequests, i);
										bFound = true;
										break;
									}
								}
								
								if(bFound)
								{
									new Handle:hBuddy;
									if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
									{
										hBuddy = CreateTrie();
										SetTrieValue(g_hContactList, sUIN, hBuddy);
										PushArrayString(g_hBuddyUINs, sUIN);
									}
									
									decl String:sBuffer[64];
									new iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "work_city", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "work_state", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "work_phone", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "work_fax", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "work_address", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "work_zip_code", sBuffer);
									
									SetTrieValue(hBuddy, "work_country_code", Bytes2Int(sSubData, 2, iOffset, true));
									iOffset += 2;
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "work_company", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "work_department", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "work_position", sBuffer);
									
									SetTrieValue(hBuddy, "work_ocupation_code", Bytes2Int(sSubData, 2, iOffset, true));
									iOffset += 2;
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "work_webpage", sBuffer);
								}
							}
						}
						case 0x00DC:
						{
							PrintToServer("META_MORE_USERINFO");
							new iSuccess = sSubData[iOffset];
							iOffset++;
							PrintToServer("Success: %02x", iSuccess);
							
							if(iSuccess == 0x0A)
							{
								new iSize = GetArraySize(g_hMetaRequests);
								new iPair[2], bool:bFound = false;
								for(new i=0;i<iSize;i++)
								{
									GetArrayArray(g_hMetaRequests, i, iPair, 2);
									if(iPair[1] == iRequestSequenceNr)
									{
										IntToString(iPair[0], sUIN, sizeof(sUIN));
										RemoveFromArray(g_hMetaRequests, i);
										bFound = true;
										break;
									}
								}
								
								if(bFound)
								{
									new Handle:hBuddy;
									if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
									{
										hBuddy = CreateTrie();
										SetTrieValue(g_hContactList, sUIN, hBuddy);
										PushArrayString(g_hBuddyUINs, sUIN);
									}
									
									SetTrieValue(hBuddy, "age", Bytes2Int(sSubData, 2, iOffset, true));
									iOffset += 2;
									
									SetTrieValue(hBuddy, "gender", sSubData[iOffset]);
									iOffset++;
									
									decl String:sBuffer[64];
									new iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "hompage_address", sBuffer);
									
									SetTrieValue(hBuddy, "birth_year", Bytes2Int(sSubData, 2, iOffset, true));
									iOffset += 2;
									
									SetTrieValue(hBuddy, "birth_month", sSubData[iOffset]);
									iOffset++;
									
									SetTrieValue(hBuddy, "birth_day", sSubData[iOffset]);
									iOffset++;
									
									SetTrieValue(hBuddy, "speaking_language_1", sSubData[iOffset]);
									iOffset++;
									
									SetTrieValue(hBuddy, "speaking_language_2", sSubData[iOffset]);
									iOffset++;
									
									SetTrieValue(hBuddy, "speaking_language_3", sSubData[iOffset]);
									iOffset++;
									
									// Unknown..
									iOffset += 2;
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "orig_from_city", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "orig_from_state", sBuffer);
									
									SetTrieValue(hBuddy, "orig_from_country_code", Bytes2Int(sSubData, 2, iOffset, true));
									iOffset += 2;
									
									SetTrieValue(hBuddy, "gmt_offset", sSubData[iOffset]);
									iOffset += 1;
								}
							}
						}
						case 0x00E6:
						{
							PrintToServer("META_NOTES_USERINFO");
							new iSuccess = sSubData[iOffset];
							iOffset++;
							PrintToServer("Success: %02x", iSuccess);
							
							if(iSuccess == 0x0A)
							{
								new iSize = GetArraySize(g_hMetaRequests);
								new iPair[2], bool:bFound = false;
								for(new i=0;i<iSize;i++)
								{
									GetArrayArray(g_hMetaRequests, i, iPair, 2);
									if(iPair[1] == iRequestSequenceNr)
									{
										IntToString(iPair[0], sUIN, sizeof(sUIN));
										RemoveFromArray(g_hMetaRequests, i);
										bFound = true;
										break;
									}
								}
								
								if(bFound)
								{
									new Handle:hBuddy;
									if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
									{
										hBuddy = CreateTrie();
										SetTrieValue(g_hContactList, sUIN, hBuddy);
										PushArrayString(g_hBuddyUINs, sUIN);
									}
									
									decl String:sBuffer[256];
									new iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									SetTrieString(hBuddy, "user_notes", sBuffer);
								}
							}
						}
						case 0x0104:
						{
							PrintToServer("META_SHORT_USERINFO");
							new iSuccess = sSubData[iOffset];
							iOffset++;
							
							if(iSuccess == 0x0A)
							{
								new iSize = GetArraySize(g_hMetaRequests);
								new iPair[2], bool:bFound = false;
								for(new i=0;i<iSize;i++)
								{
									GetArrayArray(g_hMetaRequests, i, iPair, 2);
									if(iPair[1] == iRequestSequenceNr)
									{
										IntToString(iPair[0], sUIN, sizeof(sUIN));
										RemoveFromArray(g_hMetaRequests, i);
										bFound = true;
										break;
									}
								}
								
								if(bFound)
								{
									PrintToServer("uin: %s", sUIN);
									new Handle:hBuddy;
									if(!GetTrieValue(g_hContactList, sUIN, hBuddy))
									{
										hBuddy = CreateTrie();
										SetTrieValue(g_hContactList, sUIN, hBuddy);
										PushArrayString(g_hBuddyUINs, sUIN);
									}
									
									decl String:sBuffer[64];
									new iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "nickname", sBuffer);
									// We save our own info seperately.
									if(StrEqual(sUIN, g_sUID))
									{
										Format(g_sOwnNickname, sizeof(g_sOwnNickname), "%s", sBuffer);
									}
									//PrintToServer("Nickname: %s", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "firstname", sBuffer);
									// We save our own info seperately.
									if(StrEqual(sUIN, g_sUID))
									{
										Format(g_sOwnFirstname, sizeof(g_sOwnFirstname), "%s", sBuffer);
									}
									//PrintToServer("First name: %s", sBuffer);
									
									iLength = Bytes2Int(sSubData, 2, iOffset, true);
									iOffset += 2;
									Format(sBuffer, iLength, "%s", sSubData[iOffset]);
									iOffset += iLength;
									SetTrieString(hBuddy, "lastname", sBuffer);
									// We save our own info seperately.
									if(StrEqual(sUIN, g_sUID))
									{
										Format(g_sOwnLastname, sizeof(g_sOwnLastname), "%s", sBuffer);
									}
									//PrintToServer("Last name: %s", sBuffer);
									
									UpdateBuddyInfo(sUIN);
								
									/*new iAuthFlag = Bytes2Int(sSubData, 1, iOffset);
									iOffset++;
									new iUnknown = Bytes2Int(sSubData, 1, iOffset);
									iOffset++;
									new iGender = Bytes2Int(sSubData, 1, iOffset);
									iOffset++;
									
									PrintToServer("Authflag: %02x, unknown: %02x, gender: %02x", iAuthFlag, iUnknown, iGender);*/
								}
							}
						}
					}
				}
				default:
				{
					PrintToServer("chunk size: %d, uin: %d, datatype: %04x, request nr: %04x", iChunkSize, iUIN, iDataType, iRequestSequenceNr);
				}
			}
		}
		// END - ICQ specific extensions service (15)
		
		// Authorization/registration service (17)
		else if(iFamily == 0x17 && iSubFamily == 0x03) // SRV_LOGIN_REPLY
		{
			PrintToServer("SRV_LOGIN_REPLY");
			
			new Handle:hTLV = CreateArray();
			ParseTLV(hTLV, sSubData, iDataLength-10);
			
			decl String:sServer[64], String:sCookie[512];
			new iLength;
			if(GetTLVString(hTLV, 0x05, sServer, sizeof(sServer), iLength)
			&& GetTLVString(hTLV, 0x06, sCookie, sizeof(sCookie), iLength))
			{
				CloseTLVArray(hTLV);
				
				// Migrate to the other server!
				MigrateToServer(sServer, sCookie, iLength);
			}
			// Login failed?
			else
			{
				new String:sError[256];
				GetTLVString(hTLV, 0x08, sError, sizeof(sError), iLength);
				CloseTLVArray(hTLV);
				
				// See AUTHERROR_ defines
				GetAuthErrorString(Bytes2Int(sError, 2), sError, sizeof(sError));
				PrintToServer("Authorization failed: %s", sError);
				DisconnectFromServer();
			}
		}
		else if(iFamily == 0x17 && iSubFamily == 0x05) // SRV_NEW_UIN
		{
			PrintToServer("SRV_NEW_UIN");
		}
		else if(iFamily == 0x17 && iSubFamily == 0x07) // SRV_AUTH_KEY_RESPONSE
		{
			PrintToServer("SRV_AUTH_KEY_RESPONSE");
			new iLength = Bytes2Int(sSubData, 4);
			decl String:sAuthKey[iLength+1];
			for(new i=0;i<iLength;i++)
			{
				sAuthKey[i] = sSubData[i+4];
			}
			sAuthKey[iLength] = '\0';
			
			new Handle:hArgs = CreateArray(ByteCountToCells(iLength+1));
			PushArrayString(hArgs, sAuthKey);
			SendSNAC("CLI_MD5_LOGIN", hArgs);
		}
		// END - Authorization/registration service (17)
		
		else
		{
			PrintToServer("Unknown incoming SNAC: family: %x, subfamily: %x, flags: %x, reqid: %x, data: %s", iFamily, iSubFamily, iFlags, iReqID, sSubData);
		}
	}
	
	return iDataLength+6;
}

// -----------
// Server connection functions
// -----------
ConnectToServer(String:sServer[], iPort)
{
	g_hSocket = SocketCreate(SOCKET_TCP, Socket_OnError);
	if(g_hSocket == INVALID_HANDLE)
		SetFailState("Can't create socket.");
	
	SocketConnect(g_hSocket, Socket_OnConnect, Socket_OnReceive, Socket_OnDisconnect, sServer, iPort);
	
	g_iOutgoingSequence = GetRandomInt(0x0001, 0x8000);
	g_iStatus = STATUS_ONLINE;
}

DisconnectFromServer()
{
	g_iIncomingSequence = -1;
	
	if(g_hSocket != INVALID_HANDLE)
		CloseHandle(g_hSocket);
	
	g_hSocket = INVALID_HANDLE;
	g_bConnected = false;
	g_bPause = false;
	g_iLoginState = Login_NotLoggedIn;
	g_iTempCurrentPackageLength = 0;
	Format(g_sTempCurrentPackage, sizeof(g_sTempCurrentPackage), "");
	g_iTempMetaPackageLength = 0;
	Format(g_sTempMetaPackage, sizeof(g_sTempMetaPackage), "");
	Format(g_sCookie, sizeof(g_sCookie), "");
	g_iCookieLength = 0;
	
	ClearArray(g_hSupportedFamilies);
	ClearArray(g_hBuddyUINs);
	ClearTrie(g_hContactList);
	ClearTrie(g_hSettings);
	
	new iSize = GetArraySize(g_hRequests);
	for(new i=0;i<iSize;i++)
	{
		CloseHandle(GetArrayCell(g_hRequests, i));
	}
	ClearArray(g_hRequests);
	
	ClearArray(g_hRateClasses);
	iSize = GetArraySize(g_hRateGroups);
	for(new i=0;i<iSize;i++)
	{
		CloseHandle(GetArrayCell(g_hRateGroups, i));
	}
	ClearArray(g_hRateGroups);
	
	iSize = GetArraySize(g_hContactGroups);
	new hGroupInfo[2], Handle:hTemp;
	for(new i=0;i<iSize;i++)
	{
		hTemp = GetArrayCell(g_hContactGroups, i);
		GetArrayArray(hTemp, i, hGroupInfo, 2);
		CloseHandle(Handle:hGroupInfo[1]);
		CloseHandle(hTemp);
	}
	ClearArray(g_hContactGroups);
}

MigrateToServer(String:sServer[], String:sCookie[], iCookieLength)
{
	// Migrate to the other server!
	PrintToServer("Migrating to %s.", sServer);
	
	// We're done with this server..
	DisconnectFromServer();
	
	// Save cookie!
	g_iCookieLength = iCookieLength;
	for(new i=0;i<iCookieLength;i++)
	{
		g_sCookie[i] = sCookie[i];
	}
	
	decl String:sIPPort[2][33];
	ExplodeString(sServer, ":", sIPPort, 2, 33);
	
	strcopy(g_sServiceServerIP, sizeof(g_sServiceServerIP), sIPPort[0]);
	g_iServiceServerPort = StringToInt(sIPPort[1]);
	
	ConnectToServer(g_sServiceServerIP, g_iServiceServerPort);
	
	g_iLoginState = Login_Migrating;
}


// -----------
// Protocol parsing helpers
// -----------
bool:ParseFLAP(const String:data[], &FLAP_Channel:iChannel, &iLength)
{
	if(data[0] != 0x2A)
	{
		PrintToServer("ICQ protocol sync error: bad first byte in FLAP");
		return false;
	}
	iChannel = FLAP_Channel:data[1];
	
	//new iSequence = _:data[3] + (_:data[2]<<8);
	new iSequence = Bytes2Int(data, 2, 2);
	
	// This is the first message we receive
	if(g_iIncomingSequence == -1)
		g_iIncomingSequence = iSequence;
	
	if(iSequence != g_iIncomingSequence)
	{
		PrintToServer("ICQ protocol sync error: my seq %d != %d", iSequence, g_iIncomingSequence);
		//return false;
	}
	else
		// Bump the sequence number.
		UpdateSequenceNumber(g_iIncomingSequence);
	
	iLength = Bytes2Int(data, 2, 4);
 
	return true;
}

UpdateSequenceNumber(&iSequence)
{
	iSequence++;
	if(iSequence >= 256*256)
		iSequence %= 128*256;
	
	if(iSequence == 0x8000)
		iSequence = 0x0000;
}

// -----------
// Protocol packet generation helpers
// -----------
GenerateFLAPHeader(FLAP_Channel:iChannel, iLength, String:sHeader[], maxlen)
{
	//PrintToServer("Generating FLAP header. channel: %d, length: %d, sequence: %d", iChannel, iLength, g_iOutgoingSequence);
	Format(sHeader, maxlen, "%c%c", 0x2A, iChannel);
	
	decl String:sBuffer[65];
	Int2Bytes(2, g_iOutgoingSequence, sBuffer, sizeof(sBuffer));
	for(new i=0; i<2;i++)
	{
		sHeader[2+i] = sBuffer[i];
	}
	iLength = Int2Bytes(2, iLength, sBuffer, sizeof(sBuffer));
	for(new i=0; i<2;i++)
	{
		sHeader[4+i] = sBuffer[i];
	}
}

WriteSNACHeader(iFamily, iSubFamily)
{
	WriteWord(iFamily); // Family
	WriteWord(iSubFamily); // Sub-family
	WriteWord(0x0000); // SNAC flags
	
	WriteDWord(NewRequestID("REQUEST"));
}

NewRequestID(String:sCommand[])
{
	decl String:sBuffer[5];
	Format(sBuffer, 5, "%d", RoundToNearest(GetGameTime())+GetRandomInt(0,1000)+GetTime());
	
	new Handle:hTrie = CreateTrie();
	SetTrieString(hTrie, "cmd", sCommand);
	SetTrieValue(hTrie, "time", GetTime());
	SetTrieValue(hTrie, "status", 0);
	SetTrieString(hTrie, "random", sBuffer);
	
	PushArrayCell(g_hRequests, hTrie);
	
	return StringToInt(sBuffer);
}

// -----------
// Protocol SNAC packet generation and sending
// -----------
SendSNAC(const String:sCommand[], Handle:hArgs = INVALID_HANDLE)
{
	// Don't send SNACs, if server sent SRV_PAUSE.
	if(g_bPause)
		return;
	
	// Set to true in the command to get the package printed to server console
	new bDebugPackage = false;
	
	new FLAP_Channel:iChannel = FLAP_SNAC;
	// Unused. Sent
	if(StrEqual(sCommand, "CLI_HELLO"))
	{
		iChannel = FLAP_LOGIN;
		WriteDWord(0x01);
	}
	else if(StrEqual(sCommand, "CLI_LOGIN"))
	{
		iChannel = FLAP_LOGIN;
		
		WriteDWord(0x01); // Protocol version number
		
		new String:sBuffer[128];
		
		WriteTLV(0x01, g_sUID, strlen(g_sUID)); // Screen name (uin)
		XOREncryptPassword(g_sPassword, sBuffer);
		WriteTLV(0x02, sBuffer, strlen(g_sPassword)); // XOR'ed password
		WriteTLV(0x03, CLIENT_ID_STRING, strlen(CLIENT_ID_STRING)); // Client id string (name, version)
		
		new iLength = Int2Bytes(2, CLIENT_ID, sBuffer, sizeof(sBuffer));
		WriteTLV(0x16, sBuffer, iLength); // Client id number			(e.g. "234")
		
		iLength = Int2Bytes(2, CLIENT_MAJOR, sBuffer, sizeof(sBuffer));
		WriteTLV(0x17, sBuffer, iLength); // Client major version 	(e.g. "0")
		
		iLength = Int2Bytes(2, CLIENT_MINOR, sBuffer, sizeof(sBuffer));
		WriteTLV(0x18, sBuffer, iLength); // Client minor version		(e.g. "2")
		
		iLength = Int2Bytes(2, CLIENT_LESSER, sBuffer, sizeof(sBuffer));
		WriteTLV(0x19, sBuffer, iLength); // Client lesser version 	(e.g  "1")
		
		iLength = Int2Bytes(2, CLIENT_BUILD, sBuffer, sizeof(sBuffer));
		WriteTLV(0x1A, sBuffer, iLength); // Client build number 		(e.g. "1")
		
		iLength = Int2Bytes(4, 85, sBuffer, sizeof(sBuffer));
		WriteTLV(0x14, sBuffer, iLength); // Distribution number
		
		WriteTLV(0x0F, CLIENT_LANGUAGE, strlen(CLIENT_LANGUAGE)); // Client language			(e.g. "en" or "ru")
		WriteTLV(0x0E, CLIENT_COUNTRY, strlen(CLIENT_COUNTRY)); // Client country			(e.g. "en" or "ru")
	}
	else if(StrEqual(sCommand, "CLI_COOKIE"))
	{
		iChannel = FLAP_LOGIN;
		
		WriteDWord(0x01); // Protocol version number
		WriteTLV(0x06, g_sCookie, g_iCookieLength); // Screen name (uin)
	}
	
	// Generic service controls (01)
	else if(StrEqual(sCommand, "CLI_READY"))
	{
		WriteWord(0x01); // Family
		WriteWord(0x02); // Sub-family
		// Request-ID
		new String:sValue[65];
		new iLength = Int2Bytes(5, 0x00, sValue, sizeof(sValue));
		for(new i=0; i<iLength;i++)
		{
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = sValue[i];
		}
		g_iTempCurrentPackageLength += iLength;
		
		
		WriteWord(0x0200); // Family number #1
		WriteWord(0x0100); // Family #1 version
		WriteWord(0x0301); // Family #1 tool id
		
		WriteWord(0x1002); // Family number #n
		WriteWord(0x8A00); // Family #n version
		WriteWord(0x0200); // Family #n tool id
		
		// ...
		WriteByte(0x01); WriteByte(0x01); WriteByte(0x01); WriteByte(0x02); WriteByte(0x8A);
		WriteByte(0x00); WriteByte(0x03); WriteByte(0x00); WriteByte(0x01); WriteByte(0x01);
		WriteByte(0x10); WriteByte(0x02); WriteByte(0x8A); WriteByte(0x00); WriteByte(0x15);
		WriteByte(0x00); WriteByte(0x01); WriteByte(0x01); WriteByte(0x10); WriteByte(0x02);
		WriteByte(0x8A); WriteByte(0x00); WriteByte(0x04); WriteByte(0x00); WriteByte(0x01);
		WriteByte(0x01); WriteByte(0x10); WriteByte(0x02); WriteByte(0x8A); WriteByte(0x00);
		WriteByte(0x06); WriteByte(0x00); WriteByte(0x01); WriteByte(0x01); WriteByte(0x10);
		WriteByte(0x02); WriteByte(0x8A); WriteByte(0x00); WriteByte(0x09); WriteByte(0x00);
		WriteByte(0x01); WriteByte(0x01); WriteByte(0x10); WriteByte(0x02); WriteByte(0x8A);
		WriteByte(0x00); WriteByte(0x0A); WriteByte(0x00); WriteByte(0x01); WriteByte(0x01);
	}
	
	else if(StrEqual(sCommand, "CLI_RATES_REQUEST"))
	{
		WriteSNACHeader(0x01, 0x06);
	}
	else if(StrEqual(sCommand, "CLI_RATES_ACK"))
	{
		WriteSNACHeader(0x01, 0x08);
		
		new iSize = GetArraySize(g_hRateGroups);
		new Handle:hRateGroup, iGroupPair[2];
		for(new i=0;i<iSize;i++)
		{
			hRateGroup = GetArrayCell(g_hRateGroups, i);
			GetArrayArray(hRateGroup, 0, iGroupPair, 2);
			
			WriteWord(iGroupPair[0]);
		}
	}
	else if(StrEqual(sCommand, "CLI_KEEPALIVE"))
	{
		iChannel = FLAP_KEEPALIVE;
	}
	else if(StrEqual(sCommand, "CLI_PAUSE_ACK"))
	{
		WriteSNACHeader(0x01, 0x0C);
		
		WriteWord(0x01);
		WriteWord(0x03);
		
		WriteWord(0x02);
		WriteWord(0x01);
		
		WriteWord(0x03);
		WriteWord(0x01);
		
		WriteWord(0x04);
		WriteWord(0x01);
		
		WriteWord(0x06);
		WriteWord(0x01);
		
		WriteWord(0x09);
		WriteWord(0x01);
		
		WriteWord(0x0A);
		WriteWord(0x01);
		
		WriteWord(0x13);
		WriteWord(0x04);
		
		WriteWord(0x15);
		WriteWord(0x01);
	}
	else if(StrEqual(sCommand, "CLI_REQ_SELFINFO"))
	{
		WriteSNACHeader(0x01, 0x0E);
	}
	else if(StrEqual(sCommand, "CLI_FAMILIES_VERSIONS"))
	{
		WriteSNACHeader(0x01, 0x17);
		
		WriteWord(0x01);
		WriteWord(0x03);
		
		WriteWord(0x02);
		WriteWord(0x01);
		
		WriteWord(0x03);
		WriteWord(0x01);
		
		WriteWord(0x04);
		WriteWord(0x01);
		
		WriteWord(0x06);
		WriteWord(0x01);
		
		WriteWord(0x09);
		WriteWord(0x01);
		
		WriteWord(0x0A);
		WriteWord(0x01);
		
		WriteWord(0x13);
		WriteWord(0x04);
		
		WriteWord(0x15);
		WriteWord(0x01);
	}
	else if(StrEqual(sCommand, "CLI_SETxSTATUS"))
	{
		WriteSNACHeader(0x01, 0x1E);
		
		WriteWord(g_iStatusFlags, false, true);
		WriteWord(g_iStatus, false, true);
		
		WriteTLV(0x06, g_sTempMetaPackage, g_iTempMetaPackageLength);
		ClearMetaPackage();
	}
	else if(StrEqual(sCommand, "CLI_SETxIDLExTIME"))
	{
		WriteSNACHeader(0x01, 0x11);
		WriteDWord(GetArrayCell(hArgs, 0)); // IDLE_SECS
	}
	
	// Location services (02)
	// Client use this SNAC to request location service parameters and limitations. Server should reply via SNAC(02,03). 
	else if(StrEqual(sCommand, "CLI_LOCATION_RIGHTS_REQ"))
	{
		WriteSNACHeader(0x02, 0x02);
	}
	else if(StrEqual(sCommand, "CLI_SET_LOCATION_INFO"))
	{
		WriteSNACHeader(0x02, 0x04);
		
		// http://iserverd.khstu.ru/oscar/capabilities.html
		// {09461349-4C7F-11D1-8222-444553540000} 
		// Client supports channel 2 extended, TLV(0x2711) based messages. Currently used only by ICQ clients. 
		// ICQ clients and clones use this GUID as message format sign. 
		// Trillian client use another GUID in channel 2 messages to implement its own message format 
		// (trillian doesn't use TLV(x2711) in SecureIM channel 2 messages!).
		WriteWord(0x0946, false, true);
		WriteWord(0x1349, false, true);
		WriteWord(0x4C7F, false, true);
		WriteWord(0x11D1, false, true);
		WriteWord(0x8222, false, true);
		WriteWord(0x4445, false, true);
		WriteWord(0x5354, false, true);
		WriteWord(0x0000, false, true);
		
		// Send file {09461343-4c7f-11d1-8222-444553540000}
		WriteWord(0x0946, false, true);
		WriteWord(0x1343, false, true);
		WriteWord(0x4C7F, false, true);
		WriteWord(0x11D1, false, true);
		WriteWord(0x8222, false, true);
		WriteWord(0x4445, false, true);
		WriteWord(0x5354, false, true);
		WriteWord(0x0000, false, true);
		
		// Chat {748f2420-6287-11d1-8222-444553540000}
		WriteWord(0x748f, false, true);
		WriteWord(0x2420, false, true);
		WriteWord(0x6287, false, true);
		WriteWord(0x11D1, false, true);
		WriteWord(0x8222, false, true);
		WriteWord(0x4445, false, true);
		WriteWord(0x5354, false, true);
		WriteWord(0x0000, false, true);
		
		WriteTLV(0x05, g_sTempMetaPackage, g_iTempMetaPackageLength);
		ClearMetaPackage();
	}
	else if(StrEqual(sCommand, "CLI_GET_ONLINE_USER_INFO"))
	{
		WriteSNACHeader(0x02, 0x15);
		
		// TODO
	}
	
	// Buddy List management service (03)
	// Request rights information for buddy service.
	else if(StrEqual(sCommand, "CLI_BUDDYLIST_RIGHTS_REQ"))
	{
		WriteSNACHeader(0x03, 0x02);
	}
	else if(StrEqual(sCommand, "CLI_BUDDYLIST_REMOVE"))
	{
		WriteSNACHeader(0x03, 0x05);
		
		// TODO
	}
	else if(StrEqual(sCommand, "CLI_BUDDYLIST_ADD"))
	{
		WriteSNACHeader(0x03, 0x04);
		
		// List of B-UIN
		// B-UIN is a BYTE preceded STRING: the byte indicates the length of the string and the string report an uin number
	}
	
	// ICBM service (04)
	else if(StrEqual(sCommand, "CLI_SEND_ICBM_CH1"))
	{
		decl String:sUIN[32], String:sMsg[512];
		GetArrayString(hArgs, 0, sUIN, sizeof(sUIN));
		GetArrayString(hArgs, 1, sMsg, sizeof(sMsg));
		
		/*WriteByte(0x01, true);
		WriteTLV(0x0501, g_sTempMetaPackage, g_iTempMetaPackageLength);
		Format(g_sTempMetaPackage, sizeof(g_sTempMetaPackage), "");
		g_iTempMetaPackageLength = 0;
		
		WriteWord(0x0000, true, true);
		WriteWord(0x0000, true, true);
		for(new i=0;i<strlen(sMsg);i++)
		{
			g_sTempMetaPackage[g_iTempMetaPackageLength+i] = sMsg[i]; // Message text
		}
		g_iTempMetaPackageLength += strlen(sMsg);
		WriteTLV(0x0101, g_sTempMetaPackage, g_iTempMetaPackageLength);
		
		// Put the prepacked message into the meta buffer
		for(new i=0;i<g_iTempCurrentPackageLength;i++)
		{
			g_sTempMetaPackage[i] = g_sTempCurrentPackage[i];
		}
		g_iTempMetaPackageLength = g_iTempCurrentPackageLength;
		
		Format(g_sTempCurrentPackage, sizeof(g_sTempCurrentPackage), "");
		g_iTempCurrentPackageLength = 0;*/
		
		
		
		WriteSNACHeader(0x04, 0x06);
		WriteDWord(GetTime());
		WriteDWord(NewRequestID("CLI_SEND_ICBM_CH1")); // Message id cookie
		WriteWord(0x0001); // Message channel-id
		WriteByte(strlen(sUIN));
		for(new i=0;i<strlen(sUIN);i++)
		{
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = sUIN[i];
		}
		g_iTempCurrentPackageLength += strlen(sUIN);
		
		WriteByte(0x05, true); // Fragment identifier
		WriteByte(0x01, true); // Fragment version
		
		WriteWord(1, false, true);
		g_sTempMetaPackage[g_iTempMetaPackageLength] = 0x01;
		g_iTempMetaPackageLength++; // Byte array of required capabilities (1 - text)
		
		WriteByte(0x01, true); // Fragment identifier
		WriteByte(0x01, true); // Fragment version
		
		WriteWord(strlen(sMsg)+4, false, true);
		WriteWord(0x00, false, true); // Message charset number
		WriteWord(0x00, false, true); // Message language number
		for(new i=0;i<strlen(sMsg);i++)
		{
			g_sTempMetaPackage[g_iTempMetaPackageLength+i] = sMsg[i]; // Message text
		}
		g_iTempMetaPackageLength += strlen(sMsg);
		
		WriteTLV(0x02, g_sTempMetaPackage, g_iTempMetaPackageLength);
		Format(g_sTempMetaPackage, sizeof(g_sTempMetaPackage), "");
		g_iTempMetaPackageLength = 0;
		WriteTLV(0x06, "", 0);
	}
	else if(StrEqual(sCommand, "CLI_SEND_ICBM_CH2_FILE"))
	{
		decl String:sUIN[32], iCookie[8], iIP, iPort;
		GetArrayString(hArgs, 0, sUIN, sizeof(sUIN));
		GetArrayArray(hArgs, 1, iCookie, 8);
		iIP = GetArrayCell(hArgs, 2);
		iPort = GetArrayCell(hArgs, 3);
		
		WriteSNACHeader(0x04, 0x06);
		// Write cookie
		for(new i=0;i<8;i++)
		{
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = iCookie[i];
		}
		g_iTempCurrentPackageLength += 8;
		
		WriteWord(0x0002); // Message channel-id
		WriteByte(strlen(sUIN));
		for(new i=0;i<strlen(sUIN);i++)
		{
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = sUIN[i];
		}
		g_iTempCurrentPackageLength += strlen(sUIN);
		
		
		
		// Message type
		WriteWord(0x0000, false, true);
		
		// Write cookie again
		for(new i=0;i<8;i++)
		{
			g_sTempMetaPackage[g_iTempMetaPackageLength+i] = iCookie[i];
		}
		g_iTempMetaPackageLength += 8;
		
		// Write the send file capability
		WriteWord(0x0946, false, true);
		WriteWord(0x1343, false, true);
		WriteWord(0x4C7F, false, true);
		WriteWord(0x11D1, false, true);
		WriteWord(0x8222, false, true);
		WriteWord(0x4445, false, true);
		WriteWord(0x5354, false, true);
		WriteWord(0x0000, false, true);
		
		decl String:sBuffer[64];
		// Request number is now 2
		Int2Bytes(2, 0x0002, sBuffer, sizeof(sBuffer));
		WriteTLV(0x000A, sBuffer, 2, true);
		
		// proxy ip
		Int2Bytes(4, iIP, sBuffer, sizeof(sBuffer));
		WriteTLV(0x0002, sBuffer, 4, true);
		
		// proxy ip check
		Int2Bytes(4, iIP^0xffffffff, sBuffer, sizeof(sBuffer));
		WriteTLV(0x0016, sBuffer, 4, true);
		
		// proxy port check
		Int2Bytes(2, iPort, sBuffer, sizeof(sBuffer));
		WriteTLV(0x0005, sBuffer, 2, true);
		
		// proxy port check check
		Int2Bytes(2, iPort^0xffff, sBuffer, sizeof(sBuffer));
		WriteTLV(0x0017, sBuffer, 2, true);
		
		// proxy flag
		WriteTLV(0x0010, "", 0, true);
		
		// request ssl connection?
		WriteTLV(0x0011, "", 0, true);
		
		// maximum protocol version
		Int2Bytes(2, 0x0002, sBuffer, sizeof(sBuffer));
		WriteTLV(0x0012, sBuffer, 2, true);
		
		WriteTLV(0x05, g_sTempMetaPackage, g_iTempMetaPackageLength);
		Format(g_sTempMetaPackage, sizeof(g_sTempMetaPackage), "");
		g_iTempMetaPackageLength = 0;
		WriteTLV(0x06, "", 0);
		
		bDebugPackage = true;
	}
	else if(StrEqual(sCommand, "CLI_ICBM_PARAM_REQ"))
	{
		WriteSNACHeader(0x04, 0x04);
		
	}
	else if(StrEqual(sCommand, "CLI_SETICBM"))
	{
		WriteSNACHeader(0x04, 0x02);
		
		// Unknown
		WriteWord(0x0000);
		WriteWord(0x0000);
		WriteWord(0x0003);
		WriteWord(0x1F40);
		WriteWord(0x03E7);
		WriteWord(0x03E7);
		WriteWord(0x0000);
		WriteWord(0x0000);
	}
	
	// Privacy management service
	else if(StrEqual(sCommand, "CLI_PRIVACY_RIGHTS_REQ"))
	{
		WriteSNACHeader(0x09, 0x02);
	}
	
	// Server Side Information (SSI) service
	else if(StrEqual(sCommand, "CLI_SSI_RIGHTS_REQUEST"))
	{
		WriteSNACHeader(0x13, 0x02);
	}
	else if(StrEqual(sCommand, "CLI_SSI_REQUEST"))
	{
		WriteSNACHeader(0x13, 0x04);
	}
	else if(StrEqual(sCommand, "CLI_SSI_ACTIVATE"))
	{
		WriteSNACHeader(0x13, 0x07);
	}
	else if(StrEqual(sCommand, "CLI_SSIxADD_BUDDY"))
	{
		WriteSNACHeader(0x13, 0x08);
		
		decl String:sUIN[32];
		GetArrayString(hArgs, 0, sUIN, sizeof(sUIN));
		
		WriteWord(strlen(sUIN));
		for(new i=0;i<strlen(sUIN);i++)
		{
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = sUIN[i];
		}
		g_iTempCurrentPackageLength += strlen(sUIN);
		
		WriteWord(GetArrayCell(hArgs, 1)); // Group ID#
		WriteWord(0x0000); // Item ID#
		WriteWord(0x0000); // Type of item flag (buddy)
		WriteWord(0x0000); // length of additional data
	}
	else if(StrEqual(sCommand, "CLI_SSIxDELETE_BUDDY"))
	{
		WriteSNACHeader(0x13, 0x0A);
		
		decl String:sUIN[32];
		GetArrayString(hArgs, 0, sUIN, sizeof(sUIN));
		
		new Handle:hBuddy;
		GetTrieValue(g_hContactList, sUIN, hBuddy);
		
		new iBuddyID, iGroupID;
		GetTrieValue(hBuddy, "buddy_id", iBuddyID);
		GetTrieValue(hBuddy, "group_id", iGroupID);
		
		WriteWord(strlen(sUIN));
		for(new i=0;i<strlen(sUIN);i++)
		{
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = sUIN[i];
		}
		g_iTempCurrentPackageLength += strlen(sUIN);
		WriteWord(iGroupID); // Group ID#
		WriteWord(iBuddyID); // Item ID#
		WriteWord(0x0000); // Type of item flag (buddy)
		WriteWord(0x0000); // length of additional data
		
	}
	else if(StrEqual(sCommand, "CLI_SSI_EDIT_BEGIN"))
	{
		WriteSNACHeader(0x13, 0x11);
	}
	else if(StrEqual(sCommand, "CLI_SSI_EDIT_END"))
	{
		WriteSNACHeader(0x13, 0x12);
	}
	
	// ICQ specific extensions service
	else if(StrEqual(sCommand, "CLI_META"))
	{
		// Read the "Arguments"
		decl String:sMReqType[32];
		GetArrayString(hArgs, 0, sMReqType, sizeof(sMReqType));
		
		WriteDWord(StringToInt(g_sUID), true, true);
		
		new iReqSubType;
		
		if(StrEqual(sMReqType, "CLI_OFFLINE_MESSAGE_REQ"))
		{
			WriteWord(0x003C, true, true); // request type
			WriteWord(g_iMetaSequence, true, true);
		}
		else if(StrEqual(sMReqType, "CLI_DELETE_OFFLINE_MSGS_REQ"))
		{
			WriteWord(0x003E, true, true); // request type
			WriteWord(g_iMetaSequence, true, true);
		}
		else if(StrEqual(sMReqType, "USER_INFO"))
		{
			WriteWord(0x07D0, true, true); // request type
			WriteWord(g_iMetaSequence, true, true);
			
			decl String:sMReqSubType[32];
			GetArrayString(hArgs, 1, sMReqSubType, sizeof(sMReqSubType));
			
			if(StrEqual(sMReqSubType, "SET_BASIC"))
			{
				iReqSubType = 0x03EA;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "SET_WORK"))
			{
				iReqSubType = 0x03F3;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "SET_MORE"))
			{
				iReqSubType = 0x03FD;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "SET_NOTES"))
			{
				iReqSubType = 0x0406;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "SET_EMAIL"))
			{
				iReqSubType = 0x040B;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "SET_INTERESTS"))
			{
				iReqSubType = 0x0410;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "SET_PERMS"))
			{
				WriteWord(0x0424, true, true); // subtype
				
				WriteByte(0x1, true); // auth
				WriteByte(0x0, true); // webaware
				WriteByte(0x2, true); // DC: 0-any, 1-contact, 2-authorization
				WriteByte(0x00, true); // unknown
			}
			else if(StrEqual(sMReqSubType, "SET_PASSWORD"))
			{
				iReqSubType = 0x042E;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "REQ_FULLINFO"))
			{
				WriteWord(0x04B2, true, true); // subtype
				
				decl String:sUIN[32];
				GetArrayString(hArgs, 2, sUIN, sizeof(sUIN));
				
				WriteDWord(StringToInt(sUIN), true, true);
				
				new iPair[2];
				iPair[0] = StringToInt(sUIN);
				iPair[1] = g_iMetaSequence;
				PushArrayArray(g_hMetaRequests, iPair, 2);
			}
			else if(StrEqual(sMReqSubType, "CLI_SHORTINFO_REQUEST"))
			{
				WriteWord(0x04BA, true, true); // subtype
				
				decl String:sUIN[32];
				GetArrayString(hArgs, 2, sUIN, sizeof(sUIN));
				
				WriteDWord(StringToInt(sUIN), true, true);
				
				new iPair[2];
				iPair[0] = StringToInt(sUIN);
				iPair[1] = g_iMetaSequence;
				PushArrayArray(g_hMetaRequests, iPair, 2);
			}
			else if(StrEqual(sMReqSubType, "REQ_SELF_FULLINFO"))
			{
				iReqSubType = 0x04D0;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "UNREGISTER"))
			{
				iReqSubType = 0x04C4;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "FIND_BY_DETAILS"))
			{
				iReqSubType = 0x0515;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "FIND_BY_UIN"))
			{
				iReqSubType = 0x051F;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "FIND_BY_EMAIL"))
			{
				iReqSubType = 0x0529;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "FIND_BY_UIN_TLV"))
			{
				iReqSubType = 0x051F;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "WHITEPAGES_TLV"))
			{
				iReqSubType = 0x055F;
				// TODO
			}
			else if(StrEqual(sMReqSubType, "FIND_BY_EMAIL_TLV"))
			{
				iReqSubType = 0x0529;
				// TODO
			}
		}
		
		WriteSNACHeader(0x15, 0x02);
		
		// Length - Value..
		decl String:sBuffer[5];
		new iLength = Int2Bytes(2, g_iTempMetaPackageLength, sBuffer, sizeof(sBuffer));
		
		// Shift array up by length
		for(new i=g_iTempMetaPackageLength-1;i>=0;i--)
		{
			g_sTempMetaPackage[i+iLength] = g_sTempMetaPackage[i];
		}
		for(new i=0;i<iLength;i++)
			g_sTempMetaPackage[i] = sBuffer[iLength-i-1];
		
		WriteTLV(0x01, g_sTempMetaPackage, g_iTempMetaPackageLength+iLength);
		
		ClearMetaPackage();
		
		UpdateSequenceNumber(g_iMetaSequence);
	}
	
	// Authorization/registration service
	// Does not work.
#if defined USE_MD5_LOGIN
	else if(StrEqual(sCommand, "CLI_MD5_LOGIN"))
	{
		WriteSNACHeader(0x17, 0x02);
		
		WriteTLV(0x01, g_sUID, strlen(g_sUID));
		
		WriteTLV(0x03, CLIENT_ID_STRING, strlen(CLIENT_ID_STRING)); // Client id string (name, version)
		
		new String:sBuffer[128], String:sAuthKey[32], String:sMD5Password[17];
		GetArrayString(hArgs, 0, sAuthKey, sizeof(sAuthKey));
		Format(sBuffer, sizeof(sBuffer), "%s%sAOL Instant Messenger (SM)", sAuthKey, g_sPassword);
		MD5String(sBuffer, sMD5Password, sizeof(sMD5Password));
		WriteTLV(0x25, sMD5Password, 16);
		
		
		new iLength = Int2Bytes(2, CLIENT_ID, sBuffer, sizeof(sBuffer));
		WriteTLV(0x16, sBuffer, iLength); // Client id number			(e.g. "234")
		
		iLength = Int2Bytes(2, CLIENT_MAJOR, sBuffer, sizeof(sBuffer));
		WriteTLV(0x17, sBuffer, iLength); // Client major version 	(e.g. "0")
		
		iLength = Int2Bytes(2, CLIENT_MINOR, sBuffer, sizeof(sBuffer));
		WriteTLV(0x18, sBuffer, iLength); // Client minor version		(e.g. "2")
		
		iLength = Int2Bytes(2, CLIENT_LESSER, sBuffer, sizeof(sBuffer));
		WriteTLV(0x19, sBuffer, iLength); // Client lesser version 	(e.g  "1")
		
		iLength = Int2Bytes(2, CLIENT_BUILD, sBuffer, sizeof(sBuffer));
		WriteTLV(0x1A, sBuffer, iLength); // Client build number 		(e.g. "1")
		
		iLength = Int2Bytes(4, 85, sBuffer, sizeof(sBuffer));
		WriteTLV(0x14, sBuffer, iLength); // Distribution number
		
		WriteTLV(0x0F, CLIENT_LANGUAGE, strlen(CLIENT_LANGUAGE)); // Client language			(e.g. "en" or "ru")
		WriteTLV(0x0E, CLIENT_COUNTRY, strlen(CLIENT_COUNTRY)); // Client country			(e.g. "en" or "ru")
		
		iLength = Int2Bytes(1, 1, sBuffer, sizeof(sBuffer));
		WriteTLV(0x4A, sBuffer, iLength); // SSI use flag
	}
	else if(StrEqual(sCommand, "CLI_AUTH_REQUEST"))
	{
		WriteSNACHeader(0x17, 0x06);
		
		WriteTLV(0x0001, g_sUID, strlen(g_sUID));
		
		WriteTLV(0x004B, "", 0);
		WriteTLV(0x005A, "", 0);
	}
#endif
	
	else
		return;
		
	if(hArgs != INVALID_HANDLE)
		CloseHandle(hArgs);
	
	new String:sPacket[8192];
	GenerateFLAPHeader(iChannel, g_iTempCurrentPackageLength, sPacket, sizeof(sPacket));
	for(new i=0; i<g_iTempCurrentPackageLength;i++)
	{
		sPacket[6+i] = g_sTempCurrentPackage[i];
	}
	
	PrintToServer("Sending %s on channel %d (length: %d): %s", sCommand, iChannel, g_iTempCurrentPackageLength+6, g_sTempCurrentPackage);
	
	
	SocketSend(g_hSocket, sPacket, g_iTempCurrentPackageLength+6);
	if(bDebugPackage)
	{
		for(new i=0;i<g_iTempCurrentPackageLength+6;i++)
		{
			PrintToServer("%02x (%d): %08b", _:sPacket[i]&0xff, _:sPacket[i]&0xff, _:sPacket[i]&0xff);
		}
	}
	
	Format(g_sTempCurrentPackage, sizeof(g_sTempCurrentPackage), "");
	g_iTempCurrentPackageLength = 0;
	ClearMetaPackage();
	
	UpdateSequenceNumber(g_iOutgoingSequence);
}

stock GetAuthErrorString(iErrorCode, String:sError[], maxlen)
{
	switch(iErrorCode)
	{
		case 0x0001:
			Format(sError, maxlen, "Invalid nick or password");
		case 0x0002:
			Format(sError, maxlen, "Service temporarily unavailable");
		case 0x0003:
			Format(sError, maxlen, "All other errors");
		case 0x0004:
			Format(sError, maxlen, "Incorrect nick or password, re-enter");
		case 0x0005:
			Format(sError, maxlen, "Mismatch nick or password, re-enter");
		case 0x0006:
			Format(sError, maxlen, "Internal client error (bad input to authorizer)");
		case 0x0007:
			Format(sError, maxlen, "Invalid account");
		case 0x0008:
			Format(sError, maxlen, "Deleted account");
		case 0x0009:
			Format(sError, maxlen, "Expired account");
		case 0x000A:
			Format(sError, maxlen, "No access to database");
		case 0x000B:
			Format(sError, maxlen, "No access to resolver");
		case 0x000C:
			Format(sError, maxlen, "Invalid database fields");
		case 0x000D:
			Format(sError, maxlen, "Bad database status");
		case 0x000E:
			Format(sError, maxlen, "Bad resolver status");
		case 0x000F:
			Format(sError, maxlen, "Internal error");
		case 0x0010:
			Format(sError, maxlen, "Service temporarily offline");
		case 0x0011:
			Format(sError, maxlen, "Suspended account");
		case 0x0012:
			Format(sError, maxlen, "DB send error");
		case 0x0013:
			Format(sError, maxlen, "DB link error");
		case 0x0014:
			Format(sError, maxlen, "Reservation map error");
		case 0x0015:
			Format(sError, maxlen, "Reservation link error");
		case 0x0016:
			Format(sError, maxlen, "The users num connected from this IP has reached the maximum");
		case 0x0017:
			Format(sError, maxlen, "The users num connected from this IP has reached the maximum (reservation)");
		case 0x0018:
			Format(sError, maxlen, "Rate limit exceeded (reservation). Please try to reconnect in a few minutes");
		case 0x0019:
			Format(sError, maxlen, "User too heavily warned");
		case 0x001A:
			Format(sError, maxlen, "Reservation timeout");
		case 0x001B:
			Format(sError, maxlen, "You are using an older version of ICQ. Upgrade required");
		case 0x001C:
			Format(sError, maxlen, "You are using an older version of ICQ. Upgrade recommended");
		case 0x001D:
			Format(sError, maxlen, "Rate limit exceeded. Please try to reconnect in a few minutes");
		case 0x001E:
			Format(sError, maxlen, "Can't register on the ICQ network. Reconnect in a few minutes");
		case 0x0020:
			Format(sError, maxlen, "Invalid SecurID");
		case 0x0022:
			Format(sError, maxlen, "Account suspended because of your age (age < 13)");
		default:
			Format(sError, maxlen, "Unknown error.. (%02x)", iErrorCode);
	}
}

stock WriteTLV(iType, String:sValue[], length, bool:bMeta = false)
{
	WriteWord(iType, false, bMeta);
	WriteWord(length, false, bMeta);
	for(new i=0; i<length;i++)
	{
		if(bMeta)
			g_sTempMetaPackage[g_iTempMetaPackageLength+i] = sValue[i];
		else
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = sValue[i];
	}
	if(bMeta)
		g_iTempMetaPackageLength += length;
	else
		g_iTempCurrentPackageLength += length;
}

stock WriteByte(iValue,bool:bMeta = false)
{
	new String:sValue[65];
	new iLength = Int2Bytes(1, iValue, sValue, sizeof(sValue));
	for(new i=0; i<iLength;i++)
	{
		if(bMeta)
			g_sTempMetaPackage[g_iTempMetaPackageLength+i] = sValue[i];
		else
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = sValue[i];
	}
	if(bMeta)
		g_iTempMetaPackageLength += iLength;
	else
		g_iTempCurrentPackageLength += iLength;
}

stock WriteWord(iValue, bool:bReverse = false, bool:bMeta = false)
{
	new String:sValue[65];
	new iLength = Int2Bytes(2, iValue, sValue, sizeof(sValue));
	
	for(new i=0; i<iLength;i++)
	{
		if(bMeta)
			g_sTempMetaPackage[g_iTempMetaPackageLength+i] = sValue[(bReverse?iLength-1-i:i)];
		else
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = sValue[(bReverse?iLength-1-i:i)];
	}
	if(bMeta)
		g_iTempMetaPackageLength += iLength;
	else
		g_iTempCurrentPackageLength += iLength;
}

stock WriteDWord(iValue, bool:bReverse = false, bool:bMeta = false)
{
	new String:sValue[65];
	new iLength = Int2Bytes(4, iValue, sValue, sizeof(sValue));
	for(new i=0; i<iLength;i++)
	{
		if(bMeta)
			g_sTempMetaPackage[g_iTempMetaPackageLength+i] = sValue[(bReverse?iLength-1-i:i)];
		else
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = sValue[(bReverse?iLength-1-i:i)];
	}
	if(bMeta)
		g_iTempMetaPackageLength += iLength;
	else
		g_iTempCurrentPackageLength += iLength;
}

stock WriteQWord(iValue, bool:bReverse = false, bool:bMeta = false)
{
	new String:sValue[65];
	new iLength = Int2Bytes(8, iValue, sValue, sizeof(sValue));
	for(new i=0; i<iLength;i++)
	{
		if(bMeta)
			g_sTempMetaPackage[g_iTempMetaPackageLength+i] = sValue[(bReverse?iLength-1-i:i)];
		else
			g_sTempCurrentPackage[g_iTempCurrentPackageLength+i] = sValue[(bReverse?iLength-1-i:i)];
	}
	if(bMeta)
		g_iTempMetaPackageLength += iLength;
	else
		g_iTempCurrentPackageLength += iLength;
}

stock Int2Bytes(iLength=-1, iValue=0x00, String:sOutput[], maxlen, iOffset=0)
{
	// Clear the output buffer.
	if(iOffset == 0)
		Format(sOutput, maxlen, "");
	
	// Convert to hex
	decl String:sValue[65];
	Format(sValue, sizeof(sValue), "%x", iValue);
	
	if(iLength == -1)
	{
		if(strlen(sValue) % 2)
			Format(sValue, sizeof(sValue), "0%s", sValue);
	}
	else
	{
		new iTemp = iLength*2 - strlen(sValue);
		for(new i=0;i<iTemp;i++)
		{
			Format(sValue, sizeof(sValue), "0%s", sValue);
		}
	}
	
	new iBytes = strlen(sValue)/2;
	new String:sBuffer[10];
	new iTemp;
	for(new i=0;i<iBytes;i++)
	{
		Format(sBuffer, 3, "%s", sValue[i*2]);
		iTemp = StringToInt(sBuffer, 16);
		Format(sBuffer, sizeof(sBuffer), "%c", iTemp);
		//PrintToServer("%d: %s", iTemp, sBuffer);
		sOutput[iOffset+i] = iTemp;
		//Format(sOutput, maxlen, "%s%c", sOutput, iTemp);
	}
	
	sOutput[iOffset+iBytes] = '\0';
	
	//PrintToServer("%s: %s", sOutput, sValue);
	
	return iBytes;
}

stock Bytes2Int(const String:sValue[], iLength, iOffset=0, bool:bReverse = false)
{
	new iDec = 0;

	for(new i=0;i<iLength;i++)
	{
		iDec <<= 8;
		if(bReverse)
			iDec |= sValue[iOffset+iLength-1-i];
		else
			iDec |= sValue[iOffset+i];
	}
	return iDec;
}

ClearMetaPackage()
{
	Format(g_sTempMetaPackage, sizeof(g_sTempMetaPackage), "");
	g_iTempMetaPackageLength = 0;
}

stock XOREncryptPassword(String:sPassword[], String:sEncrypted[])
{
	new iLength = strlen(sPassword);
	// We can't encrypt more chars than we have bytes in the sequence
	if(iLength > sizeof(g_iXORSeq))
		iLength = sizeof(g_iXORSeq);
	
	for(new i=0; i<iLength; i++)
	{
		sEncrypted[i] = g_iXORSeq[i] ^ sPassword[i];
	}
	sEncrypted[iLength] = '\0';
}

ParseTLV(Handle:hTLV, const String:sData[], const length)
{
	new iType, iLength;
	new iProcessed = 0;
	new Handle:hPart;
	while (iProcessed < length)
	{
		iType = sData[iProcessed+1] + (sData[iProcessed]<<8);
		iLength = sData[iProcessed+3] + (sData[iProcessed+2]<<8);
		
		decl iInfo[iLength];
		for(new i=0; i<iLength; i++)
			iInfo[i] = sData[iProcessed+4+i];
		hPart = CreateArray(ByteCountToCells(1024));
		PushArrayCell(hPart, iType);
		PushArrayCell(hPart, iLength);
		PushArrayArray(hPart, iInfo, iLength);
		
		PushArrayCell(hTLV, hPart);
		
		iProcessed += 4+iLength;
	}
}

CloseTLVArray(Handle:hTLV)
{
	new iSize = GetArraySize(hTLV);
	for(new i=0;i<iSize;i++)
		CloseHandle(GetArrayCell(hTLV, i));
	CloseHandle(hTLV);
}

bool:GetTLVString(Handle:hTLV, iType, String:sValue[], maxlen, &iLength)
{
	sValue[0] = '\0';
	iLength = 0;
	
	new iSize = GetArraySize(hTLV);
	new Handle:hPart, iDataLength;
	for(new i=0;i<iSize;i++)
	{
		hPart = GetArrayCell(hTLV, i);
		if(GetArrayCell(hPart, 0) == iType)
		{
			iDataLength = GetArrayCell(hPart, 1);
			new iValue[iDataLength];
			GetArrayArray(hPart, 2, iValue, iDataLength);
			
			for(new c=0;c<iDataLength;c++)
			{
				// Can't get more..
				if(c >= maxlen)
					break;
				
				sValue[c] = iValue[c];
			}
			if(iDataLength < maxlen)
				sValue[iDataLength] = '\0';
			else
				sValue[maxlen-1] = '\0';
			
			iLength = iDataLength;
			
			// Remove the read part from the TLV. Needed in message type 2, as there are 2 TLV with type 0x0005..
			CloseHandle(hPart);
			RemoveFromArray(hTLV, i);
			
			return true;
		}
	}
	return false;
}

WriteProxyRendezvousHeader(String:sPackage[], iLength, iCommand)
{
	decl String:sBuffer[13];
	Int2Bytes(2, iLength+10, sBuffer, sizeof(sBuffer));
	Int2Bytes(2, 0x044a, sBuffer, sizeof(sBuffer), 2);
	Int2Bytes(2, iCommand, sBuffer, sizeof(sBuffer), 4);
	Int2Bytes(4, 0, sBuffer, sizeof(sBuffer), 6);
	Int2Bytes(2, 0, sBuffer, sizeof(sBuffer), 10);
	
	for(new i=iLength;i>=0;i--)
	{
		sPackage[i+12] = sPackage[i];
	}
	
	for(new i=0;i<12;i++)
	{
		sPackage[i] = sBuffer[i];
	}
}

public ProxySocket_OnConnect(Handle:socket, any:arg)
{
	new Handle:hProxy = GetArrayCell(g_hProxyInfo, arg);
	
	// Send the initialize send command to the proxy
	decl String:sPackage[129];
	//GetTrieString(hProxy, "target_uin", sTargetUIN, sizeof(sTargetUIN));
	Int2Bytes(1, strlen(g_sUID), sPackage, sizeof(sPackage));
	new iOffset = 1;
	for(new i=0;i<strlen(g_sUID);i++)
	{
		sPackage[i+iOffset] = g_sUID[i];
	}
	iOffset += strlen(g_sUID);
	
	// icbm cookie
	decl iCookie[8];
	GetTrieArray(hProxy, "cookie", iCookie, 8);
	for(new i=0;i<8;i++)
	{
		sPackage[i+iOffset] = iCookie[i];
	}
	iOffset += 8;
	
	// Send File Capability TLV
	Int2Bytes(2, 0x0001, sPackage, sizeof(sPackage), iOffset);
	iOffset += 2;
	Int2Bytes(2, 0x0010, sPackage, sizeof(sPackage), iOffset);
	iOffset += 2;
	Int2Bytes(2, 0x0946, sPackage, sizeof(sPackage), iOffset);
	iOffset += 2;
	Int2Bytes(2, 0x1343, sPackage, sizeof(sPackage), iOffset);
	iOffset += 2;
	Int2Bytes(2, 0x4C7F, sPackage, sizeof(sPackage), iOffset);
	iOffset += 2;
	Int2Bytes(2, 0x11D1, sPackage, sizeof(sPackage), iOffset);
	iOffset += 2;
	Int2Bytes(2, 0x8222, sPackage, sizeof(sPackage), iOffset);
	iOffset += 2;
	Int2Bytes(2, 0x4445, sPackage, sizeof(sPackage), iOffset);
	iOffset += 2;
	Int2Bytes(2, 0x5354, sPackage, sizeof(sPackage), iOffset);
	iOffset += 2;
	Int2Bytes(2, 0x0000, sPackage, sizeof(sPackage), iOffset);
	iOffset += 2;
	WriteProxyRendezvousHeader(sPackage, iOffset, 0x0002);
	SocketSend(socket, sPackage, iOffset+12);
}

public ProxySocket_OnReceive(Handle:socket, const String:receiveData[], const dataSize, any:arg)
{
	new Handle:hProxy = GetArrayCell(g_hProxyInfo, arg);
	new bool:bUseOFT;
	GetTrieValue(hProxy, "use_oft", bUseOFT);
	
	// We didn't do the proxy connection handshake yet.
	if(!bUseOFT)
	{
		new iLength = Bytes2Int(receiveData, 2);
		new iPackVer = Bytes2Int(receiveData, 2, 2);
		new iCmdType = Bytes2Int(receiveData, 2, 4);
		new iFlags = Bytes2Int(receiveData, 2, 10);
		
		PrintToServer("ProxyReceived. length: %d, packver: %04x, cmdtype: %04x, flags: %04x", iLength, iPackVer, iCmdType, iFlags);
		
		switch(iCmdType)
		{
			// Error
			case 0x0001:
			{
				new iErrCode = Bytes2Int(receiveData, 2, 12);
				PrintToServer("ErrorCode: %04x", iErrCode);
			}
			// Acknowledge
			case 0x0003:
			{
				new iPortCheck = Bytes2Int(receiveData, 2, 12);
				decl String:sProxyIP[33];
				Format(sProxyIP, sizeof(sProxyIP), "%d.%d.%d.%d", Bytes2Int(receiveData, 1, 14), Bytes2Int(receiveData, 1, 15), Bytes2Int(receiveData, 1, 16), Bytes2Int(receiveData, 1, 17));
				PrintToServer("Acknowledge received. portcheck: %d, ip: %s", iPortCheck, sProxyIP);
				
				new bool:bStage1Connection;
				GetTrieValue(hProxy, "stage1_proxy", bStage1Connection);
				if(!bStage1Connection)
				{
					// Send another rendevous request with the proxyflag set.
					new Handle:hArgs = CreateArray(33);
					decl String:sTargetUIN[17];
					GetTrieString(hProxy, "target_uin", sTargetUIN, sizeof(sTargetUIN));
					PushArrayString(hArgs, sTargetUIN);
					decl iCookie[8];
					GetTrieArray(hProxy, "cookie", iCookie, 8);
					PushArrayArray(hArgs, iCookie, 8);
					PushArrayCell(hArgs, Bytes2Int(receiveData, 4, 14));
					PushArrayCell(hArgs, iPortCheck);
					SendSNAC("CLI_SEND_ICBM_CH2_FILE", hArgs);
				}
			}
			// Ready
			case 0x0005:
			{
				PrintToServer("Proxy Ready!");
				SetTrieValue(hProxy, "use_oft", true);
				SetTrieValue(hProxy, "oft_receiving", false);
			}
		}
	}
	else
	{
		//PrintToServer("OFT!");
		/*for(new i=0;i<dataSize;i++)
		{
			PrintToServer("%02x (%d): %08b", _:receiveData[i]&0xff, _:receiveData[i]&0xff, _:receiveData[i]&0xff);
		}*/
		
		new bool:bIsReceiving;
		GetTrieValue(hProxy, "oft_receiving", bIsReceiving);
		
		if(!bIsReceiving)
		{
			decl String:sProtVer[5];
			Format(sProtVer, 5, "%s", receiveData);
			new iOffset = 4;
			new iLength = Bytes2Int(receiveData, 2, iOffset);
			iOffset += 2;
			new iType = Bytes2Int(receiveData, 2, iOffset);
			iOffset += 2;
			
			// cookie!
			iOffset += 8;
			
			new iEncrypt = Bytes2Int(receiveData, 2, iOffset);
			iOffset += 2;
			
			new iComp = Bytes2Int(receiveData, 2, iOffset);
			iOffset += 2;
			
			new iTotFil = Bytes2Int(receiveData, 2, iOffset);
			iOffset += 2;
			
			new iFilLft = Bytes2Int(receiveData, 2, iOffset);
			iOffset += 2;
			
			new iTotPrts = Bytes2Int(receiveData, 2, iOffset);
			iOffset += 2;
			
			new iPrtsLft = Bytes2Int(receiveData, 2, iOffset);
			iOffset += 2;
			
			new iTotSz = Bytes2Int(receiveData, 4, iOffset);
			iOffset += 4;
			
			new iSize = Bytes2Int(receiveData, 4, iOffset);
			iOffset += 4;
			
			new iModTime = Bytes2Int(receiveData, 4, iOffset);
			iOffset += 4;
			
			new iChecksum = Bytes2Int(receiveData, 4, iOffset);
			iOffset += 4;
			
			new iRfrcvCsum = Bytes2Int(receiveData, 4, iOffset);
			iOffset += 4;
			
			new iRfSize = Bytes2Int(receiveData, 4, iOffset);
			iOffset += 4;
			
			new iCreTime = Bytes2Int(receiveData, 4, iOffset);
			iOffset += 4;
			
			new iRfcSum = Bytes2Int(receiveData, 4, iOffset);
			iOffset += 4;
			
			new inRecvd = Bytes2Int(receiveData, 4, iOffset);
			iOffset += 4;
			
			new iRecvCsum = Bytes2Int(receiveData, 4, iOffset);
			iOffset += 4;
			
			// Unknown
			iOffset += 8;
			
			// IDString (Cool FileXfer)
			iOffset += 32;
			
			new iFlags = Bytes2Int(receiveData, 1, iOffset);
			iOffset += 1;
			
			new iNameOffs = Bytes2Int(receiveData, 1, iOffset);
			iOffset += 1;
			
			new iSizeOff = Bytes2Int(receiveData, 1, iOffset);
			iOffset += 1;
			
			// Dummy
			iOffset += 69;
			
			// MacFileInfo
			iOffset += 16;
			
			new iEncoding = Bytes2Int(receiveData, 2, iOffset);
			iOffset += 2;
			
			new iSubcode = Bytes2Int(receiveData, 2, iOffset);
			iOffset += 2;
			
			// Filename
			decl String:sFileName[iLength-191];
			for(new i=0;i<(iLength-192);i++)
			{
				sFileName[i] = receiveData[iOffset+i];
				if(receiveData[iOffset+i] == '\0')
					break;
			}
			
			PrintToServer("ProtVer: %s, Len: %d, Type: %04x, Encrypt: %04x, Comp: %04x, TotFil: %d, FilLft %d, TotPrts: %d, PrtsLeft: %d, TotSz: %d, Size: %d, ModTime: %d, Checksum: %08x, RfrcvCsum: %08x, Rfize: %d, CreTime: %d, RfCsum: %08x, nRecvd: %d, RecvCsum: %08x, Flags: %02x, NameOffs: %d, SizeOffs: %d, Encoding: %04x, Subcode: %04x, Filename: %s",
			sProtVer, iLength, iType, iEncrypt, iComp, iTotFil, iFilLft, iTotPrts, iPrtsLft, iTotSz, iSize, iModTime, iChecksum, iRfrcvCsum, iRfSize, iCreTime, iRfcSum, inRecvd, iRecvCsum, iFlags, iNameOffs, iSizeOff, iEncoding, iSubcode, sFileName);
			
			// Acknowledge the prompt.
			// Only changes the type.
			if(iType == 0x0101)
			{
				SetTrieValue(hProxy, "oft_filesize", iSize);
				decl String:sPath[PLATFORM_MAX_PATH];
				BuildPath(Path_SM, sPath, sizeof(sPath), "data/%s", sFileName);
				
				decl String:sPackage[dataSize];
				for(new i=0;i<dataSize;i++)
					sPackage[i] = receiveData[i];
				
				new Handle:hFile = OpenFile(sPath, "wb");
				if(hFile == INVALID_HANDLE)
				{
					Int2Bytes(2, 0x0204, sPackage, dataSize, 6);
					PrintToServer("can't create file in %s", sPath);
				}
				else
				{
					Int2Bytes(2, 0x0202, sPackage, dataSize, 6);
					SetTrieValue(hProxy, "oft_filehandle", hFile);
					SetTrieValue(hProxy, "oft_bytessaved", 0);
				}
				
				SetTrieArray(hProxy, "oft_request", _:sPackage, dataSize);
				SetTrieValue(hProxy, "oft_request_size", dataSize);
				SetTrieValue(hProxy, "oft_receiving", true);
				
				SocketSend(socket, sPackage, dataSize);
			}
		}
		// We're receiving raw binary stuff.
		else
		{
			new Handle:hFile, iBytesSaved, iSize;
			GetTrieValue(hProxy, "oft_filehandle", hFile);
			GetTrieValue(hProxy, "oft_bytessaved", iBytesSaved);
			GetTrieValue(hProxy, "oft_filesize", iSize);
			
			decl stuff[1];
			for(new i=0;i<dataSize;i++)
			{
				stuff[0] = _:receiveData[i]&0xff;
				WriteFile(hFile, stuff, 1, 1);
				iBytesSaved++;
			}
			
			SetTrieValue(hProxy, "oft_bytessaved", iBytesSaved);
			
			//PrintToServer("Received chunk of %d bytes. Now got %d/%d.", dataSize, iBytesSaved, iSize);
			
			if(iSize <= iBytesSaved)
			{
				new iRequestSize;
				GetTrieValue(hProxy, "oft_request_size", iRequestSize);
				decl String:sRequest[iRequestSize];
				GetTrieArray(hProxy, "oft_request", sRequest, iRequestSize);
				Int2Bytes(2, 0x0204, sRequest, iRequestSize, 6);
				SocketSend(socket, sRequest, iRequestSize);
				CloseHandle(hFile);
				
				if(iSize < iBytesSaved)
					PrintToServer("WRITTEN MORE THAN THERE SHOULD BE. %d > %d", iBytesSaved, iSize);
			}
		}
	}
}

public ProxySocket_OnDisconnect(Handle:socket, any:arg)
{
	new Handle:hProxy = GetArrayCell(g_hProxyInfo, arg);
	CloseHandle(hProxy);
	// FIXME: Will break, if multiple file transfers are running simultaneously.
	RemoveFromArray(g_hProxyInfo, arg);
}

public ProxySocket_OnError(Handle:socket, const errorType, const errorNum, any:arg)
{
	new Handle:hProxy = GetArrayCell(g_hProxyInfo, arg);
	CloseHandle(hProxy);
	RemoveFromArray(g_hProxyInfo, arg);
}