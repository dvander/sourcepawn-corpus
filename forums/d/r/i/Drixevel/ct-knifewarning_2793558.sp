#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

ConVar convar_Enabled;
ConVar convar_Sound;

public Plugin myinfo = {
	name = "[ANY] CT Knife Warning",
	author = "Drixevel",
	description = "Changes up the knife for CT's to do 1 damage and play a sound.",
	version = "1.0.0",
	url = "https://drixevel.dev/"
};

public void OnPluginStart() {
	CreateConVar("sm_ct_knifewarning_version", "1.0.0", "Version control for this plugin.", FCVAR_DONTRECORD);
	convar_Enabled = CreateConVar("sm_ct_knifewarning_enabled", "1", "Should this plugin be enabled or disabled?", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	convar_Sound = CreateConVar("sm_ct_knifewarning_sound", "ui/deathnotice.wav", "What sound should play to the T who takes the knife damage and CT who does the knife damage?", FCVAR_NOTIFY);
	AutoExecConfig();

	for (int i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i)) {
			OnClientPutInServer(i);
		}
	}
}

public void OnConfigsExecuted() {
	char sSound[PLATFORM_MAX_PATH];
	convar_Sound.GetString(sSound, sizeof(sSound));

	if (strlen(sSound) > 0) {
		ReplaceString(sSound, sizeof(sSound), "sound/", "");
		PrecacheSound(sSound);
		Format(sSound, sizeof(sSound), "sound/%s", sSound);
		AddFileToDownloadsTable(sSound);
	}
}

public void OnClientPutInServer(int client) {
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action OnTakeDamage(int victim, int& attacker, int& inflictor, float& damage, int& damagetype,
							int& weapon, float damageForce[3], float damagePosition[3], int damagecustom) {
	if (!convar_Enabled.BoolValue) {
		return Plugin_Continue;
	}

	if (attacker > 0 && attacker <= MaxClients && GetClientTeam(victim) == CS_TEAM_T && GetClientTeam(attacker) == CS_TEAM_CT && IsKnife(weapon)) {
		
		char sSound[PLATFORM_MAX_PATH];
		convar_Sound.GetString(sSound, sizeof(sSound));

		if (strlen(sSound) > 0) {
			if (StrContains(sSound, "sound/", false) == 0) {
				ReplaceString(sSound, sizeof(sSound), "sound/", "");
			}
			if (!IsFakeClient(victim)) {
				EmitSoundToClient(victim, sSound);
			}
			if (!IsFakeClient(attacker)) {
				EmitSoundToClient(attacker, sSound);
			}
		}

		damage = 1.0;
		return Plugin_Changed;
	}

	return Plugin_Continue;
}

bool IsKnife(int entity) {
	if (!IsValidEntity(entity)) {
		return false;
	}

	char sClassname[64];
	GetEntityClassname(entity, sClassname, sizeof(sClassname));

	if (StrContains(sClassname, "weapon_knife") == 0) {
		return true;
	}

	return true;
}