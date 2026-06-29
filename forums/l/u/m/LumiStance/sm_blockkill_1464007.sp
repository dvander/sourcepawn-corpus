#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "0.3-lm"

public Plugin:myinfo =
{
	name = "blockkill",
	author = "LumiStance",
	version = PLUGIN_VERSION,
	description = "Plugin for blocking kill cmd",
	url = "http://srcds.LumiStance.com/"
};

public OnPluginStart()
{
	RegConsoleCmd("kill", Command_Block);
	RegConsoleCmd("explode", Command_Block);
	RegConsoleCmd("spectate", Command_Block);
	RegConsoleCmd("jointeam", Command_JoinTeam);
}

public Action:Command_Block(client, args)
{
	return Plugin_Stop;
}

public Action:Command_JoinTeam(client_index, args)
{
	if (GetClientTeam(client_index) > 1)
		return Plugin_Handled;
	return Plugin_Continue;
}
