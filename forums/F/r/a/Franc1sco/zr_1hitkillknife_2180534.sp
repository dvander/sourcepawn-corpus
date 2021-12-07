#include <sourcemod>
#include <sdkhooks>
#include <zombiereloaded>

#define PLUGIN_VERSION "1.0"


public Plugin:myinfo = 
{
	name = "ZR 1 Hit Kill Knife",
	author = "Franc1sco",
	description = "",
	version = PLUGIN_VERSION
}

public OnPluginStart()
{
    HookEvent("player_hurt", EnDamage, EventHookMode_Pre);
}

public Action:EnDamage(Handle:event, const String:name[], bool:dontBroadcast)
{
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if (!attacker) 
	{
		return Plugin_Continue;
	}

	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (IsPlayerAlive(attacker) && ZR_IsClientHuman(attacker) && ZR_IsClientZombie(client))
	{

		decl String:weapon[64];
		GetEventString(event, "weapon", weapon, sizeof(weapon));
    
		if(StrEqual(weapon, "knife", false))
		{
			SetEventInt(event, "dmg_health", 1000);
			return Plugin_Changed;
		}
	}
	return Plugin_Continue;
}