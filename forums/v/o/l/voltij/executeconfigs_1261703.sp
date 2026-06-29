#pragma semicolon 1

#include <sourcemod>

#define CLIENTS		0
#define EVENT			1
#define ROUND			2
#define TIMELEFT	3
#define TOTAL			4

#define PL_VERSION "1.1"

public Plugin:myinfo =
{
  name        = "Execute Configs",
  author      = "Tsunami to v1.0, volt to v1.1",
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
new Handle:g_hEnabled;
new Handle:g_hFile;
new Handle:g_hIncludeBots;
new Handle:g_hIncludeSpec;
new Handle:g_hTimer;
new Handle:g_hTimers[TOTAL];
new Handle:g_hTries[TOTAL];
new Handle:g_hTypes;
new String:g_sMap[32];


/**
 * Forwards
 */
public OnPluginStart()
{
	CreateConVar("sm_executeconfigs_version", PL_VERSION, "Execute configs on certain events.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_hEnabled      = CreateConVar("sm_executeconfigs_enabled",      "1", "Enable/disable executing configs");
	g_hFile		= CreateConVar("sm_executeconfigs_file",		 "executeconfigs.txt", "File to read the executeconfigs from.");
	g_hIncludeBots  = CreateConVar("sm_executeconfigs_include_bots", "1", "Enable/disable including bots when counting number of clients");
	g_hIncludeSpec  = CreateConVar("sm_executeconfigs_include_spec", "1", "Enable/disable including spectators when counting number of clients");
	
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
		HookEvent("round_start",            Event_RoundStart, EventHookMode_PostNoCopy);
}

public OnMapStart()
{
	g_iRound = 0;
	g_hTimer = INVALID_HANDLE;
	
	for(new i = 0; i < TOTAL; i++)
		g_hTimers[i] = INVALID_HANDLE;
	
	GetCurrentMap(g_sMap, sizeof(g_sMap));
	ParseConfig();
}

public OnMapTimeLeftChanged()
{
	if(g_hTimer)
	{
		CloseHandle(g_hTimer);
		g_hTimer = INVALID_HANDLE;
	}
	
	new iTimeleft;
	if(GetMapTimeLeft(iTimeleft) && iTimeleft > 0)
		g_hTimer = CreateTimer(60.0, Timer_ExecTimeleftConfig, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public OnClientPutInServer(client)
{
  ExecClientsConfig(0);
}

public OnClientDisconnect(client)
{
  ExecClientsConfig(-1);
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
	if(GetConVarBool(g_hEnabled))
		ExecConfig(EVENT, name);
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iRound++;
	
	if(!GetConVarBool(g_hEnabled))
		return;
	
	decl String:sRound[4];
	IntToString(g_iRound, sRound, sizeof(sRound));
	ExecConfig(ROUND, sRound);
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
	if(!GetConVarBool(g_hEnabled))
		return Plugin_Handled;
	
	new iTimeleft;
	if(!GetMapTimeLeft(iTimeleft) || iTimeleft < 0)
		return Plugin_Handled;
	
	decl String:sTimeleft[4];
	IntToString(iTimeleft / 60, sTimeleft, sizeof(sTimeleft));
	ExecConfig(TIMELEFT, sTimeleft);
	
	return Plugin_Handled;
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
	if(!GetConVarBool(g_hEnabled))
		return;
	
	new bool:bIncludeBots = GetConVarBool(g_hIncludeBots);
	new bool:bIncludeSpec = GetConVarBool(g_hIncludeSpec);
	if(bIncludeBots && bIncludeSpec)
		iClients += GetClientCount();
	else
	{
		for(new i = 1; i <= MaxClients; i++)
		{
			if(!IsClientInGame(i))
				continue;
			
			new bool:bBot  = bIncludeBots && IsFakeClient(i);
			new bool:bSpec = bIncludeSpec && IsClientObserver(i);
			if(bBot   || bSpec ||
				 (!bBot && !bSpec))
				iClients++;
		}
	}
	
	decl String:sClients[4];
	IntToString(iClients, sClients, sizeof(sClients));
	ExecConfig(CLIENTS, sClients);
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
	g_hTimers[iType] = CreateTimer(StringToFloat(sValues[0]), Timer_ExecConfig, hPack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
}

ParseConfig()
{
	decl String:sFile[256], String:sPath[256];
	GetConVarString(g_hFile, sFile, sizeof(sFile));
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/%s", sFile);

	if(!FileExists(sPath))
		SetFailState("File Not Found: %s", sPath);
	
	for(new i = 0; i < TOTAL; i++)
		ClearTrie(g_hTries[i]);
	
	new SMCError:iError = SMC_ParseFile(g_hConfigParser, sPath);
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