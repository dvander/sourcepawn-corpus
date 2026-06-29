#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#define L4D2UTIL_STOCKS_ONLY
#include <l4d2util>


public Plugin:myinfo =
{
	name        = "Kill Announcer",
	author      = "",
	version     = "1.0",
	description = "x",
};


public OnPluginStart()
{
	HookEvent("player_death", PlayerDeath_Event);
}

public Action: PlayerDeath_Event( Handle:event, const String:name[], bool:dontBroadcast )
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	if (!IsSurvivor(victim))
	{
		return;
	}
	decl String:victims_name[128];
	decl String:attackers_name[128];
	
	GetClientName(victim, victims_name, sizeof(victims_name));
	GetClientName(attacker, attackers_name, sizeof(attackers_name));
	
	if (!IsFakeClient(attacker))	
	{
		PrintToChatAll("[%s %s] has killed %s", L4D2_InfectedNames[_:GetEntProp(attacker, Prop_Send, "m_zombieClass")-1], attackers_name, victims_name);
	} 
	
	else {
		PrintToChatAll("[%s] has killed %s", L4D2_InfectedNames[_:GetEntProp(attacker, Prop_Send, "m_zombieClass")-1], victims_name);
	}

}

