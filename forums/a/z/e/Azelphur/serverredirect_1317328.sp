/*
This program is free software; you can redistribute it and/or
modify it under the terms of the GNU General Public License
as published by the Free Software Foundation; either version 2
of the License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program; if not, write to the Free Software
Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston, MA  02110-1301, USA.
*/

/*

Versions:
	1.1
	    ! Fixed settings not being applied properly
		! Fixed package (proper lay-out and correct files)
		! Fixed mysql script, commented the create database statement and fixed syntax.
		? Now uses sv_maxvisibleplayers by default to determine max amount of players. Provides compatibility
			with reserved slot plugins. If sv_visiblemaxplayers is not set (less than 0), it'll
			use the maximum amount of player slots on the server.
		+ Added sm_redirect_menusort to be able to choose how items get sorted.
		+ Added sm_redirect_enableheartbeat tobe able to enable/disable the heartbeat. Can be used to (temporarily) disable
			the plugin and avoid advertising the server.
 
	1.0 - initial release
	
*/


#include <sourcemod>
#include <serverredirect>
#pragma semicolon 1

#define PLUGIN_VERSION "1.1"
// amount of seconds after which a server is considered to be offline. Offline servers will not show up in the redirect window.
#define SERVER_TIMEOUT_SECONDS 120
// interval at which the database is updated
#define SERVER_UPDATE_INTERVAL 30.0

#define ADDRESS_OFFLINE "#OFFLINE#"
#define TRANSLATION_FILE "serverredirect.phrases.txt"
#define DATABASE_KEY "serverredirect"
#define CHAT_COLOR 0x04

new Handle:g_varServerId;								// ID of the server
new Handle:g_varShowCurrent;							// Whether to show the current server in the redirect menu
new Handle:g_varShowOffline;							// Whether to show offline servers in the redirect menu
new Handle:g_varSvMaxVisiblePlayers;					// sv_visiblemaxplayers var
new Handle:g_varMenuSortMode;							// Sort mode in the menu (1 = by name, 2 = by ID)
new Handle:g_varHeartbeatEnabled;						// Whether the heartbeat function is enabled
new Handle:g_varDisableCurrent;							// Set the current server to ITEMDRAW_DISABLED in the menu
new Handle:g_varDisableOffline;							// Set offline servers to ITEMDRAW_DISABLED in the menu

new Handle:g_updateTimer = INVALID_HANDLE;				// update timer handler
new Handle:g_hDatabase = INVALID_HANDLE;				// database handle
new Handle:g_hQueryUpdate = INVALID_HANDLE;				// query for updating current status

new g_fakeClientCount;									// amount of fake clients
new bool:g_playerCountChanged;							// whether the amount of players has changed

public Plugin:myinfo = 
{
	name = "Server Redirect",
	author = "Brainstorm",
	description = "Allows players to switch to a different server.",
	version = PLUGIN_VERSION,
	url = "http://www.teamfortress.be"
}

