#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <zombiereloaded>

#pragma newdecls required


public Plugin myinfo =  {
	name = "Inferno Teamkill Fix",
	author = "Agent Wesker",
	description = "Prevent teamkill exploit",
	version = "1.0",
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
	SDKHook(client, SDKHook_OnTakeDamage, DamageOnTakeDamage);
}

public Action DamageOnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, 
		float damageForce[3], float damagePosition[3])
{
	if (!IsValidClient(victim)) {
		return Plugin_Continue;
	}

	if(!ZR_IsClientZombie(victim))
	{
		//Victim is human
		char sWeapon[64];
		GetEntityClassname(inflictor, sWeapon, sizeof(sWeapon));
		if (StrEqual(sWeapon, "inferno", false)) {
			//Damage from inferno, stop damage
			return Plugin_Handled;
		}
	}
	//Allow Damage
	return Plugin_Continue;
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