#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <smlib/arrays>

#include <timer>
#include <timer-logging>

#undef REQUIRE_PLUGIN
#include <timer-physics>
#include <updater>

#define UPDATE_URL "http://dl.dropbox.com/u/16304603/timer/updateinfo-timer-core.txt"

/** 
 * Global Enums
 */
enum Timer
{
	Enabled,
	Float:StartTime,
	Float:EndTime,
	Jumps,
	bool:IsPaused,
	Float:PauseStartTime,
	Float:PauseLastOrigin[3],
	Float:PauseLastVelocity[3],
	Float:PauseLastAngles[3],
	Float:PauseTotalTime,
	FpsMax
}

enum BestTimeCacheEntity
{
	IsCached,
	Jumps,
	Float:Time
}

/**
 * Global Variables
 */
new Handle:g_hSQL;

new String:g_currentMap[32];
new g_reconnectCounter = 0;

new g_timers[MAXPLAYERS+1][Timer];
new g_bestTimeCache[MAXPLAYERS+1][BestTimeCacheEntity];

new Handle:g_timerStartedForward;
new Handle:g_timerStoppedForward;
new Handle:g_timerRestartForward;

new Handle:g_restartEnabledCvar = INVALID_HANDLE;
new Handle:g_stopEnabledCvar = INVALID_HANDLE;
new Handle:g_pauseResumeEnabledCvar = INVALID_HANDLE;
new Handle:g_showJumpsInMsg = INVALID_HANDLE;

new bool:g_restartEnabled = true;
new bool:g_stopEnabled = true;
new bool:g_pauseResumeEnabled = true;
new bool:g_showjumps = true;

new bool:g_timerPhysics = false;
new g_iVelocity;

public Plugin:myinfo =
{
    name        = "[Timer] Core",
    author      = "alongub | Glite",
    description = "Core component for [Timer]",
    version     = PL_VERSION,
    url         = "https://github.com/alongubkin/timer"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer");
	
	CreateNative("Timer_Start", Native_TimerStart);
	CreateNative("Timer_Stop", Native_TimerStop);
	CreateNative("Timer_Restart", Native_TimerRestart);
	CreateNative("Timer_GetBestRound", Native_GetBestRound);
	CreateNative("Timer_GetClientTimer", Native_GetClientTimer);
	CreateNative("Timer_FinishRound", Native_FinishRound);
	CreateNative("Timer_ForceReloadBestRoundCache", Native_ForceReloadBestRoundCache);

	return APLRes_Success;
}

public OnPluginStart()
{
	CreateConVar("timer_version", PL_VERSION, "Timer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	g_timerStartedForward = CreateGlobalForward("OnTimerStarted", ET_Event, Param_Cell);
	g_timerStoppedForward = CreateGlobalForward("OnTimerStopped", ET_Event, Param_Cell);
	g_timerRestartForward = CreateGlobalForward("OnTimerRestart", ET_Event, Param_Cell);

	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	g_timerPhysics = LibraryExists("timer-physics");
	
	LoadTranslations("timer.phrases");
	
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("player_death", Event_StopTimer);
	HookEvent("player_team", Event_StopTimer);
	HookEvent("player_spawn", Event_StopTimer);
	HookEvent("player_disconnect", Event_StopTimer);
	
	RegConsoleCmd("sm_restart", Command_Restart);
	RegConsoleCmd("sm_stop", Command_Stop);
	RegConsoleCmd("sm_pause", Command_Pause);
	RegConsoleCmd("sm_resume", Command_Resume);
	
	g_restartEnabledCvar = CreateConVar("timer_restart_enabled", "1", "Whether or not players can restart their timers.");
	g_stopEnabledCvar = CreateConVar("timer_stop_enabled", "1", "Whether or not players can stop their timers.");
	g_pauseResumeEnabledCvar = CreateConVar("timer_pauseresume_enabled", "1", "Whether or not players can resume or pause their timers.");
	g_showJumpsInMsg = CreateConVar("timer_showjumpsinfinishmessage", "1", "Whether or not players will see jumps in finish message.");
	
	HookConVarChange(g_restartEnabledCvar, Action_OnSettingsChange);
	HookConVarChange(g_stopEnabledCvar, Action_OnSettingsChange);	
	HookConVarChange(g_pauseResumeEnabledCvar, Action_OnSettingsChange);
	HookConVarChange(g_showJumpsInMsg, Action_OnSettingsChange);
	
	AutoExecConfig(true, "timer-core");
	
	if (LibraryExists("updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}	
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}
	else if (StrEqual(name, "updater"))
	{
		Updater_AddPlugin(UPDATE_URL);
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = false;
	}
}

public OnMapStart()
{	
	ConnectSQL();
	
	GetCurrentMap(g_currentMap, sizeof(g_currentMap));
	ClearCache();
}

public OnMapEnd()
{
	ClearCache();
}

public OnPlayerConnect(client)
{
    StartTimer(client);
}

/**
 * Events
 */
public Action:Event_PlayerJump(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));

	if (g_timers[client][Enabled] && !g_timers[client][IsPaused])
		g_timers[client][Jumps]++;
	
	return Plugin_Continue;
}

