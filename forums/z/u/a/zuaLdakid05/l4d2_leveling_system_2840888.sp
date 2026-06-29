#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <multicolors>
#include <left4dhooks>

#define BASE_XP_PER_LEVEL 200
#define XP_MULTIPLIER 1.1
#define PLUGIN_VERSION "2.5.3z"
#define MAX_PLAYERS 64

#define XP_REGULAR_MIN 1
#define XP_REGULAR_MAX 50
#define XP_SPECIAL_MIN 100
#define XP_SPECIAL_MAX 500
#define XP_BOSS_MIN 5000
#define XP_BOSS_MAX 10000
#define XP_WITCH_MIN 5000
#define XP_WITCH_MAX 10000
#define	XP_REVIVE_MIN 250
#define XP_REVIVE_MAX 500
#define XP_HEAL_MIN 250
#define XP_HEAL_MAX 500
#define	XP_DEFIB_MIN 500
#define	XP_DEFIB_MAX 1000
#define MAX_LOAD_ATTEMPTS 5
#define LOAD_RETRY_DELAY 2.0
#define MAX_LEVEL_CAP 1000
#define MAX_XP_CAP 1000000
#define INTEGRITY_VERSION 1

Handle g_loadRetryTimers[MAX_PLAYERS + 1];
Handle g_hFFTimer[MAXPLAYERS + 1];

bool g_showXPGain[MAXPLAYERS + 1];
bool g_dataLoaded[MAX_PLAYERS + 1];
bool g_mapChanging = false;

char g_lastKnownSteamID[MAX_PLAYERS + 1][64];

int g_loadAttempts[MAX_PLAYERS + 1];
int g_ffPenaltyBuffer[MAXPLAYERS + 1];
int g_playerLevels[MAX_PLAYERS + 1];
int g_playerXP[MAX_PLAYERS + 1];
int g_selectedAchievement[MAX_PLAYERS + 1];
int g_doubleXPEvent = 0;
int g_playerPlaytime[MAX_PLAYERS + 1];

float g_fNextRespawnTime[MAXPLAYERS+1];
float g_fNextRespawnAllTime;
float g_fNextAirdropTime;
float g_fNextAirstrikeTime[MAXPLAYERS + 1];
float g_playerSessionStartTime[MAX_PLAYERS + 1];
float g_difficultyMultipliers[4] = {0.5, 1.0, 1.5, 3.0};
float g_realismMultiplier = 2.0;

ConVar g_cvarRespawnAllCost;
ConVar g_cvarRespawnAllCooldown;
ConVar g_cvarAirdropCooldown;
ConVar g_cvarAirdropCost;
ConVar g_cvarAirstrikeCooldown;
ConVar g_cvarAirstrikeCrosshairCost;
ConVar g_cvarAirstrikeSelfCost;
ConVar g_cvarRespawnCost;
ConVar g_cvarRespawnCooldown;
ConVar g_cvarPluginEnabled;
ConVar g_cvarDebugLogging;

Handle g_saveTimer;
Handle g_doubleXPMessageTimer;
Handle g_eventCountdownTimer = null;
Handle g_playtimeTimer = null;
Handle g_allPlaytimesTimer = null;

new String:g_achievementNames[][] = {
    "Newbie",      				// Level 10
    "Apprentice",  				// Level 20
    "Survivor",     			// Level 30
    "Hunter",  					// Level 40
    "Adept",      				// Level 50
    "Expert",					// Level 60
    "Master",  					// Level 70
    "Grandmaster",     			// Level 80
    "Legend",      				// Level 90
    "Mythic",     				// Level 100
    "Conqueror",      			// Level 110
    "Vanquisher",    			// Level 120
    "Champion",        			// Level 130
    "Warlord",   				// Level 140
    "Hero",      				// Level 150
    "Gravewalker",     			// Level 160
    "Wasteland Avenger",   		// Level 170
    "Phantom",      			// Level 180
    "Specter",      			// Level 190
    "The Scourge",      		// Level 200
    "Ascended",     			// Level 210
    "Dominus",      			// Level 220
    "Titan",   					// Level 230
    "Invincible",     			// Level 240
    "Overlord",					// Level 250
    "Godlike",    				// Level 260
    "Divine",       			// Level 270
    "Celestial",   				// Level 280
    "Omnipotent",    			// Level 290
    "Eternal",      			// Level 300
    "Behemoth",     			// Level 310
    "Colossus",    			 	// Level 320
    "Juggernaut",   			// Level 330
    "Leviathan",    			// Level 340
    "Monolith",    			 	// Level 350
    "Megaton",     				// Level 360
    "Goliath",      			// Level 370
    "Brutal",      				// Level 380
    "Ruthless",     			// Level 390
    "Dauntless",				// Level 400
    "Formidable",     			// Level 410
    "Relentless",  				// Level 420
    "Unstoppable",   			// Level 430
    "Indomitable",  			// Level 440
    "The Purger",   			// Level 450
    "Dominator",   				// Level 460
    "Tyrant",    				// Level 470
    "High Tyrant",    			// Level 480
    "Warbringer",    			// Level 490
    "Dread Commander",   		// Level 500
    "Transcendent", 			// Level 510
    "Ultimate",     			// Level 520
    "Supremacy",    			// Level 530
    "Immortal Lord",			// Level 540
    "Primordial",   			// Level 550
    "Absolute",     			// Level 560
    "Unyielding",   			// Level 570
    "Sovereign",    			// Level 580
    "Overseer",     			// Level 590
    "Invincible Ruler", 		// Level 600
    "Transcendent Hero", 		// Level 610
    "Immortal Conqueror", 		// Level 620
    "Supreme Leader", 			// Level 630
    "Infinite Warrior", 		// Level 640
    "Godlike Champion", 		// Level 650
    "Immortal Deity", 			// Level 660
    "Omnipresent", 				// Level 670
    "Divine Guardian", 			// Level 680
    "Supreme Master", 			// Level 690
    "Eternal Ruler", 			// Level 700
    "Omniscient Lord", 			// Level 710
    "Primordial King", 			// Level 720
    "Absolute Sovereign", 		// Level 730
    "Unyielding Guardian", 		// Level 740
    "Eternal Champion", 		// Level 750
    "Supreme Overlord", 		// Level 760
    "Immortal Monarch", 		// Level 770
    "Divine Ruler", 			// Level 780
    "Infinite Champion", 		// Level 790
    "Transcendent Sovereign", 	// Level 800
    "Omnipotent Deity", 		// Level 810
    "Immortal King", 			// Level 820
    "Supreme Ruler", 			// Level 830
    "Godlike Warrior", 			// Level 840
    "Unstoppable Force", 		// Level 850
    "Divine Entity", 			// Level 860
    "Supreme Entity", 			// Level 870
    "Immortal Titan", 			// Level 880
    "Infinite Power", 			// Level 890
    "Guardian", 				// Level 900
    "Sentinel", 				// Level 910
    "Protector", 				// Level 920
    "Heart of Lion", 			// Level 930
    "Guidance Flame", 			// Level 940
    "Shield of the Living", 	// Level 950
    "Warden of Hope", 			// Level 960
    "Dawnbringer", 				// Level 970
    "Harbinger of Light",		// Level 980
    "Reclaimer of Life", 		// Level 990
    "Savior of Mankind"  		// Level 1000
};

