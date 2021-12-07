#include <sourcemod>
#include <cstrike>
#include <sdktools_functions>
#pragma semicolon 1;

public Plugin:myinfo =
{
	name = "Team Swapper",
	author = "Neuro Toxin",
	description = "If CT's win a round, all players are team switched.",
	version = "1.0",
	url = "https://forums.alliedmods.net/showthread.php?t=254108"
};

public OnPluginStart()
{
	HookEvents();
}

stock HookEvents()
{
	HookEvent("round_end", OnRoundEnd);
}

public OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new winner = GetEventInt(event, "winner");

	if (winner == CS_TEAM_CT)
		SwitchPlayerTeams();
}

stock SwitchPlayerTeams()
{
	for (new client = 1; client <= MaxClients; client++)
	{
		if (!IsClientInGame(client))
			continue;

		if (GetClientTeam(client) == CS_TEAM_CT)
			CS_SwitchTeam(client, CS_TEAM_T);
		else if (GetClientTeam(client) == CS_TEAM_T)
			CS_SwitchTeam(client, CS_TEAM_CT);
	}
			
	new ctscore = CS_GetTeamScore(CS_TEAM_CT);
	CS_SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_T));
	CS_SetTeamScore(CS_TEAM_T, ctscore);
			
	SetTeamScore(CS_TEAM_CT, CS_GetTeamScore(CS_TEAM_CT));
	SetTeamScore(CS_TEAM_T, CS_GetTeamScore(CS_TEAM_T));
}