#define PLUGIN_VERSION "1.3"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <tf2_stocks>

public Plugin myinfo =  {
	name = "[TF2] Market Garden Only", 
	author = "pear", 
	description = "", 
	version = PLUGIN_VERSION, 
	url = ""
};

ConVar cEnabled;
ConVar cInstant;
ConVar cRemain;
ConVar cRegen;
ConVar cJumper;
ConVar cShovel;
ConVar cBoots;
bool bLow[MAXPLAYERS + 1];
bool bJumping[MAXPLAYERS + 1];

Handle hEquipSDK;

void MGEnable() {
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 0);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("rocket_jump", Event_RocketJump);
	HookEvent("rocket_jump_landed", Event_RocketJump);
	HookEvent("player_healed", Event_PlayerHealed);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("post_inventory_application", Event_Resupply);
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)) {
			SDKHook(i, SDKHook_OnTakeDamage, Hook_TakeDamage);
			SDKHook(i, SDKHook_OnTakeDamagePost, Hook_TakeDamagePost);
		}
	}
}

void MGDisable() {
	SetConVarInt(FindConVar("tf_dropped_weapon_lifetime"), 30);
	UnhookEvent("player_spawn", Event_PlayerSpawn);
	UnhookEvent("rocket_jump", Event_RocketJump);
	UnhookEvent("rocket_jump_landed", Event_RocketJump);
	UnhookEvent("player_healed", Event_PlayerHealed);
	UnhookEvent("player_death", Event_PlayerDeath);
	UnhookEvent("post_inventory_application", Event_Resupply);
	for (int i = 1; i <= MaxClients; i++) {
		if (IsValidClient(i)) {
			SDKUnhook(i, SDKHook_OnTakeDamage, Hook_TakeDamage);
			SDKUnhook(i, SDKHook_OnTakeDamagePost, Hook_TakeDamagePost);
			SetEntProp(i, Prop_Send, "m_bGlowEnabled", 0);
			bLow[i] = false;
			bJumping[i] = false;
		}
	}
}

public void OnPluginStart() {
	cEnabled = CreateConVar("mgonly_enabled", "1", "Enable MGOnly.", _, true, 0.0, true, 1.0);
	cInstant = CreateConVar("mgonly_instant", "0", "Enable instant kills.", _, true, 0.0, true, 1.0);
	cRemain = CreateConVar("mgonly_remain", "0", "Enable remaining outline of wounded enemy even on heal.", _, true, 0.0, true, 1.0);
	cRegen = CreateConVar("mgonly_regen", "0", "Enable HP regen on kill.", _, true, 0.0, true, 1.0);
	cJumper = CreateConVar("mgonly_jumper", "0", "Restricts players to the RJ primary.", _, true, 0.0, true, 1.0);
	cShovel = CreateConVar("mgonly_shovel", "1", "Restricts players to the MG melee.", _, true, 0.0, true, 1.0);
	cBoots = CreateConVar("mgonly_boots", "1", "Restricts players to the MT boots.", _, true, 0.0, true, 1.0);
	
	Handle cfg = LoadGameConfigFile("mgonly");
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(cfg, SDKConf_Virtual, "CTFPlayer::EquipWearable");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	hEquipSDK = EndPrepSDKCall();
	
	HookConVarChange(cEnabled, ConVar_Enabled);
	if (GetConVarBool(cEnabled)) {
		MGEnable();
	}
	AutoExecConfig();
}

public void OnPluginEnd() {
	MGDisable();
}

public void OnClientPutInServer(int client) {
	if (GetConVarBool(cEnabled)) {
		SDKHook(client, SDKHook_OnTakeDamage, Hook_TakeDamage);
		SDKHook(client, SDKHook_OnTakeDamagePost, Hook_TakeDamagePost);
		bLow[client] = false;
		bJumping[client] = false;
	}
}

