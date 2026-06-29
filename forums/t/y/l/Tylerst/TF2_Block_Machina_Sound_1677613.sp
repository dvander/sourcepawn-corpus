#pragma semicolon 1
#include <sourcemod> 

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "TF2 Block Machina Sound",
	author = "Tylerst",
	description = "Stops the Machina sound from playing on a penetration kill",
	version = PLUGIN_VERSION,
	url = "none"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	new String:Game[32];
	GetGameFolderName(Game, sizeof(Game));
	if(!StrEqual(Game, "tf"))
	{
		Format(error, err_max, "This plugin only works for Team Fortress 2");
		return APLRes_Failure;
	}
	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("sm_blockmachinasound_version", PLUGIN_VERSION, "Stops the Machina sound from playing on a penetration kill", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("player_death", Event_PlayerDeath, EventHookMode_Pre);
}

public Action:Event_PlayerDeath(Handle:event, const String:name[], bool:dontBroadcast) 
{ 
	SetEventInt(event, "playerpenetratecount", 0); 
	return Plugin_Continue; 
}  