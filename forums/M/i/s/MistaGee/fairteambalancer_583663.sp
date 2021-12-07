/*
 * fairteambalancer.sp
 * 
 * Description:
 *	Keeps teams the same size and strength
 * 
 * Versions:
 *	2.7
 *		* Plugins waits 15 minutes before a player is switched again
 *	2.6
 *		* Teams are no longer checked periodically or on certain events, but whenever a
 *		  player dies
 *		* threshold: if player's score - the needed score <= threshold, switch
 *	2.5.2
 *		* Bugfix: plugin actually does something again
 *	2.5.1
 *		* Team balance info is shown the cool way(tm) in TF2
 *		* Admins are only immune when they have a certain flag
 *	2.5
 *		* Added defines for the event hooks and chat messages
 *		* Timer interval can be changed via CVar
 *	2.4.1
 *		* Specs were counted, causing an "array index out of bounds" error
 *	2.4
 *		* Typo: Only Admins were switched
 *		* Clients are switched one second after they died
 *	2.3
 *		* Timer
 *	2.2
 *		* Changed hooks for TF2 and DoD:S to better resemble gameplay
 *	2.1
 *		* Some bugfixes
 *	2.0
 *		* Changed by MistaGee to take team strengths into account
 *	1.0
 *		* Initial Release by dalto:
 *		  http://forums.alliedmods.net/showthread.php?p=519837
 *
 * Credits:
 *	* dalto for making the original plugin
 *	* Extreme_One, StevenT, lambdacore, ThatGuy, CrimsonGT and everyone else who helped testing
 *
 */


#include <sourcemod>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS


#pragma semicolon 1


// Admin level that makes players immune
#define ADMINFLAG Admin_Cheats

#define PLUGIN_VERSION "2.8"

// Wait time before a player is switched again
#define SWITCH_WAIT_TIME (60*15)

#define TEAM_1 2
#define TEAM_2 3

abs( a )   return ( a >= 0 ? a : -a );
max( a,b ) return ( a > b  ? a :  b );
min( a,b ) return ( a < b  ? a :  b );


// Plugin definitions
public Plugin:myinfo =
{
	name			= "Fair Team Balancer",
	author			= "MistaGee",
	description		= "Keeps teams the same size and strength",
	version			= PLUGIN_VERSION,
	url			= "http://forums.alliedmods.net"
};

new Handle:cvarEnabled		= INVALID_HANDLE,
    Handle:cvarThreshold	= INVALID_HANDLE,
    biggerTeam			= 0,
    clientLastSwitched[40],
    dCount			= 0,
    bool:game_is_tf2		= false,
    switches_pending		= 0,
    bool:cstrikeExtAvail	= false,
    plID[40];					// Player IDs of players to be switched


public OnPluginStart(){
	cvarEnabled = CreateConVar(
		"sm_team_balancer_enable",
		"1",
		"Enables the Team Balancer plugin"
		);

	CreateConVar(
		"sm_team_balancer_version",
		PLUGIN_VERSION,
		"Team Balancer Version",
		FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY
		);
	
	cvarThreshold = CreateConVar(
		"sm_team_balancer_threshold",
		"3",
		"Maximum score difference for players to be switched",
		FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY
		);
	
	RegAdminCmd( "sm_teams", Command_Teams, ADMFLAG_KICK, "Balance teams" );
	
	decl String:theFolder[40];
	GetGameFolderName( theFolder, sizeof(theFolder) );
	
	game_is_tf2 = StrEqual( theFolder, "tf" );
	
	// Death event is always needed in order for the actual switching to happen
	HookEvent( "player_death",			Event_PlayerDeath );
	
	// Check for cstrike extension - if available, CS_SwitchTeam is used
	cstrikeExtAvail = ( GetExtensionFileStatus( "game.cstrike.ext" ) == 1 );
	
	}

public Action:Command_Teams( client, args ){
	PerformTeamCheck( true );
	return Plugin_Handled;
	}

