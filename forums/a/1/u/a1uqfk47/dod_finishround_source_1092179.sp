//////////////////////////////////////////////
//
// SourceMod Script
//
// DoD FinishRound Source
//
// Developed by FeuerSturm
//
// - Credits to "darkranger" for the request & beta testing!
//
//////////////////////////////////////////////
//
//
// USAGE:
// ======
//
//
// CVARs:
// ------
//
// dod_finishround_source <1/0>			=	enable/disable allowing players to finish the running
//											round before changing the map if timelimit is up
//
// dod_finishround_minplayers <#>		=	minimum active players to allow finishing the round
//
// dod_drophealthkit_lifetime <#>		=	number of seconds a dropped healthkit stays on the map
//
// dod_finishround_hintmessage <1/0>	=	enable/disable displaying a 'Last Round' hint message to respawning players
//
//
//
//
// CHANGELOG:
// ==========
// 
// - 16 November 2008 - Version 1.0
//   Initial Release
//
// - 08 February 2009 - Version 1.01
//   Bugfixes:
//   * fixed "client not in game" errors
//
//
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.01"

#define ALLIES 2
#define AXIS 3

public Plugin:myinfo = 
{
	name = "DoD FinishRound Source",
	author = "FeuerSturm",
	description = "Allows players to finish the round before changing map!",
	version = PLUGIN_VERSION,
	url = "http://community.sourceplugins.net"
}

new Handle:FRStatus = INVALID_HANDLE
new Handle:FRMinPl = INVALID_HANDLE
new Handle:FRHintMsg = INVALID_HANDLE
new Handle:FinishRoundTimer = INVALID_HANDLE
new Handle:mpTimelimit = INVALID_HANDLE
new bool:g_LastRound = false
new bool:PluginChanged = false
new String:g_LastRoundMsg[256]

public OnPluginStart()
{
	CreateConVar("dod_finishround_version", PLUGIN_VERSION, "DoD FinishRound Source Version (DO NOT CHANGE!)", FCVAR_DONTRECORD|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY)
	SetConVarString(FindConVar("dod_finishround_version"), PLUGIN_VERSION)
	FRStatus = CreateConVar("dod_finishround_source", "1", "<1/0> = enable/disable allowing players to finish the running round before changing the map if timelimit is up", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	FRMinPl = CreateConVar("dod_finishround_minplayers", "4", "<#> = minimum active players to allow finishing the round", FCVAR_PLUGIN, true, 2.0, true, 12.0)
	FRHintMsg = CreateConVar("dod_finishround_hintmessage", "1", "<1/0> = enable/disable displaying a 'Last Round' hint message to respawning players", FCVAR_PLUGIN, true, 0.0, true, 1.0)
	mpTimelimit = FindConVar("mp_timelimit")
	HookConVarChange(mpTimelimit, OnTimeLimitChanged)
	HookEventEx("dod_round_win", OnRoundWin, EventHookMode_Post)
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
	AutoExecConfig(true, "dod_finishround_source", "dod_finishround_source")
	LoadTranslations("dod_finishround_source.txt")
}

public OnMapTimeLeftChanged()
{
	KillFinishRoundTimer()
	new timeleft = GetTimeLeft()
	if(timeleft > 0)
	{
		SetFinishRoundTimer(timeleft)
	}
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(FRHintMsg) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"))
		if(IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) > 1 && g_LastRound == true)
		{
			CreateTimer(0.1, ShowLastRoundMsg, client, TIMER_FLAG_NO_MAPCHANGE)
		}
	}
	return Plugin_Continue
}

public Action:ShowLastRoundMsg(Handle:timer, any:client)
{
	if(IsClientInGame(client))
	{
		PrintHintText(client, g_LastRoundMsg)
	}
	return Plugin_Handled
}

public Action:CheckFinishRound(Handle:timer)
{
	FinishRoundTimer = INVALID_HANDLE
	if(GetConVarInt(FRStatus) == 1 && EnoughPlayers() == true)
	{
		PluginChanged = true
		new time = 0
		ChangeTimeLimit(time)
		if(FormatLastRoundMsg())
		{
			PrintToChatAll("\x04[DoD FinishRound] \x01%s", g_LastRoundMsg)
		}
		g_LastRound = true
		CreateTimer(60.0, CheckPlayerCount, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE)
	}
	return Plugin_Handled
}

