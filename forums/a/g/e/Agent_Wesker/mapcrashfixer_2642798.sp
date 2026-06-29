#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required

public Plugin myinfo =
{
	name		= "CSGO Map Change Crash Fixer",
    author      = "BOT Benson + Wesker",
    description = "Prevents client crashes on map change",
    version     = "1.0.7",
    url         = "https://www.botbenson.com"
};

ConVar mapChangeDelay;
public void OnPluginStart()
{

	mapChangeDelay = FindConVar("mp_match_restart_delay");

	HookEventEx("cs_win_panel_match", Event_MapEnd);

	RegAdminCmd( "sm_mapend" , Command_MapEnd , ADMFLAG_CHANGEMAP );
	RegAdminCmd( "sm_changenextmap" , Command_ChangeNextMap , ADMFLAG_CHANGEMAP );

}

public Action OnLogAction(Handle source, Identity ident,int client,int target, const char[] message)
{
	if (StrContains(message, "changed map to") != -1)
	{
		if (IsValidClient(client))
		{
			CreateTimer(2.9, Timer_RetryPlayers, 0 , TIMER_FLAG_NO_MAPCHANGE);
		} else 
		{
			CreateTimer(2.9, Timer_RetryPlayers, 1 , TIMER_FLAG_NO_MAPCHANGE);
		}
	} 
	else if (StrContains(message, "MCE change map") != -1)
	{
		CreateTimer(0.4, Timer_RetryPlayers, 0 , TIMER_FLAG_NO_MAPCHANGE);
	}
	else if (StrContains(message, "RTV changing map") != -1)
	{
		CreateTimer(0.1, Timer_RetryPlayers, 0 , TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnMapStart()
{

   	SetIntCvar("mp_match_end_changelevel" , 0);
   	SetIntCvar("mp_endmatch_votenextmap" , 0);
   	SetIntCvar("mp_endmatch_votenextleveltime" , 0);
   	SetIntCvar("mp_match_end_restart" , 0);

}

public Action Command_ChangeNextMap( int client , int args )
{

	char mapName[PLATFORM_MAX_PATH];
	GetCmdArg(1, mapName, sizeof(mapName));

	switch (FindMap(mapName, mapName, sizeof(mapName)))
	{
		case FindMap_Found:
			SetNextMap( mapName );
		case FindMap_FuzzyMatch:
			SetNextMap( mapName );
	}
	
	return Plugin_Handled;
}

public Action Command_MapEnd( int client , int args )
{

   	SetIntCvar("mp_timelimit" , 0);
   	SetIntCvar("mp_maxrounds" , 0);
   	SetIntCvar("mp_respawn_on_death_t" , 0);
   	SetIntCvar("mp_respawn_on_death_ct" , 0);

	return Plugin_Handled;
}

public void Event_MapEnd(Event event, const char[] name, bool dontBroadcast)
{
	CreateTimer( float( mapChangeDelay.IntValue ) - 0.15 , Timer_RetryPlayers , 1 , TIMER_FLAG_NO_MAPCHANGE );
}

public Action Timer_RetryPlayers( Handle timer , int _any )
{
	RetryClients(_any);
	return Plugin_Stop;
}

stock bool RetryClients(int forceChange)
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( !IsClientInGame( i ) || IsFakeClient( i ) || !IsClientConnected( i ) )
			continue;

		LogMessage("Sent a retry command to %N", i);
		ClientCommand( i , "retry" );
	}
	
	if (!forceChange)
		return;
	
	char map[PLATFORM_MAX_PATH];
	if (GetNextMap(map, sizeof(map)))
	{
		LogMessage("Forcing a map change to %s", map);
		ForceChangeLevel(map, "Map Crash Fix >ForceChangeLevel<");
	}
}

stock bool SetIntCvar(char[] scvar, int value)
{
	ConVar cvar = FindConVar(scvar);
	if (cvar == null) 
		return false;
		
	cvar.SetInt(value);
	return true;
}

stock bool IsValidClient(int client)
{
	return (1 <= client <= MaxClients && IsClientInGame(client));
}