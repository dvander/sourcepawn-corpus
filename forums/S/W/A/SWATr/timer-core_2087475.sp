#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <loghelper>
#include <smlib>
#include <smlib/arrays>

#include <timer-logging>
#include <timer-config_loader.sp>
#include <timer-stocks>

#undef REQUIRE_PLUGIN
#include <timer>

#define MAX_FILE_LEN 128

//new bool:g_timerMapzones = false;
//new bool:g_timerCpMod = false;
//new bool:g_timerLjStats = false;
//new bool:g_timerLogging = false;
//new bool:g_timerLogging = false;
//new bool:g_timerMapTier = false;
new bool:g_timerPhysics = false;
//new bool:g_timerRankings = false;
//new bool:g_timerRankingsTopOnly = false;
//new bool:g_timerScripterDB = false;
new bool:g_timerStrafes = false;
new bool:g_timerTeams = false;
//new bool:g_timerWeapons = false;
new bool:g_timerWorldRecord = false;

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
	CurrentMode,
	FpsMax,
	Bonus,
	FinishCount,
	BonusFinishCount,
	ShortFinishCount,
	bool:ShortEndReached
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

new String:g_currentMap[64];
new g_reconnectCounter = 0;

new g_timers[MAXPLAYERS+1][Timer];
new g_bestTimeCache[MAXPLAYERS+1][BestTimeCacheEntity];
new g_iTotalRankCache;
new g_iTotalRankCacheBonus;
new g_iTotalRankCacheShort;
new g_iCurrentRankCache[MAXPLAYERS+1];
new g_iCurrentRankCacheBonus[MAXPLAYERS+1];
new g_iCurrentRankCacheShort[MAXPLAYERS+1];

new Handle:g_timerStartedForward;
new Handle:g_timerStoppedForward;
new Handle:g_timerRestartForward;
new Handle:g_timerPausedForward;
new Handle:g_timerResumedForward;

new Handle:g_timerWorldRecordForward;
new Handle:g_timerPersonalRecordForward;
new Handle:g_timerTop10RecordForward;
new Handle:g_timerFirstRecordForward;
new Handle:g_timerRecordForward;

new g_iVelocity;
new GameMod:mod;

public Plugin:myinfo =
{
    name        = "[Timer] Core",
    author      = "Zipcore, Credits: Alongub",
    description = "Core component for [Timer]",
    version     = PL_VERSION,
    url         = "zipcore#googlemail.com"
};

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	RegPluginLibrary("timer");
	
	CreateNative("Timer_Reset", Native_Reset);
	CreateNative("Timer_Start", Native_Start);
	CreateNative("Timer_Stop", Native_Stop);
	CreateNative("Timer_Pause", Native_Pause);
	CreateNative("Timer_Resume", Native_Resume);
	CreateNative("Timer_Restart", Native_Restart);
	CreateNative("Timer_FinishRound", Native_FinishRound);
	
	CreateNative("Timer_GetClientTimer", Native_GetClientTimer);
	CreateNative("Timer_GetStatus", Native_GetStatus);
	CreateNative("Timer_GetPauseStatus", Native_GetPauseStatus);
	
	CreateNative("Timer_SetMode", Native_SetMode);
	CreateNative("Timer_GetMode", Native_GetMode);
	CreateNative("Timer_IsModeRanked", Native_IsModeRanked);
	
	CreateNative("Timer_GetBonus", Native_GetBonus);
	CreateNative("Timer_SetBonus", Native_SetBonus);
	
	CreateNative("Timer_GetMapFinishCount", Native_GetMapFinishCount);
	CreateNative("Timer_GetMapFinishBonusCount", Native_GetMapFinishBonusCount);
	CreateNative("Timer_GetTotalRank", Native_GetTotalRank);
	CreateNative("Timer_GetCurrentRank", Native_GetCurrentRank);
	CreateNative("Timer_ForceClearCacheBest", Native_ForceClearCacheBest);
	
	CreateNative("Timer_AddPenaltyTime", Native_AddPenaltyTime);

	return APLRes_Success;
}

