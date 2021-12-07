#pragma semicolon 1
#include <sourcemod>
#include <smartjaildoors>

ConVar g_cvTimer;

public OnPluginStart()
{
	g_cvTimer = CreateConVar("sjd_auto_open_time", "20", "How long after round start to open cell doors automatically (if configured), in seconds");
	HookEvent("round_start", Event_RoundStart);
}

public Action Event_RoundStart(Handle event, char[] name, bool dontBroadcast) 
{
	CreateTimer((g_cvTimer.IntValue*1.0), Timer_OpenCells);
}

public Action Timer_OpenCells(Handle timer)
{
	if(!SJD_IsCurrentMapConfigured()) 
		return Plugin_Handled;
	
	SJD_OpenDoors();
	PrintToChatAll("[SM] The cells have been opened");
	
	return Plugin_Handled;
}

