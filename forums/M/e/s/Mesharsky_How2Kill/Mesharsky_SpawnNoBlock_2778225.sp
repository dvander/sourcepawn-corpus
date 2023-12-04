/*	Copyright (C) 2022 Mesharsky
	This program is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.
	This program is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with this program. If not, see <http://www.gnu.org/licenses/>.

	//Credit goes to Digby for all the tips and all the help he could give me during the past year, I love you ❤️
*/

#include <sourcemod>
#include <sdktools>
#include <multicolors>

#define PLUGIN_VERSION "0.5"

public Plugin myinfo = 
{
	name = "[CS:GO] Simple Spawn NoBlock", 
	author = "Mesharsky", 
	description = "Gives you no-block on spawn for a specific amount of time", 
	version = PLUGIN_VERSION, 
	url = "https://forums.alliedmods.net/member.php?u=279899"
};

// Collision_Group_t values from CSGO
#define COLLISION_GROUP_PUSHAWAY 17
#define COLLISION_GROUP_PLAYER 5

#define RETRY_TIMER 5.0

ConVar g_Cvar_NoBlockDuration;
ConVar g_Cvar_FreezeDuration;
ConVar g_Cvar_SolidTeam;
ConVar g_Cvar_Notify;
ConVar g_Cvar_NoBlockRoundMode;
ConVar g_Cvar_NoBlockStartRound;

Handle g_Timer_NoBlock;
Handle g_Timer_RetryReset;

bool g_AwaitingReset[MAXPLAYERS + 1];

int g_RoundCount;

// ==== [ FORWARDS ] ===========================================================

