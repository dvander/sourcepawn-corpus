#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION 	"1.0.0"

bool deagleOnly = false;

public Plugin:myinfo = {
	name = "awp_lego_2b no deagle",
	author = "Mitch",
	description = "Fixes player stripping",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() {
	CreateConVar("sm_no_deagle_version", PLUGIN_VERSION, "awp_lego_2b no deagle", FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnMapStart() {
	char mapName[32];
	GetCurrentMap(mapName, sizeof(mapName));
	if(StrContains(mapName, "awp_lego_2b") >= 0) {
		deagleOnly = true;
	} else {
		deagleOnly = false;
	}
}

public OnEntityCreated(entity, const String:classname[]) {
	if(StrEqual(classname, "game_player_equip", false) && deagleOnly){
		SDKHook(entity, SDKHook_Spawn, Hook_OnEntitySpawn);
	}
}

public Action Hook_OnEntitySpawn(int entity) {
	new gpe = CreateEntityByName("game_player_equip");
	DispatchKeyValue(gpe, "weapon_awp", "1");
	DispatchKeyValue(gpe, "weapon_knife", "1");
	DispatchKeyValue(gpe, "spawnflags", "2");
	AcceptEntityInput(entity, "Kill");
	return Plugin_Continue;
}
