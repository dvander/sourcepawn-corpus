#include <sourcemod>
#include <sdkhooks>

#include <tf2_stocks>
#include <vector>

#define SOUND_ALERT_VOL	0.1

int homingClients[MAXPLAYERS + 1];
int bouncyClients[MAXPLAYERS + 1];

enum {
	entityRef,
	target,
	homing,
	bouncy,
	bounces
}

enum TFClassHeigth {
	TFClassHeigth_Unknown = 00.00,
	TFClassHeigth_Scout = 65.00,
	TFClassHeigth_Pyro = 68.00,
	TFClassHeigth_Soldier = 68.00,
	TFClassHeigth_DemoMan = 68.00,
	TFClassHeigth_Heavy = 75.00,
	TFClassHeigth_Engineer = 68.00,
	TFClassHeigth_Medic = 75.00,
	TFClassHeigth_Sniper = 75.00,
	TFClassHeigth_Spy = 75.00,
	TFClassHeigth_Sentry = 55.00,
};

#define ARRAY_ENTITIE_SIZE 5
ArrayList arrModifiedEntities;

ConVar cvar_defaulHomingState;
ConVar cvar_defaultBounceState;
ConVar cvar_timetoStarHoming;
ConVar cvar_maxModifiedProjectiles;
ConVar cvar_homingSpeed;
ConVar cvar_homingSpeedMultiplier;
ConVar cvar_projectileMaxBounces;
ConVar cvar_noHomingTimeOnBounce;
ConVar cvar_timetoStarBouncing;

public Plugin myinfo =  {
	name = "Homing and Bouncy Projectiles", 
	author = "lugui", 
	description = "Change the behavior of some projectiles", 
	version = "1.1"
};

public void OnPluginStart()
{
	arrModifiedEntities = CreateArray(ARRAY_ENTITIE_SIZE);
	cvar_defaulHomingState = CreateConVar("hbp_defaultHomingState", "0", "Default homing state for all players.", 0, true, 0.0, true, 1.0);
	cvar_defaultBounceState = CreateConVar("hbp_defaultBounceState", "0", "Default bouncy state for all players.", 0, true, 0.0, true, 1.0);
	cvar_timetoStarHoming = CreateConVar("hbp_timetoStarHoming", "0.2", "Time to wait before start homing.", 0, true, 0.0, false);
	cvar_maxModifiedProjectiles = CreateConVar("hbp_maxModifiedProjectile", "50", "Max Homing Projectiles that will be handled at the same time.", 0, true, 1.0);
	cvar_homingSpeed = CreateConVar("hbp_homingSpeed", "1.00", "Homing projectile initial speed.");
	cvar_homingSpeedMultiplier = CreateConVar("hbp_homingSpeedMultiplier", "1.10", "Homing projectile speed multiplier on deflect.");
	cvar_projectileMaxBounces = CreateConVar("hbp_projectileMaxBounces", "10", "Amount of times that a projectile can bounce.", 0, true, 1.0);
	cvar_noHomingTimeOnBounce = CreateConVar("hbp_noHomingTimeOnBounce", "0.3", "Time that the projectile will stop homing after bouncing.", 0, true, 0.0);
	cvar_timetoStarBouncing = CreateConVar("hbp_timetoStarBouncing", "0.1", "Time to wait before start bouncing.", 0, true, 0.0);

	LoadTranslations("common.phrases");
	RegAdminCmd("sm_homing", Command_homing, ADMFLAG_ROOT, "toggles homing projectiles");
	RegAdminCmd("sm_bouncy", Command_bounce, ADMFLAG_ROOT, "toggles projectile bounce");
}

public OnMapStart(){
	PrecacheSound("weapons/sentry_spot.wav");
	PrecacheSound("mvm/melee_impacts/bottle_hit_robo01.wav");
}

public OnClientPutInServer(client){
	homingClients[client] = GetConVarInt(cvar_defaulHomingState);
	bouncyClients[client] = GetConVarInt(cvar_defaultBounceState);
}

