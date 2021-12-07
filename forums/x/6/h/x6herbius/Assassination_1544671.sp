// Third re-write of the Assassination plugin.
// Anything that still needs doing is marked with #TODO#.

/*	Recent changes:
- Removed nfas_sprite_alpha ConVar
- Relocated all sprite management to OnGameFrame; hopefully this should be more robust now.
- Fixed the round always ending in a stalemate.
- Fixed the buffed conditions flashing occasionally.
- Modified the "too few players" chat notification slightly.
- Added an admin command to allow the assassin or target to be changed by an admin.	
- Edited the code that handles when players join and leave teams to be more robust.*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <keyvalues>
#define DEBUG	0
#define UNSTABLE	1

/* FCVAR_ values for my own reference:

FCVAR_PROTECTED - Sensitive information (should not be exposed to clients or logs).
FCVAR_NOTIFY - Clients are notified of changes.
FCVAR_CHEAT - Can only be use if sv_cheats is 1.
FCVAR_REPLICATED - Setting is forced to clients.
FCVAR_PLUGIN - Custom plugin ConVar (should be used by default). */

// Plugin defines
#define PLUGIN_NAME			"Nightfire: Assassination"
#define PLUGIN_AUTHOR		"[X6] Herbius"
#define PLUGIN_DESCRIPTION	"Team deathmatch; become the assassin to gain points."
#define PLUGIN_VERSION		"0.1.1.43"	// Note: I don't update this religiously on builds. :P There have been AT LEAST this many builds.
#define PLUGIN_URL			"forums.alliedmods.net/showthread.php?p=1531506#post1531506"

// Team integers
#define TEAM_INVALID		-1
#define TEAM_UNASSIGNED		0
#define TEAM_SPECTATOR		1
#define TEAM_RED			2
#define TEAM_BLUE			3

// Flags for possible states.
// Higher flags take priority over lower flags.
// These are used to control which functionality should be active.
// If no flags are active, the plugin is running normally.
// Flags can also be checked with inequalities.
#define STATE_NO_ACTIVITY				16	// Plugin has been loaded on an active server, don't do anything until a map change.
#define STATE_DISABLED					8	// Plugin is disabled via ConVar.
#define STATE_NOT_ENOUGH_PLAYERS		4	// One team has below two players.
#define STATE_PLAYERS_ROUND_RESTARTING	2	// The player count is above the threshold but the round hasn't restarted yet.
#define STATE_NOT_IN_ROUND				1	// Not currently in a round.

/*	Flag usage
* STATE_NO_ACTIVITY: Set on plugin start, if IsServerProcessing returns true. This means that if the plugin is loaded
* 	while a match is taking place, it will not activate. This flag is only (and always) reset OnMapStart, meaning that the
* 	plugin will begin functioning after a map change. If the plugin is loaded as the server starts, IsServerProcessing will
* 	return false and the flag will not be set. This flag prevents any plugin hooks at all from running.
* STATE_DISABLED: Set when the ConVar nfas_enabled is set to 0, and cleared when it is set to 1. This flag will also
* 	prevent any plugin hooks from running, apart from CvarChange.
* STATE_NOT_ENOUGH_PLAYERS: Set when either team drops below 2 players, and cleared when both teams are above 2 players.
* 	If this flag is set, it means there are not enough players for the assassination game mode to function and so core plugin
* 	hooks such as RoundStart, RoundWin, PlayerDeathPlayerDeath, PlayerHurt etc. will not run. Hooks dealing with player numbers, however,
* 	such as OnClientConnect, TeamChange, OnClientDisconnect, etc. will continue to function and monitor the player count to
* 	clear the flag when enough players join.
* STATE_PLAYERS_ROUND_RESTARTING: Set when STATE_NOT_ENOUGH_PLAYERS has just been cleared and the round hasn't yet restarted.
* 	This flag is cleared on RoundStart. It prohibits all of the actions that STATE_NOT_ENOUGH_PLAYERS does apart from RoundStart.
* STATE_NOT_IN_ROUND: Set on RoundWin and MapEnd (just in case) and cleared on RoundStart. If this flag is set, the assassin
* 	and target indices will be clamped to 0, assassin and target sprites will not be re-assigned (and should be hidden on
* 	RoundWin), the assassin's buffed condition will not refresh, the target's hurt modifier will not function and score will
* 	not be added.	*/

#define SPRITE_OFFSET		32

// Building type flags:
#define BUILDING_SENTRY		1
#define BUILDING_DISPENSER	2
#define BUILDING_TELEPORTER	4

// Cleanup modes
#define CLEANUP_ROUNDSTART	0
#define CLEANUP_ROUNDWIN	1
#define CLEANUP_MAPSTART	2
#define CLEANUP_MAPEND		3

#define SND_ASSASSIN_KILLED					"assassination/assassin_killed.mp3"					// Sound when the assassin is killed by a player.
#define SND_PATH_ASSASSIN_KILLED			"sound/assassination/assassin_killed.mp3"
#define SND_ASSASSIN_KILLED_BY_TARGET		"assassination/assassin_killed_by_target.mp3"		// Sound when the assassin is killed by the target.
#define SND_PATH_ASSASSIN_KILLED_BY_TARGET	"sound/assassination/assassin_killed_by_target.mp3"
#define SND_ASSASSIN_SCORE					"assassination/assassin_score.mp3"					// Sound when the assassin kills the target.
#define SND_PATH_ASSASSIN_SCORE				"sound/assassination/assassin_score.mp3"
#define SND_TARGET_KILLED					"assassination/target_killed.mp3"					// Sound when the assassin kills the target.
#define SND_PATH_TARGET_KILLED				"sound/assassination/target_killed.mp3"

#define ASSASSIN_SPRITE_PATH	"materials/assassination/assassin_sprite"	// Path to the assassin sprite (excluding extension).
#define TARGET_SPRITE_PATH		"materials/assassination/target_sprite"		// Path to the target sprite (excluding extension).
#define ASSASSIN_SPRITE_Z_PATH	"materials/assassination/assassin_sprite_z"	// Path to the assassin sprite (excluding extension), ignoring Z-buffer.
#define TARGET_SPRITE_Z_PATH	"materials/assassination/target_sprite_z"	// Path to the target sprite (excluding extension), ignoring Z-buffer.
#define PLAYER_THRESHOLD		2											// The must be at least this number of players on a team for the plugin to activate.

// Responses
/*#define RESPONSE_FALL_TO_DEATH				"assassination/assassin_fall_to_death.mp3"			// "I'd give that dive a three, actually."
#define RESPONSE_PATH_FALL_TO_DEATH			"sound/assassination/assassin_fall_to_death.mp3"
#define RESPONSE_ASSASSIN_STREAK1			"assassination/assassin_score_streak1.mp3"			// "I've seen this before..."
#define RESPONSE_PATH_ASSASSIN_STREAK1		"sound/assassination/assassin_score_streak1.mp3"
#define RESPONSE_ASSASSIN_STREAK2			"assassination/assassin_score_streak2.mp3"			// "You can take your offer to hell."
#define RESPONSE_PATH_ASSASSIN_STREAK2		"sound/assassination/assassin_score_streak2.mp3"
#define RESPONSE_ASSASSIN_STREAK3			"assassination/assassin_score_streak3.mp3"			// "Try rising from -those- ashes."
#define RESPONSE_PATH_ASSASSIN_STREAK3		"sound/assassination/assassin_score_streak3.mp3"*/

// Variable declarations
new g_PluginState;				// Holds the plugin state flags.
//new bool:b_TeamBelowMin = true;	// If this flag is set, one team has less than two players.
new gVelocityOffset;			// Offset at which to find the client's velocity vector.
#if UNSTABLE == 1
new bool:b_SwitchPlayerType;	// For the switch admin function. False = assassin, true = target.
#endif

// ConVar handle declarations
new Handle:cv_PluginEnabled = INVALID_HANDLE;			// Enables or disables the plugin. Changing this while in-game will restart the map.
new Handle:cv_TargetLOS = INVALID_HANDLE;				// If possible, the new target will be chosen by prioritising players who have line-of-sight to the current assassin.
new Handle:cv_TargetTakeDamage = INVALID_HANDLE;		// If the target is hurt by an ordinary player, they will only take this fraction of the damage (between 0.1 and 1).
new Handle:cv_AssassinTakeDamage = INVALID_HANDLE;		// When the assassin is hurt, the damage they take will be multiplied by this value.
new Handle:cv_ColourTarget = INVALID_HANDLE;			// If 1, the target player will be tinted with their team's colour.
new Handle:cv_NoZSprites = INVALID_HANDLE;				// If 1, the assassin and target sprites will always be visible over world geometry.
new Handle:cv_SpawnProtection = INVALID_HANDLE;			// How long, in seconds, a player is protected from damage after they spawn.
new Handle:cv_KillAssassin = INVALID_HANDLE;			// The base amount of points the target gets for killing the assassin.
new Handle:cv_KillTarget = INVALID_HANDLE;				// The base amount of points the assassin gets for killing the target.
new Handle:cv_TargetKillPenalty = INVALID_HANDLE;		// If the target is killed by a player who is not the assassin, this amount of points will be taken from the killer's team.
new Handle:cv_MaxScore = INVALID_HANDLE;				// When this score is reached, the round will end.
new Handle:cv_HeadshotMultiplier = INVALID_HANDLE;		// Score multiplier for headshots. Applied on top of the weapon modifier.
new Handle:cv_BackstabMultiplier = INVALID_HANDLE;		// Score multiplier for backstabs. Applied on top of the weapon modifier.
new Handle:cv_ReflectMultiplier = INVALID_HANDLE;		// Score multiplier for reflected projectiles. Applied on top of the weapon modifier.
new Handle:cv_SentryL1Multiplier = INVALID_HANDLE;		// Score multiplier for level 1 sentries.
new Handle:cv_SentryL2Multiplier = INVALID_HANDLE;		// Score multiplier for level 2 sentries.
new Handle:cv_SentryL3Multiplier = INVALID_HANDLE;		// Score multiplier for level 3 sentries.
new Handle:cv_TelefragMultiplier = INVALID_HANDLE;		// Score multiplier for telefrags.

// Other handles
new Handle:timer_AssassinCondition = INVALID_HANDLE;	// Handle to our timer that refreshes the buffed state on the assassin.
new Handle:hs_Assassin = INVALID_HANDLE;				// Handle to our HUD synchroniser for displaying who is the assassin.
new Handle:hs_Target = INVALID_HANDLE;					// Handle to our HUD synchroniser for displaying who is the target.
new Handle:hs_Score = INVALID_HANDLE;					// Handle to our HUD synchroniser for displaying scores.
new Handle:hs_ScorePopup = INVALID_HANDLE;				// Handle to our HUD synchroniser for displaying the amount of score a player gains each time they kill someone.
new Handle:timer_HUDMessageRefresh = INVALID_HANDLE;	// Handle to our HUD refresh timer.
new Handle:timer_HUDScoreRefresh = INVALID_HANDLE;		// Handle to our HUD score refresh timer.
new Handle:timer_MedicHealBuff = INVALID_HANDLE;		// Handle to our timer to refresh the buffed state on assassin Medics' heal targets.

