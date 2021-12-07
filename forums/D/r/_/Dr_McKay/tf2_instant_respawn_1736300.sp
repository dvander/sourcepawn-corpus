#pragma semicolon 1

#include <sourcemod>
#include <tf2>

public Plugin:myinfo = {
	name        = "[TF2] Instant Respawn",
	author      = "Dr. McKay",
	description = "Instant respawn for TF2",
	version     = "1.0.0",
	url         = "http://www.doctormckay.com"
};

public OnPluginStart() {
	new Handle:disableCvar = FindConVar("mp_disable_respawn_times");
	HookEvent("player_death", Event_PlayerDeath);
	SetConVarBool(disableCvar, true);
	HookConVarChange(disableCvar, Callback_CvarChanged);
}

public Callback_CvarChanged(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if(!GetConVarBool(convar)) {
		SetConVarBool(convar, true);
	}
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) {
	CreateTimer(0.0, Timer_RespawnPlayer, GetClientOfUserId(GetEventInt(event, "userid")));
}

public Action:Timer_RespawnPlayer(Handle:timer, any:client) {
	if(!IsPlayerAlive(client)) {
		TF2_RespawnPlayer(client);
	}
}