#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	HookEvent("player_death", Event_OnPlayerDeath);
}

public Action:Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	SetClientViewEntity(client, client);
	
	return Plugin_Continue;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new ragdoll = GetEntPropEnt(client, Prop_Send, "m_hRagdoll");
	if (ragdoll<0)
		return Plugin_Continue;
	
	SetClientViewEntity(client, ragdoll);
	
	return Plugin_Continue;
}