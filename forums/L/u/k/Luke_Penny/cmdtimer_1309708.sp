#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Command Repeat Timer",
	author = "Luke Penny",
	description = "Runs a series of commands on a timer",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	CreateTimer(30.0, Interval, _, TIMER_REPEAT);
}

public Action:Interval(Handle:timer) 
{
	if (GetClientCount() != 0)
	{
		ServerCommand("exec sourcemod/repeatedcommands.cfg");
	}
}