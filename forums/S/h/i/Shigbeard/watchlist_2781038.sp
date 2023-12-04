#include <discordWebhookAPI> // Discord Webhook API by Sarrus
#include <DateTime> // DateTime by Nexd
#include <sourcemod>
#include <dbi>
#include <regex>
#include <handles>

/*
    Shoutouts to the following people for their help:
    - Nexd: DateTime include, pointing out the mixed syntaxes.
    - Sarrus: better discord api.
    - V1SoR: function for getting a 64bit steamid without any bigint crap. Saved me an include.
    - Zipcore: for the kv file loading that i stole.
    - You: for being breathtaking

    Thanks gamers! I'm honestly sick of staring at this code.
*/

// --------------------------------------------------------------------------------------------------------------------
#define PLUGIN_VERSION                          "2.0"
#define PLUGIN_RELEASE_DATE                     "2022-06-09"
#define PLUGIN_NAME                             "Player Watchlist"
#define PLUGIN_AUTHOR                           "Shigbeard"
// --------------------------------------------------------------------------------------------------------------------
// this is just so I know when i'm not passing a client to a function that expects but doesn't require it, which I think
//  i do precisely once.
#define NO_CLIENT                               -1
// --------------------------------------------------------------------------------------------------------------------
// dbi doesnt seem to want me to index columns by their names, but rather by their position. So, for the sake of not
//  having to refer back to the database schema, i'm just dumping these defines here
#define COLUMN_STEAMID                          0
#define COLUMN_TIMESTAMP                        1
#define COLUMN_ADMIN                            2
#define COLUMN_REASON                           3
// --------------------------------------------------------------------------------------------------------------------
// simple flag to determine which alert we're pushing out so I don't need 6 functions to do one job in 6 wacky flavors
#define ALERT_BUGGED                            0
#define ALERT_CONNECTED                         1
#define ALERT_DISCONNECTED                      2
#define ALERT_ADDED                             3
#define ALERT_REMOVED                           4
#define ALERT_CLEARED                           5
// --------------------------------------------------------------------------------------------------------------------
#define SELECT_QUERY_SPECIFIC                   "SELECT * FROM watchlist WHERE steamid = '{STEAMID}';"
#define SELECT_QUERY_RANGE                      "SELECT * FROM watchlist ORDER BY watched_since DESC LIMIT 10 OFFSET {OFFSET};"
#define INSERT_QUERY                            "INSERT INTO watchlist (steamid, watched_since, watched_by, reason) VALUES ('{STEAMID}', '{TIMESTAMP}', '{ADMIN}', '{REASON}');"
#define DELETE_QUERY                            "DELETE FROM watchlist WHERE steamid = '{STEAMID}';"
#define CREATE_QUERY                            "CREATE TABLE IF NOT EXISTS watchlist (steamid varchar(24) PRIMARY KEY NOT NULL, watched_since varchar(32) NOT NULL, watched_by varchar(100) NOT NULL, reason varchar(250));"
#define CLEAR_QUERY                             "TRUNCATE TABLE watchlist;"

#define CONNECT_URL                             "steam://connect/{HOST}"
#define COMMUNITY_URL                           "https://steamcommunity.com/profiles/{STEAMID64}"
#define STEAMID_REGEX                           "^STEAM_0:[0-1]:[0-9]+$"

