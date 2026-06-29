#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0.0"

public Plugin myinfo = {
	name          = "[TF2] Teleporter Gibs Metal Fix",
	author        = "Dr. McKay",
	description   = "Fixes teleporter gibs giving more metal than the teleporter cost after the Meet Your Match update",
	version       = PLUGIN_VERSION,
	url           = "http://www.doctormckay.com"
};

public void OnEntityCreated(int entity, const char[] classname) {
	if (StrEqual(classname, "tf_ammo_pack")) {
		SDKHook(entity, SDKHook_SpawnPost, OnPackSpawn);
	}
}

public void OnPackSpawn(int entity) {
	char modelName[32];
	GetEntPropString(entity, Prop_Data, "m_ModelName", modelName, sizeof(modelName));
	if (StrEqual(modelName, "models/buildables/gibs/teleport")) {
		SDKHook(entity, SDKHook_Touch, OnTeleGibTouch);
	}
}

public Action OnTeleGibTouch(int entity, int other) {
	if (other < 1 || other > MaxClients) {
		return Plugin_Continue; // not a player
	}
	
	int metalAmount = GetEntProp(other, Prop_Data, "m_iAmmo", _, 3);
	if (metalAmount >= 194) {
		return Plugin_Continue; // They're gonna fill up their metal anway
	}
	
	SetEntProp(other, Prop_Data, "m_iAmmo", metalAmount - 9, _, 3); // remove 9 of the metal they're about to get (works out for EE too)
	return Plugin_Continue;
}