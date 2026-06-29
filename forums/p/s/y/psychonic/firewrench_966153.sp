#include <sourcemod>
#include <takedamage>
#include <tf2>

#pragma semicolon 1

#define PLUGIN_NAME "TF2 Fire Wrench"
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "psychonic",
	description = "Wrench hits cause victim to catch on fire",
	version = PLUGIN_VERSION,
	url = "http://nicholashastings.com"
};

public OnPluginStart()
{
	CreateConVar("sm_firewrench_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public Action:OnTakeDamage(victim, attacker, inflictor, Float:damage, damagetype)
{
	if (inflictor > 0 && inflictor <= MaxClients
		&& IsClientInGame(inflictor) && IsClientInGame(victim)
		&& GetClientHealth(victim) > 0)
	{
		decl String:weapon[64];
		GetClientWeapon(inflictor, weapon, sizeof(weapon));
		if (strncmp(weapon[10], "wrench", 6) == 0)
		{
			TF2_IgnitePlayer(victim, attacker);
		}
	}
}