#pragma semicolon 1

#include <sdktools>
#include <tf2_stocks>
#include <tf2attributes>

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_PlayerSpawn);
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

/*
-- Broken for some reason, doesn't let you pick up weapons if you use this method
#include <tf2items>
Handle newItem;

public OnConfigsExecuted() 
{
	if(newItem != INVALID_HANDLE) 
	{
		CloseHandle(newItem);
	}
	
	newItem = TF2Items_CreateItem(PRESERVE_ATTRIBUTES|OVERRIDE_ATTRIBUTES);
	TF2Items_SetAttribute(newItem, 0, 731, 1.0);
	TF2Items_SetAttribute(newItem, 1, 134, float(GetRandomInt(701, 704)));
	
	TF2Items_SetNumAttributes(newItem, 2);
}

public Action TF2Items_OnGiveNamedItem(int client, char[] classname, int defindex, Handle &item) 
{
	if(StrContains(classname, "tf_weapon") != -1)
	{
		item = newItem;
		
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}*/
