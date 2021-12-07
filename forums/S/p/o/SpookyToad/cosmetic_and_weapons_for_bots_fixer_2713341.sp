#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "Cosmetics and Weapons for bots fixer",
	author = "SpookyToad",
	description = "Fixes cosmetics and weapons for bots",
	version = "1.0",
	url = "https://steamcommunity.com/id/TheMrPigeon/"
};

public void OnPluginStart()
{
	HookEvent("arena_win_panel", OnRoundWin, EventHookMode_PostNoCopy);
}

public void OnRoundWin(Event event, const char[] name, bool dontBroadcast)
{
	ServerCommand("sm plugins reload GiveBotsCosmetics.smx");
	ServerCommand("sm plugins reload GiveBotsWeapons.smx");
	
}