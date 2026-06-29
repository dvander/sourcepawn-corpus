#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

#define CLIENTS		0
#define EVENT			1
#define ROUND			2
#define TIMELEFT	3
#define TOTAL			4

#define PL_VERSION "1.0.2"

public Plugin myinfo =
{
  name        = "Execute Configs",
  author      = "Tsunami",
  description = "Execute configs on certain events.",
  version     = PL_VERSION,
  url         = "http://www.tsunami-productions.nl"
};


/**
 * Globals
 */
int g_iRound;
bool g_bSection;
SMCParser g_hConfigParser;
ConVar g_hEnabled;
ConVar g_hIncludeBots;
ConVar g_hIncludeSpec;
Handle g_hTimer;
Handle g_hTimers[TOTAL];
StringMap g_hTries[TOTAL];
StringMap g_hTypes;
char g_sConfigFile[PLATFORM_MAX_PATH + 1];
char g_sMap[32];


/**
 * Forwards
 */
public void OnPluginStart()
{
	CreateConVar("sm_executeconfigs_version", PL_VERSION, "Execute configs on certain events.", FCVAR_NOTIFY);
	g_hEnabled      = CreateConVar("sm_executeconfigs_enabled",      "1", "Enable/disable executing configs");
	g_hIncludeBots  = CreateConVar("sm_executeconfigs_include_bots", "1", "Enable/disable including bots when counting number of clients");
	g_hIncludeSpec  = CreateConVar("sm_executeconfigs_include_spec", "1", "Enable/disable including spectators when counting number of clients");

	BuildPath(Path_SM, g_sConfigFile, sizeof(g_sConfigFile), "configs/executeconfigs.txt");
	RegServerCmd("sm_executeconfigs_reload", Command_Reload, "Reload the configs");

	g_hConfigParser = new SMCParser();
	g_hConfigParser.OnEnterSection = ReadConfig_NewSection;
	g_hConfigParser.OnKeyValue     = ReadConfig_KeyValue;
	g_hConfigParser.OnLeaveSection = ReadConfig_EndSection;

	g_hTypes        = new StringMap();
	g_hTypes.SetValue("clients",  CLIENTS);
	g_hTypes.SetValue("event",    EVENT);
	g_hTypes.SetValue("round",    ROUND);
	g_hTypes.SetValue("timeleft", TIMELEFT);

	for (int i = 0; i < TOTAL; i++)
		g_hTries[i] = new StringMap();

	char sGameDir[64];
	GetGameFolderName(sGameDir, sizeof(sGameDir));

	if (StrEqual(sGameDir, "insurgency"))
		HookEvent("game_newmap",            Event_GameStart,  EventHookMode_PostNoCopy);
	else
		HookEvent("game_start",             Event_GameStart,  EventHookMode_PostNoCopy);

	if (StrEqual(sGameDir, "dod"))
		HookEvent("dod_round_start",        Event_RoundStart, EventHookMode_PostNoCopy);
	else if (StrEqual(sGameDir, "tf"))
	{
		HookEvent("teamplay_restart_round", Event_GameStart,  EventHookMode_PostNoCopy);
		HookEvent("teamplay_round_start",   Event_RoundStart, EventHookMode_PostNoCopy);
	}
	else
		HookEvent("round_start",            Event_RoundStart, EventHookMode_PostNoCopy);
}

public void OnMapStart()
{
	g_iRound = 0;
	g_hTimer = null;

	for (int i = 0; i < TOTAL; i++)
		g_hTimers[i] = null;

	GetCurrentMap(g_sMap, sizeof(g_sMap));
	ParseConfig();
}

public void OnMapTimeLeftChanged()
{
	delete g_hTimer;

	int iTimeleft;
	if (GetMapTimeLeft(iTimeleft) && iTimeleft > 0)
		g_hTimer = CreateTimer(60.0, Timer_ExecTimeleftConfig, _, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
}

public void OnClientPutInServer(int client)
{
	ExecClientsConfig(0);
}

public void OnClientDisconnect(int client)
{
	ExecClientsConfig(-1);
}


/**
 * Commands
 */
public Action Command_Reload(int args)
{
	ParseConfig();
}


/**
 * Events
 */
public void Event_GameStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iRound = 0;
}

