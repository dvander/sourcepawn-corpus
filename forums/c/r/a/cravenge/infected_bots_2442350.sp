#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

#define TEAM_SPECTATOR 1
#define TEAM_SURVIVORS 2
#define TEAM_INFECTED 3

#define ZOMBIECLASS_SMOKER 1
#define ZOMBIECLASS_BOOMER 2
#define ZOMBIECLASS_HUNTER 3
#define ZOMBIECLASS_SPITTER 4
#define ZOMBIECLASS_JOCKEY 5
#define ZOMBIECLASS_CHARGER 6

static InfectedRealCount;
static InfectedBotCount;
static InfectedBotQueue;

static GameMode;

static BoomerLimit;
static SmokerLimit;
static HunterLimit;
static SpitterLimit;
static JockeyLimit;
static ChargerLimit;

static MaxPlayerZombies;
static BotReady;
static ZOMBIECLASS_TANK;
static GetSpawnTime[MAXPLAYERS+1];
static PlayersInServer;
static InfectedSpawnTimeMax;
static InfectedSpawnTimeMin;
static InitialSpawnInt;
static TankLimit;

static bool:b_HasRoundStarted;
static bool:b_HasRoundEnded;
static bool:b_LeftSaveRoom;
static bool:canSpawnBoomer;
static bool:canSpawnSmoker;
static bool:canSpawnHunter;
static bool:canSpawnSpitter;
static bool:canSpawnJockey;
static bool:canSpawnCharger;
static bool:DirectorSpawn;
static bool:SpecialHalt;
static bool:PlayerLifeState[MAXPLAYERS+1];
static bool:InitialSpawn;
static bool:b_IsL4D2;
static bool:AlreadyGhosted[MAXPLAYERS+1];
static bool:AlreadyGhostedBot[MAXPLAYERS+1];
static bool:DirectorCvarsModified;
static bool:PlayerHasEnteredStart[MAXPLAYERS+1];
static bool:AdjustSpawnTimes;
static bool:Coordination;
static bool:DisableSpawnsTank;

static Handle:h_BoomerLimit;
static Handle:h_SmokerLimit;
static Handle:h_HunterLimit;
static Handle:h_SpitterLimit;
static Handle:h_JockeyLimit;
static Handle:h_ChargerLimit;
static Handle:h_MaxPlayerZombies;
static Handle:h_InfectedSpawnTimeMax;
static Handle:h_InfectedSpawnTimeMin;
static Handle:h_DirectorSpawn;
static Handle:h_GameMode;
static Handle:h_Coordination;
static Handle:h_idletime_b4slay;
static Handle:h_InitialSpawn;
static Handle:FightOrDieTimer[MAXPLAYERS+1];
static Handle:h_BotGhostTime;
static Handle:h_DisableSpawnsTank;
static Handle:h_TankLimit;
static Handle:h_AdjustSpawnTimes;

public Plugin:myinfo = 
{
	name = "Infected Bots",
	author = "djromero (SkyDavid), MI 5",
	description = "Spawns Infected Bots With Greater Controls.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?p=893938#post893938"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	decl String:GameName[64];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrContains(GameName, "left4dead", false) == -1)
	{
		return APLRes_Failure;
	}
	else if (StrEqual(GameName, "left4dead2", false))
	{
		b_IsL4D2 = true;
	}
	
	return APLRes_Success; 
}

