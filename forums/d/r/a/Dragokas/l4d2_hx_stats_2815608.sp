/**
 *
 * =============================================================================
 * Copyright 2017-2020 iHx, steamcommunity.com/profiles/76561198025355822/
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

#define PLUGIN_VERSION "1.0.33b"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <sdktools>
#include <hx_stats>

#undef REQUIRE_PLUGIN
#tryinclude <vip_core>

#define CVAR_FLAGS FCVAR_NOTIFY

#define DEBUG 0
#define DEBUG_SQL 1

char HX_TABLE[32]; // "l4d2_stats"
char HX_TABLE_BACKUP[32]; // "l4d2_stats_backup"

#define HX_DATABASE_CFG "l4d2_stats" // in configs/databases.cfg

#define HX_CREATE_TABLE "\
CREATE TABLE IF NOT EXISTS `%s` (\
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
 `TankSolo` int(11) NOT NULL DEFAULT '0',\
 `Witch` int(11) NOT NULL DEFAULT '0',\
 `HeadShot` int(11) NOT NULL DEFAULT '0',\
 PRIMARY KEY (`Steamid`)\
) ENGINE=InnoDB DEFAULT CHARSET=utf8;\
"
#define HX_SERVICE_STEAM "DATABASE_UPDATE"
#define HX_SERVICE_USER "Database. Don''t touch me!"
#define HX_LOG_FILE "logs/hx_stats.log"

enum
{
	PERIOD_TOTAL,
	PERIOD_MONTH,
	PERIOD_WEEK,
	PERIOD_LAST_MONTH,
	PERIOD_LAST_WEEK
}

enum REQUEST_ACTIONS
{
	ACTION_SHOWPOINTS,
	ACTION_MOVEPOINTS
}

REQUEST_ACTIONS g_iReqAction;

char g_sQuery1[640];
char g_sQuery2[640];
char g_sQuery3[312];

char g_sBuf1[312];
char g_sBuf3[32];

char g_sSteamId[MAXPLAYERS+1][32];
char g_sName[MAXPLAYERS+1][64];
char g_sReqSteam[32];
char g_sDestSteam[32];
char g_sMenuName[32];
char g_sBaseMenu[32];
char g_sVIPGroup[32];

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
int g_iPointsTankSolo;
int g_iPointsWitch;
int g_iPointsHeadShot;
int g_iPenaltyDeath;
int g_iPenaltyIncap;
int g_iPenaltyFF;
int g_iCommonsToKill;
int g_iTimeToPlay;
int g_iRequestorId;
int g_iHiddenFlagBits;

float g_fFactor;
float g_fPenaltyBonus[MAXPLAYERS+1]; // for a very little damage values ( < 10 )

bool g_bLateload;
bool g_bL4D2;
bool g_bInDisconnect[MAXPLAYERS+1];
bool g_bClientRegistered[MAXPLAYERS+1];
bool g_bRankDisplayed[MAXPLAYERS+1];
bool g_bPrintPoints;
bool g_bBaseMenuAvail;
bool g_bMapTransition;
bool g_bVipCoreLib;
bool g_bEnabled;
bool g_bAllowNegativePoints;

#pragma unused g_bVipCoreLib

Database g_hDB;

ConVar g_ConVarEnable;
ConVar g_ConVarVoteRank;
ConVar g_ConVarIdleRank;
ConVar g_ConVarTopCallInterval;
ConVar g_ConVarPoints[HX_POINTS_SIZE];
ConVar g_ConVarPrintPoints;
ConVar g_ConVarMenuName;
ConVar g_ConVarCommonsToKill;
ConVar g_ConVarTimeToPlay;
ConVar g_ConVarShowRankPlayerStart;
ConVar g_ConVarShowRankDelay;
ConVar g_ConVarFirstDayOfWeek;
ConVar g_ConVarMenuBestOfWeek;
ConVar g_ConVarMenuBestOfLWeek;
ConVar g_ConVarMenuBestOfMonth;
ConVar g_ConVarMenuBestOfLMonth;
ConVar g_ConVarLimitTopAll;
ConVar g_ConVarLimitTopWeek;
ConVar g_ConVarLimitTopMonth;
ConVar g_ConVarLimitTopWeekVIP;
ConVar g_ConVarLimitTopMonthVIP;
#if defined _vip_core_included
ConVar g_ConVarAwardTopWeekVIP;
ConVar g_ConVarAwardTopMonthVIP;
#endif
ConVar g_ConVarHideFlag;
ConVar g_ConVarVIPGroup;
ConVar g_ConVarBaseMenu;
ConVar g_ConVarWeekBackup;
ConVar g_ConVarWeekBackupRewrite;
ConVar g_ConVarTableName;
ConVar g_ConVarTableBackupName;
ConVar g_ConVarFactorEasy;
ConVar g_ConVarFactorNormal;
ConVar g_ConVarFactorHard;
ConVar g_ConVarFactorExpert;
ConVar g_ConVarDifficulty;
ConVar g_ConVarPointsAllowNegative;
ConVar g_ConVarShowRankOnce;
ConVar g_ConVarShowRankInChat;
ConVar g_ConVarShowRankInChatToAll;
ConVar g_ConVarShowRankInCenter;
ConVar g_ConVarShowRankInPanel;

Handle g_OnClientRegistered;

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
	CreateNative("HX_IsClientRegistered", NATIVE_IsClientRegistered);
	g_OnClientRegistered = CreateGlobalForward("HX_OnClientRegistered", ET_Ignore, Param_Cell);
	RegPluginLibrary("hx_stats");
	return APLRes_Success;
}

public Plugin myinfo =
{
	name = "[L4D] DragoStats",
	author = "Dragokas & MAKS",
	description = "L4D 1/2 Coop Stats",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=320247"
};

public void OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("hx_stats.phrases");
	
	CreateConVar("l4d_hxstat_version", 	PLUGIN_VERSION, "Version of this plugin", FCVAR_DONTRECORD | CVAR_FLAGS);
	
	g_ConVarEnable = 					CreateConVar("l4d_hxstat_enable", 					"1", 	"Enable counting points? (0 - No, 1 - Yes)", CVAR_FLAGS);

	g_ConVarVoteRank = 					CreateConVar("l4d_hxstat_callvote_rank", 			"0", 	"Minimum rank to allow using the vote", CVAR_FLAGS);
	g_ConVarIdleRank = 					CreateConVar("l4d_hxstat_idle_rank", 				"0", 	"Minimum rank to allow using !idle", CVAR_FLAGS);
	g_ConVarTopCallInterval = 			CreateConVar("l4d_hxstat_rank_call_interval", 		"30", 	"Minimum interval (in sec.) to allow calling !top again", CVAR_FLAGS);
	g_ConVarPrintPoints = 				CreateConVar("l4d_hxstat_print_points", 			"1", 	"Print points in chat when you kill infected? (0 - No, 1 - Yes)", CVAR_FLAGS);
	
	g_ConVarShowRankPlayerStart = 		CreateConVar("l4d_hxstat_rank_onstart",				"1", 	"Show rank when player starts to play (joined)? (0 - No, 1 - Yes)", CVAR_FLAGS);
	g_ConVarShowRankOnce =		 		CreateConVar("l4d_hxstat_rank_once",				"1", 	"Show rank (to himself) only once per player joined the server? (0 - No, 1 - Yes)", CVAR_FLAGS);
	g_ConVarShowRankInChat = 			CreateConVar("l4d_hxstat_rank_inchat",				"1", 	"Show rank in chat when player joined? (0 - No, 1 - Yes). See: 'Join_Rank_InChat' translation phrase", CVAR_FLAGS);
	g_ConVarShowRankInChatToAll =		CreateConVar("l4d_hxstat_rank_inchat_to_all",		"0", 	"Show rank in chat to all when some player joined? (0 - No, 1 - Yes).", CVAR_FLAGS);
	g_ConVarShowRankInCenter = 			CreateConVar("l4d_hxstat_rank_incenter",			"0", 	"Show rank in the center screen when player joined? (0 - No, 1 - Yes). See: 'Join_Rank_InCenter' translation phrase", CVAR_FLAGS);
	g_ConVarShowRankInPanel = 			CreateConVar("l4d_hxstat_rank_inpanel",				"1", 	"Show rank in the panel when player joined? (0 - No, 1 - Yes)", CVAR_FLAGS);
	g_ConVarShowRankDelay = 			CreateConVar("l4d_hxstat_rank_delay", 				"6.0", 	"Delay (in sec.) on round start to show player's rank", CVAR_FLAGS);
	
	g_ConVarHideFlag = 					CreateConVar("l4d_hxstat_hide_flag", 				"", 	"Users with these flag(s) will be hidden in statistics. Change require 'sm_hx_unhide' command execution", CVAR_FLAGS);
	
	if( g_bL4D2 )
	{
		g_ConVarPoints[HX_CHARGER] = 	CreateConVar("l4d_hxstat_points_charger", 			"1", 	"How many points to give for killing the charger", CVAR_FLAGS);
		g_ConVarPoints[HX_JOCKEY] = 	CreateConVar("l4d_hxstat_points_jockey", 			"1", 	"How many points to give for killing the jockey", CVAR_FLAGS);
		g_ConVarPoints[HX_SPITTER] = 	CreateConVar("l4d_hxstat_points_spitter", 			"1", 	"How many points to give for killing the spitter", CVAR_FLAGS);
	}
	g_ConVarPoints[HX_BOOMER] = 		CreateConVar("l4d_hxstat_points_boomer", 			"1", 	"How many points to give for killing the boomer", CVAR_FLAGS);
	g_ConVarPoints[HX_HUNTER] = 		CreateConVar("l4d_hxstat_points_hunter", 			"1", 	"How many points to give for killing the hunter", CVAR_FLAGS);
	g_ConVarPoints[HX_SMOKER] = 		CreateConVar("l4d_hxstat_points_smoker", 			"1", 	"How many points to give for killing the smoker", CVAR_FLAGS);
	g_ConVarPoints[HX_TANK] = 			CreateConVar("l4d_hxstat_points_tank", 				"5", 	"How many points to give for final tank shoot", CVAR_FLAGS);
	g_ConVarPoints[HX_TANK_SOLO] = 		CreateConVar("l4d_hxstat_points_tank_solo",			"10", 	"How many points to give for killing the tank in solo (1 person deal damage only)", CVAR_FLAGS);
	g_ConVarPoints[HX_WITCH] = 			CreateConVar("l4d_hxstat_points_witch", 			"2", 	"How many points to give for killing the witch", CVAR_FLAGS);
	g_ConVarPoints[HX_HEADSHOT] = 		CreateConVar("l4d_hxstat_points_headshot", 			"1", 	"How many additional points to give for headshot", CVAR_FLAGS);
	
	g_ConVarPoints[HX_PENALTY_DEATH] = 	CreateConVar("l4d_hxstat_points_penalty_death", 	"-20", 	"How many points penalty for beeing killed by infected", CVAR_FLAGS);
	g_ConVarPoints[HX_PENALTY_INCAP] = 	CreateConVar("l4d_hxstat_points_penalty_incap", 	"-5", 	"How many points penalty for beeing incapacitated", CVAR_FLAGS);
	g_ConVarPoints[HX_PENALTY_FF] = 	CreateConVar("l4d_hxstat_points_penalty_ff", 		"-1", 	"How many points penalty for shooting teammate decreasing 10 hp", CVAR_FLAGS);
	g_ConVarPointsAllowNegative = 		CreateConVar("l4d_hxstat_points_allow_negative", 	"1", 	"1 - Allow points below zero, e.g. when new player takes a penalty. 0 - forbid; in such case points will stop on zero.", CVAR_FLAGS);
	
	g_ConVarCommonsToKill = 			CreateConVar("l4d_hxstat_commons_kill", 			"50", 	"How many common zombies to kill to give points (for each piece)? (0 - to disable)", CVAR_FLAGS);
	g_ConVarPoints[HX_INFECTED] = 		CreateConVar("l4d_hxstat_points_infected", 			"1", 	"How many points to give for killing X common zombies", CVAR_FLAGS);
	
	g_ConVarTimeToPlay =				CreateConVar("l4d_hxstat_time_play", 				"30", 	"How much time to play (in minutes) to give points (for each time interval)? (0 - to disable)", CVAR_FLAGS);
	g_ConVarPoints[HX_TIME] = 			CreateConVar("l4d_hxstat_points_time", 				"10", 	"How many points to give for X minutes spent in game", CVAR_FLAGS);
	
	g_ConVarFactorEasy = 				CreateConVar("l4d_hxstat_factor_easy", 				"0.5", 	"All points are multiply by this value when game difficulty is 'Easy'", CVAR_FLAGS);
	g_ConVarFactorNormal = 				CreateConVar("l4d_hxstat_factor_normal", 			"1", 	"All points are multiply by this value when game difficulty is 'Normal'", CVAR_FLAGS);
	g_ConVarFactorHard = 				CreateConVar("l4d_hxstat_factor_hard", 				"2", 	"All points are multiply by this value when game difficulty is 'Hard'", CVAR_FLAGS);
	g_ConVarFactorExpert = 				CreateConVar("l4d_hxstat_factor_expert", 			"4", 	"All points are multiply by this value when game difficulty is 'Impossible'", CVAR_FLAGS);
	
	g_ConVarMenuName = 					CreateConVar("l4d_hxstat_menu_name", 		"My Server name", 			"Name of statistics menu in !stat command", CVAR_FLAGS);
	g_ConVarVIPGroup = 					CreateConVar("l4d_hxstat_vip_group", 		"Black VIP", 				"VIP Group name (see file: data/vip/cfg/groups.ini)", CVAR_FLAGS);
	g_ConVarBaseMenu = 					CreateConVar("l4d_hxstat_base_menu", 		"sm_menu", 					"Command of 3d-party plugin to execute when you press 'Back' button in menu (leave empty, if none need)", CVAR_FLAGS);
	
	g_ConVarLimitTopAll = 				CreateConVar("l4d_hxstat_limit_top_all", 			"15", 	"How many players to show in global top", CVAR_FLAGS);
	g_ConVarLimitTopWeek = 				CreateConVar("l4d_hxstat_limit_top_week", 			"15", 	"How many players to show in top of week", CVAR_FLAGS);
	g_ConVarLimitTopMonth = 			CreateConVar("l4d_hxstat_limit_top_month", 			"15", 	"How many players to show in top of month", CVAR_FLAGS);
	g_ConVarLimitTopWeekVIP = 			CreateConVar("l4d_hxstat_limit_top_week_vip", 		"10", 	"How many players to award in top of week (and to show in top of last week)", CVAR_FLAGS);
	g_ConVarLimitTopMonthVIP = 			CreateConVar("l4d_hxstat_limit_top_month_vip", 		"3", 	"How many players to award in top of month (and to show in top of last month)", CVAR_FLAGS);
	
	#if defined _vip_core_included
	g_ConVarAwardTopWeekVIP = 			CreateConVar("l4d_hxstat_award_top_week_vip", 		"7", 	"How many days of VIP to award player with (in winning top of week) (0 - to disable)", CVAR_FLAGS);
	g_ConVarAwardTopMonthVIP = 			CreateConVar("l4d_hxstat_award_top_month_vip", 		"31", 	"How many days of VIP to award player with (in winning top of month) (0 - to disable)", CVAR_FLAGS);
	#endif
	
	g_ConVarFirstDayOfWeek = 			CreateConVar("l4d_hxstat_firstday", 				"1", 	"First day of the week (0 - Sunday, 1 - Monday)", CVAR_FLAGS);
	
	g_ConVarMenuBestOfWeek = 			CreateConVar("l4d_hxstat_menu_best_week", 			"1", 	"Enable 'Best of week' menu item? (1 - Yes, 0 - No)", CVAR_FLAGS);
	g_ConVarMenuBestOfLWeek = 			CreateConVar("l4d_hxstat_menu_best_lweek", 			"1", 	"Enable 'Best of last week' menu item? (1 - Yes, 0 - No)", CVAR_FLAGS);
	g_ConVarMenuBestOfMonth = 			CreateConVar("l4d_hxstat_menu_best_month", 			"1", 	"Enable 'Best of month' menu item? (1 - Yes, 0 - No)", CVAR_FLAGS);
	g_ConVarMenuBestOfLMonth = 			CreateConVar("l4d_hxstat_menu_best_lmonth", 		"1", 	"Enable 'Best of last month' menu item? (1 - Yes, 0 - No)", CVAR_FLAGS);
	
	g_ConVarWeekBackup = 				CreateConVar("l4d_hxstat_week_backup", 				"0", 	"Enable full database backup every week? (1 - Yes, 0 - No)", CVAR_FLAGS);
	g_ConVarWeekBackupRewrite = 		CreateConVar("l4d_hxstat_week_backup_rewrite",		"0", 	"Should week backup be overwritten? (1 - Yes, 0 - No: each time create new table with YYYY-MM-DD in name)", CVAR_FLAGS);
	
	g_ConVarTableName = 				CreateConVar("l4d_hxstat_table", 				"l4d2_stats", 			"Preferred table name in database. It should be different for other server if you don't want to share points", CVAR_FLAGS);
	g_ConVarTableBackupName = 			CreateConVar("l4d_hxstat_table_backup",			"l4d2_stats_backup", 	"Preferred table name in database for your backups.", CVAR_FLAGS);
	
	AutoExecConfig(true, "l4d_hx_stats");
	
	g_ConVarDifficulty = FindConVar("z_difficulty");
		
	RegAdminCmd("sm_hx_sqlcreate", 	CMD_sqlcreate, 	ADMFLAG_ROOT, "Creates database table in case automatic mode is failed (warning: all data will be erased !!!)");
	RegAdminCmd("sm_hx_logpoints", 	CMD_LogPoints, 	ADMFLAG_ROOT, "Prints to log the list of top players of the last week and the last month");
	RegAdminCmd("sm_hx_upgrade", 	CMD_Upgrade,	ADMFLAG_ROOT, "Updates database table to the latest version");
	RegAdminCmd("sm_hx_backup", 	CMD_Backup,		ADMFLAG_ROOT, "<opt. 0/1 overwrite> <opt.table_name> Backups database table (by default, to `l4d2_stats_backup` table). Warning: old backup will be erased !!!");
	RegAdminCmd("sm_hx_revert", 	CMD_Revert,		ADMFLAG_ROOT, "Revert a database from a backup. Warning: current database table will be lost !!!");
	RegAdminCmd("sm_hx_showpoints",	CMD_ShowPoints,	ADMFLAG_ROOT, "sm_hx_showpoints <#userid|name|steamid> - show points of specified player (including offline, if steamid provided)");
	RegAdminCmd("sm_hx_movepoints",	CMD_MovePoints,	ADMFLAG_ROOT, "sm_hx_movepoints <steamid of source> <steamid of destination> - move points to another account (useful, if steam id is changed)");
	RegAdminCmd("sm_hx_delplayer",	CMD_DelPlayer,	ADMFLAG_ROOT, "sm_hx_delplayer <steamid> - delete statistics of this player completely");
	RegAdminCmd("sm_hx_delold",		CMD_DelOld,		ADMFLAG_ROOT, "sm_hx_delold <days> - delete players who didn't join for more than <days> ago (it is recommnded to use with `sm_hx_backup` first)");
	RegAdminCmd("sm_hx_unhide",		CMD_UnhideAll,	ADMFLAG_ROOT, "Unhides all admins statistics. Useful to populate data after changing l4d_hxstat_hide_flag ConVar since db is not update offline admins");
	
	RegConsoleCmd("sm_stat", 		CMD_stat,		"HX Statistics main menu");
	RegConsoleCmd("sm_rank", 		CMD_rank,		"Show my rank and all my stats");
	RegConsoleCmd("sm_rang", 		CMD_rank,		"-||-");
	RegConsoleCmd("sm_top", 		CMD_top,		"Show top players of all the time");
	RegConsoleCmd("sm_top10", 		CMD_top,		"-||-");
	RegConsoleCmd("sm_topweek", 	CMD_topWeek,	"Show top players of the week");
	
	#if DEBUG
	RegAdminCmd("sm_hx_refresh", CMD_Refresh, ADMFLAG_ROOT, "Force saving points to a database");
	#endif
	
	CreateTimer(60.0, HxTimer_Infinite, _, TIMER_REPEAT);
	
	if( g_bLateload )
	{
		g_iRoundStart = 1;
		g_bVipCoreLib = LibraryExists("vip_core");
		//OnConfigsExecuted(); // called by default
	}
	
	for( int i = 0; i < HX_POINTS_SIZE; i++ )
	{
		if( g_ConVarPoints[i] )
		{
			g_ConVarPoints[i].AddChangeHook(ConVarChanged);
		}
	}
	g_ConVarPointsAllowNegative.AddChangeHook(ConVarChanged);
	g_ConVarMenuName.AddChangeHook(ConVarChanged);
	g_ConVarPrintPoints.AddChangeHook(ConVarChanged);
	g_ConVarHideFlag.AddChangeHook(ConVarChanged);
	g_ConVarCommonsToKill.AddChangeHook(ConVarChanged);
	g_ConVarTimeToPlay.AddChangeHook(ConVarChanged);
	g_ConVarBaseMenu.AddChangeHook(ConVarChanged);
	g_ConVarVIPGroup.AddChangeHook(ConVarChanged);
	g_ConVarTableName.AddChangeHook(ConVarChanged);
	g_ConVarTableBackupName.AddChangeHook(ConVarChanged);
	g_ConVarFactorEasy.AddChangeHook(ConVarChanged);
	g_ConVarFactorNormal.AddChangeHook(ConVarChanged);
	g_ConVarFactorHard.AddChangeHook(ConVarChanged);
	g_ConVarFactorExpert.AddChangeHook(ConVarChanged);
	g_ConVarDifficulty.AddChangeHook(ConVarChanged);
	
	g_ConVarEnable.AddChangeHook(ConVarChanged_Allow);
	
	ReadConVars();
}

public void OnAllPluginsLoaded()
{
	g_bBaseMenuAvail = CommandExists(g_sBaseMenu);
}

public void OnPluginEnd()
{
	SQL_SaveAll(true);
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

public void ConVarChanged_Allow(ConVar convar, const char[] oldValue, const char[] newValue)
{
	g_bEnabled = g_ConVarEnable.BoolValue;
	InitHook();
}

public void ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	ReadConVars();
	
	if( convar == g_ConVarTableName )
	{
		HxSQL_RegisterClientAll();
	}
}

void ReadConVars()
{
	g_bEnabled = g_ConVarEnable.BoolValue;

	g_ConVarMenuName.GetString(g_sMenuName, sizeof(g_sMenuName));
	g_ConVarVIPGroup.GetString(g_sVIPGroup, sizeof(g_sVIPGroup));
	g_ConVarBaseMenu.GetString(g_sBaseMenu, sizeof(g_sBaseMenu));
	
	AdminFlag flag;
	static char sFlags[32];
	
	g_ConVarHideFlag.GetString(sFlags, sizeof(sFlags));
	g_iHiddenFlagBits = 0;
	
	for( int i = 0; i < strlen(sFlags); i++ )
	{
		if( FindFlagByChar(sFlags[i], flag) )
		{
			g_iHiddenFlagBits |= FlagToBit(flag);
		}
	}
	
	g_bPrintPoints = g_ConVarPrintPoints.BoolValue;
	g_iPointsTime = g_ConVarPoints[HX_TIME].IntValue;
	g_iPointsInfected = g_ConVarPoints[HX_INFECTED].IntValue;
	
	if( g_bL4D2 )
	{
		g_iPointsCharger = g_ConVarPoints[HX_CHARGER].IntValue;
		g_iPointsJockey = g_ConVarPoints[HX_JOCKEY].IntValue;
		g_iPointsSpitter = g_ConVarPoints[HX_SPITTER].IntValue;
	}
	g_iPointsBoomer = g_ConVarPoints[HX_BOOMER].IntValue;
	g_iPointsHunter = g_ConVarPoints[HX_HUNTER].IntValue;
	g_iPointsSmoker = g_ConVarPoints[HX_SMOKER].IntValue;
	g_iPointsTank = g_ConVarPoints[HX_TANK].IntValue;
	g_iPointsTankSolo = g_ConVarPoints[HX_TANK_SOLO].IntValue;
	g_iPointsWitch = g_ConVarPoints[HX_WITCH].IntValue;
	g_iPointsHeadShot = g_ConVarPoints[HX_HEADSHOT].IntValue;
	g_iCommonsToKill = g_ConVarCommonsToKill.IntValue;
	g_iTimeToPlay = g_ConVarTimeToPlay.IntValue;
	g_iPenaltyDeath = g_ConVarPoints[HX_PENALTY_DEATH].IntValue;
	g_iPenaltyIncap = g_ConVarPoints[HX_PENALTY_INCAP].IntValue;
	g_iPenaltyFF = g_ConVarPoints[HX_PENALTY_FF].IntValue;
	g_bAllowNegativePoints = g_ConVarPointsAllowNegative.BoolValue;
	
	g_ConVarTableName.GetString(HX_TABLE, sizeof(HX_TABLE));
	g_ConVarTableBackupName.GetString(HX_TABLE_BACKUP, sizeof(HX_TABLE_BACKUP));
	
	static char sDif[16];
	g_ConVarDifficulty.GetString(sDif, sizeof(sDif));
	if(strcmp(sDif, "Easy", false) == 0) {
		g_fFactor = g_ConVarFactorEasy.FloatValue;
	}
	else if (strcmp(sDif, "Normal", false) == 0) {
		g_fFactor = g_ConVarFactorNormal.FloatValue;
	}
	else if (strcmp(sDif, "Hard", false) == 0) {
		g_fFactor = g_ConVarFactorHard.FloatValue;
	}
	else if (strcmp(sDif, "Impossible", false) == 0) {
		g_fFactor = g_ConVarFactorExpert.FloatValue;
	}
	
	InitHook();
}

void InitHook()
{
	static bool bHookedOther, bHookedKbd, bHookedVote, bHookedIncap, bHookedHurt, bHookedTankKill;

	if( g_bEnabled )
	{
		if( !bHookedOther )
		{
			HookEvent("round_start", 			Event_RoundStart, 		EventHookMode_PostNoCopy);
			HookEvent("player_death", 			Event_PlayerDeath, 		EventHookMode_Pre);
			HookEvent("map_transition", 		Event_MapTransition, 	EventHookMode_PostNoCopy);
			HookEvent("finale_win", 			Event_MapTransition, 	EventHookMode_PostNoCopy);
			HookEvent("round_end", 				Event_SQL_Save, 		EventHookMode_PostNoCopy);
			HookEvent("player_disconnect", 		Event_PlayerDisconnect, EventHookMode_Pre);
			bHookedOther = true;
		}
		
		if( !bHookedIncap && g_iPenaltyIncap )
		{
			HookEvent("player_incapacitated",	Event_PlayerIncap, 		EventHookMode_Post);
			bHookedIncap = true;
		}
		if( !bHookedHurt && g_iPenaltyFF )
		{
			HookEvent("player_hurt",			Event_PlayerHurt, 		EventHookMode_Post);
			bHookedHurt = true;
		}
		if( !bHookedTankKill && g_iPointsTankSolo )
		{
			HookEvent("tank_killed",			Event_TankKilled, 		EventHookMode_Post);
			bHookedTankKill = true;
		}
		if( !bHookedKbd && g_ConVarIdleRank.BoolValue )
		{
			AddCommandListener(Listen_Keyboard, "go_away_from_keyboard");
			bHookedKbd = true;
		}
		if( !bHookedVote && g_ConVarVoteRank.BoolValue )
		{
			AddCommandListener(Listen_Callvote, "callvote");
			bHookedVote = true;
		}
	}
	
	if( ( !g_bEnabled || g_iPenaltyIncap == 0 ) && bHookedIncap )
	{		
		UnhookEvent("player_incapacitated",		Event_PlayerIncap, 		EventHookMode_Post);
		bHookedIncap = false;
	}
	if( ( !g_bEnabled || g_iPenaltyFF == 0 ) && bHookedHurt )
	{
		UnhookEvent("player_hurt",				Event_PlayerHurt, 		EventHookMode_Post);
		bHookedHurt = false;
	}
	if( ( !g_bEnabled || g_iPointsTankSolo == 0 ) && bHookedTankKill )
	{
		UnhookEvent("tank_killed",				Event_TankKilled, 		EventHookMode_Post);
		bHookedTankKill = false;
	}
	if( ( !g_bEnabled || !g_ConVarIdleRank.BoolValue ) && bHookedKbd )
	{
		RemoveCommandListener(Listen_Keyboard, "go_away_from_keyboard");
		bHookedKbd = false;
	}
	if( ( !g_bEnabled || !g_ConVarVoteRank.BoolValue ) && bHookedVote )
	{
		RemoveCommandListener(Listen_Callvote, "callvote");
		bHookedVote = false;
	}
	
	if( !g_bEnabled )
	{
		if( bHookedOther )
		{
			UnhookEvent("round_start", 				Event_RoundStart, 		EventHookMode_PostNoCopy);
			UnhookEvent("player_death", 			Event_PlayerDeath, 		EventHookMode_Pre);
			UnhookEvent("map_transition", 			Event_MapTransition, 	EventHookMode_PostNoCopy);
			UnhookEvent("finale_win", 				Event_MapTransition, 	EventHookMode_PostNoCopy);
			UnhookEvent("round_end", 				Event_SQL_Save, 		EventHookMode_PostNoCopy);
			UnhookEvent("player_disconnect", 		Event_PlayerDisconnect, EventHookMode_Pre);
			bHookedOther = false;
		}
		SQL_SaveAll(false);
	}
}

/* ==============================================================
						N A T I V E S
// ============================================================== */

