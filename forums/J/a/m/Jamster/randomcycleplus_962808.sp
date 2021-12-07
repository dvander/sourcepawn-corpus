/**
 * =====================================================================================
 * RandomCycle+
 *
 * Created by Jamster.
 * =====================================================================================
 *
 * Changelog:
 *
 * 1.0
 * - Initial release.
 *
 * 1.0.1
 * - Added code to detect duplicate maps.
 *
 * 1.0.2
 * - Fixed parsing errors on reading the config file with comments in.
 *
 * 1.0.3
 * - Spelling fixes.
 * - Slightly more optimised when checking player counts.
 *
 * 1.0.4
 * - Added cvar to instantly change the nextmap on mapstart.
 *
 * 1.0.5
 * - Added cvar to enable/disable checking for duplicate maps for the whole cycle.
 * - Added a further check to check for duplicates in the tier itself (this is always enabled due to the nature of the plugin).
 *
 * 1.0.6
 * - Added rtv code to plugin to simply skip to nextmap, other commands added.
 * - Increased string sizes for map names for safety.
 * - Other very small fixes, code optimisation/organisation.
 *
 * 1.0.7
 * - Fixed disconnect player bug for rtv.
 * - Fixed some handles.
 *
 * 1.0.7a
 * - Very small fix with max high player cvar value.
 *
 * 1.0.7b
 * - Fixed a mistake in the RTV code.
 *
 * 1.0.7c
 * - Code cleanup.
 * - Added sm_rcplus_disablehightier to default code.
 *
 * 1.0.7d
 * - Fixed a small code inconsistency with disabling the high tier.
 * - Fixed plugin version.
 *
 * 1.0.7e
 * - Fixed "disabling plugin" log bug.
 *
 * 1.0.8
 * - Fixed internal rtv not disabling when it should.
 * - Fixed log errors when the plugin uses the normal cycle (I hope).
 *
 * 1.1.0
 * - Added cvar to enable single tier mode.
 * - Fixed min value for disable high tier.
 * - Cleaned up and optimised a lot of the code.
 * - Made the disable high tier code a lot better.
 *
 * 1.1.1
 * - Small code fixes.
 * - RTV portion of the code reworked to hopefully stop the ghostly passing.
 * - Disabling of high tier takes into account if the server population dips in-between maps.
 * - If the single tier happens to get disabled the timer check will start up again and continue to check for players, single tier cvar change now hooked too so it will instantly enable or disable.
 * - Disabled check array command in default build, uncomment to enable again if you wish, but this command is now defunct.
 *
 * 1.1.1a
 * - Fixed start of map check not working.
 *
 * 1.2.0
 * - Map history code now drastically recoded, will now remember the FULL past high, medium and low tier maps rather than not using the past x maps recently played.
 * - Cvar added to control the size of the internal RC+ maphistory.
 *
 * 1.2.1
 * - Fixed single tier mode history bug.
 *
 * 1.3.0
 * - Added support for time specific rotations.
 * - Improved the map history if using multiple types of tiers.
 * - Optimised single tier mode so you don't need to fill out the other tiers if they are unused on your server.
 * - Removed dupe map check for the whole low to high cycle and the cvar that controls this due to the way the plugin now handles the map history.
 * - Improved error reporting.
 * - A few general optimisations and improvements.
 *
 * 1.3.0a
 * - Small bugfix with single tier mode enabled on startup causing the early nextmap trigger to show.
 *
 * 1.3.1
 * - Added population support to time tiers.
 * - Added in validating of time tiers to check if they clash or not.
 * - Better detection of incorrect cvar values with single tier mode enabled which will let single tier mode to continue.
 * - Time tiers now correctly override single tier mode.
 * - Further small improvements.
 *
 * 1.3.2
 * - Lots of very small fixes.
 * - Added "automatic" cvar value for excludes and is now the new default ("-1") this will automatically exclude roughly 40% of the maps on your list (this value is rounded to the nearest value). Also added a cvar to control this ratio.
 * - Added idle server support, also works with time tiers. Also setup a cvar to control if RC+ rotates through your idle maps or keeps on one idle map until players join the server.
 * - Added PL/EX support to normal tiers.
 * - Changed mapstart check default to 1.
 * - Removed max time restriction on main rc+ check time setting.
 *
 * 1.3.2.1
 * - Fixed closing the timer when applicable for the main check when single tier mode is enabled mid game. 
 * - Error handling improved with single tier mode enabled.
 * - Fixed setting regular time tier to automatic exclude.
 *
 * 1.3.2.2
 * - Added lots of debug code. Not operational by default though (requires a recompile).
 * - Adjusted some of the RC+ checks to do with time tiers and single tier.
 * - Fixed some mistakes in the exclude values.
 * - Optimised a lot of the checks and a few small fixes.
 * - Temp fix for a huge parsing bug (big props to DontWannaName, cheers man).
 *
 * 1.4.0
 * - Fixed that parsing bug for real now!
 * - Main tiers renamed and single time tiers have now changed, PLEASE CHECK THE NEW CONFIGURATION FILE, this is to avoid possible conflicts.
 * - General code facelift, performence is now vastly optimised.
 * - Removed RTV code, seperate modified plugins are better for this.
 * - Removed the basetriggers detection code, not really needed now.
 * - Added extra idle tier support to regular single time tiers.
 * - Added +/- support to time tiers. This is so you can easily add or remove maps from a tier during certain times.
 * - Provided better fallbacks if anything goes wrong rather than halting the plugin.
 * - Better error feedback.
 * - Added a cvar to control where the rc+ configuration file is. Defaults to randomcycleplus.cfg in the config folder in SM root when not set.
 * - Fixed some translation errors and trimmed the file itself.
 * - Re-done the config file to show better examples on how to set it up.
 * - Added "automatic" (-1) settings for player load cvar's. Also new default. Less than equals 1/3 for low, more than equals 2/3 for high. Rounds to nearest.
 * - Cleaned up comments in the code a bit!
 *
 * 1.4.0a
 * - Fixed a small bug in the +/- time tier code.
 * 
 * 1.4.0b
 * - Fixed idle tier code not checking on player disconnect.
 * - Some other small optimisations.
 *
 * 1.4.1
 * - Small fixes to string index's and debug code, fixes a pretty major map picking bug.
 * - Added slight delay to initial mapstart check (basically waits long enough so it can check for connected players).
 * =====================================================================================
 */

// Debug mode for me really, enable it if you want to see what's going on or I tell you to put it on!
#define DEBUG 1

// Values for arrays, easier to change here if I add/remove anything.
#define M_OLD 0
#define M_LOW 1
#define M_MED 2
#define M_HIGH 3
#define M_SINGLE 4
#define M_IDLE 5
#define M_TOTAL 6
#define M_NONE 7

#pragma semicolon 1
#include <sourcemod>
#define RCP_VERSION "1.4.1"
#define RCP_TRANSLOADED switch (b_TransLoaded) { case true:

public Plugin:myinfo =
{
	name = "RandomCycle+",
	author = "Jamster",
	description = "Random maplists with options for player population tiers and time based tiers. Includes idle server support.",
	version = RCP_VERSION,
	url = "http://www.sourcemod.net/"
};

new Handle:cvar_ExMapsLow = INVALID_HANDLE;
new Handle:cvar_ExMapsMed = INVALID_HANDLE;
new Handle:cvar_ExMapsHigh = INVALID_HANDLE;
new Handle:cvar_ExMapsSingle = INVALID_HANDLE;
new Handle:cvar_ExMapsIdle = INVALID_HANDLE;
new Handle:cvar_ExMapsRatio = INVALID_HANDLE;
new Handle:cvar_LowPlayerCount = INVALID_HANDLE;
new Handle:cvar_HighPlayerCount = INVALID_HANDLE;
new Handle:cvar_PlayerCheckTime = INVALID_HANDLE;
new Handle:cvar_Announce = INVALID_HANDLE;
new Handle:cvar_LogMSG = INVALID_HANDLE;
new Handle:cvar_NextMapHide = INVALID_HANDLE;
new Handle:cvar_MapStartCheck = INVALID_HANDLE;
new Handle:cvar_DisableHighTier = INVALID_HANDLE;
new Handle:cvar_SingleTier = INVALID_HANDLE;
new Handle:cvar_MapHistorySize = INVALID_HANDLE;
new Handle:cvar_UseTimeTiers = INVALID_HANDLE;
new Handle:cvar_IdleTime = INVALID_HANDLE;
new Handle:cvar_UseIdleTier = INVALID_HANDLE;
new Handle:cvar_IdleRotate = INVALID_HANDLE;
new Handle:cvar_FilePath = INVALID_HANDLE;

new Handle:OML_Master = INVALID_HANDLE;
new Handle:ML[M_TOTAL] = INVALID_HANDLE;
new Handle:g_TimeTierTimes = INVALID_HANDLE;
new Handle:g_NextMap = INVALID_HANDLE;
new flags_g_NextMap;
new oldflags_g_NextMap;
new Handle:h_RandomCycleCheck = INVALID_HANDLE;
new Handle:h_IdleServer = INVALID_HANDLE;

new bool:b_PickMap[M_TOTAL];
new bool:b_Loaded;
new bool:b_NextMapChanged;
new bool:b_DisableHighTier;
new bool:b_UseTimeTier;
new bool:b_UsePopulationTier;
new bool:b_TransLoaded;

new g_Players;
new g_CycleRun;
new g_ExcludeMaps[M_TOTAL];
new g_HighCount;
new p_High;
new p_Low;

new String:MAP[65][M_TOTAL];

#if DEBUG
new String:LogFilePath[PLATFORM_MAX_PATH];
#endif

