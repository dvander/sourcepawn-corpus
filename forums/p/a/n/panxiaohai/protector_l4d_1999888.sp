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


 

new bool:HaveProtector[MAXPLAYERS+1];
new ProtectorState[MAXPLAYERS+1];
new GunModelHead[MAXPLAYERS+1];
new GunModelFoot[MAXPLAYERS+1];
new GunModelOnBack[MAXPLAYERS+1];
new Float:ProtectorPosition[MAXPLAYERS+1][3];
new Float:ProtectorAngle[MAXPLAYERS+1][3];

new BulletRemain[MAXPLAYERS+1];
new LastButton[MAXPLAYERS+1];
new Float:LastTime[MAXPLAYERS+1]; 

new Float:LastShotTime [MAXPLAYERS+1];
new Float:TimerIndicator [MAXPLAYERS+1]; 
 
#define EnemyArraySize 300
new InfectedsArray[EnemyArraySize];
new InfectedCount;
new Float:ScanTime=0.0;
new GunScanIndex[MAXPLAYERS+1];
new GunEnemy[MAXPLAYERS+1];

new Handle:l4d_protector_bullet_count;
new Handle:l4d_protector_bullet_damage;
new Handle:l4d_protector_attack_distance;
new Handle:l4d_protector_attack_intervual;
new Handle:l4d_protector_attack_special_infected;
new Handle:l4d_protector_attack_common_infected;

new g_PointHurt = 0;
new g_iVelocity = 0;
public Plugin:myinfo = 
{
	name = "protector",
	author = " pan xiao hai",
	description = " ",
	version = "1.2",
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
	HookEvent("player_use", player_use);  

	HookEvent("round_start", round_end);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);	
	RegConsoleCmd("sm_protector", sm_protector);
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	
 	l4d_protector_bullet_count = CreateConVar("l4d_protector_bullet_count", "1000", " bullet count", FCVAR_PLUGIN);
	l4d_protector_bullet_damage = CreateConVar("l4d_protector_bullet_damage", "25", " bullet damage", FCVAR_PLUGIN);
	l4d_protector_attack_distance = CreateConVar("l4d_protector_attack_distance", "1500.0", "", FCVAR_PLUGIN);
	l4d_protector_attack_intervual = CreateConVar("l4d_protector_attack_intervual", "0.1", "time between two shot", FCVAR_PLUGIN);


	l4d_protector_attack_special_infected = CreateConVar("l4d_protector_attack_special_infected", "1", "1 enable, 0 disable", FCVAR_PLUGIN);
	l4d_protector_attack_common_infected = CreateConVar("l4d_protector_attack_common_infected", "1", "1 enable, 0 disable", FCVAR_PLUGIN);	
	
	AutoExecConfig(true, "l4d_protector");  
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
	g_PointHurt=0;
	InfectedCount= 0;
	ScanTime = 0.0;
	for(new i=1; i<=MaxClients; i++)
	{
		ResetClientState(i); 
	}
} 
ResetClientState(client)
{
	BulletRemain[client]=0;

	LastButton[client]=0;
	GunScanIndex[client]=0;
	HaveProtector[client]=false;
	GunModelHead[client]=0;	
	GunModelFoot[client]=0;	
	GunModelOnBack[client]=0;
	LastShotTime[client]=0.0;
	
	GunEnemy[client]=0;
	GunScanIndex[client]=0;
	
}
public Action:player_use(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new ent=GetEventInt(hEvent, "targetid"); 
	if(IsM60(ent) && !HaveProtector[client])
	{	
		BuildMenu(client, ent);
	}
 
}
public Action:sm_protector(client,args)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(!HaveProtector[client])
		{
			CreateProtector(client);
		}
		else 
		{
			RemoveProtector(client);
		}
	}
}
Give(Client, String:itemId[])
{
	new String:command[] = "give";
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	FakeClientCommand(Client, "%s %s", command, itemId);
	SetCommandFlags(command, flags);
}
public Action:BuildMenu( client , ent)
{	 
	new Handle:menu = CreateMenu(MenuSelector1);
	SetMenuTitle(menu, "Do you want to build an automatic machine?"); 
	AddMenuItem(menu, "Yes", "Yes");
	AddMenuItem(menu, "No", "No"); 
	SetMenuExitButton(menu, true);
	 
	DisplayMenu(menu, client, 5); 
}
public MenuSelector1(Handle:menu, MenuAction:action, client, param2)
{
	
	if (action == MenuAction_Select)
	{ 
		decl String:item[256], String:display[256];		
		GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));		
		if (StrEqual(item, "Yes"))
		{
			if( !HaveProtector[client])
			{
				SetupProgressBar(client, 5.0);
				 
				TimerIndicator[client]=GetEngineTime()+5.0;
				CreateTimer(0.1, BuildAutoGunTimer, client, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
			}
		}
		else if(StrEqual(item, "No"))
		{
		}
	}
	 
}

