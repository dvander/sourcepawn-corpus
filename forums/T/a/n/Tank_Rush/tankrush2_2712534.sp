
//============================================================================================================================================================================================================================================
//																								PLUGIN INFO
//============================================================================================================================================================================================================================================





/*=======================================================================================

	Plugin Info:

*	Name	:	Tank Rush 2
*	Author	:	Phil Bradley
*	Descrp	:	Spawns an endless amount of tanks.
*	Version :	1.3.5
*	Link	:	psbj.github.io

========================================================================================

	Change Log:

1.3.5 (01-01-2020)
	- New Syntax and some Methodmaps
	- Removed useless and unused code
	- Cleaned some code and whitespace
	- Changed to SDKHook_SpawnPost from z_common_limit
	- Added L4D1 support
	
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



// Require semicolon after each line
#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// Define some strings so you do not have to type them out over and over
#define VERSION				"1.3.5"
#define PREFIX				"\x04[MT]\x03"
#define DEBUG				"\x04[Debug Rush]\x03"
#define BLACKLIST			"STEAM_1:1:7973543, STEAM_1:1:64627513, STEAM_1:0:28431790, STEAM_1:1:15379151, STEAM_1:1:6786756, STEAM_1:0:52246295, STEAM_1:1:1398596, STEAM_1:1:15629348, STEAM_1:1:26680294, STEAM_1:0:57102233, STEAM_1:1:21056792, STEAM_1:0:26747789"
#define UPDATE_URL			"http://psbj.github.io/sourcemod/tankrush2/updatefile.txt"





//============================================================================================================================================================================================================================================
//																								GLOBAL VARIABLES
//============================================================================================================================================================================================================================================





// Set up handles for plugin convars
ConVar g_hEnable;
ConVar g_hSpawnInterval;
ConVar g_hGiveHealth;
ConVar g_hTankHealth;
ConVar g_hTankSpeed;
ConVar g_hTankLimit;
ConVar g_hCountdown;
ConVar g_hCooldown;
ConVar g_hHardcoreMode;
ConVar g_hCollision;
ConVar g_hIncapLimit;
ConVar g_hCoopStart;
ConVar g_hDebug;

// Set up handles for game convars
ConVar g_hDirectorNoBosses;
ConVar g_hDirectorNoSpecials;
ConVar g_hDirectorNoMobs;
ConVar g_hZFrustration;
ConVar g_hZTankHealth;
ConVar g_hZTankSpeed;
ConVar g_hZTankSpeedVs;
ConVar g_hZTankWalkSpeed;
ConVar g_hZCrouchSpeed;
ConVar g_hZBoomerLimit;
ConVar g_hZChargerLimit;
ConVar g_hZHunterLimit;
ConVar g_hZJockeyLimit;
ConVar g_hZSmokerLimit;
ConVar g_hZSpitterLimit;
ConVar g_hSurvivorMaxIncapCount;
ConVar g_hZGhostSpeed;
ConVar g_hZGhostTravelDistance;
ConVar g_hGameMode;

// Set up handles for gamedata signatures
Handle g_hZombieAbortControl = null;
Handle g_hBecomeGhost = null;
Handle g_hStateTransition = null;
Handle g_hSetClass = null;
Handle g_hCreateAbility = null;
Handle g_hOnRevived = null;
Handle g_hGameData = null;

// Set up string for storing the current gamemode (coop, versus)
char g_sGameMode[24];


// Set up bools for keeping track of plugin and player data
bool g_bSpawning;
bool g_bCountdown;
bool g_bStarted;
bool g_bRested;
bool g_bCooldown;
bool g_bEnded;
bool g_bWaiting[MAXPLAYERS+1];
bool g_bDespawning[MAXPLAYERS+1];
bool g_bWasClientGhost[MAXPLAYERS+1];
bool g_bBlackAndWhite[MAXPLAYERS+1];
bool g_bFirstTank;
bool g_bCoopStart;

// Set up integers for keeping track of player incap and despawn counts
int g_iIncapCount[MAXPLAYERS+1];
int g_iDespawnCount[MAXPLAYERS+1];

// Set up integers for timer ticks
int g_iSpawnTick;
int g_iCountdownTick;
int g_iCountdownHalf;
int g_iCooldownTick;
int g_iCoopStartTick;
int g_iWaitingTick[MAXPLAYERS+1];
int g_iDespawningTick[MAXPLAYERS+1];

// Set up integer for gamedata ability offset
int g_iAbility = 0;





//============================================================================================================================================================================================================================================
//																								PUBLIC FUNCTIONS
//============================================================================================================================================================================================================================================





public Plugin myinfo = 
{
	name			= "Tank Rush 2",
	author			= "Phil Bradley",
	description		= "Spawns an endless amount of tanks.",
	version			= VERSION,
	url				= "psbj.github.io"
}

public void OnPluginStart()
{
	// Create the convar that handles the version of the plugin and make it public (FCVAR_NOTIFY) so the plugin can be tracked
	CreateConVar("tr_version", VERSION, "Version of the installed plugin", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);

	// Create the rest of the convars for the plugin
	g_hEnable							= CreateConVar("tr_enable",			"1",	"0 - Disable plugin, 1 - Enable plugin",																					_, true, 0.0, true, 1.0);
	g_hSpawnInterval					= CreateConVar("tr_spawninterval",	"6",	"Time in seconds between tank spawns",																						_, true, 1.0, true, 180.0);
	g_hTankHealth						= CreateConVar("tr_tankhealth",		"4000",	"Amount of health tanks will spawn with",																					_, true, 1.0, true, 25000.0);
	g_hTankSpeed						= CreateConVar("tr_tankspeed",		"1.08",	"Ratio for bot and player tank speed",																						_, true, 0.0, true, 5.0);
	g_hTankLimit						= CreateConVar("tr_tanklimit",		"10",	"Maximum number of tanks allowed to spawn at a given time",																	_, true, 1.0, true, 10.0);
	g_hGiveHealth						= CreateConVar("tr_givehealth",		"2",	"0 - Tank kills do not give health, 1 - Tank kills heal all players, 2 - Tank kills heal player with least health",			_, true, 0.0, true, 2.0);
	g_hCountdown						= CreateConVar("tr_countdown",		"240",	"Time in seconds the tanks have to kill the survivors",																		_, true, 60.0, true, 600.0);
	g_hCooldown							= CreateConVar("tr_cooldown",		"30",	"Time in seconds for resting periods on finales",																			_, true, 1.0, true, 60.0);
	g_hHardcoreMode						= CreateConVar("tr_hardcoremode",	"0",	"0 - Disable hardcore mode, 1 - Enable hardcore mode",																		_, true, 0.0, true, 1.0);
	g_hCollision						= CreateConVar("tr_collision",		"0",	"0 - Disable player collision, 1 - Enable player collision",																_, true, 0.0, true, 1.0);
	g_hIncapLimit						= CreateConVar("tr_incaplimit",		"4",	"Maximum number of incaps before a player becomes black and white",															_, true, 0.0, true, 10.0);
	g_hCoopStart						= CreateConVar("tr_coopstart",		"60",	"Time in seconds before tanks will spawn on coop mode",																		_, true, 0.0, true, 180.0);
	g_hDebug							= CreateConVar("tr_debug",			"0",	"0 - Disable debug messages, 1 - Enable debug messages",																	_, true, 0.0, true, 1.0);
	
	// Create the convar config file if it does not exist, else run the config file to change convars
	AutoExecConfig(true, "tankrush2");

	// Assign handles to the game convars that the plugin uses
	g_hDirectorNoBosses					= FindConVar("director_no_bosses");
	g_hDirectorNoSpecials					= FindConVar("director_no_specials");
	g_hDirectorNoMobs					= FindConVar("director_no_mobs");
	g_hZFrustration						= FindConVar("z_frustration");
	g_hZTankHealth						= FindConVar("z_tank_health");
	g_hZTankSpeed						= FindConVar("z_tank_speed");
	g_hZTankSpeedVs						= FindConVar("z_tank_speed_vs");
	g_hZTankWalkSpeed					= FindConVar("z_tank_walk_speed");
	g_hZCrouchSpeed						= FindConVar("z_crouch_speed");
	if (g_bLeft4Dead2()) g_hZBoomerLimit						= FindConVar("z_boomer_limit");
	if (g_bLeft4Dead2()) g_hZChargerLimit						= FindConVar("z_charger_limit");
	g_hZHunterLimit						= FindConVar("z_hunter_limit");
	if (g_bLeft4Dead2()) g_hZJockeyLimit						= FindConVar("z_jockey_limit");
	if (g_bLeft4Dead2()) g_hZSmokerLimit						= FindConVar("z_smoker_limit");
	if (g_bLeft4Dead2()) g_hZSpitterLimit					= FindConVar("z_spitter_limit");
	g_hSurvivorMaxIncapCount			= FindConVar("survivor_max_incapacitated_count");
	g_hZGhostSpeed						= FindConVar("z_ghost_speed");
	g_hZGhostTravelDistance				= FindConVar("z_ghost_travel_distance");
	g_hGameMode							= FindConVar("mp_gamemode");

	// Hook when these convars change
	g_hEnable.AddChangeHook(OnConVarChanged);
	g_hTankHealth.AddChangeHook(OnConVarChanged);
	g_hTankSpeed.AddChangeHook(OnConVarChanged);
	g_hHardcoreMode.AddChangeHook(OnConVarChanged);
	g_hGameMode.AddChangeHook(OnConVarChanged);
	g_hZTankHealth.AddChangeHook(OnConVarChanged);

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
	if (g_hGameData == null)
	{
		SetFailState("Tank Rush 2 is missing its gamedata file!");
	}
	
	// Else, continue
	else
	{
		// Get the signature for ZombieAbortControl
		if (g_bLeft4Dead2())
		{		
		    StartPrepSDKCall(SDKCall_Player);
		    PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "ZombieAbortControl");
		    PrepSDKCall_AddParameter(SDKType_Float, SDKPass_Plain);
		    g_hZombieAbortControl = EndPrepSDKCall();

		    // If the signature is broken, log the error
		    if (g_hZombieAbortControl == null)
		    {
			    LogError("Tank Rush 2: ZombieAbortControl Signature broken");
		    }
        }
		
		// Get the signature for BecomeGhost
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "BecomeGhost");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hBecomeGhost = EndPrepSDKCall();

		// If the signature is broken, log the error
		if (g_hBecomeGhost == null)
		{
			LogError("Tank Rush 2: BecomeGhost Signature broken");
		}

		// Get the signature for State_Transition
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "State_Transition");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hStateTransition = EndPrepSDKCall();

		// If the signature is broken, log the error
		if (g_hStateTransition == null)
		{
			LogError("Tank Rush 2: State_Transition Signature broken");
		}

		// Get the signature for SetClass
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "SetClass");
		PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
		g_hSetClass = EndPrepSDKCall();

		// If the signature is broken, log the error
		if (g_hSetClass == null)
		{
			LogError("Tank Rush 2: SetClass Signature broken");
		}
		
		// Get the signature for CTerrorPlayer_OnRevived
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(g_hGameData, SDKConf_Signature, "CTerrorPlayer_OnRevived");
		g_hOnRevived = EndPrepSDKCall();

		// If the signature is broken, log the error
		if (g_hOnRevived == null)
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
		if (g_hCreateAbility == null)
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

public void OnConfigsExecuted()
{
	// Once all plugin config files have been executed, set the correct convars in case another plugin changed them
	ToggleConVars();
}

public void OnConVarChanged(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
	// When one of the hooked convars is changed, make sure the correct convars are set
	ToggleConVars();
}

public void OnClientAuthorized(int client, const char[] auth)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		// Get the name of the client that was authorized
		char name[24];
		GetClientName(client, name, sizeof(name));

		// If the client is a bot and it is one of the special infected, remove them from the game
		// We check their auth because it is already provided and IsFakeClient() might not return correctly as they're not fully in the game
		if (StrEqual(auth, "BOT", false) && (StrContains(name, "boomer", false) >= 0 || StrContains(name, "charger", false) >= 0 || StrContains(name, "hunter", false) >= 0 || StrContains(name, "jockey", false) >= 0 || StrContains(name, "smoker", false) >= 0 || StrContains(name, "spitter", false) >= 0))
		{
			CreateTimer(0.1, KickInfected, client);
		}
	}
}

public Action KickInfected(Handle timer, any value)
{
	KickBots(value);
}

public void KickBots(int client)
{
	if (IsClientInGame(client) && !IsClientInKickQueue(client))
	{
		KickClient(client,"Kick");
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{	
	if( strcmp(classname, "infected") == 0 )
	{
		SDKHook(entity, SDKHook_SpawnPost, OnSpawnCommon);
	}
}

public void OnClientPostAdminCheck(int client)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// Get the auth string of the client
	char auth[24];
	GetClientAuthId(client, AuthId_Steam2, auth, sizeof(auth));

	// If the client is in the blacklist, continue
	if (StrContains(BLACKLIST, auth, false) >= 0)
	{
		// Remove the client from the game with a random error message
		int iError = GetRandomInt(1000000000, 9999999999);
		KickClient(client, "Unable to parse client's SteamID (%d)", iError);
		return;
	}

	// Hook PostThink for the client
	SDKHook(client, SDKHook_PostThink, OnPostThink);

	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		// If the client is in the game and they are not a bot, continue
		if (IsClientInGame(client) && !IsFakeClient(client))
		{
			// Print the welcome message
			PrintToChat(client, "%s Bienvenido al Mutant Tanks Arcade Mod! (v%s)", PREFIX, VERSION);

			// If hardcore mode is enabled, continue
			if (g_hHardcoreMode.BoolValue)
			{
				// Print message notifying them
				PrintToChat(client, "%s el modo HARDCORE esta activado!", PREFIX);
			}

			// If the gamemode is set to coop and the game has not started yet, continue
			if (StrEqual(g_sGameMode, "coop", false) && g_bCoopStart)
			{
				// Print message with how many seconds until start
				int iSeconds = g_hCoopStart.IntValue - g_iCoopStartTick;
				PrintToChat(client, "%s Los tanks comenzaran aparecer en %d segundos!", PREFIX, iSeconds);
			}
		}

		// If the client is in the game and they are the author of the plugin, continue
		if (IsClientInGame(client) && IsClientAuthor(client))
		{
			// Print message notifying everybody
			PrintToChatAll("%s Desarrollador de Tank Rush 2 ha unido!", PREFIX);
		}
	}
}

public void OnMapStart()
{
	// Reset global variables and check for update
	ResetGlobals();
}

public void OnMapEnd()
{
	// Reset global variables
	ResetGlobals();
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

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
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

public void OnSpawnCommon(int entity)
{	
	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{ 
        AcceptEntityInput(entity, "Kill");
	}
}

public void OnPostThink(int client)
{
	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
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
//																								COMMAND CALLBACKS
//============================================================================================================================================================================================================================================





public Action Command_God(int client, int args)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return Plugin_Handled;
	}

	// If the plugin is enabled and the client is the author of the plugin and alive, continue
	if (g_hEnable.BoolValue && IsClientAuthor(client) && IsPlayerAlive(client))
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

public Action Command_NoClip(int client, int args)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	// If the plugin is enabled and the client is the author of the plugin and alive, continue
	if (g_hEnable.BoolValue && IsClientAuthor(client) && IsPlayerAlive(client))
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

public Action Command_Despawn(int client, int args)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	// If the plugin is enabled and the client is the author of the plugin, alive, not a ghost, and infected, continue
	if (g_hEnable.BoolValue && IsClientAuthor(client) && IsPlayerAlive(client) && !IsPlayerGhost(client) && GetClientTeam(client) == 3)
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

public Action Command_Cheat(int client, int args)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	// If the plugin is enabled and the client is the author of the plugin, continue
	if (g_hEnable.BoolValue && IsClientAuthor(client))
	{
		// If there are arguments, continue
		if (GetCmdArgs() > 0)
		{
			// Get the first argument
			char arg1[256];
			GetCmdArg(1, arg1, sizeof(arg1));
			// Get the whole argument string
			char argstring[256];
			GetCmdArgString(argstring, sizeof(argstring));

			// Remove the cheat flag from the first argument
			int flags = GetCommandFlags(arg1);
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

public Action Command_Debug(int client, int args)
{
	// If the client is the server, stop
	if (client == 0)
	{
		return Plugin_Handled;
	}
	
	// If the plugin is enabled and the client is the author of the plugin, continue
	if (g_hEnable.BoolValue && IsClientAuthor(client))
	{
		// If debugging is disabled, continue
		if (!g_hDebug.BoolValue)
		{
			// Enable debugging
			g_hDebug.SetBool(true);
			PrintToChatAll("%s Debugging Habilitado", PREFIX);
		}

		else
		{
			// Disable debugging
			g_hDebug.SetBool(false);
			PrintToChatAll("%s Debugging deshabilitado", PREFIX);
		}

		return Plugin_Handled;
	}

	return Plugin_Handled;
}





//============================================================================================================================================================================================================================================
//																								TIMER CALLBACKS
//============================================================================================================================================================================================================================================





public Action Timer_Ticks(Handle timer)
{
	// Select a random human client that will handle tank spawning
	int client = GetRandomClient();

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
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
			if (g_iCoopStartTick >= g_hCoopStart.IntValue)
			{
				// Enable spawning, reset variables, notify clients
				g_bSpawning = true;
				g_bCoopStart = false;
				g_iCoopStartTick = 0;
				PrintToChatAll("%s Los Tanks comienzan aparecer...", PREFIX);
			}
		}

		// If spawning is enabled, continue
		if (g_bSpawning)
		{
			// Incrase spawn tick by one
			g_iSpawnTick++;

			// If the spawn ticks >= set spawn interval, tank limit hasn't been reached, all the infected are alive, or the first tank has not spawned yet, continue
			if ((g_iSpawnTick >= g_hSpawnInterval.IntValue && GetTankCount() < g_hTankLimit.IntValue) && AreInfectedAlive() || (!g_bFirstTank && g_hSpawnInterval.IntValue >= 20))
			{
				// Use a for loop to go through the clients
				for (int x = 1; x <= MaxClients; x++)
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

				if (g_bLeft4Dead2())
				{				
				    // Remove the cheat flag from z_spawn_old
				    int flags = GetCommandFlags("z_spawn_old");
				    SetCommandFlags("z_spawn_old", flags & ~FCVAR_CHEAT);
				    // Have the random client we chose earlier spawn the tank
				    FakeClientCommand(client, "z_spawn_old tank auto");
				    // Reapply the cheat flag to z_spawn_old
				    SetCommandFlags("z_spawn_old", flags|FCVAR_CHEAT);
				}
				else
				{				
				    // Remove the cheat flag from z_spawn
				    int flags = GetCommandFlags("z_spawn");
				    SetCommandFlags("z_spawn", flags & ~FCVAR_CHEAT);
				    // Have the random client we chose earlier spawn the tank
				    FakeClientCommand(client, "z_spawn tank auto");
				    // Reapply the cheat flag to z_spawn
				    SetCommandFlags("z_spawn", flags|FCVAR_CHEAT);
				}
				
				if (g_hDebug.BoolValue)
				{
					PrintToChatAll("%s aparecio un Tank bot (%d/%d).", DEBUG, GetTankCount(), g_hTankLimit.IntValue);
				}

				// Use a for loop to go through the clients
				for (int x = 1; x <= MaxClients; x++)
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
				if (g_hCountdown.IntValue > 59)
				{
					// Format the time by deriving the minutes and seconds from the raw time
					int iMinutes = g_hCountdown.IntValue / 60;
					int iSeconds = g_hCountdown.IntValue % 60;

					// If the raw time didn't divide evenly into minutes, continue
					if (iSeconds > 0)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los tanks tienen %d minutos %d segundos para matar a los sobrevivientes.", PREFIX, iMinutes, iSeconds);
					}

					// If the time comes to more than one minute, continue
					else if (iMinutes > 1)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los tanks tienen %d minutos para matar a los sobrevivientes.", PREFIX, iMinutes);
					}

					else
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los tanks tienen %d minutos para matar a los sobrevivientes.", PREFIX, iMinutes);
					}
				}

				else
				{
					// Print message to all clients notifying of the interval
					int iSeconds = g_hCountdown.IntValue;
					PrintToChatAll("%s Los tanks tienen %d segundos para matar a los sobrevivientes.", PREFIX, iSeconds);
				}
			}

			// Incrase countdown tick by one
			g_iCountdownTick++;

			// If the survivors haven't rested yet and the tick count >= countdown interval, continue
			if (!g_bRested && g_iCountdownTick >= g_hCountdown.IntValue)
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
				g_iCountdownHalf = g_hCountdown.IntValue / 2;

				// If half the countdown interval comes to less than 60 seconds, continue
				if (g_iCountdownHalf < 60)
				{
					// Set the countdown interval to 60 seconds
					// We do this so if the survivors make it past many rest periods, the countdown interval will never get to such a low amount that it gets stuck in a loop
					g_iCountdownHalf = 60;
				}

				// We'll format the time correctly here
				// If the cooldown interval > 59 seconds, continue
				if (g_hCooldown.IntValue > 59)
				{
					// Format the time by deriving the minutes and seconds from the raw time
					int iMinutes = g_hCooldown.IntValue / 60;
					int iSeconds = g_hCooldown.IntValue % 60;

					// If the raw time didn't divide evenly into minutes, continue
					if (iSeconds > 0)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los sobrevivientes tienen %d minutos %d segundos para descansar.", PREFIX, iMinutes, iSeconds);
					}

					// If the time comes to more than one minute, continue
					else if (iMinutes > 1)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los sobrevivientes tienen %d minutos para descansar.", PREFIX, iMinutes);
					}

					else
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los sobrevivientes tienen %d minutos para descansar.", PREFIX, iMinutes);
					}
				}

				else
				{
					// Print message to all clients notifying of the interval
					int iSeconds = g_hCooldown.IntValue;
					PrintToChatAll("%s Los sobrevivientes tienen %d segundos para descansar.", PREFIX, iSeconds);
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
				if (g_hCooldown.IntValue > 59)
				{
					// Format the time by deriving the minutes and seconds from the raw time
					int iMinutes = g_hCooldown.IntValue / 60;
					int iSeconds = g_hCooldown.IntValue % 60;

					// If the raw time didn't divide evenly into minutes, continue
					if (iSeconds > 0)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los sobrevivientes tienen %d minutos %d segundos para descansar.", PREFIX, iMinutes, iSeconds);
					}

					// If the time comes to more than one minute, continue
					else if (iMinutes > 1)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los sobrevivientes tienen %d minutos para descansar.", PREFIX, iMinutes);
					}

					else
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los sobrevivientes tienen %d minutos para descansar.", PREFIX, iMinutes);
					}
				}

				else
				{
					// Print message to all clients notifying of the interval
					int iSeconds = g_hCooldown.IntValue;
					PrintToChatAll("%s Los sobrevivientes tienen %d segundos para descansar.", PREFIX, iSeconds);
				}
			}
		}

		// If the finale cooldown has started, continue
		if (g_bCooldown)
		{
			// Increase the cooldown tick by one
			g_iCooldownTick++;

			// If the current cooldown tick >= set cooldown interval, continue
			if (g_iCooldownTick >= g_hCooldown.IntValue)
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
					int iMinutes = g_iCountdownHalf / 60;
					int iSeconds = g_iCountdownHalf % 60;

					// If the raw time didn't divide evenly into minutes, continue
					if (iSeconds > 0)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los tanks tienen %d minutos %d segundos para matar a los sobrevivientes.", PREFIX, iMinutes, iSeconds);
					}

					// If the time comes to more than one minute, continue
					else if (iMinutes > 1)
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los tanks tienen %d minutos para matar a los sobrevivientes.", PREFIX, iMinutes);
					}

					else
					{
						// Print message to all clients notifying of the interval
						PrintToChatAll("%s Los tanks tienen %d minutos para matar a los sobrevivientes.", PREFIX, iMinutes);
					}
				}

				else
				{
					// Print message to all clients notifying of the interval
					int iSeconds = g_iCountdownHalf;
					PrintToChatAll("%s Los tanks tienen %d segundos para matar a los sobrevivientes.", PREFIX, iSeconds);
				}
			}
		}

		// Use a for loop to go through the clients
		for (int x = 1; x <= MaxClients; x++)
		{
			// If the client is in the game, is not a bot, is a ghost, is infected, and is waiting to spawn in, continue
			if (IsClientInGame(x) && !IsFakeClient(x) && IsPlayerGhost(x) && GetClientTeam(x) == 3 && g_bWaiting[x])
			{
				// Increase the spawn waiting tick by one
				g_iWaitingTick[x]++;

				// Calculate number of seconds before client can spawn and display it
				int iSeconds = g_hSpawnInterval.IntValue - g_iWaitingTick[x];				
				PrintCenterText(client, "You will be able to spawn in %d seconds!", iSeconds);

				// If the client has reached the spawn delay, continue
				if (g_iWaitingTick[x] >= g_hSpawnInterval.IntValue)
				{
					if (g_hDebug.BoolValue)
					{
						PrintToChatAll("%s CLIENT %d ahora puede aparecer", DEBUG, x);
					}

					// Notify the client
					PrintCenterText(client, "ahora puede aparecer!");
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
				int iSeconds = 6 - g_iDespawningTick[x];
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
					if (g_hDebug.BoolValue)
					{
						PrintToChatAll("%s CLIENT %d ha desaparecido", DEBUG, x);
					}

					// Notify the client
					PrintCenterText(client, "has desaparecido!");
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

public Action Timer_Advert(Handle timer)
{
	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		// Send advertising message to all clients
		PrintToChatAll("%s Unete al grupo Mutant Tanks Arcade Mod!", PREFIX);
		PrintToChatAll("%s https://s.team/chat/SVzEdWFA2", PREFIX);
	}
}





//============================================================================================================================================================================================================================================
//																								EVENT CALLBACKS
//============================================================================================================================================================================================================================================





public Action Event_PlayerSpawn(Event event, char[] event_name, bool dontBroadcast)
{
	// Get the client from the event
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		// If player collision is disabled, continue
		if (!g_hCollision.BoolValue)
		{
			// Disable collision on the client
			int m_CollisionGroup = FindSendPropInfo("CBaseEntity", "m_CollisionGroup");
			SetEntData(client, m_CollisionGroup, 2, 4, true);
		}
	}
}

public Action Event_PlayerFirstSpawn(Event event, char[] event_name, bool dontBroadcast)
{
	// Get the client from the event
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		// If the client is in the game, is not a bot, and is infected, continue
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3)
		{
			if (g_hDebug.BoolValue)
			{
				PrintToChatAll("%s XPMod talent fix for CLIENT %d.", DEBUG, client);
			}

			RetankPlayer(client);
		}
	}
}

public Action Event_PlayerDeath(Event event, char[] event_name, bool dontBroadcast)
{
	// Get the client from the event
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		// If hardcore mode is enabled, the client is in the game, is not a bot, and is a survivor, continue
		if (g_hHardcoreMode.BoolValue && IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 2)
		{
			// Notify the client of why they died
			PrintHintText(client, "You only get one chance to survive on HARDCORE mode!");
		}

		// If the givehealth convar is set to 1, the client is in the game, is a tank, and spawning is enabled, continue
		if (g_hGiveHealth.IntValue == 1 && IsClientInGame(client) && IsPlayerTank(client) && g_bSpawning)
		{
			if (g_hDebug.BoolValue)
			{
				PrintToChatAll("%s Dandole la salud a TODOS LOS SUPERVIVIENTES.", DEBUG);
			}

			// Use a for loop to go through the clients
			for (int x = 1; x <= MaxClients; x++)
			{
				// If the client is in the game and is a survivor, continue
				if (IsClientInGame(x) && GetClientTeam(x) == 2)
				{
					// Remove the cheat flag from the give command
					int flags = GetCommandFlags("give");
					SetCommandFlags("give", flags & ~FCVAR_CHEAT);
					// Allow the client to heal themselves to full health
					FakeClientCommand(x, "give health");
					// Reapply the cheat flag to the give command
					SetCommandFlags("give", flags|FCVAR_CHEAT);

					// If the client was black-and-white previously, continue
					if (g_bBlackAndWhite[x])
					{ 
						if (g_hDebug.BoolValue)
						{
							PrintToChatAll("%s Regresando al JUGADOR %d a estado blanco y negro.", DEBUG, x);
						}

						// Return the client to black-and-white state
						BlackAndWhite(x);
					}
				}
			}
		}

		// If the givehealth convar is set to 2, the client is in the game, is a tank, and spawning is enabled, continue
		if (g_hGiveHealth.IntValue == 2 && IsClientInGame(client) && IsPlayerTank(client) && g_bSpawning)
		{
			// Set up integers for comparing health
			int iTotalHealthNew;
			int iTotalHealthOld;
			int iMaxHealthNew;
			int iMaxHealthOld;
			int iIncapHealthNew;
			int iIncapHealthOld;
			int iTotalHealthClient;
			int iIncapClient;

			// Use a for loop to go through the clients
			for (int x = 1; x <= MaxClients; x++)
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
				if (g_hDebug.BoolValue)
				{
					PrintToChatAll("%s Dando salud al JUGADOR %d.", DEBUG, iIncapClient);
				}

				// Remove the cheat flag from the give command
				int flags = GetCommandFlags("give");
				SetCommandFlags("give", flags & ~FCVAR_CHEAT);
				// Allow the client to heal themselves to full health
				FakeClientCommand(iIncapClient, "give health");
				// Reapply the cheat flag to the give command
				SetCommandFlags("give", flags|FCVAR_CHEAT);

				// If the client was previously black-and-white, continue
				if (g_bBlackAndWhite[iIncapClient])
				{
					if (g_hDebug.BoolValue)
					{
						PrintToChatAll("%s Regresando al JUGADOR %d a estado blanco y negro.", DEBUG, iIncapClient);
					}

					// Return the client to black-and-white state
					BlackAndWhite(iIncapClient);
				}
			}

			// If a low-health client was set, continue
			else if (iTotalHealthClient > 0)
			{
				if (g_hDebug.BoolValue)
				{
					PrintToChatAll("%s Dando salud al jugador %d.", DEBUG, iTotalHealthClient);
				}

				// Remove the cheat flag from the give command
				int flags = GetCommandFlags("give");
				SetCommandFlags("give", flags & ~FCVAR_CHEAT);
				// Allow the client to heal themselves to full health
				FakeClientCommand(iTotalHealthClient, "give health");
				// Reapply the cheat flag to the give command
				SetCommandFlags("give", flags|FCVAR_CHEAT);

				// If the client was previously black-and-white, continue
				if (g_bBlackAndWhite[iTotalHealthClient])
				{
					if (g_hDebug.BoolValue)
					{
						PrintToChatAll("%s Regresando al JUGADOR %d a estado blanco y negro.", DEBUG, iTotalHealthClient);
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
				for (int x = 1; x <= MaxClients; x++)
				{
					// If the client is in the game and is a survivor, continue
					if (IsClientInGame(x) && GetClientTeam(x) == 2)
					{
						// Remove the cheat flag from the give command
						int flags = GetCommandFlags("give");
						SetCommandFlags("give", flags & ~FCVAR_CHEAT);
						// Allow the client to heal themselves to full health
						FakeClientCommand(x, "give health");
						// Reapply the cheat flag to the give command
						SetCommandFlags("give", flags|FCVAR_CHEAT);

						// If the client was black-and-white previously, continue
						if (g_bBlackAndWhite[x])
						{ 
							if (g_hDebug.BoolValue)
							{
								PrintToChatAll("%s Regresando al JUGADOR %d a estado blanco y negro.", DEBUG, x);
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

public Action Event_PlayerIncap(Event event, char[] event_name, bool dontBroadcast)
{
	// Get the client from the event
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		// If incap limits are set, the client is in the game, and the client is a survivor, continue
		if (g_hIncapLimit.IntValue > 0 && IsClientInGame(client) && GetClientTeam(client) == 2)
		{
			// Increase the client's incap count by one
			g_iIncapCount[client]++;
		}

		// If the client's incap limit >= the set incap limit, continue
		if (g_iIncapCount[client] >= g_hIncapLimit.IntValue)
		{
			if (g_hDebug.BoolValue)
			{
				PrintToChatAll("%s Limite de incapacidad para el JUGADOR %d alcanzado.", DEBUG, client);
			}

			// Set this bool so when the client is revived they will be returned to black-and-white state
			g_bBlackAndWhite[client] = true;
		}
	}
}


public Action Event_ReviveSuccess(Event event, char[] event_name, bool dontBroadcast)
{
	// Get the client from the event
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{

		// If the client was previously black-and-white and is in the game, continue
		if (g_bBlackAndWhite[client] && IsClientInGame(client))
		{
			if (g_hDebug.BoolValue)
			{
				PrintToChatAll("%s Regresando al JUGADOR %d a estado blanco y negro.", DEBUG, client);
			}

			// Return the client to black-and-white state
			BlackAndWhite(client);
		}
	}
}

public Action Event_RoundStart(Event event, char[] event_name, bool dontBroadcast)
{
	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		// Reset global variables for a new round
		ResetGlobals();

		// Use a for loop to go through the clients
		for (int x = 1; x <= MaxClients; x++)
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

public Action Event_LeftStartArea(Event event, char[] event_name, bool dontBroadcast)
{
	// If the plugin is enabled and the game mode is not set to coop, continue
	if (g_hEnable.BoolValue && !StrEqual(g_sGameMode, "coop", false))
	{
		// Notify players that tanks will begin spawning
		g_bSpawning = true;
		PrintToChatAll("%s Los tanks comienzan aparecer...", PREFIX);
	}
}

public Action Event_RoundEnd(Event event, char[] event_name, bool dontBroadcast)
{
	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{

		// Reset global variables for a new round
		ResetGlobals();
		// Remove all bot tanks from the game
		KickInfectedBots();

		// Use a for loop to go through the clients
		for (int x = 1; x <= MaxClients; x++)
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

public Action Event_FinaleStart(Event event, char[] event_name, bool dontBroadcast)
{
	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		//  Set the finale bool to true
		g_bCountdown = true;
	}
}

public Action Event_ItemPickup(Event event, char[] event_name, bool dontBroadcast)
{
	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		// Grab the client's client number
		int client = GetClientOfUserId(GetEventInt(event, "userid"));
		// Grab the name of the item the client picked up
		char item[24];
		event.GetString("item", item, sizeof(item));

		// If the client is in the game, is not a bot, and is infected, continue
		if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3)
		{
			// If the client spawned as a special infected, continue
			if (StrEqual(item, "boomer_claw") || StrEqual(item, "charger_claw") || StrEqual(item, "hunter_claw") || StrEqual(item, "jockey_claw") || StrEqual(item, "smoker_claw") || StrEqual(item, "spitter_claw"))
			{
				if (g_hDebug.BoolValue)
				{
					PrintToChatAll("%s Efectuando una transicion %d al tank y fantasma.", DEBUG, client);
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

public Action Event_HealSuccess(Event event, char[] event_name, bool dontBroadcast)
{
	// Grab the client's client number
	int client = GetClientOfUserId(GetEventInt(event, "subject"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, continue
	if (g_hEnable.BoolValue)
	{
		// If the client was previous black-and-white and is in the game, continue
		if (g_bBlackAndWhite[client] && IsClientInGame(client))
		{
			if (g_hDebug.BoolValue)
			{
				PrintToChatAll("%s Regresando al JUGADOR %d a estado blanco y negro.", DEBUG, client);
			}

			// Return the client to black-and-white state
			BlackAndWhite(client);
		}
	}
}

public Action Event_EnterGhostMode(Event event, char[] event_name, bool dontBroadcast)
{
	// Grab the client's client number
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	// If the client is the server, stop
	if (client == 0)
	{
		return;
	}

	// If the plugin is enabled, the client is dead, and the client isn't a ghost, continue
	if (g_hEnable.BoolValue && !IsPlayerAlive(client) && !IsPlayerGhost(client))
	{
		if (g_hDebug.BoolValue)
		{
			PrintToChatAll("%s Reaparecer JUGADOR %d.", DEBUG, client);
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





void ToggleConVars()
{
	// Use a switch to get the status of the plugin
	switch(g_hEnable.BoolValue)
	{
		// If the plugin is disabled, do this
		case 0:
		{
			// Reset change convars to their default value
			ResetConVar(g_hDirectorNoBosses);
			ResetConVar(g_hDirectorNoSpecials);
			ResetConVar(g_hDirectorNoMobs);
			ResetConVar(g_hZFrustration);
			ResetConVar(g_hZTankHealth);
			ResetConVar(g_hZTankSpeed);
			ResetConVar(g_hZTankSpeedVs);
			ResetConVar(g_hZTankWalkSpeed);
			ResetConVar(g_hZCrouchSpeed);
			if (g_bLeft4Dead2()) ResetConVar(g_hZBoomerLimit);
			if (g_bLeft4Dead2()) ResetConVar(g_hZChargerLimit);
			ResetConVar(g_hZHunterLimit);
			if (g_bLeft4Dead2()) ResetConVar(g_hZJockeyLimit);
			if (g_bLeft4Dead2()) ResetConVar(g_hZSmokerLimit);
			if (g_bLeft4Dead2()) ResetConVar(g_hZSpitterLimit);
			ResetConVar(g_hSurvivorMaxIncapCount);
			ResetConVar(g_hZGhostSpeed);
			ResetConVar(g_hZGhostTravelDistance);
		}

		// If the plugin is enabled, do this
		case 1:
		{
			// Grab the current gamemode
			g_hGameMode.GetString(g_sGameMode, sizeof(g_sGameMode));

			// Disable bosses, mobs, and tank frustration
			g_hDirectorNoBosses.SetInt(1);
			g_hDirectorNoSpecials.SetInt(1);
			g_hDirectorNoMobs.SetInt(1);
			g_hZFrustration.SetInt(0);
			
			// Reset these convars to their default values as they are adjusted by ratio and not direct value
			ResetConVar(g_hZTankSpeed);
			ResetConVar(g_hZTankSpeedVs);
			ResetConVar(g_hZTankWalkSpeed);
			ResetConVar(g_hZCrouchSpeed);
			// Grab the ratio that the convars will be adjusted for
			float fTankSpeed = g_hTankSpeed.FloatValue;
			float fZTankSpeed = g_hZTankSpeed.FloatValue;
			float fZTankSpeedVs = g_hZTankSpeedVs.FloatValue;
			float fZTankWalkSpeed = g_hZTankWalkSpeed.FloatValue;
			float fZCrouchSpeed = g_hZCrouchSpeed.FloatValue;
			// Calculate the new values for the convars
			fZTankSpeed = fTankSpeed * fZTankSpeed;
			fZTankSpeedVs = fTankSpeed * fZTankSpeedVs;
			fZTankWalkSpeed = fTankSpeed * fZTankWalkSpeed;
			fZCrouchSpeed = fTankSpeed * fZCrouchSpeed;
			// Round the floats up to integers
			int iZTankSpeed = RoundToCeil(fZTankSpeed);
			int iZTankSpeedVs = RoundToCeil(fZTankSpeedVs);
			int iZTankWalkSpeed = RoundToCeil(fZTankWalkSpeed);
			int iZCrouchSpeed = RoundToCeil(fZCrouchSpeed);
			// Apply the new values to the convars
			g_hZTankSpeed.SetInt(iZTankSpeed);
			g_hZTankSpeedVs.SetInt(iZTankSpeedVs);
			g_hZTankWalkSpeed.SetInt(iZTankWalkSpeed);
			g_hZCrouchSpeed.SetInt(iZCrouchSpeed);
			
			// Set the infected limits (for some reason this doesn't work on certain portions of maps)
			if (g_bLeft4Dead2()) g_hZBoomerLimit.SetInt(0);
			if (g_bLeft4Dead2()) g_hZChargerLimit.SetInt(0);
			g_hZHunterLimit.SetInt(0);
			if (g_bLeft4Dead2()) g_hZJockeyLimit.SetInt(0);
			if (g_bLeft4Dead2()) g_hZSmokerLimit.SetInt(0);
			if (g_bLeft4Dead2()) g_hZSpitterLimit.SetInt(0);
			
			// Increase the ghost movement speed
			g_hZGhostSpeed.SetInt(850);
			// Remove the linear distance requirement for spawning
			g_hZGhostTravelDistance.SetInt(0);
			
			// If the plugin tank health convar is different from the game convar, continue
			if (g_hZTankHealth.IntValue != g_hTankHealth.IntValue)
			{
				// Update the convar
				g_hZTankHealth.SetInt(g_hTankHealth.IntValue);
			}

			// Use a switch to get the status of hardcore mode
			switch(g_hHardcoreMode.BoolValue)
			{
				// If hardcore mode is disabled, do this
				case 0:
				{
					// Update the incap limit
					g_hSurvivorMaxIncapCount.SetInt(g_hIncapLimit.IntValue);
				}

				// If hardcore mode is enabled, do this
				case 1:
				{
					// Remove incap limits altogether (permanently black-and-whtie)
					g_hSurvivorMaxIncapCount.SetInt(0);
				}
			}
		}
	}
}

void ResetGlobals()
{
	// Use a for loop to go through the clients
	for (int x = 1; x <= MaxClients; x++)
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

int GetRandomClient()
{
	// Use a for loop to go through the clients
	for (int x = 1; x <= MaxClients; x++ )
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

void KickInfectedBots()
{
	// Use a for loop to go through the clients
	for (int x = 1; x <= MaxClients; x++)
	{
		// If the client is in the game, is a bot, and is infected, continue
		if (IsClientInGame(x) && IsFakeClient(x) && GetClientTeam(x) == 3)
		{
			// Remove the client from the game
			KickClient(x);
		}
	}

}

void PlayersToGhost()
{
	// Use a for loop to go through the clients
	for (int x = 1; x <= MaxClients; x++)
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

void PlayersToRandom()
{
	// Use a for loop to go through the clients
	for (int x = 1; x <= MaxClients; x++)
	{
		// If the client is in the game, is not a bot, and is infected, continue
		if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3)
		{
			// If the player is alive, continue
			if (IsPlayerAlive(x))
			{
				// Select a random special infected class and change them to it
				int i = GetRandomInt(1, 6);
				SDKCall(g_hSetClass, x, i);
			}
		}
	}
}

void PlayersToTank()
{
	// Use a for loop to go through the clients
	for (int x = 1; x <= MaxClients; x++)
	{
		// If the client is in the game, is not a bot, and is infected, continue
		if (IsClientInGame(x) && !IsFakeClient(x) && GetClientTeam(x) == 3)
		{
			// If the player is alive, continue
			if (IsPlayerAlive(x))
			{
				// Change the client to a tank
				SDKCall(g_hSetClass, x, (g_bLeft4Dead2() ? 8 : 5 ));
			}
		}
	}
}

void RespawnInfectedPlayers()
{
	// Use a for loop to go through the clients
	for (int x = 1; x <= MaxClients; x++)
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

void PlayerToGhost(int client)
{
	// Remove the cheat flag from the give command
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	// Allow the client to heal themselves to full health
	FakeClientCommand(client, "give health");
	// Reapply the cheat flag to the give command
	SetCommandFlags("give", flags|FCVAR_CHEAT);

	int m_vecVelocity0 = FindSendPropInfo("CTerrorPlayer", "m_vecVelocity[0]");

	float AbsOrigin[3];
	float EyeAngles[3];
	float Velocity[3];

	GetClientAbsOrigin(client, AbsOrigin);
	GetClientEyeAngles(client, EyeAngles);

	Velocity[0] = GetEntDataFloat(client, m_vecVelocity0);
	Velocity[1] = GetEntDataFloat(client, m_vecVelocity0 + 4);
	Velocity[2] = GetEntDataFloat(client, m_vecVelocity0 + 8);

	int m_isCulling = FindSendPropInfo("CTerrorPlayer", "m_isCulling");
	SetEntData(client, m_isCulling, 1, 1);
	// Return the client to ghost state
	SDKCall(g_hZombieAbortControl, client, 0.0);
	
	// Teleport entity to their previous position (client will be stuck in the ground otherwise)
	TeleportEntity(client, AbsOrigin, EyeAngles, Velocity);
}

void PlayerToRandom(int client)
{
	// If the client is in the game, is not a bot, and is infected, continue
	if (IsClientInGame(client) && !IsFakeClient(client) && GetClientTeam(client) == 3)
	{
		// If the player is alive, continue
		if (IsPlayerAlive(client))
		{
			// Select a random special infected class and change them to it
			int i = GetRandomInt(1, 6);
			SDKCall(g_hSetClass, client, i);
		}
	}
}

void PlayerToTank(int client)
{
	// Grab the name of their weapon (charger_claw, hunter_claw, etc.)
	int WeaponIndex = GetPlayerWeaponSlot(client, 0);
	// Remove it from them
	RemovePlayerItem(client, WeaponIndex);

	// Change client to a tank
	SDKCall(g_hSetClass, client, (g_bLeft4Dead2() ? 8 : 5 ));
	// Give the client the appropriate weapon (tank_claw)
	SetEntProp(client, Prop_Send, "m_customAbility", GetEntData(SDKCall(g_hCreateAbility, client), g_iAbility));
}

void RespawnPlayer(int client)
{
	SDKCall(g_hStateTransition, client, 8);
	SDKCall(g_hBecomeGhost, client, 1);
	SDKCall(g_hStateTransition, client, 6);
	SDKCall(g_hBecomeGhost, client, 1);
}

void RespawnGhost(int client)
{
	SDKCall(g_hStateTransition, client, 6);
	SDKCall(g_hBecomeGhost, client, 1);
}

void RetankPlayer(int client)
{
	int m_vecVelocity0 = FindSendPropInfo("CTerrorPlayer", "m_vecVelocity[0]");

	float AbsOrigin[3];
	float EyeAngles[3];
	float Velocity[3];

	GetClientAbsOrigin(client, AbsOrigin);
	GetClientEyeAngles(client, EyeAngles);

	Velocity[0] = GetEntDataFloat(client, m_vecVelocity0);
	Velocity[1] = GetEntDataFloat(client, m_vecVelocity0 + 4);
	Velocity[2] = GetEntDataFloat(client, m_vecVelocity0 + 8);

	int m_isCulling = FindSendPropInfo("CTerrorPlayer", "m_isCulling");
	SetEntData(client, m_isCulling, 1, 1);
	SDKCall(g_hStateTransition, client, 6);
	SDKCall(g_hBecomeGhost, client, 1);
	
	TeleportEntity(client, AbsOrigin, EyeAngles, Velocity);
}

void BlackAndWhite(int client)
{
	// Change the following netprops so the game thinks the client is black-and-white
	SetEntProp(client, Prop_Send, "m_currentReviveCount", FindConVar("survivor_max_incapacitated_count").IntValue);
	SetEntProp(client, Prop_Send, "m_isGoingToDie", 1);
	if (g_bLeft4Dead2()) SetEntProp(client, Prop_Send, "m_bIsOnThirdStrike", 1);
	// Apply the black-and-white effects to the client's screen
	SDKCall(g_hOnRevived, client);
}

int GetTankCount()
{
	int iTankCount;

	// Use a for loop to go through the clients
	for (int x = 1; x <= MaxClients; x++)
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

int GetClientMaxHealth(int client)
{
	// If the client doesn't exist, is not a valid entity, is not in game, is not alive, or is an observer, continue
	if (!client || !IsValidEntity(client) || !IsClientInGame(client) || !IsPlayerAlive(client) || IsClientObserver(client))
	{
		// Return -1 as their health
		return -1;
	}

	// Grab their max health from the netprop
	int MaxHealth = GetEntProp(client, Prop_Send, "m_iMaxHealth");
	// Return their max health
	return MaxHealth;
}

int GetClientTotalHealth(int client)
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
	float buffer = GetEntPropFloat(client, Prop_Send, "m_healthBuffer");
	// Grab the client's static health
	int StaticHealth = GetClientHealth(client);
	float TempHealth;

	// If there is no buffer, continue
	if (buffer <= 0.0)
	{
		// Grab the client's temporary health as 0
		TempHealth = 0.0;
	}

	else
	{
		// Calculate how long it's been since the player recieved that buffer
		float difference = GetGameTime() - GetEntPropFloat(client, Prop_Send, "m_healthBufferTime");
		// Grab the decay rate of temporary health
		float decay = FindConVar("pain_pills_decay_rate").FloatValue;
		float constant = 1.0/decay;
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

bool AreInfectedAlive()
{
	int iDeadCount;

	// Use a for loop to go through the clients
	for (int x = 1; x <= MaxClients; x++)
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

bool IsPlayerIncapped(int client)
{
	// Return the incap status from the netpop
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isIncapacitated"));
}

bool IsPlayerGhost(int client)
{
	// Return the ghost status from the netprop
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}

bool IsPlayerTank(int client)
{
	if (GetEntProp(client, Prop_Send, "m_zombieClass") == (g_bLeft4Dead2() ? 8 : 5 ))
	{
		return true;
	}

	else
	{
		return false;
	}

}

bool IsClientAuthor(int client)
{
	// Grab the client's steamID
	char sAuth[24];
	GetClientAuthId(client, AuthId_Steam2, sAuth, sizeof(sAuth));

	// If it matches the author's steamID, continue
	if (StrEqual(sAuth, "STEAM_1:0:39841182"))
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

bool g_bLeft4Dead2()
{
	EngineVersion engine = GetEngineVersion();
	return ( engine == Engine_Left4Dead2 );
}