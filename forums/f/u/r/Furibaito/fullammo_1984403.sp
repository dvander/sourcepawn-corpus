/*
 * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 * 
 *  FullAmmoOnWeapons by Furibaito
 *
 *  fullammo.sp - Source file
 *
 * ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
 */

#include <sourcemod> 
#include <sdktools>
#include <sdkhooks>
#pragma semicolon 1 

#define PLUGIN_NAME "FullAmmoOnWeapons"
#define PLUGIN_VERSION "1.0.0"
#define DESC "Set all weapon entity in a map to full ammo"

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Furibaito",
	description = DESC,
	version = PLUGIN_VERSION,
	url = ""
};

public OnEntityCreated(entity, const String:classname[])
{
	if (StrContains(classname, "weapon_*", false))
	{
		DispatchKeyValue(entity, "ammo", "300");
	}
}