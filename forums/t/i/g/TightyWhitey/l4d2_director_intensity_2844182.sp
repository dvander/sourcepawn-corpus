#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

ConVar gC_Enable;
ConVar gC_Debug;
ConVar gC_Modes;

// Horde (common) intensity
ConVar gC_HordeTrack, gC_HordeThreshold, gC_HordeDamageDivider, gC_HordeRebreather;
ConVar gC_HordeDecayEnable, gC_HordeDecayInterval, gC_HordeDecayDelay, gC_HordeDecayLockout;
ConVar gC_HordeHUD, gC_HordeChat, gC_HordeFlowUnblock;

// Special infected intensity
ConVar gC_SpecialTrack, gC_SpecialThreshold, gC_SpecialDamageDivider, gC_SpecialRebreather;
ConVar gC_SpecialDecayEnable, gC_SpecialDecayInterval, gC_SpecialDecayDelay, gC_SpecialDecayLockout;
ConVar gC_SpecialHUD, gC_SpecialChat, gC_SpecialFlowUnblock;

// Boss intensity (Tank & Witch)
ConVar gC_BossTrack, gC_BossThreshold, gC_BossDamageDivider, gC_BossRebreather;
ConVar gC_BossTankDivider, gC_BossWitchDivider;
ConVar gC_BossDecayEnable, gC_BossDecayInterval, gC_BossDecayDelay, gC_BossDecayLockout;
ConVar gC_BossHUD, gC_BossChat, gC_BossFlowUnblock;

// Disaster fatigue
ConVar gC_FatigueEnable, gC_FatigueThreshold, gC_FatigueDamageDivider, gC_FatigueRebreather;
ConVar gC_FatigueTankDivider, gC_FatigueWitchDivider;
ConVar gC_FatigueDecayEnable, gC_FatigueDecayInterval, gC_FatigueDecayDelay, gC_FatigueDecayLockout;
ConVar gC_FatigueHUD, gC_FatigueChat, gC_FatigueFlowUnblock;
ConVar gC_FatigueInitialWeight, gC_FatigueExtraWeight, gC_FatigueResetCampaign;

// Decay safe area lockout (global, applies to all systems)
ConVar gC_DecaySafeAreaLockout;
ConVar gC_DebugRebreather;

// Finale coverage & skip
ConVar gC_CoverFinales;
ConVar gC_SkipDelay;

// Fatigue no block in finales
ConVar gC_NoFatigueFinale;

// Tank-allow maps (never block Tanks)
ConVar gC_TankAllowMaps;

ConVar g_hMPGameMode;
bool  g_bModeAllowed = true;

public Plugin myinfo = {
    name = "L4D2 Director Intensity 2.0",
    author = "Tighty-Whitey",
    description = "Adaptive director intensity and disaster fatigue.",
    version = "1.8",
    url = ""
};

// Global state
bool g_bEventActive = false;
bool g_bMapStarted = false;

// Safe-area leave tracking for global decay lockout
bool  g_bLeftSafeArea = false;
float g_fSafeAreaLeaveTime = 0.0;

// Horde intensity
float g_fHordeIntensity = 0.0;
float g_fHordeLastDamageTime = 0.0;
float g_fHordeLastBumpTime = 0.0;
bool  g_bHordeBlockActive = false;
Handle g_hHordeRebreather = null;
float g_fHordeBlockStartFlow = 0.0;
float g_fHordeFlowUnblockCurrent;

// Special intensity
float g_fSpecialIntensity = 0.0;
float g_fSpecialLastDamageTime = 0.0;
float g_fSpecialLastBumpTime = 0.0;
bool  g_bSpecialBlockActive = false;
Handle g_hSpecialRebreather = null;
float g_fSpecialBlockStartFlow = 0.0;
float g_fSpecialFlowUnblockCurrent;

// Boss intensity
float g_fBossIntensity = 0.0;
float g_fBossLastDamageTime = 0.0;
float g_fBossLastBumpTime = 0.0;
bool  g_bBossBlockActive = false;
Handle g_hBossRebreather = null;
float g_fBossBlockStartFlow = 0.0;
float g_fBossFlowUnblockCurrent;

// Disaster fatigue
float g_fFatigue = 0.0;
float g_fFatigueLastDamageTime = 0.0;
float g_fFatigueLastBumpTime = 0.0;
bool  g_bFatigueBlockActive = false;
Handle g_hFatigueRebreather = null;
float g_fFatigueBlockStartFlow = 0.0;
float g_fFatigueFlowUnblockCurrent;

// Flow carryover across maps
bool  g_bHordeBlockCarryover = false;
float g_fHordeRemainingFlow = 0.0;
bool  g_bSpecialBlockCarryover = false;
float g_fSpecialRemainingFlow = 0.0;
bool  g_bBossBlockCarryover = false;
float g_fBossRemainingFlow = 0.0;
bool  g_bFatigueBlockCarryover = false;
float g_fFatigueRemainingFlow = 0.0;

// Timer carryover tracking
float g_fHordeTimerStart = 0.0;
float g_fSpecialTimerStart = 0.0;
float g_fBossTimerStart = 0.0;
float g_fFatigueTimerStart = 0.0;

// Saved remaining time for carryover
float g_fHordeRemainingTime = 0.0;
float g_fSpecialRemainingTime = 0.0;
float g_fBossRemainingTime = 0.0;
float g_fFatigueRemainingTime = 0.0;

// Boomer vomit tracking
float g_fBoomerVomitUntil[MAXPLAYERS+1];

// Finale state
bool  g_bFinaleActive = false;
Handle g_hSkipTimer = null;

// Gauntlet finale detection
bool g_bGauntletMap = false;

// Tank-allow maps
char g_sTankAllowMaps[64][64];
int  g_iTankAllowCount = 0;

Handle g_hHUDTimer = null;
char g_sLogPath[PLATFORM_MAX_PATH];

#define VOID_POS { 0.0, 0.0, -5000.0 }
#define VOID_KILL_DELAY 1.0

char g_sOfficialFinaleMaps[][] = 
{
    "c1m4_atrium",
    "c2m5_concert",
    "c3m4_plantation",
    "c4m5_milltown_escape",
    "c5m5_bridge",
    "c6m3_port",
    "c7m3_port",
    "c8m5_rooftop",
    "c9m2_alley",
    "c10m5_houseboat",
    "c11m5_runway",
    "c12m5_cornfield",
    "c13m4_cutthroatcreek",
    "c14m2_lighthouse"
};

