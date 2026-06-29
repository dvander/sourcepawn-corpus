#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>

 
#define Pai 3.14159265358979323846 
#define DEBUG false
#define State_None 0
#define State_OK 2
 
#define PARTICLE_MUZZLE_FLASH		"weapon_muzzle_flash_autoshotgun"  
#define PARTICLE_WEAPON_TRACER		"weapon_tracers" 
#define PARTICLE_WEAPON_TRACER2		"weapon_tracers_50cal"//weapon_tracers_50cal" //"weapon_tracers_explosive" weapon_tracers_50cal
 
#define PARTICLE_BLOOD		"blood_impact_red_01"
#define PARTICLE_BLOOD2		"blood_impact_headshot_01"

#define SOUND_IMPACT1		"physics/flesh/flesh_impact_bullet1.wav"  
#define SOUND_IMPACT2		"physics/concrete/concrete_impact_bullet1.wav"  
#define SOUND_BOMBEXPLODE		"weapons/grenade_launcher/grenadefire/grenade_launcher_explode_1.wav"  
#define MODEL_W_PIPEBOMB "models/w_models/weapons/w_eq_pipebomb.mdl"
#define MODEL_GUN "models/w_models/weapons/w_minigun.mdl"

new Handle:l4d_machine_enable ;   
new Handle:l4d_machine_damage ; 
new Handle:l4d_machine_maxcount ;  
new Handle:l4d_machine_range ; 
new Handle:l4d_machine_voerheat ; 

new MachineCount=0;
new ScanEnable=false;

new GameMode;
new L4D2Version;

#define ArraySize 200
new InfectedsArray[ArraySize];
new InfectedCount;

new State[MAXPLAYERS+1]; 
new Gun[MAXPLAYERS+1];
new GunOwner[MAXPLAYERS+1];
new GunCarrier[MAXPLAYERS+1];

new Float:GunCarrierOrigin[MAXPLAYERS+1][3];
new Float:GunCarrierAngle[MAXPLAYERS+1][3];
new Float:GunFireStopTime[MAXPLAYERS+1];
 

new GunScanIndex[MAXPLAYERS+1];
 

new Float:GunFireTime[MAXPLAYERS+1];


new Float:GunFireTotolTime[MAXPLAYERS+1];

new GunEnemy[MAXPLAYERS+1];
 

new Float:GunAngle[MAXPLAYERS+1][3];



new bool:Broken[MAXPLAYERS+1];
new LastButton[MAXPLAYERS+1]; 
new Float:PressTime[MAXPLAYERS+1];
new Float:LastTime[MAXPLAYERS+1]; 

new ShowMsg[MAXPLAYERS+1]; 
 
new g_sprite;
new g_iVelocity ;
new g_PointHurt;

new Float:FireIntervual=0.05;
 
new Float:FireOverHeatTime=10.0;

public Plugin:myinfo = 
{
	name = "Machine",
	author = "Pan Xiaohai",
	description = "",
	version = "1.01",	
}
 
public OnPluginStart()
{
	GameCheck(); 	
 	l4d_machine_enable = CreateConVar("l4d_machine_enable", "2", "  0:disable, 1:enable in coop mode, 2: enable in all mode ", FCVAR_PLUGIN);
	l4d_machine_damage=CreateConVar("l4d_machine_damage", "25.0", "bullet damage", FCVAR_PLUGIN);	
	l4d_machine_maxcount=CreateConVar("l4d_machine_maxuser", "5", "maxmum of machine gun", FCVAR_PLUGIN);	
	l4d_machine_range=CreateConVar("l4d_machine_range", "1000.0", "maxmum scan range of machine gun", FCVAR_PLUGIN);
	l4d_machine_voerheat=CreateConVar("l4d_machine_voerheat", "10.0", " seconds", FCVAR_PLUGIN);
 	 
 	AutoExecConfig(true, "l4d_machine");   
	
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	
	HookEvent("player_bot_replace", player_bot_replace );	  
	HookEvent("player_spawn", player_spawn);
	HookEvent("player_death", player_death);
	HookEvent("entity_shoved", entity_shoved); 
 
	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	 
	RegConsoleCmd("sm_machine", sm_machine);  
	ResetAllState();

}
bool:CanUse()
{
	new mode=GetConVarInt(l4d_machine_enable);
	if(mode==0)return false;
	if(mode==1 && GameMode!=2)return true;
	if(mode==2)return true;
	return false;
}
public Action:entity_shoved(Handle:event, String:event_name[], bool:dontBroadcast)
{
	if(!CanUse()) return Plugin_Continue; 	 
	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker>0 && IsClientInGame(attacker) && GetClientTeam(attacker)==2)
	{		
		new gun=GetMinigun(attacker);
		if(gun>0)
		{
			StartCarry(attacker, gun);
		} 
	}
	return Plugin_Continue;
}
GetMinigun(client )
{ 
	new ent= GetClientAimTarget(client, false);
	if(ent>0)
	{			
		decl String:classname[64];
		GetEdictClassname(ent, classname, 64);			
		if(StrEqual(classname, "prop_minigun") || StrEqual(classname, "prop_minigun_l4d1"))
		{
		}
		else ent=0;
	}  
	return ent;
}
 
