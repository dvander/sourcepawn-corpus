/**********************************************************************************
 *                                                                                *
 *   THIS IS A REWRITE OF THE PREDATORMOD EVENT SCRIPT                            *
 *                                                                                *
 * PredatorMod:                                                                   *
 * - only one Terrorist, transparent, with more HP than usual (+50 for each CT    *
 *   player) - he's the predator                                                  *
 * - CTs hunt the T, when T is killed his killer takes his place                  *
 *                                                                                *
 *                                                                                *
 * Original plugin by cb@ss:                                                      *
 * http://addons.eventscripts.com/addons/view/predator_mod                        *
 *                                                                                *
 * Coding and testing by Michael "MistaGee" Ziegler                               *
 *                                                                                *
 * Published as free software under the terms of the                              *
 * GNU General Public License (GPL) v2 or above.                                  *
 *                                                                                *
 * This program is distributed in the hope that it will be useful, but WITHOUT    *
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS  *
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more         *
 * details.                                                                       *
 *                                                                                *
 **********************************************************************************/


#include <sourcemod>
#include <sdktools>

#include <cstrike>
#include <entity>

#define PRD_ADMINFLAG ADMFLAG_CUSTOM1

#define PREDATORMOD_VERSION "0.3"

#define VIS_INVISIBLE { 255, 255, 255,  50 }
#define VIS_BARELY    { 255, 255, 255, 150 }
#define VIS_VISIBLE   { 255, 255, 255, 255 }

#define TEAMINDEX_NONE	0
#define TEAMINDEX_SPEC	1
#define TEAMINDEX_T	2
#define TEAMINDEX_CT	3

#define K_RENDER_NORMAL		0
#define K_RENDER_TRANS_COLOR	1

#define WEAPON_INDEX_C4 4
#define SOUND_BLIP		"buttons/blip1.wav"


new	bool:preda_running = false,
	bool:between_rounds = false,
	preda_client = 0,
	max_clients,
	g_RenderModeOffset,
	g_RenderClrOffset,
	Handle:cvar_minpl,
	Handle:cvar_auto,
	String:weapons[40][20],
	Float:preda_origin[3],
	preda_movetime,
	bool:preda_autostarted,
	bool:preda_moving,
	preda_health,
	bool:returnweapons[40],
	g_BeamSprite,
	g_HaloSprite,
	preda_campSeconds,
	greyColor[4] = {128, 128, 128, 255},
	redColor[4] = {255, 75, 75, 255};

public Plugin:myinfo = {
	name = "PredatorMod",
	author = "MistaGee",
	description = "Rewrite of the PredatorMod event script",
	version = PREDATORMOD_VERSION,
	url = "http://www.sourcemod.net/"
	}


public OnPluginStart(){
	RegAdminCmd( "preda_on",	Command_On,	PRD_ADMINFLAG );
	RegAdminCmd( "preda_off",	Command_Off,	PRD_ADMINFLAG );
	
	CreateConVar( "preda_version",	PREDATORMOD_VERSION,	"PredatorMod Version", FCVAR_NOTIFY );
	
	cvar_minpl = CreateConVar( "preda_minplayers", "5", "How many players are required", FCVAR_NOTIFY );
	cvar_auto  = CreateConVar( "preda_autostart", "1", "Automatically start PM when minplayers reached", FCVAR_NOTIFY );
	
	HookEvent( "round_start",	Event_RoundStart,	EventHookMode_PostNoCopy	);
	HookEvent( "round_end",		Event_RoundEnd,		EventHookMode_PostNoCopy	);
	HookEvent( "player_spawn",	Event_PlayerSpawn	);
	HookEvent( "player_team",	Event_PlayerTeam	);
	HookEvent( "player_activate",	Event_PlayerActivate	);
	HookEvent( "player_death",	Event_PlayerDeath	);
	HookEvent( "player_disconnect",	Event_PlayerDisconnect,	EventHookMode_Pre		);
	
	g_RenderModeOffset = FindSendPropOffs( "CCSPlayer", "m_nRenderMode" );
	g_RenderClrOffset  = FindSendPropOffs( "CCSPlayer", "m_clrRender"   );
	
	CreateTimer( 5.0, Timer_RegenerateHealth, _, TIMER_REPEAT );
	CreateTimer( 1.0, Timer_SecondlyChecks,   _, TIMER_REPEAT );
	
	g_BeamSprite = PrecacheModel("materials/sprites/laser.vmt");
	g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");	
	
	max_clients = GetMaxClients();
	}


