#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS FCVAR_NOTIFY

public Plugin myinfo =
{
    name        = "[L4D2] Finale Fail Ending",
    author      = "Tighty-Whitey",
    description = "Converts finale failure into a stats outro.",
    version     = "1.2",
    url         = ""
};

/*======================================================================================
    Change Log:

    1.2

    - Added cvar l4d2_finale_fail_ending_accept_delay to delay accepting the finale fail ending. Requested by TBK Duy.
    - Extra potential softlock preventions were added.

    1.1

    - Attempted to fix rare edge-case softlock.

    1.0 (Initial release)

    - Initial release.

======================================================================================*/

ConVar gC_FinishToStatsDelay;
ConVar gC_AcceptDelay;
ConVar gC_Debug;
char g_sLogPath[PLATFORM_MAX_PATH];

ConVar gC_Enable;
ConVar gC_Modes;
ConVar gC_MapsOff;
ConVar gC_MPGameMode;
ConVar gC_NoDeathCheck = null;

int  g_iNoDeathPrev     = 0;
bool g_bDeathLocked     = false;
bool g_bCvarAllow       = true;
bool g_bFinaleActive    = false;
bool g_bAlreadyForced   = false;
bool g_bOutroStarted    = false;
bool g_bRescueLeaving   = false;

float g_fTakeoverAt          = 0.0;
bool  g_bVanillaFailStarted  = false;

bool g_bWipeDecisionMade = false;
bool g_bForceOutroThisWipe = false;

int g_iTakeDamagePrev[MAXPLAYERS + 1];
bool g_bTakeDamageSaved[MAXPLAYERS + 1];

Handle g_hStats    = null;
Handle g_hKeepLock = null;

int g_iFinaleRef = INVALID_ENT_REFERENCE;
bool g_bSeenFinaleStartThisMap = false;

public void OnPluginStart()
{
    gC_Enable = CreateConVar("l4d2_finale_fail_ending_enable", "1", "0=Plugin off, 1=Plugin on.", CVAR_FLAGS);
    gC_Modes  = CreateConVar("l4d2_finale_fail_ending_modes", "coop,realism", "Turn on the plugin in these game modes, separate by commas (no spaces). Empty = all.", CVAR_FLAGS);
    gC_MapsOff = CreateConVar("l4d2_finale_fail_ending_maps_off", "", "Turn off the plugin on these maps, separate by commas (no spaces). Empty = none.", CVAR_FLAGS);
    gC_FinishToStatsDelay = CreateConVar("l4d2_finale_fail_ending_finish_to_stats_delay", "0.35", "Delay after FinaleEscapeFinished before env_outtro_stats.RollStatsCrawl (sec).", CVAR_FLAGS);
    gC_AcceptDelay = CreateConVar("l4d2_finale_fail_ending_accept_delay", "0", "Grace period from finale start before the plugin forces the stats outro on wipe (sec). 0 = always force outro.", CVAR_FLAGS);
    gC_Debug = CreateConVar("l4d2_finale_fail_ending_debug", "0", "0=Disable debug log file, 1=Enable debug log file (logs/l4d2_finale_fail_ending_debug.log).", CVAR_FLAGS);
    BuildPath(Path_SM, g_sLogPath, sizeof(g_sLogPath), "logs/l4d2_finale_fail_ending_debug.log");

    AutoExecConfig(true, "l4d2_finale_fail_ending");

    gC_MPGameMode = FindConVar("mp_gamemode");
    if (gC_MPGameMode != null) gC_MPGameMode.AddChangeHook(CvarChanged_Allow);
    gC_Enable.AddChangeHook(CvarChanged_Allow);
    gC_Modes.AddChangeHook(CvarChanged_Allow);
    gC_MapsOff.AddChangeHook(CvarChanged_Allow);
    gC_AcceptDelay.AddChangeHook(CvarChanged_Delay);

    IsAllowed();

    gC_NoDeathCheck = FindConVar("director_no_death_check");
    if (gC_NoDeathCheck != null) g_iNoDeathPrev = gC_NoDeathCheck.IntValue;

    HookEvent("finale_start",         E_FinaleStart,       EventHookMode_PostNoCopy);
    HookEvent("finale_radio_start",   E_FinaleStart,       EventHookMode_PostNoCopy);
    HookEvent("gauntlet_finale_start",E_FinaleStart,       EventHookMode_PostNoCopy);
    HookEvent("finale_vehicle_leaving", E_VehicleLeaving,  EventHookMode_PostNoCopy);
    HookEvent("finale_win",           E_FinaleEnd,         EventHookMode_PostNoCopy);
    HookEvent("map_transition",       E_MapTransition,     EventHookMode_PostNoCopy);
    HookEvent("round_end",            E_RoundEnd,          EventHookMode_PostNoCopy);
    HookEvent("round_start",         E_RoundStart,        EventHookMode_PostNoCopy);

    HookEvent("player_death",                E_PlayerStateChange, EventHookMode_Post);
    HookEvent("player_incapacitated",        E_PlayerStateChange, EventHookMode_Post);
    HookEvent("player_incapacitated_start",  E_PlayerStateChange, EventHookMode_Post);
    HookEvent("player_ledge_grab",           E_PlayerStateChange, EventHookMode_Post);
    HookEvent("player_ledge_release",        E_PlayerStateChange, EventHookMode_Post);

    HookEvent("mission_lost", E_MissionLost, EventHookMode_Pre);

    // Block common restart/changelevel commands while forced outro is active.
    AddCommandListener(Cmd_BlockDuringOutro, "changelevel");
    AddCommandListener(Cmd_BlockDuringOutro, "map");
    AddCommandListener(Cmd_BlockDuringOutro, "mp_restartgame");
    AddCommandListener(Cmd_BlockDuringOutro, "mp_restartgame_immediate");
    AddCommandListener(Cmd_BlockDuringOutro, "restart");
    AddCommandListener(Cmd_BlockDuringOutro, "director_restart");
    AddCommandListener(Cmd_BlockDuringOutro, "director_force_restart");

}

