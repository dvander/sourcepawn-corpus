#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Heal Refuse",
	author = "bullet28",
	description = "Allows you to deny someones first aid kit healing by pressing E",
	version = "2",
	url = ""
}

ConVar cvarKitUseDuration;
float cvarKitUseDurationValue;
Handle resetTimer[MAXPLAYERS+1];
bool bIsBeingHealing[MAXPLAYERS+1];
int healingTarget[MAXPLAYERS+1];

public void OnPluginStart() {
	HookEvent("heal_begin", eventHealBegin);
	HookEvent("heal_success", eventHealReset);
	HookEvent("heal_interrupted", eventHealReset);
	cvarKitUseDuration = FindConVar("first_aid_kit_use_duration");
	cvarKitUseDuration.AddChangeHook(OnConVarChange);
	OnConVarChange(null, "", "");
}

public void OnConVarChange(ConVar convar, char[] oldValue, char[] newValue) {
	cvarKitUseDurationValue = cvarKitUseDuration.FloatValue;
}

public Action eventHealBegin(Event event, const char[] name, bool dontBroadcast) {
	int healer = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "subject"));
	if (healer == target) return;

	bIsBeingHealing[target] = true;
	healingTarget[healer] = target;

	if (resetTimer[healer] != INVALID_HANDLE) CloseHandle(resetTimer[healer]);
	resetTimer[healer] = CreateTimer(cvarKitUseDurationValue, OnTimerResetHealingTarget, healer);

	PrintHintText(target, "You can refuse healing by pressing E button");
}

public Action OnTimerResetHealingTarget(Handle timer, any healer) {
	resetTimer[healer] = INVALID_HANDLE;
	bIsBeingHealing[healingTarget[healer]] = false;
	healingTarget[healer] = 0;
}

public Action eventHealReset(Event event, const char[] name, bool dontBroadcast) {
	int healer = GetClientOfUserId(GetEventInt(event, "userid"));
	int target = GetClientOfUserId(GetEventInt(event, "subject"));
	bIsBeingHealing[target] = false;
	healingTarget[healer] = 0;
}

public Action OnPlayerRunCmd(int client, int &buttons) {
	if (bIsBeingHealing[client] && buttons & IN_USE && isPlayerAliveSurvivor(client)) {
		bIsBeingHealing[client] = false;
		int healer = getCurrentHealer(client);
		if (isPlayerAliveSurvivor(healer)) {
			if (!IsFakeClient(healer))
				PrintHintText(healer, "%N refused your healing", client);
			PrintHintText(client, "You refused %N healing", healer);
			InterruptHealing(healer);
		}
	}
}

int getCurrentHealer(int client) {
	for (int i = 1; i <= MaxClients; i++) {
		if (healingTarget[i] == client) {
			return i;
		}
	}

	return 0;
}

void InterruptHealing(int healer) {
	ClientCommand(healer, "lastinv");

	if (IsFakeClient(healer)) {
		SDKHook(healer, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);
		CreateTimer(10.0, OnTimerReleaseBotSwitchAbility, GetClientUserId(healer), TIMER_FLAG_NO_MAPCHANGE);
		SetEntPropFloat(healer, Prop_Send, "m_flNextShoveTime", GetGameTime() + 10.0); // Otherwise he will repeatedly shove the target
	}

	CreateTimer(0.1, OnTimerCheckIfInterrupted, GetClientUserId(healer));
}

public Action OnTimerCheckIfInterrupted(Handle timer, any healerID) {
	int healer = GetClientOfUserId(healerID);
	if (healer > 0 && healingTarget[healer] != 0) {
		if (isPlayerAliveSurvivor(healer)) {
			int item = GetPlayerWeaponSlot(healer, 3);
			int activeWeapon = GetEntPropEnt(healer, Prop_Send, "m_hActiveWeapon");
			if (item != -1 && item == activeWeapon) {
				char classname[32];
				GetEntityClassname(item, classname, sizeof classname);
				if (StrEqual(classname, "weapon_first_aid_kit")) {
					RemovePlayerItem(healer, item);
					AcceptEntityInput(item, "Kill");
					giveItem(healer, "first_aid_kit");
				}
			}
		}
	}
}

public Action OnTimerReleaseBotSwitchAbility(Handle timer, any healerID) {
	int healer = GetClientOfUserId(healerID);
	if (healer > 0) {
		SDKUnhook(healer, SDKHook_WeaponCanSwitchTo, OnWeaponCanSwitchTo);
	}
}

public Action OnWeaponCanSwitchTo(int client, int weapon) {
	char weaponName[32];
	GetEntityClassname(weapon, weaponName, sizeof weaponName);
	if (StrEqual(weaponName, "weapon_first_aid_kit")) {
		return Plugin_Handled;
	}

	return Plugin_Continue;
}

void giveItem(int client, const char[] weapon) {
	int flags = GetCommandFlags("give");
	SetCommandFlags("give", flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "give %s", weapon);
	SetCommandFlags("give", flags);
}

bool isPlayerAliveSurvivor(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}
