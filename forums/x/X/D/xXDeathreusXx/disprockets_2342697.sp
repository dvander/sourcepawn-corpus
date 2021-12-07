#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>
#include <sdkhooks>

new Float:gf_RocketDamage		= 69.0;			//Rocket damage
new Float:gf_RocketDistance		= 2250000.0;	//See range of dispenser
new Float:gf_RocketSpeed		= 250.0;		//Speed of rocket

new MapStarted = false;							//Prevents a silly error from occuring with the AttachParticle stock

new Handle:hDisp = INVALID_HANDLE;
new Handle:g_hArrayHoming;
new Handle:g_hCvarHomingSpeed;
new Handle:g_hCvarHomingReflect;

#define ARRAY_HOMING_SIZE 2

#define SND_SHOOT	 "mvm/giant_soldier/giant_soldier_rocket_shoot_crit.wav"

enum
{
	ArrayHoming_EntityRef = 0,
	ArrayHoming_CurrentTarget
};

public Plugin:myinfo = 
{
	name = "[TF2] Dispenser rockets V2",
	author = "Pelipoika, Deathreus",
	description = "Makes dispensers shoot homing rockets",
	version = "6.0",
	url = ""
}

public OnPluginStart()
{
	hDisp = CreateTimer(2.5, timer_hDisp, _, TIMER_REPEAT);				   //This controlls how often the dispenser fires a rocket
	g_hArrayHoming = CreateArray(ARRAY_HOMING_SIZE);
	g_hCvarHomingSpeed = CreateConVar("sm_homing_speed", "0.5", "Speed multiplier for homing dsp rockets.");
	g_hCvarHomingReflect = CreateConVar("sm_homing_reflect", "0.1", "Speed multiplier increase for each reflection.");
}

public OnPluginEnd()
{
	if (hDisp != INVALID_HANDLE)
	{
		KillTimer(hDisp);
		hDisp = INVALID_HANDLE;
	}
}

public OnMapStart()
{
	PrecacheSound(SND_SHOOT);
	
	MapStarted = true;
}

public OnMapEnd()
{
	MapStarted = false;
}

public Action:timer_hDisp(Handle:timer)
{
	Handle_DispenserRockets();
}

Handle_DispenserRockets()
{
	new index = -1;
	while ((index = FindEntityByClassname(index, "obj_dispenser")) != -1) //Loop through all the dispensers
	{	 
		decl Float:playerpos[3], Float:targetvector[3], Float:dPos[3];
		new Float:dAng[3] = {0.0, 0.0, 90.0};
		new client = GetEntPropEnt(index, Prop_Send, "m_hBuilder");
		new iAmmo = GetEntProp(index, Prop_Send, "m_iAmmoMetal");
		new newiAmmo = iAmmo -= 40;
		
		if(IsValidClient(client))
		{
			if(!CheckCommandAccess(client, "sm_disprockets", ADMFLAG_GENERIC))
				return;
			
			new bossteam = GetClientTeam(client);
			
			decl playerarray[MAXPLAYERS+1];
			new playercount;
				
			new bool:disBuilding = GetEntProp(index, Prop_Send, "m_bBuilding") == 1;
			new bool:disPlacing = GetEntProp(index, Prop_Send, "m_bPlacing") == 1;
			new bool:disCarried = GetEntProp(index, Prop_Send, "m_bCarried") == 1;
			
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", dPos);
			//GetEntPropVector(index, Prop_Send, "m_angRotation", dAng);

			if(!disBuilding && !disPlacing && !disCarried)
			{
				new disLevel = GetEntProp(index, Prop_Send, "m_iHighestUpgradeLevel");
				if(disLevel > 2)		 //This controls the level the dispenser has to be to be able to shoot rockets
				{
					dPos[2] += 64.0;	//set the rocket's spawn position to the dispensers top

					TR_TraceRayFilter(dPos, dAng, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf, client);
					TR_GetEndPosition(targetvector);

					for(new player = 1; player <= MaxClients; player++)
					{
						if(player != client && IsClientInGame(player) && IsPlayerAlive(player))
						{
							if(HomingProjectile_IsValidTarget(player, index, GetEntProp(index, Prop_Send, "m_iTeamNum")))
							{
								GetClientEyePosition(player, playerpos);
								playerpos[2] -= 30.0;
								if(GetVectorDistance(dPos, playerpos, true) < gf_RocketDistance	 && CanSeeTarget(dPos, playerpos, player, bossteam))
								{
									playerarray[playercount] = player;	  
									playercount++;
								}
							}
						}
					}
						
					if(playercount)	   //As long as theres atleast 1 valid target fire a rocket
					{
						if(iAmmo >= 40)
						{
							AttachParticle(index, "ExplosionCore_sapperdestroyed", _, 64.0, 8.0);
							EmitSoundToAll(SND_SHOOT, index);
							SetEntProp(index, Prop_Send, "m_iAmmoMetal", newiAmmo);		   //It costs 40 metal to shoot a rocket
							CreateProjectile(client, dPos);								   //Fire a rocket
						}
					}
				}
			}
		}
	}
}

