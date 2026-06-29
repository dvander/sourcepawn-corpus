#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Replay bot fixer",
	author = "fluffys",
	description = "Fixes the replay bots on ckSurf",
	version = "1.0",
	url = "http://steamcommunity.com/profiles/76561198000303868/"
}

public OnMapStart()
{
	CreateTimer(5.0, TimerToggleOff);
	CreateTimer(10.0, TimerToggleOn);
}

public Action:TimerToggleOff(Handle:timer)
{
	ServerCommand("ck_replay_bot 0");
	ServerCommand("ck_bonus_bot 0");
}


public Action:TimerToggleOn(Handle:timer)
{
	ServerCommand("ck_replay_bot 1");
	ServerCommand("ck_bonus_bot 1");
}
