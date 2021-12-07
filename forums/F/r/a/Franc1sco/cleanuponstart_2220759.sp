#include <sourcemod>

public OnPluginStart()
{
	HookEvent("round_start", EventRound);
}

public EventRound(Handle:event, const String:name[], bool:dontBroadcast) 
{
	ServerCommand("sm_broom");
}