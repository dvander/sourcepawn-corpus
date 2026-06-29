#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>


#define Pai 3.14159265358979323846 
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6 



#define MODEL_GUN_M60 "models/w_models/weapons/w_m60.mdl"
#define MODEL_GUN_FOOT "models/props_equipment/oxygentank01.mdl"


#define PARTICLE_MUZZLE_FLASH		"weapon_muzzle_flash_autoshotgun"  
#define PARTICLE_WEAPON_TRACER		"weapon_tracers" 
#define PARTICLE_WEAPON_TRACER2		"weapon_tracers_50cal"//weapon_tracers_50cal" //"weapon_tracers_explosive" weapon_tracers_50cal
 
#define PARTICLE_BLOOD		"blood_impact_red_01"
#define PARTICLE_BLOOD2		"blood_impact_headshot_01"

#define SOUND_IMPACT1		"physics/flesh/flesh_impact_bullet1.wav"  
#define SOUND_IMPACT2		"physics/concrete/concrete_impact_bullet1.wav"  
#define SOUND_FIRE		"weapons/50cal/50cal_shoot.wav"  




#define state_none 0
#define state_carry 1
#define state_work 2
#define state_sleep 3

new ZOMBIECLASS_TANK=	5;
new GameMode;
new L4D2Version; 
 

new Float:LastTime[MAXPLAYERS+1];  
new Float:LastShotTime [MAXPLAYERS+1];
new Float:MiniGunEntForSwitch [MAXPLAYERS+1];
new Float:ShoveDelay [MAXPLAYERS+1];
#define EnemyArraySize 300
new InfectedsArray[EnemyArraySize];
new InfectedCount=0;

new Float:ScanGunTime=0.0;
new GunScanIndex[MAXPLAYERS+1];
new GunEnemy[MAXPLAYERS+1];


#define MiniArraySize 32
new MiniGunArray[MiniArraySize];
new MiniGunGhostController[MiniArraySize];
new MiniGunOwner[MiniArraySize];
new Float:MiniGunPosition[MiniArraySize][3];
new Float:MiniGunAngle[MiniArraySize][3];
new Float:MiniGunOriginAngle[MiniArraySize][3];
new MiniGunType[MiniArraySize];
new MiniGunCount=0;
new Float:ScanEenmyTime=0.0;
 
new Handle:l4d_ai_bullet_damage;
new Handle:l4d_ai_attack_distance;
new Handle:l4d_ai_attack_intervual;
new Handle:l4d_ai_attack_special_infected;
new Handle:l4d_ai_attack_common_infected;

new bool:g_start=false;
new g_PointHurt = 0;
new g_iVelocity = 0;
public Plugin:myinfo = 
{
	name = "AI minigun",
	author = " pan xiao hai",
	description = " ",
	version = "1.0",
	url = "http://forums.alliedmods.net"
}
public OnPluginStart()
{ 	 
	GameCheck(); 	
	
	if(!L4D2Version)return;
	
	HookEvent("player_spawn", player_spawn);	
	HookEvent("player_death", player_death); 

	HookEvent("player_bot_replace", player_bot_replace );	  
	HookEvent("bot_player_replace", bot_player_replace );	
   
	HookEvent("entity_shoved", entity_shoved); 

	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	

	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	
 	
	l4d_ai_bullet_damage = CreateConVar("l4d_ai_bullet_damage", "25", " bullet damage", FCVAR_PLUGIN);
	l4d_ai_attack_distance = CreateConVar("l4d_ai_attack_distance", "1500.0", "", FCVAR_PLUGIN);
	l4d_ai_attack_intervual = CreateConVar("l4d_ai_attack_intervual", "0.1", "time between two shot", FCVAR_PLUGIN);


	l4d_ai_attack_special_infected = CreateConVar("l4d_ai_attack_special_infected", "1", "1 enable, 0 disable", FCVAR_PLUGIN);
	l4d_ai_attack_common_infected = CreateConVar("l4d_ai_attack_common_infected", "1", "1 enable, 0 disable", FCVAR_PLUGIN);	
	
	AutoExecConfig(true, "l4d_ai_gun");  
	ResetAllState();
}




