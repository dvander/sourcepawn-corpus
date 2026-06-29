#define PLUGIN_VERSION "5.3"

#pragma newdecls required
#pragma semicolon 1

#include <sourcemod>
#include <geoip>
#include <regex>
#include <sdktools_gamerules>

#define CVAR_FLAGS		FCVAR_NOTIFY

public Plugin myinfo = 
{
	name = "[L4D] Votekick (Coop & Versus)",
	author = "alliedfront",
	description = "Vote to kick a player, with translucent menu",
	version = PLUGIN_VERSION,
	url = "https://github.com/Hubfront/L4D1-L4D2-Votekick-Coop-Versus"
};

/*
	Description:
	 - This plugin replaces the black screen kick vote by a translucent menu.
	 
	Features:

	 - full support for both game modes: Co-op and Versus (L4D1 % L4D2)
	 - prevents a serious vote kick exploit in the official L4D1 kick vote: A kick from a successful vote has no effect if the kicked player leaves the game shortly before the vote ends. Some players exploit this to disrupt other players' gameplay.
	 - the kick vote is now kept as short as possible (version 4.5): the vote of the initiator of the vote and the vote of the player to be kicked who is not inactive are cast automatically (similar to the official L4D behavior).
	 - simple temporary bans: ability to exclude a list of users you may not want to connect for a given time period. Excluded users receive the message "STEAM UserID is banned."ability to exclude a list of users you may not want to connect for a given time period. Excluded users receive the message "STEAM UserID is banned."
	 * See the file: data/votekick_ban.txt (if not present, create it by setting cvar sm_votekick_use_banfile set to "1" in cfg-file)
	 - translucent menu
	 - kick for 1 hour (adjustable) even if the player used a trick to quit from the game before the vote ends.
	 - un-kick (from the same menu)
	 - vote announcement
	 - no black screen
	 - flexible configuration of access rights
	 - kick reasons (with translation):
	 * See the file: data/votekick_reason.txt
	 - all actions are logged (who kick, whom kick, who tried to kick, ip/country/nick/SteamId, reason ...)
	 - ability to black list specific users (by SteamId or nickname) to prevent them from starting the vote:
	 * See the file: data/votekick_vote_block.txt
	
	Logfile location:
	 - logs/vote_kick.log
	 
	Data file:
	 - data/votekick_vote_block.txt - list of users you may want to exclude from the right to start voting
	 * (SteamId and nicknames with simple mask * are allowed).
	 - data/votekick_reason.txt - list of kick reasons (optionally, must be supplied with appropriate translation in file: l4d_votekick.phrases.txt).
	 - data/votekick_ban.txt - list of users you may want to exclude from connecting. Optional. Only read/created (if not present) if cvar sm_votekick_use_banfile = 1 (default: 0).
	 * Format: SteamId, Start (Unixtime), Minutes, Self note
	 - data/votekick_ban_lastwrite.txt - timestamp file. Optional. Only read/created (if not present) if cvar sm_votekick_use_banfile = 1 (default: 0).

	Permissions:
	 - by default, voting can be started by anyone (customizable): 
	   you could also restrict voting access, for example to players with the "k" (StartVote) flag (set cvar sm_votekick_accessflag to "k").
	 - by default, vote can be vetoed or force passed by player with "d" (Ban) flag (adjustable).
	 - ability to set a minimum time to allow voting to be repeated.
	 - ability to set a minimum number of players to hold a vote.
	 - admins cannot target root admin.
	 - non-admins cannot target admins.
	 - users with lower immunity level cannot target users with higher level.
	
	Commands:
	
	- sm_vk (or sm_votekick) - Try to start vote for kick
	- sm_veto - Allow admin to veto current vote
	- sm_votepass (or sm_pass) - Allow admin to bypass current
	
	Requirements:
	 - GeoIP extension (included in SourceMod).
	
	Languages:
	 - Chinese
	 - English
	 - French
	 - German
	 - Polish
	 - Russian
	 - Spanish
	 - Ukrainian
	 
	Installation:
	 - copy smx file to addons/sourcemod/plugins/
	 - copy files and folders in translations/ to addons/sourcemod/translations/
	 - Note: only addons/sourcemod/translations/l4d_votekick.phrases.txt is mandatory, other language files are optional.
	 - copy data/ .txt files to addons/sourcemod/data/
	 - banfile: to enable, set sm_votekick_use_banfile = 1 in the cfg file. 
	 * file data/votekick_ban.txt will be created with next map start/change, if it not already exists.
	   There You can add a player's STEAM Id to exclude them from connection
	 * file data/votekick_ban_lastwrite.txt will be created with next map start/change, if it not already exists.	   
	 - banfile: to disable, set sm_votekick_use_banfile = 0 in the cfg file (effective with the next map change).

	Credits:
	 - D1maxa - for the initial plugin
	 - Dragokas – much thanks for his outstanding and inspiring work on which this plugin is based
	
	===================================================================================================
	
	ChangeLog:
	Fork by alliedfront:

	Plugin is forked from version 3.5 of the plugin "[L4D] Votekick (no black screen)" by Dragokas. 

	4.0 (21-09-2024)
	 Added simple temporary bans by a file-based solution (new feature)
	 - Ban entries will be deleted from both memory and file after they are expired
	 - Bans are active on the instances of the l4d_votekick plugin
	 - Uses the proven access / deny - functionality of the plugin 
	 - Ban entry format: Steam-ID,Start of ban (provide Unix timestanp or leave empty for now->Unix Timestamp),Duration in minutes,Self note (e.g. nickname of banned player)
	  * see autogenerated file data/votekick_ban.txt for format details
	  * autogenerated file data/votekick_ban_lastwrite.txt
	 - This feature can be completly switched on/off (default: off) in cfg-file
	 - The logging of attempts of file - banned players to join a server can be switched on/off in the cfg file (default: on)
	 - maximum ban time: 60 days
	 Bugfixes:
	 - Fixed a bug, where the wrong team could unkick a kicked player (Versus)
	 - Fixed a bug, where, in the case of g_bCvarShowKickReason == true, it would not properly check whether a vote was already running before starting another vote. 
	 - Fixed a bug, where a player could wrongly be a target by a kickvote, although he already had switched team (Versus)
	 - Fixed a bug, when the global variable g_iVoteInitiatorTeam contained the wrong team id of a previous vote, resulting of messages to the wrong team (Versus)
	 - Fixed a bug, where additional votes could be started by other players within g_hCvarAnnounceDelay (default 2 seconds) after initial vote
	 - Fixed a bug, when sReasonEng was not initialized before its use
	 Exploits:
	 - Fixed an exploit, where a kicked player could connect by offline authentification (no proper Steam ID retrieved)
	 Minor changes:
	 - If a player opened a KickReason menu and has chosen not to start voting (cancel), his 60 second penalty will be reduced, allowing him to reopen the VK menu after 2 seconds (2 seconds for anti-spam). 
	 Compatibility:
	 - Works also with version 3.5 .txt-files in data/ and translations/ directories

	4.1 (10-10-2024)
	 - Temporary bans via banfile: Removed restriction on ban period (previously 60 days)
	 - Temporary bans via banfile: duration can now also be defined by inserting a character string: e.g. “3d” for 3 days, “1d 12h” for 1 day 12 hours, “1h 90m” for 1 hour 90 minutes (previously only [Minutes]). 
	   * See the file votekick_ban.txt for details
	 - CVARS defaults changed. Reason: Easier access to voting
	   * sm_votekick_accessflag defaults to "" (previously "k")
	   * sm_votekick_minplayers defaults to "1" (previously "4")
	   * sm_votekick_minplayers_versus defaults to "1" (previously "4")

	4.2 (19-10-2024)
	 - Code optimizations
	 
	4.3 (29-Oct-2024)
	 - Fixed a bug where in some cases a game server restart was required to create data/votekick_ban.txt
	 - Updated description

	4.4 (18-May-2025)
	 - Improvement: Faster kick vote: in Coop and in Versus the counter vote for an active player is cast automatically 
	   After a period of inactivity, he can only vote manually (Coop: depends on server config, Versus: CVAR sm_votekick_versus_inactive_time (Default: 45 sec)
	   This behavior is similar to the official L4D kick behavior during voting in both L4D game modes
	   It is designed to keep the voting kick for the team as short as possible, especially helpful in competitive games
	   CVAR (Versus):
	   * sm_votekick_versus_inactive_time (Default: 45 sec)
	 Bugfixes:
	 - Fixed a bug where kickvoting wouldn't work in Coop mode if the player was inactive.
	 Minor changes:
	 - Code optimizations
	 - Cosmetic changes (banfile description)
	 - Updated phrases.txt
	 - Updated description

	4.5 (12-June-2025)
	 - Improvement: Now the initiator of the kickvote does cast his vote automatically.
	 - Improvement: If there are only two players on the team, the kick vote immediately ends in a tie unless the target is inactive.
     - Improvement: If a dead player is the target of a kick vote, he always automatically votes against it.
	 - Added German translation
	 - Added Spanish translation
	 - The four translation languages ​​are now organized according to the official recommendation, see also https://wiki.alliedmods.net/Translations_(SourceMod_Scripting)
	 Bugfixes:
	 - Fixed a bug where no result was displayed for a kick vote if no player pressed a button to vote.
	 Minor changes:
	 - Code optimizations
	 - Updated description

	4.6 (14-July-2025)
	 - Added French translation
	 Bugfixes:
	 - Fixed a bug where in case of a vote pass or veto, the corresponding message was sent to players twice and logged twice.

	4.7 (21-Aug-2025)
	 - Added Chinese translation
	 - Added Ukrainian translation
	 Bugfixes:
	 - Fixed a bug that caused the vote to unban to not work if no one other than the vote initiator pressed a key.
	 - Fixed a bug that caused abstentions to not be displayed in voting results.
	 - Fixed a bug that caused the voting result to be displayed in case of a pass or veto.
	 - Fixed a bug that prevented the voting results from being displayed to kicked player.
	 Minor changes:
	 - Code optimizations
	 - Updated description
	 Compatibility:
	 - This is the last version which will work with the old (version 3.5 of this plugin) translations/l4d_votekick.phrases.txt language file, which provides English & Russian translation in one file.
	 - Future versions (v5+) of the plugin will require updating at least the English translation file in translations/l4d_votekick.phrases.txt to addons/sourcemod/translations/l4d_votekick.phrases.txt with every new release.
	 - The language file addons/sourcemod/translations/l4d_votekick.phrases.txt is mandatory. 
	 - Other language files found in the subdirectories of the package's translations/ directory can be added to addons/sourcemod/translations/ if you want the respectitive languages ​​to be supported by this plugin.
	 - E.g. copying translations/es/l4d_votekick.phrases.txt to addons/sourcemod/translations/es/l4d_votekick.phrases.txt for the Spanish translation. 
	 - For information about the new ( as of SourceMod 1.1 ) preferred method of shipping translations, see https://wiki.alliedmods.net/Translations_(SourceMod_Scripting) 

	5.0 (20-Sep-2025)
	 - * New * Ability to control the amount of information given to the opposing team via the kickvote message (Versus gamemode).
	   Setting the convar sm_votekick_otherteam_info_level to 0: the opposing team receives the same information as the team of the kickvote initiator ("Everything").
	   Setting the convar sm_votekick_otherteam_info_level to 1 or 2 limits the amount of information the opposing team receives about the kick vote of the team that initiated the vote ( 1: "Little"; 2: "Somewhat more"). 
	 - * New * Ability to control whether the initiator of the kickvote is mentioned or not (all game modes)
	   If you set the conversion variable sm_votekick_initiator_anonymous to 1, the initiator of the kickvote will not be mentioned.
	 - CVARS defaults changed. Reason: faster voting
	   * sm_votekick_announcedelay defaults to "0.0" (previously "2.0")
	 Bugfixes:
	 - Fixed a bug where the number of bots was not displayed in the voting result if the ConVar "sm_votekick_show_bots" was set to "1"
	 New ConVars:
	 - Added ConVar "sm_votekick_initiator_anonymous" - Should the initiator of the kickvote remain anonymous? (1 - Yes / 0 - No)
	 - Added ConVar "sm_votekick_otherteam_info_level" - Information level for the other team (Versus) (0 - Everything / 1 - Little / 2 - Somewhat more)
	 Language files:
	 - Updated language files with new phrases for the new functionalities
	 - Linguistic corrections/improvements
	 Compatibility with translation files of previous versions:
	 - This version (v5.X) is not compatible with language files of previous versions (v4.X, v3.X, etc.) anymore.
	 - Mandatory: English translation file: for this plugin to work properly, you need to copy the English translation file of this version in translations/l4d_votekick.phrases.txt to addons/sourcemod/translations/l4d_votekick.phrases.txt.
	 - Optionally, you may add additional language files located in the subdirectories of the translations/ package directory to addons/sourcemod/translations/.
	 - E.g. copying translations/es/l4d_votekick.phrases.txt to addons/sourcemod/translations/es/l4d_votekick.phrases.txt for the Spanish translation. 
	 Minor changes:
	 - Updated description

	5.1 (05-Oct-2025)
	 Bugfixes:
	 - Fixed a bug where, in rare cases, the detailed result of a vote was displayed to the wrong team (Versus)
	 CVARS defaults changed. Reason: more information about voting for the opposing team (Versus)
	   * sm_votekick_otherteam_info_level to "2" (previously "1")

	5.2 omitted (withdrawn due to a critical error)

 	5.3 (03-May-2026)
 	 Language files:
	 - added Polish translation
	 CVARS defaults changed (reverted):
	   * sm_votekick_otherteam_info_level back to "1" (previously "2")
	 Bugfixes:
	 - Fixed a bug that allowed a self-kick even though the ConVar "sm_votekick_show_self" was set to "0".
	 - Fixed a bug that, in rare cases, caused the subsequent Kickclient command to trigger a "Client Index 0" error.
	 
	Please note: for completeness, the following changelog has been copied from Dragokas' plugin "[L4D] Votekick (no black screen)", version 3.5.

	"Plugin is initially based on the work of D1maxa.
	
	1.2
	 - converted to a new syntax and methodmaps
	 - added VIP immunity support (VIP-module by R1KO).
	 - added logging of kick action and kick attempts.
	 
	1.3
	 - added restriction for vote not often than 1 times on minute
	 - fixed IsClientAdmin() security issue
	 - added to server and console log about the person who started the vote
	 - VIP-module requirement is removed, replaced by "k" (Start Vote) admin flag.
	 - added !veto
	 - added !votepass
	 
	1.4
	 - Added logging of all "callvote" commands to logs/vote.log file.
	 
	1.5
	 - Potentially, fixed exploit for bypassing votekick (thanks to MasterMind420 and Powerlord).
	 - Added ConVars.
	 
	1.6 (07-May-2019)
	 - Plugin is simplified.
	 - Added "sm_votekick_accessflag" ConVar (by default: "k" StartVote flag).
	 - Prohibit "sv_vote_issue_kick_allowed" ConVar to prevent votekick exploit (thanks to SilverShot)
	
	1.7
	 - Some security fixes
	
	1.8 (09-Aug-2019)
	 - Fixed infinite "Vote is in progress"
	 - Fixed rare mem leak.
	
	2.0 (29-Mar-2021)
	 - Added un-kick ability. Use the same command - !vk. Kicked players will be displayed at the very end of the list with the "X" icon.
	 - Vote access is now also checked via inter-players immunity priority.
	 - Vote access is now also checked whether non-admin client try to target an admin (thanks to @Profanuch for suggestion).
	 - Do not display in vote menu the players from another team (in versus mode), except for "z" root admin and "!veto" admin (thanks to @toniex for suggestion).
	 - PRIVATE_STUFF is moved from source code to external file:
	  * "data/votekick_vote_block.txt" - for specific players you may want to block the vote ability (STEAM id and player nicknames are allowed).
	 - Added ConVar "sm_votekick_vetoflag" - Admin flag required to veto/votepass the vote.
	 - Improved blocking of "sv_vote_issue_kick_allowed" ConVar.
	 - Added missing FCVAR_NOTIFY flag to version ConVar for tracking the telemetry.
	 - Better log formatting.
	 
	2.1 (25-Apr-2021)
	 - Fixed exploit allowing players with the bad name to broke the menu.
	 
	2.2 (29-Apr-2021)
	 - Added ability to specify kick reasons with translation support (thanks to GoGetSomeSleep for donation support):
	  * see file data/votekick_reason.txt
	  * see file translations/l4d_votekick.phrases.txt (for adding new translation for kick reasons).
	 - Added ConVar "sm_votekick_show_kick_reason" - Allow to select kick reason? (1 - Yes / 0 - No)
	 - Added ConVar "sm_votekick_show_bots" - Allow to vote kick survivor bots? (1 - Yes / 0 - No)
	 - Added ConVar "sm_votekick_show_self" - Allow to self-kick (for debug purposes)? (1 - Yes / 0 - No)
	 - Performance optimizations.
	 - SM 1.9+ required.
	 
	2.3 (01-Jul-2022)
	 - Allowed to vote everybody against clients who located in deny list (regardless of vote access flag).
	 - Added compatibility with Auto-Name-Changer by Exle. "newnames.txt" file will be detected and merged to deny list.
	 - Fixed compilation warnings on SM 1.11.
	 
	2.4 (01-Jul-2022)
	 - Fix for previous update.
	 - Also, support for old version of Auto-Name-Changer with newnames.ini file name, instead of newnames.txt.
	
	2.5 (07-Jan-2024)
	 - Fixed exploit in kicking bots (coded by alliedfront).
	 
	2.6 (10-Jan-2024)
	 - Added basic support for versus.
	 
	3.0 (29-Jan-2024) by alliedfront
	 - Added full support for versus.
	 - Fixed unkick list overflowing with old players.
	 - Fixed invalid target errors.
	 - Added ConVar "sm_votekick_show_vote_details" - Allow to show mumber of yesVotes - noVotes? (1 - Yes / 0 - No)
	 - Added ConVar "sm_votekick_minplayers_versus" - Minimum players present in versus games to allow starting vote for kick
	 - Added details on count of yes/no/abstained vote results.
	 - Translation file is updated.
	 
	3.1 (30-Jan-2024)
	 - Code optimizations.
	 - Translation file is updated.
	 
	3.2 (30-Jan-2024) by alliedfront
	 - Fixed regression: unkick didn't work because of incorrect access check.
	 - Fixed access check to allow everybody to kick players if the flag string is empty.
	 - Fixed spelling.
	 - Translation file is updated.
	 
	3.3 (31-Jan-2024)
	 - Added kick reason "Team killer".
	 - Translation file is updated.
	 
	3.4 (02-Feb-2024)
	 - Added command alias "sm_pass".
	 - Added kick reason to hint message.
	 - Corrected un-kick message.
	 - Code is simplified.
	 
	3.5 (03-Feb-2024)
	 - Added more kick reasons (thanks to @[ru]In1ernal Error).
	 - Fixed ghost item in menu (thanks to @alliedfront)."
*/

