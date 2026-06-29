#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS		FCVAR_NOTIFY

#define PLUGIN_VERSION "1.5"

public Plugin myinfo = 
{
	name = "RespawnStat",
	author = "Dragokas & SilverShot",
	description = "Save statistics of player on manual respawn doing by any plugin",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

/*
	ChangeLog:
	
	1.5 (05-Dec-2018)
	 - Added additional events to be extra safe in clearing statistics on round start.

	1.4 (17-Sep-2018)
	 - Added the list of L4d2 properties (thanks to cravenge).

	1.3 (15-Sep-2018)
     - The last try to fix annoying bug with moving statistics between rounds.

	1.2 (10-Sep-2018)
     - Finally fix bug with case when previous level stat has loaded on some servers where player_spawn event happens twice for each player.

	1.1 (10-Sep-2018)
	 - Fixed bug when previous level stat has loaded.

	1.0 Alpha (30-May-2018)
	 - Initial release (wrapper for Silvers' SaveLoadStat code)
*/

char g_sPlayerSave[45][] =  // Thanks to SilverShot & cravenge
{
    "m_checkpointAwardCounts",
    "m_missionAwardCounts",
    "m_checkpointZombieKills",
    "m_missionZombieKills",
    "m_checkpointSurvivorDamage",
    "m_missionSurvivorDamage",
    "m_classSpawnCount",
    "m_checkpointMedkitsUsed",
    "m_checkpointPillsUsed",
    "m_missionMedkitsUsed",
    "m_checkpointMolotovsUsed",
    "m_missionMolotovsUsed",
    "m_checkpointPipebombsUsed",
    "m_missionPipebombsUsed",
    "m_missionPillsUsed",
    "m_checkpointDamageTaken",
    "m_missionDamageTaken",
    "m_checkpointReviveOtherCount",
    "m_missionReviveOtherCount",
    "m_checkpointFirstAidShared",
    "m_missionFirstAidShared",
    "m_checkpointIncaps",
    "m_missionIncaps",
    "m_checkpointDamageToTank",
    "m_checkpointDamageToWitch",
    "m_missionAccuracy",
    "m_checkpointHeadshots",
    "m_checkpointHeadshotAccuracy",
    "m_missionHeadshotAccuracy",
    "m_checkpointDeaths",
    "m_missionDeaths",
    "m_checkpointPZIncaps",
    "m_checkpointPZTankDamage",
    "m_checkpointPZHunterDamage",
    "m_checkpointPZSmokerDamage",
    "m_checkpointPZBoomerDamage",
    "m_checkpointPZKills",
    "m_checkpointPZPounces",
    "m_checkpointPZPushes",
    "m_checkpointPZTankPunches",
    "m_checkpointPZTankThrows",
    "m_checkpointPZHung",
    "m_checkpointPZPulled",
    "m_checkpointPZBombed",
    "m_checkpointPZVomited"
};
char g_sPlayerSave_L4d2[15][] =
{
    "m_checkpointBoomerBilesUsed",
    "m_missionBoomerBilesUsed",
    "m_checkpointAdrenalinesUsed",
    "m_missionAdrenalinesUsed",
    "m_checkpointDefibrillatorsUsed",
    "m_missionDefibrillatorsUsed",
    "m_checkpointMeleeKills",
    "m_missionMeleeKills",
    "m_checkpointPZJockeyDamage",
    "m_checkpointPZSpitterDamage",
    "m_checkpointPZChargerDamage",    
	"m_checkpointPZHighestDmgPounce",
    "m_checkpointPZLongestSmokerGrab",
    "m_checkpointPZLongestJockeyRide",
    "m_checkpointPZNumChargeVictims"
};

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

ConVar 	g_hCvarEnable;
ConVar 	g_hCvarTeamReq;

int 	g_bEnabled;
int 	g_iTeamReq;
int 	g_iPlayerData[MAXPLAYERS+1][sizeof(g_sPlayerSave)];
int 	g_iPlayerData_L4d2[MAXPLAYERS+1][sizeof(g_sPlayerSave_L4d2)];
int 	g_iUserIdBind[MAXPLAYERS+1];

float 	g_fPlayerData[MAXPLAYERS+1][2];

bool 	g_bLockSave[MAXPLAYERS+1];
bool 	g_bDead[MAXPLAYERS+1];
//bool 	g_bLeft4Dead1 = false;
bool 	g_bLeft4Dead2 = false;


public void OnPluginStart()
{
	g_hCvarEnable = CreateConVar(	"l4d_repawn_stat_enable",		"1",					"Enable RespawnStat plugin (1 - On / 0 - Off)", CVAR_FLAGS );
	g_hCvarTeamReq = CreateConVar(	"l4d_repawn_stat_team",			"4",					"What team should statistics be saved for (4 - Survivors only, 8 - Infected only, 16 - Both)", CVAR_FLAGS );
	CreateConVar(					"l4d_repawn_stat_version",		PLUGIN_VERSION,			"RespawnStat plugin version", FCVAR_DONTRECORD );

	AutoExecConfig(true,			"l4d_repawn_stat");

	HookConVarChange(g_hCvarEnable,		ConVarChanged);
	GetCvars();
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead) {
		//g_bLeft4Dead1 = true;
	}
	else if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;		
	}
	else
	{
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_bEnabled = g_hCvarEnable.BoolValue;
	g_iTeamReq = g_hCvarTeamReq.IntValue;
	InitHook();
}

