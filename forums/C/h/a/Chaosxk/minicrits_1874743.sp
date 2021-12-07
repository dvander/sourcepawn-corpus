#pragma semicolon 1

#include <sourcemod>
#include <tf2>

#define PLUGIN_VERSION "1.0"

new Handle:cvarEnabled = INVALID_HANDLE;

public Plugin:myinfo =
{
	name = "[TF2] Mini-Crits",
	author = "Tak (Chaosxk)",
	description = "No...NO...NOOOO!!!",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net"
}

public OnPluginStart()
{
	CreateConVar("sm_minicrits_version", PLUGIN_VERSION, "Version of Mini-Crits plugin.", FCVAR_REPLICATED | FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_DONTRECORD | FCVAR_NOTIFY);
	cvarEnabled = CreateConVar("sm_minicrits_enabled", "1", "Enable Mini-Crits plugin.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	HookEvent("player_spawn", Player_Spawn);
}

public Action:Player_Spawn(Handle:event, String:name[], bool:dontBroadcast)
{
	if(!GetConVarBool(cvarEnabled)) return;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(!IsValidClient(client)) return;
	TF2_AddCondition(client, TFCond_Buffed, 9999.9); 
}

public TF2_OnConditionRemoved(client, TFCond:condition)
{
	if(!GetConVarBool(cvarEnabled)) return;
	if(condition == TFCond_Buffed)
		TF2_AddCondition(client, TFCond_Buffed, 9999.9); 
}

stock bool:IsValidClient(i, bool:replay = true)
{
	if(i <= 0 || i > MaxClients || !IsClientInGame(i) || GetEntProp(i, Prop_Send, "m_bIsCoaching")) return false;
	if(replay && (IsClientSourceTV(i) || IsClientReplay(i))) return false;
	return true;
}