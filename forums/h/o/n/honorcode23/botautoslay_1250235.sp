#include <sourcemod>
new Handle:g_hTimer = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("round_start_post_nav", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
}

public OnRoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	g_hTimer = CreateTimer(15.0, timerSlayBots);
}

public OnRoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
}

public OnMapEnd()
{
	if(g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
}

public Action:timerSlayBots(Handle:timer)
{
	ServerCommand("sm_slay @bots");
	g_hTimer = INVALID_HANDLE;
}