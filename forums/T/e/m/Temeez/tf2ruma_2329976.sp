#include <sourcemod>
#include <SteamWorks>

#define PLUGIN_VERSION "1.1.3"

enum LogLevel {
    Log_Error = 0,
    Log_Info,
    Log_Debug
}

public Plugin:myinfo = {
    name        = "Remove Unnecessarily Most Antagonists",
    author      = "Temeez",
    description = "Don't allow players to the server if they have too low playtime in the game.",
    version     = PLUGIN_VERSION,
    url         = "https://temeez.me/"
}

new Handle:db
static String:log_path[PLATFORM_MAX_PATH]
static String:whitelist_path[PLATFORM_MAX_PATH]

static String:ruma_steamApiKey[64]
static String:ruma_kickmsg[256]
static int ruma_time
static int ruma_strict
static bool:ruma_steamapikeyset

new Handle:sm_ruma_steamApiKey = INVALID_HANDLE
new Handle:sm_ruma_time = INVALID_HANDLE
new Handle:sm_ruma_strict_mode = INVALID_HANDLE
new Handle:sm_ruma_kickmsg = INVALID_HANDLE
new Handle:sm_ruma_log_level
new Handle:sm_ruma_kick_msg_text = INVALID_HANDLE

new Handle:whitelist_cache = INVALID_HANDLE

