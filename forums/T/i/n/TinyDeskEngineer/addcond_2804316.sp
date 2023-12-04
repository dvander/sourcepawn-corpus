#include <sourcemod>
#include <tf2>

public Plugin myinfo =
{
	name = "Addcond",
	author = "Tiny Desk Engineer",
	description = "Allows admins to use addcond",
	version = "1.0",
	url = ""
}

public void OnPluginStart()
{
	RegAdminCmd("sm_addcond", Command_Addcond, ADMFLAG_CHEATS, "Adds a condition to player using condition ID.");
	RegAdminCmd("sm_removecond", Command_Removecond, ADMFLAG_CHEATS, "Removes a condition from a player using condition IDs.")
	LoadTranslations("common.phrases");
}

public Action Command_Addcond(int client, int args)
{
	char arg1[32], arg2[32], arg3[32];
	
	float duration = TFCondDuration_Infinite;
	int target = client;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	int condition = StringToInt(arg1);
	
	if (args >= 2)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		duration = StringToFloat(arg2);
	}
	
	if (args >= 3)
	{
		GetCmdArg(3, arg3, sizeof(arg3));
		target = FindTarget(client, arg3);
		
		if (target == -1)
		{
			return Plugin_Handled;
		}
	}
	
	TF2_AddCondition(target, view_as<TFCond>(condition), duration, client);
	ReplyToCommand(client, "[SM] Condition %i applied to player %N for %f seconds.", condition, target, duration);
	
	return Plugin_Handled;
}

public Action Command_Removecond(int client, int args)
{
	char arg1[32], arg2[32];
	
	int target = client;
	
	GetCmdArg(1, arg1, sizeof(arg1));
	int condition = StringToInt(arg1);
	
	if (args >= 2)
	{
		GetCmdArg(2, arg2, sizeof(arg2));
		target = FindTarget(client, arg2);
		
		if (target == -1)
		{
			return Plugin_Handled;
		}
	}
	
	TF2_RemoveCondition(target, view_as<TFCond>(condition));
	ReplyToCommand(client, "[SM] Condition %i removed from player %N.", condition, target);
	
	return Plugin_Handled;
}