char g_sCharKicked[] = "☓";

char FILE_VOTE_BLOCK[PLATFORM_MAX_PATH]		= "data/votekick_vote_block.txt";
char FILE_VOTE_REASON[PLATFORM_MAX_PATH]	= "data/votekick_reason.txt";
char FILE_BAN[PLATFORM_MAX_PATH]			= "data/votekick_ban.txt";
char FILE_BAN_LASTWRITE[PLATFORM_MAX_PATH]	= "data/votekick_ban_lastwrite.txt";
char FILE_ANC_BLOCK[PLATFORM_MAX_PATH];
char FILE_ANC_BLOCK_1[PLATFORM_MAX_PATH]	= "cfg/sourcemod/anc/newnames.ini"; // old version naming
char FILE_ANC_BLOCK_2[PLATFORM_MAX_PATH]	= "cfg/sourcemod/anc/newnames.txt";

ArrayList g_hArrayVoteBlock, g_hArrayVoteReason;
StringMap hMapSteam, hMapPlayerName, hMapPlayerTeam, hMapBanStart, hMapBanStop, hMapBanSelfnote;
Regex hRegexSteamid, hRegexDigitsZero, hRegexDigits, hRegexStrDhm;
char g_sSteam[64], g_sIP[32], g_sCountry[4], g_sName[MAX_NAME_LENGTH], g_sLog[PLATFORM_MAX_PATH];
int g_iKickUserId, g_iInitiatorUserId, g_iLastTime[MAXPLAYERS+1], g_iKickTarget[MAXPLAYERS+1], g_iReason, g_iVoteInitiatorLogicalTeam, g_iTime_Offset[MAXPLAYERS+1], g_iLastbuttons[MAXPLAYERS+1], g_iNum_Clients;
bool g_bVeto, g_bVotepass, g_bVoteInProgress, g_bVoteDisplayed, g_bTooOften[MAXPLAYERS+1], g_bIsVersus, g_bRegexExists = false, g_bTargetManualVote, g_bVoteNoButtonPressed ;

// ConVars
ConVar g_hCvarDelay, g_hCvarKickTime, g_hCvarAnnounceDelay, g_hCvarTimeout, g_hCvarLog, g_hMinPlayers, g_hCvarAccessFlag, g_hCvarVetoFlag;
ConVar g_hCvarGameMode, g_hCvarShowKickReason, g_hCvarShowBots, g_hCvarShowSelf, g_hCvarShowVoteDetails, g_hMinPlayersVersus, g_hCvarUseBanfile, g_hCvarUseBanfileLog;
ConVar g_hCvarVersusInactiveTime, g_hCvarInitiatorAnonymous, g_hCvarOtherTeamInfoLevel;

float g_fCvarAnnounceDelay;
int g_iCvarKickTime, g_iCvarDelay, g_iCvarTimeout, g_iMinPlayers, g_iCvarAccessFlag, g_iCvarVetoFlag, g_iMinPlayersVersus, g_iCvarVersusInactiveTime, g_iCvarVsOtherTeamInfoLevel;
bool g_bCvarLog, g_bCvarShowKickReason, g_bCvarShowBots, g_bCvarShowSelf, g_bCvarShowVoteDetails, g_bCvarUseBanfile, g_bCvarUseBanfileLog, g_bCvarInitiatorAnonymous;

