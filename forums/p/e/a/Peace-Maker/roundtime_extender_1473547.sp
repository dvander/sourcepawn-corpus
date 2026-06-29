#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.0.1"

#define CONFIG_MAXPLAYERS 0
#define CONFIG_EXTENDSECONDS 1

new Handle:g_hRoundTime;
new Handle:g_hFreezeTime;

new Handle:g_hRoundTimerHandle = INVALID_HANDLE;

// Config parser stuff
new Handle:g_hConfig = INVALID_HANDLE;

enum ConfigSection
{
	State_None = 0,
	State_Root,
	State_Config
}

new ConfigSection:g_ConfigSection = State_None;
new g_iCurrentConfigIndex = -1;

public Plugin:myinfo = 
{
	name = "Roundtime Extender",
	author = "Jannik 'Peace-Maker' Hartung",
	description = "Highers the roundtime depending on players alive on round end.",
	version = PLUGIN_VERSION,
	url = "http://www.wcfan.de/"
}

public OnPluginStart()
{
	new Handle:hVersion = CreateConVar("sm_roundtimeextender_version", PLUGIN_VERSION, "Roundtime Extender version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(hVersion, PLUGIN_VERSION);
	
	g_hConfig = CreateArray();
	
	// Hook roundtime convars
	g_hFreezeTime = FindConVar("mp_freezetime");
	if(g_hFreezeTime == INVALID_HANDLE)
		SetFailState("Can't find mp_freezetime convar.");
	
	g_hRoundTime = FindConVar("mp_roundtime");
	if(g_hRoundTime == INVALID_HANDLE)
		SetFailState("Can't find mp_roundtime convar.");
	
	// Hook events
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("bomb_planted", Event_OnBombPlanted);
}

public OnMapStart()
{
	// Load us up. We're fully depending on that config file!
	ReadConfig();
}

// Make sure to set g_hRoundTimerHandle to INVALID_HANDLE on map change
public OnMapEnd()
{
	if(g_hRoundTimerHandle != INVALID_HANDLE)
	{
		KillTimer(g_hRoundTimerHandle);
		g_hRoundTimerHandle = INVALID_HANDLE;
	}
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Don't have 2 timers running at the same time anytime!
	if(g_hRoundTimerHandle != INVALID_HANDLE)
	{
		KillTimer(g_hRoundTimerHandle);
		g_hRoundTimerHandle = INVALID_HANDLE;
	}
	
	// Have a timer until _1/2_ second before round end
	new Float:fRoundTime = (GetConVarFloat(g_hRoundTime)*60.0 + GetConVarFloat(g_hFreezeTime) - 0.5);
	g_hRoundTimerHandle = CreateTimer(fRoundTime, Timer_OnBeforeRoundEnd, _, TIMER_FLAG_NO_MAPCHANGE);
}

// The round ended. No need for further actions.
public Action:Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_hRoundTimerHandle != INVALID_HANDLE)
	{
		KillTimer(g_hRoundTimerHandle);
		g_hRoundTimerHandle = INVALID_HANDLE;
	}
}

// The bomb has been planted. The roundtimer is ignored from here.
public Action:Event_OnBombPlanted(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(g_hRoundTimerHandle != INVALID_HANDLE)
	{
		KillTimer(g_hRoundTimerHandle);
		g_hRoundTimerHandle = INVALID_HANDLE;
	}
}

public Action:Timer_OnBeforeRoundEnd(Handle:timer, any:data)
{
	g_hRoundTimerHandle = INVALID_HANDLE;
	
	// Get the currently alive players
	new iAlivePlayersCount = 0;
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i) && IsPlayerAlive(i))
			iAlivePlayersCount++;
	}
	
	// Stop here, if there are no alive players left ?!
	if(iAlivePlayersCount == 0)
		return Plugin_Stop;
	
	// Determine which config part is used regarding the current player count
	new iSize = GetArraySize(g_hConfig);
	new Handle:hConfig, iMaxPlayers, iExtendSeconds = 0;
	for(new i=0;i<iSize;i++)
	{
		hConfig = GetArrayCell(g_hConfig, i);
		iMaxPlayers = GetArrayCell(hConfig, CONFIG_MAXPLAYERS);
		if(iAlivePlayersCount <= iMaxPlayers)
		{
			iExtendSeconds = GetArrayCell(hConfig, CONFIG_EXTENDSECONDS);
			break;
		}
	}
	
	// Don't care if there's no config for this player amount
	if(iExtendSeconds == 0)
		return Plugin_Stop;
	
	// Get the current roundtime
	new iCurrentRoundTime = GameRules_GetProp("m_iRoundTime");
	
	// Increase the roundtime by the seconds specified in the config	
	GameRules_SetProp("m_iRoundTime", iCurrentRoundTime+iExtendSeconds, 4, 0, true);
	
	//PrintToServer("Roundtime Extender: Increased m_iRoundTime from %d by %d. New roundtime: %d.", iCurrentRoundTime, iExtendSeconds, iCurrentRoundTime+iExtendSeconds);
	
	return Plugin_Stop;
}

