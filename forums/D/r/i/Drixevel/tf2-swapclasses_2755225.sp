#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>

public Plugin myinfo = 
{
	name = "[TF2] Swap Classes", 
	author = "Drixevel", 
	description = "A command which allows admins to swap player classes on the spot.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_swapclass", Command_SwapClasses, ADMFLAG_SLAY, "Force two players to swap classes.");
}

public Action Command_SwapClasses(int client, int args)
{
	if (args < 2)
	{
		char sCommand[32];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		ReplyToCommand(client, "[SM] Usage: %s <target1> <target2>", sCommand);
		return Plugin_Handled;
	}

	char sTarget1[MAX_TARGET_LENGTH];
	GetCmdArg(1, sTarget1, sizeof(sTarget1));

	int target1 = FindTarget(client, sTarget1, false, true);

	if (target1 < 1 || !IsClientInGame(target1))
	{
		ReplyToCommand(client, "Target '%s' is not available, please try again.", sTarget1);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(target1))
	{
		ReplyToCommand(client, "Target '%s' is not alive, please try again.", sTarget1);
		return Plugin_Handled;
	}

	TFClassType class1 = TF2_GetPlayerClass(target1);

	if (class1 == TFClass_Unknown)
	{
		ReplyToCommand(client, "Target '%s' has no valid class, please try again.", sTarget1);
		return Plugin_Handled;
	}

	char sTarget2[MAX_TARGET_LENGTH];
	GetCmdArg(2, sTarget2, sizeof(sTarget2));

	int target2 = FindTarget(client, sTarget2, false, true);

	if (target2 < 1 || !IsClientInGame(target2))
	{
		ReplyToCommand(client, "Target '%s' is not available, please try again.", sTarget2);
		return Plugin_Handled;
	}

	if (!IsPlayerAlive(target2))
	{
		ReplyToCommand(client, "Target '%s' is not alive, please try again.", sTarget2);
		return Plugin_Handled;
	}

	TFClassType class2 = TF2_GetPlayerClass(target2);

	if (class2 == TFClass_Unknown)
	{
		ReplyToCommand(client, "Target '%s' has no valid class, please try again.", sTarget2);
		return Plugin_Handled;
	}

	TF2_SetPlayerClass(target1, class2);
	TF2_RegeneratePlayer(target1);
	SetEntProp(target1, Prop_Data, "m_iHealth", GetEntProp(target1, Prop_Data, "m_iMaxHealth"));

	TF2_SetPlayerClass(target2, class1);
	TF2_RegeneratePlayer(target2);
	SetEntProp(target2, Prop_Data, "m_iHealth", GetEntProp(target2, Prop_Data, "m_iMaxHealth"));

	ShowActivity2(client, "[SM] ", "You have switched the classes of %N and %N.", target1, target2);
	LogAction(client, -1, "%L have switched the classes of %L and %L.", client, target1, target2);

	if (client != target1 && !IsFakeClient(target1))
		PrintToChat(target1, "%N has forced you and %N to switch classes.", client, target2);
	
	if (client != target2 && !IsFakeClient(target2))
		PrintToChat(target2, "%N has forced you and %N to switch classes.", client, target1);

	return Plugin_Handled;
}