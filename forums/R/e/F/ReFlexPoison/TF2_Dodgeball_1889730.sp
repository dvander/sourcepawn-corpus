// *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1				  // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <colors>

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// ---- Plugin-related constants ---------------------------------------------------
#define PLUGIN_NAME				"[TF2] Dodgeball"
#define PLUGIN_AUTHOR			"Damizean"
#define PLUGIN_VERSION			"1.1"
#define PLUGIN_CONTACT			"elgigantedeyeso@gmail.com"
#define CVAR_FLAGS				FCVAR_PLUGIN

// ---- General settings -----------------------------------------------------------
#define FPS_LOGIC_RATE			20.0
#define FPS_LOGIC_INTERVAL		1.0 / FPS_LOGIC_RATE

// ---- Maximum structure sizes ----------------------------------------------------
#define MAX_ROCKETS				100
#define MAX_ROCKET_CLASSES		50
#define MAX_SPAWNER_CLASSES		50
#define MAX_SPAWN_POINTS		100

// ---- Flags and types constants --------------------------------------------------
enum Musics
{
	Music_RoundStart,
	Music_RoundWin,
	Music_RoundLose,
	Music_Gameplay,
	SizeOfMusicsArray
};

enum BehaviourTypes
{
	Behaviour_Unknown,
	Behaviour_Homing
};

enum RocketFlags
{
	RocketFlag_None				= 0,
	RocketFlag_PlaySpawnSound	= 1 << 0,
	RocketFlag_PlayBeepSound	= 1 << 1,
	RocketFlag_PlayAlertSound	= 1 << 2,
	RocketFlag_ElevateOnDeflect	= 1 << 3,
	RocketFlag_IsNeutral		= 1 << 4,
	RocketFlag_Exploded			= 1 << 5,
	RocketFlag_OnSpawnCmd		= 1 << 6,
	RocketFlag_OnDeflectCmd		= 1 << 7,
	RocketFlag_OnKillCmd		= 1 << 8,
	RocketFlag_OnExplodeCmd		= 1 << 9,
	RocketFlag_CustomModel		= 1 << 10,
	RocketFlag_CustomSpawnSound	= 1 << 11,
	RocketFlag_CustomBeepSound	= 1 << 12,
	RocketFlag_CustomAlertSound	= 1 << 13,
	RocketFlag_Elevating		= 1 << 14,
	RocketFlag_IsAnimated		= 1 << 15
};

enum RocketSound
{
	RocketSound_Spawn,
	RocketSound_Beep,
	RocketSound_Alert
};

enum SpawnerFlags
{
	SpawnerFlag_Team_Red		= 1,
	SpawnerFlag_Team_Blu		= 2,
	SpawnerFlag_Team_Both		= 3
};

#define TestFlags(%1,%2)	(!!((%1) & (%2)))
#define TestFlagsAnd(%1,%2) (((%1) & (%2)) == %2)

// ---- Other resources ------------------------------------------------------------
#define SOUND_DEFAULT_SPAWN				"weapons/sentry_rocket.wav"
#define SOUND_DEFAULT_BEEP				"weapons/sentry_scan.wav"
#define SOUND_DEFAULT_ALERT				"weapons/sentry_spot.wav"
#define SNDCHAN_MUSIC					32
#define PARTICLE_NUKE_1					"fireSmokeExplosion"
#define PARTICLE_NUKE_2					"fireSmokeExplosion1"
#define PARTICLE_NUKE_3					"fireSmokeExplosion2"
#define PARTICLE_NUKE_4					"fireSmokeExplosion3"
#define PARTICLE_NUKE_5					"fireSmokeExplosion4"
#define PARTICLE_NUKE_COLLUMN			"fireSmoke_collumnP"
#define PARTICLE_NUKE_1_ANGLES			Float:{270.0, 0.0, 0.0}
#define PARTICLE_NUKE_2_ANGLES			PARTICLE_NUKE_1_ANGLES
#define PARTICLE_NUKE_3_ANGLES			PARTICLE_NUKE_1_ANGLES
#define PARTICLE_NUKE_4_ANGLES			PARTICLE_NUKE_1_ANGLES
#define PARTICLE_NUKE_5_ANGLES			PARTICLE_NUKE_1_ANGLES
#define PARTICLE_NUKE_COLLUMN_ANGLES	PARTICLE_NUKE_1_ANGLES

// Debug
//#define DEBUG

// *********************************************************************************
// VARIABLES
// *********************************************************************************

// -----<<< Cvars >>>-----
new Handle:g_hCvarEnabled;
new Handle:g_hCvarEnableCfgFile;
new Handle:g_hCvarDisableCfgFile;
new Handle:g_hCvarSpeedo;
new Handle:g_hCvarAnnounce;

// -----<<< Gameplay >>>-----
new bool:g_bEnabled;			// Is the plugin enabled?
new bool:g_bRoundStarted;		// Has the round started?
new g_iRoundCount;				// Current round count since map start
new g_iRocketsFired;			// No. of rockets fired since round start
new Handle:g_hLogicTimer;		// Logic timer
new Float:g_fNextSpawnTime;		// Time at wich the next rocket will be able to spawn
new g_iLastDeadTeam;			// The team of the last dead client. If none, it's a random team.
new g_iLastDeadClient;			// The last dead client. If none, it's a random client.
new g_iPlayerCount;
new Handle:g_hHud;
new g_iRocketSpeed;
new Handle:g_hTimerHud;

// -----<<< Configuration >>>-----
new bool:g_bMusicEnabled;
new bool:g_bMusic[_:SizeOfMusicsArray];
new String:g_strMusic[_:SizeOfMusicsArray][PLATFORM_MAX_PATH];
new bool:g_bUseWebPlayer;
new String:g_strWebPlayerUrl[256];

// -----<<< Structures >>>-----
// Rockets
new bool:g_bRocketIsValid				[MAX_ROCKETS];
new g_iRocketEntity						[MAX_ROCKETS];
new g_iRocketTarget						[MAX_ROCKETS];
new g_iRocketSpawner					[MAX_ROCKETS];
new g_iRocketClass						[MAX_ROCKETS];
new RocketFlags:g_iRocketFlags			[MAX_ROCKETS];
new Float:g_fRocketSpeed				[MAX_ROCKETS];
new Float:g_fRocketDirection			[MAX_ROCKETS][3];
new g_iRocketDeflections				[MAX_ROCKETS];
new Float:g_fRocketLastDeflectionTime	[MAX_ROCKETS];
new Float:g_fRocketLastBeepTime			[MAX_ROCKETS];
new g_iLastCreatedRocket;
new g_iRocketCount;

