#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo =
{
	name = "[L4D2] Unlimited Chainsaw",
	author = "bullet28",
	description = "Chainsaw fuel always at 100%",
	version = "1",
	url = ""
}

public void OnPluginStart() {
	HookEvent("weapon_fire", eventWeaponFire);
}

public Action eventWeaponFire(Event event, const char[] name, bool dontBroadcast) {
	if (event.GetInt("weaponid") == 20) {
		int client = GetClientOfUserId(event.GetInt("userid"));
		if (!isPlayerAliveSurvivor(client)) return;

		int activeWeapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
		if (!isValidEntity(activeWeapon)) return;

		char classname[32];
		GetEntityClassname(activeWeapon, classname, sizeof(classname));
		if (!StrEqual(classname, "weapon_chainsaw")) return;
		
		SetEntProp(activeWeapon, Prop_Data, "m_iClip1", 30);
	}
}

bool isPlayerAliveSurvivor(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client) && GetClientTeam(client) == 2 && IsPlayerAlive(client);
}

bool isValidEntity(int entity) {
	return entity > 0 && entity <= 2048 && IsValidEdict(entity) && IsValidEntity(entity);
}
