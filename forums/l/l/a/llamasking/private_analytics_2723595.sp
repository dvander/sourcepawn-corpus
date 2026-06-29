/**
 * ======================================================================
 * Private Analytics
 * Copyright (C) 2020-2022 llamasking
 * ======================================================================
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, as per version 3 of the license.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program.  If not, see <https://www.gnu.org/licenses/>.
 */

/* -- Data Logging --
When a player joins, the 'player_analytics' table is updated with the following.
- Server IP
- Timestamp
- Total Player Count
- Current Map
- Player's Country
- If the player blocks HTML MOTDs (only stored if this option is enabled and the player is successful queried, otherwise NULL)

When a player EITHER joins OR leaves, the 'player_count' table is updated with the following.
- Server IP
- Timestamp
- Total Player Count
- Current Map
*/

// This plugin is made to fit my needs. If it does not fit yours, that is not my problem.

#pragma semicolon 1
#pragma newdecls required

#include <geoip>
#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <updater>

//#define DEBUG
#define VERSION    "1.0.2"
#define UPDATE_URL "https://raw.githubusercontent.com/llamasking/sourcemod-plugins/master/Plugins/private_analytics/updatefile.txt"
public Plugin myinfo =
{
    name        = "Private Analytics",
    author      = "llamasking",
    description = "An alternative to Dr. McKay's Player Analytics that logs much less identifiable information.",
    version     = VERSION,
    url         = "https://github.com/llamasking/sourcemod-plugins"


}

/* ConVars */
ConVar g_html;

/* Database */
Database g_db = null;

/* Etc */
char g_ip[32];
char g_map[64];

public void OnPluginStart()
{
    // ConVars
    g_html = CreateConVar("sm_analytics_html", "0", "Whether or not the plugin logs if HTML motds are on or off.", _, true, 0.0, true, 1.0);
    CreateConVar("sm_analytics_version", VERSION, "Plugin version.", FCVAR_NOTIFY | FCVAR_DONTRECORD);

    AutoExecConfig();

    if (!SQL_CheckConfig("priv_analytics"))
        SetFailState("Database 'priv_analytics' not found in databases.cfg!");

    // Get server ip and store it globally so that it doesn't have to be redetermined each time someone connects.
    int ip = GetConVarInt(FindConVar("hostip"));
    Format(g_ip, sizeof(g_ip), "%d.%d.%d.%d:%d", ((ip & 0xFF000000) >> 24) & 0xFF, ((ip & 0x00FF0000) >> 16) & 0xFF, ((ip & 0x0000FF00) >> 8) & 0xFF, ((ip & 0x000000FF) >> 0) & 0xFF, GetConVarInt(FindConVar("hostport")));

    // Get map
    GetCurrentMap(g_map, sizeof(g_map));
    GetMapDisplayName(g_map, g_map, sizeof(g_map));

    // Create tables if it doesn't already exist.
    Database.Connect(ConnectCallback, "priv_analytics");

// Updater
#if !defined DEBUG
    if (LibraryExists("updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
#endif
}

/* Updater */
#if !defined DEBUG

public void OnLibraryAdded(const char[] name)
{
    if (StrEqual(name, "updater"))
    {
        Updater_AddPlugin(UPDATE_URL);
    }
}

#endif

/* Connect and Disconnect */
public void OnClientPutInServer(int client)
{
    if (GetConVarBool(g_html))
    {
        QueryClientConVar(client, "cl_disablehtmlmotd", QueryCallback);
    }
    else
    {
        InsertConnection(client, "", true);
    }
}

public void OnClientDisconnect_Post(int client)
{
    UpdatePlayerCount();
}

/* Functions */
void InsertConnection(int client, const char[] htmlStatus, bool nullHtml = false)
{
    // Ignore fake clients and those that managed to leave before the query finished.
    if (!IsClientConnected(client) || IsFakeClient(client))
        return;

    // Get country
    char client_ip[16];
    char country[64];
    char country_code[3];
    char country_code3[4];
    GetClientIP(client, client_ip, sizeof(client_ip));
    GeoipCountry(client_ip, country, sizeof(country));
    GeoipCode2(client_ip, country_code);
    GeoipCode3(client_ip, country_code3);

    // Determine HTML status
    // Assume it is blocked unless the convar explicitly returns "0".
    // Status is NULL if the feature is disabled or convar query failed.
    char html[5] = "1";
    if (nullHtml)
        strcopy(html, sizeof(html), "NULL");
    else if (StrEqual(htmlStatus, "0"))
        strcopy(html, sizeof(html), "0");

    // Query
    char query[512];
    g_db.Format(query, sizeof(query), "INSERT INTO `player_analytics` SET server_ip = '%s', connect_time = '%i', numplayers = '%i', map = '%s', country = '%s', country_code = '%s', country_code3 = '%s', html_motd_disabled = %s;",
                g_ip, GetTime(), GetPlayerCount(), g_map, country, country_code, country_code3, html);

#if defined DEBUG
    LogMessage("%s", query);
#else
    g_db.Query(SQLCallback, query);
#endif

    // Update player count table as well.
    UpdatePlayerCount();
}

public void UpdatePlayerCount()
{
    // Query
    char query[512];
    g_db.Format(query, sizeof(query), "INSERT INTO `player_count` SET server_ip = '%s', time = '%i', numplayers = '%i', map = '%s';",
                g_ip, GetTime(), GetPlayerCount(), g_map);
#if defined DEBUG
    LogMessage("%s", query);
#else
    g_db.Query(SQLCallback, query);
#endif
}

public int GetPlayerCount()
{
    int players = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientConnected(i) && !IsFakeClient(i))
            players++;
    }

    return players;
}

/* Callbacks */
public void ConnectCallback(Database db, const char[] error, any data)
{
    if (db == null)
        SetFailState("Could not connect to database: %s", error);

    g_db = db;

    // Create table if it doesn't already exist.
    g_db.Query(SQLCallback, "CREATE TABLE IF NOT EXISTS `player_analytics` (`id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,`server_ip` varchar(32) NOT NULL,`connect_time` int NOT NULL,`numplayers` tinyint NOT NULL,`map` varchar(64) NOT NULL,`country` varchar(64) NULL,`country_code` varchar(2) NULL,`country_code3` varchar(3) NULL,`html_motd_disabled` tinyint(1) NULL)");
    g_db.Query(SQLCallback, "CREATE TABLE IF NOT EXISTS `player_count` (`id` int NOT NULL AUTO_INCREMENT PRIMARY KEY,`server_ip` varchar(32) NOT NULL,`time` int NOT NULL,`numplayers` tinyint NOT NULL,`map` varchar(64) NOT NULL)");
}

public void SQLCallback(Database db, DBResultSet results, const char[] error, any data)
{
    // Checks if there is an error (non-empty string)
    if (error[0])
        LogError(error);
}

public void QueryCallback(QueryCookie cookie, int client, ConVarQueryResult result, const char[] cvarName, const char[] cvarValue)
{
    // If query failed, send NULL
    if (result == ConVarQuery_Okay)
    {
        InsertConnection(client, cvarValue);
    }
    else if (result != ConVarQuery_Cancelled)
    {
        InsertConnection(client, "", true);
    }
}
