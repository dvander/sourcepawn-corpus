#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>

ConVar convar_Enabled;
ConVar convar_Percentage;

public Plugin myinfo = {
	name = "[L4D2] Reduce Bot Damage",
	author = "KeithGDR",
	description = "Reduces the damage Survivor bots do to Infected.",
	version = "1.0.0",
	url = "https://KeithGDR.dev/"
};

public void OnPluginStart() {
	CreateConVar("sm_l4d2_reduce_bot_dmg_version", "1.0.0", "Version control for this plugin.", FCVAR_DONTRECORD);
	convar_Enabled = CreateConVar("sm_l4d2_reduce_bot_dmg_enabled", "1", "Should this plugin be enabled or disabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_Percentage = CreateConVar("sm_l4d2_reduce_bot_dmg_percent", "25", "What percentage should Survivor bots do less to Infected?", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	AutoExecConfig();
}

public void OnConfigsExecuted() {
	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnClientPutInServer(int client) {
	if (convar_Enabled.BoolValue) {
		SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
	}
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype,
							int& weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if (!convar_Enabled.BoolValue) {
		return Plugin_Continue;
	}

	if (IsFakeClient(attacker) && GetClientTeam(attacker) == 2) {
		damage *= (1.0 - (convar_Percentage.FloatValue / 100));
		return Plugin_Changed;
	}

	return Plugin_Continue;
}