public Action:BuildAutoGunTimer(Handle:timer, any:client)
{
	if(!(IsClientInGame(client) && IsPlayerAlive(client)))
	{
		return Plugin_Stop;
	}

	if(HaveM60(client) && !HaveProtector[client])
	{
		if(GetEngineTime()>=TimerIndicator[client])
		{
			PrintHintText(client, "Build protector successfully, Press E+Zoom");
			CreateProtector(client);
			return Plugin_Stop;
		}
		if(!L4D2Version)PrintCenterText(client, "build progress %d ", RoundFloat((5.0-(TimerIndicator[client]-GetEngineTime()))/5.0*100.0 ));
	}
	else
	{
		
		if(L4D2Version)KillProgressBar(client);
		return Plugin_Stop;
	}
	return Plugin_Continue;
}
 
IsM60(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		decl String:name[50];
		GetEdictClassname(ent, name, 50);
		if(StrEqual( name, "weapon_rifle_m60") )	return true;

	}
	return false;
}
HoldM60(client)
{
	decl String:name[50];
	GetClientWeapon(client, name, 50);
	if(StrEqual( name, "weapon_rifle_m60") )	return true;
	return false;
}
HaveM60(client)
{
	decl String:name[50];

	new ent=GetPlayerWeaponSlot(client, 0);
	if(ent>0)
	{
		GetEdictClassname(ent, name, 50);
		if(StrEqual( name, "weapon_rifle_m60") )	return true;
	}
	return false;
}
RemoveM60(client)
{
	decl String:name[50];

	new ent=GetPlayerWeaponSlot(client, 0);
	if(ent>0)
	{
		GetEdictClassname(ent, name, 50);
		if(StrEqual( name, "weapon_rifle_m60") )
		{
			RemovePlayerItem(client, ent);
		}
	}
	return false;
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
	if(HaveProtector[client])
	{
		RemoveProtector(client);
	}
	ResetClientState(client);
	ResetClientState(bot);

}
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));  
	if(HaveProtector[client])
	{
		RemoveProtector(client);
	}
	ResetClientState(client);
	ResetClientState(bot);
  
}
public Action:player_spawn(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));  
	ResetClientState(client);
	 	
}
 