public void OnPluginStart()
{
	LoadTranslations("l4d_votekick.phrases");
	CreateConVar("l4d_votekick_version", PLUGIN_VERSION, "Version of L4D Votekick on this server", FCVAR_DONTRECORD | CVAR_FLAGS);
	
	g_hCvarDelay = CreateConVar(				"sm_votekick_delay",				"60",			"Minimum delay (in sec.) allowed between votes", CVAR_FLAGS );
	g_hCvarTimeout = CreateConVar(				"sm_votekick_timeout",				"10",			"How long (in sec.) does the vote last", CVAR_FLAGS );
	g_hCvarAnnounceDelay = CreateConVar(		"sm_votekick_announcedelay",		"0.0",			"Delay (in sec.) between announce and vote menu appearing", CVAR_FLAGS );
	g_hCvarKickTime = CreateConVar(				"sm_votekick_kicktime",				"3600",			"How long player will be kicked (in sec.)", CVAR_FLAGS );
	g_hMinPlayers = CreateConVar(				"sm_votekick_minplayers",			"1",			"Minimum players present in game to allow starting vote for kick", CVAR_FLAGS );
	g_hMinPlayersVersus = CreateConVar(			"sm_votekick_minplayers_versus",	"1",			"Minimum players present in team to allow starting vote for kick (Versus gamemode)", CVAR_FLAGS );
	g_hCvarAccessFlag = CreateConVar(			"sm_votekick_accessflag",			"",				"Admin flag required to start the vote (leave empty to allow for everybody)", CVAR_FLAGS );
	g_hCvarVetoFlag = CreateConVar(				"sm_votekick_vetoflag",				"d",			"Admin flag required to veto/votepass the vote", CVAR_FLAGS );
	g_hCvarLog = CreateConVar(					"sm_votekick_log",					"1",			"Use logging? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hCvarShowKickReason = CreateConVar(		"sm_votekick_show_kick_reason",		"0",			"Allow to select kick reason? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hCvarShowBots = CreateConVar(				"sm_votekick_show_bots",			"0",			"Allow to vote kick survivor bots? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hCvarShowSelf = CreateConVar(				"sm_votekick_show_self",			"0",			"Allow to self-kick (for debug purposes)? (1 - Yes / 0 - No)", CVAR_FLAGS );
	g_hCvarShowVoteDetails = CreateConVar(		"sm_votekick_show_vote_details",	"1",			"Allow to show mumber of yesVotes - noVotes? (1 - Yes / 0 - No)", CVAR_FLAGS );	
	g_hCvarUseBanfile = CreateConVar(			"sm_votekick_use_banfile",			"0",			"Use file based temporary bans? (1 - Yes / 0 - No)", CVAR_FLAGS );	
	g_hCvarUseBanfileLog = CreateConVar(		"sm_votekick_use_banfile_log",		"1",			"File based temporary bans: log attempts to join the server? (1 - Yes / 0 - No)", CVAR_FLAGS );	
	g_hCvarVersusInactiveTime = CreateConVar(	"sm_votekick_versus_inactive_time",	"45",			"Time (in sec.) after which an inactive player is considered AFK. In a kick vote against him, he can then only vote manually", CVAR_FLAGS );	
	g_hCvarInitiatorAnonymous = CreateConVar(	"sm_votekick_initiator_anonymous",	"1",			"Should the initiator of the kickvote remain anonymous? (1 - Yes / 0 - No)", CVAR_FLAGS );	
	g_hCvarOtherTeamInfoLevel = CreateConVar(	"sm_votekick_otherteam_info_level",	"1",			"Amount of information provided to the other team (Versus) (0 - Everything / 1 - Little / 2 - Somewhat more)", CVAR_FLAGS );	
	
	AutoExecConfig(true,				"sm_votekick");
	
	FindConVar("sv_vote_issue_kick_allowed").AddChangeHook(OnCvarChangedVoteKickMenu);
	
	g_hCvarGameMode = FindConVar("mp_gamemode");
	
	RegConsoleCmd("sm_votekick", 	Command_Votekick,	"Show menu to select player to vote for kick/unkick");
	RegConsoleCmd("sm_vk", 			Command_Votekick,	"Show menu to select player to vote for kick/unkick");
	
	RegConsoleCmd("sm_veto", 		Command_Veto, 		"Allow admin to veto current vote.");
	RegConsoleCmd("sm_votepass", 	Command_Votepass, 	"Allow admin to bypass current vote.");
	RegConsoleCmd("sm_pass", 		Command_Votepass, 	"Allow admin to bypass current vote.");

	hMapSteam = new StringMap();
	hMapPlayerName = new StringMap();
	hMapPlayerTeam = new StringMap();

	g_hArrayVoteBlock = new ArrayList(ByteCountToCells(MAX_NAME_LENGTH));
	g_hArrayVoteReason = new ArrayList(ByteCountToCells(32));

	BuildPath(Path_SM, FILE_VOTE_BLOCK, sizeof(FILE_VOTE_BLOCK), FILE_VOTE_BLOCK);
	BuildPath(Path_SM, FILE_VOTE_REASON, sizeof(FILE_VOTE_REASON), FILE_VOTE_REASON);
	BuildPath(Path_SM, g_sLog, sizeof(g_sLog), "logs/vote_kick.log");
	
	char sReason[32];
	LoadReasonList();
	for( int i = 0; i < g_hArrayVoteReason.Length; i++ )
	{
		g_hArrayVoteReason.GetString(i, sReason, sizeof(sReason));
		if( !TranslationPhraseExists(sReason) )
		{
			SetFailState("Translation phrase is missing: '%s'", sReason);
		}
	}
	
	if( FileExists(FILE_ANC_BLOCK_1) )
	{
		FILE_ANC_BLOCK = FILE_ANC_BLOCK_1;
	}
	if( FileExists(FILE_ANC_BLOCK_2) )
	{
		FILE_ANC_BLOCK = FILE_ANC_BLOCK_2;
	}
	
	g_hCvarDelay.AddChangeHook(OnCvarChanged);
	g_hCvarTimeout.AddChangeHook(OnCvarChanged);
	g_hCvarAnnounceDelay.AddChangeHook(OnCvarChanged);
	g_hCvarKickTime.AddChangeHook(OnCvarChanged);
	g_hMinPlayers.AddChangeHook(OnCvarChanged);
	g_hCvarAccessFlag.AddChangeHook(OnCvarChanged);
	g_hCvarVetoFlag.AddChangeHook(OnCvarChanged);
	g_hCvarLog.AddChangeHook(OnCvarChanged);
	g_hCvarShowKickReason.AddChangeHook(OnCvarChanged);
	g_hCvarShowBots.AddChangeHook(OnCvarChanged);
	g_hCvarShowSelf.AddChangeHook(OnCvarChanged);
	g_hCvarShowVoteDetails.AddChangeHook(OnCvarChanged);
	g_hMinPlayersVersus.AddChangeHook(OnCvarChanged);
	g_hCvarGameMode.AddChangeHook(OnCvarChanged);
	g_hCvarUseBanfile.AddChangeHook(OnCvarChanged);
	g_hCvarUseBanfileLog.AddChangeHook(OnCvarChanged);
	g_hCvarVersusInactiveTime.AddChangeHook(OnCvarChanged);
	g_hCvarInitiatorAnonymous.AddChangeHook(OnCvarChanged);
	g_hCvarOtherTeamInfoLevel.AddChangeHook(OnCvarChanged);
	
	GetCvars();
}

public void OnCvarChangedVoteKickMenu(ConVar convar, const char[] oldValue, const char[] newValue)
{
	if( convar.IntValue != 0 ) // prevents black screen vote kick exploit
	{
		convar.SetInt(0);
	}
}

public void OnCvarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
	GetCvars();
}

void GetCvars()
{
	g_iCvarDelay = g_hCvarDelay.IntValue;
	g_iCvarTimeout = g_hCvarTimeout.IntValue;
	g_fCvarAnnounceDelay = g_hCvarAnnounceDelay.FloatValue;
	g_iCvarKickTime = g_hCvarKickTime.IntValue;
	g_iMinPlayers = g_hMinPlayers.IntValue;
	g_iMinPlayersVersus = g_hMinPlayersVersus.IntValue;
	g_bCvarLog = g_hCvarLog.BoolValue;
	g_bCvarShowBots = g_hCvarShowBots.BoolValue;
	g_bCvarShowSelf = g_hCvarShowSelf.BoolValue;
	g_bCvarShowVoteDetails = g_hCvarShowVoteDetails.BoolValue;
	g_bCvarUseBanfile = g_hCvarUseBanfile.BoolValue;
	g_bCvarUseBanfileLog = g_hCvarUseBanfileLog.BoolValue;
	g_iCvarVersusInactiveTime = g_hCvarVersusInactiveTime.IntValue;
	g_bCvarInitiatorAnonymous = g_hCvarInitiatorAnonymous.BoolValue;
	g_iCvarVsOtherTeamInfoLevel = g_hCvarOtherTeamInfoLevel.IntValue;
	
	char sReq[32];
	g_hCvarVetoFlag.GetString(sReq, sizeof(sReq));
	if( strlen(sReq) == 0 )
		g_iCvarVetoFlag = 0;
	else	
		g_iCvarVetoFlag = ReadFlagString(sReq);
	
	g_hCvarAccessFlag.GetString(sReq, sizeof(sReq));
	if( strlen(sReq) == 0 )
		g_iCvarAccessFlag = 0;
	else	
		g_iCvarAccessFlag = ReadFlagString(sReq);
	
	bool bShowReasonPrev = g_bCvarShowKickReason;
	g_bCvarShowKickReason = g_hCvarShowKickReason.BoolValue;
	
	if( g_bCvarShowKickReason && !bShowReasonPrev )
	{
		if( g_hArrayVoteReason.Length == 0 )
		{
			LoadReasonList();
		}
	}

	char gt[32];
	g_hCvarGameMode.GetString(gt, sizeof(gt));
	g_bIsVersus = strcmp(gt, "versus", false) == 0;
}

void ReadFileToArrayList(char[] sPath, ArrayList list, bool bClearList = true)
{
	static char str[128];
	File hFile = OpenFile(sPath, "r");
	if( hFile == null )
	{
		SetFailState("Failed to open file: \"%s\". You are missing at installing!", sPath);
	}
	else {
		if( bClearList )
		{
			list.Clear();
		}
		while( !hFile.EndOfFile() && hFile.ReadLine(str, sizeof(str)) )
		{
			TrimString(str);
			list.PushString(str);
		}
		delete hFile;
	}
}

void LoadBlockList()
{
	static int ft_block, ft_anc_block;
	int ft1, ft2;
	
	if( ft_block 		!= (ft1 = GetFileTime(FILE_VOTE_BLOCK, 	FileTime_LastChange)) 
	||	ft_anc_block 	!= (ft2 = GetFileTime(FILE_ANC_BLOCK, 	FileTime_LastChange)) )
	{
		ft_block = ft1;
		ft_anc_block = ft2;
		ReadFileToArrayList(FILE_VOTE_BLOCK, 	g_hArrayVoteBlock);
		if( FILE_ANC_BLOCK[0] != 0 && ft_anc_block != -1 )
		{
			ReadFileToArrayList(FILE_ANC_BLOCK, 	g_hArrayVoteBlock, false); // append
		}
	}
}

void LoadReasonList()
{
	static int ft_reason;
	int ft;

	if( g_bCvarShowKickReason )
	{
		ft = GetFileTime(FILE_VOTE_REASON, FileTime_LastChange);
		if( ft != ft_reason )
		{
			ft_reason = ft;
			ReadFileToArrayList(FILE_VOTE_REASON, g_hArrayVoteReason);
		}
	}
}

public void OnMapStart()
{
	LoadBlockList();
	LoadReasonList();
}

public void OnConfigsExecuted()
{

	// When sm_votekick_use_banfile is set to "1" for the first time, regex is initiated once in the life of this plugin instance
	//
	if ( !g_bRegexExists && g_bCvarUseBanfile )
	{
		hMapBanStart = new StringMap();
		hMapBanStop = new StringMap();
		hMapBanSelfnote = new StringMap();

		// Regex to detect incorrect ban file entries -> these entries are omitted
		hRegexSteamid = CompileRegex("^STEAM_[0-5]:[01]:\\d+$");
		hRegexDigitsZero = CompileRegex("^\\d{0,}$");
		hRegexDigits = CompileRegex("^\\d+$");
		hRegexStrDhm = CompileRegex("^(?:(\\d+)[ ]*[Dd])*[ ]*(?:(\\d+)[ ]*[Hh])*[ ]*(?:(\\d+)[ ]*[Mm])*$");

		BuildPath(Path_SM, FILE_BAN, sizeof(FILE_BAN), FILE_BAN);
		BuildPath(Path_SM, FILE_BAN_LASTWRITE, sizeof(FILE_BAN_LASTWRITE), FILE_BAN_LASTWRITE);
		g_bRegexExists = true;
	}
	
	if ( g_bCvarUseBanfile )
		LoadBanList();
}

public Action Command_Veto(int client, int args)
{
	if( g_bVoteInProgress ) { // IsVoteInProgress() is not working here, sm bug?
		if( !HasVetoAccessFlag(client) )
		{
			ReplyToCommand(client, "%t", "no_access");
			return Plugin_Handled;
		}
		g_bVeto = true;
		CPrintToChatAll("%t", "veto", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[VETO]");
	}
	return Plugin_Handled;
}

public Action Command_Votepass(int client, int args)
{
	if( g_bVoteInProgress ) {
		if( !HasVetoAccessFlag(client) )
		{
			ReplyToCommand(client, "%t", "no_access");
			return Plugin_Handled;
		}
		g_bVotepass = true;
		CPrintToChatAll("%t", "votepass", client);
		if( g_bVoteDisplayed ) CancelVote();
		LogVoteAction(client, "[PASS]");
	}
	return Plugin_Handled;
}

public void OnAllPluginsLoaded()
{
	AddCommandListener(CheckVote, "callvote");
	if( !CommandExists ("sm_voteban") )
	{
		RegConsoleCmd("sm_voteban", Command_Votekick);
	}
}

public Action CheckVote(int initiator, char[] command, int args)
{
	if( initiator == 0 || !IsClientInGame(initiator) )
		return Plugin_Stop;
	
	char s[MAX_NAME_LENGTH];
	if( args >= 2 ) {
		GetCmdArg(1, s, sizeof(s));
		if( strcmp(s, "Kick", false) == 0 ) {
			GetCmdArg(2, s, sizeof(s));
			int UserId = StringToInt(s);
			if( UserId ) {
				int target = GetClientOfUserId(UserId);
				if( target && IsClientInGame(target) )
					StartVoteAccessCheck(initiator, target);
			}
			return Plugin_Stop;
		}
	}
	return Plugin_Continue;
}

public Action Command_Votekick(int initiator, int args)
{
	if( initiator ) CreateVotekickMenu(initiator);
	return Plugin_Handled;
}


void CreateVotekickMenu(int initiator)
{
	Menu menu = new Menu(Menu_Votekick, MENU_ACTIONS_DEFAULT);
	static char name[MAX_NAME_LENGTH];
	static char uid[12];
	static char menuItem[64];
	static char ip[32];
	static char code[4];
	
	int iInitiatorTeam = GetClientTeam(initiator);
	int iTargetTeam;
	
	for( int i = 1; i <= MaxClients; i++ )
	{
		if( IsClientInGame(i) )
		{
			if( i == initiator && !g_bCvarShowSelf )
				continue;
			
			if( IsFakeClient(i) )
			{
				if( !g_bCvarShowBots )
					continue;
				
				if( GetClientTeam(i) != 2 )
					continue;
			}
			
			if( g_bIsVersus ) 
			{
				iTargetTeam = GetClientTeam(i);
				if( iInitiatorTeam != iTargetTeam && iTargetTeam != 1 ) // allow to kick a spectator
					continue;
			}
			Format(uid, sizeof(uid), "%i", GetClientUserId(i));
			if( GetClientName(i, name, sizeof(name)) )
			{
				NormalizeName(name, sizeof(name));
				
				if( GetClientIP(i, ip, sizeof(ip)) )
				{
					if( !GeoipCode3(ip, code) )
						strcopy(code, sizeof(code), "LAN");

					Format(menuItem, sizeof(menuItem), " %s (%s)", name, code);
					menu.AddItem(uid, menuItem);
				}
				else
					menu.AddItem(uid, name);
			}
		}
	}
	
	static char sTime[32];
	static char sSteam[64];
	int iPlayerLogicalTeam;
	StringMapSnapshot hSnap = hMapSteam.Snapshot();
	if( hSnap )
	{
		int iTime;
		for( int i = 0; i < hSnap.Length; i++ )
		{
			hSnap.GetKey(i, sSteam, sizeof(sSteam));
			hMapSteam.GetString(sSteam, sTime, sizeof(sTime));
			iTime = StringToInt(sTime);
			if( (g_iCvarKickTime - (GetTime() - iTime)) < 0 )	// expired bans
			{
				hMapSteam.Remove(sSteam);
				hMapPlayerName.Remove(sSteam);
				hMapPlayerTeam.Remove(sSteam);
				continue;
			}
			
			hMapPlayerName.GetString(sSteam, name, sizeof(name)); // active bans
			hMapPlayerTeam.GetValue(sSteam, iPlayerLogicalTeam);
			
			// Add banned player to menu for possible unkick. Specific to Versus mode: Only the team (logical team number, see also GetLogicalTeam) that kicked the player can then unkick him again
			//
			if( !(g_bIsVersus && GetLogicalTeam(iInitiatorTeam) != iPlayerLogicalTeam) ) {	
				Format(menuItem, sizeof(menuItem), "%s %s %T", g_sCharKicked, name, "time_left", initiator, (g_iCvarKickTime - (GetTime() - iTime)) / 60);  
				menu.AddItem(sSteam, menuItem);
			}
		}
		delete hSnap;
	}
	
	menu.SetTitle("%T", "Player To Kick", initiator);
	menu.Display(initiator, MENU_TIME_FOREVER);
}

public int Menu_Votekick(Menu menu, MenuAction action, int initiator, int target)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;
		
		case MenuAction_Select:
		{
			char info[32];
			if( menu.GetItem(target, info, sizeof(info)) )
			{
				if( strncmp(info, "STEAM_", 6, false) == 0 )
				{
					StartVoteAccessCheck_UnKick(initiator, info);
				}
				else {
					StartVoteAccessCheck(initiator, GetClientOfUserId(StringToInt(info)));
				}
			}
		}
	}
	return 0;
}

