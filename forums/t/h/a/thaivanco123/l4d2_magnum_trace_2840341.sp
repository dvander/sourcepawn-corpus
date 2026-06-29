#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define PLUGIN_VERSION "1.0"

ConVar g_cvTracerType;

public void OnPluginStart()
{
	g_cvTracerType = CreateConVar("sm_tracer_type", "0", "0 = weapon_tracers_incendiary, 1 = weapon_tracers_explosive", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	HookEvent("weapon_fire", Event_WeaponFire);
}

public void OnMapStart()
{
	Precache_Particle_System("weapon_tracers_incendiary");
	Precache_Particle_System("weapon_tracers_explosive");
}

public Action Event_WeaponFire(Event event, const char[] name, bool dontBroadcast)
{
	int iClient = GetClientOfUserId(event.GetInt("userid"));
	if (iClient < 1 || iClient > MaxClients || !IsClientInGame(iClient) || IsFakeClient(iClient) || GetClientTeam(iClient) != 2)
	{
		return Plugin_Continue;
	}
	
	char sWeapon[32];
	event.GetString("weapon", sWeapon, sizeof(sWeapon));
	if (strcmp(sWeapon, "pistol_magnum") != 0)
	{
		return Plugin_Continue;
	}
	
	float fEyePos[3], fEyeAngles[3];
	GetClientEyePosition(iClient, fEyePos);
	GetClientEyeAngles(iClient, fEyeAngles);
	
	Handle hTrace = TR_TraceRayFilterEx(fEyePos, fEyeAngles, MASK_SHOT, RayType_Infinite, TraceFilter_Callback, iClient);
	if (TR_DidHit(hTrace))
	{
		float fEndPos[3];
		TR_GetEndPosition(fEndPos, hTrace);
		char sParticleName[64];
		if (g_cvTracerType.IntValue == 0)
		{
			strcopy(sParticleName, sizeof(sParticleName), "weapon_tracers_incendiary");
		}
		else
		{
			strcopy(sParticleName, sizeof(sParticleName), "weapon_tracers_explosive");
		}
		
		TE_SetupParticle_Name(sParticleName, fEyePos, fEndPos);
		TE_SendToAll();
	}
	
	delete hTrace;
	return Plugin_Continue;
}

public bool TraceFilter_Callback(int iEntity, int iContentsMask, any iData)
{
	return iEntity != iData;
} 