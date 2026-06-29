#include <sourcemod>

new String:mCurrent[64];
new Handle:g_Timer = INVALID_HANDLE;


public OnMapStart()
{
	GetCurrentMap(mCurrent, sizeof(mCurrent));
	
	if (StrEqual(mCurrent, "c1m4_atrium", false))
	{
		g_Timer = CreateTimer(120.0, TimerChDelay);
	}
}

public OnMapEnd()
{
	if (g_Timer != INVALID_HANDLE)
	{
		KillTimer(g_Timer);
		g_Timer = INVALID_HANDLE;
	}
}

public Action:TimerChDelay(Handle:timer)
{	
	ServerCommand("changelevel c2m1_highway");
	g_Timer = INVALID_HANDLE;
}