public Plugin:myinfo = 
{
	// This section should take care of itself nicely now.
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

public OnPluginStart()
{
	LogMessage("--++==Assassination Mode started. Version: %s==++--", PLUGIN_VERSION);	
	LoadTranslations("assassination/assassination_phrases");
	AutoExecConfig(true, "assassination", "sourcemod/assassination");
	
	// ConVar declarations.
	// Prefixed with "nfas" (Nightfire Assassination) to make them more unique.
	CreateConVar("nfas_version", PLUGIN_VERSION, "Plugin version.", FCVAR_PLUGIN | FCVAR_NOTIFY);
	
	cv_PluginEnabled  = CreateConVar("nfas_enabled",
												"1",
												"Enables or disables the plugin. Changing this while in-game will restart the map.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_TargetLOS  = CreateConVar("nfas_target_los_priority",
												"0",
												"If possible, the new target will be chosen by prioritising players who have line-of-sight to the current assassin.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_TargetTakeDamage  = CreateConVar("nfas_target_damage_modifier",
												"0.5",
												"If the target is hurt by an ordinary player, they will only take this fraction of the damage (between 0.1 and 1).",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.1,
												true,
												1.0);
	
	cv_AssassinTakeDamage  = CreateConVar("nfas_assassin_damage_modifier",
												"1.0",
												"When the assassin is hurt, the damage they take will be multiplied by this value. Minimum 1.0",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												1.0);
	
	cv_ColourTarget  = CreateConVar("nfas_target_colour",
												"0",
												"If 1, the target player will be tinted with their team's colour.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_NoZSprites  = CreateConVar("nfas_sprites_always_visible",
												"0",
												"If 1, the assassin and target sprites will always be visible over world geometry.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_SpawnProtection  = CreateConVar("nfas_spawn_protection_length",
												"3.0",
												"How long, in seconds, a player is protected from damage after they spawn.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												10.0);
	
	cv_KillTarget  = CreateConVar("nfas_kill_target_score",
												"10",
												"The base amount of points the assassin gets for killing the target.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_TargetKillPenalty  = CreateConVar("nfas_target_kill_penalty",
												"0",
												"If the target is killed by a player who is not the assassin, this amount of points will be taken from the killer's team.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_KillAssassin  = CreateConVar("nfas_kill_assassin_score",
												"7",
												"The base amount of points the target gets for killing the assassin.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_HeadshotMultiplier  = CreateConVar("nfas_headshot_multiplier",
												"2.0",
												"Score multiplier for headshots. Applied on top of the weapon modifier.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_BackstabMultiplier  = CreateConVar("nfas_backstab_multiplier",
												"3.0",
												"Score multiplier for backstabs. Applied on top of the weapon modifier.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_ReflectMultiplier  = CreateConVar("nfas_reflect_multiplier",
												"2.0",
												"Score multiplier for reflected projectiles. Applied on top of the weapon modifier.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_SentryL1Multiplier  = CreateConVar("nfas_sentry_level1_multiplier",
												"2.0",
												"Score multiplier for level 1 sentries.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_SentryL2Multiplier  = CreateConVar("nfas_sentry_level2_multiplier",
												"1.0",
												"Score multiplier for level 2 sentries.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_SentryL3Multiplier  = CreateConVar("nfas_sentry_level3_multiplier",
												"0.5",
												"Score multiplier for level 3 sentries.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_TelefragMultiplier  = CreateConVar("nfas_telefrag_multiplier",
												"4.0",
												"Score multiplier for telefrags.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_MaxScore  = CreateConVar("nfas_score_max",
												"100",
												"When this score is reached, the round will end.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												1.0);

	// Hooks:
	HookConVarChange(cv_PluginEnabled,	CvarChange);
	HookEventEx("teamplay_round_start",		Event_RoundStart,	EventHookMode_Post);
	HookEventEx("teamplay_round_win",		Event_RoundWin,		EventHookMode_Post);
	HookEventEx("player_team",				Event_TeamsChange,	EventHookMode_Post);
	HookEventEx("player_death",				Event_PlayerDeath,	EventHookMode_Post);
	HookEventEx("player_hurt",				Event_PlayerHurt,	EventHookMode_Post);
	HookEventEx("player_spawn",				Event_PlayerSpawn,	EventHookMode_Post);
	
	RegConsoleCmd("say", Command_Say);
	
	// Admin commands:
	#if UNSTABLE == 1
	RegAdminCmd("nfas_switch",		AdminCommand_Switch, ADMFLAG_CONVARS, "Allows the assassin or target player to be changed.");
	#endif
	
	// Debug commands:
	#if DEBUG == 1
	RegConsoleCmd("nfas_showflags",		DebugCommand_ShowFlags,		"Displays the plugin state flags in the chat.");
	RegConsoleCmd("nfas_checkindices",	DebugCommand_CheckIndices,	"Displays the assassin and target indices in the chat.");
	RegConsoleCmd("nfas_hudtext",		DebugCommand_HUDText,		"Displays some text at the specified position.");
	#endif
	
	gVelocityOffset = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	// Parse the weapon modifiers file
	WeaponModifiers(false);
	
	// --Plugin State--
	// If the server is currently processing (ie. the plugin's just been loaded while a round is going on), set the state flag.
	// This flag will override ALL other flags and no plugin functionality will occur until a new map is loaded.
	if ( IsServerProcessing() )
	{
		g_PluginState |= STATE_NO_ACTIVITY;
		LogMessage("[AS] Assassination plugin loaded while round is active. Plugin will be activated on map change.");
		PrintToChatAll("[AS] %t", "as_pluginloadnextmapchange");
		
		return;
	}
}

/* ==================== \/ Begin Event Hooks \/ ====================
* NOTE: In order to make the main code as modular as possible (to allow for the different state flags to correctly control
* which functions should and should not be called), these hooks activate on game events and, depending on the conditions
* of the event, call different functions. Most of the bog-standard admin is done in these functions which reside in the
* "Custom Event Functions" section towards the bottom of the file. Not only does this keep the main code cleaner (the
* player_death event was getting rather too cluttered for me to manage in the previous version of this file), it means that
* the same groups of commands can be easily re-used and called from different places in the code.
* The only thing we do have to be careful of is that the custom functions don't accidentally re-enter other functions.	*/

public OnMapStart()
{
	// --Plugin State--
	// Clear the NO_ACTIVITY flag.
	g_PluginState &= ~STATE_NO_ACTIVITY;
	
	// ***Map Start Resets***
	Cleanup(CLEANUP_MAPSTART);
	// ***End Map Start Resets***
	
	if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return;
	
	// Files to download:
	AddFileToDownloadsTable(SND_PATH_ASSASSIN_KILLED);
	AddFileToDownloadsTable(SND_PATH_ASSASSIN_KILLED_BY_TARGET);
	AddFileToDownloadsTable(SND_PATH_ASSASSIN_SCORE);
	AddFileToDownloadsTable(SND_TARGET_KILLED);
	
	// Precache:
	PrecacheSound(SND_ASSASSIN_KILLED, true);
	PrecacheSound(SND_ASSASSIN_KILLED_BY_TARGET, true);
	PrecacheSound(SND_ASSASSIN_SCORE, true);
	PrecacheSound(SND_TARGET_KILLED, true);
	
	// Precache sprites by adding extensions
	decl String:spriteprecache[128];
	
	Format( spriteprecache, sizeof(spriteprecache), "%s.vmt", ASSASSIN_SPRITE_PATH);
	AddFileToDownloadsTable(spriteprecache);
	PrecacheGeneric(spriteprecache, true);
	
	Format( spriteprecache, sizeof(spriteprecache), "%s.vtf", ASSASSIN_SPRITE_PATH);
	AddFileToDownloadsTable(spriteprecache);
	PrecacheGeneric(spriteprecache, true);
	
	Format( spriteprecache, sizeof(spriteprecache), "%s.vmt", TARGET_SPRITE_PATH);
	AddFileToDownloadsTable(spriteprecache);
	PrecacheGeneric(spriteprecache, true);
	
	Format( spriteprecache, sizeof(spriteprecache), "%s.vtf", TARGET_SPRITE_PATH);
	AddFileToDownloadsTable(spriteprecache);
	PrecacheGeneric(spriteprecache, true);
	
	// Z sprites
	Format( spriteprecache, sizeof(spriteprecache), "%s.vmt", ASSASSIN_SPRITE_Z_PATH);
	AddFileToDownloadsTable(spriteprecache);
	PrecacheGeneric(spriteprecache, true);
	
	Format( spriteprecache, sizeof(spriteprecache), "%s.vtf", ASSASSIN_SPRITE_Z_PATH);
	AddFileToDownloadsTable(spriteprecache);
	PrecacheGeneric(spriteprecache, true);
	
	Format( spriteprecache, sizeof(spriteprecache), "%s.vmt", TARGET_SPRITE_Z_PATH);
	AddFileToDownloadsTable(spriteprecache);
	PrecacheGeneric(spriteprecache, true);
	
	Format( spriteprecache, sizeof(spriteprecache), "%s.vtf", TARGET_SPRITE_Z_PATH);
	AddFileToDownloadsTable(spriteprecache);
	PrecacheGeneric(spriteprecache, true);
	
	g_PluginState |= STATE_NOT_IN_ROUND;	// Set the NOT_IN_ROUND flag.
	
	if ( GetTeamClientCount(TEAM_RED) < PLAYER_THRESHOLD || GetTeamClientCount(TEAM_BLUE) < PLAYER_THRESHOLD )
	{
		g_PluginState |= STATE_NOT_ENOUGH_PLAYERS;
		//b_TeamBelowMin = true;
	}
	
	// When the map starts, we create a timer that automatically updates once a second.
	// This will redraw the HUD mesages (which each last for a second).
	hs_Assassin = CreateHudSynchronizer();
	hs_Target = CreateHudSynchronizer();
	hs_Score = CreateHudSynchronizer();
	hs_ScorePopup = CreateHudSynchronizer();
	
	if ( hs_Assassin != INVALID_HANDLE && hs_Target != INVALID_HANDLE )	// If the above was successful:
	{
		UpdateHUDMessages(GlobalIndex(false, 0), GlobalIndex(false, 1));	// Update the HUD
		timer_HUDMessageRefresh = CreateTimer(1.0, TimerHUDRefresh, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	// Set up the timer to next update the HUD.
	}
	
	if ( hs_Score != INVALID_HANDLE )	// If the above was successful:
	{
		UpdateHUDScore(TeamScore(false, true, TEAM_RED), TeamScore(false, true, TEAM_BLUE), TeamScore(false, false, TEAM_RED), TeamScore(false, false, TEAM_BLUE));	// Update the HUD
		timer_HUDScoreRefresh = CreateTimer(1.0, TimerHUDScoreRefresh, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	// Set up the timer to next update the HUD.
	}
	
	timer_MedicHealBuff = CreateTimer(0.25, TimerMedicHealBuff, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	// Set up the timer to refresh Medic heal buffs.
}

/*	Called when the map finishes.	*/
public OnMapEnd()
{
	g_PluginState |= STATE_NOT_IN_ROUND;	// Set the NOT_IN_ROUND flag.
	if ( (g_PluginState & STATE_NO_ACTIVITY) == STATE_NO_ACTIVITY ) return;
	
	//***Map End Cleanup***
	Cleanup(CLEANUP_MAPEND);
	//*** End Map End Cleanup***
	
	//if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return;
	
	//if ( (g_PluginState & STATE_NOT_ENOUGH_PLAYERS) == STATE_NOT_ENOUGH_PLAYERS || (g_PluginState & STATE_PLAYERS_ROUND_RESTARTING) == STATE_PLAYERS_ROUND_RESTARTING ) return;
}


/*	Checks which ConVar has changed and does the relevant things.	*/
public CvarChange( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	// If the enabled/disabled convar has changed, run PluginStateChanged
	if ( convar == cv_PluginEnabled ) PluginEnabledStateChanged(GetConVarBool(cv_PluginEnabled));
}

/*	Called when a new round begins.	*/
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	#if DEBUG == 1
	PrintToChatAll("RoundStart is running code...");
	#endif
	if ( (g_PluginState & STATE_NO_ACTIVITY) == STATE_NO_ACTIVITY ) return;
	
	g_PluginState &= ~STATE_NOT_IN_ROUND;				// Clear the NOT_IN_ROUND flag.
	g_PluginState &= ~STATE_PLAYERS_ROUND_RESTARTING;	// Clear the ROUND_RESTARTING flag.
	
	//***Round Start Cleanup***
	Cleanup(CLEANUP_ROUNDSTART);
	//***End Round Start Cleanup***
	
	// ==Start doing spawn edit things here==
	// #TODO#
	
	if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return;
	
	if ( (g_PluginState & STATE_NOT_ENOUGH_PLAYERS) == STATE_NOT_ENOUGH_PLAYERS )
	{
		PrintToChatAll("[AS] %t", "as_notenoughplayers");
		LogMessage ("[AS] Not enough players. (Red: %d, Blue: %d.)", GetTeamClientCount(TEAM_RED), GetTeamClientCount(TEAM_BLUE));
		return;
	}
	
	// Assign assassin and target indices, ignoring LoS because it's the start of a round.
	#if DEBUG == 1
	PrintToChatAll("RoundStart is assigning new assassin and target.");
	#endif
	GlobalIndex(true, 0, RandomPlayerFromTeam(TEAM_RED));
	GlobalIndex(true, 1, RandomPlayerFromTeam(TEAM_BLUE));
}

/*	Called when a round ends.	*/
public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( (g_PluginState & STATE_NO_ACTIVITY) == STATE_NO_ACTIVITY ) return;
	
	g_PluginState |= STATE_NOT_IN_ROUND;	// Set the NOT_IN_ROUND flag.
	
	//***Round Win Cleanup***
	Cleanup(CLEANUP_ROUNDWIN);
	//***End Round Win Cleanup***
	
	if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return;
	
	TeamScore(true, true, TEAM_RED, (TeamScore(false, true, TEAM_RED) + TeamScore(false, false, TEAM_RED)));
	TeamScore(true, true, TEAM_BLUE, (TeamScore(false, true, TEAM_BLUE) + TeamScore(false, false, TEAM_BLUE)));
	// This is fine here since Cleanup(CLEANUP_ROUNDWIN) doesn't reset the normal team score counters (done instead in Cleanup(CLEANUP_ROUNDSTART)).
	
	if ( (g_PluginState & STATE_NOT_ENOUGH_PLAYERS) == STATE_NOT_ENOUGH_PLAYERS || (g_PluginState & STATE_PLAYERS_ROUND_RESTARTING) == STATE_PLAYERS_ROUND_RESTARTING ) return;
	
	// Display total scores to clients via a panel
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientConnected(i) )
		{
			Panel_Scores(i, 0);
		}
	}
}

/*	Called when a player changes team.
	Note that this handles ALL the logic concerning players who are the assassin/target joining or leaving
	the game. If a player joins the game, they will not be chosen as the assassin unless they are on the Red
	or Blue team (in which case they would have to pass through this function); if a player leaves the game and
	is the assassin or target, this event will be fired and the player will be caught, re-assigning the assassin
	or target index to a new player.*/
public Event_TeamsChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( (g_PluginState & STATE_NO_ACTIVITY) == STATE_NO_ACTIVITY ) return;
	
	// This was the only place CheckMinTeams was called from, so I'm going to just code it in here instead of having it as
	// a function. It would make sense, since CheckMinTeams couldn't be called from any other event because of the specific
	// conditions it dealt with.
	
	new tc_ClientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	new tc_NewTeamID = GetEventInt(event, "team");
	new tc_OldTeamID = GetEventInt(event, "oldteam");
	
	new tc_RedTeamCount = GetTeamClientCount(TEAM_RED);
	new tc_BlueTeamCount = GetTeamClientCount(TEAM_BLUE);
	new tc_RedTeamCountPre = tc_RedTeamCount;
	new tc_BlueTeamCountPre = tc_BlueTeamCount;
	
	// Since TeamsChange always acts like a pre-event (ie. if we call GetTeamClientCount here, it will return the number of
	// players on the team as if the client who's changing hasn't changed yet), we'll need to rebuild the team information
	// to predict what the teams will look like after the change.
	
	if ( GetEventBool(event, "disconnect") ) 	// If the team change happened because the client was disconnecting:
	{
		// If disconnected, this means the team he was on will lose a player and the other teams will stay the same.
		switch (tc_OldTeamID)	// Find out which team the client left.
		{
			case TEAM_RED:
			{
				tc_RedTeamCount--;	// Decrement our counter for the team.
			}
			
			case TEAM_BLUE:
			{
				tc_BlueTeamCount--;	// Decrement our counter for the team.
			}
			
			// If the old team was spectator, we're not counting spec players so don't do anything.
		}
	}
	else	// If the client hasn't disconnected, this means they're changing teams.
	{
		// The client's old team will lose a player and their new team will gain a player.
		switch (tc_OldTeamID)
		{
			case TEAM_RED:
			{
				tc_RedTeamCount--;	// Decrement the old team's counter.
			}
			
			case TEAM_BLUE:
			{
				tc_BlueTeamCount--;	// Decrement the old team's counter.
			}
			
			// If the old team was spectator, we're not counting spec players so don't do anything.
		}
		
		switch (tc_NewTeamID)
		{
			case TEAM_RED:
			{
				tc_RedTeamCount++;	// Increment the new team's counter.
			}
			
			case TEAM_BLUE:
			{
				tc_BlueTeamCount++;	// Increment the new team's counter.
			}
			
			// If the new team is spectator, we're not counting spec players so don't do anything.
		}
	}
	
	// By this point, the correct team values for AFTER the client's switch has occurred (what we want) will be held in
	// n_redteamcounter and n_blueteamcounter. We can check these values against our thresholds.
	
	if ( tc_RedTeamCountPre < PLAYER_THRESHOLD || tc_BlueTeamCountPre < PLAYER_THRESHOLD )	// If a team was below the threshold:
	{
		if ( tc_RedTeamCount >= PLAYER_THRESHOLD && tc_BlueTeamCount >= PLAYER_THRESHOLD )	// But now both are above:
		{
			//b_TeamBelowMin = false;	// Let us know both teams are in the clear.
			g_PluginState &= ~STATE_NOT_ENOUGH_PLAYERS;				// Clear the NOT_ENOUGH_PLAYERS flag.
			
			PrintToChatAll("[AS] %t", "as_playersriseabovethreshold");	// Let us know.
			if ( (g_PluginState & STATE_PLAYERS_ROUND_RESTARTING) != STATE_PLAYERS_ROUND_RESTARTING )
			{
				ServerCommand("mp_restartround 3");	// Restart the round if we're not restarting already.
				g_PluginState |= STATE_PLAYERS_ROUND_RESTARTING;
			}
		}
		else	// One or both teams are still under.
		{
			//b_TeamBelowMin = true;
			g_PluginState |= STATE_NOT_ENOUGH_PLAYERS;
			GlobalIndex(true, 0, 0);
			GlobalIndex(true, 1, 0);
		}
	}
	else if ( tc_RedTeamCountPre >= PLAYER_THRESHOLD && tc_BlueTeamCountPre >= PLAYER_THRESHOLD )	// If no team was below the threshold:
	{
		if ( tc_RedTeamCount < PLAYER_THRESHOLD || tc_BlueTeamCount < PLAYER_THRESHOLD )	// But one now is:
		{
			//b_TeamBelowMin = true;	// Let us know not all teams are in the clear.
			g_PluginState |= STATE_NOT_ENOUGH_PLAYERS;			
			PrintToChatAll("[AS] %t", "as_playersdropbelowthreshold");	// Let us know.
			GlobalIndex(true, 0, 0);	// Reset assassin index immediately.
			GlobalIndex(true, 1, 0);	// Reset target index immediately.
			
			if ( (g_PluginState & STATE_PLAYERS_ROUND_RESTARTING) != STATE_PLAYERS_ROUND_RESTARTING )
			{
				ServerCommand("mp_restartround 3");	// Restart the round if we're not restarting already.
				g_PluginState |= STATE_PLAYERS_ROUND_RESTARTING;
			}
		}
		else g_PluginState &= ~STATE_NOT_ENOUGH_PLAYERS;	// Clear the NOT_ENOUGH_PLAYERS flag.
	}
	
	// If we're here it means the plugin is enabled and there are enough players to assign new assassins/targets.
	// If the assassin or target is changing team, re-assign the index regardless of whether they are disconnecting
	// or not (since it doesn't matter).
	// No points should be awarded when the index is changed here, but sounds should be played.

	if ( (g_PluginState & STATE_PLAYERS_ROUND_RESTARTING) != STATE_PLAYERS_ROUND_RESTARTING && (g_PluginState & STATE_NOT_ENOUGH_PLAYERS) != STATE_NOT_ENOUGH_PLAYERS )
	{
		if ( tc_ClientIndex == GlobalIndex(false, 0) )	// If client's index == assassin index:
		{
			GlobalIndex(true, 0, RandomPlayerFromTeam(tc_OldTeamID, tc_ClientIndex));	// Choose a random player from the old team, ignoring the changing player.
			EmitSoundToAll(SND_ASSASSIN_KILLED, _, SNDCHAN_STATIC, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, GlobalIndex(false, 0), _, NULL_VECTOR, false, 0.0);	// Play assassin killed
		}
		else if ( tc_ClientIndex == GlobalIndex(false, 1) )	// If client's index == target index:
		{
			GlobalIndex(true, 1, RandomPlayerFromTeam(tc_OldTeamID, tc_ClientIndex));	// Choose a random player from the old team, ignoring the changing player.
			EmitSoundToAll(SND_TARGET_KILLED, _, SNDCHAN_STATIC, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, GlobalIndex(false, 1), _, NULL_VECTOR, false, 0.0);	// Play target killed
		}
	}
}

/*	Called when a client has finished disconnecting.	*/
public OnClientDisconnect_Post(client)
{
	// BUGFIX: A bit of a hack-around here, but I'm having problems with the assassin or target player disconnecting and it not being handled properly.
	// After the player has disconnected, we will perform a check to see if either of the assassin or target is assigned to a player slot
	// which is disconnected. If either is and there are enough players to continue, re-assign the indices.
	
	if ( GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients && !IsClientConnected(GlobalIndex(false, 0)) )
	{
		// If there are abnormal states, reset the assassin index to 0.
		if ( g_PluginState > 0 )
		{
			GlobalIndex(true, 0, 0);
		}
		else
		{
			// If the target is invalid too, choose the assassin from the Red team.
			if ( GlobalIndex(false, 1) > 0 && GlobalIndex(false, 1) <= MaxClients && !IsClientConnected(GlobalIndex(false, 1)) )
			{
				GlobalIndex(true, 0, RandomPlayerFromTeam(TEAM_RED));
			}
			
			// If the target is valid, set the assassin to the opposite team.
			else if ( GlobalIndex(false, 1) > 0 && GlobalIndex(false, 1) <= MaxClients && IsClientConnected(GlobalIndex(false, 1)) )
			{
				new targetteam = GetClientTeam(GlobalIndex(false, 1));
				
				switch (targetteam)
				{
					case TEAM_RED:
					{
						GlobalIndex(true, 0, RandomPlayerFromTeam(TEAM_BLUE));
					}
					
					case TEAM_BLUE:
					{
						GlobalIndex(true, 0, RandomPlayerFromTeam(TEAM_RED));
					}
				}
			}
		}
	}
	
	if ( GlobalIndex(false, 1) > 0 && GlobalIndex(false, 1) <= MaxClients && !IsClientConnected(GlobalIndex(false, 1)) )
	{
		// If there are abnormal states, reset the target index to 0.
		if ( g_PluginState > 0 )
		{
			GlobalIndex(true, 1, 0);
		}
		else
		{
			// If the assassin is invalid too, choose the target from the Blue team.
			if ( GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients && !IsClientConnected(GlobalIndex(false, 0)) )
			{
				GlobalIndex(true, 1, RandomPlayerFromTeam(TEAM_BLUE));
			}
			
			// If the assassin is valid, set the target to the opposite team.
			else if ( GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients && IsClientConnected(GlobalIndex(false, 0)) )
			{
				new assassinteam = GetClientTeam(GlobalIndex(false, 0));
				
				switch (assassinteam)
				{
					case TEAM_RED:
					{
						GlobalIndex(true, 1, RandomPlayerFromTeam(TEAM_BLUE));
					}
					
					case TEAM_BLUE:
					{
						GlobalIndex(true, 1, RandomPlayerFromTeam(TEAM_RED));
					}
				}
			}
		}
	}
}

/*	Called when a player is hurt.	*/
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_PluginState >= STATE_DISABLED ) return;
	
	if ( (g_PluginState & STATE_NOT_ENOUGH_PLAYERS) == STATE_NOT_ENOUGH_PLAYERS ) return;
	
	new ph_ClientIndex = GetClientOfUserId(GetEventInt(event, "userid"));		// Index of the client who was hurt.
	new ph_AttackerIndex = GetClientOfUserId(GetEventInt(event, "attacker"));	// Index of the client who fired the shot.
	new ph_ClientHealth = GetEventInt(event, "health");							// How much health the injured player now has.
	new ph_ClientDamage = GetEventInt(event, "damageamount");					// The amount of damage the injured player took.
	
	// The target was hit by someone who wasn't the assassin.
	// If the damage taken was from an ordinary player, and it didn't kill them, give the target back half of the damage done
	// (rounded down).
	if ( ph_ClientIndex == GlobalIndex(false, 1) && ph_ClientIndex > 0 && ph_ClientIndex <= MaxClients && IsClientConnected(ph_ClientIndex) && !TF2_IsPlayerInCondition(ph_ClientIndex, TFCond_Overhealed)
			&& ph_AttackerIndex > 0 && ph_AttackerIndex <= MaxClients && ph_AttackerIndex != GlobalIndex(false, 0) && ph_ClientHealth > 0  )
	{
		new Float:f_healthtoset = float(ph_ClientHealth) + (float(ph_ClientDamage) * (1.0 - GetConVarFloat(cv_TargetTakeDamage)));
		SetEntProp(ph_ClientIndex, Prop_Data, "m_iHealth", RoundToFloor(f_healthtoset));
		
		// Immediately mark the health value as changed.
		ChangeEdictState(ph_ClientIndex, GetEntSendPropOffs(ph_ClientIndex, "m_iHealth"));
	}
	
	// The assassin was hit by someone.
	// Take away an extra fraction of the damage dealt.
	if ( ph_ClientIndex == GlobalIndex(false, 0) && ph_ClientIndex > 0 && ph_ClientIndex <= MaxClients && IsClientConnected(ph_ClientIndex) && ph_ClientHealth > 0 )
	{
		if ( GetConVarFloat(cv_AssassinTakeDamage) > 1.0 )
		{
			new Float:f_healthtoset = float(ph_ClientHealth) - ((GetConVarFloat(cv_AssassinTakeDamage) - 1.0) * ph_ClientDamage);
			SetEntProp(ph_ClientIndex, Prop_Data, "m_iHealth", RoundToFloor(f_healthtoset));
			
			// Immediately mark the health value as changed.
			ChangeEdictState(ph_ClientIndex, GetEntSendPropOffs(ph_ClientIndex, "m_iHealth"));
		}
	}
}

