#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_functions>
#include <sdkhooks>
#define Pai 3.14159265358979323846 

#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6 

#define PARTICLE_BLOOD		"blood_impact_headshot_01"
#define SOUND_FIRE "weapons/grenade_launcher/grenadefire/grenade_launcher_fire_1.wav"
#define SOUND_IMPACT "npc/infected/gore/bullets/bullet_impact_01.wav"
#define MODEL_SHIELD "models/weapons/melee/w_riotshield.mdl"

#define state_none 0
#define state_enable	1 
#define state_disable 	2


#define ShieldMode_None 0
#define ShieldMode_Side 8
#define ShieldMode_Front 2
#define ShieldMode_Back 4

new ZOMBIECLASS_TANK=	5;
new GameMode;
new L4D2Version;


new bool:HaveShield[MAXPLAYERS+1];
new ShieldModelEnt[MAXPLAYERS+1];
new ShieldState[MAXPLAYERS+1];
new MissileRemain[MAXPLAYERS+1];
new LastButton[MAXPLAYERS+1];

new Float:ShowShieldTime[MAXPLAYERS+1];
new Float:CheckTime[MAXPLAYERS+1];

new Float:TimerIndicator [MAXPLAYERS+1];
 

new Handle:l4d_shield_damage_from_ci; 
new Handle:l4d_shield_damage_from_si; 
new Handle:l4d_shield_damage_from_tank;
new Handle:l4d_shield_damage_from_witch;
new Handle:l4d_shield_drop_from_tank;
new Handle:l4d_shield_drop_from_witch;
new g_PointHurt = 0;
//new g_iVelocity = 0;
public Plugin:myinfo = 
{
	name = "new shield",
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
	RegConsoleCmd("sm_shield", sm_shield);
	
		
	HookEvent("witch_killed", witch_killed ); 
	HookEvent("tank_killed", tank_killed );
	
	//g_iVelocity = FindSendPropOffs("CBasePlayer", "m_vecVelocity[0]");
 
   	l4d_shield_drop_from_tank = CreateConVar("l4d_shield_drop_from_tank", "30.0", "chance of give a shield to tank killer[0.0, 100.0] %" );
  	l4d_shield_drop_from_witch = CreateConVar("l4d_shield_drop_from_witch", "50.0", "chance of give a shield to witch killer[0.0, 100.0] %" );

 
  	l4d_shield_damage_from_ci = CreateConVar("l4d_shield_damage_from_ci", "0.0", "ci damage to survivor with shield[0.0, 100.0] %" );
  	l4d_shield_damage_from_si = CreateConVar("l4d_shield_damage_from_si", "10.0", "si damage to survivor with shield[0.0, 100.0] %" );
  	l4d_shield_damage_from_tank = CreateConVar("l4d_shield_damage_from_tank", "50.0", " damage to survivor with shield[0.0, 100.0] %" );
  	l4d_shield_damage_from_witch = CreateConVar("l4d_shield_damage_from_witch", "20.0", "witch damage to survivor with shield[0.0, 100.0] %" );
 
	
	AutoExecConfig(true, "l4d_shield_new");  
}
public OnMapStart()
{
	ResetAllState();
 
	if(L4D2Version)
	{
		PrecacheSound(SOUND_FIRE);
		PrecacheSound(SOUND_IMPACT);


		PrecacheParticle(PARTICLE_BLOOD);
		PrecacheModel(MODEL_SHIELD, true);
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

	for(new i=1; i<=MaxClients; i++)
	{
		ResetClientState(i); 
	}
} 
ResetClientState(client)
{
	ShieldState[client]=state_none;
	LastButton[client]=0;
	HaveShield[client]=false;
	ShieldModelEnt[client]=0;
	CheckTime[client]=0.0;
}

public Action:witch_killed(Handle:h_Event, const String:s_Name[], bool:b_DontBroadcast)
{ 
	new witchid = GetEventInt(h_Event, "witchid");
	new attacker = GetClientOfUserId(GetEventInt(h_Event, "userid"));	
	if(witchid>0 && attacker>0)
	{
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_shield_drop_from_witch))
		{
			PrintToChatAll("Give %N a shield for killing witch", attacker);
			GiveShield(attacker, true);
		}
	}
	return Plugin_Handled;
}
public Action:tank_killed(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{ 
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(hEvent, "attacker"));
	if(victim>0 && attacker>0)
	{
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_shield_drop_from_tank))
		{
			PrintToChatAll("Give %N a shield for killing tank", attacker);
			GiveShield(attacker, true);
		}
	} 
}

