#include <sourcemod>
#define PLUGIN_VERSION "0.0.1"

public Plugin:myinfo =
{
	name = "Game-End 3cvars Reset",
	author = "St00ne + Bacardi + DarthNinja",
	description = "Resets sv_gravity, phys_pushscale and phys_timescale at the end of the map",
	version = PLUGIN_VERSION,
	url = "http://www.esc90.fr"
};

public OnPluginStart()
{
	HookEventEx("teamplay_win_panel", teamplay_win_panel, EventHookMode_PostNoCopy);
	CreateConVar("sm_3cvarsreset_version", PLUGIN_VERSION, "Version of 3cvarsReset plugin", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public teamplay_win_panel(Handle:event, const String:name[], bool:dontBroadcast)
{
	ServerCommand("sv_gravity 800");
	ServerCommand("phys_pushscale 1");
	ServerCommand("phys_timescale 1");
}
