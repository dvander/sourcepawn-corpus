#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo =
{
	name = "Block Teamswitch",
	author = "Tylerst",
	description = "Blocks Teamswitching",
	version = "1.0.0",
	url = "none"
}

public OnPluginStart() AddCommandListener(Command_JoinTeam, "jointeam");
public Action:Command_JoinTeam(client, const String:command[], args) return Plugin_Handled;
