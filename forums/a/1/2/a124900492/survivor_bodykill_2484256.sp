#include <sourcemod> 
#include <sdktools>

public OnPluginStart()
{
        HookEvent("dead_survivor_visible", SeesDeathPlayer);
}

public SeesDeathPlayer(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new entity = GetEventInt(event, "subject");
	CreateTimer(2.0, RemoveEntity, entity)
}

public Action:RemoveEntity(Handle:timer, any:client)
{
	AcceptEntityInput(client, "kill");
}