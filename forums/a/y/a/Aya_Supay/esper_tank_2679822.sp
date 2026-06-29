
#define PLUGIN_NAME           "ESPer Tank"
#define PLUGIN_AUTHOR         "spike1234"
#define PLUGIN_DESCRIPTION    "Throw many rocks with psychic power."
#define PLUGIN_VERSION        "1.0"
#define PLUGIN_URL            "https://forums.alliedmods.net/showthread.php?p=2679401#post2679401"

#pragma semicolon 1 
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

public Plugin myinfo =
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
}

ConVar g_hEnable, g_hDistanceV, g_hDistanceH, g_hCount, g_hFloatUpSpeed, g_hFloatGravity, g_hThrowDelay, g_hThrowDelayNext, g_hThrowSpeed, 
 	g_hThrowError, g_hDamage, g_hHealth;
bool g_bAbilityUsedRecently;
int 	g_tank;
float g_fDelay;

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

public Action OnStartThrow(Event event, const char[] name, bool dontBroadcast)
{
	if(!g_hEnable.BoolValue)return;
	
	char ability_name[32];
	GetEventString(event, "ability", ability_name, sizeof(ability_name));
	if(!StrEqual(ability_name, "ability_throw"))return;

	g_tank = GetClientOfUserId(event.GetInt("userid"));	
	g_fDelay = 1.0;
	for(int i=0; i < g_hCount.IntValue; i++)
	{CreateTimer(GetRandomFloat(0.0, 1.0), FloatRock);}
	
	g_bAbilityUsedRecently = true;
	CreateTimer(1.1, TimeOver);
}

public Action TimeOver(Handle timer)
{
	g_bAbilityUsedRecently = false;
}

public Action FloatRock(Handle timer)
{
	if(g_tank > 0 && g_tank <= MaxClients && IsClientInGame(g_tank)) 
	{
		float vTankEyePos[3], vTankEyeAng[3];
		GetClientEyePosition(g_tank, vTankEyePos);
		GetClientEyeAngles(g_tank, vTankEyeAng);
		
		float vRandom[3];
		float fRndAng = GetRandomFloat(-180.0,180.0);
		vRandom[0] = g_hDistanceH.FloatValue * Cosine(DegToRad(fRndAng));
		vRandom[1] = g_hDistanceH.FloatValue * Sine(DegToRad(fRndAng));
		vRandom[2] = g_hDistanceV.FloatValue * FloatAbs(fRndAng - vTankEyeAng[1])/180.0;
		
		float vRayPos[3], vRayEndPos[3];
		AddVectors(vTankEyePos, vRandom, vRayPos);
		AddVectors(vTankEyePos, vRandom, vRayEndPos);
		vRayPos[2] += 150.0;
		vRayEndPos[2] -= 50.0;
		
		float vHitPos[3];
		TR_TraceRay(vRayPos, vRayEndPos, MASK_SHOT, RayType_EndPoint);
		TR_GetEndPosition(vHitPos);
		
		float vAng[3] = {-90.0, 0.0, 0.0};
		
		int launcher = CreateEntityByName("env_rock_launcher");
		DispatchSpawn(launcher);
		TeleportEntity(launcher, vHitPos, vAng, NULL_VECTOR);
		char damage[32];
		GetConVarString(g_hDamage, damage, sizeof(damage));
		DispatchKeyValue(launcher, "rockdamageoverride", damage);
		
		ConVar tmp_valueSave;
		tmp_valueSave = FindConVar("z_tank_throw_health");
		FindConVar("z_tank_throw_health").SetInt(g_hHealth.IntValue, true, true);
		
		AcceptEntityInput(launcher, "LaunchRock");
		AcceptEntityInput(launcher, "Kill");
		
		FindConVar("z_tank_throw_health").SetInt(tmp_valueSave.IntValue, true, true);
	}
}

public void OnEntityCreated(int entity, const char[] classname)
{
	if(!g_hEnable.BoolValue)return;
	
	if(StrEqual(classname, "tank_rock") && g_bAbilityUsedRecently)
	{
		CreateTimer(0.01, FloatRockUp, entity);
		
		CreateTimer(g_hThrowDelay.FloatValue + g_hThrowDelayNext.FloatValue * g_fDelay, ThrowRock, entity);
		g_fDelay ++;
	}
}

public Action FloatRockUp(Handle timer, any entity)
{
	if(!IsValidEdict(entity))return;
	if(!IsValidEntity(entity))return;
	
	float vel[3];
	vel[2] = g_hFloatUpSpeed.FloatValue;
	TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vel);
	SetEntityGravity(entity, g_hFloatGravity.FloatValue);
	
	SetEntPropEnt(entity, Prop_Send, "m_hThrower", g_tank);
	SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", g_tank);
}

public Action ThrowRock(Handle timer, any entity)
{
	if(!IsValidEdict(entity))return;
	if(!IsValidEntity(entity))return;

	if(g_tank > 0 && g_tank <= MaxClients && IsClientInGame(g_tank)) 
	{
		float vTankEyePos[3], vTankEyeAng[3];
		GetClientEyePosition(g_tank, vTankEyePos);
		GetClientEyeAngles(g_tank, vTankEyeAng);
		
		float fError;
		fError = g_hThrowError.FloatValue /2.0;
		vTankEyeAng[0] += GetRandomFloat(-fError,fError);
		vTankEyeAng[1] += GetRandomFloat(-fError,fError);
		
		float vAimPos[3];
		TR_TraceRayFilter(vTankEyePos, vTankEyeAng, MASK_OPAQUE, RayType_Infinite, TraceEntityFilter, g_tank);
		TR_GetEndPosition(vAimPos);
		
		float vRockPos[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin",vRockPos);
		
		float vVelocity[3];
		MakeVectorFromPoints(vRockPos, vAimPos, vVelocity);
		NormalizeVector(vVelocity, vVelocity);
		ScaleVector(vVelocity, g_hThrowSpeed.FloatValue);
		
		TeleportEntity(entity, NULL_VECTOR, NULL_VECTOR, vVelocity);
		SetEntityGravity(entity, -0.001);
	}
}

public bool TraceEntityFilter(int entity, int contentsMask, any data)
{
	if(entity == data)return false;
	
	return true;
} 