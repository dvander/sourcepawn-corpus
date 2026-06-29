#include <sourcemod>
#include <sdktools>

#define BASE_XP_PER_LEVEL 200
#define XP_MULTIPLIER 1.1
#define PLUGIN_VERSION "2.6.1"
#define MAX_PLAYERS 64

#define XP_REGULAR_MIN 5
#define XP_REGULAR_MAX 15
#define XP_SPECIAL_MIN 20
#define XP_SPECIAL_MAX 35
#define XP_BOSS_MIN 40
#define XP_BOSS_MAX 60
#define XP_WITCH_AS_WORLDSPAWN 50

// Add these new lines for the fix
#define MAX_LOAD_ATTEMPTS 5
#define LOAD_RETRY_DELAY 2.0
Handle g_loadRetryTimers[MAX_PLAYERS + 1];
int g_loadAttempts[MAX_PLAYERS + 1];

// New integrity check system
#define MAX_LEVEL_CAP 1000
#define MAX_XP_CAP 1000000
#define INTEGRITY_VERSION 1
bool g_dataLoaded[MAX_PLAYERS + 1];
char g_lastKnownSteamID[MAX_PLAYERS + 1][64];

int g_playerLevels[MAX_PLAYERS + 1];
int g_playerXP[MAX_PLAYERS + 1];
int g_selectedAchievement[MAX_PLAYERS + 1];
int g_doubleXPEvent = 0;

// Variables for playtime tracking
int g_playerPlaytime[MAX_PLAYERS + 1];
float g_playerSessionStartTime[MAX_PLAYERS + 1];

// NEW: Prevent double-save during map change
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
    CreateConVar("levelup_version", PLUGIN_VERSION, "Version of the Level Up Plugin", FCVAR_NOTIFY);
    g_cvarAutoMessageInterval = CreateConVar("levelup_auto_message_interval", "120.0", "Interval for auto messages in seconds", FCVAR_ARCHIVE, true, 10.0, true, 600.0);
    g_cvarPluginEnabled = CreateConVar("levelup_enabled", "1", "Enable or disable the Level Up plugin", FCVAR_ARCHIVE);
    g_cvarDebugLogging = CreateConVar("levelup_debug_logging", "0", "Enable or disable detailed debug logging (0=disabled, 1=enabled)", FCVAR_ARCHIVE);
    g_cvarLeaderboardMaxPlayers = CreateConVar("levelup_leaderboard_max_players", "0", "Maximum players shown on the leaderboard. 0 = show all connected players.", FCVAR_ARCHIVE, true, 0.0, true, 64.0);
    g_cvarLevelAnnounceMilestonesOnly = CreateConVar("levelup_announce_milestones_only", "0", "0 = announce every level up. 1 = only announce milestone levels.", FCVAR_ARCHIVE, true, 0.0, true, 1.0);
    g_cvarLevelAnnounceMilestoneInterval = CreateConVar("levelup_announce_milestone_interval", "10", "Level interval used when milestone-only announcements are enabled. Example: 10 = levels 10, 20, 30.", FCVAR_ARCHIVE, true, 1.0, true, 1000.0);

    HookConVarChange(g_cvarAutoMessageInterval, OnAutoMessageIntervalChanged);
    AutoExecConfig(true, "levelup_plugin");

    EnsureLevelDataFolderExists(); // Ensure the level data folder exists
    
    // Initialize player data arrays
    for (int i = 1; i <= MaxClients; i++) {
        g_dataLoaded[i] = false;
        g_lastKnownSteamID[i][0] = '\0';
    }

    PrintToServer("Level Up Plugin v%s has started successfully!", PLUGIN_VERSION);

    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Post);
    
    // NEW: Save on round end and map transition
    HookEvent("round_end",        Event_RoundEnd,        EventHookMode_PostNoCopy);
    HookEvent("map_transition",   Event_MapTransition,   EventHookMode_PostNoCopy);
    
    // Hook chat processing
    AddCommandListener(Command_SayTeam, "say_team");
    AddCommandListener(Command_Say, "say");

    // Initialize timer handles
    g_saveTimer = INVALID_HANDLE;
    g_autoMessageTimer = INVALID_HANDLE;
    g_doubleXPMessageTimer = INVALID_HANDLE;
    g_eventCountdownTimer = INVALID_HANDLE;
    g_playtimeTimer = INVALID_HANDLE;
    g_allPlaytimesTimer = INVALID_HANDLE;

    // Then create your timers
    g_saveTimer = CreateTimer(60.0, SaveAllPlayerDataTimer, _, TIMER_REPEAT);

    RegConsoleCmd("sm_lv", Command_ShowMainMenu);

    StartDoubleXPMessageTimer();
    StartAutoMessageTimer();
}

