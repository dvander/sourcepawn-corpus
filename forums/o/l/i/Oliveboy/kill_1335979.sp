#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
 
public Plugin:myinfo =
{
	name = "Kill Plugin",
	author = "Oliveboy",
	description = "You die when you kill someone",
	version = "1.0",
	url = "nothing"
};
 
public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "client"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	ForcePlayerSuicide(attacker);
}
    
	