#define OUTPUT_ROW                              "#{COUNT} [{TIMESTAMP}] {ADMIN} watchlisted {STEAMID}: {REASON}\n"
// --------------------------------------------------------------------------------------------------------------------
// ConVar Globals
// - generic
ConVar g_watchlist_sqlConfig                    = null;
ConVar g_watchlist_hostName                     = null;
ConVar g_watchlist_connectString                = null;
// - fallback
ConVar g_watchlist_fallback_mention             = null;
ConVar g_watchlist_fallback_webhook             = null;
// - notification enables
ConVar g_watchlist_notify_connect_enabled       = null;
ConVar g_watchlist_notify_disconnect_enabled    = null;
ConVar g_watchlist_notify_added_enabled         = null;
ConVar g_watchlist_notify_removed_enabled       = null;
ConVar g_watchlist_notify_cleared_enabled       = null;
// - notification webhooks
ConVar g_watchlist_notify_connect_webhook       = null;
ConVar g_watchlist_notify_disconnect_webhook    = null;
ConVar g_watchlist_notify_added_webhook         = null;
ConVar g_watchlist_notify_removed_webhook       = null;
ConVar g_watchlist_notify_cleared_webhook       = null;
// - notification colors
ConVar g_watchlist_notify_connect_color         = null;
ConVar g_watchlist_notify_disconnect_color      = null;
ConVar g_watchlist_notify_added_color           = null;
ConVar g_watchlist_notify_removed_color         = null;
ConVar g_watchlist_notify_cleared_color         = null;
// - mentions
ConVar g_watchlist_notify_connect_mention       = null;
ConVar g_watchlist_notify_disconnect_mention    = null;
ConVar g_watchlist_notify_added_mention         = null;
ConVar g_watchlist_notify_removed_mention       = null;
ConVar g_watchlist_notify_cleared_mention       = null;
// - notification fields
ConVar g_watchlist_embed_field_player           = null;
ConVar g_watchlist_embed_field_steamid          = null;
ConVar g_watchlist_embed_field_ip               = null;
ConVar g_watchlist_embed_field_profile          = null;
ConVar g_watchlist_embed_field_watched_since    = null;
ConVar g_watchlist_embed_field_watched_by       = null;
ConVar g_watchlist_embed_field_reason           = null;
ConVar g_watchlist_embed_field_server           = null;
// --------------------------------------------------------------------------------------------------------------------
public Plugin:myinfo = 
{
    name = PLUGIN_NAME,
    author = PLUGIN_AUTHOR,
    description = "Alert admins via Discord when watched players connect",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2781038",
}
// Plugin Start
public OnPluginStart()
{
    /////////////
    // CONVARS //
    /////////////
    g_watchlist_sqlConfig                       = CreateConVar("watchlist_sqlconfig", "watchlist", "Configuration for the SQL database - Required even if you use SQLite.");
    g_watchlist_hostName                        = CreateConVar("watchlist_server_name", "My TF2 Server", "The name of the server - will be used as the username for the webhook.");
    g_watchlist_connectString                   = CreateConVar("watchlist_server_ip", "127.0.0.1:27015", "The IP or URL that players can use to connect to your server (including port). Will be used to provide a connect link in the webhook.");

    g_watchlist_fallback_webhook                = CreateConVar("watchlist_fallback_webhook", "fallback", "The fallback webhook config - if no webhook is given for a specific notification, use this one.");
    g_watchlist_fallback_mention                = CreateConVar("watchlist_fallback_mention", "@here", "The fallback mention - if no mention is given for a specific notification, use this one.");

    g_watchlist_notify_connect_enabled          = CreateConVar("watchlist_notify_connect_enabled", "1", "Enable/disable Discord notification when a player connects");
    g_watchlist_notify_connect_webhook          = CreateConVar("watchlist_notify_connect_webhook", "connected", "Webhook config in discord.cfg to send the Discord notification to.");
    g_watchlist_notify_connect_color            = CreateConVar("watchlist_notify_connect_color", "65280", "Color of the Discord notification when a player connects");
    g_watchlist_notify_connect_mention          = CreateConVar("watchlist_notify_connect_mention", "@here", "Use this convar to mention a role or user in the Discord notification. Use @everyone to mention everyone, or mention a specific role with <@&roleid>");

    g_watchlist_notify_disconnect_enabled       = CreateConVar("watchlist_notify_disconnect_enabled", "1", "Enable/disable Discord notification when a player disconnects");
    g_watchlist_notify_disconnect_webhook       = CreateConVar("watchlist_notify_disconnect_webhook", "disconnected", "Webhook config in discord.cfg to send the Discord notification to.");
    g_watchlist_notify_disconnect_color         = CreateConVar("watchlist_notify_disconnect_color", "16711680", "Color of the Discord notification when a player disconnects");
    g_watchlist_notify_disconnect_mention       = CreateConVar("watchlist_notify_disconnect_mention", "@here", "Use this convar to mention a role or user in the Discord notification. Use @everyone to mention everyone, or mention a specific role with <@&roleid>");

    g_watchlist_notify_added_enabled            = CreateConVar("watchlist_notify_added_enabled", "1", "Enable/disable Discord notification when a player is added to the watchlist");
    g_watchlist_notify_added_webhook            = CreateConVar("watchlist_notify_added_webhook", "added", "Webhook config in discord.cfg to send the Discord notification to.");
    g_watchlist_notify_added_color              = CreateConVar("watchlist_notify_added_color", "16711935", "Color of the Discord notification when a player is added to the watchlist");
    g_watchlist_notify_added_mention            = CreateConVar("watchlist_notify_added_mention", "@here", "Use this convar to mention a role or user in the Discord notification. Use @everyone to mention everyone, or mention a specific role with <@&roleid>");
    
    g_watchlist_notify_removed_enabled          = CreateConVar("watchlist_notify_removed_enabled", "1", "Enable/disable Discord notification when a player is removed from the watchlist");
    g_watchlist_notify_removed_webhook          = CreateConVar("watchlist_notify_removed_webhook", "removed", "Webhook config in discord.cfg to send the Discord notification to.");
    g_watchlist_notify_removed_color            = CreateConVar("watchlist_notify_removed_color", "65535", "Color of the Discord notification when a player is removed from the watchlist");
    g_watchlist_notify_removed_mention          = CreateConVar("watchlist_notify_removed_mention", "@here", "Use this convar to mention a role or user in the Discord notification. Use @everyone to mention everyone, or mention a specific role with <@&roleid>");
    
    g_watchlist_notify_cleared_enabled          = CreateConVar("watchlist_notify_cleared_enabled", "1", "Enable/disable Discord notification when the watchlist is cleared");
    g_watchlist_notify_cleared_webhook          = CreateConVar("watchlist_notify_cleared_webhook", "cleared", "Webhook config in discord.cfg to send the Discord notification to.");
    g_watchlist_notify_cleared_color            = CreateConVar("watchlist_notify_cleared_color", "16777215", "Color of the Discord notification when the watchlist is cleared");
    g_watchlist_notify_cleared_mention          = CreateConVar("watchlist_notify_cleared_mention", "@here", "Use this convar to mention a role or user in the Discord notification. Use @everyone to mention everyone, or mention a specific role with <@&roleid>");

    g_watchlist_embed_field_player              = CreateConVar("watchlist_embed_field_player", "1", "Enable/disable the player field in the Discord embed");
    g_watchlist_embed_field_steamid             = CreateConVar("watchlist_embed_field_steamid", "1", "Enable/disable the SteamID field in the Discord embed");
    g_watchlist_embed_field_ip                  = CreateConVar("watchlist_embed_field_ip", "0", "Enable/disable the IP field in the Discord embed");
    g_watchlist_embed_field_profile             = CreateConVar("watchlist_embed_field_profile", "1", "Enable/disable the profile link field in the Discord embed");
    g_watchlist_embed_field_watched_since       = CreateConVar("watchlist_embed_field_watched_since", "1", "Enable/disable the watched since field in the Discord embed");
    g_watchlist_embed_field_watched_by          = CreateConVar("watchlist_embed_field_watched_by", "1", "Enable/disable the watched by field in the Discord embed");
    g_watchlist_embed_field_reason              = CreateConVar("watchlist_embed_field_reason", "1", "Enable/disable the reason field in the Discord embed");
    g_watchlist_embed_field_server              = CreateConVar("watchlist_embed_field_server", "1", "Enable/disable the server field in the Discord embed");

    AutoExecConfig(true, "watchlist");

    RegAdminCmd("watchlist_version", Watchlist_Command_Version, ADMFLAG_KICK, "Prints the version of the plugin");
    RegAdminCmd("watchlist_add", Watchlist_Command_Add, ADMFLAG_KICK, "Adds a player to the watchlist");
    RegAdminCmd("watchlist_remove", Watchlist_Command_Remove, ADMFLAG_KICK, "Removes a player from the watchlist");
    RegAdminCmd("watchlist_list", Watchlist_Command_List, ADMFLAG_KICK, "Lists all players on the watchlist");
    RegAdminCmd("watchlist_clear", Watchlist_Command_Clear, ADMFLAG_RCON, "Clears the watchlist - must have rcon permission");
    RegAdminCmd("watchlist_setup_database", Watchlist_Command_SetupDatabase, ADMFLAG_RCON, "Sets up the SQL database - must have rcon permission");
    RegServerCmd("watchlist_healthcheck", Watchlist_Command_Healthcheck, "Checks the health of the plugin", 0);

    HookEvent("player_activate", Watchlist_Event_PlayerConnect, EventHookMode_Post);
    HookEvent("player_disconnect", Watchlist_Event_PlayerDisconnect, EventHookMode_Pre);

    Watchlist_CheckDatabaseExists();
}

Database Watchlist_Database_Connect()
{
    char dbError[255];
    Database db;
    char dbConfig[255];

    GetConVarString(g_watchlist_sqlConfig, dbConfig, sizeof(dbConfig));
    if (SQL_CheckConfig(dbConfig)) {
        db = SQL_Connect(dbConfig, true, dbError, sizeof(dbError));
    } else {
        db = SQL_Connect(dbConfig, false, dbError, sizeof(dbError));
    }

    if (db == null) {
        LogError("[Player Watchlist] Failed to connect to the database: %s\nThe Plugin cannot continue.", dbError);
        return null;
    }
    return db;
}

void Watchlist_Handle_Query_Error(int client = -1, Database db)
{
    char dbError[255];
    SQL_GetError(db, dbError, sizeof(dbError));
    LogError("[Player Watchlist] Query error: %s\n", dbError);
    if (client != -1) {
        ReplyToCommand(client, "[Player Watchlist] Query error: %s", dbError);
    }
    delete db;
}

void Watchlist_Create_Table(int client, Database db)
{
    char query[511];
    // char watchlistDatabaseQueryError[255];
    strcopy(query, sizeof(query), CREATE_QUERY);
    if (!SQL_FastQuery(db, query)) {
        Watchlist_Handle_Query_Error(client, db);
        return;
    }
    if (client != NO_CLIENT)
    {
        ReplyToCommand(client, "Successfully created the watchlist table");
    }
}

