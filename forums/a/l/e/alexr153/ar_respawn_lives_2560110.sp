#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
//#include <sdkhooks>

#pragma newdecls required

EngineVersion g_Game;

ConVar sm_respawn_lives_enable;
ConVar sm_respawn_lives_command;
ConVar sm_respawn_lives_reset;
ConVar sm_respawn_lives_chat;
ConVar sm_respawn_lives;

int g_iLivesUsed[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Respawn lives",
	author = PLUGIN_AUTHOR,
	description = "Respawns players based on the number of lives they have",
	version = PLUGIN_VERSION,
	url = "www.trugamingcs.tk"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	sm_respawn_lives_enable = CreateConVar("sm_respawn_lives_enable", "1", "Enable or disables the plugin");
	sm_respawn_lives_command = CreateConVar("sm_respawn_lives_command", "1", "Enables the use of a command to respawn yourself");
	sm_respawn_lives_reset = CreateConVar("sm_respawn_lives_reset", "1", "(1) Resets lives used on round end (0) Resets on map end");
	sm_respawn_lives_chat = CreateConVar("sm_respawn_lives_chat", "1", "Allow chat feedback on respawn");
	sm_respawn_lives = CreateConVar("sm_respawn_lives", "4", "The number of lives a player has.");
	
	RegConsoleCmd("sm_respawnself", cmd_respawn, "Respawns yourself with the lives you have");
	
	HookEvent("player_death", Event_Player_Death);
	HookEvent("round_end", Event_Round_End);
	
	AutoExecConfig(true, "plugin.respawn_lives");
}

public void OnMapEnd()
{
	if(!GetConVarBool(sm_respawn_lives_reset))
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
				g_iLivesUsed[i] = 0;
		}
	}
}

public Action cmd_respawn(int client, int args)
{
	if(!GetConVarBool(sm_respawn_lives_command))
		return Plugin_Handled;
	
	respawnPlayer(client);
	return Plugin_Handled;
}

public Action Event_Player_Death(Event action, char[] name, bool useless)
{
	if(!GetConVarBool(sm_respawn_lives_enable))
		return Plugin_Handled;
	
	int client = GetClientOfUserId(GetEventInt(action, "userid"));
	
	if(!GetConVarBool(sm_respawn_lives_command))
		respawnPlayer(client);
		
	return Plugin_Handled;
}

public Action Event_Round_End(Event action, char[] name, bool useless)
{
	if(!GetConVarBool(sm_respawn_lives_reset))
		return Plugin_Handled;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			g_iLivesUsed[i] = 0;
	}
	return Plugin_Handled;
}

void respawnPlayer(int client)
{
	g_iLivesUsed[client]++;
	
	if(g_iLivesUsed[client] <= GetConVarInt(sm_respawn_lives))
	{
		if(IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
		{
			CS_RespawnPlayer(client);
			if(GetConVarBool(sm_respawn_lives_chat))
			PrintToChat(client, "[\x06SM\x01] You have been respawned. Lives left: \x06%i\x01", GetConVarInt(sm_respawn_lives) - g_iLivesUsed[client]);
		}
	} else {
		if(GetConVarBool(sm_respawn_lives_chat))
		PrintToChat(client, "[SM] You have no more lives left.", GetConVarInt(sm_respawn_lives) - g_iLivesUsed[client]);
	}
}
