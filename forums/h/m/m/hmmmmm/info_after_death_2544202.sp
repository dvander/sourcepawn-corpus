#include <sourcemod>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

ConVar g_cvEnable;
ConVar g_cvTime;
ConVar g_cvMessage;

bool g_bPlayerMuted[MAXPLAYERS + 1];

public Plugin myinfo =
{
	name = "Info after death",
	author = "hAlexr",
	description = "Allows players to speak to teammates for limited time after death",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart(  )
{
	/* CONVARS */
	g_cvEnable = CreateConVar( "iad_enable", "1", "Enables or disables the plugin", _, true, 0.0, true, 1.0 );
	g_cvTime = CreateConVar( "iad_time", "10.0", "Time until player is muted", _, true, 0.1, true, 20.0 );
	g_cvMessage = CreateConVar( "iad_message", "1", "Enable or disable chat message", _, true, 0.0, true, 1.0 );
	AutoExecConfig( true, "InfoAfterDeath" );
	
	/* HOOKS */
	HookEvent( "player_death", Event_PlayerDeath );
	HookEvent( "player_spawn", Event_PlayerSpawn );
	HookEvent( "player_team", Event_PlayerTeam );
	HookEvent( "round_end", Event_RoundEnd );
}

public void OnClientDisconnect( int client )
{
	g_bPlayerMuted[client] = false;
}

public Action Event_PlayerDeath( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_cvEnable.BoolValue )
		return;
	
	int userid = event.GetInt( "userid" );
	int client = GetClientOfUserId( userid );
	
	if( g_cvMessage.BoolValue )
	{
		PrintToChat( client, "[SM] You have %.1f seconds to speak to your teammates!", g_cvTime.FloatValue );
	}
	
	CreateTimer( g_cvTime.FloatValue, Timer_Mute, event.GetInt( "userid" ) );
}

public Action Event_PlayerTeam( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_cvEnable.BoolValue )
		return;
	
	UnmuteClient( GetClientOfUserId( event.GetInt( "userid" ) ) );
}

public Action Event_PlayerSpawn( Event event, const char[] name, bool dontBroadcast )
{
	if ( !g_cvEnable.BoolValue )
		return;
	
	UnmuteClient( GetClientOfUserId( event.GetInt( "userid" ) ) );
}

public Action Event_RoundEnd( Event event, const char[] name, bool dontBroadcast )
{
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientConnected( i ) && IsClientInGame( i ) )
		{
			UnmuteClient( i );
		}
	}
}

public Action Timer_Mute( Handle timer, int userid )
{
	if ( !g_cvEnable.BoolValue )
		return;
	
	MuteClient( GetClientOfUserId( userid ) );
}

void MuteClient( int client )
{
	if( IsClientConnected( client ) && IsClientInGame( client ) && !IsPlayerAlive( client ) )
	{
		g_bPlayerMuted[client] = true;
		int clientTeam = GetClientTeam( client );
		
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientConnected( i ) && IsClientInGame( i ) && i != client && IsPlayerAlive( i ) )
			{
				if ( clientTeam == GetClientTeam( i ) )
				{
					SetListenOverride( i, client, Listen_No );
				}
			}
		}
		
		if( g_cvMessage.BoolValue )
			PrintToChat(client, "[SM] Times up! You can no longer speak to your teammates.");
	}
}

void UnmuteClient( int client )
{
	if( !g_bPlayerMuted[client] )
		return;
		
	if ( IsClientConnected( client ) && IsClientInGame( client ) )
	{
		g_bPlayerMuted[client] = false;
		
		for( int i = 1; i <= MaxClients; i++ )
		{
			if( IsClientConnected( i ) && IsClientInGame( i ) && i != client )
			{
				SetListenOverride( i, client, Listen_Default );
			}
		}
	}
}