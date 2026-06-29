#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma tabsize 0
#pragma newdecls required

bool g_bFullConnected[MAXPLAYERS+1] = {false, ...};

bool g_bLateLoad = false;

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max) {
	g_bLateLoad = late;
	return APLRes_Success;
}

public Plugin myinfo =
{
	name		= "CSGO Panorama Map Change Crashe Fixer",
    author      = "BOT Benson",
    description = "CSGO Panorama Map Change Crashe Fixer",
    version     = "1.0.2",
    url         = "https://www.botbenson.com"
};
ConVar mapChangeDelay;
public void OnPluginStart()
{

	mapChangeDelay = FindConVar("mp_match_restart_delay");

	HookEventEx("cs_win_panel_match", Event_MapEnd);
	HookEvent("player_connect_full", Event_OnFullConnect);

	RegAdminCmd( "sm_mapend" , Command_MapEnd , ADMFLAG_CHANGEMAP );
	RegAdminCmd( "sm_changenextmap" , Command_ChangeNextMap , ADMFLAG_CHANGEMAP );

	if (g_bLateLoad) {
		int i = 1;
		while (i <= MaxClients) {
			if (IsClientInGame(i) && !IsFakeClient(i)) {
				g_bFullConnected[i] = true;
			}
			i++;
		}
	}

}

public void OnMapStart()
{

   	SetIntCvar("mp_match_end_changelevel" , 0);
   	SetIntCvar("mp_endmatch_votenextmap" , 0);
   	SetIntCvar("mp_endmatch_votenextleveltime" , 0);
   	SetIntCvar("mp_match_end_restart" , 0);

}

public void OnClientConnected(int client) {
	g_bFullConnected[client] = false;
}

public void OnClientDisconnect(int client) {
	g_bFullConnected[client] = false;
}

public void Event_OnFullConnect(Handle event, const char[] name, bool dontBroadcast) {
	int client = GetClientOfUserId(GetEventInt(event, "userid"));

	g_bFullConnected[client] = true;
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

	CreateTimer( float( mapChangeDelay.IntValue ) - 0.15 , Timer_RetryPlayers , _ , TIMER_FLAG_NO_MAPCHANGE );

}

public Action Timer_RetryPlayers( Handle timer , int _any )
{


	for( int i = 1; i <= MaxClients; i++ )
	{

		if( !IsClientInGame( i ) || IsFakeClient( i ) || !IsClientConnected( i ) || !g_bFullConnected[i])
			continue;

		ReplyToCommand( i, "BOT Benson Automatic Map Change Success!");
		ReconnectClient(i);

	}

	return Plugin_Stop;
}

bool SetIntCvar(char[] scvar, int value)
{

	ConVar cvar = FindConVar(scvar);
	if (cvar == null)
		return false;

	cvar.SetInt(value);
	return true;
}