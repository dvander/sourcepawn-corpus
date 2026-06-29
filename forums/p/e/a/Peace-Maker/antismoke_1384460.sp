#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Anti Smoke",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Prevents all smoke grenades from going poof.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_antismoke_version", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	if(hVersion != INVALID_HANDLE)
		SetConVarString(hVersion, PLUGIN_VERSION);
	
	AddNormalSoundHook(NormalSHook);
}

public Action:NormalSHook(clients[64], &numClients, String:sample[PLATFORM_MAX_PATH], &entity, &channel, &Float:volume, &level, &pitch, &flags)
{
	if(StrContains(sample, "sg_explode.wav") != -1)
		return Plugin_Stop;
	
	return Plugin_Continue;
}

public OnEntityCreated(entity, const String:classname[])
{
	if(StrContains(classname, "env_particlesmokegrenade") != -1)
	{
		RemoveEdict(entity);
	}
}