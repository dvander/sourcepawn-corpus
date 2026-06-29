#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "L4D2 Witch Fire Fix"
#define CVAR_FLAGS FCVAR_NOTIFY|FCVAR_SPONLY

ConVar g_cvarEnable, g_cvarDebug;
bool bHooked = false, g_bDebug = false, g_witchRespawnFlag = false;
ArrayList g_adtRespawnedWitches = null;
int g_witchRespawnHP = 0;
float g_witchRespawnPos[3] = {0.0, ...};

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = "dcx2",
	description = "Fixes the Witch so she loses her target if she lights herself on fire",
	version = PLUGIN_VERSION,
	url = "www.AlliedMods.net"
}

public void OnPluginStart()
{
	CreateConVar("sm_witchfirefix_version", PLUGIN_VERSION, "Witch Fire Fix", CVAR_FLAGS|FCVAR_DONTRECORD);
	g_cvarEnable = CreateConVar("sm_witchfirefix_enable", "1.0", "Enables this plugin.", CVAR_FLAGS);
	g_cvarDebug = CreateConVar("sm_witchfirefix_debug", "0.0", "Print debug output.", CVAR_FLAGS);

	g_cvarEnable.AddChangeHook(OnWFFEnableChanged);
	g_cvarDebug.AddChangeHook(OnWFFDebugChanged);

	AutoExecConfig(true, "l4d2_witchfirefix");

	g_adtRespawnedWitches = CreateArray();
	g_witchRespawnFlag = false;
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnWFFEnableChanged(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool g_bEnabled = g_cvarEnable.BoolValue;
	if(g_bEnabled && !bHooked)
	{
		bHooked = true;
		HookEvent("round_start", Event_Round_Start);
		HookEvent("witch_killed", Event_Witch_Killed);
		HookEvent("infected_hurt", Event_Infected_Hurt);
	}
	else if(!g_bEnabled && bHooked)
	{
		bHooked = false;
		UnhookEvent("round_start", Event_Round_Start);
		UnhookEvent("witch_killed", Event_Witch_Killed);
		UnhookEvent("infected_hurt", Event_Infected_Hurt);
	}
}

void OnWFFDebugChanged(ConVar cvar, const char[] oldVal, const char[] newVal)
{
	g_bDebug = g_cvarDebug.BoolValue;
}

Action Event_Round_Start(Event event, const char[] name, bool dontBroadcast)
{
	// always do this, even if plugin disabled
	ClearArray(g_adtRespawnedWitches);
	g_witchRespawnFlag = false;
	return Plugin_Continue;
}

Action Event_Infected_Hurt(Event event, const char[] name, bool dontBroadcast)
{
	if (event.GetInt("type") & 0x8)
	{
		int victim = event.GetInt("entityid");
		char victimName[20];
		GetEntityClassname(victim, victimName, sizeof(victimName));
		if (StrContains(victimName, "witch", false) < 0) return Plugin_Continue; // if not a witch, return

		int witchIndex = FindValueInArray(g_adtRespawnedWitches, victim); // Have we already respawned this entity?
		if (witchIndex >= 0) return Plugin_Continue;

		int igniter = GetClientOfUserId(event.GetInt("attacker"));
		if (igniter > 0)
		{
			// if igniter is a player, pretend the witch has been respawned
			// This way we can't respawn a witch who was already lit by a player
			PushArrayCell(g_adtRespawnedWitches, victim);
			return Plugin_Continue;
		}

		// By now, a witch has been ignited from something that's not a player and we have not respawned her yet
		// Grab her health and position, then kill her, set the respawn flag, and spawn a new witch
		g_witchRespawnHP = GetEntProp(victim, Prop_Data, "m_iHealth");
		GetEntPropVector(victim, Prop_Send, "m_vecOrigin", g_witchRespawnPos);
		AcceptEntityInput(victim, "kill");
		g_witchRespawnFlag = true;
		if (g_bDebug) PrintToChatAll("Witch %d (hp: %d, pos: %f, %f, %f) ignited", victim, g_witchRespawnHP, g_witchRespawnPos[0], g_witchRespawnPos[1], g_witchRespawnPos[2]);
		L4D2_SpawnWitch(g_witchRespawnPos, NULL_VECTOR); // Respawn her (continue in Event_Witch_Spawn)
		g_witchRespawnPos[0] = 0.0;
		g_witchRespawnPos[1] = 0.0;
		g_witchRespawnPos[2] = 0.0;	
	}
	return Plugin_Continue;
}

public void L4D_OnSpawnWitch_Post(int entity, const float vecPos[3], const float vecAng[3])
{
	if (bHooked && IsServerProcessing())
	{
		if (g_witchRespawnFlag)
		{
			// We are supposed to respawn a previous witch
			// Remember her so that we don't respawn her again
			PushArrayCell(g_adtRespawnedWitches, entity);
			// Then restore her previous HP and position
			SetEntityHealth(entity, g_witchRespawnHP);
			if (g_bDebug) PrintToChatAll("Witch %d (hp: %d, pos: %f, %f, %f) respawned", entity, g_witchRespawnHP, vecPos[0], vecPos[1], vecPos[2]);
			// Finally, reset all the respawn fields
			g_witchRespawnFlag = false;
			g_witchRespawnHP = 1000;
		}
	}
}

Action Event_Witch_Killed(Event event, const char[] name, bool dontBroadcast)
{
	int witchid = event.GetInt("witchid");
	// If a respawned witch dies, remove her from the array
	int witchIndex = FindValueInArray(g_adtRespawnedWitches, witchid);
	if (witchIndex >= 0) RemoveFromArray(g_adtRespawnedWitches, witchIndex);
	if (g_bDebug) PrintToChatAll("Witch %d killed", witchid);
	return Plugin_Continue;
}