public OnPluginStart()
{
	new arraySize = ByteCountToCells(65);
	for (new i; i < M_TOTAL; i++)
	{
		ML[i] = CreateArray(arraySize);
	}
	OML_Master = CreateArray(arraySize);
	g_TimeTierTimes = CreateArray(9);
	
	decl String:TransPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, TransPath, sizeof(TransPath), "translations/randomcycleplus.phrases.txt");
	// This is a fallback for people forgetting to install the translation file, allows the plugin to continue and stops error log spam, simply informs the user one time only to install the translation file.
	if (FileExists(TransPath))
	{
		LoadTranslations("randomcycleplus.phrases");
		b_TransLoaded = true;
	} 
	else 
	{
		LogError("RandomCycle+ is unable to locate its translation file, please install and reload the plugin");
		b_TransLoaded = false;
	}
	
	CreateConVar("sm_rcplus_version", RCP_VERSION, "RandomCycle+ version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	cvar_ExMapsLow = CreateConVar("sm_rcplus_exclude_low", "-1", "Default setting for the number of most recent maps to remove from possible selection when player population is low (-1 to automatically pick based on tier size)", FCVAR_PLUGIN, true, -1.0);
	cvar_ExMapsMed = CreateConVar("sm_rcplus_exclude_med", "-1", "Default setting for the number of most recent maps to remove from possible selection when player population is medium (-1 to automatically pick based on tier size)", FCVAR_PLUGIN, true, -1.0);
	cvar_ExMapsHigh = CreateConVar("sm_rcplus_exclude_high", "-1", "Default setting for the number of most recent maps to remove from possible selection when player population is high (-1 to automatically pick based on tier size)", FCVAR_PLUGIN, true, -1.0);
	cvar_ExMapsSingle = CreateConVar("sm_rcplus_exclude_single", "-1", "Default setting for the number of most recent maps to remove from possible selection when running single tier mode (-1 to automatically pick based on tier size)", FCVAR_PLUGIN, true, -1.0);
	cvar_ExMapsIdle = CreateConVar("sm_rcplus_exclude_idle", "-1", "Default setting for the number of most recent maps to remove from possible selection when player population is zero (-1 to automatically pick based on tier size)", FCVAR_PLUGIN, true, -1.0);
	cvar_ExMapsRatio = CreateConVar("sm_rcplus_exclude_ratio", "0.4", "Ratio used when using the automatic settings for excluded maps", FCVAR_PLUGIN, true, 0.0, true, 0.99);
	cvar_LowPlayerCount = CreateConVar("sm_rcplus_players_low", "-1", "Populations less than and equal to this value will trigger lower sized maps (0 to disable, -1 to automatically pick based on maxplayers)", FCVAR_PLUGIN, true, -1.0, true, float(MAXPLAYERS));
	cvar_HighPlayerCount = CreateConVar("sm_rcplus_players_high", "-1", "Populations greater than and equal to this value will use higher sized maps (0 to disable, -1 to automatically pick based on maxplayers). Medium tier deactivates when there is no value between this and low players", FCVAR_PLUGIN, true, -1.0, true, float(MAXPLAYERS));
	cvar_PlayerCheckTime = CreateConVar("sm_rcplus_check", "60.0", "How often the plugin checks for players (in seconds)", FCVAR_PLUGIN, true, 10.0);
	cvar_IdleTime = CreateConVar("sm_rcplus_idletime", "320.0", "When the server should switch to an idle map when the server is empty (in seconds)", FCVAR_PLUGIN, true, 10.0);
	cvar_IdleRotate = CreateConVar("sm_rcplus_idlerotate", "0", "Time in minutes that the server should change to another idle map if it's already on an idle map with no players (0 to disable, stay on current idle map)", FCVAR_PLUGIN, true, 0.0);
	cvar_Announce = CreateConVar("sm_rcplus_announce", "0", "If RandomCycle+ changes the nextmap, should it announce that it has?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_LogMSG = CreateConVar("sm_rcplus_logmessage", "0", "If RandomCycle+ changes the nextmap, should it log that it has?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_NextMapHide = CreateConVar("sm_rcplus_hidenextmap", "0", "If RandomCycle+ changes the nextmap, should it hide the \"sm_nextmap\" convar change?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MapStartCheck = CreateConVar("sm_rcplus_checkmapstart", "1", "Should RandomCycle+ check for players and change the nextmap instantly at the start of the map?", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_DisableHighTier = CreateConVar("sm_rcplus_disablehightier", "0", "Disables the high tier after every x high tier maps in a row (0 to disable, 1 or more to enable)", FCVAR_PLUGIN, true, 0.0);
	cvar_SingleTier = CreateConVar("sm_rcplus_singletiermode", "0", "If enabled this disables all population tiers and uses the single tier maplist", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MapHistorySize = CreateConVar("sm_rcplus_maphistorysize", "40", "How many recent maps RandomCycle+ remembers to compare against the map tiers", FCVAR_PLUGIN, true, 30.0);
	cvar_UseTimeTiers = CreateConVar("sm_rcplus_timetiers", "0", "If enabled this activates the time tiers you have specified in the RandomCycle+ configuration file", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_UseIdleTier = CreateConVar("sm_rcplus_idle", "0", "If enabled this activates the idle maps you have specified in the RandomCycle+ configuration file", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_FilePath = CreateConVar("sm_rcplus_file", "default", "File path and file name to the RandomCycle+ configuration file (e.g. /cfg/rcplus.cfg, default is randomcycleplus.cfg in your sourcemod configs folder)", FCVAR_PLUGIN);
	
	RegAdminCmd("sm_rcplus_reload", Command_Reload, ADMFLAG_CHANGEMAP, "Reloads RandomCycle+ maplists");
	RegAdminCmd("sm_rcplus_resume", Command_Resume, ADMFLAG_CHANGEMAP, "Resumes RandomCycle+ if the nextmap has been changed externally");
	
	g_NextMap = FindConVar("sm_nextmap");
	
	HookConVarChange(g_NextMap, RCP_ConVarChanged_NextMap);
	HookConVarChange(cvar_SingleTier, RCP_ConVarChanged_ReloadTiers);
	HookConVarChange(cvar_UseTimeTiers, RCP_ConVarChanged_ReloadTiers);
	HookConVarChange(cvar_ExMapsSingle, RCP_ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_ExMapsIdle, RCP_ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_ExMapsHigh, RCP_ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_ExMapsMed, RCP_ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_ExMapsLow, RCP_ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_LowPlayerCount, RCP_ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_HighPlayerCount, RCP_ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_UseIdleTier, RCP_ConVarChanged_Idle);
	
	flags_g_NextMap = GetConVarFlags(g_NextMap);
	oldflags_g_NextMap = flags_g_NextMap;
	
	AutoExecConfig(true, "plugin.randomcycleplus");
}
	
public OnConfigsExecuted()
{	
	#if DEBUG
	LogToFileEx(LogFilePath, "sm_rcplus_exclude_low = \"%d\"", GetConVarInt(cvar_ExMapsLow));
	LogToFileEx(LogFilePath, "sm_rcplus_exclude_med = \"%d\"", GetConVarInt(cvar_ExMapsMed));
	LogToFileEx(LogFilePath, "sm_rcplus_exclude_high = \"%d\"", GetConVarInt(cvar_ExMapsHigh));
	LogToFileEx(LogFilePath, "sm_rcplus_exclude_single = \"%d\"", GetConVarInt(cvar_ExMapsSingle));
	LogToFileEx(LogFilePath, "sm_rcplus_exclude_idle = \"%d\"", GetConVarInt(cvar_ExMapsIdle));
	LogToFileEx(LogFilePath, "sm_rcplus_exclude_ratio = \"%f\"", GetConVarFloat(cvar_ExMapsRatio));
	LogToFileEx(LogFilePath, "sm_rcplus_players_low = \"%d\"", GetConVarInt(cvar_LowPlayerCount));
	LogToFileEx(LogFilePath, "sm_rcplus_players_high = \"%d\"", GetConVarInt(cvar_HighPlayerCount));
	LogToFileEx(LogFilePath, "sm_rcplus_check = \"%f\"", GetConVarFloat(cvar_PlayerCheckTime));
	LogToFileEx(LogFilePath, "sm_rcplus_idletime = \"%f\"", GetConVarFloat(cvar_IdleTime)); 
	LogToFileEx(LogFilePath, "sm_rcplus_idlerotate = \"%d\"", GetConVarInt(cvar_IdleRotate)); 
	LogToFileEx(LogFilePath, "sm_rcplus_announce = \"%d\"", GetConVarInt(cvar_Announce)); 
	LogToFileEx(LogFilePath, "sm_rcplus_logmessage = \"%d\"", GetConVarInt(cvar_LogMSG));  
	LogToFileEx(LogFilePath, "sm_rcplus_hidenextmap = \"%d\"", GetConVarInt(cvar_NextMapHide)); 
	LogToFileEx(LogFilePath, "sm_rcplus_checkmapstart = \"%d\"", GetConVarInt(cvar_MapStartCheck)); 
	LogToFileEx(LogFilePath, "sm_rcplus_disablehightier = \"%d\"", GetConVarInt(cvar_DisableHighTier)); 
	LogToFileEx(LogFilePath, "sm_rcplus_singletiermode = \"%d\"", GetConVarInt(cvar_SingleTier)); 
	LogToFileEx(LogFilePath, "sm_rcplus_maphistorysize = \"%d\"", GetConVarInt(cvar_MapHistorySize)); 
	LogToFileEx(LogFilePath, "sm_rcplus_timetiers = \"%d\"", GetConVarInt(cvar_UseTimeTiers)); 
	LogToFileEx(LogFilePath, "sm_rcplus_idle = \"%d\"", GetConVarInt(cvar_UseIdleTier)); 
	#endif
	
	h_IdleServer = INVALID_HANDLE;
	h_RandomCycleCheck = INVALID_HANDLE;
	
	if (GetConVarInt(cvar_DisableHighTier) && GetConVarInt(cvar_DisableHighTier) == g_HighCount && !GetConVarInt(cvar_SingleTier))
	{
		b_DisableHighTier = true;
		g_HighCount = 0;
		#if DEBUG
		LogToFileEx(LogFilePath, "Disabling high tier due to the disable high tier count limit reached."); 
		#endif
	}
	
	// Gets the next map to use if the plugin disables.
	if (b_NextMapChanged)
	{
		GetNextMap(MAP[0][M_OLD], sizeof(MAP));
	}
	else
	{
		if (MAP[0][M_OLD] == '\0')
		{
			// This is usually only need if the plugin updates while the server is running, no fall-back either because it's not the end of the world.
			new Handle:DefaultCycle = CreateArray(65);
			new serial = -1;
			ReadMapList(DefaultCycle, serial, "mapcyclefile", MAPLIST_FLAG_CLEARARRAY|MAPLIST_FLAG_MAPSFOLDER);
			new num = GetRandomInt(0, GetArraySize(DefaultCycle)-1);
			GetArrayString(DefaultCycle, num, MAP[0][M_OLD], sizeof(MAP));
		}
	}
	#if DEBUG
	LogToFileEx(LogFilePath, "Old next map: %s", MAP[0][M_OLD]);
	#endif
	b_NextMapChanged = false;
	
	decl String:CurrentMap[65];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	PushArrayString(OML_Master, CurrentMap);
	
	if (GetArraySize(OML_Master) < GetMapHistorySize())
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "The master history list is smaller than current internal sm maphistory, using sm maphistory.");
		#endif
		RCP_HistoryArray();
	}

	if (GetArraySize(OML_Master) > GetConVarInt(cvar_MapHistorySize))
	{
		RemoveFromArray(OML_Master, 0);
		#if DEBUG
		LogToFileEx(LogFilePath, "Trimmed master map history (current size: %d).", GetArraySize(OML_Master));
		#endif
	}
	
	for (new i; i < M_TOTAL; i++)
	{
		b_PickMap[i] = true;
	}
	
	RCP_LoadMaplist();
	
	b_Loaded = true;
	
	if (!GetConVarInt(cvar_SingleTier))
	{
		h_RandomCycleCheck = CreateTimer(GetConVarFloat(cvar_PlayerCheckTime), t_RandomCycleCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		#if DEBUG
		LogToFileEx(LogFilePath, "Starting main rc+ check timer."); 
		#endif
	}
	
	// Slight delay on start checks so players connected reports right.
	CreateTimer(1.0, t_MapStartCheck, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:t_MapStartCheck(Handle:timer_startcheck)
{
	// Optionally instantly check for players and change nextmap, this is always used if single tier is enabled.
	if (GetConVarInt(cvar_MapStartCheck) || GetConVarInt(cvar_SingleTier))
	{
		#if DEBUG
		if (GetConVarInt(cvar_SingleTier))
		{
			LogToFileEx(LogFilePath, "Single tier mode detected, running main rc+ check."); 
		}
		else if (GetConVarInt(cvar_MapStartCheck))
		{
			LogToFileEx(LogFilePath, "Mapstart check enabled, running main rc+ check."); 
		}
		#endif
		RCP_RandomCycleCheck();
	}
	
	RCP_ServerIdleCheck();
}

public OnMapStart()
{
	#if DEBUG
	decl String:CurrentMap[65];
	decl String:Time[32];
	decl String:LongTime[32];
	FormatTime(Time, sizeof(Time), "%Y%m%d");
	FormatTime(LongTime, sizeof(LongTime), "%d/%m/%Y %H:%M");
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	BuildPath(Path_SM, LogFilePath, sizeof(LogFilePath), "logs/rcplus_debug.log");
	LogToFileEx(LogFilePath, "-- Starting RC+ debug log for map: %s", CurrentMap);
	LogToFileEx(LogFilePath, "-- Start Time: %s ", LongTime);
	#endif
	
	// Reset everything for the plugin to start choosing again.
	g_CycleRun = M_NONE;
	g_Players = 0;
	
	// Usual code for delayed load.
	for (new i=1; i<=MaxClients; i++)
	{
		if (IsClientConnected(i))
		{
			OnClientConnected(i);	
		}	
	}
}

public OnMapEnd()
{
	if ((g_CycleRun == M_HIGH) && GetConVarInt(cvar_DisableHighTier))
	{
		g_HighCount++;
	} 
	else if (GetConVarInt(cvar_DisableHighTier) && g_HighCount > 0)
	{
		g_HighCount = 0;
	}
	
	if (b_DisableHighTier)
	{
		b_DisableHighTier = false;
	}
	
	b_UseTimeTier = false;
	
	b_NextMapChanged = false;
	
	b_Loaded = false;
}

public RCP_ConVarChanged_Idle(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (b_Loaded)
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "Idle mode enabled/disabled, checking settings.");
		#endif
		RCP_ServerIdleCheck();
	}
}

public RCP_ConVarChanged_ReloadTiers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (b_Loaded)
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "Important cvar change, reloading settings.");
		#endif
		RCP_LoadMaplist();
		RCP_RandomCycleCheck();
		if (GetConVarInt(cvar_SingleTier) && (!b_UseTimeTier || !GetConVarInt(cvar_UseTimeTiers)))
		{
			CloseHandle(h_RandomCycleCheck);
			h_RandomCycleCheck = INVALID_HANDLE;
			#if DEBUG
			LogToFileEx(LogFilePath, "Single tier mode is running, no time tiers, killing rc+ check timer.");
			#endif
		}
		RCP_ServerIdleCheck();
	}
}

public OnClientConnected(client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	g_Players++;
	
	if (h_IdleServer != INVALID_HANDLE)
	{
		CloseHandle(h_IdleServer);
		h_IdleServer = INVALID_HANDLE;
		#if DEBUG
		LogToFileEx(LogFilePath, "Killed idle timer due to player connect.");
		#endif
		RCP_RandomCycleCheck();
	}
	
	return;
}

public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	g_Players--;
	
	if (!g_Players)
	{
		RCP_ServerIdleCheck();
	}
	
	return;
}

