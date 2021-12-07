#pragma semicolon 1

#include <sourcemod>

#define CLIENTS		0
#define EVENT			1
#define ROUND			2
#define TIMELEFT	3
#define TOTAL			4

#define PL_VERSION "1.2.3"

public Plugin:myinfo =
{
  name        = "Execute Configs",
  author      = "Tsunami to v1.0, volt to v1.1, FirEXE to v1.2.2, Franug to v1.2.3",
  description = "Execute configs on certain events.",
  version     = PL_VERSION,
  url         = "http://www.tsunami-productions.nl"
};


/**
 * Globals
 */
new g_iRound;
new bool:g_bSection;
new Handle:g_hConfigParser;
// cVar handles
new Handle:g_cVarEnabled;
new Handle:g_cVarFile;
new Handle:g_cVarIncludeBots;
new Handle:g_cVarIncludeSpec;
new Handle:g_cVarLastTypeConfOnly;
new Handle:g_cVarSchedMinTime;
new Handle:g_hCvarRestartGame;
// cVar global values
new bool:g_bEnabled;
new String:g_sFile[PLATFORM_MAX_PATH + 1];
new bool:g_bIncludeBots;
new bool:g_bIncludeSpec;
new bool:g_bLastTypeConfOnly;
new Float:g_fSchedMinTime;

new Handle:g_hTimer;
new Handle:g_hTimers[TOTAL];
new Handle:g_hTries[TOTAL];
new Handle:g_hTypes;
new String:g_sMap[32];
new iClientsLast = 0;
new g_iExecClientsConfigPending = 0;


/**
 * Forwards
 */
public OnPluginStart()
{
	CreateConVar("sm_executeconfigs_version", PL_VERSION, "Execute configs on certain events.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cVarEnabled			= CreateConVar("sm_executeconfigs_enabled",      "1", "Enable/disable executing configs");
	g_cVarFile				= CreateConVar("sm_executeconfigs_file",		 "executeconfigs.txt", "File to read the executeconfigs from.");
	g_cVarIncludeBots		= CreateConVar("sm_executeconfigs_include_bots", "1", "Enable/disable including bots when counting number of clients");
	g_cVarIncludeSpec		= CreateConVar("sm_executeconfigs_include_spec", "1", "Enable/disable including spectators when counting number of clients");
	g_cVarLastTypeConfOnly	= CreateConVar("sm_executeconfigs_most_recent_only", "0", "Enable/disable avoiding of execution previously scheduled configs if the new schedule of the same type (client, map, ...) config appears.");
	g_cVarSchedMinTime	= CreateConVar("sm_executeconfigs_sched_min_time", "0.5", "The minimal time in seconds between schedules - depends on the longest time needed to execute CFG file. If next CFG execution comes sooner than current CFG is executed it will be skipped. 0.5 seconds is suitable for most cases.");
	
	RegServerCmd("sm_executeconfigs_reload", Command_Reload, "Reload the configs");
	
	g_hConfigParser = SMC_CreateParser();
	SMC_SetReaders(g_hConfigParser, ReadConfig_NewSection, ReadConfig_KeyValue, ReadConfig_EndSection);
	
	g_hTypes        = CreateTrie();
	SetTrieValue(g_hTypes, "clients",  CLIENTS);
	SetTrieValue(g_hTypes, "event",    EVENT);
	SetTrieValue(g_hTypes, "round",    ROUND);
	SetTrieValue(g_hTypes, "timeleft", TIMELEFT);
	
	for(new i = 0; i < TOTAL; i++)
		g_hTries[i] = CreateTrie();
	
	decl String:sGameDir[64];
	GetGameFolderName(sGameDir, sizeof(sGameDir));
	
	HookEvent("player_team", Event_PlayerChangeTeam, EventHookMode_PostNoCopy);
	if(StrEqual(sGameDir, "insurgency"))
		HookEvent("game_newmap",            Event_GameStart,  EventHookMode_PostNoCopy);
	else
		HookEvent("game_start",             Event_GameStart,  EventHookMode_PostNoCopy);
	
	if(StrEqual(sGameDir, "dod"))
		HookEvent("dod_round_start",        Event_RoundStart, EventHookMode_PostNoCopy);
	else if(StrEqual(sGameDir, "tf"))
	{
		HookEvent("teamplay_restart_round", Event_GameStart,  EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_start",   Event_RoundStart, EventHookMode_PostNoCopy);
	}
	else
	
	//Hook game restart
	HookEvent("round_start",            Event_RoundStart, EventHookMode_PostNoCopy);
	g_hCvarRestartGame = FindConVar("mp_restartgame");
    

	//Hook cVar changes
	HookConVarChange(g_hCvarRestartGame, CvarChange_RestartGame);
	HookConVarChange(g_cVarEnabled, CVarChange);
	HookConVarChange(g_cVarFile, CVarChange);
	HookConVarChange(g_cVarIncludeBots, CVarChange);
	HookConVarChange(g_cVarIncludeSpec, CVarChange);
	HookConVarChange(g_cVarLastTypeConfOnly, CVarChange);
	HookConVarChange(g_cVarSchedMinTime, CVarChange);
	
	//Set cVar globals
	g_bEnabled = GetConVarBool(g_cVarEnabled);
	GetConVarString(g_cVarFile, g_sFile, sizeof(g_sFile));
	g_bIncludeBots = GetConVarBool(g_cVarIncludeBots);
	g_bIncludeSpec = GetConVarBool(g_cVarIncludeSpec);
	g_bLastTypeConfOnly = GetConVarBool(g_cVarLastTypeConfOnly);
	g_fSchedMinTime = GetConVarFloat(g_cVarSchedMinTime);
	
	AutoExecConfig(true,"sm_executeconfigs");
	
	CreateTimer(0.1, Timer_ParseConfig);
}

public CVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == g_cVarEnabled)
		g_bEnabled = GetConVarBool(g_cVarEnabled);
	else if (convar == g_cVarFile)
		GetConVarString(g_cVarFile, g_sFile, sizeof(g_sFile));
	else if (convar == g_cVarIncludeBots)
		g_bIncludeBots = GetConVarBool(g_cVarIncludeBots);
	else if (convar == g_cVarIncludeSpec)
		g_bIncludeSpec = GetConVarBool(g_cVarIncludeSpec);
	else if (convar == g_cVarLastTypeConfOnly)
		g_bLastTypeConfOnly = GetConVarBool(g_cVarLastTypeConfOnly);
	else if (convar == g_cVarSchedMinTime)
		g_fSchedMinTime = GetConVarFloat(g_cVarSchedMinTime);
}

