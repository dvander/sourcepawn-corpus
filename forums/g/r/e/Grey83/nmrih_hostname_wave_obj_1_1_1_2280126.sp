#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

#define PLUGIN_VERSION	"1.1.1"
#define PLUGIN_NAME		"[NMRiH] Hostname Waves & Objectives"
#define CHAT_PREFIX		"\x01[\x04HWO\x01] \x03"
#define LOG_PREFIX			"[HWO] "

bool bLateLoad;
ConVar hHostname;
char sOldHostname[63];
ConVar hWave;
bool bWave;
ConVar hObjective;
bool bObjective;
ConVar hNotice;
bool bNotice;
ConVar hMaxWave;
bool bMaxWave;
ConVar hLog;
bool bLog;
ConVar hPrefixWaves;
char sPrefixWaves[61];
ConVar hPrefixObjectives;
char sPrefixObjectives[61];

int iNum;
int iExtracted;
int iMaxWave;
bool bSurvival;
char sNewHostname[63];
char sMap[32];

public Plugin myinfo =
{
	name		= PLUGIN_NAME,
	author		= "Grey83",
	description	= "Shows the number of wave or objective in the hostname.",
	version		= PLUGIN_VERSION,
	url			= "https://forums.alliedmods.net/showthread.php?p=2280126"
};

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	bLateLoad = late;
	return APLRes_Success; 
}

public void OnPluginStart()
{
	CreateConVar("nmrih_hostname_wave_obj_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hWave = CreateConVar("sm_hostname_wave_enable", "1", "1/0 = On/Off Show number of wave in hostname", FCVAR_NONE, true, 0.0, true, 1.0);
	hObjective = CreateConVar("sm_hostname_obj_enable", "1", "1/0 = On/Off Show number of objective in hostname", FCVAR_NONE, true, 0.0, true, 1.0);
	hNotice = CreateConVar("sm_hostname_notice_enable", "1", "1/0 = On/Off Show notices about number of objectives & waves in the chat", FCVAR_NONE, true, 0.0, true, 1.0);
	hMaxWave = CreateConVar("sm_hostname_max_enable", "1", "1/0 = On/Off Show max number of waves", FCVAR_NONE, true, 0.0, true, 1.0);
	hLog = CreateConVar("sm_hostname_log_enable", "0", "1/0 = On/Off Show notices about number of objectives & waves in the server console", FCVAR_NONE, true, 0.0, true, 1.0);
	hPrefixWaves = CreateConVar("sm_prefix_waves", "|Wave:", "Prefix for waves in hostname.", FCVAR_PRINTABLEONLY);
	hPrefixObjectives = CreateConVar("sm_prefix_objectives", "|Obj.:", "Prefix for objectives in hostname.", FCVAR_PRINTABLEONLY);
	hHostname = FindConVar("hostname");

	bMaxWave = GetConVarBool(hMaxWave);
	bObjective = GetConVarBool(hObjective);
	bNotice = GetConVarBool(hNotice);
	bWave = GetConVarBool(hWave);
	bLog = GetConVarBool(hLog);

	HookEvent("new_wave", Event_Next);
	HookEvent("objective_complete", Event_Next, EventHookMode_PostNoCopy);
	HookEvent("nmrih_round_begin", Event_New_Round, EventHookMode_PostNoCopy);
	HookEvent("extraction_begin", Event_EB, EventHookMode_PostNoCopy);
	HookEvent("player_extracted", Event_PE);
	HookEvent("extraction_complete", Event_EC, EventHookMode_PostNoCopy);
	HookEvent("extraction_expire", Event_EE, EventHookMode_PostNoCopy);
	HookEvent("map_complete", Event_MC, EventHookMode_PostNoCopy);

	AutoExecConfig(true, "nmrih_hostname_wave_obj");

	if(bLateLoad) OnMapStart();

	PrintToServer("%s v.%s has been successfully loaded!", PLUGIN_NAME, PLUGIN_VERSION);
}

public void OnConfigsExecuted()
{
	HookConVarChange(hWave, OnConVarChanged);
	HookConVarChange(hObjective, OnConVarChanged);
	HookConVarChange(hNotice, OnConVarChanged);
	HookConVarChange(hMaxWave, OnConVarChanged);
	HookConVarChange(hLog, OnConVarChanged);
	HookConVarChange(hPrefixWaves, OnConVarChanged);
	HookConVarChange(hPrefixObjectives, OnConVarChanged);

	hHostname.GetString(sOldHostname, sizeof(sOldHostname));
	int lenOH = strlen(sOldHostname);
	if(lenOH == 0) sOldHostname = "NMRiH";
	hPrefixWaves.GetString(sPrefixWaves, sizeof(sPrefixWaves));
	int lenPW = strlen(sPrefixWaves);
	if(lenPW == 0) sPrefixWaves = "|W:";
	hPrefixObjectives.GetString(sPrefixObjectives, sizeof(sPrefixObjectives));
	int lenPO = strlen(sPrefixObjectives);
	if(lenPO == 0) sPrefixObjectives = "|O:";
	PrintToServer("%s Old hostname: '%s'\nPrefix for waves: '%s'\nPrefix for objectives: '%s'", LOG_PREFIX, sOldHostname, sPrefixWaves, sPrefixObjectives);

	if((lenOH + lenPW) > 61) PrintToServer("%sToo long hostname (%d char.) or prefix for waves (%d char.)\nPlease remove %d character(s)", LOG_PREFIX, lenOH, lenPW, (lenOH + lenPW - 61));
	if((lenOH + lenPO) > 61) PrintToServer("%sToo long hostname (%d char.) or prefix for objectives (%d char.)\nPlease remove %d character(s)", LOG_PREFIX, lenOH, lenPO, (lenOH + lenPO - 61));
}

public void OnPluginEnd()
{
	SetConVarString(hHostname, sOldHostname);
}

public void OnConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if(convar == hWave)
	{
		bWave = view_as<bool>(StringToInt(newValue));
		if(bSurvival) SetHostname(!bWave);
	}
	else if(convar == hObjective)
	{
		bObjective = view_as<bool>(StringToInt(newValue));
		if(!bSurvival) SetHostname(!bObjective);
	}
	else if(convar == hNotice) bNotice = view_as<bool>(StringToInt(newValue));
	else if(convar == hMaxWave)
	{
		bMaxWave = view_as<bool>(StringToInt(newValue));
		if(bSurvival && bMaxWave) LoadMaxWaves();
	}
	else if(convar == hLog) bLog = view_as<bool>(StringToInt(newValue));
	else if(convar == hPrefixWaves)
	{
		GetConVarString(hPrefixWaves, sPrefixWaves, sizeof(sPrefixWaves));
		if(bSurvival && bWave) SetHostname();
	}
	else if(convar == hPrefixObjectives)
	{
		GetConVarString(hPrefixObjectives, sPrefixObjectives, sizeof(sPrefixObjectives));
		if(!bSurvival && bObjective) SetHostname();
	}
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof(sMap));

	bSurvival = (StrContains(sMap, "nms_") == 0);
	if(bSurvival && bMaxWave) LoadMaxWaves();

	if(bLog) PrintToServer("%sGame mode: %s", LOG_PREFIX, bSurvival ? "survival" : "objective");
}

