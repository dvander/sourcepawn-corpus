/*
KillStats.sp

Description:
	Shows damage and kills done this round to and by player upon death

Versions:
1.1.1: Fixed a bug where health remaining would not be shown for disconnected players
1.1: Added weapons
		Added body parts
		Added support for multiple panels (512 byte max per page)
		Split translations into multiple files
		Updated Translations
		Removed translation of version description - seems to be causing issues with plugin count
		Added sm_killstats_combine_damage
		Added sm_killstats_show_death_mark
		Added sm_killstats_show_distance
		Added sm_killstats_show_body_hits
		Added sm_killstats_show_weapon_used
		Added sm_killstats_show_empty_menus
		Added sm_killstats_max_panel_width
		Added sm_killstats_restart_numbering
1.03: Added sm_unit_of_measure (1=feet,2=meters)
		Fixed startup help to strip off sm_
		Changed sort to show kills first then deaths in damage taken/done sections
		Fixed distance multiplier
1.02: Added attacker health left to damage taken string upon death
		Added player name to chat strings
		Changed menu_damage_string and menu_death_string to 4 strings, same as chat has to allow for different configurations
		Handle late loading
		Change console commands to "sm_"
		sm_killstats_new_player_options
		sm_killstats_show_startup_help
1.01 Remove debug messages		
1.0: Save Preferences with SQLLite
		Added sm_killstats_menu_display_order
		Added sm_killstats_chat_display_order
		Added sm_killstats_show_killed(menu/chat)
		Added sm_killstats_show_killed_by(menu/chat)
		Added sm_killstats_show_damage_done(menu/chat)
		Added sm_killstats_show_damage_taken(menu/chat)
		Added sm_killstats_show_on_teamkill
		Added sm_killstats_default_show_in_menu
		Added sm_killstats_default_show_in_chat
		Added sm_killstats_menu_show_killed
		Added sm_killstats_menu_show_killed_by
		Added sm_killstats_menu_show_damage_done
		Added sm_killstats_menu_show_damage_taken
		Added sm_killstats_chat_show_killed
		Added sm_killstats_chat_show_killed_by
		Added sm_killstats_chat_show_damage_done
		Added sm_killstats_chat_show_damage_taken
		Added distance (approximation in feet)
		Added ability to display different messages in damage taken/damage received sections based on death (so you can put a * in front or completely reword)
		Reworked cvars to retrieve on demand
		Added enabled on death and enabled on round end player preferences
		Added display to chat/menu player preferences
		Added display to chat
		Store client names at the beginning of the round to prevent disconnects not showing damage (or errors)
		More format options
0.9.2: MAX_CLIENTS->MAXPLAYERS
		Added German Translation
		Modified the way enabled by default worked
		Moved cvars to OnConfigsExecuted so they would be checked after configs loaded
0.9.1: Added translations
		Added sm_killstats_enabled_by_default
0.9: Initial Release
0.8: Fixed console error message
		Added cvars
0.7: Sorted damage taken given from most to least
0.6: Added spacing
0.5: Initially placed on our server

Author:
	Deception5 - thanks to Dalto/AMP
*/


#include <sourcemod>
#include <sdktools>

#pragma dynamic 65536
#pragma semicolon 1

#define PLUGIN_VERSION "1.1"

// Current client side limitation
#define MAX_PANEL_CHARACTERS 512

#define MAX_LINE_WIDTH 128
#define MIN_LINE_WIDTH 30
#define MAX_KILLSTATS_PANELS 5
#define MAX_DISPLAY_ITEMS 4

// How many rounds of messages should be stored 
#define ROUNDS_TO_STORE 2

// Maximum number of rows that can be stored for kills, damage done, damage taken
#define MAX_DISPLAY_LINES 20

// Don't display killstats when a round ends for this reason
#define REASON_PRACTICE_ROUND_END 16

// How many units should be considered equal to one foot
#define UNITS_PER_FOOT 12
#define UNITS_PER_METER 39.37

// Offset to convert between int and char
#define ASCII_ZERO					48

#define DISPLAY_REASON_ROUND_END	1
#define DISPLAY_REASON_DEATH		2
#define DISPLAY_REASON_VIEW			3

#define DISPLAY_TYPE_MENU			1
#define DISPLAY_TYPE_CHAT			2

#define DAMAGE_TYPE_DEATH			1
#define DAMAGE_TYPE_DAMAGE			2

#define NEWLINE " "

#define PREF_DISABLED				0
#define PREF_ENABLED				1
#define PREF_ENABLED_ON_DEATH		2
#define PREF_ENABLED_ON_ROUND_END	3
#define PREF_UNSPECIFIED			4

#define STAT_PREF_SIZE				3
#define STAT_PREF_ENABLED			0
#define STAT_PREF_SHOW_MENU			1
#define STAT_PREF_SHOW_CHAT			2

#define PANEL_HEADER			 	0
#define PANEL_HEADER_IS_CONTINUED	1

// console commands
#define CONSOLE_KILLSTATS "sm_killstats"
#define CONSOLE_KILLSTATS_SAY "killstats"
#define CONSOLE_DAMAGE "sm_damage"
#define CONSOLE_DAMAGE_SAY "damage"
#define CONSOLE_KILLSTATS_OPTIONS "sm_killstatsoptions"
#define CONSOLE_KILLSTATS_OPTIONS_SAY "killstatsoptions"

// Body Parts
#define MAX_BODY_PARTS	7

#define HEAD		1
#define CHEST		2
#define STOMACH		3
#define LEFT_ARM	4
#define RIGHT_ARM	5
#define LEFT_LEG	6
#define RIGHT_LEG	7

#define HEAD_STRING	"head"
#define CHEST_STRING "chest"
#define STOMACH_STRING "stomach"
#define LEFT_ARM_STRING "left_arm"
#define RIGHT_ARM_STRING "right_arm"
#define LEFT_LEG_STRING "left_leg"
#define RIGHT_LEG_STRING "right_leg"

#define SHOW_ALL_BODY_DAMAGE 1

/*****************************************************
					Translations
*****************************************************/

// cvars
#define CVAR_ENABLED "sm_killstats_enable"
#define CVAR_ENABLED_BY_DEFAULT "sm_killstats_enabled_by_default"
#define CVAR_UNIT_OF_MEASURE "sm_killstats_unit_of_measure"
#define CVAR_NEW_PLAYER_OPTIONS "sm_killstats_new_player_options"
#define CVAR_SHOW_STARTUP_HELP "sm_killstats_show_startup_help"
#define CVAR_SHOW_ON_TEAMKILL "sm_killstats_show_on_teamkill"
#define CVAR_DEFAULT_SHOW_IN_CHAT "sm_killstats_default_show_in_chat"
#define CVAR_DEFAULT_SHOW_IN_MENU "sm_killstats_default_show_in_menu"
#define CVAR_CHAT_DISPLAY_ORDER "sm_killstats_chat_display_order"
#define CVAR_MENU_DISPLAY_ORDER "sm_killstats_menu_display_order"

// More cvars - What information to show and where
#define CVAR_DEFAULT_MENU_SHOW_KILLED "sm_killstats_menu_show_killed"
#define CVAR_DEFAULT_MENU_SHOW_KILLED_BY "sm_killstats_menu_show_killed_by"
#define CVAR_DEFAULT_MENU_SHOW_DAMAGE_DONE "sm_killstats_menu_show_damage_done"
#define CVAR_DEFAULT_MENU_SHOW_DAMAGE_TAKEN "sm_killstats_menu_show_damage_taken"

#define CVAR_DEFAULT_CHAT_SHOW_KILLED "sm_killstats_chat_show_killed"
#define CVAR_DEFAULT_CHAT_SHOW_KILLED_BY "sm_killstats_chat_show_killed_by"
#define CVAR_DEFAULT_CHAT_SHOW_DAMAGE_DONE "sm_killstats_chat_show_damage_done"
#define CVAR_DEFAULT_CHAT_SHOW_DAMAGE_TAKEN "sm_killstats_chat_show_damage_taken"

// Damage string manipulations
#define CVAR_COMBINE_DAMAGE "sm_killstats_combine_damage"
#define CVAR_SHOW_DEATH_MARK "sm_killstats_show_death_mark"
#define CVAR_SHOW_DISTANCE "sm_killstats_show_distance"
#define CVAR_SHOW_BODY_HITS "sm_killstats_show_body_hits"
#define CVAR_SHOW_WEAPON_USED "sm_killstats_show_weapon_used"

// whether to show menus with "None" or just skip them
#define CVAR_SHOW_EMPTY_MENUS "sm_killstats_show_empty_menus"
#define CVAR_MAX_PANEL_WIDTH "sm_killstats_max_panel_width"
#define CVAR_RESTART_NUMBERING "sm_killstats_restart_numbering"

// Times for menu display
#define CVAR_DEATH_TIME "sm_killstats_death_time"
#define CVAR_VIEW_TIME "sm_killstats_view_time"
#define CVAR_ROUND_END_TIME "sm_killstats_round_end_time"

// console instructions
#define KILLSTATS_DISPLAY "killstats_display"
#define KILLSTATS_OPTIONS_DISPLAY "killstats_options_display"

// killstats screen
#define KILLSTATS "killstats"
#define PLAYERS_KILLED "players_killed"
#define KILLED_BY "killed_by"
#define DAMAGE_DONE "damage_done"
#define DAMAGE_TAKEN "damage_taken"
#define NEXT "next"
#define PREVIOUS "previous"
#define EXIT "exit"
#define NONE "none"
#define MORE "more"
#define MENU_CONTINUED "menu_continued"

// killstats options screen
#define KILLSTATS_OPTIONS "killstats_options"
#define ENABLE "enable"
#define ENABLE_ON_DEATH "enable_on_death"
#define ENABLE_ON_ROUND_END "enable_on_round_end"
#define DISABLE "disable"
#define VIEW "view"

#define SHOW_RESULTS_IN_MENU "show_results_in_menu"
#define SHOW_RESULTS_IN_CHAT "show_results_in_chat"

#define FEET "feet"
#define METERS "meters"

// DAMAGE STRINGS

// MENU 
#define MENU_DAMAGE_DONE_DEATH_STRING "menu_damage_done_death_string"
#define MENU_DAMAGE_TAKEN_DEATH_STRING "menu_damage_taken_death_string"
#define MENU_DAMAGE_DONE_STRING "menu_damage_done_string"
#define MENU_DAMAGE_TAKEN_STRING "menu_damage_taken_string"

#define MENU_BODY_PART_FULL_STRING "menu_body_part_full_string"
#define MENU_BODY_COMBINED_PARTS "menu_body_combined_parts"
#define MENU_BODY_INDIVIDUAL_PART "menu_body_individual_part"
#define MENU_DISTANCE_STRING "menu_distance_string"
#define MENU_WEAPON_STRING "menu_weapon_string"

// CHAT
#define CHAT_DAMAGE_DONE_DEATH_STRING "chat_damage_done_death_string"
#define CHAT_DAMAGE_TAKEN_DEATH_STRING "chat_damage_taken_death_string"
#define CHAT_DAMAGE_DONE_STRING "chat_damage_done_string"
#define CHAT_DAMAGE_TAKEN_STRING "chat_damage_taken_string"
#define CHAT_DISTANCE_STRING "chat_distance_string"
#define CHAT_WEAPON_STRING "chat_weapon_string"

#define CHAT_BODY_PART_FULL_STRING "chat_body_part_full_string"
#define CHAT_BODY_COMBINED_PARTS "chat_body_combined_parts"
#define CHAT_BODY_INDIVIDUAL_PART "chat_body_individual_part"

#define HEADSHOT "headshot"
#define HEADSHOTS "headshots"

