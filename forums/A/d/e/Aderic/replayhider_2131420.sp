#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

new Handle:pluginVersion;
new offsetScoreboard;

new replayOffset = -1;
new sourceTVOffset = -1;

#define PLUGIN_VERSION 		"1.3"

public Plugin:myinfo = 
{
	name = "Replay/SourceTV Hider",
	author = "Aderic",
	description = "Hides Replay or SourceTV from the spectators listing.",
	version = PLUGIN_VERSION
}

public OnPluginStart() {
	pluginVersion =  CreateConVar("sm_replayhiderversion", 	PLUGIN_VERSION, 		"Current version of the plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY); 
	HookConVarChange(pluginVersion, 	OnPluginVersionChanged);
}
// Blocks changing of the plugin version.
public OnPluginVersionChanged(Handle:cvar, const String:oldVal[], const String:newVal[]) {
	if (StrEqual(newVal, PLUGIN_VERSION, false) == false) {
		SetConVarString(pluginVersion, PLUGIN_VERSION);
	}
}
public OnMapStart() {
	CreateTimer(1.0, Tick_ClientScanner);
}

public Action:Tick_ClientScanner(Handle:timer) {
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientConnected(i) == true) {
			if (IsClientReplay(i)) {
				replayOffset = i*4;
			}
			else if (IsClientSourceTV(i)) {
				sourceTVOffset = i*4;
			}
		}
	}
	
	if (replayOffset != -1 || sourceTVOffset != -1) {
		offsetScoreboard = FindSendPropOffs("CPlayerResource", "m_bConnected");
		SDKHook(GetPlayerResourceEntity(), SDKHook_ThinkPost, OnThinkPost);
	}
	
	return Plugin_Stop;
}
// Occurs when the scoreboard refreshes
public OnThinkPost(entity) {
	if (replayOffset != -1)
		SetEntData(entity, offsetScoreboard+replayOffset, false, 4);
	
	if (sourceTVOffset != -1)
		SetEntData(entity, offsetScoreboard+sourceTVOffset, false, 4);
}