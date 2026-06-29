#pragma semicolon 1
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = {
	name = "Sudden Death Visualizer Disabler",
	author = "Mitchell",
	description = "Disables the blocks on team spawns on sudden death",
	version = PLUGIN_VERSION,
	url = "SnBx.info"
}


public OnPluginStart()
{
	CreateConVar("sm_sdvd_version", PLUGIN_VERSION, "Sudden Death Visualizer Disabler Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	HookEvent("teamplay_round_stalemate", Event_SuddenDeath);
}

public Event_SuddenDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new ent = -1;
	while( ( ent = FindEntityByClassname(ent, "func_respawnroomvisualizer") ) !=-1 )
		AcceptEntityInput(ent, "Disable");
}
