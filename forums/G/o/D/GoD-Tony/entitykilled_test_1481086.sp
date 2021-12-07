#pragma semicolon 1
#include <sourcemod>

public OnPluginStart()
{
	if (!HookEventEx("entity_killed", Event_EntityKilled, EventHookMode_Post))
		LogError("entity_killed event not hooked.");
}

public Event_EntityKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetEventInt(event, "entindex_killed");
	new attacker = GetEventInt(event, "entindex_attacker");
	
	PrintToChatAll("*Entity Killed* Victim: %i, Attacker: %i.", victim, attacker);
	PrintToServer("*Entity Killed* Victim: %i, Attacker: %i.", victim, attacker);
}