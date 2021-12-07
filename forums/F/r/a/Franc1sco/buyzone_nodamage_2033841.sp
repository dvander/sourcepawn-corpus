#pragma semicolon 1
#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo =
{
	name        = "SM NoDamage in buyzone",
	author      = "Franc1sco steam: franug",
	description = "this",
	version     = "1.0",
	url         = "www.servers-cfg.foroactivo.com"
};

public OnClientPutInServer(client)
{
   SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(!attacker) return Plugin_Continue;
	
	if(!GetEntProp(victim, Prop_Send, "m_bInBuyZone") && !GetEntProp(attacker, Prop_Send, "m_bInBuyZone")) return Plugin_Continue;
	
	PrintHintText(attacker, "You cant hurt in buy zone!");
	return Plugin_Handled;
}