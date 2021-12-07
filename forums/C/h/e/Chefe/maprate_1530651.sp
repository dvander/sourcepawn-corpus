#pragma semicolon 1

#include <sourcemod>

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define MR_VERSION	    "1.2"

#define MAXLEN_MAP	    32

#define CVAR_DB_CONFIG	    0
#define CVAR_VERSION	    1
#define CVAR_AUTORATE_TIME  2
#define CVAR_ALLOW_REVOTE   3
#define CVAR_TABLE	    4
#define CVAR_AUTORATE_DELAY 5
#define CVAR_DISMISS	    6
#define CVAR_RESULTS	    7
#define CVAR_NUM_CVARS	    8

#define FLAG_RESET_RATINGS  ADMFLAG_VOTE

new String:g_current_map[64];
new Handle:db = INVALID_HANDLE;
new Handle:g_cvars[CVAR_NUM_CVARS];
new bool:g_SQLite = false;
new Handle:g_admin_menu = INVALID_HANDLE;
new String:g_table_name[32];
new g_lastRateTime[MAXPLAYERS+1];
new bool:g_dismiss = false;

enum MapRatingOrigin
{
	MRO_PlayerInitiated,
	MRO_ViewRatingsByRating,
	MRO_ViewRatingsByMap
};
new MapRatingOrigin:g_maprating_origins[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Map Rate",
	author = "Ryan \"FLOOR_MASTER\" Mannion & Chefe",
	description = "Allow players to rate the current map and view the map's average rating.",
	version = MR_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=1530651"
}

