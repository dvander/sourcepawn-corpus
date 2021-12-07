#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define CVAR_FLAGS		FCVAR_NOTIFY

#define PLUGIN_VERSION "3.1"

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
	 - Initial release, based on EntProp-s
	
	2.0 (03-Jun-2019)
	 - New release, based on sdk respawn specific
	
	3.0 (27-Mar-2021)
	 - New release, based on direct sdk call to CTerrorPlayer::ResetCheckpointStats
	 
	3.1 (17-Apr-2021)
	 - Changed default value of "l4d_stat_reset_team" ConVar to handle !afk players. Updated description.
	 * Players who already installed the plugin must do it manually via /cfg/sourcemod/l4d_stat_reset.cfg file!
	 
*/

#define GAMEDATA		"l4d_stat_reset"

#define TEAM_SURVIVOR 2
#define TEAM_INFECTED 3

#define DEBUG 0

ConVar 	g_hCvarEnable;
ConVar 	g_hCvarTeamReq;

int 	g_bEnabled;
int 	g_iTeamReq;

Handle g_hResetStats;

public void OnPluginStart()
{
	CreateConVar(					"l4d_stat_reset_version",		PLUGIN_VERSION,			"Plugin version", FCVAR_DONTRECORD | CVAR_FLAGS );
	g_hCvarEnable = CreateConVar(	"l4d_stat_reset_enable",		"1",					"Enable plugin (1 - On / 0 - Off)", CVAR_FLAGS );
	g_hCvarTeamReq = CreateConVar(	"l4d_stat_reset_team",			"6",					"What team should statistics be reset for (2 - Spectators, 4 - Survivors only, 8 - Infected only. You can combine.)", CVAR_FLAGS );
	
	AutoExecConfig(true,			"l4d_stat_reset");
	
	HookConVarChange(g_hCvarEnable,		ConVarChanged);
	HookConVarChange(g_hCvarTeamReq,	ConVarChanged);
	GetCvars();

	#if DEBUG
	RegConsoleCmd("sm_test", CmdReset, "Resets own statistics immediately");
	#endif
	
	Handle hGameConf = LoadGameConfigFile(GAMEDATA);

	if( hGameConf != INVALID_HANDLE )
	{
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "CTerrorPlayer::ResetCheckpointStats");
		g_hResetStats = EndPrepSDKCall();
		if( g_hResetStats == INVALID_HANDLE ) SetFailState("CTerrorPlayer::ResetCheckpointStats - Signature is broken");
		delete hGameConf;
	}
	else
	{
		SetFailState("Could not find gamedata file at addons/sourcemod/gamedata/%s.txt , you FAILED AT INSTALLING", GAMEDATA);
	}
}

#if DEBUG
public Action CmdReset(int client, int args)
{
	ResetStats(client);
	return Plugin_Handled;
}
#endif

void ResetStats(int client)
{
	SDKCall(g_hResetStats, client);
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

	if( g_bEnabled ) {
		if( !bHooked ) {
			HookEvent("map_transition",			Event_RoundEnd, 	EventHookMode_Pre);
			HookEvent("finale_win", 			Event_RoundEnd, 	EventHookMode_Pre);
			bHooked = true;
		}
	} else {
		if( bHooked ) {
			UnhookEvent("map_transition",		Event_RoundEnd, 	EventHookMode_Pre);
			UnhookEvent("finale_win", 			Event_RoundEnd, 	EventHookMode_Pre);
			bHooked = false;
		}
	}
}

public void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	for( int i = 1; i <= MaxClients; i++ ) {
		if( IsClientInGame(i) && IsTeamComply(i) ) {
			ResetStats(i);
		}
	}
}

bool IsTeamComply(int client)
{
	return view_as<bool>((1 << GetClientTeam(client)) & g_iTeamReq);
}