public Action:t_RandomCycleCheck(Handle:timer_check)
{
	RCP_RandomCycleCheck();
	return Plugin_Continue;
}

public Action:t_IdleServer(Handle:timer_idle)
{
	RCP_GetRandomMap(M_IDLE);
	
	if (GetConVarInt(cvar_LogMSG))
	{
		RCP_TRANSLOADED LogMessage("%t", "RCP Idle Server", MAP[0][M_IDLE]);}
	}
	
	#if DEBUG
	LogToFileEx(LogFilePath, "Idle server, changing map to: %s", MAP[0][M_IDLE]); 
	#endif
	
	ForceChangeLevel(MAP[0][M_IDLE], "Server idle");
	
	return Plugin_Stop;
}

public RCP_ConVarChanged_ReloadMaplist(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (b_Loaded)
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "Player count/exclude value cvar changed, reloading maplists.");
		#endif
		RCP_LoadMaplist();
	}
}

public RCP_ConVarChanged_NextMap(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// If anything happens to change the nextmap externally this will stop the plugin from picking any further changes.
	b_NextMapChanged = true;
}

public Action:Command_Reload(client, args)
{	
	#if DEBUG
	LogToFileEx(LogFilePath, "Reload admin command has been executed.");
	#endif
	RCP_LoadMaplist();
	RCP_RandomCycleCheck();
	RCP_TRANSLOADED ReplyToCommand(client, "[SM] %t", "RCP Reloaded");}
	RCP_TRANSLOADED LogMessage("\"%L\" %t", client, "RCP Reloaded Log");}
	return Plugin_Handled;
}

public Action:Command_Resume(client, args)
{	
	// Admins can run this to resume the plugin if needed.
	#if DEBUG
	LogToFileEx(LogFilePath, "Resume admin command has been executed.");
	#endif
	b_NextMapChanged = false;
	g_CycleRun = M_NONE;
	RCP_RandomCycleCheck();
	RCP_TRANSLOADED ShowActivity2(client, "%t", "RCP Resumed");}
	RCP_TRANSLOADED LogMessage("\"%L\" %t", client, "RCP Resumed");}
	return Plugin_Handled;
}

//======================================================================================================//
//======================================================================================================//
//======================================================================================================//

