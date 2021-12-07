#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.1"

// Functions
public Plugin:myinfo =
{
	name = "SetHealth",
	author = "bl4nk",
	description = "Set a player's health",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	RegAdminCmd("sm_sethealth", Command_SetHealth, ADMFLAG_SLAY, "sm_sethealth <name> <amount>");
}

public Action:Command_SetHealth(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_sethealth <name> <amount>");
		return Plugin_Handled;
	}

	decl String:text[256];
	GetCmdArg(1, text, sizeof(text));

	decl String:target_name[MAX_TARGET_LENGTH];
	decl target_list[MAXPLAYERS], target_count, bool:tn_is_ml;

	if ((target_count = ProcessTargetString(
			text,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	decl String:amount[6];
	GetCmdArg(2, amount, sizeof(amount));

	SetEntityHealth(client, StringToInt(amount));
	SetEntProp(client, Prop_Send, "m_iMaxHealth", StringToInt(amount));

	return Plugin_Handled;
}