#pragma semicolon 1

#define PLUGIN_AUTHOR "Lucas 'aIM' Maza"
#define PLUGIN_VERSION "v2.0"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "[TF2] Spec",
	author = PLUGIN_AUTHOR,
	description = "Sends certain players to spectator.",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	RegAdminCmd("sm_spec", CMD_Spec, ADMFLAG_GENERIC, "Sends a player or a group of players to spec.");
}

public Action CMD_Spec (int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_spec <name|#userid|@group>");
		return Plugin_Handled;
	}
	
	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MAXPLAYERS, COMMAND_FILTER_NO_IMMUNITY, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		TF2_ChangeClientTeam(target_list[i], TFTeam_Spectator);
	}
	
	return Plugin_Handled;
}