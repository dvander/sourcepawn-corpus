#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = 
{
	name        = "Hide Team Changes",
	author      = "Mini",
	description = "Hides team change notifications",
	version     = "1.0",
	url         = "http://forums.alliedmods.net"
};

public OnPluginStart() 
{
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
}

public Action:Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast) 
{
	SetEventBroadcast(event, true);
	return Plugin_Continue;
}