void Watchlist_CheckDatabaseExists()
{
    Database db = Watchlist_Database_Connect();
    if (db == null) {
        return;
    }
    char query[511];
    strcopy(query, sizeof(query), "SELECT * FROM watchlist LIMIT 1;");
    DBResultSet result = SQL_Query(db, query);
    if (result == null) {
        Watchlist_Create_Table(NO_CLIENT, db);
    }
    delete db;
}

// Taken from V1SoR's post on the forums (changed to new syntax as best I can AND OFC IT DOENST WORK)
// void SteamIDToCommunityID(const char[] CommunityID, size, const char[] SteamID)
// {
//     char buffer[3][32];
//     ExplodeString(SteamID, ":", buffer, 3, 32);
//     int accountID = StringToInt(buffer[2]) * 2 + StringToInt(buffer[1]);
//     if (accountID >= 39734272)
//     {
//         strcopy(CommunityID, size, CommunityID[1]);
//         Format(CommunityID, size, "765611980%s", CommunityID);
//     }
//     else
//     {
//         Format(CommunityID, size, "765611979%s", CommunityID);
//     }
// }
// Original code:
SteamIDToCommunityID(String:CommunityID[], size, const String:SteamID[])
{
    decl String:buffer[3][32];
    ExplodeString(SteamID, ":", buffer, 3, 32);
    new accountID = StringToInt(buffer[2]) * 2 + StringToInt(buffer[1]);

    IntToString((accountID + 60265728), CommunityID, size);

    if (accountID >= 39734272)
    {
        strcopy(CommunityID, size, CommunityID[1]);
        Format(CommunityID, size, "765611980%s", CommunityID);
    }
    else
    {
        Format(CommunityID, size, "765611979%s", CommunityID);
    }
}  

// We're gonna steal Zipcore's webhook config file. This is lifted straight from his plugin so that the behavior is the same.
bool GetWebHook(const char[] sWebhook, char[] sUrl, int iLength)
{
	KeyValues kv = new KeyValues("Discord");
	
	char sFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sFile, sizeof(sFile), "configs/discord.cfg");

	if (!FileExists(sFile))
	{
		PrintToServer("[GetWebHook] \"%s\" not found!", sFile);
		return false;
	}

	kv.ImportFromFile(sFile);

	if (!kv.GotoFirstSubKey())
	{
		PrintToServer("[GetWebHook] Can't find webhook for \"%s\"!", sFile);
		return false;
	}
	
	char sBuffer[64];
	
	do
	{
		kv.GetSectionName(sBuffer, sizeof(sBuffer));
		
		if(StrEqual(sBuffer, sWebhook, false))
		{
			kv.GetString("url", sUrl, iLength);
			delete kv;
			return true;
		}
	}
	while (kv.GotoNextKey());
	
	delete kv;
	
	return false;
}

public void Watchlist_Webhook_Callback(HTTPResponse response, DataPack pack)
{
    if (response.Status != HTTPStatus_NoContent)
    {
        PrintToServer("[Player Watchlist] Something went wrong when trying to send a notification to discord. Check your webhook url is correct and try again.")
        return;
    }
    return
}

// --------------------------------------------------------------------------------------------------------------------
// COMMANDS
// --------------------------------------------------------------------------------------------------------------------

public Action Watchlist_Command_Version(int client, int args) 
{
    ReplyToCommand(client, "[Player Watchlist] By Shigbeard, version %s released on %s", PLUGIN_VERSION, PLUGIN_RELEASE_DATE);
    return Plugin_Handled;
}

public Action Watchlist_Command_SetupDatabase(int client, int args) 
{
    Database db = Watchlist_Database_Connect();
    if (db == null) {
        return Plugin_Handled; // Error is already printed by Watchlist_Database_Connect
    }
    
    // TODO: Check if the table is an older version
    // - Don't need to do this yet, we haven't revised the table schema yet.

    // TODO: Check database ident and change syntax if needed
    // - Not neccisary, our create query is correct in both syntaxes.

    Watchlist_Create_Table(client, db); // Command feedback is handled by the child function
    delete db; // Always close our database connection because tidy code is good
    return Plugin_Handled;
}

public Action Watchlist_Command_Add(int client, int args) 
{
    int argCount = GetCmdArgs();
    if (argCount < 2) {
        ReplyToCommand(client, "[Player Watchlist] Usage: watchlist_add <steamid> [reason]");
        return Plugin_Handled;
    }

    char arguments[256];
    GetCmdArgString(arguments, sizeof(arguments));

    char steamid[20];
    char reason[236];
    int len = BreakString(arguments, steamid, sizeof(steamid));
    if (len == -1)
    {
        len = 0;
        arguments[0] = '\0';
    }
    strcopy(reason, sizeof(reason), arguments[len]);
    char regerror[128];
    int regmatches = SimpleRegexMatch(steamid, STEAMID_REGEX, 0, regerror, sizeof(regerror));

    if (regmatches == 1) {
        // match

        Database db = Watchlist_Database_Connect();
        if (db == null) {
            return Plugin_Handled; // Error is already printed by Watchlist_Database_Connect
        }
        char query[1024];
        // char queryError[255];
        strcopy(query, sizeof(query), SELECT_QUERY_SPECIFIC);
        ReplaceString(query, sizeof(query), "{STEAMID}", steamid);
        DBResultSet results = SQL_Query(db, query);
        if (results == null) {
            Watchlist_Handle_Query_Error(client, db);
            return Plugin_Handled;
        } else {
            if (SQL_GetRowCount(results) > 0) {
                SQL_FetchRow(results);
                char queryAdmin[100];
                char queryReason[250];
                SQL_FetchString(results, COLUMN_ADMIN, queryAdmin, sizeof(queryAdmin));
                SQL_FetchString(results, COLUMN_REASON, queryReason, sizeof(queryReason));
                ReplyToCommand(client, "%s is already watched by %s: %s", steamid, queryAdmin, queryReason);
                delete db;
                return Plugin_Handled;
            }
            char query2[1024];
            char query2AdminName[100];
            DateTime query2TimestampDateTime = new DateTime(DateTime_Now);
            int query2TimestampInt = query2TimestampDateTime.Unix;
            char query2Timestamp[32];
            strcopy(query2, sizeof(query2), INSERT_QUERY);
            ReplaceString(query2, sizeof(query2), "{STEAMID}", steamid);
            ReplaceString(query2, sizeof(query2), "{REASON}", reason);
            if (client == 0) {
                strcopy(query2AdminName, sizeof(query2AdminName), "(Console)");
            } else {
                GetClientName(client, query2AdminName, sizeof(query2AdminName));
            }
            ReplaceString(query2, sizeof(query2), "{ADMIN}", query2AdminName);
            IntToString(query2TimestampInt, query2Timestamp, sizeof(query2Timestamp));
            ReplaceString(query2, sizeof(query2), "{TIMESTAMP}", query2Timestamp);
            if (!SQL_FastQuery(db, query2)) {
                Watchlist_Handle_Query_Error(client, db);
                return Plugin_Handled;
            }
            ReplyToCommand(client, "Successfully added %s to the watchlist", steamid);
            
            SendDiscordWebhook("", steamid, "", "", 0, query2AdminName, reason, ALERT_ADDED);
            delete db;
            return Plugin_Handled;
        }
    }
    ReplyToCommand(client, "[Player Watchlist] Invalid SteamID: %s", steamid);
    return Plugin_Handled;
}

