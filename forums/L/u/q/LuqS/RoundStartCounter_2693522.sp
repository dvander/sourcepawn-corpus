#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

int g_iCurrentRound;
int g_iWarmupTime;

public Plugin myinfo = 
{
	name = "Round-Start Counter", 
	author = "LuqS",
	description = "", 
	version = "1.0", 
	url = "https://steamcommunity.com/id/LuqSGood"
};

public void OnPluginStart()
{
	if (GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");
	
	HookEvent("round_start", Event_RoundStart);
}

public void OnMapStart()
{
	g_iCurrentRound = -2; // Because game only starts on the Third occurrence of "round_start" event (Source: https://forums.alliedmods.net/showthread.php?t=201793)
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_iCurrentRound++ >= 0)
	{
		g_iWarmupTime = GetConVarInt(FindConVar("mp_freezetime")) - 1;
		CreateTimer(1.0, Timer_FreezeTimeEnd, _, TIMER_REPEAT);
	}
}

public Action Timer_FreezeTimeEnd(Handle timer)
{
	if(g_iWarmupTime <= 0)
	{
		PrintCenterTextAll("GL HF!");
		return Plugin_Stop;
	}
	
	PrintCenterTextAll("Current Round: %d\nRound Start In:%d Seconds", g_iCurrentRound, g_iWarmupTime--);
	return Plugin_Continue;
}