/** 
 * vim: set filetype=c :
 *
 * =============================================================================
 * Map Rate
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

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define MR_VERSION	    "0.4"

#define CVAR_DB_CONFIG	    0
#define CVAR_VERSION	    1
#define CVAR_AUTORATE_TIME  2
#define CVAR_ALLOW_REVOTE   3
#define CVAR_NUM_CVARS	    4

new String:g_current_map[64];
new Handle:db = INVALID_HANDLE;
new Handle:g_cvars[CVAR_NUM_CVARS];
new bool:g_SQLite = false;
new bool:g_autorate = false;
new Handle:g_admin_menu = INVALID_HANDLE;
new Handle:g_autorate_timer = INVALID_HANDLE;

public Plugin:myinfo = {
    name = "Map Rate",
    author = "Ryan \"FLOOR_MASTER\" Mannion",
    description = "Allow players to rate the current map and view the map's average rating.",
    version = MR_VERSION,
    url = "http://www.2fort2furious.com"
};

public OnPluginStart() {
    RegConsoleCmd("sm_maprate", Command_Rate);
    RegConsoleCmd("sm_maprating", Command_Rating);
    RegAdminCmd("sm_maprate_resetratings", Command_ResetRatings, ADMFLAG_VOTE);

    g_cvars[CVAR_DB_CONFIG] = CreateConVar(
	"maprate_db_config",
	"default",
	"Database configuration to use for Map Rate plugin",
	FCVAR_PLUGIN);

    g_cvars[CVAR_VERSION] = CreateConVar(
	"maprate_version",
	MR_VERSION,
	"Map Rate Version",
	FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

    g_cvars[CVAR_AUTORATE_TIME] = CreateConVar(
	"maprate_autorate_time",
	"0",
	"If non-zero, automatically asks dead players to rate map after this number of seconds",
	FCVAR_PLUGIN);

    g_cvars[CVAR_ALLOW_REVOTE] = CreateConVar(
	"maprate_allow_revote",
	"1",
	"If non-zero, allow a user to override his/her previous vote on a map",
	FCVAR_PLUGIN);

    if (!ConnectDB()) {
        LogError("FATAL: An error occurred while connecting to the database.");
        SetFailState("An error occurred while connecting to the database.");
    }

    HookEvent("player_death", Event_PlayerDeath);

    new Handle:top_menu;
    if (LibraryExists("adminmenu") && ((top_menu = GetAdminTopMenu()) != INVALID_HANDLE)) {
	OnAdminMenuReady(top_menu);
    }
}

public OnLibraryRemoved(const String:name[]) {
    if (StrEqual(name, "adminmenu")) {
	g_admin_menu = INVALID_HANDLE;
    }
}

public OnAdminMenuReady(Handle:topmenu) {
    if (topmenu == g_admin_menu) {
	return;
    }

    g_admin_menu = topmenu;

    new TopMenuObject:server_commands = FindTopMenuCategory(g_admin_menu, ADMINMENU_SERVERCOMMANDS);
    
    if (server_commands == INVALID_TOPMENUOBJECT) {
	return;
    }

    AddToTopMenu(g_admin_menu,
	"sm_all_maprate",
	TopMenuObject_Item,
	AdminMenu_AllRate,
	server_commands,
	"sm_all_maprate",
	ADMFLAG_VOTE
    );
}

public AdminMenu_AllRate(Handle:topmenu, TopMenuAction:action,
    TopMenuObject:object_id, param, String:buffer[], maxlength) {

    switch (action) {
    case TopMenuAction_DisplayOption: {
	Format(buffer, maxlength, "Have All Players Rate This Map");
    }
    case TopMenuAction_SelectOption: {
	new max_clients = GetMaxClients();
	for (new i = 1; i <= max_clients; i++) {
	    if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 0) {
		InitiateRate(i, false, param);
	    }
	}
    }
    }
}

public OnMapStart() {
    new autorate_time = GetConVarInt(g_cvars[CVAR_AUTORATE_TIME]);
    // TODO: Sanitize map name for SQL?
    GetCurrentMap(g_current_map, sizeof(g_current_map));
    g_autorate = false;
    if (autorate_time) {
	g_autorate_timer = CreateTimer(float(autorate_time), Timer_AutoRate);
    }
}

public OnMapEnd() {
/*
    if (g_autorate_timer != INVALID_HANDLE) {
	CloseHandle(g_autorate_timer);
    }
*/
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
    new client = GetClientOfUserId(GetEventInt(event, "userid"));

    if (g_autorate && !IsFakeClient(client)) {
    	InitiateRate(client, false);
    }

    return Plugin_Continue;
}

public Action:Timer_AutoRate(Handle:timer) {
    PrintToServer("[MAPRATE] Timer expired, now asking dead players to rate map");
    g_autorate = true;
}

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

    if (g_SQLite) {
	if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS map_ratings (steamid TEXT, map TEXT, rating INTEGER, rated DATE, UNIQUE (map, steamid))")) {
    	    LogError("FATAL: Could not create table map_ratings.");
    	    SetFailState("Could not create table map_ratings.");
	}
    }
    else {
	if (!SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS map_ratings (steamid VARCHAR(24), map VARCHAR(48), rating INT(4), rated DATETIME, UNIQUE KEY (map, steamid))")) {
    	    LogError("FATAL: Could not create table map_ratings.");
    	    SetFailState("Could not create table map_ratings.");
    	}
    }

    return true;
}
/* }}} END ConnectDB */

