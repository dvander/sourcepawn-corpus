#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <basecomm>
#include <cstrike>
#include <lastrequest>

public Plugin:myinfo =
{
	name = "SM Franug Jail Muter",
	author = "Franc1sco steam: franug",
	description = "",
	version = "v1.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn);
}

public OnAvailableLR(Announced)
{
	for (new i = 1; i <= MaxClients; i++)
		if (IsClientInGame(i) && IsPlayerAlive(i) && BaseComm_IsClientMuted(i)) 
		{
			BaseComm_SetClientMute(i, false);
		}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(GetUserAdmin(client) != INVALID_ADMIN_ID) return;

	if (GetClientTeam(client) == CS_TEAM_CT) BaseComm_SetClientMute(client, false);
	else BaseComm_SetClientMute(client, true);
 
}
 
public OnClientPostAdminCheck(client)
{
	if(GetUserAdmin(client) == INVALID_ADMIN_ID) BaseComm_SetClientMute(client, true);
	else BaseComm_SetClientMute(client, false);
}

