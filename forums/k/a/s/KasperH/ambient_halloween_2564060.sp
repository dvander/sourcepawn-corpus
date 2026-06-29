#include <sourcemod>
#include <sdktools>
#include <mystocks>
#include <autoexecconfig>
#include <emitsoundany>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_VERSION "1.1"

ConVar gc_bFog;
ConVar gc_bFogRandom;
ConVar gc_iFogDensity;
ConVar gc_bHowl;
ConVar gc_fHowlTimer;

int g_iFog = -1;

public Plugin myinfo = {
	name = "Ambient Halloween",
	author = "Hypr",
	description = "Makes your server spooky",
	version = PLUGIN_VERSION,
	url = "https://condolent.xyz"
};

public void OnPluginStart() {
	AutoExecConfig_SetFile("halloween.ambient");
	AutoExecConfig_SetCreateFile(true);
	
	gc_bFog = AutoExecConfig_CreateConVar("sm_halloween_fog", "1", "Enable fog?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_bFogRandom = AutoExecConfig_CreateConVar("sm_halloween_fog_random", "1", "Make the fog random each round?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_iFogDensity = AutoExecConfig_CreateConVar("sm_halloween_fog_density", "0.35", "Max density of the fog", FCVAR_NOTIFY);
	gc_bHowl = AutoExecConfig_CreateConVar("sm_halloween_howl", "1", "Enable howling?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	gc_fHowlTimer = AutoExecConfig_CreateConVar("sm_halloween_howl_timer", "300", "Time in seconds between each howling sound.", FCVAR_NOTIFY, true, 1.0);
	
	AutoExecConfig_ExecuteFile();
	AutoExecConfig_CleanFile();
	
	HookEvent("round_start", OnRoundStart);
}

public void OnMapStart() {
	if(gc_bHowl.IntValue == 1) {
		PrecacheSoundAny("npc/witch/voice/die/female_death_1.wav", true);
		
		CreateTimer(gc_fHowlTimer.FloatValue, HowlTimer, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	if(gc_bFog.IntValue == 1) {
		int iEnt = FindEntityByClassname(-1, "env_fog_controller");
		
		if(iEnt != -1) {
			g_iFog = iEnt;
		} else {
			g_iFog = CreateEntityByName("env_fog_controller");
			DispatchSpawn(g_iFog);
		}
		
		ExecFog();
		if(gc_bFogRandom.IntValue != 1) {
			AcceptEntityInput(g_iFog, "TurnOn");
		} else {
			int rand = GetRandomInt(0, 1);
			
			if(rand == 1)
				AcceptEntityInput(g_iFog, "TurnOn");
			else
				AcceptEntityInput(g_iFog, "TurnOff");
		}
	}
}

public Action HowlTimer(Handle timer) {
	for(int i = 1; i <= MaxClients; i++) EmitSoundToAllAny("npc/witch/voice/die/female_death_1.wav");
	
	return Plugin_Continue;
}

public void ExecFog() {
	if(g_iFog != -1) {
		DispatchKeyValue(g_iFog, "fogblend", "0");
		DispatchKeyValue(g_iFog, "fogcolor", "255 255 255");
		DispatchKeyValue(g_iFog, "fogcolor2", "255 255 255");
		DispatchKeyValueFloat(g_iFog, "fogstart", 250.0);
		DispatchKeyValueFloat(g_iFog, "fogend", 350.0);
		DispatchKeyValueFloat(g_iFog, "fogmaxdensity", gc_iFogDensity.FloatValue);
	}
}