public void OnMapStart()
{
    ResetState();

    g_bSeenFinaleStartThisMap = false;
    g_iFinaleRef = INVALID_ENT_REFERENCE;

    IsAllowed();

    if (gC_NoDeathCheck != null)
    {
        g_iNoDeathPrev = gC_NoDeathCheck.IntValue;
        g_bDeathLocked = false;
    }
}

public void OnConfigsExecuted()
{
    IsAllowed();
}

public void OnMapEnd()
{
    KillTimerSafe(g_hStats);
    KillTimerSafe(g_hKeepLock);

    RestoreDeathCheck();
    ResetState();

    g_bSeenFinaleStartThisMap = false;
    g_iFinaleRef = INVALID_ENT_REFERENCE;
}

void FreezeSurvivorsDamage()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != 2) continue;
        if (!HasEntProp(i, Prop_Data, "m_takedamage")) continue;

        if (!g_bTakeDamageSaved[i])
        {
            g_iTakeDamagePrev[i] = GetEntProp(i, Prop_Data, "m_takedamage");
            g_bTakeDamageSaved[i] = true;
        }        SetEntProp(i, Prop_Data, "m_takedamage", 0);
    }
}

void RestoreSurvivorsDamage()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (!g_bTakeDamageSaved[i]) continue;
        if (!IsClientInGame(i)) { g_bTakeDamageSaved[i] = false; continue; }
        if (!HasEntProp(i, Prop_Data, "m_takedamage")) { g_bTakeDamageSaved[i] = false; continue; }

        SetEntProp(i, Prop_Data, "m_takedamage", g_iTakeDamagePrev[i]);
        g_bTakeDamageSaved[i] = false;
    }
}

void ResetState()
{

    RestoreSurvivorsDamage();
    g_bFinaleActive       = false;
    g_bAlreadyForced      = false;
    g_bOutroStarted       = false;
    g_bRescueLeaving      = false;
    g_fTakeoverAt         = 0.0;
    g_bVanillaFailStarted = false;

    g_bWipeDecisionMade = false;
    g_bForceOutroThisWipe = false;

    g_iFinaleRef = INVALID_ENT_REFERENCE;
}

