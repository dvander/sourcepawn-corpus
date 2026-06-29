#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
 
#pragma newdecls required

#define ZOMBIECLASS_BOOMER	2
#define ZOMBIECLASS_SPITTER	4
int     ZOMBIECLASS_TANK  = 5;

Handle l4d_rain_enable,              l4d_spawn_enable; 
Handle l4d_rain_mininterval,         l4d_rain_maxinterval,           l4d_rain_duration,             l4d_rain_intervual;
Handle l4d_rain_chance_tankdead,     l4d_rain_chance_witchdead,      l4d_rain_chance_witch_harasser;
Handle l4d_spawn_chance_tankrock,    l4d_spawn_mincount_tankrock,    l4d_spawn_maxcount_tankrock ;
Handle l4d_spawn_chance_spitteracid, l4d_spawn_mincount_spitteracid, l4d_spawn_maxcount_spitteracid;
Handle l4d_spawn_chance_boomervomit, l4d_spawn_chance_boomerdead,    l4d_spawn_mincount_boomerdead, l4d_spawn_maxcount_boomerdead;
Handle l4d_spawn_chance_spitterdead, l4d_spawn_mincount_spitterdead, l4d_spawn_maxcount_spitterdead;
Handle l4d_spawn_chance_tankdead,    l4d_spawn_mincount_tankdead,    l4d_spawn_maxcount_tankdead;

int   timetick = 0, nexttime = 0;
float spawntime = 0.0;

public Plugin myinfo = 
{
	name = "Infected Rain",
	author = "Pan Xiaohai, AlexMy",
	description = "Infected  Rain",
	version = "1.2",
	url = "https://forums.alliedmods.net/showthread.php?p=1445842"
}

