#pragma semicolon 1
#include <sourcemod>

new Handle:sm_kill_heal = INVALID_HANDLE;
new Handle:sm_headshot_heal = INVALID_HANDLE;
new Handle:sm_fire_heal = INVALID_HANDLE;

new MaxHealth = 100;

public Plugin:info =
{
	name = "[NMRiH] Health Vampirism",
	author = "Undeadsewer",
	description = "Leech health from killed zombies",
	version = "1.0",
	url = "http://www.undeadsewer-nmrih.brace.io/"
}

public OnPluginStart()
{
	// Indicates that plugin has loaded.
	PrintToServer("[NMRiH] Health Vampirism has been successfully loaded!");

	// Defines variabled into ConVars
	sm_kill_heal = CreateConVar("sm_kill_heal", "1", "Health gained from kill");
	sm_headshot_heal = CreateConVar("sm_headshot_heal", "1", "Health gained from headshot");
	sm_fire_heal = CreateConVar("sm_fire_heal", "1", "Health gained from burning zombie");
	
	// Hooks certain events to be referenced later on.
	HookEvent("npc_killed", Event_Killed);
	HookEvent("zombie_head_split", Event_Headshot);
	HookEvent("zombie_killed_by_fire", Event_Fire);
}

public Action:Event_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Grabs ID from certain Event.
	new client = GetEventInt(event, "killeridx");
	
	// Calls command based on client variable.
	ZombieKillHeal(client);
	
	// Continues the command onwards.
	return Plugin_Continue;
}

public Action:Event_Headshot(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player_id");
	
	ZombieHeadshotHeal(client);
	
	return Plugin_Continue;
}

public Action:Event_Fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "igniter_id");
	
	ZombieFireHeal(client);
	
	return Plugin_Continue;
}

public ZombieKillHeal(client)
{
	// Gets client's current health.
	new health = GetClientHealth(client);
	
	// Only executes command if client health is less than max health.
	if(health < MaxHealth)
	{
		SetEntityHealth(client, health + GetConVarInt(sm_kill_heal));
	}
	else
	{
		if(health > MaxHealth)
		{
			SetEntityHealth(client, MaxHealth);
		}
	}
}

public ZombieHeadshotHeal(client)
{
	new health = GetClientHealth(client);
	
	if(health < MaxHealth)
	{
		SetEntityHealth(client, health + GetConVarInt(sm_headshot_heal));
	}
	else
	{
		if(health > MaxHealth)
		{
			SetEntityHealth(client, MaxHealth);
		}
	}
}

public ZombieFireHeal(client)
{
	new health = GetClientHealth(client);
	
	if(health < MaxHealth)
	{
		SetEntityHealth(client, health + GetConVarInt(sm_fire_heal));
	}
	else
	{
		if(health > MaxHealth)
		{
			SetEntityHealth(client, MaxHealth);
		}
	}
}