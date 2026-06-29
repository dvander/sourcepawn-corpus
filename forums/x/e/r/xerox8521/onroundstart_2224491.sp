#pragma semicolon 1
#include <sourcemod>
#define ROUND_START_CFG "on_round_start.cfg"

/**
 * Plugin Info
 */ 
public Plugin:myinfo = 
{
    name = "OnRoundStart",
    author = "PimpinJuice",
    description = "Execute a config file on round_start",
    version = "1.0",
    url = "http://alliedmods.net"
};

public OnPluginStart()
{
    HookEvent("round_start", OnRoundStartEvent);
	HookEvent("teamplay_round_start",OnRoundStartEvent);
}

public Action:OnRoundStartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
    ServerCommand("exec %s\n", ROUND_START_CFG);
        
    return Plugin_Continue;
}