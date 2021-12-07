#include <sourcemod>
#include <sdktools>

#define LINGHNING2 "ambient/energy/zap1.wav"

new Handle:l4d_smoker_lightning_damage1;
new Handle:l4d_smoker_lightning_damage2 ;
new Handle:l4d_smoker_lightning_chance ;
new Handle:l4d_smoker_lightning_todeath ;
new Handle:l4d_smoker_lightning_range;
new Handle:l4d_smoker_lightning_life;
new L4D2Version;
new bool:gamestart ;
new g_sprite;
new g_HaloSprite;
new whiteColor[4]		= {255, 255, 255, 255};

new Lightning[MAXPLAYERS+1][MAXPLAYERS+1];
new Float:AttackerTime[MAXPLAYERS+1];
new Victim[MAXPLAYERS+1];

public Plugin:myinfo = 
{
	name = "Smoker Lightning",
	author = "Pan Xiaohai",
	description = "Smoker Lightning",
	version = "1.0",
	url = " "
}

public OnPluginStart()
{
	l4d_smoker_lightning_damage1 = 	CreateConVar("l4d_smoker_lightning_damage1", "30", "damage at first,[1, 100]int");
	l4d_smoker_lightning_damage2 = 	CreateConVar("l4d_smoker_lightning_damage2", "5", "damage per second,[1, 10]int");
	l4d_smoker_lightning_chance = 	CreateConVar("l4d_smoker_lightning_chance", "100", "[0.0, 100.0]%");
	l4d_smoker_lightning_todeath = 	CreateConVar("l4d_smoker_lightning_todeath", "1", "0, do not damage palyer if icapped, 1, awalys damage to palyer");

	l4d_smoker_lightning_range = 	CreateConVar("l4d_smoker_lightning_range", "800.0", "lightning transfer range [300.0, -]");
	l4d_smoker_lightning_life = 	CreateConVar("l4d_smoker_lightning_life", "60.0", "lightning's life [30.0 -]");	
	
	AutoExecConfig(true, "l4d_smokerlightning");
 
	HookEvent("round_start", round_start);
	HookEvent("round_end", round_end);
	HookEvent("finale_win", round_end);
	HookEvent("mission_lost", round_end);
	HookEvent("map_transition", round_end);
 
	HookEvent("tongue_grab", tongue_grab);
 
	GameCheck();
	gamestart=false;
}

public tongue_grab (Handle:event, const String:name[], bool:dontBroadcast)
{
	gamestart=true;
	if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_smoker_lightning_chance))
	{
		new victim = GetClientOfUserId(GetEventInt(event, "victim"));
		new attacker = GetClientOfUserId(GetEventInt(event, "userid"));
		if (!victim) return;
		if (!attacker) return;
 
		ClearLightning(attacker);
		Lightning[attacker][victim]=1;
		Lightning[attacker][attacker]=1;	
		Victim[attacker]=victim;
		AttackerTime[attacker]=GetEngineTime();
		ShowEffectToPlayer(attacker, victim);
		
		CreateTimer(1.0, ScanPlayer, attacker, TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);	
	}
}

ShowEffectToPlayer(attacker, victim)
{
	float pos1[3], pos2[3];
	GetClientEyePosition(victim, pos1);
	GetClientEyePosition(attacker, pos2);

	DamageEffect(victim, l4d_smoker_lightning_damage1);
 
	new Float:life=0.2;
	new Float:width1=10.0;
 	
	if(L4D2Version)width1=5.0;
	
	if(L4D2Version)
	{
		ShowParticle(pos1, "electrical_arc_01_system", 0.5);		
	}
	else
	{
		TE_SetupBeamRingPoint(pos1, 10.0, 40.0, g_sprite, g_HaloSprite, 0, 10, 0.5, 17.0, 0.5, whiteColor, 10, 0);
		TE_SendToAll();
	}
	TE_SetupBeamPoints(pos1, pos2, g_sprite, 0, 0, 0, life, width1, width1, 1, 0.0,whiteColor, 0);
	TE_SendToAll();	
	EmitSoundToAll(LINGHNING2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos1, NULL_VECTOR, false, 0.0);	
	PrintHintText(victim, "You attacked by smoker's Lightning");
	ClientCommand(victim, "vocalize PlayerDeath");
}

public Action:ScanPlayer(Handle:timer,any:attacker)
{
	new Float:time=AttackerTime[attacker];	
	new victim=Victim[attacker];
	 
	if(!gamestart || (GetEngineTime()-time)>GetConVarFloat(l4d_smoker_lightning_life))
	{
		ClearLightning(attacker);
		return Plugin_Stop;
	}
	
	if(victim >0 && IsClientInGame(victim) && IsPlayerAlive(victim))
	{
		new v=SearchVictim(victim,attacker);
		if(v>0)
		{
			Victim[attacker]=v; 
			Lightning[attacker][v]=1;
			ShowEffectToPlayer(victim, v)
			
		}
		else if(v==0)
		{
			decl Float:pos[3];
			GetClientEyePosition(victim, pos);
			pos[2]-=15.0;
			if(L4D2Version)	ShowParticle(pos, "electrical_arc_01_system", 0.5);
			else
			{
				TE_SetupBeamRingPoint(pos, 10.0, 30.0, g_sprite, g_HaloSprite, 0, 10, 0.5, 17.0, 0.5, whiteColor, 10, 0);
				TE_SendToAll();
			}
			EmitSoundToAll(LINGHNING2, 0, SNDCHAN_WEAPON, SNDLEVEL_TRAFFIC, SND_NOFLAGS, SNDVOL_NORMAL, 100, _, pos, NULL_VECTOR, false, 0.0);	
			if(GetConVarInt(l4d_smoker_lightning_todeath)==1)
			{
				DamageEffect(victim, l4d_smoker_lightning_damage2);
			}
			else if	(!(IsPlayerIncapped(victim) || IsPlayerGrapEdge(victim)))
			{
				DamageEffect(victim, l4d_smoker_lightning_damage2);
			}
		}
		else if(v<0)
		{
			ClearLightning(attacker);
			return Plugin_Stop;
		}
		return Plugin_Continue;
	}
	else
	{
		ClearLightning(attacker);
		return Plugin_Stop;
	}
}

