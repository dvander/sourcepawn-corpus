/*
 *descriptions here
 */

new const String:PLUGIN_VERSION[60] = "1.1.3";

public Plugin:myinfo = {
	
	name = "TF2CoolRocket",
	author = "javalia",
	description = "based on idea and work of predcrab`s extension, sidewinder",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
	
};

//uncomment if u wanna use function of these include file
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include "sdkhooks"
#include "stocklib"

//semicolon!!!!
#pragma semicolon 1

new Handle:g_cvarInduceWeaponList = INVALID_HANDLE;
new Handle:g_cvarArrowToHead = INVALID_HANDLE;
new Handle:g_cvarMvMDisabler = INVALID_HANDLE;
new Handle:g_cvarAdminFlag = INVALID_HANDLE;
new Handle:g_cvarLifeTime = INVALID_HANDLE;

new g_iTarget[2048];
new bool:g_bToHead[2048];
new bool:g_bMannVsMachines;
new bool:g_bEnabled;
new g_iRocketLifeTimeMeters[2048];

#define FPS_LOGIC_RATE		22.0
new Handle:g_hLogicTimer;	// Logic timer
new Handle:g_hProjectileList = INVALID_HANDLE;

public OnPluginStart(){

	RegAdminCmd("sm_cr_missilehoming", Toggle_Homing, ADMFLAG_ROOT, "Toggle Missle Homing");

	CreateConVar("TF2CoolRocket_version", PLUGIN_VERSION, "plugin info cvar", FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	g_cvarInduceWeaponList = CreateConVar("TF2CoolRocket_InduceWeaponList", "tf_projectile_sentryrocket;tf_projectile_rocket;tf_projectile_flare;", "add classname of projectile");
	g_cvarArrowToHead = CreateConVar("TF2CoolRocket_ArrowToHead", "1", "1 or 0");
	g_cvarMvMDisabler = CreateConVar("TF2CoolRocket_MvMdisabler", "1", "Disable plugin for BLU team (MvM mode).");
	g_cvarAdminFlag = CreateConVar("TF2CoolRocket_AdminFlag", "", "Admins Flag for access; make it empty to turn off.");
	g_cvarLifeTime = CreateConVar("TF2CoolRocket_lifetime", "10", "Rocket's life time in seconds (0 for infinite, -1 to disable plugin).");

	g_bMannVsMachines = false;
	g_bEnabled = true;
	g_hLogicTimer = INVALID_HANDLE;
	g_hProjectileList = CreateArray(1);
}

public OnMapStart(){

	AutoExecConfig();
	new iEnt = FindEntityByClassname( -1, "tf_logic_mann_vs_machine" );
	g_bMannVsMachines = ( iEnt > MaxClients && IsValidEntity( iEnt ) );
	ClearArray(g_hProjectileList);
	g_hLogicTimer = CreateTimer(1.0 / FPS_LOGIC_RATE, OnThinkHookSimulation, _, TIMER_REPEAT);
}

public OnMapEnd()
{
	ClearArray(g_hProjectileList);
	if (g_hLogicTimer != INVALID_HANDLE) KillTimer(g_hLogicTimer);
	g_hLogicTimer = INVALID_HANDLE;
}

public OnEntityCreated(entity, const String:classname[]){
	
	if (!g_bEnabled)
		return;
	if (GetConVarInt(g_cvarLifeTime) < 0)
		return;

	//lets save cpu. at this will avoid long string compare compute that can execute for EVERY entitys that are created on server.
	if(StrContains(classname, "tf_projectile_", false) == 0){

		decl String:cvarstring[2048];
		GetConVarString(g_cvarInduceWeaponList, cvarstring, 2048);
		
		if(StrContains(cvarstring, classname, false) != -1){

			//hook think, create dynamic array, init thinkcount...
			g_iTarget[entity] = INVALID_ENT_REFERENCE;
			if (StrContains(classname, "tf_projectile_rocket", false) == 0)
				g_iRocketLifeTimeMeters[entity] = -RoundToZero(FPS_LOGIC_RATE/8);	// wait one eights of a sec before steering for rocket jump
			else
				g_iRocketLifeTimeMeters[entity] = 0;
			
			if(StrEqual(classname, "tf_projectile_arrow", false)){
			
				if(GetConVarBool(g_cvarArrowToHead)){
				
					g_bToHead[entity] = true;
				
				}else{
				
					g_bToHead[entity] = false;
				
				}
			
			}
			
			PushArrayCell(g_hProjectileList, entity);
		}
	
	}
	
}

public Action:Toggle_Homing(client, args)
{
	new String:arg1[32];
	GetCmdArg(1, arg1, 32);
	g_bEnabled = (StringToInt(arg1) != 0);

	return Plugin_Handled;
}

public Action:OnThinkHookSimulation(Handle:hTimer, any:Data)
{
	new index = GetArraySize(g_hProjectileList)-1;
	while (index >= 0)
	{
		if (!RocketThinkHook(GetArrayCell(g_hProjectileList, index)))
			RemoveFromArray(g_hProjectileList, index);
		--index;
	}
}

public RocketThinkHook(entity){

	if (!IsValidEntity(entity))
		return false;

	new String:sb[3];
	GetConVarString(g_cvarAdminFlag, sb, 2);
	new adm = ReadFlagString(sb);
	if( adm!=0 ){
	
		new owner = GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity");
		if( owner > MaxClients && IsValidEntity(owner) )
			owner = GetEntDataEnt2(owner, FindSendPropOffs("CObjectSentrygun","m_hBuilder"));
		if( owner < 1 || owner > MaxClients )
			return false;
		if( (GetUserFlagBits(owner) & adm)==0 )
			return false;
			
	}

	if( g_bMannVsMachines && GetConVarBool(g_cvarMvMDisabler) && GetEntProp(entity, Prop_Data, "m_iTeamNum") == _:TFTeam_Blue )
		return false;
	
	new lifeTime = GetConVarInt(g_cvarLifeTime);
	if( lifeTime < 0 || !g_bEnabled)	//plugin disabled
		return false;
	if( g_iRocketLifeTimeMeters[entity]++ < 0 )	//allow rocket jump
		return true;
	if( lifeTime > 0 && (g_iRocketLifeTimeMeters[entity]/FPS_LOGIC_RATE) >= lifeTime )	//quit steering after a time limit
		return false;


	//is rocket has target?
	if(isValidTarget(entity, g_iTarget[entity]) && isTargetTraceable(entity, g_iTarget[entity])){
		
		new target = EntRefToEntIndex(g_iTarget[entity]);
		
		decl Float:rocketposition[3], Float:targetpos[3], Float:vecangle[3], Float:angle[3];
		GetEntPropVector(entity, Prop_Send, "m_vecOrigin", rocketposition);
		//로켓포지션에서 추적 위치로 가는 벡터를 구한다
		GetClientEyePosition(target, targetpos);
		if(!g_bToHead[entity]){
		
			targetpos[2] = targetpos[2] - 25.0;
			
		}
		MakeVectorFromPoints(rocketposition, targetpos, vecangle);
		NormalizeVector(vecangle, vecangle);
		GetVectorAngles(vecangle, angle);
		decl Float:speed[3];
		GetEntPropVector(entity, Prop_Data, "m_vecVelocity", speed);
		ScaleVector(vecangle, GetVectorLength(speed));
		TeleportEntity(entity, NULL_VECTOR, angle, vecangle);
	
	}else{
	
		g_iTarget[entity] = findNewTarget(entity);
		if (g_iTarget[entity] == INVALID_ENT_REFERENCE)	//-- no target found: avoid collisions instead of going straight ahead
		{
			decl Float:position[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
			decl Float:speed[3];
			GetEntPropVector(entity, Prop_Data, "m_vecAbsVelocity", speed);
			new Float:velocity = GetVectorLength(speed);
			decl Float:angle[3];
			GetEntPropVector(entity, Prop_Data, "m_angRotation", angle);
			
			new Handle:traceOne = TR_TraceRayFilterEx(position, angle, MASK_SHOT, RayType_Infinite, tracerayfilterdefault, entity);
			if(TR_DidHit(traceOne))
			{
				decl Float:target[3];
				TR_GetEndPosition(target, traceOne);
				new Float:bestDistance = GetVectorDistance(target, position, true);
				decl Float:bestAngle[3];
				bestAngle[0] = angle[0];
				bestAngle[1] = angle[1];
				bestAngle[2] = angle[2];

				decl Float:testAngle[3];
				new Float:testDistance;
				testAngle[2] = angle[2];
				new Handle:trace;
				for(new i = 0; i < 5; i++)	//-- evaluate 5 random alternative trajectories
				{
					testAngle[0] = angle[0] + (GetURandomFloat()-0.5)*10.0;	//-- narrow vertical scan
					testAngle[1] = angle[1] + (GetURandomFloat()-0.5)*20.0;	//-- wide horizontal scan
					trace = TR_TraceRayFilterEx(position, testAngle, MASK_SHOT, RayType_Infinite, tracerayfilterdefault, entity);
					if(TR_DidHit(trace))
					{
						TR_GetEndPosition(target, trace);
						testDistance = GetVectorDistance(target, position, true);
						if (testDistance > bestDistance)
						{
							bestAngle[0] = testAngle[0];
							bestAngle[1] = testAngle[1];
							bestDistance = testDistance;
						}
					}
					CloseHandle(trace);
				}

				GetAngleVectors(bestAngle, speed, NULL_VECTOR, NULL_VECTOR);
				ScaleVector(speed, velocity);
				TeleportEntity(entity, NULL_VECTOR, bestAngle, speed);
			}
			CloseHandle(traceOne);
		}
	}
	return true;
}

findNewTarget(entity){
	
	new targetlist[MaxClients];
	new targetcount = 0;
	
	//makes list of valid client
	for(new i = 0; i < MaxClients; i++){
	
		if(isValidTarget(entity, EntIndexToEntRef(i)) && isTargetTraceable(entity, EntIndexToEntRef(i))){
		
			targetlist[targetcount] = i;
			targetcount++;
		
		}
	
	}
	
	if(targetcount != 0){
		
		decl Float:speed[3];
		GetEntPropVector(entity, Prop_Data, "m_vecVelocity", speed);
		//make list of all valid client`s distance from rocket
		new Float:distance[MaxClients];
		
		for(new i = 0; i < targetcount; i++){
		
			new Float:entorigin[3], Float:targetorigin[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entorigin);
			GetClientEyePosition(targetlist[i], targetorigin);
			//distance[i] = GetVectorDistance(entorigin, targetorigin);
			decl Float:diff[3];
			SubtractVectors(entorigin, targetorigin, diff);
			decl Float:cross[3];
			GetVectorCrossProduct( speed, diff, cross );
			distance[i] = GetVectorLength(cross);
		}
		
		//find lowest distance of that distancelist
		new Float:lowestdistance = distance[0];
		
		for(new i = 1; i < targetcount; i++){
		
			if(lowestdistance > distance[i]){
			
				lowestdistance = distance[i];
			
			}
		
		}
		
		//make list of clients that thier distance is same as lowestdistance
		//at most of time, there will actually only 1 client on this list
		new finaltargetlist[MaxClients];
		new finaltargetcount = 0;
		
		for(new i = 0; i < targetcount; i++){
		
			if(lowestdistance == distance[i]){
			
				finaltargetlist[finaltargetcount] = targetlist[i];
				finaltargetcount++;
			
			}
		
		}
		
		//get and return randome client.
		return EntIndexToEntRef(finaltargetlist[GetRandomInt(0, finaltargetcount - 1)]);
	
	}
	
	return INVALID_ENT_REFERENCE;

}

bool:isValidTarget(entity, targetentref){
	
	new target = EntRefToEntIndex(targetentref);
	
	if(isClientConnectedIngameAlive(target)){
		
		if(GetEntProp(entity, Prop_Data, "m_iTeamNum") != GetClientTeam(target)){
			
			return true;
		
		}
	
	}
	
	return false;

}

bool:isTargetTraceable(entity, targetentref){

	new target = EntRefToEntIndex(targetentref);
	
	//타겟까지 트레이스가 가능한가
	new bool:traceable = false;
	decl Float:entityposition[3];
	GetEntPropVector(entity, Prop_Send, "m_vecOrigin", entityposition);
	decl Float:clientpos[3];
	GetClientEyePosition(target, clientpos);
	if(!g_bToHead[entity]){
		
		clientpos[2] = clientpos[2] - 25.0;
		
	}
	
	new Handle:traceresult = TR_TraceRayFilterEx(entityposition, clientpos, MASK_SOLID, RayType_EndPoint, tracerayfilterdefault, entity);
	
	if(TR_GetEntityIndex(traceresult) == target){
		
		traceable = true;
		
	}
	CloseHandle(traceresult);
	
	new bool:targetvalid = false;
	
	//은폐를 사용중인가?
	if(TF2_IsPlayerInCondition(target, TFCond_Cloaked)){
	
		//보이는 상황인가?
		if(TF2_IsPlayerInCondition(target, TFCond_CloakFlicker)
			|| TF2_IsPlayerInCondition(target, TFCond_OnFire)
			|| TF2_IsPlayerInCondition(target, TFCond_Jarated)
			|| TF2_IsPlayerInCondition(target, TFCond_Milked)
			|| TF2_IsPlayerInCondition(target, TFCond_Bleeding)
			|| TF2_IsPlayerInCondition(target, TFCond_Disguising)){
			
			targetvalid = true;
			
		}else{
		
			targetvalid = false;
		
		}
	
	}else{
	
		//변장을 했고, 변장이 끝났는가?
		if(!TF2_IsPlayerInCondition(target, TFCond_Disguising) &&TF2_IsPlayerInCondition(target, TFCond_Disguised) && (GetEntProp(target, Prop_Send, "m_nDisguiseTeam") == GetEntProp(entity, Prop_Data, "m_iTeamNum"))){
		
			targetvalid = false;
		
		}else{
		
			targetvalid = true;
		
		}
	
	}
	
	return traceable && targetvalid;

}