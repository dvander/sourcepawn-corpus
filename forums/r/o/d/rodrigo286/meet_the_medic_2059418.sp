/*
Description:

The medic's receives godmod, however can only use the uber charger weapon's.

CVARs:

sm_meet_the_medic_enabled = 1/0 - Plugin is enabled/disabled.
sm_meet_the_medic_version - Current plugin version

Changelog:

* Version 1.0.0 *
Initial Release

* Version 1.0.1 *
Remove manual godmod (Ubercharge condition give the godmod)
Remove speed lock (Dont need use it yet)
Some code clean and fix

*/

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

/* 
	Current plugin version
*/
#define PLUGIN_VERSION "Build 1.0.0"

/* 
	HANDLES
*/
new Handle:gMeetTheMedicEnabled = INVALID_HANDLE;

/* 
	VARIABLE
*/
new MeetTheMedicEnabled;

/* 
	Plugin information
*/
public Plugin:myinfo =
{
	name = "Meet the medic",
	author = "Rodrigo286",
	description = "The medic's receives godmod, however can only use the uber charger weapon's",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=224850",
}

public OnPluginStart()
{
/*
	Cvars
*/
	CreateConVar("sm_meet_the_medic_version", PLUGIN_VERSION, "\"Meet the Medic\" version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);
	gMeetTheMedicEnabled = CreateConVar("sm_meet_the_medic_enabled", "1", "Meet the Medic plugin is enabled?");
	AutoExecConfig(true, "meet_the_medic");

	HookConVarChange(gMeetTheMedicEnabled, ConVarChange);	
	MeetTheMedicEnabled = GetConVarBool(gMeetTheMedicEnabled);

/* 
	Hook Events
*/
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("player_changeclass", OnPlayerChangeClass);
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	MeetTheMedicEnabled = GetConVarBool(gMeetTheMedicEnabled);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return Plugin_Handled;

	if(MeetTheMedicEnabled != 1)
		return Plugin_Handled;

	if(TF2_GetPlayerClass(client) == TF2_GetClass("medic"))
	{
		new UberWeapons = GetPlayerWeaponSlot(client, 1); // Get uber charger weapon's of medic
		TF2_AddCondition(client, TFCond_Disguised, 999.0); // Apply disguised condition to lock ubercharger condition
		TF2_AddCondition(client, TFCond_Ubercharged, 999.0); // Apply ubercharger condition to block medics push the bomb
		SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse); // Prevent player take weapons of the base dispenser
		TF2_RemoveWeaponSlot(client, 0); // Remove weapons of slot 0
		TF2_RemoveWeaponSlot(client, 2); // Remove weapons of slot 2

		if(UberWeapons != -1) 
		{ 
			EquipPlayerWeapon(client, UberWeapons); // Force player equip medigun weapon
		}
	}
	else if(TF2_GetPlayerClass(client) != TF2_GetClass("medic"))
	{
		TF2_RemoveCondition(client, TFCond_Disguised); // Clean disguised condition
		TF2_RemoveCondition(client, TFCond_Ubercharged); // Clean ubercharger condition
		TF2_RemoveAllWeapons(client); // Clean medic weapon
		TF2_RespawnPlayer(client); // Respawn player to recovery class equips
	}
	

	return Plugin_Continue;
}

public Action:OnPlayerChangeClass(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return Plugin_Handled;

	if(MeetTheMedicEnabled != 1)
		return Plugin_Handled;

	if(TF2_GetPlayerClass(client) != TF2_GetClass("medic"))
	{
		TF2_RemoveCondition(client, TFCond_Disguised); // Clean disguised condition
		TF2_RemoveCondition(client, TFCond_Ubercharged); // Clean ubercharger condition
		TF2_RemoveAllWeapons(client); // Clean medic weapon
		TF2_RespawnPlayer(client); // Respawn player to recovery class equips
	}

	return Plugin_Continue;
}

public Action:OnWeaponCanUse(client, weapon)
{
	new String:WeaponString[32];
	GetEntityClassname(weapon, WeaponString, sizeof(WeaponString));

	if(TF2_GetPlayerClass(client) == TF2_GetClass("medic")) // Detect if player is medic
	{
		if(StrEqual(WeaponString, "tf_weapon_medigun")) // Allow medic use only medigun weapons
			return Plugin_Continue;
	}
	else if(TF2_GetPlayerClass(client) != TF2_GetClass("medic")) // If player dont medic, all weapons is allowed
	{
		return Plugin_Continue;
	}

	return Plugin_Handled;
}

public Action:OnWeaponSwitch(client, weapon)
{
    decl String:sWeapon[32];
    GetEdictClassname(weapon, sWeapon, sizeof(sWeapon));
    
    if(StrEqual(sWeapon, "tf_weapon_rocketlauncher"))
        return Plugin_Handled;
    
    return Plugin_Continue;
}

public IsValidClient(client) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}