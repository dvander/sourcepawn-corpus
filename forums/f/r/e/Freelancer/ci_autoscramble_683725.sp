#include <sourcemod>
#include <sdktools>
#include <tf2_stocks>

#define PLUGIN_VERSION "0.4"

new Roundstarts = 0;


public Plugin:myinfo =
{
	name = "ci auto scramble",
	author = "MrG",
	description = "ci auto scramble",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("sm_ci_autoscramble_version", PLUGIN_VERSION, "sm ci autoscramble Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	HookEvent("teamplay_round_start", Event_Roundstart, EventHookMode_PostNoCopy);
	
}

public OnMapStart()
{
	Roundstarts = 0;
}

public Action:Event_Roundstart(Handle:event,const String:name[],bool:dontBroadcast)
{
	
	if ( Roundstarts == 0 ) 
	{
		CreateTimer(25.0, Timer_scramble);
	}
	Roundstarts++;
}


public Action:Timer_scramble(Handle:timer, any:client)
{
	PrintToChatAll("\x01[SM] \x04Welcome, Server Automatically Scrambling Teams.");
	ServerCommand("mp_scrambleteams 1");
}