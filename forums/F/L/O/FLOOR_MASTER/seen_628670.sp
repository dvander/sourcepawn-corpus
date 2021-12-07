/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * Last Seen
 *
 * Copyright 2008 Ryan Mannion. All Rights Reserved.
 * =============================================================================
 * 
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

#pragma semicolon 1

#include <sourcemod>

#define SEEN_VERSION	    "0.1"

#define CVAR_DB_CONFIG	    0
#define CVAR_VERSION	    1
#define CVAR_TABLE	    2
#define CVAR_NUM_CVARS	    3

new Handle:db = INVALID_HANDLE;
new Handle:g_cvars[CVAR_NUM_CVARS];
new bool:g_SQLite = false;
new String:g_table_name[32];
new String:g_address[24];

public Plugin:myinfo = {
    name = "Last Seen",
    author = "Ryan \"FLOOR_MASTER\" Mannion",
    description = "Display when a user was last seen.",
    version = SEEN_VERSION,
    url = "http://www.2fort2furious.com"
};

/* OnPluginStart {{{ */
public OnPluginStart() {
    g_cvars[CVAR_DB_CONFIG] = CreateConVar(
	"seen_db_config",
	"default",
	"Database configuration to use for the Last Seen plugin",
	FCVAR_PLUGIN);

    g_cvars[CVAR_TABLE] = CreateConVar(
	"seen_table",
	"last_seen",
	"The name of the database table to use",
	FCVAR_PLUGIN);

    g_cvars[CVAR_VERSION] = CreateConVar(
	"seen_version",
	SEEN_VERSION,
	"Last Seen Version",
	FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    RegConsoleCmd("sm_seen", Command_Seen);
    HookEvent("player_changename", Event_PlayerChangeName);

    GetServerAddress(g_address, sizeof(g_address));
}
/* }}} OnPluginStart */

/* AskPluginLoad {{{ */
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max) {
    CreateNative("GetNameFromAuthString", Native_GetNameFromAuthString);
    return true;
}
/* }}} AskPluginLoad */

/* OnConfigsExecuted {{{ */
public OnConfigsExecuted() {
    GetConVarString(g_cvars[CVAR_TABLE], g_table_name, sizeof(g_table_name));
    PrintToServer("[LASTSEEN] Using table name \"%s\"", g_table_name);

    if (!ConnectDB()) {
        LogError("FATAL: An error occurred while connecting to the database.");
        SetFailState("An error occurred while connecting to the database.");
    }
}
/* }}} OnConfigsExecuted */

/* OnClientDisconnect {{{ */
public OnClientDisconnect(client) {
    decl String:name[32];
    GetClientName(client, name, sizeof(name));
    UpdateLastSeen(client, name);
}
/* }}} OnClientDisconnect */

/* Event_PlayerChangeName {{{ */
public Action:Event_PlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    decl String:client_name[32];

    GetEventString(event, "oldname", client_name, sizeof(client_name));
    UpdateLastSeen(client, client_name);
    GetEventString(event, "newname", client_name, sizeof(client_name));
    UpdateLastSeen(client, client_name);
}
/* }}} Event_PlayerChangeName */

/* GetServerAddress {{{ */
stock GetServerAddress(String:address[], address_length) {
    new hostip = GetConVarInt(FindConVar("hostip"));
    new hostport = GetConVarInt(FindConVar("hostport"));

    Format(address, address_length, "%d.%d.%d.%d:%d",
	(hostip >> 24 & 0xFF),
	(hostip >> 16 & 0xFF),
	(hostip >> 8 & 0xFF),
	(hostip & 0xFF),
	hostport
    );
}
/* }}} GetServerAddress */

