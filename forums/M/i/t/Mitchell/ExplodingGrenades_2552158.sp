#include <sdkhooks>
#include <sdktools>			

#pragma newdecls required

#define PLUGIN_VERSION 			"1.1.0"
public Plugin myinfo = {
	name = "Exploding grenades",
	author = "IAmACow",
	description = "Makes grenades explode when damaged",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/member.php?u=258233"
};

ConVar cvEnabled;

public void OnPluginStart() {
	CreateConVar("sm_exploding_grenades_version", PLUGIN_VERSION, "", FCVAR_NOTIFY);
	cvEnabled = CreateConVar("sm_exploding_grenades_enabled", "1", "[bool] (0/1) Enable / disable exploding grenades plugin", FCVAR_NOTIFY);
}

public void OnEntityCreated(int entity, const char[] classname) { 
	if(StrEqual(classname, "weapon_hegrenade") && cvEnabled.BoolValue) {
		SDKHook(entity, SDKHook_SpawnPost, OnGrenadeSpawnPost);
	}
}

public void OnGrenadeSpawnPost(int entity) {
	if(IsValidEntity(entity)) {
		SetEntProp(entity, Prop_Data, "m_takedamage", 2);
		SDKHook(entity, SDKHook_OnTakeDamage, OnGrenadeTakeDamage);
	}
}

public Action OnGrenadeTakeDamage(int entity, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
	if(!IsValidEntity(entity)) {
		return Plugin_Continue;
	}
	if(attacker > 0 && attacker <= MaxClients && IsClientInGame(attacker)) {
		float pos[3];
		GetEntPropVector(entity, Prop_Data, "m_vecOrigin", pos);
		AcceptEntityInput(entity, "Kill"); //Kill it only if the attacker that did damage is a valid client, and after we save the position.
		int grenade = CreateEntityByName("hegrenade_projectile");
		if(grenade == -1) {
			return Plugin_Continue;
		}
		SetVariantString("OnUser1 !self,InitializeSpawnFromWorld,,0.0,1");
		AcceptEntityInput(grenade, "AddOutput");
		AcceptEntityInput(grenade, "FireUser1");
		DispatchSpawn(grenade); 
		SetEntPropEnt(grenade, Prop_Data, "m_hThrower", attacker);
		SetEntProp(grenade, Prop_Data, "m_iTeamNum", GetClientTeam(attacker));
		TeleportEntity(grenade, pos, NULL_VECTOR, NULL_VECTOR);
	}
	return Plugin_Continue;
}