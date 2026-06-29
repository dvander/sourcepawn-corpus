// Just for my coding style :O)

#pragma semicolon 1

// Includes

#include <adt>
#include <sdktools>
#include <sourcemod>
#include <regex>

#undef REQUIRE_EXTENSIONS

	#include <cstrike>

#define REQUIRE_EXTENSIONS

// Definitions

#define SCJ_VERSION "1.0.0"

// Handles

new Handle:h_ScjEnabledBool;
new Handle:h_ScjCronjobs = INVALID_HANDLE;
new Handle:h_ScjRegex;
new Handle:h_ScjDataPack;
new Handle:h_ScjValueArray;
new Handle:h_ScjTaskArray;
new Handle:h_ScjOriginalValueArray;
new Handle:h_ScjFindConVarEnabled;

// Strings

new String:s_ScjLogFile[PLATFORM_MAX_PATH];
new String:s_ScjCronjobsFile[PLATFORM_MAX_PATH];
new String:s_ScjCronjobsType[PLATFORM_MAX_PATH];
new String:s_ScjCronjobsTask[PLATFORM_MAX_PATH];
new String:s_ScjCronjobsSection[PLATFORM_MAX_PATH];
new String:s_ScjCurrentHour[PLATFORM_MAX_PATH];
new String:s_ScjCurrentTime[PLATFORM_MAX_PATH];
new String:s_ScjCurrentMinute[PLATFORM_MAX_PATH];
new String:s_ScjCronjobsTimeValue[PLATFORM_MAX_PATH];
new String:s_ScjCronjobsHour[PLATFORM_MAX_PATH];
new String:s_ScjCronjobsMinute[PLATFORM_MAX_PATH];

// Integers

new v_ScjCronjobsSection = 0;
new v_ScjTotalScore = 0;
new v_ScjCurrentTimestamp = 0;
new v_ScjCurrentHour = 0;
new v_ScjCurrentMinute = 0;
new v_ScjCronjobsHour = 0;
new v_ScjCronjobsMinute = 0;
new v_ScjTimeDifference = 0;
new v_ScjHourDifference = 0;
new v_ScjMinuteDifference = 0;
new v_ScjNewTimestamp = 0;
new v_ScjRoundValue = 0;
new v_ScjIndexFound = 0;
new v_ScjNewRoundValue = 0;
new v_ScjPlayedRounds = 0;
new v_ScjFuncTimeDifference = 0;

// Floats

new Float:v_ScjCronjobsPeriodValue = 0.0;

// Boolean

new bool:b_ScjParseLock = true;

// Errrrm ... Just information stuff

public Plugin:myinfo =
{
	name = "Source Cronjobs",
	author = "Daniel 'Keyschpert' Kuespert",
	description = "Executes commands, files, etc. at a specific moments",
	version = SCJ_VERSION,
	url = "http://www.srcds.net"
};

public OnPluginStart() 
{	
	
	CreateConVar("scj_version", SCJ_VERSION, "Current version of SCJ", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY | FCVAR_DONTRECORD);
	h_ScjEnabledBool = CreateConVar("scj_enabled", "1", "If true SCJ will be working", FCVAR_PLUGIN | FCVAR_SPONLY | FCVAR_REPLICATED | FCVAR_NOTIFY);
	
	if (h_ScjEnabledBool != INVALID_HANDLE)
	{
		h_ScjFindConVarEnabled = FindConVar("scj_enabled");
		
		if (h_ScjFindConVarEnabled != INVALID_HANDLE)
		{
			HookConVarChange(h_ScjFindConVarEnabled, OnScjEnabledChange);	
		}
	}
	
	AutoExecConfig(true, "sourcecronjobs", "sourcemod");
	
	if (!GetConVarBool(h_ScjEnabledBool))
	{
		SetFailState("Unloaded Source Cronjobs");
	}
	else
	{		
		BuildPath(Path_SM, s_ScjLogFile, sizeof(s_ScjLogFile), "logs/sourcecronjobs.log");
		BuildPath(Path_SM, s_ScjCronjobsFile, sizeof(s_ScjCronjobsFile), "configs/sourcecronjobs.txt");
		
		HookEvent("round_start", Event_RoundStart, EventHookMode_PostNoCopy);
		
		h_ScjRegex = CompileRegex("([0-1][0-9]|[2][0-3]):([0-5][0-9])");
		h_ScjValueArray = CreateArray(1, 0);
		h_ScjTaskArray = CreateArray(PLATFORM_MAX_PATH, 0);
		h_ScjOriginalValueArray = CreateArray(1, 0);

		if (b_ScjParseLock != true)
		{
			ParseCronjobs();	
		}
	}
}

