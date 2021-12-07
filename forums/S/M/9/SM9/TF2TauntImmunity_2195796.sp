#include <tf2>
#include <sourcemod>
#include <sdkhooks>

#define PLUGIN_VERSION "0.1"

public Plugin:myinfo = 
{
	name = "TF2 Taunt Immunity",
	author = "xCoderx",
	description = "Prevents you from being killed while taunting.",
	version = PLUGIN_VERSION,
	url = "www.bravegaming.net"
}

new g_Taunting[MAXPLAYERS+1];

public OnPluginStart()
{
	CreateConVar ("tti_version", PLUGIN_VERSION, "TTI", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	
	for (new client = 1; client <= MaxClients; client++)
	{
		if(IsValidClient(client))
		{
			SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!IsValidClient(attacker) || !IsValidClient(victim))
		return Plugin_Continue;
	
	if(g_Taunting[victim] || g_Taunting[attacker])
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public TF2_OnConditionAdded(client, TFCond:condition)
{
	if (condition == TFCond_Taunting)
	{
		g_Taunting[client] = true;
	}
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if (condition == TFCond_Taunting)
	{
		g_Taunting[client] = false;
	}
}

stock bool:IsValidClient(client)
{
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}