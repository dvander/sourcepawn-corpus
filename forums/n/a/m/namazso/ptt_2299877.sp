#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#define PLUGIN_VERSION "3.1.1"
#define PREFIX "[PTT] "

ConVar sm_ptt_refresh =		null;
ConVar sm_ptt_database =	null;
ConVar sm_ptt_table =		null;
ConVar sm_ptt_team =		null;
ConVar sm_ptt_version =		null;
ConVar sm_ptt_mode =		null;
Database hDatabase =		null;
Handle refreshTimer =		null;

char pttTable[128], pttDatabase[128];

public Plugin myinfo = 
{
	name = "Player Time Tracker (Redux)",
	author = "namazso",
	description = "Tracks how long players have played on your server(s).",
	version = PLUGIN_VERSION,
	url = "http://namazso.eu"
}

public void OnPluginStart()
{
	sm_ptt_version =	CreateConVar("sm_ptt_version2",	PLUGIN_VERSION,	"Player Time Tracker Version",					FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	sm_ptt_refresh =	CreateConVar("sm_ptt_refresh",	"5",			"Time (in seconds) between data updates.",		FCVAR_NOTIFY, true, 5.0, true, 60.0);
	sm_ptt_database =	CreateConVar("sm_ptt_database",	"default",		"Database (in databases.cfg) to use."			);
	sm_ptt_table =		CreateConVar("sm_ptt_table",	"time_tracker",	"Table in your SQL Database to use."			);
	sm_ptt_team =		CreateConVar("sm_ptt_team",		"1",			"Who to track: 0=all, 1=only those on a team.",	_, true, 0.0, true, 1.0);
	sm_ptt_mode = 		CreateConVar("sm_ptt_mode",		"0",			"Track mode: 0=on refresh, 1=on disconnect.",	_, true, 0.0, true, 1.0);
	
	RegConsoleCmd("sm_gettime",	Command_GetTime,	"Gets the total time in your servers of the client");
	RegConsoleCmd("sm_mytime",	Command_MyTime,		"Gets your time in the server.");
	
	AutoExecConfig(true, "plugin.ptt");
	
	sm_ptt_table.	GetString(pttTable,		sizeof(pttTable));
	sm_ptt_database.GetString(pttDatabase,	sizeof(pttDatabase));
	SQL_TConnect(DBConnect, pttDatabase);
	
	HookConVarChange(sm_ptt_refresh,	ModeChanged);
	HookConVarChange(sm_ptt_mode,		ModeChanged);
	ModeChanged(sm_ptt_version, "", "");		//last 2 arg is unused
}

// Get playtime of a player on the server
public Action Command_GetTime(int client, int args)
{
	static char arg1[65];
	GetCmdArg(1, arg1, sizeof(arg1));
	int target = FindTarget(client, arg1, true);
	if (target == -1)
		PrintToChat(client, "%sNo matching player online!", PREFIX);
	else
		TimeCommand(client, target);
	return Plugin_Handled;
}

// Get player's own playtime
public Action Command_MyTime(int client, int args)
{
	TimeCommand(client, client);
	return Plugin_Handled;
}

void TimeCommand(int client, int target)
{
	static char query[256], steamid[32];
	GetClientAuthId(target, AuthId_Steam2, steamid, sizeof(steamid));
	Format(query, sizeof(query), "SELECT time_played FROM %s WHERE steamid = '%s'", pttTable, steamid);
	DBCheckConnect();
	SQL_TQuery(hDatabase, TimeCommand_Callback, query, (client << 8) + target);
}

public void TimeCommand_Callback(Handle owner, Handle hQuery, const char[] error, any data)
{
	
	if (hQuery == INVALID_HANDLE)
		LogError("%sERROR: Problem with the TimeCommand query! Error: %s", PREFIX, error);
		
	int client = ((view_as<int>data) >> 8), target = ((view_as<int>data) - (((view_as<int>data) >> 8) << 8));
	static char name[65], time_str[32];
	
	if (SQL_FetchRow(hQuery))
	{
		int time_played = SQL_FetchInt(hQuery, 0);
		FormatTime(time_str, sizeof(time_str), ":%M:%S", time_played); // We need to do this ugly, because strftime would truncate hours over 24
		if(client != target)
			GetClientName(target, name, sizeof(name));
		else
			name = "You";
		PrintToChat(client, "%s%s played %d%s", PREFIX, name, time_played/3600, time_str);
	}
}


// Mode 1: Adds player time on disconnect. May cause crashes on many SM versions.
public void OnClientDisconnect(int client)
{
	if(sm_ptt_mode.IntValue != 0 && !IsFakeClient(client) && IsClientAuthorized(client))
		IncreaseClientTime(client, RoundToFloor(GetClientTime(client)));
}

// Mode 0: Adds player time on a frequency
public Action UpdateTimes(Handle timer)
{
	for(int i=1; i <= MaxClients && IsClientInGame(i); i++)
	{
		if (!IsFakeClient(i) && IsClientAuthorized(i) && !(sm_ptt_team.IntValue == 1 && GetClientTeam(i) < 2))
			IncreaseClientTime(i, sm_ptt_refresh.IntValue);
	}
	return Plugin_Continue;
}

// Performs increasing playtimes, and inserts if needed
public void IncreaseClientTime(int client, int time)
{
	static char name[65], escaped_name[128], steamid[32], query[256];
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid));
	SQL_EscapeString(hDatabase, name, escaped_name, sizeof(escaped_name));
	
	DBCheckConnect();
	Format(query, sizeof(query), "INSERT INTO %s (steamid, name, time_played) VALUES (\"%s\",\"%s\", %i) ON DUPLICATE KEY UPDATE name=VALUES(name),time_played=time_played+VALUES(time_played)", pttTable, steamid, escaped_name, time);
	SQL_TQuery(hDatabase, TQuery_Callback, query, 1);
}

