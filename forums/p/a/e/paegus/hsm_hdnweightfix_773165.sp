/*
 * Hidden:SourceMod - Hidden weighting exploit fix
 *
 * Description:
 *  Zeros the hidden's weight points when the round ends to prevent players from switching teams and retaining their often ludicrously high values.
 *
 * Changelog:
 *  v1.0.2
 *   Removed all external file dependencies
 *  v1.0.1
 *   I can't seem to make up my mind how idiotic to be.
 *  v1.0.0
 *   Initial Release
 *
 * Contact:
 *  Paegus: paegus@gmail.com
 *  SourceMod: http://www.sourcemod.net > Community > Forums > SourceMod
 *  Hidden:Source: http://www.hidden-source.com > Forums > Server Admins
 */

#define PLUGIN_VERSION		"1.0.2"
#pragma semicolon 1

#define HDN_TEAM_IRIS 2


public Plugin:myinfo = {
	name		= "H:SM - Hidden Weight Fix",
	author		= "Paegus",
	description	= "Prevents hidden's weighting exploit by zeroing his weight points at round end.",
	version		= PLUGIN_VERSION,
	url			= "http://forum.hidden-source.com/forumdisplay.php?f=13"
}

public OnPluginStart() {
	CreateConVar(
		"hsm_hwf_version",
		PLUGIN_VERSION,
		"H:SM - Hidden weight exploit fix version",
		FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY
	);
	
	HookEvent("game_round_end", event_RoundEnd, EventHookMode_Pre);
}

public event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {	// In-game.
			if (GetClientTeam(i) != HDN_TEAM_IRIS) {	// not IRIS (Spectator or Hidden)
				SetEntProp(i, Prop_Send, "m_iWeighting", 0); // Zero out hidden's weight points. I hope you're not play OVR ^.^
			}
		}
	}
}
