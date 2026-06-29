#include <tf2attributes>

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn, EventHookMode_Post)
}

public Action:PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	TF2Attrib_SetByName(client, "special taunt", 1.0);
} 