#include <sourcemod>
#include <sdktools>
#include <tf2>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[GMG] Ignite",
	author = "noodleboy347",
	description = "Ignites a player",
	version = PLUGIN_VERSION,
	url = "http://www.frozencubes.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases")
	RegAdminCmd("sm_ignite", Command_Ignite, ADMFLAG_SLAY)
	CreateConVar("sm_ignite_version", PLUGIN_VERSION, "[TF2] Ignite version")
}
public Action:Command_Ignite(client, args)
{
	new String:arg1[32], String:arg2[32]
	if (args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)))
	{
	}
	GetCmdArg(1, arg1, sizeof(arg1))
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
 
	if ((target_count = ProcessTargetString(
			arg1,
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
	if (args != 1)
	{
		ReplyToCommand(client, "\x05[SM]\x01 Usage: sm_ignite <name>");
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		TF2_IgnitePlayer(target_list[i], target_list[i])

		//Show Activity
		new String:name[MAX_NAME_LENGTH]
		GetClientName(target_list[i], name, sizeof(name))
		ShowActivity2(client, "[SM] ", "Ignited %s!", name)
	}
	
	return Plugin_Handled;
}