public void OnPluginStart()
{
    if (g_hHUDTimer != null)
    {
        KillTimer(g_hHUDTimer);
        g_hHUDTimer = null;
    }

    gC_Enable = CreateConVar("director_intensity_plugin", "1", "Enable Director Intensity", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_Debug  = CreateConVar("director_intensity_debug",  "0", "Debug logging", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_Modes  = CreateConVar("director_intensity_modes",  "coop,realism",  "Enable only in these game modes, comma-separated (no spaces). Empty = all.", FCVAR_NOTIFY);

    // Horde cvars
    gC_HordeTrack         = CreateConVar("director_intensity_horde_tracking",         "1",    "Enable horde (common) intensity", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_HordeThreshold     = CreateConVar("director_intensity_horde_threshold",        "1.0",  "Intensity threshold to block hordes", FCVAR_NOTIFY, true, 0.0);
    gC_HordeDamageDivider = CreateConVar("director_intensity_horde_damage_divider",   "500.0","Common damage divided by this to increase intensity", FCVAR_NOTIFY, true, 1.0);
    gC_HordeRebreather    = CreateConVar("director_intensity_horde_rebreather",       "480.0", "Horde block duration (seconds)", FCVAR_NOTIFY, true, 0.0);
    gC_HordeDecayEnable   = CreateConVar("director_intensity_horde_decay_enable",     "1",    "Enable horde intensity decay", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_HordeDecayInterval = CreateConVar("director_intensity_horde_decay_interval",   "60.0", "Seconds to lose 0.1 intensity", FCVAR_NOTIFY, true, 0.1);
    gC_HordeDecayDelay    = CreateConVar("director_intensity_horde_decay_delay",      "45.0", "Seconds without common damage before decay starts", FCVAR_NOTIFY, true, 0.0);
    gC_HordeDecayLockout  = CreateConVar("director_intensity_horde_decay_lockout",    "30.0", "Seconds after a bump before decay resumes", FCVAR_NOTIFY, true, 0.0);
    gC_HordeHUD           = CreateConVar("director_intensity_horde_hud",              "0",    "Show horde intensity HUD (admin only)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_HordeChat          = CreateConVar("director_intensity_horde_chat",             "0",    "Print horde block messages (admin only)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_HordeFlowUnblock   = CreateConVar("director_intensity_horde_flow_unblock",     "21000.0","Flow travel distance to attempt unblock", FCVAR_NOTIFY, true, 0.0);

    // Special cvars
    gC_SpecialTrack         = CreateConVar("director_intensity_special_tracking",         "1",    "Enable special intensity", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_SpecialThreshold     = CreateConVar("director_intensity_special_threshold",        "1.0",  "Intensity threshold to block specials", FCVAR_NOTIFY, true, 0.0);
    gC_SpecialDamageDivider = CreateConVar("director_intensity_special_damage_divider",   "300.0","Special damage divided by this to increase intensity", FCVAR_NOTIFY, true, 1.0);
    gC_SpecialRebreather    = CreateConVar("director_intensity_special_rebreather",       "600.0", "Special block duration (seconds)", FCVAR_NOTIFY, true, 0.0);
    gC_SpecialDecayEnable   = CreateConVar("director_intensity_special_decay_enable",     "1",    "Enable special intensity decay", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_SpecialDecayInterval = CreateConVar("director_intensity_special_decay_interval",   "90.0", "Seconds to lose 0.1 intensity", FCVAR_NOTIFY, true, 0.1);
    gC_SpecialDecayDelay    = CreateConVar("director_intensity_special_decay_delay",      "60.0", "Seconds without special damage before decay starts", FCVAR_NOTIFY, true, 0.0);
    gC_SpecialDecayLockout  = CreateConVar("director_intensity_special_decay_lockout",    "30.0", "Seconds after a bump before decay resumes", FCVAR_NOTIFY, true, 0.0);
    gC_SpecialHUD           = CreateConVar("director_intensity_special_hud",              "0",    "Show special intensity HUD (admin only)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_SpecialChat          = CreateConVar("director_intensity_special_chat",             "0",    "Print special block messages (admin only)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_SpecialFlowUnblock   = CreateConVar("director_intensity_special_flow_unblock",     "21000.0","Flow travel distance to attempt unblock", FCVAR_NOTIFY, true, 0.0);

    // Boss cvars
    gC_BossTrack          = CreateConVar("director_intensity_boss_tracking",          "1",    "Enable boss (Tank/Witch) intensity", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_BossThreshold      = CreateConVar("director_intensity_boss_threshold",         "1.0",  "Intensity threshold to block bosses", FCVAR_NOTIFY, true, 0.0);
    gC_BossDamageDivider  = CreateConVar("director_intensity_boss_damage_divider",    "250.0","Fallback Boss damage divider (used if specific Tank/Witch divider is 0)", FCVAR_NOTIFY, true, 1.0);
    gC_BossTankDivider    = CreateConVar("director_intensity_boss_tank_damage_divider",  "1000.0","Tank damage divided by this to increase Boss intensity (0 = use fallback)", FCVAR_NOTIFY, true, 0.0);
    gC_BossWitchDivider   = CreateConVar("director_intensity_boss_witch_damage_divider", "500.0","Witch damage divided by this to increase Boss intensity (0 = use fallback)", FCVAR_NOTIFY, true, 0.0);
    gC_BossRebreather     = CreateConVar("director_intensity_boss_rebreather",        "900.0", "Boss block duration (seconds)", FCVAR_NOTIFY, true, 0.0);
    gC_BossDecayEnable    = CreateConVar("director_intensity_boss_decay_enable",      "1",    "Enable boss intensity decay", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_BossDecayInterval  = CreateConVar("director_intensity_boss_decay_interval",    "90.0", "Seconds to lose 0.1 intensity", FCVAR_NOTIFY, true, 0.1);
    gC_BossDecayDelay     = CreateConVar("director_intensity_boss_decay_delay",       "90.0", "Seconds without boss damage before decay starts", FCVAR_NOTIFY, true, 0.0);
    gC_BossDecayLockout   = CreateConVar("director_intensity_boss_decay_lockout",     "30.0", "Seconds after a bump before decay resumes", FCVAR_NOTIFY, true, 0.0);
    gC_BossHUD            = CreateConVar("director_intensity_boss_hud",               "0",    "Show boss intensity HUD (admin only)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_BossChat           = CreateConVar("director_intensity_boss_chat",              "0",    "Print boss block messages (admin only)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_BossFlowUnblock    = CreateConVar("director_intensity_boss_flow_unblock",      "21000.0","Flow travel distance to attempt unblock", FCVAR_NOTIFY, true, 0.0);

    // Disaster fatigue cvars
    gC_FatigueEnable         = CreateConVar("director_intensity_disaster_fatigue_enable",           "1",    "Enable disaster fatigue", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_FatigueThreshold      = CreateConVar("director_intensity_disaster_fatigue_threshold",        "1.0",  "Fatigue threshold to block everything", FCVAR_NOTIFY, true, 0.0);
    gC_FatigueDamageDivider  = CreateConVar("director_intensity_disaster_fatigue_damage_divider",   "2000.0","Fallback Fatigue damage divider (used if specific Tank/Witch divider is 0)", FCVAR_NOTIFY, true, 1.0);
    gC_FatigueTankDivider    = CreateConVar("director_intensity_fatigue_tank_damage_divider",       "4000.0","Tank damage divided by this to increase Fatigue (0 = use fallback)", FCVAR_NOTIFY, true, 0.0);
    gC_FatigueWitchDivider   = CreateConVar("director_intensity_fatigue_witch_damage_divider",      "2000.0","Witch damage divided by this to increase Fatigue (0 = use fallback)", FCVAR_NOTIFY, true, 0.0);
    gC_FatigueRebreather     = CreateConVar("director_intensity_disaster_fatigue_rebreather",       "900.0","Fatigue block duration", FCVAR_NOTIFY, true, 0.0);
    gC_FatigueDecayEnable    = CreateConVar("director_intensity_disaster_fatigue_decay_enable",     "1",    "Enable fatigue decay", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_FatigueDecayInterval  = CreateConVar("director_intensity_disaster_fatigue_decay_interval",   "75.0", "Seconds to lose 0.1 fatigue", FCVAR_NOTIFY, true, 0.1);
    gC_FatigueDecayDelay     = CreateConVar("director_intensity_disaster_fatigue_decay_delay",      "60.0", "Seconds without damage before fatigue decay starts", FCVAR_NOTIFY, true, 0.0);
    gC_FatigueDecayLockout   = CreateConVar("director_intensity_disaster_fatigue_decay_lockout",    "30.0", "Seconds after a bump before decay resumes", FCVAR_NOTIFY, true, 0.0);
    gC_FatigueHUD            = CreateConVar("director_intensity_disaster_fatigue_hud",              "0",    "Show fatigue HUD (admin only)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_FatigueChat           = CreateConVar("director_intensity_disaster_fatigue_chat",             "0",    "Print fatigue block messages (admin only)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_FatigueFlowUnblock    = CreateConVar("director_intensity_disaster_fatigue_flow_unblock",     "24000.0","Flow travel distance to attempt unblock", FCVAR_NOTIFY, true, 0.0);
    gC_FatigueInitialWeight  = CreateConVar("director_intensity_disaster_fatigue_initial_weight",   "0.0",  "Multiplier for team health deficit bump", FCVAR_NOTIFY, true, 0.0);
    gC_FatigueExtraWeight    = CreateConVar("director_intensity_disaster_fatigue_extra_weight",     "0.0",  "Multiplier for item deficiency bump", FCVAR_NOTIFY, true, 0.0);
    gC_FatigueResetCampaign  = CreateConVar("director_intensity_disaster_fatigue_reset_campaign",   "1",    "Reset fatigue on campaign start", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    // Global decay safe-area lockout
    gC_DecaySafeAreaLockout = CreateConVar("director_intensity_decay_safearea_lockout", "0", "Seconds after leaving safe area before ANY decay can start. 0 = off.", FCVAR_NOTIFY, true, 0.0);

    // Finale coverage & skip
    gC_CoverFinales = CreateConVar("director_intensity_cover_finales", "1", "Cover finales with blocks (0 = disable all blocks during finales, 1 = allow blocks & auto-skip if blocked)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    gC_SkipDelay    = CreateConVar("director_intensity_finale_skip_delay", "3.0", "Delay (seconds) before auto-skipping a blocked finale (0 = instant)", FCVAR_NOTIFY, true, 0.0);

    // Fatigue no block in finales
    gC_NoFatigueFinale = CreateConVar("director_intensity_fatigue_no_finale_block", "1", "Prevent fatigue block during finales (1 = yes)", FCVAR_NOTIFY, true, 0.0, true, 1.0);

    // Tank-allow maps (never block Tanks)
    gC_TankAllowMaps = CreateConVar("director_intensity_tank_allow_maps", "c7m1_docks", "CSV of map names where Tanks are never blocked (for scripted tanks)", FCVAR_NOTIFY);

    // Rebreather debug logging (off by default)
    gC_DebugRebreather = CreateConVar("director_intensity_debug_rebreather", "0", "Log rebreather debug events to file (0/1)", FCVAR_NONE);

    AutoExecConfig(true, "l4d2_director_intensity");

    BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/director_intensity_debug.log");

    CreateTimer(0.5, Timer_Check, _, TIMER_REPEAT);
    g_hHUDTimer = CreateTimer(1.0, Timer_HUD, _, TIMER_REPEAT);

    HookEvent("round_end",              Event_ClearState, EventHookMode_PostNoCopy);
    HookEvent("mission_lost",           Event_ClearState, EventHookMode_PostNoCopy);
    HookEvent("map_transition",         Event_ClearState, EventHookMode_PostNoCopy);
    HookEvent("finale_vehicle_leaving", Event_ClearState, EventHookMode_PostNoCopy);
    HookEvent("finale_start",           Event_FinaleStart, EventHookMode_PostNoCopy);
    HookEvent("gauntlet_finale_start",  Event_GauntletFinaleStart, EventHookMode_PostNoCopy);
    HookEvent("player_now_it",          Event_PlayerNowIt, EventHookMode_Post);
    HookEvent("round_start",            Event_RoundStart, EventHookMode_PostNoCopy);
    HookEvent("player_left_safe_area",  Event_PlayerLeftSafeArea, EventHookMode_PostNoCopy);

    AddNormalSoundHook(OnNormalSound);

    RegAdminCmd("sm_detectintensity", Cmd_DetectIntensity, ADMFLAG_ROOT, "Show all intensities");

    g_hMPGameMode = FindConVar("mp_gamemode");
    if (g_hMPGameMode != null)
        g_hMPGameMode.AddChangeHook(Cvar_ModeChanged);
    gC_Modes.AddChangeHook(Cvar_ModeChanged);
    gC_TankAllowMaps.AddChangeHook(Cvar_TankAllowMapsChanged);
    UpdateAllowedGameMode();
    ParseTankAllowMaps();

    for (int i = 1; i <= MaxClients; i++)
        if (IsClientInGame(i))
            SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

void ParseTankAllowMaps()
{
    g_iTankAllowCount = 0;
    char list[512];
    gC_TankAllowMaps.GetString(list, sizeof(list));
    TrimString(list);
    if (!list[0]) return;

    char parts[64][64];
    int count = ExplodeString(list, ",", parts, 64, 64, true);
    for (int i = 0; i < count && g_iTankAllowCount < 64; i++)
    {
        TrimString(parts[i]);
        if (!parts[i][0]) continue;
        for (int k = 0; parts[i][k]; k++) parts[i][k] = CharToLower(parts[i][k]);
        strcopy(g_sTankAllowMaps[g_iTankAllowCount], 64, parts[i]);
        g_iTankAllowCount++;
    }
}

bool IsMapTankAllowed()
{
    char map[64];
    GetCurrentMap(map, sizeof(map));
    for (int k = 0; map[k]; k++) map[k] = CharToLower(map[k]);

    for (int i = 0; i < g_iTankAllowCount; i++)
        if (StrEqual(map, g_sTankAllowMaps[i], false))
            return true;
    return false;
}

public void Cvar_TankAllowMapsChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    ParseTankAllowMaps();
}

public Action OnNormalSound(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH],
    int &entity, int &channel, float &volume, int &level, int &pitch, int &flags,
    char soundEntry[PLATFORM_MAX_PATH], int &seed)
{
    if (!gC_Enable.BoolValue || !g_bModeAllowed)
        return Plugin_Continue;

    if (g_bHordeBlockActive || g_bFatigueBlockActive)
    {
        if (StrContains(soundEntry, "MegaMobIncoming", false) != -1)
            return Plugin_Stop;

        if (StrContains(sample, "mega_mob_incoming", false) != -1)
            return Plugin_Stop;
    }

    return Plugin_Continue;
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
    g_fBoomerVomitUntil[client] = 0.0;
}
public void OnClientDisconnect(int client) { SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage); }

public void OnMapStart()
{
    g_bMapStarted = true;
    g_bEventActive = true;

    if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] OnMapStart triggered");

    if (!L4D_HasAnySurvivorLeftSafeArea())
    {
        g_bLeftSafeArea = false;
        g_fSafeAreaLeaveTime = 0.0;
    }

    g_fHordeLastBumpTime = 0.0;
    g_fSpecialLastBumpTime = 0.0;
    g_fBossLastBumpTime = 0.0;
    g_fFatigueLastBumpTime = 0.0;
    KillAllTimers();
    UpdateAllowedGameMode();

    g_bFinaleActive = false;
    if (g_hSkipTimer != null) { KillTimer(g_hSkipTimer); g_hSkipTimer = null; }

    for (int i = 1; i <= MaxClients; i++)
        g_fBoomerVomitUntil[i] = 0.0;

    if (gC_FatigueResetCampaign.BoolValue && L4D_IsFirstMapInScenario())
    {
        g_fFatigue = 0.0;
        g_bFatigueBlockCarryover = false;
        g_bFatigueBlockActive = false;

        g_fHordeIntensity = 0.0;
        g_bHordeBlockCarryover = false;
        g_bHordeBlockActive = false;

        g_fSpecialIntensity = 0.0;
        g_bSpecialBlockCarryover = false;
        g_bSpecialBlockActive = false;

        g_fBossIntensity = 0.0;
        g_bBossBlockCarryover = false;
        g_bBossBlockActive = false;
    }

    if (g_bHordeBlockCarryover)
    {
        if (g_fHordeRemainingFlow > 0.0)
        {
            g_fHordeFlowUnblockCurrent = g_fHordeRemainingFlow;
            StartHordeBlock();
        }
        g_bHordeBlockCarryover = false;
        g_fHordeRemainingFlow = 0.0;
    }
    if (g_bSpecialBlockCarryover)
    {
        if (g_fSpecialRemainingFlow > 0.0)
        {
            g_fSpecialFlowUnblockCurrent = g_fSpecialRemainingFlow;
            StartSpecialBlock();
        }
        g_bSpecialBlockCarryover = false;
        g_fSpecialRemainingFlow = 0.0;
    }
    if (g_bBossBlockCarryover)
    {
        if (g_fBossRemainingFlow > 0.0)
        {
            g_fBossFlowUnblockCurrent = g_fBossRemainingFlow;
            StartBossBlock();
        }
        g_bBossBlockCarryover = false;
        g_fBossRemainingFlow = 0.0;
    }
    if (g_bFatigueBlockCarryover)
    {
        if (g_fFatigueRemainingFlow > 0.0)
        {
            g_fFatigueFlowUnblockCurrent = g_fFatigueRemainingFlow;
            StartFatigueBlock();
        }
        g_bFatigueBlockCarryover = false;
        g_fFatigueRemainingFlow = 0.0;
    }

    g_bGauntletMap = IsGauntletFinaleActive();
}

public void OnMapEnd()
{
    g_bMapStarted = false;
    g_bEventActive = false;
    KillAllTimers();
    g_bHordeBlockActive = false;
    g_bSpecialBlockActive = false;
    g_bBossBlockActive = false;
    g_bFatigueBlockActive = false;
    g_bFinaleActive = false;
    if (g_hSkipTimer != null) { KillTimer(g_hSkipTimer); g_hSkipTimer = null; }
}

void UpdateAllowedGameMode()
{
    g_bModeAllowed = true;
    char list[256];
    gC_Modes.GetString(list, sizeof(list));
    TrimString(list);
    if (!list[0]) return;

    if (g_hMPGameMode == null) { g_bModeAllowed = false; return; }

    char mode[64];
    g_hMPGameMode.GetString(mode, sizeof(mode));
    TrimString(mode);

    char hay[320], needle[96];
    Format(hay, sizeof(hay), ",%s,", list);
    Format(needle, sizeof(needle), ",%s,", mode);
    g_bModeAllowed = (StrContains(hay, needle, false) != -1);
}

public void Cvar_ModeChanged(ConVar cvar, const char[] oldV, const char[] newV) { UpdateAllowedGameMode(); }

bool IsAnyBlockActive()
{
    return (gC_HordeTrack.BoolValue && g_bHordeBlockActive) ||
           (gC_SpecialTrack.BoolValue && g_bSpecialBlockActive) ||
           (gC_BossTrack.BoolValue && g_bBossBlockActive) ||
           (gC_FatigueEnable.BoolValue && g_bFatigueBlockActive);
}

void KillAllTimers()
{
    if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] KillAllTimers called");

    if (g_hHordeRebreather != null)   { KillTimer(g_hHordeRebreather);   g_hHordeRebreather   = null; }
    if (g_hSpecialRebreather != null) { KillTimer(g_hSpecialRebreather); g_hSpecialRebreather = null; }
    if (g_hBossRebreather != null)    { KillTimer(g_hBossRebreather);    g_hBossRebreather    = null; }
    if (g_hFatigueRebreather != null) { KillTimer(g_hFatigueRebreather); g_hFatigueRebreather = null; }
}

static bool IsRootAdmin(int client) { return client > 0 && IsClientInGame(client) && (GetUserFlagBits(client) & ADMFLAG_ROOT) != 0; }
void PrintToRootAdmins(const char[] msg) { for (int i = 1; i <= MaxClients; i++) if (IsRootAdmin(i)) PrintToChat(i, msg); }

void ShowHudToRootAdmins(const char[] msg)
{
    char buffer[300];
    Format(buffer, sizeof(buffer), "%s\xE2\x80\x8B", msg);
    for (int i = 1; i <= MaxClients; i++)
        if (IsRootAdmin(i))
            PrintHintText(i, buffer);
}

void DebugLog(const char[] format, any ...)
{
    if (!gC_Debug.BoolValue) return;
    char buffer[512]; VFormat(buffer, sizeof(buffer), format, 2);
    File f = OpenFile(g_sLogPath, "a");
    if (f) { char date[32]; FormatTime(date, sizeof(date), "%Y-%m-%d %H:%M:%S"); f.WriteLine("[%s] %s", date, buffer); FlushFile(f); delete f; }
}

bool CanDecay()
{
    float lock = gC_DecaySafeAreaLockout.FloatValue;
    if (lock <= 0.0) return true;

    if (!g_bLeftSafeArea)
    {
        if (L4D_HasAnySurvivorLeftSafeArea())
        {
            g_bLeftSafeArea = true;
            g_fSafeAreaLeaveTime = GetEngineTime();
            if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] SAFE AREA LEFT (auto) at time=%.0f", g_fSafeAreaLeaveTime);
        }
        else
        {
            return false;
        }
    }

    return (GetEngineTime() - g_fSafeAreaLeaveTime) >= lock;
}

public void Event_PlayerLeftSafeArea(Event event, const char[] name, bool dontBroadcast)
{
    if (!g_bLeftSafeArea)
    {
        g_bLeftSafeArea = true;
        g_fSafeAreaLeaveTime = GetEngineTime();
    }
}

void AddIntensityBase(float &intensity, float amount, float threshold, float &lastDamageTime, bool track, bool mode)
{
    if (!g_bEventActive || !track || !mode) return;
    intensity += amount;
    if (intensity > threshold) intensity = threshold;
    lastDamageTime = GetEngineTime();
}

float GetFarthestFlowDistance()
{
    float maxFlow = 0.0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i))
        {
            float flow = L4D2Direct_GetFlowDistance(i);
            if (flow > maxFlow) maxFlow = flow;
        }
    }
    return maxFlow;
}

// Horde intensity
void AddHordeIntensity(float amount)
{
    AddIntensityBase(g_fHordeIntensity, amount, gC_HordeThreshold.FloatValue, g_fHordeLastDamageTime, gC_HordeTrack.BoolValue, g_bModeAllowed);
    EvaluateHordeBlocking();
}
void EvaluateHordeBlocking()
{
    if (!gC_HordeTrack.BoolValue || !gC_Enable.BoolValue || !g_bEventActive || !g_bModeAllowed) return;
    if (g_bHordeBlockActive) return;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return;
    if (g_fHordeIntensity >= gC_HordeThreshold.FloatValue) StartHordeBlock();
}
void StartHordeBlock()
{
    if (!gC_HordeTrack.BoolValue || g_bHordeBlockActive || !g_bEventActive || !g_bModeAllowed) return;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return;
    if (g_hHordeRebreather != null) { KillTimer(g_hHordeRebreather); g_hHordeRebreather = null; }
    g_bHordeBlockActive = true;
    g_fHordeBlockStartFlow = g_bHordeBlockCarryover ? 0.0 : GetFarthestFlowDistance();
    if (!g_bHordeBlockCarryover)
    {
        g_fHordeRemainingFlow = 0.0;
        g_fHordeFlowUnblockCurrent = gC_HordeFlowUnblock.FloatValue;
    }
    float rebr = gC_HordeRebreather.FloatValue;
    if (g_bHordeBlockCarryover && g_fHordeRemainingTime > 0.0)
        rebr = g_fHordeRemainingTime;
    g_fHordeRemainingTime = 0.0;
    if (gC_HordeChat.BoolValue) { char msg[128]; Format(msg, sizeof(msg), "\x04[DI] Horde block %.1fs", rebr); PrintToRootAdmins(msg); }
    DebugLog("Horde block started: %.1f s, flow %.0f", rebr, g_fHordeBlockStartFlow);
    g_hHordeRebreather = CreateTimer(rebr, Timer_HordeRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
    g_fHordeTimerStart = GetEngineTime();
    EvaluateFinaleSkip();
}
public Action Timer_HordeRebreatherEnd(Handle timer)
{
    g_hHordeRebreather = null;
    if (g_bFatigueBlockActive) return Plugin_Stop;
    if (!g_bEventActive) { g_bHordeBlockActive = false; EvaluateFinaleSkip(); return Plugin_Stop; }
    if (g_fHordeIntensity >= gC_HordeThreshold.FloatValue) { g_hHordeRebreather = CreateTimer(gC_HordeRebreather.FloatValue, Timer_HordeRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE); g_fHordeTimerStart = GetEngineTime(); return Plugin_Stop; }
    g_bHordeBlockActive = false; EvaluateHordeBlocking();
    EvaluateFinaleSkip();
    return Plugin_Stop;
}
void CheckHordeFlowUnblock()
{
    if (!g_bHordeBlockActive) return;

    float curFlow = GetFarthestFlowDistance();
    if (curFlow - g_fHordeBlockStartFlow >= g_fHordeFlowUnblockCurrent)
    {
        if (g_fHordeIntensity < gC_HordeThreshold.FloatValue)
        {
            if (!g_bFatigueBlockActive)
            {
                if (g_hHordeRebreather != null) { KillTimer(g_hHordeRebreather); g_hHordeRebreather = null; }
                g_bHordeBlockActive = false;
                EvaluateHordeBlocking();
                EvaluateFinaleSkip();
            }
        }
        else
        {
            g_fHordeBlockStartFlow = curFlow;
            if (g_hHordeRebreather != null) { KillTimer(g_hHordeRebreather); g_hHordeRebreather = null; }
            g_hHordeRebreather = CreateTimer(gC_HordeRebreather.FloatValue, Timer_HordeRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
            g_fHordeTimerStart = GetEngineTime();
        }
    }
}

void ApplyHordeDecay()
{
    if (!gC_HordeDecayEnable.BoolValue || !g_bEventActive || !gC_HordeTrack.BoolValue || !g_bModeAllowed) return;
    if (!CanDecay()) return;
    float now = GetEngineTime();
    if (now - g_fHordeLastDamageTime < gC_HordeDecayDelay.FloatValue) return;
    float lockout = gC_HordeDecayLockout.FloatValue;
    if (lockout > 0.0 && g_fHordeLastBumpTime > 0.0 && (now - g_fHordeLastBumpTime) < lockout) return;
    float interval = gC_HordeDecayInterval.FloatValue;
    if (interval <= 0.0) return;
    float decay = (0.5 / interval) * 0.1;
    float old = g_fHordeIntensity;
    g_fHordeIntensity -= decay;
    if (g_fHordeIntensity < 0.0) g_fHordeIntensity = 0.0;
    if (old != g_fHordeIntensity) DebugLog("Horde decay: %.2f -> %.2f", old, g_fHordeIntensity);
    EvaluateHordeBlocking();
}

// Special intensity
void AddSpecialIntensity(float amount)
{
    AddIntensityBase(g_fSpecialIntensity, amount, gC_SpecialThreshold.FloatValue, g_fSpecialLastDamageTime, gC_SpecialTrack.BoolValue, g_bModeAllowed);
    EvaluateSpecialBlocking();
}
void EvaluateSpecialBlocking()
{
    if (!gC_SpecialTrack.BoolValue || !gC_Enable.BoolValue || !g_bEventActive || !g_bModeAllowed) return;
    if (g_bSpecialBlockActive) return;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return;
    if (g_fSpecialIntensity >= gC_SpecialThreshold.FloatValue) StartSpecialBlock();
}
void StartSpecialBlock()
{
    if (!gC_SpecialTrack.BoolValue || g_bSpecialBlockActive || !g_bEventActive || !g_bModeAllowed) return;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return;
    if (g_hSpecialRebreather != null) { KillTimer(g_hSpecialRebreather); g_hSpecialRebreather = null; }
    g_bSpecialBlockActive = true;
    g_fSpecialBlockStartFlow = g_bSpecialBlockCarryover ? 0.0 : GetFarthestFlowDistance();
    if (!g_bSpecialBlockCarryover)
    {
        g_fSpecialRemainingFlow = 0.0;
        g_fSpecialFlowUnblockCurrent = gC_SpecialFlowUnblock.FloatValue;
    }
    float rebr = gC_SpecialRebreather.FloatValue;
    if (g_bSpecialBlockCarryover && g_fSpecialRemainingTime > 0.0)
        rebr = g_fSpecialRemainingTime;
    g_fSpecialRemainingTime = 0.0;
    if (gC_SpecialChat.BoolValue) { char msg[128]; Format(msg, sizeof(msg), "\x04[DI] Special block %.1fs", rebr); PrintToRootAdmins(msg); }
    DebugLog("Special block started: %.1f s, flow %.0f", rebr, g_fSpecialBlockStartFlow);
    g_hSpecialRebreather = CreateTimer(rebr, Timer_SpecialRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
    g_fSpecialTimerStart = GetEngineTime();
    EvaluateFinaleSkip();
}
public Action Timer_SpecialRebreatherEnd(Handle timer)
{
    g_hSpecialRebreather = null;
    if (g_bFatigueBlockActive) return Plugin_Stop; 
    if (!g_bEventActive) { g_bSpecialBlockActive = false; EvaluateFinaleSkip(); return Plugin_Stop; }
    if (g_fSpecialIntensity >= gC_SpecialThreshold.FloatValue) { g_hSpecialRebreather = CreateTimer(gC_SpecialRebreather.FloatValue, Timer_SpecialRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE); g_fSpecialTimerStart = GetEngineTime(); return Plugin_Stop; }
    g_bSpecialBlockActive = false; EvaluateSpecialBlocking();
    EvaluateFinaleSkip();
    return Plugin_Stop;
}
void CheckSpecialFlowUnblock()
{
    if (!g_bSpecialBlockActive) return;

    float curFlow = GetFarthestFlowDistance();
    if (curFlow - g_fSpecialBlockStartFlow >= g_fSpecialFlowUnblockCurrent)
    {
        if (g_fSpecialIntensity < gC_SpecialThreshold.FloatValue)
        {
            if (!g_bFatigueBlockActive)
            {
                if (g_hSpecialRebreather != null) { KillTimer(g_hSpecialRebreather); g_hSpecialRebreather = null; }
                g_bSpecialBlockActive = false;
                EvaluateSpecialBlocking();
                EvaluateFinaleSkip();
            }
        }
        else
        {
            g_fSpecialBlockStartFlow = curFlow;
            if (g_hSpecialRebreather != null) { KillTimer(g_hSpecialRebreather); g_hSpecialRebreather = null; }
            g_hSpecialRebreather = CreateTimer(gC_SpecialRebreather.FloatValue, Timer_SpecialRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
            g_fSpecialTimerStart = GetEngineTime();
        }
    }
}

void ApplySpecialDecay()
{
    if (!gC_SpecialDecayEnable.BoolValue || !g_bEventActive || !gC_SpecialTrack.BoolValue || !g_bModeAllowed) return;
    if (!CanDecay()) return;
    float now = GetEngineTime();
    if (now - g_fSpecialLastDamageTime < gC_SpecialDecayDelay.FloatValue) return;
    float lockout = gC_SpecialDecayLockout.FloatValue;
    if (lockout > 0.0 && g_fSpecialLastBumpTime > 0.0 && (now - g_fSpecialLastBumpTime) < lockout) return;
    float interval = gC_SpecialDecayInterval.FloatValue;
    if (interval <= 0.0) return;
    float decay = (0.5 / interval) * 0.1;
    float old = g_fSpecialIntensity;
    g_fSpecialIntensity -= decay;
    if (g_fSpecialIntensity < 0.0) g_fSpecialIntensity = 0.0;
    if (old != g_fSpecialIntensity) DebugLog("Special decay: %.2f -> %.2f", old, g_fSpecialIntensity);
    EvaluateSpecialBlocking();
}

// Boss intensity
void AddBossIntensity(float amount)
{
    AddIntensityBase(g_fBossIntensity, amount, gC_BossThreshold.FloatValue, g_fBossLastDamageTime, gC_BossTrack.BoolValue, g_bModeAllowed);
    EvaluateBossBlocking();
}
void EvaluateBossBlocking()
{
    if (!gC_BossTrack.BoolValue || !gC_Enable.BoolValue || !g_bEventActive || !g_bModeAllowed) return;
    if (g_bBossBlockActive) return;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return;
    if (g_fBossIntensity >= gC_BossThreshold.FloatValue) StartBossBlock();
}
void StartBossBlock()
{
    if (!gC_BossTrack.BoolValue || g_bBossBlockActive || !g_bEventActive || !g_bModeAllowed) return;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return;
    if (g_hBossRebreather != null) { KillTimer(g_hBossRebreather); g_hBossRebreather = null; }
    g_bBossBlockActive = true;
    g_fBossBlockStartFlow = g_bBossBlockCarryover ? 0.0 : GetFarthestFlowDistance();
    if (!g_bBossBlockCarryover)
    {
        g_fBossRemainingFlow = 0.0;
        g_fBossFlowUnblockCurrent = gC_BossFlowUnblock.FloatValue;
    }
    float rebr = gC_BossRebreather.FloatValue;
    if (g_bBossBlockCarryover && g_fBossRemainingTime > 0.0)
        rebr = g_fBossRemainingTime;
    g_fBossRemainingTime = 0.0;
    if (gC_BossChat.BoolValue) { char msg[128]; Format(msg, sizeof(msg), "\x04[DI] Boss block %.1fs", rebr); PrintToRootAdmins(msg); }
    DebugLog("Boss block started: %.1f s, flow %.0f", rebr, g_fBossBlockStartFlow);
    g_hBossRebreather = CreateTimer(rebr, Timer_BossRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
    g_fBossTimerStart = GetEngineTime();

    if (gC_DebugRebreather.BoolValue)
        LogToFileEx(g_sLogPath, "[BOSSDBG] BLOCK START | intensity=%.6f flowStart=%.0f unblockNeed=%.0f carryover=%d timerExists=%d",
            g_fBossIntensity, g_fBossBlockStartFlow, g_fBossFlowUnblockCurrent, g_bBossBlockCarryover ? 1 : 0, g_hBossRebreather != null);

    EvaluateFinaleSkip();
}
public Action Timer_BossRebreatherEnd(Handle timer)
{
    g_hBossRebreather = null;
    if (g_bFatigueBlockActive) return Plugin_Stop; 

    float curFlow = GetFarthestFlowDistance();
    bool canDecay = (gC_DecaySafeAreaLockout.FloatValue <= 0.0) ||
                    (g_bLeftSafeArea && (GetEngineTime() - g_fSafeAreaLeaveTime) >= gC_DecaySafeAreaLockout.FloatValue);

    if (gC_DebugRebreather.BoolValue)
        LogToFileEx(g_sLogPath, "[BOSSDBG] TIMER FIRED | intensity=%.6f threshold=%.1f blockActive=%d flowStart=%.0f curFlow=%.0f need=%.0f eventActive=%d safeArea=%d canDecay=%d",
            g_fBossIntensity, gC_BossThreshold.FloatValue, g_bBossBlockActive ? 1 : 0,
            g_fBossBlockStartFlow, curFlow, g_fBossFlowUnblockCurrent, g_bEventActive ? 1 : 0,
            g_bLeftSafeArea ? 1 : 0, canDecay ? 1 : 0);

    if (!g_bEventActive) { g_bBossBlockActive = false; EvaluateFinaleSkip(); return Plugin_Stop; }

    if (g_fBossIntensity >= gC_BossThreshold.FloatValue)
    {
        if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] TIMER RENEW (intensity >= threshold)");
        g_hBossRebreather = CreateTimer(gC_BossRebreather.FloatValue, Timer_BossRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
        g_fBossTimerStart = GetEngineTime();
        return Plugin_Stop;
    }

    g_bBossBlockActive = false;
    if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] TIMER RELEASE (intensity below threshold)");
    EvaluateBossBlocking();
    EvaluateFinaleSkip();
    return Plugin_Stop;
}

void CheckBossFlowUnblock()
{
    if (!g_bBossBlockActive) return;

    float curFlow = GetFarthestFlowDistance();
    float traveled = curFlow - g_fBossBlockStartFlow;

    if (gC_DebugRebreather.BoolValue)
        LogToFileEx(g_sLogPath, "[BOSSDBG] FLOWCHECK | curFlow=%.0f startFlow=%.0f traveled=%.0f need=%.0f timerExists=%d",
            curFlow, g_fBossBlockStartFlow, traveled, g_fBossFlowUnblockCurrent, g_hBossRebreather != null);

    if (traveled >= g_fBossFlowUnblockCurrent)
    {
        if (g_fBossIntensity < gC_BossThreshold.FloatValue)
        {
            if (!g_bFatigueBlockActive)
            {
                if (g_hBossRebreather != null)
                {
                    KillTimer(g_hBossRebreather);
                    g_hBossRebreather = null;
                    if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] FLOWCHECK KILLED TIMER | intensity=%.6f", g_fBossIntensity);
                }
                g_bBossBlockActive = false;
                if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] FLOWCHECK RELEASE (intensity below threshold)");
                EvaluateBossBlocking();
                EvaluateFinaleSkip();
            }
        }
        else
        {
            g_fBossBlockStartFlow = curFlow;
            if (g_hBossRebreather != null)
            {
                KillTimer(g_hBossRebreather);
                g_hBossRebreather = null;
                if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] FLOWCHECK KILLED TIMER | intensity=%.6f", g_fBossIntensity);
            }
            if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] FLOWCHECK RESET START & NEW TIMER (intensity high)");
            g_hBossRebreather = CreateTimer(gC_BossRebreather.FloatValue, Timer_BossRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
            g_fBossTimerStart = GetEngineTime();
        }
    }
}

void ApplyBossDecay()
{
    if (!gC_BossDecayEnable.BoolValue || !g_bEventActive || !gC_BossTrack.BoolValue || !g_bModeAllowed) return;

    bool canDecay = (gC_DecaySafeAreaLockout.FloatValue <= 0.0) ||
                    (g_bLeftSafeArea && (GetEngineTime() - g_fSafeAreaLeaveTime) >= gC_DecaySafeAreaLockout.FloatValue);

    if (!canDecay) return;

    float now = GetEngineTime();
    if (now - g_fBossLastDamageTime < gC_BossDecayDelay.FloatValue) return;
    float lockout = gC_BossDecayLockout.FloatValue;
    if (lockout > 0.0 && g_fBossLastBumpTime > 0.0 && (now - g_fBossLastBumpTime) < lockout) return;
    float interval = gC_BossDecayInterval.FloatValue;
    if (interval <= 0.0) return;
    float decay = (0.5 / interval) * 0.1;
    float old = g_fBossIntensity;
    g_fBossIntensity -= decay;
    if (g_fBossIntensity < 0.0) g_fBossIntensity = 0.0;
    if (old != g_fBossIntensity && gC_DebugRebreather.BoolValue)
        LogToFileEx(g_sLogPath, "[BOSSDBG] DECAY | %.4f -> %.4f (safeArea=%d canDecay=%d)",
            old, g_fBossIntensity, g_bLeftSafeArea ? 1 : 0, canDecay ? 1 : 0);
    EvaluateBossBlocking();
}

// Fatigue
void AddFatigue(float amount)
{
    if (!gC_FatigueEnable.BoolValue || !g_bModeAllowed) return;
    g_fFatigue += amount;
    float thr = gC_FatigueThreshold.FloatValue;
    if (g_fFatigue > thr) g_fFatigue = thr;
    g_fFatigueLastDamageTime = GetEngineTime();
    DebugLog("Fatigue increased by %.4f, now %.2f", amount, g_fFatigue);
    EvaluateFatigueBlocking();
}
void EvaluateFatigueBlocking()
{
    if (!gC_FatigueEnable.BoolValue || !gC_Enable.BoolValue || !g_bModeAllowed) return;
    if (g_bFatigueBlockActive) return;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return;
    if (g_bFinaleActive && gC_NoFatigueFinale.BoolValue) return;
    if (g_fFatigue >= gC_FatigueThreshold.FloatValue) StartFatigueBlock();
}
void StartFatigueBlock()
{
    if (!gC_FatigueEnable.BoolValue || g_bFatigueBlockActive || !g_bModeAllowed) return;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return;
    if (g_bFinaleActive && gC_NoFatigueFinale.BoolValue) return;
    if (g_hFatigueRebreather != null) { KillTimer(g_hFatigueRebreather); g_hFatigueRebreather = null; }
    g_bFatigueBlockActive = true;
    g_fFatigueBlockStartFlow = g_bFatigueBlockCarryover ? 0.0 : GetFarthestFlowDistance();
    if (!g_bFatigueBlockCarryover)
    {
        g_fFatigueRemainingFlow = 0.0;
        g_fFatigueFlowUnblockCurrent = gC_FatigueFlowUnblock.FloatValue;
    }
    float rebr = gC_FatigueRebreather.FloatValue;
    if (g_bFatigueBlockCarryover && g_fFatigueRemainingTime > 0.0)
        rebr = g_fFatigueRemainingTime;
    g_fFatigueRemainingTime = 0.0;
    if (gC_FatigueChat.BoolValue) { char msg[128]; Format(msg, sizeof(msg), "\x04[DI] Fatigue block %.1fs", rebr); PrintToRootAdmins(msg); }
    DebugLog("Fatigue block started: %.1f s, flow %.0f", rebr, g_fFatigueBlockStartFlow);
    g_hFatigueRebreather = CreateTimer(rebr, Timer_FatigueRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
    g_fFatigueTimerStart = GetEngineTime();
    EvaluateFinaleSkip();
}
public Action Timer_FatigueRebreatherEnd(Handle timer)
{
    g_hFatigueRebreather = null;
    if (g_fFatigue >= gC_FatigueThreshold.FloatValue)
    {
        g_hFatigueRebreather = CreateTimer(gC_FatigueRebreather.FloatValue, Timer_FatigueRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
        g_fFatigueTimerStart = GetEngineTime();
        return Plugin_Stop;
    }

    g_bFatigueBlockActive = false;

    CheckHordeFlowUnblock();
    CheckSpecialFlowUnblock();
    CheckBossFlowUnblock();

    EvaluateFatigueBlocking();
    EvaluateFinaleSkip();
    return Plugin_Stop;
}

void CheckFatigueFlowUnblock()
{
    if (!g_bFatigueBlockActive) return;
    float curFlow = GetFarthestFlowDistance();
    if (curFlow - g_fFatigueBlockStartFlow >= g_fFatigueFlowUnblockCurrent)
    {
        if (g_hFatigueRebreather != null) { KillTimer(g_hFatigueRebreather); g_hFatigueRebreather = null; }
        if (g_fFatigue < gC_FatigueThreshold.FloatValue) { g_bFatigueBlockActive = false; EvaluateFatigueBlocking(); EvaluateFinaleSkip(); }
        else { g_fFatigueBlockStartFlow = curFlow; g_hFatigueRebreather = CreateTimer(gC_FatigueRebreather.FloatValue, Timer_FatigueRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE); g_fFatigueTimerStart = GetEngineTime(); }
    }
}

void ApplyFatigueDecay()
{
    if (!gC_FatigueDecayEnable.BoolValue || !gC_FatigueEnable.BoolValue || !g_bModeAllowed) return;
    if (!CanDecay()) return;
    float now = GetEngineTime();
    if (now - g_fFatigueLastDamageTime < gC_FatigueDecayDelay.FloatValue) return;
    float lockout = gC_FatigueDecayLockout.FloatValue;
    if (lockout > 0.0 && g_fFatigueLastBumpTime > 0.0 && (now - g_fFatigueLastBumpTime) < lockout) return;
    float interval = gC_FatigueDecayInterval.FloatValue;
    if (interval <= 0.0) return;
    float decay = (0.5 / interval) * 0.1;
    float old = g_fFatigue;
    g_fFatigue -= decay;
    if (g_fFatigue < 0.0) g_fFatigue = 0.0;
    if (old != g_fFatigue) DebugLog("Fatigue decay: %.2f -> %.2f", old, g_fFatigue);
    EvaluateFatigueBlocking();
}

bool IsScavengeFinaleActive()
{
    int entity = FindEntityByClassname(-1, "point_prop_use_target");
    return (entity != -1);
}

bool IsGauntletFinaleActive()
{
    int entity = -1;
    while ((entity = FindEntityByClassname(entity, "trigger_finale")) != -1)
    {
        if (HasEntProp(entity, Prop_Data, "m_type"))
        {
            if (GetEntProp(entity, Prop_Data, "m_type") == 0)
                return true;
        }
    }
    return false;
}

bool IsOfficialFinaleMap()
{
    char map[64];
    GetCurrentMap(map, sizeof(map));
    for (int i = 0; i < sizeof(g_sOfficialFinaleMaps); i++)
        if (StrEqual(map, g_sOfficialFinaleMaps[i], false))
            return true;
    return false;
}

void FireSyntheticTankKilledEvent(int client)
{
    if (client <= 0 || client > MaxClients || !IsClientInGame(client))
        return;

    int userid = GetClientUserId(client);
    Event ev;

    ev = CreateEvent("tank_killed");
    if (ev != null)
    {
        ev.SetInt("userid", userid);
        ev.SetInt("attacker", 0);
        ev.Fire();
    }

    ev = CreateEvent("player_death");
    if (ev != null)
    {
        ev.SetInt("userid", userid);
        ev.SetInt("attacker", 0);
        ev.SetInt("zombie_class", 8);
        ev.Fire();
    }
}

void KillVoidedBoss(int entity)
{
    if (!IsValidEntity(entity)) return;

    if (entity > 0 && entity <= MaxClients && IsClientInGame(entity))
    {
        int zombieClass = GetEntProp(entity, Prop_Send, "m_zombieClass");
        if (zombieClass == 8)
        {
            ForcePlayerSuicide(entity);
            FireSyntheticTankKilledEvent(entity);
            return;
        }
    }

    char cls[64];
    GetEdictClassname(entity, cls, sizeof(cls));
    if (StrEqual(cls, "witch", false))
    {
        SetEntProp(entity, Prop_Data, "m_iHealth", 1);
        AcceptEntityInput(entity, "Break");
    }
}
public Action Timer_KillVoidedBoss(Handle timer, any entRef)
{
    int entity = EntRefToEntIndex(entRef);
    if (entity != INVALID_ENT_REFERENCE)
        KillVoidedBoss(entity);
    return Plugin_Stop;
}

public void OnBossSpawnPost(int entity)
{
    SDKUnhook(entity, SDKHook_SpawnPost, OnBossSpawnPost);

    if (!IsValidEntity(entity))
        return;

    float voidPos[3] = VOID_POS;
    TeleportEntity(entity, voidPos, NULL_VECTOR, NULL_VECTOR);

    CreateTimer(VOID_KILL_DELAY, Timer_KillVoidedBoss, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

void EvaluateFinaleSkip()
{
    if (!g_bFinaleActive || !gC_CoverFinales.BoolValue)
        return;

    if (!IsOfficialFinaleMap())
    {
        if (g_hSkipTimer != null)
        {
            KillTimer(g_hSkipTimer);
            g_hSkipTimer = null;
        }
        return;
    }

    if (IsScavengeFinaleActive() || g_bGauntletMap)
    {
        if (g_hSkipTimer != null)
        {
            KillTimer(g_hSkipTimer);
            g_hSkipTimer = null;
        }
        return;
    }

    bool shouldSkip = (g_bFatigueBlockActive) || (g_bHordeBlockActive && g_bBossBlockActive);

    if (shouldSkip)
    {
        if (g_hSkipTimer == null)
        {
            float delay = gC_SkipDelay.FloatValue;
            if (delay <= 0.0)
                ForceFinaleEnd();
            else
                g_hSkipTimer = CreateTimer(delay, Timer_FinaleSkip, _, TIMER_FLAG_NO_MAPCHANGE);
        }
    }
    else
    {
        if (g_hSkipTimer != null)
        {
            KillTimer(g_hSkipTimer);
            g_hSkipTimer = null;
        }
    }
}

void ForceFinaleEnd()
{
    if (!g_bFinaleActive || !gC_CoverFinales.BoolValue)
        return;

    if (!IsOfficialFinaleMap())
        return;

    if (IsScavengeFinaleActive() || g_bGauntletMap)
        return;

    L4D2_SendInRescueVehicle();
    g_bFinaleActive = false;
}

public Action Timer_FinaleSkip(Handle timer)
{
    g_hSkipTimer = null;
    if (!g_bFinaleActive || !gC_CoverFinales.BoolValue)
        return Plugin_Stop;

    bool shouldSkip = (g_bFatigueBlockActive) || (g_bHordeBlockActive && g_bBossBlockActive);
    if (shouldSkip)
        ForceFinaleEnd();

    return Plugin_Stop;
}

public void Event_GauntletFinaleStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!gC_Enable.BoolValue || !g_bModeAllowed) return;

    g_bGauntletMap = true;

    if (!g_bFinaleActive)
    {
        g_bFinaleActive = true;

        if (!gC_CoverFinales.BoolValue)
        {
            KillAllTimers();
            g_bHordeBlockActive = false;
            g_bSpecialBlockActive = false;
            g_bBossBlockActive = false;
            g_bFatigueBlockActive = false;
        }
        else
        {
            if (gC_NoFatigueFinale.BoolValue && gC_FatigueEnable.BoolValue && g_bFatigueBlockActive)
            {
                if (g_hFatigueRebreather != null)
                {
                    KillTimer(g_hFatigueRebreather);
                    g_hFatigueRebreather = null;
                }
                g_bFatigueBlockActive = false;
            }
        }

        ApplyDisasterFatigueBump();
        EvaluateFinaleSkip();
    }
}

public void Event_PlayerNowIt(Event event, const char[] name, bool dontBroadcast)
{
    int victim = GetClientOfUserId(event.GetInt("userid"));
    if (victim > 0 && IsClientInGame(victim) && GetClientTeam(victim) == 2)
    {
        g_fBoomerVomitUntil[victim] = GetGameTime() + 20.0;
    }
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!gC_Enable.BoolValue || !g_bEventActive || !g_bModeAllowed) return Plugin_Continue;
    if (damage <= 0.0 || victim < 1 || victim > MaxClients || !IsClientInGame(victim)) return Plugin_Continue;
    if (GetClientTeam(victim) != 2) return Plugin_Continue;
    if (GetEntProp(victim, Prop_Send, "m_isIncapacitated")) return Plugin_Continue;
    if (!IsPlayerAlive(victim)) return Plugin_Continue;

    bool friendly = (attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && GetClientTeam(attacker) == 2 && attacker != victim);
    if (friendly) return Plugin_Continue;

    // Skip self‑damage entirely
    if (attacker == victim)
        return Plugin_Continue;

    bool isCommon = false;
    int zombieClass = 0;

    if (attacker > 0 && IsValidEntity(attacker))
    {
        char cls[64];
        GetEdictClassname(attacker, cls, sizeof(cls));
        if (strcmp(cls, "infected") == 0) isCommon = true;
        else if (strcmp(cls, "witch") == 0) zombieClass = 7;
        else if (strcmp(cls, "tank") == 0) zombieClass = 8;
        else if (HasEntProp(attacker, Prop_Send, "m_zombieClass"))
        zombieClass = GetEntProp(attacker, Prop_Send, "m_zombieClass");
    }

    if (zombieClass == 0 && inflictor > 0 && IsValidEntity(inflictor))
    {
        char inflCls[64];
        GetEdictClassname(inflictor, inflCls, sizeof(inflCls));
        if (strcmp(inflCls, "witch") == 0) zombieClass = 7;
        else if (strcmp(inflCls, "tank") == 0) zombieClass = 8;
    }

    bool isSpecialDamage = false;
    if (inflictor > 0 && IsValidEntity(inflictor))
    {
        char infl_cls[64];
        GetEdictClassname(inflictor, infl_cls, sizeof(infl_cls));
        if (StrEqual(infl_cls, "insect_swarm") || StrEqual(infl_cls, "tongue")) isSpecialDamage = true;
    }
    if (!isSpecialDamage && isCommon && victim > 0 && victim <= MaxClients)
    {
        if (GetGameTime() < g_fBoomerVomitUntil[victim]) isSpecialDamage = true;
    }

    if (isSpecialDamage)
    {
        float div = gC_SpecialDamageDivider.FloatValue; if (div <= 0.0) div = 1.0;
        AddSpecialIntensity(damage / div);
    }
    else if (isCommon && gC_HordeTrack.BoolValue)
    {
        float div = gC_HordeDamageDivider.FloatValue; if (div <= 0.0) div = 1.0;
        AddHordeIntensity(damage / div);
    }
    else if (zombieClass >= 1 && zombieClass <= 6 && gC_SpecialTrack.BoolValue)
    {
        float div = gC_SpecialDamageDivider.FloatValue; if (div <= 0.0) div = 1.0;
        AddSpecialIntensity(damage / div);
    }
    else if ((zombieClass == 7 || zombieClass == 8) && gC_BossTrack.BoolValue)
    {
        float div;
        if (zombieClass == 8)
        {
            div = gC_BossTankDivider.FloatValue;
            if (div <= 0.0) div = gC_BossDamageDivider.FloatValue;
        }
        else
        {
            div = gC_BossWitchDivider.FloatValue;
            if (div <= 0.0) div = gC_BossDamageDivider.FloatValue;
        }
        if (div <= 0.0) div = 1.0;
        AddBossIntensity(damage / div);
    }

    if (gC_FatigueEnable.BoolValue)
    {
        // Only increase fatigue from actual enemy damage
        if (!isCommon && zombieClass == 0)
            return Plugin_Continue;

        float fdiv = gC_FatigueDamageDivider.FloatValue;
        if (zombieClass == 8)
        {
            float td = gC_FatigueTankDivider.FloatValue;
            if (td > 0.0) fdiv = td;
        }
        else if (zombieClass == 7)
        {
            float wd = gC_FatigueWitchDivider.FloatValue;
            if (wd > 0.0) fdiv = wd;
        }
        if (fdiv <= 0.0) fdiv = 1.0;
        AddFatigue(damage / fdiv);
    }

    return Plugin_Continue;
}

float ComputeTeamHealthIntensity()
{
    float totalMax = 0.0, totalMissing = 0.0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
        int maxHP = GetEntProp(i, Prop_Send, "m_iMaxHealth"); if (maxHP <= 0) maxHP = 100;
        int curHP = GetClientHealth(i);
        int missing = maxHP - curHP; if (missing < 0) missing = 0;
        totalMax += maxHP; totalMissing += missing;
    }
    if (totalMax <= 0.0) return 0.0;
    return (totalMissing / totalMax) * gC_FatigueInitialWeight.FloatValue;
}

float GetItemDeficiencyBump()
{
    if (gC_FatigueExtraWeight.FloatValue <= 0.0) return 0.0;
    int survCount = 0;
    float totalDeficiency = 0.0;
    float maxItemValue = 100.0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != 2 || !IsPlayerAlive(i)) continue;
        survCount++;
        float itemValue = 0.0;
        int kit = GetPlayerWeaponSlot(i, 3);
        if (kit != -1 && IsValidEntity(kit)) { char cls[64]; GetEdictClassname(kit, cls, sizeof(cls)); if (StrEqual(cls, "weapon_first_aid_kit")) itemValue = maxItemValue; }
        if (itemValue < maxItemValue)
        {
            int temp = GetPlayerWeaponSlot(i, 4);
            if (temp != -1 && IsValidEntity(temp))
            {
                char cls[64]; GetEdictClassname(temp, cls, sizeof(cls));
                if (StrContains(cls, "adrenaline", false) != -1) itemValue = 25.0;
                else if (StrContains(cls, "pain_pills", false) != -1) itemValue = 50.0;
            }
        }
        float deficiency = maxItemValue - itemValue;
        if (deficiency < 0.0) deficiency = 0.0;
        totalDeficiency += deficiency;
    }
    if (survCount == 0) return 0.0;
    return (totalDeficiency / (survCount * maxItemValue)) * gC_FatigueExtraWeight.FloatValue;
}

void ApplyDisasterFatigueBump()
{
    if (!gC_FatigueEnable.BoolValue || !g_bModeAllowed) return;
    float bump = ComputeTeamHealthIntensity();
    if (bump > 0.0) { g_fFatigue += bump; if (g_fFatigue > gC_FatigueThreshold.FloatValue) g_fFatigue = gC_FatigueThreshold.FloatValue; g_fFatigueLastBumpTime = GetEngineTime(); DebugLog("Fatigue health bump +%.2f, now %.2f", bump, g_fFatigue); }
    float extra = GetItemDeficiencyBump();
    if (extra > 0.0) { g_fFatigue += extra; if (g_fFatigue > gC_FatigueThreshold.FloatValue) g_fFatigue = gC_FatigueThreshold.FloatValue; g_fFatigueLastBumpTime = GetEngineTime(); DebugLog("Fatigue item bump +%.2f, now %.2f", extra, g_fFatigue); }
    EvaluateFatigueBlocking();
}

public Action Timer_Check(Handle timer)
{
    if (!gC_Enable.BoolValue || !g_bModeAllowed || !g_bEventActive) return Plugin_Continue;

    if (g_bHordeBlockActive && g_hHordeRebreather == null)
    {
        if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] Timer_Check: Horde timer was NULL – recreating");
        g_hHordeRebreather = CreateTimer(gC_HordeRebreather.FloatValue, Timer_HordeRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
        g_fHordeTimerStart = GetEngineTime();
    }
    if (g_bSpecialBlockActive && g_hSpecialRebreather == null)
    {
        if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] Timer_Check: Special timer was NULL – recreating");
        g_hSpecialRebreather = CreateTimer(gC_SpecialRebreather.FloatValue, Timer_SpecialRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
        g_fSpecialTimerStart = GetEngineTime();
    }
    if (g_bBossBlockActive && g_hBossRebreather == null)
    {
        if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] Timer_Check: Boss timer was NULL – recreating");
        g_hBossRebreather = CreateTimer(gC_BossRebreather.FloatValue, Timer_BossRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
        g_fBossTimerStart = GetEngineTime();
    }
    if (g_bFatigueBlockActive && g_hFatigueRebreather == null)
    {
        if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] Timer_Check: Fatigue timer was NULL – recreating");
        g_hFatigueRebreather = CreateTimer(gC_FatigueRebreather.FloatValue, Timer_FatigueRebreatherEnd, _, TIMER_FLAG_NO_MAPCHANGE);
        g_fFatigueTimerStart = GetEngineTime();
    }

    ApplyHordeDecay();
    ApplySpecialDecay();
    ApplyBossDecay();
    ApplyFatigueDecay();

    CheckHordeFlowUnblock();
    CheckSpecialFlowUnblock();
    CheckBossFlowUnblock();
    CheckFatigueFlowUnblock();

    EvaluateHordeBlocking();
    EvaluateSpecialBlocking();
    EvaluateBossBlocking();
    EvaluateFatigueBlocking();

    return Plugin_Continue;
}

public Action Timer_HUD(Handle timer, any data)
{
    if (!gC_Enable.BoolValue || !g_bModeAllowed) return Plugin_Continue;

    char msg[256] = "";
    float curFlow = GetFarthestFlowDistance();

    if (gC_HordeHUD.BoolValue)
    {
        char h[64];
        Format(h, sizeof(h), "Horde: %.2f / %.1f%s",
            g_fHordeIntensity, gC_HordeThreshold.FloatValue,
            g_bHordeBlockActive ? " (BLOCKED)" : "");
        if (g_bHordeBlockActive && g_fHordeFlowUnblockCurrent > 0.0)
        {
            float traveled = curFlow - g_fHordeBlockStartFlow;
            char flowStr[32];
            Format(flowStr, sizeof(flowStr), " Flow: %.0f / %.0f", traveled, g_fHordeFlowUnblockCurrent);
            StrCat(h, sizeof(h), flowStr);
        }
        StrCat(msg, sizeof(msg), h);
        StrCat(msg, sizeof(msg), "\n");
    }

    if (gC_SpecialHUD.BoolValue)
    {
        char s[64];
        Format(s, sizeof(s), "Special: %.2f / %.1f%s",
            g_fSpecialIntensity, gC_SpecialThreshold.FloatValue,
            g_bSpecialBlockActive ? " (BLOCKED)" : "");
        if (g_bSpecialBlockActive && g_fSpecialFlowUnblockCurrent > 0.0)
        {
            float traveled = curFlow - g_fSpecialBlockStartFlow;
            char flowStr[32];
            Format(flowStr, sizeof(flowStr), " Flow: %.0f / %.0f", traveled, g_fSpecialFlowUnblockCurrent);
            StrCat(s, sizeof(s), flowStr);
        }
        StrCat(msg, sizeof(msg), s);
        StrCat(msg, sizeof(msg), "\n");
    }

    if (gC_BossHUD.BoolValue)
    {
        char b[64];
        Format(b, sizeof(b), "Boss: %.2f / %.1f%s",
            g_fBossIntensity, gC_BossThreshold.FloatValue,
            g_bBossBlockActive ? " (BLOCKED)" : "");
        if (g_bBossBlockActive && g_fBossFlowUnblockCurrent > 0.0)
        {
            float traveled = curFlow - g_fBossBlockStartFlow;
            char flowStr[32];
            Format(flowStr, sizeof(flowStr), " Flow: %.0f / %.0f", traveled, g_fBossFlowUnblockCurrent);
            StrCat(b, sizeof(b), flowStr);
        }
        StrCat(msg, sizeof(msg), b);
        StrCat(msg, sizeof(msg), "\n");
    }

    if (gC_FatigueHUD.BoolValue)
    {
        char f[64];
        Format(f, sizeof(f), "Fatigue: %.2f / %.1f%s",
            g_fFatigue, gC_FatigueThreshold.FloatValue,
            g_bFatigueBlockActive ? " (BLOCKED)" : "");
        if (g_bFatigueBlockActive && g_fFatigueFlowUnblockCurrent > 0.0)
        {
            float traveled = curFlow - g_fFatigueBlockStartFlow;
            char flowStr[32];
            Format(flowStr, sizeof(flowStr), " Flow: %.0f / %.0f", traveled, g_fFatigueFlowUnblockCurrent);
            StrCat(f, sizeof(f), flowStr);
        }
        StrCat(msg, sizeof(msg), f);
    }

    if (msg[0]) ShowHudToRootAdmins(msg);
    return Plugin_Continue;
}

public void Event_ClearState(Event event, const char[] name, bool dontBroadcast)
{
    if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] Event_ClearState triggered: event=%s", name);

    if (StrEqual(name, "map_transition"))
    {
        float curFlow = GetFarthestFlowDistance();
        float now = GetEngineTime();

        if (g_bHordeBlockActive)
        {
            g_fHordeRemainingFlow = g_fHordeFlowUnblockCurrent - (curFlow - g_fHordeBlockStartFlow);
            if (g_fHordeRemainingFlow < 0.0) g_fHordeRemainingFlow = 0.0;
            g_bHordeBlockCarryover = true;
            float elapsed = now - g_fHordeTimerStart;
            float remaining = gC_HordeRebreather.FloatValue - elapsed;
            g_fHordeRemainingTime = (remaining > 0.0) ? remaining : 0.0;
        }
        if (g_bSpecialBlockActive)
        {
            g_fSpecialRemainingFlow = g_fSpecialFlowUnblockCurrent - (curFlow - g_fSpecialBlockStartFlow);
            if (g_fSpecialRemainingFlow < 0.0) g_fSpecialRemainingFlow = 0.0;
            g_bSpecialBlockCarryover = true;
            float elapsed = now - g_fSpecialTimerStart;
            float remaining = gC_SpecialRebreather.FloatValue - elapsed;
            g_fSpecialRemainingTime = (remaining > 0.0) ? remaining : 0.0;
        }
        if (g_bBossBlockActive)
        {
            g_fBossRemainingFlow = g_fBossFlowUnblockCurrent - (curFlow - g_fBossBlockStartFlow);
            if (g_fBossRemainingFlow < 0.0) g_fBossRemainingFlow = 0.0;
            g_bBossBlockCarryover = true;
            float elapsed = now - g_fBossTimerStart;
            float remaining = gC_BossRebreather.FloatValue - elapsed;
            g_fBossRemainingTime = (remaining > 0.0) ? remaining : 0.0;
            if (gC_DebugRebreather.BoolValue)
                LogToFileEx(g_sLogPath, "[BOSSDBG] Map transition – saving carryover: blockActive=%d curFlow=%.0f startFlow=%.0f unblockNeed=%.0f remainingFlow=%.0f remainingTime=%.1f",
                    g_bBossBlockActive, curFlow, g_fBossBlockStartFlow, g_fBossFlowUnblockCurrent, g_fBossRemainingFlow, g_fBossRemainingTime);
        }
        if (g_bFatigueBlockActive)
        {
            g_fFatigueRemainingFlow = g_fFatigueFlowUnblockCurrent - (curFlow - g_fFatigueBlockStartFlow);
            if (g_fFatigueRemainingFlow < 0.0) g_fFatigueRemainingFlow = 0.0;
            g_bFatigueBlockCarryover = true;
            float elapsed = now - g_fFatigueTimerStart;
            float remaining = gC_FatigueRebreather.FloatValue - elapsed;
            g_fFatigueRemainingTime = (remaining > 0.0) ? remaining : 0.0;
        }
    }

    g_bEventActive = false;
    KillAllTimers();
    g_bHordeBlockActive = false;
    g_bSpecialBlockActive = false;
    g_bBossBlockActive = false;
    g_bFatigueBlockActive = false;
    g_bFinaleActive = false;
    if (g_hSkipTimer != null) { KillTimer(g_hSkipTimer); g_hSkipTimer = null; }
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    if (gC_DebugRebreather.BoolValue) LogToFileEx(g_sLogPath, "[BOSSDBG] Event_RoundStart triggered");

    g_bEventActive = true;
    g_bLeftSafeArea = false;
    g_fSafeAreaLeaveTime = 0.0;
    g_bFinaleActive = false;
    if (g_hSkipTimer != null) { KillTimer(g_hSkipTimer); g_hSkipTimer = null; }

    if (L4D_HasAnySurvivorLeftSafeArea())
    {
        g_bLeftSafeArea = true;
        g_fSafeAreaLeaveTime = GetEngineTime();
    }

    EvaluateHordeBlocking();
    EvaluateSpecialBlocking();
    EvaluateBossBlocking();
    EvaluateFatigueBlocking();
}

public void Event_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
    if (!gC_Enable.BoolValue || !g_bModeAllowed) return;

    g_bFinaleActive = true;

    if (!gC_CoverFinales.BoolValue)
    {
        KillAllTimers();
        g_bHordeBlockActive = false;
        g_bSpecialBlockActive = false;
        g_bBossBlockActive = false;
        g_bFatigueBlockActive = false;
    }
    else
    {
        if (gC_NoFatigueFinale.BoolValue && gC_FatigueEnable.BoolValue && g_bFatigueBlockActive)
        {
            if (g_hFatigueRebreather != null)
            {
                KillTimer(g_hFatigueRebreather);
                g_hFatigueRebreather = null;
            }
            g_bFatigueBlockActive = false;
            EvaluateFinaleSkip();
        }

        bool shouldSkip = (g_bFatigueBlockActive) || (g_bHordeBlockActive && g_bBossBlockActive);
        if (shouldSkip)
        {
            float delay = gC_SkipDelay.FloatValue;
            if (delay <= 0.0)
                ForceFinaleEnd();
            else
            {
                if (g_hSkipTimer != null) KillTimer(g_hSkipTimer);
                g_hSkipTimer = CreateTimer(delay, Timer_FinaleSkip, _, TIMER_FLAG_NO_MAPCHANGE);
            }
        }
    }

    ApplyDisasterFatigueBump();
    EvaluateFinaleSkip();
}

public Action L4D_OnSpawnMob(int &amount)
{
    if (!gC_Enable.BoolValue || !g_bModeAllowed) return Plugin_Continue;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return Plugin_Continue;
    if (g_bHordeBlockActive || g_bFatigueBlockActive) { DebugLog("Mob BLOCKED"); return Plugin_Handled; }
    return Plugin_Continue;
}

public Action L4D_OnSpawnSpecial(int &zombieClass, const float vecOrigin[3], const float vecAngles[3])
{
    if (!gC_Enable.BoolValue || !g_bModeAllowed) return Plugin_Continue;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return Plugin_Continue;
    if (g_bSpecialBlockActive || g_bFatigueBlockActive) { DebugLog("Special BLOCKED"); return Plugin_Handled; }
    return Plugin_Continue;
}

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!gC_Enable.BoolValue || !g_bModeAllowed) return;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return;

    if ((g_bBossBlockActive || g_bFatigueBlockActive) && (StrEqual(classname, "tank") || StrEqual(classname, "witch")))
    {
        if (StrEqual(classname, "tank") && IsMapTankAllowed())
            return;

        if (g_bFinaleActive && !IsOfficialFinaleMap())
        {
            SDKHook(entity, SDKHook_SpawnPost, OnBossSpawnPost);
            return;
        }
        AcceptEntityInput(entity, "Kill");
    }
}

public Action L4D_OnSpawnTank(const float vecOrigin[3], const float vecAngles[3])
{
    if (!gC_Enable.BoolValue || !g_bModeAllowed) return Plugin_Continue;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return Plugin_Continue;
    if (g_bBossBlockActive || g_bFatigueBlockActive)
    {
        if (IsMapTankAllowed())
            return Plugin_Continue;
        if (g_bFinaleActive && !IsOfficialFinaleMap())
            return Plugin_Continue;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action L4D_OnSpawnWitch(const float vecOrigin[3], const float vecAngles[3])
{
    if (!gC_Enable.BoolValue || !g_bModeAllowed) return Plugin_Continue;
    if (g_bFinaleActive && !gC_CoverFinales.BoolValue) return Plugin_Continue;
    if (g_bBossBlockActive || g_bFatigueBlockActive)
    {
        if (g_bFinaleActive && !IsOfficialFinaleMap())
            return Plugin_Continue;
        return Plugin_Handled;
    }
    return Plugin_Continue;
}

public Action Cmd_DetectIntensity(int client, int args)
{
    ReplyToCommand(client, "\x04[DirectorIntensity] \x01Horde %.2f/%.1f | Special %.2f/%.1f | Boss %.2f/%.1f | Fatigue %.2f/%.1f | %s",
        g_fHordeIntensity, gC_HordeThreshold.FloatValue,
        g_fSpecialIntensity, gC_SpecialThreshold.FloatValue,
        g_fBossIntensity, gC_BossThreshold.FloatValue,
        g_fFatigue, gC_FatigueThreshold.FloatValue,
        IsAnyBlockActive() ? "\x03BLOCKED" : "\x04ALLOWED");
    return Plugin_Handled;
}