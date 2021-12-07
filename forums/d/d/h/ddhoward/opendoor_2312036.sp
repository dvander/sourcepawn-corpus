#include <sdktools>
#pragma newdecls required;

public void OnPluginStart() {
	HookEvent("player_spawn", Event_Spawn);
}

public Action Event_Spawn(Handle hEvent, char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if(client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client)) {
		if(CheckCommandAccess(client, "player_can_open_door", ADMFLAG_CUSTOM1)) {
			DispatchKeyValue(client, "targetname", "VIP");     //VIP is the name the plugin gives the player on spawn
		}
	}
	return Plugin_Continue;
}