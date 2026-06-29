#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <tf2_stocks>
#pragma semicolon 1

#define ARRAY_HOMING_SIZE 2
new Handle:g_hArrayHoming;
new Handle:g_hCvarHomingEnabled;
new Handle:g_hCvarHomingSpeed;
new Handle:g_hCvarHomingReflect;

enum
{
	ArrayHoming_EntityRef = 0,
	ArrayHoming_CurrentTarget
};

public OnPluginStart()
{
	g_hArrayHoming = CreateArray(ARRAY_HOMING_SIZE);
	g_hCvarHomingEnabled = CreateConVar("sm_homing_enabled", "1.0", "Enable homing Airblasted projectiles? 1/0.");
	g_hCvarHomingSpeed = CreateConVar("sm_homing_speed", "0.5", "Speed multiplier for homing rockets.");
	g_hCvarHomingReflect = CreateConVar("sm_homing_reflect", "0.1", "Speed multiplier increase for each reflection.");
	
	HookEvent("object_deflected", Event_Airblast);
}

public Event_Airblast(Handle:event, const String:name[], bool:dontBroadcast)
{
	new object = GetEventInt(event, "object_entindex");
	
	if (GetEventInt(event, "weaponid") != 0 && GetConVarFloat(g_hCvarHomingEnabled) > 0.0)
	{
		decl String:class[128];
		GetEntityClassname(object, class, sizeof(class));
		
		if(strcmp(class, "tf_projectile_rocket") == 0 || strcmp(class, "tf_projectile_arrow") == 0 ||
			strcmp(class, "tf_projectile_flare") == 0 || strcmp(class, "tf_projectile_energy_ball") == 0 ||
			strcmp(class, "tf_projectile_healing_bolt") == 0)
		{
			CreateTimer(0.2, Timer_CheckOwnership, EntIndexToEntRef(object));
		}
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

HomingProjectile_TurnToTarget(client, iProjectile)
{
	new Float:flTargetPos[3];
	GetClientAbsOrigin(client, flTargetPos);
	new Float:flRocketPos[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flRocketPos);

	new Float:flInitialVelocity[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", flInitialVelocity);
	new Float:flSpeedInit = GetVectorLength(flInitialVelocity);
	new Float:flSpeedBase = flSpeedInit * GetConVarFloat(g_hCvarHomingSpeed);
	
	//flTargetPos[2] += 50.0;
	flTargetPos[2] += 30 + Pow(GetVectorDistance(flTargetPos, flRocketPos), 2.0) / 10000;
	
	new Float:flNewVec[3];
	SubtractVectors(flTargetPos, flRocketPos, flNewVec);
	NormalizeVector(flNewVec, flNewVec);
	
	new Float:flAng[3];
	GetVectorAngles(flNewVec, flAng);

	new Float:flSpeedNew = flSpeedBase + GetEntProp(iProjectile, Prop_Send, "m_iDeflected") * flSpeedBase * GetConVarFloat(g_hCvarHomingReflect);
	
	ScaleVector(flNewVec, flSpeedNew);
	TeleportEntity(iProjectile, NULL_VECTOR, flAng, flNewVec);
}

stock bool:IsValidClient(client)
{
	if(client <= 0 ) return false;
	if(client > MaxClients) return false;
	if(!IsClientConnected(client)) return false;
	return IsClientInGame(client);
}
