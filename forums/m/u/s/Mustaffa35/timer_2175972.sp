#include <timer>
#include <timer-logging>

#undef REQUIRE_PLUGIN
#include <updater>

#define PLUGIN_NAME_RESERVED_LENGTH 33
#define UPDATE_URL "http://dl.dropbox.com/u/16304603/timer/updateinfo-timer-logging.txt"

static Handle:g_hLogFile = INVALID_HANDLE;
static const String:g_sLogLevelNames[][] = {"     ", "ERROR", "WARN", "INFO", "DEBUG", "TRACE"};
static Timer_LogLevel:g_iLogLevel = Timer_LogLevelNone;
static Timer_LogLevel:g_iLogFlushLevel = Timer_LogLevelNone;
static bool:g_bLogErrorsToSM = false;
static String:g_sCurrentDate[20];

public Plugin:myinfo =
{
	name        = "[Timer] Logging",
	author      = "alongub | Glite",
	description = "Logging component for [Timer]",
	version     = PL_VERSION,
	url         = "https://github.com/alongubkin/timer"
};

public OnPluginStart() 
{
	LoadConfig();
	
	FormatTime(g_sCurrentDate, sizeof(g_sCurrentDate), "%Y-%m-%d", GetTime());
	CreateTimer(1.0, OnCheckDate, INVALID_HANDLE, TIMER_REPEAT);
	
	if (g_iLogLevel > Timer_LogLevelNone)
	{
		CreateLogFileOrTurnOffLogging();
	}
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}			
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max) 
{
	CreateNative("Timer_GetLogLevel", Timer_GetLogLevel_);
	CreateNative("Timer_Log",         Timer_Log_);
	CreateNative("Timer_LogError",    Timer_LogError_);
	CreateNative("Timer_LogWarning",  Timer_LogWarning_);
	CreateNative("Timer_LogInfo",     Timer_LogInfo_);
	CreateNative("Timer_LogDebug",    Timer_LogDebug_);
	CreateNative("Timer_LogTrace",    Timer_LogTrace_);
	
	RegPluginLibrary("timer-logging");
	
	return APLRes_Success;
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}	
}

LoadConfig() 
{
	new Handle:kv = CreateKeyValues("root");
	
	decl String:sPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, sPath, sizeof(sPath), "configs/timer/logging.cfg");
	
	if (!FileToKeyValues(kv, sPath))
	{
		CloseHandle(kv);
		SetFailState("Can't read config file %s", sPath);
	}

	g_iLogLevel = Timer_LogLevel:KvGetNum(kv, "log_level", 2);
	g_iLogFlushLevel = Timer_LogLevel:KvGetNum(kv, "log_flush_level", 2);
	g_bLogErrorsToSM = bool:KvGetNum(kv, "log_errors_to_SM", 1);

	CloseHandle(kv);
}

public OnPluginEnd() 
{
	if (g_hLogFile != INVALID_HANDLE)
	{
		CloseLogFile();
	}
}

public Action:OnCheckDate(Handle:timer)
{
	decl String:sNewDate[20];
	FormatTime(sNewDate, sizeof(sNewDate), "%Y-%m-%d", GetTime());
	
	if (g_iLogLevel > Timer_LogLevelNone && !StrEqual(sNewDate, g_sCurrentDate)) 
	{
		strcopy(g_sCurrentDate, sizeof(g_sCurrentDate), sNewDate);
		
		if (g_hLogFile != INVALID_HANDLE) 
		{
			WriteMessageToLog(INVALID_HANDLE, Timer_LogLevelInfo, "Date changed; switching log file", true);
			CloseLogFile();
		}
		
		CreateLogFileOrTurnOffLogging();
	}
}

CloseLogFile() 
{
	WriteMessageToLog(INVALID_HANDLE, Timer_LogLevelInfo, "Logging stopped");
	FlushFile(g_hLogFile);
	CloseHandle(g_hLogFile);
	g_hLogFile = INVALID_HANDLE;
}

bool:CreateLogFileOrTurnOffLogging()
{
	decl String:sFilename[PLATFORM_MAX_PATH];
	new iPos = BuildPath(Path_SM, sFilename, sizeof(sFilename), "logs/");
	FormatTime(sFilename[iPos], sizeof(sFilename) - iPos, "timer_%Y-%m-%d.log", GetTime());
	
	if ((g_hLogFile = OpenFile(sFilename, "a")) == INVALID_HANDLE) 
	{
		g_iLogLevel = Timer_LogLevelNone;
		LogError("Can't create timer log file");
		return false;
	}
	else 
	{
		WriteMessageToLog(INVALID_HANDLE, Timer_LogLevelInfo, "Logging started", true);
		return true;
	}
}

public Timer_GetLogLevel_(Handle:plugin, num_params) 
{
	return _:g_iLogLevel;
}

