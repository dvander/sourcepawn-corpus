// Fourth re-write of the Assassination plugin.

/*
	Recent changes:
	- Changed verbose debug to be enabled via nfas_debug (default 0) rather than requiring a plugin recompile.
		- Different debug messages will be output to the server console depending on the value of nfas_debug. The ConVar value is taken
		as a bitflag value: simply add together the values of the debug flags you wish to log information for and put the total value
		into the ConVar. To see the different possible flag values in the console, use the nfas_debugflags command.
	
	- Added admin commands nfas_assassin and nfas_target for changing the assassin or target. They can be used in the following ways:
		- Typing nfas_assassin/target in the console (or preceded by ! or / in chat), followed by either a user ID or a player name, will
		attempt to assign the assassin/target as that player. If specifying a player name, enclose it in speech marks: "Player Name".
		Passing no argument will bring up a menu from which a player can be chosen.
		- If the player who will become the assassin is on the same team as the current target then the target will be chosen as a new random
		player, or vice-versa. Points are not awarded to any team when the assassin or target is forcibly changed.
*/

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <keyvalues>

#define DEBUGFLAG_GENERAL			1		// General debugging.
#define DEBUGFLAG_INDICES			2		// Logging when the global indices change.
#define DEBUGFLAG_RANDOMPLAYER		4		// Logging when fetching a random player.
#define DEBUGFLAG_TEAMCHANGE		8		// Logging when a player changes team.
#define DEBUGFLAG_ASSASSINCOND		16		// Logging when the assassin condition timer is created or destroyed.
#define DEBUGFLAG_DEATH				32		// Logging when the assassin, target, etc. dies.
#define DEBUGFLAG_IDINDEX			64		// Logging finding an item definition index.
#define DEBUGFLAG_WEAPONMODIFIERS	128		// Logging the weapon modifiers tasks.
#define DEBUGFLAG_MODIFYSCORE		256		// Logging the score modifier tasks.
#define DEBUGFLAG_OBJECTIVES		512		// Logging disabling of objectives.
#define DEBUGFLAG_COLOUR			1024	// Logging of colour tinting.

#define DEBUGFLAG_MAX				1024
#define DEBUGFLAG_MAX_FL			1024.0

#define DISABLED	1	// Any code with #if DISABLED == 0 around it will not get compiled. This allows us to block out code even with /* */ in it.

//#define DEBUG						0

// Plugin defines
#define PLUGIN_NAME			"Nightfire: Assassination"
#define PLUGIN_AUTHOR		"[X6] Herbius"
#define PLUGIN_DESCRIPTION	"Team deathmatch; become the assassin to gain points."
#define PLUGIN_VERSION		"1.1.2.48"
#define PLUGIN_URL			"http://forums.alliedmods.net/showthread.php?p=1531506"
// Note: I don't update this religiously on builds. :P There have been AT LEAST this many builds.

// Team integers
#define TEAM_INVALID		-1
#define TEAM_UNASSIGNED		0
#define TEAM_SPECTATOR		1
#define TEAM_RED			2
#define TEAM_BLUE			3

// State flags
#define STATE_DISABLED		2	// Plugin is disabled via ConVar.
#define STATE_NOT_IN_ROUND	1	// A round is not in progress. This flag is set on MapEnd, RoundWin or RoundStalemate and reset on RoundStart.

#define ICON_OFFSET		75.0

// Building type flags:
#define BUILDING_SENTRY		1
#define BUILDING_DISPENSER	2
#define BUILDING_TELEPORTER	4

// Cleanup modes
#define CLEANUP_ROUNDSTART	0
#define CLEANUP_ROUNDWIN	1
#define CLEANUP_MAPSTART	2
#define CLEANUP_MAPEND		3
#define CLEANUP_PLAYERSPAWN	4

// Sounds
#define SND_ASSASSIN_KILLED					"assassination/assassin_killed.mp3"					// Sound when the assassin is killed by a player.
#define SND_ASSASSIN_KILLED_BY_TARGET		"assassination/assassin_killed_by_target.mp3"		// Sound when the assassin is killed by the target.
#define SND_ASSASSIN_SCORE					"assassination/assassin_score.mp3"					// Sound when the assassin kills the target.
#define SND_TARGET_KILLED					"assassination/target_killed.mp3"					// Sound when the assassin kills the target.

// Sprites
//#define ASSASSIN_SPRITE_PATH	"materials/assassination/assassin_sprite"	// Path to the assassin sprite (excluding extension).
//#define TARGET_SPRITE_PATH		"materials/assassination/target_sprite"		// Path to the target sprite (excluding extension).

// Global variables
new g_PluginState;				// Holds the global state of the plugin.
new GlobalIndex[2];				// Index 0 is the assassin, 1 is the target.
new GlobalScore[4];				// 0/1 = Red/Blue total, 2/3 = Red/Blue current.
//new SpriteIndex[4] = {-1, ...};	// 0 = assassin sprite, 1 = target sprite, 2/3 = assigned players.
new DisconnectIndex;			// If a player disconnects, this will hold their indx for use in TeamsChange.

// ConVar handle declarations
new Handle:cv_PluginEnabled = INVALID_HANDLE;			// Enables or disables the plugin. Changing this while in-game will restart the map.
new Handle:cv_MaxScore = INVALID_HANDLE;				// When this score is reached, the round will end.
new Handle:cv_KillAssassin = INVALID_HANDLE;			// The base amount of points the target gets for killing the assassin.
new Handle:cv_KillTarget = INVALID_HANDLE;				// The base amount of points the assassin gets for killing the target.
new Handle:cv_HeadshotMultiplier = INVALID_HANDLE;		// Score multiplier for headshots. Applied on top of the weapon modifier.
new Handle:cv_BackstabMultiplier = INVALID_HANDLE;		// Score multiplier for backstabs. Applied on top of the weapon modifier.
new Handle:cv_ReflectMultiplier = INVALID_HANDLE;		// Score multiplier for reflected projectiles. Applied on top of the weapon modifier.
new Handle:cv_SentryL1Multiplier = INVALID_HANDLE;		// Score multiplier for level 1 sentries.
new Handle:cv_SentryL2Multiplier = INVALID_HANDLE;		// Score multiplier for level 2 sentries.
new Handle:cv_SentryL3Multiplier = INVALID_HANDLE;		// Score multiplier for level 3 sentries.
new Handle:cv_TelefragMultiplier = INVALID_HANDLE;		// Score multiplier for telefrags.
new Handle:cv_SpawnProtection = INVALID_HANDLE;			// How long, in seconds, a player is protected from damage after they spawn.
new Handle:cv_TargetTakeDamage = INVALID_HANDLE;		// If the target is hurt by an ordinary player, they will only take this fraction of the damage (between 0.1 and 1).
//new Handle:cv_AssassinTakeDamage = INVALID_HANDLE;		// When the assassin is hurt, the damage they take will be multiplied by this value.
new Handle:cv_MedicPoints = INVALID_HANDLE;				// If a Medic gains points from an assist on a target kill, the points awarded will be multiplied by this value.
new Handle:cv_CustomColours = INVALID_HANDLE;			// If 1, the assassin and target will be coloured according to custom ConVars instead of using their team's colour.
new Handle:cv_AssassinRed = INVALID_HANDLE;				// Red value of the colour to tint the assassin.
new Handle:cv_AssassinGreen = INVALID_HANDLE;			// Green value of the colour to tint the assassin.
new Handle:cv_AssassinBlue = INVALID_HANDLE;			// Blue value of the colour to tint the assassin.
new Handle:cv_TargetRed = INVALID_HANDLE;				// Red value of the colour to tint the target.
new Handle:cv_TargetGreen = INVALID_HANDLE;				// Green value of the colour to tint the target.
new Handle:cv_TargetBlue = INVALID_HANDLE;				// Blue value of the colour to tint the target.
new Handle:cv_Debug = INVALID_HANDLE;						// Holds the bitflag value for debug messages that should be output to the server console. See nfas_showdebugflags for more information.

// Timer handle declarations
new Handle:timer_AssassinCondition = INVALID_HANDLE;	// Handle to our timer that refreshes the buffed state on the assassin. Created on MapStart/PluginStart and killed on MapEnd.
new Handle:timer_MedicHealBuff = INVALID_HANDLE;		// Handle to our timer to refresh the buffed state on assassin Medics' heal targets. Created same as above.
new Handle:timer_HUDMessageRefresh = INVALID_HANDLE;	// Handle to our HUD refresh timer.
new Handle:timer_HUDScoreRefresh = INVALID_HANDLE;