void InitHook()
{
	static bool bHooked;

	if (g_bEnabled) {
		if (!bHooked) {
			HookEvent("player_spawn",		Event_PlayerSpawn);
			HookEvent("player_death",		Event_PlayerDeath);
			HookEvent("round_start", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
			HookEvent("map_transition",		Event_RoundEnd, 	EventHookMode_PostNoCopy);
			HookEvent("round_end",			Event_RoundEnd, 	EventHookMode_PostNoCopy);
			HookEvent("finale_win", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
			HookEvent("mission_lost", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			UnhookEvent("player_spawn",			Event_PlayerSpawn);
			UnhookEvent("player_death",			Event_PlayerDeath);
			UnhookEvent("round_start", 			Event_RoundEnd,		EventHookMode_PostNoCopy);
			UnhookEvent("map_transition",		Event_RoundEnd, 	EventHookMode_PostNoCopy);
			UnhookEvent("round_end",			Event_RoundEnd, 	EventHookMode_PostNoCopy);
			UnhookEvent("finale_win", 			Event_RoundEnd,		EventHookMode_PostNoCopy);
			UnhookEvent("mission_lost", 		Event_RoundEnd,		EventHookMode_PostNoCopy);
			bHooked = false;
		}
	}
}

public Action Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	int client = GetClientOfUserId(UserId);

	if( client > 0 && IsTeamComply(client)) {
		g_bLockSave[client] = true;
		
		// don't load stat on first spawn (stat should be 0)
		if (g_bDead[client])
		{
			g_bDead[client] = false;
			CreateTimer(1.0, Timer_LoadStatDelayed, UserId, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Continue;
}

public Action Timer_LoadStatDelayed(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);

	if( client > 0 && IsClientInGame(client)) {

		// not died in 1.0 sec after spawn?
		if (IsPlayerAlive(client)) {

			// is client <-> UserId binding still actual? , otherwise, it's another player
			if (g_iUserIdBind[client] == UserId)
				LoadStats(client);
		}
	}
	g_bLockSave[client] = false;
}

void ResetDeadState()
{
	for (int i = 1; i <= MaxClients; i++)	
		g_bDead[i] = false;	
}

public void OnMapStart()
{
	ResetDeadState();
}

public void OnMapEnd()
{
	ResetDeadState();
}

public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	ResetDeadState();
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int UserId = event.GetInt("userid");
	if (UserId > 0) {
		int client = GetClientOfUserId(UserId);
		g_bDead[client] = true;

		if( client > 0 && !g_bLockSave[client]) {

			if (IsClientInGame(client) && IsTeamComply(client)) {
				g_iUserIdBind[client] = UserId;
				SaveStats(client);
			}
		}
	}
	return Plugin_Continue;
}

bool IsTeamComply(int client)
{
	return view_as<bool>((1 << GetClientTeam(client)) & g_iTeamReq);
}

void SaveStats(int client) // Thanks to SilverShot
{
	g_fPlayerData[client][0] = GetEntPropFloat(client, Prop_Send, "m_maxDeadDuration");
	g_fPlayerData[client][1] = GetEntPropFloat(client, Prop_Send, "m_totalDeadDuration");
	
	for( int i = 0; i < sizeof(g_iPlayerData[]); i++ )
	{
		g_iPlayerData[client][i] = GetEntProp(client, Prop_Send, g_sPlayerSave[i]);
	}
	if (g_bLeft4Dead2)
	{
		for( int i = 0; i < sizeof(g_iPlayerData_L4d2[]); i++ )
		{
			g_iPlayerData_L4d2[client][i] = GetEntProp(client, Prop_Send, g_sPlayerSave_L4d2[i]);			
		}
	}
}

void LoadStats(int client) // Thanks to SilverShot
{
	SetEntPropFloat(client, Prop_Send, "m_maxDeadDuration", g_fPlayerData[client][0]);
	SetEntPropFloat(client, Prop_Send, "m_totalDeadDuration", g_fPlayerData[client][1]);
 
	for( int i = 0; i < sizeof(g_iPlayerData[]); i++ )
	{
		SetEntProp(client, Prop_Send, g_sPlayerSave[i], g_iPlayerData[client][i]);
	}
	if (g_bLeft4Dead2)
	{
		for( int i = 0; i < sizeof(g_iPlayerData_L4d2[]); i++ )
		{
			SetEntProp(client, Prop_Send, g_sPlayerSave_L4d2[i], g_iPlayerData_L4d2[client][i]);		
		}
	}
}
