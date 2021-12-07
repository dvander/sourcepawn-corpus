// ---- Preprocessor -----------------------------------------------------------
#pragma semicolon 1 

// ---- Includes ---------------------------------------------------------------
#include <sourcemod>

// ---- Defines ----------------------------------------------------------------
#define VERSION "0.1.0"

// ---- Variables --------------------------------------------------------------
new bool:isSuddenDeath=false;

public Plugin:myinfo =
{
	name = "Outlines Last Player",
	author = "Classic",
	description = "Outlines the last player on sudden death.",
	version = VERSION,
	url = "http://www.clangs.com.ar"
}


public OnPluginStart()
{
	HookEvent("teamplay_round_stalemate", EventSuddenDeathStart);
	HookEvent("teamplay_round_start", EventRoundStart);
	HookEvent("player_death", OnPlayerDeath);
}

public Action:EventSuddenDeathStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	isSuddenDeath=true;
	return Plugin_Continue;
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{	
	isSuddenDeath=false;
	return Plugin_Continue;
}

public Action:OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(isSuddenDeath)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		new client_team = GetClientTeam(client);
		
		if(GetAlivePlayersCount(client_team,client) == 1)
			for(new i=1 ; i<=MaxClients ; i++)
				if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(client) == client_team)
					SetEntProp(i, Prop_Send, "m_bGlowEnabled", 1);
	}
	
}

stock GetAlivePlayersCount(team,ignore=-1) 
{ 
	new count = 0;

	for(new i = 1; i <= MaxClients; i++ ) 
		if(IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == team && i != ignore) 
			count++; 

	return count; 
}  