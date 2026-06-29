#include <sourcemod>
#include <sdkhooks>
#include <left4dhooks>

#define ZOMBIECLASS_CHARGER	6
#define TEAM_SURVIVOR 2
ConVar z_charger_incap_mult;

public Plugin myinfo =
{
	name = "Charger Incap Extra",
	author = "liquidplasma",
	description = "Multiplies charger damage when survivor is incapacitated",
	version = "1.0",
	url = ""
};

bool:IsValidClient(iClient)
{
    if(iClient <= 0 || iClient > MaxClients || !IsClientInGame(iClient))
        return false;
    return true;
} 

public bool IsCharger(int client)
{
	if (!IsValidClient(client))
		return false;
		
    int infectedClass = GetEntProp(client, Prop_Send, "m_zombieClass");
    return infectedClass == ZOMBIECLASS_CHARGER;
}

public void OnPluginStart()
{
	z_charger_incap_mult = CreateConVar("z_charger_incap_mult", "3", "Damage multiplier when victim is incapacitated while getting pummelled by a charger", FCVAR_NOTIFY, true, 0.0, true, 4096.0);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (IsValidClient(inflictor) && IsCharger(attacker) && L4D_IsPlayerPinned(victim) && IsClientInGame(victim) && GetClientTeam(victim) == TEAM_SURVIVOR && L4D_IsPlayerIncapacitated(victim))
	{			
        damage = damage * z_charger_incap_mult.FloatValue;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}