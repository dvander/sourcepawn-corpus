/**
 * ==========================================================================
 * SourceMod Terrible Enable Demolition Map Vote for CS:GO
 *
 * by Sheepdude
 *
 * This plugin starts a map vote after a certain amount of rounds have
 * passed. This is useful for ensuring the map vote occurs when playing
 * Demolition mode.
 *
 * CHANGELOG
 *
 * Version 0.1 (14 October 2012)
 * -Initial Version
 * 
 * Version 0.2 (17 October 2012)
 * Current Version
 * -Plugin now uses cstrike functions to check team score
 * -Plugin does not force a vote for mp_maxrounds 0
 * 
 */

#include <sourcemod>
#include <mapchooser>
#include <cstrike>

#pragma semicolon 1

#define PLUGIN_VERSION "0.02"

public Plugin:myinfo =
{
	name = "Terrible Enable Demolition Map Vote",
	author = "Sheepdude",
	description = "Starts map voting on Demolition maps after a certain number of rounds",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

new Handle:h_MaxRounds = INVALID_HANDLE;
new Handle:h_PluginEnabled = INVALID_HANDLE;
new g_maxrounds;

public OnPluginStart()
{
	CreateConVar("sm_tedmv_version", PLUGIN_VERSION, "TEDMV Version", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_SPONLY);
	h_PluginEnabled = CreateConVar("sm_tedmv_enable", "1", "Enable or disable plugin, 1 - enable, 0 - disable", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_MaxRounds = FindConVar("mp_maxrounds");
	HookEvent("round_end", Event_RoundEnd);
}

public OnMapStart()
{
	if(h_MaxRounds != INVALID_HANDLE)
		g_maxrounds = RoundToFloor(float(GetConVarInt(h_MaxRounds))/2) - 2;
	else
		g_maxrounds = 7;
}

public Action:Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_maxrounds < 1 || GetConVarInt(h_PluginEnabled) == 0 || HasEndOfMapVoteFinished())
		return Plugin_Stop;
	if(CS_GetTeamScore(CS_TEAM_T) >= g_maxrounds || CS_GetTeamScore(CS_TEAM_CT) >= g_maxrounds)
	{
		if(CanMapChooserStartVote() && !IsVoteInProgress())
		{
			new MapChange:when = MapChange:2;
			InitiateMapChooserVote(when);
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}