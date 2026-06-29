#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

float g_fRoundStartTime;
Handle g_hRoundTimerCvar = INVALID_HANDLE;
Handle g_hFreezeTimeCvar = INVALID_HANDLE;
float g_fSpawnPosition[MAXPLAYERS+1][3];
bool g_bActiveRound = false;
bool g_bBeaconed[MAXPLAYERS+1] = {false, ...};

public OnPluginStart() {
	HookEvent("round_start", Event_roundStart);
	HookEvent("round_end", Event_roundEnd);
	HookEvent("player_spawn", Event_playerSpawn, EventHookMode_Post);
	HookEvent("player_death", Event_playerDeath);
	CreateTimer(1.0, checkTime, INVALID_HANDLE, TIMER_REPEAT);
	g_hRoundTimerCvar = FindConVar("mp_roundtime");
	g_hFreezeTimeCvar = FindConVar("mp_freezetime");
}

public OnClientPutInServer(int client) {
	g_bBeaconed[client] = false;
}

public OnClientDisconnect(int client) {
	g_bBeaconed[client] = false;
}

public Action Event_playerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client < 1 || client > MaxClients) return Plugin_Continue;
	if (!IsClientInGame(client)) return Plugin_Continue;
	if (GetClientTeam(client) < 1) return Plugin_Continue;
	GetEntPropVector(client, Prop_Data, "m_vecOrigin", g_fSpawnPosition[client]);
	if (g_bBeaconed[client]) {
		ServerCommand("sm_beacon #%i", GetClientUserId(client));
		g_bBeaconed[client] = false;
	}
	return Plugin_Continue;
}

public Action Event_playerDeath(Event event, const char[] name, bool dontroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	g_bBeaconed[client] = false;
	return Plugin_Continue;
}

public Action Event_roundStart(Event event, const char[] name, bool dontBroadcast) {
	g_fRoundStartTime = GetGameTime();
	g_bActiveRound = true;
}

public Action Event_roundEnd(Event event, const char[] name, bool dontBroadcast) {
	g_bActiveRound = false;
	removeBeacons();
}

public Action checkTime(Handle timer) {
	if (!g_bActiveRound) return Plugin_Continue;
	float elapsedTime = (GetGameTime() - g_fRoundStartTime);
	int roundTime = (GetConVarInt(g_hRoundTimerCvar) * 60);
	int freezeTime = (GetConVarInt(g_hFreezeTimeCvar));
	float remainingTime = FloatAbs(((float(roundTime) - elapsedTime) + freezeTime));
	if (RoundFloat(remainingTime) == 30) {
		teleportAliveToSpawn();
	} else if (RoundFloat(remainingTime) == 180 && getAlivePlayers() == 2) {
		setBeacons();
	}
	return Plugin_Continue;
}

void setBeacons() {
	ServerCommand("sm_beacon @alive");
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		g_bBeaconed[i] = true;
	}
}

void removeBeacons() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		if (g_bBeaconed[i]) {
			ServerCommand("sm_beacon #%i", GetClientUserId(i));
			g_bBeaconed[i] = false;
		}
	}
}

void teleportAliveToSpawn() {
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		TeleportEntity(i, g_fSpawnPosition[i], NULL_VECTOR, NULL_VECTOR);
	}
}

int getAlivePlayers() {
	int iAlivePlayers = 0;
	for (int i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i)) continue;
		if (!IsPlayerAlive(i)) continue;
		iAlivePlayers++;
	}
	return iAlivePlayers;
}