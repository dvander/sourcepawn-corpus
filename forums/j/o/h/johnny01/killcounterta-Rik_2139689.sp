#include <sourcemod>

new killCounter[MAXPLAYERS+1];

public Plugin:myinfo =
{
	name = "Reach 75 kills",
	author = "Zyanthius/joac1144",
	description = "Reach 75 kills",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
}

public OnClientPutInServer(client)
{
	killCounter[client] = 0;
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:killerName[MAX_NAME_LENGTH];
	GetClientName(killer, killerName, sizeof(killerName));
	
	killCounter[killer]++;
	
	if(killCounter[killer] == 75)
	{
		PrintToChatAll(" \x04Congratulations to \x02%s \x04for reaching 75 frags first, the map is now changing....", killerName);
	}
}