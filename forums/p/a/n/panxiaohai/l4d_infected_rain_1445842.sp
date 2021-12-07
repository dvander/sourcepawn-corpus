/* Plugin Template generated by Pawn Studio */

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
 
#define ZOMBIECLASS_SMOKER	1
#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_HUNTER	3
#define ZOMBIECLASS_SPITTER	4
#define ZOMBIECLASS_JOCKEY	5
#define ZOMBIECLASS_CHARGER	6
new ZOMBIECLASS_TANK=	5;

new Handle:l4d_rain_enable;
new Handle:l4d_spawn_enable; 
 
new Handle:l4d_rain_mininterval ;
new Handle:l4d_rain_maxinterval ;
new Handle:l4d_rain_duration ;
new Handle:l4d_rain_intervual ;

new Handle:l4d_rain_chance_tankdead ;
new Handle:l4d_rain_chance_witchdead ;
new Handle:l4d_rain_chance_witch_harasser;

new Handle:l4d_spawn_chance_tankrock ;
new Handle:l4d_spawn_mincount_tankrock ;
new Handle:l4d_spawn_maxcount_tankrock ;

new Handle:l4d_spawn_chance_spitteracid;
new Handle:l4d_spawn_mincount_spitteracid;
new Handle:l4d_spawn_maxcount_spitteracid;

new Handle:l4d_spawn_chance_boomervomit; 

new Handle:l4d_spawn_chance_boomerdead;
new Handle:l4d_spawn_mincount_boomerdead;
new Handle:l4d_spawn_maxcount_boomerdead;

new Handle:l4d_spawn_chance_spitterdead;
new Handle:l4d_spawn_mincount_spitterdead;
new Handle:l4d_spawn_maxcount_spitterdead;

new Handle:l4d_spawn_chance_tankdead;
new Handle:l4d_spawn_mincount_tankdead;
new Handle:l4d_spawn_maxcount_tankdead;

new L4D2Version;
new GameMode;
new gamestart=true;

new timetick=0;
new nexttime=0;
new Float:spawntime=0.0;
  

public Plugin:myinfo = 
{
	name = "Infected Rain",
	author = "Pan Xiaohai",
	description = "Infected  Rain",
	version = "1.1",
	url = "<- URL ->"
}