public OnClientDisconnect(client){
	homingClients[client] = 0;
	bouncyClients[client] = 0;
}

public Action Command_bounce(client, args){
	if(args == 0){
		if(IsValidClient(client)){
			toggleBouncyProjectile(client, !bouncyClients[client]);
			return Plugin_Handled;
		}
	}
	if(args < 2){
		ReplyToCommand(client, "Usage: sm_bounce <client> <0|1>");
	} else{
		char arg1[128], arg2[128];
		int state;
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		state = StringToInt(arg2);

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_TARGET_NONE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for (int i = 0; i < target_count; i++){
			if(IsValidClient(target_list[i])){
				if(IsValidClient(target_list[i])){
					toggleBouncyProjectile(target_list[i], state);
				}
			}
		}
	}
	return Plugin_Handled;
}

toggleBouncyProjectile(int client, int state) {
	bouncyClients[client] = state;
	if(state > 0){
		PrintToChat(client, "Bouncy Projectiles Enabled");
	} else {
		PrintToChat(client, "Bouncy Projectiles Disabled");
	}
}

public Action Command_homing(client, args){
	if(args == 0){
		if(IsValidClient(client)){
			toggleHomingProjectile(client, !homingClients[client]);
			return Plugin_Handled;
		}
	}
	if(args < 2){
		ReplyToCommand(client, "Usage: sm_projectilemodifier <client> <0|1>");
	} else{
		char arg1[128], arg2[128];
		int state;
		GetCmdArg(1, arg1, sizeof(arg1));
		GetCmdArg(2, arg2, sizeof(arg2));
		state = StringToInt(arg2);

		char target_name[MAX_TARGET_LENGTH];
		int target_list[MAXPLAYERS], target_count;
		bool tn_is_ml;
		if ((target_count = ProcessTargetString(
			arg1,
			client,
			target_list,
			MAXPLAYERS,
			COMMAND_TARGET_NONE,
			target_name,
			sizeof(target_name),
			tn_is_ml)) <= 0)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		for (int i = 0; i < target_count; i++){
			if(IsValidClient(target_list[i])){
				if(IsValidClient(target_list[i])){
					toggleHomingProjectile(target_list[i], state);
				}
			}
		}
	}
	return Plugin_Handled;
}

toggleHomingProjectile(int client, int state) {
	homingClients[client] = state;
	if(state > 0){
		PrintToChat(client, "Homing Projectiles Enabled");
	} else {
		PrintToChat(client, "Homing Projectiles Disabled");
	}
	
}

public OnEntityCreated(iProjectile, const char[] classname){
	if( StrContains(classname, "tf_projectile") >= 0 && (iProjectile > MaxClients && IsValidEntity(iProjectile)) ){
		SDKHook(iProjectile, SDKHook_SpawnPost, OnEntitySpawn);
	}
}

public OnEntitySpawn(int iProjectile) {
	int iLauncher = 0;
	if(HasEntProp(iProjectile, Prop_Send, "m_hOwnerEntity")){
		iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwnerEntity");
	} else if (HasEntProp(iProjectile, Prop_Send, "m_hOwner")) {
		iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hOwner");
	} else if (HasEntProp(iProjectile, Prop_Send, "m_hThrower")) {
		iLauncher = GetEntPropEnt(iProjectile, Prop_Send, "m_hThrower");
	}
	if(!isValidClient(iLauncher)){
		return;
	}
	int iData[ARRAY_ENTITIE_SIZE];
	iData[entityRef] = EntIndexToEntRef(iProjectile);
	iData[target] = 0;
	iData[homing] = 0;
	iData[bouncy] = 0;
	iData[bounces] = 0;
	if(arrModifiedEntities.Length <= GetConVarInt(cvar_maxModifiedProjectiles)){
		if(bouncyClients[iLauncher] == 1){
			float time = GetConVarFloat(cvar_timetoStarBouncing);
			if(time == 0) {
				iData[bouncy] = 1;
			} else {
				CreateTimer(time, Timer_SetBouncy, iData[entityRef]);
			}
			arrModifiedEntities.PushArray(iData);
		}
		if(homingClients[iLauncher] == 1){
			float time = GetConVarFloat(cvar_timetoStarHoming);
			if(time == 0) {
				iData[homing] = 1;
			} else {
				CreateTimer(time, Timer_SetHoming, iData[entityRef]);
			}
			arrModifiedEntities.PushArray(iData);
		}
		SDKHook(iProjectile, SDKHook_StartTouch, OnStartTouch);
	} else {
		PrintToChat(iLauncher, "Maximum simultaneous modified projectiles reached.");
	}
}

