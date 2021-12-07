#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Teleport",
	author = "The Count, WildCard65",
	description = "Teleport one person to another.",
	version = "1.1",
	url = ""
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_teleport", Command_Teleport, ADMFLAG_SLAY, "Teleports a player.");
}

public Action:Command_Teleport (client, args)
{
	if (args < 1 || args > 2)
	{
		ReplyToCommand(client, "Usage: sm_teleport <#userid|name> [#userid|name]");
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
	new teleTo;
	if (args == 2)
	{
		decl String:arg2[65];
		GetCmdArg(2, arg2, sizeof(arg2));
		teleTo = FindTarget(client, arg2);
	}
	else
	{
		teleTo = client;
	}
	if (teleTo == -1 || !IsPlayerAlive(teleTo))
	{
		ReplyToCommand(client, "Target to teleport people to is invalid.");
		return Plugin_Handled;
	}
	new Float:vec[3]; 
	GetClientAbsOrigin(teleTo, vec); 
	for (new i = 0; i < target_count; i++)
	{
		TeleportEntity(target_list, vec, NULL_VECTOR, NULL_VECTOR);
	}
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Teleported %t to %N.", target_name, teleTo);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Teleported %s to %N.", target_name, teleTo);
	}
	return Plugin_Handled;
}
