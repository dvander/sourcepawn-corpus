#include <sourcemod>
#include <sdkhooks>

ConVar sv_damage_reduction = null;
float currentReduction = 50.0;

public Plugin myinfo = {
	name = "Damage Reduction System",
	author = "XeroX",
	description = "Reduces all damage received based on a convar",
	version = "1.0.0",
	url = "http://soldiersofdemise.com"
};

public void OnPluginStart()
{
	sv_damage_reduction = CreateConVar("sv_damage_reduction", "50.0","Damage reduction in percent. 100 = no damage taken | 0 = normal damage taken",FCVAR_NOTIFY,true,0.0,true,100.0);
	sv_damage_reduction.AddChangeHook(OnReductionChange);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(GetClientTeam(victim) == 2)
	{
		damage = damage - (damage * currentReduction);
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

public void OnReductionChange(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if(StringToFloat(newValue) == currentReduction) return;
	
	currentReduction = StringToFloat(newValue);
}
