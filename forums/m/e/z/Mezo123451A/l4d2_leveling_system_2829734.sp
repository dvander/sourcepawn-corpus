#include <sourcemod>
#include <sdktools>

#define BASE_XP_PER_LEVEL 200
#define XP_MULTIPLIER 1.1
#define PLUGIN_VERSION "2.2.2"
#define MAX_PLAYERS 64

#define XP_REGULAR_MIN 5
#define XP_REGULAR_MAX 15
#define XP_SPECIAL_MIN 20
#define XP_SPECIAL_MAX 35
#define XP_BOSS_MIN 40
#define XP_BOSS_MAX 60
#define XP_WITCH_AS_WORLDSPAWN 50

// Add these new lines for the fix
#define MAX_LOAD_ATTEMPTS 3
Handle g_loadRetryTimers[MAXPLAYERS + 1];
int g_loadAttempts[MAXPLAYERS + 1];

int g_playerLevels[MAX_PLAYERS + 1];
int g_playerXP[MAX_PLAYERS + 1];
int g_selectedAchievement[MAX_PLAYERS + 1];
int g_doubleXPEvent = 0;
float g_doubleXPRemaining = 0.0;

// Variables for playtime tracking
int g_playerPlaytime[MAX_PLAYERS + 1];
float g_playerSessionStartTime[MAX_PLAYERS + 1];

ConVar g_cvarPluginVersion;
ConVar g_cvarAutoMessageInterval;
ConVar g_cvarPluginEnabled;
Handle g_saveTimer;
Handle g_autoMessageTimer;
Handle g_doubleXPMessageTimer;

new String:g_achievementNames[][] = {
    "Newbie",       // Level 10
    "Apprentice",   // Level 20
    "Adept",        // Level 30
    "Journeyman",   // Level 40
    "Expert",       // Level 50
    "Master",       // Level 60
    "Grandmaster",  // Level 70
    "Legend",       // Level 80
    "Mythic",       // Level 90
    "Immortal",     // Level 100
    "Demigod",      // Level 110
    "Conqueror",    // Level 120
    "Hero",         // Level 130
    "Vanquisher",   // Level 140
    "Warlord",      // Level 150
    "Champion",     // Level 160
    "Titan",        // Level 170
    "Phantom",      // Level 180
    "Specter",      // Level 190
    "Eternal",      // Level 200
    "Ascended",     // Level 210
    "Supreme",      // Level 220
    "Invincible",   // Level 230
    "Overlord",     // Level 240
    "Immortal Hero",// Level 250
    "Celestial",    // Level 260
    "Divine",       // Level 270
    "Omnipotent",   // Level 280
    "Ethereal",     // Level 290
    "Godlike",      // Level 300
    "Behemoth",     // Level 310
    "Colossus",     // Level 320
    "Juggernaut",   // Level 330
    "Leviathan",    // Level 340
    "Monolith",     // Level 350
    "Titanic",      // Level 360
    "Goliath",      // Level 370
    "Brutal",       // Level 380
    "Ruthless",     // Level 390
    "Supreme Ruler",// Level 400
    "Infinite",     // Level 410
    "Unstoppable",  // Level 420
    "Inexorable",   // Level 430
    "Indomitable",  // Level 440
    "Relentless",   // Level 450
    "Formidable",   // Level 460
    "Dominator",    // Level 470
    "Perpetual",    // Level 480
    "Immovable",    // Level 490
    "Omniscient",   // Level 500
    "Transcendent", // Level 510
    "Ultimate",     // Level 520
    "Supremacy",    // Level 530
    "Immortal Lord",// Level 540
    "Primordial",   // Level 550
    "Absolute",     // Level 560
    "Unyielding",   // Level 570
    "Sovereign",    // Level 580
    "Overseer",     // Level 590
    "Invincible Ruler", // Level 600
    "Transcendent Hero", // Level 610
    "Immortal Conqueror", // Level 620
    "Supreme Leader", // Level 630
    "Infinite Warrior", // Level 640
    "Godlike Champion", // Level 650
    "Immortal Deity", // Level 660
    "Omnipresent", // Level 670
    "Divine Guardian", // Level 680
    "Supreme Master", // Level 690
    "Eternal Ruler", // Level 700
    "Omniscient Lord", // Level 710
    "Primordial King", // Level 720
    "Absolute Sovereign", // Level 730
    "Unyielding Guardian", // Level 740
    "Eternal Champion", // Level 750
    "Supreme Overlord", // Level 760
    "Immortal Monarch", // Level 770
    "Divine Ruler", // Level 780
    "Infinite Champion", // Level 790
    "Transcendent Sovereign", // Level 800
    "Omnipotent Deity", // Level 810
    "Immortal King", // Level 820
    "Supreme Ruler", // Level 830
    "Godlike Warrior", // Level 840
    "Unstoppable Force", // Level 850
    "Divine Entity", // Level 860
    "Supreme Entity", // Level 870
    "Immortal Titan", // Level 880
    "Infinite Power", // Level 890
    "Omnipotent Champion", // Level 900
    "Godlike Entity", // Level 910
    "Supreme Titan", // Level 920
    "Immortal Entity", // Level 930
    "Infinite Entity", // Level 940
    "Divine Power", // Level 950
    "Omnipotent Ruler", // Level 960
    "Godlike Ruler", // Level 970
    "Supreme Power", // Level 980
    "Immortal Power", // Level 990
    "Infinite Ruler"  // Level 1000
};