public void OnPluginStart()
{
	l4d_rain_enable                = CreateConVar("l4d_rain_enable", "1", "{0,1}",                             FCVAR_PLUGIN); 
	l4d_spawn_enable               = CreateConVar("l4d_spawn_enable", "1", "{0,1}",                            FCVAR_PLUGIN); 
	
	l4d_rain_mininterval           = CreateConVar("l4d_rain_mininterval", "150", "[200, maxinterval]seconds ", FCVAR_PLUGIN); 
	l4d_rain_maxinterval           = CreateConVar("l4d_rain_maxinterval", "300", "[200, 600]seconds ",         FCVAR_PLUGIN);	
	l4d_rain_duration              = CreateConVar("l4d_rain_duration", "15.0", "",                             FCVAR_PLUGIN);	
	l4d_rain_intervual             = CreateConVar("l4d_rain_intervual", "0.3", "",                             FCVAR_PLUGIN);	
	
	l4d_rain_chance_tankdead       = CreateConVar("l4d_rain_chance_tankdead", "50", "0 - 100%",                FCVAR_PLUGIN); 
	l4d_rain_chance_witchdead      = CreateConVar("l4d_rain_chance_witchdead", "50", " ",                      FCVAR_PLUGIN); 	
	l4d_rain_chance_witch_harasser = CreateConVar("l4d_rain_chance_witch_harasser", "20", "",                  FCVAR_PLUGIN); 	
	
	l4d_spawn_chance_tankrock      = CreateConVar("l4d_spawn_chance_tankrock", "60", "",                       FCVAR_PLUGIN);
	l4d_spawn_mincount_tankrock    = CreateConVar("l4d_spawn_mincount_tankrock", "5", "",                      FCVAR_PLUGIN);
	l4d_spawn_maxcount_tankrock    = CreateConVar("l4d_spawn_maxcount_tankrock", "12", "",                     FCVAR_PLUGIN);
	
	l4d_spawn_chance_spitteracid   = CreateConVar("l4d_spawn_chance_spitteracid", "80", "",                    FCVAR_PLUGIN);
	l4d_spawn_mincount_spitteracid = CreateConVar("l4d_spawn_mincount_spitteracid", "8", "",                   FCVAR_PLUGIN);
	l4d_spawn_maxcount_spitteracid = CreateConVar("l4d_spawn_maxcount_spitteracid", "16", "",                  FCVAR_PLUGIN);
	
	l4d_spawn_chance_boomervomit   = CreateConVar("l4d_spawn_chance_boomervomit", "70", "",                    FCVAR_PLUGIN); 
	
	l4d_spawn_chance_boomerdead    = CreateConVar("l4d_spawn_chance_boomerdead", "70", "",                     FCVAR_PLUGIN);
	l4d_spawn_mincount_boomerdead  = CreateConVar("l4d_spawn_mincount_boomerdead", "5", "",                    FCVAR_PLUGIN);	
	l4d_spawn_maxcount_boomerdead  = CreateConVar("l4d_spawn_maxcount_boomerdead", "10", "",                   FCVAR_PLUGIN);

	l4d_spawn_chance_spitterdead   = CreateConVar("l4d_spawn_chance_spitterdead", "30", "",                    FCVAR_PLUGIN);
	l4d_spawn_mincount_spitterdead = CreateConVar("l4d_spawn_mincount_spitterdead", "3", "",                   FCVAR_PLUGIN);	
	l4d_spawn_maxcount_spitterdead = CreateConVar("l4d_spawn_maxcount_spitterdead", "8", "",                   FCVAR_PLUGIN);
		
	l4d_spawn_chance_tankdead      = CreateConVar("l4d_spawn_chance_tankdead", "50", "",                       FCVAR_PLUGIN);
	l4d_spawn_mincount_tankdead    = CreateConVar("l4d_spawn_mincount_tankdead", "6", "",                      FCVAR_PLUGIN);	
	l4d_spawn_maxcount_tankdead    = CreateConVar("l4d_spawn_maxcount_tankdead", "15", "",                     FCVAR_PLUGIN);
	
	
	char GameName[16];
	GetGameFolderName(GameName, sizeof(GameName));
	if (StrEqual(GameName, "left4dead2", false))
	{
		ZOMBIECLASS_TANK = 8;
	}	
	else
	{
		ZOMBIECLASS_TANK = 5;
	}

	AutoExecConfig(true, "l4d_infected_rain");	 
	
	HookEvent("tank_killed",        EventTankKilled);
	HookEvent("witch_killed",       EventWitchKilled);
	HookEvent("player_death",       EventPlayerDeath);
	HookEvent("witch_harasser_set", EventWitchHarasserSet);
	
	HookEvent("round_start",		EventRoundStart);
	
	RegAdminCmd("sm_rain",sm_rain,ADMFLAG_RCON);
}
public Action sm_rain(int client, int args)
{
	if(client) StartInfectedRain(0);
	return Plugin_Handled;
}
public void EventPlayerDeath(Event hEvent, const char [] strName, bool DontBroadcast)
{
	if(GetConVarInt(l4d_spawn_enable))
	{
		int victim = GetClientOfUserId(GetEventInt(hEvent, "userid"));
		if(victim > 0 && IsClientInGame(victim) && GetClientTeam(victim)==3)
		{
			int class = GetEntProp(victim, Prop_Send, "m_zombieClass");
			float pos[3];
			GetClientAbsOrigin(victim, pos);
			if(class == ZOMBIECLASS_BOOMER)
			{
				if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_spawn_chance_boomerdead))
				{
					spawntime = GetEngineTime();
					int count = GetRandomInt(GetConVarInt(l4d_spawn_mincount_boomerdead), GetConVarInt(l4d_spawn_maxcount_boomerdead));
					Z_Add(0, pos, count);
				}
			}
			else if(class == ZOMBIECLASS_SPITTER)
			{
				if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_spawn_chance_spitterdead))
				{
					spawntime = GetEngineTime();
					int count = GetRandomInt(GetConVarInt(l4d_spawn_mincount_spitterdead), GetConVarInt(l4d_spawn_maxcount_spitterdead));
					Z_Add(0, pos, count);
				}
			}
			else if(class == ZOMBIECLASS_TANK)
			{
				if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_spawn_chance_tankdead))
				{
					spawntime = GetEngineTime();
					int count =GetRandomInt(GetConVarInt(l4d_spawn_mincount_tankdead), GetConVarInt(l4d_spawn_maxcount_tankdead));
					Z_Add(0, pos, count);
				}
			}
		}
	}
}
public void OnEntityCreated(int entity, const char []classname)
{
	float time = GetEngineTime();
	if(time-spawntime < 0.2)
	{
		if(StrEqual(classname, "infected"))
		{
			CreateTimer(0.1, SetInfecteRush, entity, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}
public void OnEntityDestroyed(int entity)
{
	if(GetConVarInt(l4d_spawn_enable))
	{
		if(IsValidEntity(entity) && IsValidEdict(entity))
		{
			char classname[64];
			float pos[3];
			GetEdictClassname(entity, classname, sizeof(classname));
			if(StrEqual(classname, "tank_rock", false) && GetEntProp(entity, Prop_Send, "m_iTeamNum")>=0)
			{
				if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_spawn_chance_tankrock))
				{
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
					spawntime = GetEngineTime();
					int count = GetRandomInt(GetConVarInt(l4d_spawn_mincount_tankrock), GetConVarInt(l4d_spawn_maxcount_tankrock));
					Z_Add(0, pos, count);
				}
			}
			else if(StrEqual(classname, "spitter_projectile", false))
			{
				if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_spawn_chance_spitteracid))
				{
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
					spawntime = GetEngineTime();
					int count = GetRandomInt(GetConVarInt(l4d_spawn_mincount_spitteracid), GetConVarInt(l4d_spawn_maxcount_spitteracid));
					Z_Add(0, pos, count);
				}
			}
			else if(StrEqual(classname, "vomit_particle", false))
			{
				if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_spawn_chance_boomervomit))
				{
					GetEntPropVector(entity, Prop_Send, "m_vecOrigin", pos);
					pos[0]+=GetRandomFloat(-40.0,40.0);
					pos[1]+=GetRandomFloat(-40.0,40.0);
					spawntime=GetEngineTime();
					Z_Add(0, pos, 1);
				}
			}
		}
	}
}
public Action SetInfecteRush(Handle timer, any ent)
{
	if(ent > 0 && IsValidEntity(ent) && IsValidEdict(ent))
	{
		char class[256];
		GetEdictClassname(ent, class, sizeof(class));
		if(StrEqual(class, "infected"))
		{
			SetEntProp(ent,Prop_Send,"m_mobRush",1);
		}
	}
	return Plugin_Stop;
}
public void EventRoundStart(Event hEvent, const char [] strName, bool DontBroadcast)
{
	CreateTimer(10.0, TimerUpdate, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}
public void EventTankKilled(Event hEvent, const char [] strName, bool DontBroadcast)
{
	if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_rain_chance_tankdead)) StartInfectedRain(0);
}
public void EventWitchKilled(Event hEvent, const char [] strName, bool DontBroadcast)
{
	if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_rain_chance_witchdead))	StartInfectedRain(0);
}
public void EventWitchHarasserSet(Event hEvent, const char [] strName, bool DontBroadcast)
{
	if(GetRandomFloat(0.0, 100.0) < GetConVarFloat(l4d_rain_chance_witch_harasser))	StartInfectedRain(0);
}
public Action TimerUpdate(Handle timer)
{
	if(nexttime==0)nexttime=GetRandomInt(GetConVarInt(l4d_rain_mininterval), GetConVarInt(l4d_rain_maxinterval));
	timetick+=10;
	if(timetick>=nexttime)
	{
		StartInfectedRain(0);
 	}
	return Plugin_Continue;
}
int SelectAndidata(int team, int client, float hitpos[3])
{
	int selected=0;
	char andidate[MAXPLAYERS+1];
	int index=0;
	if(client>0)andidate[index++]=client;
	else 
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i)==team)
			{
				andidate[index++]=i;
			}
		}
	}
	while(index>0)
	{
		int c=GetRandomInt(0, index-1);
		float v[3], pos[3];
		
		v[0]=0.0+GetRandomFloat(-20.0, 20.0);
		v[1]=0.0+GetRandomFloat(-20.0, 20.0);
		v[2]=60.0;
		GetVectorAngles(v, v);
		GetClientEyePosition(andidate[c], pos);
		GetRayHitPos2(pos, v, hitpos, andidate[c]);
		float distance=GetVectorDistance(pos, hitpos);
		
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

void StartInfectedRain(int client)
{
	if(GetConVarInt(l4d_rain_enable))
	{
		Handle h=CreateDataPack();
		WritePackCell(h, client);
		WritePackFloat(h,GetEngineTime()+GetConVarFloat(l4d_rain_duration));	
		CreateTimer(GetConVarFloat(l4d_rain_intervual), UpdateRain, h, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
	}
}
 
public Action UpdateRain(Handle timer, any h)
{
	ResetPack(h);
	int client=ReadPackCell(h);
	float endtime=ReadPackFloat(h);
	float time=GetEngineTime();
 
	if(time<endtime)
	{
		float hitpos[3];
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

int GetRayHitPos2(float pos[3], float angle[3], float hitpos[3], int ent=0)
{
	Handle trace ;
	int hit=0;
	
	trace= TR_TraceRayFilterEx(pos, angle, MASK_SOLID, RayType_Infinite, TraceRayDontHitSelfAndLive, ent);
	if(TR_DidHit(trace))
	{
		TR_GetEndPosition(hitpos, trace);
		hit=TR_GetEntityIndex( trace);
	}
	CloseHandle(trace);
	return hit;
}

public bool TraceRayDontHitSelfAndLive(int entity, int mask, any data)
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
 
stock void Z_Add(int client, float [] pos, int count=1)
{
	if(client<=0)
	{
		for(int i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
			{
				client=i;
			}
		}
	}
	if(client)
	{
		char command [] = "z_add";
		int userflags = GetUserFlagBits(client);
		SetUserFlagBits(client, ADMFLAG_ROOT);
		int flags = GetCommandFlags(command);
		SetCommandFlags(command, flags & ~FCVAR_CHEAT);
		float pos2[3];
		for(int i=0; i<count; i++)
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
}