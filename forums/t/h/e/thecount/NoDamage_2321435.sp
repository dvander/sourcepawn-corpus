#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public OnClientPutInServer(client){ SDKHook(client, SDKHook_OnTakeDamage, OnDamage); }

public Action:OnDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype){
	damage = 0.0;
	return Plugin_Changed;
}