public Action:Event_StopTimer(Handle:event, const String:name[], bool:dontBroadcast)
{
	StopTimer(GetClientOfUserId(GetEventInt(event, "userid")));
	return Plugin_Continue;
}

public Action:Command_Restart(client, args)
{
	if (g_restartEnabled && IsPlayerAlive(client))
		RestartTimer(client);
	
	return Plugin_Handled;
}

public Action:Command_Stop(client, args)
{
	if (g_stopEnabled && IsPlayerAlive(client))
		StopTimer(client);
		
	return Plugin_Handled;
}

public Action:Command_Pause(client, args)
{
	if (g_pauseResumeEnabled && IsPlayerAlive(client))
		PauseTimer(client);
		
	return Plugin_Handled;
}

public Action:Command_Resume(client, args)
{
	if (g_pauseResumeEnabled && IsPlayerAlive(client))
		ResumeTimer(client);
		
	return Plugin_Handled;
}

public FpsMaxCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	g_timers[client][FpsMax] = StringToInt(cvarValue);
}

public Action_OnSettingsChange(Handle:cvar, const String:oldvalue[], const String:newvalue[])
{
	if (cvar == g_restartEnabledCvar)
		g_restartEnabled = bool:StringToInt(newvalue);
	else if (cvar == g_stopEnabledCvar)
		g_stopEnabled = bool:StringToInt(newvalue);
	else if (cvar == g_pauseResumeEnabledCvar)
		g_pauseResumeEnabled = bool:StringToInt(newvalue);	
	else if (cvar == g_showJumpsInMsg)
		g_showjumps = bool:StringToInt(newvalue);			
}

/**
 * Core Functionality
 */
bool:StartTimer(client)
{
	if (g_timers[client][Enabled])
		return false;
	
	g_timers[client][Enabled] = true;
	g_timers[client][StartTime] = GetGameTime();
	g_timers[client][EndTime] = -1.0;
	g_timers[client][Jumps] = 0;
	g_timers[client][IsPaused] = false;
	g_timers[client][PauseStartTime] = 0.0;
	g_timers[client][PauseTotalTime] = 0.0;

	QueryClientConVar(client, "fps_max", FpsMaxCallback, client);

	Call_StartForward(g_timerStartedForward);
	Call_PushCell(client);
	Call_Finish();

	return true;
}

bool:StopTimer(client, bool:stopPaused = true)
{
	if (!g_timers[client][Enabled])
		return false;
	
	if (!stopPaused && g_timers[client][IsPaused])
		return false;
	
	g_timers[client][Enabled] = false;
	g_timers[client][EndTime] = GetGameTime();

	Call_StartForward(g_timerStoppedForward);
	Call_PushCell(client);
	Call_Finish();
		
	return true;
}

bool:RestartTimer(client)
{
	StopTimer(client);
	
	Call_StartForward(g_timerRestartForward);
	Call_PushCell(client);
	Call_Finish();

	return StartTimer(client);
}