public Action:player_use(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{

	new client = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	new ent=GetEventInt(hEvent, "targetid"); 
	if(IsEntShield(ent) && !HaveShield[client])
	{	
		BuildMenu(client, ent);
	}
 
}
public Action:sm_shield(client,args)
{
	GiveShield(client, false);
}
GiveShield(client, bool:give)
{
	if(client>0 && IsClientInGame(client) && IsPlayerAlive(client))
	{
		if(HaveShield[client])
		{
			if(!give)RemoveShieldMode(client);
		}
		else
		{
			CreateShieldMode(client);
		}
	}
}

public Action:BuildMenu( client , ent)
{	 
	new Handle:menu = CreateMenu(MenuSelector1);
	SetMenuTitle(menu, "Do you want to build a shield?"); 
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
			if( !HaveShield[client])
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
	if(HaveShieldItem(client) && !HaveShield[client])
	{
		if(GetEngineTime()>=TimerIndicator[client])
		{
			PrintHintText(client, "Build a shield successfully");
			RemoveShieldItem(client);
			CreateShieldMode(client);
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
 
IsEntShield(ent)
{
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{
		decl String:name[64];
		GetEdictClassname(ent, name, sizeof(name));
	
		if(StrEqual(name, "weapon_melee"))
		{			 
			GetEntPropString(ent, Prop_Data, "m_ModelName", name, sizeof(name));
		
			if(StrContains(name, "shield")>0)
			{
				//PrintToChatAll("player_use shield");
				return true;
			}
		}

	}
	return false;
}
HaveShieldItem(client)
{

	new ent=GetPlayerWeaponSlot(client, 1);
	return IsEntShield(ent);

}
RemoveShieldItem(client)
{
	new ent=GetPlayerWeaponSlot(client, 1);
	if(IsEntShield(ent))
	{	
		RemovePlayerItem(client, ent);
	}
	return false;
}
public player_bot_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));   
	if(HaveShield[client])
	{
		RemoveShieldMode(client);
	}
	ResetClientState(client);
	ResetClientState(bot);

}
public bot_player_replace(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
	new client = GetClientOfUserId(GetEventInt(Spawn_Event, "player"));
	new bot = GetClientOfUserId(GetEventInt(Spawn_Event, "bot"));  
	if(HaveShield[client])
	{
		RemoveShieldMode(client);
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
		if(HaveShield[dead_player])
		{
			RemoveShieldMode(dead_player);
		}
	
	}

}

CreateShieldMode(client)
{

	HaveShield[client]=true;
	ShieldState[client]=state_none;
	LastButton[client]=0;
	ShieldModelEnt[client]=0;
	CheckTime[client]=GetEngineTime();
	
	SDKUnhook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
	SDKHook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
	
	MissileRemain[client]= 0 ;
	PrintToChatAll("%N create a shield", client);
	PrintToChat(client, "The shield will show when you use single hand melee weapon");
}
RemoveShieldMode(client)
{
	DisattachShieldModel(client);	
	ResetClientState(client);	
	SDKUnhook(client, SDKHook_OnTakeDamage,  PlayerOnTakeDamage);
	
	if(client>0 && IsClientInGame(client)) PrintToChatAll("%N remove a shield", client);
}

AttachShieldModel(client)
{
	if(ShieldState[client]==state_enable)return;
	ShieldState[client]=state_enable;
	ShowShieldTime[client]=GetEngineTime();
	
	new ent= CreateEntityByName("prop_dynamic_override");//spitter_projectile molotov_projectile
	SetEntityModel(ent, MODEL_SHIELD);
	SetEntPropFloat(ent, Prop_Data,"m_flModelScale",1.2);
	DispatchSpawn(ent);
		
	//SetEntityRenderColor(ent, 0, 0, 0, 0);
	//SetEntityMoveType(ent, MOVETYPE_NOCLIP);
	//SetEntProp(ent, Prop_Data, "m_CollisionGroup", 1);  	
		
	SetEntityGravity(ent, 0.1);
	//SetEntPropFloat(ent, Prop_Send, "m_fadeMaxDist", 2000.0);   
	new Float:angle[3];
	GetClientEyeAngles(client, angle);
	//GetAngleVectors(angle, angle, NULL_VECTOR, NULL_VECTOR);
	//ScaleVector(angle, 100.0);
	
	decl String:tName[128];
	Format(tName, sizeof(tName), "target%d",client );
	DispatchKeyValue(client , "targetname", tName);		

	SetVariantString(tName);
	AcceptEntityInput(ent, "SetParent", ent, ent, 0);
	
	SetVariantString("armL"); //muzzle_flash
	AcceptEntityInput(ent, "SetParentAttachment");
	
	//SetEntProp( ent, Prop_Data, "m_CollisionGroup", 2); 
	 
	new Float:pos[3];
	new Float:ang[3];
	pos[0]+=15.0; 
	
	ang[0]=-45.0;
	ang[1]=75.0;
	ang[2]=0.0;
	TeleportEntity(ent, pos,ang,NULL_VECTOR);	
 
	SDKHook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
	ShieldModelEnt[client]=ent;

}
DisattachShieldModel(client)
{
	if(ShieldState[client]==state_disable)return;
	ShieldState[client]=state_disable;
	
	new ent=ShieldModelEnt[client];
	if(ent>0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		SDKUnhook(ent, SDKHook_SetTransmit, Hook_SetTransmit);
		RemoveEdict(ent);
	}
	ShieldModelEnt[client]=0;
}

/* 
CreateMissileModel(client, missile_ent, Float:modelScale=1.0)
{ 
	new ent=0;
	return ent;
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

PrintEntClass(ent)
{
	decl String:name[64];
	GetEdictClassname(ent, name, sizeof(name));
	PrintToChatAll("%d %s", ent, name);
}
*/

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{	 
	if(!HaveShield[client])return Plugin_Continue; 
	
	//if((buttons & IN_ZOOM) && !(LastButton[client] & IN_ZOOM)) ShowShield[client]= !ShowShield[client];
	new Float:engine_time= GetEngineTime();
	if((buttons & IN_USE) ) ShowShieldTime[client]=engine_time;
		

	if(weapon ==0 && engine_time-CheckTime[client]>0.5)
	{
		CheckTime[client]=engine_time;
		new bool:enable=IsClientEnable(client);
		if(enable)
		{
			AttachShieldModel(client);
		}
		else
		{
			DisattachShieldModel(client);
		}
	}	
	if(weapon ==0)
	{
		CheckTime[client]=0.0;
	}
	
	LastButton[client]=buttons;
	return Plugin_Continue;
}


public Action:PlayerOnTakeDamage(victim, &attacker, &inflictor, &Float:damage, &damagetype)
{
	if(victim<=0 || victim>MaxClients)return Plugin_Continue;
	if(!HaveShield[victim])return Plugin_Continue;
	if(ShieldState[victim] != state_enable )return Plugin_Continue;

	
	decl Float:attackerPos[3];
	new Float:damageFactor=100.0;
	if(attacker>0 && attacker<=MaxClients)
	{
		GetClientAbsOrigin(attacker, attackerPos); 
		if(GetEntProp(attacker, Prop_Send, "m_zombieClass")==ZOMBIECLASS_TANK)damageFactor=GetConVarFloat(l4d_shield_damage_from_tank);
		else damageFactor=GetConVarFloat(l4d_shield_damage_from_si);
		//PrintToChatAll("si");
	}
	else 
	{ 
		decl String:name[64];
		GetEdictClassname(attacker, name, 64);
		if(StrEqual(name, "infected"))
		{
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerPos);
			damageFactor=GetConVarFloat(l4d_shield_damage_from_ci);
			//PrintToChatAll("infected");
		} 
		else if(StrEqual(name, "witch"))
		{
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerPos);
			damageFactor=GetConVarFloat(l4d_shield_damage_from_witch);
			//PrintToChatAll("witch");
		} 
		else if(StrEqual(name, "tank_rock"))
		{
			GetEntPropVector(attacker, Prop_Send, "m_vecOrigin", attackerPos);
			damageFactor=GetConVarFloat(l4d_shield_damage_from_tank);
			//PrintToChatAll("rock");
		} 		
		else return Plugin_Continue;
	}
	decl Float:playerPos[3];
	decl Float:playerAngle[3];
		
	GetClientAbsOrigin(victim, playerPos);
	GetClientEyeAngles(victim, playerAngle);
	playerAngle[0]=0.0;
	
	new mode = ShieldMode_Front;
	
	if(mode & ShieldMode_Side)
	{			
		decl Float:right[3];
	 
		decl Float:dir[3];
		
		SubtractVectors(playerPos, attackerPos, dir);
		//ShowDir(1, playerPos, dir, 0.1);
		NormalizeVector(dir, dir);
		GetAngleVectors(playerAngle, NULL_VECTOR, right, NULL_VECTOR);
		NormalizeVector(right,right); 
		new Float:a=GetAngle(dir, right)*180.0/Pai;
		 
		if(a<45.0 || a>135.0 )
		{
			damage=damage*0.01;
			DoPointHurtForInfected(victim,attacker, damage);
			
			return Plugin_Changed;
		}
		 
	}
	else
	{
		damageFactor=damageFactor*0.01;
		
		decl Float:front[3]; 
		decl Float:dir[3];
	
		SubtractVectors(playerPos, attackerPos, dir); 
		NormalizeVector(dir, dir);
		GetAngleVectors(playerAngle, front, NULL_VECTOR, NULL_VECTOR);
		NormalizeVector(front,front); 
				
		new Float:a=GetAngle(dir, front)*180.0/Pai; 

		if((mode & ShieldMode_Front) && a>90.0)
		{ 
			new d=RoundFloat ( (1.0-damageFactor)*damage );
			damage=damage*damageFactor; 	 
			//PrintToChatAll("damage %f factor %f ",damage, damageFactor ); 
			//DoPointHurtForInfected(victim,attacker, damage);
			
			PrintCenterText(victim, "prevent %d damage from infected", d);
			ShowShieldTime[victim]=GetEngineTime();
			return Plugin_Changed;
		} 
		
	} 
	return Plugin_Continue;
}

