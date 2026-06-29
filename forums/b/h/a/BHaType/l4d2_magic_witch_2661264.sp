#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define MAXENTITIES 32

ConVar cInterval, cDamage, cRange, cDistance, cSpeed, cEnable, cChance;	
float g_iInterval, g_iDamage, g_iRange, g_iDistance, g_iSpeed;

static const char szNames[][] =
{
	"spitter_projectile",
	"molotov_projectile",
	"vomitjar_projectile"
};

//g_iEntities[2048 + 1][MAXENTITIES] = {INVALID_ENT_REFERENCE, ...};
int g_iVelocity, g_iEntities[2048 + 1][MAXENTITIES];

public Plugin myinfo =
{
	name = "[L4D2] Magic Witch",
	author = "BHaType",
	description = "Makes witch more dangerous",
	version = "0.0.5",
	url = "N/A"
}

public void OnPluginStart()
{
	cInterval 	= CreateConVar("magic_witch_interval"	, "0.5"		, "Interval"							, FCVAR_NONE);
	cDamage 	= CreateConVar("magic_witch_damage"		, "5.0"		, "Number of damage"					, FCVAR_NONE);
	cRange 		= CreateConVar("magic_witch_range"		, "60.0"	, "Range of hit"						, FCVAR_NONE);
	cDistance 	= CreateConVar("magic_witch_distance"	, "950.0"	, "Distance of detect"					, FCVAR_NONE);
	cSpeed 		= CreateConVar("magic_witch_speed"		, "5.5"		, "Speed of magic items"				, FCVAR_NONE);
	cEnable 	= CreateConVar("magic_witch_enable"		, "1"		, "1 - Enable plugin \n 0 - Disable"	, FCVAR_NONE);
	cChance 	= CreateConVar("magic_witch_chance"		, "70"		, "Chance of magic witch"				, FCVAR_NONE);
	
	g_iInterval = cInterval.FloatValue;
	g_iDamage	= cDamage.FloatValue;
	g_iRange 	= cRange.FloatValue;
	g_iDistance = cDistance.FloatValue;
	g_iSpeed 	= cSpeed.FloatValue;
	
	cInterval.AddChangeHook(IntsCvar);
	cDamage.AddChangeHook(IntsCvar);
	cRange.AddChangeHook(IntsCvar);
	cDistance.AddChangeHook(IntsCvar);
	cSpeed.AddChangeHook(IntsCvar);
	
	HookEvent("witch_spawn", eWitch);
	
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	AutoExecConfig(true, "magic_witch");
}

public void IntsCvar(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_iInterval = cInterval.FloatValue;
	g_iDamage	= cDamage.FloatValue;
	g_iRange 	= cRange.FloatValue;
	g_iDistance = cDistance.FloatValue;
	g_iSpeed 	= cSpeed.FloatValue;
}

public void eWitch (Event event, const char[] name, bool dontbroadcast)
{
	if(GetRandomInt(1, 100) >= cChance.IntValue || !cEnable.IntValue)
		return;

	int index = event.GetInt("witchid");
	CreateTimer(g_iInterval, Ability, EntIndexToEntRef(index), TIMER_REPEAT);
}

public Action Ability (Handle timer, int index)
{
	index = EntRefToEntIndex(index);
	if(index != INVALID_ENT_REFERENCE && GetEntProp(index, Prop_Data, "m_iHealth") > 10)
	{
		bool bSaved;
		int weapon = CreateEntityByName(szNames[GetRandomInt(0, sizeof szNames - 1)]);
		if(IsValidEntity(weapon))
		{
			float vPos[3];
			GetEntPropVector(index, Prop_Send, "m_vecOrigin", vPos);
			vPos[2] += GetRandomInt(30, 100);
			vPos[0] += GetRandomInt(-50, 50);
			vPos[1] += GetRandomInt(-50, 50);
			DispatchSpawn(weapon);
			
			SetEntProp(weapon, Prop_Data, "m_iHammerID", index);
			SetEntProp(weapon, Prop_Send, "m_nSolidType", 0);
			
			for(int i; i < MAXENTITIES; i++)
			{
				if(EntRefToEntIndex(g_iEntities[index][i]) == INVALID_ENT_REFERENCE || EntRefToEntIndex(g_iEntities[index][i]) == 0)
				{
					g_iEntities[index][i] = EntIndexToEntRef(weapon);
					SetEntProp(weapon, Prop_Data, "m_nSkin", i);
					bSaved = true;
					break;
				}
			}
			
			if(!bSaved)
				AcceptEntityInput(weapon, "kill");
			else
			{
				CreateTimer(0.1, PreThink, EntIndexToEntRef(weapon), TIMER_REPEAT);
				TeleportEntity(weapon, vPos, NULL_VECTOR, NULL_VECTOR);
			}
		}
	}
	else
		return Plugin_Stop;
	return Plugin_Continue;
}