bool:PauseTimer(client)
{
	if (!g_timers[client][Enabled] || g_timers[client][IsPaused])
		return false;
	
	g_timers[client][IsPaused] = true;
	g_timers[client][PauseStartTime] = GetGameTime();
	
	new Float:origin[3];
	GetClientAbsOrigin(client, origin);
	Array_Copy(origin, g_timers[client][PauseLastOrigin], 3);

	new Float:angles[3];
	GetClientAbsAngles(client, angles);
	Array_Copy(angles, g_timers[client][PauseLastAngles], 3);

	new Float:velocity[3];
	GetClientAbsVelocity(client, velocity);
	Array_Copy(velocity, g_timers[client][PauseLastVelocity], 3);

	return true;
}

bool:ResumeTimer(client)
{
	if (!g_timers[client][Enabled] || !g_timers[client][IsPaused])
		return false;

	g_timers[client][IsPaused] = false;
	g_timers[client][PauseTotalTime] += GetGameTime() - g_timers[client][PauseStartTime];

	new Float:origin[3];
	Array_Copy(g_timers[client][PauseLastOrigin], origin, 3);

	new Float:angles[3];
	Array_Copy(g_timers[client][PauseLastAngles], angles, 3);

	new Float:velocity[3];
	Array_Copy(g_timers[client][PauseLastVelocity], angles, 3);

	TeleportEntity(client, origin, angles, velocity);

	return true;
}

bool:GetBestRound(client, const String:map[], &Float:time, &jumps)
{
	Timer_LogTrace("GetBestRound client: %d - Start", client);
	
	if (IsClientInGame(client))
	{
		Timer_LogTrace("GetBestRound client: %d - IsCached: %b", client, g_bestTimeCache[client][IsCached]);
		
		if (g_bestTimeCache[client][IsCached])
		{			
			time = g_bestTimeCache[client][Time];
			jumps = g_bestTimeCache[client][Jumps];
			
			return true;
		}

		Timer_LogTrace("GetBestRound client: %d - Not cached, fetching best round", client);
		
		decl String:auth[32];
		GetClientAuthString(client, auth, sizeof(auth));
		
		decl String:query[128];
		Format(query, sizeof(query), "SELECT id, map, auth, time, jumps FROM round WHERE auth = '%s' AND map = '%s' ORDER BY time ASC LIMIT 1", auth, map);
		
		Timer_LogTrace("GetBestRound client: %d - query: %s", client, query);
		
		SQL_LockDatabase(g_hSQL);
	
		new Handle:hQuery = SQL_Query(g_hSQL, query);
		
		if (hQuery == INVALID_HANDLE)
		{
			SQL_UnlockDatabase(g_hSQL);
			return false;
		}

		SQL_UnlockDatabase(g_hSQL); 

		if (SQL_FetchRow(hQuery))
		{
			Timer_LogTrace("GetBestRound client: %d - SQL_FetchRow = true", client);
			
			time = SQL_FetchFloat(hQuery, 3);
			jumps = SQL_FetchInt(hQuery, 4);
			
			Timer_LogTrace("GetBestRound client: %d - Caching.", client);
			
			g_bestTimeCache[client][IsCached] = true;
			g_bestTimeCache[client][Time] = time;
			g_bestTimeCache[client][Jumps] = jumps;
			
			CloseHandle(hQuery);
		}
		else
		{
			Timer_LogTrace("GetBestRound client: %d - SQL_FetchRow = false", client);
			
			g_bestTimeCache[client][IsCached] = true;
			g_bestTimeCache[client][Time] = 0.0;
			g_bestTimeCache[client][Jumps] = 0;			
			
			CloseHandle(hQuery);
			return false;
		}
		
		return true;
	}
	
	return false;
}

ClearCache()
{
	Timer_LogTrace("ClearCache");
	for (new client = 1; client <= MaxClients; client++)
		ClearClientCache(client);
}

