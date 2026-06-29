#pragma semicolon 1

#include <sourcemod>
#include <sdktools>


new Handle:cvarSpawnProtectionTime;
new g_SpawnTime[MAXPLAYERS+1];


public Plugin:myinfo =
{
        name = "Team switch Command",
        author = "lamdacore",
        description = "Little Spawn Protect Plugin that protects just spawned Players for being killed from the enemy.",
        version = "1.0",
        url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	cvarSpawnProtectionTime = CreateConVar("sm_spawnprotect_time", "3.0", "Amount of time the player will be spawnprotect.", FCVAR_PLUGIN, true, 0.0, true, 10.0);

	HookEvent("player_hurt",ev_PlayerHurt);
        HookEvent("player_spawn",ev_PlayerSpawn);
}

public ev_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimUserid = GetEventInt(event, "userid");
	new attackerUserid = GetEventInt(event, "attacker");
	new victim = GetClientOfUserId(victimUserid);
	new attacker = GetClientOfUserId(attackerUserid);

	if (attacker == 0 || victim == 0 || !IsClientConnected(attacker) || !IsClientConnected(victim) || victim == attacker)
	{
		return;
	}

	new victimTeam = GetClientTeam(victim);
	new attackerTeam = GetClientTeam(attacker);
	
	if (victimTeam == attackerTeam)
	{
		return;
	}

	new CurrentTime = GetTime();
	if (CurrentTime - g_SpawnTime[victim] > 0)
	{
		return;
	}

	ForcePlayerSuicide(attacker);
	PrintToChat(attacker, "You have been slain for Spawn-Attacking.");	
}

public ev_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	new ProtectTime = GetConVarInt(cvarSpawnProtectionTime);
	g_SpawnTime[client] = GetTime() + ProtectTime;
}
