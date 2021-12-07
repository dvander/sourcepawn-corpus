#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

ConVar timeExtend;

public Plugin myinfo =
{
	name = "",
	author = "",
	description = "",
	version = "",
	url = ""
};

public OnPluginStart()
{
	HookEvent("teamplay_point_captured", OnCapture);
	timeExtend = CreateConVar("sm_time_extend", "10", "The time the map extends when cp is captured");
	AutoExecConfig(true, "cp_capture_extend");
}

public Action OnCapture(Event event, const char[] name, bool dontBroadcast)
{
	int entityTimer = FindEntityByClassname(-1, "team_round_timer");
	if (entityTimer > -1)
	{
		SetVariantInt(timeExtend.IntValue);
		AcceptEntityInput(entityTimer, "AddTime");
	}
	return Plugin_Handled;
}

