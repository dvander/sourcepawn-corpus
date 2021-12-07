#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2_stocks>

public Plugin myinfo =
{
	name = "TF2: Anti-Invis Wrench",
	description = "Stops players from spawning as invisible heavies",
	author = "Batfoxkid",
	version = "1.0"
}

public void OnPluginStart()
{
	AddCommandListener(OnChangeClass, "joinclass");
	AddCommandListener(OnChangeClass, "join_class");
}

public Action OnChangeClass(int client, const char[] command, int args)
{
	if(!client)
		return Plugin_Continue;

	static char class[16];
	GetCmdArg(1, class, 16);
	if(TF2_GetPlayerClass(client)==TFClass_Engineer && TF2_GetClass(class)==TFClass_Heavy)
	{
		SetEntProp(client, Prop_Send, "m_iDesiredPlayerClass", TFClass_Heavy);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

#file "TF2: Anti-Invis Wrench"