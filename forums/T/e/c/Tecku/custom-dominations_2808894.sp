#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

public Plugin myinfo = 
{
	name = "[TF2] Custom Domination",
	author = "Tecku",
	description = "Add Custom Heavy Domination Lines",
	version = "1.0",
	url = "http://www.sourcemod.net/"
}

public OnPluginStart()
{
	HookEvent("player_domination", Event_PlayerDomination);
	
}

public Event_PlayerDomination(Handle:event, const String:name[], bool:dontBroadcast)
{ 
   	new victim = GetClientOfUserId(GetEventInt(event, "dominated"));
   	new attacker = GetClientOfUserId(GetEventInt(event, "dominator"));

	if (victim < 1 || victim > MaxClients)
	{
		return;
	}

	new TFClassType:victimClass = TF2_GetPlayerClass(victim);
	new TFClassType:attackerClass = TF2_GetPlayerClass(attacker)	
	
	PrintToConsole(attacker, "Message to attacker.");
	EmitSoundToAll("player/doubledonk.wav", attacker, _, SNDLEVEL_TRAFFIC, SND_NOFLAGS, 1.0, 100, _, _, NULL_VECTOR, true, 0.0);
}

