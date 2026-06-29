#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin:myinfo = {
	name = "RawketBawnce",
	author = "Asher \"asherkin\" Baker",
	description	= "Yep. You're screwed.",
	version = "1.0",
	url = "http://limetech.org/"
};

#define	MAX_EDICT_BITS	11
#define	MAX_EDICTS		(1 << MAX_EDICT_BITS)

new g_nBounces[MAX_EDICTS];

new Handle:g_hMaxBouncesConVar;
new g_config_iMaxBounces = 2;

public OnPluginStart()
{
	CreateConVar("rocketbounce_version", "1.0", "Corners, how do they work?", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hMaxBouncesConVar = CreateConVar("sm_rb_max", "2", "Max number of times a rocket will bounce.", FCVAR_NONE, true, 0.0, false);
	HookConVarChange(g_hMaxBouncesConVar, config_iMaxBounces_changed);
}

public config_iMaxBounces_changed(Handle:convar, const String:oldValue[], const String:newValue[])
{
	g_config_iMaxBounces = StringToInt(newValue);
}

public OnEntityCreated(entity, const String:classname[])
{
	if (!StrEqual(classname, "tf_projectile_rocket", false))
		return;
	
	g_nBounces[entity] = 0;
	SDKHook(entity, SDKHook_StartTouch, OnStartTouch);
}

public Action:OnStartTouch(entity, other)
{
	if (other > 0 && other <= MaxClients)
		return Plugin_Continue;
		
	// Only allow a rocket to bounce x times.
	if (g_nBounces[entity] >= g_config_iMaxBounces)
		return Plugin_Continue;
	
	SDKHook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public Action:OnTouch(entity, other)
{
	decl Float:vOrigin[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", vOrigin);
	
	decl Float:vAngles[3];
	GetEntPropVector(entity, Prop_Data, "m_angRotation", vAngles);
	
	decl Float:vVelocity[3];
	GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", vVelocity);
	
	new Handle:trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, entity);
	
	if(!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}
	
	decl Float:vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	//PrintToServer("Surface Normal: [%.2f, %.2f, %.2f]", vNormal[0], vNormal[1], vNormal[2]);
	
	CloseHandle(trace);
	
	new Float:dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	decl Float:vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	decl Float:vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
	//PrintToServer("Angles: [%.2f, %.2f, %.2f] -> [%.2f, %.2f, %.2f]", vAngles[0], vAngles[1], vAngles[2], vNewAngles[0], vNewAngles[1], vNewAngles[2]);
	//PrintToServer("Velocity: [%.2f, %.2f, %.2f] |%.2f| -> [%.2f, %.2f, %.2f] |%.2f|", vVelocity[0], vVelocity[1], vVelocity[2], GetVectorLength(vVelocity), vBounceVec[0], vBounceVec[1], vBounceVec[2], GetVectorLength(vBounceVec));
	
	TeleportEntity(entity, NULL_VECTOR, vNewAngles, vBounceVec);

	g_nBounces[entity]++;
	
	SDKUnhook(entity, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public bool:TEF_ExcludeEntity(entity, contentsMask, any:data)
{
	return (entity != data);
}