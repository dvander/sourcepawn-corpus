#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

#define GAMEDATA			"l4d2_backpack"
#define PLUGIN_VERSION 		"1.0"
#define CHAT_TAG			"\x04[\x05Backpack Forwards\x04] \x01"

// Setup Forward Handles
Handle g_ActiveWeapon_Forward;
Handle g_WeaponEquip_Forward;

public Plugin myinfo =
{
	name = "Backpack Forwards",
	author = "$atanic $pirit",
	description = "Provides forwards for backpack",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	Handle hGameData = LoadGameConfigFile(GAMEDATA);
	if( hGameData == null ) 
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);
	
	// ====================================================================================================
	// Detour Setup - CBaseCombatCharacter::OnChangeActiveWeapon
	// ====================================================================================================
		
	// Create a hook from config.
	Handle hDetour_OnChangeActiveWeapon = DHookCreateFromConf(hGameData, "CBaseCombatCharacter::OnChangeActiveWeapon");
	if( !hDetour_OnChangeActiveWeapon )
		SetFailState("Failed to setup detour for CBaseCombatCharacter::OnChangeActiveWeapon");
	
	// Add a post hook on the function.
	if (!DHookEnableDetour(hDetour_OnChangeActiveWeapon, false, Detour_OnChangeActiveWeapon))
		SetFailState("Failed to detour OnChangeActiveWeapon.");

	// ====================================================================================================
	// Detour Setup - CBaseCombatWeapon::Weapon_Equip
	// ====================================================================================================
	
		// Create a hook from config.
	Handle hDetour_Weapon_Equip = DHookCreateFromConf(hGameData, "CBaseCombatCharacter::Weapon_Equip");
	if( !hDetour_Weapon_Equip )
		SetFailState("Failed to setup detour for CBaseCombatCharacter::Weapon_Equip");
	
	// Add a post hook on the function.
	if (!DHookEnableDetour(hDetour_Weapon_Equip, false, Detour_Weapon_Equip))
		SetFailState("Failed to detour Weapon_Equip.");
		
	// ====================================================================================================
	// Forwards Setup
	// ====================================================================================================
	g_ActiveWeapon_Forward	= CreateGlobalForward("l4d2_OnChangeActiveWeapon", ET_Ignore, Param_Cell, Param_Cell, Param_String);
	g_WeaponEquip_Forward	= CreateGlobalForward("l4d2_OnWeaponEquip", ET_Ignore, Param_Cell, Param_Cell, Param_String);
}

// ====================================================================================================
// Function	-	CBaseCombatCharacter::OnChangeActiveWeapon
// ====================================================================================================

public MRESReturn Detour_OnChangeActiveWeapon(Address pThis, Handle hParams)
{	
	// Get the Int value
	int	client			= view_as<int>(pThis);
	int  weapon		= DHookGetParam(hParams, 1);
	char name[20];
	name = GetEntityName(weapon);
	
	/* Start function call */
	Call_StartForward(g_ActiveWeapon_Forward);

	/* Push parameters one at a time */
	Call_PushCell(client);
	Call_PushCell(weapon);
	Call_PushString(name);

	/* Finish the call, get the result */
	Call_Finish();
	
	PrintToChatAll("%s OnChangeActiveWeapon - Player Name: %N, Weapon Name: %s", CHAT_TAG, client, GetEntityName(weapon));
	return MRES_Ignored;
}

// ====================================================================================================
// Function	-	CBaseCombatCharacter::Weapon_Equip
// ====================================================================================================

public MRESReturn Detour_Weapon_Equip(Address pThis, Handle hParams)
{	
	// Get the Int value
	int  client		= view_as<int>(pThis);
	int  weapon		= DHookGetParam(hParams, 1);
	char name[20];
	name = GetEntityName(weapon);
	
	/* Start function call */
	Call_StartForward(g_WeaponEquip_Forward);

	/* Push parameters one at a time */
	Call_PushCell(client);
	Call_PushCell(weapon);
	Call_PushString(name);

	/* Finish the call, get the result */
	Call_Finish();
	
	PrintToChatAll("%s Weapon_Equip - Player Name: %N, Weapon Name: %s.", CHAT_TAG, client, GetEntityName(weapon));
	return MRES_Ignored;
}

// ====================================================================================================
// GetEntityName	-	Stock to get weapon's name
// ====================================================================================================

stock char GetEntityName(int entity)
{
	char name[20];
	GetEntityClassname(entity, name, sizeof name);
	
	if(StrEqual(name, "weapon_melee"))
	{
		GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", name, sizeof name);
	}
	return name;
}