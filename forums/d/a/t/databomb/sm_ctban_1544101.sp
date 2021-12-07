/*  [CS:S/CS:GO] CT Bans
    Copyright (C) 2011-2017 by databomb

    This program is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    This program is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with this program.  If not, see <http://www.gnu.org/licenses/>.

	***************************************************************************

	Description:
	Allows admins to restrict access to the CT team from those who violate the server's rules. Designed for specific usage in Jailbreak environments.

	Features:
	- CT Bans are stored in the ClientPrefs database and survive map changes, re-joins, and server crashes.
	- The Rage Ban feature allows admins to CT ban rage quitters who break the server's rules and then quickly disconnect.
	- You may give a timed CT ban which will work based on in minutes spent alive (so idlers in spectate or those who suicide at the beginning of the round will not be working toward an unban.)
	- The timed CT bans are stored in a SQL table for stateful access.
	- The plugin logs CT ban to a SQL table in addition to your regular SM logs.
	- Re-displays the team selection screen after an improper selection was made.
	- SM Menu integration for the rageban and ctban commands.
	- Displays helpful message to users who are CT banned when they join the server.
	- SM Translations support.
	- Custom reasons permitted (configs/ctban_reasons.ini).
	- Custom lengths permitted (configs/ctban_times.ini).

	Installation:
	Place the ctban.phrases.txt file in your addons/sourcemod/translations directory.
	Place the sm_ctban.smx file in your addons/sourcemod/plugins directory.
	Check your logs/server-console after the initial load for any SQL errors. If you have any SQL errors check your addons/sourcemod/configs/databases.cfg file and verify you can connect using the drivers you have specified.
	Upgrade: Delete cfg/sourcemod/ctban.cfg and re-configure convars after the file is re-created.
	Optional: Generate custom reasons list by creating a simple text file (addons/sourcemod/configs/ctban_reasons.ini) with 1 reason per line.

	Command Usage:

	sm_ctban <player> <time> <optional: reason>
	Bans the selected player from joining the CT team.

	sm_removectban <player> | sm_unctban <player>
	Removes the CT ban on the selected player.

	sm_isbanned <player>
	Reports back the status of the current player's CT ban and the time remaining on the ban, if any.

	sm_rageban
	Brings up a menu so you may choose a recently disconnected player to permanently CT ban.

	sm_ctban_offline <steamid>
	Bans the given Steam Id from playing on the CT team.

	sm_removectban_offline <steamid> | sm_unctban_offline <steamid>
	Unbans the given Steam Id from the CT team.

	sm_reset_ctban_cookies <'force'>
	Resets the entire CTBan cookie database.

	sm_forcect <player>
	Overrides any CTBans and swaps a player to CT team.

	sm_unforcect <player>
	Removes overrides and moves player to T team.

	sm_isbanned_offline <steamid>
	Reports back the status of the target Steam Id from the ban database.

	sm_change_ctban_time <player> <time>
	Changes an existing CTBan to the new time specified. 0 would be permanently CTBan.

	sm_ctbanlist
	Displays a menu of active players who are CT Banned.

	Settings:
	sm_ctban_soundfile, <path>: The path to the soundfile to play when denying a team-change request. Set to "" to disable.
	sm_ctban_joinbanmsg, <message>: This message is appended to a time-stamp when a CT banned user joins the server.
	sm_ctban_table_prefix, <prefix>: This prefix will be added in front of the table names.
	sm_ctban_database_driver, <driver>: This specifies which driver to use from database.cfg
	sm_ctban_force_reason, [0,1]: Specifies whether a reason is required for the CT Ban command.
	sm_ctban_checkctbans_adminflags, [a-z]: Specifies the admin flag levels that may use the !ctbanlist and !isbanned command targeting anyone. Blank allows all players access on everyone.
	sm_ctban_isbanned_selftarget, [0,1]: Specifies whether a non-admin can target themselves using the !isbanned command.
	sm_ctban_respawn, [0,1]: Specifies whether to respawn players after team changes.

	Special Thanks (Development):
	Azelphur for snippets of cross-mod code.
	Kigen for the idea of CT banning based on time spent alive.
	oaaron99 for the idea of smart !ctban menu re-directs.
	Bara for include file ideas and lengths code.

	Future Considerations:
	Using API-- Steam Group CTBans
	Using API-- New Admin Level and Command for CT Banning for Only Small Durations

	Change Log:
	2.0.3 Adds !rageban console user support. Fixed bug where !rageban was not permanent. Fixed bug with custom times (configs/ctban_times.ini) not displaying menu options correctly.
	      Adds multi-targeting filters for other admin commands: @ctban @!ctban and @noctbans (@noctbans specifies players who have never had a CT Ban).
	2.0.2 Adds SQLite support. Updated include file: Adds more intelligent #tryinclude and pre-compile directives.
	      Alerts admins if someone is swapped to CT without !forcect. Added custom times options (configs/ctban_times.ini).
		  Times file should be formatted as a Key Values file with each section having the number of minutes and a description such as: "90" "1 Hour 30 Minutes"
	2.0.1 Bug fixes in UnForceCT, ForceCT, and OnClientAuthorized which were each generating errors.
	2.0.0 Ported to the new syntax. Translation file updated. CS:GO Fixes bug where mp_force_pick_time could assign a banned player to CT. Made !ctban open menus if more info is needed.
		  CS:GO Fixes incompatibility with Zephyrus's Team Limit Bypass plugin. Adds spawn check to verify CTBans. Added !forcect/!unforcect to override CTBan and swap players.
		  Allows custom reasons (configs/ctban_reasons.ini). Allows non-admins to use !isbanned. Added command to reset all CT Ban cookies. Added Player Commands menu for !unctban.
		  Adds CT Ban to !admin Player Commands menu. Allowed fallback for !isbanned to return ban info even if database log entries were missing. Added !ctbanlist command.
		  Added CT Ban reason to !ctban chat output where possible. Changed from [SM] to [CTBAN] chat tag and added colors. Removing compile option USESQL (Now Always Uses SQL).
		  Added !isbanned_offline to find CT Ban info of offline players. !ctban_offline and !unctban_offline now update the log database records.
		  Added convar sm_ctban_respawn to allow respawns after team swaps due to !ctban or !forcect. Added !change_ctban_time command to edit the time remaining on CTBans.
		  Added API (ctban.inc) for 3rd-party plugin interfaces. The convar sm_ctban_enable is being removed (disable the plugin to disable functionality).
		  Upgraded database log table to include an auto incrementing primary key (ban_id) -- automatically upgrades from tables.
		  Added check for enforcing CTBans if the plugin is loaded late.
	1.6.2 Translation file updated. Added admin, time, reason information for !isbanned. Show !rageban results in chat to players. Added ConVar for forcing !ctban reason.
	1.6.1.4 Fixed bug preventing console CT bans (thanks Kailo!)
	1.6.1.3 Fixed bug with EscapeString function which caused query failures
	1.6.1.2 Fixed SQL Injection vulnerability
	1.6.1.1 Fixed problem in UTIL_TeamMenu()
	1.6.1 Support for new SM1.4 natives, Added config file generation
	1.6.0 Added support for new SM1.4 natives
	1.5.0 Initial public release
	1.4.4 Stable internal build
*/

// Compilation Settings
//#define CTBAN_DEBUG

#define PLUGIN_VERSION "2.0.3"

#include <sourcemod>
#include <clientprefs>
#include <sdktools>
#include <adminmenu>
#include <cstrike>

#tryinclude <hosties>
#tryinclude <ctban>

#if !defined _CTBan_Included_

	// Common constant verifications
	#if !defined INVALID_WEAPON
		#define INVALID_WEAPON -1
	#else
		#assert INVALID_WEAPON == -1
	#endif 
	#if !defined ZERO
		#define ZERO 0
	#else
		#assert ZERO == 0
	#endif
	#if !defined ONE
		#define ONE 1
	#else
		#assert ONE == 1
	#endif
	#if !defined TWO 2
		#define TWO 2
	#else
		#assert TWO == 2
	#endif
	#if !defined THREE
		#define THREE 3
	#else
		#assert THREE == 3
	#endif
	#if !defined FOUR
		#define FOUR 4
	#else
		#assert FOUR == 4
	#endif
	#if !defined FIVE
		#define FIVE 5
	#else
		#assert FIVE == 5
	#endif
	#if !defined SIX
		#define SIX 6
	#else
		#assert SIX == 6
	#endif
	#if !defined SEVEN
		#define SEVEN 7
	#else
		#assert SEVEN == 7
	#endif
	
	// General constants
	#define VALUE_NOT_FOUND_IN_ARRAY -1
	#define SUBSTRING_NOT_FOUND -1
	#define RAGEBAN_ADMIN_LEVEL ADMFLAG_SLAY
	#define CTBAN_ADMIN_LEVEL ADMFLAG_SLAY
	#define UNCTBAN_ADMIN_LEVEL ADMFLAG_SLAY
	#define FORCECT_ADMIN_LEVEL ADMFLAG_SLAY
	#define UNFORCECT_ADMIN_LEVEL ADMFLAG_SLAY
	#define JOINFAILREASON_ONECHANGE 0
	#define MENUCHOICE_USERID 0
	#define MENUCHOICE_TIME 1
	#define CALLER_NATIVE -2
	#define COOKIE_BANNED_STRING "1"
	#define COOKIE_UNBANNED_STRING "0"
	#define ARG_ZERO_GET_COMMAND_NAME 0
	#define FORCECT_ARG_TARGET 1
	#define UNFORCECT_ARG_TARGET 1
	#define ISBANNED_ARG_TARGET 1
	#define CTBAN_ARG_PLAYER 1
	#define CTBAN_ARG_TIME 2
	#define CTBAN_ARG_REASON 3
	#define CTBAN_NO_REASON_GIVEN -1
	#define CTBAN_PERM_BAN_LENGTH 0
	#define RAGEBAN_ARG_CONSOLE_TARGET 1
	#define UNCTBAN_ARG_TARGET 1
	#define CHANGE_TIME_ARG_TARGET 1
	#define CHANGE_TIME_ARG_TIME 2
	#define JOINTEAM_ARG_TEAM_STRING 1
	#define CLIENT_DISCONNECT_CB_FIELD_TIMELEFT 0
	#define FIND_COOKIE_CB_FIELD_COOKIE_ID 0
	#define CLIENT_AUTHED_CB_FIELD_TIMELEFT 0
	#define ISBANNED_CB_FIELD_TIMESTAMP 0
	#define ISBANNED_CB_FIELD_ADMINNAME 1
	#define ISBANNED_CB_FIELD_REASON 2
	#define ISBANNED_OFF_CB_FIELD_TIMESTAMP 0
	#define ISBANNED_OFF_CB_FIELD_ADMINNAME 1
	#define ISBANNED_OFF_CB_FIELD_REASON 2
	#define ISBANNED_OFF_CB_FIELD_TIMELEFT 3
	#define ISBANNED_OFF_CB_FIELD_PERPNAME 4
	#define NATIVE_ISBANNED_CELL_CLIENT 1
	#define NATIVE_GET_TIMELEFT_CELL_CLIENT 1
	#define NATIVE_GET_OVERRIDE_CELL_CLIENT 1
	#define NATIVE_GETBANINFO_CELL_CLIENT 1
	#define NATIVE_GETBANINFO_OFF_STR_AUTHID 1
	#define NATIVE_CTBAN_CELL_CLIENT 1
	#define NATIVE_CTBAN_CELL_TIME 2
	#define NATIVE_CTBAN_CELL_ADMIN 3
	#define NATIVE_CTBAN_STR_REASON 4
	#define NATIVE_CTBAN_OFF_STR_AUTHID 1
	#define NATIVE_CHANGE_TIME_CELL_CLIENT 1
	#define NATIVE_CHANGE_TIME_CELL_TIME 2
	#define NATIVE_CHANGE_TIME_CELL_ADMIN 3
	#define NATIVE_UNBAN_CELL_CLIENT 1
	#define NATIVE_UNBAN_CELL_ADMIN 2
	#define NATIVE_UNBAN_OFF_STR_AUTHID 1
	#define NATIVE_FORCECT_CELL_CLIENT 1
	#define NATIVE_FORCECT_CELL_ADMIN 2
	#define NATIVE_UNFORCECT_CELL_CLIENT 1
	#define NATIVE_UNFORCECT_CELL_ADMIN 2
	#define NATIVE_MIN_AUTHID_LENGTH 3
	#define FIELD_AUTHID_MAXLENGTH 22
	#define FIELD_NAME_MAXLENGTH 32
	#define FIELD_REASON_MAXLENGTH 200
	#define QUERY_MAXLENGTH 350
	#define COOKIE_INIT_CHECK_TIME 0.0
	#define COOKIE_RESCAN_TIME 5.0
	#define DELAY_ENFORCEMENT_TIME 1.8
	#define AUTH_RESCAN_TIME 4.0
	#define DECREMENT_TIMEBAN_INTERVAL 60.0
	#define PLAY_COMMAND_STRING "play "
	#define PLAY_COMMAND_STRING_LENGTH 5
	#define CSGO_MAX_PAGE_MENU_ITEMS 6
	#define CSS_MAX_PAGE_MENU_ITEMS 7
	#define CTBAN_COMMAND "sm_ctban"
	#define REMOVECTBAN_COMMAND "sm_removectban"
	#define RAGEBAN_COMMAND "sm_rageban"
	#define FORCECT_COMMAND "sm_forcect"
	#define UNFORCECT_COMMAND "sm_unforcect"
	#define MAX_UNBAN_CMD_LENGTH 16
	#define MAX_TABLE_LENGTH 32
	#define MAX_DEFAULT_TABLE_LENGTH 12
	#define MAX_CHAT_BANNER_LENGTH 36
	#define MAX_RESET_ARG_LENGTH 10
	#define MAX_USERID_LENGTH 32
	#define MAX_COOKIE_STR_LENGTH 7
	#define MAX_JOINTEAM_ARG_LENGTH 5
	#define MAX_TIME_ARG_LENGTH 32
	#define MAX_TIME_INFO_STR_LENGTH 150
	#define MAX_JOIN_BAN_MSG_LENGTH 100
	#define MAX_ADMINFLAGS_LENGTH 27
	#define MAX_REASON_MENU_CHOICE_LENGTH 10
	#define MAX_MENU_INT_CHOICE_LENGTH 4
	#define MAX_DATABASE_ID_LENGTH 7
	#define CTBAN_ADMIN_IS_CONSOLE 0
	#define CONSOLE_USER_NAME "Console"
	#define CONSOLE_AUTHID "STEAM_0:1:1"
	#define RAGEBAN_LOG_REASON "Rage ban"
	#define OFFLINE_NAME_UNAVAILBLE "Unavailable"
	#define REASON_OFFLINECTBAN "Offline AuthId Ban"
	#define CALLER_DO_NOT_REPLY -1
	
	// Pre-processor macros
	#define MAX_SAFE_ESCAPE_QUERY(%1) (TWO*(%1)+ONE)

#endif

// SQL Queries
#define CTBAN_QUERY_CP_FIND_COOKIE_ID 		"SELECT id FROM sm_cookies WHERE name = 'Banned_From_CT'"
#define CTBAN_QUERY_CP_SELECT_BAN_COOKIE 	"SELECT value FROM sm_cookie_cache WHERE player = '%s' and cookie_id = '%i'"
#define CTBAN_QUERY_CP_RESET_COOKIES 		"UPDATE sm_cookie_cache SET value = '' WHERE cookie_id = '%i'"

#define CTBAN_QUERY_TIME_CREATE 			"CREATE TABLE IF NOT EXISTS %s (steamid VARCHAR(%d), ctbantime INT(16), PRIMARY KEY (steamid))"
#define CTBAN_QUERY_TIME_SELECT_BANTIME 	"SELECT ctbantime FROM %s WHERE steamid = '%s'"
#define CTBAN_QUERY_TIME_INSERT_SQLITE		"INSERT OR REPLACE INTO %s (steamid, ctbantime) VALUES ('%s', %d)"
#define CTBAN_QUERY_TIME_INSERT_MYSQL		"INSERT INTO %s (steamid, ctbantime) VALUES ('%s', %d) ON DUPLICATE KEY UPDATE ctbantime=%d"
#define CTBAN_QUERY_TIME_UPDATE 			"UPDATE %s SET ctbantime = %d WHERE steamid = '%s'"
#define CTBAN_QUERY_TIME_DELETE 			"DELETE FROM %s WHERE steamid = '%s'"

#define CTBAN_QUERY_LOG_CREATE 				"CREATE TABLE IF NOT EXISTS %s (ban_id INT UNSIGNED AUTO_INCREMENT, timestamp INT, perp_steamid VARCHAR(%d), perp_name VARCHAR(%d), admin_steamid VARCHAR(%d), admin_name VARCHAR(%d), bantime INT(16), timeleft INT(16), reason VARCHAR(%d), PRIMARY KEY (ban_id))"
#define CTBAN_QUERY_LOG_INSERT 				"INSERT INTO %s (timestamp, perp_steamid, perp_name, admin_steamid, admin_name, bantime, timeleft, reason) VALUES (%d, '%s', '%s', '%s', '%s', %d, %d, '%s')"
#define CTBAN_QUERY_LOG_ISBANNED 			"SELECT timestamp, admin_name, reason FROM %s WHERE perp_steamid = '%s' AND timeleft >= 0 ORDER BY timestamp DESC LIMIT 1"
#define CTBAN_QUERY_LOG_ISBANNED_OFFLINE 	"SELECT timestamp, admin_name, reason, timeleft, perp_name FROM %s WHERE perp_steamid = '%s' AND timeleft >= 0 ORDER BY timestamp DESC LIMIT 1"
#define CTBAN_QUERY_LOG_EXPIRE 				"UPDATE %s SET timeleft=-1 WHERE perp_steamid = '%s' and timeleft >= 0"
#define CTBAN_QUERY_LOG_V1_CHECK 			"SELECT ban_id FROM %s LIMIT 1"
#define CTBAN_QUERY_LOG_TO_V2_DROPKEY 		"ALTER TABLE %s DROP PRIMARY KEY"
#define CTBAN_QUERY_LOG_TO_V2_ADD_BANID 	"ALTER TABLE %s ADD ban_id INT UNSIGNED PRIMARY KEY AUTO_INCREMENT FIRST"
#define CTBAN_QUERY_LOG_UPDATE 				"UPDATE %s SET timeleft = %d WHERE perp_steamid = '%s' AND timeleft >= 0"
#define CTBAN_QUERY_LOG_TIME_TO_PERM_MYSQL	"UPDATE %s SET (bantime, timeleft) VALUES (0, 0) WHERE perp_steamid = '%s' AND timeleft > 0"
#define CTBAN_QUERY_LOG_TIME_TO_PERM_SQLITE	"UPDATE %s SET bantime = 0, timeleft = 0 WHERE perp_steamid = '%s' AND timeleft > 0"
#define CTBAN_QUERY_LOG_PERM_TO_TIME_MYSQL	"UPDATE %s SET (bantime, timeleft) VALUES (%d, %d) WHERE perp_steamid = '%s' AND timeleft = 0 AND bantime = 0"
#define CTBAN_QUERY_LOG_PERM_TO_TIME_SQLITE	"UPDATE %s SET bantime = %d, timeleft = %d WHERE perp_steamid = '%s' AND timeleft = 0 AND bantime = 0"

