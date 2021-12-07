#include <sourcemod>
#include <steamtools>

#define PLUGIN_VERSION "1.0.0"

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
    url         = "http://temeez.me/"
}

new Handle:db
new HTTPRequestHandle:g_HTTPRequest = INVALID_HTTP_HANDLE
new String:rumaLogFile[PLATFORM_MAX_PATH]

static String:ruma_steamApiKey[64]
static String:ruma_kickmsg[128]
static int ruma_time
static bool:ruma_steamapikeyset

new Handle:sm_ruma_steamApiKey = INVALID_HANDLE
new Handle:sm_ruma_time = INVALID_HANDLE
new Handle:sm_ruma_kickmsg = INVALID_HANDLE
new Handle:sm_ruma_log_level = INVALID_HANDLE

/*
    R.U.M.A = Remove Unnecessarily Most Antagonists
*/
public OnPluginStart()
{
    CreateConVar("tf2ruma_version", PLUGIN_VERSION, "Remove Unnecessarily Most Antagonists plugin version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD)
    sm_ruma_steamApiKey = CreateConVar("sm_steam_api_key", "insertKey", "Get your Steam Api key from http://steamcommunity.com/dev/apikey", _, false)
    sm_ruma_time = CreateConVar("sm_ruma_hour_limit", "10", "The amount of hours required to join the server.", _, false)
    sm_ruma_kickmsg = CreateConVar("sm_ruma_kickmsg", "1", "Displays the hour limit on the kick message.\n0 = Off\n1 = On", _, true, 0.0, true, 1.0)
    sm_ruma_log_level = CreateConVar("sm_ruma_log_level", "1", "Level of logging\n0 = Errors only\n1 = Info + errors\n2 = Info, errors, and debug", _, true, 0.0, true, 2.0);

    AutoExecConfig(true, "plugin.tf2ruma")

    // Admin command
    RegAdminCmd("sm_ruma_addplayer", Command_AddPlayer, ADMFLAG_RCON, "Add player to the DB so he or she can play even with 0 hours of playtime.")

    InitLogging()

    // Print to the default log file and on our own
    LogMessage("Remove Unnecessarily Most Antagonists plugin loaded, version %s", PLUGIN_VERSION)
    LogItem(Log_Info, "Remove Unnecessarily Most Antagonists plugin loaded, version %s", PLUGIN_VERSION);

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

    // Format the kick messages for later use
    if (GetConVarInt(sm_ruma_kickmsg)) {
        Format(ruma_kickmsg, sizeof(ruma_kickmsg), "You haven't accumulated enough playtime to access this server. %i hours required.", ruma_time)
    } else {
        Format(ruma_kickmsg, sizeof(ruma_kickmsg), "You haven't accumulated enough playtime to access this server")
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
    Custom logging location
        /addons/sourcemod/logs/ruma_yearmonthday.log
*/
InitLogging()
{
    decl String:currentTime[64]
    // Get todays time for the log
    FormatTime(currentTime, sizeof(currentTime), "logs/ruma_%Y%m%d.log")
    // Set the new build path for the log
    BuildPath(Path_SM, rumaLogFile, sizeof(rumaLogFile), currentTime)
    // Log the new log file into the main log file
    LogAction(0, -1, "Log File: %s", rumaLogFile)
}

/*
    Neat little method for logging, 5/5
        Inspiration from: https://forums.alliedmods.net/showthread.php?t=209791
*/
LogItem(LogLevel:level, const String:format[], any:...) {
    // Get the log level from the config file
    new logLevel = GetConVarInt(sm_ruma_log_level)

    // Log only if the desired log level is high enough
    if(logLevel < _:level) {
        return;
    }

    decl String:buffer[512]
    new String:logPrefixes[][] = {"[ERROR]", "[INFO]", "[DEBUG]"};
    VFormat(buffer, sizeof(buffer), format, 3);
    LogToFileEx(rumaLogFile, "%s %s", logPrefixes[_:level], buffer);
}


/*
    Create the database file, if needed, to \tf2\tf\addons\sourcemod\data\sqlite
*/
InitDatabase()
{
    new String:error[255]
    // Creating the connection to DB
    // \tf2\tf\addons\sourcemod\configs\databases.cfg file contais "storage-local" by default
    db = SQL_Connect("storage-local", true, error, sizeof(error))
    
    // Error checking and logging
    if (db == INVALID_HANDLE) {
        LogItem(Log_Error, "Could not connect to the database: %s", error)
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

    PrintToServer(arg1)

    // Requires one argument and it needs to be the size of the steamID64, which is 32
    if (args == 1 && strlen(arg1)+1 == sizeof(arg1)) {
        if (AddPlayerToDB(arg1)) {
            ReplyToCommand(client, "[SM] Added the new player to the RUMA database.")
        } else {
            ReplyToCommand(client, "[SM] Can't add the new player to the RUMA database. Please consult the log files.")
        }
    } else {
        ReplyToCommand(client, "Usage: 'sm_ruma_addplayer steamID64'")
    }

    return Plugin_Handled
}


/*
    Send a http request to the steam api server for relative data
        steamId = Steam Community ID
*/
public bool:OnClientConnect(int client, char[] rejectmsg, int maxlen)
{
    // Do nothing if the api key is not set
    // except allow the client to connect
    if (!ruma_steamapikeyset) return true

    // steamcid buffer
    decl String:steamcid[32]
    // Get the 64bit steam id from the client
    Steam_GetCSteamIDForClient(client, steamcid, sizeof(steamcid))

    // Check if the player is already in the DB
    if (AllowPlayerFromDB(steamcid)) {
        LogItem(Log_Debug, "Allowed player %L to join the server because they are in the databse as %s", client, steamcid)
        return true
    }

    // Http request
    g_HTTPRequest = Steam_CreateHTTPRequest(HTTPMethod_GET, "http://api.steampowered.com/IPlayerService/GetOwnedGames/v0001")
    Steam_SetHTTPRequestGetOrPostParameter(g_HTTPRequest, "format", "vdf")
    Steam_SetHTTPRequestGetOrPostParameter(g_HTTPRequest, "steamid", steamcid)
    Steam_SetHTTPRequestGetOrPostParameter(g_HTTPRequest, "key", ruma_steamApiKey)
    Steam_SetHTTPRequestGetOrPostParameter(g_HTTPRequest, "include_played_free_games", "1")
    Steam_SetHTTPRequestGetOrPostParameter(g_HTTPRequest, "appids_filter[0]", "440")
    Steam_SendHTTPRequest(g_HTTPRequest, OnDownloadComplete, GetClientUserId(client))

    return true
}


/*
    Happens after the http request has completed its download from the steam api server
*/
public OnDownloadComplete(HTTPRequestHandle:HTTPRequest, bool:requestSuccessful, HTTPStatusCode:statusCode, any:userid) 
{
    new client = GetClientOfUserId(userid);

    // Console, do nothing
    if (client == 0) {
        Steam_ReleaseHTTPRequest(HTTPRequest)
        return
    }

    // Check if the http request went bad
    // This can also happen if the key is missing from the sent parameters
    // In case of forbitten, etc. allows players to play without checking the playtime (which would be hard or nearly impossible)
    if (!requestSuccessful || statusCode != HTTPStatusCode_OK) {
        LogItem(Log_Debug, "HTTP request hit a snag! | HTTPRequest: %i | Was the request succesfull: %i | Status code: %i | Client: %L", (HTTPRequest == g_HTTPRequest), requestSuccessful, statusCode, client)
        Steam_ReleaseHTTPRequest(HTTPRequest)
        return
    }

    // Get the buffer size from the http response
    new bodyBufferSize = Steam_GetHTTPResponseBodySize(HTTPRequest) + 1
    // Creating a string buffer for the response
    decl String:bodyBuffer[bodyBufferSize]
    // Put the response in the buffer and release the request
    Steam_GetHTTPResponseBodyData(HTTPRequest, bodyBuffer, bodyBufferSize)

    // Release the http request
    Steam_ReleaseHTTPRequest(HTTPRequest)
    // Clear the http request
    g_HTTPRequest = INVALID_HTTP_HANDLE
    // Check for the total playtime
    int playerTotalPlaytime = GetGameTotalPlaytime(bodyBuffer, "440", 8, client)

    // DEBUGGING
    if (playerTotalPlaytime == 999999) {
        return
    }

    // Kick the player if the total playtime is too low
    if (playerTotalPlaytime < ruma_time) {
        // Kick the client
        KickClient(client, ruma_kickmsg)
        LogItem(Log_Info, "(Method A): client %L was kicked for having a playtime of %i hours. The hour limit is set to %i hours.", client, playerTotalPlaytime, ruma_time)
    } else {
        // Save player names to the DB
        AddPlayerClientToDB(client)
    }
}


/*
    Called when a client receives an auth ID. The state of a client's authorization as an admin is not guaranteed here.
    Part of the method B
*/


/*
    The server receives the player game stats
    Part of the method B
*/
public Steam_StatsReceived(client)
{
    // Get the total playtime from each played character playtime in seconds
    // This is buggy and not very reliable.
    new playtime = Steam_GetStat(client, "Demoman.accum.iPlayTime") + Steam_GetStat(client, "Engineer.accum.iPlayTime") + Steam_GetStat(client, "Heavy.accum.iPlayTime") + Steam_GetStat(client, "Medic.accum.iPlayTime") + Steam_GetStat(client, "Pyro.accum.iPlayTime") + Steam_GetStat(client, "Scout.accum.iPlayTime") + Steam_GetStat(client, "Sniper.accum.iPlayTime") + Steam_GetStat(client, "Soldier.accum.iPlayTime") + Steam_GetStat(client, "Spy.accum.iPlayTime")
    
    // Kick the player if the playtime is too low
    if (playtime / 3600 < ruma_time) {
        // Kick the client
        KickClient(client, ruma_kickmsg)

        LogItem(Log_Info, "(Method B): client %L was kicked for having a playtime of %i hours. The hour limit is set to %i hours.", client, playtime / 3600, ruma_time)
    } else {
        // Save player names to the DB
        AddPlayerClientToDB(client)
    }

    LogItem(Log_Debug, "Used method B for client: %L", client)
}


/*
    Add client to the DB
*/
AddPlayerClientToDB(int client)
{
    // steamcid buffer
    decl String:steamcid[32]
    // Get the 64bit steam id from the client
    Steam_GetCSteamIDForClient(client, steamcid, sizeof(steamcid))
    // Add player to the DB
    AddPlayerToDB(steamcid)
}

/*
    Get the total playtime in hours
*/
int GetGameTotalPlaytime(String:dataBuffer[], String:gameid[], maxlength, int client)
{
    new Handle:kv = CreateKeyValues("response")
    StringToKeyValues(kv, dataBuffer, "dataBuffer")

    // Use method B if player profile is set to private
    // This usually means the response is empty
    if (!KvGotoFirstSubKey(kv)) {
        Steam_RequestStats(client)
        return 999999
    }

    decl String:gameidBuffer[8]

    KvGotoNextKey(kv)                                   // games
    KvGotoFirstSubKey(kv, true)                         //   |--- 0
    KvGetString(kv, "appid", gameidBuffer, maxlength)   //        |--- 440

    // Check that the gameid is correct, in case of sorcery
    if (StrEqual(gameidBuffer, gameid)) {
        // Total playtime in minutes
        int totalMinutes = KvGetNum(kv, "playtime_forever", 0)

        LogItem(Log_Debug, "Player %L has %i minutes of playtime (%i hours)", client, totalMinutes, totalMinutes / 60)

        // Return the playtime in hours
        return totalMinutes / 60
    }

    CloseHandle(kv)

    // This should never happen anymore
    LogItem(Log_Debug, "Player %L has 0 minutes of playtime | Response body: %s", client, dataBuffer)

    return 999999
}


/*
    Check if the player is already in the DB, using the steam community id
*/
bool:AllowPlayerFromDB(String:steamcid[])
{  
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
        LogItem(Log_Error, "AllowPlayerFromDB failed to query (error: %s)", error)
    } else {
        if (SQL_FetchRow(query)) {
            // Close the query handle
            CloseHandle(query)
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
    // DB query buffer
    decl String:dbQuery[512]
    new bool:queryStatus
    // Formatting the DB query
    Format(dbQuery, sizeof(dbQuery), "INSERT INTO ruma_db VALUES ('%s')", steamcid)
    // A lock, query and unlock
    SQL_LockDatabase(db)
    queryStatus = SQL_FastQuery(db, dbQuery)
    SQL_UnlockDatabase(db)

    PrintToServer("Added a new player to the db with steamcid %s", steamcid)

    // Error checking, reporting and logging
    if (!queryStatus) {
        new String:error[255]
        SQL_GetError(db, error, sizeof(error))
        // Log message
        LogItem(Log_Error, "AddPlayerToDB failed to query (error: %s)", error)
        return false
    } else {
        return true
    }
}