public OnPluginEnd()
{
	SetConVarBool(h_ScjFindConVarEnabled, true, false, false);
	b_ScjParseLock = true;
}

public OnMapStart()
{
	if (b_ScjParseLock == true)
	{
		ParseCronjobs();
		
		b_ScjParseLock = false;	
	}	
}

public OnScjEnabledChange(Handle:h_ScjEnabled, const String:s_ScjOldValue[], const String:s_ScjNewValue[])
{
	if (StringToInt(s_ScjNewValue) == 0)
	{
		SetFailState("Unloaded Source Cronjobs");
	}
}

public OnConfigsExecuted()
{	
	LogToFile(s_ScjLogFile, "Source Cronjobs configuration file was executed!");
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	v_ScjIndexFound = FindValueInArray(h_ScjValueArray, GetPlayedRounds());

	if (v_ScjIndexFound != -1)
	{
		GetArrayString(h_ScjTaskArray, v_ScjIndexFound, s_ScjCronjobsTask, sizeof(s_ScjCronjobsTask));
		
		if (strlen(s_ScjCronjobsTask) != 0)
		{
			ServerCommand("%s", s_ScjCronjobsTask);
			
			LogToFile(s_ScjLogFile, "The following task was successfully executed: '%s'", s_ScjCronjobsTask);

			v_ScjNewRoundValue = v_ScjTotalScore + GetArrayCell(h_ScjOriginalValueArray, v_ScjIndexFound, 0, false);
				
			SetArrayCell(h_ScjValueArray, v_ScjIndexFound, v_ScjNewRoundValue, 0, false);
		}
		else
		{
			LogToFile(s_ScjLogFile, "There is no task to be executed!");
		}		
	}
}

ParseCronjobs()
{
	h_ScjCronjobs = CreateKeyValues("Source Cronjobs");
	
	if (FileExists(s_ScjCronjobsFile))
	{
		FileToKeyValues(h_ScjCronjobs, s_ScjCronjobsFile);
		
		if (KvGotoFirstSubKey(h_ScjCronjobs))
		{
			LoopThroughCronjobs();
		}
		else
		{
			SetFailState("Found no cronjobs! Going to unload plugin (No need for it)!");		
		}
	} 
	else 
	{
		SetFailState("Fatal Error! Cannot find cronjob's file! Unloading plugin!");
	}
}