void StartVoteAccessCheck_UnKick(int initiator, char[] sSteam)
{
	if( IsVoteInProgress() || g_bVoteInProgress ) {
		CPrintToChat(initiator, "%t", "other_vote");
		LogVoteAction(initiator, "[DENY] Reason: another vote is in progress.");
		return;
	}

	if( !IsVoteAllowed(initiator, -1) )
	{
		if( g_bTooOften[initiator] )
		{
			// silence, no need to inform everyone except the initiator that he voted too often, this behavior is the same as the L4D votekick engine
			g_bTooOften[initiator] = false;
			return;
		}
		else
		{	
			char name[MAX_NAME_LENGTH];
			hMapPlayerName.GetString(sSteam, name, sizeof(name));
			CPrintToChatAll("%t", "no_access_specific_unkick", initiator, name); // "%s tried to use votekick against %s, but has no access."
			LogVoteAction(initiator, "[NO ACCESS]");
			LogToFileEx(g_sLog, "[TRIED] to un-kick against: %s", name);
			return;
		}
	}

	StartVoteUnKick(initiator, sSteam);
}

void StartVoteAccessCheck(int initiator, int target)
{
	if( IsVoteInProgress() || g_bVoteInProgress ) {
		CPrintToChat(initiator, "%t", "other_vote");
		LogVoteAction(initiator, "[DENY] Reason: another vote is in progress.");
		return;
	}

	if( target == 0 || !IsClientInGame(target) )
	{
		CPrintToChat(initiator, "%t", "not_in_game"); // "Client is already disconnected."
		return;
	}
	
	if( !IsVoteAllowed(initiator, target) )
	{
		if( g_bTooOften[initiator] )
		{
			// silence, no need to inform everyone except the initiator that he voted too often, this behavior is the same as the L4D votekick engine
			g_bTooOften[initiator] = false;
			return;
		}
		else
		{	
			char name[MAX_NAME_LENGTH];
			GetClientName(target, name, sizeof(name));
			CPrintToChatAll("%t", "no_access_specific", initiator, name); // "%s tried to use votekick against %s, but has no access."
			LogVoteAction(initiator, "[NO ACCESS]");
			LogVoteAction(target, "[TRIED] to kick against:");
			return;
		}
	}
	
	if( g_bCvarShowKickReason )
	{
		g_iKickTarget[initiator] = GetClientUserId(target);
		ShowMenuReason(initiator);
	}
	else {
		StartVoteKick(initiator, target);
	}
}

void ShowMenuReason(int initiator)
{
	char sReason[64];
	Menu menu = new Menu(Menu_Reason, MENU_ACTIONS_DEFAULT);
	
	for( int i = 0; i < g_hArrayVoteReason.Length; i++ )
	{
		g_hArrayVoteReason.GetString(i, sReason, sizeof(sReason));
		Format(sReason, sizeof(sReason), "%T", sReason, initiator);
		menu.AddItem("", sReason);
	}
	menu.SetTitle("%T:", "Reason_Menu", initiator);
	menu.Display(initiator, MENU_TIME_FOREVER);
}

public int Menu_Reason(Menu menu, MenuAction action, int initiator, int iReason)
{
	switch( action )
	{
		case MenuAction_End:
			delete menu;

		case MenuAction_Cancel:
		{
			// initiator (id: initiator) has decided not to not start the vote (Cancel) -> 
			// his 60-second penalty set in IsVote Allowed is therefore reduced, allowing him to reopen the VK menu shortly afterwards
			// The remaining delay is to avoid stressing the server (2 seconds should be enough) by intentionally spamming the command to open the menu.
			g_iLastTime[initiator] = 2;
		}
	
		case MenuAction_Select:
		{
			// In the case of g_bCvarShowKickReason == true, it is not properly checked whether a vote is already running. So let's take a look here before we start another one in parallel
			if( IsVoteInProgress() || g_bVoteInProgress ) {
				CPrintToChat(initiator, "%t", "other_vote");
				LogVoteAction(initiator, "[DENY] Reason: another vote is in progress.");
			} else {
				int target = GetClientOfUserId(g_iKickTarget[initiator]);
				if( target && IsClientInGame(target) )
				{
					if ( g_bIsVersus )
					{
						if ( GetClientTeam(target) == GetClientTeam(initiator) )  // Before voting starts, check also if target is still on the same team as initiator, as the Reason menu can be open forever before initiator selects
						{
							g_iReason = iReason;
							StartVoteKick(initiator, target);
						}
					} else
					{
						g_iReason = iReason;
						StartVoteKick(initiator, target);
					}
				}
			}
		}
	}
	return 0;
}

