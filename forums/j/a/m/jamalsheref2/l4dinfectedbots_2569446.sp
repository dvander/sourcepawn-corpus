/********************************************************************************************
* Plugin	: L4D/L4D2 InfectedBots Control
* Version	: 1.0.0
* Game		: Left 4 Dead 1 & 2
* Author	: djromero (SkyDavid, David) and MI 5
* Testers	: Myself, MI 5
* Website	: www.sky.zebgames.com
* 
* Purpose	: This plugin spawns infected bots in versus for L4D1 and gives greater control of the infected bots in L4D1/L4D2.
* *******************************************************************************************/

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

#define DEBUGSERVER 0
#define DEBUGCLIENTS 0
#define DEBUGTANK 0
#define DEBUGHUD 0
#define DEVELOPER 0

#define TEAM_SPECTATOR		1
#define TEAM_SURVIVORS 		2
#define TEAM_INFECTED 		3

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

// Variables
static InfectedRealCount; // Holds the amount of real infected players
static InfectedBotCount; // Holds the amount of infected bots in any gamemode
static InfectedBotQueue; // Holds the amount of bots that are going to spawn

static GameMode; // Holds the GameMode, 1 for coop and realism, 2 for versus, teamversus, scavenge and teamscavenge, 3 for survival

static BoomerLimit; // Sets the Boomer Limit, related to the boomer limit cvar
static SmokerLimit; // Sets the Smoker Limit, related to the smoker limit cvar
static HunterLimit; // Sets the Hunter Limit, related to the hunter limit cvar
static SpitterLimit; // Sets the Spitter Limit, related to the Spitter limit cvar
static JockeyLimit; // Sets the Jockey Limit, related to the Jockey limit cvar
static ChargerLimit; // Sets the Charger Limit, related to the Charger limit cvar

static MaxPlayerZombies; // Holds the amount of the maximum amount of special zombies on the field
static BotReady; // Used to determine how many bots are ready, used only for the coordination feature
static ZOMBIECLASS_TANK; // This value varies depending on which L4D game it is, holds the the tank class value
static GetSpawnTime[MAXPLAYERS+1]; // Used for the HUD on getting spawn times of players
static PlayersInServer;
static InfectedSpawnTimeMax
static InfectedSpawnTimeMin
static InitialSpawnInt
static TankLimit


// Booleans
static bool:b_HasRoundStarted; // Used to state if the round started or not
static bool:b_HasRoundEnded; // States if the round has ended or not
static bool:b_LeftSaveRoom; // States if the survivors have left the safe room
static bool:canSpawnBoomer; // States if we can spawn a boomer (releated to spawn restrictions)
static bool:canSpawnSmoker; // States if we can spawn a smoker (releated to spawn restrictions)
static bool:canSpawnHunter; // States if we can spawn a hunter (releated to spawn restrictions)
static bool:canSpawnSpitter; // States if we can spawn a spitter (releated to spawn restrictions)
static bool:canSpawnJockey; // States if we can spawn a jockey (releated to spawn restrictions)
static bool:canSpawnCharger; // States if we can spawn a charger (releated to spawn restrictions)
static bool:DirectorSpawn; // Can allow either the director to spawn the infected (normal l4d behavior), or allow the plugin to spawn them
static bool:SpecialHalt; // Loop Breaker, prevents specials spawning, while Director is spawning, from spawning again
//new bool:TankHalt; // Loop Breaker, prevents player tanks from spawning over and over
static bool:PlayerLifeState[MAXPLAYERS+1]; // States whether that player has the lifestate changed from switching the gamemode
static bool:InitialSpawn; // Related to the coordination feature, tells the plugin to let the infected spawn when the survivors leave the safe room
static bool:b_IsL4D2; // Holds the version of L4D; false if its L4D, true if its L4D2
static bool:AlreadyGhosted[MAXPLAYERS+1]; // Loop Breaker, prevents a player from spawning into a ghost over and over again
static bool:AlreadyGhostedBot[MAXPLAYERS+1]; // Prevents bots taking over a player from ghosting
static bool:DirectorCvarsModified; // Prevents reseting the director class limit cvars if the server or admin modifed them
static bool:PlayerHasEnteredStart[MAXPLAYERS+1];
static bool:AdjustSpawnTimes
static bool:Coordination
static bool:DisableSpawnsTank


// Handles
static Handle:h_BoomerLimit; // Related to the Boomer limit cvar
static Handle:h_SmokerLimit; // Related to the Smoker limit cvar
static Handle:h_HunterLimit; // Related to the Hunter limit cvar
static Handle:h_SpitterLimit; // Related to the Spitter limit cvar
static Handle:h_JockeyLimit; // Related to the Jockey limit cvar
static Handle:h_ChargerLimit; // Related to the Charger limit cvar
static Handle:h_MaxPlayerZombies; // Related to the max specials cvar
static Handle:h_InfectedSpawnTimeMax; // Related to the spawn time cvar
static Handle:h_InfectedSpawnTimeMin; // Related to the spawn time cvar
static Handle:h_DirectorSpawn; // yeah you're getting the idea
static Handle:h_GameMode; // uh huh
static Handle:h_Coordination;
static Handle:h_idletime_b4slay;
static Handle:h_InitialSpawn;
static Handle:FightOrDieTimer[MAXPLAYERS+1]; // kill idle bots
static Handle:h_BotGhostTime;
static Handle:h_DisableSpawnsTank;
static Handle:h_TankLimit;
static Handle:h_AdjustSpawnTimes;


public Plugin:myinfo = 
{
	name = "[L4D/L4D2] Infected Bots Control",
	author = "djromero (SkyDavid), MI 5",
	description = "This plugin spawns infected bots in versus for L4D1 and gives greater control of the infected bots in L4D1/L4D2.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=893938#post893938"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	// Checks to see if the game is a L4D game. If it is, check if its the sequel. L4DVersion is L4D if false, L4D2 if true.
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
		return APLRes_Failure; 
	else if (StrEqual(GameName, "left4dead2", false))
		b_IsL4D2 = true;
	
	return APLRes_Success; 
}