CreateProjectile(client, Float:origin[3])	 
{
	new entity = CreateEntityByName("tf_projectile_rocket");
	if(entity != -1)
	{
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity", client);
		
		new Float:vAngles[3];
		vAngles[0] = -90.0;
		vAngles[1] = 0.0;
		vAngles[2] = 0.0;
		
		decl Float:vVelocity[3];
		decl Float:vBuffer[3];
		
		GetAngleVectors(vAngles, vBuffer, NULL_VECTOR, NULL_VECTOR);
		
		vVelocity[0] = vBuffer[0]*gf_RocketSpeed;
		vVelocity[1] = vBuffer[1]*gf_RocketSpeed;
		vVelocity[2] = vBuffer[2]*gf_RocketSpeed;
		
		TeleportEntity(entity, origin, vAngles, vVelocity);
		DispatchSpawn(entity);
		
		SDKHook(entity, SDKHook_StartTouch, ProjectileTouchHook);
		CreateTimer(0.35, Timer_CheckOwnership, EntIndexToEntRef(entity));
	}
}

public Action:Timer_CheckOwnership(Handle:hTimer, any:iRef)
{
	new iProjectile = EntRefToEntIndex(iRef);
	if(iProjectile > MaxClients && IsValidEntity(iProjectile))
	{
		new iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
		if(iLauncher >= 1 && iLauncher <= MaxClients && IsClientInGame(iLauncher) && IsPlayerAlive(iLauncher))
		{
			// Check to make sure the projectile isn't already being homed
			if(GetEntProp(iProjectile, Prop_Send, "m_nForceBone") != 0) return Plugin_Handled;	  
			SetEntProp(iProjectile, Prop_Send, "m_nForceBone", 1);
			
			new iData[ARRAY_HOMING_SIZE];
			iData[ArrayHoming_EntityRef] = EntIndexToEntRef(iProjectile);
			PushArrayArray(g_hArrayHoming, iData);
		}
	}
	
	return Plugin_Handled;
}

public OnGameFrame()
{
	// Using this method instead of SDKHooks because the Think functions are not called consistently for all projectiles
	for(new i=GetArraySize(g_hArrayHoming)-1; i>=0; i--)
	{
		new iData[ARRAY_HOMING_SIZE];
		GetArrayArray(g_hArrayHoming, i, iData);
		
		if(iData[ArrayHoming_EntityRef] == 0)
		{
			RemoveFromArray(g_hArrayHoming, i);
			continue;
		}
		
		new iProjectile = EntRefToEntIndex(iData[ArrayHoming_EntityRef]);
		if(iProjectile > MaxClients)
			HomingProjectile_Think(iProjectile, iData[ArrayHoming_EntityRef], i, iData[ArrayHoming_CurrentTarget]);
		else
			RemoveFromArray(g_hArrayHoming, i);
	}
}

public HomingProjectile_Think(iProjectile, iRefProjectile, iArrayIndex, iCurrentTarget)
{
	new iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	
	if(!HomingProjectile_IsValidTarget(iCurrentTarget, iProjectile, iTeam))
		HomingProjectile_FindTarget(iProjectile, iRefProjectile, iArrayIndex);
	else
		HomingProjectile_TurnToTarget(iCurrentTarget, iProjectile);
}

