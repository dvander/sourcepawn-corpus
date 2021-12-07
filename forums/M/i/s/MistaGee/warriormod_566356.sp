
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
 * Idea, coding and testing by Michael "Svedrin" Ziegler                          *
 * Contact: mailto:diese-addy@funzt-halt.net - JID:mistagee@jabber.funzt-halt.net *
 *                                                                                *
 * Published as free software under the terms of the                              *
 * GNU General Public License (GPL) v2 or above.                                  *
 * This program is distributed in the hope that it will be useful, but WITHOUT    *
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS  *
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more         *
 * details.                                                                       *
 *                                                                                *
 **********************************************************************************/

#pragma semicolon 1

// Fuer TeamName-Detection geil:
// http://forums.alliedmods.net/showthread.php?t=55012

#include <sourcemod>
#include <sdktools>
#include <cstrike>

// Make the admin menu plugin optional
#undef REQUIRE_PLUGIN
#include <adminmenu>

#define WAR_ADMINFLAG ADMFLAG_CUSTOM1

#define WARRIORMOD_VERSION "2.1.10"

#define TEAMINDEX_NONE	  0
#define TEAMINDEX_SPEC	  1
#define TEAMINDEX_T	      2
#define TEAMINDEX_CT      3


#define MODE_NONE         0
#define MODE_WARMUP       1
#define MODE_KNIFE        2
#define MODE_LIVE         3
#define MODE_SUDDENDEATH  4

#define rounds_played ( score_t + score_ct )

// Globals
new	Handle:hAdminMenu = INVALID_HANDLE,
	Handle:cvar_maxrounds,
	Handle:cvar_maxrounds_wu,
	Handle:cvar_nextmap,
	Handle:cvar_vote,
	Handle:cvar_fadetoblack,
	Handle:cvar_friendlyfire,
	Handle:cvar_pausable,
	Handle:cvar_record,
	Handle:cvar_config,
	Handle:cvar_finish,
	Handle:cvar_money,
	Handle:cvar_config_end,
	Handle:cvar_suddendeath,
	Handle:theMapMenu = INVALID_HANDLE,
	Handle:dbase = INVALID_HANDLE,
	bool:config_done = false,
	max_clients,
	rounds2play,
	players_t,
	players_ct,
	score_t,
	score_ct,
	score_t_half,
	score_ct_half,
	bool:mp_friendlyfire = true,
	mp_freezetime = 0,
	mp_startmoney = 800,
	bool:teamsizes_uneq_checked = false,
	restarts_remaining = 0,
	war_mode = MODE_NONE,
	bool:war_teams_changed = false,
	war_teamchanges_remaining = 0,
	war_action_on_round_end = MODE_NONE,
	String:xonx[6],
	String:theConf[40],
	String:teamName1[40],
	String:teamName2[40],
	clientTeam[40],
	offset_money;


public Plugin:myinfo = {
	name = "WarriorMod",
	author = "Svedrin",
	description = "Handles a complete Clan War",
	version = WARRIORMOD_VERSION,
	url = "http://www.sourcemod.net/"
	}

public OnPluginStart(){
	cvar_maxrounds    = CreateConVar( "war_rounds",      "12",    "How many rounds to play", FCVAR_NOTIFY );
	cvar_maxrounds_wu = CreateConVar( "war_rounds_wu",   "5",     "How many rounds to play in warmup", FCVAR_NOTIFY );
	cvar_nextmap      = CreateConVar( "war_next_map",    "",      "Map to change to after current war", FCVAR_NOTIFY );
	cvar_config       = CreateConVar( "war_config",      "esl%s", "Config to exec - %s will be replaced by e.g. 3on3", FCVAR_NOTIFY );
	cvar_vote         = CreateConVar( "war_vote",        "0",     "Vote for rdy before starting Knife/Live?", FCVAR_NOTIFY );
	cvar_config_end   = CreateConVar( "war_config_end",  "",      "Config to exec on war_reset", FCVAR_NOTIFY );
	cvar_fadetoblack  = CreateConVar( "war_fadetoblack", "0",     "If not -1, set mp_fadetoblack to this value after loading config", FCVAR_NOTIFY );
	cvar_pausable     = CreateConVar( "war_pausable",    "0",     "If not -1, set sv_pausable to this value after loading config", FCVAR_NOTIFY    );
	cvar_record       = CreateConVar( "war_record",      "1",     "Record a demo? (Requires SrcTV!)", FCVAR_NOTIFY );
	cvar_finish       = CreateConVar( "war_finish",      "1",     "Always finish wars? If 0, war is cancelled after one team has won", FCVAR_NOTIFY );
	cvar_money        = CreateConVar( "war_showmoney",   "0",     "Show teammate's cash in status panel?", FCVAR_NOTIFY );
	cvar_suddendeath  = CreateConVar( "war_suddendeath", "1",     "Play Sudden Death on a draw?", FCVAR_NOTIFY );
	
	cvar_friendlyfire = FindConVar( "mp_friendlyfire" );
	
	// Version cVar. Somehow this doesn't get updated properly when plugin is reloaded, so I update myself.
	new Handle:cvar_version = CreateConVar( "war_version", WARRIORMOD_VERSION, "WarriorMod Version", FCVAR_NOTIFY | FCVAR_DONTRECORD );
	
	RegConsoleCmd( "say",		Command_Say	);
	RegConsoleCmd( "say_team",	Command_Say	);
	RegConsoleCmd( "buy",		Command_Buy	);
	RegConsoleCmd( "score", 	Command_Score	);
	
	RegAdminCmd( "war_warmup",	Command_Warmup,		WAR_ADMINFLAG );
	RegAdminCmd( "war_knife",	Command_Knife,		WAR_ADMINFLAG );
	RegAdminCmd( "war_live",	Command_Live,		WAR_ADMINFLAG );
	RegAdminCmd( "war_knife_end",	Command_KnifeEnd,	WAR_ADMINFLAG );
	RegAdminCmd( "war_live_end",	Command_LiveEnd,	WAR_ADMINFLAG );
	RegAdminCmd( "war_reset",	Command_Reset,		WAR_ADMINFLAG );
	RegAdminCmd( "war_maxrounds",	Command_Maxrounds,	WAR_ADMINFLAG );
	RegAdminCmd( "war_nextmap",	Command_Nextmap,	WAR_ADMINFLAG );
	
	HookEvent( "round_start",	Event_RoundStart,	EventHookMode_PostNoCopy );
	HookEvent( "round_end",		Event_RoundEnd		);
	HookEvent( "player_team",	Event_PlayerTeam	);
	HookEvent( "player_spawn",	Event_PlayerSpawn	);
	HookEvent( "weapon_fire",	Event_WeaponFire,	EventHookMode_Post );
	HookEvent( "player_activate",	Event_PlayerActivate	);
	
	AutoExecConfig( true, "warriormod" );
	SetConVarString( cvar_version, WARRIORMOD_VERSION );
	
	LoadTranslations( "warriormod.phrases" );
	LoadTranslations( "common.phrases" );
	
	// See if the menu plugin is ready
	new Handle:topmenu;
	if( LibraryExists( "adminmenu" ) && ( ( topmenu = GetAdminTopMenu() ) != INVALID_HANDLE ) ){
		OnAdminMenuReady( topmenu );
		}
	
	dbase = Mysql_Connect();
	max_clients = GetMaxClients();
	
	offset_money = FindSendPropInfo("CCSPlayer", "m_iAccount");
	}

