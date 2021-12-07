#pragma semicolon 1

#include <tf2>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "TF2 Add Condition",
	author = "Tylerst",
	description = "Add a condition to the target(s)",
	version = PLUGIN_VERSION,
	url = "None"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegAdminCmd("sm_addcond", Command_AddCondition, ADMFLAG_GENERIC, "Add a condition to the target(s), Usage: sm_addcond \"target\" \"condition number\" \"duration\"");
	RegAdminCmd("sm_removecond", Command_RemoveCondition, ADMFLAG_GENERIC, "Add a condition to the target(s), Usage: sm_removecond \"target\" \"condition number\"");
}

public Action:Command_AddCondition(client, args)
{

	if(args != 3)
	{
		ReplyToCommand(client, "[SM] Usage: sm_addcond \"target\" \"condition number\" \"duration\"");
		return Plugin_Handled;
	}

	new String:strBuffer[MAX_NAME_LENGTH], String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strBuffer, sizeof(strBuffer));
	if ((target_count = ProcessTargetString(strBuffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	new iCondition, Float:flDuration;

	GetCmdArg(2, strBuffer, sizeof(strBuffer));
	iCondition = StringToInt(strBuffer);

	GetCmdArg(3, strBuffer, sizeof(strBuffer));
	flDuration = StringToFloat(strBuffer);	

	for(new i = 0; i < target_count; i++)
	{
		TF2_AddCondition(target_list[i], TFCond:iCondition, flDuration);
	}
	return Plugin_Handled;
}

public Action:Command_RemoveCondition(client, args)
{

	if(args != 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_removecond \"target\" \"condition number\"");
		return Plugin_Handled;
	}

	new String:strBuffer[MAX_NAME_LENGTH], String:target_name[MAX_TARGET_LENGTH], target_list[MAXPLAYERS], target_count, bool:tn_is_ml;
	GetCmdArg(1, strBuffer, sizeof(strBuffer));
	if ((target_count = ProcessTargetString(strBuffer, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	new iCondition;

	GetCmdArg(2, strBuffer, sizeof(strBuffer));
	iCondition = StringToInt(strBuffer);

	for(new i = 0; i < target_count; i++)
	{
		TF2_RemoveCondition(target_list[i], TFCond:iCondition);
	}
	return Plugin_Handled;
}
