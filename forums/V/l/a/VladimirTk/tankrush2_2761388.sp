//============================================================================================================================================================================================================================================
//																								PLUGIN INFO
//============================================================================================================================================================================================================================================





/*=======================================================================================

	Plugin Info:

*	Name	:	Tank Rush 2
*	Author	:	Phil Bradley
*	Descrp	:	Spawns an endless amount of tanks.
*	Version :	1.3.4.2
*	Link	:	psbj.github.io

========================================================================================

	Change Log:

1.3.4 (20-Nov-2014)
	- Tank Rush 2 source is no longer private
	- Added comments throughout the source
	- Healed clients are now chosen by the percentage of static health plus temporary health over max health
	- If all clients are at full health, they are all topped off (just in case)

1.3.3 (31-Aug-2014)
	- New player tank spawning method
	- Convars now set more efficiently
	- Initial bot tank will only spawn if tr_spawninterval >= 20
	- Added cvar to enable or disable debugging
	- Added cvar to change how many common infected spawn on the map
	- Added cvar to change bot and player tank speed ratio
	- Ability for player tanks to despawn by holding the walk button for five seconds
	- Plugin will now check for updates at the beginning of a map
	- Plugin will now load the new version at the end of a map
	- Fixed issue with XPMod tank talents not loading on first spawn
	- Bot tank will not be spawned if any infected players are currently dead (to prevent them from taking over)

1.3.2 (11-Aug-2014)
	- Tank Rush 2 releases are no longer private
	- Moved some code around a bit to make it easier to follow
	- Players will now spawn as ghost tanks at the beginning of a round instead of after survivors leave the start area
	- Fixed an issue with survivors not being healed if they have temporary health but their health bar is "full" (i.e. 90% regular + 10% temporary = 100% health)
	- An initial tank will now spawn once tanks are allowed to spawn
	- Added workaround for bug causing rounds not to end after server is started (changes map to c1m1_hotel once the plugin loads)
	- Added dynamic coop compatibility
	- Added auto-update functionality

1.3.1 (17-Jun-2014)
	- Slight change in how hardcore mode works
	- Added cvar for max number of incaps before player is permanently black and white
	- Increased speed of ghost tanks
	- Decreased distance before ghost tanks can spawn

1.3.0 (11-Jun-2014)
	- Players will now properly spawn as ghost tanks all the time
	- Players can now press the "use" button as a ghost tank to teleport to survivors
	- Finales will no longer drop below one minute for tanks to kill the survivors
	- Random special infected will no longer spawn
	- Fixed bug (again) on certain finales where players' screens would get stuck
	- Message advertising the offical TR2 steam group

1.2.2 (17-Apr-2014)
	- Added public cvar for tracking the plugin
	- Added ghost-mode for player tanks
	- Built-in respawning for finale glitches

1.2.1 (11-Apr-2014)
	- Fix for z_common_limit not being set correctly
	- Set z_frustration to 0 to prevent players losing control of tanks
	- Added cvar for max number of tanks alive at a given time

1.2.0 (06-Apr-2014)
	- Tank Rush 2 releases are now private
	- Added built-in collision functionality
	- Condensed cvars
	- Countdown time will now halve after each passing
	- Refined finale time messages
	- Makeshift fix for players glitching on finales
	- Rewrote majority of code

1.1.2 (14-Apr-2014)
	- Added new "hardcore" mode

1.1.1 (09-Apr-2014)
	- Added time limits on finales

1.1.0 (08-Apr-2014)
	- Added cvar to allow only one survivor to be healed upon tank death

1.0.0 (04-Feb-2014)
	- Initial release.

========================================================================================

	To Do:

	- Legacy mode: spawn player tanks one at a time every x seconds, if all player tanks are able to spawn start spawning bot tanks every x seconds
	- Sound effects such as tank noises and effects
	- More cues and interaction with player
	- Menu for information and help
	
======================================================================================*/





//============================================================================================================================================================================================================================================
//																								PLUGIN INCLUDES
//============================================================================================================================================================================================================================================





#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
// Make it so the cURL extension isn't required, but include it if present
#undef REQUIRE_EXTENSIONS
// Make it so the updater plugin isn't required, but include it if present
#undef REQUIRE_PLUGIN

// Require semicolon after each line
#pragma semicolon 1

// Define some strings so you do not have to type them out over and over
#define VERSION				"1.3.4.2"
#define PREFIX				"\x04[Tank Rush]\x03"
#define DEBUG				"\x04[Debug Rush]\x03"
#define BLACKLIST			"STEAM_1:1:7973543, STEAM_1:1:64627513, STEAM_1:0:28431790, STEAM_1:1:15379151, STEAM_1:1:6786756, STEAM_1:0:52246295, STEAM_1:1:1398596, STEAM_1:1:15629348, STEAM_1:1:26680294, STEAM_1:0:57102233, STEAM_1:1:21056792, STEAM_1:0:26747789"
#define UPDATE_URL			"http://psbj.github.io/sourcemod/tankrush2/updatefile.txt"





//============================================================================================================================================================================================================================================
//																								GLOBAL VARIABLES
//============================================================================================================================================================================================================================================





// Set up handles for plugin convars
new Handle:g_hEnable;
new Handle:g_hSpawnInterval;
new Handle:g_hGiveHealth;
new Handle:g_hTankHealth;
new Handle:g_hTankSpeed;
new Handle:g_hTankLimit;
new Handle:g_hCommonLimit;
new Handle:g_hCountdown;
new Handle:g_hCooldown;
new Handle:g_hHardcoreMode;
new Handle:g_hCollision;
new Handle:g_hIncapLimit;
new Handle:g_hCoopStart;
new Handle:g_hDebug;

// Set up handles for game convars
new Handle:g_hDirectorNoBosses;
new Handle:g_hDirectorNoMobs;
new Handle:g_hZFrustration;
new Handle:g_hZTankHealth;
new Handle:g_hZTankSpeed;
new Handle:g_hZTankSpeedVs;
new Handle:g_hZTankWalkSpeed;
new Handle:g_hZCrouchSpeed;
new Handle:g_hZCommonLimit;
new Handle:g_hZBoomerLimit;
new Handle:g_hZChargerLimit;
new Handle:g_hZHunterLimit;
new Handle:g_hZJockeyLimit;
new Handle:g_hZSmokerLimit;
new Handle:g_hZSpitterLimit;
new Handle:g_hSurvivorMaxIncapCount;
new Handle:g_hZGhostSpeed;
new Handle:g_hZGhostTravelDistance;
new Handle:g_hGameMode;

// Set up handles for gamedata signatures
new Handle:g_hZombieAbortControl = INVALID_HANDLE;
new Handle:g_hBecomeGhost = INVALID_HANDLE;
new Handle:g_hStateTransition = INVALID_HANDLE;
new Handle:g_hSetClass = INVALID_HANDLE;
new Handle:g_hCreateAbility = INVALID_HANDLE;
new Handle:g_hOnRevived = INVALID_HANDLE;
new Handle:g_hGameData = INVALID_HANDLE;

// Set up string for storing the current gamemode (coop, versus)
new String:g_sGameMode[24];


// Set up bools for keeping track of plugin and player data
new bool:g_bSpawning;
new bool:g_bCountdown;
new bool:g_bStarted;
new bool:g_bRested;
new bool:g_bCooldown;
new bool:g_bEnded;
new bool:g_bWaiting[MAXPLAYERS+1];
new bool:g_bDespawning[MAXPLAYERS+1];
new bool:g_bWasClientGhost[MAXPLAYERS+1];
new bool:g_bBlackAndWhite[MAXPLAYERS+1];
new bool:g_bFirstTank;
new bool:g_bCoopStart;
new bool:g_bPluginUpdated;

// Set up integers for keeping track of player incap and despawn counts
new g_iIncapCount[MAXPLAYERS+1];
new g_iDespawnCount[MAXPLAYERS+1];

// Set up integers for timer ticks
new g_iSpawnTick;
new g_iCountdownTick;
new g_iCountdownHalf;
new g_iCooldownTick;
new g_iCoopStartTick;
new g_iWaitingTick[MAXPLAYERS+1];
new g_iDespawningTick[MAXPLAYERS+1];

// Set up integer for gamedata ability offset
new g_iAbility = 0;





//============================================================================================================================================================================================================================================
//																								PUBLIC FUNCTIONS
//============================================================================================================================================================================================================================================





public Plugin:myinfo = 
{
	name			= "Tank Rush 2",
	author			= "Phil Bradley",
	description		= "Spawns an endless amount of tanks.",
	version			= VERSION,
	url				= "psbj.github.io"
}