bool:HomingProjectile_IsValidTarget(client, iProjectile, iTeam)
{
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != iTeam)
	{
		if(TF2_IsPlayerInCondition(client, TFCond_Cloaked)) return false;
		
		if(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
			return false;
		
		new Float:flStart[3];
		GetClientEyePosition(client, flStart);
		new Float:flEnd[3];
		GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flEnd);
		
		new Handle:hTrace = TR_TraceRayFilterEx(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceFilterHoming, iProjectile);
		if(hTrace != INVALID_HANDLE)
		{
			if(TR_DidHit(hTrace))
			{
				CloseHandle(hTrace);
				return false;
			}
			
			CloseHandle(hTrace);
			return true;
		}
	}
	
	return false;
}

public bool:TraceFilterHoming(entity, contentsMask, any:iProjectile)
{
	if(entity == iProjectile || (entity >= 1 && entity <= MaxClients))
		return false;
	
	return true;
}

HomingProjectile_FindTarget(iProjectile, iRefProjectile, iArrayIndex)
{
	new iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	new Float:flPos1[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flPos1);
	
	new iBestTarget;
	new Float:flBestLength = 99999.9;
	for(new i=1; i<=MaxClients; i++)
	{
		if(HomingProjectile_IsValidTarget(i, iProjectile, iTeam))
		{
			new Float:flPos2[3];
			GetClientEyePosition(i, flPos2);
			
			new Float:flDistance = GetVectorDistance(flPos1, flPos2);
			
			//if(flDistance < 70.0) continue;
			
			if(flDistance < flBestLength)
			{
				iBestTarget = i;
				flBestLength = flDistance;
			}
		}
	}
	
	if(iBestTarget >= 1 && iBestTarget <= MaxClients)
	{
		new iData[ARRAY_HOMING_SIZE];
		iData[ArrayHoming_EntityRef] = iRefProjectile;
		iData[ArrayHoming_CurrentTarget] = iBestTarget;
		SetArrayArray(g_hArrayHoming, iArrayIndex, iData);
		
		HomingProjectile_TurnToTarget(iBestTarget, iProjectile);
	}
	else
	{
		new iData[ARRAY_HOMING_SIZE];
		iData[ArrayHoming_EntityRef] = iRefProjectile;
		iData[ArrayHoming_CurrentTarget] = 0;
		SetArrayArray(g_hArrayHoming, iArrayIndex, iData);
	}
}
/*
HomingProjectile_TurnToTarget(client, iProjectile)
{
	new Float:flTargetPos[3];
	GetClientAbsOrigin(client, flTargetPos);
	new Float:flRocketPos[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flRocketPos);
	new Float:flInitialVelocity[3];
//	  GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", flInitialVelocity);
	GetEntPropVector(iProjectile, Prop_Send, "m_vecAbsVelocity", flInitialVelocity);
	
	new Float:flSpeedInit = GetVectorLength(flInitialVelocity);
	new Float:flSpeedBase = flSpeedInit * GetConVarFloat(g_hCvarHomingSpeed);
	
	flTargetPos[2] += 30 + Pow(GetVectorDistance(flTargetPos, flRocketPos), 2.0) / 10000;
	
	new Float:flNewVec[3];
	SubtractVectors(flTargetPos, flRocketPos, flNewVec);
	NormalizeVector(flNewVec, flNewVec);
	
	new Float:flAng[3];
	GetVectorAngles(flNewVec, flAng);

	new Float:flSpeedNew = flSpeedBase + GetEntProp(iProjectile, Prop_Send, "m_iDeflected") * flSpeedBase * GetConVarFloat(g_hCvarHomingReflect);
	
	ScaleVector(flNewVec, flSpeedNew);
	TeleportEntity(iProjectile, NULL_VECTOR, flAng, flNewVec);
}*/