public Action:sm_machine(client,args)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		CreateMachine(client);
	}
} 
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	if(!CanUse())return;
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));  
	StopClientCarry(client);
	StopClientCarry(bot);
}
 
public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(!CanUse())return;
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
 	ShowMsg[victim]=0; 
	InfectedRemove(victim);
}
public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(!CanUse())return;
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	if (client > 0 && client <= GetMaxClients())
	{
		if (IsClientInGame(client) )
		{
			if(GetClientTeam(client)==3)InfectedAdd(client); 
		}
	}
} 
SetVectorOffest(Float:pos[3], Float:angle[3], Float:result[3],Float:front, Float:right, Float:up)
{
	decl Float:temp[3];
	decl Float:endpos[3];
	GetAngleVectors(angle, temp, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(temp, temp);
	ScaleVector(temp, front);
	AddVectors(pos, temp, endpos);
	
	GetAngleVectors(angle, NULL_VECTOR, temp, NULL_VECTOR);
	NormalizeVector(temp, temp);
	ScaleVector(temp, right);
	AddVectors(endpos, temp, endpos);
	
	GetAngleVectors(angle, NULL_VECTOR, NULL_VECTOR, temp);
	NormalizeVector(temp, temp);
	ScaleVector(temp, up);
	AddVectors(endpos, temp, endpos);	
	CopyVector(endpos, result);
}
 
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	return true;
}
public bool:TraceRayDontHitSelfAndSurvivor(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	if(entity>0 && entity<=MaxClients)
	{
		if(GetClientTeam(entity)==2)return false;
	}
	return true;
} 
 
PrintVector( Float:target[3], String:s[]="")
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
		L4D2Version=true;
	}	
	else
	{
		L4D2Version=false;
	}
 
}
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
}

public OnMapStart()
{
	PrecacheModel(MODEL_W_PIPEBOMB);
	PrecacheModel(MODEL_GUN);
	 
	PrecacheSound(SOUND_BOMBEXPLODE);
	PrecacheSound(SOUND_IMPACT1);	
	PrecacheSound(SOUND_IMPACT2);
 
	
	PrecacheParticle(PARTICLE_MUZZLE_FLASH);
	
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
		PrecacheParticle(PARTICLE_WEAPON_TRACER2);
		PrecacheParticle(PARTICLE_BLOOD2);
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
		PrecacheParticle(PARTICLE_WEAPON_TRACER);
		PrecacheParticle(PARTICLE_BLOOD);
	}
}
 
public Action:ShowInfo(Handle:timer, any:client)
{
	if(L4D2Version )DisplayHint(INVALID_HANDLE, client);
	else PrintToChat(client, "\x03Press \x04mouse right button to \x03carry \x04machine gun\x03");
}
//code from "DJ_WEST"

