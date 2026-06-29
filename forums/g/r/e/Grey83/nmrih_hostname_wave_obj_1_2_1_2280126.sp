#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>

static const char	PLUGIN_NAME[]	= "[NMRiH] Hostname Waves & Objectives",
					PLUGIN_VERSION[]= "1.2.1",

					CHAT_PREFIX[]	= "\x01[\x04HWO\x01] \x03",
					LOG_PREFIX[]	= ">	[HWO] ",

					DEF_HOSTNAME[]	= "NMRiH",
					DEF_WAVE_PREF[]	= "|Wave:",
					DEF_OBJ_PREF[]	= "|Obj.:";

ConVar hHostname;
bool bWave,
	bObjective,
	bNotice,
	bMaxWave,
	bLog;
char sHostname[61],
	sPrefixWaves[61],
	sPrefixObjectives[61];

bool bLateLoad,
	bActive,
	bSurvival;
int iNum,
	iExtracted,
	iMaxWave,
	lenHN,
	lenWP,
	lenOP;
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
	if((hHostname = FindConVar("hostname")) == null) SetFailState("%sUnable to retrieve hostname.", LOG_PREFIX);

	CreateConVar("nmrih_hostname_wave_obj_version", PLUGIN_VERSION, PLUGIN_NAME, FCVAR_SPONLY|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	ConVar CVar;
	(CVar = CreateConVar("sm_hwo_wave", "1", "1/0 = On/Off Show number of wave in hostname", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Wave);
	bWave = CVar.BoolValue;
	(CVar = CreateConVar("sm_hwo_obj", "1", "1/0 = On/Off Show number of objective in hostname", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Objective);
	bObjective = CVar.BoolValue;
	(CVar = CreateConVar("sm_hwo_notice", "1", "1/0 = On/Off Show notices about number of objectives & waves in the chat", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Notice);
	bNotice = CVar.BoolValue;
	(CVar = CreateConVar("sm_hwo_max", "1", "1/0 = On/Off Show max number of waves", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_MaxWave);
	bMaxWave = CVar.BoolValue;
	(CVar = CreateConVar("sm_hwo_log", "0", "1/0 = On/Off Show notices about number of objectives & waves in the server console", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Log);
	bLog = CVar.BoolValue;
	(CVar = CreateConVar("sm_hwo_hostname", DEF_HOSTNAME, "Hostname without prefixes.", FCVAR_PRINTABLEONLY|FCVAR_DONTRECORD)).AddChangeHook(CVarChanged_Hostname);
	CVar.GetString(sHostname, sizeof(sHostname));
	(CVar = CreateConVar("sm_hwo_prefix_wav", DEF_WAVE_PREF, "Prefix for waves in hostname.", FCVAR_PRINTABLEONLY)).AddChangeHook(CVarChanged_PrefixWaves);
	CVar.GetString(sPrefixWaves, sizeof(sPrefixWaves));
	(CVar = CreateConVar("sm_hwo_prefix_obj", DEF_OBJ_PREF, "Prefix for objectives in hostname.", FCVAR_PRINTABLEONLY)).AddChangeHook(CVarChanged_PrefixObjectives);
	CVar.GetString(sPrefixObjectives, sizeof(sPrefixObjectives));

	HookEvent("new_wave", Event_Next);
	HookEvent("objective_complete", Event_Next);
	HookEvent("extraction_begin", Event_ExtractionBegin, EventHookMode_PostNoCopy);
	HookEvent("player_extracted", Event_PlayerExtracted);
	HookEvent("extraction_complete", Event_ExtractionComplete, EventHookMode_PostNoCopy);
	HookEvent("extraction_expire", Event_ExtractionExpire, EventHookMode_PostNoCopy);
	HookEvent("map_complete", Event_MapComplete, EventHookMode_PostNoCopy);
	HookEvent("state_change", Event_StateChange);

	AutoExecConfig(true, "nmrih_hwo");

	PrintToServer("%s v.%s has been successfully loaded!", PLUGIN_NAME, PLUGIN_VERSION);
}

public void OnPluginEnd()
{
	hHostname.SetString(sHostname);
}

public void CVarChanged_Wave(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bWave = CVar.BoolValue;
	if(bActive && bSurvival) SetHostname("CVar Wave");
}

public void CVarChanged_Objective(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bObjective = CVar.BoolValue;
	if(bActive && !bSurvival) SetHostname("CVar Obj");
}

public void CVarChanged_Notice(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bNotice = CVar.BoolValue;
}

public void CVarChanged_MaxWave(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bMaxWave = CVar.BoolValue;
}

public void CVarChanged_Log(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	bLog = CVar.BoolValue;
}

public void CVarChanged_Hostname(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	CVar.GetString(sHostname, sizeof(sHostname));
	if(!(lenHN = strlen(sHostname)))
	{
		strcopy(sHostname, 61, DEF_HOSTNAME);
		lenHN = strlen(sHostname);
	}
	CheckLenght();
	SetHostname("CVar HostName");
}

public void CVarChanged_PrefixWaves(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	CVar.GetString(sPrefixWaves, sizeof(sPrefixWaves));
	if(!(lenWP = strlen(sPrefixWaves)))
	{
		strcopy(sPrefixWaves, 61, DEF_WAVE_PREF);
		lenWP = strlen(sPrefixWaves);
	}
	CheckLenght();
	if(bActive && bWave && bSurvival) SetHostname("CVar WavePref");
}

void CheckLenght()
{
	PrintToServer("%s Hostname: '%s'\n	Prefix for waves: '%s'\n	Prefix for objectives: '%s'", LOG_PREFIX, sHostname, sPrefixWaves, sPrefixObjectives);

	if((lenHN + lenWP) > 61) PrintToServer("%sToo long hostname (%d char.) or prefix for waves (%d char.)\nPlease remove %d character(s)", LOG_PREFIX, lenHN, lenWP, (lenHN + lenWP - 61));
	if((lenHN + lenOP) > 61) PrintToServer("%sToo long hostname (%d char.) or prefix for objectives (%d char.)\nPlease remove %d character(s)", LOG_PREFIX, lenHN, lenOP, (lenHN + lenOP - 61));
}

public void CVarChanged_PrefixObjectives(ConVar CVar, const char[] oldValue, const char[] newValue)
{
	CVar.GetString(sPrefixObjectives, sizeof(sPrefixObjectives));
	if(!(lenOP = strlen(sPrefixObjectives)))
	{
		strcopy(sPrefixObjectives, 61, DEF_OBJ_PREF);
		lenOP = strlen(sPrefixWaves);
	}
	CheckLenght();
	if(bActive && bObjective && !bSurvival) SetHostname("CVar ObjPref");
}

public void OnMapStart()
{
	GetCurrentMap(sMap, sizeof(sMap));

	bSurvival = !StrContains(sMap, "nms_");
	if(bLog) PrintToServer("%sGame mode: %s", LOG_PREFIX, bSurvival ? "survival" : "objective");
	if(bSurvival)
	{
		if(GetMaxWave()) PrintToServer("%sMap '%s' have %d waves", LOG_PREFIX, sMap, iMaxWave);
		else PrintToServer("%sMap '%s' have an unknown number of waves", LOG_PREFIX, sMap);
		if(bLateLoad) GetCurrentWave();
	}

}

bool GetMaxWave()
{
	int ent;
	iMaxWave = 0;
	if((ent = FindEntityByClassname(-1, "overlord_wave_controller")) != -1 && HasEntProp(ent, Prop_Data, "m_iEndWave")) iMaxWave = GetEntProp(ent, Prop_Data, "m_iEndWave");
	else return false;

	return true;
}

void GetCurrentWave()
{
	bLateLoad = false;

	int ent;
	if((ent = FindEntityByClassname(-1, "wave_status")) != -1)
	{
		if(HasEntProp(ent, Prop_Send, "_waveNumber"))	iNum = GetEntProp(ent, Prop_Send, "_waveNumber");
		if(HasEntProp(ent, Prop_Send, "_isActive"))		bActive = GetEntProp(ent, Prop_Send, "_isActive") != 0;
	}

	if(bLog) PrintToServer("%sCurrent wave: %d", LOG_PREFIX, iNum);

	SetHostname("Late load");
}

public void Event_Next(Event event, const char[] name, bool dontBroadcast)
{
	bool bResupply;
	if(!bSurvival)
	{
		static int ObjID;
		if(ObjID == (ObjID = event.GetInt("id"))) return;
		iNum++;
	}
	else if(!(bResupply = event.GetBool("resupply"))) iNum++;

	if((bSurvival && bWave) || (!bSurvival && bObjective)) SetHostname("Next");

	if(bSurvival && bMaxWave && iMaxWave > 1)
	{
		if(bLog) PrintToServer("%sWave: %d/%d%s", LOG_PREFIX, iNum, iMaxWave, bResupply ? " (Resupply)" : "");
		if(bNotice)
		{
			if(iNum == iMaxWave) PrintToChatAll("%sWave: \x04%d \x01(\x04final\x01)", CHAT_PREFIX, iNum);
			else PrintToChatAll("%sWave: \x04%d\x01/\x04%d%s", CHAT_PREFIX, iNum, iMaxWave, bResupply ? " \x03(Resupply)" : "");
		}
	}
	else
	{
		if(bLog) PrintToServer("%s%s: %d%s", LOG_PREFIX, bSurvival ? "Wave" : "Objective", iNum, bResupply ? " (Resupply)" : "");
		if(bNotice) PrintToChatAll("%s%s: \x04%d%s", CHAT_PREFIX, bSurvival ? "Wave" : "Objective", iNum, bResupply ? " \x03(Resupply)" : "");
	}
}

public void Event_ExtractionBegin(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%sExtraction begin", LOG_PREFIX);
	if(bNotice) PrintToChatAll("%sExtraction begin", CHAT_PREFIX);
}

public void Event_PlayerExtracted(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("player_id");
	if(bLog) PrintToServer("%sPlayer %N extracted", LOG_PREFIX, client);
	if(bNotice) PrintToChatAll("%sPlayer \x04%N \x03has been evacuated", CHAT_PREFIX, client);
	iExtracted++;
}

public void Event_ExtractionComplete(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%sExtraction complete\n%i players was evacuated", LOG_PREFIX, iExtracted);
	if(bNotice) PrintToChatAll("%sExtraction complete", CHAT_PREFIX);
}

public void Event_ExtractionExpire(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%sExtraction expire\n%i players was evacuated", LOG_PREFIX, iExtracted);
	if(bNotice) PrintToChatAll("%sExtraction expire", CHAT_PREFIX);
}

public void Event_MapComplete(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%sMap complete", LOG_PREFIX);
	if(bNotice) PrintToChatAll("%sMap complete", CHAT_PREFIX);
}

public void Event_StateChange(Event event, const char[] name, bool dontBroadcast)
{
	static int iState, iPreviousState;
	bActive = ((iState = event.GetInt("state")) == 3);
	if(bActive)
	{
		iNum = bSurvival ? 0 : 1;
		iExtracted = 0;
	}

	if(bLog) PrintToServer("%sState changed to %d\n	Game type: %s", LOG_PREFIX, iState, event.GetInt("game_type") != 0 ? "survival (1)" : "objective (0)");

	if(iState == 3 || iPreviousState == 3) SetHostname("StateChange");
	iPreviousState = iState;
}

void SetHostname(char[] reason = "") 
{
	static char sBuffer[63];
	Format(sBuffer, sizeof(sBuffer), "%s", sHostname);

	if(bActive)
	{
		if(bSurvival)
		{
			if(bWave && iNum) Format(sBuffer, sizeof(sBuffer), "%s%s%d", sBuffer, sPrefixWaves, iNum);
		}
		else if(bObjective) Format(sBuffer, sizeof(sBuffer), "%s%s%d", sBuffer, sPrefixObjectives, iNum);
	}

	hHostname.SetString(sBuffer);
	if(bLog) PrintToServer("%sHostName changed (%s)", LOG_PREFIX, reason);
}