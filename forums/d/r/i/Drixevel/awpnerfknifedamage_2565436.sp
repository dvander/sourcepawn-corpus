//Pragma
#pragma semicolon 1
#pragma newdecls required

//Sourcemod Includes
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "Awp Nerf Knife Damage", 
	author = "Keith Warren (Sky Guardian)", 
	description = "", 
	version = "1.0.0", 
	url = "http://www.sourcemod.com/"
};

public void OnPluginStart()
{
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
	//SDKHook_OnTakeDamageAlive past armor
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
	if (attacker == 0 || attacker > MaxClients)
	{
		return Plugin_Continue;
	}
	
	int primary = GetPlayerWeaponSlot(attacker, 0);
	int active = GetEntPropEnt(attacker, Prop_Send, "m_hActiveWeapon");
	
	if (!IsValidEntity(primary) || !IsValidEntity(active))
	{
		return Plugin_Continue;
	}
	
	char sClassname1[32];
	GetEntityClassname(primary, sClassname1, sizeof(sClassname1));
	
	char sClassname2[32];
	GetEntityClassname(active, sClassname2, sizeof(sClassname2));
	
	if (StrEqual(sClassname1, "weapon_awp") && StrContains(sClassname2, "knife") != -1)
	{
		damage *= 1.0 - 0.75;
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}