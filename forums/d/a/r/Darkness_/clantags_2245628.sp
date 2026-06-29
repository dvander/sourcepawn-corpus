#include <sourcemod>
#include <cstrike>

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeath);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontbroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (GetClientTeam(attacker) == 2)
	{
		SetEntityRenderColor(attacker, 255, 0, 0, 255);
	}
	if (GetClientTeam(attacker) == 3)
	{
		SetEntityRenderColor(attacker, 0, 0, 150, 255);
	}
	SetEntProp(attacker, Prop_Data, "m_takedamage", 0, 1);
	CreateTimer(1.0, Reset, attacker);
}

public Action:Reset(Handle:timer, any:attacker)
{
	SetEntProp(attacker, Prop_Data, "m_takedamage", 2, 1);
	SetEntityRenderColor(attacker, 255, 255, 255, 255);
}