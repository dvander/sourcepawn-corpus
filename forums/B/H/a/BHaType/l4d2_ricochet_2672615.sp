#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define Sound "weapons/fx/rics/ric1.wav"

#define Tracer "weapon_tracers_incendiary"
#define Tracer1 "weapon_tracers_explosive"
#define Tracer2 "weapon_tracers"

public Plugin myinfo = 
{
	name = "[L4D2] Ricochet",
	author = "BHaType",
	description = "Add ricochet system for weapons",
	version = "0.0",
	url = "Diary"
};

int g_iTracerType, g_iChance, g_iDamage, g_iDamageType;
float g_flAngle;
ConVar g_hTracerType, g_hAngle, g_hChance, g_hDamage, g_hDamageType;

public void OnPluginStart()
{
	g_hTracerType = CreateConVar("sm_ricochet_tracer_type", "0", "What type of tracers shuld we use?\n 0 - incendiary\n 1 - explosive\n 2 - Original weapon tracers", FCVAR_NONE, true, 0.0, true, 2.0);
	g_hAngle = CreateConVar("sm_ricochet_angle", "135.0", "Angle to ricochet", FCVAR_NONE);
	g_hChance = CreateConVar("sm_ricochet_chance", "100", "Chance of ricochet", FCVAR_NONE, true, 0.0, true, 100.0);
	g_hDamage = CreateConVar("sm_ricochet_damage", "5", "Damage of ricochet", FCVAR_NONE);
	g_hDamageType = CreateConVar("sm_ricochet_damage_type", "8", "Damage type of ricochet", FCVAR_NONE);
	
	AutoExecConfig(true, "l4d2_ricohet");
	
	g_iTracerType = g_hTracerType.IntValue;
	g_iChance = g_hChance.IntValue;
	g_iDamage = g_hDamage.IntValue;
	g_iDamageType = g_hDamageType.IntValue;
	g_flAngle = g_hAngle.FloatValue;
	
	g_hTracerType.AddChangeHook(OnConVarChanged);
	g_hChance.AddChangeHook(OnConVarChanged);
	g_hDamage.AddChangeHook(OnConVarChanged);
	g_hDamageType.AddChangeHook(OnConVarChanged);
	g_hAngle.AddChangeHook(OnConVarChanged);
	
	HookEvent("bullet_impact", eEvent);
}

public void OnMapStart()
{
	PrecacheSound(Sound);
	
	PrecacheParticle(Tracer);
	PrecacheParticle(Tracer1);
	PrecacheParticle(Tracer2);
}

public void OnConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	g_iTracerType = g_hTracerType.IntValue;
	g_iChance = g_hChance.IntValue;
	g_iDamage = g_hDamage.IntValue;
	g_iDamageType = g_hDamageType.IntValue;
	g_flAngle = g_hAngle.FloatValue;
}

public void eEvent (Event event, const char[] name, bool dontbroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (!client || GetClientTeam(client) != 2)
		return;
		
	float vAngles[3], vOrigin[3], vEnd[3], vDir[3], vResult[3], vPlane[3];
	
	vEnd[0] = event.GetFloat("x");
	vEnd[1] = event.GetFloat("y");
	vEnd[2] = event.GetFloat("z");
	
	GetClientEyeAngles(client, vAngles);
	GetClientEyePosition(client, vOrigin);
	
	GetAngleVectors(vAngles, vDir, NULL_VECTOR, NULL_VECTOR);
	
	Handle TraceRay = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SOLID, RayType_Infinite, TraceFilter, client);
	
	if (!TR_DidHit(TraceRay))
	{
		delete TraceRay;
		return;
	}

	TR_GetPlaneNormal(TraceRay, vPlane);
	
	delete TraceRay;
	
	if (RadToDeg(ArcCosine(GetVectorDotProduct(vDir, vPlane))) > g_flAngle || GetRandomInt(1, 100) > g_iChance)
		return;
	
	TE_SetupSparks(vEnd, vDir, GetRandomInt(1, 2), GetRandomInt(1, 2));
	TE_SendToAll();
	
	NormalizeVector(vDir, vDir);
	
	ScaleVector(vPlane, 2.0);
	ScaleVector(vPlane, GetVectorDotProduct(vDir, vPlane));
	ScaleVector(vPlane, GetVectorLength(vDir));
	
	SubtractVectors(vDir, vPlane, vResult);
	
	GetVectorAngles(vResult, vAngles);
	
	vAngles[0] += GetRandomFloat(-5.0, 5.0);
	vAngles[1] += GetRandomFloat(-5.0, 5.0);
	
	TraceRay = TR_TraceRayFilterEx(vEnd, vAngles, MASK_SOLID, RayType_Infinite, TraceFilter, 0);
	
	if (!TR_DidHit(TraceRay))
	{
		delete TraceRay;
		return;
	}
	
	TR_GetEndPosition(vResult, TraceRay);
	
	int iTarget = TR_GetEntityIndex(TraceRay);
	
	delete TraceRay;
	
	DisplayRicochet(vEnd, vResult);
	EmitSoundToAll(Sound, SOUND_FROM_WORLD, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, SNDVOL_NORMAL, SNDPITCH_NORMAL, _, vEnd);
	
	if (iTarget <= 0 || g_iDamage == 0)
		return;
	
	SDKHooks_TakeDamage(iTarget, client, client, float(g_iDamage), g_iDamageType);
}

void DisplayRicochet(float vStart[3], float vEnd[3])
{  
 	char szName[16];
	int iEntity = CreateEntityByName("info_particle_target");
	
	if (iEntity == -1)
		return;
	
	Format(szName, sizeof szName, "IInfo%d", iEntity);
	DispatchKeyValue(iEntity, "targetname", szName);	
	
	TeleportEntity(iEntity, vEnd, NULL_VECTOR, NULL_VECTOR); 
	ActivateEntity(iEntity); 
	
	SetVariantString("OnUser4 !self:Kill::1.1:-1");
	AcceptEntityInput(iEntity, "AddOutput");
	AcceptEntityInput(iEntity, "FireUser4");
	
	iEntity = CreateEntityByName("info_particle_system");
	
	if (iEntity == -1)
		return;
	
	switch (g_iTracerType)
	{
		case 0: DispatchKeyValue(iEntity, "effect_name", Tracer);
		case 1: DispatchKeyValue(iEntity, "effect_name", Tracer1);
		case 2: DispatchKeyValue(iEntity, "effect_name", Tracer2);
	}
	
	DispatchKeyValue(iEntity, "cpoint1", szName);
	
	TeleportEntity(iEntity, vStart, NULL_VECTOR, NULL_VECTOR);
	DispatchSpawn(iEntity);
	ActivateEntity(iEntity); 
	
	AcceptEntityInput(iEntity, "Start");
	
	SetVariantString("OnUser4 !self:Kill::1.1:-1");
	AcceptEntityInput(iEntity, "AddOutput");
	AcceptEntityInput(iEntity, "FireUser4");
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

public bool TraceFilter(int entity, int mask, int client)
{
	if (entity == client)
		return false;
	return true;
}