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

#define PARTICLE_BLOOD		"blood_impact_headshot_01"
#define SOUND_FIRE "weapons/grenade_launcher/grenadefire/grenade_launcher_fire_1.wav"
#define SOUND_IMPACT "npc/infected/gore/bullets/bullet_impact_01.wav"
#define MODEL_BULLET "models/w_models/weapons/w_HE_grenade.mdl"
#define PARTICLE_MUZZLE_FLASH		"weapon_muzzle_flash_autoshotgun"  
#define Missile_model2 "models/missiles/f18_agm65maverick.mdl"



new ZOMBIECLASS_TANK=	5;
new GameMode;
new L4D2Version;


new bool:HaveAutoGun[MAXPLAYERS+1];
new AutoGunModel[MAXPLAYERS+1];
new MissileCount[MAXPLAYERS+1];
new MissileRemain[MAXPLAYERS+1];
new LastButton[MAXPLAYERS+1];
#define MissileArraySize 30
new MissileEnt [MAXPLAYERS+1][MissileArraySize];
new MissileModel [MAXPLAYERS+1][MissileArraySize];
new MissileEnemy[MAXPLAYERS+1][MissileArraySize];
new Float:MissileTime[MAXPLAYERS+1][MissileArraySize];
new Float:MissileStartTime[MAXPLAYERS+1][MissileArraySize];

new Float:FireTime [MAXPLAYERS+1];
new Float:TimerIndicator [MAXPLAYERS+1];

new Handle:l4d_autogun_missile_count;
new Handle:l4d_autogun_missile_damage;
new Handle:l4d_autogun_missile_speed ;
new Handle:l4d_autogun_missile_use_delay ;

new Handle:l4d_autogun_attack_distance ;
new Handle:l4d_autogun_attack_special_infected;
new Handle:l4d_autogun_attack_common_infected ;

 
#define EnemyArraySize 300
new InfectedsArray[EnemyArraySize];
new InfectedCount;
new Float:ScanTime=0.0;
new GunScanIndex[MAXPLAYERS+1];
new GunEnemy[MAXPLAYERS+1];