public Plugin myinfo = 
{
    name = "Suvivor Leveling System",
    author = "Mezo123451A (Modified by zuaL)",
    description = "A leveling system with random XP rewards based on enemy type",
    version = PLUGIN_VERSION
};

public void OnPluginStart()
{
	RegConsoleCmd("sm_lv", Command_ShowMainMenu);
    RegConsoleCmd("sm_xp", Command_ToggleXP, "Toggle XP gain messages on/off");
	RegConsoleCmd("sm_supply", Command_Airdrop);
	RegConsoleCmd("sm_reinforce", Command_Respawn, "Spend XP to respawn");
	RegConsoleCmd("sm_reinforcement", Command_RespawnAll, "Spend XP to respawn all");
	
	CreateConVar("levelup_version", PLUGIN_VERSION, "Version of the Level Up Plugin", FCVAR_NOTIFY);
	
    g_cvarPluginEnabled = CreateConVar("levelup_enabled", "1", "Enable or disable the Level Up plugin", FCVAR_ARCHIVE);
    g_cvarDebugLogging = CreateConVar("levelup_debug_logging", "0", "Enable or disable detailed debug logging (0=disabled, 1=enabled)", FCVAR_ARCHIVE);
	g_cvarAirdropCost = CreateConVar("sm_supply_cost", "1000", "XP cost to call an airdrop", FCVAR_ARCHIVE, true, 1.0);
	g_cvarAirdropCooldown = CreateConVar("sm_supply_cooldown", "60", "Cooldown in seconds between airdrops", FCVAR_ARCHIVE, true, 1.0);
	g_cvarAirstrikeCrosshairCost = CreateConVar("sm_airstrikecrosshair_cost", "1000", "XP cost for airstrike at crosshair", FCVAR_ARCHIVE, true, 1.0);
    g_cvarAirstrikeSelfCost = CreateConVar("sm_airstrikeself_cost", "1000", "XP cost for airstrike on self", FCVAR_ARCHIVE, true, 1.0);
	g_cvarAirstrikeCooldown = CreateConVar("sm_airstrike_cooldown", "60.0", "Cooldown time (seconds) between airstrikes", FCVAR_ARCHIVE, true, 1.0);
	g_cvarRespawnCost = CreateConVar("sm_respawn_cost", "1000", "XP cost to respawn", FCVAR_ARCHIVE, true, 1.0);
	g_cvarRespawnCooldown = CreateConVar("sm_respawn_cooldown", "60.0", "Cooldown time in seconds for self-reinforce", FCVAR_NOTIFY, true, 0.0);
	g_cvarRespawnAllCost = CreateConVar("sm_respawnall_cost", "1000", "XP cost to respawn all dead teammates", FCVAR_ARCHIVE, true, 1.0);
	g_cvarRespawnAllCooldown = CreateConVar("sm_respawnall_cooldown", "60.0", "Cooldown (seconds) for respawn all", FCVAR_ARCHIVE, true, 1.0);
	
	g_fNextAirdropTime = 0.0;
	g_fNextRespawnAllTime = 0.0;
	
	HookEvent("player_hurt", Event_PlayerHurt);
	HookEvent("witch_killed", Event_WitchKilled, EventHookMode_Post);
	HookEvent("revive_success", Event_ReviveSuccess, EventHookMode_Post);
	HookEvent("heal_success", Event_HealSuccess, EventHookMode_Post);
	HookEvent("defibrillator_used", Event_DefibUsed, EventHookMode_Post);
    HookEvent("player_death", OnPlayerDeath, EventHookMode_Post);
    HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
    HookEvent("player_disconnect", OnPlayerDisconnect, EventHookMode_Post);
	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("map_transition", Event_MapTransition, EventHookMode_PostNoCopy);
	
	HookConVarChange(FindConVar("z_difficulty"), OnDifficultyChanged);
    
	AutoExecConfig(true, "levelup_plugin");
	
	EnsureLevelDataFolderExists();
    for (int i = 1; i <= MaxClients; i++) 
	{
        g_dataLoaded[i] = false;
        g_lastKnownSteamID[i][0] = '\0';
    }
    PrintToServer("Player Level version %s has started successfully!", PLUGIN_VERSION);
    
	AddCommandListener(Command_SayTeam, "say_team");
    AddCommandListener(Command_Say, "say");
	
    g_saveTimer = INVALID_HANDLE;
    g_doubleXPMessageTimer = INVALID_HANDLE;
    g_eventCountdownTimer = INVALID_HANDLE;
    g_playtimeTimer = INVALID_HANDLE;
    g_allPlaytimesTimer = INVALID_HANDLE;
    g_saveTimer = CreateTimer(60.0, SaveAllPlayerDataTimer, _, TIMER_REPEAT);
	
	CreateTimer(1.0, Timer_CheckReady, _, TIMER_REPEAT);
	
    StartDoubleXPMessageTimer();
}

