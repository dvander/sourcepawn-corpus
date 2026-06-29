#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "2.6"
#define MAX_PLAYERS 64
#define BASE_XP_PER_LEVEL 200
#define XP_MULTIPLIER 1.1

#define XP_REGULAR_MIN 5
#define XP_REGULAR_MAX 15
#define XP_SPECIAL_MIN 20
#define XP_SPECIAL_MAX 35
#define XP_BOSS_MIN 40
#define XP_BOSS_MAX 60
#define XP_WITCH_AS_WORLDSPAWN 50

#define MAX_LEVEL_CAP 1000
#define MAX_XP_CAP 1000000
#define INTEGRITY_VERSION 1

// ----------------------------------------------------------------------------
// Глобальные переменные
// ----------------------------------------------------------------------------
Database g_hDatabase = null;

int g_playerLevels[MAX_PLAYERS+1];
int g_playerXP[MAX_PLAYERS+1];
int g_selectedAchievement[MAX_PLAYERS+1];
int g_doubleXPEvent = 0;

int g_playerPlaytime[MAX_PLAYERS+1];
float g_playerSessionStartTime[MAX_PLAYERS+1];

bool g_dataLoaded[MAX_PLAYERS+1];
char g_lastKnownSteamID[MAX_PLAYERS+1][64];
bool g_mapChanging = false;

ConVar g_cvarAutoMessageInterval;
ConVar g_cvarPluginEnabled;
ConVar g_cvarDebugLogging;
ConVar g_cvarLeaderboardMaxPlayers;
ConVar g_cvarLevelAnnounceMilestonesOnly;
ConVar g_cvarLevelAnnounceMilestoneInterval;

Handle g_saveTimer;
Handle g_autoMessageTimer;
Handle g_doubleXPMessageTimer;
Handle g_eventCountdownTimer = null;
Handle g_playtimeTimer = null;
Handle g_allPlaytimesTimer = null;

char g_achievementNames[][] = {
    "Newbie", "Apprentice", "Adept", "Journeyman", "Expert", "Master", "Grandmaster",
    "Legend", "Mythic", "Immortal", "Demigod", "Conqueror", "Hero", "Vanquisher",
    "Warlord", "Champion", "Titan", "Phantom", "Specter", "Eternal", "Ascended",
    "Supreme", "Invincible", "Overlord", "Immortal Hero", "Celestial", "Divine",
    "Omnipotent", "Ethereal", "Godlike", "Behemoth", "Colossus", "Juggernaut",
    "Leviathan", "Monolith", "Titanic", "Goliath", "Brutal", "Ruthless", "Supreme Ruler",
    "Infinite", "Unstoppable", "Inexorable", "Indomitable", "Relentless", "Formidable",
    "Dominator", "Perpetual", "Immovable", "Omniscient", "Transcendent", "Ultimate",
    "Supremacy", "Immortal Lord", "Primordial", "Absolute", "Unyielding", "Sovereign",
    "Overseer", "Invincible Ruler", "Transcendent Hero", "Immortal Conqueror",
    "Supreme Leader", "Infinite Warrior", "Godlike Champion", "Immortal Deity",
    "Omnipresent", "Divine Guardian", "Supreme Master", "Eternal Ruler", "Omniscient Lord",
    "Primordial King", "Absolute Sovereign", "Unyielding Guardian", "Eternal Champion",
    "Supreme Overlord", "Immortal Monarch", "Divine Ruler", "Infinite Champion",
    "Transcendent Sovereign", "Omnipotent Deity", "Immortal King", "Supreme Ruler",
    "Godlike Warrior", "Unstoppable Force", "Divine Entity", "Supreme Entity",
    "Immortal Titan", "Infinite Power", "Omnipotent Champion", "Godlike Entity",
    "Supreme Titan", "Immortal Entity", "Infinite Entity", "Divine Power",
    "Omnipotent Ruler", "Godlike Ruler", "Supreme Power", "Immortal Power", "Infinite Ruler"
};

