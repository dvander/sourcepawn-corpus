#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION			"1.2.0"

new Handle:g_hEnable = INVALID_HANDLE;
new Handle:g_hChance = INVALID_HANDLE;
new Handle:g_hDelay = INVALID_HANDLE;
new Handle:g_hSuicide = INVALID_HANDLE;
new Handle:g_hLifetime = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Rise from the Dead",
	author = "SoulSharD",
	description = "Spawns a Skeleton on player death.",
	version = PLUGIN_VERSION,
	url = "tf2lottery.com"
};

public OnPluginStart()
{
	CreateConVar("sm_rftd_version", PLUGIN_VERSION, "Rise from the Dead: Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_CHEAT|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hEnable = CreateConVar("sm_rftd_enable", "1", "Enable or Disable this plugin. 1=Enable | 0=Disable")
	g_hChance = CreateConVar("sm_rftd_chance", "0.5", "The chance a Skeleton will spawn on player death.");
	g_hDelay = CreateConVar("sm_rftd_delay", "3", "The delay a Skeleton's spawn will be");
	g_hSuicide = CreateConVar("sm_rftd_suicide", "0", "Enable or Disable spawning if a player suicided.");
	g_hLifetime = CreateConVar("sm_rftd_lifetime", "30", "The lifetime for a Skeleton.");
	
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(g_hEnable) <= 0)
	{
		return Plugin_Continue;
	}
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));
	new Float:random = GetRandomFloat(0.0, 1.0);
	
	if(GetConVarInt(g_hSuicide) <= 0)
	{
		if(!attacker || client == attacker) // He killed himself.
		{
			return Plugin_Continue;
		}
	}
	
	if(random <= GetConVarFloat(g_hChance))
	{
		SpawnSkeleton(client);
	}
	
	return Plugin_Continue;
}

SpawnSkeleton(any:client)
{
	new Float:vecOrigin[3];
	new Float:vecAngles[3];
	GetClientAbsOrigin(client, vecOrigin);
	
	new entity = CreateEntityByName("tf_zombie") // Skeleton
	
	if(IsValidEntity(entity))
	{
		vecAngles[1] = GetRandomFloat(1.0, 360.0);
		TeleportEntity(entity, vecOrigin, vecAngles, NULL_VECTOR);
		
		SetEntProp(entity, Prop_Send, "m_iTeamNum", GetClientTeam(client));
		SetEntProp(entity, Prop_Send, "m_nSkin", GetClientTeam(client) - 2);
		
		CreateTimer(GetConVarFloat(g_hDelay) * 1.0, Timer_SpawnDelay, entity);
	}
}

public Action:Timer_SpawnDelay(Handle:timer, any:entity)
{
	DispatchSpawn(entity);
	CreateTimer(GetConVarFloat(g_hLifetime) * 1.0, Timer_KillSkeleton, entity);
}

public Action:Timer_KillSkeleton(Handle:timer, any:entity)
{
	if(IsValidEntity(entity))
	{
		AcceptEntityInput(entity, "Kill");
	}
}