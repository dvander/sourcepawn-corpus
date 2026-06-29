/*
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>.
 */
 
#pragma semicolon 1

#include <sourcemod>
#undef REQUIRE_PLUGIN
#include <sdktools>

#pragma newdecls required

#define PL_VERSION "1.0.2"

public Plugin myinfo =
{
	name = "sm_idledealmethod 1",
	author = "bzdmn",
	description = "Don't kick idle spectators (as in mp_idledealmethod 1)",
	version = PL_VERSION,
	url = "https://www.mge.me/"
};

Handle g_hIdleResetTimer;

ConVar g_cvIdleDealMethod_MP;
ConVar g_cvIdleDealMethod_SM;
ConVar g_cvIdleMaxTime;

float g_fIdleTime;
bool g_bPreventTeamBroadcast = false;

enum 
{
	TeamNone = 0,
	TeamSpec = 1
};

/**********************/
//	On-Functions
/**********************/

public void OnPluginStart()
{
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Pre);
	
	g_cvIdleDealMethod_SM = CreateConVar
	(
		"sm_idledealmethod", "1",
		"Alters mp_idledealmethod 1. If enabled, prevents idle spectators from being kicked.", 
		_, 
		true, 0.0, true, 1.0
	);
	
	g_cvIdleDealMethod_MP = FindConVar("mp_idledealmethod");
	g_cvIdleMaxTime = FindConVar("mp_idlemaxtime");
	
	// Reset idle state ten seconds before idlemaxtime expires
	g_fIdleTime = (g_cvIdleMaxTime.FloatValue * 60) - 10;

	HookConVarChange(g_cvIdleDealMethod_MP, Changed_IdleDealMethod_MP);
	HookConVarChange(g_cvIdleDealMethod_SM, Changed_IdleDealMethod_SM);
	HookConVarChange(g_cvIdleMaxTime, Changed_IdleMaxTime);
	
#if defined DEBUG
	PrintToServer("g_fIdleTime: %f", g_fIdleTime);
	RegConsoleCmd("idle_reset_timer", PrintResetTimer);
}

Action PrintResetTimer(int client, int args)
{
	ReplyToCommand(client, "g_hIdleResetTimer == null : %b", g_hIdleResetTimer == null); 
	return Plugin_Continue;
}
#else
}
#endif

public void OnConfigsExecuted()
{
	if (g_hIdleResetTimer == null)
	{
		if (g_cvIdleDealMethod_MP.IntValue == 1 && g_cvIdleDealMethod_SM.IntValue == 1)
			g_hIdleResetTimer = CreateTimer(g_fIdleTime, Timer_ResetIdle, _, TIMER_REPEAT);
		
	}
}

/******************/
//	ConVars
/******************/

void Changed_IdleDealMethod_SM(ConVar cvar, const char[] oldval, const char[] newval)
{
	int enabled = StringToInt(newval);
	
	if (enabled == 1)
	{
		if (g_cvIdleDealMethod_MP.IntValue == 1 && g_hIdleResetTimer == null)
		{
			ResetIdleTimes();
			g_hIdleResetTimer = CreateTimer(g_fIdleTime, Timer_ResetIdle, _, TIMER_REPEAT);
		}
	}
	else if (enabled == 0)
	{
		if (g_hIdleResetTimer != null)
			delete g_hIdleResetTimer;
	}
}

void Changed_IdleDealMethod_MP(ConVar cvar, const char[] oldval, const char[] newval)
{
	int mode = StringToInt(newval);
	
	if (mode == 1)
	{
		if (g_cvIdleDealMethod_SM.IntValue == 1 && g_hIdleResetTimer == null)
		{
			ResetIdleTimes();
			g_hIdleResetTimer = CreateTimer(g_fIdleTime, Timer_ResetIdle, _, TIMER_REPEAT);
		}
	}
	else if (mode == 0 || mode == 2)
	{
		if (g_hIdleResetTimer != null)
			delete g_hIdleResetTimer;
	}
}

void Changed_IdleMaxTime(ConVar cvar, const char[] oldval, const char[] newval)
{
	g_fIdleTime = (StringToFloat(newval) * 60) - 10;
	
#if defined DEBUG
	PrintToServer("g_fIdleTime: %f", g_fIdleTime);
#endif
	
	ResetIdleTimes();
	
	if (g_hIdleResetTimer != null)
	{
		delete g_hIdleResetTimer;
		g_hIdleResetTimer = CreateTimer(g_fIdleTime, Timer_ResetIdle, _, TIMER_REPEAT);
	}
}

/******************/
//	Events
/******************/

Action Event_PlayerTeam(Event ev, const char[] name, bool dontBroadcast)
{
	if (g_bPreventTeamBroadcast) 
		SetEventBroadcast(ev, true);
	else 
		SetEventBroadcast(ev, dontBroadcast);

	return Plugin_Continue;
}

/***********************/
//	Core Functions
/***********************/

/*	Idle state of spectators is reset by moving them to TEAM_NONE and then back to TEAM_SPEC. 
 */
void ResetIdleTime(int client)
{
	float eyeAngles[3];
	float eyePosition[3];

	// Get all properties of the spectator

	int iObsMode = GetEntProp(client, Prop_Send, "m_iObserverMode");
	int hObsTarget = GetEntPropEnt(client, Prop_Send, "m_hObserverTarget");

	GetClientEyeAngles(client, eyeAngles);
	GetClientEyePosition(client, eyePosition);

	ChangeClientTeam(client, TeamNone);
	ChangeClientTeam(client, TeamSpec);

	// Reset the previous spectator state

	TeleportEntity(client, eyePosition, eyeAngles, NULL_VECTOR);

	SetEntProp(client, Prop_Send, "m_iObserverMode", iObsMode);
	SetEntPropEnt(client, Prop_Send, "m_hObserverTarget", hObsTarget);

#if defined DEBUG
	PrintToChat(client, "mode: %i, target: %i", iObsMode, hObsTarget);
	PrintToChat(client, "ang: %f %f %f", eyeAngles[0], eyeAngles[1], eyeAngles[2]);
	PrintToChat(client, "pos: %f %f %f", eyePosition[0], eyePosition[1], eyePosition[2]);
#endif
}

void ResetIdleTimes()
{
	g_bPreventTeamBroadcast = true;

	for (int client = 1; client <= MaxClients; client++)
	{
		if (IsClientInGame(client) && IsClientObserver(client))
		{
			ResetIdleTime(client);
		}
	}

	g_bPreventTeamBroadcast = false;
}

/******************/
//	Timers
/******************/

Action Timer_ResetIdle(Handle timer)
{
	ResetIdleTimes();

#if defined DEBUG
	PrintToServer("sm_idledealmethod1: Timer_ResetIdle %f", GetTickedTime());
#endif
	
	return Plugin_Continue;
}
