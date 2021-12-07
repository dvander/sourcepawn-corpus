
#define PLUGIN_NAME           "ESPer Tank"
#define PLUGIN_AUTHOR         "spike1234"
#define PLUGIN_DESCRIPTION    "Throw many rocks with psychic power."
#define PLUGIN_VERSION        "1.2"
#define PLUGIN_URL            "https://forums.alliedmods.net/showthread.php?p=2679401#post2679401"

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

Handle g_hEnable;
Handle g_hDistanceV;
Handle g_hDistanceH;
Handle g_hCount;
Handle g_hFloatUpSpeed;
Handle g_hFloatGravity;
Handle g_hThrowDelay;
Handle g_hThrowDelayNext;
Handle g_hThrowSpeed;
Handle g_hThrowError;
Handle g_hDamage;
Handle g_hHealth;

bool 	g_bAbilityUsedRecently;
new 	g_tank;
float 	g_fDelay;

public void OnPluginStart()
{
	g_hEnable			= CreateConVar("sm_esperTank_enable"		, "1"		, "Whether enable plugin");
	g_hDistanceV		= CreateConVar("sm_esperTank_distance_v"	, "100.0"	, "How long distance(vertical) away when float up");
	g_hDistanceH		= CreateConVar("sm_esperTank_distance_h"	, "125.0"	, "How long distance(horizontal) away when float up");
	g_hCount			= CreateConVar("sm_esperTank_count"			, "4"		, "How many rocks float up at once");
	g_hFloatUpSpeed		= CreateConVar("sm_esperTank_floatSpeed"	, "25.0"	, "Momentum of float up");
	g_hFloatGravity		= CreateConVar("sm_esperTank_floatGravity"	, "-0.02"	, "Gravity while floating");
	g_hThrowDelay		= CreateConVar("sm_esperTank_delay"			, "1.5"		, "Wait this seconds for start throwing");
	g_hThrowDelayNext	= CreateConVar("sm_esperTank_delay_next"	, "0.2"		, "Delay(sec) of throwing next rock");
	g_hThrowSpeed		= CreateConVar("sm_esperTank_speed"			, "800"		, "Throwing power");
	g_hThrowError		= CreateConVar("sm_esperTank_error"			, "10.0"	, "Aim accuracy on throwing (10.0 = [-5.0 - +5.0] degrees get worse randomly)");
	g_hDamage			= CreateConVar("sm_esperTank_damage"		, "10"		, "Amount of damage");
	g_hHealth			= CreateConVar("sm_esperTank_health"		, "75"		, "Amount of rock's health");
	
	AutoExecConfig(true, "sm_esperTank");
	HookEvent("ability_use", OnStartThrow);
}

public Action OnStartThrow(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(g_hEnable))return;
	
	char ability_name[32];
	GetEventString(event, "ability", ability_name, sizeof(ability_name));
	if(!StrEqual(ability_name, "ability_throw"))return;
	
	g_tank = GetEventInt(event, "userid");
	g_fDelay = 1.0;
	for(int i=0; i<GetConVarInt(g_hCount); i++)
	CreateTimer(GetRandomFloat(0.0, 1.0), PrepareRock);
	
	g_bAbilityUsedRecently = true;
	CreateTimer(1.1, TimeOver);
}

public Action TimeOver(Handle timer)
{
	//this flag use to check rocks are created by tank's ability
	g_bAbilityUsedRecently = false;
}