/******************************************************************************************
 *                                ADMINISTRATIVE COMMANDS                                 *
 ******************************************************************************************/

public Action:Command_Score( client, args ){
	ShowStatusPanelClient( client );
	return Plugin_Handled;
	}

public Action:Command_Warmup( client, args ){
	// start Warmup
	// no config except startmoney = 16k, one rr
	war_mode = MODE_WARMUP;
	mp_freezetime = GetConVarInt( FindConVar( "mp_freezetime" ) );
	
	new Handle:cvar_startmoney = FindConVar( "mp_startmoney" );
	mp_startmoney = GetConVarInt( cvar_startmoney );
	SetConVarInt( cvar_startmoney, 16000 );
	
	ServerCommand( "mp_restartgame 1" );
	
	rounds2play = GetConVarInt( cvar_maxrounds_wu );
	
	return Plugin_Handled;
	}

public Action:Command_Knife( client, args ){
	if( GetConVarBool( cvar_vote ) ){
		war_mode = MODE_NONE;
		if( !IsVoteInProgress() ){
			new Handle:menu = CreateMenu( Handle_VoteKnifeRound );
			new String:janein[30];
			
			SetMenuTitle( menu, "%T", "rdy for knives?", client );
			
			Format( janein, sizeof(janein), "%T", "Yes", client );
			AddMenuItem(menu, "0", janein );
			
			Format( janein, sizeof(janein), "%T", "No",  client );
			AddMenuItem(menu, "1", janein );
			
			SetMenuExitButton(menu, false);
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
	
	war_mode = MODE_KNIFE;
	
	restarts_remaining = 2;
	ServerCommand( "mp_restartgame 3" );
	ServerCommand( "sb_status" );
	ShowRestartsPanel();
	
	PrintToChatAll( "[WAR] %T", "knife starting", LANG_SERVER );
	return Plugin_Handled;
	}

public Action:Command_KnifeEnd( client, args ){
	PrintCenterTextAll( "%T", "knife after round", LANG_SERVER );
	war_action_on_round_end = MODE_KNIFE;
	}

public Action:Command_LiveEnd( client, args ){
	PrintCenterTextAll( "%T", "live after round", LANG_SERVER );
	war_action_on_round_end = MODE_LIVE;
	}

public Action:Command_Live( client, args ){
	if( GetConVarBool( cvar_vote ) ){
		war_mode = MODE_NONE;
		if( !IsVoteInProgress() ){
			new Handle:menu = CreateMenu( Handle_VoteLiveRound );
			new String:janein[30];
			
			SetMenuTitle( menu, "%T", "rdy for live?", client );
			
			Format( janein, sizeof(janein), "%T", "Yes", client );
			AddMenuItem(menu, "0", janein );
			
			Format( janein, sizeof(janein), "%T", "No",  client );
			AddMenuItem(menu, "1", janein );
			
			SetMenuExitButton(menu, false);
			VoteMenuToAll( menu, 30 );
			}
		return Plugin_Handled;
		}
	else return Command_Live_Real( client, args );
	}

public Action:Command_Live_Real( client, args ){
	if( !config_done && !WarInit( client ) ){
		return Plugin_Handled;
		}
	
	score_t  = score_t_half;
	score_ct = score_ct_half;
	
	war_mode = MODE_LIVE;
	
	restarts_remaining = 2;
	ServerCommand( "mp_restartgame 3" );
	ServerCommand( "sb_status" );
	ShowRestartsPanel();
	
	PrintToChatAll( "[WAR] %T", "live starting", LANG_SERVER );
	
	if( !war_teams_changed ){
		StoreClientTeams();
		}
	
	return Plugin_Handled;
	}

public Action:Command_Reset( client, args ){
	config_done
		= teamsizes_uneq_checked
		= false;
	
	war_mode = MODE_NONE;
	
	ServerCommand( "tv_stoprecord" );
	
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
	
	SetConVarInt( cvar_maxrounds, StringToInt( thecount ), false, war_mode == MODE_NONE );
	
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

public Action:Command_Buy( client, args ){
	if( war_mode == MODE_KNIFE ){
		// Only allow vest or vest+helm to be bought.
		decl String:bought[50];
		GetCmdArgString( bought, sizeof(bought) );
		if( ( strcmp( bought, "vest" ) != 0 ) && ( strcmp( bought, "vesthelm" ) != 0 ) ){
			PrintCenterText( client, "You can only buy a Vest in Knife Round!" );
			return Plugin_Handled;
			}
		}
	else if( war_mode == MODE_SUDDENDEATH ){
		PrintCenterText( client, "Buying is not allowed in Sudden Death!" );
		return Plugin_Handled;
		}
	return Plugin_Continue;
	}

public Action:Command_Say( client, args ){
	decl String:text[192];
	if( GetCmdArgString( text, sizeof(text) ) < 1 ){
		return Plugin_Continue;
		}
	if( war_mode == MODE_LIVE && 
	    ( ( strncmp( text, "mr", 2, false ) == 0   && strlen( text ) <= 3 ) ||
	      ( strncmp( text, "\"mr", 3, false ) == 0 && strlen( text ) <= 5 )
	    )
	  ){
		PrintToServer(  "Maxrounds is set to %d.", rounds2play );
		if( client != 0 ){
			PrintToChat( client, "Maxrounds is set to %d.", rounds2play );
			}
		return Plugin_Handled;
		}
	else if( war_mode == MODE_LIVE && client != 0 &&
		 ( strcmp( text, "score", false ) == 0 || strcmp( text, "\"score\"", false ) == 0 )
		){
		ShowStatusPanelClient( client );
		return Plugin_Handled;
		}
	PrintToServer( text );
	return Plugin_Continue;
	}

/******************************************************************************************
 *                                     EVENT HANDLERS                                     *
 ******************************************************************************************/

public OnClientPutInServer(){
	// Run sb_status when a new client connects during a war (for instance, after a discon)
	if( war_mode != MODE_NONE ){
		ServerCommand( "sb_status" );
		}
	}

public OnMapStart(){
	max_clients = GetMaxClients();
	theMapMenu = BuildMapMenu();
	}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast){
	// Are any restarts left to be done? Then do them
	if( restarts_remaining > 0 ){
		ServerCommand( "mp_restartgame %d", restarts_remaining );
		restarts_remaining--;
		ShowRestartsPanel();
		}
	else if( war_mode == MODE_LIVE ){
		PrintToServer( "[WAR] Round %d/%d - %s %d - %s %d",
			rounds_played, rounds2play,
			teamName1, score_t, teamName2, score_ct
			);
		// Show panel to spectators
		for( new i = 1; i <= max_clients; i++ ){
			if( IsClientInGame(i) ){
				if( clientTeam[i] != TEAMINDEX_SPEC ){
					ShowStatusPanelClient(i);
					}
				else if( GetClientTeam(i) == TEAMINDEX_SPEC ){
					PrintToChat( i, "[WAR] %s - Round %d/%d - %s %d - %s %d",
						( !war_teams_changed ? "First half" : "Second half" ),
						( !war_teams_changed ? rounds_played : rounds_played - rounds2play ) + 1, rounds2play,
						teamName1, score_t, teamName2, score_ct
						);
					}
				}
			}
		}
	}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast){
	new	winTeamId = GetEventInt( event, "winner" );
	
	if( war_mode == MODE_WARMUP ){
		if( rounds_played >= rounds2play ){
			// Start a vote: 1. Not ready 2. Knife round 3. Live
			// Vote until knife or live was selected
			if( !IsVoteInProgress() ){
				new Handle:menu = CreateMenu( Handle_VoteWarmupEnd );
				new String:optstr[30];
				
				
				SetMenuTitle( menu,             "%T", "what now?",       LANG_SERVER);
				
				Format( optstr, sizeof(optstr), "%T", "continue warmup", LANG_SERVER);
				AddMenuItem(  menu, "0", optstr );
				
				Format( optstr, sizeof(optstr), "%T", "start knife",     LANG_SERVER);
				AddMenuItem(  menu, "1", optstr );
				
				Format( optstr, sizeof(optstr), "%T", "start live",      LANG_SERVER);
				AddMenuItem(  menu, "2", optstr );
				
				SetMenuExitButton(menu, false);
				VoteMenuToAll( menu, 30 );
				}
			}
		}
	else if( war_mode == MODE_KNIFE ){
		if( restarts_remaining > 0 ){
				return;
				}
		PrintToServer( "Team %d voting for stay/leave.", winTeamId );
		DisplayStayLeaveVote( winTeamId );
		}
	else if( war_mode == MODE_LIVE ){
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
			}
		if( rounds_played == rounds2play ){
			// First half is over
			if( !war_teams_changed ){
				// war_teamchanges_remaining = players_t + players_ct;
				score_t_half  = score_t;
				score_ct_half = score_ct;
				war_teams_changed = true;
				
				for( new i = 1; i <= max_clients; i++ ){
					if( IsClientInGame(i) && clientTeam[i] >= TEAMINDEX_T ){
						// Switch
						CS_SwitchTeam( i, 5 - clientTeam[i] );
						PrintHintText( i, "%T", "switched to team", i, ( clientTeam[i] == TEAMINDEX_T ? "CT" : "T" ) );
						}
					}
				Command_Live( 0, 0 );
				}
			}
		else if( GetConVarBool( cvar_finish ) ? rounds_played == rounds2play * 2 : max( score_t, score_ct ) > rounds2play ){
			// War is over -- do we need SuddenDeath?
			if( GetConVarBool( cvar_suddendeath ) && score_t == score_ct ){
				war_mode = MODE_SUDDENDEATH;
				// Store FF value, turn FF off
				mp_friendlyfire = GetConVarBool( cvar_friendlyfire );
				SetConVarBool( cvar_friendlyfire, false );
				ServerCommand( "mp_restartgame 3" );
				restarts_remaining = 2;
				ShowRestartsPanel();
				}
			else{
				DoWarEndProcessing();
				}
			}
		}
	else if( war_mode == MODE_SUDDENDEATH ){
		// SuddenDeath is active, this is only one single round after the war has been a draw, so the war must be over.
		SetConVarBool( cvar_friendlyfire, mp_friendlyfire );
		DoWarEndProcessing( winTeamId );
		}
	else if( war_action_on_round_end == MODE_KNIFE ){
		// Nuffn running but day wanna haz chzbrgr
		Command_Knife_Real( 0, 0 );
		war_action_on_round_end = MODE_NONE;
		}
	else if( war_action_on_round_end == MODE_LIVE ){
		Command_Live_Real( 0, 0 );
		war_action_on_round_end = MODE_NONE;
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

public Event_PlayerActivate(Handle:event, const String:name[], bool:dontBroadcast){
	if( war_mode == MODE_KNIFE || war_mode == MODE_LIVE ){
		// User may only join Specs
		ClientCommand( GetClientOfUserId(GetEventInt(event,"userid")), "jointeam %d", TEAMINDEX_SPEC );
		}
	}

public Event_WeaponFire(Handle:event, const String:name[], bool:dontBroadcast){
	// This event is only hooked during Knife round
	// If someone fires something other than the knife, the opposite team wins.
	if( war_mode != MODE_KNIFE || restarts_remaining > 0 ){
		return;
		}
	
	new String:weap[10];
	GetEventString( event, "weapon", weap, sizeof(weap) );
	
	if( !StrEqual( "knife", weap ) ){
		new theClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
		ForcePlayerSuicide( theClient );
		DisplayStayLeaveVote( 5 - GetClientTeam( theClient ) );
		}
	}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast){
	if( war_mode == MODE_NONE || restarts_remaining > 0 || IsVoteInProgress() ){
		return;
		}
	
	new theClient = GetClientOfUserId( GetEventInt( event, "userid" ) );
	
	if( war_mode == MODE_SUDDENDEATH || war_mode == MODE_KNIFE ){
		Timer_StripWeaponsButKnife( theClient );
		}
	ShowStatusPanelClient( theClient );
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
		war_mode = MODE_NONE;
		if( param1 == 0 ){
			// Stay
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
			PrintToServer( "[WM] Setting startmoney to %d.", mp_startmoney );
			SetConVarInt( FindConVar( "mp_startmoney" ), mp_startmoney );
			switch( param1 ){
				case 1:
					// Kniferound
					Command_Knife_Real( 0, 0 );
				case 2:
					// Live
					Command_Live_Real( 0, 0 );
				// Called Real functions here, because if players
				// ain't ready they won't vote "start".
				}
			}
		}
	}

