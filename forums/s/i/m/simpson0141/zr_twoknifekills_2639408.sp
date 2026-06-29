#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>
#include <zombiereloaded>

#pragma semicolon 1

public Plugin myinfo =
{
	name			= "[ZR] Two knife kills Hotfix",
	author			= "SHIM",
	description		= "Two knife kills Hotfix for ZR",
	version			= "1.0",
	url			= ""
};

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientConnected(i) || !IsClientInGame(i)) continue;

		OnClientPutInServer(i);
	}
}
public OnClientPutInServer(Client) 
{	
	SDKHook(Client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(Client, &attacker, &inflictor, &Float:damage, &damagetype, &ammotype, hitbox, hitgroup)
{
	if(!(inflictor > 0 && inflictor <= MaxClients && GetClientTeam(Client) != GetClientTeam(attacker))) return Plugin_Continue;
	
	new String:WeaponName[32];
	GetClientWeapon(inflictor, WeaponName, sizeof(WeaponName));

	if (StrContains(WeaponName, "knife", false) != -1 || StrContains(WeaponName, "bayonet", false) != -1)
	{
		if (ZR_IsClientZombie(attacker) && ZR_IsClientHuman(Client))
		{
			new health = GetClientHealth(Client);
			SetEntityHealth(Client, health + RoundToNearest(damage));
			
			return Plugin_Continue;
		}
		return Plugin_Continue;
	}
	return Plugin_Continue;
}