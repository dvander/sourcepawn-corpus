#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Klaus"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>


public Plugin myinfo = 
{
	name = "2 Bullets", 
	author = PLUGIN_AUTHOR, 
	description = "2 Bullets for deagle", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/KlausLaw/"
};


public OnClientPostAdminCheck(int client)
{
	SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
}

public Action OnWeaponEquip(int client, int weapon)
{
	char sWeapon[32];
	GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
	if (!StrEqual(sWeapon, "weapon_deagle"))return Plugin_Continue;
	if (GetEntProp(weapon, Prop_Send, "m_iClip1") <= 2)return Plugin_Continue;
	CreateTimer(0.1, Timer_ChangeClip, client);
	return Plugin_Continue;
}

public Action Timer_ChangeClip(Handle timer, int client)
{
	int weapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	SetEntProp(weapon, Prop_Send, "m_iPrimaryReserveAmmoCount", 0);
	SetEntProp(weapon, Prop_Send, "m_iClip1", 2);
} 