public OnPluginStart()
{
	// Create the convar that handles the version of the plugin and make it public (FCVAR_NOTIFY) so the plugin can be tracked
	CreateConVar("tr_version", VERSION, "Version of the installed plugin", FCVAR_NONE|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	// Create the rest of the convars for the plugin
	g_hEnable							= CreateConVar("tr_enable",			"1",	"0 - Disable plugin, 1 - Enable plugin",																					FCVAR_NONE, true, 0.0, true, 1.0);
	g_hSpawnInterval					= CreateConVar("tr_spawninterval",	"6",	"Time in seconds between tank spawns",																						FCVAR_NONE, true, 1.0, true, 180.0);
	g_hTankHealth						= CreateConVar("tr_tankhealth",		"2000",	"Amount of health tanks will spawn with",																					FCVAR_NONE, true, 1.0, true, 25000.0);
	g_hTankSpeed						= CreateConVar("tr_tankspeed",		"1.08",	"Ratio for bot and player tank speed",																						FCVAR_NONE, true, 0.0, true, 5.0);
	g_hTankLimit						= CreateConVar("tr_tanklimit",		"10",	"Maximum number of tanks allowed to spawn at a given time",																	FCVAR_NONE, true, 1.0, true, 10.0);
	g_hCommonLimit						= CreateConVar("tr_commonlimit",	"0",	"Maximum number of common allowed to spawn at a given time",																FCVAR_NONE, true, 0.0, true, 100.0);
	g_hGiveHealth						= CreateConVar("tr_givehealth",		"2",	"0 - Tank kills do not give health, 1 - Tank kills heal all players, 2 - Tank kills heal player with least health",			FCVAR_NONE, true, 0.0, true, 2.0);
	g_hCountdown						= CreateConVar("tr_countdown",		"240",	"Time in seconds the tanks have to kill the survivors",																		FCVAR_NONE, true, 60.0, true, 600.0);
	g_hCooldown							= CreateConVar("tr_cooldown",		"30",	"Time in seconds for resting periods on finales",																			FCVAR_NONE, true, 1.0, true, 60.0);
	g_hHardcoreMode						= CreateConVar("tr_hardcoremode",	"0",	"0 - Disable hardcore mode, 1 - Enable hardcore mode",																		FCVAR_NONE, true, 0.0, true, 1.0);
	g_hCollision						= CreateConVar("tr_collision",		"0",	"0 - Disable player collision, 1 - Enable player collision",																FCVAR_NONE, true, 0.0, true, 1.0);
	g_hIncapLimit						= CreateConVar("tr_incaplimit",		"4",	"Maximum number of incaps before a player becomes black and white",															FCVAR_NONE, true, 0.0, true, 10.0);
	g_hCoopStart						= CreateConVar("tr_coopstart",		"60",	"Time in seconds before tanks will spawn on coop mode",																		FCVAR_NONE, true, 0.0, true, 180.0);
	g_hDebug							= CreateConVar("tr_debug",			"0",	"0 - Disable debug messages, 1 - Enable debug messages",																	FCVAR_NONE, true, 0.0, true, 1.0);
	
	// Create the convar config file if it does not exist, else run the config file to change convars
	AutoExecConfig(true, "tankrush2");

	// Assign handles to the game convars that the plugin uses
	g_hDirectorNoBosses					= FindConVar("director_no_bosses");
	g_hDirectorNoMobs					= FindConVar("director_no_mobs");
	g_hZFrustration						= FindConVar("z_frustration");
	g_hZTankHealth						= FindConVar("z_tank_health");
	g_hZTankSpeed						= FindConVar("z_tank_speed");
	g_hZTankSpeedVs						= FindConVar("z_tank_speed_vs");
	g_hZTankWalkSpeed					= FindConVar("z_tank_walk_speed");
	g_hZCrouchSpeed						= FindConVar("z_crouch_speed");
	g_hZCommonLimit						= FindConVar("z_common_limit");
	g_hZBoomerLimit						= FindConVar("z_boomer_limit");
	g_hZChargerLimit					= FindConVar("z_charger_limit");
	g_hZHunterLimit						= FindConVar("z_hunter_limit");
	g_hZJockeyLimit						= FindConVar("z_jockey_limit");
	g_hZSmokerLimit						= FindConVar("z_smoker_limit");
	g_hZSpitterLimit					= FindConVar("z_spitter_limit");
	g_hSurvivorMaxIncapCount			= FindConVar("survivor_max_incapacitated_count");
	g_hZGhostSpeed						= FindConVar("z_ghost_speed");
	g_hZGhostTravelDistance				= FindConVar("z_ghost_travel_distance");
	g_hGameMode							= FindConVar("mp_gamemode");

	// Hook when these convars change
	HookConVarChange(g_hEnable, OnConVarChanged);
	HookConVarChange(g_hTankHealth, OnConVarChanged);
	HookConVarChange(g_hTankSpeed, OnConVarChanged);
	HookConVarChange(g_hCommonLimit, OnConVarChanged);
	HookConVarChange(g_hHardcoreMode, OnConVarChanged);
	HookConVarChange(g_hGameMode, OnConVarChanged);
	HookConVarChange(g_hZTankHealth, OnConVarChanged);
	HookConVarChange(g_hZCommonLimit, OnConVarChanged);

	// Hook events that the plugin uses
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("player_incapacitated", Event_PlayerIncap);
	HookEvent("revive_success", Event_ReviveSuccess);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_first_spawn", Event_PlayerFirstSpawn);
	HookEvent("player_left_start_area", Event_LeftStartArea);
	HookEvent("round_start_pre_entity", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("finale_start", Event_FinaleStart);
	HookEvent("item_pickup", Event_ItemPickup);
	HookEvent("heal_success", Event_HealSuccess);
	HookEvent("ghost_spawn_time", Event_EnterGhostMode);

	// Load the gamedata file
	g_hGameData = LoadGameConfigFile("tankrush2");

	// If the file does not exist, set fail state
	if (g_hGameData == INVALID_HANDLE)
	{
		SetFailState("Tank Rush 2 is missing its gamedata file!");
	}
	
	// Else, continue
	else
	{
		// Get the signature for ZombieAbortControl
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "ZombieAbortControl");
		PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		g_hZombieAbortControl = EndPrepSDKCall();

		// If the signature is broken, log the error
		if (g_hZombieAbortControl == INVALID_HANDLE)
		{
			LogError("Tank Rush 2: ZombieAbortControl Signature broken");
		}

		// Get the signature for BecomeGhost
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hBecomeGhost = EndPrepSDKCall();

		// If the signature is broken, log the error
		if (g_hBecomeGhost == INVALID_HANDLE)
		{
			LogError("Tank Rush 2: BecomeGhost Signature broken");
		}

		// Get the signature for State_Transition
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hStateTransition = EndPrepSDKCall();

		// If the signature is broken, log the error
		if (g_hStateTransition == INVALID_HANDLE)
		{
			LogError("Tank Rush 2: State_Transition Signature broken");
		}

		// Get the signature for SetClass
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "SetClass");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSetClass = EndPrepSDKCall();

		// If the signature is broken, log the error
		if (g_hSetClass == INVALID_HANDLE)
		{
			LogError("Tank Rush 2: SetClass Signature broken");
		}
		
		// Get the signature for CTerrorPlayer_OnRevived
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "CTerrorPlayer_OnRevived");
		g_hOnRevived = EndPrepSDKCall();

		// If the signature is broken, log the error
		if (g_hOnRevived == INVALID_HANDLE)
		{
			LogError("Tank Rush 2: CTerrorPlayer_OnRevived Signature broken");
		}
		
		// Get the signature for CreateAbility
		StartPrepSDKCall(SDKCall_Static);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "CreateAbility");
		PrepSDKCall_AddParameter(SDKType_CBasePlayer, SDKPass_Pointer);
		PrepSDKCall_SetReturnInfo(SDKType_CBaseEntity, SDKPass_Pointer);
		g_hCreateAbility = EndPrepSDKCall();

		// If the signature is broken, log the error
		if (g_hCreateAbility == INVALID_HANDLE)
		{
			LogError("Tank Rush 2: CreateAbility Signature broken");
		}

		// Get the offset for oAbility
		g_iAbility = GameConfGetOffset(g_hGameData, "oAbility");
	}

	// Register commands for use
	RegConsoleCmd("sm_gm", Command_God);
	RegConsoleCmd("sm_nc", Command_NoClip);
	RegConsoleCmd("sm_cc", Command_Cheat);
	RegConsoleCmd("sm_ds", Command_Despawn);
	RegConsoleCmd("sm_db", Command_Debug);
	
	// Start the main timer and advert timer
	CreateTimer(1.0, Timer_Ticks, _, TIMER_REPEAT);
	CreateTimer(720.0, Timer_Advert, _, TIMER_REPEAT);
}

public OnConfigsExecuted()
{
	// Once all plugin config files have been executed, set the correct convars in case another plugin changed them
	ToggleConVars();
}

public OnConVarChanged(Handle:hConVar, const String:oldValue[], const String:newValue[])
{
	// When one of the hooked convars is changed, make sure the correct convars are set
	ToggleConVars();
}

