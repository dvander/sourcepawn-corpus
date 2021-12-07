#pragma semicolon 1 // Force strict semicolon mode.

#include <sourcemod>
#define REQUIRE_EXTENSIONS
#include <sdktools>
#include <tf2>

public Plugin:myinfo =
{
	name			= "[TF2] Soldier Secondaries",
	author			= "Asherkin",
	description	= "Removes Soldier Secondaries.",
	version		= "1.0.0",
	url				= "http://limetech.org/"
};

public OnPluginStart()
{
	HookEvent("post_inventory_application", Event_PostInventoryApplication);
}

public Event_PostInventoryApplication(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client_id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(client_id);
	CreateTimer(0.1, RemoveWeaponSlotSecondary, client);
}

public Action:RemoveWeaponSlotSecondary(Handle:timer, any:client)
{
	new weapon = GetPlayerWeaponSlot(client, 1);
	
	if (!IsValidEntity(weapon))
		return Plugin_Stop;
	
	new weaponIndex = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex", 4);
	
	if (weaponIndex != 133)
	{
	RemovePlayerItem(client, weapon);
	RemoveEdict(weapon);
	}
	
	return Plugin_Stop;
}