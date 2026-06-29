/*
 * Hidden:SourceMod - Physics vs Pistols
 *
 * Description:
 *   Enabled Physics Vs Pistols mode where primary weapons are removed and the knife does not damage.
 *
 * Cvars:
 *  hsm_pvp 0/1: enable or disable Physics vs Pistols mode.
 *
 * Changelog:
 *  v2.0.1
 *   Added a console variable to set the amount of damage each knife hit actually does.
 *  v2.0
 *   Stripped most of the stuff that wasn't working.
 *   Now purely physics versus pistols. No options etc.
 *  v1.0.0
 *   Initial release.
 *
 * Known Issues:
 *  v2.0
 *   This version is actually just a tweaked version of the PigShove plugin. While I did stripe out the underlaying shove mechanisms, the act of Pigsticking someone does impart some momentum on the target so if you run both plugins, your pig-sticks may have some interesting side-effects. If you remove PigShove then you lose the vertical boosting that plugin adds to shoves.
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
 */

#define PLUGIN_VERSION		"2.0.1"

#include <sdktools>

#define HDN_TEAM_IRIS			2
#define HDN_TEAM_HIDDEN			3

new Handle:cvarPVP		= INVALID_HANDLE;
new Handle:cvarDMG		= INVALID_HANDLE;

public Plugin:myinfo = {
	name		= "H:SM - PvP",
	author		= "Paegus",
	description	= "Sets Physics vs Pistols mode",
	version		= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net/showthread.php?p=699595"
}

public OnPluginStart() {

	CreateConVar(
		"hsm_pv_version",
		PLUGIN_VERSION,
		"H:SM - Physics Vs Pistols version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);

	cvarPVP = CreateConVar(
		"hsm_pvp",
		"0",
		"Physics vs Pistols mode. 0: Disable, 1: Enable",
		_,
		true, 0.0,
		true, 1.0
	);
	
	cvarDMG = CreateConVar(
		"hsm_pvp_knifedmg",
		"0",
		"How much damage the knife does while PVP mode is enabled.",
		_,
		true, 0.0,
		true, 37.0
	);

	HookEvent("player_hurt", event_PlayerHurt, EventHookMode_Pre);
	HookEvent("game_round_start", event_RoundStart);
	HookEvent("game_round_end", event_RoundEnd);
}

public event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarInt(cvarPVP) == 1) {	// PVP mode enabled
		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (
				IsClientInGame(iClient) &&
				IsPlayerAlive(iClient) &&
				GetClientTeam(iClient) == HDN_TEAM_IRIS
			) {
				ClientCommand(iClient, "changeclass 1");	// Force to supply mode to keep the ammo coming.
			}
		}
	}
}

public event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarInt(cvarPVP) == 1) {	// PVP mode enabled
		for (new iClient = 1; iClient <= MaxClients; iClient++) {
			if (
				IsClientInGame(iClient) &&
				IsPlayerAlive(iClient)
			) {
				decl iWeapon;
				if (GetClientTeam(iClient) == HDN_TEAM_IRIS) {
					// Strip primary weapons
					iWeapon = GetPlayerWeaponSlot(iClient,0);
					RemovePlayerItem(iClient, iWeapon);
					RemoveEdict(iWeapon);
					
					ClientCommand(iClient, "slot2");
					
					
					decl secAmmoOffset;
					if (GetEntProp(iClient, Prop_Send, "m_iSecondary") == 0) {
						secAmmoOffset = FindSendPropOffs("CSDKPlayer","m_iAmmo") + 4 * 4
					} else {
						secAmmoOffset = FindSendPropOffs("CSDKPlayer","m_iAmmo") + 4 * 5
					}
					SetEntData(iClient, secAmmoOffset, 6, 4, true)
					
					
				} else {
					// Strip any grenades.
					iWeapon = GetPlayerWeaponSlot(iClient,1);
					//LogToGame("No nades: %d", iWeapon);
					if (iWeapon > 0) {
						RemovePlayerItem(iClient, iWeapon);
						RemoveEdict(iWeapon);
					}
				}
			}
		}
	}
}

public Action:event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new iAttacker = GetClientOfUserId(GetEventInt(event, "attacker")); // Get attacker.
	new iVictim = GetClientOfUserId(GetEventInt(event, "userid")); // Get victim.
	
	if (
		GetConVarInt(cvarPVP) != 1 ||
		!iAttacker ||
		GetClientTeam(iVictim) == HDN_TEAM_HIDDEN ||
		GetClientTeam(iAttacker) != HDN_TEAM_HIDDEN
	) {
		return Plugin_Continue;
	}
	
	new iDamage = GetEventInt(event, "damage");
	if (
		iDamage == 925 ||
		iDamage == 37
	) {
		new iDamageNew = GetConVarInt(cvarDMG);
		SetEventInt(event, "damage", iDamageNew);
		SetEntData(iVictim, FindDataMapOffs(iVictim, "m_iHealth"), GetClientHealth(iVictim) + iDamage - iDamageNew,	4, true);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}
