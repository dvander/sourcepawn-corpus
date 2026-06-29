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
#define PLUGIN_VERSION "1.0.1"
#define DESC "Set all weapon entity in a map to full ammo"

new Handle:CVARGlobalAmmo;

new GlobalAmmo;

public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = "Furibaito",
	description = DESC,
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	CVARGlobalAmmo = CreateConVar("map_weapons_ammo", "350", "Set how much reserve ammunition available in weapons that are available in a map. Maximum is 999.", _, true, 0.0, true, 999.0);
	GlobalAmmo = GetConVarInt(CVARGlobalAmmo);
	
	HookConVarChange(CVARGlobalAmmo, GlobalAmmoChange);
}

public GlobalAmmoChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	GlobalAmmo = GetConVarInt(CVARGlobalAmmo);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrContains(classname, "weapon_*", false))
	{
		new String:value[4];
		IntToString(GlobalAmmo, value, sizeof(value));
		DispatchKeyValue(entity, "ammo", value);
	}
}