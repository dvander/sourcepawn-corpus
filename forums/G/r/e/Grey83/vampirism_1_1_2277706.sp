#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION 	"1.1"

new Handle:h_enable, bool:b_enable,
	Handle:h_heal_max, i_heal_max,
	Handle:h_kill_heal, i_kill_heal,
	Handle:h_headshot_heal, i_headshot_heal,
	Handle:h_fire_heal, i_fire_heal;

public Plugin:myinfo =
{
	name	= "[NMRiH] Health Vampirism",
	author	= "Undeadsewer (rewrited by Grey83)",
	description	= "Leech health from killed zombies",
	version	= PLUGIN_VERSION,
	url		= "http://www.undeadsewer-nmrih.brace.io/"
};

public OnPluginStart()
{
	// Indicates that plugin has loaded.

	// Defines variabled into ConVars
	CreateConVar("nmrih_vampirism_version", PLUGIN_VERSION, "The version of the Health Vampirism the server is running.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	h_enable = CreateConVar("sm_vampirism_enable", "1", "Enables/Disables the plugin", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	h_heal_max = CreateConVar("sm_vampirism_max", "100", "The maximum amount of health, which can get a player for killing zombies", FCVAR_PLUGIN, true, 100.0);
	h_kill_heal = CreateConVar("sm_vampirism_kill", "5", "Health gained from kill", FCVAR_PLUGIN, true, 0.0);
	h_headshot_heal = CreateConVar("sm_vampirism_headshot", "10", "Health gained from headshot", FCVAR_PLUGIN, true, 0.0);
	h_fire_heal = CreateConVar("sm_vampirism_fire", "5", "Health gained from burning zombie", FCVAR_PLUGIN, true, 0.0);

	b_enable = GetConVarBool(h_enable);
	i_heal_max = GetConVarInt(h_heal_max);
	i_kill_heal = GetConVarInt(h_kill_heal);
	i_headshot_heal = GetConVarInt(h_headshot_heal);
	i_fire_heal = GetConVarInt(h_fire_heal);

	// Hooks their change
	HookConVarChange(h_enable, OnConVarChanged);
	HookConVarChange(h_heal_max, OnConVarChanged);
	HookConVarChange(h_kill_heal, OnConVarChanged);
	HookConVarChange(h_headshot_heal, OnConVarChanged);
	HookConVarChange(h_fire_heal, OnConVarChanged);
	
	// Hooks certain events to be referenced later on.
	HookEvent("npc_killed", Event_Killed);
	HookEvent("zombie_head_split", Event_Headshot);
	HookEvent("zombie_killed_by_fire", Event_Fire);

	AutoExecConfig(true, "nmrih_vampirism");
	PrintToServer("[NMRiH] Health Vampirism v.%s has been successfully loaded!", PLUGIN_VERSION);
}
public OnConVarChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == h_enable)
	{
		b_enable = bool:StringToInt(newValue);
	}
	else if (convar == h_heal_max)
	{
		i_heal_max = StringToInt(newValue);
	}
	else if (convar == h_kill_heal)
	{
		i_kill_heal = StringToInt(newValue);
	}
	else if (convar == h_headshot_heal)
	{
		i_headshot_heal= StringToInt(newValue);
	}
	else if (convar == h_fire_heal)
	{
		i_fire_heal = StringToInt(newValue);
	}
}

public Action:Event_Killed(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "killeridx");
	new i_heal = i_kill_heal;
	ZombieHeal(client, i_heal);
	return Plugin_Continue;
}

public Action:Event_Headshot(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player_id");
	new i_heal = i_headshot_heal;
	ZombieHeal(client, i_heal);
	return Plugin_Continue;
}

public Action:Event_Fire(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "igniter_id");
	new i_heal = i_fire_heal;
	ZombieHeal(client, i_heal);
	return Plugin_Continue;
}

public ZombieHeal(client, i_heal)
{
	new health = GetClientHealth(client);
	
	if(b_enable && health < i_heal_max && IsPlayerAlive(client))
	{
		SetEntityHealth(client, health + i_heal);
	}
	else
	{
		if(health > i_heal_max)
		{
			SetEntityHealth(client, i_heal_max);
		}
	}
}