public OnClientAuthorized(client, const String:auth[])
{
	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// Get the name of the client that was authorized
		new String:name[24];
		GetClientName(client, name, sizeof(name));

		// If the client is a bot and it is one of the special infected, remove them from the game
		// We check their auth because it is already provided and IsFakeClient() might not return correctly as they're not fully in the game
		if (StrEqual(auth, "BOT", false) && (StrContains(name, "boomer", false) >= 0 || StrContains(name, "charger", false) >= 0 || StrContains(name, "hunter", false) >= 0 || StrContains(name, "jockey", false) >= 0 || StrContains(name, "smoker", false) >= 0 || StrContains(name, "spitter", false) >= 0))
		{
			KickClient(client);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// Get the auth string of the client
	//new String:auth[24];
	new String:auth[32];	
	GetClientAuthId(client, AuthId_Steam2, auth, 32);	
	//GetClientAuthId(client, auth, sizeof(auth));

	// If the client is in the blacklist, continue
	if (StrContains(BLACKLIST, auth, false) >= 0)
	{
		// Remove the client from the game with a random error message
		new iError = GetRandomInt(1000000000, 9999999999);
		KickClient(client, "Unable to parse client's SteamID (%d)", iError);
		return;
	}

	// Hook PostThink for the client
	SDKHook(client, SDKHook_PostThink, OnPostThink);

	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// If the client is in the game and they are not a bot, continue
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			// Print the welcome message
			PrintToChat(client, "%s Welcome to Tank Rush 2! (v%s)", PREFIX, VERSION);

			// If hardcore mode is enabled, continue
			if (GetConVarBool(g_hHardcoreMode))
			{
				// Print message notifying them
				PrintToChat(client, "%s HARDCORE mode is enabled!", PREFIX);
			}

			// If the gamemode is set to coop and the game has not started yet, continue
			if (StrEqual(g_sGameMode, "coop", false) && g_bCoopStart)
			{
				// Print message with how many seconds until start
				new iSeconds = GetConVarInt(g_hCoopStart) - g_iCoopStartTick;
				PrintToChat(client, "%s Tanks will begin spawning in %d seconds!", PREFIX, iSeconds);
			}
		}

		// If the client is in the game and they are the author of the plugin, continue
		if (IsClientInGame(client) && IsClientAuthor(client))
		{
			// Print message notifying everybody
			PrintToChatAll("%s Developer of Tank Rush 2 has joined!", PREFIX);
		}
	}
}

public OnMapStart()
{
	// Reset global variables and check for update
	ResetGlobals();
}

public OnMapEnd()
{
	// Reset global variables
	ResetGlobals();

	// If the plugin was updated, continue
	if (g_bPluginUpdated)
	{
		// Reload the plugin so the new version takes effect
		new String:filename[256];
		GetPluginFilename(INVALID_HANDLE, filename, sizeof(filename));
		ServerCommand("sm plugins reload %s", filename);
		g_bPluginUpdated = false;
	}
}

/*
#define IN_ATTACK        (1 << 0)
#define IN_JUMP            (1 << 1)
#define IN_DUCK            (1 << 2)
#define IN_FORWARD        (1 << 3)
#define IN_BACK            (1 << 4)
#define IN_USE            (1 << 5)
#define IN_CANCEL        (1 << 6)
#define IN_LEFT            (1 << 7)
#define IN_RIGHT        (1 << 8)
#define IN_MOVELEFT        (1 << 9)
#define IN_MOVERIGHT        (1 << 10)
#define IN_ATTACK2        (1 << 11)
#define IN_RUN            (1 << 12)
#define IN_RELOAD        (1 << 13)
#define IN_ALT1            (1 << 14)
#define IN_ALT2            (1 << 15)
#define IN_SCORE        (1 << 16)       // Used by client.dll for when scoreboard is held down
#define IN_SPEED        (1 << 17)    // Player is holding the speed key
#define IN_WALK            (1 << 18)    // Player holding walk key
#define IN_ZOOM            (1 << 19)    // Zoom key for HUD zoom
#define IN_WEAPON1        (1 << 20)    // weapon defines these bits
#define IN_WEAPON2        (1 << 21)    // weapon defines these bits
#define IN_BULLRUSH        (1 << 22)
#define IN_GRENADE1        (1 << 23)    // grenade 1
#define IN_GRENADE2        (1 << 24)    // grenade 2
*/

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// If the walk button is being pressed, continue
		if (buttons & IN_SPEED)
		{
			// If the client is in the game, is not a bot, is on infected team, is not a ghost, and have despawned less than 3 times, continue
			if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3 && !IsPlayerGhost(client) && g_iDespawnCount[client] < 3)
			{
				// Enable despawning for that client
				g_bDespawning[client] = true;
			}
		}

		// If the attack button is being pressed, continue
		if (buttons & IN_ATTACK)
		{
			// If the client is in the game, is not a bot, is on infected team, is a ghost, and the game is on hold, continue
			if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3 && IsPlayerGhost(client) && (g_bCooldown || g_bEnded || g_bWaiting[client]))
			{
				// Stop the button press from going through
				// This is done to stop playings from spawning while the game is on hold
				buttons &= ~IN_ATTACK;
			}
		}
	}
}





//============================================================================================================================================================================================================================================
//																								SDKHOOK CALLBACKS
//============================================================================================================================================================================================================================================





/*

Values for m_ghostSpawnState:

Can spawn									0
Spawning has been disabled					1

Waiting for survivors leave safe room		2
Waiting for final to begin					4

Waiting for tank fight to be over			8
Survivors have escaped						16

The Director has called a time-out			32
Waiting for the next stampede of infected	64

You can be seen by the Survivors			128
You are too close to the Survivors			256

This is a restricted area					512
Something is blocking this spot				1024

*/

public OnPostThink(client)
{
	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// If the client is waiting to respawn, continue
		if (g_bWaiting[client])
		{
			// If the client is a ghost and infected, continue
			if (IsPlayerGhost(client) && GetClientTeam(client) == 3)
			{
				// Change their spawn message to "Spawning has been disabled"
				SetEntProp(client, Prop_Send, "m_ghostSpawnState", 1, 1);
			}
		}

		// If the finale cooldown is currently transpiring, continue
		else if (g_bCooldown)
		{
			// If the client is a ghost and infected, continue
			if (IsPlayerGhost(client) && GetClientTeam(client) == 3)
			{
				// Change their spawn message to "The Director has called a time-out"
				SetEntProp(client, Prop_Send, "m_ghostSpawnState", 32, 1);
			}
		}

		// If the round has ended, continue
		else if (g_bEnded)
		{
			// If the client is a ghost and infected, continue
			if (IsPlayerGhost(client) && GetClientTeam(client) == 3)
			{
				// Change their spawn message to "Survivors have escaped"
				SetEntProp(client, Prop_Send, "m_ghostSpawnState", 16, 1);
			}
		}
	}
}





//============================================================================================================================================================================================================================================
//																								UPDATER CALLBACKS
//============================================================================================================================================================================================================================================





public Updater_OnPluginUpdated()
{
	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// Print messages notifying that there has been an update
		PrintToChatAll("%s Tank Rush 2 has been updated!", PREFIX);
		PrintToChatAll("%s Changes will take effect on map change.", PREFIX);
		g_bPluginUpdated = true;
	}
}





//============================================================================================================================================================================================================================================
//																								COMMAND CALLBACKS
//============================================================================================================================================================================================================================================