public void OnPluginStart()
{
	LoadTranslations("ssnb.phrases");

	HookEvent("round_start", EventRoundStart);
	HookEvent("announce_phase_end", EventTeamChange);
	HookEvent("cs_intermission", EventTeamChange);
	
	ConVar version = CreateConVar("noblock_version", PLUGIN_VERSION, "NoBlock Version. Do not touch.", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	version.AddChangeHook(LockVersionConVar);
	
	g_Cvar_NoBlockDuration = CreateConVar("noblock_time", "8.0", "For how long noblock should be active after round starts", FCVAR_NONE, true, 0.0, true, 20.0);
	g_Cvar_Notify = CreateConVar("noblock_notification", "1", "Toggle chat announcements.\n(1 - Enabled | 0 - Disabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_NoBlockRoundMode = CreateConVar("noblock_round_mode", "0", "Toggle noblock from specific round\n(1 - Enabled | 0 - Disabled)", FCVAR_NONE, true, 0.0, true, 1.0);
	g_Cvar_NoBlockStartRound = CreateConVar("noblock_start_round", "1", "From which round noblock should start working", FCVAR_NONE, true, 0.0, true, 30.0);
	g_Cvar_FreezeDuration = FindConVar("mp_freezetime");
	g_Cvar_SolidTeam = FindConVar("mp_solid_teammates");
	
	AutoExecConfig();
}

void LockVersionConVar(ConVar cvar, const char[] oldValue, const char[] newValue)
{
	if (!StrEqual(newValue, PLUGIN_VERSION))
		cvar.SetString(PLUGIN_VERSION);
}

public void OnMapStart()
{
	g_RoundCount = 0;
	StopNoBlock();
}

public void OnClientPutInServer(int client)
{
	ResetClientPushOthers(client);
}

public void OnClientDisconnect(int client)
{
	g_AwaitingReset[client] = false;
}

public Action EventRoundStart(Event event, const char[] name, bool DontBroadcast)
{
	if (GameRules_GetProp("m_bWarmupPeriod"))
		return Plugin_Continue;
	
	g_RoundCount++;
	
	if (g_Cvar_NoBlockRoundMode.BoolValue && g_RoundCount < g_Cvar_NoBlockStartRound.IntValue)
		return Plugin_Continue;
	
	float duration = GetNoBlockDuration();
	StartNoBlock(duration);
	if (g_Cvar_Notify.BoolValue)
		CPrintToChatAll("%t", "NoBlockStart", RoundToZero(duration));
	
	return Plugin_Continue;
}

public Action EventTeamChange(Event event, const char[] name, bool DontBroadcast)
{
	g_RoundCount = -1;
}

// ==== [ NOBLOCK FUNCTIONS ] ==================================================

void StartNoBlock(float duration)
{
	StopNoBlock();
	
	// Make sure collision group is compatible with mp_solid_teammates 0
	// because EventRoundStart can cancel g_Timer_RetryReset.
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
			ResetClientPushOthers(i);
	}
	
	g_Cvar_SolidTeam.SetBool(false);
	g_Timer_NoBlock = CreateTimer(duration, Timer_FinishNoBlock);
}
void StopNoBlock(bool deleteTimer = true)
{
	g_Cvar_SolidTeam.SetBool(true);
	if (deleteTimer)
		delete g_Timer_NoBlock;
	
	delete g_Timer_RetryReset;
	for (int i = 0; i < sizeof(g_AwaitingReset); i++)
	g_AwaitingReset[i] = false;
}

public Action Timer_FinishNoBlock(Handle tmr, any client)
{
	StopNoBlock(false);
	g_Timer_NoBlock = null; // Can't delete timer here
	
	for (int i = 1; i <= MaxClients; i++)
	AttemptResetClient(i);
	
	if (g_Cvar_Notify.BoolValue)
		CPrintToChatAll("%t", "NoBlockEnd");
	
	return Plugin_Handled;
}


// ==== [ CLIENT FUNCTIONS ] ===================================================

bool AttemptResetClient(int client)
{
	if (!IsClientInGame(client))
		return true;
	
	if (ShouldResetClient(client))
	{
		// It's necessary to fix collision even if it was never
		// changed because StartNoBlock() interrupt g_Timer_RetryReset.
		ResetClientPushOthers(client);
		return true;
	}
	else
	{
		SetClientPushOthers(client);
		if (g_Timer_RetryReset == null)
			g_Timer_RetryReset = CreateTimer(RETRY_TIMER, Timer_RetryReset, 0, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	return false;
}

bool ShouldResetClient(int client)
{
	if (!IsClientInGame(client) || !IsPlayerAlive(client))
		return true;
	return !IsClientTouchingClient(client);
}

public Action Timer_RetryReset(Handle timer, any data)
{
	bool repeat = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!g_AwaitingReset[i])
			continue;
		
		if (!AttemptResetClient(i)) // Changes g_AwaitingReset
			repeat = true;
	}
	
	if (repeat)
		return Plugin_Continue;
	
	g_Timer_RetryReset = null;
	return Plugin_Stop;
}


// ==== [ COLLISION ] ==========================================================

bool IsClientTouchingClient(int client)
{
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
		return false;
	
	float mins[3];
	float maxs[3];
	float origin[3];
	GetClientMins(client, mins);
	GetClientMaxs(client, maxs);
	GetClientAbsOrigin(client, origin);
	
	TR_TraceHullFilter(origin, origin, mins, maxs, MASK_SOLID, Filter_OtherClient, client);
	return TR_DidHit();
}

bool Filter_OtherClient(int entity, int contentsMask, any data)
{
	return entity != data && entity >= 1 && entity <= MaxClients;
}

void ResetClientPushOthers(int client)
{
	g_AwaitingReset[client] = false;
	
	#if SOURCEMOD_V_MAJOR == 1 && SOURCEMOD_V_MINOR >= 11
	SetEntityCollisionGroup(client, COLLISION_GROUP_PLAYER);
	#else
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PLAYER);
	#endif
}

void SetClientPushOthers(int client)
{
	g_AwaitingReset[client] = true;
	
	#if SOURCEMOD_V_MAJOR == 1 && SOURCEMOD_V_MINOR >= 11
	SetEntityCollisionGroup(client, COLLISION_GROUP_PUSHAWAY);
	#else
	SetEntProp(client, Prop_Data, "m_CollisionGroup", COLLISION_GROUP_PUSHAWAY);
	#endif
}


// ==== [ STOCKS ] =============================================================

float GetNoBlockDuration()
{
	float duration = g_Cvar_NoBlockDuration.FloatValue + g_Cvar_FreezeDuration.FloatValue;
	float maxDuration = GetMaxRoundTimeSeconds();
	if (maxDuration <= 1.0 || duration < maxDuration)
		return duration;
	return maxDuration - 1.0;
}

float GetMaxRoundTimeSeconds()
{
	ConVar ignoreTime = FindConVar("mp_ignore_round_win_conditions");
	if (ignoreTime.BoolValue)
		return 0.0;
	
	// TODO: Use the correct one for the current gamemode
	// Until then just use the biggest value.
	ConVar defuse = FindConVar("mp_roundtime_defuse");
	ConVar hostage = FindConVar("mp_roundtime_hostage");
	ConVar roundTime = FindConVar("mp_roundtime");
	
	float a = defuse.FloatValue * 60.0;
	float b = hostage.FloatValue * 60.0;
	float c = roundTime.FloatValue * 60.0;
	
	if (a > b)
		return (a > c) ? a : c;
	return (b > c) ? b : c;
}
