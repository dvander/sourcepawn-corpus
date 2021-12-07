/*
lastconnect.sp

Description:
	Tells you the last time a player connected

Versions:
	1.0
		* Initial Release

	1.1
		* Changed functionality to keep full history
		* Added aka command and functionality
		* Added last x functionality
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.1"
#define MAX_FILE_LEN 80

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Last Connnect",
	author = "dalto",
	description = "Tells you the last time someone connected",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:db = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_last_connect_version", PLUGIN_VERSION, "Last Connect Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_last", CommandLastConnect);
	RegConsoleCmd("sm_aka", CommandAKA);
	InitializeDB();
}

// When a client is authorized to the server update them in the database
public OnClientDisconnect(client)
{
	UpdateHistory(client);
}

// Here we get a handle to the database and create it if it doesn't already exist
public InitializeDB()
{
	new String:error[255];
	db = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "last_connect", error, sizeof(error), true, 0);
	if(db == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	SQL_LockDatabase(db);
	SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS history (steam_id TEXT, name TEXT, timestamp INTEGER);");
	SQL_UnlockDatabase(db);
}

// Updates the database for a single client
public UpdateHistory(client)
{
	decl String:steamId[20];
	decl String:name[40];
	decl String:buffer[200];
	
	if(client && IsClientConnected(client) && !IsFakeClient(client))
	{
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, steamId, sizeof(steamId));

		Format(buffer, sizeof(buffer), "INSERT INTO history VALUES ('%s', '%s', %i)", steamId, name, GetTime());
		SQL_TQuery(db, SQLErrorCheckCallback, buffer);
	}
}

// This is used during a threaded query that does not return data
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		PrintToServer("Last Connect SQL Error: %s", error);
	}
}

// This is called when the sm_last command is executed
public Action:CommandLastConnect(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_last <steam id|#> (You might need quotes around the steam id)");
		return Plugin_Handled;
	}
	
	decl String:steamId[20];
	decl String:buffer[200];
	GetCmdArg(1, buffer, sizeof(buffer));
	new last = StringToInt(buffer);
	if(last)
	{
		Format(buffer, sizeof(buffer), "SELECT steam_id, name, timestamp FROM history ORDER BY timestamp DESC LIMIT %i", last);
		SQL_TQuery(db, LastXSearchCallback, buffer, client);
	}
	else {
		strcopy(steamId, sizeof(steamId), buffer);
		Format(buffer, sizeof(buffer), "SELECT steam_id, name, timestamp FROM history WHERE steam_id = '%s' ORDER BY timestamp DESC LIMIT 1", steamId);
		SQL_TQuery(db, SteamIdSearchCallback, buffer, client);
	}

	return Plugin_Handled;
}

public SteamIdSearchCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!IsClientInGame(data))
	{
		return;
	}
	
	if(hndl == INVALID_HANDLE)
	{
		ThrowError("steam search SQL error: %s", error);
		return;
	}
	decl String:steamId[20];
	decl String:name[40];
	decl String:time[20];
	decl String:date[20];
	
	if(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, steamId, sizeof(steamId));
		SQL_FetchString(hndl, 1, name, sizeof(name));
		FormatTime(date, sizeof(date), "%m/%d/%y", SQL_FetchInt(hndl, 2));
		FormatTime(time, sizeof(time), "%H:%M:%S", SQL_FetchInt(hndl, 2));
		PrintToChat(data, "%s having %s last connected on %s at %s", name, steamId, date, time);
	} else {
		PrintToChat(data, "Last Connect: Steam ID not found in database");
	}
}

public LastXSearchCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!IsClientInGame(data))
	{
		return;
	}
	
	if(hndl == INVALID_HANDLE)
	{
		ThrowError("last x SQL error: %s", error);
		return;
	}
	decl String:steamId[20];
	decl String:name[40];
	
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, steamId, sizeof(steamId));
		SQL_FetchString(hndl, 1, name, sizeof(name));
		PrintToChat(data, "%s, STEAM ID: %s", name, steamId);
	}
}

public Action:CommandAKA(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_aka <target>");
		return Plugin_Handled;
	}
	
	if(!client)
	{
		return Plugin_Handled;
	}
	
	decl String:steamId[20];
	decl String:buffer[200];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	new target = FindTarget(client, buffer, true, false);
	
	if(!target)
	{
		PrintToChat(client, "No player could be found");
		return Plugin_Handled;
	}
	
	GetClientAuthString(client, steamId, sizeof(steamId));
	Format(buffer, sizeof(buffer), "SELECT DISTINCT name from history where steam_id = '%s'", steamId);
	SQL_TQuery(db, AKACallback, buffer, client);
	return Plugin_Handled;
}

public AKACallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		ThrowError("AKA callback SQL error: %s", error);
		return;
	}
	
	if(!IsClientInGame(data))
	{
		return;
	}

	decl String:name[50];
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, name, sizeof(name));
		PrintToChat(data, "aka: %s", name);
	}
	
}