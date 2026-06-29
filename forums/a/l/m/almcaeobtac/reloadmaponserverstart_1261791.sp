#include <sourcemod>
#include <sdktools>

public OnPluginStart()
{
	decl String:MapName[255];
	GetCurrentMap(MapName, 255);
	ServerCommand("changelevel %s", MapName);
}