public OnPluginStart()
{
	RegPluginLibrary("serverredir");
	
	g_fakeClientCount = 0;
	
	CreateConVar("sm_redirect_version", PLUGIN_VERSION, "Version number of server redirect plugin.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_varServerId = CreateConVar("sm_redirect_serverid", "0", "sm_redirect_serverid - ID of the server in the database.", 0, true, 0.0, false);
	g_varShowCurrent = CreateConVar("sm_redirect_showcurrent", "1", "sm_redirect_showcurrent - Whether to show the current server in the redirect menu", 0, true, 0.0, true, 1.0);
	g_varShowOffline = CreateConVar("sm_redirect_showoffline", "1", "sm_redirect_showoffline - Whether to show offline servers in the redirect menu", 0, true, 0.0, true, 1.0);
	g_varMenuSortMode = CreateConVar("sm_redirect_menusort", "1", "sm_redirect_menusort - Indicates how menu items get sorted. 1 = by display name (default), 2 = by server ID", 0, true, 1.0, false);
	g_varDisableCurrent = CreateConVar("sm_redirect_disablecurrent", "1", "sm_redirect_disablecurrent - Disable (Grey out) the current server in the menu.", 0, true, 1.0, false);
	g_varDisableOffline = CreateConVar("sm_redirect_disableoffline", "1", "sm_redirect_disableoffline - Disable (Grey out) offline servers in the menu.", 0, true, 1.0, false);

	g_varSvMaxVisiblePlayers = FindConVar("sv_visiblemaxplayers");
	g_varHeartbeatEnabled = CreateConVar("sm_redirect_enableheartbeat", "1", "sm_redirect_enableheartbeat - Whether to enable heartbeat signal for this server. If stopped, the server will be marked as offline.", 0, true, 0.0, true, 1.0);
	if (g_varSvMaxVisiblePlayers == INVALID_HANDLE)
	{
		SetFailState("Unable to find sv_visiblemaxplayers, I need this var please.");
	}
	
	LoadTranslations(TRANSLATION_FILE);
	
	// register events
	RegConsoleCmd("sm_server", Command_ShowMenu);
	RegConsoleCmd("sm_servers", Command_ShowMenu);
	RegConsoleCmd("sm_swapme", Command_ShowMenu);

	AutoExecConfig(true, "plugin.serverredirect");
	
}

public OnPluginEnd()
{
	DisconnectFromDatabase();
}

/*public OnConfigsExecuted()
{
}*/

public OnMapStart()
{
	g_playerCountChanged = true;
	new bool:isEnabled = GetConVarBool(g_varHeartbeatEnabled);
	if (isEnabled)
	{
		StartStatusUpdateTimer();
	}
	HookConVarChange(g_varHeartbeatEnabled, OnHeartBeatEnableChange);
}

public OnMapEnd()
{
	EndStatusUpdateTimer();
	UnhookConVarChange(g_varHeartbeatEnabled, OnHeartBeatEnableChange);
}

public OnHeartBeatEnableChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new bool:newVal = GetConVarBool(g_varHeartbeatEnabled);
	if (newVal)
	{
		// create timer if needed
		if (g_updateTimer == INVALID_HANDLE)
		{
			StartStatusUpdateTimer();
			UpdateStatus();
		}
	}
	else
	{
		EndStatusUpdateTimer();
	}
}

CountFakePlayers()
{
	new fakeClientCount = 0;
	new maxClients = GetMaxClients();
	
	for (new i=1; i <= maxClients; i++)
	{
		if (IsClientConnected(i) && IsFakeClient(i))
		{
			fakeClientCount++;
		}
	}
	
	g_fakeClientCount = fakeClientCount;
}

public OnClientConnected(client)
{
	g_playerCountChanged = true;
	
	UpdateStatus();
	return true;
}

public OnClientDisconnect(client)
{
}

public OnClientDisconnect_Post(client)
{
	g_playerCountChanged = true;
	UpdateStatus();
}

StartStatusUpdateTimer()
{
	EndStatusUpdateTimer();
	g_updateTimer = CreateTimer(SERVER_UPDATE_INTERVAL, Timer_StatusUpdate, INVALID_HANDLE, TIMER_REPEAT);
}

EndStatusUpdateTimer()
{
	if (g_updateTimer != INVALID_HANDLE)
	{
		KillTimer(g_updateTimer);
		g_updateTimer = INVALID_HANDLE;
	}
}

public Action:Timer_StatusUpdate(Handle:timer)
{
	UpdateStatus();
}

public Action:Command_ShowMenu(client, args)
{
	ShowServerMenu(client);		
	return Plugin_Handled;
}

ShowServerMenu(client)
{
	if (!IsClientConnected(client) || IsFakeClient(client))
	{
		return;
	}
	
	new serverId = GetConVarInt(g_varServerId);
	new bool:showOffline = GetConVarBool(g_varShowOffline);
	new bool:showCurrent = GetConVarBool(g_varShowCurrent);
	
	// start a query for the active servers in the group
	new bool:isReady = CheckSQLConnection();
	if (isReady)
	{
		decl String:query[512];
		CreateServerListQuery(query, sizeof(query), serverId, showOffline, showCurrent);
		SQL_TQuery(g_hDatabase, Query_ActiveServers, query, client);
	}
	else
	{
		PrintToChat(client, "%T", "redir failed no database", client, CHAT_COLOR);
	}
}

CreateServerListQuery(String:query[], maxlength, serverId, bool:showOffline, bool:showCurrent)
{
	Format(query, maxlength, "SELECT id, address, display_name, offline_name, maxplayers, currplayers, map, (NOW() - last_update) AS timediff FROM `server` WHERE groupnumber IN (SELECT groupnumber FROM `server` WHERE `id` = %d)", serverId);
	
	if (!showOffline)
	{
		Format(query, maxlength, "%s AND last_update >= DATE_SUB(NOW(), INTERVAL %d SECOND)", query, SERVER_TIMEOUT_SECONDS);
	}
	if (!showCurrent)
	{
		Format(query, maxlength, "%s AND `id` != %d", query, serverId);
	}
	
	new sortMode = GetConVarInt(g_varMenuSortMode);
	
	if (sortMode == 2)
	{
		Format(query, maxlength, "%s ORDER BY `id`", query);
	}
	else
	{
		Format(query, maxlength, "%s ORDER BY display_name", query);
	}
}

