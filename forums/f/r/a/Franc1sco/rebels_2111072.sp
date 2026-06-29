#pragma semicolon 1
#include <sourcemod>

#define VERSION "1.0"


public Plugin:myinfo =
{
	name = "SM Rebels",
	author = "Franc1sco Steam: franug",
	description = "",
	version = VERSION,
	url = "www.steamcommunity.com/id/franug/"
};

public OnPluginStart()
{
	CreateConVar("sm_rebels_version", VERSION, "version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	HookEvent("player_hurt", Event_hurt);
}

public Action:Event_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(!attacker)
		return;


	if (GetClientTeam(attacker) == 2)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));

		if (GetClientTeam(attacker) != GetClientTeam(client))
		{
			PrintToChatAll("\x04[Rebel]\x03 %N \x04attacked to\x03 %N", attacker, client);
		}
	}
}