RCP_LoadMaplist()
{
	#if DEBUG
	LogToFileEx(LogFilePath, "Loading maplists."); 
	#endif
	
	g_ExcludeMaps[M_SINGLE] = GetConVarInt(cvar_ExMapsSingle);
	g_ExcludeMaps[M_HIGH] = GetConVarInt(cvar_ExMapsHigh);
	g_ExcludeMaps[M_MED] = GetConVarInt(cvar_ExMapsMed);
	g_ExcludeMaps[M_LOW] = GetConVarInt(cvar_ExMapsLow);
	g_ExcludeMaps[M_IDLE] = GetConVarInt(cvar_ExMapsIdle);
	
	decl String:ConfigPath[PLATFORM_MAX_PATH];
	decl String:ConVarPath[PLATFORM_MAX_PATH];
	GetConVarString(cvar_FilePath, ConVarPath, sizeof(ConVarPath));
	if (StrEqual(ConVarPath, "default", false))
	{
		BuildPath(Path_SM, ConfigPath, sizeof(ConfigPath), "configs/randomcycleplus.cfg");
	}
	else
	{
		ConfigPath = ConVarPath;
	}
	
	if (!FileExists(ConfigPath))
	{
		RCP_TRANSLOADED LogError("%t", "RCP No Config");}
		p_Low = 0;
		p_High = 0;
		return;
	}
	
	new Handle:h_configfile = OpenFile(ConfigPath, "r");
	if (h_configfile == INVALID_HANDLE)
	{
		RCP_TRANSLOADED LogError("%t", "RCP No Read Config");}
		p_Low = 0;
		p_High = 0;
		return;
	}
		
	for (new i; i < M_TOTAL; i++)
	{
		ClearArray(ML[i]);
	}
	ClearArray(g_TimeTierTimes);

	new bool:b_NoMedmaplist = false;
	p_High = GetConVarInt(cvar_HighPlayerCount);
	p_Low = GetConVarInt(cvar_LowPlayerCount);
	b_UseTimeTier = false;
	new SingleTierMode = GetConVarInt(cvar_SingleTier);
	new TimeTierMode = GetConVarInt(cvar_UseTimeTiers);
	new p_Total = MaxClients;
	
	decl String:line[255];
	new ConfigFilePosition;
	new bool:TimeTierFound = false;
	new bool:SearchForPopTiers = false;
	decl String:CurrentTimeTier[65];
	decl String:TimeTierConflict[65];
	decl String:map[65];
	
	new Handle:MaplistArray = CreateArray(65);
	new serial;
	new arraySize;
	ReadMapList(ML[M_HIGH], serial, "sm_rcplus_high", MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_CLEARARRAY);
	ReadMapList(ML[M_LOW], serial, "sm_rcplus_low", MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_CLEARARRAY);
	
	while(!IsEndOfFile(h_configfile))
	{
		ReadFileLine(h_configfile, line, sizeof(line));
		TrimString(line);
		if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
		{
			BreakString(line, line, sizeof(line));
			if (!StrContains(line, "High", false) && !GetArraySize(ML[M_HIGH]))
			{
				if (StrContains(line, "PL", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "PL", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					p_High = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "High player count changed to: %d (via normal PL config value)", p_High); 
					#endif
				}
			}
			else if (!StrContains(line, "Low", false) && !GetArraySize(ML[M_LOW]))
			{
				if (StrContains(line, "PL", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "PL", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					p_Low = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "Low player count changed to: %d (via normal PL config value)", p_Low); 
					#endif
				}
			}
		}
	}
	
	#if DEBUG
	new bool:log_p_Low;
	switch (p_Low)
	{
		case -1:
			log_p_Low = true;
		default:
			log_p_Low = false;
	}
	#endif
	
	switch (p_Low)
	{
		case -1:
			p_Low = RoundToNearest(0.33 * p_Total);
	}
	
	#if DEBUG
	new bool:log_p_High;
	switch (p_High)
	{
		case -1:
			log_p_High = true;
		default:
			log_p_High = false;
	}
	#endif
	
	switch (p_High)
	{
		case -1:
			p_High = RoundToNearest(0.66 * p_Total);
	}
	
	#if DEBUG
	switch (log_p_High)
	{
		case true:
			LogToFileEx(LogFilePath, "High player count rounded to: %d", p_High); 
	}
	switch (log_p_Low)
	{
		case true:
			LogToFileEx(LogFilePath, "Low player count rounded to: %d", p_Low); 
	}
	#endif
	
	if (p_Low == p_High)
	{
		RCP_TRANSLOADED LogError("%t", "RCP Same Player");}
		p_High = p_Low+1;
	}
	if (p_Low > p_High && p_High)
	{
		RCP_TRANSLOADED LogError("%t", "RCP Reversed Player");}
		p_Low = p_High;
		p_High = p_Low+1;
	}

	if (p_High-1 == p_Low)
	{
		b_NoMedmaplist = true;
	}
	else
	{
		b_NoMedmaplist = false;
	}
	
	ClearArray(ML[M_LOW]);
	ClearArray(ML[M_HIGH]);
	
	if (p_High)
	{
		ClearArray(MaplistArray);
		ReadMapList(MaplistArray, serial, "sm_rcplus_high", MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_CLEARARRAY);
		arraySize = GetArraySize(MaplistArray);
		if (arraySize)
		{
			for (new i; i < arraySize; i++)
			{
				GetArrayString(MaplistArray, i, map, sizeof(map));
				if (!IsMapValid(map))
				{
					RCP_TRANSLOADED LogError("[%t - maplists.cfg] %s %t", "RCP High", map, "RCP Map Error");}
					continue;
				}
				if (FindStringInArray(ML[M_HIGH], map) != -1)
				{
					RCP_TRANSLOADED LogError("[%t - maplists.cfg] %s %t", "RCP High", map, "RCP Dupe Map");}
					continue;
				}
				PushArrayString(ML[M_HIGH], map);
				#if DEBUG
				if (GetArraySize(ML[M_HIGH]) == 1)
				{
					LogToFileEx(LogFilePath, "High maps [maplists.cfg]:");
				}
				LogToFileEx(LogFilePath, "~ %s", map);
				#endif
			}
		}
	}
	
	if (!b_NoMedmaplist && p_High && p_Low && (p_High && p_Low))
	{
		ClearArray(MaplistArray);
		ReadMapList(MaplistArray, serial, "sm_rcplus_med", MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_CLEARARRAY);
		arraySize = GetArraySize(MaplistArray);
		if (arraySize)
		{
			for (new i; i < arraySize; i++)
			{
				GetArrayString(MaplistArray, i, map, sizeof(map));
				if (!IsMapValid(map))
				{
					RCP_TRANSLOADED LogError("[%t - maplists.cfg] %s %t", "RCP Med", map, "RCP Map Error");}
					continue;
				}
				if (FindStringInArray(ML[M_MED], map) != -1)
				{
					RCP_TRANSLOADED LogError("[%t - maplists.cfg] %s %t", "RCP Med", map, "RCP Dupe Map");}
					continue;
				}
				PushArrayString(ML[M_MED], map);
				#if DEBUG
				if (GetArraySize(ML[M_MED]) == 1)
				{
					LogToFileEx(LogFilePath, "Med maps [maplists.cfg]:");
				}
				LogToFileEx(LogFilePath, "~ %s", map);
				#endif
			}
		}
	}
	
	if (p_Low)
	{
		ClearArray(MaplistArray);
		ReadMapList(MaplistArray, serial, "sm_rcplus_low", MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_CLEARARRAY);
		arraySize = GetArraySize(MaplistArray);
		if (arraySize)
		{
			for (new i; i < arraySize; i++)
			{
				GetArrayString(MaplistArray, i, map, sizeof(map));
				if (!IsMapValid(map))
				{
					RCP_TRANSLOADED LogError("[%t - maplists.cfg] %s %t", "RCP Low", map, "RCP Map Error");}
					continue;
				}
				if (FindStringInArray(ML[M_LOW], map) != -1)
				{
					RCP_TRANSLOADED LogError("[%t - maplists.cfg] %s %t", "RCP Low", map, "RCP Dupe Map");}
					continue;
				}
				PushArrayString(ML[M_LOW], map);
				#if DEBUG
				if (GetArraySize(ML[M_LOW]) == 1)
				{
					LogToFileEx(LogFilePath, "Low maps [maplists.cfg]:");
				}
				LogToFileEx(LogFilePath, "~ %s", map);
				#endif
			}
		}
	}
	
	ClearArray(MaplistArray);
	ReadMapList(MaplistArray, serial, "sm_rcplus_single", MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_CLEARARRAY);
	arraySize = GetArraySize(MaplistArray);
	if (arraySize)
	{
		for (new i; i < arraySize; i++)
		{
			GetArrayString(MaplistArray, i, map, sizeof(map));
			if (!IsMapValid(map))
			{
				RCP_TRANSLOADED LogError("[%t - maplists.cfg] %s %t", "RCP Single", map, "RCP Map Error");}
				continue;
			}
			if (FindStringInArray(ML[M_SINGLE], map) != -1)
			{
				RCP_TRANSLOADED LogError("[%t - maplists.cfg] %s %t", "RCP Single", map, "RCP Dupe Map");}
				continue;
			}
			PushArrayString(ML[M_SINGLE], map);
			#if DEBUG
			if (GetArraySize(ML[M_SINGLE]) == 1)
			{
				LogToFileEx(LogFilePath, "Single maps [maplists.cfg]:");
			}
			LogToFileEx(LogFilePath, "~ %s", map);
			#endif
		}
	}
	
	ClearArray(MaplistArray);
	ReadMapList(MaplistArray, serial, "sm_rcplus_idle", MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_CLEARARRAY);
	arraySize = GetArraySize(MaplistArray);
	if (arraySize)
	{
		for (new i; i < arraySize; i++)
		{
			GetArrayString(MaplistArray, i, map, sizeof(map));
			if (!IsMapValid(map))
			{
				RCP_TRANSLOADED LogError("[%t - maplists.cfg] %s %t", "RCP Idle", map, "RCP Map Error");}
				continue;
			}
			if (FindStringInArray(ML[M_IDLE], map) != -1)
			{
				RCP_TRANSLOADED LogError("[%t - maplists.cfg] %s %t", "RCP Idle", map, "RCP Dupe Map");}
				continue;
			}
			PushArrayString(ML[M_IDLE], map);
			#if DEBUG
			if (GetArraySize(ML[M_IDLE]) == 1)
			{
				LogToFileEx(LogFilePath, "Idle maps [maplists.cfg]:");
			}
			LogToFileEx(LogFilePath, "~ %s", map);
			#endif
		}
	}
	
	FileSeek(h_configfile, 0, 0);
	while(!IsEndOfFile(h_configfile))
	{
		ReadFileLine(h_configfile, line, sizeof(line));
		TrimString(line);
		if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
		{
			BreakString(line, line, sizeof(line));
			if (!StrContains(line, "SingleTier", false) && !GetArraySize(ML[M_SINGLE]))
			{
				if (StrContains(line, "EX", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "EX", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					g_ExcludeMaps[M_SINGLE] = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "Single exclude count changed to: %d (via normal EX config value)", g_ExcludeMaps[M_SINGLE]); 
					#endif
				}
				while (line[0] != '}') 
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
					{
						BreakString(line, map, sizeof(map));
						if (!IsMapValid(map))
						{
							RCP_TRANSLOADED LogError("[%t] %s %t", "RCP Single", map, "RCP Map Error");}
							continue;
						}
						if (FindStringInArray(ML[M_SINGLE], map) != -1)
						{
							RCP_TRANSLOADED LogError("[%t] %s %t", "RCP Single", map, "RCP Dupe Map");}
							continue;
						}
						PushArrayString(ML[M_SINGLE], map);
						#if DEBUG
						if (GetArraySize(ML[M_SINGLE]) == 1)
						{
							LogToFileEx(LogFilePath, "Single maps:");
						}
						LogToFileEx(LogFilePath, "~ %s", map);
						#endif
						continue;
					}
				}
			}
			else if (!StrContains(line, "HighTier", false) && p_High && !GetArraySize(ML[M_HIGH]))
			{
				if (StrContains(line, "EX", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "EX", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					g_ExcludeMaps[M_HIGH] = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "High exclude count changed to: %d (via normal EX config value)", g_ExcludeMaps[M_HIGH]); 
					#endif
				}
				while (line[0] != '}')  
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
					{
						BreakString(line, map, sizeof(map));
						if (!IsMapValid(map))
						{
							RCP_TRANSLOADED LogError("[%t] %s %t", "RCP High", map, "RCP Map Error");}
							continue;
						}
						if (FindStringInArray(ML[M_HIGH], map) != -1)
						{
							RCP_TRANSLOADED LogError("[%t] %s %t", "RCP High", map, "RCP Dupe Map");}
							continue;
						}
						PushArrayString(ML[M_HIGH], map);
						#if DEBUG
						if (GetArraySize(ML[M_HIGH]) == 1)
						{
							LogToFileEx(LogFilePath, "High maps:");
						}
						LogToFileEx(LogFilePath, "~ %s", map);
						#endif
						continue; 
					}
				}
			}
			else if (!StrContains(line, "MedTier", false) && !b_NoMedmaplist && p_High && p_Low && (p_High && p_Low) && !GetArraySize(ML[M_MED]))
			{
				if (StrContains(line, "EX", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "EX", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					g_ExcludeMaps[M_MED] = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "Medium exclude count changed to: %d (via normal EX config value)", g_ExcludeMaps[M_MED]); 
					#endif
				}
				while (line[0] != '}')  
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
					{
						BreakString(line, map, sizeof(map));
						if (!IsMapValid(map))
						{
							RCP_TRANSLOADED LogError("[%t] %s %t", "RCP Med", map, "RCP Map Error");}
							continue;
						}
						if (FindStringInArray(ML[M_MED], map) != -1)
						{
							RCP_TRANSLOADED LogError("[%t] %s %t", "RCP Med", map, "RCP Dupe Map");}
							continue;
						}
						PushArrayString(ML[M_MED], map);
						#if DEBUG
						if (GetArraySize(ML[M_MED]) == 1)
						{
							LogToFileEx(LogFilePath, "Med maps:");
						}
						LogToFileEx(LogFilePath, "~ %s", map);
						#endif
						continue;
					}
				}
			}
			else if (!StrContains(line, "LowTier", false) && p_Low && !GetArraySize(ML[M_LOW]))
			{
				if (StrContains(line, "EX", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "EX", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					g_ExcludeMaps[M_LOW] = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "Low exclude count changed to: %d (via normal EX config value)", g_ExcludeMaps[M_LOW]); 
					#endif
				}
				while (line[0] != '}')  
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
					{
						BreakString(line, map, sizeof(map));
						if (!IsMapValid(map))
						{
							RCP_TRANSLOADED LogError("[%t] %s %t", "RCP Low", map, "RCP Map Error");}
							continue;
						}
						if (FindStringInArray(ML[M_LOW], map) != -1)
						{
							RCP_TRANSLOADED LogError("[%t] %s %t", "RCP Low", map, "RCP Dupe Map");}
							continue;
						}
						PushArrayString(ML[M_LOW], map);
						#if DEBUG
						if (GetArraySize(ML[M_LOW]) == 1)
						{
							LogToFileEx(LogFilePath, "Low maps:");
						}
						LogToFileEx(LogFilePath, "~ %s", map);
						#endif
						continue;
					}
				}
			}
			else if (!StrContains(line, "IdleTier", false) && !GetArraySize(ML[M_IDLE]))
			{
				if (StrContains(line, "EX", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "EX", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					g_ExcludeMaps[M_IDLE] = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "Idle exclude count changed to: %d (via normal EX config value)", g_ExcludeMaps[M_IDLE]); 
					#endif
				}
				while (line[0] != '}')  
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
					{
						BreakString(line, map, sizeof(map));
						if (!IsMapValid(map))
						{
							RCP_TRANSLOADED LogError("[%t] %s %t", "RCP Idle", map, "RCP Map Error");}
							continue;
						}
						if (FindStringInArray(ML[M_IDLE], map) != -1)
						{
							RCP_TRANSLOADED LogError("[%t] %s %t", "RCP Idle", map, "RCP Dupe Map");}
							continue;
						}
						PushArrayString(ML[M_IDLE], map);
						#if DEBUG
						if (GetArraySize(ML[M_IDLE]) == 1)
						{
							LogToFileEx(LogFilePath, "Idle maps:");
						}
						LogToFileEx(LogFilePath, "~ %s", map);
						#endif
						continue;
					}
				}
			}
			else if (!StrContains(line, "TimeTier-", false) && TimeTierMode)
			{
				// I should probably kill myself for the following code.
				decl String:Time[32];
				new TimeInt;
				new StringLength = strlen(line);
				new StringIndex;
				decl String:SD[4], String:ED[4];
				new StartDay;
				new EndDay;
				
				if (StringLength >= 24 && StringLength <= 29)
				{
					new Handle:DaysOfTheWeek = CreateArray(4);
					PushArrayString(DaysOfTheWeek, "IDK");
					PushArrayString(DaysOfTheWeek, "SUN");
					PushArrayString(DaysOfTheWeek, "MON");
					PushArrayString(DaysOfTheWeek, "TUE");
					PushArrayString(DaysOfTheWeek, "WED");
					PushArrayString(DaysOfTheWeek, "THU");
					PushArrayString(DaysOfTheWeek, "FRI");
					PushArrayString(DaysOfTheWeek, "SAT");
					decl String:Day[2];
					new AddDay;
					FormatTime(Time, sizeof(Time), "%w%H%M%S");
					FormatTime(Day, sizeof(Day), "%w");
					Format(SD, sizeof(SD), "%s%s%s", CharToUpper(line[9]), CharToUpper(line[10]), CharToUpper(line[11]));
					Format(ED, sizeof(ED), "%s%s%s", CharToUpper(line[17]), CharToUpper(line[18]), CharToUpper(line[19]));
					StartDay = FindStringInArray(DaysOfTheWeek, SD)*1000000;
					EndDay = FindStringInArray(DaysOfTheWeek, ED)*1000000;
					AddDay = StringToInt(Day)+1*1000000;
					TimeInt = StringToInt(Time)+AddDay;
					StringIndex = 3;
				}
				else if (StringLength >= 18 && StringLength <= 23)
				{
					FormatTime(Time, sizeof(Time), "%H%M%S");	
					TimeInt = StringToInt(Time);
				}
				else
				{
					RCP_TRANSLOADED LogError("\"%s\" %t", line, "RCP Time Format Error");}
					continue;
				}
				
				decl String:SH[3], String:SM[3], String:EH[3], String:EM[3];
				Format(SH, sizeof(SH), "%s", line[9+StringIndex]);
				Format(SM, sizeof(SM), "%s", line[11+StringIndex]);
				Format(EH, sizeof(EH), "%s", line[14+StringIndex+StringIndex]);
				Format(EM, sizeof(EM), "%s", line[16+StringIndex+StringIndex]);
				
				decl String:ConvertTime[7];
				Format(ConvertTime, sizeof(ConvertTime), "%s%s00", SH, SM);
				new StartTime = StringToInt(ConvertTime)+StartDay;
				Format(ConvertTime, sizeof(ConvertTime), "%s%s59", EH, EM);
				new EndTime = StringToInt(ConvertTime)+EndDay;
				
				PushArrayCell(g_TimeTierTimes, StartTime);
				PushArrayCell(g_TimeTierTimes, EndTime);
				
				if ((StartTime > EndTime && (TimeInt >= StartTime || TimeInt >= 0 && TimeInt <= EndTime)) || (StartTime < EndTime && TimeInt >= StartTime && TimeInt <= EndTime))
				{
					Format(CurrentTimeTier, sizeof(CurrentTimeTier), line);
					#if DEBUG
					LogToFileEx(LogFilePath, "Loading time tier: %s", CurrentTimeTier); 
					#endif
					if (TimeTierFound)
					{
						CloseHandle(h_configfile);
						RCP_TRANSLOADED LogError("%t", "RCP Time Tier Conflict", TimeTierConflict, CurrentTimeTier);}
						b_UseTimeTier = false;
						SearchForPopTiers = false;
						continue;
					}
					b_UseTimeTier = true;
					TimeTierFound = true;
					Format(TimeTierConflict, sizeof(TimeTierConflict), CurrentTimeTier);
				}
				else
				{
					b_UseTimeTier = false;
				}

				if (b_UseTimeTier)
				{
					new i;
					ConfigFilePosition = FilePosition(h_configfile);
					while (i != -1) 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
						{
							BreakString(line, map, sizeof(map));
							if (!StrContains(map, "TimeTierHigh", false) || !StrContains(map, "TimeTierMed", false) || !StrContains(map, "TimeTierLow", false))
							{
								SearchForPopTiers = true;
								continue;
							}
							// This is dirty BUT IT WORKS and does make sense in a strange kind of hacking way (contain your lol's).
							else if (line[0] == '{')
							{
								i++;
							}
							else if (line[0] == '}')
							{
								i--;
							}
						} 	
					}
				}
			}
		}
	}
	
	if (!SearchForPopTiers && b_UseTimeTier)
	{
		FileSeek(h_configfile, ConfigFilePosition, 0);
		ReadFileLine(h_configfile, line, sizeof(line));
		TrimString(line);
		new i;
		while(!IsEndOfFile(h_configfile))
		{
			ReadFileLine(h_configfile, line, sizeof(line));
			TrimString(line);
			if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
			{
				BreakString(line, line, sizeof(line));
				if (!StrContains(line, "TimeTierSingle", false))
				{
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMaps[M_SINGLE] = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMaps[M_SINGLE] = GetConVarInt(cvar_ExMapsSingle);
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier single exclude count: %d", g_ExcludeMaps[M_SINGLE]); 
					new bool:IsFirstDebug = true;
					#endif
					new bool:IsFirst = true;
					new bool:AddMap = true;
					new Index;
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, map, sizeof(map));
							AddMap = true;
							if (map[0] == '+' || map[0] == '-')
							{
								if (map[0] == '-')
								{
									AddMap = false;
								}
								IsFirst = false;
								Format(map, sizeof(map), map[1]);
							}
							if (!IsMapValid(map))
							{
								RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Single", CurrentTimeTier, map, "RCP Map Error");}
								continue;
							}
							if (IsFirst)
							{
								ClearArray(ML[M_SINGLE]);
								IsFirst = false;
							}
							if (AddMap)
							{	
								if (FindStringInArray(ML[M_SINGLE], map) != -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Single", CurrentTimeTier , map, "RCP Dupe Map");}
									continue;
								}
							}
							else
							{
								Index = FindStringInArray(ML[M_SINGLE], map);
								if (Index == -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Single", CurrentTimeTier , map, "RCP Map Not Found");}
									continue;
								}
							}
							#if DEBUG
							if (IsFirstDebug)
							{
								LogToFileEx(LogFilePath, "Single time tier maps:");
								if (!IsFirst)
								{
									LogToFileEx(LogFilePath, "ADD/REMOVE MODE");
								}
								IsFirstDebug = false;
							}
							#endif
							if (AddMap)
							{
								PushArrayString(ML[M_SINGLE], map);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s", map);
								#endif
							} 
							else
							{
								RemoveFromArray(ML[M_SINGLE], Index);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s (REMOVED)", map);
								#endif
							}
							continue;
						} 
					}
				}
				else if (!StrContains(line, "TimeTierIdle", false))
				{
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMaps[M_IDLE] = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMaps[M_IDLE] = GetConVarInt(cvar_ExMapsIdle);
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier idle exclude count: %d", g_ExcludeMaps[M_IDLE]); 
					new bool:IsFirstDebug = true;
					#endif
					new bool:IsFirst = true;
					new bool:AddMap = true;
					new Index;
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, map, sizeof(map));
							AddMap = true;
							if (map[0] == '+' || map[0] == '-')
							{
								if (map[0] == '-')
								{
									AddMap = false;
								}
								IsFirst = false;
								Format(map, sizeof(map), map[1]);
							}
							if (!IsMapValid(map))
							{
								RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Idle", CurrentTimeTier, map, "RCP Map Error");}
								continue;
							}
							if (IsFirst)
							{
								ClearArray(ML[M_IDLE]);
								IsFirst = false;
							}
							if (AddMap)
							{	
								if (FindStringInArray(ML[M_IDLE], map) != -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Idle", CurrentTimeTier , map, "RCP Dupe Map");}
									continue;
								}
							}
							else
							{
								Index = FindStringInArray(ML[M_IDLE], map);
								if (Index == -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Idle", CurrentTimeTier , map, "RCP Map Not Found");}
									continue;
								}
							}
							#if DEBUG
							if (IsFirstDebug)
							{
								LogToFileEx(LogFilePath, "Idle time tier maps:");
								if (!IsFirst)
								{
									LogToFileEx(LogFilePath, "ADD/REMOVE MODE");
								}
								IsFirstDebug = false;
							}
							#endif
							if (AddMap)
							{
								PushArrayString(ML[M_IDLE], map);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s", map);
								#endif
							} 
							else
							{
								RemoveFromArray(ML[M_IDLE], Index);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s (REMOVED)", map);
								#endif
							}
							continue;
						} 
					}
				}
				else if (line[0] == '{')
				{
					i++;
				}
				else if (line[0] == '}')
				{
					i--;
					if (i == -1)
					{
						break;
					}
				}
			}
		}
		
	}
	
	if (SearchForPopTiers)
	{
		ClearArray(ML[M_SINGLE]);
		FileSeek(h_configfile, ConfigFilePosition, 0);
		ReadFileLine(h_configfile, line, sizeof(line));
		TrimString(line);
		new i;
		while(!IsEndOfFile(h_configfile))
		{
			ReadFileLine(h_configfile, line, sizeof(line));
			TrimString(line);
			if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
			{
				BreakString(line, line, sizeof(line));
				if (!StrContains(line, "TimeTierHigh", false))
				{
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMaps[M_HIGH] = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMaps[M_HIGH] = GetConVarInt(cvar_ExMapsHigh);
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier high exclude count: %d", g_ExcludeMaps[M_HIGH]); 
					#endif
					if (StrContains(line, "PL", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "PL", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						p_High = StringToInt(ExcludeValue);
						#if DEBUG
						LogToFileEx(LogFilePath, "Time tier high player count changed to: %d (via time tier PL config value)", p_High);
						#endif
					}
				}
				else if (!StrContains(line, "TimeTierMed", false))
				{
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMaps[M_MED] = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMaps[M_MED] = GetConVarInt(cvar_ExMapsMed);
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier med exclude count: %d", g_ExcludeMaps[M_MED]); 
					#endif
				}
				else if (!StrContains(line, "TimeTierLow", false))
				{
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMaps[M_LOW] = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMaps[M_LOW] = GetConVarInt(cvar_ExMapsLow);
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier low exclude count: %d", g_ExcludeMaps[M_LOW]); 
					#endif
					if (StrContains(line, "PL", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "PL", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						p_Low = StringToInt(ExcludeValue);
						#if DEBUG
						LogToFileEx(LogFilePath, "Time tier low player count changed to: %d (via time tier PL config value)", p_Low);
						#endif
					}
				}
				else if (!StrContains(line, "TimeTierIdle", false))
				{
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMaps[M_IDLE] = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMaps[M_IDLE] = GetConVarInt(cvar_ExMapsIdle);
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier idle exclude count: %d", g_ExcludeMaps[M_IDLE]); 
					#endif
				}
				else if (line[0] == '{')
				{
					i++;
				}
				else if (line[0] == '}')
				{
					i--;
					if (i == -1)
					{
						break;
					}
				}
			}
		}
		
		#if DEBUG
		switch (p_Low)
		{
			case -1:
				log_p_Low = true;
			default:
				log_p_Low = false;
		}
		#endif
		
		switch (p_Low)
		{
			case -1:
				p_Low = RoundToNearest(0.33 * p_Total);
		}
		
		#if DEBUG
		switch (p_High)
		{
			case -1:
				log_p_High = true;
			default:
				log_p_High = false;
		}
		#endif
		
		switch (p_High)
		{
			case -1:
				p_High = RoundToNearest(0.66 * p_Total);
		}
		
		#if DEBUG
		switch (log_p_High)
		{
			case true:
				LogToFileEx(LogFilePath, "High player count rounded to: %d", p_High); 
		}
		switch (log_p_Low)
		{
			case true:
				LogToFileEx(LogFilePath, "Low player count rounded to: %d", p_Low); 
		}
		#endif
		
		if (p_Low == p_High)
		{
			RCP_TRANSLOADED LogError("%t (%s)", "RCP Same Player", CurrentTimeTier);}
			p_High = p_Low+1;
		}
		if (p_Low > p_High && p_High)
		{
			RCP_TRANSLOADED LogError("%t (%s)", "RCP Reversed Player", CurrentTimeTier);}
			p_Low = p_High;
			p_High = p_Low+1;
		}
		
		if (p_High-1 == p_Low)
		{
			b_NoMedmaplist = true;
		}
		else
		{
			b_NoMedmaplist = false;
		}
		
		FileSeek(h_configfile, ConfigFilePosition, 0);
		ReadFileLine(h_configfile, line, sizeof(line));
		TrimString(line);
		i = 0;
		while(!IsEndOfFile(h_configfile))
		{
			ReadFileLine(h_configfile, line, sizeof(line));
			TrimString(line);
			if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
			{
				BreakString(line, line, sizeof(line));
				if (!StrContains(line, "TimeTierHigh", false) && p_High)
				{
					#if DEBUG
					new bool:IsFirstDebug = true;
					#endif
					new bool:IsFirst = true;
					new bool:AddMap = true;
					new Index;
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, map, sizeof(map));
							AddMap = true;
							if (map[0] == '+' || map[0] == '-')
							{
								if (map[0] == '-')
								{
									AddMap = false;
								}
								IsFirst = false;
								Format(map, sizeof(map), map[1]);
							}
							if (!IsMapValid(map))
							{
								RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP High", CurrentTimeTier, map, "RCP Map Error");}
								continue;
							}
							if (IsFirst)
							{
								ClearArray(ML[M_HIGH]);
								IsFirst = false;
							}
							if (AddMap)
							{	
								if (FindStringInArray(ML[M_HIGH], map) != -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP High", CurrentTimeTier , map, "RCP Dupe Map");}
									continue;
								}
							}
							else
							{
								Index = FindStringInArray(ML[M_HIGH], map);
								if (Index == -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP High", CurrentTimeTier , map, "RCP Map Not Found");}
									continue;
								}
							}
							#if DEBUG
							if (IsFirstDebug)
							{
								LogToFileEx(LogFilePath, "High time tier maps:");
								if (!IsFirst)
								{
									LogToFileEx(LogFilePath, "ADD/REMOVE MODE");
								}
								IsFirstDebug = false;
							}
							#endif
							if (AddMap)
							{
								PushArrayString(ML[M_HIGH], map);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s", map);
								#endif
							} 
							else
							{
								RemoveFromArray(ML[M_HIGH], Index);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s (REMOVED)", map);
								#endif
							}
							continue;
						} 
					}
				}
				else if (!StrContains(line, "TimeTierMed", false) && !b_NoMedmaplist && p_High && p_Low && (p_High && p_Low))
				{
					#if DEBUG
					new bool:IsFirstDebug = true;
					#endif
					new bool:IsFirst = true;
					new bool:AddMap = true;
					new Index;
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, map, sizeof(map));
							AddMap = true;
							if (map[0] == '+' || map[0] == '-')
							{
								if (map[0] == '-')
								{
									AddMap = false;
								}
								IsFirst = false;
								Format(map, sizeof(map), map[1]);
							}
							if (!IsMapValid(map))
							{
								RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Med", CurrentTimeTier, map, "RCP Map Error");}
								continue;
							}
							if (IsFirst)
							{
								ClearArray(ML[M_MED]);
								IsFirst = false;
							}
							if (AddMap)
							{	
								if (FindStringInArray(ML[M_MED], map) != -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Med", CurrentTimeTier , map, "RCP Dupe Map");}
									continue;
								}
							}
							else
							{
								Index = FindStringInArray(ML[M_MED], map);
								if (Index == -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Med", CurrentTimeTier , map, "RCP Map Not Found");}
									continue;
								}
							}
							#if DEBUG
							if (IsFirstDebug)
							{
								LogToFileEx(LogFilePath, "Med time tier maps:");
								if (!IsFirst)
								{
									LogToFileEx(LogFilePath, "ADD/REMOVE MODE");
								}
								IsFirstDebug = false;
							}
							#endif
							if (AddMap)
							{
								PushArrayString(ML[M_MED], map);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s", map);
								#endif
							} 
							else
							{
								RemoveFromArray(ML[M_MED], Index);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s (REMOVED)", map);
								#endif
							}
							continue;
						} 
					}
				}
				else if (!StrContains(line, "TimeTierLow", false) && p_Low)
				{
					#if DEBUG
					new bool:IsFirstDebug = true;
					#endif
					new bool:IsFirst = true;
					new bool:AddMap = true;
					new Index;
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, map, sizeof(map));
							AddMap = true;
							if (map[0] == '+' || map[0] == '-')
							{
								if (map[0] == '-')
								{
									AddMap = false;
								}
								IsFirst = false;
								Format(map, sizeof(map), map[1]);
							}
							if (!IsMapValid(map))
							{
								RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Low", CurrentTimeTier, map, "RCP Map Error");}
								continue;
							}
							if (IsFirst)
							{
								ClearArray(ML[M_LOW]);
								IsFirst = false;
							}
							if (AddMap)
							{	
								if (FindStringInArray(ML[M_LOW], map) != -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Low", CurrentTimeTier , map, "RCP Dupe Map");}
									continue;
								}
							}
							else
							{
								Index = FindStringInArray(ML[M_LOW], map);
								if (Index == -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Low", CurrentTimeTier , map, "RCP Map Not Found");}
									continue;
								}
							}
							#if DEBUG
							if (IsFirstDebug)
							{
								LogToFileEx(LogFilePath, "Low time tier maps:");
								if (!IsFirst)
								{
									LogToFileEx(LogFilePath, "ADD/REMOVE MODE");
								}
								IsFirstDebug = false;
							}
							#endif
							if (AddMap)
							{
								PushArrayString(ML[M_LOW], map);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s", map);
								#endif
							} 
							else
							{
								RemoveFromArray(ML[M_LOW], Index);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s (REMOVED)", map);
								#endif
							}
							continue;
						} 
					}
				}
				else if (!StrContains(line, "TimeTierIdle", false))
				{
					#if DEBUG
					new bool:IsFirstDebug = true;
					#endif
					new bool:IsFirst = true;
					new bool:AddMap = true;
					new Index;
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, map, sizeof(map));
							AddMap = true;
							if (map[0] == '+' || map[0] == '-')
							{
								if (map[0] == '-')
								{
									AddMap = false;
								}
								IsFirst = false;
								Format(map, sizeof(map), map[1]);
							}
							if (!IsMapValid(map))
							{
								RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Idle", CurrentTimeTier, map, "RCP Map Error");}
								continue;
							}
							if (IsFirst)
							{
								ClearArray(ML[M_IDLE]);
								IsFirst = false;
							}
							if (AddMap)
							{	
								if (FindStringInArray(ML[M_IDLE], map) != -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Idle", CurrentTimeTier , map, "RCP Dupe Map");}
									continue;
								}
							}
							else
							{
								Index = FindStringInArray(ML[M_IDLE], map);
								if (Index == -1)
								{
									RCP_TRANSLOADED LogError("[%t - \"%s\"] %s %t", "RCP Idle", CurrentTimeTier , map, "RCP Map Not Found");}
									continue;
								}
							}
							#if DEBUG
							if (IsFirstDebug)
							{
								LogToFileEx(LogFilePath, "Idle time tier maps:");
								if (!IsFirst)
								{
									LogToFileEx(LogFilePath, "ADD/REMOVE MODE");
								}
								IsFirstDebug = false;
							}
							#endif
							if (AddMap)
							{
								PushArrayString(ML[M_IDLE], map);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s", map);
								#endif
							} 
							else
							{
								RemoveFromArray(ML[M_IDLE], Index);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s (REMOVED)", map);
								#endif
							}
							continue;
						} 
					}
				}
				else if (line[0] == '{')
				{
					i++;
				}
				else if (line[0] == '}')
				{
					i--;
					if (i == -1)
					{
						break;
					}
				}
			}
		}
	}
		
	CloseHandle(h_configfile);
	
	if (b_UseTimeTier && GetArraySize(ML[M_SINGLE]))
	{
		b_UsePopulationTier = false;
	}
	else
	{
		b_UsePopulationTier = true;
	}
	
	for (new i; i < M_TOTAL; i++)
	{
		if (!b_PickMap[i])
		{
			arraySize = GetArraySize(ML[i]);
			if (arraySize && FindStringInArray(ML[i], MAP[0][i]) == -1)
			{
				b_PickMap[i] = true;
				if (g_CycleRun == i)
				{
					g_CycleRun = M_NONE;
				}
			}
		}
	}
	
	// Set the automatic exclude valies, if applicable.
	
	#if DEBUG
	new bool:d_Ex[M_TOTAL];
	for (new i; i < M_TOTAL; i++)
	{
		switch (g_ExcludeMaps[i])
		{
			case -1:
				d_Ex[i] = true;
		}
	}
	#endif
	
	for (new i; i < M_TOTAL; i++)
	{
		switch (g_ExcludeMaps[i])
		{
			case -1:
				g_ExcludeMaps[i] = RoundToNearest(GetConVarFloat(cvar_ExMapsRatio) * GetArraySize(ML[i]));
		}
	}
	
	#if DEBUG
	switch (d_Ex[M_SINGLE])
	{
		case true:
			LogToFileEx(LogFilePath, "Rounded single exclude value to: %d", g_ExcludeMaps[M_SINGLE]);
	}
	switch (d_Ex[M_HIGH])
	{
		case true:
			LogToFileEx(LogFilePath, "Rounded high exclude value to: %d", g_ExcludeMaps[M_HIGH]);
	}
	switch (d_Ex[M_MED])
	{
		case true:
			LogToFileEx(LogFilePath, "Rounded med exclude value to: %d", g_ExcludeMaps[M_MED]);
	}
	switch (d_Ex[M_LOW])
	{
		case true:
			LogToFileEx(LogFilePath, "Rounded low exclude value to: %d", g_ExcludeMaps[M_LOW]);
	}
	switch (d_Ex[M_IDLE])
	{
		case true:
			LogToFileEx(LogFilePath, "Rounded idle exclude value to: %d", g_ExcludeMaps[M_IDLE]);
	}
	#endif
	
	new tierSize[M_TOTAL];
	
	for (new i; i < M_TOTAL; i++)
	{
		tierSize[i] = GetArraySize(ML[i]);
	}
	
	// Fallbacks
	
	if (tierSize[M_SINGLE] <= g_ExcludeMaps[M_SINGLE])
	{
		if (!tierSize[M_SINGLE])
		{
			if (SingleTierMode)
			{
				b_Loaded = false;
				SetConVarInt(cvar_SingleTier, 0);
				b_Loaded = true;
			}
			if (b_UseTimeTier && !b_UsePopulationTier)
			{
				b_UseTimeTier = false;
			}
			
			if (b_UseTimeTier && !b_UsePopulationTier)
			{
				RCP_TRANSLOADED LogError("[%t - \"%s\"]: %t", "RCP Single", CurrentTimeTier, "RCP Not Filled In");}
			} 
			else if (SingleTierMode)
			{
				RCP_TRANSLOADED LogError("[%t]: %t", "RCP Single", "RCP Not Filled In");}
			}
		}
		else
		{
			g_ExcludeMaps[M_SINGLE] = tierSize[M_SINGLE] - 1;
			if (b_UseTimeTier && !b_UsePopulationTier)
			{
				RCP_TRANSLOADED LogError("[%t - \"%s\"]: %t", "RCP Single", CurrentTimeTier, "RCP Exclude Error", g_ExcludeMaps[M_SINGLE]);}
			} 
			else if (SingleTierMode)
			{
				RCP_TRANSLOADED LogError("[%t]: %t", "RCP Single", "RCP Exclude Error", g_ExcludeMaps[M_SINGLE]);}
			}
		}
	}
	
	if (tierSize[M_HIGH] <= g_ExcludeMaps[M_HIGH] && p_High)
	{
		if (!tierSize[M_HIGH])
		{
			p_High = 0;
			if (b_UseTimeTier && b_UsePopulationTier)
			{
				RCP_TRANSLOADED LogError("[%t - \"%s\"]: %t", "RCP High", CurrentTimeTier, "RCP Not Filled In");}
			} 
			else if (!SingleTierMode)
			{
				RCP_TRANSLOADED LogError("[%t]: %t", "RCP High", "RCP Not Filled In");}
			}
		}
		else
		{
			g_ExcludeMaps[M_HIGH] = tierSize[M_HIGH] - 1;
			if (b_UseTimeTier && b_UsePopulationTier)
			{
				RCP_TRANSLOADED LogError("[%t - \"%s\"]: %t", "RCP High", CurrentTimeTier, "RCP Exclude Error", g_ExcludeMaps[M_HIGH]);}
			} 
			else if (!SingleTierMode)
			{
				RCP_TRANSLOADED LogError("[%t]: %t", "RCP High", "RCP Exclude Error", g_ExcludeMaps[M_HIGH]);}
			}
		}
	}

	if (tierSize[M_MED] <= g_ExcludeMaps[M_MED] && !b_NoMedmaplist && p_High && p_Low && (p_High && p_Low))
	{
		if (!tierSize[M_MED])
		{
			p_High = p_Low+1;
			if (b_UseTimeTier && b_UsePopulationTier)
			{
				RCP_TRANSLOADED LogError("[%t - \"%s\"]: %t", "RCP Med", CurrentTimeTier, "RCP Not Filled In");}
			} 
			else if (!SingleTierMode)
			{
				RCP_TRANSLOADED LogError("[%t]: %t", "RCP Med", "RCP Not Filled In");}
			}
		}
		else
		{
			g_ExcludeMaps[M_MED] = GetArraySize(ML[M_MED]) - 1;
			if (b_UseTimeTier && b_UsePopulationTier)
			{
				RCP_TRANSLOADED LogError("[%t - \"%s\"]: %t", "RCP Med", CurrentTimeTier, "RCP Exclude Error", g_ExcludeMaps[M_MED]);}
			} 
			else if (!SingleTierMode)
			{
				RCP_TRANSLOADED LogError("[%t]: %t", "RCP Med", "RCP Exclude Error", g_ExcludeMaps[M_MED]);}
			}
		}
	}
	
	if (tierSize[M_LOW] <= g_ExcludeMaps[M_LOW] && p_Low)
	{
		if (!tierSize[M_LOW])
		{
			if (!p_High)
			{
				p_Low = 0;
			}
			else
			{
				p_Low = 0;
				p_High = 1;
			}
			if (b_UseTimeTier && b_UsePopulationTier)
			{
				RCP_TRANSLOADED LogError("[%t - \"%s\"]: %t", "RCP Low", CurrentTimeTier, "RCP Not Filled In");}
			} 
			else if (!SingleTierMode)
			{
				RCP_TRANSLOADED LogError("[%t]: %t", "RCP Low", "RCP Not Filled In");}
			}
		}
		else
		{
			g_ExcludeMaps[M_LOW] = GetArraySize(ML[M_LOW]) - 1;
			if (b_UseTimeTier && b_UsePopulationTier)
			{
				RCP_TRANSLOADED LogError("[%t - \"%s\"]: %t", "RCP Low", CurrentTimeTier, "RCP Exclude Error", g_ExcludeMaps[M_LOW]);}
			} 
			else if (!SingleTierMode)
			{
				RCP_TRANSLOADED LogError("[%t]: %t", "RCP Low", "RCP Exclude Error", g_ExcludeMaps[M_LOW]);}
			}
		}
	}
	
	if (tierSize[M_IDLE] && tierSize[M_IDLE] <= g_ExcludeMaps[M_IDLE] && GetConVarInt(cvar_UseIdleTier))
	{
		g_ExcludeMaps[M_IDLE] = GetArraySize(ML[M_IDLE]) - 1;
		if (b_UseTimeTier && b_UsePopulationTier)
		{
			RCP_TRANSLOADED LogError("[%t - \"%s\"]: %t", "RCP Idle", CurrentTimeTier, "RCP Exclude Error", g_ExcludeMaps[M_IDLE]);}
		} 
		else if (!SingleTierMode)
		{
			RCP_TRANSLOADED LogError("[%t]: %t", "RCP Idle", "RCP Exclude Error", g_ExcludeMaps[M_IDLE]);}
		}
	}
}

