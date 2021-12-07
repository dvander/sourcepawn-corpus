#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "LaFF"
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

public Plugin myinfo = 
{
	name = "", 
	author = PLUGIN_AUTHOR, 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};
ConVar GAMESETpercent;

public void OnPluginStart()
{
	GAMESETpercent = CreateConVar("gs_d", "1", "boost damage by %  0 = default");
}
public void OnClientPutInServer(int client)
{
	if (IsValidClient(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDmg);
	}
	
}

public Action OnTakeDmg(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if (IsValidClient(attacker))
	{
		float onepercent = damage / 100;
		damage = onepercent * GAMESETpercent.IntValue + damage;
		return Plugin_Changed;
	}
	return Plugin_Handled;
}

stock bool IsValidClient(int client)
{
	if (client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && !IsClientSourceTV(client))
	{
		return true;
	}
	
	return false;
} 