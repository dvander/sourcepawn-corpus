#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

int g_iTimer_AutoRespawn;
Handle g_hTimer_AutoRespawn;

public void OnPluginStart()
{
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
}

public void OnMapEnd()
{
	g_iTimer_AutoRespawn = 0;
	g_hTimer_AutoRespawn = null;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	//Prevents the timer from being called more than once.
	if (g_hTimer_AutoRespawn != null)
	{
		KillTimer(g_hTimer_AutoRespawn);
		g_hTimer_AutoRespawn = null;
	}
	
	g_iTimer_AutoRespawn = 30;
	g_hTimer_AutoRespawn = CreateTimer(1.0, Timer_AutoRespawn, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
}

public Action Timer_AutoRespawn(Handle timer)
{
	if (g_iTimer_AutoRespawn > 0)
	{
		PrintHintTextToAll("Warmup: Seconds left - %i", g_iTimer_AutoRespawn);
		g_iTimer_AutoRespawn--;
		
		return Plugin_Continue;
	}
	
	g_iTimer_AutoRespawn = 0;
	g_hTimer_AutoRespawn = null;
	
	PrintToChatAll("WARMUP is OFF. Players no longer respawn.");
	
	return Plugin_Stop;
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iTimer_AutoRespawn > 0)
	{
		CreateTimer(1.0, Timer_RespawnClient, event.GetInt("userid"), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_RespawnClient(Handle timer, any data)
{
	int client = GetClientOfUserId(data);
	
	if (client > 0 && IsClientConnected(client) && IsClientInGame(client) && !IsPlayerAlive(client))
	{
		CS_RespawnPlayer(client);
	}
}