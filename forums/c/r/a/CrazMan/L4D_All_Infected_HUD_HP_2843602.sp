/*====================================================================================
    Plugin  : L4D / L4D2 - All Infected HP HUD
    Author  : SandyMilk (Nico kengaytirdi)
    Desc    : Tank va barcha Special Infected HP larini HUD da korsatadi
              10 xil HP bar korinishi mavjud
    Version : 3.1 (SourceMod 1.11+ compatible)
====================================================================================*/

#include <sdktools>
#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

//--------------------------------------------------------------
// BAR MASSIVLARI - har biri [21][28]
// [0] = dead, [1..20] = HP darajasi (5% qadam)
//--------------------------------------------------------------

// Uslub 0: Bloklar (#)
char g_Bar0[21][32] = {
    "---DEAD---",
    "[#                  ]",
    "[##                 ]",
    "[###                ]",
    "[####               ]",
    "[#####              ]",
    "[######             ]",
    "[#######            ]",
    "[########           ]",
    "[#########          ]",
    "[##########         ]",
    "[###########        ]",
    "[############       ]",
    "[#############      ]",
    "[##############     ]",
    "[###############    ]",
    "[################   ]",
    "[#################  ]",
    "[################## ]",
    "[###################]",
    "[####################]"
};

// Uslub 1: Tenglik belgisi (=)
char g_Bar1[21][32] = {
    "---DEAD---",
    "[=                  ]",
    "[==                 ]",
    "[===                ]",
    "[====               ]",
    "[=====              ]",
    "[======             ]",
    "[=======            ]",
    "[========           ]",
    "[=========          ]",
    "[==========         ]",
    "[===========        ]",
    "[============       ]",
    "[=============      ]",
    "[==============     ]",
    "[===============    ]",
    "[================   ]",
    "[=================  ]",
    "[================== ]",
    "[===================]",
    "[====================]"
};

// Uslub 2: Plus belgisi (+)
char g_Bar2[21][32] = {
    "---DEAD---",
    "|+..................|",
    "|++.................|",
    "|+++................|",
    "|++++...............|",
    "|+++++..............|",
    "|++++++.............|",
    "|+++++++............|",
    "|++++++++...........|",
    "|+++++++++..........|",
    "|++++++++++.........|",
    "|+++++++++++........|",
    "|++++++++++++.......|",
    "|+++++++++++++......|",
    "|++++++++++++++.....|",
    "|+++++++++++++++....|",
    "|++++++++++++++++...|",
    "|+++++++++++++++++..|",
    "|++++++++++++++++++.|",
    "|+++++++++++++++++++|",
    "|++++++++++++++++++++|"
};

// Uslub 3: Ok belgisi (>)
char g_Bar3[21][32] = {
    "---DEAD---",
    "|>..................|",
    "|>>.................|",
    "|>>>................|",
    "|>>>>...............|",
    "|>>>>>..............|",
    "|>>>>>>.............|",
    "|>>>>>>>............|",
    "|>>>>>>>>...........|",
    "|>>>>>>>>>..........|",
    "|>>>>>>>>>>.........|",
    "|>>>>>>>>>>>........|",
    "|>>>>>>>>>>>>.......|",
    "|>>>>>>>>>>>>>......|",
    "|>>>>>>>>>>>>>>.....|",
    "|>>>>>>>>>>>>>>>....|",
    "|>>>>>>>>>>>>>>>>...|",
    "|>>>>>>>>>>>>>>>>>..|",
    "|>>>>>>>>>>>>>>>>>>.|",
    "|>>>>>>>>>>>>>>>>>>>|",
    "|>>>>>>>>>>>>>>>>>>>>|"
};

// Uslub 4: Yulduzcha (*)
char g_Bar4[21][32] = {
    "---DEAD---",
    "[*                  ]",
    "[**                 ]",
    "[***                ]",
    "[****               ]",
    "[*****              ]",
    "[******             ]",
    "[*******            ]",
    "[********           ]",
    "[*********          ]",
    "[**********         ]",
    "[***********        ]",
    "[************       ]",
    "[*************      ]",
    "[**************     ]",
    "[***************    ]",
    "[****************   ]",
    "[*****************  ]",
    "[****************** ]",
    "[*******************]",
    "[********************]"
};

