#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

public Plugin myinfo = 
{
	name = "[L4D2] Bots Weapon Preference Manipulation(sub)",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	CreateTimer(10.0, PluginRefresh, _, TIMER_REPEAT);
}

public Action:PluginRefresh(Handle:Timer)
{
	new String:buffer[256];
	ServerCommandEx(buffer, sizeof(buffer), "%s;%s", "sm plugins unload \"[L4D2] Bots Weapon Preference Manipulation\"", "sm plugins load \"[L4D2] Bots Weapon Preference Manipulation\"");
	return Plugin_Continue;
}
