#include <sourcemod> 
#include <sdktools> 
#include <morecolors> 

#pragma semicolon 1
#pragma newdecls required

int roundx[1];

public Plugin myinfo = 
{
	name = "[TF2] Round Starting",
	author = "avan",
	description = "Do something at round start",
	version = "PLUGIN_VERSION 1.0",
}

public void OnPluginStart()
{ 
	RegConsoleCmd("sm_roundscore", Command_Round);
	HookEvent("teamplay_round_start", OnRoundStart);
}

public void OnMapStart()
{ 
	roundx[0] = 0;
}
public Action OnRoundStart(Handle hEvent, const char[] strName, bool bDontBroadcast)
{
	roundx[0] = roundx[0] +1;
	if(roundx[0] < 1)
	{
		roundx[0] = 1;
	}
	int RedScore = GetTeamScore(2);
	int BluScore = GetTeamScore(3);
	PrintToChatAll("Round %i has begun!",roundx[0]-1);	
	if(RedScore > BluScore)
	{
		CPrintToChatAll("{GREEN}Current Score: {RED}RED %i, {DARKBLUE}BLU %i, {RED}RED is Winning!", RedScore, BluScore);			
	}
	else if(BluScore > RedScore)
	{
		CPrintToChatAll("{GREEN}Current Score: {RED}RED %i, {DARKBLUE}BLU %i, {DARKBLUE}BLU is Winning!", RedScore, BluScore);			
	}
	else
	{
		CPrintToChatAll("{GREEN}Current Score: {RED}RED %i, {DARKBLUE}BLU %i", RedScore, BluScore);
	}
}

public Action Command_Round(int client, int args)
{
	if(roundx[0] < 1)
	{
		roundx[0] = 1;
	}
	PrintToChat(client, "It is currently round #%i",roundx[0]-1);
	int RedScore = GetTeamScore(2);
	int BluScore = GetTeamScore(3);
	CPrintToChatAll("{GREEN}Current Round: {YELLOW} %i",roundx[0]-1);	
	CPrintToChatAll("{GREEN}Current Score: {RED}RED %i, {DARKBLUE}BLU %i", RedScore, BluScore);		
}

public void OnMapEnd()
{ 
	roundx[0] = 0;
}