public CvarChange_RestartGame(Handle:convar, const String:oldValue[], const String:newValue[])
{
    if (StringToInt(newValue) > 0)
    {
        g_iRound = 0;
    }
}

public OnMapStart()
{
	g_iRound = 0;
	g_hTimer = INVALID_HANDLE;
	
	for(new i = 0; i < TOTAL; i++)
		g_hTimers[i] = INVALID_HANDLE;
	
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	
	iClientsLast = -1;
	ExecClientsConfig(0);
}

public OnMapTimeLeftChanged()
{
	if(g_hTimer != INVALID_HANDLE)
	{
		KillTimer(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	
	new iTimeleft;
	if(GetMapTimeLeft(iTimeleft) && iTimeleft > 0)
		g_hTimer = CreateTimer(60.0, Timer_ExecTimeleftConfig, _, TIMER_REPEAT);
}

public OnClientPutInServer(client)
{
		CreateTimer(0.1, Timer_ExecClientsConfig);
}

public OnClientDisconnect(client)
{
		CreateTimer(0.1, Timer_ExecClientsConfig);
}


/**
 * Commands
 */
public Action:Command_Reload(args)
{
	ParseConfig();
}


/**
 * Events
 */
public Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iRound = 0;
}

public Event_Hook(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_bEnabled)
		ExecConfig(EVENT, name);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iRound++;
	
	if(!g_bEnabled)
		return;
	
	decl String:sRound[4];
	IntToString(g_iRound, sRound, sizeof(sRound));
	ExecConfig(ROUND, sRound);
}

public Event_PlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	CreateTimer(0.1, Timer_ExecClientsConfig);
}


/**
 * Timers
 */
public Action:Timer_ExecConfig(Handle:timer, any:pack)
{
	ResetPack(pack);
	
	decl String:sConfig[32];
	new iType = ReadPackCell(pack);
	ReadPackString(pack, sConfig, sizeof(sConfig));
	
	ServerCommand("exec %s", sConfig);
	g_hTimers[iType] = INVALID_HANDLE;
}

public Action:Timer_ExecTimeleftConfig(Handle:timer)
{
	if(!g_bEnabled)
		return Plugin_Handled;
	
	new iTimeleft;
	if(!GetMapTimeLeft(iTimeleft) || iTimeleft < 0)
		return Plugin_Handled;
	
	decl String:sTimeleft[4];
	IntToString(iTimeleft / 60, sTimeleft, sizeof(sTimeleft));
	ExecConfig(TIMELEFT, sTimeleft);
	
	return Plugin_Handled;
}

public Action:Timer_ParseConfig(Handle:timer)
{
	ParseConfig();
	ExecConfig(CLIENTS, "0");
}

public Action:Timer_ExecClientsConfig(Handle:timer)
{
	ExecClientsConfig(0);
}

public Action:Timer_ExecConfigClients(Handle:timer, any:iClients)
{
	decl String:sClients[4];
	
	IntToString(iClients, sClients, sizeof(sClients));
	ExecConfig(CLIENTS, sClients);
	g_iExecClientsConfigPending--;
}

/**
 * Config Parser
 */
