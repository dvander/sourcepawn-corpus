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
#include <left4dhooks>

#define CVAR_FLAGS FCVAR_NOTIFY

#define EASY 1
#define NORMAL 2
#define ADVANCED 3
#define EXPERT 4
#define TEAM_SURVIVOR 2

bool secondTank[MAXPLAYERS];
ConVar g_hCvarEnable, g_hCvarTankChance;

static ConVar hGamemode;
static bool SpawnBlock;
bool g_bEnabled;
int g_iTankrunChance;

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
	CreateConVar("l4d_tank_double_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);

	g_hCvarEnable 		= CreateConVar("l4d_tank_double_enable", 		"1", 	"Enable plugin (1 - Yes, 0 - No)", CVAR_FLAGS );
	g_hCvarTankChance  	= CreateConVar("l4d_tank_double_chance_tankrun", "15",  "Chance in full percent to spawn a second tank in tankrun gamemode", CVAR_FLAGS);

	AutoExecConfig(true, "l4d_tank_double");

	GetCvars();
    hGamemode = FindConVar("mp_gamemode");
	g_hCvarEnable.AddChangeHook(OnCvarChanged);
	g_hCvarTankChance.AddChangeHook(OnCvarChanged);
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	g_iTankrunChance = g_hCvarTankChance.IntValue;
	InitHook();
}

void InitHook()
{
	static bool bHooked;

	if( g_bEnabled ) {
		if( !bHooked ) {
			HookEvent("tank_spawn", 			Event_TankSpawn, 		EventHookMode_Post);
			HookEvent("tank_killed",			Event_TankKilled, 		EventHookMode_Post);
			HookEvent("round_end", 				round_end, EventHookMode_PostNoCopy);
			bHooked = true;
		}
	} else {
		if( bHooked ) {
			UnhookEvent("tank_spawn", 			Event_TankSpawn, 		EventHookMode_Post);
			UnhookEvent("tank_killed", 			Event_TankKilled,       EventHookMode_Post);
			UnhookEvent("round_end", 			round_end, 				EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

int GetDifficultyIndex()
{
	char cDifficulty[16];
	ConVar cvDifficulty = FindConVar("z_difficulty");
	cvDifficulty.GetString(cDifficulty, sizeof(cDifficulty));

	if (StrEqual(cDifficulty, "easy", false))
		return EASY;
	if (StrEqual(cDifficulty, "normal", false))
		return NORMAL;
	if (StrEqual(cDifficulty, "hard", false))
		return ADVANCED;
	if (StrEqual(cDifficulty, "impossible", false))
		return EXPERT;

	return NORMAL;
}

int GetSurvivorCount()
{
	int num = 0;
	for (int i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == TEAM_SURVIVOR && IsPlayerAlive(i))
			num++;
	}
	return num;
}

bool EasyOrNormal()
{
	return GetDifficultyIndex() == EASY || GetDifficultyIndex() == NORMAL;
}

public void Event_TankSpawn(Event hEvent, const char[] name, bool DontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (SpawnBlock || secondTank[client])
	 	return;

	static char sGamemode[64];
	hGamemode.GetString(sGamemode, sizeof(sGamemode));

	if (client && IsClientInGame(client) && L4D_IsCoopMode() && EasyOrNormal() && L4D_IsFinaleActive())
		SpawnSecondTank();

    bool tankrun = StrEqual(sGamemode, "tankrun", false);
	if (client && IsClientInGame(client) && L4D_IsCoopMode() && EasyOrNormal() && GetSurvivorCount() > 4 && !L4D_IsFinaleActive() && !tankrun)
		SpawnSecondTank();

	if (client && IsClientInGame(client) && tankrun && L4D_IsFinaleActive() && GetRandomInt(1, 100) <= g_iTankrunChance)
		SpawnSecondTank();
}

void SpawnSecondTank()
{
	static float fSpawnPos[3];
	bool bFound = L4D_GetRandomPZSpawnPosition(GetRandomSurvivor(1), 8, 30, fSpawnPos);
	if (bFound)
	{
		SpawnBlock = true;
		int tank = L4D2_SpawnTank(fSpawnPos, NULL_VECTOR);
		secondTank[tank] = true;
		LogMessage("Succesfully spawned a second tank");
	}
}

public void Event_TankKilled(Event hEvent, const char[] name, bool DontBroadcast)
{
	int client = GetClientOfUserId(hEvent.GetInt("userid"));
	if (secondTank[client])
	{
		SpawnBlock = false;
		secondTank[client] = false;
		LogMessage("Killed second tank:  %N ", client);
	}
}

void ResetTanks()
{
	SpawnBlock = false;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			secondTank[i] = false;
		}
	}
}

public void round_end(Event hEvent, const char[] name, bool DontBroadcast)
{
	ResetTanks();
}

public void OnMapEnd()
{
	ResetTanks();
}