public void OnClientDisconnect(int client) {
	if (GetConVarBool(cEnabled)) {
		SDKUnhook(client, SDKHook_OnTakeDamage, Hook_TakeDamage);
		SDKUnhook(client, SDKHook_OnTakeDamagePost, Hook_TakeDamagePost);
		bLow[client] = false;
		bJumping[client] = false;
	}
}

public void ConVar_Enabled(Handle convar, const char[] oldValue, const char[] newValue) {
	if (StringToInt(newValue) < 1) {
		MGDisable();
	}
	else {
		MGEnable();
	}
}

public Action Event_PlayerSpawn(Handle hEvent, char[] strEventName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient))return Plugin_Continue;
	bLow[iClient] = false;
	bJumping[iClient] = false;
	SetEntProp(iClient, Prop_Send, "m_bGlowEnabled", 0);
	TFClassType iClass = TF2_GetPlayerClass(iClient);
	if (!(iClass == TFClass_Soldier || iClass == view_as<TFClassType>(TFClass_Unknown))) {
		TF2_SetPlayerClass(iClient, TFClass_Soldier, false, true);
		TF2_RespawnPlayer(iClient);
	}
	if (GetConVarBool(cJumper))ChangeWeapon(iClient, TFWeaponSlot_Primary, "tf_weapon_rocketlauncher", 237);
	if (GetConVarBool(cBoots))ChangeWeapon(iClient, TFWeaponSlot_Secondary, "tf_wearable", 444);
	if (GetConVarBool(cShovel))ChangeWeapon(iClient, TFWeaponSlot_Melee, "tf_weapon_shovel", 416);
	return Plugin_Continue;
}

public Action Event_RocketJump(Handle hEvent, char[] strEventName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient))return Plugin_Continue;
	if (StrEqual(strEventName, "rocket_jump")) {
		bJumping[iClient] = true;
	}
	else {
		bJumping[iClient] = false;
	}
	return Plugin_Continue;
}

public Action Event_PlayerHealed(Handle hEvent, char[] strEventName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "patient"));
	if (!IsValidClient(iClient))return Plugin_Continue;
	if (!GetConVarBool(cRemain)) {
		if (GetClientHealth(iClient) > 65) {
			SetEntProp(iClient, Prop_Send, "m_bGlowEnabled", 0);
			bLow[iClient] = false;
		}
	}
	return Plugin_Continue;
}

public Action Hook_TakeDamage(int client, int &attacker, int &inflictor, float &damage, int &damagetype) {
	if (!IsValidClient(client))return Plugin_Continue;
	if (client == attacker) {
		SetEntProp(client, Prop_Data, "m_takedamage", 1);
	}
	char ename[256]; GetEntityClassname(inflictor, ename, sizeof(ename));
	if (StrEqual(ename, "trigger_hurt"))return Plugin_Continue;
	if (damagetype & DMG_FALL && GetClientHealth(client) > 65) {
		return Plugin_Handled;
	}
	if (bJumping[attacker] == true && client != attacker) {
		if (StrEqual(ename, "player")) {
			int melee = GetPlayerWeaponSlot(attacker, TFWeaponSlot_Melee);
			int active = GetEntPropEnt(attacker, Prop_Data, "m_hActiveWeapon");
			if(melee == active) {
				damagetype = DMG_CRIT;
				if (GetConVarBool(cInstant)) {
					damage = 200.0;
				}
				return Plugin_Changed;
			}
			return Plugin_Handled;
		}
		else {
			return Plugin_Handled;
		}
	}
	else if (bLow[client] == true) {
		return Plugin_Continue;
	}
	else if (bJumping[attacker] == false && client != attacker) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

public Action Hook_TakeDamagePost(int client, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3]) {
	if (!IsValidClient(client))return Plugin_Continue;
	SetEntProp(client, Prop_Data, "m_takedamage", 2);
	if (GetClientHealth(client) <= 65) {
		SetEntProp(client, Prop_Send, "m_bGlowEnabled", 1);
		bLow[client] = true;
	}
	return Plugin_Continue;
}