/*****************************************************
					End Translations
*****************************************************/


/****************************************************

				Globals

*****************************************************/
// Plugin definitions
public Plugin:myinfo = 
{
	name = "KillStats",
	author = "Deception5",
	description = "Kill Stats",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

// 0 - Whether the client would like to display kill stats or not
// 1 - Whether the client would like to show menus
// 2 - Whether the client would like to show chat
new StatPreference[STAT_PREF_SIZE][MAXPLAYERS+1];

// Stores the amount of damage done by each player to each player
new Damage[MAXPLAYERS+1][MAXPLAYERS+1];
// Stores number of times each player has been hit by each player
new Hits[MAXPLAYERS+1][MAXPLAYERS+1];
// Store player x health left when player x killed player y
new HealthLeft[MAXPLAYERS+1][MAXPLAYERS+1];
// Stores who killed who
new Kills[MAXPLAYERS+1][MAXPLAYERS+1];
// Stores the distance between killers and victims upon death
new Float:Distance[MAXPLAYERS+1][MAXPLAYERS+1];
// Stores the weapon used to kill another player
new String:Weapon[MAXPLAYERS+1][MAXPLAYERS+1][MAX_LINE_WIDTH];
// Stores body part hits
new BodyParts[MAXPLAYERS+1][MAXPLAYERS+1][MAX_BODY_PARTS+1];
// Store the player names at the beginning of the round to handle disconnects
new String:Names[MAXPLAYERS+1][MAX_LINE_WIDTH];

// A list of strings from which stores all killstats panels for a certain number of rounds
// Panels are generated for a player by indexing their display lines and displaying as many as can be displayed 
new String:PanelDisplayKills[ROUNDS_TO_STORE][MAXPLAYERS+1][MAX_DISPLAY_LINES][MAX_LINE_WIDTH];
new String:PanelDisplayKilledBy[ROUNDS_TO_STORE][MAXPLAYERS+1][1][MAX_LINE_WIDTH]; // Can only be killed by one person, but use 2 as I'm not sure array[1] is supported
new String:PanelDisplayDamageDone[ROUNDS_TO_STORE][MAXPLAYERS+1][MAX_DISPLAY_LINES][MAX_LINE_WIDTH];
new String:PanelDisplayDamageTaken[ROUNDS_TO_STORE][MAXPLAYERS+1][MAX_DISPLAY_LINES][MAX_LINE_WIDTH];

// Current position in each array
new PanelDisplayKillsIndex[ROUNDS_TO_STORE][MAXPLAYERS+1];
new PanelDisplayKilledByIndex[ROUNDS_TO_STORE][MAXPLAYERS+1];
new PanelDisplayDamageDoneIndex[ROUNDS_TO_STORE][MAXPLAYERS+1];
new PanelDisplayDamageTakenIndex[ROUNDS_TO_STORE][MAXPLAYERS+1];

// "Staging Area" for displaying a set of panels to the screen
new String:PanelDisplayKillStats[MAXPLAYERS+1][MAX_KILLSTATS_PANELS][MAX_DISPLAY_LINES][MAX_LINE_WIDTH];
// Staging for which rows are actually going to be DrawPanelItem records instead of DrawPanelText records
new PanelDisplayKillStatsHeader[MAXPLAYERS+1][MAX_KILLSTATS_PANELS][MAX_DISPLAY_LINES];
// Which panels are continuations from other panels
new PanelDisplayKillStatsIsCont[MAXPLAYERS+1][MAX_KILLSTATS_PANELS];

// For displaying the current panel
new KSCurrentPanel[MAXPLAYERS+1];
new KSCurrentPanelDisplayTime[MAXPLAYERS+1];

// Whether the client should see the kill stats options menu upon joining
new bool:NewClient[MAXPLAYERS+1];

// Used for isAlive
new iLifeState = -1;

// Whether to show killstats_debug messages or not 
new bool:killstats_debug = false;
new bool:killstats_debug_verbose=false;
new bool:killstats_info = false;
new bool:killstats_info_verbose = false;

// To make sure everything is initialized properly if the plugin is loaded late
new bool:lateLoaded;

// Used to determine which set of panel messages to look at
new currentRound = 0;

// Stores body part translation strings
new String:bodyPartStrings[MAX_BODY_PARTS+1][MAX_LINE_WIDTH];

// cvars for panel timer display options
new Handle:cvarEnabledByDefault=INVALID_HANDLE;
new Handle:cvarUnitOfMeasure=INVALID_HANDLE;
new Handle:cvarShowStartupHelp=INVALID_HANDLE;
new Handle:cvarNewPlayerOptions=INVALID_HANDLE;
new Handle:cvarViewTime=INVALID_HANDLE;
new Handle:cvarRoundEndTime=INVALID_HANDLE;
new Handle:cvarDeathTime=INVALID_HANDLE;
new Handle:cvarShowOnTeamKill=INVALID_HANDLE;
new Handle:cvarDefaultMenuShowKilled=INVALID_HANDLE;
new Handle:cvarDefaultMenuShowKilledBy=INVALID_HANDLE;
new Handle:cvarDefaultMenuShowDamageDone=INVALID_HANDLE;
new Handle:cvarDefaultMenuShowDamageTaken=INVALID_HANDLE;
new Handle:cvarDefaultChatShowKilled=INVALID_HANDLE;
new Handle:cvarDefaultChatShowKilledBy=INVALID_HANDLE;
new Handle:cvarDefaultChatShowDamageDone=INVALID_HANDLE;
new Handle:cvarDefaultChatShowDamageTaken=INVALID_HANDLE;
new Handle:cvarDefaultShowInChat=INVALID_HANDLE;
new Handle:cvarDefaultShowInMenu=INVALID_HANDLE;
new Handle:cvarChatDisplayOrder=INVALID_HANDLE;
new Handle:cvarMenuDisplayOrder=INVALID_HANDLE;
new Handle:cvarCombineDamage=INVALID_HANDLE;
new Handle:cvarShowDeathMark=INVALID_HANDLE;
new Handle:cvarShowDistance=INVALID_HANDLE;
new Handle:cvarShowBodyHits=INVALID_HANDLE;
new Handle:cvarShowWeaponUsed=INVALID_HANDLE;
new Handle:cvarShowEmptyMenus=INVALID_HANDLE;
new Handle:cvarMaxPanelWidth=INVALID_HANDLE;
new Handle:cvarRestartNumbering=INVALID_HANDLE;

// SQL Variables
new Handle:sqlConnection = INVALID_HANDLE;


/****************************************************

				Startup

*****************************************************/
public OnPluginStart()
{
	killstats_info = false;
	killstats_info_verbose = false;
	killstats_debug = false;
	//killstats_debug_verbose = false;

	if ( killstats_info )
	{	
		LogMessage("OnPluginStart");
	}
	
	LoadTranslations("killstats.cvars");
	LoadTranslations("killstats.phrases");
	LoadTranslations("killstats.damagestrings");
	LoadTranslations("killstats.weapons");

	CreateCVars();
	
	iLifeState = FindSendPropOffs("CBasePlayer", "m_lifeState");

	// Listen for these events - when fired, call my local function
	// PostNoCopy can be used here for efficiency because none of the params to round_start are used
	HookEvent("round_start", EventRoundStart,EventHookMode_PostNoCopy);
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("player_hurt", EventPlayerHurt);
	HookEvent("round_end", EventRoundEnd);

	// Register !killstatsoptions
	RegConsoleCmd(CONSOLE_KILLSTATS_OPTIONS, PanelKillStatsOptions);
	
	// Register !killstats
	RegConsoleCmd(CONSOLE_KILLSTATS, PanelKillStats);
	RegConsoleCmd(CONSOLE_DAMAGE, PanelKillStats);
	
	// Set player preferences
	for(new i=0;i<=MAXPLAYERS;i++)
	{
		StatPreference[STAT_PREF_ENABLED][i]=PREF_UNSPECIFIED;
		StatPreference[STAT_PREF_SHOW_MENU][i]=PREF_UNSPECIFIED;
		StatPreference[STAT_PREF_SHOW_CHAT][i]=PREF_UNSPECIFIED;
	}
	
	InitializePrefsDatabase();

	// Load Body part array
	bodyPartStrings[HEAD] = HEAD_STRING;
	bodyPartStrings[CHEST] = CHEST_STRING;
	bodyPartStrings[STOMACH] = STOMACH_STRING;
	bodyPartStrings[LEFT_ARM] = LEFT_ARM_STRING;
	bodyPartStrings[RIGHT_ARM] = RIGHT_ARM_STRING;
	bodyPartStrings[LEFT_LEG] = LEFT_LEG_STRING;
	bodyPartStrings[RIGHT_LEG] = RIGHT_LEG_STRING;
	
	// Default to not seeing killstats options menu upon joining.  If player prefs are not
	// found upon connection, this will be set to true and then on mapstart they will see the options
	for ( new i=0 ; i <= MAXPLAYERS ; i++ )
	{
		NewClient[i]=false;
	}
		
	if ( lateLoaded )
	{
		// We need to whatever we would have done as each client authorized
		for(new i = 1; i <= GetMaxClients(); i++) 
		{
			if(IsClientInGame(i))
			{
				InitializeClient(i);
			}
		}
	}
}

// We need to capture if the plugin was late loaded so we can make sure initializations
// are handled properly
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	if ( killstats_info )
	{	
		LogMessage("AskPluginLoad");
	}
	
	lateLoaded = late;
	return true;
}

/****************************************************

				Events

*****************************************************/
public EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( killstats_info )
	{	
		LogMessage("RoundStart");
	}

	// If rounds to store is 2, this will continuously alternate between 0 and 1.  
	// If 3, it will alternate 0,1,2... etc.
	currentRound = (currentRound + 1) % ROUNDS_TO_STORE;

	if ( killstats_debug )
	{
		LogMessage("Current Round: %d", currentRound);
	}
	

	// Reset PlayerDamage 
	for (new i=0; i<=MAXPLAYERS; i++)
	{
		if ( killstats_debug )
		{
			LogMessage("i = %d", i);
			LogMessage("Reset damage");
		}
		
		for (new j=0; j<=MAXPLAYERS; j++)
		{
			Damage[i][j]=0;
			Kills[i][j]=0;
			Hits[i][j]=0;
			HealthLeft[i][j]=0;
			Distance[i][j]=0.0;
			Weapon[i][j][0]='\0';

			for (new part=0;part<=MAX_BODY_PARTS;part++)
			{
				BodyParts[i][j][part]=0;
			}
		}
		
		if ( killstats_debug )
		{
			LogMessage("Reset Indexes");
		}
		
		// Reset Index
		PanelDisplayKillsIndex[currentRound][i]=0;
		PanelDisplayKilledByIndex[currentRound][i]=0;
		PanelDisplayDamageDoneIndex[currentRound][i]=0;
		PanelDisplayDamageTakenIndex[currentRound][i]=0;

		if ( killstats_debug )
		{
			LogMessage("Killed By");
		}
		
		if ( killstats_debug_verbose )
		{
			// Reset Text
			LogMessage("Reset PanelDisplayKilledBy - currentRound: %d ; i: %d", currentRound, i );
		}	

		PanelDisplayKilledBy[currentRound][i][0][0]='\0'; 
		
		// For testing only - should not be used!!
		//PanelDisplayKilledBy[currentRound][i][0]=""; 

		if ( killstats_debug )
		{
			LogMessage("Other Display Panels");
		}

		for ( new line=0; line < MAX_DISPLAY_LINES ; line++ )
		{
			PanelDisplayKills[currentRound][i][line][0]='\0';
			PanelDisplayDamageDone[currentRound][i][line][0]='\0';
			PanelDisplayDamageTaken[currentRound][i][line][0]='\0';
		}

		if ( killstats_debug )
		{
			LogMessage("Done with i");
		}
		
	}
	
	for ( new i = 1 ; i <= GetMaxClients() ; i++ )
	{
		if ( killstats_debug )
		{
			LogMessage("Another i!");
		}
		
		if ( IsClientInGame(i) )
		{
			GetClientName(i,Names[i],MAX_LINE_WIDTH);

			if ( killstats_debug )
			{
				LogMessage("Got Client Name");
			}

			if ( !IsFakeClient(i) )
			{
				// If the server is set up to show options to new players and this is a new player then show the options
				if ( GetConVarBool(cvarNewPlayerOptions) && NewClient[i] )
				{
					DisplayKillStatsOptions(i);
					NewClient[i] = false;
				}
			}
		}
		else
		{
			if ( killstats_debug )
			{
				LogMessage("Unknown Client");
			}

			Names[i]="Unknown";
		}
		
		if ( killstats_debug )
		{
			LogMessage("Done with that i too");
		}		
	}
	
	if ( killstats_debug )
	{
		LogMessage("Done starting round");
	}
}