ReadConfig()
{
	decl String:sConfigFile[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sConfigFile, sizeof(sConfigFile), "configs/roundtime_extender.cfg");
	
	if(!FileExists(sConfigFile))
		SetFailState("FATAL ERROR: roundtime_extender.cfg doesn't exist!");
	
	// Close old arrays
	new iSize = GetArraySize(g_hConfig);
	new Handle:hConfig;
	for(new i=0;i<iSize;i++)
	{
		hConfig = GetArrayCell(g_hConfig, i);
		CloseHandle(hConfig);
	}
	ClearArray(g_hConfig);
	
	g_ConfigSection = State_None;
	g_iCurrentConfigIndex = -1;
	
	new Handle:hSMC = SMC_CreateParser();
	SMC_SetReaders(hSMC, Config_OnNewSection, Config_OnKeyValue, Config_OnEndSection);
	SMC_SetParseEnd(hSMC, Config_OnParseEnd);
	
	new iLine, iColumn;
	new SMCError:smcResult = SMC_ParseFile(hSMC, sConfigFile, iLine, iColumn);
	CloseHandle(hSMC);
	
	if(smcResult != SMCError_Okay)
	{
		decl String:sError[128];
		SMC_GetErrorString(smcResult, sError, sizeof(sError));
		LogError("Error parsing config: %s on line %d, col %d of %s", sError, iLine, iColumn, sConfigFile);
		
		// Clear the halfway parsed config
		iSize = GetArraySize(g_hConfig);
		for(new i=0;i<iSize;i++)
		{
			hConfig = GetArrayCell(g_hConfig, i);
			CloseHandle(hConfig);
		}
		ClearArray(g_hConfig);
		
		SetFailState("Error parsing config file.");
	}
}

public SMCResult:Config_OnNewSection(Handle:parser, const String:section[], bool:quotes)
{
	switch(g_ConfigSection)
	{
		// New roundtime settings
		case State_Root:
		{
			new Handle:hConfig = CreateArray();
			
			ResizeArray(hConfig, 2);
			
			g_iCurrentConfigIndex = PushArrayCell(g_hConfig, hConfig);
			g_ConfigSection = State_Config;
		}
		case State_None:
		{
			g_ConfigSection = State_Root;
		}
	}
	return SMCParse_Continue;
}

public SMCResult:Config_OnKeyValue(Handle:smc, const String:key[], const String:value[], bool:key_quotes, bool:value_quotes)
{
	if(!key[0])
		return SMCParse_Continue;
	
	new Handle:hConfig = GetArrayCell(g_hConfig, g_iCurrentConfigIndex);
	
	if(g_ConfigSection == State_Config)
	{
		if(StrEqual(key, "maxplayers", false))
		{
			new iValue = StringToInt(value);
			
			if(iValue <= 0 || iValue > MAXPLAYERS)
				return SMCParse_HaltFail;
			
			SetArrayCell(hConfig, CONFIG_MAXPLAYERS, iValue);
		}
		else if(StrEqual(key, "extendseconds", false))
		{
			new iValue = StringToInt(value);
			
			if(iValue < 0)
				return SMCParse_HaltFail;
			
			SetArrayCell(hConfig, CONFIG_EXTENDSECONDS, iValue);
		}
	}
	
	return SMCParse_Continue;
}

public SMCResult:Config_OnEndSection(Handle:parser)
{
	// Finished parsing that config part
	if(g_ConfigSection == State_Config)
	{
		g_iCurrentConfigIndex = -1;
		g_ConfigSection = State_Root;
	}
	
	return SMCParse_Continue;
}

public Config_OnParseEnd(Handle:parser, bool:halted, bool:failed) {
	// We error later already
	//if (failed)
	//	SetFailState("Error during parse of the config.");
}