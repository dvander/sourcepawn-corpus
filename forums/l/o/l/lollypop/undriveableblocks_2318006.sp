#include <sdkhooks>
#include <sdktools>

#pragma newdecls required
#pragma semicolon 1

#define PLUGIN_VERSION   "1.0"

public Plugin myinfo = {
	name = "Undriveable Blocks",
	author = "Lollypop",
	version = PLUGIN_VERSION,
	description = "Disables driving moving blocks",
	url = "http://lollypop.nu/"
};

public void OnPluginStart() {
	CreateConVar("sm_undriveable_blocks_version", PLUGIN_VERSION,  "The version of the plugin undrivable blocks by lollypops", FCVAR_REPLICATED|FCVAR_SPONLY|FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}

public void OnEntityCreated(int entity, const char [] classname) {
	if (StrEqual(classname, "func_tracktrain")
		|| StrEqual(classname, "func_tanktrain"))
		SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawned);
}

public void OnEntitySpawned(int entity) {
	if(IsValidEntity(entity)) {
		int flags = GetEntProp(entity, Prop_Data, "m_spawnflags");
		SetEntProp(entity, Prop_Data, "m_spawnflags", flags | 2);
	}
}