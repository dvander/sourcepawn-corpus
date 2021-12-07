// TeamSwitch

// Allows admins to switch people in the opposite team
// This can either be done immediately, or on player death,
// or - if available in the mod - on round end.
// The plugin configures itself for the different mods automatically,
// so there is no $mod Edition neccessary.

// Changes:
// 1.3:
//      * teamswitch_spec command
// 1.2:
//      * Bugfix: Wrong player ID got listed in the menu, so the wrong people were switched
// 1.1:
//      * Menu was re-displayed at the wrong item index

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS


// Team indices
#define TEAM_1    2
#define TEAM_2    3
#define TEAM_SPEC 1


#define TEAMSWITCH_VERSION    "1.3"
#define TEAMSWITCH_ADMINFLAG  ADMFLAG_KICK
#define TEAMSWITCH_ARRAY_SIZE 64


public Plugin:myinfo = {
	name = "TeamSwitch",
	author = "MistaGee",
	description = "switch people to the other team now, at round end, on death",
	version = TEAMSWITCH_VERSION,
	url = "http://www.sourcemod.net/"
	};

new	Handle:hAdminMenu	= INVALID_HANDLE,
	bool:onRoundEndPossible	= false,
	bool:cstrikeExtAvail	= false,
	String:teamName1[5],
	String:teamName2[5],
	bool:switchOnRoundEnd[TEAMSWITCH_ARRAY_SIZE],
	bool:switchOnDeath[TEAMSWITCH_ARRAY_SIZE];

enum TeamSwitchEvent{
	TeamSwitchEvent_Immediately	= 0,
	TeamSwitchEvent_OnDeath		= 1,
	TeamSwitchEvent_OnRoundEnd	= 2,
	TeamSwitchEvent_ToSpec		= 3
	};

public OnPluginStart(){
	CreateConVar( "teamswitch_version",	TEAMSWITCH_VERSION, "TeamSwitch version", FCVAR_NOTIFY );
	
	RegAdminCmd( "teamswitch",		Command_SwitchImmed,	TEAMSWITCH_ADMINFLAG );
	RegAdminCmd( "teamswitch_death",	Command_SwitchDeath,	TEAMSWITCH_ADMINFLAG );
	RegAdminCmd( "teamswitch_roundend",	Command_SwitchRend,	TEAMSWITCH_ADMINFLAG );
	RegAdminCmd( "teamswitch_spec", 	Command_SwitchSpec,	TEAMSWITCH_ADMINFLAG );
	
	HookEvent(   "player_death",	Event_PlayerDeath	);
	
	// Hook game specific round end events - if none found, round end is not shown in menu
	decl String:theFolder[40];
	GetGameFolderName( theFolder, sizeof(theFolder) );
	
	PrintToServer( "[TS] Hooking round end events for game: %s", theFolder );
	
	if( StrEqual( theFolder, "dod" ) ){
		HookEvent( "dod_round_win",		Event_RoundEnd, EventHookMode_PostNoCopy );
		onRoundEndPossible = true;
		}
	else if( StrEqual( theFolder, "tf" ) ){
		HookEvent( "teamplay_round_win",	Event_RoundEnd, EventHookMode_PostNoCopy );
		HookEvent( "teamplay_round_stalemate",	Event_RoundEnd, EventHookMode_PostNoCopy );
		onRoundEndPossible = true;
		}
	else if( StrEqual( theFolder, "cstrike" ) ){
		HookEvent( "round_end",			Event_RoundEnd, EventHookMode_PostNoCopy );
		onRoundEndPossible = true;
		}
	
	new Handle:topmenu;
	if( LibraryExists( "adminmenu" ) && ( ( topmenu = GetAdminTopMenu() ) != INVALID_HANDLE ) ){
		OnAdminMenuReady( topmenu );
		}
	
	// Check for cstrike extension - if available, CS_SwitchTeam is used
	cstrikeExtAvail = ( GetExtensionFileStatus( "game.cstrike.ext" ) == 1 );
	
	LoadTranslations( "common.phrases" );
	}

