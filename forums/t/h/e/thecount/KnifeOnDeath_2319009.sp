#include <sourcemod>
#include <sdktools>

public OnPluginStart(){
	HookEvent("player_death", Evt_Death, EventHookMode_Pre);
}

public Action:Evt_Death(Handle:event, const String:name[], bool:dontB){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	GivePlayerItem(client, "weapon_knife");//Give another knife which will most likely drop.
	return Plugin_Continue;
}