public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( killstats_info )
	{	
		LogMessage("EventRoundEnd");
	}
	
	new reasonId = GetEventInt(event,"reason");
	
	// If this is the end of the practice round, don't do this!
	if ( reasonId != REASON_PRACTICE_ROUND_END ) 
	{
		for (new player=1; player<=GetMaxClients(); player++)
		{
			if ( IsClientInGame(player) && !IsFakeClient(player) && IsAlive(player)
				&& IsShowStatsEnabled(player, DISPLAY_REASON_ROUND_END ) )
			{
				DisplayPlayerRoundStats(player,GetConVarInt(cvarRoundEndTime));
			}
		}
	}
}
// The hit event
public EventPlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( killstats_info )
	{	
		LogMessage("EventPlayerHurt");
	}

	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new damage = GetEventInt(event,"dmg_health");
	new hitgroup = GetEventInt(event,"hitgroup");
	
	new victim = GetClientOfUserId(victimId);
	new attacker = GetClientOfUserId(attackerId);

	// Make sure attacker is valid (not world damage, self damage, etc)
	if ( ( attacker > 0 ) && ( attacker <= MAXPLAYERS ) && ( victim != attacker ) )
	{
		// Store damage, number of hits, and body part hit for later
		Damage[attacker][victim]+=damage;
		Hits[attacker][victim]++;
		
		BodyParts[attacker][victim][hitgroup]++;

		if ( killstats_debug ) 
		{		
			LogMessage("Body Hit (%d,%d): %d", attacker, victim, hitgroup);
		}
	}
}

// The death event
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( killstats_info )
	{	
		LogMessage("EventPlayerDeath");
	}
	
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");

	new victim = GetClientOfUserId(victimId);
	new attacker = GetClientOfUserId(attackerId);

	// Give the attacker credit for killing me
	if ( ( attacker > 0 ) && ( attacker <= GetMaxClients() ) && ( victim != attacker ) )
	{
		Kills[attacker][victim]++;
		HealthLeft[attacker][victim]=GetClientHealth(attacker);

		GetEventString(event,"weapon",Weapon[attacker][victim],MAX_LINE_WIDTH);
	
		// Calculate distance	
		new Float:attackerCoords[3];	
		new Float:victimCoords[3];
		
		GetClientAbsOrigin( attacker, attackerCoords );
		GetClientAbsOrigin( victim, victimCoords );
		
		Distance[attacker][victim] = GetVectorDistance( attackerCoords, victimCoords );  
		
		switch ( GetConVarInt( cvarUnitOfMeasure ) )
		{
			case 1: // Feet
				Distance[attacker][victim] /= UNITS_PER_FOOT;
				
			case 2: // Meters
				Distance[attacker][victim] /= UNITS_PER_METER;
		}
		
		// Does the victim have stats enabled?  Make sure they aren't a bot
		if ( IsShowStatsEnabled(victim, DISPLAY_REASON_DEATH ) && !IsFakeClient(victim) )
		{
			// Also, if we are on the same team, am I supposed to show team kills?
			if ( ( IsSameTeam(victim,attacker) ) )
			{
				// Only show if convar specifies that team kills are supposed to be shown
				if ( GetConVarInt(cvarShowOnTeamKill) )
				{
					DisplayPlayerRoundStats(victim,GetConVarInt(cvarDeathTime));
				}
			}
			else
			{
				DisplayPlayerRoundStats(victim,GetConVarInt(cvarDeathTime));
			}
		}
	}
}

/****************************************************

				CVar Management

*****************************************************/

public CreateCVars()
{
	if ( killstats_info )
	{	
		LogMessage("CreateCVars");
	}

	// This buffer will be used for all of the cvars/console commands as a temporary storage space for translations
	decl String:translationBuffer[MAX_LINE_WIDTH];
	
	// Set up enabled cvar	
	new Handle:cvarEnabled=INVALID_HANDLE;
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_ENABLED, LANG_SERVER);
	cvarEnabled = CreateConVar(CVAR_ENABLED, "1", translationBuffer);
	if ( !GetConVarBool(cvarEnabled) )
	{
		SetFailState("Plugin Disabled");
	}
	
	// Set up version cvar
	CreateConVar("sm_killstats_version", PLUGIN_VERSION, "Kill Stats Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	// Feet or meters - default to feet
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_UNIT_OF_MEASURE, LANG_SERVER);
	cvarUnitOfMeasure = CreateConVar(CVAR_UNIT_OF_MEASURE, "1", translationBuffer);
	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_SHOW_STARTUP_HELP, LANG_SERVER);
	cvarShowStartupHelp = CreateConVar(CVAR_SHOW_STARTUP_HELP, "1", translationBuffer);
	
	// Specify whether players see killstats by default or whether they have to enable them to see
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_ENABLED_BY_DEFAULT, LANG_SERVER);
	cvarEnabledByDefault = CreateConVar(CVAR_ENABLED_BY_DEFAULT, "1", translationBuffer);

	// Whether new players see the killstatsoptions panel or not
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_NEW_PLAYER_OPTIONS, LANG_SERVER);
	cvarNewPlayerOptions = CreateConVar(CVAR_NEW_PLAYER_OPTIONS, "1", translationBuffer);
	
	// Whether to show on team kill or not	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_SHOW_ON_TEAMKILL, LANG_SERVER);
	cvarShowOnTeamKill = CreateConVar(CVAR_SHOW_ON_TEAMKILL, "0", translationBuffer);
	
	// Set up death time cvar
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEATH_TIME, LANG_SERVER);
	cvarDeathTime = CreateConVar(CVAR_DEATH_TIME, "20", translationBuffer);
	
	// Set up round end time cvar
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_ROUND_END_TIME, LANG_SERVER);
	cvarRoundEndTime = CreateConVar(CVAR_ROUND_END_TIME, "6", translationBuffer);
	
	// Set up view time cvar
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_VIEW_TIME, LANG_SERVER);
	cvarViewTime = CreateConVar(CVAR_VIEW_TIME, "20", translationBuffer);

	// Whether to show the kills menu item	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEFAULT_MENU_SHOW_KILLED, LANG_SERVER);
	cvarDefaultMenuShowKilled = CreateConVar(CVAR_DEFAULT_MENU_SHOW_KILLED, "1", translationBuffer);
	
	// Whether to show the killed by menu item	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEFAULT_MENU_SHOW_KILLED_BY, LANG_SERVER);
	cvarDefaultMenuShowKilledBy = CreateConVar(CVAR_DEFAULT_MENU_SHOW_KILLED_BY, "1", translationBuffer);
	
	// Whether to show the damage done menu item	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEFAULT_MENU_SHOW_DAMAGE_DONE, LANG_SERVER);
	cvarDefaultMenuShowDamageDone = CreateConVar(CVAR_DEFAULT_MENU_SHOW_DAMAGE_DONE, "1", translationBuffer);
	
	// Whether to show the damage taken menu item	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEFAULT_MENU_SHOW_DAMAGE_TAKEN, LANG_SERVER);
	cvarDefaultMenuShowDamageTaken = CreateConVar(CVAR_DEFAULT_MENU_SHOW_DAMAGE_TAKEN, "1", translationBuffer);

	// Whether to show the kills in chat
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEFAULT_CHAT_SHOW_KILLED, LANG_SERVER);
	cvarDefaultChatShowKilled = CreateConVar(CVAR_DEFAULT_CHAT_SHOW_KILLED, "1", translationBuffer);
	
	// Whether to show the kills menu item	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEFAULT_CHAT_SHOW_KILLED_BY, LANG_SERVER);
	cvarDefaultChatShowKilledBy = CreateConVar(CVAR_DEFAULT_CHAT_SHOW_KILLED_BY, "1", translationBuffer);
	
	// Whether to show the kills menu item	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEFAULT_CHAT_SHOW_DAMAGE_DONE, LANG_SERVER);
	cvarDefaultChatShowDamageDone = CreateConVar(CVAR_DEFAULT_CHAT_SHOW_DAMAGE_DONE, "1", translationBuffer);
	
	// Whether to show the kills menu item	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEFAULT_CHAT_SHOW_DAMAGE_TAKEN, LANG_SERVER);
	cvarDefaultChatShowDamageTaken = CreateConVar(CVAR_DEFAULT_CHAT_SHOW_DAMAGE_TAKEN, "1", translationBuffer);

	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEFAULT_SHOW_IN_CHAT, LANG_SERVER);
	cvarDefaultShowInChat = CreateConVar(CVAR_DEFAULT_SHOW_IN_CHAT,"1",translationBuffer);
	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_DEFAULT_SHOW_IN_MENU, LANG_SERVER);
	cvarDefaultShowInMenu = CreateConVar(CVAR_DEFAULT_SHOW_IN_MENU,"1",translationBuffer);

	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_CHAT_DISPLAY_ORDER, LANG_SERVER);
	cvarChatDisplayOrder = CreateConVar(CVAR_CHAT_DISPLAY_ORDER,"2413",translationBuffer);

	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_MENU_DISPLAY_ORDER, LANG_SERVER);
	cvarMenuDisplayOrder = CreateConVar(CVAR_MENU_DISPLAY_ORDER,"1234",translationBuffer);
	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_COMBINE_DAMAGE, LANG_SERVER);
	cvarCombineDamage = CreateConVar(CVAR_COMBINE_DAMAGE,"0",translationBuffer);
	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_SHOW_DISTANCE, LANG_SERVER);
	cvarShowDistance = CreateConVar(CVAR_SHOW_DISTANCE,"1",translationBuffer);
	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_SHOW_BODY_HITS, LANG_SERVER);
	cvarShowBodyHits = CreateConVar(CVAR_SHOW_BODY_HITS,"1",translationBuffer);
	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_SHOW_WEAPON_USED, LANG_SERVER);
	cvarShowWeaponUsed = CreateConVar(CVAR_SHOW_WEAPON_USED,"1",translationBuffer);

	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_SHOW_EMPTY_MENUS, LANG_SERVER);
	cvarShowEmptyMenus = CreateConVar(CVAR_SHOW_EMPTY_MENUS,"1",translationBuffer);

	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_MAX_PANEL_WIDTH, LANG_SERVER);
	cvarMaxPanelWidth = CreateConVar(CVAR_MAX_PANEL_WIDTH,"100",translationBuffer);
	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_SHOW_DEATH_MARK, LANG_SERVER);
	cvarShowDeathMark = CreateConVar(CVAR_SHOW_DEATH_MARK,"0",translationBuffer);
	
	Format(translationBuffer, MAX_LINE_WIDTH, "%T", CVAR_RESTART_NUMBERING, LANG_SERVER);
	cvarRestartNumbering = CreateConVar(CVAR_RESTART_NUMBERING,"0",translationBuffer);
}

