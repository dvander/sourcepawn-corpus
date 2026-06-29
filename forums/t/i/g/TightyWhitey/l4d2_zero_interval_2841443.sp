// l4d2_zero_interval.sp

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <left4dhooks>

#define TEAM_SURVIVOR 2

// -------------------- Plugin info --------------------
public Plugin myinfo =
{
	name = "[L4D2] Zero Interval",
	author = "Tighty-Whitey",
	description = "Disables common hordes and/or specials when the survivor team stalls (no flow progress within a time window). Re-enables after the leader advances a configurable amount.",
	version = "1.0",
	url = ""
};

// -------------------- ConVars --------------------
ConVar gC_Allow;
ConVar gC_Modes;
ConVar gC_Tick;
ConVar gC_Debug;

ConVar gC_MobFlowReq;
ConVar gC_MobSeconds;
ConVar gC_MobRecoverFlow;
ConVar gC_MobFinaleEnable;

ConVar gC_SiFlowReq;
ConVar gC_SiSeconds;
ConVar gC_SiRecoverFlow;
ConVar gC_SiFinaleEnable;

ConVar gC_NoMobs;
ConVar gC_NoSpecials;

ConVar gC_MPGameMode;

// -------------------- State --------------------
bool g_bEnabled = true;
bool g_bInRound = false;
bool g_bStarted = false;
bool g_bFinaleActive = false;

Handle g_hTick = null;

float g_fBaseline_Mob = 0.0;
float g_fBaseline_Si = 0.0;
float g_fLastResetTime_Mob = 0.0;
float g_fLastResetTime_Si = 0.0;

bool g_bFlipped_Mob = false;
bool g_bFlipped_Si = false;

float g_fRecoverStartFlow_Mob = 0.0;
float g_fRecoverStartFlow_Si = 0.0;

// -------------------- Helpers --------------------
static bool IsValidClient(int client)
{
	return (client >= 1 && client <= MaxClients && IsClientInGame(client));
}

static bool IsValidSurvivor(int client)
{
	return (IsValidClient(client) && GetClientTeam(client) == TEAM_SURVIVOR && IsPlayerAlive(client));
}

static float GetLeaderFlow()
{
	float best = 0.0;
	for (int i = 1; i <= MaxClients; i++)	
	{
		if (!IsValidSurvivor(i))
			continue;

		float f = L4D2Direct_GetFlowDistance(i);
		if (f > best)
			best = f;
	}
	return best;
}

static void DebugPrint(const char[] fmt, any ...)
{
	if (gC_Debug == null || !gC_Debug.BoolValue)
		return;

	char buffer[256];
	VFormat(buffer, sizeof(buffer), fmt, 2);
	PrintToServer("[ZI] %s", buffer);
}

static void SafeSetConVarInt(ConVar cv, int value)
{
	if (cv == null)
		return;

	if (cv.IntValue == value)
		return;

	int flags = cv.Flags;
	cv.Flags = (flags & ~FCVAR_NOTIFY);
	cv.IntValue = value;
	cv.Flags = flags;
}

static void KillTimerSafe(Handle &t)
{
	if (t == null)
		return;

	delete t;
	t = null;
}

static void ResetAllState(bool resetDirectorCvars)
{
	g_bStarted = false;
	g_bFinaleActive = false;

	g_fBaseline_Mob = 0.0;
	g_fBaseline_Si = 0.0;
	g_fLastResetTime_Mob = 0.0;
	g_fLastResetTime_Si = 0.0;

	g_bFlipped_Mob = false;
	g_bFlipped_Si = false;
	g_fRecoverStartFlow_Mob = 0.0;
	g_fRecoverStartFlow_Si = 0.0;

	if (resetDirectorCvars)
	{
		SafeSetConVarInt(gC_NoMobs, 0);
		SafeSetConVarInt(gC_NoSpecials, 0);
	}
}

// -------------------- Mode gating --------------------
bool IsAllowedGameMode()
{
	if (gC_Modes == null)
		return true;

	char list[256];
	gC_Modes.GetString(list, sizeof(list));
	TrimString(list);

	// Empty = all.
	if (!list[0])
		return true;

	if (gC_MPGameMode == null)
		gC_MPGameMode = FindConVar("mp_gamemode");
	if (gC_MPGameMode == null)
		return false;

	char mode[64];
	gC_MPGameMode.GetString(mode, sizeof(mode));
	TrimString(mode);

	char hay[320];
	char needle[96];
	Format(hay, sizeof(hay), ",%s,", list);
	Format(needle, sizeof(needle), ",%s,", mode);

	if (StrContains(hay, needle, false) != -1)
		return true;

	// Alias: treat "campaign" as "coop".
	if (StrEqual(mode, "coop", false) && StrContains(hay, ",campaign,", false) != -1)
		return true;

	return false;
}

