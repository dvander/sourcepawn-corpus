#include <sourcemod>

public Plugin myinfo = {
    name = "Player Tracker",
    author = "Amodd",
    description = "Saves player SteamID, nickname, and total playtime to SQLite",
    version = "1.0"
};

Handle g_hDB = null;
int g_JoinTime[MAXPLAYERS + 1];

public void OnPluginStart()
{
    InitDB();
    RegAdminCmd("sm_playtime_check", Command_PlaytimeCheck, ADMFLAG_GENERIC);
}

public void InitDB()
{
    char error[255];
    g_hDB = SQLite_UseDatabase("player_tracker", error, sizeof(error));

    if (g_hDB == null)
    {
        SetFailState("SQL error: %s", error);
    }

    SQL_LockDatabase(g_hDB);
    SQL_FastQuery(g_hDB, "VACUUM");
    SQL_FastQuery(g_hDB, "CREATE TABLE IF NOT EXISTS player_tracker (steamid TEXT PRIMARY KEY, nickname TEXT, total_playtime INTEGER); ");
    SQL_UnlockDatabase(g_hDB);
}

public void OnClientPostAdminCheck(int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
    {
        return;
    }

    char steamId[32];
    GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId));

    char nickName[64];
    GetClientName(client, nickName, sizeof(nickName));

    g_JoinTime[client] = GetTime();
}

public void OnClientDisconnect(int client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
    {
        return;
    }

    char steamId[32];
    char nickName[64];
    // Check if a valid SteamID can be retrieved
    if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
    {
        LogError("Failed to retrieve SteamID for client %d. Skipping database entry.", client);
        return; // Skip saving to the database
    }
    GetClientName(client, nickName, sizeof(nickName));

    int joinTime = g_JoinTime[client];
    int currentTime = GetTime();
    int playTime = currentTime - joinTime;

    UpdatePlayerData(steamId, nickName, playTime);
}

void UpdatePlayerData(const char[] steamId, const char[] nickName, int playTime)
{
    if (g_hDB == null)
    {
        LogError("Database handle is invalid.");
        return;
    }

    char query[512];
    Format(query, sizeof(query), "INSERT INTO player_tracker (steamid, nickname, total_playtime) VALUES ('%s', '%s', %d) ON CONFLICT(steamid) DO UPDATE SET nickname = '%s', total_playtime = total_playtime + %d;", steamId, nickName, playTime, nickName, playTime);

    SQL_LockDatabase(g_hDB);
    SQL_FastQuery(g_hDB, query);
    SQL_UnlockDatabase(g_hDB);
}

public Action Command_PlaytimeCheck(int client, int args)
{
    if (args != 1)
    {
        PrintToConsole(client, "Usage: sm_playtime_check <SteamID>");
        return Plugin_Handled;
    }

    char steamId[32];
    GetCmdArg(1, steamId, sizeof(steamId));

    if (g_hDB == null)
    {
        PrintToConsole(client, "Database handle is invalid.");
        return Plugin_Handled;
    }

    char query[256];
    Format(query, sizeof(query), "SELECT nickname, total_playtime FROM player_tracker WHERE steamid = '%s';", steamId);

    Handle hQuery = SQL_Query(g_hDB, query);

    if (hQuery == null)
    {
        PrintToConsole(client, "Error executing query: %s", g_hDB);
        return Plugin_Handled;
    }

    if (SQL_GetRowCount(hQuery) == 0)
    {
        PrintToConsole(client, "No data found for the provided SteamID.");
        return Plugin_Handled;
    }

    char nickName[64];
    int totalPlaytime;

    SQL_FetchRow(hQuery);
    SQL_FetchString(hQuery, 0, nickName, sizeof(nickName));
    totalPlaytime = SQL_FetchInt(hQuery, 1);

    int days = totalPlaytime / 86400;
    int hours = (totalPlaytime % 86400) / 3600;
    int minutes = (totalPlaytime % 3600) / 60;
    int seconds = totalPlaytime % 60;

    PrintToConsole(client, "SteamID: %s", steamId);
    PrintToConsole(client, "Nickname: %s", nickName);
    PrintToConsole(client, "Total Playtime: %d days, %d hours, %d minutes, %d seconds", days, hours, minutes, seconds);

    return Plugin_Handled;
}

public void OnPluginUnload()
{
    if (g_hDB != null)
    {
        SQL_LockDatabase(g_hDB);
        SQL_FastQuery(g_hDB, "VACUUM");
        SQL_UnlockDatabase(g_hDB);

        delete g_hDB;
    }
}