public Action:Command_God(client, args)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return Plugin_Handled;
	}

	// If the plugin is enabled and the client is the author of the plugin and alive, continue
	if (GetConVarBool(g_hEnable) && IsClientAuthor(client) && IsPlayerAlive(client))
	{
		// If god mode is not enabled on the client, continue
		if (GetEntProp(client, Prop_Data, "m_takedamage") > 0)
		{
			// Enable god mode on the client
			SetEntProp(client, Prop_Data, "m_takedamage", 0);
			PrintHintText(client, "God mode enabled!");
			return Plugin_Handled;
		}

		else
		{
			// Disable god mode on the client
			SetEntProp(client, Prop_Data, "m_takedamage", 2);
			PrintHintText(client, "God mode disabled!");
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}

public Action:Command_NoClip(client, args)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	// If the plugin is enabled and the client is the author of the plugin and alive, continue
	if (GetConVarBool(g_hEnable) && IsClientAuthor(client) && IsPlayerAlive(client))
	{
		// If noclip is not enabled on the client, continue
		if (GetEntityMoveType(client) == MOVETYPE_WALK)
		{
			// Enable noclip on the client
			SetEntityMoveType(client, MOVETYPE_NOCLIP);
			PrintHintText(client, "NoClip enabled!");
			return Plugin_Handled;
		}

		else
		{
			// Disable noclip on the client
			SetEntityMoveType(client, MOVETYPE_WALK);
			PrintHintText(client, "NoClip disabled!");
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}

public Action:Command_Despawn(client, args)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	// If the plugin is enabled and the client is the author of the plugin, alive, not a ghost, and infected, continue
	if (GetConVarBool(g_hEnable) && IsClientAuthor(client) && IsPlayerAlive(client) && !IsPlayerGhost(client) && GetClientTeam(client) == 3)
	{
		// Despawn the client in a way that allows tank talents on XPMod to be reselected
		PlayerToGhost(client);
		PlayerToRandom(client);
		PlayerToTank(client);
		RetankPlayer(client);
		PlayerToGhost(client);
		PlayerToRandom(client);
		PlayerToTank(client);
		PrintHintText(client, "You have despawned!");
		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action:Command_Cheat(client, args)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	// If the plugin is enabled and the client is the author of the plugin, continue
	if (GetConVarBool(g_hEnable) && IsClientAuthor(client))
	{
		// If there are arguments, continue
		if (GetCmdArgs() > 0)
		{
			// Get the first argument
			new String:arg1[256];
			GetCmdArg(1, arg1, sizeof(arg1));
			// Get the whole argument string
			new String:argstring[256];
			GetCmdArgString(argstring, sizeof(argstring));

			// Remove the cheat flag from the first argument
			new flags = GetCommandFlags(arg1);
			SetCommandFlags(arg1, flags & ~FCVAR_CHEAT);
			// Send the whole argument string through as a commands
			FakeClientCommand(client, argstring);
			// Reapply the cheat flag on the first argument
			SetCommandFlags(arg1, flags|FCVAR_CHEAT);

			PrintHintText(client, "Cheat: %s", argstring);
			return Plugin_Handled;
		}

		return Plugin_Handled;
	}

	return Plugin_Handled;
}

public Action:Command_Debug(client, args)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	// If the plugin is enabled and the client is the author of the plugin, continue
	if (GetConVarBool(g_hEnable) && IsClientAuthor(client))
	{
		// If debugging is disabled, continue
		if (!GetConVarBool(g_hDebug))
		{
			// Enable debugging
			SetConVarBool(g_hDebug, true);
			PrintToChatAll("%s Debugging enabled.", PREFIX);
		}

		else
		{
			// Disable debugging
			SetConVarBool(g_hDebug, false);
			PrintToChatAll("%s Debugging disabled.", PREFIX);
		}

		return Plugin_Handled;
	}

	return Plugin_Handled;
}





//============================================================================================================================================================================================================================================
//																								TIMER CALLBACKS
//============================================================================================================================================================================================================================================





public Action:Timer_Ticks(Handle:timer)
{
	// Select a random human client that will handle tank spawning
	new client = GetRandomClient();

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// If the gamemode is set to coop, continue
		if (StrEqual(g_sGameMode, "coop", false))
		{
			// If the game has not started yet, continue
			if (!g_bSpawning && !g_bCooldown && !g_bCoopStart && !g_bEnded)
			{
				// Enable coop spawning process
				g_bCoopStart = true;
			}
		}

		// If coop start spawning has been enabled, continue
		if (g_bCoopStart)
		{
			// Increase coop tick by one
			g_iCoopStartTick++;

			// If coop ticks >= the set coop start time, continue
			if (g_iCoopStartTick >= GetConVarInt(g_hCoopStart))
			{
				// Enable spawning, reset variables, notify clients
				g_bSpawning = true;
				g_bCoopStart = false;
				g_iCoopStartTick = 0;
				PrintToChatAll("%s Tanks beginning to spawn...", PREFIX);
			}
		}

		// If spawning is enabled, continue
		if (g_bSpawning)
		{
			// Incrase spawn tick by one
			g_iSpawnTick++;

			// If the spawn ticks >= set spawn interval, tank limit hasn't been reached, all the infected are alive, or the first tank has not spawned yet, continue
			if ((g_iSpawnTick >= GetConVarInt(g_hSpawnInterval) && GetTankCount() < GetConVarInt(g_hTankLimit)) && AreInfectedAlive() || (!g_bFirstTank && GetConVarInt(g_hSpawnInterval) >= 20))
			{
				// Use a for loop to go through the clients
				for (new x = 1; x <= MaxClients; x++)
				{
					// If the client is in the game, is not a bot, and is infected, continue
					if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3)
					{
						// If the client is a ghost and is a tank, continue
						if (IsPlayerGhost(x) && IsPlayerTank(x))
						{
							// Take them out of ghost mode
							// We do this so that when a tank is spawned, a ghost tank does not take control of it
							SetEntProp(x, Prop_Send, "m_isGhost", 0, 1);
							g_bWasClientGhost[x] = true;
						}
					}
				}

				// Remove the cheat flag from z_spawn_old
				new flags = GetCommandFlags("z_spawn_old");
				SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
				// Have the random client we chose earlier spawn the tank
				FakeClientCommand(client, "z_spawn_old tank auto");
				// Reapply the cheat flag to z_spawn_old
				SetCommandFlags("z_spawn_old", flags|FCVAR_CHEAT);

				if (GetConVarBool(g_hDebug))
				{
					PrintToChatAll("%s Spawning bot tank (%d/%d).", DEBUG, GetTankCount(), GetConVarInt(g_hTankLimit));
				}

				// Use a for loop to go through the clients
				for (new x = 1; x <= MaxClients; x++)
				{
					// If the client is in the game, is not a bot, and is infected, continue
					if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3)
					{
						// If the client had previously been taken out of ghost mode and they are still a valid tank, continue
						if (g_bWasClientGhost[x] && !IsPlayerGhost(x) && IsPlayerTank(x) && IsPlayerAlive(x))
						{
							// Put them back in ghost mode
							// Note that the plugin goes through this whole code so fast that you don't even notice the process in-game
							SetEntProp(x, Prop_Send, "m_isGhost", 1, 1);
							g_bWasClientGhost[x] = false;
						}
					}
				}

				// Reset the spawn tick so process for the next spawn will start
				g_bFirstTank = true;
				g_iSpawnTick = 0;
			}
		}

		// If the finale countdown has started, continue
		if (g_bCountdown)
		{
			// If this is the first time it was started, continue
			if (!g_bStarted)
			{
				g_bStarted = true;

				// We'll format the time correctly here
				// If the countdown interval > 59 seconds, continue
				if (GetConVarInt(g_hCountdown) > 59)
				{
					// Format the time by deriving the minutes and seconds from the raw time
					new iMinutes = GetConVarInt(g_hCountdown) / 60;
					new iSeconds = GetConVarInt(g_hCountdown) % 60;

					// If the raw time didn't divide evenly into minutes, continue
					if (iSeconds > 0)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Tanks have %d minutes %d seconds to kill the survivors.", PREFIX, iMinutes, iSeconds);
					}

					// If the time comes to more than one minute, continue
					else if (iMinutes > 1)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Survivors have %d minutes to kill the survivors.", PREFIX, iMinutes);
					}

					else
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Survivors have %d minute to kill the survivors.", PREFIX, iMinutes);
					}
				}

				else
				{
					// Print message to all clients notifying of the interval
					new iSeconds = GetConVarInt(g_hCountdown);
					PrintToChatAll("%s Tanks have %d seconds to kill the survivors.", PREFIX, iSeconds);
				}
			}

			// Incrase countdown tick by one
			g_iCountdownTick++;

			// If the survivors haven't rested yet and the tick count >= countdown interval, continue
			if (!g_bRested && g_iCountdownTick >= GetConVarInt(g_hCountdown))
			{
				// Set global variables for the cooldown process
				g_bRested = true;
				g_bSpawning = false;
				g_bCountdown = false;
				g_bCooldown = true;


				// Remove all bot tanks from the game
				KickInfectedBots();
				// Respawn any dead infected clients
				RespawnInfectedPlayers();
				// Put spawned tanks into ghost mode
				PlayersToGhost();
				// Set the class of infected players to a random special infected
				// We do this so that the game things all tanks have died and the survivors will advance
				PlayersToRandom();

				// Reset the countdown ticks
				g_iCountdownTick = 0;
				// Halve the countdown interval so it's easier on the survivors the second time through
				g_iCountdownHalf = GetConVarInt(g_hCountdown) / 2;

				// If half the countdown interval comes to less than 60 seconds, continue
				if (g_iCountdownHalf < 60)
				{
					// Set the countdown interval to 60 seconds
					// We do this so if the survivors make it past many rest periods, the countdown interval will never get to such a low amount that it gets stuck in a loop
					g_iCountdownHalf = 60;
				}

				// We'll format the time correctly here
				// If the cooldown interval > 59 seconds, continue
				if (GetConVarInt(g_hCooldown) > 59)
				{
					// Format the time by deriving the minutes and seconds from the raw time
					new iMinutes = GetConVarInt(g_hCooldown) / 60;
					new iSeconds = GetConVarInt(g_hCooldown) % 60;

					// If the raw time didn't divide evenly into minutes, continue
					if (iSeconds > 0)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Survivors have %d minutes %d seconds to rest.", PREFIX, iMinutes, iSeconds);
					}

					// If the time comes to more than one minute, continue
					else if (iMinutes > 1)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Survivors have %d minutes to rest.", PREFIX, iMinutes);
					}

					else
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Survivors have %d minute to rest.", PREFIX, iMinutes);
					}
				}

				else
				{
					// Print message to all clients notifying of the interval
					new iSeconds = GetConVarInt(g_hCooldown);
					PrintToChatAll("%s Survivors have %d seconds to rest.", PREFIX, iSeconds);
				}
			}

			// If the survivors have already rested and the current countdown tick > the halved countdown interval, continue
			if (g_bRested && g_iCountdownTick >= g_iCountdownHalf)
			{
				// Set global variables for the cooldown process
				g_bSpawning = false;
				g_bCountdown = false;
				g_bCooldown = true;


				// Remove all bot tanks from the game
				KickInfectedBots();
				// Respawn any dead infected clients
				RespawnInfectedPlayers();
				// Put spawned tanks into ghost mode
				PlayersToGhost();
				// Set the class of infected players to a random special infected
				// We do this so that the game things all tanks have died and the survivors will advance
				PlayersToRandom();

				// Reset the countdown ticks
				g_iCountdownTick = 0;
				// Halve the countdown interval so it's easier on the survivors the second time through
				g_iCountdownHalf = g_iCountdownHalf / 2;

				// If half the countdown interval comes to less than 60 seconds, continue
				if (g_iCountdownHalf < 60)
				{
					// Set the countdown interval to 60 seconds
					// We do this so if the survivors make it past many rest periods, the countdown interval will never get to such a low amount that it gets stuck in a loop
					g_iCountdownHalf = 60;
				}

				// We'll format the time correctly here
				// If the cooldown interval > 59 seconds, continue
				if (GetConVarInt(g_hCooldown) > 59)
				{
					// Format the time by deriving the minutes and seconds from the raw time
					new iMinutes = GetConVarInt(g_hCooldown) / 60;
					new iSeconds = GetConVarInt(g_hCooldown) % 60;

					// If the raw time didn't divide evenly into minutes, continue
					if (iSeconds > 0)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Survivors have %d minutes %d seconds to rest.", PREFIX, iMinutes, iSeconds);
					}

					// If the time comes to more than one minute, continue
					else if (iMinutes > 1)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Survivors have %d minutes to rest.", PREFIX, iMinutes);
					}

					else
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Survivors have %d minute to rest.", PREFIX, iMinutes);
					}
				}

				else
				{
					// Print message to all clients notifying of the interval
					new iSeconds = GetConVarInt(g_hCooldown);
					PrintToChatAll("%s Survivors have %d seconds to rest.", PREFIX, iSeconds);
				}
			}
		}

		// If the finale cooldown has started, continue
		if (g_bCooldown)
		{
			// Increase the cooldown tick by one
			g_iCooldownTick++;

			// If the current cooldown tick >= set cooldown interval, continue
			if (g_iCooldownTick >= GetConVarInt(g_hCooldown))
			{

				// Respawn any dead infected clients
				RespawnInfectedPlayers();
				// Change all infected clients to tank
				PlayersToTank();

				// Reset global variables for spawning period
				g_bSpawning = true;
				g_bCountdown = true;
				g_bCooldown = false;
				g_bFirstTank = false;

				g_iCooldownTick = 0;

				// We'll format the time correctly here
				// If the halved countdown interval > 59 seconds, continue
				if (g_iCountdownHalf > 59)
				{
					// Format the time by deriving the minutes and seconds from the raw time
					new iMinutes = g_iCountdownHalf / 60;
					new iSeconds = g_iCountdownHalf % 60;

					// If the raw time didn't divide evenly into minutes, continue
					if (iSeconds > 0)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Tanks have %d minutes %d seconds to kill the survivors.", PREFIX, iMinutes, iSeconds);
					}

					// If the time comes to more than one minute, continue
					else if (iMinutes > 1)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Survivors have %d minutes to kill the survivors.", PREFIX, iMinutes);
					}

					else
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Survivors have %d minute to kill the survivors.", PREFIX, iMinutes);
					}
				}

				else
				{
					// Print message to all clients notifying of the interval
					new iSeconds = g_iCountdownHalf;
					PrintToChatAll("%s Tanks have %d seconds to kill the survivors.", PREFIX, iSeconds);
				}
			}
		}

		// Use a for loop to go through the clients
		for (new x = 1; x <= MaxClients; x++)
		{
			// If the client is in the game, is not a bot, is a ghost, is infected, and is waiting to spawn in, continue
			if (IsClientInGame(x) && !IsFakeClient(x) && IsPlayerGhost(x) && GetClientTeam(x) == 3 && g_bWaiting[x])
			{
				// Increase the spawn waiting tick by one
				g_iWaitingTick[x]++;

				// Calculate number of seconds before client can spawn and display it
				new iSeconds = GetConVarInt(g_hSpawnInterval) - g_iWaitingTick[x];				
				PrintCenterText(client, "You will be able to spawn in %d seconds!", iSeconds);

				// If the client has reached the spawn delay, continue
				if (g_iWaitingTick[x] >= GetConVarInt(g_hSpawnInterval))
				{
					if (GetConVarBool(g_hDebug))
					{
						PrintToChatAll("%s CLIENT %d can now spawn.", DEBUG, x);
					}

					// Notify the client
					PrintCenterText(client, "You can now spawn!");
					// Change global variables allowing them to spawn
					g_bWaiting[x] = false;
					g_iWaitingTick[x] = 0;
				}
			}

			// If the client is in the game, is not a bot, is not a ghost, is infected, and is waiting to despawn, continue
			if (IsClientInGame(x) && !IsFakeClient(x) && !IsPlayerGhost(x) && GetClientTeam(x) == 3 && g_bDespawning[x])
			{
				// Increase the despawn waiting tick by one
				g_iDespawningTick[x]++;

				// Calculate number of seconds before client will despawn
				new iSeconds = 6 - g_iDespawningTick[x];
				PrintCenterText(client, "You will despawn in %d seconds!", iSeconds);

				// If the client is no longer holding the walk button, continue
				if (GetClientButtons(x) != IN_SPEED)
				{
					// Notify the client
					PrintCenterText(client, "Despawn cancelled!");
					// Change global variables to reset despawn status
					g_bDespawning[x] = false;
					g_iDespawningTick[x] = 0;
				}

				// If the client has reached the despawn time, continue
				else if (g_iDespawningTick[x] >= 6)
				{
					if (GetConVarBool(g_hDebug))
					{
						PrintToChatAll("%s CLIENT %d has despawned.", DEBUG, x);
					}

					// Notify the client
					PrintCenterText(client, "You have despawned!");
					// Despawn the client in a way that allows tank talents on XPMod to be reselected
					PlayerToGhost(client);
					PlayerToRandom(client);
					PlayerToTank(client);
					RetankPlayer(client);
					PlayerToGhost(client);
					PlayerToRandom(client);
					PlayerToTank(client);
					// Change global variables to reset despawn status
					g_bDespawning[x] = false;
					g_iDespawningTick[x] = 0;
					g_iDespawnCount[x]++;
				}
			}
		}
	}
}