public Action Timer_CheckReady(Handle timer, any data)
{
    float currentTime = GetEngineTime();
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client) || IsFakeClient(client))
            continue;
        if (g_fNextAirstrikeTime[client] > 0.0 && currentTime >= g_fNextAirstrikeTime[client])
        {
            g_fNextAirstrikeTime[client] = 0.0;
            CPrintToChat(client, "{olive}[Z4D2] {orange}Airstrike is now available!");
        }
	}
	if (g_fNextAirdropTime > 0.0 && currentTime >= g_fNextAirdropTime)
    {
        g_fNextAirdropTime = 0.0;
        CPrintToChatAll("{olive}[Z4D2] {orange}Supply is now available!");
    }
	if (g_fNextRespawnAllTime > 0.0 && currentTime >= g_fNextRespawnAllTime)
	{
		g_fNextRespawnAllTime = 0.0;
		CPrintToChatAll("{olive}[Z4D2] {orange}Reinforcement is now available!");
	}
    return Plugin_Continue;
}

void StartDoubleXPMessageTimer()
{
    if (g_doubleXPMessageTimer != INVALID_HANDLE)
    {
        KillTimer(g_doubleXPMessageTimer);
    }
    g_doubleXPMessageTimer = CreateTimer(180.0, DoubleXPMessageTimer, _, TIMER_REPEAT);
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
        
        for (int i = 1; i <= MaxClients; i++)
        {
            if (IsClientInGame(i) && !IsFakeClient(i))
            {
                //CPrintToChat(i, "{olive}[Z4D2] {default}XP boost weekend activated!");
            }
        }
    }
    else
    {
        g_doubleXPEvent = 0;
    }
    return Plugin_Continue;
}

public Action Command_ShowMainMenu(int client, int args)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return Plugin_Handled;

    Menu menu = new Menu(MenuHandler_MainMenu);
    menu.SetTitle("★ Player Menu ★");
    menu.AddItem("level", "➤ Level & XP");
    menu.AddItem("alllevels", "➤ Players");
    menu.AddItem("leaderboard", "➤ Leaderboard");
    menu.AddItem("achievements", "➤ Achievements");
    menu.AddItem("playtime", "➤ Playtime");
	menu.AddItem("respawn", "➤ Reinforce Self");
	menu.AddItem("respawnall", "➤ Reinforce Team");
	menu.AddItem("airdrop", "➤ Call Supply");
	menu.AddItem("airstrike", "➤ Call Airstrike");
	menu.AddItem("togglexp", "➤ Announcement Toggle");
    menu.AddItem("exit", "➤ Exit");

    menu.Display(client, 10);
    return Plugin_Handled;
}

public int MenuHandler_MainMenu(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
		char info[32];
		menu.GetItem(itemIndex, info, sizeof(info));
		if (StrEqual(info, "level")) ShowLevelMenu(client);
		else if (StrEqual(info, "alllevels")) ShowAllLevelsMenu(client);
        else if (StrEqual(info, "leaderboard")) ShowLeaderboardMenu(client);
        else if (StrEqual(info, "achievements")) ShowAchievementsMenu(client);
        else if (StrEqual(info, "playtime")) ShowPlaytimeMenu(client);
        else if (StrEqual(info, "respawn")) ShowRespawnConfirmMenu(client);
        else if (StrEqual(info, "respawnall")) ShowRespawnAllConfirmMenu(client);
        else if (StrEqual(info, "airdrop")) ShowAirdropConfirmMenu(client);
        else if (StrEqual(info, "airstrike")) ShowAirstrikeTypeMenu(client);
		else if (StrEqual(info, "togglexp"))
		{
            g_showXPGain[client] = !g_showXPGain[client];

            if (g_showXPGain[client])
                CPrintToChat(client, "{olive}[Z4D2] {orange}XP Announcement {lightgreen}Enabled{default}.");
            else
                CPrintToChat(client, "{olive}[Z4D2] {orange}XP Announcement {red}Disabled{default}.");
        }
        else if (StrEqual(info, "exit")) return 0;
    }
    else if (action == MenuAction_End)
    {
		if (g_playtimeTimer != null)
		{
			KillTimer(g_playtimeTimer);
			g_playtimeTimer = null;
		}
        delete menu;
    }
    return 0;
}

public int MenuHandler_Generic(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
		if (StrEqual(info, "airdrop"))
		{
			ShowAirdropConfirmMenu(client);
		}
		else if (StrEqual(info, "airstrike_crosshair"))
		{
			ShowAirstrikeConfirmMenu(client, true);
		}
		else if (StrEqual(info, "airstrike_self"))
		{
			ShowAirstrikeConfirmMenu(client, false);
		}
		else if (StrEqual(info, "respawn"))
        {
            ShowRespawnConfirmMenu(client);
        }
		else if (StrEqual(info, "respawnall"))
		{
			ShowRespawnAllConfirmMenu(client);
		}
        else if (StrEqual(info, "back"))
			{
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

void AddBackButton(Menu menu)
{
    menu.AddItem("back", "◄ Back to Main Menu");
}

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
    menu.Display(client, 10);
}

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
    menu.Display(client, 10);
}

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
    for (int i = 0; i < playerCount && i < 10; i++)
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
    menu.Display(client, 10);
}

void ShowAchievementsMenu(int client)
{
    Menu menu = new Menu(MenuHandler_Achievements);
    menu.SetTitle("★ Your Achievements ★");
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
    menu.AddItem("back", "◄ Back to Main Menu");
    menu.Display(client, 10);
}

void ShowAirdropConfirmMenu(int client)
{
    Menu confirm = new Menu(MenuHandler_AirdropConfirm);
	char title[64];
    Format(title, sizeof(title), "Call an airdrop?");
    confirm.SetTitle(title);
    confirm.AddItem("yes", "Yes");
    confirm.AddItem("no", "No");
    confirm.Display(client, 10);
}

public int MenuHandler_AirdropConfirm(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));

        if (StrEqual(info, "yes"))
        {
            Command_Airdrop(client, 0);
        }
        else if (StrEqual(info, "no"))
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

