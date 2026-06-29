#pragma semicolon 1
#include <sourcemod>

public Plugin:myinfo =
{
	name = "Disable Noblock after 20 seconds",
	author = "cREANy0",
	description = "Set cvar "sm_noblock" to 0",
	version = "1.0",
	url = "www.sourcemod.net"
};

public OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);	
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, Timer_RoundStart_NB_ACTIVE);
	CreateTimer(20.0, Timer_RoundStart_NB_INACTIVE);
	return Plugin_Continue;
}

public Action:Timer_RoundStart_NB_ACTIVE(Handle:timer, any:client)
{
	
	ServerCommand("sm_noblock 1");	
	return Plugin_Stop;
}

public Action:Timer_RoundStart_NB_INACTIVE(Handle:timer, any:client)
{
	
	ServerCommand("sm_noblock 0");	
	return Plugin_Stop;
}