public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	between_rounds = false;
	if( preda_running ){
		if( GetClientCount() < GetConVarInt( cvar_minpl ) && preda_autostarted ){
			// Too few players :(
			Command_Off( 0, 0 );
			return;
			}
		
		preda_campSeconds = 0;
		
		// Increase Predator's health by 50 for each enemy player
		preda_health = 130 + ( GetTeamClientCount(TEAMINDEX_CT) - 1 ) * 50;
		SetPlayerHealth( preda_client, preda_health );
		
		// Strip C4 if available
		new wepIdx;
		while( ( wepIdx = GetPlayerWeaponSlot( preda_client, WEAPON_INDEX_C4 ) ) != -1 ){
			RemovePlayerItem( preda_client, wepIdx );
			}
		
		if( GetTeamClientCount( TEAMINDEX_T ) > 1 ){
			for( new i = 1; i <= max_clients; i++ ){
				if( IsClientInGame(i) &&
				    GetClientTeam(i) == TEAMINDEX_T &&
				    i != preda_client
				  ){
					CS_SwitchTeam( i, TEAMINDEX_CT );
					}
				}
			}
		
		PrintToChatAll( "PredatorMod is running!" );
		}
	else if( GetConVarBool( cvar_auto ) ){
		new plCount = GetClientCount(),
		    plMin   = GetConVarInt( cvar_minpl );
		if( plCount >= plMin ){
			Command_On( 0, 0 );
			preda_autostarted = true;
			}
		else{
			PrintToChatAll( "PradatorMod: Waiting for players to join (%d/%d)...", plCount, plMin );
			}
		}
	}


public Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast ){
	new theClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( !preda_running ){
		UTIL_Render( theClient, VIS_VISIBLE );
		return;
		}
	
	if( returnweapons[theClient] ){
		// Client had a weapon before being killed, return it to them
		new String:plName[50];
		GetClientName( theClient, plName, 50 );
		
		GivePlayerItem( theClient, weapons[theClient] );
		PrintToChatAll( "PredatorMod: Returned %s to player %s.", weapons[theClient], plName );
		
		returnweapons[theClient] = false;
		}
	}


public Event_PlayerTeam( Handle:event, const String:name[], bool:dontBroadcast ){
	if( preda_running ){
		// Set a timer to switch the user right back if neccessary...
		CreateTimer( 1.0, Timer_CheckTeams );
		}
	}

public Action:Timer_CheckTeams( Handle:timer ){
	for( new i = 1; i <= max_clients; i++ ){
		if( !IsClientInGame(i) )
			continue;
		
		if( GetClientTeam(i) == TEAMINDEX_T && i != preda_client ){
			PrintCenterText( i, "You are not the Predator, stick with CTs please" );
			CS_SwitchTeam( i, TEAMINDEX_CT );
			}
		else if( GetClientTeam(i) == TEAMINDEX_CT && i == preda_client ){
			PrintCenterText( i, "You are the Predator, stick with Ts please" );
			CS_SwitchTeam( i, TEAMINDEX_T );
			}
		}
	return Plugin_Stop;
	}

public Event_PlayerActivate(Handle:event, const String:name[], bool:dontBroadcast){
	if( preda_running ){
		// User may only join CT
		ClientCommand( GetClientOfUserId(GetEventInt(event,"userid")), "jointeam %d", TEAMINDEX_CT );
		}
	}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast){
	if( !preda_running ){
		return;
		}
	
	new	victim   = GetClientOfUserId(GetEventInt(event,"userid")),
	    attacker = GetClientOfUserId(GetEventInt(event,"attacker"));
	
	// if killed player was predator:
	if( !between_rounds && preda_client == victim ){
		// make killer predator -> switch killer to t, switch old preda back to CT
		// Store infos and set a timer, so the round ends properly
		new Handle:dp;
		CreateDataTimer( 1.0, Timer_ChangeTeams, dp );
		WritePackCell(dp, attacker);
		WritePackCell(dp, victim);
		}
	else if( between_rounds && preda_client == attacker ){
		// TK protection: The newly selected predator (kill-protected himself) killed someone
		// store which weapon they had and return it afterwards
		returnweapons[victim] = true;
		}
	}

