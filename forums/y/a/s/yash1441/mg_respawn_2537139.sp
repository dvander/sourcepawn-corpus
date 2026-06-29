#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Simon"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

bool AllowRespawn = false;
Handle Timer_1 = INVALID_HANDLE;
Handle g_hRespawn = INVALID_HANDLE;
float g_Respawn;

EngineVersion g_Game;

public Plugin myinfo = 
{
	name = "MG Respawn",
	author = PLUGIN_AUTHOR,
	description = "Respawn available for X seconds.",
	version = PLUGIN_VERSION,
	url = "yash1441@yahoo.com"
};

public OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	CreateConVar("mg_respawn_version", PLUGIN_VERSION, "MG Respawn Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hRespawn = CreateConVar("mg_respawn_time", "15", "Time in seconds to allow auto respawn.", FCVAR_NOTIFY);
	g_Respawn = GetConVarFloat(g_hRespawn);
	HookConVarChange(g_hRespawn, OnConVarChanged);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
}

public OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_Respawn = GetConVarFloat(g_hRespawn);
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	AllowRespawn = true;
	Timer_1 = CreateTimer(g_Respawn, ToggleAllow, _, _);
}

public Action Event_RoundEnd(Handle event, const char[] name, bool dontBroadcast)
{
	ClearTimer(Timer_1);
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (AllowRespawn)
		CS_RespawnPlayer(client);
}

public Action ToggleAllow(Handle timer)
{
	AllowRespawn = false;
}

public void ClearTimer(&Handle timer)
{
	if (timer != null)
	{
		KillTimer(timer);
		timer = null;
	}
}