#pragma semicolon 1
#pragma newdecls required

char g_sChatBanner[MAX_CHAT_BANNER_LENGTH];
EngineVersion g_EngineVersion = Engine_Unknown;
Handle g_CT_Cookie = INVALID_HANDLE;
Handle gH_TopMenu = INVALID_HANDLE;
Handle gH_Cvar_SoundName = INVALID_HANDLE;
char gS_SoundPath[PLATFORM_MAX_PATH];
Handle gH_Cvar_JoinBanMessage = INVALID_HANDLE;
Handle gH_Cvar_Database_Driver = INVALID_HANDLE;
Handle gA_DNames = INVALID_HANDLE;
Handle gA_DSteamIDs = INVALID_HANDLE;
Handle gH_CP_DataBase = INVALID_HANDLE;
Handle gH_BanDatabase = INVALID_HANDLE;
Handle gH_Cvar_Table_Prefix = INVALID_HANDLE;
int g_iCookieIndex;
bool g_bAuthIdNativeExists = false;
Handle gA_TimedBanLocalList = INVALID_HANDLE;
int gA_LocalTimeRemaining[MAXPLAYERS+ONE];
char g_sLogTableName[MAX_TABLE_LENGTH];
char g_sTimesTableName[MAX_TABLE_LENGTH];
Handle gH_Cvar_Force_Reason = INVALID_HANDLE;
Handle gH_DArray_Reasons = INVALID_HANDLE;
Handle gH_KV_BanLengths = INVALID_HANDLE;
Handle gH_Cvar_CheckCTBans_Flags = INVALID_HANDLE;
Handle gH_Cvar_IsBanned_Self = INVALID_HANDLE;
Handle gH_Cvar_Respawn = INVALID_HANDLE;
bool g_bA_Temp_CTBan_Override[MAXPLAYERS+ONE];
bool g_bIgnoreOverrideResets;
bool g_bRageBanArrayChanged;

Handle g_hFrwd_OnForceCT = INVALID_HANDLE;
Handle g_hFrwd_OnUnforceCT = INVALID_HANDLE;
Handle g_hFrwd_OnCTBan_Offline = INVALID_HANDLE;
Handle g_hFrwd_OnUnCTBan_Offline = INVALID_HANDLE;
Handle g_hFrwd_OnCTBan = INVALID_HANDLE;
Handle g_hFrwd_OnUnCTBan = INVALID_HANDLE;
Handle g_hFrwd_CTBanInfo = INVALID_HANDLE;
Handle g_hFrwd_CTBanInfoOffline = INVALID_HANDLE;

enum eCTBanMenuHandler
{
	e_RemoveCTBan=ZERO,
	e_CTBanList=ONE,
	e_ForceCT=TWO
}

enum eQueryCallback
{
	e_QueryLogTableTwo=ZERO
}

enum eDatabaseType
{
  e_Unknown=ZERO,
  e_MySQL=ONE,
  e_SQLite=TWO
}

eDatabaseType g_eDatabaseType = e_Unknown;

public Plugin myinfo =
{
	name = "CT Ban",
	author = "databomb",
	description = "Allows admins to ban players from joining the CT team.",
	version = PLUGIN_VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=166080"
};

public APLRes AskPluginLoad2(Handle hMyself, bool bLate, char[] sError, int iErr_Max)
{
	g_EngineVersion = GetEngineVersion();

	SetCTBanChatBanner(g_EngineVersion, g_sChatBanner);

	RegPluginLibrary("ctban");

	CreateForwards();
	CreateNatives();

	return APLRes_Success;
}

public void OnPluginStart()
{
	CreateConVar("sm_ctban_version", PLUGIN_VERSION, "CT Ban Version", FCVAR_SPONLY|FCVAR_DONTRECORD|FCVAR_REPLICATED|FCVAR_NOTIFY);
	gH_Cvar_SoundName = CreateConVar("sm_ctban_soundfile", "buttons/button11.wav", "The name of the sound to play when an action is denied.", FCVAR_NONE);
	gH_Cvar_JoinBanMessage = CreateConVar("sm_ctban_joinbanmsg", "Contact an admin if you would like to request an unban.", "This text is appended to the time the user was last CT banned when they join T or Spectator teams.", FCVAR_NONE);
	gH_Cvar_Table_Prefix = CreateConVar("sm_ctban_table_prefix", "", "Adds a prefix to the CT Bans table, leave this blank unless you have a need to add a prefix for multiple servers on one database.", FCVAR_NONE);
	gH_Cvar_Database_Driver = CreateConVar("sm_ctban_database_driver", "default", "Specifies the configuration driver to use from SourceMod's database.cfg", FCVAR_NONE);
	gH_Cvar_Force_Reason = CreateConVar("sm_ctban_force_reason", "0", "Specifies whether to force admins to specify a reason when using CTBan command", FCVAR_NONE);
	gH_Cvar_CheckCTBans_Flags = CreateConVar("sm_ctban_checkctbans_adminflags", "bz", "The admin flag(s) that may use !isbanned command on anyone. Blank allows all players access on anyone.", FCVAR_NONE);
	gH_Cvar_IsBanned_Self = CreateConVar("sm_ctban_isbanned_selftarget", "0", "Specifies whether to allow non-admins to use !isbanned on themselves.", FCVAR_NONE);
	gH_Cvar_Respawn = CreateConVar("sm_ctban_respawn", "0", "Specifies whether players are respawned after being team changed.", FCVAR_NONE);

	AutoExecConfig(true, "ctban");

	g_CT_Cookie = RegClientCookie("Banned_From_CT", "Tells if you are restricted from joining the CT team", CookieAccess_Protected);

	RegConsoleCmd("sm_isbanned", Command_IsBanned, "sm_isbanned <player> - Lets you know if a player is banned from CT team.");
	RegConsoleCmd("sm_ctbanlist", Command_CTBanList, "sm_ctbanlist - Displays a list of active players who are CT Banned.");

	RegAdminCmd(CTBAN_COMMAND, Command_CTBan, CTBAN_ADMIN_LEVEL, "sm_ctban <player> <time> <optional: reason> - Bans a player from being a CT.");
	RegAdminCmd(REMOVECTBAN_COMMAND, Command_UnCTBan, UNCTBAN_ADMIN_LEVEL, "sm_removectban <player> - Unrestricts a player from being a CT.");
	RegAdminCmd("sm_unctban", Command_UnCTBan, UNCTBAN_ADMIN_LEVEL, "sm_unctban <player> - Unrestricts a player from being a CT.");
	RegAdminCmd(RAGEBAN_COMMAND, Command_RageBan, RAGEBAN_ADMIN_LEVEL, "sm_rageban <player> - Allows you to ban those who rage quit.");
	RegAdminCmd("sm_ctban_offline", Command_Offline_CTBan, ADMFLAG_KICK, "sm_ctban_offline <steamid> - Allows admins to CT Ban players who have long left the server using their Steam Id.");
	RegAdminCmd("sm_unctban_offline", Command_Offline_UnCTBan, ADMFLAG_KICK, "sm_unctban_offline <steamid> - Allows admins to remove CT Bans on players who have long left the server using their Steam Id.");
	RegAdminCmd("sm_removectban_offline", Command_Offline_UnCTBan, ADMFLAG_KICK, "sm_unctban_offline <steamid> - Allows admins to remove CT Bans on players who have long left the server using their Steam Id.");
	RegAdminCmd("sm_reset_ctban_cookies", Command_ResetCookies, ADMFLAG_ROOT, "sm_reset_ctban_cookies <'force'> - Allows the admin to reset all CTBan cookies to be unbanned.");
	RegAdminCmd(FORCECT_COMMAND, Command_ForceCT, FORCECT_ADMIN_LEVEL, "sm_forcect <player> - Temporarily overrides CTBan status and swaps player to CT team.");
	RegAdminCmd(UNFORCECT_COMMAND, Command_UnForceCT, UNFORCECT_ADMIN_LEVEL, "sm_unforcect <player> - Removes any temporary overrides and removes player from CT team.");
	RegAdminCmd("sm_isbanned_offline", Command_Offline_IsBanned, ADMFLAG_SLAY, "sm_isbanned_offline <steamid> - Allows admins to get CT Ban information on offline players user their Steam Id.");
	RegAdminCmd("sm_change_ctban_time", Command_Change_CTBan_Time, ADMFLAG_KICK, "sm_change_ctban_time <player> <time> - Allows the admin to change the time remaining for an existing CTBan.");

	LoadTranslations("ctban.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("clientprefs.phrases");
	LoadTranslations("core.phrases");

	// create arrays for the rage bans
	gA_DNames = CreateArray(MAX_TARGET_LENGTH);
	gA_DSteamIDs = CreateArray(22);
	g_iCookieIndex = ZERO;

	// Hook this to block joins when player is banned
	AddCommandListener(Command_CheckJoin, "jointeam");
	// This is the only sane way to deal with CS:GO auto-assign and plugin conflicts as in CS:GO Team Limit Bypass
	HookEvent("player_spawn", Event_PlayerSpawn, EventHookMode_Post);
	// This will catch anyone that gets swapped manually
	HookEvent("player_team", Event_PlayerTeam, EventHookMode_Post);

	// create local array for timed bans
	// block 0: client index
	gA_TimedBanLocalList = CreateArray(2);
	char sAuthID[FIELD_AUTHID_MAXLENGTH];
	for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
	{
		gA_LocalTimeRemaining[iIndex] = ZERO;

		// Check if we need to remove anyone from CT team immediately
		if (IsClientInGame(iIndex))
		{
			if (GetClientTeam(iIndex) == CS_TEAM_CT && GetCTBanStatus(iIndex))
			{
				EnforceCTBan(iIndex);

				// Gather the time component, if needed
				if (IsClientAuthorized(iIndex))
				{
					GetClientAuthId(iIndex, AuthId_Steam2, sAuthID, sizeof(sAuthID));
					OnClientAuthorized(iIndex, sAuthID);
				}
			}
		}
	}

	// periodic timer to handle timed bans
	CreateTimer(DECREMENT_TIMEBAN_INTERVAL, Timer_CheckTimedCTBans, _, TIMER_REPEAT);

	// Account for late loading
	Handle hTopMenu;
	if (LibraryExists("adminmenu") && ((hTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(hTopMenu);
	}

	gH_DArray_Reasons = CreateArray(FIELD_REASON_MAXLENGTH);

	if (g_EngineVersion == Engine_CSGO)
	{
		HookEvent("jointeam_failed", Event_JoinTeamFailed, EventHookMode_Pre);
	}
	
	AddMultiTargetFilter("@ctban", Filter_CTBanned_Players, "CT Banned Players", false);
	AddMultiTargetFilter("@!ctban", Filter_NotCTBanned_Players, "Players without a CT Ban", false);
	AddMultiTargetFilter("@noctbans", Filter_NeverCTBanned_Players, "Players who have never had a CT Ban", false);
}

public bool Filter_CTBanned_Players(const char[] sPattern, Handle hClients)
{
	for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
	{
		if (IsClientInGame(iIndex))
		{
			if (GetCTBanStatus(iIndex))
			{
				PushArrayCell(hClients, iIndex);
			}
		}
	}
	
	return true;
}

public bool Filter_NotCTBanned_Players(const char[] sPattern, Handle hClients)
{
	for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
	{
		if (IsClientInGame(iIndex))
		{
			if (!GetCTBanStatus(iIndex))
			{
				PushArrayCell(hClients, iIndex);
			}
		}
	}
	
	return true;
}

public bool Filter_NeverCTBanned_Players(const char[] sPattern, Handle hClients)
{
	for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
	{
		if (IsClientInGame(iIndex))
		{
			if (AreClientCookiesCached(iIndex))
			{
				char sCookie[MAX_COOKIE_STR_LENGTH];
				GetClientCookie(iIndex, g_CT_Cookie, sCookie, sizeof(sCookie));
				
				if (!strlen(sCookie))
				{
					PushArrayCell(hClients, iIndex);
				}
			}
		}
	}
	
	return true;
}

void CreateNatives()
{
	CreateNative("CTBan_IsClientBanned", Native_IsClientBanned);
	CreateNative("CTBan_GetTimeRemaining", Native_GetTimeRemaining);
	CreateNative("CTBan_GetOverrideStatus", Native_GetOverrideStatus);
	CreateNative("CTBan_GetBanInfo", Native_GetBanInfo);
	CreateNative("CTBan_GetBanInfo_Offline", Native_GetBanInfo_Offline);

	CreateNative("CTBan_Client", Native_CTBan_Client);
	CreateNative("CTBan_Client_Offline", Native_CTBan_Client_Offline);
	CreateNative("CTBan_ChangeBanLength", Native_CTBan_ChangeBanLength);

	CreateNative("CTBan_UnbanClient", Native_CTBan_UnbanClient);
	CreateNative("CTBan_UnbanClient_Offline", Native_CTBan_UnbanClient_Offline);

	CreateNative("CTBan_ForceCT", Native_CTBan_ForceCT);
	CreateNative("CTBan_UnForceCT", Native_CTBan_UnForceCT);
}

void CreateForwards()
{
	g_hFrwd_OnForceCT = CreateGlobalForward("CTBan_OnForceCT", ET_Ignore, Param_Cell, Param_Cell);
	g_hFrwd_OnUnforceCT = CreateGlobalForward("CTBan_OnUnforceCT", ET_Ignore, Param_Cell, Param_Cell);

	g_hFrwd_OnCTBan = CreateGlobalForward("CTBan_OnClientBan", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_String);
	g_hFrwd_OnCTBan_Offline = CreateGlobalForward("CTBan_OnClientBan_Offline", ET_Ignore, Param_String, Param_Cell);

	g_hFrwd_OnUnCTBan = CreateGlobalForward("CTBan_OnClientUnban", ET_Ignore, Param_Cell, Param_Cell);
	g_hFrwd_OnUnCTBan_Offline = CreateGlobalForward("CTBan_OnClientUnban_Offline", ET_Ignore, Param_String, Param_Cell);

	g_hFrwd_CTBanInfo = CreateGlobalForward("CTBan_GetBanInfoReturn", ET_Ignore, Param_Cell, Param_Cell, Param_Cell, Param_Cell, Param_String, Param_String);
	g_hFrwd_CTBanInfoOffline = CreateGlobalForward("CTBan_GetOfflineBanInfoReturn", ET_Ignore, Param_Cell, Param_String, Param_Cell, Param_Cell, Param_String, Param_String, Param_String);
}

public int Native_IsClientBanned(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(NATIVE_ISBANNED_CELL_CLIENT);

	if (iClient <= ZERO || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client (%d) is invalid!", iClient);
		return ZERO;
	}

	return GetCTBanStatus(iClient);
}

public int Native_GetTimeRemaining(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(NATIVE_GET_TIMELEFT_CELL_CLIENT);

	if (iClient <= ZERO || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client (%d) is invalid!", iClient);
	}

	return gA_LocalTimeRemaining[iClient];
}

public int Native_GetOverrideStatus(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(NATIVE_GET_OVERRIDE_CELL_CLIENT);

	if (iClient <= ZERO || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client (%d) is invalid!", iClient);
		return false;
	}

	return g_bA_Temp_CTBan_Override[iClient];
}

public int Native_GetBanInfo(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(NATIVE_GETBANINFO_CELL_CLIENT);

	if (iClient <= ZERO || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client (%d) is invalid!", iClient);
	}

	ProcessIsBannedTarget(iClient, CALLER_NATIVE);

	return SP_ERROR_NONE;
}

public int Native_GetBanInfo_Offline(Handle hPlugin, int iParams)
{
	char sAuthId[FIELD_AUTHID_MAXLENGTH];
	int iReturn = GetNativeString(NATIVE_GETBANINFO_OFF_STR_AUTHID, sAuthId, sizeof(sAuthId));

	if (iReturn != SP_ERROR_NONE || strlen(sAuthId) < NATIVE_MIN_AUTHID_LENGTH)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid Authid");
	}

	if (IsAuthIdConnected(sAuthId))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "AuthID currently connected.");
	}
	else
	{
		ProcessIsBannedOffline(CALLER_NATIVE, sAuthId);
	}

	return SP_ERROR_NONE;
}

public int Native_CTBan_Client(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(NATIVE_CTBAN_CELL_CLIENT);

	if (iClient <= ZERO || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client (%d) is invalid!", iClient);
	}

	int iMinutes = GetNativeCell(NATIVE_CTBAN_CELL_TIME);

	if (iMinutes < ZERO)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid time specified (%d).", iMinutes);
	}

	int iAdmin = GetNativeCell(NATIVE_CTBAN_CELL_ADMIN);

	if (iAdmin < ZERO || iAdmin > MaxClients || (iAdmin && !IsClientInGame(iAdmin)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Admin (%d) is invalid!", iAdmin);
	}

	char sReason[FIELD_REASON_MAXLENGTH];
	int iReturn = GetNativeString(NATIVE_CTBAN_STR_REASON, sReason, sizeof(sReason));

	if (iReturn != SP_ERROR_NONE)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid reason string");
	}

	if (!GetCTBanStatus(iClient))
	{
		PerformCTBan(iClient, iAdmin, iMinutes, _, sReason);
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, g_sChatBanner, "Already CT Banned", iClient);
	}

	return SP_ERROR_NONE;
}