public OnMapStart(){
	GetTeamName( 2, teamName1, sizeof(teamName1) );
	GetTeamName( 3, teamName2, sizeof(teamName2) );
	
	PrintToServer(
		"[TS] Team Names: %s %s - OnRoundEnd available: %s",
		teamName1, teamName2,
		( onRoundEndPossible ? "yes" : "no" )
		);
	}

public Action:Command_SwitchImmed( client, args ){
	if( args != 1 ){
		ReplyToCommand( client, "[SM] Usage: teamswitch_immed <name> - Switch player to opposite team immediately" );
		return Plugin_Handled;
		}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg( 1, targetArg, sizeof(targetArg) );
	
	decl String:target_name[50];
	
	new target = FindTarget( client, targetArg );
	if( target != -1 ){
		GetClientName( target, target_name, sizeof(target_name) );
		PerformSwitch( target );
		PrintToChatAll( "[SM] Admin switched %s to opposite team.", target_name );
		}
	
	return Plugin_Handled;
	}

public Action:Command_SwitchDeath( client, args ){
	if( args != 1 ){
		ReplyToCommand( client, "[SM] Usage: teamswitch_death <name> - Switch player to opposite team when they die" );
		return Plugin_Handled;
		}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg( 1, targetArg, sizeof(targetArg) );
	
	decl String:target_name[50];
	new target = FindTarget( client, targetArg );
	if( target != -1 ){
		switchOnDeath[target] = !switchOnDeath[target];
		GetClientName( target, target_name, sizeof(target_name) );
		PrintToChatAll(
			"[SM] %s will %s be switched to opposite team on their death.",
			target_name, ( switchOnDeath[target] ? "" : "not" )
			);
		}
	
	return Plugin_Handled;
	}

public Action:Command_SwitchRend( client, args ){
	if( args != 1 ){
		ReplyToCommand( client, "[SM] Usage: teamswitch_roundend <name> - Switch player to opposite team when the round ends" );
		return Plugin_Handled;
		}
	
	if( !onRoundEndPossible ){
		ReplyToCommand( client, "[SM] Switching on round end is not possible in this mod." );
		return Plugin_Handled;
		}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg( 1, targetArg, sizeof(targetArg) );
	
	new target = FindTarget( client, targetArg );
	
	if( target != -1 ){
		decl String:target_name[50];
		switchOnRoundEnd[target] = !switchOnRoundEnd[target];
		GetClientName( target, target_name, sizeof(target_name) );
		PrintToChatAll(
			"[SM] %s will %s be switched to opposite team on round end.",
			target_name, ( switchOnRoundEnd[target] ? "" : "not" )
			);
		}
	
	return Plugin_Handled;
	}

public Action:Command_SwitchSpec( client, args ){
	if( args != 1 ){
		ReplyToCommand( client, "[SM] Usage: teamswitch_spec <name> - Switch player to spectators immediately" );
		return Plugin_Handled;
		}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg( 1, targetArg, sizeof(targetArg) );
	
	decl String:target_name[50];
	
	new target = FindTarget( client, targetArg );
	if( target != -1 ){
		GetClientName( target, target_name, sizeof(target_name) );
		PerformSwitch( target, true );
		PrintToChatAll( "[SM] Admin switched %s to spectators.", target_name );
		}
	
	return Plugin_Handled;
	}

public Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast ){
	new victim   = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( switchOnDeath[victim] ){
		PerformTimedSwitch( victim );
		switchOnDeath[victim] = false;
		}
	}

