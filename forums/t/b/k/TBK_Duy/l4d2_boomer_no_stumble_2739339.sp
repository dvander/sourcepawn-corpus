#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo =  
{ 
    name = "[L4D2] Boomer Can't Be Shoved", 
    author = "TBK Duy", 
    description = "You can't shove dat fat ass boomer anymore (but the bots can lol)", 
    version = "1.0", 
    url = "" 
}; 

public OnPluginStart()
{ 
	HookEvent("player_shoved", Boomer_Shoved);
}

public Action Boomer_Shoved(Event event, const char[] name, bool dontBroadcast)
{
	int victim = GetClientOfUserId(GetEventInt(event, "userid")); 
	int attacker = GetClientOfUserId(GetEventInt(event, "attacker")); 

	if(0 < victim <= MaxClients && IsValidEntity(victim) && GetClientTeam(attacker) == 2 && IsValidEdict(victim) && GetEntProp(victim, Prop_Send, "m_zombieClass") == 2)
	{
		SetEntPropFloat(victim, Prop_Send, "m_flPlaybackRate", 9999.0);
		RequestFrame(Nextboomerframe, victim);
	}			
	return Plugin_Continue;
}	

public void Nextboomerframe(boomer)
{
	SetEntPropFloat(boomer, Prop_Send, "m_flPlaybackRate", 9999.0);
}