public Action:CheckPlayerCount(Handle:timer)
{
	if(GetConVarInt(FRStatus) == 1 && EnoughPlayers() == true)
	{
		return Plugin_Handled
	}
	else
	{
		CreateTimer(0.1, GoToNextMap, _, TIMER_FLAG_NO_MAPCHANGE)
		return Plugin_Stop
	}
}

stock bool:EnoughPlayers()
{
	new activeplayers = (GetTeamClientCount(ALLIES) + GetTeamClientCount(AXIS))
	if (activeplayers >= GetConVarInt(FRMinPl))
	{
		return true
	}
	else
	{
		return false
	}
}

stock bool:FormatLastRoundMsg()
{
	decl String:currmap[128]
	GetCurrentMap(currmap, sizeof(currmap))
	if(FindConVar("sm_nextmap") != INVALID_HANDLE)
	{
		decl String:nextmap[128]
		GetNextMap(nextmap, sizeof(nextmap))
		Format(g_LastRoundMsg, sizeof(g_LastRoundMsg), "%T", "LastRoundNextMap", LANG_SERVER, currmap, nextmap)
	}
	else
	{
		Format(g_LastRoundMsg, sizeof(g_LastRoundMsg), "%T", "LastRoundNoNextMap", LANG_SERVER, currmap)
	}
	return true
}
	

stock ChangeTimeLimit(time)
{
	new flags = GetConVarFlags(mpTimelimit) 
	flags &= ~FCVAR_NOTIFY
	SetConVarFlags(mpTimelimit, flags)
	SetConVarInt(mpTimelimit, time, true, false)
	flags &= FCVAR_NOTIFY
	SetConVarFlags(mpTimelimit, flags)
}

public Action:ChangeLevel(Handle:timer)
{
	decl String:nextmap[128]
	GetNextMap(nextmap, sizeof(nextmap))
	ForceChangeLevel(nextmap, "DoD RoundFinish Source")
	return Plugin_Handled
}

public Action:OnRoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_LastRound)
	{
		return Plugin_Continue
	}
	if(GetConVarInt(FindConVar("dod_bonusround")) == 1)
	{
		new BonusTime = GetConVarInt(FindConVar("dod_bonusroundtime"))-1
		CreateTimer(float(BonusTime), GoToNextMap, _, TIMER_FLAG_NO_MAPCHANGE)
	}
	else if(GetConVarInt(FindConVar("dod_bonusround")) == 0)
	{
		CreateTimer(5.0, GoToNextMap, _, TIMER_FLAG_NO_MAPCHANGE)
	}
	return Plugin_Continue
}
	
public Action:GoToNextMap(Handle:timer)	
{	
	PluginChanged = true
	new time = 1
	ChangeTimeLimit(time)
	if(FindConVar("sm_nextmap") == INVALID_HANDLE)
	{
		return Plugin_Continue
	}
	CreateTimer(14.0, ChangeLevel, _, TIMER_FLAG_NO_MAPCHANGE)
	return Plugin_Continue
}	

public OnTimeLimitChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if(PluginChanged)
	{
		PluginChanged = false
		return
	}
	new oldvalue = StringToInt(oldValue)
	new newvalue = StringToInt(newValue)
	if(oldvalue != newvalue)
	{
		OnMapTimeLeftChanged()
	}
}

public OnMapStart()
{
	new timeleft = GetTimeLeft()
	if(timeleft > 0)
	{
		SetFinishRoundTimer(timeleft)
	}
	g_LastRound = false
	PluginChanged = false
}

public OnMapEnd()
{
	KillFinishRoundTimer()
	g_LastRound = false
	PluginChanged = false
}

stock GetTimeLeft()
{
	new timeleft
	GetMapTimeLeft(timeleft)
	return timeleft
}

stock KillFinishRoundTimer()
{
	if(FinishRoundTimer != INVALID_HANDLE)
	{
		CloseHandle(FinishRoundTimer)
		FinishRoundTimer = INVALID_HANDLE
	}
}

stock SetFinishRoundTimer(timeleft)
{
	KillFinishRoundTimer()
	FinishRoundTimer = CreateTimer(float(timeleft)-15.0, CheckFinishRound)
}