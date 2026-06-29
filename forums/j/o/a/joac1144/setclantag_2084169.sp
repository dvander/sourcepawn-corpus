#include <sourcemod>
#include <cstrike>

public Plugin:myinfo =
{
	name = "Set Clan Tag",
	author = "Born/Zyanthius/joac1144",
	description = "Set players clan tag",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?t=233177"
}

public OnPluginStart()
{
	RegAdminCmd("sm_setct", Command_SetCT, ADMFLAG_SLAY, "Set players clan tag");
}

public Action:Command_SetCT(client, args)
{	
	if (args < 2)
	{
		ReplyToCommand(client, "[SM] Usage: sm_setcl <name or #userid> <clan tag>");
		return Plugin_Handled;	
	}	
	
	new String:Target[64],String:cl[32]
	GetCmdArg(1, Target, sizeof(Target))
	GetCmdArg(2, cl, sizeof(cl));

	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;
 
	if ((target_count = ProcessTargetString(
			Target,
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
		CS_SetClientClanTag(target_list[i], cl);
		LogAction(client, target_list[i], "Admin %L set %L's clantag to %s", client, target_list[i], cl);
	}
 
	if (tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Set %t's clantag to %s", target_name, cl);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Set %s's clantag to %s", target_name, cl);
	}
 
	return Plugin_Handled;
}