/****************************************************

				Player Functions

*****************************************************/

// When a new client is authorized we reset stats preferences
// and let them know how to turn the stats on and off
public OnClientAuthorized(client, const String:auth[])
{
	if ( killstats_info )
	{	
		LogMessage("OnClientAuthorized");
	}

	InitializeClient(client);
}

public InitializeClient( client )
{
	if ( killstats_info )
	{	
		LogMessage("InitializeClient");
	}

	if ( ( client > 0 ) && ( client <= MAXPLAYERS ) ) 
	{
		// Check the database to load players prefs
		if ( !IsFakeClient(client) )
		{
			LoadPrefs(client);
			
			if ( GetConVarBool( cvarShowStartupHelp ) )
			{
				CreateTimer(30.0, TimerAnnounce, client);
			}
		}
		
		for ( new i=0; i<= MAXPLAYERS ; i++ )
		{
			// Wipe any damage / stats from this round done by former client
			Damage[client][i]=0;
			Kills[client][i]=0;
			Hits[client][i]=0;
			HealthLeft[client][i]=0;
			Distance[client][i]=0.0;
			Weapon[client][i][0]='\0';
			
			// Wipe any damage done to former client
			Damage[i][client]=0;
			Kills[i][client]=0;
			Hits[i][client]=0;
			HealthLeft[i][client]=0;
			Distance[i][client]=0.0;
			Weapon[client][i][0]='\0';

			for (new part=0 ; part<=MAX_BODY_PARTS ; part++ )
			{
				BodyParts[client][i][part]=0;
				BodyParts[i][client][part]=0;
			}
		}
		
		for ( new round=0 ; round < ROUNDS_TO_STORE ; round++ )
		{
			PanelDisplayKilledBy[round][client][0][0]='\0'; 
			
			for ( new line=0; line < MAX_DISPLAY_LINES ; line++ )
			{
				PanelDisplayKills[round][client][line][0]='\0';
				PanelDisplayDamageDone[round][client][line][0]='\0';
				PanelDisplayDamageTaken[round][client][line][0]='\0';
			}
	
			PanelDisplayKillsIndex[round][client]=0;
			PanelDisplayKilledByIndex[round][client]=0;
			PanelDisplayDamageDoneIndex[round][client]=0;
			PanelDisplayDamageTakenIndex[round][client]=0;
		}
		

		// Store my name, just in case I fight someone and get disconnected 
		GetClientName( client, Names[client], MAX_LINE_WIDTH );
	}
}

// This function was stolen from ferret's teambet plugin
public bool:IsAlive(client)
{
	if ( killstats_info )
	{	
		LogMessage("IsAlive");
	}

	if (iLifeState != -1 && GetEntData(client, iLifeState, 1) == 0)
        return true;
 
	return false;
}

public Action:TimerAnnounce(Handle:timer, any:client)
{
	if ( killstats_info )
	{	
		LogMessage("TimerAnnounce");
	}

	decl String:translationBuffer[MAX_LINE_WIDTH];

	if ( IsClientInGame( client ) )
	{	
		// We have double translations here to translate the string used by the translation string since it translates the command referenced
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLSTATS_DISPLAY,client,CONSOLE_KILLSTATS_SAY,CONSOLE_DAMAGE_SAY);
		SafePrintToChat(client, translationBuffer);
		
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLSTATS_OPTIONS_DISPLAY,client,CONSOLE_KILLSTATS_OPTIONS_SAY);
		SafePrintToChat(client, translationBuffer);
	}
}


/****************************************************

				Utility Functions

*****************************************************/
public bool:IsValidNonBotClient(client)
{
	if ( killstats_info )
	{	
		LogMessage("IsValidNonBotClient");
	}

	return ( client > 0 && client <= GetMaxClients() && IsClientInGame(client) && !IsFakeClient(client) );
}

public SafePrintToChat(client,String:message[MAX_LINE_WIDTH])
{
	if ( killstats_info )
	{	
		LogMessage("SafePrintToChat");
	}

	if ( IsValidNonBotClient( client ) )
	{
		PrintToChat(client,message);
	}
}

public bool:IsPreferenceEnabled(player,pref,Handle:cvar)
{
	if ( killstats_info )
	{	
		LogMessage("IsPreferenceEnabled");
	}

	return ( ( StatPreference[pref][player] == PREF_ENABLED )
			|| ( ( StatPreference[pref][player] == PREF_UNSPECIFIED )
				&& GetConVarBool( cvar ) ) );
}

public bool:IsShowStatsEnabled( client, reason )
{
	if ( killstats_info )
	{	
		LogMessage("IsShowStatsEnabled");
	}
		
	decl bool:returnValue;
	
	returnValue = false;
	
	// Client has chosen to show the kill stats or not specified and default is to show
	if ( IsPreferenceEnabled( client, STAT_PREF_ENABLED, cvarEnabledByDefault ) )
	{
		return true;
	}
	// We're checking on client death and the client has chosen to display on death
	else if ( reason == DISPLAY_REASON_DEATH && StatPreference[STAT_PREF_ENABLED][client] == PREF_ENABLED_ON_DEATH )
	{
		returnValue = true;
	}
	else if ( reason == DISPLAY_REASON_ROUND_END && StatPreference[STAT_PREF_ENABLED][client] == PREF_ENABLED_ON_ROUND_END )
	{
		returnValue = true;
	}
	
	return returnValue;
}

public bool:IsSameTeam(attacker,victim)
{
	if ( killstats_info )
	{	
		LogMessage("IsSameTeam");
	}
		
	new attackerTeam = GetClientTeam(attacker);
	new victimTeam = GetClientTeam(victim);
	
	return attackerTeam == victimTeam;
}

public String:CreateBodyHitsString(String:strbodyparts[MAX_LINE_WIDTH],client,displayType,bodyparts[])
{
	if ( killstats_info )
	{	
		LogMessage("CreateBodyHitsString");
	}
	
	// Stores string to be translated
	decl String:bodyPartFullString[MAX_LINE_WIDTH];
	decl String:bodyCombinedParts[MAX_LINE_WIDTH];
	decl String:bodyIndividualPart[MAX_LINE_WIDTH];
	
	// This will put a divider between body parts if there are more than 1 (1 headshot, 3 chest)
	decl String:translatedBodyPart[MAX_LINE_WIDTH];
	// Formatted like "1 headshot"
	decl String:translatedBodyPartString[MAX_LINE_WIDTH];

	// tmp vars for building body part strings	
	decl String:currentBodyPartString[MAX_LINE_WIDTH];
	decl String:oldBodyPartString[MAX_LINE_WIDTH];

	// Found hit - to determine how to combine body parts - did we have a hit already or is this the first?
	new bool:foundHit = false;

	if ( displayType == DISPLAY_TYPE_MENU )
	{
		bodyPartFullString = MENU_BODY_PART_FULL_STRING;
		bodyCombinedParts = MENU_BODY_COMBINED_PARTS;
		bodyIndividualPart = MENU_BODY_INDIVIDUAL_PART;
	}	
	else
	{
		bodyPartFullString = CHAT_BODY_PART_FULL_STRING;
		bodyCombinedParts = CHAT_BODY_COMBINED_PARTS;
		bodyIndividualPart = CHAT_BODY_INDIVIDUAL_PART;
	}
	
	if ( killstats_debug ) 
	{	
		LogMessage("Printing Body parts for %d", client);
	}
	
	if ( bodyparts[HEAD] > 1 )
	{
		foundHit = true;
		Format(translatedBodyPart,MAX_LINE_WIDTH,"%T",HEADSHOTS,client);
		Format(currentBodyPartString,MAX_LINE_WIDTH,"%T",bodyIndividualPart,client,bodyparts[HEAD],translatedBodyPart);
	}
	else if ( bodyparts[HEAD] == 1 )
	{
		foundHit = true;
		Format(translatedBodyPart,MAX_LINE_WIDTH,"%T",HEADSHOT,client);
		Format(currentBodyPartString,MAX_LINE_WIDTH,"%T",bodyIndividualPart,client,bodyparts[HEAD],translatedBodyPart);
	}
	
	// if we want to show more than just headshots
	if ( GetConVarInt( cvarShowBodyHits ) == SHOW_ALL_BODY_DAMAGE )
	{
		for ( new parts=2; parts <= MAX_BODY_PARTS ;parts++)
		{
			if ( bodyparts[parts] > 0 )
			{
				oldBodyPartString = currentBodyPartString;
				
				Format(translatedBodyPart,MAX_LINE_WIDTH,"%T",bodyPartStrings[parts],client);
				Format(translatedBodyPartString,MAX_LINE_WIDTH,"%T",bodyIndividualPart,client,bodyparts[parts],translatedBodyPart);
				
				if ( foundHit )
				{
					Format(currentBodyPartString,MAX_LINE_WIDTH,"%T",bodyCombinedParts,client,oldBodyPartString,translatedBodyPartString);
				}
				else
				{
					foundHit = true;
					currentBodyPartString = translatedBodyPartString;
				}
			}
		}
	}
			
	if ( foundHit )
	{
		Format(strbodyparts,MAX_LINE_WIDTH,"%T",bodyPartFullString,client,currentBodyPartString);
	}
	else
	{
		strbodyparts[0]='\0';
	}
	
	if ( killstats_debug ) 
	{
		LogMessage("Found Hit: %d ; String: %s", foundHit, strbodyparts);
	}
}

/****************************************************

					DAMAGE

*****************************************************/
public CreateDamageString( client, String:strdamage[], maxlength, String:strname[], damage, hits, bodyparts[], killed, Float:distance, 
	attackerHealthRemaining, displayType, bool:damageDone, String:myname[], String:weapon[] )
{
	if ( killstats_info )
	{	
		LogMessage("CreateDamageString");
	}

	// Used for final translation (%T) and adds deathmark if applicable
	new String:translationString[MAX_LINE_WIDTH] = "  %T";
	
	decl String:deathString[MAX_LINE_WIDTH];
	decl String:damageString[MAX_LINE_WIDTH];

	decl String:translatedWeapon[MAX_LINE_WIDTH];
	decl String:translatedWeaponString[MAX_LINE_WIDTH];
	decl String:weaponTranslation[MAX_LINE_WIDTH];
	
	decl String:strbodyparts[MAX_LINE_WIDTH];
	
	// Determine unit of measure string for distance display
	decl String:distanceString[MAX_LINE_WIDTH];
	decl String:unitOfMeasure[MAX_LINE_WIDTH];
	decl String:distanceTranslation[MAX_LINE_WIDTH];
	
	if ( displayType == DISPLAY_TYPE_MENU )
	{
		distanceTranslation = MENU_DISTANCE_STRING;
		weaponTranslation = MENU_WEAPON_STRING;

		if ( damageDone )
		{
			deathString = MENU_DAMAGE_DONE_DEATH_STRING;
			damageString = MENU_DAMAGE_DONE_STRING;
		}
		else
		{
			deathString = MENU_DAMAGE_TAKEN_DEATH_STRING;
			damageString = MENU_DAMAGE_TAKEN_STRING;
		}
	}
	else
	{
		distanceTranslation = CHAT_DISTANCE_STRING;
		weaponTranslation = CHAT_WEAPON_STRING;
		
		if ( damageDone )
		{
			deathString = CHAT_DAMAGE_DONE_DEATH_STRING;
			damageString = CHAT_DAMAGE_DONE_STRING;
		}
		else
		{
			deathString = CHAT_DAMAGE_TAKEN_DEATH_STRING;
			damageString = CHAT_DAMAGE_TAKEN_STRING;
		}
	}

	if ( GetConVarInt( cvarShowBodyHits ) > 0 )
	{
		CreateBodyHitsString(strbodyparts,client,displayType,bodyparts);
	}
	else
	{
		strbodyparts[0]='\0';
	}
		
	if ( GetConVarBool(cvarShowDistance) )
	{
		GetUnitOfMeasureString(unitOfMeasure,client);
		Format(distanceString,MAX_LINE_WIDTH,"%T",distanceTranslation,client,distance,unitOfMeasure);
	}
	else
	{
		distanceString[0]='\0';
	}
	
	if ( GetConVarBool(cvarShowWeaponUsed) && ( strlen(weapon) > 0 ) )
	{
		// Translate weapon string
		Format(translatedWeapon,MAX_LINE_WIDTH,"%T",weapon,client);
		Format(translatedWeaponString,MAX_LINE_WIDTH,"%T",weaponTranslation,client,translatedWeapon);
	}
	else
	{
		translatedWeaponString[0]='\0';
	}
	
	if ( killed )
	{
		// For chat the * should already be displayed
		if ( ( displayType == DISPLAY_TYPE_MENU ) && ( GetConVarBool(cvarShowDeathMark) || GetConVarBool(cvarCombineDamage) ) )
		{
			translationString = " *%T";
		}
		
		Format(
			strdamage,
			maxlength,
			translationString,
			deathString,
			client,
			strname,
			damage,
			hits,
			strbodyparts,
			distanceString,
			myname,
			attackerHealthRemaining,
			translatedWeaponString
			);
	}
	else
	{
		Format(
			strdamage,
			maxlength,
			translationString,
			damageString,
			client,
			strname,
			damage,
			hits,
			strbodyparts,
			myname
			);
	}
}								

