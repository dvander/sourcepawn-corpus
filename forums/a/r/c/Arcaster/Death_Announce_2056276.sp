#include <sourcemod>

public Plugin:myinfo =
{
	name = "Death Announce",
	author = "Arcaster",
	description = "Announces the death of players.",
	version = "1.0",
	url = ""
	};
	
forward OnPluginStart();

public OnPluginStart()
{
	PrintToServer("Death Announce by Arcaster has been loaded.");
	HookEvent("player_death", Event_PlayerDeath);
}

public Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:name[64]
	new victim_id = GetEventInt(event, "userid")
	new victim = GetClientOfUserId(victim_id)
	GetClientName(victim, name, sizeof(name))
	
	PrintToChatAll("Player \"%s\" has been killed.",
	name);
}

