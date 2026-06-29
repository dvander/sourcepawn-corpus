#include <sourcemod>

#pragma semicolon 1

public OnPluginStart()
{
	HookEvent("player_death", Event_PlayerDeathPre, EventHookMode_Pre);
}

public Action:Event_PlayerDeathPre(Handle:event, const String:name[], bool:dontBroadcast)
{
	new Attacker = GetEventInt(event, "attacker");
	new String:Weapon[20];
	GetEventString(event, "weapon", Weapon, sizeof(Weapon));
	
	if ((StrEqual("env_explosion", Weapon, false)) && (Attacker != 0))
	{
		SetEventString(event, "weapon", "hegrenade");
	}
	
	return Plugin_Continue;
}