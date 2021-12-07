#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1
#pragma newdecls required

#define PLUGIN_NAME "Wrangler Through Walls Fix"
#define PLUGIN_DESC "Prevents sentries from shooting through walls when wrangled"
#define PLUGIN_AUTHOR "Bakugo"
#define PLUGIN_VERSION "1.0.0"
#define PLUGIN_URL ""

public Plugin myinfo = {
	name = PLUGIN_NAME,
	description = PLUGIN_DESC,
	author = PLUGIN_AUTHOR,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart() {
	CreateConVar("sm_wrangler_wall_fix__version", PLUGIN_VERSION, (PLUGIN_NAME ... " - Version"), (FCVAR_NOTIFY|FCVAR_DONTRECORD));
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_TraceAttack, OnTraceAttack);
}

Action OnTraceAttack(int victim, int& attacker, int& inflictor, float& damage, int& damagetype, int& ammotype, int hitbox, int hitgroup) {
	char class[64];
	float pos1[3];
	float pos2[3];
	
	if (
		attacker >= 1 &&
		attacker <= MaxClients &&
		damagetype == 0x221002
	) {
		GetEntityClassname(inflictor, class, sizeof(class));
		
		if (
			StrEqual(class, "obj_sentrygun") &&
			GetEntProp(inflictor, Prop_Send, "m_iUpgradeLevel") > 1 &&
			GetEntProp(inflictor, Prop_Send, "m_bPlayerControlled") == 1
		) {
			GetEntPropVector(inflictor, Prop_Send, "m_vecOrigin", pos1);
			GetEntPropVector(victim, Prop_Send, "m_vecOrigin", pos2);
			
			pos1[2] += 46.0; // sentry eye height (lv3)
			pos2[2] += 40.0; // player center height (approx)
			
			TR_TraceRayFilter(pos1, pos2, MASK_SOLID, RayType_EndPoint, MyTraceFilter, inflictor);
			
			if (TR_DidHit()) {
				TR_GetEndPosition(pos2);
				
				if (GetVectorDistance(pos1, pos2) < 80.0) {
					return Plugin_Stop;
				}
			}
		}
	}
	
	return Plugin_Continue;
}

bool MyTraceFilter(int entity, int contentsmask, any inflictor) {
	char class[64];
	
	if (entity == inflictor) {
		return false;
	}
	
	if (entity <= MaxClients) {
		return false;
	}
	
	GetEntityClassname(entity, class, sizeof(class));
	
	if (StrContains(class, "prop_", false) == 0) {
		return true;
	}
	
	return false;
}