/*
    R.U.M.A = Remove Unnecessarily Most Antagonists
*/
public OnPluginStart()
{
    CreateConVar("tf2ruma_version", PLUGIN_VERSION, "Remove Unnecessarily Most Antagonists plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
    sm_ruma_steamApiKey = CreateConVar("sm_steam_api_key", "insertKey", "Get your Steam Api key from http://steamcommunity.com/dev/apikey", _, false)
    sm_ruma_time = CreateConVar("sm_ruma_hour_limit", "10", "The amount of hours required to join the server.", _, false)
    sm_ruma_strict_mode = CreateConVar("sm_ruma_strict_mode", "1", "Strict mode\n0 = Off only\n1 = Kick player if couldn't get playtime on some cases\n2 = Kick player if couldn't get the playtime (private profile, Steam api down, etc)", _, true, 0.0, true, 2.0)
    sm_ruma_kickmsg = CreateConVar("sm_ruma_kickmsg", "1", "Displays the hour limit on the kick message.\n0 = Off\n1 = On", _, true, 0.0, true, 1.0)
    sm_ruma_log_level = CreateConVar("sm_ruma_log_level", "1", "Level of logging\n0 = Errors only\n1 = Info + errors\n2 = Info, errors, and debug", _, true, 0.0, true, 2.0)
    sm_ruma_kick_msg_text = CreateConVar("sm_ruma_kick_msg_text", "", "Custom reject message for the kicked player, max length of this message is 256!", _, false)

    AutoExecConfig(true, "plugin.tf2ruma")

    whitelist_cache = CreateTrie()

    // Admin command
    RegAdminCmd("sm_ruma_addplayer", Command_AddPlayer, ADMFLAG_RCON, "Add player to the DB so he or she can play even with 0 hours of playtime.")
    RegAdminCmd("sm_ruma_reloadwc", Command_ReloadWhitelistCache, ADMFLAG_RCON, "Reload the whitelist cache after editing the whitelist file.")

    InitFiles()
    LoadWhitelist()

    // Print to the default log file and on our own
    LogMessage("Remove Unnecessarily Most Antagonists plugin loaded, version %s", PLUGIN_VERSION)
    LogItem(Log_Info, "Remove Unnecessarily Most Antagonists plugin loaded, version %s", PLUGIN_VERSION)

    InitDatabase()
}

/*
    Get the values from the config file
*/
public OnConfigsExecuted()
{
    // Get ConVars from the config file
    GetConVarString(sm_ruma_steamApiKey, ruma_steamApiKey, sizeof(ruma_steamApiKey))
    ruma_time = GetConVarInt(sm_ruma_time)
    ruma_strict = GetConVarInt(sm_ruma_strict_mode)

    LogItem(Log_Debug, "Strict mode set to: %i", ruma_strict)

    GetConVarString(sm_ruma_kick_msg_text, ruma_kickmsg, sizeof(ruma_kickmsg))

    // Format the kick messages for later use
    if (StrEqual(ruma_kickmsg, "")) {
        if (GetConVarInt(sm_ruma_kickmsg) && ruma_strict < 2) {
            Format(ruma_kickmsg, sizeof(ruma_kickmsg), "You haven't accumulated enough playtime to access this server. %i hours required.", ruma_time)
        } else if (ruma_strict == 2) {
            Format(ruma_kickmsg, sizeof(ruma_kickmsg), "You probably haven't accumulated enough playtime to access this server. Profile private?", ruma_time)
        } else {
            Format(ruma_kickmsg, sizeof(ruma_kickmsg), "You haven't accumulated enough playtime to access this server")
        }
    }

    // Check if the Steam API key has been changed from the default
    if (StrEqual(ruma_steamApiKey, "insertKey") || StrEqual(ruma_steamApiKey, "")) {
        LogItem(Log_Error, "Steam API key is missing, please check your config file at /cfg/sourcemod/plugin.ruma.cfg")
        ruma_steamapikeyset = false
    } else {
        ruma_steamapikeyset = true
    }
}

/*
    Load whitelisted data into cache
*/
public LoadWhitelist()
{
    new Handle:file = OpenFile(whitelist_path, "rt")
    if (file == INVALID_HANDLE) {
        LogItem(Log_Error, "Cannot load the whitelist!")
        return
    }

    new String:linedata[20], length

    while (!IsEndOfFile(file) && ReadFileLine(file, linedata, sizeof(linedata)))
    {
        length = strlen(linedata)

        if (linedata[length - 1] == '\n') {
            linedata[--length] = '\0'
        }

        // Add steamid from the whitelist file to the cache
        SetTrieValue(whitelist_cache, linedata[0], 0)
    }

    LogItem(Log_Debug, "Whitelist cached")
    CloseHandle(file)
}

/*
    Check if the steam id is in the whitelist cache
*/
bool:IsWhitelisted(String:steamcid[]) {
    LogItem(Log_Debug, "Checking if %s is whitelisted", steamcid)
    decl dummy
    return GetTrieValue(whitelist_cache, steamcid, dummy)
}

/*
    Custom logging location
        /addons/sourcemod/logs/ruma_yearmonthday.log
*/
InitFiles()
{
    decl String:currentTime[64]
    // Get todays time for the log
    FormatTime(currentTime, sizeof(currentTime), "logs/ruma_%Y%m%d.log")
    // Set the new build path for the log
    BuildPath(Path_SM, log_path, sizeof(log_path), currentTime)
    // Log the new log file into the main log file
    LogAction(0, -1, "Log File: %s", log_path)

    // Create the whitelist file if it doesnt exist
    BuildPath(Path_SM, whitelist_path, sizeof(whitelist_path), "configs/tf2ruma_whitelist.txt")
    if (!FileExists(whitelist_path)) {
        new Handle:whitelist_file = OpenFile(whitelist_path,"w")
        CloseHandle(whitelist_file)
    }
}

/*
    Neat little method for logging, 5/5
        Inspiration from: https://forums.alliedmods.net/showthread.php?t=209791
*/
LogItem(LogLevel:level, const String:format[], any:...) {
    new logLevel = GetConVarInt(sm_ruma_log_level)

    // Log only if the desired log level is high enough
    if(logLevel < _:level) {
        return
    }

    decl String:buffer[512]
    new String:logPrefixes[][] = {"[ERROR]", "[INFO]", "[DEBUG]"}

    VFormat(buffer, sizeof(buffer), format, 3)
    LogToFileEx(log_path, "%s %s", logPrefixes[_:level], buffer)
}

/*
    Create the database file, if needed, to \tf2\tf\addons\sourcemod\data\sqlite
*/
InitDatabase()
{
    new String:error_buffer[255]
    // Creating the connection to DB
    // \tf2\tf\addons\sourcemod\configs\databases.cfg file contais "storage-local" by default
    // db = SQL_Connect("storage-local", true, error, sizeof(error))

    // Create a custom connection to the database
    // Database file is located in addons/sourcemod/data/tf2ruma
    new Handle:kv = CreateKeyValues("")
    KvSetString(kv, "driver", "sqlite")
    KvSetString(kv, "database", "tf2ruma")
    db = SQL_ConnectCustom(kv, error_buffer, sizeof(error_buffer), false)
    CloseHandle(kv)

    // Error checking and logging
    if (db == INVALID_HANDLE) {
        LogItem(Log_Error, "Could not connect to the database: %s", error_buffer)
        CloseHandle(db)
        return
    } else {
        LogItem(Log_Info, "Database connection established.")
    }

    // Lock the DB and create the table if it doesn't exist
    SQL_LockDatabase(db)
    SQL_FastQuery(db, "CREATE TABLE IF NOT EXISTS ruma_db (steamcid INTEGER PRIMARY KEY)")
    SQL_UnlockDatabase(db)
}

/*
    sm_ruma_addplayer command method
        arg1 = Steam Community id
*/
public Action:Command_AddPlayer(client, args)
{
    char arg1[18]
    GetCmdArg(1, arg1, sizeof(arg1))

    // Requires one argument and it needs to be the size of the steamID64, which is 32
    if (args == 1 && strlen(arg1)+1 == sizeof(arg1)) {
        // Check if the given steamid is already in the database
        if (IsPlayerInDB(arg1)) {
            ReplyToCommand(client, "[SM] %s is already in the RUMA database.", arg1)
            return Plugin_Handled
        }
        // Try to add the given steamid to the database
        if (AddPlayerToDB(arg1)) {
            ReplyToCommand(client, "[SM] Added %s to the RUMA database.", arg1)
        } else {
            ReplyToCommand(client, "[SM] Can't add the new player to the RUMA database. Please consult the log files.")
        }
    } else {
        ReplyToCommand(client, "Usage: 'sm_ruma_addplayer SteamID64'")
    }

    return Plugin_Handled
}

/*
    sm_ruma_reloadwc command method

    Reloads the whitelist cache by clearing it and loading it again.
    Whitelist cache loads automatically only when the server starts,
    or when this plugin is reloaded
*/
public Action:Command_ReloadWhitelistCache(client, args)
{
    ClearTrie(whitelist_cache)
    LoadWhitelist()

    ReplyToCommand(client, "[SM] Whitelist cache reloaded.")

    return Plugin_Handled
}

/*
    Send a http request to the steam api server for relative data
        steamId = Steam Community ID
*/
public bool:OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    if (IsClientConnected(client) && IsFakeClient(client)) {
        LogItem(Log_Debug, "Bot %L was ignored", client)
        return true
    }

    // Do nothing if the api key is not set
    if (!ruma_steamapikeyset) {
        LogItem(Log_Error, "Steam API key is not set!")
        PrintToServer("Steam API key is not set!")
        return true
    }

    // Get the 64bit steam id from the client
    decl String:steamcid[32]
    SteamWorks_GetClientSteamID(client, steamcid, sizeof(steamcid))
    // Steam_GetCSteamIDForClient(client, steamcid, sizeof(steamcid))
    LogItem(Log_Debug, "%s is connecting as %L", steamcid, client)

    return true
}

