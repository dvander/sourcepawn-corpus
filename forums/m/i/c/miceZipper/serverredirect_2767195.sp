/*
Versions:
  1.2.6
	+ Added Config File
  1.2.5
    + Added ConVar values to sm_redirect_menusort to sort by number of players (ascending 3, descending 4)
    ! Fixed display being shown if client disconnects and another takes their slot
    ! Fixed sm_redirect_allowbots ConVar not correctly addressing bots.
  1.2.4
    + Increased number of possible servers from 20 to 128.
  1.2.3
    ! Attempting compatibility with CS:GO
  1.2.2
    + Added convar sm_redirect_allowbots to count/ignore bots in the player count.
  1.2.1
    ! Uses RegAdminCmd instead of RegConsoleCmd.
    ! Returned Plugin_Handled] when necessary to stop "Unknown command" logs in client console.
    ? Changed DATABASE_KEY back to "serverredirect"
    ? Edited a few strings (and default chat color).
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

#define PLUGIN_VERSION "1.2.6a"

#define MAX_SERVERS 128

//Amount of seconds after which a server is considered to be offline.
#define SERVER_TIMEOUT_SECONDS 90
//Interval at which the database is updated
#define SERVER_UPDATE_INTERVAL 30.0

#define ADDRESS_OFFLINE "#OFFLINE#"
// #define DATABASE_KEY "serverredirect" - deprecated
#define CHAT_COLOR 0x03

new Handle:g_varServerId;             // ID of the server
new Handle:g_varShowCurrent;          // Whether to show the current server in the redirect menu
new Handle:g_varShowOffline;          // Whether to show offline servers in the redirect menu
new Handle:g_varAllowBots;            //Count bots in the list
new Handle:g_varSvMaxVisiblePlayers;  // sv_visiblemaxplayers var
new Handle:g_varMenuSortMode;         // Sort mode in the menu (1 = by name, 2 = by ID)
new Handle:g_varHeartbeatEnabled;      // Whether the heartbeat function is enabled
new Handle:g_varDatabaseKey;
new Handle:g_varTableKey;

new Handle:g_updateTimer = INVALID_HANDLE;  // update timer handler
new bool:g_busy[MAXPLAYERS+1];

new g_cache_age;
new g_server_count;
new String:g_address_cache[MAX_SERVERS][50];
new String:g_server_cache[MAX_SERVERS][255];

#assert sizeof(g_address_cache) == sizeof(g_server_cache)

new bool:g_bIsCSGO = false;
new bool:g_bRedirecting[MAXPLAYERS+1] = false;
new Handle:g_hResetTimer[MAXPLAYERS+1] = INVALID_HANDLE;

public Plugin:myinfo = 
{
  name = "Server Redirect Modded",
  author = "Bottiger, Brainstorm, 11530, Lacrimosa99, Prince Phobos aka miceZipper",
  description = "Allows players to switch to a different server. Modded to be completely threaded.",
  version = PLUGIN_VERSION,
  url = "http://www.teamfortress.be"
}

public OnPluginStart()
{
  CreateConVar("sm_redirect_version", PLUGIN_VERSION, "Version number of server redirect plugin.", FCVAR_SPONLY|FCVAR_NOTIFY);
  g_varServerId = CreateConVar("sm_redirect_serverid", "0", "sm_redirect_serverid - ID of the server in the database.", FCVAR_NONE, true, 0.0, false);
  g_varShowCurrent = CreateConVar("sm_redirect_showcurrent", "1", "sm_redirect_showcurrent - Whether to show the current server in the redirect menu");
  g_varShowOffline = CreateConVar("sm_redirect_showoffline", "1", "sm_redirect_showoffline - Whether to show offline servers in the redirect menu");
  g_varAllowBots = CreateConVar("sm_redirect_allowbots", "0", "sm_redirect_allowbots - Whether to count bots in the list");
  g_varMenuSortMode = CreateConVar("sm_redirect_menusort", "1", "sm_redirect_menusort - Indicates how menu items get sorted. 1 = by display name (default), 2 = server ID, 3 = number of players (ascending), 4 = number of players (descending)");  
  g_varHeartbeatEnabled = CreateConVar("sm_redirect_enableheartbeat", "1", "sm_redirect_enableheartbeat - Whether to enable heartbeat signal for this server. If stopped, the server will be marked as offline.");
  g_varDatabaseKey = CreateConVar("sm_redirect_databasekey","default","sm_redirect_databasekey - database name [default]");
  g_varTableKey = CreateConVar("sm_redirect_tablekey","serverredirect","sm_redirect_tablekey - table name [serverredirect]");

  g_varSvMaxVisiblePlayers = FindConVar("sv_visiblemaxplayers");
  if (g_varSvMaxVisiblePlayers == INVALID_HANDLE)
  {
    SetFailState("Unable to find required ConVar sv_visiblemaxplayers");
  }

  RegAdminCmd("sm_server", Command_Redirect, 0, "Show available game servers");
  RegAdminCmd("sm_servers", Command_Redirect, 0, "Show available game servers");
  RegAdminCmd("sm_swapme", Command_Redirect, 0, "Show available game servers");

  AutoExecConfig(true, "plugin.serverredirect");
  
  new String:szMod[64];
  GetGameFolderName(szMod, sizeof(szMod));
  if (StrEqual(szMod, "csgo", false))
  {
    g_bIsCSGO = true;
  }
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
  if (GetConVarBool(g_varHeartbeatEnabled))
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
  g_bRedirecting[client] = false;
  if (g_hResetTimer[client] != INVALID_HANDLE)
  {
    CloseHandle(g_hResetTimer[client]);
    g_hResetTimer[client] = INVALID_HANDLE;
  }
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
    return Plugin_Handled;
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
    return Plugin_Handled;
  }
  if(g_busy[client]) {
    PrintToChat(client, "%c[REDIRECT] Waiting for your last request.", CHAT_COLOR);
    return Plugin_Handled;
  }
  g_busy[client] = true;
  PrintToChat(client, "%c[REDIRECT] Fetching servers. May take a few seconds.", CHAT_COLOR);
  new String:temp[32];
  GetConVarString(g_varDatabaseKey,temp,32);
  SQL_TConnect(ShowServerMenu2, temp, GetClientUserId(client));
  return Plugin_Handled;
}

public ShowServerMenu2(Handle:owner, Handle:db, const String:error[], any:userid) {
  new client = GetClientOfUserId(userid);
  
  if (client == 0 || !IsClientInGame(client) || IsFakeClient(client)) {
    if(db != INVALID_HANDLE)
      CloseHandle(db);
    g_busy[client] = false;
    return;
  }

  if(db == INVALID_HANDLE) {
    g_busy[client] = false;
    LogMessage("Database error: %s", error);
    PrintToChat(client, "%c[REDIRECT] Unable to determine available servers.", CHAT_COLOR);
  } else {
    decl String:query[512];
    CreateServerListQuery(query, sizeof(query), GetConVarInt(g_varServerId), 
    GetConVarBool(g_varShowOffline), GetConVarBool(g_varShowCurrent));
    
    new Handle:hPack = CreateDataPack();
    WritePackCell(hPack, userid);
    WritePackCell(hPack, _:db);
    SQL_TQuery(db, Query_ActiveServers, query, hPack);
  }
}


CreateServerListQuery(String:query[], maxlength, serverId, bool:showOffline, bool:showCurrent)
{
  new String:temp[32];
  GetConVarString(g_varTableKey,temp,32);
  Format(query, maxlength, "SELECT address, display_name, offline_name, maxplayers, currplayers, map, (NOW() - last_update) AS timediff FROM `%s` WHERE groupnumber IN (SELECT groupnumber FROM `%s` WHERE `id` = %d)", temp, temp, serverId);
  
  if (!showOffline)
  {
    Format(query, maxlength, "%s AND last_update >= DATE_SUB(NOW(), INTERVAL %d SECOND)", query, SERVER_TIMEOUT_SECONDS);
  }
  if (!showCurrent)
  {
    Format(query, maxlength, "%s AND `id` != %d", query, serverId);
  }
  
  new sortMode = GetConVarInt(g_varMenuSortMode);
  
  switch (sortMode)
  {
    case 2:   Format(query, maxlength, "%s ORDER BY id", query);
    case 3:   Format(query, maxlength, "%s ORDER BY currplayers", query);
    case 4:   Format(query, maxlength, "%s ORDER BY currplayers DESC", query);
    default:  Format(query, maxlength, "%s ORDER BY display_name", query);
  }
}

public Query_ActiveServers(Handle:this_is_not_db, Handle:query, const String:error[], any:hPack)
{
  ResetPack(hPack);
  new client  = GetClientOfUserId(ReadPackCell(hPack));
  new Handle:db = Handle:ReadPackCell(hPack);
  CloseHandle(hPack);
  /* Make sure the client didn't disconnect while the thread was running */
  if (client == 0 || !IsClientInGame(client))
  {
    if(db != INVALID_HANDLE)
      CloseHandle(db);
    g_busy[client] = false;
    return;
  }
 
  if (query == INVALID_HANDLE)
  {
    LogError("Active server query failed, error: %s", error);
    PrintToChat(client, "%c[REDIRECT] Unable to query for available servers.", CHAT_COLOR);
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
    
    while (SQL_FetchRow(query) && itemCount < sizeof(g_address_cache[]))
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
      strcopy(g_address_cache[itemCount], sizeof(g_address_cache[]), address);
      strcopy(g_server_cache[itemCount], sizeof(g_server_cache[]), display_name);
      
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
    
    // redirect box
    if (g_bIsCSGO)
    {
      PrintHintText(param1, "The server is offering to connect you to:\n%s\nPress %s to accept.", selectedItem, "%reload%");        
      if (g_hResetTimer[param1] != INVALID_HANDLE)
      {
        CloseHandle(g_hResetTimer[param1]);
        g_hResetTimer[param1] = INVALID_HANDLE;
      }
      CreateTimer(10.0, RedirectTimer, GetClientUserId(param1));
      g_bRedirecting[param1] = true;
    }
    else
    {
      // message in the top of the screen
      new Handle:msgValues = CreateKeyValues("msg");
      KvSetString(msgValues, "title", "Join another server");
      KvSetNum(msgValues, "level", 1); 
      KvSetString(msgValues, "time", "20"); 
      CreateDialog(param1, msgValues, DialogType_Msg);
      CloseHandle(msgValues);
    
      new Handle:dialogValues = CreateKeyValues("msg");
      KvSetString(dialogValues, "title", selectedItem); 
      KvSetString(dialogValues, "time", "20"); 
      CreateDialog(param1, dialogValues, DialogType_AskConnect);
      CloseHandle(dialogValues);
    }
  }
  else if (action == MenuAction_End)
  {
    CloseHandle(menu);
  }
}