public Event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast ){
	// For TM protection
	between_rounds = true;
	}

public Action:Timer_ChangeTeams(Handle:timer, Handle:dp){
	// Switch players
	ResetPack(dp);
	new attacker = ReadPackCell(dp),
	    victim   = ReadPackCell(dp);
	
	CS_SwitchTeam( attacker, TEAMINDEX_T  );
	CS_SwitchTeam( victim,   TEAMINDEX_CT );
	
	// Make Predator slightly invisible
	UTIL_Render( attacker, VIS_BARELY );
	// Make old Predator fully visible again
	UTIL_Render( victim,   VIS_VISIBLE );
	
	// Give a very high hp count so preda isn't killed before next respawn
	SetPlayerHealth( preda_client, 10000 );
	
	preda_client = attacker;
	PrintCenterText( preda_client, "You are now Predator!" );
	
	// Store other players' weapons to return them later when they were killed interround by the predator
	for( new i = 1; i <= max_clients; i++ ){
		if( IsClientInGame(i) && GetClientTeam(i) == TEAMINDEX_CT && i != preda_client ){
			GetClientWeapon( i, weapons[i], 20 );
			returnweapons[i] = false;
			}
		}
	
	return Plugin_Stop;
	}

min( a, b ) return ( a < b ? a : b );

public Action:Timer_RegenerateHealth( Handle:timer ){
	if( preda_running && !preda_moving ){
		new plHealth = GetClientHealth( preda_client );
		if( plHealth < preda_health ){
			// Count alive cts
			new ctcount = 0;
			for( new i = 1; i <= max_clients; i++ )
				if( IsClientInGame(i) && GetClientTeam(i) == TEAMINDEX_CT && IsPlayerAlive(i) )
					ctcount++;
			
			SetPlayerHealth( preda_client, min( plHealth + ( ctcount - 1 ) * 10, preda_health ) );
			//PrintToServer( "Giving the preda some HP..." );
			}
		}
	return Plugin_Continue;
	}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast){
	if( !preda_running ){
		// No worries
		return Plugin_Continue;
		}
	
	// Check player, is he predator?
	if( GetClientOfUserId(GetEventInt(event,"userid")) == preda_client ){
		if( GetClientCount() <= GetConVarInt( cvar_minpl ) ){
			// Too bad, after this there will too few players be left...
			Command_Off( 0, 0 );
			return Plugin_Continue;
			}
		// We need to find a replacement, so just use the first CT...
		for( new i = 1; i <= max_clients; i++ ){
			if( IsClientInGame(i) && GetClientTeam(i) == TEAMINDEX_CT ){
				CS_SwitchTeam( i, TEAMINDEX_T );
				UTIL_Render( i, VIS_INVISIBLE );
				PrintCenterText( i, "You are now Predator, the old one fled!" );
				preda_client = i;
				break;
				}
			}
		}
	return Plugin_Continue;
	}

public Action:Command_On( client, args ){
	preda_client = 0;
	preda_autostarted = false;
	
	if( GetClientCount() < GetConVarInt( cvar_minpl ) ){
		ReplyToCommand( client, "There are too few players to play PredatorMod..." );
		}
	
	for( new i = 1; i <= max_clients; i++ ){
		if( IsClientInGame(i) && GetClientTeam(i) == TEAMINDEX_T ){
			if( preda_client == 0 ){
				UTIL_Render( i, VIS_BARELY );
				preda_client = i;
				PrintCenterText( i, "You were selected for Predator!" );
				}
			else{
				CS_SwitchTeam( i, TEAMINDEX_CT );
				}
			}
		}
	
	preda_running = true;
	PrintToChatAll( "PredatorMod initialized..." );
	ServerCommand( "mp_restartgame 3" );
	}