public Query_ActiveServers(Handle:db, Handle:query, const String:error[], any:client)
{
	/* Make sure the client didn't disconnect while the thread was running */
	if (!IsClientConnected(client))
	{
		return;
	}
 
	if (query == INVALID_HANDLE)
	{
		LogError("Active server query failed, error: %s", error);
		PrintToChat(client, "%T", "redir failed query error", client, CHAT_COLOR);
		DisconnectFromDatabase();
	}
	else
	{
		// get convars
		new bool:showOffline = GetConVarBool(g_varShowOffline);

		// construct voting menu
		new itemCount = 0;
		new Handle:hRedirMenu = CreateMenu(RedirMenuHandler);
		SetMenuTitle(hRedirMenu, "%T", "redir menu title", client);
		SetMenuExitButton(hRedirMenu, true);
		
		decl String:address[50];
		decl String:display_name[255];
		decl String:offline_name[100];
		decl String:map[64];
		new id;
		new maxPlayers;
		new currPlayers;
		new timeDiff;
		new draw;
		
		while (SQL_FetchRow(query))
		{
			draw = ITEMDRAW_DEFAULT;
			id = SQL_FetchInt(query, 0);
			SQL_FetchString(query, 1, address, sizeof(address));
			SQL_FetchString(query, 2, display_name, sizeof(display_name));
			SQL_FetchString(query, 3, offline_name, sizeof(offline_name));
			maxPlayers = SQL_FetchInt(query, 4);
			currPlayers = SQL_FetchInt(query, 5);
			SQL_FetchString(query, 6, map, sizeof(map));
			timeDiff = SQL_FetchInt(query, 7);
			
			if (showOffline && timeDiff > SERVER_TIMEOUT_SECONDS)
			{
				strcopy(display_name, sizeof(display_name), offline_name);
				strcopy(address, sizeof(address), ADDRESS_OFFLINE);
				if (GetConVarInt(g_varDisableOffline))
					draw = ITEMDRAW_DISABLED;
			}
			
			// format nicely
			FormatServerName(display_name, sizeof(display_name), map, currPlayers, maxPlayers);
			
			if (GetConVarInt(g_varDisableCurrent) && id == GetConVarInt(g_varServerId))
				draw = ITEMDRAW_DISABLED;

			AddMenuItem(hRedirMenu, address, display_name, draw);
			itemCount++;
		}
		
		if (itemCount > 0)
		{
			DisplayMenu(hRedirMenu, client, 30);
		}
		else
		{
			CloseHandle(hRedirMenu);
			PrintToChat(client, "%T", "redir no servers", client, CHAT_COLOR);
		}
	}
}

FormatServerName(String:buffer[], bufferSize, const String:map[], currPlayers, maxPlayers)
{
	decl String:tmpVal[10];

	if (StrContains(buffer, "{MAP}") != -1)
	{
		ReplaceString(buffer, bufferSize, "{MAP}", map);
	}
	if (StrContains(buffer, "{CURR}") != -1)
	{
		IntToString(currPlayers, tmpVal, sizeof(tmpVal));
		ReplaceString(buffer, bufferSize, "{CURR}", tmpVal);
	}
	if (StrContains(buffer, "{MAX}") != -1)
	{
		IntToString(maxPlayers, tmpVal, sizeof(tmpVal));
		ReplaceString(buffer, bufferSize, "{MAX}", tmpVal);
	}
}

public RedirMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	
	{
		// obtain selected address
		new String:selectedItem[64];
		GetMenuItem(menu, param2, selectedItem, sizeof(selectedItem));
		
		if (strcmp(selectedItem, ADDRESS_OFFLINE, false) == 0)
		{
			PrintToChat(param1, "%T", "server offline", param1, CHAT_COLOR);
			return;
		}
		
		// message in the top of the screen
		new Handle:msgValues = CreateKeyValues("msg");
		KvSetString(msgValues, "title", "Join another server");
		KvSetNum(msgValues, "level", 1); 
		KvSetString(msgValues, "time", "20"); 
		CreateDialog(param1, msgValues, DialogType_Msg);
		CloseHandle(msgValues);
		
		// redirect box
		new Handle:dialogValues = CreateKeyValues("msg");
		KvSetString(dialogValues, "title", selectedItem); 
		KvSetString(dialogValues, "time", "20"); 
		CreateDialog(param1, dialogValues, DialogType_AskConnect);
		CloseHandle(dialogValues);
	}
	else if (action == MenuAction_End)
	{
		CloseHandle(menu);
	}
}

