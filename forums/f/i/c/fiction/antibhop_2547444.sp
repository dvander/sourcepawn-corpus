#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

ConVar g_cvJumpBlockedTicks;

int g_iPassedTicks[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_jump", Event_PlayerJump);

	g_cvJumpBlockedTicks = CreateConVar("sm_jump_blocked_ticks", "100", "Ticks/frames after jumping before you are able to jump again.", _, true, 0.0);
}

public void Event_PlayerSpawn(Event event, const char[] command, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_iPassedTicks[client] = -1;
}

public void Event_PlayerJump(Event event, const char[] command, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_iPassedTicks[client] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons)
{
	Action iReturn = Plugin_Continue;
	static bool bReleasedJump[MAXPLAYERS + 1] = {true, ...};
	if(!IsPlayerAlive(client) || IsFakeClient(client))
		return iReturn;

	if(g_cvJumpBlockedTicks.IntValue > g_iPassedTicks[client] >= 0)
	{
		g_iPassedTicks[client]++;

		if(buttons & IN_JUMP)
		{
			buttons &= ~IN_JUMP;
			iReturn = Plugin_Changed;
		}
	}
	else if(g_iPassedTicks[client] == g_cvJumpBlockedTicks.IntValue)
	{
		g_iPassedTicks[client] = -1;
		bReleasedJump[client] = false;
	}

	if(g_iPassedTicks[client] == -1 && !bReleasedJump[client])
	{
		if(!(buttons & IN_JUMP))
			bReleasedJump[client] = true;

		if(!bReleasedJump[client])
		{
			buttons &= ~IN_JUMP;
			iReturn = Plugin_Changed;
		}
	}

	return iReturn;
}