void ShowAirstrikeTypeMenu(int client)
{
    Menu menu = new Menu(MenuHandler_AirstrikeType);
    menu.SetTitle("★ Choose Airstrike Type ★");

    menu.AddItem("crosshair", "➤ At Crosshair");
    menu.AddItem("self", "➤ On Yourself");
    menu.AddItem("back", "◄ Back to Main Menu");

    menu.Display(client, 10);
}

public int MenuHandler_AirstrikeType(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));

        if (StrEqual(info, "crosshair"))
        {
            ShowAirstrikeConfirmMenu(client, true);
        }
        else if (StrEqual(info, "self"))
        {
            ShowAirstrikeConfirmMenu(client, false);
        }
        else if (StrEqual(info, "back"))
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

void ShowAirstrikeConfirmMenu(int client, bool atCrosshair)
{
    Menu confirm = new Menu(MenuHandler_AirstrikeConfirm);
    char title[64];
	Format(title, sizeof(title), "Call Airstrike %s?", atCrosshair ? "at crosshair" : "on yourself");
    confirm.SetTitle(title);
    confirm.AddItem(atCrosshair ? "crosshair" : "self", "Yes");
    confirm.AddItem("no", "No");
    confirm.Display(client, 10);
}

public int MenuHandler_AirstrikeConfirm(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));

        if (StrEqual(info, "crosshair"))
        {
            Command_CallAirstrike(client, 1);
        }
        else if (StrEqual(info, "self"))
        {
            Command_CallAirstrike(client, 2);
        }
        else if (StrEqual(info, "no"))
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

public void Command_CallAirstrike(int client, int type)
{
	if (!IsPlayerAlive(client))
    {
        CPrintToChat(client, "{olive}[Z4D2] {default}You must be alive to call an airstrike!");
        return;
    }
    float currentTime = GetEngineTime();
    float cooldown = g_cvarAirstrikeCooldown.FloatValue;
    if (currentTime < g_fNextAirstrikeTime[client])
    {
        int remaining = RoundToCeil(g_fNextAirstrikeTime[client] - currentTime);
        CPrintToChat(client, "{olive}[Z4D2] {default}Airstrike is on cooldown! ({lightgreen}%d seconds{default}).", remaining);
        return;
    }
    int cost = (type == 1) ? g_cvarAirstrikeCrosshairCost.IntValue : g_cvarAirstrikeSelfCost.IntValue;
    if (g_playerXP[client] < cost)
    {
        CPrintToChat(client, "{olive}[Z4D2] {default}You need {lightgreen}%d XP {default}to call an airstrike! (Current: {orange}%d XP)", cost, g_playerXP[client]);
        return;
    }
    g_playerXP[client] -= cost;
    SavePlayerData(client);
    g_fNextAirstrikeTime[client] = currentTime + cooldown;
    char command[64];
    Format(command, sizeof(command), "sm_strikes #%d %d", GetClientUserId(client), type);
    ServerCommand(command);
    CPrintToChatAll("{olive}[Z4D2] {blue}%N {default}has called an airstrike!", client);
}

public void RespawnAtTeammate(int client)
{
    int team = GetClientTeam(client);
    int teammates[MAXPLAYERS + 1];
    int count = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (i != client && IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team)
        {
            teammates[count++] = i;
        }
    }
    if (count > 0)
    {
        int randomIndex = GetRandomInt(0, count - 1);
        int target = teammates[randomIndex];
        float origin[3];
        GetClientAbsOrigin(target, origin);
        L4D_RespawnPlayer(client);
        TeleportEntity(client, origin, NULL_VECTOR, NULL_VECTOR);
        CPrintToChat(client, "{olive}[Z4D2] {default}You reinforced near {blue}%N{default}.", target);
    }
    else
    {
        CPrintToChat(client, "{olive}[Z4D2] {default}You must reinforce near teammates!");
    }
}

void ShowRespawnConfirmMenu(int client)
{
    Menu confirm = new Menu(MenuHandler_RespawnConfirm);
    char title[64];
    Format(title, sizeof(title), "Reinforce?");
    confirm.SetTitle(title);
    confirm.AddItem("yes", "Yes");
    confirm.AddItem("no", "No");
    confirm.Display(client, 10);
}