public OnPluginStart()
{
	// Tank Class value is different in L4D2
	if (b_IsL4D2)
		ZOMBIECLASS_TANK = 8;
	else
	ZOMBIECLASS_TANK = 5;
	
	// We register the version cvar
	CreateConVar("l4d_infectedbots_version", PLUGIN_VERSION, "Version of L4D Infected Bots", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	h_GameMode = FindConVar("mp_gamemode");
	
	#if DEVELOPER
	RegConsoleCmd("sm_sp", JoinSpectator);
	RegConsoleCmd("sm_gamemode", CheckGameMode);
	RegConsoleCmd("sm_count", CheckQueue);
	#endif
	
	// console variables
	h_BoomerLimit = CreateConVar("l4d_infectedbots_boomer_limit", "1", "Sets the limit for boomers spawned by the plugin", FCVAR_PLUGIN|FCVAR_SPONLY);
	h_SmokerLimit = CreateConVar("l4d_infectedbots_smoker_limit", "1", "Sets the limit for smokers spawned by the plugin", FCVAR_PLUGIN|FCVAR_SPONLY);
	h_TankLimit = CreateConVar("l4d_infectedbots_tank_limit", "0", "Sets the limit for tanks spawned by the plugin (plugin treats these tanks as another infected bot) (does not affect director tanks)", FCVAR_PLUGIN|FCVAR_SPONLY);
	if (b_IsL4D2)
	{
		h_SpitterLimit = CreateConVar("l4d_infectedbots_spitter_limit", "1", "Sets the limit for spitters spawned by the plugin", FCVAR_PLUGIN|FCVAR_SPONLY);
		h_JockeyLimit = CreateConVar("l4d_infectedbots_jockey_limit", "1", "Sets the limit for jockeys spawned by the plugin", FCVAR_PLUGIN|FCVAR_SPONLY);
		h_ChargerLimit = CreateConVar("l4d_infectedbots_charger_limit", "1", "Sets the limit for chargers spawned by the plugin", FCVAR_PLUGIN|FCVAR_SPONLY);
		h_HunterLimit = CreateConVar("l4d_infectedbots_hunter_limit", "1", "Sets the limit for hunters spawned by the plugin", FCVAR_PLUGIN|FCVAR_SPONLY);
	}
	else
	{
		h_HunterLimit = CreateConVar("l4d_infectedbots_hunter_limit", "2", "Sets the limit for hunters spawned by the plugin", FCVAR_PLUGIN|FCVAR_SPONLY);
	}
	h_MaxPlayerZombies = CreateConVar("l4d_infectedbots_max_specials", "4", "Defines how many special infected can be on the map on all gamemodes (This affects the infected player limit as well)", FCVAR_PLUGIN|FCVAR_SPONLY); 
	h_InfectedSpawnTimeMax = CreateConVar("l4d_infectedbots_spawn_time_max", "30", "Sets the max spawn time for special infected spawned by the plugin in seconds", FCVAR_PLUGIN|FCVAR_SPONLY);
	h_InfectedSpawnTimeMin = CreateConVar("l4d_infectedbots_spawn_time_min", "25", "Sets the minimum spawn time for special infected spawned by the plugin in seconds", FCVAR_PLUGIN|FCVAR_SPONLY);
	h_DirectorSpawn = CreateConVar("l4d_infectedbots_director_spawn_times", "0", "If 1, the plugin will use the director's timing of the spawns, if the game is L4D2 and versus, it will activate Valve's bots", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	h_Coordination = CreateConVar("l4d_infectedbots_coordination", "0", "If 1, bots will only spawn when all other bot spawn timers are at zero", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	h_idletime_b4slay = CreateConVar("l4d_infectedbots_lifespan", "40", "Amount of seconds before a special infected bot is kicked", FCVAR_PLUGIN|FCVAR_SPONLY);
	h_InitialSpawn = CreateConVar("l4d_infectedbots_initial_spawn_timer", "1", "The spawn timer in seconds used when infected bots are spawned for the first time in a map", FCVAR_PLUGIN|FCVAR_SPONLY);
	h_BotGhostTime = CreateConVar("l4d_infectedbots_ghost_time", "2", "If higher than zero, the plugin will first spawn bots as ghosts before they fully spawn on versus/scavenge", FCVAR_PLUGIN|FCVAR_SPONLY);
	h_DisableSpawnsTank = CreateConVar("l4d_infectedbots_spawns_disabled_tank", "0", "If 1, Plugin will disable bot spawning when a tank is on the field", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	h_AdjustSpawnTimes = CreateConVar("l4d_infectedbots_adjust_spawn_times", "0", "If 1, The plugin will adjust spawn timers depending on the gamemode, adjusts spawn timers based on number of survivor players in coop and based on amount of infected players in versus/scavenge", FCVAR_PLUGIN|FCVAR_SPONLY, true, 0.0, true, 1.0);
	
	HookConVarChange(h_BoomerLimit, ConVarBoomerLimit);
	BoomerLimit = GetConVarInt(h_BoomerLimit);
	HookConVarChange(h_SmokerLimit, ConVarSmokerLimit);
	SmokerLimit = GetConVarInt(h_SmokerLimit);
	HookConVarChange(h_HunterLimit, ConVarHunterLimit);
	HunterLimit = GetConVarInt(h_HunterLimit);
	if (b_IsL4D2)
	{
		HookConVarChange(h_SpitterLimit, ConVarSpitterLimit);
		SpitterLimit = GetConVarInt(h_SpitterLimit);
		HookConVarChange(h_JockeyLimit, ConVarJockeyLimit);
		JockeyLimit = GetConVarInt(h_JockeyLimit);
		HookConVarChange(h_ChargerLimit, ConVarChargerLimit);
		ChargerLimit = GetConVarInt(h_ChargerLimit);
	}
	HookConVarChange(h_MaxPlayerZombies, ConVarMaxPlayerZombies);
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
	HookConVarChange(h_DirectorSpawn, ConVarDirectorSpawn);
	DirectorSpawn = GetConVarBool(h_DirectorSpawn);
	HookConVarChange(h_GameMode, ConVarGameMode);
	AdjustSpawnTimes = GetConVarBool(h_AdjustSpawnTimes);
	HookConVarChange(h_AdjustSpawnTimes, ConVarAdjustSpawnTimes);
	Coordination = GetConVarBool(h_Coordination);
	HookConVarChange(h_Coordination, ConVarCoordination);
	DisableSpawnsTank = GetConVarBool(h_DisableSpawnsTank);
	HookConVarChange(h_DisableSpawnsTank, ConVarDisableSpawnsTank);
	HookConVarChange(h_InfectedSpawnTimeMax, ConVarInfectedSpawnTimeMax);
	InfectedSpawnTimeMax = GetConVarInt(h_InfectedSpawnTimeMax);
	HookConVarChange(h_InfectedSpawnTimeMin, ConVarInfectedSpawnTimeMin);
	InfectedSpawnTimeMin = GetConVarInt(h_InfectedSpawnTimeMin);
	HookConVarChange(h_InitialSpawn, ConVarInitialSpawn);
	InitialSpawnInt = GetConVarInt(h_InitialSpawn);
	HookConVarChange(h_TankLimit, ConVarTankLimit);
	TankLimit = GetConVarInt(h_TankLimit);
	
	// If the admin wanted to change the director class limits with director spawning on, the plugin will not reset those cvars to their defaults upon startup.
	
	HookConVarChange(FindConVar("z_hunter_limit"), ConVarDirectorCvarChanged);
	if (!b_IsL4D2)
	{
		HookConVarChange(FindConVar("z_gas_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_exploding_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_boomers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_smokers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_hunters"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("holdout_max_specials"), ConVarDirectorCvarChanged);
	}
	else
	{
		HookConVarChange(FindConVar("z_smoker_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_boomer_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_jockey_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_spitter_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("z_charger_limit"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_boomers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_smokers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_hunters"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_jockeys"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_spitters"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_chargers"), ConVarDirectorCvarChanged);
		HookConVarChange(FindConVar("survival_max_specials"), ConVarDirectorCvarChanged);
	}
	
	HookEvent("round_start", evtRoundStart);
	HookEvent("round_end", evtRoundEnd, EventHookMode_Pre);
	// We hook some events ...
	HookEvent("player_death", evtPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", evtPlayerTeam);
	HookEvent("player_spawn", evtPlayerSpawn);
	HookEvent("create_panic_event", evtSurvivalStart);
	HookEvent("finale_start", evtFinaleStart);
	HookEvent("player_bot_replace", evtBotReplacedPlayer);
	HookEvent("player_first_spawn", evtPlayerFirstSpawned);
	HookEvent("player_entered_start_area", evtPlayerFirstSpawned);
	HookEvent("player_entered_checkpoint", evtPlayerFirstSpawned);
	HookEvent("player_transitioned", evtPlayerFirstSpawned);
	HookEvent("player_left_start_area", evtPlayerFirstSpawned);
	HookEvent("player_left_checkpoint", evtPlayerFirstSpawned);
	
	//Autoconfig for plugin
	AutoExecConfig(true, "l4dinfectedbots");
}

public ConVarBoomerLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	BoomerLimit = GetConVarInt(h_BoomerLimit);
}
public ConVarSmokerLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SmokerLimit = GetConVarInt(h_SmokerLimit);
}

public ConVarHunterLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	HunterLimit = GetConVarInt(h_HunterLimit);
}

public ConVarSpitterLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	SpitterLimit = GetConVarInt(h_SpitterLimit);
}

public ConVarJockeyLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	JockeyLimit = GetConVarInt(h_JockeyLimit);
}

public ConVarChargerLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	ChargerLimit = GetConVarInt(h_ChargerLimit);
}

public ConVarInfectedSpawnTimeMax(Handle:convar, const String:oldValue[], const String:newValue[])
{
	InfectedSpawnTimeMax = GetConVarInt(h_InfectedSpawnTimeMax);
}

public ConVarInfectedSpawnTimeMin(Handle:convar, const String:oldValue[], const String:newValue[])
{
	InfectedSpawnTimeMin = GetConVarInt(h_InfectedSpawnTimeMin);
}

public ConVarInitialSpawn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	InitialSpawnInt = GetConVarInt(h_InitialSpawn);
}

public ConVarTankLimit(Handle:convar, const String:oldValue[], const String:newValue[])
{
	TankLimit = GetConVarInt(h_TankLimit);
}

public ConVarDirectorCvarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DirectorCvarsModified = true;
}

