#pragma semicolon 1
#include <sourcemod>    
#include <sdktools>
#include <cstrike>
new Handle:MyTimer = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = "Auto Change Map If Server Emty",
	author = "Tomasz 'anacron' Motylinski",
	description = "Autocycle map to next if server empty",
	version = "1.0",
	url = "htto://anacron.pl"
}

public Action:CheckServer(Handle:Timer)
{
	if (GetTeamClientCount(CS_TEAM_CT) == 0 && GetTeamClientCount(CS_TEAM_T) == 0)
	{
		decl String:NextMap[128];
		GetNextMap(NextMap, sizeof(NextMap));
		if ( IsMapValid(NextMap))
		{
			ServerCommand("changelevel %s",NextMap);
		}
	}
}

public OnMapStart()
{
	MyTimer = CreateTimer(600.0,CheckServer, _,TIMER_REPEAT); 
}

public OnMapEnd()
{
	KillTimer(MyTimer);
	CloseHandle(MyTimer);
	MyTimer = INVALID_HANDLE;
}
