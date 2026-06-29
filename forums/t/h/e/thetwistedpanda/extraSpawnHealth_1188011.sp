#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PLUGIN_VERSION "1.0"

new g_iHealth;
new Handle:g_isEnabled = INVALID_HANDLE;
new Handle:g_healthAmount = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Spawn w/ Increased Health", 
	author = "Twisted|Panda", 
	description = "Allows you to increase the amount of health players spawn with.", 
	version = PLUGIN_VERSION, 
	url = "http://forums.alliedmods.com"
}

public OnPluginStart ()
{
	g_isEnabled  = CreateConVar("sm_spawnhealth_enabled", "1", "If enabled, players will spawn with the amount of health specified by the sm_spawnhealth_amount variable.");
	g_healthAmount  = CreateConVar("sm_spawnhealth_amount", "100", "The amount of health you wish for players to spawn with (try to keep this above 1 okay?)");

	g_iHealth = FindSendPropOffs("CCSPlayer", "m_iHealth");
	if (g_iHealth == -1)
		SetFailState("Unable to get offset for CSSPlayer::m_iHealth");	
	
	HookEvent("player_spawn", OnPlayerSpawn);
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_isEnabled) == 1)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		CreateTimer(0.0, setPlayerHealth, client);
	}
}

public Action:setPlayerHealth(Handle:timer, any:client)
{
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntData(client, g_iHealth, GetConVarInt(g_healthAmount));
	}
}