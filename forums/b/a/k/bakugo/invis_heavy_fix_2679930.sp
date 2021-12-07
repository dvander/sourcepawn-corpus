#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "Invisible Heavy Exploit Fix"
#define PLUGIN_DESC "Prevents the invisible heavy exploit from being used"
#define PLUGIN_AUTHOR "Bakugo"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL ""

public Plugin myinfo = {
	name = PLUGIN_NAME,
	description = PLUGIN_DESC,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
	
}

public void OnMapStart() {
	CreateTimer(0.333, Timer_CheckExploit, _, (TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE));
}

Action Timer_CheckExploit(Handle timer) {
	int idx;
	
	for (idx = 1; idx <= MaxClients; idx++) {
		if (
			IsClientInGame(idx) &&
			IsPlayerAlive(idx) &&
			(TF2_GetPlayerClass(idx) == TFClass_Heavy) &&
			(GetEntProp(idx, Prop_Send, "m_fEffects") & 0x20) // glitched players have EF_NODRAW
		) {
			ForcePlayerSuicide(idx);
			
			if (!IsPlayerAlive(idx)) {
				PrintHintText(idx, "Stop trying to use exploits!");
			}
		}
	}
	
	return Plugin_Continue;
}