public OnPluginStart()
{
	
	l4d_rain_enable =  CreateConVar("l4d_rain_enable", "1", "{0,1}", FCVAR_PLUGIN); 
	l4d_spawn_enable =  CreateConVar("l4d_spawn_enable", "1", "{0,1}", FCVAR_PLUGIN); 
	
	l4d_rain_mininterval =  CreateConVar("l4d_rain_mininterval", "150", "[200, maxinterval]seconds ", FCVAR_PLUGIN); 
	l4d_rain_maxinterval =  CreateConVar("l4d_rain_maxinterval", "400", "[200, 600]seconds ", FCVAR_PLUGIN);	
	l4d_rain_duration = CreateConVar("l4d_rain_duration", "15.0", "", FCVAR_PLUGIN);	
	l4d_rain_intervual =  CreateConVar("l4d_rain_intervual", "0.3", "", FCVAR_PLUGIN);	
	
	l4d_rain_chance_tankdead =  CreateConVar("l4d_rain_chance_tankdead", "30", "", FCVAR_PLUGIN); 
	l4d_rain_chance_witchdead =  CreateConVar("l4d_rain_chance_witchdead", "50", " ", FCVAR_PLUGIN); 	
	l4d_rain_chance_witch_harasser =  CreateConVar("l4d_rain_chance_witch_harasser", "20", "", FCVAR_PLUGIN); 	
	
	l4d_spawn_chance_tankrock = 	CreateConVar("l4d_spawn_chance_tankrock", "40", "", FCVAR_PLUGIN);
	l4d_spawn_mincount_tankrock = 	CreateConVar("l4d_spawn_mincount_tankrock", "5", "", FCVAR_PLUGIN);
	l4d_spawn_maxcount_tankrock = 	CreateConVar("l4d_spawn_maxcount_tankrock", "12", "", FCVAR_PLUGIN);
	
	l4d_spawn_chance_spitteracid = 	CreateConVar("l4d_spawn_chance_spitteracid", "80", "", FCVAR_PLUGIN);
	l4d_spawn_mincount_spitteracid = 	CreateConVar("l4d_spawn_mincount_spitteracid", "8", "", FCVAR_PLUGIN);
	l4d_spawn_maxcount_spitteracid = 	CreateConVar("l4d_spawn_maxcount_spitteracid", "16", "", FCVAR_PLUGIN);
	
	l4d_spawn_chance_boomervomit=	CreateConVar("l4d_spawn_chance_boomervomit", "45", "", FCVAR_PLUGIN); 
	
	l4d_spawn_chance_boomerdead=CreateConVar("l4d_spawn_chance_boomerdead", "30", "", FCVAR_PLUGIN);
	l4d_spawn_mincount_boomerdead=CreateConVar("l4d_spawn_mincount_boomerdead", "5", "", FCVAR_PLUGIN);	
	l4d_spawn_maxcount_boomerdead=CreateConVar("l4d_spawn_maxcount_boomerdead", "10", "", FCVAR_PLUGIN);

	l4d_spawn_chance_spitterdead=CreateConVar("l4d_spawn_chance_spitterdead", "30", "", FCVAR_PLUGIN);
	l4d_spawn_mincount_spitterdead=CreateConVar("l4d_spawn_mincount_spitterdead", "3", "", FCVAR_PLUGIN);	
	l4d_spawn_maxcount_spitterdead=CreateConVar("l4d_spawn_maxcount_spitterdead", "8", "", FCVAR_PLUGIN);
		
	l4d_spawn_chance_tankdead=CreateConVar("l4d_spawn_chance_tankdead", "50", "", FCVAR_PLUGIN);
	l4d_spawn_mincount_tankdead=CreateConVar("l4d_spawn_mincount_tankdead", "6", "", FCVAR_PLUGIN);	
	l4d_spawn_maxcount_tankdead=CreateConVar("l4d_spawn_maxcount_tankdead", "15", "", FCVAR_PLUGIN);
	
	
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

	AutoExecConfig(true, "l4d_infected_rain_v11");	 
	
	HookEvent("tank_killed", tank_killed);
	HookEvent("witch_killed", witch_killed);
	
	HookEvent("player_death", Event_PlayerDeath);

	HookEvent("witch_harasser_set", witch_harasser_set);		
	 
	HookEvent("round_start", RoundStart);
	HookEvent("round_end", RoundEnd);
	HookEvent("finale_win", RoundEnd);
	HookEvent("mission_lost", RoundEnd);
	HookEvent("map_transition", RoundEnd);
	
	RegAdminCmd("sm_rain",sm_rain,ADMFLAG_RCON);
	 
	gamestart=false;
}
public Action:sm_rain(client, args)
{
	gamestart=true;
	StartInfectedRain(0);
}
new g_sprite;
public OnMapStart()
{
	if(L4D2Version)
	{
		g_sprite = PrecacheModel("materials/sprites/laserbeam.vmt");	
		
	}
	else
	{
		g_sprite = PrecacheModel("materials/sprites/laser.vmt");	
 
	}
	CreateTimer(10.0,TimerUpdate, _, TIMER_REPEAT);
}
public Action:Event_PlayerDeath(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(gamestart==false || GameMode==2)return;
	if(GetConVarInt(l4d_spawn_enable)==0)return;
	new victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if(victim>0 && IsClientInGame(victim) && GetClientTeam(victim)==3)
	{
		new class = GetEntProp(victim, Prop_Send, "m_zombieClass");
		decl Float:pos[3];
		GetClientAbsOrigin(victim, pos);	
		if(class==ZOMBIECLASS_BOOMER)//boomer
		{
			if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_spawn_chance_boomerdead))
			{
				spawntime=GetEngineTime();
				new count=GetRandomInt(GetConVarInt(l4d_spawn_mincount_boomerdead), GetConVarInt(l4d_spawn_maxcount_boomerdead));
				Z_Add(0, pos, count);
			}
		}
		else if(class==ZOMBIECLASS_SPITTER)//spitter
		{
			if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_spawn_chance_spitterdead))
			{
				spawntime=GetEngineTime();
				new count=GetRandomInt(GetConVarInt(l4d_spawn_mincount_spitterdead), GetConVarInt(l4d_spawn_maxcount_spitterdead));
				Z_Add(0, pos, count);
			}
		}
		else if(class==ZOMBIECLASS_TANK)//spitter
		{
			if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_spawn_chance_tankdead))
			{
				spawntime=GetEngineTime();
				new count=GetRandomInt(GetConVarInt(l4d_spawn_mincount_tankdead), GetConVarInt(l4d_spawn_maxcount_tankdead));
				Z_Add(0, pos, count);
			}
		}
	}
	
}
public OnEntityCreated(entity, const String:classname[])
{
	if(gamestart==false || GameMode==2)return;
	new Float:time=GetEngineTime();
	//PrintToChatAll("create %s", classname);
    if(time-spawntime<0.2)
	{
		if(StrEqual(classname, "infected") )
		{
			CreateTimer(0.1, SetInfecteRush, entity);
		}
	}
}
public OnEntityDestroyed(entity)
{
	if(gamestart==false || GameMode==2)return;
	if(GetConVarInt(l4d_spawn_enable)==0)return;
	decl String:classname[32];
	GetEdictClassname(entity, classname, 32);
	//PrintToChatAll("destory %s", classname);
	if(StrEqual(classname, "tank_rock", true) && GetEntProp(entity, Prop_Send, "m_iTeamNum")>=0)
	{
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_spawn_chance_tankrock))
		{
			decl Float:pos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
			spawntime=GetEngineTime();
			new count=GetRandomInt(GetConVarInt(l4d_spawn_mincount_tankrock), GetConVarInt(l4d_spawn_maxcount_tankrock));
			Z_Add(0, pos, count);
		}
	}
	else if(StrEqual(classname, "spitter_projectile", true))
	{
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_spawn_chance_spitteracid))
		{
			decl Float:pos[3];
			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
			spawntime=GetEngineTime();
			new count=GetRandomInt(GetConVarInt(l4d_spawn_mincount_spitteracid), GetConVarInt(l4d_spawn_maxcount_spitteracid));
			Z_Add(0, pos, count);	
		}
	}
	else if(StrEqual(classname, "vomit_particle", true))
	{
		if(GetRandomFloat(0.0, 100.0)<GetConVarFloat(l4d_spawn_chance_boomervomit))
		{
			decl Float:pos[3];

			GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
			pos[0]+=GetRandomFloat(-40.0,40.0);
			pos[1]+=GetRandomFloat(-40.0,40.0);
			spawntime=GetEngineTime();
			Z_Add(0, pos, 1);
		}
	}
 
}
public Action:SetInfecteRush(Handle:timer, any:ent)
{ 
	 if(ent > 0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		decl String:class[256];
		GetEdictClassname(ent, class, sizeof(class));
		if(StrEqual(class, "infected"))
		{
			SetEntProp(ent,Prop_Send,"m_mobRush",1);
		}
		
	}
	return Plugin_Stop;
}
public Action:tank_killed(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(gamestart==false || GameMode==2)return;
	if(GetRandomFloat(0.0, 100.0)< GetConVarFloat(l4d_rain_chance_tankdead)) StartInfectedRain(0);
}
public Action:witch_killed(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(gamestart==false || GameMode==2)return;
	if(GetRandomFloat(0.0, 100.0)< GetConVarFloat(l4d_rain_chance_witchdead) )	StartInfectedRain(0);
}
public Action:witch_harasser_set(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	if(gamestart==false || GameMode==2)return;
	if(GetRandomFloat(0.0, 100.0)< GetConVarFloat(l4d_rain_chance_witch_harasser) )	StartInfectedRain(0);
}

