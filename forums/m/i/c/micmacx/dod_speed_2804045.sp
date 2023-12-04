#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#define PLUGIN_VERSION "1.0"

new Handle:cvar_speed_enable;
new Handle:cvar_speed_mul;

public Plugin:myinfo = 
{
	name = "DoD:S Speed", 
	author = "Micmacx", 
	description = "Manage speed in DoD:S", 
	version = PLUGIN_VERSION, 
	url = "https://dods.135db.fr"
};

public OnPluginStart()
{
	CreateConVar("dod_speed_version", PLUGIN_VERSION, "DoD plugin Version", FCVAR_DONTRECORD | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	cvar_speed_enable = CreateConVar("dod_speed_enable", "1", "Enabled/Disabled plugin, 0 = off/1 = on", FCVAR_DONTRECORD | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_speed_mul = CreateConVar("dod_speed_multiplicator", "1.1", "Setting Speed", _, true, 0.0, true, 2.0);
	HookEvent("player_spawn", SpawnEvent);
	AutoExecConfig(true, "dod_speed", "dod_speed");
}

public OnEventShutdown()
{
	UnhookEvent("player_spawn", SpawnEvent);
}

public SpawnEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvar_speed_enable))
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		if(IsValidClient(client))
		{
			CreateTimer(0.1, Speed_Player, client, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public Action:Speed_Player(Handle:timer, any:client)
{
	if (IsValidClient(client) && IsPlayerAlive(client))
	{
		float speed = GetConVarFloat(cvar_speed_mul);
		SetEntPropFloat(client, Prop_Send, "m_flLaggedMovementValue", speed);
	}
}

bool IsValidClient(int client)
{
	if (client > 0 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client))
	{
		return true;
	}
	else
	{
		return false;
	}
}
