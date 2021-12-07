/*                                                        
 * 		    Copyright (C) 2018 Adam "Potatoz" Ericsson
 * 
 * 	This program is free software: you can redistribute it and/or modify it
 * 	under the terms of the GNU General Public License as published by the Free
 * 	Software Foundation, either version 3 of the License, or (at your option) 
 * 	any later version.
 *
 * 	This program is distributed in the hope that it will be useful, but WITHOUT 
 * 	ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS 
 * 	FOR A PARTICULAR PURPOSE. See the GNU General Public License for more details.
 *
 * 	See http://www.gnu.org/licenses/. for more information
 */

#include <sourcemod>
#include <sdktools>
#include <cstrike>

bool IsAutorespawnEnabled = true;
ConVar sm_autorespawn_time = null,
sm_autorespawn_spawnkilldetection = null;
Handle slaytimer[MAXPLAYERS+1], respawntimer[MAXPLAYERS+1], spawnkill[MAXPLAYERS+1];
int deathcount[MAXPLAYERS+1];

Handle timerz = null;

public Plugin:myinfo = 
{
	name = "Auto Respawn",
	author = "Potatoz",
	description = "Auto-respawn plugin for Minigames",
	version = "1.2",
	url = "http://steamcommunity.com/id/steampotatoz"
};

public OnPluginStart()
{	
	sm_autorespawn_time = CreateConVar("sm_autorespawn_time", "85", "Amount of time to keep auto-respawn on before disabling? Default = 85");
	sm_autorespawn_spawnkilldetection = CreateConVar("sm_autorespawn_spawnkilldetection", "1", "Enable spawnkill-detection? 0 = Disable");
	AutoExecConfig(true, "autorespawn");

	AddCommandListener(OnJoinTeam, "jointeam");
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Post);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	IsAutorespawnEnabled = true;
}

public Action Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsAutorespawnEnabled && IsPlayerAlive(client))
		slaytimer[client] = CreateTimer(0.5, SlayClient, client);
}

public Action SlayClient(Handle timer, any client)
{
	if(!IsAutorespawnEnabled && IsPlayerAlive(client))
	ForcePlayerSuicide(client);
	
	slaytimer[client] = null;
}

public Action RespawnClient(Handle timer, int userid)
{
	int client = GetClientOfUserId(userid);
	if(client == 0) return;
	
	if(IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1 && IsAutorespawnEnabled) 
		CS_RespawnPlayer(client)
		
	respawntimer[client] = null;
}

public Action OnJoinTeam(int client, const char[] command, int numArgs)
{
	if (!IsClientInGame(client) || numArgs < 1) return Plugin_Continue;

	if(!IsPlayerAlive(client) && IsAutorespawnEnabled)
		respawntimer[client] = CreateTimer(1.5, RespawnClient, client);

	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	respawntimer[client] = null;
	slaytimer[client] = null;
}

public Action DisableRespawn(Handle timer)
{
	if(IsAutorespawnEnabled && timerz != null) {
		IsAutorespawnEnabled = false;
		PrintToChatAll(" \x07* \x01Auto-respawn: \x07Disabled");
		timerz = null;
	}
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	IsAutorespawnEnabled = true;
	timerz = null;
	
	PrintToChatAll(" \x04* \x01Auto-respawn: \x04Enabled");
	timerz = CreateTimer(GetConVarFloat(sm_autorespawn_time), DisableRespawn);
}

public Action SpawnKillDetection(Handle timer, any client)
{
	if(deathcount[client] == 3 && IsAutorespawnEnabled) {
		IsAutorespawnEnabled = false;
		PrintToChatAll(" \x07* \x01Auto-respawn: \x07Disabled");
	}
	
	deathcount[client] = 0;
	spawnkill[client] = null;
}

public Action Event_PlayerDeath(Handle event, const char[] name, bool dontBroadcast)
{
	
	if (!IsAutorespawnEnabled)
		return;
		
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	respawntimer[client] = CreateTimer(0.1, RespawnClient, client);
		
	if(GetConVarInt(sm_autorespawn_spawnkilldetection) == 0)
		return;
	
	if(deathcount[client] < 1)
	spawnkill[client] = CreateTimer(2.0, SpawnKillDetection, client);
		
	deathcount[client]++;
}