public Action:TimerUpdate(Handle:timer)
{
	if(gamestart==false || GameMode==2)return Plugin_Continue;
	if(nexttime==0)nexttime=GetRandomInt(GetConVarInt(l4d_rain_mininterval), GetConVarInt(l4d_rain_maxinterval));
	timetick+=10;
	if(timetick>=nexttime)
	{
		StartInfectedRain(0);
 	}
	return Plugin_Continue;
}
SelectAndidata(team, client, Float:hitpos[3])
{
	new selected=0;
	decl andidate[MAXPLAYERS+1];
	new index=0;
	if(client>0)andidate[index++]=client;
	else 
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==team)
			{
				andidate[index++]=i;
			}
		}
	}
	while(index>0)
	{
		new c=GetRandomInt(0, index-1);
		
		decl Float:v[3];
		decl Float:pos[3];
		 
		v[0]=0.0+GetRandomFloat(-20.0, 20.0);
		v[1]=0.0+GetRandomFloat(-20.0, 20.0);
		v[2]=60.0;
		GetVectorAngles(v, v);
		GetClientEyePosition(andidate[c], pos);
		GetRayHitPos2(pos, v, hitpos, andidate[c]);
		new Float:distance=GetVectorDistance(pos, hitpos);
		
		//ShowLarserByPos(pos, hitpos, 0, 12.5);
		if(distance>400.0)
		{
			distance=distance-100.0;
			if(distance>2000.0)distance=2000.0;		
			MakeVectorFromPoints(pos, hitpos, v);
			NormalizeVector(v, v);
			ScaleVector(v, distance);
			AddVectors(pos, v, hitpos);
			selected=andidate[c]; 			
			break;
		} 
		andidate[c]=andidate[--index];		
	}
	
	return selected;
}
public Action:RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	gamestart=true;
}
public Action:RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	gamestart=false;
}