public Event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast ){
	if( !onRoundEndPossible )
		return;
	
	for( new i = 0; i < TEAMSWITCH_ARRAY_SIZE; i++ ){
		if( switchOnRoundEnd[i] ){
			PerformTimedSwitch(i);
			switchOnRoundEnd[i] = false;
			}
		}
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
		hAdminMenu,		// Menu
		"ts_commands",		// Name
		TopMenuObject_Category,	// Type
		Handle_Category,	// Callback
		INVALID_TOPMENUOBJECT	// Parent
		);
	
	if( menu_category == INVALID_TOPMENUOBJECT ){
		// Error... lame...
		return;
		}
	
	// Now add items to it
	AddToTopMenu(
		hAdminMenu,			// Menu
		"ts_immed",			// Name
		TopMenuObject_Item,		// Type
		Handle_ModeImmed,		// Callback
		menu_category,			// Parent
		"ts_immed",			// cmdName
		TEAMSWITCH_ADMINFLAG		// Admin flag
		);
	
	AddToTopMenu(
		hAdminMenu,			// Menu
		"ts_death",			// Name
		TopMenuObject_Item,		// Type
		Handle_ModeDeath,		// Callback
		menu_category,			// Parent
		"ts_death",			// cmdName
		TEAMSWITCH_ADMINFLAG		// Admin flag
		);
	
	if( onRoundEndPossible ){
		AddToTopMenu(
			hAdminMenu,			// Menu
			"ts_rend",			// Name
			TopMenuObject_Item,		// Type
			Handle_ModeRend,		// Callback
			menu_category,			// Parent
			"ts_rend",			// cmdName
			TEAMSWITCH_ADMINFLAG		// Admin flag
			);
		}
	
	AddToTopMenu(
		hAdminMenu,			// Menu
		"ts_spec",			// Name
		TopMenuObject_Item,		// Type
		Handle_ModeSpec,		// Callback
		menu_category,			// Parent
		"ts_spec",			// cmdName
		TEAMSWITCH_ADMINFLAG		// Admin flag
		);
	
	}

public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	switch( action ){
		case TopMenuAction_DisplayTitle:
			Format( buffer, maxlength, "TeamSwitch - when?" );
		case TopMenuAction_DisplayOption:
			Format( buffer, maxlength, "TeamSwitch Commands" );
		}
	}

public Handle_ModeImmed( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "Immediately" );
		}
	else if( action == TopMenuAction_SelectOption){
		ShowPlayerSelectionMenu( param, TeamSwitchEvent_Immediately );
		}
	}

public Handle_ModeDeath( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "On Death" );
		}
	else if( action == TopMenuAction_SelectOption){
		ShowPlayerSelectionMenu( param, TeamSwitchEvent_OnDeath );
		}
	}

public Handle_ModeRend( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "On Round end" );
		}
	else if( action == TopMenuAction_SelectOption){
		ShowPlayerSelectionMenu( param, TeamSwitchEvent_OnRoundEnd );
		}
	}

public Handle_ModeSpec( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "To Spectator" );
		}
	else if( action == TopMenuAction_SelectOption){
		ShowPlayerSelectionMenu( param, TeamSwitchEvent_ToSpec );
		}
	}


/******************************************************************************************
 *                           PLAYER SELECTION MENU HANDLERS                               *
 ******************************************************************************************/

void:ShowPlayerSelectionMenu( client, TeamSwitchEvent:event, item = 0 ){
	new Handle:playerMenu = INVALID_HANDLE;
	
	// Create Menu with the correct Handler, so I don't have to store which player chose
	// which action...
	switch( event ){
		case TeamSwitchEvent_Immediately:
			playerMenu = CreateMenu( Handle_SwitchImmed );
		case TeamSwitchEvent_OnDeath:
			playerMenu = CreateMenu( Handle_SwitchDeath );
		case TeamSwitchEvent_OnRoundEnd:
			playerMenu = CreateMenu( Handle_SwitchRend  );
		case TeamSwitchEvent_ToSpec:
			playerMenu = CreateMenu( Handle_SwitchSpec  );
		}
	
	SetMenuTitle(		playerMenu, "Choose player"	);
	SetMenuExitButton(	playerMenu, true		);
	SetMenuExitBackButton(	playerMenu, true		);
	
	// Now add players to it
	// I'm aware there is a function AddTargetsToMenu in the SourceMod API, but I don't
	// use that one because it does not display the team the clients are in.
	new cTeam = 0,
	    mc    = GetMaxClients();
	
	decl String:cName[15],
	     String:buffer[20],
	     String:cBuffer[5];
	
	for( new i = 1; i < mc; i++ ){
		if( IsClientInGame(i) ){
			cTeam = GetClientTeam(i);
			if( cTeam < 2 )
				continue;
			
			GetClientName( i, cName, sizeof(cName) );
			
			switch( event ){
				case TeamSwitchEvent_Immediately,
				     TeamSwitchEvent_ToSpec:
					Format( buffer, sizeof(buffer),
						"[%s] %s", 
						( cTeam == 2 ? teamName1 : teamName2 ),
						cName
						);
				case TeamSwitchEvent_OnDeath:
					Format( buffer, sizeof(buffer),
						"[%s] [%s] %s",
						( switchOnDeath[i] ? 'x' : ' ' ),
						( cTeam == 2 ? teamName1 : teamName2 ),
						cName
						);
				case TeamSwitchEvent_OnRoundEnd:
					Format( buffer, sizeof(buffer),
						"[%s] [%s] %s",
						( switchOnRoundEnd[i] ? 'x' : ' ' ),
						( cTeam == 2 ? teamName1 : teamName2 ),
						cName
						);
				}
			
			IntToString( i, cBuffer, sizeof(cBuffer) );
			
			AddMenuItem( playerMenu, cBuffer, buffer );
			}
		}
	
	// Send the menu to our admin
	if( item == 0 )
		DisplayMenu(       playerMenu, client,         30 );
	else	DisplayMenuAtItem( playerMenu, client, item-1, 30 );
	}

