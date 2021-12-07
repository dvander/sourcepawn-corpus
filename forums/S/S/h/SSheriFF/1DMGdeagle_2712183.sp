#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "1 DMG Deagle",
	author = "SheriF",
	description = "",
	version = "1.0",
	url = ""
};

public void OnClientPutInServer(int client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamageHook);
}
public Action OnTakeDamageHook(int client, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if ((client>=1) && (client<=MaxClients) && (attacker>=1) && (attacker<=MaxClients) && (attacker==inflictor))
    {
        char WeaponName[64];
        GetClientWeapon(attacker, WeaponName, sizeof(WeaponName));
        if (StrContains(WeaponName, "deagle", false) != -1)
        {
            damage = 1.0;
            return Plugin_Changed;
        }
    }
    return Plugin_Continue;
}
