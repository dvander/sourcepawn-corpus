#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

// Functions
public Plugin:myinfo =
{
	name = "noclip",
	author = "bl4nk",
	description = "Enable noclip on players",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_noclip", Command_Noclip, ADMFLAG_CHEATS, "sm_noclip <#userid|name>");
}

public Action:Command_Noclip(client, args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_noclip <#userid|name>");
		return Plugin_Handled;
	}

	decl String:arg[65];
	GetCmdArg(1, arg, sizeof(arg));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			arg,
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

	for (new i = 0; i < target_count; i++)
	{
		PerformNoclip(client, target_list[i]);
	}

	return Plugin_Handled;
}

PerformNoclip(client, target)
{
	if (GetEntProp(target, Prop_Send, "movetype", 1) == 8)
		SetEntProp(target, Prop_Send, "movetype", 2, 1);
	else
		SetEntProp(target, Prop_Send, "movetype", 8, 1);
}