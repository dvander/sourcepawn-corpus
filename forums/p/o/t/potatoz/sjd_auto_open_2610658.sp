#pragma semicolon 1
#include <sourcemod>
#include <smartjaildoors>

ConVar g_cvTimer,
	g_cvCheckCT;

public OnPluginStart()
{
	g_cvCheckCT = CreateConVar("sjd_auto_open_ctcheck_delay", "0", "How long after round start to check if there are any CT (in seconds, use 0 to disable)");
	g_cvTimer = CreateConVar("sjd_auto_open_time", "20", "How long after round start to open cell doors automatically (if configured), in seconds");
	HookEvent("round_start", Event_RoundStart);
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast) 
{
	int alivect = 0;

	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
				alivect++;

	if(alivect > 0) 
		CreateTimer((g_cvTimer.IntValue * 1.0), Timer_OpenCells);
	else if(g_cvCheckCT.IntValue > 0) 
		CreateTimer((g_cvCheckCT.IntValue * 1.0), Timer_CheckCT);
	else SJD_OpenDoors();
}

public Action Timer_OpenCells(Handle timer)
{
	if(!SJD_IsCurrentMapConfigured()) 
		return Plugin_Handled;
	
	SJD_OpenDoors();
	PrintToChatAll("[SM] The cells have been opened automatically");
	
	return Plugin_Handled;
}

public Action Timer_CheckCT(Handle timer)
{
	int alivect = 0;

	for (int i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && GetClientTeam(i) == 3 && IsPlayerAlive(i))
				alivect++;

	if(alivect == 0)
		SJD_OpenDoors();
	
	return Plugin_Handled;
}

