 // *********************************************************************************
// PREPROCESSOR
// *********************************************************************************
#pragma semicolon 1				  // Force strict semicolon mode.

// *********************************************************************************
// INCLUDES
// *********************************************************************************
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2>
#include <tf2_stocks>
#include <tf2attributes>
#include <morecolors>

#pragma newdecls required

// *********************************************************************************
// CONSTANTS
// *********************************************************************************
// ---- Plugin-related constants ---------------------------------------------------
#define PLUGIN_NAME				"[TF2] Yet Another Dodgeball Plugin"
#define PLUGIN_AUTHOR			"Damizean, Edited by BloodTiger"
#define PLUGIN_VERSION			"1.3"
#define PLUGIN_CONTACT			"elgigantedeyeso@gmail.com"

// ---- General settings -----------------------------------------------------------
#define FPS_LOGIC_RATE			20.0
#define FPS_LOGIC_INTERVAL		1.0 / FPS_LOGIC_RATE

// ---- Maximum structure sizes ----------------------------------------------------
#define MAX_ROCKETS				100
#define MAX_ROCKET_CLASSES		50
#define MAX_SPAWNER_CLASSES		50
#define MAX_SPAWN_POINTS		100

// ---- PyroVision Stuff -----------------------------------------------------------
#define PYROVISION_ATTRIBUTE "vision opt in flags"

#define USAGE "Usage: sm_ab [0/1]"
int abPrevention[MAXPLAYERS + 1];
int firstJoined[MAXPLAYERS + 1];

// ---- Asherkin's RocketBounce Stuff ----------------------------------------------
#define	MAX_EDICT_BITS	11
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)

int g_nBounces[MAX_EDICTS];

Handle g_hMaxBouncesConVar;
int g_config_iMaxBounces = 2;

// ---- Airblast -------------------------------------------------------------------
bool Airblast[MAXPLAYERS + 1] =  { true, ... };

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
	RocketFlag_None = 0, 
	RocketFlag_PlaySpawnSound = 1 << 0, 
	RocketFlag_PlayBeepSound = 1 << 1, 
	RocketFlag_PlayAlertSound = 1 << 2, 
	RocketFlag_ElevateOnDeflect = 1 << 3, 
	RocketFlag_IsNeutral = 1 << 4, 
	RocketFlag_Exploded = 1 << 5, 
	RocketFlag_OnSpawnCmd = 1 << 6, 
	RocketFlag_OnDeflectCmd = 1 << 7, 
	RocketFlag_OnKillCmd = 1 << 8, 
	RocketFlag_OnExplodeCmd = 1 << 9, 
	RocketFlag_CustomModel = 1 << 10, 
	RocketFlag_CustomSpawnSound = 1 << 11, 
	RocketFlag_CustomBeepSound = 1 << 12, 
	RocketFlag_CustomAlertSound = 1 << 13, 
	RocketFlag_Elevating = 1 << 14, 
	RocketFlag_IsAnimated = 1 << 15
};

enum RocketSound
{
	RocketSound_Spawn, 
	RocketSound_Beep, 
	RocketSound_Alert
};

