#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>  
#pragma newdecls required

#define FilterSelf 0
#define FilterSelfAndPlayer 1
#define FilterSelfAndSurvivor 2
#define FilterSelfAndInfected 3
#define FilterSelfAndPlayerAndCI 4

ConVar l4d_tank_throw_si, l4d_tank_throw_hunter, l4d_tank_throw_smoker, l4d_tank_throw_boomer, l4d_tank_throw_charger, l4d_tank_throw_spitter, l4d_tank_throw_jockey, 
    l4d_tank_throw_tank, l4d_tank_throw_witch, l4d_tank_throw_self, l4d_tank_throw_tankhealth, l4d_tank_rock_speed;
int g_iVelocity, rock[MAXPLAYERS+1], tank = 0;
bool gamestart = false, g_bLeft4Dead2;
float throw_all[8], FrameTime=0.0, FrameDuration=0.0;

/*
	ChangeLog:
	
	1.2 (31-08-2019)
	- Full optimize
	- Changed PrecacheParticle method.
	
	1.1 (31-08-2019)
	- Code is reworked by JOSHE GATITO SPARTANSKII >>>
	
	1.0
	- Initial release 

*/

public Plugin myinfo = 
{
	name = "tank's throw special infected",
	author = "Pan Xiaohai, JOSHE GATITO SPARTANSKII >>>",
	description = "tank's throw special infected",
	version = "1.2",
	url = "<- URL ->"
}

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2) {
		g_bLeft4Dead2 = true;		
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	return APLRes_Success;
}

