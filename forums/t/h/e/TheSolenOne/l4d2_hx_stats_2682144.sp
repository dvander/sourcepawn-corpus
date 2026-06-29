/**
 *
 * =============================================================================
 * Copyright 2017-2020 steamcommunity.com/profiles/76561198025355822/
 * Fork by Dragokas: steamcommunity.com/id/drago-kas/
 * Статистика игроков.
 * =============================================================================
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 *
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program. If not, see <www.gnu.org/licenses/>.
 *
 * As a special exception, AlliedModders LLC gives you permission to link the
 * code of this program (as well as its derivative works) to "Half-Life 2," the
 * "Source Engine," the "SourcePawn JIT," and any Game MODs that run on software
 * by the Valve Corporation.  You must obey the GNU General Public License in
 * all respects for all other code used.  Additionally, AlliedModders LLC grants
 * this exception to all derivative works.  AlliedModders LLC defines further
 * exceptions, found in LICENSE.txt (as of this writing, version JULY-31-2007),
 * or <www.sourcemod.net/license.php>.
 *
*/

#define PLUGIN_VERSION "1.0.10"

/*
	Version history:
	
	1.0.10 (09-Jan-2020)
	 - Fixed error in log and disabled 'win' message for client with permanent VIP status (thanks to ur5efj for report).
	 - VIP_GROUP define is replaced by new "l4d_hxstat_vip_group" ConVar (for easy update).
	 - BASE_MENU define is replaced by new "l4d_hxstat_base_menu" ConVar (for easy update).
	
	1.0.9 (03-Jan-2020)
	 - Potential fix: to prevent SQL query cache cause move week points twice (I hope).
	 - Disabled DB disconnection on round end.
	
	1.0.8 (26-Dec-2019)
	 - Fixed chat messages are displayed even if points are disabled.
	
	1.0.7 (24-Dec-2019)
	 - Fixed double-save points on player disconnect caused no points are saved at all (in L4D2).
	 - Fixed 'Witch' and 'Commons' points are not counted (in L4D2).
	 - 'Description of points' screen is splitted into 2 parts (for L4D2), because they doesn't fit in one.
	 - "Rank of other player" is now displayed in correct (requestor) language.
	 - Added command: "sm_hx_delplayer" <SteamId> - delete statistics of this player completely.
	 - Added command: "sm_hx_delold" <days> - delete players who didn't join for more than <days> ago (it is recommnded to use with `sm_hx_backup` first)
	 - Added ability to disable some fields in statistics (you just need to set '0' points in ConVars where you want).
	 - Added ability to hide some players from statistics (requested by Re:Creator). 
	 See "l4d_hxstat_hide_flag" ConVar. Offline players are not supported. They should join the server at least once to populate database.
	
	* DataBase Table version is now 2.3. Use "sm_hx_upgrade" to upgrade.
	
	* Web-site files (index.php) are updated!
	
	1.0.6 (16-Dec-2019)
	 - Some SQL queries simplification
	 - Updated SQL queries to follow standard
	
	1.0.5 (15-Dec-2019)
	 - Fixed hardcoded string not allowing to use "sm_hx_upgrade".
	
	1.0.4 (14-Dec-2019)
	 - Added penalties:
	 * Survivor death
	 * Survivor Incap
	 * Friendly-fire
	 
	 - Added ability to see "Rank of other player"
	 
	* DataBase Table version is now 2.2. Use "sm_hx_upgrade" to upgrade.

	1.0.3 (01-Dec-2019)
	 - Added "sm_hx_showpoints" to view points of specific player by name / userid / steamid.
	 - Added "sm_hx_movepoints" to move points to another account (useful, if steam id is changed).
	 - "sm_topweek" renamed to "sm_hx_logpoints" and include top of last week and last month.
	 - Added auto-reconnect to database (max 20 attempts each 3 sec.) in case initial connection cannot be established for some reason.

	1.0.2 (29-Nov-2019)
	 - Added integration with VIP Core by R1KO (added new ConVars).
	 - Finished functionality on shifting stats: week -> last week, month -> last month.
	 - Added ability to dump top of week to log, e.g. for your news site (sm_topweek).
	 - Added place of player.
	 
	 - Added "HX_GetPoints" native.
	 - Added "sm_hx_upgrade" command to upgrade database table version.
	 - Added "sm_hx_backup" command to make a backup just in case.
	 - "sm_addsqlcreate" renamed to "sm_hx_sqlcreate" and now is not required while installation (leave just in case).
	 
	 - All SQL queries are now Multi-threaded and no more spike the server.
	 
	 - Statistics is now correctly re-loaded on plugin late load.
	 - Fixed: statistics is not saved when map is forcibly changed (by vote).
	 - User name escaping algorithm is replaced by SQL_EscapeString to be less false positive.
	 - Prevented counting game time points for !afk clients.
	 - Fixed "l4d_hxstat_points_time" ConVar is not worked.
	 
	* DataBase Table version is now 2.1. Use "sm_hx_upgrade" to upgrade.
	
	1.0.1 (16-Nov-2019)
	 - Added L4D1 support
	 
	 - added convars to choose min rank for blocking callvote and idle
	 - added convar to enable/disable coloring players by stat
	 - added convar to control min. interval allowed to call !top again
	 - Added convars for adjusting points of each type of killed infected, separately options for: 1. Killing 50 common, 2. Spent 30 minutes in game.
	 - Added convar for disabling printing the points in chat
	 - Added convars to choose whether you want to show player's rank on round start and delay
	 
	 - Added !stat command to open main menu
	 - Added top of month / top of week (including previous month / week).
	 - Added menu with points description
	 
	 - Added translation support
	 - Added translation into Russian
	 
	 - Added library "hx_stats" registration
	 - Added native "HX_AddPoints" for developers
	 
	 - client id replaced by UserId in timers
	 - Some code and SQL optimizations.
	 - Added protection and walkaround if Steam background is not responding
	 - !rank total score is now calculated more accurately
	 - Fixed empty name in database when new player connected
	 - Fixed bug when stats are not saved at all on player disconnect when none commons are killed
	
	PHP update:
	 - Added L4d1 version of html/php scripts
	 - links are opened in the same window now
	 
	* DataBase Table version is now 2.0.
	
-----------------------------------------------------------------------------------------
	
	// TODO:
	* Nothing for now.
	 
-----------------------------------------------------------------------------------------

Notes:
	timedatectl set-ntp 0
	date --set="2019-12-02 10:05:59.990"

*/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>

#undef REQUIRE_PLUGIN
#tryinclude <vip_core>

#define CVAR_FLAGS FCVAR_NOTIFY

#define DEBUG 0

#define HX_TABLE "l4d2_stats"
#define HX_TABLE_BACKUP "l4d2_stats_backup"
#define HX_DATABASE_CFG "l4d2_stats"

#define HX_REMOVE_TABLE "DROP TABLE IF EXISTS `"...HX_TABLE..."`;"
#define HX_CREATE_TABLE "\
CREATE TABLE IF NOT EXISTS `"...HX_TABLE..."` (\
 `Steamid` varchar(32) NOT NULL DEFAULT '',\
 `Name` tinyblob NOT NULL,\
 `Points` int(11) NOT NULL DEFAULT '0',\
 `Pt_month` int(11) NOT NULL DEFAULT '0',\
 `Pt_week` int(11) NOT NULL DEFAULT '0',\
 `Pt_lmonth` int(11) NOT NULL DEFAULT '0',\
 `Pt_lweek` int(11) NOT NULL DEFAULT '0',\
 `Time1` int(11) NOT NULL DEFAULT '0',\
 `Time2` int(11) NOT NULL DEFAULT '0',\
 `VipQueue` int(11) NOT NULL DEFAULT '0',\
 `Penalty` int(11) NOT NULL DEFAULT '0',\
 `Hide` SMALLINT NOT NULL DEFAULT '0',\
 `Boomer` int(11) NOT NULL DEFAULT '0',\
 `Charger` int(11) NOT NULL DEFAULT '0',\
 `Hunter` int(11) NOT NULL DEFAULT '0',\
 `Infected` int(11) NOT NULL DEFAULT '0',\
 `Jockey` int(11) NOT NULL DEFAULT '0',\
 `Smoker` int(11) NOT NULL DEFAULT '0',\
 `Spitter` int(11) NOT NULL DEFAULT '0',\
 `Tank` int(11) NOT NULL DEFAULT '0',\
 `Witch` int(11) NOT NULL DEFAULT '0',\
 PRIMARY KEY (`Steamid`)\
) ENGINE=MyISAM DEFAULT CHARSET=utf8;\
"
#define HX_SERVICE_STEAM "DATABASE_UPDATE"

enum
{
	PERIOD_TOTAL,
	PERIOD_MONTH,
	PERIOD_WEEK,
	PERIOD_LAST_MONTH,
	PERIOD_LAST_WEEK
}

enum
{
	HX_POINTS,
	HX_TIME,
	HX_BOOMER,
	HX_CHARGER,
	HX_HUNTER,
	HX_INFECTED,
	HX_JOCKEY,
	HX_SMOKER,
	HX_SPITTER,
	HX_TANK,
	HX_WITCH,
	HX_POINTS_MONTH,
	HX_POINTS_WEEK,
	HX_POINTS_LAST_MONTH,
	HX_POINTS_LAST_WEEK,
	HX_PLACE,
	HX_VIP_QUEUE,
	HX_PENALTY,
	HX_PENALTY_DEATH,
	HX_PENALTY_INCAP,
	HX_PENALTY_FF,
	HX_HIDE,
	HX_POINTS_SIZE
}

enum REQUEST_ACTIONS
{
	ACTION_SHOWPOINTS,
	ACTION_MOVEPOINTS
}

REQUEST_ACTIONS g_iReqAction;

char g_sQuery1[1000];
char g_sQuery2[1000];
char g_sQuery3[1000];

char g_sBuf1[1000];
char g_sBuf3[1000];

char g_sSteamId[MAXPLAYERS+1][32];
char g_sReqSteam[1000];
char g_sDestSteam[1000];
char g_sMenuName[1000];
char g_sBaseMenu[1000];
char g_sVIPGroup[1000];

int g_iTemp[MAXPLAYERS+1][HX_POINTS_SIZE];
int g_iReal[MAXPLAYERS+1][HX_POINTS_SIZE];
int g_iTopLastTime[MAXPLAYERS+1];
int g_iRoundStart;

int g_iPointsTime;
int g_iPointsInfected;
int g_iPointsBoomer;
int g_iPointsCharger;
int g_iPointsHunter;
int g_iPointsJockey;
int g_iPointsSmoker;
int g_iPointsSpitter;
int g_iPointsTank;
int g_iPointsWitch;
int g_iPenaltyDeath;
int g_iPenaltyIncap;
int g_iPenaltyFF;
int g_iCommonsToKill;
int g_iTimeToPlay;
int g_iRequestorId;
int g_iHiddenFlagBits;

float g_fPenaltyBonus[MAXPLAYERS+1]; // for a very little damage values ( < 10 )

bool g_bLateload;
bool g_bL4D2;
bool g_bInDisconnect[MAXPLAYERS+1];
bool g_bPrintPoints;
bool g_bBaseMenuAvail;
bool g_bMapTransition;
bool g_bVipCoreLib;
#pragma unused g_bVipCoreLib