/*	Called when a player spawns.	*/
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_PluginState >= STATE_DISABLED ) return;
	
	new ps_ClientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	
	// Set up spawn protection.
	// Until/unless I can come up with a better solution, the player will have an Ubercharge applied.
	if ( GetConVarFloat(cv_SpawnProtection) > 0.0 )
	{
		TF2_AddCondition(ps_ClientIndex, TFCond_Ubercharged, GetConVarFloat(cv_SpawnProtection));
	}
	
	if ( (g_PluginState & STATE_NOT_ENOUGH_PLAYERS) == STATE_NOT_ENOUGH_PLAYERS || (g_PluginState & STATE_PLAYERS_ROUND_RESTARTING) == STATE_PLAYERS_ROUND_RESTARTING ) return;
}

/*	Called when a player dies.	*/
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If there are ANY abnormal states, don't go through all the crap below.
	if ( g_PluginState > 0 ) return;
	
	// Since the player death event was getting exceedingly complicated in the last version of this file, I've made a few
	// changes: depdnding on which conditions are met, different user-defined events will be called.
	// These events will handle everything to do with changing global indices, playing sounds, adding score, etc.
	
	new pd_ClientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	new pd_AttackerIndex = -1;
	new pd_AssisterIndex = -1;
	new pd_InflictorIndex = GetEventInt(event, "inflictor_entindex");
	new pd_DamageBits = GetEventInt(event, "damagebits");
	new pd_CustomKill = GetEventInt(event, "customkill");
	new pd_DeathFlags = GetEventInt(event, "death_flags");
	new pd_WeaponID = GetEventInt(event, "weaponid");
	
	if ( GetEventInt(event, "attacker") >= 1 ) pd_AttackerIndex = GetClientOfUserId(GetEventInt(event, "attacker"));
	if ( GetEventInt(event, "assister") >= 1 ) pd_AssisterIndex = GetClientOfUserId(GetEventInt(event, "assister"));
	
	//***Assassin has died***
	if ( GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients && pd_ClientIndex == GlobalIndex(false, 0) /*&& IsClientConnected(pd_ClientIndex)*/ )
	{
		// If the attacker was the target:
		if ( pd_AttackerIndex > 0 && pd_AttackerIndex <= MaxClients && pd_AttackerIndex == GlobalIndex(false, 1) /*&& IsClientConnected(pd_AttackerIndex)*/ )
		{
			// Call AssassinKilledByTarget
			UsrEvent_AssassinKilledByTarget(pd_ClientIndex, pd_AttackerIndex, pd_AssisterIndex, ItemDefinitionIndex(pd_InflictorIndex, pd_WeaponID), pd_DamageBits, pd_CustomKill, pd_DeathFlags, pd_InflictorIndex);
		}
		// If the attacker was an enemy player but not the target or the assassin:
		else if ( pd_AttackerIndex > 0 && pd_AttackerIndex <= MaxClients && pd_AttackerIndex != GlobalIndex(false, 1) && pd_AttackerIndex != GlobalIndex(false, 0) && GetClientTeam(pd_ClientIndex) != GetClientTeam(pd_AttackerIndex) /*&& IsClientConnected(pd_AttackerIndex)*/ )
		{
			// Call AssassinKilled
			UsrEvent_AssassinKilled(pd_ClientIndex, pd_AttackerIndex, pd_AssisterIndex, ItemDefinitionIndex(pd_InflictorIndex, pd_WeaponID), pd_DamageBits, pd_CustomKill, pd_DeathFlags, pd_InflictorIndex);
		}
		// If the attacker wasn't a player, or it was suicide, or a team kill:
		else if ( pd_AttackerIndex == pd_ClientIndex || GetClientTeam(pd_AttackerIndex) == GetClientTeam(pd_ClientIndex) || pd_AttackerIndex <= 0 || pd_AttackerIndex > MaxClients )
		{
			// Call AssassinDied
			UsrEvent_AssassinDied(pd_ClientIndex, pd_AttackerIndex, pd_AssisterIndex, ItemDefinitionIndex(pd_InflictorIndex, pd_WeaponID), pd_DamageBits, pd_CustomKill, pd_DeathFlags, pd_InflictorIndex);
		}
	}
	//***Target has died***
	else if ( GlobalIndex(false, 1) > 0 && GlobalIndex(false, 1) <= MaxClients && pd_ClientIndex == GlobalIndex(false, 1) /*&& IsClientConnected(pd_ClientIndex)*/ )
	{
		// If the attacker was the assassin:
		if ( pd_AttackerIndex > 0 && pd_AttackerIndex <= MaxClients && pd_AttackerIndex == GlobalIndex(false, 0) /*&& IsClientConnected(pd_AttackerIndex)*/ )
		{
			// Call TargetKilledByAssassin
			UsrEvent_TargetKilledByAssassin(pd_ClientIndex, pd_AttackerIndex, pd_AssisterIndex, ItemDefinitionIndex(pd_InflictorIndex, pd_WeaponID), pd_DamageBits, pd_CustomKill, pd_DeathFlags, pd_InflictorIndex);
		}
		// Or If the assister was the assassin and a Medic:
		else if ( pd_AssisterIndex > 0 && pd_AssisterIndex <= MaxClients && pd_AssisterIndex == GlobalIndex(false, 0) && TF2_GetPlayerClass(pd_AssisterIndex) == TFClass_Medic /*&& IsClientConnected(pd_AssisterIndex)*/ )
		{
			// Call TargetKilledByAssassin
			UsrEvent_TargetKilledByAssassin(pd_ClientIndex, pd_AttackerIndex, pd_AssisterIndex, ItemDefinitionIndex(pd_InflictorIndex, pd_WeaponID), pd_DamageBits, pd_CustomKill, pd_DeathFlags, pd_InflictorIndex);
		}
		// If the attacker was an enemy player but not the assassin or the target:
		else if ( pd_AttackerIndex > 0 && pd_AttackerIndex <= MaxClients && pd_AttackerIndex != GlobalIndex(false, 0) && pd_AttackerIndex != GlobalIndex(false, 1) && GetClientTeam(pd_ClientIndex) != GetClientTeam(pd_AttackerIndex) /*&& IsClientConnected(pd_AttackerIndex)*/ )
		{
			// Call TargetKilled
			UsrEvent_TargetKilled(pd_ClientIndex, pd_AttackerIndex, pd_AssisterIndex, ItemDefinitionIndex(pd_InflictorIndex, pd_WeaponID), pd_DamageBits, pd_CustomKill, pd_DeathFlags, pd_InflictorIndex);
		}
		// If the attacker wasn't a player, or it was suicide, or a team kill:
		else if ( pd_AttackerIndex == pd_ClientIndex || GetClientTeam(pd_AttackerIndex) == GetClientTeam(pd_ClientIndex) || pd_AttackerIndex <= 0 || pd_AttackerIndex > MaxClients )
		{
			// Call TargetDied
			UsrEvent_TargetDied(pd_ClientIndex, pd_AttackerIndex, pd_AssisterIndex, ItemDefinitionIndex(pd_InflictorIndex, pd_WeaponID), pd_DamageBits, pd_CustomKill, pd_DeathFlags, pd_InflictorIndex);
		}
	}
	//***Other player has died***
	else if ( pd_ClientIndex != GlobalIndex(false, 0) && pd_ClientIndex != GlobalIndex(false, 1) && pd_ClientIndex > 0 && pd_ClientIndex <= MaxClients /*&& IsClientConnected(pd_ClientIndex)*/ )
	{
		if ( pd_AttackerIndex > 0 && pd_AttackerIndex <= MaxClients && GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients /*&& IsClientConnected(pd_AttackerIndex)*/ )
		{
			if ( GetClientTeam(pd_AttackerIndex) == GetClientTeam(GlobalIndex(false, 0)) )
			{
				// Call AssassinTeamKillPlayer
				UsrEvent_AssassinTeamKillPlayer(pd_ClientIndex, pd_AttackerIndex, pd_AssisterIndex, ItemDefinitionIndex(pd_InflictorIndex, pd_WeaponID), pd_DamageBits, pd_CustomKill, pd_DeathFlags, pd_InflictorIndex);
			}
		}
	}
	
	// Double-check whether the assassin and the target are on the same team.
	// They shouldn't be, but if they are then swap the team of the target.
	if ( GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients && GlobalIndex(false, 1) > 0 && GlobalIndex(false, 1) <= MaxClients && IsClientConnected(GlobalIndex(false, 0)) && IsClientConnected(GlobalIndex(false, 1)) && GetClientTeam(GlobalIndex(false, 0)) == GetClientTeam(GlobalIndex(false, 1)) )
	{
		switch (GetClientTeam(GlobalIndex(false, 1)))
		{
			case TEAM_RED:
			{
				if ( GetConVarBool(cv_TargetLOS) )
				{
					new assassin = GlobalIndex(false, 0);
					GlobalIndex(true, 1, RandomPlayerFromTeam(TEAM_BLUE, _, assassin));
				}
				else GlobalIndex(true, 1, RandomPlayerFromTeam(TEAM_BLUE));
			}
			
			case TEAM_BLUE:
			{
				if ( GetConVarBool(cv_TargetLOS) )
				{
					new assassin = GlobalIndex(false, 0);
					GlobalIndex(true, 1, RandomPlayerFromTeam(TEAM_RED, _, assassin));
				}
				else GlobalIndex(true, 1, RandomPlayerFromTeam(TEAM_RED));
			}
		}
	}
	
	if ( TF2_GetPlayerClass(pd_ClientIndex) == TFClass_Engineer )	// If the player who died was an Engineer, kill their sentry.
	{
		KillBuildings(pd_ClientIndex, BUILDING_SENTRY);
	}
	
	// Check to see if the round needs to be won:
	CheckScoresAgainstMax();
	
}

/*	Called on every frame.	*/
public OnGameFrame()
{
	// Sprites will now be managed entirely from OnGameFrame.
	
	// Index 0 is the sprite index, index 1 is the player it's assigned to.
	static AssassinSprite[2] = {-1, -1};
	static TargetSprite[2] = {-1,-1};
	
	// Firstly, deal with when we want to have sprites enabled.
	if ( g_PluginState < STATE_DISABLED )
	{
		// We should be drawing sprites. Let's deal with the assassin first.
		// Firstly, check to see if the sprite exists.
		if ( AssassinSprite[0] > MaxClients && IsValidEntity(AssassinSprite[0]) )
		{
			// The sprite exists. If the assassin isn't valid, or if the assassin is different to the assigned player, kill the sprite.
			if ( GlobalIndex(false, 0) < 1 || GlobalIndex(false, 0) > MaxClients || !IsClientConnected(GlobalIndex(false, 0)) || !IsPlayerAlive(GlobalIndex(false, 0)) || AssassinSprite[1] != GlobalIndex(false, 0) )
			{
				#if DEBUG == 1
				LogMessage("Killing assassin sprite...");
				#endif
				
				AcceptEntityInput(AssassinSprite[0], "HideSprite");
				AcceptEntityInput(AssassinSprite[0], "Kill");
				AssassinSprite[0] = -1;
				AssassinSprite[1] = -1;
			}
			// If the assassin is valid and the same as the assigned player, handle movement.
			else if ( GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients && IsClientInGame(GlobalIndex(false, 0)) && IsPlayerAlive(GlobalIndex(false, 0)) && AssassinSprite[1] == GlobalIndex(false, 0) )
			{
				new Float:v_asOrigin[3], Float:v_asVelocity[3];
			
				GetClientEyePosition(GlobalIndex(false, 0), v_asOrigin);
				v_asOrigin[2] += SPRITE_OFFSET;
				GetEntDataVector(GlobalIndex(false, 0), gVelocityOffset, v_asVelocity);
				TeleportEntity(AssassinSprite[0], v_asOrigin, NULL_VECTOR, v_asVelocity);
			}
		}
		else if ( AssassinSprite[0] < 0 )
		{
			// The sprite doesn't exist. If the assassin is valid, create it.
			if ( GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients && IsClientInGame(GlobalIndex(false, 0)) && IsPlayerAlive(GlobalIndex(false, 0)) )
			{
				#if DEBUG == 1
				LogMessage("Creating assassin sprite...");
				#endif
				
				AssassinSprite[0] = CreateSprite(GlobalIndex(false, 0), false);
				
				if ( AssassinSprite[0] > MaxClients )
				{
					// The sprite is completely set up apart from parenting it to the client.
					// Deal with this here:
					
					// Name the client for parenting purposes.
					// Here we use a UserID since these are much more likely to be unique than a client index.
					new String:s_ClientTargetname[64]; 
					Format(s_ClientTargetname, sizeof(s_ClientTargetname), "client%i", GetClientUserId(GlobalIndex(false, 0)));
					DispatchKeyValue(GlobalIndex(false, 0), "targetname", s_ClientTargetname);
					
					new Float:v_ClientOrigin[3];
					GetClientAbsOrigin(GlobalIndex(false, 0), v_ClientOrigin);
					v_ClientOrigin[2] += SPRITE_OFFSET;	// Set our Z (vertical) offset.
					
					DispatchKeyValue(AssassinSprite[0], "parentname", s_ClientTargetname);
					DispatchSpawn(AssassinSprite[0]);
					TeleportEntity(AssassinSprite[0], v_ClientOrigin, NULL_VECTOR, NULL_VECTOR);	// Place our sprite at the player.
					AssassinSprite[1] = GlobalIndex(false, 0);	// Record the player we're assigned to.
				}
			}
			
			// If the assassin isn't valid, don't create the sprite.
		}
		
		// Now deal with the target.
		// Firstly, check to see if the sprite exists.
		if ( TargetSprite[0] > MaxClients && IsValidEntity(TargetSprite[0]) )
		{
			// The sprite exists. If the target isn't valid, or if the target is different to the assigned player, kill the sprite.
			if ( GlobalIndex(false, 1) < 1 || GlobalIndex(false, 1) > MaxClients || !IsClientConnected(GlobalIndex(false, 1)) || !IsPlayerAlive(GlobalIndex(false, 1)) || TargetSprite[1] != GlobalIndex(false, 1) )
			{
				#if DEBUG == 1
				LogMessage("Killing target sprite...");
				#endif
				
				AcceptEntityInput(TargetSprite[0], "HideSprite");
				AcceptEntityInput(TargetSprite[0], "Kill");
				TargetSprite[0] = -1;
				TargetSprite[1] = -1;
			}
			// If the target is valid and the same as the assigned player, handle movement.
			else if ( GlobalIndex(false, 1) > 0 && GlobalIndex(false, 1) <= MaxClients && IsClientInGame(GlobalIndex(false, 1)) && IsPlayerAlive(GlobalIndex(false, 1)) && TargetSprite[1] == GlobalIndex(false, 1) )
			{
				new Float:v_trOrigin[3], Float:v_trVelocity[3];
			
				GetClientEyePosition(GlobalIndex(false, 1), v_trOrigin);
				v_trOrigin[2] += SPRITE_OFFSET;
				GetEntDataVector(GlobalIndex(false, 1), gVelocityOffset, v_trVelocity);
				TeleportEntity(TargetSprite[0], v_trOrigin, NULL_VECTOR, v_trVelocity);
			}
		}
		else if ( TargetSprite[0] < 0 )
		{
			// The sprite doesn't exist. If the target is valid, create it.
			if ( GlobalIndex(false, 1) > 0 && GlobalIndex(false, 1) <= MaxClients && IsClientInGame(GlobalIndex(false, 1)) && IsPlayerAlive(GlobalIndex(false, 1)) )
			{
				#if DEBUG == 1
				LogMessage("Creating target sprite...");
				#endif
				
				TargetSprite[0] = CreateSprite(GlobalIndex(false, 1), true);
				
				if ( TargetSprite[0] > MaxClients )
				{
					// The sprite is completely set up apart from parenting it to the client.
					// Deal with this here:
					
					// Name the client for parenting purposes.
					// Here we use a UserID since these are much more likely to be unique than a client index.
					new String:s_ClientTargetname[64]; 
					Format(s_ClientTargetname, sizeof(s_ClientTargetname), "client%i", GetClientUserId(GlobalIndex(false, 1)));
					DispatchKeyValue(GlobalIndex(false, 1), "targetname", s_ClientTargetname);
					
					new Float:v_ClientOrigin[3];
					GetClientAbsOrigin(GlobalIndex(false, 1), v_ClientOrigin);
					v_ClientOrigin[2] += SPRITE_OFFSET;	// Set our Z (vertical) offset.
					
					DispatchKeyValue(TargetSprite[0], "parentname", s_ClientTargetname);
					DispatchSpawn(TargetSprite[0]);
					TeleportEntity(TargetSprite[0], v_ClientOrigin, NULL_VECTOR, NULL_VECTOR);	// Place our sprite at the player.
					TargetSprite[1] = GlobalIndex(false, 1);	// Record the player we're assigned to.
				}
			}
			
			// If the target isn't valid, don't create the sprite.
		}
	}
	// Now we don't want to have sprites, so if they exist, kill them.
	else
	{
		if ( AssassinSprite[0] > MaxClients && IsValidEntity(AssassinSprite[0]) )
		{
			AcceptEntityInput(AssassinSprite[0], "HideSprite");
			AcceptEntityInput(AssassinSprite[0], "Kill");
			AssassinSprite[0] = -1;
			AssassinSprite[1] = -1;
		}
		
		if ( TargetSprite[0] > MaxClients && IsValidEntity(TargetSprite[0]) )
		{
			AcceptEntityInput(TargetSprite[0], "HideSprite");
			AcceptEntityInput(TargetSprite[0], "Kill");
			TargetSprite[0] = -1;
			TargetSprite[1] = -1;
		}
	}
}

