#include <sourcemod>
#include <customachievements>

public Plugin:myinfo =
{
	name = "Admin Achievements",
	author = "Luki",
	description = "Admin Achievements for \"Custom Achievements\".",
	version = "1.1",
	url = "none"
};
 
public OnPluginStart()
{
	RegAdminCmd("sm_achievement", cAchievement, ADMFLAG_GENERIC);
}

public Action:cAchievement(client, args)
{
	decl String:arg1[MAXPLAYERS], String:arg2[10];
	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_achievement <#userid|name> <achievementid>");
		return Plugin_Handled;
	}
	else
	{
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
	}
	
	/*
	
	new target = FindTarget(client, arg1)
	if (target == -1)
	{
		return Plugin_Handled;
	}
	
	ProcessAchievement(StringToInt(arg2), target);

	*/
	
	new String:target_name[MAX_TARGET_LENGTH]
	new target_list[MAXPLAYERS], target_count
	new bool:tn_is_ml
	
	if ((target_count = ProcessTargetString(
				arg1,
				client,
				target_list,
				MAXPLAYERS,
				COMMAND_FILTER_CONNECTED,
				target_name,
				sizeof(target_name),
				tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		ProcessAchievement(StringToInt(arg2), target_list[i]);
		LogAction(client, target_list[i], "\"%L\" has given an achievement to \"%L\" (achievement id %d)", client, target_list[i], StringToInt(arg2));
	}
	
	return Plugin_Handled;
}