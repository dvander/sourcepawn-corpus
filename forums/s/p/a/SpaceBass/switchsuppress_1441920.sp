#include <sourcemod>

#define VERSION "1.2"

public Plugin:myinfo =
{
	name = "Switch Suppress",
	author = "SpaceBass",
	description = "Blocks all team switch event messages",
	version = VERSION,
	url = "http://roflservers.com"
}

public OnPluginStart()
{
	CreateConVar("switchsuppress_version", VERSION, _, FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED|FCVAR_SPONLY);
	HookEvent("player_team", ev_PlayerTeam, EventHookMode_Pre);
}

public Action:ev_PlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!dontBroadcast && !GetEventBool(event, "silent"))
	{
		SetEventBroadcast(event, true);
		return Plugin_Changed;
    }
	return Plugin_Continue;
}