LoopThroughCronjobs()
{
	do
	{
		KvGetString(h_ScjCronjobs, "type", s_ScjCronjobsType, sizeof(s_ScjCronjobsType));
		
		if (StrEqual(s_ScjCronjobsType, "round", true))
		{
			v_ScjRoundValue = KvGetNum(h_ScjCronjobs, "value", 0);

			KvGetString(h_ScjCronjobs, "task", s_ScjCronjobsTask, sizeof(s_ScjCronjobsTask), "");
			
			v_ScjPlayedRounds = GetPlayedRounds();
			
			if (v_ScjPlayedRounds > v_ScjRoundValue)
			{
				v_ScjNewRoundValue = v_ScjPlayedRounds + v_ScjRoundValue;

				PushArrayCell(h_ScjValueArray, v_ScjNewRoundValue);
				PushArrayCell(h_ScjOriginalValueArray, v_ScjRoundValue);
			}
			else if (v_ScjPlayedRounds == v_ScjRoundValue)
			{
				if (strlen(s_ScjCronjobsTask) != 0)
				{
					ServerCommand("%s", s_ScjCronjobsTask);
			
					LogToFile(s_ScjLogFile, "The following task was successfully executed: '%s'", s_ScjCronjobsTask);
				}
				else
				{
					LogToFile(s_ScjLogFile, "There is no task to be executed!");
				}
				
				v_ScjNewRoundValue = v_ScjPlayedRounds + v_ScjRoundValue;

				PushArrayCell(h_ScjValueArray, v_ScjNewRoundValue);
				PushArrayCell(h_ScjOriginalValueArray, v_ScjRoundValue);
			}
			else
			{
				PushArrayCell(h_ScjValueArray, v_ScjRoundValue);
				PushArrayCell(h_ScjOriginalValueArray, v_ScjRoundValue);
			}
			
			PushArrayString(h_ScjTaskArray, s_ScjCronjobsTask);	
		}		
		else if (StrEqual(s_ScjCronjobsType, "period", true))
		{
			KvGetString(h_ScjCronjobs, "task", s_ScjCronjobsTask, sizeof(s_ScjCronjobsTask), "");
			
			v_ScjCronjobsPeriodValue = KvGetFloat(h_ScjCronjobs, "value", 0.0);
			
			CreateDataTimer(v_ScjCronjobsPeriodValue, ExecutePeriodTimerTask, h_ScjDataPack, TIMER_REPEAT);
			
			WritePackCell(h_ScjDataPack, v_ScjCronjobsSection);
			WritePackString(h_ScjDataPack, s_ScjCronjobsTask);
		}
		else if (StrEqual(s_ScjCronjobsType, "time", true))
		{
			KvGetString(h_ScjCronjobs, "task", s_ScjCronjobsTask, sizeof(s_ScjCronjobsTask), "");
			KvGetString(h_ScjCronjobs, "value", s_ScjCronjobsTimeValue, sizeof(s_ScjCronjobsTimeValue), "");
			
			v_ScjTimeDifference = CalculateTimeDifference(s_ScjCronjobsTimeValue);
																	
			CreateDataTimer(float(v_ScjTimeDifference), ExecuteTimeTimerTask, h_ScjDataPack, TIMER_HNDL_CLOSE);
			
			WritePackCell(h_ScjDataPack, v_ScjCronjobsSection);
			WritePackString(h_ScjDataPack, s_ScjCronjobsTask);
		}
		else
		{
			KvGetSectionName(h_ScjCronjobs, s_ScjCronjobsSection, sizeof(s_ScjCronjobsSection));
			
			LogToFile(s_ScjLogFile, "Error ! No valid type at section '%s'", s_ScjCronjobsSection);
		}
	}
	while (KvGotoNextKey(h_ScjCronjobs, true));
		
	LogToFile(s_ScjLogFile, "Source Cronjobs cronjob file parsed successfully!");
}

CalculateTimeDifference(String:s_ScjCronjobsFuncTimeValue[PLATFORM_MAX_PATH])
{
	v_ScjCurrentTimestamp = GetTime();
			
	FormatTime(s_ScjCurrentTime, sizeof(s_ScjCurrentTime), "%H:%M", v_ScjCurrentTimestamp);
		
	MatchRegex(h_ScjRegex, s_ScjCurrentTime);
	GetRegexSubString(h_ScjRegex, 1, s_ScjCurrentHour, sizeof(s_ScjCurrentHour));
	GetRegexSubString(h_ScjRegex, 2, s_ScjCurrentMinute, sizeof(s_ScjCurrentMinute));
	
	MatchRegex(h_ScjRegex, s_ScjCronjobsFuncTimeValue);
	GetRegexSubString(h_ScjRegex, 1, s_ScjCronjobsHour, sizeof(s_ScjCronjobsHour));
	GetRegexSubString(h_ScjRegex, 2, s_ScjCronjobsMinute, sizeof(s_ScjCronjobsMinute));
	
	v_ScjCurrentHour = StringToInt(s_ScjCurrentHour, 10);
	v_ScjCurrentMinute = StringToInt(s_ScjCurrentMinute, 10);
	v_ScjCronjobsHour = StringToInt(s_ScjCronjobsHour, 10);
	v_ScjCronjobsMinute = StringToInt(s_ScjCronjobsMinute, 10);
	
	if (v_ScjCronjobsHour == v_ScjCurrentHour && v_ScjCronjobsMinute < v_ScjCurrentMinute || v_ScjCronjobsHour < v_ScjCurrentHour)
	{
		if (v_ScjCronjobsHour == 0 && v_ScjCronjobsMinute == 0)
		{
			v_ScjHourDifference = 23 - v_ScjCurrentHour;
			v_ScjMinuteDifference = 59 - v_ScjCurrentMinute;		
		}
		else
		{
			v_ScjHourDifference = (23 - v_ScjCurrentHour) + v_ScjCronjobsHour;
			v_ScjMinuteDifference = (59 - v_ScjCurrentMinute) + v_ScjCronjobsMinute;	
		}
	}
	else if (v_ScjCronjobsHour == v_ScjCurrentHour && v_ScjCronjobsMinute == v_ScjCurrentMinute)
	{			
		if (strlen(s_ScjCronjobsTask) != 0)
		{
			ServerCommand("%s", s_ScjCronjobsTask);
			
			LogToFile(s_ScjLogFile, "The following task was successfully executed: '%s'", s_ScjCronjobsTask);
		}
		else
		{
			LogToFile(s_ScjLogFile, "There is no task to be executed!");
		}
	}
	else if (v_ScjCronjobsHour == v_ScjCurrentHour && v_ScjCronjobsMinute > v_ScjCurrentMinute || v_ScjCronjobsHour > v_ScjCurrentHour && v_ScjCronjobsHour <= 23)
	{				
		v_ScjHourDifference = v_ScjCronjobsHour - v_ScjCurrentHour;
		v_ScjMinuteDifference = v_ScjCronjobsMinute - v_ScjCurrentMinute;		
	}
	else
	{
		LogToFile(s_ScjLogFile, "No valid format of the daytime. Only 24 hour style!");	
	}
		
	v_ScjNewTimestamp = (v_ScjHourDifference * 3600) + (v_ScjMinuteDifference * 60) + v_ScjCurrentTimestamp;	
	v_ScjFuncTimeDifference = v_ScjNewTimestamp - v_ScjCurrentTimestamp;
	
	return v_ScjFuncTimeDifference;
}