public OnMapStart()
{
	ResetAllState();
 
	if(L4D2Version)
	{
		PrecacheSound(SOUND_IMPACT1);
		PrecacheSound(SOUND_IMPACT2);
		PrecacheSound(SOUND_FIRE);

		PrecacheParticle(PARTICLE_BLOOD);
		PrecacheParticle(PARTICLE_BLOOD2);	
		
		PrecacheParticle(PARTICLE_MUZZLE_FLASH);
		PrecacheParticle(PARTICLE_WEAPON_TRACER);
		PrecacheParticle(PARTICLE_WEAPON_TRACER2);	
			
		PrecacheModel(MODEL_GUN_M60, true);
		PrecacheModel(MODEL_GUN_FOOT, true);
	}
 
} 

public Action:round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	ResetAllState();
}
 
public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{  
	ResetAllState();
} 
ResetAllState( )
{	
	g_start=false;
	g_PointHurt=0;
	InfectedCount= 0;
	ScanEenmyTime = 0.0;
	ScanGunTime = 0.0;
	MiniGunCount=0;
	for(new i=1; i<=MaxClients; i++)
	{
		ResetClientState(i); 
	}
	for(new i=0; i<MiniGunCount; i++)
	{
		MiniGunArray[i]=0;
		MiniGunGhostController[i]=0;
	}
//		new flags = GetConVarFlags(FindConVar("z_max_player_zombies"));
//	SetConVarBounds(FindConVar("z_max_player_zombies"), ConVarBound_Upper, false);
//	SetConVarFlags(FindConVar("z_max_player_zombies"), flags & ~FCVAR_NOTIFY);
	
	for(new i=1; i<=MaxClients; i++)
	{
		if(IsGhostController(i))
		{
			KickClient(i,"");
		}
	}
	
} 
ResetClientState(client)
{
 
 
	GunScanIndex[client]=0;

	LastShotTime[client]=0.0;
	
	GunEnemy[client]=0;
	GunScanIndex[client]=0;
	ShoveDelay[client]=0.0;
}


Give(Client, String:itemId[])
{
	new String:command[] = "give";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", command, itemId);
	SetCommandFlags(command, flags);
}

public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   

	ResetClientState(client);
	ResetClientState(bot);

}
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));  
 
	ResetClientState(client);
	ResetClientState(bot);
  
}
public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));  
	//PrintToChatAll("player_spawn %d %N", client, client);
	if(client>0 && IsFakeClient(client) && GetClientTeam(client)==3)
	{
		new Float:time=GetEngineTime();
		for(new index=0; index<MiniGunCount; index++)
		{
			
			if(MiniGunGhostController[index]==0 && time-LastTime[index]<0.15)
			{
				//PrintToChatAll("%d",MiniGunGhostController[index]);
				SetMiniGunGhostController(index, client);
			}
		}
		
	}
}
 

public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{

	new dead_player = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	
	if(dead_player>0)
	{
		ResetClientState(dead_player); 
	
	}
	else 
	{
		dead_player= GetEventInt(hEvent, "entityid") ; 
	} 

	if(dead_player>0)
	{
		new find_index=-1;
		for(new i=0; i<InfectedCount; i++)
		{
			if(InfectedsArray[i]==dead_player)
			{
				InfectedsArray[i]=InfectedsArray[InfectedCount-1];
				InfectedCount--;
				find_index=i;
				break;
			}
		}
		
		for(new i=1; i<=MaxClients; i++)
		{
			if(GunEnemy[i]==dead_player) 
			{
				GunEnemy[i]=0;
			}
			if(GunScanIndex[i]>=find_index) 
			{
				if(GunScanIndex[i]>0)GunScanIndex[i]--;
			}		
		}
		
	} 


}


GetMinigun(client )
{ 
	new ent= GetClientAimTarget(client, false);
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{			
		decl String:classname[64];
		GetEdictClassname(ent, classname, 64);			
		if(StrEqual(classname, "prop_minigun") || StrEqual(classname, "prop_minigun_l4d1"))
		{
			new Float:client_pos[3];
			GetClientEyePosition(client, client_pos);
			new Float:pos[3];
			GetEntPropVector(ent, Prop_Send, "m_vecOrigin",pos );
			pos[2]+=50.0;
			if(GetVectorDistance(client_pos, pos)>80.0) ent=0;
		}
		else ent=0;
	}  
	return ent;
}
bool:IsMiniGun(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		decl String:classname[64];
		GetEdictClassname(ent, classname, 64);			
		if(StrEqual(classname, "prop_minigun") || StrEqual(classname, "prop_minigun_l4d1"))
		{
			return true;
		}
	}
	return false;
}
GetMiniGunType(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		decl String:classname[64];
		GetEdictClassname(ent, classname, 64);			
		if(StrEqual(classname, "prop_minigun"))return 1;
		else if(StrEqual(classname, "prop_minigun_l4d1"))return 0;
 
	}
	return -1;
}
public Action:entity_shoved(Handle:event, String:event_name[], bool:dontBroadcast)
{
	new attacker  = GetClientOfUserId(GetEventInt(event, "attacker"));
	if(attacker>0 && IsClientInGame(attacker) && GetClientTeam(attacker)==2)
	{		
		new b=GetClientButtons(attacker); 
		new gun=GetMinigun(attacker);
		if(gun>0 &&  GetEngineTime()-ShoveDelay[attacker]>0.5)
		{
			ShoveDelay[attacker]=GetEngineTime();
			MiniGunEntForSwitch[attacker]=gun;
			CreateTimer(0.3, SwitchGunModeTimer, attacker, TIMER_FLAG_NO_MAPCHANGE);
		}  
	}
	return Plugin_Continue;
}

