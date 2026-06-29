#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION "1.0.2"
#define BASE_MESSAGE " has been permanently banned from official CS:GO servers."

public Plugin myinfo = {
	name        = "FakeVAC",
	author      = "Brrdy",
	description = "Fake VAC Ban",
	version     = PLUGIN_VERSION,
	url         = "https://forums.alliedmods.net/showthread.php?t=259350"
};


public void OnPluginStart()
{
	CreateConVar("fv_version", PLUGIN_VERSION, "Fake vac ban version", FCVAR_CHEAT, true, StringToFloat(PLUGIN_VERSION), true, StringToFloat(PLUGIN_VERSION));
	RegAdminCmd("fv_kick", Command_FVKICK, ADMFLAG_GENERIC);
	RegAdminCmd("fv_none", Command_FVNONE, ADMFLAG_GENERIC);
}

stock void DoCommand(const char target_name[MAX_NAME_LENGTH], const int target_list[MAX_TARGET_LENGTH], int target_count, bool tn_is_ml, bool kick)
{
	if (tn_is_ml)
		PrintToChatAll("\x07%t%s", target_name, BASE_MESSAGE);
	for (int i = 0; i < target_count; i++)
	{
		if (!IsClientInGame(target_list[i]))
			continue;
		if (kick)
			KickClient(target_list[i], "Your account is currently untrusted.");
		if (!tn_is_ml)
			PrintToChatAll("%N%s", target_list[i], BASE_MESSAGE);
	}
}

public Action Command_FVNONE(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: fv_none <Player>");
		return Plugin_Handled;
	}
	//Create strings
	char buffer[64], target_name[MAX_NAME_LENGTH];
	int target_list[MAX_TARGET_LENGTH];
	int target_count;
	bool tn_is_ml;
	//Get target
	GetCmdArg(1, buffer, sizeof(buffer));
	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAX_TARGET_LENGTH,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	DoCommand(target_name, target_list, target_count, tn_is_ml, false);
	return Plugin_Handled;
}

public Action Command_FVKICK(int client, int args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "Usage: fv_kick <Player>");
		return Plugin_Handled;
	}
	//Create strings
	char buffer[64], target_name[MAX_NAME_LENGTH];
	int target_list[MAX_TARGET_LENGTH];
	int target_count;
	bool tn_is_ml;
	//Get target
	GetCmdArg(1, buffer, sizeof(buffer));
	//Process
	if ((target_count = ProcessTargetString(
			buffer,
			client,
			target_list,
			MAX_TARGET_LENGTH,
			COMMAND_FILTER_ALIVE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	DoCommand(target_name, target_list, target_count, tn_is_ml, true);
	return Plugin_Handled;
}