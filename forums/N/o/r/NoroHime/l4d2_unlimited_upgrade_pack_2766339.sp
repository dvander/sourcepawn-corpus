#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

ConVar upgrade_pack_remove_timer_used;
ConVar upgrade_pack_remove_timer_created;
ConVar upgrade_pack_allow_bot_infinity;
ConVar upgrade_pack_use_buffer;
static int upgrade_pack_can_use_count;

public Plugin myinfo = {
	name = "[L4D2] Upgrade Pack Unlimited Use",
	author = "NoroHime",
	description = "make your upgrade pack use count unlimited and delete it after timeout",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/NoroHime/"
}

public void OnPluginStart() {

	Handle gamedata = LoadGameConfigFile("l4d2_unlimited_upgrade_pack");
	upgrade_pack_can_use_count = GameConfGetOffset(gamedata, "m_iUpgradePackCanUseCount");
	delete gamedata;

	upgrade_pack_remove_timer_used = CreateConVar("upgrade_pack_remove_timer_used", "0", "timer of used after to remove upgrade pack (0: disable feature)", FCVAR_NOTIFY);
	upgrade_pack_remove_timer_created = CreateConVar("upgrade_pack_remove_timer_created", "0", "timer of created after to remove upgrade pack (0: disable feature)", FCVAR_NOTIFY);
	upgrade_pack_allow_bot_infinity = CreateConVar("upgrade_pack_allow_bot_infinity", "0", "is allowed bot infinity to use, solve bot stuck in taking action", FCVAR_NOTIFY);
	upgrade_pack_use_buffer = CreateConVar("upgrade_pack_use_buffer", "127", "buffer of upgrade pack use count", FCVAR_NOTIFY);

	AutoExecConfig(true, "l4d2_unlimited_upgrade_pack");
	
}

public void OnEntityCreated(int entity, const char[] classname) {
	if (strcmp(classname, "upgrade_ammo_explosive") == 0 || strcmp(classname, "upgrade_ammo_incendiary") == 0 ) {
		
		SDKHook(entity, SDKHook_Use, OnUpgradeUse);

		if(upgrade_pack_remove_timer_created.BoolValue)
			CreateTimer(
				upgrade_pack_remove_timer_created.FloatValue,
				Timer_RemoveEntity, 
				EntIndexToEntRef(entity),
				TIMER_FLAG_NO_MAPCHANGE
			);
	}
}

public Action OnUpgradeUse(int entity, int activator, int caller, UseType type, float value) {
	if (!isValidEntity(entity)) return Plugin_Continue;

	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	if (StrContains(classname, "upgrade_ammo_") == -1) 
		return Plugin_Continue;

	SetEntData(entity, upgrade_pack_can_use_count, upgrade_pack_use_buffer.IntValue, 1, true);

	int client = caller;
	if (!isPlayerSurvivor(client)) 
		return Plugin_Continue;

	int primaryItem = GetPlayerWeaponSlot(client, 0);
	if (primaryItem == -1) 
		return Plugin_Continue;

	if(!IsFakeClient(client) || upgrade_pack_allow_bot_infinity.BoolValue) //prevent bot taken action loop
		SetEntProp(entity, Prop_Send, "m_iUsedBySurvivorsMask", 0);

	if(upgrade_pack_remove_timer_used.BoolValue)
		CreateTimer(
			upgrade_pack_remove_timer_used.FloatValue,
			Timer_RemoveEntity, 
			EntIndexToEntRef(entity),
			TIMER_FLAG_NO_MAPCHANGE
		);

	return Plugin_Continue;
}

public Action Timer_RemoveEntity(Handle timer, int ref)
{
	int entity;
	if(ref && (entity = EntRefToEntIndex(ref)) != INVALID_ENT_REFERENCE )
	{
		RemoveEntity(entity);
	}
	return Plugin_Continue;
}


bool isValidEntity(int entity) {
	return entity > 0 && entity <= 2048 && IsValidEdict(entity) && IsValidEntity(entity);
}

bool isPlayerValid(int client) {
	return client > 0 && client <= MaxClients && IsClientInGame(client);
}

bool isPlayerSurvivor(int client) {
	return isPlayerValid(client) && GetClientTeam(client) == 2;
}