public Plugin myinfo = 
{
    name = "Level Up Plugin",
    author = "Mezo123451A",
    description = "A leveling system with random XP rewards based on enemy type",
    version = PLUGIN_VERSION
};

public void OnPluginStart()
{
    g_cvarPluginVersion = CreateConVar("levelup_version", PLUGIN_VERSION, "Version of the Level Up Plugin", FCVAR_NOTIFY);
    g_cvarAutoMessageInterval = CreateConVar("levelup_auto_message_interval", "120.0", "Interval for auto messages in seconds", FCVAR_ARCHIVE, true, 10.0, true, 600.0);
    g_cvarPluginEnabled = CreateConVar("levelup_enabled", "1", "Enable or disable the Level Up plugin", FCVAR_ARCHIVE);

    HookConVarChange(g_cvarAutoMessageInterval, OnAutoMessageIntervalChanged);
    AutoExecConfig(true, "levelup_plugin");

    PrintToServer("Level Up Plugin v%s has started successfully!", PLUGIN_VERSION);

    CreateDirectoryStructure();

    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Post);

    g_saveTimer = CreateTimer(60.0, SaveAllPlayerDataTimer, _, TIMER_REPEAT);

    RegConsoleCmd("sm_lv", Command_ShowMainMenu);

    StartDoubleXPMessageTimer();
    StartAutoMessageTimer();
}

public void OnAutoMessageIntervalChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    StartAutoMessageTimer();
}

void StartDoubleXPMessageTimer()
{
    if (g_doubleXPMessageTimer != INVALID_HANDLE)
    {
        KillTimer(g_doubleXPMessageTimer);
    }

    g_doubleXPMessageTimer = CreateTimer(120.0, DoubleXPMessageTimer, _, TIMER_REPEAT);
}

public Action DoubleXPMessageTimer(Handle timer, any data)
{
    char sDayOfWeek[2];
    FormatTime(sDayOfWeek, sizeof(sDayOfWeek), "%w", GetTime());

    int dayOfWeek = StringToInt(sDayOfWeek);

    if (dayOfWeek == 0 || dayOfWeek == 6)
    {
        g_doubleXPEvent = 1;
        g_doubleXPRemaining = 3600.0; // Example: Double XP event lasts 1 hour
    }
    else
    {
        g_doubleXPEvent = 0;
        g_doubleXPRemaining = 0.0;
    }

    if (g_doubleXPEvent)
    {
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                PrintHintText(i, "[Etkinlik] 2x TP Etkinliği aktif!");
            }
        }
    }

    return Plugin_Continue;
}