public int MenuHandler_RespawnConfirm(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
        if (StrEqual(info, "yes"))
        {
            Command_Respawn(client, 0);
        }
        else if (StrEqual(info, "no"))
        {
            ShowLevelMenu(client);
        }
    }
    else if (action == MenuAction_End)
    {
        delete menu;
    }
    return 0;
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
				CPrintToChat(client, "{olive}[Z4D2] {default}You have {red}disabled{default} achievement display in chat");
            }
            else
            {
				CPrintToChat(client, "{olive}[Z4D2] {default}You have selected the title {orange}%s{default}",
					g_achievementNames[achievementIndex]);
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

void ShowRespawnAllConfirmMenu(int client)
{
    Menu confirm = new Menu(MenuHandler_RespawnAllConfirm);

    char title[64];
    Format(title, sizeof(title), "Call Reinforcement?");
    confirm.SetTitle(title);
    confirm.AddItem("yes", "Yes");
    confirm.AddItem("no", "No");
    confirm.Display(client, 10);
}

public int MenuHandler_RespawnAllConfirm(Menu menu, MenuAction action, int client, int itemIndex)
{
    if (action == MenuAction_Select)
    {
        char info[32];
        menu.GetItem(itemIndex, info, sizeof(info));
        if (StrEqual(info, "yes"))
        {
            Command_RespawnAll(client, 0);
        }
        else if (StrEqual(info, "no"))
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

public Action Command_RespawnAll(int client, int args)
{
    if (!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{olive}[Z4D2] {default}You must be alive to call reinforcement!");
		return Plugin_Handled;
	}
	float currentTime = GetEngineTime();
    float cooldown = g_cvarRespawnAllCooldown.FloatValue;
    if (currentTime < g_fNextRespawnAllTime)
    {
        int remaining = RoundToCeil(g_fNextRespawnAllTime - currentTime);
        CPrintToChat(client, "{olive}[Z4D2] {default}Reinforcement is on cooldown! ({lightgreen}%d seconds{default}).", remaining);
        return Plugin_Handled;
    }
    int cost = g_cvarRespawnAllCost.IntValue;
    if (g_playerXP[client] < cost)
    {
        CPrintToChat(client, "{olive}[Z4D2] {default}You need {lightgreen}%d XP {default}to reinforce teammates! (Current: {orange}%d XP)", cost, g_playerXP[client]);
        return Plugin_Handled;
    }
    int team = GetClientTeam(client);
    bool respawned = false;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsPlayerAlive(i) && GetClientTeam(i) == team)
        {
            RespawnAtTeammate(i);
            respawned = true;
        }
    }
    if (respawned)
    {
		g_playerXP[client] -= cost;
        SavePlayerData(client);
        g_fNextRespawnAllTime = currentTime + cooldown;
        CPrintToChatAll("{olive}[Z4D2] {blue}%N {default}has called for reinforcement!", client);
    }
    else
    {
        CPrintToChat(client, "{olive}[Z4D2] {default}No teammates are available!");
    }
	return Plugin_Handled;
}

void ShowEventStatusMenu(int client)
{
    if (g_eventCountdownTimer != null)
    {
        KillTimer(g_eventCountdownTimer);
    }
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
    char status[256];
    int currentTime = GetTime();
    int dayOfWeek = GetDayOfWeek();
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
    menu.Display(client, 10);
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

void ShowPlaytimeMenu(int client)
{
    if (g_playtimeTimer != null)
    {
        KillTimer(g_playtimeTimer);
		g_playtimeTimer = null;
    }
        Timer_UpdatePlaytime(INVALID_HANDLE, client);
		g_playtimeTimer = CreateTimer(1.0, Timer_UpdatePlaytime, client, TIMER_REPEAT);
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
    menu.Display(client, 10);
    return Plugin_Continue;
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
    menu.Display(client, 10);
    return Plugin_Continue;
}

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

bool IsValidHuman(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client));
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client));
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

int GetDifficultyIndex()
{
    static ConVar z_difficulty = null;
    if (z_difficulty == null)
    {
        z_difficulty = FindConVar("z_difficulty");
    }

    char diff[16];
    z_difficulty.GetString(diff, sizeof(diff));

    if (StrEqual(diff, "Easy", false))    return 0;
    if (StrEqual(diff, "Normal", false))  return 1;
    if (StrEqual(diff, "Hard", false))    return 2; // Advanced
    if (StrEqual(diff, "Impossible", false)) return 3; // Expert

    return 1; // Default to Normal if unknown
}

bool IsRealismMode()
{
    static char mode[64];
    GetConVarString(FindConVar("mp_gamemode"), mode, sizeof(mode));
    return StrContains(mode, "realism", false) != -1;
}

void AddXP(int client, int xp)
{
    if (!g_cvarPluginEnabled.BoolValue)
        return;
	if (!IsValidHuman(client))
		return;
	float totalXP = float(xp);
	char sDayOfWeek[2];
    FormatTime(sDayOfWeek, sizeof(sDayOfWeek), "%w", GetTime());
    int dayOfWeek = StringToInt(sDayOfWeek);
    if (dayOfWeek == 0 || dayOfWeek == 6)
    {
        totalXP *= 2.0;
    }
	int diffIndex = GetDifficultyIndex();
    totalXP *= g_difficultyMultipliers[diffIndex];
	if (IsRealismMode())
    {
        totalXP *= g_realismMultiplier;
    }
	xp = RoundToNearest(totalXP);
	if (g_showXPGain[client])
	{
		CPrintToChat(client, "{orange}[XP] {default}You gained {lightgreen}%d {default}XP", xp);
	}
	g_playerXP[client] += xp;
    while (g_playerXP[client] >= GetXPForNextLevel(g_playerLevels[client]))
    {
        int xpRequired = GetXPForNextLevel(g_playerLevels[client]);
        g_playerXP[client] -= xpRequired;
        g_playerLevels[client]++;
        ClientCommand(client, "play UI/gift_drop.wav");
        int level = g_playerLevels[client];
        int achievementIndex = (level / 10) - 1;
		if (level % 10 == 0 && achievementIndex >= 0)
        {
            CPrintToChatAll("{olive}[Z4D2] {blue}%N {default}has leveled up to {orange}%d {default}and earned the '{orange}%s{default}' ACHIEVEMENT!",
                client, level, g_achievementNames[achievementIndex]);
        }
        else
        {
			CPrintToChatAll("{olive}[Z4D2] {blue}%N {default}has leveled up to {orange}%d{default}!",
                client, level);
        }
        SavePlayerData(client);
    }
}

public void OnDifficultyChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    int diffIndex = GetDifficultyIndex();
    float multiplier = g_difficultyMultipliers[diffIndex];

    char difficultyName[16];
    convar.GetString(difficultyName, sizeof(difficultyName));

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            CPrintToChat(i, "{olive}[Z4D2] {default}Difficulty: {orange}%s{default}. XP Multiplied Bonus: {lightgreen}%.1f{default}.", difficultyName, multiplier);
        }
    }
		if (IsRealismMode())
	{
		multiplier *= g_realismMultiplier;
		CPrintToChatAll("{olive}[Z4D2] {orange}Realism Mode{default}. XP Multiplied Bonus: {lightgreen}%.1f{default}.", multiplier);
	}
}

public void Event_ReviveSuccess(Event event, const char[] name, bool dontBroadcast)
{
    int reviver = GetClientOfUserId(event.GetInt("userid"));
    int patient = GetClientOfUserId(event.GetInt("subject"));

    if (!IsClientInGame(reviver) || !IsClientInGame(patient))
        return;
    if (reviver == patient)
        return;
    int xpReward = GetRandomInt(XP_REVIVE_MIN, XP_REVIVE_MAX);
    AddXP(reviver, xpReward);
    PrintToConsole(reviver, "Awarded %d XP for reviving a teammate!", xpReward);
}

