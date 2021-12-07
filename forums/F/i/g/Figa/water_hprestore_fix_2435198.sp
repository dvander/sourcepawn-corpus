#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

public Plugin:myinfo = 
{
	name = "Fix Restore Health",
	author = "Figa",
	description = "Fix restore health if u incapacitated in water.",
	version = "1.0",
	url = "https://forums.alliedmods.net"
};

public OnPluginStart()
{
	HookEvent("player_incapacitated", Event_PlayerIncapacitated);
	HookEvent("player_hurt", Event_PlayerHurt, EventHookMode_Pre);
}
public Event_PlayerIncapacitated(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetClientOfUserId(GetEventInt(event, "attacker")))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (victim < 1 || !IsClientInGame(victim)) return;
		if (GetEventInt(event, "attackerentid") == 0 && GetEventInt(event, "type") == 16384)
		{
			new flag = GetEntityFlags(victim);   
			if(flag & FL_INWATER)
			{
				ClientCommand(victim, "vocalize Playerdeath");
				ForcePlayerSuicide(victim);
			}
		}
	}
}
public Event_PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetClientOfUserId(GetEventInt(event, "attacker")))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "userid"));
		if (victim < 1 || !IsClientInGame(victim)) return;
		
		if (GetEventInt(event, "attackerentid") == 0 && GetEventInt(event, "type") == 16384)
		{
			new victimHealth = GetEntProp(victim, Prop_Send, "m_iHealth");
			if (victimHealth > 10)
			{
				SlapPlayer(victim, 10, bool:false);
				ClientCommand(victim, "vocalize Playerdeath");
			}
			else if (victimHealth < 11 && victimHealth > 1)
			{
				SlapPlayer(victim, 0, bool:false);
				SetEntProp(victim, Prop_Send, "m_iHealth", 1);
				ClientCommand(victim, "vocalize Playerdeath");
			}
			else if (victimHealth < 2)
			{
				ClientCommand(victim, "vocalize Playerdeath");
				ForcePlayerSuicide(victim);
			}
		}
	}
}