// ----------------------------------------------------------------------------
// Plugin info
// ----------------------------------------------------------------------------
public Plugin myinfo = {
    name = "Level Up Plugin",
    author = "Mezo123451A (SQLite version)",
    description = "Leveling system with SQLite storage",
    version = PLUGIN_VERSION
};

// ----------------------------------------------------------------------------
// Инициализация
// ----------------------------------------------------------------------------
public void OnPluginStart()
{
    CreateConVar("levelup_version", PLUGIN_VERSION, "Version of the Level Up Plugin", FCVAR_NOTIFY);
    g_cvarAutoMessageInterval = CreateConVar("levelup_auto_message_interval", "120.0", "Interval for auto messages in seconds", FCVAR_ARCHIVE, true, 10.0, true, 600.0);
    g_cvarPluginEnabled = CreateConVar("levelup_enabled", "1", "Enable or disable the Level Up plugin", FCVAR_ARCHIVE);
    g_cvarDebugLogging = CreateConVar("levelup_debug_logging", "0", "Enable detailed debug logging", FCVAR_ARCHIVE);
    g_cvarLeaderboardMaxPlayers = CreateConVar("levelup_leaderboard_max_players", "0", "Max players on leaderboard (0=all)", FCVAR_ARCHIVE, true, 0.0, true, 64.0);
    g_cvarLevelAnnounceMilestonesOnly = CreateConVar("levelup_announce_milestones_only", "0", "Announce only milestone levels", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
    g_cvarLevelAnnounceMilestoneInterval = CreateConVar("levelup_announce_milestone_interval", "10", "Milestone interval", FCVAR_ARCHIVE, true, 1.0, true, 1000.0);

    HookConVarChange(g_cvarAutoMessageInterval, OnAutoMessageIntervalChanged);
    AutoExecConfig(true, "levelup_plugin");

    // Подключение к БД
    Database.Connect(OnDatabaseConnect, "l4d2_level");

    // Очистка массивов
    for (int i = 1; i <= MaxClients; i++) {
        g_dataLoaded[i] = false;
        g_lastKnownSteamID[i][0] = '\0';
    }

    PrintToServer("Level Up Plugin v%s (SQLite) starting...", PLUGIN_VERSION);

    // События
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Post);
    HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
    HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);

    // Команды чата
    AddCommandListener(Command_SayTeam, "say_team");
    AddCommandListener(Command_Say, "say");

    // Команды меню
    RegConsoleCmd("sm_lv", Command_ShowMainMenu);

    // Таймеры
    g_saveTimer = CreateTimer(60.0, SaveAllPlayerDataTimer, _, TIMER_REPEAT);
    StartAutoMessageTimer();
    StartDoubleXPMessageTimer();
}

// ----------------------------------------------------------------------------
// Подключение к БД и создание таблицы
// ----------------------------------------------------------------------------
public void OnDatabaseConnect(Database db, const char[] error, any data)
{
    if (db == null)
    {
        LogError("Failed to connect to database 'l4d2_level': %s", error);
        SetFailState("Could not connect to SQLite database");
        return;
    }
    g_hDatabase = db;
    DebugLog("Connected to SQLite database");

    char query[] = "CREATE TABLE IF NOT EXISTS players (steam_id TEXT PRIMARY KEY, level INTEGER NOT NULL DEFAULT 1, xp INTEGER NOT NULL DEFAULT 0, achievement INTEGER NOT NULL DEFAULT -1, playtime INTEGER NOT NULL DEFAULT 0, integrity_hash INTEGER, integrity_version INTEGER, last_save_time INTEGER);";
    g_hDatabase.Query(SQL_ErrorCallback, query);
}

// ----------------------------------------------------------------------------
// Загрузка данных игрока
// ----------------------------------------------------------------------------
public void OnClientPutInServer(int client)
{
    if (!g_cvarPluginEnabled.BoolValue || IsFakeClient(client))
        return;

    g_playerSessionStartTime[client] = GetGameTime();
    g_dataLoaded[client] = false;
    g_lastKnownSteamID[client][0] = '\0';
    g_playerLevels[client] = 1;
    g_playerXP[client] = 0;
    g_selectedAchievement[client] = -1;
    g_playerPlaytime[client] = 0;

    CreateTimer(1.0, Timer_DelayedLoad, client);
}

