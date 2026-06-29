#pragma semicolon 1
#include <sourcemod>
#include <tf2roundinfo>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "TF2 Round Info Example",
	author = "Antithasys",
	description = "Returns the amount of time left in the round.",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	RegConsoleCmd("sm_roundtime", Command_RoundTime, "Returns the round time left");
}

public Action:Command_RoundTime(client, args)
{
	new time;
	TF2INFO_GetRoundTimeLeft(time);
	ReplyToCommand(client, "Round Time Left: %i", time);
}