public Handle_Panel( Handle:menu, MenuAction:action, client, selIdx ){
	// Fire slot1-5 if the according keys have been pressed
	if( action == MenuAction_Select && selIdx < 10 ){
		ClientCommand( client, "slot%d", selIdx );
		}
	else if( action == MenuAction_End ){
		CloseHandle(menu);
		}
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
 *                                      STATUS PANEL                                      *
 ******************************************************************************************/

void:ShowStatusPanelClient( theClient ){
	if( war_mode == MODE_WARMUP ){
		new Handle:panel = CreatePanel();
		new String:roundnr[20];
		SetPanelTitle( panel, "WARMUP" );
		Format( roundnr, sizeof(roundnr), "%T", "round x of y", theClient, rounds_played, rounds2play );
		DrawPanelText( panel, roundnr );
		// Panel only reacts to key 0
		SetPanelKeys( panel, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<9) );
		SendPanelToClient( panel, theClient, Handle_Panel, mp_freezetime );
		CloseHandle( panel );
		}
	else if( war_mode == MODE_KNIFE ){
		new Handle:panel = CreatePanel();
		SetPanelTitle( panel, "KNIFE" );
		DrawPanelItem( panel, "", ITEMDRAW_SPACER );
		DrawPanelText( panel, "Drop or lose" );
		// Panel only reacts to key 0
		SetPanelKeys( panel, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<9) );
		SendPanelToClient( panel, theClient, Handle_Panel, mp_freezetime );
		CloseHandle( panel );
		}
	else if( war_mode == MODE_LIVE ){
		new Handle:panel = CreatePanel(),
		    myTeam = GetClientTeam(theClient);
		
		SetPanelTitle( panel, "LIVE" );
		DrawPanelItem( panel, "", ITEMDRAW_SPACER );
		
		// Create a nice panel showing what's up:
		// * Round x of y
		// * Second half
		// *
		// * First half:
		// * Team1     7
		// * Team2     5
		// *
		// * Second half:
		// * Team1    13
		// * Team2    11
		// *
		// * You're in Team2.
		// *
		// * Player   $cash
		
		new String:roundnr[20];
		
		new thisround = rounds_played + 1;
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
		
		if( !war_teams_changed )
			Format( roundnr, sizeof(roundnr), "%T", "first half",  theClient );
		else
			Format( roundnr, sizeof(roundnr), "%T", "second half", theClient );
		DrawPanelText( panel, roundnr );
		
		DrawPanelItem( panel, "", ITEMDRAW_SPACER );
		
		if( war_teams_changed ){
			Format( roundnr, sizeof(roundnr), "%T:", "first half",  theClient );
			DrawPanelText( panel, roundnr );
			
			Format( roundnr, sizeof(roundnr), "%T", "team x score y",   theClient, teamName1, score_t_half  );
			DrawPanelText( panel, roundnr );
			
			Format( roundnr, sizeof(roundnr), "%T", "team x score y",   theClient, teamName2, score_ct_half );
			DrawPanelText( panel, roundnr );
			
			DrawPanelItem( panel, "", ITEMDRAW_SPACER );
			
			Format( roundnr, sizeof(roundnr), "%T:", "second half",  theClient );
			DrawPanelText( panel, roundnr );
			}
		
		Format( roundnr, sizeof(roundnr), "%T", "team x score y",   theClient, teamName1, score_t  );
		DrawPanelText( panel, roundnr );
	 
		Format( roundnr, sizeof(roundnr), "%T", "team x score y",   theClient, teamName2, score_ct );
		DrawPanelText( panel, roundnr );
			
		DrawPanelItem( panel, "", ITEMDRAW_SPACER );
		
		Format( roundnr, sizeof(roundnr), "%T", "youre in team x", theClient,
			( ( war_teams_changed
			    ? 5-myTeam
			    : myTeam
			  ) == TEAMINDEX_T
			  ? teamName1
			  : teamName2
			  )
			);
		DrawPanelText( panel, roundnr );
		
		DrawPanelItem( panel, "", ITEMDRAW_SPACER );
		
		if( GetConVarBool( cvar_money ) && ( myTeam == TEAMINDEX_T ? players_t : players_ct ) > 1 ){
			Format( roundnr, sizeof(roundnr), "%T:", "mates cash", theClient );
			DrawPanelText( panel, roundnr );
			
			for( new i = 1; i < max_clients; i++ ){
				if( i != theClient && IsClientInGame(i) && GetClientTeam(i) == myTeam ){
					decl String:plName[10], String:cash[20];
					GetClientName( i, plName, sizeof(plName) );
					
					Format( cash, sizeof(cash), "%s  $%d", plName, GetClientMoney(i) );
					DrawPanelText( panel, cash );
					}
				}
			}
		
		// Panel only reacts to key 0
		SetPanelKeys( panel, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<9) );
		
		SendPanelToClient( panel, theClient, Handle_Panel, mp_freezetime );
	 
		CloseHandle( panel );
		}
	else if( war_mode == MODE_SUDDENDEATH ){
		new Handle:panel = CreatePanel();
		SetPanelTitle( panel, "SUDDEN DEATH" );
		DrawPanelItem( panel, "", ITEMDRAW_SPACER );
		DrawPanelText( panel, "Go shoot 'em up!" );
		// Panel only reacts to key 0
		SetPanelKeys( panel, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<9) );
		SendPanelToClient( panel, theClient, Handle_Panel, mp_freezetime );
		CloseHandle( panel );
		}
	}


