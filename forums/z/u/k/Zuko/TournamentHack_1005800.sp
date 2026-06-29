#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define PL_VERSION "0.3"
#define CVAR_Enabled	0
#define NUM_CVARS	1


public Plugin:myinfo = 
{
	name = "Tournament Hack",
	author = "Geit",
	description = "Allows the use of tournament commands without requiring the tournament HUD",
	version = PL_VERSION,
	url = "http://gamingmasters.co.uk"
};

new Handle:g_cvars[NUM_CVARS] = INVALID_HANDLE;
new g_enabled;
new Handle:cvar;
new bool:g_FirstRound = false;
new Handle:g_WaitTimer = INVALID_HANDLE;

public OnPluginStart()
{
	//if(GetConVarInt(FindConVar("hostport")) != 27018)
	//SetFailState("Failure: Not on port 27018");
	
	g_cvars[CVAR_Enabled] = CreateConVar("sm_th_Enabled", "1", "Enables Tournament Hacker");	
	cvar = FindConVar("mp_tournament");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	
	cvar = FindConVar("mp_tournament_stopwatch");
	SetConVarFlags(cvar, GetConVarFlags(cvar) & ~(FCVAR_NOTIFY));
	
	SetConVarInt(FindConVar("mp_tournament_stopwatch"), 0, true);
	SetConVarInt(FindConVar("tf_tournament_hide_domination_icons"), 0, true);
	SetConVarInt(FindConVar("mp_tournament"), 0, true);
	
	HookConVarChange(FindConVar("mp_restartgame"), OnConVarChange);
	HookConVarChange(g_cvars[CVAR_Enabled], OnConVarChange);
	
	HookEvent("arena_round_start", Event_arena_round_start);
	HookEvent("arena_win_panel", Event_arena_round_end);
	HookEvent("teamplay_round_start", Event_teamplay_round_start);
	HookEvent("teamplay_round_win", Event_teamplay_round_end);
	
	ServerCommand("tf_tournament_classlimit_scout -1");
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == FindConVar("mp_restartgame"))
	{
		DisableBB();
	}
	else if (hCvar == g_cvars[CVAR_Enabled])
	{
		g_enabled = StringToInt(newValue);
		if (g_enabled == 1)
		{
			EnableBB();
		}
		else
		{
			DisableBB();
		}
	}
}

public Action:Event_teamplay_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_FirstRound)
	{
		g_FirstRound = true;
		new Float:g_WaitTime = float(GetConVarInt(FindConVar("mp_waitingforplayers_time")));
		g_WaitTime += 2.0;
		g_WaitTimer = CreateTimer(g_WaitTime, EndOfWaiting);
	} 
	else {
		EnableBB();
		CloseHandle(g_WaitTimer);
	}
	
}

public Action:Event_arena_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!g_FirstRound){ g_FirstRound = true; } else {EnableBB();}
}

public Action:Event_arena_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	DisableBB();
}

public Action:Event_teamplay_round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	DisableBB();
}

public OnMapStart(){
	DisableBB();
	g_FirstRound = false;
}

public Action:EndOfWaiting(Handle:timer, any:data) {
	SetConVarInt(FindConVar("mp_waitingforplayers_cancel"), 1, true);	
	CreateTimer(2.0, DelayedEnable);
	for(new i=1; i<=MaxClients; i++) {
		if(IsClientInGame(i) && IsPlayerAlive(i)) {
			TF2_RespawnPlayer(i);
		}
	}
}

public Action:DelayedEnable(Handle:timer, any:data) {
EnableBB();	
}



DisableBB(){
	SetConVarInt(FindConVar("mp_tournament"), 0, true);
}

EnableBB(){
	if (g_enabled == 1 && g_FirstRound 	){
		SetConVarInt(FindConVar("mp_tournament"), 1, true);
	}
}