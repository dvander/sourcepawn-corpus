#pragma semicolon 1

#include <sourcemod>
#include <colors>


public Plugin:myinfo = {
	name        = "FakeVAC",
	author      = "Brrdy",
	description = "Fake VAC Ban",
	version     = "1.0.2",
	url         = "https://forums.alliedmods.net/showthread.php?t=259350"
};


public OnPluginStart()
{
	RegConsoleCmd("fv_version", Command_FVVERSION);
	RegAdminCmd("fv_kick", Command_FVKICK, ADMFLAG_GENERIC);
	RegAdminCmd("fv_none", Command_FVNONE, ADMFLAG_GENERIC);
}
public Action:Command_FVVERSION(client, args)
{
	PrintToConsole(client, "Version 1.0.2 ");
}
public Action:Command_FVNONE(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: fv_none <Player>");
		return Plugin_Handled;
	}
	
	//Create strings
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
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
		PrintToChatAll("\x07%N has been permanently banned from official CS:GO servers.", target_list[i]);
	}
	
	return Plugin_Handled;
}
public Action:Command_FVKICK(client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: fv_ban <Player>");
		return Plugin_Handled;
	}
	
	//Create strings
	decl String:buffer[64];
	decl String:target_name[MAX_NAME_LENGTH];
	decl target_list[MAXPLAYERS];
	decl target_count;
	decl bool:tn_is_ml;
	
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
		PrintToChatAll("\x07%N has been permanently banned from official CS:GO servers.", target_list[i]);
		KickClient(target_list[i], "Your account is 
currently untrusted.");
	}
	
	return Plugin_Handled;
}