#include <sourcemod>

public OnPluginStart()
{
	CreateTimer(5.0, Start_Delay)
	HookEvent("round_start", RoundStart, EventHookMode_Post)
}


public Action:Start_Delay(Handle:timer)
{
	ServerCommand("sm plugins unload keyman_dls.smx")
	ServerCommand("sm plugins load keyman_dls.smx")
}

public Action:RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	CreateTimer(5.0, Start_Delay)
} 
