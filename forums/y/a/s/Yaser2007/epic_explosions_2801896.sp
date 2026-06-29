#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

char sEntities[][32] =
{
	"hegrenade_projectile",
	"npc_grenade_frag",
	"grenade_ar2"
};

public Plugin myinfo =
{
	name = "Epic Explosions",
	author = "StrikerMan780, Yaser2007",
	description = "Makes explosions create plumes of fire.",
	version = "1.2",
	url = "http://shadowmavericks.com"
};

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "env_explosion"))
	{
		SDKHook(entity, SDKHook_Spawn, Explosion);
	}
}

public void OnEntityDestroyed(int entity)
{
	if(!IsValidEntity(entity))
	{
		return;
	}

	char classname[32];
	GetEntityClassname(entity, classname, sizeof(classname));
	int size = sizeof(sEntities);
	for(int i; i < size; i++)
	{
		if(StrEqual(classname, sEntities[i]))
		{
			Explosion(entity);
		}
	}
}

void Explosion(int entity)
{
	CreateParticle(entity, "Fire_Large_01", 0.2, false, false, true);
	CreateLight(entity, "255 100 10 255", 200.0, 0.1, false, true);
}

// ------------------------------------------------------------------------
// CreateParticle()
// ------------------------------------------------------------------------
// >> Original code by J-Factor
// ------------------------------------------------------------------------
stock void CreateParticle(int iEntity, char[] strParticle, float time = 5.0, bool bAttach = false, bool bAngle = false, bool bKill = false, char[] strAttachmentPoint = "", float fOffset[3] = {0.0, 0.0, 0.0})
{
	if(!IsValidEdict(iEntity))
	{
		return;
	}

	int iParticle = CreateEntityByName("info_particle_system");

	if(IsValidEdict(iParticle))
	{
		// Retrieve entity's position and angles
		float fPosition[3];
		float fAngles[3];
		float fForward[3];
		float fRight[3];
		float fUp[3];

		if(bAngle == true)
		{
			GetClientAbsOrigin(iEntity, fPosition);
			GetClientAbsAngles(iEntity, fAngles);
		}
		else
		{
			GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
		}

		// Determine vectors and apply offset
		GetAngleVectors(fAngles, fForward, fRight, fUp); // I assume 'x' is Right, 'y' is Forward and 'z' is Up
		fPosition[0] += fRight[0] * fOffset[0] + fForward[0] * fOffset[1] + fUp[0] * fOffset[2];
		fPosition[1] += fRight[1] * fOffset[0] + fForward[1] * fOffset[1] + fUp[1] * fOffset[2];
		fPosition[2] += fRight[2] * fOffset[0] + fForward[2] * fOffset[1] + fUp[2] * fOffset[2];

		// Teleport and attach
		TeleportEntity(iParticle, fPosition, bAngle == true ? fAngles : NULL_VECTOR);

		if(bAttach == true)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle);

			if(StrEqual(strAttachmentPoint, NULL_STRING) == false)
			{
				SetVariantString(strAttachmentPoint);
				AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle);
			}
		}

		// Spawn and start
		DispatchKeyValue(iParticle, "effect_name", strParticle);
		DispatchSpawn(iParticle);
		ActivateEntity(iParticle);
		AcceptEntityInput(iParticle, "Start");
	}

	if(bKill == true)
	{
		CreateTimer(time, Timer_KillParticle, EntIndexToEntRef(iParticle));
	}
}

stock void CreateLight(int iEntity, char[] strColor, float distance, float time, bool bAttach = false, bool bKill = false, char[] strAttachmentPoint = "")
{
	if(!IsValidEdict(iEntity) || !IsValidEntity(iEntity))
	{
		return;
	}

	// Spawn and start
	int iLight = CreateEntityByName("light_dynamic");
	DispatchKeyValue(iLight, "_inner_cone", "0");
	DispatchKeyValue(iLight, "_cone", "80");
	DispatchKeyValue(iLight, "brightness", "0");
	DispatchKeyValueFloat(iLight, "spotlight_radius", 200.0);
	DispatchKeyValueFloat(iLight, "distance", distance);
	DispatchKeyValue(iLight, "_light", strColor);
	DispatchKeyValue(iLight, "pitch", "-90");
	DispatchKeyValue(iLight, "style", "5");

	// Teleport and attach
	float fPosition[3];
	GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", fPosition);
	TeleportEntity(iLight, fPosition, NULL_VECTOR, NULL_VECTOR);

	if(bAttach == true)
	{
		SetVariantString("!activator");
		AcceptEntityInput(iLight, "SetParent", iEntity, iLight);
		if(StrEqual(strAttachmentPoint, "") == false)
		{
			SetVariantString(strAttachmentPoint);
			AcceptEntityInput(iLight, "SetParentAttachmentMaintainOffset", iLight, iLight);
		}
	}

	DispatchSpawn(iLight);
	ActivateEntity(iLight);
	AcceptEntityInput(iLight, "TurnOn");

	if(bKill == true)
	{
		CreateTimer(time, Timer_KillLight, EntIndexToEntRef(iLight));
	}
}

public void Timer_KillParticle(Handle timer, int entity)
{
	if((entity = EntRefToEntIndex(entity)) && IsValidEdict(entity))
	{
		RemoveEdict(entity);
	}
}

public void Timer_KillLight(Handle timer, int entity)
{
	if((entity = EntRefToEntIndex(entity)) && IsValidEdict(entity))
	{
		RemoveEdict(entity);
	}
}

stock bool IsValidClient(int client)
{
	if(client < 1 || client > MaxClients || !IsClientInGame(client))
	{
		return false;
	}

	return true;
}