public int NATIVE_AddPoints(Handle plugin, int numParams)
{
	if( numParams < 2 )
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int iClient = GetNativeCell(1);
	int iPoints = GetNativeCell(2);
	
	int iSource = HX_POINTS;
	if( numParams == 3 )
		iSource = GetNativeCell(3);
	
	if( !IsClientInGame(iClient) )
		ThrowNativeError(SP_ERROR_PARAM, "[HXStats] HX_AddPoints: client %i is not in game", iClient);
	
	g_iTemp[iClient][iSource] += iPoints;
	return 0;
}

public int NATIVE_GetPoints(Handle plugin, int numParams)
{
	if(numParams < 3)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int iClient = GetNativeCell(1);
	int iCounting = GetNativeCell(2);
	int iSource = GetNativeCell(3);
	
	if( iSource >= HX_POINTS_SIZE 	||
		iSource == HX_VIP_QUEUE		||
		iSource == HX_PENALTY_DEATH	||
		iSource == HX_PENALTY_INCAP	||
		iSource == HX_PENALTY_FF		)
		ThrowNativeError(SP_ERROR_PARAM, "[HXStats] HX_GetPoints: requested incompatible source type %i", iSource);
	
	if( !IsClientInGame(iClient) )
		ThrowNativeError(SP_ERROR_PARAM, "[HXStats] HX_GetPoints: client %i is not in game", iClient);
	
	switch( iCounting )
	{
		case HX_COUNTING_ROUND:
		{
			return g_iTemp[iClient][iSource];
		}
		case HX_COUNTING_START:
		{
			return g_iReal[iClient][iSource];
		}
		case HX_COUNTING_ACTUAL:
		{
			return g_iReal[iClient][iSource] + g_iTemp[iClient][iSource];
		}
	}
	
	ThrowNativeError(SP_ERROR_PARAM, "[HXStats] HX_GetPoints: counting argument is wrong: %i", iCounting);
	return 0;
}