/*
    Mainly for debugging
*/
public OnClientConnected(int client)
{
    // Get the 64bit steam id from the client
    decl String:steamcid[32]
    SteamWorks_GetClientSteamID(client, steamcid, sizeof(steamcid))
    // Steam_GetCSteamIDForClient(client, steamcid, sizeof(steamcid))
    LogItem(Log_Debug, "%s has connected as %L", steamcid, client)
}

/*
    Handle all the things after player has authenticated
*/
public OnClientAuthorized(int client, const char[] auth)
{
    if (IsClientConnected(client) && IsFakeClient(client)) {
        LogItem(Log_Debug, "Bot %L was ignored", client)
        return
    }

    // Get the 64bit steam id from the client
    decl String:steamcid[32]
    SteamWorks_GetClientSteamID(client, steamcid, sizeof(steamcid))
    LogItem(Log_Debug, "%s authed as %L - %s", steamcid, client, auth)

    // Check if the player is already in the DB
    if (IsPlayerInDB(steamcid)) {
        return
    }

    // Check if the player is whitelisted
    if (IsWhitelisted(steamcid)) {
        LogItem(Log_Debug, "%s as %L is whitelisted", steamcid, client)
        return
    }

    SendHTTPRequest(steamcid, client)
}

/*
    Mainly for debugging
*/
public OnClientPutInServer(int client)
{
    // Get the 64bit steam id from the client
    decl String:steamcid[32]
    SteamWorks_GetClientSteamID(client, steamcid, sizeof(steamcid))
    // Steam_GetCSteamIDForClient(client, steamcid, sizeof(steamcid))
    LogItem(Log_Debug, "%s put in server as %L", steamcid, client)
}