public int Native_CTBan_Client_Offline(Handle hPlugin, int iParams)
{
	if (!g_bAuthIdNativeExists)
	{
		ThrowNativeError(SP_ERROR_NATIVE, g_sChatBanner, "Feature Not Available");
	}

	char sAuthId[FIELD_AUTHID_MAXLENGTH];
	int iReturn = GetNativeString(NATIVE_CTBAN_OFF_STR_AUTHID, sAuthId, sizeof(sAuthId));

	if (iReturn != SP_ERROR_NONE || strlen(sAuthId) < NATIVE_MIN_AUTHID_LENGTH)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid Authid");
	}

	if (IsAuthIdConnected(sAuthId))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "AuthID currently connected.");
	}
	else
	{
		PerformOfflineCTBan(sAuthId, CALLER_NATIVE);
	}

	return SP_ERROR_NONE;
}

public int Native_CTBan_ChangeBanLength(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(NATIVE_CHANGE_TIME_CELL_CLIENT);

	if (iClient <= ZERO || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client (%d) is invalid!", iClient);
	}

	int iMinutes = GetNativeCell(NATIVE_CHANGE_TIME_CELL_TIME);

	if (iMinutes < ZERO)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid time specified (%d).", iMinutes);
	}

	int iAdmin = GetNativeCell(NATIVE_CHANGE_TIME_CELL_ADMIN);

	if (iAdmin < ZERO || iAdmin > MaxClients || (iAdmin && !IsClientInGame(iAdmin)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Admin (%d) is invalid!", iAdmin);
	}

	if (GetCTBanStatus(iClient))
	{
		// check if time is not changing
		if (gA_LocalTimeRemaining[iClient] == iMinutes || (gA_LocalTimeRemaining[iClient] <= CTBAN_PERM_BAN_LENGTH && iMinutes == CTBAN_PERM_BAN_LENGTH))
		{
			ThrowNativeError(SP_ERROR_NATIVE, g_sChatBanner, "Invalid Amount");
		}
		else
		{
			PerformChangeCTBanTime(iClient, iAdmin, iMinutes);
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, g_sChatBanner, "Not CT Banned", iClient);
	}

	return SP_ERROR_NONE;
}

public int Native_CTBan_UnbanClient(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(NATIVE_UNBAN_CELL_CLIENT);

	if (iClient <= ZERO || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client (%d) is invalid!", iClient);
	}

	int iAdmin = GetNativeCell(NATIVE_UNBAN_CELL_ADMIN);

	if (iAdmin < ZERO || iAdmin > MaxClients || (iAdmin && !IsClientInGame(iAdmin)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Admin (%d) is invalid!", iAdmin);
	}

	if (GetCTBanStatus(iClient))
	{
		// check if the cookies are ready
		if (AreClientCookiesCached(iClient))
		{
			Remove_CTBan(iAdmin, iClient);
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, g_sChatBanner, "Cookie Status Unavailable");
		}
	}
	else
	{
		ThrowNativeError(SP_ERROR_NATIVE, g_sChatBanner, "Not CT Banned", iClient);
	}

	return SP_ERROR_NONE;
}

public int Native_CTBan_UnbanClient_Offline(Handle hPlugin, int iParams)
{
	if (!g_bAuthIdNativeExists)
	{
		ThrowNativeError(SP_ERROR_NATIVE, g_sChatBanner, "Feature Not Available");
	}

	char sAuthId[FIELD_AUTHID_MAXLENGTH];
	int iReturn = GetNativeString(NATIVE_UNBAN_OFF_STR_AUTHID, sAuthId, sizeof(sAuthId));

	if (iReturn != SP_ERROR_NONE || strlen(sAuthId) < NATIVE_MIN_AUTHID_LENGTH)
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Invalid Authid");
	}

	if (IsAuthIdConnected(sAuthId))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "AuthID currently connected.");
	}
	else
	{
		PerformOfflineUnCTBan(sAuthId, CALLER_NATIVE);
	}

	return SP_ERROR_NONE;
}

public int Native_CTBan_ForceCT(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(NATIVE_FORCECT_CELL_CLIENT);

	if (iClient <= ZERO || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client (%d) is invalid!", iClient);
	}

	int iAdmin = GetNativeCell(NATIVE_FORCECT_CELL_ADMIN);

	if (iAdmin < ZERO || iAdmin > MaxClients || (iAdmin && !IsClientInGame(iAdmin)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Admin (%d) is invalid!", iAdmin);
	}

	if (GetClientTeam(iClient) == CS_TEAM_CT)
	{
		ThrowNativeError(SP_ERROR_NATIVE, g_sChatBanner, "Unable to target");
	}
	else
	{
		ForceCTActions(iAdmin, iClient);
	}

	return SP_ERROR_NONE;
}

public int Native_CTBan_UnForceCT(Handle hPlugin, int iParams)
{
	int iClient = GetNativeCell(NATIVE_UNFORCECT_CELL_CLIENT);

	if (iClient <= ZERO || iClient > MaxClients || !IsClientInGame(iClient))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Client (%d) is invalid!", iClient);
	}

	int iAdmin = GetNativeCell(NATIVE_UNFORCECT_CELL_ADMIN);

	if (iAdmin < ZERO || iAdmin > MaxClients || (iAdmin && !IsClientInGame(iAdmin)))
	{
		ThrowNativeError(SP_ERROR_NATIVE, "Admin (%d) is invalid!", iAdmin);
	}

	UnForceCTActions(iAdmin, iClient, true);

	return SP_ERROR_NONE;
}

public void OnAllPluginsLoaded()
{
	g_bAuthIdNativeExists = IsSetAuthIdNativePresent();
}

public Action Event_PlayerSpawn(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));

	if (IsClientInGame(iClient) && GetClientTeam(iClient) == CS_TEAM_CT)
	{
		if (!g_bA_Temp_CTBan_Override[iClient] && GetCTBanStatus(iClient))
		{
			#if defined CTBAN_DEBUG
			LogMessage("%N spawned as CT but was CTBanned. Moving to Terrorist team.", iClient);
			#endif

			EnforceCTBan(iClient);
		}
	}

	return Plugin_Continue;
}

