/*
Description:

Allows players to drop all grenades of your inventory

This plugin has been rewritten from the original made by member: Rodipm
Original thread: http://forums.alliedmods.net/showthread.php?t=172315

The cause of rewriting the plugin? Support bugs and add cvars.

I removed knife drop function.

Bugs fixed:

Infinite grenades: http://forums.alliedmods.net/showpost.php?p=1599372&postcount=11

CVARs:

sm_grenadedrop_enabled = 1/0 - Plugin is enabled/disabled.
sm_drop_he = 0/1 - Allow drop HE Grenades?
sm_drop_smoke = 0/1 Allow drop SMOKE Grenades?
sm_drop_flash = 0/1 Allow drop FLASH Grenades?
sm_grenadedrop_version - Current plugin version

Changelog:

* Version 1.0.0 *
Initial Release

* Version 1.0.1 *
Oficial CSGO Support

New cvar's
sm_drop_incendery = 0/1 Allow drop INCENDERY Grenades?
sm_drop_molotov = 0/1 Allow drop MOLOTOVS?
sm_drop_decoy = 0/1 Allow drop DECOY Grenades?

* Version 1.0.2 *
Little code clean

*/

#include <sourcemod>
#include <sdktools>
#include <cstrike>

/* 
	CSS Grenades Indexes
*/
#define HEGRENADE_AMMO 11
#define FLASH_AMMO 12
#define SMOKE_AMMO 13

/* 
	CS:GO Grenades Indexes
*/
#define CSGO_HEGRENADE_AMMO 13
#define CSGO_FLASH_AMMO 14
#define CSGO_SMOKE_AMMO 15
#define INCENDERY_AND_MOLOTOV_AMMO 16
#define	DECOY_AMMO 17

/* 
	Current plugin version
*/
#define PLUGIN_VERSION "Build 1.0.2"

/* 
	HANDLES
*/
new Handle:gGrenadeDropEnabled = INVALID_HANDLE;
new Handle:gAllowDropHe = INVALID_HANDLE;
new Handle:gAllowDropSmoke = INVALID_HANDLE;
new Handle:gAllowDropFlash = INVALID_HANDLE;
new Handle:gAllowDropIncendery = INVALID_HANDLE;
new Handle:gAllowDropMolotov = INVALID_HANDLE;
new Handle:gAllowDropDecoy = INVALID_HANDLE;

/* 
	GLOBAL
*/
new GrenadeDropEnabled;
new AllowDropHe;
new AllowDropSmoke;
new AllowDropFlash;
new AllowDropIncendery;
new AllowDropMolotov;
new AllowDropDecoy;

/* 
	Plugin information
*/
public Plugin:myinfo = {
	name = "SM: Grenade Drop",
	author = "Rodrigo286",
	description = "Allows players to drop all grenades of your inventory",
    version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=224570"
}

