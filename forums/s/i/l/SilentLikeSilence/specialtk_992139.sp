#include <sourcemod>
#include <cstrike>

public Plugin:myinfo =
{
	name = "[CSS] Special TK Mod",
	author = "John B.",
	description = "Attacker gets the amount of damage what victim would get",
	version = "1.0.0",
	url = "www.sourcemod.net",
}

public OnPluginStart()
{
	HookEvent("player_hurt", Event_PlayerHurt);
}

public Action:Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new damage = GetEventInt(event, "dmg_health");
	new currenthealthVictim = GetClientHealth(victim);
	new currenthealthAttacker = GetClientHealth(attacker);
	new victimTeam = GetClientTeam(victim);
	new attackerTeam = GetClientTeam(attacker);

	if(attackerTeam == victimTeam)
	{
		SetEntityHealth(victim, currenthealthVictim + damage);
		SetEntityHealth(attacker, currenthealthAttacker - damage);	
	}

	return Plugin_Continue;
}

