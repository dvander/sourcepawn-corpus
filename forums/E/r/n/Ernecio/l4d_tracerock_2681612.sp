#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#pragma semicolon 1
#pragma newdecls required

#define SOUNDMISSILELOCK "UI/Beep07.wav" 

#define FilterSelf 0
#define FilterSelfAndPlayer 1
#define FilterSelfAndSurvivor 2
#define FilterSelfAndInfected 3
#define FilterSelfAndPlayerAndCI 4

ConVar hCvar_Tracerock_Enabled; 
ConVar hCvar_Tracerock_Chance;
ConVar hCvar_Tracerock_Speed;

int GameMode;
int iVelocity;

bool  bGameStarted 	= false;
float FrameTime 	= 0.0;
float FrameDuration = 0.0;
bool  ShowMsg 		= false;
float ShowTime 		= 0.0;

static bool bL4D2;

public Plugin myinfo = 
{
	name 		= "Tank's track rock",
	author 		= "Pan Xiaohai, Edited By Ernecio (Satanael)",
	description = "When the Tank throws a rock it can be remote controlled.",
	version 	= "1.2",
	url 		= "<- URL ->"
}

/**
 * Called on pre plugin start.
 *
 * @param myself        Handle to the plugin.
 * @param late          Whether or not the plugin was loaded "late" (after map load).
 * @param error         Error message buffer in case load failed.
 * @param err_max       Maximum number of characters for error message buffer.
 * @return              APLRes_Success for load success, APLRes_Failure or APLRes_SilentFailure otherwise.
 */
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion engine = GetEngineVersion();
	if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
	{
		strcopy(error, err_max, "This plugin only runs in the \"Left 4 Dead\" and \"Left 4 Dead 2\" game.");
		return APLRes_SilentFailure;
	}
	bL4D2 = (engine == Engine_Left4Dead2);
	return APLRes_Success;
}

public void OnPluginStart()
{
  	hCvar_Tracerock_Enabled = CreateConVar("l4d_tracerock_enabled", "1", 		"0 = Disabled, 1 = Enabled in coop mode, 2 = Enabled in all modes ", FCVAR_NOTIFY, true, 0.0, true, 2.0);
 	hCvar_Tracerock_Chance 	= CreateConVar("l4d_tracerock_chance", 	"30.0", 	"Remote control rock throwing probability", FCVAR_NOTIFY, true, 0.0, true, 100.0);	
	hCvar_Tracerock_Speed 	= CreateConVar("l4d_tracerock_speed", 	"300.0", 	"Speed Tank's rock", FCVAR_NOTIFY, true, 0.0, true, 950.0);
  	
	iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	if 		(StrEqual(GameName, "survival", false)) GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false)) GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false)) GameMode = 1;
	else	 GameMode = 0;
 
	HookEvent("round_start", 	Event_RoundStart, EventHookMode_Post);
	HookEvent("round_end", 		Event_RoundStart, EventHookMode_Pre);
	HookEvent("finale_win", 	Event_RoundStart);
	HookEvent("mission_lost", 	Event_RoundStart);
	HookEvent("map_transition", Event_RoundStart);
	HookEvent("ability_use", 	Event_AbilityUse);
	
	bGameStarted = false;
	
	FrameTime = GetEngineTime();
	
	AutoExecConfig(true, "l4d_tracerock"); 
}

public Action Event_RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	bGameStarted = false;
}

public Action Event_AbilityUse(Handle event, const char[] name, bool dontBroadcast)
{
	char sBuffer[32];
	GetEventString(event, "ability", sBuffer, 32);
 
	if(StrEqual(sBuffer, "ability_throw", true))
	{	
		int iMode = hCvar_Tracerock_Enabled.IntValue;
		if (iMode == 0 ) return;
		if (iMode == 1 && GameMode == 2) return;
		bGameStarted = true;
	}
	
} 

public void OnMapStart()
{
	PrecacheSound(SOUNDMISSILELOCK, true);
}
 
public void OnEntityCreated(int entity, const char[] classname)
{
	if(!bGameStarted) return; 
	
	int iMode = hCvar_Tracerock_Enabled.IntValue;
	if (iMode == 0 ) return;
	if (iMode == 1 && GameMode == 2) return;	
	if(StrEqual(classname, "tank_rock" ))
	{
		if( GetRandomFloat( 0.0, 100.0 ) < hCvar_Tracerock_Chance.FloatValue )
			CreateTimer(1.1, StartTimer, entity, TIMER_FLAG_NO_MAPCHANGE);
		
		bGameStarted = false;
	}
 
}

public Action StartTimer(Handle timer, any ent)
{ 
	if( ent > 0 && IsValidEdict(ent) && IsValidEntity(ent))
	{ 
		char classname[32];
		GetEdictClassname(ent, classname, sizeof(classname));
		if(StrEqual(classname, "tank_rock" ))
		{
			int Team = GetEntProp(ent, Prop_Send, "m_iTeamNum");  
			if( Team >= 0 ) StartRockTrace(ent);
		}
	}
}

