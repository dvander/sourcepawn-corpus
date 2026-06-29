#include <sourcemod>

public Plugin:myinfo =
{
	name = "SM Godmode On Round End",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
}

public OnPluginStart()
{
	HookEvent("round_start", roundStart);
	HookEvent("round_end", roundEnd);
}

public Action:roundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	for (new x = 1; x <= MaxClients; x++)
	{
		if (IsClientInGame(x) && IsPlayerAlive(x))
		{
			SetEntProp(x, Prop_Data, "m_takedamage", 2, 1);
		}
	}
}

public Action:roundEnd(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new winner_team = GetEventInt(event, "winner");
	
	for (new x = 1; x <= MaxClients; x++)
	{
		if (IsClientInGame(x) && IsPlayerAlive(x) && GetClientTeam(x) == winner_team)
		{
			SetEntProp(x, Prop_Data, "m_takedamage", 0, 1);
		}
	}
}