public OnPluginStart()
{
	LoadPhysics();
	LoadTimerSettings();
	
	CreateConVar("timer_version", PL_VERSION, "Timer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	
	RegConsoleCmd("sm_credits", Command_Credits);
	mod = GetGameMod();
	
	g_timerStartedForward = CreateGlobalForward("OnTimerStarted", ET_Event, Param_Cell);
	g_timerStoppedForward = CreateGlobalForward("OnTimerStopped", ET_Event, Param_Cell);
	g_timerRestartForward = CreateGlobalForward("OnTimerRestart", ET_Event, Param_Cell);
	g_timerPausedForward = CreateGlobalForward("OnTimerPaused", ET_Event, Param_Cell);
	g_timerResumedForward = CreateGlobalForward("OnTimerResumed", ET_Event, Param_Cell);
	
	g_timerWorldRecordForward = CreateGlobalForward("OnTimerWorldRecord", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_timerPersonalRecordForward = CreateGlobalForward("OnTimerPersonalRecord", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_timerTop10RecordForward = CreateGlobalForward("OnTimerTop10Record", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_timerFirstRecordForward = CreateGlobalForward("OnTimerFirstRecord", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	g_timerRecordForward = CreateGlobalForward("OnTimerRecord", ET_Event, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_Cell);
	
	g_iVelocity = FindSendPropInfo("CBasePlayer", "m_vecVelocity[0]");
	
	LoadTranslations("timer.phrases");
	
	//RegConsoleCmd("sm_stop", Command_Stop);
	if(g_Settings[PauseEnable]) RegConsoleCmd("sm_pause", Command_Pause);
	if(g_Settings[PauseEnable]) RegConsoleCmd("sm_resume", Command_Resume);
	
	HookEvent("player_jump", Event_PlayerJump);
	HookEvent("player_death", Event_StopTimer);
	HookEvent("player_team", Event_StopTimerPaused);
	HookEvent("player_spawn", Event_PlayerSpawn);
	HookEvent("player_disconnect", Event_StopTimer);
	
	AutoExecConfig(true, "timer/timer-core");
	
	//g_timerMapzones = LibraryExists("timer-mapzones");
	//g_timerCpMod = LibraryExists("timer-cpmod");
	//g_timerLjStats = LibraryExists("timer-ljstats");
	//g_timerLogging = LibraryExists("timer-logging");
	//g_timerMapTier = LibraryExists("timer-maptier");
	//g_timerRankings = LibraryExists("timer-rankings");
	//g_timerRankingsTopOnly = LibraryExists("timer-rankings_top_only");
	g_timerPhysics = LibraryExists("timer-physics");
	//g_timerScripterDB = LibraryExists("timer-scripter_db");
	g_timerStrafes = LibraryExists("timer-strafes");
	g_timerTeams = LibraryExists("timer-teams");
	//g_timerWeapons = LibraryExists("timer-weapons");
	g_timerWorldRecord = LibraryExists("timer-worldrecord");
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "timer-mapzones"))
	{
		//g_timerMapzones = true;
	}		
	else if (StrEqual(name, "timer-cpmod"))
	{
		//g_timerCpMod = true;
	}	
	else if (StrEqual(name, "timer-ljstats"))
	{
		//g_timerLjStats = true;
	}	
	else if (StrEqual(name, "timer-logging"))
	{
		//g_timerLogging = true;
	}	
	else if (StrEqual(name, "timer-maptier"))
	{
		//g_timerMapTier = true;
	}	
	else if (StrEqual(name, "timer-rankings"))
	{
		//g_timerRankings = true;
	}		
	else if (StrEqual(name, "timer-rankings_top_only"))
	{
		//g_timerRankingsTopOnly = true;
	}
	else if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = true;
	}
	else if (StrEqual(name, "timer-scripter_db"))
	{
		//g_timerScripterDB = true;
	}
	else if (StrEqual(name, "timer-strafes"))
	{
		g_timerStrafes = true;
	}
	else if (StrEqual(name, "timer-teams"))
	{
		g_timerTeams = true;
	}
	else if (StrEqual(name, "timer-weapons"))
	{
		//g_timerWeapons = true;
	}
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = true;
	}
}

public OnLibraryRemoved(const String:name[])
{	
	if (StrEqual(name, "timer-mapzones"))
	{
		//g_timerMapzones = false;
	}		
	else if (StrEqual(name, "timer-cpmod"))
	{
		//g_timerCpMod = false;
	}	
	else if (StrEqual(name, "timer-ljstats"))
	{
		//g_timerLjStats = false;
	}	
	else if (StrEqual(name, "timer-logging"))
	{
		//g_timerLogging = false;
	}	
	else if (StrEqual(name, "timer-maptier"))
	{
		//g_timerMapTier = false;
	}	
	else if (StrEqual(name, "timer-rankings"))
	{
		//g_timerRankings = false;
	}		
	else if (StrEqual(name, "timer-rankings_top_only"))
	{
		//g_timerRankingsTopOnly = false;
	}
	else if (StrEqual(name, "timer-physics"))
	{
		g_timerPhysics = false;
	}
	else if (StrEqual(name, "timer-scripter_db"))
	{
		//g_timerScripterDB = false;
	}
	else if (StrEqual(name, "timer-strafes"))
	{
		g_timerStrafes = false;
	}
	else if (StrEqual(name, "timer-teams"))
	{
		g_timerTeams = false;
	}
	else if (StrEqual(name, "timer-weapons"))
	{
		//g_timerWeapons = false;
	}
	else if (StrEqual(name, "timer-worldrecord"))
	{
		g_timerWorldRecord = false;
	}
}

public OnClientAuthorized(client, const String:auth[])
{
	if(StrContains(auth, "STEAM", true) > -1)
	{
		if(Client_IsValid(client) && !IsFakeClient(client) && g_hSQL != INVALID_HANDLE)
		{
			new String:name[32];
			GetClientName(client, name, sizeof(name));
			
			decl String:safeName[2 * strlen(name) + 1];
			SQL_EscapeString(g_hSQL, name, safeName, 2 * strlen(name) + 1);
			
			decl String:query[512];
			Format(query, sizeof(query), "UPDATE `round` SET name = '%s' WHERE auth = '%s'", safeName, auth);

			SQL_TQuery(g_hSQL, UpdateNameCallback, query, _, DBPrio_Normal);
			
			if(GetGameTime() > 10.0 && g_timerWorldRecord) Timer_ForceReloadCache();
		}
	}
	else if(!IsFakeClient(client)) KickClient(client, "NO VALID STEAM ID");
}

public PrepareSound(String: sound[MAX_FILE_LEN])
{
	decl String:fileSound[MAX_FILE_LEN];

	Format(fileSound, MAX_FILE_LEN, "sound/%s", sound);

	if (FileExists(fileSound))
	{
		PrecacheSound(sound, true);
		AddFileToDownloadsTable(fileSound);
	}
	else
	{
		PrintToServer("[Timer] ERROR: File '%s' not found!", fileSound);
	}
}

public OnMapStart()
{	
	ConnectSQL();
	
	GetCurrentMap(g_currentMap, sizeof(g_currentMap));
	ClearCache();
	ClearFinishCounts();
	
	LoadPhysics();
	LoadTimerSettings();
}

ClearFinishCounts()
{
	for(new i=1;i<=MaxClients;i++)
	{
		g_timers[i][FinishCount] = 0;	
		g_timers[i][BonusFinishCount] = 0;
		g_timers[i][ShortFinishCount] = 0;
		g_timers[i][Bonus] = 0;
	}
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
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(0 < client <= GetMaxClients()) if (IsClientInGame(client)) StopTimer(client, false);
	return Plugin_Continue;
}

public Action:Event_StopTimerPaused(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(0 < client <= GetMaxClients()) if (IsClientInGame(client)) StopTimer(client);
	return Plugin_Continue;
}

public Event_PlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if(0 < client <= GetMaxClients())
	{
		if(IsClientInGame(client))
			StopTimer(client);
	}
}

