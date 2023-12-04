#include <sourcemod>
#include <cstrike>
#include <sdktools_functions>

public Action CS_OnTerminateRound(float &flDelay, CSRoundEndReason &reason)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_T && IsPlayerAlive(i))
		{
			ForcePlayerSuicide(i);
		}
	}

	return Plugin_Continue;
}