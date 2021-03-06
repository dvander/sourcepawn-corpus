/* Plugin Template generated by Pawn Studio */
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

new ZOMBIECLASS_TANK=	5;
 
#define Pai 3.14159265358979323846 
 
#define Particle_electrical_arc_01_system "electrical_arc_01_system"
#define Particle_st_elmos_fire "st_elmos_fire"
new String:Sound_hit[]=  "ambient/energy/zap1.wav";
new HookWitchCount=0;
 
public Plugin:myinfo = 
{
	name = "Witch Lightning Attack",
	author = "Pan XiaoHai",
	description = "<- Description ->",
	version = "1.8",
	url = "<- URL ->"
}

new Handle:l4d_witch_lightning_chance= INVALID_HANDLE; 
new Handle:l4d_witch_lightning_range= INVALID_HANDLE;
new Handle:l4d_witch_lightning_damage_min= INVALID_HANDLE; 
new Handle:l4d_witch_lightning_damage_max= INVALID_HANDLE;  
new GameMode;
new L4D2Version;
new g_sprite;
public OnPluginStart()
{
	GameCheck(); 

 	l4d_witch_lightning_chance = CreateConVar("l4d_witch_lightning_chance", "100.0", "witch attack chance [0.0, 100.0]");
	l4d_witch_lightning_range = CreateConVar("l4d_witch_lightning_range", "600.0", "witch attack range");
	l4d_witch_lightning_damage_min = CreateConVar("l4d_witch_lightning_damage_min", "5.0", "min attack damage");
 	l4d_witch_lightning_damage_max = CreateConVar("l4d_witch_lightning_damage_max", "30.0", "max attack damage");
    
	AutoExecConfig(true, "witch_lightning_l4d");
	HookEvent("witch_spawn", witch_spawn); 
	HookEvent("witch_killed", witch_killed);  
	
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition",  round_end);	 
 
	Init();
}
public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{ 
 
}
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
 
}
 
 
public Action:witch_killed(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{ 
	new witchid = GetEventInt(h_Event, "witchid");
	if(witchid>0)
	{ 
		StopHookWitch(witchid);
	}
	return Plugin_Handled;
}
public Action:witch_spawn(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{
	//PrintToChatAll("witch spawn");
	new witchid = GetEventInt(h_Event, "witchid");
	CreateTimer(0.1, DelayHookWitch, witchid, TIMER_FLAG_NO_MAPCHANGE );	 

}
 
public Action:DelayHookWitch(Handle:timer, any:witch)
{
	StartHookWitch(witch);
}
new HookWitchs[100];  
new Float:AttackTime[100];
new Float:LastTime[100]; 

new anim_crawl; 
new anim_run; 
new anim_walk;  
new anim_run_crazy;
new anim_ducking;
new anim_threaten;

StartHookWitch(witch)
{
	StopHookWitch(witch);
	if(IsWitch(witch))
	{ 
		new index=AddWitch(witch);
 
		AttackTime[index]=0.0;
		 
		SDKHook(witch, SDKHook_ThinkPost, ThinkWitch);
	}
}
StopHookWitch(witch)
{
	if(witch>0)
	{	
		SDKUnhook(witch, SDKHook_ThinkPost, ThinkWitch);		
		DeleteWitch(witch);
	}
}
DeleteWitch(witch)
{
	new find=-1;
	for(new i=0; i<HookWitchCount; i++)
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
FindWitchIndex(witch)
{
	 
	for(new i=0; i<HookWitchCount; i++)
	{
		if(witch==HookWitchs[i])return i;
	}
	return -1;
}
AddWitch(witch)
{
	HookWitchs[HookWitchCount++]=witch;
	return HookWitchCount-1;
}
Float:GetRage(witch, &Float:rage, &wanderRage)
{
	rage=GetEntPropFloat(witch, Prop_Send, "m_rage");
	if(L4D2Version)wanderRage=GetEntPropFloat(witch, Prop_Send, "m_wanderrage");
	else wanderRage=0.0;
	if(rage>wanderRage)return rage;
	else return wanderRage;
}
SetRage(witch, rage, wanderRage)
{
	SetEntPropFloat(witch, Prop_Send, "m_rage", rage);
	if(L4D2Version)SetEntPropFloat(witch, Prop_Send, "m_wanderrage",wanderRage);  
}
public ThinkWitch(witch)
{
	if(!IsWitch(witch))
	{
		StopHookWitch(witch);
		return;
	}
	new index=FindWitchIndex(witch);
	if(index<0)
	{
		StopHookWitch(witch);
		return;
	}
	new Float:time=GetEngineTime();
	new Float:duration=time-LastTime[index];
	if(duration>0.1)duration=0.1;
	LastTime[index]=time;
	

	new Float:m_rage;
	new Float:m_wanderrage;
	new Float:rage=GetRage(witch, m_rage, m_wanderrage);
	
	if(time-AttackTime[index]>1.0)
	{	
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_witch_lightning_chance))
		{
			decl Float:witchAngle[3]; 
			decl Float:witchPos[3];
			decl Float:victimPos[3];
			
			GetEntPropVector(witch, Prop_Send, "m_angRotation", witchAngle);
			GetEntPropVector(witch, Prop_Send, "m_vecOrigin", witchPos);
			witchPos[2]+=20.0;
			new Float:range=GetConVarFloat(l4d_witch_lightning_range);
			new enemy=FindEnemy(witch, witchPos, range);
			if(enemy>0)
			{ 
				//PrintToChatAll("rage %f",rage);
				new Float:damage1=0.0; 
				new Float:damage2=0.0;
				new Float:damage=0.0;
				new Float:min=GetConVarFloat(l4d_witch_lightning_damage_min);
				new Float:max=GetConVarFloat(l4d_witch_lightning_damage_max);
				new Float:distance=0.0;
				GetClientEyePosition(enemy, victimPos);
				victimPos[2]-=15.0;
				CreateElec(witch,enemy, witchPos, victimPos, true); 
				distance=GetVectorDistance(witchPos, victimPos);
				damage1=min+rage*(max-min) ;
				damage2=min+((range-distance)/range)*(max-min);
				damage=damage1*0.5+damage2*0.5;
				//PrintToChatAll("damage %f", damage);
				DoPointHurtForInfected(enemy, enemy,damage );  
			}
		}
		 
		AttackTime[index]=time;
	} 
 	else return;
 
 
}
CreateElec(witch, victim, Float:pos[3], Float:endpos[3],  bool:show=true)
{   
	if(L4D2Version)
	{
		decl String:witchname[10];
		decl String:cpoint1[10]; 
		decl String:victimname[10]; 
		
		for(new i=0; i<1; i++)
		{
			new ent = CreateEntityByName("info_particle_target"); 
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
			
			
			new particle = CreateEntityByName("info_particle_system");
		 
			DispatchKeyValue(particle, "effect_name",  Particle_st_elmos_fire ); //st_elmos_fire fire_jet_01_flame
			DispatchKeyValue(particle, "cpoint1", cpoint1);
			DispatchKeyValue(particle, "parentname", witchname);
			DispatchSpawn(particle);
			ActivateEntity(particle); 
				
			SetVariantString(witchname);
			AcceptEntityInput(particle, "SetParent",particle, particle, 0);   
			SetVariantString("leye"); 
			AcceptEntityInput(particle, "SetParentAttachment");
			new Float:v[3];
			SetVector(v, 0.0,  0.0,  0.0);  
			TeleportEntity(particle, v, NULL_VECTOR, NULL_VECTOR); 
			AcceptEntityInput(particle, "start");  
			CreateTimer(1.0, DeleteParticles, particle);
			CreateTimer(0.5, DeleteParticletargets, ent);
			
			EmitSoundToAll(Sound_hit, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, endpos, NULL_VECTOR, true, 0.0);
			EmitSoundToAll(Sound_hit, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
			//if(show)ShowParticle(endpos, NULL_VECTOR, Particle_electrical_arc_01_system, 3.0);
		}
	}
	else
	{
		 
		new color[4];
		color[0]=255;
		color[3]=255;
		 
		TE_SetupBeamPoints(pos, endpos, g_sprite, 0, 0, 0, 0.1, 5.0, 5.0, 1, 0.0, color, 0);
		TE_SendToAll();
		EmitSoundToAll(Sound_hit, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, endpos, NULL_VECTOR, true, 0.0);
		EmitSoundToAll(Sound_hit, 0, SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);

	}
	 
 
}
 
FindEnemy(witch,Float:witchPos[3] ,Float:range)
{ 
	witch+=0;  
	if(range==0.0)return 0;	 
 		 
	new Float:minDis=9999.0;
	new selectedPlayer=0;
	decl Float:playerPos[3];
	 
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i)==2 && IsPlayerAlive(i) )
		{
		 
			GetClientEyePosition(i, playerPos);
			new Float:dis=GetVectorDistance(playerPos, witchPos);  
			
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
bool:IfTwoPosVisible(witch, Float:pos1[3], Float:pos2[3])
{
	new bool:r=true;
	new Handle:trace ;
	trace=TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor,witch);
	if(TR_DidHit(trace))
	{
		r=false;
	}
 	CloseHandle(trace);
	return r;
}
public bool:DontHitSelfAndSurvivor(entity, mask, any:data)
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
bool:IsPlayerIncapped(client)
{
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client))
	{
		if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
		
	}
	return false;
}