ClearLightning(attacker)
{
	for(new client = 1; client <= MaxClients; client++)
	{
		Lightning[attacker][client]=0;
	}
	Victim[attacker]=0;
	AttackerTime[attacker]=0.0;
}

SearchVictim(victim, attacker)
{
	new t=0;
	float pos1[3], pos2[3];
	GetClientEyePosition(victim, pos1);
	new bool:left=false;
	new Float:range=GetConVarFloat(l4d_smoker_lightning_range);
	for(new client = 1; client <= MaxClients; client++)
	{
		if(IsClientInGame(client) && IsPlayerAlive(client) )
		{
			if(Lightning[attacker][client]==0 )
			{
				if(GetClientTeam(client)==2)left=true;
				GetClientEyePosition(client, pos2);
				new Float:d=GetVectorDistance(pos1, pos2)
				if(d<range)
				{
					bool ok = IfTwoPosVisible(pos1, pos2, 0);
					if(ok)
					{
						t=client;
						break;
					}
				}
			}
		}
	}
	
	if(!left)t=-1;
	return t;
}
 
public Action:round_start(Handle:Spawn_Event, const String:Spawn_Name[], bool:Spawn_Broadcast)
{
 	gamestart=true;
}

public Action:round_end(Handle:event, const String:name[], bool:dontBroadcast)
{
	gamestart=false;
}

GameCheck()
{
	decl String:GameName[16];
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

public ShowParticle(Float:pos[3], String:particlename[], Float:time)
{
 new particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		TeleportEntity(particle, pos, NULL_VECTOR, NULL_VECTOR);
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
		DispatchSpawn(particle);
		ActivateEntity(particle);
		AcceptEntityInput(particle, "start");
		CreateTimer(time, DeleteParticles, particle, TIMER_FLAG_NO_MAPCHANGE);
 } 
}
 
public PrecacheParticle(String:particlename[])
{
 new particle = CreateEntityByName("info_particle_system");
 if (IsValidEdict(particle))
 {
		DispatchKeyValue(particle, "effect_name", particlename);
		DispatchKeyValue(particle, "targetname", "particle");
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
public AttachParticle(i_Ent, String:s_Effect[], Float:f_Origin[3])
{
	decl i_Particle, String:s_TargetName[32]
	
	i_Particle = CreateEntityByName("info_particle_system")
	
	if (IsValidEdict(i_Particle))
	{
	 
		//f_Origin[2] -= 15.0;
		TeleportEntity(i_Particle, f_Origin, NULL_VECTOR, NULL_VECTOR)
		FormatEx(s_TargetName, sizeof(s_TargetName), "target%d", i_Ent)
		DispatchKeyValue(i_Particle, "targetname", s_TargetName)
		GetEntPropString(i_Ent, Prop_Data, "m_iName", s_TargetName, sizeof(s_TargetName))
		DispatchKeyValue(i_Particle, "parentname", s_TargetName)
		DispatchKeyValue(i_Particle, "effect_name", s_Effect)
		DispatchSpawn(i_Particle)
		SetVariantString(s_TargetName)
		AcceptEntityInput(i_Particle, "SetParent", i_Particle, i_Particle, 0)
		ActivateEntity(i_Particle)
		AcceptEntityInput(i_Particle, "Start")
	}
	return i_Particle
}

bool IfTwoPosVisible(Float:pos1[3], Float:pos2[3], self)
{
	new bool:r=true;
	new Handle:trace = TR_TraceRayFilterEx(pos2, pos1, MASK_SOLID, RayType_EndPoint, TraceRayDontHitSelfAndLive,self);
	if(TR_DidHit(trace))
	{
		r=false;
	}
 	CloseHandle(trace);
	return r;
}
public bool:TraceRayDontHitSelfAndLive(entity, mask, any:data)
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
stock DamageEffect(target, Handle:damageconvar)
{
	decl String:damage[10];
	GetConVarString(damageconvar, damage, 10);
	decl String:N[20];
	Format(N, 20, "target%d", target);	
	new pointHurt = CreateEntityByName("point_hurt");	
	if(pointHurt<=0)return;
	DispatchKeyValue(target, "targetname", N);			
	DispatchKeyValue(pointHurt, "Damage", damage);				
	DispatchKeyValue(pointHurt, "DamageTarget", N);
	DispatchKeyValue(pointHurt, "DamageType", "8");			
	DispatchSpawn(pointHurt);									
	AcceptEntityInput(pointHurt, "Hurt"); 					
	AcceptEntityInput(pointHurt, "Kill"); 	
	RemoveEdict(pointHurt);
 	
}
public OnMapStart()
{
 
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
		g_HaloSprite = PrecacheModel("materials/dev/halo_add_to_screen.vmt");	
		PrecacheParticle("electrical_arc_01_system");

	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
		g_HaloSprite = PrecacheModel("materials/sprites/halo01.vmt");	
	}
	PrecacheSound(LINGHNING2, true);
}
bool:IsPlayerIncapped(client)
{
	if (GetEntProp(client, Prop_Send, "m_isIncapacitated", 1)) return true;
 	return false;
}
bool:IsPlayerGrapEdge(client)
{
 	if (GetEntProp(client, Prop_Send, "m_isHangingFromLedge", 1))return true;
	return false;
}