public Action Timer_SetBouncy(Handle hTimer, int iRef){
	int iData[ARRAY_ENTITIE_SIZE];
	int indexRefProjectile = findEntityByRef(iRef);
	if(indexRefProjectile > -1){
		arrModifiedEntities.GetArray(indexRefProjectile, iData);
		iData[bouncy] = 1;
		arrModifiedEntities.SetArray(indexRefProjectile, iData);
	}
	return Plugin_Handled;
}

public Action Timer_SetHoming(Handle hTimer, int iRef){
	int iData[ARRAY_ENTITIE_SIZE];
	int indexRefProjectile = findEntityByRef(iRef);
	if(indexRefProjectile > -1){
		arrModifiedEntities.GetArray(indexRefProjectile, iData);
		iData[homing] = 1;
		arrModifiedEntities.SetArray(indexRefProjectile, iData);
	}
	return Plugin_Handled;
}

public OnGameFrame(){
	int iData[ARRAY_ENTITIE_SIZE];
	int iProjectile;
	for(int i = arrModifiedEntities.Length -1; i >= 0; i--){
		if(arrModifiedEntities.GetArray(i, iData)){
			iProjectile = EntRefToEntIndex(iData[entityRef]);
			if(iData[entityRef] == 0 || iProjectile < MaxClients){
				arrModifiedEntities.Erase(i);
			} else{
				if(iData[homing] == 1){
				HomingProjectile_Think(iProjectile, i, iData[target]);
			}
			}
		}
	}
}

public HomingProjectile_Think(iProjectile, indexArrEntitie, iCurrentTarget) {
	int iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	int valid = HomingProjectile_IsValidTarget(iCurrentTarget, iProjectile, iTeam);
	if(!valid){
		HomingProjectile_FindTarget(iProjectile, indexArrEntitie);
	}else{
		HomingProjectile_TurnToTarget(iCurrentTarget, iProjectile);
	}
}


bool HomingProjectile_IsValidTarget(client, iProjectile, iTeam) {
	if(client >= 1 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) != iTeam){
		if(
			TF2_IsPlayerInCondition(client, TFCond_Cloaked) ||
			(TF2_IsPlayerInCondition(client, TFCond_Disguised) && GetEntProp(client, Prop_Send, "m_nDisguiseTeam") == iTeam)
		){
			return false;
		}
		float flStart[3];
		GetClientEyePosition(client, flStart);
		float flEnd[3];
		GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flEnd);
		Handle hTrace = TR_TraceRayFilterEx(flStart, flEnd, MASK_SOLID, RayType_EndPoint, TraceFilterHoming, iProjectile);
		if(hTrace != INVALID_HANDLE)
		{
			if(TR_DidHit(hTrace))
			{
				CloseHandle(hTrace);
			} else {
				CloseHandle(hTrace);
				return true;
			}
		}
	}
	return false;
}

public bool TraceFilterHoming(entity, contentsMask, any:iProjectile) {
	if(entity == iProjectile || (entity >= 1 && entity <= MaxClients)){
		return false;
	}
	return true;
}

