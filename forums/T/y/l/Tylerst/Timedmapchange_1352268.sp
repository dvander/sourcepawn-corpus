#include <sourcemod>

public Plugin:myinfo = 
{
	name = "Timed Map Change",
	author = "Tylerst",
	description = "Change Map Every 90 Minutes",
	version = "1.0",
	url = ""
}

public OnMapStart()
{	
	CreateTimer(5400.0, MapChange);
}

public Action:MapChange(Handle:timer) 
{
	new String:nextmap[64];
	GetConVarString(FindConVar("sm_nextmap"), nextmap, 64);
	ServerCommand("sm_map %s", nextmap);
}