public int NATIVE_IsClientRegistered(Handle plugin, int numParams)
{
	if(numParams < 1)
		ThrowNativeError(SP_ERROR_PARAM, "Invalid numParams");
	
	int iClient = GetNativeCell(1);
	return g_bClientRegistered[iClient] ? 1 : 0;
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

public Action Timer_SQL_ReConnect(Handle timer)
{
	OnConfigsExecuted();
	return Plugin_Continue;
}

public void SQL_Callback_Connect (Database db, const char[] error, any data)
{
	g_hDB = db;
	if( !db )
	{
		#if DEBUG
			LogError("%s", error);
		#endif
	
		/* // this walkaround doesn't work for some reason
		
		const int MAX_ATTEMPT = 20;
		static int iAttempt;
		
		++iAttempt;
		LogError("Attempt #%i. %s", iAttempt, error);
		
		if (iAttempt < MAX_ATTEMPT)
		{
			CreateTimer(3.0, Timer_SQL_ReConnect, _, TIMER_FLAG_NO_MAPCHANGE);
		}
		else {
			iAttempt = 0;
		}
		*/
		return;
	}
	SQL_OnConnected();
}

void SQL_OnConnected()
{
	//ShiftWeekMonthPoints();
	
	if( g_bLateload )
	{
		HxSQL_RegisterClientAll();
	}
}

public void OnMapStart()
{
	ShiftWeekMonthPoints();
}

void ShiftWeekMonthPoints()
{
	if( !g_hDB )
		return;
	RequestLastUpdateTime();
}

public void	SQL_OnUpdateTimeRequested(int iWeekUpdate, int iMonthUpdate)
{
	Transaction tx;
	int iUpdateType;
	
	int iUnixFirstWeekDay = GetFirstWeekDay();
	int iUnixFirstMonthDay = GetFirstMonthDay();
	
	if( iWeekUpdate < iUnixFirstWeekDay )
	{		
		if( g_ConVarWeekBackup.BoolValue )
		{
			if( g_ConVarWeekBackupRewrite.BoolValue )
			{
				MakeBackup(0, 1, HX_TABLE_BACKUP);
			}
			else {
				char sTable[64];
				FormatTime(sTable, sizeof(sTable), "%F", GetTime());
				Format(sTable, sizeof(sTable), "%s_%s", HX_TABLE_BACKUP, sTable);
				MakeBackup(0, 0, sTable);
			}
		}
		
		FormatEx(g_sQuery1, sizeof(g_sQuery1),
			"UPDATE `%s` SET \
			Time1 = %i \
			WHERE `Steamid` = '%s'"
			, HX_TABLE
			, GetTime()
			, HX_SERVICE_STEAM);
		
		FormatEx(g_sQuery2, sizeof(g_sQuery2),
			"UPDATE `%s` SET Pt_lweek = Pt_week", HX_TABLE);
		
		FormatEx(g_sQuery3, sizeof(g_sQuery3),
			"UPDATE `%s` SET Pt_week = 0", HX_TABLE);
		
		tx = new Transaction();
		tx.AddQuery(g_sQuery1);
		tx.AddQuery(g_sQuery2);
		tx.AddQuery(g_sQuery3);
		
		iUpdateType |= 1;
		
		#if defined _vip_core_included
		if( g_ConVarAwardTopWeekVIP.IntValue != 0 )
		{
			FormatEx(g_sQuery3, sizeof(g_sQuery3),
				"UPDATE `%s` \
				SET VipQueue = VipQueue + %i \
				WHERE `Hide` = 0 \
				ORDER BY `Pt_lweek` DESC LIMIT %i", HX_TABLE, g_ConVarAwardTopWeekVIP.IntValue, g_ConVarLimitTopWeekVIP.IntValue);
			tx.AddQuery(g_sQuery3);
		}
		#endif
	}
	
	if( iMonthUpdate < iUnixFirstMonthDay )
	{
		FormatEx(g_sQuery1, sizeof(g_sQuery1),
			"UPDATE `%s` SET \
			Time2 = %i \
			WHERE `Steamid` = '%s'"
			, HX_TABLE
			, GetTime()
			, HX_SERVICE_STEAM);
	
		FormatEx(g_sQuery2, sizeof(g_sQuery2),
			"UPDATE `%s` SET Pt_lmonth = Pt_month", HX_TABLE);
			
		FormatEx(g_sQuery3, sizeof(g_sQuery3),
			"UPDATE `%s` SET Pt_month = 0", HX_TABLE);
		
		if( !tx )
		{
			tx = new Transaction();
		}
		tx.AddQuery(g_sQuery1);
		tx.AddQuery(g_sQuery2);
		tx.AddQuery(g_sQuery3);
		
		iUpdateType |= 2;
		
		#if defined _vip_core_included
		if( g_ConVarAwardTopMonthVIP.IntValue != 0 )
		{
			FormatEx(g_sQuery3, sizeof(g_sQuery3),
				"UPDATE `%s` \
				SET VipQueue = VipQueue + %i \
				WHERE `Hide` = 0 \
				ORDER BY `Pt_lmonth` DESC LIMIT %i", HX_TABLE, g_ConVarAwardTopMonthVIP.IntValue, g_ConVarLimitTopMonthVIP.IntValue);
			tx.AddQuery(g_sQuery3);
		}
		#endif
	}
	
	if( tx )
	{
		g_hDB.Execute(tx, SQL_Tx_SuccessWeekMonth, SQL_Tx_SuccessWeekMonth_Failure, iUpdateType);
	}
}

public void SQL_Tx_SuccessWeekMonth (Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	int iUpdateType = data;
	if( iUpdateType & 1 )
	{
		ShowTop(0, PERIOD_LAST_WEEK, true);
	}
	if( iUpdateType & 2 )
	{
		ShowTop(0, PERIOD_LAST_MONTH, true);
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
	g_bClientRegistered[client] = false;
	HxClean(client);
}

public void Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	int client = GetClientOfUserId(event.GetInt("userid"));
	g_bRankDisplayed[client] = false;
	
	if (client && IsClientInGame(client) && !IsFakeClient(client) && !g_bInDisconnect[client] )
	{
		g_bInDisconnect[client] = true;
		
		SQL_Save(client);
	}
}

public void OnMapEnd()
{
	// This doesn't work because clients are already not in game
	//SQL_SaveAll(true);
}

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
}