public Action:SwitchGunModeTimer(Handle:timer, any:client)
{
	new gun=MiniGunEntForSwitch[client];
	if(IsMiniGun(gun))
	{
		SwitchGunMode(client, gun);
	} 
	return Plugin_Stop;
	 
}
SwitchGunMode(client,gun)
{
	new gun_user = GetEntPropEnt(gun, Prop_Send, "m_owner");
	if(IsGhostController(gun_user))
	{
		SwitchToManualMode(client,gun,gun_user);
		return;
	}
	
	new ghost_controller = GetEntPropEnt(gun, Prop_Send, "m_hOwnerEntity");
	if(ghost_controller==-1 || ghost_controller==0)
	{
		SwitchToAutoMode(client, gun);
	}
	else //if(IsGhostController(ghost_controller))
	{
		SwitchToManualMode(client,gun,ghost_controller);
	}	


}
SwitchToManualMode(op,gun,ghost_controller)
{
	new index=FindGunIndex(gun);
	if(index>=0)
	{
	
		SetEntPropEnt(gun, Prop_Send, "m_owner", -1);
		SetEntPropEnt(gun, Prop_Send, "m_hOwnerEntity", -1); 
		if(IsGhostController(ghost_controller))KickClient(ghost_controller, "kick ai controller");
		TeleportEntity(gun, NULL_VECTOR, MiniGunOriginAngle[index], NULL_VECTOR);	
		if(MiniGunType[index]==1)
		{
			SetEntPropFloat(gun, Prop_Send, "m_heat", 0);
			SetEntProp(gun, Prop_Send, "m_overheated", 0);
		}
		SetEntProp(gun, Prop_Send, "m_firing", 0); 
		RemoveGunFromIndex(index);
		
		if(op>0)PrintHintText(op, "turn in to manual mode");
	}
}
SwitchToAutoMode(op,gun)
{
	if(MiniGunCount>=MiniArraySize-1)return;
	new index=FindGunIndex(gun);
	if(index>=0)
	{
		RemoveGunFromIndex(index);
	} 
	CreateGhostController(op); 
	 
	SetEntPropEnt(gun, Prop_Send, "m_hOwnerEntity", 0);
 
	MiniGunArray[MiniGunCount]=gun;
	MiniGunOwner[MiniGunCount]=op;
	MiniGunType[MiniGunCount]=GetMiniGunType(gun);
	MiniGunGhostController[MiniGunCount]=0;
	LastTime[MiniGunCount] = GetEngineTime();
	GetEntPropVector(gun, Prop_Send, "m_angRotation", MiniGunAngle[MiniGunCount]);
	GetEntPropVector(gun, Prop_Send, "m_vecOrigin",MiniGunPosition[MiniGunCount] );
	CopyVector(MiniGunAngle[MiniGunCount],MiniGunOriginAngle[MiniGunCount]);
	MiniGunPosition[MiniGunCount][2]+=45.0;

	MiniGunCount++;
	
  
}
SetMiniGunGhostController(index, ghost)
{ 
	
	new mini_gun=MiniGunArray[index];
	SetEntPropEnt(mini_gun, Prop_Send, "m_owner",ghost);	
	SetEntPropEnt(mini_gun, Prop_Send, "m_hOwnerEntity", ghost);
	MiniGunGhostController[index]=ghost;
	
	SetEntityMoveType(ghost, MOVETYPE_NONE);
	SetGhostStatus(ghost, true);
	
	new op=MiniGunOwner[index];
	if(op>0 && IsClientInGame(op))PrintHintText(op, "turn in to auto mode");
}
RemoveGunFromIndex(index)
{
	if(index>=0 && index<MiniGunCount && MiniGunCount>0)
	{
		MiniGunCount--;
		MiniGunArray[index]=MiniGunArray[MiniGunCount];
		MiniGunType[index]=MiniGunType[MiniGunCount];
		MiniGunGhostController[index]=MiniGunGhostController[MiniGunCount];
		MiniGunOwner[index]=MiniGunOwner[MiniGunCount];		
		
		CopyVector(MiniGunPosition[MiniGunCount], MiniGunPosition[index]);
		CopyVector(MiniGunAngle[MiniGunCount], MiniGunAngle[index]);		
		CopyVector(MiniGunOriginAngle[MiniGunCount], MiniGunOriginAngle[index]);
	}

}
FindGunIndex(ent)
{
	for(new i=0; i<MiniGunCount; i++)
	{
		if(MiniGunArray[i]==ent)
		{
			return i;
		}		
	}
	return -1;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	
	if(MiniGunCount<=0)return Plugin_Continue; 
	if(GetClientTeam(client)!=3)return Plugin_Continue; 
	if(!IsFakeClient(client))return Plugin_Continue; 
	if(GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1)==0)return Plugin_Continue; 
	new Float:engine_time= GetEngineTime();	

	new mini_gun_index=-1;
	new mini_gun=0;
	//PrintToChatAll("index %d gun %d controller %N", mini_gun, mini_gun_index, client);
	if(MiniGunCount>0)
	{
		for(new i=0; i<MiniGunCount; i++)
		{
			if(MiniGunGhostController[i]==client)
			{ 
				mini_gun_index=i;
				mini_gun = MiniGunArray[i];
				break;
			}
		} 
	} 
	if(mini_gun_index<0)return Plugin_Continue;
	
	if(IsMiniGun(mini_gun))
	{
		
	}
	else 
	{
 
		RemoveGunFromIndex(mini_gun_index);
		//PrintToChatAll("remove gun , count %d", MiniGunCount);
		return Plugin_Continue;
	}
 
	
	ScanAllEnemy(engine_time);
	
	new Float:duration=engine_time-LastTime[mini_gun_index];
	if(duration>0.1)duration=0.1;
	else if(duration<=0.0)duration=0.005;
	
	new Float:client_eye_position[3];
	GetClientEyePosition(client, client_eye_position);
	
	new Float:client_eye_angle[3];
	GetClientEyeAngles(client, client_eye_angle);
	 
	TrackGun(client, mini_gun_index, engine_time,duration); 
  

	LastTime[mini_gun_index]=engine_time;
	

	return Plugin_Continue;
}
TrackGun(client,mini_gun_index,Float:engine_time, Float:duration)
{
	decl Float:gun_pos[3];
	CopyVector(MiniGunPosition[mini_gun_index],gun_pos);
	decl Float:gun_angle[3];
	CopyVector(MiniGunAngle[mini_gun_index],gun_angle);
	
	new mini_gun=MiniGunArray[mini_gun_index];
	new op=MiniGunOwner[mini_gun_index];
	
	new import_enemy=GetFrontEnemy(mini_gun, gun_pos, gun_angle);
	new bool:need_shot=false;
	if(import_enemy>0)
	{
		need_shot=true;
	}
	
	
	new bool:have_new_enemy=false;
	// get a new enmey 
	if(GunEnemy[client] == 0 && InfectedCount>0)
	{
		if(GunScanIndex[client]>=InfectedCount)
		{
			GunScanIndex[client]=0;
		}
		GunEnemy[client]=InfectedsArray[GunScanIndex[client]];
		GunScanIndex[client]++; 
	}
	

	// ensure the enemy is valid.
	decl Float:enemy_pos[3];
	if( IsInfectedTeam(GunEnemy[client] ))
	{ 
		GetEnemyPostion(GunEnemy[client], enemy_pos);
		new newenemy=GetEnemyIfVisible(mini_gun,GunEnemy[client], gun_pos, enemy_pos);	
		if(GunEnemy[client]!=newenemy)
		{
			GunEnemy[client]=0;
			if(newenemy!=0)need_shot=true;
		}
	}
	else GunEnemy[client]=0;
	
	//GunEnemy[client]=1;
	//GetEnemyPostion(GunEnemy[client], enemy_pos);
	if(GunEnemy[client]>0)
	{
		decl Float:target_angle[3];
		SubtractVectors(enemy_pos,gun_pos,target_angle);
		GetVectorAngles(target_angle,target_angle);
		
		//PrintVector("gun angle", target_angle);
		
		
		
		//GetClientEyeAngles(client, target_angle);
		//PrintVector("cli angle", target_angle);
		

		new Float:diff0=AngleDiff(target_angle[0], gun_angle[0]);
		new Float:diff1=AngleDiff(target_angle[1], gun_angle[1]);
		
		
		new Float:turn0=45.0*Sign(diff0)*duration;
		new Float:turn1=90.0*Sign(diff1)*duration;
		if(FloatAbs(turn0)>=FloatAbs(diff0))
		{
			turn0=diff0;
		}
		if(FloatAbs(turn1)>=FloatAbs(diff1))
		{
			turn1=diff1;
		}
		 
		target_angle[0]=gun_angle[0]+turn0;
		target_angle[1]=gun_angle[1]+turn1; 
		target_angle[2]=0.0; 
		
		if(FloatAbs(diff1)<50.0 )need_shot=true;
			
		//TrunGun(client, target_angle);
		decl Float:temp_pos[3];
		CopyVector(MiniGunPosition[mini_gun_index],temp_pos);
		temp_pos[2]-=150.0;
		TeleportEntity(client, temp_pos, target_angle,NULL_VECTOR);
		CopyVector(target_angle, MiniGunAngle[mini_gun_index]);
				
	 	
		decl Float:gun_origin_angle[3]; 
		decl Float:gun_target_angle[3]; 
		CopyVector(target_angle,gun_target_angle);
		GetEntPropVector(mini_gun, Prop_Send, "m_angRotation", gun_origin_angle);
		gun_target_angle[0]=0.0;
		gun_origin_angle[0]=0.0;
		new Float:angle = GetAngle(gun_target_angle, gun_origin_angle)*180.0/Pai;		
				
		if(angle>89.0)
		{
			TeleportEntity(mini_gun, NULL_VECTOR, gun_target_angle,NULL_VECTOR);		
		}
		
	}
	else 
	{
		TeleportEntity(client, NULL_VECTOR, MiniGunAngle[mini_gun_index],NULL_VECTOR);
	}
	new gun_type=MiniGunType[mini_gun_index];
	if(need_shot)
	{
		//new overheated=GetEntProp(mini_gun, Prop_Send, "m_overheated");
		new Float:heat=GetEntPropFloat(mini_gun, Prop_Send, "m_heat"); 
		if(gun_type==0) 
		{
			if(heat>0.95)SetEntPropFloat(mini_gun, Prop_Send, "m_heat", 0.95);
		}
		else 
		{
			SetEntPropFloat(mini_gun, Prop_Send, "m_heat", 0.95);
			SetEntProp(mini_gun, Prop_Send, "m_overheated", 1);
		}
		
		SetEntProp(mini_gun, Prop_Send, "m_firing", 1); 
		if(engine_time-LastShotTime[client]>=GetConVarFloat(l4d_ai_attack_intervual))
		{
			LastShotTime[client]=engine_time;
			Shot(op, gun_pos, gun_angle , gun_type,mini_gun);


		}
	}
	else
	{
		if(engine_time-LastShotTime[client]>=1.0)
		{
			SetEntProp(mini_gun, Prop_Send, "m_firing", 0); 
			if(gun_type==1)
			{
				SetEntPropFloat(mini_gun, Prop_Send, "m_heat", 0);
				SetEntProp(mini_gun, Prop_Send, "m_overheated", 0);
			}		
		}

	}
	 
}

