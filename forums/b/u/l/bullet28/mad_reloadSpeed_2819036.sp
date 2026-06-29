#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <lfd_stocks>
#include <dhooks>

enum {
	Weapon_None,
	Weapon_ShotgunSpas,
	Weapon_AutoShotgun,
	Weapon_PumpShotgun,
	Weapon_ShotgunChrome
};

Handle hGetReloadDurationModifier;
bool bDetectingReloadEnd[MAXPLAYERS+1];
int reloadingWeapon[MAXPLAYERS+1];

public void OnPluginStart() {
	Handle hGameData = LoadGameConfigFile("WeaponHandling");

	if (hGameData == null)
		SetFailState("Failed to load gamedata");

	int offset = GameConfGetOffset(hGameData, "CTerrorWeapon::GetReloadDurationModifier");

	if (offset == -1)
		SetFailState("Unable to get offset for 'CTerrorPlayer::GetReloadDurationModifier'");

	hGetReloadDurationModifier = DHookCreate(offset, HookType_Entity, ReturnType_Float, ThisPointer_CBaseEntity, OnGetReloadDurationModifier);
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (classname[0] != 'w')
		return;

	int weaponType;

	if (StrEqual(classname, "weapon_shotgun_spas"))
		weaponType = Weapon_ShotgunSpas;

	else if (StrEqual(classname, "weapon_autoshotgun"))
		weaponType = Weapon_AutoShotgun;

	else if (StrEqual(classname, "weapon_pumpshotgun"))
		weaponType = Weapon_PumpShotgun;

	else if (StrEqual(classname, "weapon_shotgun_chrome"))
		weaponType = Weapon_ShotgunChrome;

	else return;

	DHookEntity(hGetReloadDurationModifier, true, entity);
}

MRESReturn OnGetReloadDurationModifier(int pThis, Handle hReturn) {
	int client = GetEntPropEnt(pThis, Prop_Send, "m_hOwnerEntity");

	if (client < 1)
		return MRES_Ignored;

	float fCurrentValue = DHookGetReturn(hReturn);
	float fModValue = FMax(fCurrentValue / 1.75, 0.01);
	DHookSetReturn(hReturn, fModValue);

	if (!bDetectingReloadEnd[client]) {
		bDetectingReloadEnd[client] = true;
		reloadingWeapon[client] = EntIndexToEntRef(pThis);
		RequestFrame(DetectReloadEnd, client);
	}

	return MRES_Override;
}

void DetectReloadEnd(int client) {
	//PrintToServer("[%f] DetectReloadEnd", GetGameTime());

	if (!IsPlayerAliveSurvivor(client)) {
		bDetectingReloadEnd[client] = false;
		return;
	}

	int weapon = EntRefToEntIndex(reloadingWeapon[client]);

	if (weapon != GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon") || !IsValidWeapon(weapon)) {
		bDetectingReloadEnd[client] = false;
		return;
	}

	if (!GetEntProp(weapon, Prop_Send, "m_reloadState")) {
		bDetectingReloadEnd[client] = false;
		CreateTimer(0.30, RestorePlaybackRate, reloadingWeapon[client]);
		return;
	}
	
	RequestFrame(DetectReloadEnd, client);
}

Action RestorePlaybackRate(Handle hTimer, int weaponRef) {
	int weapon = EntRefToEntIndex(weaponRef);

	if (!IsValidWeapon(weapon))
		return Plugin_Continue;

	if (GetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate") == 1.0)
		return Plugin_Continue;

	SetEntPropFloat(weapon, Prop_Send, "m_flPlaybackRate", 1.0);
	return Plugin_Continue;
}
