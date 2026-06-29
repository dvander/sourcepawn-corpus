#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "[TF2] SCREAM",
	author = "Keith Warren (Jack of Designs)",
	description = "Allows anybody to scream at any time!",
	version = "1.0.2",
	url = "http://www.jackofdesigns.com/"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_screamme", Scream);
	RegAdminCmd("sm_scream", Admin_Scream, ADMFLAG_SLAY);
}

public Action:Admin_Scream(client, args)
{
	if (args < 1)
	{
		PrintToChat(client, "[SM] Usage: sm_scream <target>");
		return Plugin_Handled;
	}
	
	new String:arg1[32];
	
	GetCmdArg(1, arg1, sizeof(arg1));
	
	new String:target_name[MAX_TARGET_LENGTH];
	new target_list[MAXPLAYERS], target_count;
	new bool:tn_is_ml;

	if ((target_count = ProcessTargetString(arg1, client, target_list, MAXPLAYERS, COMMAND_FILTER_ALIVE, target_name, sizeof(target_name), tn_is_ml)) <= 0)
	{
		ReplyToTargetError(client, target_count);
		return Plugin_Handled;
	}

	for (new i = 0; i < target_count; i++)
	{
		SetVariantString("HalloweenLongFall");
		AcceptEntityInput(target_list[i], "SpeakResponseConcept");
	}
	
	return Plugin_Handled;
}

public Action:Scream(client, args)
{
	if (!IsClientInGame(client))
	{
		ReplyToCommand(client, "[SM] %t", "Command is in-game only");
		return Plugin_Handled;
	}
	
	if (!IsPlayerAlive(client))
	{
		PrintToChat(client, "[SM] Must be alive to scream.");
		return Plugin_Handled;
	}
	
	SetVariantString("HalloweenLongFall");
	AcceptEntityInput(client, "SpeakResponseConcept");
	
	return Plugin_Handled;
}