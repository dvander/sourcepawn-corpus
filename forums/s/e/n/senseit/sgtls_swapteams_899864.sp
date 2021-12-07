#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.01"

public Plugin:myinfo = {
	name = "SGTLS Swapteams",
	author = "Sense",
	description = "Swap teams at round end.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart() {
	LogMessage("[SGTLS Swapteam] - Loaded");
	HookEvent("sgtls_round_win", event_RoundEnd);
}

public event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	LogMessage("[SGTLS Swapteam] Swapping teams");
	new maxclients = GetMaxClients();
	for(new i=1; i <= maxclients; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) != 0 && GetClientTeam(i) != 1) {
			if (GetClientTeam(i) == 2) {
				ChangeClientTeam(i, 3);
			} else {
				ChangeClientTeam(i, 2);
			}
		}
	}
}