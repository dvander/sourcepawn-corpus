#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Psycheat"
#define PLUGIN_VERSION "2.0.2"

#include <sourcemod>
#include <sdktools>

EngineVersion g_Game;
ConVar gravity;
new Float:factor, Float:disp;
new trail;
new trailcolor[4];
new Float:dtime;
new String:nadelist[128] = "weapon_hegrenade weapon_smokegrenade weapon_flashbang weapon_incgrenade weapon_tagrenade weapon_molotov weapon_decoy";
new Handle:sm_gtrajectory;
new Handle:sm_gtrajectory_admin;
new Handle:sm_gtrajectory_size;
new Handle:sm_gtrajectory_timestep;
new Handle:sm_gtrajectory_delay;
new Handle:sm_gtrajectory_throw;
new Handle:sm_gtrajectory_lob;
new Handle:sm_gtrajectory_roll;

public Plugin:myinfo = 
{
	name = "Grenade Trajectory Prediction",
	author = PLUGIN_AUTHOR,
	description = "Predict the trajectory of a grenade before throwing.",
	version = PLUGIN_VERSION,
	url = ""
};

public OnPluginStart()
{
	g_Game = GetEngineVersion();
	if(g_Game != Engine_CSGO && g_Game != Engine_CSS)
	{
		SetFailState("This plugin is for CSGO/CSS only.");
	}
	
	gravity = FindConVar("sv_gravity");
	sm_gtrajectory = CreateConVar("sm_gtrajectory", "1.0", "Enable/Disable", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	sm_gtrajectory_admin = CreateConVar("sm_gtrajectory", "0.0", "Enable/disable grenade prediction for admin only", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	sm_gtrajectory_size = CreateConVar("sm_gtrajectory_size", "0.5", "Thickness of predicted trail", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.1, true, 10.0);
	sm_gtrajectory_timestep = CreateConVar("sm_gtrajectory_timestep", "0.05", "Time step for the loop, smaller = better accuracy", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.001, true, 0.5);
	sm_gtrajectory_delay= CreateConVar("sm_gtrajectory_delay", "0.0", "Delay set with other plugins", FCVAR_NOTIFY | FCVAR_DONTRECORD);
	sm_gtrajectory_throw= CreateConVar("sm_gtrajectory_throw", "0.9", "Grenade throwing speed adjustment: IN_ATTACK", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	sm_gtrajectory_lob= CreateConVar("sm_gtrajectory_lob", "0.6", "Grenade throwing speed adjustment: IN_ATTACK + IN_ATTACK2", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.0, true, 1.0);
	sm_gtrajectory_roll= CreateConVar("sm_gtrajectory_roll", "0.27", "Grenade throwing speed adjustment: IN_ATTACK2", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.0, true, 1.0);
}

public OnMapStart()
{
	trail = PrecacheModel("sprites/laserbeam.spr");
}

public Action:OnPlayerRunCmd(int client, int &buttons)
{
	if (!GetConVarBool(sm_gtrajectory))
		return Plugin_Continue;
	
	if (GetConVarBool(sm_gtrajectory_admin))
		if(!CheckCommandAccess(client, "gtrajectory_admin_flags", ADMFLAG_GENERIC))
			return Plugin_Continue;
	 
	if (!(buttons & IN_ATTACK) && !(buttons & IN_ATTACK2))
		return Plugin_Continue;
	
	decl String:cWeapon[32];
	GetClientWeapon(client, cWeapon, sizeof(cWeapon));
	if (StrContains(nadelist, cWeapon, false) != -1)
	{
		if (buttons & IN_ATTACK && buttons & IN_ATTACK2)
		{
			factor = GetConVarFloat(sm_gtrajectory_lob);
			disp = -6.0;
		}
		else if (buttons & IN_ATTACK)
		{
			factor = GetConVarFloat(sm_gtrajectory_throw);
			disp = 0.0;
		}
		else if (buttons & IN_ATTACK2)
		{
			factor = GetConVarFloat(sm_gtrajectory_roll);
			disp = -12.0;
		}
		
		ShowTrajectory(client, cWeapon);
	}
	
	return Plugin_Continue;
}

ShowTrajectory(int client, const String:cWeapon[])
{
	GetTrailColor(cWeapon);
	GetDetonationTime(cWeapon);
			
	new Float:GrenadeVelocity[3], Float:PlayerVelocity[3], Float:ThrowAngle[3], Float:ThrowVector[3], Float:ThrowVelocity;
	new Float:gStart[3], Float:gEnd[3], Float:fwd[3], Float:right[3], Float:up[3];
	
	GetClientEyeAngles(client, ThrowAngle);
	ThrowAngle[0] = -10.0 + ThrowAngle[0] + FloatAbs(ThrowAngle[0]) * 10.0 / 90.0;
	
	GetAngleVectors(ThrowAngle, fwd, right, up);
	NormalizeVector(fwd, ThrowVector);
	
	GetClientEyePosition(client, gStart);
	for (new i = 0; i < 3; i++)
		gStart[i] += ThrowVector[i] * 16.0;
	
	gStart[2] += disp;
	
	GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", PlayerVelocity);
	
	switch (g_Game)
	{
		case Engine_CSS:
		{
			ThrowVelocity = (90.0 - ThrowAngle[0]) * 6.0;
			if (ThrowVelocity > 750.0)
				ThrowVelocity = 750.0;
		}
		
		case Engine_CSGO:
		{
			ThrowVelocity = 750.0 * factor;
			ScaleVector(PlayerVelocity, 1.25);
		}
	}
	
	for (new i = 0; i < 3; i++)
		GrenadeVelocity[i] = ThrowVector[i] * ThrowVelocity + PlayerVelocity[i];
	
	new Float:dt = GetConVarFloat(sm_gtrajectory_timestep); 
	for (new Float:t = 0.0; t <= dtime; t += dt)
	{
		gEnd[0] = gStart[0] + GrenadeVelocity[0] * dt;
		gEnd[1] = gStart[1] + GrenadeVelocity[1] * dt;
		
		new Float:gForce = 0.4 * float(gravity.IntValue);
		new Float:NewVelocity = GrenadeVelocity[2] - gForce * dt;
		new Float:AvgVelocity = (GrenadeVelocity[2] + NewVelocity) / 2.0;
		
		gEnd[2] = gStart[2] + AvgVelocity * dt;
		GrenadeVelocity[2] = NewVelocity;
		
		new Float:mins[3] = {-2.0, -2.0, -2.0}, Float:maxs[3] = {2.0, 2.0, 2.0};
		new Handle:gRayTrace = TR_TraceHullEx(gStart, gEnd, mins, maxs, MASK_SHOT_HULL);
		if (TR_GetFraction(gRayTrace) != 1.0) 
		{
			if (TR_GetEntityIndex(gRayTrace) == client && t == 0.0)
			{
				CloseHandle(gRayTrace);
				gStart = gEnd;
				continue;
			}
			
			TR_GetEndPosition(gEnd, gRayTrace);
			
			new Float:NVector[3];
			TR_GetPlaneNormal(gRayTrace, NVector);
			new Float:Impulse = 2.0 * GetVectorDotProduct(NVector, GrenadeVelocity);
			for (new i = 0; i < 3; i++)
			{
				GrenadeVelocity[i] -= Impulse * NVector[i];
				
				if (FloatAbs(GrenadeVelocity[i]) < 0.1)
					GrenadeVelocity[i] = 0.0;
			}
			
			new Float:SurfaceElasticity = GetEntPropFloat(TR_GetEntityIndex(gRayTrace), Prop_Send, "m_flElasticity");
			new Float:elasticity = 0.45 * SurfaceElasticity;
			ScaleVector(GrenadeVelocity, elasticity);
			
			new Float:ZVector[3] = { 0.0, 0.0, 1.0 };
			if(GetVectorDotProduct(NVector, ZVector) > 0.7)
			{
				if (StrEqual(cWeapon, "weapon_incgrenade", false) || StrEqual(cWeapon, "weapon_molotov", false))
					dtime = 0.0;
			}
		}
		CloseHandle(gRayTrace);
		
		new Float:width = GetConVarFloat(sm_gtrajectory_size);
		TE_SetupBeamPoints(gStart, gEnd, trail, 0, 0, 0, 0.2, width, width, 0, 0.0, trailcolor, 0);
		TE_SendToClient(client, 0.0);
		
		gStart = gEnd;
	}
}

GetTrailColor(const String:weapon[])
{
	if (StrEqual(weapon, "weapon_hegrenade", false))
		trailcolor = { 255, 0, 0, 255 };
	else if (StrEqual(weapon, "weapon_smokegrenade", false))
		trailcolor = { 0, 255, 0, 255 };
	else if (StrEqual(weapon, "weapon_flashbang", false))
		trailcolor = { 0, 255, 255, 255 };
	else if (StrEqual(weapon, "weapon_incgrenade", false))
		trailcolor = { 255, 0, 255, 255 };
	else if (StrEqual(weapon, "weapon_tagrenade", false))
		trailcolor = { 0, 255, 255, 255 };
	else if (StrEqual(weapon, "weapon_molotov", false))
		trailcolor = { 255, 255, 0, 255 };
	else if (StrEqual(weapon, "weapon_decoy", false))
		trailcolor = { 255, 255, 255, 255 };
}

GetDetonationTime(const String:weapon[])
{
	if (StrContains("weapon_hegrenade weapon_flashbang", weapon,  false) != -1)
		dtime = 1.5 + GetConVarFloat(sm_gtrajectory_delay);
	else if (StrEqual("weapon_tagrenade", weapon, false))
		dtime = 5.0 + GetConVarFloat(sm_gtrajectory_delay);
	else
		dtime = 3.0 + GetConVarFloat(sm_gtrajectory_delay);
}
