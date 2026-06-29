#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "0.1"

new Handle:g_hSPResetTime;

new bool:g_IsSpawned[MAXPLAYERS+1];
new bool:g_IsProtected[MAXPLAYERS+1];
new Handle:g_hSPTimers[MAXPLAYERS+1];

SpawnProtect(client,v)
{
	if(v == 1 && IsClientConnected(client) && IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 0, 1);
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 2);
		SetEntityRenderColor(client, 255, 255, 255, 128);
		SetEntityRenderMode(client, RENDER_TRANSCOLOR);
		g_IsProtected[client] = true;
	}
	else if(v == 0 && IsClientConnected(client) && IsClientInGame(client))
	{
		SetEntProp(client, Prop_Data, "m_takedamage", 2, 1);
		SetEntProp(client, Prop_Data, "m_CollisionGroup", 5);
		SetEntityRenderColor(client, 255, 255, 255, 255);
		SetEntityRenderMode(client, RENDER_NORMAL);
		g_IsProtected[client] = false;
	}
}

public Plugin:myinfo = 
{
	name = "RP Spawn SpawnProtect",
	author = "Smacked",
	description = "RP Players have NoBlock untill move",
	version = PLUGIN_VERSION,
	url = "N/A"
}

public OnPluginStart()
{
	CreateConVar("rp_spawnprotect_version", PLUGIN_VERSION, "Plugin RP Spawn Protect current version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hSPResetTime = CreateConVar("rp_spawnprotect_resettime", "2", "Amount of seconds the players spawnprotection will be reset after movement or attack", FCVAR_PLUGIN, true, 1.0, false, 10.0);
	
	HookEvent( "player_spawn", PlayerSpawn_Event, EventHookMode_Post);
	HookEvent( "player_death", PlayerDeath_Event, EventHookMode_Post);
	
	for (new client = 1; client <= MaxClients; client++) 
	{ 
        if (IsClientConnected(client))
		{
			g_IsSpawned[client] = false;
			g_IsProtected[client] = false;
			g_hSPTimers[client] = INVALID_HANDLE;
		}
    }
}

public OnClientPutInServer(client)
{
	g_IsSpawned[client] = false;
	g_IsProtected[client] = false;
	g_hSPTimers[client] = INVALID_HANDLE;
}

public OnClientDisconnect(client)
{
	g_IsSpawned[client] = false;
	g_IsProtected[client] = false;
	if(g_hSPTimers[client] != INVALID_HANDLE)
	{
		KillTimer(g_hSPTimers[client]);
		g_hSPTimers[client] = INVALID_HANDLE;
	}
}

public Action:PlayerSpawn_Event( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client != 0)
	{
		g_IsSpawned[client] = true;
		if(!g_IsProtected[client])
		{
			SpawnProtect(client, 1);
		}
		if(g_hSPTimers[client] != INVALID_HANDLE)
		{
			KillTimer(g_hSPTimers[client]);
			g_hSPTimers[client] = INVALID_HANDLE;
		}
	}
	return Plugin_Continue;
}

public Action:PlayerDeath_Event( Handle:event, const String:name[], bool:dontBroadcast )
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (client != 0)
	{
		g_IsSpawned[client] = false;
		if(g_IsProtected[client])
		{
			SpawnProtect(client, 0);
		}
		if(g_hSPTimers[client] != INVALID_HANDLE)
		{
			KillTimer(g_hSPTimers[client]);
			g_hSPTimers[client] = INVALID_HANDLE;
		}
	}
}

public Action:ResetSP(Handle:timer, any:client)
{
	if (client != 0 && IsPlayerAlive(client) && IsClientInGame(client))
	{
		if(g_IsProtected[client])
		{
			SpawnProtect(client, 0);
		}
		if(g_hSPTimers[client] != INVALID_HANDLE)
		{
			KillTimer(g_hSPTimers[client]);
			g_hSPTimers[client] = INVALID_HANDLE;
		}
	}
	return Plugin_Stop;
}

public Action:OnPlayerRunCmd(client, &buttons, &impulse, Float:vel[3], Float:angles[3], &weapon)
{
	if ( g_IsSpawned[client] && (
	((buttons & IN_FORWARD)) ||
	((buttons & IN_BACK)) ||
	((buttons & IN_MOVERIGHT)) ||
	((buttons & IN_MOVELEFT)) ||
	((buttons & IN_ATTACK)) ||
	((buttons & IN_ATTACK2)) ||
	((buttons & IN_DUCK)) ||
	((buttons & IN_JUMP)) ||
	((buttons & IN_SPEED))
	)
	) 
	{
		g_IsSpawned[client] = false;
		g_hSPTimers[client] = CreateTimer(GetConVarFloat(g_hSPResetTime), ResetSP, client, 0);
	}
	return Plugin_Continue;
}
	