HomingProjectile_TurnToTarget(client, iProjectile)						  // update projectile position
{
	new Float:flTargetPos[3];
	GetClientAbsOrigin(client, flTargetPos);
	new Float:flRocketPos[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flRocketPos);
	new Float:flRocketVel[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_vecAbsVelocity", flRocketVel);
		
	flTargetPos[2] += 30 + Pow(GetVectorDistance(flTargetPos, flRocketPos), 2.0) / 10000;
		
	new Float:flNewVec[3];
	SubtractVectors(flTargetPos, flRocketPos, flNewVec);
	NormalizeVector(flNewVec, flNewVec);
		
	new Float:flAng[3];
	GetVectorAngles(flNewVec, flAng);

	ScaleVector(flNewVec, gf_RocketSpeed);
	TeleportEntity(iProjectile, NULL_VECTOR, flAng, flNewVec);
}

public Action:ProjectileTouchHook(entity, other)								// Wat happens when this projectile touches something
{
	if(other > 0 && other <= MaxClients)
	{
		new client = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if(client > 0 && client <= MaxClients && IsClientInGame(client))		// will probably just be -1, but whatever.
		{
			SDKHooks_TakeDamage(other, client, client, gf_RocketDamage, DMG_SHOCK|DMG_ALWAYSGIB);
		}
	}
}

stock AttachParticle(iEntity, const String:strParticleEffect[], const String:strAttachPoint[]="", Float:flZOffset=0.0, Float:flSelfDestruct=0.0) 
{ 
	if (MapStarted)
	{
		new iParticle = CreateEntityByName("info_particle_system"); 
		if( !IsValidEdict(iParticle) ) 
			return 0; 
		 
		new Float:flPos[3]; 
		GetEntPropVector(iEntity, Prop_Send, "m_vecOrigin", flPos); 
		flPos[2] += flZOffset; 
		 
		TeleportEntity(iParticle, flPos, NULL_VECTOR, NULL_VECTOR); 
		 
		DispatchKeyValue(iParticle, "effect_name", strParticleEffect); 
		DispatchSpawn(iParticle); 
		 
		SetVariantString("!activator"); 
		AcceptEntityInput(iParticle, "SetParent", iEntity); 
		ActivateEntity(iParticle); 
		 
		if(strlen(strAttachPoint)) 
		{ 
			SetVariantString(strAttachPoint); 
			AcceptEntityInput(iParticle, "SetParentAttachmentMaintainOffset"); 
		} 
		 
		AcceptEntityInput(iParticle, "start"); 
		 
		if( flSelfDestruct > 0.0 ) 
			CreateTimer( flSelfDestruct, Timer_DeleteParticle, EntIndexToEntRef(iParticle) ); 
		 
		return iParticle; 
	}
	return 0;
}

public Action:Timer_DeleteParticle(Handle:hTimer, any:iRefEnt) 
{ 
	new iEntity = EntRefToEntIndex(iRefEnt); 
	if(iEntity > MaxClients) 
		AcceptEntityInput(iEntity, "Kill"); 
	 
	return Plugin_Handled; 
}

public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	return entity != data;
}

public bool:TraceRayFilterClients(entity, mask, any:data)
{
	if(entity > 0 && entity <=MaxClients)					 // only hit the client we're aiming at
	{
		if(entity == data)
			return true;
		else
			return false;
	}
	return true;
}

bool:CanSeeTarget(Float:startpos[3], Float:targetpos[3], target, bossteam)		  // Tests to see if vec1 > vec2 can "see" target
{
	TR_TraceRayFilter(startpos, targetpos, MASK_SOLID, RayType_EndPoint, TraceRayFilterClients, target);

	if(TR_GetEntityIndex() == target)
	{
		if(TF2_GetPlayerClass(target) == TFClass_Spy)							 // if they are a spy, do extra tests (coolrocket stuff?)
		{
			if(TF2_IsPlayerInCondition(target, TFCond_Cloaked))					   // if they are cloaked
			{
				if(TF2_IsPlayerInCondition(target, TFCond_CloakFlicker)			   // check if they are partially visible
					|| TF2_IsPlayerInCondition(target, TFCond_OnFire)
					|| TF2_IsPlayerInCondition(target, TFCond_Jarated)
					|| TF2_IsPlayerInCondition(target, TFCond_Milked)
					|| TF2_IsPlayerInCondition(target, TFCond_Bleeding))
				{
					return true;
				}
				return false;
			}
			return true;
		}
		if(GetClientTeam(target) == bossteam)
		{
			return false;
		}
		return true;
	}
	return false;
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}