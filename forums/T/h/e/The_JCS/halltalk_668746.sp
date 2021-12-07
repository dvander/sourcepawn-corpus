// Includes
#include <sourcemod>

// Plugin version
#define PLUGIN_VERSION  "0.1"

public Plugin:myinfo = 
{
	name = "Humiliation All Talk",
	author = "TheJCS",
	description = "Turns All Talk on at TF2 Humiliation",
	version = "0.1",
	url = "http://kongbr.com.br"
}

// ConVars
new Handle:cvarEnabled;
new Handle:cvarAllTalk;

public OnPluginStart()
{
	// ConVars
	CreateConVar("sm_halltalk", PLUGIN_VERSION, "Humiliation All Talk Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	cvarAllTalk = FindConVar("sv_alltalk");
	cvarEnabled = CreateConVar("sm_halltalk_enabled", "1", "Enable/Disable the Humiliation All Talk plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	// Events
    HookEvent("teamplay_round_start", 		event_RoundStart);
    
	HookEvent("teamplay_round_win", 		event_RoundEnd);
    HookEvent("teamplay_round_stalemate", 	event_RoundEnd);
}

public Action:event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!GetConVarInt(cvarEnabled))
		return;

	SetConVarBool(cvarAllTalk, false);
}

public Action:event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
    if (!GetConVarInt(cvarEnabled))
		return;

	SetConVarBool(cvarAllTalk, true);
}