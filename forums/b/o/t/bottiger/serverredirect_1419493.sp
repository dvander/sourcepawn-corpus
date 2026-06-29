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
#pragma semicolon 1

#define PLUGIN_VERSION "1.2"
// amount of seconds after which a server is considered to be offline. Offline servers will not show up in the redirect window.
#define SERVER_TIMEOUT_SECONDS 90
// interval at which the database is updated
#define SERVER_UPDATE_INTERVAL 30.0

#define ADDRESS_OFFLINE "#OFFLINE#"
#define DATABASE_KEY "default"
#define CHAT_COLOR 0x04

new Handle:g_varServerId;                                // ID of the server
new Handle:g_varShowCurrent;                            // Whether to show the current server in the redirect menu
new Handle:g_varShowOffline;                            // Whether to show offline servers in the redirect menu
new Handle:g_varSvMaxVisiblePlayers;                    // sv_visiblemaxplayers var
new Handle:g_varMenuSortMode;                            // Sort mode in the menu (1 = by name, 2 = by ID)
new Handle:g_varHeartbeatEnabled;                        // Whether the heartbeat function is enabled

new Handle:g_updateTimer = INVALID_HANDLE;                // update timer handler
new bool:g_busy[MAXPLAYERS+1];

new g_cache_age;
new g_server_count;
new String:g_address_cache[20][50];
new String:g_server_cache[20][255];

public Plugin:myinfo = 
{
    name = "Server Redirect Modded",
    author = "Bottiger, Brainstorm",
    description = "Allows players to switch to a different server. Modded to be completely threaded.",
    version = PLUGIN_VERSION,
    url = "http://www.teamfortress.be"
}

