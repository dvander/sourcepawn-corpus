#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION		"1.2.1custom (ddh debug)"

public Plugin:myinfo = {
	name = "[TF2] No Enemies In Spawn",
	author = "Dr. McKay",
	description = "Slays anyone who manages to get into the enemy spawn",
	version = PLUGIN_VERSION,
	url = "http://www.doctormckay.com"
};

new Handle:cvarMessage;

new bool:roundRunning = true;


public OnPluginStart() {
	cvarMessage = CreateConVar("no_enemy_in_spawn_message", "You may not enter the enemy team's spawn.", "Message to display when a player is slayed for entering the enemy spawn (blank for none)");
	LogError("Message convar has been created");
	HookEvent("teamplay_round_start", Event_RoundStart);
	LogError("teamplay_round_start has been hooked");
	HookEvent("teamplay_round_win", Event_RoundEnd);
	LogError("teamplay_round_win has been hooked");
	HookEvent("teamplay_round_stalemate", Event_RoundEnd);
	LogError("teamplay_round_stalemate has been hooked");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast) {
	roundRunning = true;
	LogError("round has started, enabling slaying, and attempting to hook spawn rooms");
	new i = -1;
	while((i = FindEntityByClassname(i, "func_respawnroom")) != -1) {
		SDKHook(i, SDKHook_TouchPost, OnTouchRespawnRoom);
		SDKHook(i, SDKHook_StartTouchPost, OnTouchRespawnRoom);
		LogError("spawnroom has been hooked");
	}
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast) {
	roundRunning = false;
	LogError("round has ended, disabling slaying");
}

public OnTouchRespawnRoom(entity, other) {
	if(other < 1 || other > MaxClients || !IsPlayerAlive(other) || !roundRunning) {
		return;
	}
	if(GetEntProp(entity, Prop_Send, "m_iTeamNum") != GetClientTeam(other)) {
		LogError("player has been detected in enemy spawn, checking command access");
		if (CheckCommandAccess(other, "sm_admin", ADMFLAG_GENERIC)) {
			LogError("client is admin, aborting");
			return;
		}
		ForcePlayerSuicide(other);
		LogError("slay executed, attempting to display message");
		decl String:message[512];
		LogError("string declared");
		GetConVarString(cvarMessage, message, sizeof(message));
		LogError("convar retrieved");
		if(!StrEqual(message, "")) {
			PrintCenterText(other, message);
			LogError("message printed");
		} else {
			LogError("message convar is blank, not printing");
		}
	}
}