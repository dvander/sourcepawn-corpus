#pragma semicolon 1

#include <sourcemod>    
#include <sdktools>
#include <cstrike>

public Plugin myinfo = 
{
	name = "Auto Change Map If Server Emty",
	author = "Tomasz 'anacron' Motylinski",
	description = "Autocycle map to next if server empty",
	version = "1.0",
	url = "htto://anacron.pl"
}

public void OnMapStart()
{
	CreateTimer(600.0, CheckServer, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE); 
}

public Action CheckServer(Handle timer)
{
	if (GetTeamClientCount(CS_TEAM_CT) == 0 && GetTeamClientCount(CS_TEAM_T) == 0)
	{
		char NextMap[128];
		GetNextMap(NextMap, sizeof(NextMap));
		
		if (IsMapValid(NextMap))
		{
			ServerCommand("changelevel %s",NextMap);
		}
	}
}