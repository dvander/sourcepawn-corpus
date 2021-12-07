#include <sourcemod>
new Handle:g_hTimer = INVALID_HANDLE;
new Handle:g_cvarMode = INVALID_HANDLE;

public OnPluginStart()
{
	HookEvent("round_start_post_nav", OnRoundStart);
	HookEvent("round_end", OnRoundEnd);
	HookEvent("player_left_start_area", OnPlayerLeave);
	HookEvent("mission_lost", OnMissionLost);
	g_cvarMode = CreateConVar("l4d2_botautoslay_mode", "1", "1: Slay bots when player leave safe are, 0:Slay bots on round start", FCVAR_PLUGIN);
}

public OnRoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	if(!GetConVarBool(g_cvarMode))
	{
		g_hTimer = CreateTimer(15.0, timerSlayBots);
	}
	else
	{
		HookEvent("door_open", OnDoorOpen);
	}
}
public OnDoorOpen(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(!GetEventBool(event, "checkpoint") || !GetEventBool(event, "closed"))
	{
		return;
	}
	ServerCommand("sm_slay @bots");
	UnhookEvent("door_open", OnDoorOpen);
}

public OnPlayerLeave(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(GetConVarBool(g_cvarMode))
	{
		ServerCommand("sm_slay @bots");
	}
}

public OnMissionLost(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
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