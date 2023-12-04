#pragma semicolon 1
#pragma newdecls required
 
#include <sdktools>
#include <sdkhooks>

#include <left4dhooks>

// #define _DEBUG

#if defined _DEBUG
	#define LOG(%0) LogMessage(%0)
#else
	#define LOG(%0) (0)
#endif

#define THINK_INTERVAL 1.0

public Plugin myinfo =
{
	name = "[L4D2] Realistic Pipe Bomb",
	author = "BHaType",
	version = "0.0"
}

enum struct	CContext
{
	ArrayList projectiles;
	float time;
	Handle timer;
	bool init;
	
	void Init()
	{
		if ( this.init )
			return;
			
		this.init = true;
		this.projectiles = new ArrayList();
	}
	
	bool Start( int entity )
	{
		if ( this.timer )
			return false;
		
		this.time = GetExplodeTime();
		this.timer = CreateTimer(this.time, timer_explode, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
		
		return true;
	}
	
	bool Stop()
	{
		if ( !this.timer )
			return false;
		
		delete this.timer;
		return true;
	}
}

CContext g_Context[MAXPLAYERS + 1];
Handle g_hTimer;
ConVar pipe_bomb_timer_duration;

public void OnPluginStart()
{
	pipe_bomb_timer_duration = FindConVar("pipe_bomb_timer_duration");
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_Context[i].Init();
		
		if ( !IsClientInGame(i) )
			continue;
		
		OnClientPutInServer(i);
	}
}

public void OnMapEnd()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		g_Context[i].timer = null;
	}
}

public void OnClientPutInServer(int client)
{	
	SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitch);
}

public void OnWeaponSwitch( int client, int weapon )
{
	if ( g_Context[client].time <= 0 )
		return;
		
	g_Context[client].Stop();
	g_Context[client].time = 0.0;
}

public void OnPlayerRunCmdPost( int client, int buttons )
{
	if ( !g_Context[client].timer )
	{
		if ( buttons & IN_ATTACK )
		{
			int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
			
			if ( weapon == -1 )
				return;
			
			if ( !MatchClassname(weapon, "weapon_pipe_bomb") || !g_Context[client].Start(weapon) )
				return;
			
			LOG("Started projectile explode");
			
			if ( !g_hTimer )
			{
				LOG("Started projectiles think");
				g_hTimer = CreateTimer(THINK_INTERVAL, timer_projectiles_think, .flags = TIMER_FLAG_NO_MAPCHANGE | TIMER_REPEAT);
				TriggerTimer(g_hTimer);
			}
		}
	}
	else 
	{	
		if ( !(buttons & IN_ATTACK) )
		{
			if ( g_Context[client].Stop() )
			{
				LOG("%N throwed or switched weapon", client);
			}
		}
	}
}

public Action timer_explode_projectile( Handle timer, int client )
{
	if ( !g_Context[client].projectiles.Length )
		return Plugin_Continue;
		
	int projectile = g_Context[client].projectiles.Get(0);
	g_Context[client].projectiles.Erase(0);
	
	if ( (projectile = EntRefToEntIndex(projectile)) <= MaxClients || !IsValidEntity(projectile) )
		return Plugin_Continue;

	L4D_DetonateProjectile(projectile);
	return Plugin_Continue;
}

public Action timer_explode( Handle timer, int projectile )
{
	if ( (projectile = EntRefToEntIndex(projectile)) <= MaxClients || !IsValidEntity(projectile) )
		return Plugin_Continue;
	
	int owner = GetEntPropEnt(projectile, Prop_Data, "m_hOwner");
	
	if ( owner == -1 )
		return Plugin_Continue;
	
	LOG("Explode!");
	
	float vOrigin[3];
	GetClientEyePosition(owner, vOrigin);
	
	RemovePlayerItem(owner, projectile);
	
	int pipe_bomb = L4D_PipeBombPrj(owner, vOrigin, view_as<float>({0.0, 0.0, 0.0}));
	L4D_DetonateProjectile(pipe_bomb);
	
	g_Context[owner].timer = null;
	return Plugin_Continue;
}

public Action timer_projectiles_think( Handle timer )
{
	bool set;
	
	for ( int i = 1; i <= MaxClients; i++ )
	{
		if ( !IsClientInGame(i) || g_Context[i].time <= 0 )
			continue;
		
		g_Context[i].time -= THINK_INTERVAL;
		
		if ( g_Context[i].time < 0.0 )
			g_Context[i].time = 0.0;
		
		PrintHintText(i, "Time to detonate %.1f", g_Context[i].time);
		set = true;
	}
 
	if ( !set )
	{
		LOG("Stopped projectiles think");
		g_hTimer = null;
		return Plugin_Stop;
	}
	
	return Plugin_Continue;
}

public void OnEntityCreated( int entity, const char[] name )
{
	if ( strcmp(name, "pipe_bomb_projectile") != 0 )
		return;
		
	SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}
 
public void OnSpawnPost( int entity )
{
	RequestFrame(NextFrame, EntIndexToEntRef(entity));
}

public void NextFrame(int entity)
{
	if ( (entity = EntRefToEntIndex(entity)) <= MaxClients || !IsValidEntity(entity) )
		return;
	
	int client = GetEntPropEnt(entity, Prop_Data, "m_hThrower");
	
	if ( client > 0 && client <= MaxClients && IsClientInGame(client))
	{
		g_Context[client].projectiles.Push(EntIndexToEntRef(entity));
		CreateTimer(g_Context[client].time, timer_explode_projectile, client);
	}
}

float GetExplodeTime()
{
	return pipe_bomb_timer_duration.FloatValue;
}

bool MatchClassname( int entity, const char[] name )
{
	char classname[36];
	GetEntityClassname(entity, classname, sizeof classname);
	
	return strcmp(classname, name, false) == 0;
}