#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

public Plugin:myinfo = 
{
	name = "QuickFix clear Uber on Spawn",
	author = "Powerlord",
	description = "Removes the MegaHeal effect from players on Spawn",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	HookEvent("player_spawn", OnPlayerSpawn);
}

public OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return;
	}
	
	if (TF2_IsPlayerInCondition(client, TFCond_MegaHeal))
	{
		TF2_RemoveCondition(client, TFCond_MegaHeal);
	}
	
}