#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdktools_functions> 
#include <sdkhooks>
 
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6

//int ZOMBIECLASS_TANK=	5;
 
#define Pai 3.14159265358979323846 
 
#define Particle_electrical_arc_01_system "electrical_arc_01_system"
#define Particle_st_elmos_fire "st_elmos_fire"
char Sound_hit[]=  "ambient/energy/zap1.wav";
int HookWitchCount=0;

char N[10];
 
ConVar l4d_witch_lightning_chance; 
ConVar l4d_witch_lightning_range_min;
ConVar l4d_witch_lightning_range_max;
ConVar l4d_witch_lightning_damage_min; 
ConVar l4d_witch_lightning_damage_max;  
//int GameMode;
int L4D2Version;
int g_sprite;
int HookWitchs[100];  
float AttackTime[100];
float LastTime[100]; 
/*
int anim_crawl; 
int anim_run; 
int anim_walk;  
int anim_run_crazy;
int anim_ducking;
int anim_threaten;
*/

public Plugin myinfo = 
{
	name = "Witch Lightning Attack",
	author = "Pan XiaoHai",
	description = "<- Description ->",
	version = "1.8.1",
	url = "<- URL ->"
}

/*
	Fork by Dragokas
	
	1.8.1
	 - Patial backport of electrical effects to l4d1 (required vmt file to add to sm downloader manually)
	 - Converted to a new syntax and methodmaps
	 - Removed unused variables
	 - Set color of laser by entity render color of witch (I set it using another plugin)
	 - The meaning of random chance is changed (now it apply to concrete witch - some witches will not be able to use the laser at all by chance).
	 - l4d_witch_lightning_range ConVar is splitted by two ConVars: min and max.
*/

public void OnPluginStart()
{
	GameCheck();

 	l4d_witch_lightning_chance = CreateConVar("l4d_witch_lightning_chance", "33.3", "witch attack chance [0.0, 100.0]");
	l4d_witch_lightning_range_min = CreateConVar("l4d_witch_lightning_range_min", "100.0", "witch attack minimum range");
	l4d_witch_lightning_range_max = CreateConVar("l4d_witch_lightning_range_max", "300.0", "witch attack maximum range");
	l4d_witch_lightning_damage_min = CreateConVar("l4d_witch_lightning_damage_min", "3.0", "min attack damage");
 	l4d_witch_lightning_damage_max = CreateConVar("l4d_witch_lightning_damage_max", "10.0", "max attack damage");
    
	AutoExecConfig(true, "l4d_witch_lightning");
	HookEvent("witch_spawn", witch_spawn); 
	HookEvent("witch_killed", witch_killed);  
	
	/*
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition",  round_end);	 
	*/
}
 