//Detect CS:GO players pressing Accept.
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
  if (g_bRedirecting[client] && (buttons & IN_RELOAD))
  {
    FakeClientCommandEx(client, "askconnect_accept");
    g_bRedirecting[client] = false;
  }
  return Plugin_Continue;
}

public Action:RedirectTimer(Handle:timer, any:userid)
{
  new client;
  if ((client = GetClientOfUserId(userid)) > 0)
  {
    g_bRedirecting[client] = false;
    g_hResetTimer[client] = INVALID_HANDLE;
  }
}

// used to update the status of the server to the database
UpdateStatus() {
  if (!GetConVarBool(g_varHeartbeatEnabled))
    return;
  new String:temp[32];
  GetConVarString(g_varDatabaseKey,temp,32);
  SQL_TConnect(UpdateStatus2, temp);
  return;
}

public UpdateStatus2(Handle:owner, Handle:db, const String:error[], any:data) {
  if(db == INVALID_HANDLE) {
    LogMessage("Database error: %s", error);
    return;
  }
  
  new maxPlayers  = GetConVarInt(g_varSvMaxVisiblePlayers);
  if (maxPlayers < 0)
  {
    maxPlayers = MaxClients;
  }
  
  new currPlayers = (GetConVarBool(g_varAllowBots) ? GetClientCount(false) : GetRealClientCount(false));
  
  decl String:map[64];
  GetCurrentMap(map, sizeof(map));
  new serverId = GetConVarInt(g_varServerId);
  
  decl String:query[255];
  new String:temp[32];
  GetConVarString(g_varTableKey,temp,32);
  Format(query, sizeof(query), "UPDATE %s SET maxplayers=%i, currplayers=%i, map='%s', last_update=now() WHERE id = %i", temp, 
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

GetRealClientCount(bool:inGameOnly = true)
{
  new clients = 0;
  for (new i = 1; i <= MaxClients; i++) {
    if (((inGameOnly) ? IsClientInGame(i) : IsClientConnected(i)) && !IsFakeClient(i) && !IsClientSourceTV(i) && !IsClientReplay(i)) {
      clients++;
    }
  }
  return clients;
}