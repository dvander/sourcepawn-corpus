#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "[TF2] No Ready Up", 
	author = "Drixevel", 
	description = "Adds an admin command which forces a team to have their ready status disabled.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_unready", Command_Unready, ADMFLAG_SLAY, "Force a team to unready.");
	RegAdminCmd("sm_noready", Command_Unready, ADMFLAG_SLAY, "Force a team to unready.");
}

public Action Command_Unready(int client, int args)
{
	if (args == 0)
	{
		char sCommand[32];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		ReplyToCommand(client, "[SM] Usage: %s <team>", sCommand);
		return Plugin_Handled;
	}

	char sTeam[32];
	GetCmdArg(1, sTeam, sizeof(sTeam));
	int team = StringToInt(sTeam);

	if (!IsStringNumeric(sTeam))
		team = FindTeamByName(sTeam);

	if (team == -2)
	{
		ReplyToCommand(client, "More than one team found with the name '%s'.", sTeam);
		return Plugin_Handled;
	}

	if (team < 1)
	{
		ReplyToCommand(client, "No team found with the name '%s'.", sTeam);
		return Plugin_Handled;
	}
	
	GameRules_SetProp("m_bTeamReady", 0, _ , team, true);

	char sName[64];
	GetTeamName(team, sName, sizeof(sName));

	ShowActivity2(client, "[SM] ", "%N has disabled the ready state for team %s.", client, sName);
	LogAction(client, -1, "%L has disabled the ready state for team %s.", client, sName);

	return Plugin_Handled;
}

bool IsStringNumeric(const char[] str)
{
	int x = 0;
	int dotsFound = 0;
	int numbersFound = 0;

	if (str[x] == '+' || str[x] == '-')
		x++;

	while (str[x] != '\0')
	{
		if (IsCharNumeric(str[x]))
			numbersFound++;
		else if (str[x] == '.')
		{
			dotsFound++;

			if (dotsFound > 1)
				return false;
		}
		else
			return false;

		x++;
	}

	return numbersFound > 0;
}