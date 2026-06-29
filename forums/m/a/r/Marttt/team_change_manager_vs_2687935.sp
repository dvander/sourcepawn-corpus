#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2.2"

#define TEAM_UNASSIGNED 0
#define TEAM_SPECTATE 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

public Plugin:myinfo =
{
	name = "Team Change Manager",
	author = "Sheepdude",
	description = "Provides Management To Team Changes.",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

public OnPluginStart() 
{
	AddCommandListener(JoinTeamCmd, "jointeam");
	
	//CreateConVar("team_change_manager_version", PLUGIN_VERSION, "Team Change Manager Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_SPONLY);
	
	//AutoExecConfig(true, "team_change_manager");
}

int GetTeam(const char[] team)
{
	if (StrEqual(team, "survivor", false) || StrEqual(team, "2", false))
		return TEAM_SURVIVORS;
	if (StrEqual(team, "infected", false) || StrEqual(team, "3", false))
		return TEAM_INFECTED;
	
	//int toteam = StringToInt(team);
	//
	//if (TEAM_UNASSIGNED <= toteam <= TEAM_INFECTED)
	//	return toteam;
	
	//return TEAM_UNASSIGNED;
	return TEAM_SPECTATE;
}

public Action:JoinTeamCmd(client, const String:command[], argc)
{ 
	if (!IsValidClient(client) || argc < 1)
		return Plugin_Handled;
	
	char arg[9];
	GetCmdArg(1, arg, sizeof(arg));
	int toteam = GetTeam(arg);
	
	if (toteam == TEAM_UNASSIGNED)
		return Plugin_Handled;
	
	switch (toteam)
	{
		case TEAM_SURVIVORS:
		{
			if (GetClientTeam(client) == TEAM_SURVIVORS)
			{
				PrintHintText(client, "[JBTP] Already In Survivors Team!");
				return Plugin_Handled;
			}
			else
			{
				if (GetTotalPlayers(TEAM_SURVIVORS) > GetTotalPlayers(TEAM_INFECTED))
				{
					PrintHintText(client, "[JBTP] That's Unfair!");
				}
				else
				{
					int aBot = FindAvailableBot();
					if (aBot != -1)
					{
						int flags = GetCommandFlags("sb_takecontrol");
						SetCommandFlags("sb_takecontrol", flags & ~FCVAR_CHEAT);
						FakeClientCommand(client, "sb_takecontrol");
						SetCommandFlags("sb_takecontrol", flags);
					}
					
					PrintToChatAll("\x03[JBTP] \x04%N\x01 Joined \x05Survivors Team\x01!", client);
				}
			}
		}
		case TEAM_INFECTED:
		{
			if (GetClientTeam(client) == TEAM_INFECTED)
			{
				PrintHintText(client, "[JBTP] Already In Infected Team!");
			}
			else
			{
				if (GetTotalPlayers(TEAM_INFECTED) > GetTotalPlayers(TEAM_SURVIVORS))
				{
					PrintHintText(client, "[JBTP] That's Unfair!");
				}
				else
				{
					ChangeClientTeam(client, TEAM_INFECTED);
					PrintToChatAll("\x03[JBTP] \x04%N\x01 Joined \x05Infected Team\x01!", client);
				}
			}
		}
		case TEAM_SPECTATE:
		{
			if (GetClientTeam(client) == TEAM_SPECTATE)
			{
				PrintHintText(client, "[JBTP] Already In Spectators Team!");
			}
			else
			{
				ChangeClientTeam(client, TEAM_SPECTATE);
			}
		}
	}
	
	return Plugin_Handled;
}

GetTotalPlayers(selectedTeam)
{
	int total = 0;
	for (int i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == selectedTeam && !IsFakeClient(i))
		{
			total++;
		}
	}
	if (total < 1)
	{
		return 0;
	}
	
	return total;
}

stock IsValidClient(client)
{
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && !IsFakeClient(client))
	{
		return true;
	}
	return false;
}

stock FindAvailableBot()
{
	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && GetClientTeam(client) == TEAM_SURVIVORS && IsFakeClient(client))
		{
			return client;
		}
	}
	return -1;
}

