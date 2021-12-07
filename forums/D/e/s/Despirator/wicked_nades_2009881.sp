#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <smlib>

public OnEntityCreated(entity, const String:classname[])
{
    if (StrContains(classname, "_projectile") != -1)
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
    }
}

public OnSpawnPost(entity)
{
	new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
	
	static Float:fVelp[3];
	
	new Float:RandomMult;
	
	if(Client_IsValid(client, true))
	{
		Entity_GetAbsVelocity(client, fVelp);
		new Float:currentspeed = SquareRoot(Pow(fVelp[0],2.0)+Pow(fVelp[1],2.0));
		
		RandomMult = currentspeed+1.0 / 2.0;
	}
	
	static Float:fVeln[3];
	Entity_GetAbsVelocity(entity, fVeln);
	
	fVeln[1] += GetRandomFloat(RandomMult*(-1.0), RandomMult);
	fVeln[0] += GetRandomFloat(RandomMult*(-1.0), RandomMult);
	
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, fVeln);
}  