public Action Timer_DelayedLoad(Handle timer, any client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Stop;

    LoadPlayerData(client);
    return Plugin_Stop;
}

void LoadPlayerData(int client)
{
    if (!g_cvarPluginEnabled.BoolValue || g_hDatabase == null)
        return;

    char steamID[64];
    if (!GetSteamIDWithFallback(client, steamID, sizeof(steamID)) || steamID[0] == '\0')
    {
        DebugLog("No SteamID for %N, will retry later", client);
        CreateTimer(3.0, Timer_DelayedLoad, client);
        return;
    }

    strcopy(g_lastKnownSteamID[client], sizeof(g_lastKnownSteamID[]), steamID);
    char escapedSteamID[64];
    g_hDatabase.Escape(steamID, escapedSteamID, sizeof(escapedSteamID));

    char query[256];
    Format(query, sizeof(query), "SELECT level, xp, achievement, playtime FROM players WHERE steam_id = '%s'", escapedSteamID);

    DebugLog("Loading data for %N (SteamID: %s)", client, steamID);
    g_hDatabase.Query(LoadPlayerDataCallback, query, GetClientUserId(client));
}

public void LoadPlayerDataCallback(Database db, DBResultSet results, const char[] error, any userid)
{
    int client = GetClientOfUserId(userid);
    if (client == 0 || !IsClientInGame(client) || IsFakeClient(client))
        return;

    if (error[0] != '\0' || results == null)
    {
        DebugLog("SQL error loading %N: %s", client, error);
        g_dataLoaded[client] = true;
        return;
    }

    if (results.FetchRow())
    {
        g_playerLevels[client] = results.FetchInt(0);
        g_playerXP[client] = results.FetchInt(1);
        g_selectedAchievement[client] = results.FetchInt(2);
        g_playerPlaytime[client] = results.FetchInt(3);
        DebugLog("Loaded %N: Level %d, XP %d, Playtime %d", client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
    }
    else
    {
        DebugLog("No record for %N, default values assigned", client);
    }

    g_dataLoaded[client] = true;
    PrintToChat(client, "\x04[Survivor Leveling]\x01 Your data loaded: Level \x05%d\x01, XP \x05%d\x01", g_playerLevels[client], g_playerXP[client]);
}

// ----------------------------------------------------------------------------
// Сохранение данных игрока
// ----------------------------------------------------------------------------
void SavePlayerData(int client)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;
    if (!IsClientInGame(client) || IsFakeClient(client))
        return;
    if (!g_dataLoaded[client])
        return;

    // Обновляем playtime текущей сессией
    if (g_playerSessionStartTime[client] > 0.0)
    {
        float sessionTime = GetGameTime() - g_playerSessionStartTime[client];
        g_playerPlaytime[client] += RoundToFloor(sessionTime);
        g_playerSessionStartTime[client] = GetGameTime();
    }

    char steamID[64];
    if (!GetSteamIDWithFallback(client, steamID, sizeof(steamID)) || steamID[0] == '\0')
        return;
    if (g_lastKnownSteamID[client][0] != '\0' && !StrEqual(steamID, g_lastKnownSteamID[client]))
    {
        DebugLog("SteamID mismatch for %N – skipping save", client);
        return;
    }

    char escapedSteamID[64];
    g_hDatabase.Escape(steamID, escapedSteamID, sizeof(escapedSteamID));

    int integrityHash = CalculateIntegrityHash(g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);

    char query[1024];
    Format(query, sizeof(query), "REPLACE INTO players (steam_id, level, xp, achievement, playtime, integrity_hash, integrity_version, last_save_time) VALUES ('%s', %d, %d, %d, %d, %d, %d, %d)", escapedSteamID, g_playerLevels[client], g_playerXP[client], g_selectedAchievement[client], g_playerPlaytime[client], integrityHash, INTEGRITY_VERSION, GetTime());

    g_hDatabase.Query(SQL_ErrorCallback, query);
    DebugLog("Saved %N: Level %d, XP %d, Playtime %d", client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
}

void SaveAllPlayerData()
{
    if (!g_cvarPluginEnabled.BoolValue || g_hDatabase == null)
        return;

    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i))
            SavePlayerData(i);
}

