/**
 * =====================================================================================
 * RandomCycle+
 * Randomly picks a map from tiered maplists based on player counts.
 *
 * Special thanks to Sven Stryker for grammar correction in this plugin!
 *
 * Base code from SourceMod Random Map Cycle plugin, additional code by Jamster.
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
 * - Added cvar to enable/disable checking for duplicate maps for the whole 
 *   cycle.
 * - Added a further check to check for duplicates in the tier itself (this is
 *   always enabled due to the nature of the plugin).
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
 * - Disabling of high tier takes into account if the server population dips in-
 *   between maps.
 * - If the single tier happens to get disabled the timer check will start up
 *   again and continue to check for players, single tier cvar change now hooked 
 *   too so it will instantly enable or disable.
 * - Disabled check array command in default build, uncomment to enable again
 *   if you wish, but this command is now defunct.
 *
 * 1.1.1a
 * - Fixed start of map check not working.
 *
 * 1.2.0
 * - Map history code now drastically recoded, will now remember the FULL past
 *   high, medium and low tier maps rather than not using the past x maps 
 *   recently played.
 * - Cvar added to control the size of the internal RC+ maphistory.
 *
 * 1.2.1
 * - Fixed single tier mode history bug.
 *
 * 1.3.0
 * - Added support for time specific rotations.
 * - Improved the map history if using multiple types of tiers.
 * - Optimised single tier mode so you don't need to fill out the other tiers
 *   if they are unused on your server.
 * - Removed dupe map check for the whole low to high cycle and the cvar that 
 *   controls this due to the way the plugin now handles the map history.
 * - Improved error reporting.
 * - A few general optimisations and improvements.
 *
 * 1.3.0a
 * - Small bugfix with single tier mode enabled on startup causing the early
 *   nextmap trigger to show.
 *
 * 1.3.1
 * - Added population support to time tiers.
 * - Added in validating of time tiers to check if they clash or not.
 * - Better detection of incorrect cvar values with single tier mode enabled
 *   which will let single tier mode to continue.
 * - Time tiers now correctly override single tier mode.
 * - Further small improvements.
 *
 * 1.3.2
 * - Lots of very small fixes.
 * - Added "automatic" cvar value for excludes and is now the new default ("-1")
 *   this will automatically exclude roughly 40% of the maps on your list (this
 *   value is rounded to the nearest value). Also added a cvar to control this ratio.
 * - Added idle server support, also works with time tiers. Also setup a cvar to
 *   control if RC+ rotates through your idle maps or keeps on one idle map
 *   until players join the server.
 * - Added PL/EX support to normal tiers.
 * - Changed mapstart check default to 1.
 * - Removed max time restriction on main rc+ check time setting.
 *
 * 1.3.2.1
 * - Fixed closing the timer when applicable for the main check when single tier mode 
 *   is enabled mid game. 
 * - Error handling improved with single tier mode enabled.
 * - Fixed setting regular time tier to automatic exclude.
 *
 * 1.3.2.2
 * - Added lots of debug code. Not operational by default though (requires a recompile).
 * - Adjusted some of the RC+ checks to do with time tiers and single tier.
 * - Fixed some mistakes in the exclude values.
 * - Optimised a lot of the checks and a few small fixes.
 * =====================================================================================
 */
 
// Set to 0 to remove the rtv code, slight speed increase if you don't use
// the interal RTV
#define RTV 1
#define DEBUG 1

/////////////
// Globals //
///////////// 

#pragma semicolon 1
#include <sourcemod>
#define PLUGIN_VERSION "1.3.2.2"

public Plugin:myinfo =
{
	name = "RandomCycle+",
	author = "Jamster",
	description = "Randomly chooses the nextmap based on current player counts from tiered maplists",
	version = PLUGIN_VERSION,
	url = "http://www.sourcemod.net/"
};

// cvars
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

// handles
new Handle:g_MapList = INVALID_HANDLE;
new Handle:g_OldMapList = INVALID_HANDLE;
new Handle:g_OldMapListSingle = INVALID_HANDLE;
new Handle:g_OldMapListMaster = INVALID_HANDLE;
new Handle:g_OldMapListHigh = INVALID_HANDLE;
new Handle:g_OldMapListMed = INVALID_HANDLE;
new Handle:g_OldMapListLow = INVALID_HANDLE;
new Handle:g_OldMapListIdle = INVALID_HANDLE;
new Handle:g_OldMapListTime = INVALID_HANDLE;
new Handle:g_MapListSingle = INVALID_HANDLE;
new Handle:g_MapListHigh = INVALID_HANDLE;
new Handle:g_MapListMed = INVALID_HANDLE;
new Handle:g_MapListLow = INVALID_HANDLE;
new Handle:g_MapListIdle = INVALID_HANDLE;
new Handle:g_MapListTime = INVALID_HANDLE;
new Handle:g_TimeTierTimes = INVALID_HANDLE;
new Handle:g_NextMap = INVALID_HANDLE;
new flags_g_NextMap;
new oldflags_g_NextMap;
new Handle:h_RandomCycleCheck = INVALID_HANDLE;
new Handle:h_IdleServer = INVALID_HANDLE;

// bools
new bool:b_Loaded = false;
new bool:b_NextMapChanged = false;
new bool:b_PickMapSingle = true;
new bool:b_PickMapHigh = true;
new bool:b_PickMapMed = true;
new bool:b_PickMapLow = true;
new bool:b_PickMapTime = true;
new bool:b_BaseTriggersLoaded = false;
new bool:b_DisableHighTier = false;
new bool:b_UseTimeTier = false;
new bool:b_UsePopulationTier = true;

// ints/floats
new g_Players = 0;
new g_CycleRun = 0;
new g_ExcludeMapsSingle;
new g_ExcludeMapsHigh;
new g_ExcludeMapsMed;
new g_ExcludeMapsLow;
new g_ExcludeMapsTime;
new g_ExcludeMapsIdle;
new g_HighCount = 0;
new p_High;
new p_Low;

// strings
new String:map[65];
new String:setmap[65];
new String:maplow[65];
new String:mapmed[65];
new String:maphigh[65];
new String:mapsingle[65];
new String:maptimetier[65];
new String:oldnextmap[65];

#if RTV
// rtv globals
new bool:b_RTVLoaded = false;
new bool:b_rtv_ChangingMap = false;
new bool:b_rtv_Enable = false;
new bool:rtv_Counted[MAXPLAYERS+1] = {false, ...};
new rtv_Needed = 0;
new rtv_Count = 0;
new Handle:cvar_RTV = INVALID_HANDLE;
new Handle:cvar_RTVplayers = INVALID_HANDLE;
new Handle:cvar_RTVdelay = INVALID_HANDLE;
#endif

#if DEBUG
new String:LogFilePath[PLATFORM_MAX_PATH];
#endif

//////////////////////
// Initial Load/End //
//////////////////////

