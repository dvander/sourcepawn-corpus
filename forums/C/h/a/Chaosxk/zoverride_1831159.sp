#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "[TF2] Override Zombie Convar Flags",
	author = "Tak (Chaosxk)",
	description = "Overrides the convar to spawn zombies?",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	new enabled = GetConVarFlags(FindConVar("tf_halloween_zombie_mob_enabled"));
	new interval = GetConVarFlags(FindConVar("tf_halloween_zombie_mob_spawn_interval"));
	new count = GetConVarFlags(FindConVar("tf_halloween_zombie_mob_spawn_count"));
	new speed = GetConVarFlags(FindConVar("tf_halloween_zombie_speed"));
	new dmg = GetConVarFlags(FindConVar("tf_halloween_zombie_damage"));
	
	SetConVarFlags(FindConVar("tf_halloween_zombie_mob_enabled"), enabled & ~FCVAR_CHEAT);
	SetConVarFlags(FindConVar("tf_halloween_zombie_mob_spawn_interval"), interval & ~FCVAR_CHEAT);
	SetConVarFlags(FindConVar("tf_halloween_zombie_mob_spawn_count"), count & ~FCVAR_CHEAT);
	SetConVarFlags(FindConVar("tf_halloween_zombie_speed"), speed & ~FCVAR_CHEAT);
	SetConVarFlags(FindConVar("tf_halloween_zombie_damage"), dmg & ~FCVAR_CHEAT);	
}