void StartAutoMessageTimer()
{
    if (g_autoMessageTimer != INVALID_HANDLE)
    {
        KillTimer(g_autoMessageTimer);
    }

    float interval = g_cvarAutoMessageInterval.FloatValue;
    g_autoMessageTimer = CreateTimer(interval, AutoMessageTimer, _, TIMER_REPEAT);
}

public Action AutoMessageTimer(Handle timer, any data)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return Plugin_Continue;

    PrintToChatAll("\x04[Hayatta Kalma Seviyeleri]\x01 Seviyenizi, başarımlarınızı ve etkinlik durumunu görmek için \x05!lv\x01 yazın!");

    return Plugin_Continue;
}

// Main Menu
public Action Command_ShowMainMenu(int client, int args)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return Plugin_Handled;

    Menu menu = new Menu(MenuHandler_MainMenu);
    menu.SetTitle("★ Oyuncu Menüsü ★");

    menu.AddItem("1", "➤ Seviye & TP Bilgisi");
    menu.AddItem("2", "➤ Tüm Oyuncuların Seviyeleri");
    menu.AddItem("3", "➤ Sıralama");
    menu.AddItem("4", "➤ Başarımlar");
    menu.AddItem("5", "➤ Etkinlik Durumu");
    menu.AddItem("6", "➤ Oynama Süreniz");
    menu.AddItem("7", "➤ Tüm Oyuncuların Süreleri");
    menu.AddItem("0", "➤ Çıkış");

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
    {
        delete menu;
    }
    return 0;
}

void AddBackButton(Menu menu)
{
    menu.AddItem("back", "◄ Ana Menüye Dön");
}

public int MenuHandler_Generic(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
        
        if (StrEqual(info, "back"))
        {
            Command_ShowMainMenu(client, 0);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// Level Menu
void ShowLevelMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Seviye & TP Bilginiz ★");

    int level = g_playerLevels[client];
    int xp = g_playerXP[client];
    int xpNextLevel = GetXPForNextLevel(level);

    char item[128];
    Format(item, sizeof(item), "➤ Seviye: %d\n➤ TP: %d / %d", level, xp, xpNextLevel);
    menu.AddItem("", item, ITEMDRAW_DISABLED);

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

// All Levels Menu
void ShowAllLevelsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Tüm Oyuncuların Seviyeleri ★");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            char playerName[64];
            GetClientName(i, playerName, sizeof(playerName));
            int level = g_playerLevels[i];
            int xp = g_playerXP[i];
            int xpNextLevel = GetXPForNextLevel(level);

            char item[128];
            int achievementIndex = g_selectedAchievement[i];
            if (achievementIndex >= 0)
            {
                Format(item, sizeof(item), "➤ [%s] %s: Seviye %d | TP: %d / %d",
                       g_achievementNames[achievementIndex], playerName, level, xp, xpNextLevel);
            }
            else
            {
                Format(item, sizeof(item), "➤ %s: Seviye %d | TP: %d / %d", playerName, level, xp, xpNextLevel);
            }
            menu.AddItem("", item, ITEMDRAW_DISABLED);
        }
    }

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

// Leaderboard Menu
void ShowLeaderboardMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Sıralama ★");

    int players[MAX_PLAYERS + 1];
    int playerCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            players[playerCount++] = i;
        }
    }

    SortPlayerArray(players, playerCount);

    for (int i = 0; i < playerCount && i < 10; i++)
    {
        int player = players[i];
        char playerName[64];
        GetClientName(player, playerName, sizeof(playerName));
        char item[128];
        int achievementIndex = g_selectedAchievement[player];
        if (achievementIndex >= 0)
        {
            Format(item, sizeof(item), "➤ %d. [%s] %s - Seviye %d (TP: %d)",
                   i + 1, g_achievementNames[achievementIndex], playerName, g_playerLevels[player], g_playerXP[player]);
        }
        else
        {
            Format(item, sizeof(item), "➤ %d. %s - Seviye %d (TP: %d)",
                   i + 1, playerName, g_playerLevels[player], g_playerXP[player]);
        }
        menu.AddItem("", item, ITEMDRAW_DISABLED);
    }

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