public Action witch_killed(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{ 
	int witchid = h_Event.GetInt("witchid");
	if(witchid>0)
	{ 
		StopHookWitch(witchid);
	}
	return Plugin_Handled;
}
public Action witch_spawn(Event h_Event, const char[] s_Name, bool b_DontBroadcast)
{
	//PrintToChatAll("witch spawn");
	if(GetRandomFloat(0.0, 100.0)<=l4d_witch_lightning_chance.FloatValue)
	{
		int witchid = h_Event.GetInt("witchid");
		CreateTimer(0.1, DelayHookWitch, witchid, TIMER_FLAG_NO_MAPCHANGE );	 
	}
}
 
public Action DelayHookWitch(Handle timer, any witch)
{
	StartHookWitch(witch);
}

void StartHookWitch(int witch)
{
	StopHookWitch(witch);
	if(IsWitch(witch))
	{ 
		int index=AddWitch(witch);
 
		AttackTime[index]=0.0;
		 
		SDKHook(witch, SDKHook_ThinkPost, ThinkWitch);
	}
}
void StopHookWitch(int witch)
{
	if(witch>0)
	{	
		SDKUnhook(witch, SDKHook_ThinkPost, ThinkWitch);		
		DeleteWitch(witch);
	}
}
void DeleteWitch(int witch)
{
	int find=-1;
	for(int i=0; i<HookWitchCount; i++)
	{
		if(witch==HookWitchs[i]) 
		{
			find=i; break;
		}
	}
	if(find>=0)
	{
		HookWitchs[find]=HookWitchs[HookWitchCount-1]; 
		AttackTime[find]=AttackTime[HookWitchCount-1];
		LastTime[find]=LastTime[HookWitchCount-1]; 
		HookWitchCount--;
	}
}
int FindWitchIndex(int witch)
{
	 
	for(int i=0; i<HookWitchCount; i++)
	{
		if(witch==HookWitchs[i])return i;
	}
	return -1;
}
int AddWitch(int witch)
{
	HookWitchs[HookWitchCount++]=witch;
	return HookWitchCount-1;
}
stock float GetRage(int witch, float &rage, float &wanderRage)
{
	rage=GetEntPropFloat(witch, Prop_Send, "m_rage");
	if(L4D2Version)wanderRage=GetEntPropFloat(witch, Prop_Send, "m_wanderrage");
	else wanderRage=0.0;
	if(rage>wanderRage)return rage;
	else return wanderRage;
}
stock void SetRage(int witch, int rage, int wanderRage)
{
	SetEntPropFloat(witch, Prop_Send, "m_rage", rage);
	if(L4D2Version)SetEntPropFloat(witch, Prop_Send, "m_wanderrage",wanderRage);  
}
public void ThinkWitch(int witch)
{
	if(!IsWitch(witch))
	{
		StopHookWitch(witch);
		return;
	}
	int index=FindWitchIndex(witch);
	if(index<0)
	{
		StopHookWitch(witch);
		return;
	}
	float time=GetEngineTime();
	float duration=time-LastTime[index];
	if(duration>0.1)duration=0.1;
	LastTime[index]=time;
	
	float m_rage;
	float m_wanderrage;
	float rage=GetRage(witch, m_rage, m_wanderrage);

	if(time-AttackTime[index]>2.0)
	{	
		float witchAngle[3]; 
		float witchPos[3];
		float victimPos[3];
		
		GetEntPropVector(witch, Prop_Send, "m_angRotation", witchAngle);
		GetEntPropVector(witch, Prop_Send, "m_vecOrigin", witchPos);
		witchPos[2]+=20.0;
		float range= GetRandomFloat(l4d_witch_lightning_range_min.FloatValue, l4d_witch_lightning_range_max.FloatValue);
		int enemy=FindEnemy(witch, witchPos, range);
		if(enemy>0)
		{ 
			//PrintToChatAll("rage %f",rage);
			float damage1=0.0; 
			float damage2=0.0;
			float damage=0.0;
			float min=l4d_witch_lightning_damage_min.FloatValue;
			float max=l4d_witch_lightning_damage_max.FloatValue;
			float distance=0.0;
			GetClientEyePosition(enemy, victimPos);
			victimPos[2]-=15.0;
			CreateElec(witch,enemy, witchPos, victimPos, true); 
			distance=GetVectorDistance(witchPos, victimPos);
			
			damage1=min+rage*(max-min) ;
			damage2=min+((range-distance)/range)*(max-min);
			damage=damage1*0.5+damage2*0.5;
			
			//damage = GetRandomFloat(min, max);
			
			//PrintToChatAll("damage %f", damage);
			DoPointHurtForInfected(enemy, enemy,damage );  
		}
		 
		AttackTime[index]=time;
	} 
 	else return;
}
void CreateElec(int witch, int victim, float pos[3], float endpos[3], bool show = true)
{   
	char witchname[10];
	char cpoint1[10]; 
	char victimname[10]; 
	
	for(int i=0; i<1; i++)
	{
		if(L4D2Version) {
			int ent = CreateEntityByName("info_particle_target"); 
			DispatchSpawn(ent);  			
			
			Format(witchname, sizeof(witchname), "target%d", witch);
			Format(victimname, sizeof(victimname), "target%d", victim);
			Format(cpoint1, sizeof(cpoint1), "target%d", ent);
			DispatchKeyValue(witch, "targetname", witchname);
			DispatchKeyValue(victim, "targetname", victimname);
			DispatchKeyValue(ent, "targetname", cpoint1);
			
			TeleportEntity(ent, endpos, NULL_VECTOR, NULL_VECTOR); 
			SetVariantString(victimname);
			AcceptEntityInput(ent, "SetParent",ent, ent, 0);
			
			CreateTimer(0.5, DeleteParticletargets, ent);
		}
		
		int particle = CreateEntityByName("info_particle_system");
	 
		DispatchKeyValue(particle, "effect_name",  Particle_st_elmos_fire ); //st_elmos_fire fire_jet_01_flame
		DispatchKeyValue(particle, "cpoint1", cpoint1);
		DispatchKeyValue(particle, "parentname", witchname);
		DispatchSpawn(particle);
		ActivateEntity(particle); 
		
		SetVariantString(witchname);
		AcceptEntityInput(particle, "SetParent",particle, particle, 0);   
		SetVariantString("leye"); 
		AcceptEntityInput(particle, "SetParentAttachment");
		float v[3];
		SetVector(v, 0.0,  0.0,  0.0);  
		TeleportEntity(particle, v, NULL_VECTOR, NULL_VECTOR); 
		AcceptEntityInput(particle, "start");  
		CreateTimer(1.0, DeleteParticles, particle);
		
		EmitSoundToAll(Sound_hit, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, endpos, NULL_VECTOR, true, 0.0);
		EmitSoundToAll(Sound_hit, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
		if(show)ShowParticle(endpos, NULL_VECTOR, Particle_electrical_arc_01_system, 3.0);
	}

	int color[4];
	/*
	color[0]=255;
	color[3]=255;
	*/
	
	GetEntityRenderColor(witch, color[0], color[1], color[2], color[3]);
	 
	TE_SetupBeamPoints(pos, endpos, g_sprite, 0, 0, 0, 0.5, 5.0, 5.0, 1, 0.0, color, 0);
	TE_SendToAll();
}
 
int FindEnemy(int witch, float witchPos[3], float range)
{ 
	witch+=0;  
	if(range==0.0)return 0;	 
 		 
	float minDis=9999.0;
	int selectedPlayer=0;
	float playerPos[3];
	 
	for(int i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2 && IsPlayerAlive(i) )
		{
		 
			GetClientEyePosition(i, playerPos);
			float dis=GetVectorDistance(playerPos, witchPos);  
			
			if(dis<=range && dis<=minDis)
			{
				if(IfTwoPosVisible(witch, witchPos, playerPos))
				{
					selectedPlayer=i ;
					minDis=dis; 
				}
			}
		}
	} 
	return selectedPlayer;	 
} 
bool IfTwoPosVisible(int witch, float pos1[3], float pos2[3])
{
	bool r=true;
	Handle trace ;
	trace=TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor,witch);
	if(TR_DidHit(trace))
	{
		r=false;
	}
 	delete trace;
	return r;
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
stock bool IsPlayerIncapped(int client)
{
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client))
	{
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
		
	}
	return false;
}

