#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <sdkhooks>

#define PLUGIN_VERSION "1.1"

new bool:IsInSpawn[MAXPLAYERS+1] = false;
new bool:WasRegen[MAXPLAYERS+1] = false;

new Handle:g_hDelay = INVALID_HANDLE;
new Float:g_fDelay = 0.2;

public Plugin:myinfo = 
{
	name = "[TF2] Double Regen",
	author = "EHG",
	description = "Double Regen in Spawn",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("tf2_double_regen_version", PLUGIN_VERSION, "[TF2] Double Regen Version", FCVAR_REPLICATED|FCVAR_NOTIFY | FCVAR_PLUGIN | FCVAR_SPONLY);
	
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("post_inventory_application", Event_Inventory_Application,  EventHookMode_Post);
	g_hDelay = CreateConVar("sm_DoubleRegen_delay", "0.2", "Double Regen delay");
	HookConVarChange(g_hDelay, Cvar_delay);
}

public OnClientDisconnect(client)
{
	IsInSpawn[client] = false;
	WasRegen[client] = false;
}

public OnClientPostAdminCheck(client)
{
	IsInSpawn[client] = false;
	WasRegen[client] = false;
}

public Cvar_delay(Handle:convar, const String:oldValue[], const String:newValue[]) {
	g_fDelay = GetConVarFloat(g_hDelay);
}

public Event_Inventory_Application(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	CreateTimer(g_fDelay, Timer_Inventory_Application, any:client);
}

public Action:Timer_Inventory_Application(Handle:timer, any:client)
{
	if (WasRegen[client])
	{
		WasRegen[client] = false;
	}
	else if (IsInSpawn[client])
	{
		WasRegen[client] = true;
		TF2_RegeneratePlayer(client);
	}
}

public Action:Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	IsInSpawn[client] = true;
}

public OnEntityCreated(entity, const String:classname[])
{
	if (strcmp(classname, "func_respawnroom") == 0)
	{
		SDKHook(entity, SDKHook_StartTouch, SpawnStartTouch);
		SDKHook(entity, SDKHook_EndTouch, SpawnEndTouch);
	}
}

public SpawnStartTouch(entity, other)
{
	if (other <= MaxClients && other >= 1)
	{
		if(IsClientConnected(other))
		{
			if (IsClientInGame(other) && !IsFakeClient(other))
			{
				IsInSpawn[other] = true;
			}
		}
	}
}

public SpawnEndTouch(entity, other)
{
	if (other <= MaxClients && other >= 1)
	{
		if(IsClientConnected(other))
		{
			if (IsClientInGame(other) && !IsFakeClient(other))
			{
				IsInSpawn[other] = false;
			}
		}
	}
}