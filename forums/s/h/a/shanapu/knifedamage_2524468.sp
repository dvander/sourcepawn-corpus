#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Knife damage to 1000",
	author = "shanapu",
	description = "https://forums.alliedmods.net/showthread.php?t=297988",
	version = "1.1",
	url = "https://github.com/shanapu/"
};

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	if(!IsValidEdict(weapon))
		return Plugin_Continue;

	char sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));

	if(StrEqual(sWeapon, "weapon_knife") || StrEqual(sWeapon, "weapon_knife_t"))
	{
		damage = 1000.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}