TrunGun(client, Float:target_angle[3])
{
 
 	

	 
}

Shot(client, Float:gunpos[3],  Float:shotangle[3],gun_type, mini_gun)
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

	new Handle:trace= TR_TraceRayFilterEx(gunpos, ang, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, mini_gun); 
	new enemy=0;	
	 
	if(TR_DidHit(trace))
	{			
		decl Float:hitpos[3];		 
		TR_GetEndPosition(hitpos, trace);		
		enemy=TR_GetEntityIndex(trace); 
		
		new bool:blood=false;
		if(IsInfectedTeam(enemy))
		{
		} 
		else enemy=0;
		
		if(enemy>0)
		{
			new attacker=0;
			if(client>0 &&IsPlayerAlive(client))attacker=client;
			if(IsInfectedTeam(enemy))DoPointHurtForInfected(enemy, attacker, GetConVarInt(l4d_ai_bullet_damage));
			decl Float:Direction[3];
			GetAngleVectors(ang, Direction, NULL_VECTOR, NULL_VECTOR);
			ScaleVector(Direction, -1.0);
			GetVectorAngles(Direction,Direction);
			//if(!L4D2Version || blood)ShowParticle(hitpos, Direction, PARTICLE_BLOOD, 0.1);			
			EmitSoundToAll(SOUND_IMPACT1, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,hitpos, NULL_VECTOR,true, 0.0);
		}
		else
		{		
			/*
			decl Float:Direction[3];
			Direction[0] = GetRandomFloat(-1.0, 1.0);
			Direction[1] = GetRandomFloat(-1.0, 1.0);
			Direction[2] = GetRandomFloat(-1.0, 1.0);
			TE_SetupSparks(hitpos,Direction,1,3);
			TE_SendToAll();
			*/
			EmitSoundToAll(SOUND_IMPACT2, 0,  SNDCHAN_AUTO, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,hitpos, NULL_VECTOR,true, 0.0);

		}
		 
		
		if(gun_type==0)ShowMuzzleFlash(gunpos, ang, 20.0 );
		else ShowMuzzleFlash(gunpos, ang, 50.0 );
		
		ShowTrack(gunpos, hitpos); 

		if(gun_type==1)EmitSoundToAll(SOUND_FIRE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,gunpos, NULL_VECTOR,true, 0.0);
	}
	
	CloseHandle(trace);  
 	
}


