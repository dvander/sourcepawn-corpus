
/**********************************************************************************
 *                                                                                *
 *   THIS IS A REWRITE OF THE WARRIORMOD CLANWAR MANAGER                          *
 *                                                                                *
 * This plugin handles a complete ClanWar, including:                             *
 * - Restarts                                                                     *
 * - Score counting                                                               *
 * - Loading Server configuration (ESL)                                           *
 * - Recording SrcTV demos                                                        *
 *                                                                                *
 * Since this plugin is a rewrite of my original MetaMod:Source plugin, version   *
 * numbering starts at 2.0.0.                                                     *
 *                                                                                *
 * Idea, coding and testing by Michael "MistaGee" Ziegler                         *
 *                                                                                *
 * Published as free software under the terms of the                              *
 * GNU General Public License (GPL) v2 or above.                                  *
 * This program is distributed in the hope that it will be useful, but WITHOUT    *
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS  *
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more         *
 * details.                                                                       *
 *                                                                                *
 **********************************************************************************/


// Fuer TeamName-Detection geil:
// http://forums.alliedmods.net/showthread.php?t=55012

#include <sourcemod>
#include <sdktools>
#include <cstrike>

// Make the admin menu plugin optional
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define WAR_ADMINFLAG ADMFLAG_CUSTOM1

#define WARRIORMOD_VERSION "2.0.13"

#define TEAMINDEX_T  2
#define TEAMINDEX_CT 3

// Globals
new	Handle:hAdminMenu = INVALID_HANDLE,
	Handle:cvar_maxrounds,
	Handle:cvar_maxrounds_wu,
	Handle:cvar_nextmap,
	Handle:cvar_vote,
	Handle:cvar_fadetoblack,
	Handle:cvar_pausable,
	Handle:cvar_record,
	Handle:cvar_config,
	Handle:cvar_config_end,
	Handle:theMapMenu = INVALID_HANDLE,
	bool:config_done = false,
	max_clients,
	rounds_played,
	rounds2play,
	players_t,
	players_ct,
	score_t,
	score_ct,
	mp_freezetime = 0,
	bool:teamsizes_uneq_checked = false,
	restarts_remaining = 0,
	bool:war_wu_running    = false,
	bool:war_knife_running = false,
	bool:war_live_running  = false,
	bool:war_teams_changed = false,
	war_teamchanges_remaining = 0,
	String:xonx[6],
	String:theConf[40],
	clientTeam[40];


public Plugin:myinfo = {
	name = "WarriorMod",
	author = "MistaGee",
	description = "Handles a complete Clan War",
	version = WARRIORMOD_VERSION,
	url = "http://www.sourcemod.net/"
	}

public OnPluginStart(){
	cvar_maxrounds   = CreateConVar( "war_rounds",      "12",    "How many rounds to play", FCVAR_NOTIFY );
	cvar_maxrounds_wu= CreateConVar( "war_rounds_wu",   "5",     "How many rounds to play in warmup", FCVAR_NOTIFY );
	cvar_nextmap     = CreateConVar( "war_next_map",    "",      "Map to change to after current war", FCVAR_NOTIFY );
	cvar_config      = CreateConVar( "war_config",      "esl%s", "Config to exec - %s will be replaced by e.g. 3on3", FCVAR_NOTIFY );
	cvar_vote        = CreateConVar( "war_vote",        "0",     "Vote for rdy before starting Knife/Live?", FCVAR_NOTIFY );
	cvar_config_end  = CreateConVar( "war_config_end",  "",      "Config to exec on war_reset", FCVAR_NOTIFY );
	cvar_fadetoblack = CreateConVar( "war_fadetoblack", "0",     "If not -1, set mp_fadetoblack to this value after loading config", FCVAR_NOTIFY );
	cvar_pausable    = CreateConVar( "war_pausable",    "0",     "If not -1, set sv_pausable to this value after loading config", FCVAR_NOTIFY    );
	cvar_record      = CreateConVar( "war_record",      "1",     "Record a demo? (Requires SrcTV!)", FCVAR_NOTIFY );
	
	// Version cVar. Somehow this doesn't get updated properly when plugin is reloaded, so I update myself.
	new Handle:cvar_version = CreateConVar( "war_version", WARRIORMOD_VERSION, "WarriorMod Version", FCVAR_NOTIFY );
	SetConVarString( cvar_version, WARRIORMOD_VERSION );
	
	RegAdminCmd( "war_warmup",    Command_Warmup,    WAR_ADMINFLAG );
	RegAdminCmd( "war_knife",     Command_Knife,     WAR_ADMINFLAG );
	RegAdminCmd( "war_live",      Command_Live,      WAR_ADMINFLAG );
	RegAdminCmd( "war_reset",     Command_Reset,     WAR_ADMINFLAG );
	RegAdminCmd( "war_maxrounds", Command_Maxrounds, WAR_ADMINFLAG );
	RegAdminCmd( "war_nextmap",   Command_Nextmap,   WAR_ADMINFLAG );
	
	HookEvent( "round_start",  Event_RoundStart, EventHookMode_PostNoCopy );
	HookEvent( "round_end",    Event_RoundEnd    );
	HookEvent( "player_team",  Event_PlayerTeam  );
	HookEvent( "player_spawn", Event_PlayerSpawn );
	HookEvent( "weapon_fire",  Event_WeaponFire  );
	
	AutoExecConfig( true, "warriormod" );
	
	LoadTranslations( "warriormod.phrases" );
	LoadTranslations( "common.phrases" );
	
	// See if the menu plugin is ready
	new Handle:topmenu;
	if( LibraryExists( "adminmenu" ) && ( ( topmenu = GetAdminTopMenu() ) != INVALID_HANDLE ) ){
		OnAdminMenuReady( topmenu );
		}
	}

