#include <sourcemod>
#include <cstrike>
#include <colors>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.2"


public Plugin:myinfo = 
{
	name = "Show Leader CS:GO",
	author = "Sheepdude and Franc1sco franug :-)",
	description = "Announces the current score leader",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

public OnPluginStart()
{
	CreateConVar("sm_showleader_csgo_version", PLUGIN_VERSION, "Plugin version", FCVAR_CHEAT|FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	HookEvent("round_start", OnRoundStart);
}

public OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(3.0, LeaderAnnounceTimer);
}

public Action:LeaderAnnounceTimer(Handle:timer, any:data)
{
	new Leader = FindLeader();
	if(Leader == 0)
		return Plugin_Handled;
	new Frags = GetClientFrags(Leader);
	new Assists = 0;
	Assists = CS_GetClientAssists(Leader);
	new Deaths = GetClientDeaths(Leader);
	new Score = CS_GetClientContributionScore(Leader);
	CPrintToChatAllEx(Leader, "\x01\x0B{teamcolor}%N\x04 [%i]\x01 is the current \x04Leader\x01 with \x05%i\x01 kills, \x05%i\x01 assists, and \x05%i\x01 deaths.", Leader, Score, Frags, Assists, Deaths);
	return Plugin_Handled;
}

FindLeader()
{
	new Leader = 0;
	new Score = -1;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && CS_GetClientContributionScore(i) > Score)
		{
			Score = CS_GetClientContributionScore(i);
			Leader = i;
		}
	}
	return Leader;
}