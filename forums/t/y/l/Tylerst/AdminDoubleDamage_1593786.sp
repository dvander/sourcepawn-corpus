#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "Admin Double Damage",
	author = "Tylerst",
	description = "Admins do double damage",
	version = "1.0.0",
	url = "none"
}

public OnPluginStart()
{	
	for (new i = 1; i <= MaxClients; i++)

	{
		if(IsClientInGame(i)) 
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}		
	}		
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(CheckCommandAccess(attacker, "sm_admin_doubledamage", ADMFLAG_GENERIC))
	{
		damage *= 2.0;
		return Plugin_Changed;
	}
	else return Plugin_Continue;
}