// Hud syncs
new Handle:hs_Assassin = INVALID_HANDLE;				// Handle to our HUD synchroniser for displaying who is the assassin.
new Handle:hs_Target = INVALID_HANDLE;					// Handle to our HUD synchroniser for displaying who is the target.
new Handle:hs_Score = INVALID_HANDLE;					// Handle to our HUD synchroniser for displaying scores.

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	LogMessage("--++==Assassination Mode started. Version: %s==++--", PLUGIN_VERSION);
	
	//#if DEBUG > 0
	//LogMessage("This compile is not final. Please disable DEBUG before releasing.");
	//#endif
	
	LoadTranslations("assassination/assassination_phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("core.phrases");
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
	
	cv_Debug  = CreateConVar("nfas_debug",
												"0",
												"Holds the bitflag value for debug messages that should be output to the server console. See nfas_debugflags for more information.",
												FCVAR_PLUGIN | FCVAR_NOTIFY,
												true,
												0.0);
	
	cv_MaxScore  = CreateConVar("nfas_score_max",
												"100",
												"When this score is reached, the round will end.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												1.0);
	
	cv_KillAssassin  = CreateConVar("nfas_kill_assassin_score",
												"7",
												"The base amount of points the target gets for killing the assassin.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0);
	
	cv_KillTarget  = CreateConVar("nfas_kill_target_score",
												"10",
												"The base amount of points the assassin gets for killing the target.",
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
												
	cv_SpawnProtection  = CreateConVar("nfas_spawn_protection_length",
												"3.0",
												"How long, in seconds, a player is protected from damage after they spawn.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												10.0);
	
	cv_TargetTakeDamage  = CreateConVar("nfas_target_damage_modifier",
												"0.5",
												"If the target is hurt by an ordinary player, they will only take this fraction of the damage (between 0.1 and 1).",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.1,
												true,
												1.0);
	
	/*cv_AssassinTakeDamage  = CreateConVar("nfas_assassin_damage_modifier",
												"1.0",
												"When the assassin is hurt, the damage they take will be multiplied by this value. Minimum 1.0",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												1.0);*/
	
	cv_MedicPoints  = CreateConVar("nfas_medic_assist_score_modifier",
												"0.5",
												"If a Medic gains points from an assist on a target kill, the points awarded will be multiplied by this value.",
												FCVAR_PLUGIN | FCVAR_NOTIFY | FCVAR_ARCHIVE,
												true,
												0.1,
												true,
												1.0);
	
	cv_CustomColours  = CreateConVar("nfas_colours_custom",
												"0",
												"If 1, the assassin and target will be coloured according to custom ConVars instead of using their team's colour.",
												FCVAR_PLUGIN | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												1.0);
	
	cv_AssassinRed  = CreateConVar("nfas_colour_assassin_red",
												"255",
												"Red value of the colour to tint the assassin.",
												FCVAR_PLUGIN | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												255.0);
	
	cv_AssassinGreen  = CreateConVar("nfas_colour_assassin_green",
												"0",
												"Green value of the colour to tint the assassin.",
												FCVAR_PLUGIN | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												255.0);
	
	cv_AssassinBlue  = CreateConVar("nfas_colour_assassin_blue",
												"0",
												"Blue value of the colour to tint the assassin.",
												FCVAR_PLUGIN | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												255.0);
	
	cv_TargetRed  = CreateConVar("nfas_colour_target_red",
												"0",
												"Red value of the colour to tint the Target.",
												FCVAR_PLUGIN | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												255.0);
	
	cv_TargetGreen  = CreateConVar("nfas_colour_target_green",
												"0",
												"Green value of the colour to tint the Target.",
												FCVAR_PLUGIN | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												255.0);
	
	cv_TargetBlue  = CreateConVar("nfas_colour_target_blue",
												"255",
												"Blue value of the colour to tint the Target.",
												FCVAR_PLUGIN | FCVAR_ARCHIVE,
												true,
												0.0,
												true,
												255.0);
	
	// Hooks:
	HookConVarChange(cv_PluginEnabled,	CvarChange);
	HookConVarChange(cv_CustomColours, CvarChange);
	
	HookEventEx("teamplay_round_start",		Event_RoundStart,		EventHookMode_Post);
	HookEventEx("teamplay_round_win",		Event_RoundWin,			EventHookMode_Post);
	HookEventEx("teamplay_round_stalemate",	Event_RoundStalemate,	EventHookMode_Post);
	HookEventEx("player_spawn",				Event_PlayerSpawn,		EventHookMode_Post);
	HookEventEx("player_team",				Event_TeamsChange,		EventHookMode_Post);
	HookEventEx("player_disconnect",			Event_Disconnect,		EventHookMode_Post);
	HookEventEx("player_death",				Event_PlayerDeath,		EventHookMode_Post);
	HookEventEx("player_hurt",				Event_PlayerHurt,		EventHookMode_Post);
	
	RegConsoleCmd("say", Command_Say);
	
	RegConsoleCmd("nfas_checkindices",	Cmd_CheckIndices,	"Outputs the global indices to the client's console.");
	RegConsoleCmd("nfas_debugflags",		Cmd_ShowDebugFlags,	"Outputs debug flag dsescriptions and values to the console, or toggles flag values in nfas_debug.");
	RegConsoleCmd("nfas_help",			Cmd_Help,				"Displays help info.");
	RegAdminCmd("nfas_assassin",			Cmd_ChangeAssassin,	ADMFLAG_SLAY,	"Assigns the chosen player as the Assassin.");
	RegAdminCmd("nfas_target",			Cmd_ChangeTarget,	ADMFLAG_SLAY,	"Assigns the chosen player as the Target.");
	
	// Parse the weapon modifiers file
	WeaponModifiers(false);
	
	// Only continue on from this point if the round is already being played.
	if ( !IsServerProcessing() ) return;
	
	// End the current round.
	RoundWin(TEAM_UNASSIGNED);
	
	if ( timer_AssassinCondition == INVALID_HANDLE )
	{
		timer_AssassinCondition = CreateTimer(0.5, TimerAssassinCondition, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		
		/*#if (DEBUG & DEBUGFLAG_ASSASSINCOND) == DEBUGFLAG_ASSASSINCOND
		LogMessage("Assassin cond timer created on plugin start.");
		#endif*/
	}
	/*#if (DEBUG & DEBUGFLAG_ASSASSINCOND) == DEBUGFLAG_ASSASSINCOND
	else
	{
		LogMessage("Assassin cond timer is not INVALID_HANDLE on plugin start. This is probably a weird error!");
	}
	#endif*/
	
	if ( timer_MedicHealBuff == INVALID_HANDLE )
	{
		timer_MedicHealBuff = CreateTimer(0.25, TimerMedicHealBuff, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if ( hs_Assassin == INVALID_HANDLE )
	{
		hs_Assassin = CreateHudSynchronizer();
	}
	
	if ( hs_Target == INVALID_HANDLE )
	{
		hs_Target = CreateHudSynchronizer();
	}
	
	if ( hs_Score == INVALID_HANDLE )
	{
		hs_Score = CreateHudSynchronizer();
	}
	
	if ( hs_Assassin != INVALID_HANDLE && hs_Target != INVALID_HANDLE )	// If the above was successful:
	{
		UpdateHUDMessages(GlobalIndex[0], GlobalIndex[1]);	// Update the HUD
		timer_HUDMessageRefresh = CreateTimer(1.0, TimerHUDRefresh, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	// Set up the timer to next update the HUD.
	}
	
	if ( hs_Score != INVALID_HANDLE )	// If the above was successful:
	{
		UpdateHUDScore(GlobalScore[0], GlobalScore[1], GlobalScore[2], GlobalScore[3]);	// Update the HUD
		timer_HUDScoreRefresh = CreateTimer(1.0, TimerHUDScoreRefresh, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	// Set up the timer to next update the HUD.
	}
}

/*public Action:OnGetGameDescription(String:gameDesc[64])
{
	if ( (g_PluginState & STATE_DISABLED) != STATE_DISABLED )
	{
		Format(gameDesc, sizeof(gameDesc), "%s v%s", PLUGIN_NAME, PLUGIN_VERSION);
		return Plugin_Changed;
	}
	else return Plugin_Continue;
}*/

public Action:Command_Say(client, args)
{
	new String:text[192];
	GetCmdArgString(text, sizeof(text));
 
	new startidx = 0;
	if (text[0] == '"')
	{
		startidx = 1;
		/* Strip the ending quote, if there is one */
		new len = strlen(text);
		if (text[len-1] == '"')
		{
			text[len-1] = '\0';
		}
	}
	
	new Action:ReturnValue = Plugin_Continue;
	if ( text[startidx] == '/' ) ReturnValue = Plugin_Handled;
 
	if ( StrEqual(text[startidx+1], "nfas_help") )
	{
		Cmd_Help(client, args);
		return ReturnValue;
	}
 
	/* Let say continue normally */
	return Plugin_Continue;
}

// ================================
// ====== Enabling/Disabling ======
// ================================

/*	Checks which ConVar has changed and does the relevant things.	*/
public CvarChange( Handle:convar, const String:oldValue[], const String:newValue[] )
{
	// If the enabled/disabled convar has changed, run PluginStateChanged
	if ( convar == cv_PluginEnabled ) PluginEnabledStateChanged(GetConVarBool(cv_PluginEnabled));
	else if ( convar == cv_CustomColours ) TintPlayers();
}

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
	
	// Get the current map name
	decl String:mapname[64];
	GetCurrentMap(mapname, sizeof(mapname));
	LogMessage("[AS] Plugin state changed. Restarting map (%s)...", mapname);
	
	// Restart the map	
	ForceChangeLevel(mapname, "Nightfire Assassinaion enabled state changed, requires map restart.");
}

// ================================
// ============ Hooks =============
// ================================

/* Parses our chat commands.	*/
/*public Action:Command_Say(client, args)
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
	
	// When we return a value, Plugin_Continue will allow the chat text to appear on the screen
	// while Plugin_Handled will block it. If the command begins with '/', this value will be set
	// to Plugin_Handled so that when we return the chat command will not publicly display.
	new Action:ReturnValue = Plugin_Continue;
	if ( text[startidx] == '/' ) ReturnValue = Plugin_Handled;
 
	if ( StrEqual(text[startidx], "/nfas_help") )
	{
		Panel_Help(client, 0);
		return ReturnValue;
	}
 
	// Let say continue normally
	return Plugin_Continue;
}*/

public OnMapStart()
{
	// Set the NOT_IN_ROUND flag.
	g_PluginState |= STATE_NOT_IN_ROUND;
	
	Cleanup(CLEANUP_MAPSTART);
	
	// Start precaching here.
	decl String:SoundBuffer[128];	// Precache the sounds and add them to the download table.
	
	Format(SoundBuffer, sizeof(SoundBuffer), "sound/%s", SND_ASSASSIN_KILLED);
	AddFileToDownloadsTable(SoundBuffer);
	PrecacheSound(SND_ASSASSIN_KILLED, true);
	
	Format(SoundBuffer, sizeof(SoundBuffer), "sound/%s", SND_ASSASSIN_KILLED_BY_TARGET);
	AddFileToDownloadsTable(SoundBuffer);
	PrecacheSound(SND_ASSASSIN_KILLED_BY_TARGET, true);
	
	Format(SoundBuffer, sizeof(SoundBuffer), "sound/%s", SND_ASSASSIN_SCORE);
	AddFileToDownloadsTable(SoundBuffer);
	PrecacheSound(SND_ASSASSIN_SCORE, true);
	
	Format(SoundBuffer, sizeof(SoundBuffer), "sound/%s", SND_TARGET_KILLED);
	AddFileToDownloadsTable(SoundBuffer);
	PrecacheSound(SND_TARGET_KILLED, true);
	
	if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return;
}

public OnMapEnd()
{
	// Set the NOT_IN_ROUND flag.
	g_PluginState |= STATE_NOT_IN_ROUND;
	
	Cleanup(CLEANUP_MAPEND);
	
	if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return;
}

/*	Called when a round starts.	*/
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Player_spawn is called before teamplay_round_start!
	
	// Clear the NOT_IN_ROUND flag.
	g_PluginState &= ~STATE_NOT_IN_ROUND;
	
	Cleanup(CLEANUP_ROUNDSTART);
	
	if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return;
	
	DisableObjectives();
	AssignBestIndices();
}

/*	Called when a round is won.	*/
public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Set the NOT_IN_ROUND flag.
	g_PluginState |= STATE_NOT_IN_ROUND;
	
	Cleanup(CLEANUP_ROUNDWIN);
	
	if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return;
	
	GlobalScore[0] += GlobalScore[TEAM_RED];
	GlobalScore[1] += GlobalScore[TEAM_BLUE];
	
	// Display total scores to clients via a panel
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame(i) )
		{
			Panel_Scores(i, 0);
		}
	}
}

/*	Called when a round is drawn.	*/
public Event_RoundStalemate(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Set the NOT_IN_ROUND flag.
	g_PluginState |= STATE_NOT_IN_ROUND;
	
	Cleanup(CLEANUP_ROUNDWIN);
	
	if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return;
	
	GlobalScore[0] += GlobalScore[TEAM_RED];
	GlobalScore[1] += GlobalScore[TEAM_BLUE];
	
	// Display total scores to clients via a panel
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame(i) )
		{
			Panel_Scores(i, 0);
		}
	}
}

/*	Called when a player spawns.	*/
public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (	(g_PluginState & STATE_DISABLED)		== STATE_DISABLED		||
			(g_PluginState & STATE_NOT_IN_ROUND)	== STATE_NOT_IN_ROUND  )
	{
		Cleanup(CLEANUP_PLAYERSPAWN);
		
		if ( (GetConVarInt(cv_Debug) & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
		{
			LogMessage("Spawn: Reset indices to 0; plugin disabled or not in round.");
		}
		
		return;
	}
	
	AssignBestIndices();
	
	if ( GetConVarFloat(cv_SpawnProtection) > 0.0 )
	{
		TF2_AddCondition(GetClientOfUserId(GetEventInt(event, "userid")), TFCond_Ubercharged, GetConVarFloat(cv_SpawnProtection));
	}
}

/*	Called when a player is hurt.	*/
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if ( g_PluginState > 0 ) return;
	
	new ph_ClientIndex = GetClientOfUserId(GetEventInt(event, "userid"));		// Index of the client who was hurt.
	new ph_AttackerIndex = GetClientOfUserId(GetEventInt(event, "attacker"));	// Index of the client who fired the shot.
	new ph_ClientHealth = GetEventInt(event, "health");							// How much health the injured player now has.
	new ph_ClientDamage = GetEventInt(event, "damageamount");					// The amount of damage the injured player took.
	
	// The target was hit by someone who wasn't the assassin.
	// If the damage taken was from an ordinary player, and it didn't kill them, give the target back half of the damage done
	// (rounded down).
	if ( ph_ClientIndex == GlobalIndex[1] && !TF2_IsPlayerInCondition(ph_ClientIndex, TFCond_Overhealed)
			&& ph_AttackerIndex > 0 && ph_AttackerIndex <= MaxClients && ph_AttackerIndex != GlobalIndex[0] && ph_ClientHealth > 0  )
	{
		new Float:f_healthtoset = float(ph_ClientHealth) + (float(ph_ClientDamage) * (1.0 - GetConVarFloat(cv_TargetTakeDamage)));
		SetEntProp(ph_ClientIndex, Prop_Data, "m_iHealth", RoundToFloor(f_healthtoset));
		
		// Immediately mark the health value as changed.
		ChangeEdictState(ph_ClientIndex, GetEntSendPropOffs(ph_ClientIndex, "m_iHealth"));
	}
	
	// The assassin was hit by someone.
	// Take away an extra fraction of the damage dealt.
	/*if ( ph_ClientIndex == GlobalIndex[0] && ph_ClientHealth > 0 )
	{
		if ( GetConVarFloat(cv_AssassinTakeDamage) > 1.0 )
		{
			new Float:f_healthtoset = float(ph_ClientHealth) - ((GetConVarFloat(cv_AssassinTakeDamage) - 1.0) * ph_ClientDamage);
			SetEntProp(ph_ClientIndex, Prop_Data, "m_iHealth", RoundToFloor(f_healthtoset));
			
			// Immediately mark the health value as changed.
			ChangeEdictState(ph_ClientIndex, GetEntSendPropOffs(ph_ClientIndex, "m_iHealth"));
		}
	}*/
}

/*	Called when a player disconnects.
	This is called BEFORE TeamsChange below.*/
public Event_Disconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	DisconnectIndex = GetClientOfUserId(GetEventInt(event, "userid"));
}

/*	Called when a player changes team.	*/
public Event_TeamsChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	// Player spawn will deal with assigning the assassin or target.
	// Here we need to check whether the player who is changing team is the assassin or target.
	
	new tc_ClientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	new tc_NewTeamID = GetEventInt(event, "team");
	new tc_OldTeamID = GetEventInt(event, "oldteam");
	
	new tc_RedTeamCount = GetTeamClientCount(TEAM_RED);		// These will give us the team counts BEFORE the client has switched.
	new tc_BlueTeamCount = GetTeamClientCount(TEAM_BLUE);
	
	new g_debug = GetConVarInt(cv_Debug);
	
	// Since the team change event is ALWAYS called like a pre (thanks, Valve), we need to build up a picture of what
	// the teams will look like after the switch.
	
	if ( GetEventBool(event, "disconnect") ) 	// If the team change happened because the client was disconnecting:
	{
		// Note that, if disconnect == true, the userid will point to the index 0.
		// We fix this here.
		tc_ClientIndex = DisconnectIndex;	// This is retrieved from player_disconnect, which is fired before player_team.
		DisconnectIndex = 0;
		
		if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
		{
			LogMessage("TC: Player %d is disconnecting.", tc_ClientIndex);
		}
		
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
		if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
		{
			LogMessage("TC: Player %N is not disconnecting.", tc_ClientIndex);
		}
		
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
	
	if ( tc_ClientIndex > 0 && tc_ClientIndex == GlobalIndex[1] )	// If the client was the target:
	{
		if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
		{
			LogMessage("TC: Player %d is the target.", tc_ClientIndex);
		}
		
		// If there will not be enough players on a team after the change, set both indices to 0.
		if ( tc_RedTeamCount < 1 || tc_BlueTeamCount < 1 )
		{
			GlobalIndex[0] = 0;
			GlobalIndex[1] = 0;
			TintPlayers();
			
			if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
			{
				LogMessage("TC: All indices set to 0.", tc_ClientIndex);
			}
		}
		else	// Otherwise, the team counts are acceptable.
		{
			if ( GlobalIndex[0] > 0 && GlobalIndex[0] <= MaxClients && IsClientInGame(GlobalIndex[0]) )	// If the assassin is valid, choose the other team.
			{
				new AssassinTeam = GetClientTeam(GlobalIndex[0]);
				
				switch (AssassinTeam)
				{
					case TEAM_RED:
					{
						GlobalIndex[1] = RandomPlayerFromTeam(TEAM_BLUE, tc_ClientIndex);
						TintPlayers();
						// Ignore the changing client since they will still be on the team at this point.
						
						if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
						{
							LogMessage("TC: Target is %N", GlobalIndex[1]);
						}
					}
					
					case TEAM_BLUE:
					{
						GlobalIndex[1] = RandomPlayerFromTeam(TEAM_RED, tc_ClientIndex);
						TintPlayers();
						
						if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
						{
							LogMessage("TC: Target is %N", GlobalIndex[1]);
						}
					}
				}
			}
			else	// If the assassin isn't valid, choose at random.
			{
				new RandomTeam = GetRandomInt(TEAM_RED, TEAM_BLUE);
				GlobalIndex[1] = RandomPlayerFromTeam(RandomTeam, tc_ClientIndex);
				TintPlayers();
				
				if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
				{
					LogMessage("TC: Target is %N", GlobalIndex[1]);
				}
			}
		}
	}
	else if ( tc_ClientIndex > 0 && tc_ClientIndex == GlobalIndex[0] )	// If the client was the assassin:
	{
		if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
		{
			LogMessage("TC: Player %d is the assassin.", tc_ClientIndex);
		}
		
		// If there will not be enough players on a team after the change, set both indices to 0.
		if ( tc_RedTeamCount < 1 || tc_BlueTeamCount < 1 )
		{
			GlobalIndex[0] = 0;
			GlobalIndex[1] = 0;
			TintPlayers();
			
			if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
			{
				LogMessage("TC: All indices set to 0.", tc_ClientIndex);
			}
		}
		else	// Otherwise, the team counts are acceptable.
		{
			if ( GlobalIndex[0] > 0 && GlobalIndex[0] <= MaxClients && IsClientInGame(GlobalIndex[1]) )	// If the target is valid, choose the other team.
			{
				new TargetTeam = GetClientTeam(GlobalIndex[1]);
				
				switch (TargetTeam)
				{
					case TEAM_RED:
					{
						GlobalIndex[0] = RandomPlayerFromTeam(TEAM_BLUE, tc_ClientIndex);
						TintPlayers();
						
						if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
						{
							LogMessage("TC: Assassin is %N", GlobalIndex[1]);
						}
					}
					
					case TEAM_BLUE:
					{
						GlobalIndex[0] = RandomPlayerFromTeam(TEAM_RED, tc_ClientIndex);
						TintPlayers();
						
						if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
						{
							LogMessage("TC: Assassin is %N", GlobalIndex[1]);
						}
					}
				}
			}
			else	// If the target isn't valid, choose at random.
			{
				new RandomTeam = GetRandomInt(TEAM_RED, TEAM_BLUE);
				GlobalIndex[0] = RandomPlayerFromTeam(RandomTeam, tc_ClientIndex);
				TintPlayers();
				
				if ( (g_debug & DEBUGFLAG_TEAMCHANGE) == DEBUGFLAG_TEAMCHANGE )
				{
					LogMessage("TC: Assassin is %N", GlobalIndex[1]);
				}
			}
		}
	}
}

/*	Called when a player changes team.	*/
public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// We need a robust system for managing what happens when a player dies.
	// OnAssassinDeath will manage when the assassin dies,
	// OnTargetDeath will manage when the target dies, and
	// OnAssassinEnemyDeath will manage when a player on the opposite team to the assassin dies.
	// Each handler function will act differently depending on how many people are on each team
	// and which indices are currently valid.
	
	// If there are ANY abnormal states, don't go through all the crap below.
	if ( g_PluginState > 0 ) return;
	
	decl DeathEvents[11];
	
	DeathEvents[0] = GetEventInt(event, "userid");					// This is the user ID of the player who died.
	DeathEvents[1] = GetEventInt(event, "victim_entindex");			// ???
	DeathEvents[2] = GetEventInt(event, "inflictor_entindex");		// Entindex of the inflictor. This could be a weapon, sentry, projectile, etc.
	DeathEvents[3] = GetEventInt(event, "attacker");				// User ID of the attacker.
	DeathEvents[4] = GetEventInt(event, "weaponid");				// Weapon ID the attacker used.
	DeathEvents[5] = GetEventInt(event, "damagebits");				// Bitflags of the damage dealt.
	DeathEvents[6] = GetEventInt(event, "customkill");				// Custom kill value (headshot, etc.).
	DeathEvents[7] = GetEventInt(event, "assister");				// User ID of the assister.
	DeathEvents[8] = GetEventInt(event, "stun_flags");				// Bitflags of the user's stunned state before death.
	DeathEvents[9] = GetEventInt(event, "death_flags");				// Bitflags describing the type of death.
	DeathEvents[10] = GetEventInt(event, "playerpenetratecount");	// ??? To do with new penetration weapons?
	
	decl String:Weapon[32], String:WeaponLogClassname[32];
	GetEventString(event, "weapon", Weapon, sizeof(Weapon));										// Weapon name.
	GetEventString(event, "weapon_logclassname", WeaponLogClassname, sizeof(WeaponLogClassname));	// Weapon that should be printed to the log.
	
	new bool:SilentKill = GetEventBool(event, "silent_kill");
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if ( client < 1 ) return;
	
	// The assassin has died.
	if ( client == GlobalIndex[0] )
	{
		OnAssassinDeath(DeathEvents, sizeof(DeathEvents), Weapon, WeaponLogClassname, SilentKill);
	}
	
	// The target has died.
	else if ( client == GlobalIndex[1] )
	{
		OnTargetDeath(DeathEvents, sizeof(DeathEvents), Weapon, WeaponLogClassname, SilentKill);
	}
	
	// A player on the opposite team to the assassin has died.
	else if ( GlobalIndex[0] > 0 && GlobalIndex[0] <= MaxClients && IsClientInGame(GlobalIndex[0]) )
	{
		if ( GetClientTeam(client) == TEAM_RED && GetClientTeam(GlobalIndex[0]) == TEAM_BLUE )
		{
			OnAssassinEnemyDeath(DeathEvents, sizeof(DeathEvents), Weapon, WeaponLogClassname, SilentKill);
		}
		else if ( GetClientTeam(client) == TEAM_BLUE && GetClientTeam(GlobalIndex[0]) == TEAM_RED )
		{
			OnAssassinEnemyDeath(DeathEvents, sizeof(DeathEvents), Weapon, WeaponLogClassname, SilentKill);
		}
	}
	
	if ( TF2_GetPlayerClass(GetClientOfUserId(DeathEvents[0])) == TFClass_Engineer )	// If the player who died was an Engineer, kill their sentry.
	{
		KillBuildings(GetClientOfUserId(DeathEvents[0]), BUILDING_SENTRY);
	}
	
	// After doing all the stuff, check the scores.
	CheckScoresAgainstMax();
}

