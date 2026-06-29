#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =
{
	name = "[Deathrun] Death List Cleaner",
	author = "Purixi",
	description = "",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new client = GetClientOfUserId(userid);
	
	new attacker = GetEventInt(event, "attacker");
	new aClient = GetClientOfUserId(attacker);
	
	if(client == aClient)
	{
		return 3;
	}
	
	if(userid == attacker)
	{
		return 3;
	}
	
	return 0;
}