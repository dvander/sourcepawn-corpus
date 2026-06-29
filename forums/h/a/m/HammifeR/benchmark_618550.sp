#pragma semicolon 1

#include <sourcemod>

// Global Definitions
#define PLUGIN_VERSION "1.0.1"

// Functions
public Plugin:myinfo =
{
	name = "Benchmark blocker",
	author = "pRED*",
	description = "Blocks usage of the sv_benchmark_force_start",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

public OnPluginStart()
{
	new flags = GetCommandFlags("sv_benchmark_force_start");
	SetCommandFlags("sv_benchmark_force_start", flags|FCVAR_CHEAT);
	
	new flags1 = GetCommandFlags("sv_soundscape_printdebuginfo");
	SetCommandFlags("sv_soundscape_printdebuginfo", flags1|FCVAR_CHEAT);
	
	CreateConVar("sm_benchmarkblock_version", PLUGIN_VERSION, "Benchmark blocker version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}