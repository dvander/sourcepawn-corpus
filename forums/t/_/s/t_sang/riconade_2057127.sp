#include <sdkhooks>
#include <sdktools>

#define PLUGIN_VERSION	 "1.0.1"
const Float:BOUNCE_MULTIPLIER = 1.1111111111
#define ACCESS_CMD "sm_riconade"

public Plugin:myinfo = 
{
	name = "RicoNade",
	author = "AlexSang",
	description = "Ricochet HE grenade",
	version = PLUGIN_VERSION,
	url = "http://steamcommunity.com/id/AlexSang"
}

public OnPluginStart()
{
	CreateConVar("riconade_version", PLUGIN_VERSION, "RicoNade Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_UNLOGGED|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY)

	RegConsoleCmd(ACCESS_CMD, Cmd_Riconade)
}

public OnEntityCreated(entity, const String:classname[])
{
	if (StrEqual(classname, "hegrenade_projectile"))
	{
		SDKHook(entity, SDKHook_Spawn, OnEntitySpawned)		
	}
}

public OnEntitySpawned(entity)
{
	SDKUnhook(entity, SDKHook_Spawn, OnEntitySpawned)	
	new entityRef = EntIndexToEntRef(entity)
	CreateTimer(0.0, Timer_OnGrenadeCreated, entityRef)
}

public Action:Timer_OnGrenadeCreated(Handle:timer, any:entityRef)
{
	new entity = EntRefToEntIndex(entityRef)
	if (entity != INVALID_ENT_REFERENCE)
	{
		new thrower = GetEntPropEnt(entity, Prop_Data, "m_hThrower")
		if (CheckCommandAccess(thrower, ACCESS_CMD, 0))
		{
			SDKHook(entity, SDKHook_Touch, OnEntityTouch)
			SetEntProp(entity, Prop_Data, "m_nNextThinkTick", -1)
			SetEntPropFloat(entity, Prop_Data, "m_flElasticity", 1.0)
			SetEntityMoveType(entity, MOVETYPE_FLY)
		}
	}
}

public OnEntityTouch(nadeEntity, other)
{
	if (IsPlayer(other))
	{
		Detonate(nadeEntity)
	}
	else if (IsEntitySolid(other))
	{
		AcceptBounceMultiplier(nadeEntity)
	}
}

AcceptBounceMultiplier(nadeEntity)
{
	decl Float:oldVelocity[3]
	GetEntPropVector(nadeEntity, Prop_Data, "m_vecVelocity", oldVelocity)

	decl Float:newVelocity[3]		
	for (new i = 0; i < 3; i++)
	{
		newVelocity[i] = oldVelocity[i] * BOUNCE_MULTIPLIER
	}

	TeleportEntity(nadeEntity, NULL_VECTOR, NULL_VECTOR, newVelocity)
}

Detonate(nadeEntity)
{
	SetEntityMoveType(nadeEntity, MOVETYPE_NONE)
	SetEntProp(nadeEntity, Prop_Data, "m_nNextThinkTick", 1)
}

bool:IsEntitySolid(entity)
{
	decl String:classname[32];
	GetEdictClassname(entity, classname, sizeof(classname))
	return StrContains(classname, "trigger_", false) < 0 
		&& StrContains(classname, "func_", false) < 0
}

bool:IsPlayer(entity)
{
	return entity >= 1
		&& entity <= MaxClients
		&& IsClientInGame(entity)
		&& IsPlayerAlive(entity)
}

public Action:Cmd_Riconade(client, argc)
{
	return Plugin_Handled
}