#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "Gascan Fixes",
	author = "tRololo312312",
	description = "Fixes some Gascan related exploits...",
	version = "1.0",
	url = "http://www.sourcemod.net/"
};

public OnEntityCreated(entity, const String:classname[])
{
	if(StrEqual(classname, "weapon_gascan"))
	{
		if(IsValidEntity(entity))
		{
			SDKHook(entity, SDKHook_SpawnPost, OnGascanSpawn);
			SDKHook(entity, SDKHook_OnTakeDamage, OnDamage);
		}
	}
}

public Action:OnDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype, &weapon, Float:damageForce[3], Float:damagePosition[3])
{
	damageForce[0] = 0.0;
	damageForce[1] = 0.0;
	damageForce[2] = 0.0;
	return Plugin_Changed;
}

public OnGascanSpawn(entity)
{
	if(IsValidEntity(entity))
	{
		SetEntProp(entity, Prop_Data, "m_CollisionGroup", 3);
	}
}
