#include <sourcemod>
#include <sendproxy>

#pragma semicolon 1
#pragma newdecls required

#define IsValidClient(%0) 				(1 <= %0 <= MaxClients && IsClientInGame(%0) && !IsFakeClient(%0) && !IsClientSourceTV(%0) && !IsClientReplay(%0))
#define PLUGIN_VERSION "1.0"
#define PLUGIN_NAME "CS:GO Native Vote ESP fix (mmcs.pro)"

public Plugin myinfo = {
	name        = PLUGIN_NAME,
	author      = "SAZONISCHE",
	description = "Native Vote fix for ESP/WH for Admins",
	version     = PLUGIN_VERSION,
	url         = "https://mmcs.pro/"
};

public void OnPluginStart() {
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin works only on CS:GO. Disabling plugin...");

	if(GetConVarInt(FindConVar("sv_parallel_packentities")) == 1)
		SetFailState("Please set convar sv_parallel_packentities to 0. Disabling plugin...");

	HookEvent("cs_win_panel_match", EventVote, EventHookMode_PostNoCopy);
}

public Action EventVote(Event event, const char[] name, bool dontBroadcast) {
	for (int i = 1; i <= MaxClients; i++) 
		if (IsValidClient(i))
			if (SendProxy_IsHooked(i, "m_iTeamNum"))
				SendProxy_Unhook(i, "m_iTeamNum", Set_Esp);
}

public Action Set_Esp(int entity, const char[] PropName, int &iValue, int element) {
	if (iValue) {
		iValue = 1;
		return Plugin_Changed;
	}
	return Plugin_Continue;
}
