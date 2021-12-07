#include <sourcemod>

public OnMapStart()
{
	CreateTimer(20.0, Timer_Reload);
}

public Action:Timer_Reload(Handle:timer)
{
	ServerCommand("sm plugins reload mpbhops");
	return Plugin_Stop;
}