public ConVarAdjustSpawnTimes(Handle:convar, const String:oldValue[], const String:newValue[])
{
	AdjustSpawnTimes = GetConVarBool(h_AdjustSpawnTimes);
}

public ConVarCoordination(Handle:convar, const String:oldValue[], const String:newValue[])
{
	Coordination = GetConVarBool(h_Coordination);
}

public ConVarDisableSpawnsTank(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DisableSpawnsTank = GetConVarBool(h_DisableSpawnsTank);
}

public ConVarMaxPlayerZombies(Handle:convar, const String:oldValue[], const String:newValue[])
{
	MaxPlayerZombies = GetConVarInt(h_MaxPlayerZombies);
	CreateTimer(0.1, MaxSpecialsSet);
}

public ConVarDirectorSpawn(Handle:convar, const String:oldValue[], const String:newValue[])
{
	DirectorSpawn = GetConVarBool(h_DirectorSpawn);
	if (!DirectorSpawn)
	{
		//ResetCvars();
		TweakSettings();
		CheckIfBotsNeeded(true, false);
	}
	else
	{
		//ResetCvarsDirector();
		DirectorStuff();
	}
}

public ConVarGameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GameModeCheck();
	
	if (!DirectorSpawn)
	{
		//ResetCvars();
		TweakSettings();
	}
	else
	{
		//ResetCvarsDirector();
		DirectorStuff();
	}
}

public Action:JoinSpectator(client, args)
{
	if (client)
	{
		ChangeClientTeam(client, TEAM_SPECTATOR);
	}
}

TweakSettings()
{
	// We tweak some settings ...
	
	// Some interesting things about this. There was a bug I discovered that in versions 1.7.8 and below, infected players would not spawn as ghosts in VERSUS. This was
	// due to the fact that the coop class limits were not being reset (I didn't think they were linked at all, but I should have known better). This bug has been fixed
	// with the coop class limits being reset on every gamemode except coop of course.
	
	// Reset the cvars
	ResetCvars();
	
	switch (GameMode)
	{
		case 1: // Coop, We turn off the ability for the director to spawn the bots, and have the plugin do it while allowing the director to spawn tanks and witches, 
		// MI 5
		{
			// If the game is L4D 2...
			if (b_IsL4D2)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 0);
				SetConVarInt(FindConVar("z_boomer_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
				SetConVarInt(FindConVar("z_spitter_limit"), 0);
				SetConVarInt(FindConVar("z_jockey_limit"), 0);
				SetConVarInt(FindConVar("z_charger_limit"), 0);
			}
			else
			{
				SetConVarInt(FindConVar("z_gas_limit"), 0);
				SetConVarInt(FindConVar("z_exploding_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
			}
		}
		case 2: // Versus, Better Versus Infected Bot AI
		{
			// If the game is L4D 2...
			if (b_IsL4D2)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 0);
				SetConVarInt(FindConVar("z_boomer_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
				SetConVarInt(FindConVar("z_spitter_limit"), 0);
				SetConVarInt(FindConVar("z_jockey_limit"), 0);
				SetConVarInt(FindConVar("z_charger_limit"), 0);
				
			}
			else
			{
				SetConVarInt(FindConVar("z_gas_limit"), 999);
				SetConVarInt(FindConVar("z_exploding_limit"), 999);
				SetConVarInt(FindConVar("z_hunter_limit"), 999);
			}
			// Enhance Special Infected AI
			
		}
		case 3: // Survival, Turns off the ability for the director to spawn infected bots in survival, MI 5
		{
			if (b_IsL4D2)
			{
				SetConVarInt(FindConVar("survival_max_smokers"), 0);
				SetConVarInt(FindConVar("survival_max_boomers"), 0);
				SetConVarInt(FindConVar("survival_max_hunters"), 0);
				SetConVarInt(FindConVar("survival_max_spitters"), 0);
				SetConVarInt(FindConVar("survival_max_jockeys"), 0);
				SetConVarInt(FindConVar("survival_max_chargers"), 0);
				SetConVarInt(FindConVar("survival_max_specials"), MaxPlayerZombies);
				SetConVarInt(FindConVar("z_smoker_limit"), 0);
				SetConVarInt(FindConVar("z_boomer_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
				SetConVarInt(FindConVar("z_spitter_limit"), 0);
				SetConVarInt(FindConVar("z_jockey_limit"), 0);
				SetConVarInt(FindConVar("z_charger_limit"), 0);
			}
			else
			{
				SetConVarInt(FindConVar("holdout_max_smokers"), 0);
				SetConVarInt(FindConVar("holdout_max_boomers"), 0);
				SetConVarInt(FindConVar("holdout_max_hunters"), 0);
				SetConVarInt(FindConVar("holdout_max_specials"), MaxPlayerZombies);
				SetConVarInt(FindConVar("z_gas_limit"), 0);
				SetConVarInt(FindConVar("z_exploding_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
			}
		}
	}
	
	//Some cvar tweaks
	
	SetConVarInt(FindConVar("director_spectate_specials"), 1);
	
	DirectorCvarsModified = false;
	if (b_IsL4D2)
	{
		// Prevents the Director from spawning bots in versus
		SetConVarInt(FindConVar("versus_special_respawn_interval"), 99999999);
	}
	#if DEBUGSERVER
	LogMessage("Tweaking Settings");
	#endif
}

ResetCvars()
{
	#if DEBUGSERVER
	LogMessage("Plugin Cvars Reset");
	#endif
	if (GameMode == 1)
	{
		ResetConVar(FindConVar("director_no_specials"), true, true);
		
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("survival_max_smokers"), true, true);
			ResetConVar(FindConVar("survival_max_boomers"), true, true);
			ResetConVar(FindConVar("survival_max_hunters"), true, true);
			ResetConVar(FindConVar("survival_max_spitters"), true, true);
			ResetConVar(FindConVar("survival_max_jockeys"), true, true);
			ResetConVar(FindConVar("survival_max_chargers"), true, true);
			ResetConVar(FindConVar("survival_max_specials"), true, true);
			
		}
		else
		{
			ResetConVar(FindConVar("holdout_max_smokers"), true, true);
			ResetConVar(FindConVar("holdout_max_boomers"), true, true);
			ResetConVar(FindConVar("holdout_max_hunters"), true, true);
			ResetConVar(FindConVar("holdout_max_specials"), true, true);
		}
	}
	else if (GameMode == 2)
	{
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("survival_max_smokers"), true, true);
			ResetConVar(FindConVar("survival_max_boomers"), true, true);
			ResetConVar(FindConVar("survival_max_hunters"), true, true);
			ResetConVar(FindConVar("survival_max_spitters"), true, true);
			ResetConVar(FindConVar("survival_max_jockeys"), true, true);
			ResetConVar(FindConVar("survival_max_chargers"), true, true);
			ResetConVar(FindConVar("survival_max_specials"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("holdout_max_smokers"), true, true);
			ResetConVar(FindConVar("holdout_max_boomers"), true, true);
			ResetConVar(FindConVar("holdout_max_hunters"), true, true);
			ResetConVar(FindConVar("holdout_max_specials"), true, true);
		}
	}
	else if (GameMode == 3)
	{
		ResetConVar(FindConVar("z_hunter_limit"), true, true);
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("z_smoker_limit"), true, true);
			ResetConVar(FindConVar("z_boomer_limit"), true, true);
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			ResetConVar(FindConVar("z_spitter_limit"), true, true);
			ResetConVar(FindConVar("z_jockey_limit"), true, true);
			ResetConVar(FindConVar("z_charger_limit"), true, true);
			
		}
		else
		{
			ResetConVar(FindConVar("z_gas_limit"), true, true);
			ResetConVar(FindConVar("z_exploding_limit"), true, true);
		}
		
	}
}

ResetCvarsDirector()
{
	#if DEBUGSERVER
	LogMessage("Director Cvars Reset");
	#endif
	if (GameMode != 2)
	{
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("z_smoker_limit"), true, true);
			ResetConVar(FindConVar("z_boomer_limit"), true, true);
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			ResetConVar(FindConVar("z_spitter_limit"), true, true);
			ResetConVar(FindConVar("z_jockey_limit"), true, true);
			ResetConVar(FindConVar("z_charger_limit"), true, true);
			ResetConVar(FindConVar("survival_max_smokers"), true, true);
			ResetConVar(FindConVar("survival_max_boomers"), true, true);
			ResetConVar(FindConVar("survival_max_hunters"), true, true);
			ResetConVar(FindConVar("survival_max_spitters"), true, true);
			ResetConVar(FindConVar("survival_max_jockeys"), true, true);
			ResetConVar(FindConVar("survival_max_chargers"), true, true);
			ResetConVar(FindConVar("survival_max_specials"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			ResetConVar(FindConVar("z_exploding_limit"), true, true);
			ResetConVar(FindConVar("z_gas_limit"), true, true);
			ResetConVar(FindConVar("holdout_max_smokers"), true, true);
			ResetConVar(FindConVar("holdout_max_boomers"), true, true);
			ResetConVar(FindConVar("holdout_max_hunters"), true, true);
			ResetConVar(FindConVar("holdout_max_specials"), true, true);
		}
	}
	else
	{
		if (b_IsL4D2)
		{
			//ResetConVar(FindConVar("z_smoker_limit"), true, true);
			SetConVarInt(FindConVar("z_smoker_limit"), 2);
			ResetConVar(FindConVar("z_boomer_limit"), true, true);
			//ResetConVar(FindConVar("z_hunter_limit"), true, true);
			SetConVarInt(FindConVar("z_hunter_limit"), 2);
			ResetConVar(FindConVar("z_spitter_limit"), true, true);
			ResetConVar(FindConVar("z_jockey_limit"), true, true);
			ResetConVar(FindConVar("z_charger_limit"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("z_hunter_limit"), true, true);
			ResetConVar(FindConVar("z_exploding_limit"), true, true);
			ResetConVar(FindConVar("z_gas_limit"), true, true);
		}
	}
}

public Action:evtRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If round has started ...
	if (b_HasRoundStarted)
		return;
	
	b_LeftSaveRoom = false;
	b_HasRoundEnded = false;
	b_HasRoundStarted = true;
	
	//Check the GameMode
	GameModeCheck();
	
	if (GameMode == 0)
		return;
	
	#if DEBUGCLIENTS
	PrintToChatAll("Round Started");
	#endif
	#if DEBUGSERVER
	LogMessage("Round Started");
	#endif
	
	// Removes the boundaries for z_max_player_zombies and notify flag
	new flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
	SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);
	
	// Added a delay to setting MaxSpecials so that it would set correctly when the server first starts up
	CreateTimer(0.4, MaxSpecialsSet);
	
	//reset some variables
	InfectedBotQueue = 0;
	BotReady = 0;
	SpecialHalt = false;
	InitialSpawn = false;
	
	// Start up TweakSettings or Director Stuff
	if (!DirectorSpawn)
		TweakSettings();
	else
	DirectorStuff();
	
	if (GameMode != 3)
	{
		#if DEBUGSERVER
		LogMessage("Starting the Coop/Versus PlayerLeft Start Timer");
		#endif
		CreateTimer(1.0, PlayerLeftStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:evtPlayerFirstSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	// This event's purpose is to execute when a player first enters the server. This eliminates a lot of problems when changing variables setting timers on clients.
	
	if (b_HasRoundEnded)
		return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!client)
		return;
	
	if (IsFakeClient(client))
		return;
	
	// If player has already entered the start area, don't go into this
	if (PlayerHasEnteredStart[client])
		return;
	
	#if DEBUGCLIENTS
	PrintToChatAll("Player has spawned for the first time");
	#endif
	
	
	AlreadyGhosted[client] = false;
	PlayerHasEnteredStart[client] = true;
	
}

GameModeCheck()
{
	#if DEBUGSERVER
	LogMessage("Checking Gamemode");
	#endif
	// We determine what the gamemode is
	decl String:GameName[16];
	GetConVarString(h_GameMode, GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false) || StrEqual(GameName, "mutation12", false) || StrEqual(GameName, "mutation13", false) || StrEqual(GameName, "mutation15", false) || StrEqual(GameName, "mutation11", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false) || StrEqual(GameName, "mutation3", false) || StrEqual(GameName, "mutation9", false) || StrEqual(GameName, "mutation1", false) || StrEqual(GameName, "mutation7", false) || StrEqual(GameName, "mutation10", false) || StrEqual(GameName, "mutation2", false) || StrEqual(GameName, "mutation4", false) || StrEqual(GameName, "mutation5", false) || StrEqual(GameName, "mutation14", false))
		GameMode = 1;
	else
	GameMode = 1;
	
}

