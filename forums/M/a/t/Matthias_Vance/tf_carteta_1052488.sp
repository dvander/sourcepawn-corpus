#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

new Handle:hudSync;
new trainWatcher = -1;
new Float:previousSpeed[8];
new previousSpeedCount;
new Float:previousProgress;
new Handle:checkTimer;

new bool:wasHooked;
new bool:lateLoad;
new stage;

public Plugin:myinfo = {
	name = "[TF2] Cart ETA",
	author = "Matthias Vance",
	description = "Displays cart ETA.",
	version = PLUGIN_VERSION,
	url = "http://www.matthiasvance.com/"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) {
	lateLoad = late;
	return APLRes_Success;
}

public FindTrainWatcher() {
	new ent = -1;
	new nodeChar;
	decl String:startNode[64];
	while((ent = FindEntityByClassname(ent, "team_train_watcher")) != -1) {
		GetEntPropString(ent, Prop_Data, "m_iszStartNode", startNode, sizeof(startNode));
		nodeChar = startNode[14];
		if(StringToInt(startNode[14]) == stage || nodeChar == (96 + stage) || nodeChar == (64 + stage)) {
			return ent;
		}
	}
	return -1;
}

public OnPluginStart() {
	CreateConVar("tf2_carteta_version", PLUGIN_VERSION, "Displays cart ETA.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	SetConVarString(FindConVar("tf2_carteta_version"), PLUGIN_VERSION);

	previousSpeedCount = sizeof(previousSpeed);

	hudSync = CreateHudSynchronizer();
}

public OnMapStart() {

	stage = 1;

	checkTimer = INVALID_HANDLE;

	previousProgress = 0.0;
	for(new i = 0; i < previousSpeedCount; i++) {
		previousSpeed[i] = 0.0;
	}

	trainWatcher = FindEntityByClassname(-1, "team_train_watcher");

	if(trainWatcher != -1) {
		HookEvent("teamplay_round_start", event_RoundStart, EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_win", event_RoundWin, EventHookMode_Post);
		wasHooked = true;
	} else {
		if(wasHooked) {
			UnhookEvent("teamplay_round_start", event_RoundStart, EventHookMode_PostNoCopy);
			UnhookEvent("teamplay_round_win", event_RoundWin, EventHookMode_Post);
			wasHooked = false;
		}
	}

}

public Action:event_RoundWin(Handle:event, const String:eventName[], bool:dontBroadcast) {
	if(!bool:GetEventInt(event, "full_round")) {
		stage++;
	} else {
		if(lateLoad) lateLoad = false;
		stage = 1;
	}
	if(checkTimer != INVALID_HANDLE) {
		CloseHandle(checkTimer);
		checkTimer = INVALID_HANDLE;
	}
	return Plugin_Continue;
}

public Action:event_RoundStart(Handle:event, const String:eventName[], bool:dontBroadcast) {
	if(lateLoad) return Plugin_Continue;
	if(trainWatcher == -1) return Plugin_Continue;
	trainWatcher = FindTrainWatcher();
	if(trainWatcher != -1) {
		for(new i = 0; i < previousSpeedCount; i++) {
			previousSpeed[i] = 0.0;
		}
		if(checkTimer != INVALID_HANDLE) CloseHandle(checkTimer);
		checkTimer = CreateTimer(1.0, timer_Check, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
	return Plugin_Continue;
}

public Action:timer_Check(Handle:timer) {

	new Float:currentProgress = GetEntPropFloat(trainWatcher, Prop_Send, "m_flTotalProgress");
	new Float:progressLeft = (1.0 - currentProgress);
	new Float:currentSpeed = (currentProgress - previousProgress);

	// We don't have to do anything if we're not moving forward
	if(currentSpeed <= 0.0) {
		for(new i = 0; i < previousSpeedCount; i++) {
			previousSpeed[i] = 0.0;
		}
		return Plugin_Continue;
	}

	// Shift array, add current entry
	for(new i = 0; i < (previousSpeedCount - 1); i++) {
		previousSpeed[i] = previousSpeed[i + 1];
	}
	previousSpeed[previousSpeedCount - 1] = currentSpeed;

	// Check how many entries we have
	new entryCount = 0;
	for(new i = (previousSpeedCount - 1); i >= 0; i--) {
		if(previousSpeed[i] > 0.0) {
			entryCount++;
		} else {
			break;
		}
	}

	// Calculate average speed
	new Float:averageSpeed = 0.0;
	for(new i = (previousSpeedCount - 1); i >= (previousSpeedCount - entryCount); i--) {
		averageSpeed += previousSpeed[i];
	}
	averageSpeed /= entryCount;

	new Float:arrivalTime = (progressLeft / averageSpeed);

	SetHudTextParams(0.8, 0.85, 1.0, 255, 255, 255, 255);
	for(new client = 1; client <= MaxClients; client++) {
		if(!IsClientInGame(client)) continue;
		ShowSyncHudText(client, hudSync, "ETA : %d s", RoundToCeil(arrivalTime));
	}

	previousProgress = currentProgress;

	/*
	// Basic version of the algorithm (v1.0)
	new Float:currentProgress = GetEntPropFloat(trainWatcher, Prop_Send, "m_flTotalProgress");
	new Float:progressLeft = (1.0 - currentProgress);
	new Float:currentSpeed = (currentProgress - previousProgress);
	new Float:arrivalTime = (progressLeft / currentSpeed);

	SetHudTextParams(0.8, 0.85, 1.0, 255, 255, 255, 255);
	for(new client = 1; client <= MaxClients; client++) {
		if(!IsClientInGame(client)) continue;
		ShowSyncHudText(client, hudSync, "ETA : %d s", RoundToCeil(arrivalTime));
	}

	previousProgress = currentProgress;
	*/

	return Plugin_Continue;
}
