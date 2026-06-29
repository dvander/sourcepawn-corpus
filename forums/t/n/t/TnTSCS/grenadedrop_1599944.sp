#include <sourcemod>
#include <sdktools>
#include <cstrike>

public Plugin:myinfo =
{
	name = "Grenade Drop (he, flash, smoke)",
	author = "rodipm",
	description = "Allows you to drop your grenades like dropping normal weapons (by default pressing 'G')",
	version = "1.1",
	url = "sourcemod.net"
}

public OnPluginStart()
{
	AddCommandListener(Drop, "drop");
}

public Action:Drop(client, const String:command[], argc)
{
	decl String:name[80];
	new wpindex = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");
	
	if(!IsValidEntity(wpindex))
		return Plugin_Handled;
		
	GetEntityClassname(wpindex, name, sizeof(name));
	
	if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(StrEqual(name, "weapon_flashbang", false) || StrEqual(name, "weapon_hegrenade", false) || StrEqual(name, "weapon_smokegrenade", false))
		{
			CS_DropWeapon(client, wpindex, true, true);
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}