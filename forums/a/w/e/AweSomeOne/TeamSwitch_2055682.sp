#include <sourcemod>

#pragma semicolon 1

#define TEAM_SPEC 1
#define TEAM_RED 2 
#define TEAM_BLUE 3


public Plugin:myinfo = 
{
	name = "Team Switch",
	author = "AweSomeOne",
	description = "Switch the team of player by command",
	version = "1.0",
	url = "www.sourcemod.net"
}


public OnPluginStart()
{
	RegConsoleCmd("sm_red", Switch_RED);
	RegConsoleCmd("sm_blue", Switch_BLUE);
	RegConsoleCmd("sm_spec", Switch_Spec);
}


public Action:Switch_RED(client, args)
{	
	if(IsClientValid(client))
	{
		new team = GetClientTeam(client);
		
		if(team != TEAM_RED)
		{
			ChangeClientTeam(client, TEAM_RED);
		}
	}
	
	return Plugin_Handled;
}


public Action:Switch_BLUE(client, args)
{
	if(IsClientValid(client))
	{
		new team = GetClientTeam(client);
		
		if(team != TEAM_BLUE)
		{
			ChangeClientTeam(client, TEAM_BLUE);
		}
	}
	
	return Plugin_Handled;
}


public Action:Switch_Spec(client, args)
{	
	if(IsClientValid(client))
	{
		new team = GetClientTeam(client);
		
		if(team != TEAM_SPEC)
		{
			ChangeClientTeam(client, TEAM_SPEC);
		}
	}
	
	return Plugin_Handled;
}

stock bool:IsClientValid(i)
{
	if(i > 0 && i <= MaxClients && IsClientInGame(i))
	{
		return true;
	}
	
	return false;
}