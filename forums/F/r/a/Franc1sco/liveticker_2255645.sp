#include <sourcemod>
#include <cstrike>
#include <sdktools>

new bool:mstart;
new String:map[256];

public Plugin:myinfo =
{
	name = "SM LiveTicker",
	author = "Franc1sco franug",
	description = "",
	version = "1.0",
	url = "http://steamcommunity.com/id/franug"
};

public OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("cs_win_panel_match", Event_End);
}

public OnMapStart()
{
	mstart = false;
	GetCurrentMap(map, 256);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(!mstart) PrintToChatAll(" \x04[LiveTicker]\x05 Team1 vs. Team2 @ %s has just started!", map);
	
	mstart = true;
}

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	PrintToChatAll(" \x04[LiveTicker]\x05 Team1 %i:%i Team2", GetTeamScore(2), GetTeamScore(3));
}

public Event_End(Handle:event, const String:name[], bool:dontBroadcast)
{
	new score1, score2;
	score1 = GetTeamScore(2);
	score2 = GetTeamScore(3);
	
	
	if(score1 > score2) PrintToChatAll(" \x04[LiveTicker]\x05 Team1 won against Team2 @ %s with %i:%i", map, score1, score2);
	else PrintToChatAll(" \x04[LiveTicker]\x05 Team2 won against Team1 @ %s with %i:%i", map, score2, score1);
}