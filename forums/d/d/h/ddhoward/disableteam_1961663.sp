#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#define PLUGIN_VERSION "13.0531.1"

new Handle:hcvar_team = INVALID_HANDLE;

public Plugin:myinfo = {
	name = "[TF2] Freeze and Disable a Team",
	author = "Derek D. Howard",
	description = "Freezes players belonging to a particular team, and strips them of all weapons.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=217196"
};

public OnPluginStart() {
	hcvar_team = CreateConVar("sm_disableteam", "0", "What team to freeze? 2 = red, 3 = blue, anything else to disable.", FCVAR_PLUGIN);
//	HookEvent("player_spawn", OnPlayerSpawned);
	HookEvent("post_inventory_application", Inventory_App);
}

//public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast) {
public Inventory_App(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (GetClientTeam(client) == GetConVarInt(hcvar_team)) {
		CreateTimer(0.1, DoFreeze, client);
	}
}

public Action:DoFreeze(Handle:timer, any:client) {
	if (IsClientConnected(client)) {
		if (IsClientInGame(client)) {
			if (IsPlayerAlive(client)) {
				if (GetClientTeam(client) == GetConVarInt(hcvar_team)) {
					SetEntityMoveType(client, MOVETYPE_NONE);
					TF2_RemoveAllWeapons(client);
				}
			}
		}
	}
}