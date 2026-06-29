#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Scrim Clips", 
	author = "Kolapsicle", 
	description = "Stores timestamps in a database.", 
	version = "1.0.0"
};

ConVar g_cvDatabaseName, g_cvDate;
Database g_db;
int g_iRoundTick;

public void OnPluginStart()
{
	g_cvDatabaseName = CreateConVar("sm_sc_database_name", "scrim clips", "Database to use. Found in sourcemod/configs/databases.cfg");
	g_cvDate = CreateConVar("sm_sc_date_format", "%H:%M %d/%m/%y", "Date format to store. See http://www.cplusplus.com/reference/ctime/strftime");
	
	char dbName[32];
	GetConVarString(g_cvDatabaseName, dbName, sizeof(dbName));
	Database.Connect(ConnectCallback, dbName);
	
	HookEvent("round_start", Hook_RoundStart);
	RegConsoleCmd("sm_clip", Command_Clip);
	
	AutoExecConfig(true, "scrim_clips");
}

public Action Hook_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iRoundTick = GetGameTickCount();
}

public Action Command_Clip(int client, int args)
{
	if (!IsValidClient(client))
	{
		return Plugin_Handled;
	}
	
	char date[32];
	GetConVarString(g_cvDate, date, sizeof(date));
	FormatTime(date, sizeof(date), date, GetTime());
	
	char name[65], authid[3][21], escapeBuffer[32];
	GetClientName(client, escapeBuffer, sizeof(escapeBuffer));
	g_db.Escape(escapeBuffer, name, sizeof(name));
	
	GetClientAuthId(client, AuthId_Steam2, authid[0], sizeof(authid[]));
	GetClientAuthId(client, AuthId_Steam3, authid[1], sizeof(authid[]));
	GetClientAuthId(client, AuthId_SteamID64, authid[2], sizeof(authid[]));
	
	char team[2][65];
	GetTeamName(CS_TEAM_T, escapeBuffer, sizeof(escapeBuffer));
	g_db.Escape(escapeBuffer, team[0], sizeof(team[]));
	GetTeamName(CS_TEAM_CT, escapeBuffer, sizeof(escapeBuffer));
	g_db.Escape(escapeBuffer, team[1], sizeof(team[]));
	
	int roundsPlayed = GameRules_GetProp("m_totalRoundsPlayed", 2);
	
	char map[65];
	GetCurrentMap(escapeBuffer, sizeof(escapeBuffer));
	g_db.Escape(escapeBuffer, map, sizeof(map));
	
	int cmdTick = GetGameTickCount();
	
	char query[800];
	Format(query, sizeof(query), "INSERT INTO `clips`(`steamid2`, `steamid3`, `steamid64`, `player`, `team1`, `team2`, `rounds_played`, `map`, `round_tick`, `cmd_tick`, `date`) VALUES (\"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%s\", \"%d\", \"%s\", \"%d\", \"%d\", \"%s\")", authid[0], authid[1], authid[2], name, team[0], team[1], roundsPlayed, map, g_iRoundTick, cmdTick, date);
	g_db.Query(InsertCallback, query, GetClientUserId(client));
	return Plugin_Handled;
}

public void InsertCallback(Database db, DBResultSet results, const char[] error, any data)
{
	char err[256];
	if (SQL_GetError(db, err, sizeof(err)))
	{
		ThrowError("Unable to insert into database. %s", err);
		return;
	}
	
	int client = GetClientOfUserId(data);
	if (!IsValidClient(client))
	{
		return;
	}
	
	PrintToChat(client, "[Scim Clips] Your clip has been added the the database!");
}

public void ConnectCallback(Database db, const char[] error, any data)
{
	if (db == null)
	{
		SetFailState("Unable to connect to database. %s", error);
	}
	
	g_db = db;
	CreateTables(g_db);
}

void CreateTables(Database &db)
{
	char query[] = "CREATE TABLE IF NOT EXISTS `clips`(`id` INT AUTO_INCREMENT PRIMARY KEY, `steamid2` VARCHAR(32), `steamid3` VARCHAR(32), `steamid64` VARCHAR(32), `player` VARCHAR(32), `team1` VARCHAR(32), `team2` VARCHAR(32), `rounds_played` SMALLINT, `map` VARCHAR(64), `round_tick` INT, `cmd_tick` INT, `date` VARCHAR(32));";
	db.Query(CreateTablesCallback, query);
}

public void CreateTablesCallback(Database db, DBResultSet results, const char[] error, any data)
{
	char err[256];
	if (SQL_GetError(db, err, sizeof(err)))
	{
		SetFailState("Unable to create tables. %s", err);
	}
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
} 