public Action:Command_Stop(client, args)
{
	if (IsPlayerAlive(client))
		StopTimer(client, false);
		
	return Plugin_Handled;
}

public Action:Command_Pause(client, args)
{
	if (g_Settings[PauseEnable] && IsPlayerAlive(client))
		PauseTimer(client);
		
	return Plugin_Handled;
}

public Action:Command_Resume(client, args)
{
	if (g_Settings[PauseEnable] && IsPlayerAlive(client))
		ResumeTimer(client);
		
	return Plugin_Handled;
}

public FpsMaxCallback(QueryCookie:cookie, client, ConVarQueryResult:result, const String:cvarName[], const String:cvarValue[])
{
	g_timers[client][FpsMax] = StringToInt(cvarValue);
}

/**
 * Core Functionality
 */

bool:ResetTimer(client)
{
	g_timers[client][Enabled] = false;
	g_timers[client][StartTime] = GetGameTime();
	g_timers[client][EndTime] = -1.0;
	g_timers[client][Jumps] = 0;
	g_timers[client][IsPaused] = false;
	g_timers[client][PauseStartTime] = 0.0;
	g_timers[client][PauseTotalTime] = 0.0;
	g_timers[client][ShortEndReached] = false;
	if(g_timerPhysics) Timer_ResetAccuracy(client);
	
	return true;
}

bool:TimerPenalty(client, Float:penaltytime)
{
	g_timers[client][StartTime] -= penaltytime;
	
	return true;
}
 
bool:StartTimer(client)
{
	if(!IsValidClient(client))
		return true;
	if (g_timers[client][Enabled])
		return false;
	
	g_timers[client][Enabled] = true;
	g_timers[client][ShortEndReached] = false;
	g_timers[client][StartTime] = GetGameTime();
	g_timers[client][EndTime] = -1.0;
	g_timers[client][Jumps] = 0;
	g_timers[client][IsPaused] = false;
	g_timers[client][PauseStartTime] = 0.0;
	g_timers[client][PauseTotalTime] = 0.0;
	if(g_timerPhysics) Timer_ResetAccuracy(client);
	
	//Check for custom settings
	QueryClientConVar(client, "fps_max", FpsMaxCallback, client);

	//Push Forward Timer_Started(client)
	Call_StartForward(g_timerStartedForward);
	Call_PushCell(client);
	Call_Finish();
	return true;
}

bool:StopTimer(client, bool:stopPaused = true)
{
	if(!IsValidClient(client))
		return true;
	if (!g_timers[client][Enabled])
		return false;
	
	//Already paused?
	if (!stopPaused && g_timers[client][IsPaused])
		return false;
	
	//EmitSoundToClient(client, SND_TIMER_STOP);
	
	//Get time
	g_timers[client][Enabled] = false;
	g_timers[client][ShortEndReached] = true;
	g_timers[client][EndTime] = GetGameTime();
	
	//Prevent Resume
	if (!stopPaused) g_timers[client][IsPaused] = false;
	
	//Forward Timer_Stopped(client)
	Call_StartForward(g_timerStoppedForward);
	Call_PushCell(client);
	Call_Finish();
	
	//Stop mate
	new mate = Timer_GetClientTeammate(client);
	if(0 < mate) StopTimer(mate, false);
		
	return true;
}