public Action:Timer_Advert(Handle:timer)
{
	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// Send advertising message to all clients
		PrintToChatAll("%s Join the official Tank Rush 2 steam group!", PREFIX);
		PrintToChatAll("%s steamcommunity.com/groups/tankrush2", PREFIX);
	}
}





//============================================================================================================================================================================================================================================
//																								EVENT CALLBACKS
//============================================================================================================================================================================================================================================





public Action:Event_PlayerSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// Get the client from the event
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// If player collision is disabled, continue
		if (!GetConVarBool(g_hCollision))
		{
			// Disable collision on the client
			new m_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
			SetEntData(client, m_CollisionGroup, 2, 4, true);
		}
	}
}

public Action:Event_PlayerFirstSpawn(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// Get the client from the event
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// If the client is in the game, is not a bot, and is infected, continue
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3)
		{
			if (GetConVarBool(g_hDebug))
			{
				PrintToChatAll("%s XPMod talent fix for CLIENT %d.", DEBUG, client);
			}

			RetankPlayer(client);
		}
	}
}

public Action:Event_PlayerDeath(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// Get the client from the event
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// If hardcore mode is enabled, the client is in the game, is not a bot, and is a survivor, continue
		if (GetConVarBool(g_hHardcoreMode) && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
		{
			// Notify the client of why they died
			PrintHintText(client, "You only get one chance to survive on HARDCORE mode!");
		}

		// If the givehealth convar is set to 1, the client is in the game, is a tank, and spawning is enabled, continue
		if (GetConVarInt(g_hGiveHealth) == 1 && IsClientInGame(client) && IsPlayerTank(client) && g_bSpawning)
		{
			if (GetConVarBool(g_hDebug))
			{
				PrintToChatAll("%s Giving health to ALL CLIENTS.", DEBUG);
			}

			// Use a for loop to go through the clients
			for (new x = 1; x <= MaxClients; x++)
			{
				// If the client is in the game and is a survivor, continue
				if (IsClientInGame(x) && GetClientTeam(x) == 2)
				{
					// Remove the cheat flag from the give command
					new flags = GetCommandFlags("give");
					SetCommandFlags("give", flags & ~FCVAR_CHEAT);
					// Allow the client to heal themselves to full health
					FakeClientCommand(x, "give health");
					// Reapply the cheat flag to the give command
					SetCommandFlags("give", flags|FCVAR_CHEAT);

					// If the client was black-and-white previously, continue
					if (g_bBlackAndWhite[x])
					{ 
						if (GetConVarBool(g_hDebug))
						{
							PrintToChatAll("%s Returning CLIENT %d to black-and-white state.", DEBUG, x);
						}

						// Return the client to black-and-white state
						BlackAndWhite(x);
					}
				}
			}
		}

		// If the givehealth convar is set to 2, the client is in the game, is a tank, and spawning is enabled, continue
		if (GetConVarInt(g_hGiveHealth) == 2 && IsClientInGame(client) && IsPlayerTank(client) && g_bSpawning)
		{
			// Set up integers for comparing health
			new iTotalHealthNew;
			new iTotalHealthOld;
			new iMaxHealthNew;
			new iMaxHealthOld;
			new iIncapHealthNew;
			new iIncapHealthOld;
			new iTotalHealthClient;
			new iIncapClient;

			// Use a for loop to go through the clients
			for (new x = 1; x <= MaxClients; x++)
			{
				// If the client is in the game, is alive, and is a survivor, continue
				if (IsClientInGame(x) && IsPlayerAlive(x) && GetClientTeam(x) == 2)
				{
					// If the client is incapped, continue
					if (IsPlayerIncapped(x))
					{
						// Get the client's incap health
						iIncapHealthNew = GetClientHealth(x);

						// If this is the first client, continue
						if (iIncapClient == 0)
						{
							// Store the clients health and userID
							iIncapHealthOld = iIncapHealthNew;
							iIncapClient = x;
						}

						// If the client's health < previous client's health, continue
						else if (iIncapHealthNew < iIncapHealthOld)
						{
							// Store the clients health and userID
							iIncapHealthOld = iIncapHealthNew;
							iIncapClient = x;
						}
					}

					else
					{
						// Get the client's health information
						iTotalHealthNew = GetClientTotalHealth(x);
						iMaxHealthNew = GetClientMaxHealth(x);

						// If this is the first client, continue
						if (iTotalHealthClient == 0)
						{
							// Store the clients health and userID
							iTotalHealthOld = iTotalHealthNew;
							iMaxHealthOld = iMaxHealthNew;
							iTotalHealthClient = x;
						}

						// If the current client's total health ratio is lower than the previous, continue
						else if (iTotalHealthNew / iMaxHealthNew < iTotalHealthOld / iMaxHealthOld)
						{
							// Store the clients health and userID
							iTotalHealthOld = iTotalHealthNew;
							iMaxHealthOld = iMaxHealthNew;
							iTotalHealthClient = x;
						}
					}
				}
			}

			// If an incapped client was set, continue
			if (iIncapClient > 0)
			{
				if (GetConVarBool(g_hDebug))
				{
					PrintToChatAll("%s Giving health to CLIENT %d.", DEBUG, iIncapClient);
				}

				// Remove the cheat flag from the give command
				new flags = GetCommandFlags("give");
				SetCommandFlags("give", flags & ~FCVAR_CHEAT);
				// Allow the client to heal themselves to full health
				FakeClientCommand(iIncapClient, "give health");
				// Reapply the cheat flag to the give command
				SetCommandFlags("give", flags|FCVAR_CHEAT);

				// If the client was previously black-and-white, continue
				if (g_bBlackAndWhite[iIncapClient])
				{
					if (GetConVarBool(g_hDebug))
					{
						PrintToChatAll("%s Returning CLIENT %d to black-and-white state.", DEBUG, iIncapClient);
					}

					// Return the client to black-and-white state
					BlackAndWhite(iIncapClient);
				}
			}

			// If a low-health client was set, continue
			else if (iTotalHealthClient > 0)
			{
				if (GetConVarBool(g_hDebug))
				{
					PrintToChatAll("%s Giving health to CLIENT %d.", DEBUG, iTotalHealthClient);
				}

				// Remove the cheat flag from the give command
				new flags = GetCommandFlags("give");
				SetCommandFlags("give", flags & ~FCVAR_CHEAT);
				// Allow the client to heal themselves to full health
				FakeClientCommand(iTotalHealthClient, "give health");
				// Reapply the cheat flag to the give command
				SetCommandFlags("give", flags|FCVAR_CHEAT);

				// If the client was previously black-and-white, continue
				if (g_bBlackAndWhite[iTotalHealthClient])
				{
					if (GetConVarBool(g_hDebug))
					{
						PrintToChatAll("%s Returning CLIENT %d to black-and-white state.", DEBUG, iTotalHealthClient);
					}

					// Return the client to black-and-white state
					BlackAndWhite(iTotalHealthClient);
				}
			}

			// If everyone was at full health, continue
			// We do this just to make sure everyone is topped off
			else
			{
				// Use a for loop to go through the clients
				for (new x = 1; x <= MaxClients; x++)
				{
					// If the client is in the game and is a survivor, continue
					if (IsClientInGame(x) && GetClientTeam(x) == 2)
					{
						// Remove the cheat flag from the give command
						new flags = GetCommandFlags("give");
						SetCommandFlags("give", flags & ~FCVAR_CHEAT);
						// Allow the client to heal themselves to full health
						FakeClientCommand(x, "give health");
						// Reapply the cheat flag to the give command
						SetCommandFlags("give", flags|FCVAR_CHEAT);

						// If the client was black-and-white previously, continue
						if (g_bBlackAndWhite[x])
						{ 
							if (GetConVarBool(g_hDebug))
							{
								PrintToChatAll("%s Returning CLIENT %d to black-and-white state.", DEBUG, x);
							}

							// Return the client to black-and-white state
							BlackAndWhite(x);
						}
					}
				}
			}
		}
	}
}

