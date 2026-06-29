#include <sourcemod>
#include "dbi.inc"

#define PLUGIN_VERSION "0.4"

public Plugin:myinfo = 
{
	name = "Server Info",
	author = "Dmustanger",
	description = "Inserts  server info into a database.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=84899"
}

new Handle:Database = INVALID_HANDLE;
new Handle:CvarHostIp;
new Handle:CvarPort;
new Handle:UpdateServer = INVALID_HANDLE;

new String:logFile[1024];
new String:ServerIp[50];
new String:ServerPort[25];

public OnPluginStart()
{
	BuildPath(Path_SM, logFile, sizeof(logFile), "logs/Server_Info.log");
	CvarHostIp = FindConVar("hostip");
	CvarPort = FindConVar("hostport");
	SQL_TConnect(GotDatabase, "Server_Info");
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
		InsertDB();
		InsertServerInfo();
	}	
}

InsertDB()
{
	new String:query[] = "CREATE TABLE IF NOT EXISTS server_info ( \
						 server VARCHAR(50) NOT NULL, \
						 port VARCHAR(50) NOT NULL, \
						 totalplayers INT NOT NULL DEFAULT '0', \
						 maxplayer INT NOT NULL DEFAULT '0', \
						 servername VARCHAR(100) NOT NULL DEFAULT 'noserver', \
						 map VARCHAR(50) NOT NULL DEFAULT 'de_dust', \
				 	PRIMARY KEY (server) ) \
				 	ENGINE = InnoDB;";
	SQL_TQuery(Database, T_Generic, query);
	
}

public T_Generic(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_generic: %s", error);
	}
}

public InsertServerInfo()
{
	decl String:squery[256], pieces[4];
	new longip = GetConVarInt(CvarHostIp);
	pieces[0] = (longip >> 24) & 0x000000FF;
	pieces[1] = (longip >> 16) & 0x000000FF;
	pieces[2] = (longip >> 8) & 0x000000FF;
	pieces[3] = longip & 0x000000FF;
	Format(ServerIp, sizeof(ServerIp), "%d.%d.%d.%d", pieces[0], pieces[1], pieces[2], pieces[3]);
	GetConVarString(CvarPort, ServerPort, sizeof(ServerPort));
	Format(squery, sizeof(squery), "SELECT * FROM server_info WHERE server = '%s'", ServerIp)
	SQL_TQuery(Database, T_InsertServerInfo, squery);
}

public T_InsertServerInfo(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogToFile(logFile, "Query Failed T_InsertServerInfo: %s", error);
		return;
	}
	if (SQL_FetchRow(hndl))
	{
		return;
	}
	else
	{
		decl String:squery[256];
		new maxplayer =  GetMaxClients();
		Format(squery, sizeof(squery), "INSERT INTO server_info (server, port, maxplayer) VALUES ('%s', '%s', '%i')", ServerIp, ServerPort, maxplayer);
		SQL_TQuery(Database, T_Generic, squery);
	}
}

public OnMapStart()
{
	UpdateServer = CreateTimer(300.0, UpdateServerInfo, INVALID_HANDLE, TIMER_REPEAT);
}

public Action:UpdateServerInfo(Handle:timer)
{
	decl String:mapname[100];
	decl String:q_mapname[201];
	decl String:servername[100];
	decl String:q_servername[201];
	decl String:squery[256];
	GetCurrentMap(mapname, sizeof(mapname));
	SQL_EscapeString(Database, mapname, q_mapname, sizeof(q_mapname));
	GetClientName(0, servername, sizeof(servername));
	SQL_EscapeString(Database, servername, q_servername, sizeof(q_servername));
	new playercount = GetClientCount(true);
	Format(squery, sizeof(squery), "UPDATE server_info SET totalplayers = '%i', servername = '%s', map = '%s' WHERE server = '%s'", playercount, q_servername, q_mapname, ServerIp);
	SQL_TQuery(Database, T_Generic, squery);
}

public OnMapEnd()
{
	CloseHandle(UpdateServer);
}