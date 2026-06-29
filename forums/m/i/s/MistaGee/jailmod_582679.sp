// JailMod++

// On TK: People get the option to send their killer in jail
// In Jail: inmates have knives only, store weapons and return when freed / round restarts
// Admin Command: jail/unjail <player>

// Config: Done via admin menu system

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#define JAILMOD_VERSION "1.1"
#define JAILMOD_ADMINFLAG ADMFLAG_SLAY
#define JAILMOD_SLOTINDEX_KNIFE 2

#define JAILMOD_ADMINMODE_ADDLOC 0
#define JAILMOD_ADMINMODE_REMLOC 1
#define JAILMOD_ADMINMODE_TELLOC 2
#define JAILMOD_ADMINMODE_SETMAX 3

public Plugin:myinfo = {
	name = "JailMod++",
	author = "MistaGee",
	description = "Easy-to-use JailMod",
	version = JAILMOD_VERSION,
	url = "http://www.sourcemod.net/"
	}

new	Handle:hAdminMenu	= INVALID_HANDLE,
	Handle:db		= INVALID_HANDLE,
	Handle:cvar_fill	= INVALID_HANDLE,
	Handle:cvar_tkpunish	= INVALID_HANDLE,
	Handle:cvar_strip	= INVALID_HANDLE,
	adminmode		= JAILMOD_ADMINMODE_TELLOC,
	jailInmates[5],					// Inmate counters
	jailsAvail		= 0,			// How many jails?
	bool:inmateHadWeapon[40],			// Do we need to return something next round?
	String:inmateWeapon[40][20],			// Weapon the user had when jailed
	inmatePosition[40][3],				// Position the user was at when jailed
	jailCoords[5][4],				// Jail Coordinates - 4th field is size
	isInmate[40];					// Is the client an inmate? no: -1 yes: index


public OnPluginStart(){
	CreateConVar( "jail_version",	JAILMOD_VERSION, "JailMod version", FCVAR_NOTIFY );
	cvar_fill = CreateConVar( "jail_fill", "1", "Defines how jails are chosen for players. 0: random - 1: fill jails" );
	cvar_strip = CreateConVar( "jail_strip", "1", "Should weapons be stripped from inmates?" );
	cvar_tkpunish = CreateConVar( "jail_tkpunish", "1", "Should teamkillers be put in jail automatically?" );
	
	RegAdminCmd( "jail_reload",	Command_Reload,		JAILMOD_ADMINFLAG );
	RegAdminCmd( "jail",		Command_Jail,		JAILMOD_ADMINFLAG );
	RegAdminCmd( "unjail",		Command_Unjail,		JAILMOD_ADMINFLAG );
	
	HookEvent(   "player_death",	Event_PlayerDeath	);
	HookEvent(   "player_spawn",	Event_PlayerSpawn	);
	HookEvent(   "round_start",	Event_RoundStart	);
	
	// Shamelessly stolen from sql-admin-manager.sp
	new String:error[255];
	
	for( new i = 0; i < sizeof(isInmate); i++ ){
		isInmate[i] = -1;
		}
	
	if( SQL_CheckConfig("jailmod") ){
		db = SQL_Connect( "jailmod", true, error, sizeof(error) );
		}
	else if( SQL_CheckConfig("default") ){
		db = SQL_Connect( "default", true, error, sizeof(error) );
		}
	
	if( db == INVALID_HANDLE ){
		LogError( "[JAIL] Could not connect to database: %s", error );
		}
	else{
		// Make sure table exists
		SQL_FastQuery( db,
			"CREATE TABLE IF NOT EXISTS jails ( map varchar(40) NOT NULL, x INT NOT NULL, y INT NOT NULL, z INT NOT NULL, size INT NOT NULL DEFAULT 5, PRIMARY KEY( map, x, y, z ) );"
			);
		
		// Load Jails from Database
		Command_Reload( 0, 0 );
		}
	
	new Handle:topmenu;
	if( LibraryExists( "adminmenu" ) && ( ( topmenu = GetAdminTopMenu() ) != INVALID_HANDLE ) ){
		OnAdminMenuReady( topmenu );
		}
	}

public OnMapStart(){
	Command_Reload( 0, 0 );
	}