void UpdateEnabledState()
{
	bool allow = (gC_Allow != null && gC_Allow.BoolValue) && IsAllowedGameMode();

	if (allow && !g_bEnabled)
	{
		g_bEnabled = true;
		ResetAllState(true);

		if (g_bInRound && g_hTick == null)
		{
			float dt = gC_Tick.FloatValue;
			if (dt < 0.05)
				dt = 0.05;

			g_hTick = CreateTimer(dt, T_Tick, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else if (!allow && g_bEnabled)
	{
		g_bEnabled = false;
		KillTimerSafe(g_hTick);
		ResetAllState(true);
	}
}

public void CvarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	UpdateEnabledState();
}

// -------------------- Lifecycle --------------------
public void OnPluginStart()
{
	CreateConVar("l4d2_zero_interval_version", "1.0", "Version", FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY);

	gC_Allow = CreateConVar("l4d2_zero_interval_allow", "1", "Enable/disable plugin (0/1).", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gC_Modes = CreateConVar("l4d2_zero_interval_modes", "campaign,realism", "Allowed modes, comma-separated (no spaces). Empty = all. campaign is treated as coop.", FCVAR_NOTIFY);

	gC_Tick = CreateConVar("l4d2_zero_interval_tick", "0.25", "Update interval (seconds).", FCVAR_NOTIFY, true, 0.05);
	gC_Debug = CreateConVar("l4d2_zero_interval_debug", "0", "Debug logs (0/1).", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	gC_MobFlowReq = CreateConVar("l4d2_zero_interval_mob_flow_required", "3000.0", "Flow needed within window before mobs timeout.", FCVAR_NOTIFY, true, 0.0);
	gC_MobSeconds = CreateConVar("l4d2_zero_interval_mob_seconds", "90.0", "Seconds without progress before disabling mobs.", FCVAR_NOTIFY, true, 1.0);
	gC_MobRecoverFlow = CreateConVar("l4d2_zero_interval_mob_recover_flow", "2000.0", "Leader flow needed to re-enable mobs.", FCVAR_NOTIFY, true, 0.0);
	gC_MobFinaleEnable = CreateConVar("l4d2_zero_interval_mob_finale_enable", "1", "Force enable mobs during finale (0/1).", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	gC_SiFlowReq = CreateConVar("l4d2_zero_interval_si_flow_required", "3000.0", "Flow needed within window before specials timeout.", FCVAR_NOTIFY, true, 0.0);
	gC_SiSeconds = CreateConVar("l4d2_zero_interval_si_seconds", "120.0", "Seconds without progress before disabling specials.", FCVAR_NOTIFY, true, 1.0);
	gC_SiRecoverFlow = CreateConVar("l4d2_zero_interval_si_recover_flow", "2000.0", "Leader flow needed to re-enable specials.", FCVAR_NOTIFY, true, 0.0);
	gC_SiFinaleEnable = CreateConVar("l4d2_zero_interval_si_finale_enable", "1", "Force enable specials during finale (0/1).", FCVAR_NOTIFY, true, 0.0, true, 1.0);

	gC_NoMobs = FindConVar("director_no_mobs");
	gC_NoSpecials = FindConVar("director_no_specials");
	gC_MPGameMode = FindConVar("mp_gamemode");

	if (gC_MPGameMode != null)
		gC_MPGameMode.AddChangeHook(CvarChanged_Allow);
	gC_Allow.AddChangeHook(CvarChanged_Allow);
	gC_Modes.AddChangeHook(CvarChanged_Allow);

	AutoExecConfig(true, "l4d2_zero_interval");

	HookEvent("round_start", E_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("round_end", E_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("player_left_checkpoint", E_LeftStart, EventHookMode_PostNoCopy);
	HookEvent("player_left_start_area", E_LeftStart, EventHookMode_PostNoCopy);

	HookEvent("finale_start", E_FinaleStart, EventHookMode_PostNoCopy);
	HookEvent("finale_radio_start", E_FinaleStart, EventHookMode_PostNoCopy);
	HookEvent("gauntlet_finale_start", E_FinaleStart, EventHookMode_PostNoCopy);
	HookEvent("finale_win", E_FinaleEnd, EventHookMode_PostNoCopy);

	ResetAllState(true);
	UpdateEnabledState();
}

public void OnMapStart()
{
	ResetAllState(true);
	UpdateEnabledState();
}

public void OnMapEnd()
{
	KillTimerSafe(g_hTick);
	ResetAllState(false);
}

// -------------------- Events --------------------
public void E_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bInRound = true;
	UpdateEnabledState();

	if (!g_bEnabled)
		return;

	KillTimerSafe(g_hTick);
	ResetAllState(true);

	float dt = gC_Tick.FloatValue;
	if (dt < 0.05)
		dt = 0.05;

	g_hTick = CreateTimer(dt, T_Tick, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public void E_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_bInRound = false;
	KillTimerSafe(g_hTick);
}

public void E_LeftStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return;
	if (g_bStarted)
		return;
	if (!L4D_HasAnySurvivorLeftSafeArea())
		return;

	g_bStarted = true;

	float now = GetEngineTime();
	float lead = GetLeaderFlow();

	g_fBaseline_Mob = lead;
	g_fBaseline_Si = lead;
	g_fLastResetTime_Mob = now;
	g_fLastResetTime_Si = now;

	DebugPrint("Started at flow=%.0f", lead);
}

public void E_FinaleStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return;

	g_bFinaleActive = true;

	if (gC_MobFinaleEnable.BoolValue)
		SafeSetConVarInt(gC_NoMobs, 0);
	if (gC_SiFinaleEnable.BoolValue)
		SafeSetConVarInt(gC_NoSpecials, 0);

	g_bFlipped_Mob = false;
	g_bFlipped_Si = false;

	float now = GetEngineTime();
	float lead = GetLeaderFlow();
	g_fBaseline_Mob = lead;
	g_fBaseline_Si = lead;
	g_fLastResetTime_Mob = now;
	g_fLastResetTime_Si = now;
}

public void E_FinaleEnd(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bEnabled)
		return;

	g_bFinaleActive = false;

	float now = GetEngineTime();
	float lead = GetLeaderFlow();
	g_fBaseline_Mob = lead;
	g_fBaseline_Si = lead;
	g_fLastResetTime_Mob = now;
	g_fLastResetTime_Si = now;
}

// -------------------- Core tick --------------------
public Action T_Tick(Handle timer, any data)
{
	if (!g_bEnabled || !g_bStarted)
		return Plugin_Continue;

	float now = GetEngineTime();
	float lead = GetLeaderFlow();

	// No survivors alive/in game.
	if (lead <= 0.0)
		return Plugin_Continue;

	// Finale override: keep enabled for selected types.
	if (g_bFinaleActive)
	{
		if (gC_MobFinaleEnable.BoolValue)
			SafeSetConVarInt(gC_NoMobs, 0);
		if (gC_SiFinaleEnable.BoolValue)
			SafeSetConVarInt(gC_NoSpecials, 0);
	}

	// ----- Mobs -----
	if (!(g_bFinaleActive && gC_MobFinaleEnable.BoolValue))
	{
		float reqFlow = gC_MobFlowReq.FloatValue;
		float winSec = gC_MobSeconds.FloatValue;
		float recFlow = gC_MobRecoverFlow.FloatValue;

		if (!g_bFlipped_Mob)
		{
			if (lead >= g_fBaseline_Mob + reqFlow)
			{
				g_fBaseline_Mob = lead;
				g_fLastResetTime_Mob = now;
				SafeSetConVarInt(gC_NoMobs, 0);
				DebugPrint("Mobs progress OK; reset window at flow=%.0f", lead);
			}
			else if (now - g_fLastResetTime_Mob >= winSec)
			{
				g_bFlipped_Mob = true;
				g_fRecoverStartFlow_Mob = lead;
				SafeSetConVarInt(gC_NoMobs, 1);
				DebugPrint("Mobs disabled (no progress %.0fs); leader=%.0f baseline=%.0f need=%.0f", winSec, lead, g_fBaseline_Mob, reqFlow);
			}
		}
		else
		{
			if (lead >= g_fRecoverStartFlow_Mob + recFlow)
			{
				g_bFlipped_Mob = false;
				SafeSetConVarInt(gC_NoMobs, 0);
				g_fBaseline_Mob = lead;
				g_fLastResetTime_Mob = now;
				DebugPrint("Mobs re-enabled at leader=%.0f (needed %.0f)", lead, recFlow);
			}
		}
	}

	// ----- Specials -----
	if (!(g_bFinaleActive && gC_SiFinaleEnable.BoolValue))
	{
		float reqFlow = gC_SiFlowReq.FloatValue;
		float winSec = gC_SiSeconds.FloatValue;
		float recFlow = gC_SiRecoverFlow.FloatValue;

		if (!g_bFlipped_Si)
		{
			if (lead >= g_fBaseline_Si + reqFlow)
			{
				g_fBaseline_Si = lead;
				g_fLastResetTime_Si = now;
				SafeSetConVarInt(gC_NoSpecials, 0);
				DebugPrint("SI progress OK; reset window at flow=%.0f", lead);
			}
			else if (now - g_fLastResetTime_Si >= winSec)
			{
				g_bFlipped_Si = true;
				g_fRecoverStartFlow_Si = lead;
				SafeSetConVarInt(gC_NoSpecials, 1);
				DebugPrint("SI disabled (no progress %.0fs); leader=%.0f baseline=%.0f need=%.0f", winSec, lead, g_fBaseline_Si, reqFlow);
			}
		}
		else
		{
			if (lead >= g_fRecoverStartFlow_Si + recFlow)
			{
				g_bFlipped_Si = false;
				SafeSetConVarInt(gC_NoSpecials, 0);
				g_fBaseline_Si = lead;
				g_fLastResetTime_Si = now;
				DebugPrint("SI re-enabled at leader=%.0f (needed %.0f)", lead, recFlow);
			}
		}
	}

	return Plugin_Continue;
}
