//	============================================================================
//	DoD:S - Instant Respawn v1.1
//
//	By: Andersso
//	============================================================================

#include <sourcemod>
#include <sdktools>
#pragma semicolon 1

#define Plugin_Version "1.1"

public Plugin:myinfo =
{
	name			= "DoD:S Instant Respawn",
	author		= "Andersso",
	description	= "Instantly respawn players after death.",
	version		= Plugin_Version,
	url			= "http://www.europeanmarines.eu/"
};

new Handle:g_hGameConfig;
new Handle:g_hPlayerRespawn;

new Handle:g_hRespawnDelay;

new bool:g_hIsPlayerJoiningTeam[MAXPLAYERS+1];

//	============================================================================
//	Forwards
//	============================================================================

public OnClientPutInServer(iClient)
{
	g_hIsPlayerJoiningTeam[iClient] = false;
}


public OnPluginStart()
{
	CreateConVar("sm_instantrespawn_version", Plugin_Version, "DoD:S Instant Respawn version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hRespawnDelay = CreateConVar("sm_instantrespawn_delay", "0.1", "Respawn Delay", FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.1, false);
	
	g_hGameConfig = LoadGameConfigFile("plugin.instantrespawn");
	
	if (g_hGameConfig == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Missing File \"plugin.instantrespawn\"!");
	}
	
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(g_hGameConfig, SDKConf_Signature, "DODRespawn");
	g_hPlayerRespawn = EndPrepSDKCall();

	if (g_hPlayerRespawn == INVALID_HANDLE)
	{
		SetFailState("Fatal Error: Unable to find signature for \"CDODPlayer::DODRespawn(void)\"!");
	}
	
	HookEvent("player_death", Event_PlayerDeath);
	
	RegConsoleCmd("jointeam", Command_JoinTeam);
}

//	============================================================================
//	Console Command Hooks
//	============================================================================

public Action:Command_JoinTeam(iClient, iArgs)
{
	g_hIsPlayerJoiningTeam[iClient] = true;
}

//	============================================================================
//	Events
//	============================================================================

public Action:Event_PlayerDeath(Handle:hEvent, const String:sName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (!g_hIsPlayerJoiningTeam[iClient])
	{
		CreateTimer(GetConVarFloat(g_hRespawnDelay), Timer_RespawnPlayer, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		g_hIsPlayerJoiningTeam[iClient] = false;
	}
}

//	============================================================================
//	Timers
//	============================================================================

public Action:Timer_RespawnPlayer(Handle:hTimer, any:iClient)
{
	if (IsClientInGame(iClient))
	{
		SDKCall(g_hPlayerRespawn, iClient);
	}
}