public Action:MaxSpecialsSet(Handle:Timer)
{
	SetConVarInt(FindConVar("z_max_player_zombies"), MaxPlayerZombies);
	#if DEBUGSERVER
	LogMessage("Max Player Zombies Set");
	#endif
}

DirectorStuff()
{	
	SpecialHalt = false;
	
	SetConVarInt(FindConVar("director_spectate_specials"), 1);
	if (b_IsL4D2)
		ResetConVar(FindConVar("versus_special_respawn_interval"), true, true);
	
	// if the server changes the director spawn limits in any way, don't reset the cvars
	if (!DirectorCvarsModified)
		ResetCvarsDirector();
	
	#if DEBUGSERVER
	LogMessage("Director Stuff has been executed");
	#endif
	
}

public Action:evtRoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	// If round has not been reported as ended ..
	if (!b_HasRoundEnded)
	{
		// we mark the round as ended
		b_HasRoundEnded = true;
		b_HasRoundStarted = false;
		b_LeftSaveRoom = false;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			PlayerHasEnteredStart[i] = false;
			if (FightOrDieTimer[i] != INVALID_HANDLE)
			{
				KillTimer(FightOrDieTimer[i]);
				FightOrDieTimer[i] = INVALID_HANDLE;
			}
		}
		
		#if DEBUGCLIENTS
		PrintToChatAll("Round Ended");
		#endif
		#if DEBUGSERVER
		LogMessage("Round Ended");
		#endif
	}
	
}

public OnMapEnd()
{
	#if DEBUGSERVER
	LogMessage("Map has ended");
	#endif
	
	b_HasRoundStarted = false;
	b_HasRoundEnded = true;
	b_LeftSaveRoom = false;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (FightOrDieTimer[i] != INVALID_HANDLE)
		{
			KillTimer(FightOrDieTimer[i]);
			FightOrDieTimer[i] = INVALID_HANDLE;
		}
	}
}