public OnPluginStart()
{
	LoadTranslations("maprate.phrases");
	
	RegConsoleCmd("sm_maprate", Command_Rate);
	RegConsoleCmd("sm_maprating", Command_Rating);
	/* RegConsoleCmd("sm_mapratings", Command_Ratings); */
	RegAdminCmd("sm_maprate_resetratings", Command_ResetRatings, FLAG_RESET_RATINGS);
	
	g_cvars[CVAR_DB_CONFIG] = CreateConVar("sm_maprate_db_config", "default", "Database configuration to use for Map Rate plugin", FCVAR_PLUGIN);
	g_cvars[CVAR_VERSION] = CreateConVar("sm_maprate_version", MR_VERSION, "Map Rate Version", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvars[CVAR_AUTORATE_TIME] = CreateConVar("sm_maprate_autorate_time", "0", "If non-zero, automatically asks dead players to rate map after they have played the map for this number of seconds", FCVAR_PLUGIN);
	g_cvars[CVAR_ALLOW_REVOTE] = CreateConVar("sm_maprate_allow_revote", "1", "If non-zero, allow a user to override his/her previous vote on a map", FCVAR_PLUGIN);
	g_cvars[CVAR_TABLE] = CreateConVar("sm_maprate_table", "map_ratings", "The name of the database table to use", FCVAR_PLUGIN);
	g_cvars[CVAR_AUTORATE_DELAY] = CreateConVar("sm_maprate_autorate_delay", "5", "After a player dies, wait this number of seconds before asking to rate if maprate_autorate_tie is non-zero", FCVAR_PLUGIN);
	g_cvars[CVAR_DISMISS] = CreateConVar("sm_maprate_dismiss", "0", "If non-zero, the first voting option will be \"Dismiss\"", FCVAR_PLUGIN);
	g_cvars[CVAR_RESULTS] = CreateConVar("sm_maprate_autoresults", "1", "If non-zero, the results graph will automatically be displayed when a player rates a map", FCVAR_PLUGIN);
	
	HookEvent("player_death", Event_PlayerDeath);
	AutoExecConfig(true, "maprate");
	
	g_dismiss = GetConVarBool(g_cvars[CVAR_DISMISS]);
	
	new Handle:top_menu;
	if (LibraryExists("adminmenu") && ((top_menu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(top_menu);
	}
}

public OnConfigsExecuted()
{
	GetConVarString(g_cvars[CVAR_TABLE], g_table_name, sizeof(g_table_name));
	g_dismiss = GetConVarBool(g_cvars[CVAR_DISMISS]);
	PrintToServer("[MAPRATE] Using table name \"%s\"", g_table_name);
	
	if (!ConnectDB())
	{
		LogError("FATAL: An error occurred while connecting to the database.");
		SetFailState("An error occurred while connecting to the database.");
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{
		g_admin_menu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_admin_menu)
	{
		return;
	}
	
	g_admin_menu = topmenu;
	
	new TopMenuObject:server_commands = FindTopMenuCategory(g_admin_menu, ADMINMENU_SERVERCOMMANDS);
	
	if (server_commands == INVALID_TOPMENUOBJECT)
	{
		return;
	}
	
	AddToTopMenu(g_admin_menu, "sm_all_maprate", TopMenuObject_Item, AdminMenu_AllRate, server_commands, "sm_all_maprate", ADMFLAG_VOTE);
}

public AdminMenu_AllRate(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayOption:
		{
			Format(buffer, maxlength, "%T", "Everyone Rate Command", param);
		}
		case TopMenuAction_SelectOption:
		{
			new max_clients = GetMaxClients();
			for (new i = 1; i <= max_clients; i++)
			{
				if (IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) > 0)
				{
					InitiateRate(i, g_current_map, false, param);
				}
			}
		}
	}
}

public OnMapStart()
{
	GetCurrentMap(g_current_map, sizeof(g_current_map));
	
	g_dismiss = GetConVarBool(g_cvars[CVAR_DISMISS]);
}

public OnMapEnd()
{
	if (db != INVALID_HANDLE)
	{
		CloseHandle(db);
		db = INVALID_HANDLE;
	}
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new autorateTime = GetConVarInt(g_cvars[CVAR_AUTORATE_TIME]);
	
	if (IsClientInGame(client) && !IsFakeClient(client) && autorateTime && g_lastRateTime[client] + autorateTime < GetTime())
	{
		new Float:time = GetConVarFloat(g_cvars[CVAR_AUTORATE_DELAY]);
		if (time >= 0.0)
		{
			decl String:steamid[24];
			GetClientAuthString(client, steamid, sizeof(steamid));
			new Handle:dp = CreateDataPack();
			WritePackCell(dp, client);
			WritePackString(dp, steamid);
			CreateTimer(time, Timer_AutoRateClient, dp);
		}
	}
	
	return Plugin_Continue;
}

public Action:Timer_AutoRateClient(Handle:timer, any:dp)
{
	decl String:steamid_orig[24];
	decl String:steamid[24];
	ResetPack(dp);
	new client = ReadPackCell(dp);
	ReadPackString(dp, steamid_orig, sizeof(steamid_orig));
	CloseHandle(dp);
	
	g_lastRateTime[client] = GetTime();
	
	if (IsClientConnected(client))
	{
		GetClientAuthString(client, steamid, sizeof(steamid));
		
		if (!strcmp(steamid, steamid_orig))
		{
			InitiateRate(client, g_current_map, false);
		}
	}
}

stock bool:ConnectDB()
{
	decl String:db_config[64];
	GetConVarString(g_cvars[CVAR_DB_CONFIG], db_config, sizeof(db_config));
	
	/* Verify that the configuration is defined in databases.cfg  */
	if (!SQL_CheckConfig(db_config))
	{
		LogError("Database configuration \"%s\" does not exist", db_config);
		return false;
	}
	
	/* Establish a connection */
	new String:error[256];
	db = SQL_Connect(db_config, true, error, sizeof(error));
	if (db == INVALID_HANDLE)
	{
		LogError("Error establishing database connection: %s", error);
		return false;
	}
	
	decl String:driver[32];
	SQL_ReadDriver(db, driver, sizeof(driver));
	
	if (!strcmp(driver, "sqlite"))
	{
		g_SQLite = true;
	}
	
	decl String:query[256];
	
	if (g_SQLite)
	{
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (steamid TEXT, map TEXT, rating INTEGER, rated DATE, UNIQUE (map, steamid))", g_table_name);
		if (!SQL_FastQuery(db, query)) {
			new String:sqlerror[300];
			SQL_GetError(db, sqlerror, sizeof(sqlerror));
			LogError("FATAL: Could not create table %s. (%s)", g_table_name, sqlerror);
			SetFailState("Could not create table %s.", g_table_name);
		}
	}
	else
	{
		Format(query, sizeof(query), "CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR(24), map VARCHAR(48), rating INT(4), rated DATETIME, UNIQUE KEY (map, steamid))", g_table_name);
		if (!SQL_FastQuery(db, query))
		{
			new String:sqlerror[300];
			SQL_GetError(db, sqlerror, sizeof(sqlerror)); 
			LogError("FATAL: Could not create table %s. (%s)", g_table_name, sqlerror);
			SetFailState("Could not create table %s.", g_table_name);
		}
	}
	
	return true;
}

public Menu_Rate(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	
	switch (action)
	{
		/* User selected a rating - update database */
		case MenuAction_Select:
		{
			decl String:steamid[24];
			decl String:map[MAXLEN_MAP];
			GetClientAuthString(client, steamid, sizeof(steamid));
			
			if (!GetMenuItem(menu, param2, map, sizeof(map)))
			{
				return;
			}
			
			if (g_dismiss && param2 == 0)
			{
				return;
			}
			
			/* param2 is the menu selection index starting from 0 */
			new rating = param2 + 1 - (g_dismiss ? 1 : 0);
			
			decl String:query[256];
			
			if (g_SQLite)
			{
				Format(query, sizeof(query), "REPLACE INTO %s VALUES ('%s', '%s', %d, DATETIME('NOW'))", g_table_name, steamid, map, rating);
			}
			else
			{
				Format(query, sizeof(query), "INSERT INTO %s SET map = '%s', steamid = '%s', rating = %d, rated = NOW() ON DUPLICATE KEY UPDATE rating = %d, rated = NOW()", g_table_name, map, steamid, rating, rating);
			}
			LogAction(client, -1, "%L rated %s: %d", client, map, rating);
			
			new Handle:dp = CreateDataPack();
			WritePackCell(dp, client);
			WritePackString(dp, map);
			SQL_TQuery(db, T_PostRating, query, dp);
		}
		case MenuAction_Cancel:
		{
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:Command_Rating(client, args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	
	CreateMenuRatings(client);
	
	return Plugin_Handled;
}

stock CreateMenuRatings(client)
{
	new Handle:menu = CreateMenu(Menu_Ratings);
	decl String:text[64];
	Format(text, sizeof(text), "%T", "View Ratings", client);
	SetMenuTitle(menu, text);
	AddMenuItem(menu, "none", g_current_map);
	Format(text, sizeof(text), "%T", "Ordered by Rating", client);
	AddMenuItem(menu, "rating", text);
	Format(text, sizeof(text), "%T", "Ordered by Map Name", client);
	AddMenuItem(menu, "map", text);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 300);
}

public Menu_Ratings(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 0:
				{
					g_maprating_origins[client] = MRO_PlayerInitiated;
					GetMapRating(client, g_current_map);
				}
				case 1:
				{
					ViewRatingsByRating(client);
				}
				case 2:
				{
					ViewRatingsByMap(client);
				}
			}
		}
		
		case MenuAction_Cancel:
		{
		}
		
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

stock ViewRatingsByRating(client)
{
	new Handle:dp = CreateDataPack();
	WritePackCell(dp, client);
	decl String:text[64];
	Format(text, sizeof(text), "%T", "Ordered by Rating Title", client);
	WritePackString(dp, text);
	g_maprating_origins[client] = MRO_ViewRatingsByRating;
	
	decl String:query[256];
	Format(query, sizeof(query), "SELECT map, AVG(rating) AS rating, COUNT(*) AS ratings FROM %s GROUP BY map ORDER BY rating DESC", g_table_name);
	SQL_TQuery(db, T_CreateMenuRatingsResults, query, dp);
}

stock ViewRatingsByMap(client)
{
	new Handle:dp = CreateDataPack();
	WritePackCell(dp, client);
	decl String:text[64];
	Format(text, sizeof(text), "%T", "Ordered by Map Name Title", client);
	WritePackString(dp, text);
	g_maprating_origins[client] = MRO_ViewRatingsByMap;
	
	decl String:query[256];
	Format(query, sizeof(query), "SELECT map, AVG(rating) AS rating, COUNT(*) AS ratings FROM %s GROUP BY map ORDER BY map", g_table_name);
	SQL_TQuery(db, T_CreateMenuRatingsResults, query, dp);
}

public T_CreateMenuRatingsResults(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		PrintToChat(data, "A database error occurred. Please try again later.");
		return;
	}
	
	ResetPack(data);
	new client = ReadPackCell(data);
	decl String:menu_title[64];
	ReadPackString(data, menu_title, sizeof(menu_title));
	CloseHandle(data);
	
	new Handle:menu = CreateMenu(Menu_ViewMapRatings);
	
	decl String:map[MAXLEN_MAP];
	new Float:rating;
	new ratings;
	decl String:menu_item[128];
	
	while (SQL_FetchRow(hndl))
	{
		SQL_FetchString(hndl, 0, map, sizeof(map));
		rating = SQL_FetchFloat(hndl, 1);
		ratings = SQL_FetchInt(hndl, 2);
		
		Format(menu_item, sizeof(menu_item), "%.2f %s (%d)", rating, map, ratings);
		AddMenuItem(menu, map, menu_item);
	}
	CloseHandle(hndl);
	
	SetMenuTitle(menu, menu_title);
	SetMenuExitButton(menu, true);
	SetMenuExitBackButton(menu, true);
	DisplayMenu(menu, client, 300);
}

public Menu_ViewMapRatings(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	
	switch (action)
	{
		case MenuAction_Select:
		{
			decl String:map[MAXLEN_MAP];
			if (GetMenuItem(menu, param2, map, sizeof(map)))
			{
				GetMapRating(client, map);
			}
		}
		case MenuAction_Cancel:
		{
			switch (param2)
			{
				case MenuCancel_ExitBack:
				{
					CreateMenuRatings(client);
				}
			}
		}
		case MenuAction_End: {
			CloseHandle(menu);
		}
	}
}

public T_CreateMenuRating(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ResetPack(data);
	new client = ReadPackCell(data);
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		CloseHandle(data);
		PrintToChat(client, "A database error occurred. Please try again later.");
		return;
	}
	
	decl String:map[MAXLEN_MAP];
	ReadPackString(data, map, sizeof(map));
	new my_rating = ReadPackCell(data);
	CloseHandle(data);
	
	/* This is kind of ugly */
	new rating = 0;
	new arr_ratings[5] = {0, 0, 0, 0, 0};
	new ratings = 0;
	new total_ratings = 0;
	new total_rating = 0;
	decl String:menu_item[64];
	
	while (SQL_FetchRow(hndl))
	{
		rating = SQL_FetchInt(hndl, 0);
		ratings = SQL_FetchInt(hndl, 1);
		total_rating += rating * ratings;
		
		arr_ratings[rating - 1] = ratings;
		total_ratings += ratings;
	}
	CloseHandle(hndl);
	
	/* Now build the menu */
	decl String:menu_title[64];
	new Handle:menu = CreateMenu(Menu_ViewRating);
	
	new Float:average_rating = 0.0;
	if (total_ratings)
	{
		average_rating = float(total_rating) / float(total_ratings);
	}
	
	Format(menu_title, sizeof(menu_title), "%T\n%T", "Ratings Title", client, map, "Average Rating", client, average_rating);
	if (my_rating)
	{
		Format(menu_title, sizeof(menu_title), "%s\n%T", menu_title, "Your Rating", client, my_rating);
	}
	SetMenuTitle(menu, menu_title);
	
	/* VARIABLE WIDTH FONTS ARE EVIL */
	new bars[5];
	new max_bars = 0;
	if (total_ratings)
	{
		for (new i = 0; i < sizeof(arr_ratings); i++)
		{
			bars[i] = RoundToNearest(float(arr_ratings[i] * 100 / total_ratings) / 5);
			max_bars = (bars[i] > max_bars ? bars[i] : max_bars);
		}
		
		if (max_bars >= 15)
		{
			for (new i = 0; i < sizeof(arr_ratings); i++)
			{
				bars[i] /= 2;
			}
			max_bars /= 2;
		}
	}
	decl String:menu_item_bars[64];
	new String:rating_phrase[] = "1 Star";
	for (new i = 0; i < sizeof(arr_ratings); i++)
	{
		new j;
		for (j = 0; j < bars[i]; j++)
		{
			menu_item_bars[j] = '=';
		}
		new max = RoundToNearest(float(max_bars - j) * 2.5) + j;
		for (; j < max; j++)
		{
			menu_item_bars[j] = ' ';
		}
		menu_item_bars[j] = 0;
		
		rating_phrase[0] = '1' + i;
		Format(menu_item, sizeof(menu_item), "%s (%T - %T)", menu_item_bars, rating_phrase, client, (arr_ratings[i] == 1 ? "Rating" : "Rating Plural"), client, arr_ratings[i]);
		/* AddMenuItem(menu, map, menu_item, ITEMDRAW_DISABLED); */
		AddMenuItem(menu, map, menu_item);
	}
	
	decl String:text[64];
	if (!my_rating)
	{
		Format(text, sizeof(text), "%T", "Rate Map", client);
		AddMenuItem(menu, map, text);
	}
	else if (GetConVarInt(g_cvars[CVAR_ALLOW_REVOTE]))
	{
		Format(text, sizeof(text), "%T", "Change Rating", client);
		AddMenuItem(menu, map, text);
	}
	
	SetMenuExitBackButton(menu, true);
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 300);
}

