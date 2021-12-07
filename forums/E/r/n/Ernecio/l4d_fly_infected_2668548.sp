#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>

#pragma newdecls required
#pragma semicolon 1

#define SOUNDMISSILELOCK "UI/Beep07.wav" 
#define OXYGENTANK "models/props_equipment/oxygentank01.mdl"

#define FilterSelf 0
#define FilterSelfAndPlayer 1
#define FilterSelfAndSurvivor 2
#define FilterSelfAndInfected 3
#define FilterSelfAndPlayerAndCI 4

#define SurvivorTeam 2
#define InfectedTeam 3
#define MissileTeam 1 

#define State_None 0
#define State_Start 1
#define State_Fly 2
 
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

int ZOMBIECLASS_TANK = 5;
 
int JetPack[MAXPLAYERS+1][2];
int ClientState[MAXPLAYERS+1];
int LastButton[MAXPLAYERS+1];
int Enemy[MAXPLAYERS+1];
int Clone[MAXPLAYERS+1];

float ClientVelocity[MAXPLAYERS+1][3];
float LastTime[MAXPLAYERS+1]; 
float LastPos[MAXPLAYERS+1][3]; 
float FireTime[MAXPLAYERS+1]; 
float StartTime[MAXPLAYERS+1];
float ScanTime[MAXPLAYERS+1];

int GameMode;
int g_iVelocity;
static bool L4D2Version;

public Plugin myinfo = 
{
	name 		= "{L4D1 AND L4D2} Fly Infected",
	author 		= "Pan Xiaohai, Editado por Ernecio",
	description = "Otorga la habilidad de volar al Tank",
	version 	= "1.5",
	url 		= "<- URL ->"
}

Handle hCvar_Flyinfected_enable ; 
Handle hCvar_Flyinfected_chance_throw;
Handle hCvar_Flyinfected_chance_tankclaw;
Handle hCvar_Flyinfected_chance_tankjump;
Handle hCvar_Flyinfected_speed; 
Handle hCvar_Flyinfected_maxtime; 

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in the \"Left 4 Dead\" and \"Left 4 Dead 2\" game.");
        return APLRes_SilentFailure;
    }

    L4D2Version = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}
 
public void OnPluginStart()
{
	GameCheck();
  	hCvar_Flyinfected_enable 			= CreateConVar("l4d_flyinfected_enable", 			"1", 	"0 = Deshabilitar Plugin.\n1 = Habilitar plugin solo modo cooperativo.\n2 = Habilitar plugin en todos los modos de juego. ", FCVAR_NOTIFY, true, 0.0, true, 2.0);
 
	hCvar_Flyinfected_chance_throw 		= CreateConVar("l4d_flyinfected_chance_throw", 		"30.0", "Probavilidad de volar cuando el Tank arroja una roca.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
 	hCvar_Flyinfected_chance_tankclaw 	= CreateConVar("l4d_flyinfected_chance_tankclaw", 	"10", 	"Probabilidad de volar cuando el Tank da un golpe.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
 	hCvar_Flyinfected_chance_tankjump 	= CreateConVar("l4d_flyinfected_chance_tankjump", 	"20", 	"Probabilidad de volar cuando el Tank salta.", FCVAR_NOTIFY, true, 0.0, true, 100.0);
	
	hCvar_Flyinfected_speed 			= CreateConVar("l4d_flyinfected_speed", 			"300", 	"Velocidad en vuelo del Tank", FCVAR_NOTIFY, true, 0.0, true, 450.0);
 	hCvar_Flyinfected_maxtime 			= CreateConVar("l4d_flyinfected_maxtime", 			"10", 	"Tiempo maximo de vuelo.", FCVAR_NOTIFY, true, 0.0, true, 100.0);	
	
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	AutoExecConfig(true, "l4d_fly_infected"); 
 
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundStart);
	HookEvent("finale_win", RoundStart);
	HookEvent("mission_lost", RoundStart);
	HookEvent("map_transition", RoundStart);	
 
	HookEvent("ability_use", ability_use);
	HookEvent("weapon_fire", weapon_fire);
	HookEvent("player_jump", player_jump);
	
	HookEvent("player_hurt", player_hurt);
	HookEvent("player_death", player_death);
	
 	SetRandomSeed(GetSysTickCount()); 
}

public void OnMapStart()
{
	PrecacheSound(SOUNDMISSILELOCK, true);
	PrecacheModel(OXYGENTANK); // DispatchKeyValue(jetpack, "model", "models/props_equipment/oxygentank01.mdl");  
}

public Action RoundStart(Handle event, const char[] name, bool dontBroadcast)
{
	for(int i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			ClientState[i]=State_None;
			FireTime[i]=0.0;
			JetPack[i][0]=JetPack[i][1]=0;
			Clone[i]=0;
			SDKUnhook(i, SDKHook_PreThink,  PreThink); 
			SDKUnhook(i, SDKHook_StartTouch , FlyTouch);
		}
	} 
}
bool CanUse()
{
	int mode = GetConVarInt(hCvar_Flyinfected_enable);
	if(mode == 0)return false;
	if(mode == 1 && GameMode == 2) return false;
	return true;
}
public Action weapon_fire(Handle event, const char[] name, bool dontBroadcast)
{
	if(!CanUse())return;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client > 0)
	{
		if(GetClientTeam(client )== 3 && IsInfected(client, ZOMBIECLASS_TANK))
		{   
			float time=GetEngineTime();
			if(FireTime[client] +1.0 < time)
			{
				FireTime[client]=time;
			}
			else return;
			//PrintToChatAll("---------Fire------------");
			if(ClientState[client]==State_None)
			{
				float r = GetRandomFloat(0.0, 100.0); 
				if(r < GetConVarFloat(hCvar_Flyinfected_chance_tankclaw))
				{ 
					//PrintToChatAll("Start by Tank Fire");
					ClientState[client] = State_Start;
					CreateTimer(3.0, StartTimer, client, TIMER_FLAG_NO_MAPCHANGE);
				}
			}
			else if(ClientState[client] == State_Fly)
			{
				//StopFly(client);
			}
		}
	}
	return ;
}

