#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = 
{
    name = "Invulnerable Players",
    author = "Kyle Sanderson",
    description = "Makes everyone Invulnerable.",
    version = "1.0",
    url = ""
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(attacker && attacker <= MaxClients)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}