#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "0.1"

new gOffsetHealth = -1;

public Plugin:myinfo =
{
	name = "SimpleHP",
	author = "Ghost.-",
	description = "",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	HookEvent("player_death", OnPlayerDeath);
	
	gOffsetHealth = FindSendPropOffs("CBasePlayer", "m_iHealth");
	if (gOffsetHealth == -1)
	{
		SetFailState("Unable to find offset for health.");
	}
}

public OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if (IsClientConnected(attacker) && IsPlayerAlive(attacker))
	{
		new currentHealth = GetClientHealth(attacker);
		if (currentHealth < 100)
		{
			decl String:weapon[32];
			GetEventString(event, "weapon", weapon, 32);
			
			new extraHealth = 5;
			if (StrEqual(weapon,"weapon_hegrenade"))
				extraHealth = 50;
			
			new newHealth = (currentHealth + extraHealth);
			
			if (newHealth >= 100)
				SetEntData(attacker, gOffsetHealth, 100);
			else
				SetEntData(attacker, gOffsetHealth, newHealth);
		}
	}
}