// NEW: Save on round end
public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_mapChanging) {
        g_mapChanging = true;
        SaveAllPlayerData();
        DebugLog("Round ended – all player data saved.");
    }
}

// NEW: Save on map transition
public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_mapChanging) {
        g_mapChanging = true;
        SaveAllPlayerData();
        DebugLog("Map transition – all player data saved.");
    }
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

    if (dayOfWeek == 0 || dayOfWeek == 6)  // Saturday or Sunday
    {
        if (g_doubleXPEvent == 0)  // Only set the duration when the event starts
        {
            g_doubleXPEvent = 1;
        }
        
        // Simplified message - removed time remaining
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                PrintHintText(i, "Double XP Weekend Active!");
            }
        }
    }
    else
    {
        g_doubleXPEvent = 0;
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

    PrintToChatAll("\x04[Survivor Leveling]\x01 Use \x05!lv\x01 to view your level, achievements, and event status!");

    return Plugin_Continue;
}

// Main Menu
public Action Command_ShowMainMenu(int client, int args)
{
    if (!g_cvarPluginEnabled.BoolValue)
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
    {
        delete menu;
    }
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
            // Clean up timers when going back
            if (g_playtimeTimer != null)
            {
                KillTimer(g_playtimeTimer);
                g_playtimeTimer = null;
            }
            if (g_allPlaytimesTimer != null)
            {
                KillTimer(g_allPlaytimesTimer);
                g_allPlaytimesTimer = null;
            }
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
    menu.SetTitle("★ Your Level & XP ★");

    int level = g_playerLevels[client];
    int xp = g_playerXP[client];
    int xpNextLevel = GetXPForNextLevel(level);

    char item[128];
    Format(item, sizeof(item), "➤ Level: %d\n➤ XP: %d / %d", level, xp, xpNextLevel);
    menu.AddItem("", item, ITEMDRAW_DISABLED);

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);
}