public Action player_hurt(Handle event, const char[] name, bool dontBroadcast)
{
	if(!CanUse())return;
 	int  attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker > 0 && ClientState[attacker] == State_Fly)
	{
		char s[32];	
		GetEventString(event, "weapon", s, 32);
		//PrintToChatAll("weapon %s", s);	
	 	if(StrEqual(s, "tank_claw", true))
		{
			//PrintToChatAll("Stop by Hurt");
			StopFly(attacker);
		}
	}
	return;
}

public Action player_jump(Handle hEvent, const char[] strName, bool DontBroadcast)
{
	if(!CanUse())return;
	int client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	
	if(client > 0 && GetClientTeam(client) == 3 && IsInfected(client, ZOMBIECLASS_TANK) && ClientState[client] == State_None)
	{ 	
		float r = GetRandomFloat(0.0, 100.0); 
		if(r < GetConVarFloat(hCvar_Flyinfected_chance_tankjump))
		{ 
			//PrintToChatAll("Start by Jump");
			ClientState[client] = State_Start;
			StartTimer(INVALID_HANDLE, client);
		}
	}
}

public Action player_death(Handle hEvent, const char[] strName, bool DontBroadcast)
{
	if(!CanUse())return;
	int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));  

	if(victim > 0 && ClientState[victim] == State_Fly)
	{ 	
		StopFly(victim); 
	}
}

public Action ability_use(Handle event, const char[] name, bool dontBroadcast)
{	
	if(!CanUse())return;
	int client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(ClientState[client]==State_None) 
	{
		char s[32];	
		GetEventString(event, "ability", s, 32);
		if(StrEqual(s, "ability_throw", true))
		{	 
			float r = GetRandomFloat(0.0, 100.0); 
			if(r < GetConVarFloat(hCvar_Flyinfected_chance_throw))
			{ 
				//PrintToChatAll("Start by Throw");
				ClientState[client] = State_Start;
				CreateTimer(3.0, StartTimer, client, TIMER_FLAG_NO_MAPCHANGE);
			}

		}
	}
	
} 

public Action StartTimer(Handle timer, any client)
{ 
	if(client > 0 && ClientState[client]!= State_Fly && IsClientInGame(client) && IsPlayerAlive(client) && IsInfected(client, ZOMBIECLASS_TANK) )
	{ 
		StartFly(client); 	 
	}
	if(ClientState[client]!= State_Fly) ClientState[client] = State_None;
}