public void Event_HealSuccess(Event event, const char[] name, bool dontBroadcast)
{
    int healer = GetClientOfUserId(event.GetInt("userid"));
    int patient = GetClientOfUserId(event.GetInt("subject"));
    if (!IsClientInGame(healer) || !IsClientInGame(patient))
        return;
	if (healer == patient)
        return;
	int xpReward = GetRandomInt(XP_HEAL_MIN, XP_HEAL_MAX);
	AddXP(healer, xpReward);
    PrintToConsole(healer, "Award %d XP for healing a teammate!", xpReward);
}

public void Event_DefibUsed(Event event, const char[] name, bool dontBroadcast)
{
    int savior = GetClientOfUserId(event.GetInt("userid"));
    int target = GetClientOfUserId(event.GetInt("subject"));
    if (savior > 0 && IsClientInGame(savior) && target > 0 && IsClientInGame(target) && savior != target)
    {
        int xpReward = GetRandomInt(XP_DEFIB_MIN, XP_DEFIB_MAX);
        AddXP(savior, xpReward);
        PrintToConsole(savior, "%N defibrillated %N and earned %d XP!", savior, target, xpReward);
    }
}

public void Event_WitchKilled(Event event, const char[] name, bool dontBroadcast)
{
    int killer = GetClientOfUserId(event.GetInt("userid"));
    if (killer > 0 && IsClientInGame(killer))
    {
        int xp = GetRandomInt(XP_WITCH_MIN, XP_WITCH_MAX);
        AddXP(killer, xp);
    }
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    
	if (!IsValidClient(victim) || !IsValidClient(attacker)) 
	return;
	if (victim == attacker) 
	return;
    
	if (GetClientTeam(victim) == 2 && GetClientTeam(attacker) == 2)
    {
        int damage = event.GetInt("dmg_health");
        int xpPenalty = damage * 5;

        if (xpPenalty > 0)
        {
            g_ffPenaltyBuffer[attacker] += xpPenalty;
			if (g_hFFTimer[attacker] != null)
            {
				KillTimer(g_hFFTimer[attacker]);
                g_hFFTimer[attacker] = null;
            }
			g_hFFTimer[attacker] = CreateTimer(1.5, Timer_ShowFFPenalty, attacker);
        }
    }
}

public Action Timer_ShowFFPenalty(Handle timer, any client)
{
    g_hFFTimer[client] = null;

    int penalty = g_ffPenaltyBuffer[client];
    if (penalty > 0 && IsClientInGame(client))
    {
        g_playerXP[client] -= penalty;
        if (g_playerXP[client] < 0) g_playerXP[client] = 0;
		if (g_showXPGain[client])
		{
			CPrintToChat(client, "{olive}[XP] {orange}You lost {lightgreen}%d {orange}XP for dealing friendly fire{default}!", penalty);
		}
        SavePlayerData(client);
        g_ffPenaltyBuffer[client] = 0;
    }
    return Plugin_Stop;
}

