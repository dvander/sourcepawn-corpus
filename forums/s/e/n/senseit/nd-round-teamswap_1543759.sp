#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.03"

public Plugin:myinfo = {
	name = "ND Swapteams",
	author = "Senseless",
	description = "Swap teams at round end.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart() {
	LogMessage("[ND Swapteam] - Loaded");
	HookEvent("round_win", event_RoundEnd, EventHookMode_PostNoCopy);
}

public event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	LogMessage("[ND Swapteam] Round Ended Swapping teams");
	SetConVarInt(FindConVar("sm_nd_balancer_enable"), 0, false, false);
	for(new i=1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i)) {
			new team = GetClientTeam(i);
			if (team == 2) {
				ChangeClientTeam(i, 3);
			}
			if (team == 3) {
				ChangeClientTeam(i, 2);
			}
		}
	}
	SetConVarInt(FindConVar("sm_nd_balancer_enable"), 1, false, false);
}


