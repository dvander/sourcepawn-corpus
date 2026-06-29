#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_EXTENSIONS
#undef REQUIRE_PLUGIN
#if !defined STANDALONE_BUILD
#include <tf2_stocks>
#endif
//#include <sdkhooks>

#pragma newdecls required

EngineVersion g_Game;

ConVar sm_hp_enable;
ConVar sm_hp_enable_chat;
ConVar sm_hp_over_100;
ConVar sm_hp_on_bot_kill;
ConVar sm_hp_on_team_kill;
ConVar sm_hp_on_hs;
ConVar sm_hp_on_kill;

public Plugin myinfo = 
{
	name = "HP on kill",
	author = PLUGIN_AUTHOR,
	description = "Gives player HP on kills",
	version = PLUGIN_VERSION,
	url = "www.trugamingcs.tk"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	
	sm_hp_enable = CreateConVar("sm_hp_enable", "1", "Enables or disables the plugin", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_hp_enable_chat = CreateConVar("sm_hp_enable_chat", "1", "Enables or disables chat messages", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_hp_on_bot_kill = CreateConVar("sm_hp_on_bot_kill", "1", "Enables or disables giving HP on bot kill", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_hp_over_100 = CreateConVar("sm_hp_over_100", "0", "Enables or disables giving HP over 100", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_hp_on_team_kill = CreateConVar("sm_hp_on_team_kill", "0", "Enables or disables giving HP on team kill", FCVAR_NONE, true, 0.0, true, 1.0);
	sm_hp_on_hs = CreateConVar("sm_hp_on_hs", "15", "The amount of HP to give the attacker for a headshot", FCVAR_NONE, true, 0.0, true, 100.0);
	sm_hp_on_kill = CreateConVar("sm_hp_on_kill", "10", "The amount of HP to give the attacker for a kill", FCVAR_NONE, true, 0.0, true, 100.0);
	
	HookEvent("player_death", playerDeath);
}

public Action playerDeath(Event event, char[] name, bool useless)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if(!GetConVarBool(sm_hp_enable))
		return Plugin_Handled;
	
	if(!GetConVarBool(sm_hp_on_bot_kill) && !IsValidClient(client))
		return Plugin_Handled;
		
	if (client == target)
		return Plugin_Handled;
	
	if(g_Game == Engine_TF2 && !GetConVarBool(sm_hp_on_team_kill) && TF2_GetClientTeam(client) == TF2_GetClientTeam(target))
	return Plugin_Handled;
	
	else if (g_Game != Engine_TF2 && !GetConVarBool(sm_hp_on_team_kill) && GetClientTeam(client) == GetClientTeam(target))
	return Plugin_Handled;
	
	
	if (GetEventBool(event, "headshot"))
	{
		if(!IsValidClient(target))
		return Plugin_Handled;
		
		int health = GetClientHealth(target) + GetConVarInt(sm_hp_on_hs);
		
		if(GetConVarBool(sm_hp_over_100) && health >= 100)
		SetEntityHealth(target, health);
		else if(GetConVarBool(sm_hp_over_100) && health < 100)
		SetEntityHealth(target, health);
		else if(!GetConVarBool(sm_hp_over_100) && health >= 100)
		SetEntityHealth(target, 100);
		else if(!GetConVarBool(sm_hp_over_100) && health < 100)
		SetEntityHealth(target, health);
		
		if(GetConVarBool(sm_hp_enable_chat) && !(!GetConVarBool(sm_hp_over_100) && health >= 100))
		{
			char clientName[64];
			GetClientName(client, clientName, 64);
			PrintToChat(target, "[\x06SM\x01] You have been given %i HP for killing %s with a headshot", GetConVarInt(sm_hp_on_hs), clientName);
		}
		
	} else {
		if(!IsValidClient(target))
		return Plugin_Handled;
		
		int health = GetClientHealth(target) + GetConVarInt(sm_hp_on_kill);
		
		if(GetConVarBool(sm_hp_over_100) && health >= 100)
		SetEntityHealth(target, health);
		else if(GetConVarBool(sm_hp_over_100) && health < 100)
		SetEntityHealth(target, health);
		else if(!GetConVarBool(sm_hp_over_100) && health >= 100)
		SetEntityHealth(target, 100);
		else if(!GetConVarBool(sm_hp_over_100) && health < 100)
		SetEntityHealth(target, health);
		
		if(GetConVarBool(sm_hp_enable_chat) && !(!GetConVarBool(sm_hp_over_100) && health >= 100))
		{
			char clientName[64];
			GetClientName(client, clientName, 64);
			PrintToChat(target, "[\x06SM\x01] You have been given %i HP for killing %s with a headshot", GetConVarInt(sm_hp_on_kill), clientName);
		}
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client)
{
	if (client < 1 || client > MaxClients)
		return false;
	if (!IsClientConnected(client))
		return false;
	if (!IsClientInGame(client))
		return false;
	if (IsFakeClient(client))
		return false;
	
	return true;
} 