/*	Called when the assassin dies.	*/
stock OnAssassinDeath(EventArray[], size, String:Weapon[], String:WeaponLogClassname[], bool:SilentKill)
{
	new g_debug = GetConVarInt(cv_Debug);
	
	if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
	{
		LogMessage("Assassin %N has died.", GetClientOfUserId(EventArray[0]));
	}
	
	// If either team has no players, reset both the indices.
	if ( GetTeamClientCount(TEAM_RED) < 1 || GetTeamClientCount(TEAM_BLUE) < 1 )
	{
		GlobalIndex[0] = 0;
		GlobalIndex[1] = 0;
		TintPlayers();
		
		return;
	}
	
	// Determine what has happened in this instance.
	// Suicide, team kill, world kill must be handled separately.
	// Environmental kills (falling to death, trigger_hurt, etc.) have an attacker ID of 0.
	// Suicide has an attacker ID that is the same as the user ID.
	// Team kill means the user ID team will be the same as the attacker ID team.
	
	new client = GetClientOfUserId(EventArray[0]);
	new team = GetClientTeam(client);
	new attacker = GetClientOfUserId(EventArray[3]);
	
	// The assassin has killed themselves somehow.
	if ( EventArray[0] == EventArray[3] || EventArray[3] < 1 )
	{
		if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
		{
			LogMessage("Assassin %N has killed themselves.", GetClientOfUserId(EventArray[0]));
		}
		
		// Play the Assassin Killed music.
		EmitSoundToAll(SND_ASSASSIN_KILLED, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, _, NULL_VECTOR, false, 0.0);
		
		// No points should be awarded.
		
		// Assign a new player from the same team to be the assassin, excluding the player who died.
		GlobalIndex[0] = RandomPlayerFromTeam(team, client);
		if ( GlobalIndex[0] == 0 ) GlobalIndex[0] = client;
		TintPlayers();
	}
	// The assassin was killed by a player from the same team.
	else if ( attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && team == GetClientTeam(attacker) )
	{
		// Don't do anything. Keep the assassin as the same player.
		if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
		{
			LogMessage("Assassin %N was team killed by %N.", client, attacker);
		}
	}
	// The assassin was killed by an enemy player.
	else if ( attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) )
	{
		new attackerteam = GetClientTeam(attacker);
		
		// If this wasn't the target:
		if ( attacker != GlobalIndex[1] )
		{
			if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
			{
				LogMessage("Assassin %N was killed by non-target %N.", GetClientOfUserId(EventArray[0]), attacker);
			}
		
			// Play the Assassin Killed music.
			EmitSoundToAll(SND_ASSASSIN_KILLED, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, _, NULL_VECTOR, false, 0.0);
			
			// Add 1 point to the attacker's team's counter.
			GlobalScore[attackerteam]++;
			
			// Make the attacker the assassin.
			GlobalIndex[0] = attacker;
			TintPlayers();
			
			// Choose a target from the late assassin's team.
			GlobalIndex[1] = RandomPlayerFromTeam(team);
			TintPlayers();
		}
		// If it was the target:
		else
		{
			if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
			{
				LogMessage("Assassin %N was killed by target %N.", GetClientOfUserId(EventArray[0]), attacker);
			}
			
			// Play Assassin Killed by Target music.
			EmitSoundToAll(SND_ASSASSIN_KILLED_BY_TARGET, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, _, NULL_VECTOR, false, 0.0);
			
			// Calculate points earned
			new Float:PointsEarned = ModifyScore(GetConVarFloat(cv_KillAssassin), EventArray[4], EventArray[6], EventArray[2]);
			
			// Add points earned to the target's team's counter
			GlobalScore[attackerteam] += RoundFloat(PointsEarned);
			
			// Make the attacker the assassin.
			GlobalIndex[0] = attacker;
			TintPlayers();
			
			// Choose a target from the late assassin's team.
			GlobalIndex[1] = RandomPlayerFromTeam(team);
			TintPlayers();
		}
	}
}

