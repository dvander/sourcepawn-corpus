// SPDX-License-Identifier: GPL-3.0-only
/**
 *
 * Copyright 2011 - 2026 steamcommunity.com/profiles/76561198025355822/
 * native int HxGetClientPoints(int client); // Получить поинты игрока
 * native int HxGetAverageSkill(); // Получить усредненные skill команды
 * Статистика игроков.
 *
 */

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

#define HX_POINTS       0
#define HX_TIME         1
#define HX_BOOMER       2
#define HX_CHARGER      3
#define HX_HUNTER       4
#define HX_INFECTED     5
#define HX_JOCKEY       6
#define HX_SMOKER       7
#define HX_SPITTER      8
#define HX_TANK         9
#define HX_WITCH        10

#define HX_32_SIZE      32
#define HX_64_SIZE      64
#define HX_128_SIZE     128
#define HX_1024_SIZE    1024

#define HX_CREATE_TABLE "\
CREATE TABLE IF NOT EXISTS l4d2_stats (\
 Steamid TEXT NOT NULL,\
 Name BLOB NOT NULL,\
 Points INTEGER NOT NULL DEFAULT 0,\
 Time1 INTEGER NOT NULL DEFAULT 0,\
 Time2 INTEGER NOT NULL DEFAULT 0,\
 Boomer INTEGER NOT NULL DEFAULT 0,\
 Charger INTEGER NOT NULL DEFAULT 0,\
 Hunter INTEGER NOT NULL DEFAULT 0,\
 Infected INTEGER NOT NULL DEFAULT 0,\
 Jockey INTEGER NOT NULL DEFAULT 0,\
 Smoker INTEGER NOT NULL DEFAULT 0,\
 Spitter INTEGER NOT NULL DEFAULT 0,\
 Tank INTEGER NOT NULL DEFAULT 0,\
 Witch INTEGER NOT NULL DEFAULT 0,\
 PRIMARY KEY (Steamid)\
);\
"

char sg_query1[HX_1024_SIZE];
char sg_query2[HX_1024_SIZE];
char sg_query3[HX_1024_SIZE];
char sg_query4[HX_1024_SIZE];

char sg_buf1[HX_1024_SIZE];
char sg_buf2[HX_128_SIZE];
char sg_buf3[HX_128_SIZE];

int ig_temp[MAXPLAYERS + 1][16];
int ig_real[MAXPLAYERS + 1][16];
int ig_average_skill;

Database hg_db;

public Plugin myinfo =
{
    name        = "[L4D2] hx_stats",
    author      = "MAKS",
    description = "L4D2 Coop Stats",
    version     = "1.6 SQLite",
    url         = "https://forums.alliedmods.net/showthread.php?t=298535"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    CreateNative("HxGetClientPoints", __HxGetPoints);
    CreateNative("HxGetAverageSkill", __HxGetSkill);
    return APLRes_Success;
}

public void OnPluginStart()
{
    HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("defibrillator_used", Event_DefibrillatorUsed);
    HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
    HookEvent("map_transition", Event_SQL_Save, EventHookMode_PostNoCopy);
    HookEvent("finale_win", Event_SQL_Save, EventHookMode_PostNoCopy);

    RegConsoleCmd("go_away_from_keyboard", CMD_keyboard, "", 0);
    RegConsoleCmd("callvote", CMD_callvote, "", 0);
    RegConsoleCmd("sm_rank", CMD_rank, "", 0);
    RegConsoleCmd("sm_top", CMD_top, "", 0);

    CreateTimer(60.0, HxTimerInfinite18, _, TIMER_REPEAT);
    hg_db = null;
}

public void HxDBvoid(Handle owner, Handle hndl, const char[] error, any data)
{
    if (!hndl)
    {
        LogError("SQL Error: %s", error);
    }
}

