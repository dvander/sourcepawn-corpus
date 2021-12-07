#include <sdkhooks>
#include <sdktools>
/* Plugin Info */
#define PLUGIN_NAME 			"Exploding grenades"
#define PLUGIN_VERSION_M 			"1.0.0"
#define PLUGIN_AUTHOR 			"IAmACow"
#define PLUGIN_DESCRIPTION		"Makes grenades explode when damaged"
#define PLUGIN_URL				"https://forums.alliedmods.net/member.php?u=258233"

#define DAMAGE_NO		0
#define DAMAGE_EVENTS_ONLY	1	// Call damage functions, but don't modify health
#define DAMAGE_YES		2
#define DAMAGE_AIM		3


#pragma newdecls required

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION_M,
	url = PLUGIN_URL
};

ConVar sm_exploding_grenades_enabled = null;

public void OnPluginStart()
{
	RegisterCvars();
}

/* 
 * Create convars here
 */
public void RegisterCvars()
{
	CreateConVar("sm_exploding_grenades_version", PLUGIN_VERSION_M, "", FCVAR_NOTIFY);
	sm_exploding_grenades_enabled = CreateConVar("sm_exploding_grenades_enabled", "1", "[bool] (0/1) Enable / disable exploding grenades plugin", FCVAR_NOTIFY);
}

public void OnEntityCreated(int entity, const char[] classname) 
{ 
	if(!IsValidEntity(entity))
		return;
	if(StrEqual(classname, "weapon_hegrenade"))
	{
		SDKHook(entity, SDKHook_SpawnPost, OnGrenadeSpawnPost);
	}
}

public void OnGrenadeSpawnPost(int entity)
{
	if(!IsValidEntity(entity))
		return;
	SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_YES);
	SDKHook(entity, SDKHook_OnTakeDamage, OnGrenadeTakeDamage);
}

public Action OnGrenadeTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype, int &weapon, float damageForce[3], float damagePosition[3])
{
	if(!sm_exploding_grenades_enabled.BoolValue)
		return Plugin_Continue;
	float pos[3];
	GetEntPropVector(victim, Prop_Data, "m_vecOrigin", pos);
	if(IsValidClient(attacker))
	{
		SpawnGrenadeOnLocation(attacker, pos);
	}
	AcceptEntityInput(victim, "Kill");
	return Plugin_Continue;
}


public void SpawnGrenadeOnLocation(const int thrower, const float fLoc[3])
{
	//https://developer.valvesoftware.com/wiki/Hegrenade_projectile
	int entity = CreateEntityByName("hegrenade_projectile");
	if(entity == -1)
		return;//its dead jim!
	SetVariantString("OnUser1 !self,InitializeSpawnFromWorld,,0.0,1");
	AcceptEntityInput(entity, "AddOutput");
	AcceptEntityInput(entity, "FireUser1");
	DispatchSpawn(entity); 
	SetEntPropEnt(entity, Prop_Data, "m_hThrower", thrower);
	SetEntProp(entity, Prop_Data, "m_iTeamNum", GetClientTeam(thrower));
	TeleportEntity(entity, fLoc, NULL_VECTOR, NULL_VECTOR);
}

/**
 * This function will check if we have a valid player
 **/
stock bool IsValidClient(int client,bool allowconsole=false)
{
	if(client == 0 && allowconsole)
	{
		return true;
	}
	if(client <= 0)
	{
		return false;
	}
	if(client > MaxClients)
	{
		return false;
	}
	if (!IsClientConnected(client)) 
	{ 
		return false; 
	} 
	if(!IsClientInGame(client))
	{
		return false;
	}
	if(IsFakeClient(client))
	{
		return false;
	}
	return true;
}