/* UpdateLastSeen {{{ */
stock UpdateLastSeen(client, const String:name[]) {
    decl String:query[512];
    decl String:name_escaped[65];
    decl String:steamid[24];
    decl String:hostname[64];
    decl String:hostname_escaped[129];

    GetConVarString(FindConVar("hostname"), hostname, sizeof(hostname));
    if (!SQL_EscapeString(db, hostname, hostname_escaped, sizeof(hostname_escaped))) {
	LogError("Could not escape hostname string: \"%s\"", hostname);
	return;
    }

    GetClientAuthString(client, steamid, sizeof(steamid));
    if (!SQL_EscapeString(db, name, name_escaped, sizeof(name_escaped))) {
	LogError("Could not escape client name string: \"%s\"", name);
	return;
    }

    if (g_SQLite) {
	Format(query, sizeof(query), "REPLACE INTO %s VALUES ('%s', '%s', DATETIME('NOW'), '%s', '%s')",
	    g_table_name,
	    steamid,
	    name_escaped,
	    g_address,
	    hostname_escaped
	);
    }
    else {
	Format(query, sizeof(query), "REPLACE INTO %s VALUES ('%s', '%s', NOW(), '%s', '%s')",
	    g_table_name,
	    steamid,
	    name_escaped,
	    g_address,
	    hostname_escaped
	);
    }

    SQL_LockDatabase(db);
    SQL_FastQuery(db, query);
    SQL_UnlockDatabase(db);
}
/* }}} UpdateLastSeen */

/* OnMapStart {{{ */
public OnMapStart() {
}
/* }}} OnMapStart */

/* OnMapEnd {{{ */
public OnMapEnd() {
    if (db != INVALID_HANDLE) {
	CloseHandle(db);
	db = INVALID_HANDLE;
    }
}
/* }}} OnMapEnd */

/* ConnectDB {{{ */
/* Establish a connection to the database, setting logStats accordingly. Also
 * create the DB tables if necessary. */
stock bool:ConnectDB() {
    decl String:db_config[64];
    GetConVarString(g_cvars[CVAR_DB_CONFIG], db_config, sizeof(db_config));

    /* Verify that the configuration is defined in databases.cfg  */
    if (!SQL_CheckConfig(db_config)) {
	LogError("Database configuration \"%s\" does not exist", db_config);
	return false;
    }

    /* Establish a connection */
    new String:error[256];
    db = SQL_Connect(db_config, true, error, sizeof(error));
    if (db == INVALID_HANDLE) {
	LogError("Error establishing database connection: %s", error);
	return false;
    }

    decl String:driver[32];
    SQL_ReadDriver(db, driver, sizeof(driver));

    if (!strcmp(driver, "sqlite")) {
	g_SQLite = true;
    }

    decl String:query[256];

    if (g_SQLite) {
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (steamid TEXT, name TEXT, seen DATE, address TEXT, hostname TEXT, UNIQUE (steamid, name))", g_table_name);
	if (!SQL_FastQuery(db, query)) {
    	    LogError("FATAL: Could not create table %s.", g_table_name);
    	    SetFailState("Could not create table %s.", g_table_name);
	}
    }
    else {
	Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR(24), name VARCHAR(64), seen DATETIME, address VARCHAR(24), hostname VARCHAR(32), UNIQUE KEY (steamid, name))", g_table_name);
	if (!SQL_FastQuery(db, query)) {
    	    LogError("FATAL: Could not create table %s.", g_table_name);
    	    SetFailState("Could not create table %s.", g_table_name);
    	}
    }

    return true;
}
/* }}} END ConnectDB */

/* OnPluginEnd {{{ */
public OnPluginEnd() {
}
/* }}} OnPluginEnd */

/* UpdateAllLastSeen {{{ */
stock UpdateAllLastSeen() {
    decl String:name[32];
    for (new i = 1; i <= GetMaxClients(); i++) {
	if (IsClientInGame(i) && !IsFakeClient(i)) {
	    GetClientName(i, name, sizeof(name));
	    UpdateLastSeen(i, name);
	}
    }
}
/* }}} UpdateAllLastSeen */

/* Command_Seen {{{ */
public Action:Command_Seen(client, args) {
    decl String:name[32];
    decl String:name_escaped[65];
    decl String:query[256];

    if (!args) {
	ReplyToCommand(client, "[LS] Usage: sm_seen <name>");
	return;
    }

    UpdateAllLastSeen();
    GetCmdArgString(name, sizeof(name));
    if (!SQL_EscapeString(db, name, name_escaped, sizeof(name_escaped))) {
	LogError("Could not escape client name string: \"%s\"", name);
	return;
    }

    if (g_SQLite) {
	Format(query, sizeof(query), "SELECT name, address, hostname, strftime('%%s', 'now') - strftime('%%s', seen) AS ls FROM %s WHERE name LIKE '%s' ORDER BY ls ASC LIMIT 1",
	    g_table_name,
	    name_escaped
	);
    }
    else {
	Format(query, sizeof(query), "SELECT name, address, hostname, UNIX_TIMESTAMP() - UNIX_TIMESTAMP(seen) AS ls FROM %s WHERE name LIKE '%s' ORDER BY ls ASC LIMIT 1",
	    g_table_name,
	    name_escaped
	);
    }

    new Handle:dp = CreateDataPack();
    WritePackCell(dp, client);
    WritePackString(dp, name);
    WritePackString(dp, name_escaped);
    WritePackCell(dp, true); /* Is this the first (exact match) query? */
    SQL_TQuery(db, T_SeenResults, query, dp);
}
/* }}} */