/******************************************************************************************
 *                                ADMINISTRATIVE COMMANDS                                 *
 ******************************************************************************************/

public Action:Command_Warmup( client, args ){
	// start Warmup
	// no config except startmoney = 16k, one rr
	war_wu_running = true;
	mp_freezetime = GetConVarInt( FindConVar( "mp_freezetime" ) );
	SetConVarInt( FindConVar( "mp_startmoney" ), 16000, true, true );
	ServerCommand( "mp_restartgame 1" );
	
	rounds_played = 1;
	rounds2play = GetConVarInt( cvar_maxrounds_wu );
	
	return Plugin_Handled;
	}

public Action:Command_Knife( client, args ){
	if( GetConVarBool( cvar_vote ) ){
		war_live_running = false;
		war_knife_running = false;
		war_wu_running = false;
		if( !IsVoteInProgress() ){
			new Handle:menu = CreateMenu( Handle_VoteKnifeRound )
			new String:janein[30];
			
			SetMenuTitle( menu, "%T", "rdy for knives?", client )
			
			Format( janein, sizeof(janein), "%T", "Yes", client );
			AddMenuItem(menu, "0", janein )
			
			Format( janein, sizeof(janein), "%T", "No",  client );
			AddMenuItem(menu, "1", janein )
			
			SetMenuExitButton(menu, false)
			VoteMenuToAll( menu, 30 );
			}
		return Plugin_Handled;
		}
	else	return Command_Knife_Real( client, args );
	}

public Action:Command_Knife_Real( client, args ){
	if( !config_done && !WarInit( client ) ){
		return Plugin_Handled;
		}
	
	/*PrintToChatAll( "   _  ___   _ ___ _____ _____   " );
	PrintToChatAll( "  | |/ / \\ | |_ _|  ___| ____|  " );
	PrintToChatAll( "  | ' /|  \\| || || |_  |  _|    " );
	PrintToChatAll( "  | . \\| |\\  || ||  _| | |___   " );
	PrintToChatAll( "  |_|\\_\\_| \\_|___|_|   |_____|  " );*/
	
	restarts_remaining = 2;
	ServerCommand( "mp_restartgame 3" );
	war_wu_running = false;
	war_knife_running = true;
	war_live_running = false;
	
	PrintToChatAll( "[WAR] %T", "knife starting", LANG_SERVER );
	return Plugin_Handled;
	}

public Action:Command_Live( client, args ){
	if( GetConVarBool( cvar_vote ) ){
		war_live_running = false;
		war_knife_running = false;
		war_wu_running = false;
		if( !IsVoteInProgress() ){
			new Handle:menu = CreateMenu( Handle_VoteLiveRound )
			new String:janein[30];
			
			SetMenuTitle( menu, "%T", "rdy for live?", client )
			
			Format( janein, sizeof(janein), "%T", "Yes", client );
			AddMenuItem(menu, "0", janein )
			
			Format( janein, sizeof(janein), "%T", "No",  client );
			AddMenuItem(menu, "1", janein )
			
			SetMenuExitButton(menu, false)
			VoteMenuToAll( menu, 30 );
			}
		return Plugin_Handled;
		}
	else	return Command_Live_Real( client, args );
	}

