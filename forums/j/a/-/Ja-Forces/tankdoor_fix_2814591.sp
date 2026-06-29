#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <entity_prop_stocks>

#define PLUGIN_VERSION "1.4.8"

#define DOOR_CLASS_01 "prop_door_rotating"
#define DOOR_CLASS_02 "prop_door_rotating_checkpoint"

#define DOOR_MODEL_01 "models/props_doors/doorfreezer01.mdl"
#define DOOR_MODEL_02 "models/props_doors/checkpoint_door_01.mdl"
#define DOOR_MODEL_03 "models/props_doors/checkpoint_door_-01.mdl"
#define DOOR_MODEL_04 "models/lighthouse/checkpoint_door_lighthouse01.mdl"

static int g_iTankCount;
static int g_iTankClassIndex;
float g_fNextTankPunchAllowed[MAXPLAYERS + 1];

ConVar g_hPluginEnabled;

public Plugin myinfo = 
{
	name = "TankDoorFix",
	author = "PP(R)TH: Dr. Gregory House, Glide Loading, Dosergen",
	description = "Fixes Tank not destroying doors properly",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=225087"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead:
			g_iTankClassIndex = 5;
		case Engine_Left4Dead2:
			g_iTankClassIndex = 8;
		default:
		{
			strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
			return APLRes_SilentFailure;
		}
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("tankdoorfix_version", PLUGIN_VERSION, "TankDoorFix Version", FCVAR_NOTIFY | FCVAR_DONTRECORD);

	g_hPluginEnabled = CreateConVar("tankdoorfix_enabled", "1", "Enable or disable the plugin", FCVAR_NOTIFY);
	
	HookEvent("round_start", evt_RoundStart, EventHookMode_Post);
	HookEvent("tank_spawn", evt_SpawnTank, EventHookMode_Post);
	HookEvent("tank_killed", evt_KilledTank, EventHookMode_Post);
	
	AutoExecConfig(true, "tankdoor_fix");
}

void evt_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hPluginEnabled.BoolValue)
		return;
	g_iTankCount = 0;
}

void evt_SpawnTank(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hPluginEnabled.BoolValue)
		return;
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (!IsValidClient(client))
		return;
	g_iTankCount++;
	g_fNextTankPunchAllowed[client] = GetGameTime() + 0.8;
}

void evt_KilledTank(Event event, const char[] name, bool dontBroadcast)
{
	if (!g_hPluginEnabled.BoolValue)
		return;
	g_iTankCount--;
}

public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (!g_hPluginEnabled.BoolValue || g_iTankCount <= 0 || !(buttons & IN_ATTACK) || !IsValidTank(client) || IsPlayerGhost(client))
		return Plugin_Continue;
	int tankweapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
	if (tankweapon > 0)
	{
		float gameTime = GetGameTime();
		if (GetEntPropFloat(tankweapon, Prop_Send, "m_flTimeWeaponIdle") <= gameTime && g_fNextTankPunchAllowed[client] <= gameTime)
		{
			g_fNextTankPunchAllowed[client] = gameTime + 2.0;
			CreateTimer(1.0, Timer_DoorCheck, GetClientUserId(client));
		}
	}
	return Plugin_Continue;
}

Action Timer_DoorCheck(Handle timer, int clientUserID)
{
	int client = GetClientOfUserId(clientUserID);
	if (IsValidTank(client) && !IsPlayerGhost(client))
		IsLookingAtBreakableDoor(client);
	return Plugin_Stop;
}

void IsLookingAtBreakableDoor(int client)
{
	int g_iDoorEntity;
	float origin[3], angles[3], endorigin[3], Push[3], power;
	GetClientAbsOrigin(client, origin);
	GetClientAbsAngles(client, angles);
	origin[2] += 20.0;
	TR_TraceRayFilter(origin, angles, MASK_SHOT, RayType_Infinite, TraceFilterClients, client);
	if (!TR_DidHit())
		return;
	g_iDoorEntity = TR_GetEntityIndex();
	TR_GetEndPosition(endorigin);
	if (g_iDoorEntity > 0 && GetVectorDistance(origin, endorigin) <= 90.0)
	{
		char sClassName[64], sModelName[64];
		GetEntityClassname(g_iDoorEntity, sClassName, sizeof(sClassName));
		GetEntPropString(g_iDoorEntity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
		if (IsValidDoor(sClassName, sModelName))
		{
			GetEntPropVector(g_iDoorEntity, Prop_Send, "m_vecOrigin", endorigin);
			float vPos[3], vAng[3];
			GetEntPropVector(g_iDoorEntity, Prop_Send, "m_vecOrigin", vPos);
			GetEntPropVector(g_iDoorEntity, Prop_Send, "m_angRotation", vAng);
			SetEntProp(g_iDoorEntity, Prop_Send, "m_CollisionGroup", 1);
			vPos[2] += 10000.0;
			TeleportEntity(g_iDoorEntity, vPos, NULL_VECTOR, NULL_VECTOR);
			vPos[2] -= 10000.0;
			SetEntityRenderMode(g_iDoorEntity, RENDER_TRANSALPHA);
			SetEntityRenderColor(g_iDoorEntity, 0, 0, 0, 0);
			int g_iBrokenEntity = CreateEntityByName("prop_physics");
			if (g_iBrokenEntity > 0)
			{
				DispatchKeyValue(g_iBrokenEntity, "model", sModelName);
				DispatchKeyValue(g_iBrokenEntity, "spawnflags", "4");
				DispatchSpawn(g_iBrokenEntity);
				GetAngleVectors(angles, Push, NULL_VECTOR, NULL_VECTOR);
				power = GetRandomFloat(600.0, 800.0);
				Push[0] *= power;
				Push[1] *= power;
				Push[2] *= power;
				TeleportEntity(g_iBrokenEntity, vPos, vAng, Push);
				SetEntProp(g_iBrokenEntity, Prop_Send, "m_CollisionGroup", 1);
				CreateTimer(5.0, Timer_StartFadeEffect, g_iBrokenEntity);
			}
		}
	}
}

Action Timer_StartFadeEffect(Handle timer, int g_iBrokenEntity)
{
	if (IsValidEntity(g_iBrokenEntity))
	{
		char remove[64];
		FormatEx(remove, sizeof(remove), "OnUser1 !self:kill::%f:1", 5.0);
		SetVariantString(remove);
		SetEntityRenderFx(g_iBrokenEntity, RENDERFX_FADE_FAST);
		AcceptEntityInput(g_iBrokenEntity, "AddOutput");
		AcceptEntityInput(g_iBrokenEntity, "FireUser1");
	}
	return Plugin_Stop;
}

bool IsValidDoor(const char className[64], const char modelName[64])
{
	return (strcmp(className, DOOR_CLASS_01) == 0 && strcmp(modelName, DOOR_MODEL_01) == 0) 
			|| (strcmp(className, DOOR_CLASS_02) == 0 && (strcmp(modelName, DOOR_MODEL_02) == 0 
				|| strcmp(modelName, DOOR_MODEL_03) == 0 || strcmp(modelName, DOOR_MODEL_04) == 0));
}

bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client);
}

bool IsValidTank(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == g_iTankClassIndex;
}

bool IsPlayerGhost(int client)
{
	return GetEntProp(client, Prop_Send, "m_isGhost") != 0;
}

bool TraceFilterClients(int entity, int mask, any data)
{
	return entity != data && entity > MaxClients;
}