void:ShowRestartsPanel(){
	for( new theClient = 1; theClient <= max_clients; theClient++ ){
		if( !IsClientInGame(theClient) ){
			continue;
			}
		
		if( GetClientTeam( theClient ) != TEAMINDEX_SPEC ){
			new Handle:panel = CreatePanel();
			SetPanelTitle( panel, "Restarting" );
			DrawPanelItem( panel, "", ITEMDRAW_SPACER );
			SetPanelKeys( panel, (1<<0)|(1<<1)|(1<<2)|(1<<3)|(1<<4)|(1<<9) );
			
			DrawPanelText( panel, "Get ready for" );
			switch( war_mode ){
				case MODE_KNIFE:
					DrawPanelText( panel, "Knife Round!" );
				case MODE_LIVE:
					DrawPanelText( panel, "Live!" );
				case MODE_SUDDENDEATH:
					DrawPanelText( panel, "Sudden Death!" );
				}
			
			DrawPanelItem( panel, "", ITEMDRAW_SPACER );
			DrawPanelItem( panel, "", ITEMDRAW_SPACER );
			
			new String:roundnr[20];
			
			for( new i = 1; i <= 3; i++ ){
				// Restart that has been done already:   [x]
				// Restart that is being done right now: [>]
				// Restart that is yet to be done:       [_]
				new String:char[1];
				
				// ,-- restarts_remaining
				// v | 1   2   3  <- i
				// 2: [>] [_] [_]
				// 1: [x] [>] [_]
				// 0: [x] [x] [>]
				
				if( restarts_remaining + i == 3 )
					// "current" restart
					char[0] = '>';
				else if( restarts_remaining + i > 3 )
					// Upcoming restart
					char[0] = '_';
				else if( restarts_remaining + i < 3 )
					// Past restart
					char[0] = 'x';
				
				Format( roundnr, sizeof(roundnr), "[%s] Restart %d", char, i );
				DrawPanelText( panel, roundnr );
				}
			
			DrawPanelItem( panel, "", ITEMDRAW_SPACER );
			DrawPanelText( panel, "Good luck" );
			DrawPanelText( panel, "Have fun" );
			
			SendPanelToClient( panel, theClient, Handle_Panel, 5 );
			
			CloseHandle( panel );
			}
		else{
			// Spec - SrcTV gets a nice clean unsuspect'n text message
			new String:char[15];
			
			for( new i = 1; i <= 3; i++ ){
				if( restarts_remaining + i == 3 )
					Format( char, sizeof(char), "%s[>] ", char );
				else if( restarts_remaining + i > 3 )
					Format( char, sizeof(char), "%s[_] ", char );
				else if( restarts_remaining + i < 3 )
					Format( char, sizeof(char), "%s[x] ", char );
				}
			
			PrintToChat( theClient, "Restarting: %s", char );
			}
		}
	}


