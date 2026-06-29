#pragma semicolon 1
#pragma newdecls required
 
#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <entity_prop_stocks>
 
#define VERSION "1.4.6"
#define CVAR_FLAGS FCVAR_NOTIFY
#define DOOR_CLASS_01 "prop_door_rotating"
#define DOOR_CLASS_02 "prop_door_rotating_checkpoint"
#define DOOR_MODEL_01 "models/props_doors/doorfreezer01.mdl"
#define DOOR_MODEL_02 "models/props_doors/checkpoint_door_01.mdl"
#define DOOR_MODEL_03 "models/lighthouse/checkpoint_door_lighthouse01.mdl"

static int g_iTankCount = 0, g_iTankClassIndex = 0;
float g_fNextTankPunchAllowed[MAXPLAYERS + 1] = {0.0, ...};
ConVar hPluginOn;
static bool bHooked = false;
 
public Plugin myinfo = 
{
	name = "TankDoorFix",
	author = "PP(R)TH: Dr. Gregory House, Glide Loading, Uncle Jessie, Dosergen",
	description = "This should at some point fix the case in which the tank misses the door he's supposed to destroy by using his punch",
	version = VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=225087"
}
 
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	switch (GetEngineVersion())
	{
		case Engine_Left4Dead: g_iTankClassIndex = 5;
		case Engine_Left4Dead2: g_iTankClassIndex = 8;
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
	CreateConVar("tankdoorfix_version", VERSION, "TankDoorFix Version", CVAR_FLAGS|FCVAR_DONTRECORD);
	hPluginOn = CreateConVar("tankdoorfix_plugin_on", "1", "Plugin On/Off.", CVAR_FLAGS);
	hPluginOn.AddChangeHook(OnConVarChanged_Allow);
	AutoExecConfig(true, "tankdoorfix");
}

public void OnConfigsExecuted()
{
	IsAllowed();
}

void OnConVarChanged_Allow(ConVar cvar, const char[] sOldValue, const char[] sNewValue)
{
	IsAllowed();
}

void IsAllowed()
{
	bool bPluginOn = hPluginOn.BoolValue;
	if(bPluginOn && !bHooked)
	{
		bHooked = true;
		HookEvent("round_start", evt_RoundStart, EventHookMode_Post);
		HookEvent("tank_spawn", evt_SpawnTank, EventHookMode_Post);
		HookEvent("tank_killed", evt_KilledTank, EventHookMode_Post);
	}
	else if(!bPluginOn && bHooked)
	{
		bHooked = false;
		UnhookEvent("round_start", evt_RoundStart, EventHookMode_Post);
		UnhookEvent("tank_spawn", evt_SpawnTank, EventHookMode_Post);
		UnhookEvent("tank_killed", evt_KilledTank, EventHookMode_Post);
	}
}
 
void evt_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iTankCount = 0;
}
 
void evt_SpawnTank(Event event, const char[] name, bool dontBroadcast)
{
	g_iTankCount++;
	g_fNextTankPunchAllowed[GetClientOfUserId(event.GetInt("userid"))] = GetGameTime() + 0.8;
}
 
void evt_KilledTank(Event event, const char[] name, bool dontBroadcast)
{
	g_iTankCount--;
}
 
public Action OnPlayerRunCmd(int client, int &buttons, int &impulse, float vel[3], float angles[3], int &weapon, int &subtype, int &cmdnum, int &tickcount, int &seed, int mouse[2])
{
	if (g_iTankCount > 0)
	{
		if (buttons & IN_ATTACK && IsValidTank(client) && !IsPlayerGhost(client))
		{
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
		}
	}
	return Plugin_Continue;
}
 
Action Timer_DoorCheck(Handle timer, int clientUserID)
{
	int client = GetClientOfUserId(clientUserID);
 	if (IsValidTank(client) && !IsPlayerGhost(client))
	{
		IsLookingAtBreakableDoor(client);
	}
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
	if (TR_DidHit())
	{
		g_iDoorEntity = TR_GetEntityIndex();
		TR_GetEndPosition(endorigin);
		if (g_iDoorEntity > 0 && GetVectorDistance(origin, endorigin) <= 90.0)
		{
			char sClassName[64], sModelName[64];
			GetEntityClassname(g_iDoorEntity, sClassName, sizeof(sClassName));
			GetEntPropString(g_iDoorEntity, Prop_Data, "m_ModelName", sModelName, sizeof(sModelName));
			if (strcmp(sClassName, DOOR_CLASS_01) == 0 && strcmp(sModelName, DOOR_MODEL_01) == 0 
			|| strcmp(sClassName, DOOR_CLASS_02) == 0 && strcmp(sModelName, DOOR_MODEL_02) == 0
			)
			{
				GetEntPropVector(g_iDoorEntity, Prop_Send, "m_vecOrigin", endorigin);
				float vPos[3], vAng[3];
				GetEntPropVector(g_iDoorEntity, Prop_Send, "m_vecOrigin", vPos);
				GetEntPropVector(g_iDoorEntity, Prop_Send, "m_angRotation", vAng);
				SetEntProp(g_iDoorEntity, Prop_Send, "m_CollisionGroup", 1);
				SetEntProp(g_iDoorEntity, Prop_Data, "m_CollisionGroup", 1);
				vPos[2] += 10000.0;
				TeleportEntity(g_iDoorEntity, vPos, NULL_VECTOR, NULL_VECTOR);
				vPos[2] -= 10000.0;
				SetEntityRenderMode(g_iDoorEntity, RENDER_TRANSALPHA);
				SetEntityRenderColor(g_iDoorEntity, 0, 0, 0, 0);
				int g_iBrokenEntity = CreateEntityByName("prop_physics");
				DispatchKeyValue(g_iBrokenEntity, "model", sModelName);
				DispatchKeyValue(g_iBrokenEntity, "spawnflags", "4");
				DispatchSpawn(g_iBrokenEntity);
				GetAngleVectors(angles, Push, NULL_VECTOR, NULL_VECTOR);
				power = GetRandomFloat(600.0, 800.0);
				Push[0] *= power;
				Push[1] *= power;
				Push[2] *= power;
				TeleportEntity(g_iBrokenEntity, vPos, vAng, Push);
				if (g_iBrokenEntity > 0)
				{
					char remove[64];
					FormatEx(remove, sizeof(remove), "OnUser1 !self:kill::%f:1", 5.0);
					SetVariantString(remove);
					SetEntityRenderFx(g_iBrokenEntity, RENDERFX_FADE_SLOW);
					AcceptEntityInput(g_iBrokenEntity, "AddOutput");
					AcceptEntityInput(g_iBrokenEntity, "FireUser1");
				}
			}
		}
	}
}

stock bool IsValidClient(int client)
{
	return client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client);
}
 
stock bool IsValidTank(int client)
{
	return IsValidClient(client) && GetClientTeam(client) == 3 && GetEntProp(client, Prop_Send, "m_zombieClass") == g_iTankClassIndex;
}

stock bool IsPlayerGhost(int client)
{
	return view_as<bool>(GetEntProp(client, Prop_Send, "m_isGhost"));
}
 
stock bool TraceFilterClients(int entity, int mask, any data)
{
 	return entity != data && entity > MaxClients;
}
