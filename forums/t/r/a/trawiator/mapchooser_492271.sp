/**
 * mapchooser.sp
 * Adds a vote for the next map.
 */

#include <sourcemod>

#pragma semicolon 1

public Plugin:myinfo = 
{
	name = "Mapchooser",
	author = "ferret",
	description = "Map vote at end of map",
	version = "0.1",
	url = "http://www.sourcemod.net/"
};

#define MAXMAPS 128
#define SELECTMAPS 5

new String:g_mapNames[MAXMAPS][32];
new g_mapCount = 0;
new g_teamScore[4];
new g_nextMaps[SELECTMAPS];

new Handle:g_hSmExtendMax = INVALID_HANDLE;
new Handle:g_hSmExtendStep = INVALID_HANDLE;
new Handle:g_hSmExtendRMax = INVALID_HANDLE;
new Handle:g_hSmExtendRStep = INVALID_HANDLE;
new Handle:g_hSmLastMap = INVALID_HANDLE;
new Handle:g_hSmNextMap = INVALID_HANDLE;

new Handle:g_hMpWinlimit = INVALID_HANDLE;
//new Handle:g_hMpMaxrounds = INVALID_HANDLE;
new Handle:g_hMpTimelimit = INVALID_HANDLE;

new Handle:g_hCheckTimer = INVALID_HANDLE;

new Float:g_fStartTime;

public OnPluginStart()
{
	LoadTranslations("common.cfg");
	LoadTranslations("plugin.mapchooser.cfg");
	
	g_hSmExtendMax = CreateConVar("sm_extendmap_max", "40", "Maximum time a map can be extended (Def 90 minutes)");
	g_hSmExtendStep = CreateConVar("sm_extendmap_step", "10", "How much longer does each extension make the map? (Def 15 minutes)"); 
//	g_hSmExtendRMax = CreateConVar("sm_extendmap_rmax", "30", "Maximum rounds a map can be extended? (Def 12 rounds)");
//	g_hSmExtendRStep = CreateConVar("sm_extendmap_rstep", "5", "How many more rounds does each extension make the map? (Def 2 rounds)");
	g_hSmLastMap = CreateConVar("sm_extendmap_max", "90", "The last map played.");
	
	g_hMpWinlimit = FindConVar("mp_winlimit");
//	g_hMpMaxrounds = FindConVar("mp_maxrounds");
	g_hMpTimelimit = FindConVar("mp_timelimit");
	
	g_fStartTime = GetEngineTime();
}

public OnMapStart()
{
	new String:mapIniPath[256];
	BuildPath(Path_SM, mapIniPath, sizeof(mapIniPath), "configs/maps.ini");
	if(!FileExists(mapIniPath))
	{
		new Handle:hMapCycleFile = FindConVar("mapcyclefile");
		GetConVarString(hMapCycleFile, mapIniPath, sizeof(mapIniPath));	
	}
	
	LogMessage("[MapChooser] Map Cycle Path: %s", mapIniPath);
	
	if(LoadSettings(mapIniPath))
		CreateTimer(2.0, Timer_DelayStart);
	else
		LogMessage("[MapChooser] Cannot find map cycle file, mapchooser not active.");	
}

public OnMapEnd()
{
	if(g_hCheckTimer != INVALID_HANDLE)
	{
		KillTimer(g_hCheckTimer);
		g_hCheckTimer = INVALID_HANDLE;
	}
}

public Action:Timer_DelayStart(Handle:timer)
{
	g_hSmNextMap = FindConVar("sm_nextmap");
	if(g_hSmNextMap == INVALID_HANDLE)
	{
		LogMessage("[MapChooser] Cannot find sm_nextmap, mapchooser not active.");
		return;
	}	
	
	HookEvent("team_score", Event_TeamScore, EventHookMode_Post);
	g_hCheckTimer = CreateTimer(30.0, Timer_CheckLimits, _, TIMER_REPEAT);
}

public Action:Timer_CheckLimits(Handle:timer)
{
//	new iWinLimit = GetConVarInt(g_hMpWinlimit);
//	new iMaxRounds = GetConVarInt(g_hMpMaxrounds);
	new iTimeLimit = GetConVarInt(g_hMpTimelimit);
	
	new bool:bIssueVote = false;
	
/*	if(iWinLimit)
	{
		new iLimit = iWinLimit - 2;
		if(g_teamScore[2] > iLimit || g_teamScore[3] > iLimit)
			bIssueVote = true;		
	}
	else if(iMaxRounds)
	{
		new iLimit = iMaxRounds - 2;
		if((g_teamScore[2] + g_teamScore[3]) > iLimit)
			bIssueVote = true;
	}
*/
	//else
	//{
		new Float:iLimit = GetTimeLeft();
		if(iLimit < 180.0)
			bIssueVote = true;
	//}
	
	if(bIssueVote)
	{
		new Handle:hMapVoteMenu = CreateMenu(Handler_MapVoteMenu);
		SetMenuTitle(hMapVoteMenu, "%T", "Choose Next Map", LANG_SERVER);
		
		new iMap;
		for(new i = 0; i < (g_mapCount < SELECTMAPS ? g_mapCount : SELECTMAPS); i++)
		{
			iMap = GetRandomInt(0, g_mapCount - 1);

			while(IsInMenu(iMap))
				if(++iMap >= g_mapCount) iMap = 0;
			
			g_nextMaps[i] = iMap;
			AddMenuItem(hMapVoteMenu, g_mapNames[iMap], g_mapNames[iMap]);
		}
		
/*		if(iTimeLimit < GetConVarInt(g_hSmExtendMax) || (iWinLimit && iWinLimit < GetConVarInt(g_hSmExtendRMax)) || (iMaxRounds && iMaxRounds < GetConVarInt(g_hSmExtendRMax)))
		{
			AddMenuItem(hMapVoteMenu, "extend", "Extend");
		}
*/		
		SetMenuExitButton(hMapVoteMenu, false);
		VoteMenuToAll(hMapVoteMenu, 20);			
	
		LogMessage("Voting for next map has started.");	
	
		KillTimer(g_hCheckTimer);
		g_hCheckTimer = INVALID_HANDLE;
	}
}