public Action PrepareRock(Handle timer) //spawn rocks
{
	int tank = GetClientOfUserId(g_tank);
	if(!tank || !IsClientInGame(tank)) return;
	
	float vTankEyePos[3];
	float vTankEyeAng[3];
	GetClientEyePosition(tank, vTankEyePos);
	GetClientEyeAngles(tank, vTankEyeAng);
	
	//spawn rocks on circle line that tank centerd and radius based g_hDistanceH
	//to prevent hit rocks to tank, spawn them at higher position that spawned behind tank (g_hDistanceV based)
	float fRndAng = GetRandomFloat(-180.0,180.0);
	float vRandom[3];
	vRandom[0] = GetConVarFloat(g_hDistanceH) * Cosine(DegToRad(fRndAng));
	vRandom[1] = GetConVarFloat(g_hDistanceH) * Sine(DegToRad(fRndAng));
	vRandom[2] = GetConVarFloat(g_hDistanceV) * FloatAbs(fRndAng - vTankEyeAng[1])/180.0;
	
	//prepare to using ray
	float vRayPos[3];
	float vRayEndPos[3];
	AddVectors(vTankEyePos, vRandom, vRayPos);
	AddVectors(vTankEyePos, vRandom, vRayEndPos);
	vRayPos[2] += 450.0;
	vRayEndPos[2] -= 50.0;
	
	//to spawn rocks safety, check terrain around tank
	float vHitPos[3];
	TR_TraceRay(vRayPos, vRayEndPos, MASK_SHOT, RayType_EndPoint);
	TR_GetEndPosition(vHitPos);
	vHitPos[2] += 50.0;
	
	float vLaunchAng[3] = {-90.0, 0.0, 0.0};
	
	int launcher = CreateEntityByName("env_rock_launcher");
	DispatchSpawn(launcher);
	
	TeleportEntity(launcher, vHitPos, vLaunchAng, NULL_VECTOR);
	
	//set damage(don't work)
	char damage[32];
	GetConVarString(g_hDamage, damage, sizeof(damage));
	DispatchKeyValue(launcher, "rockdamageoverride", damage);
	
	//save original value of convar
	ConVar tmp_valueSave;
	tmp_valueSave = FindConVar("z_tank_throw_health");
	FindConVar("z_tank_throw_health").SetInt(GetConVarInt(g_hHealth), true, true);
	
	AcceptEntityInput(launcher, "LaunchRock");
	AcceptEntityInput(launcher, "Kill");
	
	//restore convar to original value(don't work)
	FindConVar("z_tank_throw_health").SetInt(GetConVarInt(tmp_valueSave), true, true);
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!GetConVarBool(g_hEnable))return;
	
	if(StrEqual(classname, "tank_rock") && g_bAbilityUsedRecently)
	{
		int entRef = EntIndexToEntRef(entity);
		
		CreateTimer(0.01, FloatUp, entRef);
		CreateTimer(GetConVarFloat(g_hThrowDelay) + GetConVarFloat(g_hThrowDelayNext) * g_fDelay, ThrowRock, entRef);
		
		g_fDelay ++;
	}
}

public Action FloatUp(Handle timer, any entRef) //float spawned rocks
{
	int entity = EntRefToEntIndex(entRef);
	if(entity == INVALID_ENT_REFERENCE) return;
	
	int tank = GetClientOfUserId(g_tank);
	if(tank && IsClientInGame(tank))
	{
		float vFloatVel[3];
		vFloatVel[2] = GetConVarFloat(g_hFloatUpSpeed);
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vFloatVel);
		SetEntityGravity(entity, GetConVarFloat(g_hFloatGravity));
		
		SetEntPropEnt(entity, Prop_Send, "m_hThrower", tank);
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", tank);
	}
	else
	{
		//delete rocks if tank was not found
		AcceptEntityInput(entity, "Kill");
	}
}

public Action ThrowRock(Handle timer, any entRef) //shoot floated rocks
{
	int entity = EntRefToEntIndex(entRef);
	if(entity == INVALID_ENT_REFERENCE) return;
	
	int tank = GetClientOfUserId(g_tank);
	if(tank && IsClientInGame(tank))
	{
		float vTankEyePos[3];
		float vTankEyeAng[3];
		GetClientEyePosition(tank, vTankEyePos);
		GetClientEyeAngles(tank, vTankEyeAng);
		
		//add aiming error
		float fError;
		fError = GetConVarFloat(g_hThrowError)/2.0;
		vTankEyeAng[0] += GetRandomFloat(-fError,fError);
		vTankEyeAng[1] += GetRandomFloat(-fError,fError);
		
		//get position where tank looking at
		float vAimPos[3];
		TR_TraceRayFilter(vTankEyePos, vTankEyeAng, MASK_OPAQUE, RayType_Infinite, TraceEntityFilter, tank);
		TR_GetEndPosition(vAimPos);
		
		float vRockPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin",vRockPos);
		
		float vVelocity[3];
		MakeVectorFromPoints(vRockPos, vAimPos, vVelocity);
		NormalizeVector(vVelocity, vVelocity);
		ScaleVector(vVelocity, GetConVarFloat(g_hThrowSpeed));
		
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
		SetEntityGravity(entity, -0.001);
	}
	else
	{
		//drop rocks if tank was not found
		float vVelocity[3] = {0.0};
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
		SetEntityGravity(entity, 0.5);
	}
}

public bool TraceEntityFilter(int entity, int contentsMask,any data)
{
	if(entity == data) return false;
	
	return true;
} 