// Uslub 5: I harfi (ustunlar)
char g_Bar5[21][32] = {
    "---DEAD---",
    "|I                  |",
    "|II                 |",
    "|III                |",
    "|IIII               |",
    "|IIIII              |",
    "|IIIIII             |",
    "|IIIIIII            |",
    "|IIIIIIII           |",
    "|IIIIIIIII          |",
    "|IIIIIIIIII         |",
    "|IIIIIIIIIII        |",
    "|IIIIIIIIIIII       |",
    "|IIIIIIIIIIIII      |",
    "|IIIIIIIIIIIIII     |",
    "|IIIIIIIIIIIIIII    |",
    "|IIIIIIIIIIIIIIII   |",
    "|IIIIIIIIIIIIIIIII  |",
    "|IIIIIIIIIIIIIIIIII |",
    "|IIIIIIIIIIIIIIIIIII|",
    "|IIIIIIIIIIIIIIIIIIII|"
};

// Uslub 6: o va _ harflari
char g_Bar6[21][32] = {
    "---DEAD---",
    "HP[o__________________]",
    "HP[oo_________________]",
    "HP[ooo________________]",
    "HP[oooo_______________]",
    "HP[ooooo______________]",
    "HP[oooooo_____________]",
    "HP[ooooooo____________]",
    "HP[oooooooo___________]",
    "HP[ooooooooo__________]",
    "HP[oooooooooo_________]",
    "HP[ooooooooooo________]",
    "HP[oooooooooooo_______]",
    "HP[ooooooooooooo______]",
    "HP[oooooooooooooo_____]",
    "HP[ooooooooooooooo____]",
    "HP[oooooooooooooooo___]",
    "HP[ooooooooooooooooo__]",
    "HP[oooooooooooooooooo_]",
    "HP[ooooooooooooooooooo]",
    "HP[oooooooooooooooooooo]"
};

// Uslub 7: Minus (-)
char g_Bar7[21][32] = {
    "---DEAD---",
    "[-                  ]",
    "[--                 ]",
    "[---                ]",
    "[----               ]",
    "[-----              ]",
    "[------             ]",
    "[-------            ]",
    "[--------           ]",
    "[---------          ]",
    "[----------         ]",
    "[-----------        ]",
    "[------------       ]",
    "[-------------      ]",
    "[--------------     ]",
    "[---------------    ]",
    "[----------------   ]",
    "[-----------------  ]",
    "[------------------ ]",
    "[-------------------]",
    "[--------------------]"
};

// Uslub 8: X harfi
char g_Bar8[21][32] = {
    "---DEAD---",
    "[X                  ]",
    "[XX                 ]",
    "[XXX                ]",
    "[XXXX               ]",
    "[XXXXX              ]",
    "[XXXXXX             ]",
    "[XXXXXXX            ]",
    "[XXXXXXXX           ]",
    "[XXXXXXXXX          ]",
    "[XXXXXXXXXX         ]",
    "[XXXXXXXXXXX        ]",
    "[XXXXXXXXXXXX       ]",
    "[XXXXXXXXXXXXX      ]",
    "[XXXXXXXXXXXXXX     ]",
    "[XXXXXXXXXXXXXXX    ]",
    "[XXXXXXXXXXXXXXXX   ]",
    "[XXXXXXXXXXXXXXXXX  ]",
    "[XXXXXXXXXXXXXXXXXX ]",
    "[XXXXXXXXXXXXXXXXXXX]",
    "[XXXXXXXXXXXXXXXXXXXX]"
};

// Uslub 9: @ belgi
char g_Bar9[21][32] = {
    "---DEAD---",
    "[@                  ]",
    "[@@                 ]",
    "[@@@                ]",
    "[@@@@               ]",
    "[@@@@@              ]",
    "[@@@@@@             ]",
    "[@@@@@@@            ]",
    "[@@@@@@@@           ]",
    "[@@@@@@@@@          ]",
    "[@@@@@@@@@@         ]",
    "[@@@@@@@@@@@        ]",
    "[@@@@@@@@@@@@       ]",
    "[@@@@@@@@@@@@@      ]",
    "[@@@@@@@@@@@@@@     ]",
    "[@@@@@@@@@@@@@@@    ]",
    "[@@@@@@@@@@@@@@@@   ]",
    "[@@@@@@@@@@@@@@@@@  ]",
    "[@@@@@@@@@@@@@@@@@ ]",
    "[@@@@@@@@@@@@@@@@@@@]",
    "[@@@@@@@@@@@@@@@@@@@@]"
};

