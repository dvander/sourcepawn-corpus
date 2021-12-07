#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "AI"
#define PLUGIN_VERSION "0.1.0"

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2_stocks>
#include <tf2idb>
#include <tf2items>

bool g_bJetPack[MAXPLAYERS + 1] = {false, ...};
ConVar g_hRegenerate;
ConVar g_hBlockFuncRegenerate;

public Plugin myinfo = 
{
	name = "Jetpack",
	author = PLUGIN_AUTHOR,
	description = "Equip the pyro jetpack with charge regeneration",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=302213"
};

public void OnPluginStart()
{
	CreateConVar("sm_pyro_jetpack_version", PLUGIN_VERSION, "Pyro jetpack plugin version", FCVAR_NOTIFY);
	g_hRegenerate = CreateConVar("sm_pyro_jetpack_regen", "1", "Auto regenerate charge for equipped jetpacks", 0, true, 0.0, true, 1.0);
	g_hBlockFuncRegenerate = CreateConVar("sm_pyro_jetpack_block_func_regenerate", "0", "Block func_regenerate trigger while enabled", 0, true, 0.0, true, 1.0);
	RegConsoleCmd("sm_jetpack", cmdJetPack, "Equips a jetpack for pyro");
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_Resupply,  EventHookMode_Post);
	HookEvent("teamplay_round_start", Event_OnRoundStart, EventHookMode_Post);
}

public void OnMapStart() {
	if (g_hBlockFuncRegenerate.BoolValue) {
		doHookRegenerate();
	}
	
	if (g_hRegenerate.BoolValue) {
		CreateTimer(0.5, Timer_Regenerate, 0, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientConnected(int iClient) {
	g_bJetPack[iClient] = false;
}

// Custom callbacks

public Action Event_OnRoundStart(Event hEvent, const char[] sName, bool bDontBroadcast) {
	if (g_hBlockFuncRegenerate.BoolValue) {
		doHookRegenerate();
	}
}

public Action Event_PlayerSpawn(Event hEvent, const char[] sName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (g_bJetPack[iClient] && TF2_GetPlayerClass(iClient) == TFClass_Pyro) {
		doEquipJetPack(iClient);
	}
	
	return Plugin_Continue;
}

public Action Event_Resupply(Event hEvent, const char[] sName, bool bDontBroadcast) {
	int iClient = GetClientOfUserId(hEvent.GetInt("userid"));
	if (g_bJetPack[iClient] && TF2_GetPlayerClass(iClient) == TFClass_Pyro) {
		doEquipJetPack(iClient);
	}
	
	return Plugin_Continue;
}

public Action OnRegenTouch(int iEntity, int iOther) {
	if (0<iOther && iOther<=MaxClients && g_bJetPack[iOther] && TF2_GetPlayerClass(iOther) == TFClass_Pyro) {
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action Timer_Regenerate(Handle hTimer) {
	for (int i = 1; i <= MaxClients; i++) {
		if (g_bJetPack[i] && IsClientInGame(i) && IsPlayerAlive(i)) {
			SetEntPropFloat(i, Prop_Send, "m_flItemChargeMeter", 100.0, 1);
		}
	}
	
	return Plugin_Continue;
}

// Commands

public Action cmdJetPack(int iClient, int iArgC) {
	if (g_bJetPack[iClient]) {
		g_bJetPack[iClient] = false;
		ReplyToCommand(iClient, "[SM] Respawn or touch a resupply cabinet to unequip");
		
		return Plugin_Handled;
	}
	
	ReplyToCommand(iClient, "[SM] Equipping jetpack");
	
	g_bJetPack[iClient] = true;
	if (TF2_GetPlayerClass(iClient) == TFClass_Pyro) {
		doEquipJetPack(iClient);
	}
	
	return Plugin_Handled;
}

// Helper and stocks

void doHookRegenerate() { 
	int iEntity = -1;
	while ((iEntity = FindEntityByClassname(iEntity, "func_regenerate")) != INVALID_ENT_REFERENCE) {
		SDKHook(iEntity, SDKHook_Touch, OnRegenTouch);
	}
}

void doEquipJetPack(int iClient) {
	if (!g_bJetPack[iClient]) {
		return;
	}
	
	const int iItem = 1179;
	int iSlot = view_as<int>(TF2IDB_GetItemSlot(iItem));
	
	Handle hWeapon = TF2Items_CreateItem(OVERRIDE_ALL);
	char sClassName[32];
	TF2IDB_GetItemClass(iItem, sClassName, sizeof(sClassName));
	
	TF2Items_SetItemIndex(hWeapon, iItem);
	
	TF2Items_SetClassname(hWeapon, sClassName);
	int iLevelMin, iLevelMax;
	TF2IDB_GetItemLevels(iItem, iLevelMin, iLevelMax);
	TF2Items_SetLevel(hWeapon, iLevelMax);
	TF2Items_SetQuality(hWeapon, view_as<int>(TF2IDB_GetItemQuality(iItem)));
	
	int iAttributeIDs[TF2IDB_MAX_ATTRIBUTES];
	float fAttributeValues[TF2IDB_MAX_ATTRIBUTES];
	
	int iAttributes = TF2IDB_GetItemAttributes(iItem, iAttributeIDs, fAttributeValues);
	
	if (iAttributes) {
		TF2Items_SetNumAttributes(hWeapon, iAttributes);
		for (int j = 0; j < iAttributes; j++) {
			TF2Items_SetAttribute(hWeapon, j, iAttributeIDs[j], fAttributeValues[j]);
		}
	}
	
	int iWeapon = GetPlayerWeaponSlot(iClient, iSlot);
	if (iWeapon == -1 || GetItemDefIndex(iWeapon) != iItem) {
		if (iWeapon != -1) {
			RemovePlayerItem(iClient, iWeapon);
			RemoveEdict(iWeapon);
		}
		
		iWeapon = TF2Items_GiveNamedItem(iClient, hWeapon);
		EquipPlayerWeapon(iClient, iWeapon);
	}
}

stock GetItemDefIndex(int iItem) {
	return GetEntProp(iItem, Prop_Send, "m_iItemDefinitionIndex");
}
