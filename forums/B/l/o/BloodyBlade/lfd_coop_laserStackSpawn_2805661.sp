#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"
#define CVAR_FLAGS FCVAR_NOTIFY
#define LASERBOX_MODEL "models/w_models/Weapons/w_laser_sights.mdl"

public Plugin myinfo =
{
	name = "Ammo Piles with Laser Box",
	author = "bullet28",
	description = "Randomly creates laserboxes near the ammo piles",
	version = PLUGIN_VERSION,
	url = ""
}

ConVar cvarOnOff, cvarChance, cvarIgnoreSaferoom;
bool bcvarIgnoreSaferoom, bWaitingFirstSurvivor;
float fSpawnPointOrigin[3], fLastRoundStartEvent, fLastBoxesProcessed;
int icvarChance;

public void OnPluginStart() {
    CreateConVar("lfd_coop_laserStackSpawn_version",	PLUGIN_VERSION, "Ammo Piles with Laser Box plugin version.", CVAR_FLAGS|FCVAR_DONTRECORD);
    cvarOnOff = CreateConVar("laser_autospawn_on", "1", "Plugin On/Off", CVAR_FLAGS);
    cvarChance = CreateConVar("laser_autospawn_chance", "20", "Chance of a laser box spawning on the ammo pile", CVAR_FLAGS);
    cvarIgnoreSaferoom = CreateConVar("laser_autospawn_ignoresaferoom", "1", "If set to 1 the laserboxes will not spawn in the saferoom", CVAR_FLAGS);

    cvarOnOff.AddChangeHook(ConVarAllowChanged);
    cvarChance.AddChangeHook(ConVarsChanged);
    cvarIgnoreSaferoom.AddChangeHook(ConVarsChanged);

    AutoExecConfig(true, "lfd_coop_laserStackSpawn");
}

public void OnConfigsExecuted() {
	IsAllowed();
}

void IsAllowed()
{
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

void GetCvars() {

	icvarChance = cvarChance.IntValue;
	bcvarIgnoreSaferoom = cvarIgnoreSaferoom.BoolValue;
}

public void OnMapStart() {
	if (!IsModelPrecached(LASERBOX_MODEL))
		PrecacheModel(LASERBOX_MODEL);
	bWaitingFirstSurvivor = true;
	fLastRoundStartEvent = 0.0;
	fLastBoxesProcessed = 0.0;
}

Action eventPlayerTeam(Event event, char[] name, bool dontBroadcast) {
	if (!bWaitingFirstSurvivor) return Plugin_Continue;

	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client > 0 && client <= MaxClients && IsClientInGame(client) && IsFakeClient(client)) {
		GetEntPropVector(client, Prop_Send, "m_vecOrigin", fSpawnPointOrigin);
		bWaitingFirstSurvivor = false;
		addLaserSightBoxes();
	}

	return Plugin_Continue;
}

Action eventRoundStart(Event event, char[] name, bool dontBroadcast) {
	if (bWaitingFirstSurvivor) return Plugin_Continue;
	fLastRoundStartEvent = GetEngineTime();
	CreateTimer(1.0, roundStartDelay, _, TIMER_FLAG_NO_MAPCHANGE);
	return Plugin_Continue;
}

Action roundStartDelay(Handle timer) {
	addLaserSightBoxes();
	return Plugin_Stop;
}

void addLaserSightBoxes() {
	if (fLastBoxesProcessed > fLastRoundStartEvent) return;
	fLastBoxesProcessed = GetEngineTime();

	int entity;
	while ((entity = FindEntityByClassname(entity, "weapon_ammo_spawn")) != INVALID_ENT_REFERENCE) {
		if (GetRandomInt(1, 100) > icvarChance) continue;
		
		float minDist = getMinDistanceToStopListEntities(entity);
		if (minDist == -1.0 || minDist >= 750.0 || !bcvarIgnoreSaferoom) {
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
