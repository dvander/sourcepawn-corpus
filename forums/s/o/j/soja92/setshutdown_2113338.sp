#include <sourcemod>

new Handle:g_Timer_One = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Auto restart",
	author = "SoJa",
	description = "restart server after 1 day",
	version = "1",
	url = "http://gflclan.com"
}





public OnMapStart()
{
	g_Timer_One = CreateTimer(21600.0, SetShutdown)
}

public Action:SetShutdown(Handle:timer)
{
	ServerCommand("sv_shutdown");
	KillTimer(g_Timer_One);
	return Plugin_Handled;
}