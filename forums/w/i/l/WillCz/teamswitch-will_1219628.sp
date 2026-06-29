// TeamSwitch

// Allows admins to switch people in the opposite team
// This can either be done immediately, or on player death,
// or - if available in the mod - on round end.
// The plugin configures itself for the different mods automatically,
// so there is no $mod Edition neccessary.

// Changes:
// 1.5:
//      * Works with new CS:Source, made working for CS:Source only
// 1.4:
//      * change player skin when switch immediately (for CSS)
//      * drop bomb when T switch to CT (Dalto part of code)
//      * add announce in chat when admins switch from menu 
//      * increase length of players name in menu 
//      * add translation support
// 1.3:
//      * teamswitch_spec command
// 1.2:
//      * Bugfix: Wrong player ID got listed in the menu, so the wrong people were switched
// 1.1:
//      * Menu was re-displayed at the wrong item index

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <colors>

#undef REQUIRE_PLUGIN
#include <adminmenu>

#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

// Team indices
#define TEAM_1    2
#define TEAM_2    3
#define TEAM_SPEC 1

// TeamSwitch stuff
#define TEAMSWITCH_VERSION    "1.5"
#define TEAMSWITCH_ADMINFLAG  ADMFLAG_KICK
#define TEAMSWITCH_ARRAY_SIZE 64

// Global Variables
//new Handle:hGameConf = INVALID_HANDLE;
//new Handle:hDropWeapon = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "TeamSwitch",
	author = "MistaGee (Modifed by Snake 60, Will)",
	description = "Switch people to the other team now, at round end, on death",
	version = TEAMSWITCH_VERSION,
	url = "http://www.sourcemod.net/"
	};

new	Handle:hAdminMenu	= INVALID_HANDLE,
	bool:onRoundEndPossible	= false,
	bool:cstrikeExtAvail	= false,
	String:teamName1[2],
	String:teamName2[3],
	bool:switchOnRoundEnd[TEAMSWITCH_ARRAY_SIZE],
	bool:switchOnDeath[TEAMSWITCH_ARRAY_SIZE];

enum TeamSwitchEvent
{
	TeamSwitchEvent_Immediately	= 0,
	TeamSwitchEvent_OnDeath		= 1,
	TeamSwitchEvent_OnRoundEnd	= 2,
	TeamSwitchEvent_ToSpec		= 3
};

public OnPluginStart()
{
	CreateConVar( "teamswitch_version",	TEAMSWITCH_VERSION, "TeamSwitch version", FCVAR_NOTIFY );
	
	RegAdminCmd( "teamswitch",		Command_SwitchImmed,	TEAMSWITCH_ADMINFLAG );
	RegAdminCmd( "teamswitch_death",	Command_SwitchDeath,	TEAMSWITCH_ADMINFLAG );
	RegAdminCmd( "teamswitch_roundend",	Command_SwitchRend,	TEAMSWITCH_ADMINFLAG );
	RegAdminCmd( "teamswitch_spec", 	Command_SwitchSpec,	TEAMSWITCH_ADMINFLAG );
	
	
	// Load the gamedata file
	// Removed due to server crash
	
	HookEvent("player_death", Event_PlayerDeath);
	
	// Hook game specific round end events - if none found, round end is not shown in menu
	decl String:theFolder[40];
	GetGameFolderName( theFolder, sizeof(theFolder) );
	
	if(StrEqual(theFolder, "cstrike"))
  {
		HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
		onRoundEndPossible = true;
	}
	else
  {
    SetFailState("Game %s is not supported.", theFolder);
  }
	
	// Check for cstrike extension - if available, CS_SwitchTeam is used
	cstrikeExtAvail = ( GetExtensionFileStatus( "game.cstrike.ext" ) == 1 );
	
	LoadTranslations( "common.phrases" );
	LoadTranslations( "teamswitch.phrases" );
	
}

public OnMapStart()
{
	GetTeamName( 2, teamName1, sizeof(teamName1) );
	GetTeamName( 3, teamName2, sizeof(teamName2) );
	
	PrintToServer(
		"[TS] Team Names: %s %s - OnRoundEnd available: %s",
		teamName1, teamName2,
		( onRoundEndPossible ? "yes" : "no" )
		);
}

/** Commands handlers */

public Action:Command_SwitchImmed( client, args )
{
	if( args != 1 )
  {
		ReplyToCommand( client, "[SM] %t", "ts usage immediately" );
		return Plugin_Handled;
	}
	
  // Try to find a target player
	decl String:targetArg[50];
	GetCmdArg( 1, targetArg, sizeof(targetArg) );
	
	decl String:target_name[50];
	
	new target = FindTarget( client, targetArg );
	if( target != -1 )
  {
		GetClientName( target, target_name, sizeof(target_name) );
		PerformSwitch( target );
		CPrintToChatAll("[SM] %t {lightgreen}%s {default} %t", "ts admin switch", target_name, "ts opposite team");
  }
	return Plugin_Handled;
}