void KillTimerSafe(Handle &h)
{
    if (h != null)
    {
        CloseHandle(h);
        h = null;
    }
}

void DbgLog(const char[] fmt, any ...)
{
    if (gC_Debug != null && !gC_Debug.BoolValue) return;

    char msg[512];
    VFormat(msg, sizeof(msg), fmt, 2);
    LogToFileEx(g_sLogPath, "%s", msg);
}

void DbgLogState(const char[] tag)
{
    DbgLog(
        "[%s] t=%.3f allow=%d finaleActive=%d outro=%d rescueLeaving=%d alreadyForced=%d vanilla=%d takeAt=%.3f",
        tag,
        GetGameTime(),
        g_bCvarAllow,
        g_bFinaleActive,
        g_bOutroStarted,
        g_bRescueLeaving,
        g_bAlreadyForced,
        g_bVanillaFailStarted,
        g_fTakeoverAt
    );
}

void CvarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
    IsAllowed();
}

void CvarChanged_Delay(ConVar convar, const char[] oldValue, const char[] newValue)
{
    if (!g_bCvarAllow) return;
    if (!IsFinaleContext()) return;

    float d = (gC_AcceptDelay != null) ? gC_AcceptDelay.FloatValue : 0.0;
    if (d < 0.0) d = 0.0;

    g_fTakeoverAt = GetGameTime() + d;

    if (d <= 0.0)
    {
        LockDeathCheck();
    }
    else if (!g_bOutroStarted)
    {
        RestoreDeathCheck();
    }
}

void IsAllowed()
{
    bool allow = (gC_Enable != null) ? gC_Enable.BoolValue : true;
    bool mode  = IsAllowedGameMode();
    bool maps  = !IsBlockedMap();

    g_bCvarAllow = (allow && mode && maps);

    if (!g_bCvarAllow)
    {
        KillTimerSafe(g_hKeepLock);
        RestoreDeathCheck();
    }
}

bool IsAllowedGameMode()
{
    if (gC_MPGameMode == null) gC_MPGameMode = FindConVar("mp_gamemode");
    if (gC_MPGameMode == null) return false;

    char mode[64];
    gC_MPGameMode.GetString(mode, sizeof(mode));
    Format(mode, sizeof(mode), ",%s,", mode);

    char modes[256];
    if (gC_Modes != null) gC_Modes.GetString(modes, sizeof(modes));
    else modes[0] = '\0';

    if (!modes[0]) return true;

    Format(modes, sizeof(modes), ",%s,", modes);
    return (StrContains(modes, mode, false) != -1);
}

bool IsBlockedMap()
{
    if (gC_MapsOff == null) return false;

    char maps[512];
    gC_MapsOff.GetString(maps, sizeof(maps));
    if (!maps[0]) return false;

    char map[64];
    GetCurrentMap(map, sizeof(map));
    Format(map, sizeof(map), ",%s,", map);
    Format(maps, sizeof(maps), ",%s,", maps);

    return (StrContains(maps, map, false) != -1);
}