/*	Called when the target dies.	*/
stock OnTargetDeath(EventArray[], size, String:Weapon[], String:WeaponLogClassname[], bool:SilentKill)
{
	new g_debug = GetConVarInt(cv_Debug);
	
	if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
	{
		LogMessage("Target %N has died.", GetClientOfUserId(EventArray[0]));
	}
	
	// If either team has no players, reset both the indices.
	if ( GetTeamClientCount(TEAM_RED) < 1 || GetTeamClientCount(TEAM_BLUE) < 1 )
	{
		GlobalIndex[0] = 0;
		GlobalIndex[1] = 0;
		TintPlayers();
		
		return;
	}
	
	new client = GetClientOfUserId(EventArray[0]);
	new team = GetClientTeam(client);
	new attacker = GetClientOfUserId(EventArray[3]);
	new assister = GetClientOfUserId(EventArray[7]);
	
	// Determine what has happened in this instance.
	// Suicide, team kill, world kill must be handled separately.
	// Environmental kills (falling to death, trigger_hurt, etc.) have an attacker ID of 0.
	// Suicide has an attacker ID that is the same as the user ID.
	// Team kill means the user ID team will be the same as the attacker ID team.
	
	// The target killed themselves somehow.
	if ( EventArray[0] == EventArray[3] || EventArray[3] < 1 )
	{
		// If the assister was not a Medic assassin:
		if ( !IsPlayerMedicAssassin(assister) || GetClientTeam(assister) == GetClientTeam(client) )
		{
			if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
			{
				LogMessage("Target %N killed themselves.", GetClientOfUserId(EventArray[0]));
			}
			
			// Play the Target Killed music.
			EmitSoundToAll(SND_TARGET_KILLED, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, _, NULL_VECTOR, false, 0.0);
			
			// No points should be awarded.
			
			// Assign a new player from the same team to be the target, excluding the player who died.
			GlobalIndex[1] = RandomPlayerFromTeam(team, client);
			if ( GlobalIndex[1] == 0 ) GlobalIndex[1] = client;
			TintPlayers();
		}
		// If the assister was a Medic assassin:
		else if ( IsPlayerMedicAssassin(assister) && GetClientTeam(assister) != GetClientTeam(client) )
		{
			if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
			{
				LogMessage("Target %N killed themselves and was assisted by Medic assassin %N.", client, assister);
			}
			
			new assisterteam = GetClientTeam(assister);
			
			// Play the Assassin Score music.
			EmitSoundToAll(SND_ASSASSIN_SCORE, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, _, NULL_VECTOR, false, 0.0);
			
			// Calculate the points earned.
			new Float:PointsEarned = ModifyScore(GetConVarFloat(cv_KillTarget), EventArray[4], EventArray[6], EventArray[2]);
			
			// Modify this score since the Medic only assisted.
			PointsEarned = PointsEarned * GetConVarFloat(cv_MedicPoints);
			
			// Add the points to the assassin's team's counter.
			GlobalScore[assisterteam] += RoundFloat(PointsEarned);
			
			// Choose a new target from the same team.
			GlobalIndex[1] = RandomPlayerFromTeam(team);
			TintPlayers();
		}
	}
	// The target was killed by someone on the same team.
	else if ( attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && team == GetClientTeam(attacker) )
	{
		// Don't do anything. Keep the target as the same player.
		if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
		{
			LogMessage("Target %N was team killed by %N.", client, attacker);
		}
	}
	// The target was killed by an enemy player.
	else if ( attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) )
	{
		// If this wasn't the assassin, and neither was the assisting Medic:
		if ( attacker != GlobalIndex[0] && !IsPlayerMedicAssassin(assister) )
		{
			if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
			{
				LogMessage("Target %N was killed by non-assassin %N.", GetClientOfUserId(EventArray[0]), attacker);
			}
			
			// Play the Target Killed music.
			EmitSoundToAll(SND_TARGET_KILLED, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, _, NULL_VECTOR, false, 0.0);
			
			// Choose a target from the same team.
			GlobalIndex[1] = RandomPlayerFromTeam(team);
			TintPlayers();
		}
		// If it was the assassin:
		else if ( attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker) && attacker == GlobalIndex[0] )
		{
			if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
			{
				LogMessage("Target %N was killed by assassin %N.", GetClientOfUserId(EventArray[0]), attacker);
			}
			
			new attackerteam = GetClientTeam(attacker);
			
			// Play the Assassin Score music.
			EmitSoundToAll(SND_ASSASSIN_SCORE, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, _, NULL_VECTOR, false, 0.0);
			
			// Calculate the points earned.
			new Float:PointsEarned = ModifyScore(GetConVarFloat(cv_KillTarget), EventArray[4], EventArray[6], EventArray[2]);
			
			// Add the points to the assassin's team's counter.
			GlobalScore[attackerteam] += RoundFloat(PointsEarned);
			
			// Choose a new target from the same team.
			GlobalIndex[1] = RandomPlayerFromTeam(team);
			TintPlayers();
		}
		// If the assisting Medic was the assassin:
		else if ( IsPlayerMedicAssassin(assister) && GetClientTeam(assister) != GetClientTeam(client) )
		{
			if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
			{
				LogMessage("Target %N was killed by %N and assisted by Medic assassin %N.", client, attacker, assister);
			}
			
			new assisterteam = GetClientTeam(assister);
			
			// Play the Assassin Score music.
			EmitSoundToAll(SND_ASSASSIN_SCORE, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, _, NULL_VECTOR, false, 0.0);
			
			// Calculate the points earned.
			new Float:PointsEarned = ModifyScore(GetConVarFloat(cv_KillTarget), EventArray[4], EventArray[6], EventArray[2]);
			
			// Modify this score since the Medic only assisted.
			PointsEarned = PointsEarned * GetConVarFloat(cv_MedicPoints);
			
			// Add the points to the assassin's team's counter.
			GlobalScore[assisterteam] += RoundFloat(PointsEarned);
			
			// Choose a new target from the same team.
			GlobalIndex[1] = RandomPlayerFromTeam(team);
			TintPlayers();
		}
	}
}

/*	Called when someone on the opposite team to the assassin dies.	*/
stock OnAssassinEnemyDeath(EventArray[], size, String:Weapon[], String:WeaponLogClassname[], bool:SilentKill)
{
	new g_debug = GetConVarInt(cv_Debug);
	
	if ( (g_debug & DEBUGFLAG_DEATH) == DEBUGFLAG_DEATH )
	{
		LogMessage("Assassin enemy %N has died.", GetClientOfUserId(EventArray[0]));
	}
	
	// If either team has no players, reset both the indices.
	if ( GetTeamClientCount(TEAM_RED) < 1 || GetTeamClientCount(TEAM_BLUE) < 1 )
	{
		GlobalIndex[0] = 0;
		GlobalIndex[1] = 0;
		TintPlayers();
		
		return;
	}
	
	// Increment the assassin's team score by one.
	new team = GetClientTeam(GetClientOfUserId(EventArray[0]));
	if ( team == TEAM_RED ) GlobalScore[TEAM_BLUE]++;
	else if ( team == TEAM_BLUE ) GlobalScore[TEAM_RED]++;
}