public Action:PlayerLeftStart(Handle:Timer)
{
	if (LeftStartArea())
	{	
		// We don't care who left, just that at least one did
		if (!b_LeftSaveRoom)
		{
			decl String:GameName[16];
			GetConVarString(h_GameMode, GameName, sizeof(GameName));
			if (StrEqual(GameName, "mutation15", false))
			{
				SetConVarInt(FindConVar("survival_max_smokers"), 0);
				SetConVarInt(FindConVar("survival_max_boomers"), 0);
				SetConVarInt(FindConVar("survival_max_hunters"), 0);
				SetConVarInt(FindConVar("survival_max_jockeys"), 0);
				SetConVarInt(FindConVar("survival_max_spitters"), 0);
				SetConVarInt(FindConVar("survival_max_chargers"), 0);
				return Plugin_Continue; 
			}
			
			#if DEBUGSERVER
			LogMessage("A player left the start area, spawning bots");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("A player left the start area, spawning bots");
			#endif
			b_LeftSaveRoom = true;
			
			
			
			
			// We reset some settings
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			canSpawnHunter = true;
			if (b_IsL4D2)
			{
				canSpawnSpitter = true;
				canSpawnJockey = true;
				canSpawnCharger = true;
			}
			InitialSpawn = true;
			
			// We check if we need to spawn bots
			CheckIfBotsNeeded(false, true);
			#if DEBUGSERVER
			LogMessage("Checking to see if we need bots");
			#endif
			CreateTimer(3.0, InitialSpawnReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		CreateTimer(1.0, PlayerLeftStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

// This is hooked to the panic event, but only starts if its survival. This is what starts up the bots in survival.

public Action:evtSurvivalStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 3)
	{  
		// We don't care who left, just that at least one did
		if (!b_LeftSaveRoom)
		{
			#if DEBUGSERVER
			LogMessage("A player triggered the survival event, spawning bots");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("A player triggered the survival event, spawning bots");
			#endif
			b_LeftSaveRoom = true;
			
			// We reset some settings
			canSpawnBoomer = true;
			canSpawnSmoker = true;
			canSpawnHunter = true;
			if (b_IsL4D2)
			{
				canSpawnSpitter = true;
				canSpawnJockey = true;
				canSpawnCharger = true;
			}
			InitialSpawn = true;
			
			// We check if we need to spawn bots
			CheckIfBotsNeeded(false, true);
			#if DEBUGSERVER
			LogMessage("Checking to see if we need bots");
			#endif
			CreateTimer(3.0, InitialSpawnReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action:InitialSpawnReset(Handle:Timer)
{
	InitialSpawn = false;
}

public Action:BotReadyReset(Handle:Timer)
{
	BotReady = 0;
}

public Action:InfectedBotBooterVersus(Handle:Timer)
{
	//This is to check if there are any extra bots and boot them if necessary, excluding tanks, versus only
	if (GameMode != 2 || b_IsL4D2)
		return;
	
	// current count ...
	new total;
	
	for (new i=1; i<=MaxClients; i++)
	{
		// if player is ingame ...
		if (IsClientInGame(i))
		{
			// if player is on infected's team
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
				// We count depending on class ...
				if (!IsPlayerTank(i) || (IsPlayerTank(i) && !PlayerIsAlive(i)))
				{
					total++;
				}
			}
		}
	}
	if (total + InfectedBotQueue > MaxPlayerZombies)
	{
		new kick = total + InfectedBotQueue - MaxPlayerZombies; 
		new kicked = 0;
		
		// We kick any extra bots ....
		for (new i=1;(i<=MaxClients)&&(kicked < kick);i++)
		{
			// If player is infected and is a bot ...
			if (IsClientInGame(i) && IsFakeClient(i))
			{
				//  If bot is on infected ...
				if (GetClientTeam(i) == TEAM_INFECTED)
				{
					// If player is not a tank
					if (!IsPlayerTank(i) || ((IsPlayerTank(i) && !PlayerIsAlive(i))))
					{
						// timer to kick bot
						CreateTimer(0.1,kickbot,i);
						
						// increment kicked count ..
						kicked++;
						#if DEBUGSERVER
						LogMessage("Kicked a Bot because its over the player limit");
						#endif
					}
				}
			}
		}
	}
	
}

public OnClientPutInServer(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	
	PlayersInServer++;
	
	#if DEBUGSERVER
	LogMessage("OnClientPutInServer has started");
	#endif
}

public Action:CheckGameMode(client, args)
{
	if (client)
	{
		PrintToChat(client, "GameMode = %i", GameMode);
	}
}

public Action:CheckQueue(client, args)
{
	if (client)
	{
		CountInfected();
		
		PrintToChat(client, "InfectedBotQueue = %i, InfectedBotCount = %i, InfectedRealCount = %i", InfectedBotQueue, InfectedBotCount, InfectedRealCount);
	}
}

public Action:evtPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	// We get the client id and time
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	// If client is valid
	if (!client || !IsClientInGame(client)) return Plugin_Continue;
	
	if (GetClientTeam(client) != TEAM_INFECTED)
		return Plugin_Continue;
	
	if (DirectorSpawn && GameMode != 2)
	{
		if (IsPlayerSmoker(client))
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Smoker kicked");
					#endif
					
					new BotNeeded = 1;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("Spawned Smoker");
					#endif
				}
			}
		}
		else if (IsPlayerBoomer(client))
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Boomer kicked");
					#endif
					
					new BotNeeded = 2;
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("Spawned Booomer");
					#endif
				}
			}
		}
		else if (IsPlayerHunter(client))
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Hunter Kicked");
					#endif
					
					new BotNeeded = 3;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("Hunter Spawned");
					#endif
				}
			}
		}
		else if (IsPlayerSpitter(client) && b_IsL4D2)
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Spitter Kicked");
					#endif
					
					new BotNeeded = 4;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("Spitter Spawned");
					#endif
				}
			}
		}
		else if (IsPlayerJockey(client) && b_IsL4D2)
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Jockey Kicked");
					#endif
					
					new BotNeeded = 5;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("Jockey Spawned");
					#endif
				}
			}
		}
		else if (IsPlayerCharger(client) && b_IsL4D2)
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					#if DEBUGSERVER
					LogMessage("Charger Kicked");
					#endif
					
					new BotNeeded = 6;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
					
					
					#if DEBUGSERVER
					LogMessage("Charger Spawned");
					#endif
				}
			}
		}
	}
	
	if (!IsPlayerTank(client) && IsFakeClient(client))
	{
		if (FightOrDieTimer[client] != INVALID_HANDLE)
		{
			KillTimer(FightOrDieTimer[client]);
			FightOrDieTimer[client] = INVALID_HANDLE;
		}
		FightOrDieTimer[client] = CreateTimer(GetConVarFloat(h_idletime_b4slay), DisposeOfCowards, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	// If its Versus and the bot is not a tank, make the bot into a ghost
	if (IsFakeClient(client) && GameMode == 2 && !IsPlayerTank(client))
		CreateTimer(0.1, Timer_SetUpBotGhost, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Continue;
}

public Action:evtBotReplacedPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	// The purpose of using this event, is to prevent a bot from ghosting after the player leaves or joins another team
	
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	AlreadyGhostedBot[bot] = true;
}

public Action:DisposeOfCowards(Handle:timer, any:coward)
{
	if (IsClientInGame(coward) && IsFakeClient(coward) && GetClientTeam(coward) == TEAM_INFECTED && !IsPlayerTank(coward) && PlayerIsAlive(coward))
	{
		// Check to see if the infected thats about to be slain sees the survivors. If so, kill the timer and make a new one.
		new threats = GetEntProp(coward, Prop_Send, "m_hasVisibleThreats");
		
		if (threats)
		{
			FightOrDieTimer[coward] = INVALID_HANDLE;
			FightOrDieTimer[coward] = CreateTimer(GetConVarFloat(h_idletime_b4slay), DisposeOfCowards, coward);
			#if DEBUGCLIENTS
			PrintToChatAll("%N saw survivors after timer is up, creating new timer", coward);
			#endif
			return;
		}
		else
		{
			CreateTimer(0.1, kickbot, coward);
			if (!DirectorSpawn)
			{
				new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
				
				if (GameMode == 2 && AdjustSpawnTimes && MaxPlayerZombies != HumansOnInfected())
					SpawnTime = SpawnTime / (MaxPlayerZombies - HumansOnInfected());
				else if (GameMode == 1 && AdjustSpawnTimes)
					SpawnTime = SpawnTime - TrueNumberOfSurvivors();
				
				CreateTimer(float(SpawnTime), Spawn_InfectedBot, _, 0);
				InfectedBotQueue++;
				
				#if DEBUGCLIENTS
				PrintToChatAll("Kicked bot %N for not attacking", coward);
				PrintToChatAll("An infected bot has been added to the spawn queue due to lifespan timer expiring");
				#endif
			}
		}
	}
	FightOrDieTimer[coward] = INVALID_HANDLE;
}

public Action:Timer_SetUpBotGhost(Handle:timer, any:client)
{
	// This will set the bot a ghost, stop the bot's movement, and waits until it can spawn
	if (IsValidEntity(client))
	{
		if (!AlreadyGhostedBot[client])
		{
			SetGhostStatus(client, true);
			SetEntityMoveType(client, MOVETYPE_NONE);
			CreateTimer(GetConVarFloat(h_BotGhostTime), Timer_RestoreBotGhost, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		AlreadyGhostedBot[client] = false;
	}
}

public Action:Timer_RestoreBotGhost(Handle:timer, any:client)
{
	if (IsValidEntity(client))
	{
		SetGhostStatus(client, false);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
}

public Action:evtPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If round has ended .. we ignore this
	if (b_HasRoundEnded || !b_LeftSaveRoom) return Plugin_Continue;
	
	// We get the client id and time
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (FightOrDieTimer[client] != INVALID_HANDLE)
	{
		KillTimer(FightOrDieTimer[client]);
		FightOrDieTimer[client] = INVALID_HANDLE;
	}
	
	
	if (!client || !IsClientInGame(client)) return Plugin_Continue;
	
	if (GetClientTeam(client) !=TEAM_INFECTED) return Plugin_Continue;
	
	/*
	if (!DirectorSpawn)
	{
	if (L4DVersion)
	{
	if (IsPlayerBoomer(client))
	{
	canSpawnBoomer = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 3);
	#if DEBUGSERVER
	LogMessage("Boomer died, setting spawn restrictions");
	#endif
	}
	else if (IsPlayerSmoker(client))
	{
	canSpawnSmoker = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 2);
	}
	else if (IsPlayerHunter(client))
	{
	canSpawnHunter = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 1);
	}
	else if (IsPlayerSpitter(client))
	{
	canSpawnSpitter = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 4);
	}
	else if (IsPlayerJockey(client))
	{
	canSpawnJockey = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 5);
	}
	else if (IsPlayerCharger(client))
	{
	canSpawnCharger = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin)), ResetSpawnRestriction, 6);
	}
	}
	else
	{
	if (IsPlayerBoomer(client))
	{
	canSpawnBoomer = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin) * 0), ResetSpawnRestriction, 3);
	#if DEBUGSERVER
	LogMessage("Boomer died, setting spawn restrictions");
	#endif
	}
	else if (IsPlayerSmoker(client))
	{
	canSpawnSmoker = false;
	CreateTimer(float(GetConVarInt(h_InfectedSpawnTimeMin) * 0), ResetSpawnRestriction, 2);
	}
	}
	}
	*/
	
	// if victim was a bot, we setup a timer to spawn a new bot ...
	if (GetEventBool(event, "victimisbot") && (!DirectorSpawn))
	{
		if (!IsPlayerTank(client))
		{
			new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
			if (AdjustSpawnTimes && MaxPlayerZombies != HumansOnInfected())
				SpawnTime = SpawnTime / (MaxPlayerZombies - HumansOnInfected());
			CreateTimer(float(SpawnTime), Spawn_InfectedBot, _, 0);
			InfectedBotQueue++;
		}
		
		#if DEBUGCLIENTS
		PrintToChatAll("An infected bot has been added to the spawn queue...");
		#endif
	}
	
	if (IsPlayerTank(client))
		CheckIfBotsNeeded(false, false);
	
	#if DEBUGCLIENTS
	PrintToChatAll("An infected bot has been added to the spawn queue...");
	#endif
	
	else if (GameMode != 2 && DirectorSpawn)
	{
		new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
		GetSpawnTime[client] = SpawnTime;
	}
	
	// This fixes the spawns when the spawn timer is set to 5 or below and fixes the spitter spit glitch
	if (IsFakeClient(client) && !IsPlayerSpitter(client))
		CreateTimer(0.1, kickbot, client);
	
	return Plugin_Continue;
}

public Action:Spawn_InfectedBot_Director(Handle:timer, any:BotNeeded)
{
	
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i))) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a ghost ....
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
				}
				else if (!PlayerIsAlive(i))
				{
					AlreadyGhosted[i] = false;
					SetLifeState(i, true);
				}
			}
		}
	}
	
	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (anyclient == -1)
	{
		#if DEBUGSERVER
		LogMessage("[Infected bots] Creating temp client to fake command");
		#endif
		
		// we create a fake client
		anyclient = CreateFakeClient("Bot");
		if (anyclient == 0)
		{
			LogError("[L4D] Infected Bots: CreateFakeClient returned 0 -- Infected bot was not spawned");
		}
		temp = true;
	}
	
	SpecialHalt = true;
	
	switch (BotNeeded)
	{
		case 1: // Smoker
		CheatCommand(anyclient, "z_spawn_old", "smoker auto");
		case 2: // Boomer
		CheatCommand(anyclient, "z_spawn_old", "boomer auto");
		case 3: // Hunter
		CheatCommand(anyclient, "z_spawn_old", "hunter auto");
		case 4: // Spitter
		CheatCommand(anyclient, "z_spawn_old", "spitter auto");
		case 5: // Jockey
		CheatCommand(anyclient, "z_spawn_old", "jockey auto");
		case 6: // Charger
		CheatCommand(anyclient, "z_spawn_old", "charger auto");
	}
	
	SpecialHalt = false;
	
	// We restore the player's status
	for (new i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i])
			SetGhostStatus(i, true);
		if (resetLife[i])
			SetLifeState(i, true);
	}
	// If client was temp, we setup a timer to kick the fake player
	if (temp) CreateTimer(0.1, kickbot, anyclient);
}

