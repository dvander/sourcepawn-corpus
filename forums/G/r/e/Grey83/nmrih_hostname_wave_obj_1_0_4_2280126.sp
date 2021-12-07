#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION	"1.0.4"
#define PLUGIN_NAME		"[NMRiH] Hostname Waves & Objectives"
#define CHAT_PREFIX		"\x01[\x04HWO\x01] \x03"
#define LOG_PREFIX			"[HWO]"

new bool:bLateLoad = false;
new Handle:hHostname = INVALID_HANDLE, String:sOldHostname[63],
	Handle:hWaveEnable = INVALID_HANDLE, bool:bWaveEnable,
	Handle:hObjectiveEnable = INVALID_HANDLE, bool:bObjectiveEnable,
	Handle:hNoticeEnable = INVALID_HANDLE, bool:bNoticeEnable,
	Handle:hMaxWaveEnable = INVALID_HANDLE, bool:bMaxWaveEnable,
	Handle:hLogEnable = INVALID_HANDLE, bool:bLogEnable,
	Handle:hPrefixWaves = INVALID_HANDLE, String:sPrefixWaves[61],
	Handle:hPrefixObjectives = INVALID_HANDLE, String:sPrefixObjectives[61];

new hNumber,
	iMaxWave,
	bool:bSurvival = false,
	String:sNewHostname[63],
	String:sMap[32];

public Plugin:myinfo =
{
	name =		PLUGIN_NAME,
	author =		"Grey83",
	description =	"Shows the number of wave or objective in the hostname.",
	version =	PLUGIN_VERSION,
	url =		"https://forums.alliedmods.net/showthread.php?p=2280126"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	bLateLoad = late;
	return APLRes_Success; 
}