void StartKeepLock()
{
    if (g_hKeepLock != null) return;
    g_hKeepLock = CreateTimer(1.0, T_KeepLock, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action T_KeepLock(Handle t)
{
    if (!g_bCvarAllow || (!g_bFinaleActive && !g_bOutroStarted))
    {
        g_hKeepLock = null;
        return Plugin_Stop;
    }

    if (gC_NoDeathCheck != null && g_bDeathLocked)
    {
        if (gC_NoDeathCheck.IntValue != 1)
            gC_NoDeathCheck.SetInt(1);
    }

    return Plugin_Continue;
}

void LockDeathCheck()
{
    if (gC_NoDeathCheck == null) return;

    if (!g_bDeathLocked)
    {
        g_iNoDeathPrev = gC_NoDeathCheck.IntValue;
        g_bDeathLocked = true;
    }

    if (gC_NoDeathCheck.IntValue != 1)
        gC_NoDeathCheck.SetInt(1);

    StartKeepLock();
}

void RestoreDeathCheck()
{
    if (gC_NoDeathCheck == null || !g_bDeathLocked) return;

    gC_NoDeathCheck.SetInt(g_iNoDeathPrev);
    g_bDeathLocked = false;
}

public void E_FinaleStart(Event e, const char[] n, bool b)
{
    DbgLogState("finale_start");

    if (!g_bCvarAllow) return;

        g_bFinaleActive = true;
    g_bAlreadyForced = false;
    g_bOutroStarted = false;
    g_bRescueLeaving = false;
    g_bVanillaFailStarted = false;
    g_bWipeDecisionMade = false;
    g_bForceOutroThisWipe = false;

    float d = (gC_AcceptDelay != null) ? gC_AcceptDelay.FloatValue : 0.0;
    if (d < 0.0) d = 0.0;

    g_fTakeoverAt = GetGameTime() + d;

    if (d <= 0.0)
        LockDeathCheck();
}

public void E_FinaleEnd(Event e, const char[] n, bool b)
{
    DbgLogState("finale_win");

    if (g_bOutroStarted)
    {
        DbgLogState("finale_win_IGNORED_OUTRO");
        LockDeathCheck();
        return;
    }

    g_fTakeoverAt = 0.0;
    g_bVanillaFailStarted = false;
    g_bFinaleActive = false;
    g_bAlreadyForced = false;

    KillTimerSafe(g_hStats);
    KillTimerSafe(g_hKeepLock);
    RestoreDeathCheck();
}



public void E_MapTransition(Event e, const char[] n, bool b)
{
    DbgLogState("map_transition");

    if (g_bOutroStarted)
    {
        DbgLogState("map_transition_IGNORED_OUTRO");
        LockDeathCheck();
        return;
    }

    g_fTakeoverAt = 0.0;
    g_bVanillaFailStarted = false;
    g_bFinaleActive = false;
    g_bAlreadyForced = true;

    KillTimerSafe(g_hStats);
    KillTimerSafe(g_hKeepLock);
    RestoreDeathCheck();
}



public void E_RoundEnd(Event e, const char[] n, bool b)
{
    DbgLogState("round_end");

    if (g_bOutroStarted)
    {
        DbgLogState("round_end_IGNORED_OUTRO");
        LockDeathCheck();
        return;
    }

    g_fTakeoverAt = 0.0;
    g_bVanillaFailStarted = false;
    g_bFinaleActive = false;
    g_bAlreadyForced = false;

    KillTimerSafe(g_hStats);
    KillTimerSafe(g_hKeepLock);
    RestoreDeathCheck();
}



public void E_RoundStart(Event e, const char[] n, bool b)
{
    DbgLogState("round_start");
    if (g_bOutroStarted || g_bDeathLocked)
    {
        DbgLogState("round_start_hard_reset");

        KillTimerSafe(g_hStats);
        KillTimerSafe(g_hKeepLock);

        RestoreDeathCheck();
        EnableAllFinaleTriggers();

        ResetState();
        g_bSeenFinaleStartThisMap = false;
        g_iFinaleRef = INVALID_ENT_REFERENCE;
    }
}

public void E_VehicleLeaving(Event e, const char[] n, bool b)
{
    DbgLogState("vehicle_leaving");
    if (!g_bCvarAllow) return;
    if (!g_bFinaleActive) return;

    g_bRescueLeaving = true;
        LockDeathCheck();
}

public void E_PlayerStateChange(Event e, const char[] n, bool b)
{
    if (!g_bCvarAllow) return;
    if (!IsFinaleContext()) return;
    if (g_bAlreadyForced || g_bOutroStarted) return;

    if (!AllSurvivorsUnableToStand())
        return;
    if (g_bVanillaFailStarted)
        return;
    if (!g_bWipeDecisionMade)
    {
        g_bWipeDecisionMade = true;
        if (g_bRescueLeaving)
        {
            g_bForceOutroThisWipe = true;
        }
        else
        {
            float d = (gC_AcceptDelay != null) ? gC_AcceptDelay.FloatValue : 0.0;
            if (d < 0.0) d = 0.0;

            if (d <= 0.0)
                g_bForceOutroThisWipe = true;
            else
                g_bForceOutroThisWipe = (GetGameTime() >= g_fTakeoverAt);
        }

        if (!g_bForceOutroThisWipe)
        {
            DbgLogState("wipe_vanilla");
            g_bVanillaFailStarted = true;
            return;
        }
    }

    if (!g_bForceOutroThisWipe)
        return;

    DbgLogState("wipe_force_outro");

    g_bAlreadyForced = true;
    LockDeathCheck();
    RequestFrame(RF_ForceOutro);
}

public Action E_MissionLost(Event e, const char[] n, bool b)
{
    DbgLogState("mission_lost");

    if (!g_bCvarAllow) return Plugin_Continue;
    if (g_bOutroStarted)
    {
        LockDeathCheck();
        return Plugin_Handled;
    }

    if (!IsFinaleContext()) return Plugin_Continue;
    if (g_bRescueLeaving)
    {
        LockDeathCheck();

        if (!g_bOutroStarted)
        {
            g_bForceOutroThisWipe = true;
            g_bWipeDecisionMade = true;

            if (!g_bAlreadyForced) g_bAlreadyForced = true;
            RequestFrame(RF_ForceOutro);
        }

        return Plugin_Handled;
    }
    if (g_bVanillaFailStarted)
        return Plugin_Continue;
    if (!g_bWipeDecisionMade)
    {
        g_bWipeDecisionMade = true;

        float d = (gC_AcceptDelay != null) ? gC_AcceptDelay.FloatValue : 0.0;
        if (d < 0.0) d = 0.0;

        if (d <= 0.0)
            g_bForceOutroThisWipe = true;
        else
            g_bForceOutroThisWipe = (GetGameTime() >= g_fTakeoverAt);
    }
    if (!g_bForceOutroThisWipe)
    {
        g_bVanillaFailStarted = true;
        return Plugin_Continue;
    }

    LockDeathCheck();

    if (!g_bOutroStarted)
        g_bAlreadyForced = true;

    FreezeSurvivorsDamage();
    RequestFrame(RF_ForceOutro);
    return Plugin_Handled;
}




public void RF_ForceOutro(any data)
{
    ForceOutroNow();
}

bool IsFinaleContext()
{
    if (g_bFinaleActive) return true;

    if (!g_bSeenFinaleStartThisMap) return false;

    return (GetActiveFinaleController() != -1);
}

void DisableAllFinaleTriggers()
{
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "trigger_finale")) != -1)
    {
        AcceptEntityInput(ent, "Disable");
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "trigger_finale_dlc3")) != -1)
    {
        AcceptEntityInput(ent, "Disable");
    }
}
void EnableAllFinaleTriggers()
{
    int ent = -1;
    while ((ent = FindEntityByClassname(ent, "trigger_finale")) != -1)
        AcceptEntityInput(ent, "Enable");

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "trigger_finale_dlc3")) != -1)
        AcceptEntityInput(ent, "Enable");
}

