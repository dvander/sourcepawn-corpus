#pragma newdecls required
#include <sourcemod>

#define CVAR_FLAGS FCVAR_NONE|FCVAR_SPONLY|FCVAR_NOTIFY
#define PLUGIN_VERSION "1.0"

public Plugin myinfo = 
{
	name = "Map Config Loader",
	author = "Jonny",
	description = "Executes a config file based on the current map",
	version = PLUGIN_VERSION,
	url = ""
}

public void OnPluginStart()
{
	CreateConVar("map_config_ver", PLUGIN_VERSION, "Version of the map config loader plugin.", CVAR_FLAGS);
	HookEvent("round_start", Event_RoundStart);
}

public Action Event_RoundStart(Event hEvent, const char[] strName, bool DontBroadcast)
{
	char current_map[36];
	GetCurrentMap(current_map, 35);
	ServerCommand("exec maps\\%s.cfg", current_map);
	return Plugin_Continue
}