ShowMuzzleFlash(Float:gunpos[3],  Float:angle[3], Float:offset)
{  
	new Float:pos[3];
	new Float:vec[3];
	CopyVector(gunpos,pos);
	GetAngleVectors(angle, vec, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vec,vec);
	ScaleVector(vec, offset);
	AddVectors(vec, pos, vec);
	
 	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_MUZZLE_FLASH); 
	DispatchSpawn(particle);
	ActivateEntity(particle); 
	TeleportEntity(particle, vec, angle, NULL_VECTOR);
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
GetEnemyIfVisible(mini_gun, enemy, Float:gun_pos[3], Float:enmey_pos[3])
{	
	if(GetVectorDistance(gun_pos,enmey_pos)>GetConVarFloat(l4d_ai_attack_distance))return 0;
 	new Float:angle[3]; 
	SubtractVectors(enmey_pos, gun_pos, angle);
	GetVectorAngles(angle, angle); 
	new Handle:trace=TR_TraceRayFilterEx(gun_pos, enmey_pos, MASK_SHOT, RayType_EndPoint, TraceRayDontHitSelf, mini_gun); 	 

	new newenemy=0;
	 
	if(TR_DidHit(trace))
	{		 
		newenemy=TR_GetEntityIndex(trace);  		
	}
	else 
	{
		CloseHandle(trace);
		return enemy;
	}
	CloseHandle(trace); 
	
	if(newenemy==0)return 0;
	if(newenemy == enemy)return enemy;

	if(IsInfectedTeam(newenemy))
	{
		return newenemy;
	}	
	return 0; 
}

