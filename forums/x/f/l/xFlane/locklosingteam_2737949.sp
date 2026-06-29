#include <sourcemod>
#include <cstrike>

#pragma semicolon 1

#define PLUGIN_VERSION "1.00"

public Plugin:myinfo = {
	name = "Lock losing team",
	author = "xFlane",
	description = "Prevents switching team when on the losing team.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/xflane/"
};

public OnPluginStart() {
	AddCommandListener(Event_JoinTeam, "jointeam");	
}

public Action Event_JoinTeam(int client, const char[] command, int args) {
	int iLosingTeam = GetLosingTeam();

	if (iLosingTeam == -1) // Tie.
		return Plugin_Continue;

	if (GetClientTeam(client) != iLosingTeam)
		return Plugin_Continue;

	PrintToChat(client, "You cant switch teams when your team is losing!");
	return Plugin_Handled;
}

int GetLosingTeam() {
	int iCTScore = CS_GetTeamScore(CS_TEAM_CT);
	int iTScore = CS_GetTeamScore(CS_TEAM_T);

	if (iCTScore == iTScore)
		return -1;

	return iCTScore > iTScore ? CS_TEAM_T : CS_TEAM_CT;
}