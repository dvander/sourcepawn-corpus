/**
 * =====================================================================================
 *  RandomCycle+ Change Log
 * =====================================================================================
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
 * - Disabling of high tier takes into account if the server population dips in-between 
 *   maps.
 * - If the single tier happens to get disabled the timer check will start up again and
 *   continue to check for players, single tier cvar change now hooked too so it will 
 *   instantly enable or disable.
 * - Disabled check array command in default build, uncomment to enable again if you 
 *   wish, but this command is now defunct.
 *
 * 1.1.1a
 * - Fixed start of map check not working.
 *
 * 1.2.0
 * - Map history code now drastically recoded, will now remember the FULL past high, 
 *   medium and low tier maps rather than not using the past x maps recently played.
 * - Cvar added to control the size of the internal RC+ maphistory.
 *
 * 1.2.1
 * - Fixed single tier mode history bug.
 *
 * 1.3.0
 * - Added support for time specific rotations.
 * - Improved the map history if using multiple types of tiers.
 * - Optimised single tier mode so you don't need to fill out the other tiers if they
 *   are unused on your server.
 * - Removed dupe map check for the whole low to high cycle and the cvar that controls 
 *   this due to the way the plugin now handles the map history.
 * - Improved error reporting.
 * - A few general optimisations and improvements.
 *
 * 1.3.0a
 * - Small bugfix with single tier mode enabled on startup causing the early nextmap
 *   trigger to show.
 *
 * 1.3.1
 * - Added population support to time tiers.
 * - Added in validating of time tiers to check if they clash or not.
 * - Better detection of incorrect cvar values with single tier mode enabled which 
 *   will let single tier mode to continue.
 * - Time tiers now correctly override single tier mode.
 * - Further small improvements.
 *
 * 1.3.2
 * - Lots of very small fixes.
 * - Added "automatic" cvar value for excludes and is now the new default ("-1") this
 *   will automatically exclude roughly 40% of the maps on your list (this value is 
 *   rounded to the nearest value). Also added a cvar to control this ratio.
 * - Added idle server support, also works with time tiers. Also setup a cvar to control
 *   if RC+ rotates through your idle maps or keeps on one idle map until players join 
 *   the server.
 * - Added PL/EX support to normal tiers.
 * - Changed mapstart check default to 1.
 * - Removed max time restriction on main rc+ check time setting.
 *
 * 1.3.2.1
 * - Fixed closing the timer when applicable for the main check when single tier mode is
 *   enabled mid game. 
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
 * - Main tiers renamed and single time tiers have now changed, PLEASE CHECK THE NEW 
 *   CONFIGURATION FILE, this is to avoid possible conflicts.
 * - General code facelift, performence is now vastly optimised.
 * - Removed RTV code, seperate modified plugins are better for this.
 * - Removed the basetriggers detection code, not really needed now.
 * - Added extra idle tier support to regular single time tiers.
 * - Added +/- support to time tiers. This is so you can easily add or remove maps 
 *   from a tier during certain times.
 * - Provided better fallbacks if anything goes wrong rather than halting the plugin.
 * - Better error feedback.
 * - Added a cvar to control where the rc+ configuration file is. Defaults to 
 *   randomcycleplus.cfg in the config folder in SM root when not set.
 * - Fixed some translation errors and trimmed the file itself.
 * - Re-done the config file to show better examples on how to set it up.
 * - Added "automatic" (-1) settings for player load cvar's. Also new default. 
 *   Less than equals 1/3 for low, more than equals 2/3 for high. Rounds to nearest.
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
 * - Rolled back current map array, fixes a pretty major map picking bug. 
 * - Fixed some debug code.
 * - Added slight delay to initial mapstart check (basically waits long enough so it can
 *   check for connected players).
 *
 * 1.4.1.1
 * - New map fallback, 100% safe map fallback when plugin is no longer in control.
 *
 * 1.4.1.2
 * - Fixed handle error when cvar settings change mid-game and rc+ check is not running.
 *
 * 1.4.1.3
 * - Fixed some spelling mistakes!
 * - Fixed some fallbacks.
 *
 * 2.0
 * - Major changes to randomcycle configuration, more control over cycles. See new
 *   config for more info.
 * - Some changes to cvars and changed for more "logic". Read plugin config for more 
 *   info. Highly likely most users will need to reconfigure.
 * - Added a cvar to change the default cycle "sm_rcplus_usecycle", will fallback to
 *   use the "default" cycle in the config if not found.
 * - Removed check on mapstart cvar, checking is now done when needed on player
 *   connect/disconnect.
 * - Added cvar execution support when certain tiers become active.
 * - Maplist loading optimisations.
 * - Fallback improvements.
 * - Ratio default now 50% for automatic exclude.
 * - Added options to exclude any tier after it has been used for x amount of maps, will
 *   always try and use the tier above itself.
 * - Added ability to "group" similar maps, as to exclude them as one. Handy for similar
 *   styled maps.
 * - +/- map ability has been changed, this falls in line with the new config setup.
 * - Added crash maphistory support, this will let the server continue from where it
 *   left off after an unexpected crash. Enable or disable this with 
 *   "sm_rcplus_crashrec_enable", set "sm_rcplus_crashrec_skipmap" to enable or disable 
 *   skipping the initial default map on server restart. All data for this part of the
 *   plugin is stored in the SourceMod data folder.
 * - Added population change map support. When setup will change the map if the
 *   population changes quick within a certain time limit.
 * - Fixed resume command not displaying correctly.
 * - When forcing a manual reload RC+ will always repick a map for all tiers.
 * - Changed the reload and resume commands from admin commands to server commands.
 * - Hooks removed for all cvars, just complicated things. If you change a cvar either
 *   wait until RC+ checks again or run the reload command.
 * - Changed phrase for showing the nextmap if you have announce enabled. No longer
 *   says "RandomCycle+".
 * - Improved randomisation with SM 1.3+ specific code (thanks goes to psychonic).
 * - Removed some redundant code.
 * - Lots of other fixes due to total recode, the odd leak etc.
 * - Added translation support to commands and convars.
 * - Plus much much more I forgot to note.
 *
 * 2.0.1
 * - Disabled debug code for release.
 * - Config now falls back properly if the config set it not valid.
 * - Fixed crash recovery from resuming from an idle map if idle tier was disabled.
 * - Fixed invalid handles with some timers.
 *
 * 2.0.2
 * - Fixed the config fallback for real now.
 * - Added recognition and blocking of SM/meta commands for config execs.
 * - Added cvar "sm_rcplus_crashrec_skipmap_force", this acts similar to the force cvar
 *   for the population change portion of RC+. This toggles if a crashed map is unknown 
 *   should it be treated as a high/single map.
 *
 * 2.0.3
 * - Fixed invalid timer issue on player connect/disconnect, also cause of a possible
 *   rare crashes on mapstart.
 * - Fixed idle tier sometimes not activating on players vacating the server.
 * =====================================================================================
 */
 
#pragma semicolon 1
#include <sourcemod>
#define VERSION "2.0.4"
#define DEBUG 0

const M_NONE = -1;
const M_LOW = 0;
const M_MED = 1;
const M_HIGH = 2;
const M_SINGLE = 3;
const M_IDLE = 4;
const M_OLD = 5;
const M_TOTAL = 5;
const M_TOTAL_PLUS_OLD = 6;
const M_TIERS = M_HIGH+1;
const TYPE_SINGLE = 0;
const TYPE_IDLE = 1;
const TYPE_TIME = 2;
const TYPE_TOTAL = 3;
const MAPGROUP_INVALID = 0;
const MAPGROUP_VALID = 1;
const MAPGROUP_EMPTY = 2;
const KV_LOAD_CONFIGS = 0;
const KV_MODIFY_CYCLE = 1;

new Handle:cvar_Announce;
new Handle:cvar_Log;
new Handle:cvar_NextMapHide;
new Handle:cvar_MapHistorySize;
new Handle:cvar_UseTierType[TYPE_TOTAL];
new Handle:cvar_IdleTime;
new Handle:cvar_IdleTimeRotate;
new Handle:cvar_FilePath;
new Handle:cvar_PlayerLow;
new Handle:cvar_PlayerHigh;
new Handle:cvar_ExcludeRatio;
new Handle:cvar_Exclude[M_TOTAL];
new Handle:cvar_DisableTier[M_TIERS];
new Handle:cvar_UseCycle;
new Handle:cvar_CrashEnable;
new Handle:cvar_CrashSkipMap;
new Handle:cvar_CrashSkipMapForce;
new Handle:cvar_PopulationChangeTime;
new Handle:cvar_PopulationChangeTier;
new Handle:cvar_PopulationChangeForce;

new Handle:h_IdleServer;
new Handle:h_TimeTierCheck;
new Handle:h_PopChangeMap;

new Handle:g_NextMap;

new Handle:arr_MapHistory;
new Handle:arr_Maplist[M_TOTAL];
new Handle:arr_PickedMap[M_TOTAL_PLUS_OLD];
new Handle:arr_TimeTiers;
new Handle:arr_MapGroups;
new Handle:arr_Maps;
new Handle:arr_Configs[M_TOTAL];

new bool:b_PickMap[M_TOTAL_PLUS_OLD];
new bool:b_Loaded;
new bool:b_NextMapChanged;

new g_Players;
new g_CycleRun;
new g_Exclude[M_TOTAL];
new g_DisableTier[M_TOTAL];
new p_High;
new p_Low;
new g_UseTierType[TYPE_TOTAL];
new Float:g_ExcludeRatio;

#if DEBUG
new String:LogFilePath[PLATFORM_MAX_PATH];
#endif

public Plugin:myinfo =
{
	name = "RandomCycle+",
	author = "Jamster",
	description = "Random maplists/cycles with options for player population tiers and time based tiers. Includes idle/crashed server support.",
	version = VERSION,
	url = "http://www.sourcemod.net/"
};

