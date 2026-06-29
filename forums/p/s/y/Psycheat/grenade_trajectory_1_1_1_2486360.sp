/*
Psycheat: Grenade Path

Hi everyone, hoped you enjoyed this plugin. It took me two full days and night to write and test this plugin.
The calculation of grenade path is directly taken from the following scripts of Source SDK 2013:

weapon_grenade.cpp
weapon_basesdkgrenade.cpp
sdk_basegrenade_projectile.h
sdk_basegrenade_projectile.cpp
physics_main_shared.cpp

Currently the path would only be accurately if the entity it bounces off are not breakable and is not water.
i.e. trails would not be correct if grenade bounces off the following:

water surface
windows
other breakable stuff

If the map you player have moving surfaces or teleportation, those wouldnt work as well.
If you have other plugins that change the grenade detonation time, you would have to change the time value for yourself.

*/
#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Psycheat"
#define PLUGIN_VERSION "1.1.1"

#include <sourcemod>
#include <sdktools>

EngineVersion g_Game;
ConVar gravity;
new trail;
new trailcolor[4];
new Float:dtime;
new String:nadelist[128] = "weapon_hegrenade weapon_smokegrenade weapon_flashbang weapon_incgrenade weapon_molotov weapon_decoy";
new Handle:sm_gtrajectory;
new Handle:sm_gtrajectory_size;
new Handle:sm_gtrajectory_timestep;
new Handle:sm_gtrajectory_delay;

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
	sm_gtrajectory_size = CreateConVar("sm_gtrajectory_size", "1.0", "Thickness of predicted trail", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.1, true, 10.0);
	sm_gtrajectory_timestep = CreateConVar("sm_gtrajectory_timestep", "0.1", "Time step for the loop, smaller = better accuracy", FCVAR_NOTIFY | FCVAR_DONTRECORD, true, 0.001, true, 0.5);
	sm_gtrajectory_delay= CreateConVar("sm_gtrajectory_delay", "0.0", "Delay set with other plugins", FCVAR_NOTIFY | FCVAR_DONTRECORD);
}

public OnMapStart()
{
	trail = PrecacheModel("sprites/laserbeam.spr");
}