void ForceOutroNow()
{
    if (g_bOutroStarted) return;
    if (g_bVanillaFailStarted) return;

    int finale = GetActiveFinaleController();
    if (finale == -1)
    {
        RequestFrame(RF_ForceOutro);
        return;
    }

    g_bOutroStarted = true;
    g_bFinaleActive = true;

    DbgLogState("outro_start");

    DisableAllFinaleTriggers();
    LockDeathCheck();

    int stats = FindEntityByClassname(-1, "env_outtro_stats");

    DbgLogState("Trigger_FinaleEscapeFinished");
    AcceptEntityInput(finale, "FinaleEscapeFinished");    AcceptEntityInput(finale, "Disable");

    if (stats == -1) return;

    float gap = gC_FinishToStatsDelay.FloatValue;
    if (gap < 0.0) gap = 0.0;

    KillTimerSafe(g_hStats);
    g_hStats = CreateTimer(gap, T_RollStats, EntIndexToEntRef(stats), TIMER_FLAG_NO_MAPCHANGE);
}

public Action T_RollStats(Handle t, any ref)
{
    g_hStats = null;

    int stats = EntRefToEntIndex(ref);
    if (stats != -1)
        AcceptEntityInput(stats, "RollStatsCrawl");

    return Plugin_Stop;
}