DoWarEndProcessing( winTeamId = -1 ){
	PrintToServer( "[WAR] WAR FINISHED -- SCORE: %s %d - %s %d",
		teamName1, score_t, teamName2, score_ct
		);
	
	
	for( new theClient = 1; theClient <= max_clients; theClient++ ){
		if( IsClientInGame(theClient) ){
			new myTeam = GetClientTeam(theClient);
			if( myTeam != TEAMINDEX_SPEC ){
				new Handle:panel = CreatePanel();
				SetPanelTitle( panel, "WAR FINISHED" );
				DrawPanelItem( panel, "", ITEMDRAW_SPACER );
				SetPanelKeys( panel, (1<<9) );
				
				new String:roundnr[20];
				
				Format( roundnr, sizeof(roundnr), "%T:", "first half", theClient );
				DrawPanelText( panel, roundnr );
				
				Format( roundnr, sizeof(roundnr), "%T", "team x score y", theClient, teamName1, score_t_half );
				DrawPanelText( panel, roundnr );
			
				Format( roundnr, sizeof(roundnr), "%T", "team x score y", theClient, teamName2, score_ct_half );
				DrawPanelText( panel, roundnr );
				
				DrawPanelItem( panel, "", ITEMDRAW_SPACER );
			
				Format( roundnr, sizeof(roundnr), "%T:", "second half", theClient );
				DrawPanelText( panel, roundnr );
				
				Format( roundnr, sizeof(roundnr), "%T", "team x score y", theClient, teamName1, score_t );
				DrawPanelText( panel, roundnr );
			
				Format( roundnr, sizeof(roundnr), "%T", "team x score y", theClient, teamName2, score_ct );
				DrawPanelText( panel, roundnr );
				
				if( war_mode == MODE_SUDDENDEATH ){
					// TODO: Sudden Death Results go here
					DrawPanelItem( panel, "", ITEMDRAW_SPACER );
				
					DrawPanelText( panel, "SuddenDeath winner:" );
					
					// Team1 starts as T and is now CT, so if Ts win, that is Team2
					if( winTeamId == TEAMINDEX_T )
						DrawPanelText( panel, teamName2 );
					else
						DrawPanelText( panel, teamName1 );
					}
				
				DrawPanelItem( panel, "", ITEMDRAW_SPACER );
				
				Format( roundnr, sizeof(roundnr), "%T", "youre in team x", theClient,
					( ( war_teams_changed ? 5-myTeam : myTeam ) == TEAMINDEX_T
					? teamName1
					: teamName2
					)
					);
				DrawPanelText( panel, roundnr );
				
				SendPanelToClient( panel, theClient, Handle_Panel, 30 );
				
				CloseHandle( panel );
				}
			else{
				// Send a string to chat, as specs are most likely SRCTVs and these won't display panels
				PrintToChat( theClient, "[WAR] War finished - %s %d - %s %d",
					teamName1, score_t, teamName2, score_ct
					);
				}
			}
		}
	
	Mysql_InsertResult();
	
	CreateTimer( 2.0, Timer_ResetPlugin );
	
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


/******************************************************************************************
 *                                   HELPER FUNCTIONS                                     *
 ******************************************************************************************/

public Action:Timer_ResetPlugin( Handle:timer ){
	Command_Reset( 0, 0 );
	return Plugin_Stop;
	}

public Action:Timer_ChangeMap(Handle:timer, Handle:dp){
	// Shamelessly ripped from basecommands/map.sp.
	decl String:map[65];
	
	ResetPack(dp);
	ReadPackString(dp, map, sizeof(map));
	
	ServerCommand("changelevel \"%s\"", map);
	
	return Plugin_Stop;
	}

max( a, b ){
	return ( a > b ? a : b );
	}

GetClientMoney( client ){
	return GetEntData( client, offset_money, 4 );
	}

bool:WarInit( client = 0 ){
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
		PrintToServer( "[WAR] Number of players in teams is not equal." );
		PrintToServer( "      Repeat command to start anyway." );
		if( client != 0 ){
				PrintToChat( client, "[WAR] %T", "number not equal", client );
				PrintToChat( client, "      %T", "repeat command",  client );
				}
		teamsizes_uneq_checked = true;
		return false;
		}
	
	war_mode = MODE_NONE;
	war_teams_changed = false;
	score_t_half = score_ct_half = score_t = score_ct = 0;
	
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
	
	findTeamNames();
	
	if( GetConVarBool( cvar_record ) ){
		// TODO: Name
		new String:datetime[20],
		    String:mapname[20];
		
		GetCurrentMap( mapname, sizeof(mapname) );
		FormatTime( datetime, sizeof(datetime), "%Y-%m-%d_%H-%M" );
		ServerCommand( "tv_record \"clanwar_%s-vs-%s_%s_%s\"", teamName1, teamName2, mapname, datetime );
		}
	
	ServerCommand( "sb_status" );
	
	config_done = true;
	return true;
	}

