#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_NAME "FakeVAC"
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name        = PLUGIN_NAME,
	author      = "Brrdy",
	description = "Fake VAC Ban",
	version     = PLUGIN_VERSION,
	url         = ""
};

public OnPluginStart()
{
	CreateConVar("fakevac_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	RegAdminCmd("sm_fakevac", SwagMode, ADMFLAG_GENERIC);
}

public Action:SwagMode(client, args)
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
		PrintToChatAll("\x07%N has been permanently banned from official CS:GO servers.", target_list[i]);
		KickClient(target_list[i], "You have been banned from all VAC secure servers.");
	}
	
	return Plugin_Handled;
}