void StartFly(int client)
{   
	if(ClientState[client]==State_Fly)StopFly(client);
	ClientState[client]=State_None;

	float pos[3], hitpos[3], ang[3];
	ang[0] =- 89.0;
	GetClientEyePosition(client, pos);
	Handle trace = TR_TraceRayFilterEx(pos, ang, MASK_ALL, RayType_Infinite, DontHitSelf, client);
	bool narrow = false;
 
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace); 
		if(GetVectorDistance(hitpos, pos) < 100.0)
		{ 
			narrow = true;
			PrintCenterText(client, "It is too narrow");
		}
	}
 	CloseHandle(trace);
	if(narrow)return; 
	ClientState[client]=State_Fly;
	float vec[3];
	GetEntPropVector(client, Prop_Send, "m_vecOrigin", pos);
	pos[2]+=5.0;
	GetClientEyeAngles(client,vec);
	GetAngleVectors(vec, vec, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vec , vec);
	ScaleVector(vec, 55.0);
	vec[2]=30.0; 
	TeleportEntity(client, pos, NULL_VECTOR, vec);
	CopyVector(pos, LastPos[client]);
	CopyVector(vec, ClientVelocity[client]);
	
	LastTime[client]=GetEngineTime()-0.01;
	StartTime[client]=GetEngineTime();
	ScanTime[client]=GetEngineTime()-0.0;
	LastButton[client]=IN_JUMP;
	Enemy[client]=0;
	
	SDKUnhook(client, SDKHook_PreThink,  PreThink);
	SDKHook( client, SDKHook_PreThink,  PreThink);  
	SDKUnhook(client, SDKHook_StartTouch , FlyTouch);
	SDKHook(client, SDKHook_StartTouch , FlyTouch);
 	
	Clone[client]=0;
	int jetpackb1=CreateJetPackB1(client);
	int jetpackb2=CreateJetPackB2(client);  
	JetPack[client][0]=jetpackb1;
	JetPack[client][1]=jetpackb2; 
	AttachFlame(client, jetpackb1 );
	AttachFlame(client, jetpackb2 );
	
	if(L4D2Version)
	{
		SetEntProp(client, Prop_Send, "m_iGlowType", 3 ); //3
		SetEntProp(client, Prop_Send, "m_nGlowRange", 0 ); //0
		SetEntProp(client, Prop_Send, "m_glowColorOverride", 256*100); //1	
	}
} 
/*
// =====|	Esta parte del plugin esta como nota debido a que genera conflictos de 
// =====|	RenderColor con otros plugins, pero el plugin funciona bien omitiendo esta parte.
// =====|	
	
void VisiblePlayer(int client, bool visible = true)
{
	if(visible)
	{
		SetEntityRenderMode(client, RENDER_NORMAL);
		SetEntityRenderColor(client, 255, 255, 255, 255);		 
	}
	else
	{
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		SetEntityRenderColor(client, 0, 0, 0, 0);
	} 
}
*/
void StopFly(int client)
{  
	if(ClientState[client] != State_Fly) return;
	
	ClientState[client] = State_None;
	SDKUnhook(client, SDKHook_PreThink,  PreThink); 
	SDKUnhook(client, SDKHook_StartTouch , FlyTouch);
	int jet0 = JetPack[client][0];
	int jet1 = JetPack[client][1];
	int  clone = Clone[client];
	Clone[client] = JetPack[client][0] = JetPack[client][1] = 0;	
	
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client) && IsInfected(client, ZOMBIECLASS_TANK))
	{
		SetEntityGravity(client, 1.0);
//		VisiblePlayer(client, true); 		// ====| Sí remueves las notas no olvides estas sección. |===== //
		if(L4D2Version)
		{
			SetEntProp(client, Prop_Send, "m_iGlowType", 0 ); // 3
			SetEntProp(client, Prop_Send, "m_nGlowRange", 0 ); // 0
			SetEntProp(client, Prop_Send, "m_glowColorOverride", 0 ); // 1	
		}
	}

	if(jet0 > 0 && IsValidEdict(jet0) && IsValidEntity(jet0) )  // Remove dummy body
	{
		AcceptEntityInput(jet0, "ClearParent");
		AcceptEntityInput(jet0, "kill"); 
	}
	if(jet1 > 0 && IsValidEdict(jet1) && IsValidEntity(jet1) )  // Remove dummy body
	{
		AcceptEntityInput(jet1, "ClearParent");
		AcceptEntityInput(jet1, "kill"); 
	}	 
	if(clone > 0 && IsValidEdict(clone) && IsValidEntity(clone) )  // Remove dummy body
	{
		AcceptEntityInput(clone, "ClearParent");
		AcceptEntityInput(clone, "kill"); 
	}
	
}

