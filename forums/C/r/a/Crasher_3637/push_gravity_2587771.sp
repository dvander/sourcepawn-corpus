#include <sourcemod>
#include <sdktools>
#include <vphysics>
#pragma semicolon 1
#pragma newdecls required
#define PLUGIN_VERSION "1.1"

public Plugin myinfo =
{
	name = "Push_Gravity",
	author = "Chi_Nai",
	description = "The world without gravity",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=306518"
}

public void OnPluginStart()
{
	HookEvent("entity_shoved", Event_Entity_Shoved);
	HookEvent("round_start", Event_RoundStart);
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	int iMax = GetMaxEntities();
	for (int i = MaxClients; i < iMax; i++)
	{
		if (IsValidEntity(i) && Phys_IsPhysicsObject(i))
		{
			Phys_EnableGravity(i, false);
		}
	}
}

public Action Event_Entity_Shoved(Event event, const char[] event_name, bool dontBroadcast)
{	 
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	int iEntity = iPushEnt(iAttacker);
	if (iEntity > 0)
	{
		vPush(iAttacker, iEntity, 100.0);
	}
}

void vPush(int client, int entity, float force)
{	
	float flAngles[3];
	float flOrigin[3];
	float flPos[3];
	GetClientEyePosition(client, flOrigin);
	GetClientEyeAngles(client, flAngles);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", flPos);
	float flVelocity[3];
	SubtractVectors(flPos, flOrigin, flVelocity);
	NormalizeVector(flVelocity, flVelocity);
	ScaleVector(flVelocity, force);
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, flVelocity);
	char sClassname[64];
	GetEdictClassname(entity, sClassname, 64);
	if (StrContains(sClassname, "prop_") != -1)
	{
		float flGravity[3];
		Phys_GetEnvironmentGravity(flGravity);
		flGravity[0] *= -0.01;
		flGravity[1] *= -0.01;
		flGravity[2] *= -0.01;
		Phys_SetEnvironmentGravity(flGravity);
		SetEntPropEnt(entity, Prop_Data, "m_hPhysicsAttacker", client);
		SetEntPropFloat(entity, Prop_Data, "m_flLastPhysicsInfluenceTime", GetEngineTime());
	}
}

int iPushEnt(int client)
{
	int iEntity = 0;
	float flAngles[3];
	float flOrigin[3];
	float flPos[3];
	GetClientEyePosition(client, flOrigin);
	GetClientEyeAngles(client, flAngles);
	Handle hTrace = TR_TraceRayFilterEx(flOrigin, flAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
	if(TR_DidHit(hTrace))
	{
		TR_GetEndPosition(flPos, hTrace);
		iEntity = TR_GetEntityIndex(hTrace);
	}

	hTrace.Close();
	return iEntity;
}

bool TraceRayDontHitSelf(int entity, any data)
{
	return (entity == data);
}