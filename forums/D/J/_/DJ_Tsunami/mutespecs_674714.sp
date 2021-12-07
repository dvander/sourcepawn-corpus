#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.0"

public Plugin:myinfo = {
	name        = "Mute Spectators",
	author      = "Tsunami",
	description = "Mutes spectators so they can't talk to alive players.",
	version     = PL_VERSION,
	url         = "http://www.tsunami-productions.nl"
}

new Handle:g_hEnabled;

public OnPluginStart() {
	CreateConVar("sm_mutespecs_version", PL_VERSION, "Mutes spectators so they can't talk to alive players.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled  = CreateConVar("sm_mutespecs_enabled", "1", "Enable/disable muting spectators so they can't talk to alive players.");
	
	HookEvent("player_team", Event_PlayerTeam);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	if (GetConVarBool(g_hEnabled))
		SetClientListeningFlags(GetClientOfUserId(GetEventInt(event, "userid")), GetEventInt(event, "team") == 1 ? VOICE_MUTED : VOICE_NORMAL);
}