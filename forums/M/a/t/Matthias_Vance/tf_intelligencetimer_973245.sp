#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.2"

new flagEntities[4];
new Handle:timers[4];
new Handle:hudSyncs[4];

new Float:timerConfig[4][5] = {
	// Red
	{ 0.506, 0.78, 255.0, 0.0, 0.0 },
	{ 0.506, 0.70, 255.0, 0.0, 0.0 },

	// Blu
	{ 0.468, 0.78, 0.0, 0.0, 255.0 },
	{ 0.468, 0.70, 0.0, 0.0, 255.0 }
};

public Plugin:myinfo = {
	name = "[TF2] Intelligence Timer",
	author = "Matthias Vance",
	description = "Displays reset timers for dropped intelligence.",
	version = PLUGIN_VERSION,
	url = "http://www.matthiasvance.com/"
};

public OnPluginStart() {
	CreateConVar("tf_inteltimer_version", PLUGIN_VERSION, "Displays reset timers for dropped intelligence.", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	SetConVarString(FindConVar("tf_inteltimer_version"), PLUGIN_VERSION);

	HookEvent("teamplay_round_win", stopTimers);
	HookEvent("teamplay_round_stalemate", stopTimers);
}

public OnMapStart() {
	HookEntityOutput("item_teamflag", "OnDrop", eo_FlagDrop);
	HookEntityOutput("item_teamflag", "OnPickUp", eo_FlagPickup);
	HookEntityOutput("item_teamflag", "OnReturn", eo_Return);
	/*
	new ent = -1;
	while((ent = FindEntityByClassname(ent, "item_teamflag")) != -1) {
		PrintToServer("Found the flag!");
		HookSingleEntityOutput(ent, "OnDrop", eo_FlagDrop);
		HookSingleEntityOutput(ent, "OnPickUp", eo_FlagPickup);
	}
	*/
}

public eo_Return(const String:output[], caller, activator, Float:delay) {
	stopTimer(caller);
}

public Action:stopTimers(Handle:event, const String:eventName[], bool:dontBroadcast) {
	new timerCount = sizeof(timers);
	new Handle:timer;
	for(new i = 0; i < timerCount; i++) {
		flagEntities[i] = 0;
		timer = timers[i];
		if(timer != INVALID_HANDLE) CloseHandle(timer);
		timers[i] = INVALID_HANDLE;
	}
}

public eo_FlagDrop(const String:output[], caller, activator, Float:delay) {
	// Check the team
	new m_iTeamNum = GetEntProp(caller, Prop_Send, "m_iTeamNum");
	if(m_iTeamNum == 0) return; // This will be implemented later

	// Get a new flag index
	new indexStart = 0 + (m_iTeamNum - 2) * 2;
	new indexEnd = indexStart + 2;
	new flagIndex = -1;
	for(new i = indexStart; i < indexEnd; i++) {
		if(flagEntities[i] == 0) {
			flagIndex = i;
			break;
		}
	}
	if(flagIndex == -1) return;
	new Handle:dataPack = CreateDataPack();
	WritePackCell(dataPack, flagIndex);

	// Get the reset time
	new Float:m_flMaxResetTime = GetEntPropFloat(caller, Prop_Send, "m_flMaxResetTime");
	WritePackFloat(dataPack, m_flMaxResetTime);

	// Check if we have a HUD synchronizer
	new Handle:hudSync = hudSyncs[flagIndex];
	if(hudSync == INVALID_HANDLE) {
		hudSync = CreateHudSynchronizer();
		if(hudSync == INVALID_HANDLE) return;
		hudSyncs[flagIndex] = hudSync;
	}

	// Create the timer
	flagEntities[flagIndex] = caller;
	new Handle:timer = CreateTimer(1.0, timer_Flag, dataPack, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
	timer_Flag(timer, dataPack);
	timers[flagIndex] = timer;
}

static stopTimer(flag) {
	new flagCount = sizeof(flagEntities);
	for(new i = 0; i < flagCount; i++) {
		if(flagEntities[i] == flag) {
			new Handle:timer = timers[i];
			if(timer != INVALID_HANDLE) CloseHandle(timer);
			flagEntities[i] = 0;
			timers[i] = INVALID_HANDLE;
			break;
		}
	}
}

public eo_FlagPickup(const String:output[], caller, activator, Float:delay) {
	stopTimer(caller);
}

public Action:timer_Flag(Handle:timer, any:data) {
	new Handle:dataPack = data;
	ResetPack(dataPack);

	new flagIndex = ReadPackCell(dataPack);
	new Float:resetTime = ReadPackFloat(dataPack);
	
	if(resetTime > 0) {
		SetHudTextParams(timerConfig[flagIndex][0], timerConfig[flagIndex][1], 1.1, RoundToFloor(timerConfig[flagIndex][2]), RoundToFloor(timerConfig[flagIndex][3]), RoundToFloor(timerConfig[flagIndex][4]), 255);

		new Handle:hudSync = hudSyncs[flagIndex];
		decl String:timerText[8];
		Format(timerText, sizeof(timerText), "%d", RoundToNearest(resetTime));
		for(new i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i)) ShowSyncHudText(i, hudSync, timerText);
		}

		SetPackPosition(dataPack, 8);
		WritePackFloat(dataPack, resetTime - 1.0);
		return Plugin_Continue;
	}
	
	flagEntities[flagIndex] = 0;
	timers[flagIndex] = INVALID_HANDLE;
	
	return Plugin_Stop;
}