public Action:Command_Reload( client, args ){
	// Reload all jails from the Database and store their coords
	if( db == INVALID_HANDLE ){
		ReplyToCommand( client, "[JAIL] Database is not connected." );
		return Plugin_Handled;
		}
	
	decl String:error[255],
	     String:theMap[40];
	
	GetCurrentMap( theMap, sizeof(theMap) );
	
	new Handle:qry = SQL_PrepareQuery(db, "SELECT * FROM jails WHERE map=?", error, sizeof(error));
	SQL_BindParamString( qry, 0, theMap, false );
	SQL_Execute( qry );
	
	jailsAvail = 0;
	for( new i = 0; i < 5; i++ ){
		if( SQL_MoreRows( qry ) ){
			SQL_FetchRow( qry );
			// Get all fields into our coordinates array
			for( new j = 0; j < 4; j++ ){
				jailCoords[i][j] = SQL_FetchInt( qry, j+1 );
				}
			jailsAvail++;
			}
		else	// No more data, set jail coords to -1 to mark invalid
			jailCoords[i] = { -1, -1, -1, -1 };
		
		ReplyToCommand( client, "[JAIL] Loaded Jail %d at %d %d %d - max %d inmates", 
			i, jailCoords[i][0], jailCoords[i][1], jailCoords[i][2], jailCoords[i][3]
			);
		}
	
	ReplyToCommand( client, "[JAIL] Found %d usable jails.", jailsAvail );
	return Plugin_Handled;
	}


public Action:Command_Jail( client, args ){
	if( db == INVALID_HANDLE ){
		ReplyToCommand( client, "[JAIL] Database is not connected." );
		return Plugin_Handled;
		}
	
	if( args != 1 ){
		ReplyToCommand( client, "[JAIL] Usage: jail <name> - Put a player in jail" );
		return Plugin_Handled;
		}
	
	if( jailsAvail == 0 ){
		ReplyToCommand( client, "[JAIL] Sorry, no jails are available!" );
		return Plugin_Handled;
		}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg( 1, targetArg, sizeof(targetArg) );
	
	decl String:target_name[50];
	decl target_list[5], target_count, bool:tn_is_ml;
	
	target_count = ProcessTargetString(
		targetArg,
		client,
		target_list,
		5,
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml
		);
	for( new i = 0; i < target_count; i++ ){
		JailPlayer( target_list[i] );
		}
	ShowActivity2( client, "[JAIL] Put %s in jail.", target_name );
	
	return Plugin_Handled;
	}

public Action:Command_Unjail( client, args ){
	if( args != 1 ){
		ReplyToCommand( client, "[JAIL] Usage: unjail <name> - Set a player free" );
		return Plugin_Handled;
		}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg( 1, targetArg, sizeof(targetArg) );
	
	decl String:target_name[50];
	decl target_list[5], target_count, bool:tn_is_ml;
	
	target_count = ProcessTargetString(
		targetArg,
		client,
		target_list,
		5,
		COMMAND_FILTER_CONNECTED,
		target_name,
		sizeof(target_name),
		tn_is_ml
		);
	for( new i = 0; i < target_count; i++ ){
		UnjailPlayer( target_list[i] );
		}
	ShowActivity2( client, "[JAIL] Freed %s from jail.", target_name );
	
	return Plugin_Handled;
	}

public Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast ){
	new victim   = GetClientOfUserId( GetEventInt( event, "userid" ) );
	new attacker = GetClientOfUserId( GetEventInt( event, "attacker" ) );
	
	if( isInmate[victim] != -1 ){
		// Jail lost an inmate
		jailInmates[isInmate[victim]]--;
		isInmate[victim] = -1;
		inmateHadWeapon[victim] = false;
		}
	
	if( GetConVarBool( cvar_tkpunish ) &&
	    isInmate[attacker] == -1       &&
	    GetClientTeam( attacker ) == GetClientTeam( victim )
	  ){
		// Attacker is not in jail, so if teamkill, put them there
		if( JailPlayer( attacker ) ){
			PrintToChat( attacker, "[JAIL] You have been put in jail for team killing." );
			}
		}
	
	}

