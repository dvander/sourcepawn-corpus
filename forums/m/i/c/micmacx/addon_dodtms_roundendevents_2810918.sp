//////////////////////////////////////////////
//
// SourceMod Script
//
// [DoD TMS] Addon - RoundEnd Events
//
// Developed by FeuerSturm
//
//////////////////////////////////////////////
#include <sourcemod>
#include <sdktools>
#include <dodtms_base>

public Plugin:myinfo = 
{
	name = "[DoD TMS] Addon - RoundEnd Events",
	author = "FeuerSturm, modif Micmacx",
	description = "Addon RoundEnd Events for [DoD TMS]",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net"
}

new Handle:RoundEndEvent = INVALID_HANDLE
new Handle:RoundEndMix = INVALID_HANDLE
new Handle:RoundEndSwap = INVALID_HANDLE
new Handle:RoundEndStats = INVALID_HANDLE
new g_PlayedRounds = 0, g_WonRoundsAllies = 0, g_WonRoundsAxis = 0
new g_Casualties[4]
new Float:g_StartTime = 0.0
new String:TeamName[4][] = { "", "", "U.S. Army", "Wehrmacht" }
new String:OpTeamName[4][] = { "", "", "Wehrmacht", "U.S. Army" }

public OnPluginStart()
{
	RoundEndEvent = CreateConVar("dod_tms_roundendevent", "1", "<1/2/0> = set RoundEnd Event  -  1 for swapping teams  -  2 for mixing teams  -  0 to disable",_, true, 0.0, true, 2.0)
	RoundEndMix = CreateConVar("dod_tms_roundendmix", "3", "<#> = Auto-Mix Teams after # consecutive round wins by a team",_, true, 1.0)
	RoundEndSwap = CreateConVar("dod_tms_roundendswap", "3", "<#> = Auto-Swap Teams after # rounds",_, true, 1.0)
	RoundEndStats = CreateConVar("dod_tms_roundendteamstats", "1", "<1/0> = enable/disable displaying some Team Stats on RoundEnd",_, true, 0.0, true, 1.0)
	HookEventEx("dod_stats_player_killed", OnPlayerKilled, EventHookMode_Post)
	HookEventEx("dod_round_win", OnRoundWin, EventHookMode_Post)
	AutoExecConfig(true,"addon_dodtms_roundendevents", "dod_teammanager_source")
	LoadTranslations("dod_teammanager_source.txt")
	LoadTranslations("dodtms_roundendevents.txt")
}

public OnAllPluginsLoaded()
{
	CreateTimer(0.4, DoDTMSRunning)
}

public OnMapStart()
{
	g_PlayedRounds = 0
	g_WonRoundsAllies = 0
	g_WonRoundsAxis = 0
	ResetStats()
}

public OnMapEnd()
{
	g_PlayedRounds = 0
	g_WonRoundsAllies = 0
	g_WonRoundsAxis = 0
	ResetStats()
}

public Action:ResetStats()
{
	g_Casualties[ALLIES] = 0
	g_Casualties[AXIS] = 0
	return Plugin_Handled
}

public Action:DoDTMSRunning(Handle:timer)
{
	if(!LibraryExists("DoDTeamManagerSource"))
	{
		SetFailState("[DoD TMS] Base Plugin not found!")
		return Plugin_Handled
	}
	TMSRegAddon("D")
	return Plugin_Handled
}

public OnDoDTMSDeleteCfg()
{
	decl String:configfile[256]
	Format(configfile, sizeof(configfile), "cfg/dod_teammanager_source/addon_dodtms_roundendevents.cfg")
	if(FileExists(configfile))
	{
		DeleteFile(configfile)
	}
}

public Action:OnRoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(RoundEndStats) == 0)
	{
		return Plugin_Continue
	}
	new WinnerTeam = GetEventInt(event, "team")
	new RoundTime = RoundToCeil(GetGameTime() - g_StartTime)
	ShowTeamStats(WinnerTeam, RoundTime)
	return Plugin_Continue
}

public OnDoDTMSRoundActive()
{
	g_StartTime = GetGameTime()
	ResetStats()
}
	

public Action:OnPlayerKilled(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetConVarInt(RoundEndStats) == 0)
	{
		return Plugin_Continue
	}
	new victim = GetClientOfUserId(GetEventInt(event, "victim"))
	if(IsValidEntity(victim) && IsClientConnected(victim) && IsClientInGame(victim))
	{
		new team = GetClientTeam(victim)
		g_Casualties[team]++
	}
	return Plugin_Continue
}