/*
    HTTP request for checking the playtime
    https://forums.alliedmods.net/showthread.php?p=2386954
*/
public SendHTTPRequest(String:steamcid[32], int client) {
    // Request url
    char[] url = "http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001/?"
    // Handle
    Handle HTTPRequest = SteamWorks_CreateHTTPRequest(k_EHTTPMethodGET, url)
    // Set timeout to 10 seconds
    bool setnetwork = SteamWorks_SetHTTPRequestNetworkActivityTimeout(HTTPRequest, 10)
    // Set required parameters
    bool setparam = SteamWorks_SetHTTPRequestGetOrPostParameter(HTTPRequest, "format", "vdf")
    bool setsteamid = SteamWorks_SetHTTPRequestGetOrPostParameter(HTTPRequest, "steamid", steamcid)
    bool setkey = SteamWorks_SetHTTPRequestGetOrPostParameter(HTTPRequest, "key", ruma_steamApiKey)
    bool setparam1 = SteamWorks_SetHTTPRequestGetOrPostParameter(HTTPRequest, "include_played_free_games", "1")
    bool setparam2 = SteamWorks_SetHTTPRequestGetOrPostParameter(HTTPRequest, "appids_filter[0]", "440")
    // So we can get the client in the response method
    bool setcontext = SteamWorks_SetHTTPRequestContextValue(HTTPRequest, GetClientUserId(client))
    // Callback for response data
    bool setcallback = SteamWorks_SetHTTPCallbacks(HTTPRequest, GetHTTPRequest)

    if(!setnetwork || !setparam || !setsteamid || !setkey || !setparam1 || !setparam2 || !setcontext || !setcallback) {
        LogItem(Log_Error, "Error in setting request properties, cannot send request")
        CloseHandle(HTTPRequest)
        return
    }

    // Initialize the request.
    bool sentrequest = SteamWorks_SendHTTPRequest(HTTPRequest)
    if(!sentrequest) {
        LogItem(Log_Error, "Error in sending request, cannot send request")
        CloseHandle(HTTPRequest)
        return
    }

    // Send the request to the front of the queue
    SteamWorks_PrioritizeHTTPRequest(HTTPRequest)
}