/* ==================== /\ End Event Hooks /\ ==================== */

/* ==================== \/ Begin Custom Functions \/ ==================== */

/*	Sets the enabled/disabled state of the plugin and restarts the map.
	Passing true enables, false disables.	*/
stock PluginEnabledStateChanged(bool:b_state)
{
	if ( b_state )
	{
		g_PluginState &= ~STATE_DISABLED;	// Clear the disabled flag.
	}
	else
	{
		g_PluginState |= STATE_DISABLED;	// Set the disabled flag.
	}
	
	// If we're not active, the next time we become active will be when the map changes anyway, so we can leave this.
	if ( (g_PluginState & STATE_NO_ACTIVITY) == STATE_NO_ACTIVITY ) return;
	
	// Get the current map name
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	
	LogMessage("[AS] Plugin state changed. Restarting map (%s)...", mapname);
	
	// Restart the map
	ServerCommand( "changelevel %s", mapname);
}

/*	Chooses a random player from the specified team.
	If a second argument is specified, exclude the player with this index.
	If the third argument is non-zero, the function will try to return a random player who have line of sight to
	the player of this index. If there are none, it will return a random player as normal.
	Returns the client index of the player, or 0 if not found. */
stock RandomPlayerFromTeam(team, exclude = 0, los_index = 0)
{
	// The first thing we need to do is iterate through all indices between 1 and MAX_CLIENTS inclusive.
	// Each time we come across a player, put their client index in an array. At the end, note down the
	// number of players we found.
	// Choose a random client index from the ones we collected and return that value.
	// If the total number of players we found was 0, or the team was invalid, return 0.
	
	if ( team < 0 ) return 0;	// Make sure our team input value is valid.
	
	new playersfound[MaxClients];
	new n_playersfound = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		
		if ( IsClientConnected(i) && i != exclude )	// If the client we've chosen is in the game and not excluded:
		{
			if ( GetClientTeam(i) == team /*&& !IsFakeClient(i)*/ )	// If they're on the right team:
			{
				playersfound[n_playersfound] = i;	// Put our client index (i) into the array.
				n_playersfound++;					// Increment our "players found" count and loop back.
			}
		}
	}
	
	if ( n_playersfound < 1 ) return 0;	// If we didn't find any players, return 0.
	
	// By this point we will have the number of players found stored in n_playersfound, and their indices in playersfound[].
	// The max index will be found at (n_playersfound - 1).
	// The minimum number of players found will be 1.
	
	// First, do our stuff but don't return yet. If we do LOS checks later and come up blank, this value will be returned instead.
	
	// Return a random index from the array, less than or equal to the number of players we found. -1 to allow for the 0 array index.
	new n = GetRandomInt(0, n_playersfound-1);
	
	#if DEBUG == 1
	decl String:clientname[MAX_NAME_LENGTH + 1];
	clientname[0] = '\0';
	GetClientName(playersfound[n], clientname, sizeof(clientname));
	LogMessage("RPFT: Players found: %d Index chosen: %d in array, %d (%s)", n_playersfound, n, playersfound[n], clientname);
	#endif
	
	if ( los_index < 1 || los_index > MaxClients || !IsClientConnected(los_index) )	// If the LOS index is invalid:
	{		
		return playersfound[n];
	}
	
	// Now we want to iterate through each of the players in our found index and check to see if they have line of sight to
	// the player of the index specified in los_index.
	// We know that if we have got this far the player in los_index definitely exists, so we don't need to do more checks.
	// The process below will never add los_index to the array, since we don't trace to ourself.
	
	// I'd like to note that this method is crude in that it checks for a traceline from the queried player to the specified
	// player via checking to see whether the line between their two eye positions is blocked. This may disallow the choosing
	// of a player even if they can see the rest of the body of the target player.
	
	new los_playersfound[n_playersfound];	// Array to hold the indices of who we find
	new n_los_playersfound;					// The number of people we found
	new Float:eyepos_los_index[3];
	new Float:eyepos_los_i[3];
	GetClientEyePosition(los_index, eyepos_los_index);
	
	for ( new los_i = 0; los_i < n_playersfound; los_i++ )	// Starts at 0 instead of 1 since we're now going through an array
	{
		// First, make sure we're not tracing to ourself.
		if ( los_i != los_index )
		{		
			// Run a traceline measuring from the eye position of the player at los_i to the eye position of the player at los_index.
			GetClientEyePosition(los_i, eyepos_los_i);
			
			TR_TraceRayFilter(eyepos_los_i,				/*Start at the eyepos of the current queried player*/
								eyepos_los_index,		/*End at the eyepos of the specified player*/
								MASK_VISIBLE,			/*Anything that blocks player LOS*/
								RayType_EndPoint,		/*The ray goes between two points*/
								TraceRayDontHitSelf,	/*Function to make sure we don't hit ourself*/
								los_i);					/*The index of ourself to pass to the function*/
			
			// Now, work out if anything blocked the trace.
			// Only add the queried player to the array if nothing was hit.
			if ( !TR_DidHit(INVALID_HANDLE) )	// If there was nothing hit:
			{
				los_playersfound[n_los_playersfound] = los_i;	// Add the client index to the array.
				n_los_playersfound++;							// Increment our "players found" count and loop back.
			}
		}
	}
	
	// By now we will have a new array of players. If we didn't find anyone, return a random index from the players we found back
	// in the first loop.
	
	if ( n_los_playersfound >= 1 )	// If we found people:
	{
		// Return a random index from the array, less than or equal to the number of players we found. -1 to allow for the 0 array index.
		new los_n = GetRandomInt(0, n_los_playersfound-1);
		
		#if DEBUG == 1
		decl String:los_clientname[MAX_NAME_LENGTH + 1];
		los_clientname[0] = '\0';
		GetClientName(los_playersfound[los_n], los_clientname, sizeof(los_clientname));
		LogMessage("RPFT (LOS): Players found: %d Index chosen: %d in array, %d (%s)", n_los_playersfound, los_n, los_playersfound[los_n], los_clientname);
		#endif
		
		return playersfound[los_n];
	}
	else	// If we found no-one:
	{
		return playersfound[n];
	}
}

/*	Trace function to exclude tracelines from hitting the player they emerge from.	*/
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
 	if(entity == data) // Check if the TraceRay hit the player.
 	{
 		return false; // Don't let the entity be hit.
 	}
 
 	return true; // It didn't hit itself.
}

/*	Called every time the assassin/target index is changed or read.
	Passing write as true changes the index and returns the value; false reads the index and returns the value.
	Passing 0 as the id accesses the assassin index, 1 accesses the target index.
	If writing, the value argument is the value the specified index should be changed to.	
	Note that if write = true, UsrEvent_IndexModified is called and is given the id of the changed index and its new value.	*/