public Action:ShowTeamStats(WinnerTeam, RoundTime)
{
	new RoundMin = RoundToFloor(RoundTime / 60.0)
	new RoundSecs = RoundTime % 60
	decl String:RoundSec[3]
	if(RoundSecs < 10)
	{
		Format(RoundSec, sizeof(RoundSec), "0%i", RoundSecs)
	}
	else
	{
		Format(RoundSec, sizeof(RoundSec), "%i", RoundSecs)
	}
	new Handle:TeamStatsMenu = INVALID_HANDLE
	TeamStatsMenu = CreatePanel()
	decl String:menutitle[256]
	Format(menutitle, sizeof(menutitle), "[DoD TMS] RoundEnd TeamStats")
	SetPanelTitle(TeamStatsMenu, menutitle)
	DrawPanelItem(TeamStatsMenu, "", ITEMDRAW_SPACER)
	decl String:Winner[256]
	Format(Winner, sizeof(Winner), "%T", "Team Defeated", LANG_SERVER, TeamName[WinnerTeam], OpTeamName[WinnerTeam])
	DrawPanelText(TeamStatsMenu, Winner)
	DrawPanelItem(TeamStatsMenu, "", ITEMDRAW_SPACER)
	decl String:RoundCasualties[256]
	Format(RoundCasualties, sizeof(RoundCasualties), "%T", "Team Casualties", LANG_SERVER, g_Casualties[ALLIES], TeamName[ALLIES], g_Casualties[AXIS], TeamName[AXIS])
	DrawPanelText(TeamStatsMenu, RoundCasualties)
	DrawPanelItem(TeamStatsMenu, "", ITEMDRAW_SPACER)
	decl String:RoundWinTime[256]
	Format(RoundWinTime, sizeof(RoundWinTime), "%T", "RoundWon In", LANG_SERVER, RoundMin, RoundSec)
	DrawPanelText(TeamStatsMenu, RoundWinTime)
	DrawPanelItem(TeamStatsMenu, "", ITEMDRAW_SPACER)
	SetPanelCurrentKey(TeamStatsMenu, 10)
	DrawPanelItem(TeamStatsMenu, "Close", ITEMDRAW_CONTROL)
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientConnected(i) && IsClientInGame(i))
		{
			SendPanelToClient(TeamStatsMenu, i, Handle_TeamStats, 15)
		}
	}
}

public Handle_TeamStats(Handle:TeamStatsMenu, MenuAction:action, client, itemNum)
{	
}
	

public Action:OnDoDTMSRoundEnd(winnerteam)
{
	if(GetConVarInt(RoundEndEvent) == 0)
	{
		return Plugin_Continue
	}
	else if(GetConVarInt(RoundEndEvent) == 1)
	{
		new RESwap = GetConVarInt(RoundEndSwap)
		if(RESwap > 0)
		{
			decl String:message[265]
			g_PlayedRounds++
			if(g_PlayedRounds >= RESwap)
			{
				TMSSwapTeams()
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						if(RESwap == 1)
						{
							Format(message,sizeof(message),"%T", "RE Swapped", i)
						}
						else
						{
							Format(message,sizeof(message),"%T", "RE Swapped2", i, g_PlayedRounds,RESwap)
						}
						TMSMessage(i, message)
					}
				}
				g_PlayedRounds = 0
			}
			else if(g_PlayedRounds < RESwap)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						if(g_PlayedRounds+1 < RESwap)
						{
							Format(message,sizeof(message),"%T", "RE SwapIn", i, g_PlayedRounds,RESwap,RESwap-g_PlayedRounds)
						}
						else if(g_PlayedRounds+1 == RESwap)
						{
							Format(message,sizeof(message),"%T", "RE SwapNext", i, g_PlayedRounds,RESwap)
						}
						TMSMessage(i, message)
					}
				}
			}
		}
	}
	else if(GetConVarInt(RoundEndEvent) == 2)
	{	
		new REMix = GetConVarInt(RoundEndMix)
		if(REMix > 0)
		{
			if(winnerteam == ALLIES)
			{
				g_WonRoundsAllies++
				g_WonRoundsAxis = 0
			}
			else if(winnerteam == AXIS)
			{
				g_WonRoundsAxis++
				g_WonRoundsAllies = 0
			}
			decl String:message[265]
			if((g_WonRoundsAllies+g_WonRoundsAxis) >= REMix)
			{
				TMSMixTeams()
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						if(REMix == 1)
						{
							Format(message,sizeof(message),"%T", "RE Mixed", i)
						}
						else
						{
							Format(message,sizeof(message),"%T", "RE Mixed2", i, (g_WonRoundsAllies+g_WonRoundsAxis),REMix)
						}
						TMSMessage(i, message)
					}
				}
				g_WonRoundsAllies = 0
				g_WonRoundsAxis = 0
			}
			else if((g_WonRoundsAllies+g_WonRoundsAxis) < REMix)
			{
				for(new i = 1; i <= MaxClients; i++)
				{
					if(IsClientInGame(i))
					{
						if((g_WonRoundsAllies+g_WonRoundsAxis)+1 < REMix)
						{
							Format(message,sizeof(message),"%T", "RE MixIn", i, (g_WonRoundsAllies+g_WonRoundsAxis),REMix,REMix-(g_WonRoundsAllies+g_WonRoundsAxis))
						}
						else if((g_WonRoundsAllies+g_WonRoundsAxis)+1 == REMix)
						{
							Format(message,sizeof(message),"%T", "RE MixNext", i, (g_WonRoundsAllies+g_WonRoundsAxis),REMix)
						}
						TMSMessage(i, message)
					}
				}
			}
		}
	}
	return Plugin_Continue
}