public void OnConfigsExecuted()
{
    ig_average_skill = 1;

    if (hg_db)
    {
        delete hg_db;
    }

    hg_db = SQLite_UseDatabase("l4d2_stats", sg_buf2, sizeof(sg_buf2) - 1);

    if (!hg_db)
    {
        LogError("Failed to connect to database 'l4d2_stats'. Error: %s", sg_buf2);
    }
    else
    {
        SQL_TQuery(hg_db, HxDBvoid, HX_CREATE_TABLE, 0, DBPrio_High);
    }
}

void HxClean(int client)
{
    ig_temp[client][HX_POINTS]   = 0;
    ig_temp[client][HX_TIME]     = 0;
    ig_temp[client][HX_BOOMER]   = 0;
    ig_temp[client][HX_CHARGER]  = 0;
    ig_temp[client][HX_HUNTER]   = 0;
    ig_temp[client][HX_INFECTED] = 0;
    ig_temp[client][HX_JOCKEY]   = 0;
    ig_temp[client][HX_SMOKER]   = 0;
    ig_temp[client][HX_SPITTER]  = 0;
    ig_temp[client][HX_TANK]     = 0;
    ig_temp[client][HX_WITCH]    = 0;

    ig_real[client][HX_POINTS]   = 0;
    ig_real[client][HX_TIME]     = 0;
    ig_real[client][HX_BOOMER]   = 0;
    ig_real[client][HX_CHARGER]  = 0;
    ig_real[client][HX_HUNTER]   = 0;
    ig_real[client][HX_INFECTED] = 0;
    ig_real[client][HX_JOCKEY]   = 0;
    ig_real[client][HX_SMOKER]   = 0;
    ig_real[client][HX_SPITTER]  = 0;
    ig_real[client][HX_TANK]     = 0;
    ig_real[client][HX_WITCH]    = 0;
}

public int __HxGetPoints(Handle plugin, int numParams)
{
    int client = GetNativeCell(1);

    if (client > 0)
    {
        if (client <= MaxClients)
        {
            return ig_real[client][HX_POINTS];
        }
    }

    return 0;
}

public int __HxGetSkill(Handle plugin, int numParams)
{
    return ig_average_skill;
}

public Action HxTimerConnected(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);
    CMD_rank(client, 0);
    return Plugin_Stop;
}

public void HxSQLregisterClient(Handle owner, Handle hndl, const char[] error, any data)
{
    int client = GetClientOfUserId(data);

    if (client > 0)
    {
        if (IsClientInGame(client))
        {
            if (hndl)
            {
                if (SQL_FetchRow(hndl))
                {
                    ig_real[client][HX_POINTS]   = SQL_FetchInt(hndl, 0);
                    ig_real[client][HX_TIME]     = SQL_FetchInt(hndl, 1);
                    ig_real[client][HX_BOOMER]   = SQL_FetchInt(hndl, 2);
                    ig_real[client][HX_CHARGER]  = SQL_FetchInt(hndl, 3);
                    ig_real[client][HX_HUNTER]   = SQL_FetchInt(hndl, 4);
                    ig_real[client][HX_INFECTED] = SQL_FetchInt(hndl, 5);
                    ig_real[client][HX_JOCKEY]   = SQL_FetchInt(hndl, 6);
                    ig_real[client][HX_SMOKER]   = SQL_FetchInt(hndl, 7);
                    ig_real[client][HX_SPITTER]  = SQL_FetchInt(hndl, 8);
                    ig_real[client][HX_TANK]     = SQL_FetchInt(hndl, 9);
                    ig_real[client][HX_WITCH]    = SQL_FetchInt(hndl, 10);

                    CreateTimer(7.0, HxTimerConnected, data, TIMER_FLAG_NO_MAPCHANGE);
                }
                else
                {
                    if (hg_db)
                    {
                        char sTeamID[HX_32_SIZE];
                        GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID) - 1);

                        sg_query1[0] = '\0';
                        Format(sg_query1, sizeof(sg_query1) - 1, "INSERT OR IGNORE INTO l4d2_stats (Steamid, Name) VALUES ('%s', '');", sTeamID);
                        SQL_TQuery(hg_db, HxDBvoid, sg_query1, 0, DBPrio_Low);
                    }
                }
            }
        }
    }
}