/*	Returns true if the specified client index is the Medic assassin, or false if they are not.	*/
stock bool:IsPlayerMedicAssassin(client)
{
	if ( client < 1 || client > MaxClients || !IsClientInGame(client) || TF2_GetPlayerClass(client) != TFClass_Medic || client != GlobalIndex[0] ) return false;
	else return true;
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

/*	Returns a random player from the chosen team, or 0 on error.
	If exclude is specified, the client with this indx will be excluded from the search.	*/
stock RandomPlayerFromTeam(team, exclude = 0)
{
	if ( team < 0 ) return 0;	// Make sure our team input value is valid.
	
	new playersfound[MaxClients];
	new n_playersfound = 0;
	
	// Check each client index.
	for (new i = 1; i <= MaxClients; i++)
	{
		if ( IsClientInGame(i) && i != exclude )	// If the client we've chosen is in the game and not excluded:
		{
			if ( GetClientTeam(i) == team )	// If they're on the right team:
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
	
	new ChosenPlayer = GetRandomInt(0, n_playersfound-1);	// Choose a random player between index 0 and the max index.
	
	if ( (GetConVarInt(cv_Debug) & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
	{
		LogMessage("Players found on team %d: %d. Chosen player index: %d (%N).", team, n_playersfound, playersfound[ChosenPlayer], playersfound[ChosenPlayer]);
	}
	
	return playersfound[ChosenPlayer];
}

/*	Runs checks and assigns indices if they are needed.	*/
AssignBestIndices()
{
	// Check the number of players on the Red and Blue teams.
	new RedTeamCount = GetTeamClientCount(TEAM_RED);
	new BlueTeamCount = GetTeamClientCount(TEAM_BLUE);
	new g_debug = GetConVarInt(cv_Debug);
	
	// If either team has no players, reset the indices to 0.
	// We don't need to be playing any sounds or dealing with score here.
	if ( RedTeamCount < 1 || BlueTeamCount < 1 )
	{
		if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
		{
			LogMessage("ABI: Red or Blue has 0 players. Red: %d. Blue: %d", RedTeamCount, BlueTeamCount);
		}
		
		GlobalIndex[0] = 0;
		GlobalIndex[1] = 0;
		TintPlayers();
		
		if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
		{
			LogMessage("ABI: Reset indices to 0.");
		}
	}
	else	// Both teams have a count of 1 or greater.
	{
		
		if ( GlobalIndex[0] < 1 || GlobalIndex[0] > MaxClients || !IsClientInGame(GlobalIndex[0]) )	// If the assassin is not a valid player, re-assign.
		{
			if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
			{
				LogMessage("ABI: Assassin index %d is not connected.", GlobalIndex[0]);
			}
			
			if ( GlobalIndex[1] > 0 && GlobalIndex[1] <= MaxClients && IsClientInGame(GlobalIndex[1]) )	// If the target is valid, choose the other team.
			{
				if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
				{
					LogMessage("ABI: Target %d is valid.", GlobalIndex[1]);
				}
				
				new TargetTeam = GetClientTeam(GlobalIndex[1]);
				
				switch (TargetTeam)
				{
					case TEAM_RED:
					{
						GlobalIndex[0] = RandomPlayerFromTeam(TEAM_BLUE);
						TintPlayers();
						
						if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
						{
							LogMessage("ABI: Assassin is %N", GlobalIndex[0]);
						}
					}
					
					case TEAM_BLUE:
					{
						GlobalIndex[0] = RandomPlayerFromTeam(TEAM_RED);
						TintPlayers();
						
						if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
						{
							LogMessage("ABI: Assassin is %N", GlobalIndex[0]);
						}
					}
				}
			}
			else	// If the target isn't valid, choose at random.
			{
				if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
				{
					LogMessage("ABI: Target %d is not valid.", GlobalIndex[1]);
				}
				
				new RandomTeam = GetRandomInt(TEAM_RED, TEAM_BLUE);
				GlobalIndex[0] = RandomPlayerFromTeam(RandomTeam);
				TintPlayers();
				
				if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
				{
					LogMessage("ABI: Assassin is %N", GlobalIndex[0]);
				}
			}
		}
		
		// If the assassin is valid, leave them.
		
		if ( GlobalIndex[1] < 1 || GlobalIndex[1] > MaxClients || !IsClientInGame(GlobalIndex[1]) )	// If the target is not a valid player, re-assign.
		{
			if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
			{
				LogMessage("ABI: Target index %d is not connected.", GlobalIndex[1]);
			}
			
			if ( GlobalIndex[0] > 0 && GlobalIndex[0] <= MaxClients && IsClientInGame(GlobalIndex[0]) )	// If the assassin is valid, choose the other team.
			{
				if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
				{
					LogMessage("ABI: Assassin %d is valid", GlobalIndex[0]);
				}
				
				new AssassinTeam = GetClientTeam(GlobalIndex[0]);
				
				switch (AssassinTeam)
				{
					case TEAM_RED:
					{
						GlobalIndex[1] = RandomPlayerFromTeam(TEAM_BLUE);
						TintPlayers();
						
						if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
						{
							LogMessage("ABI: Target is %N", GlobalIndex[1]);
						}
					}
					
					case TEAM_BLUE:
					{
						GlobalIndex[1] = RandomPlayerFromTeam(TEAM_RED);
						TintPlayers();
						
						if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
						{
							LogMessage("ABI: Target is %N", GlobalIndex[1]);
						}
					}
				}
			}
			else	// If the target isn't valid, choose at random.
			{
				if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
				{
					LogMessage("ABI: Assassin %d is not valid", GlobalIndex[0]);
				}
				
				new RandomTeam = GetRandomInt(TEAM_RED, TEAM_BLUE);
				GlobalIndex[0] = RandomPlayerFromTeam(RandomTeam);
				TintPlayers();
				
				if ( (g_debug & DEBUGFLAG_INDICES) == DEBUGFLAG_INDICES )
				{
					LogMessage("ABI: Target is %N", GlobalIndex[1]);
				}
			}
		}
		
		// If the target is valid, leave them.
		
		// If the assassin and the target are on the same team, re-assign the target.
		if ( GlobalIndex[0] > 0 && GlobalIndex[0] <= MaxClients && GlobalIndex[1] > 0 && GlobalIndex[1] <= MaxClients && IsClientInGame(GlobalIndex[0]) && IsClientInGame(GlobalIndex[1]) && GetClientTeam(GlobalIndex[0]) == GetClientTeam(GlobalIndex[1]) )
		{
			switch (GetClientTeam(GlobalIndex[0]))
			{
				case TEAM_RED:
				{
					GlobalIndex[1] = RandomPlayerFromTeam(TEAM_BLUE);
					TintPlayers();
				}
				
				case TEAM_BLUE:
				{
					GlobalIndex[1] = RandomPlayerFromTeam(TEAM_RED);
					TintPlayers();
				}
				
				default:	// This shouldn't happen, but just in case:
				{
					GlobalIndex[0] = RandomPlayerFromTeam(TEAM_RED);
					GlobalIndex[1] = RandomPlayerFromTeam(TEAM_BLUE);
					TintPlayers();
				}
			}
		}
	}
}

/*	Tints players.	*/
stock TintPlayers()
{
	new g_debug = GetConVarInt(cv_Debug);
	
	// Clear all players.
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame(i) ) SetEntityRenderColor(i, 255, 255, 255, 255);
	}
	
	// If the assassin and target are valid, tint them.
	if ( GlobalIndex[0] > 0 && GlobalIndex[0] <= MaxClients && IsClientInGame(GlobalIndex[0]) )
	{
		// If we're not using custom colours, tint according to team.
		if ( !GetConVarBool(cv_CustomColours) )
		{
			if ( (g_debug & DEBUGFLAG_COLOUR) == DEBUGFLAG_COLOUR )
			{
				LogMessage("Custom colours not enabled for assassin.");
			}
			
			switch (GetClientTeam(GlobalIndex[0]))
			{
				case TEAM_RED:
				{
					SetEntityRenderColor(GlobalIndex[0], 255, 58, 84, 255);
				}
				
				case TEAM_BLUE:
				{
					SetEntityRenderColor(GlobalIndex[0], 50, 98, 255, 255);
				}
			}
		}
		// Else, tint according to the ConVars.
		else
		{
			// Create our int vectors to hold the colour values.
			new RGBAssassin[3];
			
			// Get the colour values from the ConVars.
			RGBAssassin[0] = GetConVarInt(cv_AssassinRed);
			RGBAssassin[1] = GetConVarInt(cv_AssassinGreen);
			RGBAssassin[2] = GetConVarInt(cv_AssassinBlue);
			
			if ( (g_debug & DEBUGFLAG_COLOUR) == DEBUGFLAG_COLOUR )
			{
				LogMessage("Custom colours for assassin: %d %d %d", RGBAssassin[0], RGBAssassin[1], RGBAssassin[2]);
			}
			
			// Set the render colour.
			SetEntityRenderColor(GlobalIndex[0], RGBAssassin[0], RGBAssassin[1], RGBAssassin[2], 255);
		}
	}
	
	if ( GlobalIndex[1] > 0 && GlobalIndex[1] <= MaxClients && IsClientInGame(GlobalIndex[1]) )
	{
		// If we're not using custom colours, tint according to team.
		if ( !GetConVarBool(cv_CustomColours) )
		{
			if ( (g_debug & DEBUGFLAG_COLOUR) == DEBUGFLAG_COLOUR )
			{
				LogMessage("Custom colours not enabled for target.");
			}
			
			switch (GetClientTeam(GlobalIndex[1]))
			{
				case TEAM_RED:
				{
					SetEntityRenderColor(GlobalIndex[1], 255, 58, 84, 255);
				}
				
				case TEAM_BLUE:
				{
					SetEntityRenderColor(GlobalIndex[1], 50, 98, 255, 255);
				}
			}
		}
		// Else, tint according to the ConVars.
		else
		{
			// Create our int vectors to hold the colour values.
			new RGBTarget[3];
			
			// Get the colour values from the ConVars.
			RGBTarget[0] = GetConVarInt(cv_TargetRed);
			RGBTarget[1] = GetConVarInt(cv_TargetGreen);
			RGBTarget[2] = GetConVarInt(cv_TargetBlue);
			
			if ( (g_debug & DEBUGFLAG_COLOUR) == DEBUGFLAG_COLOUR )
			{
				LogMessage("Custom colours for target: %d %d %d", RGBTarget[0], RGBTarget[1], RGBTarget[2]);
			}
			
			// Set the render colour.
			SetEntityRenderColor(GlobalIndex[1], RGBTarget[0], RGBTarget[1], RGBTarget[2], 255);
		}
	}
}

/*	Wins the round for the specified team.	*/
stock RoundWin(team = 0)
{
	new ent = FindEntityByClassname2(-1, "team_control_point_master");
	if (ent == -1)
	{
		ent = CreateEntityByName("team_control_point_master");
		DispatchSpawn(ent);
		AcceptEntityInput(ent, "Enable");
	}
	SetVariantInt(team);
	AcceptEntityInput(ent, "SetWinner");
}

stock FindEntityByClassname2(startEnt, const String:classname[])
{
	/* If startEnt isn't valid shifting it back to the nearest valid one */
	while (startEnt > -1 && !IsValidEntity(startEnt)) startEnt--;
	return FindEntityByClassname(startEnt, classname);
}  

stock Cleanup(mode = 0)
{
	/*On RoundStart:
	* 	Reset normal score counters.
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
	*	Kill any menus.
	* 	Kill any timers.
	* 	Kill any HUD sync objects.
	* On PlayerSpawn:
	*	Reset indices (only called if we're not in a round or the mode is disabled).*/
	
	switch (mode)
	{
		case CLEANUP_ROUNDSTART:	// RoundStart
		{
			GlobalScore[TEAM_RED] = 0;
			GlobalScore[TEAM_BLUE] = 0;
		}
		
		case CLEANUP_ROUNDWIN:	// RoundWin:
		{
			GlobalIndex[0] = 0;
			GlobalIndex[1] = 0;
			TintPlayers();
		}
		
		case CLEANUP_MAPSTART:	// MapStart
		{
			GlobalIndex[0] = 0;
			GlobalIndex[1] = 0;
			TintPlayers();
			
			GlobalScore[TEAM_RED-2] = 0;
			GlobalScore[TEAM_BLUE-2] = 0;
			GlobalScore[TEAM_RED] = 0;
			GlobalScore[TEAM_BLUE] = 0;
			
			// We only want to do these bits if we're enabled.
			if ( (g_PluginState & STATE_DISABLED) != STATE_DISABLED )
			{
				if ( timer_AssassinCondition == INVALID_HANDLE )
				{
					timer_AssassinCondition = CreateTimer(0.5, TimerAssassinCondition, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				
				if ( timer_MedicHealBuff == INVALID_HANDLE )
				{
					timer_MedicHealBuff = CreateTimer(0.25, TimerMedicHealBuff, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
				}
				
				if ( hs_Assassin == INVALID_HANDLE )
				{
					hs_Assassin = CreateHudSynchronizer();
				}
				
				if ( hs_Target == INVALID_HANDLE )
				{
					hs_Target = CreateHudSynchronizer();
				}
				
				if ( hs_Score == INVALID_HANDLE )
				{
					hs_Score = CreateHudSynchronizer();
				}
				
				if ( hs_Assassin != INVALID_HANDLE && hs_Target != INVALID_HANDLE )	// If the above was successful:
				{
					UpdateHUDMessages(GlobalIndex[0], GlobalIndex[1]);	// Update the HUD
					timer_HUDMessageRefresh = CreateTimer(1.0, TimerHUDRefresh, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	// Set up the timer to next update the HUD.
				}
				
				if ( hs_Score != INVALID_HANDLE )	// If the above was successful:
				{
					UpdateHUDScore(GlobalScore[0], GlobalScore[1], GlobalScore[2], GlobalScore[3]);	// Update the HUD
					timer_HUDScoreRefresh = CreateTimer(1.0, TimerHUDScoreRefresh, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);	// Set up the timer to next update the HUD.
				}
			}
		}
		
		case CLEANUP_MAPEND:	// MapEnd
		{
			GlobalIndex[0] = 0;
			GlobalIndex[1] = 0;
			TintPlayers();
			
			GlobalScore[TEAM_RED-2] = 0;
			GlobalScore[TEAM_BLUE-2] = 0;
			GlobalScore[TEAM_RED] = 0;
			GlobalScore[TEAM_BLUE] = 0;
			
			if ( timer_AssassinCondition != INVALID_HANDLE )
			{
				KillTimer(timer_AssassinCondition);
				timer_AssassinCondition = INVALID_HANDLE;
			}
			
			if ( timer_MedicHealBuff != INVALID_HANDLE )
			{
				KillTimer(timer_MedicHealBuff);
				timer_MedicHealBuff = INVALID_HANDLE;
			}
			
			if ( hs_Assassin != INVALID_HANDLE )
			{
				CloseHandle(hs_Assassin);	// If the assassin hud snyc isn't invalid, close it.
				hs_Assassin = INVALID_HANDLE;
			}
			
			if ( hs_Target != INVALID_HANDLE )
			{
				CloseHandle(hs_Target);		// If the target hud snyc isn't invalid, close it.
				hs_Target = INVALID_HANDLE;
			}
			
			if ( hs_Score != INVALID_HANDLE )
			{
				CloseHandle(hs_Score);
				hs_Score = INVALID_HANDLE;
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
		}
		
		case CLEANUP_PLAYERSPAWN:	// PlayerSpawn
		{
			GlobalIndex[0] = 0;
			GlobalIndex[1] = 0;
			TintPlayers();
		}
	}
	
	return;
}

/*	Checks the team scores against the max score ConVar.
	If either team is over the max, the round is won for that team.
	If both teams are over, the round is ended as a draw.*/
stock CheckScoresAgainstMax()
{
	if ( GlobalScore[TEAM_RED] >= GetConVarInt(cv_MaxScore) && GlobalScore[TEAM_BLUE] >= GetConVarInt(cv_MaxScore) )
	{
		RoundWin();
	}
	else if ( GlobalScore[TEAM_RED] >= GetConVarInt(cv_MaxScore) )
	{
		RoundWin(TEAM_RED);
	}
	else if ( GlobalScore[TEAM_BLUE] >= GetConVarInt(cv_MaxScore) )
	{
		RoundWin(TEAM_BLUE);
	}
}

// Timers:

/*	Timer continually called every 0.5s to re-apply the buffed condition on the assassin.
	This is to allow the assassin to stay buffed if another soldier on the team activates their buff banner,
	as this would otherwise disable the assassin buff condition when it finishes.
	Since the assassin index is always changed if something happens to the client who is the assassin,
	hopefully it's safe to use in this timer.	*/
public Action:TimerAssassinCondition(Handle:timer)
{
	if ( g_PluginState > 0 ) return Plugin_Handled;
	
	// If the assassin index is valid, reset the condition on the assassin.
	if ( GlobalIndex[0] > 0 && GlobalIndex[0] <= MaxClients && IsClientInGame(GlobalIndex[0]) && IsPlayerAlive(GlobalIndex[0]) )
	{
		TF2_AddCondition(GlobalIndex[0], TFCond_Buffed, 0.55);
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
	if ( GlobalIndex[0] > 0 && GlobalIndex[0] <= MaxClients && IsClientInGame(GlobalIndex[0]) && IsPlayerAlive(GlobalIndex[0]) )
	{
		// If the assassin is a Medic:
		if ( TF2_GetPlayerClass(GlobalIndex[0]) == TFClass_Medic )
		{
			decl String:CurrentWeapon[32];
			CurrentWeapon[0] = '\0';
			GetClientWeapon(GlobalIndex[0], CurrentWeapon, sizeof(CurrentWeapon));
			
			// If the current weapon is a medigun and it's healing:
			if ( StrContains(CurrentWeapon, "tf_weapon_medigun", false) != -1 && GetEntProp(GetPlayerWeaponSlot(GlobalIndex[0], 1), Prop_Send, "m_bHealing") == 1 )
			{
				// Look through all the players and apply the buffed condition to the player who matches the Medic's heal target.
				for ( new i = 1; i <= MaxClients; i++ )
				{
					if ( IsClientInGame(i) && IsPlayerAlive(i) && GetEntPropEnt(GetPlayerWeaponSlot(GlobalIndex[0], 1), Prop_Send, "m_hHealingTarget") == i )
					{
						TF2_AddCondition(i, TFCond_Buffed, 0.3);
					}
				}
			}
		}
	}
	
	return Plugin_Handled;
}

/*	Timer called once a second to update the HUD messages.	*/
public Action:TimerHUDRefresh(Handle:timer)
{
	UpdateHUDMessages(GlobalIndex[0], GlobalIndex[1]);
	
	return Plugin_Continue;
}

public Action:TimerHUDScoreRefresh(Handle:timer)
{
	UpdateHUDScore(GlobalScore[0], GlobalScore[1], GlobalScore[2], GlobalScore[3]);
	
	return Plugin_Continue;
}

// HUD Message functions:

/*	Updates the HUD for all clients concerning who is the assassin/target.	*/
stock UpdateHUDMessages(assassin, target)
{
	if ( g_PluginState > STATE_DISABLED ) return;	// If we're not enabled, return.
	
	new assassin_team;
	new target_team;
	
	if ( assassin > 0 && assassin <= MaxClients && IsClientInGame(assassin) ) assassin_team = GetClientTeam(assassin);
	if ( target > 0 && target <= MaxClients && IsClientInGame(target) ) target_team = GetClientTeam(target);
	
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
		
		if ( (g_PluginState & STATE_NOT_IN_ROUND) != STATE_NOT_IN_ROUND )	// If we're in a round:
		{
			
			// Display the text to all players.
			decl String:s_AssassinName[MAX_NAME_LENGTH + 1];
			s_AssassinName[0] = '\0';
			
			// Make sure our client is valid before we get their name.
			if ( assassin > 0 && assassin <= MaxClients && IsClientInGame(assassin) )
			{
				GetClientName(assassin, s_AssassinName, sizeof(s_AssassinName));
				
				for ( new i_assassin = 1; i_assassin <= MaxClients; i_assassin++ )	// Iterate through the client indices
				{
					if ( IsClientInGame(i_assassin) )	// If the client is connected:
					{
						ShowSyncHudText(i_assassin, hs_Assassin, "%T: %s", "as_assassin", i_assassin, s_AssassinName);
					}
				}
			}
			else
			{
				for ( new i_assassin = 1; i_assassin <= MaxClients; i_assassin++ )	// Iterate through the client indices
				{
					if ( IsClientInGame(i_assassin) )	// If the client is connected:
					{
						ShowSyncHudText(i_assassin, hs_Assassin, "%T: %T", "as_assassin", i_assassin, "as_none", i_assassin);
					}
				}
			}
		}
		else	// Otherwise:
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
		
		if ( (g_PluginState & STATE_NOT_IN_ROUND) != STATE_NOT_IN_ROUND )	// If we're in a round:
		{			
			// Display the text to all players.
			decl String:s_TargetName[MAX_NAME_LENGTH + 1];
			s_TargetName[0] = '\0';
			
			// Make sure our client is valid before we get their name.
			if ( target > 0 && target <= MaxClients && IsClientInGame(target) )
			{
				GetClientName(target, s_TargetName, sizeof(s_TargetName));
			
				for ( new i_target= 1; i_target <= MaxClients; i_target++ )	// Iterate through the client indices
				{
					if ( IsClientInGame(i_target) )	// If the client is connected:
					{
						ShowSyncHudText(i_target, hs_Target, "%T: %s", "as_target", i_target, s_TargetName);
					}
				}
			}
			else
			{
				for ( new i_target = 1; i_target <= MaxClients; i_target++ )	// Iterate through the client indices
				{
					if ( IsClientInGame(i_target) )	// If the client is connected:
					{
						ShowSyncHudText(i_target, hs_Target, "%T: %T", "as_target", i_target, "as_none", i_target);
					}
				}
			}
		}
		else	// Otherwise:
		{
			// Clear HUD sync for all players
			ClearSyncHUDTextAll(hs_Target);
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
	
	if ( (g_PluginState & STATE_NOT_IN_ROUND) != STATE_NOT_IN_ROUND )
	{
		if ( hs_Score != INVALID_HANDLE )
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
	}
	else	// Otherwise, hide any text.
	{
		if ( hs_Score != INVALID_HANDLE )
		{
			// Clear HUD sync for all players
			ClearSyncHUDTextAll(hs_Score);
		}
	}
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

// Weapon modifiers:

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
	new g_debug = GetConVarInt(cv_Debug);
	
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
				
				if ( (g_debug & DEBUGFLAG_WEAPONMODIFIERS) == DEBUGFLAG_WEAPONMODIFIERS )
				{
					LogMessage("Sub-key count: %d", n_SubKeys);
				}
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
				
				if ( (g_debug & DEBUGFLAG_WEAPONMODIFIERS) == DEBUGFLAG_WEAPONMODIFIERS )
				{
					LogMessage("Weapon ID key %d put into WeaponID[%d]", GetArrayCell(WeaponID, i-1), i-1);
				}
				
				SetArrayCell(WeaponModifier, i-1, KvGetFloat(KV, "modifier", 1.0));				
				if ( GetArrayCell(WeaponModifier, i-1) < 0.0 ) SetArrayCell(WeaponModifier, i-1, 0.0);	// If the modifier is less than 0, set to zero.
				
				if ( (g_debug & DEBUGFLAG_WEAPONMODIFIERS) == DEBUGFLAG_WEAPONMODIFIERS )
				{
					LogMessage("Weapon modifier value %f put into WeaponModifier[%d]", GetArrayCell(WeaponModifier, i-1), i-1);
				}
				
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
				if ( (g_debug & DEBUGFLAG_WEAPONMODIFIERS) == DEBUGFLAG_WEAPONMODIFIERS )
				{
					LogMessage("No. of sub-keys = 0. Return: 1.0");
				}
				
				return 1.0;
			}
			
			// If either array is invalid, return 1.0.
			if ( WeaponID == INVALID_HANDLE || WeaponModifier == INVALID_HANDLE )
			{
				if ( (g_debug & DEBUGFLAG_WEAPONMODIFIERS) == DEBUGFLAG_WEAPONMODIFIERS )
				{
					LogMessage("WeaponID or WeaponModifier array is invalid. Return: 1.0");
				}
				
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
					if ( (g_debug & DEBUGFLAG_WEAPONMODIFIERS) == DEBUGFLAG_WEAPONMODIFIERS )
					{
						LogMessage("Match: weapon ID %d matches array index %d of value %f", n_WeaponID, j-1, GetArrayCell(WeaponModifier, j-1));
					}
					
					return GetArrayCell(WeaponModifier, j-1);
				}
			}
			
			// If there were no matches, return 1.0.
			if ( (g_debug & DEBUGFLAG_WEAPONMODIFIERS) == DEBUGFLAG_WEAPONMODIFIERS )
			{
				LogMessage("No match found for weapon ID %d, return: 1.0", n_WeaponID);
			}
			
			return 1.0;
			
			
		}
		else
		{
			if ( (g_debug & DEBUGFLAG_WEAPONMODIFIERS) == DEBUGFLAG_WEAPONMODIFIERS )
			{
				LogMessage("Check ID called before file has been parsed. Return: 1.0");
			}
			
			return 1.0;	// Otherwise, return 1 (no modifier).
		}
	}
}

/*	Returns the float value of a score after it has been multiplied by score modifiers.
	If an error is encountered, the original score is returned.*/
stock Float:ModifyScore(Float:n_Score, id_Weapon, n_CustomKill, i_InflictorIndex)
{
	new g_debug = GetConVarInt(cv_Debug);
	
	// The first thing we want to do is multiply our input score by the weapon multiplier.
	// id_Weapon gives us the item definition index of the weapon from the player_death event.
	
	new Float:n_NewScore = n_Score * WeaponModifiers(true, id_Weapon);
	
	if ( (g_debug & DEBUGFLAG_MODIFYSCORE) == DEBUGFLAG_MODIFYSCORE )
	{
		LogMessage("ModifyScore: Weapon modifiers applied, score = %f", n_NewScore);
	}
	
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
			if ( (g_debug & DEBUGFLAG_MODIFYSCORE) == DEBUGFLAG_MODIFYSCORE )
			{
				LogMessage("ModifyScore: Headshot, score = %f", n_NewScore);
			}
		}
		
		case TF_CUSTOM_BACKSTAB:
		{
			n_NewScore = n_NewScore * GetConVarFloat(cv_BackstabMultiplier);
			if ( (g_debug & DEBUGFLAG_MODIFYSCORE) == DEBUGFLAG_MODIFYSCORE )
			{
				LogMessage("ModifyScore: Backstab, score = %f", n_NewScore);
			}
		}
		
		case TF_CUSTOM_TELEFRAG:
		{
			n_NewScore = n_NewScore * GetConVarFloat(cv_TelefragMultiplier);
			if ( (g_debug & DEBUGFLAG_MODIFYSCORE) == DEBUGFLAG_MODIFYSCORE )
			{
				LogMessage("ModifyScore: Telefrag, score = %f", n_NewScore);
			}
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
					if ( (g_debug & DEBUGFLAG_MODIFYSCORE) == DEBUGFLAG_MODIFYSCORE )
					{
						LogMessage("ModifyScore: L2 sentry, score = %f", n_NewScore);
					}
				}
				
				case 3:
				{
					n_NewScore = n_NewScore * GetConVarFloat(cv_SentryL3Multiplier);
					if ( (g_debug & DEBUGFLAG_MODIFYSCORE) == DEBUGFLAG_MODIFYSCORE )
					{
						LogMessage("ModifyScore: L3 sentry, score = %f", n_NewScore);
					}
				}
				
				default:
				{
					n_NewScore = n_NewScore * GetConVarFloat(cv_SentryL1Multiplier);
					if ( (g_debug & DEBUGFLAG_MODIFYSCORE) == DEBUGFLAG_MODIFYSCORE )
					{
						LogMessage("ModifyScore: L1 sentry or default, score = %f", n_NewScore);
					}
				}
			}
		}
		else if ( StrContains(entname, "tf_projectile_") != -1 )
		{
			if ( GetEntPropEnt(i_InflictorIndex, Prop_Send, "m_iDeflected") > 0 )
			{
				n_NewScore = n_NewScore * GetConVarFloat(cv_ReflectMultiplier);
				if ( (g_debug & DEBUGFLAG_MODIFYSCORE) == DEBUGFLAG_MODIFYSCORE )
				{
					LogMessage("ModifyScore: Reflect, score = %f", n_NewScore);
				}
			}
		}
	}
	
	if ( (g_debug & DEBUGFLAG_MODIFYSCORE) == DEBUGFLAG_MODIFYSCORE )
	{
		LogMessage("ModifyScore: Final score = %f", n_NewScore);
	}
	return n_NewScore;
}

/*	Gets the item definition index of a weapon, given the inflictor index.	*/
stock ItemDefinitionIndex(inflictor, weapon_id)
{
	new g_debug = GetConVarInt(cv_Debug);
	
	/*	We need to do different things depending on the inflictor index:
	* If it's the player, get their current weapon.
	* If it's a projectile, get the owner player through m_hOwnerEntity and check their weapons for a match with the weapon ID.
	* If it's something like a flare, apparently the inflictor index will already be the weapon, so
	* to check if the entity is a weapon we could check if the entity name contains "tf_weapon_". */
	
	if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
	{
		LogMessage("#1 ItemDefinitionIndex called.");
	}
	
	if ( inflictor <= 0)
	{
		if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
		{
			LogMessage("#2 ABORT: Inflictor value %d is <= 0, returning -1.", inflictor);
		}
		
		return -1;
	}
	
	// If the index is a player, get their current weapon.
	else if ( inflictor > 0 && inflictor <= MaxClients && IsClientInGame(inflictor) )
	{
		if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
		{
			LogMessage("#3 Index is player.");
		}
		
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
				
				if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
				{
					LogMessage("#4 Owner value %d of weapon matches inflictor index %d. Weapon index chosen is %d.", GetEntPropEnt(cycleindex, Prop_Send, "m_hOwner" ), inflictor, cweaponindex);
				}
			}
		}
		
		if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
		{
			LogMessage("#5 Cweaponindex is %d.", cweaponindex);
		}
		
		// By now the entindex of the weapon is held in cweaponindex.
		// Get the item definition index from the weapon.
		
		if ( IsValidEntity(cweaponindex) )
		{
			if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
			{
				decl String:weaponclassname[64];
				GetEntityClassname(cweaponindex, weaponclassname, sizeof(weaponclassname));
				LogMessage("#6 Returning item def index %d of weapon %d (%s).", GetEntProp(cweaponindex, Prop_Send, "m_iItemDefinitionIndex"), cweaponindex, weaponclassname);
			}
			return GetEntProp(cweaponindex, Prop_Send, "m_iItemDefinitionIndex");
		}
		else
		{
			if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
			{
				LogMessage("#7 ABORT: cweaponindex %d is not a valid entity, returning -1.", cweaponindex);
			}
			
			return -1;
		}
	}
	else	// If the inflictor is another entity:
	{
		if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
		{
			LogMessage("#8 Inflictor is an entity other than the player (weapon or projectile).");
		}
		
		// We need to determine if this entity is a projectile or a weapon.
		// If it's a weapon, return the definition index immediately.
		// If it's not, find the weapon through the owner.
		
		decl String:classname[64];
		GetEntityClassname(inflictor, classname, sizeof(classname));
		
		if ( StrContains(classname, "tf_weapon_", false) != -1 )	// If the classname is in weapon format:
		{
			if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
			{
				LogMessage("#9 Classname %s is in weapon format.", classname);
			}
			if ( IsValidEntity(inflictor) )
			{
				if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
				{
					decl String:weaponclassname[64];
					GetEntityClassname(inflictor, weaponclassname, sizeof(weaponclassname));
					LogMessage("#10 Returning item def index %d of weapon %d (%s).", GetEntProp(inflictor, Prop_Send, "m_iItemDefinitionIndex"), inflictor, weaponclassname);
				}
				return GetEntProp(inflictor, Prop_Send, "m_iItemDefinitionIndex");	// Return the definition index.
			}
			else
			{
				if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
				{
					LogMessage("#11 ABORT: classname in weapon format but not valid entity (??), returning -1.");
				}
				
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
			if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
			{
				LogMessage("#12 Classname %s is in projectile format.", classname);
			}
			
			if ( !IsValidEntity(inflictor) )
			{
				if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
				{
					LogMessage("#13 ABORT: inflictor at index %d is not a valid entity, returning -1.", inflictor);
				}
				
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
			
			if ( IsValidEntity(projectileowner) && projectileowner > 0 && projectileowner <= MaxClients && IsClientInGame(projectileowner) )
			{
				if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
				{
					LogMessage("#14 Projectile owner %d is valid.", projectileowner);
				}
			}
			else
			{
				if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
				{
					LogMessage("#15 ABORT: owner index %d is invalid, returning -1.", projectileowner);
				}
				
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
					if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
					{
						decl String:weaponclassname[64];
						GetEntityClassname(slotindex, weaponclassname, sizeof(weaponclassname));
						LogMessage("#16 Returning item def index %d from weapon index %d (%s) at slot 0.", GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex"), slotindex, weaponclassname);
					}
					
					return  GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex");	// Return the definition index.
				}
				else
				{
					if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
					{
						LogMessage("#17 ABORT: slotindex %d is invalid, returning -1.", slotindex);
					}
					
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
					if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
					{
						decl String:weaponclassname[64];
						GetEntityClassname(slotindex, weaponclassname, sizeof(weaponclassname));
						LogMessage("#18 Returning item def index %d from weapon index %d (%s) at slot 1.", GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex"), slotindex, weaponclassname);
					}
					
					return  GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex");	// Return the definition index.
				}
				else
				{
					if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
					{
						LogMessage("#19 ABORT: slotindex %d is invalid, returning -1.", slotindex);
					}
					
					return -1;
				}
			}
			// Same for melee (sandman).
			else if ( weapon_id == TF_WEAPON_BAT_WOOD )
			{
				new slotindex = GetPlayerWeaponSlot(projectileowner, 2);
				
				if ( slotindex != -1 && IsValidEntity(slotindex) )
				{
					if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
					{
						decl String:weaponclassname[64];
						GetEntityClassname(slotindex, weaponclassname, sizeof(weaponclassname));
						LogMessage("#20 Returning item def index %d from weapon index %d (%s) at slot 1.", GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex"), slotindex, weaponclassname);
					}
					
					return  GetEntProp(slotindex, Prop_Send, "m_iItemDefinitionIndex");	// Return the definition index.
				}
				else
				{
					if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
					{
						LogMessage("#21 ABORT: slotindex %d is invalid, returning -1.", slotindex);
					}
					
					return -1;
				}
			}
			// Weapon ID is not specified in code, return -1 and notify.
			else
			{
				LogMessage("#22 Error in ItemDefinitionIndex: Weapon ID %d from inflictor ID %d is not recognised. The plugin code probably needs updating.", weapon_id, inflictor);
				
				return -1;
			}
		}
		
		else
		{
			if ( (g_debug & DEBUGFLAG_IDINDEX) == DEBUGFLAG_IDINDEX )
			{
				LogMessage("#23 ABORT: classname %s is not in projectile format either, returning -1.", classname);
			}
			
			return -1;	// If the entity isn't a projectile either (eg it's a sentry), return -1.
		}
	}
}

/*	Disables any objective-related map entities.	*/
stock DisableObjectives()
{
	new g_debug = GetConVarInt(cv_Debug);
	
	// Kill any control point triggers.
	new ent = -1;
	
	while ( (ent = FindEntityByClassname2(ent, "trigger_capture_area")) != -1 )
	{
		if ( (g_debug & DEBUGFLAG_OBJECTIVES) == DEBUGFLAG_OBJECTIVES )
		{
			LogMessage("Killing trigger_capture_area %d.", ent);
		}
		
		AcceptEntityInput(ent, "Kill");
	}
	
	// Disable and hide any control points.
	ent = -1;
	
	while ( (ent = FindEntityByClassname2(ent, "team_control_point")) != -1 )
	{
		if ( (g_debug & DEBUGFLAG_OBJECTIVES) == DEBUGFLAG_OBJECTIVES )
		{
			LogMessage("Disabling team_control_point %d.", ent);
		}
		
		AcceptEntityInput(ent, "HideModel");
		AcceptEntityInput(ent, "Disable");
	}
	
	// Kill any CTF flags.
	ent = -1;
	
	while ( (ent = FindEntityByClassname2(ent, "item_teamflag")) != -1 )
	{
		if ( (g_debug & DEBUGFLAG_OBJECTIVES) == DEBUGFLAG_OBJECTIVES )
		{
			LogMessage("Killing item_teamflag %d.", ent);
		}
		
		AcceptEntityInput(ent, "Kill");
	}
	
	// Kill any flag capture areas.
	// This will also kill the capture areas around payload carts.
	ent = -1;
	
	while ( (ent = FindEntityByClassname2(ent, "func_capturezone")) != -1 )
	{
		if ( (g_debug & DEBUGFLAG_OBJECTIVES) == DEBUGFLAG_OBJECTIVES )
		{
			LogMessage("Killing func_capturezone %d.", ent);
		}
		
		AcceptEntityInput(ent, "Kill");
	}
}

// User commands are below:

/*	Displays the global indices to a client via the console.	*/
public Action:Cmd_CheckIndices(client, args)
{
	if ( GlobalIndex[0] < 1 || GlobalIndex[0] > MaxClients || !IsClientInGame(GlobalIndex[0]) ) PrintToConsole(client, "Asassin index %d is invalid.", GlobalIndex[0]);
	else PrintToConsole(client, "Asassin index: %d (%N)", GlobalIndex[0], GlobalIndex[0]);
	
	if ( GlobalIndex[1] < 1 || GlobalIndex[1] > MaxClients || !IsClientInGame(GlobalIndex[1]) ) PrintToConsole(client, "Target index %d is invalid.", GlobalIndex[1]);
	else PrintToConsole(client, "Target index: %d (%N)", GlobalIndex[1], GlobalIndex[1]);
	
	return Plugin_Handled;
}

/*	Displays debug flags and descriptors in the console.	*/
public Action:Cmd_ShowDebugFlags(client, args)
{
	new LogFunc = RoundFloat(Logarithm(DEBUGFLAG_MAX_FL, 2.0));
	
	decl String:Flags[LogFunc+1][33];
	decl String:Desc[LogFunc+1][129];
	decl String:Buffer[33];
	decl String:Buffer2[129];
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_GENERAL");
	Format(Buffer2, sizeof(Buffer2), "General debugging.");
	Flags[0] = Buffer;
	Desc[0] = Buffer2;
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_INDICES");
	Format(Buffer2, sizeof(Buffer2), "Logging when the global indices change.");
	Flags[1] = Buffer;
	Desc[1] = Buffer2;
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_RANDOMPLAYER");
	Format(Buffer2, sizeof(Buffer2), "Logging when fetching a random player.");
	Flags[2] = Buffer;
	Desc[2] = Buffer2;
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_TEAMCHANGE");
	Format(Buffer2, sizeof(Buffer2), "Logging when a player changes team.");
	Flags[3] = Buffer;
	Desc[3] = Buffer2;
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_ASSASSINCOND");
	Format(Buffer2, sizeof(Buffer2), "Logging when the assassin condition timer is created or destroyed.");
	Flags[4] = Buffer;
	Desc[4] = Buffer2;
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_DEATH");
	Format(Buffer2, sizeof(Buffer2), "Logging when the assassin, target, etc. dies.");
	Flags[5] = Buffer;
	Desc[5] = Buffer2;
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_IDINDEX");
	Format(Buffer2, sizeof(Buffer2), "Logging finding an item definition index.");
	Flags[6] = Buffer;
	Desc[6] = Buffer2;
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_WEAPONMODIFIERS");
	Format(Buffer2, sizeof(Buffer2), "Logging the weapon modifiers tasks.");
	Flags[7] = Buffer;
	Desc[7] = Buffer2;
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_MODIFYSCORE");
	Format(Buffer2, sizeof(Buffer2), "Logging the score modifier tasks.");
	Flags[8] = Buffer;
	Desc[8] = Buffer2;
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_OBJECTIVES");
	Format(Buffer2, sizeof(Buffer2), "Logging disabling of objectives.");
	Flags[9] = Buffer;
	Desc[9] = Buffer2;
	
	Format(Buffer, sizeof(Buffer), "DEBUGFLAG_COLOUR");
	Format(Buffer2, sizeof(Buffer2), "Logging of colour tinting.");
	Flags[10] = Buffer;
	Desc[10] = Buffer2;
	
	/*
	#define DEBUGFLAG_GENERAL			1		// General debugging.
	#define DEBUGFLAG_INDICES			2		// Logging when the global indices change.
	#define DEBUGFLAG_RANDOMPLAYER		4		// Logging when fetching a random player.
	#define DEBUGFLAG_TEAMCHANGE		8		// Logging when a player changes team.
	#define DEBUGFLAG_ASSASSINCOND		16		// Logging when the assassin condition timer is created or destroyed.
	#define DEBUGFLAG_DEATH				32		// Logging when the assassin, target etc. dies.
	#define DEBUGFLAG_IDINDEX			64		// Logging finding an item definition index.
	#define DEBUGFLAG_WEAPONMODIFIERS	128		// Logging the weapon modifiers tasks.
	#define DEBUGFLAG_MODIFYSCORE		256		// Logging the score modifier tasks.
	#define DEBUGFLAG_OBJECTIVES		512		// Logging disabling of objectives.
	#define DEBUGFLAG_COLOUR			1024	// Logging of colour tinting.
	*/
	
	// How many args there are will determine how many flags will be toggled.
	// For example, "nfas_debugflags 1 5 4 5" would toggle indices, death, assassincond and death again.
	// If all flags were 0, this would result in the indices and assassincond flags ending up enabled.
	/*new Args = GetCmdArgs();
	
	if ( Args <= 0 )
	{*/
	new DebugCVar = GetConVarInt(cv_Debug);
	PrintToConsole(client, "Current debug flag value: %d. Flags set:", DebugCVar);
	
	if ( DebugCVar > 0 )
	{
		for ( new i = 0; i <= LogFunc; i++ )
		{
			if ( (DebugCVar & (2^i)) == (2^i) ) PrintToConsole(client, "%s", Flags[i]);
		}
	}
	else PrintToConsole(client, "None.");
	
	// If DEBUGFLAG_MAX is 1024, for example, 0 <= i <= 10.
	for ( new i = 0; i <= LogFunc ; i++ )
	{
		PrintToConsole(client, "== Flag %d == %s - %s", 2^i, Flags[i], Desc[i]);
	}
	
	return Plugin_Handled;
	/*}
	else
	{
		PrintToConsole(client, "Current debug flag value: %d", GetConVarInt(cv_Debug));
		
		for ( new n = 1; n <= Args; n++ )
		{
			decl String:ArgN[17];
			GetCmdArg(n, ArgN, sizeof(ArgN));
			
			new FlagToToggle = StringToInt(ArgN);
			new OldDebug = GetConVarInt(cv_Debug);
			new NewDebug = OldDebug;
			
			if ( FlagToToggle > LogFunc )
			{
				PrintToConsole (client, "Flag number %d does not exist.", FlagToToggle);
			}
			else
			{
				PrintToConsole(client, "Toggling flag number %d (%s)...", FlagToToggle, Flags[FlagToToggle]);
				NewDebug ^= (2 ^ FlagToToggle);
				SetConVarInt(cv_Debug, NewDebug);
				
				PrintToConsole(client, "Old debug value: %d. Flag number %d was toggled (raw value %d). New debug value: %d.", OldDebug, FlagToToggle, 2^FlagToToggle, NewDebug);
				
			}
		}
	}
	
	return Plugin_Handled;*/
}

/*	Displays the help panel.	*/
public Action:Cmd_Help(client, args)
{
	Panel_Help(client, 0);
	
	return Plugin_Handled;
}

/*	Changes the assassin to the specified player.	*/
public Action:Cmd_ChangeAssassin(client, args)
{
	if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return Plugin_Handled;
	
	if ( (g_PluginState & STATE_NOT_IN_ROUND) == STATE_NOT_IN_ROUND || GetTeamClientCount(TEAM_RED) < 1 || GetTeamClientCount(TEAM_BLUE) < 1 )
	{
		ReplyToCommand(client, "%T", "as_cannot_reassign_now", client);
		return Plugin_Handled;
	}
	
	if ( GetCmdArgs() < 1 )
	{
		PrintToConsole(client, "nfas_assassin <name|#userID>");
		
		new Handle:ClientMenu = CreateMenu(Handler_AssassinChangeMenu);
		if ( !BuildClientMenu(ClientMenu) )
		{
			ReplyToCommand(client, "%T", "as_menu_cannot_be_created", client);
			CloseHandle(ClientMenu);
			ClientMenu = INVALID_HANDLE;
			
			return Plugin_Handled;
		}
		
		DisplayMenu(ClientMenu, client, 20);
		
		return Plugin_Handled;
	}
	
	decl String:Arg[MAX_NAME_LENGTH+1];
	GetCmdArg(1, Arg, sizeof(Arg));
	new userid = StringToInt(Arg);
	new bool:success;
	new String:PlayerName[MAX_NAME_LENGTH+1];
	
	if ( userid > 0 )
	{
		new nclient = GetClientOfUserId(userid);
		
		if ( nclient > 0 && nclient <= MaxClients && IsClientInGame(nclient) )
		{
			GetClientName(nclient, PlayerName, sizeof(PlayerName));
			success = ChangeIndex(nclient, 0);
		}
	}
	else
	{
		new target = FindTarget(client, Arg, false, false);
		if ( target == -1 ) return Plugin_Handled;
		GetClientName(target, PlayerName, sizeof(PlayerName));
		
		success = ChangeIndex(target, 0);
	}
	
	if ( success == false )
	{
		ReplyToCommand(client, "%T", "as_unable_to_reassign_assassin", client);
	}
	else
	{
		ReplyToCommand(client, "%T", "as_assassin_reassigned", client, PlayerName);
	}
	
	return Plugin_Handled;
}

/*	Handler for the assassin change menu.	*/
public Handler_AssassinChangeMenu(Handle:clientmenu, MenuAction:action, param1, param2)
{
	if ( action == MenuAction_Select )
	{
		// The "info" for the menu item is the user ID of the client.
		// Check to make sure this is still valid.
		
		decl String:info[9];
		GetMenuItem(clientmenu, param2, info, sizeof(info));
		new client = GetClientOfUserId(StringToInt(info));
		
		if ( client < 1 || client > MaxClients ) return;
		
		new bool:success = ChangeIndex(client, 0);
		
		if ( success )
		{
			decl String:PlayerName[MAX_NAME_LENGTH+1];
			GetClientName(client, PlayerName, sizeof(PlayerName));
			PrintToChatAll("%T", "as_assassin_reassigned", LANG_SERVER, PlayerName);
		}
	}
	
	else if (action == MenuAction_End)
	{
		CloseHandle(clientmenu);
	}
}

/*	Changes the target to the specified player.	*/
public Action:Cmd_ChangeTarget(client, args)
{
	if ( (g_PluginState & STATE_DISABLED) == STATE_DISABLED ) return Plugin_Handled;
	
	if ( (g_PluginState & STATE_NOT_IN_ROUND) == STATE_NOT_IN_ROUND || GetTeamClientCount(TEAM_RED) < 1 || GetTeamClientCount(TEAM_BLUE) < 1 )
	{
		ReplyToCommand(client, "%T", "as_cannot_reassign_now", client);
		return Plugin_Handled;
	}
	
	if ( GetCmdArgs() < 1 )
	{
		PrintToConsole(client, "nfas_target <name|#userID>");
		
		new Handle:ClientMenu = CreateMenu(Handler_TargetChangeMenu);
		if ( !BuildClientMenu(ClientMenu) )
		{
			ReplyToCommand(client, "%T", "as_menu_cannot_be_created", client);
			CloseHandle(ClientMenu);
			ClientMenu = INVALID_HANDLE;
			
			return Plugin_Handled;
		}
		
		DisplayMenu(ClientMenu, client, 20);
		
		return Plugin_Handled;
	}
	
	decl String:Arg[MAX_NAME_LENGTH+1];
	GetCmdArg(1, Arg, sizeof(Arg));
	new userid = StringToInt(Arg);
	new bool:success;
	new String:PlayerName[MAX_NAME_LENGTH+1];
	
	if ( userid > 0 )
	{
		new nclient = GetClientOfUserId(userid);
		
		if ( nclient > 0 && nclient <= MaxClients && IsClientInGame(nclient) )
		{
			GetClientName(nclient, PlayerName, sizeof(PlayerName));
			success = ChangeIndex(nclient, 1);
		}
	}
	else
	{
		new target = FindTarget(client, Arg, false, false);
		if ( target == -1 ) return Plugin_Handled;
		GetClientName(target, PlayerName, sizeof(PlayerName));
		
		success = ChangeIndex(target, 1);
	}
	
	if ( success == false )
	{
		ReplyToCommand(client, "%T", "as_unable_to_reassign_target", client);
	}
	else
	{
		ReplyToCommand(client, "%T", "as_target_reassigned", client, PlayerName);
	}
	
	return Plugin_Handled;
}
/*	Handler for the target change menu.	*/
public Handler_TargetChangeMenu(Handle:clientmenu, MenuAction:action, param1, param2)
{
	if ( action == MenuAction_Select )
	{
		// The "info" for the menu item is the user ID of the client.
		// Check to make sure this is still valid.
		
		decl String:info[9];
		GetMenuItem(clientmenu, param2, info, sizeof(info));
		new client = GetClientOfUserId(StringToInt(info));
		
		if ( client < 1 || client > MaxClients ) return;
		
		new bool:success = ChangeIndex(client, 1);
		
		if ( success )
		{
			decl String:PlayerName[MAX_NAME_LENGTH+1];
			GetClientName(client, PlayerName, sizeof(PlayerName));
			PrintToChatAll("%T", "as_target_reassigned", LANG_SERVER, PlayerName);
		}
	}
	
	else if (action == MenuAction_End)
	{
		CloseHandle(clientmenu);
	}
}

/*	Used with commands to re-assign the assassin or target.	*/
bool:ChangeIndex(client, type)
{
	// Check to make sure that we are able to change indices.
	if ( g_PluginState > 0 ) return false;
	if ( GetTeamClientCount(TEAM_RED) < 1 || GetTeamClientCount(TEAM_BLUE) < 1 ) return false;
	if ( client < 0 || client > MaxClients || !IsClientInGame(client) ) return false;
	
	new client_team = GetClientTeam(client);
	if ( client_team != TEAM_RED && client_team != TEAM_BLUE ) return false;
	
	if ( type < 0 ) type = 0;
	else if ( type > 1 ) type = 1;
	
	new opposite;
	if ( type == 0 ) opposite = 1;
	else if ( type == 1 ) opposite = 0;
	
	// Check the team of the opposite index and the intended client.
	// If their team is the same:
	if ( GetClientTeam(GlobalIndex[opposite]) == client_team )
	{
		switch ( client_team )
		{
			case TEAM_RED:
			{
				GlobalIndex[type] = client;
				GlobalIndex[opposite] = RandomPlayerFromTeam(TEAM_BLUE);
			}
			
			case TEAM_BLUE:
			{
				GlobalIndex[type] = client;
				GlobalIndex[opposite] = RandomPlayerFromTeam(TEAM_RED);
			}
		}
	}
	else
	{
		GlobalIndex[type] = client;
	}
	
	TintPlayers();
	EmitSoundToAll(SND_ASSASSIN_KILLED, _, SNDCHAN_AUTO, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, client, _, NULL_VECTOR, false, 0.0);
	
	return true;
}

/*	Displays the help panel to the client.	*/
public Action:Panel_Help(client, args)
{
	if ( g_PluginState < STATE_DISABLED )
	{	
		new Handle:panel_help = CreatePanel();
		decl String:StringBuffer[256];
		
		Format(StringBuffer, sizeof(StringBuffer), "%T", "as_title_help", client, PLUGIN_VERSION);
		SetPanelTitle(panel_help, StringBuffer);
		
		Format(StringBuffer, sizeof(StringBuffer), "%T", "as_dialogue_help", client);
		DrawPanelText(panel_help, StringBuffer);
		
		Format(StringBuffer, sizeof(StringBuffer), "%T", "Exit", client);
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
	if ( g_PluginState < STATE_DISABLED )
	{	
		new Handle:panel_scores = CreatePanel();
		decl String:StringBuffer[32];
		
		// Scores
		Format(StringBuffer, sizeof(StringBuffer), "%T", "as_score_menu_title", client);
		SetPanelTitle(panel_scores, StringBuffer);
		
		Format(StringBuffer, sizeof(StringBuffer), "%T", "as_red", client);
		DrawPanelItem(panel_scores, StringBuffer);
		
		Format(StringBuffer, sizeof(StringBuffer), "%T", "as_this_round", client, GlobalScore[TEAM_RED] );
		DrawPanelText(panel_scores, StringBuffer);
		
		Format(StringBuffer, sizeof(StringBuffer), "%T", "as_in_total", client, GlobalScore[TEAM_RED-2] );
		DrawPanelText(panel_scores, StringBuffer);
		
		Format(StringBuffer, sizeof(StringBuffer), "%T", "as_blue", client);
		DrawPanelItem(panel_scores, StringBuffer);
		
		Format(StringBuffer, sizeof(StringBuffer), "%T", "as_this_round", client, GlobalScore[TEAM_BLUE] );
		DrawPanelText(panel_scores, StringBuffer);
		
		Format(StringBuffer, sizeof(StringBuffer), "%T", "as_in_total", client, GlobalScore[TEAM_BLUE-2] );
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

/*	Fills a menu with clients on Red or Blue. Returns the number of clients added.	*/
BuildClientMenu(Handle:menu)
{
	if ( menu == INVALID_HANDLE ) return 0;
	new added = 0;
	
	for ( new i = 1; i <= MaxClients; i++ )
	{
		if ( IsClientInGame(i) )
		{
			if ( GetClientTeam(i) == TEAM_RED || GetClientTeam(i) == TEAM_BLUE )
			{
				decl String:ClientName[MAX_NAME_LENGTH+1];
				GetClientName(i, ClientName, sizeof(ClientName));
				
				// Our "info" is the user ID of the client.
				decl String:ClientUserID[9];
				Format(ClientUserID, sizeof(ClientUserID), "%d", GetClientUserId(i));
				
				AddMenuItem(menu, ClientUserID, ClientName);
				added++;
			}
		}
	}
	
	return added;
}