Database g_hDB;

ConVar g_ConVarVoteRank;
ConVar g_ConVarIdleRank;
ConVar g_ConVarUseColors;
ConVar g_ConVarTopCallInterval;
ConVar g_ConVarPoints[HX_POINTS_SIZE];
ConVar g_ConVarPrintPoints;
ConVar g_ConVarMenuName;
ConVar g_ConVarCommonsToKill;
ConVar g_ConVarTimeToPlay;
ConVar g_ConVarShowRankRoundStart;
ConVar g_ConVarShowRankDelay;
ConVar g_ConVarFirstDayOfWeek;
ConVar g_ConVarLimitTopAll;
ConVar g_ConVarLimitTopWeek;
ConVar g_ConVarLimitTopMonth;
ConVar g_ConVarLimitTopWeekVIP;
ConVar g_ConVarLimitTopMonthVIP;
ConVar g_ConVarAwardTopWeekVIP;
ConVar g_ConVarAwardTopMonthVIP;
ConVar g_ConVarHideFlag;
ConVar g_ConVarVIPGroup;
ConVar g_ConVarBaseMenu;
	

public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	EngineVersion test = GetEngineVersion();
	if (test == Engine_Left4Dead2)
	{
		g_bL4D2 = true;
	}
	else if (test != Engine_Left4Dead) {
		strcopy(error, err_max, "Plugin only supports Left 4 Dead 1 & 2.");
		return APLRes_SilentFailure;
	}
	g_bLateload = late;
	CreateNative("HX_AddPoints", NATIVE_AddPoints);
	CreateNative("HX_GetPoints", NATIVE_GetPoints);
	RegPluginLibrary("hx_stats");
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D] HX_Stats Remastered",
	author = "MAKS (fork by Dragokas, edit by TheSolenOne)",
	description = "L4D 1/2 Coop Stats",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=320247"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("hx_stats.phrases");
	
	CreateConVar("l4d_hxstat_version", 	PLUGIN_VERSION, "Version of this plugin", FCVAR_DONTRECORD);
	
	g_ConVarVoteRank = CreateConVar("l4d_hxstat_callvote_rank", 			"0", 	"Minimum rank to allow using the vote", CVAR_FLAGS);
	g_ConVarIdleRank = CreateConVar("l4d_hxstat_idle_rank", 				"0", 	"Minimum rank to allow using !idle", CVAR_FLAGS);
	g_ConVarUseColors = CreateConVar("l4d_hxstat_use_colors", 				"0", 	"Change player's color according to his rank (0 - No, 1 - Yes)", CVAR_FLAGS);
	g_ConVarTopCallInterval = CreateConVar("l4d_hxstat_rank_call_interval", "30", 	"Minimum interval (in sec.) to allow calling !top again", CVAR_FLAGS);
	g_ConVarPrintPoints = CreateConVar("l4d_hxstat_print_points", 			"1", 	"Print points in chat when you kill infected? (0 - No, 1 - Yes)", CVAR_FLAGS);
	g_ConVarShowRankRoundStart = CreateConVar("l4d_hxstat_rank_onstart",	"1", 	"Show rank on round start? (0 - No, 1 - Yes)", CVAR_FLAGS);
	g_ConVarShowRankDelay = CreateConVar("l4d_hxstat_rank_delay", 			"6.0", 	"Delay (in sec.) on round start to show player's rank", CVAR_FLAGS);
	g_ConVarHideFlag = CreateConVar("l4d_hxstat_hide_flag", 				"", 	"Users with these flag(s) will be hidden in statistics", CVAR_FLAGS);
	
	g_ConVarPoints[HX_BOOMER] = CreateConVar("l4d_hxstat_points_boomer", 	"1", 	"How many points to give for killing the boomer", CVAR_FLAGS);
	g_ConVarPoints[HX_CHARGER] = CreateConVar("l4d_hxstat_points_charger", 	"1", 	"How many points to give for killing the charger", CVAR_FLAGS);
	g_ConVarPoints[HX_HUNTER] = CreateConVar("l4d_hxstat_points_hunter", 	"1", 	"How many points to give for killing the hunter", CVAR_FLAGS);
	g_ConVarPoints[HX_JOCKEY] = CreateConVar("l4d_hxstat_points_jockey", 	"1", 	"How many points to give for killing the jockey", CVAR_FLAGS);
	g_ConVarPoints[HX_SMOKER] = CreateConVar("l4d_hxstat_points_smoker", 	"1", 	"How many points to give for killing the smoker", CVAR_FLAGS);
	g_ConVarPoints[HX_SPITTER] = CreateConVar("l4d_hxstat_points_spitter", 	"1", 	"How many points to give for killing the spitter", CVAR_FLAGS);
	g_ConVarPoints[HX_TANK] = CreateConVar("l4d_hxstat_points_tank", 		"5", 	"How many points to give for final tank shoot", CVAR_FLAGS);
	g_ConVarPoints[HX_WITCH] = CreateConVar("l4d_hxstat_points_witch", 		"2", 	"How many points to give for killing the witch", CVAR_FLAGS);
	
	g_ConVarPoints[HX_PENALTY_DEATH] = CreateConVar("l4d_hxstat_points_penalty_death", 	"-20", 	"How many points penalty for beeing killed by infected", CVAR_FLAGS);
	g_ConVarPoints[HX_PENALTY_INCAP] = CreateConVar("l4d_hxstat_points_penalty_incap", 	"-5", 	"How many points penalty for beeing incapacitated", CVAR_FLAGS);
	g_ConVarPoints[HX_PENALTY_FF] = CreateConVar("l4d_hxstat_points_penalty_ff", 		"-1", 	"How many points penalty for shooting teammate decreasing 10 hp", CVAR_FLAGS);
	
	g_ConVarCommonsToKill = CreateConVar("l4d_hxstat_commons_kill", 		"50", 	"How many common zombies to kill to give points (for each piece)? (0 - to disable)", CVAR_FLAGS);
	g_ConVarPoints[HX_INFECTED] = CreateConVar("l4d_hxstat_points_infected", "1", 	"How many points to give for killing X common zombies", CVAR_FLAGS);
	
	g_ConVarTimeToPlay = CreateConVar("l4d_hxstat_time_play", 				"30", 	"How much time to play (in minutes) to give points (for each time interval)? (0 - to disable)", CVAR_FLAGS);
	g_ConVarPoints[HX_TIME] = CreateConVar("l4d_hxstat_points_time", 		"10", 	"How many points to give for X minutes spent in game", CVAR_FLAGS);
	
	g_ConVarMenuName = CreateConVar("l4d_hxstat_menu_name", "My Server name", 		"Name of statistics menu in !stat command", CVAR_FLAGS);
	g_ConVarVIPGroup = CreateConVar("l4d_hxstat_vip_group", "Black VIP", 			"VIP Group name (see file: data/vip/cfg/groups.ini)", CVAR_FLAGS);
	g_ConVarBaseMenu = CreateConVar("l4d_hxstat_base_menu", "sm_menu", 				"Command of 3d-party plugin to execute when you press 'Back' button in menu (leave empty, if none need)", CVAR_FLAGS);
	
	g_ConVarLimitTopAll = CreateConVar("l4d_hxstat_limit_top_all", 				"15", 	"How many players to show in global top", CVAR_FLAGS);
	g_ConVarLimitTopWeek = CreateConVar("l4d_hxstat_limit_top_week", 			"15", 	"How many players to show in top of week", CVAR_FLAGS);
	g_ConVarLimitTopMonth = CreateConVar("l4d_hxstat_limit_top_month", 			"15", 	"How many players to show in top of month", CVAR_FLAGS);
	g_ConVarLimitTopWeekVIP = CreateConVar("l4d_hxstat_limit_top_week_vip", 	"10", 	"How many players to award in top of week (and to show in top of last week)", CVAR_FLAGS);
	g_ConVarLimitTopMonthVIP = CreateConVar("l4d_hxstat_limit_top_month_vip", 	"3", 	"How many players to award in top of month (and to show in top of last month)", CVAR_FLAGS);
	g_ConVarAwardTopWeekVIP = CreateConVar("l4d_hxstat_award_top_week_vip", 	"7", 	"How many days of VIP to award player with (in winning top of week) (0 - to disable)", CVAR_FLAGS);
	g_ConVarAwardTopMonthVIP = CreateConVar("l4d_hxstat_award_top_month_vip", 	"31", 	"How many days of VIP to award player with (in winning top of month) (0 - to disable)", CVAR_FLAGS);
	g_ConVarFirstDayOfWeek = CreateConVar("l4d_hxstat_firstday", 				"1", 	"First day of the week (0 - Sunday, 1 - Monday)", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_hx_stats");
	
	HookEvent("round_start", 			Event_RoundStart, 		EventHookMode_PostNoCopy);
	HookEvent("player_death", 			Event_PlayerDeath, 		EventHookMode_Pre);
	HookEvent("player_incapacitated",	Event_PlayerIncap, 		EventHookMode_Post);
	HookEvent("player_hurt",			Event_PlayerHurt, 		EventHookMode_Post);
	HookEvent("map_transition", 		Event_MapTransition, 	EventHookMode_PostNoCopy);
	HookEvent("finale_win", 			Event_MapTransition, 	EventHookMode_PostNoCopy);
	HookEvent("round_end", 				Event_SQL_Save, 		EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", 		Event_PlayerDisconnect, EventHookMode_Pre);
	
	AddCommandListener(Listen_Keyboard, "go_away_from_keyboard");
	AddCommandListener(Listen_Callvote, "callvote");
	
	RegAdminCmd("sm_hx_sqlcreate", 	CMD_sqlcreate, 	ADMFLAG_ROOT, "Creates database table in case automatic mode is failed (warning: all data will be erased !!!)");
	RegAdminCmd("sm_hx_logpoints", 	CMD_LogPoints, 	ADMFLAG_ROOT, "Prints to log the list of top players of the last week and the last month");
	RegAdminCmd("sm_hx_upgrade", 	CMD_Upgrade,	ADMFLAG_ROOT, "Updates database table to the latest version");
	RegAdminCmd("sm_hx_backup", 	CMD_Backup,		ADMFLAG_ROOT, "Backups database table (by default, to `l4d2_stats_backup` table). Warning: old backup will be erased !!!");
	RegAdminCmd("sm_hx_revert", 	CMD_Revert,		ADMFLAG_ROOT, "Revert a database from a backup. Warning: current database table will be lost !!!");
	RegAdminCmd("sm_hx_showpoints",	CMD_ShowPoints,	ADMFLAG_ROOT, "sm_hx_showpoints <#userid|name|steamid> - show points of specified player (including offline, if steamid provided)");
	RegAdminCmd("sm_hx_movepoints",	CMD_MovePoints,	ADMFLAG_ROOT, "sm_hx_movepoints <steamid of source> <steamid of destination> - move points to another account (useful, if steam id is changed)");
	RegAdminCmd("sm_hx_delplayer",	CMD_DelPlayer,	ADMFLAG_ROOT, "sm_hx_delplayer <steamid> - delete statistics of this player completely");
	RegAdminCmd("sm_hx_delold",		CMD_DelOld,		ADMFLAG_ROOT, "sm_hx_delold <days> - delete players who didn't join for more than <days> ago (it is recommnded to use with `sm_hx_backup` first)");
	
	RegConsoleCmd("sm_stat", 		CMD_stat,	"HX Statistics main menu");
	RegConsoleCmd("sm_rank", 		CMD_rank,	"Show my rank and all my stats");
	RegConsoleCmd("sm_top", 		CMD_top,	"Show top players of all the time");
	RegConsoleCmd("sm_top10", 		CMD_top,	"-||-");
	
	#if DEBUG
	RegAdminCmd("sm_hx_refresh", CMD_Refresh, ADMFLAG_ROOT, "Force saving points to a database");
	#endif
	
	CreateTimer(60.0, HxTimer_Infinite18, _, TIMER_REPEAT);
	
	if (g_bLateload)
	{
		g_iRoundStart = 1;
		g_bVipCoreLib = LibraryExists("vip_core");
		//OnConfigsExecuted(); // called by default
	}
	
	g_ConVarMenuName.AddChangeHook(ConVarChanged);
	g_ConVarPrintPoints.AddChangeHook(ConVarChanged);
	g_ConVarHideFlag.AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_BOOMER].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_CHARGER].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_HUNTER].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_JOCKEY].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_SMOKER].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_SPITTER].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_TANK].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_WITCH].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_INFECTED].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_TIME].AddChangeHook(ConVarChanged);
	g_ConVarCommonsToKill.AddChangeHook(ConVarChanged);
	g_ConVarTimeToPlay.AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_PENALTY_DEATH].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_PENALTY_INCAP].AddChangeHook(ConVarChanged);
	g_ConVarPoints[HX_PENALTY_FF].AddChangeHook(ConVarChanged);
	g_ConVarBaseMenu.AddChangeHook(ConVarChanged);
	g_ConVarVIPGroup.AddChangeHook(ConVarChanged);
	
	ReadConVars();
}

