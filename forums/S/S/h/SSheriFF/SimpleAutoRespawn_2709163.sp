#pragma semicolon 1
#define DEBUG
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#pragma newdecls required
bool TimePassed = false;
public Plugin myinfo = 
{
	name = "Simple auto respawn",
	author = "SheriF",
	description = "",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
	HookEvent("player_death", OnPlayerDeath);
}
public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	TimePassed = false;
	CreateTimer(60.0, TimerFunc);
}
public Action OnPlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int userid = GetClientOfUserId(event.GetInt("userid"));
	if(!TimePassed)
	CS_RespawnPlayer(userid);
}
public Action TimerFunc(Handle timer)
{
	TimePassed = true;
}