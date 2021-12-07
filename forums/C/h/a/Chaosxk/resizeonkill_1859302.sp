#pragma semicolon 1
#include <sdktools>
#include <sourcemod> 

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "[TF2] Resize on Kill",
	author = "Tak (Chaosxk)",
	description = "Requested",
	version = PLUGIN_VERSION,
	url = "http://www.alliedmods.net"
}

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}
 
public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new i = GetClientOfUserId(GetEventInt(event, "attacker"));
	SetEntPropFloat(i, Prop_Send, "m_flModelScale", 0.5);
}