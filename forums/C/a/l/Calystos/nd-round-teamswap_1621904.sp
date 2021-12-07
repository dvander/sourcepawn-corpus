#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.04"

#define SPEC    1
#define TEAM1   2
#define TEAM2   3

public Plugin:myinfo = {
	name = "[ND] Swapteams",
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
	PrintToChatAll("\x01\x04[SM]\x01 Round Ended: Swapping Teams");
	LogMessage("[ND Swapteam] Round Ended Swapping teams");

	// Check against team balancer plugin
	if (FindConVar("sm_nd_balancer_enable")) { SetConVarInt(FindConVar("sm_nd_balancer_enable"), 0, false, false); }

	// Swap the teams
	for (new i=1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && !IsFakeClient(i)) switch (GetClientTeam(i))
		{
			case TEAM1 : ChangeClientTeam(i, TEAM2);
			case TEAM2 : ChangeClientTeam(i, TEAM1);
		}
	}

	// Swap the scores
	new ts = GetTeamScore(TEAM1);
	SetTeamScore(TEAM1,GetTeamScore(TEAM2));
	SetTeamScore(TEAM2,ts);

	// Check against team balancer plugin
	if (FindConVar("sm_nd_balancer_enable")) { SetConVarInt(FindConVar("sm_nd_balancer_enable"), 1, false, false); }

	LogMessage("[ND Swapteam] Round Ended Swapped teams");
}
