#include <sourcemod>
#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo =
{
	name = "ckSurf fix",
	author = "ch4os, edit by blackhawk74/sneaK",
	description = "Reloads current map within 20 seconds after server restart",
	version = PLUGIN_VERSION,
	url = "www.killerspielplatz.com"
}

public OnPluginStart()
{
	CreateTimer(20.0, Event_ReloadMap);
}

public Action:Event_ReloadMap(Handle:Timer)
{
	decl String:MapName[255];
	GetCurrentMap(MapName, 255);
	ServerCommand("changelevel %s", MapName);
}