// Achievements Menu
void ShowAchievementsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Achievements);
    menu.SetTitle("★ Başarımlarınız ★");

    int level = g_playerLevels[client];
    for (int i = 0; i < sizeof(g_achievementNames); i++)
    {
        int achievementLevel = (i + 1) * 10;
        if (level >= achievementLevel)
        {
            char item[128];
            Format(item, sizeof(item), "➤ %s (Seviye %d)", g_achievementNames[i], achievementLevel);
            menu.AddItem(IntToChar(i), item);
        }
        else
        {
            break;
        }
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
        {
            Command_ShowMainMenu(client, 0);
        }
        else
        {
            int achievementIndex = StringToInt(info);
            g_selectedAchievement[client] = achievementIndex;
            PrintToChat(client, "Seçtiğiniz başarım: '%s'", g_achievementNames[achievementIndex]);
            ShowAchievementsMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// Event Status Menu
void ShowEventStatusMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Etkinlik Durumu ★");

    char status[128];
    if (g_doubleXPEvent)
    {
        Format(status, sizeof(status), "➤ 2x TP Etkinliği aktif!\nKalan süre: %.0f saniye", g_doubleXPRemaining);
    }
    else
    {
        int dayOfWeek = GetDayOfWeek();
        int daysUntilSaturday = (6 - dayOfWeek + 7) % 7;
        if (daysUntilSaturday == 0)
        {
            daysUntilSaturday = 7;
        }

        int currentTime = GetTime();
        int secondsInADay = 86400;
        int timeLeftToday = secondsInADay - (currentTime % secondsInADay);
        int totalSecondsUntilEvent = (daysUntilSaturday * secondsInADay) + timeLeftToday;
        int days = totalSecondsUntilEvent / 86400;
        totalSecondsUntilEvent %= 86400;
        int hours = totalSecondsUntilEvent / 3600;
        totalSecondsUntilEvent %= 3600;
        int minutes = totalSecondsUntilEvent / 60;
        int seconds = totalSecondsUntilEvent % 60;

        Format(status, sizeof(status), "➤ Etkinlik yok.\nSonraki 2x TP etkinliğine: %d gün, %d saat, %d dakika, %d saniye",
               days, hours, minutes, seconds);
    }

    menu.AddItem("", status, ITEMDRAW_DISABLED);
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

// Show Playtime Menu
void ShowPlaytimeMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Oynama Süreniz ★");

    int totalSeconds = g_playerPlaytime[client];
    if (g_playerSessionStartTime[client] > 0.0)
    {
        float sessionTime = GetGameTime() - g_playerSessionStartTime[client];
        totalSeconds += RoundToFloor(sessionTime);
    }

    int hours = totalSeconds / 3600;
    int minutes = (totalSeconds % 3600) / 60;
    int seconds = totalSeconds % 60;

    char timeString[128];
    Format(timeString, sizeof(timeString), "➤ Toplam oynama süreniz: %d saat, %d dakika, %d saniye", hours, minutes, seconds);

    menu.AddItem("", timeString, ITEMDRAW_DISABLED);

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

// Show All Players' Playtimes
void ShowAllPlaytimesMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Tüm Oyuncuların Süreleri ★");

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            char playerName[64];
            GetClientName(i, playerName, sizeof(playerName));

            int totalSeconds = g_playerPlaytime[i];
            if (g_playerSessionStartTime[i] > 0.0)
            {
                float sessionTime = GetGameTime() - g_playerSessionStartTime[i];
                totalSeconds += RoundToFloor(sessionTime);
            }

            int hours = totalSeconds / 3600;
            int minutes = (totalSeconds % 3600) / 60;
            int seconds = totalSeconds % 60;

            char item[128];
            Format(item, sizeof(item), "➤ %s: %d saat, %d dakika, %d saniye", playerName, hours, minutes, seconds);

            menu.AddItem("", item, ITEMDRAW_DISABLED);
        }
    }

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

