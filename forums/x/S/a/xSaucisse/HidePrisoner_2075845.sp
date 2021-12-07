#include <sourcemod>

new g_TerroValeur[MAXPLAYERS +1];

public Plugin:myinfo = 
{
	name = "Cachekill",
	author = "Delachambre",
	version = "1.0",
	description = "Plugin qui cache les kill",
	url = "http://clan-family.com"
};

public OnPluginStart()
{
	HookEvent("player_death", Event_HidePrisonerKill, EventHookMode_Pre);
	HookEvent("player_spawn", Event_PlayerSpawn);
}
public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (!IsFakeClient(client) && IsClientConnected(client) && GetClientTeam(client) == 2)
		g_TerroValeur[client] = 0;
}

public Action:Event_HidePrisonerKill(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new String:weaponName[12];

	GetEventString(event, "weapon", weaponName, sizeof(weaponName));
	
	if (GetClientTeam(attacker) > 1 && GetClientTeam(victim) > 1)
	{
		if(strcmp(weaponName, "knife") == 0)
			g_TerroValeur[attacker]++;

		else
			g_TerroValeur[attacker] += 2;

		if (g_TerroValeur[attacker] <= 1000000)
			return Plugin_Changed;
	}
	return Plugin_Continue;
}