#pragma semicolon 1

#include <sourcemod>

#define RED_TEAM 2
#define BLUE_TEAM 3
#define SPEC_TEAM 1

public Plugin:myinfo = 
{
	name = "Team Switch",
	author = "linux_lover",
	description = "Commands to switch a player's team.",
	version = "0.1",
	url = "http://sourcemod.net"
}

public OnPluginStart()
{
	RegAdminCmd("sm_team", Command_ChangeTeam, ADMFLAG_KICK);
}

public Action:Command_ChangeTeam(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_team <#userid|name> <@red|@blue|@spec>");
		return Plugin_Handled;
	}

	decl String:text[256], String:arg[64];
	GetCmdArg(1, text, sizeof(text));
	GetCmdArg(2, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			text,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_CONNECTED,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		if (strcmp(arg, "\0") == 0)
		{
			if(GetClientTeam(target_list[i])==RED_TEAM)
				ChangeTeam(target_list[i], BLUE_TEAM, client);
			else if(GetClientTeam(target_list[i])==BLUE_TEAM)
				ChangeTeam(target_list[i], RED_TEAM, client);
		}else{
			if(StrEqual(arg, "@red"))
				ChangeTeam(target_list[i], RED_TEAM, client);
			else if(StrEqual(arg, "@blue"))
				ChangeTeam(target_list[i], BLUE_TEAM, client);
			else if(StrEqual(arg, "@spec"))
				ChangeTeam(target_list[i], SPEC_TEAM, client);
		}
	}

	return Plugin_Handled;
}

ChangeTeam(client, teamIndex, caller)
{
	ChangeClientTeam(client, teamIndex);

	new String:team[10];
	
	switch(teamIndex)
	{
		case RED_TEAM:
			team = "RED";
		case BLUE_TEAM:
			team = "BLUE";
		case SPEC_TEAM:
			team = "SPECTATE";
	}
	
	new String:message[192];
	Format(message, sizeof(message), "\x03[SM]\x01%N was switched to the %s team.", client, team);
	
	ReplyToCommand(caller, message);
	
	return;
}