#include <sourcemod>
#define PLUGIN_VERSION "1.1"

new Handle:sm_fly_version = INVALID_HANDLE

public Plugin:myinfo = 
{
	name = "Flight",
	author = "noodleboy347",
	description = "Lets players fly around.",
	version = PLUGIN_VERSION,
	url = "http://www.frozencubes.com"
}

public OnPluginStart()
{
	LoadTranslations("common.phrases")
	RegAdminCmd("sm_fly", Command_Fly, ADMFLAG_SLAY)
	sm_fly_version = CreateConVar("sm_fly_version", PLUGIN_VERSION, "Flight plugin version")
}
public Action:Command_Fly(client, args)
{
	new String:arg1[32], String:arg2[32]
	
	GetCmdArg(1, arg1, sizeof(arg1))
	if (args >= 2 && GetCmdArg(2, arg2, sizeof(arg2)))
	{
	}
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
		ReplyToCommand(client, "[SM] Usage: sm_fly <#userid|name>");
		return Plugin_Handled;
	}
	for (new i = 0; i < target_count; i++)
	{
		new String:name[MAX_NAME_LENGTH]
		GetClientName(target_list[i], name, sizeof(name))
		new MoveType:movetype = GetEntityMoveType(target_list[i]);
		if (movetype != MOVETYPE_FLY)
		{
			SetEntityMoveType(target_list[i], MOVETYPE_FLY);
		}
		else
		{
			SetEntityMoveType(target_list[i], MOVETYPE_WALK);
		}
		ShowActivity2(client, "[SM] ", "Toggled flight on %s.", name)
		LogAction(client, target_list[i], "\"%L\" toggled flight on \"%L\"", client, target_list[i])
	}
	return Plugin_Handled;
}