public GetUnitOfMeasureString(String:unitOfMeasure[MAX_LINE_WIDTH],client)
{
	if ( killstats_info )
	{	
		LogMessage("GetUnitOfMeasureString");
	}

	switch ( GetConVarInt( cvarUnitOfMeasure ) )
	{
		case 1: // Feet
			Format(unitOfMeasure,MAX_LINE_WIDTH,"%T",FEET,client);
		
		case 2: // Meters
			Format(unitOfMeasure,MAX_LINE_WIDTH,"%T",METERS,client);
	}
}

// The comparison function used in the sort routine to show max damage first
// Use to sort an array of strings by damage descending
public SortDamageDesc(row1[], row2[], const array[][], Handle:hndl)
{
	if ( killstats_info_verbose )
	{	
		LogMessage("SortDamageDesc");
	}
	
	if(row1[1] > row2[1])
    {
		return -1;
	}
	else if(row1[1] == row2[1])
	{
		return 0;
	}
	else
	{
    	return 1;
    }
}

public DisplayPlayerRoundStats(player,displayTime)
{
	if ( killstats_info )
	{	
		LogMessage("DisplayPlayerRoundStats");
	}

	// Reset Index to avoid repeating information when displayed twice or more in one round (!damage or !killstats)
	PanelDisplayKillsIndex[currentRound][player]=0;
	PanelDisplayKilledByIndex[currentRound][player]=0;
	PanelDisplayDamageDoneIndex[currentRound][player]=0;
	PanelDisplayDamageTakenIndex[currentRound][player]=0;
	GenerateOutputRoundStats(player);

	if ( IsPreferenceEnabled(player,STAT_PREF_SHOW_MENU,cvarDefaultShowInMenu) )
	{	
		GeneratePanelRoundStats(player,currentRound);
		
		// Set to beginning
		KSCurrentPanel[player]=0;
		KSCurrentPanelDisplayTime[player]=displayTime;
		DrawMultiPanelKSDisplay(player);
	}
	else
	{
		DisplayChatMessages(player,currentRound);
	}
}

/*
public DrawTestMultiPanelDisplay(player)
{
	if ( killstats_info )
	{	
		LogMessage("DrawTestMultiPanelDisplay");
	}
	
	for ( new panel=0 ; panel<MAX_KILLSTATS_PANELS ; panel++ )
	{
		for ( new index=0 ; index < MAX_DISPLAY_LINES ; index++ )
		{
			if ( PanelDisplayKillStatsHeader[player][panel][index]==-1 )
			{
				break;
			}
			else
			{
				if ( PanelDisplayKillStatsHeader[player][panel][index] > 0 )
				{
					if ( index == 0 && PanelDisplayKillStatsIsCont[player][panel] )
					{
						decl String:trans[MAX_LINE_WIDTH];
						Format(trans,MAX_LINE_WIDTH,"%T",MENU_CONTINUED,player,PanelDisplayKillStats[player][panel][index]);
						
						if ( killstats_debug )
					    {
							LogMessage("ITEM: %s",trans);
						}
					}
					else
					{
					    if ( killstats_debug )
					    {
							LogMessage("ITEM: %s", PanelDisplayKillStats[player][panel][index]);
						}
					}
				}
				else
				{
					if ( killstats_debug ) 
					{
						LogMessage("Text:   %s", PanelDisplayKillStats[player][panel][index]);
					}
				}
			}
		}
	}
}
*/

public GenerateOutputRoundStats( player )	
{
	if ( killstats_info )
	{	
		LogMessage("GenerateOutputRoundStats");
	}
	
	// Limit nothing if combine damage is on - we will limit them to 2 categories in the end
	new bool:combineDamage=GetConVarBool(cvarCombineDamage);
	
	if ( IsValidNonBotClient( player ) )
	{
		if ( IsPreferenceEnabled(player,STAT_PREF_SHOW_MENU,cvarDefaultShowInMenu) )
		{
			if ( combineDamage || GetConVarBool( cvarDefaultMenuShowKilled ) )
			{
				CreateDamageDone(player,DISPLAY_TYPE_MENU,DAMAGE_TYPE_DEATH);
			}
						
			if ( combineDamage || GetConVarBool( cvarDefaultMenuShowKilledBy ) )
			{
				CreateDamageTaken(player,DISPLAY_TYPE_MENU,DAMAGE_TYPE_DEATH);
			}
						
			if ( combineDamage || GetConVarBool( cvarDefaultMenuShowDamageDone ) )
			{
				CreateDamageDone(player,DISPLAY_TYPE_MENU,DAMAGE_TYPE_DAMAGE);
			}
						
			if ( combineDamage || GetConVarBool( cvarDefaultMenuShowDamageTaken ) )
			{
				CreateDamageTaken(player,DISPLAY_TYPE_MENU,DAMAGE_TYPE_DAMAGE);
			}
		}

		if ( IsPreferenceEnabled(player,STAT_PREF_SHOW_CHAT,cvarDefaultShowInChat) )
		{
			if ( combineDamage || GetConVarBool( cvarDefaultChatShowKilled ) )
			{
				CreateDamageDone(player,DISPLAY_TYPE_CHAT,DAMAGE_TYPE_DEATH);
			}
						
			if ( combineDamage || GetConVarBool( cvarDefaultChatShowKilledBy ) )
			{
				CreateDamageTaken(player,DISPLAY_TYPE_CHAT,DAMAGE_TYPE_DEATH);
			}
						
			if ( combineDamage || GetConVarBool( cvarDefaultChatShowDamageDone ) )
			{
				CreateDamageDone(player,DISPLAY_TYPE_CHAT,DAMAGE_TYPE_DAMAGE);
			}
						
			if ( combineDamage || GetConVarBool( cvarDefaultChatShowDamageTaken ) )
			{
				CreateDamageTaken(player,DISPLAY_TYPE_CHAT,DAMAGE_TYPE_DAMAGE);
			}
		}
	}
}
		
// 1/3 - Damage Done		
public CreateDamageDone(player, displayType, damageType)
{
	if ( killstats_info )
	{	
		LogMessage("CreateDamageDone");
	}
	
	// Move damage to temp arrays so they can be sorted
	decl String:DamageDoneStrings[MAXPLAYERS+1][MAX_LINE_WIDTH];
	// Array of Amounts of damage done.  0 is client id, 1 is damage
	new DamageDone[MAXPLAYERS+1][2];
	
	// Whether any damage was dealt by this player this round - otherwise we will display "None"
	new damageDoneFlag = 0;

	for (new i=0; i<=MAXPLAYERS; i++)
	{
		if ( Damage[player][i] > 0 )
		{
			// If we're looking for kills and this is a kill OR we're looking for damage and this is damage
			if ( ( ( Kills[player][i] )&& ( damageType == DAMAGE_TYPE_DEATH ) )
				|| ( ( Kills[player][i] == 0 ) && ( damageType == DAMAGE_TYPE_DAMAGE ) ) )
			{
				CreateDamageString( 
					player, 
					DamageDoneStrings[i], 
					MAX_LINE_WIDTH, 
					Names[i], 
					Damage[player][i], 
					Hits[player][i], 
					BodyParts[player][i], 
					Kills[player][i], 
					Distance[player][i], 
					-1, // remaining health not needed for damage done
					displayType, 
					true,
					Names[player],
					Weapon[player][i] );
					
				damageDoneFlag=1;
				DamageDone[i][0] = i;
				DamageDone[i][1] = Damage[player][i];
			}
		}
	}

	if ( damageDoneFlag )
	{
		SortCustom2D(DamageDone, MAXPLAYERS+1, SortDamageDesc);
		
		new bool:combineDamage = GetConVarBool(cvarCombineDamage);

		for ( new i=0 ; i<=MAXPLAYERS && DamageDone[i][1] > 0 ; i++ )
		{
			if ( damageType == DAMAGE_TYPE_DAMAGE || combineDamage )
			{
				PanelDisplayDamageDone[currentRound][player][PanelDisplayDamageDoneIndex[currentRound][player]++]=DamageDoneStrings[DamageDone[i][0]];
			}
			else
			{
				PanelDisplayKills[currentRound][player][PanelDisplayKillsIndex[currentRound][player]++]=DamageDoneStrings[DamageDone[i][0]];
			}
		}
	}
}		

// 2/4 - Damage Taken
public CreateDamageTaken(player, displayType, damageType)
{
	if ( killstats_info )
	{	
		LogMessage("CreateDamageTaken");
	}
	
	// Move damage to temp arrays so they can be sorted
	decl String:DamageTakenStrings[MAXPLAYERS+1][MAX_LINE_WIDTH];
	// Array of Amounts of damage done.  0 is client id, 1 is damage
	new DamageTaken[MAXPLAYERS+1][2];
	new damageTakenFlag = 0;

	for (new i=0; i<=MAXPLAYERS; i++)
	{
		if ( Damage[i][player] > 0 )
		{
			// If we're looking for kills and this is a kill OR we're looking for damage and this is damage
			if ( ( ( Kills[i][player] )&& ( damageType == DAMAGE_TYPE_DEATH ) )
				|| ( ( Kills[i][player] == 0 ) && ( damageType == DAMAGE_TYPE_DAMAGE ) ) )
			{
				CreateDamageString( 
					player, 
					DamageTakenStrings[i], 
					MAX_LINE_WIDTH, 
					Names[i], 
					Damage[i][player], 
					Hits[i][player], 
					BodyParts[i][player], 
					Kills[i][player], 
					Distance[i][player], 
					HealthLeft[i][player],
					displayType, 
					false,
					Names[player],
					Weapon[i][player] );
				
				damageTakenFlag=1;
				DamageTaken[i][0] = i;
				DamageTaken[i][1] = Damage[i][player];
			}
		}

	}
	
	if ( damageTakenFlag )
	{
		SortCustom2D(DamageTaken, MAXPLAYERS+1, SortDamageDesc);

		new combineDamage=GetConVarBool(cvarCombineDamage);
		
		for ( new i=0 ; i<=MAXPLAYERS && DamageTaken[i][1] > 0 ; i++ )
		{
			if ( damageType == DAMAGE_TYPE_DAMAGE || combineDamage )
			{
				PanelDisplayDamageTaken[currentRound][player][PanelDisplayDamageTakenIndex[currentRound][player]++]=DamageTakenStrings[DamageTaken[i][0]];
			}
			else
			{
				PanelDisplayKilledBy[currentRound][player][0]=DamageTakenStrings[DamageTaken[i][0]];
				PanelDisplayKilledByIndex[currentRound][player]=1;
			}
		}
	}
}		