void:PerformTeamCheck( bool:switchImmed = false ){
	// If we are disabled - exit
	if( !GetConVarBool(cvarEnabled) )
		return;
	
	// Count the size and frags of each team
	new tPlayers[2] = { 0, 0 },
	    tFrags[2]   = { 0, 0 },
	    mc          = GetMaxClients(),
	    cTeam;
	
	for( new i = 1; i < mc; i++ ){
		if( IsClientInGame(i) ){
			cTeam = GetClientTeam(i);
			// Thanks to lambdacore for the hint
			if( cTeam < 2 ){
				continue;
				}
			tPlayers[ cTeam-2 ]++;
			tFrags[ cTeam-2 ] += GetClientFrags(i);
			}
		}
	
	// Calc score difference, div by player count difference
	// eg: if T1 has 6 players and 12 Frags, and T2 has 8 players and 16 frags,
	// player diff is 2 and frag diff is 4. That means, we need to switch 1 player (diff/2),
	// who has 2 frags ((diff/2)/players).
	
	dCount = abs(tPlayers[0]-tPlayers[1]) / 2;
	new dScore = ( abs(tFrags[0]-tFrags[1]) / 2 ) / max( dCount, 1 );
	
	if( dCount == 0 ){
		return;
		}
	
	// Purge the ID array
	for( new n = 0; n < 40; n++ ){
		plID[n] = 0;
		}
	
	biggerTeam = ( tPlayers[0] > tPlayers[1] ? TEAM_1 : TEAM_2 );
	
	// Find the player(s) who fit best for team change
	// these are those n who come closest to the needed frag count
	
	new plScoreDelta[40],	// Difference of players' score to dScore
	    plFragDelta,
	    AdminId:plAdminID;
	
	for( new i = 1; i < mc; i++ ){
		if( IsClientInGame(i) &&
		    GetClientTeam(i) == biggerTeam &&		// Switch people from bigger team
		    ( ( plAdminID = GetUserAdmin(i) ) == INVALID_ADMIN_ID ||// Who are not admins or...
		      !GetAdminFlag( plAdminID, ADMINFLAG )	// ...not immune
		    )
		  ){
			plFragDelta = abs( GetClientFrags(i) - dScore );
			// Iterate through first n slots of array
			for( new s = 0; s < min( dCount, 40 ); s++ ){
				// if no player found or difference bigger
				if( plID[s] == 0 || plScoreDelta[s] > plFragDelta ){
					plID[s] = i;
					plScoreDelta[s] = plFragDelta;
					}
				}
			}
		}
	
	PrintToChatAll( "[SM] Balancing teams in size and strength, switching %d players.", dCount );
	
	// Now we found the players to switch, so maybe do it
	if( switchImmed ){
		for( new s = 0; s < min( dCount, 40 ); s++ ){
			PerformSwitch( plID[s] );
			plID[s] = 0;
			}
		PrintToServer(  "[SM] Teams have been balanced." );
		}
	else{
		// We're not to switch immediately, but maybe some of the players we want to
		// switch are already dead, so don't wait for them to die again
		for( new s = 0; s < min( dCount, 40 ); s++ ){
			if( IsPlayerAlive( plID[s] ) )
				continue;
			
			PerformSwitch( plID[s] );
			plID[s] = 0;
			}
		}
	}

public Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast ){
	// If we are disabled - exit
	new client = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	
	if( client == 0 )
		return;
		
	new AdminId:plAdminID = GetUserAdmin(client);
	
	if( !GetConVarBool(cvarEnabled) ||
	    ( plAdminID != INVALID_ADMIN_ID && GetAdminFlag( plAdminID, ADMINFLAG ) )
	  )
		return;
	
	// Count the size and frags of each team
	new tPlayers[2] = { 0, 0 },
	    tFrags[2]   = { 0, 0 },
	    mc          = GetMaxClients(),
	    cTeam;
	
	for( new i = 1; i < mc; i++ ){
		if( IsClientInGame(i) ){
			cTeam = GetClientTeam(i);
			// Thanks to lambdacore for the hint
			if( cTeam < 2 )
				continue;
			tPlayers[ cTeam-2 ]++;
			tFrags[ cTeam-2 ] += GetClientFrags(i);
			}
		}
	
	// Calc score difference, div by player count difference
	// eg: if T1 has 6 players and 12 Frags, and T2 has 8 players and 16 frags,
	// player diff is 2 and frag diff is 4. That means, we need to switch 1 player (diff/2),
	// who has 2 frags ((diff/2)/players).
	
	dCount = max( ( abs(tPlayers[0]-tPlayers[1]) / 2 ) - switches_pending, 0 );
	new dScore = ( abs(tFrags[0]-tFrags[1]) / 2 ) / max( dCount, 1 );
	
	if( dCount == 0 ){
		return;
		}
	
	biggerTeam = ( tPlayers[0] > tPlayers[1] ? TEAM_1 : TEAM_2 );
	
	// Check for correct Team and last time user was switched
	if( GetClientTeam(client) != biggerTeam ||
	    GetTime() - clientLastSwitched[client] < SWITCH_WAIT_TIME
	  )
		return;
	
	// If the guy has the score we need, switch them and be done
	if( abs( GetClientFrags(client) - dScore ) <= GetConVarInt(cvarThreshold) ){
		PerformTimedSwitch( client );
		clientLastSwitched[client] = GetTime();
		}
	}

public OnClientDisconnect_Post( client ){
	clientLastSwitched[client] = 0;
	}

void:PerformTimedSwitch( client ){
	CreateTimer( 0.5, Timer_TeamSwitch, client );
	switches_pending++;
	}

public Action:Timer_TeamSwitch( Handle:timer, any:client ){
	if( !IsClientInGame( client ) )
		return Plugin_Stop;
	
	switches_pending--;
	
	// Maybe the player already switched?
	if( GetClientTeam( client ) == biggerTeam ){
		PerformSwitch( client );
		}
	
	return Plugin_Stop;
	}

void:PerformSwitch( client ){
	if( cstrikeExtAvail )
		CS_SwitchTeam( client, 5 - biggerTeam );
	else
		ChangeClientTeam( client, 5 - biggerTeam );
	
	if( game_is_tf2 ){
		new Handle:event = CreateEvent( "teamplay_teambalanced_player" );
		SetEventInt( event, "player", client         );
		SetEventInt( event, "team",   5 - biggerTeam );
		FireEvent( event );
		}
	else{
		decl String:plName[40];
		GetClientName( client, plName, sizeof(plName) );
		
		PrintToChatAll( "[SM] %s has been switched for team balance.", plName );
		}
	}
