#include <sdkhooks>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

ConVar cv_explosions;

public Plugin myinfo =
{
	name = "[CSS/CSGO?] Epic Explosions",
	author = "StrikerMan780, Yaser2007",
	description = "Makes explosions create plumes of fire.",
	version = "1.1",
	url = "http://shadowmavericks.com"
};

public void OnPluginStart()
{
	cv_explosions = CreateConVar("sm_epic_explosions", "1", "Enable/Disable Epic Explosions Effect", FCVAR_REPLICATED, true, 0.0, true, 1.0);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(StrEqual(classname, "env_explosion"))
	{
		SDKHook(entity, SDKHook_Spawn, Explosion);
	}
}

public void OnEntityDestroyed(int entity)
{
	if(IsValidEntity(entity) && IsValidEdict(entity))
	{
		char classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));

		if(StrEqual(classname, "hegrenade_projectile"))
		{
			Explosion(entity);
		}
	}
}

void Explosion(int entity)
{
	if(!GetConVarBool(cv_explosions))
	{
		return;
	}

	int owner = GetEntPropEnt(entity, Prop_Data, "m_hOwnerEntity");

	if(IsValidClient(owner) && IsValidEdict(entity))
	{
		CreateParticle(entity, "Fire_Large_01", 0.2, false, false, true);
		CreateLight(entity, "255 100 10 255", 200.0, 0.1, false, true);
	}
}

stock bool IsValidClient(int client)
{
	if(client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	return false;
}

/**
* Description:	Function to check the entity limit.
*				Use before spawning an entity.
*/
#if !defined _entlimit_included
stock bool IsEntLimitReached(int warn = 20, int critical = 16, int client = 0, const char[] message = "")
{
	return (EntitiesAvailable(warn, critical, client, message) < warn);
}

stock int EntitiesAvailable(int warn = 20, int critical = 16, int client = 0, const char[] message = "")
{
	int max = GetMaxEntities();
	int count = GetEntityCount();
	int remaining = max - count;

	if(remaining <= critical)
	{
		PrintToServer("Warning: Entity limit is nearly reached! Please switch or reload the map!");
		LogError("Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);

		if(client > 0)
		{
			PrintToConsole(client, "Entity limit is nearly reached: %d/%d (%d):%s", count, max, remaining, message);
		}
	}
	else if(remaining <= warn)
	{
		PrintToServer("Caution: Entity count is getting high!");
		LogMessage("Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);

		if(client > 0)
		{
			PrintToConsole(client, "Entity count is getting high: %d/%d (%d):%s", count, max, remaining, message);
		}
	}
	return remaining;
}
#endif
/*****************************************************************/

// ------------------------------------------------------------------------
// CreateParticle()
// ------------------------------------------------------------------------
// >> Original code by J-Factor
// ------------------------------------------------------------------------
stock void CreateParticle(int iEntity, char[] strParticle, float time = 5.0, bool bAttach = false, bool bAngle = false, bool bKill = false, char[] strAttachmentPoint = "", float fOffset[3] = {0.0, 0.0, 0.0})
{
	if(IsEntLimitReached() || !IsValidEdict(iEntity))
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
		GetAngleVectors(fAngles, fForward, fRight, fUp);    // I assume 'x' is Right, 'y' is Forward and 'z' is Up
		fPosition[0] += fRight[0]*fOffset[0] + fForward[0]*fOffset[1] + fUp[0]*fOffset[2];
		fPosition[1] += fRight[1]*fOffset[0] + fForward[1]*fOffset[1] + fUp[1]*fOffset[2];
		fPosition[2] += fRight[2]*fOffset[0] + fForward[2]*fOffset[1] + fUp[2]*fOffset[2];

		// Teleport and attach
		if(bAngle == true)
		{
			TeleportEntity(iParticle, fPosition, fAngles, NULL_VECTOR);
		}
		else
		{
			TeleportEntity(iParticle, fPosition, NULL_VECTOR, NULL_VECTOR);
		}

		if(bAttach == true)
		{
			SetVariantString("!activator");
			AcceptEntityInput(iParticle, "SetParent", iEntity, iParticle, 0);

			if(StrEqual(strAttachmentPoint, "") == false)
			{
				SetVariantString(strAttachmentPoint);
				AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset", iParticle, iParticle, 0);            
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
		CreateTimer(time, Timer_KillParticle, iParticle);
	}
}

stock void CreateLight(int iEntity, char[] strColor, float distance, float time, bool bAttach = false, bool bKill = false, char[] strAttachmentPoint = "")
{
	if(IsEntLimitReached() || !IsValidEdict(iEntity))
	{
		return;
	}

	int iLight = CreateEntityByName("light_dynamic");

	if(IsValidEntity(iEntity))
	{
		// Spawn and start
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
			AcceptEntityInput(iLight, "SetParent", iEntity, iLight, 0);            

			if(StrEqual(strAttachmentPoint, "") == false)
			{
				SetVariantString(strAttachmentPoint);
				AcceptEntityInput(iLight, "SetParentAttachmentMaintainOffset", iLight, iLight, 0);                
			}
		}

		DispatchSpawn(iLight);

		ActivateEntity(iLight);
		AcceptEntityInput(iLight, "TurnOn");
	}

	if(bKill == true)
	{
		CreateTimer(time, Timer_KillLight, iLight);
	}
}

public Action Timer_KillParticle(Handle timer, any entity)
{
	if(IsValidEdict(entity) && IsValidEntity(entity))
	{
		char classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));

		if(StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(entity, "Stop");
			AcceptEntityInput(entity, "ClearParent");
			AcceptEntityInput(entity, "Kill");
		}
	}
	return Plugin_Continue;
}

public Action Timer_KillLight(Handle timer, any entity)
{
	if(IsValidEdict(entity) && IsValidEntity(entity))
	{
		char classname[64];
		GetEdictClassname(entity, classname, sizeof(classname));

		if(StrEqual(classname, "light_dynamic", false))
		{
			AcceptEntityInput(entity, "Kill");
		}
	}
	return Plugin_Continue;
}