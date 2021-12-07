#include <sourcemod>
#pragma semicolon 1
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Block Disconnect Message",
	author = "Jamster",
	description = "Blocks disconnect message",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent("player_disconnect", event_PlayerDisconnect, EventHookMode_Pre);
}

public Action:event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	SetEventBroadcast(event, true);	
	return Plugin_Continue;
}