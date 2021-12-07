#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

ConVar gH_Enabled;

public Plugin myinfo = 
{
	name = "1 Hit Kill AWP",
	author = "TimeBomb, updated by Shaders Allen.",
	description = "Attack with a AWP, BAM YOU'RE DEAD!",
	version = PLUGIN_VERSION
}

public void OnPluginStart()
{
	CreateConVar("sm_1hkawp_version", PLUGIN_VERSION, "1 Hit Kill AWP version", FCVAR_DONTRECORD|FCVAR_NOTIFY);
	gH_Enabled = CreateConVar("sm_1hkawp_enabled", "1", "1 Hit AWP Kill is enabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			OnClientPutInServer(i);
	}
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (!gH_Enabled.BoolValue || attacker == 0 || attacker > MaxClients)
	{
		return Plugin_Continue;
	}
	
	int active = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidEntity(active))
	{
		return Plugin_Continue;
	}
	
	char sWeapon[32];
	GetEntityClassname(active, sWeapon, sizeof(sWeapon));
	
	if (!StrEqual(sWeapon, "weapon_awp", false))
	{
		return Plugin_Continue;
	}
	
	damage = float(GetClientHealth(victim) + GetClientArmor(victim));
	return Plugin_Changed;
}