public void OnAllPluginsLoaded()
{
	g_bBaseMenuAvail = CommandExists(g_sBaseMenu);
}

#if defined _vip_core_included

public void VIP_OnVIPLoaded()
{
	g_bVipCoreLib = true;
}

public void OnLibraryRemoved(const char[] name)
{
	if (strcmp(name, "vip_core") == 0)
	{
		g_bVipCoreLib = false;
	}
}
#endif

/* ==============================================================
						C O N.  V A R S
// ============================================================== */

public void ConVarChanged(Handle convar, const char[] oldValue, const char[] newValue)
{
	ReadConVars();
}

void ReadConVars()
{
	g_ConVarMenuName.GetString(g_sMenuName, sizeof(g_sMenuName));
	g_ConVarVIPGroup.GetString(g_sVIPGroup, sizeof(g_sVIPGroup));
	g_ConVarBaseMenu.GetString(g_sBaseMenu, sizeof(g_sBaseMenu));
	
	AdminFlag flag;
	static char sFlags[32];
	
	g_ConVarHideFlag.GetString(sFlags, sizeof(sFlags));
	g_iHiddenFlagBits = 0;
	
	for (int i = 0; i < strlen(sFlags); i++)
		if (FindFlagByChar(sFlags[i], flag))
			g_iHiddenFlagBits |= FlagToBit(flag);
	
	g_bPrintPoints = g_ConVarPrintPoints.BoolValue;
	g_iPointsTime = g_ConVarPoints[HX_TIME].IntValue;
	g_iPointsInfected = g_ConVarPoints[HX_INFECTED].IntValue;
	g_iPointsBoomer = g_ConVarPoints[HX_BOOMER].IntValue;
	g_iPointsCharger = g_ConVarPoints[HX_CHARGER].IntValue;
	g_iPointsHunter = g_ConVarPoints[HX_HUNTER].IntValue;
	g_iPointsJockey = g_ConVarPoints[HX_JOCKEY].IntValue;
	g_iPointsSmoker = g_ConVarPoints[HX_SMOKER].IntValue;
	g_iPointsSpitter = g_ConVarPoints[HX_SPITTER].IntValue;
	g_iPointsTank = g_ConVarPoints[HX_TANK].IntValue;
	g_iPointsWitch = g_ConVarPoints[HX_WITCH].IntValue;
	g_iCommonsToKill = g_ConVarCommonsToKill.IntValue;
	g_iTimeToPlay = g_ConVarTimeToPlay.IntValue;
	g_iPenaltyDeath = g_ConVarPoints[HX_PENALTY_DEATH].IntValue;
	g_iPenaltyIncap = g_ConVarPoints[HX_PENALTY_INCAP].IntValue;
	g_iPenaltyFF = g_ConVarPoints[HX_PENALTY_FF].IntValue;
}

/* ==============================================================
						N A T I V E S
// ============================================================== */

public int NATIVE_AddPoints(Handle plugin, int numParams)
{
	if(numParams < 2)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int iClient = GetNativeCell(1);
	int iPoints = GetNativeCell(2);
	
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_PARAM, "[HXStats] HX_AddPoints: client %i is not in game", iClient);
	
	g_iTemp[iClient][HX_POINTS] += iPoints;
	return 0;
}

public int NATIVE_GetPoints(Handle plugin, int numParams)
{
	if(numParams < 3)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int iClient = GetNativeCell(1);
	int iIsTotal = GetNativeCell(2);
	int iType = GetNativeCell(3);
	
	if (iType >= HX_POINTS_SIZE 	||
		iType == HX_VIP_QUEUE		||
		iType == HX_PENALTY_DEATH	||
		iType == HX_PENALTY_INCAP	||
		iType == HX_PENALTY_FF		)
		ThrowNativeError(SP_ERROR_PARAM, "[HXStats] HX_GetPoints: requested incompatible type %i", iType);
	
	if (!IsClientInGame(iClient))
		ThrowNativeError(SP_ERROR_PARAM, "[HXStats] HX_GetPoints: client %i is not in game", iClient);
	
	if (iIsTotal == 1)
	{
		return g_iReal[iClient][iType];
	}
	else {
		return g_iTemp[iClient][iType];
	}
}

/* ==============================================================
					EVENTS  &  FORWARDS
// ============================================================== */

public void OnConfigsExecuted()
{
	if (!g_hDB)
	{
		if (SQL_CheckConfig(HX_DATABASE_CFG))
		{
			Database.Connect(SQL_Callback_Connect, HX_DATABASE_CFG);
		}
	}
}

Action Timer_SQL_ReConnect(Handle timer)
{
	OnConfigsExecuted();
}

