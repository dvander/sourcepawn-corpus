#include <sourcemod>
#include <cstrike>
#include <zephstocks>

#pragma semicolon 1

#define PLUGIN_VERSION "1.0.1"

public Plugin:myinfo = 
{
	name = "Show Leader CS:GO",
	author = "Sheepdude",
	description = "Announces the current score leader",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

public OnPluginStart()
{
	IdentifyGame();

	// Supress warnings about unused variables.....
	if(g_bL4D || g_bL4D2 || g_bND) {}

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
	new Assists = CS_GetClientAssists(Leader);
	new Deaths = GetClientDeaths(Leader);
	new Score = CS_GetClientContributionScore(Leader);

	new String:m_szMessage[256];
	Format(STRING(m_szMessage), "{teamcolor}%N{green} [%d]{default} is the current {green}Leader{default} with {olive}%d{default} kills, {olive}%d{default} assists, and {olive}%i{default} deaths.", Leader, Score, Frags, Assists, Deaths);
	ReplaceColors(STRING(m_szMessage), Leader);
	PrintToChatAll(m_szMessage);
	
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