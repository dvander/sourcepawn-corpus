/**
 * mapchooser.sp
 * Adds a vote for the next map.
 */

#include <sourcemod>

#pragma semicolon 1

#define PLUGIN_VERSION "1.3"

public Plugin:myinfo = 
{
	name = "Mapchooser",
	author = "ferret",
	description = "Map vote at end of map",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

#define MAXMAPS 128
#define SELECTMAPS 5

new String:g_szModName[32];

new String:g_szMapNames[MAXMAPS][32];
new g_iMapCount = 0;
new g_iTeamScore[4];
new g_iNextMaps[SELECTMAPS];

new Handle:g_hSmExtendMax = INVALID_HANDLE;
new Handle:g_hSmExtendStep = INVALID_HANDLE;
new Handle:g_hSmExtendRMax = INVALID_HANDLE;
new Handle:g_hSmExtendRStep = INVALID_HANDLE;
new Handle:g_hSmStartVoteTime = INVALID_HANDLE;
new Handle:g_hSmLastMap = INVALID_HANDLE;
new Handle:g_hSmNextMap = INVALID_HANDLE;
new Handle:g_hSmMapChooserFile = INVALID_HANDLE;

new Handle:g_hMpMaxrounds = INVALID_HANDLE;
new Handle:g_hMpTimelimit = INVALID_HANDLE;

new Handle:g_hCheckTimer = INVALID_HANDLE;

new Float:g_fStartTime;

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.mapchooser");
	
	CreateConVar("sm_mapchooser_version", PLUGIN_VERSION, "MapChooser Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_hSmExtendMax = CreateConVar("sm_extendmap_max", "90", "Maximum time a map can be extended (Def 90 minutes)");
	g_hSmExtendStep = CreateConVar("sm_extendmap_step", "15", "How much longer does each extension make the map? (Def 15 minutes)"); 
	g_hSmExtendRMax = CreateConVar("sm_extendmap_rmax", "30", "Maximum rounds a map can be extended? (Def 12 rounds)");
	g_hSmExtendRStep = CreateConVar("sm_extendmap_rstep", "5", "How many more rounds does each extension make the map? (Def 2 rounds)");
	g_hSmStartVoteTime = CreateConVar("sm_startvotetime", "180", "Start the vote when this much time remains. (Default 180 seconds)");
	g_hSmLastMap = CreateConVar("sm_extendmap_max", "90", "The last map played.");
	g_hSmMapChooserFile = CreateConVar("sm_mapchooser_file", "configs/maps.ini", "Map file to use. (Def configs/maps.ini)");

	g_hMpTimelimit = FindConVar("mp_timelimit");

	GetGameFolderName(g_szModName, sizeof(g_szModName));	
	
	if(strcmp(g_szModName, "zombie_master", false) == 0)
	{
		g_hMpMaxrounds = FindConVar("zm_roundlimit");
	}	
	
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
}

public OnMapStart()
{
	g_fStartTime = GetEngineTime();
	
	decl String:szMapPath[256], String:szMapFile[64];
	GetConVarString(g_hSmMapChooserFile, szMapFile, 64);
	BuildPath(Path_SM, szMapPath, sizeof(szMapPath), szMapFile);
	if(!FileExists(szMapPath))
	{
		new Handle:hMapCycleFile = FindConVar("mapcyclefile");
		GetConVarString(hMapCycleFile, szMapPath, sizeof(szMapPath));	
	}
	
	LogMessage("[MapChooser] Map Cycle Path: %s", szMapPath);
	
	if(LoadSettings(szMapPath))
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

public Event_RoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(GetEventInt(event, "reason") == 16)
		g_fStartTime = GetEngineTime();
}

public Action:Timer_DelayStart(Handle:timer)
{
	g_hSmNextMap = FindConVar("sm_nextmap");
	if(g_hSmNextMap == INVALID_HANDLE)
	{
		LogMessage("[MapChooser] Cannot find sm_nextmap, mapchooser not active.");
		return;
	}	
	
	if(strcmp(g_szModName, "zombie_master", false) == 0)
		HookEvent("team_score", Event_TeamScore, EventHookMode_Post);
	
	if(g_hCheckTimer == INVALID_HANDLE)
		g_hCheckTimer = CreateTimer(30.0, Timer_CheckLimits, _, TIMER_REPEAT);
	else
		LogMessage("[MapChooser] g_hCheckTimer not INVALID_HANDLE in Timer_DelayStart! Why not? Check logs!");
}

public Action:Timer_CheckLimits(Handle:timer)
{
	new iMaxRounds;
	new iTimeLimit = GetConVarInt(g_hMpTimelimit);
	
	if(strcmp(g_szModName, "zombie_master", false) == 0)
	{
		iMaxRounds = GetConVarInt(g_hMpMaxrounds);
	}
	
	new bool:bIssueVote = false;
	
	if(iMaxRounds)
	{
		new iLimit = iMaxRounds;
		if((g_iTeamScore[2] + g_iTeamScore[3]) > iLimit)
			bIssueVote = true;
	}
	else
	{
		new Float:iLimit = GetTimeLeft();
		if(iLimit < GetConVarFloat(g_hSmStartVoteTime))
			bIssueVote = true;
	}
	
	if(bIssueVote)
	{
		new Handle:hMapVoteMenu = CreateMenu(Handler_MapVoteMenu);
		SetMenuTitle(hMapVoteMenu, "%T", "Choose Next Map", LANG_SERVER);
		
		new iMap;
		for(new i = 0; i < (g_iMapCount < SELECTMAPS ? g_iMapCount : SELECTMAPS); i++)
		{
			iMap = GetRandomInt(0, g_iMapCount - 1);

			while(IsInMenu(iMap))
				if(++iMap >= g_iMapCount) iMap = 0;
			
			g_iNextMaps[i] = iMap;
			AddMenuItem(hMapVoteMenu, g_szMapNames[iMap], g_szMapNames[iMap]);
		}
		
		if(iTimeLimit < GetConVarInt(g_hSmExtendMax) || (iMaxRounds && iMaxRounds < GetConVarInt(g_hSmExtendRMax)))
		{
			AddMenuItem(hMapVoteMenu, "extend", "Extend");
		}
		
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
		new String:szVoter[64], String:szChoice[64];
		GetClientName(param1, szVoter, sizeof(szVoter));
		GetMenuItem(menu, param2, szChoice, sizeof(szChoice));
		PrintToChatAll("[SM] %T", "Selected Map", LANG_SERVER, szVoter, szChoice);
	}	
	else if (action == MenuAction_VoteEnd)
	{
		new String:szMap[64];
		new iVotes, iTotalVotes;
		GetMenuVoteInfo(param2, iVotes, iTotalVotes);
		
		if(iTotalVotes < 1)
		{
			PrintToChatAll("[SM] %T", "No Map Chosen", LANG_SERVER);
			return;
		}
		
		GetMenuItem(menu, param1, szMap, sizeof(szMap));
		
		if(strcmp(szMap, "extend", false) == 0)
		{
			new iMaxRounds;
			new iTimeLimit = GetConVarInt(g_hMpTimelimit);
			
			if(strcmp(g_szModName, "zombie_master", false) == 0)
			{
				iMaxRounds = GetConVarInt(g_hMpMaxrounds);
			}
			
			new iTimeExtendMax = GetConVarInt(g_hSmExtendMax);
			new iTimeExtendStep = GetConVarInt(g_hSmExtendStep);
			new iRoundExtendMax = GetConVarInt(g_hSmExtendRMax);
			new iRoundExtendStep = GetConVarInt(g_hSmExtendRStep);
			
			if(iTimeLimit < iTimeExtendMax)
			{
				iTimeLimit += iTimeExtendStep;
				SetConVarInt(g_hMpTimelimit, iTimeLimit);
			}
			
			if(iMaxRounds && iMaxRounds < iRoundExtendMax)
			{
				iMaxRounds += iRoundExtendStep;
				SetConVarInt(g_hMpMaxrounds, iMaxRounds);
			}
			
			PrintToChatAll("[SM] %T", "Current Map Extended", LANG_SERVER);
			LogMessage("Voting for next map has finished. Current map extended.");
		}
		else
		{
			SetConVarString(g_hSmNextMap, szMap);
			new String:szCurrentMap[64];
			GetCurrentMap(szCurrentMap, sizeof(szCurrentMap));
			SetConVarString(g_hSmLastMap, szCurrentMap);
			PrintToChatAll("[SM] %T", "Next Map Chosen", LANG_SERVER, szMap);
			LogMessage("Voting for next map has finished. Nextmap: %s.", szMap);
		}
	}
}

public Event_TeamScore(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iTeam = GetEventInt(event, "teamid");
	new iScore = GetEventInt(event, "score");
	
	g_iTeamScore[iTeam] = iScore;
}

bool:IsInMenu(id)
{
	for (new i = 0; i < SELECTMAPS; i++)
		if (id == g_iNextMaps[i])
			return true;
	return false;
}

LoadSettings(String:szFilename[])
{
	if (!FileExists(szFilename))
		return 0;

	new String:szText[32];
	new String:szCurrentMap[64], String:szLastMap[64];
	
	GetConVarString(g_hSmLastMap, szLastMap, sizeof(szLastMap));
	GetCurrentMap(szCurrentMap, sizeof(szCurrentMap));

	new Handle:hMapFile = OpenFile(szFilename, "r");
	
	g_iMapCount = 0;
	
	while(g_iMapCount < MAXMAPS && !IsEndOfFile(hMapFile))
	{
		ReadFileLine(hMapFile, szText, sizeof(szText));
		TrimString(szText);

		if (szText[0] != ';' && strcopy(g_szMapNames[g_iMapCount], sizeof(g_szMapNames[]), szText) &&
			IsMapValid(g_szMapNames[g_iMapCount]) && strcmp(g_szMapNames[g_iMapCount], szLastMap, false) != 0 &&
			strcmp(g_szMapNames[g_iMapCount], szCurrentMap, false) != 0)
		{
			++g_iMapCount;
		}
	}

	return g_iMapCount;
}

Float:GetTimeLeft()
{
	new Float:fLimit = GetConVarFloat(g_hMpTimelimit);
	new Float:fElapsed = GetEngineTime() - g_fStartTime;

	return (fLimit*60.0) - fElapsed;
}