/*
public Action:ResetSpawnRestriction (Handle:timer, any:bottype)
{
#if DEBUGSERVER
LogMessage("Resetting spawn restrictions");
#endif
switch (bottype)
{
case 1: // hunter
canSpawnHunter = true;
case 2: // smoker
canSpawnSmoker = true;
case 3: // boomer
canSpawnBoomer = true;
case 4: // spitter
canSpawnSpitter = true;
case 5: // jockey
canSpawnJockey = true;
case 6: // charger
canSpawnCharger = true;
}

}
*/
public Action:evtPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	// If player is a bot, we ignore this ...
	if (GetEventBool(event, "isbot")) return Plugin_Continue;
	
	// We get some data needed ...
	new newteam = GetEventInt(event, "team");
	new oldteam = GetEventInt(event, "oldteam");
	
	// If player's new/old team is infected, we recount the infected and add bots if needed ...
	if (!b_HasRoundEnded && b_LeftSaveRoom && GameMode == 2)
	{
		if (oldteam == 3||newteam == 3)
		{
			CheckIfBotsNeeded(false, false);
		}
		if (newteam == 3)
		{
			//Kick Timer
			CreateTimer(1.0, InfectedBotBooterVersus, _, TIMER_FLAG_NO_MAPCHANGE);
			#if DEBUGSERVER
			LogMessage("A player switched to infected, attempting to boot a bot");
			#endif
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	// If is a bot, skip this function
	if (IsFakeClient(client))
		return;
	
	// Reset all other arrays
	PlayerLifeState[client] = false;
	GetSpawnTime[client] = 0;
	AlreadyGhosted[client] = false;
	PlayerHasEnteredStart[client] = false;
	PlayersInServer--;
	
	// If no real players are left in game ... MI 5
	if (PlayersInServer == 0)
	{
		#if DEBUGSERVER
		LogMessage("All Players have left the Server");
		#endif
		
		b_LeftSaveRoom = false;
		b_HasRoundEnded = true;
		b_HasRoundStarted = false;
		DirectorCvarsModified = false;
		
		
		// Zero all respawn times ready for the next round
		for (new i = 1; i <= MaxClients; i++)
		{
			AlreadyGhosted[i] = false;
			PlayerHasEnteredStart[i] = false;
		}
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (FightOrDieTimer[i] != INVALID_HANDLE)
			{
				KillTimer(FightOrDieTimer[i]);
				FightOrDieTimer[i] = INVALID_HANDLE;
			}
		}
		
	}
	
}

