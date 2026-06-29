#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>


public void OnPluginStart()
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientValid(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public void OnClientPutInServer(int i)
{
	SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
		if(IsClientValid(victim))
		{
			if(damagetype == DMG_BURN)
			{
				if(GetClientTeam(victim) == 2)
				{
					IgniteEntity(victim, 7.0);
					return Plugin_Continue;
				}
				if(GetClientTeam(victim) == 3)
				{
					return Plugin_Continue;
				}
				else
					return Plugin_Handled;
			}
		}
		return Plugin_Continue;
}

stock bool IsClientValid(int client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
		return true;
	return false;
}