public OnPluginStart()
{
	new arraySize = ByteCountToCells(65);
	g_MapListSingle = CreateArray(arraySize);	
	g_MapListHigh = CreateArray(arraySize);
	g_MapListMed = CreateArray(arraySize);
	g_MapListLow = CreateArray(arraySize);
	g_MapListIdle = CreateArray(arraySize);
	g_MapListTime = CreateArray(arraySize);
	g_OldMapListSingle = CreateArray(arraySize);
	g_OldMapListHigh = CreateArray(arraySize);
	g_OldMapListMed = CreateArray(arraySize);
	g_OldMapListLow = CreateArray(arraySize);
	g_OldMapListIdle = CreateArray(arraySize);
	g_OldMapListTime = CreateArray(arraySize);
	g_OldMapListMaster = CreateArray(arraySize);
	g_TimeTierTimes = CreateArray(9);
	
	decl String:TransPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, TransPath, sizeof(TransPath), "translations/randomcycleplus.phrases.txt");
	if (FileExists(TransPath))
	{
		LoadTranslations("randomcycleplus.phrases");
	} else {
		LogError("RandomCycle+ is unable to locate its translation file, please install");
		Error();
	}
	
	CreateConVar("sm_rcplus_version", PLUGIN_VERSION, "RandomCycle+ version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	cvar_ExMapsLow = CreateConVar("sm_rcplus_exclude_low", "-1", "Default setting for the number of most recent maps to remove from possible selection when player population is low (-1 to automatically pick based on tier size)", FCVAR_PLUGIN, true, -1.0);
	cvar_ExMapsMed = CreateConVar("sm_rcplus_exclude_med", "-1", "Default setting for the number of most recent maps to remove from possible selection when player population is medium (-1 to automatically pick based on tier size)", FCVAR_PLUGIN, true, -1.0);
	cvar_ExMapsHigh = CreateConVar("sm_rcplus_exclude_high", "-1", "Default setting for the number of most recent maps to remove from possible selection when player population is high (-1 to automatically pick based on tier size)", FCVAR_PLUGIN, true, -1.0);
	cvar_ExMapsSingle = CreateConVar("sm_rcplus_exclude_single", "-1", "Default setting for the number of most recent maps to remove from possible selection when running single tier mode (-1 to automatically pick based on tier size)", FCVAR_PLUGIN, true, -1.0);
	cvar_ExMapsIdle = CreateConVar("sm_rcplus_exclude_idle", "-1", "Default setting for the number of most recent maps to remove from possible selection when player population is zero (-1 to automatically pick based on tier size)", FCVAR_PLUGIN, true, -1.0);
	cvar_ExMapsRatio = CreateConVar("sm_rcplus_exclude_ratio", "0.4", "Ratio used when using the automatic settings for excluded maps", FCVAR_PLUGIN, true, 0.0, true, 0.99);
	cvar_LowPlayerCount = CreateConVar("sm_rcplus_players_low", "8", "Populations less than and equal to this value will trigger lower sized maps (0 to disable)", FCVAR_PLUGIN, true, 0.0, true, float(MAXPLAYERS));
	cvar_HighPlayerCount = CreateConVar("sm_rcplus_players_high", "14", "Populations greater than and equal to this value will use higher sized maps (0 to disable). Medium sized maps are used when the population is between the high and low values. If there are no numbers between the two values, the medium tier is disabled", FCVAR_PLUGIN, true, 0.0, true, float(MAXPLAYERS));
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
	#if RTV
	cvar_RTV = CreateConVar("sm_rcplus_rtv", "0", "RTV pass rate (0 to disable, also disabled if normal RTV plugin detected)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_RTVplayers = CreateConVar("sm_rcplus_rtv_players", "0", "Minimum player population needed on the server to enable RTV", FCVAR_PLUGIN, true, 0.0, true, float(MAXPLAYERS));
	cvar_RTVdelay = CreateConVar("sm_rcplus_rtv_delay", "0", "Delay (in seconds) until RTV can start", FCVAR_PLUGIN, true, 0.0);
	#endif
	
	RegAdminCmd("sm_rcplus_reload", Command_Reload, ADMFLAG_CHANGEMAP, "Reloads RandomCycle+ maplists");
	RegAdminCmd("sm_rcplus_resume", Command_Resume, ADMFLAG_CHANGEMAP, "Resumes RandomCycle+ if the nextmap has been changed externally");
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	
	g_NextMap = FindConVar("sm_nextmap");
	
	HookConVarChange(g_NextMap, ConVarChanged_NextMap);
	HookConVarChange(cvar_SingleTier, ConVarChanged_ReloadTiers);
	HookConVarChange(cvar_UseTimeTiers, ConVarChanged_ReloadTiers);
	HookConVarChange(cvar_ExMapsSingle, ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_ExMapsIdle, ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_ExMapsHigh, ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_ExMapsMed, ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_ExMapsLow, ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_LowPlayerCount, ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_HighPlayerCount, ConVarChanged_ReloadMaplist);
	HookConVarChange(cvar_UseIdleTier, ConVarChanged_Idle);
	
	flags_g_NextMap = GetConVarFlags(g_NextMap);
	oldflags_g_NextMap = flags_g_NextMap;
	
	AutoExecConfig(true, "plugin.randomcycleplus");
}

Error()
{
	SetFailState("RandomCycle+ encountered a major error, please read your sourcemod logs for more info");
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
	#if RTV
	LogToFileEx(LogFilePath, "sm_rcplus_rtv = \"%f\"", GetConVarFloat(cvar_RTV)); 
	LogToFileEx(LogFilePath, "sm_rcplus_rtv_players = \"%d\"", GetConVarInt(cvar_RTVplayers));
	LogToFileEx(LogFilePath, "sm_rcplus_rtv_delay = \"%f\"", GetConVarFloat(cvar_RTVdelay)); 
	#endif
	#endif
	// Triggers a message if RandomCycle hasn't picked a map yet if
	// basetriggers is loaded
	new Handle:g_BaseTriggersLoaded = FindPluginByFile("basetriggers.smx");
	if (g_BaseTriggersLoaded != INVALID_HANDLE)
	{
		b_BaseTriggersLoaded = true;
	} else {
		b_BaseTriggersLoaded = false;
	}
	
	#if DEBUG
	if (b_BaseTriggersLoaded)
	{
		LogToFileEx(LogFilePath, "Base triggers plugin is loaded"); 
	}
	else
	{
		LogToFileEx(LogFilePath, "Base triggers plugin is NOT loaded"); 
	}
	#endif
	
	#if RTV
	// Disables/enables internal RTV if normal RTV detected
	new Handle:g_RTVLoaded = FindPluginByFile("rockthevote.smx");
	if (g_RTVLoaded != INVALID_HANDLE)
	{
		b_RTVLoaded = true;
	} else {
		b_RTVLoaded = false;
	}
	#endif
	
	#if DEBUG
	if (b_RTVLoaded)
	{
		LogToFileEx(LogFilePath, "Rock the Vote plugin is loaded"); 
	}
	else
	{
		LogToFileEx(LogFilePath, "Rock the Vote plugin is NOT loaded, internal RTV possible"); 
	}
	#endif
	
	h_IdleServer = INVALID_HANDLE;
	h_RandomCycleCheck = INVALID_HANDLE;
	
	LoadMaplist();
	
	b_PickMapHigh = true;
	b_PickMapMed = true;
	b_PickMapLow = true;
	b_PickMapSingle = true;
	b_PickMapTime = true;
	
	if (GetConVarInt(cvar_DisableHighTier) && GetConVarInt(cvar_DisableHighTier) == g_HighCount && !GetConVarInt(cvar_SingleTier))
	{
		b_DisableHighTier = true;
		g_HighCount = 0;
		#if DEBUG
		LogToFileEx(LogFilePath, "Disabling high tier due to the disable high tier count limit reached"); 
		#endif
	}
	
	// Gets the next map to use if the plugin disables
	if (b_NextMapChanged)
	{
		GetNextMap(oldnextmap, sizeof(oldnextmap));
	}
	#if DEBUG
	LogToFileEx(LogFilePath, "Old next map: %s", oldnextmap);
	#endif
	b_NextMapChanged = false;
	
	if (GetArraySize(g_OldMapListMaster) < GetMapHistorySize())
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "The master history list is smaller than current internal sm maphistory, using sm maphistory");
		#endif
		HistoryArray();
	}
	
	decl String:CurrentMap[65];
	GetCurrentMap(CurrentMap, sizeof(CurrentMap));
	PushArrayString(g_OldMapListMaster, CurrentMap);

	if (GetArraySize(g_OldMapListMaster) > GetConVarInt(cvar_MapHistorySize))
	{
		RemoveFromArray(g_OldMapListMaster, 0);
		#if DEBUG
		LogToFileEx(LogFilePath, "Trimmed master map history (current size: %d)", GetArraySize(g_OldMapListMaster));
		#endif
	}
	
	ReloadMapHistory();
	
	b_Loaded = true;
	
	if (!GetConVarInt(cvar_SingleTier))
	{
		h_RandomCycleCheck = CreateTimer(GetConVarFloat(cvar_PlayerCheckTime), t_RandomCycleCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		#if DEBUG
		LogToFileEx(LogFilePath, "Starting main rc+ check timer"); 
		#endif
	}
	
	// Optionally instantly check for players and change nextmap, this is always used if single tier is enabled
	if (GetConVarInt(cvar_MapStartCheck) || GetConVarInt(cvar_SingleTier))
	{
		#if DEBUG
		if (GetConVarInt(cvar_SingleTier))
		{
			LogToFileEx(LogFilePath, "Single tier mode detected, running main rc+ check"); 
		}
		else if (GetConVarInt(cvar_MapStartCheck))
		{
			LogToFileEx(LogFilePath, "Mapstart check enabled, running main rc+ check"); 
		}
		#endif
		RandomCycleCheck();
	}
	
	#if RTV
	if (b_RTVLoaded && GetConVarFloat(cvar_RTV) > 0)
	{
		LogError("%t", "RCP RTV Loaded");
	} 
	else if (GetConVarFloat(cvar_RTV) > 0) 
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "Enabling internal RTV (in %f seconds)", GetConVarFloat(cvar_RTVdelay)); 
		#endif
		CreateTimer(GetConVarFloat(cvar_RTVdelay), t_EnableRTV, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	#endif
	
	ServerIdleCheck();
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
	
	// Reset everything for the plugin to start choosing again
	g_CycleRun = 0;
	g_Players = 0;
	
	// RTV resets
	#if RTV
	b_rtv_ChangingMap = false;
	rtv_Count = 0;
	rtv_Needed = 0;
	#endif
	
	// Usual code for delayed load
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
	#if RTV
	b_rtv_Enable = false;
	for (new i=1; i<=MAXPLAYERS; i++)
	{
		rtv_Counted[i] = false;
	}
	#endif
	
	if (g_CycleRun == 3 && GetConVarInt(cvar_DisableHighTier))
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

public Action:t_RandomCycleCheck(Handle:timer_check)
{
	RandomCycleCheck();
	return Plugin_Continue;
}

public Action:t_IdleServer(Handle:timer_idle)
{
	g_MapList = g_MapListIdle;
	g_OldMapList = g_OldMapListIdle;
	GetRandomMap();
	
	if (GetConVarInt(cvar_LogMSG))
	{
		LogMessage("%t", "RCP Idle Server", map);
	}
	
	#if DEBUG
	LogToFileEx(LogFilePath, "Idle server, changing map to: %s", map); 
	#endif
	
	ForceChangeLevel(map, "Server idle");
	
	return Plugin_Stop;
}

#if RTV
public Action:t_EnableRTV(Handle:timer_enable_rtv)
{
	if (GetConVarFloat(cvar_RTV) > 0)
	{
		b_rtv_Enable = true;
		#if DEBUG
		LogToFileEx(LogFilePath, "Interal Rock the Vote now active"); 
		#endif
	}
	return Plugin_Stop;
}
#endif

LoadMaplist()
{

	#if DEBUG
	LogToFileEx(LogFilePath, "Loading maplists"); 
	#endif
	
	decl String:ConfigPath[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, ConfigPath, sizeof(ConfigPath), "configs/randomcycleplus.cfg");
	if (!FileExists(ConfigPath))
	{
		LogError("%t", "RCP No Config");
		Error();
	}
	
	new Handle:h_configfile = OpenFile(ConfigPath, "r");
	if (h_configfile == INVALID_HANDLE)
	{
		LogError("%t", "RCP No Read Config");
		Error();
	}
	
	g_ExcludeMapsSingle = GetConVarInt(cvar_ExMapsSingle);
	g_ExcludeMapsHigh = GetConVarInt(cvar_ExMapsHigh);
	g_ExcludeMapsMed = GetConVarInt(cvar_ExMapsMed);
	g_ExcludeMapsLow = GetConVarInt(cvar_ExMapsLow);
	g_ExcludeMapsIdle = GetConVarInt(cvar_ExMapsIdle);
		
	ClearArray(g_MapListSingle);
	ClearArray(g_MapListHigh);
	ClearArray(g_MapListMed);
	ClearArray(g_MapListLow);
	ClearArray(g_MapListIdle);
	ClearArray(g_MapListTime);
	ClearArray(g_TimeTierTimes);

	new bool:b_LowIsZero = false;
	new bool:b_HighIsZero = false;
	new bool:b_NoMedMaplist = false;
	p_High = GetConVarInt(cvar_HighPlayerCount);
	p_Low = GetConVarInt(cvar_LowPlayerCount);
	b_UseTimeTier = false;
	new SingleTierMode = GetConVarInt(cvar_SingleTier);
	new TimeTierMode = GetConVarInt(cvar_UseTimeTiers);
	
	decl String:line[255];
	new ConfigFilePosition;
	new bool:TimeTierFound = false;
	new bool:SearchForPopTiers = false;
	decl String:CurrentTimeTier[65];
	decl String:TimeTierConflict[65];
	decl String:SingleMap[65];
	decl String:TimeMap[65];
	decl String:HighMap[65];
	decl String:MedMap[65];
	decl String:LowMap[65];
	decl String:IdleMap[65];
	
	while(!IsEndOfFile(h_configfile))
	{
		ReadFileLine(h_configfile, line, sizeof(line));
		TrimString(line);
		if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
		{
			BreakString(line, line, sizeof(line));
			if (!StrContains(line, "High", false))
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
			else if (!StrContains(line, "Low", false))
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
	
	if (p_Low == p_High && !SingleTierMode)
	{
		LogError("%t", "RCP Same Player");
		CloseHandle(h_configfile);
		Error();
	}
	if (p_Low > p_High && p_High && !SingleTierMode)
	{
		LogError("%t", "RCP Reversed Player");
		CloseHandle(h_configfile);
		Error();
	}
	
	if (!p_Low)
	{
		b_LowIsZero = true;
	}
	if (!p_High)
	{
		b_HighIsZero = true;
	}
	if (p_High-1 == p_Low)
	{
		b_NoMedMaplist = true;
	}
	
	FileSeek(h_configfile, 0, 0);
	while(!IsEndOfFile(h_configfile))
	{
		ReadFileLine(h_configfile, line, sizeof(line));
		TrimString(line);
		if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
		{
			BreakString(line, line, sizeof(line));
			if (!StrContains(line, "Single", false))
			{
				if (StrContains(line, "EX", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "EX", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					g_ExcludeMapsSingle = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "Single exclude count changed to: %d (via normal EX config value)", g_ExcludeMapsSingle); 
					#endif
				}
				#if DEBUG
				LogToFileEx(LogFilePath, "Single maps:");
				#endif
				while (line[0] != '}') 
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
					{
						BreakString(line, SingleMap, sizeof(SingleMap));
						if (!IsMapValid(SingleMap))
						{
							LogError("%s %t", SingleMap, "RCP Map Error");
							continue;
						}
						if (FindStringInArray(g_MapListSingle, SingleMap) != -1)
						{
							LogError("%s %t", SingleMap, "RCP Dupe Map Single");
							continue;
						}
						PushArrayString(g_MapListSingle, SingleMap);
						#if DEBUG
						LogToFileEx(LogFilePath, "~ %s", SingleMap);
						#endif
						continue;
					}
				}
			}
			else if (!StrContains(line, "High", false) && !b_HighIsZero && !GetArraySize(g_MapListHigh))
			{
				if (StrContains(line, "EX", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "EX", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					g_ExcludeMapsHigh = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "High exclude count changed to: %d (via normal EX config value)", g_ExcludeMapsHigh); 
					#endif
				}
				#if DEBUG
				LogToFileEx(LogFilePath, "High maps:");
				#endif
				while (line[0] != '}')  
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
					{
						BreakString(line, HighMap, sizeof(HighMap));
						if (!IsMapValid(HighMap))
						{
							LogError("%s %t", HighMap, "RCP Map Error");
							continue;
						}
						if (FindStringInArray(g_MapListHigh, HighMap) != -1)
						{
							LogError("%s %t", HighMap, "RCP Dupe Map High");
							continue;
						}
						PushArrayString(g_MapListHigh, HighMap);
						#if DEBUG
						LogToFileEx(LogFilePath, "~ %s", HighMap);
						#endif
						continue; 
					}
				}
			}
			else if (!StrContains(line, "Med", false) && !b_NoMedMaplist && !b_HighIsZero && !b_LowIsZero && (!b_HighIsZero && !b_LowIsZero) && !GetArraySize(g_MapListMed))
			{
				if (StrContains(line, "EX", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "EX", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					g_ExcludeMapsMed = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "Medium exclude count changed to: %d (via normal EX config value)", g_ExcludeMapsMed); 
					#endif
				}
				#if DEBUG
				LogToFileEx(LogFilePath, "Med maps:");
				#endif
				while (line[0] != '}')  
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
					{
						BreakString(line, MedMap, sizeof(MedMap));
						if (!IsMapValid(MedMap))
						{
							LogError("%s %t", MedMap, "RCP Map Error");
							continue;
						}
						if (FindStringInArray(g_MapListMed, MedMap) != -1)
						{
							LogError("%s %t", MedMap, "RCP Dupe Map Med");
							continue;
						}
						PushArrayString(g_MapListMed, MedMap);
						#if DEBUG
						LogToFileEx(LogFilePath, "~ %s", MedMap);
						#endif
						continue;
					}
				}
			}
			else if (!StrContains(line, "Low", false) && !b_LowIsZero && !GetArraySize(g_MapListLow))
			{
				if (StrContains(line, "EX", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "EX", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					g_ExcludeMapsLow = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "Low exclude count changed to: %d (via normal EX config value)", g_ExcludeMapsLow); 
					#endif
				}
				#if DEBUG
				LogToFileEx(LogFilePath, "Low maps:");
				#endif
				while (line[0] != '}')  
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
					{
						BreakString(line, LowMap, sizeof(LowMap));
						if (!IsMapValid(LowMap))
						{
							LogError("%s %t", LowMap, "RCP Map Error");
							continue;
						}
						if (FindStringInArray(g_MapListLow, LowMap) != -1)
						{
							LogError("%s %t", LowMap, "RCP Dupe Map Low");
							continue;
						}
						PushArrayString(g_MapListLow, LowMap);
						#if DEBUG
						LogToFileEx(LogFilePath, "~ %s", LowMap);
						#endif
						continue;
					}
				}
			}
			else if (!StrContains(line, "Idle", false))
			{
				if (StrContains(line, "EX", false) != -1)
				{
					decl String:ExcludeValue[3];
					new ExcludeIndex = StrContains(line, "EX", false);
					Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
					g_ExcludeMapsIdle = StringToInt(ExcludeValue);
					#if DEBUG
					LogToFileEx(LogFilePath, "Idle exclude count changed to: %d (via normal EX config value)", g_ExcludeMapsIdle); 
					#endif
				}
				#if DEBUG
				LogToFileEx(LogFilePath, "Idle maps:");
				#endif
				while (line[0] != '}')  
				{
					ReadFileLine(h_configfile, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
					{
						BreakString(line, IdleMap, sizeof(IdleMap));
						if (!IsMapValid(IdleMap))
						{
							LogError("%s %t", IdleMap, "RCP Map Error");
							continue;
						}
						if (FindStringInArray(g_MapListIdle, IdleMap) != -1)
						{
							LogError("%s %t", IdleMap, "RCP Dupe Map Low");
							continue;
						}
						PushArrayString(g_MapListIdle, IdleMap);
						#if DEBUG
						LogToFileEx(LogFilePath, "~ %s", IdleMap);
						#endif
						continue;
					}
				}
			}
			else if (!StrContains(line, "TimeTier-", false) && TimeTierMode)
			{
				// I should probably kill myself for the following code
				decl String:Time[32];
				new TimeInt;
				new StringLength = strlen(line);
				new StringIndex = 0;
				decl String:SD[4], String:ED[4];
				new StartDay = 0;
				new EndDay = 0;
				
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
					LogError("\"%s\" %t", line, "RCP Time Format Error");
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
					b_UseTimeTier = true;
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMapsTime = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMapsTime = g_ExcludeMapsSingle;
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Timetier exclude count: %d", g_ExcludeMapsTime); 
					#endif
					if (TimeTierFound)
					{
						CloseHandle(h_configfile);
						LogError("%t", "RCP Time Tier Conflict", TimeTierConflict, CurrentTimeTier);
						Error();
					}
					TimeTierFound = true;
					Format(TimeTierConflict, sizeof(TimeTierConflict), CurrentTimeTier);
				}
				else
				{
					b_UseTimeTier = false;
				}
				
				if (b_UseTimeTier)
				{
					ConfigFilePosition = FilePosition(h_configfile);
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, TimeMap, sizeof(TimeMap));
							if (!StrContains(TimeMap, "TimeTierHigh", false) || !StrContains(TimeMap, "TimeTierMed", false) || !StrContains(TimeMap, "TimeTierLow", false) || !StrContains(TimeMap, "TimeTierIdle", false))
							{
								SearchForPopTiers = true;
								ClearArray(g_MapListTime);
								continue;
							}
							if (!IsMapValid(TimeMap))
							{
								LogError("%s %t", TimeMap, "RCP Map Error");
								continue;
							}
							if (FindStringInArray(g_MapListTime, TimeMap) != -1)
							{
								LogError("%s %t (%t: %s)", TimeMap, "RCP Dupe Map Time", "RCP Time Tier", CurrentTimeTier);
								continue;
							}
							if (!SearchForPopTiers)
							{
								#if DEBUG
								if (!GetArraySize(g_MapListTime))
								{
									LogToFileEx(LogFilePath, "Single time tier maps:");
								}
								#endif
								PushArrayString(g_MapListTime, TimeMap);
								#if DEBUG
								LogToFileEx(LogFilePath, "~ %s", TimeMap);
								#endif
							}
							continue;
						} 	
					}
				}
			}
		}
	}
	
	if (SearchForPopTiers)
	{
		FileSeek(h_configfile, ConfigFilePosition, 0);
		ReadFileLine(h_configfile, line, sizeof(line));
		TrimString(line);
		while(line[0] != '}')
		{
			ReadFileLine(h_configfile, line, sizeof(line));
			TrimString(line);
			if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
			{
				BreakString(line, line, sizeof(line));
				if (!StrContains(line, "TimeTierHigh", false))
				{
					ClearArray(g_MapListHigh);
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMapsHigh = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMapsHigh = GetConVarInt(cvar_ExMapsHigh);
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier high exclude count: %d", g_ExcludeMapsHigh); 
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
					ClearArray(g_MapListMed);
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMapsMed = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMapsMed = GetConVarInt(cvar_ExMapsMed);
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier med exclude count: %d", g_ExcludeMapsMed); 
					#endif
				}
				else if (!StrContains(line, "TimeTierLow", false))
				{
					ClearArray(g_MapListLow);
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMapsLow = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMapsLow = GetConVarInt(cvar_ExMapsLow);
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier low exclude count: %d", g_ExcludeMapsLow); 
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
					ClearArray(g_MapListIdle);
					if (StrContains(line, "EX", false) != -1)
					{
						decl String:ExcludeValue[3];
						new ExcludeIndex = StrContains(line, "EX", false);
						Format(ExcludeValue, sizeof(ExcludeValue), line[ExcludeIndex+2]);
						g_ExcludeMapsIdle = StringToInt(ExcludeValue);
					}
					else
					{
						g_ExcludeMapsIdle = GetConVarInt(cvar_ExMapsIdle);
					}
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier idle exclude count: %d", g_ExcludeMapsIdle); 
					#endif
				}
			}
		}
		
		if (p_Low == p_High)
		{
			LogError("%t (%t: %s)", "RCP Same Player", "RCP Time Tier", CurrentTimeTier);
			CloseHandle(h_configfile);
			Error();
		}
		if (p_Low > p_High && p_High)
		{
			LogError("%t (%t: %s)", "RCP Reversed Player", "RCP Time Tier", CurrentTimeTier);
			CloseHandle(h_configfile);
			Error();
		}
		
		if (!p_Low)
		{
			b_LowIsZero = true;
		}
		if (!p_High)
		{
			b_HighIsZero = true;
		}
		if (p_High-1 == p_Low)
		{
			b_NoMedMaplist = true;
		}
		else
		{
			b_NoMedMaplist = false;
		}
		
		FileSeek(h_configfile, ConfigFilePosition, 0);
		ReadFileLine(h_configfile, line, sizeof(line));
		TrimString(line);
		while(line[0] != '}')
		{
			ReadFileLine(h_configfile, line, sizeof(line));
			TrimString(line);
			if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
			{
				BreakString(line, line, sizeof(line));
				if (!StrContains(line, "TimeTierHigh", false) && !b_HighIsZero)
				{
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier high maps:");
					#endif
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, HighMap, sizeof(HighMap));
							if (!IsMapValid(HighMap))
							{
								LogError("%s %t", HighMap, "RCP Map Error");
								continue;
							}
							if (FindStringInArray(g_MapListHigh, HighMap) != -1)
							{
								LogError("%s %t (%t: %s)", HighMap, "RCP Dupe Map High", "RCP Time Tier", CurrentTimeTier);
								continue;
							}
							PushArrayString(g_MapListHigh, HighMap);
							#if DEBUG
							LogToFileEx(LogFilePath, "~ %s", HighMap);
							#endif
							continue;
						} 
					}
				}
				else if (!StrContains(line, "TimeTierMed", false) && !b_NoMedMaplist && !b_HighIsZero && !b_LowIsZero && (!b_HighIsZero && !b_LowIsZero))
				{
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier med maps:");
					#endif
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, MedMap, sizeof(MedMap));
							if (!IsMapValid(MedMap))
							{
								LogError("%s %t", MedMap, "RCP Map Error");
								continue;
							}
							if (FindStringInArray(g_MapListMed, MedMap) != -1)
							{
								LogError("%s %t (%t: %s)", MedMap, "RCP Dupe Map Med", "RCP Time Tier", CurrentTimeTier);
								continue;
							}
							PushArrayString(g_MapListMed, MedMap);
							#if DEBUG
							LogToFileEx(LogFilePath, "~ %s", MedMap);
							#endif
							continue;
						} 
					}
				}
				else if (!StrContains(line, "TimeTierLow", false) && !b_LowIsZero)
				{
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier low maps:");
					#endif
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, LowMap, sizeof(LowMap));
							if (!IsMapValid(LowMap))
							{
								LogError("%s %t", LowMap, "RCP Map Error");
								continue;
							}
							if (FindStringInArray(g_MapListLow, LowMap) != -1)
							{
								LogError("%s %t (%t: %s)", LowMap, "RCP Dupe Map Low", "RCP Time Tier", CurrentTimeTier);
								continue;
							}
							PushArrayString(g_MapListLow, LowMap);
							#if DEBUG
							LogToFileEx(LogFilePath, "~ %s", LowMap);
							#endif
							continue;
						} 
					}
				}
				else if (!StrContains(line, "TimeTierIdle", false))
				{
					#if DEBUG
					LogToFileEx(LogFilePath, "Time tier idle maps:");
					#endif
					while (line[0] != '}') 
					{
						ReadFileLine(h_configfile, line, sizeof(line));
						TrimString(line);
						if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '{' && line[0] != '}' && line[0] != '*')
						{
							BreakString(line, IdleMap, sizeof(IdleMap));
							if (!IsMapValid(LowMap))
							{
								LogError("%s %t", IdleMap, "RCP Map Error");
								continue;
							}
							if (FindStringInArray(g_MapListIdle, IdleMap) != -1)
							{
								LogError("%s %t (%t: %s)", IdleMap, "RCP Dupe Map Low", "RCP Time Tier", CurrentTimeTier);
								continue;
							}
							PushArrayString(g_MapListIdle, IdleMap);
							#if DEBUG
							LogToFileEx(LogFilePath, "~ %s", IdleMap);
							#endif
							continue;
						} 
					}
				}
			}
		}
	}
		
	CloseHandle(h_configfile);
	
	if (b_UseTimeTier && GetArraySize(g_MapListTime))
	{
		b_UsePopulationTier = false;
	}
	else
	{
		b_UsePopulationTier = true;
	}
	
	if (!b_PickMapHigh)
	{
		if (GetArraySize(g_MapListHigh) && FindStringInArray(g_MapListHigh, maphigh) == -1)
		{
			b_PickMapHigh = true;
			if (g_CycleRun == 3)
			{
				g_CycleRun = 0;
			}
		}
	}
		
	if (!b_PickMapMed)
	{
		if (GetArraySize(g_MapListMed) && FindStringInArray(g_MapListMed, mapmed) == -1)
		{
			b_PickMapMed = true;
			if (g_CycleRun == 2)
			{
				g_CycleRun = 0;
			}
		}
	}
		
	if (!b_PickMapLow)
	{
		if (GetArraySize(g_MapListLow) && FindStringInArray(g_MapListLow, maplow) == -1)
		{
			b_PickMapLow = true;
			if (g_CycleRun == 1)
			{
				g_CycleRun = 0;
			}
		}
	}
		
	if (!b_PickMapSingle)
	{
		if (GetArraySize(g_MapListSingle) && FindStringInArray(g_MapListSingle, mapsingle) == -1)
		{
			b_PickMapSingle = true;
			if (g_CycleRun == 10)
			{
				g_CycleRun = 0;
			}
		}
	}
	
	if (!b_PickMapTime)
	{
		if (GetArraySize(g_MapListTime) && FindStringInArray(g_MapListTime, maptimetier) == -1)
		{
			b_PickMapTime = true;
			if (g_CycleRun == 20)
			{
				g_CycleRun = 0;
			}
		}
	}
	
	// Set the automatic exclude valies, if applicable
	switch (g_ExcludeMapsTime)
	{
		case -1:
			g_ExcludeMapsTime = RoundToNearest(GetConVarFloat(cvar_ExMapsRatio) * GetArraySize(g_MapListTime));
	}
	switch (g_ExcludeMapsSingle)
	{
		case -1:
			g_ExcludeMapsSingle = RoundToNearest(GetConVarFloat(cvar_ExMapsRatio) * GetArraySize(g_MapListSingle));
	}
	switch (g_ExcludeMapsHigh)
	{
		case -1:
			g_ExcludeMapsHigh = RoundToNearest(GetConVarFloat(cvar_ExMapsRatio) * GetArraySize(g_MapListHigh));
	}
	switch (g_ExcludeMapsMed)
	{
		case -1:
			g_ExcludeMapsMed = RoundToNearest(GetConVarFloat(cvar_ExMapsRatio) * GetArraySize(g_MapListMed));
	}
	switch (g_ExcludeMapsLow)
	{
		case -1:
			g_ExcludeMapsLow = RoundToNearest(GetConVarFloat(cvar_ExMapsRatio) * GetArraySize(g_MapListLow));
	}
	switch (g_ExcludeMapsIdle)
	{
		case -1:
			g_ExcludeMapsIdle = RoundToNearest(GetConVarFloat(cvar_ExMapsRatio) * GetArraySize(g_MapListIdle));
	}
	
	// The SetFailState in here is needed otherwise source crashes!
	if (GetArraySize(g_MapListHigh) <= g_ExcludeMapsHigh && !b_HighIsZero)
	{
		if (b_UseTimeTier && b_UsePopulationTier)
		{
			LogError("%t (%t: %s): %t", "RCP High", "RCP Time Tier", CurrentTimeTier, "RCP Exclude Error");
			Error();
		} 
		else if (!SingleTierMode)
		{
			LogError("%t: %t", "RCP High", "RCP Exclude Error");
			Error();
		}
	}

	if (GetArraySize(g_MapListMed) <= g_ExcludeMapsMed && !b_NoMedMaplist && !b_HighIsZero && !b_LowIsZero && (!b_HighIsZero && !b_LowIsZero))
	{
		if (b_UseTimeTier && b_UsePopulationTier)
		{
			LogError("%t (%t: %s): %t", "RCP Med", "RCP Time Tier", CurrentTimeTier, "RCP Exclude Error");
			Error();
		} 
		else if (!SingleTierMode)
		{
			LogError("%t: %t", "RCP Med", "RCP Exclude Error");
			Error();
		}
	}
	
	if (GetArraySize(g_MapListLow) <= g_ExcludeMapsLow && !b_LowIsZero)
	{
		if (b_UseTimeTier && b_UsePopulationTier)
		{
			LogError("%t (%t: %s): %t", "RCP Low", "RCP Time Tier", CurrentTimeTier, "RCP Exclude Error");
			Error();
		} 
		else if (!SingleTierMode)
		{
			LogError("%t: %t", "RCP Low", "RCP Exclude Error");
			Error();
		}
	}
	
	if (GetArraySize(g_MapListIdle) && GetArraySize(g_MapListIdle) <= g_ExcludeMapsIdle && GetConVarInt(cvar_UseIdleTier))
	{
		if (b_UseTimeTier && b_UsePopulationTier)
		{
			LogError("%t (%t: %s): %t", "RCP Low", "RCP Time Tier", CurrentTimeTier, "RCP Exclude Error");
		} 
		else
		{
			LogError("%t: %t", "RCP Idle", "RCP Exclude Error");
		}
		Error();
	}
	
	if (SingleTierMode && GetArraySize(g_MapListSingle) <= g_ExcludeMapsSingle)
	{
		LogError("%t %t", "RCP Single", "RCP Exclude Error");
		Error();
	}
	
	if (TimeTierMode && b_UseTimeTier && GetArraySize(g_MapListTime) && GetArraySize(g_MapListTime) <= g_ExcludeMapsTime)
	{
		LogError("%t (%s): %t", "RCP Time", CurrentTimeTier, "RCP Exclude Error");
		Error();
	}

}

