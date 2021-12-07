#pragma semicolon 1

#include <sourcemod>
#include <tf2_stocks>

#define PLUGIN_VERSION "1.0.0"

new Handle:cvarEnabled;

public Plugin:myinfo =
{
	name = "UberTaunts",
	author = "ReFlexPoison",
	description = "Makes player uber while taunting",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_ubertaunt_version", PLUGIN_VERSION, "UberTaunts Version", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);

	cvarEnabled = CreateConVar("sm_ubertaunt_enabled", "1", "Enable UberTaunts\n0 = Disabled\n1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	CreateTimer(0.1, Timer_UberTaunt, _, TIMER_REPEAT);
}

public Action:Timer_UberTaunt(Handle:timer)
{
	new bool:Enabled = GetConVarBool(cvarEnabled);
	if(!Enabled) return Plugin_Continue;

	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsValidClient(i))
		{
			if(TF2_IsPlayerInCondition(i, TFCond_Taunting)) TF2_AddCondition(i, TFCond_Ubercharged, 0.2);
		}
	}
	return Plugin_Continue;
}

stock bool:IsValidClient(client, bool:replay = true)
{
	if(client <= 0 || client > MaxClients || !IsClientInGame(client) || GetEntProp(client, Prop_Send, "m_bIsCoaching")) return false;
	if(replay && (IsClientSourceTV(client) || IsClientReplay(client))) return false;
	return true;
}