new g_PointHurt = 0;
new g_iVelocity = 0;
public Plugin:myinfo = 
{
	name = "automatic gun",
	author = " pan xiao hai",
	description = " ",
	version = "1.4",
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
	RegConsoleCmd("sm_autogun", sm_autogun);
	g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
	
 	l4d_autogun_missile_count = CreateConVar("l4d_autogun_missile_count", "100", " missile count", FCVAR_PLUGIN);
	l4d_autogun_missile_damage = CreateConVar("l4d_autogun_missile_damage", "50", " missile damage", FCVAR_PLUGIN);
	l4d_autogun_missile_speed = CreateConVar("l4d_autogun_missile_speed", "800.0", " missile fly speed", FCVAR_PLUGIN);
	l4d_autogun_missile_use_delay = CreateConVar("l4d_autogun_missile_use_delay", "0.2", "min time between two shot", FCVAR_PLUGIN);
	
	l4d_autogun_attack_distance = CreateConVar("l4d_autogun_attack_distance", "1500.0", "max attack range", FCVAR_PLUGIN);
	l4d_autogun_attack_special_infected = CreateConVar("l4d_autogun_attack_special_infected", "1", "1 enable, 0 disable", FCVAR_PLUGIN);
	l4d_autogun_attack_common_infected = CreateConVar("l4d_autogun_attack_common_infected", "1", "1 enable, 0 disable", FCVAR_PLUGIN);	

	
	AutoExecConfig(true, "l4d_autogun");  
}
public OnMapStart()
{
	ResetAllState();
 
	if(L4D2Version)
	{
		PrecacheSound(SOUND_FIRE);
		PrecacheSound(SOUND_IMPACT);
		PrecacheModel(MODEL_BULLET);
		PrecacheParticle(PARTICLE_MUZZLE_FLASH);
		PrecacheParticle(PARTICLE_BLOOD);
		PrecacheModel(Missile_model2, true);
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
	MissileRemain[client]=0;
	MissileCount[client]=0;
	LastButton[client]=0;
	GunScanIndex[client]=0;
	HaveAutoGun[client]=false;
	AutoGunModel[client]=0;	
	FireTime[client]=0.0;
	
	GunEnemy[client]=0;
	GunScanIndex[client]=0;
	
}
public Action:player_use(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	
	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new ent=GetEventInt(hEvent, "targetid"); 
	if(IsGrenadeLauncher(ent) && !HaveAutoGun[client])
	{	
		BuildMenu(client, ent);
	}
 
}
public Action:sm_autogun(client,args)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(HaveAutoGun[client])
		{
			RemoveAutoGun(client);
			new weapon=GetPlayerWeaponSlot(client, 0);
			if(weapon>0)
			{			
				RemovePlayerItem(client, weapon);				
			}
			Give(client, "grenade_launcher");
		}
		else
		{
			CreateAutoGun(client);
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
	SetMenuTitle(menu, "Do you want to build an auto gun?"); 
	AddMenuItem(menu, "Yes", "Yes");
	AddMenuItem(menu, "No", "No"); 
	SetMenuExitButton(menu, true);
	 
	DisplayMenu(menu, client, 2); 
}
public MenuSelector1(Handle:menu, MenuAction:action, client, param2)
{
	
	if (action == MenuAction_Select)
	{ 
		decl String:item[256], String:display[256];		
		GetMenuItem(menu, param2, item, sizeof(item), _, display, sizeof(display));		
		if (StrEqual(item, "Yes"))
		{
			if( !HaveAutoGun[client])
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
	if(HaveGrenadeLauncher(client) && !HaveAutoGun[client])
	{
		if(GetEngineTime()>=TimerIndicator[client])
		{
			PrintHintText(client, "Build an auto gun successfully, press mouse middle button");
			RemoveGrenadeLauncher(client);
			CreateAutoGun(client);
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
 
IsGrenadeLauncher(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		decl String:name[50];
		GetEdictClassname(ent, name, 50);
	
		if(StrEqual( name, "weapon_grenade_launcher") )	return true;

	}
	return false;
}
HoldGrenadeLauncher(client)
{
	decl String:name[50];
	GetClientWeapon(client, name, 50);
	if(StrEqual( name, "weapon_grenade_launcher") )	return true;
	return false;
}
HaveGrenadeLauncher(client)
{
	decl String:name[50];

	new ent=GetPlayerWeaponSlot(client, 0);
	if(ent>0)
	{
		GetEdictClassname(ent, name, 50);
		if(StrEqual( name, "weapon_grenade_launcher") )	return true;
	}
	return false;
}
RemoveGrenadeLauncher(client)
{
	decl String:name[50];

	new ent=GetPlayerWeaponSlot(client, 0);
	if(ent>0)
	{
		GetEdictClassname(ent, name, 50);
		if(StrEqual( name, "weapon_grenade_launcher") )
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
	if(HaveAutoGun[client])
	{
		RemoveAutoGun(client);
	}
	ResetClientState(client);
	ResetClientState(bot);

}
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));  
	if(HaveAutoGun[client])
	{
		RemoveAutoGun(client);
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
		if(HaveAutoGun[dead_player])
		{
			RemoveAutoGun(dead_player);
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


public Action:player_hurt(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	new  attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new  victim = GetClientOfUserId(GetEventInt(event, "userid"));  
	

}
CreateAutoGun(client)
{

	HaveAutoGun[client]=true;
	AutoGunModel[client]= CreateGunModel(client);
	FireTime[client]=GetEngineTime();
	MissileRemain[client]=GetConVarInt(l4d_autogun_missile_count);
	PrintToChatAll("%N create a auto gun", client);
}
RemoveAutoGun(client)
{
	HaveAutoGun[client]=false;
	RemoveGunModel(client);
	AutoGunModel[client] = 0;
	if(client>0 && IsClientInGame(client)) PrintToChatAll("%N remove an auto gun", client);
	ResetClientState(client);
}

CreateGunModel(client)
{
	new ent=CreateEntityByName("prop_dynamic_override");      
	SetEntityModel(ent,  "models/w_models/weapons/w_grenade_launcher.mdl");	//"models/weapons/melee/w_machete.mdl"
	DispatchSpawn(ent); 
	SetEntPropFloat(ent , Prop_Send,"m_flModelScale", 0.6); 
	
	decl String:tName[128];
	Format(tName, sizeof(tName), "target%d",client );
	DispatchKeyValue(client , "targetname", tName);		
	
 	SetVariantString(tName);
	AcceptEntityInput(ent, "SetParent", ent, ent, 0);
	 
	SetVariantString("eyes");  
	AcceptEntityInput(ent, "SetParentAttachment"); 


	new Float:pos[3];
	new Float:ang[3]; 
	SetVector(pos,   0.0,  3.5, -1.0); 
	SetVector(ang, 0.0, 0.0,0.0);	
	
 
	TeleportEntity(ent, pos, ang, NULL_VECTOR);
	GlowEnt(ent, true);
	
	SDKHook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
	return ent;
}
RemoveGunModel(client)
{
	new ent=AutoGunModel[client];
	if(ent>0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		SDKUnhook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
		RemoveEdict(ent);
	}
}

ShowMuzzleFlash(client, Float:pos[3],  Float:angle[3])
{  
 	new particle = CreateEntityByName("info_particle_system");
	DispatchKeyValue(particle, "effect_name", PARTICLE_MUZZLE_FLASH); 
	DispatchSpawn(particle);
	ActivateEntity(particle); 

	
		
	decl String:tName[128];
	Format(tName, sizeof(tName), "target%d",client );
	DispatchKeyValue(client , "targetname", tName);		
	
 	SetVariantString(tName);
	AcceptEntityInput(particle, "SetParent",particle, particle, 0);
	 
	SetVariantString("eyes");  
	AcceptEntityInput(particle, "SetParentAttachment"); 
	//TeleportEntity(particle, pos, angle, NULL_VECTOR);
	
	new Float:pos2[3];
	new Float:ang2[3]; 
	SetVector(pos2,   0.0,  3.5, -1.0); 
	SetVector(ang2, 0.0, 0.0,0.0);	
	SetVector(pos2,   18.0,  0, 0.0); 
	SetVector(ang2, 0.0, 0.0,0.0);	
 
	TeleportEntity(particle, pos2,ang2, NULL_VECTOR);
	
	AcceptEntityInput(particle, "start");	
	CreateTimer(0.01, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
	
}
CreateGLprojectile(client, Float:pos[3] , Float:dir[3], Float:volicity=1000.0, Float:gravity=0.01, Float:modelScale=1.0)
{

	decl Float:v[3];
	CopyVector(dir, v);
	NormalizeVector(v,v);
	ScaleVector(v, volicity);
	new ent=0;
	if(L4D2Version)
	{
		ent=CreateEntityByName("grenade_launcher_projectile");	
		DispatchKeyValue(ent,  "model", MODEL_BULLET); 
	}
	else
	{
		ent=CreateEntityByName("molotov_projectile");	
		DispatchKeyValue(ent, "model", "models/w_models/weapons/w_eq_molotov.mdl"); 
	}

	SetEntityGravity(ent, gravity);  
	DispatchSpawn(ent);
	ActivateEntity(ent);

	decl Float:ang[3];
	GetVectorAngles(dir, ang);
	ang[0]+=90.0;
	TeleportEntity(ent, pos, ang, v);
	
	DispatchKeyValueFloat(ent, "fademindist", 10000.0);
	DispatchKeyValueFloat(ent, "fademaxdist", 20000.0);
	DispatchKeyValueFloat(ent, "fadescale", 0.0); 
 	SetEntPropFloat(ent, Prop_Send,"m_flModelScale",modelScale);	

		//SetEntProp(ent, Prop_Send, "m_iGlowType", 3);
		//SetEntProp(ent, Prop_Send, "m_nGlowRange", 0);
		//SetEntProp(ent, Prop_Send, "m_nGlowRangeMin", 10);
		//SetEntProp(ent, Prop_Send, "m_glowColorOverride", 255*200);
		//IgniteEntity(ent, 0.0);
 

	SetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity", client)	;
	//SetEntPropFloat(ent, Prop_Send, "m_fadeMinDist", 20000.0); 
	//new Float:data= (client+1*10000) * 1.0;
	//SetEntPropFloat(ent, Prop_Send, "m_fadeMaxDist", data);   
	

	
	return ent;
}
CreateMissileModel(client, missile_ent, Float:modelScale=1.0)
{

	
	new ent=0;

	if(L4D2Version)
	{
		ent=CreateEntityByName("prop_dynamic_override");	
		DispatchKeyValue(ent,  "model", Missile_model2); 
 
		DispatchSpawn(ent);
		ActivateEntity(ent);
		
		decl String:tName[128];
		Format(tName, sizeof(tName), "target%d",missile_ent );
		DispatchKeyValue(missile_ent , "targetname", tName);		
	
		SetVariantString(tName);
		AcceptEntityInput(ent, "SetParent",ent, ent, 0);


		SetEntPropFloat(ent, Prop_Send,"m_flModelScale", modelScale);	
		DispatchKeyValueFloat(ent, "fademindist", 10000.0);
		DispatchKeyValueFloat(ent, "fademaxdist", 20000.0);
		DispatchKeyValueFloat(ent, "fadescale", 0.0); 
		
		new Float:ang[3];
		new Float:pos[3];
		SetVector(ang, 0.0, 0.0, 0.0);
		SetVector(pos, 0.0, 0.0, 0.0);
		TeleportEntity(ent, pos, ang, NULL_VECTOR);
	}
	return ent;
}

public GLprojectileTouch(ent, other)
{ 
  	//new Float:f=GetEntPropFloat(ent, Prop_Send, "m_fadeMaxDist");
	//new data=RoundFloat(f);
	//new type=data/10000;
	//new client=data%10000; 

	new client=GetEntPropEnt(ent, Prop_Data, "m_hOwnerEntity");
	new Float:pos[3];
	GetEntPropVector(ent, Prop_Send, "m_vecOrigin", pos);
	if(IsInfectedTeam(other))
	{		
		DoPointHurtForInfected(other,client, GetConVarInt(l4d_autogun_missile_damage));
		new Float:angle[3];
		SetVector(angle ,0.0, 0.0, -1.0);
		GetVectorAngles(angle,angle);
		ShowParticle(pos, angle, PARTICLE_BLOOD, 0.1);
	}
	
	EmitSoundToAll(SOUND_IMPACT, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 1.0, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
	
	RemoveMissile(client, ent);
}
 
  
Glow(client, bool:glow)
{
	if(L4D2Version)
	{
		if (client>0 && IsClientInGame(client) && IsPlayerAlive(client))
		{
			if(glow)
			{
				SetEntProp(client, Prop_Send, "m_iGlowType", 3 ); //3
				SetEntProp(client, Prop_Send, "m_nGlowRange", 0 ); //0
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 256*100); //1	
			}
			else 
			{
				SetEntProp(client, Prop_Send, "m_iGlowType", 0 ); //3
				SetEntProp(client, Prop_Send, "m_nGlowRange", 0 ); //0
				SetEntProp(client, Prop_Send, "m_glowColorOverride", 0); //1	
			}
			
		
		}
	
	}
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if(!HaveAutoGun[client])return Plugin_Continue; 
	new Float:engine_time= GetEngineTime();
	ScanAllEnemy(engine_time);
	new Float:client_position[3];
	GetClientAbsOrigin(client, client_position); 
	client_position[2]+=35.0;
	
	new Float:client_eye_position[3];
	GetClientEyePosition(client, client_eye_position);
	
	new Float:infected_postion[3];
	//GetClientAbsOrigin(infected, infected_postion);
	//infected_postion[2]+=35.0;	

	

	new gun_enemy=GunEnemy[client];

	
	if( IsInfectedTeam(gun_enemy ))
	{
		new Float:hitpos[3];
		new Float:shotangle[3];
		
		new enemy=IsEnemyVisible(client, gun_enemy, client_eye_position);	 
		gun_enemy=enemy;
	}
	else gun_enemy=0;

	if(gun_enemy==0 && InfectedCount>0)
	{
		if(GunScanIndex[client]>=InfectedCount)
		{
			GunScanIndex[client]=0;
			//if(buttons & IN_ZOOM)	PrintToChatAll("scan index zeor ",GunScanIndex[client] );
		}
		GunEnemy[client]=InfectedsArray[GunScanIndex[client]];
		GunScanIndex[client]++;
	}
	new bool:fire= ((buttons & IN_ZOOM) && !(LastButton[client] & IN_ZOOM));
	if(fire)
	{
		if(IsPrimaryWeapon(client))fire=false;

	}
	new Float:use_delay=GetConVarFloat(l4d_autogun_missile_use_delay);
	if(IsFakeClient(client))
	{
		fire=true;
		use_delay=0.5;
	}

	if(fire)
	{
		
		if(gun_enemy>0 || (buttons & IN_USE))
		{
			if( GetEngineTime() - FireTime[client]>use_delay)
			{
				if(MissileRemain[client]>0)
				{
					CreateMissile(client, gun_enemy);
					FireTime[client]=GetEngineTime();
					GunEnemy[client]=0;
					MissileRemain[client]--;
				}
				PrintCenterText(client, "missile left %d",MissileRemain[client] );
			}
		}
		else 
		{
			PrintCenterText(client, "no enemy find");
		}

	}
	if(MissileCount[client]>0)
	{
		TraceMissile(client, engine_time, gun_enemy);
	}
	LastButton[client]=buttons;
	return Plugin_Continue;
}
bool:IsPrimaryWeapon(client)
{
	decl String:weapon_name[50];
	GetClientWeapon(client, weapon_name, 50);


	new ent=GetPlayerWeaponSlot(client, 0);
	if(ent<=0)return false;
	
	decl String:primary_name[50];
	GetEdictClassname(ent, primary_name, 50);
	if(StrEqual( weapon_name, primary_name) )return true;

	return false;
}
CreateMissile(client ,gun_enmey)
{
	if(MissileCount[client]>=MissileArraySize-1)return 0;
	decl Float:pos[3];
	decl Float:hitpos[3];
	decl Float:dir[3];
	decl Float:angle[3];
	decl Float:temp[3];
	GetClientEyePosition(client, pos);
	GetClientEyeAngles(client , angle);	
	
	decl Float:newpos[3];
	decl Float:right[3];
	GetAngleVectors(angle, NULL_VECTOR, right, NULL_VECTOR);
	NormalizeVector(right, right);
	ScaleVector(right, -3.0);
	AddVectors(pos, right, newpos);	

	GetAngleVectors(angle, dir, NULL_VECTOR, NULL_VECTOR);
	NormalizeVector(dir, dir);
	CopyVector(dir,temp);
	ScaleVector(temp, 35.0);
	AddVectors(newpos, temp,newpos);
	
	
	new missile_ent=CreateGLprojectile(client, newpos, dir, 300.0);
	new missile_model=CreateMissileModel(client, missile_ent, 0.1);
	SDKHook(missile_ent, SDKHook_StartTouch , GLprojectileTouch); 
	
	ShowMuzzleFlash(client, newpos, angle);
	EmitSoundToAll(SOUND_FIRE, 0,  SNDCHAN_WEAPON, SNDLEVEL_NORMAL, SND_NOFLAGS, 0.8, SNDPITCH_NORMAL, -1, pos, NULL_VECTOR, true, 0.0);
	
	
	new index=MissileCount[client];
	MissileCount[client]++;
	MissileEnt[client][index]=missile_ent;
	MissileModel[client][index]=missile_model;
	MissileEnemy[client][index]=gun_enmey;
	MissileStartTime[client][index]=GetEngineTime();
	MissileTime[client][index]=GetEngineTime();
	//PrintToChatAll("create missle %d", missile_ent );
	
}
RemoveMissile(client ,missile_ent)
{
	//PrintToChatAll("remove missle %d", missile_ent );

	new count=MissileCount[client];
	for(new index=0; index<count; index++)
	{
		if(MissileEnt[client][index]==missile_ent)
		{
			new model=MissileModel[client][index];
			if(model>0 && IsValidEdict(model) && IsValidEntity(model))AcceptEntityInput(model, "kill");
			MissileEnt[client][index]=MissileEnt[client][count-1];
			MissileModel[client][index]=MissileModel[client][count-1];			
			MissileStartTime[client][index]=MissileStartTime[client][count-1];
			MissileTime[client][index]=MissileTime[client][count-1];
			MissileEnemy[client][index]=MissileEnemy[client][count-1];
			MissileCount[client]--;
			break;
		}
	}
	if(missile_ent>0)
	{		
		SDKUnhook(missile_ent, SDKHook_StartTouch, GLprojectileTouch);
		if(IsValidEdict(missile_ent) && IsValidEntity(missile_ent))AcceptEntityInput(missile_ent, "kill");
	}
}
TraceMissile(client, Float:time, current_enemy)
{
	new Float:missile_direction[3];
	new Float:enemy_position[3];
	new Float:missile_position[3];
	new Float:enemy_direction[3];
	new Float:missile_velocity[3];
	new Float:up_direction[3];
	for(new index=0; index<MissileCount[client]; index++)
	{
		
		new Float:duration=time-MissileTime[client][index];
		if(duration>1.0)duration=1.0;
		else if(duration<=0.0)duration=0.01;
		MissileTime[client][index] = time; 
		
		
		new enemy=MissileEnemy[client][index];
		if(enemy == 0)	enemy=current_enemy;
		
		new missile_ent=MissileEnt[client][index];

		if(IsInfectedTeam( enemy))
		{
			GetEnemyPostion(enemy, enemy_position);
		}
		else 
		{
			GetClientEyePosition(client, enemy_position);
			GetClientEyeAngles(client,enemy_direction );
			GetLookPosition(client, enemy_position, enemy_direction, enemy_position);
			enemy=0;
		}
		MissileEnemy[client][index] = enemy;
		GetEntPropVector(missile_ent, Prop_Send, "m_vecOrigin", missile_position);
		GetEntDataVector(missile_ent, g_iVelocity, missile_velocity);
		NormalizeVector(missile_velocity,missile_velocity);

		SubtractVectors(enemy_position,missile_position,enemy_direction );
		NormalizeVector(enemy_direction,enemy_direction);
		ScaleVector(enemy_direction, 8.0*duration);
		
		AddVectors(missile_velocity, enemy_direction,missile_direction);
		if(time-MissileStartTime[client][index]<0.1)
		{
			SetVector(up_direction, 0.0, 0.0, 1.0);
			ScaleVector(up_direction, 10.0*duration);
			AddVectors(missile_direction, up_direction,missile_direction);
		}

		NormalizeVector(missile_direction,missile_direction);
		ScaleVector(missile_direction, GetConVarFloat(l4d_autogun_missile_speed));
		TeleportEntity(missile_ent,NULL_VECTOR , NULL_VECTOR, missile_direction);
		//PrintToChatAll("trace missile_enemy %d", enemy);

	}
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
		if(GetConVarInt(l4d_autogun_attack_special_infected)>0)
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
		if(GetConVarInt(l4d_autogun_attack_common_infected)>0)
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
	if(GetVectorDistance(enemy_position, client_position)>GetConVarFloat(l4d_autogun_attack_distance))return 0;
	
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
bool:IsVisible(Float:pos1[3], Float:pos2[3], infected)
{	
 	
	new Handle:trace=TR_TraceRayFilterEx(pos1, pos2, MASK_SHOT, RayType_EndPoint, TraceRayDontHitAlive, infected); 	 
	
	new ent=0;
	if(TR_DidHit(trace))
	{		 
		ent=TR_GetEntityIndex(trace); 
	}
	CloseHandle(trace); 

	if(ent>0)return false;
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
	if(HaveAutoGun[client] && AutoGunModel[client]==entity )return Plugin_Handled;
	
	return Plugin_Continue;
}
 
GlowEnt(ent, bool:glow)
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