IsWitch(witch, bool:alive=false)
{
	if(witch>0 && IsValidEdict(witch) && IsValidEntity(witch))
	{
		decl String:classname[32];
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
IsSurvivor(client)
{
	if(client>0 && IsClientInGame(client) && GetClientTeam(client)==2 && IsPlayerAlive(client))
	{
		return true;	 
	}
	return false;
}
CreatePointHurt()
{
	new pointHurt=CreateEntityByName("point_hurt");
	if(pointHurt)
	{		
		DispatchKeyValue(pointHurt,"Damage","10");
		if(L4D2Version)	DispatchKeyValue(pointHurt,"DamageType","2"); 
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}
 new String:N[10];
DoPointHurtForInfected(victim, attacker=0, Float:FireDamage)
{
 
	new g_PointHurt=CreatePointHurt();	 			
	Format(N, 20, "target%d", victim);
	DispatchKeyValue(victim,"targetname", N);
	if(L4D2Version)DispatchKeyValue(g_PointHurt,"DamageType","-2130706422");
	else DispatchKeyValue(g_PointHurt, "DamageType", "8");
	DispatchKeyValue(g_PointHurt,"DamageTarget", N); 
 	DispatchKeyValueFloat(g_PointHurt,"Damage", FireDamage);
	AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
	AcceptEntityInput(g_PointHurt,"kill" ); 
}
GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	
	
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
	
 
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		ZOMBIECLASS_TANK=8;
		L4D2Version=true;
	}	
	else
	{
		ZOMBIECLASS_TANK=5;
		L4D2Version=false;
	}
 
}
 
public OnMapStart()
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
PrintVector(String:s[], Float:target[3])
{
	PrintToChatAll("%s - %f %f %f", s, target[0], target[1], target[2]); 
}
CopyVector(Float:source[3], Float:target[3])
{
	target[0]=source[0];
	target[1]=source[1];
	target[2]=source[2];
}
SetVector(Float:target[3], Float:x, Float:y, Float:z)
{
	target[0]=x;
	target[1]=y;
	target[2]=z;
}
 
//draw line between pos1 and pos2
ShowLaser(colortype,Float:pos1[3], Float:pos2[3], Float:life=10.0,  Float:width1=1.0, Float:width2=11.0)
{
	decl color[4];
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
ShowPos(color, Float:pos1[3], Float:pos2[3],Float:life=10.0, Float:length=0.0, Float:width1=1.0, Float:width2=11.0)
{
	decl Float:t[3];
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
ShowDir(color,Float:pos[3], Float:dir[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=11.0)
{
	decl Float:pos2[3];
	CopyVector(dir, pos2);
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life,   width1, width2);
}
//draw line start from pos, the line's angle is angle.
ShowAngle(color,Float:pos[3], Float:angle[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=11.0)
{
	decl Float:pos2[3];
	GetAngleVectors(angle, pos2, NULL_VECTOR, NULL_VECTOR);
 
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life, width1, width2);
}
Init()
{
 
}
RotateVector(Float:direction[3], Float:vec[3], Float:alfa, Float:result[3])
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
   	decl Float:v[3];
	CopyVector(vec,v);
	
	decl Float:u[3];
	CopyVector(direction,u);
	NormalizeVector(u,u);
	
	decl Float:uv[3];
	GetVectorCrossProduct(u,v,uv);
	
	decl Float:sinuv[3];
	CopyVector(uv, sinuv);
	ScaleVector(sinuv, Sine(alfa));
	
	decl Float:uuv[3];
	GetVectorCrossProduct(u,uv,uuv);
	ScaleVector(uuv, 2.0*Pow(Sine(alfa*0.5), 2.0));	
	
	AddVectors(v, sinuv, result);
	AddVectors(result, uuv, result);
	
 
} 
Float:GetAngle(Float:x1[3], Float:x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}
public PrecacheParticle(String:particlename[])
{
	new particle = CreateEntityByName("info_particle_system");
	if (IsValidEdict(particle))
	{
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	} 
}
public Action:DeleteParticles(Handle:timer, any:particle)
{
	 if (IsValidEntity(particle))
	 {
		 decl String:classname[64];
		 GetEdictClassname(particle, classname, sizeof(classname));
		 if (StrEqual(classname, "info_particle_system", false))
			{
				AcceptEntityInput(particle, "stop");
				AcceptEntityInput(particle, "kill");
				RemoveEdict(particle);
				 
			}
	 }
}
public ShowParticle(Float:pos[3], Float:ang[3],String:particlename[], Float:time)
{
	new particle = CreateEntityByName("info_particle_system");
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
public Action:DeleteParticletargets(Handle:timer, any:target)
{
	 if (IsValidEntity(target))
	 {
		 decl String:classname[64];
		 GetEdictClassname(target, classname, sizeof(classname));
		 if (StrEqual(classname, "info_particle_target", false))
			{
				AcceptEntityInput(target, "stop");
				AcceptEntityInput(target, "kill");
				RemoveEdict(target);
				 
			}
	 }
}