public Action:CheckIfBotsNeededLater (Handle:timer, any:spawn_immediately)
{
	CheckIfBotsNeeded(spawn_immediately, false);
}

CheckIfBotsNeeded(bool:spawn_immediately, bool:initial_spawn)
{
	if (!DirectorSpawn)
	{
		#if DEBUGSERVER
		LogMessage("Checking bots");
		#endif
		#if DEBUGCLIENTS
		PrintToChatAll("Checking bots");
		#endif
		
		if (b_HasRoundEnded || !b_LeftSaveRoom) return;
		
		// First, we count the infected
		CountInfected();
		
		new diff = MaxPlayerZombies - (InfectedBotCount + InfectedRealCount + InfectedBotQueue);
		
		// If we need more infected bots
		if (diff > 0)
		{
			for (new i;i<diff;i++)
			{
				// If we need them right away ...
				if (spawn_immediately)
				{
					InfectedBotQueue++;
					CreateTimer(0.5, Spawn_InfectedBot, _, 0);
					#if DEBUGSERVER
					LogMessage("Setting up the bot now");
					#endif
				}
				else if (initial_spawn)
				{
					InfectedBotQueue++;
					CreateTimer(float(InitialSpawnInt), Spawn_InfectedBot, _, 0);
					#if DEBUGSERVER
					LogMessage("Setting up the initial bot now");
					#endif
				}
				else // We use the normal time ..
				{
					InfectedBotQueue++;
					if (GameMode == 2 && AdjustSpawnTimes && MaxPlayerZombies != HumansOnInfected())
						CreateTimer(float(InfectedSpawnTimeMax) / (MaxPlayerZombies - HumansOnInfected()), Spawn_InfectedBot, _, 0);
					else if (GameMode == 1 && AdjustSpawnTimes)
						CreateTimer(float(InfectedSpawnTimeMax - TrueNumberOfSurvivors()), Spawn_InfectedBot, _, 0);
					else
					CreateTimer(float(InfectedSpawnTimeMax), Spawn_InfectedBot, _, 0);
				}
			}
		}
		
	}
}

CountInfected()
{
	// reset counters
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	
	// First we count the ammount of infected real players and bots
	for (new i=1;i<=MaxClients;i++)
	{
		// We check if player is in game
		if (!IsClientInGame(i)) continue;
		
		// Check if client is infected ...
		if (GetClientTeam(i) == TEAM_INFECTED)
		{
			// If player is a bot ...
			if (IsFakeClient(i))
				InfectedBotCount++;
			else
			InfectedRealCount++;
		}
	}
	
}

// This event serves to make sure the bots spawn at the start of the finale event. The director disallows spawning until the survivors have started the event, so this was
// definitely needed.
public Action:evtFinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, CheckIfBotsNeededLater, true);
}

BotTimePrepare()
{
	CreateTimer(1.0, BotTypeTimer)
	
	return 0;
}

public Action:BotTypeTimer (Handle:timer)
{
	BotTypeNeeded()
}

BotTypeNeeded()
{
	#if DEBUGSERVER
	LogMessage("Determining Bot type now");
	#endif
	#if DEBUGCLIENTS
	PrintToChatAll("Determining Bot type now");
	#endif
	
	// current count ...
	new boomers=0;
	new smokers=0;
	new hunters=0;
	new spitters=0;
	new jockeys=0;
	new chargers=0;
	new tanks=0;
	
	for (new i=1;i<=MaxClients;i++)
	{
		// if player is connected and ingame ...
		if (IsClientInGame(i))
		{
			// if player is on infected's team
			if (GetClientTeam(i) == TEAM_INFECTED && PlayerIsAlive(i))
			{
				// We count depending on class ...
				if (IsPlayerSmoker(i))
					smokers++;
				else if (IsPlayerBoomer(i))
					boomers++;	
				else if (IsPlayerHunter(i))
					hunters++;	
				else if (IsPlayerTank(i))
					tanks++;	
				else if (b_IsL4D2 && IsPlayerSpitter(i))
					spitters++;	
				else if (b_IsL4D2 && IsPlayerJockey(i))
					jockeys++;	
				else if (b_IsL4D2 && IsPlayerCharger(i))
					chargers++;	
			}
		}
	}
	
	if  (b_IsL4D2)
	{
		new random = GetURandomIntRange(1, 7);
		
		if (random == 2)
		{
			if ((smokers < SmokerLimit) && (canSpawnSmoker))
			{
				#if DEBUGSERVER
				LogMessage("Bot type returned Smoker");
				#endif
				return 2;
			}
		}
		else if (random == 3)
		{
			if ((boomers < BoomerLimit) && (canSpawnBoomer))
			{
				#if DEBUGSERVER
				LogMessage("Bot type returned Boomer");
				#endif
				return 3;
			}
		}
		else if (random == 1)
		{
			if ((hunters < HunterLimit) && (canSpawnHunter))
			{
				#if DEBUGSERVER
				LogMessage("Bot type returned Hunter");
				#endif
				return 1;
			}
		}
		else if (random == 4)
		{
			if ((spitters < SpitterLimit) && (canSpawnSpitter))
			{
				#if DEBUGSERVER
				LogMessage("Bot type returned Spitter");
				#endif
				return 4;
			}
		}
		else if (random == 5)
		{
			if ((jockeys < JockeyLimit) && (canSpawnJockey))
			{
				#if DEBUGSERVER
				LogMessage("Bot type returned Jockey");
				#endif
				return 5;
			}
		}
		else if (random == 6)
		{
			if ((chargers < ChargerLimit) && (canSpawnCharger))
			{
				#if DEBUGSERVER
				LogMessage("Bot type returned Charger");
				#endif
				return 6;
			}
		}
		
		else if (random == 7)
		{
			if (tanks < TankLimit)
			{
				#if DEBUGSERVER
				LogMessage("Bot type returned Tank");
				#endif
				return 7;
			}
		}
		
		return BotTimePrepare();
	}
	else
	{
		new random = GetURandomIntRange(1, 4);
		
		if (random == 2)
		{
			if ((smokers < SmokerLimit) && (canSpawnSmoker)) // we need a smoker ???? can we spawn a smoker ??? is smoker bot allowed ??
			{
				#if DEBUGSERVER
				LogMessage("Returning Smoker");
				#endif
				return 2;
			}
		}
		else if (random == 3)
		{
			if ((boomers < BoomerLimit) && (canSpawnBoomer))
			{
				#if DEBUGSERVER
				LogMessage("Returning Boomer");
				#endif
				return 3;
			}
		}
		else if (random == 1)
		{
			if (hunters < HunterLimit && canSpawnHunter)
			{
				#if DEBUGSERVER
				LogMessage("Returning Hunter");
				#endif
				return 1;
			}
		}
		
		else if (random == 4)
		{
			if (tanks < GetConVarInt(h_TankLimit))
			{
				#if DEBUGSERVER
				LogMessage("Bot type returned Tank");
				#endif
				return 7;
			}
		}
		
		return BotTimePrepare();
	}
}