/* SecondsToTime {{{ */
stock SecondsToTime(time, String:time_s[], time_s_length) {
    new days = time / 86400;
    time %= 86400;
    new hours = time / 3600;
    time %= 3600;
    new mins = time / 60;
    time %= 60;

    decl String:times[4][8];
    new i = 0;

    if (days)  Format(times[i++], 8, "%dd", days);
    if (hours) Format(times[i++], 8, "%dh", hours);
    if (mins)  Format(times[i++], 8, "%dm", mins);
    Format(times[i++], 8, "%ds", time);

    ImplodeStrings(times, i, " ", time_s, time_s_length);
}
/* }}} SecondsToTime */

/* T_SeenResults {{{ */
public T_SeenResults(Handle:owner, Handle:hndl, const String:error[], any:dp) {
    if (hndl == INVALID_HANDLE) {
	LogError("Query failed: %s", error);
	CloseHandle(dp);
	return;
    }

    ResetPack(dp);
    decl String:name[32];
    decl String:name_escaped[65];
    new client = ReadPackCell(dp);
    ReadPackString(dp, name, sizeof(name));
    ReadPackString(dp, name_escaped, sizeof(name_escaped));
    new first = ReadPackCell(dp);
    
    new count = SQL_GetRowCount(hndl);
    if (count == 1) {
	DisplaySingleSeenResult(hndl, client);
	CloseHandle(dp);
    }
    else if (count == 0) {
	if (first) {
	    decl String:query[256];
	    SetPackPosition(dp, GetPackPosition(dp) - 8);
	    WritePackCell(dp, false);

	    if (g_SQLite) {
		Format(query, sizeof(query), "SELECT name, address, hostname, strftime('%%s', 'now') - strftime('%%s', seen) AS ls FROM %s WHERE name LIKE '%%%s%%' GROUP BY name ORDER BY ls ASC",
		    g_table_name,
		    name_escaped
		);
	    }
	    else {
		Format(query, sizeof(query), "SELECT name, address, hostname, UNIX_TIMESTAMP() - UNIX_TIMESTAMP(seen) AS ls FROM %s WHERE name LIKE '%%%s%%' GROUP BY name ORDER BY ls ASC",
		    g_table_name,
		    name_escaped
		);
	    }
	    SQL_TQuery(db, T_SeenResults, query, dp);
	}
	else {
	    if (client) {
		PrintToChatAll("!seen: No match found for \"%s\"", name);
	    }
	    else {
		PrintToServer("!seen: No match found for \"%s\"", name);
	    }
	    CloseHandle(dp);
	}
    }
    else {
	DisplayMultipleSeenResult(hndl, client, count);
	CloseHandle(dp);
    }
}
/* }}} T_SeenResults */

/* DisplayMultipleSeenResult {{{ */
stock DisplayMultipleSeenResult(Handle:hndl, client, count) {
    decl String:names[5][32];
    new i = 0;

    while (SQL_FetchRow(hndl) && i < 5) {
	SQL_FetchString(hndl, 0, names[i++], 32); 
    }

    decl String:names_imploded[256];
    ImplodeStrings(names, i, ", ", names_imploded, sizeof(names_imploded));

    if (i < count) {
	if (client) {
	    PrintToChatAll("!seen: Multiple matches found: %s, and %d more",
		names_imploded, count - i);
	}
	else {
	    PrintToServer("!seen: Multiple matches found: %s, and %d more",
		names_imploded, count - i);
	}
    }
    else {
	if (client) {
	    PrintToChatAll("!seen: Multiple matches found: %s",
		names_imploded);
	}
	else {
	    PrintToServer("!seen: Multiple matches found: %s",
		names_imploded);
	}
    }
}
/* }}} DisplayMultipleSeenResult */

