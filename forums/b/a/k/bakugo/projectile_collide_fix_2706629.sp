#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "TF2 Projectile Collision Fix"
#define PLUGIN_DESC "Fixes some projectiles colliding incorrectly with map geometry"
#define PLUGIN_AUTHOR "Bakugo"
#define PLUGIN_VERSION "1.1.0"
#define PLUGIN_URL "https://steamcommunity.com/profiles/76561198020610103"

public Plugin myinfo = {
	name = PLUGIN_NAME,
	description = PLUGIN_DESC,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

enum struct Projectile {
	int entity;
	float position[3];
}

Projectile projectiles[20];

public void OnPluginStart() {
	CreateConVar("sm_projectile_collide_fix__version", PLUGIN_VERSION, (PLUGIN_NAME ... " - Version"), (FCVAR_NOTIFY|FCVAR_DONTRECORD));
}

public void OnGameFrame() {
	int idx;
	
	for (idx = 0; idx < sizeof(projectiles); idx++) {
		if (projectiles[idx].entity != 0) {
			// save the projectile's position for this frame
			GetEntPropVector(projectiles[idx].entity, Prop_Send, "m_vecOrigin", projectiles[idx].position);
		}
	}
}

public void OnEntityCreated(int entity, const char[] class) {
	int idx;
	
	if (
		StrEqual(class, "tf_projectile_ball_ornament") ||
		StrEqual(class, "tf_projectile_energy_ring") ||
		StrEqual(class, "tf_projectile_balloffire")
	) {
		for (idx = 0; idx < sizeof(projectiles); idx++) {
			if (projectiles[idx].entity == 0) {
				// add this projectile to the list and keep track of it
				projectiles[idx].entity = entity;
				
				SDKHook(entity, SDKHook_Spawn, SDKHookCB_Spawn);
				SDKHook(entity, SDKHook_Touch, SDKHookCB_Touch);
				
				break;
			}
		}
	}
}

public void OnEntityDestroyed(int entity) {
	int idx;
	
	for (idx = 0; idx < sizeof(projectiles); idx++) {
		if (projectiles[idx].entity == entity) {
			projectiles[idx].entity = 0;
		}
	}
}

Action SDKHookCB_Spawn(int entity) {
	int idx;
	
	for (idx = 0; idx < sizeof(projectiles); idx++) {
		if (projectiles[idx].entity == entity) {
			// in case the projectile collides immediately after spawning
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", projectiles[idx].position);
			break;
		}
	}
}

Action SDKHookCB_Touch(int entity, int other) {
	int idx;
	float pos1[3];
	float pos2[3];
	float maxs[3];
	float mins[3];
	
	if (other > MaxClients) {
		for (idx = 0; idx < sizeof(projectiles); idx++) {
			if (projectiles[idx].entity == entity) {
				GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos1);
				
				// roughly predict the projectile's next position
				SubtractVectors(pos1, projectiles[idx].position, pos2);
				ScaleVector(pos2, 1.3);
				AddVectors(pos1, pos2, pos2);
				
				maxs[0] = 5.0;
				mins[0] = (0.0 - maxs[0]);
				maxs[1] = maxs[0]; maxs[2] = maxs[0];
				mins[1] = mins[0]; mins[2] = mins[0];
				
				// check if the projectile will collide with this entity in its next position
				TR_TraceHullFilter(pos1, pos2, mins, maxs, MASK_SOLID, TraceFilter_IncludeSingle, other);
				
				if (TR_DidHit() == false) {
					// trace did not hit, cancel touch
					return Plugin_Handled;
				}
				
				break;
			}
		}
	}
	
	return Plugin_Continue;
}

bool TraceFilter_IncludeSingle(int entity, int contentsmask, any data) {
	return (entity == data);
}