// Utility Functions
void SortPlayerArray(int players[MAX_PLAYERS + 1], int count)
{
    for (int i = 0; i < count - 1; i++)
    {
        for (int j = 0; j < count - i - 1; j++)
        {
            int playerA = players[j];
            int playerB = players[j + 1];

            if (g_playerLevels[playerA] < g_playerLevels[playerB] ||
                (g_playerLevels[playerA] == g_playerLevels[playerB] && g_playerXP[playerA] < g_playerXP[playerB]))
            {
                int temp = players[j];
                players[j] = players[j + 1];
                players[j + 1] = temp;
            }
        }
    }
}

int GetXPForNextLevel(int currentLevel)
{
    float xpRequired = float(BASE_XP_PER_LEVEL);
    for (int i = 1; i < currentLevel; i++)
    {
        xpRequired *= XP_MULTIPLIER;
    }
    return RoundToNearest(xpRequired);
}

bool IsPlayerHuman(int client)
{
    return GetClientTeam(client) == 2;
}

int GetDayOfWeek()
{
    char sDayOfWeek[2];
    FormatTime(sDayOfWeek, sizeof(sDayOfWeek), "%w", GetTime());

    return StringToInt(sDayOfWeek);
}

char[] IntToChar(int value)
{
    char buffer[16];
    IntToString(value, buffer, sizeof(buffer));
    return buffer;
}

void AddXP(int client, int xp)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    char sDayOfWeek[2];
    FormatTime(sDayOfWeek, sizeof(sDayOfWeek), "%w", GetTime());

    int dayOfWeek = StringToInt(sDayOfWeek);

    if (dayOfWeek == 0 || dayOfWeek == 6)
    {
        xp *= 2;
    }

    g_playerXP[client] += xp;

    while (g_playerXP[client] >= GetXPForNextLevel(g_playerLevels[client]))
    {
        int xpRequired = GetXPForNextLevel(g_playerLevels[client]);
        g_playerXP[client] -= xpRequired;
        g_playerLevels[client]++;

        char message[256];
        int level = g_playerLevels[client];
        if (level % 10 == 0)
        {
            int achievementIndex = (level / 10) - 1;
            Format(message, sizeof(message), "\x04[Hayatta Kalma Seviyeleri]\x01 %N, \x04%d\x01 seviyeye ulaştı ve '\x05%s\x01' BAŞARIMINI kazandı!", client, level, g_achievementNames[achievementIndex]);
            PrintToChatAll(message);
        }
        else
        {
            Format(message, sizeof(message), "\x04[Hayatta Kalma Seviyeleri]\x01 Tebrikler! %N, \x04%d\x01 seviyeye ulaştı!", client, level);
            PrintToChatAll(message);
        }

        SavePlayerData(client);
    }
}

