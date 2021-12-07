/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>
#include <sdktools_functions>
 
 
#define SOUNDMISSILELOCK "UI/Beep07.wav" 

#define FilterSelf 0
#define FilterSelfAndPlayer 1
#define FilterSelfAndSurvivor 2
#define FilterSelfAndInfected 3
#define FilterSelfAndPlayerAndCI 4

#define SurvivorTeam 2
#define InfectedTeam 3
#define MissileTeam 1 

 
new Handle:l4d_tracerock_enable ; 
new Handle:l4d_tracerock_chance;
new Handle:l4d_tracerock_speed; 
new Handle:l4d_tracerock_health; 


new GameMode;
new g_sprite;
new g_iVelocity;
new bool:L4D2Version;
public Plugin:myinfo = 
{
	name = "tank' trace rock",
	author = "Pan Xiaohai",
	description = " ",
	version = "1.0",
	url = "<- URL ->"
}
new bool:gamestart=false;
new Float:FrameTime=0.0;
new Float:FrameDuration=0.0;
new bool:ShowMsg=false;
new Float:ShowTime=0.0;
public OnPluginStart()
{
  	l4d_tracerock_enable = CreateConVar("l4d_tracerock_enable", "1", "  0:disable, 1:enable in coop mode, 2: enable in all mode ", FCVAR_PLUGIN);
 	l4d_tracerock_chance = 	CreateConVar("l4d_tracerock_chance", "30", "the chance of trace of rock [0-100](int)");	
	l4d_tracerock_speed = 	CreateConVar("l4d_tracerock_speed", "300", "trace rock 's speed");	
	l4d_tracerock_health = 	CreateConVar("l4d_tracerock_health", "0", "set trace rock's health, 0:normal health , useless ");	
  	
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	
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
		L4D2Version=true;
	}	
	else
	{
		L4D2Version=false;
	}

	AutoExecConfig(true, "l4d_tracerock"); 
 
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundStart);
	HookEvent("finale_win", RoundStart);
	HookEvent("mission_lost", RoundStart);
	HookEvent("map_transition", RoundStart);	
 
	HookEvent("ability_use", Ability_Use);
	Reset();
	gamestart=false;
	FrameTime=GetEngineTime();
}

Reset()
{
	
}
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	Reset();
	gamestart=false;
}
public Action:Ability_Use(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:s[32];
	GetEventString(event, "ability", s, 32);
 
	if(StrEqual(s, "ability_throw", true))
	{	
		new mode=GetConVarInt(l4d_tracerock_enable);
		if(mode==0)return;
		if(mode==1 && GameMode==2)return;
		gamestart=true;
	}
	
} 

public OnMapStart()
{
 
	PrecacheSound(SOUNDMISSILELOCK, true);	
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
	 
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
		 	
	}

}
 
