#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "Achievement Setup",
	author = "Jindo",
	description = "Adjusts settings for an achievement map.",
	version = PLUGIN_VERSION,
	url = "http://www.topaz-games.com"
};

public OnPluginStart()
{
	CreateConVar("achievementsetup_version",PLUGIN_VERSION,"Version Information",FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("teamplay_round_start",round_start);
}

public round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:map[64];
	GetCurrentMap(map,64);
	if (StrContains(map,"achievement_",false) != -1)
	{	
		ServerCommand("sm_cvar sv_alltalk 1");
		ServerCommand("sm_cvar mp_respawnwavetime 0");
		ServerCommand("sm_cvar mp_timelimit 0");
		ServerCommand("mp_maxrounds 0");
		ServerCommand("sm_cvar mp_winlimit 0");
		ServerCommand("sm_cvar tf_flag_caps_per_round 0");
	}
}