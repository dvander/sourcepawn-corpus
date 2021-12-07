#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PL_VERSION "1.3"

public Plugin myinfo =
{
	name        = "TF2 Fast Respawn",
	author      = "Tsunami",
	description = "Fast Respawn for TF2.",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

ConVar g_hEnabled;
ConVar g_hBlu;
ConVar g_hRed;

public void OnPluginStart()
{
	CreateConVar("sm_fastrespawn_version", PL_VERSION, "Fast Respawn for TF2.", FCVAR_NOTIFY);
	g_hEnabled   = CreateConVar("sm_fastrespawn_enabled", "1",    "Enable/disable fast respawn for TF2.");
	g_hBlu       = CreateConVar("sm_fastrespawn_blu",     "10.0", "Respawn time for Blu team in TF2.");
	g_hRed       = CreateConVar("sm_fastrespawn_red",     "10.0", "Respawn time for Red team in TF2.");

	g_hEnabled.AddChangeHook(ConVarChange_SetRespawnTime);
	g_hBlu.AddChangeHook(ConVarChange_SetRespawnTime);
	g_hRed.AddChangeHook(ConVarChange_SetRespawnTime);

	HookEvent("player_death", Event_SetRespawnTime, EventHookMode_Pre);
}

public void ConVarChange_SetRespawnTime(ConVar convar, const char[] oldValue, const char[] newValue)
{
	SetRespawnTime();
}

public void Event_SetRespawnTime(Event event, const char[] name, bool dontBroadcast)
{
	SetRespawnTime();
}

void SetRespawnTime()
{
	int iGameRules = FindEntityByClassname(-1, "tf_gamerules");
	bool bEnabled = g_hEnabled.BoolValue;

	if (iGameRules != -1)
	{
		SetVariantFloat(bEnabled ? g_hBlu.FloatValue : 10.0);
		AcceptEntityInput(iGameRules, "SetBlueTeamRespawnWaveTime");

		SetVariantFloat(bEnabled ? g_hRed.FloatValue : 10.0);
		AcceptEntityInput(iGameRules, "SetRedTeamRespawnWaveTime");
	}

	bEnabled ? AddServerTag("fastrespawn") : RemoveServerTag("fastrespawn");
}