public Event_PlayerSpawn( Handle:event, const String:name[], bool:dontBroadcast ){
	// Return weapon if the guy was an inmate
	new client = GetClientOfUserId( GetEventInt( event, "userid" ) );
	if( isInmate[client] != -1 ){
		isInmate[client] = -1;
		ReturnWeapon( client );
		}
	}

public Event_RoundStart( Handle:event, const String:name[], bool:dontBroadcast ){
	// Reset inmate counter
	jailInmates = {0,0,0,0,0};
	}


/******************************************************************************************
 *                                   HELPER FUNCTIONS                                     *
 ******************************************************************************************/

bool:JailPlayer( client ){
	if( jailsAvail == 0 || db == INVALID_HANDLE || client == 0 || !IsClientInGame( client ) || isInmate[client] != -1 ){
		return false;
		}
	
	new targetJailIndex = 0;
	if( GetConVarBool( cvar_fill ) ){
		// Search for a jail that has room left
		while( jailInmates[targetJailIndex] >= jailCoords[targetJailIndex][3] ){
			// No room
			if( targetJailIndex < 4 )
				// there are Jails left, keep looking
				targetJailIndex++;
			else	return false;
			}
		}
	else{
		// Find random jail with room - but first, see if there are any!
		new bool:foundFreeJail = false;
		for( new i = 0; i < 5; i++ ){
			if( jailInmates[i] < jailCoords[i][3] ){
				foundFreeJail = true;
				break; // one is enough
				}
			}
		if( !foundFreeJail )
			return false;
		// Now choose one
		do{
			targetJailIndex = GetRandomInt( 0, 4 );
			}
			while( jailInmates[targetJailIndex] >= jailCoords[targetJailIndex][3] );
		}
	
	// Target player is to be sent to jailCoords at targetJailIndex
	
	// Store primary weapon, strip all weapons except knife and teleport them in
	isInmate[client] = targetJailIndex;
	jailInmates[targetJailIndex]++;
	
	new Float:pos[3];
	GetClientEyePosition( client, pos );
	inmatePosition[client][0] = RoundToNearest( pos[0] );
	inmatePosition[client][1] = RoundToNearest( pos[1] );
	inmatePosition[client][2] = RoundToNearest( pos[2] );
	
	if( GetConVarBool( cvar_strip ) ){
		GetClientWeapon( client, inmateWeapon[client], 20 /*sizeof(inmateWeapon[client])*/ );
		inmateHadWeapon[client] = true;
		
		StripWeaponsButKnife( client );
		}
	
	// teleport with zero velocity
	new Float:npos[3];
	npos[0] = float( jailCoords[targetJailIndex][0] );
	npos[1] = float( jailCoords[targetJailIndex][1] );
	npos[2] = float( jailCoords[targetJailIndex][2] );
	TeleportEntity( client, npos, NULL_VECTOR, NULL_VECTOR );
	
	return true;
	}

bool:UnjailPlayer( client ){
	if( client == 0 || !IsClientInGame( client ) || isInmate[client] == -1 ){
		return false;
		}
	
	// Teleport them back to their old position and return their weapon, if it was stripped
	jailInmates[isInmate[client]]--;
	isInmate[client] = -1;
	
	new Float:npos[3];
	npos[0] = float( inmatePosition[client][0] );
	npos[1] = float( inmatePosition[client][1] );
	npos[2] = float( inmatePosition[client][2] );
	
	TeleportEntity( client, npos, NULL_VECTOR, NULL_VECTOR );
	ReturnWeapon( client );
	return true;
	}

StripWeaponsButKnife( client ){
	new wepIdx;
	// Iterate through weapon slots
	for( new i = 0; i < 5; i++ ){
		if( i == JAILMOD_SLOTINDEX_KNIFE ) continue; // You can leeeeave your knife on...
		// Strip all weapons from current slot
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ){
			RemovePlayerItem( client, wepIdx );
			}
		}
	// Now switch to knife
	ClientCommand( client, "slot3" );
	}

ReturnWeapon( client ){
	if( !inmateHadWeapon[client] )
		return;
	GivePlayerItem( client, inmateWeapon[client] );
	inmateHadWeapon[client] = false;
	}


/******************************************************************************************
 *                                   ADMIN MENU HANDLERS                                  *
 ******************************************************************************************/

public OnLibraryRemoved(const String:name[]){
	if( StrEqual( name, "adminmenu" ) ){
		hAdminMenu = INVALID_HANDLE;
		}
	}
 