int CheckByClassname(int victim, int client)
{
    char classname[64];
    GetEdictClassname(victim, classname, sizeof(classname));

    char model[PLATFORM_MAX_PATH];
    GetEntPropString(victim, Prop_Data, "m_ModelName", model, sizeof(model));

    int xp = 0;

    if (StrEqual(classname, "infected"))
    {
        xp = GetRandomInt(XP_REGULAR_MIN, XP_REGULAR_MAX);
        PrintToConsole(client, "Sıradan Zombi öldürdüğünüz için %d TP kazandınız.", xp);
    }
    else if (StrEqual(classname, "witch"))
    {
        xp = XP_WITCH_AS_WORLDSPAWN;
        PrintToConsole(client, "Cadı öldürdüğünüz için %d TP kazandınız.", xp);
    }
    else if (StrEqual(classname, "tank") || StrContains(model, "tank") != -1 || StrContains(model, "hulk") != -1)
    {
        xp = GetRandomInt(XP_BOSS_MIN, XP_BOSS_MAX);
        PrintToConsole(client, "Tank öldürdüğünüz için %d TP kazandınız.", xp);
    }
    else if (StrEqual(classname, "boomer") || StrContains(model, "boomer") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Boomer öldürdüğünüz için %d TP kazandınız.", xp);
    }
    else if (StrEqual(classname, "smoker") || StrContains(model, "smoker") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Smoker öldürdüğünüz için %d TP kazandınız.", xp);
    }
    else if (StrEqual(classname, "hunter") || StrContains(model, "hunter") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Hunter öldürdüğünüz için %d TP kazandınız.", xp);
    }
    else if (StrEqual(classname, "spitter") || StrContains(model, "spitter") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Spitter öldürdüğünüz için %d TP kazandınız.", xp);
    }
    else if (StrEqual(classname, "jockey") || StrContains(model, "jockey") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Jockey öldürdüğünüz için %d TP kazandınız.", xp);
    }
    else if (StrEqual(classname, "charger") || StrContains(model, "charger") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Charger öldürdüğünüz için %d TP kazandınız.", xp);
    }
    else
    {
        xp = GetRandomInt(XP_REGULAR_MIN, XP_REGULAR_MAX);
        PrintToConsole(client, "Bilinmeyen bir düşman öldürdüğünüz için %d TP kazandınız.", xp);
    }

    return xp;
}

// New functions for the progress reset fix
public Action Timer_DelayedLoadData(Handle timer, any client)
{
    if (!IsClientInGame(client) || IsFakeClient(client))
        return Plugin_Stop;
        
    LoadPlayerDataWithRetry(client);
    return Plugin_Stop;
}

void LoadPlayerDataWithRetry(int client)
{
    if (g_loadAttempts[client] >= MAX_LOAD_ATTEMPTS)
    {
        PrintToServer("Failed to load data for %N after %d attempts", client, MAX_LOAD_ATTEMPTS);
        return;
    }
    
    char steamID[64];
    if (!GetClientAuthId(client, AuthId_Steam3, steamID, sizeof(steamID), true) || steamID[0] == '\0')
    {
        g_loadAttempts[client]++;
        g_loadRetryTimers[client] = CreateTimer(1.0, Timer_RetryLoad, client);
        return;
    }
    
    LoadPlayerData(client);
}

public Action Timer_RetryLoad(Handle timer, any client)
{
    g_loadRetryTimers[client] = null;
    LoadPlayerDataWithRetry(client);
    return Plugin_Stop;
}

void LoadPlayerData(int client)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    char steamID[64];
    bool authSuccess = GetClientAuthId(client, AuthId_Steam3, steamID, sizeof(steamID), true);

    if (!authSuccess || steamID[0] == '\0')
    {
        PrintToServer("Failed to get Steam ID for player %N, using fallback ID", client);
        Format(steamID, sizeof(steamID), "unknown_%N", client);
    }

    ReplaceString(steamID, sizeof(steamID), "[", "", true);
    ReplaceString(steamID, sizeof(steamID), "]", "", true);
    ReplaceString(steamID, sizeof(steamID), ":", "", true);

    char filePath[PLATFORM_MAX_PATH];
    Format(filePath, sizeof(filePath), "addons/sourcemod/data/level_data/%s.kv", steamID);

    KeyValues kv = new KeyValues("PlayerData");

    if (kv.ImportFromFile(filePath))
    {
        g_playerLevels[client] = kv.GetNum("level", 1);
        g_playerXP[client] = kv.GetNum("xp", 0);
        g_selectedAchievement[client] = kv.GetNum("achievement", -1);
        g_playerPlaytime[client] = kv.GetNum("playtime", 0);
        PrintToServer("Loaded data for player %N: Level %d, XP %d, Playtime %d seconds", client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
    }
    else
    {
        g_playerLevels[client] = 1;
        g_playerXP[client] = 0;
        g_selectedAchievement[client] = -1;
        g_playerPlaytime[client] = 0;
        PrintToServer("No data found for player %N, initializing with default values.", client);
    }

    delete kv;
}

