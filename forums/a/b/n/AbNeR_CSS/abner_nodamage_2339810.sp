#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
new Handle:g_Enabled;

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "AbNeR No Player Damage",
	author = "AbNeR_CSS",
	description = "Godmod options.",
	version = PLUGIN_VERSION,
	url = "www.tecnohardclan.com"
}

public OnPluginStart()
{
	CreateConVar("abner_nodamage_version", PLUGIN_VERSION, "Plugin Version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	g_Enabled = CreateConVar("sm_nodamage", "2", "0 - Disabled, 1 - Only prevent fall/world damage, 2 - Only prevent damage from other players, 3 - Full godmode.");
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsValidClient(i))
		{
			SDKHook(i, SDKHook_OnTakeDamage, OnTakeDamage);
		}
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(client, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(GetConVarInt(g_Enabled) == 0)
	{
		return Plugin_Continue; //Normal damage
	}
	else if(GetConVarInt(g_Enabled) == 1)
	{
		if(!IsValidClient(attacker)) //Only prevent world damage;
		{
			return Plugin_Handled;
		}
	}
	else if(GetConVarInt(g_Enabled) == 2)
	{
		if(IsValidClient(attacker)) //Only prevent players damage
		{
			return Plugin_Handled;
		}
	}
	else if(GetConVarInt(g_Enabled) == 3)
	{
		return Plugin_Handled; //Full GodMod (PRETTY AWESOME)
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