StartInfectedRain(client)
{
	if(GetConVarInt(l4d_rain_enable)==0)return;
	new Handle:h=CreateDataPack();
	WritePackCell(h, client);
	WritePackFloat(h,GetEngineTime()+GetConVarFloat(l4d_rain_duration));	
	CreateTimer(GetConVarFloat(l4d_rain_intervual), UpdateRain, h, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	//PrintToChatAll("start rain");
}
 
public Action:UpdateRain(Handle:timer, any:h)
{  
	if(!gamestart)return Plugin_Stop;
	ResetPack(h);
	new client=ReadPackCell(h);
	new Float:endtime=ReadPackFloat(h);
	new Float:time=GetEngineTime();
 
	if(time<endtime)
	{
	 
		decl Float:hitpos[3];
		client=SelectAndidata(2, client, hitpos);
		if(client>0)
		{
			spawntime=time;
			Z_Add(client, hitpos);
			timetick=nexttime=0;
			
		}		 
	}
	else
	{
		return Plugin_Stop;	
	}
	return Plugin_Continue;
}

 
GetRayHitPos2(Float:pos[3], Float: angle[3], Float:hitpos[3], ent=0)
{
	new Handle:trace ;
	new hit=0;
	
	trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndLive, ent);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex( trace);
	}
	CloseHandle(trace);
	return hit;
}


ShowLarserByPos(Float:pos1[3], Float:pos2[3], flag=0, Float:life=0.06)
{
	decl color[4];
	if(flag==0)
	{
		color[0] = 200; 
		color[1] = 200;
		color[2] = 200;
		color[3] = 230;
	}
	else
	{
		color[0] = 200; 
		color[1] = 0;
		color[2] = 0;
		color[3] = 230;
	}
	
	 
	new Float:width1=0.5;
	new Float:width2=0.5;		
	if(L4D2Version)
	{
		width2=0.3;
		width2=0.3;
	}
 	
	TE_SetupBeamPoints(pos1, pos2, g_sprite, 0, 0, 0, life, width1, width2, 1, 0.0, color, 0);
	TE_SendToAll();
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
 
stock Z_Add(client, Float:pos[], count=1)
{
	if(client<=0)
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) )
			{
				client=i;
			}
		}
	}
	new String:command[]="z_add";
	new userflags = GetUserFlagBits(client);
	SetUserFlagBits(client, ADMFLAG_ROOT);
	new flags = GetCommandFlags(command);
	SetCommandFlags(command, flags & ~FCVAR_CHEAT);
	decl Float:pos2[3];
	for(new i=0; i<count; i++)
	{
		if(count==1)FakeClientCommand(client, "%s %f %f %f", command, pos[0], pos[1], pos[2]);
		else
		{			
			pos2[0] =pos[0]+GetRandomFloat(-40.0,40.0);
			pos2[1] =pos[1]+GetRandomFloat(-40.0,40.0);
			pos2[2]=pos[2];
			FakeClientCommand(client, "%s %f %f %f", command, pos2[0], pos2[1], pos2[2]);
		}
	}
	SetCommandFlags(command, flags);
	SetUserFlagBits(client, userflags);
}