#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.0"

new healthOffset;

// Functions
public Plugin:myinfo =
{
	name = "Losing Team Health Changer",
	author = "bl4nk",
	description = "Reduces the health of the losing team to 1",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_lthc_version", PLUGIN_VERSION, "Losing Team Health Changer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	healthOffset = FindSendPropInfo("CTFPlayer", "m_iHealth");
	if (healthOffset == -1)
		SetFailState("Could not find health offset");

	HookEvent("teamplay_round_win", event_RoundEnd);
}

public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetOpposingTeam(GetEventInt(event, "team"));
	if (team == 0)
		return;

	for (new i = 1; i <= GetMaxClients(); i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && GetClientTeam(i) == team && IsPlayerAlive(i))
			SetEntityHealth(i, 1);
	}
}

stock GetOpposingTeam(team)
{
	switch (team)
	{
		case 2:
			return 3;
		case 3:
			return 2;
	}

	return 0;
}