public void OnPluginStart()
{
	l4d_tank_throw_si = CreateConVar("l4d_tank_throw_si", "100.0", "tank throws special infected [0.0, 100.0]", FCVAR_NOTIFY);
	l4d_tank_throw_hunter 	= CreateConVar("l4d_tank_throw_hunter", "2.0", 	"[0.0, 100.0]", FCVAR_NOTIFY);
	l4d_tank_throw_smoker 	= CreateConVar("l4d_tank_throw_smoker", "5.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_boomer 	= CreateConVar("l4d_tank_throw_boomer", "5.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_charger 	= CreateConVar("l4d_tank_throw_charger", "5.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_spitter	= CreateConVar("l4d_tank_throw_spitter", "5.0", 	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_jockey	= CreateConVar("l4d_tank_throw_jockey", "2.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_tank	=	  CreateConVar("l4d_tank_throw_tank", "5.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_self	= 	  CreateConVar("l4d_tank_throw_self", "2.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);	
	l4d_tank_throw_witch =    CreateConVar("l4d_tank_throw_witch", "10.0",  	"[0.0, 10.0]", FCVAR_NOTIFY);
	l4d_tank_throw_tankhealth=CreateConVar("l4d_tank_throw_tankhealth", "1000.0",  	"", FCVAR_NOTIFY);
	l4d_tank_rock_speed 	      = CreateConVar("l4d_tank_rock_speed", "300", "trace rock 's speed", FCVAR_NOTIFY);	
	
	HookEvent("round_end", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("map_transition", RoundEnd);
	HookEvent("tank_spawn", RoundStart);
	HookEvent("ability_use", ability_use);
	
	AutoExecConfig(true, "l4d_tankhelper");
	
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	l4d_tank_throw_si.AddChangeHook(ConVarChanged);
	l4d_tank_throw_hunter.AddChangeHook(ConVarChanged);
	l4d_tank_throw_smoker.AddChangeHook(ConVarChanged);
	l4d_tank_throw_boomer.AddChangeHook(ConVarChanged);
	l4d_tank_throw_charger.AddChangeHook(ConVarChanged);
	l4d_tank_throw_spitter.AddChangeHook(ConVarChanged);
	l4d_tank_throw_jockey.AddChangeHook(ConVarChanged);
	l4d_tank_throw_tank.AddChangeHook(ConVarChanged);
	l4d_tank_throw_witch.AddChangeHook(ConVarChanged);
	
	GetConVar();
	gamestart = true;
}

public void OnMapStart()
{ 
    PrecacheParticle("electrical_arc_01_system");
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetConVar();

}
void GetConVar()
{
	
	throw_all[0]=l4d_tank_throw_hunter.FloatValue;
	throw_all[1]=throw_all[0]+l4d_tank_throw_smoker.FloatValue;
	throw_all[2]=throw_all[1]+l4d_tank_throw_boomer.FloatValue;
	throw_all[3]=throw_all[2]+l4d_tank_throw_tank.FloatValue;	
	throw_all[4]=throw_all[3]+l4d_tank_throw_self.FloatValue;
	throw_all[4]=throw_all[3]+l4d_tank_throw_witch.FloatValue;
	throw_all[5]=throw_all[4]+l4d_tank_throw_charger.FloatValue;
	throw_all[6]=throw_all[5]+l4d_tank_throw_spitter.FloatValue;
	throw_all[7]=throw_all[6]+l4d_tank_throw_jockey.FloatValue;
 
}
public void RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	gamestart = true;
	tank = 0;
}
public void RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	gamestart = false;
}
public void ability_use(Event event, const char[] name, bool dontBroadcast)
{
	char s[32];
	GetEventString(event, "ability", s, 32);
	if(StrEqual(s, "ability_throw", true))
	{	
		tank = GetClientOfUserId(GetEventInt(event, "userid"));
	}

}
public void OnEntityCreated(int entity, const char[] classname)
{
	if(!gamestart) return;
	if(tank > 0 && IsValidEdict(entity) && StrEqual(classname, "tank_rock", true) && GetEntProp(entity, Prop_Send, "m_iTeamNum") >= 0) {
		rock[tank]=entity;
		if( GetRandomFloat(0.0, 100.0) < l4d_tank_throw_si.FloatValue) { 
			int random = GetRandomInt(1, 2);
			switch (random) {
			    case 1: CreateTimer(0.01, TraceRock, tank, TIMER_REPEAT);
				case 2: CreateTimer(1.1, StartTimer, entity, TIMER_FLAG_NO_MAPCHANGE);
			}
		}
		tank=0;
	}
}
public Action TraceRock(Handle timer, any thetank)
{
	float velocity[3];
	int ent=rock[thetank];
	if(gamestart && IsValidEdict(ent))
	{	
		GetEntDataVector(ent, g_iVelocity, velocity);
		float v = GetVectorLength(velocity)
		if(v > 500.0)
		{	
			float pos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
			if(StuckCheck(ent, pos))
			{
				int si=CreateSI(thetank);
				if(si>0)
				{
					RemoveEdict(ent);
					NormalizeVector(velocity, velocity);
					float speed=GetConVarFloat(FindConVar("z_tank_throw_force"));
					ScaleVector(velocity, speed*1.4);
					TeleportEntity(si, pos, NULL_VECTOR, velocity);	
					ShowParticle(pos, "electrical_arc_01_system", 3.0);					
				}
				
			}
			return Plugin_Stop;
		}		
		 
	}
	return Plugin_Continue;
}

public Action StartTimer(Handle timer, any ent)
{ 
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{ 
		char classname[32];
		GetEdictClassname(ent, classname, sizeof(classname));
		if(StrEqual(classname, "tank_rock" ))
		{
			int team=GetEntProp(ent, Prop_Send, "m_iTeamNum");  
			if(team>=0)
			{
				StartRockTrace(ent); 
			}
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
	float time=GetEngineTime(); 
	FrameDuration=time-FrameTime; 
	FrameTime=time;
	if(FrameDuration>0.1)FrameDuration=0.1;
	if(FrameDuration==0.0)FrameDuration=0.01;
}

public void PreThink(int ent)
{
	if(ent>0 && IsValidEntity(ent) && IsValidEdict(ent)) TraceMissile(ent, FrameDuration);
	else SDKUnhook(ent, SDKHook_Think, PreThink);
}

bool StuckCheck(int ent, float pos[3])
{
	float vAngles[3], vOrigin[3];
	vAngles[2]=1.0;
	GetVectorAngles(vAngles, vAngles);
	Handle trace = TR_TraceRayFilterEx(pos, vAngles, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelf,ent);

	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(vOrigin, trace);
	 	float dis=GetVectorDistance(vOrigin, pos);
		if(dis>100.0)return true;
	}
	return false;
}

int CreateSI(int thetank)
{
	bool IsPalyerSI[MAXPLAYERS+1];
 
	int selected=0;
	for(int i = 1; i <= MaxClients; i++)
	{	
		IsPalyerSI[i]=false;
		if(IsClientInGame(i) && IsPlayerAlive(i))
		{
			if(GetClientTeam(i)==3)
			{
				IsPalyerSI[i]=true;
			}
		}		 
	}
 
	bool istank=false;
	float r=GetRandomFloat(0.0, throw_all[4]);
	if(g_bLeft4Dead2)r=GetRandomFloat(0.0, throw_all[7]);
	
	if(r<throw_all[0])
	{
		if(g_bLeft4Dead2) CheatCommand(thetank, "z_spawn_old", "hunter");
		else CheatCommand(thetank, "z_spawn", "hunter"); 		
	}
	else if(r<throw_all[1])
	{
		if(g_bLeft4Dead2) CheatCommand(thetank, "z_spawn_old", "smoker");
		else CheatCommand(thetank, "z_spawn", "smoker"); 
	}
	else if(r<throw_all[2])
	{
		if(g_bLeft4Dead2) CheatCommand(thetank, "z_spawn_old", "boomer");
		else CheatCommand(thetank, "z_spawn", "boomer");
	}
	else if(r<throw_all[3])
	{
		if(g_bLeft4Dead2) CheatCommand(thetank, "z_spawn_old", "tank");
		else CheatCommand(thetank, "z_spawn", "tank");
		istank=true;
	}
	else if(r<throw_all[4])
	{
		if(g_bLeft4Dead2) CheatCommand(thetank, "z_spawn_old", "witch");
		else CheatCommand(thetank, "z_spawn", "witch"); 
		istank=true;
	}
	else if(r<throw_all[5])
	{
		CheatCommand(thetank, "z_spawn_old", "charger"); 
	}
	else if(r<throw_all[6])
	{
		CheatCommand(thetank, "z_spawn_old", "spitter"); 
	}
	else if(r<throw_all[7])
	{
		CheatCommand(thetank, "z_spawn_old", "jockey"); 
	}
	
	if(selected==0)
	{
		int candidate[MAXPLAYERS+1];
		int index=0;
		for(int i = 1; i <= MaxClients; i++)
		{	
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==3)
			{
				if(!IsPalyerSI[i])
				{
					selected = i;
					break;
				}
				candidate[index++] = i;
			}		 
		}
		if(selected == 0 && index > 0)
		{
			selected = candidate[GetRandomInt(0, index-1)];
		}
		
	}
	if(selected > 0 && istank)
	{
		SetEntityHealth(selected, l4d_tank_throw_tankhealth.IntValue);
	}
 
 	return selected;
	
}
 
stock void CheatCommand(int client, char[] command, char[] arguments = "")
{
	int userFlags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	int flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(client, "%s %s", command, arguments);
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userFlags);
}

