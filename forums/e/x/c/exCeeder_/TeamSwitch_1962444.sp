#include <sourcemod>
#include <morecolors>

#pragma semicolon 1

#define CS_TEAM_SPEC 1
#define CS_TEAM_T 2 
#define CS_TEAM_CT 3


public Plugin:myinfo = 
{
	name = "Team Switch",
	author = "eXceeder",
	description = "Switch the team of a player by a command",
	version = "1.0",
	url = "www.sourcemod.net"
}


public OnPluginStart()
{
	RegConsoleCmd("sm_t", Switch_T);
	RegConsoleCmd("sm_ct", Switch_CT);
	RegConsoleCmd("sm_spec", Switch_Spec);
}


public Action:Switch_T(client, args)
{	
	if(IsClientValid(client))
	{
		new team = GetClientTeam(client);
		
		if(team != CS_TEAM_T)
		{
			ChangeClientTeam(client, CS_TEAM_T);
		}
	}
	
	return Plugin_Handled;
}


public Action:Switch_CT(client, args)
{
	if(IsClientValid(client))
	{
		new team = GetClientTeam(client);
		
		if(team != CS_TEAM_CT)
		{
			ChangeClientTeam(client, CS_TEAM_CT);
		}
	}
	
	return Plugin_Handled;
}


public Action:Switch_Spec(client, args)
{	
	if(IsClientValid(client))
	{
		new team = GetClientTeam(client);
		
		if(team != CS_TEAM_SPEC)
		{
			ChangeClientTeam(client, CS_TEAM_SPEC);
			
			CPrintToChat(client, "{DARKGREEN}You are now in {AZURE}Spectator");
		}
	}
	
	return Plugin_Handled;
}


// --------------------------------- STOCKS --------------------------------- //


stock bool:IsClientValid(i)
{
	if(i > 0 && i <= MaxClients && IsClientInGame(i))
	{
		return true;
	}
	
	return false;
}