public OnPluginStart()
{
	if (b_IsL4D2)
	{
		ZOMBIECLASS_TANK = 8;
	}
	else
	{
		ZOMBIECLASS_TANK = 5;
	}
	
	CreateConVar("infected_bots_version", PLUGIN_VERSION, "Infected Bots Version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	h_GameMode = FindConVar("mp_gamemode");
	
	h_TankLimit = CreateConVar("infected_bots_tank_limit", "0", "Limit Of Tanks Spawned", FCVAR_SPONLY);
	if (b_IsL4D2)
	{
		h_BoomerLimit = CreateConVar("infected_bots-l4d2_boomer_limit", "2", "Limit Of Boomers Spawned", FCVAR_SPONLY);
		h_SmokerLimit = CreateConVar("infected_bots-l4d2_smoker_limit", "2", "Limit Of Smokers Spawned", FCVAR_SPONLY);
		h_SpitterLimit = CreateConVar("infected_bots-l4d2_spitter_limit", "2", "Limit Of Spitters Spawned", FCVAR_SPONLY);
		h_JockeyLimit = CreateConVar("infected_bots-l4d2_jockey_limit", "2", "Limit Of Jockeys Spawned", FCVAR_SPONLY);
		h_ChargerLimit = CreateConVar("infected_bots-l4d2_charger_limit", "2", "Limit Of Chargers Spawned", FCVAR_SPONLY);
		h_HunterLimit = CreateConVar("infected_bots-l4d2_hunter_limit", "3", "Limit Of Hunters Spawned", FCVAR_SPONLY);
	}
	else
	{
		h_BoomerLimit = CreateConVar("infected_bots-l4d_boomer_limit", "4", "Limit Of Boomers Spawned", FCVAR_SPONLY);
		h_SmokerLimit = CreateConVar("infected_bots-l4d_smoker_limit", "4", "Limit Of Smokers Spawned", FCVAR_SPONLY);
		h_HunterLimit = CreateConVar("infected_bots-l4d_hunter_limit", "5", "Limit Of Hunters Spawned", FCVAR_SPONLY);
	}
	h_MaxPlayerZombies = CreateConVar("infected_bots_max_specials", "13", "Maximum Limit Of Infected Players", FCVAR_SPONLY); 
	h_InfectedSpawnTimeMax = CreateConVar("infected_bots_spawn_time_max", "10", "Maximum Spawn Time Delay Of Infected Bots", FCVAR_SPONLY);
	h_InfectedSpawnTimeMin = CreateConVar("infected_bots_spawn_time_min", "10", "Minimum Spawn Time Delay Of Infected Bots", FCVAR_SPONLY);
	h_DirectorSpawn = CreateConVar("infected_bots_director_spawn_times", "1", "Enable/Disable Director Spawn Timings", FCVAR_SPONLY, true, 0.0, true, 1.0);
	h_Coordination = CreateConVar("infected_bots_coordination", "0", "Enable/Disable Infected Bots Coordination", FCVAR_SPONLY, true, 0.0, true, 1.0);
	h_idletime_b4slay = CreateConVar("infected_bots_lifespan", "60", "Life Span Of Infected Bots", FCVAR_SPONLY);
	h_InitialSpawn = CreateConVar("infected_bots_initial_spawn_timer", "5", "Initial Spawn Time To Spawn Infected Bots", FCVAR_SPONLY);
	h_BotGhostTime = CreateConVar("infected_bots_ghost_time", "2", "Time To Spawn Infected Bots As Ghosts", FCVAR_SPONLY);
	h_DisableSpawnsTank = CreateConVar("infected_bots_spawns_disabled_tank", "1", "Enable/Disable No Infected Bots During Tank Fights", FCVAR_SPONLY, true, 0.0, true, 1.0);
	h_AdjustSpawnTimes = CreateConVar("infected_bots_adjust_spawn_times", "0", "Enable/Disable Spawn Time Adjustments Depending On Both Team Limits", FCVAR_SPONLY, true, 0.0, true, 1.0);
	
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
	
	HookEvent("round_start", OnRoundStart);
	HookEvent("round_end", OnRoundEnd, EventHookMode_Pre);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
	HookEvent("player_team", OnPlayerTeam);
	HookEvent("player_spawn", OnPlayerSpawn);
	HookEvent("create_panic_event", OnCreatePanicEvent);
	HookEvent("finale_start", OnFinaleStart);
	HookEvent("player_bot_replace", OnPlayerBotReplace);
	HookEvent("player_first_spawn", OnFixStart);
	HookEvent("player_entered_start_area", OnFixStart);
	HookEvent("player_entered_checkpoint", OnFixStart);
	HookEvent("player_transitioned", OnFixStart);
	HookEvent("player_left_start_area", OnFixStart);
	HookEvent("player_left_checkpoint", OnFixStart);
	
	AutoExecConfig(true, "infected_bots");
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
		TweakSettings();
		CheckIfBotsNeeded(true, false);
	}
	else
	{
		DirectorStuff();
	}
}

public ConVarGameMode(Handle:convar, const String:oldValue[], const String:newValue[])
{
	GameModeCheck();
	
	if (!DirectorSpawn)
	{
		TweakSettings();
	}
	else
	{
		DirectorStuff();
	}
}

