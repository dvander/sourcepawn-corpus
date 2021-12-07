public Plugin myinfo =
{
	name = "Fly",
	author = "Sourcemod",
	description = "Simple edit of Sourcemod's funcommands",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public void OnPluginStart()
{
	RegAdminCmd("sm_fly", Command_Fly, ADMFLAG_SLAY|ADMFLAG_CHEATS, "sm_fly <#userid|name>");
	LoadTranslations("common.phrases");
}

void PerformFly(int client, int target)
{
	MoveType movetype = GetEntityMoveType(target);

	if (movetype != MOVETYPE_FLY)
	{
		SetEntityMoveType(target, MOVETYPE_FLY);
	}
	else
	{
		SetEntityMoveType(target, MOVETYPE_WALK);
	}
	
	LogAction(client, target, "\"%L\" toggled fly on \"%L\"", client, target);
}

public Action Command_Fly(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: sm_fly <#userid|name>");
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArg(1, arg, sizeof(arg));
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	if ((target_count = ProcessTargetString(arg, client, target_list, MaxClients, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}
	
	for (int i = 0; i < target_count; i++)
	{
		PerformFly(client, target_list[i]);
	}
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Toggled fly on %t", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Toggled fly on %s", target_name);
	}
	return Plugin_Handled;
}