public Action Event_PlayerDeath(Handle hEvent, char[] strEventName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	int iAttacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if (iClient != iAttacker && GetConVarBool(cRegen) && IsValidClient(iAttacker)) {
		SetEntProp(iAttacker, Prop_Send, "m_iHealth", 200, 1);
		SetEntProp(iAttacker, Prop_Send, "m_bGlowEnabled", 0);
		bLow[iAttacker] = false;
	}
	return Plugin_Continue;
}

public Action Event_Resupply(Handle hEvent, char[] strEventName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (!IsValidClient(iClient))return Plugin_Continue;
	if (GetConVarBool(cJumper))ChangeWeapon(iClient, TFWeaponSlot_Primary, "tf_weapon_rocketlauncher", 237);
	if (GetConVarBool(cBoots))ChangeWeapon(iClient, TFWeaponSlot_Secondary, "tf_wearable", 444);
	if (GetConVarBool(cShovel))ChangeWeapon(iClient, TFWeaponSlot_Melee, "tf_weapon_shovel", 416);
	if(GetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon") == -1) {
		SetEntPropEnt(iClient, Prop_Data, "m_hActiveWeapon", GetPlayerWeaponSlot(iClient, TFWeaponSlot_Melee));
	}
	return Plugin_Continue;
}

stock bool IsValidClient(int client) {
	if (client <= 0 || client > MaxClients)return false;
	if (!IsClientInGame(client))return false;
	if (GetEntProp(client, Prop_Send, "m_bIsCoaching"))return false;
	return true;
}

public void ChangeWeapon(int client, int slot, char[] weapon, int index) {
	int target = -1;
	char cname[256] = "tf_wearable";
	if (StrEqual(weapon, "tf_wearable")) {
		int ent = -1;
		while ((ent = FindEntityByClassname2(ent, "tf_wearable")) != -1) {
			if (GetEntPropEnt(ent, Prop_Send, "m_hOwnerEntity") == client && GetEntProp(ent, Prop_Send, "m_iItemDefinitionIndex") == index) {
				target = ent;
				break;
			}
		}
	}
	else {
		target = GetPlayerWeaponSlot(client, slot);
		if (target == -1)return;
		GetEntityClassname(target, cname, sizeof(cname));
	}
	if (!StrEqual(weapon, "tf_wearable") && target == -1) {
		return;
	}
	if(target != -1) {
		if (StrEqual(cname, weapon) && GetEntProp(target, Prop_Send, "m_iItemDefinitionIndex") == index)return;
	}
	TF2_RemoveWeaponSlot(client, slot);
	int entity = CreateEntityByName(weapon);
	if (entity != -1) {
		SetEntProp(entity, Prop_Send, "m_iItemDefinitionIndex", index);
		SetEntProp(entity, Prop_Send, "m_iEntityQuality", 6);
		SetEntProp(entity, Prop_Send, "m_iEntityLevel", 10);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		SetEntPropEnt(entity, Prop_Send, "moveparent", client);
		SetEntProp(entity, Prop_Send, "m_bInitialized", 1);
		if (!StrEqual(weapon, "tf_wearable")) {
			SetEntPropEnt(entity, Prop_Send, "m_hOwner", client);
			SetEntProp(entity, Prop_Send, "m_bDisguiseWeapon", 1);
			DispatchSpawn(entity);
			EquipPlayerWeapon(client, entity);
		}
		else {
			DispatchSpawn(entity);
			SDKCall(hEquipSDK, client, entity);
		}
		SetEntityRenderMode(entity, RENDER_NORMAL);
		SetEntityRenderColor(entity, 255, 255, 255, 255);
	}
}

stock int FindEntityByClassname2(int startEnt, const char[] classname) {
	while (startEnt > -1 && !IsValidEntity(startEnt))startEnt--;
	return FindEntityByClassname(startEnt, classname);
}