public void SQL_Callback_Connect (Database db, const char[] error, any data)
{
	const int MAX_ATTEMPT = 20;
	static int iAttempt;
	g_hDB = db;
	if (!db)
	{
		++iAttempt;
		LogError("Attempt #%i. %s", iAttempt, error);
		
		if (iAttempt < MAX_ATTEMPT)
		{
			CreateTimer(3.0, Timer_SQL_ReConnect, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {
			iAttempt = 0;
		}
		return;
	}
	SQL_OnConnected();
}

void SQL_OnConnected()
{
	//ShiftWeekMonthPoints();
	
	if (g_bLateload)
	{
		for (int i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				HxSQL_RegisterClient(i);
			}
		}
	}
}

public void OnMapStart()
{
	ShiftWeekMonthPoints();
}

void ShiftWeekMonthPoints()
{
	if (!g_hDB)
		return;
	RequestLastUpdateTime();
}

public void	SQL_OnUpdateTimeRequested(int iWeekUpdate, int iMonthUpdate)
{
	int iUnixFirstWeekDay = GetFirstWeekDay();
	int iUnixFirstMonthDay = GetFirstMonthDay();
	
	if (iWeekUpdate < iUnixFirstWeekDay)
	{
		FormatEx(g_sQuery1, sizeof(g_sQuery1),
			"UPDATE `"...HX_TABLE..."` SET \
			Time1 = %i \
			WHERE `Steamid` = '%s'"
			, GetTime()
			, HX_SERVICE_STEAM);
		
		FormatEx(g_sQuery2, sizeof(g_sQuery2),
			"UPDATE `"...HX_TABLE..."` SET \
			Pt_lweek = Pt_week, \
			Pt_week = 0");
			
		Transaction tx1 = new Transaction();
		tx1.AddQuery(g_sQuery1);
		tx1.AddQuery(g_sQuery2);
		
		#if defined _vip_core_included
		if (g_ConVarAwardTopWeekVIP.IntValue != 0)
		{
			FormatEx(g_sQuery3, sizeof(g_sQuery3),
				"UPDATE `"...HX_TABLE..."` SET \
				VipQueue = VipQueue + %i \
				ORDER BY `Pt_lweek` DESC LIMIT %i", g_ConVarAwardTopWeekVIP.IntValue, g_ConVarLimitTopWeekVIP.IntValue);
			tx1.AddQuery(g_sQuery3);
		}
		#endif
		
		g_hDB.Execute(tx1, SQL_Tx_Success, SQL_Tx_Failure);
	}
	
	if (iMonthUpdate < iUnixFirstMonthDay)
	{
		FormatEx(g_sQuery1, sizeof(g_sQuery1),
			"UPDATE `"...HX_TABLE..."` SET \
			Time2 = %i \
			WHERE `Steamid` = '%s'"
			, GetTime()
			, HX_SERVICE_STEAM);
	
		FormatEx(g_sQuery2, sizeof(g_sQuery2),
			"UPDATE `"...HX_TABLE..."` SET \
			Pt_lmonth = Pt_month, \
			Pt_month = 0");
		
		Transaction tx2 = new Transaction();
		tx2.AddQuery(g_sQuery1);
		tx2.AddQuery(g_sQuery2);
		
		#if defined _vip_core_included
		if (g_ConVarAwardTopMonthVIP.IntValue != 0)
		{
			FormatEx(g_sQuery3, sizeof(g_sQuery3),
				"UPDATE `"...HX_TABLE..."` SET \
				VipQueue = VipQueue + %i \
				ORDER BY `Pt_lmonth` DESC LIMIT %i", g_ConVarAwardTopMonthVIP.IntValue, g_ConVarLimitTopMonthVIP.IntValue);
			tx2.AddQuery(g_sQuery3);
		}
		#endif
		
		g_hDB.Execute(tx2, SQL_Tx_Success, SQL_Tx_Failure);
	}
}

public void OnClientPostAdminCheck(int client)
{
	if (!IsFakeClient(client))
	{
		HxClean(client);
		g_bInDisconnect[client] = false;
		CreateTimer(0.5, HxTimer_ClientPost, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void OnClientAuthorized(int client, const char[] auth)
{
	// TODO: validate "auth" arg. instead of GetClientAuthId()
	// https://sm.alliedmods.net/new-api/clients/OnClientAuthorized
	
	if (client)
	{
		CacheSteamID(client);
	}
}

public void OnClientDisconnect_Post(int client)
{
	g_sSteamId[client][0] = '\0';
	HxClean(client);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	
	if (client && IsClientInGame(client) && !IsFakeClient(client) && !g_bInDisconnect[client] )
	{
		g_bInDisconnect[client] = true;
		
		SQL_Save(client);
	}
}

/* This doesn't work because clients are already not in game
public void OnMapEnd()
{
	SQL_SaveAll(true);
}
*/

public void Event_MapTransition(Event event, const char[] name, bool dontBroadcast)
{
	g_bMapTransition = true;
	SQL_SaveAll(true);
}

public void OnClientDisconnect(int client)
{
	if ( !g_bMapTransition && !g_bInDisconnect[client] )
	{
		g_bInDisconnect[client] = true;
	
		if (client && IsClientInGame(client) && !IsFakeClient(client))
		{
			SQL_Save(client);
		}
	}
}

public void Event_SQL_Save(Event event, const char[] name, bool dontBroadcast)
{
	SQL_SaveAll(true);
}

public Action Listen_Keyboard(int client, const char[] sCommand, int iArg)
{
	if (g_iReal[client][HX_POINTS] > g_ConVarIdleRank.IntValue || IsClientRootAdmin(client))
	{
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public Action Listen_Callvote(int client, const char[] sCommand, int iArg)
{
	if (g_iReal[client][HX_POINTS] > g_ConVarVoteRank.IntValue || IsClientRootAdmin(client))
	{
		return Plugin_Continue;
	}
	return Plugin_Stop;
}

public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_iRoundStart = 1;
	g_bMapTransition = false;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_iTemp[i][HX_POINTS] = 0;
	}
	
	if (g_ConVarUseColors.IntValue != 0)
	{
		CreateTimer(17.0, HxTimer_R18, _, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(40.0, HxTimer_R18, _, TIMER_FLAG_NO_MAPCHANGE);
		CreateTimer(85.0, HxTimer_R18, _, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iPenaltyFF == 0)
		return;

	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if (iVictim && !IsFakeClient(iVictim))
	{
		if (iAttacker && !IsFakeClient(iAttacker))
		{
			int iDmg = event.GetInt("dmg_health");
			float iDmgRest = float(iDmg % 10);
			
			int iPenalty = iDmg / 10 * g_iPenaltyFF;
			g_fPenaltyBonus[iAttacker] += iDmgRest / 10.0 * g_iPenaltyFF;
			
			g_iTemp[iAttacker][HX_PENALTY] += iPenalty;
			g_iTemp[iAttacker][HX_POINTS] += iPenalty;
			PrintPoints(iAttacker, "%t", "PenaltyFF-", iPenalty);
		}
	}
}

public void Event_PlayerIncap(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iPenaltyIncap == 0)
		return;

	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	
	if (iVictim && !IsFakeClient(iVictim)) // Real survivor is incapacitated
	{
		g_iTemp[iVictim][HX_PENALTY] += g_iPenaltyIncap;
		g_iTemp[iVictim][HX_POINTS] += g_iPenaltyIncap;
		PrintPoints(iVictim, "%t", "PenaltyIncap-", g_iPenaltyIncap);
	}
}

public Action Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iVictim = GetClientOfUserId(event.GetInt("userid"));	/* User ID который умер */
	
	if (iVictim && !IsFakeClient(iVictim) && g_iPenaltyDeath) // Real survivor is killed
	{
		g_iTemp[iVictim][HX_PENALTY] += g_iPenaltyDeath;
		g_iTemp[iVictim][HX_POINTS] += g_iPenaltyDeath;
		PrintPoints(iVictim, "%t", "PenaltyDeath-", g_iPenaltyDeath);
		return Plugin_Continue;
	}
	
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));	/* User ID который убил */
	
	if (iAttacker && iAttacker != iVictim)
	{
		if (!IsFakeClient(iAttacker)) // Attacker is not a bot
		{
			g_sBuf3[0] = '\0';
			event.GetString("victimname", g_sBuf3, sizeof(g_sBuf3));
			
			#if DEBUG
			PrintToChat(iAttacker, "Victim: %s", g_sBuf3);
			#endif
			
			if (g_sBuf3[0] == 'I' && g_iPointsInfected)
			{		/* Common Infected */
				if ((g_iTemp[iAttacker][HX_INFECTED] += 1) % g_iCommonsToKill == 0 && g_iCommonsToKill)
				{
					g_iTemp[iAttacker][HX_POINTS] += g_iPointsInfected;
					PrintPoints(iAttacker, "%t", "Infected+", g_iCommonsToKill, g_iPointsInfected);
				}
				return Plugin_Continue;
			}
			
			if (g_sBuf3[0] == 'B' && g_iPointsBoomer)
			{		/* Boomer */
				g_iTemp[iAttacker][HX_BOOMER] += 1;
				g_iTemp[iAttacker][HX_POINTS] += g_iPointsBoomer;
				PrintPoints(iAttacker, "%t", "Boomer+", g_iPointsBoomer);
				return Plugin_Continue;
			}
			
			if (g_sBuf3[0] == 'S')
			{
				if (g_sBuf3[1] == 'm' && g_iPointsSmoker)
				{		/* Smoker */
					g_iTemp[iAttacker][HX_SMOKER] += 1;
					g_iTemp[iAttacker][HX_POINTS] += g_iPointsSmoker;
					PrintPoints(iAttacker, "%t", "Smoker+", g_iPointsSmoker);
					return Plugin_Continue;
				}
				if (g_sBuf3[1] == 'p' && g_iPointsSpitter)
				{		/* Spitter */
					g_iTemp[iAttacker][HX_SPITTER] += 1;
					g_iTemp[iAttacker][HX_POINTS] += g_iPointsSpitter;
					PrintPoints(iAttacker, "%t", "Spitter+", g_iPointsSpitter);
					return Plugin_Continue;
				}
			}
			
			if (g_sBuf3[0] == 'H' && g_iPointsHunter)
			{		/* Hunter */
				g_iTemp[iAttacker][HX_HUNTER] += 1;
				g_iTemp[iAttacker][HX_POINTS] += g_iPointsHunter;
				PrintPoints(iAttacker, "%t", "Hunter+", g_iPointsHunter);
				return Plugin_Continue;
			}

			if (g_bL4D2)
			{
				if (g_sBuf3[0] == 'J' && g_iPointsJockey)
				{		/* Jockey */
					g_iTemp[iAttacker][HX_JOCKEY] += 1;
					g_iTemp[iAttacker][HX_POINTS] += g_iPointsJockey;
					PrintPoints(iAttacker, "%t", "Jockey+", g_iPointsJockey);
					return Plugin_Continue;
				}
			
				if (g_sBuf3[0] == 'C' && g_iPointsCharger)
				{		/* Charger */
					g_iTemp[iAttacker][HX_CHARGER] += 1;
					g_iTemp[iAttacker][HX_POINTS] += g_iPointsCharger;
					PrintPoints(iAttacker, "%t", "Charger+", g_iPointsCharger);
					return Plugin_Continue;
				}
			}

			if (g_sBuf3[0] == 'T' && g_iPointsTank)
			{		/* Tank */
				g_iTemp[iAttacker][HX_TANK] += 1;
				g_iTemp[iAttacker][HX_POINTS] += g_iPointsTank;
				PrintPoints(iAttacker, "%t", "Tank+", g_iPointsTank);
				return Plugin_Continue;
			}

			if (g_sBuf3[0] == 'W' && g_iPointsWitch)
			{		/* Witch */
				g_iTemp[iAttacker][HX_WITCH] += 1;
				g_iTemp[iAttacker][HX_POINTS] += g_iPointsWitch;
				PrintPoints(iAttacker, "%t", "Witch+", g_iPointsWitch);
			}
		}
	}
	return Plugin_Continue;
}

/* ==============================================================
					T I M E R S
// ============================================================== */

public Action HxTimer_R18(Handle timer)
{
	int iPoints = 0;

	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				if (IsPlayerAlive(i))
				{
					iPoints = g_iReal[i][HX_POINTS];
					HxColorC(i, iPoints);
				}
			}
		}
	}
	return Plugin_Stop;
}

public Action HxTimer_Connected(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);

	if (client && IsClientInGame(client))
	{
		CMD_rank(client, 0);
	}
}

public Action HxTimer_ClientPost(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if (client && IsClientInGame(client))
	{
		HxSQL_RegisterClient(client);
	}
}

public Action HxTimer_Infinite18(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) != 1)
			{
				if ( (g_iTemp[i][HX_TIME] += 1) % g_iTimeToPlay == 0 && g_iTimeToPlay && g_iPointsTime)
				{
					g_iTemp[i][HX_POINTS] += g_iPointsTime;
					PrintPoints(i, "%t", "min. in game+", g_iTimeToPlay, g_iPointsTime);
				}
			}
		}
		else
		{
			g_iTemp[i][HX_TIME] = 0;
		}
	}
}

/* ==============================================================
						S Q L
// ============================================================== */

public Action CMD_Upgrade(int client, int args)
{
	if (!g_hDB) {
		LogError("sm_hx_upgrade failed! No connection to MySQL.");
		return Plugin_Handled;
	}
	
	InsertColumn("Pt_month", 	"int(11) NOT NULL DEFAULT '0' AFTER Points");
	InsertColumn("Pt_week", 	"int(11) NOT NULL DEFAULT '0' AFTER Pt_month");
	InsertColumn("Pt_lmonth", 	"int(11) NOT NULL DEFAULT '0' AFTER Pt_week");
	InsertColumn("Pt_lweek", 	"int(11) NOT NULL DEFAULT '0' AFTER Pt_lmonth");
	InsertColumn("VipQueue", 	"int(11) NOT NULL DEFAULT '0' AFTER Time2");
	InsertColumn("Penalty", 	"int(11) NOT NULL DEFAULT '0' AFTER VipQueue");
	InsertColumn("Hide", 		"SMALLINT NOT NULL DEFAULT '0' AFTER Penalty");
	
	PrintToChat(client, "Upgrade command is processed.");
	return Plugin_Handled;
}

void InsertColumn(char[] sColumn, char[] sCmd)
{
	DataPack dp = new DataPack();
	char sPack[128];
	FormatEx(sPack, sizeof(sPack), "ADD COLUMN `%s` %s", sColumn, sCmd);

	dp.WriteString(sPack);

	FormatEx(g_sQuery1, sizeof(g_sQuery1)
	 , "SELECT COUNT(*) \
		FROM INFORMATION_SCHEMA.COLUMNS \
		WHERE table_name = '"...HX_TABLE..."' \
		AND column_name = '%s'", sColumn);
		//AND table_schema = 'dragokas_db'
	
	g_hDB.Query(SQL_Callback_InsertColumn, g_sQuery1, dp);
}

public void SQL_Callback_InsertColumn (Database db, DBResultSet hQuery, const char[] error, any data)
{
	char sInsert[128];
	DataPack dp = view_as<DataPack>(data);
	dp.Reset();
	dp.ReadString(sInsert, sizeof(sInsert));
	delete dp;
	
	if (!db || !hQuery) { LogError(error); return; }
	if (hQuery.FetchRow())
	{
		if (hQuery.FetchInt(0) == 0)
		{
			FormatEx(g_sQuery1, sizeof(g_sQuery1), "ALTER TABLE `"...HX_TABLE..."` %s", sInsert);
			g_hDB.Query(SQL_Callback, g_sQuery1, dp);
		}
	}
}