public void Event_PlayerHurt(Event event, const char[] name, bool dontBroadcast)
{
	if (g_iPenaltyFF == 0)
		return;
	
	int iVictim = GetClientOfUserId(event.GetInt("userid"));
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));
	
	if( iVictim == iAttacker)
		return;
	
	if( iVictim && !IsFakeClient(iVictim) && GetClientTeam(iVictim) == 2 )
	{
		if( iAttacker && !IsFakeClient(iAttacker) && GetClientTeam(iAttacker) == 2 )
		{
			int iDmg = event.GetInt("dmg_health");
			float iDmgRest = float(iDmg % 10);
			
			int iPenalty = RoundToFloor(iDmg / 10 * g_iPenaltyFF / g_fFactor);
			g_fPenaltyBonus[iAttacker] += iDmgRest / 10.0 * g_iPenaltyFF / g_fFactor;
			
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
	
	if( iVictim && !IsFakeClient(iVictim) && GetClientTeam(iVictim) == 2 ) // Real survivor is incapacitated
	{
		int iPenalty = RoundToFloor(g_iPenaltyIncap / g_fFactor);
		g_iTemp[iVictim][HX_PENALTY] += iPenalty;
		g_iTemp[iVictim][HX_POINTS] += iPenalty;
		PrintPoints(iVictim, "%t", "PenaltyIncap-", iPenalty);
	}
}

public void Event_TankKilled(Event event, const char[] name, bool dontBroadcast)
{
	if( g_iPointsTankSolo && event.GetBool("solo") )
	{
		int iAttacker = GetClientOfUserId(event.GetInt("attacker"));	/* User ID который убил */
		if( iAttacker && GetClientTeam(iAttacker) == 2 )
		{
			int iPoints = RoundToCeil(g_iPointsTankSolo * g_fFactor);
			g_iTemp[iAttacker][HX_TANK_SOLO] += 1;
			g_iTemp[iAttacker][HX_POINTS] += iPoints;
			PrintPoints(iAttacker, "%t", "TankSolo+", iPoints);
		}
	}
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
	int iPoints;
	int iVictim = GetClientOfUserId(event.GetInt("userid"));	/* User ID который умер */
	
	if (iVictim && g_iPenaltyDeath && !IsFakeClient(iVictim) && GetClientTeam(iVictim) == 2) // Real survivor is killed
	{
		int iPenalty = RoundToFloor(g_iPenaltyDeath / g_fFactor);
		g_iTemp[iVictim][HX_PENALTY] += iPenalty;
		g_iTemp[iVictim][HX_POINTS] += iPenalty;
		PrintPoints(iVictim, "%t", "PenaltyDeath-", iPenalty);
		return;
	}
	
	int iAttacker = GetClientOfUserId(event.GetInt("attacker"));	/* User ID который убил */
	
	if (iAttacker && iAttacker != iVictim)
	{
		if (!IsFakeClient(iAttacker) && GetClientTeam(iAttacker) == 2) // Attacker is not a bot
		{
			bool bHeadShot = event.GetBool("headshot");

			event.GetString("victimname", g_sBuf3, sizeof(g_sBuf3));

			#if DEBUG
			PrintToChat(iAttacker, "Victim: %s", g_sBuf3);
			#endif
			
			if (g_sBuf3[0] == 'I' )
			{		/* Common Infected */
				bHeadShot = false;
				
				if( g_iPointsInfected )
				{
					if ((g_iTemp[iAttacker][HX_INFECTED] += 1) % g_iCommonsToKill == 0 && g_iCommonsToKill)
					{
						iPoints = RoundToCeil(g_iPointsInfected * g_fFactor);
						g_iTemp[iAttacker][HX_POINTS] += iPoints;
						PrintPoints(iAttacker, "%t", "Infected+", g_iCommonsToKill, iPoints);
					}
				}
			}
			else if (g_sBuf3[0] == 'B')
			{		/* Boomer */
				if( g_iPointsBoomer )
				{
					iPoints = RoundToCeil(g_iPointsBoomer * g_fFactor);
					g_iTemp[iAttacker][HX_BOOMER] += 1;
					g_iTemp[iAttacker][HX_POINTS] += iPoints;
					PrintPoints(iAttacker, "%t", "Boomer+", iPoints);
				}
			}
			else if (g_sBuf3[0] == 'S')
			{
				if (g_sBuf3[1] == 'm')
				{		/* Smoker */
					if( g_iPointsSmoker )
					{
						iPoints = RoundToCeil(g_iPointsSmoker * g_fFactor);
						g_iTemp[iAttacker][HX_SMOKER] += 1;
						g_iTemp[iAttacker][HX_POINTS] += iPoints;
						PrintPoints(iAttacker, "%t", "Smoker+", iPoints);
					}
				}
				else if (g_sBuf3[1] == 'p')
				{		/* Spitter */
					if( g_iPointsSpitter )
					{
						iPoints = RoundToCeil(g_iPointsSpitter * g_fFactor);
						g_iTemp[iAttacker][HX_SPITTER] += 1;
						g_iTemp[iAttacker][HX_POINTS] += iPoints;
						PrintPoints(iAttacker, "%t", "Spitter+", iPoints);
					}
				}
			}
			else if (g_sBuf3[0] == 'H')
			{		/* Hunter */
				if( g_iPointsHunter )
				{
					iPoints = RoundToCeil(g_iPointsHunter * g_fFactor);
					g_iTemp[iAttacker][HX_HUNTER] += 1;
					g_iTemp[iAttacker][HX_POINTS] += iPoints;
					PrintPoints(iAttacker, "%t", "Hunter+", iPoints);
				}
			}
			else if (g_sBuf3[0] == 'T')
			{		/* Tank */
				if( g_iPointsTank )
				{
					iPoints = RoundToCeil(g_iPointsTank * g_fFactor);
					g_iTemp[iAttacker][HX_TANK] += 1;
					g_iTemp[iAttacker][HX_POINTS] += iPoints;
					PrintPoints(iAttacker, "%t", "Tank+", iPoints);
				}
			}
			else if (g_sBuf3[0] == 'W')
			{		/* Witch */
				if( g_iPointsWitch )
				{
					iPoints = RoundToCeil(g_iPointsWitch * g_fFactor);
					g_iTemp[iAttacker][HX_WITCH] += 1;
					g_iTemp[iAttacker][HX_POINTS] += iPoints;
					PrintPoints(iAttacker, "%t", "Witch+", iPoints);
				}
			}
			else if (g_bL4D2)
			{
				if (g_sBuf3[0] == 'J')
				{		/* Jockey */
					if( g_iPointsJockey )
					{
						iPoints = RoundToCeil(g_iPointsJockey * g_fFactor);
						g_iTemp[iAttacker][HX_JOCKEY] += 1;
						g_iTemp[iAttacker][HX_POINTS] += iPoints;
						PrintPoints(iAttacker, "%t", "Jockey+", iPoints);
					}
				}
				else if (g_sBuf3[0] == 'C')
				{		/* Charger */
					if( g_iPointsCharger )
					{
						iPoints = RoundToCeil(g_iPointsCharger * g_fFactor);
						g_iTemp[iAttacker][HX_CHARGER] += 1;
						g_iTemp[iAttacker][HX_POINTS] += iPoints;
						PrintPoints(iAttacker, "%t", "Charger+", iPoints);
					}
				}
			}
			
			if( bHeadShot )
			{
				if( g_iPointsHeadShot )
				{
					iPoints = RoundToCeil(g_iPointsHeadShot * g_fFactor);
					g_iTemp[iAttacker][HX_HEADSHOT] += 1;
					g_iTemp[iAttacker][HX_POINTS] += iPoints;
					PrintPoints(iAttacker, "%t", "HeadShot+", iPoints);
				}
			}
		}
	}
}

/* ==============================================================
					T I M E R S
// ============================================================== */

public Action HxTimer_Connected(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if( client && IsClientInGame(client) )
	{
		static char s[192];
		
		if( g_ConVarShowRankInChat.BoolValue )
		{
			FormatEx(s, sizeof(s), "%T", "Join_Rank_InChat", client);
			BuildPointsString(client, s, sizeof(s));
			CPrintToChat(client, s);
		}
		if( g_ConVarShowRankInChatToAll.BoolValue && !g_bRankDisplayed[client] )
		{
			for( int i = 1; i <= MaxClients; i++ )
			{
				if( i == client ) // don't duplicate msg twice
				{
					continue;
				}
				if( IsClientInGame(i) && !IsFakeClient(i) )
				{
					FormatEx(s, sizeof(s), "%T", "Join_Rank_InChatAll", i);
					BuildPointsString(client, s, sizeof(s));
					CPrintToChat(i, s);
				}
			}
		}
		
		if( g_ConVarShowRankInCenter.BoolValue )
		{
			FormatEx(s, sizeof(s), "%T", "Join_Rank_InCenter", client);
			BuildPointsString(client, s, sizeof(s));
			CPrintHintText(client, s);
		}
		if( g_ConVarShowRankInPanel.BoolValue )
		{	
			CMD_rank(client, 0);
		}
		g_bRankDisplayed[client] = true;
	}
	return Plugin_Continue;
}

char[] IntToStringEx(int v)
{
	static char s[16];
	IntToString(v, s, sizeof(s));
	return s;
}

void BuildPointsString(int client, char[] str, int length)
{
	char sName[MAX_NAME_LENGTH];
	FormatEx(sName, sizeof(sName), "%N", client);
	if( g_bL4D2 )
	{
		ReplaceString(str, length, "HX_CHARGER", IntToStringEx(g_iReal[client][HX_CHARGER]), true);
		ReplaceString(str, length, "HX_JOCKEY", IntToStringEx(g_iReal[client][HX_JOCKEY]), true);
		ReplaceString(str, length, "HX_SPITTER", IntToStringEx(g_iReal[client][HX_SPITTER]), true);
	}
	ReplaceString(str, length, "HX_TIME", IntToStringEx(g_iReal[client][HX_TIME]), true);
	ReplaceString(str, length, "HX_BOOMER", IntToStringEx(g_iReal[client][HX_BOOMER]), true);
	ReplaceString(str, length, "HX_HUNTER", IntToStringEx(g_iReal[client][HX_HUNTER]), true);
	ReplaceString(str, length, "HX_INFECTED", IntToStringEx(g_iReal[client][HX_INFECTED]), true);
	ReplaceString(str, length, "HX_SMOKER", IntToStringEx(g_iReal[client][HX_SMOKER]), true);
	ReplaceString(str, length, "HX_TANK_SOLO", IntToStringEx(g_iReal[client][HX_TANK_SOLO]), true);
	ReplaceString(str, length, "HX_TANK", IntToStringEx(g_iReal[client][HX_TANK]), true);
	ReplaceString(str, length, "HX_WITCH", IntToStringEx(g_iReal[client][HX_WITCH]), true);
	ReplaceString(str, length, "HX_HEADSHOT", IntToStringEx(g_iReal[client][HX_HEADSHOT]), true);
	ReplaceString(str, length, "HX_POINTS_MONTH", IntToStringEx(g_iReal[client][HX_POINTS_MONTH]), true);
	ReplaceString(str, length, "HX_POINTS_WEEK", IntToStringEx(g_iReal[client][HX_POINTS_WEEK]), true);
	ReplaceString(str, length, "HX_POINTS_LAST_MONTH", IntToStringEx(g_iReal[client][HX_POINTS_LAST_MONTH]), true);
	ReplaceString(str, length, "HX_POINTS_LAST_WEEK", IntToStringEx(g_iReal[client][HX_POINTS_LAST_WEEK]), true);
	ReplaceString(str, length, "HX_PENALTY_DEATH", IntToStringEx(g_iReal[client][HX_PENALTY_DEATH]), true);	
	ReplaceString(str, length, "HX_PENALTY", IntToStringEx(g_iReal[client][HX_PENALTY]), true);	
	ReplaceString(str, length, "HX_PENALTY_INCAP", IntToStringEx(g_iReal[client][HX_PENALTY_INCAP]), true);	
	ReplaceString(str, length, "HX_PENALTY_FF", IntToStringEx(g_iReal[client][HX_PENALTY_FF]), true);	
	ReplaceString(str, length, "HX_POINTS", IntToStringEx(g_iReal[client][HX_POINTS]), true);
	ReplaceString(str, length, "HX_PLACE_WEEK", IntToStringEx(g_iReal[client][HX_PLACE_WEEK]), true);
	ReplaceString(str, length, "HX_PLACE", IntToStringEx(g_iReal[client][HX_PLACE]), true);
	ReplaceString(str, length, "PLAYER_NAME", sName, true);
}

public Action HxTimer_ClientPost(Handle timer, int UserId)
{
	int client = GetClientOfUserId(UserId);
	
	if (client && IsClientInGame(client))
	{
		HxSQL_RegisterClient(client);
	}
	return Plugin_Continue;
}

public Action HxTimer_Infinite(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			if (GetClientTeam(i) != 1)
			{
				if ( (g_iTemp[i][HX_TIME] += 1) % g_iTimeToPlay == 0 && g_iTimeToPlay && g_iPointsTime)
				{
					int iPoints = RoundToCeil(g_iPointsTime * g_fFactor);
					g_iTemp[i][HX_POINTS] += iPoints;
					PrintPoints(i, "%t", "min. in game+", g_iTimeToPlay, iPoints);
				}
			}
		}
		else
		{
			g_iTemp[i][HX_TIME] = 0;
		}
	}
	return Plugin_Continue;
}

