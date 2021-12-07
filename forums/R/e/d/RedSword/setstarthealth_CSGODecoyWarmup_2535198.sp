#pragma semicolon 1

#include <sdktools>

#define PLUGIN_VERSION "1.0.1vCSGODecoyWarmup"

public Plugin:myinfo =
{
	name = "Set Start Health",
	author = "RedSword / Bob Le Ponge", //Based on sm_sethealth code by MrBlip (useful for TF2)
	description = "Set health of a player when he spawns or when round starts",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

//CVars
new Handle:g_hStartHealth;
new Handle:g_hStartHealthValue;

new g_iWpnOffset;

public OnPluginStart()
{
	//CVARs
	CreateConVar("setstarthealthversion", PLUGIN_VERSION, "Set Health on Spawn version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	g_hStartHealth		= CreateConVar("starthealth", "1", "Is plugin enabled ? 0=No, 1+ =Yes. 2=team 1 only. 3=team 2 only", 
		FCVAR_NOTIFY, true, 0.0, true, 3.0);
	g_hStartHealthValue	= CreateConVar("starthealth_value", "100.0", "Value to change health to. Minimum 1.", 
		FCVAR_NOTIFY, true, 1.0);
	
	//Config
	AutoExecConfig(true, "setstarthealth");
	
	//Hooks
	HookEvent("player_spawn", Event_Spawn);
	HookEvent("round_start", Event_RoundStart);
	
	g_iWpnOffset = FindSendPropInfo("CCSPlayer", "m_hMyWeapons");
}

//=====Events

public Event_Spawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new enabled = GetConVarInt(g_hStartHealth);
	
	if (enabled == 0)
		return bool:Plugin_Continue;
	
	new userId = GetEventInt(event, "userid");
	new clientId = GetClientOfUserId(userId);
	if (clientId != 0 && IsClientInGame(clientId) && IsPlayerAlive(clientId))
	{
		if (enabled == 1 || GetClientTeam(clientId) == enabled)
		{
			CreateTimer(0.0, Timer_SetHealth, userId);
		}
	}
	
	return bool:Plugin_Handled;
}

//Round start may happen after the first spawn-wave (Wpn Restrict uses round start; so we need this hook too; unless they are done in the same frame ? ¯\_ツ_/¯)
public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	new enabled = GetConVarInt(g_hStartHealth);
	
	if (enabled == 0)
		return bool:Plugin_Continue;
	
	for (new i = 1; i <= MaxClients; ++i)
	{
		if (IsClientInGame(i) && IsPlayerAlive(i))
		{
			if (enabled == 1 || GetClientTeam(i) == enabled)
			{
				CreateTimer(0.0, Timer_SetHealth, GetClientUserId(i));
			}
		}
	}
	
	return bool:Plugin_Handled;
}

public Action:Timer_SetHealth(Handle:Timer, any:data)
{
	new clientId = GetClientOfUserId(data);
	if (clientId != 0 && IsClientInGame(clientId) && IsPlayerAlive(clientId))
	{
		setClientHealth(clientId, GetConVarInt(g_hStartHealthValue));
	}
}

//=====Private

//Client is INGAME and ALIVE
setClientHealth(any:iClient, any:value)
{
	//Not in warmup
	if (bool:GameRules_GetProp("m_bWarmupPeriod") == false)
	{
		return;
	}
	
	if (isDecoyPresent(iClient) == false)
	{
		return;
	}
	
	//Then set health
	SetEntityHealth(iClient, value);
}

bool:isDecoyPresent(client)
{
	int entity;
	new String:className[64];
	for (int i = 0; i < 32; ++i)
	{
		entity = GetEntDataEnt2(client, g_iWpnOffset + i * 4);
		
		if (entity == -1)
		{
			continue;
		}
		
		GetEntityClassname(entity, className, sizeof(className));
		
		if (StrEqual(className, "weapon_decoy"))
		{
			return true;
		}
	}
	
	return false;
}