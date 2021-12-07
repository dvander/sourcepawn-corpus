#pragma semicolon 1

#include <sourcemod>

public Plugin:myinfo = {
	name = "Heartbeat",
	author = "Wazz",
	description = "Runs the heartbeat command every minute.",
	version = "1.0.0.0",
};

public OnMapStart()
{
	CreateTimer(60.0, Timer_RunHeartbeatCmd, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	
	return;
}

public Action:Timer_RunHeartbeatCmd(Handle:timer, any:none)
{
	ServerCommand("heartbeat");
	
	return Plugin_Continue;
}