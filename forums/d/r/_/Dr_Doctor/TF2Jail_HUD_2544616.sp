#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Battlefield Duck"
#define PLUGIN_VERSION "1.2"

#include <sourcemod>
#include <sdktools>
#include <tf2jail>

#undef REQUIRE_PLUGIN
#include <TF2Jail>

#pragma newdecls required

//define
#define TEAM_RED 2
#define TEAM_BLU 3


public Plugin myinfo = 
{
	name = "[TF2] Jailbreak - HUD",
	author = PLUGIN_AUTHOR,
	description = "A Hintbox show Player status, Game status.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=300720"
};
//Handle cvar
Handle hConVars;

public void OnPluginStart()
{
	CreateConVar("sm_tf2jail_HUD_version", PLUGIN_VERSION, "Version of [TF2] Jail - HUD", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_NOTIFY);
	hConVars = CreateConVar("sm_tf2jail_HUDenable", "1", "Enable [TF2] Jail - HUD", _, true, 0.0, true, 1.0);
}

public void OnMapStart()
{
	CreateTimer(1.0, Timer_ShowHintBox, _, TIMER_REPEAT);
}

public Action Timer_ShowHintBox(Handle hTimer)
{
	if(GetConVarBool(hConVars) && !IsVoteInProgress())
	{
	 	for (int iClient = 1; iClient <= MaxClients; iClient++)
		{
			if(IsValidClient(iClient))
    		{
    			int iWarden = -1;
    			int iFreeday = 0;
    			int iRebel = 0;
    			int AliveRed = GetAlivePlayersCount(TEAM_RED);
    			int AliveBlu = GetAlivePlayersCount(TEAM_BLU);
    			int Red = GetTeamClientCount(TEAM_RED);
    			int Blu = GetTeamClientCount(TEAM_BLU);
    			for(int i = 1; i <= MaxClients; i++)
    			{
    				if(IsValidClient(i))
    				{
    					if(TF2Jail_IsWarden(i))		iWarden = i;
    					if(TF2Jail_IsFreeday(i))	iFreeday++;
    					if(TF2Jail_IsRebel(i))		iRebel++;
    				}
    			}
			if(iWarden != -1)	PrintHintText(iClient, "Warden: %N \n Guard: %i/%i  Prisoner: %i/%i \n Freeday: %i  Rebel: %i", iWarden, AliveBlu, Blu, AliveRed, Red, iFreeday, iRebel);
			else	PrintHintText(iClient, "Warden:  -  \n Guard: %i/%i  Prisoner: %i/%i \n Freeday: %i  Rebel: %i",AliveBlu, Blu, AliveRed, Red, iFreeday, iRebel);
			StopSound(iClient, SNDCHAN_STATIC, "UI/hint.wav");
    		}
		}
	}
}




/*******************
Vaild Client?
*******************/
stock bool IsValidClient(int client) 
{ 
    if(client <= 0 ) return false; 
    if(client > MaxClients) return false; 
    if(!IsClientConnected(client)) return false; 
    return IsClientInGame(client); 
}

/**********************
GetAlivePlayersCount
***********************/
stock int GetAlivePlayersCount(int iTeam)
{
  int i; 
  int iCount = 0;

  for( i = 1; i <= MaxClients; i++ )
    if( IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == iTeam)
      iCount++;

  return iCount;
}  
