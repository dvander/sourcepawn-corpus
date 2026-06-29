#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define CVAR_FLAGS		FCVAR_NOTIFY

#define PLUGIN_VERSION "0.4"

int 	g_iTankClass, g_iTankCount, g_iTanksCountSpawned, g_iTankCountKicked;
bool 	g_bLateload;
Handle  g_TankCountChanged, g_TankCountSpawnedPerRoundChanged;

public Plugin myinfo = 
{
	name = "[L4D1] Left4dragokas",
	author = "Alex Dragokas",
	description = "Left 4 dead helpers functions and forwards",
	version = PLUGIN_VERSION,
	url = "https://dragokas.com/"
}

/*
	Changelog:
	
	0.1
		- First release
		
	0.2
		- Changed detection method to count kicked tanks
		
	0.3 (28-Jan-2020)
		- Fixed counting tanks on versus (thanks Nuki for report and detailed explanation).
		
	0.4 (05-Jun-2021)
		- Added forward "OnTankCountSpawnedPerRoundChanged" to get info about total number of tanks spawned per this round, excluding those been instantly kicked for some reason.
		- Forward "OnTankCountChanged" is 2 frames delayed to prevent it from firing when the number of tanks is not changed in case tank was instantly kicked via KickClient() command.
		- Some optimizations.
*/

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if( test == Engine_Left4Dead2 )
	{
		g_iTankClass = 8;
	}
	else if( test == Engine_Left4Dead )
	{
		g_iTankClass = 5;
	} 
	else {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateload = late;
	g_TankCountChanged = 					CreateGlobalForward("OnTankCountChanged", ET_Ignore, Param_Cell);
	g_TankCountSpawnedPerRoundChanged = 	CreateGlobalForward("OnTankCountSpawnedPerRoundChanged", ET_Ignore, Param_Cell);
	return APLRes_Success;
}

public void OnPluginStart()
{
	HookEvent("round_start", 			Event_RoundStart,	EventHookMode_PostNoCopy);
	HookEvent("tank_spawn",       		Event_TankSpawn,	EventHookMode_Post);
	
	if( g_bLateload )
	{
		g_iTankCount = GetTanksCount();
		g_iTanksCountSpawned = g_iTankCount;
	}
}

public Action Event_RoundStart(Event hEvent, const char[] name, bool dontBroadcast) 
{
	g_iTankCount = 0;
	g_iTanksCountSpawned = 0;
	g_iTankCountKicked = 0;
}

public void Event_TankSpawn(Event hEvent, const char[] name, bool dontBroadcast) 
{
	RequestFrame(OnTankSpawn_Frame1, hEvent.GetInt("userid"));
}

public void OnTankSpawn_Frame1(int userid)
{
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) )
	{
		RequestFrame(OnTankSpawn_Frame2, userid);
	}
	else {
		g_iTankCountKicked ++;
	}
}

public void OnTankSpawn_Frame2(int userid)
{
	int client = GetClientOfUserId(userid);
	if( client && IsClientInGame(client) )
	{
		g_iTankCount ++;
		g_iTanksCountSpawned ++;
		
		Forward_TankCountChanged(g_iTankCount);
		Forward_TankCountSpawnedPerRoundChanged(g_iTanksCountSpawned);
	}
	else {
		g_iTankCountKicked ++;
	}
}

public void OnClientDisconnect(int client)
{
	if( client && IsTank(client) )
	{
		// KickClient is 1 frame delayed 
		// Our counter is 2 frames delayed
		// OnClientDisconnect should be 3 frames delayed to guarantee correct counter value
	
		RequestFrame(OnClientDisconnect_Frame1);
	}
}

public void OnClientDisconnect_Frame1()
{
	RequestFrame(OnClientDisconnect_Frame2);
}

public void OnClientDisconnect_Frame2()
{
	RequestFrame(OnClientDisconnect_Frame3);
}

public void OnClientDisconnect_Frame3()
{
	if( g_iTankCountKicked <= 0 )
	{
		g_iTankCount --;
		Forward_TankCountChanged(g_iTankCount);
	}
	else {
		g_iTankCountKicked --;
	}
}

int GetTanksCount()
{
	int cnt;
	for( int i = 1; i <= MaxClients; i++ )
		if( IsTank(i) )
			cnt++;
	
	return cnt;
}

stock bool IsTank(int client)
{
	if( client && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) != 2 )
	{
		if( g_iTankClass == GetEntProp(client, Prop_Send, "m_zombieClass"))
			return true;
	}
	return false;
}

void Forward_TankCountChanged(int iCount)
{
	Action result;
	Call_StartForward(g_TankCountChanged);
	Call_PushCell(iCount);
	Call_Finish(result);
}

void Forward_TankCountSpawnedPerRoundChanged(int iCount)
{
	Action result;
	Call_StartForward(g_TankCountSpawnedPerRoundChanged);
	Call_PushCell(iCount);
	Call_Finish(result);
}