int GetRealClientCount() {
	int cnt;
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && ( !IsFakeClient(i) || g_bCvarShowBots ) ) cnt++;
	return cnt;
}

//	Versus: count members of initiator team
// 
int GetRealTeamClientCount(int iTeam) {
	int cnt;
	for( int i = 1; i <= MaxClients; i++ )
		if( IsClientInGame(i) && ( !IsFakeClient(i) || g_bCvarShowBots ) && GetClientTeam(i) == iTeam ) cnt++; //Versus: get only number of members of team of initiator of votekick
	return cnt;
}

bool IsVoteAllowed(int initiator, int target)
{
	
	bool bHasVoteAccessFlagClient = HasVoteAccessFlag(initiator);

	if( target != -1)
	{
		if( target == 0 || !IsClientInGame(target) )
			return false;
	
		if( initiator == target )
		{
			if ( g_bCvarShowSelf )
				return true;
			else
				return false;
		}
	
		// This comparison does not trigger an "Exception reported: Client index -1 is invalid", but logically precedes the subsequent comparison 
		// if( initiator == target && bHasVoteAccessFlagClient )
		//	return true;
	
		if( IsClientRootAdmin(target) )
			return false;
	}
	
	if( IsClientRootAdmin(initiator) )
		return true;
	
	if( g_iLastTime[initiator] != 0 )
	{
		if( g_iLastTime[initiator] + g_iCvarDelay > GetTime() ) {
			CPrintToChat(initiator, "%t", "too_often"); // "You can't vote too often!"
			LogVoteAction(initiator, "[DENY] Reason: too often.");
			g_bTooOften[initiator] = true;
			return false;
		}
	}
	g_iLastTime[initiator] = GetTime();
	
	// Check if there are enough players in order to vote for kick/unkick. 
	// Versus minimum may be set differently, cfg variable "sm_votekick_minplayers_versus"
	//
	int iClients = GetRealClientCount();
	int iMinPlayers = 0;
	if ( g_bIsVersus ) {
		iClients = GetRealTeamClientCount( GetClientTeam(initiator) ); //Versus: only team of initiator is allowed to vote
		iMinPlayers = g_iMinPlayersVersus;
	}
	else {
		iMinPlayers = g_iMinPlayers;
	}
	if( iClients < iMinPlayers ) {
		CPrintToChat(initiator, "%t", "not_enough_players", iMinPlayers); // "Not enough players to start the vote. Required minimum: %i"
		LogVoteAction(initiator, "[DENY] Reason: Not enough players. Now: %i, required: %i.", iClients, iMinPlayers);
		return false;
	}
	
	if( target != -1)
	{
		if( HasVoteAccessFlag(target) && !bHasVoteAccessFlagClient )
			return false;
	

		if( GetImmunityLevel(initiator) < GetImmunityLevel(target) )
		{
			CPrintToChat(initiator, "%t", "no_access_immunity");
			LogVoteAction(initiator, "[DENY] Reason: Target immunity (%i) is higher than vote initiator (%i)", GetImmunityLevel(target), GetImmunityLevel(initiator));
			return false;
		}
	
		if( IsAdmin(target) && !IsAdmin(initiator) )
			return false;

		if( InDenyFile(target, g_hArrayVoteBlock) )	// allow to vote everybody against clients who located in deny list (regardless of vote access flag)
		{
			LogVoteAction(initiator, "[ALLOW] Reason: target is in deny list.");
			return true;
		}

		if( !g_bCvarShowBots && IsFakeClient(target) )
			return false;
	}
		
	if( InDenyFile(initiator, g_hArrayVoteBlock) )
	{
		LogVoteAction(initiator, "[DENY] Reason: player is in deny list.");
		return false;
	}

	return bHasVoteAccessFlagClient;
}

bool InDenyFile(int client, ArrayList list)
{
	static char sName[MAX_NAME_LENGTH], str[MAX_NAME_LENGTH];
	static char sSteam[64];
	
	GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
	GetClientName(client, sName, sizeof(sName));
	
	for( int i = 0; i < list.Length; i++ )
	{
		list.GetString(i, str, sizeof(str));
	
		if( strncmp(str, "STEAM_", 6, false) == 0 )
		{
			if( strcmp(sSteam, str, false) == 0 )
			{
				return true;
			}
		}
		else {
			if( StrContains(str, "*") ) // allow masks like "Dan*" to match "Danny and Danil"
			{
				ReplaceString(str, sizeof(str), "*", "");
				if( StrContains(sName, str, false) != -1 )
				{
					return true;
				}
			}
			else {
				if( strcmp(sName, str, false) == 0 )
				{
					return true;
				}
			}
		}
	}
	return false;
}

void GetReason(char[] sReasonEng, int len)
{
	if( g_bCvarShowKickReason )
	{
		if( g_iReason < g_hArrayVoteReason.Length )
		{
			g_hArrayVoteReason.GetString(g_iReason, sReasonEng, len);
			return;
		}
	}
	strcopy(sReasonEng, len, "kick_reason");
}

// The advanced vote handling callback receives detailed results of voting, 
// which will be displayed to the Team the initiator belongs to (versus) or to all (co-op), 
// if "sm_votekick_show_vote_details" is set to "1" ("0": vote results are not shown)
// This handler is et via Menu.VoteResultCallback property (see below). If this callback is set, 
// MenuAction_VoteEnd will not be called for menu.DisplayVoteToAll and menu.DisplayVote, which is no longer needed. 
// The use of Menu.VoteResultCallback was necessary, because on a tie, a random item is returned by menu.VoteDisplay()
// from a list of the tied items (confirmed in my tests: sometimes in case of a tie it returns 0 and player is kicked out, 
// which is of course not acceptable. Behavior may be due to intended use in the case of map voting).
//
public void Handle_VoteResults(	Menu menu,	// The menu being voted on.
				int num_votes,				// Number of votes tallied in total.
				int num_clients,			// Number of clients who could vote.
				const int[][] client_info,	// Array of clients.  Use VOTEINFO_CLIENT_ defines.
				int num_items,				// Number of unique items that were selected.
				const int[][] item_info )	// Array of items, sorted by count.  Use VOTEINFO_ITEM defines.
{

	// VoteResults handle not appears when nobody has voted at all, so we need to test only for cases: num_items >= 1

	int yesVotes = 0; int noVotes = 0;
	if( num_items == 1 )
	{
		// winner vote is array index 0

		if( item_info[0][VOTEINFO_ITEM_INDEX] == 0 )		// item_info[0][0] ="Yes" wins
			yesVotes = item_info[0][VOTEINFO_ITEM_VOTES];
		else
			noVotes = item_info[0][VOTEINFO_ITEM_VOTES];	// item_info[0][1] ="No" wins
	} 
	else if( num_items > 1 )
	{
		if( item_info[0][VOTEINFO_ITEM_VOTES] == item_info[1][VOTEINFO_ITEM_VOTES] )	// Tie: #"Yes" = #"No"
			yesVotes = noVotes = item_info[0][VOTEINFO_ITEM_VOTES];
		else
		{
			if( item_info[0][VOTEINFO_ITEM_INDEX] == 0 )
			{
				yesVotes = item_info[0][VOTEINFO_ITEM_VOTES];	// item_info[0][0] ="Yes" wins
				noVotes = item_info[1][VOTEINFO_ITEM_VOTES];
			}
			else
			{
				noVotes = item_info[0][VOTEINFO_ITEM_VOTES];	// item_info[0][1] ="No" wins
				yesVotes = item_info[1][VOTEINFO_ITEM_VOTES];
			}
		}
	}
	
	VoteResultsDisplay( yesVotes, noVotes, num_votes, num_clients ) ;
	g_bVoteNoButtonPressed = false ;
}

void VoteResultsDisplay(int yesVotes, int noVotes, int num_votes = 0, int num_clients = 0 )
{
	// Initiator votes "Yes" automatically
	//
	yesVotes++ ;
	
	// Target votes "No" automatically, if he is not idle (L4D behaviour)
	// If the target userid (g_iKickUserId) is -1, this is the result of a vote to "unkick" a suspended player who doesn't currently have a valid player id. In this case, there is no automatic no vote for that player.
	if ( g_iKickUserId != -1 && !g_bTargetManualVote ) noVotes++; 
	
	// Show vote result details, if "sm_votekick_show_vote_details" is set to "1" in cfg
	// don't show voting results in case of a votepass or veto
	//
	if( g_bCvarShowVoteDetails && (!g_bVotepass || !g_bVeto) )
		if( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel > 0 ) 
			CPrintToChatTeam( GetClientTeamOfLogical(g_iVoteInitiatorLogicalTeam), "%t", "detailed_vote_results", yesVotes, noVotes, (num_clients-num_votes) );
		else
			CPrintToChatAll( "%t", "detailed_vote_results", yesVotes, noVotes, (num_clients-num_votes) );

	if( (yesVotes > noVotes || g_bVotepass) && !g_bVeto )
		Handler_PostVoteAction(true); // kick player
	else
		Handler_PostVoteAction(false); // vote failed

	g_bVoteInProgress = false;

}