public Action Event_PlayerTeam(Event hEvent, const char[] sName, bool bDontBroadcast)
{
	int iUserID = GetEventInt(hEvent, "userid");
	int iClient = GetClientOfUserId(iUserID);
	int iTeam = GetEventInt(hEvent, "team");
	bool bDisconnected = GetEventBool(hEvent, "disconnect");
	
	if (bDisconnected || !iClient || !IsClientInGame(iClient))
	{
		return Plugin_Continue;
	}
	
	if (iTeam == CS_TEAM_CT && GetCTBanStatus(iClient))
	{	
		// if a CT banned player is on CT and did not get an override they will be swapped after they spawn
		// BUT an admin likely did this and should get instruction to use !forcect
		if (!g_bA_Temp_CTBan_Override[iClient])
		{
			// only admins need the message
			for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
			{
				if (IsClientInGame(iIndex) && CheckCommandAccess(iIndex, "sm_chat", ADMFLAG_CHAT))
				{
					PrintToChat(iIndex, g_sChatBanner, "CTBanned Player On CT Team", iClient);
				}
			}
		}
		
		// if they are still alive then we should not even wait until the respawn
		if (IsPlayerAlive(iClient))
		{
			CreateTimer(DELAY_ENFORCEMENT_TIME, Timer_DelayEnforcement, iUserID, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	
	return Plugin_Continue;
}

public Action Timer_DelayEnforcement(Handle hTimer, any iUserID)
{
	int iClient = GetClientOfUserId(iUserID);
	
	if (iClient && IsClientInGame(iClient) && GetClientTeam(iClient) == CS_TEAM_CT && GetCTBanStatus(iClient))
	{
		EnforceCTBan(iClient);
	}
}

public Action Event_JoinTeamFailed(Handle hEvent, const char[] sName, bool bDontBroadcast)
{
	int iClient = GetClientOfUserId(GetEventInt(hEvent, "userid"));
	if (iClient && IsClientInGame(iClient))
	{
		int iReason = GetEventInt(hEvent, "reason");

		if (iReason == JOINFAILREASON_ONECHANGE)
		{
			// Check if client is banned and is blocked
			if (GetCTBanStatus(iClient))
			{
				#if defined CTBAN_DEBUG
				LogMessage("%N was unable to join a team due to limit. Forcing to Terrorist team.");
				#endif

				ChangeClientTeam(iClient, CS_TEAM_T);

				return Plugin_Handled;
			}
		}
	}

	return Plugin_Continue;
}

// consider if someone does a 'retry' and clientprefs is accessinsg on its ClientConnectCallback and this is also trying to set a value
public void OnClientAuthorized(int iClient, const char[] sAuthID)
{
	// check if the Steam ID is in the Rage Ban list
	int iNeedle = FindStringInArray(gA_DSteamIDs, sAuthID);
	if (iNeedle != VALUE_NOT_FOUND_IN_ARRAY)
	{
		g_bRageBanArrayChanged = true;
		
		RemoveFromArray(gA_DNames, iNeedle);
		RemoveFromArray(gA_DSteamIDs, iNeedle);
		#if defined CTBAN_DEBUG
		LogMessage("removed %N from Rage Bannable player list for re-connecting to the server", iClient);
		#endif
	}

	// check if we have a database connection
	if (gH_BanDatabase != INVALID_HANDLE)
	{
		// check if the Steam ID is in the Timed Ban list
		char sQuery[QUERY_MAXLENGTH];
		Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_SELECT_BANTIME, g_sTimesTableName, sAuthID);
		SQL_TQuery(gH_BanDatabase, DB_Callback_OnClientAuthed, sQuery, view_as<int>(iClient));
	}
	else
	{
		CreateTimer(AUTH_RESCAN_TIME, Timer_OnAuthCheckDatabase, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action Timer_OnAuthCheckDatabase(Handle hTimer, any iClient)
{
	if (gH_BanDatabase != INVALID_HANDLE && IsClientInGame(iClient))
	{
		char sAuthID[FIELD_AUTHID_MAXLENGTH];
		GetClientAuthId(iClient, AuthId_Steam2, sAuthID, sizeof(sAuthID));

		char sQuery[QUERY_MAXLENGTH];
		Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_SELECT_BANTIME, g_sTimesTableName, sAuthID);
		SQL_TQuery(gH_BanDatabase, DB_Callback_OnClientAuthed, sQuery, view_as<int>(iClient));
	}
	else if(IsClientInGame(iClient))
	{
		CreateTimer(AUTH_RESCAN_TIME, Timer_OnAuthCheckDatabase, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public void DB_Callback_OnClientAuthed(Handle hOwner, Handle hCallback, const char[] sError, any iClient)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error in OnClientAuthorized query: %s", sError);
	}
	else
	{
		int iRowCount = SQL_GetRowCount(hCallback);
		#if defined CTBAN_DEBUG
		LogMessage("SQL Auth: %d row count", iRowCount);
		#endif
		if (iRowCount)
		{
			SQL_FetchRow(hCallback);
			int iBanTimeRemaining = SQL_FetchInt(hCallback, CLIENT_AUTHED_CB_FIELD_TIMELEFT);
			#if defined CTBAN_DEBUG
			LogMessage("SQL Auth: %N joined with %i time remaining on ban", iClient, iBanTimeRemaining);
			#endif
			// update local time
			PushArrayCell(gA_TimedBanLocalList, iClient);
			gA_LocalTimeRemaining[iClient] = iBanTimeRemaining;
		}
	}
}

public void AdminMenu_RageBan(Handle hTopMenu, TopMenuAction eAction, TopMenuObject eObjectID, int iClient, char[] sBuffer, int iMaxLength)
{
	if (eAction == TopMenuAction_DisplayOption)
	{
		Format(sBuffer, iMaxLength, "%T", "Rage Ban Admin Menu", iClient);
	}
	else if (eAction == TopMenuAction_SelectOption)
	{
		DisplayRageBanMenu(iClient, GetArraySize(gA_DNames));
	}
}

void DisplayRageBanMenu(int iClient, int iArraySize)
{
	if (iArraySize == ZERO)
	{
		PrintToChat(iClient, g_sChatBanner, "No Targets");
	}
	else
	{
		Handle hMenu = CreateMenu(MenuHandler_RageBan);

		SetMenuTitle(hMenu, "%T", "Rage Ban Menu Title", iClient);
		SetMenuExitBackButton(hMenu, true);

		for (int iArrayIndex = ZERO; iArrayIndex < iArraySize; iArrayIndex++)
		{
			char sName[FIELD_NAME_MAXLENGTH];
			GetArrayString(gA_DNames, iArrayIndex, sName, sizeof(sName));

			char sAuthID[FIELD_AUTHID_MAXLENGTH];
			GetArrayString(gA_DSteamIDs, iArrayIndex, sAuthID, sizeof(sAuthID));

			AddMenuItem(hMenu, sAuthID, sName);
		}

		DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
	}
}

public int MenuHandler_RageBan(Handle hMenu, MenuAction action, int iClient, int iMenuChoice)
{
	if (action == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (action == MenuAction_Cancel)
	{
		if ((iMenuChoice == MenuCancel_ExitBack) && (gH_TopMenu != INVALID_HANDLE))
		{
			DisplayTopMenu(gH_TopMenu, iClient, TopMenuPosition_LastCategory);
		}
	}
	else if (action == MenuAction_Select)
	{
		if (!g_bAuthIdNativeExists)
		{
			ReplyToCommand(iClient, g_sChatBanner, "Feature Not Available");
		}
		else
		{
			char sAuthID[FIELD_AUTHID_MAXLENGTH];
			char sTargetName[MAX_TARGET_LENGTH];
			GetMenuItem(hMenu, iMenuChoice, sAuthID, sizeof(sAuthID), _, sTargetName, sizeof(sTargetName));
			
			#if defined CTBAN_DEBUG
			PrintToChat(iClient, g_sChatBanner, "Ready to CT Ban", sAuthID);
			#endif
			
			SetAuthIdCookie(sAuthID, g_CT_Cookie, COOKIE_BANNED_STRING);

			char sAdminSteamID[FIELD_AUTHID_MAXLENGTH];
			GetClientAuthId(iClient, AuthId_Steam2, sAdminSteamID, sizeof(sAdminSteamID));

			LogMessage("%N (%s) has issued a rage ban on %s (%s) indefinitely.", iClient, sAdminSteamID, sTargetName, sAuthID);

			ShowActivity2(iClient, "", g_sChatBanner, "Rage Ban", sTargetName);

			int iTimeStamp = GetTime();
			char sTempName[FIELD_NAME_MAXLENGTH];
			char sQuery[QUERY_MAXLENGTH];
			char sEscapedPerpName[MAX_SAFE_ESCAPE_QUERY(FIELD_NAME_MAXLENGTH)];
			char sEscapedAdminName[MAX_SAFE_ESCAPE_QUERY(FIELD_NAME_MAXLENGTH)];
			Format(sTempName, sizeof(sTempName), "%s", sTargetName);
			SQL_EscapeString(gH_BanDatabase, sTempName, sEscapedPerpName, sizeof(sEscapedPerpName));
			Format(sTempName, sizeof(sTempName), "%N", iClient);
			SQL_EscapeString(gH_BanDatabase, sTempName, sEscapedAdminName, sizeof(sEscapedAdminName));
			
			Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_INSERT, g_sLogTableName, iTimeStamp, sAuthID, sEscapedPerpName, sAdminSteamID, sEscapedAdminName, CTBAN_PERM_BAN_LENGTH, CTBAN_PERM_BAN_LENGTH, RAGEBAN_LOG_REASON);

			#if defined CTBAN_DEBUG
			LogMessage("log query: %s", sQuery);
			#endif

			SQL_TQuery(gH_BanDatabase, DB_Callback_CTBan, sQuery, iClient);
			
			// Remove any existing time information to make the CTBan permanently
			Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_DELETE, g_sTimesTableName, sAuthID);
			SQL_TQuery(gH_BanDatabase, DB_Callback_DisconnectAction, sQuery);
		}
	}
}

public void CP_Callback_ResetAllCTBans(Handle hOwner, Handle hCallback, const char[] sError, any data)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error reseting the CTBan cookies: %s", sError);
	}
	else
	{
		LogMessage("CTBans Cookie Bans were successfully RESET by the administrator.");
	}
}

public Action Command_Offline_CTBan(int iClient, int iArgs)
{
	if (g_bAuthIdNativeExists)
	{
		char sAuthId[FIELD_AUTHID_MAXLENGTH];
		GetCmdArgString(sAuthId, sizeof(sAuthId));

		if (IsAuthIdConnected(sAuthId))
		{
			ReplyToCommand(iClient, g_sChatBanner, "Unable to target");
		}
		else
		{
			PerformOfflineCTBan(sAuthId, iClient);
		}
	}
	else
	{
		ReplyToCommand(iClient, g_sChatBanner, "Feature Not Available");
	}
	return Plugin_Handled;
}

void PerformOfflineCTBan(char[] sAuthId, int iAdmin)
{
	SetAuthIdCookie(sAuthId, g_CT_Cookie, COOKIE_BANNED_STRING);

	char sAdminSteamID[FIELD_AUTHID_MAXLENGTH];
	if (iAdmin > ZERO)
	{
		GetClientAuthId(iAdmin, AuthId_Steam2, sAdminSteamID, sizeof(sAdminSteamID));
	}
	else
	{
		sAdminSteamID = CONSOLE_AUTHID;
	}

	int iTimeStamp = GetTime();
	char sQuery[QUERY_MAXLENGTH];
	char sTempName[FIELD_NAME_MAXLENGTH];
	char sEscapedPerpAuthId[MAX_SAFE_ESCAPE_QUERY(FIELD_NAME_MAXLENGTH)];
	SQL_EscapeString(gH_BanDatabase, sAuthId, sEscapedPerpAuthId, sizeof(sEscapedPerpAuthId));

	char sEscapedAdminName[MAX_SAFE_ESCAPE_QUERY(FIELD_NAME_MAXLENGTH)];
	if (iAdmin > ZERO)
	{
		Format(sTempName, sizeof(sTempName), "%N", iAdmin);
		SQL_EscapeString(gH_BanDatabase, sTempName, sEscapedAdminName, sizeof(sEscapedAdminName));
	}
	else
	{
		sEscapedAdminName = CONSOLE_USER_NAME;
	}
	
	Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_INSERT, g_sLogTableName, iTimeStamp, sEscapedPerpAuthId, OFFLINE_NAME_UNAVAILBLE, sAdminSteamID, sEscapedAdminName, CTBAN_PERM_BAN_LENGTH, CTBAN_PERM_BAN_LENGTH, REASON_OFFLINECTBAN);

	#if defined CTBAN_DEBUG
	LogMessage("log query: %s", sQuery);
	#endif

	SQL_TQuery(gH_BanDatabase, DB_Callback_CTBan, sQuery, iAdmin);

	if (iAdmin == CALLER_NATIVE)
	{
		// No response
	}
	{
		ReplyToCommand(iAdmin, g_sChatBanner, "Banned AuthId", sAuthId);
	}

	Call_StartForward(g_hFrwd_OnCTBan_Offline);
	Call_PushString(sAuthId);
	Call_PushCell(iAdmin);
	Call_Finish();
}

public Action Command_ForceCT(int iClient, int iArgs)
{
	if (!iClient && !iArgs)
	{
		ReplyToCommand(iClient, g_sChatBanner, "Command Usage", "sm_forcect <player>");
		return Plugin_Handled;
	}

	if (!iArgs)
	{
		DisplayCTBannedPlayerMenu(iClient, e_ForceCT);
		return Plugin_Handled;
	}

	char sTarget[MAX_TARGET_LENGTH];
	GetCmdArg(FORCECT_ARG_TARGET, sTarget, sizeof(sTarget));

	char sClientName[MAX_TARGET_LENGTH];
	int aiTargetList[MAXPLAYERS];
	int iTargetCount;
	bool b_tn_is_ml;
	iTargetCount = ProcessTargetString(sTarget, iClient, aiTargetList, MAXPLAYERS, COMMAND_FILTER_NO_MULTI, sClientName, sizeof(sClientName), b_tn_is_ml);

	if (iTargetCount < ONE)
	{
		ReplyToTargetError(iClient, iTargetCount);
	}
	else
	{
		int iTarget = aiTargetList[ZERO];

		if (iTarget && IsClientInGame(iTarget))
		{
			if (GetClientTeam(iTarget) == CS_TEAM_CT)
			{
				ReplyToCommand(iClient, g_sChatBanner, "Unable to target");
			}
			else
			{
				ForceCTActions(iClient, iTarget);
			}
		}
	}
	return Plugin_Handled;
}

void ForceCTActions(int iAdmin, int iTarget)
{
	if (IsClientInGame(iTarget))
	{
		g_bA_Temp_CTBan_Override[iTarget] = true;

		if (IsPlayerAlive(iTarget))
		{
			StripAllWeapons(iTarget);
			ForcePlayerSuicide(iTarget);
		}

		ChangeClientTeam(iTarget, CS_TEAM_CT);

		if (GetConVarBool(gH_Cvar_Respawn))
		{
			CS_RespawnPlayer(iTarget);
		}

		ShowActivity2(iAdmin, "", g_sChatBanner, "Force CT", iTarget);

		Call_StartForward(g_hFrwd_OnForceCT);
		Call_PushCell(iTarget);
		Call_PushCell(iAdmin);
		Call_Finish();
	}
}

public Action Command_UnForceCT(int iClient, int iArgs)
{
	if (!iClient && !iArgs)
	{
		ReplyToCommand(iClient, g_sChatBanner, "Command Usage", "sm_unforcect <player>");
		return Plugin_Handled;
	}

	if (!iArgs)
	{
		DisplayUnForceCTPlayerMenu(iClient);
		return Plugin_Handled;
	}

	char sTarget[MAX_TARGET_LENGTH];
	GetCmdArg(UNFORCECT_ARG_TARGET, sTarget, sizeof(sTarget));

	char sClientName[MAX_TARGET_LENGTH];
	int aiTargetLlist[MAXPLAYERS];
	int iTargetCount;
	bool b_tn_is_ml;
	iTargetCount = ProcessTargetString(sTarget, iClient, aiTargetLlist, MAXPLAYERS, COMMAND_FILTER_NO_MULTI, sClientName, sizeof(sClientName), b_tn_is_ml);

	if (iTargetCount < ONE)
	{
		ReplyToTargetError(iClient, iTargetCount);
	}
	else
	{
		int iTarget = aiTargetLlist[ZERO];
		UnForceCTActions(iClient, iTarget);
	}
	return Plugin_Handled;
}

void UnForceCTActions(int iAdmin, int iTarget, bool bQuiet = false)
{
	if (!g_bA_Temp_CTBan_Override[iTarget])
	{
		if (!bQuiet)
		{
			ReplyToCommand(iAdmin, g_sChatBanner, "Unable to target");
		}
	}
	else
	{
		if (IsClientInGame(iTarget))
		{
			if (GetClientTeam(iTarget) == CS_TEAM_CT)
			{
				if (IsPlayerAlive(iTarget))
				{
					StripAllWeapons(iTarget);
					ForcePlayerSuicide(iTarget);
				}

				ChangeClientTeam(iTarget, CS_TEAM_T);

				if (GetConVarBool(gH_Cvar_Respawn))
				{
					CS_RespawnPlayer(iTarget);
				}
			}
			g_bA_Temp_CTBan_Override[iTarget] = false;

			if (!bQuiet)
			{
				ShowActivity2(iAdmin, "", g_sChatBanner, "Unforce CT", iTarget);
			}

			Call_StartForward(g_hFrwd_OnUnforceCT);
			Call_PushCell(iTarget);
			Call_PushCell(iAdmin);
			Call_Finish();
		}
	}
}

void DisplayUnForceCTPlayerMenu(int iClient)
{
	Handle hMenu = CreateMenu(MenuHandler_UnForceCT);

	SetMenuTitle(hMenu, "%T", "UnForce CT Menu Title", iClient);
	SetMenuExitBackButton(hMenu, true);

	int iCount = ZERO;
	char sUserId[MAX_USERID_LENGTH];
	char sName[MAX_NAME_LENGTH];

	// filter away those with current overrides
	for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
	{
		if (IsClientInGame(iIndex))
		{
			if (g_bA_Temp_CTBan_Override[iIndex])
			{
				IntToString(GetClientUserId(iIndex), sUserId, sizeof(sUserId));
				GetClientName(iIndex, sName, sizeof(sName));

				AddMenuItem(hMenu, sUserId, sName);

				iCount++;
			}
		}
	}

	if (!iCount)
	{
		PrintToChat(iClient, g_sChatBanner, "No matching clients");
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public Action Command_ResetCookies(int iClient, int iArgs)
{
	char sArgs[MAX_RESET_ARG_LENGTH];
	GetCmdArgString(sArgs, sizeof(sArgs));

	if (StrEqual("force", sArgs))
	{
		if (!g_iCookieIndex)
		{
			ReplyToCommand(iClient, g_sChatBanner, "Cookie not Found", "Banned_From_CT");
		}
		else
		{
			char sQuery[QUERY_MAXLENGTH];
			Format(sQuery, sizeof(sQuery), CTBAN_QUERY_CP_RESET_COOKIES, g_iCookieIndex);
			
			#if defined CTBAN_DEBUG
			LogMessage("Query to run: %s", sQuery);
			#endif
			
			SQL_TQuery(gH_CP_DataBase, CP_Callback_ResetAllCTBans, sQuery);

			ShowActivity2(iClient, "", g_sChatBanner, "Reset Cookies");
		}
	}
	else
	{
		ReplyToCommand(iClient, g_sChatBanner, "Reset Cookie Confirmation");
	}

	return Plugin_Handled;
}

public Action Command_Offline_UnCTBan(int iClient, int iArgs)
{
	if (g_bAuthIdNativeExists)
	{
		char sAuthId[FIELD_AUTHID_MAXLENGTH];
		GetCmdArgString(sAuthId, sizeof(sAuthId));

		if (IsAuthIdConnected(sAuthId))
		{
			ReplyToCommand(iClient, g_sChatBanner, "Unable to target");
		}
		else
		{
			PerformOfflineUnCTBan(sAuthId, iClient);
		}
	}
	else
	{
		ReplyToCommand(iClient, g_sChatBanner, "Feature Not Available");
	}

	return Plugin_Handled;
}

void PerformOfflineUnCTBan(char[] sAuthId, int iAdmin)
{
	SetAuthIdCookie(sAuthId, g_CT_Cookie, COOKIE_UNBANNED_STRING);

	char sEscapedAuthId[MAX_SAFE_ESCAPE_QUERY(FIELD_NAME_MAXLENGTH)];
	SQL_EscapeString(gH_BanDatabase, sAuthId, sEscapedAuthId, sizeof(sEscapedAuthId));

	char sQuery[QUERY_MAXLENGTH];
	Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_EXPIRE, g_sLogTableName, sEscapedAuthId);

	#if defined CTBAN_DEBUG
	LogMessage("log query: %s", sQuery);
	#endif

	SQL_TQuery(gH_BanDatabase, DB_Callback_RemoveCTBan, sQuery, CALLER_DO_NOT_REPLY);

	// delete from the timedban database if there was one
	Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_DELETE, g_sTimesTableName, sEscapedAuthId);

	#if defined CTBAN_DEBUG
	LogMessage("log query: %s", sQuery);
	#endif

	SQL_TQuery(gH_BanDatabase, DB_Callback_RemoveCTBan, sQuery, CALLER_DO_NOT_REPLY);

	if (iAdmin == CALLER_NATIVE)
	{
		// No response
	}
	else
	{
		ReplyToCommand(iAdmin, g_sChatBanner, "Unbanned AuthId", sAuthId);

		LogMessage("%N has removed the CT ban on %s.", iAdmin, sAuthId);
	}

	Call_StartForward(g_hFrwd_OnUnCTBan_Offline);
	Call_PushString(sAuthId);
	Call_PushCell(iAdmin);
	Call_Finish();
}

public Action Command_RageBan(int iClient, int iArgs)
{
	int iArraySize = GetArraySize(gA_DNames);
	if (iArraySize == ZERO)
	{
		ReplyToCommand(iClient, g_sChatBanner, "No Targets");
		return Plugin_Handled;
	}

	if (!iArgs)
	{
		if (iClient)
		{
			DisplayRageBanMenu(iClient, iArraySize);
		}
		// Console user
		else
		{
			PrintToServer(g_sChatBanner, "Rage Ban Menu Title");
			
			for (int iArrayIndex = ZERO; iArrayIndex < iArraySize; iArrayIndex++)
			{
				char sName[FIELD_NAME_MAXLENGTH];
				GetArrayString(gA_DNames, iArrayIndex, sName, sizeof(sName));

				char sAuthID[FIELD_AUTHID_MAXLENGTH];
				GetArrayString(gA_DSteamIDs, iArrayIndex, sAuthID, sizeof(sAuthID));

				PrintToServer("[CTBAN] (%d.) %s [%s]", iArrayIndex + ONE, sName, sAuthID);
			}
			
			g_bRageBanArrayChanged = false;
		}
		return Plugin_Handled;
	}
	else
	{
		if (iClient)
		{
			ReplyToCommand(iClient, g_sChatBanner, "Command Usage", RAGEBAN_COMMAND);
		}
		// Console user
		else
		{
			char sTarget[MAX_MENU_INT_CHOICE_LENGTH];
			GetCmdArg(RAGEBAN_ARG_CONSOLE_TARGET, sTarget, sizeof(sTarget));
			
			int iArrayIndex = StringToInt(sTarget) - ONE;
			
			if ((iArrayIndex >= iArraySize) || (iArrayIndex < ZERO))
			{
				ReplyToCommand(iClient, g_sChatBanner, "No matching client");
			}
			else if (g_bRageBanArrayChanged)
			{
				ReplyToCommand(iClient, g_sChatBanner, "Player no longer available");
			}
			else
			{
				char sTargetName[FIELD_NAME_MAXLENGTH];
				GetArrayString(gA_DNames, iArrayIndex, sTargetName, sizeof(sTargetName));

				char sAuthID[FIELD_AUTHID_MAXLENGTH];
				GetArrayString(gA_DSteamIDs, iArrayIndex, sAuthID, sizeof(sAuthID));
				
				#if defined CTBAN_DEBUG
				PrintToServer(g_sChatBanner, "Ready to CT Ban", sAuthID);
				#endif
				
				SetAuthIdCookie(sAuthID, g_CT_Cookie, COOKIE_BANNED_STRING);

				LogMessage("%N has issued a rage ban on %s (%s) indefinitely.", iClient, sTargetName, sAuthID);

				ShowActivity2(iClient, "", g_sChatBanner, "Rage Ban", sTargetName);

				int iTimeStamp = GetTime();
				char sTempName[FIELD_NAME_MAXLENGTH];
				char sQuery[QUERY_MAXLENGTH];
				char sEscapedPerpName[MAX_SAFE_ESCAPE_QUERY(FIELD_NAME_MAXLENGTH)];
				Format(sTempName, sizeof(sTempName), "%s", sTargetName);
				SQL_EscapeString(gH_BanDatabase, sTempName, sEscapedPerpName, sizeof(sEscapedPerpName));
				
				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_INSERT, g_sLogTableName, iTimeStamp, sAuthID, sEscapedPerpName, CONSOLE_AUTHID, CONSOLE_USER_NAME, CTBAN_PERM_BAN_LENGTH, CTBAN_PERM_BAN_LENGTH, RAGEBAN_LOG_REASON);

				#if defined CTBAN_DEBUG
				LogMessage("log query: %s", sQuery);
				#endif

				SQL_TQuery(gH_BanDatabase, DB_Callback_CTBan, sQuery, iClient);
				
				// Remove any existing time information to make the CTBan permanently
				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_DELETE, g_sTimesTableName, sAuthID);
				SQL_TQuery(gH_BanDatabase, DB_Callback_DisconnectAction, sQuery);
			}
		}
	}

	return Plugin_Handled;
}

public Action Timer_CheckTimedCTBans(Handle hTimer)
{
	// check if anyone has a time
	int iTimeArraySize = GetArraySize(gA_TimedBanLocalList);

	// credit for this idea goes to Kigen
	for (int iIndex = ZERO; iIndex < iTimeArraySize; iIndex++)
	{
		int iBannedClientIndex = GetArrayCell(gA_TimedBanLocalList, iIndex);
		if (IsClientInGame(iBannedClientIndex))
		{
			if (IsPlayerAlive(iBannedClientIndex))
			{
				gA_LocalTimeRemaining[iBannedClientIndex]--;

				#if defined CTBAN_DEBUG
				LogMessage("found alive time banned client with %i remaining", gA_LocalTimeRemaining[iBannedClientIndex]);
				#endif

				// check if we should remove the CT ban
				if (gA_LocalTimeRemaining[iBannedClientIndex] <= ZERO)
				{
					// remove CT ban
					RemoveFromArray(gA_TimedBanLocalList, iIndex);
					iTimeArraySize--;

					Remove_CTBan(ZERO, iBannedClientIndex, true);

					#if defined CTBAN_DEBUG
					LogMessage("removed CT ban on %N", iBannedClientIndex);
					#endif
				}
			}
		}
	}
}

public void OnConfigsExecuted()
{
	#if defined CTBAN_DEBUG
	LogMessage("Connecting to clientprefs database");
	#endif

	SQL_TConnect(CP_Callback_Connect, "clientprefs");

	char sDatabaseDriver[64];
	GetConVarString(gH_Cvar_Database_Driver, sDatabaseDriver, sizeof(sDatabaseDriver));

	#if defined CTBAN_DEBUG
	LogMessage("Connecting to log database");
	#endif

	SQL_TConnect(DB_Callback_Connect, sDatabaseDriver);

	ParseCTBanReasonsFile(gH_DArray_Reasons);
	
	gH_KV_BanLengths = ParseCTBanLengthsFile(gH_KV_BanLengths);
}

public void DB_Callback_Connect(Handle hOwner, Handle hCallback, const char[] sError, any data)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Default database database connection failure: %s", sError);
		SetFailState("Error while connecting to default database. Exiting.");
	}
	else
	{
		gH_BanDatabase = hCallback;

		// Determine the type of database we're on so we may modify the syntax of queries
		char sDatabaseID[MAX_DATABASE_ID_LENGTH];
		SQL_GetDriverIdent(SQL_ReadDriver(gH_BanDatabase), sDatabaseID, sizeof(sDatabaseID));
		if (StrEqual(sDatabaseID, "mysql"))
		{
			g_eDatabaseType = e_MySQL;
		}
		else if (StrEqual(sDatabaseID, "sqlite"))
		{
			g_eDatabaseType = e_SQLite;
		}
		else
		{
			g_eDatabaseType = e_Unknown;
		}

		// figure out table prefix situation
		char sPrefix[MAX_TABLE_LENGTH - MAX_DEFAULT_TABLE_LENGTH];
		GetConVarString(gH_Cvar_Table_Prefix, sPrefix, sizeof(sPrefix));
		if (strlen(sPrefix) > ZERO)
		{
			Format(g_sTimesTableName, sizeof(g_sTimesTableName), "%s_CTBan_Times", sPrefix);
		}
		else
		{
			Format(g_sTimesTableName, sizeof(g_sTimesTableName), "CTBan_Times");
		}

		char sQuery[QUERY_MAXLENGTH];
		Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_CREATE, g_sTimesTableName, FIELD_AUTHID_MAXLENGTH);

		#if defined CTBAN_DEBUG
		LogMessage("times table create query %s", sQuery);
		#endif

		// create database if not already there
		SQL_TQuery(gH_BanDatabase, DB_Callback_CreateTime, sQuery);

		if (strlen(sPrefix) > ZERO)
		{
			Format(g_sLogTableName, sizeof(g_sLogTableName), "%s_CTBan_Log", sPrefix);
		}
		else
		{
			Format(g_sLogTableName, sizeof(g_sLogTableName), "CTBan_Log");
		}

		Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_CREATE, g_sLogTableName, FIELD_AUTHID_MAXLENGTH, FIELD_NAME_MAXLENGTH, FIELD_AUTHID_MAXLENGTH, FIELD_NAME_MAXLENGTH, FIELD_REASON_MAXLENGTH);

		#if defined CTBAN_DEBUG
		LogMessage("log table create query %s", sQuery);
		#endif

		SQL_TQuery(gH_BanDatabase, DB_Callback_CreateLog, sQuery);
	}
}

public void DB_Callback_CheckTableVersion(Handle hOwner, Handle hCallback, const char[] sError, any data)
{
	if (hCallback == INVALID_HANDLE)
	{
		#if defined CTBAN_DEBUG
		LogMessage("Table layout check revealed this error: %s", sError);
		#endif

		// Check specifically for if there was a problem finding the ban_id column
		if (StrContains(sError, "column", false) != SUBSTRING_NOT_FOUND)
		{
			LogMessage("Upgrading CTBan_Log Table to Version Two...");
			
			char sQuery[QUERY_MAXLENGTH];
			Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_TO_V2_DROPKEY, g_sLogTableName);

			#if defined CTBAN_DEBUG
			LogMessage("alter primary key query: %s", sQuery);
			#endif

			SQL_TQuery(gH_BanDatabase, DB_Callback_UpgradeToLogTableTwo, sQuery);
		}
	}
}