void StartRockTrace(int ent)
{	
	SDKUnhook(ent, SDKHook_Think,  PreThink);
	SDKHook( ent, SDKHook_Think,  PreThink);  
}

public void OnGameFrame()
{	 
 	float time = GetEngineTime(); 
	FrameDuration = time - FrameTime; 
	FrameTime = time;
	if(FrameDuration > 0.1) FrameDuration = 0.1;
	if(FrameDuration == 0.0) FrameDuration = 0.01;
	if(ShowMsg)
	{
		ShowMsg = false;
		ShowTime = time;
	}
	if(time - ShowTime > 1.0 )
	{
		ShowMsg = true;
	}
}

public void PreThink(int ent)
{
	if(ent > 0 && IsValidEntity(ent) && IsValidEdict(ent)) 
		TraceMissile(ent, FrameDuration );  
	else 
		SDKUnhook(ent, SDKHook_Think,  PreThink);
}
 
void TraceMissile( int ent, float duration )
{
	float MissilePosition[3];
	float MissileVelocity[3];	
	
	GetEntPropVector( ent, Prop_Send, "m_vecOrigin", MissilePosition );	
	GetEntDataVector( ent, iVelocity, MissileVelocity );
	if( GetVectorLength( MissileVelocity ) < 50.0 ) return;
	
	NormalizeVector( MissileVelocity, MissileVelocity );
	
 	int EnemyClient = GetEnemy( MissilePosition, MissileVelocity );
	
	float velocityenemy[3];
	float vtrace[3];
	
	vtrace[0] = vtrace[1] = vtrace[2] = 0.0;
	
	bool  bVisible = false;
 
	float ENEMY_DISTANCE = 1000.0;
	
	if( EnemyClient > 0 )	
	{
		float Objective[3];
		GetClientEyePosition(EnemyClient, Objective);
		
		ENEMY_DISTANCE = GetVectorDistance(MissilePosition, Objective);
		bVisible = IfTwoPosVisible(MissilePosition, Objective, ent);
		
		GetEntDataVector(EnemyClient, iVelocity, velocityenemy);
		ScaleVector(velocityenemy, duration);
		AddVectors(Objective, velocityenemy, Objective);
		MakeVectorFromPoints(MissilePosition, Objective, vtrace);
		
		if ( ShowMsg )
		{
			if(EnemyClient > 0 && IsClientInGame(EnemyClient) && IsPlayerAlive(EnemyClient))
			{
				PrintHintText( EnemyClient, "Warning! Your are locked by Tank's rock, Distance: %d", RoundFloat( ENEMY_DISTANCE ) );
				EmitSoundToClient( EnemyClient, SOUNDMISSILELOCK );
			} 
		}
	}
	
	float vleft[3], vright[3], vup[3], vdown[3], vfront[3], vv1[3], vv2[3], vv3[3], vv4[3], vv5[3], vv6[3], vv7[3], vv8[3];	
	
	vfront[0] = vfront[1] = vfront[2] = 0.0;
	
	float factor2 = 0.5; 
	float factor1 = 0.2; 
	float t;
	float MissionAngle[3];
	float base = 1500.0;
	if ( bVisible ) base = 80.0;
	
	int flag = FilterSelfAndSurvivor;
	int self = ent;
	
	GetVectorAngles(MissileVelocity, MissionAngle);
	
	float front = CalRay(MissilePosition, MissionAngle, 0.0, 0.0, vfront, self, flag);
	float down 	= CalRay(MissilePosition, MissionAngle, 90.0, 0.0, vdown, self, flag);
	float up 	= CalRay(MissilePosition, MissionAngle, -90.0, 0.0, vup, self);
	float left 	= CalRay(MissilePosition, MissionAngle, 0.0, 90.0, vleft, self, flag);
	float right = CalRay(MissilePosition, MissionAngle, 0.0, -90.0, vright, self, flag);
	
	float f1 = CalRay(MissilePosition, MissionAngle, 30.0, 0.0, vv1, self, flag);
	float f2 = CalRay(MissilePosition, MissionAngle, 30.0, 45.0, vv2, self, flag);
	float f3 = CalRay(MissilePosition, MissionAngle, 0.0, 45.0, vv3, self, flag);
	float f4 = CalRay(MissilePosition, MissionAngle, -30.0, 45.0, vv4, self, flag);
	float f5 = CalRay(MissilePosition, MissionAngle, -30.0, 0.0, vv5, self, flag);
	float f6 = CalRay(MissilePosition, MissionAngle, -30.0, -45.0, vv6, self, flag);	
	float f7 = CalRay(MissilePosition, MissionAngle, 0.0, -45.0, vv7, self, flag);
	float f8 = CalRay(MissilePosition, MissionAngle, 30.0, -45.0, vv8, self, flag);
	
	NormalizeVector(vfront, vfront);
	NormalizeVector(vup, vup);
	NormalizeVector(vdown, vdown);
	NormalizeVector(vleft, vleft);
	NormalizeVector(vright, vright);
	NormalizeVector(vtrace, vtrace);

	NormalizeVector(vv1, vv1);
	NormalizeVector(vv2, vv2);
	NormalizeVector(vv3, vv3);
	NormalizeVector(vv4, vv4);
	NormalizeVector(vv5, vv5);
	NormalizeVector(vv6, vv6);
	NormalizeVector(vv7, vv7);
	NormalizeVector(vv8, vv8);
	
	if(front > base) front 	= base;
	if(up 	> base) up 		= base;
	if(down > base) down 	= base;
	if(left > base) left 	= base;
	if(right > base) right 	= base;
	
	if(f1 > base) f1 = base;	
	if(f2 > base) f2 = base;	
	if(f3 > base) f3 = base;	
	if(f4 > base) f4 = base;	
	if(f5 > base) f5 = base;	
	if(f6 > base) f6 = base;	
	if(f7 > base) f7 = base;	
	if(f8 > base) f8 = base;	
	
	t =- 1.0 * factor1 * (base - front) / base;
	ScaleVector( vfront, t);
	t =- 1.0 * factor1 * (base - up) / base;
	ScaleVector( vup, t);
	t =- 1.0 * factor1 * (base - down) / base;
	ScaleVector( vdown, t);
	t =- 1.0 * factor1 * (base - left) / base;
	ScaleVector( vleft, t);
	t =- 1.0 * factor1 * ( base - right) / base;
	ScaleVector( vright, t);
	t =- 1.0 * factor1 * (base - f1) / f1;
	ScaleVector( vv1, t);
	t =- 1.0 * factor1 * (base - f2) / f2;
	ScaleVector( vv2, t);
	t =- 1.0 * factor1 * (base - f3) / f3;
	ScaleVector( vv3, t);
	t =- 1.0 * factor1 * (base - f4) / f4;
	ScaleVector( vv4, t);
	t =- 1.0 * factor1 * (base - f5) / f5;
	ScaleVector( vv5, t);
	t =- 1.0 * factor1 * (base - f6) / f6;
	ScaleVector( vv6, t);
	t =- 1.0 * factor1 * (base - f7) / f7;
	ScaleVector( vv7, t);
	t =- 1.0 * factor1 * (base - f8) / f8;
	ScaleVector( vv8, t);
	
	if ( ENEMY_DISTANCE >= 500.0 ) ENEMY_DISTANCE = 500.0;
	t = 1.0 * factor2 * ( 1000.0 - ENEMY_DISTANCE ) / 500.0;
	ScaleVector( vtrace, t);							

	AddVectors(vfront, vup, vfront);
	AddVectors(vfront, vdown, vfront);
	AddVectors(vfront, vleft, vfront);
	AddVectors(vfront, vright, vfront);
	AddVectors(vfront, vv1, vfront);
	AddVectors(vfront, vv2, vfront);
	AddVectors(vfront, vv3, vfront);
	AddVectors(vfront, vv4, vfront);
	AddVectors(vfront, vv5, vfront);
	AddVectors(vfront, vv6, vfront);
	AddVectors(vfront, vv7, vfront);
	AddVectors(vfront, vv8, vfront);
	AddVectors(vfront, vtrace, vfront);	
	NormalizeVector(vfront, vfront);
	
	float vAngle = GetAngle(vfront, MissileVelocity);			 
	float vAngleMax = 3.14159 * duration * 1.5;
	
	if( vAngle > vAngleMax ) vAngle = vAngleMax;
	
	ScaleVector( vfront, vAngle );
	
	float NewMissileVelocity[3];
	AddVectors(MissileVelocity, vfront, NewMissileVelocity);
	
	float fSpeed = hCvar_Tracerock_Speed.FloatValue;
	if(fSpeed < 60.0) fSpeed = 60.0;
	NormalizeVector(NewMissileVelocity, NewMissileVelocity);
	ScaleVector(NewMissileVelocity, fSpeed);   
	
	SetEntityGravity(ent, 0.01);
	TeleportEntity(ent, NULL_VECTOR, NULL_VECTOR, NewMissileVelocity);
	
	if ( bL4D2 ) SetEntProp(ent, Prop_Send, "m_iGlowType", 3 ); //3
	if ( bL4D2 ) SetEntProp(ent, Prop_Send, "m_nGlowRange", 0 ); //0
	if ( bL4D2 ) SetEntProp(ent, Prop_Send, "m_glowColorOverride", 11111); //1
}

