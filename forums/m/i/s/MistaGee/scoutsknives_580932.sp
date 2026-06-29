// Scoutsknives plugin by MistaGee

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

new	Handle:cvar_enabled = INVALID_HANDLE;

#define SCOUTSKNIVES_VERSION "0.1"

public Plugin:myinfo = {
	name = "ScoutsKnives",
	author = "MistaGee",
	description = "Strips all weapons and gives scout",
	version = SCOUTSKNIVES_VERSION,
	url = "http://www.sourcemod.net/"
	}


public OnPluginStart(){
	cvar_enabled = CreateConVar( "scoutsknives_enable", "0", "Enable Scoutsknives", FCVAR_NOTIFY );
	
	HookEvent( "player_spawn",	Event_PlayerSpawn	);
	}


public Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast ){
	if( !GetConVarBool( cvar_enabled ) )
		return;
	
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	new wepIdx;
	// Iterate through weapon slots
	for( new i = 0; i < 5; i++ ){
		if( i == 2 ) continue; // You can leeeeave your knife on...
		// Strip all weapons from current slot
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ){
			RemovePlayerItem( client, wepIdx );
			}
		}
	// Give a scout
	GivePlayerItem( client, "weapon_scout" );
	// Now switch to slot1
	ClientCommand( client, "slot1" );
	}
