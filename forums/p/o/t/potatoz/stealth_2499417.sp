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

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

bool g_bHideMe[MAXPLAYERS+1] = {false,...};

int g_iPlayerManager,
	g_iConnectedOffset,
	g_iAliveOffset,
	g_iTeamOffset,
	g_iPingOffset,
	g_iScoreOffset,
	g_iDeathsOffset,
	g_iHealthOffset;

ConVar sm_stealth_autoswitch,
	sm_stealth_disable_switch;
	
public Plugin:myinfo = 
{
	name = "Simple Stealth",
	author = "Potatoz",
	description = "",
	version = "1.0",
	url = "http://sourcemod.net"
}

public OnPluginStart()
{	
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	
	RegAdminCmd("sm_stealth", Command_StealthMode, ADMFLAG_ROOT);
	
	sm_stealth_autoswitch = CreateConVar("sm_stealth_autoswitch", "1", "Automatically switch admins to spectators on Stealth?");
	sm_stealth_disable_switch = CreateConVar("sm_stealth_disable_switch", "1", "Disable Stealth Mode on switch to other team? (If autoswitch is enabled)");
	AutoExecConfig(true, "simple_stealth");
	
	g_iConnectedOffset = FindSendPropInfo("CCSPlayerResource", "m_bConnected");
	g_iAliveOffset = FindSendPropInfo("CCSPlayerResource", "m_bAlive");
	g_iTeamOffset = FindSendPropInfo("CCSPlayerResource", "m_iTeam");
	g_iPingOffset = FindSendPropInfo("CCSPlayerResource", "m_iPing");
	g_iScoreOffset = FindSendPropInfo("CCSPlayerResource", "m_iScore");
	g_iDeathsOffset = FindSendPropInfo("CCSPlayerResource", "m_iDeaths");
	g_iHealthOffset = FindSendPropInfo("CCSPlayerResource", "m_iHealth");
}

public OnMapStart()
{
	g_iPlayerManager = FindEntityByClassname(-1, "cs_player_manager");
	if(g_iPlayerManager != -1)
		SDKHook(g_iPlayerManager, SDKHook_ThinkPost, Hook_PMThink);
}

public OnClientDisconnect(int client)
{
	g_bHideMe[client] = false;
}

public Action:Command_StealthMode(int client, int args)
{
	if(!client)
		return Plugin_Handled;
	
	if(!g_bHideMe[client])
	{
		g_bHideMe[client] = true;
		
		if(GetClientTeam(client) != CS_TEAM_SPECTATOR && GetConVarInt(sm_stealth_autoswitch) == 1)
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
	}
	else
		g_bHideMe[client] = false;
		
	return Plugin_Continue;
}

public Action Event_OnPlayerTeam(Handle event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bHideMe[client])
	{
		if(g_bHideMe[client] && GetConVarInt(sm_stealth_disable_switch) == 1 && GetConVarInt(sm_stealth_autoswitch) == 1 && GetClientTeam(client) == CS_TEAM_SPECTATOR)
		g_bHideMe[client] = false;
		
		SetEventBroadcast(event, true);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Hook_PMThink(int entity)
{
	for(int i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && g_bHideMe[i])
		{
			SetEntData(g_iPlayerManager, g_iAliveOffset + (i * 4), false, 4, true);
			SetEntData(g_iPlayerManager, g_iConnectedOffset + (i * 4), false, 4, true);
			SetEntData(g_iPlayerManager, g_iTeamOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iPingOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iScoreOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iDeathsOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iHealthOffset + (i * 4), 0, 4, true);
		}
	}
}

public OnGameFrame()
{
	for(int i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && g_bHideMe[i])
		{
			SetEntData(g_iPlayerManager, g_iAliveOffset + (i * 4), false, 4, true);
			SetEntData(g_iPlayerManager, g_iConnectedOffset + (i * 4), false, 4, true);
			SetEntData(g_iPlayerManager, g_iTeamOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iPingOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iScoreOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iDeathsOffset + (i * 4), 0, 4, true);
			SetEntData(g_iPlayerManager, g_iHealthOffset + (i * 4), 0, 4, true);
		}
	}
}