public void DB_Callback_UpgradeToLogTableTwo(Handle hOwner, Handle hCallback, const char[] sError, any data)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error upgrading log table: %s", sError);
		SetFailState("Error while upgrading to Log Table Version Two. Exiting.");
	}

	char sQuery[QUERY_MAXLENGTH];
	Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_TO_V2_ADD_BANID, g_sLogTableName);

	#if defined CTBAN_DEBUG
	LogMessage("add ban_id query: %s", sQuery);
	#endif

	SQL_TQuery(gH_BanDatabase, DB_Callback_LogError, sQuery, e_QueryLogTableTwo);
}

public void DB_Callback_LogError(Handle hOwner, Handle hCallback, const char[] sError, any eCallback)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error: %s", sError);
	}
	else
	{
		switch (eCallback)
		{
			case e_QueryLogTableTwo:
			{
				LogMessage("CTBan_Log Table Successfully Upgraded to Version Two");
			}
		}
	}
}

public void DB_Callback_CreateTime(Handle hOwner, Handle hCallback, const char[] sError, any data)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error establishing table creation: %s", sError);
		SetFailState("Unable to ascertain creation of table in default database. Exiting.");
	}
}

public void DB_Callback_CreateLog(Handle hOwner, Handle hCallback, const char[] sError, any data)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error establishing table creation: %s", sError);
		SetFailState("Unable to ascertain creation of table in default database. Exiting.");
	}

	// Check the log table and upgrade to the new version if needed
	char sQuery[QUERY_MAXLENGTH];
	
	Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_V1_CHECK, g_sLogTableName);

	#if defined CTBAN_DEBUG
	LogMessage("check table version query %s", sQuery);
	#endif

	SQL_TQuery(gH_BanDatabase, DB_Callback_CheckTableVersion, sQuery);
}

public void CP_Callback_Connect(Handle hOwner, Handle hCallback, const char[] sError, any data)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Clientprefs database connection failure: %s", sError);
		SetFailState("Error while connecting to clientprefs database. Exiting.");
	}
	else
	{
		gH_CP_DataBase = hCallback;

		// find the Banned_From_CT Cookie id #
		SQL_TQuery(gH_CP_DataBase, CP_Callback_FindCookie, CTBAN_QUERY_CP_FIND_COOKIE_ID);
	}
}

public void CP_Callback_FindCookie(Handle hOwner, Handle hCallback, const char[] sError, any data)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Cookie query failure: %s", sError);
	}
	else
	{
		int iRowCount = SQL_GetRowCount(hCallback);
		if (iRowCount)
		{
			SQL_FetchRow(hCallback);
			int iCookieIDIndex = SQL_FetchInt(hCallback, FIND_COOKIE_CB_FIELD_COOKIE_ID);
			#if defined CTBAN_DEBUG
			LogMessage("found cookie index as %i", iCookieIDIndex);
			#endif
			g_iCookieIndex = iCookieIDIndex;
		}
		else
		{
			LogError("Could not find the cookie index. Rageban functionality disabled.");
		}
	}
}

public void OnMapEnd()
{
	g_bIgnoreOverrideResets = true;
}

public void OnMapStart()
{
	// pre-cache deny sound
	char sCommand[PLATFORM_MAX_PATH];
	GetConVarString(gH_Cvar_SoundName, gS_SoundPath, sizeof(gS_SoundPath));
	if(strcmp(gS_SoundPath, ""))
	{
		PrecacheSound(gS_SoundPath, true);
		Format(sCommand, sizeof(sCommand), "sound/%s", gS_SoundPath);
		AddFileToDownloadsTable(sCommand);
	}

	g_bIgnoreOverrideResets = false;
}

public void OnAdminMenuReady(Handle hTopMenu)
{
	// Block us from being called twice
	if (hTopMenu == gH_TopMenu)
	{
		return;
	}

	// Save the Handle
	gH_TopMenu = hTopMenu;

	// Build the "Player Commands" category
	TopMenuObject player_commands = FindTopMenuCategory(gH_TopMenu, ADMINMENU_PLAYERCOMMANDS);

	if (player_commands != INVALID_TOPMENUOBJECT)
	{
		AddToTopMenu(gH_TopMenu,
			RAGEBAN_COMMAND,
			TopMenuObject_Item,
			AdminMenu_RageBan,
			player_commands,
			RAGEBAN_COMMAND,
			RAGEBAN_ADMIN_LEVEL);

		AddToTopMenu(gH_TopMenu,
			CTBAN_COMMAND,
			TopMenuObject_Item,
			AdminMenu_CTBan,
			player_commands,
			CTBAN_COMMAND,
			CTBAN_ADMIN_LEVEL);

		AddToTopMenu(gH_TopMenu,
			REMOVECTBAN_COMMAND,
			TopMenuObject_Item,
			AdminMenu_RemoveCTBan,
			player_commands,
			REMOVECTBAN_COMMAND,
			UNCTBAN_ADMIN_LEVEL);

		AddToTopMenu(gH_TopMenu,
			FORCECT_COMMAND,
			TopMenuObject_Item,
			AdminMenu_ForceCT,
			player_commands,
			FORCECT_COMMAND,
			FORCECT_ADMIN_LEVEL);

		AddToTopMenu(gH_TopMenu,
			UNFORCECT_COMMAND,
			TopMenuObject_Item,
			AdminMenu_UnForceCT,
			player_commands,
			UNFORCECT_COMMAND,
			UNFORCECT_ADMIN_LEVEL);
	}
}

public void AdminMenu_ForceCT(Handle hTopMenu,
					  TopMenuAction eAction,
					  TopMenuObject eObjectID,
					  int iClient,
					  char[] sBuffer,
					  int iMaxLength)
{
	if (eAction == TopMenuAction_DisplayOption)
	{
		Format(sBuffer, iMaxLength, "%T", "Force CT Admin Menu", iClient);
	}
	else if (eAction == TopMenuAction_SelectOption)
	{
		DisplayCTBannedPlayerMenu(iClient, e_ForceCT);
	}
}

public void AdminMenu_UnForceCT(Handle hTopMenu,
					  TopMenuAction eAction,
					  TopMenuObject eObjectID,
					  int iClient,
					  char[] sBuffer,
					  int iMaxLength)
{
	if (eAction == TopMenuAction_DisplayOption)
	{
		Format(sBuffer, iMaxLength, "%T", "UnForce CT Admin Menu", iClient);
	}
	else if (eAction == TopMenuAction_SelectOption)
	{
		DisplayUnForceCTPlayerMenu(iClient);
	}
}

public void AdminMenu_RemoveCTBan(Handle hTopMenu,
					  TopMenuAction eAction,
					  TopMenuObject eObjectID,
					  int iClient,
					  char[] sBuffer,
					  int iMaxLength)
{
	if (eAction == TopMenuAction_DisplayOption)
	{
		Format(sBuffer, iMaxLength, "%T", "Remove CT Ban Admin Menu", iClient);
	}
	else if (eAction == TopMenuAction_SelectOption)
	{
		DisplayCTBannedPlayerMenu(iClient, e_RemoveCTBan);
	}
}

