#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define HEGRENADE_AMMO 11
#define FLASH_AMMO 12
#define SMOKE_AMMO 13

new Handle:cknife;

public Plugin:myinfo =
{ 
	name = "Grenade Drop (he, flash, smoke)",
	author = "rodipm",
	description = "Allows you to drop your grenades like dropping normal weapons (by default pressing 'G')",
	version = "1.3",
	url = "http://forums.alliedmods.net/showthread.php?t=172315"
}

public OnPluginStart()
{
	AddCommandListener(Drop, "drop");
	cknife = CreateConVar("gd_dropknife", "0", "allows you to drop the knife too");
}

public Action:Drop(client, const String:command[], argc)
{
	decl String:name[80];
	new count;
	new index;
	new wpindex = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if(!IsValidEntity(wpindex))
		return Plugin_Handled;

	GetEntityClassname(wpindex, name, sizeof(name));

	if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(StrEqual(name, "weapon_flashbang", false))
		{
			count = GetEntProp(client, Prop_Send, "m_iAmmo", _, FLASH_AMMO);
			CS_DropWeapon(client, wpindex, true, true);
			if(count > 1)
			{
				index = GivePlayerItem(client, "weapon_flashbang");
				SetEntProp(client, Prop_Send, "m_iAmmo", count-1, _, FLASH_AMMO);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", index);
			}
			return Plugin_Handled;
		}
		else if(StrEqual(name, "weapon_hegrenade", false))
		{
			count = GetEntProp(client, Prop_Send, "m_iAmmo", _, HEGRENADE_AMMO);
			CS_DropWeapon(client, wpindex, true, true);
			if(count > 1)
			{
				index = GivePlayerItem(client, "weapon_hegrenade");
				SetEntProp(client, Prop_Send, "m_iAmmo", count-1, _, HEGRENADE_AMMO);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", index);
			}
			return Plugin_Handled;
		}
		else if(StrEqual(name, "weapon_smokegrenade", false))
		{
			count = GetEntProp(client, Prop_Send, "m_iAmmo", _, SMOKE_AMMO);
			CS_DropWeapon(client, wpindex, true, true);
			if(count > 1)
			{
				index = GivePlayerItem(client, "weapon_smokegrenade");
				SetEntProp(client, Prop_Send, "m_iAmmo", count-1, _, SMOKE_AMMO);
				SetEntPropEnt(client, Prop_Send, "m_hActiveWeapon", index);
			}
			return Plugin_Handled;
		}
		else if(StrEqual(name, "weapon_knife", false) && GetConVarInt(cknife) == 1)
		{
			CS_DropWeapon(client, wpindex, true, true);
			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}