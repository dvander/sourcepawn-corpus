#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

bool g_bPanic[MAXPLAYERS+1];

public void OnPluginStart()
{	
	AddCommandListener(BlockAfk, "sm_afk");
	AddCommandListener(BlockAfk, "sm_away");
	AddCommandListener(BlockAfk, "sm_idle");
	AddCommandListener(BlockAfk, "sm_spectate");
	AddCommandListener(BlockAfk, "sm_spectators");
	AddCommandListener(BlockAfk, "sm_joinspectators");
	AddCommandListener(BlockAfk, "sm_jointeam1");
	AddCommandListener(Listen_Keyboard, "go_away_from_keyboard");
	
	HookEvent("witch_harasser_set", 	Event_WitchHarraser);
	HookEvent("player_spawn", 			Event_PlayerSpawn);
	HookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_bPanic[i] = false;
	}
}

public void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	g_bPanic[GetClientOfUserId(event.GetInt("userid"))] = false;
}

public void Event_WitchHarraser(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && GetClientTeam(client) == 2 && !IsFakeClient(client))
	{
		g_bPanic[client] = true;
		CreateTimer(60.0, Timer_AllowAfk, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_AllowAfk(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	g_bPanic[client] = false;
}

bool IsAllowAFK(int iClient)
{
	if (iClient == 0 || !IsClientInGame(iClient))
		return true;
	
	if (g_bPanic[iClient])
	{
		PrintToChat(iClient, "[AFK] You must wait until panic finishes!");
		return false;
	}
	
	return true;
}

public Action BlockAfk(int iClient, const char[] sCommand, int iArg)
{
	if (!IsAllowAFK(iClient))
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}

public Action Listen_Keyboard(int iClient, const char[] sCommand, int iArg)
{
	if (!IsAllowAFK(iClient))
	{
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