/*
    Callback for the HTTP request
    https://forums.alliedmods.net/showthread.php?p=2386954
*/
public GetHTTPRequest(Handle:hRequest, bool:bFailure, bool:bRequestSuccessful, EHTTPStatusCode:eStatusCode, any:data1) {
    // Check if request was succesful
    if(!bRequestSuccessful) {
        LogItem(Log_Error, "There was an error in the request")
        CloseHandle(hRequest)
        return
    }

    // Get the client
    new client = GetClientOfUserId(data1)
    decl String:steamcid[32]
    SteamWorks_GetClientSteamID(client, steamcid, sizeof(steamcid))

    // Check response status codes
    if(eStatusCode == k_EHTTPStatusCode200OK) {

    } else if(eStatusCode == k_EHTTPStatusCode304NotModified) {
        CloseHandle(hRequest)
        return
    } else if(eStatusCode == k_EHTTPStatusCode404NotFound) {
        if (ruma_strict == 2) {
            KickClient(client, ruma_kickmsg)
            LogItem(Log_Info, "%s as %L was kicked because http request returned %s and strict mode is set to %i.", steamcid, client, eStatusCode, ruma_strict)
        }
        CloseHandle(hRequest)
        return
    } else if(eStatusCode == k_EHTTPStatusCode500InternalServerError) {
        if (ruma_strict == 2) {
            KickClient(client, ruma_kickmsg)
            LogItem(Log_Info, "%s as %L was kicked because http request returned %s and strict mode is set to %i.", steamcid, client, eStatusCode, ruma_strict)
        }
        CloseHandle(hRequest)
        return
    } else {
        if (ruma_strict == 2) {
            KickClient(client, ruma_kickmsg)
            LogItem(Log_Info, "%s as %L was kicked because http request returned %s and strict mode is set to %i.", steamcid, client, eStatusCode, ruma_strict)
        }
        char errmessage[128]
        Format(errmessage, 128, "The requested returned with an unexpected HTTP Code %d", eStatusCode)
        LogItem(Log_Error, errmessage)
        CloseHandle(hRequest)
        return
    }

    // Could not get body response size
    int bodysize
    bool bodyexists = SteamWorks_GetHTTPResponseBodySize(hRequest, bodysize)
    if(bodyexists == false) {
        if (ruma_strict == 1) {
            KickClient(client, ruma_kickmsg)
            LogItem(Log_Info, "%s as %L was kicked because couldnt get the body response size from the request (%s) and strict mode is set to %i.", steamcid, client, eStatusCode, ruma_strict)
        }
        CloseHandle(hRequest)
        return
    }

    // Get the buffer size from the http response
    int bodyBufferSize
    SteamWorks_GetHTTPResponseBodySize(hRequest, bodyBufferSize)
    // Creating a string buffer for the response
    decl String:bodyBuffer[bodyBufferSize]
    bool bodyData = SteamWorks_GetHTTPResponseBodyData(hRequest, bodyBuffer, bodyBufferSize)

    // Could not get body data or body data is blank
    if(bodyData == false) {
        if (ruma_strict == 1) {
            KickClient(client, ruma_kickmsg)
            LogItem(Log_Info, "%s as %L was kicked because couldnt get the body from the request (%s) and strict mode is set to %i.", steamcid, client, eStatusCode, ruma_strict)
        }
        CloseHandle(hRequest)
        return
    }

    CloseHandle(hRequest)

    int playerTotalPlaytime = GetGameTotalPlaytime(bodyBuffer, "440", 8)
    LogItem(Log_Debug, "%s as %L has %i hours of playtime", steamcid, client, playerTotalPlaytime)

    // Do nothing if player has 999999 as playtime
    // This usually mean that something went wrong
    // Reason for this can be anything from steam server to the client
    if (playerTotalPlaytime != 999999 && playerTotalPlaytime != -1) {
        // Kick the player if the total playtime is too low
        if (playerTotalPlaytime < ruma_time) {
            // Kick the client
            KickClient(client, ruma_kickmsg)
            LogItem(Log_Info, "%s as %L was kicked for having a playtime of %i. %i hours required.", steamcid, client, playerTotalPlaytime, ruma_time)
        } else {
            // Save player names to the DB
            AddPlayerToDB(steamcid)
        }
    } else if (playerTotalPlaytime == -1) {
      // Kick players with private profiles if strict mode is set to 2
      if (ruma_strict == 2) {
        KickClient(client, ruma_kickmsg)
        LogItem(Log_Info, "%s as %L was kicked for having the profile in private and because strict mode is set to %i.", steamcid, client, ruma_strict)
      }
    } else {
        if (ruma_strict == 1) {
            KickClient(client, ruma_kickmsg)
            LogItem(Log_Info, "%s as %L was kicked for having a playtime of %i hours and because strict mode is set to %i.", steamcid, client, playerTotalPlaytime, ruma_strict)
        }
    }
}

