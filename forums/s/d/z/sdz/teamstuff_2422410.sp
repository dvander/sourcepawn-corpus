#include <sourcemod>
#include <cstrike>
#include <sdktools>

public OnPluginStart()
{
	RegAdminCmd("sm_spectate", command_switchSpec, ADMFLAG_CUSTOM6, "Switch to specatate");
	RegAdminCmd("sm_spec", command_switchSpec, ADMFLAG_CUSTOM6, "Switch to specatate");
	AddCommandListener(altJoin, "jointeam");
}

public Action:command_switchSpec(client, args)
{
	switch(GetClientTeam(client))
	{
		case CS_TEAM_CT, CS_TEAM_T:
		{
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
			return Plugin_Handled;
		}

		case CS_TEAM_SPECTATOR:
		{
			ChangeClientTeam(client, CS_TEAM_T);
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
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
	else 
	{
		// ignore switches between T/CT team
		if((teamLeave == CS_TEAM_CT && teamJoin == CS_TEAM_T)
		|| (teamLeave == CS_TEAM_T  && teamJoin == CS_TEAM_CT))
		{
			return Plugin_Handled;
		}
	}
	return Plugin_Handled;
}