#include <sourcemod>
#include <sourcebans>
#pragma semicolon 1

new IsPlayerBanned[MAXPLAYERS+1] = 0;

public Plugin:myinfo =
{
	name = "CMDFIX Autoban",
	author = "root",
	description = "Automatically bans cheaters trying to crash server",
	version = "1.0.0",
	url = "http://uwujka.pl"
}
public OnMapStart()
{
	HookEvent("player_disconnect", PlayerDisconnected);
}

public Action:PlayerDisconnected(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	decl String:s_reason[256];
	GetEventString(event,"reason", s_reason, sizeof(s_reason));
	if(StrContains(s_reason, "Corrupt user cmd", false) != -1 && !IsPlayerBanned[client])
	{
		SBBanPlayer(0, client, 0, "Banned for trying to crash the server");
		IsPlayerBanned[client] = 1;
	}
	return Plugin_Continue;
}