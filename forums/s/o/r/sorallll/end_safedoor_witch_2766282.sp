#pragma semicolon 1
#pragma newdecls required
#include <sourcemod>
#include <sdktools>
#include <left4dhooks>

#define GAMEDATA	"end_safedoor_witch"

Handle
	g_hSDKIsCheckpointDoor,
	g_hSDKIsCheckpointExitDoor;

int
	g_iRoundStart,
	g_iPlayerSpawn;

public Plugin myinfo = 
{
	name = 			"End Safedoor Witch",
	author = 		"sorallll",
	description = 	"",
	version = 		"1.0.0",
	url = 			""
}

public void OnPluginStart()
{
	vLoadGameData();

	HookEvent("round_end", Event_RoundEnd, EventHookMode_PostNoCopy);
	HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_PostNoCopy);
}

public void OnMapEnd()
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

void Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_iRoundStart = 0;
	g_iPlayerSpawn = 0;
}

void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	if(g_iRoundStart == 0 && g_iPlayerSpawn == 1)
		CreateTimer(1.0, Timer_SpawnWitch, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStart = 1;
}

void Event_PlayerSpawn(Event event, const char[] name, bool dontBroadcast)
{
	if(g_iRoundStart == 1 && g_iPlayerSpawn == 0)
		CreateTimer(1.0, Timer_SpawnWitch, _, TIMER_FLAG_NO_MAPCHANGE);
	g_iPlayerSpawn = 1;
}

Action Timer_SpawnWitch(Handle timer)
{
	int entity = INVALID_ENT_REFERENCE;
	if((entity = FindEntityByClassname(MaxClients + 1, "info_changelevel")) == INVALID_ENT_REFERENCE)
		entity = FindEntityByClassname(MaxClients + 1, "trigger_changelevel");

	if(entity != INVALID_ENT_REFERENCE)
	{
		int i;
		float vPos[3];
		entity = MaxClients + 1;
		while((entity = FindEntityByClassname(entity, "prop_door_rotating_checkpoint")) != INVALID_ENT_REFERENCE)
		{
			if(GetEntProp(entity, Prop_Data, "m_eDoorState") != 2)
				continue;

			i = GetEntProp(entity, Prop_Data, "m_spawnflags");
			if(i & 8192 == 0 || i & 32768 != 0)
				continue;
		
			if(!SDKCall(g_hSDKIsCheckpointDoor, entity))
				continue;

			if(SDKCall(g_hSDKIsCheckpointExitDoor, entity))
				continue;

			GetEntPropVector(entity, Prop_Data, "m_vecAbsOrigin", vPos);
			i = L4D_GetNearestNavArea(vPos);
			if(i)
			{
				L4D_FindRandomSpot(i, vPos);
				iSpawnWitch(vPos);
			}
		}
	}

	return Plugin_Continue;
}

// https://forums.alliedmods.net/showthread.php?p=1471101
void iSpawnWitch(float vPos[3])
{
	int entity = CreateEntityByName("witch");
	if(entity != -1)
	{
		TeleportEntity(entity, vPos, NULL_VECTOR, NULL_VECTOR);
		SetEntPropFloat(entity, Prop_Send, "m_rage", 0.5);
		SetEntProp(entity, Prop_Data, "m_nSequence", 4);
		DispatchSpawn(entity);
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 1);
		CreateTimer(0.3, Timer_SolidCollision, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
	}
}

Action Timer_SolidCollision(Handle timer, int entity)
{
	if(EntRefToEntIndex(entity) != INVALID_ENT_REFERENCE)
		SetEntProp(entity, Prop_Send, "m_CollisionGroup", 0);

	return Plugin_Continue;
}

void vLoadGameData()
{
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "gamedata/%s.txt", GAMEDATA);
	if(FileExists(sPath) == false)
		SetFailState("\n==========\nMissing required file: \"%s\".\n==========", sPath);

	GameData hGameData = new GameData(GAMEDATA);
	if(hGameData == null)
		SetFailState("Failed to load \"%s.txt\" gamedata.", GAMEDATA);

	StartPrepSDKCall(SDKCall_Entity);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CPropDoorRotatingCheckpoint::IsCheckpointDoor") == false)
		SetFailState("Failed to find offset: CPropDoorRotatingCheckpoint::IsCheckpointDoor");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKIsCheckpointDoor = EndPrepSDKCall();
	if(g_hSDKIsCheckpointDoor == null)
		SetFailState("Failed to create SDKCall: CPropDoorRotatingCheckpoint::IsCheckpointDoor");

	StartPrepSDKCall(SDKCall_Entity);
	if(PrepSDKCall_SetFromConf(hGameData, SDKConf_Virtual, "CPropDoorRotatingCheckpoint::IsCheckpointExitDoor") == false)
		SetFailState("Failed to find offset: CPropDoorRotatingCheckpoint::IsCheckpointExitDoor");
	PrepSDKCall_SetReturnInfo(SDKType_Bool, SDKPass_Plain);
	g_hSDKIsCheckpointExitDoor = EndPrepSDKCall();
	if(g_hSDKIsCheckpointExitDoor == null)
		SetFailState("Failed to create SDKCall: CPropDoorRotatingCheckpoint::IsCheckpointExitDoor");

	delete hGameData;
}