public Action:OnPlayerRunCmd(int client, int &buttons)
{
	if (!GetConVarBool(sm_gtrajectory))
		return Plugin_Continue;
	
	if (buttons & IN_ATTACK)
	{
		decl String:cWeapon[32];
		GetClientWeapon(client, cWeapon, sizeof(cWeapon));
		
		if (StrContains(nadelist, cWeapon, false) != -1) // grenade path start to render if your current weapon type is grenade and you are holding down the attack button
		{
			GetTrailColor(cWeapon);
			GetDetonationTime(cWeapon);
			
			new Float:GrenadeVelocity[3], Float:PlayerVelocity[3], Float:ThrowAngle[3], Float:ThrowVector[3], Float:ThrowVelocity;
			new Float:gStart[3], Float:gEnd[3], Float:fwd[3], Float:right[3], Float:up[3];
			
			GetClientEyeAngles(client, ThrowAngle);
			ThrowAngle[0] = -10.0 + ThrowAngle[0] + FloatAbs(ThrowAngle[0]) * 10.0 / 90.0; // modified formula from weapon_basesdkgrenade.cpp
			
			GetAngleVectors(ThrowAngle, fwd, right, up);
			NormalizeVector(fwd, ThrowVector); // just to ensure that fwd is normalized (a unit/directional vector)
			
			GetClientEyePosition(client, gStart); // initial position of grenade is offset by 16 units towards where the client is looking
			for (new i = 0; i < 3; i++)
				gStart[i] += ThrowVector[i] * 16.0;
			
			GetEntPropVector(client, Prop_Data, "m_vecAbsVelocity", PlayerVelocity); // get the client's current velocity
			
			switch (g_Game)
			{
				case Engine_CSS:
				{
					ThrowVelocity = (90.0 - ThrowAngle[0]) * 6.0; // calculation of grenade throwing velocity from weapon_basesdkgrenade.cpp
					if (ThrowVelocity > 750.0)
						ThrowVelocity = 750.0;
				}
				
				case Engine_CSGO:
				{
					ThrowVelocity = 750.0 * 0.9;
					ScaleVector(PlayerVelocity, 1.25);
				}
			}
			
			for (new i = 0; i < 3; i++)
				GrenadeVelocity[i] = ThrowVector[i] * ThrowVelocity + PlayerVelocity[i]; // grenade velocity vector calculation, did not account for map with moving surfaces
			
			new Float:dt = GetConVarFloat(sm_gtrajectory_timestep); 
			for (new Float:t = 0.0; t <= dtime; t += dt) // loop through small time step and do a tracehull, smaller timestep = more accurate trail but might lagg
			{
				gEnd[0] = gStart[0] + GrenadeVelocity[0] * dt; // this is just kinematics in physics: x = x0 + v0(x)*t
				gEnd[1] = gStart[1] + GrenadeVelocity[1] * dt; // y = y0 + v0(y)*t
				
				new Float:gForce = 0.4 * float(gravity.IntValue); // 0.4 factor obtained from sdk_basegrenade_projectile.h
				new Float:NewVelocity = GrenadeVelocity[2] - gForce * dt; // kinematics again, vf = v0 - g*t
				new Float:AvgVelocity = (GrenadeVelocity[2] + NewVelocity) / 2.0; // just calculation of average velocity, surely you know this
				
				gEnd[2] = gStart[2] + AvgVelocity * dt; // z = z0 + v(avg)*t
				GrenadeVelocity[2] = NewVelocity; // Since the z component of velocity changed due to gravity, update it!
				
				new Float:mins[3] = {-2.0, -2.0, -2.0}, Float:maxs[3] = {2.0, 2.0, 2.0}; // hull size from sdk_basegrenade_projectile.cpp
				new Handle:gRayTrace = TR_TraceHullEx(gStart, gEnd, mins, maxs, MASK_SHOT_HULL); // flags: see sdktools_trace.inc
				if (TR_GetFraction(gRayTrace) != 1.0) // check if there is any collision for this trace, != 0.0 check if ray immediately collide with client entity
				{
					if (TR_GetEntityIndex(gRayTrace) == client && t == 0.0)
					{
						CloseHandle(gRayTrace);
						gStart = gEnd;
						continue;
					}
					
					TR_GetEndPosition(gEnd, gRayTrace); //overwrite gEnd with the collision position
					
					/* The below calculation is just conservation of linear momentum in physics, can be found in physics_main_shared.cpp
					Assume perfectly elastic collision, velocity vector of the grenade along the surface normal would have its sign reversed
					
					To get component of grenade velocity vector along the surface normal, do a dot product
					The dot product should be a negative number since direction of velocity vector along the normal is opposite of the normal vector
					The sign of velocity along that component is reversed by adding twice the dot product (along the normal) to the original velocity vector */
					
					new Float:NVector[3];
					TR_GetPlaneNormal(gRayTrace, NVector);
					new Float:Impulse = 2.0 * GetVectorDotProduct(NVector, GrenadeVelocity);
					for (new i = 0; i < 3; i++)
					{
						GrenadeVelocity[i] -= Impulse * NVector[i];
						
						if (FloatAbs(GrenadeVelocity[i]) < 0.1)
							GrenadeVelocity[i] = 0.0;
					}
					
					// Of course collision is inelastic and we have to factor in the inelastic coefficient
					new Float:SurfaceElasticity = GetEntPropFloat(TR_GetEntityIndex(gRayTrace), Prop_Send, "m_flElasticity");
					new Float:elasticity = 0.45 * SurfaceElasticity;
					ScaleVector(GrenadeVelocity, elasticity); // scale the new velocity after collision accordingly
					
					// Also excluded the following codes present in sdk_basegrenade_projectile.cpp,
					/*if (GetVectorLength(GrenadeVelocity, true) < 30.0 * 30.0)
						ScaleVector(GrenadeVelocity, 0.0);*/
					
					new Float:ZVector[3] = { 0.0, 0.0, 1.0 };
					if(GetVectorDotProduct(NVector, ZVector) > 0.7)
					{
						if (StrEqual(cWeapon, "weapon_incgrenade", false) || StrEqual(cWeapon, "weapon_molotov", false)) // check if collision on ground
							dtime = 0.0; // prevent execution of next loop since incgrenade detonate on contact with ground
						//ScaleVector(GrenadeVelocity, (1.0 - TR_GetFraction(gRayTrace)) * 0.1);
					}
				}
				CloseHandle(gRayTrace); // close handle if not memory will be used up in seconds
				
				new startframe = 0, framerate = 0, fadelength= 0, speed = 0; // no animation, no fading, instant display
				new Float:life = 0.2, Float:width = GetConVarFloat(sm_gtrajectory_size), Float:amplitude = 0.0; // beamlife of 0.1 so beam won't stay as you move, amplitude = 0.0 no flickering
				TE_SetupBeamPoints(gStart, gEnd, trail, 0, startframe, framerate, life, width, width, fadelength, amplitude, trailcolor, speed); // Create a laserbeam between the tracehull start and end points
				TE_SendToClient(client, 0.0); // this beam is of course only sent to the client throwing the grenade
				
				gStart = gEnd; // obviously you have to set the next start point for trace hull as current end point
			}
		}
		return Plugin_Continue;
	}
	else
		return Plugin_Continue;
}

GetTrailColor(const String:weapon[])
{
	if (StrContains(weapon, "hegrenade", false) != -1)
		trailcolor = { 255, 0, 0, 255 };
	else if (StrContains(weapon, "smokegrenade", false) != -1)
		trailcolor = { 0, 255, 0, 255 };
	else if (StrContains(weapon, "flashbang", false) != -1)
		trailcolor = { 0, 255, 255, 255 };
	else if (StrContains(weapon, "incgrenade", false) != -1)
		trailcolor = { 255, 0, 255, 255 };
	else if (StrContains(weapon, "molotov", false) != -1)
		trailcolor = { 255, 255, 0, 255 };
	else if (StrContains(weapon, "decoy", false) != -1)
		trailcolor = { 255, 255, 255, 255 };
}

GetDetonationTime(const String:weapon[])
{
	if (StrContains("weapon_hegrenade weapon_flashbang", weapon,  false) != -1)
		dtime = 1.5 + GetConVarFloat(sm_gtrajectory_delay); //obtained from Source Sdk 2013 weapon_grenade.cpp
	else 
		dtime = 3.0 + GetConVarFloat(sm_gtrajectory_delay);
}