int IsInfected(int client, int type)
{
	int class = GetEntProp(client, Prop_Send, "m_zombieClass");
	if(type == class)return true;
	else return false;
}
 
public void FlyTouch(int ent, int other)
{
	StopFly(ent); 
}
public void PreThink(int client)
{
	if(client > 0 && IsClientInGame(client) && IsPlayerAlive(client))
	{ 
		float time=GetEngineTime( );
		float intervual=time-LastTime[client]; 
		int button = GetClientButtons(client);  
		TraceFly(client, button, time, intervual );  
		LastTime[client]=time; 
		LastButton[client]=button;	 
		 
	}
	else
	{
		SDKUnhook(client, SDKHook_PreThink,  PreThink);
	}

}
 
 
void TraceFly(int ent, int button, float time, float duration)
{
	if(time - StartTime[ent] > GetConVarFloat(hCvar_Flyinfected_maxtime))
	{
		StopFly(ent);
		return;
	}
	 
	float posmissile[3], velocitymissile[3];
	
	GetClientAbsOrigin(ent, posmissile); 
	posmissile[2] += 30.0;
	GetEntDataVector(ent, g_iVelocity, velocitymissile);
	bool fake=IsFakeClient(ent);
	if(!fake && (button & IN_JUMP) && !(LastButton[ent] & IN_JUMP))
	{
	 
	 
		GetClientEyeAngles(ent, velocitymissile);
		GetAngleVectors(velocitymissile, velocitymissile, NULL_VECTOR, NULL_VECTOR);
		velocitymissile[2]=0.0;
		NormalizeVector(velocitymissile, velocitymissile);
		ScaleVector(velocitymissile, 310.0);
		velocitymissile[2]=150.0;
		TeleportEntity(ent, NULL_VECTOR,NULL_VECTOR, velocitymissile);
		StopFly(ent);
		return;
	}
	CopyVector(ClientVelocity[ent], velocitymissile);	
	if(GetVectorLength(velocitymissile) < 10.0) return ;
	NormalizeVector(velocitymissile, velocitymissile);
	
	//ShowDir(0, posmissile, velocitymissile, 0.06);
	int enemyteam = 2;
 	int enemy=Enemy[ent];
	if(ScanTime[ent] + 1.0 <= time)
	{
		ScanTime[ent]=time;
		if(fake)enemy=GetEnemy(posmissile, velocitymissile, enemyteam);
		else 
		{
			float lookdir[3];
			GetClientEyeAngles(ent, lookdir);
			GetAngleVectors(lookdir, lookdir, NULL_VECTOR, NULL_VECTOR); 
			NormalizeVector(lookdir, lookdir);
			//ScaleVector(lookdir, 310.0);
			enemy=GetEnemy(posmissile, lookdir, enemyteam);
		}
		//PrintToChatAll("scan %f %N", time, enemy);
	}
	if(enemy > 0 && IsClientInGame(enemy) && IsPlayerAlive(enemy))
	{
		Enemy[ent]=enemy;
	}
	else
	{
		enemy = 0;
		Enemy[ent] = enemy;
	}
	
	float velocityenemy[3], vtrace[3];
	
	vtrace[0] = vtrace[1] = vtrace[2] = 0.0;	
	bool visible=false;
	float missionangle[3];
 
	float disenemy = 1000.0;
	if(enemy > 0)	
	{
		float posenemy[3];
		GetClientEyePosition(enemy, posenemy);
		
		disenemy = GetVectorDistance(posmissile, posenemy);
		
		visible = IfTwoPosVisible(posmissile, posenemy, ent);
		
		//if(visible)PrintToChatAll("%N visible %f ", client, disenemy);	
		GetEntDataVector(enemy, g_iVelocity, velocityenemy);
 
		ScaleVector(velocityenemy, duration);

		AddVectors(posenemy, velocityenemy, posenemy);
		MakeVectorFromPoints(posmissile, posenemy, vtrace);
		//PrintToChatAll("%N lock %N D:%f", client,enemy, disenemy); 
		
		if(enemy > 0 && IsClientInGame(enemy) && IsPlayerAlive(enemy))
		{
			PrintHintText(enemy, "Warning! Your are locked by flying tank, Distance: %d", RoundFloat(disenemy) );
			EmitSoundToClient(enemy, SOUNDMISSILELOCK);
		}
	} 
	
	GetVectorAngles(velocitymissile, missionangle);
	
	float vleft[3], vright[3], vup[3], vdown[3], vfront[3], vv1[3], vv2[3], vv3[3], vv4[3], vv5[3], vv6[3], vv7[3], vv8[3];	
	
	vfront[0] = vfront[1] = vfront[2 ]=0.0;	
	
	float factor2 = 0.5; 
	float factor1 = 0.2; 
	float t;
	float base = 1500.0;
	
	if(visible)
	{
		base = 80.0;
 
	}
	
	{
		//PrintToChatAll("%f %f %f %f %f",front, up, down, left, right);
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
		
		float b2=10.0;
		if(front<b2) front=b2;
		if(up<b2) up=b2;
		if(down<b2) down=b2;
		if(left<b2) left=b2;
		if(right<b2) right=b2;
		if(f1<b2) f1=b2;	
		if(f2<b2) f2=b2;	
		if(f3<b2) f3=b2;	
		if(f4<b2) f4=b2;	
		if(f5<b2) f5=b2;	
		if(f6<b2) f6=b2;	
		if(f7<b2) f7=b2;	
		if(f8<b2) f8=b2;		
 
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
		ScaleVector(vtrace, t);		

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
	
	float a = GetAngle(vfront, velocitymissile);			 
	float amax=3.14159 * duration * 2.0;
	 
	if(a > amax )a = amax;
	
	ScaleVector(vfront ,a);
	
	//PrintToChat(client, "max %f %f  ",amax , a);
	float newvelocitymissile[3];
	AddVectors(velocitymissile, vfront, newvelocitymissile);
	
	float speed=GetConVarFloat(hCvar_Flyinfected_speed);
	if(speed < 60.0) speed = 60.0;
	NormalizeVector(newvelocitymissile, newvelocitymissile);
	ScaleVector(newvelocitymissile,speed);   
	
	SetEntityGravity(ent, 0.01);
	
	TeleportEntity(ent, NULL_VECTOR,  NULL_VECTOR ,newvelocitymissile); 
	CopyVector(newvelocitymissile, ClientVelocity[ent]);
 	//ShowDir(0, posmissile, newvelocitymissile, 0.06); 
}

int GetEnemy(float pos[3], float vec[3], int enemyteam)
{
	float min = 4.0;
	float pos2[3];
	float t;
	int s = 0;
	
	for(int client = 1; client <= MaxClients; client++)
	{
		bool playerok = IsClientInGame(client) && GetClientTeam(client) == enemyteam && IsPlayerAlive(client);
		if(playerok )
		{
			GetClientEyePosition(client, pos2);
			MakeVectorFromPoints(pos, pos2, pos2);
			t = GetAngle(vec, pos2);
			//PrintToChatAll("%N %f", client, 360.0*t/3.1415926/2.0);
			if(t <= min)
			{
				min = t;
				s = client;
			}
		}
	}
	return s;
}
void CopyVector(float source[3], float target[3])
{
	target[0] = source[0];
	target[1] = source[1];
	target[2] = source[2];
}
void SetVector(float target[3], float x, float y, float z)
{
	target[0] = x;
	target[1] = y;
	target[2] = z;
}
bool IfTwoPosVisible(float pos1[3], float pos2[3], int self )
{
	bool r = true;
	Handle trace ;
	trace = TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor, self);
	if(TR_DidHit(trace))
	{
		r=false;
	}
 	CloseHandle(trace);
	return r;
}

