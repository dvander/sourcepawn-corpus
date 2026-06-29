#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0h"
#define LASERBOX_MODEL "models/w_models/Weapons/w_laser_sights.mdl"

public Plugin myinfo =
{
	name = "[L4D2] Laser Sight Box Auto Spawner",
	author = "bullet28 modded by Huck",
	description = "Randomly spawns laser boxes near an ammo pile",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=327691"
}

ConVar cvarOnOff, cvarChance, cvarIgnoreSaferoom;
bool bcvarIgnoreSaferoom, bWaitingFirstSurvivor;
float fSpawnPointOrigin[3], fLastRoundStartEvent, fLastBoxesProcessed;
int icvarChance;
bool g_bPluginDisabled = false;

public void OnPluginStart()
{
    CreateConVar("laser_autospawn_version", PLUGIN_VERSION, "Laser Sight Box Auto Spawner plugin version.", FCVAR_DONTRECORD);
    cvarOnOff = CreateConVar("laser_autospawn_on", "1", "Plugin On/Off. 0=Off, 1=On", _, true, 0.0, true, 1.0);
    cvarChance = CreateConVar("laser_autospawn_chance", "25", "Percent chance a laser box will spawn with an ammo pile. Min=0%, Max=100%", _, true, 0.0, true, 100.0);
    cvarIgnoreSaferoom = CreateConVar("laser_autospawn_ignoresaferoom", "1", "If set to 1 the laser boxes will not spawn in the saferoom. 0=Disabled, 1=Enabled", _, true, 0.0, true, 1.0);

    cvarOnOff.AddChangeHook(ConVarAllowChanged);
	cvarChance.AddChangeHook(ConVarsChanged);
    cvarIgnoreSaferoom.AddChangeHook(ConVarsChanged);
	
    AutoExecConfig(true, "l4d2_laser_autospawner");
}

public void OnConfigsExecuted() 
{
	IsAllowed();
}

void IsAllowed()
{
	if (g_bPluginDisabled)
		return;

	bool bCvarAllow = cvarOnOff.BoolValue;
	GetCvars();

	if(bCvarAllow)
	{
		HookEvent("round_start", eventRoundStart);
		HookEvent("player_team", eventPlayerTeam);
	}
	else
	{
		UnhookEvent("round_start", eventRoundStart);
		UnhookEvent("player_team", eventPlayerTeam);
	}
}


void ConVarAllowChanged(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
	IsAllowed();
}

void ConVarsChanged(ConVar hConVar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars() 
{
	icvarChance = cvarChance.IntValue;
	bcvarIgnoreSaferoom = cvarIgnoreSaferoom.BoolValue;
}

public void OnMapStart()
{
	if(!IsModelPrecached(LASERBOX_MODEL))
	{
		PrecacheModel(LASERBOX_MODEL);
	}
	
	bWaitingFirstSurvivor = true;
	fLastRoundStartEvent = 0.0;
	fLastBoxesProcessed = 0.0;
	g_bPluginDisabled = false;
}


Action eventPlayerTeam(Event event, char[] name, bool dontBroadcast) 
{
	if(!bWaitingFirstSurvivor)
	{
		return Plugin_Continue;
	}

	int client = GetClientOfUserId(event.GetInt("userid"));
	if(client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client))
	{
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fSpawnPointOrigin);
		bWaitingFirstSurvivor = false;
		addLaserSightBoxes();
	}

	return Plugin_Continue;
}

Action eventRoundStart(Event event, char[] name, bool dontBroadcast) 
{
	if(bWaitingFirstSurvivor)
	{
		return Plugin_Continue;
	}
	
	fLastRoundStartEvent = GetEngineTime();
	CreateTimer(1.0, roundStartDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

Action roundStartDelay(Handle timer) 
{
	addLaserSightBoxes();
	return Plugin_Stop;
}

int GetRandomUInt(int min, int max)
{
    return RoundToFloor(GetURandomFloat() * (max - min + 1)) + min;
}  

void addLaserSightBoxes() 
{
	if(fLastBoxesProcessed > fLastRoundStartEvent) return;
	fLastBoxesProcessed = GetEngineTime();

	int entity;
	while((entity = FindEntityByClassname(entity, "weapon_ammo_spawn")) != INVALID_ENT_REFERENCE)
	{
		int iRandomChance = GetRandomUInt(1,100);
		if(iRandomChance <= icvarChance) continue;
		
		float minDist = getMinDistanceToStopListEntities(entity);
		if(minDist == -1.0 || minDist >= 750.0 || !bcvarIgnoreSaferoom)
		{
			int ammoStack = CreateEntityByName("upgrade_laser_sight");
			if(ammoStack <= 0) return;

			float origin[3], angles[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
			
			origin[0] += 15.0;
			origin[1] -= 5.0;
			angles[1] -= 45.0;
			
			TeleportEntity(ammoStack, origin, angles, NULL_VECTOR);
			SetEntityModel(ammoStack, LASERBOX_MODEL);
			DispatchSpawn(ammoStack);
			
			g_bPluginDisabled = true;
			UnhookEvent("round_start", eventRoundStart);
			UnhookEvent("player_team", eventPlayerTeam);
			return;
		}
	}
}

float getMinDistanceToStopListEntities(int entity) 
{
	float minDist = -1.0;
	float entityVec[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityVec);

	char classname[32];
	for(int i = 0; i <= GetEntityCount(); i++)
	{
		if(!isValidEntity(i)) continue;

		GetEdictClassname(i, classname, sizeof(classname));
		if(StrEqual(classname, "prop_door_rotating_checkpoint") || StrEqual(classname, "info_survivor_position") || StrEqual(classname, "upgrade_laser_sight") || StrEqual(classname, "info_changelevel"))
		{
			float targetVec[3];
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", targetVec);
			float dist = GetVectorDistance(entityVec, targetVec);
			if(minDist == -1.0 || dist < minDist)
			{
				minDist = dist;
			}
		}
	}

	float dist = GetVectorDistance(entityVec, fSpawnPointOrigin);
	if(minDist == -1.0 || dist < minDist) minDist = dist;
	return minDist;
}

bool isValidEntity(int entity) 
{
	return entity > 0 && entity <= 2048 && IsValidEdict(entity) && IsValidEntity(entity);
}
