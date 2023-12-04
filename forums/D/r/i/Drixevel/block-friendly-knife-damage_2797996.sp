#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

ConVar convar_Enabled;

public Plugin myinfo = {
	name = "[CSS/CSGO] Block Friendly Knife Damage",
	author = "Drixevel",
	description = "Blocks friendly knife damage for Terrorists.",
	version = "1.0.0",
	url = "https://drixevel.dev/"
};

public void OnPluginStart() {
	CreateConVar("sm_block_friendly_knife_damage_version", "1.0.0", "Version control for this plugin.", FCVAR_DONTRECORD);
	convar_Enabled = CreateConVar("sm_block_friendly_knife_damage_enabled", "1", "Should this plugin be enabled or disabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	AutoExecConfig();

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype,
							int& weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if (convar_Enabled.BoolValue && attacker > 0 && attacker <= MaxClients && GetClientTeam(victim) == GetClientTeam(attacker) && GetClientTeam(attacker) == CS_TEAM_T && IsKnife(weapon)) {
		damage = 0.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

bool IsKnife(int weapon) {
	if (!IsValidEntity(weapon)) {
		return false;
	}

	char class[32];
	GetEntityClassname(weapon, class, sizeof(class));

	if (StrContains(class, "knife", false) == -1) {
		return false;
	}

	return true;
}