/* ==============================================================
						S Q L
// ============================================================== */

public Action CMD_Upgrade(int client, int args)
{
	if (!g_hDB) {
		LogError("sm_hx_upgrade %T", "No_Connection", client); // failed! No connection to Database.
		return Plugin_Handled;
	}
	
	/*
	Transaction tx = new Transaction();
	
	PrepareInsertColumn(tx, "Pt_month", 	"int(11) NOT NULL DEFAULT '0' AFTER `Points`");
	PrepareInsertColumn(tx, "Pt_week", 		"int(11) NOT NULL DEFAULT '0' AFTER `Pt_month`");
	PrepareInsertColumn(tx, "Pt_lmonth", 	"int(11) NOT NULL DEFAULT '0' AFTER `Pt_week`");
	PrepareInsertColumn(tx, "Pt_lweek", 	"int(11) NOT NULL DEFAULT '0' AFTER `Pt_lmonth`");
	PrepareInsertColumn(tx, "VipQueue", 	"int(11) NOT NULL DEFAULT '0' AFTER `Time2`");
	PrepareInsertColumn(tx, "Penalty", 		"int(11) NOT NULL DEFAULT '0' AFTER `VipQueue`");
	PrepareInsertColumn(tx, "Hide", 		"SMALLINT NOT NULL DEFAULT '0' AFTER `Penalty`");
	PrepareInsertColumn(tx, "TankSolo", 	"int(11) NOT NULL DEFAULT '0' AFTER `Tank`");
	PrepareInsertColumn(tx, "HeadShot", 	"int(11) NOT NULL DEFAULT '0' AFTER `Witch`");
	
	FormatEx(g_sQuery1, sizeof(g_sQuery1), "ALTER TABLE `%s` ENGINE = InnoDB", HX_TABLE);
	tx.AddQuery(g_sQuery1);
	
	g_hDB.Execute(tx, SQL_Tx_UpgradeSuccess, SQL_Tx_UpgradeFailure, GetClientUserId(client));
	*/
	
	InsertColumn("Pt_month", 	"int(11) NOT NULL DEFAULT '0' AFTER `Points`");
	InsertColumn("Pt_week", 	"int(11) NOT NULL DEFAULT '0' AFTER `Pt_month`");
	InsertColumn("Pt_lmonth", 	"int(11) NOT NULL DEFAULT '0' AFTER `Pt_week`");
	InsertColumn("Pt_lweek", 	"int(11) NOT NULL DEFAULT '0' AFTER `Pt_lmonth`");
	InsertColumn("VipQueue", 	"int(11) NOT NULL DEFAULT '0' AFTER `Time2`");
	InsertColumn("Penalty", 	"int(11) NOT NULL DEFAULT '0' AFTER `VipQueue`");
	InsertColumn("Hide", 		"SMALLINT NOT NULL DEFAULT '0' AFTER `Penalty`");
	InsertColumn("TankSolo", 	"int(11) NOT NULL DEFAULT '0' AFTER `Tank`");
	InsertColumn("HeadShot", 	"int(11) NOT NULL DEFAULT '0' AFTER `Witch`");
	
	FormatEx(g_sQuery1, sizeof(g_sQuery1), "ALTER TABLE `%s` ENGINE = InnoDB", HX_TABLE);
	
	#if DEBUG_SQL
		DataPack dp = new DataPack();
		dp.WriteString(g_sQuery1);
		g_hDB.Query(SQL_CallbackUpgrade, g_sQuery1, dp);
	#else
		g_hDB.Query(SQL_CallbackUpgrade, g_sQuery1);
	#endif
	
	PrintToConsoles(client, "%t", "Upgrade_Process"); // Database upgrade sent for processing.
	
	CreateTimer(5.0, Timer_UpdateClients, _, TIMER_FLAG_NO_MAPCHANGE);
	
	return Plugin_Handled;
}

public Action Timer_UpdateClients(Handle timer)
{
	HxSQL_RegisterClientAll();
	return Plugin_Continue;
}

/*
void PrepareInsertColumn(Transaction tx, char[] sColumn, char[] sCmd)
{
	FormatEx(g_sQuery1, sizeof(g_sQuery1), "ALTER TABLE `%s` ADD COLUMN `%s` %s", HX_TABLE, sColumn, sCmd);
	tx.AddQuery(g_sQuery1);
}

public void SQL_Tx_UpgradeSuccess (Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	PrintToConsoles(GetClientOfUserId(data), "%t", "Upgrade_Success");
	HxSQL_RegisterClientAll();
}
*/

void InsertColumn(char[] sColumn, char[] sCmd)
{
	DataPack dp = new DataPack();
	char sPack[128];
	FormatEx(sPack, sizeof(sPack), "ADD COLUMN `%s` %s", sColumn, sCmd);

	dp.WriteString(sPack);

	FormatEx(g_sQuery1, sizeof(g_sQuery1)
	 , "SELECT COUNT(*) \
		FROM INFORMATION_SCHEMA.COLUMNS \
		WHERE table_name = '%s' \
		AND column_name = '%s'", HX_TABLE, sColumn);
	
	g_hDB.Query(SQL_Callback_InsertColumn, g_sQuery1, dp);
}

public void SQL_Callback_InsertColumn (Database db, DBResultSet hQuery, const char[] error, any data)
{
	char sInsert[128];
	DataPack dp = view_as<DataPack>(data);
	dp.Reset();
	dp.ReadString(sInsert, sizeof(sInsert));
	delete dp;
	
	if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	if (hQuery.FetchRow())
	{
		if (hQuery.FetchInt(0) == 0)
		{
			FormatEx(g_sQuery1, sizeof(g_sQuery1), "ALTER TABLE `%s` %s", HX_TABLE, sInsert);

			#if DEBUG_SQL
				dp = new DataPack();
				dp.WriteString(g_sQuery1);
				g_hDB.Query(SQL_CallbackInsertColumn, g_sQuery1, dp);
			#else
				g_hDB.Query(SQL_CallbackInsertColumn, g_sQuery1);
			#endif
		}
	}
}

public void SQL_Tx_UpgradeFailure (Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogStackTrace("%s", error);
	PrintToConsoles(GetClientOfUserId(data), "%t", "Upgrade_Failed");
}

public Action CMD_Backup( int client, int args ) // sm_backup <overwrite> <table_name>
{
	char buf[4], sBackupTableName[64];
	
	int iDropTable = 1;
	strcopy(sBackupTableName, sizeof(sBackupTableName), HX_TABLE_BACKUP);
	
	if (args >= 1)
	{
		GetCmdArg(1, buf, sizeof(buf));
		iDropTable = StringToInt(buf);
	}
	if (args >= 2)
	{
		GetCmdArg(2, sBackupTableName, sizeof(sBackupTableName));
	}
	MakeBackup(client, iDropTable, sBackupTableName);
	return Plugin_Handled;
}

void MakeBackup( int client, int iDropTable, char[] sBackupTableName)
{
	Transaction tx = new Transaction();
	
	if (iDropTable)
	{
		FormatEx(g_sQuery1, sizeof(g_sQuery1), "DROP TABLE IF EXISTS `%s`", sBackupTableName);
		tx.AddQuery(g_sQuery1);
	}
	
	FormatEx(g_sQuery2, sizeof(g_sQuery2), "CREATE TABLE `%s` LIKE `%s`", sBackupTableName, HX_TABLE);
	tx.AddQuery(g_sQuery2);
	
	FormatEx(g_sQuery3, sizeof(g_sQuery3), "INSERT `%s` SELECT * FROM `%s`", sBackupTableName, HX_TABLE);
	tx.AddQuery(g_sQuery3);
	
	DataPack dp = new DataPack();
	dp.WriteCell(client == 0 ? 0 : GetClientUserId(client));
	dp.WriteString(sBackupTableName);
	
	g_hDB.Execute(tx, SQL_Tx_BackupSuccess, SQL_Tx_BackupFailure, dp);
}

public void SQL_Tx_BackupSuccess (Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	DataPack dp = data;
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	char sBackupTableName[64];
	dp.ReadString(sBackupTableName, sizeof(sBackupTableName));
	delete dp;
	
	PrintToConsoles(client, "%t (%s => %s)", "Backup_Success", HX_TABLE, sBackupTableName); // Backup is success.
}

public void SQL_Tx_BackupFailure (Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	DataPack dp = data;
	dp.Reset();
	PrintToConsoles(GetClientOfUserId(dp.ReadCell()), "%t", "Backup_FAILED");
	delete dp;
	LogStackTrace("%s", error);
}

public Action CMD_Revert( int client, int args)
{
	FormatEx(g_sQuery1, sizeof(g_sQuery1), "DROP TABLE IF EXISTS `%s`", HX_TABLE);
	FormatEx(g_sQuery2, sizeof(g_sQuery2), "CREATE TABLE IF NOT EXISTS `%s` LIKE `%s`", HX_TABLE, HX_TABLE_BACKUP);
	FormatEx(g_sQuery3, sizeof(g_sQuery3), "INSERT `%s` SELECT * FROM `%s`", HX_TABLE, HX_TABLE_BACKUP);
	
	Transaction tx = new Transaction();
	tx.AddQuery(g_sQuery1);
	tx.AddQuery(g_sQuery2);
	tx.AddQuery(g_sQuery3);
	g_hDB.Execute(tx, SQL_Tx_SuccessRevert, SQL_Tx_RevertFailure, GetClientUserId(client));
	return Plugin_Handled;
}

public void SQL_Tx_SuccessRevert (Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
	HxSQL_RegisterClientAll();
	PrintToConsoles(GetClientOfUserId(data), "%t (%s => %s)", "Revert_Success", HX_TABLE_BACKUP, HX_TABLE); // Revert is success.
}

public void SQL_Tx_RevertFailure (Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogStackTrace("%s", error);
	PrintToConsoles(GetClientOfUserId(data), "%t", "Revert_FAILED"); // Revert is FAILURE !!!"
}

void RequestLastUpdateTime()
{
	// week		(column `Time1`)
	// month	(column `Time2`)
	
	FormatEx(g_sQuery1, sizeof(g_sQuery1)
	 , "SELECT SQL_NO_CACHE \
		Time1, \
		Time2 \
		FROM `%s` WHERE `Steamid` = '%s'", HX_TABLE, HX_SERVICE_STEAM);
	
	#if DEBUG_SQL
		DataPack dp = new DataPack();
		dp.WriteString(g_sQuery1);
		g_hDB.Query(SQL_Callback_RequestUpdateTime, g_sQuery1, dp);
	#else
		g_hDB.Query(SQL_Callback_RequestUpdateTime, g_sQuery1);
	#endif
}

