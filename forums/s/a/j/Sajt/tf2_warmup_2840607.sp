#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <morecolors>


#define DEFAULT_WARMUP_COOLDOWN 60.0

bool g_bWarmup = false;
Handle g_hTimerRespawn = INVALID_HANDLE;
Handle g_hTimerCountdown = INVALID_HANDLE;
Handle g_hTimerEndWarmup = INVALID_HANDLE;
bool g_bWarmupStarted = false;
float g_iCountdownTime = DEFAULT_WARMUP_COOLDOWN;
bool g_bFirstRound = true;

// ===== CONVARS ===== //
ConVar g_hCvarWarmupTime;
ConVar g_hCvarWarmupEnabled;

public Plugin myinfo = 
{
    name = "[TF2] Warmup",
    author = "Sajt",
    description = "Simple TF2 warmup plugin with adjustable duration and instant respawn support",
    version = "1.5",
};

public void OnPluginStart()
{
    g_hCvarWarmupTime = CreateConVar("sm_warmup_time", "60.0", "Warmup duration in seconds", FCVAR_NOTIFY, true, 10.0, true, 600.0);
    g_hCvarWarmupEnabled = CreateConVar("sm_warmup_enabled", "1", "Enable or disable automatic warmup (1 = enabled, 0 = disabled)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
    
    //RegAdminCmd("sm_startwarmup", Command_StartWarmup, ADMFLAG_GENERIC);
    RegAdminCmd("sm_cancelwarmup", Command_StopWarmup, ADMFLAG_GENERIC);
    RegAdminCmd("sm_warmup_toggle", Command_ToggleWarmup, ADMFLAG_GENERIC);
    
    AutoExecConfig(true, "TF2_Warmup");
    
    HookEvent("arena_round_start", TF2_ArenaRoundStart);
    HookEvent("teamplay_round_win", TF2_OnRoundEnd);
}

public void OnMapStart() 
{
    g_bWarmupStarted = false;
    g_bWarmup = false;
    g_iCountdownTime = DEFAULT_WARMUP_COOLDOWN;
}

public Action Command_ToggleWarmup(int client, int args)
{
    bool bEnabled = GetConVarBool(g_hCvarWarmupEnabled);
    SetConVarBool(g_hCvarWarmupEnabled, !bEnabled);

    MC_PrintToChatAll("{orange}[Warmup]{default} Warmup has been %s!", !bEnabled ? "{green}ENABLED" : "{red}DISABLED");
    PrintToServer("[Warmup] Warmup %s.", !bEnabled ? "ENABLED" : "DISABLED");
    return Plugin_Handled;
}

public Action Command_StopWarmup(int client, int args)
{
    if (!g_bWarmup)
    {
        ReplyToCommand(client, "{orange}[Warmup] {default}There is no active warmup to stop.");
        return Plugin_Handled;
    }

    StopWarmup();
    ReplyToCommand(client, "{orange}[Warmup] {default}The warmup has been manually stopped.");
    return Plugin_Handled;
}

public void StopWarmup()
{
    if (!g_bWarmup) return;

    g_bWarmup = false;
    g_iCountdownTime = 0.0;

    if (g_hTimerRespawn != INVALID_HANDLE)
    {
        KillTimer(g_hTimerRespawn);
        g_hTimerRespawn = INVALID_HANDLE;
    }

    if (g_hTimerCountdown != INVALID_HANDLE)
    {
        KillTimer(g_hTimerCountdown);
        g_hTimerCountdown = INVALID_HANDLE;
    }

    if (g_hTimerEndWarmup != INVALID_HANDLE)
    {
        KillTimer(g_hTimerEndWarmup);
        g_hTimerEndWarmup = INVALID_HANDLE;
    }

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsPlayerAlive(i))
        {
            ForcePlayerSuicide(i);
        }
    }

    MC_PrintToChatAll("{orange}[Warmup] {red}Warmup has been stopped!");
    PrintToServer("[Warmup] Warmup stopped.");
}

/*
public Action Command_StartWarmup(int client, int args)
{
    if (!IsClientInGame(client))
    {
        return Plugin_Handled;
    }

    if (g_bWarmup)
    {
        MC_PrintToChat(client, "{yellow}[{orange}Warmup{yellow}] {red}Warmup is already in progress!");
        return Plugin_Handled;
    }

    MC_PrintToChat(client, "{yellow}[{orange}Warmup{yellow}] {red}Warmup started!");
    StartWarmup();
    return Plugin_Handled;
}
*/

public Action TF2_ArenaRoundStart(Handle event, const char[] name, bool dontBroadcast)
{
    if (GetConVarBool(g_hCvarWarmupEnabled) && g_bFirstRound && !g_bWarmupStarted)
    {
        g_bFirstRound = false;
        g_bWarmupStarted = true;
        StartWarmup();
    }
    return Plugin_Continue;
}

public Action TF2_OnRoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
    if (g_bWarmup)
    {
        StopWarmup();
    }
    return Plugin_Continue;
}

public void OnPluginEnd() 
{
    StopWarmup();
}

public void StartWarmup()
{
    if (g_bWarmup) return;

    g_bWarmup = true;

    // Lekérjük a ConVar értékét
    g_iCountdownTime = GetConVarFloat(g_hCvarWarmupTime);
    float warmupTime = g_iCountdownTime;

    MC_PrintToChatAll("{orange}[Warmup] {default}Warmup has started! {green}%.0f {default}seconds to end!", warmupTime);

    g_hTimerEndWarmup = CreateTimer(warmupTime, Timer_EndWarmup);
    g_hTimerRespawn = CreateTimer(0.1, Timer_Respawn, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    g_hTimerCountdown = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_Respawn(Handle timer, any data)
{
    if (!g_bWarmup) return Plugin_Stop;

    int alivePlayers = 0;
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if (IsPlayerAlive(i))
            {
                alivePlayers++;
            }
            else
            {
                TF2_RespawnPlayer(i);
            }
        }
    }
    if (alivePlayers == 0)
    {
        StopWarmup();
        MC_PrintToChatAll("{orange}[Warmup] {red}Warmup stopped because all players are dead!");
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

public Action Timer_Countdown(Handle timer, any data)
{
    if (!g_bWarmup) return Plugin_Stop;

    if (g_iCountdownTime > 0)
    {
        PrintHudTextAll("Warmup time remaining: %.0f seconds", g_iCountdownTime);
        g_iCountdownTime--;
        return Plugin_Continue;
    }

    return Plugin_Stop;
}

public void PrintHudTextAll(const char[] message, any ...)
{
    char buffer[256];
    VFormat(buffer, sizeof(buffer), message, 2);

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            SetHudTextParams(-1.0, 0.2, 1.0, 255, 165, 0, 255); // Orange
            ShowHudText(i, -1, buffer);
        }
    }
}

public Action Timer_EndWarmup(Handle timer, any data)
{
    g_hTimerEndWarmup = INVALID_HANDLE;
    StopWarmup();
    MC_PrintToChatAll("{orange}[Warmup] {red}Warmup has ended!");
    return Plugin_Stop;
}