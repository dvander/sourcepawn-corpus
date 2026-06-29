/*
Changelog:

Version 1.1:
- Added an in-game menu (sm_playtime_menu) for displaying player playtime.
- Improved database query efficiency.
- Enhanced plugin description and admin command documentation.

Version 1.0:
- Initial release.
- Tracks and stores players total playtime, SteamID, and nickname in an SQLite database.
- Provides the sm_playtime_check command to query individual player data.
*/


#include <sourcemod>

public Plugin myinfo = {
    name = "[AMD] Playtime Tracker",
    author = "Amodd",
    description = "Tracks and stores players total playtime on the server in an SQLite",
    version = "1.1"
};

Handle g_hDB = null;
int g_JoinTime[MAXPLAYERS + 1];

public void OnPluginStart()
{
    InitDB();

    // Usage: sm_playtime_check <SteamID>
    // Description: Retrieves the total playtime and nickname of a player by SteamID and prints it to the admin's console.
    RegAdminCmd("sm_playtime_check", Command_PlaytimeCheck, ADMFLAG_GENERIC);

    // Usage: sm_playtime_menu
    // Description: Opens an in-game menu displaying players sorted by total playtime.
    RegAdminCmd("sm_playtime_menu", Command_PlaytimeMenu, ADMFLAG_GENERIC);
}

public void InitDB()
{
    char error[255];
    g_hDB = SQLite_UseDatabase("playtime_tracker", error, sizeof(error));

    if (g_hDB == null)
    {
        SetFailState("SQL error: %s", error);
    }

    SQL_LockDatabase(g_hDB);
    SQL_FastQuery(g_hDB, "VACUUM");
    SQL_FastQuery(g_hDB, "CREATE TABLE IF NOT EXISTS playtime_tracker (steamid TEXT PRIMARY KEY, nickname TEXT, total_playtime INTEGER); ");
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
    if (!GetClientAuthId(client, AuthId_Steam2, steamId, sizeof(steamId)))
    {
        LogError("Failed to retrieve SteamID for client %d. Skipping database entry.", client);
        return;
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
    Format(query, sizeof(query), "INSERT INTO playtime_tracker (steamid, nickname, total_playtime) VALUES ('%s', '%s', %d) ON CONFLICT(steamid) DO UPDATE SET nickname = '%s', total_playtime = total_playtime + %d;", steamId, nickName, playTime, nickName, playTime);

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
    Format(query, sizeof(query), "SELECT nickname, total_playtime FROM playtime_tracker WHERE steamid = '%s';", steamId);

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
    PrintToConsole(client, "Time Played: %d days, %d hours, %d minutes, %d seconds", days, hours, minutes, seconds);

    return Plugin_Handled;
}

public Action Command_PlaytimeMenu(int client, int args)
{
    if (g_hDB == null)
    {
        PrintToConsole(client, "Database handle is invalid.");
        return Plugin_Handled;
    }

    Handle hQuery = SQL_Query(g_hDB, "SELECT nickname, total_playtime FROM playtime_tracker ORDER BY total_playtime DESC;");

    if (hQuery == null)
    {
        PrintToConsole(client, "Error executing query.");
        return Plugin_Handled;
    }

    Menu menu = CreateMenu(MenuHandler_PlaytimeMenu);
    SetMenuTitle(menu, "Top Playtime List");
    SetMenuExitButton(menu, true);
    SetMenuPagination(menu, true);

    while (SQL_FetchRow(hQuery))
    {
        char nickName[64];
        int totalPlaytime;

        SQL_FetchString(hQuery, 0, nickName, sizeof(nickName));
        totalPlaytime = SQL_FetchInt(hQuery, 1);

        int days = totalPlaytime / 86400;
        int hours = (totalPlaytime % 86400) / 3600;
        int minutes = (totalPlaytime % 3600) / 60;

        char display[128];
        Format(display, sizeof(display), "%s - %d days, %d hours, %d minutes", nickName, days, hours, minutes);
        AddMenuItem(menu, nickName, display);
    }

    CloseHandle(hQuery);
    DisplayMenu(menu, client, 60);
    return Plugin_Handled;
}

public int MenuHandler_PlaytimeMenu(Menu menu, MenuAction action, int param1, int param2)
{
    if (action == MenuAction_Select)
    {
        int client = param1;
        char info[64];
        GetMenuItem(menu, param2, info, sizeof(info));
        PrintToConsole(client, "You selected: %s", info);
    }
    else if (action == MenuAction_End)
    {
        CloseHandle(menu);
    }

    return 0;
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
