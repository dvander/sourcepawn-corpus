#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <tf2>

#pragma semicolon 1

#define PLUGIN_NAME "TF2 Fire Jarate"
#define PLUGIN_VERSION "1.1"

#define MDL_JAR "models/props_gameplay/bottle001.mdl"

new Handle:cvModel = INVALID_HANDLE;
new String:model[512];

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "psychonic, TheSpyHunter, L.Duke, xCoderx",
	description = "Jarate cause victim to catch on fire",
	version = PLUGIN_VERSION,
	url = "http://www.ultimatefragforce.co.uk"
};

public OnConfigsExecuted()
{
	GetConVarString(cvModel, model, sizeof(model));
	PrecacheModel(model, true);
}

public OnPluginStart()
{
	CreateConVar("sm_firejarate_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvModel = CreateConVar("sm_jar_model", MDL_JAR, "model for jarate bomb");
	
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
	if (inflictor > 0 && inflictor <= MaxClients
	&& IsClientInGame(inflictor) && IsClientInGame(victim) 
	&& GetClientHealth(victim) > 0)
	{
		if (IsClientInGame(victim) && GetEntData(victim, FindSendPropInfo("CTFPlayer", "m_nPlayerCond")) & (1 << 19))
		{
			TF2_IgnitePlayer(victim, attacker);
		}
	}
}

public OnEntityCreated(entity)
{
	SDKHook(entity, SDKHook_Spawn, EntSpawn);
}

public Action:EntSpawn(entity)
{
	new String:g_sClassName[64];
	GetEntityClassname(entity, g_sClassName, sizeof(g_sClassName));
	
	if (StrEqual(g_sClassName, "tf_projectile_jar"))
	{
		SetEntityModel(entity, model);
	}
	return;
}

stock bool:IsValidClient(client)
{
	if(client < 1 || client > MaxClients) return false;
	if(!IsClientInGame(client)) return false;
	if(IsClientSourceTV(client) || IsClientReplay(client)) return false;
	return true;
}
	