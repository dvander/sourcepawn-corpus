#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#define PLUGIN_VERSION "1.01"

ConVar pFF, pFFFire, pFFBarrel;

public Plugin myinfo =
{
	name = "[L4D & L4D2] No Friendly Fire",
	author = "Psykotik, Crasher_3637 and cravenge",
	description = "Disables friendly fire.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
}

public void OnPluginStart()
{
	CreateConVar("l4d_friendlyfire_version", PLUGIN_VERSION, "Version of the plugin.");
	pFF = CreateConVar("l4d_friendlyfire", "0", "Friendly Fire status: 0 = Disabled, 1 = Enabled");
	pFFFire = CreateConVar("l4d_friendlyfire_from_fire", "0", "Friendly Fire status from fire sources: 0 = Disabled, 1 = Enabled");
	pFFBarrel = CreateConVar("l4d_friendlyfire_from_barrel", "0", "Friendly Fire status from explosive barrels: 0 = Disabled, 1 = Enabled");
	
	AutoExecConfig(true, "l4d_nofriendlyfire");
}

public void OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) 
{
	if (!pFF.BoolValue || (!pFFFire.BoolValue && (damagetype == 8 || damagetype == 2056 || damagetype == 268435464)))
	{
		if ((IsSurvivor(victim) && IsSurvivor(attacker)) || (attacker != 0 && (!IsClientInGame(attacker) || GetClientTeam(attacker) != GetClientTeam(victim))))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}
	else if (IsValidEnt(inflictor))
	{
		char sInflictorClass[64];
		GetEdictClassname(inflictor, sInflictorClass, sizeof(sInflictorClass));
		if (!pFFBarrel.BoolValue && StrContains(sInflictorClass, "prop_fuel_barrel", false) != -1 && (IsSurvivor(attacker) || (attacker != 0 && (!IsClientInGame(attacker) || GetClientTeam(attacker) != GetClientTeam(victim))))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
	}

	return Plugin_Continue;
}

stock bool IsSurvivor(int client)
{
	return (client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2);
}

stock bool IsValidEnt(int entity)
{
	return (entity > 0 && IsValidEntity(entity) && IsValidEdict(entity));
}