/////////////
// 'Hooks' //
/////////////

public ConVarChanged_Idle(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (b_Loaded)
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "Idle mode enabled, checking settings");
		#endif
		ServerIdleCheck();
	}
}

public ConVarChanged_ReloadTiers(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (b_Loaded)
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "Important cvar change, reloading settings");
		#endif
		LoadMaplist();
		ReloadMapHistory();
		RandomCycleCheck();
		if (GetConVarInt(cvar_SingleTier) && (!b_UseTimeTier || !GetConVarInt(cvar_UseTimeTiers)))
		{
			CloseHandle(h_RandomCycleCheck);
			h_RandomCycleCheck = INVALID_HANDLE;
			#if DEBUG
			LogToFileEx(LogFilePath, "Single tier mode is running, no time tiers, killing rc+ check timer");
			#endif
		}
	}
}

public ConVarChanged_ReloadMaplist(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (b_Loaded)
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "Player count/exclude value cvar changed, reloading maplists");
		#endif
		LoadMaplist();
	}
}

public ConVarChanged_NextMap(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// If anything happens to change the nextmap externally this
	// will stop the plugin from picking any further changes
	b_NextMapChanged = true;
}

public OnClientConnected(client)
{
	if(IsFakeClient(client))
	{
		return;
	}
	
	g_Players++;
	
	#if RTV
	rtv_Counted[client] = false;
	rtv_Needed = RoundToFloor(float(g_Players) * GetConVarFloat(cvar_RTV));
	
	if (rtv_Needed < 1)
	{
		rtv_Needed = 1;
	}
	#endif
	
	if (h_IdleServer != INVALID_HANDLE)
	{
		CloseHandle(h_IdleServer);
		h_IdleServer = INVALID_HANDLE;
		#if DEBUG
		LogToFileEx(LogFilePath, "Killed idle timer due to player connect");
		#endif
		RandomCycleCheck();
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
	
	#if RTV
	if (rtv_Counted[client])
	{
		rtv_Count--;
	}
	
	rtv_Needed = RoundToFloor(float(g_Players) * GetConVarFloat(cvar_RTV));
	
	if (rtv_Needed < 1)
	{
		rtv_Needed = 1;
	}
	
	if (!g_Players)
	{
		ServerIdleCheck();
	}
	
	if (!b_rtv_Enable || b_RTVLoaded)
	{
		return;
	}
	
	if (g_Players && rtv_Count >= rtv_Needed && b_rtv_Enable)
	{
		RCPRTV();
	}
	#endif
}

//////////////
// Commands //
//////////////

public Action:Command_Reload(client, args)
{	
	#if DEBUG
	LogToFileEx(LogFilePath, "Reload admin command has been executed");
	#endif
	LoadMaplist();
	ReloadMapHistory();
	RandomCycleCheck();
	ReplyToCommand(client, "[SM] %t", "RCP Reloaded");
	LogMessage("\"%L\" %t", client, "RCP Reloaded Log");
}

public Action:Command_Resume(client, args)
{	
	#if DEBUG
	LogToFileEx(LogFilePath, "Resume admin command has been executed");
	#endif
	// Admins can run this to resume the plugin if needed
	b_NextMapChanged = false;
	g_CycleRun = 0;
	RandomCycleCheck();
	ShowActivity(client, "%t", "RCP Resumed");
	LogMessage("\"%L\" %t", client, "RCP Resumed");
}

public Action:Command_Say(client, args)
{
	// Grabs the nextmap chat trigger and if the plugin has not
	// picked a map it replies saying so, also rtv triggers if
	// applicable
	decl String:text[192], String:command[64];
	if (GetCmdArgString(text, sizeof(text)) < 1)
	{
		return Plugin_Continue;
	}
	
	new startidx;
	if (text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	
	if (!strcmp(command, "say2", false))
	{
		startidx += 4;
	}
	
	decl String:message[8];
	BreakString(text[startidx], message, sizeof(message));
 
	if (!strcmp(message, "nextmap", false) && !g_CycleRun && !b_NextMapChanged && b_BaseTriggersLoaded)
	{
		PrintToChatAll("[SM] %t", "RCP Early Nextmap");
	}
	
	// RTV portion of the chat hooks
	#if RTV
	new ReplySource:rtvreply = SetCmdReplySource(SM_REPLY_TO_CHAT);
	if (!strcmp(message, "rtv", false) || !strcmp(message, "rockthevote", false))
	{
		RCPRTVCheck(client);
	}
	SetCmdReplySource(rtvreply);
	#endif
	return Plugin_Continue;
}

//////////////////
// Internal RTV //
//////////////////

#if RTV
RCPRTVCheck(client)
{
	if (b_RTVLoaded || b_rtv_ChangingMap || GetConVarFloat(cvar_RTV) == 0)
	{
		return;
	}
	
	if (!b_rtv_Enable)
	{
		ReplyToCommand(client, "[SM] %t", "RCP RTV NA");
		return;
	}
	
	if (g_Players < GetConVarInt(cvar_RTVplayers))
	{
		ReplyToCommand(client, "[SM] %t", "RCP RTV Min", GetConVarInt(cvar_RTVplayers), g_Players);
		return;
	}
	
	if (rtv_Counted[client])
	{
		ReplyToCommand(client, "[SM] %t", "RCP RTV Voted");
		return;
	}
	
	rtv_Counted[client] = true;
	rtv_Count++;
	
	PrintToChatAll("[SM] %N: %t (%d/%d)", client, "RCP RTV OK", rtv_Count, rtv_Needed);
	
	if (g_Players && rtv_Count >= rtv_Needed)
	{
		RCPRTV();
	}
}

RCPRTV()
{
	if (b_rtv_ChangingMap)
	{
		return;
	}
	
	RandomCycleCheck();
	
	decl String:NextMap[65];
	
	if (GetNextMap(NextMap, sizeof(NextMap)))
	{
		PrintToChatAll("[SM] %t %s", "RCP RTV Pass", NextMap);
		LogMessage("%t %s", "RCP RTV Pass Log", NextMap);
		
		new Handle:RTVMap;
		b_rtv_ChangingMap = true;
		
		CreateDataTimer(5.0, LoadRTVMap, RTVMap, TIMER_FLAG_NO_MAPCHANGE);
		
		WritePackString(RTVMap, NextMap);
		
		rtv_Count = 0;
		
		for (new i=1; i<=MAXPLAYERS; i++)
		{
			rtv_Counted[i] = false;
		}
	}
}

public Action:LoadRTVMap(Handle:timer_rtv, Handle:RTVMap)
{
	decl String:NextMap[65];
	ResetPack(RTVMap);
	ReadPackString(RTVMap, NextMap, sizeof(NextMap));
	#if DEBUG
	LogToFileEx(LogFilePath, "Changing map due to RTV (%s)", NextMap);
	#endif
	ForceChangeLevel(NextMap, "RC+ RTV");
	return Plugin_Stop;
}

RTVReEnableCheck()
{
	new Handle:g_RTVLoaded = FindPluginByFile("rockthevote.smx");
	if (g_RTVLoaded != INVALID_HANDLE)
	{
		b_RTVLoaded = true;
	} else {
		b_RTVLoaded = false;
	}
	
	#if DEBUG
	if (b_RTVLoaded)
	{
		LogToFileEx(LogFilePath, "Rock the Vote plugin is loaded"); 
	}
	else
	{
		LogToFileEx(LogFilePath, "Rock the Vote plugin is NOT loaded, internal RTV possible"); 
	}
	#endif
	
	if (GetConVarFloat(cvar_RTV) > 0 && !b_RTVLoaded && !b_rtv_Enable && g_CycleRun != 4)
	{
		b_rtv_Enable = true;
		if (g_Players && rtv_Count >= rtv_Needed)
		{
			RCPRTV();
		}
	}
}
#endif

//////////////
// RC+ Main //
//////////////

RandomCycleCheck()
{
	#if DEBUG
	LogToFileEx(LogFilePath, "Running main rc+ check");
	#endif
	
	// All the checks for what map to pick!
	if (b_NextMapChanged || !b_Loaded || h_IdleServer != INVALID_HANDLE)
	{
		return;
	}
	
	#if RTV
	if (b_rtv_ChangingMap)
	{
		return;
	}
	#endif
	
	new SingleTierMode = GetConVarInt(cvar_SingleTier);
	new TimeTierMode = GetConVarInt(cvar_UseTimeTiers);
	
	if (TimeTierMode)
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "Checking if time tier needs enabling yet");
		#endif
		StartTimeTier();
	}
	
	// Continues the timer if single tier has just been disabled or time tiers are on
	if ((!SingleTierMode || GetConVarInt(cvar_UseTimeTiers)) && h_RandomCycleCheck == INVALID_HANDLE)
	{
		h_RandomCycleCheck = CreateTimer(GetConVarFloat(cvar_PlayerCheckTime), t_RandomCycleCheck, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		#if DEBUG
		LogToFileEx(LogFilePath, "Resumed main rc+ check timer");
		#endif
	} 
	
	if (TimeTierMode && b_UseTimeTier && !b_UsePopulationTier && g_CycleRun != 20)
	{
		g_CycleRun = 20;
		if (b_PickMapTime)
		{
			g_MapList = g_MapListTime;
			g_OldMapList = g_OldMapListTime;
			GetRandomMap();
			maptimetier = map;
		}
		setmap = maptimetier;
		SetRandomMap();
		b_PickMapTime = false;
		#if RTV
		RTVReEnableCheck();
		#endif
		#if DEBUG
		LogToFileEx(LogFilePath, "rc+ set time tier map: %s", setmap);
		#endif
		return;
	}
	
	if (!b_UseTimeTier && SingleTierMode && b_UsePopulationTier && g_CycleRun != 10)
	{
		g_CycleRun = 10;
		if (b_PickMapSingle)
		{
			g_MapList = g_MapListSingle;
			g_OldMapList = g_OldMapListSingle;
			GetRandomMap();
			mapsingle = map;
		}
		setmap = mapsingle;
		SetRandomMap();
		b_PickMapSingle = false;
		#if RTV
		RTVReEnableCheck();
		#endif
		#if DEBUG
		LogToFileEx(LogFilePath, "rc+ set single tier map: %s", setmap);
		#endif
		return;
	}
	
	// This allows the time tier population tiers to work
	if (b_UseTimeTier && b_UsePopulationTier && SingleTierMode)
	{
		SingleTierMode = false;
	}
	
	if (p_High && g_Players >= p_High && g_CycleRun != 3 && !b_DisableHighTier && !SingleTierMode && b_UsePopulationTier)
	{
		g_CycleRun = 3;
		if (b_PickMapHigh)
		{
			g_MapList = g_MapListHigh;
			g_OldMapList = g_OldMapListHigh;
			GetRandomMap();
			maphigh = map;
		}
		setmap = maphigh;
		SetRandomMap();
		b_PickMapHigh = false;
		#if RTV
		RTVReEnableCheck();
		#endif
		#if DEBUG
		LogToFileEx(LogFilePath, "rc+ set high tier map: %s", setmap);
		#endif
		return;
	}
	
	if ((p_High && p_Low) && g_Players > p_Low && (g_Players < p_High || (b_DisableHighTier && g_Players >= p_High && p_High-1 != p_Low)) && g_CycleRun != 2 && !SingleTierMode && b_UsePopulationTier)
	{
		g_CycleRun = 2;
		if (b_PickMapMed)
		{
			g_MapList = g_MapListMed;
			g_OldMapList = g_OldMapListMed;
			GetRandomMap();
			mapmed = map;
		}
		setmap = mapmed;
		SetRandomMap();
		b_PickMapMed = false;
		#if RTV
		RTVReEnableCheck();
		#endif
		#if DEBUG
		LogToFileEx(LogFilePath, "rc+ set med tier map: %s", setmap);
		#endif
		return;
	}
	
	if (p_Low && (g_Players <= p_Low || (b_DisableHighTier && (!p_High || p_High-1 == p_Low))) && g_CycleRun != 1 && !SingleTierMode && b_UsePopulationTier)
	{
		g_CycleRun = 1;
		if (b_PickMapLow)
		{
			g_MapList = g_MapListLow;
			g_OldMapList = g_OldMapListLow;
			GetRandomMap();
			maplow = map;
		}
		setmap = maplow;
		SetRandomMap();
		b_PickMapLow = false;
		#if RTV
		RTVReEnableCheck();
		#endif
		#if DEBUG
		LogToFileEx(LogFilePath, "rc+ set low tier map: %s", setmap);
		#endif
		return;
	}
	
	// Checks to see if the plugin needs to disable or not based on the player counts
	// and set the old nextmap (based on default maplist).
	if 	((!p_Low && g_Players < p_High && p_High > p_Low && g_CycleRun != 4) || (!p_High && g_Players > p_Low && p_Low > p_High && g_CycleRun != 4) || (!p_High && !p_Low && g_CycleRun != 4) || (b_DisableHighTier && !p_Low && g_CycleRun != 4) && !SingleTierMode && b_UsePopulationTier)
	{
		if (GetConVarInt(cvar_NextMapHide))
		{
			HideNextMapConVar();
			SetNextMap(oldnextmap);
			ShowNextMapConVar();
		} else {
			SetNextMap(oldnextmap);
		}
		#if DEBUG
		LogToFileEx(LogFilePath, "rc+ is setting the old map: %s", oldnextmap);
		#endif
		b_NextMapChanged = false;
		#if RTV
		if (b_rtv_Enable)
		{
			b_rtv_Enable = false;
			for (new i=1; i<=MAXPLAYERS; i++)
			{
				rtv_Counted[i] = false;
			}
		}
		#endif
		g_CycleRun = 4;
		if (GetConVarInt(cvar_Announce))
		{
			PrintToChatAll("[SM] %t %s", "RCP Disable", oldnextmap);
		}
		if (GetConVarInt(cvar_LogMSG))
		{
			LogMessage("%t %s", "RCP Disable", oldnextmap);
		}
		return;
	}
}

HistoryArray()
{
	// We need to work our way BACKWARDS through the maphistory array 
	// so the maps go into the array in the right order
	// In 1.2.0+ this has changed to only call if the master map history
	// is not big enough or the plugin has been fully reloaded during
	// the middle of running the server
	decl String:HistoryMap[65];
	new HistorySize;
	new CurrentIndex;
	ClearArray(g_OldMapListMaster);
	HistorySize = GetMapHistorySize();
	
	if (HistorySize == 0)
	{
		return;
	} else {
		CurrentIndex = HistorySize-1;
		while (CurrentIndex >= 0)
		{
			decl String:reason[128], time;
			GetMapHistory(CurrentIndex, HistoryMap, sizeof(HistoryMap), reason, sizeof(reason), time);
			PushArrayString(g_OldMapListMaster, HistoryMap);
			CurrentIndex--;
		}
	}
}

StartTimeTier()
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
			if (!b_UseTimeTier)
			{
				LoadMaplist();
				ReloadMapHistory();
				// Just in case anything changes, I know
				if (b_UseTimeTier)
				{
					b_PickMapTime = true;
				}
			}
		} 
		else if (b_UseTimeTier)
		{
			LoadMaplist();
			ReloadMapHistory();
			// I set this just in case it loads another new time tier
			b_PickMapTime = true;
		}
	}
}

