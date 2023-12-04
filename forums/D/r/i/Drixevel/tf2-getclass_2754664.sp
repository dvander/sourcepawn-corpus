#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>

public Plugin myinfo = 
{
	name = "[TF2] Get Class", 
	author = "Drixevel", 
	description = "Gets the players class and replies with the name.", 
	version = "1.0.0", 
	url = "https://drixevel.dev/"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	RegConsoleCmd("sm_getclass", Command_GetClass, "Gets the players class and replies with the name.");
}

public Action Command_GetClass(int client, int args)
{
	if (args == 0)
	{
		char sCommand[32];
		GetCmdArg(0, sCommand, sizeof(sCommand));
		ReplyToCommand(client, "[SM] Usage: %s <target>", sCommand);
		return Plugin_Handled;
	}

	char sTarget[MAX_TARGET_LENGTH];
	GetCmdArg(1, sTarget, sizeof(sTarget));

	int target = FindTarget(client, sTarget, false, false);

	if (target < 1)
		return Plugin_Handled;

	char sClass[32];
	TF2_GetClientClassName(target, sClass, sizeof(sClass), true);

	ReplyToCommand(client, "[SM] %N's class: %s", target, sClass);

	return Plugin_Handled;
}

void TF2_GetClientClassName(int client, char[] buffer, int size, bool capitalize = false)
{
	switch (TF2_GetPlayerClass(client))
	{
		case TFClass_Unknown: strcopy(buffer, size, "unknown");
		case TFClass_Scout: strcopy(buffer, size, "scout");
		case TFClass_Sniper: strcopy(buffer, size, "sniper");
		case TFClass_Soldier: strcopy(buffer, size, "soldier");
		case TFClass_DemoMan: strcopy(buffer, size, "demoman");
		case TFClass_Medic: strcopy(buffer, size, "medic");
		case TFClass_Heavy: strcopy(buffer, size, "heavy");
		case TFClass_Pyro: strcopy(buffer, size, "pyro");
		case TFClass_Spy: strcopy(buffer, size, "spy");
		case TFClass_Engineer: strcopy(buffer, size, "engineer");
	}

	if (capitalize)
		buffer[0] = CharToUpper(buffer[0]);
	else
		buffer[0] = CharToLower(buffer[0]);
}