public Action:Event_PlayerIncap(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// Get the client from the event
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// If incap limits are set, the client is in the game, and the client is a survivor, continue
		if (GetConVarInt(g_hIncapLimit) > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			// Increase the client's incap count by one
			g_iIncapCount[client]++;
		}

		// If the client's incap limit >= the set incap limit, continue
		if (g_iIncapCount[client] >= GetConVarInt(g_hIncapLimit))
		{
			if (GetConVarBool(g_hDebug))
			{
				PrintToChatAll("%s Incap limit for CLIENT %d reached.", DEBUG, client);
			}

			// Set this bool so when the client is revived they will be returned to black-and-white state
			g_bBlackAndWhite[client] = true;
		}
	}
}


public Action:Event_ReviveSuccess(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// Get the client from the event
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{

		// If the client was previously black-and-white and is in the game, continue
		if (g_bBlackAndWhite[client] && IsClientInGame(client))
		{
			if (GetConVarBool(g_hDebug))
			{
				PrintToChatAll("%s Returning CLIENT %d to black-and-white state.", DEBUG, client);
			}

			// Return the client to black-and-white state
			BlackAndWhite(client);
		}
	}
}

public Action:Event_RoundStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// Reset global variables for a new round
		ResetGlobals();

		// Use a for loop to go through the clients
		for (new x = 1; x <= MaxClients; x++)
		{
			// If the client is in the game, is not a bot, and is infected, continue
			if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3)
			{
				// Respawn the player to fix occasional bug where screens get stuck
				RespawnPlayer(x);
			}
		}
	}
}

public Action:Event_LeftStartArea(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// If the plugin is enabled and the game mode is not set to coop, continue
	if (GetConVarBool(g_hEnable) && !StrEqual(g_sGameMode, "coop", false))
	{
		// Notify players that tanks will begin spawning
		g_bSpawning = true;
		PrintToChatAll("%s Tanks beginning to spawn...", PREFIX);
	}
}

public Action:Event_RoundEnd(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{

		// Reset global variables for a new round
		ResetGlobals();
		// Remove all bot tanks from the game
		KickInfectedBots();

		// Use a for loop to go through the clients
		for (new x = 1; x <= MaxClients; x++)
		{
			// If the client is in the game, is not a bot, is alive, is not a ghost, and is infected, continue
			if (IsClientInGame(x) && !IsFakeClient(x) && IsPlayerAlive(x) && !IsPlayerGhost(x) && GetClientTeam(x) == 3)
			{
				// Return the client to ghost state
				PlayerToGhost(x);
			}
		}

		// Set the round ended bool to true
		g_bEnded = true;
	}
}

public Action:Event_FinaleStart(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		//  Set the finale bool to true
		g_bCountdown = true;
	}
}

public Action:Event_ItemPickup(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// Grab the client's client number
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		// Grab the name of the item the client picked up
		new String:item[24];
		GetEventString(event, "item", item, sizeof(item));

		// If the client is in the game, is not a bot, and is infected, continue
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3)
		{
			// If the client spawned as a special infected, continue
			if (StrEqual(item, "boomer_claw") || StrEqual(item, "charger_claw") || StrEqual(item, "hunter_claw") || StrEqual(item, "jockey_claw") || StrEqual(item, "smoker_claw") || StrEqual(item, "spitter_claw"))
			{
				if (GetConVarBool(g_hDebug))
				{
					PrintToChatAll("%s Transitioning CLIENT %d to tank and ghost.", DEBUG, client);
				}

				// Return the client to ghost state
				PlayerToGhost(client);
				// Change the client's class to random infected
				PlayerToRandom(client);
				// Change the client to a tank
				PlayerToTank(client);
			}
		}
	}
}