public OnPluginStart()
{
    CreateConVar("sm_redirect_version", PLUGIN_VERSION, "Version number of server redirect plugin.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
    g_varServerId = CreateConVar("sm_redirect_serverid", "0", "sm_redirect_serverid - ID of the server in the database.", 0, true, 0.0, false);
    g_varShowCurrent = CreateConVar("sm_redirect_showcurrent", "1", "sm_redirect_showcurrent - Whether to show the current server in the redirect menu", 0, true, 0.0, true, 1.0);
    g_varShowOffline = CreateConVar("sm_redirect_showoffline", "1", "sm_redirect_showoffline - Whether to show offline servers in the redirect menu", 0, true, 0.0, true, 1.0);
    g_varMenuSortMode = CreateConVar("sm_redirect_menusort", "1", "sm_redirect_menusort - Indicates how menu items get sorted. 1 = by display name (default), 2 = by server ID", 0, true, 1.0, false);
    g_varSvMaxVisiblePlayers = FindConVar("sv_visiblemaxplayers");
    g_varHeartbeatEnabled = CreateConVar("sm_redirect_enableheartbeat", "1", "sm_redirect_enableheartbeat - Whether to enable heartbeat signal for this server. If stopped, the server will be marked as offline.", 0, true, 0.0, true, 1.0);
    if (g_varSvMaxVisiblePlayers == INVALID_HANDLE)
    {
        SetFailState("Unable to find sv_visiblemaxplayers, I need this var please.");
    }
    
    // register events
    RegConsoleCmd("server", Command_Redirect);
    RegConsoleCmd("servers", Command_Redirect);
    RegConsoleCmd("swapme", Command_Redirect);
}

public OnMapStart()
{
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

public OnClientConnected(client) {
    g_busy[client] = false;
    UpdateStatus();
}

public OnClientDisconnect_Post(client) {
    UpdateStatus();
}

StartStatusUpdateTimer() {
    EndStatusUpdateTimer();
    g_updateTimer = CreateTimer(SERVER_UPDATE_INTERVAL, Timer_StatusUpdate, INVALID_HANDLE, TIMER_REPEAT);
}

EndStatusUpdateTimer() {
    if (g_updateTimer != INVALID_HANDLE) {
        KillTimer(g_updateTimer);
        g_updateTimer = INVALID_HANDLE;
    }
}

public Action:Timer_StatusUpdate(Handle:timer)
{
    UpdateStatus();
}

public Action:Command_Redirect(client, args)
{
    if(client <= 0) {
        return;
    }
    
    if(GetTime() - g_cache_age <= 5) {
        // cached
        if(g_server_count == 0) {
            PrintToChat(client, "%c[REDIRECT] There are currently no servers available.", CHAT_COLOR);
        } else {
            new Handle:hRedirMenu = CreateMenu(RedirMenuHandler);
            SetMenuTitle(hRedirMenu, "Choose a server to join.", client);
            SetMenuExitButton(hRedirMenu, true);
            
            for(new i=0;i<g_server_count;i++) {
                AddMenuItem(hRedirMenu, g_address_cache[i], g_server_cache[i]);
            }
            DisplayMenu(hRedirMenu, client, 30);
        }
        return;
    }
    if(g_busy[client]) {
        PrintToChat(client, "%c[REDIRECT] Waiting for your last request.", CHAT_COLOR);
        return;
    }
    g_busy[client] = true;
    PrintToChat(client, "%c[REDIRECT] Fetching Servers. May take a few seconds.", CHAT_COLOR);
    SQL_TConnect(ShowServerMenu2, DATABASE_KEY, client);
    return;
}

public ShowServerMenu2(Handle:owner, Handle:db, const String:error[], any:client) {
    // TODO: Cancel this query if the client disconnected
    // Will display to the wrong person if someone reconnects in the same slot before the query finishes.
    if (!IsClientConnected(client) || IsFakeClient(client)) {
        if(db != INVALID_HANDLE)
            CloseHandle(db);
        g_busy[client] = false;
        return;
    }

    if(db == INVALID_HANDLE) {
        g_busy[client] = false;
        LogMessage("Database error: %s", error);
        PrintToChat(client, "%c[REDIRECT] Sorry, I was unable to determine which servers are currently available.", CHAT_COLOR);
    } else {
        decl String:query[512];
        CreateServerListQuery(query, sizeof(query), GetConVarInt(g_varServerId), 
                              GetConVarBool(g_varShowOffline), GetConVarBool(g_varShowCurrent));
        
        new Handle:client_and_db = CreateDataPack();
        WritePackCell(client_and_db, _:client);
        WritePackCell(client_and_db, _:db);
        ResetPack(client_and_db);
        SQL_TQuery(db, Query_ActiveServers, query, client_and_db);
    }
}


CreateServerListQuery(String:query[], maxlength, serverId, bool:showOffline, bool:showCurrent)
{
    Format(query, maxlength, "SELECT address, display_name, offline_name, maxplayers, currplayers, map, (NOW() - last_update) AS timediff FROM `server` WHERE groupnumber IN (SELECT groupnumber FROM `server` WHERE `id` = %d)", serverId);
    
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

public Query_ActiveServers(Handle:this_is_not_db, Handle:query, const String:error[], any:client_and_db)
{
    new client    = ReadPackCell(client_and_db);
    new Handle:db = Handle:ReadPackCell(client_and_db);
    CloseHandle(client_and_db);
    /* Make sure the client didn't disconnect while the thread was running */
    if (!IsClientConnected(client))
    {
        if(db != INVALID_HANDLE)
            CloseHandle(db);
        g_busy[client] = false;
        return;
    }
 
    if (query == INVALID_HANDLE)
    {
        LogError("Active server query failed, error: %s", error);
        PrintToChat(client, "%c[REDIRECT] Sorry, I was unable to query for the available servers.", CHAT_COLOR);
        g_busy[client] = false;
        CloseHandle(db);
        return;
    }
    else
    {
        // get convars
        new bool:showOffline = GetConVarBool(g_varShowOffline);

        // construct voting menu
        g_server_count = 0;
        new itemCount = 0;
        new Handle:hRedirMenu = CreateMenu(RedirMenuHandler);
        SetMenuTitle(hRedirMenu, "Choose a server to join.", client);
        SetMenuExitButton(hRedirMenu, true);
        
        decl String:address[50];
        decl String:display_name[255];
        decl String:offline_name[100];
        decl String:map[64];
        new maxPlayers;
        new currPlayers;
        new timeDiff;
        
        while (SQL_FetchRow(query))
        {
            SQL_FetchString(query, 0, address, sizeof(address));
            SQL_FetchString(query, 1, display_name, sizeof(display_name));
            SQL_FetchString(query, 2, offline_name, sizeof(offline_name));
            maxPlayers = SQL_FetchInt(query, 3);
            currPlayers = SQL_FetchInt(query, 4);
            SQL_FetchString(query, 5, map, sizeof(map));
            timeDiff = SQL_FetchInt(query, 6);
            
            if (showOffline && timeDiff > SERVER_TIMEOUT_SECONDS)
            {
                strcopy(display_name, sizeof(display_name), offline_name);
                strcopy(address, sizeof(address), ADDRESS_OFFLINE);
            }
            
            // format nicely
            FormatServerName(display_name, sizeof(display_name), map, currPlayers, maxPlayers);
            AddMenuItem(hRedirMenu, address, display_name);
            
            // add to cache
            strcopy(g_address_cache[itemCount], sizeof(address), address);
            strcopy(g_server_cache[itemCount], sizeof(display_name), display_name);
            
            itemCount++;
        }
        g_server_count = itemCount;
        g_cache_age = GetTime();
        
        if (itemCount > 0)
        {
            DisplayMenu(hRedirMenu, client, 30);
        }
        else
        {
            CloseHandle(hRedirMenu);
            PrintToChat(client, "%c[REDIRECT] There are currently no servers available.", CHAT_COLOR);
        }
        
        g_busy[client] = false;
        CloseHandle(query);
        CloseHandle(db);
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
            PrintToChat(param1,  "%c[REDIRECT] The selected server is currently offline.", CHAT_COLOR);
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
UpdateStatus() {
    if (!GetConVarBool(g_varHeartbeatEnabled))
        return;
    
    SQL_TConnect(UpdateStatus2, DATABASE_KEY);
    return;
}

public UpdateStatus2(Handle:owner, Handle:db, const String:error[], any:data) {
    if(db == INVALID_HANDLE) {
        LogMessage("Database error: %s", error);
        return;
    }
    
    new maxVisiblePlayers = GetConVarInt(g_varSvMaxVisiblePlayers);
    if (maxVisiblePlayers < 0) {
        maxVisiblePlayers = GetMaxClients();
    }
    new maxPlayers  = maxVisiblePlayers;
    new currPlayers = GetClientCount(false);
    
    decl String:map[64];
    GetCurrentMap(map, sizeof(map));
    new serverId = GetConVarInt(g_varServerId);
    
    decl String:query[255];
    Format(query, sizeof(query), "UPDATE server SET maxplayers=%i, currplayers=%i, map='%s', last_update=now() WHERE id = %i",
                                maxPlayers, currPlayers,  map, serverId);
    SQL_TQuery(db, UpdateStatus3, query, db);
}

public UpdateStatus3(Handle:this_is_not_the_db, Handle:query, const String:error[], any:realdb) {
    if(query == INVALID_HANDLE) {
        LogMessage("Failed to execute status update query: %s", error);
    } else {
        CloseHandle(query);
    }
    if(realdb != INVALID_HANDLE) {
        CloseHandle(realdb);
    }
}