#pragma semicolon 1

#define PLUGIN_AUTHOR "Rachnus"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <sdkhooks>

#pragma newdecls required

EngineVersion g_Game;

ConVar g_DroppedGrenadeDamage;
ConVar g_DroppedGrenadeRadius;

public Plugin myinfo = 
{
	name = "Explode Dropped Nades v1.0",
	author = PLUGIN_AUTHOR,
	description = "Shooting dropped grenades",
	version = PLUGIN_VERSION,
	url = "https://github.com/Rachnus"
};

public void OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");	
	}
	
	g_DroppedGrenadeDamage = CreateConVar("dropped_grenade_damage", "80", "Amount of damage the dropped grenade should deal");
	g_DroppedGrenadeRadius = CreateConVar("dropped_grenade_radius", "350", "Amount of radius the dropped grenade should have");
}

public void OnEntityCreated(int entity, const char[] classname)
{
	char szClassName[32];
	GetEntityClassname(entity, szClassName, sizeof(szClassName));
	if(StrEqual(szClassName, "weapon_hegrenade"))
	{
		SDKHook(entity, SDKHook_Spawn, OnGrenadeSpawn);
	}
}

public Action OnGrenadeSpawn(int entity)
{
	SetEntProp(entity, Prop_Data, "m_takedamage", 2);
	SDKHook(entity, SDKHook_OnTakeDamage, OnGrenadeTakeDamage);
}

public Action OnGrenadeTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	float pos[3];
	GetEntPropVector(victim, Prop_Data, "m_vecOrigin", pos);
	AcceptEntityInput(victim, "Kill");
	CS_CreateExplosion(attacker, g_DroppedGrenadeDamage.IntValue, g_DroppedGrenadeRadius.IntValue, pos);
}

void CS_CreateExplosion(int client, int damage, int radius, float pos[3])
{
	int entity;
	if((entity = CreateEntityByName("env_explosion")) != -1)
	{
		//DispatchKeyValue(entity, "spawnflags", "552");
		DispatchKeyValue(entity, "rendermode", "5");
		SetEntProp(entity, Prop_Data, "m_iMagnitude", damage);
		SetEntProp(entity, Prop_Data, "m_iRadiusOverride", radius);
		SetEntProp(entity, Prop_Data, "m_iTeamNum", GetClientTeam(client));
		SetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity", client);

		DispatchSpawn(entity);
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		EmitAmbientSound("weapons/hegrenade/explode4.wav", pos, entity);
		RequestFrame(TriggerExplosion, entity);
	}
}

public void TriggerExplosion(int entity)
{
	AcceptEntityInput(entity, "explode");
	AcceptEntityInput(entity, "Kill");
}