/**
 *	Validates if the client is valid.
 *
 * @param vPos				The vector for origin of client.
 * @param vlAngles			The vector for angle of client.
 **/
int GetEnemy( float vPos[3], float vAngles[3] )
{
	float vMinAngle = 4.0;
	float vPosition[3];
	int   iClientIndex = 0;
	
	for( int client = 1; client <= MaxClients; client ++ )
	{
		if( IsClientInGame( client ) && GetClientTeam( client ) == 2 && IsPlayerAlive( client ) )
		{
			GetClientEyePosition( client, vPosition );
			MakeVectorFromPoints( vPos, vPosition, vPosition );
			if( GetAngle( vAngles, vPosition ) <= vMinAngle )
			{
				vMinAngle = GetAngle( vAngles, vPosition );
				iClientIndex = client;
			}
		}
	}
	return iClientIndex;
}

void CopyVector(float source[3], float target[3])
{
	target[0] = source[0];
	target[1] = source[1];
	target[2] = source[2];
}

bool IfTwoPosVisible( float vAngles[3], float vOrigins[3], int iSelf )
{
	bool bR = true;
	Handle trace = TR_TraceRayFilterEx( vOrigins, vAngles, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor, iSelf );
	if ( TR_DidHit( trace ) ) bR = false;
	
 	CloseHandle( trace );
	return bR;
}