public Action HxTimerClientPost(Handle timer, any userid)
{
    int client = GetClientOfUserId(userid);

    if (client > 0)
    {
        if (IsClientInGame(client))
        {
            if (hg_db)
            {
                char sTeamID[HX_32_SIZE];
                GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID) - 1);

                sg_query1[0] = '\0';
                Format(sg_query1, sizeof(sg_query1) - 1, "SELECT \
 Points, \
 Time1, \
 Boomer, \
 Charger, \
 Hunter, \
 Infected, \
 Jockey, \
 Smoker, \
 Spitter, \
 Tank, \
 Witch \
 FROM l4d2_stats WHERE Steamid = '%s';",
                       sTeamID);

                SQL_TQuery(hg_db, HxSQLregisterClient, sg_query1, userid, DBPrio_High);
            }
        }
    }

    return Plugin_Stop;
}

public void OnClientPostAdminCheck(int client)
{
    if (!IsFakeClient(client))
    {
        HxClean(client);
        CreateTimer(0.5, HxTimerClientPost, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
    }
}

public void OnClientDisconnect(int client)
{
    if (!IsFakeClient(client))
    {
        if (ig_temp[client][HX_INFECTED])
        {
            if (hg_db)
            {
                char sTeamID[HX_32_SIZE];
                GetClientAuthId(client, AuthId_Steam2, sTeamID, sizeof(sTeamID) - 1);

                sg_query2[0] = '\0';
                Format(sg_query2, sizeof(sg_query2) - 1, "UPDATE l4d2_stats SET \
 Time1 = Time1 + %d, \
 Time2 = %d, \
 Boomer = Boomer + %d, \
 Charger = Charger + %d, \
 Hunter = Hunter + %d, \
 Infected = Infected + %d, \
 Jockey = Jockey + %d, \
 Smoker = Smoker + %d, \
 Spitter = Spitter + %d, \
 Tank = Tank + %d, \
 Witch = Witch + %d \
 WHERE Steamid = '%s';"
                       , ig_temp[client][HX_TIME]
                       , GetTime()
                       , ig_temp[client][HX_BOOMER]
                       , ig_temp[client][HX_CHARGER]
                       , ig_temp[client][HX_HUNTER]
                       , ig_temp[client][HX_INFECTED]
                       , ig_temp[client][HX_JOCKEY]
                       , ig_temp[client][HX_SMOKER]
                       , ig_temp[client][HX_SPITTER]
                       , ig_temp[client][HX_TANK]
                       , ig_temp[client][HX_WITCH]
                       , sTeamID);

                SQL_TQuery(hg_db, HxDBvoid, sg_query2, 0, DBPrio_Low);
            }
        }

        HxClean(client);
    }
}

int HxColorC(int client, int iPoints)
{
    if (IsPlayerAlive(client))
    {
        if (iPoints > 80000)
        {
            SetEntityRenderColor(client, 0, 0, 0, 252);
            return 10;
        }

        if (iPoints > 50000)
        {
            SetEntityRenderColor(client, 255, 51, 204, 255);
            return 8;
        }

        if (iPoints > 20000)
        {
            SetEntityRenderColor(client, 164, 79, 25, 255);
            return 6;
        }

        if (iPoints > 7000)
        {
            SetEntityRenderColor(client, 0, 153, 51, 255);
            return 5;
        }

        if (iPoints > 2000)
        {
            SetEntityRenderColor(client, 0, 51, 255, 255);
            return 4;
        }

        if (iPoints > 500)
        {
            SetEntityRenderColor(client, 0, 204, 255, 255);
            return 3;
        }
    }

    return 1;
}

public Action HxTimerR_18(Handle timer)
{
    int i = 1;
    int iNum = 0;
    int iPoints = 0;
    int iSkillAll = 0;

    while (i <= MaxClients)
    {
        if (IsClientInGame(i))
        {
            if (!IsFakeClient(i))
            {
                iPoints = ig_real[i][HX_POINTS];
                iSkillAll += HxColorC(i, iPoints);
                iNum += 1;
            }
        }

        i += 1;
    }

    ig_average_skill = 1;

    if (iNum > 0)
    {
        ig_average_skill = iSkillAll / iNum;
    }

    return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    int i = 1;

    while (i <= MaxClients)
    {
        ig_temp[i][HX_POINTS] = 0;
        i += 1;
    }

    CreateTimer(17.0, HxTimerR_18, _, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(40.0, HxTimerR_18, _, TIMER_FLAG_NO_MAPCHANGE);
    CreateTimer(85.0, HxTimerR_18, _, TIMER_FLAG_NO_MAPCHANGE);
}

public void Event_DefibrillatorUsed(Event event, const char[] name, bool dontBroadcast)
{
    int iSubject = GetClientOfUserId(event.GetInt("subject"));

    if (iSubject)
    {
        if (!IsFakeClient(iSubject))
        {
            int iPoints = ig_real[iSubject][HX_POINTS];
            HxColorC(iSubject, iPoints);
        }
    }
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    int iAttacker = GetClientOfUserId(event.GetInt("attacker")); /* User ID который убил */

    if (iAttacker)
    {
        int iUserid = GetClientOfUserId(event.GetInt("userid")); /* User ID который умер */

        if (iAttacker != iUserid)
        {
            if (!IsFakeClient(iAttacker))
            {
                sg_buf3[0] = '\0';
                event.GetString("victimname", sg_buf3, sizeof(sg_buf3) - 1);

                if (sg_buf3[0] == 'I')
                {
                    /* Infected */
                    ig_temp[iAttacker][HX_INFECTED] += 1;
                    return Plugin_Continue;
                }

                if (sg_buf3[0] == 'B')
                {
                    /* Boomer */
                    ig_temp[iAttacker][HX_BOOMER] += 1;
                    ig_temp[iAttacker][HX_POINTS] += 1;
                    PrintToChat(iAttacker, "\x05+1");
                    return Plugin_Continue;
                }

                if (sg_buf3[0] == 'J')
                {
                    /* Jockey */
                    ig_temp[iAttacker][HX_JOCKEY] += 1;
                    ig_temp[iAttacker][HX_POINTS] += 1;
                    PrintToChat(iAttacker, "\x05+1");
                    return Plugin_Continue;
                }

                if (sg_buf3[0] == 'S')
                {
                    if (sg_buf3[1] == 'm')
                    {
                        /* Smoker */
                        ig_temp[iAttacker][HX_SMOKER] += 1;
                    }

                    if (sg_buf3[1] == 'p')
                    {
                        /* Spitter */
                        ig_temp[iAttacker][HX_SPITTER] += 1;
                    }

                    ig_temp[iAttacker][HX_POINTS] += 1;
                    PrintToChat(iAttacker, "\x05+1");
                    return Plugin_Continue;
                }

                if (sg_buf3[0] == 'H')
                {
                    /* Hunter */
                    ig_temp[iAttacker][HX_HUNTER] += 1;
                    ig_temp[iAttacker][HX_POINTS] += 1;
                    PrintToChat(iAttacker, "\x05+1");
                    return Plugin_Continue;
                }

                if (sg_buf3[0] == 'C')
                {
                    /* Charger */
                    ig_temp[iAttacker][HX_CHARGER] += 1;
                    ig_temp[iAttacker][HX_POINTS] += 1;
                    PrintToChat(iAttacker, "\x05+1");
                    return Plugin_Continue;
                }

                if (sg_buf3[0] == 'T')
                {
                    /* Tank */
                    ig_temp[iAttacker][HX_TANK] += 1;
                    ig_temp[iAttacker][HX_POINTS] += 10;
                    PrintToChat(iAttacker, "\x05+10");
                    return Plugin_Continue;
                }

                if (sg_buf3[0] == 'W')
                {
                    /* Witch */
                    ig_temp[iAttacker][HX_WITCH] += 1;
                    ig_temp[iAttacker][HX_POINTS] += 1;
                    PrintToChat(iAttacker, "\x05+1");
                }
            }
        }
    }

    return Plugin_Continue;
}

void HxProtect(char[] sBuf)
{
    int i = 0;

    while (sBuf[i] != '\0')
    {
        if (sBuf[i] > 32)
        {
            if (sBuf[i] < 48)
            {
                sBuf[i] = ' ';
            }
        }

        if (sBuf[i] > 57)
        {
            if (sBuf[i] < 65)
            {
                sBuf[i] = ' ';
            }
        }

        if (sBuf[i] > 90)
        {
            if (sBuf[i] < 97)
            {
                sBuf[i] = ' ';
            }
        }

        i += 1;
    }
}

public void Event_SQL_Save(Event event, const char[] name, bool dontBroadcast)
{
    char sEscName[HX_128_SIZE];
    char sName[HX_64_SIZE];
    char sTeamID[HX_32_SIZE];
    int i = 1;

    if (hg_db)
    {
        Transaction Txn = SQL_CreateTransaction();

        while (i <= MaxClients)
        {
            if (IsClientInGame(i))
            {
                if (!IsFakeClient(i))
                {
                    sName[0]     = '\0';
                    sTeamID[0]   = '\0';
                    sEscName[0]  = '\0';
                    sg_query3[0] = '\0';

                    GetClientName(i, sName, sizeof(sName) - 8);
                    GetClientAuthId(i, AuthId_Steam2, sTeamID, sizeof(sTeamID) - 1);

                    HxProtect(sName);
                    hg_db.Escape(sName, sEscName, sizeof(sEscName) - 1);

                    Format(sg_query3, sizeof(sg_query3) - 1, "UPDATE l4d2_stats SET \
 Name = '%s', \
 Points = Points + %d, \
 Time1 = Time1 + %d, \
 Time2 = %d, \
 Boomer = Boomer + %d, \
 Charger = Charger + %d, \
 Hunter = Hunter + %d, \
 Infected = Infected + %d, \
 Jockey = Jockey + %d, \
 Smoker = Smoker + %d, \
 Spitter = Spitter + %d, \
 Tank = Tank + %d, \
 Witch = Witch + %d \
 WHERE Steamid = '%s';"
                           , sEscName
                           , ig_temp[i][HX_POINTS]
                           , ig_temp[i][HX_TIME]
                           , GetTime()
                           , ig_temp[i][HX_BOOMER]
                           , ig_temp[i][HX_CHARGER]
                           , ig_temp[i][HX_HUNTER]
                           , ig_temp[i][HX_INFECTED]
                           , ig_temp[i][HX_JOCKEY]
                           , ig_temp[i][HX_SMOKER]
                           , ig_temp[i][HX_SPITTER]
                           , ig_temp[i][HX_TANK]
                           , ig_temp[i][HX_WITCH]
                           , sTeamID);

                    Txn.AddQuery(sg_query3);
                }
            }

            HxClean(i);
            i += 1;
        }

        SQL_ExecuteTransaction(hg_db, Txn, _, _, _, DBPrio_High);
        Txn = null;
    }
}

public Action CMD_keyboard(int client, int args)
{
    if (client < 1)
    {
        return Plugin_Continue;
    }

    if (ig_real[client][HX_POINTS] > 50)
    {
        return Plugin_Continue;
    }

    if (GetUserFlagBits(client) & ADMFLAG_ROOT)
    {
        return Plugin_Continue;
    }

    return Plugin_Handled;
}

public Action CMD_callvote(int client, int args)
{
    if (client < 1)
    {
        return Plugin_Continue;
    }

    if (ig_real[client][HX_POINTS] > 500)
    {
        return Plugin_Continue;
    }

    if (GetUserFlagBits(client) & ADMFLAG_ROOT)
    {
        return Plugin_Continue;
    }

    return Plugin_Handled;
}

public int RankPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
    return 0;
}

public Action CMD_rank(int client, int args)
{
    if (client > 0)
    {
        if (IsClientInGame(client))
        {
            Panel hPanel = new Panel();

            sg_buf1[0]   = '\0';
            Format(sg_buf1, sizeof(sg_buf1) - 1, " Points: %d (%d)\n \
 - \n \
 Boomer: %d (%d)\n \
 Charger: %d (%d)\n \
 Hunter: %d (%d)\n \
 Infected: %d (%d)\n \
 Jockey: %d (%d)\n \
 Smoker: %d (%d)\n \
 Spitter: %d (%d)\n \
 Tank: %d (%d)\n \
 Witch: %d (%d)"
                   , ig_real[client][HX_POINTS],   ig_temp[client][HX_POINTS]
                   , ig_real[client][HX_BOOMER],   ig_temp[client][HX_BOOMER]
                   , ig_real[client][HX_CHARGER],  ig_temp[client][HX_CHARGER]
                   , ig_real[client][HX_HUNTER],   ig_temp[client][HX_HUNTER]
                   , ig_real[client][HX_INFECTED], ig_temp[client][HX_INFECTED]
                   , ig_real[client][HX_JOCKEY],   ig_temp[client][HX_JOCKEY]
                   , ig_real[client][HX_SMOKER],   ig_temp[client][HX_SMOKER]
                   , ig_real[client][HX_SPITTER],  ig_temp[client][HX_SPITTER]
                   , ig_real[client][HX_TANK],     ig_temp[client][HX_TANK]
                   , ig_real[client][HX_WITCH],    ig_temp[client][HX_WITCH]);

            hPanel.DrawText(sg_buf1);

            hPanel.DrawItem("Close");
            hPanel.Send(client, RankPanelHandler, 20);
            delete hPanel;
        }
    }

    return Plugin_Handled;
}

public Action CMD_top(int client, int args)
{
    char sBuffer[HX_128_SIZE];
    char sName[HX_64_SIZE];

    int iPoints = 0;
    int iNum = 0;

    if (client > 0)
    {
        if (IsClientInGame(client))
        {
            if (hg_db)
            {
                Panel hPanel = new Panel();
                hPanel.SetTitle("Top players");

                sg_query4[0] = '\0';
                Format(sg_query4, sizeof(sg_query4) - 1, "SELECT Name, Points FROM l4d2_stats WHERE Points > 0 ORDER BY Points DESC LIMIT 15;");

                SQL_LockDatabase(hg_db);
                DBResultSet hQuery = SQL_Query(hg_db, sg_query4);

                if (hQuery)
                {
                    while (hQuery.FetchRow())
                    {
                        sName[0]   = '\0';
                        sBuffer[0] = '\0';

                        hQuery.FetchString(0, sName, sizeof(sName) - 8);
                        iPoints = hQuery.FetchInt(1);

                        iNum += 1;
                        Format(sBuffer, sizeof(sBuffer) - 1, "%d. %s  %d Points", iNum, sName, iPoints);
                        hPanel.DrawText(sBuffer);
                    }

                    delete hQuery;
                }

                SQL_UnlockDatabase(hg_db);

                hPanel.DrawItem("Close");
                hPanel.Send(client, RankPanelHandler, 20);
                delete hPanel;
            }
        }
    }

    return Plugin_Handled;
}

public Action HxTimerInfinite18(Handle timer)
{
    int i = 1;

    while (i <= MaxClients)
    {
        if (IsClientInGame(i))
        {
            ig_temp[i][HX_TIME] += 1;
        }
        else
        {
            ig_temp[i][HX_TIME] = 0;
        }

        i += 1;
    }

    return Plugin_Continue;
}

public void OnPluginEnd()
{
    if (hg_db)
    {
        delete hg_db;
    }
}
