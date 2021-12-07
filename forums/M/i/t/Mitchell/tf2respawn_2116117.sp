#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION		"1.0.0"
new Handle:sv_tags = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Instant Instant Respawn",
	author = "Mitch",
	description = "",
	version = PLUGIN_VERSION,
	url = "http://snbx.info/"
}

public OnPluginStart()
{
	CreateConVar( "sm_instant_instant_respawn_version", PLUGIN_VERSION, "TF2 Respawn Time Override plugin version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY );
	HookEvent( "player_death", OnPlayerDeath );
	sv_tags = FindConVar( "sv_tags" );
}

public OnConfigsExecuted()
{
	AddTag( "norespawntime" );
}

public OnPlayerDeath( Handle:hEvent, const String:strEventName[], bool:bDontBroadcast )
{
	new iUserID = GetEventInt( hEvent, "userid" );
	new iClient = GetClientOfUserId( iUserID );
	if( !( 0 < iClient <= MaxClients ) )
		return;

	if( !IsValidClient( iClient ) )
		return;

	if( ( GetEventInt( hEvent, "death_flags" ) & TF_DEATHFLAG_DEADRINGER ) == TF_DEATHFLAG_DEADRINGER )
		return;

	TF2_RespawnPlayer( iClient );
}

stock AddTag( const String:strTag[] )
{
	if( sv_tags == INVALID_HANDLE )
		return;
	decl String:strBuffer[576], String:strOldTags[24][24], String:strNewTags[24][24];
	GetConVarString( sv_tags, strBuffer, sizeof( strBuffer ) );
	new nTags = ExplodeString( strBuffer, ",", strOldTags, sizeof( strOldTags ), sizeof( strOldTags[] ) );
	for( new n = 1, o = 0; o < nTags; o++ )
	{
		if( n >= 24 || StrEqual( strOldTags[o], strTag, false ) )
			return;
		strcopy( strNewTags[n++], sizeof( strNewTags[] ), strOldTags[o] );
	}
	strcopy( strNewTags[0], sizeof( strNewTags[] ), strTag );
	ImplodeStrings( strNewTags, sizeof( strNewTags ), ",", strBuffer, sizeof( strBuffer ) );
	SetConVarString( sv_tags, strBuffer );
}

stock bool:IsValidClient( iClient )
{
	if( iClient <= 0 ) return false;
	if( iClient > MaxClients ) return false;
	if( !IsClientConnected(iClient) ) return false;
	if( !IsClientInGame(iClient) ) return false;
	return true;
}