//--------------------------------------------------------------
// GLOBAL O'ZGARUVCHILAR
//--------------------------------------------------------------
int    g_ClientData[MAXPLAYERS+1][2];
int    g_HurtTarget[MAXPLAYERS+1];
int    g_BurnTarget[MAXPLAYERS+1];
Handle g_HideTimer[MAXPLAYERS+1];
Handle g_BurnTimer[MAXPLAYERS+1];

ConVar g_CvarEnable;
ConVar g_CvarDuration;
ConVar g_CvarSpectators;
ConVar g_CvarWitch;

int    g_TankClass;
bool   g_IsL4D2;
Database g_DB;

//--------------------------------------------------------------
// PLUGIN MA'LUMOTI
//--------------------------------------------------------------
public Plugin myinfo = {
    name        = "L4D/L4D2 - All Infected HP HUD",
    author      = "SandyMilk (Nico kengaytirdi)",
    description = "Faqat zarar berganda infected HP sini HUD da korsatadi",
    version     = "3.1",
    url         = "https://forums.alliedmods.net"
};

//--------------------------------------------------------------
// PLUGIN YOQILGANDA
//--------------------------------------------------------------
public void OnPluginStart()
{
    g_IsL4D2    = (GetEngineVersion() == Engine_Left4Dead2);
    g_TankClass = g_IsL4D2 ? 8 : 5;

    LoadTranslations("l4d_infected_hud_hp.phrases");

    for (int i = 1; i <= MAXPLAYERS; i++)
    {
        g_HurtTarget[i] = -1;
        g_BurnTarget[i] = -1;
        g_HideTimer[i]  = null;
        g_BurnTimer[i]  = null;
    }

    HookEvent("player_hurt", Event_PlayerHurt);
    HookEvent("player_spawn", Event_PlayerSpawn);

    g_CvarEnable     = CreateConVar("xi_hp_enable",     "1",   "HUD yoq/yoqiq (0/1)",              FCVAR_NONE, true, 0.0, true, 1.0);
    g_CvarDuration   = CreateConVar("xi_hp_duration",   "1.0", "HUD necha sekund korinadi",         FCVAR_NONE, true, 0.5, true, 10.0);
    g_CvarSpectators = CreateConVar("xi_hp_spectators", "1",   "Kuzatuvchilar ham korsinmi (0/1)",  FCVAR_NONE, true, 0.0, true, 1.0);
    g_CvarWitch      = CreateConVar("xi_hp_witch",      "1",   "Witch HP korsinmi (0/1)",           FCVAR_NONE, true, 0.0, true, 1.0);

    RegConsoleCmd("sm_xhud", Cmd_HudMenu, "HP HUD sozlamalarini ochadi");
    RegConsoleCmd("sm_ihud", Cmd_HudMenu, "HP HUD sozlamalarini ochadi");

    AutoExecConfig(true, "l4d_all_infected_hud");

    char error[256];
    g_DB = SQLite_UseDatabase("l4d_hud_prefs", error, sizeof(error));
    if (g_DB == null)
    {
        LogError("[HUD] SQLite ochilmadi: %s", error);
        return;
    }
    g_DB.Query(SQL_OnTableCreate, "CREATE TABLE IF NOT EXISTS hud_prefs (steamid TEXT PRIMARY KEY, hud_type INTEGER DEFAULT 0, bar_style INTEGER DEFAULT 0)");
}

public void OnMapStart()
{
    // Precache any resources if needed
}

public void OnClientDisconnect(int client)
{
    DB_SavePrefs(client);
    ClearClientHUD(client);
}

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client)) return;
    DB_LoadPrefs(client);
}

//--------------------------------------------------------------
// EVENT: PLAYER SPAWN
//--------------------------------------------------------------
public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client && IsAllowedClient(client))
    {
        ClearClientHUD(client);
    }
}

//--------------------------------------------------------------
// DB: JADVAL YARATISH CALLBACK
//--------------------------------------------------------------
public void SQL_OnTableCreate(Database db, DBResultSet results, const char[] error, any data)
{
    if (db == null || error[0] != '\0')
        LogError("[HUD] Jadval yaratishda xato: %s", error);
}