bool IsWitch(int witch, bool alive = false)
{
	if(witch>0 && IsValidEdict(witch) && IsValidEntity(witch))
	{
		char classname[32];
		GetEdictClassname(witch, classname, sizeof(classname));
		if(StrEqual(classname, "witch"))
		{
			if(alive)
			{
			}
			return true;
		}
	}
	return false;
}
stock bool IsSurvivor(int client)
{
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client))
	{
		return true;	 
	}
	return false;
}
int CreatePointHurt()
{
	int pointHurt=CreateEntityByName("point_hurt");
	if(pointHurt)
	{		
		DispatchKeyValue(pointHurt,"Damage","10");
		if(L4D2Version)	DispatchKeyValue(pointHurt,"DamageType","2"); 
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}

void DoPointHurtForInfected(int victim, int attacker = 0, float FireDamage)
{
 
	int g_PointHurt=CreatePointHurt();	 			
	Format(N, 20, "target%d", victim);
	DispatchKeyValue(victim,"targetname", N);
	if(L4D2Version)DispatchKeyValue(g_PointHurt,"DamageType","-2130706422");
	else DispatchKeyValue(g_PointHurt, "DamageType", "8");
	DispatchKeyValue(g_PointHurt,"DamageTarget", N); 
 	DispatchKeyValueFloat(g_PointHurt,"Damage", FireDamage);
	AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
	AcceptEntityInput(g_PointHurt,"kill" ); 
}

stock void GameCheck()
{
	char GameName[16];
	
	/*
	FindConVar("mp_gamemode").GetString(GameName, sizeof(GameName));
	
	if (StrEqual(GameName, "survival", false))
		GameMode = 3;
	else if (StrEqual(GameName, "versus", false) || StrEqual(GameName, "teamversus", false) || StrEqual(GameName, "scavenge", false) || StrEqual(GameName, "teamscavenge", false))
		GameMode = 2;
	else if (StrEqual(GameName, "coop", false) || StrEqual(GameName, "realism", false))
		GameMode = 1;
	else
	{
		GameMode = 0;
 	}
	*/
	
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		//ZOMBIECLASS_TANK=8;
		L4D2Version=true;
	}	
	else
	{
		//ZOMBIECLASS_TANK=5;
		L4D2Version=false;
	}
 
}
 
public void OnMapStart()
{
	 
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
	 
		PrecacheParticle(Particle_electrical_arc_01_system);
		PrecacheParticle(Particle_st_elmos_fire);
 
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
		Sound_hit="ambient/energy/zap1.wav";
	}
	PrecacheSound(Sound_hit, true);
	g_sprite=g_sprite+0;
	HookWitchCount=0;

}
stock void PrintVector(char[] s, float target[3])
{
	PrintToChatAll("%s - %f %f %f", s, target[0], target[1], target[2]); 
}
stock void CopyVector(float source[3], float target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}
void SetVector(float target[3], float x, float y, float z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}
 
