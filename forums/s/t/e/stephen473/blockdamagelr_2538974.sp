#pragma semicolon 1

#define DEBUG

#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <hosties>
#include <lastrequest>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Block other damages if client in lr",
	author = "stephen473(Hardy)",
	description = "This plugin will block the take damage if the victim in lr",
	version = PLUGIN_VERSION,
	url = "steamcommunity.com/id/kHardy"
};


public void OnClientConnected(int client)
{
	if (IsClientInGame(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (IsValidClient(victim) && IsValidClient(attacker))
	{
		if (IsClientInLastRequest(victim) && !IsClientInLastRequest(attacker))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
		return true;
	return false;
}