bool:RestartTimer(client)
{
	if(!IsValidClient(client))
		return true;
	
	StopTimer(client, false);
	
	//Forward Timer_Restarted(client)
	Call_StartForward(g_timerRestartForward);
	Call_PushCell(client);
	Call_Finish();
	
	new mate = Timer_GetClientTeammate(client);
	if(mate != 0) StopTimer(mate, false);

	return StartTimer(client);
}

bool:PauseTimer(client)
{
	if(!IsValidClient(client))
		return true;
	if (!g_timers[client][Enabled] || g_timers[client][IsPaused])
		return false;
	
	Call_StartForward(g_timerPausedForward);
	Call_PushCell(client);
	Call_Finish();
	
	new mate;
	if(g_timerTeams) mate = Timer_GetClientTeammate(client);
	g_timers[client][IsPaused] = true;
	g_timers[client][PauseStartTime] = GetGameTime();
	
	CreateTimer(0.0, Timer_ValidatePause, client, TIMER_FLAG_NO_MAPCHANGE);
	
	CPrintToChat(client, PLUGIN_PREFIX, "Pause Info");
	
	if(0 < mate)
	{
		g_timers[mate][IsPaused] = true;
		g_timers[mate][PauseStartTime] = GetGameTime();
		
		CreateTimer(0.0, Timer_ValidatePause, mate, TIMER_FLAG_NO_MAPCHANGE);
		
		CPrintToChat(mate, PLUGIN_PREFIX, "Pause Info");
		
		new Float:origin2[3];
		GetClientAbsOrigin(mate, origin2);
		Array_Copy(origin2, g_timers[mate][PauseLastOrigin], 3);

		new Float:angles2[3];
		GetClientAbsAngles(mate, angles2);
		Array_Copy(angles2, g_timers[mate][PauseLastAngles], 3);

		new Float:velocity2[3];
		GetClientAbsVelocity(mate, velocity2);
		Array_Copy(velocity2, g_timers[mate][PauseLastVelocity], 3);
	}
	
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

public Action:Timer_ValidatePause(Handle:timer, any:client)
{
	if(CalculateTime(client) < 1.0)
	{
		ResetTimer(client);
	}
	
	return Plugin_Stop;
}

bool:ResumeTimer(client)
{
	if(!IsValidClient(client))
		return true;
	if (!g_timers[client][Enabled] || !g_timers[client][IsPaused])
		return false;

	Call_StartForward(g_timerResumedForward);
	Call_PushCell(client);
	Call_Finish();
	
	new mate ;
	if(g_timerTeams) mate = Timer_GetClientTeammate(client);
	if(0 < mate)
	{
		g_timers[mate][IsPaused] = false;
		g_timers[mate][PauseTotalTime] += GetGameTime() - g_timers[mate][PauseStartTime];
		new Float:origin2[3];
		Array_Copy(g_timers[mate][PauseLastOrigin], origin2, 3);

		new Float:angles2[3];
		Array_Copy(g_timers[mate][PauseLastAngles], angles2, 3);

		new Float:velocity2[3];
		Array_Copy(g_timers[mate][PauseLastVelocity], angles2, 3);

		if(IsClientInGame(mate)) TeleportEntity(mate, origin2, angles2, velocity2);
	}

	new Float:origin[3];
	Array_Copy(g_timers[client][PauseLastOrigin], origin, 3);

	new Float:angles[3];
	Array_Copy(g_timers[client][PauseLastAngles], angles, 3);

	new Float:velocity[3];
	Array_Copy(g_timers[client][PauseLastVelocity], angles, 3);

	TeleportEntity(client, origin, angles, velocity);
	
	CreateTimer(0.0, TResumed, client, TIMER_FLAG_NO_MAPCHANGE);
	
	return true;
}

public Action:TResumed(Handle:timer, any:client)
{
	if(!IsClientInGame(client))
	return Plugin_Handled;

	if(!IsPlayerAlive(client))
	return Plugin_Handled;
	
	g_timers[client][IsPaused] = false;
	g_timers[client][PauseTotalTime] += GetGameTime() - g_timers[client][PauseStartTime];
	
	return Plugin_Handled;
}

ClearCache()
{
	for (new client = 1; client <= MaxClients; client++)
		ClearClientCache(client);
}

ClearClientCache(client)
{
	g_bestTimeCache[client][IsCached] = false;
	g_bestTimeCache[client][Jumps] = 0;
	g_bestTimeCache[client][Time] = 0.0;	
}

FinishRound(client, const String:map[], Float:time, jumps, mode, fpsmax, bonus)
{
	if (!IsClientInGame(client))
		return;
	if (IsFakeClient(client))
		return;
	
	decl String:auth[32];
	GetClientAuthString(client, auth, sizeof(auth));
	
	//ignore unranked
	if(g_timerPhysics) 
		if (g_Physics[mode][ModeCategory] != MCategory_Ranked || !(bool:Timer_IsModeRanked(mode)))
			return;
	
	//short end already triggered
	if (g_timers[client][ShortEndReached] && bonus == 2)
		return;
	
	if (time < 1.0)
	{
		Timer_Log(Timer_LogLevelWarning, "Detected illegal record by %N on %s [time:%.2f|mode:%d|bonus:%d|jumps:%d] SteamID: %s", client, g_currentMap, time, mode, bonus, jumps, auth);
		return;
	}
	if (Timer_GetScripter(client))
	{
		Timer_Log(Timer_LogLevelWarning, "Detected scripter record by %N on %s [time:%.2f|mode:%d|bonus:%d|jumps:%d] SteamID: %s", client, g_currentMap, time, mode, bonus, jumps, auth);
		return;
	}
	
	if(bonus == 2) g_timers[client][ShortEndReached] = true;
	
	//Record Info
	new RecordId;
	new Float:RecordTime;
	new RankTotal;
	
	//Personal Record
	new currentrank;	
	if(g_timerWorldRecord) currentrank = Timer_GetDifficultyRank(client, bonus, mode);	
	new newrank;
	if(g_timerWorldRecord) newrank = Timer_GetNewPossibleRank(mode, bonus, time);
	
	new Float:LastTime;
	new Float:LastTimeStatic;
	new LastJumps;
	decl String:TimeDiff[32];
	decl String:buffer[32];
	
	new bool:NewPersonalRecord = false;
	new bool:NewWorldRecord = false;
	new bool:FirstRecord = false;
	
	new Float:jumpacc;
	if(g_timerPhysics) Timer_GetJumpAccuracy(client, jumpacc);
	
	new strafes, strafes_boosted, Float:strafeacc;
	if(g_timerStrafes) strafes = Timer_GetStrafeCount(client);
	if(g_timerStrafes) strafes_boosted = Timer_GetBoostedStrafeCount(client);
	
	if(strafes < 1)
	{
		strafes = 1;
	}
	
	strafeacc = 100.0-(100.0*(float(strafes_boosted)/float(strafes)));
	
	//get speed
	new Float:maxspeed;
	if(g_timerPhysics) Timer_GetMaxSpeed(client, maxspeed);
	new Float:currentspeed;
	Timer_GetCurrentSpeed(client, currentspeed);
	new Float:avgspeed;
	if(g_timerPhysics) Timer_GetAvgSpeed(client, avgspeed);

	//Player Info

	decl String:name[MAX_NAME_LENGTH];
	GetClientName(client, name, sizeof(name));

	decl String:safeName[2 * strlen(name) + 1];
	SQL_EscapeString(g_hSQL, name, safeName, 2 * strlen(name) + 1);
	
	/* Get Personal Record */
	if(g_timerWorldRecord && Timer_GetBestRound(client, mode, bonus, LastTime, LastJumps))
	{
		LastTimeStatic = LastTime;
		LastTime -= time;			
		if(LastTime < 0.0)
		{
			LastTime *= -1.0;
			Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
			Format(TimeDiff, sizeof(TimeDiff), "+%s", buffer);
		}
		else if(LastTime > 0.0)
		{
			Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
			Format(TimeDiff, sizeof(TimeDiff), "-%s", buffer);
		}
		else if(LastTime == 0.0)
		{
			Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
			Format(TimeDiff, sizeof(TimeDiff), "%s", buffer);
		}
	}
	else
	{
		//No personal record, this is his first record
		FirstRecord = true;
		LastTime = 0.0;
		Timer_SecondsToTime(LastTime, buffer, sizeof(buffer), 3);
		Format(TimeDiff, sizeof(TimeDiff), "%s", buffer);
		RankTotal++;
	}

	/* Get World Record */
	if(g_timerWorldRecord) Timer_GetDifficultyRecordTime(mode, bonus, RecordId, RecordTime, RankTotal);
	
	/* Detect Record Type */
	if(RecordTime == 0.0 || time < RecordTime)
	{
		NewWorldRecord = true;
	}
	
	if(LastTimeStatic == 0.0 || time < LastTimeStatic)
	{
		NewPersonalRecord = true;
	}
	
	new oldrecordid;
	if(g_timerWorldRecord) oldrecordid = Timer_GetRankID(mode, bonus, currentrank);
	
	//Delete old record
	if(!FirstRecord && NewPersonalRecord)
	{
		decl String:query[512];
		Format(query, sizeof(query), "DELETE FROM `round` WHERE id = %d", oldrecordid);	

		SQL_TQuery(g_hSQL, DeleteRecordCallback, query, client, DBPrio_Normal);
	}
	
	new count;
	if(g_timerWorldRecord) count = Timer_GetFinishCount(mode, bonus, currentrank);
	count ++;
	
	if(FirstRecord || NewPersonalRecord)
	{
		//CPrintToChat(client, "%s{blue} Your record has been saved.", PLUGIN_PREFIX2);
		
		//Save record
		decl String:query2[1024];
		Format(query2, sizeof(query2), "INSERT INTO round (map, auth, time, jumps, physicsdifficulty, name, fpsmax, bonus, rank, jumpacc, maxspeed, avgspeed, finishspeed, finishcount, strafes, strafeacc) VALUES ('%s', '%s', %f, %d, %d, '%s', %d, %d, %d, %f, %f, %f, %f, %d, %d, %f);", map, auth, time, jumps, mode, safeName, fpsmax, bonus, newrank, jumpacc, maxspeed, avgspeed, currentspeed, count, strafes, strafeacc);
			
		SQL_TQuery(g_hSQL, FinishRoundCallback, query2, client, DBPrio_High);
	}
	else
	{
		decl String:query2[512];
		Format(query2, sizeof(query2), "UPDATE `round` SET finishcount = %d WHERE id = %d", count, oldrecordid);
		SQL_TQuery(g_hSQL, FinishRoundCallback, query2, client, DBPrio_High);
	}
	
	/* Forwards */
	Call_StartForward(g_timerRecordForward);
	Call_PushCell(client);
	Call_PushCell(bonus);
	Call_PushCell(mode);
	Call_PushCell(time);
	Call_PushCell(LastTimeStatic);
	Call_PushCell(currentrank);
	Call_PushCell(newrank);
	Call_Finish();
	
	if(NewWorldRecord)
	{
		Call_StartForward(g_timerWorldRecordForward);
		Call_PushCell(client);
		Call_PushCell(bonus);
		Call_PushCell(mode);
		Call_PushCell(time);
		Call_PushCell(LastTimeStatic);
		Call_PushCell(currentrank);
		Call_PushCell(newrank);
		Call_Finish();
	}
	
	if(NewPersonalRecord)
	{
		Call_StartForward(g_timerPersonalRecordForward);
		Call_PushCell(client);
		Call_PushCell(bonus);
		Call_PushCell(mode);
		Call_PushCell(time);
		Call_PushCell(LastTimeStatic);
		Call_PushCell(currentrank);
		Call_PushCell(newrank);
		Call_Finish();
	}
	
	if(newrank <= 10)
	{
		Call_StartForward(g_timerTop10RecordForward);
		Call_PushCell(client);
		Call_PushCell(bonus);
		Call_PushCell(mode);
		Call_PushCell(time);
		Call_PushCell(LastTimeStatic);
		Call_PushCell(currentrank);
		Call_PushCell(newrank);
		Call_Finish();
	}
	
	if(FirstRecord)
	{
		Call_StartForward(g_timerFirstRecordForward);
		Call_PushCell(client);
		Call_PushCell(bonus);
		Call_PushCell(mode);
		Call_PushCell(time);
		Call_PushCell(LastTimeStatic);
		Call_PushCell(currentrank);
		Call_PushCell(newrank);
		Call_Finish();
	}
}

public DeleteRecordCallback(Handle:owner, Handle:hndl, const String:error[], any:client)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on DeleteRecord: %s", error);
		return;
	}
}