public Action:DisplayHint(Handle:h_Timer, any:i_Client)
{ 
	if ( IsClientInGame(i_Client))	ClientCommand(i_Client, "gameinstructor_enable 0");
	CreateTimer(1.0, DelayDisplayHint, i_Client);
}
public Action:DelayDisplayHint(Handle:h_Timer, any:i_Client)
{ 
	DisplayInstructorHint(i_Client, "SHOVE to carry machine gun", "+attack2");
}
public DisplayInstructorHint(i_Client, String:s_Message[256], String:s_Bind[])
{
	decl i_Ent, String:s_TargetName[32], Handle:h_RemovePack;
	
	i_Ent = CreateEntityByName("env_instructor_hint");
	FormatEx(s_TargetName, sizeof(s_TargetName), "hint%d", i_Client);
	ReplaceString(s_Message, sizeof(s_Message), "\n", " ");
	DispatchKeyValue(i_Client, "targetname", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_target", s_TargetName);
	DispatchKeyValue(i_Ent, "hint_timeout", "5");
	DispatchKeyValue(i_Ent, "hint_range", "0.01");
	DispatchKeyValue(i_Ent, "hint_color", "255 255 255");
	DispatchKeyValue(i_Ent, "hint_icon_onscreen", "use_binding");
	DispatchKeyValue(i_Ent, "hint_caption", s_Message);
	DispatchKeyValue(i_Ent, "hint_binding", s_Bind);
	DispatchSpawn(i_Ent);
	AcceptEntityInput(i_Ent, "ShowHint");
	
	h_RemovePack = CreateDataPack();
	WritePackCell(h_RemovePack, i_Client);
	WritePackCell(h_RemovePack, i_Ent);
	CreateTimer(5.0, RemoveInstructorHint, h_RemovePack);
}
	
public Action:RemoveInstructorHint(Handle:h_Timer, Handle:h_Pack)
{
	decl i_Ent, i_Client;
	
	ResetPack(h_Pack, false);
	i_Client = ReadPackCell(h_Pack);
	i_Ent = ReadPackCell(h_Pack);
	CloseHandle(h_Pack);
	
	if (!i_Client || !IsClientInGame(i_Client))
		return Plugin_Handled;
	
	if (IsValidEntity(i_Ent))
			RemoveEdict(i_Ent);
	
	ClientCommand(i_Client, "gameinstructor_enable 0");
		
	DispatchKeyValue(i_Client, "targetname", "");
		
	return Plugin_Continue;
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
public Action:DeleteParticletargets(Handle:timer, any:target)
{
	 if (IsValidEntity(target))
	 {
		 decl String:classname[64];
		 GetEdictClassname(target, classname, sizeof(classname));
		 if (StrEqual(classname, "info_particle_target", false) || StrEqual(classname, "info_target", false))
			{
				AcceptEntityInput(target, "stop");
				AcceptEntityInput(target, "kill");
				RemoveEdict(target);
				 
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
ShowPos(color, Float:pos1[3], Float:pos2[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=4.0)
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
ShowDir(color,Float:pos[3], Float:dir[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=4.0)
{
	decl Float:pos2[3];
	CopyVector(dir, pos2);
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life,   width1, width2);
}
//draw line start from pos, the line's angle is angle.
ShowAngle(color,Float:pos[3], Float:angle[3],Float:life=10.0, Float:length=200.0, Float:width1=1.0, Float:width2=4.0)
{
	decl Float:pos2[3];
	GetAngleVectors(angle, pos2, NULL_VECTOR, NULL_VECTOR);
 
	NormalizeVector(pos2,pos2);
	ScaleVector(pos2, length);
	AddVectors(pos, pos2,pos2);
	ShowLaser(color,pos, pos2, life, width1, width2);
} 
ShowMuzzleFlash(Float:pos[3],  Float:angle[3])
{  
 	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_MUZZLE_FLASH); 
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	TeleportEntity(particle, pos, angle, NULL_VECTOR);
	AcceptEntityInput(particle, "start");	
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);	
}
ShowTrack(  Float:pos[3], Float:endpos[3] )
{  
 	decl String:temp[32];		
	new target =0;
	if(L4D2Version)target=CreateEntityByName("info_particle_target");
	else target=CreateEntityByName("info_target"); 
	Format(temp, 32, "cptarget%d", target);
	DispatchKeyValue(target, "targetname", temp);	
	TeleportEntity(target, endpos, NULL_VECTOR, NULL_VECTOR); 
	ActivateEntity(target); 
 
	new particle = CreateEntityByName("info_particle_system");
	if(L4D2Version)	DispatchKeyValue(particle, "effect_name", PARTICLE_WEAPON_TRACER2);
	else DispatchKeyValue(particle, "effect_name", PARTICLE_WEAPON_TRACER);
	DispatchKeyValue(particle, "cpoint1", temp);
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
	AcceptEntityInput(particle, "start");	
	CreateTimer(0.01, DeleteParticletargets, target, TIMER_FLAG_NO_MAPCHANGE);
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
}
CreatePointHurt()
{
	new pointHurt=CreateEntityByName("point_hurt");
	if(pointHurt)
	{		
		DispatchKeyValue(pointHurt,"Damage","10");
		if(L4D2Version)	DispatchKeyValue(pointHurt,"DamageType","-2130706430"); 
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}
new String:N[10];
DoPointHurtForInfected(victim, attacker=0)
{
	if(g_PointHurt > 0)
	{
		if(IsValidEdict(g_PointHurt))
		{
			if(victim>0 && IsValidEdict(victim))
			{		
				
				Format(N, 20, "target%d", victim);
				DispatchKeyValue(victim,"targetname", N);
				DispatchKeyValue(g_PointHurt,"DamageTarget", N);
				new Float:d=GetConVarFloat(l4d_machine_damage);
				DispatchKeyValueFloat(g_PointHurt,"Damage", d);
				if(L4D2Version)
				{					
					DispatchKeyValueFloat(g_PointHurt,"Damage", d); 
				}
				else
				{
					new h=GetEntProp(victim, Prop_Data, "m_iHealth"); 
					if(h*1.0<=d)  DispatchKeyValue(g_PointHurt, "DamageType", "64");
					else  DispatchKeyValue(g_PointHurt, "DamageType", "-1073741822"); 
				}
				AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
			}
		}
		else g_PointHurt=CreatePointHurt();
	}
	else g_PointHurt=CreatePointHurt();
}
public OnEntityCreated(entity, const String:classname[])
{
	if(!ScanEnable)return;
	//PrintToChatAll("create %d %s", entity, classname);
	if(StrEqual(classname, "infected") )
	{
		InfectedAdd(entity); 
	}
} 
ResetAllState()
{
	g_PointHurt=0; 
	ScanEnable=false; 
	MachineCount=0;
	for(new i=1; i<=MaxClients; i++)
	{
		if(State[i]!=State_None)SDKUnhook( Gun[i], SDKHook_Think,  PreThinkGun);  
		State[i]=State_None; 
		ShowMsg[i]=0;
		GunOwner[i]=GunCarrier[i]=Gun[i]=0;
	} 
	InfectedArrayReset();
} 
InfectedArrayReset()
{
	InfectedCount=0;
}
InfectedAdd(data)
{
	if(InfectedCount<ArraySize)
	{
		InfectedsArray[InfectedCount++]=data; 
		//PrintToChatAll("add %d", InfectedCount);
	} 
}
InfectedRemove(data)
{
	new find=-1;
	for(new i=0; i<InfectedCount; i++)
	{
		if(InfectedsArray[i]==data)
		{
			find=i;
			break;
		}
	}
	if(find>=0)
	{
		InfectedsArray[find]=InfectedsArray[--InfectedCount];  
			//PrintToChatAll("remove %d", InfectedCount);
	} 
}
CreateMachine(client)
{
	if(MachineCount>=GetConVarInt(l4d_machine_maxcount))
	{
		PrintToChat(client, "There are too many machine");
		return;
	} 
	if(IsClientInGame(client) && IsPlayerAlive(client))
	{
		
		Gun[MachineCount]=SpawnMiniGun(client); 
		State[MachineCount]=State_OK;  
		LastTime[MachineCount]=GetEngineTime();
		Broken[MachineCount]=false; 
	 
		GunScanIndex[MachineCount]=InfectedCount-1;
		GunEnemy[MachineCount]=0;
		GunFireTime[MachineCount]=0.0;
		GunFireStopTime[MachineCount]=0.0;
		GunFireTotolTime[MachineCount]=0.0;
		GunOwner[MachineCount]=client;
		GunCarrier[MachineCount]=0;
		SDKUnhook( Gun[MachineCount], SDKHook_Think,  PreThinkGun); 
		SDKHook( Gun[MachineCount], SDKHook_Think,  PreThinkGun); 
		if(MachineCount==0)
		{
			InfectedArrayReset();
			for(new i=1; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==3)
				{
					InfectedAdd(i);
				}
			}
		} 
		 
		ScanEnable=true;
		MachineCount++;
		if(ShowMsg[client]<2)
		{
			ShowMsg[client]++;
			CreateTimer(1.0, ShowInfo,client); 
		}
	}

}

RemoveMachine(index)
{
	if(State[index]==State_None)return; 
	State[index]=State_None;
	SDKUnhook( Gun[index], SDKHook_Think,  PreThinkGun);   
	if(Gun[index]>0 && IsValidEdict(Gun[index]) && IsValidEntity(Gun[index]))RemoveEdict(Gun[index]);  
	Gun[index]=0;
	if(MachineCount>1)
	{
		
		Gun[index]=Gun[MachineCount-1];
		State[index]=State[MachineCount-1];  
		LastTime[index]=LastTime[MachineCount-1];
		Broken[index]=Broken[MachineCount-1]; 
		GunScanIndex[index]=GunScanIndex[MachineCount-1];
		GunEnemy[index]=GunEnemy[MachineCount-1];
		GunFireTime[index]=GunFireTime[MachineCount-1];
		GunFireStopTime[index]=GunFireStopTime[MachineCount-1];
		GunFireTotolTime[index]=GunFireTotolTime[MachineCount-1];
		GunOwner[index]=GunOwner[MachineCount-1];
		GunCarrier[index]=GunCarrier[MachineCount-1];
	}
	MachineCount--;
	if(MachineCount==0)
	{
		ScanEnable=false;
		InfectedArrayReset();
	}
	if(MachineCount<0)MachineCount=0;
	PrintToChatAll("remove gun count %d ",MachineCount);
}

/* code from  "Movable Machine Gun", author = "hihi1210" 
*/
SpawnMiniGun(client )
{
	decl Float:VecOrigin[3], Float:VecAngles[3], Float:VecDirection[3]; 
	new index=0;
	if(L4D2Version)index=CreateEntityByName ( "prop_minigun_l4d1"); 
	else index=CreateEntityByName ( "prop_minigun");  
	//DispatchKeyValue(index, "model", "Minigun_1");
	SetEntityModel (index, MODEL_GUN);
	DispatchKeyValueFloat (index, "MaxPitch", 360.00);
	DispatchKeyValueFloat (index, "MinPitch", -360.00);
	DispatchKeyValueFloat (index, "MaxYaw", 360.00);
	DispatchSpawn(index);
	 
	GetClientAbsOrigin(client, VecOrigin);
	GetClientEyeAngles(client, VecAngles);
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 45;
	VecOrigin[1] += VecDirection[1] * 45;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(index, "Angles", VecAngles);
	DispatchSpawn(index);
	TeleportEntity(index, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	if(L4D2Version)
	{
		SetEntProp(index, Prop_Send, "m_iGlowType", 3 ); //3
		SetEntProp(index, Prop_Send, "m_nGlowRange", 0 ); //0
		SetEntProp(index, Prop_Send, "m_glowColorOverride", 1); //1	
	}	
	return index;
}
PutMiniGun(index, Float:VecOrigin[3],Float:VecAngles[3])
{
 
	new Float:VecDirection[3]; 
	DispatchKeyValueFloat (index, "MaxPitch", 360.00);
	DispatchKeyValueFloat (index, "MinPitch", -360.00);
	DispatchKeyValueFloat (index, "MaxYaw", 360.00);   
	 
	GetAngleVectors(VecAngles, VecDirection, NULL_VECTOR, NULL_VECTOR);
	VecOrigin[0] += VecDirection[0] * 45;
	VecOrigin[1] += VecDirection[1] * 45;
	VecOrigin[2] += VecDirection[2] * 1;   
	VecAngles[0] = 0.0;
	VecAngles[2] = 0.0;
	DispatchKeyValueVector(index, "Angles", VecAngles);
	TeleportEntity(index, VecOrigin, NULL_VECTOR, NULL_VECTOR);
	if(L4D2Version)
	{
		SetEntProp(index, Prop_Send, "m_iGlowType", 3 ); //3
		SetEntProp(index, Prop_Send, "m_nGlowRange", 0 ); //0
		SetEntProp(index, Prop_Send, "m_glowColorOverride", 1); //1	
	}	
	return index; 
} 
FindGunIndex(gun)
{
	new index=-1;
	for(new i=0; i<MachineCount; i++)
	{
		if(Gun[i]==gun)
		{
			index=i;
			break;
		}
	}
	return index;
}
FindCarryIndex(client)
{
	new index=-1;
	for(new i=0; i<MachineCount; i++)
	{
		if(GunCarrier[i]==client)
		{
			index=i;
			break;
		}
	}
	
	return index;
}
StartCarry(client, gun)
{
	
	if(FindCarryIndex(client)>=0)return;  
	new index=FindGunIndex(gun); 
	if(index>=0)
	{
		if(GunCarrier[index]>0)return;
		GunCarrier[index]=client; 
		SetEntProp(gun, Prop_Data, "m_CollisionGroup", 2); 
		SetEntProp(gun, Prop_Send, "m_firing", 0); 
		new Float:ang[3];
		SetVector(ang, 0.0, 0.0, 90.0);
		new Float:pos[3];
		SetVector(pos, 0.0, 10.0,  0.0);
		AttachEnt(client, gun, "medkit", pos, ang);
		LastButton[client]=0;
		PressTime[client]=0.0;
	}
}
StopClientCarry(client)
{
	if(client<=0)return;
	new index=FindCarryIndex(client);
	if(index>=0)
	{
		StopCarry(index);
	}
	return;
}
StopCarry(index)
{
	if(GunCarrier[index]>0)
	{
		GunCarrier[index]=0; 
		AcceptEntityInput(Gun[index], "ClearParent"); 
		PutMiniGun(Gun[index], GunCarrierOrigin[index], GunCarrierAngle[index]);
		SetEntProp(Gun[index], Prop_Data, "m_CollisionGroup", 0); 
	}
}
Carrying(index, Float:intervual)
{ 
	new client=GunCarrier[index];
	new button=GetClientButtons(client);
	GetClientAbsOrigin(client , GunCarrierOrigin[index]);
	GetClientEyeAngles(client, GunCarrierAngle[index]);
	if(button & IN_USE)
	{
		PressTime[client]+=intervual;
		if(PressTime[client]>0.5)
		{
			if(GetEntityFlags(client) & FL_ONGROUND)StopCarry(index);
		}
	} 
	else
	{
		PressTime[client]=0.0;
	}
	LastButton[client]=client;
}
AttachEnt(owner, ent, String:positon[]="medkit", Float:pos[3]=NULL_VECTOR,Float:ang[3]=NULL_VECTOR)
{
	decl String:tname[60];
	Format(tname, sizeof(tname), "target%d", owner);
	DispatchKeyValue(owner, "targetname", tname); 		
	DispatchKeyValue(ent, "parentname", tname);
	
	SetVariantString(tname);
	AcceptEntityInput(ent, "SetParent",ent, ent, 0); 	
	if(strlen(positon)!=0)
	{
		SetVariantString(positon); 
		AcceptEntityInput(ent, "SetParentAttachment");
	}
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
}

public PreThinkGun(gun)
{
	
	new index=FindGunIndex(gun);
	
	if(index!=-1)
	{
		new Float:time=GetEngineTime( );
		new Float:intervual=time-LastTime[index];  
		LastTime[index]=time; 
		new carrier=GunCarrier[index];
		if(carrier>0)
		{
			if(IsClientInGame(carrier) && IsPlayerAlive(carrier) && !IsFakeClient(carrier))
			{
				Carrying(index, intervual);
			}
			else 
			{
				StopCarry(index);
			}
		}
		else
		{	
			Scan(index, time, intervual); 
		}
			 
	}
}


Scan(index , Float:time, Float:intervual)
{
	new bool:ok=false; 
	new gun1=Gun[index]; 
	if(gun1>0 && IsValidEdict(gun1) && IsValidEntity(gun1) )   ok=true;


	new owner=GunOwner[index];
	if(owner>0 && IsClientInGame(owner))owner=owner+0;
	else owner=0;
	
	if(ok==false || Broken[index])
	{
		if(owner>0)PrintHintText(owner, "Your machine was broke");
		RemoveMachine(index);		 
	}
	Broken[index]=true;
	//PrintToChatAll("index %d", index);

	decl Float:gun1pos[3];
	decl Float:gun1angle[3];
	decl Float:hitpos[3];
	decl Float:temp[3];
	decl Float:shotangle[3];
	decl Float:gunDir[3];
	 
	GetEntPropVector(gun1, Prop_Send, "m_vecOrigin", gun1pos);	
	GetEntPropVector(gun1, Prop_Send, "m_angRotation", gun1angle);	
	
	
	GetAngleVectors(gun1angle, gunDir, NULL_VECTOR, NULL_VECTOR );
	NormalizeVector(gunDir, gunDir);
	CopyVector(gunDir, temp);	
	ScaleVector(temp, 20.0);
	AddVectors(gun1pos, temp ,gun1pos);
	GetAngleVectors(gun1angle, NULL_VECTOR, NULL_VECTOR, temp );
	NormalizeVector(temp, temp);
	//ShowDir(2, gun1pos, temp, 0.06);
	ScaleVector(temp, 43.0);
	AddVectors(gun1pos, temp ,gun1pos);
 
	new newenemy=0;
	if( IsVilidEenmey(GunEnemy[index]))
	{
		newenemy=IsEnemyVisible(gun1, GunEnemy[index], gun1pos, hitpos,shotangle, 3);		
	}
	
	if(InfectedCount>0 && newenemy==0)
	{
		GunScanIndex[index]++;
		if(GunScanIndex[index]>=InfectedCount)
		{
			GunScanIndex[index]=0;
		}
		newenemy=InfectedsArray[GunScanIndex[index]];
		if(IsVilidEenmey(newenemy))
		{
			newenemy=IsEnemyVisible(gun1, InfectedsArray[GunScanIndex[index]], gun1pos, hitpos, shotangle,3);
		}
		
	}
	GunEnemy[index]=newenemy;
	
	
	
	
	decl Float:enemyDir[3]; 
	decl Float:newGunAngle[3]; 
	if(newenemy>0)
	{
		SubtractVectors(hitpos, gun1pos, enemyDir);				
	}
	else
	{
		CopyVector(gunDir, enemyDir); 
		enemyDir[2]=0.0; 
	}
	NormalizeVector(enemyDir,enemyDir);	 
	
	decl Float:targetAngle[3]; 
	GetVectorAngles(enemyDir, targetAngle);
	new Float:diff0=AngleDiff(targetAngle[0], gun1angle[0]);
	new Float:diff1=AngleDiff(targetAngle[1], gun1angle[1]);
	
	//PrintToChatAll("gun %f %f diff %f" ,gun1angle[0], targetAngle[0], diff0);
	new Float:turn0=45.0*Sign(diff0)*intervual;
	new Float:turn1=120.0*Sign(diff1)*intervual;
	if(FloatAbs(turn0)>=FloatAbs(diff0))
	{
		turn0=diff0;
	}
	if(FloatAbs(turn1)>=FloatAbs(diff1))
	{
		turn1=diff1;
	}
	//newGunAngle[0]=gun1angle[0]+5.0 ;
	newGunAngle[0]=gun1angle[0]+turn0;
	newGunAngle[1]=gun1angle[1]+turn1;//=gun1angle[1]+Sign(targetAngle[1]- gun1angle[1])*2.0; 
	 
	newGunAngle[2]=0.0; 
	
	DispatchKeyValueVector(gun1, "Angles", newGunAngle);
	new overheated=GetEntProp(gun1, Prop_Send, "m_overheated");
	
	GetAngleVectors(newGunAngle, gunDir, NULL_VECTOR, NULL_VECTOR);
	new Float:a=GetAngle(gunDir, enemyDir);
	 
	if(overheated==0)
	{
		if( ( a<50.0 && newenemy>0))
		{
			if(time>=GunFireTime[index] )
			{
				GunFireTime[index]=time+FireIntervual;  								
				Shot(owner,gun1, gun1pos, newGunAngle); 
			}
			GunFireStopTime[index]=time+0.5; 
		} 
	}
	new Float:heat=GetEntPropFloat(gun1, Prop_Send, "m_heat");
	FireOverHeatTime=GetConVarFloat(l4d_machine_voerheat);
	if(time<GunFireStopTime[index])
	{
		GunFireTotolTime[index]+=intervual;
		heat=GunFireTotolTime[index]/FireOverHeatTime;
		if(heat>=1.0)heat=1.0;
		SetEntProp(gun1, Prop_Send, "m_firing", 1); 		
		SetEntPropFloat(gun1, Prop_Send, "m_heat", heat);
		//PrintToChatAll("enemy %d fire", newenemy);
	}
	else
	{
		SetEntProp(gun1, Prop_Send, "m_firing", 0);
		GunFireTotolTime[index]=FireOverHeatTime*heat;
		//PrintToChatAll("enemy %d", newenemy);
	}	
	//PrintToChatAll("heat %f",GunFireTotolTime[client]/FireOverHeatTime); 
	Broken[index]=false;
	return;
}
Float:AngleDiff(Float:a, Float:b)
{
	new Float:d=0.0;
	if(a>=b)
	{
		d=a-b;
		if(d>=180.0)d=d-360.0;
	}
	else
	{
		d=a-b;
		if(d<=-180.0)d=360+d;
	}
	return d;
}
Float:Sign(Float:v)
{
	if(v==0.0)return 0.0;
	else if(v>0.0)return 1.0;
	else return -1.0;
}
CheckAngle(Float:angle[3])
{
	for(new i=0; i<3; i++)
	{
		if(angle[i]>360.0)angle[i]=angle[i]-360.0;
		else if(angle[i]<-360.0)angle[i]=angle[i]+360.0;
	}
}
Float:GetAngle(Float:x1[3], Float:x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)))*180.0/Pai;
}
bool:IsVilidEenmey(enemy, team=3)
{	
	new bool:r=false;
	if(enemy>0 && enemy<=MaxClients)
	{
		if(IsClientInGame(enemy) && IsPlayerAlive(enemy) && GetClientTeam(enemy)==team)
		{
			r=true;
		} 
	}
	else if(enemy>0 && IsValidEntity(enemy) && IsValidEdict(enemy))
	{
		decl String:classname[32];
		GetEdictClassname(enemy, classname,32);
		if(StrEqual(classname, "infected", true) )
		{
			r=true;
		} 
	}
	if(r && GetEntProp(enemy, Prop_Data, "m_iHealth")<=0)
	{
		r=false;
	}
	if(!r)InfectedRemove(enemy);
	return r;
}
IsEnemyVisible( gun, ent, Float:gunpos[3], Float:hitpos[3], Float:angle[3] ,team=3)
{	
	new enemy=ent;	
	if(enemy<=MaxClients)
	{	
		GetClientEyePosition( ent, hitpos);
		hitpos[2]-=16.0;
	}
	else
	{
		GetEntPropVector(ent, Prop_Send, "m_vecOrigin", hitpos);
		hitpos[2]+=40.0;
	}
	SubtractVectors(hitpos, gunpos, angle);
	GetVectorAngles(angle, angle);
	//ShowAngle(1, gunpos, angle, 0.06);
	new Handle:trace= TR_TraceRayFilterEx(gunpos, angle, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, gun); 
	new bool:hit=false;
	
	if(TR_DidHit(trace))
	{		 
		TR_GetEndPosition(hitpos, trace);
		enemy=TR_GetEntityIndex(trace); 
		if(GetVectorDistance(gunpos, hitpos)>GetConVarFloat(l4d_machine_range))enemy=0;
		if(enemy>0)
		{	
			 
			if(enemy>0 && enemy<=MaxClients)
			{
				if(IsClientInGame(enemy) && IsPlayerAlive(enemy) && GetClientTeam(enemy)==team)
				{
					enemy=enemy+0;
				}
				else enemy=0;
			}
			else 
			{
				decl String:classname[32];
				GetEdictClassname(enemy, classname,32);
				if(StrEqual(classname, "infected", true) )
				{
					enemy=enemy+0;
				}
				else enemy=0;
			}
		} 
	}
	CloseHandle(trace); 
	return enemy;
}

Shot(client ,gun,  Float:gunpos[3],  Float:shotangle[3])
{		 

	
			
	decl Float:temp[3];
	decl Float:ang[3];
	GetAngleVectors(shotangle, temp, NULL_VECTOR,NULL_VECTOR); 
	NormalizeVector(temp, temp); 
	 
	new Float:acc=0.020;
	temp[0] += GetRandomFloat(-1.0, 1.0)*acc;
	temp[1] += GetRandomFloat(-1.0, 1.0)*acc;
	temp[2] += GetRandomFloat(-1.0, 1.0)*acc;
	GetVectorAngles(temp, ang);
	
	new Handle:trace= TR_TraceRayFilterEx(gunpos, ang, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, gun); 
	new enemy=0;	
	if(TR_DidHit(trace))
	{			
		decl Float:hitpos[3];		 
		TR_GetEndPosition(hitpos, trace);		
		enemy=TR_GetEntityIndex(trace); 

		
		if(enemy>0)
		{			
			decl String:classname[32];
			GetEdictClassname(enemy, classname, 32);	
			if(enemy >=1 && enemy<=MaxClients)
			{
				if(GetClientTeam(enemy)==2) {enemy=0;}		 
			}
			else if(StrContains(classname, "infected")!=-1){ } 	
			else enemy=0;
		} 
		if(enemy>0)
		{
			if(client>0 &&IsPlayerAlive(client))client=client+0;
			else client=0;
			DoPointHurtForInfected(enemy, client);
			decl Float:Direction[3];
			GetAngleVectors(ang, Direction, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(Direction, -1.0);
			GetVectorAngles(Direction,Direction);
			if(!L4D2Version)ShowParticle(hitpos, Direction, PARTICLE_BLOOD, 0.1);
			EmitSoundToAll(SOUND_IMPACT1, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,hitpos, NULL_VECTOR,true, 0.0);
		}
		else
		{		
			decl Float:Direction[3];
			Direction[0] = GetRandomFloat(-1.0, 1.0);
			Direction[1] = GetRandomFloat(-1.0, 1.0);
			Direction[2] = GetRandomFloat(-1.0, 1.0);
			TE_SetupSparks(hitpos,Direction,1,3);
			TE_SendToAll();
			EmitSoundToAll(SOUND_IMPACT2, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,hitpos, NULL_VECTOR,true, 0.0);

		}
		 
		
		ShowMuzzleFlash(gunpos, ang);
		if(L4D2Version)ShowTrack(gunpos, hitpos); 
		else
		{
			ShowPos(0, gunpos, hitpos, 0.06, 0.0, 0.5, 1.0);
		}
	}
	CloseHandle(trace);  
 	
}