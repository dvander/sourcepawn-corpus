#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>

#define PLUGIN_AUTHOR	"tuty"
#define PLUGIN_VERSION	"1.1"

#pragma semicolon 1

new Handle:gBombEvents = INVALID_HANDLE;
new Handle:gBombPlanted = INVALID_HANDLE;
new Handle:gBombDefused = INVALID_HANDLE;
new Handle:gBombPlanting = INVALID_HANDLE;
new Handle:gBombExploded = INVALID_HANDLE;
new Handle:gBombAbort = INVALID_HANDLE;
new Handle:gBombPickUp = INVALID_HANDLE;
new Handle:gBombDropped = INVALID_HANDLE;
new Handle:gBombDefusing = INVALID_HANDLE;
new Handle:gBombAbortDef = INVALID_HANDLE;
new Handle:gPrintType = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Bomb Events",
	author = PLUGIN_AUTHOR,
	description = "Bomb events. Show when a player planted ... defused the bomb.",
	version = PLUGIN_VERSION,
	url = "www.sourcemod.net"
};
public OnPluginStart()
{
	gBombEvents = CreateConVar( "be_enabled", "1" );
	CreateConVar( "bombevents_version", PLUGIN_VERSION, "Bomb Events", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY );
	
	if( GetConVarInt( gBombEvents ) != 0 )
	{
		HookEvent( "bomb_beginplant", Event_BeginPlant );
		HookEvent( "bomb_abortplant", Event_BombAbort );
		HookEvent( "bomb_planted", Event_BombPlanted );
		HookEvent( "bomb_defused", Event_BombDefused );
		HookEvent( "bomb_exploded", Event_BombExploded );
		HookEvent( "bomb_dropped", Event_BombDropped );
		HookEvent( "bomb_pickup", Event_BombPickup );
		HookEvent( "bomb_begindefuse", Event_BombBeginDefuse );
		HookEvent( "bomb_abortdefuse", Event_BombAbortDefuse );
	
	
		gBombPlanted = CreateConVar( "be_planted", "1" );
		gBombDefused = CreateConVar( "be_defused", "1" );
		gBombPlanting = CreateConVar( "be_planting", "1" );
		gBombExploded = CreateConVar( "be_exploded", "1" );
		gBombAbort = CreateConVar( "be_abort", "1" );
		gBombPickUp = CreateConVar( "be_pickup", "1" );
		gBombDropped = CreateConVar( "be_dropped", "1" );
		gBombDefusing = CreateConVar( "be_defusing", "1" );
		gBombAbortDef = CreateConVar( "be_abortdefuse", "1" );	
		gPrintType = CreateConVar( "be_printtype", "1" ); // 1 hint, 2 chat, 3 center
	}
}
public OnMapStart()
{
	decl String:planted[ 256 ];
	decl String:defused[ 256 ];
	decl String:exploded[ 256 ];

	FormatEx( planted, sizeof( planted ) - 1, "sound/misc/c4powa.wav" );
	FormatEx( defused, sizeof( defused ) - 1, "sound/misc/laugh.wav" );
	FormatEx( exploded, sizeof( exploded ) - 1, "sound/misc/witch.wav" );

	if( FileExists( planted ) && FileExists( defused ) && FileExists( exploded ) )
	{
		AddFileToDownloadsTable( planted );
		AddFileToDownloadsTable( defused );
		AddFileToDownloadsTable( exploded );

		PrecacheSound( "misc/c4powa.wav", true );
		PrecacheSound( "misc/laugh.wav", true );
		PrecacheSound( "misc/witch.wav", true );
	}
}	
public Action:Event_BeginPlant( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gBombPlanting ) == 1 )
	{
		new id = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
		decl String:Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );
		
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintTextToAll( "Warning! %s is planting the BOMB!!", Name );
			case 2:	PrintToChatAll( "\x03Warning! %s is planting the BOMB!!", Name );
			case 3:	PrintCenterTextAll( "Warning! %s is planting the BOMB!!", Name );
		}
	}
}
public Action:Event_BombAbort( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gBombAbort ) == 1 )
	{
		new id = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
		decl String:Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );
		
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintTextToAll( "Oh no! %s has stopped BOMB planting!", Name );
			case 2:	PrintToChatAll( "\x03Oh no! %s has stopped BOMB planting!", Name );
			case 3:	PrintCenterTextAll( "Oh no! %s has stopped BOMB planting!", Name );
		}
	}
}
public Action:Event_BombPlanted( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gBombPlanted ) == 1 )
	{
		new id = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
		decl String:Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );
		
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintTextToAll( "%s has planted the BOMB!", Name );
			case 2:	PrintToChatAll( "\x03%s has planted the BOMB!", Name );
			case 3:	PrintCenterTextAll( "%s has planted the BOMB!", Name );
		}
		EmitSoundToAll( "misc/c4powa.wav" );
	}
}
public Action:Event_BombDefused( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gBombDefused ) == 1 )
	{
		new id = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
		decl String:Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );
		
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintTextToAll( "%s defused the BOMB!", Name );
			case 2:	PrintToChatAll( "\x03%s defused the BOMB!", Name );
			case 3:	PrintCenterTextAll( "%s defused the BOMB!", Name );
		}
		EmitSoundToAll( "misc/laugh.wav" );
	}
}
public Action:Event_BombExploded( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gBombExploded ) == 1 )
	{
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintTextToAll( "BOMB successfully exploded" );
			case 2:	PrintToChatAll( "\x03BOMB successfully exploded" );
			case 3:	PrintCenterTextAll( "BOMB successfully exploded" );
		}
		EmitSoundToAll( "misc/witch.wav" );
	}
}
public Action:Event_BombDropped( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gBombDropped ) == 1 )
	{
		new id = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
		decl String:Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );
		
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintTextToAll( "%s dropped the BOMB!", Name );
			case 2:	PrintToChatAll( "\x03%s dropped the BOMB!", Name );
			case 3:	PrintCenterTextAll( "%s dropped the BOMB!", Name );
		}
	}
}
public Action:Event_BombPickup( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gBombPickUp ) == 1 )
	{
		new id = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
		decl String:Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );
		
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintTextToAll( "%s picked up the BOMB.", Name );
			case 2:	PrintToChatAll( "\x03%s picked up the BOMB.", Name );
			case 3:	PrintCenterTextAll( "%s picked up the BOMB.", Name );
		}
	}
}
public Action:Event_BombBeginDefuse( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gBombDefusing ) == 1 )
	{
		new id = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
		decl String:Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );
		
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintTextToAll( "OMG! %s is defusing the BOMB!!!!", Name );
			case 2:	PrintToChatAll( "\x03OMG! %s is defusing the BOMB!!!!", Name );
			case 3:	PrintCenterTextAll( "OMG! %s is defusing the BOMB!!!!", Name );
		}
	}
}
public Action:Event_BombAbortDefuse( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( GetConVarInt( gBombAbortDef ) == 1 )
	{
		new id = GetClientOfUserId( GetEventInt( event, "userid" ) );
		
		decl String:Name[ 32 ];
		GetClientName( id, Name, sizeof( Name ) - 1 );
		
		switch( GetConVarInt( gPrintType ) )
		{
			case 1:	PrintHintTextToAll( "%s has stoped BOMB defusing!", Name );
			case 2:	PrintToChatAll( "\x03%s has stoped BOMB defusing!", Name );
			case 3:	PrintCenterTextAll( "%s has stoped BOMB defusing!", Name );
		}
	}
}