float CalRay(float posmissile[3], float angle[3], float offset1, float offset2, float force[3], int ent, int flag = FilterSelf)
{
	float ang[3];
	CopyVector(angle, ang);
	ang[0]+=offset1;
	ang[1]+=offset2;
	GetAngleVectors(ang, force, NULL_VECTOR,NULL_VECTOR);
	float dis=GetRayDistance(posmissile, ang, ent, flag) ; 
	//PrintToChatAll("%f %f, %f", dis, offset1, offset2);
	return dis;
}

float GetAngle(float x1[3], float x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2) / (GetVectorLength(x1) * GetVectorLength(x2)));
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
	else if(entity > 0 && entity <= MaxClients)
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
	else if(entity > 0 && entity <= MaxClients)
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
			if(StrContains(edictname, "infected") >=0 )
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
			if(StrContains(edictname, "prop_dynamic") >= 0)
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
	else if(entity > 0 && entity<=MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity) == 2)
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
	else if(entity > 0 && entity <= MaxClients)
	{
		if(IsClientInGame(entity) && GetClientTeam(entity) == 3)
		{
			return false;
		}
	}
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
	Handle trace ;
	int hit = 0;
	if(flag == FilterSelf)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelf, self);
	}
	else if(flag == FilterSelfAndPlayer)
	{
		trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayer, self);
	}
	else if(flag == FilterSelfAndSurvivor)
	{
		trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndSurvivor, self);
	}
	else if(flag == FilterSelfAndInfected)
	{
		trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndInfected, self);
	}
	else if(flag == FilterSelfAndPlayerAndCI)
	{
		trace = TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, DontHitSelfAndPlayerAndCI, self);
	}
	if(TR_DidHit(trace))
	{	
		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex( trace);
	}
	CloseHandle(trace);
	return hit;
}