public Action:Event_HealSuccess(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// Grab the client's client number
	new client = GetClientOfUserId(GetEventInt(event, "subject"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (GetConVarBool(g_hEnable))
	{
		// If the client was previous black-and-white and is in the game, continue
		if (g_bBlackAndWhite[client] && IsClientInGame(client))
		{
			if (GetConVarBool(g_hDebug))
			{
				PrintToChatAll("%s Returning CLIENT %d to black-and-white state.", DEBUG, client);
			}

			// Return the client to black-and-white state
			BlackAndWhite(client);
		}
	}
}

public Action:Event_EnterGhostMode(Handle:event, String:event_name[], bool:dontBroadcast)
{
	// Grab the client's client number
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, the client is dead, and the client isn't a ghost, continue
	if (GetConVarBool(g_hEnable) && !IsPlayerAlive(client) && !IsPlayerGhost(client))
	{
		if (GetConVarBool(g_hDebug))
		{
			PrintToChatAll("%s Respawning CLIENT %d.", DEBUG, client);
		}

		// Respawn the client 
		RespawnGhost(client);
		// Set the respawn waiting bool to true
		g_bWaiting[client] = true;
	}

	return;
}





//============================================================================================================================================================================================================================================
//																								CUSTOM FUNCTIONS
//============================================================================================================================================================================================================================================





ToggleConVars()
{
	// Use a switch to get the status of the plugin
	switch(GetConVarBool(g_hEnable))
	{
		// If the plugin is disabled, do this
		case 0:
		{
			// Reset change convars to their default value
			ResetConVar(g_hDirectorNoBosses);
			ResetConVar(g_hDirectorNoMobs);
			ResetConVar(g_hZFrustration);
			ResetConVar(g_hZTankHealth);
			ResetConVar(g_hZTankSpeed);
			ResetConVar(g_hZTankSpeedVs);
			ResetConVar(g_hZTankWalkSpeed);
			ResetConVar(g_hZCrouchSpeed);
			ResetConVar(g_hZCommonLimit);
			ResetConVar(g_hZBoomerLimit);
			ResetConVar(g_hZChargerLimit);
			ResetConVar(g_hZHunterLimit);
			ResetConVar(g_hZJockeyLimit);
			ResetConVar(g_hZSmokerLimit);
			ResetConVar(g_hZSpitterLimit);
			ResetConVar(g_hSurvivorMaxIncapCount);
			ResetConVar(g_hZGhostSpeed);
			ResetConVar(g_hZGhostTravelDistance);
		}

		// If the plugin is enabled, do this
		case 1:
		{
			// Grab the current gamemode
			GetConVarString(g_hGameMode, g_sGameMode, sizeof(g_sGameMode));

			// Disable bosses, mobs, and tank frustration
			SetConVarInt(g_hDirectorNoBosses, 1);
			SetConVarInt(g_hDirectorNoMobs, 1);
			SetConVarInt(g_hZFrustration, 0);

			// Reset these convars to their default values as they are adjusted by ratio and not direct value
			ResetConVar(g_hZTankSpeed);
			ResetConVar(g_hZTankSpeedVs);
			ResetConVar(g_hZTankWalkSpeed);
			ResetConVar(g_hZCrouchSpeed);
			// Grab the ratio that the convars will be adjusted for
			new Float:fTankSpeed = GetConVarFloat(g_hTankSpeed);
			new Float:fZTankSpeed = GetConVarFloat(g_hZTankSpeed);
			new Float:fZTankSpeedVs = GetConVarFloat(g_hZTankSpeedVs);
			new Float:fZTankWalkSpeed = GetConVarFloat(g_hZTankWalkSpeed);
			new Float:fZCrouchSpeed = GetConVarFloat(g_hZCrouchSpeed);
			// Calculate the new values for the convars
			//fZTankSpeed = FloatMul(fTankSpeed, fZTankSpeed);
			//fZTankSpeedVs = FloatMul(fTankSpeed, fZTankSpeedVs);
			//fZTankWalkSpeed = FloatMul(fTankSpeed, fZTankWalkSpeed);
			//fZCrouchSpeed = FloatMul(fTankSpeed, fZCrouchSpeed);
			fZTankSpeed = (fTankSpeed, fZTankSpeed);
			fZTankSpeedVs = (fTankSpeed, fZTankSpeedVs);
			fZTankWalkSpeed = (fTankSpeed, fZTankWalkSpeed);
			fZCrouchSpeed = (fTankSpeed, fZCrouchSpeed);			
			// Round the floats up to integers
			new iZTankSpeed = RoundToCeil(fZTankSpeed);
			new iZTankSpeedVs = RoundToCeil(fZTankSpeedVs);
			new iZTankWalkSpeed = RoundToCeil(fZTankWalkSpeed);
			new iZCrouchSpeed = RoundToCeil(fZCrouchSpeed);
			// Apply the new values to the convars
			SetConVarInt(g_hZTankSpeed, iZTankSpeed);
			SetConVarInt(g_hZTankSpeedVs, iZTankSpeedVs);
			SetConVarInt(g_hZTankWalkSpeed, iZTankWalkSpeed);
			SetConVarInt(g_hZCrouchSpeed, iZCrouchSpeed);

			// Set the infected limits (for some reason this doesn't work on certain portions of maps)
			SetConVarInt(g_hZBoomerLimit, 0);
			SetConVarInt(g_hZChargerLimit, 0);
			SetConVarInt(g_hZHunterLimit, 0);
			SetConVarInt(g_hZJockeyLimit, 0);
			SetConVarInt(g_hZSmokerLimit, 0);
			SetConVarInt(g_hZSpitterLimit, 0);

			// Increase the ghost movement speed
			SetConVarInt(g_hZGhostSpeed, 850);
			// Remove the linear distance requirement for spawning
			SetConVarInt(g_hZGhostTravelDistance, 0);

			// If the plugin tank health convar is different from the game convar, continue
			if (GetConVarInt(g_hZTankHealth) != GetConVarInt(g_hTankHealth))
			{
				// Update the convar
				SetConVarInt(g_hZTankHealth, GetConVarInt(g_hTankHealth));
			}

			// If the plugin common limit convar is different from the game convar, continue
			if (GetConVarInt(g_hZCommonLimit) != GetConVarInt(g_hCommonLimit))
			{
				// Update the convar
				SetConVarInt(g_hZCommonLimit, GetConVarInt(g_hCommonLimit));
			}

			// Use a switch to get the status of hardcore mode
			switch(GetConVarBool(g_hHardcoreMode))
			{
				// If hardcore mode is disabled, do this
				case 0:
				{
					// Update the incap limit
					SetConVarInt(g_hSurvivorMaxIncapCount, GetConVarInt(g_hIncapLimit));
				}

				// If hardcore mode is enabled, do this
				case 1:
				{
					// Remove incap limits altogether (permanently black-and-whtie)
					SetConVarInt(g_hSurvivorMaxIncapCount, 0);
				}
			}
		}
	}
}

ResetGlobals()
{
	// Use a for loop to go through the clients
	for (new x = 1; x <= MaxClients; x++)
	{
		// Reset client-specific variables
		g_bWasClientGhost[x] = false;
		g_bBlackAndWhite[x] = false;
		g_bWaiting[x] = false;
		g_bDespawning[x] = false;
		g_iIncapCount[x] = 0;
		g_iDespawnCount[x] = 0;
		g_iWaitingTick[x] = 0;
		g_iDespawningTick[x] = 0;
	}

	// Reset other variables
	g_bSpawning = false;
	g_bCountdown = false;
	g_bStarted = false;
	g_bRested = false;
	g_bCooldown = false;
	g_bEnded = false;
	g_bFirstTank = false;
	g_bCoopStart = false;
	g_iSpawnTick = 0;
	g_iCountdownTick = 0;
	g_iCooldownTick = 0;
	g_iCoopStartTick = 0;
}

GetRandomClient()
{
	// Use a for loop to go through the clients
	for (new x = 1; x <= MaxClients; x++ )
	{
		// If the client is in the game and not a bot, continue
		if (IsClientInGame(x) && !IsFakeClient(x))
		{
			// Return the first client that meets the criteria
			return x;
		}
	}

	// If there isn't one, return the server client
	return 0;
}

KickInfectedBots()
{
	// Use a for loop to go through the clients
	for (new x = 1; x <= MaxClients; x++)
	{
		// If the client is in the game, is a bot, and is infected, continue
		if (IsClientInGame(x) && IsFakeClient(x) && GetClientTeam(x) == 3)
		{
			// Remove the client from the game
			KickClient(x);
		}
	}

}

PlayersToGhost()
{
	// Use a for loop to go through the clients
	for (new x = 1; x <= MaxClients; x++)
	{
		// If the client is in the game, is not a bot, and is infected, continue
		if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3)
		{
			// If the player is alive, continue
			if (IsPlayerAlive(x))
			{
				// Return client to ghost state
				PlayerToGhost(x);
			}
		}
	}
}

PlayersToRandom()
{
	// Use a for loop to go through the clients
	for (new x = 1; x <= MaxClients; x++)
	{
		// If the client is in the game, is not a bot, and is infected, continue
		if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3)
		{
			// If the player is alive, continue
			if (IsPlayerAlive(x))
			{
				// Select a random special infected class and change them to it
				new i = GetRandomInt(1, 6);
				SDKCall(g_hSetClass, x, i);
			}
		}
	}
}