void StartVoteKick(int initiator, int target)
{
	Menu menu = new Menu(Handle_Votekick, MenuAction_DisplayItem | MenuAction_Display);
	menu.VoteResultCallback = Handle_VoteResults;
	g_iKickUserId = GetClientUserId(target);
	g_iInitiatorUserId = GetClientUserId(initiator);
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;
	
	GetClientAuthId(target, AuthId_Steam2, g_sSteam, sizeof(g_sSteam));
	GetClientName(target, g_sName, sizeof(g_sName));
	GetClientIP(target, g_sIP, sizeof(g_sIP));
	GeoipCode3(g_sIP, g_sCountry);
	
	LogVoteAction(initiator, "[KICK STARTED] by");
	LogVoteAction(target, "[KICK AGAINST] ");
	
	g_bVotepass = false;
	g_bVeto = false;
	g_bVoteDisplayed = false;
	
	// Update the global variable before CPrintHintTextToTeam to fix the bug, when the global variable g_iVoteInitiatorLogicalTeam contained the wrong team id of a previous vote
	int iTeam = GetClientTeam(initiator);
	g_iVoteInitiatorLogicalTeam = GetLogicalTeam(iTeam);

	// If the target is inactive, there is no passive vote in his favor against his expulsion, but the target must actively participate in the vote
	//	
	if( g_bIsVersus )
	{
		if ( GetTime() - g_iTime_Offset[target] >= g_iCvarVersusInactiveTime )
		{
			g_bTargetManualVote = true;

			// No "inactive" state for a dead player (official L4D behavior)
			// -> automatic vote against kick vote
			//
			if( IsClientInGame(target) && !IsPlayerAlive(target) )
				g_bTargetManualVote = false;
		}		
		else
			g_bTargetManualVote = false;
		
		g_iNum_Clients = GetRealTeamClientCount( GetClientTeam(initiator) ) ;

	} else
	{
		if ( get_bot_of_idled( target ) )
			g_bTargetManualVote = true;
		else
			g_bTargetManualVote = false;
		
		g_iNum_Clients = GetRealClientCount() ;
	}

	if( g_bCvarShowKickReason )
	{
		char sReasonEng[32];
		GetReason(sReasonEng, sizeof(sReasonEng));
		LogVoteAction(0, "[REASON] %s", sReasonEng);
		
		// Msg to issuer team
		if ( g_bCvarInitiatorAnonymous ) 
			if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel > 0 )
				// vote_started_anonymous_initiator -- added to phrases.txt in v5.0
				CPrintToChatTeam( iTeam, "%t \x01(%t %t\x01)", "vote_started_anonymous_initiator", g_sName, "Reason", sReasonEng);
			else
				CPrintToChatAll( "%t \x01(%t %t\x01)", "vote_started_anonymous_initiator", g_sName, "Reason", sReasonEng);
		else
			if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel > 0 )
				CPrintToChatTeam( iTeam, "%t \x01(%t %t\x01)", "vote_started", initiator, g_sName, "Reason", sReasonEng);
			else
				CPrintToChatAll("%t \x01(%t %t\x01)", "vote_started", initiator, g_sName, "Reason", sReasonEng);

		// Msg to other team
		if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel == 2)
			// vote_started_otherteam -- added to phrases.txt in v5.0
			CPrintToChatTeam(GetOppositeClientTeam(iTeam), "%t", "vote_started_otherteam");

		CPrintHintTextToTeam( iTeam, "%t\n(%t: %t)", "vote_started_announce", g_sName, "Reason_Menu", sReasonEng);
	}
	else
	{
		// Msg to issuer team
		if ( g_bCvarInitiatorAnonymous )
			if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel > 0 ) {
				CPrintToChatTeam( iTeam, "%t", "vote_started_anonymous_initiator", g_sName );
			} else
				CPrintToChatAll( "%t", "vote_started_anonymous_initiator", g_sName );
		else
			if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel > 0 ) {
				CPrintToChatTeam( iTeam, "%t", "vote_started", initiator, g_sName );
			} else
				CPrintToChatAll( "%t", "vote_started", initiator, g_sName );
			
		// Msg to other team
		if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel == 2 )
			CPrintToChatTeam(GetOppositeClientTeam(iTeam), "%t", "vote_started_otherteam");

		CPrintHintTextToTeam( iTeam, "%t", "vote_started_announce", g_sName );
	}

	// Inform target how to vote against Kickvote (depends on whether he is considered active or inactive)
	//

	if ( !g_bTargetManualVote )
		CPrintToChat(target, "%t", "note_to_target_automatic_vote"); // "Note: Your vote against will be cast automatically" -- added to phrases.txt in v4.4
	else
		CPrintToChat(target, "%t", "note_to_target_manual_vote"); // "Since you are inactive, you must manually vote against it" -- added to phrases.txt in v4.4

	PrintToServer("Voting for Kick is started by: %N", initiator);
	if ( g_bCvarInitiatorAnonymous )
		PrintToConsoleAll("A vote for Kick has been started");
	else
		PrintToConsoleAll("Voting for Kick is started by: %N", initiator);
		
	// Due to the delay of the Timer_VoteDelayed function, g_bVoteInProgress must be set here, as it is possible (and has already happened) that a second vote will begin within g_hCvarAnnounceDelay (before vote starts with menu.DisplayVote), which of course will confuse players
	g_bVoteInProgress = true;

	if ( g_iNum_Clients == 2 && !g_bTargetManualVote ) 
	{
		// Tie if there are only 2 players in the team and the target is not AFK
		VoteResultsDisplay( 0, 0, 2, 2 ) ;
		g_bVoteInProgress = false;
	}
	else
	{
		g_bVoteNoButtonPressed = true ;

		CreateTimer(g_fCvarAnnounceDelay, Timer_VoteDelayed, menu);

	}

}

void StartVoteUnKick(int initiator, char[] sSteam)
{
	Menu menu = new Menu(Handle_Votekick, MenuAction_DisplayItem | MenuAction_Display);
	menu.VoteResultCallback = Handle_VoteResults;
	g_iKickUserId = -1;
	g_iInitiatorUserId = GetClientUserId(initiator);
	menu.AddItem("", "Yes");
	menu.AddItem("", "No");
	menu.ExitButton = false;

	strcopy(g_sSteam, sizeof(g_sSteam), sSteam); 
	hMapPlayerName.GetString(sSteam, g_sName, sizeof(g_sName));
	g_sIP[0] = 0;
	g_sCountry[0] = 0;
	
	g_bVotepass = false;
	g_bVeto = false;
	g_bVoteDisplayed = false;
	int iTeam = GetClientTeam(initiator);
	g_iVoteInitiatorLogicalTeam = GetLogicalTeam(iTeam);

	if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel > 0 )
		// vote_started_unkick_otherteam -- added to phrases.txt in v5.0
		CPrintToChatTeam( GetOppositeClientTeam(iTeam), "%t", "vote_started_unkick_otherteam", g_sName);
	else if ( g_bCvarInitiatorAnonymous )
		// vote_started_unkick_anonymous_initiator -- added to phrases.txt in v5.0
		CPrintToChatAll("%t", "vote_started_unkick_anonymous_initiator", g_sName); // A vote to un-kick {cyan}%s{white} has been started.
	else
		CPrintToChatAll("%t", "vote_started_unkick", initiator, g_sName); // %N is started vote for un-kick: %s
	
	PrintToServer("Vote for un-kick is started by: %N", initiator);
	PrintToConsoleAll("Vote for un-kick is started by: %N", initiator);
	
	LogVoteAction(initiator, "[UN-KICK STARTED] by");
	LogVoteAction(0, "[UN-KICK] ");

	if( g_bIsVersus )
	{
		g_iNum_Clients = GetRealTeamClientCount( GetClientTeam(initiator) ) ;

	} else
	{
		g_iNum_Clients = GetRealClientCount() ;
	}
	
	// Due to the delay of the Timer_VoteDelayed function, g_bVoteInProgress must be set here, as it is possible (and has already happened) that a second vote will begin within g_hCvarAnnounceDelay (before vote starts with menu.DisplayVote), which of course will confuse players
	g_bVoteInProgress = true;
	
	//Required because the initiator's vote was not counted and the vote had no effect if no one pressed a vote button.
	g_bVoteNoButtonPressed = true ;
	
	CreateTimer(g_fCvarAnnounceDelay, Timer_VoteDelayed, menu);
	
	CPrintHintTextToTeam( iTeam, "%t", "vote_started_announce_unkick", g_sName );
}

Action Timer_VoteDelayed(Handle timer, Menu menu)
{
	if( g_bVotepass || g_bVeto ) {
		Handler_PostVoteAction(g_bVotepass);
		delete menu;
	}
	else {
		if( !IsVoteInProgress() ) {

			int[] iClients = new int[MaxClients];
			int iCount = 0;
			int target = GetClientOfUserId( g_iKickUserId ) ;
			int initiator = GetClientOfUserId( g_iInitiatorUserId );
			
			if( g_bIsVersus )
			{
				int iVoteInitiatorClientTeam = GetClientTeamOfLogical(g_iVoteInitiatorLogicalTeam);

				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientInGame(i) && GetClientTeam(i) == iVoteInitiatorClientTeam )
					{
						if ( i != target && i != initiator ) iClients[iCount++] = i;
						else if ( g_bTargetManualVote ) 
						{
							iClients[iCount++] = target;
						}
					}
				}
			}
			else {
				
				for( int i = 1; i <= MaxClients; i++ )
				{
					if( IsClientInGame(i) )
					{
						if ( i != target && i != initiator ) iClients[iCount++] = i;
						else if ( g_bTargetManualVote )
						{
							iClients[iCount++] = target;
						}
					}
				}
			}
			
			menu.DisplayVote(iClients, iCount, g_iCvarTimeout);
			g_bVoteDisplayed = true ;

		}
		else {
			delete menu;
		}
	}
	return Plugin_Continue;
}


public int Handle_Votekick(Menu menu, MenuAction action, int player, int param2)
{
	static char display[64], buffer[255];

	switch( action )
	{
		case MenuAction_End: 
		{
			g_bVoteInProgress = false;
			delete menu;

			// in case vote is passed with CancelVote(), so MenuAction_VoteEnd is not called.
			//
			if ( g_bVotepass )
			{
				Handler_PostVoteAction(true);
			}
			// The voting result should not be displayed in case of a pass or veto
			//
			else if ( g_bVoteNoButtonPressed && !g_bVeto )
			{
				// Initiator automatically votes against target
				// Target votes automatically unless it is AFK
				// Even if no one presses a button, there is at least one vote
				//
				VoteResultsDisplay( 0, 0, (g_bTargetManualVote || g_iKickUserId == -1 ?1:2), g_iNum_Clients ) ;
			}
			
			// does currently nothing, just in case
			/*
			if ( player == MenuEnd_VotingCancelled )
			{
				PrintToServer("No Votes or Vote Cancelled!");
			}
			else if ( player == MenuEnd_VotingDone )
			{
				PrintToServer("Voting Done!");
			}
			*/
		}
		
		case MenuAction_DisplayItem:
		{
			menu.GetItem(param2, "", 0, _, display, sizeof(display));
			Format(buffer, sizeof(buffer), "%T", display, player);
			return RedrawMenuItem(buffer);
		}
		case MenuAction_Display:
		{
			Format(buffer, sizeof(buffer), "%T", g_iKickUserId == -1 ? "vote_started_announce_unkick" : "vote_started_announce", player, g_sName); // "Do you want to kick: %s ?"
			menu.SetTitle(buffer);
		}
	}
	return 0;
}

void Handler_PostVoteAction(bool bVoteSuccess)
{
	if( g_iKickUserId == -1 )
	{
		if( bVoteSuccess ) {
			hMapSteam.Remove(g_sSteam);
			hMapPlayerName.Remove(g_sSteam);
			hMapPlayerTeam.Remove(g_sSteam);
			LogVoteAction(0, "[UN-KICKED]");
			CPrintToChatAll("%t", "vote_success_unkick", g_sName);
		}
		else {
			LogVoteAction(0, "[NOT ACCEPTED]");
			CPrintToChatAll("%t", "vote_failed_unkick", g_sName);
		}
	}
	else {
		int iVoteInitiatorClientTeam = GetClientTeamOfLogical(g_iVoteInitiatorLogicalTeam);

		if( bVoteSuccess ) {
			char sTime[32], sReasonEng[32];
			int iTarget = GetClientOfUserId(g_iKickUserId);
			
			//initialize sReasonEng here, in case IsClientInGame(iTarget) == false (e.g. target timed out in the meantime or immediately disconnected by intention, in that case SM would throw an error later in CPrintToChatAll below: "Language phrase "" not found (arg 6)")
			if( g_bCvarShowKickReason )
				GetReason(sReasonEng, sizeof(sReasonEng));
			if( iTarget && IsClientInGame(iTarget) ) {
				if( g_bCvarShowKickReason )
				{
					if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel > 0 )
					{
						CPrintToChatTeam( iVoteInitiatorClientTeam, "%t. %t %t", "vote_success", g_sName, "Reason", sReasonEng );
						// vote_success_otherteam -- added to phrases.txt in v5.0
						CPrintToChatTeam( GetOppositeClientTeam( iVoteInitiatorClientTeam ), "%t", "vote_success_otherteam", g_sName );
					}
					else {
						CPrintToChatAll( "%t. %t %t", "vote_success", g_sName, "Reason", sReasonEng );
					}
				}
				else {
					if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel > 0 )
					{
						CPrintToChatTeam( iVoteInitiatorClientTeam, "%t", "vote_success", g_sName );
						CPrintToChatTeam( GetOppositeClientTeam( iVoteInitiatorClientTeam ), "%t", "vote_success_otherteam", g_sName );
					}
					else {
						CPrintToChatAll("%t", "vote_success", g_sName);
					}
					
				}

				// Timer required because a kicked player did not receive the chat message
				//
				CreateTimer(0.5, TimerKickClient, _, TIMER_FLAG_NO_MAPCHANGE);
			}
			FormatEx(sTime, sizeof(sTime), "%i", GetTime());
			hMapSteam.SetString(g_sSteam, sTime, true);
			hMapPlayerName.SetString(g_sSteam, g_sName, true);
			hMapPlayerTeam.SetValue(g_sSteam, g_iVoteInitiatorLogicalTeam, true);
			
			LogVoteAction(0, "[KICKED]");

		}
		else {
			LogVoteAction(0, "[NOT ACCEPTED]");
			
			if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel == 2 ) {
				CPrintToChatTeam( iVoteInitiatorClientTeam, "%t", "vote_failed" );
				// vote_failed_otherteam -- added to phrases.txt in v5.0
				CPrintToChatTeam(GetOppositeClientTeam( iVoteInitiatorClientTeam ), "%t", "vote_failed_otherteam");
			}
			else if ( g_bIsVersus && g_iCvarVsOtherTeamInfoLevel == 1 )
				CPrintToChatTeam( iVoteInitiatorClientTeam, "%t", "vote_failed" );
			else if ( !g_bIsVersus || g_iCvarVsOtherTeamInfoLevel == 0 )
				CPrintToChatAll("%t", "vote_failed");
		}
	}
	g_bVoteInProgress = false;
}
 
