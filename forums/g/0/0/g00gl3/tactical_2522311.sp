#pragma semicolon 1

#include <sourcemod>
#include <cstrike>

public Plugin:myinfo =
{
	name = "Team Timeout",
	author = "g00gl3",
	description = "Set a team timeout",
	version = "1.0.0"
};

public OnPluginStart()
{
	RegConsoleCmd("sm_tactical", Command_TimeOut, "Start a Team timeout"); 
}

public Action:Command_TimeOut(client, args)
{
	if(GetClientTeam(client) == CS_TEAM_T)
	{
		ServerCommand("timeout_terrorist_start");
		PrintToChatAll(" \x02[TimeOut] \x04%N \x03start the timeout for (T) Team", client);
		
		return Plugin_Handled;
	}
	
	else if(GetClientTeam(client) == CS_TEAM_CT)
	{
		ServerCommand("timeout_ct_start");
		PrintToChatAll(" \x02[TimeOut] \x04%N \x03start the timeout for (CT) Team", client);
		
		return Plugin_Handled;
	}

	return Plugin_Continue;
}
