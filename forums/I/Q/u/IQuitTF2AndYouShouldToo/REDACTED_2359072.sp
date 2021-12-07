#include <sourcemod>
#include <morecolors>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "[REDACTED]",
	author = "[REDACTED]",
	description = "[REDACTED]",
	version = "[REDACTED]"
}

public OnPluginStart()
{
	RegAdminCmd("sm_fakevac", Command_FakeVAC, ADMFLAG_ROOT);
}

public Action:Command_FakeVAC(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: sm_fakevac <Player>");
		return Plugin_Handled;
	}
	
	//Create strings
	new String:buffer[64];
	new String:target_name[MAX_NAME_LENGTH];
	new target_list[MAXPLAYERS];
	new target_count;
	new bool:tn_is_ml;
	
	//Get target
	GetCmdArg(1, buffer, sizeof(buffer));
	
	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i ++)
	{
		CPrintToChatAll("{fullred}%N has been permanently banned from official TF2 servers.", target_list[i]);
		KickClient(target_list[i], "You have been banned from all VAC secure servers");
	}
	
	return Plugin_Handled;
}