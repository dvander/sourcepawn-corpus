#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Simon"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#define LoopClients(%1) for(new %1 = 1; %1 <= MaxClients; %1++)

EngineVersion g_Game;

public Plugin:myinfo = 
{
	name = "Team Damage Show",
	author = PLUGIN_AUTHOR,
	description = "Shows Team Damage to admins.",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if (attacker <= 0 || attacker > MaxClients || victim <= 0 || victim > MaxClients || !IsClientInGame(victim) || !IsClientInGame(attacker))
		return Plugin_Continue;

	LoopClients(i)
	{
		if (CheckCommandAccess(i, "sm_map", ADMFLAG_CHANGEMAP, true))
			PrintToChat(i, "[Team Damage] Victim: %N, Attacker: %N, Damage: %d HP",victim, attacker, damage);
	}
	return Plugin_Continue;
}