public Action:Command_Live_Real( client, args ){
	if( !config_done && !WarInit( client ) ){
		return Plugin_Handled;
		}
	
	/*PrintToChatAll( "   _       _____       _______  " );
	PrintToChatAll( "  |  |      |_ _\\  \\      /  /  ____| " );
	PrintToChatAll( "  |  |        | | \\  \\  /  /|   _|   " );
	PrintToChatAll( "  |  |___  |  |    \\  V / |  |___  " );
	PrintToChatAll( "  |_____|___|    \\_/    |_____| " );*/
	
	restarts_remaining = 2;
	ServerCommand( "mp_restartgame 3" );
	war_wu_running = false;
	war_knife_running = false;
	war_live_running = true;
	
	PrintToChatAll( "[WAR] %T", "live starting", LANG_SERVER );
	
	if( !war_teams_changed ){
		StoreClientTeams();
		}
	
	return Plugin_Handled;
	}

public Action:Command_Reset( client, args ){
	war_wu_running
		= war_knife_running
		= war_live_running
		= config_done
		= teamsizes_uneq_checked
		= false;
	
	if( GetConVarBool( cvar_record ) ){
		ServerCommand( "tv_stoprecord" );
		}
	
	new String:conf[40];
	GetConVarString( cvar_config_end, conf, sizeof(conf) );
	if( !StrEqual( conf, "" ) ){
		ServerCommand( "exec %s", conf );
		ServerExecute();
		}
	
	PrintToChatAll( "[WAR] %T", "plugin reset", LANG_SERVER );
	return Plugin_Handled;
	}

public Action:Command_Maxrounds( client, args ){
	// Set war_rounds to first arg
	if( args < 1 ){
		ReplyToCommand( client, "[WAR] %T", "usage: war_maxrounds", client, GetConVarInt( cvar_maxrounds ) );
		return Plugin_Handled;
		}
	
	new String:thecount[4];
	GetCmdArg( 1, thecount, sizeof( thecount ) );
	
	SetConVarInt( cvar_maxrounds, StringToInt( thecount ), false, ( !war_knife_running && !war_live_running ) );
	
	return Plugin_Handled;
	}

public Action:Command_Nextmap( client, args ){
	// Set war_rounds to first arg
	new String:themap[40];
	if( args < 1 ){
		GetConVarString( cvar_nextmap, themap, sizeof(themap) );
		if( StrEqual( themap, "" ) ){
			strcopy( themap, sizeof(themap), "None" );
			}
		ReplyToCommand( client, "[WAR] %T", "usage: war_nextmap", client, themap );
		return Plugin_Handled;
		}
	
	GetCmdArg( 1, themap, sizeof(themap) );
	
	if( !IsMapValid( themap ) ){
		ReplyToCommand( client, "[WAR] %T", "Map was not found", client, themap );
		return Plugin_Handled;
		}
	
	new String:currentMap[40];
	GetCurrentMap( currentMap, sizeof(currentMap) );
	if( StrEqual( currentMap, themap, false ) ){
		ReplyToCommand( client, "[WAR] %T", "map running", client, themap );
		return Plugin_Handled;
		}
	
	SetConVarString( cvar_nextmap, themap, false, true );
	
	return Plugin_Handled;
	}

/******************************************************************************************
 *                                     EVENT HANDLERS                                     *
 ******************************************************************************************/

