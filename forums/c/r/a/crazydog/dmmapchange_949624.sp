#include <sourcemod>
#define PLUGIN_VERSION "1.0"

public Plugin:myinfo = 
{
	name = "Deathmatch - Map Change when mp_timelimit = 0",
	author = "Crazydog",
	description = "Changes the map on a CS:S DM server when mp_timelimit = 0",
	version = "1.0",
	url = ""
}


new Handle:timelimitchecker = INVALID_HANDLE

public OnPluginStart()
{
	CreateConVar("sm_dmmapchange_version", PLUGIN_VERSION, "Deathmatch Mapchange Version", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_DONTRECORD)
}
public OnMapStart(){
	timelimitchecker = CreateTimer(30.0, checkTimelimit, _, TIMER_REPEAT)
}

public OnMapEnd(){
	KillTimer(timelimitchecker)
}

public Action:checkTimelimit(Handle:timer){
	new timeleft
	GetMapTimeLeft(timeleft)
	if(timeleft < 1){
		new String:nextmap[256]
		GetNextMap(nextmap, sizeof(nextmap))
		ForceChangeLevel(nextmap, "Forced by DM timelimit map changeR")
	}
	return Plugin_Continue
}