public Action Watchlist_Command_Remove(int client, int args)
{
    int watchlistCommandRemoveArgCount = GetCmdArgs();
    if (watchlistCommandRemoveArgCount < 2) {
        ReplyToCommand(client, "[Player Watchlist] Usage: watchlist_remove <steamid>");
        return Plugin_Handled;
    }
    char watchlistCommandRemoveArguments[256];
    GetCmdArgString(watchlistCommandRemoveArguments, sizeof(watchlistCommandRemoveArguments));
    char watchlistCommandRemoveSteamID[20];
    int watchlistCommandRemoveLen = BreakString(watchlistCommandRemoveArguments, watchlistCommandRemoveSteamID, sizeof(watchlistCommandRemoveSteamID));
    if (watchlistCommandRemoveLen == -1)
    {
        watchlistCommandRemoveLen = 0;
        watchlistCommandRemoveArguments[0] = '\0';
    }
    char watchlistCommandRemoveRegexError[128];
    int watchlistCommandRemoveRegexMatches = SimpleRegexMatch(watchlistCommandRemoveSteamID, STEAMID_REGEX, 0, watchlistCommandRemoveRegexError, sizeof(watchlistCommandRemoveRegexError));
    if (watchlistCommandRemoveRegexMatches == 1) {
        Database watchlistCommandRemoveDatabase = Watchlist_Database_Connect();
        if (watchlistCommandRemoveDatabase == null) {
            return Plugin_Handled; // Error is already printed by Watchlist_Database_Connect
        }
        char watchlistCommandRemoveQuery[1024];
        // char watchlistCommandRemoveQueryError[255];
        strcopy(watchlistCommandRemoveQuery, sizeof(watchlistCommandRemoveQuery), SELECT_QUERY_SPECIFIC);
        ReplaceString(watchlistCommandRemoveQuery, sizeof(watchlistCommandRemoveQuery), "{STEAMID}", watchlistCommandRemoveSteamID);
        DBResultSet watchlistCommandRemoveQueryResults = SQL_Query(watchlistCommandRemoveDatabase, watchlistCommandRemoveQuery);
        if (watchlistCommandRemoveQueryResults == null) {
            Watchlist_Handle_Query_Error(client, watchlistCommandRemoveDatabase);
            return Plugin_Handled;
        }
        if (SQL_GetRowCount(watchlistCommandRemoveQueryResults) == 0) {
            ReplyToCommand(client, "%s is not on the watchlist", watchlistCommandRemoveSteamID);
            return Plugin_Handled;
        }
        char watchlistCommandRemoveQuery2[1024];
        strcopy(watchlistCommandRemoveQuery2, sizeof(watchlistCommandRemoveQuery2), DELETE_QUERY);
        ReplaceString(watchlistCommandRemoveQuery2, sizeof(watchlistCommandRemoveQuery2), "{STEAMID}", watchlistCommandRemoveSteamID);
        if (!SQL_FastQuery(watchlistCommandRemoveDatabase, watchlistCommandRemoveQuery2)) {
            Watchlist_Handle_Query_Error(client, watchlistCommandRemoveDatabase);
            return Plugin_Handled;
        }
        ReplyToCommand(client, "Successfully removed %s from the watchlist", watchlistCommandRemoveSteamID);
        char adminname[52];
        if (client == 0) {
            strcopy(adminname, sizeof(adminname), "(Console)");
        } else {
            GetClientName(client, adminname, sizeof(adminname));
        }
        SendDiscordWebhook("", watchlistCommandRemoveSteamID, "", "", 0, adminname, "", ALERT_REMOVED);
        return Plugin_Handled;
    }
    ReplyToCommand(client, "[Player Watchlist] Invalid SteamID: %s", watchlistCommandRemoveSteamID);
    return Plugin_Handled;
}