public void SQL_Callback_RequestUpdateTime (Database db, DBResultSet hQuery, const char[] error, any data)
{
	#if DEBUG_SQL
		DataPack dp = view_as<DataPack>(data);
		if (!db || !hQuery) {
			char query[640];
			dp.Reset();
			dp.ReadString(query, sizeof(query));
			LogStackTrace("Query: \"%s\". Error: %s", query, error);
			delete dp;
			return;
		}
		delete dp;
	#else
		if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	#endif
	
	if (!hQuery.FetchRow())
	{
		FormatEx(g_sQuery1, sizeof(g_sQuery1), "INSERT INTO `%s` (`Name`,`Time1`,`Time2`,`Steamid`,`Hide`) VALUES ('%s',%i,%i,'%s',1)", HX_TABLE, HX_SERVICE_USER, GetTime(), GetTime(), HX_SERVICE_STEAM);
		
		#if DEBUG_SQL
			dp = new DataPack();
			dp.WriteString(g_sQuery1);
			g_hDB.Query(SQL_CallbackRequestUpdateTime, g_sQuery1, dp);
		#else
			g_hDB.Query(SQL_CallbackRequestUpdateTime, g_sQuery1);
		#endif
	}
	else {
		int iWeekUpdate = hQuery.FetchInt(0);
		int iMonthUpdate = hQuery.FetchInt(1);
		SQL_OnUpdateTimeRequested(iWeekUpdate, iMonthUpdate);
	}
}

void HxSQL_RegisterClientAll()
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			HxSQL_RegisterClient(i);
		}
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
		TankSolo, \
		Witch, \
		HeadShot, \
		Pt_month, \
		Pt_week, \
		Pt_lmonth, \
		Pt_lweek, \
		VipQueue, \
		Penalty, \
		Hide, \
		Name \
		FROM `%s` WHERE `Steamid` = '%s'", HX_TABLE, g_sSteamId[client]);
	
	g_hDB.Query(SQL_Callback_RegisterClient, g_sQuery1, client == 0 ? 0 : GetClientUserId(client));
}