public Action:Command_SwitchDeath( client, args )
{
	if( args != 1 )
  {
		ReplyToCommand( client, "[SM] %t", "ts usage death" );
		return Plugin_Handled;
	}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg( 1, targetArg, sizeof(targetArg) );
	
	decl String:target_name[50];
	new target = FindTarget( client, targetArg );
	if( target != -1 )
  {
		switchOnDeath[target] = !switchOnDeath[target];
		GetClientName( target, target_name, sizeof(target_name) );
		if(switchOnDeath[target])
    { 
	     CPrintToChatAll( "[SM] {lightgreen}%s {default}%t", target_name, "ts will be switch to apposite team on death");
    }
	  else 
    {  
	    CPrintToChatAll( "[SM] {lightgreen}%s {default}%t", target_name, "ts will not be switch to apposite team on death");
    }
	}
	return Plugin_Handled;
}

public Action:Command_SwitchRend( client, args )
{
	if( args != 1 )
  {
		ReplyToCommand( client, "[SM] %t", "ts usage roundend" );
		return Plugin_Handled;
	}
	
	if( !onRoundEndPossible )
  {
		ReplyToCommand( client, "[SM] %t", "ts usage roundend error" );
		return Plugin_Handled;
	}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg( 1, targetArg, sizeof(targetArg) );
	
	new target = FindTarget( client, targetArg );
	
	if( target != -1 )
  {
		decl String:target_name[50];
		switchOnRoundEnd[target] = !switchOnRoundEnd[target];
		GetClientName( target, target_name, sizeof(target_name) );
		if(switchOnRoundEnd[target])
    { 
	     CPrintToChatAll( "\x01[SM] \x03%s \x01%t", target_name, "ts will be switch to apposite team on rounend");
    }
	  else
    { 
	    CPrintToChatAll( "\x01[SM] \x03%s \x01%t", target_name, "ts will not be switch to apposite team on rounend");
    }
	}
	return Plugin_Handled;
}

public Action:Command_SwitchSpec( client, args )
{
	if( args != 1 )
  {
		ReplyToCommand( client, "[SM] %t", "ts usage spec" );
		return Plugin_Handled;
	}
	
	// Try to find a target player
	decl String:targetArg[50];
	GetCmdArg( 1, targetArg, sizeof(targetArg) );
	
	decl String:target_name[50];
	
	new target = FindTarget( client, targetArg );
	if( target != -1 )
  {
		GetClientName( target, target_name, sizeof(target_name) );
		PerformSwitch( target, true );
		CPrintToChatAll( "[SM] %t {lightgreen}%s {default}%t", "ts admin switch", target_name, "ts to spectators" );
	}
	
  return Plugin_Handled;
}
	
/** Event handlers */

public Event_PlayerDeath( Handle:event, const String:name[], bool:dontBroadcast )
{
	new victim = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( switchOnDeath[victim] )
  {
		PerformTimedSwitch( victim );
		switchOnDeath[victim] = false;
	}
}

public Event_RoundEnd( Handle:event, const String:name[], bool:dontBroadcast )
{
	if( !onRoundEndPossible )
		return;
	
	for( new i = 0; i < TEAMSWITCH_ARRAY_SIZE; i++ )
  {
		if( switchOnRoundEnd[i] )
    {
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
	// Блокировка вызова меню дважды
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
			Format( buffer, maxlength, "%t", "ts when" );
		case TopMenuAction_DisplayOption:
			Format( buffer, maxlength, "%t", "ts commands" );
		}
	}

public Handle_ModeImmed( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%t", "ts immediately" );
		}
	else if( action == TopMenuAction_SelectOption){
		ShowPlayerSelectionMenu( param, TeamSwitchEvent_Immediately );
		}
	}

public Handle_ModeDeath( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%t", "ts on death" );
		}
	else if( action == TopMenuAction_SelectOption){
		ShowPlayerSelectionMenu( param, TeamSwitchEvent_OnDeath );
		}
	}

public Handle_ModeRend( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%t", "ts on round end" );
		}
	else if( action == TopMenuAction_SelectOption){
		ShowPlayerSelectionMenu( param, TeamSwitchEvent_OnRoundEnd );
		}
	}