public Action:Command_Off( client, args ){
	preda_client = 0;
	preda_running = false;
	UTIL_Render( preda_client, VIS_VISIBLE );
	PrintToChatAll( "PredatorMod disabled." );
	}

public OnMapStart(){
	max_clients = GetMaxClients();
	}

public OnGameFrame(){
	if( !preda_running )
		return;
	
	new Float:current_origin[3],
	    thisSecond = GetTime();
	
	GetClientAbsOrigin( preda_client, current_origin );
	
	if( GetVectorDistance( preda_origin, current_origin, true ) > Pow( 50.0, 2.0 ) ){
		// Predator has moved
		preda_movetime = thisSecond;
		preda_origin[0] = current_origin[0];
		preda_origin[1] = current_origin[1];
		preda_origin[2] = current_origin[2];
		
		//PrintToServer( "Preda is moving. %d", preda_movetime );
		
		if( !preda_moving ){
			preda_moving = true;
			UTIL_Render( preda_client, VIS_BARELY );
			//PrintToServer( "Preda is moving, time %d - %d %d %d", preda_movetime, preda_origin[0], preda_origin[1], preda_origin[2] );
			}
		}
	
	else if( thisSecond - preda_movetime >= 2 ){
		// Predator has been standing at the same position for at least two seconds
		if( preda_moving ){
			preda_moving = false;
			UTIL_Render( preda_client, VIS_INVISIBLE );
			//PrintToServer( "Preda invi, has not moved since %d (now is %d).", preda_movetime, GetTime() );
			}
		}
	
	}


public Action:Timer_SecondlyChecks( Handle:timer ){
	if( !preda_running )
		return Plugin_Continue;
	
	static beaconSeconds = 0;
	
	if( preda_moving ){
		if( preda_campSeconds > 0 )
			preda_campSeconds--;
		}
	else
		preda_campSeconds++;
	
	//PrintToServer( "preda_campSeconds: %d", preda_campSeconds );
	
	if( preda_campSeconds >= 15 )
		beaconSeconds = 5;
	else if( preda_campSeconds > 7 )
		PrintHintText(
			preda_client,
			"You should get going.\n\nCampmeter: %d%%",
			min( RoundToNearest( float(preda_campSeconds) / 15.0 * 100.0 ), 100 )
			);
	
	if( beaconSeconds > 0 ){
		PrintHintText(
			preda_client,
			"Told you...\n\nCampmeter: %d%%\nBeaconmeter: %d%%",
			min( RoundToNearest( float(preda_campSeconds) / 15.0 * 100.0 ), 100 ),
			min( RoundToNearest( float(beaconSeconds) /  5.0 * 100.0 ), 100 )
			);
		beaconSeconds--;
	
		new Float:vec[3];
		GetClientAbsOrigin( preda_client, vec );
		vec[2] += 10;
	
		TE_SetupBeamRingPoint(vec, 10.0, 500.0, g_BeamSprite, g_HaloSprite, 0, 15, 0.5, 5.0, 0.0, greyColor, 10, 0);
		TE_SendToAll();
		
		TE_SetupBeamRingPoint(vec, 10.0, 500.0, g_BeamSprite, g_HaloSprite, 0, 10, 0.6, 10.0, 0.5, redColor, 10, 0);
		TE_SendToAll();
			
		GetClientEyePosition( preda_client, vec );
		EmitAmbientSound( SOUND_BLIP, vec, preda_client, SNDLEVEL_RAIDSIREN );
		}
	
	return Plugin_Continue;
	}



UTIL_Render(client, const color[4]){
	// Shamelessly stolen from CSS:DM by BAILOPAN
	// dm_spawn_protection.sp
	new mode = (color[3] == 255) ? K_RENDER_NORMAL : K_RENDER_TRANS_COLOR;
	
	SetEntData(client, g_RenderModeOffset, mode, 1);
	SetEntDataArray(client, g_RenderClrOffset, color, 4, 1);
	ChangeEdictState(client);
	}

SetPlayerHealth(entity, amount){
	// Shamelessly stolen from knifesyphon.sp by ferret
	new HealthOffset = FindDataMapOffs(entity, "m_iHealth");
	SetEntData(entity, HealthOffset, amount, 4, true);
	}