public Action PreThink (Handle timer, int index)
{
	index = EntRefToEntIndex(index);
	if(index != INVALID_ENT_REFERENCE && IsValidEntity(index))
	{
		int witch = GetEntProp(index, Prop_Data, "m_iHammerID");
		if(witch > MaxClients && witch < 2049 && IsValidEntity(witch) && GetEntProp(witch, Prop_Data, "m_iHealth") > 10)
			Tracering(index, witch);
		else
		{
			int entity;
			for(int i; i < MAXENTITIES; i++)
			{
				if((entity = EntRefToEntIndex(g_iEntities[witch][i])) != INVALID_ENT_REFERENCE && IsValidEntity(entity) && entity > MaxClients)
				{
					if(IsValidEntity(entity)) AcceptEntityInput(entity, "kill");
					g_iEntities[witch][i] = INVALID_ENT_REFERENCE;
				}
			}
			return Plugin_Stop;
		}
	}
	else
		return Plugin_Stop;
	return Plugin_Continue;
}

void Tracering(int iEnt, int index)
{
   	float vPos[3], vVel[3], flDistance;
	
	GetEntPropVector(iEnt, Prop_Send, "m_vecOrigin", vPos);	
	GetEntDataVector(iEnt, g_iVelocity, vVel);
	
	float vLenght = GetVectorLength(vVel);

	NormalizeVector(vVel, vVel);
	
	int client = lucker(iEnt);
	if(client == -1)
		client = index;
 
	if(client > 0 && IsValidEntity(client))	
	{
		float vEnemy[3], vVelEnemy[3], vDir[3], doubleVel[3];
		
		if(client != index)
			GetClientEyePosition(client, vEnemy);
		else 
		{
			GetEntPropVector(client, Prop_Send, "m_vecOrigin", vEnemy);
			vEnemy[2] += 30.0;
		}
		GetEntDataVector(client, g_iVelocity, vVelEnemy);
		
		flDistance = GetVectorDistance(vPos, vEnemy);
		if(flDistance <= g_iRange && client != index)
		{
			SDKHooks_TakeDamage(client, iEnt, iEnt, g_iDamage, 8);
			AcceptEntityInput(iEnt, "kill");
			
			int witch = GetEntProp(iEnt, Prop_Data, "m_iHammerID");
			int flags = GetEntProp(iEnt, Prop_Data, "m_nSkin");
			g_iEntities[witch][flags] = INVALID_ENT_REFERENCE;
		}
		
		SetEntityGravity(iEnt, 0.01);
		
		SubtractVectors(vEnemy, vPos, vDir);
		NormalizeVector(vDir, vDir);
		ScaleVector(vDir, 0.5);
		AddVectors(vVel, vDir, doubleVel);
		NormalizeVector(doubleVel, doubleVel);
		ScaleVector(doubleVel, vLenght + g_iSpeed);
		TeleportEntity(iEnt, NULL_VECTOR, NULL_VECTOR, doubleVel);
		
	}
	else
		SetEntProp(iEnt, Prop_Data, "m_iHammerID", 0);
}

int lucker(int index)
{
	float vPos[3], vPosEntity[3], vDistance = 100000.0, flDistance;
	int count = -1;
	GetEntPropVector(index, Prop_Send, "m_vecOrigin", vPos);
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) == 2 && IsPlayerAlive(i) && IsVisibleTo(i, index))
		{
			GetEntPropVector(i, Prop_Send, "m_vecOrigin", vPosEntity);
			flDistance = GetVectorDistance(vPosEntity, vPos);
			if(flDistance < vDistance && flDistance <= g_iDistance)
			{
				vDistance = flDistance;
				count = i;
			}
		}
	}
	
	return count;
}

static bool IsVisibleTo(int client, int entity)
{
	float vAngles[3], vOrigin[3], vEnt[3], vLookAt[3];
	
	GetClientEyePosition(client, vOrigin);
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", vEnt);
	vEnt[2] += 64.0;
	
	MakeVectorFromPoints(vOrigin, vEnt, vLookAt);
	
	GetVectorAngles(vLookAt, vAngles);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TraceFilter, entity);
	
	bool isVisible = false;
	if (TR_DidHit(trace))
	{
		float vStart[3];
		TR_GetEndPosition(vStart, trace);
		
		if ((GetVectorDistance(vOrigin, vStart, false) + 25.0) >= GetVectorDistance(vOrigin, vEnt))
		{
			isVisible = true;
		}
	}
	delete trace;
	return isVisible;
}

public bool TraceFilter(int entity, int mask, any data)
{
	if(entity == data) 
		return false;
	return true;
}