public Action CMD_Backup( int client, int args)
{
	strcopy(g_sQuery1, sizeof(g_sQuery1), "DROP TABLE IF EXISTS `"...HX_TABLE_BACKUP..."`");
	strcopy(g_sQuery2, sizeof(g_sQuery2), "CREATE TABLE IF NOT EXISTS `"...HX_TABLE_BACKUP..."` LIKE `"...HX_TABLE..."`");
	strcopy(g_sQuery3, sizeof(g_sQuery3), "INSERT `"...HX_TABLE_BACKUP..."` SELECT * FROM `"...HX_TABLE..."`");

	Transaction tx = new Transaction();
	tx.AddQuery(g_sQuery1);
	tx.AddQuery(g_sQuery2);
	tx.AddQuery(g_sQuery3);
	g_hDB.Execute(tx, SQL_Tx_Success, SQL_Tx_Failure);
	PrintToChat(client, "Backup command is executed.");
	return Plugin_Handled;
}

public Action CMD_Revert( int client, int args)
{
	strcopy(g_sQuery1, sizeof(g_sQuery1), "DROP TABLE IF EXISTS `"...HX_TABLE..."`");
	strcopy(g_sQuery2, sizeof(g_sQuery2), "CREATE TABLE IF NOT EXISTS `"...HX_TABLE..."` LIKE `"...HX_TABLE_BACKUP..."`");
	strcopy(g_sQuery3, sizeof(g_sQuery3), "INSERT `"...HX_TABLE..."` SELECT * FROM `"...HX_TABLE_BACKUP..."`");
	
	Transaction tx = new Transaction();
	tx.AddQuery(g_sQuery1);
	tx.AddQuery(g_sQuery2);
	tx.AddQuery(g_sQuery3);
	g_hDB.Execute(tx, SQL_Tx_Success, SQL_Tx_Failure);
	PrintToChat(client, "Revert command is executed.");
	return Plugin_Handled;
}

void RequestLastUpdateTime()
{
	// week		(column `Time1`)
	// month	(column `Time2`)
	
	FormatEx(g_sQuery1, sizeof(g_sQuery1)
	 , "SELECT SQL_NO_CACHE \
		Time1, \
		Time2 \
		FROM `"...HX_TABLE..."` WHERE `Steamid` = '%s'", HX_SERVICE_STEAM);
	
	g_hDB.Query(SQL_Callback_RequestUpdateTime, g_sQuery1);
}

public void SQL_Callback_RequestUpdateTime (Database db, DBResultSet hQuery, const char[] error, any data)
{
	if (!db || !hQuery) { LogError(error); return; }
	if (!hQuery.FetchRow())
	{
		FormatEx(g_sQuery1, sizeof(g_sQuery1), "INSERT INTO `"...HX_TABLE..."` (`Name`,`Time1`,`Time2`,`Steamid`) VALUES ('',%i,%i,'%s')", GetTime(), GetTime(), HX_SERVICE_STEAM);
		db.Query(SQL_Callback, g_sQuery1);
	}
	else {
		int iWeekUpdate = hQuery.FetchInt(0);
		int iMonthUpdate = hQuery.FetchInt(1);
		SQL_OnUpdateTimeRequested(iWeekUpdate, iMonthUpdate);
	}
}

public void HxSQL_RegisterClient(int client)
{
	if (!g_hDB)
		return;
	
	if ( !CacheSteamID(client) )
		return;
	
	FormatEx(g_sQuery1, sizeof(g_sQuery1)
	 , "SELECT \
		Steamid, \
		Points, \
		Time1, \
		Boomer, \
		Charger, \
		Hunter, \
		Infected, \
		Jockey, \
		Smoker, \
		Spitter, \
		Tank, \
		Witch, \
		Pt_month, \
		Pt_week, \
		Pt_lmonth, \
		Pt_lweek, \
		VipQueue, \
		Penalty, \
		Hide \
		FROM `"...HX_TABLE..."` WHERE `Steamid` = '%s'", g_sSteamId[client]);
	
	g_hDB.Query(SQL_Callback_RegisterClient, g_sQuery1, client == 0 ? 0 : GetClientUserId(client));
}

public void SQL_Callback_RegisterClient (Database db, DBResultSet hQuery, const char[] error, any data)
{
	if (!hQuery)
	{
		if (StrContains(error, "Table") != -1 && StrContains(error, "doesn't exist") != -1)
		{
			PrintToChatAll(error);
			HxSQL_CreateTable();
			return;
		}
	}
	if (!db || !hQuery) { LogError(error); return; }
	int client;
	if (data != 0)
	{
		client = GetClientOfUserId(data);
		if (!client || !IsClientInGame(client)) return;
	}
	
	if (!hQuery.FetchRow())
	{
		if (client == 0) // for service requested SteamId
			return;

		static char sName[32];
		GetClientName(client, sName, sizeof(sName));
		HxProtect(sName, sizeof(sName));
		
		FormatEx(g_sQuery1, sizeof(g_sQuery1),
			"INSERT INTO `"...HX_TABLE..."` SET \
			Name = '%s', \
			Time2 = %d, \
			Steamid = '%s'"
			, sName
			, GetTime()
			, g_sSteamId[client]);
		
		db.Query(SQL_Callback, g_sQuery1, data);
	}
	else
	{
		g_iReal[client][HX_POINTS]   = hQuery.FetchInt(1);
		g_iReal[client][HX_TIME]     = hQuery.FetchInt(2);
		g_iReal[client][HX_BOOMER]   = hQuery.FetchInt(3);
		g_iReal[client][HX_CHARGER]  = hQuery.FetchInt(4);
		g_iReal[client][HX_HUNTER]   = hQuery.FetchInt(5);
		g_iReal[client][HX_INFECTED] = hQuery.FetchInt(6);
		g_iReal[client][HX_JOCKEY]   = hQuery.FetchInt(7);
		g_iReal[client][HX_SMOKER]   = hQuery.FetchInt(8);
		g_iReal[client][HX_SPITTER]  = hQuery.FetchInt(9);
		g_iReal[client][HX_TANK]     = hQuery.FetchInt(10);
		g_iReal[client][HX_WITCH]    = hQuery.FetchInt(11);
		g_iReal[client][HX_POINTS_MONTH]   = hQuery.FetchInt(12);
		g_iReal[client][HX_POINTS_WEEK]    = hQuery.FetchInt(13);
		g_iReal[client][HX_POINTS_LAST_MONTH]   = hQuery.FetchInt(14);
		g_iReal[client][HX_POINTS_LAST_WEEK]    = hQuery.FetchInt(15);
		g_iReal[client][HX_VIP_QUEUE]    		= hQuery.FetchInt(16);
		g_iReal[client][HX_PENALTY]    			= hQuery.FetchInt(17);
		g_iReal[client][HX_HIDE]    			= hQuery.FetchInt(18);
		
		UpdateHiddenFlag(client);
		
		FormatEx(g_sQuery1, sizeof(g_sQuery1), 
					"SELECT COUNT(*)+1 FROM `"...HX_TABLE..."` WHERE \
					Points > ( \
					SELECT Points FROM `"...HX_TABLE..."` \
					WHERE `Steamid` = '%s')"
					, g_sSteamId[client]);
		
		db.Query(SQL_CallbackPlace, g_sQuery1, data);
		
		if (client == 0) // for service requested SteamId
		{
			return;
		}
		
		if (g_ConVarShowRankRoundStart.BoolValue)
		{
			CreateTimer(g_ConVarShowRankDelay.FloatValue, HxTimer_Connected, data, TIMER_FLAG_NO_MAPCHANGE);
		}
		
		#if defined _vip_core_included
		int iVipDays = g_iReal[client][HX_VIP_QUEUE];
		
		if (iVipDays != 0)
		{
			DataPack dp = new DataPack();
			dp.WriteCell(GetClientUserId(client));
			dp.WriteCell(iVipDays);
			CreateTimer(5.0, Timer_GiveAwardVIP, dp, TIMER_FLAG_NO_MAPCHANGE | TIMER_DATA_HNDL_CLOSE);
		}
		#endif
	}
}

Action Timer_GiveAwardVIP(Handle timer, DataPack dp)
{
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int days = dp.ReadCell();
	
	if (client && IsClientInGame(client))
	{
		if (GiveVIP(client, days))
		{
			FormatEx(g_sQuery2, sizeof(g_sQuery2), "UPDATE `"...HX_TABLE..."` SET VipQueue = 0 WHERE `Steamid` = '%s'", g_sSteamId[client]);
			g_hDB.Query(SQL_Callback, g_sQuery2);
		}
	}
}

public void SQL_CallbackPlace (Database db, DBResultSet hQuery, const char[] error, any data)
{
	if (!db || !hQuery) { LogError(error); return; }
	int client = GetClientOfUserId(data); //if (!client || !IsClientInGame(client)) return;
	
	if (hQuery.FetchRow())
	{
		g_iReal[client][HX_PLACE]    = hQuery.FetchInt(0);
	}
	
	if (client == 0) // for service requested SteamId
	{
		OnReqClientRegistered();
	}
}

public void SQL_Tx_Success (Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
}
public void SQL_Tx_Failure (Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogError(error);
}

public void SQL_Callback (Database db, DBResultSet hQuery, const char[] error, any data)
{
	if (!db || !hQuery) { LogError(error); return; }
}

void UpdateHiddenFlag(int client)
{
	int iFlagBits = GetUserFlagBits(client);
	int iHidden = iFlagBits & g_iHiddenFlagBits ? 1 : 0; // should be hidden?
	
	if (iHidden ^ g_iReal[client][HX_HIDE]) // db flag is different => populate it
	{
		FormatEx(g_sQuery2, sizeof(g_sQuery2)
		 , "UPDATE `"...HX_TABLE..."` SET \
			Hide = '%d' \
			WHERE `Steamid` = '%s'"
			, iHidden
			, g_sSteamId[client]);
		
		g_hDB.Query(SQL_Callback, g_sQuery2);
	}
}