DisplayStayLeaveVote( winTeamId ){
	// Maybe these guys are _still_ voting? Then don't send a new vote.
	if( !IsVoteInProgress() ){
		new Handle:menu = CreateMenu( Handle_VoteStayLeave );
		SetMenuTitle( menu, "Teams?"    );
		AddMenuItem(  menu, "0", "Stay" );
		AddMenuItem(  menu, "1", "Leave");
		SetMenuExitButton( menu, false );
		
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


Timer_StripWeaponsButKnife( client ){
	CreateTimer( 0.5, TimerHandler_Strip, client );
	}

public Action:TimerHandler_Strip( Handle:timer, any:client ){
	StripWeaponsButKnife( client );
	}

StripWeaponsButKnife( client ){
	new wepIdx;
	// Iterate through weapon slots
	for( new i = 0; i <= 5; i++ ){
		if( i == 2 ) continue; // You can leeeeave your knife on...
		// Strip all weapons from current slot
		while( ( wepIdx = GetPlayerWeaponSlot( client, i ) ) != -1 ){
			RemovePlayerItem( client, wepIdx );
			}
		}
	
	if( war_mode == MODE_SUDDENDEATH ){
		GivePlayerItem( client, "weapon_m249" );
		SetPlayerHealth( client, 1 );
		}
	else
		// Now switch to knife
		ClientCommand( client, "lastinv" );
	}

SetPlayerHealth(entity, amount){
	// Shamelessly stolen from knifesyphon.sp by ferret
	new HealthOffset = FindDataMapOffs(entity, "m_iHealth");
	SetEntData(entity, HealthOffset, amount, 4, true);
	}


Handle:BuildMapMenu(){
	// Shamelessly ripped from http://wiki.alliedmods.net/Menu_API_%28SourceMod%29#Basic_Paginated_Menu
	/* Open the file */
	new Handle:file = OpenFile( "maplist.txt", "rt" );
	if( file == INVALID_HANDLE ){
		return INVALID_HANDLE;
		}
 
	/* Create the menu Handle */
	new Handle:menu = CreateMenu( Menu_ChangeMap );
	new String:mapname[255];
	while( !IsEndOfFile(file) && ReadFileLine( file, mapname, sizeof(mapname) ) ){
		if (mapname[0] == ';' || !IsCharAlpha(mapname[0])){
			continue;
			}
		/* Cut off the name at any whitespace */
		new len = strlen( mapname );
		for (new i=0; i<len; i++){
			if (IsCharSpace(mapname[i])){
				mapname[i] = '\0';
				break;
				}
			}
		/* Check if the map is valid */
		if (!IsMapValid(mapname)){
			continue;
			}
		/* Add it to the menu */
		AddMenuItem(menu, mapname, mapname);
		}
	/* Make sure we close the file! */
	CloseHandle(file);
 
	/* Finally, set the title */
	SetMenuTitle( menu, "%T", "select map", LANG_SERVER );
 
	return menu;
	}

void:BanTeam( theTeamIndex ){
	for( new i = 1; i <= max_clients; i++ ){
		if( IsClientInGame(i) && GetClientTeam(i) == theTeamIndex ){
			BanClient( i, 60, BANFLAG_AUTO, "Banned by Admin." );
			}
		}
	}

// Helpers for auto team name detection
void:strFindLongestMatch( String:target[], targetLen, String:s1[], String:s2[] ){
	new s1len   = strlen(s1),
	    s2len   = strlen(s2),
	    resIpos = 0,
	    s1pos   = 0,
	    s2pos   = 0,
	    String:resFinal[40],
	    String:resInter[40];
	
	// Compare s1 to s2.
	for( s1pos = 0; s1pos < s1len; s1pos++ ){
		// Make sure we don't read behind the end of s2
		if( s2pos >= s2len )
			s2pos = 0;
		
		// If chars are equal, copy
		if( s1[s1pos] == s2[s2pos] )
			resInter[resIpos++] = s2[s2pos++];
		// Match ends. If we found something which is longer than what we currently have:
		else{
			if( resIpos > strlen( resFinal ) ){
				// copy this match to final result and delete intermediate result
				strcopy( resFinal, sizeof(resFinal), resInter );
				}
			strcopy( resInter, sizeof(resInter), "" );
			resIpos = 0;
			}
		}
	strcopy( target, targetLen, resFinal );
	}

void:findTeamNames(){
	strcopy( teamName1, sizeof(teamName1), "" );
	strcopy( teamName2, sizeof(teamName2), "" );
	
	new firstNameCopied1 = false,
	    firstNameCopied2 = false,
	    String:plName[40];
	
	for( new i = 1; i <= max_clients; i++ ){
		if( IsClientInGame(i) ){
			if( !GetClientName( i, plName, sizeof(plName) ) )
				continue;
			
			switch( GetClientTeam(i) ){
				case TEAMINDEX_T:
					if( !firstNameCopied1 ){
						strcopy( teamName1, sizeof(teamName1), plName );
						firstNameCopied1 = true;
						}
					else{
						strFindLongestMatch( teamName1, sizeof(teamName1),
							teamName1, plName
							);
						}
				case TEAMINDEX_CT:
					if( !firstNameCopied2 ){
						strcopy( teamName2, sizeof(teamName2), plName );
						firstNameCopied2 = true;
						}
					else{
						strFindLongestMatch( teamName2, sizeof(teamName2),
							teamName2, plName
							);
						}
				}
			}
		}
	
	// Cutoff team names at the first space, max length: 10 chars (panel too small for more)
	new String:tnSplit1[10], String:tnSplit2[10];
	SplitString( teamName1, " ", tnSplit1, sizeof(tnSplit1) );
	strcopy( teamName1, sizeof(teamName1), tnSplit1 );
	
	SplitString( teamName2, " ", tnSplit2, sizeof(tnSplit2) );
	strcopy( teamName2, sizeof(teamName2), tnSplit2 );
	
	// Check for min length
	if( strlen( teamName1 ) <3 ){
		strcopy( teamName1, sizeof(teamName1), "Team1" );
		}
	if( strlen( teamName2 ) <3 ){
		strcopy( teamName2, sizeof(teamName2), "Team2" );
		}
	}

/******************************************************************************************
 *                          DATABASE HELPER FUNCTIONS                                     *
 ******************************************************************************************/

Handle:Mysql_Connect(){
	// Shamelessly stolen from sql-admin-manager.sp
	new String:error[255],
	    Handle:db = INVALID_HANDLE;
	
	if( SQL_CheckConfig("warriormod") ){
		db = SQL_Connect( "warriormod", true, error, sizeof(error) );
		}
	else if( SQL_CheckConfig("default") ){
		db = SQL_Connect( "default", true, error, sizeof(error) );
		}
	
	if( db == INVALID_HANDLE ){
		LogError( "[WAR] Could not connect to database: %s", error );
		}
	else{
		// Make sure table exists
		SQL_FastQuery( db,
			"CREATE TABLE IF NOT EXISTS wars ( date_time int NOT NULL PRIMARY KEY, name_team1 varchar(50) NOT NULL, name_team2 varchar(50) NOT NULL, score_t1 int NOT NULL, score_t2 int NOT NULL, map varchar(20) NOT NULL, teamsize int NOT NULL );"
			);
		}
	
	return db;
	}

Mysql_InsertResult(){
	if( dbase == INVALID_HANDLE ){
		LogError( "[WAR] Mysql: database handle invalid, cannot insert." );
		return;
		}
	
	decl String:error[255];
	
	// Prepare insert statement
	new Handle:dbase_insert = SQL_PrepareQuery( dbase,
		"INSERT INTO wars VALUES( UNIX_TIMESTAMP(CURRENT_TIMESTAMP), ?, ?, ?, ?, ?, ? )",
		error, sizeof(error)
		);
	
	if( dbase_insert == INVALID_HANDLE ){
		LogError( "[WAR] Could not prepare insert statement: %s", error );
		return;
		}
	
	// Gather intel
	new String:map[20],
	    pidx   = 0,
	    plconf = RoundToFloor( ( players_t + players_ct ) / 2.0 );
	
	GetCurrentMap( map, sizeof(map) );
	
	// Bind parameters to statement
	SQL_BindParamString( dbase_insert, pidx++, teamName1, false );
	SQL_BindParamString( dbase_insert, pidx++, teamName2, false );
	SQL_BindParamInt(    dbase_insert, pidx++, score_t,   false );
	SQL_BindParamInt(    dbase_insert, pidx++, score_ct,  false );
	SQL_BindParamString( dbase_insert, pidx++, map,       false );
	SQL_BindParamInt(    dbase_insert, pidx++, plconf,    false );
	
	if( !SQL_Execute( dbase_insert ) ){
		SQL_GetError( dbase_insert, error, sizeof(error) );
		LogError( "[WAR] The insert statement failed: %s", error );
		}
	
	CloseHandle( dbase_insert );
	}
