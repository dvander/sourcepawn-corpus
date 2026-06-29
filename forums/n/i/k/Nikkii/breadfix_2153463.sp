#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

new bool:g_bEnabled = false;

public Plugin:myinfo = {
	name = "[TF2] Bread Fix",
	author = "Nikki",
	description = "Stops payload bread exploit by disabling bread on payload maps.",
	version = PLUGIN_VERSION
};

public OnPluginStart() {
	CreateConVar("sm_breadfix_version", PLUGIN_VERSION, "BreadFix version.", FCVAR_DONTRECORD|FCVAR_CHEAT|FCVAR_NOTIFY);
}

public OnMapStart() {
	decl String:map[64];
	GetCurrentMap(map, sizeof(map));
	
	if (StrContains(map, "pl_") == 0) {
		g_bEnabled = true;
	} else {
		g_bEnabled = false;
	}
}

public OnEntityCreated(entity, const String:classname[]) {
	if (g_bEnabled && StrEqual(classname, "prop_physics_override")) {
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned); 
	}
}

public OnEntitySpawned(entity) {
	decl String:m_ModelName[PLATFORM_MAX_PATH];
	GetEntPropString(entity, Prop_Data, "m_ModelName", m_ModelName, sizeof(m_ModelName));
	
	if (StrContains(m_ModelName, "c_bread") != -1) {
		AcceptEntityInput(entity, "Kill");
	}
}