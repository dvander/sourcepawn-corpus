#pragma semicolon 1
#pragma newdecls required

#include <sdkhooks>
#include <sdktools>
#include <lvl_ranks>

#define PLUGIN_NAME "Levels Ranks"
#define PLUGIN_AUTHOR "RoadSide Romeo"

int		g_iRankPlayers[MAXPLAYERS+1],
		g_iRankOffset;

public Plugin myinfo = {name = "[LR] Module - FakeRank", author = PLUGIN_AUTHOR, version = PLUGIN_VERSION}
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch(GetEngineVersion())
	{
		case Engine_CSGO: LogMessage("[" ... PLUGIN_NAME ... " Fake Rank] Successfully launched");
		default: SetFailState("[" ... PLUGIN_NAME ... " Fake Rank] Plug-in works only on CS:GO");
	}
}

public void OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
}

public void OnMapStart()
{
	g_iRankOffset = FindSendPropInfo("CCSPlayerResource", "m_iCompetitiveRanking");
	SDKHook(FindEntityByClassname(MaxClients + 1, "cs_player_manager"), SDKHook_ThinkPost, Hook_OnThinkPost);
}

public void OnMapEnd()
{
	SDKUnhook(FindEntityByClassname(MaxClients + 1, "cs_player_manager"), SDKHook_ThinkPost, Hook_OnThinkPost);
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon)
{
	if(buttons & IN_SCORE && !(GetEntProp(client, Prop_Data, "m_nOldButtons") & IN_SCORE))
	{
		Handle hBuffer = StartMessageOne("ServerRankRevealAll", client);
		if(hBuffer != INVALID_HANDLE)
		{
			EndMessage();
		}
	}

	return Plugin_Continue;
}

public void Hook_OnThinkPost(int iEnt)
{
	SetEntDataArray(iEnt, g_iRankOffset, g_iRankPlayers, MAXPLAYERS+1);
}

public void LR_OnLevelChanged(int iClient, int iNewLevel, bool bUp)
{
	g_iRankPlayers[iClient] = iNewLevel;
}

public void PlayerSpawn(Handle hEvent, char[] sEvName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	g_iRankPlayers[iClient] = LR_GetClientInfo(iClient, ST_RANK);
}