public OnMapStart(){
	max_clients = GetMaxClients();
	theMapMenu = BuildMapMenu()
	}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	// Are any restarts left to be done? Then do them
	if( restarts_remaining > 0 ){
		ServerCommand( "mp_restartgame %d", restarts_remaining );
		restarts_remaining--;
		}
	else if( war_live_running ){
		PrintToServer( "[WAR] Round %d/%d - Team1 %d - Team2 %d", rounds_played, rounds2play, score_t, score_ct );
		}
	}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	new	winTeamId = GetEventInt( event, "winner" );
	
	if( war_wu_running ){
		rounds_played++;
		if( rounds_played >= rounds2play ){
			// Start a vote: 1. Not ready 2. Knife round 3. Live
			// Vote until knife or live was selected
			if( !IsVoteInProgress() ){
				new Handle:menu = CreateMenu( Handle_VoteWarmupEnd )
				new String:optstr[30];
				
				
				SetMenuTitle( menu,             "%T", "what now?",       LANG_SERVER )
				
				Format( optstr, sizeof(optstr), "%T", "continue warmup", LANG_SERVER )
				AddMenuItem(  menu, "0", optstr )
				
				Format( optstr, sizeof(optstr), "%T", "start knife",     LANG_SERVER )
				AddMenuItem(  menu, "1", optstr )
				
				Format( optstr, sizeof(optstr), "%T", "start live",      LANG_SERVER )
				AddMenuItem(  menu, "2", optstr )
				
				SetMenuExitButton(menu, false)
				VoteMenuToAll( menu, 30 );
				}
			}
		}
	else if( war_knife_running ){
		if( restarts_remaining > 0 ){
				return;
				}
		PrintToServer( "Team %d voting for stay/leave.", winTeamId );
		DisplayStayLeaveVote( winTeamId );
		}
	else if( war_live_running ){
		if( restarts_remaining == 0 && war_teamchanges_remaining == 0 ){
			if( !war_teams_changed ){
				switch( winTeamId ){
					case TEAMINDEX_T:
						score_t++;
					case TEAMINDEX_CT:
						score_ct++;
					}
				}
			else{
				switch( winTeamId ){
					case TEAMINDEX_T:
						score_ct++;
					case TEAMINDEX_CT:
						score_t++;
					}
				}
			rounds_played++;
			}
		if( rounds_played == rounds2play ){
			// First half is over
			if( !war_teams_changed ){
				// war_teamchanges_remaining = players_t + players_ct;
				war_teams_changed = true;
				
				for( new i = 1; i <= max_clients; i++ ){
					if( IsClientInGame(i) && clientTeam[i] >= TEAMINDEX_T ){
						// Switch
						CS_SwitchTeam( i, 5 - clientTeam[i] );
						}
					}
				Command_Live( 0, 0 );
				}
			PrintToChatAll( "[WAR] %T", "teamchange please", LANG_SERVER );
			}
		else if( rounds_played == rounds2play * 2 ){
			// War is over
			PrintToChatAll( "[WAR] WAR OVER -- SCORE: Team1 %d - Team2 %d", score_t, score_ct );
			Command_Reset(0,0);
			
			// Check nextmap thing
			new String:theNextMap[40];
			GetConVarString( cvar_nextmap, theNextMap, sizeof(theNextMap) );
			if( !StrEqual( theNextMap, "" ) && IsMapValid( theNextMap ) ){
				// Set mapchange timer, notify players, unset cvar
				new Handle:dp;
				CreateDataTimer(5.0, Timer_ChangeMap, dp);
				WritePackString(dp, theNextMap);
				
				PrintToChatAll( "[WAR] %T", "Changing map", LANG_SERVER, theNextMap );
				
				SetConVarString( cvar_nextmap, "" );
				}
			}
		}
	}