public Action:player_death(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{

	new dead_player = GetClientOfUserId(GetEventInt(hEvent, "userid")); 
	
	if(dead_player>0)
	{
		if(HaveProtector[dead_player])
		{
			RemoveProtector(dead_player);
		}
	
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


RemoveProtector(client)
{
	
	if(!HaveProtector[client])return;
	
	HaveProtector[client]=false;
	RemoveEnt(GunModelFoot[client]);
	RemoveEnt(GunModelHead[client]);
	RemoveEnt(GunModelOnBack[client]);
	
	ResetClientState(client);
	if(client>0 && IsClientInGame(client))PrintToChatAll("Remove %N 's protector", client);
}

CreateProtector(client)
{
	if(HaveProtector[client])return;
	if(HaveM60(client)) RemoveM60(client); 
	
	HaveProtector[client]=true;
	GunModelFoot[client] = 0;
	GunModelHead[client] = 0;
	GunModelOnBack[client]= 0;
	GunEnemy[client]=0;
	GunScanIndex[client]=0;
	BulletRemain[client]=GetConVarInt(l4d_protector_bullet_count);
	
	LastButton[client]=0;
	LastShotTime[client]=LastTime[client]=GetEngineTime();
	
	GoWork(client); 
	PrintToChatAll("%N build a protector", client);
}
GoBack(client)
{
	ProtectorState[client] = state_carry;
	
	RemoveEnt(GunModelFoot[client]);
	RemoveEnt(GunModelHead[client]);
	
	GunModelFoot[client] = 0;
	GunModelHead[client] = 0;

	GunModelOnBack[client]=CreateOnBack(client);
}
GoWork(client)
{
	ProtectorState[client] = state_work;
	RemoveEnt(GunModelOnBack[client]);
	GunModelOnBack[client]=0;
	
	new Float:gun_pos[3];
	GetClientAbsOrigin(client, gun_pos); 
	
	new Float:gun_angle[3];
	GetClientEyeAngles(client, gun_angle);
	
	new Float:vec[3];
	CopyVector(gun_angle,vec);
	vec[0]=0.0;
	GetAngleVectors(vec, vec, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vec,vec);
	ScaleVector(vec,20.0);
	AddVectors(gun_pos,vec,gun_pos);
	
	GunModelFoot[client] = CreateFoot(client, gun_pos);
	GunModelHead[client] = CreateHead(GunModelFoot[client]);
	gun_pos[2]+=28.0;
	CopyVector(gun_pos, ProtectorPosition[client]);
	TrunGun(client, gun_angle);
}
TrunGun(client, Float:target_angle[3])
{
	new Float:pos[3];
	new Float:ang[3];
 
	CopyVector(target_angle,ang);
	ang[0]=0.0;
	//ang[1]=0.0;
	ang[2]=0.0;
	TeleportEntity(GunModelFoot[client], NULL_VECTOR,ang,NULL_VECTOR);	

	CopyVector(target_angle,ang);

	//ang[0]=0.0;
	ang[1]=0.0;
	ang[2]=0.0;
	TeleportEntity(GunModelHead[client], NULL_VECTOR,ang,NULL_VECTOR);	
	
	
	CopyVector(target_angle, ProtectorAngle[client]);
	 
}
public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!HaveProtector[client])return Plugin_Continue; 
	new Float:engine_time= GetEngineTime();
	if(ProtectorState[client] == state_work )ScanAllEnemy(engine_time);
	
	new Float:duration=engine_time-LastTime[client];
	if(duration>1.0)duration=1.0;
	else if(duration<=0.0)duration=0.01;
		
	new last_button=LastButton[client];
	
	new Float:client_eye_position[3];
	GetClientEyePosition(client, client_eye_position);
	
	new Float:client_eye_angle[3];
	GetClientEyeAngles(client, client_eye_angle);
	
	if((buttons & IN_USE) && (buttons & IN_ZOOM) && !(last_button & IN_ZOOM) )
	{
		if(ProtectorState[client]==state_carry && (GetEntityFlags(client) & FL_ONGROUND))
		{
			GoWork(client);
			PrintHintText(client, "Protector is searching enemy, bullet %d", BulletRemain[client]);
		}
		else if(ProtectorState[client]==state_work)
		{
			if(GetVectorDistance(client_eye_position, ProtectorPosition[client])<70.0)
			{
				GoBack(client);
				PrintHintText(client, "Protector is on your back, bullet %d", BulletRemain[client]);
			}
		}
	} 
	
	if(ProtectorState[client]==state_work)
	{
		TrackGun(client,engine_time,duration); 
	}


	LastButton[client]=buttons;
	LastTime[client]=engine_time;
	
	if(BulletRemain[client]<=0)
	{
		RemoveProtector(client);
	}
	return Plugin_Continue;
}
TrackGun(client, Float:engine_time, Float:duration)
{
	decl Float:gun_pos[3];
	CopyVector(ProtectorPosition[client],gun_pos);
	decl Float:gun_angle[3];
	CopyVector(ProtectorAngle[client],gun_angle);
	
	new import_enemy=GetFrontEnemy(client, gun_pos, gun_angle);
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
		new newenemy=GetEnemyIfVisible(client,GunEnemy[client], gun_pos, enemy_pos);	
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
			
		TrunGun(client, target_angle);
		
		
	}
	if(need_shot)
	{
		if(engine_time-LastShotTime[client]>=GetConVarFloat(l4d_protector_attack_intervual))
		{
			LastShotTime[client]=engine_time;
			Shot(client, gun_pos, gun_angle );
			BulletRemain[client]--;
			if(BulletRemain[client]%10==0)
			{
				PrintCenterText(client, "protector's bullet %d", BulletRemain[client]);
			}
		}
	}
	
	
	//TrunGun(client, client_eye_angle);
}


Shot(client, Float:gunpos[3],  Float:shotangle[3])
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

	new Handle:trace= TR_TraceRayFilterEx(gunpos, ang, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, 0); 
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
			if(IsInfectedTeam(enemy))DoPointHurtForInfected(enemy, attacker, GetConVarInt(l4d_protector_bullet_damage));
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
		 
		
		ShowMuzzleFlash(gunpos, ang);
		ShowTrack(gunpos, hitpos); 

		EmitSoundToAll(SOUND_FIRE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS,1.0, SNDPITCH_NORMAL, -1,gunpos, NULL_VECTOR,true, 0.0);
	}
	
	CloseHandle(trace);  
 	
}


