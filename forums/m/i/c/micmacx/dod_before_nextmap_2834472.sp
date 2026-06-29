#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0"

#pragma semicolon 1
#define MAX_FILE_LEN 255

public Plugin:myinfo = 
{
	name = "before_nextmap", 
	author = "micmacx", 
	description = "Change map 20s before nextmap", 
	version = PLUGIN_VERSION, 
	url = ""
};

new Handle:cvarTime;


public OnPluginStart()
{
	CreateConVar("dod_before_nextmap", PLUGIN_VERSION, "before_nextmap", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvarTime = CreateConVar("dod_before_nextmap_adjust", "0", "Nombre de secondes ");
	
	AutoExecConfig(true, "dod_before_nextmap");
}


public OnMapStart()
{
	CreateTimer(10.0, FirstTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}


public Action:FirstTimer(Handle:timer)
{
	int tempo_cvarTime = GetConVarInt(cvarTime);
	int timeleft;
	GetMapTimeLeft(timeleft);
	int timetempo = (timeleft - (tempo_cvarTime + 20));
	if (timetempo > 140)
	{
		CreateTimer(120.0, SecondTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		float timefinal = float(timetempo);
		CreateTimer(timefinal, FinalTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:SecondTimer(Handle:timer)
{
	int tempo_cvarTime = GetConVarInt(cvarTime);
	int timeleft;
	GetMapTimeLeft(timeleft);
	int timetempo = (timeleft - (tempo_cvarTime + 20));
	if (timetempo > 140)
	{
		CreateTimer(120.0, FirstTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		float timefinal = float(timetempo);
		CreateTimer(timefinal, FinalTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}


public Action:FinalTimer(Handle:timer)
{
	char mapbnextmap[PLATFORM_MAX_PATH];
	if (GetNextMap(mapbnextmap, sizeof(mapbnextmap)))
	{
		ForceChangeLevel(mapbnextmap, "Before NextMap for Mapchooser for DoD:S");
	}
}