public Action Watchlist_Command_List(int client, int args)
{
    // If no argument, list first 10 entries
    // If argument is Steamid, find that entry.
    // If argument is number greater than 0, 10*(arg-1) to 10*(arg-1)+10
    // If argument is number equal to or less than 0, list first 10 entries
    // If argument is anything else, list first 10 entries

    // arg is 1
    // 1-1=0 * 10 = 0 + 10 = 10
    Database watchlistCommandListDatabase = Watchlist_Database_Connect();
    if (watchlistCommandListDatabase == null) {
        return Plugin_Handled; // Error is already printed by Watchlist_Database_Connect
    }
    char watchlistCommandListQuery[1024];
    int watchlistCommandListArgCount = GetCmdArgs();
    int watchlistCommandListPage = 1;
    if (watchlistCommandListArgCount >= 1) {
        char watchlistCommandListArguments[256];
        GetCmdArgString(watchlistCommandListArguments, sizeof(watchlistCommandListArguments));
        char watchlistCommandListArgument[20];
        int watchlistCommandListArgumentLen = BreakString(watchlistCommandListArguments, watchlistCommandListArgument, sizeof(watchlistCommandListArgument));
        // int watchlistCommandListArgumentInt;
        if (watchlistCommandListArgumentLen == -1)
        {
            watchlistCommandListArgumentLen = 0;
            watchlistCommandListArguments[0] = '\0';
        }
        char watchlistCommandListRegexError[128];
        int watchlistCommandListRegexMatches = SimpleRegexMatch(watchlistCommandListArgument, STEAMID_REGEX, 0, watchlistCommandListRegexError, sizeof(watchlistCommandListRegexError));
        if (watchlistCommandListRegexMatches == 1) {
            // Search for Steam ID
            strcopy(watchlistCommandListQuery, sizeof(watchlistCommandListQuery), SELECT_QUERY_SPECIFIC);
            ReplaceString(watchlistCommandListQuery, sizeof(watchlistCommandListQuery), "{STEAMID}", watchlistCommandListArgument);
        } else {
            watchlistCommandListPage = StringToInt(watchlistCommandListArgument);
            
            
            strcopy(watchlistCommandListQuery, sizeof(watchlistCommandListQuery), SELECT_QUERY_RANGE);
            char watchlistCommandListQueryOffset[8];
            if (watchlistCommandListPage < 1) {
                watchlistCommandListPage = 1;
            }
            IntToString((watchlistCommandListPage - 1) * 10, watchlistCommandListQueryOffset, sizeof(watchlistCommandListQueryOffset));
            ReplaceString(watchlistCommandListQuery, sizeof(watchlistCommandListQuery), "{OFFSET}", watchlistCommandListQueryOffset);
        }
    } else {
        strcopy(watchlistCommandListQuery, sizeof(watchlistCommandListQuery), SELECT_QUERY_RANGE);
        ReplaceString(watchlistCommandListQuery, sizeof(watchlistCommandListQuery), "{OFFSET}", "0");
    }
    DBResultSet watchlistCommandListQueryResults = SQL_Query(watchlistCommandListDatabase, watchlistCommandListQuery); 
    if (watchlistCommandListQueryResults == null) {
        Watchlist_Handle_Query_Error(client, watchlistCommandListDatabase);
        return Plugin_Handled;
    }
    int watchlistCommandListRowCount = SQL_GetRowCount(watchlistCommandListQueryResults);
    if (watchlistCommandListRowCount == 0) {
        if (watchlistCommandListPage == 1) {
            ReplyToCommand(client, "[Player Watchlist] No entries found");
        } else {
            ReplyToCommand(client, "[Player Watchlist] No more entries found");
        }
        return Plugin_Handled;
    }
    char watchlistCommandOutput[2048];
    strcopy(watchlistCommandOutput, sizeof(watchlistCommandOutput), "[Player Watchlist] Watched Players\n");
    int watchlistCommandListRow = 0;
    while (watchlistCommandListRow < watchlistCommandListRowCount) {
        bool watchlistCommandListHasRow = SQL_FetchRow(watchlistCommandListQueryResults);
        if (!watchlistCommandListHasRow) {
            break;
        }
        char watchlistCommandListSteamID[24];
        char watchlistCommandListAdmin[100];
        char watchlistCommandListReason[250];
        char watchlistCommandListTimestamp[32];
        SQL_FetchString(watchlistCommandListQueryResults, COLUMN_STEAMID, watchlistCommandListSteamID, sizeof(watchlistCommandListSteamID));
        SQL_FetchString(watchlistCommandListQueryResults, COLUMN_ADMIN, watchlistCommandListAdmin, sizeof(watchlistCommandListAdmin));
        SQL_FetchString(watchlistCommandListQueryResults, COLUMN_REASON, watchlistCommandListReason, sizeof(watchlistCommandListReason));
        SQL_FetchString(watchlistCommandListQueryResults, COLUMN_TIMESTAMP, watchlistCommandListTimestamp, sizeof(watchlistCommandListTimestamp));
        
        char watchlistCommandListOutputRow[1024];
        strcopy(watchlistCommandListOutputRow, sizeof(watchlistCommandListOutputRow), OUTPUT_ROW);
        ReplaceString(watchlistCommandListOutputRow, sizeof(watchlistCommandListOutputRow), "{STEAMID}", watchlistCommandListSteamID);
        ReplaceString(watchlistCommandListOutputRow, sizeof(watchlistCommandListOutputRow), "{ADMIN}", watchlistCommandListAdmin);
        ReplaceString(watchlistCommandListOutputRow, sizeof(watchlistCommandListOutputRow), "{REASON}", watchlistCommandListReason);

        int watchlistCommandListTimestampInt = StringToInt(watchlistCommandListTimestamp);
        char watchlistCommandListTimestampOutput[64];
        FormatTime(watchlistCommandListTimestampOutput, sizeof(watchlistCommandListTimestampOutput), "%Y-%m-%d %H:%M.%S", watchlistCommandListTimestampInt);
        ReplaceString(watchlistCommandListOutputRow, sizeof(watchlistCommandListOutputRow), "{TIMESTAMP}", watchlistCommandListTimestampOutput);
        char watchlistCommandListRowNumber[8];
        IntToString(watchlistCommandListRow + 1 + (watchlistCommandListPage-1)*10, watchlistCommandListRowNumber, sizeof(watchlistCommandListRowNumber));
        ReplaceString(watchlistCommandListOutputRow, sizeof(watchlistCommandListOutputRow), "{COUNT}", watchlistCommandListRowNumber);
        StrCat(watchlistCommandOutput, sizeof(watchlistCommandOutput), watchlistCommandListOutputRow);
        watchlistCommandListRow = watchlistCommandListRow + 1;
    }
    char watchlistCommandListPageNumberOutput[16];
    char watchlistCommandListPageNumberAsAString[8];
    strcopy(watchlistCommandListPageNumberOutput, sizeof(watchlistCommandListPageNumberOutput), "Page {PAGE}");
    IntToString(watchlistCommandListPage, watchlistCommandListPageNumberAsAString, sizeof(watchlistCommandListPageNumberAsAString));
    ReplaceString(watchlistCommandListPageNumberOutput, sizeof(watchlistCommandListPageNumberOutput), "{PAGE}", watchlistCommandListPageNumberAsAString);
    StrCat(watchlistCommandOutput, sizeof(watchlistCommandOutput), watchlistCommandListPageNumberOutput);
    PrintToConsole(client, watchlistCommandOutput);
    return Plugin_Handled;
}

public Action Watchlist_Command_Clear(int client, int args)
{
    Database watchlistCommandClearDatabase = Watchlist_Database_Connect();
    if (watchlistCommandClearDatabase == null) {
        return Plugin_Handled;
    }
    if(!SQL_FastQuery(watchlistCommandClearDatabase, CLEAR_QUERY)) {
        Watchlist_Handle_Query_Error(client, watchlistCommandClearDatabase);
        return Plugin_Handled;
    }
    ReplyToCommand(client, "[Player Watchlist] Watchlist cleared");
    char adminname[52];
    if(client == 0)
    {
        strcopy(adminname, sizeof(adminname), "(Console)");
    }
    else
    {
        GetClientName(client, adminname, sizeof(adminname));
    }
    SendDiscordWebhook("", "", "", "", 0, adminname, "", ALERT_CLEARED);
    return Plugin_Handled;
}

public Action Watchlist_Command_Healthcheck(int args)
{
    char responseString[2048];
    // Check that the SQL config has been set
    char watchlistCommandHealthcheckSQLConfig[64];
    GetConVarString(g_watchlist_sqlConfig, watchlistCommandHealthcheckSQLConfig, sizeof(watchlistCommandHealthcheckSQLConfig));
    if (strlen(watchlistCommandHealthcheckSQLConfig) == 0) {
        StrCat(responseString, sizeof(responseString), "watchlist_sqlconfig not set - please set watchlist_sqlconfig to the name of the SQL config in your MySQL config file - EVEN IF YOU USE SQLITE\n");
    }
    // Check that the SQL config is valid
    else if (!SQL_CheckConfig(watchlistCommandHealthcheckSQLConfig)) {
        StrCat(responseString, sizeof(responseString), "watchlist_sqlconfig is set but no matching SQL config could be found - please check your MySQL config file\n");
    }
    bool connectEnabled = GetConVarBool(g_watchlist_notify_connect_enabled);
    bool disconnectEnabled = GetConVarBool(g_watchlist_notify_disconnect_enabled);
    if (!connectEnabled && !disconnectEnabled) {
        StrCat(responseString, sizeof(responseString), "watchlist_notify_connect_enabled and watchlist_notify_disconnect_enabled are both off - this will result in ZERO functionality.\n");
    }
    // Check that the webhook is set
    char watchlistCommandHealthcheckWebhook[64];
    GetConVarString(g_watchlist_fallback_webhook, watchlistCommandHealthcheckWebhook, sizeof(watchlistCommandHealthcheckWebhook));

    if (strlen(watchlistCommandHealthcheckWebhook) == 0) {
        StrCat(responseString, sizeof(responseString), "watchlist_fallback_webhook not set - This could be an issue, if you don't set per-notification overrides.\n");
    }

    StrCat(responseString, sizeof(responseString), "Healthcheck complete - Ultimately, you should make sure the entire config file is filled out.\n");
    PrintToServer(responseString);
    return Plugin_Handled;
}

