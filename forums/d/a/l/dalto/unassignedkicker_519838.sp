/*
unassignedkicker.sp

Description:
	Kicks anyone who tries to join the unnassigned team

Versions:
	1.0
		* Initial Release
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Unassigned Kicker",
	author = "AMP",
	description = "Kicks anyone who tries to join the unnassigned team",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("sm_unassigned_kicker_version", PLUGIN_VERSION, "Unassigned Kicker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_team", EventPlayerTeamChange);
}

public EventPlayerTeamChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetEventInt(event, "team");
	new oldteam = GetEventInt(event, "oldteam");
	if(team == 0 && oldteam) {
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(client && IsClientInGame(client))
			CreateTimer(0.5, TimerKick, client);
	}
}

public Action:TimerKick(Handle:timer, any:client)
{
	if(client && IsClientConnected(client))
		KickClient(client, "Joining unnassigned is not allowed.");
}
	