void GameCheck()
{
	char GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	if (StrEqual(GameName, "survival", false))
	{
		GameMode = 3;
	}
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
	{
		GameMode = 2;
	}
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
	{
		GameMode = 1;
	}
	else
	{
		GameMode = 0;
 	}
	
	if (L4D2Version)
	{
		ZOMBIECLASS_TANK = 8;
	}	
	else
	{
		ZOMBIECLASS_TANK = 5;
	}
}

int CreateJetPackB1(int client)
{
	float pos[3];
	float ang[3];
	GetClientEyePosition(client, pos);
	GetClientAbsAngles(client, ang);
	int jetpack=CreateEntityByName("prop_dynamic_override"); 
	DispatchKeyValue( jetpack, "model", OXYGENTANK );  
	DispatchSpawn(jetpack); 
	SetEntProp(jetpack, Prop_Data, "m_takedamage", 0, 1);  
	SetEntityMoveType(jetpack, MOVETYPE_NOCLIP);    
	SetEntProp(jetpack, Prop_Data, "m_CollisionGroup", 2); 
	
	if(GetClientTeam(client)==2)
	{
		AttachJetPack(jetpack, client, 0);
	}		
	else 
	{
		AttachJetPack(jetpack, client, 1);
	}
	
	float ang3[3];
	SetVector(ang3, 0.0, 0.0, 1.0); 
	GetVectorAngles(ang3, ang3); 
	CopyVector(ang,ang3);
	if( GetClientTeam(client) == 2)
	{
		ang3[2] += 270.0; 
		ang3[1] -= 10.0; 
		SetVector(pos,  0.0,  -5.0,  4.0);
	}
	else
	{
		ang3[2]+=90.0; 
		SetVector(pos,  0.0,  30.0,  -8.0);
	}
	DispatchKeyValueVector(jetpack, "origin", pos);  
	DispatchKeyValueVector(jetpack, "Angles", ang3); 
	TeleportEntity(jetpack, pos, NULL_VECTOR, ang3); 	
 
	
	if(L4D2Version)
	{
		SetEntProp(jetpack, Prop_Send, "m_iGlowType", 3 ); //3
		SetEntProp(jetpack, Prop_Send, "m_nGlowRange", 0 ); //0
		SetEntProp(jetpack, Prop_Send, "m_glowColorOverride", 1); //1	
	}	
	return 	jetpack;
}

