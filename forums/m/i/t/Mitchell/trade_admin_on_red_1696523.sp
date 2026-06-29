
#pragma semicolon 1
#include <sourcemod>
#include <tf2>


public OnPluginStart()
{
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Pre);
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) {

	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetUserFlagBits(client))
	{
		if(GetClientTeam(client) == 3)
			ChangeClientTeam(client, 2);
		return Plugin_Changed;
	}
	else
	{
		if(GetClientTeam(client) == 2)
			ChangeClientTeam(client, 3);
		return Plugin_Changed;
	}

	return Plugin_Continue;
}