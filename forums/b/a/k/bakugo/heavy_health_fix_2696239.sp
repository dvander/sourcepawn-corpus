#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "TF2 Heavy Health Exploit Fix"
#define PLUGIN_DESC "Fixes an infinite health exploit with the GRUs and other health-draining Heavy melees"
#define PLUGIN_AUTHOR "Bakugo"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL "https://steamcommunity.com/profiles/76561198020610103"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	description = PLUGIN_DESC,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

Handle sdkcall_GetMaxHealth;

public void OnPluginStart() {
	Handle conf;
	
	CreateConVar("sm_heavy_health_fix__version", PLUGIN_VERSION, (PLUGIN_NAME ... " - Version"), (FCVAR_NOTIFY|FCVAR_DONTRECORD));
	
	conf = LoadGameConfigFile("sdkhooks.games");
	
	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(conf, SDKConf_Virtual, "GetMaxHealth");
	PrepSDKCall_SetReturnInfo(SDKType_PlainOldData, SDKPass_Plain);
	sdkcall_GetMaxHealth = EndPrepSDKCall();
	
	CloseHandle(conf);
	
	if (sdkcall_GetMaxHealth == null) {
		SetFailState("Failed to create sdkcall_GetMaxHealth");
	}
}

public void OnMapStart() {
	CreateTimer(1.0, Timer_CheckExploit, _, (TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE));
}

Action Timer_CheckExploit(Handle timer) {
	int idx;
	
	for (idx = 1; idx <= MaxClients; idx++) {
		if (
			IsClientInGame(idx) &&
			IsPlayerAlive(idx) &&
			(TF2_GetPlayerClass(idx) == TFClass_Heavy) &&
			(SDKCall(sdkcall_GetMaxHealth, idx) == 1)
		) {
			ForcePlayerSuicide(idx);
		}
	}
	
	return Plugin_Continue;
}
