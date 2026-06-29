#include <sourcemod>

#define CVAR_FLAGS FCVAR_PLUGIN
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Map Config Loader",
	author = "Jonny",
	description = "Executes a config file based on the current map",
	version = PLUGIN_VERSION,
	url = ""
}

public OnPluginStart()
{
	CreateConVar("map_config_ver", PLUGIN_VERSION, "Version of the map config loader plugin.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	HookEvent("round_start", Event_RoundStart);
}

public Action:Event_RoundStart(Handle:hEvent, const String:strName[], bool:DontBroadcast)
{
	new String:current_map[36];
	GetCurrentMap(current_map, 35);
	ServerCommand("exec maps\\%s.cfg", current_map);
	return Plugin_Continue
}