TweakSettings()
{
	ResetCvars();
	
	switch (GameMode)
	{
		case 1:
		{
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
		case 2:
		{
			if (b_IsL4D2)
			{
				SetConVarInt(FindConVar("z_smoker_limit"), 0);
				SetConVarInt(FindConVar("z_boomer_limit"), 0);
				SetConVarInt(FindConVar("z_hunter_limit"), 0);
				SetConVarInt(FindConVar("z_spitter_limit"), 0);
				SetConVarInt(FindConVar("z_jockey_limit"), 0);
				SetConVarInt(FindConVar("z_charger_limit"), 0);
				SetConVarInt(FindConVar("z_jockey_leap_time"), 0);
				SetConVarInt(FindConVar("z_spitter_max_wait_time"), 0);
			}
			else
			{
				SetConVarInt(FindConVar("z_gas_limit"), 999);
				SetConVarInt(FindConVar("z_exploding_limit"), 999);
				SetConVarInt(FindConVar("z_hunter_limit"), 999);
			}
			
			SetConVarFloat(FindConVar("smoker_tongue_delay"), 0.0);
			SetConVarFloat(FindConVar("boomer_vomit_delay"), 0.0);
			SetConVarFloat(FindConVar("boomer_exposed_time_tolerance"), 0.0);
			SetConVarInt(FindConVar("hunter_leap_away_give_up_range"), 0);
			SetConVarInt(FindConVar("z_hunter_lunge_distance"), 5000);
			SetConVarInt(FindConVar("hunter_pounce_ready_range"), 1500);
			SetConVarFloat(FindConVar("hunter_pounce_loft_rate"), 0.055);
			SetConVarFloat(FindConVar("z_hunter_lunge_stagger_time"), 0.0);
		}
		case 3:
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
	
	SetConVarInt(FindConVar("z_attack_flow_range"), 50000);
	SetConVarInt(FindConVar("director_spectate_specials"), 1);
	SetConVarInt(FindConVar("z_spawn_safety_range"), 0);
	SetConVarInt(FindConVar("z_spawn_flow_limit"), 50000);
	DirectorCvarsModified = false;
	if (b_IsL4D2)
	{
		SetConVarInt(FindConVar("versus_special_respawn_interval"), 99999999);
	}
}

ResetCvars()
{
	if (GameMode == 1)
	{
		ResetConVar(FindConVar("director_no_specials"), true, true);
		ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
		ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
		ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
		ResetConVar(FindConVar("boomer_exposed_time_tolerance"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
		ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
		ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_stagger_time"), true, true);
		if (b_IsL4D2)
		{
			ResetConVar(FindConVar("survival_max_smokers"), true, true);
			ResetConVar(FindConVar("survival_max_boomers"), true, true);
			ResetConVar(FindConVar("survival_max_hunters"), true, true);
			ResetConVar(FindConVar("survival_max_spitters"), true, true);
			ResetConVar(FindConVar("survival_max_jockeys"), true, true);
			ResetConVar(FindConVar("survival_max_chargers"), true, true);
			ResetConVar(FindConVar("survival_max_specials"), true, true);
			ResetConVar(FindConVar("z_jockey_leap_time"), true, true);
			ResetConVar(FindConVar("z_spitter_max_wait_time"), true, true);
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
			ResetConVar(FindConVar("z_jockey_leap_time"), true, true);
			ResetConVar(FindConVar("z_spitter_max_wait_time"), true, true);
		}
		else
		{
			ResetConVar(FindConVar("z_gas_limit"), true, true);
			ResetConVar(FindConVar("z_exploding_limit"), true, true);
		}
		ResetConVar(FindConVar("boomer_vomit_delay"), true, true);
		ResetConVar(FindConVar("director_no_specials"), true, true);
		ResetConVar(FindConVar("smoker_tongue_delay"), true, true);
		ResetConVar(FindConVar("hunter_leap_away_give_up_range"), true, true);
		ResetConVar(FindConVar("boomer_exposed_time_tolerance"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_distance"), true, true);
		ResetConVar(FindConVar("hunter_pounce_ready_range"), true, true);
		ResetConVar(FindConVar("hunter_pounce_loft_rate"), true, true);
		ResetConVar(FindConVar("z_hunter_lunge_stagger_time"), true, true);
	}
}

ResetCvarsDirector()
{
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
			SetConVarInt(FindConVar("z_smoker_limit"), 2);
			ResetConVar(FindConVar("z_boomer_limit"), true, true);
			SetConVarInt(FindConVar("z_hunter_limit"), 3);
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

public Action:OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (b_HasRoundStarted)
	{
		return;
	}
	
	b_LeftSaveRoom = false;
	b_HasRoundEnded = false;
	b_HasRoundStarted = true;
	
	GameModeCheck();
	
	if (GameMode == 0)
	{
		return;
	}
	
	new flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
	SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);
	
	CreateTimer(0.4, MaxSpecialsSet);
	
	InfectedBotQueue = 0;
	BotReady = 0;
	SpecialHalt = false;
	InitialSpawn = false;
	
	if (!DirectorSpawn)
	{
		TweakSettings();
	}
	else
	{
		DirectorStuff();
	}
	
	if (GameMode != 3)
	{
		CreateTimer(1.0, PlayerLeftStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:OnFixStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (b_HasRoundEnded)
	{
		return;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || IsFakeClient(client) || PlayerHasEnteredStart[client])
	{
		return;
	}
	
	AlreadyGhosted[client] = false;
	PlayerHasEnteredStart[client] = true;
}

GameModeCheck()
{
	decl String:GameName[16];
	GetConVarString(h_GameMode, GameName, sizeof(GameName));
	if (StrEqual(GameName, "survival", false))
	{
		GameMode = 3;
	}
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false) || StrEqual(GameName, "mutation12", false) || StrEqual(GameName, "mutation13", false) || StrEqual(GameName, "mutation15", false) || StrEqual(GameName, "mutation11", false))
	{
		GameMode = 2;
	}
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false) || StrEqual(GameName, "mutation3", false) || StrEqual(GameName, "mutation9", false) || StrEqual(GameName, "mutation1", false) || StrEqual(GameName, "mutation7", false) || StrEqual(GameName, "mutation10", false) || StrEqual(GameName, "mutation2", false) || StrEqual(GameName, "mutation4", false) || StrEqual(GameName, "mutation5", false) || StrEqual(GameName, "mutation14", false))
	{
		GameMode = 1;
	}
	else
	{
		GameMode = 1;
	}
}

public Action:MaxSpecialsSet(Handle:Timer)
{
	SetConVarInt(FindConVar("z_max_player_zombies"), MaxPlayerZombies);
	return Plugin_Stop;
}

DirectorStuff()
{
	SpecialHalt = false;
	SetConVarInt(FindConVar("z_spawn_safety_range"), 0);
	SetConVarInt(FindConVar("director_spectate_specials"), 1);
	if (b_IsL4D2)
	{
		ResetConVar(FindConVar("versus_special_respawn_interval"), true, true);
	}
	
	if (!DirectorCvarsModified)
	{
		ResetCvarsDirector();
	}
}

public Action:OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!b_HasRoundEnded)
	{
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
	}
}

public OnMapEnd()
{
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
				return Plugin_Stop; 
			}
			
			b_LeftSaveRoom = true;
			
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
			
			CheckIfBotsNeeded(false, true);
			CreateTimer(3.0, InitialSpawnReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	else
	{
		CreateTimer(1.0, PlayerLeftStart, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Stop;
}

public Action:OnCreatePanicEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GameMode == 3)
	{
		if (!b_LeftSaveRoom)
		{
			b_LeftSaveRoom = true;
			
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
			
			CheckIfBotsNeeded(false, true);
			CreateTimer(3.0, InitialSpawnReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action:InitialSpawnReset(Handle:Timer)
{
	InitialSpawn = false;
	return Plugin_Stop;
}

public Action:BotReadyReset(Handle:Timer)
{
	BotReady = 0;
	return Plugin_Stop;
}

public Action:InfectedBotBooterVersus(Handle:Timer)
{
	if (GameMode != 2 || b_IsL4D2)
	{
		return Plugin_Stop;
	}
	
	new total;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
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
		
		for (new i=1; (i<=MaxClients) && (kicked < kick); i++)
		{
			if (IsClientInGame(i) && IsFakeClient(i))
			{
				if (GetClientTeam(i) == TEAM_INFECTED)
				{
					if (!IsPlayerTank(i) || ((IsPlayerTank(i) && !PlayerIsAlive(i))))
					{
						CreateTimer(0.1, kickbot, i);
						
						kicked++;
					}
				}
			}
		}
	}
	
	return Plugin_Stop;
}

public OnClientPutInServer(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	PlayersInServer++;
}

public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}
	
	if (DirectorSpawn && GameMode != 2)
	{
		if (IsPlayerSmoker(client))
		{
			if (IsFakeClient(client))
			{
				if (!SpecialHalt)
				{
					CreateTimer(0.1, kickbot, client);
					
					new BotNeeded = 1;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
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
					
					new BotNeeded = 2;
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
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
					
					new BotNeeded = 3;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
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
					
					new BotNeeded = 4;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
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
					
					new BotNeeded = 5;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
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
					
					new BotNeeded = 6;
					
					CreateTimer(0.2, Spawn_InfectedBot_Director, BotNeeded);
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
	
	if (IsFakeClient(client) && GameMode == 2 && !IsPlayerTank(client))
	{
		CreateTimer(0.1, Timer_SetUpBotGhost, client, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action:OnPlayerBotReplace(Handle:event, const String:name[], bool:dontBroadcast)
{
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	AlreadyGhostedBot[bot] = true;
}

public Action:DisposeOfCowards(Handle:timer, any:coward)
{
	if (IsClientInGame(coward) && IsFakeClient(coward) && GetClientTeam(coward) == TEAM_INFECTED && !IsPlayerTank(coward) && PlayerIsAlive(coward))
	{
		new threats = GetEntProp(coward, Prop_Send, "m_hasVisibleThreats");
		
		if (threats)
		{
			FightOrDieTimer[coward] = INVALID_HANDLE;
			FightOrDieTimer[coward] = CreateTimer(GetConVarFloat(h_idletime_b4slay), DisposeOfCowards, coward);
			return Plugin_Stop;
		}
		else
		{
			CreateTimer(0.1, kickbot, coward);
			if (!DirectorSpawn)
			{
				new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
				
				if (GameMode == 2 && AdjustSpawnTimes && MaxPlayerZombies != HumansOnInfected())
				{
					SpawnTime = SpawnTime / (MaxPlayerZombies - HumansOnInfected());
				}
				else if (GameMode == 1 && AdjustSpawnTimes)
				{
					SpawnTime = SpawnTime - TrueNumberOfSurvivors();
				}
				
				CreateTimer(float(SpawnTime), Spawn_InfectedBot, _, 0);
				InfectedBotQueue++;
			}
		}
	}
	FightOrDieTimer[coward] = INVALID_HANDLE;
	
	return Plugin_Stop;
}

public Action:Timer_SetUpBotGhost(Handle:timer, any:client)
{
	if (IsValidEntity(client))
	{
		if (!AlreadyGhostedBot[client])
		{
			SetGhostStatus(client, true);
			SetEntityMoveType(client, MOVETYPE_NONE);
			CreateTimer(GetConVarFloat(h_BotGhostTime), Timer_RestoreBotGhost, client, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			AlreadyGhostedBot[client] = false;
		}
	}
	
	return Plugin_Stop;
}

public Action:Timer_RestoreBotGhost(Handle:timer, any:client)
{
	if (IsValidEntity(client))
	{
		SetGhostStatus(client, false);
		SetEntityMoveType(client, MOVETYPE_WALK);
	}
	
	return Plugin_Stop;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (b_HasRoundEnded || !b_LeftSaveRoom)
	{
		return Plugin_Continue;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (FightOrDieTimer[client] != INVALID_HANDLE)
	{
		KillTimer(FightOrDieTimer[client]);
		FightOrDieTimer[client] = INVALID_HANDLE;
	}
	
	if (!client || !IsClientInGame(client) || GetClientTeam(client) != TEAM_INFECTED)
	{
		return Plugin_Continue;
	}
	
	if (GetEventBool(event, "victimisbot") && (!DirectorSpawn))
	{
		if (!IsPlayerTank(client))
		{
			new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
			if (AdjustSpawnTimes && MaxPlayerZombies != HumansOnInfected())
			{
				SpawnTime = SpawnTime / (MaxPlayerZombies - HumansOnInfected());
			}
			CreateTimer(float(SpawnTime), Spawn_InfectedBot, _, 0);
			InfectedBotQueue++;
		}
	}
	
	if (IsPlayerTank(client))
	{
		CheckIfBotsNeeded(false, true);
	}
	
	if (GameMode != 2 && DirectorSpawn)
	{
		new SpawnTime = GetURandomIntRange(InfectedSpawnTimeMin, InfectedSpawnTimeMax);
		GetSpawnTime[client] = SpawnTime;
	}
	
	if (IsFakeClient(client) && !IsPlayerSpitter(client))
	{
		CreateTimer(0.1, kickbot, client);
	}
	
	return Plugin_Continue;
}

public Action:Spawn_InfectedBot_Director(Handle:timer, any:BotNeeded)
{
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && (!IsFakeClient(i)))
		{
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
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
		anyclient = CreateFakeClient("Bot");
		if (anyclient == 0)
		{
			return Plugin_Stop;
		}
		temp = true;
	}
	
	SpecialHalt = true;
	
	switch (BotNeeded)
	{
		case 1: CheatCommand(anyclient, "z_spawn_old", "smoker auto");
		case 2: CheatCommand(anyclient, "z_spawn_old", "boomer auto");
		case 3: CheatCommand(anyclient, "z_spawn_old", "hunter auto");
		case 4: CheatCommand(anyclient, "z_spawn_old", "spitter auto");
		case 5: CheatCommand(anyclient, "z_spawn_old", "jockey auto");
		case 6: CheatCommand(anyclient, "z_spawn_old", "charger auto");
	}
	
	SpecialHalt = false;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (resetGhost[i])
		{
			SetGhostStatus(i, true);
		}
		
		if (resetLife[i])
		{
			SetLifeState(i, true);
		}
	}
	
	if (temp)
	{
		CreateTimer(0.1, kickbot, anyclient);
	}
	
	return Plugin_Stop;
}

public Action:OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "isbot"))
	{
		return Plugin_Continue;
	}
	
	new newteam = GetEventInt(event, "team");
	new oldteam = GetEventInt(event, "oldteam");
	
	if (!b_HasRoundEnded && b_LeftSaveRoom && GameMode == 2)
	{
		if (oldteam == 3 || newteam == 3)
		{
			CheckIfBotsNeeded(false, false);
		}
		
		if (newteam == 3)
		{
			CreateTimer(1.0, InfectedBotBooterVersus, _, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	PlayerLifeState[client] = false;
	GetSpawnTime[client] = 0;
	AlreadyGhosted[client] = false;
	PlayerHasEnteredStart[client] = false;
	PlayersInServer--;
	
	if (PlayersInServer == 0)
	{
		b_LeftSaveRoom = false;
		b_HasRoundEnded = true;
		b_HasRoundStarted = false;
		DirectorCvarsModified = false;
		
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

public Action:CheckIfBotsNeededLater(Handle:timer, any:spawn_immediately)
{
	CheckIfBotsNeeded(spawn_immediately, false);
	return Plugin_Stop;
}

CheckIfBotsNeeded(bool:spawn_immediately, bool:initial_spawn)
{
	if (!DirectorSpawn)
	{
		if (b_HasRoundEnded || !b_LeftSaveRoom)
		{
			return;
		}
		
		CountInfected();
		
		new diff = MaxPlayerZombies - (InfectedBotCount + InfectedRealCount + InfectedBotQueue);
		
		if (diff > 0)
		{
			for (new i; i<diff; i++)
			{
				if (spawn_immediately)
				{
					InfectedBotQueue++;
					CreateTimer(0.5, Spawn_InfectedBot, _, 0);
				}
				else if (initial_spawn)
				{
					InfectedBotQueue++;
					CreateTimer(float(InitialSpawnInt), Spawn_InfectedBot, _, 0);
				}
				else
				{
					InfectedBotQueue++;
					if (GameMode == 2 && AdjustSpawnTimes && MaxPlayerZombies != HumansOnInfected())
					{
						CreateTimer(float(InfectedSpawnTimeMax) / (MaxPlayerZombies - HumansOnInfected()), Spawn_InfectedBot, _, 0);
					}
					else if (GameMode == 1 && AdjustSpawnTimes)
					{
						CreateTimer(float(InfectedSpawnTimeMax - TrueNumberOfSurvivors()), Spawn_InfectedBot, _, 0);
					}
					else
					{
						CreateTimer(float(InfectedSpawnTimeMax), Spawn_InfectedBot, _, 0);
					}
				}
			}
		}
	}
}

CountInfected()
{
	InfectedBotCount = 0;
	InfectedRealCount = 0;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (!IsClientInGame(i))
		{
			continue;
		}
		
		if (GetClientTeam(i) == TEAM_INFECTED)
		{
			if (IsFakeClient(i))
			{
				InfectedBotCount++;
			}
			else
			{
				InfectedRealCount++;
			}
		}
	}
}

public Action:OnFinaleStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(1.0, CheckIfBotsNeededLater, true);
}

BotTimePrepare()
{
	CreateTimer(1.0, BotTypeTimer);
	
	return 0;
}

public Action:BotTypeTimer(Handle:timer)
{
	BotTypeNeeded();
	return Plugin_Stop;
}

BotTypeNeeded()
{
	new boomers = 0;
	new smokers = 0;
	new hunters = 0;
	new spitters = 0;
	new jockeys = 0;
	new chargers = 0;
	new tanks = 0;
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == TEAM_INFECTED && PlayerIsAlive(i))
			{
				if (IsPlayerSmoker(i))
				{
					smokers++;
				}
				else if (IsPlayerBoomer(i))
				{
					boomers++;
				}
				else if (IsPlayerHunter(i))
				{
					hunters++;
				}
				else if (IsPlayerTank(i))
				{
					tanks++;
				}
				else if (b_IsL4D2 && IsPlayerSpitter(i))
				{
					spitters++;
				}
				else if (b_IsL4D2 && IsPlayerJockey(i))
				{
					jockeys++;
				}
				else if (b_IsL4D2 && IsPlayerCharger(i))
				{
					chargers++;
				}
			}
		}
	}
	if(b_IsL4D2)
	{
		new random = GetURandomIntRange(1, 7);
		
		if (random == 2)
		{
			if ((smokers < SmokerLimit) && (canSpawnSmoker))
			{
				return 2;
			}
		}
		else if (random == 3)
		{
			if ((boomers < BoomerLimit) && (canSpawnBoomer))
			{
				return 3;
			}
		}
		else if (random == 1)
		{
			if ((hunters < HunterLimit) && (canSpawnHunter))
			{
				return 1;
			}
		}
		else if (random == 4)
		{
			if ((spitters < SpitterLimit) && (canSpawnSpitter))
			{
				return 4;
			}
		}
		else if (random == 5)
		{
			if ((jockeys < JockeyLimit) && (canSpawnJockey))
			{
				return 5;
			}
		}
		else if (random == 6)
		{
			if ((chargers < ChargerLimit) && (canSpawnCharger))
			{
				return 6;
			}
		}
		else if (random == 7)
		{
			if (tanks < TankLimit)
			{
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
			if ((smokers < SmokerLimit) && (canSpawnSmoker))
			{
				return 2;
			}
		}
		else if (random == 3)
		{
			if ((boomers < BoomerLimit) && (canSpawnBoomer))
			{
				return 3;
			}
		}
		else if (random == 1)
		{
			if (hunters < HunterLimit && canSpawnHunter)
			{
				return 1;
			}
		}
		else if (random == 4)
		{
			if (tanks < GetConVarInt(h_TankLimit))
			{
				return 7;
			}
		}
		
		return BotTimePrepare();
	}
}

public Action:Spawn_InfectedBot(Handle:timer)
{
	if (b_HasRoundEnded || !b_HasRoundStarted || !b_LeftSaveRoom)
	{
		return Plugin_Stop;
	}
	
	new Infected = MaxPlayerZombies;
	
	if (Coordination && !DirectorSpawn && !InitialSpawn)
	{
		BotReady++;
		
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
				if (!IsFakeClient(i))
				{
					Infected--;
				}
			}
		}
		if (BotReady >= Infected)
		{
			CreateTimer(3.0, BotReadyReset, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else
		{
			InfectedBotQueue--;
			return Plugin_Stop;
		}
	}
	
	CountInfected();
	
	if ((InfectedRealCount + InfectedBotCount) >= MaxPlayerZombies || (InfectedRealCount + InfectedBotCount + InfectedBotQueue) > MaxPlayerZombies) 	
	{
		InfectedBotQueue--;
		return Plugin_Stop;
	}
	
	if (DisableSpawnsTank)
	{
		for (new i=1; i<=MaxClients; i++)
		{
			if (!IsClientInGame(i))
			{
				continue;
			}
			
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
				if (IsPlayerTank(i) && IsPlayerAlive(i))
				{
					InfectedBotQueue--;
					return Plugin_Stop;
				}
			}
		}
	}
	
	new bool:resetGhost[MAXPLAYERS+1];
	new bool:resetLife[MAXPLAYERS+1];
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			if (GetClientTeam(i) == TEAM_INFECTED)
			{
				if (IsPlayerGhost(i))
				{
					resetGhost[i] = true;
					SetGhostStatus(i, false);
				}
				else if (!PlayerIsAlive(i))
				{
					resetLife[i] = true;
					SetLifeState(i, false);
				}
			}
		}
	}
	
	new anyclient = GetAnyClient();
	new bool:temp = false;
	if (anyclient == -1)
	{
		anyclient = CreateFakeClient("Bot");
		if (!anyclient)
		{
			return Plugin_Stop;
		}
		temp = true;
	}
	
	if (b_IsL4D2 && GameMode != 2)
	{
		new bot = CreateFakeClient("Infected Bot");
		if (bot != 0)
		{
			ChangeClientTeam(bot, TEAM_INFECTED);
			CreateTimer(0.1, kickbot, bot);
		}
	}
	
	new bot_type = BotTypeNeeded();
	
	switch (bot_type)
	{
		case 0:
		{
		}
		case 1:
		{
			CheatCommand(anyclient, "z_spawn_old", "hunter auto");
		}
		case 2:
		{
			CheatCommand(anyclient, "z_spawn_old", "smoker auto");
		}
		case 3:
		{
			CheatCommand(anyclient, "z_spawn_old", "boomer auto");
		}
		case 4:
		{
			CheatCommand(anyclient, "z_spawn_old", "spitter auto");
		}
		case 5:
		{
			CheatCommand(anyclient, "z_spawn_old", "jockey auto");
		}
		case 6:
		{
			CheatCommand(anyclient, "z_spawn_old", "charger auto");
		}
		case 7:
		{
			CheatCommand(anyclient, "z_spawn_old", "tank auto");
		}
	}
	
	for (new i=1; i<=MaxClients; i++)
	{
		if (resetGhost[i] == true)
		{
			SetGhostStatus(i, true);
		}
		
		if (resetLife[i] == true)
		{
			SetLifeState(i, true);
		}
	}
	if (temp)
	{
		CreateTimer(0.1, kickbot, anyclient);
	}
	
	InfectedBotQueue--;
	
	CreateTimer(1.0, CheckIfBotsNeededLater, true);
	
	return Plugin_Stop;
}

stock GetAnyClient() 
{ 
	for (new target = 1; target <= MaxClients; target++) 
	{ 
		if (IsClientInGame(target))
		{
			return target;
		}
	} 
	return -1; 
} 

public Action:kickbot(Handle:timer, any:client)
{
	if (IsClientInGame(client) && (!IsClientInKickQueue(client)))
	{
		if (IsFakeClient(client))
		{
			KickClient(client);
		}
	}
	
	return Plugin_Stop;
}

bool:IsPlayerGhost(client)
{
	if (GetEntProp(client, Prop_Send, "m_isGhost"))
	{
		return true;
	}
	return false;
}

bool:PlayerIsAlive(client)
{
	if (!GetEntProp(client, Prop_Send, "m_lifeState"))
	{
		return true;
	}
	return false;
}

bool:IsPlayerSmoker(client)
{
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_SMOKER)
	{
		return true;
	}
	return false;
}

bool:IsPlayerBoomer(client)
{
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_BOOMER)
	{
		return true;
	}
	return false;
}

bool:IsPlayerHunter(client)
{
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_HUNTER)
	{
		return true;
	}
	return false;
}

bool:IsPlayerSpitter(client)
{
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_SPITTER)
	{
		return true;
	}
	return false;
}