// used to update the status of the server to the database
UpdateStatus()
{
	new bool:isEnabled = GetConVarBool(g_varHeartbeatEnabled);
	if (!isEnabled)
	{
		return 0;
	}
	
	if (g_playerCountChanged)
	{
		g_playerCountChanged = false;
		CountFakePlayers();
	}
	
	// obtain vars
	new maxVisiblePlayers = GetConVarInt(g_varSvMaxVisiblePlayers);
	if (maxVisiblePlayers < 0)
	{
		maxVisiblePlayers = GetMaxClients();
	}
	new maxPlayers = maxVisiblePlayers - g_fakeClientCount;
	new currPlayers = GetClientCount(false) - g_fakeClientCount;
	//PrintToServer("maxvis:%d   fake:%d   maxpl:%d   currpl:%d   igcount:%d", maxVisiblePlayers, g_fakeClientCount, maxPlayers, currPlayers, currPlayers + g_fakeClientCount);
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	new serverId = GetConVarInt(g_varServerId);
	
	new bool:isReady = CheckSQLConnection();
	if (isReady)
	{
		if (g_hQueryUpdate == INVALID_HANDLE)
		{
			new String:error[255];
			g_hQueryUpdate = SQL_PrepareQuery(g_hDatabase, "UPDATE server SET maxplayers = ?, currplayers = ?, map = ?, last_update = now() WHERE id = ?", error, sizeof(error));
			if (g_hQueryUpdate == INVALID_HANDLE)
			{
				LogMessage("Failed to prepare status update query, error: %s", error);
				DisconnectFromDatabase();
				return 0;
			}
		}
		
		SQL_BindParamInt(g_hQueryUpdate, 0, maxPlayers);
		SQL_BindParamInt(g_hQueryUpdate, 1, currPlayers);
		SQL_BindParamString(g_hQueryUpdate, 2, map, false);
		SQL_BindParamInt(g_hQueryUpdate, 3, serverId);
		
		SQL_LockDatabase(g_hDatabase);
		new bool:success = SQL_Execute(g_hQueryUpdate);
		SQL_UnlockDatabase(g_hDatabase);
		if (!success)
		{
			LogMessage("Failed to execute status update query");
			DisconnectFromDatabase();
			return 0;
		}
	}
	return 0;
}

// Checks the SQL connection and returns whether it's available for usage. If not, an attempt will be made
// to create the connection.
bool:CheckSQLConnection()
{
	// connect to the database if needed
	decl String:error[255];
	if (g_hDatabase == INVALID_HANDLE)
	{
		g_hDatabase = SQL_Connect(DATABASE_KEY, true, error, sizeof(error));
		if (g_hDatabase != INVALID_HANDLE)
		{
			return true;
		}
		LogMessage("Failed to connect to database, error: %s", error);
		return false;
	}
	else
	{
		return true;
	}
}

DisconnectFromDatabase()
{
	if (g_hDatabase != INVALID_HANDLE)
	{
		CloseHandle(g_hDatabase);
		g_hDatabase = INVALID_HANDLE;
	}
	
	if (g_hQueryUpdate != INVALID_HANDLE)
	{
		CloseHandle(g_hQueryUpdate);
		g_hQueryUpdate = INVALID_HANDLE;
	}
}

// Native function for showing the redirect window
public Native_ShowServerRedirectMenu(Handle:plugin, numParams)
{
   new client = GetNativeCell(1);
   ShowServerMenu(client);
}

public Native_RedirectList(Handle:plugin, numParams)
{
	new bool:showCurrent = GetConVarBool(g_varShowCurrent);
	new bool:showOffline = GetConVarBool(g_varShowOffline);
	new OnRedirectServersLoaded:callback = OnRedirectServersLoaded:GetNativeCell(1);
	new any:userData = any:GetNativeCell(2);
	Internal_RedirectList(plugin, showCurrent, showOffline, callback, userData);
}