public Menu_ViewRating(Handle:menu, MenuAction:action, param1, param2)
{
	new client = param1;
	
	switch (action)
	{
		case MenuAction_Select:
		{
			switch (param2)
			{
				case 5:
				{
					decl String:map[MAXLEN_MAP];
					if (GetMenuItem(menu, param2, map, sizeof(map)))
					{
						InitiateRate(client, map, true);
					}
				}
			}
		}
		case MenuAction_Cancel:
		{
			switch (param2)
			{
				case MenuCancel_ExitBack:
				{
					switch (g_maprating_origins[client])
					{
						case MRO_PlayerInitiated:
						{
							CreateMenuRatings(client);
						}
						case MRO_ViewRatingsByRating:
						{
							ViewRatingsByRating(client);
						}
						case MRO_ViewRatingsByMap:
						{
							ViewRatingsByMap(client);
						}
					}
				}
			}
		}
		case MenuAction_End:
		{
			CloseHandle(menu);
		}
	}
}

public Action:Command_Rate(client, args)
{
	if (!client)
	{
		return Plugin_Handled;
	}
	
	InitiateRate(client, g_current_map, true);
	return Plugin_Handled;
}

stock InitiateRate(client, const String:map[], bool:voluntary, initiator = 0)
{
	decl String:steamid[24];
	GetClientAuthString(client, steamid, sizeof(steamid));
	
	new Handle:dp = CreateDataPack();
	WritePackCell(dp, client);
	WritePackString(dp, map);
	WritePackCell(dp, voluntary);
	WritePackCell(dp, initiator);
	
	decl String:query[256];
	Format(query, sizeof(query), "SELECT rating FROM %s WHERE map = '%s' AND steamid = '%s'", g_table_name, map, steamid);
	SQL_TQuery(db, T_CreateMenuRate, query, dp);
}

