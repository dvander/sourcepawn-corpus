#include <sourcemod>

#pragma semicolon 1

//Defines
#define EVENT     "teamplay_round_start"

// Info
public Plugin:myinfo =
{
	name = "Event call Debugger",
	author = "Naydef",
	description = "Test if event calls!",
	version = "0.1",
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	HookEvent(EVENT, Hook_EventCalled, EventHookMode_PostNoCopy);
}

public Action:Hook_EventCalled(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll("Event %s was called!", name);
	LogMessage("Event %s was called!", name);
	return Plugin_Continue;
}