stock GlobalIndex(bool:write = false, id, value = 0)
{
	static GlobalIndices[2];	// Array index 0 is the assassin, 1 is the target.
	
	if ( id > 1 ) id = 1;	// Clamp the ID value.
	if (id < 0 ) id = 0;
	
	if ( write )	// If we're changing the index:
	{
		// Notify us if the index is being assigned a non-zero value when abnormal states are present.
		if ( g_PluginState > 0 && value > 0 )
		{
			LogMessage("WARNING: GlobalIndex being written to with value %d when plugin state is %d. This is probably not correct.", value, g_PluginState);
		}
		
		if ( id == 0 )	// If the index is 0 (assassin):
		{
			// Clear the buff condition on the previous assassin, if there was one.
			if ( GlobalIndices[0] > 0 && GlobalIndices[0] <= MaxClients && IsClientConnected(GlobalIndices[0]) )
			{
				TF2_RemoveCondition(GlobalIndices[0], TFCond_Buffed);
				
				if ( timer_AssassinCondition != INVALID_HANDLE )
				{
					KillTimer(timer_AssassinCondition);	// Kill the timer if there is one.
					timer_AssassinCondition = INVALID_HANDLE;	// Set our handle back to invalid (this doesn't happen automatically, it seems).
				}
			}
		}
		else if ( id == 1)
		{
			// Reset the render mode on the target player
			if ( GlobalIndices[1] > 0 && GlobalIndices[1] <= MaxClients && IsClientConnected(GlobalIndices[1]))	// If they're valid:
			{
				SetEntityRenderColor(GlobalIndices[1], 255, 255, 255, 255);
			}
		}
		
		GlobalIndices[id] = value;						// Write to the index.
		
		// If the index isn't 0 and the client is valid, set the buff condition on the new assassin.
		if ( id == 0 && GlobalIndices[0] > 0 && GlobalIndices[0] <= MaxClients && IsClientConnected(GlobalIndices[0]) )
		{
			if ( IsPlayerAlive(GlobalIndices[0]) )	// If the player's alive, set the buff.
			{
				TF2_AddCondition(GlobalIndices[0], TFCond_Buffed, 0.55);
			}
			
			// We still want to set the timer, even if the player isn't alive.
			timer_AssassinCondition = CreateTimer(0.5, TimerAssassinCondition, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		}
		// Set the render mode on the target player
		else if ( id == 1 && GlobalIndices[1] > 0 && GlobalIndices[1] <= MaxClients && IsClientConnected(GlobalIndices[0]) && GetConVarBool(cv_ColourTarget) )	// If they're valid and we should be colouring the target:
		{
			switch (GetClientTeam(GlobalIndices[1]))
			{
				case TEAM_RED:
				{
					SetEntityRenderColor(GlobalIndices[1], 255, 58, 84, 255);
				}
				
				case TEAM_BLUE:
				{
					SetEntityRenderColor(GlobalIndices[1], 50, 98, 255, 255);
				}
			}
		}
		
		#if DEBUG == 1
		new String:debugassassin[MAX_NAME_LENGTH + 1];
		new String:debugtarget[MAX_NAME_LENGTH + 1];
		if ( GlobalIndices[0] > 0 && GlobalIndices[0] <= MaxClients && IsClientConnected(GlobalIndices[0]) ) GetClientName(GlobalIndices[0], debugassassin, sizeof(debugassassin));
		if ( GlobalIndices[1] > 0 && GlobalIndices[1] <= MaxClients && IsClientConnected(GlobalIndices[1]) ) GetClientName(GlobalIndices[1], debugtarget, sizeof(debugtarget));
		LogMessage("[AS] Assassin: %s Target: %s", debugassassin, debugtarget);
		#endif
		
		UsrEvent_IndexModified(GlobalIndices[0], GlobalIndices [1]);	// Update the dependant systems.
		return GlobalIndices[id];						// Return the value.
	}
	else return GlobalIndices[id];	// Otherwise, just return the value.
}

/*	Holds the team score counters and handles when they're changed.
	Passing write as true changes the counter and returns the value; false reads the counter and returns the value.
	Passing total as false accesses the normal counters; true accesses the total counters that are only reset on a new map.
	Passing TEAM_RED as the id accesses the Red counter, TEAM_BLUE accesses the Blue counter.
	If writing, the value argument is the value the specified index should be changed to.	
	Note that if write = true, UsrEvent_CounterModified is called and is given the id of the changed counter and its new value.	*/
stock TeamScore(write = false, total = false, id, value = 0)
{
	static TeamCounters[4];	// Index 0 is Red total, 1 is Blue total, 2 is Red normal, 3 is Blue normal.
	
	if ( id < TEAM_RED ) id = TEAM_RED;		// Clamp the ID values
	if ( id > TEAM_BLUE ) id = TEAM_BLUE;
	
	if ( write )	// If we're changing a value:
	{
		if ( total )
		{
			TeamCounters[id-2] = value;
			if ( TeamCounters[id-2] < 0 ) TeamCounters[id-2] = 0;
			UsrEvent_CounterModified(TeamCounters[0], TeamCounters[1], TeamCounters[2], TeamCounters[3]);
			return TeamCounters[id-2];
		}
		else
		{
			TeamCounters[id] = value;
			if ( TeamCounters[id] > GetConVarInt(cv_MaxScore) ) TeamCounters[id] = GetConVarInt(cv_MaxScore);	// Clamp to max score.
			if ( TeamCounters[id] < 0 ) TeamCounters[id] = 0;
			UsrEvent_CounterModified(TeamCounters[0], TeamCounters[1], TeamCounters[2], TeamCounters[3]);
			return TeamCounters[id];
		}
	}
	else
	{
		if ( total ) return TeamCounters[id-2];	// If we're looking at total scores, use an array index offset.
		else return TeamCounters[id];			// Otherwise, return as normal.
	}
}

/*	Returns the float value of a score after it has been multiplied by score modifiers.
	If an error is encountered, the original score is returned.*/
stock Float:ModifyScore(Float:n_Score, id_Weapon, g_DamageBits, n_CustomKill, g_DeathFlags, i_InflictorIndex)
{
	// The first thing we want to do is multiply our input score by the weapon multiplier.
	// id_Weapon gives us the item definition index of the weapon from the player_death event.
	
	new Float:n_NewScore = n_Score * WeaponModifiers(true, id_Weapon);
	#if DEBUG == 1
	LogMessage("ModifyScore: Weapon modifiers applied, score = %f", n_NewScore);
	#endif
	
	// We then want to multiply this new score by the multipliers for custom kill types:
	// We need to deal with:
	// Headshots
	// Backstabs
	// Reflect kills
	// Sentries (level 1, 2, 3)
	// Telefrags
	
	switch (n_CustomKill)
	{
		case TF_CUSTOM_HEADSHOT:
		{
			n_NewScore = n_NewScore * GetConVarFloat(cv_HeadshotMultiplier);
			#if DEBUG == 1
			LogMessage("ModifyScore: Headshot, score = %f", n_NewScore);
			#endif
		}
		
		case TF_CUSTOM_BACKSTAB:
		{
			n_NewScore = n_NewScore * GetConVarFloat(cv_BackstabMultiplier);
			#if DEBUG == 1
			LogMessage("ModifyScore: Backstab, score = %f", n_NewScore);
			#endif
		}
		
		case TF_CUSTOM_TELEFRAG:
		{
			n_NewScore = n_NewScore * GetConVarFloat(cv_TelefragMultiplier);
			#if DEBUG == 1
			LogMessage("ModifyScore: Telefrag, score = %f", n_NewScore);
			#endif
		}
	}
	
	// Now deal with entities:
	if ( i_InflictorIndex > 0 && IsValidEntity(i_InflictorIndex) )
	{
		decl String:entname[64];
		GetEdictClassname(i_InflictorIndex, entname, sizeof(entname));
		if ( StrEqual(entname, "obj_sentrygun", false) )
		{
			switch (GetEntPropEnt(i_InflictorIndex, Prop_Send, "m_iUpgradeLevel"))
			{				
				case 2:
				{
					n_NewScore = n_NewScore * GetConVarFloat(cv_SentryL2Multiplier);
					#if DEBUG == 1
					LogMessage("ModifyScore: L2 sentry, score = %f", n_NewScore);
					#endif
				}
				
				case 3:
				{
					n_NewScore = n_NewScore * GetConVarFloat(cv_SentryL3Multiplier);
					#if DEBUG == 1
					LogMessage("ModifyScore: L3 sentry, score = %f", n_NewScore);
					#endif
				}
				
				default:
				{
					n_NewScore = n_NewScore * GetConVarFloat(cv_SentryL1Multiplier);
					#if DEBUG == 1
					LogMessage("ModifyScore: L1 sentry or default, score = %f", n_NewScore);
					#endif
				}
			}
		}
		else if ( StrContains(entname, "tf_projectile_") != -1 )
		{
			if ( GetEntPropEnt(i_InflictorIndex, Prop_Send, "m_iDeflected") > 0 )
			{
				n_NewScore = n_NewScore * GetConVarFloat(cv_ReflectMultiplier);
				#if DEBUG == 1
				LogMessage("ModifyScore: Reflect, score = %f", n_NewScore);
				#endif
			}
		}
	}
	
	#if DEBUG == 1
	LogMessage("ModifyScore: Final score = %f", n_NewScore);
	#endif
	return n_NewScore;
}

/*	Cleans up any variables, timers, etc.
	If 0 is passed (default), does actions for RoundStart.
	If 1 is passed, does actions for RoundWin.
	If 2 is passed, does actions for MapStart.
	If 3 is passed, does actions for MapEnd.	*/
stock Cleanup(mode = 0)
{
	/*On RoundStart:
	* 	Reset normal score counters.
	* 	Reset assassin and target indices to 0.
	* On RoundWin:
	* 	Reset assassin and target indices to 0.
	* On MapStart:
	* 	Reset assassin and target indices to 0.
	* 	Reset normal score counters to 0.
	* 	Reset total score counters to 0.
	* On MapEnd:
	* 	Reset assassin and target indices to 0.
	* 	Reset normal score counters to 0.
	* 	Reset total score counters to 0.
	*	Reset spawn edit flag.
	*	Reset spawn edit client.
	*	Kill any menus.
	* 	Kill any timers.
	* 	Kill any HUD sync objects.	*/
	
	switch (mode)
	{
		case CLEANUP_ROUNDSTART:	// RoundStart
		{
			TeamScore(true, false, TEAM_RED, 0);
			TeamScore(true, false, TEAM_BLUE, 0);
			
			GlobalIndex(true, 0, 0);
			GlobalIndex(true, 1, 0);
		}
		
		case CLEANUP_ROUNDWIN:	// RoundWin:
		{
			GlobalIndex(true, 0, 0);
			GlobalIndex(true, 1, 0);
		}
		
		case CLEANUP_MAPSTART:	// MapStart
		{
			GlobalIndex(true, 0, 0);
			GlobalIndex(true, 1, 0);
			
			
			TeamScore(true, false, TEAM_RED, 0);
			TeamScore(true, false, TEAM_BLUE, 0);
			TeamScore(true, true, TEAM_RED, 0);
			TeamScore(true, true, TEAM_BLUE, 0);
		}
		
		case CLEANUP_MAPEND:	// MapEnd
		{
			GlobalIndex(true, 0, 0);
			GlobalIndex(true, 1, 0);
			
			TeamScore(true, false, TEAM_RED, 0);
			TeamScore(true, false, TEAM_BLUE, 0);
			TeamScore(true, true, TEAM_RED, 0);
			TeamScore(true, true, TEAM_BLUE, 0);
			
			if ( timer_AssassinCondition != INVALID_HANDLE )
			{
				KillTimer(timer_AssassinCondition);
				timer_AssassinCondition = INVALID_HANDLE;
			}
			
			if ( timer_HUDMessageRefresh != INVALID_HANDLE )
			{
				KillTimer(timer_HUDMessageRefresh);
				timer_HUDMessageRefresh = INVALID_HANDLE;
			}
			
			if ( timer_HUDScoreRefresh != INVALID_HANDLE )
			{
				KillTimer(timer_HUDScoreRefresh);
				timer_HUDScoreRefresh = INVALID_HANDLE;
			}
			
			if ( timer_MedicHealBuff != INVALID_HANDLE )
			{
				KillTimer(timer_MedicHealBuff);
				timer_MedicHealBuff = INVALID_HANDLE;
			}
			
			if ( hs_Assassin != INVALID_HANDLE ) CloseHandle(hs_Assassin);	// If the assassin hud snyc isn't invalid, close it.
			if ( hs_Target != INVALID_HANDLE ) CloseHandle(hs_Target);		// If the target hud snyc isn't invalid, close it.
			if ( hs_Score != INVALID_HANDLE ) CloseHandle(hs_Score);
		}
	}
}

/*	Gets the item definition index of a weapon, given the inflictor index.	*/
stock ItemDefinitionIndex(inflictor, weapon_id)
{
	/*	We need to do different things depending on the inflictor index:
	* If it's the player, get their current weapon.
	* If it's a projectile, get the owner player through m_hOwnerEntity and check their weapons for a match with the weapon ID.
	* If it's something like a flare, apparently the inflictor index will already be the weapon, so
	* to check if the entity is a weapon we could check if the entity name contains "tf_weapon_". */
	
	#if DEBUG == 1
	LogMessage("#1 ItemDefinitionIndex called.");
	#endif
	
	if ( inflictor <= 0)
	{
		#if DEBUG == 1
		LogMessage("##2 ABORT: Inflictor value %d is <= 0, returning -1.", inflictor);
		#endif
		
		return -1;
	}
	
	// If the index is a player, get their current weapon.
	else if ( inflictor > 0 && inflictor <= MaxClients && IsClientConnected(inflictor) )
	{
		#if DEBUG == 1
		LogMessage("#3 Index is player.");
		#endif
		
		new cweaponindex = -1;
		decl String:clientweapon[64];
		clientweapon[0] = '\0';
		GetClientWeapon(inflictor, clientweapon, sizeof(clientweapon));
		
		// Cycle through all instances of this weapon and check if the weapon owner matches the player.
		// We have to do this because, AFAIK, there is no way of getting the player's weapon index,
		// only its classname.
		new cycleindex = -1;
		while ( (cycleindex = FindEntityByClassname(cycleindex, clientweapon)) != -1 )
		{
			if ( GetEntPropEnt(cycleindex, Prop_Send, "m_hOwner" ) == inflictor )	// If owner matches inflictor:
			{
				cweaponindex = cycleindex;
				
				#if DEBUG == 1
				LogMessage("#4 Owner value %d of weapon matches inflictor index %d. Weapon index chosen is %d.", GetEntPropEnt(cycleindex, Prop_Send, "m_hOwner" ), inflictor, cweaponindex);
				#endif
			}
		}
		
		#if DEBUG == 1
		LogMessage("#5 Cweaponindex is %d.", cweaponindex);
		#endif
		
		// By now the entindex of the weapon is held in cweaponindex.
		// Get the item definition index from the weapon.
		
		if ( IsValidEntity(cweaponindex) )
		{
			#if DEBUG == 1
			decl String:weaponclassname[64];
			GetEntityClassname(cweaponindex, weaponclassname, sizeof(weaponclassname));
			LogMessage("#6 Returning item def index %d of weapon %d (%s).", GetEntProp(cweaponindex, Prop_Send, "m_iItemDefinitionIndex"), cweaponindex, weaponclassname);
			#endif
			return GetEntProp(cweaponindex, Prop_Send, "m_iItemDefinitionIndex");
		}
		else
		{
			#if DEBUG == 1
			LogMessage("##7 ABORT: cweaponindex %d is not a valid entity, returning -1.", cweaponindex);
			#endif 
			
			return -1;
		}
	}
	else	// If the inflictor is another entity:
	{
		#if DEBUG == 1
		LogMessage("#8 Inflictor is an entity other than the player (weapon or projectile).");
		#endif
		
		// We need to determine if this entity is a projectile or a weapon.
		// If it's a weapon, return the definition index immediately.
		// If it's not, find the weapon through the owner.
		
		decl String:classname[64];
		GetEntityClassname(inflictor, classname, sizeof(classname));
		
		if ( StrContains(classname, "tf_weapon_", false) != -1 )	// If the classname is in weapon format:
		{
			#if DEBUG == 1
			LogMessage("#9 Classname %s is in weapon format.", classname);
			#endif
			if ( IsValidEntity(inflictor) )
			{
				#if DEBUG == 1
				decl String:weaponclassname[64];
				GetEntityClassname(inflictor, weaponclassname, sizeof(weaponclassname));
				LogMessage("#10 Returning item def index %d of weapon %d (%s).", GetEntProp(inflictor, Prop_Send, "m_iItemDefinitionIndex"), inflictor, weaponclassname);
				#endif
				return GetEntProp(inflictor, Prop_Send, "m_iItemDefinitionIndex");	// Return the definition index.
			}
			else
			{
				#if DEBUG == 1
				LogMessage("##11 ABORT: classname in weapon format but not valid entity (??), returning -1.");
				#endif
				
				return -1;
			}
		}
		
		// Getting to here means inflictor didn't point to a weapon.
		// We now need to check to see if it points to a projectile and, if so, trace back to the owner weapon.
		// Projectiles have the name format tf_projectile_...
		
		// If the projectile is a sentry rocket, return -1 since sentries are handled elsewhere.
		else if ( StrContains(classname, "tf_projectile_sentryrocket", false) != -1 )
		{
			return -1;
		}
		
		else if ( StrContains(classname, "tf_projectile_", false) != -1 )	// If the classname is in projectile format:
		{
			#if DEBUG == 1
			LogMessage("#12 Classname %s is in projectile format.", classname);
			#endif
			
			if ( !IsValidEntity(inflictor) )
			{
				#if DEBUG == 1
				LogMessage("##13 ABORT: inflictor at index %d is not a valid entity, returning -1.", inflictor);
				#endif
				
				return -1;
			}
			
			// If the inflictor is a projectile, this could be one of many things (rocket, grenade, flare, etc.).
			// We then need to check the weapon ID from the death event and see which weapon it points to.
			// Once we have the owner entity from the projectile (which will be the index of the client who
			// fired it), we will be able to check their weapon slots for the weapon that matches the weapon
			// ID and then get the item definition index from that weapon.
			
			// If this is a grenade, the property is held in m_hThrower instead.
			
			decl String:projectileowner_name[64];
			projectileowner_name[0] = '\0';
			
			new projectileowner;
			if ( StrContains(classname, "tf_projectile_pipe", false) != -1 )	// Pipes act differently. >:(
			{
				projectileowner = GetEntPropEnt(inflictor, Prop_Send, "m_hThrower");
			}
			else projectileowner = GetEntPropEnt(inflictor, Prop_Send, "m_hOwnerEntity");
			
			if ( IsValidEntity(projectileowner) && IsClientConnected(projectileowner) )
			{
				#if DEBUG == 1
				LogMessage("#14 Projectile owner %d is valid.", projectileowner);
				#endif
			}
			else
			{
				#if DEBUG == 1
				LogMessage("##15 ABORT: owner index %d is invalid, returning -1.", projectileowner);
				#endif
				
				return -1;
			}
			
			// Now the client index of the player who fired the projectile is in projectileowner.
			// The weapon ID could be one of the following: TF_WEAPON_SYRINGEGUN_MEDIC (?),
			// TF_WEAPON_ROCKETLAUNCHER, TF_WEAPON_GRENADELAUNCHER, TF_WEAPON_PIPEBOMBLAUNCHER,
			// TF_WEAPON_DIRECTHIT, TF_WEAPON_FLAREGUN, TF_WEAPON_COMPOUND_BOW, TF_CUSTOM_BASEBALL,
			// TF_WEAPON_GRENADE_DEMOMAN.
			
			// Grenadelauncher slot 0, pipebomblauncher slot 1, although pipebomblauncher is the grenade launcher... Jesus Christ, Valve.
			
			// If the weapon ID is from a weapon in the primary slot, we need to check the owner's primary.
			if ( weapon_id == TF_WEAPON_ROCKETLAUNCHER
				|| weapon_id == TF_WEAPON_DIRECTHIT
				|| weapon_id == TF_WEAPON_COMPOUND_BOW
				|| weapon_id == TF_WEAPON_SYRINGEGUN_MEDIC
				|| weapon_id == TF_WEAPON_GRENADELAUNCHER )
			{
				new slotindex = GetPlayerWeaponSlot(projectileowner, 0);
				
				if ( slotindex != -1 && IsValidEntity(slotindex) )
				{
					#if DEBUG == 1
					decl String:weaponclassname[64];
					GetEntityClassname(slotindex, weaponclassname, sizeof(weaponclassname));
					LogMessage("#16 Returning item def index %d from weapon index %d (%s) at slot 0.", GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex"), slotindex, weaponclassname);
					#endif
					
					return  GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex");	// Return the definition index.
				}
				else
				{
					#if DEBUG == 1
					LogMessage("##17 ABORT: slotindex %d is invalid, returning -1.", slotindex);
					#endif
					
					return -1;
				}
			}
			// Same for secondary.
			else if ( weapon_id == TF_WEAPON_FLAREGUN
					|| weapon_id == TF_WEAPON_PIPEBOMBLAUNCHER
					|| weapon_id == TF_WEAPON_NONE
					|| weapon_id == TF_WEAPON_GRENADE_DEMOMAN )	// Loch 'n' Load sometimes shows up as weapon ID 0; bug in Sourcemod?
			{
				new slotindex = GetPlayerWeaponSlot(projectileowner, 1);
				
				if ( slotindex != -1 && IsValidEntity(slotindex) )
				{
					#if DEBUG == 1
					decl String:weaponclassname[64];
					GetEntityClassname(slotindex, weaponclassname, sizeof(weaponclassname));
					LogMessage("#18 Returning item def index %d from weapon index %d (%s) at slot 1.", GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex"), slotindex, weaponclassname);
					#endif
					
					return  GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex");	// Return the definition index.
				}
				else
				{
					#if DEBUG == 1
					LogMessage("##19 ABORT: slotindex %d is invalid, returning -1.", slotindex);
					#endif
					
					return -1;
				}
			}
			// Same for melee (sandman).
			else if ( weapon_id == TF_WEAPON_BAT_WOOD )
			{
				new slotindex = GetPlayerWeaponSlot(projectileowner, 2);
				
				if ( slotindex != -1 && IsValidEntity(slotindex) )
				{
					#if DEBUG == 1
					decl String:weaponclassname[64];
					GetEntityClassname(slotindex, weaponclassname, sizeof(weaponclassname));
					LogMessage("#20 Returning item def index %d from weapon index %d (%s) at slot 1.", GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex"), slotindex, weaponclassname);
					#endif
					
					return  GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex");	// Return the definition index.
				}
				else
				{
					#if DEBUG == 1
					LogMessage("##21 ABORT: slotindex %d is invalid, returning -1.", slotindex);
					#endif
					
					return -1;
				}
			}
			// Weapon ID is not specified in code, return -1 and notify.
			else
			{
				LogMessage("##22 Error in ItemDefinitionIndex: Weapon ID %d from inflictor ID %d is not recognised. The plugin code probably needs updating.", weapon_id, inflictor);
				
				return -1;
			}
		}
		
		else
		{
			#if DEBUG == 1
			LogMessage("##23 ABORT: classname %s is not in projectile format either, returning -1.", classname);
			#endif
			
			return -1;	// If the entity isn't a projectile either (eg it's a sentry), return -1.
		}
	}
}

/*	Timer continually called every 0.5s to re-apply the buffed condition on the assassin.
	This is to allow the assassin to stay buffed if another soldier on the team activates their buff banner,
	as this would otherwise disable the assassin buff condition when it finishes.
	Since the assassin index is always changed if something happens to the client who is the assassin,
	hopefully it's safe to use in this timer.	*/
public Action:TimerAssassinCondition(Handle:timer)
{
	// If the assassin index is valid, reset the condition on the assassin.
	if ( GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients && IsClientConnected(GlobalIndex(false, 0)) && IsPlayerAlive(GlobalIndex(false, 0)) )
	{
		TF2_AddCondition(GlobalIndex(false, 0), TFCond_Buffed, 0.55);
	}
	
	return Plugin_Handled;
}

/*	Timer continually called every 0.25 seconds to re-apply the buffed condition on the assassin's heal target, if the
	assassin is a Medic.	*/
public Action:TimerMedicHealBuff(Handle:timer)
{
	// If there are any abnormal states, exit.
	if ( g_PluginState > 0 ) return Plugin_Handled;
	
	// If the assassin index is valid:
	if ( GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients && IsClientConnected(GlobalIndex(false, 0)) && IsPlayerAlive(GlobalIndex(false, 0)) )
	{
		// If the assassin is a Medic:
		if ( TF2_GetPlayerClass(GlobalIndex(false, 0)) == TFClass_Medic )
		{
			decl String:CurrentWeapon[32];
			CurrentWeapon[0] = '\0';
			GetClientWeapon(GlobalIndex(false, 0), CurrentWeapon, sizeof(CurrentWeapon));
			
			// If the current weapon is a medigun and it's healing:
			if ( StrContains(CurrentWeapon, "tf_weapon_medigun", false) != -1 && GetEntProp(GetPlayerWeaponSlot(GlobalIndex(false, 0), 1), Prop_Send, "m_bHealing") == 1 )
			{
				// Look through all the players and apply the buffed condition to the player who matches the Medic's heal target.
				for ( new i = 1; i <= MaxClients; i++ )
				{
					if ( IsClientInGame(i) && IsPlayerAlive(i) && GetEntPropEnt(GetPlayerWeaponSlot(GlobalIndex(false, 0), 1), Prop_Send, "m_hHealingTarget") == i )
					{
						TF2_AddCondition(i, TFCond_Buffed, 0.3);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

/*	Updates the HUD for all clients concerning who is the assassin/target.	*/
stock UpdateHUDMessages(assassin, target)
{
	if ( g_PluginState > STATE_DISABLED ) return;	// If we're not enabled, return.
	
	new assassin_team;
	new target_team;
	
	if ( assassin > 0 && assassin <= MaxClients && IsClientConnected(assassin) ) assassin_team = GetClientTeam(assassin);
	if ( target > 0 && target <= MaxClients && IsClientConnected(target) ) target_team = GetClientTeam(target);
	
	if ( hs_Assassin != INVALID_HANDLE )	// If our assassin synchroniser exists:
	{
		switch(assassin_team)
		{
			case TEAM_RED:
			{
				SetHudTextParams(0.05, 0.1,
									1.0,
									189,
									58,
									58,
									255,
									0,
									0.0,
									0.0,
									0.0);
			}
			
			case TEAM_BLUE:
			{
				SetHudTextParams(0.05, 0.1,
									1.0,
									0,
									38,
									255,
									255,
									0,
									0.0,
									0.0,
									0.0);
			}
			
			default:
			{
				SetHudTextParams(0.05, 0.1,
									1.0,
									255,
									255,
									255,
									255,
									0,
									0.0,
									0.0,
									0.0);
			}
		}
		
		if ( assassin > 0 && (g_PluginState & STATE_NOT_IN_ROUND) != STATE_NOT_IN_ROUND )	// If we should display text:
		{
			
			// Display the text to all players.
			decl String:s_AssassinName[MAX_NAME_LENGTH + 1];
			s_AssassinName[0] = '\0';
			
			// Make sure our client is valid before we get their name.
			if ( assassin > 0 && assassin <= MaxClients )
			{
				if ( IsClientInGame(assassin) ) GetClientName(assassin, s_AssassinName, sizeof(s_AssassinName));
			}
			
			for ( new i_assassin = 1; i_assassin <= MaxClients; i_assassin++ )	// Iterate through the client indices
			{
				if ( IsClientInGame(i_assassin) )	// If the client is connected:
				{
					ShowSyncHudText(i_assassin, hs_Assassin, "%t: %s", "as_assassin", s_AssassinName);
				}
			}
		}
		else	// Otherwise, hide any text.
		{			
			// Clear HUD sync for all players
			ClearSyncHUDTextAll(hs_Assassin);
		}
	}
	
	if ( hs_Target != INVALID_HANDLE )	// If our target synchroniser exists:
	{
		switch(target_team)
		{
			case TEAM_RED:
			{
				SetHudTextParams(0.05, 0.13,
									1.0,
									189,
									58,
									58,
									255,
									0,
									0.0,
									0.0,
									0.0);
			}
			
			case TEAM_BLUE:
			{
				SetHudTextParams(0.05, 0.13,
									1.0,
									0,
									38,
									255,
									255,
									0,
									0.0,
									0.0,
									0.0);
			}
			
			default:
			{
				SetHudTextParams(0.05, 0.13,
									1.0,
									255,
									255,
									255,
									255,
									0,
									0.0,
									0.0,
									0.0);
			}
		}
		
		if ( target > 0 && (g_PluginState & STATE_NOT_IN_ROUND) != STATE_NOT_IN_ROUND )	// If we should display text:
		{			
			// Display the text to all players.
			decl String:s_TargetName[MAX_NAME_LENGTH + 1];
			s_TargetName[0] = '\0';
			
			// Make sure our client is valid before we get their name.
			if ( target > 0 && target <= MaxClients )
			{
				if ( IsClientInGame(target) ) GetClientName(target, s_TargetName, sizeof(s_TargetName));
			}
			
			for ( new i_target= 1; i_target <= MaxClients; i_target++ )	// Iterate through the client indices
			{
				if ( IsClientInGame(i_target) )	// If the client is connected:
				{
					ShowSyncHudText(i_target, hs_Target, "%t: %s", "as_target", s_TargetName);
				}
			}
		}
		else	// Otherwise, hide any text.
		{			
			// Clear HUD sync for all players
			ClearSyncHUDTextAll(hs_Target);
		}
	}
}

/*	Timer called once a second to update the HUD messages.
	If ModifyClientIndex is called, it will close this timer if it's running, execute the impending UpdateHUDMessages
	and then set up the timer again.	*/
public Action:TimerHUDRefresh(Handle:timer)
{
	UpdateHUDMessages(GlobalIndex(false, 0), GlobalIndex(false, 1));
	
	return Plugin_Continue;
}

/*	Clears the HUD text through the HUD synchroniser for all clients.
	Argument is the handle of the synchronisation object.*/
stock ClearSyncHUDTextAll(Handle:syncobj = INVALID_HANDLE)
{
	if ( syncobj == INVALID_HANDLE ) return;	// If our handle isn't valid, return.
	
	for ( new i = 1; i <= MaxClients; i++ )	// Iterate through the client indices
	{
		if ( IsClientInGame(i) )	// If the client is connected:
		{
			ClearSyncHud(i, syncobj);	// Clear their sync object.
		}
	}
}

stock UpdateHUDScore(red_total, blue_total, red, blue)
{
	if ( g_PluginState > STATE_DISABLED ) return;	// If we're not enabled, return.
	
	new MaxScore = GetConVarInt(cv_MaxScore);
	
	if ( hs_Score != INVALID_HANDLE )
	{
		SetHudTextParams(-1.0, 0.8,
									1.0,
									255,
									255,
									255,
									255,
									0,
									0.0,
									0.0,
									0.0);
	}
	
	if ( (g_PluginState & STATE_NOT_IN_ROUND) != STATE_NOT_IN_ROUND && hs_Score != INVALID_HANDLE )
	{
		// Display the scores to all players.

		for ( new i_target= 1; i_target <= MaxClients; i_target++ )	// Iterate through the client indices
		{
			if ( IsClientInGame(i_target) )	// If the client is connected:
			{
				ShowSyncHudText(i_target, hs_Score, "%t %d | %t %d | %t %d", "as_red", red, "as_blue", blue, "as_playingto", MaxScore);
			}
		}
	}
	else	// Otherwise, hide any text.
	{			
		// Clear HUD sync for all players
		ClearSyncHUDTextAll(hs_Score);
	}
}

public Action:TimerHUDScoreRefresh(Handle:timer)
{
	UpdateHUDScore(TeamScore(false, true, TEAM_RED), TeamScore(false, true, TEAM_RED), TeamScore(false, false, TEAM_RED), TeamScore(false, false, TEAM_BLUE));
	
	return Plugin_Continue;
}

/*	Returns the entity index of the sprite that has been created.
	Second argument specifies the sprite type (false = assassin, true = target).	*/
stock CreateSprite(client, bool:type)
{
	// Create the sprite.
	new sprite = CreateEntityByName("env_sprite_oriented");
	
	if ( sprite )	// If creation succeeded:
	{
		decl String:spritepath[128];
		
		if ( !type )	// If type is false (assassin):
		{
			if ( GetConVarBool(cv_NoZSprites) )
			{
				Format(spritepath, sizeof(spritepath), "%s.vmt", ASSASSIN_SPRITE_Z_PATH);
			}
			else
			{
				Format(spritepath, sizeof(spritepath), "%s.vmt", ASSASSIN_SPRITE_PATH);
			}
		}
		else	// If type is true (target):
		{
			if ( GetConVarBool(cv_NoZSprites) )
			{
				Format(spritepath, sizeof(spritepath), "%s.vmt", TARGET_SPRITE_Z_PATH);
			}
			else
			{
				Format(spritepath, sizeof(spritepath), "%s.vmt", TARGET_SPRITE_PATH);
			}
		}
		
		DispatchKeyValue(sprite, "model", spritepath);
		DispatchKeyValue(sprite, "classname", "env_sprite_oriented");
		DispatchKeyValue(sprite, "spawnflags", "1");
		DispatchKeyValue(sprite, "scale", "0.1");
		DispatchKeyValue(sprite, "rendermode", "1");
		DispatchKeyValue(sprite, "rendercolor", "255 255 255");
		
		if ( !type ) DispatchKeyValue(sprite, "targetname", "assassin_sprite");	// Assassin sprite name
		else DispatchKeyValue(sprite, "targetname", "target_sprite");			// Target sprite name
		
		return sprite;	// Return the sprite index
	}
	else return -1;	// Creation didn't succeed, return -1.
}

/*	Kills any buildings built by the specified player.
	Client is the player index to check.
	Flags is the types of building to check for.
	1 = Sentries
	2 = Dispensers
	4 = Teleporters	*/
stock KillBuildings(client, flags)
{
	if ( TF2_GetPlayerClass(client) != TFClass_Engineer ) return;
	
	// Sentries:
	if ( (flags & BUILDING_SENTRY) == BUILDING_SENTRY )
	{
		new n_SentryIndex = -1;
		while ( (n_SentryIndex = FindEntityByClassname(n_SentryIndex, "obj_sentrygun")) != -1 )
		{
			if ( IsValidEntity(n_SentryIndex) && GetEntPropEnt(n_SentryIndex, Prop_Send, "m_hBuilder") == client )
			{
				SetVariantInt( GetEntProp(n_SentryIndex, Prop_Send, "m_iMaxHealth") + 1 );
				AcceptEntityInput(n_SentryIndex, "RemoveHealth");
				AcceptEntityInput(n_SentryIndex, "Kill");
			}
		}
	}
	
	// Dispensers:
	if ( (flags & BUILDING_DISPENSER) == BUILDING_DISPENSER )
	{
		new n_DispenserIndex = -1;
		while ( (n_DispenserIndex = FindEntityByClassname(n_DispenserIndex, "obj_dispenser")) != -1 )
		{
			if ( IsValidEntity(n_DispenserIndex) && GetEntPropEnt(n_DispenserIndex, Prop_Send, "m_hBuilder") == client )
			{
				SetVariantInt( GetEntProp(n_DispenserIndex, Prop_Send, "m_iMaxHealth") + 1 );
				AcceptEntityInput(n_DispenserIndex, "RemoveHealth");
				AcceptEntityInput(n_DispenserIndex, "Kill");
			}
		}
	}
	
	// Teleporters:
	if ( (flags & BUILDING_TELEPORTER) == BUILDING_TELEPORTER )
	{
		new n_TeleporterIndex = -1;
		while ( (n_TeleporterIndex = FindEntityByClassname(n_TeleporterIndex, "obj_teleporter")) != -1 )
		{
			if ( IsValidEntity(n_TeleporterIndex) && GetEntPropEnt(n_TeleporterIndex, Prop_Send, "m_hBuilder") == client )
			{
				SetVariantInt( GetEntProp(n_TeleporterIndex, Prop_Send, "m_iMaxHealth") + 1 );
				AcceptEntityInput(n_TeleporterIndex, "RemoveHealth");
				AcceptEntityInput(n_TeleporterIndex, "Kill");
			}
		}
	}
}

/*	Checks the team scores against the max score ConVar.
	If either team is over the max, the round is won for that team.
	If both teams are over, the round is ended as a draw.*/
stock CheckScoresAgainstMax()
{
	if ( TeamScore(false, false, TEAM_RED) >= GetConVarInt(cv_MaxScore) && TeamScore(false, false, TEAM_BLUE) >= GetConVarInt(cv_MaxScore) )
	{
		RoundWin();
	}
	else if ( TeamScore(false, false, TEAM_RED) >= GetConVarInt(cv_MaxScore) )
	{
		RoundWin(TEAM_RED);
	}
	else if ( TeamScore(false, false, TEAM_BLUE) >= GetConVarInt(cv_MaxScore) )
	{
		RoundWin(TEAM_BLUE);
	}
}

/*	Wins the round for the specified team.	*/
stock RoundWin(n_team = 0)
{	
	// #TODO#: Sort out these flag issues.
	new Flags = GetCommandFlags("mp_forcewin");	// Get the ConVar flags
	if ( Flags != INVALID_FCVAR_FLAGS )
	{
		Flags &= ~FCVAR_CHEAT;						// Clear the cheat flag.
		SetCommandFlags("mp_forcewin", Flags);		// Reset the flags.
	}
	else LogMessage("ERROR: mp_forcewin not found.");
	
	if ( n_team == TEAM_RED || n_team == TEAM_BLUE )
	{
		ServerCommand("sv_cheats 1;mp_forcewin %d;sv_cheats 0", n_team);
	}
	else
	{
		ServerCommand("sv_cheats 1;mp_forcewin 0;sv_cheats 0");
	}
	
	if ( Flags != INVALID_FCVAR_FLAGS )
	{
		Flags |= FCVAR_CHEAT;					// Set the cheat flag.
		SetCommandFlags("mp_forcewin", Flags);	// Reset the flags.
	}
}

/*	Handles reading and writing weapon score modifier data.
	If read = false, the weapons modifier file will be parsed and the info put into the two static arrays. This should
	only be done once OnPluginStart since it's quite an intensive operation. Returns 1.0 on success, 0.0 on failure.
	If read = true, the weapon ID specified will be checked against the arrays and the score modifier value returned. If no modifier
	value was specified in the file, 1.0 will be returned (no change in the score).
	Note that this function should be called SPARINGLY. Make sure that read-false is only called OnPluginStart and read-true only
	called when the assassin kills the target (or vice-versa), as these are the only times we'll need to be checking weapon
	modifiers.	*/
stock Float:WeaponModifiers(bool:read = true, n_WeaponID = -1)
{
	/*	-- The process of applying weapon modifiers --
	* 
	* This was quite a system to devise, so it needs some explanation (also for my own reference).
	* 
	* I wanted to minimise the need to update this part of the plugin every single time Valve updated TF2 with new weapons and
	* items. In an ideal scenario, the player_death event could pass any weapon ID to the scoring function (ie. any integer
	* whatsoever) and it would be handled: if there was an entry in the configuration file that matched the weapon ID, the
	* specified score modifier would be applied, and if not it would be ignored (treated as 1). Looping through the file
	* on each and every kill was not an option, due to the intensity of the KeyValues operations, so I decided the best way
	* to deal with the file would be to load it when the plugin started and store the values in an array.
	* 
	* However, the problem arose as to what size the array should be. With potentially hundreds of different weapons the array
	* would need to be fairly large, and if I just hardcoded a top limit (of, say, 512 indices) then this would need to be
	* changed if Valve ever breached that amount of weapons (unlikely but, considering the way things are going, probably
	* possible). It would also be a tremendous waste of array indices if the server operator only had a handful of weapon
	* modifiers set, as the plugin would end up dimensioning an array of several hundred indices when only 10 were used.
	* 
	* Furthermore, there was a problem with decl'ing this type of array. I wanted the weapon ID to be handed straight over to
	* the array, so the modifier value for a weapon would be at the array index [weaponID - 1], but if the array was declared
	* using decl then it was possible for a weapon that wasn't specified in the KeyValues file to be passed over and the plugin
	* would attempt to access a garbage index. Finally, using a dynamic array also seemed to be out of the question since
	* dynamic arrays could only exist at local scope and the weapon modifier array needed to be persistent.
	* 
	* The system I have eventually chosen is to have two local-static dynamic arrays, WeaponID[] and WeaponModifier[]. When
	* a weapon ID is passed to the function, the indices of WeaponID are cycled through first and the values checked against
	* the given ID. When a match is found, the corresponding index number in WeaponModifier will contain the correct weapon
	* modifier float for the given weapon. Because the arrays are dynamic, they will only use the number of indices required
	* (the number of entries in the KeyValues file). This way, I can keep the size of the array down and (hopefully) never
	* need to manually update it when the game updates.	*/
	
	static Handle:WeaponID = INVALID_HANDLE;		// Dynamic aray to hold weapon IDs.
	static Handle:WeaponModifier = INVALID_HANDLE;	// Dynamic array to hold weapon score modifiers.
	static n_SubKeys;								// Holds the number of sub-keys we have.
	static bool:FileRead;							// After the KeyValues file has been read this flag is set to true, allowing reading from the arrays.
	
	if ( !read )	// If we're parsing:
	{
		/*	The KeyValues file is found at scripts/assassination/weaponmodifiers.txt
		* 	Format of the file should be as follows:
		* 
		* 	"weapons"
		* 	{
		* 		"[integersubkey]"
		* 		{
		* 			"weaponid"	"[weaponID]"
		* 			"modifier"	"[modifierfloat]"
		* 		}
		* 	}
		* 
		* 	[integersubkey] - An integer to group together the weapon ID and modifier. It's recommended to use integers increasing from 0. This value is not stored by the code.
		* 	[weaponID] 		- The item definition index of the weapon the modifier is tied to. This ID comes from TF2 Content GCF: tf/scripts/items/items_game.txt.
		* 	[modifierfloat]	- The points modifier for the weapon. This can be anything >= 0. If less than 0, the value will be treated as 0.
		* 					If the value is not formatted as a float (ie. not something like "2.0"), the function will return an error and treat the value as 1.
		*/
		
		if ( FileRead )	// If we've already read the file:
		{
			LogMessage("[AS] KeyValues file attempting to be re-parsed, which is not allowed.");			
			return 0.0;
		}
		
		new Handle:KV = CreateKeyValues("weapons");	// "weapons" is our root node.
		
		// Assuming the file path is from the tf directory?
		if ( !FileToKeyValues(KV, "scripts/assassination/weaponmodifiers.txt") )	// If the operation failed:
		{
			LogMessage("[AS] FileToKeyValues failed for scripts/assassination/weaponmodifiers.txt");
			return 0.0;
		}
		
		// If we've got this far, the file exists and is open.
		// We now need to check how many sub-keys are in the file and dimension our dynamic arrays accordingly.
		
		if ( !KvGotoFirstSubKey(KV) )	// If there are no sub-keys:
		{
			LogMessage("[AS] No first sub-key found in KeyValues file.");
		}
		else	// If there are sub-keys:
		{
			do
			{
				n_SubKeys++;
				
				#if DEBUG == 1
					LogMessage("Sub-key count: %d", n_SubKeys);
				#endif
			} while ( KvGotoNextKey(KV) );	// Increment n_SubKeys while the next key exists.
		}
		
		LogMessage("[AS] Number of sub-keys (weapon IDs) in file: %d", n_SubKeys);
		
		// At this point the number of keys we have (the number of weapon IDs in the file) will be held in n_SubKeys.
		// This will include if the same weapon ID occurs twice. When checking through the arrays later on, this should
		// mean that the first value matching the weapon ID will be returned, thus rendering the later instamces useless.
		
		if ( n_SubKeys <= 0 )	// If no sub-keys were found
		{
			// Dimension our arrays to hold no useful data.
			// This will mean that if the arrays are checked, the weapon ID will not match the values and will be ignored.
			
			WeaponID = CreateArray(1, 1);
			SetArrayCell(WeaponID, 0, -2);
			WeaponModifier = CreateArray(1, 1);
			SetArrayCell(WeaponModifier, 0, 1);
		}
		else	// If n_SubKeys > 0:
		{
			// Dimension our arrays to hold the number of values we found.
			if ( WeaponID == INVALID_HANDLE ) WeaponID = CreateArray(1, n_SubKeys);
			if ( WeaponModifier == INVALID_HANDLE ) WeaponModifier = CreateArray(1, n_SubKeys);
			
			// Go through the KeyValues file again and input the weapon IDs and modifier values into the arrays.
			KvRewind(KV);
			KvGotoFirstSubKey(KV);
			
			for ( new i = 1; i <= n_SubKeys; i++ )
			{
				SetArrayCell(WeaponID, i-1, KvGetNum(KV, "weaponid", -2));	// Put the weapon ID into the array.
				if ( GetArrayCell(WeaponID, i-1) < 0 ) SetArrayCell(WeaponID, i-1, -2);	// If the weapon ID is less than 0, set to an invalid index.
				
				#if DEBUG == 1
					LogMessage("Weapon ID key %d put into WeaponID[%d]", GetArrayCell(WeaponID, i-1), i-1);
				#endif
				
				SetArrayCell(WeaponModifier, i-1, KvGetFloat(KV, "modifier", 1.0));				
				if ( GetArrayCell(WeaponModifier, i-1) < 0.0 ) SetArrayCell(WeaponModifier, i-1, 0.0);	// If the modifier is less than 0, set to zero.
				
				#if DEBUG == 1
					LogMessage("Weapon modifier value %f put into WeaponModifier[%d]", GetArrayCell(WeaponModifier, i-1), i-1);
				#endif
				
				if ( i < n_SubKeys ) KvGotoNextKey(KV);	// If we're not on the last key, go to the next one.
			}
		}
		
		// Now all of the weapon IDs and modifiers have been put into their relevant arrays.
		// n_SubKeys holds the total number of weapon IDs (and n_SubKeys - 1 consequently the number of array indices we should
		// check).
		
		CloseHandle(KV);	// Close the KeyValues structure.
		FileRead = true;	// File has been parsed.
		return 1.0;			// We're finished.
	}
	else
	{
		if ( FileRead )	// As long as we've already read the file:
		{
			// If we didn't have any weapon IDs, return 1 (no modifier).
			if ( n_SubKeys <= 0 )
			{
				#if DEBUG == 1
					LogMessage("No. of sub-keys = 0. Return: 1.0");
				#endif
				return 1.0;
			}
			
			// If either array is invalid, return 1.0.
			if ( WeaponID == INVALID_HANDLE || WeaponModifier == INVALID_HANDLE )
			{
				#if DEBUG == 1
					LogMessage("WeaponID or WeaponModifier array is invalid. Return: 1.0");
				#endif
				return 1.0;
			}
			
			// If the passed weapon ID is < -1, reset to -1 so we don't accidentally get a match in the ID array.
			if ( n_WeaponID < -1 ) n_WeaponID = -1;
			
			// Now check through the Weapon ID array and see if the passed weapon ID can be found.
			for ( new j = 1; j <= n_SubKeys; j++ )
			{
				// If the weapon IDs match, return the corresponding modifier.
				if ( GetArrayCell(WeaponID, j-1) == n_WeaponID )
				{
					#if DEBUG == 1
						LogMessage("Match: weapon ID %d matches array index %d of value %d", n_WeaponID, j-1, GetArrayCell(WeaponModifier, j-1));
					#endif
					return GetArrayCell(WeaponModifier, j-1);
				}
			}
			
			// If there were no matches, return 1.0.
			#if DEBUG == 1
				LogMessage("No match found for weapon ID %d, return: 1.0", n_WeaponID);
			#endif
			return 1.0;
			
			
		}
		else
		{
			#if DEBUG == 1
				LogMessage("Check ID called before file has been parsed. Return: 1.0");
			#endif
			return 1.0;	// Otherwise, return 1 (no modifier).
		}
	}
}

/* Parses our chat commands.	*/
public Action:Command_Say(client, args)
{
	if ( g_PluginState >= STATE_DISABLED ) return Plugin_Handled;
	
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
 
	new startidx = 0;
	if ( text[0] == '"' )
	{
		startidx = 1;
		// Strip the ending quote, if there is one
		new len = strlen(text);
		if ( text[len-1] == '"' )
		{
			text[len-1] = '\0';
		}
	}
 
	if ( StrEqual(text[startidx], "/nfas_help") )
	{
		Panel_Help(client, 0);
		
		// Block the client's messsage from broadcasting
		return Plugin_Handled;
	}
 
	// Let say continue normally
	return Plugin_Continue;
}

/* ==================== /\ End Custom Functions /\ ==================== */

/* ==================== \/ Begin Custom Event Functions \/ ==================== */

/*	Called every time the assassin/target index is changed.
	ID is the index that's changed (false = assassin, true = target).
	Value is the index's new value.
	Any systems that depend on changes to the assassin or target indices should be called from here.
	Values must be passed to let the other functions know the assassin and target indices, as checking
	via GlobalIndex from within the function makes this a re-entrant loop. It seems SourceMod doesn't
	like this, because the server goes down faster than a nymphomaniac fox at Anthrocon.
	At time of writing, I'm not 100% on whether this will fix the crashing problems I'm having (I'm
	not even 100% on the cause of the crash), but nevertheless it needed to be fixed anyway.*/
stock UsrEvent_IndexModified(assassin, target)
{
	// Update systems that should update AFTER an index changes.
	
	if ( timer_HUDMessageRefresh != INVALID_HANDLE )	// If the HUD message timer is still alive:
	{
		KillTimer(timer_HUDMessageRefresh);			// Kill the timer.
		timer_HUDMessageRefresh = INVALID_HANDLE;	// Reset the handle to invalid.
	}
	
	UpdateHUDMessages(assassin, target);
	timer_HUDMessageRefresh = CreateTimer(1.0, TimerHUDRefresh, _, TIMER_REPEAT);	// Set up the new timer.
}

/*	Called every time a team's counter is changed.
	Total is whether the counter was a total counter or not.
	ID is the counter that's changed (TEAM_RED or TEAM_BLUE).
	Value is the index's new value.
	Any systems that depend on changes to the assassin or target indices should be called from here.	*/
stock UsrEvent_CounterModified(red_total, blue_total, red, blue)
{
	if ( timer_HUDScoreRefresh != INVALID_HANDLE )	// If the HUD message timer is still alive:
	{
		KillTimer(timer_HUDScoreRefresh);			// Kill the timer.
		timer_HUDScoreRefresh = INVALID_HANDLE;	// Reset the handle to invalid.
	}
	
	UpdateHUDScore(red_total, blue_total, red, blue);
	timer_HUDScoreRefresh = CreateTimer(1.0, TimerHUDScoreRefresh, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	// Set up the new timer.
}

/*	Called from Event_PlayerDeath when the assassin is killed by the target.
	i_Assassin: 	Index of the assassin who died.
	i_Target: 		Index of the target who attacked them.
	i_Assister: 	Index of the player who assisted.
	id_Weapon: 		Item definition of the weapon the attacker used.
	g_DamageBits: 	Damage type.
	n_CustomKill: 	Custom kill value (eg. headshot, backstab).
	g_DeathFlags: 	Death flags (eg. Dead Ringer).
	i_Inflictor:	Entindex of inflictor.	*/
stock UsrEvent_AssassinKilledByTarget(i_Assassin, i_Target, i_Assister, id_Weapon, g_DamageBits, n_CustomKill, g_DeathFlags, i_Inflictor)
{
	// Play assassin killed by target music
	EmitSoundToAll(SND_ASSASSIN_KILLED_BY_TARGET, _, SNDCHAN_STATIC, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, i_Target, _, NULL_VECTOR, false, 0.0);
	
	// Calculate points earned
	new Float:PointsEarned = ModifyScore(GetConVarFloat(cv_KillAssassin), id_Weapon, g_DamageBits, n_CustomKill, g_DeathFlags, i_Inflictor);
	
	// Add points earned to the target's team's counter
	TeamScore(true, false, GetClientTeam(i_Target), (TeamScore(false, false, GetClientTeam(i_Target)) + RoundFloat(PointsEarned)));
	
	// Display the points earned to the client on the HUD.
	SetHudTextParams(-1.0, 0.73, 2.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0); 
	ShowSyncHudText(i_Target, hs_ScorePopup, "+%d", RoundFloat(PointsEarned));
	
	// Make the killer the assassin
	GlobalIndex(true, 0, i_Target);
	#if DEBUG == 1
	LogMessage("i_Target: %d. Assassin: %d.", i_Target, GlobalIndex(false, 0));
	#endif
	
	// Choose a random target from the late assassin's team, not excluding the late assassin
	GlobalIndex(true, 1, RandomPlayerFromTeam(GetClientTeam(i_Assassin)));
	#if DEBUG == 1
	LogMessage("Target: %d.", i_Target, GlobalIndex(false, 1));
	#endif
}

/*	Called from Event_PlayerDeath when the assassin is killed by another player.
	i_Assassin: 	Index of the assassin who died.
	i_Attacker: 	Index of player who attacked them.
	i_Assister: 	Index of player who assisted.
	id_Weapon: 		Item definition of the weapon the attacker used.
	g_DamageBits: 	Damage type.
	n_CustomKill: 	Custom kill value (eg. headshot, backstab).
	g_DeathFlags: 	Death flags (eg. Dead Ringer).
	i_Inflictor:	Entindex of inflictor.	*/
stock UsrEvent_AssassinKilled(i_Assassin, i_Attacker, i_Assister, id_Weapon, g_DamageBits, n_CustomKill, g_DeathFlags, i_Inflictor)
{
	// Play the assassin killed music
	EmitSoundToAll(SND_ASSASSIN_KILLED, _, SNDCHAN_STATIC, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, i_Attacker, _, NULL_VECTOR, false, 0.0);
	
	// Add 1 point to the killer's team's counter (if teams are different)
	new AttackerTeam = GetClientTeam(i_Attacker);
	if ( GetClientTeam(i_Assassin) != AttackerTeam )
	{
		TeamScore(true, false, AttackerTeam, (TeamScore(false, false, AttackerTeam) + 1));
		
		// Display the points earned to the client on the HUD.
		SetHudTextParams(-1.0, 0.73, 2.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0); 
		ShowSyncHudText(i_Attacker, hs_ScorePopup, "+1");
	}
	
	// Make the killer the assassin
	GlobalIndex(true, 0, i_Attacker);
	
	// Choose a random target from the late assassin's team, not excluding the late assassin
	GlobalIndex(true, 1, RandomPlayerFromTeam(GetClientTeam(i_Assassin)));
}

/*	Called from Event_PlayerDeath when the assassin dies (not from another player), or is teamkilled, or suicides.
	i_Assassin: 	Index of the assassin who died.
	i_Attacker: 	Index of player who attacked them (same as i_Assassin if suicide).
	i_Assister: 	Index of player who assisted (-1 if suicide).
	id_Weapon: 		Item definition of the weapon the attacker used.
	g_DamageBits: 	Damage type.
	n_CustomKill: 	Custom kill value (eg. headshot, backstab).
	g_DeathFlags: 	Death flags (eg. Dead Ringer).
	i_Inflictor:	Entindex of inflictor.	*/
stock UsrEvent_AssassinDied(i_Assassin, i_Attacker, i_Assister, id_Weapon, g_DamageBits, n_CustomKill, g_DeathFlags, i_Inflictor)
{
	// Play the assassin killed music
	EmitSoundToAll(SND_ASSASSIN_KILLED, _, SNDCHAN_STATIC, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, i_Attacker, _, NULL_VECTOR, false, 0.0);
	
	// Assign the assassin to be someone from the opposite team to the late assassin
	switch(GetClientTeam(i_Assassin))
	{
		case TEAM_RED:
		{
			GlobalIndex(true, 0, RandomPlayerFromTeam(TEAM_BLUE));
		}
		
		case TEAM_BLUE:
		{
			GlobalIndex(true, 0, RandomPlayerFromTeam(TEAM_RED));
		}
	}
	
	// Assign the target to be someone from the late assassin's team, not excluding the late assassin
	
	GlobalIndex(true, 1, RandomPlayerFromTeam(GetClientTeam(i_Assassin)));
}

/*	Called from Event_PlayerDeath when the target is killed by the assassin.
	i_Target: 		Index of the target who died.
	i_Attacker: 	Index of the player who attacked them.
	i_Assister: 	Index of the player who assisted.
	id_Weapon: 		Item definition of the weapon the attacker used.
	g_DamageBits: 	Damage type.
	n_CustomKill: 	Custom kill value (eg. headshot, backstab).
	g_DeathFlags: 	Death flags (eg. Dead Ringer).
	i_Inflictor:	Entindex of inflictor.	*/
stock UsrEvent_TargetKilledByAssassin(i_Target, i_Attacker, i_Assister, id_Weapon, g_DamageBits, n_CustomKill, g_DeathFlags, i_Inflictor)
{
	// Play the assassin score music
	EmitSoundToAll(SND_ASSASSIN_SCORE, _, SNDCHAN_STATIC, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, i_Attacker, _, NULL_VECTOR, false, 0.0);
	
	// Calculate the points earned
	new Float:PointsEarned = ModifyScore(GetConVarFloat(cv_KillTarget), id_Weapon, g_DamageBits, n_CustomKill, g_DeathFlags, i_Inflictor);
	
	// Add the points earned to the assassin's team's counter
	TeamScore(true, false, GetClientTeam(i_Attacker), (TeamScore(false, false, GetClientTeam(i_Attacker)) + RoundFloat(PointsEarned)));
	
	// Display the points earned to the client on the HUD.
	SetHudTextParams(-1.0, 0.73, 2.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0); 
	ShowSyncHudText(i_Attacker, hs_ScorePopup, "+%d", RoundFloat(PointsEarned));
	
	// Choose a new target from the same team, not excluding the late target, adhering to LoS settings
	if ( GetConVarBool(cv_TargetLOS) )
	{
		GlobalIndex(true, 1, RandomPlayerFromTeam(GetClientTeam(i_Target), _, i_Attacker));
	}
	else
	{
		GlobalIndex(true, 1, RandomPlayerFromTeam(GetClientTeam(i_Target)));
	}
}

/*	Called from Event_PlayerDeath when the target is killed by another player.
	i_Target: 		Index of the target who died.
	i_Attacker: 	Index of the player who attacked them.
	i_Assister: 	Index of the player who assisted.
	id_Weapon: 		Item definition of the weapon the attacker used.
	g_DamageBits: 	Damage type.
	n_CustomKill: 	Custom kill value (eg. headshot, backstab).
	g_DeathFlags: 	Death flags (eg. Dead Ringer).
	i_Inflictor:	Entindex of inflictor.	*/
stock UsrEvent_TargetKilled(i_Target, i_Attacker, i_Assister, id_Weapon, g_DamageBits, n_CustomKill, g_DeathFlags, i_Inflictor)
{
	// Play target killed music
	EmitSoundToAll(SND_TARGET_KILLED, _, SNDCHAN_STATIC, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, i_Attacker, _, NULL_VECTOR, false, 0.0);
	
	// Take points from the killer's team.
	if ( i_Attacker > 0 && i_Attacker <= MaxClients && IsClientConnected(i_Attacker) && GetConVarInt(cv_TargetKillPenalty) > 0 )
	{
		new scoretoset = TeamScore(false, false, GetClientTeam(i_Attacker)) - GetConVarInt(cv_TargetKillPenalty);
		if ( scoretoset >= 0 ) TeamScore(true, false, GetClientTeam(i_Attacker), scoretoset);
		else TeamScore(true, false, GetClientTeam(i_Attacker), 0);	// If the penalty would result in a negative score, clamp to 0.
		
		// Display the points taken to the client on the HUD.
		SetHudTextParams(-1.0, 0.73, 2.0, 189, 58, 58, 255, 0, 0.0, 0.0, 0.0); 
		ShowSyncHudText(i_Attacker, hs_ScorePopup, "-%d", GetConVarInt(cv_TargetKillPenalty));
	}
	
	// Choose a new target from the same team, not excluding the late target, adhering to LoS settings
	if ( GetConVarBool(cv_TargetLOS) )
	{
		new assassin = GlobalIndex(false, 0);
		GlobalIndex(true, 1, RandomPlayerFromTeam(GetClientTeam(i_Target), _, assassin));
	}
	else
	{
		GlobalIndex(true, 1, RandomPlayerFromTeam(GetClientTeam(i_Target)));
	}
}

/*	Called from Event_PlayerDeath when the target dies (not from another player), or is teamkilled, or suicides.
	i_Target: 		Index of the target who died.
	i_Attacker: 	Index of the player who attacked them (same as i_Target if suicide).
	i_Assister: 	Index of the player who assisted (-1 if suicide).
	id_Weapon: 		Item definition of the weapon the attacker used.
	g_DamageBits: 	Damage type.
	n_CustomKill: 	Custom kill value (eg. headshot, backstab).
	g_DeathFlags: 	Death flags (eg. Dead Ringer).
	i_Inflictor:	Entindex of inflictor.	*/
stock UsrEvent_TargetDied(i_Target, i_Attacker, i_Assister, id_Weapon, g_DamageBits, n_CustomKill, g_DeathFlags, i_Inflictor)
{
	// Play target killed music
	EmitSoundToAll(SND_TARGET_KILLED, _, SNDCHAN_STATIC, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, i_Attacker, _, NULL_VECTOR, false, 0.0);
	
	// Choose a new target from the same team, excluding the late target, adhering to LoS settings
	if ( GetConVarBool(cv_TargetLOS) )
	{
		new assassin = GlobalIndex(false, 0);
		GlobalIndex(true, 1, RandomPlayerFromTeam(GetClientTeam(i_Target), i_Target, assassin));
	}
	else
	{
		GlobalIndex(true, 1, RandomPlayerFromTeam(GetClientTeam(i_Target), i_Target));
	}
}

/*	Called from Event_PlayerDeath when someone on the assassin's team kills another player.
	i_Client: 		Index of the target who died.
	i_Attacker: 	Index of the player who attacked them.
	i_Assister: 	Index of the player who assisted.
	id_Weapon: 		Item definition of the weapon the attacker used.
	g_DamageBits: 	Damage type.
	n_CustomKill: 	Custom kill value (eg. headshot, backstab).
	g_DeathFlags: 	Death flags (eg. Dead Ringer).
	i_Inflictor:	Entindex of inflictor.	*/
stock UsrEvent_AssassinTeamKillPlayer(i_Client, i_Attacker, i_Assister, id_Weapon, g_DamageBits, n_CustomKill, g_DeathFlags, i_Inflictor)
{
	// Increment the assassin's team's score counter by 1.
	if ( GlobalIndex(false, 0) > 0 && GlobalIndex(false, 0) <= MaxClients && IsClientConnected(GlobalIndex(false, 0)) )
	{
		new AssassinTeam = GetClientTeam(GlobalIndex(false, 0));
		TeamScore(true, false, AssassinTeam, (TeamScore(false, false, AssassinTeam) + 1));
		
		// Display the points earned to the client on the HUD.
		SetHudTextParams(-1.0, 0.73, 2.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0); 
		ShowSyncHudText(i_Attacker, hs_ScorePopup, "+1");
	}
}

/* ==================== /\ End Custom Event Functions /\ ==================== */

/* ==================== \/ Begin Menu Functions \/ ==================== */

/*	Displays the help panel to the client.	*/
public Action:Panel_Help(client, args)
{
	if ( g_PluginState < STATE_DISABLED )
	{	
		new Handle:panel_help = CreatePanel();
		decl String:StringBuffer[256];
		
		Format(StringBuffer, sizeof(StringBuffer), "%t%s", "as_title_help", PLUGIN_VERSION);
		SetPanelTitle(panel_help, StringBuffer);
		
		Format(StringBuffer, sizeof(StringBuffer), "%t", "as_dialogue_help");
		DrawPanelItem(panel_help, StringBuffer);
		
		SendPanelToClient(panel_help, client, Handler_Help, 20);
		CloseHandle(panel_help);
	}
	
	return Plugin_Continue;
}

public Handler_Help(Handle:panel_help, MenuAction:action, param1, param2)
{
	if ( action == MenuAction_Select ) return;
}

/*	Displays the panel at the end of the round, showing each team's final and total scores.
	Layout:
	
	==Scores==	
	Red:
	This round:
	Total:
	Blue:
	This round:
	Total:	*/
public Action:Panel_Scores(client, args)
{
	if ( g_PluginState < STATE_PLAYERS_ROUND_RESTARTING )
	{	
		new Handle:panel_scores = CreatePanel();
		decl String:StringBuffer[32];
		
		// Scores
		Format(StringBuffer, sizeof(StringBuffer), "%t", "as_score_menu_title");
		SetPanelTitle(panel_scores, StringBuffer);
		
		// This round:
		Format(StringBuffer, sizeof(StringBuffer), "%t", "as_red");
		DrawPanelItem(panel_scores, StringBuffer);
		
		// Red: <n>
		Format(StringBuffer, sizeof(StringBuffer), "%t %d", "as_this_round", TeamScore(false, false, TEAM_RED) );
		DrawPanelText(panel_scores, StringBuffer);
		
		// Blue: <n>
		Format(StringBuffer, sizeof(StringBuffer), "%t %d", "as_in_total", TeamScore(false, true, TEAM_RED) );
		DrawPanelText(panel_scores, StringBuffer);
		
		// In total:
		Format(StringBuffer, sizeof(StringBuffer), "%t", "as_blue");
		DrawPanelItem(panel_scores, StringBuffer);
		
		// Red: <n>
		Format(StringBuffer, sizeof(StringBuffer), "%t %d", "as_this_round", TeamScore(false, false, TEAM_BLUE) );
		DrawPanelText(panel_scores, StringBuffer);
		
		// Blue: <n>
		Format(StringBuffer, sizeof(StringBuffer), "%t %d", "as_in_total", TeamScore(false, true, TEAM_BLUE) );
		DrawPanelText(panel_scores, StringBuffer);
		
		SendPanelToClient(panel_scores, client, Handler_Scores, 10);
		CloseHandle(panel_scores);
	}
	
	return Plugin_Continue;
}

public Handler_Scores(Handle:panel_scores, MenuAction:action, param1, param2)
{
	if ( action == MenuAction_Select ) return;
}

/* ==================== /\ End Menu Functions /\ ==================== */

/* ==================== \/ Begin Admin Functions \/ ==================== */

#if UNSTABLE == 1
/*	Allows the assassin and target players to be changed.	*/
public Action:AdminCommand_Switch(client, args)
{
	if ( g_PluginState > 0 )
	{
		PrintToChat(client, "%t", "as_switch_states");
		return Plugin_Handled;
	}
	
	// Bring up the base switch menu.
	// From this menu, either the assassin or target sub-menu can be chosen
	// and the desired player chosen from then on.
	
	new Handle:panel_switch_init = CreatePanel();
	decl String:StringBuffer[16];
	
	// Player type
	Format(StringBuffer, sizeof(StringBuffer), "%t", "as_switch_init_menu_title");
	SetPanelTitle(panel_switch_init, StringBuffer);
	
	// Assassin
	Format(StringBuffer, sizeof(StringBuffer), "%t", "as_assassin");
	DrawPanelItem(panel_switch_init, StringBuffer);
	
	// Target
	Format(StringBuffer, sizeof(StringBuffer), "%t", "as_target");
	DrawPanelItem(panel_switch_init, StringBuffer);
	
	SendPanelToClient(panel_switch_init, client, Handler_SwitchInit, 15);
	CloseHandle(panel_switch_init);
	
	return Plugin_Handled;
}

public Handler_SwitchInit(Handle:panel, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		// Create the player menu
		new Handle:m_SwitchPlayer = BuildSwitchPlayerMenu();
		
		if ( param2 == 1 ) b_SwitchPlayerType = false;
		else if ( param2 == 2 ) b_SwitchPlayerType = true;
		
		if ( m_SwitchPlayer != INVALID_HANDLE )
		{
			DisplayMenu(m_SwitchPlayer, param1, MENU_TIME_FOREVER);
		}
	}
	else if (action == MenuAction_Cancel)
	{
		ShowActivity2(param1, "[AS]", "%t", "as_reassign_cancelled");
	}
}

/*	Builds the player menu for the switch command.	*/
Handle:BuildSwitchPlayerMenu()
{
	new Handle:menu = CreateMenu(Handler_SwitchPlayer);
	decl String:PlayerName[MAX_NAME_LENGTH + 1];
	
	SetMenuTitle(menu, "%t", "as_switch_player_menu_title");
	
	// Iterate through all our client indices.
	// If the client is valid, get their name and add it to the menu.
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientConnected(i) )
		{
			if ( GetClientTeam(i) == TEAM_RED || GetClientTeam(i) == TEAM_BLUE )
			{
				GetClientName(i, PlayerName, sizeof(PlayerName));
				AddMenuItem(menu, PlayerName, PlayerName);
			}
		}
	}
	
	return menu;
}

public Handler_SwitchPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select)
	{
		decl String:PlayerName[MAX_NAME_LENGTH + 1];
		decl String:Buffer[MAX_NAME_LENGTH + 1];
		GetMenuItem(menu, param2, PlayerName, sizeof(PlayerName));
		
		// The name of the player we want to change is now in PlayerName.
		// Find out which client index this was.
		
		for ( new i = 1; i <= MaxClients; i++ )
		{
			if ( IsClientConnected(i) )
			{
				GetClientName(i, Buffer, sizeof(Buffer));
				
				if ( StrEqual(Buffer, PlayerName) )
				{
					if ( !b_SwitchPlayerType )	// Assassin
					{
						if ( GetClientTeam(i) == TEAM_RED || GetClientTeam(i) == TEAM_BLUE )
						{
							EmitSoundToAll(SND_ASSASSIN_KILLED, _, SNDCHAN_STATIC, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, GlobalIndex(false, 0), _, NULL_VECTOR, false, 0.0);
							GlobalIndex(true, 0, i);
							
							if ( GetClientTeam(GlobalIndex(false, 0)) == GetClientTeam(GlobalIndex(false, 1)) )
							{
								GlobalIndex(true, 1, RandomPlayerFromTeam(GetClientTeam(GlobalIndex(false, 1))));
							}
							
							ShowActivity2(param1, "[AS]", "%s %t", PlayerName, "as_player_now_assassin");
							return;
						}
						else ShowActivity2(param1, "[AS]", "%t %s", "as_player_incorrect_team", PlayerName);
						return;
					}
					else	// Target
					{
						if ( GetClientTeam(i) == TEAM_RED || GetClientTeam(i) == TEAM_BLUE )
						{
							EmitSoundToAll(SND_TARGET_KILLED, _, SNDCHAN_STATIC, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, GlobalIndex(false, 1), _, NULL_VECTOR, false, 0.0);
							GlobalIndex(true, 1, i);
							
							if ( GetClientTeam(GlobalIndex(false, 0)) == GetClientTeam(GlobalIndex(false, 1)) )
							{
								GlobalIndex(true, 0, RandomPlayerFromTeam(GetClientTeam(GlobalIndex(false, 0))));
							}
							
							ShowActivity2(param1, "[AS]", "%s %t", PlayerName, "as_player_now_target");
							return;
						}
						else ShowActivity2(param1, "[AS]", "%t %s", "as_player_incorrect_team", PlayerName);
						return;
					}
				}
			}
		}
		
		ShowActivity2(param1, "[AS]", "%t", "as_player_not_found");
		
		return;
	}
	else if (action == MenuAction_Cancel)
	{
		ShowActivity2(param1, "[AS]", "%t", "as_reassign_cancelled");
		CloseHandle(menu);
		
		return;
	}
}
#endif

/* ==================== /\ End Admin Functions /\ ==================== */

/* ==================== \/ Begin Debug Functions \/ ==================== */

#if DEBUG == 1

/*	Outputs the plugin's state flags to the chat.	*/
public Action:DebugCommand_ShowFlags(client, args)
{
	if ( client > 0 && client <= MaxClients )
	{
		if ( (g_PluginState & STATE_NO_ACTIVITY) == STATE_NO_ACTIVITY )								PrintToChat(client, "STATE_NO_ACTIVITY");
		if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED )									PrintToChat(client, "STATE_DISABLED");
		if ( (g_PluginState & STATE_NOT_ENOUGH_PLAYERS) == STATE_NOT_ENOUGH_PLAYERS )				PrintToChat(client, "STATE_NOT_ENOUGH_PLAYERS");
		if ( (g_PluginState & STATE_PLAYERS_ROUND_RESTARTING) == STATE_PLAYERS_ROUND_RESTARTING )	PrintToChat(client, "STATE_PLAYERS_ROUND_RESTARTING");
		if ( (g_PluginState & STATE_NOT_IN_ROUND) == STATE_NOT_IN_ROUND )							PrintToChat(client, "STATE_NOT_IN_ROUND");
		if ( g_PluginState == 0 )																	PrintToChat(client, "No flags set.");
	}
	else if ( client == 0 )
	{
		if ( (g_PluginState & STATE_NO_ACTIVITY) == STATE_NO_ACTIVITY )								LogMessage("STATE_NO_ACTIVITY");
		if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED )									LogMessage("STATE_DISABLED");
		if ( (g_PluginState & STATE_NOT_ENOUGH_PLAYERS) == STATE_NOT_ENOUGH_PLAYERS )				LogMessage("STATE_NOT_ENOUGH_PLAYERS");
		if ( (g_PluginState & STATE_PLAYERS_ROUND_RESTARTING) == STATE_PLAYERS_ROUND_RESTARTING )	LogMessage("STATE_PLAYERS_ROUND_RESTARTING");
		if ( (g_PluginState & STATE_NOT_IN_ROUND) == STATE_NOT_IN_ROUND )							LogMessage("STATE_NOT_IN_ROUND");
		if ( g_PluginState == 0 )																	LogMessage("No flags set.");
	}
}

/*	Outputs the plugin's global indices to the chat.	*/
public Action:DebugCommand_CheckIndices(client, args)
{
	decl String:assassin_name[MAX_NAME_LENGTH + 1];
	decl String:target_name[MAX_NAME_LENGTH + 1];
	GetClientName(GlobalIndex(false, 0), assassin_name, sizeof(assassin_name));
	GetClientName(GlobalIndex(false, 1), target_name, sizeof(target_name));
	
	if ( client > 0 && client <= MaxClients )
	{
		PrintToChat(client, "Assassin: %d (%s)", GlobalIndex(false, 0), assassin_name);
		PrintToChat(client, "Target: %d (%s)", GlobalIndex(false, 1), target_name);
	}
	else if ( client == 0 )
	{
		LogMessage("Assassin: %d (%s)", GlobalIndex(false, 0), assassin_name);
		LogMessage("Target: %d (%s)", GlobalIndex(false, 1), target_name);
	}
}

/*	Displays some text at the specified position on the HUD.	*/
public Action:DebugCommand_HUDText(client, args)
{
	if ( client < 1 || client > MaxClients || !IsClientConnected(client) ) return Plugin_Handled;
	
	if ( args < 2 )
	{
		PrintToChat(client, "2 arguments needed! <x> <y>");
		return Plugin_Handled;
	}
	
	new String:arg[8];
	GetCmdArg(1, arg, sizeof(arg));
	new Float:xpos = StringToFloat(arg);
	GetCmdArg(2, arg, sizeof(arg));
	new Float:ypos = StringToFloat(arg);
	
	SetHudTextParams(xpos, ypos, 1.0, 255, 255, 255, 255, 0, 0.0, 0.0, 0.0); 
	ShowSyncHudText(client, hs_ScorePopup, "+1");
	
	return Plugin_Handled;
}

#endif
/* ==================== /\ End Debug Functions /\ ==================== */