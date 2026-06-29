#include <sourcemod>
#include <sdktools>
#include <colors>
#include <csgocolors>

#define PLUGIN_AUTHOR    "tuty"
#define PLUGIN_VERSION    "1.1"

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
    
    
        gBombPlanted = CreateConVar( "be_planted", "0" );
        gBombDefused = CreateConVar( "be_defused", "0" );
        gBombPlanting = CreateConVar( "be_planting", "0" );
        gBombExploded = CreateConVar( "be_exploded", "0" );
        gBombAbort = CreateConVar( "be_abort", "1" );
        gBombPickUp = CreateConVar( "be_pickup", "1" );
        gBombDropped = CreateConVar( "be_dropped", "1" );
        gBombDefusing = CreateConVar( "be_defusing", "0" );
        gBombAbortDef = CreateConVar( "be_abortdefuse", "1" );    
        gPrintType = CreateConVar( "be_printtype", "2" ); // 1 hint, 2 chat, 3 center
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
            case 1:    PrintHintTextToAll( "{purple}Warning{normal}! {green}%s{normal} is planting the BOMB!!", Name );
            case 2:    CPrintToChatAll( "\x03{purple}Warning{normal}! {green}%s{normal} is planting the BOMB!!", Name );
            case 3:    PrintCenterTextAll( "{purple}Warning{normal}! {green}%s{normal} is planting the BOMB!!", Name );
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
            case 1:    PrintHintTextToAll( "%s a oprit amorsarea bombei!", Name );
            case 2:    CPrintToChatAll( "\x04%s \x01a oprit amorsarea bombei!", Name );
            case 3:    PrintCenterTextAll( "%s a oprit amorsarea bombei!", Name );
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
            case 1:    PrintHintTextToAll( "{green}%s{normal} has planted the BOMB!", Name );
            case 2:    CPrintToChatAll( "\x03{green}%s{normal} has planted the BOMB!", Name );
            case 3:    PrintCenterTextAll( "{green}%s{normal} has planted the BOMB!", Name );
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
            case 1:    PrintHintTextToAll( "{green}%s{normal} defused the BOMB!", Name );
            case 2:    CPrintToChatAll( "\x03{green}%s{normal} defused the BOMB!", Name );
            case 3:    PrintCenterTextAll( "{green}%s{normal} defused the BOMB!", Name );
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
            case 1:    PrintHintTextToAll( "BOMB successfully exploded" );
            case 2:    CPrintToChatAll( "\x03BOMB successfully exploded" );
            case 3:    PrintCenterTextAll( "BOMB successfully exploded" );
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
            case 1:    PrintHintTextToAll( "%s a scapat bomba!", Name );
            case 2:    CPrintToChatAll( "\x04%s \x01a scapat bomba!", Name );
            case 3:    PrintCenterTextAll( "%s a scapat bomba!", Name );
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
            case 1:    PrintHintTextToAll( "%s a ridicat bomba.", Name );
            case 2:    CPrintToChatAll( "\x04%s \x01a ridicat bomba.", Name );
            case 3:    PrintCenterTextAll( "%s a ridicat bomba.", Name );
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
            case 1:    PrintHintTextToAll( "OMG! {green}%s{normal} is defusing the BOMB!!!!", Name );
            case 2:    CPrintToChatAll( "\x03OMG! {green}%s{normal} is defusing the BOMB!!!!", Name );
            case 3:    PrintCenterTextAll( "OMG! {green}%s{normal} is defusing the BOMB!!!!", Name );
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
            case 1:    PrintHintTextToAll( "%s a oprit dezamorsarea bombei!", Name );
            case 2:    CPrintToChatAll( "\x04%s \x01a oprit dezamorsarea bombei!", Name );
            case 3:    PrintCenterTextAll( "%s a oprit dezamorsarea bombei!", Name );
        }
    }
}