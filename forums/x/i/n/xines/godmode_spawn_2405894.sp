#include <sourcemod>

public OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
	}
	
	return Plugin_Continue;
}