#include <tf2attributes>

public OnPluginStart()
{
	RegAdminCmd("sm_maxhealth", SetMaxHealth, ADMFLAG_GENERIC)
	RegAdminCmd("sm_maxhealth_f", SetMaxHealthF, ADMFLAG_GENERIC)
}

public Action:SetMaxHealth(client, args)
{
	new String:arg1[32], String:arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		TF2Attrib_SetByName(target_list[i], "max health additive bonus", StringToFloat(arg2))
	}
	return Plugin_Continue;
}

public Action:SetMaxHealthF(client, args)
{
	new String:arg1[32], String:arg2[32];
	GetCmdArg(1, arg1, sizeof(arg1))
	GetCmdArg(2, arg2, sizeof(arg2))
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_CONNECTED, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
 
	for (new i = 0; i < target_count; i++)
	{
		new HP = GetClientHealth(target_list[i])
		TF2Attrib_SetByName(target_list[i], "max health additive bonus", StringToFloat(arg2))
		SetEntityHealth(client, StringToInt(arg2) + HP)
	}
	return Plugin_Continue;
}