public OnPluginStart()
{
	CreateConVar("sm_grenadedrop_version", PLUGIN_VERSION, "\"SM: Grenade Drop\" version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);

	gGrenadeDropEnabled = CreateConVar("sm_grenadedrop_enabled", "1", "SM: Grenade Drop plugin is enabled?[CSS/CSGO]");
	gAllowDropHe = CreateConVar("sm_drop_he", "1", "Allow drop he grenades?[CSS/CSGO]");
	gAllowDropSmoke = CreateConVar("sm_drop_smoke", "1", "Allow drop smoke grenades?[CSS/CSGO]");
	gAllowDropFlash = CreateConVar("sm_drop_flash", "1", "Allow drop flash grenades?[CSS/CSGO]");
	gAllowDropIncendery = CreateConVar("sm_drop_incendery", "1", "Allow drop incendery grenades?[CSGO]");
	gAllowDropMolotov = CreateConVar("sm_drop_molotov", "1", "Allow drop molotovs?[CSGO]");
	gAllowDropDecoy = CreateConVar("sm_drop_decoy", "1", "Allow drop decoy grenades?[CSGO]");
	AutoExecConfig(true, "sm_grenade_drop");

	HookConVarChange(gGrenadeDropEnabled, ConVarChange);	
	HookConVarChange(gAllowDropHe, ConVarChange);
	HookConVarChange(gAllowDropSmoke, ConVarChange);
	HookConVarChange(gAllowDropFlash, ConVarChange);	
	HookConVarChange(gAllowDropIncendery, ConVarChange);
	HookConVarChange(gAllowDropMolotov, ConVarChange);
	HookConVarChange(gAllowDropDecoy, ConVarChange);

	GrenadeDropEnabled = GetConVarBool(gGrenadeDropEnabled);
	AllowDropHe = GetConVarBool(gAllowDropHe);
	AllowDropSmoke = GetConVarBool(gAllowDropSmoke);
	AllowDropFlash = GetConVarBool(gAllowDropFlash);
	AllowDropIncendery = GetConVarBool(gAllowDropIncendery);
	AllowDropMolotov = GetConVarBool(gAllowDropMolotov);
	AllowDropDecoy = GetConVarBool(gAllowDropDecoy);

	decl String:game[12];
	GetGameFolderName(game, sizeof(game));

	if(StrContains(game, "cstrike") != -1)
	{
		AddCommandListener(Drop_CSS, "drop");
	}
	else if(StrContains(game, "csgo") != -1)
	{
		AddCommandListener(Drop_CSGO, "drop");
	}
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GrenadeDropEnabled = GetConVarBool(gGrenadeDropEnabled);
	AllowDropHe = GetConVarBool(gAllowDropHe);
	AllowDropSmoke = GetConVarBool(gAllowDropSmoke);
	AllowDropFlash = GetConVarBool(gAllowDropFlash);
	AllowDropIncendery = GetConVarBool(gAllowDropIncendery);
	AllowDropMolotov = GetConVarBool(gAllowDropMolotov);
	AllowDropDecoy = GetConVarBool(gAllowDropDecoy);
}

public Action:Drop_CSS(client, const String:command[], argc)
{
	if(GrenadeDropEnabled != 1)
		return Plugin_Handled;

	decl String:name[80];
	new wpindex = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if(!IsValidEntity(wpindex))
		return Plugin_Handled;

	GetEntityClassname(wpindex, name, sizeof(name));

	if(IsValidClient(client))
	{
		if(StrEqual(name, "weapon_flashbang", false))
		{
			if(AllowDropFlash != 1)
				return Plugin_Handled;

			new flash = GetEntProp(client, Prop_Send, "m_iAmmo", _, FLASH_AMMO);

			if(flash >= 1)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", -1, _, FLASH_AMMO);
				CS_DropWeapon(client, wpindex, true, true); 
			}

			return Plugin_Handled;
		}
		else if(StrEqual(name, "weapon_hegrenade", false))
		{
			if(AllowDropHe != 1)
				return Plugin_Handled;

			new he = GetEntProp(client, Prop_Send, "m_iAmmo", _, HEGRENADE_AMMO);

			if(he >= 1)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", -1, _, HEGRENADE_AMMO);
				CS_DropWeapon(client, wpindex, true, true);
			}

			return Plugin_Handled;
		}
		else if(StrEqual(name, "weapon_smokegrenade", false))
		{
			if(AllowDropSmoke != 1)
				return Plugin_Handled;

			new smoke = GetEntProp(client, Prop_Send, "m_iAmmo", _, SMOKE_AMMO);

			if(smoke >= 1)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", -1, _, SMOKE_AMMO);
				CS_DropWeapon(client, wpindex, true, true);
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public Action:Drop_CSGO(client, const String:command[], argc)
{
	if(GrenadeDropEnabled != 1)
		return Plugin_Handled;

	decl String:name[80];
	new wpindex = GetEntPropEnt(client, Prop_Data, "m_hActiveWeapon");

	if(!IsValidEntity(wpindex))
		return Plugin_Handled;

	GetEntityClassname(wpindex, name, sizeof(name));

	if(IsValidClient(client))
	{
		if(StrEqual(name, "weapon_flashbang", false))
		{
			if(AllowDropFlash != 1)
				return Plugin_Handled;

			new flash = GetEntProp(client, Prop_Send, "m_iAmmo", _, CSGO_FLASH_AMMO);

			if(flash >= 1)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", -1, _, CSGO_FLASH_AMMO);
				CS_DropWeapon(client, wpindex, true, true);
			}

			return Plugin_Handled;
		}
		else if(StrEqual(name, "weapon_hegrenade", false))
		{
			if(AllowDropHe != 1)
				return Plugin_Handled;

			new he = GetEntProp(client, Prop_Send, "m_iAmmo", _, CSGO_HEGRENADE_AMMO);

			if(he >= 1)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", -1, _, CSGO_HEGRENADE_AMMO);
				CS_DropWeapon(client, wpindex, true, true);
			}

			return Plugin_Handled;
		}
		else if(StrEqual(name, "weapon_smokegrenade", false))
		{
			if(AllowDropSmoke != 1)
				return Plugin_Handled;

			new smoke = GetEntProp(client, Prop_Send, "m_iAmmo", _, CSGO_SMOKE_AMMO);

			if(smoke >= 1)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", -1, _, CSGO_SMOKE_AMMO);
				CS_DropWeapon(client, wpindex, true, true);
			}

			return Plugin_Handled;
		}
		else if(StrEqual(name, "weapon_incgrenade", false))
		{
			if(AllowDropIncendery != 1)
				return Plugin_Handled;

			new incendery = GetEntProp(client, Prop_Send, "m_iAmmo", _, INCENDERY_AND_MOLOTOV_AMMO);

			if(incendery >= 1)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", -1, _, INCENDERY_AND_MOLOTOV_AMMO);
				CS_DropWeapon(client, wpindex, true, true);
			}

			return Plugin_Handled;
		}
		else if(StrEqual(name, "weapon_molotov", false))
		{
			if(AllowDropMolotov != 1)
				return Plugin_Handled;

			new molotov = GetEntProp(client, Prop_Send, "m_iAmmo", _, INCENDERY_AND_MOLOTOV_AMMO);

			if(molotov >= 1)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", -1, _, INCENDERY_AND_MOLOTOV_AMMO);
				CS_DropWeapon(client, wpindex, true, true);
			}

			return Plugin_Handled;
		}
		else if(StrEqual(name, "weapon_decoy", false))
		{
			if(AllowDropDecoy != 1)
				return Plugin_Handled;

			new decoy = GetEntProp(client, Prop_Send, "m_iAmmo", _, DECOY_AMMO);

			if(decoy >= 1)
			{
				SetEntProp(client, Prop_Send, "m_iAmmo", -1, _, DECOY_AMMO);
				CS_DropWeapon(client, wpindex, true, true);
			}

			return Plugin_Handled;
		}
	}

	return Plugin_Continue;
}

public IsValidClient(client) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}