//This function is required to delay the expulsion by a minimum of 0.1 seconds. Otherwise, the expelled user won't see the voting results.
//
public Action TimerKickClient( Handle timer )
{
	int iTarget = GetClientOfUserId(g_iKickUserId);
	char sReasonEng[32];
	
	if ( iTarget && IsClientInGame(iTarget) )
	{
		if ( g_bCvarShowKickReason )
		{
			GetReason(sReasonEng, sizeof(sReasonEng));
			KickClient(iTarget, "%t: %t", "kick_for", sReasonEng);
		}
		else
		{
			KickClient(iTarget, "%t", "kick_reason"); // You have been kicked from session
		}
	}
	return Plugin_Stop;
}

public void OnClientPutInServer(int client){
	g_iTime_Offset[client] = GetTime();
}

public void OnPlayerRunCmdPost(int client, int buttons){
	if (buttons != g_iLastbuttons[client]){
		g_iTime_Offset[client] = GetTime();
	}
	g_iLastbuttons[client] = buttons;
}

public void OnClientAuthorized(int client, const char[] auth)
{
	
	// After the client connects, first check whether he is properly authenticated with its Steam ID. If not, kick him immediately.
	// Explaination: only clients who properly authenticate with their Steam ID are allowed to participate in the game to prevent banned clients from avoiding a ban
	// Exploit example: https://forums.alliedmods.net/showthread.php?t=293984
	//
	static char sSteam[64];
	if ( GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam)) ) // did retrieve a proper Steam ID
	{	
		static char sTime[32];
		static int iTime;
		
		if( strcmp(auth, "BOT") != 0 ) 
		{
			if( hMapSteam.GetString(auth, sTime, sizeof(sTime)) ) {
				iTime = StringToInt(sTime);
				if( GetTime() - iTime < g_iCvarKickTime ) { // 1 hour
					KickClient(client, "%t", "kick_reason"); // You have been kicked from session
					if( g_bCvarLog )
						LogToFileEx(g_sLog, "[DENY] %N | %s cannot join because kicked. Time left = %i min.", client, auth, (g_iCvarKickTime - (GetTime() - iTime)) / 60);
				}
				else {
					hMapSteam.Remove(auth);
					hMapPlayerName.Remove(auth);
					hMapPlayerTeam.Remove(auth);
				}
			}
			else 
			if ( g_bCvarUseBanfile )
			{
			    if( hMapBanStart.GetString(auth, sTime, sizeof(sTime)) ) {
			    	iTime = StringToInt(sTime);
			    	if( (GetTime() - iTime) > 0 ) {  // Start value is in the past -> ban active if stop value is in the future
						hMapBanStop.GetString(auth, sTime, sizeof(sTime));
						iTime = StringToInt(sTime);
						if( (GetTime() - iTime) < 0 ) {	// Stop value is in the future -> Ban is active -> kick player
							if ( TranslationPhraseExists("steamid_is_banned") )
								KickClient(client, "%t", "steamid_is_banned", auth); // "STEAM UserID STEAM_1:1:123456789 is banned." added to phrases.txt in v4.0
							else
								KickClient(client, "STEAM UserID %s is banned", auth); // You have been kicked from session, compatibility with v3.5 phrases.txt
							if( g_bCvarLog && g_bCvarUseBanfileLog )
								LogToFileEx(g_sLog, "[DENY] %N | %s cannot join because temporary banned. Time left = %s.", client, auth, SecsToDays( iTime - GetTime() ) );
			    		}
						else {	// Stop value is in the past -> Ban has expired -> delete ban from memory and also from ban list file
							hMapBanStart.Remove(auth);
							hMapBanStop.Remove(auth);
							hMapBanSelfnote.Remove(auth);
							SaveBanList( .bDelExpiredBan = true, .sExpiredBanSteamId = auth );
						}
					}
				}
			}
		}
	} 
	else // didn't retrieve a proper Steam ID
	{
		KickClient(client, "%t", "kick_reason"); // You have been kicked from session
		LogToFileEx(g_sLog, "[DENY] %N | %s cannot join because kicked. Reason: no proper Steam ID retrieved: %s", sSteam);
	}
}

stock bool IsClientRootAdmin(int client)
{
	return ((GetUserFlagBits(client) & ADMFLAG_ROOT) != 0);
}

bool HasVoteAccessFlag(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT != 0 ) return true;
	if (g_iCvarAccessFlag == 0) return true;			// sm_votekick_accessflag="" (leave empty to allow for everybody)
	return (iUserFlag & g_iCvarAccessFlag != 0);
}

bool HasVetoAccessFlag(int client)
{
	int iUserFlag = GetUserFlagBits(client);
	if( iUserFlag & ADMFLAG_ROOT != 0 ) return true;
	return (iUserFlag & g_iCvarVetoFlag != 0);
}

void LogVoteAction(int client, const char[] format, any ...)
{
	if( !g_bCvarLog )
		return;
	
	static char sSteam[64];
	static char sIP[32];
	static char sCountry[4];
	static char sName[MAX_NAME_LENGTH];
	static char buffer[256];
	
	VFormat(buffer, sizeof(buffer), format, 3);
	
	if( client && IsClientInGame(client) ) {
		GetClientAuthId(client, AuthId_Steam2, sSteam, sizeof(sSteam));
		GetClientName(client, sName, sizeof(sName));
		GetClientIP(client, sIP, sizeof(sIP));
		GeoipCode3(sIP, sCountry);
		LogToFileEx(g_sLog, "%s %s (%s | [%s] %s)", buffer, sName, sSteam, sCountry, sIP);
	}
	else {
		LogToFileEx(g_sLog, "%s %s (%s | [%s] %s)", buffer, g_sName, g_sSteam, g_sCountry, g_sIP);
	}
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
    char buffer[192];
    SetGlobalTransTarget(iClient);
    VFormat(buffer, sizeof(buffer), format, 3);
    ReplaceColor(buffer, sizeof(buffer));
    PrintToChat(iClient, "\x01%s", buffer);
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

// Versus: msg only to members of iTeam (client team number)
//
stock void CPrintToChatTeam(int iTeam, const char[] format, any ...)
{
    char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
	if( IsClientInGame(i) && !IsFakeClient(i) && GetClientTeam(i) == iTeam )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 3);
            ReplaceColor(buffer, sizeof(buffer));
            PrintToChat(i, "\x01%s", buffer);
        }
    }
}

stock void CPrintHintTextToAll(const char[] format, any ...)
{
    static char buffer[192];
    for( int i = 1; i <= MaxClients; i++ )
    {
        if( IsClientInGame(i) && !IsFakeClient(i) )
        {
            SetGlobalTransTarget(i);
            VFormat(buffer, sizeof(buffer), format, 2);
            PrintHintText(i, buffer);
        }
    }
}

// Versus: msg only to members of iTeam (client team number)
//
stock void CPrintHintTextToTeam(int iTeam, const char[] format, any ...)
{
	static char buffer[192];
//	int iBotTargetId = get_bot_of_idled(GetClientOfUserId(g_iKickUserId));
	int iTarget = GetClientOfUserId(g_iKickUserId);
	int iInitiator = GetClientOfUserId(g_iInitiatorUserId);
	
	for( int i = 1; i <= MaxClients; i++ )
    {
		if( IsClientInGame(i) && !IsFakeClient(i) )
		{
			if ( g_bIsVersus )
			{
				if ( GetClientTeam(i) == iTeam )
				{
					if ( i != iInitiator &&  ( i != iTarget || g_bTargetManualVote ) )
					{
						SetGlobalTransTarget(i);
						VFormat(buffer, sizeof(buffer), format, 3);
						PrintHintText(i, buffer);
					}
				}
			}
			else if ( i != iInitiator &&  ( i != iTarget || g_bTargetManualVote ) )
			{
				SetGlobalTransTarget(i);
				VFormat(buffer, sizeof(buffer), format, 3);
				PrintHintText(i, buffer);
			}
		}
	}
}

int GetImmunityLevel(int client)
{
	AdminId id = GetUserAdmin(client);
	if( id != INVALID_ADMIN_ID )
	{
		return GetAdminImmunityLevel(id);
	}
	return 0;
}

bool IsAdmin(int client)
{
	return GetUserAdmin(client) != INVALID_ADMIN_ID;
}

void NormalizeName(char[] name, int len)
{
	int i, j, k, bytes;
	char sNew[MAX_NAME_LENGTH];
	
	while( name[i] )
	{
		bytes = GetCharBytes(name[i]);
		
		if( bytes > 1 )
		{
			for( k = 0; k < bytes; k++ )
			{
				sNew[j++] = name[i++];
			}
		}
		else {
			if( name[i] >= 32 )
			{
				sNew[j++] = name[i++];
			}
			else {
				i++;
			}
		}
	}
	strcopy(name, len, sNew);
}

// A team's logical team number does not change during the game and is derived from the current 
// client team number (0=spectator,1=survivor,2=zombie), which may change with the next map (here iTeam). 
// Requires to include sdktools_gamerules (included in SM). https://forums.alliedmods.net/showthread.php?t=282369
//
int GetLogicalTeam(int iClientTeam)
{
    return (iClientTeam ^ GameRules_GetProp("m_bAreTeamsFlipped", 1)) - 1;
}  

// Reverse function of GetLogicalTeam()
//
int GetClientTeamOfLogical(int iLogicalTeam)
{
    return (iLogicalTeam + 1) ^ GameRules_GetProp("m_bAreTeamsFlipped", 1);
}

// Returns client team number of the opposite team
//
int GetOppositeClientTeam(int iTeam)
{
    if ( iTeam == 2 )
		return 3;
	else
		return 2;
}  