public OnEntityCreated(entity, const String:classname[])
{
	if(!gamestart)return; 
	new mode=GetConVarInt(l4d_tracerock_enable);
	if(mode==0)return;
	if(mode==1 && GameMode==2)return;	
	if(StrEqual(classname, "tank_rock" ))
	{
		new Float:r=GetRandomFloat(0.0, 100.0); 
		if(r<GetConVarFloat(l4d_tracerock_chance))
		{ 
			CreateTimer(1.1, StartTimer, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
		gamestart=false;
	}
 
}
public Action:StartTimer(Handle:timer, any:ent)
{ 
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{ 
		decl String:classname[32];
		GetEdictClassname(ent, classname, sizeof(classname));
		if(StrEqual(classname, "tank_rock" ))
		{
			new team=GetEntProp(ent, Prop_Send, "m_iTeamNum");  
			if(team>=0)
			{
				StartRockTrace(ent); 
			}
		}
	}
}
StartRockTrace(ent)
{ 
	//new h=GetConVarInt(l4d_tracerock_health);
	//if(h>0)SetEntProp(ent, Prop_Data, "m_iHealth", h);
	SDKUnhook(ent, SDKHook_Think,  PreThink);
	SDKHook( ent, SDKHook_Think,  PreThink);  
}

public OnGameFrame()
{	 
 	new Float:time=GetEngineTime(); 
	FrameDuration=time-FrameTime; 
	FrameTime=time;
	if(FrameDuration>0.1)FrameDuration=0.1;
	if(FrameDuration==0.0)FrameDuration=0.01;
	if(ShowMsg)
	{
		ShowMsg=false;
		ShowTime=time;
	}
	if(time-ShowTime>1.0)
	{
		ShowMsg=true;
	}
}
public PreThink(ent)
{
	if(ent>0 && IsValidEntity(ent) && IsValidEdict(ent))
	{ 
		TraceMissile(ent, FrameDuration );  
	}
	else
	{
		SDKUnhook(ent, SDKHook_Think,  PreThink);
	}

}
 
 
TraceMissile(ent,   Float:duration)
{ 
	
	decl Float:posmissile[3];
 			
	decl Float:velocitymissile[3];	
	 
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", posmissile);	
	GetEntDataVector(ent, g_iVelocity, velocitymissile);
	if(GetVectorLength(velocitymissile)<50.0)return ;
	
	
	NormalizeVector(velocitymissile, velocitymissile);
 
	new myteam=3; 
	new enemyteam=2;
	
 	new enemy=GetEnemy(posmissile, velocitymissile, enemyteam);
	
	decl Float:velocityenemy[3];
	decl Float:vtrace[3];
	
	vtrace[0]=vtrace[1]=vtrace[2]=0.0;	
	new bool:visible=false;
	decl Float:missionangle[3];
 
	new Float:disenemy=1000.0;
	new Float:disobstacle=1000.0;
 
 
	if(enemy>0)	
	{
		decl Float:posenemy[3];
		GetClientEyePosition(enemy, posenemy);
		
		disenemy=GetVectorDistance(posmissile, posenemy);
		 
		visible=IfTwoPosVisible(posmissile, posenemy, ent);
			
		//if(visible)PrintToChatAll("%N visible %f ", client, disenemy);	
		GetEntDataVector(enemy, g_iVelocity, velocityenemy);
 
		ScaleVector(velocityenemy, duration);

		AddVectors(posenemy, velocityenemy, posenemy);
		MakeVectorFromPoints(posmissile, posenemy, vtrace);
		//PrintToChatAll("%N lock %N D:%f", client,enemy, disenemy); 
		
		if(ShowMsg)
		{
			if(enemy>0 && IsClientInGame(enemy) && IsPlayerAlive(enemy))
			{
				PrintHintText(enemy, "Warning! Your are locked by tank's rock, Distance: %d", RoundFloat(disenemy) );
				EmitSoundToClient(enemy, SOUNDMISSILELOCK);
			} 
		} 
	 
	} 
	
	////////////////////////////////////////////////////////////////////////////////////
	GetVectorAngles(velocitymissile, missionangle);
 
	decl Float:vleft[3];
	decl Float:vright[3];
	decl Float:vup[3];
	decl Float:vdown[3];
	decl Float:vfront[3];
	decl Float:vv1[3];
	decl Float:vv2[3];
	decl Float:vv3[3];
	decl Float:vv4[3];
	decl Float:vv5[3];
	decl Float:vv6[3];
	decl Float:vv7[3];
	decl Float:vv8[3];	
	
	vfront[0]=vfront[1]=vfront[2]=0.0;	
	 
	new Float:factor2=0.5; 
	new Float:factor1=0.2; 
	new Float:t;
	new Float:base=1500.0;
	if(visible)
	{
		base=80.0;
 
	}
	{
		//PrintToChatAll("%f %f %f %f %f",front, up, down, left, right);
		new flag=FilterSelfAndSurvivor;
		new bool:print=false;
		new self=ent;
		new Float:front=CalRay(posmissile, missionangle, 0.0, 0.0, vfront, self, print, flag);
		print=false;
		disobstacle=CalRay(posmissile, missionangle, 0.0, 0.0, vfront, self, print, FilterSelf);
		 
		new Float:down=CalRay(posmissile, missionangle, 90.0, 0.0, vdown, self, print,  flag);
		new Float:up=CalRay(posmissile, missionangle, -90.0, 0.0, vup, self, print);
		new Float:left=CalRay(posmissile, missionangle, 0.0, 90.0, vleft, self, print, flag);
		new Float:right=CalRay(posmissile, missionangle, 0.0, -90.0, vright, self, print, flag);
		
		new Float:f1=CalRay(posmissile, missionangle, 30.0, 0.0, vv1, self, print, flag);
		new Float:f2=CalRay(posmissile, missionangle, 30.0, 45.0, vv2, self, print, flag);
		new Float:f3=CalRay(posmissile, missionangle, 0.0, 45.0, vv3, self, print, flag);
		new Float:f4=CalRay(posmissile, missionangle, -30.0, 45.0, vv4, self, print, flag);
		new Float:f5=CalRay(posmissile, missionangle, -30.0, 0.0, vv5, self, print,flag);
		new Float:f6=CalRay(posmissile, missionangle, -30.0, -45.0, vv6, self, print, flag);	
		new Float:f7=CalRay(posmissile, missionangle, 0.0, -45.0, vv7, self, print, flag);
		new Float:f8=CalRay(posmissile, missionangle, 30.0, -45.0, vv8, self, print, flag);					
		  
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
	
	new Float:a=GetAngle(vfront, velocitymissile);			 
	new Float:amax=3.14159*duration*1.5;
	 
	if(a> amax )a=amax ;
	
	ScaleVector(vfront ,a);
	
	//PrintToChat(client, "max %f %f  ",amax , a);
	decl Float:newvelocitymissile[3];
	AddVectors(velocitymissile, vfront, newvelocitymissile);
	
	new Float:speed=GetConVarFloat(l4d_tracerock_speed);
	if(speed<60.0)speed=60.0;
	NormalizeVector(newvelocitymissile, newvelocitymissile);
	ScaleVector(newvelocitymissile,speed);   
	
	SetEntityGravity(ent, 0.01);
	TeleportEntity(ent, NULL_VECTOR,  NULL_VECTOR ,newvelocitymissile);
	if(L4D2Version)
	{
		SetEntProp(ent, Prop_Send, "m_iGlowType", 3 ); //3
		SetEntProp(ent, Prop_Send, "m_nGlowRange", 0 ); //0
		SetEntProp(ent, Prop_Send, "m_glowColorOverride", 11111); //1	
	}	
	
 	//ShowDir(0, posmissile, newvelocitymissile, 0.06); 
}
PrintVector(Float:target[3], String:s[]="")
{
	PrintToChatAll("%s - %f %f %f", s, target[0], target[1], target[2]); 
}
GetEnemy(Float:pos[3], Float:vec[3], enemyteam)
{
	new Float:min=4.0;
	decl Float:pos2[3];
	new Float:t;
	new s=0;
	
	for(new client = 1; client <= MaxClients; client++)
	{
		new bool:playerok=IsClientInGame(client) && GetClientTeam(client)==enemyteam && IsPlayerAlive(client);
		 
		if(playerok )
		{
 
			GetClientEyePosition(client, pos2);
			MakeVectorFromPoints(pos, pos2, pos2);
			t=GetAngle(vec, pos2);
			//PrintToChatAll("%N %f", client, 360.0*t/3.1415926/2.0);
			if(t<=min)
			{
				min=t;
				s=client;
			}
			 
		}
	}
	return s;
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
bool:IfTwoPosVisible(Float:pos1[3], Float:pos2[3], self )
{
	new bool:r=true;
	new Handle:trace ;
	trace=TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, DontHitSelfAndSurvivor,self);
	if(TR_DidHit(trace))
	{
		r=false;
	}
 	CloseHandle(trace);
	return r;
}
Float:CalRay(Float:posmissile[3], Float:angle[3], Float:offset1, Float:offset2,   Float:force[3], ent, bool:printlaser=true, flag=FilterSelf) 
{

	decl Float:ang[3];
	CopyVector(angle, ang);
	ang[0]+=offset1;
	ang[1]+=offset2;
	GetAngleVectors(ang, force, NULL_VECTOR,NULL_VECTOR);
	new Float:dis=GetRayDistance(posmissile, ang, ent, flag) ; 
	//PrintToChatAll("%f %f, %f", dis, offset1, offset2);
	return dis;
}
Float:GetAngle(Float:x1[3], Float:x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}
public bool:DontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	return true;
}
public bool:DontHitSelfAndPlayer(entity, mask, any:data)
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
public bool:DontHitSelfAndPlayerAndCI(entity, mask, any:data)
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
			decl String:edictname[128];
			GetEdictClassname(entity, edictname, 128);
			if(StrContains(edictname, "infected")>=0)
			{
				return false;
			}
		}
	}
	return true;
}
public bool:DontHitSelfAndMissile(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	}
	else if(entity > MaxClients)
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			decl String:edictname[128];
			GetEdictClassname(entity, edictname, 128);
			if(StrContains(edictname, "prop_dynamic")>=0)
			{
				return false;
			}
		}
		
	}
	return true;
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
public bool:DontHitSelfAndInfected(entity, mask, any:data)
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
Float:GetRayDistance(Float:pos[3], Float: angle[3], self, flag)
{
	decl Float:hitpos[3];
	GetRayHitPos(pos, angle, hitpos, self, flag);
	return GetVectorDistance( pos,  hitpos);
}

GetRayHitPos(Float:pos[3], Float: angle[3], Float:hitpos[3], self, flag)
{
	new Handle:trace ;
	new hit=0;
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
		hit=TR_GetEntityIndex( trace);
			
	}
	CloseHandle(trace);
	return hit;
}
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
ShowPos(color, Float:pos1[3], Float:pos2[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=11.0)
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