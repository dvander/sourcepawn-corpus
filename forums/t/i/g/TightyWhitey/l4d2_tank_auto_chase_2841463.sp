// File: l4d2_tank_auto_chase.sp

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3
#define ZC_TANK 8

ConVar g_hCvarAllow;
ConVar g_hCvarMPGameMode;
ConVar g_hCvarModes;

bool g_bCvarAllow;
public Plugin myinfo =
{
	name = "[L4D2] Tank Auto Chase",
	author = "Tighty-Whitey",
	description = "Tank immediately chases survivors on spawn.",
	version = "1.0",
	url = ""
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}

	return APLRes_Success;
}

public void OnPluginStart()
{
	// CVARS
	g_hCvarAllow    = CreateConVar( "l4d2_tank_auto_chase_allow",     "1", "0=Off, 1=On.", CVAR_FLAGS );
	g_hCvarModes    = CreateConVar( "l4d2_tank_auto_chase_modes",     "coop,realism", "Enable only in these game modes (comma-separated). Empty = all.", CVAR_FLAGS );
	AutoExecConfig(true, "l4d2_tank_auto_chase");

	g_hCvarMPGameMode = FindConVar("mp_gamemode");
	if (g_hCvarMPGameMode != null)
		g_hCvarMPGameMode.AddChangeHook(ConVarChanged_Allow);

	g_hCvarAllow.AddChangeHook(ConVarChanged_Allow);
	g_hCvarModes.AddChangeHook(ConVarChanged_Allow);
	IsAllowed();
}


public void OnConfigsExecuted()
{
	IsAllowed();
}

void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool allow = g_hCvarAllow.BoolValue;
	bool allowMode = IsAllowedGameMode();

	if (!g_bCvarAllow && allow && allowMode)
	{
		HookEvents(true);
		g_bCvarAllow = true;
	}
	else if (g_bCvarAllow && (!allow || !allowMode))
	{
		HookEvents(false);
		g_bCvarAllow = false;
	}
}

bool IsAllowedGameMode()
{
	if (g_hCvarMPGameMode == null)
		return false;

	char mode[64], list[256];
	g_hCvarMPGameMode.GetString(mode, sizeof(mode));
	Format(mode, sizeof(mode), ",%s,", mode);

	// Inclusive list. Empty = all modes.
	g_hCvarModes.GetString(list, sizeof(list));
	if (list[0])
	{
		Format(list, sizeof(list), ",%s,", list);
		if (StrContains(list, mode, false) == -1)
			return false;
	}

	return true;
}


void HookEvents(bool hook)
{
	static bool hooked;

	if (hook && !hooked)
	{
		HookEvent("tank_spawn", Event_TankSpawn, EventHookMode_PostNoCopy);
		hooked = true;
	}
	else if (!hook && hooked)
	{
		UnhookEvent("tank_spawn", Event_TankSpawn, EventHookMode_PostNoCopy);
		hooked = false;
	}
}

public void Event_TankSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_bCvarAllow)
		return;

	int tank = GetClientOfUserId(event.GetInt("userid"));
	if (tank < 1 || tank > MaxClients)
		return;

	if (!IsClientInGame(tank) || !IsPlayerAlive(tank))
		return;

	if (GetClientTeam(tank) != TEAM_INFECTED)
		return;

	if (GetEntProp(tank, Prop_Send, "m_zombieClass") != ZC_TANK)
		return;

	// Only bother if at least one survivor is alive/in-game.
	if (GetClosestSurvivor(tank) == 0)
		return;

	// Nudge the Tank AI into combat immediately.
	SetEntProp(tank, Prop_Send, "m_hasVisibleThreats", 1);
}

int GetClosestSurvivor(int tank)
{
	float tankOrigin[3];
	GetClientAbsOrigin(tank, tankOrigin);

	int best = 0;
	float bestDistSq = 0.0;

	float pos[3];
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))
			continue;

		if (GetClientTeam(i) != TEAM_SURVIVOR)
			continue;

		GetClientAbsOrigin(i, pos);

		float distSq = GetVectorDistance(tankOrigin, pos, true);
		if (best == 0 || distSq < bestDistSq)
		{
			best = i;
			bestDistSq = distSq;
		}
	}

	return best;
}
