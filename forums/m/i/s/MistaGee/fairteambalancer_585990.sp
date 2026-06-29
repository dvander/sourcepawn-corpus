/*
fairteambalancer.sp

Description:
	Keeps teams the same size and strength

Versions:
	2.52
		* Bugfix: plugin actually does something again
	2.51
		* Team balance info is shown the cool way(tm) in TF2
		* Admins are only immune when they have a certain flag
	2.5
		* Added defines for the event hooks and chat messages
		* Timer interval can be changed via CVar
	2.41
		* Specs were counted, causing an "array index out of bounds" error
	2.4
		* Typo: Only Admins were switched
		* Clients are switched one second after they died
	2.3
		* Timer
	2.2
		* Changed hooks for TF2 and DoD:S to better resemble gameplay
	2.1
		* Some bugfixes
	2.0
		* Changed by MistaGee to take team strengths into account
	1.0
		* Initial Release by dalto:
		  http://forums.alliedmods.net/showthread.php?p=519837

Credits:
	* dalto for making the original plugin
	* Extreme_One, StevenT, lambdacore and everyone else who helped testing

*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

// Admin level that makes players immune
#define ADMINFLAG Admin_Cheats

// Comment the next line if you don't want periodic checks to happen
#define RUN_TIMER
// Default value for the interval cvar (needs to be string)
#define TIMER_INTERVAL "120.0"

// Comment the next line if you don't want checks on specific events to happen
#define HOOK_EVENTS

// Comment the next line if you don't want the message "Teams are equal" to show
#define SHOW_EQUAL_MESSAGES

#define PLUGIN_VERSION "2.5.2"

#define TEAM_1 2
#define TEAM_2 3

abs( a )   return ( a >= 0 ? a : -a );
max( a,b ) return ( a > b  ? a :  b );
min( a,b ) return ( a < b  ? a :  b );


// Plugin definitions
public Plugin:myinfo =
{
	name		= "Fair Team Balancer",
	author		= "MistaGee",
	description	= "Keeps teams the same size and strength",
	version		= PLUGIN_VERSION,
	url		= "http://forums.alliedmods.net"
};

new Handle:cvarEnabled  = INVALID_HANDLE,
    Handle:cvarInterval = INVALID_HANDLE,
    Handle:timerChecks  = INVALID_HANDLE,
    biggerTeam = 0,
    dCount = 0,
    bool:game_is_tf2    = false,
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
	
	cvarInterval = CreateConVar(
		"sm_team_balancer_interval",
		TIMER_INTERVAL,
		"Interval between periodic checks",
		FCVAR_PLUGIN | FCVAR_REPLICATED | FCVAR_NOTIFY
		);
	
	RegAdminCmd( "sm_teams", Command_Teams, ADMFLAG_KICK, "Balance teams" );
	
	decl String:theFolder[40];
	GetGameFolderName( theFolder, sizeof(theFolder) );
	
#if defined HOOK_EVENTS
	PrintToServer( "[TB] Hooking events for game: %s", theFolder );
	
	if( StrEqual( theFolder, "dod" ) ){
		HookEvent( "dod_round_win",		Event_RoundEnd, EventHookMode_PostNoCopy );
		HookEvent( "dod_point_captured",	Event_RoundEnd, EventHookMode_PostNoCopy );
		}
	else if( StrEqual( theFolder, "tf" ) ){
		HookEvent( "teamplay_round_win",	Event_RoundEnd, EventHookMode_PostNoCopy );
		HookEvent( "teamplay_round_stalemate",	Event_RoundEnd, EventHookMode_PostNoCopy );
		HookEvent( "ctf_flag_captured",		Event_RoundEnd, EventHookMode_PostNoCopy );
		game_is_tf2 = true;
		}
	else{
		HookEvent( "round_end",			Event_RoundEnd, EventHookMode_PostNoCopy );
		}
#else
	game_is_tf2 = StrEqual( theFolder, "tf" );
#endif
	
	// Death event is always needed in order for the actual switching to happen
	HookEvent( "player_death",			Event_PlayerDeath );
	
#if defined RUN_TIMER
	HookConVarChange( cvarInterval, ConVarChange_Interval );
	RecreateCheckTimer();
#endif
	}

#if defined RUN_TIMER
public ConVarChange_Interval( Handle:convar, const String:oldValue[], const String:newValue[] ){
	RecreateCheckTimer();
	}

void:RecreateCheckTimer(){
	if( timerChecks != INVALID_HANDLE )
		KillTimer( timerChecks );
	
	new Float:theInt = GetConVarFloat( cvarInterval );
	timerChecks = CreateTimer( theInt, Timer_Check, _, TIMER_REPEAT );
	PrintToServer( "[TB] Recreating timer with interval %f seconds.", theInt );
	}

public Action:Timer_Check( Handle:timer ){
	// Call check func
	PerformTeamCheck();
	return Plugin_Continue;
	}
#endif

public Action:Command_Teams( client, args ){
	PerformTeamCheck( true );
	return Plugin_Handled;
	}

public Event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast ){
	PerformTeamCheck();
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
#if defined SHOW_EQUAL_MESSAGES
		PrintToServer(  "[SM] Teams are equal in size or can't be balanced." );
		PrintToChatAll( "[SM] Teams are equal in size or can't be balanced." );
#endif
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
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	// Check the array of clients that are to be switched
	for( new s = 0; s < min( dCount, 40 ); s++ ){
		if( plID[s] != client )
			continue;
		
		/*new Handle:dp;
		CreateDataTimer( 1.0, Timer_TeamSwitch, dp, TIMER_HNDL_CLOSE );
		WritePackCell( dp, client );
		*/
		CreateTimer( 1.0, Timer_TeamSwitch, client, TIMER_HNDL_CLOSE );
		
		plID[s] = 0;
		// If we're here, we found the player we were looking for, so...
		break;
		}
	}

/*public Action:Timer_TeamSwitch( Handle:timer, Handle:dp ){
	ResetPack( dp );
	new client = ReadPackCell( dp );
	*/
public Action:Timer_TeamSwitch( Handle:timer, any:client ){
	if( !IsClientInGame( client ) )
		return Plugin_Stop;
	
	// Maybe the player already switched?
	if( GetClientTeam( client ) == biggerTeam ){
		PerformSwitch( client );
		}
	
	return Plugin_Stop;
	}

void:PerformSwitch( client ){
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
