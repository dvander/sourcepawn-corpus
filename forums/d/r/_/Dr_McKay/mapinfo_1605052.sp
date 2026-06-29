#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"
new Handle:db = INVALID_HANDLE;
new Handle:tableCvar = INVALID_HANDLE;

public Plugin:myinfo = {
	name        = "SQL Map Info Logger",
	author      = "Dr. McKay",
	description = "Made by request: https://forums.alliedmods.net/showthread.php?t=173076",
	version     = PLUGIN_VERSION,
	url         = "http://www.doctormckay.com"
};

public OnPluginStart()
{
	decl String:error[255];
	db = SQL_Connect("mapinfo", true, error, sizeof(error));
	if(db == INVALID_HANDLE)
		SetFailState("Could not connect to the database.");
	tableCvar = CreateConVar("sqlinfo_tablename", "mapinfo", "Table in your SQL database");
}

public OnMapStart()
{
	decl String:mapname[100], tablename[100], String:sessionID[100];
	new Handle:steamworks_sessionid_server = FindConVar("steamworks_sessionid_server");
	GetConVarString(steamworks_sessionid_server, sessionID, sizeof(sessionID));
	GetCurrentMap(mapname, sizeof(mapname));
	GetConVarString(tableCvar, tablename, sizeof(tablename));
	SQL_FastQuery(db, "INSERT INTO `%s` (map, match_id) VALUES ('%s', '%s')", tablename, mapname, sessionID);
	return;
}