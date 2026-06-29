#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1"

public Plugin:myinfo =
{
	name = "DoD Nostalgic Death",
	author = "FeuerSturm, playboycyberclub",
	description = "Players screen fades grey on death!",
	version = PLUGIN_VERSION,
	url = "http://dodsplugins.net"
}

new Handle:NostalgicDeath = INVALID_HANDLE

public OnPluginStart()
{
	NostalgicDeath = CreateConVar("dod_nostalgic_death", "1", "<1/0> = enable/disable fading grey on death")
	HookEventEx("player_death", OnPlayerDeath, EventHookMode_Post)
	HookEventEx("player_spawn", OnPlayerSpawn, EventHookMode_Post)
}

public OnClientDisconnect(client)
{
	if(IsClientInGame(client))
	{
		ClientCommand(client, "r_screenoverlay 0")
	}
}
	
public Action:OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(NostalgicDeath) == 0)
	{
		return Plugin_Continue
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		ClientCommand(client, "r_screenoverlay 0")
	}
	return Plugin_Continue
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(NostalgicDeath) == 0)
	{
		return Plugin_Continue
	}
	new client = GetClientOfUserId(GetEventInt(event, "userid"))
	if(IsClientInGame(client))
	{
		ClientCommand(client, "r_screenoverlay debug/yuv.vmt")
	}
	return Plugin_Continue
}