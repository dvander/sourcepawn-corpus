#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PL_VERSION "1.1"

public Plugin:myinfo = {
	name        = "Intel Timer",
	author      = "EnigmatiK",
	description = "Displays the number of seconds before the intel returns to the base on CTF maps.",
	version     = PL_VERSION,
	url         = "http://theme.freehostia.com/"
}

new Handle:enabled = INVALID_HANDLE; // inteltimer_enabled
new max_clients;
// RED
new Handle:redTimer = INVALID_HANDLE; // timer for RED intel
new Handle:redText = INVALID_HANDLE;  // HUD text sync for RED intel
new Float:redFlag = 0.0;              // time when RED flag was dropped
new redRunner = 0;                    // RED player holding BLU flag
// BLU
new Handle:bluTimer = INVALID_HANDLE; // timer for BLU intel
new Handle:bluText = INVALID_HANDLE;  // HUD text sync for BLU intel
new Float:bluFlag = 0.0;              // time when BLU flag was dropped
new bluRunner = 0;                    // BLU player holding RED flag

public OnPluginStart() {
	CreateConVar("inteltimer_version", PL_VERSION, "Intel Timer plugin for TF2.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	enabled = CreateConVar("inteltimer_enabled", "1", "Enable/disable intel timer plugin for TF2.", FCVAR_PLUGIN|FCVAR_NOTIFY);
	HookConVarChange(enabled, cvar_toggled);
	HookEvent("teamplay_flag_event", FlagEvent);
	HookEvent("teamplay_round_win", ResetTimers);
	HookEvent("teamplay_round_stalemate", ResetTimers);
	//
	redText = CreateHudSynchronizer();
	bluText = CreateHudSynchronizer();
}

public OnMapStart() {
	max_clients = GetMaxClients();
}

public Action:FlagEvent(Handle:event, const String:name[], bool:dontBroadcast) {
	if (!GetConVarBool(enabled)) return Plugin_Continue;
	new type = GetEventInt(event, "eventtype"); // 1 = pickup, 2 = cap, 4 = drop
	new user = GetEventInt(event, "player");
	if (type < 3) { // pickup or cap; remember player (on pickup) & reset timer
		if (type == 1) {
			new team = GetClientTeam(user);
			if (team == 2) redRunner = user;
			if (team == 3) bluRunner = user;
		}
		if (user == redRunner) bluFlag = 0.0;
		if (user == bluRunner) redFlag = 0.0;
	} else if (type == 4) { // dropped; set timer
		if (user == redRunner) {
			redRunner = 0;
			bluFlag = GetEngineTime();
			showBluTimer(INVALID_HANDLE);
			bluTimer = CreateTimer(1.0, showBluTimer, _, TIMER_REPEAT + TIMER_FLAG_NO_MAPCHANGE);
		} else if (user == bluRunner) {
			bluRunner = 0;
			redFlag = GetEngineTime();
			showRedTimer(INVALID_HANDLE);
			redTimer = CreateTimer(1.0, showRedTimer, _, TIMER_REPEAT + TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	return Plugin_Handled;
}

public Action:ResetTimers(Handle:event, const String:name[], bool:dontBroadcast) {
	bluFlag = 0.0;
	redFlag = 0.0;
	return Plugin_Handled;
}

public Action:showBluTimer(Handle:timer) {
	new Float:diff = bluFlag + 60.0 - GetEngineTime();
	if (diff <= 0.0) { // returned
		bluFlag = 0.0;
		return Plugin_Stop;
	}
	decl String:BLU[3];
	Format(BLU, sizeof(BLU), "%d", RoundToNearest(diff));
	SetHudTextParams(0.468, 0.86, 1.1, 0, 0, 255, 255);
	for (new i = 1; i <= max_clients; i++) if (IsClientInGame(i)) ShowSyncHudText(i, bluText, BLU);
	return Plugin_Continue;
}

public Action:showRedTimer(Handle:timer) {
	new Float:diff = redFlag + 60.0 - GetEngineTime();
	if (diff <= 0.0) { // returned
		redFlag = 0.0;
		return Plugin_Stop;
	}
	decl String:RED[3];
	Format(RED, sizeof(RED), "%d", RoundToNearest(diff));
	SetHudTextParams(0.506, 0.86, 1.1, 255, 0, 0, 255);
	for (new i = 1; i <= max_clients; i++) if (IsClientInGame(i)) ShowSyncHudText(i, redText, RED);
	return Plugin_Continue;
}

public cvar_toggled(Handle:convar, const String:oldValue[], const String:newValue[]) {
	if (!GetConVarBool(enabled)) {
		if (redTimer != INVALID_HANDLE) CloseHandle(redTimer);
		if (bluTimer != INVALID_HANDLE) CloseHandle(bluTimer);
	}
}