void SQL_Save(int client)
{
	static char sName[32];
	
	if (!g_hDB)
		return;
	
	GetClientName(client, sName, sizeof(sName));
	HxProtect(sName, sizeof(sName));
	
	if ( !CacheSteamID(client) )
		return;
	
	g_iTemp[client][HX_PENALTY] += RoundToCeil(g_fPenaltyBonus[client]);
	g_iTemp[client][HX_POINTS] += RoundToCeil(g_fPenaltyBonus[client]);
	g_fPenaltyBonus[client] = 0.0;
	
	FormatEx(g_sQuery2, sizeof(g_sQuery2)
	 , "UPDATE `"...HX_TABLE..."` SET \
		Name = '%s', \
		Points = Points + %d, \
		Pt_month = Pt_month + %d, \
		Pt_week = Pt_week + %d, \
		Time1 = Time1 + %d, \
		Time2 = %d, \
		Penalty = Penalty + %d, \
		Boomer = Boomer + %d, \
		Charger = Charger + %d, \
		Hunter = Hunter + %d, \
		Infected = Infected + %d, \
		Jockey = Jockey + %d, \
		Smoker = Smoker + %d, \
		Spitter = Spitter + %d, \
		Tank = Tank + %d, \
		Witch = Witch + %d \
		WHERE `Steamid` = '%s'"

		, sName
		, g_iTemp[client][HX_POINTS]
		, g_iTemp[client][HX_POINTS]
		, g_iTemp[client][HX_POINTS]
		, g_iTemp[client][HX_TIME]
		, GetTime()
		, g_iTemp[client][HX_PENALTY]
		, g_iTemp[client][HX_BOOMER]
		, g_iTemp[client][HX_CHARGER]
		, g_iTemp[client][HX_HUNTER]
		, g_iTemp[client][HX_INFECTED]
		, g_iTemp[client][HX_JOCKEY]
		, g_iTemp[client][HX_SMOKER]
		, g_iTemp[client][HX_SPITTER]
		, g_iTemp[client][HX_TANK]
		, g_iTemp[client][HX_WITCH]
		, g_sSteamId[client]);

	g_hDB.Query(SQL_Callback, g_sQuery2);

	g_iReal[client][HX_POINTS] 			+= g_iTemp[client][HX_POINTS];
	g_iReal[client][HX_POINTS_MONTH] 	+= g_iTemp[client][HX_POINTS];
	g_iReal[client][HX_POINTS_WEEK] 	+= g_iTemp[client][HX_POINTS];
	g_iReal[client][HX_TIME]     		+= g_iTemp[client][HX_TIME];
	g_iReal[client][HX_BOOMER]			+= g_iTemp[client][HX_BOOMER];
	g_iReal[client][HX_CHARGER]			+= g_iTemp[client][HX_CHARGER];
	g_iReal[client][HX_HUNTER] 			+= g_iTemp[client][HX_HUNTER];
	g_iReal[client][HX_INFECTED]		+= g_iTemp[client][HX_INFECTED];
	g_iReal[client][HX_JOCKEY]  		+= g_iTemp[client][HX_JOCKEY];
	g_iReal[client][HX_SMOKER]  		+= g_iTemp[client][HX_SMOKER];
	g_iReal[client][HX_SPITTER]  		+= g_iTemp[client][HX_SPITTER];
	g_iReal[client][HX_TANK]   			+= g_iTemp[client][HX_TANK];
	g_iReal[client][HX_WITCH]  			+= g_iTemp[client][HX_WITCH];
	g_iReal[client][HX_PENALTY]  		+= g_iTemp[client][HX_PENALTY];
	
	HxClean(client, true);
}

public Action CMD_sqlcreate(int client, int args)
{
	HxSQL_CreateTable(true);
	return Plugin_Handled;
}

void HxSQL_CreateTable(bool bRemoveOld = false)
{
	if (g_hDB)
	{
		if (bRemoveOld)
		{
			g_hDB.Query(SQL_Callback, HX_REMOVE_TABLE);
		}
		g_hDB.Query(SQL_Callback, HX_CREATE_TABLE);
		
		PrintToChatAll("\x01[HXStats] Database table is created. \x04Please, restart the map.");
	}
}

/* ========================================================================
							COMMANDS & MENU
======================================================================== */

public Action CMD_ShowPoints(int client, int args)
{
	g_iRequestorId = client;
	g_iReqAction = ACTION_SHOWPOINTS;
	
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_hx_showpoints <#userid|name|steamid>");
		return Plugin_Handled;
	}
	
	bool tn_is_ml;
	char arg[MAX_NAME_LENGTH], target_name[MAX_TARGET_LENGTH];
	int target_list[MAXPLAYERS], target_count, target_client;
	
	GetCmdArg(1, arg, sizeof(arg));
	
	if (StrContains(arg, "STEAM_") == 0)
	{
		strcopy(g_sReqSteam, sizeof(g_sReqSteam), arg);
	}
	else {
		target_count = ProcessTargetString(arg,	client,	target_list, sizeof(target_list), COMMAND_FILTER_NO_BOTS | COMMAND_FILTER_NO_MULTI, target_name, sizeof(target_name), tn_is_ml);
		if (target_count != 1)
		{
			ReplyToTargetError(client, target_count);
			return Plugin_Handled;
		}
		else {
			target_client = target_list[0];
		}
		
		if ( !GetClientAuthId(target_client, AuthId_Steam2, g_sReqSteam, sizeof(g_sReqSteam)) )
		{
			PrintToChat(client, "Can't obtain SteamId of user: %N", target_client);
			return Plugin_Handled;
		}
	}
	HxSQL_RegisterClient(0);
	return Plugin_Handled;
}

void OnReqClientRegistered()
{
	if (g_iReqAction == ACTION_SHOWPOINTS)
	{
		ShowRank(0);
	}
	else if (g_iReqAction == ACTION_MOVEPOINTS)
	{
		SQL_MovePoints();
	}
}

void SQL_MovePoints()
{
	FormatEx(g_sQuery2, sizeof(g_sQuery2)
	 , "UPDATE `"...HX_TABLE..."` SET \
		Points = Points + %d, \
		Pt_month = Pt_month + %d, \
		Pt_week = Pt_week + %d, \
		Pt_lmonth = %d, \
		Pt_lweek = %d, \
		Time1 = Time1 + %d, \
		VipQueue = VipQueue + %d, \
		Penalty = Penalty + %d, \
		Hide = %d, \
		Boomer = Boomer + %d, \
		Charger = Charger + %d, \
		Hunter = Hunter + %d, \
		Infected = Infected + %d, \
		Jockey = Jockey + %d, \
		Smoker = Smoker + %d, \
		Spitter = Spitter + %d, \
		Tank = Tank + %d, \
		Witch = Witch + %d \
		WHERE `Steamid` = '%s'"

		, g_iReal[0][HX_POINTS]
		, g_iReal[0][HX_POINTS_MONTH]
		, g_iReal[0][HX_POINTS_WEEK]
		, g_iReal[0][HX_POINTS_LAST_MONTH]
		, g_iReal[0][HX_POINTS_LAST_WEEK]
		, g_iReal[0][HX_TIME]
		, g_iReal[0][HX_VIP_QUEUE]
		, g_iReal[0][HX_PENALTY]
		, g_iReal[0][HX_HIDE]
		, g_iReal[0][HX_BOOMER]
		, g_iReal[0][HX_CHARGER]
		, g_iReal[0][HX_HUNTER]
		, g_iReal[0][HX_INFECTED]
		, g_iReal[0][HX_JOCKEY]
		, g_iReal[0][HX_SMOKER]
		, g_iReal[0][HX_SPITTER]
		, g_iReal[0][HX_TANK]
		, g_iReal[0][HX_WITCH]
		, g_sDestSteam);
	
	g_hDB.Query(SQL_Callback, g_sQuery2);
	
	PrintToChat(g_iRequestorId, "Moving points is processed.");
}

public Action CMD_DelOld(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_hx_delold <days>");
		return Plugin_Handled;
	}
	
	char s[8];
	GetCmdArg(1, s, sizeof(s));
	int days = StringToInt(s);
	
	int iUnix = GetTime();
	iUnix -= days * 60 * 60 * 24;
	
	FormatEx(g_sQuery2, sizeof(g_sQuery2)
	 , "DELETE FROM `"...HX_TABLE..."` \
		WHERE `Time2` < %i AND NOT `SteamId` = '%s'"
		, iUnix
		, HX_SERVICE_STEAM);
	
	g_hDB.Query(SQL_CallbackDelOld, g_sQuery2, GetClientUserId(client));
	return Plugin_Handled;
}

public void SQL_CallbackDelOld (Database db, DBResultSet hQuery, const char[] error, int data)
{
	if (!db || !hQuery) { LogError(error); return; }
	int client = GetClientOfUserId(data);
	if (!client || !IsClientInGame(client)) return;

	if (hQuery)
	{
		PrintToChat(client, "Total players deleted: %i", hQuery.AffectedRows);
	}
}

public Action CMD_DelPlayer(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "Usage: sm_hx_delplayer <steamid>");
		return Plugin_Handled;
	}
	
	char sSteam[64];
	GetCmdArg(1, sSteam, sizeof(sSteam));
	
	if (StrContains(sSteam, "STEAM_") != 0)
	{
		ReplyToCommand(client, "Usage: sm_hx_delplayer <steamid>");
		return Plugin_Handled;
	}
	
	FormatEx(g_sQuery2, sizeof(g_sQuery2)
	 , "DELETE FROM `"...HX_TABLE..."` \
		WHERE `Steamid` = '%s'"
		, sSteam);
	
	g_hDB.Query(SQL_Callback, g_sQuery2);
	
	PrintToChat(client, "Delete player: %s is processed.", sSteam);
	return Plugin_Handled;
}

public Action CMD_MovePoints(int client, int args)
{
	g_iRequestorId = client;
	g_iReqAction = ACTION_MOVEPOINTS;
	
	if (args < 2)
	{
		ReplyToCommand(client, "Usage: sm_hx_movepoints <STEAM_1> <STEAM_2> where 1 - source, 2 - destination");
		return Plugin_Handled;
	}
	
	GetCmdArg(1, g_sReqSteam, sizeof(g_sReqSteam));
	GetCmdArg(2, g_sDestSteam, sizeof(g_sDestSteam));
	
	HxSQL_RegisterClient(0);
	return Plugin_Handled;
}

public Action CMD_stat(int client, int args)
{
	Menu menu = new Menu(MenuHandler_MenuStat, MENU_ACTIONS_DEFAULT);
	menu.SetTitle(Translate(client, "%t", "Statistics", g_sMenuName));
	menu.AddItem("1", Translate(client, "%t", "Rank"));
	menu.AddItem("2", Translate(client, "%t", "Top"));
	menu.AddItem("3", Translate(client, "%t", "VIP: Top of week"));
	menu.AddItem("4", Translate(client, "%t", "VIP: Top of month"));
	menu.AddItem("5", Translate(client, "%t", "VIP: Top of last week"));
	menu.AddItem("6", Translate(client, "%t", "VIP: Top of last month"));
	menu.AddItem("7", Translate(client, "%t", "Description of points"));
	if (g_bBaseMenuAvail)
	{
		menu.ExitBackButton = true;
	}
	menu.Display(client, MENU_TIME_FOREVER);
	return Plugin_Handled;
}

public int MenuHandler_MenuStat(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack)
				FakeClientCommand(param1, g_sBaseMenu);
		
		case MenuAction_Select:
		{
			int client = param1;
			int ItemIndex = param2;
			
			static char nAction[4];
			menu.GetItem(ItemIndex, nAction, sizeof(nAction));
			
			switch(StringToInt(nAction)) {
				case 1: { CMD_rank(client, 0); }
				case 2: { ShowTop(client, PERIOD_TOTAL); }
				case 3: { ShowTop(client, PERIOD_WEEK); }
				case 4: { ShowTop(client, PERIOD_MONTH); }
				case 5: { ShowTop(client, PERIOD_LAST_WEEK); }
				case 6: { ShowTop(client, PERIOD_LAST_MONTH); }
				case 7: { ShowPointsAbout(client); }
			}
		}
	}
}