public Action SaveAllPlayerDataTimer(Handle timer, any data)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return Plugin_Handled;
    SaveAllPlayerData();
    g_mapChanging = false;
    return Plugin_Continue;
}

// ----------------------------------------------------------------------------
// События
// ----------------------------------------------------------------------------
public void OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client < 1 || client > MaxClients)
        return;

    if (g_playerSessionStartTime[client] > 0.0)
    {
        float sessionTime = GetGameTime() - g_playerSessionStartTime[client];
        g_playerPlaytime[client] += RoundToFloor(sessionTime);
        g_playerSessionStartTime[client] = 0.0;
    }
    SavePlayerData(client);
    g_dataLoaded[client] = false;
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) { /* не используется */ }

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim   = GetClientOfUserId(event.GetInt("userid"));

    if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && !IsFakeClient(attacker))
    {
        int xp = CheckByClassname(victim);
        if (xp > 0)
            AddXP(attacker, xp);
    }
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_mapChanging && g_cvarPluginEnabled.BoolValue)
    {
        g_mapChanging = true;
        SaveAllPlayerData();
        DebugLog("Round end – all data saved");
    }
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_mapChanging && g_cvarPluginEnabled.BoolValue)
    {
        g_mapChanging = true;
        SaveAllPlayerData();
        DebugLog("Map transition – all data saved");
    }
}

// ----------------------------------------------------------------------------
// Начисление XP
// ----------------------------------------------------------------------------
void AddXP(int client, int xp)
{
    if (!g_cvarPluginEnabled.BoolValue || !g_dataLoaded[client])
        return;

    int dayOfWeek = GetDayOfWeek();
    if (dayOfWeek == 0 || dayOfWeek == 6)
        xp *= 2;

    g_playerXP[client] += xp;

    while (g_playerXP[client] >= GetXPForNextLevel(g_playerLevels[client]))
    {
        int required = GetXPForNextLevel(g_playerLevels[client]);
        g_playerXP[client] -= required;
        g_playerLevels[client]++;

        ClientCommand(client, "play UI/gift_drop.wav");

        int level = g_playerLevels[client];
        if (ShouldAnnounceLevelUp(level))
        {
            if (level % 10 == 0)
            {
                int idx = (level / 10) - 1;
                PrintToChatAll("\x04[Survivor Leveling]\x01 %N has reached level \x04%d\x01 and earned '\x05%s\x01'!", client, level, g_achievementNames[idx]);
            }
            else
            {
                PrintToChatAll("\x04[Survivor Leveling]\x01 %N leveled up to level \x04%d\x01!", client, level);
            }
        }
        SavePlayerData(client);
    }
}

int CheckByClassname(int victim)
{
    if (victim <= 0 || !IsValidEntity(victim))
        return 0;

    char classname[64];
    GetEntityClassname(victim, classname, sizeof(classname));

    char model[PLATFORM_MAX_PATH];
    GetEntPropString(victim, Prop_Data, "m_ModelName", model, sizeof(model));

    if (StrEqual(classname, "infected"))
        return GetRandomInt(XP_REGULAR_MIN, XP_REGULAR_MAX);
    else if (StrEqual(classname, "witch"))
        return XP_WITCH_AS_WORLDSPAWN;
    else if (StrEqual(classname, "tank") || StrContains(model, "tank") != -1)
        return GetRandomInt(XP_BOSS_MIN, XP_BOSS_MAX);
    else if (StrContains(classname, "boomer") != -1 || StrContains(model, "boomer") != -1 ||
             StrContains(classname, "smoker") != -1 || StrContains(model, "smoker") != -1 ||
             StrContains(classname, "hunter") != -1 || StrContains(model, "hunter") != -1 ||
             StrContains(classname, "spitter") != -1 || StrContains(model, "spitter") != -1 ||
             StrContains(classname, "jockey") != -1 || StrContains(model, "jockey") != -1 ||
             StrContains(classname, "charger") != -1 || StrContains(model, "charger") != -1)
        return GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
    else
        return GetRandomInt(XP_REGULAR_MIN, XP_REGULAR_MAX);
}