public T_PostRating(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ResetPack(data);
	new client = ReadPackCell(data);
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		PrintToChat(client, "%t", "Database Error");
		CloseHandle(data);
		return;
	}
	
	decl String:map[MAXLEN_MAP];
	ReadPackString(data, map, sizeof(map));
	CloseHandle(data);
	
	PrintToChat(client, "\03%t", "Successful Rate", map);
	g_maprating_origins[client] = MRO_PlayerInitiated;
	
	if (GetConVarInt(g_cvars[CVAR_RESULTS]))
	{
		GetMapRating(client, map);
	}
}

stock GetMapRating(client, const String:map[])
{
	new Handle:dp = CreateDataPack();
	WritePackCell(dp, client);
	WritePackString(dp, map);
	
	decl String:steamid[24];
	GetClientAuthString(client, steamid, sizeof(steamid));
	
	decl String:query[256];
	Format(query, sizeof(query), "SELECT rating FROM %s WHERE steamid = '%s' AND map = '%s'", g_table_name, steamid, map);
	SQL_TQuery(db, T_GetMapRating2, query, dp);
}

public T_GetMapRating2(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	ResetPack(data);
	new client = ReadPackCell(data);
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		PrintToChat(data, "%t", "Database Error");
		CloseHandle(data);
		return;
	}
	
	decl String:map[MAXLEN_MAP];
	ReadPackString(data, map, sizeof(map));
	CloseHandle(data);
	
	new Handle:dp = CreateDataPack();
	WritePackCell(dp, client);
	WritePackString(dp, map);
	
	if (SQL_GetRowCount(hndl) == 1)
	{
		SQL_FetchRow(hndl);
		WritePackCell(dp, SQL_FetchInt(hndl, 0));
	}
	else
	{
		WritePackCell(dp, 0);
	}
	CloseHandle(hndl);
	
	decl String:query[256];
	Format(query, sizeof(query), "SELECT rating, COUNT(*) FROM %s WHERE map = '%s' GROUP BY rating ORDER BY rating DESC", g_table_name, map);
	SQL_TQuery(db, T_CreateMenuRating, query, dp);
}

