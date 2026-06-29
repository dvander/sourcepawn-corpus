#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	HookEvent("player_spawn", playerSpawn, EventHookMode_Post);
}

public Action:playerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	CreateTimer(0.3, giveItems, client);
	CloseHandle(event);
	return Plugin_Continue;
}

public Action:giveItems(Handle:timer, any:client)
{
	GivePlayerItem(client, "weapon_357");
	GivePlayerItem(client, "weapon_shotgun");
	GivePlayerItem(client, "weapon_crossbow");
	GivePlayerItem(client, "weapon_ar2");
}