// displaying the list of CT Banned players is used by two commands
// default is for Remove CT Ban
// optional boolean is for CTBan List
void DisplayCTBannedPlayerMenu(int iClient, eCTBanMenuHandler eChoice)
{
	Handle hMenu = INVALID_HANDLE;

	switch (eChoice)
	{
		case e_RemoveCTBan:
		{
			hMenu = CreateMenu(MenuHandler_RemoveCTBanPlayerList);
			SetMenuTitle(hMenu, "%T", "Remove CT Ban Menu Title", iClient);
			SetMenuExitBackButton(hMenu, true);
		}
		case e_CTBanList:
		{
			hMenu = CreateMenu(MenuHandler_CTBanList);
			SetMenuTitle(hMenu, "%T", "CTBanList Menu Title", iClient);
			SetMenuExitBackButton(hMenu, false);
		}
		case e_ForceCT:
		{
			hMenu = CreateMenu(MenuHandler_ForceCT);
			SetMenuTitle(hMenu, "%T", "Force CT Menu Title", iClient);
			SetMenuExitBackButton(hMenu, true);
		}
	}

	int iCount = ZERO;
	char sUserId[MAX_USERID_LENGTH];
	char sName[MAX_NAME_LENGTH];

	// display only people with existing CTBans
	for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
	{
		if (IsClientInGame(iIndex))
		{
			if (GetCTBanStatus(iIndex))
			{
				// Do no list people with overrides for Force CT Menu
				if (eChoice == e_ForceCT && g_bA_Temp_CTBan_Override[iIndex])
				{
					continue;
				}

				IntToString(GetClientUserId(iIndex), sUserId, sizeof(sUserId));
				GetClientName(iIndex, sName, sizeof(sName));

				AddMenuItem(hMenu, sUserId, sName);

				iCount++;
			}
		}
	}

	if (!iCount)
	{
		PrintToChat(iClient, g_sChatBanner, "No matching clients");
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_UnForceCT(Handle hMenu, MenuAction eAction, int iClient, int iMenuChoice)
{
	if (eAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (eAction == MenuAction_Select)
	{
		char sTargetUserId[MAX_USERID_LENGTH];
		GetMenuItem(hMenu, iMenuChoice, sTargetUserId, sizeof(sTargetUserId));
		int iTargetUserId = StringToInt(sTargetUserId);
		int iTarget = GetClientOfUserId(iTargetUserId);

		if (!iTarget || !IsClientInGame(iTarget))
		{
			PrintToChat(iClient, g_sChatBanner, "Player no longer available");
		}
		else if (!g_bA_Temp_CTBan_Override[iTarget])
		{
			PrintToChat(iClient, g_sChatBanner, "Player no longer available");
		}
		else
		{
			UnForceCTActions(iClient, iTarget);
		}
	}
}


public int MenuHandler_ForceCT(Handle hMenu, MenuAction eAction, int iClient, int iMenuChoice)
{
	if (eAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (eAction == MenuAction_Select)
	{
		char sTargetUserId[MAX_USERID_LENGTH];
		GetMenuItem(hMenu, iMenuChoice, sTargetUserId, sizeof(sTargetUserId));
		int iTargetUserId = StringToInt(sTargetUserId);
		int iTarget = GetClientOfUserId(iTargetUserId);

		if (!iTarget || !IsClientInGame(iTarget))
		{
			PrintToChat(iClient, g_sChatBanner, "Player no longer available");
		}
		else if (GetClientTeam(iTarget) == CS_TEAM_CT)
		{
			PrintToChat(iClient, g_sChatBanner, "Unable to target");
		}
		else
		{
			ForceCTActions(iClient, iTarget);
		}
	}
}

public int MenuHandler_CTBanList(Handle hMenu, MenuAction eAction, int iClient, int iMenuChoice)
{
	if (eAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (eAction == MenuAction_Select)
	{
		char sTargetUserId[MAX_USERID_LENGTH];
		GetMenuItem(hMenu, iMenuChoice, sTargetUserId, sizeof(sTargetUserId));
		int iTargetUserId = StringToInt(sTargetUserId);
		int iTarget = GetClientOfUserId(iTargetUserId);

		if (!iTarget || !IsClientInGame(iTarget))
		{
			PrintToChat(iClient, g_sChatBanner, "Player no longer available");
		}
		else if (!GetCTBanStatus(iTarget, iClient))
		{
			PrintToChat(iClient, g_sChatBanner, "Not CT Banned", iTarget);
		}
		else
		{
			ProcessIsBannedTarget(iTarget, iClient);
		}
	}
}

public int MenuHandler_RemoveCTBanPlayerList(Handle hMenu, MenuAction eAction, int iClient, int iMenuChoice)
{
	if (eAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (eAction == MenuAction_Cancel)
	{
		if (iMenuChoice == MenuCancel_ExitBack && gH_TopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(gH_TopMenu, iClient, TopMenuPosition_LastCategory);
		}
	}
	else if (eAction == MenuAction_Select)
	{
		char sTargetUserId[MAX_USERID_LENGTH];
		GetMenuItem(hMenu, iMenuChoice, sTargetUserId, sizeof(sTargetUserId));
		int iTargetUserId = StringToInt(sTargetUserId);
		int iTarget = GetClientOfUserId(iTargetUserId);

		if (!iTarget || !IsClientInGame(iTarget))
		{
			PrintToChat(iClient, g_sChatBanner, "Player no longer available");
		}
		else if (!CanUserTarget(iClient, iTarget))
		{
			PrintToChat(iClient, g_sChatBanner, "Unable to target");
		}
		else if (!GetCTBanStatus(iTarget, iClient))
		{
			PrintToChat(iClient, g_sChatBanner, "Not CT Banned", iTarget);
		}
		else
		{
			if (AreClientCookiesCached(iTarget))
			{
				Remove_CTBan(iClient, iTarget);
			}
			else
			{
				ReplyToCommand(iClient, g_sChatBanner, "Cookie Status Unavailable");
			}
		}
	}
}

public void AdminMenu_CTBan(Handle hTopMenu,
					  TopMenuAction eAction,
					  TopMenuObject eObjectID,
					  int iClient,
					  char[] sBuffer,
					  int iMaxLength)
{
	if (eAction == TopMenuAction_DisplayOption)
	{
		Format(sBuffer, iMaxLength, "%T", "CT Ban Admin Menu", iClient);
	}
	else if (eAction == TopMenuAction_SelectOption)
	{
		DisplayCTBanPlayerMenu(iClient);
	}
}

void DisplayCTBanPlayerMenu(int iClient)
{
	Handle hMenu = CreateMenu(MenuHandler_CTBanPlayerList);

	SetMenuTitle(hMenu, "%T", "CT Ban Menu Title", iClient);
	SetMenuExitBackButton(hMenu, true);

	int iCount = ZERO;
	char sUserId[MAX_USERID_LENGTH];
	char sName[MAX_NAME_LENGTH];

	// filter away those with current CTBans
	for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
	{
		if (IsClientInGame(iIndex))
		{
			if (!GetCTBanStatus(iIndex))
			{
				IntToString(GetClientUserId(iIndex), sUserId, sizeof(sUserId));
				GetClientName(iIndex, sName, sizeof(sName));

				AddMenuItem(hMenu, sUserId, sName);

				iCount++;
			}
		}
	}

	if (!iCount)
	{
		PrintToChat(iClient, g_sChatBanner, "No Targets");
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

void DisplayCTBanTimeMenu(int iClient, int iTargetUserId)
{
	Handle hMenu = CreateMenu(MenuHandler_CTBanTimeList);

	SetMenuTitle(hMenu, "%T", "CT Ban Length Menu", iClient, GetClientOfUserId(iTargetUserId));
	SetMenuExitBackButton(hMenu, true);

	char sUserId[MAX_USERID_LENGTH];
	IntToString(iTargetUserId, sUserId, sizeof(sUserId));
	AddMenuItem(hMenu, sUserId, "", ITEMDRAW_IGNORE);

	if (gH_KV_BanLengths != INVALID_HANDLE)
	{
		char sBanDuration[MAX_TIME_ARG_LENGTH];
		char sDurationDescription[MAX_TIME_INFO_STR_LENGTH];
		
		KvGotoFirstSubKey(gH_KV_BanLengths, false);
		do
		{
			KvGetSectionName(gH_KV_BanLengths, sBanDuration, sizeof(sBanDuration));
			KvGetString(gH_KV_BanLengths, NULL_STRING, sDurationDescription, sizeof(sDurationDescription));
			
			AddMenuItem(hMenu, sBanDuration, sDurationDescription);
		}
		while (KvGotoNextKey(gH_KV_BanLengths, false));
		
		KvRewind(gH_KV_BanLengths);
	}
	else
	{
		AddMenuItem(hMenu, "0", "Permanent");
		AddMenuItem(hMenu, "5", "5 Minutes");
		// Only add 6 items in CS:GO menus so we don't paginate
		if (g_EngineVersion != Engine_CSGO)
		{
			AddMenuItem(hMenu, "10", "10 Minutes");
		}
		AddMenuItem(hMenu, "30", "30 Minutes");
		AddMenuItem(hMenu, "60", "1 Hour");
		AddMenuItem(hMenu, "120", "2 Hours");
		AddMenuItem(hMenu, "240", "4 Hours");
	}
	
	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

void DisplayCTBanReasonMenu(int iClient, int iTargetUserId, int iMinutesToBan)
{
	Handle hMenu = CreateMenu(MenuHandler_CTBanReasonList);

	SetMenuTitle(hMenu, "%T", "CT Ban Reason Menu", iClient, GetClientOfUserId(iTargetUserId));
	SetMenuExitBackButton(hMenu, true);

	char sTargetUserId[MAX_USERID_LENGTH];
	IntToString(iTargetUserId, sTargetUserId, sizeof(sTargetUserId));
	AddMenuItem(hMenu, sTargetUserId, "", ITEMDRAW_IGNORE);

	char sTimeInMinutes[MAX_TIME_ARG_LENGTH];
	IntToString(iMinutesToBan, sTimeInMinutes, sizeof(sTimeInMinutes));
	AddMenuItem(hMenu, sTimeInMinutes, "", ITEMDRAW_IGNORE);

	int iNumManualReasons = GetArraySize(gH_DArray_Reasons);

	char sMenuReason[FIELD_REASON_MAXLENGTH];
	char sMenuInt[MAX_MENU_INT_CHOICE_LENGTH];

	if (iNumManualReasons > ZERO)
	{
		for (int iLineNumber = ZERO; iLineNumber < iNumManualReasons; iLineNumber++)
		{
			GetArrayString(gH_DArray_Reasons, iLineNumber, sMenuReason, sizeof(sMenuReason));
			IntToString(iLineNumber, sMenuInt, sizeof(sMenuInt));
			AddMenuItem(hMenu, sMenuInt, sMenuReason);
		}
	}
	else
	{
		// Only display 6 reasons in CS:GO by default to avoid pagination
		// Freekill Massacre is a redundant reason with Freekilling "CT Ban Reason 5"
		if (g_EngineVersion != Engine_CSGO)
		{
			Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 1", iClient);
			AddMenuItem(hMenu, "1", sMenuReason);
		}
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 2", iClient);
		AddMenuItem(hMenu, "2", sMenuReason);
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 3", iClient);
		AddMenuItem(hMenu, "3", sMenuReason);
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 4", iClient);
		AddMenuItem(hMenu, "4", sMenuReason);
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 5", iClient);
		AddMenuItem(hMenu, "5", sMenuReason);
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 6", iClient);
		AddMenuItem(hMenu, "6", sMenuReason);
		Format(sMenuReason, sizeof(sMenuReason), "%T", "CT Ban Reason 7", iClient);
		AddMenuItem(hMenu, "7", sMenuReason);
	}

	DisplayMenu(hMenu, iClient, MENU_TIME_FOREVER);
}

public int MenuHandler_CTBanReasonList(Handle hMenu, MenuAction eAction, int iClient, int iMenuChoice)
{
	if (eAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (eAction == MenuAction_Cancel)
	{
		if (iMenuChoice == MenuCancel_ExitBack && gH_TopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(gH_TopMenu, iClient, TopMenuPosition_LastCategory);
		}
	}
	else if (eAction == MenuAction_Select)
	{
		char sTargetUserId[MAX_USERID_LENGTH];
		GetMenuItem(hMenu, MENUCHOICE_USERID, sTargetUserId, sizeof(sTargetUserId));
		int iTargetUserId = StringToInt(sTargetUserId);

		char sTimeInMinutes[MAX_TIME_ARG_LENGTH];
		GetMenuItem(hMenu, MENUCHOICE_TIME, sTimeInMinutes, sizeof(sTimeInMinutes));
		int iMinutesToBan = StringToInt(sTimeInMinutes);

		char sBanChoice[MAX_REASON_MENU_CHOICE_LENGTH];
		GetMenuItem(hMenu, iMenuChoice, sBanChoice, sizeof(sBanChoice));
		int iBanReason = StringToInt(sBanChoice);

		int iTarget = GetClientOfUserId(iTargetUserId);

		if (!GetCTBanStatus(iTarget))
		{
			PerformCTBan(iTarget, iClient, iMinutesToBan, iBanReason);
		}
		else
		{
			PrintToChat(iClient, g_sChatBanner, "Already CT Banned", iTarget);
		}
	}
}

public int MenuHandler_CTBanPlayerList(Handle hMenu, MenuAction eAction, int iClient, int iMenuChoice)
{
	if (eAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (eAction == MenuAction_Cancel)
	{
		if (iMenuChoice == MenuCancel_ExitBack && gH_TopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(gH_TopMenu, iClient, TopMenuPosition_LastCategory);
		}
	}
	else if (eAction == MenuAction_Select)
	{
		char sTargetUserId[MAX_USERID_LENGTH];
		GetMenuItem(hMenu, iMenuChoice, sTargetUserId, sizeof(sTargetUserId));
		int iTargetUserId = StringToInt(sTargetUserId);
		int iTarget = GetClientOfUserId(iTargetUserId);

		if (!iTarget || !IsClientInGame(iTarget))
		{
			PrintToChat(iClient, g_sChatBanner, "Player no longer available");
		}
		else if (!CanUserTarget(iClient, iTarget))
		{
			PrintToChat(iClient, g_sChatBanner, "Unable to target");
		}
		else if (GetCTBanStatus(iTarget, iClient))
		{
			PrintToChat(iClient, g_sChatBanner, "Already CT Banned", iTarget);
		}
		else
		{
			DisplayCTBanTimeMenu(iClient, iTargetUserId);
		}
	}
}

public int MenuHandler_CTBanTimeList(Handle hMenu, MenuAction eAction, int iClient, int iMenuChoice)
{
	if (eAction == MenuAction_End)
	{
		CloseHandle(hMenu);
	}
	else if (eAction == MenuAction_Cancel)
	{
		if (iMenuChoice == MenuCancel_ExitBack && gH_TopMenu != INVALID_HANDLE)
		{
			DisplayTopMenu(gH_TopMenu, iClient, TopMenuPosition_LastCategory);
		}
	}
	else if (eAction == MenuAction_Select)
	{
		char sTargetUserId[MAX_USERID_LENGTH];
		GetMenuItem(hMenu, MENUCHOICE_USERID, sTargetUserId, sizeof(sTargetUserId));
		int iTargetUserId = StringToInt(sTargetUserId);

		char sTimeInMinutes[MAX_TIME_ARG_LENGTH];
		GetMenuItem(hMenu, iMenuChoice, sTimeInMinutes, sizeof(sTimeInMinutes));
		int iMinutesToBan = StringToInt(sTimeInMinutes);

		DisplayCTBanReasonMenu(iClient, iTargetUserId, iMinutesToBan);
	}
}

public void OnClientConnected(int iClient)
{
	g_bA_Temp_CTBan_Override[iClient] = false;
}

public void OnClientPostAdminCheck(int iClient)
{
	CreateTimer(COOKIE_INIT_CHECK_TIME, Timer_CheckBanCookies, iClient, TIMER_FLAG_NO_MAPCHANGE);
}

public void OnClientDisconnect(int iClient)
{
	char sDisconnectSteamID[FIELD_AUTHID_MAXLENGTH];
	GetClientAuthId(iClient, AuthId_Steam2, sDisconnectSteamID, sizeof(sDisconnectSteamID));

	// add information to rage ban list
	char sName[MAX_TARGET_LENGTH];
	GetClientName(iClient, sName, sizeof(sName));

	// add information to array
	// if information isn't already in the arrays then add it
	if (FindStringInArray(gA_DSteamIDs, sDisconnectSteamID) == VALUE_NOT_FOUND_IN_ARRAY)
	{
		g_bRageBanArrayChanged = true;
		
		PushArrayString(gA_DNames, sName);
		PushArrayString(gA_DSteamIDs, sDisconnectSteamID);

		if (GetArraySize(gA_DNames) >= (g_EngineVersion == Engine_CSGO ? CSGO_MAX_PAGE_MENU_ITEMS : CSS_MAX_PAGE_MENU_ITEMS))
		{
			// Remove the oldest entry
			RemoveFromArray(gA_DNames, ZERO);
			RemoveFromArray(gA_DSteamIDs, ZERO);
		}
	}

	// check if they were in the timed array
	int iBannedArrayIndex = FindValueInArray(gA_TimedBanLocalList, iClient);
	if (iBannedArrayIndex != VALUE_NOT_FOUND_IN_ARRAY)
	{
		// remove them from the local array
		RemoveFromArray(gA_TimedBanLocalList, iBannedArrayIndex);

		// make a datapack for the next query
		Handle hDisconnectPack = CreateDataPack();
		WritePackCell(hDisconnectPack, iClient);
		WritePackString(hDisconnectPack, sDisconnectSteamID);

		// update steam array
		char sQuery[QUERY_MAXLENGTH];
		Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_SELECT_BANTIME, g_sTimesTableName, sDisconnectSteamID);
		SQL_TQuery(gH_BanDatabase, DB_Callback_ClientDisconnect, sQuery, hDisconnectPack);
	}

	// if there are no admins left then swap all the !forcect players back to T team!
	bool bAdminPresent = false;
	for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
	{
		if (IsClientInGame(iIndex))
		{
			if (CheckCommandAccess(iIndex, FORCECT_COMMAND, ADMFLAG_SLAY))
			{
				bAdminPresent = true;
				break;
			}
		}
	}

	// if no admins are present then move *everyone* back to Terrorist team who has an override
	if (!bAdminPresent && !g_bIgnoreOverrideResets)
	{
		for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
		{
			UnForceCTActions(ZERO, iIndex, true);
		}
	}
}

public void DB_Callback_ClientDisconnect(Handle hOwner, Handle hCallback, const char[] sError, any hDataPack)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error with query on client disconnect: %s", sError);
		CloseHandle(hDataPack);
	}
	else
	{
		ResetPack(hDataPack);
		int iClient = ReadPackCell(hDataPack);
		char sAuthID[FIELD_AUTHID_MAXLENGTH];
		ReadPackString(hDataPack, sAuthID, sizeof(sAuthID));

		int iRowCount = SQL_GetRowCount(hCallback);
		if (iRowCount)
		{
			#if defined CTBAN_DEBUG
			SQL_FetchRow(hCallback);
			int iBanTimeRemaining = SQL_FetchInt(hCallback, CLIENT_DISCONNECT_CB_FIELD_TIMELEFT);

			if (IsClientInGame(iClient))
			{
				LogMessage("SQL: %N disconnected with %i time remaining on ban", iClient, iBanTimeRemaining);
			}
			else
			{
				LogMessage("SQL: %i client index disconnected with %i time remaining on ban", iClient, iBanTimeRemaining);
			}
			#endif

			char sQuery[QUERY_MAXLENGTH];
			if (gA_LocalTimeRemaining[iClient] <= ZERO)
			{
				// remove steam array
				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_DELETE, g_sTimesTableName, sAuthID);
				SQL_TQuery(gH_BanDatabase, DB_Callback_DisconnectAction, sQuery);

				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_EXPIRE, g_sLogTableName, sAuthID);
				SQL_TQuery(gH_BanDatabase, DB_Callback_DisconnectAction, sQuery);
			}
			else
			{
				// update the time
				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_UPDATE, g_sTimesTableName, gA_LocalTimeRemaining[iClient], sAuthID);
				SQL_TQuery(gH_BanDatabase, DB_Callback_DisconnectAction, sQuery);

				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_UPDATE, g_sLogTableName, gA_LocalTimeRemaining[iClient], sAuthID);
				SQL_TQuery(gH_BanDatabase, DB_Callback_DisconnectAction, sQuery);
			}
		}
	}
}

public void DB_Callback_DisconnectAction(Handle hOwner, Handle hCallback, const char[] sError, any data)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error with updating/deleting record after client disconnect: %s", sError);
	}
}

public Action Timer_CheckBanCookies(Handle hTimer, any iClient)
{
	if (AreClientCookiesCached(iClient))
	{
		ProcessBanCookies(iClient);
	}
	else if(IsClientInGame(iClient))
	{
		CreateTimer(COOKIE_RESCAN_TIME, Timer_CheckBanCookies, iClient, TIMER_FLAG_NO_MAPCHANGE);
	}
}

void ProcessBanCookies(int iClient)
{
	if(iClient && IsClientInGame(iClient))
	{
		if (GetCTBanStatus(iClient))
		{
			// check to see if they joined CT
			if (GetClientTeam(iClient) == CS_TEAM_CT)
			{
				EnforceCTBan(iClient);
			}
		}
	}
}

public Action Command_UnCTBan(int iClient, int iArgs)
{
	if (!iClient && !iArgs)
	{
		char sCommandName[MAX_UNBAN_CMD_LENGTH];
		// position 0 retrieves the command name. Could be unctban or removectban.
		GetCmdArg(ARG_ZERO_GET_COMMAND_NAME, sCommandName, sizeof(sCommandName));
		StrCat(sCommandName, sizeof(sCommandName), " <player>");

		ReplyToCommand(iClient, g_sChatBanner, "Command Usage", sCommandName);
		return Plugin_Handled;
	}

	if (!iArgs)
	{
		DisplayCTBannedPlayerMenu(iClient, e_RemoveCTBan);
	}
	else
	{
		char sTarget[MAX_NAME_LENGTH];
		GetCmdArg(UNCTBAN_ARG_TARGET, sTarget, sizeof(sTarget));

		char sClientName[MAX_TARGET_LENGTH];
		int aiTargetList[MAXPLAYERS];
		int iTargetCount;
		bool b_tn_is_ml;
		iTargetCount = ProcessTargetString(sTarget, iClient, aiTargetList, MAXPLAYERS, COMMAND_FILTER_NO_MULTI, sClientName, sizeof(sClientName), b_tn_is_ml);

		if (iTargetCount < ONE)
		{
			ReplyToTargetError(iClient, iTargetCount);
		}
		else
		{
			int iTarget = aiTargetList[ZERO];
			// check if the cookies are ready
			if (AreClientCookiesCached(iTarget))
			{
				Remove_CTBan(iClient, iTarget);
			}
			else
			{
				ReplyToCommand(iClient, g_sChatBanner, "Cookie Status Unavailable");
			}
		}
	}

	return Plugin_Handled;
}

void Remove_CTBan(int iAdmin, int iTarget, bool bExpired=false)
{
	if (GetCTBanStatus(iTarget))
	{
		char sTargetSteam[FIELD_AUTHID_MAXLENGTH];
		GetClientAuthId(iTarget, AuthId_Steam2, sTargetSteam, sizeof(sTargetSteam));

		char sQuery[QUERY_MAXLENGTH];
		Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_EXPIRE, g_sLogTableName, sTargetSteam);

		#if defined CTBAN_DEBUG
		LogMessage("log query: %s", sQuery);
		#endif

		SQL_TQuery(gH_BanDatabase, DB_Callback_RemoveCTBan, sQuery, iTarget);

		LogMessage("%N has removed the CT ban on %N (%s).", iAdmin, iTarget, sTargetSteam);

		if (!bExpired)
		{
			ShowActivity2(iAdmin, "", g_sChatBanner, "CT Ban Removed", iTarget);
		}
		else
		{
			ShowActivity2(iAdmin, "", g_sChatBanner, "CT Ban Auto Removed", iTarget);
		}

		// delete from the timedban database if there was one 
		Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_DELETE, g_sTimesTableName, sTargetSteam);

		SQL_TQuery(gH_BanDatabase, DB_Callback_RemoveCTBan, sQuery, iTarget);
	}
	else
	{
		ReplyToCommand(iAdmin, g_sChatBanner, "Not CT Banned", iTarget);
	}

	// error on side of caution and just set cookie to 0 regardless of what it was
	SetClientCookie(iTarget, g_CT_Cookie, COOKIE_UNBANNED_STRING);

	g_bA_Temp_CTBan_Override[iTarget] = false;

	Call_StartForward(g_hFrwd_OnUnCTBan);
	Call_PushCell(iTarget);
	Call_PushCell(iAdmin);
	Call_Finish();
}

public void DB_Callback_RemoveCTBan(Handle hOwner, Handle hCallback, const char[] sError, any iClient)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error handling steamID after CT ban removal: %s", sError);
	}
	else
	{
		#if defined CTBAN_DEBUG
		if (iClient > ZERO && IsClientInGame(iClient))
		{
			LogMessage("CTBan on %N was removed in SQL", iClient);
		}
		else
		{
			LogMessage("CTBan on --- was removed in SQL");
		}
		#endif
	}
}

public Action Command_CTBan(int iClient, int iArgs)
{
	if (!iClient && (iArgs < (GetConVarBool(gH_Cvar_Force_Reason) ? CTBAN_ARG_REASON : CTBAN_ARG_TIME)))
	{
		if (GetConVarBool(gH_Cvar_Force_Reason))
		{
			ReplyToCommand(iClient, g_sChatBanner, "Command Usage", "sm_ctban <player> <time> <reason>");
		}
		else
		{
			ReplyToCommand(iClient, g_sChatBanner, "Command Usage", "sm_ctban <player> <time> <optional:reason>");
		}

		return Plugin_Handled;
	}

	if (!iArgs)
	{
		DisplayCTBanPlayerMenu(iClient);
		return Plugin_Handled;
	}

	char sTarget[MAX_NAME_LENGTH];
	GetCmdArg(CTBAN_ARG_PLAYER, sTarget, sizeof(sTarget));

	char sClientName[MAX_TARGET_LENGTH];
	int aiTargetList[MAXPLAYERS];
	int iTargetCount;
	bool b_tn_is_ml;
	iTargetCount = ProcessTargetString(sTarget, iClient, aiTargetList, MAXPLAYERS, COMMAND_FILTER_NO_MULTI, sClientName, sizeof(sClientName), b_tn_is_ml);

	// target count 0 or less is an error condition
	if (iTargetCount < ONE)
	{
		ReplyToTargetError(iClient, iTargetCount);
	}
	else
	{
		int iTarget = aiTargetList[ZERO];

		if(iTarget && IsClientInGame(iTarget))
		{
			if (GetCTBanStatus(iTarget, iClient))
			{
				ReplyToCommand(iClient, g_sChatBanner, "Already CT Banned", iTarget);
			}
			else
			{
				if (iArgs == CTBAN_ARG_PLAYER)
				{
					int iTargetUserId = GetClientUserId(iTarget);
					DisplayCTBanTimeMenu(iClient, iTargetUserId);
					return Plugin_Handled;
				}

				char sBanTime[MAX_TIME_ARG_LENGTH];
				GetCmdArg(CTBAN_ARG_TIME, sBanTime, sizeof(sBanTime));
				int iBanTime = StringToInt(sBanTime);

				if (GetConVarBool(gH_Cvar_Force_Reason) && iArgs == CTBAN_ARG_TIME)
				{
					int iTargetUserId = GetClientUserId(iTarget);
					DisplayCTBanReasonMenu(iClient, iTargetUserId, iBanTime);
					return Plugin_Handled;
				}

				char sReasonStr[FIELD_REASON_MAXLENGTH];
				char sArgPart[FIELD_REASON_MAXLENGTH];
				for (int iArg = CTBAN_ARG_REASON; iArg <= iArgs; iArg++)
				{
					GetCmdArg(iArg, sArgPart, sizeof(sArgPart));
					Format(sReasonStr, sizeof(sReasonStr), "%s %s", sReasonStr, sArgPart);
				}
				// Remove the space at the beginning
				TrimString(sReasonStr);

				if (GetConVarBool(gH_Cvar_Force_Reason) && !strlen(sReasonStr))
				{
					ReplyToCommand(iClient, g_sChatBanner, "Reason Required");
				}
				else
				{
					PerformCTBan(iTarget, iClient, iBanTime, _, sReasonStr);
				}
			}
		}
	}
	return Plugin_Handled;
}