// Seconds to days, hours, minutes, seconds
//
stock char[] SecsToDays(int iSeconds)
{
	char sDays[128];
	int iDays, iHours, iMinutes;
	
	if(iSeconds > 59)
	{
		iMinutes = iSeconds / 60;
		iSeconds = iSeconds - (iMinutes * 60);
	}
	if(iMinutes > 59)
	{
		iHours = iMinutes / 60;
		iMinutes = iMinutes - (iHours * 60);
	}
	if(iHours > 23)
	{
		iDays = iHours / 24;
		iHours = iHours - (iDays * 24);
	}
	
	Format(sDays,sizeof(sDays),"%i days %i hours %i minutes", iDays, iHours, iMinutes); 
	
	return sDays;
}

void LoadBanList()
{
	static bool bSaveBanFile = false;
	static int iLastReadInstance;
	int ft;
	
	bSaveBanFile = false;
	
	if( !FileExists(FILE_BAN) )	// write ban file if not exist
	{	
		// Delete all entries from memory before
		hMapBanStart.Clear();
		hMapBanStop.Clear();
		hMapBanSelfnote.Clear();
		SaveBanList();
	}
	if( !FileExists(FILE_BAN_LASTWRITE) )	// write ban file timestamp file if not exist
	{
		Handle hFile = OpenFile(FILE_BAN_LASTWRITE, "w");
		CloseHandle(hFile);
	}

	// if there is a timestamp difference of ban file to iLastReadInstance (= probably due to changed ban entries)
	// -> reload ban file into memory. Rewrite ban file (e.g. adding human-readable Information) then, if its timestamp differs from FILE_BAN_LASTWRITE
	if( iLastReadInstance 		!= (ft = GetFileTime(FILE_BAN, FileTime_LastChange)) )
	{
		ArrayList hArrayBan;
		static char sTime[32], sBuffer[128], sPair[ 4 ][ 22 ], buffer[16];
		static int iTime, iDays, iHours, iMinutes;

		if (GetFileTime(FILE_BAN_LASTWRITE, FileTime_LastChange) != ft)
			bSaveBanFile = true;	// ban file has been changed, add human-readable information using SaveBanFile()
		else
			// Another server instance of this plugin had loaded the ban file and had called SaveBanList() in order to add human-readable information to the file
			// This instance still needs to load the ban file, but no longer needs to call SaveBanList() 
			// iLastReadInstance = ft; to prevent this instance from reloading the ban file next time a map change occours
			iLastReadInstance = ft;	

		// Delete all entries from memory before reloading the ban file
		hMapBanStart.Clear();
		hMapBanStop.Clear();
		hMapBanSelfnote.Clear();
		
		hArrayBan = new ArrayList(ByteCountToCells(64));
		ReadFileToArrayList(FILE_BAN, 	hArrayBan);
		
		for( int i = 0; i < hArrayBan.Length; i++ )
		{
			hArrayBan.GetString(i, sBuffer, sizeof(sBuffer));
			if( StrContains(sBuffer, "//") == -1 )
			{
				if ( ExplodeString( sBuffer, ",", sPair, sizeof(sPair), sizeof(sPair[ ]) ) > 3 )
				{
					// remove leading and trailing whitespaces from strings
					TrimString(sPair[0]); TrimString(sPair[1]); TrimString(sPair[2]); TrimString(sPair[3]);
					
					// Regex to detect incorrect ban entries -> these entries are omitted
					if ( sPair[2][0] && hRegexSteamid.Match( sPair[0] ) && hRegexDigitsZero.Match( sPair[1] ) && ( hRegexDigits.Match( sPair[2] ) || hRegexStrDhm.Match( sPair[2] ) ) )
					{
						// Start time
						if (!sPair[1][0]) // no Unix time specified -> start of the ban for the player is the timestamp of the ban file
						{
							iTime = ft;
							bSaveBanFile = true;
						}
						else
							iTime = StringToInt( sPair[1] );
					
						// Ban period
						if ( hRegexDigits.Match( sPair[2] ) ) 
							iMinutes = StringToInt( sPair[2] );
						else
						{
							iDays = ( hRegexStrDhm.GetSubString( 1, buffer, sizeof(buffer), 0 ) ) ? StringToInt ( buffer ) : 0 ;
							iHours = ( hRegexStrDhm.GetSubString( 2, buffer, sizeof(buffer), 0 ) ) ? StringToInt ( buffer ) : 0 ;
							iMinutes = ( hRegexStrDhm.GetSubString( 3, buffer, sizeof(buffer), 0 ) ) ? StringToInt ( buffer ) : 0 ;
							iMinutes = iDays * 1440 + iHours * 60 + iMinutes ;
							bSaveBanFile = true;
						}
						
						if ( iTime + iMinutes * 60 > GetTime() ) // Ban period has not expired or is in the future
						{
							FormatEx( sTime, sizeof(sTime), "%i", iTime );
							hMapBanStart.SetString( sPair[0], sTime, true );
							FormatEx( sTime, sizeof(sTime), "%i", iTime + iMinutes * 60 );
							hMapBanStop.SetString( sPair[0], sTime, true );
							hMapBanSelfnote.SetString( sPair[0], sPair[3], true );
						}
						else
							bSaveBanFile = true; // delete expired ban from file
					}
					else
						bSaveBanFile = true; // delete wrong format ban from file
				}
			}
		}
		if ( bSaveBanFile )
		{
			SaveBanList(); // Rewrites the ban file from memory: Adds a Unix timestamp for start if not specified. Adds information about the start and end of the ban in a human-readable format. Delete expired bans.
			iLastReadInstance = GetFileTime(FILE_BAN, FileTime_LastChange);  // Updates iLastReadInstance to prevent this plugin instance from reading the same ban entries into memory a second time
		}
	}	
}

void SaveBanList( bool bDelExpiredBan = false, const char[] sExpiredBanSteamId = "" )
{

	if ( bDelExpiredBan ) // delete expired ban from file, called by OnClientAuthorized
	{
		static char sBuffer[128];
		ArrayList hArrayBan;
		
		hArrayBan = new ArrayList(ByteCountToCells(128));
		
		ReadFileToArrayList(FILE_BAN, hArrayBan);
		
		Handle hFile = OpenFile(FILE_BAN, "wt");
		
		for( int i = 0; i < hArrayBan.Length; i++ )
		{
			hArrayBan.GetString(i, sBuffer, sizeof(sBuffer));
			if( StrContains(sBuffer, sExpiredBanSteamId) == -1 )
				WriteFileLine( hFile, sBuffer );
		}
		CloseHandle(hFile);
		hFile = OpenFile(FILE_BAN_LASTWRITE, "w"); // Set new timestamp. Prevents writing th same ban entries again.
		CloseHandle(hFile);

		return;
	}

	Handle hFile = OpenFile(FILE_BAN, "wt");
	WriteFileLine(hFile, "//	l4d_votekick: simple temporary bans");
	WriteFileLine(hFile, "//");
	WriteFileLine(hFile, "//	Format:");
	WriteFileLine(hFile, "//	[Steam-ID],[Empty]OR[Unix timestamp],[Minutes]OR[d h m]OR[dhm],[Empty]OR[Self note]");
	WriteFileLine(hFile, "//");
	WriteFileLine(hFile, "//	Explanation:");
	WriteFileLine(hFile, "//	Steam-ID,Begin of ban[If empty -> automatically set to the Unix timestamp of the file time],Duration of the ban in minutes OR dhm-String,Self note");
	WriteFileLine(hFile, "//	l4d_votekick sets the begin of the ban to a Unix timestamp and and automatically adds human readable");
	WriteFileLine(hFile, "//	information to each entry: ', (Begin YYYY-MM-DD HH:MM:SS <-> End YYYY-MM-DD HH:MM:SS)'");
	WriteFileLine(hFile, "//");
	WriteFileLine(hFile, "//	Examples of entries:");
	WriteFileLine(hFile, "//	STEAM_1:0:12345678,,360,				= Begin of ban: now, duration: 360 minutes (6h), self note: none");
	WriteFileLine(hFile, "//	STEAM_1:0:12345678,,360m,				= same result as above");
	WriteFileLine(hFile, "//	STEAM_1:0:12345678,,1440,Dagobert			= Begin of ban: now, duration 1440m (1d), self note: Dagobert");
	WriteFileLine(hFile, "//	STEAM_1:0:12345678,,1d,Dagobert				= same result as above");
	WriteFileLine(hFile, "//	STEAM_1:0:12345678,,24h,Dagobert			= same result as above");
	WriteFileLine(hFile, "//	STEAM_1:1:12345678,1713214999,4320,Donald 		= Begin 2024-04-15 23:03:19, duration: 4320m (3d), self note: Donald");
	WriteFileLine(hFile, "//	STEAM_1:1:12345678,1713214999,2d 24h,Donald 		= same result as above");
	WriteFileLine(hFile, "//	STEAM_1:1:12345678,1713214999,1d 24h 1440m,Donald	= same result as above");
	WriteFileLine(hFile, "//");
	WriteFileLine(hFile, "////////////////////////////////");

	StringMapSnapshot hSnap = hMapBanStart.Snapshot();
	if( hSnap )
	{
		static char sTime[32], sTime2[32], sSteam[64], sSelfnote[32], sStartDate[20], sStopDate[20], sMinutes[10], sBuffer[128];
		static int iTime, iTime2, iMinutes;
		for( int i = 0; i < hSnap.Length; i++ )
		{
			hSnap.GetKey( i, sSteam, sizeof(sSteam) );
			hMapBanStart.GetString( sSteam, sTime, sizeof(sTime) );
			hMapBanStop.GetString( sSteam, sTime2, sizeof(sTime2) );
			hMapBanSelfnote.GetString( sSteam, sSelfnote, sizeof(sSelfnote) );
			iTime = StringToInt( sTime );
			iTime2 = StringToInt( sTime2 );
			FormatTime( sStartDate , sizeof(sStartDate) , "%Y-%m-%d %H:%M:%S", iTime );
			FormatTime( sStopDate , sizeof(sStopDate) , "%Y-%m-%d %H:%M:%S", iTime2 );
			iMinutes = ( iTime2 - iTime ) / 60;
			FormatEx( sMinutes , sizeof( sMinutes ) , "%i", iMinutes );
			FormatEx( sBuffer, sizeof(sBuffer), "%s,%s,%s,%s, (Begin %s <-> End %s)", sSteam, sTime, sMinutes, sSelfnote, sStartDate, sStopDate);
			WriteFileLine( hFile, sBuffer, false );
		}
		delete hSnap;
	}
	CloseHandle(hFile);

	hFile = OpenFile(FILE_BAN_LASTWRITE, "w"); // Set new timestamp. Prevents writing th same ban entries again.
	CloseHandle(hFile);
}

int get_idled_of_bot(int bot)
{
    if(!HasEntProp(bot, Prop_Send, "m_humanSpectatorUserID"))
    {
        return -1;
    }
    return GetClientOfUserId(GetEntProp(bot, Prop_Send, "m_humanSpectatorUserID"));			
}

int get_bot_of_idled(int client)
{
    for(int i = 1; i <= MaxClients; i++)
    {
        if(i != client && IsClientInGame(i) && IsFakeClient(i) && GetClientTeam(i) == 2 && get_idled_of_bot(i) == client)
        {
            return i;
        }
    }
    return 0;
}