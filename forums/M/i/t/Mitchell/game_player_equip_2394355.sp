#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION 	"1.1.1"

public Plugin:myinfo = {
	name = "Game_Player_Equip Fix",
	author = "Mitch",
	description = "Fixes player stripping",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart() {
	CreateConVar("sm_game_player_equip_version", PLUGIN_VERSION, "Game_Player_Equip Fix", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public OnEntityCreated(entity, const String:classname[]) {
	if(StrEqual(classname, "game_player_equip", false)){
		SDKHook(entity, SDKHook_Spawn, Hook_OnEntitySpawn);
	}
}
public Action:Hook_OnEntitySpawn(entity) {
	if(!(GetEntProp(entity, Prop_Data, "m_spawnflags")&1)) {
		SetEntProp(entity, Prop_Data, "m_spawnflags", GetEntProp(entity, Prop_Data, "m_spawnflags")|2);
	}
	return Plugin_Continue;
}