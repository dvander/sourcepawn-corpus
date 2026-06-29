#pragma semicolon 1

#include <sourcemod>

new String:currentmap[256], String:previous_map[256];

public Plugin:myinfo = 
{
	name = "Map Refresh",
	author = "[W]atch [D]ogs",
	description = "refresh map on every map changes once",
	version = "0.1"
};

public OnPluginStart()
{
	AddCommandListener(OnCmd_MapChange, "sm_map");
	AddCommandListener(OnCmd_MapChange, "changelevel");
}

public Action:OnCmd_MapChange(client, const String:command[], argc)
{
	GetCurrentMap(previous_map, sizeof(previous_map));
}


public OnConfigsExecuted()
{
	GetCurrentMap(currentmap, sizeof(currentmap));
	
	if(!StrEqual(currentmap, previous_map, false) && !StrEqual(previous_map, ""))
	{
		ForceChangeLevel(currentmap, "Refresh map once");
	}
}
