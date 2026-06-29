#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "[Deathrun] Decoy Teleporter",
	author = "Purixi",
	description = "",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_spawned", OnPlayerSpawned);
	HookEvent("decoy_firing", OnDecoyFiring);
}

public OnPlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	GivePlayerItem(client, "weapon_decoy");
}

public OnDecoyFiring(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	new Float:f_Pos[3];
	new entityid = GetEventInt(event, "entityid");
	f_Pos[0] = GetEventFloat(event, "x");
	f_Pos[1] = GetEventFloat(event, "y");
	f_Pos[2] = GetEventFloat(event, "z");
	
	TeleportEntity(client, f_Pos, NULL_VECTOR, NULL_VECTOR);
	RemoveEdict(entityid);
}