public T_CreateMenuRate(Handle:owner, Handle:hndl, const String:error[], any:data)
{	
	ResetPack(data);
	new client = ReadPackCell(data);
	
	if (hndl == INVALID_HANDLE)
	{
		LogError("Query failed! %s", error);
		if (IsClientConnected(client))
		{
			PrintToChat(client, "%t", "Database Error");
		}
		CloseHandle(data);
		return;
	}
	
	decl String:map[MAXLEN_MAP];    
	ReadPackString(data, map, sizeof(map));
	new bool:voluntary =    bool:ReadPackCell(data);
	new initiator =	    ReadPackCell(data);
	new rating =	    0;
	
	CloseHandle(data);
	
	new allow_revote = GetConVarInt(g_cvars[CVAR_ALLOW_REVOTE]);
	
	/* The player has rated this map before */
	if (SQL_GetRowCount(hndl) == 1)
	{
		SQL_FetchRow(hndl);
		rating = SQL_FetchInt(hndl, 0);
		
		/* If the user didn't initiate the maprate, just ignore the request */
		if (!voluntary)
		{
			return;
		}
		
		/* Deny rerating if the applicable cvar is set */
		else if (!allow_revote)
		{
			PrintToChat(client, "\03%t", "Already Rated", rating);
			return;
		}
	}
	CloseHandle(hndl);
	
	decl String:title[256];
	
	/* If an initiator was set, then this map rating request was initiated by
	* an admin. We'll specify who in the map rate panel title. */
	if (initiator)
	{
		decl String:initiator_name[32];
		GetClientName(initiator, initiator_name, sizeof(initiator_name));
		Format(title, sizeof(title), "%T", "Everyone Rate Title",
		client, initiator_name, g_current_map);
	}
	else
	{
		Format(title, sizeof(title), "%T", "Rate Map Title", client, map);
	}
	
	/* If the player already rated this map, show the previous rating. */
	if (rating)
	{
		Format(title, sizeof(title), "%s\n%T", title, "Previous Rating", client, rating);
	}
	
	/* Build the menu panel */
	new Handle:menu = CreateMenu(Menu_Rate);
	SetMenuTitle(menu, title);
	
	decl String:menu_item[128];
	
	if (g_dismiss)
	{
		Format(menu_item, sizeof(menu_item), "%T", "Dismiss", client);
		AddMenuItem(menu, "dismiss", menu_item);
	}
	
	new String:rating_phrase[] = "1 Star";
	for (new i = 0; i < 5; i++)
	{
		rating_phrase[0] = '1' + i;
		Format(menu_item, sizeof(menu_item), "%T", rating_phrase, client);
		AddMenuItem(menu, map, menu_item);
	}
	SetMenuExitButton(menu, true);
	DisplayMenu(menu, client, 300);
}

public Action:Command_ResetRatings(client, args)
{
	ResetRatings(client, g_current_map);
	
	return Plugin_Handled;
}

stock ResetRatings(client, const String:map[])
{
	decl String:query[256];
	
	Format(query, sizeof(query), "DELETE FROM %s WHERE map = '%s'", 
	g_table_name, map);
	PrintToServer(query);
	SQL_LockDatabase(db);
	SQL_FastQuery(db, query);
	SQL_UnlockDatabase(db);
	
	LogAction(client, -1, "%L reset ratings for map %s", client, g_current_map);
}

public OnClientPostAdminCheck(client)
{
	g_lastRateTime[client] = GetTime();
}