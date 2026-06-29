#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	HookEvent("player_death", playerDeath);

}



public Action:playerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(!attacker)
		return;

 	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	PrintToChatAll("%N killed %N", attacker, client);

}
