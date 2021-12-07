#pragma semicolon 1

#define DEBUG


#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <profiler>
#include <sdkhooks>

#pragma newdecls required
#pragma semicolon 1

ConVar teamAreEnemies;
ConVar g_hFFAPlayerCount;

public Plugin myinfo = 
{
	name = "hFFA",
	author = "HerrMagic",
	description = "Turn ffa on under 6 players",
	version = "1.0",
	url = ""
};

public void OnPluginStart()
{
	AutoExecConfig(true, "plugin.hffa", "sourcemod");
	
	g_hFFAPlayerCount = CreateConVar("sm_hFFA_playercount", "6", "Set the player count when ffa is enabled");
	

	teamAreEnemies = FindConVar("mp_teammates_are_enemies");
	
	HookEvent("round_prestart", Event_RoundStart);
	
	
    
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	
	if(GetClientCount() < g_hFFAPlayerCount.IntValue + 1)
    {
        teamAreEnemies.BoolValue = true;
        PrintToChatAll("\x04[FFA] \x05Friendly fire is \x04activated");
        
	} else if(GetClientCount() > g_hFFAPlayerCount.IntValue)
	{
   		teamAreEnemies.BoolValue = false;
   		PrintToChatAll("\x04[FFA] \x05Friendly fire is \x02deactivated");
   		
	}
}