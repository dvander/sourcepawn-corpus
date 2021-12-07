#pragma semicolon 1

#include <sourcemod>
#include <tf2jail>
#include <sdkhooks>

public Plugin myinfo = {
	name = "[TF2Jail] Freeday Godmode",
	author = "Keith Warren (Jack of Designs), Sgt. Gremulock",
	description = "Gives Freedays Godmode on start & removes on exit (fixed by Sgt. Gremulock to add a valid client check).",
	version = "1.0.1",
	url = "http://www.jackofdesigns.com/"
};

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (IsValidClient(victim) && IsValidClient(attacker))
	{
		if (TF2Jail_IsFreeday(victim))
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		
		if (TF2Jail_IsFreeday(attacker))
		{
			TF2Jail_RemoveFreeday(attacker);
		}
	}
	
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	if (client <= 0 || client > MaxClients || !IsClientConnected(client))
	{
		return false;
	}
	
	return IsClientInGame(client);
}