bool:IsPlayerJockey(client)
{
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_JOCKEY)
	{
		return true;
	}
	return false;
}

bool:IsPlayerCharger(client)
{
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_CHARGER)
	{
		return true;
	}
	return false;
}

bool:IsPlayerTank(client)
{
	if(GetEntProp(client, Prop_Send, "m_zombieClass") == ZOMBIECLASS_TANK)
	{
		return true;
	}
	return false;
}

SetGhostStatus(client, bool:ghost)
{
	if (ghost)
	{
		SetEntProp(client, Prop_Send, "m_isGhost", 1);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_isGhost", 0);
	}
}

SetLifeState(client, bool:ready)
{
	if(ready)
	{
		SetEntProp(client, Prop_Send,  "m_lifeState", 1);
	}
	else
	{
		SetEntProp(client, Prop_Send, "m_lifeState", 0);
	}
}

TrueNumberOfSurvivors()
{
	new TotalSurvivors;
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) == TEAM_SURVIVORS)
			{
				TotalSurvivors++;
			}
		}
	}
	return TotalSurvivors;
}

HumansOnInfected()
{
	new TotalHumans;
	for (new i=1;i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == TEAM_INFECTED && !IsFakeClient(i))
		{
			TotalHumans++;
		}
	}
	return TotalHumans;
}

bool:LeftStartArea()
{
	new ent = -1, maxents = GetMaxEntities();
	for (new i = MaxClients + 1; i <= maxents; i++)
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
	return (GetURandomInt() % (max - min + 1)) + min;
}

stock CheatCommand(client, String:command[], String:arguments[] = "")
{
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
}