Float:GetAngle(Float:x1[3], Float:x2[3])
{
	return ArcCosine(GetVectorDotProduct(x1, x2)/(GetVectorLength(x1)*GetVectorLength(x2)));
}

/*
GetEnemyPostion(entity, Float:position[3])
{
	if(entity<=MaxClients) GetClientAbsOrigin(entity, position);
	else GetEntPropVector(entity, Prop_Send, "m_vecOrigin", position);
	position[2]+=35.0; 
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
*/

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
	GameMode+=0;
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
DoPointHurtForInfected(victim, attacker=0,  Float:damage=0.0)
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
	if(HaveShield[client] && ShieldModelEnt[client]==entity)
	{
		if( GetEngineTime() - ShowShieldTime[client]<0.1)return Plugin_Continue;
		else return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/*
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
*/

bool:IsClientEnable(client )
{
	new bool:ret=false;
	decl String:classname[64]; 
	GetClientWeapon(client, classname, 64);
	if(StrEqual(classname, "weapon_melee"))
	{
		new ent=GetPlayerWeaponSlot(client, 1);
		ret = IsItemEnable(ent);
	}
	else if(StrEqual(classname, "weapon_pain_pills"))ret=true;
	else if(StrEqual(classname, "weapon_adrenaline")) ret=true;
	else if(StrEqual(classname, "weapon_molotov")) ret=true;
	else if(StrEqual(classname, "weapon_pipe_bomb")) ret=true;
	else if(StrEqual(classname, "weapon_vomitjar")) ret=true;

	return ret;
}	
bool:IsItemEnable(ent )
{
	new bool:ret=false;
	
	if(ent>0 && IsValidEdict(ent) && IsValidEntity(ent))
	{		
		decl String:classname[64];

		GetEdictClassname(ent, classname, 64);
		if(StrEqual(classname, "weapon_melee"))
		{
			decl String:model[128];
			GetEntPropString(ent, Prop_Data, "m_ModelName", model, sizeof(model));
			if(StrContains(model, "fireaxe")>=0) ret=true;
			else if(StrContains(model, "v_bat")>=0)	ret=true;
			else if(StrContains(model, "crowbar")>=0)ret=true;
			else if(StrContains(model, "electric_guitar")>=0)ret=true;
			else if(StrContains(model, "cricket_bat")>=0) ret=true;
			else if(StrContains(model, "frying_pan")>=0) ret=true;
			else if(StrContains(model, "golfclub")>=0)ret=true;
			else if(StrContains(model, "machete")>=0) ret=true;
			else if(StrContains(model, "katana")>=0) ret=true;
			else if(StrContains(model, "tonfa")>=0)ret=true;
			else if(StrContains(model, "riotshield")>=0)ret=false;
			else if(StrContains(model, "knife")>=0)ret=true;
		}
		else if(StrEqual(classname, "weapon_pain_pills"))ret=true;
		else if(StrEqual(classname, "weapon_adrenaline")) ret=true;
		else if(StrEqual(classname, "weapon_molotov")) ret=true;
		else if(StrEqual(classname, "weapon_pipe_bomb")) ret=true;
		else if(StrEqual(classname, "weapon_vomitjar")) ret=true;

	
	}
	return ret;
}
