#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "Spawn effect",
	author = "Alienmario",
	version = "1.0",
}

public OnPluginStart(){
	HookEvent("player_spawn", Event_Spawn);
}

public Event_Spawn (Handle:event, const String:name[], bool:dontBroadcast){
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	SetEntProp(client, Prop_Send, "m_iFOVStart", 150);
	SetEntPropFloat(client, Prop_Send, "m_flFOVTime", GetGameTime());
	//SetEntProp(client, Prop_Send, "m_iFOV", 75);
	SetEntPropFloat(client, Prop_Send, "m_flFOVRate", 1.5);
}