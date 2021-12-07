#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public OnPluginStart()
{
    HookEvent("player_spawn", Event_OnPlayerSpawn);
}
public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
    new client = GetClientOfUserId(GetEventInt(event, "userid"));
    GivePlayerItem(client, "weapon_nova")
}