/*
 * Hidden:SourceMod - Anti-Blur
 *
 * Description:
 *   Drastically reduces blurry vision on IRIS when friendly-fired with 303.
 *
 * Changelog:
 *  v1.0.0
 *   Initial release.
 *
 * Known Issues:
 *  v1.0.0
 *   There is still an overlay texture that appears slightly blurry. Can't remove that.
 * 
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
 * 
 */

#define PLUGIN_VERSION		"1.0.0"

#define HDN_TEAM_IRIS	2
#define HDN_TEAM_HIDDEN	3

public Plugin:myinfo = {
	name		= "H:SM - Anti-Blur",
	author		= "Paegus",
	description	= "Drastically reduces blurry vision on IRIS when friendly-fired with 303.",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/showthread.php?9853"
}

public OnPluginStart() {
	CreateConVar(
		"hsm_antiblur_version",
		PLUGIN_VERSION,
		"H:SM - Anti-Blur Version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	)
	
	HookEventEx("player_hurt", event_PlayerHurt)
}

// Check for 303 or grenade damage.
public Action:event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	
	if (
		IsIRIS(client) &&
		IsIRIS(GetClientOfUserId(GetEventInt(event, "attacker"))) &&
		GetEventFloat(event, "damage") == 3.000000
	) {
		// 303 Hit
		CreateTimer(0.1, tmr_UnBlur, client)	// Why the delay mang?
	}
}

public Action:tmr_UnBlur(Handle:timer, any:client) {
	SetEntPropFloat(client, Prop_Send, "m_flBlur", 0.0)
}

// Return true if valid player.
stock bool:IsPlayer(const any:client) {
	return(
		client &&
		IsClientInGame(client) &&
		IsPlayerAlive(client)
	)
}

// Returns true if client is IRIS player.
stock bool:IsIRIS(const any:client) {
	return (
		IsPlayer(client) &&
		GetClientTeam(client) == HDN_TEAM_IRIS
	)
}