float CalRay(float MissilePosition[3], float vAngle[3], float Offset1, float Offset2, float Force[3], int Ent, int Flag = FilterSelf) 
{
	float vAng[3];
	CopyVector(vAngle, vAng);
	vAng[0] += Offset1;
	vAng[1] += Offset2;
	GetAngleVectors(vAng, Force, NULL_VECTOR,NULL_VECTOR);
	float Distance = GetRayDistance(MissilePosition, vAng, Ent, Flag);
	return Distance;
}

float GetAngle(float x1[3], float x2[3])
{
	return ArcCosine( GetVectorDotProduct( x1, x2 ) / ( GetVectorLength( x1 ) * GetVectorLength( x2 ) ) );
}

public bool DontHitSelf(int entity, int mask, any data)
{
	if(entity == data) return false; 
	return true;
}

public bool DontHitSelfAndPlayer(int entity, int mask, any data)
{
	if(entity == data) return false; 
	else if( entity > 0 && entity <= MaxClients ) 
		if ( IsClientInGame(entity) ) 
			return false;
	return true;
}

public bool DontHitSelfAndPlayerAndCI(int entity, int mask, any data)
{
	if(entity == data) return false;
	else if( entity > 0 && entity <= MaxClients ){ 
		if ( IsClientInGame( entity) ){ 
			return false;
		}
	}
	else
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			char edictname[128];
			GetEdictClassname(entity, edictname, 128);
			if(StrContains(edictname, "infected") >= 0) 
				return false;
		}
	}
	return true;
}

public bool DontHitSelfAndMissile(int entity, int mask, any data)
{
	if(entity == data) return false;
	else if(entity > MaxClients)
	{
		if( IsValidEntity(entity) && IsValidEdict(entity) )
		{
			char edictname[128];
			GetEdictClassname(entity, edictname, 128);
			if(StrContains(edictname, "prop_dynamic") >= 0 ) 
				return false;
		}
	}
	return true;
}

public bool DontHitSelfAndSurvivor(int entity, int mask, any data)
{
	if(entity == data) return false;
	else if(entity > 0 && entity <= MaxClients) if(IsClientInGame(entity) && GetClientTeam(entity) == 2 ) 
		return false;
	return true;
}

public bool DontHitSelfAndInfected(int entity, int mask, any data)
{
	if(entity == data) return false; 
	else if(entity > 0 && entity <= MaxClients) if(IsClientInGame(entity) && GetClientTeam(entity) == 3 ) 
		return false;
	return true;
}

float GetRayDistance(float pos[3], float angle[3], int self, int flag)
{
	float hitpos[3];
	GetRayHitPos(pos, angle, hitpos, self, flag);
	return GetVectorDistance( pos,  hitpos);
}

int GetRayHitPos(float pos[3], float angle[3], float hitpos[3], int self, int flag)
{
	Handle trace;
	int hit = 0;
	
	if(flag == FilterSelf) 						trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelf, self);
	else if (flag == FilterSelfAndPlayer) 		trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayer, self);
	else if (flag == FilterSelfAndSurvivor) 	trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndSurvivor, self);
	else if (flag == FilterSelfAndInfected) 	trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndInfected, self);
	else if (flag == FilterSelfAndPlayerAndCI) 	trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayerAndCI, self);
	if(TR_DidHit(trace))
	{	
		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex( trace);
	}
	CloseHandle(trace);
	return hit;
}