public OnAdminMenuReady( Handle:topmenu ){
	// Block us from being called twice
	if( topmenu == hAdminMenu ){
		return;
		}
	hAdminMenu = topmenu;
	
	// Now add stuff to the menu: My very own category *yay*
	new TopMenuObject:menu_category = AddToTopMenu(
		// Menu     Name           Type                    Callback         Parent
		hAdminMenu, "jm_commands", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT
		);
	
	if( menu_category == INVALID_TOPMENUOBJECT ){
		// Error... lame...
		return;
		}
	
	// Now add items to it
	//            Menu        Name        Type                Callback     Parent         cmdname      Admin flag
	AddToTopMenu( hAdminMenu, "jm_mode",   TopMenuObject_Item, Handle_Mode, menu_category, "jm_mode",    JAILMOD_ADMINFLAG );
	
	AddToTopMenu( hAdminMenu, "jm_coord1", TopMenuObject_Item, Handle_Coord1, menu_category, "jm_coord1",    JAILMOD_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "jm_coord2", TopMenuObject_Item, Handle_Coord2, menu_category, "jm_coord2",    JAILMOD_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "jm_coord3", TopMenuObject_Item, Handle_Coord3, menu_category, "jm_coord3",    JAILMOD_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "jm_coord4", TopMenuObject_Item, Handle_Coord4, menu_category, "jm_coord4",    JAILMOD_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "jm_coord5", TopMenuObject_Item, Handle_Coord5, menu_category, "jm_coord5",    JAILMOD_ADMINFLAG );
	
	AddToTopMenu( hAdminMenu, "jm_noclip", TopMenuObject_Item, Handle_Noclip, menu_category, "jm_noclip",    JAILMOD_ADMINFLAG );
	
	
	// Items: 
	// 1. J1: x y z - Max
	// 2. J2: x y z - Max
	// 3. J3: x y z - Max
	// 4. J4: x y z - Max
	// 5. J5: x y z - Max
	// 6. Mode: Add location -> Set max inmates -> Teleport to location -> Delete location
	// 7. Toggle NoClip
	}

public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayTitle){
		Format( buffer, maxlength, "JailMod Commands:" );
		}
	else if (action == TopMenuAction_DisplayOption ){
		Format( buffer, maxlength, "JailMod Commands" );
		}
	}

public Handle_Mode( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		decl String:mode[50];
		switch( adminmode ){
			case JAILMOD_ADMINMODE_ADDLOC:	mode = "Add current location";
			case JAILMOD_ADMINMODE_REMLOC:	mode = "Remove a location";
			case JAILMOD_ADMINMODE_TELLOC:	mode = "Teleport to location";
			case JAILMOD_ADMINMODE_SETMAX:	mode = "Set max inmates";
			}
		Format( buffer, maxlength, "Mode: %s", mode );
		}
	else if( action == TopMenuAction_SelectOption){
		adminmode = ++adminmode % 4;
		RedisplayAdminMenu( topmenu, param );
		}
	}


public Handle_Coord1( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	Handle_Coords( 0, topmenu, action, object_id, param, buffer, maxlength );
	}

public Handle_Coord2( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	Handle_Coords( 1, topmenu, action, object_id, param, buffer, maxlength );
	}

public Handle_Coord3( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	Handle_Coords( 2, topmenu, action, object_id, param, buffer, maxlength );
	}

public Handle_Coord4( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	Handle_Coords( 3, topmenu, action, object_id, param, buffer, maxlength );
	}

public Handle_Coord5( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	Handle_Coords( 4, topmenu, action, object_id, param, buffer, maxlength );
	}