GetFrontEnemy(mini_gun, Float:gun_pos[3], Float:gun_angle[3])
{

	new Handle:trace=TR_TraceRayFilterEx(gun_pos, gun_angle, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, mini_gun); 	 
	
	new enemy=0;
	if(TR_DidHit(trace))
	{		 
		enemy=TR_GetEntityIndex(trace); 
	} 
	CloseHandle(trace); 
	if(!IsInfectedTeam(enemy))enemy=0;
	return enemy;
} 


GetEnemyPostion(entity, Float:position[3])
{
	if(entity<=MaxClients) GetClientAbsOrigin(entity, position);
	else GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2]+=35.0; 
}



ScanAllEnemy(Float:time)
{
	if(time-ScanEenmyTime>1.0)
	{
		ScanEenmyTime=time; 
		InfectedCount = 0;
		if(GetConVarInt(l4d_ai_attack_special_infected)>0)
		{
			for(new i=1 ; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==3 && GetEntData(i, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1)==0)
				{
					new class = GetEntProp(i, Prop_Send, "m_zombieClass"); 
					if(class==ZOMBIECLASS_TANK)continue;
					InfectedsArray[InfectedCount++]=i;
				}
			}
		}
		if(GetConVarInt(l4d_ai_attack_common_infected)>0)
		{
			new ent=-1;
			while ((ent = FindEntityByClassname(ent,  "infected" )) != -1 && InfectedCount<EnemyArraySize-1)
			{
				InfectedsArray[InfectedCount++]=ent;
			} 
		}
	}
}

