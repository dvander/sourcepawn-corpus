#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <tf2>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "Arena Waitingforplayers Cancel",
	author = "ThatGuy",
	description = "So no admin is needed to play in arena maps.",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	CreateConVar("arenawait_version",PLUGIN_VERSION,"Version Information",FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("teamplay_round_start",round_start);
}

public round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:map[64];
	GetCurrentMap(map,64);
	if (StrContains(map,"arena_",false) != -1)
	{	
		ServerCommand("mp_waitingforplayers_cancel 1");
                ServerCommand("sm plugins unload arenawait");

		}
	}	