// ----------------------------------------------------------------------------
// Вспомогательные функции
// ----------------------------------------------------------------------------
void DebugLog(const char[] format, any ...)
{
    if (!g_cvarDebugLogging.BoolValue)
        return;
    char buffer[512];
    VFormat(buffer, sizeof(buffer), format, 2);
    LogToFileEx("logs/levelup_debug.log", "%s", buffer);
}

public void SQL_ErrorCallback(Database db, DBResultSet results, const char[] error, any data)
{
    if (error[0] != '\0')
        LogError("SQL error: %s", error);
}

bool GetSteamIDWithFallback(int client, char[] buffer, int size)
{
    return GetClientAuthId(client, AuthId_Steam2, buffer, size, true) && buffer[0] != '\0';
}

int CalculateIntegrityHash(int level, int xp, int playtime)
{
    return (level * 31337) ^ (xp * 27183) + playtime;
}

int GetXPForNextLevel(int currentLevel)
{
    float xp = float(BASE_XP_PER_LEVEL);
    for (int i = 1; i < currentLevel; i++)
        xp *= XP_MULTIPLIER;
    return RoundToNearest(xp);
}

int GetDayOfWeek()
{
    char s[2];
    FormatTime(s, sizeof(s), "%w", GetTime());
    return StringToInt(s);
}

bool ShouldAnnounceLevelUp(int level)
{
    if (!g_cvarLevelAnnounceMilestonesOnly.BoolValue)
        return true;
    int interval = g_cvarLevelAnnounceMilestoneInterval.IntValue;
    if (interval <= 0) interval = 10;
    return (level % interval) == 0;
}

int GetLeaderboardMaxPlayers(int playerCount)
{
    int limit = g_cvarLeaderboardMaxPlayers.IntValue;
    return (limit <= 0 || limit > playerCount) ? playerCount : limit;
}

void SortPlayerArray(int players[MAX_PLAYERS+1], int count)
{
    for (int i = 0; i < count-1; i++)
        for (int j = 0; j < count-i-1; j++)
            if (g_playerLevels[players[j]] < g_playerLevels[players[j+1]] ||
               (g_playerLevels[players[j]] == g_playerLevels[players[j+1]] && g_playerXP[players[j]] < g_playerXP[players[j+1]]))
            {
                int tmp = players[j];
                players[j] = players[j+1];
                players[j+1] = tmp;
            }
}

// ----------------------------------------------------------------------------
// Меню и команды
// ----------------------------------------------------------------------------
public Action Command_ShowMainMenu(int client, int args)
{
    if (!g_cvarPluginEnabled.BoolValue || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Handled;

    Menu menu = new Menu(MenuHandler_MainMenu);
    menu.SetTitle("★ Player Menu ★");
    menu.AddItem("1", "➤ Your Level & XP");
    menu.AddItem("2", "➤ All Players' Levels");
    menu.AddItem("3", "➤ Leaderboard");
    menu.AddItem("4", "➤ Achievements");
    menu.AddItem("5", "➤ Event Status");
    menu.AddItem("6", "➤ Your Playtime");
    menu.AddItem("7", "➤ All Players' Playtime");
    menu.AddItem("0", "➤ Exit");
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Handled;
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        switch (itemIndex)
        {
            case 0: ShowLevelMenu(client);
            case 1: ShowAllLevelsMenu(client);
            case 2: ShowLeaderboardMenu(client);
            case 3: ShowAchievementsMenu(client);
            case 4: ShowEventStatusMenu(client);
            case 5: ShowPlaytimeMenu(client);
            case 6: ShowAllPlaytimesMenu(client);
        }
    }
    else if (action == MenuAction_End)
        delete menu;
    return 0;
}