void LoadMaxWaves()
{
	char sMaxWave[3];
	char sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/waves.ini");

	Handle hKeyValue = CreateKeyValues("Waves");
	if(FileToKeyValues(hKeyValue, sPath))
	{
		KvGetString(hKeyValue, sMap, sMaxWave, sizeof(sMaxWave), "0");
		StringToIntEx(sMaxWave, iMaxWave);

		if(iMaxWave > 0) PrintToServer("%sMap '%s' have %d waves", LOG_PREFIX, sMap, iMaxWave);
		else PrintToServer("%sMap '%s' have an unknown number of waves", LOG_PREFIX, sMap);
	}
	else
	{
		bMaxWave = false;
		PrintToServer("%s Could not locate: %s", PLUGIN_VERSION, sPath);
	}
	CloseHandle(hKeyValue);
}

public void Event_Next(Event event, const char[] name, bool dontBroadcast)
{
	bool bResupply;
	if(bSurvival) bResupply = event.GetBool("resupply");
	if(!bResupply) iNum++;

	if((bSurvival && bWave) || (!bSurvival && bObjective))
	{
		SetHostname();
		if(bLog)
		{
			if(bSurvival && bMaxWave && iMaxWave > 1) PrintToServer("%sWave: %d/%d%s", LOG_PREFIX, iNum, iMaxWave, bResupply ? " (Resupply)" : "");
			else PrintToServer("%s%s: %d%s", LOG_PREFIX, bSurvival ? "Wave" : "Objective", iNum, bResupply ? " (Resupply)" : "");
		}
		if(bNotice)
		{
			if(bSurvival && bMaxWave && iMaxWave > 1) PrintToChatAll("%sWave: \x04%d\x01/\x04%d%s", CHAT_PREFIX, iNum, iMaxWave, bResupply ? " \x03(Resupply)" : "");
			else PrintToChatAll("%s%s: \x04%d%s", CHAT_PREFIX, bSurvival ? "Wave" : "Objective", iNum, bResupply ? " \x03(Resupply)" : "");
		}
	}
}

public void Event_EB(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%sExtraction begin", LOG_PREFIX);
	if(bNotice) PrintToChatAll("%sExtraction begin", CHAT_PREFIX);
}

public void Event_PE(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetEventInt(event, "player_id");
	if(bLog) PrintToServer("Player %N extracted", client);
	if(bNotice) PrintToChatAll("%sPlayer \x04%N \x03has been evacuated", CHAT_PREFIX, client);
	iExtracted++;
}

public void Event_EC(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%sExtraction complete\n%i players was evacuated", LOG_PREFIX, iExtracted);
	if(bNotice) PrintToChatAll("%sExtraction complete", CHAT_PREFIX);
}

public void Event_EE(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%sExtraction expire\n%i players was evacuated", LOG_PREFIX, iExtracted);
	if(bNotice) PrintToChatAll("%sExtraction expire", CHAT_PREFIX);
}

public void Event_MC(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%sMap complete", LOG_PREFIX);
	if(bNotice) PrintToChatAll("%sMap complete", CHAT_PREFIX);
}

public void OnClientDisconnect_Post(int client)
{
	if((bObjective || bWave) && GetClientCount() == 0) SetHostname(true);
	if(bLog) PrintToServer("%sServer is empty", LOG_PREFIX); 
}

public void Event_New_Round(Event event, const char[] name, bool dontBroadcast)
{
	if(bWave || bObjective)
	{
		iNum = 0;
		SetHostname(true);
	}
	if(bLog) PrintToServer("%sRound begin", LOG_PREFIX);
	iExtracted = 0;
}

void SetHostname(bool reset = false) 
{
	if(!reset) Format(sNewHostname, sizeof(sNewHostname), "%s%s%d", sOldHostname, bSurvival ? sPrefixWaves : sPrefixObjectives, iNum); 
	SetConVarString(hHostname, reset ? sOldHostname : sNewHostname); 
}