HomingProjectile_FindTarget(iProjectile, indexArrEntitie) {
	int iTeam = GetEntProp(iProjectile, Prop_Send, "m_iTeamNum");
	float flPos1[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flPos1);
	
	int iBestTarget;
	float flBestLength = 99999.9;
	for(int i = 1; i <= MaxClients; i++) {
		if(HomingProjectile_IsValidTarget(i, iProjectile, iTeam)){
			
			float flPos2[3];
			GetClientEyePosition(i, flPos2);
			
			float flDistance = GetVectorDistance(flPos1, flPos2);
			
			if(flDistance < flBestLength)
			{
				iBestTarget = i;
				flBestLength = flDistance;
			}
		}
	}
	
	if(iBestTarget >= 1 && iBestTarget <= MaxClients)
	{
		HomingProjectile_TurnToTarget(iBestTarget, iProjectile);
	}else{
		int iData[ARRAY_ENTITIE_SIZE];
		arrModifiedEntities.GetArray(indexArrEntitie, iData);
		iData[target] = 0;
		arrModifiedEntities.SetArray(indexArrEntitie, iData);
	}
}

HomingProjectile_TurnToTarget(client, iProjectile)
{
	float flTargetPos[3];
	GetClientAbsOrigin(client, flTargetPos);
	float heigth = getEntityHeigth(client) - 30.0;
	float flRocketPos[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vecOrigin", flRocketPos);

	float flInitialVelocity[3];
	GetEntPropVector(iProjectile, Prop_Send, "m_vInitialVelocity", flInitialVelocity);
	float flSpeedInit = GetVectorLength(flInitialVelocity);
	float flSpeedBase = flSpeedInit * GetConVarFloat(cvar_homingSpeed);

	flTargetPos[2] += heigth;
	flTargetPos[2] += 30 + Pow(GetVectorDistance(flTargetPos, flRocketPos), 2.0) / 10000;
	
	float flNewVec[3];
	SubtractVectors(flTargetPos, flRocketPos, flNewVec);
	NormalizeVector(flNewVec, flNewVec);
	
	float flAng[3];
	GetVectorAngles(flNewVec, flAng);

	float flSpeedNew = flSpeedBase + GetEntProp(iProjectile, Prop_Send, "m_iDeflected") * flSpeedBase * GetConVarFloat(cvar_homingSpeedMultiplier);
	
	ScaleVector(flNewVec, flSpeedNew);
	TeleportEntity(iProjectile, NULL_VECTOR, flAng, flNewVec);
}

public Action OnStartTouch(int iProjectile, int iVictim){
	int wallColisionGroup = GetEntProp(iVictim, Prop_Data, "m_CollisionGroup");
		
	int iRefProjectile = EntIndexToEntRef(iProjectile);
	int indexArrEntitie = findEntityByRef(iRefProjectile);
	if(indexArrEntitie == -1){
		return Plugin_Continue;
	}
	
	int iData[ARRAY_ENTITIE_SIZE];
	arrModifiedEntities.GetArray(indexArrEntitie, iData);
	
	if (iData[bounces] >= GetConVarInt(cvar_projectileMaxBounces) || iData[bouncy] == 0 || iVictim > 0 && iVictim <= MaxClients || wallColisionGroup){
		iData[entityRef] = 0;	
	}
	iData[bounces]++;
	arrModifiedEntities.SetArray(indexArrEntitie, iData);
	
	if(iData[entityRef] != 0){
		SDKHook(iProjectile, SDKHook_Touch, OnTouch);
	}
	return Plugin_Handled;
}

public Action OnTouch(int iProjectile, int iWall)
{
	float vOrigin[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_vecOrigin", vOrigin);
	
	float vAngles[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_angRotation", vAngles);
	
	float vVelocity[3];
	GetEntPropVector(iProjectile, Prop_Data, "m_vecAbsVelocity", vVelocity);
	
	Handle trace = TR_TraceRayFilterEx(vOrigin, vAngles, MASK_SHOT, RayType_Infinite, TEF_ExcludeEntity, iProjectile);
	
	if(!TR_DidHit(trace))
	{
		CloseHandle(trace);
		return Plugin_Continue;
	}
	
	float vNormal[3];
	TR_GetPlaneNormal(trace, vNormal);
	
	CloseHandle(trace);
	
	float dotProduct = GetVectorDotProduct(vNormal, vVelocity);
	
	ScaleVector(vNormal, dotProduct);
	ScaleVector(vNormal, 2.0);
	
	float vBounceVec[3];
	SubtractVectors(vVelocity, vNormal, vBounceVec);
	
	float vNewAngles[3];
	GetVectorAngles(vBounceVec, vNewAngles);
	
	TeleportEntity(iProjectile, NULL_VECTOR, vNewAngles, vBounceVec);

	int iRefProjectile = EntIndexToEntRef(iProjectile);
	int indexArrEntitie = findEntityByRef(iRefProjectile);
	if(indexArrEntitie == -1){
		return Plugin_Continue;
	}
	int iData[ARRAY_ENTITIE_SIZE];
	arrModifiedEntities.GetArray(indexArrEntitie, iData);

	float noHomingTime = GetConVarFloat(cvar_noHomingTimeOnBounce);
	if(noHomingTime >= 0.1 && iData[homing] == 1){
		if(indexArrEntitie > -1){
			iData[homing] = 0;
			arrModifiedEntities.SetArray(indexArrEntitie, iData);
			CreateTimer(noHomingTime ,Timer_enableHoming , indexArrEntitie);
		}
	}

	EmitSoundToAll("mvm/melee_impacts/bottle_hit_robo01.wav", iProjectile, _, SNDLEVEL_TRAIN,_,SOUND_ALERT_VOL);

	SDKUnhook(iProjectile, SDKHook_Touch, OnTouch);
	return Plugin_Handled;
}

public Action Timer_enableHoming(Handle hTimer, indexArrEntitie){
	if(indexArrEntitie < arrModifiedEntities.Length){
		int iData[ARRAY_ENTITIE_SIZE];
		arrModifiedEntities.GetArray(indexArrEntitie, iData);
		iData[homing] = 1;
		arrModifiedEntities.SetArray(indexArrEntitie, iData);
	}
	return Plugin_Handled;
}

int findEntityByRef(int iRef){
	int iData[ARRAY_ENTITIE_SIZE];
	for(int i = 0; i < arrModifiedEntities.Length; i++){
		arrModifiedEntities.GetArray(i, iData);
		if(iData[entityRef] == iRef){
			return i;
		}
	}
	return -1;
}

public bool TEF_ExcludeEntity(int entity, int contentsMask, int data){
	return (entity != data);
}

IsValidClient(int client) {
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) && !IsFakeClient(client)){
		return false; 
	}
	return true; 
}

float getEntityHeigth(int entity){
	TFClassType class = TF2_GetPlayerClass(entity);
	switch(class){
		case TFClass_Scout: {
			return view_as<float>(TFClassHeigth_Scout);
		}
		case TFClass_Soldier: {
			return view_as<float>(TFClassHeigth_Soldier);
		}
		case TFClass_Pyro:{
			return view_as<float>(TFClassHeigth_Pyro);
		}
		case TFClass_DemoMan: {
			return view_as<float>(TFClassHeigth_DemoMan);
		}
		case TFClass_Heavy: {
			return view_as<float>(TFClassHeigth_Heavy);
		}
		case TFClass_Engineer: {
			return view_as<float>(TFClassHeigth_Engineer);
		}
		case TFClass_Medic: {
			return view_as<float>(TFClassHeigth_Medic);
		}
		case TFClass_Sniper: {
			return view_as<float>(TFClassHeigth_Sniper);
		}
		case TFClass_Spy: {
			return view_as<float>(TFClassHeigth_Spy);
		}
	}
	return view_as<float>(TFClassHeigth_Unknown);
}

stock bool isValidClient(int client, bool allowBot = false) {
	if ( !( 1 <= client <= MaxClients ) || !IsClientInGame(client) || IsClientSourceTV(client) || (!allowBot && IsFakeClient(client) ) ){
		return false;
	}
	return true;
}