public Native_RedirectListFiltered(Handle:plugin, numParams)
{
	new bool:showCurrent = bool:GetNativeCell(1);
	new bool:showOffline = bool:GetNativeCell(2);
	new OnRedirectServersLoaded:callback = OnRedirectServersLoaded:GetNativeCell(3);
	new any:userData = any:GetNativeCell(4);
	Internal_RedirectList(plugin, showCurrent, showOffline, callback, userData);
}

Internal_RedirectList(Handle:plugin, bool:showCurrent, bool:showOffline, OnRedirectServersLoaded:callback, any:userData)
{	
	new serverId = GetConVarInt(g_varServerId);

	// execute async query for the server list
	new bool:isReady = CheckSQLConnection();
	if (isReady)
	{
		decl String:query[512];
		CreateServerListQuery(query, sizeof(query), serverId, showOffline, showCurrent);
		
		// store plugin handle and callback function in a datapack
		new Handle:data = CreateDataPack();
		WritePackCell(data, _:callback);
		WritePackCell(data, _:plugin);
		WritePackCell(data, _:userData);
		
		SQL_TQuery(g_hDatabase, LoadServerRedirectList_Query, query, data);
	}
	else
	{
		Call_StartFunction(plugin, callback);
		Call_PushCell(-1);
		Call_PushString("Database connection unavailable");
		Call_PushCell(Handle:INVALID_HANDLE);
		Call_PushCell(userData);
		new result;
		Call_Finish(result);
	}
}

public LoadServerRedirectList_Query(Handle:db, Handle:query, const String:error[], any:data)
{
	// read vars from the data
	ResetPack(data);
	new OnRedirectServersLoaded:callback = OnRedirectServersLoaded:ReadPackCell(data);
	new Handle:plugin = Handle:ReadPackCell(data);
	new any:userData = any:ReadPackCell(data);
	CloseHandle(data);
	
	
	if (query == INVALID_HANDLE)
	{
		LogError("(LoadServerRedirectList_Query) Active server query failed, error: %s", error);
		DisconnectFromDatabase();
		
		Call_StartFunction(plugin, callback);
		Call_PushCell(-1);
		Call_PushString("Failed to query server list from the database. Check the log for errors");
		Call_PushCell(Handle:INVALID_HANDLE);
		Call_PushCell(userData);
		new result;
		Call_Finish(result);
	}
	else
	{
		// create keyvalues structure containing the servers
		new Handle:list = CreateKeyValues("servers");
		
		decl String:address[50];
		decl String:display_name[255];
		decl String:offline_name[255];
		decl String:map[64];
		new maxPlayers;
		new currPlayers;
		new timeDiff;
		new bool:isOnline;
		new serverCount = 0;

		while (SQL_FetchRow(query))
		{
			SQL_FetchString(query, 0, address, sizeof(address));
			SQL_FetchString(query, 1, display_name, sizeof(display_name));
			SQL_FetchString(query, 2, offline_name, sizeof(offline_name));
			maxPlayers = SQL_FetchInt(query, 3);
			currPlayers = SQL_FetchInt(query, 4);
			SQL_FetchString(query, 5, map, sizeof(map));
			timeDiff = SQL_FetchInt(query, 6);
			
			if (timeDiff > SERVER_TIMEOUT_SECONDS)
			{
				isOnline = false;
			}
			else
			{
				isOnline = true;
			}
			
			// format names
			FormatServerName(display_name, sizeof(display_name), map, currPlayers, maxPlayers);
			FormatServerName(offline_name, sizeof(offline_name), map, currPlayers, maxPlayers);

			
			KvJumpToKey(list, address, true);
			KvSetSectionName(list, address);
			KvSetString(list, "display_name", display_name);
			KvSetString(list, "offline_name", offline_name);
			KvSetNum(list, "maxplayers", maxPlayers);
			KvSetNum(list, "currentplayers", currPlayers);
			KvSetNum(list, "update_sec", timeDiff);
			KvSetString(list, "map", map);
			KvSetNum(list, "isonline", isOnline);
			KvRewind(list);
			
			serverCount++;
		}
		
		Call_StartFunction(plugin, callback);
		Call_PushCell(serverCount);
		Call_PushString("");
		Call_PushCell(list);
		Call_PushCell(userData);
		new result;
		Call_Finish(result);
	}
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
   CreateNative("ShowServerRedirectMenu", Native_ShowServerRedirectMenu);
   CreateNative("LoadServerRedirectList", Native_RedirectList);
   CreateNative("LoadServerRedirectListFiltered", Native_RedirectListFiltered);
   return APLRes_Success;
}