public Handle_Coords( coords, Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if( action == TopMenuAction_DisplayOption ){
		Format( buffer, maxlength, "J%d: %d %d %d (Max %d)", coords+1, jailCoords[coords][0], jailCoords[coords][1], jailCoords[coords][2], jailCoords[coords][3] );
		}
	else if (action == TopMenuAction_SelectOption ){
		decl String:theMap[40];
		GetCurrentMap( theMap, sizeof(theMap) );
		
		switch( adminmode ){
			case JAILMOD_ADMINMODE_ADDLOC:{
				// Check if the pos is taken - if so, user wants to overwrite
				decl String:error[255];
				new Handle:qry;
				if( jailCoords[coords][3] != -1 ){
					// Delete old coords from db
					qry = SQL_PrepareQuery( db,
						"DELETE FROM jails WHERE map=? AND x=? AND y=? and z=?",
						error, sizeof(error)
						);
					SQL_BindParamString( qry, 0, theMap, false );
					SQL_BindParamInt(    qry, 1, jailCoords[coords][0] );
					SQL_BindParamInt(    qry, 2, jailCoords[coords][1] );
					SQL_BindParamInt(    qry, 3, jailCoords[coords][2] );
					SQL_Execute( qry );
					CloseHandle( qry );
					}
				
				// Save a new pos in array and database
				new Float:pos[3];
				GetClientEyePosition( param, pos );
				jailCoords[coords][0] = RoundToNearest( pos[0] );
				jailCoords[coords][1] = RoundToNearest( pos[1] );
				jailCoords[coords][2] = RoundToNearest( pos[2] );
				jailCoords[coords][3] = 5;
				
				qry = SQL_PrepareQuery( db,
					"INSERT INTO jails VALUES( ?, ?, ?, ?, ? )",
					error, sizeof(error)
					);
				SQL_BindParamString( qry, 0, theMap, false );
				SQL_BindParamInt(    qry, 1, jailCoords[coords][0] );
				SQL_BindParamInt(    qry, 2, jailCoords[coords][1] );
				SQL_BindParamInt(    qry, 3, jailCoords[coords][2] );
				SQL_BindParamInt(    qry, 4, jailCoords[coords][3] );
				SQL_Execute( qry );
				CloseHandle( qry );
				}
			case JAILMOD_ADMINMODE_REMLOC:{
				if( jailCoords[coords][3] != -1 ){
					// Delete old coords from db
					decl String:error[255];
					new Handle:qry = SQL_PrepareQuery( db,
						"DELETE FROM jails WHERE map=? AND x=? AND y=? and z=?",
						error, sizeof(error)
						);
					SQL_BindParamString( qry, 0, theMap, false );
					SQL_BindParamInt(    qry, 1, jailCoords[coords][0] );
					SQL_BindParamInt(    qry, 2, jailCoords[coords][1] );
					SQL_BindParamInt(    qry, 3, jailCoords[coords][2] );
					SQL_Execute( qry );
					CloseHandle( qry );
					jailCoords[coords] = { 0, 0, 0, 0 };
					}
				}
			case JAILMOD_ADMINMODE_TELLOC:{
				new Float:npos[3];
				npos[0] = float( jailCoords[coords][0] );
				npos[1] = float( jailCoords[coords][1] );
				npos[2] = float( jailCoords[coords][2] );
				
				TeleportEntity( param, npos, NULL_VECTOR, NULL_VECTOR );
				}
			case JAILMOD_ADMINMODE_SETMAX:{
				jailCoords[coords][3] = ( jailCoords[coords][3] % 20 ) + 1;
				
				decl String:error[255];
				new Handle:qry = SQL_PrepareQuery( db,
					"UPDATE jails SET size=? WHERE map=? AND x=? AND y=? and z=?",
					error, sizeof(error)
					);
				SQL_BindParamInt(    qry, 0, jailCoords[coords][3] );
				SQL_BindParamString( qry, 1, theMap, false );
				SQL_BindParamInt(    qry, 2, jailCoords[coords][0] );
				SQL_BindParamInt(    qry, 3, jailCoords[coords][1] );
				SQL_BindParamInt(    qry, 4, jailCoords[coords][2] );
				SQL_Execute( qry );
				CloseHandle( qry );
				}
			}
		RedisplayAdminMenu( topmenu, param );
		}
	}

public Handle_Noclip( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "Toggle NoClip" );
		}
	else if (action == TopMenuAction_SelectOption){
		new MoveType:movetype = GetEntityMoveType( param );
		
		if( movetype != MOVETYPE_NOCLIP ){
			SetEntityMoveType( param, MOVETYPE_NOCLIP);
			}
		else{
			SetEntityMoveType( param, MOVETYPE_WALK);
			}
		RedisplayAdminMenu( topmenu, param );
		}
	}

