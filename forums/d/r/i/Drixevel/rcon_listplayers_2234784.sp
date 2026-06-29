#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name = "[Any] Rcon List Players",
	author = "Keith Warren (Jack of Designs)",
	description = "List clients names and their teams in console.",
	version = "1.0.0",
	url = "http://www.drixevel.com/"
};

public OnPluginStart()
{
	RegServerCmd("sm_listplayers", ListPlayers, "List all players in the server and their team names.");
}

public Action:ListPlayers(args)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || IsFakeClient(i)) continue;

		PrintToServer("%i - %N", GetClientTeam(i), i);
	}
	return Plugin_Handled;
}
