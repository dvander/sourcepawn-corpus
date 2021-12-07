#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdkhooks>

ConVar sv_damage_reduction;

public Plugin myinfo =
{
	name = "Damage Reduction System",
	author = "XeroX",
	description = "Reduces all damage received based on a convar",
	version = "1.0.0",
	url = "http://soldiersofdemise.com"
};

public void OnPluginStart()
{
	sv_damage_reduction = CreateConVar("sv_damage_reduction", "0.5", "Damage reduction in percent. 0.0 = normal damage taken | 1.0 = no damage taken", FCVAR_NOTIFY, true, 0.0, true, 1.0);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(IsClientInGame(victim) && GetClientTeam(victim) == 2 && !IsFakeClient(victim))
	{
		damage = damage - (damage * sv_damage_reduction.FloatValue);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