// DB connection callback at plugins start
public void DBConnect(Handle owner, Handle hndl, const char[] error, any data)
{
	if (hndl == null)
	{
		LogError("%sDBConnect error! %s", PREFIX, error);
		return;
	}
	hDatabase = view_as<Database>hndl;
	
	char query[256];
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS `%s` (`name` varchar(64) CHARACTER SET utf8 NOT NULL, `steamid` varchar(64) NOT NULL, `time_played` int(64) NOT NULL, UNIQUE KEY `steamid` (`steamid`))", pttTable);
	SQL_TQuery(hDatabase, TQuery_Callback, query, 2);
}

// Check connection to the DB
public void DBCheckConnect()
{
	if(hDatabase != null)
		return;
	char error[256];
	hDatabase = SQL_Connect(pttDatabase, true, error, sizeof(error));
	if (hDatabase == null)
		LogError("%sDBCheckConnect error! %s", PREFIX, error);
}

// Called of refresh frequency or mode is called. Changing it is not recommended while running, as we may lose/get some time
public void ModeChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	CloseHandle(refreshTimer);
	if(sm_ptt_mode.IntValue == 0)
		refreshTimer = CreateTimer(sm_ptt_refresh.FloatValue, UpdateTimes, _, TIMER_REPEAT);
}

// Generic TQuery callback
public void TQuery_Callback(Handle owner, Handle hQuery, const char[] error, any data)
{
	if (hQuery == INVALID_HANDLE)
		LogError("%sERROR: Problem with the SQL query! Id: %i Error: %s", PREFIX, data, error);
	CloseHandle(hQuery);
}


// Insert into the table if not present
// New MySQL query replaced this
/*
public void OnClientPostAdminCheck(int client)
{
	if (IsFakeClient(client))
		return;
	
	static char name[65], auth[32], query[256], escaped_name[128];
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));
	SQL_EscapeString(hDatabase, name, escaped_name, sizeof(escaped_name));
	
	DBCheckConnect();
	Format(query, sizeof(query), "INSERT IGNORE INTO %s VALUES ('%s', '%s', '%i')", pttTable, escaped_name, auth, RoundToFloor(GetClientTime(client)));
	SQL_TQuery(hDatabase, QueryResponse, query, 0);
}*/


// TimeCommand replaced this
/*int GetPlayedTime(char[] steamid, char[] name, int namelen)
{
	char query[128];
	int time;
	
	Format(query, sizeof(query), "SELECT name, time_played FROM %s WHERE steamid = '%s'", pttTable, steamid);
	DBCheckConnect();
	Handle hQuery = SQL_Query(hDatabase, query);
	if (hQuery == null)
		LogError("[PTT] ERROR: Problem with the SQL query! (%s)", query);
	else
	{
		if (SQL_FetchRow(hQuery))
		{
			SQL_FetchString(hQuery, 0, name, namelen);
			time = SQL_FetchInt(hQuery, 1);
		}
		else
			time = -1;
	}
	CloseHandle(hQuery);
	return time;
}*/
