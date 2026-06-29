#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public void OnPluginStart()
{
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}
public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int Vitima = GetClientOfUserId(event.GetInt("userid"));

	int Corpo = GetEntPropEnt(Vitima, Prop_Send, "m_hRagdoll");
	if (IsValidEdict(Corpo))
	{
		AcceptEntityInput(Corpo, "Kill");
	}
}

 