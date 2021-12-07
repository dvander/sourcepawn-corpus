

#include <sourcemod>

public OnPluginStart()
{
	HookEvent("player_spawn", Event_Spawn);
}

public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(!IsPlayerAlive(client))
		return; 
	
	SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
}
	