void PerformCTBan(int iClient, int iAdmin, int iBanTime = CTBAN_PERM_BAN_LENGTH, int iReason = CTBAN_NO_REASON_GIVEN, char[] sManualReason="")
{
	// set cookie to ban
	SetClientCookie(iClient, g_CT_Cookie, COOKIE_BANNED_STRING);

	char sTargetAuthID[FIELD_AUTHID_MAXLENGTH];
	GetClientAuthId(iClient, AuthId_Steam2, sTargetAuthID, sizeof(sTargetAuthID));

	// check if they're on CT team
	if (GetClientTeam(iClient) == CS_TEAM_CT)
	{
		EnforceCTBan(iClient);
	}

	char sReason[FIELD_REASON_MAXLENGTH];
	if (strlen(sManualReason) > ZERO)
	{
		Format(sReason, sizeof(sReason), "%s", sManualReason);
	}
	// or else they picked a reason # from the admin menu
	else
	{
		// Check if we are using the translated phrase reasons or the manual file reasons
		int iNumManualReasons = GetArraySize(gH_DArray_Reasons);

		// manual file reasons
		if (iNumManualReasons > ZERO)
		{
			if (iReason == CTBAN_NO_REASON_GIVEN)
			{
				Format(sReason, sizeof(sReason), "No reason given.");
			}
			else
			{
				GetArrayString(gH_DArray_Reasons, iReason, sReason, sizeof(sReason));
			}
		}
		// translated phrases reasons
		else
		{
			switch (iReason)
			{
				case ONE:
				{
					Format(sReason, sizeof(sReason), "%T", "CT Ban Reason 1", iAdmin);
				}
				case TWO:
				{
					Format(sReason, sizeof(sReason), "%T", "CT Ban Reason 2", iAdmin);
				}
				case THREE:
				{
					Format(sReason, sizeof(sReason), "%T", "CT Ban Reason 3", iAdmin);
				}
				case FOUR:
				{
					Format(sReason, sizeof(sReason), "%T", "CT Ban Reason 4", iAdmin);
				}
				case FIVE:
				{
					Format(sReason, sizeof(sReason), "%T", "CT Ban Reason 5", iAdmin);
				}
				case SIX:
				{
					Format(sReason, sizeof(sReason), "%T", "CT Ban Reason 6", iAdmin);
				}
				case SEVEN:
				{
					Format(sReason, sizeof(sReason), "%T", "CT Ban Reason 7", iAdmin);
				}
				default:
				{
					Format(sReason, sizeof(sReason), "No reason given.");
				}
			}
		}
	}

	int iTimeStamp = GetTime();

	char sTempName[FIELD_NAME_MAXLENGTH];
	char sQuery[QUERY_MAXLENGTH];

	char sEscapedPerpName[MAX_SAFE_ESCAPE_QUERY(FIELD_NAME_MAXLENGTH)];
	Format(sTempName, sizeof(sTempName), "%N", iClient);
	SQL_EscapeString(gH_BanDatabase, sTempName, sEscapedPerpName, sizeof(sEscapedPerpName));

	char sEscapedReason[MAX_SAFE_ESCAPE_QUERY(FIELD_REASON_MAXLENGTH)];
	SQL_EscapeString(gH_BanDatabase, sReason, sEscapedReason, sizeof(sEscapedReason));

	if(iAdmin && IsClientInGame(iAdmin))
	{
		char sAdminAuthID[FIELD_AUTHID_MAXLENGTH];
		GetClientAuthId(iAdmin, AuthId_Steam2, sAdminAuthID, sizeof(sAdminAuthID));

		char sEscapedAdminName[MAX_SAFE_ESCAPE_QUERY(FIELD_NAME_MAXLENGTH)];
		Format(sTempName, sizeof(sTempName), "%N", iAdmin);
		SQL_EscapeString(gH_BanDatabase, sTempName, sEscapedAdminName, sizeof(sEscapedAdminName));

		Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_INSERT, g_sLogTableName, iTimeStamp, sTargetAuthID, sEscapedPerpName, sAdminAuthID, sEscapedAdminName, iBanTime, iBanTime, sEscapedReason);

		#if defined CTBAN_DEBUG
		LogMessage("log query: %s", sQuery);
		#endif

		SQL_TQuery(gH_BanDatabase, DB_Callback_CTBan, sQuery, iClient);

		LogMessage("%N (%s) has issued a CT ban on %N (%s) for %d minutes for %s.", iAdmin, sAdminAuthID, iClient, sTargetAuthID, iBanTime, sReason);
	}
	else
	{
		Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_INSERT, g_sLogTableName, iTimeStamp, sTargetAuthID, sEscapedPerpName, CONSOLE_AUTHID, CONSOLE_USER_NAME, iBanTime, iBanTime, sEscapedReason);

		#if defined CTBAN_DEBUG
		LogMessage("log query: %s", sQuery);
		#endif

		SQL_TQuery(gH_BanDatabase, DB_Callback_CTBan, sQuery, iClient);

		LogMessage("Console has issued a CT ban on %N (%s) for %d.", iClient, sTargetAuthID, iBanTime);
	}

	// check if there is a time
	if (iBanTime > CTBAN_PERM_BAN_LENGTH)
	{
		ShowActivity2(iAdmin, "", g_sChatBanner, "Temporary CT Ban and Reason", iClient, iBanTime, sReason);
		// save in local quick-access array
		PushArrayCell(gA_TimedBanLocalList, iClient);
		gA_LocalTimeRemaining[iClient] = iBanTime;

		// save in long-term database (already guaranteed to run only once per steam ID)
		switch (g_eDatabaseType)
		{
			case e_SQLite:
			{
				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_INSERT_SQLITE, g_sTimesTableName, sTargetAuthID, iBanTime);
			}
			default:
			{
				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_INSERT_MYSQL, g_sTimesTableName, sTargetAuthID, iBanTime, iBanTime);
			}
		}

		#if defined CTBAN_DEBUG
		LogMessage("ctban query: %s", sQuery);
		#endif

		SQL_TQuery(gH_BanDatabase, DB_Callback_CTBan, sQuery, iClient);
	}
	else
	{
		ShowActivity2(iAdmin, "", g_sChatBanner, "Permanent CT Ban and Reason", iClient, sReason);
	}

	Call_StartForward(g_hFrwd_OnCTBan);
	Call_PushCell(iClient);
	Call_PushCell(iAdmin);
	Call_PushCell(iBanTime);
	Call_PushString(sReason);
	Call_Finish();
}

public void DB_Callback_CTBan(Handle hOwner, Handle hCallback, const char[] sError, any iClient)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error writing CTBan to Timed Ban database: %s", sError);
	}
	else
	{
		#if defined CTBAN_DEBUG
		if (iClient > ZERO && IsClientInGame(iClient))
		{
			LogMessage("SQL CTBan: Updated database with CT Ban for %N", iClient);
		}
		#endif
	}
}

public Action Command_Change_CTBan_Time(int iClient, int iArgs)
{
	if (iArgs != CHANGE_TIME_ARG_TIME)
	{
		ReplyToCommand(iClient, g_sChatBanner, "Command Usage", "sm_change_ctban_time <player> <time>");
		return Plugin_Handled;
	}

	char sTarget[MAX_TARGET_LENGTH];
	GetCmdArg(CHANGE_TIME_ARG_TARGET, sTarget, sizeof(sTarget));

	char sClientName[MAX_TARGET_LENGTH];
	int aiTargetList[MAXPLAYERS];
	int iTargetCount;
	bool b_tn_is_ml;
	iTargetCount = ProcessTargetString(sTarget, iClient, aiTargetList, MAXPLAYERS, COMMAND_FILTER_NO_MULTI, sClientName, sizeof(sClientName), b_tn_is_ml);
	if (iTargetCount < ONE)
	{
		ReplyToTargetError(iClient, iTargetCount);
	}
	else
	{
		int iTarget = aiTargetList[ZERO];
		if (GetCTBanStatus(iTarget))
		{
			char sTime[MAX_TIME_ARG_LENGTH];
			GetCmdArg(CHANGE_TIME_ARG_TIME, sTime, sizeof(sTime));

			int iTime = StringToInt(sTime);

			if (iTime < ZERO)
			{
				ReplyToCommand(iClient, g_sChatBanner, "Invalid Amount");
			}
			// check if time is not changing
			else if (gA_LocalTimeRemaining[iTarget] == iTime || (gA_LocalTimeRemaining[iTarget] <= ZERO && iTime == ZERO))
			{
				ReplyToCommand(iClient, g_sChatBanner, "Invalid Amount");
			}
			else
			{
				PerformChangeCTBanTime(iTarget, iClient, iTime);
			}
		}
		else
		{
			ReplyToCommand(iClient, g_sChatBanner, "Not CT Banned", iTarget);
		}
	}

	return Plugin_Handled;
}

void PerformChangeCTBanTime(int iTarget, int iClient, int iTime)
{
	// 3 types of possible actions depending on the existing and new ban type
	// timed to timed
	if (iTime > ZERO && gA_LocalTimeRemaining[iTarget] > ZERO)
	{
		gA_LocalTimeRemaining[iTarget] = iTime;

		ShowActivity2(iClient, "", g_sChatBanner, "Temporary CT Ban", iTarget, iTime);

		// if it is a timed to timed change then the values will be cached on client disconnect like normal
	}
	// timed to perm
	else if (iTime == ZERO && gA_LocalTimeRemaining[iTarget] > ZERO)
	{
		gA_LocalTimeRemaining[iTarget] = iTime;

		// check if they were in the timed array
		int iBannedArrayIndex = FindValueInArray(gA_TimedBanLocalList, iTarget);
		if (iBannedArrayIndex != VALUE_NOT_FOUND_IN_ARRAY)
		{
			// remove them from the local array
			RemoveFromArray(gA_TimedBanLocalList, iBannedArrayIndex);

			char sAuthId[FIELD_AUTHID_MAXLENGTH];
			GetClientAuthId(iTarget, AuthId_Steam2, sAuthId, sizeof(sAuthId));

			// fix these tables so it will not reset on the next server join
			char sQuery[QUERY_MAXLENGTH];
			Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_DELETE, g_sTimesTableName, sAuthId);
			SQL_TQuery(gH_BanDatabase, DB_Callback_DisconnectAction, sQuery);
			
			switch (g_eDatabaseType)
			{
				case e_SQLite:
				{
					Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_TIME_TO_PERM_SQLITE, g_sLogTableName, sAuthId);
				}
				default:
				{ 
					Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_TIME_TO_PERM_MYSQL, g_sLogTableName, sAuthId);
				}
			}
			SQL_TQuery(gH_BanDatabase, DB_Callback_DisconnectAction, sQuery);
		}

		ShowActivity2(iClient, "", g_sChatBanner, "Permanent CT Ban", iTarget);
	}
	// perm to timed
	else if (iTime > ZERO && gA_LocalTimeRemaining[iTarget] <= ZERO)
	{
		// save in local quick-access array
		PushArrayCell(gA_TimedBanLocalList, iTarget);
		gA_LocalTimeRemaining[iTarget] = iTime;

		char sAuthId[FIELD_AUTHID_MAXLENGTH];
		GetClientAuthId(iTarget, AuthId_Steam2, sAuthId, sizeof(sAuthId));

		// save in long-term database (already guaranteed to run only once per steam ID)
		char sQuery[QUERY_MAXLENGTH];
		switch (g_eDatabaseType)
		{
			case e_SQLite:
			{
				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_INSERT_SQLITE, g_sTimesTableName, sAuthId, iTime);
			}
			default:
			{
				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_TIME_INSERT_MYSQL, g_sTimesTableName, sAuthId, iTime, iTime);
			}
		}
		#if defined CTBAN_DEBUG
		LogMessage("ctban query: %s", sQuery);
		#endif
		SQL_TQuery(gH_BanDatabase, DB_Callback_DisconnectAction, sQuery);
		
		switch (g_eDatabaseType)
		{
			case e_SQLite:
			{
				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_PERM_TO_TIME_SQLITE, g_sLogTableName, iTime, iTime, sAuthId);
			}
			default:
			{
				Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_PERM_TO_TIME_MYSQL, g_sLogTableName, iTime, iTime, sAuthId);
			}
		}
		SQL_TQuery(gH_BanDatabase, DB_Callback_DisconnectAction, sQuery);

		ShowActivity2(iClient, "", g_sChatBanner, "Temporary CT Ban", iTarget, iTime);
	}
}

public Action Command_CTBanList(int iClient, int iArgs)
{
	// console user
	if (!iClient)
	{
		for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
		{
			if (IsClientInGame(iIndex))
			{
				if (GetCTBanStatus(iIndex))
				{
					if (gA_LocalTimeRemaining[iIndex] <= ZERO)
					{
						ReplyToCommand(iClient, g_sChatBanner, "Permanent CT Ban", iIndex);
					}
					else
					{
						ReplyToCommand(iClient, g_sChatBanner, "Temporary CT Ban", iIndex, gA_LocalTimeRemaining[iIndex]);
					}
				}
			}
		}
	}
	// regular in-game player
	else
	{
		// check if client is allowed to use the command
		AdminId clientAdminId = GetUserAdmin(iClient);
		char sFlags[MAX_ADMINFLAGS_LENGTH];
		GetConVarString(gH_Cvar_CheckCTBans_Flags, sFlags, sizeof(sFlags));
		int iAdminFlags = ReadFlagString(sFlags);

		#if defined CTBAN_DEBUG
		LogMessage("Flag string %s and value %d and client effective %d", sFlags, iAdminFlags, GetAdminFlags(clientAdminId, Access_Effective));
		#endif

		// length of 0 means they want everyone to have access to this
		if (strlen(sFlags) == ZERO)
		{
			DisplayCTBannedPlayerMenu(iClient, e_CTBanList);
		}
		// if the player has no admin access
		//  iAdminFlags bitstring & client's bitstring will leave a logic TRUE if there is overlap
		else if (clientAdminId == INVALID_ADMIN_ID || !(iAdminFlags & GetAdminFlags(clientAdminId, Access_Effective)))
		{
			ReplyToCommand(iClient, g_sChatBanner, "No Access");
		}
		// they are an admin and they have effective flag access
		else
		{
			DisplayCTBannedPlayerMenu(iClient, e_CTBanList);
		}
	}

	return Plugin_Handled;
}

public Action Command_IsBanned(int iClient, int iArgs)
{
	char sTarget[MAX_TARGET_LENGTH];
	GetCmdArg(ISBANNED_ARG_TARGET, sTarget, sizeof(sTarget));

	char sClientName[MAX_TARGET_LENGTH];
	int aiTargetList[MAXPLAYERS];
	int iTargetCount;
	bool b_tn_is_ml;
	iTargetCount = ProcessTargetString(sTarget, iClient, aiTargetList, MAXPLAYERS, COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_IMMUNITY, sClientName, sizeof(sClientName), b_tn_is_ml);
	int iTarget = aiTargetList[ZERO];

	// Console
	if (!iClient)
	{
		if (!iArgs)
		{
			ReplyToCommand(iClient, g_sChatBanner, "Command Usage", "sm_isbanned <player>");
		}
		else
		{
			if (iTargetCount < ONE)
			{
				ReplyToTargetError(iClient, iTargetCount);
			}
			else
			{
				ProcessIsBannedTarget(iTarget, iClient);
			}
		}
		return Plugin_Handled;
	}

	// check if client is allowed to use the command
	AdminId clientAdminId = GetUserAdmin(iClient);
	char sFlags[MAX_ADMINFLAGS_LENGTH];
	GetConVarString(gH_Cvar_CheckCTBans_Flags, sFlags, sizeof(sFlags));

	int iAdminFlags = ReadFlagString(sFlags);

	#if defined CTBAN_DEBUG
	LogMessage("Flag string %s and value %d and client effective %d", sFlags, iAdminFlags, GetAdminFlags(clientAdminId, Access_Effective));
	#endif

	// length of 0 means they want everyone to have access to this
	if (strlen(sFlags) == ZERO)
	{
		if (!iArgs)
		{
			// automatically target self
			ProcessIsBannedTarget(iClient, iClient);
		}
		else
		{
			if (iTargetCount < ONE)
			{
				ReplyToTargetError(iClient, iTargetCount);
			}
			else
			{
				ProcessIsBannedTarget(iTarget, iClient);
			}
		}
	}
	// if the player has no admin access
	//  iAdminFlags bitstring & client's bitstring will leave a logic TRUE if there is overlap
	else if (clientAdminId == INVALID_ADMIN_ID || !(iAdminFlags & GetAdminFlags(clientAdminId, Access_Effective)))
	{
		// check if self-targeting allowed
		if (GetConVarBool(gH_Cvar_IsBanned_Self))
		{
			if (!iArgs)
			{
				// automatically target self
				ProcessIsBannedTarget(iClient, iClient);
			}
			else
			{
				// check if they target themselves
				if (iTargetCount < ONE)
				{
					ReplyToTargetError(iClient, iTargetCount);
				}
				else if (iTarget != iClient)
				{
					ReplyToCommand(iClient, g_sChatBanner, "No Access");
				}
				// target is the calling client
				else
				{
					ProcessIsBannedTarget(iTarget, iClient);
				}
			}
		}
		else
		{
			ReplyToCommand(iClient, g_sChatBanner, "No Access");
		}
	}
	// they are an admin and they have effective flag access
	else
	{
		if (!iArgs)
		{
			ReplyToCommand(iClient, g_sChatBanner, "Command Usage", "sm_isbanned <player>");
		}
		else
		{
			if (iTargetCount < ONE)
			{
				ReplyToTargetError(iClient, iTargetCount);
			}
			else
			{
				ProcessIsBannedTarget(iTarget, iClient);
			}
		}
	}

	return Plugin_Handled;
}

void ProcessIsBannedTarget(int iTarget, int iCaller)
{
	#if defined CTBAN_DEBUG
	LogMessage("Processing IsBanned on %N by %N", iTarget, iCaller);
	#endif

	if(iTarget > ZERO && iTarget <= MaxClients && IsClientInGame(iTarget))
	{
		if (GetCTBanStatus(iTarget, iCaller))
		{
			// grab perp steam id
			char sPerpSteamID[FIELD_AUTHID_MAXLENGTH];
			GetClientAuthId(iTarget, AuthId_Steam2, sPerpSteamID, sizeof(sPerpSteamID));

			char sQuery[QUERY_MAXLENGTH];
			Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_ISBANNED, g_sLogTableName, sPerpSteamID);

			#if defined CTBAN_DEBUG
			LogMessage("isbanned query: %s", sQuery);
			#endif

			Handle hDataPack = CreateDataPack();
			// perp SteamID
			WritePackString(hDataPack, sPerpSteamID);
			// current client who asked for isbanned info
			WritePackCell(hDataPack, iCaller);
			// target index
			WritePackCell(hDataPack, iTarget);

			SQL_TQuery(gH_BanDatabase, DB_Callback_IsBanned, sQuery, hDataPack);
		}
		else
		{
			if (iCaller != CALLER_NATIVE)
			{
				ReplyToCommand(iCaller, g_sChatBanner, "Not CT Banned", iTarget);
			}
			else
			{
				ThrowNativeError(SP_ERROR_NATIVE, g_sChatBanner, "Not CT Banned", iTarget);
			}
		}
	}
	else
	{
		if (iCaller != CALLER_NATIVE)
		{
			ReplyToCommand(iCaller, g_sChatBanner, "Unable to target");
		}
		else
		{
			ThrowNativeError(SP_ERROR_NATIVE, g_sChatBanner, "Unable to target");
		}
	}
}