public void ShowParticle(float pos[3], char[] particlename, float time)
{
	int entity;
	entity = CreateEntityByName("info_particle_system");
	if( entity != -1 )
	{
		DispatchKeyValue(entity, "effect_name", particlename);
		DispatchKeyValue(entity, "targetname", "particle");
		DispatchSpawn(entity);
		ActivateEntity(entity);
		AcceptEntityInput(entity, "Start");
		TeleportEntity(entity, pos, NULL_VECTOR, NULL_VECTOR);
		SetVariantString("OnUser1 !self:Stop::0.2:1");
		AcceptEntityInput(entity, "AddOutput");
		SetVariantString("OnUser1 !self:Kill::0.3:1");
		AcceptEntityInput(entity, "AddOutput");
		AcceptEntityInput(entity, "FireUser1");
	}
}

void PrecacheParticle(const char[] sEffectName)
{
	static int table = INVALID_STRING_TABLE;

	if( table == INVALID_STRING_TABLE )
	{
		table = FindStringTable("ParticleEffectNames");
	}

	if( FindStringIndex(table, sEffectName) == INVALID_STRING_INDEX )
	{
		bool save = LockStringTables(false);
		AddToStringTable(table, sEffectName);
		LockStringTables(save);
	}
}

public bool TraceRayDontHitSelf(int entity, int mask, any data)
{
	if(entity == data) 
		return false; 
	return true;
}
 
