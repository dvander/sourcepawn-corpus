/*
-----------------------------------------------------------------------------
VERY BASIC PLAYER TRACKER - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By Michelle Sleeper (c) 2010
Optimized by Kigen (c) 2010
Visit http://www.msleeper.com/ for more info!
-----------------------------------------------------------------------------
This plugin is a simple player tracker that logs player information into a
MySQL database. It logs the player SteamID, Name and IP address, as well as
the game type (using GetGameFolderName()) and server IP. It logs this
information X seconds after being connected, which is controlled with a cvar.
This is useful if you only want to keep track of players who are connected
for a minimum amount of time, the default is 60 seconds. If a duplicate
player is found, it updates their name.

I am not providing any web interface at this time, though I may in the
future. This is really just a base for anyone who may want to develop it
further, or use it for a more specific purpose.

Thank you and enjoy!
- msleeper
-----------------------------------------------------------------------------
Version History
-- 1.0 (10/1/09)
 . Initial release!

-- 1.1 (10/23/09)
 . Changed the way player SteamID is logged to be more accurate.

-- 1.2 (12/23/09)
 . Added player name logging.

-- 1.3 (6/16/10)
 . Removed duplicate error messaging.
 . Increased MySQL query sizes for instances where the string would be
   longer than expected (that's what she said).

-- 1.4 (7/14/10)
 . Added GeoIP Country field to table, and added new cvar to control how the
   country name is stored.
 . Changed INSERT statement to update all possible fields (name, player IP,
   game type, server IP and GeoIP country) when a duplicate entry is found.
 . Added query to properly handle UTF8 player names.

-- 1.5 (7/15/10)
 . Added server port due to request.

-- 1.6 (10/11/2010)
 . Converted plugin to use full threaded queries to help eliminate lagging
 . during player connection. Hat tip goes to Kigen.
 . Optimized the code. - Kigen
-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>
#include <geoip>

#define PLUGIN_VERSION "1.6"

// Database handle
new Handle:db = INVALID_HANDLE;

// Logfile path var
new String:Logfile[PLATFORM_MAX_PATH];

// Game Type
new String:GameType[32];

// Cvar handles
new Handle:cvar_AddTime = INVALID_HANDLE;
new Handle:cvar_GeoIPType = INVALID_HANDLE;

// Cvar settings
new String:ServerIP[64];
new String:ServerPort[64];
new Float:AddTime = 90.0;
new GeoIPType = 1;

// Plugin Info
public Plugin:myinfo =
{
	name = "Very Basic Player Tracker",
	author = "msleeper",
	description = "Tracks basic player information to a MySQL database",
	version = PLUGIN_VERSION,
	url = "http://www.msleeper.com/"
};

// Here we go!
public OnPluginStart()
{
	// Plugin version public Cvar
	CreateConVar("sm_tracker_version", PLUGIN_VERSION, "Very Basic Player Tracker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	// Config Cvars
	cvar_AddTime = CreateConVar("sm_tracker_addtime", "90.0", "Add/update players in the database after this many seconds", FCVAR_PLUGIN, true, 1.0);
	cvar_GeoIPType = CreateConVar("sm_tracker_geoiptype", "1", "Add player's GeoIP country to the database. 0 = Disabled, 1 = 2 letter Country Code, 2 = 3 letter Country Code, 3 = full Country Name.", FCVAR_PLUGIN, true, 0.0, true, 3.0);

	// Hook Config CVars
	HookConVarChange(cvar_AddTime, AddTime_Change);
	HookConVarChange(cvar_GeoIPType, GeoIP_Change);

	// Get the Game Type
	GetGameFolderName(GameType, sizeof(GameType));

	// Get the Server's IP and port
	GetConVarString(FindConVar("ip"), ServerIP, sizeof(ServerIP));
	GetConVarString(FindConVar("hostport"), ServerPort, sizeof(ServerPort));

	// Make that config!
	AutoExecConfig(true, "tracker");

	// Log file for SQL errors
	BuildPath(Path_SM, Logfile, sizeof(Logfile), "logs/tracker.log");

	// Connect to the almighty database
	// db = SQL_Connect("default", true, Error, sizeof(Error));
	SQL_TConnect(SQL_GetDatabase, "default");

	// Init player arrays
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i) )
			CreateTimer(GetConVarFloat(cvar_AddTime), timer_InsertPlayer, i);
	}
}

// When a client connects, insert them into the database
public OnClientAuthorized(client, const String:auth[])
{
	if ( IsFakeClient(client) )
		return;

	CreateTimer(AddTime, timer_InsertPlayer, client);
}

public Action:timer_InsertPlayer(Handle:timer, any:client)
{
	if ( !IsClientConnected(client) || IsFakeClient(client) )
		return;

	new String:SteamID[32], String:PlayerName[MAX_NAME_LENGTH], String:PlayerIP[32], String:GeoIPCode[4], String:GeoIPCountry[45], String:query[1024];

	GetClientAuthString(client, SteamID, sizeof(SteamID));

	GetClientName(client, PlayerName, sizeof(PlayerName));
	ReplaceString(PlayerName, sizeof(PlayerName), "\"", "");
	ReplaceString(PlayerName, sizeof(PlayerName), "'", "");
	ReplaceString(PlayerName, sizeof(PlayerName), ";", "");
	ReplaceString(PlayerName, sizeof(PlayerName), "`", "");

	GetClientIP(client, PlayerIP, sizeof(PlayerIP));

	// Get the client's Country Code
	if ( GeoIPType == 1 ) GeoipCode2(PlayerIP, GeoIPCode);
	else if ( GeoIPType == 2 ) GeoipCode3(PlayerIP, GeoIPCode);
	else if ( GeoIPType == 3 ) GeoipCountry(PlayerIP, GeoIPCountry, sizeof(GeoIPCountry));

	// Convert code into string. Method 3 already process it into a string, so do method 1 and 2.
	if ( GeoIPType == 1 || GeoIPType == 2 )
	Format(GeoIPCountry, sizeof(GeoIPCountry), "%s", GeoIPCode);

	// Do the query
	Format(query, sizeof(query), "INSERT INTO player_tracker (steamid, playername, playerip, servertype, serverip, serverport, geoipcountry, status) \
													  VALUES ('%s', '%s', '%s', '%s', '%s', '%s', '%s', 'new') \
													  ON DUPLICATE KEY UPDATE playername='%s', playerip='%s', servertype='%s', serverip='%s', serverport='%s', geoipcountry='%s'",
													  SteamID, PlayerName, PlayerIP, GameType, ServerIP, ServerPort, GeoIPCountry,
															   PlayerName, PlayerIP, GameType, ServerIP, ServerPort, GeoIPCountry);
	SQL_TQuery(db, SQL_ErrorCallback, query);
}

// Connection error logging
public SQL_GetDatabase(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( hndl == INVALID_HANDLE )
	{
		LogToFile(Logfile, "Failed to connect to database: %s", error);
		SetFailState("Failed to connect to the database");
	}

	db = hndl;

	decl String:query[1024];
	FormatEx(query, sizeof(query), "SET NAMES \"UTF8\"");
	SQL_TQuery(db, SQL_ErrorCallback, query);
}

// Error logging
public SQL_ErrorCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( !StrEqual("", error) )
		LogToFile(Logfile, "SQL Error: %s", error);
}

// Get cvar changes
public AddTime_Change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	AddTime = GetConVarFloat(cvar_AddTime);
}

public GeoIP_Change(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GeoIPType = GetConVarInt(cvar_GeoIPType);
}

