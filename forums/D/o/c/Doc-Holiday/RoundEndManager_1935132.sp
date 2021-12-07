#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

new const String:PLUGIN_VERSION[] = "1.0.1";
const MAXTEAMS = 3;

/* Valve ConVars */
new Handle:g_Cvar_IgnoreWinConditions = INVALID_HANDLE;
new Handle:g_Cvar_RoundTime = INVALID_HANDLE;

/* Plugin Setting ConVars */
new Handle:g_Cvar_Toggle = INVALID_HANDLE;
new Handle:g_Cvar_IgrnoreTimer = INVALID_HANDLE;
new Handle:g_Cvar_IgnoreBombDefused = INVALID_HANDLE;
new Handle:g_Cvar_IgnoreBombExplode = INVALID_HANDLE;
new Handle:g_Cvar_DebugMod = INVALID_HANDLE;

/* Data Handles */
new Handle:g_Timer_RoundTimer = INVALID_HANDLE;

/* Player Variables */
new bool:g_bIsUserAlive[MAXPLAYERS+1];
new g_iTeam[MAXPLAYERS+1];

/* Team Variables */
new g_iAlivePlayers[MAXTEAMS+1];

/* Map Variables */
new bool:g_bHasBombSite;

public Plugin:myinfo = 
{
	name = "Round End Manager",
	author = "SavSin",
	description = "Disable certain round end conditions.",
	version = PLUGIN_VERSION,
	url = "www.norcalbots.com"
}

public OnPluginStart()
{
	
	/* Get Valve ConVars */
	g_Cvar_IgnoreWinConditions = FindConVar("mp_ignore_round_win_conditions");
	g_Cvar_RoundTime = FindConVar("mp_roundtime");
	
	HookConVarChange(g_Cvar_IgnoreWinConditions, Cvar_IgnoreWinConditionsChanged);
	
	/* Create Plugin ConVars */
	g_Cvar_Toggle = CreateConVar("rem_ignore_round_win_conditions", "1", "Toggles the plugin on and off. <Default: 1>", _, true, 0.0, true, 1.0);
	g_Cvar_IgrnoreTimer = CreateConVar("rem_ignore_round_timer", "1", "Disables round timer on bomb maps. <Default: 1>", _, true, 0.0, true, 1.0);
	g_Cvar_IgnoreBombDefused = CreateConVar("rem_ignore_bomb_defused", "0", "Ignores the bomb being defused. <Default: 0>", _, true, 0.0, true, 1.0);
	g_Cvar_IgnoreBombExplode = CreateConVar("rem_ignore_bomb_exploded", "0", "Ignores the bomb being blown up. <Default: 0>", _, true, 0.0, true, 1.0);
	g_Cvar_DebugMod = CreateConVar("rem_debug_toggle", "1", "Toggles debug mode on and off. <Default: 1>", _, true, 0.0, true, 1.0);
	
	HookConVarChange(g_Cvar_Toggle, Cvar_ToggleChanged);
	
	/* Create and Execute the Config File */
	AutoExecConfig(true, "roundendconditions", "sourcemod");
	
	/* Hook Events */
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_deaht", Event_PlayerDeath);
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("bomb_defused", Event_BombDefused);
	HookEvent("bomb_exploded", Event_BombExploded);
}

public OnMapStart()
{
	new iEnt = -1;
	if((FindEntityByClassname(iEnt, "func_bomb_target")) != -1)
	{
		g_bHasBombSite = true;
	}
}

public OnConfigsExecuted()
{
	if(g_bHasBombSite && GetConVarBool(g_Cvar_Toggle))
	{
		SetConVarInt(g_Cvar_IgnoreWinConditions, 1);
		
		if(GetConVarBool(g_Cvar_DebugMod))
			PrintToServer("DEBUG: Setting mp_ignore_round_win_conditions to 1");
	}
	else
	{
		SetConVarInt(g_Cvar_IgnoreWinConditions, 0);
		SetConVarInt(g_Cvar_Toggle, 0);
		
		if(GetConVarBool(g_Cvar_DebugMod))
			PrintToServer("DEBUG: Setting mp_ignore_round_win_conditions to 0");
	}
}

public OnClientDisconnect(iClient)
{
	if(g_bIsUserAlive[iClient])
	{
		if(--g_iAlivePlayers[g_iTeam[iClient]] <= 0)
		{
			if(g_iTeam[iClient] == CS_TEAM_CT)
				TerminateRound(CS_TEAM_CT, CS_TEAM_T, CSRoundEnd_TerroristWin);
			else if(g_iTeam[iClient] == CS_TEAM_T)
				TerminateRound(CS_TEAM_T, CS_TEAM_CT, CSRoundEnd_TerroristWin);
		}
	}
}

public Cvar_ToggleChanged(Handle:hConVar, const String:szOldValue[], const String:szNewValue[])
{
	if(StringToInt(szNewValue) == 0)
	{
		PrintToServer("Disabling Round End Manager, mp_ignore_round_win_conditions restored to default");
		SetConVarInt(g_Cvar_IgnoreWinConditions, 0);
	}
	else
	{
		PrintToServer("Enabling Round End Manager, mp_ignore_round_win_conditions set to 1");
		SetConVarInt(g_Cvar_IgnoreWinConditions, 1);
	}
}