void ShowPointsAbout(int client)
{
	Panel hPanel = new Panel();
	hPanel.SetTitle(Translate(client, "%t", "Scoring:"));
	
	if (g_iPointsBoomer != 0)
		hPanel.DrawText(Translate(client, "%t", "1 Boomer - {} point(s)", g_iPointsBoomer));
	if (g_iPointsHunter != 0)
		hPanel.DrawText(Translate(client, "%t", "1 Hunter - {} point(s)", g_iPointsHunter));
	if (g_iPointsSmoker != 0)
		hPanel.DrawText(Translate(client, "%t", "1 Smoker - {} point(s)", g_iPointsSmoker));
		
	if (g_bL4D2)
	{
		if (g_iPointsCharger != 0)
			hPanel.DrawText(Translate(client, "%t", "1 Charger - {} point(s)", g_iPointsCharger));
		if (g_iPointsJockey != 0)
			hPanel.DrawText(Translate(client, "%t", "1 Jockey - {} point(s)", g_iPointsJockey));
		if (g_iPointsSpitter != 0)
			hPanel.DrawText(Translate(client, "%t", "1 Spitter - {} point(s)", g_iPointsSpitter));
	}
	if (g_iPointsTank != 0)
		hPanel.DrawText(Translate(client, "%t", "1 Tank - {} point(s)", g_iPointsTank));
	if (g_iPointsWitch != 0)
		hPanel.DrawText(Translate(client, "%t", "1 Witch - {} point(s)", g_iPointsWitch));
	
	if (!g_bL4D2)
	{
		DrawPointsAbout2(client, hPanel);
	}
	hPanel.DrawItem(Translate(client, "%t", "Close"));
	hPanel.DrawItem(Translate(client, "%t", "Back"));
	
	if (g_bL4D2)
	{
		hPanel.DrawItem(Translate(client, "%t", "Next")); // Second part of list
	}
	hPanel.Send(client, AboutPanelHandler, 20);
	delete hPanel;
}

void DrawPointsAbout2(int client, Panel hPanel)
{
	if (g_iPointsInfected != 0)
		hPanel.DrawText(Translate(client, "%t", "{} zombies - {} point(s)", g_iCommonsToKill, g_iPointsInfected));
	if (g_iPointsTime != 0)
		hPanel.DrawText(Translate(client, "%t", "{} min. in game - {} point(s)", g_iTimeToPlay, g_iPointsTime));
	if (g_iPenaltyDeath != 0)
		hPanel.DrawText(Translate(client, "%t", "Penalty for death - {} point(s)", g_iPenaltyDeath));
	if (g_iPenaltyIncap != 0)
		hPanel.DrawText(Translate(client, "%t", "Penalty for incap - {} point(s)", g_iPenaltyIncap));
	if (g_iPenaltyFF != 0)
		hPanel.DrawText(Translate(client, "%t", "Penalty for ff - {} point(s)", g_iPenaltyFF));
}

void ShowPointsAbout2(int client)
{
	Panel hPanel = new Panel();
	hPanel.SetTitle(Translate(client, "%t", "Scoring:"));
	DrawPointsAbout2(client, hPanel);
	hPanel.DrawItem(Translate(client, "%t", "Close"));
	hPanel.DrawItem(Translate(client, "%t", "Back"));
	hPanel.Send(client, AboutPanelHandler, 20);
	delete hPanel;
}

public int AboutPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 2: CMD_stat(param1, 0);
			case 3: ShowPointsAbout2(param1);
		}
	}
	return 0;
}

public int CommonPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 2: CMD_stat(param1, 0);
		}
	}
	return 0;
}

public int RankPanelHandler(Menu menu, MenuAction action, int param1, int param2)
{
	if (action == MenuAction_Select)
	{
		switch (param2)
		{
			case 2: CMD_stat(param1, 0);
			case 3: ShowOtherPlayerRank(param1);
		}
	}
}

void ShowOtherPlayerRank(int client)
{
	Menu menu = new Menu(MenuHandler_MenuOtherRank, MENU_ACTIONS_DEFAULT);
	menu.SetTitle(Translate(client, "%t", "List_Players"));
	
	static char sId[16], name[64];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			Format(sId, sizeof(sId), "%i", GetClientUserId(i));
			Format(name, sizeof(name), "%N - %i", i, g_iReal[i][HX_POINTS] + g_iTemp[i][HX_POINTS]);
			
			menu.AddItem(sId, name);
		}
	}
	menu.ExitBackButton = true;
	menu.Display(client, MENU_TIME_FOREVER);
}

public int MenuHandler_MenuOtherRank(Menu menu, MenuAction action, int param1, int param2)
{
	switch (action)
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Cancel:
			if (param2 == MenuCancel_ExitBack)
				CMD_stat(param1, 0);
		
		case MenuAction_Select:
		{
			int client = param1;
			int ItemIndex = param2;
			
			static char sUserId[16];
			menu.GetItem(ItemIndex, sUserId, sizeof(sUserId));
			
			int UserId = StringToInt(sUserId);
			int target = GetClientOfUserId(UserId);
			
			if (target && IsClientInGame(target))
			{
				ShowRank(target, client);
			}
		}
	}
}

public Action CMD_rank(int client, int args)
{
	ShowRank(client);
	return Plugin_Handled;
}

void ShowRank(int client, int iDisplayToCustomClient = 0)
{
	int iRequestor = iDisplayToCustomClient == 0 ? client : iDisplayToCustomClient;
	
	FormatEx(g_sBuf1, sizeof(g_sBuf1)
	, "%d %T (%T:%d, %T:%d, %T:%d)\n\
		- \n\
		%T: %d \n"
			, 					 	RoundToCeil(g_iReal[client][HX_POINTS] 			+ g_iTemp[client][HX_POINTS] 	+ g_fPenaltyBonus[client]), "points", iRequestor
			,	"M", iRequestor, 				g_iReal[client][HX_POINTS_MONTH] 	+ g_iTemp[client][HX_POINTS]
			,	"W", iRequestor,				g_iReal[client][HX_POINTS_WEEK] 	+ g_iTemp[client][HX_POINTS]
			,	"R", iRequestor,	RoundToCeil(g_iTemp[client][HX_POINTS]											+ g_fPenaltyBonus[client])
		, "Place", iRequestor,		g_iReal[client][HX_PLACE] );
	
	if (g_iPointsInfected != 0)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Infected", iRequestor, 	g_iReal[client][HX_INFECTED]	+ g_iTemp[client][HX_INFECTED],   	g_iTemp[client][HX_INFECTED] );
	if (g_iPointsBoomer != 0)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Boomer", iRequestor, 		g_iReal[client][HX_BOOMER]		+ g_iTemp[client][HX_BOOMER],   	g_iTemp[client][HX_BOOMER] );
	if (g_bL4D2 && g_iPointsCharger != 0)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Charger", iRequestor, 	g_iReal[client][HX_CHARGER]		+ g_iTemp[client][HX_CHARGER],   	g_iTemp[client][HX_CHARGER] );
	if (g_iPointsHunter != 0)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Hunter", iRequestor, 		g_iReal[client][HX_HUNTER]		+ g_iTemp[client][HX_HUNTER],   	g_iTemp[client][HX_HUNTER] );
	if (g_bL4D2 && g_iPointsJockey != 0)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Jockey", iRequestor, 		g_iReal[client][HX_JOCKEY]		+ g_iTemp[client][HX_JOCKEY],   	g_iTemp[client][HX_JOCKEY] );
	if (g_iPointsSmoker != 0)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Smoker", iRequestor, 		g_iReal[client][HX_SMOKER]		+ g_iTemp[client][HX_SMOKER],   	g_iTemp[client][HX_SMOKER] );
	if (g_bL4D2 && g_iPointsSpitter != 0)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Spitter", iRequestor, 	g_iReal[client][HX_SPITTER]		+ g_iTemp[client][HX_SPITTER],   	g_iTemp[client][HX_SPITTER] );
	if (g_iPointsTank != 0)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Tank", iRequestor, 		g_iReal[client][HX_TANK]		+ g_iTemp[client][HX_TANK],   		g_iTemp[client][HX_TANK] );
	if (g_iPointsWitch != 0)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Witch", iRequestor, 		g_iReal[client][HX_WITCH]		+ g_iTemp[client][HX_WITCH],   		g_iTemp[client][HX_WITCH] );
		
	if (g_iPenaltyDeath != 0 || g_iPenaltyIncap != 0 || g_iPenaltyFF != 0)
	{
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)", g_sBuf1, "Penalty", iRequestor, 	
			RoundToCeil(g_fPenaltyBonus[client] + g_iReal[client][HX_PENALTY] + g_iTemp[client][HX_PENALTY]),
			RoundToCeil(g_fPenaltyBonus[client] + g_iTemp[client][HX_PENALTY]) );
	}
	
	if (client == 0)
	{
		if (IsClientInGame(g_iRequestorId))
		{
			PrintToConsole(g_iRequestorId, g_sBuf1);
			PrintToChat(g_iRequestorId, g_sBuf1);
		}
	}
	else {
		Panel hPanel = new Panel();
		hPanel.DrawText(g_sBuf1);
		hPanel.DrawItem(Translate(iRequestor, "%t", "Close"));
		hPanel.DrawItem(Translate(iRequestor, "%t", "Back"));
		hPanel.DrawItem(Translate(iRequestor, "%t", "Other_Player_Points"));
		hPanel.Send(iRequestor, RankPanelHandler, 20);
		delete hPanel;
	}
}

public Action CMD_top(int client, int args)
{
	ShowTop(client, PERIOD_TOTAL);
	return Plugin_Handled;
}

public Action CMD_LogPoints(int client, int agrs)
{
	ShowTop(client, PERIOD_LAST_WEEK, true);
	ShowTop(client, PERIOD_LAST_MONTH, true);
	PrintToChat(client, "Log points is executed.");
	return Plugin_Handled;
}

void ShowTop(int client, int ePeriod, bool bPrintLog = false)
{
	static char sField[16];
	GetTopPeriodField( ePeriod, sField, sizeof(sField));
	
	if (client)
	{
		if (IsClientInGame(client))
		{
			if (g_iTopLastTime[client] != 0 ) // block calling !top too often
			{
				if (g_iTopLastTime[client] + g_ConVarTopCallInterval.IntValue > GetTime() && !IsClientRootAdmin(client))
				{
					CPrintToChat(client, "%t", "Wait for {} sec", g_ConVarTopCallInterval.IntValue - (GetTime() - g_iTopLastTime[client]));
					return;
				}
			}
			g_iTopLastTime[client] = GetTime();
			
			if (g_hDB)
			{
				FormatEx(g_sQuery3, sizeof(g_sQuery3), "SELECT `Name`, `%s` FROM `"...HX_TABLE..."` WHERE `Hide` = 0 ORDER BY `%s` DESC LIMIT %i", sField, sField, GetTopPeriodLimit(ePeriod));
				
				DataPack dp = new DataPack();
				dp.WriteCell(GetClientUserId(client));
				dp.WriteCell(ePeriod);
				dp.WriteCell(bPrintLog);
				
				g_hDB.Query(SQL_Callback_Top, g_sQuery3, dp);
			}
		}
	}
}

