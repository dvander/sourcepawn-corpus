#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#pragma newdecls required

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo =
{
	name = "TOG Block Grenade Team Damage",
	author = "That One Guy",
	description = "Blocks team damage from nades only",
	version = PLUGIN_VERSION,
	url = "https://www.togcoding.com/togcoding/index.php"
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

public void OnClientDisconnect(int client)
{
	SDKUnhook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage);
}

public Action Event_OnTakeDamage(int victim, int &attacker, int &inflictor, float &fDamage, int &damagetype)
{
	if(!IsValidClient(victim) || !IsValidClient(attacker))
	{
		return Plugin_Continue;
	}
	if(GetClientTeam(victim) != GetClientTeam(attacker))
	{
		return Plugin_Continue;
	}
	if(victim == attacker)
	{
		return Plugin_Continue;
	}
	
	char sClassname[64];
	GetEdictClassname(inflictor, sClassname, sizeof(sClassname));
	if(StrContains(sClassname, "hegrenade", false) != -1)
	{
		fDamage = 0.0;
		return Plugin_Changed;
	}
	else if(StrContains(sClassname, "incgrenade", false) != -1)
	{
		fDamage = 0.0;
		return Plugin_Changed;
	}
	else if(StrContains(sClassname, "molotov", false) != -1)
	{
		fDamage = 0.0;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}

bool IsValidClient(int client)
{
	if(!(1 <= client <= MaxClients) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}

/////////////////////////////////////////////////////////////////////////////////////////
/////////////////////////////////////// CHANGE LOG //////////////////////////////////////
/////////////////////////////////////////////////////////////////////////////////////////
/*
	1.0.0
		* Initial creation.
		
*/