static bool IsEntDisabled(int ent)
{
    if (ent <= 0 || !IsValidEntity(ent)) return true;

    if (HasEntProp(ent, Prop_Data, "m_bDisabled"))
        return (GetEntProp(ent, Prop_Data, "m_bDisabled") != 0);

    return false;
}

static bool GetEntOriginSafe(int ent, float o[3])
{
    if (HasEntProp(ent, Prop_Send, "m_vecOrigin"))
    {
        GetEntPropVector(ent, Prop_Send, "m_vecOrigin", o);
        return true;
    }

    if (HasEntProp(ent, Prop_Data, "m_vecAbsOrigin"))
    {
        GetEntPropVector(ent, Prop_Data, "m_vecAbsOrigin", o);
        return true;
    }

    return false;
}

static bool GetSurvivorCentroid(float outPos[3])
{
    float s[3] = {0.0, 0.0, 0.0};
    int c = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != 2) continue;

        float p[3];
        GetClientAbsOrigin(i, p);

        s[0] += p[0];
        s[1] += p[1];
        s[2] += p[2];

        c++;
    }

    if (!c) return false;

    outPos[0] = s[0] / float(c);
    outPos[1] = s[1] / float(c);
    outPos[2] = s[2] / float(c);

    return true;
}

int FindActiveFinaleTrigger()
{
    int list[64];
    int n = 0;
    int ent = -1;

    while ((ent = FindEntityByClassname(ent, "trigger_finale")) != -1 && n < 64)
    {
        if (!IsEntDisabled(ent)) list[n++] = ent;
    }

    ent = -1;
    while ((ent = FindEntityByClassname(ent, "trigger_finale_dlc3")) != -1 && n < 64)
    {
        if (!IsEntDisabled(ent)) list[n++] = ent;
    }

    if (n == 0) return -1;

    float team[3];
    if (!GetSurvivorCentroid(team)) return list[0];

    float best = 1.0e12;
    int   pick = list[0];

    for (int i = 0; i < n; i++)
    {
        float o[3];
        if (!GetEntOriginSafe(list[i], o)) continue;

        float dx = o[0] - team[0];
        float dy = o[1] - team[1];
        float dz = o[2] - team[2];

        float d = dx*dx + dy*dy + dz*dz;
        if (d < best)
        {
            best = d;
            pick = list[i];
        }
    }

    return pick;
}

int GetActiveFinaleController()
{
    int e = EntRefToEntIndex(g_iFinaleRef);
    if (e != -1 && !IsEntDisabled(e)) return e;

    e = FindActiveFinaleTrigger();
    g_iFinaleRef = (e != -1) ? EntIndexToEntRef(e) : INVALID_ENT_REFERENCE;
    return e;
}

static bool IsPlayerHanging(int client)
{
    if (client <= 0 || client > MaxClients) return false;
    if (!IsClientInGame(client) || GetClientTeam(client) != 2) return false;
    if (!IsPlayerAlive(client)) return false;

    if (HasEntProp(client, Prop_Send, "m_isHangingFromLedge"))
    {
        if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge") != 0) return true;
    }

    if (HasEntProp(client, Prop_Send, "m_isFallingFromLedge"))
    {
        if (GetEntProp(client, Prop_Send, "m_isFallingFromLedge") != 0) return true;
    }

    return false;
}

bool AllSurvivorsUnableToStand()
{
    int aliveStanding = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (!IsClientInGame(i) || GetClientTeam(i) != 2) continue;
        if (!IsPlayerAlive(i)) continue;
        if (GetEntProp(i, Prop_Send, "m_isIncapacitated") != 0) continue;
        if (IsPlayerHanging(i)) continue;

        aliveStanding++;
    }

    return (aliveStanding == 0);
}


public Action Cmd_BlockDuringOutro(int client, const char[] command, int argc)
{
    if (!g_bCvarAllow) return Plugin_Continue;    if (client == 0) return Plugin_Continue;

    if (g_bOutroStarted)
    {
        DbgLogState("BLOCK_CMD");
        DbgLog("Blocking command during outro: %s", command);
        return Plugin_Handled;
    }

    return Plugin_Continue;
}
