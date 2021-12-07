/*
Description:

If medic die while charging uber charge, the load back when he is reborn.

If you see a bug or doubts please comment.

CVARs:

sm_uber_recall_enabled = 1/0 - Plugin is enabled/disabled. (def. 1)
sm_uber_recall_version - Current plugin version

Changelog:

* Version 1.0.0 *
Initial Release

* Version 1.0.1 *
Fixed Vita-Saw broken plugin effect

*/

#include <sourcemod>
#include <tf2_stocks>
#include <sdkhooks>

/* 
	Current plugin version
*/
#define PLUGIN_VERSION "Build 1.0.1"

/* 
	HANDLES
*/
new Handle:gUberRecallEnabled = INVALID_HANDLE;

/* 
	VARIABLE
*/
new UberRecallEnabled;
new edict;
new defIdx;

/*
	Floats
*/
new Float:vChargerLevel[MAXPLAYERS+1];

/* 
	Plugin information
*/
public Plugin:myinfo =
{
	name = "Uber Recall",
	author = "Rodrigo286",
	description = "Allow players recall uber charge level on death.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?p=2022903",
}

public OnPluginStart()
{
/*
	Cvars
*/
	CreateConVar("sm_uber_recall_version", PLUGIN_VERSION, "\"Uber Recall\" version", FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY);
	gUberRecallEnabled = CreateConVar("sm_uber_recall_enabled", "1", "Uber Recall plugin is enabled?");
	AutoExecConfig(true, "uber_recall");

	HookConVarChange(gUberRecallEnabled, ConVarChange);	
	UberRecallEnabled = GetConVarBool(gUberRecallEnabled);

/* 
	Hook Events
*/
	HookEvent("player_spawn", OnPlayerSpawn);
}

public ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	UberRecallEnabled = GetConVarBool(gUberRecallEnabled);
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(!IsValidClient(client))
		return;

	if(UberRecallEnabled != 1)
		return;

	if(TF2_GetPlayerClass(client) == TF2_GetClass("medic"))
	{
		if((edict = GetPlayerWeaponSlot(client, 2)))
		{
			defIdx = GetEntProp(edict, Prop_Send, "m_iItemDefinitionIndex");

			if(defIdx == 173) // Detect if weapon is Vita-Saw for prevent bug and future new plugin features.
			{
				CreateTimer(0.6, load, client, TIMER_FLAG_NO_MAPCHANGE); // Create delay to prevent Vita-Saw Weapon bug.
			}
			else
			{
				CreateTimer(0.6, load, client, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage); // Detect imminent death using SDKHooks
	}
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	if(!IsValidClient(victim))
		return;

	if(damage >= GetClientHealth(victim) && TF2_GetPlayerClass(victim) == TF2_GetClass("medic")) // Detect imminent death of player and filter class to save charge level
	{
		new UberWeapons = GetPlayerWeaponSlot(victim, 1); // Get uber charger weapon's of medic
	
		vChargerLevel[victim] = GetEntPropFloat(UberWeapons, Prop_Send, "m_flChargeLevel"); // Store charge level on float
	}
}

public Action:load(Handle:timer, any:client) // Load uber charger level
{
	if(!IsValidClient(client))
		return Plugin_Stop;

	new UberWeapons = GetPlayerWeaponSlot(client, 1); // Get uber charger weapon's of medic

	if(UberWeapons != -1) 
	{ 
		SetEntPropFloat(UberWeapons, Prop_Send, "m_flChargeLevel", vChargerLevel[client]); // Set charge level stored in float
	}

	return Plugin_Continue;
}

public OnClientPutInServer(client)
{
	vChargerLevel[client] = 0.0; // Reset charger level if player connect
}

public OnClientDisconnect(client)
{
	vChargerLevel[client] = 0.0; // Reset charger level if player disconnect
}

public IsValidClient(client) 
{ 
    if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) ) 
        return false; 
     
    return true; 
}