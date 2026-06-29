#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>

#pragma newdecls required

public Plugin myinfo =  {
	name = "Inferno Ignite Slow",
	author = "AgentWesker",
	description = "Molotov's ignite zombies.",
	version = "1.3",
	url = "http://steam-gamers.net"
};

public void OnPluginStart(){	
	//Late plugin load (or reload)
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client)
{
	//Use an SDKHook for inflictor index
	SDKHook(client, SDKHook_OnTakeDamagePost, OnTakeDamagePost);
}

public void OnTakeDamagePost(int victim, int attacker, int inflictor, float damage, int damagetype, int weapon, 
		const float damageForce[3], const float damagePosition[3], int damagecustom)
{
	if(!IsValidClient(victim))
	{
		return;
	}
	
	if(!ZR_IsClientZombie(victim))
	{
		return;
	}
	
	char sWeapon[64];
	GetEntityClassname(inflictor, sWeapon, sizeof(sWeapon));
	
	if (StrEqual(sWeapon, "inferno", false))
	{
		if (GetEntPropEnt(victim, Prop_Data, "m_hEffectEntity") == -1) {
			//Touching inferno but extinguished, re-ignite
			IgniteEntity(victim, 1.5);
			//PrintToChatAll("%N inferno", victim); //~~~DEBUGGING~~~
		}
	}
}

public bool IsValidClient(int client) {
	if ((client <= 0) || (client > MaxClients)) {
		return false;
	}
	if (!IsClientInGame(client)) {
		return false;
	}
	if (!IsPlayerAlive(client)) {
		return false;
	}
	return true;
}  