public void Event_Hook(Event event, const char[] name, bool dontBroadcast)
{
	if (g_hEnabled.BoolValue)
		ExecConfig(EVENT, name);
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iRound++;

	if (!g_hEnabled.BoolValue)
		return;

	char sRound[4];
	IntToString(g_iRound, sRound, sizeof(sRound));
	ExecConfig(ROUND, sRound);
}


/**
 * Timers
 */
public Action Timer_ExecConfig(Handle timer, DataPack pack)
{
	pack.Reset();

	char sConfig[32];
	int iType = pack.ReadCell();
	pack.ReadString(sConfig, sizeof(sConfig));

	ServerCommand("exec \"%s\"", sConfig);
	g_hTimers[iType] = null;
}

public Action Timer_ExecTimeleftConfig(Handle timer)
{
	if (!g_hEnabled.BoolValue)
		return Plugin_Handled;

	int iTimeleft;
	if (!GetMapTimeLeft(iTimeleft) || iTimeleft < 0)
		return Plugin_Handled;

	char sTimeleft[4];
	IntToString(iTimeleft / 60, sTimeleft, sizeof(sTimeleft));
	ExecConfig(TIMELEFT, sTimeleft);

	return Plugin_Handled;
}


/**
 * Config Parser
 */
public SMCResult ReadConfig_EndSection(SMCParser smc) {}

public SMCResult ReadConfig_KeyValue(SMCParser smc, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
	if (!g_bSection || !key[0])
		return SMCParse_Continue;

	int iType;
	char sKeys[2][32];
	ExplodeString(key, ":", sKeys, sizeof(sKeys), sizeof(sKeys[]));
	if (!g_hTypes.GetValue(sKeys[0], iType))
		return SMCParse_Continue;

	g_hTries[iType].SetString(sKeys[1], value);
	if (iType == EVENT)
		HookEvent(sKeys[1], Event_Hook);

	return SMCParse_Continue;
}

public SMCResult ReadConfig_NewSection(SMCParser smc, const char[] name, bool opt_quotes)
{
	g_bSection = StrEqual(name, "*") || strncmp(g_sMap, name, strlen(name), false) == 0;
}


/**
 * Stocks
 */
void ExecClientsConfig(int iClients)
{
	if (!g_hEnabled.BoolValue)
		return;

	bool bIncludeBots = g_hIncludeBots.BoolValue;
	bool bIncludeSpec = g_hIncludeSpec.BoolValue;
	if (bIncludeBots && bIncludeSpec)
		iClients += GetClientCount();
	else
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (!IsClientInGame(i))
				continue;

			bool bBot  = IsFakeClient(i);
			bool bSpec = IsClientObserver(i);
			if ((!bBot && !bSpec) ||
				(bIncludeBots && bBot) ||
				(bIncludeSpec && bSpec))
				iClients++;
		}
	}

	char sClients[4];
	IntToString(iClients, sClients, sizeof(sClients));
	ExecConfig(CLIENTS, sClients);
}

void ExecConfig(int iType, const char[] sKey)
{
	char sValue[64];
	if (!g_hTries[iType].GetString(sKey, sValue, sizeof(sValue)))
		return;

	char sValues[2][32];
	ExplodeString(sValue, ":", sValues, sizeof(sValues), sizeof(sValues[]));

	DataPack hPack = new DataPack();
	hPack.WriteCell(iType);
	hPack.WriteString(sValues[1]);
	g_hTimers[iType] = CreateTimer(StringToFloat(sValues[0]), Timer_ExecConfig, hPack, TIMER_DATA_HNDL_CLOSE|TIMER_FLAG_NO_MAPCHANGE);
}

void ParseConfig()
{
	if (!FileExists(g_sConfigFile))
		SetFailState("File Not Found: %s", g_sConfigFile);

	for (int i = 0; i < TOTAL; i++)
		g_hTries[i].Clear();

	SMCError iError = g_hConfigParser.ParseFile(g_sConfigFile);
	if (iError)
	{
		char sError[64];
		if (g_hConfigParser.GetErrorString(iError, sError, sizeof(sError)))
			LogError(sError);
		else
			LogError("Fatal parse error");
		return;
	}
}
