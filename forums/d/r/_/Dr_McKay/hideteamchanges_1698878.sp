#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
	name        = "Hide Team Changes",
	author      = "Dr. McKay",
	description = "Hides team change notifications",
	version     = "1.0.0",
	url         = "http://www.doctormckay.com"
};

public OnPluginStart() {
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) {
	return Plugin_Handled;
}