public Event_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast){
	if( war_teamchanges_remaining == 0 ){
		return;
		}
	war_teamchanges_remaining--;
	if( war_teamchanges_remaining == 0 ){
		Command_Live( 0, 0 );
		}
	}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast){
	// This event is only hooked during Knife round
	// If someone fires something other than the knife, the opposite team wins.
	if( !war_knife_running || restarts_remaining > 0 ){
		return;
		}
	
	new String:weap[10];
	GetEventString( event, "weapon", weap, sizeof(weap) );
	PrintToServer( "[WAR] Player used weapon %s.", weap );
	
	if( !StrEqual( "knife", weap ) ){
		new theClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
		ForcePlayerSuicide( theClient );
		DisplayStayLeaveVote( 5 - GetClientTeam( theClient ) );
		}
	}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	if( restarts_remaining > 0 || IsVoteInProgress() ){
		return;
		}
	
	new theClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( war_wu_running ){
		new Handle:panel = CreatePanel();
		new String:roundnr[20];
		SetPanelTitle( panel, "WARMUP" );
		Format( roundnr, sizeof(roundnr), "%T", "round x of y", theClient, rounds_played, rounds2play );
		DrawPanelText( panel, roundnr );
		SendPanelToClient( panel, theClient, Handle_Panel, mp_freezetime-1 );
		CloseHandle( panel );
		}
	else if( war_knife_running ){
		StripWeaponsButKnife( theClient );
		new Handle:panel = CreatePanel();
		SetPanelTitle( panel, "KNIFE" );
		DrawPanelText( panel, "Drop or lose" );
		SendPanelToClient( panel, theClient, Handle_Panel, mp_freezetime-1 );
		CloseHandle( panel );
		}
	else if( war_live_running ){
		new Handle:panel = CreatePanel();
		SetPanelTitle( panel, "LIVE" );
		DrawPanelItem( panel, "", ITEMDRAW_SPACER );
		
		new String:roundnr[20];
		
		new thisround = rounds_played + 1
		if( thisround < rounds2play ){
			Format( roundnr, sizeof(roundnr), "%T", "round x of y", theClient, thisround, rounds2play );
			}
		else if( thisround == rounds2play || thisround == rounds2play * 2 ){
			Format( roundnr, sizeof(roundnr), "%T", "last round", theClient );
			}
		else if( thisround > rounds2play ){
			if( war_teamchanges_remaining > 0 ){
				Format( roundnr, sizeof(roundnr), "%T", "teamchange please", theClient );
				}
			else if( restarts_remaining == 0 ){
				Format( roundnr, sizeof(roundnr), "%T", "round x of y", theClient, thisround - rounds2play, rounds2play );
				}
			}
		
		DrawPanelText( panel, roundnr );
		
		if( rounds_played < rounds2play )
			Format( roundnr, sizeof(roundnr), "%T", "first half",  theClient );
		else
			Format( roundnr, sizeof(roundnr), "%T", "second half", theClient );
		DrawPanelText( panel, roundnr );
		
		DrawPanelItem( panel, "", ITEMDRAW_SPACER );
		
		Format( roundnr, sizeof(roundnr), "%T", "team x score y", theClient, 1, score_t );
		DrawPanelText( panel, roundnr );
	 
		Format( roundnr, sizeof(roundnr), "%T", "team x score y", theClient, 2, score_ct );
		DrawPanelText( panel, roundnr );
		
		// The inner thing calcs the team index of the team the player was originally in, that is: 2 = T, 3 = CT.
		// We substract 1 to have 1=T 2=CT, because that's the way they were when the war started.
		Format( roundnr, sizeof(roundnr), "%T", "youre in team x", theClient,
			( war_teams_changed ? 5-GetClientTeam(theClient) : GetClientTeam(theClient) )-1
			);
		DrawPanelText( panel, roundnr );
		
		SendPanelToClient( panel, theClient, Handle_Panel, mp_freezetime-1 );
	 
		CloseHandle( panel );
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
		// Menu     Name           Type                    Callback         Parent
		hAdminMenu, "wm_commands", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT
		);
	
	if( menu_category == INVALID_TOPMENUOBJECT ){
		// Error... lame...
		return;
		}
	
	// Now add items to it
	//            Menu        Name        Type                Callback             Parent         cmdname      Admin flag
	AddToTopMenu( hAdminMenu, "wm_mr",    TopMenuObject_Item, Handle_CmdMaxrounds, menu_category, "wm_mr",    WAR_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "wm_mrwu",  TopMenuObject_Item, Handle_CmdWarmuprounds, menu_category, "wm_mrwu",    WAR_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "wm_vote",  TopMenuObject_Item, Handle_CmdVote,      menu_category, "wm_vote",    WAR_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "wm_nm",    TopMenuObject_Item, Handle_CmdNextmap,   menu_category, "wm_nm",    WAR_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "wm_knife", TopMenuObject_Item, Handle_CmdKnife,     menu_category, "wm_knife", WAR_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "wm_warmup",TopMenuObject_Item, Handle_CmdWarmup,    menu_category, "wm_knife", WAR_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "wm_live",  TopMenuObject_Item, Handle_CmdLive,      menu_category, "wm_live",  WAR_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "wm_reset", TopMenuObject_Item, Handle_CmdReset,     menu_category, "wm_reset", WAR_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "wm_ban_t", TopMenuObject_Item, Handle_CmdBanT,      menu_category, "wm_ban_t", WAR_ADMINFLAG );
	AddToTopMenu( hAdminMenu, "wm_ban_ct",TopMenuObject_Item, Handle_CmdBanCT,     menu_category, "wm_ban_ct",WAR_ADMINFLAG );
	}

