#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

#define PLUGIN_VERSION 		"1.0"

public Plugin:myinfo = {
	name = "Mackerel Fix",
	author = "Modified by Fox (All Creds to Wazz)",
	description = "prevents the Holy Mackerel + Bonk crash",
	version = PLUGIN_VERSION,
};

// This is the main 'event trigger' for the plugin when stuff starts happening
public OnEntityCreated(entity, const String:classname[])
{
	// The algorithm must be done next frame so that the entity is fully spawned
	CreateTimer(0.0, ProcessEdict, entity, TIMER_FLAG_NO_MAPCHANGE);
	
	return;
}

public Action:ProcessEdict(Handle:timer, any:edict)
{
	if (!IsValidEdict(edict))
		return Plugin_Handled;
		
	new String:netclassname[64];
	GetEntityNetClass(edict, netclassname, sizeof(netclassname));
	
	// Checking to see if its an edict with an Item Definition Index
	if (FindSendPropOffs(netclassname, "m_iItemDefinitionIndex") == -1)
		return Plugin_Handled;
		
	new defIdx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");
	
	if(defIdx == -1)
		return Plugin_Handled;
	
	//Check to see if the weapon being created is either (46) Bonk! Atomic Punch or (221) The Holy Mackerel
	if(defIdx != 221 && defIdx != 46)
		return Plugin_Handled;
	
	//Check to see if this player has both weapons equipped
	new client = GetEntPropEnt(edict, Prop_Send, "m_hOwnerEntity");
	
	if(client == -1)
		return Plugin_Handled;
	
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return Plugin_Handled;
	
	new hasWeapon;
	new foundWeapon;
	new weapon;
	
	for (new x=0; x<11; x++)
	{
		if((weapon = GetPlayerWeaponSlot(client, x)) != -1)
		{
			foundWeapon = GetEntProp(weapon, Prop_Send, "m_iItemDefinitionIndex");
			if(foundWeapon == 221 || foundWeapon == 46)
				hasWeapon++;
		}
	}
	
	//LogMessage("Found: %i", hasWeapon);
	//the player is attempting to equip both weapons
	if(hasWeapon == 2)
	{
		RemovePlayerItem(client, edict);
		RemoveEdict(edict);
		
		PrintCenterText(client, "Cannot use both Mackerel and Bonk! Switch your loadout!");
		PrintToChat(client, "\x04[Unlock Problem!]:\x01 You cannot use both the Holy Mackerel and the Bonk Atomic Punch together due to stability issues!");
	}
	
	return Plugin_Handled;
}