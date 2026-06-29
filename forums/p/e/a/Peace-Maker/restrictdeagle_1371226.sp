#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin:myinfo = 
{
	name = "Restrict Deagle",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Restricts the deagle on spawn",
	version = "1.0",
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	//HookEvent("item_pickup", Event_OnItemPickup);
}


public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:sWeapon[100];
	new iSecondaryWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
	if(iSecondaryWeapon != -1)
	{
		GetEdictClassname(iSecondaryWeapon, sWeapon, sizeof(sWeapon));
		if(StrEqual(sWeapon, "weapon_deagle"))
			RemovePlayerItem(client, iSecondaryWeapon);
	}
	return Plugin_Continue;
}

/*
public Event_OnItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt( event, "userid"));
	decl String:sItem[100];
	GetEventString(event, "item", sItem, sizeof(sItem));
	
	// strip deagle
	if(StrEqual(sItem, "deagle", false))
	{
		new iSecondaryWeapon = GetPlayerWeaponSlot(client, CS_SLOT_SECONDARY);
		if(iSecondaryWeapon != -1)
		{
			RemovePlayerItem(client, iSecondaryWeapon);
		}
	}
}
*/