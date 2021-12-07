#include <sourcemod>

#include <tf2>

#pragma semicolon 1
#pragma newdecls required

public void OnPluginStart() {
	HookEvent("player_spawn", OnPlayerSpawn, EventHookMode_PostNoCopy);
}

public void OnPlayerSpawn(Event event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	
	if (client && IsPlayerAlive(client) && CheckCommandAccess(client, "air_swim", ADMFLAG_GENERIC)) {
		TF2_AddCondition(client, TFCond_SwimmingCurse, TFCondDuration_Infinite);
	}
}
