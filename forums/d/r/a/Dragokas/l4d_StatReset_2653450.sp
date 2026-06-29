#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS		FCVAR_NOTIFY

#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "Statistics Reset",
	author = "Dragokas",
	description = "Reset player statistics on round end",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

/*
	ChangeLog:
	
	1.0 (28-May-2019)
	 - Initial release
*/

char g_sPlayerSave[][] =  // Thanks to SilverShot & cravenge
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
char g_sPlayerSave_L4d2[][] =
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

bool 	g_bLeft4Dead2 = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead) {
	}
	else if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;		
	}
	else {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	g_hCvarEnable = CreateConVar(	"l4d_stat_reset_enable",		"1",					"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS );
	g_hCvarTeamReq = CreateConVar(	"l4d_stat_reset_team",			"4",					"What team should statistics be reset for (4 - Survivors only, 8 - Infected only, 16 - Both)", CVAR_FLAGS );
	CreateConVar(					"l4d_stat_reset_version",		PLUGIN_VERSION,			"Plugin version", FCVAR_DONTRECORD );

	AutoExecConfig(true,			"l4d_stat_reset");

	HookConVarChange(g_hCvarEnable,		ConVarChanged);
	GetCvars();
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
			HookEvent("map_transition",			Event_RoundEnd, 	EventHookMode_Pre);
			HookEvent("finale_win", 			Event_RoundEnd, 	EventHookMode_Pre);
			bHooked = true;
		}
	} else {
		if (bHooked) {
			UnhookEvent("map_transition",		Event_RoundEnd, 	EventHookMode_Pre);
			UnhookEvent("finale_win", 			Event_RoundEnd, 	EventHookMode_Pre);
			bHooked = false;
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && IsTeamComply(i)) {
			ResetStats(i);
		}
	}
}

bool IsTeamComply(int client)
{
	return view_as<bool>((1 << GetClientTeam(client)) & g_iTeamReq);
}

void ResetStats(int client) // Thanks to SilverShot
{
	SetEntPropFloat(client, Prop_Send, "m_maxDeadDuration", 0.0);
	SetEntPropFloat(client, Prop_Send, "m_totalDeadDuration", 0.0);
	
	for( int i = 0; i < sizeof(g_sPlayerSave); i++ )
	{
		SetEntProp(client, Prop_Send, g_sPlayerSave[i], 0);
	}
	if (g_bLeft4Dead2)
	{
		for( int i = 0; i < sizeof(g_sPlayerSave_L4d2); i++ )
		{
			SetEntProp(client, Prop_Send, g_sPlayerSave_L4d2[i], 0);
		}
	}
}