int CreateJetPackB2(int client )
{
	float pos[3];
	float ang[3];
	GetClientEyePosition(client, pos);
	GetClientAbsAngles(client, ang);
	int jetpack=CreateEntityByName("prop_dynamic_override"); 
	DispatchKeyValue( jetpack, "model", OXYGENTANK );  
	DispatchSpawn(jetpack); 
	SetEntProp(jetpack, Prop_Data, "m_takedamage", 0, 1); 	 
	SetEntityMoveType(jetpack, MOVETYPE_NOCLIP);    
	SetEntProp(jetpack, Prop_Data, "m_CollisionGroup", 2);
	
	if(GetClientTeam(client) == 2)
	{
		AttachJetPack(jetpack, client, 0);
	}
	else 
	{
		AttachJetPack(jetpack, client, 2);
	}
	
	float ang3[3];
	SetVector(ang3, 0.0, 0.0, 1.0);
	GetVectorAngles(ang3, ang3); 
	CopyVector(ang, ang3);
	if( GetClientTeam(client) == 2)
	{
		ang3[2] += 270.0; 
		ang3[1] -= 10.0; 
		SetVector(pos,  0.0,  -5.0,  -4.0);
	}
	else
	{
		ang3[2] += 90.0; 
		SetVector(pos,  0.0,  30.0,  8.0);
	} 
	
	DispatchKeyValueVector(jetpack, "origin", pos);  
	DispatchKeyValueVector(jetpack, "Angles", ang3); 
	TeleportEntity(jetpack, pos, NULL_VECTOR, ang3); 	 
	
	if(L4D2Version)
	{
		SetEntProp(jetpack, Prop_Send, "m_iGlowType", 3 ); //3
		SetEntProp(jetpack, Prop_Send, "m_nGlowRange", 0 ); //0
		SetEntProp(jetpack, Prop_Send, "m_glowColorOverride", 1); //1	
	}
	
	return 	jetpack;
}

void AttachFlame( int client, int ent )
{
	client = client + 0;
	char flame_name[128];
	Format(flame_name, sizeof(flame_name), "target%d", ent);
	int flame = CreateEntityByName("env_steam");
	DispatchKeyValue( ent, "targetname", flame_name);
	DispatchKeyValue(flame, "parentname", flame_name);
	DispatchKeyValue(flame, "SpawnFlags", "1");
	DispatchKeyValue(flame, "Type", "0");
 
	DispatchKeyValue(flame, "InitialState", "1");
	DispatchKeyValue(flame, "Spreadspeed", "1");
	DispatchKeyValue(flame, "Speed", "250");
	DispatchKeyValue(flame, "Startsize", "6");
	DispatchKeyValue(flame, "EndSize", "8");
	DispatchKeyValue(flame, "Rate", "555");
	DispatchKeyValue(flame, "RenderColor", "10 52 99"); 
	DispatchKeyValue(flame, "JetLength", "40"); 
	DispatchKeyValue(flame, "RenderAmt", "180");
	
	DispatchSpawn(flame);	 
	SetVariantString(flame_name);
	AcceptEntityInput(flame, "SetParent", flame, flame, 0);
	
	float origin[3];
	SetVector(origin,  -2.0, 0.0,  26.0);
	float ang[3];
	SetVector(ang, 0.0, 0.0, 1.0); 
	GetVectorAngles(ang, ang); 
	TeleportEntity(flame, origin, ang,NULL_VECTOR);	
	AcceptEntityInput(flame, "TurnOn"); 
  
}

void AttachJetPack(int ent, int owner, int position)
{
	 
	if( owner > 0 && ent > 0 )
	{
		if(owner<MaxClients)
		{
			char sTemp[16];
			Format(sTemp, sizeof(sTemp), "target%d", owner);
			DispatchKeyValue(owner, "targetname", sTemp);
			SetVariantString(sTemp);
			AcceptEntityInput(ent, "SetParent", ent, ent, 0);
			if(position==0)SetVariantString("medkit");
			if(position==1)SetVariantString("lfoot");  
			if(position==2)SetVariantString("rfoot"); 
			AcceptEntityInput(ent, "SetParentAttachment");
		}
	}
	 
}