IsEnemyVisible(client, infected, Float:client_position[3])
{	

 	new Float:angle[3];
	new Float:enemy_position[3];
	if(infected<=MaxClients) GetClientAbsOrigin(infected, enemy_position);
	else GetEntPropVector(infected, Prop_Send, "m_vecOrigin", enemy_position);
	enemy_position[2]+=35.0; 
	if(GetVectorDistance(enemy_position, client_position)>g_max_attack_distance)return 0;
	
	SubtractVectors(enemy_position, client_position, angle);
	GetVectorAngles(angle, angle); 
	new Handle:trace=TR_TraceRayFilterEx(client_position, angle, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf, client); 	 

	new newenemy=0;
	 
	if(TR_DidHit(trace))
	{		 

		newenemy=TR_GetEntityIndex(trace);  		
	}
	CloseHandle(trace); 
	if(newenemy==0)return 0;
	if(newenemy == infected)return infected;

	if(IsInfectedTeam(newenemy))
	{
		return newenemy;
	}	
	return 0;
}

GetClientFrontEnemy(client, Float:client_postion[3], Float:range)
{
	new enemy_id=GetClientAimTarget(client, false);

	if(IsInfectedTeam(enemy_id)) 
	{
		new Float:enemy_position[3];
		GetEntPropVector(enemy_id, Prop_Send, "m_vecOrigin", enemy_position);
		return enemy_id;
	}
	return 0;
}
Float:GetRange(enemy_id, Float:human_position[3], Float:enemy_position[3])
{		
	GetEntPropVector(enemy_id, Prop_Send, "m_vecOrigin", enemy_position);
	enemy_position[2]+=50.0;
	new Float:dis=GetVectorDistance(enemy_position, human_position);
	
	return dis;
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

GameCheck()
{
	decl String:GameName[16];
	GetConVarString(FindConVar("mp_gamemode"), GameName, sizeof(GameName));
	//PrintToChatAll("mp_gamemode = %s", GameName);
	
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
	L4D2Version=!!L4D2Version;
}

GetLookPosition(client, Float:pos[3], Float:angle[3], Float:hitpos[3])
{
	
	new Handle:trace=TR_TraceRayFilterEx(pos, angle, MASK_ALL, RayType_Infinite, TraceRayDontHitSelf, client); 

	if(TR_DidHit(trace))
	{		
	
		TR_GetEndPosition(hitpos, trace);
		
	}
	CloseHandle(trace);  
	
}

ScanEnemy(client, infected, Float:client_postion[3], Float:angle)
{	

	new Float:angle_vec[3] ;
	new Float:postion[3];
	CopyVector(client_postion,postion);
	postion[2]-=20.0;

	angle_vec[0]=angle_vec[1]=angle_vec[2]=0.0;
	angle_vec[1]=angle;
	//GetEntPropVector(ent, Prop_Send, "m_vecOrigin", hitpos);
	//PrintToChatAll("%f %f", dir[0], dir[1]);
	new Handle:trace=TR_TraceRayFilterEx(postion, angle_vec, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelfAndHuman, infected); 	 
	
	new newenemy=0;
	if(TR_DidHit(trace))
	{		 
		newenemy=TR_GetEntityIndex(trace); 
	} 
	CloseHandle(trace); 
	if(!IsInfectedTeam(newenemy))newenemy=0;
	return newenemy;
}
bool:IsInfectedTeam(ent)
{
	if(ent>0)
	{		 
		if(ent<=MaxClients)
		{
			if(IsClientInGame(ent) && IsPlayerAlive(ent) && GetClientTeam(ent)==3 && GetEntData(ent, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1)==0)
			{
				return true;
			}
		}
		else if(IsValidEntity(ent) && IsValidEdict(ent))
		{
			
			decl String:classname[32];
			GetEdictClassname(ent, classname,32);
			
			if(StrEqual(classname, "infected", true) || StrEqual(classname, "witch", true) )
			{
				return true;
			}
		}
	} 
	return false;
}
public bool:TraceRayDontHitSelfAndHuman(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	if(entity<=MaxClients && entity>0)
	{
		if(IsClientInGame(entity) && IsPlayerAlive(entity) && GetClientTeam(entity)==2)
		{
			return false; 
		}
	}
	return true;
} 
public bool:TraceRayDontHitSelf(entity, mask, any:data)
{
	if(entity == data) 
	{
		return false; 
	} 
	
	return true;
} 
 
public bool:TraceRayDontHitAlive(entity, mask, any:data)
{
	if(entity==0)return false;
	if(entity == data) 
	{
		return false; 
	} 
	if(entity<=MaxClients && entity>0)
	{
		return false;  
	}
	else 
	{
		decl String:classname[32];
		GetEdictClassname(entity, classname,32);
		if(StrEqual(classname, "infected", true) || StrEqual(classname, "witch", true) )
		{
			return false;  
		}
	}
	return true;
} 
CreatePointHurt()
{
	new pointHurt=CreateEntityByName("point_hurt");
	if(pointHurt)
	{

		DispatchKeyValue(pointHurt,"Damage","10");
		DispatchKeyValue(pointHurt,"DamageType","2");
		DispatchSpawn(pointHurt);
	}
	return pointHurt;
}
new String:N[20];
DoPointHurtForInfected(victim, attacker=0,  damage=0)
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
				//DispatchKeyValue(g_PointHurt,"classname","");
				DispatchKeyValueFloat(g_PointHurt,"Damage", damage*1.0);
				DispatchKeyValue(g_PointHurt,"DamageType","-2130706430");
				AcceptEntityInput(g_PointHurt,"Hurt",(attacker>0)?attacker:-1);
			}
		}
		else g_PointHurt=CreatePointHurt();
	}
	else g_PointHurt=CreatePointHurt();
}