void TraceMissile(int ent, float duration)
{
	float posmissile[3];
	float velocitymissile[3];
	
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", posmissile);
	GetEntDataVector(ent, g_iVelocity, velocitymissile);
	if(GetVectorLength(velocitymissile)<50.0)return;
	
	NormalizeVector(velocitymissile, velocitymissile);
	
	int enemyteam=2;
	
	int enemy=GetEnemy(posmissile, velocitymissile, enemyteam);
	
	float velocityenemy[3];
	float vtrace[3];
	
	vtrace[0]=vtrace[1]=vtrace[2]=0.0;
	bool visible=false;
	float missionangle[3];
	
	float disenemy=1000.0;
	
	if(enemy>0)
	{
		float posenemy[3];
		GetClientEyePosition(enemy, posenemy);
		
		disenemy=GetVectorDistance(posmissile, posenemy);
		 
		visible=IfTwoPosVisible(posmissile, posenemy, ent);
		
		GetEntDataVector(enemy, g_iVelocity, velocityenemy);

		ScaleVector(velocityenemy, duration);

		AddVectors(posenemy, velocityenemy, posenemy);
		MakeVectorFromPoints(posmissile, posenemy, vtrace);
	}
	
	////////////////////////////////////////////////////////////////////////////////////
	GetVectorAngles(velocitymissile, missionangle);

	float vleft[3];
	float vright[3];
	float vup[3];
	float vdown[3];
	float vfront[3];
	float vv1[3];
	float vv2[3];
	float vv3[3];
	float vv4[3];
	float vv5[3];
	float vv6[3];
	float vv7[3];
	float vv8[3];
	
	vfront[0]=vfront[1]=vfront[2]=0.0;
	
	float factor2=0.5; 
	float factor1=0.2; 
	float t;
	float base=1500.0;
	if(visible)
	{
		base=80.0;
	}
	{
		int flag=FilterSelfAndSurvivor;
		int self=ent;
		float front=CalRay(posmissile, missionangle, 0.0, 0.0, vfront, self, flag);

		float down=CalRay(posmissile, missionangle, 90.0, 0.0, vdown, self, flag);
		float up=CalRay(posmissile, missionangle, -90.0, 0.0, vup, self);
		float left=CalRay(posmissile, missionangle, 0.0, 90.0, vleft, self, flag);
		float right=CalRay(posmissile, missionangle, 0.0, -90.0, vright, self, flag);

		float f1=CalRay(posmissile, missionangle, 30.0, 0.0, vv1, self, flag);
		float f2=CalRay(posmissile, missionangle, 30.0, 45.0, vv2, self, flag);
		float f3=CalRay(posmissile, missionangle, 0.0, 45.0, vv3, self, flag);
		float f4=CalRay(posmissile, missionangle, -30.0, 45.0, vv4, self, flag);
		float f5=CalRay(posmissile, missionangle, -30.0, 0.0, vv5, self, flag);
		float f6=CalRay(posmissile, missionangle, -30.0, -45.0, vv6, self, flag);
		float f7=CalRay(posmissile, missionangle, 0.0, -45.0, vv7, self, flag);
		float f8=CalRay(posmissile, missionangle, 30.0, -45.0, vv8, self, flag);

		NormalizeVector(vfront,vfront);
		NormalizeVector(vup,vup);
		NormalizeVector(vdown,vdown);
		NormalizeVector(vleft,vleft);
		NormalizeVector(vright,vright);
		NormalizeVector(vtrace, vtrace);

		NormalizeVector(vv1,vv1);
		NormalizeVector(vv2,vv2);
		NormalizeVector(vv3,vv3);
		NormalizeVector(vv4,vv4);
		NormalizeVector(vv5,vv5);
		NormalizeVector(vv6,vv6);
		NormalizeVector(vv7,vv7);
		NormalizeVector(vv8,vv8);

		if(front>base) front=base;
		if(up>base) up=base;
		if(down>base) down=base;
		if(left>base) left=base;
		if(right>base) right=base;

		if(f1>base) f1=base;
		if(f2>base) f2=base;
		if(f3>base) f3=base;
		if(f4>base) f4=base;
		if(f5>base) f5=base;
		if(f6>base) f6=base;
		if(f7>base) f7=base;
		if(f8>base) f8=base;

		t=-1.0*factor1*(base-front)/base;
		ScaleVector( vfront, t);
		
		t=-1.0*factor1*(base-up)/base;
		ScaleVector( vup, t);
		
		t=-1.0*factor1*(base-down)/base;
		ScaleVector( vdown, t);
		
		t=-1.0*factor1*(base-left)/base;
		ScaleVector( vleft, t);
		
		t=-1.0*factor1*(base-right)/base;
		ScaleVector( vright, t);
		
		t=-1.0*factor1*(base-f1)/f1;
		ScaleVector( vv1, t);
		
		t=-1.0*factor1*(base-f2)/f2;
		ScaleVector( vv2, t);
		
		t=-1.0*factor1*(base-f3)/f3;
		ScaleVector( vv3, t);
		
		t=-1.0*factor1*(base-f4)/f4;
		ScaleVector( vv4, t);
		
		t=-1.0*factor1*(base-f5)/f5;
		ScaleVector( vv5, t);
		
		t=-1.0*factor1*(base-f6)/f6;
		ScaleVector( vv6, t);
		
		t=-1.0*factor1*(base-f7)/f7;
		ScaleVector( vv7, t);
		
		t=-1.0*factor1*(base-f8)/f8;
		ScaleVector( vv8, t);
		
		if(disenemy>=500.0)disenemy=500.0;
		t=1.0*factor2*(1000.0-disenemy)/500.0;
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
	}
	
	float a=GetAngle(vfront, velocitymissile);
	float amax=3.14159*duration*1.5;
	 
	if(a> amax)a=amax;
	
	ScaleVector(vfront,a);
	
	float newvelocitymissile[3];
	AddVectors(velocitymissile, vfront, newvelocitymissile);
	
	float speed = l4d_tank_rock_speed.FloatValue;
	if(speed<60.0)speed=60.0;
	NormalizeVector(newvelocitymissile, newvelocitymissile);
	ScaleVector(newvelocitymissile,speed);
	
	SetEntityGravity(ent, 0.01);
	TeleportEntity(ent, NULL_VECTOR,  NULL_VECTOR ,newvelocitymissile);
}

