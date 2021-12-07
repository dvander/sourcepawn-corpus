#include <sourcemod>
#include <tf2_stocks>

public OnPluginStart()
{
	HookEvent("teamplay_round_win", Event_RoundWin);
}

public Action:Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	for (new z = 1; z <= MaxClients; z++)
	{
		if (!IsClientInGame(z)) continue;
		if (!IsPlayerAlive(z)) continue;
		if (GetClientTeam(z) == team) TF2_AddCondition(z, TFCond_SpeedBuffAlly, 30.0);
	}
	return Plugin_Continue;
}