#include <sourcemod>
#include <cstrike>
#include <sdktools>

public OnPluginStart()
{
	AddCommandListener(altJoin, "jointeam");
}

public Action:altJoin(Client, const String:command[], argc)
{
	if(!IsClientInGame(Client) || argc < 1) 
	{
		return Plugin_Handled;
	}
 
	decl String:arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	new teamJoin = StringToInt(arg);
	new teamLeave = GetClientTeam(Client);
 
	if(teamLeave == teamJoin || IsFakeClient(Client))
	{
		return Plugin_Continue;
	} 
	
	if(teamLeave == CS_TEAM_CT && teamJoin == CS_TEAM_T) 
	{
		ChangeClientTeam(Client, CS_TEAM_T);
		return Plugin_Handled;
	}
	
	return Plugin_Handled;
}