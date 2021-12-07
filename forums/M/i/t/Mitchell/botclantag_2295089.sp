#pragma semicolon 1
#include <cstrike>

public OnPluginStart() {
	HookEvent("player_spawn", Event_Spawn);
}
public Action:Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast) {
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsFakeClient(client)) {
		CS_SetClientClanTag(client, " ");
	}
}