void AddBackButton(Menu menu)
{
    menu.AddItem("back", "◄ Back to Main Menu");
}

public int MenuHandler_Generic(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
        if (StrEqual(info, "back"))
        {
            if (g_playtimeTimer != null) { KillTimer(g_playtimeTimer); g_playtimeTimer = null; }
            if (g_allPlaytimesTimer != null) { KillTimer(g_allPlaytimesTimer); g_allPlaytimesTimer = null; }
            Command_ShowMainMenu(client, 0);
        }
    }
    else if (action == MenuAction_End)
        delete menu;
    return 0;
}

void ShowLevelMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Your Level & XP ★");
    char item[128];
    Format(item, sizeof(item), "➤ Level: %d\n➤ XP: %d / %d", g_playerLevels[client], g_playerXP[client], GetXPForNextLevel(g_playerLevels[client]));
    menu.AddItem("", item, ITEMDRAW_DISABLED);
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowAllLevelsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ All Players' Levels ★");
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            char name[64], item[128];
            GetClientName(i, name, sizeof(name));
            int idx = g_selectedAchievement[i];
            if (idx >= 0)
                Format(item, sizeof(item), "➤ [%s] %s: Level %d | XP: %d/%d", g_achievementNames[idx], name, g_playerLevels[i], g_playerXP[i], GetXPForNextLevel(g_playerLevels[i]));
            else
                Format(item, sizeof(item), "➤ %s: Level %d | XP: %d/%d", name, g_playerLevels[i], g_playerXP[i], GetXPForNextLevel(g_playerLevels[i]));
            menu.AddItem("", item, ITEMDRAW_DISABLED);
        }
    }
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowLeaderboardMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Leaderboard ★");

    int players[MAX_PLAYERS+1], count = 0;
    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i))
            players[count++] = i;
    SortPlayerArray(players, count);

    int max = GetLeaderboardMaxPlayers(count);
    for (int i = 0; i < count && i < max; i++)
    {
        int p = players[i];
        char name[64], item[128];
        GetClientName(p, name, sizeof(name));
        int idx = g_selectedAchievement[p];
        if (idx >= 0)
            Format(item, sizeof(item), "➤ %d. [%s] %s - Level %d (XP: %d)", i+1, g_achievementNames[idx], name, g_playerLevels[p], g_playerXP[p]);
        else
            Format(item, sizeof(item), "➤ %d. %s - Level %d (XP: %d)", i+1, name, g_playerLevels[p], g_playerXP[p]);
        menu.AddItem("", item, ITEMDRAW_DISABLED);
    }
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

void ShowAchievementsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Achievements);
    menu.SetTitle("★ Your Achievements ★");
    menu.AddItem("-1", "➤ No Achievement");

    int level = g_playerLevels[client];
    for (int i = 0; i < sizeof(g_achievementNames); i++)
    {
        int reqLevel = (i+1)*10;
        if (level >= reqLevel)
        {
            char item[128];
            Format(item, sizeof(item), "➤ %s (Level %d)", g_achievementNames[i], reqLevel);
            char idx[16];
            IntToString(i, idx, sizeof(idx));
            menu.AddItem(idx, item);
        }
        else break;
    }
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_Achievements(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
        if (StrEqual(info, "back"))
            Command_ShowMainMenu(client, 0);
        else
        {
            int idx = StringToInt(info);
            g_selectedAchievement[client] = idx;
            PrintToChat(client, idx == -1 ? "Achievement display disabled." : "Selected title: %s", g_achievementNames[idx]);
            ShowAchievementsMenu(client);
        }
    }
    else if (action == MenuAction_End)
        delete menu;
    return 0;
}

void ShowEventStatusMenu(int client)
{
    if (g_eventCountdownTimer != null) KillTimer(g_eventCountdownTimer);
    g_eventCountdownTimer = CreateTimer(1.0, Timer_UpdateEventStatus, client, TIMER_REPEAT);
    Timer_UpdateEventStatus(INVALID_HANDLE, client);
}