public UpdateNameCallback(Handle:owner, Handle:hndl, const String:error[], any:param1)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on UpdateName: %s", error);
		return;
	}
}

public DeletePlayersRecordCallback(Handle:owner, Handle:hndl, const String:error[], any:param1)
{
	if (hndl == INVALID_HANDLE)
	{
		Timer_LogError("SQL Error on DeletePlayerRecord: %s", error);
		return;
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
	//PrintToChat(client, "Your stats have been stored into our database, thank you.");
	
	if(g_timerWorldRecord) Timer_ForceReloadCache();
}

GetTotalRank(const String:map[], bonus)
{
	decl String:sQuery[512], String:sError[255];
	FormatEx(sQuery, sizeof(sQuery), "SELECT m.id, m.auth, m.time, MAX(m.jumps) jumps, m.physicsdifficulty, m.name FROM round AS m INNER JOIN (SELECT MIN(n.time) time, n.auth FROM round n WHERE n.map = '%s' AND n.bonus = '%d' GROUP BY n.physicsdifficulty, n.auth) AS j ON (j.time = m.time AND j.auth = m.auth) WHERE m.map = '%s' AND m.bonus = '%d' GROUP BY m.physicsdifficulty, m.auth", map, bonus, map, bonus);

	SQL_LockDatabase(g_hSQL);

	new Handle:hQuery = SQL_Query(g_hSQL, sQuery);

	if (hQuery == INVALID_HANDLE)
	{
		SQL_GetError(g_hSQL, sError, sizeof(sError));
		Timer_LogError("SQL Error on GetTotalRank: %s", sError);
		SQL_UnlockDatabase(g_hSQL);
		return;
	}

	SQL_UnlockDatabase(g_hSQL);

	if(bonus == 1) g_iTotalRankCacheBonus = SQL_GetRowCount(hQuery);
	else if(bonus == 2) g_iTotalRankCacheShort = SQL_GetRowCount(hQuery);
	else g_iTotalRankCache = SQL_GetRowCount(hQuery);

	CloseHandle(hQuery);
}

GetCurrentRank(client, const String:map[], bonus)
{
	decl String:sQuery[512], String:sError[255];
	FormatEx(sQuery, sizeof(sQuery), "SELECT m.id, m.auth, m.time, MAX(m.jumps) jumps, m.physicsdifficulty, m.name FROM round AS m INNER JOIN (SELECT MIN(n.time) time, n.auth FROM round n WHERE n.map = '%s' AND n.bonus = '%d' AND n.time <= %f GROUP BY n.physicsdifficulty, n.auth) AS j ON (j.time = m.time AND j.auth = m.auth) WHERE m.map = '%s' AND m.bonus = '%d' AND m.time <= %f GROUP BY m.physicsdifficulty, m.auth", map, g_bestTimeCache[client][Time] + 0.0001, map, g_bestTimeCache[client][Time] + 0.0001);

	SQL_LockDatabase(g_hSQL);

	new Handle:hQuery = SQL_Query(g_hSQL, sQuery);

	if (hQuery == INVALID_HANDLE)
	{
		SQL_GetError(g_hSQL, sError, sizeof(sError));
		Timer_LogError("SQL Error on GetCurrentRank: %s", sError);
		SQL_UnlockDatabase(g_hSQL);
		return;
	}

	SQL_UnlockDatabase(g_hSQL);

	if(bonus == 1) g_iCurrentRankCacheBonus[client] = SQL_GetRowCount(hQuery);
	else if(bonus == 2) g_iCurrentRankCacheShort[client] = SQL_GetRowCount(hQuery);
	else g_iCurrentRankCache[client] = SQL_GetRowCount(hQuery);

	CloseHandle(hQuery);
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
	db_createTables(driver);
	
	g_reconnectCounter = 1;
}

public db_createTables(String:driver[16])
{
	SQL_LockDatabase(g_hSQL);

	if (StrEqual(driver, "mysql", false))
	{
		SQL_FastQuery(g_hSQL, "SET NAMES  'utf8'");
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `round` (`id` int(11) NOT NULL AUTO_INCREMENT, `map` varchar(32) NOT NULL, `auth` varchar(32) NOT NULL, `time` float NOT NULL, `jumps` int(11) NOT NULL, `jumpacc` float NOT NULL, `strafes` int(11) NOT NULL, `strafeacc` float NOT NULL, `avgspeed` float NOT NULL, `maxspeed` float NOT NULL, `finishspeed` float NOT NULL, `flashbangcount` int(11) NOT NULL, `rank` int(11) NOT NULL, `replaypath` varchar(32) NOT NULL, `finishcount` int(11) NOT NULL, `physicsdifficulty` int(11) NOT NULL, `name` varchar(64) CHARACTER SET utf8 NOT NULL, `fpsmax` int(11) NOT NULL, `bonus` int(11) NOT NULL, PRIMARY KEY (`id`), date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);");
	}
	else if (StrEqual(driver, "sqlite", false))
	{
		SQL_TQuery(g_hSQL, CreateSQLTableCallback, "CREATE TABLE IF NOT EXISTS `round` (`id` INTEGER PRIMARY KEY, `map` varchar(32) NOT NULL, `auth` varchar(32) NOT NULL, `time` float NOT NULL, `jumps` INTEGER NOT NULL, `jumpacc` float NOT NULL, `strafes` INTEGER NOT NULL, `strafeacc` float NOT NULL, `avgspeed` float NOT NULL, `maxspeed` float NOT NULL, `flashbangcount` INTEGER NOT NULL, `rank` INTEGER NOT NULL, `replaypath` varchar(32) NOT NULL, `finishcount` INTEGER NOT NULL, `physicsdifficulty` INTEGER NOT NULL, `name` varchar(64) NOT NULL, `fpsmax` INTEGER NOT NULL), `bonus` INTEGER NOT NULL, date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP);");
	}

	SQL_UnlockDatabase(g_hSQL);
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

public Native_Reset(Handle:plugin, numParams)
{
	return ResetTimer(GetNativeCell(1));
}

public Native_Start(Handle:plugin, numParams)
{
	return StartTimer(GetNativeCell(1));
}

public Native_Stop(Handle:plugin, numParams)
{
	return StopTimer(GetNativeCell(1), bool:GetNativeCell(2));
}

public Native_Restart(Handle:plugin, numParams)
{
	return RestartTimer(GetNativeCell(1));
}

public Native_Resume(Handle:plugin, numParams)
{
	if(g_Settings[PauseEnable])
		return ResumeTimer(GetNativeCell(1));
	else
		return false;
}

public Native_Pause(Handle:plugin, numParams)
{
	if(g_Settings[PauseEnable])
		return PauseTimer(GetNativeCell(1));
	else
		return StopTimer(GetNativeCell(1));
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
	new mode = GetNativeCell(5);
	new fpsmax = GetNativeCell(6);
	new bonus = GetNativeCell(7);
	
	FinishRound(client, map, time, jumps, mode, fpsmax, bonus);
}

public Native_ForceClearCacheBest(Handle:plugin, numParams)
{
	ClearCache();
}

public Native_SetBonus(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new newmode = GetNativeCell(2);
	g_timers[client][Bonus] = newmode;
}

public Native_GetBonus(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_timers[client][Bonus];
}

public Native_GetMapFinishCount(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_timers[client][FinishCount];
}

public Native_GetMapFinishBonusCount(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_timers[client][BonusFinishCount];
}

public Native_SetMode(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new newmode = GetNativeCell(2);
	
	g_timers[client][CurrentMode] = newmode;
	if(g_timerPhysics) Timer_ApplyPhysics(client);
}

public Native_AddPenaltyTime(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new Float:penaltytime = GetNativeCell(2);
	return TimerPenalty(client, penaltytime);
}

public Native_GetMode(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return g_timers[client][CurrentMode];
}

public Native_GetStatus(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return (g_timers[client][Enabled] && !g_timers[client][IsPaused]);
}

public Native_GetPauseStatus(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	return (g_timers[client][IsPaused]);
}

public Native_IsModeRanked(Handle:plugin, numParams)
{
	new mode = GetNativeCell(1);
	
	return (g_Physics[mode][ModeCategory] == MCategory_Ranked);
}

public Native_GetTotalRank(Handle:plugin, numParams)
{
	new bool:update = bool:GetNativeCell(1);
	new bonus = GetNativeCell(2);
	if (update)
	{
		GetTotalRank(g_currentMap, bonus);
	}
	if(bonus == 1) return g_iTotalRankCacheBonus;
	else if(bonus == 1) return g_iTotalRankCacheShort;
		else return g_iTotalRankCache;
}

public Native_GetCurrentRank(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new bool:update = bool:GetNativeCell(2);
	new bonus = GetNativeCell(3);
	if (update)
	{
		GetCurrentRank(client, g_currentMap, bonus);
	}
	if(bonus == 1) return g_iCurrentRankCacheBonus[client];
	else if(bonus == 2) return g_iCurrentRankCacheShort[client];
		else return g_iCurrentRankCache[client];
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

// CREDITS
public Action:Command_Credits(client, args)
{
	CreditsPanel(client);
	
	return Plugin_Handled;
}

public CreditsPanel(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer Credits -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 8);
	else SetPanelCurrentKey(panel, 9);
	
	DrawPanelText(panel, "     -- Page 1/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "Zipcore - Creator and Main Coder of plugin");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "Alongub - Old Timer Core");
	DrawPanelText(panel, "Shavit - Added new features and supported plugin");
	DrawPanelText(panel, "Paduh - Rankings system");
	DrawPanelText(panel, "Das D - Chatrank, Player Info, Timer Info, Chatextension");
	DrawPanelText(panel, "DaFox - MultiPlayer Bunny Hops");
	DrawPanelText(panel, "Peace-Maker - Bot Mimic 2, Backwards and more");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, CreditsHandler1, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public CreditsHandler1 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 8:
				{
					CreditsPanel2(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 9:
				{
					CreditsPanel2(param1);
				}
			}
		}
    }
}

public CreditsPanel2(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer Credits -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "     -- Page 2/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "0wn3r - Many small improvements");
	DrawPanelText(panel, "Justshoot - LJ Stats");
	DrawPanelText(panel, "DieterM75 - Checkpoint System");
	DrawPanelText(panel, "Skippy - Trigger Hooks");
	DrawPanelText(panel, "GoD-Tony - AutoTrigger Detection");
	DrawPanelText(panel, "Miu - Strafe Stats");
	DrawPanelText(panel, "Inami - Macrodox Detection");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, CreditsHandler2, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public CreditsHandler2 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					CreditsPanel(param1);
				}
				case 8:
				{
					CreditsPanel3(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					CreditsPanel(param1);
				}
				case 9:
				{
					CreditsPanel3(param1);
				}
			}
		}
    }
}