int CheckByClassname(int victim, int client)
{
	if (!IsValidEdict(victim) || !IsValidEntity(victim))
    {
        return 0;
    }
	
	char classname[64];
    GetEdictClassname(victim, classname, sizeof(classname));
	char model[PLATFORM_MAX_PATH];
    GetEntPropString(victim, Prop_Data, "m_ModelName", model, sizeof(model));
	int xp = 0;
	if (StrEqual(classname, "tank") || StrContains(model, "tank") != -1 || StrContains(model, "hulk") != -1)
    {
        xp = GetRandomInt(XP_BOSS_MIN, XP_BOSS_MAX);
    }
    else if (StrEqual(classname, "boomer") || StrContains(model, "boomer") != -1 ||
			 StrEqual(classname, "smoker") || StrContains(model, "smoker") != -1 ||
			 StrEqual(classname, "hunter") || StrContains(model, "hunter") != -1 ||
			 StrEqual(classname, "spitter") || StrContains(model, "spitter") != -1 || 
			 StrEqual(classname, "jockey") || StrContains(model, "jockey") != -1 ||
			 StrEqual(classname, "charger") || StrContains(model, "charger") != -1)
    {
        xp = GetRandomInt(XP_SPECIAL_MIN, XP_SPECIAL_MAX);
    }
    else
    {
        xp = GetRandomInt(XP_REGULAR_MIN, XP_REGULAR_MAX);
    }
    PrintToConsole(client, "%N rewarded %d XP for killing %s (model: %s)", client, xp, classname, model);
    return xp;
}

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
        g_loadRetryTimers[client] = CreateTimer(1.0, Timer_RetryLoad, client);
        PrintToServer("SteamID not available for %N yet, retry attempt %d scheduled in 1 seconds", client, g_loadAttempts[client]);
        DebugLog("SteamID not available for %N yet, retry attempt %d scheduled in 1 seconds", client, g_loadAttempts[client]);
        return;
    }
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
bool GetSteamIDWithFallback(int client, char[] buffer, int bufferSize)
{
    if (GetClientAuthId(client, AuthId_Steam2, buffer, bufferSize, true) && buffer[0] != '\0')
    {
        DebugLog("Got Steam2 ID for %N: %s", client, buffer);
        return true;
    }
    if (GetClientAuthId(client, AuthId_Steam3, buffer, bufferSize, true) && buffer[0] != '\0')
    {
        DebugLog("Got Steam3 ID for %N: %s", client, buffer);
        return true;
    }
    if (GetClientAuthId(client, AuthId_SteamID64, buffer, bufferSize, true) && buffer[0] != '\0')
    {
        DebugLog("Got SteamID64 for %N: %s", client, buffer);
        return true;
    }
    DebugLog("Failed to get any Steam ID format for %N", client);
    return false;
}
int CalculateIntegrityHash(int level, int xp, int playtime)
{
    return ((level * 31337) ^ (xp * 27183)) + playtime;
}
bool VerifyDataIntegrity(int client, int level, int xp, int playtime, int storedHash)
{
    int calculatedHash = CalculateIntegrityHash(level, xp, playtime);
    
    if (calculatedHash != storedHash)
    {
        DebugLog("Integrity check failed for %N: Expected hash %d, got %d", client, storedHash, calculatedHash);
        return false;
    }
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
    char formattedID[64];
    strcopy(formattedID, sizeof(formattedID), FormatSteamIDForFilePath(steamID));
    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof(filePath), "data/level_data/%s.kv", formattedID);
    PrintToServer("Loading data for %N from: %s", client, filePath);
    DebugLog("Loading data for %N from: %s (SteamID: %s)", client, filePath, steamID);
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
        g_dataLoaded[client] = true;
        return;
    }
    bool loadedSuccessfully = TryLoadFromFile(client, filePath, steamID);
    if (!loadedSuccessfully && FileExists(backupPath))
    {
        PrintToServer("Trying to load from backup file for %N: %s", client, backupPath);
        DebugLog("Trying to load from backup file for %N: %s", client, backupPath);
        loadedSuccessfully = TryLoadFromFile(client, backupPath, steamID);
        
        if (loadedSuccessfully)
        {
            PrintToServer("Restoring backup file for %N", client);
            DebugLog("Restoring backup file for %N", client);
            DeleteFile(filePath);
            CopyFile(backupPath, filePath);
        }
    }
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
    int level = kv.GetNum("level", 1);
    int xp = kv.GetNum("xp", 0);
    int achievement = kv.GetNum("achievement", -1);
    int playtime = kv.GetNum("playtime", 0);
    int storedHash = kv.GetNum("integrity_hash", 0);
    int integrityVersion = kv.GetNum("integrity_version", 0);
    char storedSteamID[64];
    kv.GetString("steam_id", storedSteamID, sizeof(storedSteamID), "");
    bool dataValid = true;
    if (integrityVersion == INTEGRITY_VERSION && storedHash > 0)
    {
        dataValid = VerifyDataIntegrity(client, level, xp, playtime, storedHash);
    }
    if (dataValid && storedSteamID[0] != '\0' && !StrEqual(storedSteamID, steamID))
    {
        DebugLog("Steam ID mismatch for %N: File has %s but current is %s", 
                client, storedSteamID, steamID);
        dataValid = false;
    }
    if (dataValid)
    {
        g_playerLevels[client] = level;
        g_playerXP[client] = xp;
        g_selectedAchievement[client] = achievement;
        g_playerPlaytime[client] = playtime;
        int showXP = kv.GetNum("show_xp_gain", 1);
		g_showXPGain[client] = (showXP != 0);
        PrintToServer("Successfully loaded data for player %N: Level %d, XP %d, Playtime %d seconds", 
                     client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
        DebugLog("Successfully loaded data for player %N: Level %d, XP %d, Playtime %d seconds (SteamID: %s)", 
                client, g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client], steamID);
        CPrintToChat(client, "{olive}[Z4D2] {default}Your data has been loaded: {orange}Level{default}: {lightgreen}%d{default}, {orange}XP{default}: {lightgreen}%d{default}", 
                     g_playerLevels[client], g_playerXP[client]);
        delete kv;
        return true;
    }
    delete kv;
    return false;
}

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
    if (g_lastKnownSteamID[client][0] != '\0' && !StrEqual(steamID, g_lastKnownSteamID[client]))
    {
        PrintToServer("WARNING: Steam ID changed for %N from %s to %s - not saving data", 
                     client, g_lastKnownSteamID[client], steamID);
        DebugLog("WARNING: Steam ID changed for %N from %s to %s - not saving data", 
                client, g_lastKnownSteamID[client], steamID);
        return;
    }
    char formattedID[64];
    strcopy(formattedID, sizeof(formattedID), FormatSteamIDForFilePath(steamID));
    EnsureLevelDataFolderExists();
    char filePath[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, filePath, sizeof(filePath), "data/level_data/%s.kv", formattedID);
    PrintToServer("Saving data for %N to: %s", client, filePath);
    DebugLog("Saving data for %N to: %s (SteamID: %s)", client, filePath, steamID);
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
	kv.SetNum("show_xp_gain", g_showXPGain[client] ? 1 : 0);
    kv.SetNum("level", g_playerLevels[client]);
    kv.SetNum("xp", g_playerXP[client]);
    kv.SetNum("achievement", g_selectedAchievement[client]);
    kv.SetNum("playtime", g_playerPlaytime[client]);
    kv.SetString("steam_id", steamID);
    int integrityHash = CalculateIntegrityHash(g_playerLevels[client], g_playerXP[client], g_playerPlaytime[client]);
    kv.SetNum("integrity_hash", integrityHash);
    kv.SetNum("integrity_version", INTEGRITY_VERSION);
    kv.SetNum("last_save_time", GetTime());
    if (FileExists(filePath))
    {
        char backupPath[PLATFORM_MAX_PATH];
        Format(backupPath, sizeof(backupPath), "%s.bak", filePath);
        DeleteFile(backupPath);
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
	g_showXPGain[client] = true;
    g_playerSessionStartTime[client] = GetGameTime();
    g_loadAttempts[client] = 0;
    g_dataLoaded[client] = false;
    g_lastKnownSteamID[client][0] = '\0';
    
    if (g_loadRetryTimers[client] != null)
    {
        KillTimer(g_loadRetryTimers[client]);
        g_loadRetryTimers[client] = null;
    }
    CreateTimer(1.0, Timer_DelayedLoadData, client);
	CreateTimer(5.0, Timer_WelcomeMessage, client);
}

public Action Timer_WelcomeMessage(Handle timer, any client)
{
    if (IsClientInGame(client) && !IsFakeClient(client))
    {
        CPrintToChat(client, "{olive}[Z4D2] {orange}Type {lightgreen}!lv {orange}to open player menu!");
    }
    return Plugin_Stop;
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
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            SavePlayerData(i);
        }
    }
    return Plugin_Continue;
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

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_mapChanging) 
	{
        g_mapChanging = true;
        SaveAllPlayerData();
        DebugLog("Round ended – all player data saved.");
    }
}

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_mapChanging) 
	{
        g_mapChanging = true;
        SaveAllPlayerData();
        DebugLog("Map transition – all player data saved.");
    }
}

