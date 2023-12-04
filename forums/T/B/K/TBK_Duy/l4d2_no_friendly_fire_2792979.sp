#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#define PLUGIN_VERSION 	"1.0"

public Plugin myinfo =
{
	name = "[L4D2] No Friendly Fire",
	author = "Hoangzp, TBK Duy",
	description = "Bullet will penetrate through players, melee can't slash players",
	version = PLUGIN_VERSION,
	url = "Link forum tải :))"
}

public OnMapStart()
{
	for (int target = 1; target <= MaxClients; target++)
	{
		if(IsClientInGame(target))
		{
			SDKUnhook(target, SDKHook_TraceAttack, PreThink);
			SDKHook(target, SDKHook_TraceAttack, PreThink);
		}
	}
}	
public OnClientPutInServer(client)
{
	SDKUnhook(client, SDKHook_TraceAttack, PreThink);
	SDKHook(client, SDKHook_TraceAttack, PreThink);
}

public Action PreThink(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if(!(0 < attacker <= MaxClients))
	{
		return Plugin_Continue;
	}
	if(!(0 < victim <= MaxClients))
	{
		return Plugin_Continue;
	}	
	if((0 < attacker <= MaxClients))
	{
		if(!IsClientInGame(attacker) 
	  || !IsPlayerAlive(attacker))
	  {
		return Plugin_Continue;
	  }
	} 
	if((0 < victim <= MaxClients))
	{
	if(!IsClientInGame(victim)
	  || !IsPlayerAlive(victim))
	  {
		return Plugin_Continue;
	  }
	}
	if(GetClientTeam(attacker) == 2 && GetClientTeam(victim) == 2)
	{
		if((damagetype & 2 || damagetype & 4))
		return Plugin_Handled;
	}

	return Plugin_Continue;
}