public void SQL_Callback_Top (Database db, DBResultSet hQuery, const char[] error, int data)
{
	if (!db || !hQuery) { LogError(error); return; }
	
	DataPack dp = view_as<DataPack>(data);
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int ePeriod = dp.ReadCell();
	bool bPrintLog = dp.ReadCell();
	delete dp;
	
	if (!client || !IsClientInGame(client)) return;
	
	static char sName[32];
	static char sPeriod[64];
	int iPoints = 0;
	int iNum = 0;
	
	GetTopPeriodName(client, ePeriod, sPeriod, sizeof(sPeriod));
	StrCat(sPeriod, sizeof(sPeriod), "\n - \n");

	Panel hPanel = new Panel();
	hPanel.SetTitle(sPeriod);
	
	if (bPrintLog)
	{
		char sTime[32];
		FormatTime(sTime, sizeof(sTime), "%F, %X", GetTime());
		AddLogString("%s - %s", sPeriod, sTime);
	}

	if (hQuery)
	{
		while (hQuery.FetchRow())
		{
			hQuery.FetchString(0, sName, sizeof(sName));
			iPoints = hQuery.FetchInt(1);

			iNum += 1;
			hPanel.DrawText(Translate(client, "%d. %s - %d", iNum, sName, iPoints));
			
			if (bPrintLog)
			{
				AddLogString("%d. %s - %d", iNum, sName, iPoints);
			}
		}
	}
	
	hPanel.DrawItem(Translate(client, "%t", "Close"));
	hPanel.DrawItem(Translate(client, "%t", "Back"));
	hPanel.Send(client, CommonPanelHandler, 20);
	delete hPanel;
}

public Action CMD_Refresh(int client, int args)
{
	if (g_hDB) {
		PrintToChat(client, "SQL connection is live.");
		SQL_SaveAll(false);
	}
	else {
		PrintToChat(client, "SQL connection is LOST!");
	}
	return Plugin_Handled;
}

/* ==============================================================
					H E L P E R S
// ============================================================== */

void GetTopPeriodName (int client, int ePeriod, char[] sPeriod, int size)
{
	switch(ePeriod)
	{
		case PERIOD_TOTAL: 		{ strcopy(sPeriod, size, Translate(client, "%t", "all the time")); 		}
		case PERIOD_MONTH: 		{ strcopy(sPeriod, size, Translate(client, "%t", "the month")); 		}
		case PERIOD_WEEK: 		{ strcopy(sPeriod, size, Translate(client, "%t", "the week")); 			}
		case PERIOD_LAST_MONTH: { strcopy(sPeriod, size, Translate(client, "%t", "the last month")); 	}
		case PERIOD_LAST_WEEK: 	{ strcopy(sPeriod, size, Translate(client, "%t", "the last week")); 	}
	}
}

void GetTopPeriodField (int ePeriod, char[] sField, int size)
{
	switch(ePeriod)
	{
		case PERIOD_TOTAL: 		{ strcopy(sField, size, "Points");		}
		case PERIOD_MONTH: 		{ strcopy(sField, size, "Pt_month");	}
		case PERIOD_WEEK: 		{ strcopy(sField, size, "Pt_week");		}
		case PERIOD_LAST_MONTH: { strcopy(sField, size, "Pt_lmonth");	}
		case PERIOD_LAST_WEEK: 	{ strcopy(sField, size, "Pt_lweek");	}
	}
}

int GetTopPeriodLimit(int ePeriod)
{
	switch(ePeriod)
	{
		case PERIOD_TOTAL: 		{ return g_ConVarLimitTopAll.IntValue;		}
		case PERIOD_MONTH: 		{ return g_ConVarLimitTopMonth.IntValue;	}
		case PERIOD_WEEK: 		{ return g_ConVarLimitTopWeek.IntValue;		}
		case PERIOD_LAST_MONTH: { return g_ConVarLimitTopMonthVIP.IntValue;	}
		case PERIOD_LAST_WEEK: 	{ return g_ConVarLimitTopWeekVIP.IntValue;	}
	}
	return 0;
}

void HxClean(int &client, bool bTempOnly = false)
{
	g_iTemp[client][HX_POINTS]   = 0;
	g_iTemp[client][HX_TIME]     = 0;
	g_iTemp[client][HX_BOOMER]   = 0;
	g_iTemp[client][HX_CHARGER]  = 0;
	g_iTemp[client][HX_HUNTER]   = 0;
	g_iTemp[client][HX_INFECTED] = 0;
	g_iTemp[client][HX_JOCKEY]   = 0;
	g_iTemp[client][HX_SMOKER]   = 0;
	g_iTemp[client][HX_SPITTER]  = 0;
	g_iTemp[client][HX_TANK]     = 0;
	g_iTemp[client][HX_WITCH]    = 0;
	g_iTemp[client][HX_PENALTY]  = 0;
	
	if ( !bTempOnly )
	{
		g_iReal[client][HX_POINTS]   = 0;
		g_iReal[client][HX_TIME]     = 0;
		g_iReal[client][HX_BOOMER]   = 0;
		g_iReal[client][HX_CHARGER]  = 0;
		g_iReal[client][HX_HUNTER]   = 0;
		g_iReal[client][HX_INFECTED] = 0;
		g_iReal[client][HX_JOCKEY]   = 0;
		g_iReal[client][HX_SMOKER]   = 0;
		g_iReal[client][HX_SPITTER]  = 0;
		g_iReal[client][HX_TANK]     = 0;
		g_iReal[client][HX_WITCH]    = 0;
		g_iReal[client][HX_PENALTY]  = 0;
		g_iReal[client][HX_POINTS_MONTH]   = 0;
		g_iReal[client][HX_POINTS_WEEK]    = 0;
		g_iReal[client][HX_PLACE]    = 0;
	}
}

bool CacheSteamID(int client)
{
	if (client == 0)
	{
		strcopy( g_sSteamId[0], sizeof(g_sSteamId[]), g_sReqSteam);
		g_sReqSteam[0] = '\0';
		return true;
	}
	if (g_sSteamId[client][0] == '\0')
	{
		if ( !GetClientAuthId(client, AuthId_Steam2, g_sSteamId[client], sizeof(g_sSteamId[])) )
		{
			return false;
		}
	}
	return true;
}

public int HxColorC(int &client, int iPoints)
{
	if (iPoints > 80000) { SetEntityRenderColor(client, 0, 0, 0, 252); 		return 8; }
	if (iPoints > 50000) { SetEntityRenderColor(client, 255, 51, 204, 255); return 7; }
	if (iPoints > 20000) { SetEntityRenderColor(client, 164, 79, 25, 255);	return 6; }
	if (iPoints > 7000)  { SetEntityRenderColor(client, 0, 153, 51, 255);	return 5; }
	if (iPoints > 2000)  { SetEntityRenderColor(client, 0, 51, 255, 255); 	return 4; }
	if (iPoints > 500)   { SetEntityRenderColor(client, 0, 204, 255, 255); 	return 3; }
	if (iPoints > 20) 	 { return 2; }
	return 1;
}

public void HxProtect(char[] sBuf, int size)
{
	static char result[64];
	g_hDB.Escape(sBuf, result, sizeof(result));
	strcopy(sBuf, size, result);
}

void SQL_SaveAll(bool bCloseConn)
{
	if (g_iRoundStart == 0)
		return;

	if (bCloseConn)
		g_iRoundStart = 0;
	
	if (!g_hDB)
		return;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (!IsFakeClient(i))
			{
				SQL_Save(i);
			}
		}
	}
	
	/*
	if (bCloseConn)
	{
		delete g_hDB;
	}
	*/
}

stock bool IsClientRootAdmin(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}

stock char[] Translate(int client, const char[] format, any ...)
{
	static char buffer[192];
	SetGlobalTransTarget(client);
	VFormat(buffer, sizeof(buffer), format, 3);
	return buffer;
}

stock void ReplaceColor(char[] message, int maxLen)
{
    ReplaceString(message, maxLen, "{white}", "\x01", false);
    ReplaceString(message, maxLen, "{cyan}", "\x03", false);
    ReplaceString(message, maxLen, "{orange}", "\x04", false);
    ReplaceString(message, maxLen, "{green}", "\x05", false);
}

stock void CPrintToChat(int iClient, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
}

stock void CPrintHintText(int iClient, const char[] format, any ...)
{
    static char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintHintText(iClient, "\x01%s", buffer);
}

void PrintPoints(int client, const char[] format, any ...)
{
	if (g_bPrintPoints)
	{
		static char buffer[192];
		SetGlobalTransTarget(client);
		VFormat(buffer, sizeof(buffer), format, 3);
		ReplaceColor(buffer, sizeof(buffer));
		PrintToChat(client, buffer);
	}
}

void AddLogString(const char[] format, any ...)
{
	static char sLogPath[PLATFORM_MAX_PATH];
	static char buffer[192];
	if (sLogPath[0] == '\0')
	{
		BuildPath(Path_SM, sLogPath, sizeof(sLogPath), "logs/hx_stats.log");
	}
	File hFile = OpenFile(sLogPath, "a+");
	if( hFile != null )
	{
		VFormat(buffer, sizeof(buffer), format, 2);
		hFile.WriteLine(buffer);
		FlushFile(hFile);
		hFile.Close();
	}
}

bool GiveVIP(int client, int days)
{
	#if defined _vip_core_included

	bool bSuccess = false;

	if ( g_bVipCoreLib )
	{
		int iTimeStamp;
		
		if ( VIP_IsClientVIP (client) )
		{
			iTimeStamp = VIP_GetClientAccessTime(client);
			
			if (iTimeStamp != 0)
			{
				iTimeStamp += VIP_SecondsToTime(days * 24 * 60 * 60);
			
				VIP_SetClientAccessTime(client, iTimeStamp, true);
				bSuccess = true;
			}
		}
		else {
			if (VIP_IsValidVIPGroup(g_sVIPGroup))
			{
				iTimeStamp = VIP_SecondsToTime(days * 24 * 60 * 60);
				
				VIP_GiveClientVIP(0, client, iTimeStamp, g_sVIPGroup, true);
				bSuccess = true;
			}
			else {
				LogError("Invalid vip group: %s", g_sVIPGroup);
				return false;
			}
		}
		if (bSuccess)
		{
			CPrintToChat(client, "%t", "Won_VIP", days);
			CPrintHintText(client, "%t", "Won_VIP_Hint", days);
		}
		return true;
	}
	#else
		#pragma unused client, days
	#endif
	return false;
}

int GetFirstMonthDay()
{
	static char sH[8], sM[8], sS[8], sD[8];
	int H, M, S, D;
	int iUnix = GetTime();
	FormatTime(sH, 8, "%H", iUnix);
	FormatTime(sM, 8, "%M", iUnix);
	FormatTime(sS, 8, "%S", iUnix);
	FormatTime(sD, 8, "%d", iUnix);
	H = StringToInt(sH);
	M = StringToInt(sM);
	S = StringToInt(sS);
	D = StringToInt(sD);
	iUnix -= S + M * 60 + H * 3600 + (D - 1) * 24 * 3600;
	return iUnix;
}

int GetFirstWeekDay()
{
	static char sH[8], sM[8], sS[8], sWDN[8];
	int H, M, S, WDN;
	int iUnix = GetTime();
	FormatTime(sH, 8, "%H", iUnix);
	FormatTime(sM, 8, "%M", iUnix);
	FormatTime(sS, 8, "%S", iUnix);
	FormatTime(sWDN, 8, "%w", iUnix);
	H = StringToInt(sH);
	M = StringToInt(sM);
	S = StringToInt(sS);
	WDN = StringToInt(sWDN);
	WDN -= g_ConVarFirstDayOfWeek.IntValue;
	if (WDN == -1) WDN = 6;
	iUnix -= S + M * 60 + H * 3600 + WDN * 24 * 3600;
	return iUnix;
}