#define PLUGIN_VERSION		"1.1"

/*
========================================================================================
	Change Log:

	1.0 (12-Jan-2023)
	- First commit

	1.1 (03-Feb-2023)
	 - Added ConVar "l4d_tank_double_enable" - Enable plugin (1 - Yes, 0 - No)

========================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <liquidHelpers>

ConVar g_hCvarEnable;			bool g_bEnabled;
ConVar g_hExpertEnabled; 		bool g_bExpertEnabled;
ConVar g_hHigherThan4; 			bool g_bHigherThan4;
ConVar g_hHigherThan4Finale;	bool g_bHigherThan4Finale;
ConVar g_hFinaleOnly;			bool g_bFinaleOnly;
ConVar g_hLogging;				bool g_bLogging;
ConVar g_hEnabledSurvival;		bool g_bEnabledSurvival;
ConVar g_hAnnoucement;			bool g_bAnnouncement;
ConVar g_hChance;				int g_iChance;
ConVar g_hMaxActive;			int g_iMaxActive;
ConVar g_hLimitPerRound;		int g_iLimitPerRound;
ConVar g_hDelay;				float g_fDelay;

ConVar cvDifficulty, cvGamemode;

char currentMap[48];
bool expertCheck;
static bool survivalGamemode;
static bool vehicleArrived;
bool tankTracking[MAXPLAYERS + 1];
int tanksSpawned;

public Plugin myinfo =
{
	name = "Tank Double",
	author = "Alex Dragokas",
	description = "Creates second tank when director spawns the tank",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas/"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion EngineCheck = GetEngineVersion();
	if (EngineCheck != Engine_Left4Dead2) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	LoadTranslations("l4d_Tank_Double.phrases");
	CreateConVar("l4d_tank_double_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);

	g_hCvarEnable = 		CreateConVar("l4d_tank_double_enable", 				"1",	"Enable plugin (1 - Yes, 0 - No)", FCVAR_NOTIFY);
	g_hFinaleOnly = 		CreateConVar("l4d_tank_double_enable_finale_only", 	"0", 	"Spawns a double tank on finale only, before the escape vehicle arrives ( 1 - Enabled; 0 - Disabled)", FCVAR_NOTIFY);
	g_hEnabledSurvival =	CreateConVar("l4d_tank_double_enable_survival", 	"0", 	"Enable double tanks on survival gamemode (1 - Yes, 0 - No)", FCVAR_NOTIFY);
	g_hAnnoucement = 		CreateConVar("l4d_tank_double_announce", 			"0", 	"Whether or not to announce the spawn of the second tank", FCVAR_NOTIFY);
	g_hLimitPerRound =		CreateConVar("l4d_tank_double_round_limit", 		"3",  	"How many second tanks can spawn per round", FCVAR_NOTIFY);
	g_hChance =				CreateConVar("l4d_tank_double_chance",				"5", 	"1 in x chance of spawning a second tank, 0 = always", FCVAR_NOTIFY);
	g_hHigherThan4 =		CreateConVar("l4d_tank_double_above_4", 			"1", 	"Always spawn a second tank when alive survivor count is higher than 4, this ignores l4d_tank_double_chance ( 1 - Enabled; 0 - Disabled)", FCVAR_NOTIFY);
	g_hHigherThan4Finale = 	CreateConVar("l4d_tank_double_above_4_finale", 		"0", 	"Always spawn a second tank if player count is higher than 4 on finales, this ignores l4d_tank_double_chance ( 1 - Enabled; 0 - Disabled)", FCVAR_NOTIFY);
	g_hLogging =			CreateConVar("l4d_tank_double_logging", 			"0",	"Logs the steps taken to spawn a second tank to logfile", FCVAR_NONE);
	g_hMaxActive = 			CreateConVar("l4d_tank_double_max_active", 			"2", 	"Do not spawn a second tank when active tanks is higher or equal of this value", FCVAR_NOTIFY);
	g_hExpertEnabled = 		CreateConVar("l4d_tank_double_higher_difficulties", "1", 	"Enable to stop second tanks from appearing at higher difficulties such as advanced or expert ( 1 - Enabled; 0 - Disabled)", FCVAR_NOTIFY);
	g_hDelay =				CreateConVar("l4d_tank_double_delay",				"10", 	"Delay before spawning a second tank, I recommend leaving this 10 minimum, some custom maps already spawns a second tank on the finale, you might end up with more than 2 tanks", FCVAR_NOTIFY);

	cvDifficulty = 			FindConVar("z_difficulty");
	cvGamemode = 			FindConVar("mp_gamemode");

	AutoExecConfig(true, "l4d_tank_double");

	g_hCvarEnable.AddChangeHook(OnCvarChanged);
	g_hEnabledSurvival.AddChangeHook(OnCvarChanged);
	g_hAnnoucement.AddChangeHook(OnCvarChanged);
	g_hLimitPerRound.AddChangeHook(OnCvarChanged);
	g_hHigherThan4.AddChangeHook(OnCvarChanged);
	g_hHigherThan4Finale.AddChangeHook(OnCvarChanged);
	g_hFinaleOnly.AddChangeHook(OnCvarChanged);
	g_hLogging.AddChangeHook(OnCvarChanged);
	g_hChance.AddChangeHook(OnCvarChanged);
	g_hMaxActive.AddChangeHook(OnCvarChanged);
	g_hExpertEnabled.AddChangeHook(OnCvarChanged);
	g_hDelay.AddChangeHook(OnCvarChanged);
	GetCvars();
}

public void OnMapInit(const char[] mapName)
{
	strcopy(currentMap, sizeof(currentMap), mapName);
}

public void OnMapStart()
{
	survivalGamemode = vehicleArrived = false;
	if (CheckGamemode(cvGamemode, "survival") && !g_bEnabledSurvival)
		survivalGamemode = true;
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

public void ChangedDifficulty(Event hEvent, const char[] name, bool DontBroadcast)
{
	expertCheck = g_bExpertEnabled && AdvancedOrExpert(cvDifficulty);
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	g_bEnabledSurvival = g_hEnabledSurvival.BoolValue;
	g_bAnnouncement = g_hAnnoucement.BoolValue;
	g_bHigherThan4 = g_hHigherThan4.BoolValue;
	g_bHigherThan4Finale = g_hHigherThan4Finale.BoolValue;
	g_bFinaleOnly = g_hFinaleOnly.BoolValue;
	g_bLogging = g_hLogging.BoolValue;
	g_iChance = g_hChance.IntValue;
	g_iMaxActive = g_hMaxActive.IntValue;
	g_iLimitPerRound = g_hLimitPerRound.IntValue;
	g_bExpertEnabled = g_hExpertEnabled.BoolValue;
	g_fDelay = g_hDelay.FloatValue;
	expertCheck = g_bExpertEnabled && AdvancedOrExpert(cvDifficulty);
	InitHook();
}

void InitHook()
{
	static bool bHooked;

	if( g_bEnabled ) {
		if( !bHooked ) {
			HookEvent("tank_spawn", 			Event_TankSpawn, 		EventHookMode_Post);
			HookEvent("difficulty_changed", 	ChangedDifficulty,		EventHookMode_Post);
			HookEvent("round_start",			roundStart, 			EventHookMode_Post);
			HookEvent("survival_round_start", 	roundStart, 			EventHookMode_Post);
			bHooked = true;
		}
	} else {
		if( bHooked ) {
			UnhookEvent("tank_spawn", 			Event_TankSpawn, 		EventHookMode_Post);
			UnhookEvent("difficulty_changed", 	ChangedDifficulty,		EventHookMode_Post);
			UnhookEvent("round_start",			roundStart, 			EventHookMode_Post);
			UnhookEvent("survival_round_start", roundStart, 			EventHookMode_Post);
			bHooked = false;
		}
	}
}

public void roundStart(Event hEvent, const char[] name, bool DontBroadcast)
{
	tanksSpawned = 0;
	vehicleArrived = false;
}

public Action L4D2_OnSendInRescueVehicle()
{
	vehicleArrived = true;
	return Plugin_Continue;
}

bool HigherThan4()
{
	int survivor = 0;
	for (int i = 1; i < MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i))
			continue;

		if (OnSurvivorTeam(i))
			survivor++;
	}
	return survivor > 4 && g_bHigherThan4;
}

bool ChanceCheck()
{
	if (g_iChance == 0)
		return true;

	return GetRandomInt(1, g_iChance) == 1;
}

public void Event_TankSpawn(Event hEvent, const char[] name, bool DontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	int entIndex = hEvent.GetInt("tankid");
	bool allowSpawn;

	// Allow spawn under certain conditions
	if (HigherThan4() || ChanceCheck()) {
		allowSpawn = true;
	}

	if ((!IsValidClient(client) || survivalGamemode) && allowSpawn) {
		if (g_bLogging) {
			LogMessage("[%s] Client not valid or it's survival gamemode, not spawning a tank", currentMap);
		}
		allowSpawn = false;
	}

	if (tankTracking[entIndex] && allowSpawn) {
		tankTracking[entIndex] = false;
		if (g_bLogging) {
			LogMessage("[%s] This is a child tank spawned from another tank, ignoring...", currentMap);
		}
		allowSpawn = false;
	}

	if (tanksSpawned < g_iLimitPerRound && g_bFinaleOnly && L4D_IsFinaleActive() && !vehicleArrived && allowSpawn) {
		if (g_bLogging) {
			LogMessage("[%s] Finale detected and rescue vehicle has not arrived yet, spawning a second tank");
		}
		CreateTimer(g_fDelay, SpawnSecondTank, _, TIMER_FLAG_NO_MAPCHANGE);
		return;
	}

	if (!g_bHigherThan4Finale && L4D_IsFinaleActive() && allowSpawn && !HigherThan4() ) {
		if (g_bLogging) {
			LogMessage("[%s] Finale detected, not spawning a second tank", currentMap);
		}
		allowSpawn = false;
	}

	if (expertCheck && allowSpawn) {
		if (g_bLogging) {
			LogMessage("[%s] Advanced or expert detected, not spawning a second tank", currentMap);
		}
		allowSpawn = false;
	}

	if (MoreThanXTanks() && allowSpawn) {
		if (g_bLogging) {
			LogMessage("[%s] %i or more tanks are active, not spawning a second tank", currentMap, g_iMaxActive);
		}
		allowSpawn = false;
	}

	if (tanksSpawned > g_iLimitPerRound && allowSpawn){
		if (g_bLogging) {
			LogMessage("[%s] Reached tank limit of %i, not spawning a second tank", currentMap, g_iLimitPerRound);
		}
	}

	// Spawn the second tank if allowed
	if (allowSpawn) {
		CreateTimer(g_fDelay, SpawnSecondTank, _, TIMER_FLAG_NO_MAPCHANGE);
		if (g_bLogging) {
			LogMessage("[%s] Spawning a second tank in %f seconds", currentMap,  g_fDelay);
		}
	}
}

bool MoreThanXTanks()
{
	int tanks = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (!IsValidClient(i) || !IsPlayerAlive(i))
			continue;

		if (IsTank(i) && !L4D_IsPlayerIncapacitated(i))
			tanks++;
	}
	return tanks >= g_iMaxActive;
}

Action SpawnSecondTank(Handle timer)
{
	static float fSpawnPos[3];

	bool bFound = L4D_GetRandomPZSpawnPosition(GetRandomSurvivor(1), view_as<int>(L4D2ZombieClass_Tank), 30, fSpawnPos);

	if (bFound) {
		int tank = L4D2_SpawnTank(fSpawnPos, NULL_VECTOR);
		if (IsValidEntity(tank)) {
			tankTracking[tank] = true;
		}
		if (g_bAnnouncement) {
			PrintToChatAll("[Double Tanks] %t", "TankSpawn");
		}
		tanksSpawned++;
		return Plugin_Stop;
	}

	return Plugin_Continue;
}