// Classes
new String:g_strRocketClassName				[MAX_ROCKET_CLASSES][16];
new String:g_strRocketClassLongName			[MAX_ROCKET_CLASSES][32];
new BehaviourTypes:g_iRocketClassBehaviour	[MAX_ROCKET_CLASSES];
new String:g_strRocketClassModel			[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
new RocketFlags:g_iRocketClassFlags			[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassBeepInterval		[MAX_ROCKET_CLASSES];
new String:g_strRocketClassSpawnSound		[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
new String:g_strRocketClassBeepSound		[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
new String:g_strRocketClassAlertSound		[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
new Float:g_fRocketClassCritChance			[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassDamage				[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassDamageIncrement		[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassSpeed				[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassSpeedIncrement		[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassTurnRate			[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassTurnRateIncrement	[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassElevationRate		[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassElevationLimit		[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassRocketsModifier		[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassPlayerModifier		[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassControlDelay		[MAX_ROCKET_CLASSES];
new Float:g_fRocketClassTargetWeight		[MAX_ROCKET_CLASSES];
new Handle:g_hRocketClassCmdsOnSpawn		[MAX_ROCKET_CLASSES];
new Handle:g_hRocketClassCmdsOnDeflect		[MAX_ROCKET_CLASSES];
new Handle:g_hRocketClassCmdsOnKill			[MAX_ROCKET_CLASSES];
new Handle:g_hRocketClassCmdsOnExplode		[MAX_ROCKET_CLASSES];
new Handle:g_hRocketClassTrie;
new g_iRocketClassCount;

// Spawner classes
new String:g_strSpawnersName		[MAX_SPAWNER_CLASSES][32];
new g_iSpawnersMaxRockets			[MAX_SPAWNER_CLASSES];
new Float:g_fSpawnersInterval		[MAX_SPAWNER_CLASSES];
new Handle:g_hSpawnersChancesTable	[MAX_SPAWNER_CLASSES];
new Handle:g_hSpawnersTrie;
new g_iSpawnersCount;

// Array containing the spawn points for the Red team, and
// their associated spawner class.
new g_iCurrentRedSpawn;
new g_iSpawnPointsRedCount;
new g_iSpawnPointsRedClass  [MAX_SPAWN_POINTS];
new g_iSpawnPointsRedEntity [MAX_SPAWN_POINTS];

// Array containing the spawn points for the Blu team, and
// their associated spawner class.
new g_iCurrentBluSpawn;
new g_iSpawnPointsBluCount;
new g_iSpawnPointsBluClass  [MAX_SPAWN_POINTS];
new g_iSpawnPointsBluEntity [MAX_SPAWN_POINTS];

// The default spawner class.
new g_iDefaultRedSpawner;
new g_iDefaultBluSpawner;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin:myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_NAME,
	version = PLUGIN_VERSION,
	url = PLUGIN_CONTACT
};

// *********************************************************************************
// METHODS
// *********************************************************************************

/* OnPluginStart()
**
** When the plugin is loaded.
** -------------------------------------------------------------------------- */
public OnPluginStart()
{
	decl String:strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (!StrEqual(strModName, "tf")) SetFailState("This plugin is only for Team Fortress 2.");

	CreateConVar("tf_dodgeball_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN);
	g_hCvarEnabled = CreateConVar("tf_dodgeball_enabled", "1", "Enable Dodgeball on TFDB maps?", _, true, 0.0, true, 1.0);
	g_hCvarEnableCfgFile = CreateConVar("tf_dodgeball_enablecfg", "sourcemod/dodgeball_enable.cfg", "Config file to execute when enabling the Dodgeball game mode.");
	g_hCvarDisableCfgFile = CreateConVar("tf_dodgeball_disablecfg", "sourcemod/dodgeball_disable.cfg", "Config file to execute when disabling the Dodgeball game mode.");
	g_hCvarSpeedo = CreateConVar("tf_dodgeball_speedo", "1", "Enable HUD speedometer");
	g_hCvarAnnounce = CreateConVar("tf_dodgeball_announce", "1", "Enable kill announces in chat");

	g_hRocketClassTrie = CreateTrie();
	g_hSpawnersTrie = CreateTrie();

	g_hHud = CreateHudSynchronizer();

	RegisterCommands();
}

/* OnConfigsExecuted()
**
** When all the configuration files have been executed, try to enable the
** Dodgeball.
** -------------------------------------------------------------------------- */
public OnConfigsExecuted()
{
	if (GetConVarBool(g_hCvarEnabled) && IsDodgeBallMap())
	{
		EnableDodgeBall();
	}
}

/* OnMapEnd()
**
** When the map ends, disable DodgeBall.
** -------------------------------------------------------------------------- */
public OnMapEnd()
{
	DisableDodgeBall();
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**	 __  ___												  __
**	/  |/  /___ _____  ____ _____ ____  ____ ___  ___  ____  / /_
**   / /|_/ / __ `/ __ \/ __ `/ __ `/ _ \/ __ `__ \/ _ \/ __ \/ __/
**  / /  / / /_/ / / / / /_/ / /_/ /  __/ / / / / /  __/ / / / /_
** /_/  /_/\__,_/_/ /_/\__,_/\__, /\___/_/ /_/ /_/\___/_/ /_/\__/
**						  /____/
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

//   ___					   _
//  / __|___ _ _  ___ _ _ __ _| |
// | (_ / -_) ' \/ -_) '_/ _` | |
//  \___\___|_||_\___|_| \__,_|_|

/* IsDodgeBallMap()
**
** Checks if the current map is a dodgeball map.
** -------------------------------------------------------------------------- */
bool:IsDodgeBallMap()
{
	decl String:strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	return StrContains(strMap, "tfdb_", false) == 0;
}

/* EnableDodgeBall()
**
** Enables and hooks all the required events.
** -------------------------------------------------------------------------- */
EnableDodgeBall()
{
	if (g_bEnabled == false)
	{
		// Parse configuration files
		decl String:strMapName[64]; GetCurrentMap(strMapName, sizeof(strMapName));
		decl String:strMapFile[PLATFORM_MAX_PATH]; Format(strMapFile, sizeof(strMapFile), "%s.cfg", strMapName);
		ParseConfigurations();
		ParseConfigurations(strMapFile);

		// Check if we have all the required information
		if (g_iRocketClassCount == 0)   SetFailState("No rocket class defined.");
		if (g_iSpawnersCount == 0)	  SetFailState("No spawner class defined.");
		if (g_iDefaultRedSpawner == -1) SetFailState("No spawner class definition for the Red spawners exists in the config file.");
		if (g_iDefaultBluSpawner == -1) SetFailState("No spawner class definition for the Blu spawners exists in the config file.");

		// Hook events and info_target outputs.
		HookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
		HookEvent("teamplay_setup_finished", OnSetupFinished, EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
		HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
		HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
		HookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
		HookEvent("teamplay_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre);

		// Precache sounds
		PrecacheSound(SOUND_DEFAULT_SPAWN, true);
		PrecacheSound(SOUND_DEFAULT_BEEP, true);
		PrecacheSound(SOUND_DEFAULT_ALERT, true);
		if (g_bMusicEnabled == true)
		{
			if (g_bMusic[Music_RoundStart]) PrecacheSoundEx(g_strMusic[Music_RoundStart], true, true);
			if (g_bMusic[Music_RoundWin])   PrecacheSoundEx(g_strMusic[Music_RoundWin], true, true);
			if (g_bMusic[Music_RoundLose])  PrecacheSoundEx(g_strMusic[Music_RoundLose], true, true);
			if (g_bMusic[Music_Gameplay])   PrecacheSoundEx(g_strMusic[Music_Gameplay], true, true);
		}

		// Precache particles
		PrecacheParticle(PARTICLE_NUKE_1);
		PrecacheParticle(PARTICLE_NUKE_2);
		PrecacheParticle(PARTICLE_NUKE_3);
		PrecacheParticle(PARTICLE_NUKE_4);
		PrecacheParticle(PARTICLE_NUKE_5);
		PrecacheParticle(PARTICLE_NUKE_COLLUMN);

		// Precache rocket resources
		for (new i = 0; i < g_iRocketClassCount; i++)
		{
			new RocketFlags:iFlags = g_iRocketClassFlags[i];
			if (TestFlags(iFlags, RocketFlag_CustomModel))	  PrecacheModelEx(g_strRocketClassModel[i], true, true);
			if (TestFlags(iFlags, RocketFlag_CustomSpawnSound)) PrecacheSoundEx(g_strRocketClassSpawnSound[i], true, true);
			if (TestFlags(iFlags, RocketFlag_CustomBeepSound))  PrecacheSoundEx(g_strRocketClassBeepSound[i], true, true);
			if (TestFlags(iFlags, RocketFlag_CustomAlertSound)) PrecacheSoundEx(g_strRocketClassAlertSound[i], true, true);
		}

		// Execute enable config file
		decl String:strCfgFile[64]; GetConVarString(g_hCvarEnableCfgFile, strCfgFile, sizeof(strCfgFile));
		ServerCommand("exec \"%s\"", strCfgFile);

		// Done.
		g_bEnabled		= true;
		g_bRoundStarted   = false;
		g_iRoundCount	 = 0;
	}
}

/* DisableDodgeBall()
**
** Disables all hooks and frees arrays.
** -------------------------------------------------------------------------- */
DisableDodgeBall()
{
	if (g_bEnabled == true)
	{
		// Clean up everything
		DestroyRockets();
		DestroyRocketClasses();
		DestroySpawners();
		if (g_hLogicTimer != INVALID_HANDLE) KillTimer(g_hLogicTimer);
		g_hLogicTimer = INVALID_HANDLE;

		// Disable music
		g_bMusic[Music_RoundStart] =
		g_bMusic[Music_RoundWin]   =
		g_bMusic[Music_RoundLose]  =
		g_bMusic[Music_Gameplay]   = false;

		// Unhook events and info_target outputs;
		UnhookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_setup_finished", OnSetupFinished, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
		UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
		UnhookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
		UnhookEvent("teamplay_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre);

		// Execute enable config file
		decl String:strCfgFile[64]; GetConVarString(g_hCvarDisableCfgFile, strCfgFile, sizeof(strCfgFile));
		ServerCommand("exec \"%s\"", strCfgFile);

		// Done.
		g_bEnabled		= false;
		g_bRoundStarted   = false;
		g_iRoundCount	 = 0;
	}
}

//   ___					 _
//  / __|__ _ _ __  ___ _ __| |__ _ _  _
// | (_ / _` | '  \/ -_) '_ \ / _` | || |
//  \___\__,_|_|_|_\___| .__/_\__,_|\_, |
//					 |_|		  |__/

/* OnRoundStart()
**
** At round start, do something?
** -------------------------------------------------------------------------- */
public Action:OnRoundStart(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	if (g_bMusic[Music_RoundStart])
	{
		EmitSoundToAll(g_strMusic[Music_RoundStart]);
	}
	g_iRocketSpeed = 0;
	if (g_hTimerHud != INVALID_HANDLE)
	{
		KillTimer(g_hTimerHud);
		g_hTimerHud = INVALID_HANDLE;
	}
	g_hTimerHud = CreateTimer(1.0, Timer_HudSpeed, _, TIMER_REPEAT);
}

/* OnSetupFinished()
**
** When the setup finishes, populate the spawn points arrays and create the
** Dodgeball game logic timer.
** -------------------------------------------------------------------------- */
public Action:OnSetupFinished(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	if ((g_bEnabled == true) && (BothTeamsPlaying() == true))
	{
		PopulateSpawnPoints();

		if (g_iLastDeadTeam == 0) g_iLastDeadTeam = GetURandomIntRange(_:TFTeam_Red, _:TFTeam_Blue);
		if (!IsValidClient(g_iLastDeadClient)) g_iLastDeadClient = 0;

		g_hLogicTimer	  = CreateTimer(FPS_LOGIC_INTERVAL, OnDodgeBallGameFrame, _, TIMER_REPEAT);
		g_iPlayerCount	 = CountAlivePlayers();
		g_iRocketsFired	= 0;
		g_iCurrentRedSpawn = 0;
		g_iCurrentBluSpawn = 0;
		g_fNextSpawnTime   = GetGameTime();
		g_bRoundStarted	= true;
		g_iRoundCount++;
	}
}

/* OnRoundEnd()
**
** At round end, stop the Dodgeball game logic timer and destroy the remaining
** rockets.
** -------------------------------------------------------------------------- */
public Action:OnRoundEnd(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	if (g_hTimerHud != INVALID_HANDLE)
	{
		KillTimer(g_hTimerHud);
		g_hTimerHud = INVALID_HANDLE;
	}
	if (g_hLogicTimer != INVALID_HANDLE)
	{
		KillTimer(g_hLogicTimer);
		g_hLogicTimer = INVALID_HANDLE;
	}

	if (g_bMusicEnabled == true)
	{
		if (g_bUseWebPlayer)
		{
			for (new iClient = 1; iClient <= MaxClients; iClient++)
			{
				if (IsValidClient(iClient))
				{
					ShowHiddenMOTDPanel(iClient, "MusicPlayerStop", "http://0.0.0.0/");
					if (!IsFakeClient(iClient))
					{
						ClearSyncHud(iClient, g_hHud);
					}
				}
			}
		}
		else if (g_bMusic[Music_Gameplay])
		{
			StopSoundToAll(SNDCHAN_MUSIC, g_strMusic[Music_Gameplay]);
		}
	}

	DestroyRockets();
	g_bRoundStarted = false;
}

/* OnPlayerSpawn()
**
** When the player spawns, force class to Pyro.
** -------------------------------------------------------------------------- */
public Action:OnPlayerSpawn(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return;

	new TFClassType:iClass = TF2_GetPlayerClass(iClient);
	if (!(iClass == TFClass_Pyro || iClass == TFClassType:TFClass_Unknown))
	{
		TF2_SetPlayerClass(iClient, TFClass_Pyro, false, true);
		TF2_RespawnPlayer(iClient);
	}
}

/* OnPlayerDeath()
**
** When the player dies, set the last dead team to determine the next
** rocket's team.
** -------------------------------------------------------------------------- */
public Action:OnPlayerDeath(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	if (g_bRoundStarted == false) return;
	new iAttacker = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (IsValidClient(iVictim))
	{
		g_iLastDeadClient = iVictim;
		g_iLastDeadTeam = GetClientTeam(iVictim);

		new iInflictor = GetEventInt(hEvent, "inflictor_entindex");
		new iIndex = FindRocketByEntity(iInflictor);

		if (iIndex != -1)
		{
			new iClass = g_iRocketClass[iIndex];
			new iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
			new Float:fSpeed = g_fRocketSpeed[iIndex];
			new iDeflections = g_iRocketDeflections[iIndex];

			if(GetConVarBool(g_hCvarAnnounce)) PrintToChatAll("\x05%N\01 died to a rocket travelling \x05%i\x01 mph!", g_iLastDeadClient, g_iRocketSpeed);

			if ((g_iRocketFlags[iIndex] & RocketFlag_OnExplodeCmd) && !(g_iRocketFlags[iIndex] & RocketFlag_Exploded))
			{
				ExecuteCommands(g_hRocketClassCmdsOnExplode[iClass], iClass, iInflictor, iAttacker, iTarget, g_iLastDeadClient, fSpeed, iDeflections);
				g_iRocketFlags[iIndex] |= RocketFlag_Exploded;
			}

			if (TestFlags(g_iRocketFlags[iIndex], RocketFlag_OnKillCmd))
				ExecuteCommands(g_hRocketClassCmdsOnKill[iClass], iClass, iInflictor, iAttacker, iTarget, g_iLastDeadClient, fSpeed, iDeflections);
		}
	}

	SetRandomSeed(_:GetGameTime());
}

/* OnPlayerInventory()
**
** Make sure the client only has the flamethrower equipped.
** -------------------------------------------------------------------------- */
public Action:OnPlayerInventory(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	new iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient)) return;

	for (new iSlot = 1; iSlot < 5; iSlot++)
	{
		new iEntity = GetPlayerWeaponSlot(iClient, iSlot);
		if (iEntity != -1) RemoveEdict(iEntity);
	}
}

/* OnPlayerRunCmd()
**
** Block flamethrower's Mouse1 attack.
** -------------------------------------------------------------------------- */
public Action:OnPlayerRunCmd(iClient, &iButtons, &iImpulse, Float:fVelocity[3], Float:fAngles[3], &iWeapon)
{
	if (g_bEnabled == true) iButtons &= ~IN_ATTACK;
	return Plugin_Continue;
}

/* OnBroadcastAudio()
**
** Replaces the broadcasted audio for our custom music files.
** -------------------------------------------------------------------------- */
public Action:OnBroadcastAudio(Handle:hEvent, String:strEventName[], bool:bDontBroadcast)
{
	if (g_bMusicEnabled == true)
	{
		decl String:strSound[PLATFORM_MAX_PATH];
		GetEventString(hEvent, "sound", strSound, sizeof(strSound));
		new iTeam = GetEventInt(hEvent, "team");

		if (StrEqual(strSound, "Announcer.AM_RoundStartRandom") == true)
		{
			if (g_bUseWebPlayer == false)
			{
				if (g_bMusic[Music_Gameplay])
				{
					EmitSoundToAll(g_strMusic[Music_Gameplay], SOUND_FROM_PLAYER, SNDCHAN_MUSIC);
					return Plugin_Handled;
				}
			}
			else
			{
				for (new iClient = 1; iClient <= MaxClients; iClient++)
					if (IsValidClient(iClient))
						ShowHiddenMOTDPanel(iClient, "MusicPlayerStart", g_strWebPlayerUrl);

				return Plugin_Handled;
			}
		}
		else if (StrEqual(strSound, "Game.YourTeamWon") == true)
		{
			if (g_bMusic[Music_RoundWin])
			{
				for (new iClient = 1; iClient <= MaxClients; iClient++)
					if (IsValidClient(iClient) && (iTeam == GetClientTeam(iClient)))
						EmitSoundToClient(iClient, g_strMusic[Music_RoundWin]);

				return Plugin_Handled;
			}
		}
		else if (StrEqual(strSound, "Game.YourTeamLost") == true)
		{
			if (g_bMusic[Music_RoundLose])
			{
				for (new iClient = 1; iClient <= MaxClients; iClient++)
					if (IsValidClient(iClient) && (iTeam == GetClientTeam(iClient)))
						EmitSoundToClient(iClient, g_strMusic[Music_RoundLose]);

				return Plugin_Handled;
			}
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

/* OnDodgeBallGameFrame()
**
** Every tick of the Dodgeball logic.
** -------------------------------------------------------------------------- */
public Action:OnDodgeBallGameFrame(Handle:hTimer, any:Data)
{
	// Only if both teams are playing
	if (BothTeamsPlaying() == false) return;

	// Check if we need to fire more rockets.
	if (GetGameTime() >= g_fNextSpawnTime)
	{
		if (g_iLastDeadTeam == _:TFTeam_Red)
		{
			new iSpawnerEntity = g_iSpawnPointsRedEntity[g_iCurrentRedSpawn];
			new iSpawnerClass  = g_iSpawnPointsRedClass[g_iCurrentRedSpawn];
			if (g_iRocketCount < g_iSpawnersMaxRockets[iSpawnerClass])
			{
				CreateRocket(iSpawnerEntity, iSpawnerClass, _:TFTeam_Red);
				g_iCurrentRedSpawn = (g_iCurrentRedSpawn + 1) % g_iSpawnPointsRedCount;
			}
		}
		else
		{
			new iSpawnerEntity = g_iSpawnPointsBluEntity[g_iCurrentBluSpawn];
			new iSpawnerClass  = g_iSpawnPointsBluClass[g_iCurrentBluSpawn];
			if (g_iRocketCount < g_iSpawnersMaxRockets[iSpawnerClass])
			{
				CreateRocket(iSpawnerEntity, iSpawnerClass, _:TFTeam_Blue);
				g_iCurrentBluSpawn = (g_iCurrentBluSpawn + 1) % g_iSpawnPointsBluCount;
			}
		}
	}

	// Manage the active rockets
	new iIndex = -1;
	while ((iIndex = FindNextValidRocket(iIndex)) != -1)
	{
		switch (g_iRocketClassBehaviour[g_iRocketClass[iIndex]])
		{
			case Behaviour_Unknown: {}
			case Behaviour_Homing:  { HomingRocketThink(iIndex); }
		}
	}
}

public Action:Timer_HudSpeed(Handle:hTimer)
{
	if(GetConVarBool(g_hCvarSpeedo))
	{
		SetHudTextParams(-1.0, 0.9, 1.1, 255, 255, 255, 255);
		for (new iClient = 1; iClient <= MaxClients; iClient++)
		{
			if (IsValidClient(iClient) && !IsFakeClient(iClient) && g_iRocketSpeed != 0)
			{
				ShowSyncHudText(iClient, g_hHud, "Speed: %i mph", g_iRocketSpeed);
			}
		}
	}
}

//  ___		 _	   _
// | _ \___  __| |_____| |_ ___
// |   / _ \/ _| / / -_)  _(_-<
// |_|_\___/\__|_\_\___|\__/__/

/* CreateRocket()
**
** Fires a new rocket entity from the spawner's position.
** -------------------------------------------------------------------------- */
public CreateRocket(iSpawnerEntity, iSpawnerClass, iTeam)
{
	new iIndex = FindFreeRocketSlot();
	if (iIndex != -1)
	{
		// Fetch a random rocket class and it's parameters.
		new iClass = GetRandomRocketClass(iSpawnerClass);
		new RocketFlags:iFlags = g_iRocketClassFlags[iClass];

		// Create rocket entity.
		new iEntity = CreateEntityByName(TestFlags(iFlags, RocketFlag_IsAnimated)? "tf_projectile_sentryrocket" : "tf_projectile_rocket");
		if (iEntity && IsValidEntity(iEntity))
		{
			// Fetch spawn point's location and angles.
			new Float:fPosition[3], Float:fAngles[3], Float:fDirection[3];
			GetEntPropVector(iSpawnerEntity, Prop_Send, "m_vecOrigin", fPosition);
			GetEntPropVector(iSpawnerEntity, Prop_Send, "m_angRotation", fAngles);
			GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);

			// Setup rocket entity.
			SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", 0);
			SetEntProp(iEntity,	Prop_Send, "m_bCritical",	(GetURandomFloatRange(0.0, 100.0) <= g_fRocketClassCritChance[iClass])? 1 : 0, 1);
			SetEntProp(iEntity,	Prop_Send, "m_iTeamNum",	 iTeam, 1);
			SetEntProp(iEntity,	Prop_Send, "m_iDeflected",   1);
			TeleportEntity(iEntity, fPosition, fAngles, Float:{0.0, 0.0, 0.0});

			// Setup rocket structure with the newly created entity.
			new iTargetTeam	 = (TestFlags(iFlags, RocketFlag_IsNeutral))? 0 : GetAnalogueTeam(iTeam);
			new iTarget		 = SelectTarget(iTargetTeam);
			new Float:fModifier = CalculateModifier(iClass, 0);
			g_bRocketIsValid[iIndex]			= true;
			g_iRocketFlags[iIndex]			  = iFlags;
			g_iRocketEntity[iIndex]			 = EntIndexToEntRef(iEntity);
			g_iRocketTarget[iIndex]			 = EntIndexToEntRef(iTarget);
			g_iRocketSpawner[iIndex]			= iSpawnerClass;
			g_iRocketClass[iIndex]			  = iClass;
			g_iRocketDeflections[iIndex]		= 0;
			g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
			g_fRocketLastBeepTime[iIndex]	   = GetGameTime();
			g_fRocketSpeed[iIndex]			  = CalculateRocketSpeed(iClass, fModifier);
			g_iRocketSpeed 						= RoundFloat(g_fRocketSpeed[iIndex] * 0.042614);

			CopyVectors(fDirection, g_fRocketDirection[iIndex]);
			SetEntDataFloat(iEntity, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
			DispatchSpawn(iEntity);

			// Apply custom model, if specified on the flags.
			if (TestFlags(iFlags, RocketFlag_CustomModel))
			{
				SetEntityModel(iEntity, g_strRocketClassModel[iClass]);
				UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
			}

			// Execute commands on spawn.
			if (TestFlags(iFlags, RocketFlag_OnSpawnCmd))
			{
				ExecuteCommands(g_hRocketClassCmdsOnSpawn[iClass], iClass, iEntity, 0, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], 0);
			}

			// Emit required sounds.
			EmitRocketSound(RocketSound_Spawn, iClass, iEntity, iTarget, iFlags);
			EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);

			// Done
			g_iRocketCount++;
			g_iRocketsFired++;
			g_fNextSpawnTime = GetGameTime() + g_fSpawnersInterval[iSpawnerClass];
		}
	}
}

/* DestroyRocket()
**
** Destroys the rocket at the given index.
** -------------------------------------------------------------------------- */
DestroyRocket(iIndex)
{
	if (IsValidRocket(iIndex) == true)
	{
		new iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
		if (iEntity && IsValidEntity(iEntity)) RemoveEdict(iEntity);
		g_bRocketIsValid[iIndex] = false;
		g_iRocketCount--;
	}
}

/* DestroyRockets()
**
** Destroys all the rockets that are currently active.
** -------------------------------------------------------------------------- */
DestroyRockets()
{
	for (new iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
	{
		DestroyRocket(iIndex);
	}
	g_iRocketCount = 0;
}

/* IsValidRocket()
**
** Checks if a rocket structure is valid.
** -------------------------------------------------------------------------- */
bool:IsValidRocket(iIndex)
{
	if ((iIndex >= 0) && (g_bRocketIsValid[iIndex] == true))
	{
		if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == -1)
		{
			g_bRocketIsValid[iIndex] = false;
			g_iRocketCount--;
			return false;
		}
		return true;
	}
	return false;
}

/* FindNextValidRocket()
**
** Retrieves the index of the next valid rocket from the current offset.
** -------------------------------------------------------------------------- */
FindNextValidRocket(iIndex, bool:bWrap = false)
{
	for (new iCurrent = iIndex + 1; iCurrent < MAX_ROCKETS; iCurrent++)
		if (IsValidRocket(iCurrent))
			return iCurrent;

	return (bWrap == true)? FindNextValidRocket(-1, false) : -1;
}

/* FindFreeRocketSlot()
**
** Retrieves the next free rocket slot since the current one. If all of them
** are full, returns -1.
** -------------------------------------------------------------------------- */
FindFreeRocketSlot()
{
	new iIndex = g_iLastCreatedRocket;
	new iCurrent = iIndex;

	do
	{
		if (!IsValidRocket(iCurrent)) return iCurrent;
		if ((++iCurrent) == MAX_ROCKETS) iCurrent = 0;
	} while (iCurrent != iIndex);

	return -1;
}

/* FindRocketByEntity()
**
** Finds a rocket index from it's entity.
** -------------------------------------------------------------------------- */
FindRocketByEntity(iEntity)
{
	new iIndex = -1;
	while ((iIndex = FindNextValidRocket(iIndex)) != -1)
		if (EntRefToEntIndex(g_iRocketEntity[iIndex]) == iEntity)
			return iIndex;

	return -1;
}

/* HomingRocketThinkg()
**
** Logic process for the Behaviour_Homing type rockets, wich is simply a
** follower rocket, picking a random target.
** -------------------------------------------------------------------------- */
HomingRocketThink(iIndex)
{
	// Retrieve the rocket's attributes.
	new iEntity			= EntRefToEntIndex(g_iRocketEntity[iIndex]);
	new iClass			 = g_iRocketClass[iIndex];
	new RocketFlags:iFlags = g_iRocketFlags[iIndex];
	new iTarget			= EntRefToEntIndex(g_iRocketTarget[iIndex]);
	new iTeam			  = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
	new iTargetTeam		= (TestFlags(iFlags, RocketFlag_IsNeutral))? 0 : GetAnalogueTeam(iTeam);
	new iDeflectionCount   = GetEntProp(iEntity, Prop_Send, "m_iDeflected") - 1;
	new Float:fModifier	= CalculateModifier(iClass, iDeflectionCount);

	// Check if the target is available
	if (!IsValidClient(iTarget, true))
	{
		iTarget = SelectTarget(iTargetTeam);
		if (!IsValidClient(iTarget, true)) return;
		g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
	}
	// Has the rocket been deflected recently? If so, set new target.
	else if ((iDeflectionCount > g_iRocketDeflections[iIndex]))
	{
		// Calculate new direction from the player's forward
		new iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if (IsValidClient(iClient))
		{
			new Float:fViewAngles[3], Float:fDirection[3];
			GetClientEyeAngles(iClient, fViewAngles);
			GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
			CopyVectors(fDirection, g_fRocketDirection[iIndex]);
			UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
		}

		// Set new target & deflection count
		iTarget = SelectTarget(iTargetTeam, iIndex);
		g_iRocketTarget[iIndex]			 = EntIndexToEntRef(iTarget);
		g_iRocketDeflections[iIndex]		= iDeflectionCount;
		g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
		g_fRocketSpeed[iIndex]			  = CalculateRocketSpeed(iClass, fModifier);
		g_iRocketSpeed 						= RoundFloat(g_fRocketSpeed[iIndex] * 0.042614);

		SetEntDataFloat(iEntity, FindSendPropOffs("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
		if (TestFlags(iFlags, RocketFlag_ElevateOnDeflect)) g_iRocketFlags[iIndex] |= RocketFlag_Elevating;
		EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);

		// Execute appropiate command
		if (TestFlags(iFlags, RocketFlag_OnDeflectCmd))
		{
			ExecuteCommands(g_hRocketClassCmdsOnDeflect[iClass], iClass, iEntity, iClient, iTarget, g_iLastDeadClient, g_fRocketSpeed[iIndex], iDeflectionCount);
		}
	}
	else
	{
		// If the delay time since the last reflection has been elapsed, rotate towards the client.
		if ((GetGameTime() - g_fRocketLastDeflectionTime[iIndex]) >= g_fRocketClassControlDelay[iClass])
		{
			// Calculate turn rate and retrieve directions.
			new Float:fTurnRate = CalculateRocketTurnRate(iClass, fModifier);
			decl Float:fDirectionToTarget[3]; CalculateDirectionToClient(iEntity, iTarget, fDirectionToTarget);

			// Elevate the rocket after a deflection (if it's enabled on the class definition, of course.)
			if (g_iRocketFlags[iIndex] & RocketFlag_Elevating)
			{
				if (g_fRocketDirection[iIndex][2] < g_fRocketClassElevationLimit[iClass])
				{
					g_fRocketDirection[iIndex][2] = FMin(g_fRocketDirection[iIndex][2] + g_fRocketClassElevationRate[iClass], g_fRocketClassElevationLimit[iClass]);
					fDirectionToTarget[2] = g_fRocketDirection[iIndex][2];
				}
				else
				{
					g_iRocketFlags[iIndex] &= ~RocketFlag_Elevating;
				}
			}

			// Smoothly change the orientation to the new one.
			LerpVectors(g_fRocketDirection[iIndex], fDirectionToTarget, g_fRocketDirection[iIndex], fTurnRate);
		}

		// If it's a nuke, beep every some time
		if ((GetGameTime() - g_fRocketLastBeepTime[iIndex]) >= g_fRocketClassBeepInterval[iClass])
		{
			EmitRocketSound(RocketSound_Beep, iClass, iEntity, iTarget, iFlags);
			g_fRocketLastBeepTime[iIndex] = GetGameTime();
		}
	}

	// Done
	ApplyRocketParameters(iIndex);
}

/* CalculateModifier()
**
** Gets the modifier for the damage/speed/rotation calculations.
** -------------------------------------------------------------------------- */
Float:CalculateModifier(iClass, iDeflections)
{
	return  iDeflections +
			(g_iRocketsFired * g_fRocketClassRocketsModifier[iClass]) +
			(g_iPlayerCount * g_fRocketClassPlayerModifier[iClass]);
}

/* CalculateRocketDamage()
**
** Calculates the damage of the rocket based on it's type and deflection count.
** -------------------------------------------------------------------------- */
Float:CalculateRocketDamage(iClass, Float:fModifier)
{
	return g_fRocketClassDamage[iClass] + g_fRocketClassDamageIncrement[iClass] * fModifier;
}

/* CalculateRocketSpeed()
**
** Calculates the speed of the rocket based on it's type and deflection count.
** -------------------------------------------------------------------------- */
Float:CalculateRocketSpeed(iClass, Float:fModifier)
{
	return g_fRocketClassSpeed[iClass] + g_fRocketClassSpeedIncrement[iClass] * fModifier;
}

/* CalculateRocketTurnRate()
**
** Calculates the rocket's turn rate based upon it's type and deflection count.
** -------------------------------------------------------------------------- */
Float:CalculateRocketTurnRate(iClass, Float:fModifier)
{
	return g_fRocketClassTurnRate[iClass] + g_fRocketClassTurnRateIncrement[iClass] * fModifier;
}

/* CalculateDirectionToClient()
**
** As the name indicates, calculates the orientation for the rocket to move
** towards the specified client.
** -------------------------------------------------------------------------- */
CalculateDirectionToClient(iEntity, iClient, Float:fOut[3])
{
	decl Float:fRocketPosition[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
	GetClientEyePosition(iClient, fOut);
	MakeVectorFromPoints(fRocketPosition, fOut, fOut);
	NormalizeVector(fOut, fOut);
}

/* ApplyRocketParameters()
**
** Transforms and applies the speed, direction and angles for the rocket
** entity.
** -------------------------------------------------------------------------- */
ApplyRocketParameters(iIndex)
{
	new iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	decl Float:fAngles[3]; GetVectorAngles(g_fRocketDirection[iIndex], fAngles);
	decl Float:fVelocity[3]; CopyVectors(g_fRocketDirection[iIndex], fVelocity);
	ScaleVector(fVelocity, g_fRocketSpeed[iIndex]);
	SetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", fVelocity);
	SetEntPropVector(iEntity, Prop_Send, "m_angRotation", fAngles);
}

/* UpdateRocketSkin()
**
** Changes the skin of the rocket based on it's team.
** -------------------------------------------------------------------------- */
UpdateRocketSkin(iEntity, iTeam, bool:bNeutral)
{
	if (bNeutral == true) SetEntProp(iEntity, Prop_Send, "m_nSkin", 2);
	else				  SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam == _:TFTeam_Blue)? 0 : 1);
}

/* GetRandomRocketClass()
**
** Generates a random value and retrieves a rocket class based upon a chances table.
** -------------------------------------------------------------------------- */
GetRandomRocketClass(iSpawnerClass)
{
	new iRandom = GetURandomIntRange(0, 101);
	new Handle:hTable = g_hSpawnersChancesTable[iSpawnerClass];
	new iTableSize = GetArraySize(hTable);
	new iChancesLower = 0;
	new iChancesUpper = 0;

	for (new iEntry = 0; iEntry < iTableSize; iEntry++)
	{
		iChancesLower += iChancesUpper;
		iChancesUpper  = iChancesLower + GetArrayCell(hTable, iEntry);

		if ((iRandom >= iChancesLower) && (iRandom < iChancesUpper))
		{
			return iEntry;
		}
	}

	return 0;
}

/* EmitRocketSound()
**
** Emits one of the rocket sounds
** -------------------------------------------------------------------------- */
EmitRocketSound(RocketSound:iSound, iClass, iEntity, iTarget, RocketFlags:iFlags)
{
	switch (iSound)
	{
		case RocketSound_Spawn:
		{
			if (TestFlags(iFlags, RocketFlag_PlaySpawnSound))
			{
				if (TestFlags(iFlags, RocketFlag_CustomSpawnSound)) EmitSoundToAll(g_strRocketClassSpawnSound[iClass], iEntity);
				else												EmitSoundToAll(SOUND_DEFAULT_SPAWN, iEntity);
			}
		}
		case RocketSound_Beep:
		{
			if (TestFlags(iFlags, RocketFlag_PlayBeepSound))
			{
				if (TestFlags(iFlags, RocketFlag_CustomBeepSound)) EmitSoundToAll(g_strRocketClassBeepSound[iClass], iEntity);
				else											   EmitSoundToAll(SOUND_DEFAULT_BEEP, iEntity);
			}
		}
		case RocketSound_Alert:
		{
			if (TestFlags(iFlags, RocketFlag_PlayAlertSound))
			{
				if (TestFlags(iFlags, RocketFlag_CustomAlertSound)) EmitSoundToClient(iTarget, g_strRocketClassAlertSound[iClass]);
				else												EmitSoundToClient(iTarget, SOUND_DEFAULT_ALERT, _, _, _, _, 0.5);
			}
		}
	}
}

//  ___		 _	   _	  ___ _
// | _ \___  __| |_____| |_   / __| |__ _ ______ ___ ___
// |   / _ \/ _| / / -_)  _| | (__| / _` (_-<_-</ -_|_-<
// |_|_\___/\__|_\_\___|\__|  \___|_\__,_/__/__/\___/__/
//

/* DestroyRocketClasses()
**
** Frees up all the rocket classes defined now.
** -------------------------------------------------------------------------- */
DestroyRocketClasses()
{
	for (new iIndex = 0; iIndex < g_iRocketClassCount; iIndex++)
	{
		new Handle:hCmdOnSpawn   = g_hRocketClassCmdsOnSpawn[iIndex];
		new Handle:hCmdOnKill	= g_hRocketClassCmdsOnKill[iIndex];
		new Handle:hCmdOnExplode = g_hRocketClassCmdsOnExplode[iIndex];
		new Handle:hCmdOnDeflect = g_hRocketClassCmdsOnDeflect[iIndex];
		if (hCmdOnSpawn   != INVALID_HANDLE) CloseHandle(hCmdOnSpawn);
		if (hCmdOnKill	!= INVALID_HANDLE) CloseHandle(hCmdOnKill);
		if (hCmdOnExplode != INVALID_HANDLE) CloseHandle(hCmdOnExplode);
		if (hCmdOnDeflect != INVALID_HANDLE) CloseHandle(hCmdOnDeflect);
		g_hRocketClassCmdsOnSpawn[iIndex]   = INVALID_HANDLE;
		g_hRocketClassCmdsOnKill[iIndex]	= INVALID_HANDLE;
		g_hRocketClassCmdsOnExplode[iIndex] = INVALID_HANDLE;
		g_hRocketClassCmdsOnDeflect[iIndex] = INVALID_HANDLE;
	}
	g_iRocketClassCount = 0;
	ClearTrie(g_hRocketClassTrie);
}

//  ___						  ___	 _	 _					 _	___ _
// / __|_ __  __ ___ __ ___ _   | _ \___(_)_ _| |_ ___  __ _ _ _  __| |  / __| |__ _ ______ ___ ___
// \__ \ '_ \/ _` \ V  V / ' \  |  _/ _ \ | ' \  _(_-< / _` | ' \/ _` | | (__| / _` (_-<_-</ -_|_-<
// |___/ .__/\__,_|\_/\_/|_||_| |_| \___/_|_||_\__/__/ \__,_|_||_\__,_|  \___|_\__,_/__/__/\___/__/
//	 |_|

/* DestroySpawners()
**
** Frees up all the spawner points defined up to now.
** -------------------------------------------------------------------------- */
DestroySpawners()
{
	for (new iIndex = 0; iIndex < g_iSpawnersCount; iIndex++)
	{
		CloseHandle(g_hSpawnersChancesTable[iIndex]);
	}
	g_iSpawnersCount  = 0;
	g_iSpawnPointsRedCount = 0;
	g_iSpawnPointsBluCount = 0;
	g_iDefaultRedSpawner = -1;
	g_iDefaultBluSpawner = -1;
	ClearTrie(g_hSpawnersTrie);
}

/* PopulateSpawnPoints()
**
** Iterates through all the possible spawn points and assigns them an spawner.
** -------------------------------------------------------------------------- */
PopulateSpawnPoints()
{
	// Clear the current settings
	g_iSpawnPointsRedCount = 0;
	g_iSpawnPointsBluCount = 0;

	// Iterate through all the info target points and check 'em out.
	new iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "info_target")) != -1)
	{
		decl String:strName[32]; GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
		if ((StrContains(strName, "rocket_spawn_red") != -1) || (StrContains(strName, "tf_dodgeball_red") != -1))
		{
			// Find most appropiate spawner class for this entity.
			new iIndex = FindSpawnerByName(strName);
			if (!IsValidRocket(iIndex)) iIndex = g_iDefaultRedSpawner;

			// Upload to point list
			g_iSpawnPointsRedClass [g_iSpawnPointsRedCount] = iIndex;
			g_iSpawnPointsRedEntity[g_iSpawnPointsRedCount] = iEntity;
			g_iSpawnPointsRedCount++;
		}
		if ((StrContains(strName, "rocket_spawn_blue") != -1) || (StrContains(strName, "tf_dodgeball_blu") != -1))
		{
			// Find most appropiate spawner class for this entity.
			new iIndex = FindSpawnerByName(strName);
			if (!IsValidRocket(iIndex)) iIndex = g_iDefaultBluSpawner;

			// Upload to point list
			g_iSpawnPointsBluClass [g_iSpawnPointsBluCount] = iIndex;
			g_iSpawnPointsBluEntity[g_iSpawnPointsBluCount] = iEntity;
			g_iSpawnPointsBluCount++;
		}
	}

	// Check if there exists spawn points
	if (g_iSpawnPointsRedCount == 0) SetFailState("No RED spawn points found on this map.");
	if (g_iSpawnPointsBluCount == 0) SetFailState("No BLU spawn points found on this map.");
}

/* FindSpawnerByName()
**
** Finds the first spawner wich contains the given name.
** -------------------------------------------------------------------------- */
FindSpawnerByName(String:strName[32])
{
	new iIndex = -1;
	GetTrieValue(g_hSpawnersTrie, strName, iIndex);
	return iIndex;
}


/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**	______										  __
**   / ____/___  ____ ___  ____ ___  ____ _____  ____/ /____
**  / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  / ___/
** / /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ (__  )
** \____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/____/
**
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* RegisterCommands()
**
** Creates helper server commands to use with the plugin's events system.
** -------------------------------------------------------------------------- */
RegisterCommands()
{
	RegServerCmd("tf_dodgeball_explosion", CmdExplosion);
	RegServerCmd("tf_dodgeball_shockwave", CmdShockwave);
}

/* CmdExplosion()
**
** Creates a huge explosion at the location of the client.
** -------------------------------------------------------------------------- */
public Action:CmdExplosion(iArgs)
{
	if (iArgs == 1)
	{
		decl String:strBuffer[8], iClient;
		GetCmdArg(1, strBuffer, sizeof(strBuffer));
		iClient = StringToInt(strBuffer);
		if (IsValidEntity(iClient))
		{
			decl Float:fPosition[3]; GetClientAbsOrigin(iClient, fPosition);
			switch (GetURandomIntRange(0, 4))
			{
				case 0: { PlayParticle(fPosition, PARTICLE_NUKE_1_ANGLES, PARTICLE_NUKE_1); }
				case 1: { PlayParticle(fPosition, PARTICLE_NUKE_2_ANGLES, PARTICLE_NUKE_2); }
				case 2: { PlayParticle(fPosition, PARTICLE_NUKE_3_ANGLES, PARTICLE_NUKE_3); }
				case 3: { PlayParticle(fPosition, PARTICLE_NUKE_4_ANGLES, PARTICLE_NUKE_4); }
				case 4: { PlayParticle(fPosition, PARTICLE_NUKE_5_ANGLES, PARTICLE_NUKE_5); }
			}
			PlayParticle(fPosition, PARTICLE_NUKE_COLLUMN_ANGLES, PARTICLE_NUKE_COLLUMN);
		}
	}
	else
	{
		PrintToServer("Usage: tf_dodgeball_explosion <client index>");
	}

	return Plugin_Handled;
}

/* CmdShockwave()
**
** Creates a huge shockwave at the location of the client, with the given
** parameters.
** -------------------------------------------------------------------------- */
public Action:CmdShockwave(iArgs)
{
	if (iArgs == 5)
	{
		decl String:strBuffer[8], iClient, iTeam, Float:fPosition[3], iDamage, Float:fPushStrength, Float:fRadius, Float:fFalloffRadius;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iClient		= StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); iDamage		= StringToInt(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); fPushStrength  = StringToFloat(strBuffer);
		GetCmdArg(4, strBuffer, sizeof(strBuffer)); fRadius		= StringToFloat(strBuffer);
		GetCmdArg(5, strBuffer, sizeof(strBuffer)); fFalloffRadius = StringToFloat(strBuffer);

		if (IsValidClient(iClient))
		{
			iTeam = GetClientTeam(iClient);
			GetClientAbsOrigin(iClient, fPosition);

			for (iClient = 1; iClient <= MaxClients; iClient++)
			{
				if ((IsValidClient(iClient, true) == true) && (GetClientTeam(iClient) == iTeam))
				{
					decl Float:fPlayerPosition[3]; GetClientEyePosition(iClient, fPlayerPosition);
					new Float:fDistanceToShockwave = GetVectorDistance(fPosition, fPlayerPosition);

					if (fDistanceToShockwave < fRadius)
					{
						decl Float:fImpulse[3], Float:fFinalPush, iFinalDamage;
						fImpulse[0] = fPlayerPosition[0] - fPosition[0];
						fImpulse[1] = fPlayerPosition[1] - fPosition[1];
						fImpulse[2] = fPlayerPosition[2] - fPosition[2];
						NormalizeVector(fImpulse, fImpulse);
						if (fImpulse[2] < 0.4) { fImpulse[2] = 0.4; NormalizeVector(fImpulse, fImpulse); }

						if (fDistanceToShockwave < fFalloffRadius)
						{
							fFinalPush = fPushStrength;
							iFinalDamage = iDamage;
						}
						else
						{
							new Float:fImpact = (1.0 - ((fDistanceToShockwave - fFalloffRadius) / (fRadius - fFalloffRadius)));
							fFinalPush   = fImpact * fPushStrength;
							iFinalDamage = RoundToFloor(fImpact * iDamage);
						}
						ScaleVector(fImpulse, fFinalPush);
						SetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", fImpulse);

						new Handle:hDamage = CreateDataPack();
						WritePackCell(hDamage, iClient);
						WritePackCell(hDamage, iFinalDamage);
						CreateTimer(0.1, ApplyDamage, hDamage, TIMER_FLAG_NO_MAPCHANGE);
					}
				}
			}
		}
	}
	else
	{
		PrintToServer("Usage: tf_dodgeball_shockwave <client index> <damage> <push strength> <radius> <falloff>");
	}

	return Plugin_Handled;
}

/* ExecuteCommands()
**
** The core of the plugin's event system, unpacks and correctly formats the
** given command strings to be executed.
** -------------------------------------------------------------------------- */
ExecuteCommands(Handle:hDataPack, iClass, iRocket, iOwner, iTarget, iLastDead, Float:fSpeed, iNumDeflections)
{
	ResetPack(hDataPack, false);
	new iNumCommands = ReadPackCell(hDataPack);
	while (iNumCommands-- > 0)
	{
		decl String:strCmd[256], String:strBuffer[8];
		ReadPackString(hDataPack, strCmd, sizeof(strCmd));
		ReplaceString(strCmd, sizeof(strCmd), "@name", g_strRocketClassLongName[iClass]);
		Format(strBuffer, sizeof(strBuffer), "%i", iRocket);		 ReplaceString(strCmd, sizeof(strCmd), "@rocket", strBuffer);
		Format(strBuffer, sizeof(strBuffer), "%i", iOwner);		  ReplaceString(strCmd, sizeof(strCmd), "@owner", strBuffer);
		Format(strBuffer, sizeof(strBuffer), "%i", iTarget);		 ReplaceString(strCmd, sizeof(strCmd), "@target", strBuffer);
		Format(strBuffer, sizeof(strBuffer), "%i", iLastDead);	   ReplaceString(strCmd, sizeof(strCmd), "@dead", strBuffer);
		Format(strBuffer, sizeof(strBuffer), "%f", fSpeed);		  ReplaceString(strCmd, sizeof(strCmd), "@speed", strBuffer);
		Format(strBuffer, sizeof(strBuffer), "%i", iNumDeflections); ReplaceString(strCmd, sizeof(strCmd), "@deflections", strBuffer);
		ServerCommand(strCmd);
	}
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**	______			_____
**   / ____/___  ____  / __(_)___ _
**  / /   / __ \/ __ \/ /_/ / __ `/
** / /___/ /_/ / / / / __/ / /_/ /
** \____/\____/_/ /_/_/ /_/\__, /
**						/____/
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* ParseConfiguration()
**
** Parses a Dodgeball configuration file. It doesn't clear any of the previous
** data, so multiple files can be parsed.
** -------------------------------------------------------------------------- */
bool:ParseConfigurations(String:strConfigFile[] = "general.cfg")
{
	// Parse configuration
	decl String:strPath[PLATFORM_MAX_PATH];
	decl String:strFileName[PLATFORM_MAX_PATH];
	Format(strFileName, sizeof(strFileName), "configs/dodgeball/%s", strConfigFile);
	BuildPath(Path_SM, strPath, sizeof(strPath), strFileName);

	// Try to parse if it exists
	LogMessage("Executing configuration file %s", strPath);
	if (FileExists(strPath, true))
	{
		new Handle:kvConfig = CreateKeyValues("TF2_Dodgeball");
		if (FileToKeyValues(kvConfig, strPath) == false) SetFailState("Error while parsing the configuration file.");
		KvGotoFirstSubKey(kvConfig);

		// Parse the subsections
		do
		{
			decl String:strSection[64]; KvGetSectionName(kvConfig, strSection, sizeof(strSection));

			if (StrEqual(strSection, "general"))	   ParseGeneral(kvConfig);
			else if (StrEqual(strSection, "classes"))  ParseClasses(kvConfig);
			else if (StrEqual(strSection, "spawners")) ParseSpawners(kvConfig);
		}
		while (KvGotoNextKey(kvConfig));

		CloseHandle(kvConfig);
	}
}

/* ParseGeneral()
**
** Parses general settings, such as the music, urls, etc.
** -------------------------------------------------------------------------- */
ParseGeneral(Handle:kvConfig)
{
	g_bMusicEnabled = bool:KvGetNum(kvConfig, "music", 0);
	if (g_bMusicEnabled == true)
	{
		g_bUseWebPlayer = bool:KvGetNum(kvConfig, "use web player", 0);
		KvGetString(kvConfig, "web player url",   g_strWebPlayerUrl, sizeof(g_strWebPlayerUrl));

		g_bMusic[Music_RoundStart] = KvGetString(kvConfig, "round start",	  g_strMusic[Music_RoundStart], PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundStart]);
		g_bMusic[Music_RoundWin]   = KvGetString(kvConfig, "round end (win)",  g_strMusic[Music_RoundWin],   PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundWin]);
		g_bMusic[Music_RoundLose]  = KvGetString(kvConfig, "round end (lose)", g_strMusic[Music_RoundLose],  PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundLose]);
		g_bMusic[Music_Gameplay]   = KvGetString(kvConfig, "gameplay",		 g_strMusic[Music_Gameplay],   PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_Gameplay]);
	}
}

/* ParseClasses()
**
** Parses the rocket classes data from the given configuration file.
** -------------------------------------------------------------------------- */
ParseClasses(Handle:kvConfig)
{
	decl String:strName[64];
	decl String:strBuffer[256];

	KvGotoFirstSubKey(kvConfig);
	do
	{
		new iIndex = g_iRocketClassCount;
		new RocketFlags:iFlags;

		// Basic parameters
		KvGetSectionName(kvConfig, strName, sizeof(strName));		 strcopy(g_strRocketClassName[iIndex], 16, strName);
		KvGetString(kvConfig, "name", strBuffer, sizeof(strBuffer));  strcopy(g_strRocketClassLongName[iIndex], 32, strBuffer);
		if (KvGetString(kvConfig, "model", strBuffer, sizeof(strBuffer)))
		{
			strcopy(g_strRocketClassModel[iIndex], PLATFORM_MAX_PATH, strBuffer);
			if (strlen(g_strRocketClassModel[iIndex]) != 0)
			{
				iFlags |= RocketFlag_CustomModel;
				if (KvGetNum(kvConfig, "is animated", 0)) iFlags |= RocketFlag_IsAnimated;
			}
		}

		KvGetString(kvConfig, "behaviour", strBuffer, sizeof(strBuffer), "homing");
		if (StrEqual(strBuffer, "homing")) g_iRocketClassBehaviour[iIndex] = Behaviour_Homing;
		else							   g_iRocketClassBehaviour[iIndex] = Behaviour_Unknown;

		if (KvGetNum(kvConfig, "play spawn sound", 0) == 1)
		{
			iFlags |= RocketFlag_PlaySpawnSound;
			if (KvGetString(kvConfig, "spawn sound", g_strRocketClassSpawnSound[iIndex], PLATFORM_MAX_PATH) && (strlen(g_strRocketClassSpawnSound[iIndex]) != 0))
			{
				iFlags |= RocketFlag_CustomSpawnSound;
			}
		}

		if (KvGetNum(kvConfig, "play beep sound", 0) == 1)
		{
			iFlags |= RocketFlag_PlayBeepSound;
			g_fRocketClassBeepInterval[iIndex] = KvGetFloat(kvConfig, "beep interval", 0.5);
			if (KvGetString(kvConfig, "beep sound", g_strRocketClassBeepSound[iIndex], PLATFORM_MAX_PATH) && (strlen(g_strRocketClassBeepSound[iIndex]) != 0))
			{
				iFlags |= RocketFlag_CustomBeepSound;
			}
		}

		if (KvGetNum(kvConfig, "play alert sound", 0) == 1)
		{
			iFlags |= RocketFlag_PlayAlertSound;
			if (KvGetString(kvConfig, "alert sound", g_strRocketClassAlertSound[iIndex], PLATFORM_MAX_PATH) && strlen(g_strRocketClassAlertSound[iIndex]) != 0)
			{
				iFlags |= RocketFlag_CustomAlertSound;
			}
		}

		// Behaviour modifiers
		if (KvGetNum(kvConfig, "elevate on deflect", 1) == 1) iFlags |= RocketFlag_ElevateOnDeflect;
		if (KvGetNum(kvConfig, "neutral rocket", 0) == 1)	 iFlags |= RocketFlag_IsNeutral;

		// Movement parameters
		g_fRocketClassDamage[iIndex]			= KvGetFloat(kvConfig, "damage");
		g_fRocketClassDamageIncrement[iIndex]   = KvGetFloat(kvConfig, "damage increment");
		g_fRocketClassCritChance[iIndex]		= KvGetFloat(kvConfig, "critical chance");
		g_fRocketClassSpeed[iIndex]			 = KvGetFloat(kvConfig, "speed");
		g_fRocketClassSpeedIncrement[iIndex]	= KvGetFloat(kvConfig, "speed increment");
		g_fRocketClassTurnRate[iIndex]		  = KvGetFloat(kvConfig, "turn rate");
		g_fRocketClassTurnRateIncrement[iIndex] = KvGetFloat(kvConfig, "turn rate increment");
		g_fRocketClassElevationRate[iIndex]	 = KvGetFloat(kvConfig, "elevation rate");
		g_fRocketClassElevationLimit[iIndex]	= KvGetFloat(kvConfig, "elevation limit");
		g_fRocketClassControlDelay[iIndex]	  = KvGetFloat(kvConfig, "control delay");
		g_fRocketClassPlayerModifier[iIndex]	= KvGetFloat(kvConfig, "no. players modifier");
		g_fRocketClassRocketsModifier[iIndex]   = KvGetFloat(kvConfig, "no. rockets modifier");
		g_fRocketClassTargetWeight[iIndex]	  = KvGetFloat(kvConfig, "direction to target weight");

		// Events
		new Handle:hCmds = INVALID_HANDLE;
		KvGetString(kvConfig, "on spawn", strBuffer, sizeof(strBuffer));
		if ((hCmds = ParseCommands(strBuffer)) != INVALID_HANDLE) { iFlags |= RocketFlag_OnSpawnCmd; g_hRocketClassCmdsOnSpawn[iIndex] = hCmds; }
		KvGetString(kvConfig, "on deflect", strBuffer, sizeof(strBuffer));
		if ((hCmds = ParseCommands(strBuffer)) != INVALID_HANDLE) { iFlags |= RocketFlag_OnDeflectCmd; g_hRocketClassCmdsOnDeflect[iIndex] = hCmds; }
		KvGetString(kvConfig, "on kill", strBuffer, sizeof(strBuffer));
		if ((hCmds = ParseCommands(strBuffer)) != INVALID_HANDLE) { iFlags |= RocketFlag_OnKillCmd; g_hRocketClassCmdsOnKill[iIndex] = hCmds; }
		KvGetString(kvConfig, "on explode", strBuffer, sizeof(strBuffer));
		if ((hCmds = ParseCommands(strBuffer)) != INVALID_HANDLE) { iFlags |= RocketFlag_OnExplodeCmd; g_hRocketClassCmdsOnExplode[iIndex] = hCmds; }

		// Done
		SetTrieValue(g_hRocketClassTrie, strName, iIndex);
		g_iRocketClassFlags[iIndex] = iFlags;
		g_iRocketClassCount++;
	}
	while (KvGotoNextKey(kvConfig));
	KvGoBack(kvConfig);
}

/* ParseSpawners()
**
** Parses the spawn points classes data from the given configuration file.
** -------------------------------------------------------------------------- */
ParseSpawners(Handle:kvConfig)
{
	decl String:strBuffer[256];
	KvGotoFirstSubKey(kvConfig);

	do
	{
		new iIndex = g_iSpawnersCount;

		// Basic parameters
		KvGetSectionName(kvConfig, strBuffer, sizeof(strBuffer)); strcopy(g_strSpawnersName[iIndex], 32, strBuffer);
		g_iSpawnersMaxRockets[iIndex] = KvGetNum(kvConfig, "max rockets", 1);
		g_fSpawnersInterval[iIndex]   = KvGetFloat(kvConfig, "interval", 1.0);

		// Chances table
		g_hSpawnersChancesTable[iIndex] = CreateArray();
		for (new iClassIndex = 0; iClassIndex < g_iRocketClassCount; iClassIndex++)
		{
			Format(strBuffer, sizeof(strBuffer), "%s%%", g_strRocketClassName[iClassIndex]);
			PushArrayCell(g_hSpawnersChancesTable[iIndex], KvGetNum(kvConfig, strBuffer, 0));
		}

		// Done.
		SetTrieValue(g_hSpawnersTrie, g_strSpawnersName[iIndex], iIndex);
		g_iSpawnersCount++;
	}
	while (KvGotoNextKey(kvConfig));
	KvGoBack(kvConfig);

	GetTrieValue(g_hSpawnersTrie, "red", g_iDefaultRedSpawner);
	GetTrieValue(g_hSpawnersTrie, "blu", g_iDefaultBluSpawner);
}

/* ParseCommands()
**
** Part of the event system, parses the given command strings and packs them
** to a Datapack.
** -------------------------------------------------------------------------- */
Handle:ParseCommands(String:strLine[])
{
	TrimString(strLine);
	if (strlen(strLine) == 0)
	{
		return INVALID_HANDLE;
	}
	else
	{
		new String:strStrings[8][255];
		new iNumStrings = ExplodeString(strLine, ";", strStrings, 8, 255);

		new Handle:hDataPack = CreateDataPack();
		WritePackCell(hDataPack, iNumStrings);
		for (new i = 0; i < iNumStrings; i++)
		{
			WritePackString(hDataPack, strStrings[i]);
		}

		return hDataPack;
	}
}

/*
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
**   ______			__
**  /_  __/___  ____  / /____
**   / / / __ \/ __ \/ / ___/
**  / / / /_/ / /_/ / (__  )
** /_/  \____/\____/_/____/
**
**••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••••
*/

/* ApplyDamage()
**
** Applies a damage to a player.
** -------------------------------------------------------------------------- */
public Action:ApplyDamage(Handle:hTimer, any:hDataPack)
{
	ResetPack(hDataPack, false);
	new iClient = ReadPackCell(hDataPack);
	new iDamage = ReadPackCell(hDataPack);
	CloseHandle(hDataPack);
	SlapPlayer(iClient, iDamage, true);
}

/* CopyVectors()
**
** Copies the contents from a vector to another.
** -------------------------------------------------------------------------- */
stock CopyVectors(Float:fFrom[3], Float:fTo[3])
{
	fTo[0] = fFrom[0];
	fTo[1] = fFrom[1];
	fTo[2] = fFrom[2];
}

/* LerpVectors()
**
** Calculates the linear interpolation of the two given vectors and stores
** it on the third one.
** -------------------------------------------------------------------------- */
stock LerpVectors(Float:fA[3], Float:fB[3], Float:fC[3], Float:t)
{
	if (t < 0.0) t = 0.0;
	if (t > 1.0) t = 1.0;

	fC[0] = fA[0] + (fB[0] - fA[0]) * t;
	fC[1] = fA[1] + (fB[1] - fA[1]) * t;
	fC[2] = fA[2] + (fB[2] - fA[2]) * t;
}

/* IsValidClient()
**
** Checks if the given client index is valid, and if it's alive or not.
** -------------------------------------------------------------------------- */
stock bool:IsValidClient(iClient, bool:bAlive = false)
{
	if (iClient >= 1 &&
	iClient <= MaxClients &&
	IsClientConnected(iClient) &&
	IsClientInGame(iClient) &&
	(bAlive == false || IsPlayerAlive(iClient)))
	{
		return true;
	}

	return false;
}

/* BothTeamsPlaying()
**
** Checks if there are players on both teams.
** -------------------------------------------------------------------------- */
stock bool:BothTeamsPlaying()
{
	new bool:bRedFound, bool:bBluFound;
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsValidClient(iClient, true) == false) continue;
		new iTeam = GetClientTeam(iClient);
		if (iTeam == _:TFTeam_Red) bRedFound = true;
		if (iTeam == _:TFTeam_Blue) bBluFound = true;
	}
	return bRedFound && bBluFound;
}

/* CountAlivePlayers()
**
** Retrieves the number of players alive.
** -------------------------------------------------------------------------- */
stock CountAlivePlayers()
{
	new iCount = 0;
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsValidClient(iClient, true)) iCount++;
	}
	return iCount;
}

/* SelectTarget()
**
** Determines a random target of the given team for the homing rocket.
** -------------------------------------------------------------------------- */
stock SelectTarget(iTeam, iRocket = -1)
{
	new iTarget			 = -1;
	new Float:fTargetWeight = 0.0;
	decl Float:fRocketPosition[3];
	decl Float:fRocketDirection[3];
	decl Float:fWeight;
	new bool:bUseRocket;

	if (iRocket != -1)
	{
		new iClass = g_iRocketClass[iRocket];
		new iEntity = EntRefToEntIndex(g_iRocketEntity[iRocket]);

		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
		CopyVectors(g_fRocketDirection[iRocket], fRocketDirection);
		fWeight = g_fRocketClassTargetWeight[iClass];

		bUseRocket = true;
	}

	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		// If the client isn't connected, skip.
		if (!IsValidClient(iClient, true)) continue;
		if (iTeam && GetClientTeam(iClient) != iTeam) continue;

		// Determine if this client should be the target.
		new Float:fNewWeight = GetURandomFloatRange(0.0, 100.0);

		if (bUseRocket == true)
		{
			decl Float:fClientPosition[3]; GetClientEyePosition(iClient, fClientPosition);
			decl Float:fDirectionToClient[3]; MakeVectorFromPoints(fRocketPosition, fClientPosition, fDirectionToClient);
			fNewWeight += GetVectorDotProduct(fRocketDirection, fDirectionToClient) * fWeight;
		}

		if ((iTarget == -1) || fNewWeight >= fTargetWeight)
		{
			iTarget = iClient;
			fTargetWeight = fNewWeight;
		}
	}

	return iTarget;
}

/* StopSoundToAll()
**
** Stops a sound for all the clients on the given channel.
** -------------------------------------------------------------------------- */
stock StopSoundToAll(iChannel, const String:strSound[])
{
	for (new iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsValidClient(iClient)) StopSound(iClient, iChannel, strSound);
	}
}

/* PlayParticle()
**
** Plays a particle system at the given location & angles.
** -------------------------------------------------------------------------- */
stock PlayParticle(Float:fPosition[3], Float:fAngles[3], String:strParticleName[], Float:fEffectTime = 5.0, Float:fLifeTime = 9.0)
{
	new iEntity = CreateEntityByName("info_particle_system");
	if (iEntity && IsValidEdict(iEntity))
	{
		TeleportEntity(iEntity, fPosition, fAngles, NULL_VECTOR);
		DispatchKeyValue(iEntity, "effect_name", strParticleName);
		ActivateEntity(iEntity);
		AcceptEntityInput(iEntity, "Start");
		CreateTimer(fEffectTime, StopParticle, EntIndexToEntRef(iEntity));
		CreateTimer(fLifeTime, KillParticle, EntIndexToEntRef(iEntity));
	}
	else
	{
		LogError("ShowParticle: could not create info_particle_system");
	}
}

/* StopParticle()
**
** Turns of the particle system. Automatically called by PlayParticle
** -------------------------------------------------------------------------- */
public Action:StopParticle(Handle:hTimer, any:iEntityRef)
{
	if (iEntityRef != INVALID_ENT_REFERENCE)
	{
		new iEntity = EntRefToEntIndex(iEntityRef);
		if (iEntity && IsValidEntity(iEntity))
		{
			AcceptEntityInput(iEntity, "Stop");
		}
	}
}

/* KillParticle()
**
** Destroys the particle system. Automatically called by PlayParticle
** -------------------------------------------------------------------------- */
public Action:KillParticle(Handle:hTimer, any:iEntityRef)
{
	if (iEntityRef != INVALID_ENT_REFERENCE)
	{
		new iEntity = EntRefToEntIndex(iEntityRef);
		if (iEntity && IsValidEntity(iEntity))
		{
			RemoveEdict(iEntity);
		}
	}
}

/* PrecacheParticle()
**
** Forces the client to precache a particle system.
** -------------------------------------------------------------------------- */
stock PrecacheParticle(String:strParticleName[])
{
	PlayParticle(Float:{0.0, 0.0, 0.0}, Float:{0.0, 0.0, 0.0}, strParticleName, 0.1, 0.1);
}

/* FindEntityByClassnameSafe()
**
** Used to iterate through entity types, avoiding problems in cases where
** the entity may not exist anymore.
** -------------------------------------------------------------------------- */
stock FindEntityByClassnameSafe(iStart, const String:strClassname[])
{
	while (iStart > -1 && !IsValidEntity(iStart))
	{
		iStart--;
	}
	return FindEntityByClassname(iStart, strClassname);
}

/* GetAnalogueTeam()
**
** Gets the analogue team for this. In case of Red, it's Blue, and viceversa.
** -------------------------------------------------------------------------- */
stock GetAnalogueTeam(iTeam)
{
	if (iTeam == _:TFTeam_Red) return _:TFTeam_Blue;
	return _:TFTeam_Red;
}

/* ShowHiddenMOTDPanel()
**
** Shows a hidden MOTD panel, useful for streaming music.
** -------------------------------------------------------------------------- */
stock ShowHiddenMOTDPanel(iClient, String:strTitle[], String:strMsg[], String:strType[] = "2")
{
	new Handle:hPanel = CreateKeyValues("data");
	KvSetString(hPanel, "title", strTitle);
	KvSetString(hPanel, "type", strType);
	KvSetString(hPanel, "msg", strMsg);
	ShowVGUIPanel(iClient, "info", hPanel, false);
	CloseHandle(hPanel);
}

/* PrecacheSoundEx()
**
** Precaches a sound and adds it to the download table.
** -------------------------------------------------------------------------- */
stock PrecacheSoundEx(String:strFileName[], bool:bPreload=false, bool:bAddToDownloadTable=false)
{
	new String:strFinalPath[PLATFORM_MAX_PATH];
	Format(strFinalPath, sizeof(strFinalPath), "sound/%s", strFileName);
	PrecacheSound(strFileName, bPreload);
	if (bAddToDownloadTable == true) AddFileToDownloadsTable(strFinalPath);
}

/* PrecacheModelEx()
**
** Precaches a models and adds it to the download table.
** -------------------------------------------------------------------------- */
stock PrecacheModelEx(String:strFileName[], bool:bPreload=false, bool:bAddToDownloadTable=false)
{
	PrecacheModel(strFileName, bPreload);
	if (bAddToDownloadTable)
	{
		decl String:strDepFileName[PLATFORM_MAX_PATH];
		Format(strDepFileName, sizeof(strDepFileName), "%s.res", strFileName);

		if (FileExists(strDepFileName))
		{
			// Open stream, if possible
			new Handle:hStream = OpenFile(strDepFileName, "r");
			if (hStream == INVALID_HANDLE) { LogMessage("Error, can't read file containing model dependencies."); return; }

			while(!IsEndOfFile(hStream))
			{
				decl String:strBuffer[PLATFORM_MAX_PATH];
				ReadFileLine(hStream, strBuffer, sizeof(strBuffer));
				CleanString(strBuffer);

				// If file exists...
				if (FileExists(strBuffer, true))
				{
					// Precache depending on type, and add to download table
					if (StrContains(strBuffer, ".vmt", false) != -1)	  PrecacheDecal(strBuffer, true);
					else if (StrContains(strBuffer, ".mdl", false) != -1) PrecacheModel(strBuffer, true);
					else if (StrContains(strBuffer, ".pcf", false) != -1) PrecacheGeneric(strBuffer, true);
					AddFileToDownloadsTable(strBuffer);
				}
			}

			// Close file
			CloseHandle(hStream);
		}
	}
}

/* CleanString()
**
** Cleans the given string from any illegal character.
** -------------------------------------------------------------------------- */
stock CleanString(String:strBuffer[])
{
	// Cleanup any illegal characters
	new Length = strlen(strBuffer);
	for (new iPos=0; iPos<Length; iPos++)
	{
		switch(strBuffer[iPos])
		{
			case '\r': strBuffer[iPos] = ' ';
			case '\n': strBuffer[iPos] = ' ';
			case '\t': strBuffer[iPos] = ' ';
		}
	}

	// Trim string
	TrimString(strBuffer);
}

/* FMax()
**
** Returns the maximum of the two values given.
** -------------------------------------------------------------------------- */
stock Float:FMax(Float:a, Float:b)
{
	return (a > b)? a:b;
}

/* FMin()
**
** Returns the minimum of the two values given.
** -------------------------------------------------------------------------- */
stock Float:FMin(Float:a, Float:b)
{
	return (a < b)? a:b;
}

/* GetURandomIntRange()
**
**
** -------------------------------------------------------------------------- */
stock GetURandomIntRange(iMin, iMax)
{
	return iMin + (GetURandomInt() % (iMax - iMin + 1));
}

/* GetURandomFloatRange()
**
**
** -------------------------------------------------------------------------- */
stock Float:GetURandomFloatRange(Float:fMin, Float:fMax)
{
	return fMin + (GetURandomFloat() * (fMax - fMin));
}

// EOF