public OnPluginStart()
{
	AutoExecConfig(true, "nmrih_hostname_wave_obj");

	CreateConVar("nmrih_hostname_wave_obj_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	hWaveEnable = CreateConVar("sm_hostname_wave_enable", "1", "1/0 = On/Off Show number of wave in hostname", FCVAR_NONE, true, 0.0, true, 1.0);
	hObjectiveEnable = CreateConVar("sm_hostname_obj_enable", "1", "1/0 = On/Off Show number of objective in hostname", FCVAR_NONE, true, 0.0, true, 1.0);
	hNoticeEnable = CreateConVar("sm_hostname_notice_enable", "0", "1/0 = On/Off Show notices about number of objectives & waves in chat", FCVAR_NONE, true, 0.0, true, 1.0);
	hMaxWaveEnable = CreateConVar("sm_hostname_max_enable", "1", "1/0 = On/Off Show max number of waves", FCVAR_NONE, true, 0.0, true, 1.0);
	hLogEnable = CreateConVar("sm_hostname_log_enable", "0", "1/0 = On/Off Show notices about number of objectives & waves in server console", FCVAR_NONE, true, 0.0, true, 1.0);
	hPrefixWaves = CreateConVar("sm_prefix_waves", "|Wave:", "Prefix for waves in hostname.", FCVAR_PRINTABLEONLY);
	hPrefixObjectives = CreateConVar("sm_prefix_objectives", "|Obj.:", "Prefix for objectives in hostname.", FCVAR_PRINTABLEONLY);

	bMaxWaveEnable = GetConVarBool(hMaxWaveEnable);
	bObjectiveEnable = GetConVarBool(hObjectiveEnable);
	bNoticeEnable = GetConVarBool(hNoticeEnable);
	bWaveEnable = GetConVarBool(hWaveEnable);
	bLogEnable = GetConVarBool(hLogEnable);

	HookConVarChange(hWaveEnable, OnConVarChange);
	HookConVarChange(hObjectiveEnable, OnConVarChange);
	HookConVarChange(hNoticeEnable, OnConVarChange);
	HookConVarChange(hMaxWaveEnable, OnConVarChange);
	HookConVarChange(hLogEnable, OnConVarChange);
	HookConVarChange(hPrefixWaves, OnConVarChange);
	HookConVarChange(hPrefixObjectives, OnConVarChange);

	HookEvent("new_wave", Event_Next);
	HookEvent("objective_complete", Event_Next, EventHookMode_PostNoCopy);
	HookEvent("nmrih_round_begin", Event_New_Round, EventHookMode_PostNoCopy);
	HookEvent("player_leave", Event_Leave, EventHookMode_PostNoCopy);
	HookEvent("extraction_begin", Event_EB, EventHookMode_PostNoCopy);
	HookEvent("player_extracted", Event_PE);
	HookEvent("extraction_complete", Event_EC, EventHookMode_PostNoCopy);
	HookEvent("extraction_expire", Event_EE, EventHookMode_PostNoCopy);
	HookEvent("map_complete", Event_MC, EventHookMode_PostNoCopy);

	if (bLateLoad) OnMapStart();

	PrintToServer("%s v.%s has been successfully loaded!", PLUGIN_NAME, PLUGIN_VERSION);
}

public OnConfigsExecuted()
{

	hHostname = FindConVar("hostname");
	if(hHostname == INVALID_HANDLE)
		SetFailState("%s Unable to retrieve hostname.", LOG_PREFIX);

	GetConVarString(hHostname, sOldHostname, sizeof(sOldHostname));
	GetConVarString(hPrefixWaves, sPrefixWaves, sizeof(sPrefixWaves));
	GetConVarString(hPrefixObjectives, sPrefixObjectives, sizeof(sPrefixObjectives));
	new lenOH = strlen(sOldHostname);
	new lenPW = strlen(sPrefixWaves);
	new lenPO = strlen(sPrefixObjectives);
	PrintToServer("%s Old hostname: '%s'\nPrefix for waves: '%s'\nPrefix for objectives: '%s'", LOG_PREFIX, sOldHostname, sPrefixWaves, sPrefixObjectives);

	if ((lenOH + lenPW) > 61)
	{
		PrintToServer("%s Too long hostname (%d char.) or prefix for waves (%d char.)\nPlease remove %d character(s)", LOG_PREFIX, lenOH, lenPW, (lenOH + lenPW - 61));
	}
	if ((lenOH + lenPO) > 61)
	{
		PrintToServer("%s Too long hostname (%d char.) or prefix for objectives (%d char.)\nPlease remove %d character(s)", LOG_PREFIX, lenOH, lenPO, (lenOH + lenPO - 61));
	}
}

public OnPluginEnd()
{
	SetConVarString(hHostname, sOldHostname);
}

public OnConVarChange(Handle:hCvar, const String:oldValue[], const String:newValue[])
{
	if (hCvar == hWaveEnable) bWaveEnable = bool:StringToInt(newValue);
	else if (hCvar == hObjectiveEnable) bObjectiveEnable = bool:StringToInt(newValue);
	else if (hCvar == hNoticeEnable) bNoticeEnable = bool:StringToInt(newValue);
	else if (hCvar == hMaxWaveEnable) bMaxWaveEnable = bool:StringToInt(newValue);
	else if (hCvar == hLogEnable) bLogEnable = bool:StringToInt(newValue);
	else if (hCvar == hPrefixWaves) GetConVarString(hPrefixWaves, sPrefixWaves, sizeof(sPrefixWaves));
	else if (hCvar == hPrefixObjectives) GetConVarString(hPrefixObjectives, sPrefixObjectives, sizeof(sPrefixObjectives));
}

public OnMapStart()
{
	GetCurrentMap(sMap, sizeof(sMap));

	if (StrContains(sMap, "nms_") == 0)
	{
		bSurvival = true;
		if (bMaxWaveEnable) LoadMaxWaves();
	}
	else
	{
		bSurvival = false;
	}
	if(bLogEnable) PrintToServer("%s Survival: %b", LOG_PREFIX, bSurvival);
}

LoadMaxWaves()
{
	decl String:sMaxWave[3];
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, PLATFORM_MAX_PATH, "configs/waves.ini");

	new Handle:hKeyValue = CreateKeyValues("Waves");
	if (FileToKeyValues(hKeyValue, sPath))
	{
		KvGetString(hKeyValue, sMap, sMaxWave, sizeof(sMaxWave), "0");
		StringToIntEx(sMaxWave, iMaxWave);

		if (!iMaxWave) PrintToServer("%s Map '%s' have an unknown number of waves", LOG_PREFIX, sMap, iMaxWave);
		else PrintToServer("%s Map '%s' have %d waves", LOG_PREFIX, sMap, iMaxWave);
	} else
	{
		bMaxWaveEnable = false;
		PrintToServer("%s Could not locate: %s", PLUGIN_VERSION, sPath);
	}
	CloseHandle(hKeyValue);
}

