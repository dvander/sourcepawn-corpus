/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdkhooks>

public Plugin:myinfo = 
{
	name = "damage reducer",
	author = "Nikooo777",
	description = "reduce damage with a 10x factor",
	version = "1.1",
	url = "elite-hunterz.info"
}

public OnClientPutInServer(client)
{
    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

public Action:OnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
    damage = damage/10;
	//PrintToChatAll("yes it fired");
	//PrintToChatAll("%d",damage);
    return Plugin_Changed;
}
/*
public OnPluginStart()
{
HookEvent("player_hurt", Event_player_hurt, EventHookMode_Pre)
}

public Action:Event_player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid")
	new victim = GetClientOfUserId(victimId)
	new healthlost = GetEventInt(event,"dmg_health")
	new Float:health = float(healthlost);
	SetEntityHealth(victim,GetEventInt(event,"health")+healthlost-RoundToNearest(health/10))
	return Plugin_Handled
}
*/