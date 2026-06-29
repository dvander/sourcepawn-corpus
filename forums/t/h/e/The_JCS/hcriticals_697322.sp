// Includes
#include <sourcemod>

// Plugin version
#define PLUGIN_VERSION  "0.1"

public Plugin:myinfo = 
{
	name = "Humiliation Criticals",
	author = "TheJCS",
	description = "Turns criticals on at TF2 Humiliation",
	version = "0.2",
	url = ""
}

// ConVars
new Handle:cvarEnabled;
new Handle:cvarCriticals;

public OnPluginStart()
{
	// ConVars
	CreateConVar("sm_hcriticals", PLUGIN_VERSION, "Humiliation Criticals Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cvarCriticals = FindConVar("tf_weapon_criticals");
	cvarEnabled = CreateConVar("sm_hcriticals_enabled", "1", "Enable/Disable the Humiliation Criticals plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	// Events
	HookEvent("teamplay_round_start", event_RoundStart);
    
	HookEvent("teamplay_round_win", event_RoundEnd);
	HookEvent("teamplay_round_stalemate", event_RoundEnd);
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(cvarEnabled))
		return;
	
	SetConVarBool(cvarCriticals, false);
}

public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarInt(cvarEnabled))
		return;
	
	SetConVarBool(cvarCriticals, true);
}