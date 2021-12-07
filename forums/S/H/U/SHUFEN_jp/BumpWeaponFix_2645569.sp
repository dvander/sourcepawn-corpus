#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <dhooks>

Handle g_hValidateLineOfSight = null;

public Plugin myinfo = {
	name = "[CS:GO] BumpWeapon Fix",
	author = "SHUFEN from POSSESSION.tokyo",
	description = "Ignore to validate line-of-sight when pick up weapons",
	version = "20190331",
	url = "https://possession.tokyo"
};

public void OnPluginStart() {
	Handle hGameConf = LoadGameConfigFile("BumpWeaponFix.games");
	if (hGameConf == null) {
		SetFailState("Couldn't load BumpWeaponFix.games game config!");
		return;
	}

	// ValidateLineOfSight
	g_hValidateLineOfSight = DHookCreateDetour(Address_Null, CallConv_THISCALL, ReturnType_Bool, ThisPointer_CBaseEntity);
	if (!g_hValidateLineOfSight) {
		delete hGameConf;
		SetFailState("Failed to setup detour for \"ValidateLineOfSight\"");
	}
	if (!DHookSetFromConf(g_hValidateLineOfSight, hGameConf, SDKConf_Signature, "ValidateLineOfSight")) {
		delete hGameConf;
		SetFailState("Failed to load \"ValidateLineOfSight\" signature from gamedata");
	}
	DHookAddParam(g_hValidateLineOfSight, HookParamType_Int);
	if (!DHookEnableDetour(g_hValidateLineOfSight, false, Detour_ValidateLineOfSight)) {
		delete hGameConf;
		SetFailState("Failed to detour \"ValidateLineOfSight\"");
	}

	delete hGameConf;
}

public MRESReturn Detour_ValidateLineOfSight(Address pThis, Handle hReturn, Handle hParams) {
	DHookSetReturn(hReturn, true);
	return MRES_ChangedOverride;
}