RCP_HistoryArray()
{
	// We need to work our way BACKWARDS through the maphistory array so the maps go into the array in the right order.
	// In 1.2.0+ this has changed to only call if the master map history is not big enough or the plugin has been fully reloaded during the middle of running the server.
	decl String:HistoryMap[65];
	new HistorySize;
	ClearArray(OML_Master);
	HistorySize = GetMapHistorySize();
	
	if (!HistorySize)
	{
		return;
	} 
	else 
	{
		for (new i = HistorySize-1; i >= 0; i--)
		{
			decl String:reason[128], time;
			GetMapHistory(i, HistoryMap, sizeof(HistoryMap), reason, sizeof(reason), time);
			PushArrayString(OML_Master, HistoryMap);
		}
	}
}

RCP_RandomCycleCheck()
{
	// Removed due to log spam really, can enable if you want though.
	//#if DEBUG
	//LogToFileEx(LogFilePath, "Running main rc+ check.");
	//#endif
	
	// All the checks for what map to pick!
	if (b_NextMapChanged || !b_Loaded || h_IdleServer != INVALID_HANDLE)
	{
		return;
	}
	
	new SingleTierMode = GetConVarInt(cvar_SingleTier);
	new TimeTierMode = GetConVarInt(cvar_UseTimeTiers);
	
	if (TimeTierMode)
	{
		// Again, removed due to log spam, can enable if you want though.
		//#if DEBUG
		//LogToFileEx(LogFilePath, "Checking if time tier needs enabling/disabling yet.");
		//#endif
		RCP_StartTimeTier();
	}
	
	// Continues the timer if single tier has just been disabled or time tiers are on.
	if ((!SingleTierMode || GetConVarInt(cvar_UseTimeTiers)) && h_RandomCycleCheck == INVALID_HANDLE)
	{
		h_RandomCycleCheck = CreateTimer(GetConVarFloat(cvar_PlayerCheckTime), t_RandomCycleCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		#if DEBUG
		LogToFileEx(LogFilePath, "Resumed main rc+ check timer.");
		#endif
	} 
	
	if ((!b_UseTimeTier && SingleTierMode) || (TimeTierMode && b_UseTimeTier && !b_UsePopulationTier))
	{
		RCP_ParseTier(M_SINGLE);
		return;
	}
	
	if (p_High && g_Players >= p_High && !b_DisableHighTier)
	{
		RCP_ParseTier(M_HIGH);
		return;
	}
	
	if ((p_High && p_Low) && g_Players > p_Low && (g_Players < p_High || (b_DisableHighTier && g_Players >= p_High && p_High-1 != p_Low)))
	{
		RCP_ParseTier(M_MED);
		return;
	}
	
	if (p_Low && (g_Players <= p_Low || (b_DisableHighTier && (!p_High || p_High-1 == p_Low))))
	{
		RCP_ParseTier(M_LOW);
		return;
	}
	
	// The fall-back code is now a lot less messy due to all the returns above
	if (g_CycleRun == M_OLD)
	{
		return;
	}
	g_CycleRun = M_OLD;
	RCP_SetRandomMap(M_OLD);
	return;
}

RCP_ParseTier(const tier)
{
	if (g_CycleRun == tier)
	{
		return;
	}
	g_CycleRun = tier;
	if (b_PickMap[tier])
	{
		RCP_GetRandomMap(tier);
	}
	RCP_SetRandomMap(tier);
	
	return;
}

RCP_GetRandomMap(const tier)
{	
	// Loads the full map history from the master array, this gives RC+ a fuller history to look back upon.
	
	new Handle:oldmaplist = CreateArray(65);
	
	if (g_ExcludeMaps[tier])
	{
		decl String:CheckMap[65];
		for (new i = GetArraySize(OML_Master) - 1; i >= 0; i--)
		{
			GetArrayString(OML_Master, i, CheckMap, sizeof(CheckMap));
			if (FindStringInArray(ML[tier], CheckMap) != -1)
			{
				new CheckArray = FindStringInArray(oldmaplist, CheckMap);
				if (CheckArray != -1)
				{
					continue;
				}
				PushArrayString(oldmaplist, CheckMap);
				#if DEBUG
				switch (GetArraySize(oldmaplist))
				{
					case 1:
						LogToFileEx(LogFilePath, "Current history maps:");
				}
				LogToFileEx(LogFilePath, "~ %s", CheckMap);
				#endif
				if (GetArraySize(oldmaplist) == g_ExcludeMaps[tier])
				{
					break;
				}
			}
		}
	}
	
	// Picks and sets what the nextmap will be, checks against the old current tier map array to make sure that it isn't repeating itself.
	new arraySize = GetArraySize(ML[tier]);
	new num = GetRandomInt(0, arraySize - 1);
	
	GetArrayString(ML[tier], num, MAP[0][tier], sizeof(MAP));

	if (g_ExcludeMaps[tier])
	{
		while (FindStringInArray(oldmaplist, MAP[0][tier]) != -1)
		{
			num = GetRandomInt(0, arraySize - 1);
			GetArrayString(ML[tier], num, MAP[0][tier], sizeof(MAP));
		}
	}
}

RCP_SetRandomMap(const tier)
{
	// Applies the picked nextmap.
	if (GetConVarInt(cvar_NextMapHide))
	{
		flags_g_NextMap &= ~FCVAR_NOTIFY;
		SetConVarFlags(g_NextMap, flags_g_NextMap);
		SetNextMap(MAP[0][tier]);
		SetConVarFlags(g_NextMap, oldflags_g_NextMap);
	} 
	else 
	{
		SetNextMap(MAP[0][tier]);
	}
	
	b_NextMapChanged = false;
	
	if (GetConVarInt(cvar_Announce))
	{
		RCP_TRANSLOADED PrintToChatAll("[SM] %t %s", "RCP Nextmap", MAP[0][tier]);}
	}
	
	if (GetConVarInt(cvar_LogMSG))
	{
		RCP_TRANSLOADED LogMessage("%t %s", "RCP Nextmap", MAP[0][tier]);}
	}
	
	b_PickMap[tier] = false;
	
	#if DEBUG
	switch (tier)
	{
		case M_SINGLE:
			LogToFileEx(LogFilePath, "rc+ set single tier map: %s", MAP[0][tier]);
		case M_HIGH:
			LogToFileEx(LogFilePath, "rc+ set high tier map: %s", MAP[0][tier]);
		case M_MED:
			LogToFileEx(LogFilePath, "rc+ set med tier map: %s", MAP[0][tier]);
		case M_LOW:
			LogToFileEx(LogFilePath, "rc+ set low tier map: %s", MAP[0][tier]);
		case M_OLD:
			LogToFileEx(LogFilePath, "rc+ set old map: %s", MAP[0][tier]);
	}
	LogToFileEx(LogFilePath, "Current player count: %d", g_Players);
	#endif
}

