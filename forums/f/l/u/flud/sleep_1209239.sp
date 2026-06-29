#include <sourcemod>

public OnPluginStart()
{
	RegAdminCmd("sm_sleep", Command_sleep, ADMFLAG_SLAY, "[SM] Usage: sm_sleep <#userid|name>");
	RegAdminCmd("sm_wakeup", Command_wakeup, ADMFLAG_SLAY, "[SM] Usage: sm_wakeup <#userid|name>");
}

public Action:Command_sleep(client, args)
{    
	if (args < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_sleep <#userid|name>");
		return Plugin_Handled;
	}

	decl String:arg[256];
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
		ReplyToCommand(client, "[SM] no matching client was found");
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Send, "m_isIncapacitated", true);
	}
	return Plugin_Handled;
}

public Action:Command_wakeup(client, args)
{    
	if (args < 1) {
		ReplyToCommand(client, "[SM] Usage: sm_wakeup <#userid|name>");
		return Plugin_Handled;
	}

	decl String:arg[256];
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
		ReplyToCommand(client, "[SM] no matching client was found");
		return Plugin_Handled;
	}
	
	for (new i = 0; i < target_count; i++)
	{
		SetEntProp(target_list[i], Prop_Send, "m_isIncapacitated", false);
	}
	return Plugin_Handled;
}