#pragma semicolon 1
#include <sourcemod>

public OnPluginStart()
{
	if (!HookEventEx("player_death", Event_PlayerDeath, EventHookMode_Post))
		LogError("player_death event not hooked.");
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	PrintToChatAll("*Death Event* Victim: %i, Attacker: %i.", victim, attacker);
	PrintToServer("*Death Event* Victim: %i, Attacker: %i.", victim, attacker);
}