#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "New Plugin",
	author = "Unknown",
	description = "<- Description ->",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	HookEvent("bomb_dropped", OnBombDropped);
}

public Action:OnBombDropped(Handle:event, String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(IsClientConnected(client) && IsClientInGame(client) && IsPlayerAlive(client))
	{
		ForcePlayerSuicide(client);
	}
}
	