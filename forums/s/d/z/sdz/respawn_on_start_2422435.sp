#include <sourcemod>
#include <cstrike>

public OnPluginStart()
{
	HookEvent("round_start", eventRoundStart, EventHookMode_Post);
}

public Action:eventRoundStart(Handle:event, const String:name[], bool:dontBroadcast) 
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			CS_RespawnPlayer(i);
		}
	}
}