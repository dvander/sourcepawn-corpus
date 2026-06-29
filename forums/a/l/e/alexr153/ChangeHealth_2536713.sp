#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

#pragma newdecls required

EngineVersion g_Game;
ConVar sm_health_before;
ConVar sm_health_after;
ConVar sm_health_timer;

public Plugin myinfo = 
{
	name = "Change clients health",
	author = PLUGIN_AUTHOR,
	description = "Sets a clients health on spawn then changes back to full",
	version = PLUGIN_VERSION,
	url = "crypto-gaming.tk"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	sm_health_before = CreateConVar("sm_health_before", "20", "Sets the client health before the timer");
	sm_health_after = CreateConVar("sm_health_after", "100", "Sets the clients health after the timer");
	sm_health_timer = CreateConVar("sm_health_timer", "7.0", "The timer");
	
	HookEvent("player_spawn", Player_Spawn);
}

public Action Player_Spawn(Handle event, char[] name, bool useless)
{
	int client = GetClientOfUserId(GetEventInt(event,"userid"));
	SetEntityHealth(client, GetConVarInt(sm_health_before));
	CreateTimer(GetConVarFloat(sm_health_timer), changeHealthBack, client);
}

public Action changeHealthBack(Handle timer, int client)
{
	if(GetClientHealth(client) == GetConVarInt(sm_health_before))
		SetEntityHealth(client, GetConVarInt(sm_health_after));
}