public SMCResult:ReadConfig_EndSection(Handle:smc) {}

public SMCResult:ReadConfig_KeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if(!g_bSection || !key[0])
		return SMCParse_Continue;
	
	decl iType, String:sKeys[2][32];
	ExplodeString(key, ":", sKeys, sizeof(sKeys), sizeof(sKeys[]));
	if(!GetTrieValue(g_hTypes, sKeys[0], iType))
		return SMCParse_Continue;
	
	SetTrieString(g_hTries[iType], sKeys[1], value);
	if(iType == EVENT)
		HookEvent(sKeys[1], Event_Hook);
	
	return SMCParse_Continue;
}

public SMCResult:ReadConfig_NewSection(Handle:smc, const String:name[], bool:opt_quotes)
{
	g_bSection = StrEqual(name, "*") || strncmp(g_sMap, name, strlen(name), false) == 0;
}


/**
 * Stocks
 */
ExecClientsConfig(iClients)
{
	if(!g_bEnabled)
		return;
	
	if(g_bIncludeBots && g_bIncludeSpec)
		iClients += GetClientCount();
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
				continue;
			
			if ((g_bIncludeBots || !IsFakeClient(i)) && (g_bIncludeSpec || (GetClientTeam(i) == 2 || GetClientTeam(i) == 3)))
				iClients++;
		}
	}
	//PrintToChatAll("\x01\x04[ExecConf]\x01 Valid player count: %i",iClients);
	//LogAction(-1, -1, "Valid player count: %i",iClients);
	
	if (iClientsLast == iClients)
	{
		//PrintToChatAll("\x01\x04[ExecConf]\x01 Client cfg execution blocked");
		//LogAction(-1, -1, "Client cfg execution blocked");
		return;
	}
	
	decl iCl;
	if (iClientsLast < iClients)
	{
		for(iCl=iClientsLast+1;iCl<=iClients;iCl++)
		{
			if ((g_iExecClientsConfigPending == 0) && (iCl == iClientsLast+1))
			{
				//LogAction(-1, -1, "Scheduled client %i CFG execution with timer delay 0.0", iCl);
				CreateTimer(0.0, Timer_ExecConfigClients, iCl);
			}
			else
			{
				CreateTimer(g_iExecClientsConfigPending*g_fSchedMinTime, Timer_ExecConfigClients, iCl);
				//LogAction(-1, -1, "Scheduled client %i CFG execution with timer delay %f",iCl,g_iExecClientsConfigPending*g_fSchedMinTime);
			}
			g_iExecClientsConfigPending++;
		}
	}
	else 
	{
		for(iCl=iClientsLast-1;iCl>=iClients;iCl--)
		{
			if ((g_iExecClientsConfigPending == 0) && (iCl == iClientsLast+1))
			{
				//LogAction(-1, -1, "Scheduled client %i CFG execution with timer delay 0.0", iCl);
				CreateTimer(0.0, Timer_ExecConfigClients, iCl);
			}
			else
			{
				CreateTimer(g_iExecClientsConfigPending*g_fSchedMinTime, Timer_ExecConfigClients, iCl);
				//LogAction(-1, -1, "Scheduled client %i CFG execution with timer delay %f",iCl,g_iExecClientsConfigPending*g_fSchedMinTime);
			}
			g_iExecClientsConfigPending++;
		}
	}
	
	iClientsLast = iClients;
}

ExecConfig(iType, const String:sKey[])
{
	decl String:sValue[64];
	if(!GetTrieString(g_hTries[iType], sKey, sValue, sizeof(sValue)))
		return;
	
	decl String:sValues[2][32];
	ExplodeString(sValue, ":", sValues, sizeof(sValues), sizeof(sValues[]));
	
	new Handle:hPack = CreateDataPack();
	WritePackCell(hPack,   iType);
	WritePackString(hPack, sValues[1]);
	
	if ((g_hTimers[iType] != INVALID_HANDLE) && g_bLastTypeConfOnly)
	{
		KillTimer(g_hTimers[iType]);
		g_hTimers[iType] = INVALID_HANDLE;
	}

	g_hTimers[iType] = CreateTimer(StringToFloat(sValues[0]), Timer_ExecConfig, hPack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
}

ParseConfig()
{
	decl String:g_sConfigFile[PLATFORM_MAX_PATH + 1];
	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/%s", g_sFile);
	
	
	if(!FileExists(g_sConfigFile))
	{
		SetFailState("File Not Found: %s", g_sConfigFile);
		return;
	}
	
	for(new i = 0; i < TOTAL; i++)
		ClearTrie(g_hTries[i]);
	
	new SMCError:iError = SMC_ParseFile(g_hConfigParser, g_sConfigFile);
	if(iError)
	{
		decl String:sError[64];
		if(SMC_GetErrorString(iError, sError, sizeof(sError)))
			LogError(sError);
		else
			LogError("Fatal parse error");
		return;
	}
}