ReloadMapHistory()
{
	// Loads the full map history from the master array, this
	// gives RC+ a fuller history to look back upon
	// This also might seem a lot of checking but it takes
	// into account of the maplists changing and such
	
	if (GetArraySize(g_MapListSingle) > 0)
	{
		if (GetArraySize(g_OldMapListSingle) > 0)
		{
			new CurrentOldIndex = GetArraySize(g_OldMapListSingle)-1;
			while (CurrentOldIndex >= 0)
			{
				decl String:CheckOldMap[65];
				GetArrayString(g_OldMapListSingle, CurrentOldIndex, CheckOldMap, sizeof(CheckOldMap));
				if (FindStringInArray(g_MapListSingle, CheckOldMap) == -1)
				{
					ClearArray(g_OldMapListSingle);
					CurrentOldIndex = -1;
				}
				CurrentOldIndex--;
			}
		}
		new CurrentIndex = 0;
		while (CurrentIndex < GetArraySize(g_OldMapListMaster))
		{
			decl String:CheckMap[65];
			GetArrayString(g_OldMapListMaster, CurrentIndex, CheckMap, sizeof(CheckMap));
			if (FindStringInArray(g_MapListSingle, CheckMap) != -1)
			{
				new CheckArray = FindStringInArray(g_OldMapListSingle, CheckMap);
				if (CheckArray != -1)
				{
					RemoveFromArray(g_OldMapListSingle, CheckArray);
				}
				PushArrayString(g_OldMapListSingle, CheckMap);
				while (GetArraySize(g_OldMapListSingle) > g_ExcludeMapsSingle)
				{
					RemoveFromArray(g_OldMapListSingle, 0);
				}
			}
			CurrentIndex++;
		}
	}
	
	if (GetArraySize(g_MapListHigh) > 0)
	{
		if (GetArraySize(g_OldMapListHigh) > 0)
		{
			new CurrentOldIndex = GetArraySize(g_OldMapListHigh)-1;
			while (CurrentOldIndex >= 0)
			{
				decl String:CheckOldMap[65];
				GetArrayString(g_OldMapListHigh, CurrentOldIndex, CheckOldMap, sizeof(CheckOldMap));
				if (FindStringInArray(g_MapListHigh, CheckOldMap) == -1)
				{
					ClearArray(g_OldMapListHigh);
					CurrentOldIndex = -1;
				}
				CurrentOldIndex--;
			}
		}
		new CurrentIndex = 0;
		while (CurrentIndex < GetArraySize(g_OldMapListMaster))
		{
			decl String:CheckMap[65];
			GetArrayString(g_OldMapListMaster, CurrentIndex, CheckMap, sizeof(CheckMap));
			if (FindStringInArray(g_MapListHigh, CheckMap) != -1)
			{
				new CheckArray = FindStringInArray(g_OldMapListHigh, CheckMap);
				if (CheckArray != -1)
				{
					RemoveFromArray(g_OldMapListHigh, CheckArray);
				}
				PushArrayString(g_OldMapListHigh, CheckMap);
				while (GetArraySize(g_OldMapListHigh) > g_ExcludeMapsHigh)
				{
					RemoveFromArray(g_OldMapListHigh, 0);
				}
			}
			CurrentIndex++;
		}
	}
	
	if (GetArraySize(g_MapListMed) > 0)
	{
		if (GetArraySize(g_OldMapListMed) > 0)
		{
			new CurrentOldIndex = GetArraySize(g_OldMapListMed)-1;
			while (CurrentOldIndex >= 0)
			{
				decl String:CheckOldMap[65];
				GetArrayString(g_OldMapListMed, CurrentOldIndex, CheckOldMap, sizeof(CheckOldMap));
				if (FindStringInArray(g_MapListMed, CheckOldMap) == -1)
				{
					ClearArray(g_OldMapListMed);
					CurrentOldIndex = -1;
				}
				CurrentOldIndex--;
			}
		}
		new CurrentIndex = 0;
		while (CurrentIndex < GetArraySize(g_OldMapListMaster))
		{
			decl String:CheckMap[65];
			GetArrayString(g_OldMapListMaster, CurrentIndex, CheckMap, sizeof(CheckMap));
			if (FindStringInArray(g_MapListMed, CheckMap) != -1)
			{
				new CheckArray = FindStringInArray(g_OldMapListMed, CheckMap);
				if (CheckArray != -1)
				{
					RemoveFromArray(g_OldMapListMed, CheckArray);
				}
				PushArrayString(g_OldMapListMed, CheckMap);
				while (GetArraySize(g_OldMapListMed) > g_ExcludeMapsMed)
				{
					RemoveFromArray(g_OldMapListMed, 0);
				}
			}
			CurrentIndex++;
		}
	}
	
	if (GetArraySize(g_MapListLow) > 0)
	{
		if (GetArraySize(g_OldMapListLow) > 0)
		{
			new CurrentOldIndex = GetArraySize(g_OldMapListLow)-1;
			while (CurrentOldIndex >= 0)
			{
				decl String:CheckOldMap[65];
				GetArrayString(g_OldMapListLow, CurrentOldIndex, CheckOldMap, sizeof(CheckOldMap));
				if (FindStringInArray(g_MapListLow, CheckOldMap) == -1)
				{
					ClearArray(g_OldMapListLow);
					CurrentOldIndex = -1;
				}
				CurrentOldIndex--;
			}
		}
		new CurrentIndex = 0;
		while (CurrentIndex < GetArraySize(g_OldMapListMaster))
		{
			decl String:CheckMap[65];
			GetArrayString(g_OldMapListMaster, CurrentIndex, CheckMap, sizeof(CheckMap));
			if (FindStringInArray(g_MapListLow, CheckMap) != -1)
			{
				new CheckArray = FindStringInArray(g_OldMapListLow, CheckMap);
				if (CheckArray != -1)
				{
					RemoveFromArray(g_OldMapListLow, CheckArray);
				}
				PushArrayString(g_OldMapListLow, CheckMap);
				while (GetArraySize(g_OldMapListLow) > g_ExcludeMapsLow)
				{
					RemoveFromArray(g_OldMapListLow, 0);
				}
			}
			CurrentIndex++;
		}
	}
	
	if (GetArraySize(g_MapListIdle) > 0)
	{
		if (GetArraySize(g_OldMapListIdle) > 0)
		{
			new CurrentOldIndex = GetArraySize(g_OldMapListIdle)-1;
			while (CurrentOldIndex >= 0)
			{
				decl String:CheckOldMap[65];
				GetArrayString(g_OldMapListIdle, CurrentOldIndex, CheckOldMap, sizeof(CheckOldMap));
				if (FindStringInArray(g_MapListIdle, CheckOldMap) == -1)
				{
					ClearArray(g_OldMapListIdle);
					CurrentOldIndex = -1;
				}
				CurrentOldIndex--;
			}
		}
		new CurrentIndex = 0;
		while (CurrentIndex < GetArraySize(g_OldMapListMaster))
		{
			decl String:CheckMap[65];
			GetArrayString(g_OldMapListMaster, CurrentIndex, CheckMap, sizeof(CheckMap));
			if (FindStringInArray(g_MapListIdle, CheckMap) != -1)
			{
				new CheckArray = FindStringInArray(g_OldMapListIdle, CheckMap);
				if (CheckArray != -1)
				{
					RemoveFromArray(g_OldMapListIdle, CheckArray);
				}
				PushArrayString(g_OldMapListIdle, CheckMap);
				while (GetArraySize(g_OldMapListIdle) > g_ExcludeMapsIdle)
				{
					RemoveFromArray(g_OldMapListIdle, 0);
				}
			}
			CurrentIndex++;
		}
	}
	
	if (GetArraySize(g_MapListTime) > 0)
	{
		if (GetArraySize(g_OldMapListTime) > 0)
		{
			new CurrentOldIndex = GetArraySize(g_OldMapListTime)-1;
			while (CurrentOldIndex >= 0)
			{
				decl String:CheckOldMap[65];
				GetArrayString(g_OldMapListTime, CurrentOldIndex, CheckOldMap, sizeof(CheckOldMap));
				if (FindStringInArray(g_MapListTime, CheckOldMap) == -1)
				{
					ClearArray(g_OldMapListTime);
					CurrentOldIndex = -1;
				}
				CurrentOldIndex--;
			}
		}
		new CurrentIndex = 0;
		while (CurrentIndex < GetArraySize(g_OldMapListMaster))
		{
			decl String:CheckMap[65];
			GetArrayString(g_OldMapListMaster, CurrentIndex, CheckMap, sizeof(CheckMap));
			if (FindStringInArray(g_MapListTime, CheckMap) != -1)
			{
				new CheckArray = FindStringInArray(g_OldMapListTime, CheckMap);
				if (CheckArray != -1)
				{
					RemoveFromArray(g_OldMapListTime, CheckArray);
				}
				PushArrayString(g_OldMapListTime, CheckMap);
				while (GetArraySize(g_OldMapListTime) > g_ExcludeMapsTime)
				{
					RemoveFromArray(g_OldMapListTime, 0);
				}
			}
			CurrentIndex++;
		}
	}
}

