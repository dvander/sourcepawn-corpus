#pragma semicolon 1

#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#include <tf2attributes>

public void OnPluginStart()
{
	HookEvent("post_inventory_application", Event_PlayerSpawn, EventHookMode_Post);
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	int Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Primary);
	if(IsValidEntity(Weapon))
	{
		TF2Attrib_SetByName(Weapon, "weapon_allow_inspect", 1.0);
	}
	
	Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Secondary);
	if(IsValidEntity(Weapon))
	{
		TF2Attrib_SetByName(Weapon, "weapon_allow_inspect", 1.0);
	}
	
	Weapon = GetPlayerWeaponSlot(client, TFWeaponSlot_Melee);
	if(IsValidEntity(Weapon))
	{
		TF2Attrib_SetByName(Weapon, "weapon_allow_inspect", 1.0);
	}
}