//--------------------------------------------------------------
// DB: SAQLASH
//--------------------------------------------------------------
void DB_SavePrefs(int client)
{
    if (g_DB == null || !IsClientInGame(client) || IsFakeClient(client)) return;

    char steamid[64];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid))) return;

    char query[512];
    FormatEx(query, sizeof(query),
        "INSERT OR REPLACE INTO hud_prefs (steamid, hud_type, bar_style) VALUES ('%s', %d, %d)",
        steamid, g_ClientData[client][0], g_ClientData[client][1]
    );
    g_DB.Query(SQL_OnSave, query);
}

public void SQL_OnSave(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0] != '\0')
        LogError("[HUD] Saqlashda xato: %s", error);
}

//--------------------------------------------------------------
// DB: YUKLASH
//--------------------------------------------------------------
void DB_LoadPrefs(int client)
{
    if (g_DB == null) return;

    char steamid[64];
    if (!GetClientAuthId(client, AuthId_Steam2, steamid, sizeof(steamid)))
    {
        DataPack dp = new DataPack();
        dp.WriteCell(GetClientSerial(client));
        CreateTimer(1.0, Timer_DelayedLoad, dp);
        return;
    }

    char query[512];
    FormatEx(query, sizeof(query),
        "SELECT hud_type, bar_style FROM hud_prefs WHERE steamid = '%s'",
        steamid
    );
    DataPack dp = new DataPack();
    dp.WriteCell(GetClientSerial(client));
    g_DB.Query(SQL_OnLoad, query, dp);
}

public Action Timer_DelayedLoad(Handle timer, DataPack dp)
{
    dp.Reset();
    int serial = dp.ReadCell();
    delete dp;
    
    int client = GetClientFromSerial(serial);
    if (client > 0)
        DB_LoadPrefs(client);
    return Plugin_Stop;
}

public void SQL_OnLoad(Database db, DBResultSet results, const char[] error, DataPack dp)
{
    dp.Reset();
    int serial = dp.ReadCell();
    delete dp;

    int client = GetClientFromSerial(serial);
    if (client <= 0) return;

    if (error[0] != '\0')
    {
        LogError("[HUD] Yuklashda xato: %s", error);
        return;
    }

    if (results != null && results.FetchRow())
    {
        g_ClientData[client][0] = results.FetchInt(0);
        g_ClientData[client][1] = results.FetchInt(1);
    }
}

//--------------------------------------------------------------
// ASOSIY EVENT: KIM KIMGA ZARAR BERDI
//--------------------------------------------------------------
public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_CvarEnable.BoolValue)
        return;

    int victim    = GetClientOfUserId(event.GetInt("userid"));
    int attacker  = GetClientOfUserId(event.GetInt("attacker"));

    if (!IsInfectedBot(victim))
        return;

    int remainingHp = event.GetInt("health");
    
    // O'lim zarbasi
    if (remainingHp <= 0)
    {
        HandleDeath(victim, attacker);
        return;
    }

    // Witch tekshiruvi
    if (g_IsL4D2)
    {
        int zc = GetEntProp(victim, Prop_Send, "m_zombieClass");
        if (zc == 7 && !g_CvarWitch.BoolValue)
            return;
    }

    // Attacker haqiqiy o'yinchi
    if (attacker > 0 && attacker <= MaxClients && IsAllowedClient(attacker))
    {
        ShowHPToClient(attacker, victim, false);
    }
    else if (attacker == 0)
    {
        // World damage - yonish
        for (int c = 1; c <= MaxClients; c++)
        {
            if (IsAllowedClient(c) && g_BurnTarget[c] == victim)
            {
                ShowHPToClient(c, victim, true);
            }
        }
    }
}

void HandleDeath(int victim, int attacker)
{
    if (attacker > 0 && attacker <= MaxClients && IsAllowedClient(attacker))
    {
        int zclass = GetEntProp(victim, Prop_Send, "m_zombieClass");
        char cname[32];
        GetInfectedName(zclass, cname, sizeof(cname), attacker);

        char bar[32];
        GetBarString(g_ClientData[attacker][1], 0, bar, sizeof(bar));

        if (g_ClientData[attacker][0] == 1)
            PrintHintText(attacker, "%s  HP: 0\n%s", cname, bar);
        else
            PrintCenterText(attacker, "%s  HP: 0\n%s", cname, bar);

        if (g_HideTimer[attacker] != null)
        {
            delete g_HideTimer[attacker];
            g_HideTimer[attacker] = null;
        }
        
        DataPack dp = new DataPack();
        dp.WriteCell(GetClientSerial(attacker));
        dp.WriteCell(0);
        g_HurtTarget[attacker] = -1;
        g_HideTimer[attacker] = CreateTimer(g_CvarDuration.FloatValue, Timer_HideHUD, dp, TIMER_FLAG_NO_MAPCHANGE);
    }
    else
    {
        for (int c = 1; c <= MaxClients; c++)
        {
            if (IsAllowedClient(c) && (g_BurnTarget[c] == victim || g_HurtTarget[c] == victim))
                ClearClientHUD(c);
        }
    }
}