public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayTitle){
		Format( buffer, maxlength, "WarriorMod Commands:" );
		}
	else if (action == TopMenuAction_DisplayOption ){
		Format( buffer, maxlength, "WarriorMod Commands" );
		}
	}

public Handle_CmdWarmup( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%T", "start warmup", param );
		}
	else if (action == TopMenuAction_SelectOption){
		Command_Warmup( param, 0 );
		}
	}

public Handle_CmdKnife( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%T", "start knife", param );
		}
	else if (action == TopMenuAction_SelectOption){
		Command_Knife( param, 0 );
		}
	}

public Handle_CmdLive( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%T", "start live", param );
		}
	else if (action == TopMenuAction_SelectOption){
		Command_Live( param, 0 );
		}
	}

public Handle_CmdReset( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%T", "reset plugin", param );
		}
	else if (action == TopMenuAction_SelectOption){
		Command_Reset( param, 0 );
		}
	}

public Handle_CmdMaxrounds( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	new currentMrValue = GetConVarInt( cvar_maxrounds );
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%T", "maxrounds x", param, currentMrValue );
		}
	else if (action == TopMenuAction_SelectOption){
		switch( currentMrValue ){
				case 6:
					currentMrValue = 10;
				case 10:
					currentMrValue = 12;
				case 12:
					currentMrValue = 15;
				case 15:
					currentMrValue = 6;
				default:
					currentMrValue = 12;
			}
		SetConVarInt( cvar_maxrounds, currentMrValue, false, true );
		RedisplayAdminMenu( topmenu, param );
		}
	}

public Handle_CmdWarmuprounds( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	new currentMrValue = GetConVarInt( cvar_maxrounds_wu );
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%T", "warmup rounds x", param, currentMrValue );
		}
	else if (action == TopMenuAction_SelectOption){
		switch( currentMrValue ){
				case 5:
					currentMrValue = 10;
				case 10:
					currentMrValue = 15;
				case 15:
					currentMrValue = 5;
				default:
					currentMrValue = 5;
			}
		SetConVarInt( cvar_maxrounds_wu, currentMrValue, false, true );
		RedisplayAdminMenu( topmenu, param );
		}
	}

public Handle_CmdVote( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	new currentMrValue = GetConVarBool( cvar_vote );
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "Vote \"%T\":  %T",
			"ready", param,
			( currentMrValue ? "Yes" : "No" ), param
			);
		}
	else if (action == TopMenuAction_SelectOption){
		SetConVarInt( cvar_vote, !currentMrValue, false, true );
		RedisplayAdminMenu( topmenu, param );
		}
	}

public Handle_CmdNextmap( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if( action == TopMenuAction_DisplayOption ){
		new String:currentNmValue[40];
		GetConVarString( cvar_nextmap, currentNmValue, sizeof(currentNmValue) );
		if( StrEqual( currentNmValue, "" ) ){
			strcopy( currentNmValue, sizeof(currentNmValue), "None" );
			}
		Format( buffer, maxlength, "%T", "nextmap x", param, currentNmValue );
		}
	else if( action == TopMenuAction_SelectOption ){
		if( theMapMenu == INVALID_HANDLE ){
			PrintToChat( param, "The maplist.txt file was not found!" );
			}	
 		else{
			DisplayMenu( theMapMenu, param, MENU_TIME_FOREVER );
			}
		}
	}

public Menu_ChangeMap( Handle:menu, MenuAction:action, param1, param2 ){
	if( action == MenuAction_Select ){
		new String:info[40];
		GetMenuItem( menu, param2, info, sizeof(info) );
		SetConVarString( cvar_nextmap, info, false, true );
		}
	}

public Handle_CmdBanT( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%T", "ban team x", param, "T" );
		}
	else if (action == TopMenuAction_SelectOption){
		BanTeam( TEAMINDEX_T );
		Command_Reset( param, 0 );
		}
	}

public Handle_CmdBanCT( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength ){
	if (action == TopMenuAction_DisplayOption){
		Format( buffer, maxlength, "%T", "ban team x", param, "CT" );
		}
	else if (action == TopMenuAction_SelectOption){
		BanTeam( TEAMINDEX_CT );
		Command_Reset( param, 0 );
		}
	}

