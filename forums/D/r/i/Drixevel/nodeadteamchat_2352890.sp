#pragma semicolon 1

#include <sourcemod>

public Plugin myinfo = 
{
	name = "No Dead Team Chat",
	author = "Keith Warren (Drixevel)",
	description = "Stops players from typing in team chat while dead to prevent ghosting.",
	version = "1.0.0",
	url = "http://www.drixevel.com/"
};

public void OnPluginStart()
{
	AddCommandListener(OnTeamChat, "say_team");
}

public Action OnTeamChat(int client, const char[] command, int args)
{
	if (!IsPlayerAlive(client))
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}