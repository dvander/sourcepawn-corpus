/**
 * vim: set ts=4 :
 * =============================================================================
 * [TF2] Arena Scramble
 * Make tf_arena_use_queue scramble and score like normal arena
 *
 * Name (C)2014 Powerlord (Ross Bemrose).  All rights reserved.
 * =============================================================================
 *
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
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <http://www.sourcemod.net/license.php>.
 *
 * Version: $Id$
 */
#include <sourcemod>
#include <tf2_stocks>
#include <sdktools>
#pragma semicolon 1

// Enable this to turn on debugging code.
//#define DEBUG

#define VERSION "1.1.0"

//swiped from tf2_morestocks.inc in my sourcemod-snippets repo
enum TF2GameType
{
	TF2GameType_Generic,
	TF2GameType_CTF = 1,
	TF2GameType_CP = 2,
	TF2GameType_PL = 3,
	TF2GameType_Arena = 4,
}

// Valve CVars
new Handle:g_Cvar_Queue;
new Handle:g_Cvar_Arena_Streak;

new bool:g_bActive = true;
//new bool:g_bMapActive = false;

new Handle:g_Call_SetScramble;

new TF2GameType:g_MapType = TF2GameType_Generic;

new bool:g_bScrambledThisRound = false;
new winningTeam = 0;

new bool:g_bIgnoreCvarChange = false;
// Stolen from another one of my plugins' valve.inc
#define HUD_PRINTNOTIFY	1
#define HUD_PRINTCONSOLE	2
#define HUD_PRINTTALK		3
#define HUD_PRINTCENTER	4

public Plugin:myinfo = {
	name			= "[TF2] Arena Scramble",
	author			= "Powerlord",
	description		= "Make tf_arena_use_queue scramble and score like normal arena",
	version			= VERSION,
	url				= "https://forums.alliedmods.net/showthread.php?t=251810"
};

//swiped from tf2_morestocks.inc in my sourcemod-snippets repo
/**
 * What basic game type are we?
 *
 * Note that types are based on their base scoring type:
 * CTF - CTF, SD, MvM, and RD(?)
 * CP - CP, 5CP, and TC
 * PL - PL and PLR
 * Arena - Arena
 * 
 * You can find some of the specific types using the IsGameModeX functions.
 * You can tell if a CTF or CP also implements the opposite type using TF2_IsGameModeHybrid()
 * 
 * @return 	A TF2GameType value. 
 */
stock TF2GameType:TF2_GetGameType()
{
	return TF2GameType:GameRules_GetProp("m_nGameType");
}

public OnPluginStart()
{
	CreateConVar("tf2_arena_scramble_version", VERSION, "[TF2] Arena Scramble version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
	
	g_Cvar_Queue = FindConVar("tf_arena_use_queue");
	g_Cvar_Arena_Streak = FindConVar("tf_arena_max_streak");
	
	HookConVarChange(g_Cvar_Queue, Cvar_QueueState);
	
	HookEvent("teamplay_round_start", Event_RoundStart, EventHookMode_Pre);
	//HookEvent("teamplay_round_win", Event_RoundEnd);
	HookEvent("arena_win_panel", Event_WinPanel, EventHookMode_Pre);
	HookEvent("arena_win_panel", Event_WinPanelPost, EventHookMode_PostNoCopy);
	
	new Handle:gamedata = LoadGameConfigFile("tf2scramble");
	
	if (gamedata == INVALID_HANDLE)
	{
		SetFailState("Could not load gamedata");
	}
	
	//void CTeamplayRules::SetScrambleTeams( bool bScramble )
	StartPrepSDKCall(SDKCall_GameRules);
	PrepSDKCall_SetFromConf(gamedata, SDKConf_Virtual, "CTeamplayRules::SetScrambleTeams");
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	g_Call_SetScramble = EndPrepSDKCall();
	
	CloseHandle(gamedata);	
}

//void CTeamplayRules::SetScrambleTeams( bool bScramble )
SetScrambleTeams(bool:bScramble)
{
#if defined DEBUG
    LogMessage("Telling game to scramble on round change.");
#endif
	
	SDKCall(g_Call_SetScramble, bScramble);
	g_bScrambledThisRound = true;
}

public OnConfigsExecuted()
{
	PrecacheScriptSound("Announcer.AM_TeamScrambleRandom");
	
#if defined DEBUG
    LogMessage("g_GameRulesProxy is entref %d", g_GameRulesProxy);
#endif
	
//	g_bMapActive = true;
	g_bActive = false;
	
	g_MapType = TF2_GetGameType();

#if defined DEBUG
    LogMessage("gametype is: %d", g_MapType);
#endif
	
	// If queue is false, we need to be active
	if (g_MapType == TF2GameType_Arena && !GetConVarBool(g_Cvar_Queue))
	{
		g_bActive = true;
	}
}

public OnMapEnd()
{
//	g_bMapActive = false;

	g_MapType = TF2GameType_Generic;
}


public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bScrambledThisRound)
	{
		g_bScrambledThisRound = false;
		
#if defined DEBUG
		LogMessage("Scramble was activated. Resetting team scores.");
#endif
		
		SetTeamScore(_:TFTeam_Red, 0);
		SetTeamScore(_:TFTeam_Blue, 0);
		
		// Arena scrambling using SetScrambleTeams has a few minor differences:
		// 1. It doesn't play the scramble sound.
		EmitGameSoundToAll("Announcer.AM_TeamScrambleRandom");
		
		// 2. It doesn't print the scramble in chat
		new String:streakString[4];
		GetConVarString(g_Cvar_Arena_Streak, streakString, sizeof(streakString));
		
		new String:teamName[18];
		if (winningTeam == _:TFTeam_Red)
		{
			teamName = "#TF_RedTeam_Name";
		}
		else if (winningTeam == _:TFTeam_Blue)
		{
			teamName = "#TF_BlueTeam_Name";
		}
		
		PrintValveTranslationToAll(HUD_PRINTTALK, "#TF_Arena_MaxStreak", teamName, streakString);
	}
	
	return Plugin_Continue;
}