//-----------------------------------------------------------------------------
// Connections
//-----------------------------------------------------------------------------

public Action Watchlist_Event_PlayerDisconnect(Handle event, const char[] name, bool dontBroadcast)
{
    int userid = GetEventInt(event, "userid")
    int watchlistTimerCheckPlayerClient = GetClientOfUserId(userid);
    if (Watchlist_Validate_Player(userid) > 0)
    {
        Watchlist_Process_Watched_Player(watchlistTimerCheckPlayerClient, ALERT_DISCONNECTED);
    } 
    return Plugin_Handled;
}


public Action Watchlist_Timer_CheckPlayer(Handle timer, int userid)
{
    int watchlistTimerCheckPlayerClient = GetClientOfUserId(userid);
    if (Watchlist_Validate_Player(watchlistTimerCheckPlayerClient) == 1) 
    {
        CreateTimer(5.0, Watchlist_Timer_CheckPlayer, userid);
        return Plugin_Continue;
    } 
    else if (Watchlist_Validate_Player(watchlistTimerCheckPlayerClient) == 2) 
    {
        Watchlist_Process_Watched_Player(watchlistTimerCheckPlayerClient, ALERT_CONNECTED);
        return Plugin_Handled;
    } 
    else 
    {
        return Plugin_Continue;
    }
}
public Action Watchlist_Event_PlayerConnect(Handle event, const char[] name, bool dontBroadcast)
{
    CreateTimer(5.0, Watchlist_Timer_CheckPlayer, GetEventInt(event, "userid"));
    return Plugin_Handled;
}

public int Watchlist_Validate_Player(int client)
{
    if (!client)
    {
        return 0
    }
    if (!IsClientConnected(client))
    {
        return 1
    }
    if (!IsClientAuthorized(client))
    {
        return 1
    } 
    if (IsFakeClient(client))
    {
        return 0
    }
    return 2
}

public Action Watchlist_Process_Watched_Player(int client, int alertType)
{
    Database watchlistProcessWatchedPlayerDatabase = Watchlist_Database_Connect();
    if (watchlistProcessWatchedPlayerDatabase == null) {
        return Plugin_Handled;
    }
    char watchlistProcessWatchedPlayerQuery[1024];
    char watchlistProcessWatchedPlayerSteamID[24];
    GetClientAuthId(client, AuthId_Steam2, watchlistProcessWatchedPlayerSteamID, sizeof(watchlistProcessWatchedPlayerSteamID));
    strcopy(watchlistProcessWatchedPlayerQuery, sizeof(watchlistProcessWatchedPlayerQuery), SELECT_QUERY_SPECIFIC);
    ReplaceString(watchlistProcessWatchedPlayerQuery, sizeof(watchlistProcessWatchedPlayerQuery), "{STEAMID}", watchlistProcessWatchedPlayerSteamID);
    DBResultSet watchlistProcessWatchedPlayerQueryResults = SQL_Query(watchlistProcessWatchedPlayerDatabase, watchlistProcessWatchedPlayerQuery);
    if (watchlistProcessWatchedPlayerQueryResults == null) {
        Watchlist_Handle_Query_Error(NO_CLIENT, watchlistProcessWatchedPlayerDatabase);
        return Plugin_Handled;
    }
    if (SQL_GetRowCount(watchlistProcessWatchedPlayerQueryResults) == 0) {
        return Plugin_Handled;
    }
    SQL_FetchRow(watchlistProcessWatchedPlayerQueryResults);
    char watchlistProcessWatchedPlayerTimestamp[32];
    char watchlistProcessWatchedPlayerAdmin[100];
    char watchlistProcessWatchedPlayerReason[250];
    SQL_FetchString(watchlistProcessWatchedPlayerQueryResults, COLUMN_TIMESTAMP, watchlistProcessWatchedPlayerTimestamp, sizeof(watchlistProcessWatchedPlayerTimestamp));
    SQL_FetchString(watchlistProcessWatchedPlayerQueryResults, COLUMN_ADMIN, watchlistProcessWatchedPlayerAdmin, sizeof(watchlistProcessWatchedPlayerAdmin));
    SQL_FetchString(watchlistProcessWatchedPlayerQueryResults, COLUMN_REASON, watchlistProcessWatchedPlayerReason, sizeof(watchlistProcessWatchedPlayerReason));

    char watchlistProcessWatchedPlayerName[24];
    GetClientName(client, watchlistProcessWatchedPlayerName, sizeof(watchlistProcessWatchedPlayerName));
    char watchlistProcessWatchedPlayerIP[16];
    GetClientIP(client, watchlistProcessWatchedPlayerIP, sizeof(watchlistProcessWatchedPlayerIP));
    char wathclistProcessWatchedPlayerSteamID64[64];
    GetClientAuthId(client, AuthId_SteamID64, wathclistProcessWatchedPlayerSteamID64, sizeof(wathclistProcessWatchedPlayerSteamID64));
    int  watchlistProcessWatchedPlayerTimestampInt = StringToInt(watchlistProcessWatchedPlayerTimestamp);
    SendDiscordWebhook(watchlistProcessWatchedPlayerName, watchlistProcessWatchedPlayerSteamID, watchlistProcessWatchedPlayerIP, wathclistProcessWatchedPlayerSteamID64, watchlistProcessWatchedPlayerTimestampInt, watchlistProcessWatchedPlayerAdmin, watchlistProcessWatchedPlayerReason, alertType);
    delete watchlistProcessWatchedPlayerDatabase;
    return Plugin_Handled;
}

//-----------------------------------------------------------------------------
// Discord Webhook Stuff
//-----------------------------------------------------------------------------

/**
 * Returns a message to be sent to Discord
 * 
 * @param player            Name of the player
 * @param steamid           SteamID of the player
 * @param ip                IP address of the player
 * @param profile           profileID of the player (so 64bit steamid)
 * @param watched_since     unix timestamp of when the player was watched without timezone adjustments
 * @param watched_by        Name of the admin who watched the player
 * @param reason            Reason for the watch
 * @return                  Message to be sent to Discord, or null if something went wrong.
 */


