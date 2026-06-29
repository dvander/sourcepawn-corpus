#pragma semicolon 1
#include <sourcemod>
#include <tf2>

public Plugin:myinfo = 
{
	name = "[VSH/FF2] Block sucides when raged.",
	author = "Adjo",
	description = "Blocks kill and explode command when the client is under the rage effect.",
	version = "1.0",
}

public OnPluginStart()
{
	AddCommandListener(Command_Kill, "kill");
	AddCommandListener(Command_Kill, "explode");
}

public Action:Command_Kill(client, const String:command[], argc)
{
	if(client == 0)
		return Plugin_Continue;

	new stunFlags = GetEntProp(client, Prop_Send, "m_iStunFlags");
	if(stunFlags == TF_STUNFLAGS_GHOSTSCARE | TF_STUNFLAG_NOSOUNDOREFFECT)return Plugin_Handled;
	else return Plugin_Continue;
}