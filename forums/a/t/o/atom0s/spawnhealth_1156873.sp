/**
 * SpawnHealth.sp - (c) 2010 atom0s [atom0s@live.com]
 * ====================================================
 * 
 * Sets a players health to the given cvar amount when
 * they spawn.
 * 
 * 
 */
 
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

// Plugin Version
#define PLUGIN_VERSION "1.0.0"

// Plugin Information
public Plugin:myinfo =
{
	name 		= "SpawnHealth",
	author 		= "atom0s",
	description = "Sets clients health to a given cvar value when they spawn.",
	version 	= PLUGIN_VERSION,
	url 		= "N/A"
};

// Health Amount Handle
new Handle:g_HealthAmount;

public OnPluginStart( )
{
	CreateConVar( "spawnhealth_version", PLUGIN_VERSION, "SpawnHealth Version (by atom0s)", FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD );
	g_HealthAmount = CreateConVar( "spawnhealth_amount", "35", "Amount of health for players to spawn with." );
	
	HookEvent( "player_spawn", OnPlayerSpawnEvent );
}

public Action:OnPlayerSpawnEvent( Handle:event, String:name[], bool:dontBroadcast )
{
	new pClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new nHealth = GetConVarInt( g_HealthAmount );
	
	new nHealthOffset = FindSendPropOffs( "CBasePlayer", "m_iHealth" );
	if( nHealthOffset != -1 )
	{
		// Set Health
		SetEntData( pClient, nHealthOffset, nHealth );
	}
	
	return Plugin_Continue;
}