public Event_Next(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bSurvival && bWaveEnable)
	{
		new bool:bResupply = GetEventBool(event, "resupply");
		if(!bResupply)
		{
			hNumber++;
			SetNewHostname();
			if(bLogEnable)
			{
				if (bMaxWaveEnable && iMaxWave > 1) PrintToServer("%s Wave: %d/%d", LOG_PREFIX, hNumber, iMaxWave);
				else PrintToServer("%s Wave: %d", LOG_PREFIX, hNumber);
			}
			if(bNoticeEnable)
			{
				if (bMaxWaveEnable && iMaxWave > 1) PrintToChatAll("%sWave: \x04%d\x01/\x04%d", CHAT_PREFIX, hNumber, iMaxWave);
				else PrintToChatAll("%sWave: \x04%d", CHAT_PREFIX, hNumber);
			}
		}
		else
		{
			PrintToServer("[HWO] Wave: %d (Resupply)", hNumber);
			if(bNoticeEnable)
			{
				if (bMaxWaveEnable && iMaxWave > 1) PrintToChatAll("%sWave: \x04%d\x01/\x04%d \x03(Resupply)", CHAT_PREFIX, hNumber, MaxWave);
				else PrintToChatAll("%sWave: \x04%d \x03(Resupply)", CHAT_PREFIX, hNumber);
			}
		}
	}
	else if(!bSurvival && bObjectiveEnable)
	{
		hNumber++;
		SetNewHostname();
		if(bLogEnable) PrintToServer("%s Objective: %d", LOG_PREFIX, hNumber);
		if(bNoticeEnable) PrintToChatAll("%sObjective: \x04%d", CHAT_PREFIX, hNumber);
	}
}

public Event_EB(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bLogEnable) PrintToServer("%s Extraction begin", LOG_PREFIX);
	if(bNoticeEnable) PrintToChatAll("%sExtraction begin", CHAT_PREFIX);
}

public Event_PE(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player_id");
	if(bLogEnable) PrintToServer("Player %N extracted", client);
	if(bNoticeEnable) PrintToChatAll("%sPlayer \x04%N \x03has been evacuated", CHAT_PREFIX, client);
}

public Event_EC(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bLogEnable) PrintToServer("%s Extraction complete", LOG_PREFIX);
	if(bNoticeEnable) PrintToChatAll("%sExtraction complete", CHAT_PREFIX);
}

public Event_EE(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bLogEnable) PrintToServer("%s Extraction expire", LOG_PREFIX);
	if(bNoticeEnable) PrintToChatAll("%sExtraction expire", CHAT_PREFIX);
}

public Event_MC(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bLogEnable) PrintToServer("%s Map complete", LOG_PREFIX);
	if(bNoticeEnable) PrintToChatAll("%sMap complete", CHAT_PREFIX);
}

public Event_Leave(Handle:event, const String:name[], bool:dontBroadcast)
{
	if((bObjectiveEnable || bWaveEnable) && GetClientCount() == 0) SetConVarString(hHostname, sOldHostname);
}

public Event_New_Round(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(bWaveEnable || bObjectiveEnable)
	{
		hNumber = 0;
		SetConVarString(hHostname, sOldHostname);
	}
	if(bLogEnable) PrintToServer("%s Round begin", LOG_PREFIX); 
}

public SetNewHostname() 
{
	decl String:prefix[61];
	prefix[0] = '\0';
	if(bSurvival)
	{
		strcopy(prefix, sizeof(prefix), sPrefixWaves);
	}
	else
	{
		strcopy(prefix, sizeof(prefix), sPrefixObjectives);
	}
	Format(sNewHostname, sizeof(sNewHostname), "%s%s%d", sOldHostname, prefix, hNumber); 
	SetConVarString(hHostname, sNewHostname); 
}