public Action Timer_UpdateEventStatus(Handle timer, any client)
{
    if (!IsClientInGame(client))
    {
        g_eventCountdownTimer = null;
        return Plugin_Stop;
    }

    Menu menu = new Menu(MenuHandler_EventStatus);
    menu.SetTitle("★ Event Status ★");

    int now = GetTime();
    int dow = GetDayOfWeek();
    char status[256];
    if (dow != 0 && dow != 6)
    {
        int daysToSat = (6 - dow + 7) % 7;
        if (daysToSat == 0) daysToSat = 7;
        int secToday = 86400 - (now % 86400);
        int total = daysToSat * 86400 + secToday;
        int days = total / 86400;
        int hours = (total % 86400) / 3600;
        int mins = (total % 3600) / 60;
        int secs = total % 60;
        Format(status, sizeof(status), "➤ No event.\nNext Double XP starts in:\n%d days, %d hours, %d min, %d sec", days, hours, mins, secs);
    }
    else
    {
        int left = (dow == 6) ? 2 : 1;
        int secsLeft = (left * 86400) - (now % 86400);
        int days = secsLeft / 86400;
        int hours = (secsLeft % 86400) / 3600;
        int mins = (secsLeft % 3600) / 60;
        int secs = secsLeft % 60;
        Format(status, sizeof(status), "➤ Double XP Active!\nTime left:\n%d days, %d hours, %d min, %d sec", days, hours, mins, secs);
    }

    menu.AddItem("refresh", status);
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Continue;
}

public int MenuHandler_EventStatus(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
        if (StrEqual(info, "back"))
        {
            if (g_eventCountdownTimer != null) { KillTimer(g_eventCountdownTimer); g_eventCountdownTimer = null; }
            Command_ShowMainMenu(client, 0);
        }
        else ShowEventStatusMenu(client);
    }
    else if (action == MenuAction_End)
        delete menu;
    return 0;
}

void ShowPlaytimeMenu(int client)
{
    if (g_playtimeTimer != null) KillTimer(g_playtimeTimer);
    g_playtimeTimer = CreateTimer(1.0, Timer_UpdatePlaytime, client, TIMER_REPEAT);
    Timer_UpdatePlaytime(INVALID_HANDLE, client);
}

public Action Timer_UpdatePlaytime(Handle timer, any client)
{
    if (!IsClientInGame(client))
    {
        g_playtimeTimer = null;
        return Plugin_Stop;
    }

    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Your Playtime ★");

    int total = g_playerPlaytime[client];
    if (g_playerSessionStartTime[client] > 0.0)
        total += RoundToFloor(GetGameTime() - g_playerSessionStartTime[client]);

    int days = total / 86400;
    int hours = (total % 86400) / 3600;
    int mins = (total % 3600) / 60;
    int secs = total % 60;

    char text[256];
    Format(text, sizeof(text), "➤ Total Playtime:\n%d days, %d hours, %d minutes, %d seconds", days, hours, mins, secs);
    menu.AddItem("", text, ITEMDRAW_DISABLED);
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Continue;
}

void ShowAllPlaytimesMenu(int client)
{
    if (g_allPlaytimesTimer != null) KillTimer(g_allPlaytimesTimer);
    g_allPlaytimesTimer = CreateTimer(1.0, Timer_UpdateAllPlaytimes, client, TIMER_REPEAT);
    Timer_UpdateAllPlaytimes(INVALID_HANDLE, client);
}

public Action Timer_UpdateAllPlaytimes(Handle timer, any client)
{
    if (!IsClientInGame(client))
    {
        g_allPlaytimesTimer = null;
        return Plugin_Stop;
    }

    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ All Players' Playtime ★");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            char name[64];
            GetClientName(i, name, sizeof(name));
            int total = g_playerPlaytime[i];
            if (g_playerSessionStartTime[i] > 0.0)
                total += RoundToFloor(GetGameTime() - g_playerSessionStartTime[i]);

            int days = total / 86400;
            int hours = (total % 86400) / 3600;
            int mins = (total % 3600) / 60;
            int secs = total % 60;
            char item[256];
            Format(item, sizeof(item), "➤ %s:\n%d days, %d hours, %d minutes, %d seconds", name, days, hours, mins, secs);
            menu.AddItem("", item, ITEMDRAW_DISABLED);
        }
    }
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
    return Plugin_Continue;
}