/******************************************************************************************
 *                                    VOTE MENU HANDLERS                                  *
 ******************************************************************************************/

public Handle_VoteStayLeave( Handle:menu, MenuAction:action, param1, param2 ){
	if( action == MenuAction_End ){
		CloseHandle(menu);
		}
	else if( action == MenuAction_VoteEnd ){
		// Stay or Leave has been voted by the winners, act accordingly
		if( param1 == 0 ){
			// Stay
			war_knife_running = false;
			Command_Live( 0, 0 );
			}
		else{
			// Testing: Autoswitch all clients
			new theClientTeam = 0;
			for( new i = 1; i <= max_clients; i++ ){
				if( IsClientInGame(i) && ( theClientTeam = GetClientTeam(i) ) >= TEAMINDEX_T ){
					// Switch
					CS_SwitchTeam( i, 5 - theClientTeam );
					}
				}
			
			war_knife_running = false;
			Command_Live( 0, 0 );
			}
		}
	}

public Handle_VoteWarmupEnd( Handle:menu, MenuAction:action, param1, param2 ){
	if( action == MenuAction_End ){
		CloseHandle(menu);
		}
	else if( action == MenuAction_VoteEnd ){
		// Stay or Leave has been voted by the winners, act accordingly
		if( param1 > 0 ){
			SetConVarInt( FindConVar( "mp_startmoney" ), 800 );
			switch( param1 ){
				case 1:
					// Kniferound
					Command_Knife_Real( 0, 0 );
				case 2:
					// Live
					Command_Live_Real( 0, 0 );
				// Called Real functions here, because if players ain't ready they won't vote
				// "start".
				}
			}
		}
	}

public Handle_Panel( Handle:menu, MenuAction:action, param1, param2 ){
	// This handles the panel, if the user fired it. Nothing to do here, just added to satisfy the compiler :/
	}

public Handle_VoteKnifeRound( Handle:menu, MenuAction:action, param1, param2 ){
	if( action == MenuAction_End ){
		CloseHandle(menu);
		}
	else if( action == MenuAction_VoteEnd ){
		// Stay or Leave has been voted by the winners, act accordingly
		if( param1 == 0 ){
			Command_Knife_Real( 0, 0 );
			}
		}
	}

public Handle_VoteLiveRound( Handle:menu, MenuAction:action, param1, param2 ){
	if( action == MenuAction_End ){
		CloseHandle(menu);
		}
	else if( action == MenuAction_VoteEnd ){
		// Stay or Leave has been voted by the winners, act accordingly
		if( param1 == 0 ){
			Command_Live_Real( 0, 0 );
			}
		}
	}


/******************************************************************************************
 *                                   HELPER FUNCTIONS                                     *
 ******************************************************************************************/

public Action:Timer_ChangeMap(Handle:timer, Handle:dp){
	// Shamelessly ripped from basecommands/map.sp.
	decl String:map[65];
	
	ResetPack(dp);
	ReadPackString(dp, map, sizeof(map));
	
	ServerCommand("changelevel \"%s\"", map);
	
	return Plugin_Stop;
	}

bool:WarInit( client = 0 ){
	rounds_played = 0;
	rounds2play   = GetConVarInt( cvar_maxrounds );
	
	players_t  = GetTeamClientCount( TEAMINDEX_T  );
	players_ct = GetTeamClientCount( TEAMINDEX_CT );
	
	mp_freezetime = GetConVarInt( FindConVar( "mp_freezetime" ) );
	
	if( players_t == 0 || players_ct == 0 ){
		PrintToServer( "[WAR] One team has no players..." );
		if( client != 0 ){
			PrintToChat( client, "[WAR] %T", "one team empty", client );
			}
		return false;
		}
	if( players_t != players_ct && !teamsizes_uneq_checked ){
		PrintToServer( "[WAR] Number of players in teams is not eqal." );
		PrintToServer( "      Repeat command to start anyway." );
		if( client != 0 ){
				PrintToChat( client, "[WAR] %T", "number not eqal", client );
				PrintToChat( client, "      %T", "repeat command",  client );
				}
		teamsizes_uneq_checked = true;
		return false;
		}
	
	war_knife_running = false;
	war_live_running  = false;
	war_teams_changed = false;
	score_t = score_ct = 0;
	
	// Load ESL Configs
	new plconf = RoundToFloor( ( players_t + players_ct ) / 2.0 );
	
	if( plconf >= 5 ){
		Format( xonx, sizeof( xonx ), "5on5" );
		}
	else{
		Format( xonx, sizeof( xonx ), "%don%d", plconf, plconf );
		}
	
	new String:confNameBuffer[40];
	GetConVarString( cvar_config, confNameBuffer, sizeof(confNameBuffer) );
	
	// ConfNameBuffer is something like esl%s. Now we put the xonx value in
	Format( theConf, sizeof(theConf), confNameBuffer, xonx );
	
	// Exec the config immediately so the cvars will be set correctly
	ServerCommand( "exec %s", theConf );
	ServerExecute();
	
	new ConVarValue_ftb = GetConVarInt( cvar_fadetoblack );
	if( ConVarValue_ftb != -1 ){
		SetConVarInt( FindConVar( "mp_fadetoblack" ), ConVarValue_ftb );
		}
	
	new ConVarValue_pausable = GetConVarInt( cvar_pausable );
	if( ConVarValue_pausable != -1 ){
		SetConVarInt( FindConVar( "sv_pausable" ), ConVarValue_pausable );
		}
	
	if( GetConVarBool( cvar_record ) ){
		// TODO: Name
		ServerCommand( "tv_record a_clanwar_demo" );
		}
	
	config_done = true;
	return true;
	}