public MenuRate(Handle:menu, MenuAction:action, param1, param2) {
    new client = param1;

    switch (action) {
	case MenuAction_Select: {
	    decl String:steamid[24];
	    GetClientAuthString(client, steamid, sizeof(steamid));

	    new rating = param2 + 1;
	    decl String:query[256];

	    if (g_SQLite) {
		Format(query, sizeof(query), "REPLACE INTO map_ratings VALUES ('%s', '%s', %d, DATETIME('NOW'))",
		    steamid,
	    	    g_current_map, 
	    	    rating
	    	);
	    }
	    else {
		Format(query, sizeof(query), "INSERT INTO map_ratings SET map = '%s', steamid = '%s', rating = %d, rated = NOW() ON DUPLICATE KEY UPDATE rating = %d, rated = NOW()",
	    	    g_current_map, 
	    	    steamid,
	    	    rating,
	    	    rating
	    	);
	    }
	    LogAction(client, -1, "%L rated %s: %d", client, g_current_map, rating);
	    SQL_TQuery(db, T_PostRating, query, client);
	}

	case MenuAction_Cancel: {
	}

	case MenuAction_End: {
	    CloseHandle(menu);
	}
    }
}

public Action:Command_Rating(client, args) {
    if (!client) return Plugin_Handled;

    GetMapRating(client);
    return Plugin_Handled;
}

public Action:Command_Rate(client, args) {
    if (!client) return Plugin_Handled;

    InitiateRate(client, true);
    return Plugin_Handled;
}

stock InitiateRate(client, bool:voluntary, initiator = 0) {
    decl String:steamid[24];
    GetClientAuthString(client, steamid, sizeof(steamid));

    new Handle:dp = CreateDataPack();
    WritePackCell(dp, client);
    WritePackCell(dp, voluntary);
    WritePackCell(dp, initiator);

    decl String:query[256];
    Format(query, sizeof(query), "SELECT rating FROM map_ratings WHERE map = '%s' AND steamid = '%s'",
	g_current_map, steamid);
    SQL_TQuery(db, T_CreateMenuRate, query, dp);
}

public T_PostRating(Handle:owner, Handle:hndl, const String:error[], any:data) {
    if (hndl == INVALID_HANDLE) {
	LogError("Query failed! %s", error);
	PrintToChat(data, "A database error occurred. Please try again later.");
	return;
    }

    new client = data;
    PrintToChat(client, "\03You successfully rated %s", g_current_map);
    GetMapRating(client);
}

stock GetMapRating(client) {
    decl String:query[256];
    Format(query, sizeof(query), "SELECT AVG(rating), COUNT(*) FROM map_ratings WHERE map = '%s'", g_current_map);
    SQL_TQuery(db, T_GotMapRating, query, client);
}

public T_GotMapRating(Handle:owner, Handle:hndl, const String:error[], any:data) {

    if (hndl == INVALID_HANDLE) {
	LogError("Query failed! %s", error);
	PrintToChat(data, "A database error occurred. Please try again later.");
	return;
    }

    new client = data;

    if (SQL_GetRowCount(hndl) == 1) {
	SQL_FetchRow(hndl);
	new Float:rating = SQL_FetchFloat(hndl, 0);
	new ratings = SQL_FetchInt(hndl, 1);

	if (ratings) {
	    PrintToChat(client, "\03%s is rated: %.2f (%d rating%s)", 
	        g_current_map,
	        rating,
	        ratings,
	        (ratings == 1 ? "" : "s")
	    );
	}
	else {
	    PrintToChat(client, "\03%s has not yet been rated", g_current_map);
	}
    }
}

public T_CreateMenuRate(Handle:owner, Handle:hndl, const String:error[], any:data) {

    if (hndl == INVALID_HANDLE) {
	LogError("Query failed! %s", error);
	PrintToChat(data, "A database error occurred. Please try again later.");
	return;
    }

    ResetPack(data);
    new client = ReadPackCell(data);
    new bool:voluntary = bool:ReadPackCell(data);
    new initiator = ReadPackCell(data);
    CloseHandle(data);
    new rating = 0;

    new allow_revote = GetConVarInt(g_cvars[CVAR_ALLOW_REVOTE]);

    if (SQL_GetRowCount(hndl) == 1) {
	SQL_FetchRow(hndl);
	rating = SQL_FetchInt(hndl, 0);
	if (!voluntary) {
	    return;
	}
	else if (!allow_revote) {
	    PrintToChat(client, "\03You already rated this map a %d and cannot change your vote", rating);
	    return;
	}
    }
    
    decl String:title[256];

    if (initiator) {
	decl String:initiator_name[32];
	GetClientName(initiator, initiator_name, sizeof(initiator_name));
	Format(title, sizeof(title), "%s has requested that you rate %s",
	    initiator_name, g_current_map);
    }
    else {
	Format(title, sizeof(title), "Please rate %s", g_current_map);
    }

    if (rating) {
	Format(title, sizeof(title), "%s\nYou previously rated this map: %d", title, rating);
    }

    new Handle:menu = CreateMenu(MenuRate);
    SetMenuTitle(menu, title);
    AddMenuItem(menu, "1", "Terrible");
    AddMenuItem(menu, "2", "Poor");
    AddMenuItem(menu, "3", "Average");
    AddMenuItem(menu, "4", "Good");
    AddMenuItem(menu, "5", "Excellent");
    SetMenuExitButton(menu, true);
    DisplayMenu(menu, client, 20);

}

public Action:Command_ResetRatings(client, args) {
    decl String:query[256];

    Format(query, sizeof(query), "DELETE FROM map_ratings WHERE map = '%s'", g_current_map);
    PrintToServer(query);
    SQL_LockDatabase(db);
    SQL_FastQuery(db, query);
    SQL_UnlockDatabase(db);

    LogAction(client, -1, "%L reset ratings for map %s", client, g_current_map);
}

public OnPluginEnd() {
}