/* DisplaySingleSeenResult {{{ */
stock DisplaySingleSeenResult(Handle:hndl, client) {
    decl String:name[32];
    decl time;
    decl String:address[32];
    decl String:hostname[64];

    SQL_FetchRow(hndl);
    SQL_FetchString(hndl, 0, name, sizeof(name));
    SQL_FetchString(hndl, 1, address, sizeof(address));
    SQL_FetchString(hndl, 2, hostname, sizeof(hostname));
    time = SQL_FetchInt(hndl, 3);

    if (time <= 1) {
	if (!strcmp(address, g_address)) {
	    Format(address, sizeof(address), "the server");
	}

	if (client) {
	    PrintToChatAll("!seen: %s is connected to %s now", name, address);
	}
	else {
	    PrintToServer("!seen: %s is connected to %s now", name, address);
	}
    }
    else {
	decl String:time_s[32];
	time_s[0] = 0;

	SecondsToTime(time, time_s, sizeof(time_s));

	if (!strcmp(address, g_address)) {
	    if (client) {
		PrintToChatAll("!seen: %s was last seen %s ago", name, time_s);
	    }
	    else {
		PrintToServer("!seen: %s was last seen %s ago", name, time_s);
	    }
	}
	else {
	    if (client) {
		PrintToChatAll("!seen: %s was last seen %s ago on %s (%s)",
		    name, time_s, hostname, address);
	    }
	    else {
		PrintToServer("!seen: %s was last seen %s ago on %s (%s)",
		    name, time_s, hostname, address);
	    }
	}
    }
}
/* }}} DisplaySingleSeenResult */

/* Native_GetNameFromAuthString {{{ */
public Native_GetNameFromAuthString(Handle:plugin, numParams) {
    decl String:auth[24];
    decl String:auth_escaped[49];

    GetNativeString(1, auth, sizeof(auth));
    if (!SQL_EscapeString(db, auth, auth_escaped, sizeof(auth_escaped))) {
	return _:false;
    }

    decl String:query[256];
    if (g_SQLite) {
	Format(query, sizeof(query), "SELECT name, strftime('%%s', 'now') - strftime('%%s', seen) AS ls FROM %s WHERE steamid = '%s' ORDER BY ls ASC LIMIT 1",
	    g_table_name,
	    auth_escaped
	);
    }
    else {
	Format(query, sizeof(query), "SELECT name, UNIX_TIMESTAMP() - UNIX_TIMESTAMP(seen) AS ls FROM %s WHERE steamid = '%s' ORDER BY ls ASC LIMIT 1",
	    g_table_name,
	    auth_escaped
	);
    }

    new callback = GetNativeCell(2);
    new data = 0;
    if (numParams == 3) {
	data = GetNativeCell(3);
    }
    new Handle:dp = CreateDataPack();
    WritePackCell(dp, _:plugin);
    WritePackCell(dp, callback);
    WritePackCell(dp, data);
    WritePackString(dp, auth);
    SQL_TQuery(db, T_GetNameFromAuthString, query, dp);

    return _:true;
}
/* }}} Native_GetNameFromAuthString */

/* T_GetNameFromAuthString {{{ */
public T_GetNameFromAuthString(Handle:owner, Handle:hndl, const String:error[], any:dp) {
    decl String:name[32];
    decl String:steamid[24];
    decl result;

    ResetPack(dp);
    new Handle:plugin = Handle:ReadPackCell(dp);
    new Function:callback = Function:ReadPackCell(dp);
    new data = ReadPackCell(dp);
    ReadPackString(dp, steamid, sizeof(steamid));
    CloseHandle(dp);

    Call_StartFunction(plugin, callback);
    if (SQL_GetRowCount(hndl)) {
	SQL_FetchRow(hndl);
	SQL_FetchString(hndl, 0, name, sizeof(name));
	Call_PushCell(true);
	Call_PushString(steamid);
	Call_PushString(name);
	Call_PushCell(data);
    }
    else {
	Call_PushCell(false);
	Call_PushString(steamid);
	Call_PushString("");
	Call_PushCell(data);
    }
    Call_Finish(result);
}
/* }}} T_GetNameFromAuthString */

