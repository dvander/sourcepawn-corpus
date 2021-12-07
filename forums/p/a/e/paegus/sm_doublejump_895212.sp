/*
 * Double Jump
 *
 * Description:
 *  Allows players to double-jump
 *  Original idea: NcB_Sav
 *
 * Convars:
 *  sm_doublejump_enabled [bool] : Enables or disable double-jumping. Default: 1
 *  sm_doublejump_boost [amount] : Amount to boost the player. Default: 250
 *  sm_doublejump_max [jumps]    : Maximum number of re-jumps while airborne. Default: 1
 *
 * Changelog:
 *  v1.0.1
 *   Minor code optimization.
 *  v1.0.0
 *   Initial release.
 *
 * Known issues:
 *  Doesn't register all mouse-wheel triggered +jumps
 *
 * Todo:
 *  Employ upcoming OnClientCommand function to remove excess OnGameFrame-age.
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net
 *  Hidden:Source: http://www.hidden-source.com
 *  NcB_Sav: http://forums.alliedmods.net/showthread.php?t=99228
 */
#define PLUGIN_VERSION		"1.0.1"

#include <sdktools>


public Plugin:myinfo = {
	name		= "Double Jump",
	author		= "Paegus",
	description	= "Allows double-jumping.",
	version		= PLUGIN_VERSION,
	url			= ""
}

new
	Handle:g_cvJumpBoost	= INVALID_HANDLE,
	Handle:g_cvJumpEnable	= INVALID_HANDLE,
	Handle:g_cvJumpMax		= INVALID_HANDLE,
	Float:g_flBoost			= 250.0,
	bool:g_bDoubleJump		= true,
	g_fLastButtons[MAXPLAYERS+1],
	g_fLastFlags[MAXPLAYERS+1],
	g_iJumps[MAXPLAYERS+1],
	g_iJumpMax
	
public OnPluginStart() {
	CreateConVar(
		"sm_doublejump_version", PLUGIN_VERSION,
		"Double Jump Version",
		FCVAR_PLUGIN|FCVAR_NOTIFY
	)
	
	g_cvJumpEnable = CreateConVar(
		"sm_doublejump_enabled", "1",
		"Enables double-jumping.",
		FCVAR_PLUGIN|FCVAR_NOTIFY
	)
	
	g_cvJumpBoost = CreateConVar(
		"sm_doublejump_boost", "250.0",
		"The amount of vertical boost to apply to double jumps.",
		FCVAR_PLUGIN|FCVAR_NOTIFY
	)
	
	g_cvJumpMax = CreateConVar(
		"sm_doublejump_max", "1",
		"The maximum number of re-jumps allowed while already jumping.",
		FCVAR_PLUGIN|FCVAR_NOTIFY
	)
	
	HookConVarChange(g_cvJumpBoost,		convar_ChangeBoost)
	HookConVarChange(g_cvJumpEnable,	convar_ChangeEnable)
	HookConVarChange(g_cvJumpMax,		convar_ChangeMax)
	
	g_bDoubleJump	= GetConVarBool(g_cvJumpEnable)
	g_flBoost		= GetConVarFloat(g_cvJumpBoost)
	g_iJumpMax		= GetConVarInt(g_cvJumpMax)
}

public convar_ChangeBoost(Handle:convar, const String:oldVal[], const String:newVal[]) {
	g_flBoost = StringToFloat(newVal)
}

public convar_ChangeEnable(Handle:convar, const String:oldVal[], const String:newVal[]) {
	if (StringToInt(newVal) >= 1) {
		g_bDoubleJump = true
	} else {
		g_bDoubleJump = false
	}
}

public convar_ChangeMax(Handle:convar, const String:oldVal[], const String:newVal[]) {
	g_iJumpMax = StringToInt(newVal)
}

public OnGameFrame() {
	if (g_bDoubleJump) {							// double jump active
		for (new i = 1; i <= MaxClients; i++) {		// cycle through players
			if (
				IsClientInGame(i) &&				// is in the game
				IsPlayerAlive(i)					// is alive
			) {
				DoubleJump(i)						// Check for double jumping
			}
		}
	}
}

stock DoubleJump(const any:client) {
	new
		fCurFlags	= GetEntityFlags(client),		// current flags
		fCurButtons	= GetClientButtons(client)		// current buttons
	
	if (g_fLastFlags[client] & FL_ONGROUND) {		// was grounded last frame
		if (
			!(fCurFlags & FL_ONGROUND) &&			// becomes airbirne this frame
			!(g_fLastButtons[client] & IN_JUMP) &&	// was not jumping last frame
			fCurButtons & IN_JUMP					// started jumping this frame
		) {
			OriginalJump(client)					// process jump from the ground
		}
	} else if (										// was airborne last frame
		fCurFlags & FL_ONGROUND						// becomes grounded this frame
	) {
		Landed(client)								// process landing on the ground
	} else if (										// remains airborne this frame
		!(g_fLastButtons[client] & IN_JUMP) &&		// was not jumping last frame
		fCurButtons & IN_JUMP						// started jumping this frame
	) {
		ReJump(client)								// process attempt to double-jump
	}
	
	g_fLastFlags[client]	= fCurFlags				// update flag state for next frame
	g_fLastButtons[client]	= fCurButtons			// update button state for next frame
}

stock OriginalJump(const any:client) {
	g_iJumps[client]++	// increment jump count
}

stock Landed(const any:client) {
	g_iJumps[client] = 0	// reset jumps count
}

stock ReJump(const any:client) {
	if ( 1 <= g_iJumps[client] <= g_iJumpMax) {						// has jumped at least once but hasn't exceeded max re-jumps
		g_iJumps[client]++											// increment jump count
		decl Float:vVel[3]
		GetEntPropVector(client, Prop_Data, "m_vecVelocity", vVel)	// get current speeds
		
		vVel[2] = g_flBoost
		TeleportEntity(client, NULL_VECTOR, NULL_VECTOR, vVel)		// boost player
	}
}

