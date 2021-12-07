#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo =  {
	name = "Friendly Fire Grenades", 
	author = "Kolapsicle", 
	description = "Disables all non-grenade sources of friendly fire damage.", 
	version = "1.0"
};

#define DMG_GRENADE (DMG_BLAST | DMG_CLUB)

ConVar cvFriendlyFire;

public void OnPluginStart()
{
	cvFriendlyFire = FindConVar("mp_friendlyfire");
	if (cvFriendlyFire == null)
	{
		SetFailState("Could not find console variable: mp_friendlyfire");
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_TraceAttack, Hook_TraceAttack);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_TraceAttack, Hook_TraceAttack);
}

public Action Hook_TraceAttack(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &ammotype, int hitbox, int hitgroup)
{
	if (!GetConVarBool(cvFriendlyFire))
	{
		return Plugin_Continue;
	}
	
	if (!IsValidClient(attacker) || !IsValidClient(victim))
	{
		return Plugin_Continue;
	}
	
	if (GetClientTeam(attacker) == GetClientTeam(victim) && (damagetype & ~DMG_GRENADE))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	return 0 < client <= MaxClients && IsClientInGame(client);
} 