//draw line between pos1 and pos2
stock void ShowLaser(int colortype, float pos1[3], float pos2[3], float life = 10.0, float width1 = 1.0, float width2 = 11.0)
{
	int color[4];
	if(colortype==1)
	{
		color[0] = 200; 
		color[1] = 0;
		color[2] = 0;
		color[3] = 230; 
	}
	else if(colortype==2)
	{
		color[0] = 0; 
		color[1] = 200;
		color[2] = 0;
		color[3] = 230; 
	}
	else if(colortype==3)
	{
		color[0] = 0; 
		color[1] = 0;
		color[2] = 200;
		color[3] = 230; 
	}
	else 
	{
		color[0] = 200; 
		color[1] = 200;
		color[2] = 200;
		color[3] = 230; 		
	}

	
	TE_SetupBeamPoints(pos1, pos2, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
	TE_SendToAll();
}
//draw line between pos1 and pos2
stock void ShowPos(int color, float pos1[3], float pos2[3], float life = 10.0, float length = 0.0, float width1 = 1.0, float width2 = 11.0)
{
	float t[3];
	if(length!=0.0)
	{
		SubtractVectors(pos2, pos1, t);	 
		NormalizeVector(t,t);
		ScaleVector(t, length);
		AddVectors(pos1, t,t);
	}
	else 
	{
		CopyVector(pos2,t);
	}
	ShowLaser(color,pos1, t, life,   width1, width2);
}
//draw line start from pos, the line's drection is dir.
stock void ShowDir(int color, float pos[3], float dir[3], float life = 10.0, float length = 200.0, float width1 = 1.0, float width2 = 11.0)
{
	float pos2[3];
	CopyVector(dir, pos2);
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life,   width1, width2);
}
//draw line start from pos, the line's angle is angle.
stock void ShowAngle(int color, float pos[3], float angle[3], float life = 10.0, float length = 200.0, float width1 = 1.0, float width2 = 11.0)
{
	float pos2[3];
	GetAngleVectors(angle, pos2, NULL_VECTOR, NULL_VECTOR);
 
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life, width1, width2);
}
stock void RotateVector(float direction[3], float vec[3], float alfa, float result[3])
{
  /*
   on rotateVector (v, u, alfa)
  -- rotates vector v around u alfa degrees
  -- returns rotated vector 
  -----------------------------------------
  u.normalize()
  alfa = alfa*pi()/180 -- alfa in rads
  uv = u.cross(v)
  vect = v + sin (alfa) * uv + 2*power(sin(alfa/2), 2) * (u.cross(uv))
  return vect
	end
   */
   	float v[3];
	CopyVector(vec,v);
	
	float u[3];
	CopyVector(direction,u);
	NormalizeVector(u,u);
	
	float uv[3];
	GetVectorCrossProduct(u,v,uv);
	
	float sinuv[3];
	CopyVector(uv, sinuv);
	ScaleVector(sinuv, Sine(alfa));
	
	float uuv[3];
	GetVectorCrossProduct(u,uv,uuv);
	ScaleVector(uuv, 2.0*Pow(Sine(alfa*0.5), 2.0));	
	
	AddVectors(v, sinuv, result);
	AddVectors(result, uuv, result);
	
 
} 
stock float GetAngle(float x1[3], float x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}
public void PrecacheParticle(char[] particlename)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	} 
}
public Action DeleteParticles(Handle timer, any particle)
{
	if (IsValidEntity(particle))
	{
		char classname[64];
		GetEdictClassname(particle, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_system", false))
		{
			AcceptEntityInput(particle, "stop");
			AcceptEntityInput(particle, "kill");
			RemoveEdict(particle);
		}
	 }
}
public int ShowParticle(float pos[3], float ang[3], char[] particlename, float time)
{
	int particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename); 
		DispatchSpawn(particle);
		ActivateEntity(particle);
		
		TeleportEntity(particle, pos, ang, NULL_VECTOR);
		AcceptEntityInput(particle, "start");		
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
		return particle;
	}  
	return 0;
}
public Action DeleteParticletargets(Handle timer, any target)
{
	if (IsValidEntity(target))
	{
		char classname[64];
		GetEdictClassname(target, classname, sizeof(classname));
		if (StrEqual(classname, "info_particle_target", false))
		{
			AcceptEntityInput(target, "stop");
			AcceptEntityInput(target, "kill");
			RemoveEdict(target);
		}
	}
}
