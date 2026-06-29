#include <sourcemod>
#define TEAM_UNASSIGNED 0

ConVar	RestrictedTeam,
		AutoTeamRestrict;

public Plugin myinfo =
{
	name = "Simple Team Restriction",
	author = "Xines",
	description = "Sets a team to be restricted.",
	version = "1.4",
	url = ""
};

public void OnPluginStart()
{
	AddCommandListener(TeamJoin, "jointeam");
	RestrictedTeam = CreateConVar("sm_simple_team_restriction", "0", "Sets Team to Restrict, (1 = SPEC), (2 = T), (3 = CT), (0 = OFF)", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	AutoTeamRestrict = CreateConVar("sm_simple_autoteam_restriction", "0", "Enable/Disable Auto Team Join Function, (1 = ON), (0 = OFF)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
}

public Action TeamJoin(int client, const char[] command, int argc)
{
	if(!IsValidClient(client)) return Plugin_Handled;
	
	char teamarg[2];
	GetCmdArg(1, teamarg, sizeof(teamarg));
	int myteam = StringToInt(teamarg);
	if (myteam == TEAM_UNASSIGNED && AutoTeamRestrict.IntValue == 1)
	{
		PrintToChat(client, "[SM] Auto team join is restricted!");
		return Plugin_Handled;
	}
	else if (myteam == RestrictedTeam.IntValue && RestrictedTeam.IntValue != 0)
	{
		PrintToChat(client, "[SM] Team is restricted!");
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

/** Stocks **/
stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}