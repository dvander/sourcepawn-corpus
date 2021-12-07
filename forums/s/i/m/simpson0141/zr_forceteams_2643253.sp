#pragma semicolon 1

#include <sourcemod>
#include <zombiereloaded>
#include <cstrike>

bool started;

public Plugin myinfo =
{
	name = "[ZR] Force Teams",
	author = "Franc1sco franug",
	description = "",
	version = "2.0",
	url = "http://steamcommunity.com/id/franug"
};

public void OnPluginStart() 
{
	HookEvent("player_spawn", EventPlayerSpawn, EventHookMode_Pre);
	HookEvent("round_start", EventRoundStart, EventHookMode_Pre);
	HookEvent("round_end", EventRoundEnd, EventHookMode_Pre);
}

public Action EventPlayerSpawn(Handle event, const char[] name, bool dontBroadcast) 
{
	if(started) return;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if(GetClientTeam(client) == CS_TEAM_T) CS_SwitchTeam(client, CS_TEAM_CT);
}

public Action EventRoundStart(Handle event, const char[] name, bool dontBroadcast) 
{
	started = false;
}

public Action EventRoundEnd(Handle event, const char[] name, bool dontBroadcast) 
{
	started = false;
}

public int ZR_OnClientInfected(int client, int attacker, bool motherInfect, bool respawnOverride, bool respawn)
{
	if(!started) started = true;
}

public Action CS_OnTerminateRound(float &delay, CSRoundEndReason &reason)
{
	if(!started)
	{
		int count;
	
		for (int i = 1; i <= MaxClients; i++) 
			if (IsClientInGame(i) && IsPlayerAlive(i))
				count++;
	
		if(count > 0)
			return Plugin_Handled;
	}
	else return Plugin_Continue;
	
	return Plugin_Continue;
}