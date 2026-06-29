#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

new bool:g_bHideMe[MAXPLAYERS+1] = {false,...};

new g_iPlayerManager;
new g_iConnectedOffset;
new g_iAliveOffset;
new g_iTeamOffset;
new g_iPingOffset;
new g_iScoreOffset;
new g_iDeathsOffset;
new g_iHealthOffset;

public Plugin:myinfo = 
{
	name = "Simple Stealth",
	author = "Potatoz",
	description = "",
	version = "1.0",
	url = "http://sourcemod.net"
}

ConVar sm_stealth_autoswitch = null;
ConVar sm_stealth_disable_switch = null;

public OnPluginStart()
{	
	HookEvent("player_team", Event_OnPlayerTeam, EventHookMode_Pre);
	
	RegAdminCmd("sm_stealth", Command_StealthMode, ADMFLAG_BAN);
	
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
	{
		SDKHook(g_iPlayerManager, SDKHook_ThinkPost, Hook_PMThink);
	}
}

public OnClientDisconnect(client)
{
	g_bHideMe[client] = false;
}

public Action:Command_StealthMode(client, args)
{
	if(!client)
		return Plugin_Handled;
	
	if(!g_bHideMe[client])
	{
		g_bHideMe[client] = true;
		
		if(GetClientTeam(client) != CS_TEAM_SPECTATOR && GetConVarInt(sm_stealth_autoswitch) == 1)
		{
			ChangeClientTeam(client, CS_TEAM_SPECTATOR);
		}
		SDKHook(client, SDKHook_SetTransmit, Hook_Transmit);
	}
	else
	{
		g_bHideMe[client] = false;
		SDKUnhook(client, SDKHook_SetTransmit, Hook_Transmit);
	}
		
	return Plugin_Continue;
}

public Action:Hook_Transmit(entity, client)  
{  
    if (entity != client)  
        return Plugin_Handled; 
      
    return Plugin_Continue;
}  

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(g_bHideMe[client])
	{
		if(g_bHideMe[client] && GetConVarInt(sm_stealth_disable_switch) == 1 && GetConVarInt(sm_stealth_autoswitch) == 1 && GetClientTeam(client) == CS_TEAM_SPECTATOR)
		g_bHideMe[client] = false;
		SDKUnhook(client, SDKHook_SetTransmit, Hook_Transmit);
		
		SetEventBroadcast(event, true);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public Hook_PMThink(entity)
{
	for(new i=1;i<=MaxClients;i++)
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
	for(new i=1;i<=MaxClients;i++)
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