#define PLUGIN_VERSION "1.0.0"

#include <sdktools>

#pragma newdecls required

public Plugin myinfo =
{
	name = "HL2DM AfkToSpec",
	author = "RedSword",
	description = "Move an AFK to Spec after a certain amount of time",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

Handle g_hTimeBeforeOtherCheck;

bool g_bCanCheckPlayer[ MAXPLAYERS + 1 ];

float g_fPositions[ MAXPLAYERS + 1 ][ 3 ];
float g_fEyesAngles[ MAXPLAYERS + 1 ][ 3 ];

public void OnPluginStart()
{
	CreateConVar( "hl2dmafktospec", PLUGIN_VERSION, "HL2DM Afk To Spec version.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	g_hTimeBeforeOtherCheck = CreateConVar( "hl2dma2s_time_2ndcheck", "60.0", "Time after first check to check if a player moved", FCVAR_PLUGIN, true, 0.0 );
	
	RegAdminCmd( "sm_whatismyteam", Command_TellClientTeam, ADMFLAG_BAN, "sm_whatismyteam");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
}
public Action Command_TellClientTeam(int client, int args)
{
	if ( client == 0 )
		ReplyToCommand( client, "You need to be in game" );
	
	ReplyToCommand( client, "Your team is %d", GetClientTeam( client ) );
}
public void OnMapStart()
{
	for ( int i; i <= MaxClients; ++i )
		g_bCanCheckPlayer[ i ] = true;
}

public void OnClientConnected(int iClient)
{
	g_bCanCheckPlayer[ iClient ] = true;
}

public void Event_PlayerSpawn(Handle event, const char[] name, bool dontBroadcast)
{
	int iUserId = GetEventInt( event, "userid" )
	int iClient = GetClientOfUserId( iUserId );
	
	if ( g_bCanCheckPlayer[ iClient ] == true )
	{
		CreateTimer( 1.0, Timer_FirstCheck, iUserId );
		g_bCanCheckPlayer[ iClient ] = false;
	}
}

public Action Timer_FirstCheck( Handle timer, int userId )
{
	int clientId = GetClientOfUserId( userId );
	
	if ( clientId == 0 )
		return;
	
	saveStuff( clientId );
	
	CreateTimer( GetConVarFloat( g_hTimeBeforeOtherCheck ), Timer_SecondCheck, userId );
}
public Action Timer_SecondCheck( Handle timer, int userId )
{
	int clientId = GetClientOfUserId( userId );
	
	if ( clientId == 0 )
		return;
	
	checkStuff( clientId );
}
void saveStuff(int clientId)
{
	GetClientAbsOrigin( clientId, g_fPositions[ clientId ] );
	GetClientEyeAngles( clientId, g_fEyesAngles[ clientId ] );
}
void checkStuff(int clientId)
{
	float vecPos[3];
	float vecAngle[3];
	
	GetClientAbsOrigin( clientId, vecPos );
	GetClientEyeAngles( clientId, vecAngle );
	
	if ( areEquals( vecPos, g_fPositions[ clientId ] ) == false || areEquals( vecAngle, g_fEyesAngles[ clientId ] ) )
	{
		ChangeClientTeam( clientId, 1 );
		PrintToChat( clientId, "[SM] You're being placed to spectator because you're blocking the spawn :@ !!" );
	}
}

bool areEquals( const float vec1[3], const float vec2[3] )
{
	return vec1[0] == vec2[0] && vec1[1] == vec2[1] && vec1[2] == vec2[2];
}