public void OnPluginEnd()
{
    if (g_saveTimer != INVALID_HANDLE)
    {
        KillTimer(g_saveTimer);
        g_saveTimer = INVALID_HANDLE;
    }
    if (g_doubleXPMessageTimer != INVALID_HANDLE)
    {
        KillTimer(g_doubleXPMessageTimer);
        g_doubleXPMessageTimer = INVALID_HANDLE;
    }
    SaveAllPlayerData();
}

public void OnMapStart()
{
    g_mapChanging = false;
}

public void OnMapEnd()
{
	if (g_saveTimer != INVALID_HANDLE)
    {
        KillTimer(g_saveTimer);
        g_saveTimer = INVALID_HANDLE;
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
        CreateDirectory(dirPath, 511);
    }
}

public Action Command_ToggleXP(int client, int args)
{
    g_showXPGain[client] = !g_showXPGain[client];
    if (g_showXPGain[client])
    {
        CPrintToChat(client, "{olive}[Z4D2] {orange}XP Announcement {lightgreen}Enabled{default}.");
    }
    else
    {
        CPrintToChat(client, "{olive}[Z4D2] {orange}XP Announcement {red}Disabled{default}.");
    }
    return Plugin_Handled;
}

native bool Airdrop_CreateAirdrop( const float vOrigin[3], const float vAngles[3], int initiator = 0, bool trace_to_sky = true );

public Action Command_Airdrop(int client, int args)
{
    if (!IsValidHuman(client))
        return Plugin_Handled;
	if (!IsPlayerAlive(client))
	{
		CPrintToChat(client, "{olive}[Z4D2] {default}You must be alive to call an airdrop!");
		return Plugin_Handled;
	}
	float currentTime = GetEngineTime();
	float cooldown = g_cvarAirdropCooldown.FloatValue;
    if (currentTime < g_fNextAirdropTime)
    {
        int remaining = RoundToCeil(g_fNextAirdropTime - currentTime);
        CPrintToChat(client, "{olive}[Z4D2] {default}You must wait {orange}%d seconds {default}to call another!", remaining);
        return Plugin_Handled;
    }
    int cost = g_cvarAirdropCost.IntValue;
    if (g_playerXP[client] < cost)
    {
        CPrintToChat(client, "{olive}[Z4D2] {default}You need {lightgreen}%d XP {default}to call an airdrop! (Current: {orange}%d {default}XP)", cost, g_playerXP[client]);
        return Plugin_Handled;
    }
    g_playerXP[client] -= cost;
    SavePlayerData(client);
	g_fNextAirdropTime = currentTime + cooldown;
	
    CPrintToChatAll("{olive}[Z4D2] {blue}%N {default}has called an airdrop!", client);
	
	float vOrigin[3], vAngles[3];
    GetClientEyePosition(client, vOrigin);
    GetClientEyeAngles(client, vAngles);
	Airdrop_CreateAirdrop(vOrigin, vAngles, client, true);
    return Plugin_Handled;
}

public Action Command_Respawn(int client, int args)
{
    if (!IsValidHuman(client))
        return Plugin_Handled;

    if (IsPlayerAlive(client))
    {
        CPrintToChat(client, "{olive}[Z4D2] {default}You are already in combat!");
        return Plugin_Handled;
    }
	float currentTime = GetEngineTime();
    float cooldown = g_cvarRespawnCooldown.FloatValue;
    if (currentTime < g_fNextRespawnTime[client])
    {
        int remaining = RoundToCeil(g_fNextRespawnTime[client] - currentTime);
        CPrintToChat(client, "{olive}[Z4D2] {default}Reinforce is not available! ({lightgreen}%d seconds{default}).", remaining);
        return Plugin_Handled;
    }
    int cost = g_cvarRespawnCost.IntValue;
    if (g_playerXP[client] < cost)
    {
        CPrintToChat(client, "{olive}[Z4D2] {default}You need {lightgreen}%d XP {default}to reinforce! (Current: {orange}%d XP)", cost, g_playerXP[client]);
        return Plugin_Handled;
    }
    g_playerXP[client] -= cost;
    SavePlayerData(client);
	g_fNextRespawnTime[client] = currentTime + cooldown;
	int userid = GetClientUserId(client);
    CreateTimer(1.0, Timer_RespawnCountdown, userid << 16 | 5, TIMER_FLAG_NO_MAPCHANGE);
    CPrintToChatAll("{olive}[Z4D2] {blue}%N {default}is reinforcing!", client);
    return Plugin_Handled;
}

public Action Timer_RespawnCountdown(Handle timer, any data)
{

    int userid      = data >> 16;
    int secondsLeft = data & 0xFFFF;

    int client = GetClientOfUserId(userid);
    if (client <= 0 || !IsClientInGame(client))
        return Plugin_Stop;
	if (IsPlayerAlive(client))
		return Plugin_Stop;
    if (secondsLeft <= 0)
    {
        RespawnAtTeammate(client);
		return Plugin_Stop;
    }
	PrintHintText(client, "You are reinforcing in %d...", secondsLeft);
    CreateTimer(1.0, Timer_RespawnCountdown, userid << 16 | (secondsLeft - 1), TIMER_FLAG_NO_MAPCHANGE);
    return Plugin_Stop;
}

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
    int achievementIndex = g_selectedAchievement[client];
    if (achievementIndex < 0)
	return Plugin_Continue;
		
    char text[256];
    GetCmdArgString(text, sizeof(text));
    if (text[0] == '"' && text[strlen(text)-1] == '"')
    {
        text[strlen(text)-1] = '\0';
        strcopy(text, sizeof(text), text[1]);
    }
   	for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i))
        {
            if (!team || GetClientTeam(i) == GetClientTeam(client))
			{
				if (team)
				{
					CPrintToChat(i, "{blue}(Team) {default}[{orange}%s{default}] {blue}%N{default}: %s",
                        g_achievementNames[achievementIndex], client, text);
				}
				else
				{
					CPrintToChat(i, "{default}[{orange}%s{default}] {blue}%N{default}: %s",
                        g_achievementNames[achievementIndex], client, text);
				}
            }
        }
    }
    return Plugin_Handled;
}

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