void CopyVector(float source[3], float target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}

int GetEnemy(float pos[3], float vec[3], int enemyteam)
{
	float min=4.0;
	float pos2[3];
	float t;
	int s=0;
	
	for(int client = 1; client <= MaxClients; client++)
	{
		bool playerok=IsClientInGame(client) && GetClientTeam(client)==enemyteam && IsPlayerAlive(client);
		
		if(playerok)
		{
			GetClientEyePosition(client, pos2);
			MakeVectorFromPoints(pos, pos2, pos2);
			t=GetAngle(vec, pos2);
			if(t<=min)
			{
				min=t;
				s=client;
			}
		}
	}
	return s;
}

bool IfTwoPosVisible(float pos1[3], float pos2[3], int self)
{
	bool r=true;
	Handle trace;
	trace=TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor,self);
	if(TR_DidHit(trace))
	{
		r=false;
	}
	CloseHandle(trace);
	return r;
}

float GetRayDistance(float pos[3], float  angle[3], int self, int flag)
{
	float hitpos[3];
	GetRayHitPos(pos, angle, hitpos, self, flag);
	return GetVectorDistance( pos,  hitpos);
}

float CalRay(float posmissile[3], float angle[3], float offset1, float offset2, float force[3], int ent, int flag = FilterSelf) 
{
	float ang[3];
	CopyVector(angle, ang);
	ang[0]+=offset1;
	ang[1]+=offset2;
	GetAngleVectors(ang, force, NULL_VECTOR,NULL_VECTOR);
	float dis=GetRayDistance(posmissile, ang, ent, flag);
	return dis;
}

float GetAngle(float x1[3], float x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}

public bool DontHitSelf(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}

public bool DontHitSelfAndPlayer(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	return true;
}

public bool DontHitSelfAndPlayerAndCI(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false;
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity))
		{
			return false;
		}
	}
	else
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			char edictname[128];
			GetEdictClassname(entity, edictname, 128);
			if(StrContains(edictname, "infected")>=0)
			{
				return false;
			}
		}
	}
	return true;
}

public bool DontHitSelfAndMissile(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity > MaxClients)
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			char edictname[128];
			GetEdictClassname(entity, edictname, 128);
			if(StrContains(edictname, "prop_dynamic")>=0)
			{
				return false;
			}
		}
	}
	return true;
}

public bool DontHitSelfAndSurvivor(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity)==2)
		{
			return false;
		}
	}
	return true;
}

public bool DontHitSelfAndInfected(int entity, int mask, any data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity>0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity)==3)
		{
			return false;
		}
	}
	return true;
}

int GetRayHitPos(float pos[3], float  angle[3], float hitpos[3], int self, int flag)
{
	Handle trace;
	int hit=0;
	if(flag==FilterSelf)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelf, self);
	}
	else if(flag==FilterSelfAndPlayer)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayer, self);
	}
	else if(flag==FilterSelfAndSurvivor)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndSurvivor, self);
	}
	else if(flag==FilterSelfAndInfected)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndInfected, self);
	}
	else if(flag==FilterSelfAndPlayerAndCI)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayerAndCI, self);
	}
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex(trace);
	}
	CloseHandle(trace);
	return hit;
}