#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

new Handle:cvarEnabled;
new bool:IsZombie[MAXPLAYERS + 1] = false;

public Plugin:myinfo = 
{
	name = "Force Team",
	author = "ReFlexPoison",
	description = "Force player team change on client reconnect.",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	cvarEnabled = CreateConVar("sm_forceteam_enabled", "1", "Force player team on reconnect.", FCVAR_NONE, true, 0.0, true, 1.0);
	
	HookEvent("event_spawn", event_player_spawn);
	HookEvent("post_inventory_application", event_player_spawn);
}

public event_player_spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarBool(cvarEnabled))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(GetClientTeam(client) == 3) // CT
		{
			IsZombie[client] = true;
		}
		if(GetClientTeam(client) != 3 && IsZombie[client])
		{
			ChangeClientTeam(client, 3);
		}
	}
}