#include <sourcemod>
#include <takedamage>
#include <tf2>
#include <tf2_codes>
#include <dukehacks>

#pragma semicolon 1

#define PLUGIN_NAME "TF2 Fire Jarate"
#define PLUGIN_VERSION "1.0"

#define MDL_JAR "models/props_gameplay/bottle001.mdl"

new Handle:cvModel = INVALID_HANDLE;
new String:model[512];

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = "psychonic, TheSpyHunter, L.Duke",
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
}

public Action:OnTakeDamage(victim, attacker, inflictor)
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

// entity listener
public ResultType:dhOnEntitySpawned(edict)
{
	// get class name
	new String:classname[64];
	GetEdictClassname(edict, classname, sizeof(classname)); 
	
	// is entity a rocket?
	if (StrEqual(classname, "tf_projectile_jar"))
	{
		SetEntityModel(edict, model);
	}
	return;
}