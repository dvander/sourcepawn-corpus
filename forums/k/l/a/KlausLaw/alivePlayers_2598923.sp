#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Klaus"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "Alive players", 
	author = PLUGIN_AUTHOR, 
	description = "Info in hud", 
	version = PLUGIN_VERSION, 
	url = "https://steamcommunity.com/id/KlausLaw/"
};

int g_Kills[MAXPLAYERS + 1];

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_death", Event_PlayerDeath);
	CreateTimer(1.0, Timer_HudMsg, _, TIMER_REPEAT);
}


public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	g_Kills[attacker]++;
	return Plugin_Continue;
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		g_Kills[i] = 0;
	}
	return Plugin_Continue;
}

public Action Timer_HudMsg(Handle timer)
{
	static int iAlivePlayers;
	iAlivePlayers = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsPlayerAlive(i))continue;
		iAlivePlayers++;
	}
	SetHudTextParams(0.4, 0.2, 1.0, 2, 2, 252, 1, 0);
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i))continue;
		ShowHudText(i, 1, "Remaining players: %d\nKills: %d", iAlivePlayers, g_Kills[i]);
	}
}
