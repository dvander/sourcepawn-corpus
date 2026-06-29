/**
 * The sm_slay command will cause a Dystopia server to crash. This plugin was made to replace its function,
 * and can be integrated into the admin menu.
 *
 * Creates the fslay command.
 */

#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo =
{
	name = "Fake Client Command Slay",
	author = "emjay",
	description = "Slays a player using a fake client command.",
	version = "4.0",
	url = "https://forums.alliedmods.net/showthread.php?t=275168"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");

	/* Register the fslay command. */
	RegAdminCmd("fslay", Command_Fslay, ADMFLAG_SLAY, "fslay <#userid|name>");
}

public Action Command_Fslay(int client, int args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "[SM] Usage: fslay <#userid|name>");
		return Plugin_Handled;
	}

	char arg[65];
	GetCmdArgString( arg, sizeof(arg) );
	
	char target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count;
	bool tn_is_ml;
	
	target_count = ProcessTargetString(arg, 
									   client, 
									   target_list, 
									   MAXPLAYERS, 
									   COMMAND_FILTER_ALIVE,
									   target_name,
									   sizeof(target_name),
									   tn_is_ml);

	if(target_count <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for(int i = 0; i < target_count; i++)
	{
		LogAction(client, target_list[i], "\"%L\" called \"fslay\" on \"%L\"", client, target_list[i]);
		FakeClientCommandEx(target_list[i], "kill");
	}

	if(tn_is_ml)
	{
		ShowActivity2(client, "[SM] ", "Called \"fslay\" on \"%t\".", target_name);
	}
	else
	{
		ShowActivity2(client, "[SM] ", "Called \"fslay\" on \"%s\".", target_name);
	}

	return Plugin_Handled;
}