public Action:Spawn_InfectedBot(Handle:timer)
{
	// If round has ended, we ignore this request ...
	if (b_HasRoundEnded || !b_HasRoundStarted || !b_LeftSaveRoom) return;
	
	new Infected = MaxPlayerZombies;
	
	if (Coordination && !DirectorSpawn && !InitialSpawn)
	{
		BotReady++;
		
		for (new i=1;i<=MaxClients;i++)
		{
			// We check if player is in game
			if (!IsClientInGame(i)) continue;
			
			// Check if client is infected ...
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a real player 
				if (!IsFakeClient(i))
					Infected--;
			}
		}
		
		if (BotReady >= Infected)
		{
			CreateTimer(3.0, BotReadyReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			InfectedBotQueue--;
			return;
		}
	}
	
	// First we get the infected count
	CountInfected();
	
	// If infected's team is already full ... we ignore this request (a real player connected after timer started ) ..
	if ((InfectedRealCount + InfectedBotCount) >= MaxPlayerZombies || (InfectedRealCount + InfectedBotCount + InfectedBotQueue) > MaxPlayerZombies) 	
	{
		#if DEBUGSERVER
		LogMessage("Infected team is full, Plugin will not spawn a bot");
		#endif
		InfectedBotQueue--;
		return;
	}
	
	// If there is a tank on the field and l4d_infectedbots_spawns_disable_tank is set to 1, the plugin will check for
	// any tanks on the field
	
	if (DisableSpawnsTank)
	{
		for (new i=1;i<=MaxClients;i++)
		{
			// We check if player is in game
			if (!IsClientInGame(i)) continue;
			
			// Check if client is infected ...
			if (GetClientTeam(i)==TEAM_INFECTED)
			{
				// If player is a tank
				if (IsPlayerTank(i) && IsPlayerAlive(i))
				{
					InfectedBotQueue--;
					return;
				}
			}
		}
		
	}
	
	// The bread and butter of this plugin.
	
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i)) // player is connected and is not fake and it's in game ...
		{
			// If player is on infected's team and is dead ..
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
				// If player is a ghost ....
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
					#if DEBUGSERVER
					LogMessage("Player is a ghost, preventing the player from spawning");
					#endif
				}
				else if (!PlayerIsAlive(i)) // if player is just dead
				{
					resetLife[i] = true;
					SetLifeState(i, false);
				}
			}
		}
	}
	
	// We get any client ....
	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (anyclient == -1)
	{
		#if DEBUGSERVER
		LogMessage("[Infected bots] Creating temp client to fake command");
		#endif
		// we create a fake client
		anyclient = CreateFakeClient("Bot");
		if (!anyclient)
		{
			LogError("[L4D] Infected Bots: CreateFakeClient returned 0 -- Infected bot was not spawned");
			return;
		}
		temp = true;
	}
	
	if (b_IsL4D2 && GameMode != 2)
	{
		new bot = CreateFakeClient("Infected Bot");
		if (bot != 0)
		{
			ChangeClientTeam(bot,TEAM_INFECTED);
			CreateTimer(0.1,kickbot,bot);
		}
	}
	
	// Determine the bot class needed ...
	new bot_type = BotTypeNeeded();
	
	// We spawn the bot ...
	switch (bot_type)
	{
		case 0: // Nothing
		{
			#if DEBUGSERVER
			LogMessage("Bot_type returned NOTHING!");
			#endif
		}
		case 1: // Hunter
		{
			#if DEBUGSERVER
			LogMessage("Spawning Hunter");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("Spawning Hunter");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "hunter auto");
		}
		case 2: // Smoker
		{	
			#if DEBUGSERVER
			LogMessage("Spawning Smoker");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("Spawning Smoker");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "smoker auto");
		}
		case 3: // Boomer
		{
			#if DEBUGSERVER
			LogMessage("Spawning Boomer");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("Spawning Boomer");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "boomer auto");
		}
		case 4: // Spitter
		{
			#if DEBUGSERVER
			LogMessage("Spawning Spitter");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("Spawning Spitter");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "spitter auto");
		}
		case 5: // Jockey
		{
			#if DEBUGSERVER
			LogMessage("Spawning Jockey");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("Spawning Jockey");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "jockey auto");
		}
		case 6: // Charger
		{
			#if DEBUGSERVER
			LogMessage("Spawning Charger");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("Spawning Charger");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "charger auto");
		}
		case 7: // Tank
		{
			#if DEBUGSERVER
			LogMessage("Spawning Tank");
			#endif
			#if DEBUGCLIENTS
			PrintToChatAll("Spawning Tank");
			#endif
			CheatCommand(anyclient, "z_spawn_old", "tank auto");
		}
	}
	
	// We restore the player's status
	for (new i=1;i<=MaxClients;i++)
	{
		if (resetGhost[i] == true)
			SetGhostStatus(i, true);
		if (resetLife[i] == true)
			SetLifeState(i, true);
	}
	
	// If client was temp, we setup a timer to kick the fake player
	if (temp) CreateTimer(0.1,kickbot,anyclient);
	
	// Debug print
	#if DEBUGCLIENTS
	PrintToChatAll("Spawning an infected bot. Type = %i ", bot_type);
	#endif
	
	// We decrement the infected queue
	InfectedBotQueue--;
	
	CreateTimer(1.0, CheckIfBotsNeededLater, true);
}

stock GetAnyClient() 
{ 
	for (new target = 1; target <= MaxClients; target++) 
	{ 
		if (IsClientInGame(target)) return target; 
	} 
	return -1; 
} 

public Action:kickbot(Handle:timer, any:client)
{
	if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client)) KickClient(client);
	}
}

bool:IsPlayerGhost (client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
		return true;
	return false;
}

bool:PlayerIsAlive (client)
{
	if (!GetEntProp(client,Prop_Send, "m_lifeState"))
		return true;
	return false;
}

bool:IsPlayerSmoker (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_SMOKER)
		return true;
	return false;
}

bool:IsPlayerBoomer (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_BOOMER)
		return true;
	return false;
}

bool:IsPlayerHunter (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_HUNTER)
		return true;
	return false;
}

bool:IsPlayerSpitter (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_SPITTER)
		return true;
	return false;
}

bool:IsPlayerJockey (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_JOCKEY)
		return true;
	return false;
}

bool:IsPlayerCharger (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_CHARGER)
		return true;
	return false;
}

bool:IsPlayerTank (client)
{
	if(GetEntProp(client,Prop_Send,"m_zombieClass") == ZOMBIECLASS_TANK)
		return true;
	return false;
}

SetGhostStatus (client, bool:ghost)
{
	if (ghost)
		SetEntProp(client, Prop_Send, "m_isGhost", 1);
	else
	SetEntProp(client, Prop_Send, "m_isGhost", 0);
}

SetLifeState (client, bool:ready)
{
	if (ready)
		SetEntProp(client, Prop_Send,  "m_lifeState", 1);
	else
	SetEntProp(client, Prop_Send, "m_lifeState", 0);
}

TrueNumberOfSurvivors ()
{
	new TotalSurvivors;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i))
			if (GetClientTeam(i) == TEAM_SURVIVORS)
				TotalSurvivors++;
		}
	return TotalSurvivors;
}

HumansOnInfected ()
{
	new TotalHumans;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && !IsFakeClient(i))
			TotalHumans++;
	}
	return TotalHumans;
}

bool:LeftStartArea()
{
	new ent = -1, maxents = GetMaxEntities();
	for (new i = MaxClients+1; i <= maxents; i++)
	{
		if (IsValidEntity(i))
		{
			decl String:netclass[64];
			GetEntityNetClass(i, netclass, sizeof(netclass));
			
			if (StrEqual(netclass, "CTerrorPlayerResource"))
			{
				ent = i;
				break;
			}
		}
	}
	
	if (ent > -1)
	{
		if (GetEntProp(ent, Prop_Send, "m_hasAnySurvivorLeftSafeArea"))
		{
			return true;
		}
	}
	return false;
}

stock GetURandomIntRange(min, max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}

stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	new userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

/////////////////////////////////////////////////////////