public CreditsPanel3(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer Credits -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "     -- Page 3/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "SMAC Team - Trigger Detection");
	DrawPanelText(panel, "Jason Bourne - Challenge, Custom-HUD");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -");
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, CreditsHandler3, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public CreditsHandler3 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					CreditsPanel2(param1);
				}
				case 8:
				{
					CreditsPanel4(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					CreditsPanel2(param1);
				}
				case 9:
				{
					CreditsPanel4(param1);
				}
			}
		}
    }
}

public CreditsPanel4(client)
{
	new Handle:panel = CreatePanel();
	SetPanelTitle(panel, "- DMT|Timer Credits -");
	
	if(mod == MOD_CSGO) SetPanelCurrentKey(panel, 7);
	else SetPanelCurrentKey(panel, 8);
	
	DrawPanelText(panel, "     -- Page 4/4 --");
	DrawPanelText(panel, " ");
	DrawPanelText(panel, "   ---- Special Thanks ----");
	DrawPanelText(panel, "AlliedModders, .#IsKulT, Jacky, Shadow[DK],");
	DrawPanelText(panel, "Korki, Joy, Blackpanther, Popping-Fresh,");
	DrawPanelText(panel, "Dirthy Secret, KackEinKrug, Blackout, Cru,");
	DrawPanelText(panel, "Shadow, Schoschy, Extan, cREANy0,");
	DrawPanelText(panel, "Kolapsicle, DevilHunterMultigaming, ");
	DrawPanelText(panel, "and many others");
	DrawPanelText(panel, " ");
	DrawPanelItem(panel, "- Back -");
	DrawPanelItem(panel, "- Next -", ITEMDRAW_SPACER);
	DrawPanelItem(panel, "- Exit -");
	SendPanelToClient(panel, client, CreditsHandler4, MENU_TIME_FOREVER);

	CloseHandle(panel);
}

public CreditsHandler4 (Handle:menu, MenuAction:action,param1, param2)
{
    if ( action == MenuAction_Select )
    {
		if(mod == MOD_CSGO) 
		{
			switch (param2)
			{
				case 7:
				{
					CreditsPanel3(param1);
				}
			}
		}
		else
		{
			switch (param2)
			{
				case 8:
				{
					CreditsPanel3(param1);
				}
			}
		}
    }
}