/****************************************************

				Display Panels

*****************************************************/

//  This sets enables or disables the automatic popup
public PanelHandlerKillStatsOptions(Handle:menu, MenuAction:action, param1, param2)
{
	if ( killstats_info )
	{	
		LogMessage("PanelHandlerKillStatsOptions");
	}
	
	if (action == MenuAction_Select)
	{
		if ( param2 == 1 )
		{
			StatPreference[STAT_PREF_ENABLED][param1] = PREF_ENABLED;
			SavePrefs(param1);
			DisplayMoreOptions(param1);
		}
		else if ( param2 == 2 )
		{
			StatPreference[STAT_PREF_ENABLED][param1] = PREF_ENABLED_ON_DEATH;
			SavePrefs(param1);
			DisplayMoreOptions(param1);
		}
		else if ( param2 == 3 )
		{
			StatPreference[STAT_PREF_ENABLED][param1] = PREF_ENABLED_ON_ROUND_END;
			SavePrefs(param1);
			DisplayMoreOptions(param1);
		}
		else if ( param2 == 4 )
		{
			StatPreference[STAT_PREF_ENABLED][param1] = PREF_DISABLED;
			SavePrefs(param1);
		}
		else if ( param2 == 5 )
		{
			DisplayPlayerRoundStats(param1,GetConVarInt(cvarViewTime));
		}
		else if( param2 == 9 )
		{
			DisplayMoreOptions(param1);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		// Ignore
	}
}
 
//  This creates the kill stats options panel
public Action:PanelKillStatsOptions(client, args)
{
	if ( killstats_info )
	{	
		LogMessage("PanelKillStatsOptions");
	}
	
	DisplayKillStatsOptions(client);
	return Plugin_Handled;
}

public DisplayKillStatsOptions(client)
{
	if ( killstats_info )
	{	
		LogMessage("DisplayKillStatsOptions");
	}
	
	decl String:translationBuffer[MAX_LINE_WIDTH];

	new Handle:panel = CreatePanel();
	
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLSTATS_OPTIONS,client);
	SetPanelTitle(panel, translationBuffer );
	
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",ENABLE,client);
	DrawPanelItem(panel, translationBuffer);

	Format(translationBuffer,MAX_LINE_WIDTH,"%T",ENABLE_ON_DEATH,client);
	DrawPanelItem(panel, translationBuffer);

	Format(translationBuffer,MAX_LINE_WIDTH,"%T",ENABLE_ON_ROUND_END,client);
	DrawPanelItem(panel, translationBuffer);

	Format(translationBuffer,MAX_LINE_WIDTH,"%T",DISABLE,client);
	DrawPanelItem(panel, translationBuffer);

	Format(translationBuffer,MAX_LINE_WIDTH,"%T",VIEW,client);
	DrawPanelItem(panel, translationBuffer);

	SetPanelCurrentKey( panel, 9 );
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",NEXT,client);
	DrawPanelItem(panel, translationBuffer);

	// Set for exit menu
	SetPanelCurrentKey( panel, 10 );
	
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",EXIT,client);
	DrawPanelItem(panel, translationBuffer);
		
	SendPanelToClient(panel, client, PanelHandlerKillStatsOptions, GetConVarInt(cvarViewTime) );
 
	CloseHandle(panel);
}

//  This sets enables or disables the automatic popup
public PanelHandlerMoreOptions(Handle:menu, MenuAction:action, param1, param2)
{
	if ( killstats_info )
	{	
		LogMessage("PanelHandlerMoreOptions");
	}
	
	if (action == MenuAction_Select)
	{
		if ( param2 == 1 )
		{
			StatPreference[STAT_PREF_SHOW_MENU][param1] = PREF_ENABLED;
			StatPreference[STAT_PREF_SHOW_CHAT][param1] = PREF_DISABLED;
			SavePrefs(param1);
		}
		else if ( param2 == 2 )
		{
			StatPreference[STAT_PREF_SHOW_MENU][param1] = PREF_DISABLED;
			StatPreference[STAT_PREF_SHOW_CHAT][param1] = PREF_ENABLED;
			SavePrefs(param1);
		}
		else if ( param2 == 8 )
		{
			DisplayKillStatsOptions( param1 );
		}
	}
	else if (action == MenuAction_Cancel)
	{
		// Ignore
	}
}

//  This creates the kill stats options panel page 2
public DisplayMoreOptions(client)
{
	if ( killstats_info )
	{	
		LogMessage("DisplayMoreOptions");
	}

	decl String:translationBuffer[MAX_LINE_WIDTH];

	new Handle:panel = CreatePanel();
	
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLSTATS_OPTIONS,client);
	SetPanelTitle(panel, translationBuffer );
	
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",SHOW_RESULTS_IN_MENU,client);
	DrawPanelItem(panel, translationBuffer);

	Format(translationBuffer,MAX_LINE_WIDTH,"%T",SHOW_RESULTS_IN_CHAT,client);
	DrawPanelItem(panel, translationBuffer);

	SetPanelCurrentKey( panel, 8 );
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",PREVIOUS,client);
	DrawPanelItem(panel, translationBuffer);

	// Set for exit menu
	SetPanelCurrentKey( panel, 10 );

	Format(translationBuffer,MAX_LINE_WIDTH,"%T",EXIT,client);
	DrawPanelItem(panel, translationBuffer);
		
	SendPanelToClient(panel, client, PanelHandlerMoreOptions, GetConVarInt(cvarViewTime) );
 
	CloseHandle(panel);
}

public PanelHandlerKillStats(Handle:menu, MenuAction:action, param1, param2)
{
	if ( killstats_info )
	{	
		LogMessage("PanelHandlerKillStats");
	}
	
	// No matter what is selected, let it pass through so they exit the menu
}

// This displays the kill stats panel / chat
public Action:PanelKillStats(client, args)
{
	if ( killstats_info )
	{	
		LogMessage("PanelKillStats");
	}
	
	// Set to the beginning
	KSCurrentPanel[client]=0;
	
	DisplayPlayerRoundStats(client,GetConVarInt(cvarViewTime));
 
	return Plugin_Handled;
}

/****************************************************

				CHAT DISPLAY

*****************************************************/
public DisplayChatMessages(player, displayRound)
{
	if ( killstats_info )
	{	
		LogMessage("DisplayChatMessages");
	}
	
	decl String:displayOrder[MAX_DISPLAY_ITEMS+1];
	
	if ( IsPreferenceEnabled( player,STAT_PREF_SHOW_CHAT, cvarDefaultShowInChat ) )
	{
		GetConVarString(cvarChatDisplayOrder,displayOrder,MAX_DISPLAY_ITEMS+1);
		
		if ( StringToInt(displayOrder) == 0 )
		{
			LogMessage("Could not convert display order to numeric for menu.  Using default of 1234");
			displayOrder = "1234";
		}
		
		for ( new i=0 ; i<MAX_DISPLAY_ITEMS && displayOrder[i] > 0 ; i++ )
		{
			switch(displayOrder[i]-ASCII_ZERO)
			{
				case 1: // Kills
					if ( GetConVarBool( cvarDefaultChatShowKilled ) )
					{		
						for ( new msg=0 ; msg< PanelDisplayKillsIndex[displayRound][player] ; msg++ )
						{
							SafePrintToChat(player,PanelDisplayKills[displayRound][player][msg]);
						}
					}
					
				case 2: // Killed By
					if ( GetConVarBool( cvarDefaultChatShowKilledBy ) )
					{
						if ( PanelDisplayKilledByIndex[displayRound][player] > 0 )
						{
							SafePrintToChat(player, PanelDisplayKilledBy[displayRound][player][0]);
						}
					}
					
				case 3: // Damage Done
					if ( GetConVarBool( cvarDefaultChatShowDamageDone ) )
					{
						for ( new msg=0 ; msg< PanelDisplayDamageDoneIndex[displayRound][player] ; msg++ )
						{
							SafePrintToChat(player,PanelDisplayDamageDone[displayRound][player][msg]);
						}
					}
					
				case 4: // DamageTaken
					if ( GetConVarBool( cvarDefaultChatShowDamageTaken ) )
					{
						for ( new msg=0 ; msg< PanelDisplayDamageTakenIndex[displayRound][player] ; msg++ )
						{
							SafePrintToChat(player,PanelDisplayDamageTaken[displayRound][player][msg]);
						}
					}	
			}
		}
	}
}

/****************************************************

				MULTI PANEL DISPLAY

*****************************************************/
public any:GetCharsNeededForRequiredItems(player)
{
	if ( killstats_info )
	{	
		LogMessage("GetCharsNeededForRequiredItems");
	}
	
	new charsNeeded = 0;
	decl String:translationBuffer[MAX_LINE_WIDTH];

	// Get base items on every panel

	// Title
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLSTATS,player);
	charsNeeded += strlen(translationBuffer);

	// Exit
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",EXIT,player);
	charsNeeded += strlen(translationBuffer);
	
	// We're going to slightly overestimate here by always including next/previous even though
	// they are only both used in "middle" panels.  This greatly simplifies things though as
	// we don't know when we're on the last panel and it's only like 4 characters typically.

	// Next
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",NEXT,player);
	charsNeeded += strlen(translationBuffer);
	
	// Previous 
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",PREVIOUS,player);
	charsNeeded += strlen(translationBuffer);

	// Newlines, numbers, periods, spaces for the entire screen so we don't have to be meticuluous (conservative estimate)
	charsNeeded+=30;
		
	return charsNeeded;
}

public InitializePanelDisplayKillStats(player)
{
	if ( killstats_info )
	{	
		LogMessage("InitializePanelDisplayKillStats");
	}
	
	for ( new i=0 ; i<MAX_KILLSTATS_PANELS ; i++ )
	{
		// Set whether panels are continued from another panel (false should be the default)
		PanelDisplayKillStatsIsCont[player][i]=false;
		
		for ( new index ; index < MAX_DISPLAY_LINES ; index++ )
		{
			// Default to item 0
			PanelDisplayKillStatsHeader[player][i][index]=0;
			
			// Blank out killstats array for this player
			PanelDisplayKillStats[player][i][index][0]='\0';
		}
	}
}

public DrawMultiPanelKSDisplayWrapper(Handle:menu, MenuAction:action, param1, param2)
{
	if ( killstats_info )
	{	
		LogMessage("DrawMultiPanelKSDisplayWrapper");
	}
	
	if (action == MenuAction_Select)
	{
		// Prev
		if ( param2 == 8 )
		{
			KSCurrentPanel[param1]--;
			DrawMultiPanelKSDisplay(param1);
		}
		// Next
		else if ( param2 == 9 )
		{
			KSCurrentPanel[param1]++;
			DrawMultiPanelKSDisplay(param1);
		}
	}
	else if ( action == MenuAction_Cancel )
	{
		// Do nothing, done
	}
}