//--------------------------------------------------------------
// O'YINCHIGA HP KORSATISH + TIMER BOSHQARUVI
//--------------------------------------------------------------
void ShowHPToClient(int client, int infected, bool isBurn)
{
    if (!IsValidClient(infected) || !IsPlayerAlive(infected))
    {
        ClearClientHUD(client);
        return;
    }

    g_HurtTarget[client] = infected;
    DrawHP(client, infected);

    if (isBurn)
    {
        g_BurnTarget[client] = infected;

        if (g_BurnTimer[client] != null)
        {
            delete g_BurnTimer[client];
            g_BurnTimer[client] = null;
        }

        DataPack dp = new DataPack();
        dp.WriteCell(GetClientSerial(client));
        dp.WriteCell(EntIndexToEntRef(infected));
        g_BurnTimer[client] = CreateTimer(0.3, Timer_BurnCheck, dp, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);

        if (g_HideTimer[client] != null)
        {
            delete g_HideTimer[client];
            g_HideTimer[client] = null;
        }
    }
    else
    {
        if (g_HideTimer[client] != null)
        {
            delete g_HideTimer[client];
            g_HideTimer[client] = null;
        }

        if (g_BurnTimer[client] != null && g_BurnTarget[client] == infected)
            return;

        DataPack dp = new DataPack();
        dp.WriteCell(GetClientSerial(client));
        dp.WriteCell(EntIndexToEntRef(infected));
        g_HideTimer[client] = CreateTimer(g_CvarDuration.FloatValue, Timer_HideHUD, dp, TIMER_FLAG_NO_MAPCHANGE);
    }
}

//--------------------------------------------------------------
// YONISH TEKSHIRUV TIMERI
//--------------------------------------------------------------
public Action Timer_BurnCheck(Handle timer, DataPack dp)
{
    dp.Reset();
    int serial   = dp.ReadCell();
    int entref   = dp.ReadCell();

    int client   = GetClientFromSerial(serial);
    int infected = EntRefToEntIndex(entref);

    if (client <= 0 || !IsAllowedClient(client) || infected == INVALID_ENT_REFERENCE || infected <= 0)
    {
        if (client > 0 && client <= MAXPLAYERS)
        {
            g_BurnTimer[client] = null;
            ClearClientHUD(client);
        }
        return Plugin_Stop;
    }

    if (!IsValidClient(infected) || !IsPlayerAlive(infected))
    {
        g_BurnTimer[client] = null;
        ClearClientHUD(client);
        return Plugin_Stop;
    }

    bool stillBurning = false;
    if (HasEntProp(infected, Prop_Send, "m_bBurning"))
        stillBurning = view_as<bool>(GetEntProp(infected, Prop_Send, "m_bBurning"));

    if (stillBurning)
    {
        DrawHP(client, infected);
        return Plugin_Continue;
    }
    else
    {
        g_BurnTimer[client] = null;
        g_BurnTarget[client] = -1;
        ClearClientHUD(client);
        return Plugin_Stop;
    }
}

//--------------------------------------------------------------
// ODDIY ZARAR TIMER
//--------------------------------------------------------------
public Action Timer_HideHUD(Handle timer, DataPack dp)
{
    dp.Reset();
    int serial = dp.ReadCell();
    int client = GetClientFromSerial(serial);
    delete dp;

    if (client > 0 && client <= MAXPLAYERS)
    {
        g_HideTimer[client] = null;
        g_HurtTarget[client] = -1;
        ClearClientHUD(client);
    }

    return Plugin_Stop;
}