void SavePlayerData(int client)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    if (g_playerSessionStartTime[client] > 0.0)
    {
        float sessionTime = GetGameTime() - g_playerSessionStartTime[client];
        g_playerPlaytime[client] += RoundToFloor(sessionTime);
        g_playerSessionStartTime[client] = GetGameTime();
    }

    char steamID[64];
    bool authSuccess = GetClientAuthId(client, AuthId_Steam3, steamID, sizeof(steamID), true);

    if (!authSuccess || steamID[0] == '\0')
    {
        PrintToServer("Failed to get Steam ID for player %N, using fallback ID", client);
        Format(steamID, sizeof(steamID), "unknown_%N", client);
    }

    ReplaceString(steamID, sizeof(steamID), "[", "", true);
    ReplaceString(steamID, sizeof(steamID), "]", "", true);
    ReplaceString(steamID, sizeof(steamID), ":", "", true);

    char filePath[PLATFORM_MAX_PATH];
    Format(filePath, sizeof(filePath), "addons/sourcemod/data/level_data/%s.kv", steamID);

    KeyValues kv = new KeyValues("PlayerData");

    kv.SetNum("level", g_playerLevels[client]);
    kv.SetNum("xp", g_playerXP[client]);
    kv.SetNum("achievement", g_selectedAchievement[client]);
    kv.SetNum("playtime", g_playerPlaytime[client]);

    if (kv.ExportToFile(filePath))
    {
        PrintToServer("Data saved successfully for player %N: Level %d, XP %d, Playtime %d seconds", client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
    }
    else
    {
        PrintToServer("Failed to save data for player %N", client);
    }

    delete kv;
}

void SaveAllPlayerData()
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            SavePlayerData(i);
        }
    }
}

public void OnClientPutInServer(int client)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    g_playerSessionStartTime[client] = GetGameTime();
    g_loadAttempts[client] = 0;
    
    // Create timer to delay initial load
    CreateTimer(0.5, Timer_DelayedLoadData, client);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && client <= MaxClients && IsClientInGame(client))
    {
        // You can include any necessary code here for when a player spawns
    }
}

public void OnPlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    int client = GetClientOfUserId(event.GetInt("userid"));
    if (client > 0 && client <= MaxClients)
    {
        if (g_loadRetryTimers[client] != null)
        {
            KillTimer(g_loadRetryTimers[client]);
            g_loadRetryTimers[client] = null;
        }
        
        if (g_playerSessionStartTime[client] > 0.0)
        {
            float sessionTime = GetGameTime() - g_playerSessionStartTime[client];
            g_playerPlaytime[client] += RoundToFloor(sessionTime);
            g_playerSessionStartTime[client] = 0.0;
        }

        SavePlayerData(client);
    }
}

public void OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    int victim = GetClientOfUserId(event.GetInt("userid"));

    if (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && IsPlayerHuman(attacker) && GetClientTeam(attacker) <= 2)
    {
        if (!IsFakeClient(attacker))
        {
            int xpAwarded = CheckByClassname(victim, attacker);
            AddXP(attacker, xpAwarded);
        }
    }
}

public Action SaveAllPlayerDataTimer(Handle timer, any data)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return Plugin_Handled;

    SaveAllPlayerData();
    return Plugin_Continue;
}

void CreateDirectoryStructure()
{
    char dirPath[PLATFORM_MAX_PATH];
    Format(dirPath, sizeof(dirPath), "addons/sourcemod/data/level_data/");

    if (!DirExists(dirPath))
    {
        if (CreateDirectory(dirPath, true))
        {
            PrintToServer("Created directory: %s", dirPath);
        }
        else
        {
            PrintToServer("Failed to create directory: %s", dirPath);
        }
    }
}