public Cvar_IgnoreWinConditionsChanged(Handle:hConVar, const String:szOldValue[], const String:szNewValue[])
{
	if(g_bHasBombSite && GetConVarBool(g_Cvar_Toggle))
	{
		if(StringToInt(szNewValue) == 0)
		{
			PrintToServer("This ConVar is Locked. Disable Round End Manager by setting rem_ignore_round_win_conditions to 0");
			SetConVarInt(g_Cvar_IgnoreWinConditions, 1);
		}
	}
}

public Action:Event_PlayerTeam(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if(!GetConVarBool(g_Cvar_Toggle))
		return Plugin_Continue;
		
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	g_iTeam[iClient] = GetEventInt(hEvent, "team");
	return Plugin_Continue;
}

public Action:Event_RoundStart(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	/* Start Round Timer */
	if(GetConVarBool(g_Cvar_IgrnoreTimer))
		return Plugin_Continue;
	
	if(GetConVarBool(g_Cvar_DebugMod))
		PrintToServer("DEBUG: Starting Round Timer");
	
	g_Timer_RoundTimer = CreateTimer(GetConVarFloat(g_Cvar_RoundTime), Timer_RoundEndTime, INVALID_HANDLE, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

public Action:Event_RoundEnd(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if(g_Timer_RoundTimer != INVALID_HANDLE)
	{
		KillTimer(g_Timer_RoundTimer);
		g_Timer_RoundTimer = INVALID_HANDLE;
	}
}

public Action:Event_PlayerSpawn(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if(!GetConVarBool(g_Cvar_Toggle))
		return Plugin_Continue;
		
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(IsPlayerAlive(iClient) && g_iTeam[iClient] > CS_TEAM_SPECTATOR)
	{
		if(GetConVarBool(g_Cvar_DebugMod))
			PrintToServer("DEBUG: Updating player status.");
			
		g_bIsUserAlive[iClient] = true;
		++g_iAlivePlayers[g_iTeam[iClient]];
	}
	return Plugin_Continue;
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if(!GetConVarBool(g_Cvar_Toggle))
		return Plugin_Continue;
		
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	g_bIsUserAlive[iVictim] = false;
	
	if(--g_iAlivePlayers[g_iTeam[iVictim]] <= 0)
	{
		if(GetConVarBool(g_Cvar_DebugMod))
			PrintToServer("DEBUG: All team is dead End the Round.");
			
		if(g_iTeam[iVictim] == CS_TEAM_CT)
			TerminateRound(CS_TEAM_CT, CS_TEAM_T, CSRoundEnd_TerroristWin);
		else if(g_iTeam[iVictim] == CS_TEAM_T)
			TerminateRound(CS_TEAM_T, CS_TEAM_CT, CSRoundEnd_TerroristWin);
	}
	return Plugin_Continue;
}

public Action:Event_BombDefused(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if(GetConVarBool(g_Cvar_IgnoreBombDefused))
		return Plugin_Continue;
	
	if(GetConVarBool(g_Cvar_DebugMod))
		PrintToServer("DEBUG: Bomb has been defused Ending the round..");
	TerminateRound(CS_TEAM_CT, CS_TEAM_T, CSRoundEnd_BombDefused);
	return Plugin_Continue;
}

public Action:Event_BombExploded(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if(GetConVarBool(g_Cvar_IgnoreBombExplode))
		return Plugin_Continue;
		
	if(GetConVarBool(g_Cvar_DebugMod))
		PrintToServer("DEBUG: Bomb has exploded ending the round..");
		
	TerminateRound(CS_TEAM_CT, CS_TEAM_T, CSRoundEnd_TargetBombed);
	return Plugin_Continue;
}

public Action:Timer_RoundEndTime(Handle:hTimer, any:data)
{
	if(GetConVarBool(g_Cvar_DebugMod))
	PrintToServer("DEBUG: The round timer has expired ending the round.");
	
	g_Timer_RoundTimer = INVALID_HANDLE;
	TerminateRound(CS_TEAM_CT, CS_TEAM_T, CSRoundEnd_TargetSaved);
}

stock TerminateRound(iWinningTeam, iLosingTeam, CSRoundEndReason:iReason)
{
	if(GetConVarBool(g_Cvar_DebugMod))
	PrintToServer("DEBUG: Stopping the timer, updating the team score, ending the round.");
	
	if(g_Timer_RoundTimer != INVALID_HANDLE)
	{
		KillTimer(g_Timer_RoundTimer);
		g_Timer_RoundTimer = INVALID_HANDLE;
	}
	
	new iTeamScore = (CS_GetTeamScore(iWinningTeam) +1 );
	CS_SetTeamScore(iWinningTeam, iTeamScore);
	SetTeamScore(iWinningTeam, iTeamScore);
	CS_TerminateRound(3.0, iReason, false);
}