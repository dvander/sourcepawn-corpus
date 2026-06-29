#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if (!victim || victim > MaxClients || !IsClientInGame(victim))
		return Plugin_Continue;

	if (!damagecustom && TF2_IsPlayerInCondition(victim, TFCond_Taunting) && TF2_IsPlayerInCondition(attacker, TFCond_Taunting))
	{
		damage = 9001.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}