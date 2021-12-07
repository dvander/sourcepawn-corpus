#pragma semicolon 1
#include <sourcemod>
#include <usermessages>

#define FADE_IN  0x0001
#define FADE_OUT 0x0002

new max_clients = 0;

public Plugin:myinfo =
{
	name = "Ghostfade",
	author = "MistaGee",
	description = "Fades players' screen when there is another player with the same IP",
	version = "1.1",
	url = "http://www.sourcemod.net"
};

public OnMapStart(){
	max_clients = GetMaxClients();
	}

public OnPluginStart(){
	HookEvent(	"player_death",	Event_PlayerDeath );
	HookEvent(	"round_start",	Event_RoundStart,	EventHookMode_PostNoCopy	);
	
	max_clients = GetMaxClients();
	}

void:SendFadeMsgOut( client ){
	new Handle:msg = StartMessageOne( "Fade", client );
	BfWriteShort( msg, 1000 );	// Fade duration
	BfWriteShort( msg, -1 );	// Fade hold time
	BfWriteShort( msg, FADE_OUT );	// What to do
	BfWriteByte(  msg, 0 );		// Color R
	BfWriteByte(  msg, 0 );		// Color G
	BfWriteByte(  msg, 0 );		// Color B
	BfWriteByte(  msg, 255 );	// Color Alpha
	EndMessage();
	}

public Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast ){
	// Loop through specters to find ghosts
	for( new i = 1; i <= max_clients; i++ ){
		if( IsClientInGame(i) && IsClientObserver(i) ){
			findGhostsForClient(i);
			}
		}
	}

public Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast ){
	new theClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	findGhostsForClient( theClient );
	}
	
void:findGhostsForClient( theClient ){
	decl String:theClientIP[16];
	GetClientIP( theClient, theClientIP, sizeof(theClientIP) );
	
	decl String:refClientIP[16];
	
	for( new i = 1; i <= max_clients; i++ ){
		// Look for an alive player...
		if( theClient != i && IsClientInGame(i) && IsPlayerAlive(i) ){
			GetClientIP( i, refClientIP, sizeof(refClientIP) );
			// who's sitting on the same IP
			if( StrEqual( theClientIP, refClientIP ) ){
				// There's an alive player on the same IP, so the dead one
				// could tell the alive one what's going on - fade them to prevent
				SendFadeMsgOut( theClient );
				
				decl String:plName[40];
				GetClientName( i, plName, sizeof(plName) );
				
				// Tell them what's up
				PrintToChat( theClient, "[SM] Your screen has been faded for ghosting on the same IP (%s) with %s.", theClientIP, plName );
				
				// A single fading is enough
				break;
				}
			}
		}
	}