public void DB_Callback_IsBanned(Handle hOwner, Handle hCallback, const char[] sError, any hDataPack)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error in IsBanned query: %s", sError);
		CloseHandle(hDataPack);
	}
	else
	{
		ResetPack(hDataPack);
		char sPerpAuthID[FIELD_AUTHID_MAXLENGTH];
		ReadPackString(hDataPack, sPerpAuthID, sizeof(sPerpAuthID));
		int iCaller = ReadPackCell(hDataPack);
		int iTarget = ReadPackCell(hDataPack);
		CloseHandle(hDataPack);

		int iRowCount = SQL_GetRowCount(hCallback);
		if (iRowCount > ONE || iRowCount < ZERO)
		{
			LogError("%d rows returned on LIMIT 1 query: %s", iRowCount, sError);
		}
		else if (!iRowCount)
		{
			#if defined CTBAN_DEBUG
			LogMessage("Row count is 0 for IsBanned Query!");
			#endif

			if (iCaller == CALLER_NATIVE)
			{
				// Have to use incomplete information because the row is missing from the database table
				Call_StartForward(g_hFrwd_CTBanInfo);
				Call_PushCell(false);
				Call_PushCell(iTarget);
				Call_PushCell(gA_LocalTimeRemaining[iTarget]);
				Call_PushCell(CALLER_NATIVE);
				Call_PushString("Invalid");
				Call_PushString("Invalid");
				Call_Finish();
			}
			else if (gA_LocalTimeRemaining[iTarget] <= ZERO)
			{
				if (!iCaller)
				{
					PrintToServer(g_sChatBanner, "Permanent CT Ban", iTarget);
				}
				else
				{
					PrintToChat(iCaller, g_sChatBanner, "Permanent CT Ban", iTarget);
				}
			}
			else
			{
				if (!iCaller)
				{
					PrintToServer(g_sChatBanner, "Temporary CT Ban", iTarget, gA_LocalTimeRemaining[iTarget]);
				}
				else
				{
					PrintToChat(iCaller, g_sChatBanner, "Temporary CT Ban", iTarget, gA_LocalTimeRemaining[iTarget]);
				}
			}
		}
		// Rows are exactly 1
		else
		{
			SQL_FetchRow(hCallback);
			int iTimeStamp = SQL_FetchInt(hCallback, ISBANNED_CB_FIELD_TIMESTAMP);
			char sAdminName[FIELD_NAME_MAXLENGTH];
			SQL_FetchString(hCallback, ISBANNED_CB_FIELD_ADMINNAME, sAdminName, sizeof(sAdminName));
			char sReason[FIELD_REASON_MAXLENGTH];
			SQL_FetchString(hCallback, ISBANNED_CB_FIELD_REASON, sReason, sizeof(sReason));
			#if defined CTBAN_DEBUG
			LogMessage("SQL ISBanned: admin %s banned with timestamp %d for reason %s", sAdminName, iTimeStamp, sReason);
			#endif

			char sTimeBanned[MAX_TIME_INFO_STR_LENGTH];
			FormatTime(sTimeBanned, sizeof(sTimeBanned), NULL_STRING, iTimeStamp);

			#if defined CTBAN_DEBUG
			LogMessage("target %N, admin banning %s, when banned %s, timeleft %d", iTarget, sAdminName, sTimeBanned, gA_LocalTimeRemaining[iTarget]);
			#endif

			// check if we need to fire a forward from a native call
			if (iCaller == CALLER_NATIVE)
			{
				Call_StartForward(g_hFrwd_CTBanInfo);
				Call_PushCell(true);
				Call_PushCell(iTarget);
				Call_PushCell(gA_LocalTimeRemaining[iTarget]);
				Call_PushCell(iTimeStamp);
				Call_PushString(sAdminName);
				Call_PushString(sReason);
				Call_Finish();
			}
			// find the time if any
			else if (gA_LocalTimeRemaining[iTarget] <= ZERO)
			{
				if (!iCaller)
				{
					PrintToServer(g_sChatBanner, "IsBanned Permanent", iTarget, sAdminName, sTimeBanned, sReason);
				}
				else
				{
					PrintToChat(iCaller, g_sChatBanner, "IsBanned Permanent", iTarget, sAdminName, sTimeBanned, sReason);
				}
			}
			else
			{
				if (!iCaller)
				{
					PrintToServer(g_sChatBanner, "IsBanned Temporary", iTarget, gA_LocalTimeRemaining[iTarget], sAdminName, sTimeBanned, sReason);
				}
				else
				{
					PrintToChat(iCaller, g_sChatBanner, "IsBanned Temporary", iTarget, gA_LocalTimeRemaining[iTarget], sAdminName, sTimeBanned, sReason);
				}
			}
		}
	}
}

public Action Command_Offline_IsBanned(int iClient, int iArgs)
{
	char sPerpSteamID[FIELD_AUTHID_MAXLENGTH];
	GetCmdArgString(sPerpSteamID, sizeof(sPerpSteamID));
	TrimString(sPerpSteamID);

	if (IsAuthIdConnected(sPerpSteamID))
	{
		ReplyToCommand(iClient, g_sChatBanner, "Unable to target");
	}
	else
	{
		ProcessIsBannedOffline(iClient, sPerpSteamID);
	}

	return Plugin_Handled;
}

void ProcessIsBannedOffline(int iCaller, char[] sPerpAuthID)
{
	char sEscapedPerpSteamID[MAX_SAFE_ESCAPE_QUERY(FIELD_NAME_MAXLENGTH)];
	SQL_EscapeString(gH_BanDatabase, sPerpAuthID, sEscapedPerpSteamID, sizeof(sEscapedPerpSteamID));

	char sQuery[QUERY_MAXLENGTH];
	Format(sQuery, sizeof(sQuery), CTBAN_QUERY_LOG_ISBANNED_OFFLINE, g_sLogTableName, sEscapedPerpSteamID);

	#if defined CTBAN_DEBUG
	LogMessage("offline isbanned query: %s", sQuery);
	#endif

	Handle hDataPack = CreateDataPack();
	// perp SteamID
	WritePackString(hDataPack, sPerpAuthID);
	// current client who asked for isbanned info
	WritePackCell(hDataPack, iCaller);

	SQL_TQuery(gH_BanDatabase, DB_Callback_Offline_IsBanned, sQuery, hDataPack);
}

public void DB_Callback_Offline_IsBanned(Handle hOwner, Handle hCallback, const char[] sError, any hOfflineIsBannedPack)
{
	if (hCallback == INVALID_HANDLE)
	{
		LogError("Error in Offline IsBanned query: %s", sError);
	}
	else
	{
		ResetPack(hOfflineIsBannedPack);
		char sPerpAuthID[FIELD_AUTHID_MAXLENGTH];
		ReadPackString(hOfflineIsBannedPack, sPerpAuthID, sizeof(sPerpAuthID));
		int iClient = ReadPackCell(hOfflineIsBannedPack);
		CloseHandle(hOfflineIsBannedPack);

		int iRowCount = SQL_GetRowCount(hCallback);
		if (iRowCount != ONE)
		{
			if (iClient == CALLER_NATIVE)
			{
				Call_StartForward(g_hFrwd_CTBanInfoOffline);
				Call_PushCell(false);
				Call_PushString(sPerpAuthID);
				Call_PushCell(CALLER_NATIVE);
				Call_PushCell(CALLER_NATIVE);
				Call_PushString("Invalid");
				Call_PushString("Invalid");
				Call_PushString("Invalid");
				Call_Finish();
			}
			else if (!iClient)
			{
				PrintToServer(g_sChatBanner, "No matching client");
			}
			else
			{
				PrintToChat(iClient, g_sChatBanner, "No matching client");
			}
		}
		else
		{
			SQL_FetchRow(hCallback);
			int timestamp = SQL_FetchInt(hCallback, ISBANNED_OFF_CB_FIELD_TIMESTAMP);
			char sAdminName[FIELD_NAME_MAXLENGTH];
			SQL_FetchString(hCallback, ISBANNED_OFF_CB_FIELD_ADMINNAME, sAdminName, sizeof(sAdminName));
			char sReason[FIELD_REASON_MAXLENGTH];
			SQL_FetchString(hCallback, ISBANNED_OFF_CB_FIELD_REASON, sReason, sizeof(sReason));
			int timeleft = SQL_FetchInt(hCallback, ISBANNED_OFF_CB_FIELD_TIMELEFT);
			char sPerpName[FIELD_NAME_MAXLENGTH];
			SQL_FetchString(hCallback, ISBANNED_OFF_CB_FIELD_PERPNAME, sPerpName, sizeof(sPerpName));

			char sTimeBanned[MAX_TIME_INFO_STR_LENGTH];
			FormatTime(sTimeBanned, sizeof(sTimeBanned), NULL_STRING, timestamp);

			#if defined CTBAN_DEBUG
			LogMessage("target name %s, admin banning %s, when banned %s, timeleft %d", sPerpName, sAdminName, sTimeBanned, timeleft);
			#endif

			if (iClient == CALLER_NATIVE)
			{
				Call_StartForward(g_hFrwd_CTBanInfoOffline);
				Call_PushCell(true);
				Call_PushString(sPerpAuthID);
				Call_PushCell(timeleft);
				Call_PushCell(timestamp);
				Call_PushString(sAdminName);
				Call_PushString(sReason);
				Call_PushString(sPerpName);
				Call_Finish();
			}
			else if (timeleft <= ZERO)
			{
				if (!iClient)
				{
					PrintToServer(g_sChatBanner, "IsBanned Permanent String Name", sPerpName, sAdminName, sTimeBanned, sReason);
				}
				else
				{
					PrintToChat(iClient, g_sChatBanner, "IsBanned Permanent String Name", sPerpName, sAdminName, sTimeBanned, sReason);
				}
			}
			else
			{
				if (!iClient)
				{
					PrintToServer(g_sChatBanner, "IsBanned Temporary String Name", sPerpName, timeleft, sAdminName, sTimeBanned, sReason);
				}
				else
				{
					PrintToChat(iClient, g_sChatBanner, "IsBanned Temporary String Name", sPerpName, timeleft, sAdminName, sTimeBanned, sReason);
				}
			}
		}
	}
}

public Action Command_CheckJoin(int iClient, const char[] sCommand, int iArgs)
{
	// Check to see if we should continue (not a listen server, is in game, not a bot, if cookies are cached, and we're enabled)
	if(!iClient || !IsClientInGame(iClient) || IsFakeClient(iClient) || !AreClientCookiesCached(iClient))
	{
		return Plugin_Continue;
	}

	// Get the target team
	char sJoinTeamString[MAX_JOINTEAM_ARG_LENGTH];
	GetCmdArg(JOINTEAM_ARG_TEAM_STRING, sJoinTeamString, sizeof(sJoinTeamString));
	int iTargetTeam = StringToInt(sJoinTeamString);

	int iBanStatus = GetCTBanStatus(iClient);

	// check for an active ban to send a message
	if ((iTargetTeam == CS_TEAM_SPECTATOR || iTargetTeam == CS_TEAM_T) && iBanStatus)
	{
		// display them a message about the ban
		int iTimeBanned = GetClientCookieTime(iClient, g_CT_Cookie);
		char sTimeBanned[MAX_TIME_INFO_STR_LENGTH];
		FormatTime(sTimeBanned, sizeof(sTimeBanned), NULL_STRING, iTimeBanned);
		char sJoinBanMsg[MAX_JOIN_BAN_MSG_LENGTH];
		GetConVarString(gH_Cvar_JoinBanMessage, sJoinBanMsg, sizeof(sJoinBanMsg));
		PrintHintText(iClient, "%t", "Last CT Banned On", sTimeBanned, sJoinBanMsg);

		if (GetConVarBool(gH_Cvar_IsBanned_Self))
		{
			ProcessIsBannedTarget(iClient, iClient);
		}
	}
	// otherwise they joined CT or auto-select and are banned
	else if (iBanStatus)
	{
		if(strcmp(gS_SoundPath, ""))
		{
			char sPlayCommand[PLATFORM_MAX_PATH + PLAY_COMMAND_STRING_LENGTH];
			Format(sPlayCommand, sizeof(sPlayCommand), "%s%s", PLAY_COMMAND_STRING, gS_SoundPath);
			ClientCommand(iClient, sPlayCommand);
		}
		PrintToChat(iClient, g_sChatBanner, "Enforcing CT Ban");
		
		// if they are already on the Terrorist team then they don't need to pick anything again
		if (GetClientTeam(iClient) != CS_TEAM_T)
		{
			UTIL_TeamMenu(iClient);
		}
		
		return Plugin_Stop;
	}

	return Plugin_Continue;
}

// This helper procedure will re-display the team join menu
// and is equivalent to what ClientCommand(client, "chooseteam") did in the past
void UTIL_TeamMenu(int iClient)
{
	int aiClients[ONE];
	Handle hBfWritePack;
	aiClients[ZERO] = iClient;
	hBfWritePack = StartMessage("VGUIMenu", aiClients, ONE);

	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetString(hBfWritePack, "name", "team");
		PbSetBool(hBfWritePack, "show", true);
	}
	else
	{
		BfWriteString(hBfWritePack, "team"); // panel name
		BfWriteByte(hBfWritePack, ONE); // bShow
		BfWriteByte(hBfWritePack, ZERO); // count
	}

	EndMessage();
}

// figure out if we can use the handy native SetAuthIdCookie
bool IsSetAuthIdNativePresent()
{
	if (GetFeatureStatus(FeatureType_Native, "SetAuthIdCookie") == FeatureStatus_Available)
	{
		return true;
	}
	return false;
}

int GetCTBanStatus(int iClient, int iCaller = CALLER_DO_NOT_REPLY)
{
	int iCTBanStatus = ZERO;

	if (AreClientCookiesCached(iClient))
	{
		char sCookie[MAX_COOKIE_STR_LENGTH];
		GetClientCookie(iClient, g_CT_Cookie, sCookie, sizeof(sCookie));
		iCTBanStatus = StringToInt(sCookie);
	}
	else
	{
		if (iCaller >= ZERO)
		{
			ReplyToCommand(iCaller, g_sChatBanner, "Cookie Status Unavailable");
		}
	}

	return iCTBanStatus;
}

void EnforceCTBan(int iClient)
{
	if (IsPlayerAlive(iClient))
	{
		// strip their weapons so they cannot gunplant after death
		StripAllWeapons(iClient);

		ForcePlayerSuicide(iClient);
	}

	ChangeClientTeam(iClient, CS_TEAM_T);

	if (GetConVarBool(gH_Cvar_Respawn))
	{
		CS_RespawnPlayer(iClient);
	}

	PrintToChat(iClient, g_sChatBanner, "Enforcing CT Ban");
}

#if !defined _Hosties_Included_
	// From hosties.inc on Beta branch (20 Aug 2017)
	stock void StripAllWeapons(int iClient)
	{
		int iWeaponIndex = INVALID_WEAPON;
		for (int iLoopIndex = CS_SLOT_PRIMARY; iLoopIndex < CS_SLOT_GRENADE + ONE; iLoopIndex++)
		{
			iWeaponIndex = INVALID_WEAPON;
			while ((iWeaponIndex = GetPlayerWeaponSlot(iClient, iLoopIndex)) != INVALID_WEAPON)
			{
				RemovePlayerItem(iClient, iWeaponIndex);
				AcceptEntityInput(iWeaponIndex, "Kill");
			}
		}
	}
#endif

#if !defined _CTBan_Included_
	stock int IsAuthIdConnected(char[] sAuthID)
	{
		char sIndexAuthID[FIELD_AUTHID_MAXLENGTH];
		for (int iIndex = ONE; iIndex <= MaxClients; iIndex++)
		{
			if (IsClientInGame(iIndex))
			{
				GetClientAuthId(iIndex, AuthId_Steam2, sIndexAuthID, sizeof(sIndexAuthID));
				if (StrEqual(sAuthID, sIndexAuthID))
				{
					return iIndex;
				}
			}
		}

		return ZERO;
	}

	stock void ParseCTBanReasonsFile(Handle hReasonsArray)
	{
		ClearArray(hReasonsArray);

		char sPathReasons[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPathReasons, sizeof(sPathReasons), "configs/ctban_reasons.ini");
		Handle hReasonsFile = OpenFile(sPathReasons, "r");

		if (hReasonsFile != null)
		{
			char sReasonsLine[FIELD_REASON_MAXLENGTH];

			while (ReadFileLine(hReasonsFile, sReasonsLine, sizeof(sReasonsLine)))
			{
				PushArrayString(hReasonsArray, sReasonsLine);
			}
		}
		
		CloseHandle(hReasonsFile);
	}
	
	stock Handle ParseCTBanLengthsFile(Handle hKeyValues)
	{
		if (hKeyValues != INVALID_HANDLE)
		{
			CloseHandle(hKeyValues);
		}
		
		hKeyValues = CreateKeyValues("length");
		
		char sPathLengths[PLATFORM_MAX_PATH];
		BuildPath(Path_SM, sPathLengths, sizeof(sPathLengths), "configs/ctban_times.ini");
		
		if (FileToKeyValues(hKeyValues, sPathLengths))
		{
			KvRewind(hKeyValues);
		}
		else
		{
			CloseHandle(hKeyValues);
			return INVALID_HANDLE;
		}
		
		return hKeyValues;
	}
	
	stock void SetCTBanChatBanner(EngineVersion e_EngineVersion, char sChatBanner[MAX_CHAT_BANNER_LENGTH])
	{
		switch (e_EngineVersion) 
		{
			case Engine_CSS, Engine_TF2:
			{
				sChatBanner = "[\x0799CCFFCTBAN\x01] \x07FFD700%t";
			}
			case Engine_CSGO:
			{
				sChatBanner = "[\x0BCTBAN\x01] \x10%t";
			}
			default:
			{
				SetFailState("Game engine is not supported.");
			}
		}
	}
#endif

/*
	[CS:S/CS:GO] CT Bans
	by: databomb
*/