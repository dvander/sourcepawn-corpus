#pragma semicolon 1
#include <sourcemod>
#include <cstrike>
#define PLUGIN_VERSION "0.5"

public Plugin:myinfo = {
	name = "Cr(+)sshair's Auto Respawner",
	author = "[HG] Cr(+)sshair",
	description = "Automatically respawns players.",
	version = PLUGIN_VERSION,
	url = "http://www.hellsgamers.com/"
}



public OnPluginStart() {
	
	HookEvent("player_death", Event_PlayerDeath);
	CreateConVar("sm_respawn_version", PLUGIN_VERSION, "Respawn Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}


public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
			new client = GetClientOfUserId(GetEventInt(event, "userid"));		
			CreateTimer(0.1, Respawn, client);
}

public Action:Respawn(Handle:timer, any:client)
{
CS_RespawnPlayer(client);
}