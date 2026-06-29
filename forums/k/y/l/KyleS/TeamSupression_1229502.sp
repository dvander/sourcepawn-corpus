#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Team Supression",
	author = "Kyle Sanderson",
	description = "Got Milk?",
	url = "http://www.SourceMod.net/"
}

public OnPluginStart()
{
	HookEvent("player_team", PlayerTeam, EventHookMode_Pre);
}

public Action:PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	return Plugin_Handled;
}