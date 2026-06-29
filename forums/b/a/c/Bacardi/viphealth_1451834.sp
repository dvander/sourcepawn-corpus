#include <sourcemod>

public Plugin:myinfo = {
	name = "[VIPHealth]",
	author = "Bacardi",
	description = "Set player health when they spawn who have vip_health_access",
	version = "0.1",
	url = "https://forums.alliedmods.net/showthread.php?t=155049"
};

new Handle:sm_vip_spawnhealth = INVALID_HANDLE;
new health;

public OnPluginStart()
{
	HookEvent("player_spawn", PlayerSpawn);
	sm_vip_spawnhealth = CreateConVar("sm_vip_spawnhealth", "120", "Set health amount to players when they spawn who have vip_health_access", FCVAR_NONE, true, 1.0);
	health = GetConVarInt(sm_vip_spawnhealth);
	HookConVarChange(sm_vip_spawnhealth, ConVarChanged);
}

public ConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	health = GetConVarInt(sm_vip_spawnhealth);
}

public PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client) >= 2 && CheckCommandAccess(client, "vip_healt_access", ADMFLAG_RESERVATION))
	{
		SetEntityHealth(client, health);
	}
}