// ----------------------------------------------------------------------------
// Автосообщения и таймер двойного XP
// ----------------------------------------------------------------------------
void StartAutoMessageTimer()
{
    if (g_autoMessageTimer != null) KillTimer(g_autoMessageTimer);
    float interval = g_cvarAutoMessageInterval.FloatValue;
    if (interval > 0.0)
        g_autoMessageTimer = CreateTimer(interval, AutoMessageTimer, _, TIMER_REPEAT);
}

public Action AutoMessageTimer(Handle timer, any data)
{
    if (g_cvarPluginEnabled.BoolValue)
        PrintToChatAll("\x04[Survivor Leveling]\x01 Use \x05!lv\x01 to view your level, achievements, and event status!");
    return Plugin_Continue;
}

void StartDoubleXPMessageTimer()
{
    if (g_doubleXPMessageTimer != null) KillTimer(g_doubleXPMessageTimer);
    g_doubleXPMessageTimer = CreateTimer(120.0, DoubleXPMessageTimer, _, TIMER_REPEAT);
}

public Action DoubleXPMessageTimer(Handle timer, any data)
{
    int dow = GetDayOfWeek();
    if (dow == 0 || dow == 6)
    {
        if (g_doubleXPEvent == 0) g_doubleXPEvent = 1;
        for (int i = 1; i <= MaxClients; i++)
            if (IsClientInGame(i) && !IsFakeClient(i))
                PrintHintText(i, "Double XP Weekend Active!");
    }
    else g_doubleXPEvent = 0;
    return Plugin_Continue;
}

public void OnAutoMessageIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    StartAutoMessageTimer();
}

// ----------------------------------------------------------------------------
// Обработка чата с титулами
// ----------------------------------------------------------------------------
public Action Command_Say(int client, const char[] command, int args)
{
    return ProcessChatMessage(client, false);
}

public Action Command_SayTeam(int client, const char[] command, int args)
{
    return ProcessChatMessage(client, true);
}

public Action ProcessChatMessage(int client, bool team)
{
    if (!g_cvarPluginEnabled.BoolValue || client <= 0 || !IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Continue;

    int idx = g_selectedAchievement[client];
    if (idx < 0)
        return Plugin_Continue;

    char text[256];
    GetCmdArgString(text, sizeof(text));
    if (text[0] == '"' && text[strlen(text)-1] == '"')
    {
        text[strlen(text)-1] = '\0';
        strcopy(text, sizeof(text), text[1]);
    }

    char message[512];
    if (team)
        Format(message, sizeof(message), "\x01(TEAM) \x05[%s]\x01 %N: %s", g_achievementNames[idx], client, text);
    else
        Format(message, sizeof(message), "\x05[%s]\x01 %N: %s", g_achievementNames[idx], client, text);

    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i) && !IsFakeClient(i) && (!team || GetClientTeam(i) == GetClientTeam(client)))
            PrintToChat(i, "%s", message);

    return Plugin_Handled;
}

// ----------------------------------------------------------------------------
// Завершение работы
// ----------------------------------------------------------------------------
public void OnPluginEnd()
{
    if (g_saveTimer != null) KillTimer(g_saveTimer);
    if (g_autoMessageTimer != null) KillTimer(g_autoMessageTimer);
    if (g_doubleXPMessageTimer != null) KillTimer(g_doubleXPMessageTimer);
    if (g_eventCountdownTimer != null) KillTimer(g_eventCountdownTimer);
    if (g_playtimeTimer != null) KillTimer(g_playtimeTimer);
    if (g_allPlaytimesTimer != null) KillTimer(g_allPlaytimesTimer);

    SaveAllPlayerData();
    if (g_hDatabase != null)
        delete g_hDatabase;
}