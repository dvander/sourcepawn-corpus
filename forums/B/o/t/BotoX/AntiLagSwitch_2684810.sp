#include <sourcemod>
#include <sdktools>
#include <PhysHooks>
#include <dhooks>

#pragma semicolon 1
#pragma newdecls required

#define MAX_MISSED_TICKS 16

public Plugin myinfo =
{
	name 			= "AntiLagSwitch",
	author 			= "BotoX",
	description 	= "",
	version 		= "1.0",
	url 			= ""
};

Handle g_hProcessUsercmds;
Handle g_hRunNullCommand;

int g_LastProcessed[MAXPLAYERS + 1];

public void OnPluginStart()
{
	Handle hGameConf = LoadGameConfigFile("AntiLagSwitch.games");
	if(!hGameConf)
		SetFailState("Failed to load AntiLagSwitch gamedata.");

	// void CBasePlayer::RunNullCommand( void )
	StartPrepSDKCall(SDKCall_Player);
	if(!PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, "RunNullCommand"))
		SetFailState("PrepSDKCall_SetFromConf(hGameConf, SDKConf_Signature, \"RunNullCommand\" failed!");

	g_hRunNullCommand = EndPrepSDKCall();

	int Offset = GameConfGetOffset(hGameConf, "ProcessUsercmds");
	if(Offset == -1)
		SetFailState("Failed to find ProcessUsercmds offset");

	/* void CBasePlayer::ProcessUsercmds( CUserCmd *cmds, int numcmds, int totalcmds,
	int dropped_packets, bool paused ) */
	g_hProcessUsercmds = DHookCreate(Offset, HookType_Entity, ReturnType_Void, ThisPointer_CBaseEntity, Hook_ProcessUsercmds);
	if(g_hProcessUsercmds == INVALID_HANDLE)
		SetFailState("Failed to DHookCreate ProcessUsercmds");

	DHookAddParam(g_hProcessUsercmds, HookParamType_ObjectPtr);	// 1 - CUserCmd *cmds
	DHookAddParam(g_hProcessUsercmds, HookParamType_Int);		// 2 - int numcmds
	DHookAddParam(g_hProcessUsercmds, HookParamType_Int);		// 3 - int totalcmds
	DHookAddParam(g_hProcessUsercmds, HookParamType_Int);		// 4 - int dropped_packets
	DHookAddParam(g_hProcessUsercmds, HookParamType_Bool);		// 5 - bool paused

	delete hGameConf;

	// Late load.
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client))
			OnClientPutInServer(client);
	}
}

public void OnClientPutInServer(int client)
{
	DHookEntity(g_hProcessUsercmds, true, client);
	g_LastProcessed[client] = GetGameTickCount();
}

public void OnClientDisconnect(int client)
{
	g_LastProcessed[client] = 0;
}

public void OnPrePlayerThinkFunctions()
{
	int minimum = GetGameTickCount() - MAX_MISSED_TICKS;
	for(int client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && (IsFakeClient(client) || g_LastProcessed[client] < minimum))
		{
			RunNullCommand(client);
		}
	}
}

public MRESReturn Hook_ProcessUsercmds(int client, Handle hParams)
{
	g_LastProcessed[client] = GetGameTickCount();
}

int RunNullCommand(int client)
{
	return SDKCall(g_hRunNullCommand, client);
}
