#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0"

new Handle:hEnable;
new EnableTeam;

public Plugin:myinfo =
{
	name = "Player Stacker",
	author = "Blodia",
	description = "Removes player stacking limit",
	version = "1.0",
	url = ""
}

public OnPluginStart()
{
	CreateConVar("playerstacker_version", PLUGIN_VERSION, "Player Stacker version", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED);
	hEnable = CreateConVar("playerstacker_enable", "1", "0 disables plugin, 1 removes stack limit for both teams, 2 removes stack limit for terrorist only, 3 removes stack limit for counter terrorist only", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_REPLICATED, true, 0.0, true, 3.0);
	
	HookConVarChange(hEnable, ConVarChange);
	
	EnableTeam = GetConVarInt(hEnable);
	
	for (new client = 1; client <= MaxClients; client++) 
	{ 
		if (IsClientInGame(client)) 
		{ 
			SDKHook(client, SDKHook_PostThink, OnPostThink);
		} 
	}
}

public ConVarChange(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	if (cvar == hEnable)
	{
		EnableTeam = GetConVarInt(hEnable);
	}
}

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_PostThink, OnPostThink);
}

public OnPostThink(client)
{
	if (!EnableTeam)
	{
		return;
	}
	
	if (!IsPlayerAlive(client))
	{
		return;
	}
	
	if ((EnableTeam > 1) && (GetEntProp(client, Prop_Send, "m_iTeamNum") != EnableTeam))
	{
		return;
	}
	
	// the entity the player is standing on.
	new GroundEnt = GetEntPropEnt(client, Prop_Send, "m_hGroundEntity");
	
	
	// if the player is standing on another player change it to world instead.
	
	if ((GroundEnt > 0) && (GroundEnt <= MaxClients))
	{
		SetEntPropEnt(client, Prop_Send, "m_hGroundEntity", 0);
	}
}