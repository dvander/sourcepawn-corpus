#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.1"

new Handle:g_hEnabled = INVALID_HANDLE;
new Handle:g_hTimer = INVALID_HANDLE;
new Handle:g_hPlugin = INVALID_HANDLE;
new Handle:UnloadTimer = INVALID_HANDLE;

public Plugin:myinfo ={
	name = "Plugin Unloader",
	author = "TheGodKing",
	description = "Unloads a plugin after x seconds",
	version = PLUGIN_VERSION,
	url = "http://www.immersion-networks.com"
}

public OnPluginStart()
{
	CreateConVar("sm_unloader_version", PLUGIN_VERSION, "Unloader Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_hEnabled = CreateConVar("unloader_enabled", "1", "Enable/Disable unloader", FCVAR_PLUGIN);
	g_hTimer = CreateConVar("unloader_time", "295.0", "Time before unloading plugin", FCVAR_PLUGIN);
	g_hPlugin = CreateConVar("unloader_plugin", "rockthevote", "Plugin name to unload/reload", FCVAR_PLUGIN);
	
	HookEvent("round_start", Event_RoundStart);
	HookEvent("round_end", Event_RoundEnd);
	
	AutoExecConfig(true, "plugin.unloader");
}

public Action:Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarInt(g_hEnabled)){
		UnloadTimer = CreateTimer(GetConVarFloat(g_hTimer), Timer_Unload,_,TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (UnloadTimer != INVALID_HANDLE){
		KillTimer(UnloadTimer);
		UnloadTimer = INVALID_HANDLE;
	}
	
	if (GetConVarInt(g_hEnabled)){
		new String:plugin[32];
		GetConVarString(g_hPlugin, plugin, sizeof(plugin));
		ServerCommand("sm plugins load %s", plugin);
	}
}

public Action:Timer_Unload(Handle:timer)
{
	new String:plugin[32];
	GetConVarString(g_hPlugin, plugin, sizeof(plugin));
	ServerCommand("sm plugins unload %s", plugin);
	UnloadTimer = INVALID_HANDLE;
}