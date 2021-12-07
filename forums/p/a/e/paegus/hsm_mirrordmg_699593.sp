/*
 * Hidden:SourceMod - Mirror Damage
 *
 * Description:
 *  Reflects a potion of team-damage back on attacker
 *  or allows the vicitms 'armour' to absorb some.
 *
 * CVars:
 *  hsm_mirror_ratio [0~1] : ratio of damage to restore to victim 0-100%
 *  hsm_mirror_armour [0/1] : disable damage reflection on attacker?
 *  hsm_mirror_spawnguard [seconds]: Time from spawn to have 100%. Is disabled as soon as hidden attacks
 *  hsm_mirror_weight [0/1] : does the victim gain weight from team-attacks. 0: Disabled, 1:Enabled. Default 1.
 *
 * Changelog:
 *  v1.0.2
 *   Actually added option to bonus weight of victim
 *   Spawnguard now elapses automatically when the hidden attacks or is attacked.
 *  v1.0.1
 *   Added message from server when an attacker dies due to mirrored damage.
 *   Added option to boost victim's weighting by the amount of health they lost.
 *  v1.0.0
 *   Initial Release
 *
 */

#define PLUGIN_VERSION		"1.0.2"

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define DAMAGE_TYPE "16384"

new Handle:cvarArmour;		// Armour absorbs some friendly fire but does not reflect it back on attacker?
new Handle:cvarRatio;		// Damage reflection level.
new Handle:cvarSpawnGuard;	// Seconds from round-start to have 100%
new Handle:cvarWeightAdd;	// Do we boost the victim's weighting?
new Handle:cvarSelection;	// Link to hdn_selectmethod.

new Float:g_fActiveRatio;	// Effective reflection level.

public Plugin:myinfo =
{
	name		= "H:SM - Mirror",
	author		= "Paegus",
	description = "Mirrors or absorbs team-damage.",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart()
{
	CreateConVar(
		"hsm_mirror_version",
		PLUGIN_VERSION,
		"H:SM - Mirror damage Version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarArmour = CreateConVar(
		"hsm_mirror_armour",
		"0.0",
		"Restore hsm_mirror_ratio health to victim but don't take it from attacker",
		_,
		true, 0.0,
		true, 1.0
	);

	cvarRatio = CreateConVar(
		"hsm_mirror_ratio",
		"0.666666",
		"Team-damage to restore or reflect. 0: Disable (0%), 1: Full (100%).",
		_,
		true, -1.0,
		true, 1.0
	);

	cvarSpawnGuard = CreateConVar(
		"hsm_mirror_spawnguard",
		"10.0",
		"Seconds from round start have 100% restore/reflect. Automatically disabled on hidden attack. 0: Disable",
		_,
		true, 0.0,
		true, 15.0
	);

	cvarWeightAdd = CreateConVar(
		"hsm_mirror_weightadd",
		"0.0",
		"Add the remaining damage to the victim's weight-points? 0: Disable, 1: Enable",
		_,
		true, 0.0,
		true, 1.0
	);

	cvarSelection = FindConVar("hdn_selectmethod");

	HookEvent("player_hurt", event_PlayerHurt, EventHookMode_Pre);
	HookEvent("game_round_start", event_RoundStart);
	HookConVarChange(cvarRatio, CvarChange_Ratio);

	g_fActiveRatio = GetConVarFloat(cvarRatio); // active mirror's initial setting.

}

public event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(cvarSelection)) // it's not weighted
		return;

	new Float:fSpawnTimeout = GetConVarFloat(cvarSpawnGuard);
	if (fSpawnTimeout > 0) // Spawn guarding is enabled
	{
		g_fActiveRatio = 1.0; // Set full mirroring
		CreateTimer(fSpawnTimeout, tSpawnGuard); // Delay to reset to normal mirror level
	}
	// else spawn guarding is disabled.
}

public Action:tSpawnGuard(Handle:timer)
{
	SpawnGuardElapse();
}

SpawnGuardElapse()
{
	if (g_fActiveRatio == GetConVarFloat(cvarRatio)) // Already elapsed
		return;

//	LogToGame("[MirrorDmg] Spawn guard elapsed!");
	g_fActiveRatio = GetConVarFloat(cvarRatio); // reset active ratio setting.
}

public CvarChange_Ratio(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_fActiveRatio = GetConVarFloat(cvarRatio); // Update active ratio setting if set in-round.
}

public event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarFloat(cvarRatio) == 0 || GetConVarInt(cvarSelection)) // Mirror is 0% or selection is not weighted so we're done here
		return;

	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker")); // Get attacker
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid")); // Get victim

	if (!iAttacker || iAttacker == iVictim)	// World or self attack so we're done here.
		return;

	new iAttackerTeam = GetClientTeam(iAttacker);
	new iVictimTeam = GetClientTeam(iVictim);

	if (iAttackerTeam == 3 || iVictimTeam == 3) // Hidden attacked
	{
		SpawnGuardElapse();
		return;
	}

	if (iAttackerTeam != 2 || iAttackerTeam != iVictimTeam) // Wasn't IRIS OR Same team so we're done here.
		return;

	new Float:fDamage = GetEventFloat(event, "damage"); // Damage done
	new Float:fUndamage = (fDamage * g_fActiveRatio); // Calculate restoration factor
	new iHealth = GetClientHealth(iVictim) + RoundToNearest(fUndamage); // Calculate their new health.
	new iNewDamage = RoundToNearest(fDamage - fUndamage);

	SetEventInt(event, "damage", iNewDamage); // Alter the damage.

	SetEntData(iVictim, FindDataMapOffs(iVictim, "m_iHealth"), iHealth, 4, true); // Set victim's new health.

	new osWeight = FindSendPropOffs("CSDKPlayer","m_iWeighting");

	if (GetConVarInt(cvarWeightAdd)) // weight boosting victim is enabled
	{
		SetEntData(iVictim, osWeight, GetEntData(iVictim, osWeight, 4) + RoundToNearest((1.0 - g_fActiveRatio) * GetEventFloat(event, "damage")), 4, true);
	}

	if (GetConVarInt(cvarArmour)) // Armour mode enabled, adjust weighting and leave it at that.
	{
		SetEntData(iAttacker, osWeight, GetEntData(iAttacker, osWeight, 4) + RoundToNearest(fUndamage), 4, true);
		return;
	}

	// Hurt the attacker
	new String:sPointDamage[64];
	Format(
		sPointDamage,
		sizeof(sPointDamage),
		"%f",
		fUndamage
	);	// Format the entity's output

	new pointHurt = CreateEntityByName("point_hurt");			// Create point_hurt
	DispatchKeyValue(iAttacker, "targetname", "hurtmebaby");	// Tag target
	DispatchKeyValue(pointHurt, "Damage", sPointDamage);		// Damage to target
	DispatchKeyValue(pointHurt, "DamageTarget", "hurtmebaby");	// Target
	DispatchKeyValue(pointHurt, "DamageType", DAMAGE_TYPE);		// TYpe of damage
	DispatchSpawn(pointHurt);									// Set info to entity
	AcceptEntityInput(pointHurt, "Hurt"); 						// Trigger point_hurt.
	AcceptEntityInput(pointHurt, "Kill"); 						// Kill point_hurt.
	DispatchKeyValue(iAttacker, "targetname",	"illbegood");	// Clear target's tag
}