ReinitializeTimeTimer(v_ScjCronjobsFuncSection)
{
	KvJumpToKeySymbol(h_ScjCronjobs, v_ScjCronjobsFuncSection);
	KvGetString(h_ScjCronjobs, "value", s_ScjCronjobsTimeValue, sizeof(s_ScjCronjobsTimeValue), "");
		
	CalculateTimeDifference(s_ScjCronjobsTimeValue);
	
	CreateDataTimer(float(v_ScjTimeDifference), ExecuteTimeTimerTask, h_ScjDataPack, TIMER_HNDL_CLOSE);
		
	WritePackCell(h_ScjDataPack, v_ScjCronjobsSection);
	WritePackString(h_ScjDataPack, s_ScjCronjobsTask);
}

GetPlayedRounds()
{
	v_ScjTotalScore = GetTeamScore(CS_TEAM_T) + GetTeamScore(CS_TEAM_CT);
	
	return v_ScjTotalScore;	
}

public Action:ExecutePeriodTimerTask(Handle:timer, Handle:h_ScjPeriodDataPack)
{	
	ResetPack(h_ScjPeriodDataPack, false);
	
	v_ScjCronjobsSection = ReadPackCell(h_ScjPeriodDataPack);
	
	ReadPackString(h_ScjPeriodDataPack, s_ScjCronjobsTask, sizeof(s_ScjCronjobsTask));
	
	if (strlen(s_ScjCronjobsTask) != 0)
	{
		ServerCommand("%s", s_ScjCronjobsTask);
		
		LogToFile(s_ScjLogFile, "The following task was successfully executed: '%s'", s_ScjCronjobsTask);
	}
	else
	{
		LogToFile(s_ScjLogFile, "There is no task to be executed! Killing Cronjob!");
		
		return Plugin_Stop;
	}
		
	return Plugin_Continue;
}

public Action:ExecuteTimeTimerTask(Handle:timer, Handle:h_ScjTimeDataPack)
{	
	ResetPack(h_ScjTimeDataPack, false);
	
	v_ScjCronjobsSection = ReadPackCell(h_ScjTimeDataPack);
	
	ReadPackString(h_ScjTimeDataPack, s_ScjCronjobsTask, sizeof(s_ScjCronjobsTask));
	
	if (strlen(s_ScjCronjobsTask) != 0)
	{
		ServerCommand("%s", s_ScjCronjobsTask);
		
		LogToFile(s_ScjLogFile, "The following task was successfully executed: '%s'", s_ScjCronjobsTask);
		
		ReinitializeTimeTimer(v_ScjCronjobsSection);
	}
	else
	{
		LogToFile(s_ScjLogFile, "There is no task to be executed! Killing Cronjob!");
	}
}

// Idiom of the day: The stroke who broke the camel's back!