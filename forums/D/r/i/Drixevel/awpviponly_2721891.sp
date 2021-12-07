#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

public Plugin myinfo =
{
	name = "[CS:GO/CSS] AWP for VIPs Only",
	author = "Drixevel",
	description = "Only allow VIPs to purchase, equip and use AWPs.",
	version = "1.0.0",
	url = "http://drixevel.dev/"
};

public void OnPluginStart()
{
	for (int i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i))
			OnClientPutInServer(i);
}

public void OnClientPutInServer(int client)
{
	SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCheck);
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponCheck);
}

public Action OnWeaponCheck(int client, int weapon)
{
	if (CheckCommandAccess(client, "", ADMFLAG_RESERVATION, true))
		return Plugin_Continue;

	char classname[32];
	GetEntityClassname(weapon, classname, sizeof(classname));
	
	if (StrEqual(classname, "weapon_awp", false))
		return Plugin_Handled;
	
	return Plugin_Continue;
}

public Action CS_OnBuyCommand(int client, const char[] weapon)
{
	if (CheckCommandAccess(client, "", ADMFLAG_RESERVATION, true))
		return Plugin_Continue;
	
	if (StrEqual(weapon, "awp", false))
		return Plugin_Handled;
	
	return Plugin_Continue;
}