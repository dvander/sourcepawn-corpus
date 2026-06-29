#include <sourcemod>
#include <cstrike>

new bool:Respawn = false;
new Handle:RespawnTimer = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "Build Wars Respawn",
	author = "AbNeR_CSS",
	description = "Respawn anyone who joins late or dies in the first 5 minutes",
	version = "1.0fix",
	url = "www.tecnohardclan.com"
};

public OnPluginStart()
{
	
	HookEvent("player_team", OnPlayerChangedTeam, EventHookMode_Post);
	HookEvent("player_death", OnPlayerChangedTeam, EventHookMode_Post);
	HookEvent("round_start", RoundStart);
}


public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if(RespawnTimer != INVALID_HANDLE)
	{
		KillTimer(RespawnTimer);
		RespawnTimer = INVALID_HANDLE;
	}
	Respawn = true;
	RespawnTimer = CreateTimer(300.0, RespawnEnd);
}	

public Action:RespawnEnd(Handle:timer)
{
	Respawn = false;
	RespawnTimer = INVALID_HANDLE;
}

public Action:OnPlayerChangedTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(Respawn)
	{
		CreateTimer(1.0, RespawnClient, any:client);
	}
}

public Action:RespawnClient(Handle:timer, any:client)
{
	if(IsClientInGame(client) && !IsPlayerAlive(client) && GetClientTeam(client) > 1) 
		CS_RespawnPlayer(client);
}






