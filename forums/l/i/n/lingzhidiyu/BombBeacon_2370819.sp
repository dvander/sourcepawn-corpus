#pragma semicolon 1
//#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

Handle g_hBeaconTimer				= INVALID_HANDLE;
float g_vecBeaconOrigin[3];
int g_BeamIndex = -1;

ConVar g_hCvarBeaconRadius			= null;
ConVar g_hCvarBeaconLifetime		= null;
ConVar g_hCvarBeaconWidth			= null;
ConVar g_hCvarBeaconAmplitude		= null;
ConVar g_hCvarBeaconColor			= null;
ConVar g_hCvarBeaconRandomColor		= null;

public Plugin myinfo = {
	name        = "Bomb beacon",
	author      = "lingzhidiyu",
	description = "description",
	version     = "1.0",
	url         = "url"
}

public void OnPluginStart() {
	g_hCvarBeaconRadius			= CreateConVar("bomb_beacon_radius",		"600.0",		"Set beacon radius");
	g_hCvarBeaconLifetime		= CreateConVar("bomb_beacon_lifetime",		"1.0",			"Set beacon lifetime");
	g_hCvarBeaconWidth			= CreateConVar("bomb_beacon_width",			"10.0",			"Set beacon width");
	g_hCvarBeaconAmplitude		= CreateConVar("bomb_beacon_amplitude",		"1.0",			"Set beacon amplitude");
	g_hCvarBeaconColor			= CreateConVar("bomb_beacon_color",			"255 0 0 255",	"Set beacon color");
	g_hCvarBeaconRandomColor	= CreateConVar("bomb_beacon_randomcolor",	"1",			"Set beacon randomcolor");
	AutoExecConfig(true);

	HookEvent("round_start",	OnRoundStart,	EventHookMode_Post);
	HookEvent("bomb_planted",	OnBombPlanted,	EventHookMode_Post);
	HookEvent("bomb_exploded",	OnBombExploded,	EventHookMode_Post);
}

public void OnMapStart() {
	g_BeamIndex = PrecacheModel("materials/sprites/laserbeam.vmt", true);
}

public void OnMapEnd() {
	delete g_hBeaconTimer;
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	delete g_hBeaconTimer;
}

public void OnBombPlanted(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0) {
		return;
	}

	GetClientAbsOrigin(client, g_vecBeaconOrigin);

	Timer_BombBeacon(INVALID_HANDLE);
	g_hBeaconTimer = CreateTimer(1.0, Timer_BombBeacon, _, TIMER_REPEAT);
}


public void OnBombExploded(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client == 0) {
		return;
	}

	delete g_hBeaconTimer;
}

public Action Timer_BombBeacon(Handle timer) {
	int color[4];
	if (GetConVarInt(g_hCvarBeaconRandomColor) == 1) {
		PickRandomColor(color);
	} else {
		GetConVarColor(g_hCvarBeaconColor, color);
	}

	TE_SetupBeamRingPoint(g_vecBeaconOrigin, 10.0, GetConVarFloat(g_hCvarBeaconRadius), g_BeamIndex, -1, 0, 30, GetConVarFloat(g_hCvarBeaconLifetime), GetConVarFloat(g_hCvarBeaconWidth), GetConVarFloat(g_hCvarBeaconAmplitude), color, 0, 0);
	TE_SendToAll();
}

stock void PickRandomColor(int color[4], int min = 1, int max = 255, int alpha = 255) {
	color[0] = GetRandomInt(min, max);
	color[1] = GetRandomInt(min, max);
	color[2] = GetRandomInt(min, max);
	if (alpha == -1) {
		color[3] = GetRandomInt(min, max);
	} else {
		color[3] = alpha;
	}
}

stock bool GetConVarColor(const Handle convar, int color[4]) {
	char szColor[4][16];
	GetConVarString(g_hCvarBeaconColor, szColor[0], sizeof(szColor[]));

	if (ExplodeString(szColor[0], " ", szColor, 4, sizeof(szColor[])) == 4) {
		color[0] = StringToInt(szColor[0]);
		color[1] = StringToInt(szColor[1]);
		color[2] = StringToInt(szColor[2]);
		color[3] = StringToInt(szColor[3]);

		return true;
	}

	return false;
}