#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.2"


public Plugin:myinfo = {
	name = "Egypt Arch Fix",
	author = "Messy Recipe",
	description = "Prevents engineers from building on the arch on Egypt, Stage 2, Point B",
	version = PLUGIN_VERSION,
	url = "http://www.ctpirates.net/"
}

public OnPluginStart() {
	LoadTranslations("common.phrases");
	CreateConVar("sm_egyptarchfix_version", PLUGIN_VERSION, "Egypt Arch Fix Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnMapStart() {
	static bool:hookExists = false;
	decl bool:isEgypt;
	decl String:mapname[128];
	GetCurrentMap(mapname, 128);
	isEgypt = (strcmp(mapname, "cp_egypt_final", false) == 0);
	if (isEgypt && !hookExists) {
		hookExists = HookEventEx("player_builtobject", DestroyArchBuilding);
	} else if (!isEgypt && hookExists) {
		UnhookEvent("player_builtobject", DestroyArchBuilding);
		hookExists = false;
	}
}

public Action:DestroyArchBuilding(Handle:event, String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new entity = GetEventInt(event, "index");
	
	decl Float:minBounds[] = {1860.0, 1430.0, 460.0};
	decl Float:maxBounds[] = {2100.0, 1800.0, 500.0};
	
	if (EntityInBounds(entity, minBounds, maxBounds)) {
		SetVariantInt(9999);
		AcceptEntityInput(entity, "RemoveHealth");
		PrintCenterText(client, "Construction is not allowed at this location");
	}
	
	return Plugin_Handled;
}

public bool:EntityInBounds(entity, Float:minBounds[], Float:maxBounds[]) {
	decl Float:position[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	
	for (new i = 0; i < 3; i++) {
		if (!(minBounds[i] <= position[i] && position[i] <= maxBounds[i])) {
			return false;
		}
	}
	
	return true;
}
