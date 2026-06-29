#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#pragma newdecls required

public Plugin myinfo =
{
	name = "Ammo Piles with Laser Box",
	author = "bullet28",
	description = "Randomly creates laserboxes near the ammo piles",
	version = "1",
	url = ""
}

#define LASERBOX_MODEL "models/w_models/Weapons/w_laser_sights.mdl"

ConVar cvarChance;
ConVar cvarIgnoreSaferoom;
bool bWaitingFirstSurvivor;
float fSpawnPointOrigin[3];
float fLastRoundStartEvent;
float fLastBoxesProcessed;

public void OnPluginStart() {
	cvarChance = CreateConVar("laser_autospawn_chance", "20", "Chance of a laser box spawning on the ammo pile", FCVAR_NONE);
	cvarIgnoreSaferoom = CreateConVar("laser_autospawn_ignoresaferoom", "1", "If set to 1 the laserboxes will not spawn in the saferoom", FCVAR_NONE);
	HookEvent("round_start", eventRoundStart);
	HookEvent("player_team", eventPlayerTeam);
}

public void OnMapStart() {
	if (!IsModelPrecached(LASERBOX_MODEL))
		PrecacheModel(LASERBOX_MODEL);
	bWaitingFirstSurvivor = true;
	fLastRoundStartEvent = 0.0;
	fLastBoxesProcessed = 0.0;
}

public Action eventPlayerTeam(Event event, char[] name, bool dontBroadcast) {
	if (!bWaitingFirstSurvivor) return;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client)) {
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fSpawnPointOrigin);
		bWaitingFirstSurvivor = false;
		addLaserSightBoxes();
	}
}

public Action eventRoundStart(Event event, char[] name, bool dontBroadcast) {
	if (bWaitingFirstSurvivor) return;
	fLastRoundStartEvent = GetEngineTime();
	CreateTimer(1.0, roundStartDelay, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action roundStartDelay(Handle timer) {
	addLaserSightBoxes();
}

void addLaserSightBoxes() {
	if (fLastBoxesProcessed > fLastRoundStartEvent) return;
	fLastBoxesProcessed = GetEngineTime();

	int entity;
	while ((entity = FindEntityByClassname(entity, "weapon_ammo_spawn")) != INVALID_ENT_REFERENCE) {
		if (GetRandomInt(1, 100) > GetConVarInt(cvarChance)) continue;
		
		float minDist = getMinDistanceToStopListEntities(entity);
		if (minDist == -1.0 || minDist >= 750.0 || !cvarIgnoreSaferoom.BoolValue) {
			int ammoStack = CreateEntityByName("upgrade_laser_sight");
			if (ammoStack <= 0) continue;

			float origin[3], angles[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", origin);
			GetEntPropVector(entity, Prop_Send, "m_angRotation", angles);
			
			origin[0] += 15.0;
			origin[1] -= 5.0;
			angles[1] -= 45.0;
			
			TeleportEntity(ammoStack, origin, angles, NULL_VECTOR);
			SetEntityModel(ammoStack, LASERBOX_MODEL);
			DispatchSpawn(ammoStack);
		}
	}
}

float getMinDistanceToStopListEntities(int entity) {
	float minDist = -1.0;
	float entityVec[3];
	GetEntPropVector(entity, Prop_Data, "m_vecOrigin", entityVec);

	char classname[32];
	for (int i = 0; i <= GetEntityCount(); i++) {
		if (!isValidEntity(i)) continue;

		GetEdictClassname(i, classname, sizeof(classname));
		if (StrEqual(classname, "prop_door_rotating_checkpoint")
		|| StrEqual(classname, "info_survivor_position")
		|| StrEqual(classname, "upgrade_laser_sight")
		|| StrEqual(classname, "info_changelevel")) {
			float targetVec[3];
			GetEntPropVector(i, Prop_Data, "m_vecOrigin", targetVec);
			float dist = GetVectorDistance(entityVec, targetVec);
			if (minDist == -1.0 || dist < minDist) {
				minDist = dist;
			}
		}
	}

	float dist = GetVectorDistance(entityVec, fSpawnPointOrigin);
	if (minDist == -1.0 || dist < minDist) minDist = dist;
	return minDist;
}

bool isValidEntity(int entity) {
	return entity > 0 && entity <= 2048 && IsValidEdict(entity) && IsValidEntity(entity);
}
