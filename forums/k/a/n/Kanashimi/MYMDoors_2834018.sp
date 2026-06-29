#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

ConVar g_cvarWaitTime;
ConVar g_cvarCompetitiveMode;

bool g_MapStart;
Handle gH_RestartTimer = null;
Handle g_hEventTimer = null;
int gI_RestartTimerIteration = 0;
int g_iRoundTimer = -1;

public Plugin myinfo = {
	name = "[TF2] Round Start Animation",
	author = "gloom",
	description = "Plays a door opening animation with Round signs. Includes a toggle for competitive mode.",
	version = "2.0.0",
	url = "https://steamcommunity.com/id/OneDeadGloom/"
};

public void OnPluginStart() {
	CreateConVar("sm_round_start_version", "2.0.0", "Version control for this plugin.", FCVAR_DONTRECORD);
	
	// Create the new ConVar for switching modes.
	// 0 = Casual (m_nMatchGroupType 7)
	// 1 = Competitive (m_nMatchGroupType 8)
	g_cvarCompetitiveMode = CreateConVar("sm_round_start_competitive_mode", "0", "Switch to Competitive Mode. 0 = Casual, 1 = Competitive.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	
	g_cvarWaitTime = FindConVar("mp_waitingforplayers_time");

	RegAdminCmd("sm_dooranimation", Command_DoorAnimation, ADMFLAG_RCON, "Shows you the door animation");

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

/**
 * Sets the match group type based on the value of the sm_round_start_competitive_mode cvar.
 */
void SetMatchGroupType() {
	// If g_cvarCompetitiveMode is true (1), set group type to 8 (Competitive). Otherwise, set it to 7 (Casual).
	int groupType = GetConVarBool(g_cvarCompetitiveMode) ? 8 : 7;
	GameRules_SetProp("m_nMatchGroupType", groupType);
}

public void OnClientPutInServer(int client) {
	// Set the match group type based on the cvar setting
	SetMatchGroupType();

	Event event = CreateEvent("client_beginconnect", true);
	if (event != null) {
		event.SetString("source", "matchmaking");
		event.FireToClient(client);
		event.Cancel();
	}
}

public void OnMapStart() {
	g_MapStart = true;
	g_iRoundTimer = FindEntityByClassname(-1, "team_round_timer");
	if (g_iRoundTimer == -1) {
		LogError("Could not find team_round_timer entity.");
	}
}

public void OnMapEnd() {
	StopTimer(gH_RestartTimer);
	StopTimer(g_hEventTimer);
}

public void TF2_OnWaitingForPlayersStart() {
	if (g_iRoundTimer != -1) {
		AcceptEntityInput(g_iRoundTimer, "Disable");
	}
	CreateTimer(5.0, Timer_SetRoundTime);

	if (g_cvarWaitTime != null) {
		float waitTime = GetConVarFloat(g_cvarWaitTime);
		// Check if there is enough time to trigger the events 7 seconds before the end.
		if (waitTime > 7.0) {
			// Create a single timer that will fire 7 seconds before the "waiting for players" period ends.
			g_hEventTimer = CreateTimer(waitTime - 7.0, Timer_TriggerFinalEvents);
		}
	}
}

public void TF2_OnWaitingForPlayersEnd() {
	StopTimer(g_hEventTimer);
}

public Action Timer_SetRoundTime(Handle timer) {
	if (g_iRoundTimer != -1) {
		SetVariantFloat(69.0);
		AcceptEntityInput(g_iRoundTimer, "SetTime", -1, -1, 0);
		AcceptEntityInput(g_iRoundTimer, "Enable");
	}
	return Plugin_Stop;
}

public Action Timer_TriggerFinalEvents(Handle timer) {
	g_hEventTimer = null;

	// 1. Respawn and freeze players.
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && GetClientTeam(i) > 1) {
			TF2_RespawnPlayer(i);
			SetEntityMoveType(i, MOVETYPE_NONE);
		}
	}
	CreateTimer(10.0, Timer_UnfreezePlayers);

	// 2. Start the visual door/countdown animation.
	StartAnimation();
	
	return Plugin_Stop;
}

public Action Timer_UnfreezePlayers(Handle timer) {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			SetEntityMoveType(i, MOVETYPE_WALK);
		}
	}
	return Plugin_Stop;
}

void StartAnimation() {
	if (!g_MapStart) {
		return;
	}
	
	g_MapStart = false;
	StartDoorAnimSequence();
}

void StartDoorAnimSequence() {
	GameRules_SetProp("m_nRoundsPlayed", 0);
	
	// Set the match group type based on the cvar setting
	SetMatchGroupType();

	RequestFrame(Frame_RestartTime);
}

void Frame_RestartTime() {
	gI_RestartTimerIteration = 10;
	StopTimer(gH_RestartTimer);
	gH_RestartTimer = CreateTimer(1.0, Timer_RestartTime, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	TriggerTimer(gH_RestartTimer, true);
}

public Action Timer_RestartTime(Handle timer) {
	Event event = CreateEvent("restart_timer_time");
	if (event != null) {
		event.SetInt("time", gI_RestartTimerIteration);
		event.Fire();
	}

	gI_RestartTimerIteration--;

	if (gI_RestartTimerIteration >= 0) {
		return Plugin_Continue;
	}
	
	gH_RestartTimer = null;
	return Plugin_Stop;
}

// =================================================================================================
// HELPER & UTILITY FUNCTIONS
// =================================================================================================
public Action Command_DoorAnimation(int client, int args) {
	StartDoorAnimSequence();
	return Plugin_Handled;
}

bool StopTimer(Handle& timer) {
	if (timer != null) {
		KillTimer(timer);
		timer = null;
		return true;
	}
	return false;
}