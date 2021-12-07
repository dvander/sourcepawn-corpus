#include <sourcemod>
#include <sdktools>
 
new Handle:sm_myslap_damage = INVALID_HANDLE
 
public Plugin:myinfo =
{
	name = "MultiMod Slap Plugin",
	author = "[GR]McBoo",
	description = "My Slap Plugin",
	version = "1.0.0.0",
	url = "http://www.buildmod.net46.net/"
}
public OnPluginStart()
{
	LoadTranslations("common.phrases")
	RegAdminCmd("sm_myslap", Command_MySlap, ADMFLAG_SLAY)
 
	sm_myslap_damage = CreateConVar("sm_myslap_damage", "5", "Default slap damage")
	AutoExecConfig(true, "plugin_myslap")
}
 
public Action:Command_MySlap(client, args)
{
	new String:arg1[32], String:arg2[32]
	new damage = GetConVarInt(sm_myslap_damage)
 
	/* Get the first argument */
	GetCmdArg(1, arg1, sizeof(arg1))
 
	/* If there are 2 or more arguments, and the second argument fetch 
	 * is successful, convert it to an integer.
	 */
	if (args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)))
	{
		damage = StringToInt(arg2)
	}
 
	/**
	 * target_name - stores the noun identifying the target(s)
	 * target_list - array to store clients
	 * target_count - variable to store number of clients
	 * tn_is_ml - stores whether the noun must be translated
	 */
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_FILTER_ALIVE, /* Only allow alive players */
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
	{
		/* This function replies to the admin with a failure message */
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		SlapPlayer(target_list[i], damage)
		LogAction(client, target_list[i], "\"%L\" slapped \"%L\" (damage %d)", client, target_list[i], damage)
	}
 
	if (tn_is_ml)
	{
		ShowActivity2(client, "[MMS] ", "Slapped %t for %d damage!", target_name, damage)
	}
	else
	{
		ShowActivity2(client, "[MMS] ", "Slapped %s for %d damage!", target_name, damage)
	}
 
	return Plugin_Handled;
}