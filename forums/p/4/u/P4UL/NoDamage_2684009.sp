#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "P4UL"
#define PLUGIN_VERSION "1.1"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "P4UL",
	author = PLUGIN_AUTHOR,
	description = "Disable knife/zeus etc damage",
	version = PLUGIN_VERSION,
	url = "ZU-GAMING.COM"
};

public void OnPluginStart()
{
	for (int client = 1; client <= MaxClients; client++) 
    { 
        if (IsClientInGame(client)) 
        {
            SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
        }
    }
}

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, Hook_OnTakeDamage);
}

public Action Hook_OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if ( (victim>=1) && (victim<=MaxClients) && (attacker>=1) && (attacker<=MaxClients) && (attacker==inflictor) )
    {
        char WeaponName[64];
        GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));
        if (StrContains(WeaponName, "knife", false) != -1 || StrContains(WeaponName, "taser", false) != -1)
        {
            damage = 0.0;
            return Plugin_Changed;
        }
    }
	return Plugin_Continue;
}