public Handle_ModeSpec( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%t", "ts to spec" );
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
	
	SetMenuTitle(		playerMenu, "%t", "ts choose player"	);
	SetMenuExitButton(	playerMenu, true		);
	SetMenuExitBackButton(	playerMenu, true		);
	
	// Now add players to it
	// I'm aware there is a function AddTargetsToMenu in the SourceMod API, but I don't
	// use that one because it does not display the team the clients are in.
	new cTeam = 0,
				mc = GetMaxClients();
	
	decl String:cName[45],
			String:buffer[50],
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
				case TeamSwitchEvent_OnDeath:{
					Format( buffer, sizeof(buffer),
						"[%s] [%s] %s",
						( switchOnDeath[i] ? 'x' : ' ' ),
						( cTeam == 2 ? teamName1 : teamName2 ),
						cName
						);}
				case TeamSwitchEvent_OnRoundEnd:{
					Format( buffer, sizeof(buffer),
						"[%s] [%s] %s",
						( switchOnRoundEnd[i] ? 'x' : ' ' ),
						( cTeam == 2 ? teamName1 : teamName2 ),
						cName
						);}
				}
			
			IntToString( i, cBuffer, sizeof(cBuffer) );
			
			AddMenuItem( playerMenu, cBuffer, buffer );
			}
		}
	
	// Открываем меню для наших админов
	if( item == 0 )
		DisplayMenu( playerMenu, client, 30 );
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
	
	
void:Handle_Switch( TeamSwitchEvent:event, Handle:playerMenu, MenuAction:action, client, param )
{
	switch( action )
  {
		case MenuAction_Select:
    {
			decl String:info[5];
			GetMenuItem( playerMenu, param, info, sizeof(info) );
			new target = StringToInt( info );
			
			switch( event )
      {
				case TeamSwitchEvent_Immediately:
        {
	         PerformSwitch( target );
	         decl String:target_name[50];
	         GetClientName( target, target_name, sizeof(target_name) );
	         CPrintToChatAll( "[SM] %t {lightgreen}%s {default}%t", "ts admin switch", target_name, "ts opposite team" );
			  }
				case TeamSwitchEvent_OnDeath:
        {
					// If alive: player must be listed in OnDeath array
					if( IsPlayerAlive( target ) )
          {
						// If alive, toggle status
						switchOnDeath[target] = !switchOnDeath[target];
					}
					else	// Switch right away
	          PerformSwitch( target );
	
          if(switchOnDeath[target])
          {
	          decl String:target_name[50];
	          GetClientName( target, target_name, sizeof(target_name));
            CPrintToChatAll( "[SM] {lightgreen}%s {default}%t", target_name, "ts will be switch to apposite team on death");
	        }
	        else
          {
            decl String:target_name[50];
          	GetClientName( target, target_name, sizeof(target_name) );
	          CPrintToChatAll( "[SM] {lightgreen}%s {default}%t", target_name, "ts will not be switch to apposite team on death");
      	  }
				}
				case TeamSwitchEvent_OnRoundEnd:
        {
				  // Toggle status
	        switchOnRoundEnd[target] = !switchOnRoundEnd[target];
	        if(switchOnRoundEnd[target])
          {
	           decl String:target_name[50];
	           GetClientName( target, target_name, sizeof(target_name) );
	           CPrintToChatAll( "[SM] {lightgreen}%s {default}%t", target_name, "ts will be switch to apposite team on rounend");
	        }
		      else
          { 
	           decl String:target_name[50];
	           GetClientName( target, target_name, sizeof(target_name) );
	           CPrintToChatAll( "[SM] {lightgreen}%s {default}%t", target_name, "ts will not be switch to apposite team on rounend"); 
		      }
	      }
				case TeamSwitchEvent_ToSpec:
        {
	         PerformSwitch( target, true );
	         decl String:target_name[50];
	         GetClientName( target, target_name, sizeof(target_name) );
	         CPrintToChatAll( "[SM] %t {lightgreen}%s {default}%t", "ts admin switch", target_name, "ts to spectators" );
				}
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




void:PerformTimedSwitch( client )
{
	CreateTimer( 0.5, Timer_TeamSwitch, client );
}

public Action:Timer_TeamSwitch( Handle:timer, any:client )
{
	if( IsClientInGame( client ) )
		PerformSwitch( client );
	return Plugin_Stop;
}

void:PerformSwitch( client, bool:toSpec = false )
{
	new cTeam = GetClientTeam( client ),
			toTeam = ( toSpec ? TEAM_SPEC : TEAM_1 + TEAM_2 - cTeam );
	
	if( cstrikeExtAvail && !toSpec )
  {
	   CS_SwitchTeam( client, toTeam );
	   if(cTeam == TEAM_2)
     {
	      SetEntityModel(client,"models/player/t_leet.mdl");
     } 
     else
     {
        SetEntityModel(client,"models/player/ct_sas.mdl");
     }
	   /*if(GetPlayerWeaponSlot(client, 4) != -1) {SDKCall(hDropWeapon, client, GetPlayerWeaponSlot(client, 4), false, false);}*/
  }
	else	ChangeClientTeam( client, toTeam );
	
	decl String:plName[40];
	GetClientName( client, plName, sizeof(plName) );
	CPrintToChatAll("[SM] {lightgreen}%s {default}%t", plName, "ts switch by admin");
}