GetRandomMap()
{	
	// Picks and sets what the nextmap will be, checks against
	// the MapHistory array to make sure that it isn't 
	// repeating itself
	new num = GetRandomInt(0, GetArraySize(g_MapList) - 1);
	GetArrayString(g_MapList, num, map, sizeof(map));

	while (FindStringInArray(g_OldMapList, map) != -1)
	{
		num = GetRandomInt(0, GetArraySize(g_MapList) - 1);
		GetArrayString(g_MapList, num, map, sizeof(map));
	}
}

SetRandomMap()
{
	// Applies the picked nextmap
	if (GetConVarInt(cvar_NextMapHide))
	{
		HideNextMapConVar();
		SetNextMap(setmap);
		ShowNextMapConVar();
	} else {
		SetNextMap(setmap);
	}
	
	b_NextMapChanged = false;
	
	if (GetConVarInt(cvar_Announce))
	{
		PrintToChatAll("[SM] %t %s", "RCP Nextmap", setmap);
	}
	
	if (GetConVarInt(cvar_LogMSG))
	{
		LogMessage("%t %s", "RCP Nextmap", setmap);
	}
}

ServerIdleCheck()
{
	#if DEBUG
	LogToFileEx(LogFilePath, "Running idle check");
	#endif
	if (GetConVarInt(cvar_UseIdleTier) && GetArraySize(g_MapListIdle) && !g_Players && h_IdleServer == INVALID_HANDLE)
	{
		decl String:CurrentMap[65];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		if (FindStringInArray(g_MapListIdle, CurrentMap) == -1)
		{
			if (h_RandomCycleCheck != INVALID_HANDLE)
			{
				CloseHandle(h_RandomCycleCheck);
				h_RandomCycleCheck = INVALID_HANDLE;
			}
			h_IdleServer = CreateTimer(GetConVarFloat(cvar_IdleTime), t_IdleServer, _, TIMER_FLAG_NO_MAPCHANGE);
			#if DEBUG
			LogToFileEx(LogFilePath, "Starting normal idle server timer");
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
			LogToFileEx(LogFilePath, "Starting rotating idle server timer");
			#endif
		}
	}
	else if (h_IdleServer != INVALID_HANDLE && !GetConVarInt(cvar_UseIdleTier))
	{
		CloseHandle(h_IdleServer);
		h_IdleServer = INVALID_HANDLE;
		#if DEBUG
		LogToFileEx(LogFilePath, "Killed idle server timer");
		#endif
		RandomCycleCheck();
	}
}

HideNextMapConVar()
{
	flags_g_NextMap &= ~FCVAR_NOTIFY;
	SetConVarFlags(g_NextMap, flags_g_NextMap);
}

ShowNextMapConVar()
{
	SetConVarFlags(g_NextMap, oldflags_g_NextMap);
}