//--------------------------------------------------------------
// INFECTED NOMI
//--------------------------------------------------------------
void GetInfectedName(int zclass, char[] out, int maxLen, int client = 0)
{
    if (zclass == g_TankClass)
        Format(out, maxLen, "%T", "HUD_Tank", client);
    else if (g_IsL4D2)
    {
        switch (zclass)
        {
            case 1: Format(out, maxLen, "%T", "HUD_Smoker",  client);
            case 2: Format(out, maxLen, "%T", "HUD_Boomer",  client);
            case 3: Format(out, maxLen, "%T", "HUD_Hunter",  client);
            case 4: Format(out, maxLen, "%T", "HUD_Spitter", client);
            case 5: Format(out, maxLen, "%T", "HUD_Jockey",  client);
            case 6: Format(out, maxLen, "%T", "HUD_Charger", client);
            case 7: Format(out, maxLen, "%T", "HUD_Witch",   client);
            default: Format(out, maxLen, "%T", "HUD_Infected", client);
        }
    }
    else
    {
        switch (zclass)
        {
            case 1: Format(out, maxLen, "%T", "HUD_Smoker", client);
            case 2: Format(out, maxLen, "%T", "HUD_Boomer", client);
            case 3: Format(out, maxLen, "%T", "HUD_Hunter", client);
            default: Format(out, maxLen, "%T", "HUD_Infected", client);
        }
    }
}

//--------------------------------------------------------------
// INFECTED NOMI + HP SATR
//--------------------------------------------------------------
void GetInfectedLabel(int ent, char[] label, int maxLen, int client = 0)
{
    int zclass = GetEntProp(ent, Prop_Send, "m_zombieClass");
    int hp    = GetEntProp(ent, Prop_Data, "m_iHealth");
    int maxhp = GetEntProp(ent, Prop_Data, "m_iMaxHealth");

    if (hp < 0) hp = 0;

    char cname[32];
    GetInfectedName(zclass, cname, sizeof(cname), client);

    if (maxhp > 0)
        FormatEx(label, maxLen, "%s  HP: %d / %d", cname, hp, maxhp);
    else
        FormatEx(label, maxLen, "%s  HP: %d", cname, hp);
}

//--------------------------------------------------------------
// BAR SATRINI OLISH
//--------------------------------------------------------------
void GetBarString(int styleIdx, int barIdx, char[] out, int maxLen)
{
    switch (styleIdx)
    {
        case 0: strcopy(out, maxLen, g_Bar0[barIdx]);
        case 1: strcopy(out, maxLen, g_Bar1[barIdx]);
        case 2: strcopy(out, maxLen, g_Bar2[barIdx]);
        case 3: strcopy(out, maxLen, g_Bar3[barIdx]);
        case 4: strcopy(out, maxLen, g_Bar4[barIdx]);
        case 5: strcopy(out, maxLen, g_Bar5[barIdx]);
        case 6: strcopy(out, maxLen, g_Bar6[barIdx]);
        case 7: strcopy(out, maxLen, g_Bar7[barIdx]);
        case 8: strcopy(out, maxLen, g_Bar8[barIdx]);
        case 9: strcopy(out, maxLen, g_Bar9[barIdx]);
        default: strcopy(out, maxLen, g_Bar0[barIdx]);
    }
}

//--------------------------------------------------------------
// HUD CHIZISH
//--------------------------------------------------------------
void DrawHP(int client, int infected)
{
    char header[64];
    GetInfectedLabel(infected, header, sizeof(header), client);

    int styleIdx = g_ClientData[client][1];
    int barIdx   = RatioToIndex(infected, 20);

    char bar[32];
    GetBarString(styleIdx, barIdx, bar, sizeof(bar));

    if (g_ClientData[client][0] == 1)
        PrintHintText(client, "%s\n%s", header, bar);
    else
        PrintCenterText(client, "%s\n%s", header, bar);
}

//--------------------------------------------------------------
// HP RATIO -> BAR INDEX
//--------------------------------------------------------------
int RatioToIndex(int ent, int rows)
{
    if (GetEntProp(ent, Prop_Send, "m_isIncapacitated"))
        return 0;

    int hp    = GetEntProp(ent, Prop_Data, "m_iHealth");
    int maxhp = GetEntProp(ent, Prop_Data, "m_iMaxHealth");

    if (maxhp <= 0 || hp <= 0)
        return 0;

    return RoundToCeil(float(rows) * float(hp) / float(maxhp));
}

