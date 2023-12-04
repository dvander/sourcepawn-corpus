#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <sourcemod>

/* Constants */

#define PLUGIN_VERSION "1.0"
#define LIMIT          2

/* ConVars handles */

ConVar cvar_godmodeEnabled = null;

/* Variables */

bool b_1v1Enabled = false;

public Plugin myinfo =
{
	name        = "[TF2] Godmode 1vs1",
	author      = "Walgrim",
	description = "Enable godmode in 1vs1",
	version     = PLUGIN_VERSION,
	url         = "http://steamcommunity.com/id/walgrim/"
};

public void OnPluginStart()
{
	// ConVars
	CreateConVar("tf2_godmode1vs1_version", PLUGIN_VERSION, "Godmode 1vs1 Version", FCVAR_SPONLY | FCVAR_UNLOGGED | FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY);
	cvar_godmodeEnabled = CreateConVar("tf2_godmode1vs1", "1", "Enable godmode 1vs1 on the server ?", _, true, 0.0, true, 1.0);

	// Hook Events
	if (cvar_godmodeEnabled.BoolValue)
	{
		HookEvent("player_team", OnChangeTeam, EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
	}
	AutoExecConfig(true, "tf2_godmode1vs1");
}

/* Hook player damages */
public void OnClientPutInServer(int client)
{
	if (cvar_godmodeEnabled.BoolValue && IsEntityConnectedClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnClientTakesDamage);
	}
}

/* Check on change team if the conditions are fulfilled (or not) */
public void OnChangeTeam(Event event, const char[] name, bool dontBroadcast)
{
	// Delaying by 1 frame
	RequestFrame(DelayCheck);
}

/* Check on round start if the conditions are fulfilled (or not) */
public void OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	// 1vs1
	CheckGodmodeStatus();
}

public void OnClientDisconnect(int client)
{
	// 1vs1
	CheckGodmodeStatus();
}

/* Request Frame (delaying by 1 frame to get right team values) */
void DelayCheck()
{
	// 1vs1
	CheckGodmodeStatus();
}

/* Player Damages */

/* Applies the new damage amount */
public Action OnClientTakesDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& weapon, float damageForce[3], float damagePosition[3])
{
	if (b_1v1Enabled)
	{
		if (IsEntityConnectedClient(victim))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}

/* Functions */

/* Enable/Disable godmode */
void CheckGodmodeStatus()
{
	if (!cvar_godmodeEnabled.BoolValue)
	{
		return;
	}

	int players = GetTeamClientCount(2) + GetTeamClientCount(3);
	if (players == LIMIT)
	{
		b_1v1Enabled = true;

		return;
	}
	b_1v1Enabled = false;
}

/* Stocks */

stock bool IsEntityConnectedClient(int entity)
{
	return (0 < entity <= MaxClients && IsClientInGame(entity));
}
