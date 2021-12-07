#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

float g_flNextC4PlantTime = 0.0;
int g_flC4TimeLeft = 60;

public Plugin myinfo = {
	name        = "C4 plant time",
	author      = "lingzhidiyu",
	description = "description",
	version     = "1.1",
	url         = "url"
}

public void OnPluginStart() {
	ConVar hC4TimeLeft = CreateConVar("c4_timeleft", "60", "How much timeleft allow player plant bomb");
	if (hC4TimeLeft == INVALID_HANDLE) {
		SetFailState("CreateConVar failed");
	}
	AutoExecConfig(true);

	g_flC4TimeLeft = GetConVarInt(hC4TimeLeft);
	delete hC4TimeLeft;

	HookEvent("round_start", OnRoundStart, EventHookMode_Post);
	HookEvent("bomb_pickup", OnBombPickup, EventHookMode_Post);
}

public void OnRoundStart(Event event, const char[] name, bool dontBroadcast) {
	g_flNextC4PlantTime = GetGameTime() + float(GameRules_GetProp("m_iRoundTime") - g_flC4TimeLeft);
}

public void OnBombPickup(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client != 0) {
		OnWeaponSwitch(client, GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon"));
	}
}

public void OnClientPutInServer(client) {
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public Action OnWeaponSwitch(int client, int weapon) {
	if (weapon == GetPlayerWeaponSlot(client, CS_SLOT_C4)) {
		if (GetGameTime() < g_flNextC4PlantTime) {
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", g_flNextC4PlantTime);
		} else {
			SetEntPropFloat(client, Prop_Send, "m_flNextAttack", 0.0);
		}
	}
}
