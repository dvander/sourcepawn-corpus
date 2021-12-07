#include <sourcemod>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = 
{
	name			= 	"No knife damage",
	author			= 	"Cruze",
	description		= 	"No knife damage I guess",
	version			= 	"1.0",
	url				= 	"http://steamcommunity.com/profiles/76561198132924835"
}

public void OnPluginStart()
{
    for(int client = 1; client <= MaxClients; client++) 
    { 
        if (IsClientInGame(client)) 
        {
            SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
        }
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamageAlive, OnTakeDamageAlive);
}

public Action OnTakeDamageAlive(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	char WeaponName[64];
	GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));
	if(StrContains(WeaponName, "knife", false) != -1 || StrContains(WeaponName, "fists", false) != -1 || StrContains(WeaponName, "axe", false) != -1 || StrContains(WeaponName, "hammer", false) != -1 || StrContains(WeaponName, "spanner", false) != -1 || StrContains(WeaponName, "melee", false) != -1)
	{
		damage = 0.0;
		PrintCenterText(attacker, "Knife Damage is Disabled.");
		return Plugin_Changed;
	}
	return Plugin_Continue;
}