// All Levels Menu
void ShowAllLevelsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ All Players' Levels ★");

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
                Format(item, sizeof(item), "➤ [%s] %s: Level %d | XP: %d / %d",
                       g_achievementNames[achievementIndex], playerName, level, xp, xpNextLevel);
            }
            else
            {
                Format(item, sizeof(item), "➤ %s: Level %d | XP: %d / %d", playerName, level, xp, xpNextLevel);
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
    menu.SetTitle("★ Leaderboard ★");

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

    int maxShown = GetLeaderboardMaxPlayers(playerCount);
    for (int i = 0; i < playerCount && i < maxShown; i++)
    {
        int player = players[i];
        char playerName[64];
        GetClientName(player, playerName, sizeof(playerName));
        char item[128];
        int achievementIndex = g_selectedAchievement[player];
        if (achievementIndex >= 0)
        {
            Format(item, sizeof(item), "➤ %d. [%s] %s - Level %d (XP: %d)",
                   i + 1, g_achievementNames[achievementIndex], playerName, g_playerLevels[player], g_playerXP[player]);
        }
        else
        {
            Format(item, sizeof(item), "➤ %d. %s - Level %d (XP: %d)",
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
    menu.SetTitle("★ Your Achievements ★");

    // Add option to disable achievement display
    menu.AddItem("-1", "➤ No Achievement");

    int level = g_playerLevels[client];
    for (int i = 0; i < sizeof(g_achievementNames); i++)
    {
        int achievementLevel = (i + 1) * 10;
        if (level >= achievementLevel)
        {
            char item[128];
            Format(item, sizeof(item), "➤ %s (Level %d)", g_achievementNames[i], achievementLevel);
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
            
            if (achievementIndex == -1)
            {
                PrintToChat(client, "You have disabled achievement display in chat.");
            }
            else
            {
                PrintToChat(client, "You have selected the title '%s'", g_achievementNames[achievementIndex]);
            }
            
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
    // Start or restart the countdown timer
    if (g_eventCountdownTimer != null)
    {
        KillTimer(g_eventCountdownTimer);
    }
    g_eventCountdownTimer = CreateTimer(1.0, Timer_UpdateEventStatus, client, TIMER_REPEAT);
    
    // Initial display
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

    char status[256];
    int currentTime = GetTime();
    int dayOfWeek = GetDayOfWeek();
    
    // Calculate time until next Saturday if it's not weekend
    if (dayOfWeek != 0 && dayOfWeek != 6)
    {
        int daysUntilSaturday = (6 - dayOfWeek + 7) % 7;
        if (daysUntilSaturday == 0) daysUntilSaturday = 7;
        
        int secondsInADay = 86400;
        int timeLeftToday = secondsInADay - (currentTime % secondsInADay);
        int totalSecondsUntilEvent = (daysUntilSaturday * secondsInADay) + timeLeftToday;
        
        int days = totalSecondsUntilEvent / 86400;
        int hours = (totalSecondsUntilEvent % 86400) / 3600;
        int minutes = (totalSecondsUntilEvent % 3600) / 60;
        int seconds = totalSecondsUntilEvent % 60;

        Format(status, sizeof(status), "➤ No event running.\nNext Double XP event starts in:\n%d days, %d hours, %d minutes, %d seconds", 
            days, hours, minutes, seconds);
    }
    // If it's weekend (Saturday or Sunday), show remaining time until end of Sunday
    else
    {
        int secondsInDay = 86400;
        int daysUntilEnd = (dayOfWeek == 6) ? 2 : 1; // 2 days if Saturday, 1 if Sunday
        int currentSecondOfDay = currentTime % secondsInDay;
        int totalSecondsLeft = (daysUntilEnd * secondsInDay) - currentSecondOfDay;
        
        int days = totalSecondsLeft / 86400;
        int hours = (totalSecondsLeft % 86400) / 3600;
        int minutes = (totalSecondsLeft % 3600) / 60;
        int seconds = totalSecondsLeft % 60;

        Format(status, sizeof(status), "➤ Double XP Weekend Active!\nTime remaining:\n%d days, %d hours, %d minutes, %d seconds", 
            days, hours, minutes, seconds);
    }

    menu.AddItem("refresh", status);
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Continue;
}

// Add new menu handler for event status
public int MenuHandler_EventStatus(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
        
        if (StrEqual(info, "back"))
        {
            // Kill the countdown timer when going back
            if (g_eventCountdownTimer != null)
            {
                KillTimer(g_eventCountdownTimer);
                g_eventCountdownTimer = null;
            }
            Command_ShowMainMenu(client, 0);
        }
        else if (StrEqual(info, "refresh"))
        {
            ShowEventStatusMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
}

// Show Playtime Menu
void ShowPlaytimeMenu(int client)
{
    // Start or restart the countdown timer
    if (g_playtimeTimer != null)
    {
        KillTimer(g_playtimeTimer);
    }
    g_playtimeTimer = CreateTimer(1.0, Timer_UpdatePlaytime, client, TIMER_REPEAT);
    
    // Initial display
    Timer_UpdatePlaytime(INVALID_HANDLE, client);
}

// Add new timer callback for updating personal playtime
public Action Timer_UpdatePlaytime(Handle timer, any client)
{
    if (!IsClientInGame(client))
    {
        g_playtimeTimer = null;
        return Plugin_Stop;
    }

    Menu menu = new Menu(MenuHandler_Generic);
    menu.SetTitle("★ Your Playtime ★");

    int totalSeconds = g_playerPlaytime[client];
    if (g_playerSessionStartTime[client] > 0.0)
    {
        float sessionTime = GetGameTime() - g_playerSessionStartTime[client];
        totalSeconds += RoundToFloor(sessionTime);
    }

    int days = totalSeconds / 86400;
    int hours = (totalSeconds % 86400) / 3600;
    int minutes = (totalSeconds % 3600) / 60;
    int seconds = totalSeconds % 60;

    char timeString[256];
    Format(timeString, sizeof(timeString), "➤ Total Playtime:\n%d days, %d hours, %d minutes, %d seconds", 
           days, hours, minutes, seconds);

    menu.AddItem("", timeString, ITEMDRAW_DISABLED);
    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Continue;
}

// Show All Players' Playtimes
void ShowAllPlaytimesMenu(int client)
{
    // Start or restart the countdown timer
    if (g_allPlaytimesTimer != null)
    {
        KillTimer(g_allPlaytimesTimer);
    }
    g_allPlaytimesTimer = CreateTimer(1.0, Timer_UpdateAllPlaytimes, client, TIMER_REPEAT);
    
    // Initial display
    Timer_UpdateAllPlaytimes(INVALID_HANDLE, client);
}

// Add new timer callback for updating all players' playtime
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
            char playerName[64];
            GetClientName(i, playerName, sizeof(playerName));

            int totalSeconds = g_playerPlaytime[i];
            if (g_playerSessionStartTime[i] > 0.0)
            {
                float sessionTime = GetGameTime() - g_playerSessionStartTime[i];
                totalSeconds += RoundToFloor(sessionTime);
            }

            int days = totalSeconds / 86400;
            int hours = (totalSeconds % 86400) / 3600;
            int minutes = (totalSeconds % 3600) / 60;
            int seconds = totalSeconds % 60;

            char item[256];
            Format(item, sizeof(item), "➤ %s:\n%d days, %d hours, %d minutes, %d seconds", 
                   playerName, days, hours, minutes, seconds);

            menu.AddItem("", item, ITEMDRAW_DISABLED);
        }
    }

    AddBackButton(menu);
    menu.Display(client, MENU_TIME_FOREVER);

    return Plugin_Continue;
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

int GetLeaderboardMaxPlayers(int playerCount)
{
    int limit = g_cvarLeaderboardMaxPlayers.IntValue;
    if (limit <= 0 || limit > playerCount)
        return playerCount;

    return limit;
}

bool ShouldAnnounceLevelUp(int level)
{
    if (!g_cvarLevelAnnounceMilestonesOnly.BoolValue)
        return true;

    int interval = g_cvarLevelAnnounceMilestoneInterval.IntValue;
    if (interval <= 0)
        interval = 10;

    return (level % interval) == 0;
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
        
        ClientCommand(client, "play UI/gift_drop.wav");

        char message[256];
        int level = g_playerLevels[client];
        if (ShouldAnnounceLevelUp(level))
        {
            if (level % 10 == 0)
            {
                int achievementIndex = (level / 10) - 1;
                Format(message, sizeof(message), "\x04[Survivor Leveling]\x01 %N has leveled up to level \x04%d\x01 and earned the '\x05%s\x01' ACHIEVEMENT!", client, level, g_achievementNames[achievementIndex]);
            }
            else
            {
                Format(message, sizeof(message), "\x04[Survivor Leveling]\x01 Congratulations! %N has leveled up to level \x04%d\x01!", client, level);
            }
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
        PrintToConsole(client, "Awarded %d XP for killing a Common Infected.", xp);
    }
    else if (StrEqual(classname, "witch"))
    {
        xp = XP_WITCH_AS_WORLDSPAWN;
        PrintToConsole(client, "Awarded %d XP for killing a Witch.", xp);
    }
    else if (StrEqual(classname, "tank") || StrContains(model, "tank") != -1 || StrContains(model, "hulk") != -1)
    {
        xp = GetRandomInt(XP_BOSS_MIN, XP_BOSS_MAX);
        PrintToConsole(client, "Awarded %d XP for killing a Tank.", xp);
    }
    else if (StrEqual(classname, "boomer") || StrContains(model, "boomer") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Awarded %d XP for killing a Boomer.", xp);
    }
    else if (StrEqual(classname, "smoker") || StrContains(model, "smoker") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Awarded %d XP for killing a Smoker.", xp);
    }
    else if (StrEqual(classname, "hunter") || StrContains(model, "hunter") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Awarded %d XP for killing a Hunter.", xp);
    }
    else if (StrEqual(classname, "spitter") || StrContains(model, "spitter") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Awarded %d XP for killing a Spitter.", xp);
    }
    else if (StrEqual(classname, "jockey") || StrContains(model, "jockey") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Awarded %d XP for killing a Jockey.", xp);
    }
    else if (StrEqual(classname, "charger") || StrContains(model, "charger") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
        PrintToConsole(client, "Awarded %d XP for killing a Charger.", xp);
    }
    else
    {
        xp = GetRandomInt(XP_REGULAR_MIN, XP_REGULAR_MAX);
        PrintToConsole(client, "Awarded %d XP for killing an unknown entity.", xp);
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
        DebugLog("Failed to load data for %N after %d attempts", client, MAX_LOAD_ATTEMPTS);
        return;
    }
    
    char steamID[64];
    if (!GetSteamIDWithFallback(client, steamID, sizeof(steamID)) || steamID[0] == '\0')
    {
        g_loadAttempts[client]++;
        // Increased retry delay from 1.0 to 3.0 seconds
        g_loadRetryTimers[client] = CreateTimer(3.0, Timer_RetryLoad, client);
        PrintToServer("SteamID not available for %N yet, retry attempt %d scheduled in 3 seconds", client, g_loadAttempts[client]);
        DebugLog("SteamID not available for %N yet, retry attempt %d scheduled in 3 seconds", client, g_loadAttempts[client]);
        return;
    }
    
    // Store the Steam ID for integrity checks
    strcopy(g_lastKnownSteamID[client], sizeof(g_lastKnownSteamID[]), steamID);
    
    PrintToServer("SteamID for %N: %s", client, steamID);
    DebugLog("SteamID for %N: %s", client, steamID);
    LoadPlayerData(client);
}

public Action Timer_RetryLoad(Handle timer, any client)
{
    g_loadRetryTimers[client] = null;
    
    if (!IsClientConnected(client))
    {
        LogMessage("Client %d disconnected before retry could complete", client);
        return Plugin_Stop;
    }
    
    LogMessage("Retrying data load for %N (attempt %d of %d)", client, g_loadAttempts[client] + 1, MAX_LOAD_ATTEMPTS);
    LoadPlayerDataWithRetry(client);
    return Plugin_Stop;
}

char[] FormatSteamIDForFilePath(const char[] steamID)
{
    char result[64];
    strcopy(result, sizeof(result), steamID);
    
    // Replace characters that are problematic in file paths
    ReplaceString(result, sizeof(result), ":", "_");
    ReplaceString(result, sizeof(result), "/", "_");
    ReplaceString(result, sizeof(result), "\\", "_");
    ReplaceString(result, sizeof(result), "?", "_");
    ReplaceString(result, sizeof(result), "*", "_");
    ReplaceString(result, sizeof(result), "\"", "_");
    ReplaceString(result, sizeof(result), "<", "_");
    ReplaceString(result, sizeof(result), ">", "_");
    ReplaceString(result, sizeof(result), "|", "_");
    
    return result;
}

// Add a helper function to get the Steam ID in multiple formats
bool GetSteamIDWithFallback(int client, char[] buffer, int bufferSize)
{
    // Try Steam2 format first (STEAM_X:Y:Z)
    if (GetClientAuthId(client, AuthId_Steam2, buffer, bufferSize, true) && buffer[0] != '\0')
    {
        DebugLog("Got Steam2 ID for %N: %s", client, buffer);
        return true;
    }
    
    // If that fails, try Steam3 format (numeric)
    if (GetClientAuthId(client, AuthId_Steam3, buffer, bufferSize, true) && buffer[0] != '\0')
    {
        DebugLog("Got Steam3 ID for %N: %s", client, buffer);
        return true;
    }
    
    // If that fails too, try SteamID64
    if (GetClientAuthId(client, AuthId_SteamID64, buffer, bufferSize, true) && buffer[0] != '\0')
    {
        DebugLog("Got SteamID64 for %N: %s", client, buffer);
        return true;
    }
    
    DebugLog("Failed to get any Steam ID format for %N", client);
    return false;
}

// New function to calculate data integrity hash
int CalculateIntegrityHash(int level, int xp, int playtime)
{
    // Simple but effective hash that combines the values
    // This will detect if any of these values change unexpectedly
    return ((level * 31337) ^ (xp * 27183)) + playtime;
}

// New function to verify data integrity
bool VerifyDataIntegrity(int client, int level, int xp, int playtime, int storedHash)
{
    int calculatedHash = CalculateIntegrityHash(level, xp, playtime);
    
    if (calculatedHash != storedHash)
    {
        DebugLog("Integrity check failed for %N: Expected hash %d, got %d", client, storedHash, calculatedHash);
        return false;
    }
    
    // Also validate reasonable values
    if (level < 1 || level > MAX_LEVEL_CAP)
    {
        DebugLog("Invalid level value for %N: %d (outside range 1-%d)", client, level, MAX_LEVEL_CAP);
        return false;
    }
    
    if (xp < 0 || xp > MAX_XP_CAP)
    {
        DebugLog("Invalid XP value for %N: %d (outside range 0-%d)", client, xp, MAX_XP_CAP);
        return false;
    }
    
    if (playtime < 0)
    {
        DebugLog("Invalid playtime value for %N: %d (negative)", client, playtime);
        return false;
    }
    
    return true;
}

void LoadPlayerData(int client)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    char steamID[64];
    if (!GetSteamIDWithFallback(client, steamID, sizeof(steamID)) || steamID[0] == '\0')
    {
        PrintToServer("Failed to get Steam ID for player %N", client);
        DebugLog("Failed to get Steam ID for player %N", client);
        return;
    }

    // Format the ID for safe file naming - same as in SavePlayerData
    char formattedID[64];
    strcopy(formattedID, sizeof(formattedID), FormatSteamIDForFilePath(steamID));
    
    // Use BuildPath for a more reliable file path - same as in SavePlayerData
    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof(filePath), "data/level_data/%s.kv", formattedID);
    
    PrintToServer("Loading data for %N from: %s", client, filePath);
    DebugLog("Loading data for %N from: %s (SteamID: %s)", client, filePath, steamID);

    // Check for backup file if main file doesn't exist
    char backupPath[PLATFORM_MAX_PATH];
    Format(backupPath, sizeof(backupPath), "%s.bak", filePath);
    
    if (!FileExists(filePath) && !FileExists(backupPath))
    {
        PrintToServer("No data file exists for %N at path: %s", client, filePath);
        DebugLog("No data file exists for %N at path: %s (SteamID: %s)", client, filePath, steamID);
        g_playerLevels[client] = 1;
        g_playerXP[client] = 0;
        g_selectedAchievement[client] = -1;
        g_playerPlaytime[client] = 0;
        g_dataLoaded[client] = true; // Mark as loaded with default values
        return;
    }

    // Try to load from primary file first
    bool loadedSuccessfully = TryLoadFromFile(client, filePath, steamID);
    
    // If primary file failed, try backup
    if (!loadedSuccessfully && FileExists(backupPath))
    {
        PrintToServer("Trying to load from backup file for %N: %s", client, backupPath);
        DebugLog("Trying to load from backup file for %N: %s", client, backupPath);
        loadedSuccessfully = TryLoadFromFile(client, backupPath, steamID);
        
        if (loadedSuccessfully)
        {
            // If backup loaded successfully, restore it as the main file
            PrintToServer("Restoring backup file for %N", client);
            DebugLog("Restoring backup file for %N", client);
            DeleteFile(filePath);
            CopyFile(backupPath, filePath);
        }
    }
    
    // If both files failed, set default values
    if (!loadedSuccessfully)
    {
        PrintToServer("Failed to load data for %N from both main and backup files, using defaults", client);
        DebugLog("Failed to load data for %N from both main and backup files, using defaults", client);
        g_playerLevels[client] = 1;
        g_playerXP[client] = 0;
        g_selectedAchievement[client] = -1;
        g_playerPlaytime[client] = 0;
    }
    
    g_dataLoaded[client] = true;
}

bool TryLoadFromFile(int client, const char[] filePath, const char[] steamID)
{
    KeyValues kv = new KeyValues("PlayerData");
    
    if (!kv.ImportFromFile(filePath))
    {
        delete kv;
        return false;
    }
    
    // Read values
    int level = kv.GetNum("level", 1);
    int xp = kv.GetNum("xp", 0);
    int achievement = kv.GetNum("achievement", -1);
    int playtime = kv.GetNum("playtime", 0);
    
    // Check integrity
    int storedHash = kv.GetNum("integrity_hash", 0);
    int integrityVersion = kv.GetNum("integrity_version", 0);
    
    // Verify stored Steam ID if available
    char storedSteamID[64];
    kv.GetString("steam_id", storedSteamID, sizeof(storedSteamID), "");
    
    bool dataValid = true;
    
    // If we have a stored integrity hash, verify it
    if (integrityVersion == INTEGRITY_VERSION && storedHash > 0)
    {
        dataValid = VerifyDataIntegrity(client, level, xp, playtime, storedHash);
    }
    
    // Additional check: if we have a stored Steam ID, make sure it matches
    if (dataValid && storedSteamID[0] != '\0' && !StrEqual(storedSteamID, steamID))
    {
        DebugLog("Steam ID mismatch for %N: File has %s but current is %s", 
                client, storedSteamID, steamID);
        dataValid = false;
    }
    
    // If data is valid, use it
    if (dataValid)
    {
        g_playerLevels[client] = level;
        g_playerXP[client] = xp;
        g_selectedAchievement[client] = achievement;
        g_playerPlaytime[client] = playtime;
        
        PrintToServer("Successfully loaded data for player %N: Level %d, XP %d, Playtime %d seconds", 
                     client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
        DebugLog("Successfully loaded data for player %N: Level %d, XP %d, Playtime %d seconds (SteamID: %s)", 
                client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client], steamID);
        
        // Notify player
        PrintToChat(client, "\x04[Survivor Leveling]\x01 Your data has been loaded: Level \x05%d\x01, XP \x05%d\x01", 
                   g_playerLevels[client], g_playerXP[client]);
                   
        delete kv;
        return true;
    }
    
    delete kv;
    return false;
}

// Helper function to copy a file
bool CopyFile(const char[] source, const char[] destination)
{
    File sourceFile = OpenFile(source, "rb");
    if (sourceFile == null)
    {
        return false;
    }
    
    File destFile = OpenFile(destination, "wb");
    if (destFile == null)
    {
        delete sourceFile;
        return false;
    }
    
    int buffer[4096];
    int bytesRead;
    
    while ((bytesRead = sourceFile.Read(buffer, sizeof(buffer), 1)) > 0)
    {
        destFile.Write(buffer, bytesRead, 1);
    }
    
    delete sourceFile;
    delete destFile;
    return true;
}

void SavePlayerData(int client)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;

    if (!IsClientInGame(client) || IsFakeClient(client))
    {
        DebugLog("Not saving data for %d - not in game or is a bot", client);
        return;
    }
    
    // Don't save if data was never properly loaded
    if (!g_dataLoaded[client])
    {
        DebugLog("Not saving data for %N - data was never properly loaded", client);
        return;
    }

    if (g_playerSessionStartTime[client] > 0.0)
    {
        float sessionTime = GetGameTime() - g_playerSessionStartTime[client];
        g_playerPlaytime[client] += RoundToFloor(sessionTime);
        g_playerSessionStartTime[client] = GetGameTime();
    }

    char steamID[64];
    if (!GetSteamIDWithFallback(client, steamID, sizeof(steamID)) || steamID[0] == '\0')
    {
        PrintToServer("Failed to get Steam ID for player %N when saving data", client);
        DebugLog("Failed to get Steam ID for player %N when saving data", client);
        return;
    }
    
    // Verify Steam ID consistency
    if (g_lastKnownSteamID[client][0] != '\0' && !StrEqual(steamID, g_lastKnownSteamID[client]))
    {
        PrintToServer("WARNING: Steam ID changed for %N from %s to %s - not saving data", 
                     client, g_lastKnownSteamID[client], steamID);
        DebugLog("WARNING: Steam ID changed for %N from %s to %s - not saving data", 
                client, g_lastKnownSteamID[client], steamID);
        return;
    }

    // Format the ID for safe file naming
    char formattedID[64];
    strcopy(formattedID, sizeof(formattedID), FormatSteamIDForFilePath(steamID));
    
    // Make sure the directory exists
    EnsureLevelDataFolderExists();
    
    // Use BuildPath for a more reliable file path
    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof(filePath), "data/level_data/%s.kv", formattedID);
    
    PrintToServer("Saving data for %N to: %s", client, filePath);
    DebugLog("Saving data for %N to: %s (SteamID: %s)", client, filePath, steamID);

    // Validate data before saving
    if (g_playerLevels[client] < 1)
    {
        PrintToServer("Warning: Not saving invalid level (%d) for %N", g_playerLevels[client], client);
        DebugLog("Warning: Not saving invalid level (%d) for %N", g_playerLevels[client], client);
        return;
    }
    
    if (g_playerXP[client] < 0 || g_playerXP[client] > MAX_XP_CAP)
    {
        PrintToServer("Warning: Not saving invalid XP (%d) for %N", g_playerXP[client], client);
        DebugLog("Warning: Not saving invalid XP (%d) for %N", g_playerXP[client], client);
        return;
    }

    KeyValues kv = new KeyValues("PlayerData");

    kv.SetNum("level", g_playerLevels[client]);
    kv.SetNum("xp", g_playerXP[client]);
    kv.SetNum("achievement", g_selectedAchievement[client]);
    kv.SetNum("playtime", g_playerPlaytime[client]);
    kv.SetString("steam_id", steamID); // Store the original Steam ID for reference
    
    // Add integrity data
    int integrityHash = CalculateIntegrityHash(g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
    kv.SetNum("integrity_hash", integrityHash);
    kv.SetNum("integrity_version", INTEGRITY_VERSION);
    
    // Store timestamp
    kv.SetNum("last_save_time", GetTime());

    // Create a backup of the existing file if it exists
    if (FileExists(filePath))
    {
        char backupPath[PLATFORM_MAX_PATH];
        Format(backupPath, sizeof(backupPath), "%s.bak", filePath);
        DeleteFile(backupPath); // Remove any existing backup
        RenameFile(backupPath, filePath);
        DebugLog("Created backup of existing data file at %s", backupPath);
    }

    if (kv.ExportToFile(filePath))
    {
        PrintToServer("Data saved successfully for player %N: Level %d, XP %d, Playtime %d seconds", client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
        DebugLog("Data saved successfully for player %N: Level %d, XP %d, Playtime %d seconds (SteamID: %s)", client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client], steamID);
    }
    else
    {
        PrintToServer("Failed to save data for player %N to path: %s", client, filePath);
        DebugLog("Failed to save data for player %N to path: %s (SteamID: %s)", client, filePath, steamID);
        
        // Try to restore from backup if save failed
        char backupPath[PLATFORM_MAX_PATH];
        Format(backupPath, sizeof(backupPath), "%s.bak", filePath);
        if (FileExists(backupPath))
        {
            PrintToServer("Attempting to restore backup file for %N", client);
            DebugLog("Attempting to restore backup file for %N from %s", client, backupPath);
            RenameFile(filePath, backupPath);
        }
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
    if (!g_cvarPluginEnabled.BoolValue || IsFakeClient(client))
        return;

    // Reset client data
    g_playerSessionStartTime[client] = GetGameTime();
    g_loadAttempts[client] = 0;
    g_dataLoaded[client] = false;
    g_lastKnownSteamID[client][0] = '\0';
    
    // Clean up any existing timer just in case
    if (g_loadRetryTimers[client] != null)
    {
        KillTimer(g_loadRetryTimers[client]);
        g_loadRetryTimers[client] = null;
    }
    
    // Create timer to delay initial load - increased from 0.5 to 3.0 seconds
    CreateTimer(3.0, Timer_DelayedLoadData, client);
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
    g_mapChanging = false;  // Re-enable map-end saves
    return Plugin_Continue;
}

public void OnPluginEnd()
{
    if (g_saveTimer != INVALID_HANDLE)
    {
        KillTimer(g_saveTimer);
        g_saveTimer = INVALID_HANDLE;
    }
    
    // Also clean up other timers while we're at it
    if (g_autoMessageTimer != INVALID_HANDLE)
    {
        KillTimer(g_autoMessageTimer);
        g_autoMessageTimer = INVALID_HANDLE;
    }
    
    if (g_doubleXPMessageTimer != INVALID_HANDLE)
    {
        KillTimer(g_doubleXPMessageTimer);
        g_doubleXPMessageTimer = INVALID_HANDLE;
    }
    
    SaveAllPlayerData();
}

void EnsureLevelDataFolderExists()
{
    char dirPath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, dirPath, sizeof(dirPath), "data/level_data");
    
    if (!DirExists(dirPath))
    {
        PrintToServer("Creating level data directory: %s", dirPath);
        CreateDirectory(dirPath, 511); // 511 = full permissions
    }
}

// Remove the Command_Say function and replace with User Message hook
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
    
    // Get the achievement index
    int achievementIndex = g_selectedAchievement[client];
    if (achievementIndex < 0) // No achievement selected or specifically disabled
        return Plugin_Continue; // Let original message flow through
    
    // Get text
    char text[256];
    GetCmdArgString(text, sizeof(text));
    
    // Remove quotes
    if (text[0] == '"' && text[strlen(text)-1] == '"')
    {
        text[strlen(text)-1] = '\0';
        strcopy(text, sizeof(text), text[1]);
    }
    
    // Format with achievement tag in light green (changed from \x04 to \x05)
    char message[512];
    if (team)
    {
        Format(message, sizeof(message), "\x01(TEAM) \x05[%s]\x01 %N: %s", 
            g_achievementNames[achievementIndex], client, text);
    }
    else
    {
        Format(message, sizeof(message), "\x05[%s]\x01 %N: %s", 
            g_achievementNames[achievementIndex], client, text);
    }
    
    // Print message to appropriate clients
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (!team || GetClientTeam(i) == GetClientTeam(client))
            {
                PrintToChat(i, "%s", message);
            }
        }
    }
    
    return Plugin_Handled; // Block original message
}

// Add a debug logging function
void DebugLog(const char[] format, any ...)
{
    if (!g_cvarDebugLogging.BoolValue)
        return;
        
    char buffer[512];
    VFormat(buffer, sizeof(buffer), format, 2);
    
    char logFile[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, logFile, sizeof(logFile), "logs/levelup_debug.log");
    
    LogToFileEx(logFile, "%s", buffer);
}
