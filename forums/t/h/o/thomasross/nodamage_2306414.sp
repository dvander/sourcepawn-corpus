#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "NoDamage",
	author = "Thomas Ross",
	description = "Stops damage from being taken",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	for(new client; client <= MaxClients; client++)
	{
		if(IsClientValid(client))
		{
			SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage); 
		}
	}
}

bool:IsClientValid(client)
{
	if(client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

public OnClientPostAdminCheck(client)
{
	if(IsClientValid(client))
	{
		SDKHook(client, SDKHook_OnTakeDamage, Event_OnTakeDamage); 
	}
}

public Action:Event_OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype) 
{ 
    damage = 0.0; 
    return Plugin_Handled; 
}