// Discord Webhook Alert
public Action SendDiscordWebhook(const char[] player, const char[] steamid, const char[] ip, const char[] profile, int watched_since, const char[] watched_by, const char[] reason, int alertType)
{
    // Set us up the buffers
    char watchlistDiscordTitle[256];
    char watchlistDiscordDescription[256];
    char watchlistDiscordContent[256];
    // char watchlistDiscordColor[16];
    char watchlistDiscordFields_player[256];
    char watchlistDiscordFields_steamid[256];
    char watchlistDiscordFields_ip[256];
    char watchlistDiscordFields_profile[256];
    char watchlistDiscordFields_watched_since[256];
    char watchlistDiscordFields_watched_by[256];
    char watchlistDiscordFields_reason[256];
    char watchlistDiscordFields_server[256];
    char watchlistDiscordWebhook[256];
    bool usePlayer = GetConVarBool(g_watchlist_embed_field_player);
    bool useSteamId = GetConVarBool(g_watchlist_embed_field_steamid);
    bool useIp = GetConVarBool(g_watchlist_embed_field_ip);
    bool useProfile = GetConVarBool(g_watchlist_embed_field_profile);
    bool useWatchedSince = GetConVarBool(g_watchlist_embed_field_watched_since);
    bool useWatchedBy = GetConVarBool(g_watchlist_embed_field_watched_by);
    bool useReason = GetConVarBool(g_watchlist_embed_field_reason);
    bool useServer = GetConVarBool(g_watchlist_embed_field_server);
    // bool useServer = GetConVarBool(g_watchlist_embed_field_server);
    GetConVarString(g_watchlist_hostName, watchlistDiscordFields_server, sizeof(watchlistDiscordFields_server));
    Webhook webhook = new Webhook(/* mention */);
    webhook.SetUsername(watchlistDiscordFields_server);


    Embed notification = new Embed();
    notification.SetTimeStampNow();
    switch(alertType)
    {
        case ALERT_CONNECTED:
        {
            if (!GetConVarBool(g_watchlist_notify_connect_enabled)) {
                // Do nothing and return
                delete webhook;
                return Plugin_Handled;
            }
            // Title
            strcopy(watchlistDiscordTitle, sizeof(watchlistDiscordTitle), "[Player Watchlist] Player Connected");
            // Description
            strcopy(watchlistDiscordDescription, sizeof(watchlistDiscordDescription), CONNECT_URL);
            char connectString[256];
            GetConVarString(g_watchlist_connectString, connectString, sizeof(connectString));
            ReplaceString(watchlistDiscordDescription, sizeof(watchlistDiscordDescription), "{HOST}", connectString);
            // Content
            GetConVarString(g_watchlist_notify_connect_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
            // Player name
            strcopy(watchlistDiscordFields_player, sizeof(watchlistDiscordFields_player), player);
            // Steam id
            strcopy(watchlistDiscordFields_steamid, sizeof(watchlistDiscordFields_steamid), steamid);
            // Profile link
            strcopy(watchlistDiscordFields_profile, sizeof(watchlistDiscordFields_profile), COMMUNITY_URL);
            ReplaceString(watchlistDiscordFields_profile, sizeof(watchlistDiscordFields_profile), "{STEAMID64}", profile);
            // IP
            strcopy(watchlistDiscordFields_ip, sizeof(watchlistDiscordFields_ip), ip);
            // Watched since
            strcopy(watchlistDiscordFields_watched_since, sizeof(watchlistDiscordFields_watched_since), "<t:{Z}>");
            char ts[24];
            IntToString(watched_since, ts, sizeof(ts));
            ReplaceString(watchlistDiscordFields_watched_since, sizeof(watchlistDiscordFields_watched_since), "{Z}", ts);
            // Watched By
            strcopy(watchlistDiscordFields_watched_by, sizeof(watchlistDiscordFields_watched_by), watched_by);
            // Reason
            strcopy(watchlistDiscordFields_reason, sizeof(watchlistDiscordFields_reason), reason);

            // Color
            notification.SetColor(GetConVarInt(g_watchlist_notify_connect_color));

            // mention
            GetConVarString(g_watchlist_notify_connect_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
            webhook.SetContent(watchlistDiscordContent);

            // Webhook
            GetConVarString(g_watchlist_notify_connect_webhook, watchlistDiscordWebhook, sizeof(watchlistDiscordWebhook));
        }
        case ALERT_DISCONNECTED:
        {
            if (!GetConVarBool(g_watchlist_notify_disconnect_enabled)) {
                // Do nothing and return
                delete webhook;
                return Plugin_Handled;
            }
            // Title
            strcopy(watchlistDiscordTitle, sizeof(watchlistDiscordTitle), "[Player Watchlist] Player Disconnected");
            // Description
            strcopy(watchlistDiscordDescription, sizeof(watchlistDiscordDescription), CONNECT_URL);
            char connectString[256];
            GetConVarString(g_watchlist_connectString, connectString, sizeof(connectString));
            ReplaceString(watchlistDiscordDescription, sizeof(watchlistDiscordDescription), "{HOST}", connectString);
            // Content
            GetConVarString(g_watchlist_notify_disconnect_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
            // Player name
            strcopy(watchlistDiscordFields_player, sizeof(watchlistDiscordFields_player), player);
            // Steam id
            strcopy(watchlistDiscordFields_steamid, sizeof(watchlistDiscordFields_steamid), steamid);
            // Profile link
            strcopy(watchlistDiscordFields_profile, sizeof(watchlistDiscordFields_profile), COMMUNITY_URL);
            ReplaceString(watchlistDiscordFields_profile, sizeof(watchlistDiscordFields_profile), "{STEAMID64}", profile);
            // IP
            strcopy(watchlistDiscordFields_ip, sizeof(watchlistDiscordFields_ip), ip);
            // Watched since
            strcopy(watchlistDiscordFields_watched_since, sizeof(watchlistDiscordFields_watched_since), "<t:{Z}>");
            char ts[24];
            IntToString(watched_since, ts, sizeof(ts));
            ReplaceString(watchlistDiscordFields_watched_since, sizeof(watchlistDiscordFields_watched_since), "{Z}", ts);
            // Watched By
            strcopy(watchlistDiscordFields_watched_by, sizeof(watchlistDiscordFields_watched_by), watched_by);
            // Reason
            strcopy(watchlistDiscordFields_reason, sizeof(watchlistDiscordFields_reason), reason);

            // Color
            notification.SetColor(GetConVarInt(g_watchlist_notify_disconnect_color));

            // mention
            GetConVarString(g_watchlist_notify_disconnect_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
            webhook.SetContent(watchlistDiscordContent);

            // Webhook
            GetConVarString(g_watchlist_notify_disconnect_webhook, watchlistDiscordWebhook, sizeof(watchlistDiscordWebhook));
        }
        case ALERT_ADDED:
        {
            if (!GetConVarBool(g_watchlist_notify_added_enabled)) {
                // Do nothing and return
                delete webhook;
                return Plugin_Handled;
            }
            // Title
            strcopy(watchlistDiscordTitle, sizeof(watchlistDiscordTitle), "[Player Watchlist] Player Added to List");
            // Content
            GetConVarString(g_watchlist_notify_added_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
            // Player name isn't given here, so set the player bool to false
            usePlayer = false;
            // IP isnt used
            useIp = false;
            // watched_since isnt used
            useWatchedSince = false;
            // Steam ID
            strcopy(watchlistDiscordFields_steamid, sizeof(watchlistDiscordFields_steamid), steamid);
            // Profile link
            char watchlistSteamid64[32];
            strcopy(watchlistDiscordFields_profile, sizeof(watchlistDiscordFields_profile), COMMUNITY_URL);
            SteamIDToCommunityID(watchlistSteamid64, sizeof(watchlistSteamid64), steamid);
            ReplaceString(watchlistDiscordFields_profile, sizeof(watchlistDiscordFields_profile), "{STEAMID64}", watchlistSteamid64);
            // Admin
            strcopy(watchlistDiscordFields_watched_by, sizeof(watchlistDiscordFields_watched_by), watched_by);
            // Reason
            strcopy(watchlistDiscordFields_reason, sizeof(watchlistDiscordFields_reason), reason);

            // Color
            notification.SetColor(GetConVarInt(g_watchlist_notify_added_color));

            // mention
            GetConVarString(g_watchlist_notify_added_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
            webhook.SetContent(watchlistDiscordContent);

            // Webhook
            GetConVarString(g_watchlist_notify_added_webhook, watchlistDiscordWebhook, sizeof(watchlistDiscordWebhook));
        }
        case ALERT_REMOVED:
        {
            if (!GetConVarBool(g_watchlist_notify_removed_enabled)) {
                // Do nothing and return
                delete webhook;
                return Plugin_Handled;
            }
            // Title
            strcopy(watchlistDiscordTitle, sizeof(watchlistDiscordTitle), "[Player Watchlist] Player removed from List");
            // Content
            GetConVarString(g_watchlist_notify_removed_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
            // Player name isn't given here, so set the player bool to false
            usePlayer = false;
            // IP isnt used
            useIp = false;
            // watched_since isnt used
            useWatchedSince = false;
            // Steam ID
            strcopy(watchlistDiscordFields_steamid, sizeof(watchlistDiscordFields_steamid), steamid);
            // Profile link
            char watchlistSteamid64[32];
            strcopy(watchlistDiscordFields_profile, sizeof(watchlistDiscordFields_profile), COMMUNITY_URL);
            SteamIDToCommunityID(watchlistSteamid64, sizeof(watchlistSteamid64), steamid);
            ReplaceString(watchlistDiscordFields_profile, sizeof(watchlistDiscordFields_profile), "{STEAMID64}", watchlistSteamid64);
            // Admin
            strcopy(watchlistDiscordFields_watched_by, sizeof(watchlistDiscordFields_watched_by), watched_by);
            // Reason wont exist
            useReason = false;

            // Color
            notification.SetColor(GetConVarInt(g_watchlist_notify_removed_color));

            // mention
            GetConVarString(g_watchlist_notify_removed_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
            webhook.SetContent(watchlistDiscordContent);

            // Webhook
            GetConVarString(g_watchlist_notify_removed_webhook, watchlistDiscordWebhook, sizeof(watchlistDiscordWebhook));
        }
        case ALERT_CLEARED:
        {
            if (!GetConVarBool(g_watchlist_notify_cleared_enabled)) {
                // Do nothing and return
                delete webhook;
                return Plugin_Handled;
            }
            // Title
            strcopy(watchlistDiscordTitle, sizeof(watchlistDiscordTitle), "[Player Watchlist] Watchlist cleared!");
            // Content
            GetConVarString(g_watchlist_notify_cleared_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
            // Player name isn't given here, so set the player bool to false
            usePlayer = false;
            // IP isnt used
            useIp = false;
            // watched_since isnt used
            useWatchedSince = false;
            // Steam ID wont exist
            useSteamId = false;
            // Profile link wont exist
            useProfile = false;
            // Admin
            strcopy(watchlistDiscordFields_watched_by, sizeof(watchlistDiscordFields_watched_by), watched_by);
            // Reason wont exist
            useReason = false;

            // Color
            notification.SetColor(GetConVarInt(g_watchlist_notify_cleared_color));

            // mention
            GetConVarString(g_watchlist_notify_cleared_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
            webhook.SetContent(watchlistDiscordContent);

            // Webhook
            GetConVarString(g_watchlist_notify_cleared_webhook, watchlistDiscordWebhook, sizeof(watchlistDiscordWebhook));
        }
        default:
        {
            // Title
            strcopy(watchlistDiscordTitle, sizeof(watchlistDiscordTitle), "[Player Watchlist] Unknown Alert Type -- this shouldn't happen");
            // Description
            strcopy(watchlistDiscordDescription, sizeof(watchlistDiscordDescription), "If you encountered this, please report it to the developer, and tell them how you did it.");
            usePlayer = false;
            useIp = false;
            useWatchedSince = false;
            useSteamId = false;
            useProfile = false;
            useReason = false;
            useWatchedBy = false;
        }
    }
    // Our buffers are full, lets build the embed
    notification.SetTitle(watchlistDiscordTitle);
    notification.SetDescription(watchlistDiscordDescription);
    if (usePlayer)
    {
        EmbedField fieldPlayer = new EmbedField("Player", watchlistDiscordFields_player, true);
        notification.AddField(fieldPlayer);
    }
    if (useServer)
    {
        GetClientName(0, watchlistDiscordFields_server, sizeof(watchlistDiscordFields_server));
        EmbedField fieldServer = new EmbedField("Server", watchlistDiscordFields_server, true);
        notification.AddField(fieldServer);
    }
    if (useSteamId)
    {
        EmbedField fieldSteamId = new EmbedField("Steam ID", watchlistDiscordFields_steamid, true);
        notification.AddField(fieldSteamId);
    }
    if (useProfile)
    {
        EmbedField fieldProfile = new EmbedField("Profile", watchlistDiscordFields_profile, true);
        notification.AddField(fieldProfile);
    }
    if (useIp)
    {
        EmbedField fieldIp = new EmbedField("IP", watchlistDiscordFields_ip, true);
        notification.AddField(fieldIp);
    }
    if (useWatchedSince)
    {
        EmbedField fieldWatchedSince = new EmbedField("Watched Since", watchlistDiscordFields_watched_since, true);
        notification.AddField(fieldWatchedSince);
    }
    if (useWatchedBy)
    {
        EmbedField fieldWatchedBy = new EmbedField("Watched By", watchlistDiscordFields_watched_by, true);
        notification.AddField(fieldWatchedBy);
    }
    if (useReason)
    {
        EmbedField fieldReason = new EmbedField("Reason", watchlistDiscordFields_reason, true);
        notification.AddField(fieldReason);
    }

    if (strcmp(watchlistDiscordWebhook, "") == 0)
    {
        // Fallback webhook
        GetConVarString(g_watchlist_fallback_webhook, watchlistDiscordWebhook, sizeof(watchlistDiscordWebhook));
    }
    if (strcmp(watchlistDiscordContent, "") == 0) {
        // Fallback content
        GetConVarString(g_watchlist_fallback_mention, watchlistDiscordContent, sizeof(watchlistDiscordContent));
    }
    webhook.AddEmbed(notification);
    // Time to send the notification
    char szWebhookUrl[1000];
    bool webhookfound = GetWebHook(watchlistDiscordWebhook, szWebhookUrl, sizeof(szWebhookUrl));
    if (!webhookfound)
    {
        // Webhook not found, fallback to default
        GetConVarString(g_watchlist_fallback_webhook, watchlistDiscordWebhook, sizeof(watchlistDiscordWebhook));
        webhookfound = GetWebHook(watchlistDiscordWebhook, szWebhookUrl, sizeof(szWebhookUrl));
        if (!webhookfound)
        {
            // Fallback not found, scream
            PrintToServer("Something went wrong with the webhook - check sourcemod/configs/discord.cfg!");
            return Plugin_Handled;
        }
    }

    DataPack pack = new DataPack();

    webhook.Execute(szWebhookUrl, Watchlist_Webhook_Callback, pack);
    delete webhook;

    return Plugin_Continue;
}