DisplayStayLeaveVote( winTeamId ){
	// Maybe these guys are _still_ voting? Then don't send a new vote.
	if( !IsVoteInProgress() ){
		new Handle:menu = CreateMenu( Handle_VoteStayLeave )
		SetMenuTitle(menu, "Teams?")
		AddMenuItem(menu, "0", "Stay")
		AddMenuItem(menu, "1", "Leave")
		SetMenuExitButton(menu, false)
		
		new UsersInTeam[16],
		    UsersCount = 0;
		
		for( new i = 1; i <= max_clients; i++ ){
			if( IsClientInGame(i) && GetClientTeam(i) == winTeamId ){
				UsersInTeam[UsersCount++] = i;
				}
			}
		
		VoteMenu( menu, UsersInTeam, UsersCount, 30 );
		}
	}

StoreClientTeams(){
	for( new i = 1; i <= max_clients; i++ ){
		if( IsClientInGame(i) ){
			clientTeam[i] = GetClientTeam(i);
			}
		}
	}

StripWeaponsButKnife( client ){
	new wepIdx;
	// Iterate through weapon slots
	for( new i = 0; i < 5; i++ ){
		if( i == 2 ) continue; // You can leeeeave your knife on...
		// Strip all weapons from current slot
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ){
			RemovePlayerItem( client, wepIdx );
			}
		}
	// Now switch to knife
	ClientCommand( client, "slot3" );
	}


Handle:BuildMapMenu()
	// Shamelessly ripped from http://wiki.alliedmods.net/Menu_API_%28SourceMod%29#Basic_Paginated_Menu
{
	/* Open the file */
	new Handle:file = OpenFile("maplist.txt", "rt")
	if (file == INVALID_HANDLE)
	{
		return INVALID_HANDLE
	}
 
	/* Create the menu Handle */
	new Handle:menu = CreateMenu(Menu_ChangeMap);
	new String:mapname[255]
	while (!IsEndOfFile(file) && ReadFileLine(file, mapname, sizeof(mapname)))
	{
		if (mapname[0] == ';' || !IsCharAlpha(mapname[0]))
		{
			continue
		}
		/* Cut off the name at any whitespace */
		new len = strlen(mapname)
		for (new i=0; i<len; i++)
		{
			if (IsCharSpace(mapname[i]))
			{
				mapname[i] = '\0'
				break
			}
		}
		/* Check if the map is valid */
		if (!IsMapValid(mapname))
		{
			continue
		}
		/* Add it to the menu */
		AddMenuItem(menu, mapname, mapname)
	}
	/* Make sure we close the file! */
	CloseHandle(file)
 
	/* Finally, set the title */
	SetMenuTitle( menu, "%T", "select map", LANG_SERVER )
 
	return menu
}
 
void:BanTeam( theTeamIndex ){
	for( new i = 1; i <= max_clients; i++ ){
		if( IsClientInGame(i) && GetClientTeam(i) == theTeamIndex ){
			BanClient( i, 60, BANFLAG_AUTO, "Banned by Admin." );
			}
		}
	}
