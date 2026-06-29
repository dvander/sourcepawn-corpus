#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

int ga_iWepWithFlashlightRef[MAXPLAYERS + 1] = {INVALID_ENT_REFERENCE, ...};

public Plugin myinfo = {
	name = "bot_flashlight",
	author = "Nullifidian",
	description = "If a bot's weapon has a flashlight, it will be turned on by this plugin.",
	version = "1.0",
	url = ""
};

public void OnPluginStart() {
	HookEvent("weapon_deploy", Event_WeaponDeploy);
	AddNormalSoundHook(NormalSoundHook);
}

public void OnClientDisconnect(int client) {
	ga_iWepWithFlashlightRef[client] = INVALID_ENT_REFERENCE;
}

public Action Event_WeaponDeploy(Event event, char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client < 1 || !IsClientInGame(client) || !IsFakeClient(client)) {
		return Plugin_Continue;
	}

	int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (activeWeapon < 1 || !IsValidEntity(activeWeapon) || !HasEntProp(activeWeapon, Prop_Send, "m_bFlashlightOn")) {
		ga_iWepWithFlashlightRef[client] = INVALID_ENT_REFERENCE;
		return Plugin_Continue;
	}

	ga_iWepWithFlashlightRef[client] = EntIndexToEntRef(activeWeapon);
	TurnOnFlashlight(client);

	return Plugin_Continue;
}

void TurnOnFlashlight(int client) {
	int weapon = EntRefToEntIndex(ga_iWepWithFlashlightRef[client]);
	if (!IsValidEntity(weapon)) {
		return;
	}

	if (GetEntProp(weapon, Prop_Send, "m_bFlashlightOn") == 0) {
		SetEntProp(weapon, Prop_Send, "m_bFlashlightOn", 1);
	}
}

public Action NormalSoundHook(int clients[MAXPLAYERS], int &numClients, char sample[PLATFORM_MAX_PATH], int &entity, int &channel, float &volume, int &level, int &pitch, int &flags, char soundEntry[PLATFORM_MAX_PATH], int &seed) {
	if (entity < 1 || entity > MaxClients || !IsClientInGame(entity) || !IsFakeClient(entity)) {
		return Plugin_Continue;
	}

	if (strcmp(sample, "player/flashlight_off.wav") == 0) {
		if (ga_iWepWithFlashlightRef[entity] != INVALID_ENT_REFERENCE) {
			TurnOnFlashlight(entity);
		}
		return Plugin_Handled;
	} else if (strcmp(sample, "player/flashlight_on.wav") == 0) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}