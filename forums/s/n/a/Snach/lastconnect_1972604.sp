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
	
	2.0
		* Overall fixes by Snach`
*/


#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "2.0"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Last Connnect",
	author = "dalto, Fixed by Snach`",
	description = "Tells you the last time someone connected",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

new Handle:h_db = INVALID_HANDLE;

public OnPluginStart()
{
	CreateConVar("sm_last_connect_version", PLUGIN_VERSION, "Last Connect Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	RegConsoleCmd("sm_last", CommandLastConnect,"returns the last # people to disconnect / returns the last time the player with that steamid connected.");
	RegConsoleCmd("sm_aka", CommandAKA,"returns a list of all the other names that player has used.");
	InitializeDB();
}

// When a client is authorized to the server update them in the database
public OnClientPostAdminCheck(client)
{
	UpdateHistory(client);
}

// Here we get a handle to the database and create it if it doesn't already exist
public InitializeDB()
{
	new String:error[255];
	h_db=SQLite_UseDatabase("last_connect",error,sizeof(error));

	if(h_db == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	SQL_LockDatabase(h_db);
	SQL_FastQuery(h_db, "CREATE TABLE IF NOT EXISTS history (steam_id TEXT, name TEXT, timestamp INTEGER);");
	SQL_UnlockDatabase(h_db);
}

// Updates the database for a single client
public UpdateHistory(client)
{
	decl String:steamId[20];
	decl String:name[MAX_NAME_LENGTH];
	decl String:buffer[200];
	
	if(client && IsClientConnected(client) && !IsFakeClient(client))
	{
		GetClientName(client, name, sizeof(name));
		GetClientAuthString(client, steamId, sizeof(steamId));

		Format(buffer, sizeof(buffer), "INSERT INTO history VALUES ('%s', '%s', %i)", steamId, name, GetTime());
		SQL_TQuery(h_db, SQLErrorCheckCallback, buffer);
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
	if(!client)
		return Plugin_Handled;
	
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_last <steam id|#> (You might need quotes around the steam id)");
		return Plugin_Handled;
	}
	
	decl String:steamId[20];
	decl String:buffer[200];
	GetCmdArg(1, buffer, sizeof(buffer));
	if(StrContains(buffer,"steam",false)!=-1)
	{
		strcopy(steamId, sizeof(steamId), buffer);
		Format(buffer, sizeof(buffer), "SELECT steam_id, name, timestamp FROM history WHERE steam_id = '%s' ORDER BY timestamp DESC LIMIT 1", steamId);
		SQL_TQuery(h_db, SteamIdSearchCallback, buffer, GetClientUserId(client));
	}
	else
	{
		new last = StringToInt(buffer);
		Format(buffer, sizeof(buffer), "SELECT steam_id, name, timestamp FROM history ORDER BY timestamp ASC LIMIT %i", last);
		SQL_TQuery(h_db, LastXSearchCallback, buffer, GetClientUserId(client));
	}	
	

	return Plugin_Handled;
}

public SteamIdSearchCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client=GetClientOfUserId(data);
	if(!IsClientInGame(client))
	{
		return;
	}
	
	if(hndl == INVALID_HANDLE)
	{
		ThrowError("steam search SQL error: %s", error);
		return;
	}
	decl String:steamId[20];
	decl String:name[MAX_NAME_LENGTH];
	decl String:time[20];
	decl String:date[20];
	
	if(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, steamId, sizeof(steamId));
		SQL_FetchString(hndl, 1, name, sizeof(name));
		FormatTime(date, sizeof(date), "%x", SQL_FetchInt(hndl, 2));
		FormatTime(time, sizeof(time), "%X", SQL_FetchInt(hndl, 2));
		PrintToChat(client, "\x03[Last Connect] \"\x04%s\x01\" - \x03SteamID: \x04%s, \x03last connected on \x04%s \x03at \x04%s", name, steamId, date, time);
	} else {
		PrintToChat(client, "\x03[Last Connect] \x04Steam ID not found in database");
	}
}

public LastXSearchCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	new client=GetClientOfUserId(data);
	if(!IsClientInGame(client))
	{
		return;
	}
	
	if(hndl == INVALID_HANDLE)
	{
		ThrowError("last x SQL error: %s", error);
		return;
	}
	decl String:steamId[20];
	decl String:name[MAX_NAME_LENGTH];
	decl String:time[20];
	decl String:date[20];
	new i=1;
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, steamId, sizeof(steamId));
		SQL_FetchString(hndl, 1, name, sizeof(name));
		FormatTime(date, sizeof(date), "%x", SQL_FetchInt(hndl, 2));
		FormatTime(time, sizeof(time), "%X", SQL_FetchInt(hndl, 2));
		PrintToChat(client, "\x03[Last Connect] \x01No. %d: \x03\"\x04%s\x03\" - \x03SteamID: \x04%s, \x03last connected on \x04%s \x03at \x04%s", i, name, steamId, date, time);
		PrintToChat(client,"-  -  -  -  -  -  -  -");
		i++;
	}
}

public Action:CommandAKA(client, args)
{
	if(!client)
		return Plugin_Handled;
	
	
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_aka <target>");
		return Plugin_Handled;
	}
	
	decl String:steamId[20];
	decl String:buffer[200];
	GetCmdArg(1, buffer, sizeof(buffer));
	
	new target = FindTarget(client, buffer, true, false);
	
	if(!target)
	{
		ReplyToCommand(client, "\x03[Last Connect] \x04 player \x03%s \x04could not be found.",buffer);
		return Plugin_Handled;
	}
	
	GetClientAuthString(target, steamId, sizeof(steamId));
	Format(buffer, sizeof(buffer), "SELECT DISTINCT name from history where steam_id = '%s'", steamId);
	SQL_TQuery(h_db, AKACallback, buffer, GetClientUserId(client));
	return Plugin_Handled;
}

public AKACallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		ThrowError("AKA callback SQL error: %s", error);
		return;
	}
	new client=GetClientOfUserId(data);
	if(!IsClientInGame(client))
	{
		return;
	}

	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client,name,sizeof(name));
	PrintToChat(client,"%s's aliases:",name);
	new i=1;
	while(SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, name, sizeof(name));
		PrintToChat(client, "\x03[Last Connect] \x01No. %d: \x04%s", i,name);
		i++;
	}
	
}