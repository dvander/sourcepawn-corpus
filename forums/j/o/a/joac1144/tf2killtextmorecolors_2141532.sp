#include <sourcemod>
#include <morecolors>

public Plugin:myinfo =
{
	name = "Kill Text",
	author = "joac1144/Zyanthius",
	description = "Kill text",
	version = "1.0",
	url = ""
};

public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath);
}

public PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:clientName[MAX_NAME_LENGTH];
	new String:killerName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	GetClientName(killer, killerName, sizeof(killerName));
	
	CPrintToChatAll("{green}%s {lightgreen}was killed by {green}%s", clientName, killerName);
}