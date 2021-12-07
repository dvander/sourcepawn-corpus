/*
	MySQL server informations.
	Thanks to dmustanger for first version. (http://forums.alliedmods.net/showthread.php?t=84899)
	
	This plugin is not finished !
*/

#include <sourcemod>
#include <sdktools>
#include <dbi>

#define SERVER_ID 1 /*!!! If you have more than one server, change this !!!*/

#define TEAM_T  2
#define TEAM_CT 3

public Plugin:myinfo = 
{
	name = "MySQL server informations",
	author = "foohey",
	description = "Insert server and players info into a database.",
	version = "1.0",
	url = "http://forums.alliedmods.net/showthread.php?t=84899"
}

new Handle:Database = INVALID_HANDLE;
new Handle:CvarHostIp;
new Handle:CvarPort;
new Handle:CvarServerName;

new String:logFile[1024];
new String:ServerIp[50];
new String:ServerPort[25];
new String:ServerName[200];
new String:SafeServerName[200];
new String:MapName[50];

new ScoreCT;
new ScoreT;

public OnPluginStart()
{
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/Server_Info.log");
	
	CvarHostIp = FindConVar("hostip");
	CvarPort = FindConVar("hostport");
	CvarServerName = FindConVar("hostname");
	
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("game_end", Event_GameEnd);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	SQL_TConnect(GotDatabase, "server_info");
}

public OnMapStart()
{
	UpdateServer();
}

public OnMapEnd()
{
	new String:squery[256];
	Format(squery, sizeof(squery), "DELETE FROM players WHERE server_id = '%i'", SERVER_ID);
	SQL_TQuery(Database, T_Generic, squery);		
}

public OnClientPutInServer(client)
{
	if (IsClientConnected(client))
	{
		InsertPlayer(client);
	}		
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	UpdateServer();
}

public Event_GameEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new String:squery[256];
	Format(squery, sizeof(squery), "DELETE FROM players WHERE server_id = '%i'", SERVER_ID);
	SQL_TQuery(Database, T_Generic, squery);
}

public Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new UserId = GetEventInt(event, "userid");
	decl String:squery[256];
	Format(squery, sizeof(squery), "DELETE FROM players WHERE server_id = '%i' AND userid = '%i'", SERVER_ID, UserId);
	SQL_TQuery(Database, T_Generic, squery);		
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
		InitServer();
	}	
}

public T_Generic(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_generic: %s", error);
	}
}

public InitServer()
{
	decl String:squery[256], pieces[4];
	new longip = GetConVarInt(CvarHostIp);
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	Format(ServerIp, sizeof(ServerIp), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	GetConVarString(CvarPort, ServerPort, sizeof(ServerPort));
	GetConVarString(CvarServerName, ServerName, sizeof(ServerName));
	Format(squery, sizeof(squery), "SELECT * FROM servers WHERE server_id = '%i'", SERVER_ID)
	SQL_TQuery(Database, T_InitServer, squery);
	Format(squery, sizeof(squery), "DELETE FROM players WHERE server_id = '%i'", SERVER_ID);
	SQL_TQuery(Database, T_Generic, squery);	
}

public UpdateServer()
{
	decl String:squery[256];
	ScoreT = GetTeamScore(TEAM_T);
	ScoreCT = GetTeamScore(TEAM_CT);
	GetCurrentMap(MapName, sizeof(MapName));
	Format(squery, sizeof(squery), "SELECT * FROM servers WHERE server_id = '%i'", SERVER_ID)
	SQL_TQuery(Database, T_UpdateServer, squery);	
}

public InsertPlayer(client)
{	
	decl String:squery[256];
	decl String:SteamId[50];
	decl String:ClientName[60];
	decl String:SafeClientName[60];
	
	new UserId = GetClientUserId(client);
	GetClientName(client, ClientName, sizeof(ClientName));
	GetClientAuthString(client, SteamId, sizeof(SteamId));
	SQL_EscapeString(Database, ClientName, SafeClientName, sizeof(SafeClientName));
	
	Format(squery, sizeof(squery), "INSERT INTO players (userid, steam_id, server_id, name) VALUES ('%i', '%s', '%i', '%s')", UserId, SteamId, SERVER_ID, SafeClientName);
	SQL_TQuery(Database, T_Generic, squery);		
}


public T_InitServer(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_InitServer: %s", error);
		return;
	}
	if (SQL_FetchRow(hndl))
	{
		decl String:squery[256];
		decl QueryMaxPlayers;
		new maxplayers = GetMaxClients();
		QueryMaxPlayers = SQL_FetchInt(hndl, 5);
		SQL_EscapeString(Database, ServerName, SafeServerName, sizeof(SafeServerName));
		if (QueryMaxPlayers != maxplayers)
		{
			Format(squery, sizeof(squery), "UPDATE servers SET maxplayers = '%i', servername = '%s' WHERE server_id = '%i'", maxplayers, SafeServerName, SERVER_ID);
			SQL_TQuery(Database, T_Generic, squery);					
		}
		return;
	}
	else
	{
		decl String:squery[256];
		new maxplayers = GetMaxClients();
		SQL_EscapeString(Database, ServerName, SafeServerName, sizeof(SafeServerName));
		Format(squery, sizeof(squery), "INSERT INTO servers (server_id, server, port, maxplayers, servername, map) VALUES ('%i', '%s', '%s', '%i', '%s', 'none')", SERVER_ID, ServerIp, ServerPort, maxplayers, SafeServerName);
		SQL_TQuery(Database, T_Generic, squery);
		return;
	}
}

public T_UpdateServer(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_UpdateServer: %s", error);
		return;
	}
	if (SQL_FetchRow(hndl))
	{
		decl String:squery[256];
		Format(squery, sizeof(squery), "UPDATE servers SET map = '%s', score_t = '%i', score_ct = '%i' WHERE server_id = '%i'", MapName, ScoreT, ScoreCT, SERVER_ID);
		SQL_TQuery(Database, T_Generic, squery);
		return;
	}
}