stock SetupProgressBar(client, Float:time)
{
	//KillProgressBar(client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", time);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", client);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", client);

}

stock KillProgressBar(client)
{
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", -1);
	//SetEntityMoveType(client, MOVETYPE_WALK);
	//SetEntPropEnt(client, Prop_Send, "m_reviveTarget", 0);
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", GetGameTime());
	SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
	//SetEntPropEnt(client, Prop_Send, "m_reviveOwner", 0);
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
		 if (StrEqual(classname, "info_particle_target", false))
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

 
RemoveEnt(ent)
{

	if(ent>0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		RemoveEdict(ent);
	}
}

 

Float:Sign(Float:v)
{
	if(v==0.0)return 0.0;
	else if(v>0.0)return 1.0;
	else return -1.0;
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

Glow(ent, bool:glow)
{
	if(L4D2Version)
	{
		if (ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
		{
			if(glow)
			{
				SetEntProp(ent, Prop_Send, "m_iGlowType", 3 ); //3
				SetEntProp(ent, Prop_Send, "m_nGlowRange", 0 ); //0
				SetEntProp(ent, Prop_Send, "m_glowColorOverride", 256*100); //1	
			}
			else 
			{
				SetEntProp(ent, Prop_Send, "m_iGlowType", 0 ); //3
				SetEntProp(ent, Prop_Send, "m_nGlowRange", 0 ); //0
				SetEntProp(ent, Prop_Send, "m_glowColorOverride", 0); //1	
			}
			
		
		}
	
	}
}

SpawnCommand(client, String:command[], String:arguments[] = "")
{
	if (client)
	{ 
		new flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		FakeClientCommand(client, "%s %s", command, arguments);
		SetCommandFlags(command, flags);
	}
} 

CreateGhostController(op)
{ 
	new bot = CreateFakeClient("Monster");
	if (bot > 0)	
	{	 
		ChangeClientTeam(bot,3);   
		SpawnCommand(bot, "z_spawn", "jockey"); 
		KickClient(bot);
	}	  

}


RemoveGhostController(ghost)
{
	if(IsGhostController(ghost))
	{
		KickClient(ghost,"");
	}
}
IsGhostController(ghost)
{
	if(ghost>0 && IsClientInGame(ghost) && IsFakeClient(ghost) && GetClientTeam(ghost)==3 && GetGhostStatus(ghost))
	{
		return true;
	}
	return false;
}
bool:GetGhostStatus(client)
{
	return GetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1);
}
SetGhostStatus (client, bool:ghost)
{
	if(client>0 && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client)==3 )
	{
		if (ghost)
		{	
			SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 1, 1, true);
		}
		else
		{
			SetEntData(client, FindSendPropInfo("CTerrorPlayer", "m_isGhost"), 0, 1, false);
		}	
	}

}

Float:GetAngle(Float:x1[3], Float:x2[3])
{
	decl Float:a[3];
	decl Float:b[3];
	 
	GetAngleVectors(x1, a, NULL_VECTOR, NULL_VECTOR);
	//NormalizeVector(a, a);
	//GetVectorAngles(a, a);
	//NormalizeVector(a,a); 
	
	GetAngleVectors(x2, b, NULL_VECTOR, NULL_VECTOR);
	
	//NormalizeVector(b, b);
	//GetVectorAngles(b, b);
	//NormalizeVector(b,b); 
	
	return ArcCosine(GetVectorDotProduct(a, b)/(GetVectorLength(a)*GetVectorLength(b)));
}