public Timer_Log_(Handle:plugin, num_params) 
{
	new Timer_LogLevel:iLogLevel = Timer_LogLevel:GetNativeCell(1);
	if (g_iLogLevel >= iLogLevel) 
	{
		decl String:sMessage[10000], written;
		FormatNativeString(0, 2, 3, sizeof(sMessage), written, sMessage);
		
		if (g_hLogFile != INVALID_HANDLE)
		{
			WriteMessageToLog(plugin, iLogLevel, sMessage);
		}
		
		if (iLogLevel == Timer_LogLevelError && g_bLogErrorsToSM) 
		{
			ReplaceString(sMessage, sizeof(sMessage), "%", "%%");
			LogError(sMessage);
		}
	}
}

public Timer_LogError_(Handle:plugin, num_params) 
{
	if (g_iLogLevel >= Timer_LogLevelError) 
	{
		decl String:sMessage[10000], written;
		FormatNativeString(0, 1, 2, sizeof(sMessage), written, sMessage);
		
		if (g_hLogFile != INVALID_HANDLE)
		{
			WriteMessageToLog(plugin, Timer_LogLevelError, sMessage);
		}
		
		if (g_bLogErrorsToSM) 
		{
			ReplaceString(sMessage, sizeof(sMessage), "%", "%%");
			LogError(sMessage);
		}
	}
}

public Timer_LogWarning_(Handle:plugin, num_params) 
{
	if (g_iLogLevel >= Timer_LogLevelWarning && g_hLogFile != INVALID_HANDLE) 
	{
		decl String:sMessage[10000], written;
		FormatNativeString(0, 1, 2, sizeof(sMessage), written, sMessage);
		WriteMessageToLog(plugin, Timer_LogLevelWarning, sMessage);
	}
}

public Timer_LogInfo_(Handle:plugin, num_params) 
{
	if (g_iLogLevel >= Timer_LogLevelInfo && g_hLogFile != INVALID_HANDLE) 
	{
		decl String:sMessage[10000], written;
		FormatNativeString(0, 1, 2, sizeof(sMessage), written, sMessage);
		WriteMessageToLog(plugin, Timer_LogLevelInfo, sMessage);
	}
}

public Timer_LogDebug_(Handle:plugin, num_params) 
{
	if (g_iLogLevel >= Timer_LogLevelDebug && g_hLogFile != INVALID_HANDLE) 
	{
		decl String:sMessage[10000], written;
		FormatNativeString(0, 1, 2, sizeof(sMessage), written, sMessage);
		WriteMessageToLog(plugin, Timer_LogLevelDebug, sMessage);
	}
}

public Timer_LogTrace_(Handle:plugin, num_params) 
{
	if (g_iLogLevel >= Timer_LogLevelTrace && g_hLogFile != INVALID_HANDLE) 
	{
		decl String:sMessage[10000], written;
		FormatNativeString(0, 1, 2, sizeof(sMessage), written, sMessage);
		WriteMessageToLog(plugin, Timer_LogLevelTrace, sMessage);
	}
}

WriteMessageToLog(Handle:plugin, Timer_LogLevel:iLogLevel, const String:sMessage[], bool:bForceFlush=false) 
{
	decl String:sLogLine[10000];
	PrepareLogLine(plugin, iLogLevel, sMessage, sLogLine);
	WriteFileString(g_hLogFile, sLogLine, false);
	
	if (iLogLevel <= g_iLogFlushLevel || bForceFlush)
	{
		FlushFile(g_hLogFile);
	}
}

PrepareLogLine(Handle:plugin, Timer_LogLevel:iLogLevel, const String:sMessage[], String:sLogLine[10000]) 
{
	decl String:sPluginName[100];
	GetPluginFilename(plugin, sPluginName, sizeof(sPluginName) - 1);
	// Make windows consistent with unix
	ReplaceString(sPluginName, sizeof(sPluginName), "\\", "/");
	new iNameEnd = strlen(sPluginName);
	sPluginName[iNameEnd++] = ']';
	for (new end = PLUGIN_NAME_RESERVED_LENGTH - 1; iNameEnd < end; ++iNameEnd)
	{
		sPluginName[iNameEnd] = ' ';
	}
	sPluginName[iNameEnd++] = 0;
	FormatTime(sLogLine, sizeof(sLogLine), "%Y-%m-%d %H:%M:%S [", GetTime());
	new iPos = strlen(sLogLine);
	iPos += strcopy(sLogLine[iPos], sizeof(sLogLine) - iPos, sPluginName);
	sLogLine[iPos++] = ' ';
	iPos += strcopy(sLogLine[iPos], sizeof(sLogLine) - iPos - 5, g_sLogLevelNames[iLogLevel]);
	sLogLine[iPos++] = ' ';
	sLogLine[iPos++] = '|';
	sLogLine[iPos++] = ' ';
	iPos += strcopy(sLogLine[iPos], sizeof(sLogLine) - iPos - 2, sMessage);
	sLogLine[iPos++] = '\n';
	sLogLine[iPos++] = 0;
}