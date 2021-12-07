#include <sourcemod>

public Plugin myinfo = 
{
	name = "Killer info", 
	author = "ExTacY", 
	description = "Show information about your killer", 
	version = "1.0", 
	url = ""
};

public void OnPluginStart()
{
	HookEvent("player_death", player_death);
}

public Action:player_death(Handle:event, const char[] name, bool dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
	
	new String:wep[64]
	GetEventString(event, "weapon", wep, 64);
	
	if (client == 0 || attacker == 0)
	{
		return Plugin_Continue
	}
	
	char cname[32], aname[32]
	GetClientName(client, cname, 32)
	GetClientName(client, aname, 32)
	
	if (client == attacker)
	{
		PrintToChatAll("%s Huniliation!", cname);
	} else {
		PrintToChatAll("%s killed %s with %s", aname, cname, wep);
	}
	
	return Plugin_Continue
}

