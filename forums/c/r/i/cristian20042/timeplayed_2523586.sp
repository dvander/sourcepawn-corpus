#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define CHAT_PREFIX "[SM]"
#define PLUGIN_VERSION "2.0.1"

Handle g_DB = INVALID_HANDLE;
char g_Error[PLATFORM_MAX_PATH];
char g_Query[PLATFORM_MAX_PATH];
char g_sUserSteamId[MAXPLAYERS+1][PLATFORM_MAX_PATH];

Handle ClientTimer[MAXPLAYERS+1];
int Minutes[MAXPLAYERS+1];

public Plugin myinfo = {
    name = "Played Time",
    author = "SniperHero / cristian20042",
    description = "It's showing the played time on the server.",
    version = PLUGIN_VERSION,
    url = "https://forums.alliedmods.net/showthread.php?p=2523586"
}; 

public void OnPluginStart() 
{ 
    CreateConVar("sm_playtime_version", PLUGIN_VERSION, "Plugin version"); 
    RegConsoleCmd("sm_time", Command_showTime, "Shows your played time."); 
    RegConsoleCmd("sm_playedtime", Command_showTime, "Shows your played time."); 
    RegConsoleCmd("sm_hours", Command_showTime, "Shows your played time."); 
    RegAdminCmd("sm_gettime", Command_getTime, ADMFLAG_SLAY, "Gets a player's played time."); 

    if(g_DB == INVALID_HANDLE) 
        g_DB = SQL_Connect ("default", false, g_Error, sizeof (g_Error)); 

    if(g_DB == INVALID_HANDLE) 
    { 
        SetFailState ("Can't reach the database."); 
        return; 
    } 

    FormatEx (g_Query, sizeof (g_Query), "CREATE TABLE IF NOT EXISTS PlayTime (SteamID varchar(128) PRIMARY KEY, mins int(11) DEFAULT 0);"); 
    SQL_Query (g_DB, g_Query); 

    SQL_SetCharset (g_DB, "utf8"); 
} 

public void OnClientPutInServer(int client) 
{ 
    if (IsValidClient(client)) 
    { 
        if(!GetClientAuthId(client, AuthId_Engine, g_sUserSteamId[client], sizeof(g_sUserSteamId), true)) //always check for valid return 
            return; 

        FormatEx (g_Query, sizeof (g_Query), "SELECT mins FROM PlayTime WHERE SteamID = '%s' LIMIT 1;", g_sUserSteamId [ client ]); 
        SQL_TQuery (g_DB, LoadPlayerData, g_Query, client); 
    } 

    ClientTimer[client] = (CreateTimer(60.0, TimerAdd, client, TIMER_REPEAT)); 
} 

void LoadPlayerData (Handle pDb, Handle pQuery, char[] Error, any Data) 
{ 
    static int Id, RowsCount; 

    RowsCount = 0; 
    Id = view_as<int>(Data); 

    if (strlen(Error) > 0) 
        LogError("SQL_TQuery() @ LoadPlayerData() reported: %s", Error); 

    else if (IsValidClient(Id)) 
    { 
         
        if (SQL_HasResultSet(pQuery)) 
            RowsCount = SQL_HasResultSet(pQuery) ? SQL_GetRowCount(pQuery) : 0; 

        switch (RowsCount) 
        { 
            case 0: 
            { 
                FormatEx (g_Query, sizeof (g_Query), "INSERT INTO `PlayTime`(`SteamID`) VALUES ('%s')", g_sUserSteamId [ Id ]); 
                SQL_Query (g_DB, g_Query); 
            } 

            default: 
            { 
                SQL_FetchRow (pQuery); 

                Minutes[Id] = SQL_FetchInt (pQuery, 0); 
            } 
        } 
        CloseHandle (pDb); 
    } 
} 

public void OnClientDisconnect(int client) 
{ 
    CloseHandle(ClientTimer[client]); 
    SaveTime(client); 
} 

public Action TimerAdd(Handle timer, int client) 
{ 
    if(IsClientConnected(client) && IsClientInGame(client)) 
    { 
        Minutes[client]++; 
        SaveTime(client); 
    } 
} 

public Action Command_showTime(int client, int args) 
{ 
    static char totalTime[PLATFORM_MAX_PATH]; 

    FormatEx (g_Query, sizeof (g_Query), "SELECT mins FROM PlayTime WHERE SteamID = '%s' LIMIT 1;", g_sUserSteamId [ client ]); 
    SQL_TQuery (g_DB, LoadPlayerData, g_Query, client); 

    SniperH_GetTimeStringMinutes(Minutes[client], totalTime, sizeof(totalTime)); 
    PrintToChat(client, "\x04%s \x01Played Time: \x04%s\x01.", CHAT_PREFIX, totalTime); 
    return Plugin_Handled;  
} 

public Action Command_getTime(int client, int args) 
{ 
    if (args < 1) 
    { 
        PrintToChat(client, "%s Usage: \x04!gettime \x02<target>", CHAT_PREFIX); 
        return Plugin_Handled; 
    } 

    char szTarget[64]; 
    GetCmdArg(1, szTarget, sizeof(szTarget)); 

    int target = FindTarget(client, szTarget, true, false); 

    static char totalTime[PLATFORM_MAX_PATH]; 

    FormatEx (g_Query, sizeof (g_Query), "SELECT mins FROM PlayTime WHERE SteamID = '%s' LIMIT 1;", g_sUserSteamId [ client ]); 
    SQL_TQuery (g_DB, LoadPlayerData, g_Query, target); 

    SniperH_GetTimeStringMinutes(Minutes[target], totalTime, sizeof(totalTime)); 
    PrintToChat(client, "\x04%s \x01This player played: \x04%s\x01.", CHAT_PREFIX, totalTime); 
    return Plugin_Handled;  
} 

void SaveTime(int client) 
{ 
    FormatEx (g_Query, sizeof (g_Query), "UPDATE `PlayTime` SET `mins` = '%d' WHERE `SteamID` = '%s'", Minutes[client], g_sUserSteamId [ client ]); 
    SQL_Query (g_DB, g_Query); 
} 

/* Fancy Stuff * Do NOT touch unless you know what you are doing! */ 

int SniperH_GetTimeStringMinutes(int Mins, char[] Output, int Size) 
{ 
    static int m_Hours, m_Mins; 

    m_Hours = 0; 
    m_Mins = SniperH_AbsInt(Mins); 

    if (m_Mins == 0) 
        return FormatEx(Output, Size, "0 minutes"); 

    while (m_Mins >= 60) 
    { 
        m_Hours++; 

        m_Mins -= 60; 
    } 

    if (m_Hours > 0) 
    { 
        if (m_Mins > 0) 
            return FormatEx(Output, Size, "%d hours %d minutes", m_Hours, m_Mins); 

        return FormatEx(Output, Size, "%d hours", m_Hours); 
    } 

    return FormatEx(Output, Size, "%d minutes", m_Mins); 
} 

int SniperH_AbsInt(int Value = 0) 
{ 
    return Value >= 0 ? Value : -Value; 
} 

bool IsValidClient(int client) 
{ 
    if (!(1 <= client <= MaxClients) || !IsClientInGame (client) || IsFakeClient(client)) 
        return false; 

    return true; 
}  