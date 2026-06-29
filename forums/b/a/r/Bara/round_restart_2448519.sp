#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

ConVar g_cEnable = null;
ConVar g_cRestart = null;

public Plugin myinfo = 
{
	name = "Round Restart",
	author = "Bara",
	description = "",
	version = "1.0.0",
	url = "ngx-gaming.com"
};

public void OnPluginStart()
{
	g_cEnable = CreateConVar("round_restart_enable", "1", "Enable this plugin?", _, true, 0.0, true, 1.0);
	g_cRestart = CreateConVar("round_restart_method", "1", "How to restart? 0 - CS_TerminateRound, 1 - mp_restartgame", _, true, 0.0, true, 1.0);
	
	HookEvent("teamchange_pending", Event_TeamChangePending, EventHookMode_Pre);
}

public Action Event_TeamChangePending(Event event, const char[] name, bool dontBroadcast)
{
	if(g_cEnable.BoolValue)
	{
		return Plugin_Continue;
	}
	
	int iCTCount = GetTeamClientCount(CS_TEAM_CT);
	int iTCount = GetTeamClientCount(CS_TEAM_T);
	int newTeam = event.GetInt("toteam");
	
	if(newTeam == CS_TEAM_T && iTCount == 0 && iCTCount > 1 || newTeam == CS_TEAM_CT && iCTCount == 0 && iTCount > 1)
	{
		if(!g_cRestart.BoolValue)
		{
			CS_TerminateRound(1.0, CSRoundEnd_Draw, false);
		}
		else
		{
			ServerCommand("mp_restartgame 1");
		}
	}
	
	return Plugin_Continue;
}