PlayersToTank()
{
	// Use a for loop to go through the clients
	for (new x = 1; x <= MaxClients; x++)
	{
		// If the client is in the game, is not a bot, and is infected, continue
		if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3)
		{
			// If the player is alive, continue
			if (IsPlayerAlive(x))
			{
				// Change the client to a tank
				SDKCall(g_hSetClass, x, 8);
			}
		}
	}
}

RespawnInfectedPlayers()
{
	// Use a for loop to go through the clients
	for (new x = 1; x <= MaxClients; x++)
	{
		// If the client is in the game, is not a bot, is infected, and is not alive, continue
		if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3 && !IsPlayerAlive(x))
		{
			// Respawn the client
			RespawnPlayer(x);
			// Change them to a tank
			PlayerToTank(x);
			// Return them to a ghost state
			PlayerToGhost(x);
		}
	}
}

PlayerToGhost(client)
{
	// Remove the cheat flag from the give command
	new flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	// Allow the client to heal themselves to full health
	FakeClientCommand(client, "give health");
	// Reapply the cheat flag to the give command
	SetCommandFlags("give", flags|FCVAR_CHEAT);

	new m_vecVelocity0 = FindSendPropInfo("CTerrorPlayer", "m_vecVelocity[0]");

	decl Float:AbsOrigin[3];
	decl Float:EyeAngles[3];
	decl Float:Velocity[3];

	GetClientAbsOrigin(client, AbsOrigin);
	GetClientEyeAngles(client, EyeAngles);

	Velocity[0] = GetEntDataFloat(client, m_vecVelocity0);
	Velocity[1] = GetEntDataFloat(client, m_vecVelocity0 + 4);
	Velocity[2] = GetEntDataFloat(client, m_vecVelocity0 + 8);

	new m_isCulling = FindSendPropInfo("CTerrorPlayer", "m_isCulling");
	SetEntData(client, m_isCulling, 1, 1);
	// Return the client to ghost state
	SDKCall(g_hZombieAbortControl, client, 0.0);
	
	// Teleport entity to their previous position (client will be stuck in the ground otherwise)
	TeleportEntity(client, AbsOrigin, EyeAngles, Velocity);
}

PlayerToRandom(client)
{
	// If the client is in the game, is not a bot, and is infected, continue
	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		// If the player is alive, continue
		if (IsPlayerAlive(client))
		{
			// Select a random special infected class and change them to it
			new i = GetRandomInt(1, 6);
			SDKCall(g_hSetClass, client, i);
		}
	}
}

PlayerToTank(client)
{
	// Grab the name of their weapon (charger_claw, hunter_claw, etc.)
	new WeaponIndex = GetPlayerWeaponSlot(client, 0);
	// Remove it from them
	RemovePlayerItem(client, WeaponIndex);

	// Change client to a tank
	SDKCall(g_hSetClass, client, 8);
	// Give the client the appropriate weapon (tank_claw)
	SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, client), g_iAbility));
}

RespawnPlayer(client)
{
	SDKCall(g_hStateTransition, client, 8);
	SDKCall(g_hBecomeGhost, client, 1);
	SDKCall(g_hStateTransition, client, 6);
	SDKCall(g_hBecomeGhost, client, 1);
}

RespawnGhost(client)
{
	SDKCall(g_hStateTransition, client, 6);
	SDKCall(g_hBecomeGhost, client, 1);
}

RetankPlayer(client)
{
	new m_vecVelocity0 = FindSendPropInfo("CTerrorPlayer", "m_vecVelocity[0]");

	decl Float:AbsOrigin[3];
	decl Float:EyeAngles[3];
	decl Float:Velocity[3];

	GetClientAbsOrigin(client, AbsOrigin);
	GetClientEyeAngles(client, EyeAngles);

	Velocity[0] = GetEntDataFloat(client, m_vecVelocity0);
	Velocity[1] = GetEntDataFloat(client, m_vecVelocity0 + 4);
	Velocity[2] = GetEntDataFloat(client, m_vecVelocity0 + 8);

	new m_isCulling = FindSendPropInfo("CTerrorPlayer", "m_isCulling");
	SetEntData(client, m_isCulling, 1, 1);
	SDKCall(g_hStateTransition, client, 6);
	SDKCall(g_hBecomeGhost, client, 1);
	
	TeleportEntity(client, AbsOrigin, EyeAngles, Velocity);
}

BlackAndWhite(client)
{
	// Change the following netprops so the game thinks the client is black-and-white
	SetEntProp(client, Prop_Send, "m_currentReviveCount", GetConVarInt(FindConVar("survivor_max_incapacitated_count")));
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
	SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	// Apply the black-and-white effects to the client's screen
	SDKCall(g_hOnRevived, client);
}

GetTankCount()
{
	new iTankCount;

	// Use a for loop to go through the clients
	for (new x = 1; x <= MaxClients; x++)
	{
		// If the client is in the game and is a tank, continue
		if (IsClientInGame(x) && IsPlayerTank(x))
		{
			// Increase the tank count by one
			iTankCount++;
		}
	}

	// Return the tank count
	return iTankCount;
}

GetClientMaxHealth(client)
{
	// If the client doesn't exist, is not a valid entity, is not in game, is not alive, or is an observer, continue
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client))
	{
		// Return -1 as their health
		return -1;
	}

	// Grab their max health from the netprop
	new MaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
	// Return their max health
	return MaxHealth;
}

GetClientTotalHealth(client)
{
	// If the client doesn't exist, is not a valid entity, is not in game, is not alive, or is an observer, continue
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client))
	{
		return -1;
	}

	// If the client is not a survivor, continue
	if (GetClientTeam(client) != 2)
	{
		// Return their health from the GetClientHealth function
		return GetClientHealth(client);
	}

	// Grab the client's temporary health buffer
	new Float:buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	// Grab the client's static health
	new StaticHealth = GetClientHealth(client);
	new Float:TempHealth;

	// If there is no buffer, continue
	if (buffer <= 0.0)
	{
		// Grab the client's temporary health as 0
		TempHealth = 0.0;
	}

	else
	{
		// Calculate how long it's been since the player recieved that buffer
		new Float:difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		// Grab the decay rate of temporary health
		new Float:decay = GetConVarFloat(FindConVar("pain_pills_decay_rate"));
		new Float:constant = 1.0/decay;
		// Calculate how much temporary health the client currently has
		TempHealth = buffer - (difference / constant);
	}

	// If the temporary health is negative for some reason, continue
	if (TempHealth < 0.0)
	{
		// Grab the client's temporary health as 0
		TempHealth = 0.0;
	}

	// Return the rounded down value of their static health plus temporary health
	return RoundToFloor(StaticHealth + TempHealth);
}

bool:AreInfectedAlive()
{
	new iDeadCount;

	// Use a for loop to go through the clients
	for (new x = 1; x <= MaxClients; x++)
	{
		// If the client is in the game, is not a bot, is not alive, and is infected, continue
		if (IsClientInGame(x) && !IsFakeClient(x) && !IsPlayerAlive(x) && GetClientTeam(x) == 3)
		{
			// Increase dead count by one
			iDeadCount++;
		}
	}

	// If there dead clients, continue
	if (iDeadCount > 0)
	{
		// Return false
		return false;
	}

	// If all clients are alive, continue
	else
	{
		// Return true
		return true;
	}

}

bool:IsPlayerIncapped(client)
{
	// Return the incap status from the netpop
	return bool:GetEntProp(client, Prop_Send, "m_isIncapacitated");
}

bool:IsPlayerGhost(client)
{
	// Return the ghost status from the netprop
	return bool:GetEntProp(client, Prop_Send, "m_isGhost");
}

bool:IsPlayerTank(client)
{
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == 8)
	{
		return true;
	}

	else
	{
		return false;
	}

}

bool:IsClientAuthor(client)
{
	// Grab the client's steamID
	//new String:auth[24];
	new String:auth[32];
	GetClientAuthId(client, AuthId_Steam2, auth, 32);	
	//GetClientAuthId(client, auth, sizeof(auth));

	// If it matches the author's steamID, continue
	if (StrEqual(auth, "STEAM_1:0:39841182"))
	{
		// Return true
		return true;
	}

	// If it doesn't match, continue
	else
	{
		// Return false
		return false;
	}
}