//--------------------------------------------------------------
// CLIENTNING BARCHA HUD VA TIMERLARINI TOZALASH
//--------------------------------------------------------------
void ClearClientHUD(int client)
{
    if (client <= 0 || client > MAXPLAYERS) return;

    g_HurtTarget[client] = -1;
    g_BurnTarget[client] = -1;

    if (g_HideTimer[client] != null)
    {
        delete g_HideTimer[client];
        g_HideTimer[client] = null;
    }
    if (g_BurnTimer[client] != null)
    {
        delete g_BurnTimer[client];
        g_BurnTimer[client] = null;
    }
}

//--------------------------------------------------------------
// MENYU BUYRUG'I
//--------------------------------------------------------------
public Action Cmd_HudMenu(int client, int args)
{
    if (!client)
    {
        ReplyToCommand(client, "[SM] Bu buyruq faqat o'yin ichida ishlaydi.");
        return Plugin_Handled;
    }
    if (!g_CvarEnable.BoolValue)
    {
        ReplyToCommand(client, "[SM] HUD hozirda o'chirilgan.");
        return Plugin_Handled;
    }
    OpenMenu(client);
    return Plugin_Handled;
}

//--------------------------------------------------------------
// MENYU
//--------------------------------------------------------------
static const char g_StyleKeys[10][] = {
    "HUD_Style0", "HUD_Style1", "HUD_Style2", "HUD_Style3", "HUD_Style4",
    "HUD_Style5", "HUD_Style6", "HUD_Style7", "HUD_Style8", "HUD_Style9"
};

void OpenMenu(int client)
{
    Menu menu = new Menu(MenuHandler);

    char styleName[32];
    Format(styleName, sizeof(styleName), "%T", g_StyleKeys[g_ClientData[client][1]], client);
    char title[128];
    Format(title, sizeof(title), "%T", "HUD_MenuTitle", client, styleName);
    menu.SetTitle(title);

    char hudItem[64];
    if (g_ClientData[client][0] == 0)
        Format(hudItem, sizeof(hudItem), "%T", "HUD_TypeCenter", client);
    else
        Format(hudItem, sizeof(hudItem), "%T", "HUD_TypeHint", client);
    menu.AddItem("hud_type", hudItem);

    for (int i = 0; i < 10; i++)
    {
        char sname[32];
        Format(sname, sizeof(sname), "%T", g_StyleKeys[i], client);

        char itemText[64];
        if (i == g_ClientData[client][1])
            Format(itemText, sizeof(itemText), "%T", "HUD_Selected", client, sname);
        else
            strcopy(itemText, sizeof(itemText), sname);

        char itemVal[8];
        FormatEx(itemVal, sizeof(itemVal), "%d", i);
        menu.AddItem(itemVal, itemText);
    }

    menu.ExitButton = true;
    menu.Display(client, 30);
}

public int MenuHandler(Menu menu, MenuAction action, int client, int param2)
{
    if (action == MenuAction_End)
    {
        delete menu;
        return 0;
    }

    if (action == MenuAction_Select)
    {
        char info[16];
        menu.GetItem(param2, info, sizeof(info));

        if (StrEqual(info, "hud_type"))
        {
            g_ClientData[client][0] = g_ClientData[client][0] == 0 ? 1 : 0;
        }
        else
        {
            int style = StringToInt(info);
            g_ClientData[client][1] = style;

            char bar[32];
            GetBarString(style, 15, bar, sizeof(bar));
            if (g_ClientData[client][0] == 1)
                PrintHintText(client, "[ TANK ]  HP: 18750 / 25000\n%s", bar);
            else
                PrintCenterText(client, "[ TANK ]  HP: 18750 / 25000\n%s", bar);
        }

        DB_SavePrefs(client);
        OpenMenu(client);
    }
    return 0;
}

//--------------------------------------------------------------
// YORDAMCHI FUNKSIYALAR
//--------------------------------------------------------------
bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
}

bool IsAllowedClient(int client)
{
    if (!IsValidClient(client))  return false;
    if (IsFakeClient(client))    return false;
    if (IsClientObserver(client) && !g_CvarSpectators.BoolValue) return false;
    return true;
}

bool IsInfectedBot(int client)
{
    if (!IsValidClient(client))     return false;
    if (!IsFakeClient(client))      return false;
    if (!IsPlayerAlive(client))     return false;
    if (GetClientTeam(client) != 3) return false;
    if (!HasEntProp(client, Prop_Send, "m_zombieClass")) return false;

    int zc = GetEntProp(client, Prop_Send, "m_zombieClass");
    return g_IsL4D2 ? (zc >= 1 && zc <= 8) : (zc >= 1 && zc <= 5);
}