ShowMuzzleFlash(Float:pos[3],  Float:angle[3])
{  
	new Float:vec[3];
	GetAngleVectors(angle, vec, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(vec,vec);
	ScaleVector(vec, 30.0);
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
GetEnemyIfVisible(client, enemy, Float:gun_pos[3], Float:enmey_pos[3])
{	
	if(GetVectorDistance(gun_pos,enmey_pos)>GetConVarFloat(l4d_protector_attack_distance))return 0;
 	new Float:angle[3]; 
	SubtractVectors(enmey_pos, gun_pos, angle);
	GetVectorAngles(angle, angle); 
	new Handle:trace=TR_TraceRayFilterEx(gun_pos, enmey_pos, MASK_SHOT, RayType_EndPoint, TraceRayDontHitSelf, 0); 	 

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

GetFrontEnemy(client, Float:gun_pos[3], Float:gun_angle[3])
{

	new Handle:trace=TR_TraceRayFilterEx(gun_pos, gun_angle, MASK_SHOT, RayType_Infinite, TraceRayDontHitSelf, 0); 	 
	
	new enemy=0;
	if(TR_DidHit(trace))
	{		 
		enemy=TR_GetEntityIndex(trace); 
	} 
	CloseHandle(trace); 
	if(!IsInfectedTeam(enemy))enemy=0;
	return enemy;
}









CreateHead(foot)
{
		
	new ent= CreateEntityByName("prop_dynamic_override");
	SetEntityModel(ent, MODEL_GUN_M60);
	DispatchSpawn(ent);
	
	decl String:tName[128];
	Format(tName, sizeof(tName), "target%d",foot );
	DispatchKeyValue(foot , "targetname", tName);		
	
 	SetVariantString(tName);
	AcceptEntityInput(ent, "SetParent", ent, ent, 0);
	
	
	new Float:vec_pos[3];
	new Float:vec_ang[3];
	
	SetVector(vec_pos, 0.0, 0.0, 28.0);
	SetVector(vec_ang, 0.0, 0.0, 0.0);
	
	TeleportEntity(ent, vec_pos,vec_ang,NULL_VECTOR);	
	DispatchKeyValueFloat(ent, "fademindist", 10000.0);
	DispatchKeyValueFloat(ent, "fademaxdist", 20000.0);
	DispatchKeyValueFloat(ent, "fadescale", 0.0); 
	
	Glow(foot, true);
	Glow(ent, true);
	return ent;
}
CreateFoot(client,	Float:pos[3])
{
	new jetpack=CreateEntityByName("prop_dynamic_override"); 
	DispatchKeyValue(jetpack, "model", MODEL_GUN_FOOT);   
	DispatchSpawn(jetpack); 
	SetEntProp(jetpack, Prop_Data, "m_takedamage", 0, 1);  	

	new Float:ang[3];
	SetVector(ang, 0.0, 0.0, 0.0);

	TeleportEntity(jetpack, pos,ang, NULL_VECTOR);  
	
	SetEntProp(jetpack, Prop_Send, "m_iGlowType", 3 ); //3
	SetEntProp(jetpack, Prop_Send, "m_nGlowRange", 0 ); //0
	SetEntProp(jetpack, Prop_Send, "m_glowColorOverride", 1); //1	
	
	DispatchKeyValueFloat(jetpack, "fademindist", 10000.0);
	DispatchKeyValueFloat(jetpack, "fademaxdist", 20000.0);
	DispatchKeyValueFloat(jetpack, "fadescale", 0.0); 
	return 	jetpack;
}

CreateOnBack(client )
{

	new ent= CreateEntityByName("prop_dynamic_override");
	SetEntityModel(ent, MODEL_GUN_M60);
	DispatchSpawn(ent);
	
	decl String:tName[128];
	Format(tName, sizeof(tName), "target%d",client );
	DispatchKeyValue(client , "targetname", tName);		
	
 	SetVariantString(tName);
	AcceptEntityInput(ent, "SetParent", ent, ent, 0);
	SetVariantString("medkit"); 
	AcceptEntityInput(ent, "SetParentAttachment");
	
	new Float:vec_pos[3];
	new Float:vec_ang[3];
	
	SetVector(vec_pos, 0.0, 0.0, 10.0); 
	SetVector(vec_ang, 90.0, 90.0, 0.0); 

	
	TeleportEntity(ent, vec_pos,vec_ang,NULL_VECTOR);	
	Glow(ent, true);
	return ent;
	
}

GetEnemyPostion(entity, Float:position[3])
{
	if(entity<=MaxClients) GetClientAbsOrigin(entity, position);
	else GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2]+=35.0; 
}
ScanAllEnemy(Float:time)
{
	if(time-ScanTime>1.0)
	{
		ScanTime=time; 
		InfectedCount = 0;
		if(GetConVarInt(l4d_protector_attack_special_infected)>0)
		{
			for(new i=1 ; i<=MaxClients; i++)
			{
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==3)
				{
					new class = GetEntProp(i, Prop_Send, "m_zombieClass"); 
					if(class==ZOMBIECLASS_TANK)continue;
					InfectedsArray[InfectedCount++]=i;
				}
			}
		}
		if(GetConVarInt(l4d_protector_attack_common_infected)>0)
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
	PrintToChatAll("mp_gamemode = %s", GameName);
	
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
			if(IsClientInGame(ent) && IsPlayerAlive(ent) && GetClientTeam(ent)==3)
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
public Action:Hook_SetTransmit(entity, client)
{  
	if(HaveProtector[client] && GunModelHead[client]==entity )return Plugin_Handled;
	
	return Plugin_Continue;
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
