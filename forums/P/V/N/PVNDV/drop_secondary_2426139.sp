#pragma semicolon 1

#include <sourcemod>
#include <sdkhooks>
#include <sdktools>

new g_PlayerSecondaryWeapons[MAXPLAYERS + 1];

public Plugin:myinfo =
{
	name		= "L4D2 Drop Secondary",
	author		= "Jahze, Visor, NoBody",
	version		= "1.4",
	description	= "Survivor players will drop their secondary weapon when they die",
	url		= "https://github.com/Attano/Equilibrium"
};

public OnPluginStart()
{
	HookEvent("round_start", EventHook:OnRoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_use", OnPlayerUse, EventHookMode_Post);
	HookEvent("player_bot_replace", player_bot_replace);
	HookEvent("bot_player_replace", bot_player_replace);
	HookEvent("player_death", OnPlayerDeath, EventHookMode_Pre);
}

public OnRoundStart() 
{
	for (new i = 0; i <= MAXPLAYERS; i++) 
	{
		g_PlayerSecondaryWeapons[i] = -1;
	}
}

public Action:OnPlayerUse(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == 0 || !IsClientInGame(client))
	{
		return;
	}
	
	new weapon = GetPlayerWeaponSlot(client, 1);
	
	g_PlayerSecondaryWeapons[client] = (weapon == -1 ? weapon : EntIndexToEntRef(weapon));
}

public Action:bot_player_replace(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));
	new client = GetClientOfUserId(GetEventInt(event, "player"));

	g_PlayerSecondaryWeapons[client] = g_PlayerSecondaryWeapons[bot];
	g_PlayerSecondaryWeapons[bot] = -1;
}

public Action:player_bot_replace(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "player"));
	new bot = GetClientOfUserId(GetEventInt(event, "bot"));

	g_PlayerSecondaryWeapons[bot] = g_PlayerSecondaryWeapons[client];
	g_PlayerSecondaryWeapons[client] = -1;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(client == 0 || !IsClientInGame(client))
	{
		return;
	}
	
	new weapon = EntRefToEntIndex(g_PlayerSecondaryWeapons[client]);
	
	if(weapon == INVALID_ENT_REFERENCE)
	{
		return;
	}
	
	new OwnerEntity = GetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity");
	
	if (OwnerEntity != client) 
	{
		SetEntPropEnt(weapon, Prop_Send, "m_hOwnerEntity", client);
	}

	SDKHooks_DropWeapon(client, weapon, NULL_VECTOR, NULL_VECTOR);
}
/*
stock bool:IsSurvivor(client) 
{
	if (client <= 0 || client > MaxClients) 
	{
		return false;
	}

	if (!IsClientInGame(client) || GetClientTeam(client) == 2) 
	{
		return false;
	}

	return true;
}
*/