RCP_StartTimeTier()
{
	new Index = GetArraySize(g_TimeTierTimes)-1;
	while (Index >= 0)
	{
		new EndTime = GetArrayCell(g_TimeTierTimes, Index);
		Index--;
		new StartTime = GetArrayCell(g_TimeTierTimes, Index);
		Index--;
		decl String:Time[32];
		new TimeInt;
		
		if (StartTime > 999999)
		{
			decl String:Day[2];
			new AddDay;
			FormatTime(Time, sizeof(Time), "%w%H%M%S");
			FormatTime(Day, sizeof(Day), "%w");
			AddDay = StringToInt(Day)+1*1000000;
			TimeInt = StringToInt(Time)+AddDay;
		}
		else
		{
			FormatTime(Time, sizeof(Time), "%H%M%S");
			TimeInt = StringToInt(Time);
		}
		if ((StartTime > EndTime && (TimeInt >= StartTime || TimeInt >= 0 && TimeInt <= EndTime)) || (StartTime < EndTime && TimeInt >= StartTime && TimeInt <= EndTime))
		{
			// This enables the time tiers and gets its maps.
			if (!b_UseTimeTier)
			{
				RCP_LoadMaplist();
			}
		} 
		// This disables the time tiers and loads the normal maplists.
		else if (b_UseTimeTier)
		{
			RCP_LoadMaplist();
		}
	}
}

