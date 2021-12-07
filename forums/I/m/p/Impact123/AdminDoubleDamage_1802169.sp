#include <sourcemod>
#include <sdkhooks>
#pragma semicolon 1



public Plugin:myinfo =
{
	name = "Admin Double Damage",
	author = "Tylerst & Impact",
	description = "Admins do double damage",
	version = "1.1.0",
	url = "none"
}




public OnPluginStart()
{	
	for(new i; i <= MaxClients; i++)
	{
		if(IsClientValid(i)) 
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
	if(IsClientValid(attacker))
	{
		if(CheckCommandAccess(attacker, "sm_admin_doubledamage", ADMFLAG_GENERIC))
		{
			damage *= 2.0;
			return Plugin_Changed;
		}
	}
	
	return Plugin_Continue;
}




stock bool:IsClientValid(id)
{
	if(id > 0 && id <= MaxClients && IsClientInGame(id))
	{
		return true;
	}
	
	return false;
}