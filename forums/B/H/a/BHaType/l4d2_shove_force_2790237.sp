#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

ConVar sv_player_shove_force_min_scale, sv_player_shove_force_max_scale;
ConVar sv_player_shove_velocity_min, sv_player_shove_velocity_max;
ConVar sv_player_shove_angle_threshold;

Handle g_hSetAbsVelocityImpulse; 

public void OnPluginStart()
{
	GameData data = new GameData("l4d2_shove_force");

	StartPrepSDKCall(SDKCall_Entity);
	PrepSDKCall_SetFromConf(data, SDKConf_Signature, "CBaseEntity::ApplyAbsVelocityImpulse");
	PrepSDKCall_AddParameter(SDKType_Vector, SDKPass_ByRef);
	g_hSetAbsVelocityImpulse = EndPrepSDKCall();

	delete data;

	if (g_hSetAbsVelocityImpulse == null)
		SetFailState("g_hSetAbsVelocityImpulse == null");

	sv_player_shove_force_min_scale = CreateConVar("sv_player_shove_force_min_scale", "0.8", "Shove impulse scale min");
	sv_player_shove_force_max_scale = CreateConVar("sv_player_shove_force_max_scale", "1.2", "Shove impulse scale max");
	sv_player_shove_velocity_min = CreateConVar("sv_player_shove_velocity_min", "250.0", "Min Z velocity");
	sv_player_shove_velocity_max = CreateConVar("sv_player_shove_velocity_max", "450.0", "Max Z velocity");
	sv_player_shove_angle_threshold = CreateConVar("sv_player_shove_angle_threshold", "15.0", "Max angle threshold");
	
	AutoExecConfig(true, "l4d2_shove_force");
}

public void L4D2_OnEntityShoved_Post(int shover, int target, int weapon, const float vecDir[3] , bool bIsHighPounce)
{
	if (!target || target > MaxClients || !shover || shover > MaxClients || !IsClientInGame(target) || !IsClientInGame(shover))
		return;

	if (GetClientTeam(shover) != 2 || GetClientTeam(target) != 2)
		return;

	ApplyShoveImpulse(shover, target);
}

void ApplyShoveImpulse(int shover, int target)
{
	float start[3], end[3], dir[3], angle[3];
	float shover_vel[3], target_vel[3], base_vel[3], result[3];

	float ratioMin = sv_player_shove_force_min_scale.FloatValue;
	float ratioMax = sv_player_shove_force_max_scale.FloatValue;
	float velMin = sv_player_shove_velocity_min.FloatValue;
	float velMax = sv_player_shove_velocity_max.FloatValue;
	float angleThreshold = sv_player_shove_angle_threshold.FloatValue;
	float midvel = (velMin + velMax) / 2;

	GetClientAbsOrigin(shover, start);
	GetClientAbsOrigin(target, end);
	
	GetEntPropVector(shover, Prop_Data, "m_vecVelocity", shover_vel);	
	GetEntPropVector(target, Prop_Data, "m_vecVelocity", target_vel);	
	GetEntPropVector(target, Prop_Data, "m_vecBaseVelocity", base_vel);	

	MakeVectorFromPoints(start, end, dir);
	GetVectorAngles(dir, angle);
	
	angle[0] += GetRandomFloat(angleThreshold, -angleThreshold);
	angle[1] += GetRandomFloat(angleThreshold, -angleThreshold);

	GetAngleVectors(angle, result, NULL_VECTOR, NULL_VECTOR);

	result[0] *= midvel * GetRandomFloat(ratioMin, ratioMax);
	result[1] *= midvel * GetRandomFloat(ratioMin, ratioMax);
	result[2] = result[2] + midvel * GetRandomFloat(ratioMin, ratioMax);
	
	AddVectors(result, shover_vel, result);
	AddVectors(result, target_vel, result);
	AddVectors(result, base_vel, result);

	result[2] = clampf(result[2], velMin, velMax);

	L4D2Direct_DoAnimationEvent(target, 96 /* ANIM_TANK_PUNCH_GETUP */);
	ApplyAbsVelocityImpulse(target, result);
}

void ApplyAbsVelocityImpulse(int client, const float impulse[3])
{
	SDKCall(g_hSetAbsVelocityImpulse, client, impulse);
}

float clampf(float value, float min, float max)
{
	if (value < min)
		return min;

	if (value > max)
		return max;

	return value;
}