#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#pragma semicolon 1 
 
public Plugin:myinfo =
{
    name = "VIP Benefits",
    author = "The1Speck",
    description = "For Zayes",
    version = PLUGIN_VERSION,
    url = "http://www.tangoworldwide.net"
}

public OnPluginStart()
{
	HookEvent("player_spawn", Event_Spawned);
}

public Action:Event_Spawned(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(GetAdminFlag(GetUserAdmin(client), Admin_Reservation))
		CreateTimer(0.1, Timer_Give, client);
}

public Action:Timer_Give(Handle:timer, client)
{
	SetEntityHealth(client, 150);
	SetEntProp(client, Prop_Data, "m_ArmorValue", 100, 1);
}