public DrawMultiPanelKSDisplay(player)
{
	if ( killstats_info )
	{	
		LogMessage("DrawMultiPanelKSDisplay");
	}
	
	decl String:translationBuffer[MAX_LINE_WIDTH];

	new Handle:panel = CreatePanel();

	// Title	
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",KILLSTATS,player);
	SetPanelTitle(panel, translationBuffer );

	new currentPanel=KSCurrentPanel[player];	
	for ( new index=0 ; index < MAX_DISPLAY_LINES ; index++ )
	{
		if ( PanelDisplayKillStatsHeader[player][currentPanel][index]==-1 )
		{
			break;
		}
		else
		{
			if ( PanelDisplayKillStatsHeader[player][currentPanel][index] > 0 )
			{
				if ( !GetConVarBool(cvarRestartNumbering) )
				{
					SetPanelCurrentKey( panel, PanelDisplayKillStatsHeader[player][currentPanel][index]);
				}
					
				if ( ( index == 0 ) && ( PanelDisplayKillStatsIsCont[player][currentPanel] ) )
				{
					DrawPanelText(panel,NEWLINE);
					Format(translationBuffer,MAX_LINE_WIDTH,"%T",MENU_CONTINUED,player,PanelDisplayKillStats[player][currentPanel][index]);
					DrawPanelItem( panel, translationBuffer );
				}
				else
				{
					DrawPanelText(panel,NEWLINE);
					DrawPanelItem(panel, PanelDisplayKillStats[player][currentPanel][index]);
				}
			}
			else
			{
				DrawPanelText(panel, PanelDisplayKillStats[player][currentPanel][index]);
			}
		}
	}
	
	DrawPanelText(panel,NEWLINE);
	
	// Previous 
	if ( currentPanel > 0 )
	{
		SetPanelCurrentKey( panel, 8 );
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",PREVIOUS,player);
		DrawPanelItem(panel, translationBuffer);
	}

	// Next
	
	// If this is not the last panel and the next panel has something in it
	if ( ( currentPanel + 1 < MAX_KILLSTATS_PANELS ) && ( PanelDisplayKillStatsHeader[player][currentPanel+1][0] > -1 ) ) 
	{
		SetPanelCurrentKey( panel, 9 );
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",NEXT,player);
		DrawPanelItem(panel, translationBuffer);
	}

	// Exit
	SetPanelCurrentKey( panel, 10 );	
	Format(translationBuffer,MAX_LINE_WIDTH,"%T",EXIT,player);
	DrawPanelItem(panel, translationBuffer);
		
	SendPanelToClient(panel, player, DrawMultiPanelKSDisplayWrapper, KSCurrentPanelDisplayTime[player] );
 
	CloseHandle(panel);
}

public any:PrintToArrayAndSplitString(
		String:PrintToArray[MAXPLAYERS+1][MAX_KILLSTATS_PANELS][MAX_DISPLAY_LINES][MAX_LINE_WIDTH],
		player,
		panel,
		index,
		maxWidth,
		String:stringToPrint[MAX_LINE_WIDTH] )
{
	if ( killstats_info )
	{	
		LogMessage("PrintToArrayAndSplitString");
	}
	
	decl String:currentString[MAX_LINE_WIDTH];
	decl String:buffer[MAX_LINE_WIDTH];
	new currentLength = 0;
	new charsToUse = 0;
	     
	// Get the whole string copied so we don't mess up the original!
	strcopy(currentString, sizeof(currentString), stringToPrint );

	while ( index < MAX_DISPLAY_LINES && ( currentLength = strlen( currentString ) ) > 0 )
	{
		// Use the max characters unless there is a space, hyphen, etc in the last 10 chars
		charsToUse = maxWidth;
		
		if ( killstats_debug ) 
		{
			LogMessage("CurrentString: %s; Length: %d", currentString, currentLength );
			LogMessage("Panel: %d; Index: %d", panel, index);
		}

		// If this is not going to fit on the line, try to break it up a little cleaner
		if ( currentLength > maxWidth )
		{		
			// look at the last 10 chars to find a better splitting point
			for ( new i=0 ; i<10 ; i++ )
			{
				if ( currentString[charsToUse-i] == ' ' || currentString[charsToUse-i] == '-' )
				{
					if ( killstats_debug )
					{
						LogMessage("Found: %s", currentString[charsToUse-i]);
					}

					charsToUse -= i;
					break;
				}
			}
		}
		
	    // Size is first "maxWidth" letters and null terminator
		Format(PrintToArray[player][panel][index++], charsToUse + 1, "%s", currentString );    

	    // Copy the rest into a new string
		if ( charsToUse > currentLength )
	    {
			if ( killstats_debug )
			{
				LogMessage("Using currentLength: %d instead of charsToUse: %d", currentLength, charsToUse );
			}
			strcopy(buffer, sizeof(buffer), currentString[currentLength]);
	    }
		else
	    {
			if ( killstats_debug )
			{
				LogMessage("Using charsToUse: %d instead of currentLength: %d", charsToUse, currentLength);
			}
			
			strcopy(buffer, sizeof(buffer), currentString[charsToUse]);
		}
	    
		TrimString(buffer);
		
		if ( strlen( buffer ) > 0 )
		{
			Format(currentString,sizeof(currentString),"    %s",buffer);
		}
		else
		{
			currentString=buffer;
		}
	}
	
	return index;
}

/**
* @param player - client id
* @param displayRound - current round that is being displayed (usually currentRound)
* @param menuItem - Actual number for menu (1/2/3/4)
* @param menuString - Menu Title - "Kills", "Killed By", etc.
* @param indexArray - PanelDisplayKillsIndex/etc
* @param stringArray - PanelDisplayKills, etc.
* @param currentPanelCharactersLeft
* @param currentKillStatsPanel
* @param currentKillStatsPanel
*
* @return	returnValues[0] = currentPanelCharactersLeft;
			returnValues[1] = currentKillStatsPanel;
			returnValues[2] = currentKillStatsPanelIndex;
*/
public any:GeneratePanelMenuItem( player, displayRound, menuItem, const String:menuString[], indexArray[ROUNDS_TO_STORE][MAXPLAYERS+1], 
	String:stringArray[][][][MAX_LINE_WIDTH], 
	currentPanelCharactersLeft, currentKillStatsPanel, currentKillStatsPanelIndex, returnValues[3] )
{
	if ( killstats_info )
	{	
		LogMessage("GeneratePanelMenuItem");
	}
	
	new bool:showEmptyMenus = GetConVarBool(cvarShowEmptyMenus);
	decl String:translationBuffer[MAX_LINE_WIDTH];
	new maxPanelWidth = GetConVarInt(cvarMaxPanelWidth);
	
	// Too Big
	if ( maxPanelWidth > MAX_LINE_WIDTH )
	{
		maxPanelWidth = MAX_LINE_WIDTH;
	}
	// Too Small
	else if ( maxPanelWidth < MIN_LINE_WIDTH )
	{
		maxPanelWidth = MIN_LINE_WIDTH;
	}

	if ( ( indexArray[displayRound][player] > 0 ) || showEmptyMenus )
	{
		Format(translationBuffer,MAX_LINE_WIDTH,"%T",menuString,player);

		// Make sure there's at least enough left for the title and one line or don't bother
		if ( ( currentPanelCharactersLeft < ( MAX_LINE_WIDTH + strlen(translationBuffer) )) || currentKillStatsPanelIndex >= MAX_DISPLAY_LINES )
		{
			if ( killstats_debug )
			{
				LogMessage("%s (1)Incrementing Panel from %d", menuString,currentKillStatsPanel);
			}
		
			// Set "eof" for array
			if ( currentKillStatsPanelIndex < MAX_DISPLAY_LINES )
			{	
				PanelDisplayKillStatsHeader[player][currentKillStatsPanel][currentKillStatsPanelIndex]=-1;
			}

			currentKillStatsPanel++;
			currentKillStatsPanelIndex = 0;
			currentPanelCharactersLeft=MAX_PANEL_CHARACTERS-GetCharsNeededForRequiredItems(player);
			
			if ( killstats_debug )
			{
				LogMessage("Panel CharactersLeft %d", currentPanelCharactersLeft);
			}
			
			// We're done, already displayed max panels.  GET OUT!
			if ( currentKillStatsPanel == MAX_KILLSTATS_PANELS )
			{
				returnValues[0] = currentPanelCharactersLeft;
				returnValues[1] = currentKillStatsPanel;
				returnValues[2] = currentKillStatsPanelIndex;
				return;
			}
		}
	
		// Menu Item
		PanelDisplayKillStats[player][currentKillStatsPanel][currentKillStatsPanelIndex]=translationBuffer;
		// Set menu item # (First displayed menu gets 1, second 2)
		PanelDisplayKillStatsHeader[player][currentKillStatsPanel][currentKillStatsPanelIndex]=menuItem+1;

		// for menu item					
		currentKillStatsPanelIndex++;
		currentPanelCharactersLeft -= strlen(translationBuffer);
		
		if ( killstats_debug )
	    {
			LogMessage("Panel CharactersLeft %d", currentPanelCharactersLeft);
		}

		if ( showEmptyMenus && ( indexArray[displayRound][player] == 0 ) )
		{
			Format(translationBuffer,MAX_LINE_WIDTH," %T",NONE,player);
			PanelDisplayKillStats[player][currentKillStatsPanel][currentKillStatsPanelIndex]=translationBuffer;
			currentPanelCharactersLeft-=(strlen(translationBuffer)+1);
			currentKillStatsPanelIndex++;
		}
		else
		{
			for ( new currentIndex = 0 ; currentIndex < indexArray[displayRound][player] ; currentIndex++, currentKillStatsPanelIndex++ )
			{
				if ( killstats_debug )
				{			
					LogMessage("Panel CharactersLeft %d; currentKillStatsPanelIndex %d", currentPanelCharactersLeft, currentKillStatsPanelIndex );
				}
				
				if ( ( currentPanelCharactersLeft < MAX_LINE_WIDTH ) || currentKillStatsPanelIndex >= MAX_DISPLAY_LINES )
				{
					// Be safe
					if ( currentKillStatsPanelIndex < MAX_DISPLAY_LINES )
					{
						// Show: (more)
						Format(translationBuffer,MAX_LINE_WIDTH,"  (%T)",MORE,player);
						PanelDisplayKillStats[player][currentKillStatsPanel][currentKillStatsPanelIndex++]=translationBuffer;
					}
				
					if ( currentKillStatsPanelIndex < MAX_DISPLAY_LINES )
					{
						// Set "eof" for array
						PanelDisplayKillStatsHeader[player][currentKillStatsPanel][currentKillStatsPanelIndex]=-1;
					}

					currentKillStatsPanel++;
					currentKillStatsPanelIndex = 0;
					currentPanelCharactersLeft=MAX_PANEL_CHARACTERS-GetCharsNeededForRequiredItems(player);
					
					// We're done, already displayed max panels.  GET OUT!
					if ( currentKillStatsPanel == MAX_KILLSTATS_PANELS )
					{
						returnValues[0] = currentPanelCharactersLeft;
						returnValues[1] = currentKillStatsPanel;
						returnValues[2] = currentKillStatsPanelIndex;
						return;
					}

					// Interrupted in the middle of display!
					PanelDisplayKillStatsIsCont[player][currentKillStatsPanel]=true;
					
					// Menu Item
					Format(translationBuffer,MAX_LINE_WIDTH,"%T",menuString,player);
					PanelDisplayKillStats[player][currentKillStatsPanel][currentKillStatsPanelIndex]=translationBuffer;
					// Set menu item # (First displayed menu gets 1, second 2)
					PanelDisplayKillStatsHeader[player][currentKillStatsPanel][currentKillStatsPanelIndex]=menuItem+1;
					currentKillStatsPanelIndex++;
				}

				currentKillStatsPanelIndex = PrintToArrayAndSplitString(
					PanelDisplayKillStats,
					player,
					currentKillStatsPanel,
					currentKillStatsPanelIndex,
					maxPanelWidth,
					stringArray[displayRound][player][currentIndex]);
				currentPanelCharactersLeft -= strlen(stringArray[displayRound][player][currentIndex]);
			}
		}
	}
	
	returnValues[0] = currentPanelCharactersLeft;
	returnValues[1] = currentKillStatsPanel;
	returnValues[2] = currentKillStatsPanelIndex;
}

