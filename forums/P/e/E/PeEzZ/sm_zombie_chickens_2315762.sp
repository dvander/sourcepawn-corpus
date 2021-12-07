#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin: myinfo =
{
	name = "Zombie Chickens",
	author = "PeEzZ",
	description = "Zombie chickens is here.",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?t=265790"
};

#define MODEL_CHICKEN_ZOMBIE "models/chicken/chicken_zombie.mdl"

public OnMapStart()
{
	PrecacheModel(MODEL_CHICKEN_ZOMBIE, true);
}

public OnEntityCreated(entity)
{
	if(IsValidEntity(entity))
	{
		new String: classname[32];
		GetEntityClassname(entity, classname, sizeof(classname));
		if(StrEqual(classname, "chicken"))
		{
			SDKHook(entity, SDKHook_SpawnPost, OnEntitySpawnPost);
		}
	}
}

//-----SDKHOOKS-----//
public OnEntitySpawnPost(entity)
{
	if(IsValidEntity(entity))
	{
		SetEntityModel(entity, MODEL_CHICKEN_ZOMBIE);
		HookSingleEntityOutput(entity, "OnBreak", OnBreak);
	}
}

//-----SINGLEOUTPUTS-----//
public OnBreak(const String: output[], caller, activator, Float: delay)
{
	new particle = CreateEntityByName("info_particle_system");
	if(IsValidEntity(particle))
	{
		new Float: pos[3];
		GetEntPropVector(caller, Prop_Send, "m_vecOrigin", pos);
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		
		DispatchKeyValue(particle, "effect_name", "chicken_gone_feathers_zombie");
		DispatchKeyValue(particle, "angles", "-90 0 0");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "Start");
		
		CreateTimer(5.0, Timer_KillParticle, EntIndexToEntRef(particle));
	}
}

//-----TIMERS-----//
public Action: Timer_KillParticle(Handle: timer, any: reference)
{
	new entity = EntRefToEntIndex(reference);
	if(entity != INVALID_ENT_REFERENCE)
	{
		AcceptEntityInput(entity, "Kill");
	}
}