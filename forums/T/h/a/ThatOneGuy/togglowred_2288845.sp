#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(IsValidEntity(client))
	{
		SetEntityRenderColor(client, 255, 0, 0, 255);
	}
	
	return Plugin_Continue;
}