public GeneratePanelRoundStats( player, displayRound )
{
	if ( killstats_info )
	{	
		LogMessage("GeneratePanelRoundStats");
	}
	
	decl String:displayOrder[MAX_DISPLAY_ITEMS+1];
	new currentKillStatsPanel = 0;
	new currentKillStatsPanelIndex = 0;
	decl returnValues[3];
	
	new currentPanelCharactersLeft=MAX_PANEL_CHARACTERS;
	
	if ( killstats_debug )
	{
		LogMessage("Panel CharactersLeft %d", currentPanelCharactersLeft);
	}
	
	currentPanelCharactersLeft -= GetCharsNeededForRequiredItems(player);
	
	if ( killstats_debug )
	{	
		LogMessage("Panel CharactersLeft %d", currentPanelCharactersLeft);
	}
						
	// Get Display Order
	GetConVarString(cvarMenuDisplayOrder,displayOrder,MAX_DISPLAY_ITEMS+1);
	
	if ( StringToInt(displayOrder) == 0 )
	{
		LogMessage("Could not convert display order to numeric for menu.  Using default of 1234");
		displayOrder = "1234";
	}

	// Zeroes/blanks out KillStats arrays
	InitializePanelDisplayKillStats(player);

	// Loop through the menus to displayed.  Once done, we are finished
	for ( new i=0 ; i<MAX_DISPLAY_ITEMS && displayOrder[i] > ASCII_ZERO ; i++ )
	{
		switch(displayOrder[i]-ASCII_ZERO)
		{
			case 1: // Kills
				if ( GetConVarBool( cvarDefaultMenuShowKilled ) && !GetConVarBool(cvarCombineDamage) )
				{
					// 	returnValues[0] = currentPanelCharactersLeft;
					//	returnValues[1] = currentKillStatsPanel;
					//	returnValues[2] = currentKillStatsPanelIndex;
					GeneratePanelMenuItem(
						player, 
						displayRound, 
						i,
						PLAYERS_KILLED, 
						PanelDisplayKillsIndex, 
						PanelDisplayKills, 
						currentPanelCharactersLeft, 
						currentKillStatsPanel, 
						currentKillStatsPanelIndex,
						returnValues );
					
					currentPanelCharactersLeft = returnValues[0];
					currentKillStatsPanel = returnValues[1];
					currentKillStatsPanelIndex = returnValues[2];
					
					if ( currentKillStatsPanel == MAX_KILLSTATS_PANELS )
					{
						return;
					}
				}
				
			case 2: // Killed By
				if ( GetConVarBool( cvarDefaultMenuShowKilledBy ) && !GetConVarBool(cvarCombineDamage) )
				{
					// 	returnValues[0] = currentPanelCharactersLeft;
					//	returnValues[1] = currentKillStatsPanel;
					//	returnValues[2] = currentKillStatsPanelIndex;
					GeneratePanelMenuItem(
						player, 
						displayRound, 
						i,
						KILLED_BY, 
						PanelDisplayKilledByIndex, 
						PanelDisplayKilledBy, 
						currentPanelCharactersLeft, 
						currentKillStatsPanel, 
						currentKillStatsPanelIndex,
						returnValues );
					
					currentPanelCharactersLeft = returnValues[0];
					currentKillStatsPanel = returnValues[1];
					currentKillStatsPanelIndex = returnValues[2];

					if ( currentKillStatsPanel == MAX_KILLSTATS_PANELS )
					{
						return;
					}
				}
				
			case 3: // Damage Done
				if ( GetConVarBool( cvarDefaultMenuShowDamageDone ) )
				{
					// 	returnValues[0] = currentPanelCharactersLeft;
					//	returnValues[1] = currentKillStatsPanel;
					//	returnValues[2] = currentKillStatsPanelIndex;
					GeneratePanelMenuItem(
						player, 
						displayRound, 
						i,
						DAMAGE_DONE, 
						PanelDisplayDamageDoneIndex, 
						PanelDisplayDamageDone, 
						currentPanelCharactersLeft, 
						currentKillStatsPanel, 
						currentKillStatsPanelIndex,
						returnValues );
					
					currentPanelCharactersLeft = returnValues[0];
					currentKillStatsPanel = returnValues[1];
					currentKillStatsPanelIndex = returnValues[2];

					if ( currentKillStatsPanel == MAX_KILLSTATS_PANELS )
					{
						return;
					}
				}
				
			case 4: // DamageTaken
				if ( GetConVarBool( cvarDefaultMenuShowDamageTaken ) )
				{
					// 	returnValues[0] = currentPanelCharactersLeft;
					//	returnValues[1] = currentKillStatsPanel;
					//	returnValues[2] = currentKillStatsPanelIndex;
					GeneratePanelMenuItem(
						player, 
						displayRound, 
						i,
						DAMAGE_TAKEN, 
						PanelDisplayDamageTakenIndex, 
						PanelDisplayDamageTaken, 
						currentPanelCharactersLeft, 
						currentKillStatsPanel, 
						currentKillStatsPanelIndex,
						returnValues );
					
					currentPanelCharactersLeft = returnValues[0];
					currentKillStatsPanel = returnValues[1];
					currentKillStatsPanelIndex = returnValues[2];

					if ( currentKillStatsPanel == MAX_KILLSTATS_PANELS )
					{
						return;
					}
				}	
		}
	}	

	// Set "eof" for array
	if ( currentKillStatsPanelIndex < MAX_DISPLAY_LINES )
	{	
		PanelDisplayKillStatsHeader[player][currentKillStatsPanel][currentKillStatsPanelIndex]=-1;
	}
	
	// Mark the Remaining Panels as Empty
	while ( currentKillStatsPanel < MAX_KILLSTATS_PANELS - 1 )
	{
		currentKillStatsPanel++;
		PanelDisplayKillStatsHeader[player][currentKillStatsPanel][0]=-1;
	}
}

/****************************************************

		SQL - Storing of Prefs (Stats eventually?)
		-- Thanks to Dalto/AMP

*****************************************************/
// Here we get a handle to the database and create it if it doesn't already exist
public InitializePrefsDatabase()
{
	if ( killstats_info )
	{	
		LogMessage("InitializePrefsDatabase");
	}
	
	new String:error[255];
	
	sqlConnection = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "killstats", error, sizeof(error));
	if(sqlConnection == INVALID_HANDLE)
		SetFailState(error);

	SQL_LockDatabase(sqlConnection);		
	// Create prefs table (if it doesn't already exist)
	SQL_FastQuery(sqlConnection, 
		"CREATE TABLE IF NOT EXISTS prefs (steam_id TEXT, enable_prefs INTEGER, show_menu INTEGER, show_chat INTEGER, timestamp INTEGER);");
			
	// Index
	SQL_FastQuery(sqlConnection, "CREATE UNIQUE INDEX IF NOT EXISTS prefs_steam_id on prefs(steam_id);");
	SQL_UnlockDatabase(sqlConnection);		
}
	
// Load the stats for a given client
public LoadPrefs(client)
{
	if ( killstats_info )
	{	
		LogMessage("LoadPrefs");
	}
	
	if( ( client < 0 ) || ( client > GetMaxClients() ) || ( IsFakeClient(client) ) )
		return;
		
	new String:steamId[20];
	GetSteamId(client, steamId, sizeof(steamId));

	decl String:buffer[200];
	Format(buffer, sizeof(buffer), "SELECT enable_prefs, show_menu, show_chat, timestamp FROM prefs WHERE steam_id = '%s'", steamId );
	SQL_TQuery(sqlConnection, LoadPrefsCallback, buffer, client);
}

// Load the stats for a given client
public LoadPrefsCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( killstats_info )
	{	
		LogMessage("LoadPrefsCallback");
	}
	
	if(!StrEqual("", error)) 
	{
		LogError("Load Prefs SQL Error: %s", error);
		return;
	}
	
	new client = data;
	if(SQL_FetchRow(hndl)) 
	{
		NewClient[client]=false;
		StatPreference[STAT_PREF_ENABLED][client]=SQL_FetchInt(hndl,0);
		StatPreference[STAT_PREF_SHOW_MENU][client]=SQL_FetchInt(hndl,1);
		StatPreference[STAT_PREF_SHOW_CHAT][client]=SQL_FetchInt(hndl,2);
	}
	else 
	{
		NewClient[client]=true;
		StatPreference[STAT_PREF_ENABLED][client]=PREF_UNSPECIFIED;
		StatPreference[STAT_PREF_SHOW_MENU][client]=PREF_UNSPECIFIED;
		StatPreference[STAT_PREF_SHOW_CHAT][client]=PREF_UNSPECIFIED;
	}
}
		
// Updates the database for a single client
public SavePrefs(client)
{
	if ( killstats_info )
	{	
		LogMessage("SafePrefs");
	}
	
	new String:steamId[20];
	new String:buffer[255];
	
	if(IsClientInGame(client) && !IsFakeClient(client) ) 
	{
		GetSteamId(client, steamId, sizeof(steamId));

		new Handle:updatePack = CreateDataPack();
		WritePackString(updatePack, steamId);
		WritePackCell(updatePack, StatPreference[STAT_PREF_ENABLED][client]);
		WritePackCell(updatePack, StatPreference[STAT_PREF_SHOW_MENU][client]);
		WritePackCell(updatePack, StatPreference[STAT_PREF_SHOW_CHAT][client]);
		
		// This is just to check whether the row exists
		Format(buffer, sizeof(buffer), "SELECT enable_prefs, show_menu, show_chat FROM prefs WHERE steam_id = '%s'", steamId);
		SQL_TQuery(sqlConnection, SavePrefsCallback, buffer, updatePack);
	}
}

public SavePrefsCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( killstats_info )
	{	
		LogMessage("SavePrefsCallback");
	}
	
	if(!StrEqual("", error)) 
	{
		LogError("Save Prefs SQL Error: %s", error);
		return;
	}
	
	decl String:buffer[255];

	// Explode the datapack in data
	decl String:steamId[20];
	ResetPack(data);
	ReadPackString(data, steamId, sizeof(steamId));
	
	new enabled = ReadPackCell(data);
	new showMenu = ReadPackCell(data);
	new showChat = ReadPackCell(data);
	CloseHandle(data);
	
	if(SQL_FetchRow(hndl))
	{
		Format(
			buffer, 
			sizeof(buffer), 
			"UPDATE prefs SET enable_prefs = %i, show_menu = %i, show_chat = %i, timestamp = %i where steam_id = '%s'", 
			enabled, 
			showMenu, 
			showChat, 
			GetTime(), 
			steamId);
	}
	else
	{
		Format(
			buffer, 
			sizeof(buffer), 
			"INSERT INTO prefs VALUES ('%s', %i, %i, %i, %i)", 
			steamId, 
			enabled, 
			showMenu, 
			showChat, 
			GetTime());
	}
	
	SQL_TQuery(sqlConnection, SQLErrorCheckCallback, buffer);
}

// This is used during a threaded query that does not return data
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if ( killstats_info )
	{	
		LogMessage("SQLErrorCheckCallback");
	}
	
	if(!StrEqual("", error))
	{
		PrintToServer("Kill Stats SQl Error: %s", error);
	}
}

public GetSteamId(client, String:buffer[], bufferSize)
{
	if ( killstats_info )
	{	
		LogMessage("GetSteamId");
	}

	if( client && !IsFakeClient(client))
	{
		GetClientAuthString(client, buffer, bufferSize);
	}
}