enum SpawnerFlags
{
	SpawnerFlag_Team_Red = 1, 
	SpawnerFlag_Team_Blu = 2, 
	SpawnerFlag_Team_Both = 3
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
#define PARTICLE_NUKE_1_ANGLES			view_as<float> ({270.0, 0.0, 0.0})
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
Handle g_hCvarEnabled;
Handle g_hCvarEnableCfgFile;
Handle g_hCvarDisableCfgFile;
Handle g_hCvarSpeedo;
Handle g_hCvarAnnounce;
Handle g_hCvarAnnounceKill;
Handle g_hCvarPyroVisionEnabled = INVALID_HANDLE;
Handle g_hCvarAirBlastCommandEnabled;
Handle g_hCvarDeflectCountAnnounce;
Handle g_hCvarRedirectBeep;
Handle g_hCvarPreventTauntKillEnabled;
Handle g_hCvarStealPrevention;
Handle g_hCvarStealPreventionNumber;

// -----<<< Gameplay >>>-----
int g_stolen[MAXPLAYERS + 1];
bool g_bEnabled; // Is the plugin enabled?
bool g_bRoundStarted; // Has the round started?
int g_iRoundCount; // Current round count since map start
int g_iRocketsFired; // No. of rockets fired since round start
Handle g_hLogicTimer; // Logic timer
float g_fNextSpawnTime; // Time at wich the next rocket will be able to spawn
int g_iLastDeadTeam; // The team of the last dead client. If none, it's a random team.
int g_iLastDeadClient; // The last dead client. If none, it's a random client.
int g_iPlayerCount;
Handle g_hHud;
int g_iRocketSpeed;
Handle g_hTimerHud;

// -----<<< Configuration >>>-----
bool g_bMusicEnabled;
bool g_bMusic[view_as<int>(SizeOfMusicsArray)];
char g_strMusic[view_as<int>(SizeOfMusicsArray)][PLATFORM_MAX_PATH];
bool g_bUseWebPlayer;
char g_strWebPlayerUrl[256];

// -----<<< Structures >>>-----
// Rockets
bool g_bRocketIsValid[MAX_ROCKETS];
int g_iRocketEntity[MAX_ROCKETS];
int g_iRocketTarget[MAX_ROCKETS];
int g_iRocketSpawner[MAX_ROCKETS];
int g_iRocketClass[MAX_ROCKETS];
RocketFlags g_iRocketFlags[MAX_ROCKETS];
float g_fRocketSpeed[MAX_ROCKETS];
float g_fRocketDirection[MAX_ROCKETS][3];
int g_iRocketDeflections[MAX_ROCKETS];
float g_fRocketLastDeflectionTime[MAX_ROCKETS];
float g_fRocketLastBeepTime[MAX_ROCKETS];
int g_iLastCreatedRocket;
int g_iRocketCount;

// Classes
char g_strRocketClassName[MAX_ROCKET_CLASSES][16];
char g_strRocketClassLongName[MAX_ROCKET_CLASSES][32];
BehaviourTypes g_iRocketClassBehaviour[MAX_ROCKET_CLASSES];
char g_strRocketClassModel[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
RocketFlags g_iRocketClassFlags[MAX_ROCKET_CLASSES];
float g_fRocketClassBeepInterval[MAX_ROCKET_CLASSES];
char g_strRocketClassSpawnSound[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char g_strRocketClassBeepSound[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
char g_strRocketClassAlertSound[MAX_ROCKET_CLASSES][PLATFORM_MAX_PATH];
float g_fRocketClassCritChance[MAX_ROCKET_CLASSES];
float g_fRocketClassDamage[MAX_ROCKET_CLASSES];
float g_fRocketClassDamageIncrement[MAX_ROCKET_CLASSES];
float g_fRocketClassSpeed[MAX_ROCKET_CLASSES];
float g_fRocketClassSpeedIncrement[MAX_ROCKET_CLASSES];
float g_fRocketClassTurnRate[MAX_ROCKET_CLASSES];
float g_fRocketClassTurnRateIncrement[MAX_ROCKET_CLASSES];
float g_fRocketClassElevationRate[MAX_ROCKET_CLASSES];
float g_fRocketClassElevationLimit[MAX_ROCKET_CLASSES];
float g_fRocketClassRocketsModifier[MAX_ROCKET_CLASSES];
float g_fRocketClassPlayerModifier[MAX_ROCKET_CLASSES];
float g_fRocketClassControlDelay[MAX_ROCKET_CLASSES];
float g_fRocketClassTargetWeight[MAX_ROCKET_CLASSES];
Handle g_hRocketClassCmdsOnSpawn[MAX_ROCKET_CLASSES];
Handle g_hRocketClassCmdsOnDeflect[MAX_ROCKET_CLASSES];
Handle g_hRocketClassCmdsOnKill[MAX_ROCKET_CLASSES];
Handle g_hRocketClassCmdsOnExplode[MAX_ROCKET_CLASSES];
Handle g_hRocketClassTrie;
char g_iRocketClassCount;

// Spawner classes
char g_strSpawnersName[MAX_SPAWNER_CLASSES][32];
int g_iSpawnersMaxRockets[MAX_SPAWNER_CLASSES];
float g_fSpawnersInterval[MAX_SPAWNER_CLASSES];
Handle g_hSpawnersChancesTable[MAX_SPAWNER_CLASSES];
Handle g_hSpawnersTrie;
int g_iSpawnersCount;

// Array containing the spawn points for the Red team, and
// their associated spawner class.
int g_iCurrentRedSpawn;
int g_iSpawnPointsRedCount;
int g_iSpawnPointsRedClass[MAX_SPAWN_POINTS];
int g_iSpawnPointsRedEntity[MAX_SPAWN_POINTS];

// Array containing the spawn points for the Blu team, and
// their associated spawner class.
int g_iCurrentBluSpawn;
int g_iSpawnPointsBluCount;
int g_iSpawnPointsBluClass[MAX_SPAWN_POINTS];
int g_iSpawnPointsBluEntity[MAX_SPAWN_POINTS];

// The default spawner class.
int g_iDefaultRedSpawner;
int g_iDefaultBluSpawner;

//Observer
int g_observer;
int g_op_rocket;

// *********************************************************************************
// PLUGIN
// *********************************************************************************
public Plugin myinfo = 
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
public void OnPluginStart()
{
	char strModName[32]; GetGameFolderName(strModName, sizeof(strModName));
	if (!StrEqual(strModName, "tf"))SetFailState("This plugin is only for Team Fortress 2.");
	
	CreateConVar("tf_dodgeballupdated_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY | FCVAR_UNLOGGED | FCVAR_DONTRECORD | FCVAR_REPLICATED | FCVAR_NOTIFY);
	g_hCvarEnabled = CreateConVar("tf_dodgeball_enabled", "1", "Enable Dodgeball on TFDB maps?", _, true, 0.0, true, 1.0);
	g_hCvarEnableCfgFile = CreateConVar("tf_dodgeball_enablecfg", "sourcemod/dodgeball_enable.cfg", "Config file to execute when enabling the Dodgeball game mode.");
	g_hCvarDisableCfgFile = CreateConVar("tf_dodgeball_disablecfg", "sourcemod/dodgeball_disable.cfg", "Config file to execute when disabling the Dodgeball game mode.");
	g_hCvarSpeedo = CreateConVar("tf_dodgeball_speedo", "1", "Enable HUD speedometer");
	g_hCvarAnnounce = CreateConVar("tf_dodgeball_announce", "1", "Enable kill announces in chat");
	g_hCvarAnnounceKill = CreateConVar("tf_dodgeball_announcekill", "1", "Enable who killed who in chat");
	g_hCvarPyroVisionEnabled = CreateConVar("tf_dodgeball_pyrovision", "1", "Enable pyrovision for everyone");
	g_hMaxBouncesConVar = CreateConVar("tf_dodgeball_rbmax", "2", "Max number of times a rocket will bounce.", FCVAR_NONE, true, 0.0, false);
	g_hCvarAirBlastCommandEnabled = CreateConVar("tf_dodgeball_airblast", "1", "Enable if airblast is enabled or not");
	g_hCvarDeflectCountAnnounce = CreateConVar("tf_dodgeball_count_deflect", "1", "Enable number of deflections in kill announce");
	g_hCvarRedirectBeep = CreateConVar("tf_dodgeball_rdrbeep", "1", "Do redirects beep?");
	g_hCvarPreventTauntKillEnabled = CreateConVar("tf_dodgeball_block_tauntkill", "1", "Block taunt kills?");
	g_hCvarStealPrevention = CreateConVar("tf_dodgeball_steal_prevention", "1", "Enable steal prevention?");
	g_hCvarStealPreventionNumber = CreateConVar("tf_dodgeball_sp_number", "3", "How many steals before you get slayed?");
	
	// Commands
	RegConsoleCmd("sm_ab", Command_ToggleAirblast, USAGE);
	
	ServerCommand("tf_arena_use_queue 0");
	
	HookConVarChange(g_hMaxBouncesConVar, tf2dodgeball_hooks);
	HookConVarChange(g_hCvarPyroVisionEnabled, tf2dodgeball_hooks);
	
	g_hRocketClassTrie = CreateTrie();
	g_hSpawnersTrie = CreateTrie();
	
	g_hHud = CreateHudSynchronizer();
	
	AutoExecConfig(true, "tf2_dodgeball");
	
	RegisterCommands();
}

/* OnConfigsExecuted()
**
** When all the configuration files have been executed, try to enable the
** Dodgeball.
** -------------------------------------------------------------------------- */
public void OnConfigsExecuted()
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
public void OnMapEnd()
{
	DisableDodgeBall();
}

/*
**����������������������������������������������������������������������������������
**	 __  ___												  __
**	/  |/  /___ _____  ____ _____ ____  ____ ___  ___  ____  / /_
**   / /|_/ / __ `/ __ \/ __ `/ __ `/ _ \/ __ `__ \/ _ \/ __ \/ __/
**  / /  / / /_/ / / / / /_/ / /_/ /  __/ / / / / /  __/ / / / /_
** /_/  /_/\__,_/_/ /_/\__,_/\__, /\___/_/ /_/ /_/\___/_/ /_/\__/
**						  /____/
**����������������������������������������������������������������������������������
*/

//   ___					   _
//  / __|___ _ _  ___ _ _ __ _| |
// | (_ / -_) ' \/ -_) '_/ _` | |
//  \___\___|_||_\___|_| \__,_|_|

/* IsDodgeBallMap()
**
** Checks if the current map is a dodgeball map.
** -------------------------------------------------------------------------- */
bool IsDodgeBallMap()
{
	char strMap[64];
	GetCurrentMap(strMap, sizeof(strMap));
	return StrContains(strMap, "tfdb_", false) == 0;
}

/* EnableDodgeBall()
**
** Enables and hooks all the required events.
** -------------------------------------------------------------------------- */
void EnableDodgeBall()
{
	if (g_bEnabled == false)
	{
		// Parse configuration files
		char strMapName[64]; GetCurrentMap(strMapName, sizeof(strMapName));
		char strMapFile[PLATFORM_MAX_PATH]; Format(strMapFile, sizeof(strMapFile), "%s.cfg", strMapName);
		ParseConfigurations();
		ParseConfigurations(strMapFile);
		
		// Check if we have all the required information
		if (g_iRocketClassCount == 0)SetFailState("No rocket class defined.");
		if (g_iSpawnersCount == 0)SetFailState("No spawner class defined.");
		if (g_iDefaultRedSpawner == -1)SetFailState("No spawner class definition for the Red spawners exists in the config file.");
		if (g_iDefaultBluSpawner == -1)SetFailState("No spawner class definition for the Blu spawners exists in the config file.");
		
		// Hook events and info_target outputs.
		HookEvent("object_deflected", Event_ObjectDeflected);
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
			if (g_bMusic[Music_RoundStart])PrecacheSoundEx(g_strMusic[Music_RoundStart], true, true);
			if (g_bMusic[Music_RoundWin])PrecacheSoundEx(g_strMusic[Music_RoundWin], true, true);
			if (g_bMusic[Music_RoundLose])PrecacheSoundEx(g_strMusic[Music_RoundLose], true, true);
			if (g_bMusic[Music_Gameplay])PrecacheSoundEx(g_strMusic[Music_Gameplay], true, true);
		}
		
		// Precache particles
		PrecacheParticle(PARTICLE_NUKE_1);
		PrecacheParticle(PARTICLE_NUKE_2);
		PrecacheParticle(PARTICLE_NUKE_3);
		PrecacheParticle(PARTICLE_NUKE_4);
		PrecacheParticle(PARTICLE_NUKE_5);
		PrecacheParticle(PARTICLE_NUKE_COLLUMN);
		
		// Precache rocket resources
		for (int i = 0; i < g_iRocketClassCount; i++)
		{
			RocketFlags iFlags = g_iRocketClassFlags[i];
			if (TestFlags(iFlags, RocketFlag_CustomModel))PrecacheModelEx(g_strRocketClassModel[i], true, true);
			if (TestFlags(iFlags, RocketFlag_CustomSpawnSound))PrecacheSoundEx(g_strRocketClassSpawnSound[i], true, true);
			if (TestFlags(iFlags, RocketFlag_CustomBeepSound))PrecacheSoundEx(g_strRocketClassBeepSound[i], true, true);
			if (TestFlags(iFlags, RocketFlag_CustomAlertSound))PrecacheSoundEx(g_strRocketClassAlertSound[i], true, true);
		}
		
		// Execute enable config file
		char strCfgFile[64]; GetConVarString(g_hCvarEnableCfgFile, strCfgFile, sizeof(strCfgFile));
		ServerCommand("exec \"%s\"", strCfgFile);
		
		// Done.
		g_bEnabled = true;
		g_bRoundStarted = false;
		g_iRoundCount = 0;
	}
}

/* DisableDodgeBall()
**
** Disables all hooks and frees arrays.
** -------------------------------------------------------------------------- */
void DisableDodgeBall()
{
	if (g_bEnabled == true)
	{
		// Clean up everything
		DestroyRockets();
		DestroyRocketClasses();
		DestroySpawners();
		if (g_hLogicTimer != INVALID_HANDLE)KillTimer(g_hLogicTimer);
		g_hLogicTimer = INVALID_HANDLE;
		
		// Disable music
		g_bMusic[Music_RoundStart] = 
		g_bMusic[Music_RoundWin] = 
		g_bMusic[Music_RoundLose] = 
		g_bMusic[Music_Gameplay] = false;
		
		// Unhook events and info_target outputs;
		UnhookEvent("teamplay_round_start", OnRoundStart, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_setup_finished", OnSetupFinished, EventHookMode_PostNoCopy);
		UnhookEvent("teamplay_round_win", OnRoundEnd, EventHookMode_PostNoCopy);
		UnhookEvent("player_spawn", OnPlayerSpawn, EventHookMode_Post);
		UnhookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
		UnhookEvent("post_inventory_application", OnPlayerInventory, EventHookMode_Post);
		UnhookEvent("teamplay_broadcast_audio", OnBroadcastAudio, EventHookMode_Pre);
		
		// Execute enable config file
		char strCfgFile[64]; GetConVarString(g_hCvarDisableCfgFile, strCfgFile, sizeof(strCfgFile));
		ServerCommand("exec \"%s\"", strCfgFile);
		
		// Done.
		g_bEnabled = false;
		g_bRoundStarted = false;
		g_iRoundCount = 0;
	}
}


public void OnClientPutInServer(int clientId)
{
	if (GetConVarBool(g_hCvarAirBlastCommandEnabled))
	{
		firstJoined[clientId] = true;
	}
	if (GetConVarBool(g_hCvarPreventTauntKillEnabled))
	{
		SDKHook(clientId, SDKHook_OnTakeDamage, TauntCheck);
	}
}


public void OnClientDisconnect(int client)
{
	if (GetConVarBool(g_hCvarPreventTauntKillEnabled))
	{
		SDKUnhook(client, SDKHook_OnTakeDamage, TauntCheck);
	}
}

/* OnObjectDeflected
**
**
** Check if client is human, don't airblast if bool is false
** -------------------------------------------------------------------------- */
public Action Event_ObjectDeflected(Handle event, const char[] name, bool dontBroadcast)
{
	if (GetConVarBool(g_hCvarAirBlastCommandEnabled))
	{
		int object1 = GetEventInt(event, "object_entindex");
		if ((object1 >= 1) && (object1 <= MaxClients))
		{
			if (Airblast[object1])
			{
				float Vel[3];
				TeleportEntity(object1, NULL_VECTOR, NULL_VECTOR, Vel); // Stops knockback
				TF2_RemoveCondition(object1, TFCond_Dazed); // Stops slowdown
				SetEntPropVector(object1, Prop_Send, "m_vecPunchAngle", Vel);
				SetEntPropVector(object1, Prop_Send, "m_vecPunchAngleVel", Vel); // Stops screen shake
			}
		}
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
public Action OnRoundStart(Handle hEvent, char[] strEventName, bool bDontBroadcast)
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
public Action OnSetupFinished(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if ((g_bEnabled == true) && (BothTeamsPlaying() == true))
	{
		PopulateSpawnPoints();
		
		if (g_iLastDeadTeam == 0)
		{
			g_iLastDeadTeam = GetURandomIntRange(view_as<int>(TFTeam_Red), view_as<int>(TFTeam_Blue));
		}
		if (!IsValidClient(g_iLastDeadClient))g_iLastDeadClient = 0;
		
		g_hLogicTimer = CreateTimer(FPS_LOGIC_INTERVAL, OnDodgeBallGameFrame, _, TIMER_REPEAT);
		g_iPlayerCount = CountAlivePlayers();
		g_iRocketsFired = 0;
		g_iCurrentRedSpawn = 0;
		g_iCurrentBluSpawn = 0;
		g_fNextSpawnTime = GetGameTime();
		g_bRoundStarted = true;
		g_iRoundCount++;
	}
}

/* OnRoundEnd()
**
** At round end, stop the Dodgeball game logic timer and destroy the remaining
** rockets.
** -------------------------------------------------------------------------- */
public Action OnRoundEnd(Handle hEvent, char[] strEventName, bool bDontBroadcast)
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
	
	if (GetConVarBool(g_hCvarAirBlastCommandEnabled))
	{
		for (int i = 0; i < MAXPLAYERS + 1; i++)
		{
			firstJoined[i] = false;
		}
	}
	if (g_bMusicEnabled == true)
	{
		if (g_bUseWebPlayer)
		{
			for (int iClient = 1; iClient <= MaxClients; iClient++)
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

public Action Command_ToggleAirblast(int clientId, int args)
{
	if (GetConVarBool(g_hCvarAirBlastCommandEnabled))
	{
		char arg[128];
		
		if (args > 1)
		{
			ReplyToCommand(clientId, "[SM] %s", USAGE);
			return Plugin_Handled;
		}
		
		if (args == 0)
		{
			preventAirblast(clientId, !abPrevention[clientId]);
		}
		else if (args == 1)
		{
			GetCmdArg(1, arg, sizeof(arg));
			
			if (strcmp(arg, "0") == 0)
			{
				preventAirblast(clientId, false);
			}
			else if (strcmp(arg, "1") == 0)
			{
				preventAirblast(clientId, true);
			}
			else
			{
				ReplyToCommand(clientId, "[SM] %s", USAGE);
				return Plugin_Handled;
			}
		}
		
		if (abPrevention[clientId])
		{
			ReplyToCommand(clientId, "[SM] %s", "Airblast Prevention Enabled");
		}
		else
		{
			ReplyToCommand(clientId, "[SM] %s", "Airblast Prevention Disabled");
		}
	}
	
	if (!GetConVarBool(g_hCvarAirBlastCommandEnabled))
	{
		ReplyToCommand(clientId, "[SM] %s", "Airblast Prevention is disabled on this server.");
		preventAirblast(clientId, false);
	}
	return Plugin_Handled;
}


/* OnPlayerSpawn()
**
** When the player spawns, force class to Pyro.
** -------------------------------------------------------------------------- */
public Action OnPlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int clientId = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	g_stolen[iClient] = 0;
	
	if (!IsValidClient(iClient))return;
	
	TFClassType iClass = TF2_GetPlayerClass(iClient);
	if (!(iClass == TFClass_Pyro || iClass == view_as<TFClassType>(TFClass_Unknown)))
	{
		TF2_SetPlayerClass(iClient, TFClass_Pyro, false, true);
		TF2_RespawnPlayer(iClient);
	}
	
	if (!GetConVarBool(g_hCvarPyroVisionEnabled))
	{
		return;
	}
	TF2Attrib_SetByName(iClient, PYROVISION_ATTRIBUTE, 1.0);
	
	if (GetConVarBool(g_hCvarAirBlastCommandEnabled))
	{
		if (firstJoined[clientId])
		{
			//Enable ab prevention when a player joins the server
			abPrevention[clientId] = true;
		}
		
		preventAirblast(clientId, true);
	}
}

/* OnPlayerDeath()
**
** When the player dies, set the last dead team to determine the next
** rocket's team.
** -------------------------------------------------------------------------- */
public Action OnPlayerDeath(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int killer = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if (g_bRoundStarted == false)
	{
		return;
	}
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int iVictim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if (GetConVarBool(g_hCvarAirBlastCommandEnabled))
	{
		int clientId = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		firstJoined[clientId] = false;
	}
	if (IsValidClient(iVictim))
	{
		g_iLastDeadClient = iVictim;
		g_iLastDeadTeam = GetClientTeam(iVictim);
		
		int iInflictor = GetEventInt(hEvent, "inflictor_entindex");
		int iIndex = FindRocketByEntity(iInflictor);
		
		if (iIndex != -1)
		{
			int iClass = g_iRocketClass[iIndex];
			int iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
			float fSpeed = g_fRocketSpeed[iIndex];
			int iDeflections = g_iRocketDeflections[iIndex];
			
			if (GetConVarBool(g_hCvarAnnounce))
			{
				if (GetConVarBool(g_hCvarDeflectCountAnnounce))
				{
					CPrintToChatAll("\x05%N\01 died to a rocket travelling \x05%i\x01 mph with \x05%i\x01 deflections!", g_iLastDeadClient, g_iRocketSpeed, iDeflections);
				}
				else
				{
					CPrintToChatAll("\x05%N\01 died to a rocket travelling \x05%i\x01 mph!", g_iLastDeadClient, g_iRocketSpeed);
				}
			}
			
			if (GetConVarBool(g_hCvarAnnounceKill))
			{
				if (killer == 1)
				{
					CPrintToChatAll("\x05%N\01 died to \x05%N\x01", g_iLastDeadClient, killer);
				}
			}
			
			if ((g_iRocketFlags[iIndex] & RocketFlag_OnExplodeCmd) && !(g_iRocketFlags[iIndex] & RocketFlag_Exploded))
			{
				ExecuteCommands(g_hRocketClassCmdsOnExplode[iClass], iClass, iInflictor, iAttacker, iTarget, g_iLastDeadClient, fSpeed, iDeflections);
				g_iRocketFlags[iIndex] |= RocketFlag_Exploded;
			}
			
			if (TestFlags(g_iRocketFlags[iIndex], RocketFlag_OnKillCmd))
				ExecuteCommands(g_hRocketClassCmdsOnKill[iClass], iClass, iInflictor, iAttacker, iTarget, g_iLastDeadClient, fSpeed, iDeflections);
		}
	}
	
	SetRandomSeed(view_as<int>(GetGameTime()));
}

/* OnPlayerInventory()
**
** Make sure the client only has the flamethrower equipped.
** -------------------------------------------------------------------------- */
public Action OnPlayerInventory(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient))return;
	
	for (int iSlot = 1; iSlot < 5; iSlot++)
	{
		int iEntity = GetPlayerWeaponSlot(iClient, iSlot);
		if (iEntity != -1)RemoveEdict(iEntity);
	}
}

/* OnPlayerRunCmd()
**
** Block flamethrower's Mouse1 attack.
** -------------------------------------------------------------------------- */
public Action OnPlayerRunCmd(int iClient, int &iButtons, int &iImpulse, float fVelocity[3], float fAngles[3], int &iWeapon)
{
	if (g_bEnabled == true)iButtons &= ~IN_ATTACK;
	return Plugin_Continue;
}

/* OnBroadcastAudio()
**
** Replaces the broadcasted audio for our custom music files.
** -------------------------------------------------------------------------- */
public Action OnBroadcastAudio(Handle hEvent, char[] strEventName, bool bDontBroadcast)
{
	if (g_bMusicEnabled == true)
	{
		char strSound[PLATFORM_MAX_PATH];
		GetEventString(hEvent, "sound", strSound, sizeof(strSound));
		int iTeam = GetEventInt(hEvent, "team");
		
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
				for (int iClient = 1; iClient <= MaxClients; iClient++)
				if (IsValidClient(iClient))
					ShowHiddenMOTDPanel(iClient, "MusicPlayerStart", g_strWebPlayerUrl);
				
				return Plugin_Handled;
			}
		}
		else if (StrEqual(strSound, "Game.YourTeamWon") == true)
		{
			if (g_bMusic[Music_RoundWin])
			{
				for (int iClient = 1; iClient <= MaxClients; iClient++)
				if (IsValidClient(iClient) && (iTeam == GetClientTeam(iClient)))
					EmitSoundToClient(iClient, g_strMusic[Music_RoundWin]);
				
				return Plugin_Handled;
			}
		}
		else if (StrEqual(strSound, "Game.YourTeamLost") == true)
		{
			if (g_bMusic[Music_RoundLose])
			{
				for (int iClient = 1; iClient <= MaxClients; iClient++)
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
public Action OnDodgeBallGameFrame(Handle hTimer, any Data)
{
	// Only if both teams are playing
	if (BothTeamsPlaying() == false)return;
	
	// Check if we need to fire more rockets.
	if (GetGameTime() >= g_fNextSpawnTime)
	{
		if (g_iLastDeadTeam == view_as<int>(TFTeam_Red))
		{
			int iSpawnerEntity = g_iSpawnPointsRedEntity[g_iCurrentRedSpawn];
			int iSpawnerClass = g_iSpawnPointsRedClass[g_iCurrentRedSpawn];
			if (g_iRocketCount < g_iSpawnersMaxRockets[iSpawnerClass])
			{
				CreateRocket(iSpawnerEntity, iSpawnerClass, view_as<int>(TFTeam_Red));
				g_iCurrentRedSpawn = (g_iCurrentRedSpawn + 1) % g_iSpawnPointsRedCount;
			}
		}
		else
		{
			int iSpawnerEntity = g_iSpawnPointsBluEntity[g_iCurrentBluSpawn];
			int iSpawnerClass = g_iSpawnPointsBluClass[g_iCurrentBluSpawn];
			if (g_iRocketCount < g_iSpawnersMaxRockets[iSpawnerClass])
			{
				CreateRocket(iSpawnerEntity, iSpawnerClass, view_as<int>(TFTeam_Blue));
				g_iCurrentBluSpawn = (g_iCurrentBluSpawn + 1) % g_iSpawnPointsBluCount;
			}
		}
	}
	
	// Manage the active rockets
	int iIndex = -1;
	while ((iIndex = FindNextValidRocket(iIndex)) != -1)
	{
		switch (g_iRocketClassBehaviour[g_iRocketClass[iIndex]])
		{
			case Behaviour_Unknown: {  }
			case Behaviour_Homing: { HomingRocketThink(iIndex); }
		}
	}
}

public Action Timer_HudSpeed(Handle hTimer)
{
	if (GetConVarBool(g_hCvarSpeedo))
	{
		SetHudTextParams(-1.0, 0.9, 1.1, 255, 255, 255, 255);
		for (int iClient = 1; iClient <= MaxClients; iClient++)
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
public void CreateRocket(int iSpawnerEntity, int iSpawnerClass, int iTeam)
{
	int iIndex = FindFreeRocketSlot();
	if (iIndex != -1)
	{
		// Fetch a random rocket class and it's parameters.
		int iClass = GetRandomRocketClass(iSpawnerClass);
		RocketFlags iFlags = g_iRocketClassFlags[iClass];
		
		// Create rocket entity.
		int iEntity = CreateEntityByName(TestFlags(iFlags, RocketFlag_IsAnimated) ? "tf_projectile_sentryrocket" : "tf_projectile_rocket");
		if (iEntity && IsValidEntity(iEntity))
		{
			// Fetch spawn point's location and angles.
			float fPosition[3];
			float fAngles[3];
			float fDirection[3];
			GetEntPropVector(iSpawnerEntity, Prop_Send, "m_vecOrigin", fPosition);
			GetEntPropVector(iSpawnerEntity, Prop_Send, "m_angRotation", fAngles);
			GetAngleVectors(fAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
			
			// Setup rocket entity.
			SetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity", 0);
			SetEntProp(iEntity, Prop_Send, "m_bCritical", (GetURandomFloatRange(0.0, 100.0) <= g_fRocketClassCritChance[iClass]) ? 1 : 0, 1);
			SetEntProp(iEntity, Prop_Send, "m_iTeamNum", iTeam, 1);
			SetEntProp(iEntity, Prop_Send, "m_iDeflected", 1);
			TeleportEntity(iEntity, fPosition, fAngles, view_as<float>( { 0.0, 0.0, 0.0 } ));
			
			// Setup rocket structure with the newly created entity.
			int iTargetTeam = (TestFlags(iFlags, RocketFlag_IsNeutral)) ? 0 : GetAnalogueTeam(iTeam);
			int iTarget = SelectTarget(iTargetTeam);
			float fModifier = CalculateModifier(iClass, 0);
			g_bRocketIsValid[iIndex] = true;
			g_iRocketFlags[iIndex] = iFlags;
			g_iRocketEntity[iIndex] = EntIndexToEntRef(iEntity);
			g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
			g_iRocketSpawner[iIndex] = iSpawnerClass;
			g_iRocketClass[iIndex] = iClass;
			g_iRocketDeflections[iIndex] = 0;
			g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
			g_fRocketLastBeepTime[iIndex] = GetGameTime();
			g_fRocketSpeed[iIndex] = CalculateRocketSpeed(iClass, fModifier);
			g_iRocketSpeed = RoundFloat(g_fRocketSpeed[iIndex] * 0.042614);
			
			CopyVectors(fDirection, g_fRocketDirection[iIndex]);
			SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
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
			
			
			//Observer
			if (IsValidEntity(g_observer))
			{
				g_op_rocket = iEntity;
				TeleportEntity(g_observer, fPosition, fAngles, view_as<float>( { 0.0, 0.0, 0.0 } ));
				SetVariantString("!activator");
				AcceptEntityInput(g_observer, "SetParent", g_op_rocket);
			}
		}
	}
}

public void OnEntityDestroyed(int entity)
{
	if (entity == -1)
	{
		return;
	}
	
	if (entity == g_op_rocket && g_bEnabled == true && IsValidEntity(g_observer) && IsValidEntity(g_op_rocket))
	{
		SetVariantString("");
		AcceptEntityInput(g_observer, "ClearParent");
		g_op_rocket = -1;
		
		float opPos[3];
		float opAng[3];
		
		int spawner = GetRandomInt(0, 1);
		if (spawner == 0)
			spawner = g_iSpawnPointsRedEntity[0];
		else
			spawner = g_iSpawnPointsBluEntity[0];
		
		if (IsValidEntity(spawner) && spawner > MAXPLAYERS)
		{
			GetEntPropVector(spawner, Prop_Data, "m_vecOrigin", opPos);
			GetEntPropVector(spawner, Prop_Data, "m_angAbsRotation", opAng);
			TeleportEntity(g_observer, opPos, opAng, NULL_VECTOR);
		}
	}
}

/* DestroyRocket()
**
** Destroys the rocket at the given index.
** -------------------------------------------------------------------------- */
void DestroyRocket(int iIndex)
{
	if (IsValidRocket(iIndex) == true)
	{
		int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
		if (iEntity && IsValidEntity(iEntity))RemoveEdict(iEntity);
		g_bRocketIsValid[iIndex] = false;
		g_iRocketCount--;
	}
}

/* DestroyRockets()
**
** Destroys all the rockets that are currently active.
** -------------------------------------------------------------------------- */
void DestroyRockets()
{
	for (int iIndex = 0; iIndex < MAX_ROCKETS; iIndex++)
	{
		DestroyRocket(iIndex);
	}
	g_iRocketCount = 0;
}

/* IsValidRocket()
**
** Checks if a rocket structure is valid.
** -------------------------------------------------------------------------- */
bool IsValidRocket(int iIndex)
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
int FindNextValidRocket(int iIndex, bool bWrap = false)
{
	for (int iCurrent = iIndex + 1; iCurrent < MAX_ROCKETS; iCurrent++)
	if (IsValidRocket(iCurrent))
		return iCurrent;
	
	return (bWrap == true) ? FindNextValidRocket(-1, false) : -1;
}

/* FindFreeRocketSlot()
**
** Retrieves the next free rocket slot since the current one. If all of them
** are full, returns -1.
** -------------------------------------------------------------------------- */
int FindFreeRocketSlot()
{
	int iIndex = g_iLastCreatedRocket;
	int iCurrent = iIndex;
	
	do
	{
		if (!IsValidRocket(iCurrent))return iCurrent;
		if ((++iCurrent) == MAX_ROCKETS)iCurrent = 0;
	} while (iCurrent != iIndex);
	
	return -1;
}

/* FindRocketByEntity()
**
** Finds a rocket index from it's entity.
** -------------------------------------------------------------------------- */
int FindRocketByEntity(int iEntity)
{
	int iIndex = -1;
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
void HomingRocketThink(int iIndex)
{
	// Retrieve the rocket's attributes.
	int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	int iClass = g_iRocketClass[iIndex];
	RocketFlags iFlags = g_iRocketFlags[iIndex];
	int iTarget = EntRefToEntIndex(g_iRocketTarget[iIndex]);
	int iTeam = GetEntProp(iEntity, Prop_Send, "m_iTeamNum", 1);
	int iTargetTeam = (TestFlags(iFlags, RocketFlag_IsNeutral)) ? 0 : GetAnalogueTeam(iTeam);
	int iDeflectionCount = GetEntProp(iEntity, Prop_Send, "m_iDeflected") - 1;
	float fModifier = CalculateModifier(iClass, iDeflectionCount);
	
	// Check if the target is available
	if (!IsValidClient(iTarget, true))
	{
		iTarget = SelectTarget(iTargetTeam);
		if (!IsValidClient(iTarget, true))return;
		g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
		
		if (GetConVarBool(g_hCvarRedirectBeep))
		{
			EmitRocketSound(RocketSound_Alert, iClass, iEntity, iTarget, iFlags);
		}
	}
	// Has the rocket been deflected recently? If so, set new target.
	else if ((iDeflectionCount > g_iRocketDeflections[iIndex]))
	{
		// Calculate new direction from the player's forward
		int iClient = GetEntPropEnt(iEntity, Prop_Send, "m_hOwnerEntity");
		if (IsValidClient(iClient))
		{
			float fViewAngles[3];
			float fDirection[3];
			GetClientEyeAngles(iClient, fViewAngles);
			GetAngleVectors(fViewAngles, fDirection, NULL_VECTOR, NULL_VECTOR);
			CopyVectors(fDirection, g_fRocketDirection[iIndex]);
			UpdateRocketSkin(iEntity, iTeam, TestFlags(iFlags, RocketFlag_IsNeutral));
			if (GetConVarBool(g_hCvarStealPrevention))
			{
				StolenRocket(iClient, iTarget);
			}
		}
		
		// Set new target & deflection count
		iTarget = SelectTarget(iTargetTeam, iIndex);
		g_iRocketTarget[iIndex] = EntIndexToEntRef(iTarget);
		g_iRocketDeflections[iIndex] = iDeflectionCount;
		g_fRocketLastDeflectionTime[iIndex] = GetGameTime();
		g_fRocketSpeed[iIndex] = CalculateRocketSpeed(iClass, fModifier);
		g_iRocketSpeed = RoundFloat(g_fRocketSpeed[iIndex] * 0.042614);
		
		SetEntDataFloat(iEntity, FindSendPropInfo("CTFProjectile_Rocket", "m_iDeflected") + 4, CalculateRocketDamage(iClass, fModifier), true);
		if (TestFlags(iFlags, RocketFlag_ElevateOnDeflect))g_iRocketFlags[iIndex] |= RocketFlag_Elevating;
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
			float fTurnRate = CalculateRocketTurnRate(iClass, fModifier);
			float fDirectionToTarget[3]; CalculateDirectionToClient(iEntity, iTarget, fDirectionToTarget);
			
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
float CalculateModifier(int iClass, int iDeflections)
{
	return iDeflections + 
	(g_iRocketsFired * g_fRocketClassRocketsModifier[iClass]) + 
	(g_iPlayerCount * g_fRocketClassPlayerModifier[iClass]);
}

/* CalculateRocketDamage()
**
** Calculates the damage of the rocket based on it's type and deflection count.
** -------------------------------------------------------------------------- */
float CalculateRocketDamage(int iClass, float fModifier)
{
	return g_fRocketClassDamage[iClass] + g_fRocketClassDamageIncrement[iClass] * fModifier;
}

/* CalculateRocketSpeed()
**
** Calculates the speed of the rocket based on it's type and deflection count.
** -------------------------------------------------------------------------- */
float CalculateRocketSpeed(int iClass, float fModifier)
{
	return g_fRocketClassSpeed[iClass] + g_fRocketClassSpeedIncrement[iClass] * fModifier;
}

/* CalculateRocketTurnRate()
**
** Calculates the rocket's turn rate based upon it's type and deflection count.
** -------------------------------------------------------------------------- */
float CalculateRocketTurnRate(int iClass, float fModifier)
{
	return g_fRocketClassTurnRate[iClass] + g_fRocketClassTurnRateIncrement[iClass] * fModifier;
}

/* CalculateDirectionToClient()
**
** As the name indicates, calculates the orientation for the rocket to move
** towards the specified client.
** -------------------------------------------------------------------------- */
void CalculateDirectionToClient(int iEntity, int iClient, float fOut[3])
{
	float fRocketPosition[3]; GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
	GetClientEyePosition(iClient, fOut);
	MakeVectorFromPoints(fRocketPosition, fOut, fOut);
	NormalizeVector(fOut, fOut);
}

/* ApplyRocketParameters()
**
** Transforms and applies the speed, direction and angles for the rocket
** entity.
** -------------------------------------------------------------------------- */
void ApplyRocketParameters(int iIndex)
{
	int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	float fAngles[3]; GetVectorAngles(g_fRocketDirection[iIndex], fAngles);
	float fVelocity[3]; CopyVectors(g_fRocketDirection[iIndex], fVelocity);
	ScaleVector(fVelocity, g_fRocketSpeed[iIndex]);
	SetEntPropVector(iEntity, Prop_Data, "m_vecAbsVelocity", fVelocity);
	SetEntPropVector(iEntity, Prop_Send, "m_angRotation", fAngles);
}

/* UpdateRocketSkin()
**
** Changes the skin of the rocket based on it's team.
** -------------------------------------------------------------------------- */
void UpdateRocketSkin(int iEntity, int iTeam, bool bNeutral)
{
	if (bNeutral == true)SetEntProp(iEntity, Prop_Send, "m_nSkin", 2);
	else SetEntProp(iEntity, Prop_Send, "m_nSkin", (iTeam == view_as<int>(TFTeam_Blue)) ? 0 : 1);
}

/* GetRandomRocketClass()
**
** Generates a random value and retrieves a rocket class based upon a chances table.
** -------------------------------------------------------------------------- */
int GetRandomRocketClass(int iSpawnerClass)
{
	int iRandom = GetURandomIntRange(0, 101);
	Handle hTable = g_hSpawnersChancesTable[iSpawnerClass];
	int iTableSize = GetArraySize(hTable);
	int iChancesLower = 0;
	int iChancesUpper = 0;
	
	for (int iEntry = 0; iEntry < iTableSize; iEntry++)
	{
		iChancesLower += iChancesUpper;
		iChancesUpper = iChancesLower + GetArrayCell(hTable, iEntry);
		
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
void EmitRocketSound(RocketSound iSound, int iClass, int iEntity, int iTarget, RocketFlags iFlags)
{
	switch (iSound)
	{
		case RocketSound_Spawn:
		{
			if (TestFlags(iFlags, RocketFlag_PlaySpawnSound))
			{
				if (TestFlags(iFlags, RocketFlag_CustomSpawnSound))EmitSoundToAll(g_strRocketClassSpawnSound[iClass], iEntity);
				else EmitSoundToAll(SOUND_DEFAULT_SPAWN, iEntity);
			}
		}
		case RocketSound_Beep:
		{
			if (TestFlags(iFlags, RocketFlag_PlayBeepSound))
			{
				if (TestFlags(iFlags, RocketFlag_CustomBeepSound))EmitSoundToAll(g_strRocketClassBeepSound[iClass], iEntity);
				else EmitSoundToAll(SOUND_DEFAULT_BEEP, iEntity);
			}
		}
		case RocketSound_Alert:
		{
			if (TestFlags(iFlags, RocketFlag_PlayAlertSound))
			{
				if (TestFlags(iFlags, RocketFlag_CustomAlertSound))EmitSoundToClient(iTarget, g_strRocketClassAlertSound[iClass]);
				else EmitSoundToClient(iTarget, SOUND_DEFAULT_ALERT, _, _, _, _, 0.5);
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
void DestroyRocketClasses()
{
	for (int iIndex = 0; iIndex < g_iRocketClassCount; iIndex++)
	{
		Handle hCmdOnSpawn = g_hRocketClassCmdsOnSpawn[iIndex];
		Handle hCmdOnKill = g_hRocketClassCmdsOnKill[iIndex];
		Handle hCmdOnExplode = g_hRocketClassCmdsOnExplode[iIndex];
		Handle hCmdOnDeflect = g_hRocketClassCmdsOnDeflect[iIndex];
		if (hCmdOnSpawn != INVALID_HANDLE)CloseHandle(hCmdOnSpawn);
		if (hCmdOnKill != INVALID_HANDLE)CloseHandle(hCmdOnKill);
		if (hCmdOnExplode != INVALID_HANDLE)CloseHandle(hCmdOnExplode);
		if (hCmdOnDeflect != INVALID_HANDLE)CloseHandle(hCmdOnDeflect);
		g_hRocketClassCmdsOnSpawn[iIndex] = INVALID_HANDLE;
		g_hRocketClassCmdsOnKill[iIndex] = INVALID_HANDLE;
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
void DestroySpawners()
{
	for (int iIndex = 0; iIndex < g_iSpawnersCount; iIndex++)
	{
		CloseHandle(g_hSpawnersChancesTable[iIndex]);
	}
	g_iSpawnersCount = 0;
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
void PopulateSpawnPoints()
{
	// Clear the current settings
	g_iSpawnPointsRedCount = 0;
	g_iSpawnPointsBluCount = 0;
	
	// Iterate through all the info target points and check 'em out.
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "info_target")) != -1)
	{
		char strName[32]; GetEntPropString(iEntity, Prop_Data, "m_iName", strName, sizeof(strName));
		if ((StrContains(strName, "rocket_spawn_red") != -1) || (StrContains(strName, "tf_dodgeball_red") != -1))
		{
			// Find most appropiate spawner class for this entity.
			int iIndex = FindSpawnerByName(strName);
			if (!IsValidRocket(iIndex))iIndex = g_iDefaultRedSpawner;
			
			// Upload to point list
			g_iSpawnPointsRedClass[g_iSpawnPointsRedCount] = iIndex;
			g_iSpawnPointsRedEntity[g_iSpawnPointsRedCount] = iEntity;
			g_iSpawnPointsRedCount++;
		}
		if ((StrContains(strName, "rocket_spawn_blue") != -1) || (StrContains(strName, "tf_dodgeball_blu") != -1))
		{
			// Find most appropiate spawner class for this entity.
			int iIndex = FindSpawnerByName(strName);
			if (!IsValidRocket(iIndex))iIndex = g_iDefaultBluSpawner;
			
			// Upload to point list
			g_iSpawnPointsBluClass[g_iSpawnPointsBluCount] = iIndex;
			g_iSpawnPointsBluEntity[g_iSpawnPointsBluCount] = iEntity;
			g_iSpawnPointsBluCount++;
		}
	}
	
	// Check if there exists spawn points
	if (g_iSpawnPointsRedCount == 0)SetFailState("No RED spawn points found on this map.");
	if (g_iSpawnPointsBluCount == 0)SetFailState("No BLU spawn points found on this map.");
	
	
	//ObserverPoint
	float opPos[3];
	float opAng[3];
	
	int spawner = GetRandomInt(0, 1);
	if (spawner == 0)
		spawner = g_iSpawnPointsRedEntity[0];
	else
		spawner = g_iSpawnPointsBluEntity[0];
	
	if (IsValidEntity(spawner) && spawner > MAXPLAYERS)
	{
		GetEntPropVector(spawner, Prop_Data, "m_vecOrigin", opPos);
		GetEntPropVector(spawner, Prop_Data, "m_angAbsRotation", opAng);
		g_observer = CreateEntityByName("info_observer_point");
		DispatchKeyValue(g_observer, "Angles", "90 0 0");
		DispatchKeyValue(g_observer, "TeamNum", "0");
		DispatchKeyValue(g_observer, "StartDisabled", "0");
		DispatchSpawn(g_observer);
		AcceptEntityInput(g_observer, "Enable");
		TeleportEntity(g_observer, opPos, opAng, NULL_VECTOR);
	}
	else
	{
		g_observer = -1;
	}
	
}

/* FindSpawnerByName()
**
** Finds the first spawner wich contains the given name.
** -------------------------------------------------------------------------- */
int FindSpawnerByName(char strName[32])
{
	int iIndex = -1;
	GetTrieValue(g_hSpawnersTrie, strName, iIndex);
	return iIndex;
}


/*
**����������������������������������������������������������������������������������
**	______										  __
**   / ____/___  ____ ___  ____ ___  ____ _____  ____/ /____
**  / /   / __ \/ __ `__ \/ __ `__ \/ __ `/ __ \/ __  / ___/
** / /___/ /_/ / / / / / / / / / / / /_/ / / / / /_/ (__  )
** \____/\____/_/ /_/ /_/_/ /_/ /_/\__,_/_/ /_/\__,_/____/
**
**����������������������������������������������������������������������������������
*/

/* RegisterCommands()
**
** Creates helper server commands to use with the plugin's events system.
** -------------------------------------------------------------------------- */
void RegisterCommands()
{
	RegServerCmd("tf_dodgeball_explosion", CmdExplosion);
	RegServerCmd("tf_dodgeball_shockwave", CmdShockwave);
	RegServerCmd("tf_dodgeball_resize", CmdResize);
}

public Action CmdResize(int iIndex)
{
	int iEntity = EntRefToEntIndex(g_iRocketEntity[iIndex]);
	if (iEntity && IsValidEntity(iEntity))
	{
		SetEntPropFloat(iEntity, Prop_Send, "m_flModelScale", (2.0));
	}
}

/* CmdExplosion()
**
** Creates a huge explosion at the location of the client.
** -------------------------------------------------------------------------- */
public Action CmdExplosion(int iArgs)
{
	if (iArgs == 1)
	{
		char strBuffer[8], iClient;
		GetCmdArg(1, strBuffer, sizeof(strBuffer));
		iClient = StringToInt(strBuffer);
		if (IsValidEntity(iClient))
		{
			float fPosition[3];
			GetClientAbsOrigin(iClient, fPosition);
			switch (GetURandomIntRange(0, 4))
			{
				case 0:
				{
					PlayParticle(fPosition, PARTICLE_NUKE_1_ANGLES, PARTICLE_NUKE_1);
				}
				case 1:
				{
					PlayParticle(fPosition, PARTICLE_NUKE_2_ANGLES, PARTICLE_NUKE_2);
				}
				case 2:
				{
					PlayParticle(fPosition, PARTICLE_NUKE_3_ANGLES, PARTICLE_NUKE_3);
				}
				case 3:
				{
					PlayParticle(fPosition, PARTICLE_NUKE_4_ANGLES, PARTICLE_NUKE_4);
				}
				case 4:
				{
					PlayParticle(fPosition, PARTICLE_NUKE_5_ANGLES, PARTICLE_NUKE_5);
				}
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
public Action CmdShockwave(int iArgs)
{
	if (iArgs == 5)
	{
		char strBuffer[8];
		int iClient;
		int iTeam;
		float fPosition[3];
		int iDamage;
		float fPushStrength;
		float fRadius;
		float fFalloffRadius;
		GetCmdArg(1, strBuffer, sizeof(strBuffer)); iClient = StringToInt(strBuffer);
		GetCmdArg(2, strBuffer, sizeof(strBuffer)); iDamage = StringToInt(strBuffer);
		GetCmdArg(3, strBuffer, sizeof(strBuffer)); fPushStrength = StringToFloat(strBuffer);
		GetCmdArg(4, strBuffer, sizeof(strBuffer)); fRadius = StringToFloat(strBuffer);
		GetCmdArg(5, strBuffer, sizeof(strBuffer)); fFalloffRadius = StringToFloat(strBuffer);
		
		if (IsValidClient(iClient))
		{
			iTeam = GetClientTeam(iClient);
			GetClientAbsOrigin(iClient, fPosition);
			
			for (iClient = 1; iClient <= MaxClients; iClient++)
			{
				if ((IsValidClient(iClient, true) == true) && (GetClientTeam(iClient) == iTeam))
				{
					float fPlayerPosition[3]; GetClientEyePosition(iClient, fPlayerPosition);
					float fDistanceToShockwave = GetVectorDistance(fPosition, fPlayerPosition);
					
					if (fDistanceToShockwave < fRadius)
					{
						float fImpulse[3];
						float fFinalPush;
						int iFinalDamage;
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
							float fImpact = (1.0 - ((fDistanceToShockwave - fFalloffRadius) / (fRadius - fFalloffRadius)));
							fFinalPush = fImpact * fPushStrength;
							iFinalDamage = RoundToFloor(fImpact * iDamage);
						}
						ScaleVector(fImpulse, fFinalPush);
						SetEntPropVector(iClient, Prop_Data, "m_vecAbsVelocity", fImpulse);
						
						Handle hDamage = CreateDataPack();
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
void ExecuteCommands(Handle hDataPack, int iClass, int iRocket, int iOwner, int iTarget, int iLastDead, float fSpeed, int iNumDeflections)
{
	ResetPack(hDataPack, false);
	int iNumCommands = ReadPackCell(hDataPack);
	while (iNumCommands-- > 0)
	{
		char strCmd[256];
		char strBuffer[8];
		ReadPackString(hDataPack, strCmd, sizeof(strCmd));
		ReplaceString(strCmd, sizeof(strCmd), "@name", g_strRocketClassLongName[iClass]);
		Format(strBuffer, sizeof(strBuffer), "%i", iRocket); ReplaceString(strCmd, sizeof(strCmd), "@rocket", strBuffer);
		Format(strBuffer, sizeof(strBuffer), "%i", iOwner); ReplaceString(strCmd, sizeof(strCmd), "@owner", strBuffer);
		Format(strBuffer, sizeof(strBuffer), "%i", iTarget); ReplaceString(strCmd, sizeof(strCmd), "@target", strBuffer);
		Format(strBuffer, sizeof(strBuffer), "%i", iLastDead); ReplaceString(strCmd, sizeof(strCmd), "@dead", strBuffer);
		Format(strBuffer, sizeof(strBuffer), "%f", fSpeed); ReplaceString(strCmd, sizeof(strCmd), "@speed", strBuffer);
		Format(strBuffer, sizeof(strBuffer), "%i", iNumDeflections); ReplaceString(strCmd, sizeof(strCmd), "@deflections", strBuffer);
		ServerCommand(strCmd);
	}
}

/*
**����������������������������������������������������������������������������������
**	______			_____
**   / ____/___  ____  / __(_)___ _
**  / /   / __ \/ __ \/ /_/ / __ `/
** / /___/ /_/ / / / / __/ / /_/ /
** \____/\____/_/ /_/_/ /_/\__, /
**						/____/
**����������������������������������������������������������������������������������
*/

/* ParseConfiguration()
**
** Parses a Dodgeball configuration file. It doesn't clear any of the previous
** data, so multiple files can be parsed.
** -------------------------------------------------------------------------- */
bool ParseConfigurations(char strConfigFile[] = "general.cfg")
{
	// Parse configuration
	char strPath[PLATFORM_MAX_PATH];
	char strFileName[PLATFORM_MAX_PATH];
	Format(strFileName, sizeof(strFileName), "configs/dodgeball/%s", strConfigFile);
	BuildPath(Path_SM, strPath, sizeof(strPath), strFileName);
	
	// Try to parse if it exists
	LogMessage("Executing configuration file %s", strPath);
	if (FileExists(strPath, true))
	{
		Handle kvConfig = CreateKeyValues("TF2_Dodgeball");
		if (FileToKeyValues(kvConfig, strPath) == false)SetFailState("Error while parsing the configuration file.");
		KvGotoFirstSubKey(kvConfig);
		
		// Parse the subsections
		do
		{
			char strSection[64]; KvGetSectionName(kvConfig, strSection, sizeof(strSection));
			
			if (StrEqual(strSection, "general"))ParseGeneral(kvConfig);
			else if (StrEqual(strSection, "classes"))ParseClasses(kvConfig);
			else if (StrEqual(strSection, "spawners"))ParseSpawners(kvConfig);
		}
		while (KvGotoNextKey(kvConfig));
		
		CloseHandle(kvConfig);
	}
}

/* ParseGeneral()
**
** Parses general settings, such as the music, urls, etc.
** -------------------------------------------------------------------------- */
void ParseGeneral(Handle kvConfig)
{
	g_bMusicEnabled = view_as<bool>(KvGetNum(kvConfig, "music", 0));
	if (g_bMusicEnabled == true)
	{
		g_bUseWebPlayer = view_as<bool>(KvGetNum(kvConfig, "use web player", 0));
		KvGetString(kvConfig, "web player url", g_strWebPlayerUrl, sizeof(g_strWebPlayerUrl));
		
		g_bMusic[Music_RoundStart] = KvGetString(kvConfig, "round start", g_strMusic[Music_RoundStart], PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundStart]);
		g_bMusic[Music_RoundWin] = KvGetString(kvConfig, "round end (win)", g_strMusic[Music_RoundWin], PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundWin]);
		g_bMusic[Music_RoundLose] = KvGetString(kvConfig, "round end (lose)", g_strMusic[Music_RoundLose], PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_RoundLose]);
		g_bMusic[Music_Gameplay] = KvGetString(kvConfig, "gameplay", g_strMusic[Music_Gameplay], PLATFORM_MAX_PATH) && strlen(g_strMusic[Music_Gameplay]);
	}
}

/* ParseClasses()
**
** Parses the rocket classes data from the given configuration file.
** -------------------------------------------------------------------------- */
void ParseClasses(Handle kvConfig)
{
	char strName[64];
	char strBuffer[256];
	
	KvGotoFirstSubKey(kvConfig);
	do
	{
		int iIndex = g_iRocketClassCount;
		RocketFlags iFlags;
		
		// Basic parameters
		KvGetSectionName(kvConfig, strName, sizeof(strName)); strcopy(g_strRocketClassName[iIndex], 16, strName);
		KvGetString(kvConfig, "name", strBuffer, sizeof(strBuffer)); strcopy(g_strRocketClassLongName[iIndex], 32, strBuffer);
		if (KvGetString(kvConfig, "model", strBuffer, sizeof(strBuffer)))
		{
			strcopy(g_strRocketClassModel[iIndex], PLATFORM_MAX_PATH, strBuffer);
			if (strlen(g_strRocketClassModel[iIndex]) != 0)
			{
				iFlags |= RocketFlag_CustomModel;
				if (KvGetNum(kvConfig, "is animated", 0))iFlags |= RocketFlag_IsAnimated;
			}
		}
		
		KvGetString(kvConfig, "behaviour", strBuffer, sizeof(strBuffer), "homing");
		if (StrEqual(strBuffer, "homing"))g_iRocketClassBehaviour[iIndex] = Behaviour_Homing;
		else g_iRocketClassBehaviour[iIndex] = Behaviour_Unknown;
		
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
		if (KvGetNum(kvConfig, "elevate on deflect", 1) == 1)iFlags |= RocketFlag_ElevateOnDeflect;
		if (KvGetNum(kvConfig, "neutral rocket", 0) == 1)iFlags |= RocketFlag_IsNeutral;
		
		// Movement parameters
		g_fRocketClassDamage[iIndex] = KvGetFloat(kvConfig, "damage");
		g_fRocketClassDamageIncrement[iIndex] = KvGetFloat(kvConfig, "damage increment");
		g_fRocketClassCritChance[iIndex] = KvGetFloat(kvConfig, "critical chance");
		g_fRocketClassSpeed[iIndex] = KvGetFloat(kvConfig, "speed");
		g_fRocketClassSpeedIncrement[iIndex] = KvGetFloat(kvConfig, "speed increment");
		g_fRocketClassTurnRate[iIndex] = KvGetFloat(kvConfig, "turn rate");
		g_fRocketClassTurnRateIncrement[iIndex] = KvGetFloat(kvConfig, "turn rate increment");
		g_fRocketClassElevationRate[iIndex] = KvGetFloat(kvConfig, "elevation rate");
		g_fRocketClassElevationLimit[iIndex] = KvGetFloat(kvConfig, "elevation limit");
		g_fRocketClassControlDelay[iIndex] = KvGetFloat(kvConfig, "control delay");
		g_fRocketClassPlayerModifier[iIndex] = KvGetFloat(kvConfig, "no. players modifier");
		g_fRocketClassRocketsModifier[iIndex] = KvGetFloat(kvConfig, "no. rockets modifier");
		g_fRocketClassTargetWeight[iIndex] = KvGetFloat(kvConfig, "direction to target weight");
		
		// Events
		Handle hCmds = INVALID_HANDLE;
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
void ParseSpawners(Handle kvConfig)
{
	char strBuffer[256];
	KvGotoFirstSubKey(kvConfig);
	
	do
	{
		int iIndex = g_iSpawnersCount;
		
		// Basic parameters
		KvGetSectionName(kvConfig, strBuffer, sizeof(strBuffer)); strcopy(g_strSpawnersName[iIndex], 32, strBuffer);
		g_iSpawnersMaxRockets[iIndex] = KvGetNum(kvConfig, "max rockets", 1);
		g_fSpawnersInterval[iIndex] = KvGetFloat(kvConfig, "interval", 1.0);
		
		// Chances table
		g_hSpawnersChancesTable[iIndex] = CreateArray();
		for (int iClassIndex = 0; iClassIndex < g_iRocketClassCount; iClassIndex++)
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
Handle ParseCommands(char[] strLine)
{
	TrimString(strLine);
	if (strlen(strLine) == 0)
	{
		return INVALID_HANDLE;
	}
	else
	{
		char strStrings[8][255];
		int iNumStrings = ExplodeString(strLine, ";", strStrings, 8, 255);
		
		Handle hDataPack = CreateDataPack();
		WritePackCell(hDataPack, iNumStrings);
		for (int i = 0; i < iNumStrings; i++)
		{
			WritePackString(hDataPack, strStrings[i]);
		}
		
		return hDataPack;
	}
}

/*
**����������������������������������������������������������������������������������
**   ______			__
**  /_  __/___  ____  / /____
**   / / / __ \/ __ \/ / ___/
**  / / / /_/ / /_/ / (__  )
** /_/  \____/\____/_/____/
**
**����������������������������������������������������������������������������������
*/

/* ApplyDamage()
**
** Applies a damage to a player.
** -------------------------------------------------------------------------- */
public Action ApplyDamage(Handle hTimer, any hDataPack)
{
	ResetPack(hDataPack, false);
	int iClient = ReadPackCell(hDataPack);
	int iDamage = ReadPackCell(hDataPack);
	CloseHandle(hDataPack);
	SlapPlayer(iClient, iDamage, true);
}

/* CopyVectors()
**
** Copies the contents from a vector to another.
** -------------------------------------------------------------------------- */
stock void CopyVectors(float fFrom[3], float fTo[3])
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
stock void LerpVectors(float fA[3], float fB[3], float fC[3], float t)
{
	if (t < 0.0)t = 0.0;
	if (t > 1.0)t = 1.0;
	
	fC[0] = fA[0] + (fB[0] - fA[0]) * t;
	fC[1] = fA[1] + (fB[1] - fA[1]) * t;
	fC[2] = fA[2] + (fB[2] - fA[2]) * t;
}

/* IsValidClient()
**
** Checks if the given client index is valid, and if it's alive or not.
** -------------------------------------------------------------------------- */
stock bool IsValidClient(int iClient, bool bAlive = false)
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
stock bool BothTeamsPlaying()
{
	bool bRedFound;
	bool bBluFound;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsValidClient(iClient, true) == false)continue;
		int iTeam = GetClientTeam(iClient);
		if (iTeam == view_as<int>(TFTeam_Red))bRedFound = true;
		if (iTeam == view_as<int>(TFTeam_Blue))bBluFound = true;
	}
	return bRedFound && bBluFound;
}

/* CountAlivePlayers()
**
** Retrieves the number of players alive.
** -------------------------------------------------------------------------- */
stock int CountAlivePlayers()
{
	int iCount = 0;
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsValidClient(iClient, true))iCount++;
	}
	return iCount;
}

/* SelectTarget()
**
** Determines a random target of the given team for the homing rocket.
** -------------------------------------------------------------------------- */
stock int SelectTarget(int iTeam, int iRocket = -1)
{
	int iTarget = -1;
	float fRocketPosition[3];
	float fRocketDirection[3];
	bool bUseRocket;
	float flBestLength = 99999.9;
	
	if (iRocket != -1)
	{
		int iEntity = EntRefToEntIndex(g_iRocketEntity[iRocket]);
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fRocketPosition);
		
	}
	
	for (int i = 1; i <= MaxClients; i++)
	{
		// If the client isn't connected, skip.
		if (!IsValidClient(i, true))continue;
		if (iTeam && GetClientTeam(i) != iTeam)continue;
		float flPos2[3];
		GetClientEyePosition(i, flPos2);
		
		float flDistance = GetVectorDistance(fRocketPosition, flPos2);
		
		//if(flDistance < 70.0) continue;
		
		if (flDistance < flBestLength)
		{
			iTarget = i;
			flBestLength = flDistance;
		}
		
	}
	return iTarget;
}

/* StopSoundToAll()
**
** Stops a sound for all the clients on the given channel.
** -------------------------------------------------------------------------- */
stock void StopSoundToAll(int iChannel, const char[] strSound)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsValidClient(iClient))StopSound(iClient, iChannel, strSound);
	}
}

/* PlayParticle()
**
** Plays a particle system at the given location & angles.
** -------------------------------------------------------------------------- */
stock void PlayParticle(float fPosition[3], float fAngles[3], char[] strParticleName, float fEffectTime = 5.0, float fLifeTime = 9.0)
{
	int iEntity = CreateEntityByName("info_particle_system");
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
public Action StopParticle(Handle hTimer, any iEntityRef)
{
	if (iEntityRef != INVALID_ENT_REFERENCE)
	{
		int iEntity = EntRefToEntIndex(iEntityRef);
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
public Action KillParticle(Handle hTimer, any iEntityRef)
{
	if (iEntityRef != INVALID_ENT_REFERENCE)
	{
		int iEntity = EntRefToEntIndex(iEntityRef);
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
stock void PrecacheParticle(char[] strParticleName)
{
	PlayParticle(view_as<float>( { 0.0, 0.0, 0.0 } ), view_as<float>( { 0.0, 0.0, 0.0 } ), strParticleName, 0.1, 0.1);
}

/* FindEntityByClassnameSafe()
**
** Used to iterate through entity types, avoiding problems in cases where
** the entity may not exist anymore.
** -------------------------------------------------------------------------- */
stock void FindEntityByClassnameSafe(int iStart, const char[] strClassname)
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
stock int GetAnalogueTeam(int iTeam)
{
	if (iTeam == view_as<int>(TFTeam_Red))return view_as<int>(TFTeam_Blue);
	return view_as<int>(TFTeam_Red);
}

/* ShowHiddenMOTDPanel()
**
** Shows a hidden MOTD panel, useful for streaming music.
** -------------------------------------------------------------------------- */
stock void ShowHiddenMOTDPanel(int iClient, char[] strTitle, char[] strMsg, char[] strType = "2")
{
	Handle hPanel = CreateKeyValues("data");
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
stock void PrecacheSoundEx(char[] strFileName, bool bPreload = false, bool bAddToDownloadTable = false)
{
	char strFinalPath[PLATFORM_MAX_PATH];
	Format(strFinalPath, sizeof(strFinalPath), "sound/%s", strFileName);
	PrecacheSound(strFileName, bPreload);
	if (bAddToDownloadTable == true)AddFileToDownloadsTable(strFinalPath);
}

/* PrecacheModelEx()
**
** Precaches a models and adds it to the download table.
** -------------------------------------------------------------------------- */
stock void PrecacheModelEx(char[] strFileName, bool bPreload = false, bool bAddToDownloadTable = false)
{
	PrecacheModel(strFileName, bPreload);
	if (bAddToDownloadTable)
	{
		char strDepFileName[PLATFORM_MAX_PATH];
		Format(strDepFileName, sizeof(strDepFileName), "%s.res", strFileName);
		
		if (FileExists(strDepFileName))
		{
			// Open stream, if possible
			Handle hStream = OpenFile(strDepFileName, "r");
			if (hStream == INVALID_HANDLE) { LogMessage("Error, can't read file containing model dependencies."); return; }
			
			while (!IsEndOfFile(hStream))
			{
				char strBuffer[PLATFORM_MAX_PATH];
				ReadFileLine(hStream, strBuffer, sizeof(strBuffer));
				CleanString(strBuffer);
				
				// If file exists...
				if (FileExists(strBuffer, true))
				{
					// Precache depending on type, and add to download table
					if (StrContains(strBuffer, ".vmt", false) != -1)PrecacheDecal(strBuffer, true);
					else if (StrContains(strBuffer, ".mdl", false) != -1)PrecacheModel(strBuffer, true);
					else if (StrContains(strBuffer, ".pcf", false) != -1)PrecacheGeneric(strBuffer, true);
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
stock void CleanString(char[] strBuffer)
{
	// Cleanup any illegal characters
	int Length = strlen(strBuffer);
	for (int iPos = 0; iPos < Length; iPos++)
	{
		switch (strBuffer[iPos])
		{
			case '\r':strBuffer[iPos] = ' ';
			case '\n':strBuffer[iPos] = ' ';
			case '\t':strBuffer[iPos] = ' ';
		}
	}
	
	// Trim string
	TrimString(strBuffer);
}

/* FMax()
**
** Returns the maximum of the two values given.
** -------------------------------------------------------------------------- */
stock float FMax(float a, float b)
{
	return (a > b) ? a:b;
}

/* FMin()
**
** Returns the minimum of the two values given.
** -------------------------------------------------------------------------- */
stock float FMin(float a, float b)
{
	return (a < b) ? a:b;
}

/* GetURandomIntRange()
**
**
** -------------------------------------------------------------------------- */
stock int GetURandomIntRange(const int iMin, const int iMax)
{
	return iMin + (GetURandomInt() % (iMax - iMin + 1));
}

/* GetURandomFloatRange()
**
**
** -------------------------------------------------------------------------- */
stock float GetURandomFloatRange(float fMin, float fMax)
{
	return fMin + (GetURandomFloat() * (fMax - fMin));
}

// Pyro vision
public void tf2dodgeball_hooks(Handle convar, const char[] oldValue, const char[] newValue)
{
	if (GetConVarBool(g_hCvarPyroVisionEnabled))
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i))
			{
				TF2Attrib_SetByName(i, PYROVISION_ATTRIBUTE, 1.0);
			}
		}
	}
	else
	{
		for (int i = 1; i <= MaxClients; ++i)
		{
			if (IsClientInGame(i))
			{
				TF2Attrib_RemoveByName(i, PYROVISION_ATTRIBUTE);
			}
		}
	}
	g_config_iMaxBounces = StringToInt(newValue);
}

// Asherkins RocketBounce

public void OnEntityCreated(int entity, const char[] classname)
{
	if (!StrEqual(classname, "tf_projectile_rocket", false))
		return;
	
	
	g_nBounces[entity] = 0;
	SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
}

public Action OnStartTouch(int entity, int other)
{
	if (other > 0 && other <= MaxClients)
		return Plugin_Continue;
	
	// Only allow a rocket to bounce x times.
	if (g_nBounces[entity] >= g_config_iMaxBounces)
		return Plugin_Continue;
	
	SDKHook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public Action OnTouch(int entity, int other)
{
	float vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	
	float vAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	
	float vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, entity);
	
	if (!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}
	
	float vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
	
	CloseHandle(trace);
	
	float dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	float vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	float vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
	//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));
	
	TeleportEntity(entity, NULL_VECTOR, vNewAngles, vBounceVec);
	
	g_nBounces[entity]++;
	
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public bool TEF_ExcludeEntity(int entity, int contentsMask, any data)
{
	return (entity != data);
}

void preventAirblast(int clientId, bool prevent)
{
	int flags;
	
	if (prevent == true)
	{
		abPrevention[clientId] = true;
		flags = GetEntityFlags(clientId) | FL_NOTARGET;
	}
	else
	{
		abPrevention[clientId] = false;
		flags = GetEntityFlags(clientId) & ~FL_NOTARGET;
	}
	
	SetEntityFlags(clientId, flags);
}

public Action TauntCheck(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3], int damagecustom)
{
	switch (damagecustom)
	{
		case TF_CUSTOM_TAUNT_ARMAGEDDON:
		{
			damage = 0.0;
			return Plugin_Changed;
		}
		
	}
	return Plugin_Continue;
}

void StolenRocket(int iClient, int iTarget)
{
	if (iTarget != iClient)
	{
		PrintToChatAll("\x03%N\x01 stole \x03%N\x01's rocket!", iClient, iTarget);
		g_stolen[iClient]++;
		if (g_stolen[iClient] >= GetConVarFloat(g_hCvarStealPreventionNumber))
		{
			g_stolen[iClient] = 0;
			ForcePlayerSuicide(iClient);
			PrintToChat(iClient, "\x03You stole %i rockets and got slayed", g_hCvarStealPreventionNumber);
		}
	}
}


// EOF