public void SQL_Callback_RegisterClient (Database db, DBResultSet hQuery, const char[] error, any data)
{
	if (!hQuery)
	{
		if (StrContains(error, "Table") != -1 && StrContains(error, "doesn't exist") != -1)
		{
			PrintToChatAll(error);
			//LogError("[HxStats] If this error happened once upon plugin installation, it is normally, and you need to change the map.");
			HxSQL_CreateTable();
			return;
		}
	}
	if (!db || !hQuery) { LogStackTrace("%s", error); return; }
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
			"INSERT INTO `%s` SET \
			Name = '%s', \
			Time2 = %d, \
			Steamid = '%s'"
			, HX_TABLE
			, sName
			, GetTime()
			, g_sSteamId[client]);
		
		#if DEBUG_SQL
			DataPack dp = new DataPack();
			dp.WriteString(g_sQuery1);
			db.Query(SQL_CallbackCreateClient, g_sQuery1, dp);
		#else
			db.Query(SQL_CallbackCreateClient, g_sQuery1);
		#endif
	}
	else
	{
		g_iReal[client][HX_POINTS]   			= hQuery.FetchInt(1);
		g_iReal[client][HX_TIME]     			= hQuery.FetchInt(2);
		g_iReal[client][HX_BOOMER]   			= hQuery.FetchInt(3);
		g_iReal[client][HX_CHARGER]  			= hQuery.FetchInt(4);
		g_iReal[client][HX_HUNTER]   			= hQuery.FetchInt(5);
		g_iReal[client][HX_INFECTED] 			= hQuery.FetchInt(6);
		g_iReal[client][HX_JOCKEY]   			= hQuery.FetchInt(7);
		g_iReal[client][HX_SMOKER]   			= hQuery.FetchInt(8);
		g_iReal[client][HX_SPITTER]  			= hQuery.FetchInt(9);
		g_iReal[client][HX_TANK]     			= hQuery.FetchInt(10);
		g_iReal[client][HX_TANK_SOLO]    		= hQuery.FetchInt(11);
		g_iReal[client][HX_WITCH]    			= hQuery.FetchInt(12);
		g_iReal[client][HX_HEADSHOT]    		= hQuery.FetchInt(13);
		g_iReal[client][HX_POINTS_MONTH]   		= hQuery.FetchInt(14);
		g_iReal[client][HX_POINTS_WEEK]    		= hQuery.FetchInt(15);
		g_iReal[client][HX_POINTS_LAST_MONTH]   = hQuery.FetchInt(16);
		g_iReal[client][HX_POINTS_LAST_WEEK]    = hQuery.FetchInt(17);
		g_iReal[client][HX_VIP_QUEUE]    		= hQuery.FetchInt(18);
		g_iReal[client][HX_PENALTY]    			= hQuery.FetchInt(19);
		g_iReal[client][HX_HIDE]    			= hQuery.FetchInt(20);
		hQuery.FetchString						(21, g_sName[client], sizeof(g_sName[]));
		
		FormatEx(g_sQuery1, sizeof(g_sQuery1), 
					"SELECT COUNT(*)+1 FROM `%s` WHERE Points > \
					(SELECT Points FROM `%s` WHERE `Steamid` = '%s') AND `Hide` = 0 \
					UNION \
					SELECT COUNT(*)+1 FROM `%s` WHERE Pt_week > \
					(SELECT Pt_week FROM `%s` WHERE `Steamid` = '%s') AND `Hide` = 0"
					, HX_TABLE, HX_TABLE, g_sSteamId[client],
					HX_TABLE, HX_TABLE, g_sSteamId[client]);
		
		db.Query(SQL_CallbackPlace, g_sQuery1, data);
		
		if (client == 0) // for service requested SteamId
		{
			return;
		}
		
		UpdateHiddenFlag(client);
		
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

#if defined _vip_core_included
Action Timer_GiveAwardVIP(Handle timer, DataPack dp)
{
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int days = dp.ReadCell();
	
	if (client && IsClientInGame(client))
	{
		if (GiveVIP(client, days))
		{
			FormatEx(g_sQuery2, sizeof(g_sQuery2), "UPDATE `%s` SET VipQueue = 0 WHERE `Steamid` = '%s'", HX_TABLE, g_sSteamId[client]);
			
			#if DEBUG_SQL
				DataPack dp2 = new DataPack();
				dp2.WriteString(g_sQuery2);
				g_hDB.Query(SQL_CallbackGiveAwardVIP, g_sQuery2, dp2);
			#else
				g_hDB.Query(SQL_CallbackGiveAwardVIP, g_sQuery2);
			#endif
		}
	}
	return Plugin_Continue;
}
#endif

public void SQL_CallbackPlace (Database db, DBResultSet hQuery, const char[] error, any data)
{
	if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	int client = GetClientOfUserId(data); //if (!client || !IsClientInGame(client)) return;
	
	if (hQuery.FetchRow())
	{
		g_iReal[client][HX_PLACE]    = hQuery.FetchInt(0);
		
		if (hQuery.FetchRow())
		{
			g_iReal[client][HX_PLACE_WEEK]    = hQuery.FetchInt(0);
		}
	}
	
	if (client == 0) // for service requested SteamId
	{
		OnReqClientRegistered();
	}
	else {
		g_bClientRegistered[client] = true;
		Forward_OnClientRegistered(client);

		if (g_ConVarShowRankPlayerStart.BoolValue)
		{
			if( g_ConVarShowRankOnce.BoolValue && g_bRankDisplayed[client] )
			{
				return;
			}
			CreateTimer(g_ConVarShowRankDelay.FloatValue, HxTimer_Connected, data, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
}

public void SQL_Tx_Success (Database db, any data, int numQueries, DBResultSet[] results, any[] queryData)
{
}

public void SQL_Tx_SuccessWeekMonth_Failure (Database db, any data, int numQueries, const char[] error, int failIndex, any[] queryData)
{
	LogStackTrace("%s", error);
}
/*
public void SQL_Callback (Database db, DBResultSet hQuery, const char[] error, any data)
{
	if (!db || !hQuery) { LogError("%s", error); return; }
}
*/

public void SQL_CallbackUpgrade (Database db, DBResultSet hQuery, const char[] error, any data)
{
	#if DEBUG_SQL
		DataPack dp = view_as<DataPack>(data);
		if (!db || !hQuery) { char query[640]; dp.Reset(); dp.ReadString(query, sizeof(query));	LogStackTrace("Query: \"%s\". Error: %s", query, error); delete dp; return;	}
		delete dp;
	#else
		if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	#endif
}

public void SQL_CallbackInsertColumn (Database db, DBResultSet hQuery, const char[] error, any data)
{
	#if DEBUG_SQL
		DataPack dp = view_as<DataPack>(data);
		if (!db || !hQuery) { char query[640]; dp.Reset(); dp.ReadString(query, sizeof(query));	LogStackTrace("Query: \"%s\". Error: %s", query, error); delete dp; return;	}
		delete dp;
	#else
		if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	#endif
}

public void SQL_CallbackRequestUpdateTime (Database db, DBResultSet hQuery, const char[] error, any data)
{
	#if DEBUG_SQL
		DataPack dp = view_as<DataPack>(data);
		if (!db || !hQuery) { char query[640]; dp.Reset(); dp.ReadString(query, sizeof(query));	LogStackTrace("Query: \"%s\". Error: %s", query, error); delete dp; return;	}
		delete dp;
	#else
		if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	#endif
}

public void SQL_CallbackCreateClient (Database db, DBResultSet hQuery, const char[] error, any data)
{
	#if DEBUG_SQL
		DataPack dp = view_as<DataPack>(data);
		if (!db || !hQuery) { char query[640]; dp.Reset(); dp.ReadString(query, sizeof(query));	LogStackTrace("Query: \"%s\". Error: %s", query, error); delete dp; return;	}
		delete dp;
	#else
		if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	#endif
}

public void SQL_CallbackGiveAwardVIP (Database db, DBResultSet hQuery, const char[] error, any data)
{
	#if DEBUG_SQL
		DataPack dp = view_as<DataPack>(data);
		if (!db || !hQuery) { char query[640]; dp.Reset(); dp.ReadString(query, sizeof(query));	LogStackTrace("Query: \"%s\". Error: %s", query, error); delete dp; return;	}
		delete dp;
	#else
		if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	#endif
}

public void SQL_CallbackUpdateHiddenFlag (Database db, DBResultSet hQuery, const char[] error, any data)
{
	#if DEBUG_SQL
		DataPack dp = view_as<DataPack>(data);
		if (!db || !hQuery) { char query[640]; dp.Reset(); dp.ReadString(query, sizeof(query));	LogStackTrace("Query: \"%s\". Error: %s", query, error); delete dp; return;	}
		delete dp;
	#else
		if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	#endif
}

public void SQL_CallbackSaveStat (Database db, DBResultSet hQuery, const char[] error, any data)
{
	#if DEBUG_SQL
		DataPack dp = view_as<DataPack>(data);
		if (!db || !hQuery) { char query[640]; dp.Reset(); dp.ReadString(query, sizeof(query));	LogStackTrace("Query: \"%s\". Error: %s", query, error); delete dp; return;	}
		delete dp;
	#else
		if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	#endif
}

public void SQL_CallbackDropTable (Database db, DBResultSet hQuery, const char[] error, any data)
{
	#if DEBUG_SQL
		DataPack dp = view_as<DataPack>(data);
		if (!db || !hQuery) { char query[640]; dp.Reset(); dp.ReadString(query, sizeof(query));	LogStackTrace("Query: \"%s\". Error: %s", query, error); delete dp; return;	}
		delete dp;
	#else
		if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	#endif
}

public void SQL_CallbackCreateTable (Database db, DBResultSet hQuery, const char[] error, any data)
{
	#if DEBUG_SQL
		DataPack dp = view_as<DataPack>(data);
		if (!db || !hQuery) { char query[1540]; dp.Reset(); dp.ReadString(query, sizeof(query));	LogStackTrace("Query: \"%s\". Error: %s", query, error); delete dp; return;	}
		delete dp;
	#else
		if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	#endif
}

void UpdateHiddenFlag(int client)
{
	int iFlagBits = GetUserFlagBits(client);
	int iHidden = iFlagBits & g_iHiddenFlagBits ? 1 : 0; // should be hidden?
	
	if (iHidden ^ g_iReal[client][HX_HIDE]) // db flag is different => populate it
	{
		FormatEx(g_sQuery2, sizeof(g_sQuery2)
		 , "UPDATE `%s` SET \
			Hide = '%d' \
			WHERE `Steamid` = '%s'"
			, HX_TABLE
			, iHidden
			, g_sSteamId[client]);
		
		#if DEBUG_SQL
			DataPack dp = new DataPack();
			dp.WriteString(g_sQuery2);
			g_hDB.Query(SQL_CallbackUpdateHiddenFlag, g_sQuery2, dp);
		#else
			g_hDB.Query(SQL_CallbackUpdateHiddenFlag, g_sQuery2);
		#endif
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
	
	if( !g_bAllowNegativePoints )
	{
		if( g_iReal[client][HX_POINTS] + g_iTemp[client][HX_POINTS] < 0 )
		{
			g_iTemp[client][HX_POINTS] = -g_iReal[client][HX_POINTS];
		}
		if( g_iReal[client][HX_POINTS_MONTH] + g_iTemp[client][HX_POINTS_MONTH] < 0 )
		{
			g_iTemp[client][HX_POINTS_MONTH] = -g_iReal[client][HX_POINTS_MONTH];
		}
		if( g_iReal[client][HX_POINTS_WEEK] + g_iTemp[client][HX_POINTS_WEEK] < 0 )
		{
			g_iTemp[client][HX_POINTS_WEEK] = -g_iReal[client][HX_POINTS_WEEK];
		}
	}
	
	FormatEx(g_sQuery2, sizeof(g_sQuery2)
	 , "UPDATE `%s` SET \
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
		TankSolo = TankSolo + %d, \
		Witch = Witch + %d, \
		HeadShot = HeadShot + %d \
		WHERE `Steamid` = '%s'"
		
		, HX_TABLE
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
		, g_iTemp[client][HX_TANK_SOLO]
		, g_iTemp[client][HX_WITCH]
		, g_iTemp[client][HX_HEADSHOT]
		, g_sSteamId[client]);
	
	#if DEBUG_SQL
		DataPack dp = new DataPack();
		dp.WriteString(g_sQuery2);
		g_hDB.Query(SQL_CallbackSaveStat, g_sQuery2, dp);
	#else
		g_hDB.Query(SQL_CallbackSaveStat, g_sQuery2);
	#endif
	
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
	g_iReal[client][HX_TANK_SOLO]   	+= g_iTemp[client][HX_TANK_SOLO];
	g_iReal[client][HX_WITCH]  			+= g_iTemp[client][HX_WITCH];
	g_iReal[client][HX_HEADSHOT] 		+= g_iTemp[client][HX_HEADSHOT];
	g_iReal[client][HX_PENALTY]  		+= g_iTemp[client][HX_PENALTY];
	
	HxClean(client, true);
}

public Action CMD_sqlcreate(int client, int args)
{
	HxSQL_CreateTable(true);
	HxCleanAll();
	return Plugin_Handled;
}

void HxSQL_CreateTable(bool bRemoveOld = false)
{
	if (g_hDB)
	{
		#if DEBUG_SQL
			DataPack dp = new DataPack();
		#endif
		
		if (bRemoveOld)
		{
			FormatEx(g_sQuery2, sizeof(g_sQuery2), "DROP TABLE IF EXISTS `%s`;", HX_TABLE);
			
			#if DEBUG_SQL
				dp.WriteString(g_sQuery2);
				g_hDB.Query(SQL_CallbackDropTable, g_sQuery2, dp);
			#else
				g_hDB.Query(SQL_CallbackDropTable, g_sQuery2);
			#endif
		}
		
		char g_sQuery[1540];
		FormatEx(g_sQuery, sizeof(g_sQuery), HX_CREATE_TABLE, HX_TABLE);
		
		#if DEBUG_SQL
			delete dp;
			dp = new DataPack();
			dp.WriteString(g_sQuery);
			g_hDB.Query(SQL_CallbackCreateTable, g_sQuery, dp);
		#else
			g_hDB.Query(SQL_CallbackCreateTable, g_sQuery);
		#endif
		
		CPrintToChatAll("%t", "Database_Created"); // [HXStats] Database table is created. Please, restart the map.
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
		ReplyToCommand(client, "%t: sm_hx_showpoints <#userid|name|steamid>", "Usage");
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
			ReplyToCommand(client, "%t: %N", "No_SteamId", target_client); // Can't obtain SteamId of user
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
	 , "UPDATE `%s` SET \
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
		TankSolo = TankSolo + %d, \
		Witch = Witch + %d, \
		HeadShot = HeadShot + %d \
		WHERE `Steamid` = '%s'"
		
		, HX_TABLE
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
		, g_iReal[0][HX_TANK_SOLO]
		, g_iReal[0][HX_WITCH]
		, g_iReal[0][HX_HEADSHOT]
		, g_sDestSteam);
	
	g_hDB.Query(SQL_MovePointsCallback, g_sQuery2);
}

public void SQL_MovePointsCallback (Database db, DBResultSet hQuery, const char[] error, any data)
{
	if (!db || !hQuery) {
		LogStackTrace("%s", error);
		PrintToConsoles(g_iRequestorId, "%t", "Move_FAILED"); // Moving points is FAILURE !!!
		return;
	}
	PrintToConsoles(g_iRequestorId, "%t", "Move_Success"); // Moving points is success.
}

public Action CMD_DelOld(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%t: sm_hx_delold <%t>", "Usage", "days");
		return Plugin_Handled;
	}
	
	char s[8];
	GetCmdArg(1, s, sizeof(s));
	int days = StringToInt(s);
	
	int iUnix = GetTime();
	iUnix -= days * 60 * 60 * 24;
	
	FormatEx(g_sQuery2, sizeof(g_sQuery2)
	 , "DELETE FROM `%s` \
		WHERE `Time2` < %i AND NOT `SteamId` = '%s'"
		, HX_TABLE
		, iUnix
		, HX_SERVICE_STEAM);
	
	g_hDB.Query(SQL_CallbackDelOld, g_sQuery2, GetClientUserId(client));
	return Plugin_Handled;
}

public void SQL_CallbackDelOld (Database db, DBResultSet hQuery, const char[] error, int data)
{
	if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	if (hQuery)
	{
		PrintToConsoles(GetClientOfUserId(data), "%t: %i", "Deleted_Players", hQuery.AffectedRows); // Total players deleted
	}
}

public Action CMD_UnhideAll(int client, int args)
{
	FormatEx(g_sQuery2, sizeof(g_sQuery2), "UPDATE `%s` SET `Hide` = 0 WHERE NOT `Steamid` = '%s'", HX_TABLE, HX_SERVICE_STEAM);
	g_hDB.Query(SQL_CallbackUnhideAll, g_sQuery2, GetClientUserId(client));
	return Plugin_Handled;
}

public void SQL_CallbackUnhideAll (Database db, DBResultSet hQuery, const char[] error, int data)
{
	if (!db || !hQuery) { LogStackTrace("%s", error); return; }
	if (hQuery)
	{
		PrintToConsoles(GetClientOfUserId(data), "%t", "Admins_unhidden"); // Statistics of all admins are now unhidden in top
	}
}

public Action CMD_DelPlayer(int client, int args)
{
	if (args < 1)
	{
		ReplyToCommand(client, "%t: sm_hx_delplayer <steamid>", "Usage");
		return Plugin_Handled;
	}
	
	char sSteam[64];
	GetCmdArg(1, sSteam, sizeof(sSteam));
	
	if (StrContains(sSteam, "STEAM_") != 0)
	{
		ReplyToCommand(client, "%t: sm_hx_delplayer <steamid>", "Usage");
		return Plugin_Handled;
	}
	
	FormatEx(g_sQuery2, sizeof(g_sQuery2)
	 , "DELETE FROM `%s` \
		WHERE `Steamid` = '%s'"
		, HX_TABLE, sSteam);
	
	g_hDB.Query(SQL_DelPlayerCallback, g_sQuery2, GetClientUserId(client));
	return Plugin_Handled;
}

public void SQL_DelPlayerCallback (Database db, DBResultSet hQuery, const char[] error, any data)
{
	int client = GetClientOfUserId(data);
	if (!db || !hQuery) {
		LogStackTrace("%s", error);
		PrintToConsoles(client, "%t", "DelPlayer_FAILED"); // Delete player is FAILURE !!!
	}
	else {
		PrintToConsoles(client, "%t", "DelPlayer_Success"); // Delete player is success.
	}
}

public Action CMD_MovePoints(int client, int args)
{
	g_iRequestorId = client;
	g_iReqAction = ACTION_MOVEPOINTS;
	
	if (args < 2)
	{
		ReplyToCommand(client, "%t: sm_hx_movepoints <STEAM_1> <STEAM_2> %t", "Usage", "movepoints_hint"); // where 1 - source, 2 - destination
		return Plugin_Handled;
	}
	
	GetCmdArg(1, g_sReqSteam, sizeof(g_sReqSteam));
	GetCmdArg(2, g_sDestSteam, sizeof(g_sDestSteam));
	
	HxSQL_RegisterClient(0);
	return Plugin_Handled;
}

public Action CMD_stat(int client, int args)
{
	if( !g_bEnabled ) {
		PrintToChat(client, "%t", "Plugin_Disabled");
		return Plugin_Handled;
	}
	
	char s[192];
	FormatEx(s, sizeof(s), "%T", "Join_Rank_InChat", client);
	BuildPointsString(client, s, sizeof(s));
	CPrintToChat(client, s);
	
	Menu menu = new Menu(MenuHandler_MenuStat, MENU_ACTIONS_DEFAULT);
	menu.SetTitle(Translate(client, "%t", "Statistics", g_sMenuName));
	menu.AddItem("1", Translate(client, "%t", "Rank"));
	menu.AddItem("2", Translate(client, "%t", "Top"));
	if (g_ConVarMenuBestOfWeek.BoolValue)
		menu.AddItem("3", Translate(client, "%t", "VIP: Top of week"));
	if (g_ConVarMenuBestOfMonth.BoolValue)
		menu.AddItem("4", Translate(client, "%t", "VIP: Top of month"));
	if (g_ConVarMenuBestOfLWeek.BoolValue)
		menu.AddItem("5", Translate(client, "%t", "VIP: Top of last week"));
	if (g_ConVarMenuBestOfLMonth.BoolValue)
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
	return 0;
}

void ShowPointsAbout(int client)
{
	Panel hPanel = new Panel();
	hPanel.SetTitle(Translate(client, "%t", "Scoring:"));
	
	if (g_iPointsBoomer)
		hPanel.DrawText(Translate(client, "%t", "1 Boomer - {} point(s)", g_iPointsBoomer));
	if (g_iPointsHunter)
		hPanel.DrawText(Translate(client, "%t", "1 Hunter - {} point(s)", g_iPointsHunter));
	if (g_iPointsSmoker)
		hPanel.DrawText(Translate(client, "%t", "1 Smoker - {} point(s)", g_iPointsSmoker));
		
	if (g_bL4D2)
	{
		if (g_iPointsCharger)
			hPanel.DrawText(Translate(client, "%t", "1 Charger - {} point(s)", g_iPointsCharger));
		if (g_iPointsJockey)
			hPanel.DrawText(Translate(client, "%t", "1 Jockey - {} point(s)", g_iPointsJockey));
		if (g_iPointsSpitter)
			hPanel.DrawText(Translate(client, "%t", "1 Spitter - {} point(s)", g_iPointsSpitter));
	}
	if (g_iPointsTank)
	{
		if( g_iPointsTankSolo )
		{
			hPanel.DrawText(Translate(client, "%t", "1 TankSolo - {} point(s)", g_iPointsTank, g_iPointsTankSolo));
		}
		else {
			hPanel.DrawText(Translate(client, "%t", "1 Tank - {} point(s)", g_iPointsTank, g_iPointsTankSolo));
		}
	}
	if (g_iPointsWitch)
		hPanel.DrawText(Translate(client, "%t", "1 Witch - {} point(s)", g_iPointsWitch));
	
	hPanel.DrawItem(Translate(client, "%t", "Close"));
	hPanel.DrawItem(Translate(client, "%t", "Back"));
	hPanel.DrawItem(Translate(client, "%t", "Next")); // Second part of list
	
	hPanel.Send(client, AboutPanelHandler, 20);
	delete hPanel;
}

void DrawPointsAbout2(int client, Panel hPanel)
{
	if (g_iPointsHeadShot)
		hPanel.DrawText(Translate(client, "%t", "1 Headshot - {} point(s)", g_iPointsHeadShot));
	if (g_iPointsInfected)
		hPanel.DrawText(Translate(client, "%t", "{} zombies - {} point(s)", g_iCommonsToKill, g_iPointsInfected));
	if (g_iPointsTime)
		hPanel.DrawText(Translate(client, "%t", "{} min. in game - {} point(s)", g_iTimeToPlay, g_iPointsTime));
	if (g_iPenaltyDeath)
		hPanel.DrawText(Translate(client, "%t", "Penalty for death - {} point(s)", g_iPenaltyDeath));
	if (g_iPenaltyIncap)
		hPanel.DrawText(Translate(client, "%t", "Penalty for incap - {} point(s)", g_iPenaltyIncap));
	if (g_iPenaltyFF)
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
	return 0;
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
	return 0;
}

public Action CMD_rank(int client, int args)
{
	if( !g_bEnabled )
	{
		PrintToChat(client, "%t", "Plugin_Disabled");
		return Plugin_Handled;
	}
	
	ShowRank(client);
	return Plugin_Handled;
}

void ShowRank(int client, int iDisplayToCustomClient = 0)
{
	int iRequestor = iDisplayToCustomClient == 0 ? client : iDisplayToCustomClient;
	
	int iPointsTotal = RoundToCeil(	g_iReal[client][HX_POINTS] 			+ g_iTemp[client][HX_POINTS] 	+ g_fPenaltyBonus[client]);
	int iPointsMonth = 				g_iReal[client][HX_POINTS_MONTH] 	+ g_iTemp[client][HX_POINTS];
	int iPointsWeek = 				g_iReal[client][HX_POINTS_WEEK] 	+ g_iTemp[client][HX_POINTS];
	
	if( !g_bAllowNegativePoints )
	{
		if( iPointsTotal < 0 ) iPointsTotal = 0;
		if( iPointsMonth < 0 ) iPointsMonth = 0;
		if( iPointsWeek < 0 ) iPointsWeek = 0;
	}
	
	FormatEx(g_sBuf1, sizeof(g_sBuf1)
	, "%d %T (%T:%d, %T:%d, %T:%d)\n\
		- \n\
		%T: %d \n"
			, 					 	iPointsTotal, "points", iRequestor
			,	"M", iRequestor, 	iPointsMonth			
			,	"W", iRequestor,	iPointsWeek
			,	"R", iRequestor,	RoundToCeil(g_iTemp[client][HX_POINTS]											+ g_fPenaltyBonus[client])
		, "Place", iRequestor,		g_iReal[client][HX_PLACE] );
	
	if (g_iPointsBoomer)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Boomer", iRequestor, 			g_iReal[client][HX_BOOMER]		+ g_iTemp[client][HX_BOOMER],   	g_iTemp[client][HX_BOOMER] );
	if (g_bL4D2 && g_iPointsCharger)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Charger", iRequestor, 		g_iReal[client][HX_CHARGER]		+ g_iTemp[client][HX_CHARGER],   	g_iTemp[client][HX_CHARGER] );
	if (g_iPointsHunter)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Hunter", iRequestor, 			g_iReal[client][HX_HUNTER]		+ g_iTemp[client][HX_HUNTER],   	g_iTemp[client][HX_HUNTER] );
	if (g_iPointsInfected)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Infected", iRequestor, 		g_iReal[client][HX_INFECTED]	+ g_iTemp[client][HX_INFECTED],   	g_iTemp[client][HX_INFECTED] );
	if (g_bL4D2 && g_iPointsJockey)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Jockey", iRequestor, 			g_iReal[client][HX_JOCKEY]		+ g_iTemp[client][HX_JOCKEY],   	g_iTemp[client][HX_JOCKEY] );
	if (g_iPointsSmoker)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Smoker", iRequestor, 			g_iReal[client][HX_SMOKER]		+ g_iTemp[client][HX_SMOKER],   	g_iTemp[client][HX_SMOKER] );
	if (g_bL4D2 && g_iPointsSpitter)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Spitter", iRequestor, 		g_iReal[client][HX_SPITTER]		+ g_iTemp[client][HX_SPITTER],   	g_iTemp[client][HX_SPITTER] );
	if (g_iPointsTank)
	{
		if( g_iPointsTankSolo )
		{
			Format(g_sBuf1, sizeof(g_sBuf1), "%s%T / %T: %d/%d (%d/%d)\n", g_sBuf1, "Tank", iRequestor, "Solo", iRequestor, 
				g_iReal[client][HX_TANK]		+ g_iTemp[client][HX_TANK], 	g_iReal[client][HX_TANK_SOLO]		+ g_iTemp[client][HX_TANK_SOLO],
				g_iTemp[client][HX_TANK],	g_iTemp[client][HX_TANK_SOLO] );
		}
		else {
			Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Tank", iRequestor, 		g_iReal[client][HX_TANK]		+ g_iTemp[client][HX_TANK], 		g_iTemp[client][HX_TANK] );
		}
	}
	if (g_iPointsWitch)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "Witch", iRequestor, 			g_iReal[client][HX_WITCH]		+ g_iTemp[client][HX_WITCH],   		g_iTemp[client][HX_WITCH] );
	if (g_iPointsHeadShot)
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)\n", g_sBuf1, "HeadShot", iRequestor, 		g_iReal[client][HX_HEADSHOT]	+ g_iTemp[client][HX_HEADSHOT],   	g_iTemp[client][HX_HEADSHOT] );
	
	if (g_iPenaltyDeath || g_iPenaltyIncap || g_iPenaltyFF)
	{
		Format(g_sBuf1, sizeof(g_sBuf1), "%s%T: %d (%d)", g_sBuf1, "Penalty", iRequestor, 	
			RoundToCeil(g_fPenaltyBonus[client] + g_iReal[client][HX_PENALTY] + g_iTemp[client][HX_PENALTY]),
			RoundToCeil(g_fPenaltyBonus[client] + g_iTemp[client][HX_PENALTY]) );
	}
	
	if (client == 0)
	{
		Format(g_sBuf1, sizeof(g_sBuf1), "Name: %s\n%s", g_sName[client], g_sBuf1);
		if (g_iRequestorId && IsClientInGame(g_iRequestorId))
		{
			PrintToConsole(g_iRequestorId, g_sBuf1);
		}
		else {
			PrintToServer(g_sBuf1);
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

public Action CMD_topWeek(int client, int args)
{
	if( !g_bEnabled ) {
		PrintToChat(client, "%t", "Plugin_Disabled");
		return Plugin_Handled;
	}
	
	ShowTop(client, PERIOD_WEEK);
	return Plugin_Handled;
}

public Action CMD_top(int client, int args)
{
	if( !g_bEnabled ) {
		PrintToChat(client, "%t", "Plugin_Disabled");
		return Plugin_Handled;
	}
	
	ShowTop(client, PERIOD_TOTAL);
	return Plugin_Handled;
}

public Action CMD_LogPoints(int client, int agrs)
{
	ShowTop(client, PERIOD_LAST_WEEK, true);
	ShowTop(client, PERIOD_LAST_MONTH, true);
	
	PrintToConsoles(client, "%t", "LogPoints_Processing"); // Log points sent for processing.
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
		}
	}
	
	if (g_hDB)
	{
		FormatEx(g_sQuery3, sizeof(g_sQuery3), "SELECT `Name`, `%s` FROM `%s` WHERE `Hide` = 0 ORDER BY `%s` DESC LIMIT %i", sField, HX_TABLE, sField, GetTopPeriodLimit(ePeriod));
		
		DataPack dp = new DataPack();
		dp.WriteCell(client ? GetClientUserId(client) : 0);
		dp.WriteCell(ePeriod);
		dp.WriteCell(bPrintLog);
		
		g_hDB.Query(SQL_Callback_Top, g_sQuery3, dp);
	}
}

public void SQL_Callback_Top (Database db, DBResultSet hQuery, const char[] error, int data)
{
	DataPack dp = view_as<DataPack>(data);
	if (!db || !hQuery) {
		LogStackTrace("%s", error);
		delete dp;
		return;
	}
	dp.Reset();
	int client = GetClientOfUserId(dp.ReadCell());
	int ePeriod = dp.ReadCell();
	bool bPrintLog = dp.ReadCell();
	delete dp;
	
	//if (client && !IsClientInGame(client)) return;
	
	static char sName[32];
	int iPoints = 0;
	int iNum = 0;
	
	static char sPeriod[64];
	GetTopPeriodName(client, ePeriod, sPeriod, sizeof(sPeriod));
	
	if (bPrintLog)
	{
		char sTime[32];
		FormatTime(sTime, sizeof(sTime), "%F, %X", GetTime());
		AddLogString("\n\n%s (%s)\n", sPeriod, sTime);
	}
	
	Panel hPanel = new Panel();
	StrCat(sPeriod, sizeof(sPeriod), "\n - \n");
	hPanel.SetTitle(sPeriod);

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
	
	if (client)
	{
		hPanel.DrawItem(Translate(client, "%t", "Close"));
		hPanel.DrawItem(Translate(client, "%t", "Back"));
		hPanel.Send(client, CommonPanelHandler, 20);
	}
	delete hPanel;
}

public Action CMD_Refresh(int client, int args)
{
	if (g_hDB) {
		ReplyToCommand(client, "%t", "Connection_Live"); // Database connection is live.
		SQL_SaveAll(false);
	}
	else {
		ReplyToCommand(client, "%t", "Connection_Lost"); // Database connection is LOST !!!
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

void HxCleanAll()
{
	for( int i = 1; i <= MaxClients; i++ )
	{
		HxClean(i);
	}
}

void HxClean(int &client, bool bTempOnly = false)
{
	g_iTemp[client][HX_POINTS]   	= 0;
	g_iTemp[client][HX_TIME]     	= 0;
	g_iTemp[client][HX_BOOMER]   	= 0;
	g_iTemp[client][HX_CHARGER]  	= 0;
	g_iTemp[client][HX_HUNTER]   	= 0;
	g_iTemp[client][HX_INFECTED] 	= 0;
	g_iTemp[client][HX_JOCKEY]   	= 0;
	g_iTemp[client][HX_SMOKER]   	= 0;
	g_iTemp[client][HX_SPITTER]  	= 0;
	g_iTemp[client][HX_TANK]     	= 0;
	g_iTemp[client][HX_TANK_SOLO]	= 0;
	g_iTemp[client][HX_WITCH]    	= 0;
	g_iTemp[client][HX_HEADSHOT]    = 0;
	g_iTemp[client][HX_PENALTY]  	= 0;
	
	if ( !bTempOnly )
	{
		g_iReal[client][HX_POINTS]   		= 0;
		g_iReal[client][HX_TIME]     		= 0;
		g_iReal[client][HX_BOOMER]   		= 0;
		g_iReal[client][HX_CHARGER]  		= 0;
		g_iReal[client][HX_HUNTER]   		= 0;
		g_iReal[client][HX_INFECTED] 		= 0;
		g_iReal[client][HX_JOCKEY]   		= 0;
		g_iReal[client][HX_SMOKER]   		= 0;
		g_iReal[client][HX_SPITTER]  		= 0;
		g_iReal[client][HX_TANK]     		= 0;
		g_iReal[client][HX_TANK_SOLO]		= 0;
		g_iReal[client][HX_WITCH]    		= 0;
		g_iReal[client][HX_HEADSHOT]   		= 0;
		g_iReal[client][HX_PENALTY]  		= 0;
		g_iReal[client][HX_POINTS_MONTH]  	= 0;
		g_iReal[client][HX_POINTS_WEEK]   	= 0;
		g_iReal[client][HX_PLACE]    		= 0;
		g_iReal[client][HX_PLACE_WEEK]		= 0;
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

stock void CPrintToChatAll(const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

void PrintPoints(int client, const char[] format, any ...)
{
	if (g_bPrintPoints)
	{
		static char buffer[192];
		SetGlobalTransTarget(client);
		VFormat(buffer, sizeof(buffer), format, 3);
		ReplaceColor(buffer, sizeof(buffer));
		PrintToChat(client, "\x01%s", buffer);
	}
}

void AddLogString(const char[] format, any ...)
{
	static char sLogPath[PLATFORM_MAX_PATH];
	static char buffer[192];
	if (sLogPath[0] == '\0')
	{
		BuildPath(Path_SM, sLogPath, sizeof(sLogPath), HX_LOG_FILE);
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

#if defined _vip_core_included

bool GiveVIP(int client, int days)
{
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
	return false;
}
#endif

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

void PrintToConsoles( int client, char[] format, any ... )
{
	if( client && !IsClientInGame(client) )
	{
		client = 0;
	}
	static char buf[256];
	SetGlobalTransTarget(client);
	VFormat(buf, sizeof(buf), format, 3);

	if( client )
	{
		PrintToChat(client, buf);
		SetGlobalTransTarget(0);
		VFormat(buf, sizeof(buf), format, 3);
		PrintToConsole(client, buf);
	}
	else {
		PrintToServer(buf);
	}
}

void Forward_OnClientRegistered(int iClient)
{
	Action result;
	Call_StartForward(g_OnClientRegistered);
	Call_PushCell(iClient);
	Call_Finish(result);
}