ClearClientCache(client)
{
	g_bestTimeCache[client][IsCached] = false;
	g_bestTimeCache[client][Jumps] = 0;
	g_bestTimeCache[client][Time] = 0.0;	
}

FinishRound(client, const String:map[], Float:time, jumps, physicsDifficulty, fpsmax)
{
	if (IsClientInGame(client))
	{
		new Float:LastTime;
		new LastJumps;
		decl String:TimeDiff[32];
		decl String:buffer[32];
		
		if(Timer_GetBestRound(client, map, LastTime, LastJumps))
		{
			LastTime -= time;			
			if(LastTime < 0.0)
			{	
				LastTime *= -1.0;
				Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), true);
				Format(TimeDiff, sizeof(TimeDiff), "+%s", buffer);
			}
			else if(LastTime > 0.0)
			{
				Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), true);
				Format(TimeDiff, sizeof(TimeDiff), "-%s", buffer);
			}
			else if(LastTime == 0.0)
			{
				Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), true);
				Format(TimeDiff, sizeof(TimeDiff), "%s", buffer);

			}
		}
		else
		{
			LastTime = 0.0;
			Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), true);
			Format(TimeDiff, sizeof(TimeDiff), "%s", buffer);
		}

		decl String:auth[32];
		GetClientAuthString(client, auth, sizeof(auth));

		decl String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
		
		decl String:safeName[2 * strlen(name) + 1];
		SQL_EscapeString(g_hSQL, name, safeName, 2 * strlen(name) + 1);

		decl String:query[256];
		Format(query, sizeof(query), "INSERT INTO round (map, auth, time, jumps, physicsdifficulty, name, fpsmax) VALUES ('%s', '%s', %f, %d, %d, '%s', %d);", map, auth, time, jumps, physicsDifficulty, safeName, fpsmax);
		
		SQL_TQuery(g_hSQL, FinishRoundCallback, query, client, DBPrio_Normal);
		
		decl String:TimeString[32];
		Timer_SecondsToTime(time, TimeString, sizeof(TimeString), true);
		
		
		if(g_showjumps)
		{
			if (g_timerPhysics)
			{
				new String:difficulty[32];
				Timer_GetDifficultyName(physicsDifficulty, difficulty, sizeof(difficulty));	
				
				PrintToChatAll(PLUGIN_PREFIX, "Round Finish Difficulty", name, TimeString, TimeDiff, difficulty, jumps);
			}
			else
			{
				PrintToChatAll(PLUGIN_PREFIX, "Round Finish", name, TimeString, TimeDiff, jumps);		
			}
		}
		else
		{
			if (g_timerPhysics)
			{
				new String:difficulty[32];
				Timer_GetDifficultyName(physicsDifficulty, difficulty, sizeof(difficulty));	
				
				PrintToChatAll(PLUGIN_PREFIX, "Round Finish Difficulty Without Jumps", name, TimeString, TimeDiff, difficulty);
			}
			else
			{
				PrintToChatAll(PLUGIN_PREFIX, "Round Finish Without Jumps", name, TimeString, TimeDiff);
			}
		}
	}
}

public FinishRoundCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on FinishRound: %s", error);
		return;
	}

	g_bestTimeCache[client][IsCached] = false;
}

Float:CalculateTime(client)
{
	if (g_timers[client][Enabled] && g_timers[client][IsPaused])
		return g_timers[client][PauseStartTime] - g_timers[client][StartTime] - g_timers[client][PauseTotalTime];
	else
		return (g_timers[client][Enabled] ? GetGameTime() : g_timers[client][EndTime]) - g_timers[client][StartTime] - g_timers[client][PauseTotalTime];	
}

ConnectSQL()
{
    if (g_hSQL != INVALID_HANDLE)
        CloseHandle(g_hSQL);
	
    g_hSQL = INVALID_HANDLE;

    if (SQL_CheckConfig("timer"))
	{
		SQL_TConnect(ConnectSQLCallback, "timer");
	}
    else
	{
		Timer_LogError("PLUGIN STOPPED - Reason: no config entry found for 'timer' in databases.cfg - PLUGIN STOPPED");
	}
}

public ConnectSQLCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if (g_reconnectCounter >= 5)
	{
		Timer_LogError("PLUGIN STOPPED - Reason: reconnect counter reached max - PLUGIN STOPPED");
		return;
	}

	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("Connection to SQL database has failed, Reason: %s", error);
		
		g_reconnectCounter++;
		ConnectSQL();
		
		return;
	}

	decl String:driver[16];
	SQL_GetDriverIdent(owner, driver, sizeof(driver));

	g_hSQL = CloneHandle(hndl);		
	
	if (StrEqual(driver, "mysql", false))
	{
		SQL_FastQuery(g_hSQL, "SET NAMES  'utf8'");
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `round` (`id` int(11) NOT NULL AUTO_INCREMENT, `map` varchar(32) NOT NULL, `auth` varchar(32) NOT NULL, `time` float NOT NULL, `jumps` int(11) NOT NULL, `physicsdifficulty` int(11) NOT NULL, `name` varchar(64) NOT NULL, `fpsmax` int(11) NOT NULL, PRIMARY KEY (`id`));");
	}
	else if (StrEqual(driver, "sqlite", false))
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `round` (`id` INTEGER PRIMARY KEY, `map` varchar(32) NOT NULL, `auth` varchar(32) NOT NULL, `time` float NOT NULL, `jumps` INTEGER NOT NULL, `physicsdifficulty` INTEGER NOT NULL, `name` varchar(64) NOT NULL, `fpsmax` INTEGER NOT NULL);");
	}
	
	g_reconnectCounter = 1;
}

public CreateSQLTableCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{	
	if (owner == INVALID_HANDLE)
	{
		Timer_LogError(error);
		
		g_reconnectCounter++;
		ConnectSQL();

		return;
	}
	
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on CreateSQLTable: %s", error);
		return;
	}
}

public Native_TimerStart(Handle:plugin, numParams)
{
	return StartTimer(GetNativeCell(1));
}

public Native_TimerStop(Handle:plugin, numParams)
{
	return StopTimer(GetNativeCell(1), bool:GetNativeCell(2));
}

public Native_TimerRestart(Handle:plugin, numParams)
{
	return RestartTimer(GetNativeCell(1));
}

public Native_GetBestRound(Handle:plugin, numParams)
{
	Timer_LogTrace("Native_GetBestRound");
	
	decl String:map[32];
	GetNativeString(2, map, sizeof(map));
	
	new Float:time;
	new jumps;
	
	Timer_LogTrace("Native_GetBestRound - Calling GetBestRound");
	
	new bool:success = GetBestRound(GetNativeCell(1), map, time, jumps);
	Timer_LogTrace("Native_GetBestRound - success: %b", success);
	
	if (success)
	{
		SetNativeCellRef(3, time);
		SetNativeCellRef(4, jumps);
		
		return true;
	}
	
	return false;
}

public Native_GetClientTimer(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	
	SetNativeCellRef(2, g_timers[client][Enabled]);
	SetNativeCellRef(3, CalculateTime(client));
	SetNativeCellRef(4, g_timers[client][Jumps]);
	SetNativeCellRef(5, g_timers[client][FpsMax]);	

	return true;
}

public Native_FinishRound(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);

	decl String:map[32];
	GetNativeString(2, map, sizeof(map));
	
	new Float:time = GetNativeCell(3);
	new jumps = GetNativeCell(4);
	new physicsDifficulty = GetNativeCell(5);
	new fpsmax = GetNativeCell(6);

	FinishRound(client, map, time, jumps, physicsDifficulty, fpsmax);
}

public Native_ForceReloadBestRoundCache(Handle:plugin, numParams)
{
	Timer_LogTrace("Native_ForceReloadBestRoundCache");
	ClearCache();
}

/**
 * Utils methods
 */
stock GetClientAbsVelocity(client, Float:vecVelocity[3])
{
	for (new x = 0; x < 3; x++)
	{
		vecVelocity[x] = GetEntDataFloat(client, g_iVelocity + (x*4));
	}
}