public Handler_MapVoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		CloseHandle(menu);
		menu = INVALID_HANDLE;
	}
	else if (action == MenuAction_Select)
	{
		new String:voter[64], String:choice[64];
		GetClientName(param1, voter, sizeof(voter));
		GetMenuItem(menu, param2, choice, sizeof(choice));
		PrintToChatAll("[SM] %T", "Selected Map", LANG_SERVER, voter, choice);
	}	
	else if (action == MenuAction_VoteEnd)
	{
		new String:map[64];
		new votes, totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		
		if(totalVotes < 1)
		{
			PrintToChatAll("[SM] %T", "No Map Chosen", LANG_SERVER);
			return;
		}
		
		GetMenuItem(menu, param1, map, sizeof(map));
		
		if(strcmp(map, "extend", false) == 0)
		{
//			new iWinLimit = GetConVarInt(g_hMpWinlimit);
//			new iMaxRounds = GetConVarInt(g_hMpMaxrounds);
			new iTimeLimit = GetConVarInt(g_hMpTimelimit);
			new iTimeExtendMax = GetConVarInt(g_hSmExtendMax);
			new iTimeExtendStep = GetConVarInt(g_hSmExtendStep);
//			new iRoundExtendMax = GetConVarInt(g_hSmExtendRMax);
//			new iRoundExtendStep = GetConVarInt(g_hSmExtendRStep);
			
			if(iTimeLimit < iTimeExtendMax)
			{
				iTimeLimit += iTimeExtendStep;
				SetConVarInt(g_hMpTimelimit, iTimeLimit);
			}
			
/*			if(iMaxRounds < iRoundExtendMax)
			{
				iMaxRounds += iRoundExtendStep;
				SetConVarInt(g_hMpMaxrounds, iMaxRounds);
			}
			
			if(iWinLimit < iRoundExtendMax)
			{
				iWinLimit += iRoundExtendStep;
				SetConVarInt(g_hMpWinlimit, iWinLimit);
			}
*/			
			PrintToChatAll("[SM] %T", "Current Map Extended", LANG_SERVER);
			LogMessage("Voting for next map has finished. Current map extended.");
		}
		else
		{
			SetConVarString(g_hSmNextMap, map);
			new String:cMap[64];
			GetCurrentMap(cMap, sizeof(cMap));
			SetConVarString(g_hSmLastMap, cMap);
			PrintToChatAll("[SM] %T", "Next Map Chosen", LANG_SERVER, map);
			LogMessage("Voting for next map has finished. Nextmap: %s.", map);
		}
	}
}

public Event_TeamScore(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iTeam = GetEventInt(event, "teamid");
	new iScore = GetEventInt(event, "score");
	
	g_teamScore[iTeam] = iScore;
}

bool:IsInMenu(id)
{
	for (new i = 0; i < SELECTMAPS; i++)
		if (id == g_nextMaps[i])
			return true;
	return false;
}

LoadSettings(String:filename[])
{
	if (!FileExists(filename))
		return 0;

	new String:szText[32];
	new String:currentMap[64], String:lastMap[64];
	
	GetConVarString(g_hSmLastMap, lastMap, sizeof(lastMap));
	GetCurrentMap(currentMap, sizeof(currentMap));

	new Handle:hMapFile = OpenFile(filename, "r");
	
	while(g_mapCount < MAXMAPS && !IsEndOfFile(hMapFile))
	{
		ReadFileLine(hMapFile, szText, sizeof(szText));
		TrimString(szText);

		if (szText[0] != ';' && strcopy(g_mapNames[g_mapCount], sizeof(g_mapNames[]), szText) &&
			IsMapValid(g_mapNames[g_mapCount]) && strcmp(g_mapNames[g_mapCount], lastMap, false) != 0 &&
			strcmp(g_mapNames[g_mapCount], currentMap, false) != 0)
		{
			++g_mapCount;
		}
	}

	return g_mapCount;
}

Float:GetTimeLeft()
{
	new Float:fLimit = GetConVarFloat(g_hMpTimelimit);
	new Float:fElapsed = GetEngineTime() - g_fStartTime;

	return (fLimit*60.0) - fElapsed;
}