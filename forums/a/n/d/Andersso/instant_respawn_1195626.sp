//	============================================================================
//	DoD:S - Instant Respawn
//
//	By: Andersso
//	============================================================================
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.4"

public Plugin:myinfo =
{
	name = "DoD:S Instant Respawn",
	author = "Andersso",
	description = "Instantly respawn players after death.",
	version = PL_VERSION,
	url = "http://www.europeanmarines.eu/"
};

new bool:g_bMaxPlayers;

new g_iDesiredPlayerClass;

new Handle:g_hGameConfig;
new Handle:g_hPlayerRespawn;

new Handle:g_hConVar_Delay;
new Handle:g_hConVar_Enabled;
new Handle:g_hConVar_MaxPlayers;
new Handle:g_hConVar_SelectClass;

public OnPluginStart()
{
	AutoExecConfig(true, "instant_respawn", "instantrespawn_config");
	
	g_hGameConfig = LoadGameConfigFile("plugin.instantrespawn");
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "DODRespawn");

	if ((g_hPlayerRespawn = EndPrepSDKCall()) == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Unable to find signature \"DODRespawn\"!");
	}
	
	if ((g_iDesiredPlayerClass = FindSendPropInfo("CDODPlayer", "m_iDesiredPlayerClass")) == -1)
	{
		SetFailState("Fatal Error: Unable to find offset \"m_iDesiredPlayerClass\"!");
	}
	
	CreateConVar("sm_instantrespawn_version", PL_VERSION, "DoD:S Instant Respawn version.", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED);
	
	g_hConVar_Delay        = CreateConVar("sm_instantrespawn_delay",       "0.1", "Respawn Delay", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.1, true, 4.0);
	g_hConVar_Enabled      = CreateConVar("sm_instantrespawn_enabled",     "1",   "Enable/Disable Instant Respawn", FCVAR_NOTIFY|FCVAR_PLUGIN);
	g_hConVar_MaxPlayers   = CreateConVar("sm_instantrespawn_maxplayers",  "14",  "Disable Instant Respawn if the client count exceed this value. (0 = Disabled)", FCVAR_NOTIFY|FCVAR_PLUGIN);
	g_hConVar_SelectClass  = CreateConVar("sm_instantrespawn_selectclass", "1",   "Enable/Disable Instant Respawn after you have selected class.", FCVAR_NOTIFY|FCVAR_PLUGIN);
	
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_changeclass", Event_PlayerChangeClass);
}

public OnClientConnected(iClient)
{
	if (!g_bMaxPlayers && GetClientCount() > GetConVarInt(g_hConVar_MaxPlayers))
	{
		g_bMaxPlayers = true;
	}
}

public OnClientDisconnect_Post(iClient)
{
	if (g_bMaxPlayers && GetClientCount() <= GetConVarInt(g_hConVar_MaxPlayers))
	{
		g_bMaxPlayers = false;
	}
}

public Action:Event_PlayerDeath(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (GetConVarBool(g_hConVar_Enabled) && (GetConVarInt(g_hConVar_MaxPlayers) <= 0 || !g_bMaxPlayers))
	{
		CreateTimer(GetConVarFloat(g_hConVar_Delay), Timer_RespawnPlayer, GetEventInt(hEvent, "userid"), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Timer_RespawnPlayer(Handle:hTimer, any:iClient)
{
	if ((iClient = GetClientOfUserId(iClient)) != 0)
	{
		RespawnPlayer(iClient);
	}
}

public Action:Event_PlayerChangeClass(Handle:hEvent, const String:szName[], bool:bDontBroadcast)
{
	if (GetConVarBool(g_hConVar_Enabled) && GetConVarBool(g_hConVar_SelectClass))
	{
		new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		
		if (!IsPlayerAlive(iClient))
		{
			RespawnPlayer(iClient);
		}
	}
}

RespawnPlayer(iClient)
{
	if (GetEntData(iClient, g_iDesiredPlayerClass) != -1)
	{
		SDKCall(g_hPlayerRespawn, iClient);
	}
}
