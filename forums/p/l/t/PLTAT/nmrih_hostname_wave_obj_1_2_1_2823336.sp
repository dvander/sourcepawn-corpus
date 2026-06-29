#pragma semicolon 1
#pragma newdecls required

#include <sdktools_functions>

static const char	PLUGIN_NAME[]	= "[NMRiH] Hostname Waves & Objectives",
					PLUGIN_VERSION[]= "1.2.1",

					CHAT_PREFIX[]	= "\x01[\x04HWO\x01] \x03",
					LOG_PREFIX[]	= ">	[HWO] ",

					DEF_HOSTNAME[]	= "服务器 ",
					DEF_WAVE_PREF[]	= "波次 : ",
					DEF_OBJ_PREF[]	= "任务 : ";

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
	(CVar = CreateConVar("sm_hwo_log", "1", "1/0 = On/Off Show notices about number of objectives & waves in the server console", _, true, 0.0, true, 1.0)).AddChangeHook(CVarChanged_Log);
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

	PrintToServer("%s v.%s 成功加载!", PLUGIN_NAME, PLUGIN_VERSION);
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
	SetHostname("控制台命令");
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
	PrintToServer("%s 主机名: '%s'\n	波次前缀: '%s'\n	任务前缀: '%s'", LOG_PREFIX, sHostname, sPrefixWaves, sPrefixObjectives);

	if((lenHN + lenWP) > 61) PrintToServer("%s主机名 太长 (%d 字符.) 或 波次前缀 (%d 字符.)\n请 移除 %d 字符", LOG_PREFIX, lenHN, lenWP, (lenHN + lenWP - 61));
	if((lenHN + lenOP) > 61) PrintToServer("%s主机名 太长 (%d 字符.) 或 任务前缀 (%d 字符.)\n请 移除 %d 字符", LOG_PREFIX, lenHN, lenOP, (lenHN + lenOP - 61));
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
	if(bLog) PrintToServer("%s游戏模式: %s", LOG_PREFIX, bSurvival ? "生存模式" : "任务模式");
	if(bSurvival)
	{
		if(GetMaxWave()) PrintToServer("%s地图 '%s' 有 %d 波", LOG_PREFIX, sMap, iMaxWave);
		else PrintToServer("%s地图 '%s' 未知 波次", LOG_PREFIX, sMap);
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

	if(bLog) PrintToServer("%s当前波次: %d", LOG_PREFIX, iNum);

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

	if((bSurvival && bWave) || (!bSurvival && bObjective)) SetHostname("继续");

	if(bSurvival && bMaxWave && iMaxWave > 1)
	{
		if(bLog) PrintToServer("%s波次: %d/%d%s", LOG_PREFIX, iNum, iMaxWave, bResupply ? " (补给)" : "");
		if(bNotice)
		{
			if(iNum == iMaxWave) PrintToChatAll("%s波次: \x04%d \x01(\x04最后一波\x01)", CHAT_PREFIX, iNum);
			else PrintToChatAll("%s波次: \x04%d\x01/\x04%d%s", CHAT_PREFIX, iNum, iMaxWave, bResupply ? " \x03(补给)" : "");
		}
	}
	else
	{
		if(bLog) PrintToServer("%s%s: %d%s", LOG_PREFIX, bSurvival ? "波次" : "任务", iNum, bResupply ? " (补给)" : "");
		if(bNotice) PrintToChatAll("%s%s: \x04%d%s", CHAT_PREFIX, bSurvival ? "波次" : "任务", iNum, bResupply ? " \x03(补给)" : "");
	}
}

public void Event_ExtractionBegin(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%s撤离 开始", LOG_PREFIX);
	if(bNotice) PrintToChatAll("%s撤离 开始", CHAT_PREFIX);
}

public void Event_PlayerExtracted(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("player_id");
	if(bLog) PrintToServer("%s玩家 %N 已撤离", LOG_PREFIX, client);
	if(bNotice) PrintToChatAll("%s玩家 \x04%N \x03已撤离", CHAT_PREFIX, client);
	iExtracted++;
}

public void Event_ExtractionComplete(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%s撤离 完成\n%i 玩家 完成 撤离", LOG_PREFIX, iExtracted);
	if(bNotice) PrintToChatAll("%s撤离 完成", CHAT_PREFIX);
}

public void Event_ExtractionExpire(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%s撤离 到期\n%i 玩家 完成 撤离", LOG_PREFIX, iExtracted);
	if(bNotice) PrintToChatAll("%s撤离 到期", CHAT_PREFIX);
}

public void Event_MapComplete(Event event, const char[] name, bool dontBroadcast)
{
	if(bLog) PrintToServer("%s地图 完成", LOG_PREFIX);
	if(bNotice) PrintToChatAll("%s地图 完成", CHAT_PREFIX);
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

	if(bLog) PrintToServer("%s状态 更改 为 %d\n	游戏模式: %s", LOG_PREFIX, iState, event.GetInt("game_type") != 0 ? "生存模式 (1)" : "任务模式 (0)");

	if(iState == 3 || iPreviousState == 3) SetHostname("状态更改");
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
	if(bLog) PrintToServer("%s主机名 更改 (%s)", LOG_PREFIX, reason);
}