public Action:Event_WinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
#if defined DEBUG
	new panelStyle = GetEventInt(event, "panel_style");
	LogMessage("Panel style: %d", panelStyle);
#endif

	if (!g_bActive)
	{
		return Plugin_Continue;
	}

	g_bIgnoreCvarChange = true;
	// Remove the notify flag and set the queue cvar to true
	new flags = GetConVarFlags(g_Cvar_Queue);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(g_Cvar_Queue, flags);
	SetConVarBool(g_Cvar_Queue, true);
	
	new score;
	new opponentScore;
	new winner = GetEventInt(event, "winning_team");

	new streak = GetConVarInt(g_Cvar_Arena_Streak);
	
	if (winner == _:TFTeam_Red)
	{
		score = GetEventInt(event, "red_score");
		opponentScore = GetEventInt(event, "blue_score_prev");

#if defined DEBUG
		LogMessage("Winner: RED, RED score: %d, BLU score: %d", score, opponentScore);
#endif
		
		if (score >= streak)
		{
#if defined DEBUG
			LogMessage("Red score (%d) exceeds win streak (%d)", score, streak);
#endif
			winningTeam = winner;
			SetScrambleTeams(true);
			return Plugin_Continue;
		}
		
		// Reset the score to imitate how non-queue arena works
		if (opponentScore > 0)
		{
#if defined DEBUG
			LogMessage("Resetting Blue score by adding %d", 0 - opponentScore);
#endif
			SetTeamScore(_:TFTeam_Blue, 0);
		}
		
	}
	else if (winner == _:TFTeam_Blue)
	{
		score = GetEventInt(event, "blue_score");
		opponentScore = GetEventInt(event, "red_score_prev");

#if defined DEBUG
		LogMessage("Winner: BLU, BLU score: %d, RED score: %d", score, opponentScore);
#endif	
		
		if (score >= streak)
		{
#if defined DEBUG
			LogMessage("Blue score (%d) exceeds win streak (%d)", score, streak);
#endif
			winningTeam = winner;
			SetScrambleTeams(true);
			return Plugin_Continue;
		}

		// Reset the score to imitate how non-queue arena works
		if (opponentScore > 0)
		{
#if defined DEBUG
			LogMessage("Resetting Red score by adding %d", 0 - opponentScore);
#endif
			SetTeamScore(_:TFTeam_Red, 0);
		}

	}
	
	return Plugin_Continue;
}

public Event_WinPanelPost(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!g_bActive)
	{
		return;
	}
	
	// Set the queue cvar back to false and reset the notify flag
	SetConVarBool(g_Cvar_Queue, false);
	new flags = GetConVarFlags(g_Cvar_Queue);
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(g_Cvar_Queue, flags);
	g_bIgnoreCvarChange = false;
}

public Cvar_QueueState(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (g_bIgnoreCvarChange || g_MapType != TF2GameType_Arena)
	{
		return;
	}
#if defined DEBUG
	LogMessage("Arena queue setting changed to %s", newValue);
#endif
	
	g_bActive = !GetConVarBool(convar);
}

// Stolen from another one of my plugins' valve.inc

// Print a Valve translation phrase to a group of players
// Adapted from util.h's UTIL_PrintToClientFilter
stock PrintValveTranslation(clients[],
						    numClients,
						    msg_dest,
						    const String:msg_name[],
						    const String:param1[]="",
						    const String:param2[]="",
						    const String:param3[]="",
						    const String:param4[]="")
{
	new Handle:bf = StartMessage("TextMsg", clients, numClients, USERMSG_RELIABLE);
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetInt(bf, "msg_dest", msg_dest);
		PbAddString(bf, "params", msg_name);
		
		PbAddString(bf, "params", param1);
		PbAddString(bf, "params", param2);
		PbAddString(bf, "params", param3);
		PbAddString(bf, "params", param4);
	}
	else
	{
		BfWriteByte(bf, msg_dest);
		BfWriteString(bf, msg_name);
		
		BfWriteString(bf, param1);
		BfWriteString(bf, param2);
		BfWriteString(bf, param3);
		BfWriteString(bf, param4);
	}
	
	EndMessage();
}

stock PrintValveTranslationToAll(msg_dest,
								const String:msg_name[],
								const String:param1[]="",
								const String:param2[]="",
								const String:param3[]="",
								const String:param4[]="")
{
	new total = 0;
	new clients[MaxClients];
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			clients[total++] = i;
		}
	}
	PrintValveTranslation(clients, total, msg_dest, msg_name, param1, param2, param3, param4);
}