/*
    Get the total playtime in hours
*/
int GetGameTotalPlaytime(String:dataBuffer[], String:gameid[], maxlength)
{
    new Handle:kv = CreateKeyValues("response")
    StringToKeyValues(kv, dataBuffer, "dataBuffer")
    // This usually means that the response object is empty
    // Steam profile is set to private
    if (!KvGotoFirstSubKey(kv)) {
        //Steam_RequestStats(client)
        return -1
    }

    decl String:gameidBuffer[8]
    KvGotoNextKey(kv)                                   // games
    KvGotoFirstSubKey(kv, true)                         //   |--- 0
    KvGetString(kv, "appid", gameidBuffer, maxlength)   //        |--- 440

    // Check that the gameid is correct, in case of sorcery
    if (StrEqual(gameidBuffer, gameid)) {
        // Total playtime in minutes
        int totalMinutes = KvGetNum(kv, "playtime_forever", 0)
        // Return the playtime in hours
        return totalMinutes / 60
    }

    CloseHandle(kv)
    return 999999
}

/*
    Check if the player is already in the DB, using the steam community id
*/
bool:IsPlayerInDB(String:steamcid[])
{
    LogItem(Log_Debug, "Checking if %s is in the database", steamcid)
    // DB query buffer
    decl String:dbQuery[512]
    // Format the DB query
    Format(dbQuery, sizeof(dbQuery), "SELECT steamcid FROM ruma_db WHERE steamcid = '%s'", steamcid)
    // Lock, query and unlock the DB
    SQL_LockDatabase(db)
    new Handle:query = SQL_Query(db, dbQuery)
    SQL_UnlockDatabase(db)

    // Do the error dance
    if (query == INVALID_HANDLE) {
        new String:error[255]
        SQL_GetError(db, error, sizeof(error))
        LogItem(Log_Error, "IsPlayerInDB failed to query (error: %s)", error)
    } else {
        if (SQL_FetchRow(query)) {
            // Close the query handle
            CloseHandle(query)
            LogItem(Log_Debug, "%s was found in the database", steamcid)
            return true
        }
    }

    return false
}

/*
    Add the player steam community id into the DB
*/
bool:AddPlayerToDB(String:steamcid[])
{
    LogItem(Log_Debug, "Trying to add %s to the database", steamcid)
    // DB query buffer
    decl String:dbQuery[512]
    new bool:queryStatus
    // Formatting the DB query
    Format(dbQuery, sizeof(dbQuery), "INSERT INTO ruma_db VALUES ('%s')", steamcid)
    // A lock, query and unlock
    SQL_LockDatabase(db)
    queryStatus = SQL_FastQuery(db, dbQuery)
    SQL_UnlockDatabase(db)

    // Error checking, reporting and logging
    if (!queryStatus) {
        new String:error[255]
        SQL_GetError(db, error, sizeof(error))
        // Log message
        LogItem(Log_Error, "AddPlayerToDB failed to query (error: %s)", error)
        return false
    } else {
        LogItem(Log_Debug, "Added %s to the database", steamcid)
        return true
    }
}
