#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "1.0"

public Plugin myinfo =
{
	name = "SM No PVP",
	author = "Franc1sco franug",
	description = "Prevents players vs players damage",
	version = VERSION,
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart()
{
	for (new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if(IsValidClient(attacker) && attacker != victim)
		return Plugin_Handled;
		
		
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client))
	{
		return false;
	}
	return true;
}