public OnPluginStart()
{
	for (new i; i < M_TOTAL; i++)
	{
		arr_Maplist[i] = CreateArray(17);
		arr_PickedMap[i] = CreateArray(17);
		arr_Configs[i] = CreateArray(ByteCountToCells(130));
	}
	arr_PickedMap[M_OLD] = CreateArray(17);
	arr_MapHistory = CreateArray(17);
	arr_MapGroups = CreateArray(17);
	arr_Maps = CreateArray(17);
	arr_TimeTiers = CreateArray(17);
	
	LoadTranslations("randomcycleplus.phrases");
	
	decl String:desc[255];
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_version");
	CreateConVar("sm_rcplus_version", VERSION, desc, FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_exclude_low");
	cvar_Exclude[M_LOW] = CreateConVar("sm_rcplus_exclude_low", "-1", desc, FCVAR_PLUGIN, true, -1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_exclude_med");
	cvar_Exclude[M_MED] = CreateConVar("sm_rcplus_exclude_med", "-1", desc, FCVAR_PLUGIN, true, -1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_exclude_high");
	cvar_Exclude[M_HIGH] = CreateConVar("sm_rcplus_exclude_high", "-1", desc, FCVAR_PLUGIN, true, -1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_exclude_single");
	cvar_Exclude[M_SINGLE] = CreateConVar("sm_rcplus_exclude_single", "-1", desc, FCVAR_PLUGIN, true, -1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_exclude_idle");
	cvar_Exclude[M_IDLE] = CreateConVar("sm_rcplus_exclude_idle", "-1", desc, FCVAR_PLUGIN, true, -1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_disable_low");
	cvar_DisableTier[M_LOW] = CreateConVar("sm_rcplus_disable_low", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_disable_med");
	cvar_DisableTier[M_MED] = CreateConVar("sm_rcplus_disable_med", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_disable_high");
	cvar_DisableTier[M_HIGH] = CreateConVar("sm_rcplus_disable_high", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_exclude_ratio");
	cvar_ExcludeRatio = CreateConVar("sm_rcplus_exclude_ratio", "0.5", desc, FCVAR_PLUGIN, true, 0.0, true, 0.99);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_players_low");
	cvar_PlayerLow = CreateConVar("sm_rcplus_players_low", "-1", desc, FCVAR_PLUGIN, true, -1.0, true, float(MAXPLAYERS));
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_players_high");
	cvar_PlayerHigh = CreateConVar("sm_rcplus_players_high", "-1", desc, FCVAR_PLUGIN, true, -1.0, true, float(MAXPLAYERS));
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_idletime");
	cvar_IdleTime = CreateConVar("sm_rcplus_idletime", "320.0", desc, FCVAR_PLUGIN, true, 10.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_idletimerotate");
	cvar_IdleTimeRotate = CreateConVar("sm_rcplus_idletimerotate", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_announce");
	cvar_Announce = CreateConVar("sm_rcplus_announce", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_log");
	cvar_Log = CreateConVar("sm_rcplus_log", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_hidenextmap");
	cvar_NextMapHide = CreateConVar("sm_rcplus_hidenextmap", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_singletier");
	cvar_UseTierType[TYPE_SINGLE] = CreateConVar("sm_rcplus_singletier", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_maphistorysize");
	cvar_MapHistorySize = CreateConVar("sm_rcplus_maphistorysize", "40", desc, FCVAR_PLUGIN, true, 30.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_timetier");
	cvar_UseTierType[TYPE_TIME] = CreateConVar("sm_rcplus_timetier", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_idletier");
	cvar_UseTierType[TYPE_IDLE] = CreateConVar("sm_rcplus_idletier", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_configfile");
	cvar_FilePath = CreateConVar("sm_rcplus_configfile", "default", desc, FCVAR_PLUGIN);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_reload");
	RegServerCmd("sm_rcplus_reload", Command_Reload, desc);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_resume");
	RegServerCmd("sm_rcplus_resume", Command_Resume, desc);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_usecycle");
	cvar_UseCycle = CreateConVar("sm_rcplus_usecycle", "default", desc, FCVAR_PLUGIN);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_crashrec_enable");
	cvar_CrashEnable = CreateConVar("sm_rcplus_crashrec_enable", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_crashrec_skipmap");
	cvar_CrashSkipMap = CreateConVar("sm_rcplus_crashrec_skipmap", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_crashrec_skipmap_force");
	cvar_CrashSkipMapForce = CreateConVar("sm_rcplus_crashrec_skipmap_force", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_changemap_time");
	cvar_PopulationChangeTime = CreateConVar("sm_rcplus_changemap_time", "0", desc, FCVAR_PLUGIN, true, 0.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_changemap_tieronly");
	cvar_PopulationChangeTier = CreateConVar("sm_rcplus_changemap_tieronly", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	Format(desc, sizeof(desc), "%t", "sm_rcplus_changemap_force");
	cvar_PopulationChangeForce = CreateConVar("sm_rcplus_changemap_force", "0", desc, FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	g_NextMap = FindConVar("sm_nextmap");
	
	HookConVarChange(g_NextMap, ConVarChanged_NextMap);
	
	AutoExecConfig(true, "plugin.randomcycleplus");
}
	
public OnConfigsExecuted()
{	
	#if DEBUG
	LogToFileEx(LogFilePath, "Executing OnConfigsExecuted()"); 
	#endif
	
	h_IdleServer = INVALID_HANDLE;
	h_PopChangeMap = INVALID_HANDLE;
	h_TimeTierCheck = INVALID_HANDLE;
	
	decl String:currentmap[65];
	decl String:currentnextmap[65];
	GetCurrentMap(currentmap, sizeof(currentmap));
	
	if (b_NextMapChanged)
	{
		GetNextMap(currentnextmap, sizeof(currentnextmap));
		ClearArray(arr_PickedMap[M_OLD]);
		PushArrayString(arr_PickedMap[M_OLD], currentnextmap);
	}
	
	if (GetArraySize(arr_PickedMap[M_OLD]))
	{
		GetArrayString(arr_PickedMap[M_OLD], 0, currentnextmap, sizeof(currentnextmap));
		if (StrEqual(currentmap, currentnextmap, false) || !IsMapValid(currentnextmap))
		{
			ClearArray(arr_PickedMap[M_OLD]);
		}
	}
	
	if (!GetArraySize(arr_PickedMap[M_OLD]))
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "Picking a new old next map."); 
		#endif
		new Handle:DefaultCycle = CreateArray(17);
		new serial;
		
		ReadMapList(DefaultCycle, serial, "mapcyclefile", MAPLIST_FLAG_MAPSFOLDER);
		new arraySize = GetArraySize(DefaultCycle);
		new num = RCP_GetRandomInt(0, GetArraySize(DefaultCycle)-1);
		GetArrayString(DefaultCycle, num, currentnextmap, sizeof(currentnextmap));
		
		if (arraySize > 1)
		{
			while (StrEqual(currentnextmap, currentmap, false))
			{
				num = RCP_GetRandomInt(0, arraySize - 1);
				GetArrayString(DefaultCycle, num, currentnextmap, sizeof(currentnextmap));
			}
		}
		
		PushArrayString(arr_PickedMap[M_OLD], currentnextmap);
		CloseHandle(DefaultCycle);
	}
	
	#if DEBUG
	GetArrayString(arr_PickedMap[M_OLD], 0, currentnextmap, sizeof(currentnextmap));
	LogToFileEx(LogFilePath, "Old next map: %s.", currentnextmap);
	#endif
	
	b_NextMapChanged = false;
	
	new MapHistorySize = GetMapHistorySize();
	decl String:crashdb[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, crashdb, sizeof(crashdb), "data/rcplus/maphistory.ini");
	new Handle:h_crashdb = OpenFile(crashdb, "r");
	if (h_crashdb == INVALID_HANDLE)
	{
		BuildPath(Path_SM, crashdb, sizeof(crashdb), "data");
		h_crashdb = OpenDirectory(crashdb);
		if (h_crashdb == INVALID_HANDLE)
		{
			CreateDirectory(crashdb, FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC|FPERM_G_READ|FPERM_G_EXEC|FPERM_O_READ|FPERM_O_EXEC);
			#if DEBUG
			LogToFileEx(LogFilePath, "Created data folder for crash database.");
			#endif
		}
		
		BuildPath(Path_SM, crashdb, sizeof(crashdb), "data/rcplus");
		h_crashdb = OpenDirectory(crashdb);
		if (h_crashdb == INVALID_HANDLE)
		{
			CreateDirectory(crashdb, FPERM_U_READ|FPERM_U_WRITE|FPERM_U_EXEC|FPERM_G_READ|FPERM_G_EXEC|FPERM_O_READ|FPERM_O_EXEC);
			#if DEBUG
			LogToFileEx(LogFilePath, "Created rcplus folder in data folder for crash database.");
			#endif
		}
	}
	else if (GetConVarInt(cvar_CrashEnable) && !MapHistorySize)
	{
		decl String:map[65] = "\0";
		#if DEBUG
		LogToFileEx(LogFilePath, "Crash Recovery adding maps to map history:");
		#endif
		while (!IsEndOfFile(h_crashdb))
		{
			ReadFileLine(h_crashdb, map, sizeof(map));
			BreakString(map, map, sizeof(map));
			if (map[0] != '\0')
			{
				PushArrayString(arr_MapHistory, map);
				#if DEBUG
				LogToFileEx(LogFilePath, "~ %s", map);
				#endif
			}
		}
	}
	
	if (h_crashdb != INVALID_HANDLE)
	{
		CloseHandle(h_crashdb);
	}

	PushArrayString(arr_MapHistory, currentmap);
	
	if (GetArraySize(arr_MapHistory) < MapHistorySize)
	{
		#if DEBUG
		LogToFileEx(LogFilePath, "The master history list is smaller than current internal sm maphistory, using sm maphistory.");
		#endif
		HistoryArray();
	}

	if (GetArraySize(arr_MapHistory) > GetConVarInt(cvar_MapHistorySize))
	{
		RemoveFromArray(arr_MapHistory, 0);
		#if DEBUG
		LogToFileEx(LogFilePath, "Trimmed master map history (current size: %d).", GetArraySize(arr_MapHistory));
		#endif
	}
	
	for (new i; i < M_TOTAL_PLUS_OLD; i++)
	{
		b_PickMap[i] = true;
	}
	
	LoadMaplist();
	DisableTierCheck();
	ServerIdleCheck();
	CrashRecoveryCheck();
	PopulationChangeMapCheck();
	
	b_Loaded = true;
	
	RandomCycleCheck();
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
	LogToFileEx(LogFilePath, "-- Starting RC+ debug log for map: %s.", CurrentMap);
	LogToFileEx(LogFilePath, "-- Start Time: %s.", LongTime);
	LogToFileEx(LogFilePath, "Executing OnMapStart()"); 
	#endif
	
	g_CycleRun = M_NONE;
	g_Players = 0;
	
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
	#if DEBUG
	LogToFileEx(LogFilePath, "Executing OnMapEnd()"); 
	#endif
	
	b_NextMapChanged = false;
	b_Loaded = false;
	
	#if DEBUG
	LogToFileEx(LogFilePath, "Ending map.");
	#endif
}

public OnClientConnected(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	g_Players++;
	
	if (b_Loaded)
	{
		if (h_IdleServer != INVALID_HANDLE)
		{
			KillTimer(h_IdleServer);
			h_IdleServer = INVALID_HANDLE;
			#if DEBUG
			LogToFileEx(LogFilePath, "Killed idle timer due to player connect.");
			#endif
		}
		
		if (g_Players == 1)
		{
			PopulationChangeMapCheck();
		}
		
		RandomCycleCheck();
	}
}

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	g_Players--;
	
	if (b_Loaded)
	{
		if (!g_Players)
		{
			ServerIdleCheck();
			if (h_PopChangeMap != INVALID_HANDLE)
			{
				KillTimer(h_PopChangeMap);
				h_PopChangeMap = INVALID_HANDLE;
				#if DEBUG
				LogToFileEx(LogFilePath, "Killed population change map timer due to no players on the server.");
				#endif
			}
		}
		
		RandomCycleCheck();
	}
}

/**
 * Checks whether to start the timer for tier mapchange, if set.
 *
 * @noreturn					
 */
 
PopulationChangeMapCheck()
{
	if (!GetConVarFloat(cvar_PopulationChangeTime) || !g_Players)
	{
		return;
	}
	
	if (h_PopChangeMap == INVALID_HANDLE)
	{
		h_PopChangeMap = CreateTimer(GetConVarFloat(cvar_PopulationChangeTime), t_PopChangeMap, _, TIMER_FLAG_NO_MAPCHANGE);
		#if DEBUG
		LogToFileEx(LogFilePath, "Started population change map timer.");
		#endif
	}
}

/**
 * Checks if a tier need to be disabled.
 *
 * @noreturn					
 */

DisableTierCheck()
{
	new TierArrSize[M_TIERS];
	for (new i; i < M_TIERS; i++)
	{
		TierArrSize[i] = GetArraySize(arr_Maplist[i]);
	}
	
	for (new i; i < M_TIERS; i++)
	{
		if (g_DisableTier[i])
		{
			decl String:CheckMap[65];
			new DisableTier;
			for (new i2 = GetArraySize(arr_MapHistory) - 1; i2 >= 0; i2--)
			{
				GetArrayString(arr_MapHistory, i2, CheckMap, sizeof(CheckMap));
				if (!CheckForMapInTier(CheckMap, i, true))
				{
					break;
				}
				DisableTier++;
				if (DisableTier == g_DisableTier[i])
				{
					if (i == M_HIGH)
					{
						if (TierArrSize[M_MED])
						{
							p_High = MAXPLAYERS+1;
							#if DEBUG
							LogToFileEx(LogFilePath, "Disabled high tier, using medium tier in place."); 
							#endif
						}
						else if (TierArrSize[M_LOW])
						{
							p_Low = MAXPLAYERS;
							p_High = MAXPLAYERS+1;
							#if DEBUG
							LogToFileEx(LogFilePath, "Disabled high tier, using low tier in place."); 
							#endif
						}
						else
						{
							p_High = 0;
							p_Low = 0;
							#if DEBUG
							LogToFileEx(LogFilePath, "Disabled high tier, no valid tier to run, disabling."); 
							#endif
						}
					}
					else if (i == M_MED)
					{
						if (TierArrSize[M_HIGH])
						{
							p_High = p_Low+1;
							#if DEBUG
							LogToFileEx(LogFilePath, "Disabled medium tier, using high tier."); 
							#endif
						}
						else if (TierArrSize[M_LOW])
						{
							p_Low = p_High-1;
							#if DEBUG
							LogToFileEx(LogFilePath, "Disabled medium tier, using low tier."); 
							#endif
						}
						else
						{
							p_High = 0;
							p_Low = 0;
							#if DEBUG
							LogToFileEx(LogFilePath, "Disabled medium tier, no valid tier to run, disabling."); 
							#endif
						}
					}
					else if (i == M_LOW)
					{
						if (TierArrSize[M_MED])
						{
							p_Low = -1;
							#if DEBUG
							LogToFileEx(LogFilePath, "Disabled low tier, using medium tier."); 
							#endif
						}
						else if (TierArrSize[M_HIGH])
						{
							p_Low = -2;
							p_High = -1;
							g_Exclude[i] = g_Exclude[M_HIGH];
							#if DEBUG
							LogToFileEx(LogFilePath, "Disabled low tier, using high tier."); 
							#endif
						}
						else
						{
							p_High = 0;
							p_Low = 0;
							#if DEBUG
							LogToFileEx(LogFilePath, "Disabled low tier, no valid tier to run, disabling."); 
							#endif
						}
					}
					break;
				}				
			}
		}
	}
}

/**
 * Executes the resuming of a cycle on a server crash/restart and writes db.
 *
 * @noreturn					
 */

CrashRecoveryCheck()
{
	if (GetConVarInt(cvar_CrashEnable) && GetConVarInt(cvar_CrashSkipMap) && !GetMapHistorySize() && GetArraySize(arr_MapHistory) > 1)
	{
		decl String:map[65];
		new tier = -1;
		GetArrayString(arr_MapHistory, (GetArraySize(arr_MapHistory)-2), map, sizeof(map));
		for (new i; i < M_TOTAL; i++)
		{
			if (CheckForMapInTier(map, i, true))
			{
				tier = i;
				break;
			}
		}
		
		if (tier == -1 && GetConVarInt(cvar_CrashSkipMapForce))
		{
			if (g_UseTierType[TYPE_SINGLE])
			{
				tier = M_SINGLE;
			}
			else
			{
				tier = M_HIGH;
			}
		}
		
		if (tier != -1)
		{
			RandomCycleCheck(tier);
			
			decl String:desc[255];
			GetNextMap(map, sizeof(map));
			Format(desc, sizeof(desc), "%t", "RCP Endmap Crash");
			
			if (GetConVarInt(cvar_Log))
			{
				LogMessage("%t", "RCP Crash Server", map);
			}
			
			#if DEBUG
			LogToFileEx(LogFilePath, "Server crash/restart, changing map to: %s.", map); 
			#endif
			
			RemoveFromArray(arr_MapHistory, (GetArraySize(arr_MapHistory)-1));
			ForceChangeLevel(map, desc);
			return;
		}
	}
	
	decl String:crashdb[PLATFORM_MAX_PATH];
	BuildPath(Path_SM, crashdb, sizeof(crashdb), "data/rcplus");
	new Handle:h_crashdb = OpenDirectory(crashdb);
	if (h_crashdb != INVALID_HANDLE)
	{
		BuildPath(Path_SM, crashdb, sizeof(crashdb), "data/rcplus/maphistory.ini");
		h_crashdb = OpenFile(crashdb, "w");
		if (h_crashdb != INVALID_HANDLE)
		{
			DeleteFile(crashdb);
		}
		new MapHistorySize = GetArraySize(arr_MapHistory);
		decl String:map[65];
		for (new i; i < MapHistorySize; i++)
		{
			GetArrayString(arr_MapHistory, i, map, sizeof(map));
			WriteFileLine(h_crashdb, map);
		}
		WriteFileLine(h_crashdb, "\0");
		CloseHandle(h_crashdb);
	}
}

public Action:t_TimeTierCheck(Handle:timer, any:timetier)
{
	if (!b_Loaded)
	{
		return Plugin_Continue;
	}
	
	if (CheckTimeTiers() != timetier)
	{
		// I have to do this since reloading the maplists kills the current timer.
		CreateTimer(1.0, t_ReloadAll, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	return Plugin_Continue;
}

public Action:t_ReloadAll(Handle:timer)
{
	if (b_Loaded)
	{
		ReloadAll();
	}
	return Plugin_Stop;
}

public Action:t_IdleServer(Handle:timer)
{
	decl String:desc[255];
	decl String:map[65];
	GetArrayString(arr_PickedMap[M_IDLE], 0, map, sizeof(map));
	
	if (GetConVarInt(cvar_Log))
	{
		LogMessage("%t", "RCP Idle Server", map);
	}
	
	#if DEBUG
	LogToFileEx(LogFilePath, "Idle server, changing map to: %s.", map); 
	#endif
	
	Format(desc, sizeof(desc), "%t", "RCP Endmap Idle");
	ForceChangeLevel(map, desc);
	h_IdleServer = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:t_PopChangeMap(Handle:timer)
{
	if (!g_Players)
	{
		h_PopChangeMap = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	decl String:currentmap[65];
	GetCurrentMap(currentmap, sizeof(currentmap));
	new tier = -1;
	
	b_Loaded = false;
	
	LoadMaplist();
	
	for (new i; i < M_TOTAL; i++)
	{
		if (!CheckForMapInTier(currentmap, i, true))
		{
			continue;
		}
		
		tier = i;
	}
	
	if (tier == -1 && GetConVarInt(cvar_PopulationChangeForce))
	{
		if (g_UseTierType[TYPE_SINGLE])
		{
			tier = M_SINGLE;
		}
		else
		{
			tier = M_HIGH;
		}
	}
	
	if (g_CycleRun == tier)
	{
		b_Loaded = true;
		RandomCycleCheck();
		h_PopChangeMap = INVALID_HANDLE;
		return Plugin_Stop;
	}
	
	if (GetConVarInt(cvar_PopulationChangeTier))
	{
		b_NextMapChanged = false;
		RandomCycleCheck(-2);
	}
	
	decl String:nextmap[65];
	GetNextMap(nextmap, sizeof(nextmap));
	
	if (GetConVarInt(cvar_Log))
	{
		LogMessage("%t", "RCP Pop Map Log", nextmap);
	}
	
	if (GetConVarInt(cvar_Announce))
	{
		PrintToChatAll("%t", "RCP Pop Changing Map", nextmap);
		CreateTimer(5.0, t_PopChangeMapDelay, _,  TIMER_FLAG_NO_MAPCHANGE);
	}
	else
	{
		PopulationChangeMap();
	}
	
	h_PopChangeMap = INVALID_HANDLE;
	return Plugin_Stop;
}

public Action:t_PopChangeMapDelay(Handle:timer)
{
	PopulationChangeMap();
	return Plugin_Stop;
}

/**
 * Executed when the map needs to end due to a sudden population change.
 *
 * @noreturn					
 */
 
PopulationChangeMap()
{
	decl String:desc[255];
	decl String:nextmap[65];
	Format(desc, sizeof(desc), "%t", "RCP Endmap Pop");
	GetNextMap(nextmap, sizeof(nextmap));
	ForceChangeLevel(nextmap, desc);
}

public ConVarChanged_NextMap(Handle:convar, const String:oldValue[], const String:newValue[])
{
	// If anything happens to change the nextmap externally this will stop the plugin
	// from picking any further changes.
	#if DEBUG
	if (!StrEqual(oldValue, newValue, false))
	{
		LogToFileEx(LogFilePath, "sm_nextmap changed from \"%s\" to \"%s\"", oldValue, newValue);
	}
	#endif
	b_NextMapChanged = true;
}

public Action:Command_Reload(client)
{	
	// Reloads RC+'s maplists and picks a different map, if applicable.
	#if DEBUG
	LogToFileEx(LogFilePath, "Reload admin command has been executed.");
	#endif
	ReloadAll();
	ReplyToCommand(client, "%t", "RCP Reloaded");
	return Plugin_Handled;
}

/**
 * Resets settings and reloads everything.
 *
 * @noreturn
 */

ReloadAll()
{
	b_Loaded = false;
	LoadMaplist();
	DisableTierCheck();
	for (new i; i < M_TOTAL_PLUS_OLD; i++)
	{
		b_PickMap[i] = true;
	}
	g_CycleRun = M_NONE;
	b_Loaded = true;
	RandomCycleCheck();
}

public Action:Command_Resume(client)
{	
	// Resumes RC+ if another plugin changed the nextmap.
	#if DEBUG
	LogToFileEx(LogFilePath, "Resume admin command has been executed.");
	#endif
	b_NextMapChanged = false;
	g_CycleRun = M_NONE;
	RandomCycleCheck();
	ReplyToCommand(client, "%t", "RCP Resumed");
	return Plugin_Handled;
}

/**
 * Checks to see if the map is in the provided tier.
 *
 * @param srcmap			Map to check.
 * @param tier				What tier to check.
 * @param check_only		Whether to check only (i.e. don't remove from array).
 * @return					True if found, false otherwise.
 */
 
bool:CheckForMapInTier(const String:srcmap[], const tier, const bool:check_only = false)
{
	// Zero fallbacks due to if there's a problem here I've done something
	// really really wrong.
	
	new ArraySize = GetArraySize(arr_Maplist[tier]);
	new ArraySizeMG = GetArraySize(arr_MapGroups);
	decl String:map[65];
	new ArrayIndex;
	
	for (new i; i < ArraySize; i++)
	{
		GetArrayString(arr_Maplist[tier], i, map, sizeof(map));
		if (!RCP_IsMapValid(map))
		{
			ArrayIndex = FindStringInArray(arr_MapGroups, map);
			for (new i2 = ArrayIndex+1; i2 < ArraySizeMG; i2++)
			{
				GetArrayString(arr_MapGroups, i2, map, sizeof(map));
				if (map[0] == '!')
				{
					Format(map, sizeof(map), "%s", map[1]);
				}
				if (!RCP_IsMapValid(map))
				{
					break;
				}
				if (StrEqual(map, srcmap, false))
				{
					if (!check_only)
					{
						RemoveFromArray(arr_Maplist[tier], i);
					}
					return true;
				}
			}
		}
		else if (StrEqual(map, srcmap, false))
		{
			if (!check_only)
			{
				RemoveFromArray(arr_Maplist[tier], i);
			}
			return true;
		}
	}
	
	return false;
}


/**
 * Loads all maplists.
 *
 * @noreturn
 */

LoadMaplist()
{
	#if DEBUG
	LogToFileEx(LogFilePath, "Loading maplists."); 
	#endif
	
	CacheValidMaps();
	
	if (h_TimeTierCheck != INVALID_HANDLE)
	{
		KillTimer(h_TimeTierCheck);
		h_TimeTierCheck = INVALID_HANDLE;
		#if DEBUG
		LogToFileEx(LogFilePath, "Killed time tier timer due to loading maplists.");
		#endif
	}
	
	for (new i; i < TYPE_TOTAL; i++)
	{
		g_UseTierType[i] = GetConVarInt(cvar_UseTierType[i]);
	}

	for (new i; i < M_TOTAL; i++)
	{
		ClearArray(arr_Maplist[i]);
		ClearArray(arr_Configs[i]);
		g_Exclude[i] = GetConVarInt(cvar_Exclude[i]);
		if (i < M_TIERS)
		{
			g_DisableTier[i] = GetConVarInt(cvar_DisableTier[i]);
		}
		LoadMaplistsDotCFG(i);
	}
	
	ClearArray(arr_TimeTiers);
	ClearArray(arr_MapGroups);
	
	decl String:ConfigPath[PLATFORM_MAX_PATH];
	decl String:ConVarPath[PLATFORM_MAX_PATH];
	GetConVarString(cvar_FilePath, ConVarPath, sizeof(ConVarPath));
	
	if (!StrEqual(ConVarPath, "default", false) && FileExists(ConVarPath))
	{	
		ConfigPath = ConVarPath;
	}
	else
	{
		BuildPath(Path_SM, ConfigPath, sizeof(ConfigPath), "configs/randomcycleplus.cfg");
	}
	
	new bool:b_MaplistsCFG;
	
	for (new i; i < M_TOTAL; i++)
	{
		if (GetArraySize(arr_Maplist[i]))
		{
			b_MaplistsCFG = true;
			break;
		}
	}
	
	new bool:ConfigValid = FileExists(ConfigPath);
	
	if (!ConfigValid && !b_MaplistsCFG)
	{
		LogError("%t", "RCP No Config");
		p_Low = 0;
		p_High = 0;
		return;
	}
	
	p_High = GetConVarInt(cvar_PlayerHigh);
	p_Low = GetConVarInt(cvar_PlayerLow);
	g_ExcludeRatio = GetConVarFloat(cvar_ExcludeRatio);
	decl String:usecycle[255];
	GetConVarString(cvar_UseCycle, usecycle, sizeof(usecycle));
	
	// Config Parsing
	
	if (ConfigValid)
	{
		if (b_MaplistsCFG)
		{
			for (new i; i < M_TOTAL; i++)
			{
				ClearArray(arr_Maplist[i]);
			}
		}
		
		if (!ParseRCPKV(ConfigPath, true, usecycle, false))
		{
			LogError("%t", "RCP KV Parse Error", usecycle);
		}
	}
	
	// Fallbacks for automatic cvar values
	
	switch (p_High)
	{
		case -1:
			p_High = RoundToNearest(0.66 * MaxClients);
	}
	
	switch (p_Low)
	{
		case -1:
			p_Low = RoundToNearest(0.33 * MaxClients);
	}
	
	if (p_Low == p_High)
	{
		LogError("%t", "RCP Same Player");
		p_High = p_Low+1;
	}
	
	if (p_Low > p_High && p_High)
	{
		LogError("%t", "RCP Reversed Player");
		p_Low = p_High;
		p_High = p_Low+1;
	}
	
	new arr_Size;
	for (new i; i < M_TOTAL; i++)
	{
		arr_Size = GetArraySize(arr_Maplist[i]);
		switch (g_Exclude[i])
		{
			case -1:
				g_Exclude[i] = RoundToNearest(g_ExcludeRatio * arr_Size);
			default:
				continue;
		}
		if (g_Exclude[i] >= arr_Size)
		{
			g_Exclude[i] = arr_Size-1;
		}
	}
	
	#if DEBUG
	LogToFileEx(LogFilePath, "Low exclude count: %d", g_Exclude[M_LOW]); 
	LogToFileEx(LogFilePath, "Med exclude count: %d", g_Exclude[M_MED]); 
	LogToFileEx(LogFilePath, "High exclude count: %d", g_Exclude[M_HIGH]); 
	LogToFileEx(LogFilePath, "Single exclude count: %d", g_Exclude[M_SINGLE]); 
	LogToFileEx(LogFilePath, "Idle exclude count: %d", g_Exclude[M_IDLE]); 
	LogToFileEx(LogFilePath, "Ratio exclude value: %f", g_ExcludeRatio); 
	LogToFileEx(LogFilePath, "High player count: %d", p_High); 
	LogToFileEx(LogFilePath, "Low player count: %d", p_Low); 
	#endif
	
	// General map fallbacks and fallbacks for invalid values
	
	new TierArrSize[M_TOTAL];
	for (new i; i < M_TOTAL; i++)
	{
		TierArrSize[i] = GetArraySize(arr_Maplist[i]);
		if (TierArrSize[i] && TierArrSize[i] <= g_Exclude[i])
		{
			decl String:Tier[128];
			g_Exclude[i] = TierArrSize[i]-1;
			switch (i)
			{
				case M_LOW:
					Format(Tier, sizeof(Tier), "%t", "RCP Low");
				case M_MED:
					Format(Tier, sizeof(Tier), "%t", "RCP Med");
				case M_HIGH:
					Format(Tier, sizeof(Tier), "%t", "RCP High");
				case M_IDLE:
					Format(Tier, sizeof(Tier), "%t", "RCP Idle");
				case M_SINGLE:
					Format(Tier, sizeof(Tier), "%t", "RCP Single");
			}
			LogError("[%s] %t", Tier, "RCP Exclude Error", g_Exclude[i]);
		}
	}
	
	if (g_UseTierType[TYPE_SINGLE] && !TierArrSize[M_SINGLE])
	{
		g_UseTierType[TYPE_SINGLE] = 0;
		ClearArray(arr_Maplist[M_SINGLE]);
		TierArrSize[M_SINGLE] = 0;
		LogError("%t", "RCP Single Tier Disabled");
	}
	
	if (!g_UseTierType[TYPE_SINGLE] && TierArrSize[M_SINGLE])
	{
		ClearArray(arr_Maplist[M_SINGLE]);
	}
	
	if (g_UseTierType[TYPE_IDLE] && !TierArrSize[M_IDLE])
	{
		g_UseTierType[TYPE_IDLE] = 0;
		ClearArray(arr_Maplist[M_IDLE]);
		TierArrSize[M_IDLE] = 0;
		if (h_IdleServer != INVALID_HANDLE)
		{
			KillTimer(h_IdleServer);
			h_IdleServer = INVALID_HANDLE;
			#if DEBUG
			LogToFileEx(LogFilePath, "Killed idle timer due to empty maplist.");
			#endif
		}
		LogError("%t", "RCP Idle Tier Disabled");
	}
	
	if (!g_UseTierType[TYPE_IDLE] && TierArrSize[M_IDLE])
	{
		ClearArray(arr_Maplist[M_IDLE]);
	}
	
	// Checks the player values are valid for the arrays that are actually loaded.
	if (!g_UseTierType[TYPE_SINGLE])
	{
		if (p_High && p_High-1 == p_Low)
		{
			if (!TierArrSize[M_LOW] && !TierArrSize[M_HIGH])
			{
				p_High = 0;
				p_Low = 0;
				LogError("%t", "RCP Fallback H+L");
			}
			else if (!TierArrSize[M_LOW])
			{
				p_Low = -2;
				p_High = -1;
				LogError("%t", "RCP Fallback L");
			}
			else if (!TierArrSize[M_HIGH])
			{
				p_High = MAXPLAYERS+1;
				p_Low = MAXPLAYERS;
				LogError("%t", "RCP Fallback H");
			}
		}
		else if (p_High && p_Low)
		{
			if (!TierArrSize[M_MED])
			{
				p_High = p_Low+1;
				LogError("%t", "RCP Fallback NoM", p_High);
				if (!TierArrSize[M_LOW] && !TierArrSize[M_HIGH])
				{
					p_High = 0;
					p_Low = 0;
					LogError("%t", "RCP Fallback NoM H+L");
				}
				else if (!TierArrSize[M_LOW])
				{
					p_Low = 0;
					LogError("%t", "RCP Fallback L");
				}
				else if (!TierArrSize[M_HIGH])
				{
					p_High = 0;
					LogError("%t", "RCP Fallback H");
				}
			}
			else if (!TierArrSize[M_LOW] && !TierArrSize[M_HIGH])
			{
				p_High = MAXPLAYERS+1;
				p_Low = -1;
				LogError("%t", "RCP Fallback M H+L");
			}
			else if (!TierArrSize[M_LOW])
			{
				p_Low = -1;
				LogError("%t", "RCP Fallback L");
			}
			else if (!TierArrSize[M_HIGH])
			{
				p_High = MAXPLAYERS+1;
				LogError("%t", "RCP Fallback H");
			}
		}
	}
	
	return;
}

/**
 * Parses the RC+ config fully.
 *
 * @param kvfile		Filepath string to config.
 * @param full_load		Do a full parse or not. A partial pass only reads cycle info.
 * @param rcycle		Random cycle to load.
 * @param is_timetier	Toggles whether this is a time tier or not.
 * @return				True if parsed correctly, false if unable to find the rcycle.
 */

ParseRCPKV(const String:kvfile[], const bool:full_load, const String:rcycle[], const bool:is_timetier)
{
	new Handle:kv = CreateKeyValues("rcplus");
	FileToKeyValues(kv, kvfile);
	
	if (!KvJumpToKey(kv, rcycle))
	{
		CloseHandle(kv);
		return false;
	}
	
	if (full_load && !is_timetier && g_UseTierType[TYPE_TIME])
	{
		if (KvJumpToKey(kv, "timetiers"))
		{
			if (KvGotoFirstSubKey(kv))
			{
				LoadKVTimeTiers(kv);
				while (KvGotoNextKey(kv))
				{
					LoadKVTimeTiers(kv);
				}
				KvGoBack(kv);
			}
			KvGoBack(kv);
			
			if (GetArraySize(arr_TimeTiers))
			{
				new i = CheckTimeTiers();
				if (i != -1)
				{
					decl String:timetier[65];
					GetArrayString(arr_TimeTiers, i, timetier, sizeof(timetier));
					if (ParseRCPKV(kvfile, true, timetier, true))
					{
						h_TimeTierCheck = CreateTimer(60.0, t_TimeTierCheck, i, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
						#if DEBUG
						LogToFileEx(LogFilePath, "Created timer to check for time tier end.");
						#endif
						CloseHandle(kv);
						return true;
					}
					else
					{
						LogError("%t", "RCP KV Parse Error", timetier);
					}
				}
				else
				{
					h_TimeTierCheck = CreateTimer(60.0, t_TimeTierCheck, -1, TIMER_FLAG_NO_MAPCHANGE|TIMER_REPEAT);
					#if DEBUG
					LogToFileEx(LogFilePath, "Created timer to check for time tier initiation.");
					#endif
				}
			}
		}
	}
	
	decl String:cy_file[255];
	decl String:cy_copy[255];
	
	KvGetString(kv, "cycle file", cy_file, sizeof(cy_file), "NULL_KEY_VALUE");
	KvGetString(kv, "cycle copy", cy_copy, sizeof(cy_copy), "NULL_KEY_VALUE");
	
	if (full_load && !StrEqual(cy_copy, "NULL_KEY_VALUE"))
	{
		if (!ParseRCPKV(kvfile, false, cy_copy, false))
		{
			LogError("%t", "RCP KV Parse Error", cy_copy);
		}
	}
	else if (!StrEqual(cy_file, "NULL_KEY_VALUE"))
	{
		if (!StrContains(cy_file, "\%smpath\%", false))
		{
			BuildPath(Path_SM, cy_file, sizeof(cy_file), cy_file[9]);
		}
		
		if (FileExists(cy_file))
		{
			for (new i; i < M_TOTAL; i++)
			{
				LoadTierInCycleFile(i, cy_file);
			}
		}
		else
		{
			LogError("%t", "RCP No Cycle File", cy_file);
		}
	}
	else
	{
		if (KvJumpToKey(kv, "cycle maplists"))
		{
			decl String:maplist[7];
			decl String:filepath[255];
			for (new i; i < M_TOTAL; i++)
			{
				switch (i)
				{
					case M_LOW:
						Format(maplist, sizeof(maplist), "low");
					case M_MED:
						Format(maplist, sizeof(maplist), "med");
					case M_HIGH:
						Format(maplist, sizeof(maplist), "high");
					case M_SINGLE:
						Format(maplist, sizeof(maplist), "single");
					case M_IDLE:
						Format(maplist, sizeof(maplist), "idle");
				}
				KvGetString(kv, maplist, filepath, sizeof(filepath), "NULL_KEY_VALUE");
				if (StrEqual(filepath, "NULL_KEY_VALUE"))
				{
					continue;
				}
				if (!StrContains(filepath, "\%smpath\%", false))
				{
					BuildPath(Path_SM, filepath, sizeof(filepath), filepath[9]);
				}
				if (FileExists(filepath))
				{
					LoadMaplistFile(filepath, i);
				}
				else
				{
					LogError("%t", "RCP No Maplist File", filepath);
				}
			}
			KvGoBack(kv);
		}
	}
	
	if (KvJumpToKey(kv, "cycle modify"))
	{
		if (KvGotoFirstSubKey(kv))
		{
			LoadKeysOneByOne(kv, KV_MODIFY_CYCLE);
			while (KvGotoNextKey(kv))
			{
				LoadKeysOneByOne(kv, KV_MODIFY_CYCLE);
			}
			KvGoBack(kv);
		}
		KvGoBack(kv);
	}
	
	if (!full_load)
	{
		CloseHandle(kv);
		return true;
	}
	
	if (KvJumpToKey(kv, "options"))
	{
		g_Exclude[M_LOW] = GetKvOption("exclude low", g_Exclude[M_LOW], kv);
		g_Exclude[M_MED] = GetKvOption("exclude med", g_Exclude[M_MED], kv);
		g_Exclude[M_HIGH] = GetKvOption("exclude high", g_Exclude[M_HIGH], kv);
		g_Exclude[M_IDLE] = GetKvOption("exclude idle", g_Exclude[M_IDLE], kv);
		g_Exclude[M_SINGLE] = GetKvOption("exclude single", g_Exclude[M_SINGLE], kv);
		g_ExcludeRatio = GetKvOption("exclude ratio", g_ExcludeRatio, kv, false);
		p_Low = GetKvOption("players low", p_Low, kv);
		p_High = GetKvOption("players high", p_High, kv);
		KvGoBack(kv);
	}
	
	if (KvJumpToKey(kv, "configs"))
	{
		if (KvGotoFirstSubKey(kv))
		{
			LoadKeysOneByOne(kv, KV_LOAD_CONFIGS);
			while (KvGotoNextKey(kv))
			{
				LoadKeysOneByOne(kv, KV_LOAD_CONFIGS);
			}
			KvGoBack(kv);
		}
		KvGoBack(kv);
	}
	
	CloseHandle(kv);
	return true;
}

/**
 * Loads cvars from config file.
 *
 * @param kv			Handle to config.
 * @param tier			Index of the tier.
 * @noreturn
 */

LoadKvConfigs(Handle:kv, const tier)
{
	decl String:cvar[65];
	decl String:value[65];
	decl String:cvar_string[130];
	KvGetSectionName(kv, cvar, sizeof(cvar));
	KvGoBack(kv);
	KvGetString(kv, cvar, value, sizeof(value));
	KvJumpToKey(kv, cvar);
	if (StrEqual(value, "NO_ARGS"))
	{
		cvar_string = "\0";
		RCP_PushConfig(cvar, tier);
	}
	else
	{
		if (StrEqual(value, "EMPTY_VALUE"))
		{
			Format(value, sizeof(value), "\"\"");
		}
		Format(cvar_string, sizeof(cvar_string), "%s %s", cvar, value);
		RCP_PushConfig(cvar_string, tier);
	}
}

/**
 * Checks a cvar to see if it's OK to add.
 *
 * @param check		String to check.
 * @param tier		Index of tier.
 * @noreturn
 */

RCP_PushConfig(const String:check[], const tier)
{
	decl String:breakstr[130];
	BreakString(check, breakstr, sizeof(breakstr));
	if (StrEqual(breakstr, "rcon_password", false))
	{
		LogError("%t", "RCP rcon pass warning", check);
		return;
	}
	
	if (StrEqual(breakstr, "exec", false) || StrEqual(breakstr, "sm_execcfg", false))
	{
		LogError("%t", "RCP exec warning", check);
		return;
	}
	
	if (StrEqual(breakstr, "sm", false) || StrEqual(breakstr, "meta", false))
	{
		LogError("%t", "RCP sm cmd warning", check);
		return;
	}
	
	if (StrContains(check, ";") != -1)
	{
		LogError("%t", "RCP semicolon warning", check);
		return;
	}

	PushArrayString(arr_Configs[tier], check);
}

/**
 * Gets and sets the option overrides for RC+.
 *
 * @param find_value	Value to find.
 * @param set_value		Value to change if find value is valid.
 * @param kv			Current handle to config.
 * @param is_int		Controls whether to return a int or float.
 * @noreturn
 */

any:GetKvOption(const String:find_value[], any:set_value, Handle:kv, const bool:is_int = true)
{
	// Slightly bigger for future use.
	decl String:value[16];
	KvGetString(kv, find_value, value, sizeof(value), "NULL_KEY_VALUE");
	if (StrEqual(value, "NULL_KEY_VALUE"))
	{
		return set_value;
	}

	switch (is_int)
	{
		case true:
			set_value = KvGetNum(kv, find_value);
		case false:
			set_value = KvGetFloat(kv, find_value);
	}
	
	return set_value;
}

/**
 * Loads unknown keys one by one.
 *
 * @param kv			Current handle to config.
 * @param type			What we are loading.
 * @noreturn
 */

LoadKeysOneByOne(Handle:kv, const type)
{
	new i;
	decl String:tier[7];
	KvGetSectionName(kv, tier, sizeof(tier));
	if (StrEqual(tier, "low", false))
	{
		i = M_LOW;
	}
	else if (StrEqual(tier, "med", false))
	{
		i = M_MED;
	}
	else if (StrEqual(tier, "high", false))
	{
		i = M_HIGH;
	}
	else if (StrEqual(tier, "single", false))
	{
		i = M_SINGLE;
	}
	else if (StrEqual(tier, "idle", false))
	{
		i = M_IDLE;
	}
	if (KvGotoFirstSubKey(kv, false))
	{
		switch (type)
		{
			case KV_MODIFY_CYCLE:
				ModifyCycle_Check(kv, i);
			case KV_LOAD_CONFIGS:
				LoadKvConfigs(Handle:kv, i);
		}
		while (KvDeleteThis(kv) != -1)
		{
			switch (type)
			{
				case KV_MODIFY_CYCLE:
					ModifyCycle_Check(kv, i);
				case KV_LOAD_CONFIGS:
					LoadKvConfigs(Handle:kv, i);
			}
		}
	}
}

/**
 * Modifies the current cycle map by map. Add and remove section.
 *
 * @param kv			Current handle to config.
 * @param tier			Index to tier.
 * @noreturn
 */

ModifyCycle_Check(Handle:kv, const tier)
{
	new add;
	decl String:map[65];
	decl String:action[7];
	KvGetSectionName(kv, map, sizeof(map));
	KvGoBack(kv);
	KvGetString(kv, map, action, sizeof(action));
	KvJumpToKey(kv, map);
	if (StrEqual(action, "add", false))
	{
		add = true;
	}
	else if (!StrEqual(action, "remove", false))
	{
		LogError("%t", "RCP Cycle Modify Action", action, map);
		return;
	}
	
	decl String:tiererror[16];
	switch (tier)
	{
		case M_SINGLE:
			Format(tiererror, sizeof(tiererror), "RCP Single");
		case M_IDLE:
			Format(tiererror, sizeof(tiererror), "RCP Idle");
		case M_HIGH:
			Format(tiererror, sizeof(tiererror), "RCP High");
		case M_MED:
			Format(tiererror, sizeof(tiererror), "RCP Med");
		case M_LOW:
			Format(tiererror, sizeof(tiererror), "RCP Low");
	}
	
	if (add)
	{
		if (!CheckForMapInTier(map, tier, true))
		{
			PushArrayString(arr_Maplist[tier], map);
			#if DEBUG
			LogToFileEx(LogFilePath, "[%t] Added map \"%s\"", tiererror, map);
			#endif
		}
		else
		{
			LogError("[%t] %t", tiererror, "RCP Cycle Modify Add", map);
		}
	}
	else
	{
		if (!RCP_IsMapValid(map))
		{
			new index = FindStringInArray(arr_Maplist[tier], map);
			if (index != -1)
			{
				RemoveFromArray(arr_Maplist[tier], index);
				#if DEBUG
				LogToFileEx(LogFilePath, "[%t] Removed mapgroup \"%s\".", tiererror, map);
				#endif
			}
			else
			{
				LogError("[%t] %t", tiererror, "RCP Cycle Modify Mapgroup Remove", map);
			}
		}
		else if (!CheckForMapInTier(map, tier))
		{
			LogError("[%t] %t", tiererror, "RCP Cycle Modify Remove", map);
		}
		#if DEBUG
		else
		{
			LogToFileEx(LogFilePath, "[%t] Removed map \"%s\"", tiererror, map);
		}
		#endif
	}
}

/**
 * Loads a tier from a single maplist file.
 *
 * @param maplist		Path to maplist.
 * @param tier			Index of tier to fill.
 * @noreturn
 */

LoadMaplistFile(const String:maplist[], const tier)
{
	new Handle:h_maplist = OpenFile(maplist, "r");
	decl String:map[65];
	decl String:tiererror[16];
	switch (tier)
	{
		case M_SINGLE:
			Format(tiererror, sizeof(tiererror), "RCP Single");
		case M_IDLE:
			Format(tiererror, sizeof(tiererror), "RCP Idle");
		case M_HIGH:
			Format(tiererror, sizeof(tiererror), "RCP High");
		case M_MED:
			Format(tiererror, sizeof(tiererror), "RCP Med");
		case M_LOW:
			Format(tiererror, sizeof(tiererror), "RCP Low");
	}
	while (!IsEndOfFile(h_maplist))
	{
		ReadFileLine(h_maplist, map, sizeof(map));
		TrimString(map);
		if (map[0] != '/' && map[1] != '/' && map[0] != '\0' && map[0] != '*')
		{
			BreakString(map, map, sizeof(map));
			if (!RCP_IsMapValid(map))
			{
				LogError("[%t], %t", tiererror, "RCP Map Error", map);
				continue;
			}
			if (FindStringInArray(arr_Maplist[tier], map) != -1)
			{
				LogError("[%t] %t", tiererror, "RCP Dupe Map", map);
				continue;
			}
			PushArrayString(arr_Maplist[tier], map);
			#if DEBUG
			if (GetArraySize(arr_Maplist[tier]) == 1)
			{
				switch (tier)
				{
					case M_SINGLE:
						LogToFileEx(LogFilePath, "Single maps:");
					case M_IDLE:
						LogToFileEx(LogFilePath, "Idle maps:");
					case M_HIGH:
						LogToFileEx(LogFilePath, "High maps:");
					case M_MED:
						LogToFileEx(LogFilePath, "Med maps:");
					case M_LOW:
						LogToFileEx(LogFilePath, "Low maps:");
				}
			}
			LogToFileEx(LogFilePath, "~ %s", map);
			#endif
		}
	}
	CloseHandle(h_maplist);
}

/**
 * Parses the time tier settings in the current cycle.
 *
 * @param kv			Current handle to the config.
 * @noreturn
 */

LoadKVTimeTiers(Handle:kv)
{
	decl String:value[65];
	KvGetSectionName(kv, value, sizeof(value));
	PushArrayString(arr_TimeTiers, value);
	KvGetString(kv, "start day", value, sizeof(value));
	PushArrayCell(arr_TimeTiers, StringToDay(value));
	KvGetString(kv, "end day", value, sizeof(value));
	PushArrayCell(arr_TimeTiers, StringToDay(value));
	PushArrayCell(arr_TimeTiers, KvGetNum(kv, "start", -1));
	PushArrayCell(arr_TimeTiers, KvGetNum(kv, "end", -1));
	PushArrayCell(arr_TimeTiers, KvGetNum(kv, "priority", 0));
}

/**
 * Converts a string containing a day to a int.
 *
 * @param data			Day string to check.
 * @return				-1 if no day found, otherwise int for
 *						day provided.
 */

StringToDay(const String:data[])
{
	decl String:day[4];
	for (new i = 1; i <= 7; i++)
	{
		switch (i)
		{
			case 1:
				Format(day, sizeof(day), "sun");
			case 2:
				Format(day, sizeof(day), "mon");
			case 3:
				Format(day, sizeof(day), "tue");
			case 4:
				Format(day, sizeof(day), "wed");
			case 5:
				Format(day, sizeof(day), "thu");
			case 6:
				Format(day, sizeof(day), "fri");
			case 7:
				Format(day, sizeof(day), "sat");
		}
		if (StrContains(data, day, false) != -1)
		{
			return i;
		}
	}
	
	return -1;
}

/**
 * Checks if and when a time tier needs to start and end.
 *
 * @return				-1 if a tier tier does not need to be
 *						loaded, any other value index to time tier.
 */
 
CheckTimeTiers()
{
	new index = GetArraySize(arr_TimeTiers)-1;
	new m_Priority = -1;
	new m_Index = -1;
	while (index >= 0)
	{
		new Priority = GetArrayCell(arr_TimeTiers, index);
		index--;
		new End = GetArrayCell(arr_TimeTiers, index);
		index--;
		new Start = GetArrayCell(arr_TimeTiers, index);
		index--;
		new EndDay = GetArrayCell(arr_TimeTiers, index);
		index--;
		new StartDay = GetArrayCell(arr_TimeTiers, index);
		index--;
		
		if (Start == -1 || End == -1)
		{
			decl String:timetier[65];
			GetArrayString(arr_TimeTiers, index, timetier, sizeof(timetier));
			LogError("%t", "RCP Timetier No Time", timetier);
			index--;
			continue;
		}
		
		new Time;
		decl String:hour_min[5];
		
		if (StartDay != -1 && EndDay != -1)
		{
			decl String:day[2];
			FormatTime(hour_min, sizeof(hour_min), "%H%M");
			FormatTime(day, sizeof(day), "%w");
			Time = (StringToInt(day)+1)*10000 + StringToInt(hour_min);
			Start = (StartDay*10000)+Start;
			End = (EndDay*10000)+End;
		}
		else
		{
			FormatTime(hour_min, sizeof(hour_min), "%H%M");
			Time = StringToInt(hour_min);
		}
		
		

		if ((Start > End && (Time >= Start || Time >= 0 && Time <= End)) || (Start < End && Time >= Start && Time <= End))
		{
			if (Priority > m_Priority)
			{
				m_Index = index;
				m_Priority = Priority;
			}
		}
		index--;
	}
	
	return m_Index;
}

/**
 * Loads a mapgroup from a full maplist file.
 *
 * @param tier			Tier that requested the mapgroup.
 * @param mapgroup		Mapgroup to load.
 * @param config		Path to the config.
 * @param MapGroupMaps	Array to check for duplicate maps across tier.
 * @return				True if found, false otherwise.
 */

LoadMapGroupInCycleFile(const tier, const String:mapgroup[], const String:config[], Handle:MapGroupMaps)
{
	new bool:write = true;
	if (FindStringInArray(arr_MapGroups, mapgroup) != -1)
	{
		write = false;
	}
	
	new Handle:h_config = OpenFile(config, "r");
	decl String:findgroup[65];
	new bool:found;
	Format(findgroup, sizeof(findgroup), "[%s]", mapgroup);
	new const ArraySize = GetArraySize(arr_MapGroups);
	
	decl String:line[255];
	while (!IsEndOfFile(h_config))
	{
		ReadFileLine(h_config, line, sizeof(line));
		TrimString(line);
		if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
		{
			BreakString(line, line, sizeof(line));
			if (StrEqual(line, findgroup, false))
			{
				decl String:map[65] = "\0";
				new bool:exclude = false;
				found = true;
				while (!IsEndOfFile(h_config))
				{
					ReadFileLine(h_config, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
					{
						if (line[0] == '[')
						{
							break;
						}
						exclude = false;
						BreakString(line, map, sizeof(map));
						if (map[0] == '!')
						{
							Format(map, sizeof(map), "%s", map[1]);
							exclude = true;
						}
						if (!RCP_IsMapValid(map))
						{
							LogError("[%t] %t", "RCP Mapgroup", mapgroup, "RCP Map Error", map);
							continue;
						}
						if (FindStringInArray(arr_Maplist[tier], map) != -1)
						{
							LogError("[%t] %t", "RCP Mapgroup", mapgroup, "RCP Dupe Map", map);
							continue;
						}
						if (FindStringInArray(MapGroupMaps, map) != -1)
						{
							LogError("[%t] %t", "RCP Mapgroup", mapgroup, "RCP Dupe Map", map);
							continue;
						}
						if (exclude)
						{
							Format(map, sizeof(map), "!%s", map);
						}
						PushArrayString(MapGroupMaps, map);
						if (write)
						{
							if (GetArraySize(arr_MapGroups) == ArraySize)
							{
								PushArrayString(arr_MapGroups, mapgroup);
							}
							PushArrayString(arr_MapGroups, map);
							#if DEBUG
							if (GetArraySize(arr_MapGroups) == ArraySize+2)
							{
								LogToFileEx(LogFilePath, "Mapgroup %s maps:", mapgroup);
							}
							LogToFileEx(LogFilePath, "~ %s", map);
							#endif
						}
					}
				}
			}
		}
	}
	
	CloseHandle(h_config);
	
	if (!write)
	{
		return MAPGROUP_VALID;
	}
	
	new CurrentArraySize = GetArraySize(arr_MapGroups);
	
	if (CurrentArraySize > ArraySize)
	{
		decl String:checkmap[65];
		for (new i = ArraySize+1; i < CurrentArraySize; i++)
		{
			GetArrayString(arr_MapGroups, i, checkmap, sizeof(checkmap));
			if (checkmap[0] != '!')
			{
				break;
			}
			if (i == CurrentArraySize-1)
			{
				return MAPGROUP_EMPTY;
			}
		}
		return MAPGROUP_VALID;
	}
	else if (found)
	{
		return MAPGROUP_EMPTY;
	}
	else
	{
		return MAPGROUP_INVALID;
	}
}

/**
 * Loads a specific tier from a full maplist file.
 *
 * @param tier			Tier to load.
 * @param config		Path to the config.
 * @noreturn
 */

LoadTierInCycleFile(const tier, const String:config[])
{
	new Handle:h_config = OpenFile(config, "r");
	decl String:tiertype[16];
	decl String:tiererror[16];
	switch (tier)
	{
		case M_SINGLE:
			Format(tiertype, sizeof(tiertype), "[Single]");
		case M_IDLE:
			Format(tiertype, sizeof(tiertype), "[Idle]");
		case M_HIGH:
			Format(tiertype, sizeof(tiertype), "[High]");
		case M_MED:
			Format(tiertype, sizeof(tiertype), "[Med]");
		case M_LOW:
			Format(tiertype, sizeof(tiertype), "[Low]");
	}
	switch (tier)
	{
		case M_SINGLE:
			Format(tiererror, sizeof(tiererror), "RCP Single");
		case M_IDLE:
			Format(tiererror, sizeof(tiererror), "RCP Idle");
		case M_HIGH:
			Format(tiererror, sizeof(tiererror), "RCP High");
		case M_MED:
			Format(tiererror, sizeof(tiererror), "RCP Med");
		case M_LOW:
			Format(tiererror, sizeof(tiererror), "RCP Low");
	}
	
	new Handle:MapGroup = CreateArray(17);
	decl String:line[255];
	while (!IsEndOfFile(h_config))
	{
		ReadFileLine(h_config, line, sizeof(line));
		TrimString(line);
		if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
		{
			BreakString(line, line, sizeof(line));
			if (StrEqual(line, tiertype, false))
			{
				decl String:map[65] = "\0";
				while (!IsEndOfFile(h_config))
				{
					ReadFileLine(h_config, line, sizeof(line));
					TrimString(line);
					if (line[0] != '/' && line[1] != '/' && line[0] != '\0' && line[0] != '*')
					{
						if (line[0] == '[')
						{
							break;
						}
						BreakString(line, map, sizeof(map));
						if (!RCP_IsMapValid(map))
						{
							if (FindStringInArray(MapGroup, map) != -1)
							{
								LogError("[%t] %t", tiererror, "RCP Dupe Map", map);
								continue;
							}
							PushArrayString(MapGroup, map);
							continue;
						}
						if (FindStringInArray(arr_Maplist[tier], map) != -1)
						{
							LogError("[%t] %t", tiererror, "RCP Dupe Map", map);
							continue;
						}
						PushArrayString(arr_Maplist[tier], map);
						#if DEBUG
						if (GetArraySize(arr_Maplist[tier]) == 1)
						{
							switch (tier)
							{
								case M_SINGLE:
									LogToFileEx(LogFilePath, "Single maps:");
								case M_IDLE:
									LogToFileEx(LogFilePath, "Idle maps:");
								case M_HIGH:
									LogToFileEx(LogFilePath, "High maps:");
								case M_MED:
									LogToFileEx(LogFilePath, "Med maps:");
								case M_LOW:
									LogToFileEx(LogFilePath, "Low maps:");
							}
						}
						LogToFileEx(LogFilePath, "~ %s", map);
						#endif
					}
				}
			}
		}
	}
	
	CloseHandle(h_config);
	
	decl String:map[65] = "\0";
	new MapGroupSize = GetArraySize(MapGroup);
	new Handle:MapGroupMaps = CreateArray(17);
	new MapGroupIndex;
	if (MapGroupSize)
	{
		for (new i; i < MapGroupSize; i++)
		{
			GetArrayString(MapGroup, i, map, sizeof(map));
			MapGroupIndex = LoadMapGroupInCycleFile(tier, map, config, MapGroupMaps);
			if (MapGroupIndex == MAPGROUP_INVALID)
			{	
				LogError("[%t] %t", tiererror, "RCP Map Error", map);
				continue;
			}
			else if (MapGroupIndex == MAPGROUP_EMPTY)
			{
				LogError("%t", "RCP Mapgroup Empty", map);
				continue;
			}
			PushArrayString(arr_Maplist[tier], map);
		}
	}
	
	CloseHandle(MapGroupMaps);
}

/**
 * Filters out maps so the tier can pick a valid map.
 *
 * @param tier			Tier to check.
 * @noreturn
 */

GetPickableMaps(const tier)
{
	if (!g_Exclude[tier])
	{
		PickRandomGroupMaps(tier);
		return;
	}
	
	new found;
	decl String:CheckMap[65];
	for (new i = GetArraySize(arr_MapHistory) - 1; i >= 0; i--)
	{
		GetArrayString(arr_MapHistory, i, CheckMap, sizeof(CheckMap));
		if (CheckForMapInTier(CheckMap, tier))
		{
			found++;
			#if DEBUG
			switch (found)
			{
				case 1:
					LogToFileEx(LogFilePath, "Current history maps:");
			}
			LogToFileEx(LogFilePath, "~ %s", CheckMap);
			#endif
			if (found == g_Exclude[tier])
			{
				break;
			}
		}
	}
	
	PickRandomGroupMaps(tier);
}

/**
 * If a mapgroup exists it will pick a random map.
 *
 * @param tier			Tier to check.
 * @noreturn
 */

PickRandomGroupMaps(const tier)
{
	new ArraySize = GetArraySize(arr_Maplist[tier]);
	decl String:map[65];
	decl String:mapgroupmap[65];
	new index;
	new index_end = GetArraySize(arr_MapGroups);
	new Handle:groupmaps = CreateArray(17);
	for (new i; i < ArraySize; i++)
	{
		GetArrayString(arr_Maplist[tier], i, map, sizeof(map));
		if (!RCP_IsMapValid(map))
		{
			index = FindStringInArray(arr_MapGroups, map);
			for (new i2 = index+1; i2 < index_end; i2++)
			{
				GetArrayString(arr_MapGroups, i2, mapgroupmap, sizeof(mapgroupmap));
				if (mapgroupmap[0] == '!')
				{
					continue;
				}
				if (!RCP_IsMapValid(mapgroupmap))
				{
					break;
				}
				PushArrayString(groupmaps, mapgroupmap);
			}
			index = RCP_GetRandomInt(0, (GetArraySize(groupmaps) - 1));
			GetArrayString(groupmaps, index, mapgroupmap, sizeof(mapgroupmap));
			PushArrayString(arr_Maplist[tier], mapgroupmap);
			RemoveFromArray(arr_Maplist[tier], i);
			ArraySize = GetArraySize(arr_Maplist[tier]);
			ClearArray(groupmaps);
			i--;
		}
	}
	CloseHandle(groupmaps);
}

/**
 * Loads the specified maplist from maplists.cfg.
 *
 * @param tier			Tier to load.
 * @noreturn
 */

LoadMaplistsDotCFG(const tier)
{
	// Made this a seperate function for possible future use.
	decl String:cycle[24];
	switch (tier)
	{
		case M_LOW:
			Format(cycle, sizeof(cycle), "rcplus low");
		case M_MED:
			Format(cycle, sizeof(cycle), "rcplus med");
		case M_HIGH:
			Format(cycle, sizeof(cycle), "rcplus high");
		case M_SINGLE:
			Format(cycle, sizeof(cycle), "rcplus single");
		case M_IDLE:
			Format(cycle, sizeof(cycle), "rcplus idle");
	}
	decl String:map[65];
	new Handle:MaplistArray = CreateArray(17);
	new serial;
	ReadMapList(MaplistArray, serial, cycle, MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_CLEARARRAY);
	new arraySize = GetArraySize(MaplistArray);
	if (arraySize)
	{
		decl String:tiererror[24];
		switch (tier)
		{
			case M_LOW:
				Format(tiererror, sizeof(tiererror), "RCP Low");
			case M_MED:
				Format(tiererror, sizeof(tiererror), "RCP Med");
			case M_HIGH:
				Format(tiererror, sizeof(tiererror), "RCP High");
			case M_SINGLE:
				Format(tiererror, sizeof(tiererror), "RCP Single");
			case M_IDLE:
				Format(tiererror, sizeof(tiererror), "RCP Idle");
		}
		// LoadMapList() checks for invalid maps beforehand so that's why the RCP_IsMapValid check is not in this loop.
		for (new i; i < arraySize; i++)
		{
			GetArrayString(MaplistArray, i, map, sizeof(map));
			if (FindStringInArray(arr_Maplist[tier], map) != -1)
			{
				LogError("[%s - maplists.cfg] %t", tiererror, "RCP Dupe Map", map);
				continue;
			}
			PushArrayString(arr_Maplist[tier], map);
			#if DEBUG
			if (GetArraySize(arr_Maplist[tier]) == 1)
			{
				switch (tier)
				{
					case M_LOW:
						LogToFileEx(LogFilePath, "Low maps [maplists.cfg]:");
					case M_MED:
						LogToFileEx(LogFilePath, "Med maps [maplists.cfg]:");
					case M_HIGH:
						LogToFileEx(LogFilePath, "High maps [maplists.cfg]:");
					case M_SINGLE:
						LogToFileEx(LogFilePath, "Single maps [maplists.cfg]:");
					case M_IDLE:
						LogToFileEx(LogFilePath, "Idle maps [maplists.cfg]:");
				}
			}
			LogToFileEx(LogFilePath, "~ %s", map);
			#endif
		}
	}
	CloseHandle(MaplistArray);
}

/**
 * Loads SM internal maphistory.
 *
 * @noreturn
 */

HistoryArray()
{
	decl String:HistoryMap[65];
	new HistorySize;
	ClearArray(arr_MapHistory);
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
			PushArrayString(arr_MapHistory, HistoryMap);
		}
	}
}

/**
 * Parses all the tiers and sets the map accordingly to the server player count.
 *
 * @noreturn					
 */

RandomCycleCheck(const force = -1)
{
	if (force >= 0)
	{
		ParseTier(force);
		return;
	}
	
	// All the checks for what map to pick.
	if (b_NextMapChanged || (!b_Loaded && force != -2))
	{
		return;
	}
	
	if (h_IdleServer != INVALID_HANDLE && !g_Players)
	{
		ParseTier(M_IDLE);
		return;
	}
	
	if (g_UseTierType[TYPE_SINGLE])
	{
		ParseTier(M_SINGLE);
		return;
	}
	
	if (p_High && g_Players >= p_High)
	{
		ParseTier(M_HIGH);
		return;
	}
	
	if ((p_High && p_Low) && g_Players > p_Low && (g_Players < p_High))
	{
		ParseTier(M_MED);
		return;
	}
	
	if (p_Low && (g_Players <= p_Low))
	{
		ParseTier(M_LOW);
		return;
	}
	
	// The fall-back code is now a lot less messy due to all the returns above.
	if (g_CycleRun == M_OLD)
	{
		return;
	}
	g_CycleRun = M_OLD;
	SetRandomMap(M_OLD);
}

/**
 * Parses a single tier.
 *
 * @param tier				Index of the tier to parse.
 * @noreturn
 */

ParseTier(const tier)
{
	if (g_CycleRun == tier)
	{
		return;
	}
	g_CycleRun = tier;
	if (b_PickMap[tier])
	{
		GetRandomMap(tier);
	}
	SetRandomMap(tier);
	ExecKvConfigs(tier);
}

/**
 * Executes configs when a tier becomes active.
 *
 * @param tier				Index of the tier to load the configs for.
 * @noreturn					
 */

ExecKvConfigs(const tier)
{
	new ArraySize = GetArraySize(arr_Configs[tier]);
	if (!ArraySize)
	{
		return;
	}
	
	decl String:cvar[130];
	for (new i; i < ArraySize; i++)
	{
		GetArrayString(arr_Configs[tier], i, cvar, sizeof(cvar));
		ServerCommand("%s", cvar);
	}
}

/**
 * Gets a valid random map for the specified tier.
 *
 * @param tier				Index of the tier to get a random map for.
 * @noreturn					
 */
 
GetRandomMap(const tier)
{	
	decl String:map[65];
	GetPickableMaps(tier);
	GetArrayString(arr_Maplist[tier], RCP_GetRandomInt(0, (GetArraySize(arr_Maplist[tier]) - 1)), map, sizeof(map));
	ClearArray(arr_PickedMap[tier]);
	PushArrayString(arr_PickedMap[tier], map);
}

/**
 * Sets the generated random map for the specified tier.
 *
 * @param tier				Index of the tier to get the set random map from.
 * @noreturn					
 */

SetRandomMap(const tier)
{
	decl String:map[65];
	GetArrayString(arr_PickedMap[tier], 0, map, sizeof(map));
	if (GetConVarInt(cvar_NextMapHide))
	{
		new cvarflags = GetConVarFlags(g_NextMap);
		new cvarflags_reset = cvarflags;
		cvarflags &= ~FCVAR_NOTIFY;
		SetConVarFlags(g_NextMap, cvarflags);
		SetNextMap(map);
		SetConVarFlags(g_NextMap, cvarflags_reset);
	} 
	else 
	{
		SetNextMap(map);
	}
	
	b_NextMapChanged = false;
	
	if (GetConVarInt(cvar_Announce))
	{
		PrintToChatAll("%t", "RCP Nextmap", map);
	}
	
	if (GetConVarInt(cvar_Log))
	{
		LogMessage("%t", "RCP Nextmap", map);
	}
	
	b_PickMap[tier] = false;
	
	#if DEBUG
	switch (tier)
	{
		case M_SINGLE:
			LogToFileEx(LogFilePath, "rc+ set single tier map: %s", map);
		case M_HIGH:
			LogToFileEx(LogFilePath, "rc+ set high tier map: %s", map);
		case M_MED:
			LogToFileEx(LogFilePath, "rc+ set med tier map: %s", map);
		case M_LOW:
			LogToFileEx(LogFilePath, "rc+ set low tier map: %s", map);
		case M_OLD:
			LogToFileEx(LogFilePath, "rc+ set old map: %s", map);
		case M_IDLE:
			LogToFileEx(LogFilePath, "rc+ set idle map: %s", map);
	}
	LogToFileEx(LogFilePath, "Current player count: %d", g_Players);
	#endif
}

/**
 * Checks to see if the server needs to go into idle mode.
 *
 * @noreturn					
 */

ServerIdleCheck()
{
	#if DEBUG
	LogToFileEx(LogFilePath, "Running idle check.");
	#endif
	if (g_UseTierType[TYPE_IDLE] && !g_Players && h_IdleServer == INVALID_HANDLE)
	{
		decl String:CurrentMap[65];
		GetCurrentMap(CurrentMap, sizeof(CurrentMap));
		if (FindStringInArray(arr_Maplist[M_IDLE], CurrentMap) == -1)
		{
			h_IdleServer = CreateTimer(GetConVarFloat(cvar_IdleTime), t_IdleServer, _, TIMER_FLAG_NO_MAPCHANGE);
			#if DEBUG
			LogToFileEx(LogFilePath, "Starting normal idle server timer.");
			#endif
		} 
		else if (GetConVarInt(cvar_IdleTimeRotate))
		{
			h_IdleServer = CreateTimer(float(GetConVarInt(cvar_IdleTimeRotate))*60, t_IdleServer, _, TIMER_FLAG_NO_MAPCHANGE);
			#if DEBUG
			LogToFileEx(LogFilePath, "Starting rotating idle server timer.");
			#endif
		}
	}
	else if (h_IdleServer != INVALID_HANDLE && !g_UseTierType[TYPE_IDLE])
	{
		KillTimer(h_IdleServer);
		h_IdleServer = INVALID_HANDLE;
		#if DEBUG
		LogToFileEx(LogFilePath, "Killed idle server timer.");
		#endif
		RandomCycleCheck();
	}
}

/**
 * Caches all valid maps, decreases excessive access during map checking.
 *
 * @noreturn					
 */
 
CacheValidMaps()
{
	ClearArray(arr_Maps);
	new serial = -1;
	ReadMapList(arr_Maps, serial, "rcplus maps", MAPLIST_FLAG_MAPSFOLDER|MAPLIST_FLAG_NO_DEFAULT|MAPLIST_FLAG_CLEARARRAY);
}

/**
 * This is to check for a validmap, this is used for loading mapgroups too so
 * this functions supresses the console spam.
 *
 * @return				True on map found, false if mapgroup/invalid.					
 */

RCP_IsMapValid(const String:srcmap[])
{
	if (FindStringInArray(arr_Maps, srcmap) != -1)
	{
		return true;
	}
	
	return false;
}

/**
 * Internal random number generation using SM 1.3+ specific number generation
 * for better randoms. Thanks to psychonic for this.
 *
 * @min					Minimum value to return.
 * @max					Maximum value to return.
 * @return				Valid number between the values provided.					
 */
 
RCP_GetRandomInt(const min, const max)
{
	return (GetURandomInt() % (max-min+1)) + min;
}