#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define VERSION "0.6"

Handle	g_hTimerRepeatCheckLadderStatus[MAXPLAYERS+1];
float	g_vecPunchAngle[MAXPLAYERS+1][3];

// ====================================================================================================
//					PLUGIN INFO / START / END
// ====================================================================================================
public Plugin myinfo = 
{
	name = "[L4D2] Special Infected On Ladder Glitch Fix",
	author = "Zheldorg",
	description = "Fix of the behavior of retreat of the SI bot when it is on the stairs and takes damage from players",
	version = VERSION,
	url = ""
}

public void OnPluginStart()
{
	HookEvent("round_start", 	Event_RoundSTND,	EventHookMode_PostNoCopy);
	HookEvent("round_end",		Event_RoundSTND,	EventHookMode_PostNoCopy);
}

public void OnClientConnected(int client)
{
	CreateTimer(0.1, JustShortWait, client);
}
public Action JustShortWait(Handle timer, any client)
{
	if (IsClientConnected(client))
	{
		if(IsClientInGame(client))
		{
			if (IsFakeClient(client) && GetClientTeam(client) == 3)
			{
				g_hTimerRepeatCheckLadderStatus[client] = CreateTimer(0.1, CheckIsOnLadder, client, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		else CreateTimer(0.1, JustShortWait, client);
	}
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	ClearSIbotTimer(client);
}

public void Event_RoundSTND(Handle event, const char[] name, bool dontBroadcast)
{
	for (int iClient = 1; iClient <= MAXPLAYERS; iClient++)
	{
		ClearSIbotTimer(iClient);
	}
}

public Action CheckIsOnLadder(Handle timer, any client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (IsOnLadder(client))
		{
			ClearSIbotTimer(client);
			SDKHook(client, SDKHook_TraceAttack, TraceAttack);
			SDKHook(client, SDKHook_TraceAttackPost, TraceAttackPost);
			RequestFrame(CheckIsOnLadder2, client);
		}
	}
	else ClearSIbotTimer(client);
	return Plugin_Handled;
}

public void CheckIsOnLadder2(any client)
{
	if (IsClientInGame(client) && IsPlayerAlive(client))
	{
		if (IsOnLadder(client))
		{
			RequestFrame(CheckIsOnLadder2, client);
		}
		else
		{
			SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
			SDKUnhook(client, SDKHook_TraceAttackPost, TraceAttackPost);
			g_hTimerRepeatCheckLadderStatus[client] = CreateTimer(0.1, CheckIsOnLadder, client, TIMER_REPEAT);
		}
	}
	else
	{
		SDKUnhook(client, SDKHook_TraceAttack, TraceAttack);
		SDKUnhook(client, SDKHook_TraceAttackPost, TraceAttackPost);
	}
}

public void ClearSIbotTimer(int client)
{
	if (g_hTimerRepeatCheckLadderStatus[client] != null)
	{
		KillTimer(g_hTimerRepeatCheckLadderStatus[client]);
		g_hTimerRepeatCheckLadderStatus[client] = null;
	}
}

public Action TraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup)
{
	GetEntPropVector(victim, Prop_Send, "m_vecPunchAngle", g_vecPunchAngle[victim]);
	return Plugin_Continue;
}

public void TraceAttackPost(int victim, int attacker, int inflictor, float damage, int damagetype, int ammotype, int hitbox, int hitgroup)
{
	SetEntPropVector(victim, Prop_Send, "m_vecPunchAngle", g_vecPunchAngle[victim]);
}

public bool IsOnLadder(int entity)
{
	return GetEntityMoveType(entity) == MOVETYPE_LADDER;
}