public Handle_SwitchImmed( Handle:playerMenu, MenuAction:action, client, target ){
	Handle_Switch( TeamSwitchEvent_Immediately, playerMenu, action, client, target );
	}

public Handle_SwitchDeath( Handle:playerMenu, MenuAction:action, client, target ){
	Handle_Switch( TeamSwitchEvent_OnDeath, playerMenu, action, client, target );
	}

public Handle_SwitchRend( Handle:playerMenu, MenuAction:action, client, target ){
	Handle_Switch( TeamSwitchEvent_OnRoundEnd, playerMenu, action, client, target );
	}

public Handle_SwitchSpec( Handle:playerMenu, MenuAction:action, client, target ){
	Handle_Switch( TeamSwitchEvent_ToSpec, playerMenu, action, client, target );
	}

void:Handle_Switch( TeamSwitchEvent:event, Handle:playerMenu, MenuAction:action, client, param ){
	switch( action ){
		case MenuAction_Select:{
			decl String:info[5];
			GetMenuItem( playerMenu, param, info, sizeof(info) );
			new target = StringToInt( info );
			
			switch( event ){
				case TeamSwitchEvent_Immediately:
					PerformSwitch( target );
				case TeamSwitchEvent_OnDeath:{
					// If alive: player must be listed in OnDeath array
					if( IsPlayerAlive( target ) ){
						// If alive, toggle status
						switchOnDeath[target] = !switchOnDeath[target];
						}
					else	// Switch right away
						PerformSwitch( target );
					}
				case TeamSwitchEvent_OnRoundEnd:{
					// Toggle status
					switchOnRoundEnd[target] = !switchOnRoundEnd[target];
					}
				case TeamSwitchEvent_ToSpec:
					PerformSwitch( target, true );
				}
			// Now display the menu again
			ShowPlayerSelectionMenu( client, event, target );
			}
			
		case MenuAction_Cancel:
			// param gives us the reason why the menu was cancelled
			if( param == MenuCancel_ExitBack )
				RedisplayAdminMenu( hAdminMenu, client );
		
		case MenuAction_End:
			CloseHandle( playerMenu );
		}
	}


void:PerformTimedSwitch( client ){
	CreateTimer( 0.5, Timer_TeamSwitch, client );
	}

public Action:Timer_TeamSwitch( Handle:timer, any:client ){
	if( IsClientInGame( client ) )
		PerformSwitch( client );
	return Plugin_Stop;
	}

void:PerformSwitch( client, bool:toSpec = false ){
	new cTeam  = GetClientTeam( client ),
	    toTeam = ( toSpec ? TEAM_SPEC : TEAM_1 + TEAM_2 - cTeam );
	
	if( cstrikeExtAvail && !toSpec )
		CS_SwitchTeam(    client, toTeam );
	else	ChangeClientTeam( client, toTeam );
	
	decl String:plName[40];
	GetClientName( client, plName, sizeof(plName) );
	PrintToChatAll( "[SM] %s has been switched by admin.", plName );
	}
