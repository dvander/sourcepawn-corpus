
/*=======================================================================================
	Change Log:
	
1.1 (29-10-2019)
	- Fixed "CreateEntityByName" 
	
1.0 
	- Initial release.
	 
=======================================================================================*/

#pragma semicolon 1
#pragma newdecls required

#include <sdktools>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "[L4D & L4D2] Rock Glow",
	author = "Joshe Gatito",
	description = "...",
	version = "1.1",
	url = "https://github.com/JosheGatitoSpartankii09"
};

public void OnEntityCreated (int entity, const char[] classname)
{	
	if (strcmp(classname, "tank_rock") == 0)
		SDKHook(entity, SDKHook_Spawn, SpawnThink);
}

public void SpawnThink(int entity)
{
	RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

public void OnNextFrame(int entity)
{
	int GlowRock = -1;
	float Pos[3], Ang[3];
	char sModel[PLATFORM_MAX_PATH];
	
	GetEntPropString(entity, Prop_Data, "m_ModelName", sModel, sizeof(sModel));
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", Pos);
	GetEntPropVector(entity, Prop_Send, "m_angRotation", Ang);
	
	if (IsL4D())
	{
		GlowRock = CreateEntityByName("prop_glowing_object"); 
		if( GlowRock == -1)
		{
		    LogError("Failed to create 'prop_glowing_object'");
		    return;
		}
		
		SetEntityModel(GlowRock, sModel);
		SetEntityRenderFx(GlowRock, RENDERFX_FADE_FAST);
		SetVariantString("!activator");
		AcceptEntityInput(GlowRock, "SetParent", entity);
		DispatchSpawn(GlowRock);
		AcceptEntityInput(GlowRock, "StartGlowing");
			
		TeleportEntity(GlowRock, Pos, Ang, NULL_VECTOR);
	}
	else 
	{
		GlowRock = CreateEntityByName("prop_dynamic_override"); 
		if( GlowRock == -1)
		{
		    LogError("Failed to create 'prop_dynamic_override'");
		    return;
		}
		
		SetEntityModel(GlowRock, sModel);
		SetVariantString("!activator");
		AcceptEntityInput(GlowRock, "SetParent", entity);
		DispatchSpawn(GlowRock);
		AcceptEntityInput(GlowRock, "StartGlowing");
		SetEntProp(GlowRock, Prop_Send, "m_iGlowType", 3);
		SetEntProp(GlowRock, Prop_Send, "m_nGlowRange", 5000);
		int R = GetRandomInt(1, 255), G = GetRandomInt(1, 255), B = GetRandomInt(1, 255);
		SetEntProp(GlowRock, Prop_Send, "m_glowColorOverride", R + (G * 256) + (B * 65536));

		TeleportEntity(GlowRock, Pos, Ang, NULL_VECTOR);
		
	}
}

bool IsL4D()
{
	EngineVersion engine = GetEngineVersion();
	return ( engine == Engine_Left4Dead );
}

/*
public bool DontHitSelfAndSurvivor (int entity, int mask)
{
	return (entity > MaxClients || !IsValidEntity(entity));
}

public bool TracerSurvivor(float pos[3], float angle[3])
{
	float pos1[3], pos2[3];
	pos[2] += 50.0;

	MakeVectorFromPoints(pos, angle, pos2); 
	GetVectorAngles(pos2, pos1); 

	Handle trace = TR_TraceRayFilterEx(pos, pos1, MASK_SOLID, RayType_Infinite, DontHitSelfAndSurvivor);

	bool r = false;
	if( TR_DidHit(trace) )
	{
		float hitpos[3];
		TR_GetEndPosition(hitpos, trace); 

		if( GetVectorDistance(pos, hitpos) + 25.0 >= GetVectorDistance(pos, angle) )
			r = true; 
	}
	else
		r = false;

	pos[2] -= 50.0;
	delete trace;
	return r;
}*/