RCP_ServerIdleCheck()
{
	#if DEBUG
	LogToFileEx(LogFilePath, "Running idle check.");
	#endif
	if (GetConVarInt(cvar_UseIdleTier) && GetArraySize(ML[M_IDLE]) && !g_Players && h_IdleServer == INVALID_HANDLE)
	{
		decl String:CurrentMap[65];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		if (FindStringInArray(ML[M_IDLE], CurrentMap) == -1)
		{
			if (h_RandomCycleCheck != INVALID_HANDLE)
			{
				CloseHandle(h_RandomCycleCheck);
				h_RandomCycleCheck = INVALID_HANDLE;
			}
			h_IdleServer = CreateTimer(GetConVarFloat(cvar_IdleTime), t_IdleServer, _, TIMER_FLAG_NO_MAPCHANGE);
			#if DEBUG
			LogToFileEx(LogFilePath, "Starting normal idle server timer.");
			#endif
		} 
		else if (GetConVarInt(cvar_IdleRotate))
		{
			if (h_RandomCycleCheck != INVALID_HANDLE)
			{
				CloseHandle(h_RandomCycleCheck);
				h_RandomCycleCheck = INVALID_HANDLE;
			}
			h_IdleServer = CreateTimer(float(GetConVarInt(cvar_IdleRotate))*60, t_IdleServer, _, TIMER_FLAG_NO_MAPCHANGE);
			#if DEBUG
			LogToFileEx(LogFilePath, "Starting rotating idle server timer.");
			#endif
		}
	}
	else if (h_IdleServer != INVALID_HANDLE && (!GetConVarInt(cvar_UseIdleTier) || !GetArraySize(ML[M_IDLE])))
	{
		CloseHandle(h_IdleServer);
		h_IdleServer = INVALID_HANDLE;
		#if DEBUG
		LogToFileEx(LogFilePath, "Killed idle server timer.");
		#endif
		RCP_RandomCycleCheck();
	}
}