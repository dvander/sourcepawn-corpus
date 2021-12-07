#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "hAlexr"
#define PLUGIN_VERSION "1.1"

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
ConVar sm_respawn_lives_spawn_kill;
ConVar sm_respawn_lives_all_maps;
ConVar sm_respawn_lives;

char g_szMap[64];
bool g_bEnableMap;

int g_iLivesUsed[MAXPLAYERS + 1];
int g_iSpawnKill[MAXPLAYERS + 1];

bool g_bSpawnKill[MAXPLAYERS + 1];

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
	sm_respawn_lives_spawn_kill = CreateConVar("sm_respawn_lives_spawn_kill", "1", "Check if player is being spawn killed");
	sm_respawn_lives_all_maps = CreateConVar("sm_respawn_lives_all_maps", "0", "Use this plugin on all maps or maps you put in a config");
	sm_respawn_lives = CreateConVar("sm_respawn_lives", "4", "The number of lives a player has.");
	
	RegConsoleCmd("sm_respawnself", cmd_respawn, "Respawns yourself with the lives you have");
	
	HookEvent("player_death", Event_Player_Death);
	HookEvent("round_end", Event_Round_End);
	
	AutoExecConfig(true, "plugin.respawn_lives");
}

public void OnClientDisconnect(int client)
{
	g_iSpawnKill[client] = 0;
	g_bSpawnKill[client] = false;
}

public void OnMapStart()
{
	if(!GetConVarBool(sm_respawn_lives_enable))
		return;
		
	if(!GetConVarBool(sm_respawn_lives_all_maps))
	{
		GetCurrentMap(g_szMap, 64);
		checkMaps();
	}
}

public void OnMapEnd()
{
	if(!GetConVarBool(sm_respawn_lives_enable))
		return;
		
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
	if(!GetConVarBool(sm_respawn_lives_enable) || !g_bEnableMap)
		return Plugin_Handled;
		
	if(!GetConVarBool(sm_respawn_lives_command))
		return Plugin_Handled;
	
	if(!g_bSpawnKill[client])
		respawnPlayer(client);
	return Plugin_Handled;
}

public Action Event_Player_Death(Event action, char[] name, bool useless)
{
	if(!GetConVarBool(sm_respawn_lives_enable) || !g_bEnableMap)
		return Plugin_Handled;
	
	int client = GetClientOfUserId(GetEventInt(action, "userid"));
	
	if(GetConVarBool(sm_respawn_lives_spawn_kill))
	{
		g_iSpawnKill[client]++;
		CreateTimer(2.0, check_spawn_kill, client);
	}
	
	if(!GetConVarBool(sm_respawn_lives_command))
		if(!g_bSpawnKill[client])
			respawnPlayer(client);
		
	return Plugin_Handled;
}

public Action Event_Round_End(Event action, char[] name, bool useless)
{
	if(!GetConVarBool(sm_respawn_lives_enable) || !g_bEnableMap)
		return Plugin_Handled;
	
	if(!GetConVarBool(sm_respawn_lives_reset))
		return Plugin_Handled;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			g_iLivesUsed[i] = 0;
		g_bSpawnKill[i] = false;
	}
	return Plugin_Handled;
}

public Action check_spawn_kill(Handle timer, int client)
{
	if(!GetConVarBool(sm_respawn_lives_enable) || !g_bEnableMap)
		return Plugin_Handled;
	if(g_iSpawnKill[client] != 1)
	{
		g_bSpawnKill[client] = true;
		g_iSpawnKill[client] = 0;
	}
	else g_iSpawnKill[client] = 0;
	return Plugin_Handled;
}

void respawnPlayer(int client)
{
	if(!GetConVarBool(sm_respawn_lives_enable) || !g_bEnableMap || IsPlayerAlive(client))
		return;
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
		PrintToChat(client, "[\x06SM\x01] You have no more lives left.", GetConVarInt(sm_respawn_lives) - g_iLivesUsed[client]);
	}
}

void checkMaps()
{
	if(!GetConVarBool(sm_respawn_lives_enable))
		return;
		
	char line[120], g_szConfig[PLATFORM_MAX_PATH];
	
	BuildPath(Path_SM, g_szConfig, sizeof(g_szConfig), "configs/ar_respawn_maps.cfg");
	
	Handle g_hKV = OpenFile(g_szConfig, "r");
	
	if (g_hKV != INVALID_HANDLE)
	{
		while (!IsEndOfFile(g_hKV))
		{
			ReadFileLine(g_hKV, line, 120);
			
			if (StrEqual(line, g_szMap, true))
			{
				g_bEnableMap = true;
				CloseHandle(g_hKV);
				return;
			}
		}
		g_bEnableMap = false;
		CloseHandle(g_hKV);
			
	} else {
		PrintToServer("[SM] Could not find config (configs/ar_respawn_maps.cfg)");
	}
}
