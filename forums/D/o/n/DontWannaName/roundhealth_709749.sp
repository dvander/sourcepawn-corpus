#pragma semicolon 1
#include <sourcemod>

public OnPluginStart()
{
  HookEvent("player_spawn", event_PlayerSpawn);
}

public Action:event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
  new client = GetClientOfUserId(GetEventInt(event, "userid"));
  SetEntityHealth(client, 80);
}