/************************************************************************
*************************************************************************
gScramble
Description:
	Automatic scramble and balance script for TF2
*************************************************************************
*************************************************************************

This plugin is free software: you can redistribute 
it and/or modify it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the License, or
later version. 

This plugin is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this plugin.  If not, see <http://www.gnu.org/licenses/>.
*************************************************************************
*************************************************************************

*/
#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

// comment out to disable debug
//#define DEBUG

#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS

/**
comment these 2 lines if you want to compile without them.
*/
#define GAMEME_INCLUDED
#define HLXCE_INCLUDED

#undef REQUIRE_PLUGIN
#include <adminmenu>
#if defined GAMEME_INCLUDED
#include <gameme>
#endif
#if defined HLXCE_INCLUDED
#include <hlxce-sm-api>
#endif
#define REQUIRE_PLUGIN

#define VERSION "3.0.20"
#define TEAM_RED 2
#define TEAM_BLUE 3
#define SCRAMBLE_SOUND  "vo/announcer_am_teamscramble03.wav"
#define EVEN_SOUND		"vo/announcer_am_teamscramble01.wav"

/**
cvar handles
*/
new Handle:cvar_Version				= INVALID_HANDLE,
	Handle:cvar_Steamroll 			= INVALID_HANDLE,
	Handle:cvar_Needed 				= INVALID_HANDLE,
	Handle:cvar_Delay 				= INVALID_HANDLE,
	Handle:cvar_MinPlayers 			= INVALID_HANDLE,
	Handle:cvar_MinAutoPlayers 		= INVALID_HANDLE,
	Handle:cvar_FragRatio 			= INVALID_HANDLE,
	Handle:cvar_AutoScramble 		= INVALID_HANDLE,
	Handle:cvar_VoteEnable 			= INVALID_HANDLE,
	Handle:cvar_WaitScramble 		= INVALID_HANDLE,
	Handle:cvar_ForceTeam 			= INVALID_HANDLE,
	Handle:cvar_ForceBalance 		= INVALID_HANDLE,
	Handle:cvar_SteamrollRatio 		= INVALID_HANDLE,
	Handle:cvar_VoteMode			= INVALID_HANDLE,
	Handle:cvar_PublicNeeded		= INVALID_HANDLE,
	Handle:cvar_FullRoundOnly		= INVALID_HANDLE,
	Handle:cvar_AutoScrambleWinStreak = INVALID_HANDLE,
	Handle:cvar_SortMode			= INVALID_HANDLE,
	Handle:cvar_TeamSwapBlockImmunity = INVALID_HANDLE,
	Handle:cvar_MenuVoteEnd			= INVALID_HANDLE,
	Handle:cvar_AutoscrambleVote	= INVALID_HANDLE,
	Handle:cvar_ScrambleImmuneMode	= INVALID_HANDLE,
	Handle:cvar_Punish				= INVALID_HANDLE,
	Handle:cvar_Balancer			= INVALID_HANDLE,
	Handle:cvar_BalanceTime			= INVALID_HANDLE,
	Handle:cvar_TopProtect			= INVALID_HANDLE,
	Handle:cvar_BalanceLimit		= INVALID_HANDLE,
	Handle:cvar_BalanceImmunity		= INVALID_HANDLE,
	Handle:cvar_Enabled				= INVALID_HANDLE,
	Handle:cvar_RoundTime			= INVALID_HANDLE,
	Handle:cvar_VoteDelaySuccess	= INVALID_HANDLE,
	Handle:cvar_RoundTimeMode		= INVALID_HANDLE,
	Handle:cvar_SetupCharge			= INVALID_HANDLE,
	Handle:cvar_MaxUnbalanceTime	= INVALID_HANDLE,
	Handle:cvar_AvgDiff				= INVALID_HANDLE,
	Handle:cvar_DominationDiff		= INVALID_HANDLE,
	Handle:cvar_Preference			= INVALID_HANDLE,
	Handle:cvar_SetupRestore		= INVALID_HANDLE,
	Handle:cvar_BalanceAdmFlags		= INVALID_HANDLE,
	Handle:cvar_ScrambleAdmFlags	= INVALID_HANDLE,
	Handle:cvar_TeamswapAdmFlags	= INVALID_HANDLE,
	Handle:cvar_Koth				= INVALID_HANDLE,
	Handle:cvar_AutoScrambleRoundCount = INVALID_HANDLE,
	Handle:cvar_ForceReconnect		= INVALID_HANDLE,
	Handle:cvar_TeamworkProtect		= INVALID_HANDLE,
	Handle:cvar_BalanceActionDelay	= INVALID_HANDLE,
	Handle:cvar_ForceBalanceTrigger = INVALID_HANDLE,
	Handle:cvar_NoSequentialScramble = INVALID_HANDLE,
	Handle:cvar_AdminBlockVote		= INVALID_HANDLE,
	Handle:cvar_BuddySystem 		= INVALID_HANDLE,
	Handle:cvar_ImbalancePrevent = INVALID_HANDLE,
	Handle:cvar_MenuIntegrate = INVALID_HANDLE,
	Handle:cvar_Silent 			= INVALID_HANDLE,
	Handle:cvar_VoteCommand		= INVALID_HANDLE,
	Handle:cvar_VoteAd			= INVALID_HANDLE,
	Handle:cvar_BlockJointeam	= INVALID_HANDLE,
	Handle:cvar_TopSwaps			= INVALID_HANDLE,
	Handle:cvar_BalanceTimeLimit = INVALID_HANDLE,
	Handle:cvar_ScrLockTeams		= INVALID_HANDLE,
	Handle:cvar_RandomSelections = INVALID_HANDLE,
	Handle:cvar_PrintScrambleStats = INVALID_HANDLE,
	Handle:cvar_ScrambleDuelImmunity = INVALID_HANDLE,
	Handle:cvar_AbHumanOnly			= INVALID_HANDLE,
	Handle:cvar_LockTeamsFullRound  	= INVALID_HANDLE,
	Handle:cvar_SelectSpectators 		= INVALID_HANDLE,
	Handle:cvar_OneScramblePerRound 		= INVALID_HANDLE;

new Handle:g_hAdminMenu 			= INVALID_HANDLE,
	Handle:g_hScrambleVoteMenu 		= INVALID_HANDLE,
	Handle:g_hScrambleNowPack		= INVALID_HANDLE;
#if defined GAMEME_INCLUDED
	new Handle:g_hGameMeUpdateTimer 	= INVALID_HANDLE;
#endif

/**
timer handles
*/
new Handle:g_hVoteDelayTimer 		= INVALID_HANDLE,
	Handle:g_hScrambleDelay			= INVALID_HANDLE,
	Handle:g_hRoundTimeTick 		= INVALID_HANDLE,
	Handle:g_hForceBalanceTimer		= INVALID_HANDLE,
	Handle:g_hBalanceFlagTimer		= INVALID_HANDLE,
	Handle:g_hCheckTimer 			= INVALID_HANDLE,
	Handle:g_hVoteAdTimer			= INVALID_HANDLE;
	
new Handle:g_cookie_timeBlocked 	= INVALID_HANDLE,
	Handle:g_cookie_teamIndex		= INVALID_HANDLE,
	Handle:g_cookie_serverIp		= INVALID_HANDLE,
	Handle:g_cookie_serverStartTime = INVALID_HANDLE;

new String:g_sVoteCommands[3][65];

new bool:g_bScrambleNextRound = false,	
	bool:g_bVoteAllowed, 			
	bool:g_bScrambleAfterVote,			
	bool:g_bWasFullRound = false,	
	bool:g_bPreGameScramble,
	bool:g_bHooked = false,		
	bool:g_bIsTimer,
	bool:g_bArenaMode,
	bool:g_bKothMode,
	bool:g_bRedCapped,
	bool:g_bBluCapped,
	bool:g_bFullRoundOnly,
	bool:g_bAutoBalance,
	bool:g_bForceTeam,
	bool:g_bForceReconnect,
	bool:g_bAutoScramble,
	bool:g_bUseClientPrefs = false,
	bool:g_bNoSequentialScramble,
	bool:g_bScrambledThisRound,
	bool:g_bBlockDeath,
	bool:g_bUseBuddySystem,
	bool:g_bSilent,
	bool:g_bBlockJointeam,
	bool:g_bNoSpec,
	bool:g_bUseGameMe,
	bool:g_bUseHlxCe,
	bool:g_bVoteCommandCreated,
	bool:g_bTeamsLocked,
	bool:g_bSelectSpectators,
	
	/**
	overrides the auto scramble check
	*/
	bool:g_bScrambleOverride;  // allows for the scramble check to be blocked by admin

new g_iTeamIds[2] = {TEAM_RED, TEAM_BLUE};

new	g_iPluginStartTime,
	g_iMapStartTime,
	g_iRoundStartTime,
	g_iSpawnTime,
	g_iVotes,
	g_iVoters,
	g_iVotesNeeded,
	g_iCompleteRounds,
	g_iRoundTrigger,
	g_iForceTime,
	g_iLastRoundWinningTeam,
	g_iTeamworkProtection,
	g_iNumAdmins;


enum e_TeamInfo
{
	iRedFrags,
	iBluFrags,
	iRedScore,
	iBluScore,
	iRedWins,
	iBluWins,
	bool:bImbalanced
};

enum e_PlayerInfo
{
	iBalanceTime,
	bool:bHasVoted,
	iBlockTime,
	iBlockWarnings,
	iTeamPreference,
	iTeamworkTime,
	bool:bIsVoteAdmin,
	iBuddy,
	iFrags,
	iDeaths,
	bool:bHasFlag,
	iSpecChangeTime,
	iGameMe_Rank,
	iGameMe_Skill,
	iGameMe_gRank,
	iGameMe_gSkill,
	iGameMe_SkillChange,
	iHlxCe_Rank,
	iHlxCe_Skill,
};

enum e_RoundState
{
	newGame,
	preGame,
	bonusRound,
	suddenDeath,
	mapEnding,
	setup,
	normal,
};

enum ScrambleTime
{
	Scramble_Now,
	Scramble_Round,
};

enum e_ImmunityModes
{
	scramble,
	balance,
};

enum e_Protection
{
	none,
	admin,
	uberAndBuildings,
	both
};

enum e_ScrambleModes
{
	invalid,
	random,
	score,
	scoreSqdPerMinute,
	kdRatio,
	topSwap,
	gameMe_Rank,
	gameMe_Skill,
	gameMe_gRank,
	gameMe_gSkill,
	gameMe_SkillChange,
	hlxCe_Rank,
	hlxCe_Skill,
	playerClass,
	randomSort,
}

new e_RoundState:g_RoundState,
	ScrambleTime:g_iDefMode,
	g_aTeams[e_TeamInfo],
	g_aPlayers[MAXPLAYERS + 1][e_PlayerInfo];

new g_iTimerEnt;
new g_iRoundTimer;

#include "gscramble/gscramble_menu_settings.sp"
#include "gscramble/gscramble_autoscramble.sp"
#include "gscramble/gscramble_autobalance.sp"
#include "gscramble/gscramble_tf2_extras.sp"

public Plugin:myinfo = 
{
	name = "[TF2] gScramble (Redux)",
	author = "David",
	description = "Auto Managed team balancer/scrambler.",
	version = VERSION,
	url = "https://forums.alliedmods.net/showthread.php?t=219898"
};

public OnPluginStart()
{
	CheckTranslation();
	cvar_Enabled			= CreateConVar("gs_enabled", 		"1",		"Enable/disable the plugin and all its hooks.", FCVAR_PLUGIN|FCVAR_NOTIFY, true, 0.0, true, 1.0);

	cvar_Balancer		=	CreateConVar("gs_autobalance",	"0",	"Enable/disable the autobalance feature of this plugin.\nUse only if you have the built-in balancer disabled.", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	cvar_TopProtect		= CreateConVar("gs_ab_protect", "5",	"How many of the top players to protect on each team from autobalance.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_BalanceTime	= 	CreateConVar("gs_ab_balancetime",	"5",			"Time in minutes after a client is balanced in which they cannot be balanced again.", FCVAR_PLUGIN);
	cvar_BalanceLimit	=	CreateConVar("gs_ab_unbalancelimit",	"2",	"If one team has this many more players than the other, then consider the teams imbalanced.", FCVAR_PLUGIN);
	cvar_BalanceImmunity =	CreateConVar("gs_ab_immunity",			"0",	"Controls who is immune from auto-balance\n0 = no immunity\n1 = admins\n2 = engies with buildings\n3 = both admins and engies with buildings", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	cvar_MaxUnbalanceTime	= CreateConVar("gs_ab_max_unbalancetime", "30", "Max time the teams are allowed to be unbalanced before a balanced is forced on living players.\n0 = disabled.", FCVAR_PLUGIN, true, 0.0, false); 
	cvar_Preference			= CreateConVar("gs_ab_preference",		"1",	"Allow clients to tell the plugin what team they prefer.  When an autobalance starts, if the client prefers the team, it overrides any immunity check.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_BalanceActionDelay = CreateConVar("gs_ab_actiondelay",		"5", 	"Time, in seconds after an imbalance is detected in which an imbalance is flagged, and possible swapping can occur", FCVAR_PLUGIN, true, 0.0, false);
	cvar_ForceBalanceTrigger = CreateConVar("gs_ab_forcetrigger",	"4",	"If teams become imbalanced by this many players, auto-force a balance", FCVAR_PLUGIN, true, 0.0, false);
	cvar_BalanceTimeLimit	= 	CreateConVar("gs_ab_timelimit", "0", 		"If there are this many seconds, or less, remaining in a round, stop auto-balacing", FCVAR_PLUGIN, true, 0.0, false);
	cvar_AbHumanOnly = CreateConVar("gs_ab_humanonly", "0", "Only auto-balance human players", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvar_ImbalancePrevent	= CreateConVar("gs_prevent_spec_imbalance", "0", "If set, block changes to spectate that result in a team imbalance", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_BuddySystem		= CreateConVar("gs_use_buddy_system", "0", "Allow players to choose buddies to try to keep them on the same team", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SelectSpectators = CreateConVar("gs_Select_spectators", "60", "During a scramble or force-balance, select spectators who have change to spectator in less time in seconds than this setting, 0 disables", FCVAR_PLUGIN, true, 0.0, false);
	
	cvar_TeamworkProtect	= CreateConVar("gs_teamwork_protect", "60",		"Time in seconds to protect a client from autobalance if they have recently captured a point, defended/touched intelligence, or assisted in or destroying an enemy sentry. 0 = disabled", FCVAR_PLUGIN, true, 0.0, false);
	cvar_ForceBalance 		= CreateConVar("gs_force_balance",	"0", 		"Force a balance between each round. (If you use a custom team balance plugin that doesn't do this already, or you have the default one disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_TeamSwapBlockImmunity = CreateConVar("gs_teamswitch_immune",	"1",	"Sets if admins (root and ban) are immune from team swap blocking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ScrambleImmuneMode = CreateConVar("gs_scramble_immune", "0",		"Sets if admins and people with uber and engie buildings are immune from being scrambled.\n0 = no immunity\n1 = just admins\n2 = charged medics + engineers with buildings\n3 = admins + charged medics and engineers with buildings.", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	cvar_SetupRestore		= CreateConVar("gs_setup_reset",	"1", 		"If a scramble happens during setup, restore the setup timer to its starting value", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ScrambleAdmFlags	= CreateConVar("gs_flags_scramble", "ab",		"Admin flags for scramble protection (if enabled)", FCVAR_PLUGIN);
	cvar_BalanceAdmFlags	= CreateConVar("gs_flags_balance",	"ab",		"Admin flags for balance protection (if enabled)", FCVAR_PLUGIN);
	cvar_TeamswapAdmFlags	= CreateConVar("gs_flags_teamswap", "bf",		"Admin flags for team swap block protection (if enabled)", FCVAR_PLUGIN);
	
	cvar_NoSequentialScramble = CreateConVar("gs_no_sequential_scramble", "1", "If set, then it will block auto-scrambling from happening two rounds in a row. Also stops scrambles from being started if one has occured already during a round.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_WaitScramble 		= CreateConVar("gs_prescramble", 	"0", 		"If enabled, teams will scramble at the end of the 'waiting for players' period", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_RoundTime			= CreateConVar("gs_public_roundtime", 	"0",		"If this many seconds or less is left on the round timer, then block public voting.\n0 = disabled.\nConfigure this with the roundtime_blockmode cvar.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_RoundTimeMode		= CreateConVar("gs_public_roundtime_blockmode", "0", "How to handle the final public vote if there are less that X seconds left in the round, specified by the roundtime cvar.\n0 = block the final vote.\n1 = Allow the vote and force a scramble for the next round regardless of any other setting.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_VoteMode			= CreateConVar("gs_public_votemode",	"0",		"For public chat votes\n0 = if enough triggers, enable scramble for next round.\n1 = if enough triggers, start menu vote to start a scramble\n2 = scramble teams right after the last trigger.", FCVAR_PLUGIN, true, 0.0, true, 2.0);
	cvar_PublicNeeded		= CreateConVar("gs_public_triggers", 	"0.60",		"Percentage of people needing to trigger a scramble in chat.  If using votemode 1, I suggest you set this lower than 50%", FCVAR_PLUGIN, true, 0.05, true, 1.0);
	cvar_VoteEnable 		= CreateConVar("gs_public_votes",	"1", 		"Enable/disable public voting", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Punish				= CreateConVar("gs_punish_stackers", "0", 		"Punish clients trying to restack teams during the team-switch block period by adding time to when they are able to team swap again", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SortMode			= CreateConVar("gs_sort_mode",		"1",		
		"Player scramble sort mode.\n1 = Random\n2 = Player Score\n3 = Player Score Per Minute.\n4 = Kill-Death Ratio\n5 = Swap the top players on each team.\n6 = GameMe rank\n7 = GameMe skill\n8 Global GameMe rank\n9 = Global GameMe Skill\n10 = GameMe session skill change.\n11 = HlxCe Rank.\n12 = HlxCe Skill\n13 = player classes.\n14. Random mode\nThis controls how players get swapped during a scramble.", FCVAR_PLUGIN, true, 1.0, true, 14.0);
	cvar_RandomSelections = CreateConVar("gs_random_selections", "0.55", "Percentage of players to swap during a random scramble", FCVAR_PLUGIN, true, 0.1, true, 0.80);
	cvar_TopSwaps			= CreateConVar("gs_top_swaps",		"5",		"Number of top players the top-swap scramble will switch", FCVAR_PLUGIN, true, 1.0, false);
	
	cvar_SetupCharge		= CreateConVar("gs_setup_fill_ubers",		"0",		"If a scramble-now happens during setup time, fill up any medic's uber-charge.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ForceTeam 			= CreateConVar("gs_changeblocktime",	"120", 		"Time after being swapped by a scramble where players aren't allowed to change teams", FCVAR_PLUGIN, true, 0.0, false);
	cvar_ForceReconnect		= CreateConVar("gs_check_reconnect",	"1",		"The plugin will check if people are reconnecting to the server to avoid being forced on a team.  Requires clientprefs", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MenuVoteEnd		= CreateConVar("gs_menu_votebehavior",	"0",		"0 =will trigger scramble for round end.\n1 = will scramble teams after vote.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Needed 			= CreateConVar("gs_menu_votesneeded", 	"0.60", 	"Percentage of votes for the menu vote scramble needed.", FCVAR_PLUGIN, true, 0.05, true, 1.0);
	cvar_Delay 				= CreateConVar("gs_vote_delay", 		"60.0", 	"Time in seconds after the map has started and after a failed vote in which players can votescramble.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_VoteDelaySuccess	= CreateConVar("gs_vote_delay2",		"300",		"Time in seconds after a successful scramble in which players can vote again.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_AdminBlockVote		= CreateConVar("gs_vote_adminblock",		"0",		"If set, publicly started votes are disabled when an admin is preset.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvar_MinPlayers 		= CreateConVar("gs_vote_minplayers",	"6", 		"Minimum poeple connected before any voting will work.", FCVAR_PLUGIN, true, 0.0, false);
	
	cvar_AutoScrambleWinStreak			= CreateConVar("gs_winstreak",		"0", 		"If set, it will scramble after a team wins X full rounds in a row", FCVAR_PLUGIN, true, 0.0, false);
	cvar_AutoScrambleRoundCount				= CreateConVar("gs_scramblerounds", "0",		"If set, it will scramble every X full round", FCVAR_PLUGIN, true, 0.0, false, 1.0);
	
	cvar_AutoScramble		= CreateConVar("gs_autoscramble",	"1", 		"Enables/disables the automatic scrambling.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_FullRoundOnly 		= CreateConVar("gs_as_fullroundonly",	"0",		"Auto-scramble only after a full round has completed.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AutoscrambleVote	= CreateConVar("gs_as_vote",		"0",		"Starts a scramble vote instead of scrambling at the end of a round", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MinAutoPlayers 	= CreateConVar("gs_as_minplayers", "12", 		"Minimum people connected before automatic scrambles are possible", FCVAR_PLUGIN, true, 0.0, false);
	cvar_FragRatio 			= CreateConVar("gs_as_hfragratio", 		"2.0", 		"If a teams wins with a frag ratio greater than or equal to this setting, trigger a scramble.\nSetting this to 0 disables.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_Steamroll 			= CreateConVar("gs_as_wintimelimit", 	"120.0", 	"If a team wins in less time, in seconds, than this, and has a frag ratio greater than specified: perform an auto scramble.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_SteamrollRatio 	= CreateConVar("gs_as_wintimeratio", 	"1.5", 		"Lower kill ratio for teams that win in less than the wintime_limit.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_AvgDiff			= CreateConVar("gs_as_playerscore_avgdiff", "10.0",	"If the average score difference for all players on each team is greater than this, then trigger a scramble.\n0 = skips this check", FCVAR_PLUGIN, true, 0.0, false);
	cvar_DominationDiff		= CreateConVar("gs_as_domination_diff",		"10",	"If a team has this many more dominations than the other team, then trigger a scramble.\n0 = skips this check", FCVAR_PLUGIN, true, 0.0, false);
	cvar_Koth				= CreateConVar("gs_as_koth_pointcheck",		"0",	"If enabled, trigger a scramble if a team never captures the point in koth mode.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ScrLockTeams		= CreateConVar("gs_as_lockteamsbefore", "1", "If enabled, lock the teams between the scramble check and the actual scramble", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_PrintScrambleStats = CreateConVar("gs_as_print_stats", "1", "If enabled, print the scramble stats", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ScrambleDuelImmunity = CreateConVar("gs_as_dueling_immunity", "0", "If set it 1, grant immunity to dueling players during a scramble", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_LockTeamsFullRound	= CreateConVar("gs_as_lockteamsafter", "0", "If enabled, block team changes after a scramble for the entire next round", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvar_Silent 		=	CreateConVar("gs_silent", "0", 	"Disable most commen chat messages", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_VoteCommand =	CreateConVar("gs_vote_trigger",	"votescramble", "The trigger for starting a vote-scramble", FCVAR_PLUGIN);
	cvar_VoteAd		= CreateConVar("gs_vote_advertise", "500", "How often, in seconds, to advertise the vote command trigger.\n0 disables this", FCVAR_PLUGIN, true, 0.0, false);
	cvar_MenuIntegrate = CreateConVar("gs_admin_menu",			"1",  "Enable or disable the automatic integration into the admin menu", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvar_BlockJointeam = CreateConVar("gs_block_jointeam",		"0", "If enabled, will block the use of the jointeam and spectate commands and force mp_forceautoteam enabled if it is not enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvar_OneScramblePerRound =  CreateConVar("gs_onescrambleperround", "1", "If enabled, will only allow only allow one scramble per round", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvar_Version			= CreateConVar("gscramble_version", VERSION, "Gscramble version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	RegCommands();
	
	/**
	convar variables we need to know the new values of
	*/
	HookConVarChange(cvar_ForceReconnect, handler_ConVarChange);
	HookConVarChange(cvar_ForceTeam, handler_ConVarChange);
	HookConVarChange(cvar_FullRoundOnly, handler_ConVarChange);	
	HookConVarChange(cvar_Enabled, handler_ConVarChange);
	HookConVarChange(cvar_AutoScramble, handler_ConVarChange);
	HookConVarChange(cvar_VoteMode, handler_ConVarChange);
	HookConVarChange(cvar_Balancer, handler_ConVarChange);
	HookConVarChange(cvar_NoSequentialScramble, handler_ConVarChange);
	HookConVarChange(cvar_SortMode, handler_ConVarChange);
	
	AutoExecConfig(true, "plugin.gscramble");	
	LoadTranslations("common.phrases");
	LoadTranslations("gscramble.phrases");
		
	CheckExtensions();	
		
	g_iVoters = GetClientCount(false);
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
	g_bVoteCommandCreated = false;
	g_iPluginStartTime = GetTime();

}

public OnAllPluginsLoaded()
{
	new Handle:gTopMenu;
	
	if (LibraryExists("adminmenu") && ((gTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{	
		OnAdminMenuReady(gTopMenu);
	}
}

stock CheckTranslation()
{
	decl String:sPath[257];
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/gscramble.phrases.txt");
	
	if (!FileExists(sPath))
	{
		SetFailState("Translation file 'gscramble.phrases.txt' is missing. Please download the zip file at 'http://forums.alliedmods.net/showthread.php?t=1983244'");
	}
}

RegCommands()
{
	RegAdminCmd("sm_scrambleround", cmd_Scramble, ADMFLAG_GENERIC, "Scrambles at the end of the bonus round");
	RegAdminCmd("sm_cancel", 		cmd_Cancel, ADMFLAG_GENERIC, "Cancels any active scramble, and scramble timer.");
	RegAdminCmd("sm_resetvotes",	cmd_ResetVotes, ADMFLAG_GENERIC, "Resets all public votes.");
	RegAdminCmd("sm_scramble", 		cmd_Scramble_Now, ADMFLAG_GENERIC, "sm_scramble <delay> <respawn> <mode>");
	RegAdminCmd("sm_forcebalance",	cmd_Balance, ADMFLAG_GENERIC, "Forces a team balance if an imbalance exists.");
	RegAdminCmd("sm_scramblevote",	cmd_Vote, ADMFLAG_GENERIC, "Start a vote. sm_scramblevote <now/end>");
	
	AddCommandListener(CMD_Listener, "say_team");
	AddCommandListener(CMD_Listener, "jointeam");
	AddCommandListener(CMD_Listener, "spectate");
	
	RegConsoleCmd("sm_preference", cmd_Preference);
	RegConsoleCmd("sm_addbuddy",   cmd_AddBuddy);	
}

public Action:CMD_Listener(client, const String:command[], argc)
{
	if (StrEqual(command, "jointeam", false) || StrEqual(command, "spectate", false))
	{
		if (client && !IsFakeClient(client))
		{	
			if (g_bBlockJointeam)
			{
				if (GetConVarBool(cvar_TeamSwapBlockImmunity))
				{				
					new String:flags[32];
					GetConVarString(cvar_TeamswapAdmFlags, flags, sizeof(flags));
					if (IsAdmin(client, flags))
					{
						return Plugin_Continue;
					}
				}
				if (TeamsUnbalanced(false)) //allow clients to change teams during imbalances
				{
					return Plugin_Continue;
				}
				if (GetClientTeam(client) >= 2)
				{
					PrintToChat(client, "\x01\x04[SM]\x01 %t", "BlockJointeam");
					LogAction(-1, client, "\"%L\" is being blocked from using the %s command due to setting", client, command);
					return Plugin_Handled;				
				}			
			}
			if (IsValidTeam(client))
			{
				new String:sArg[9];
				if (argc)
				{
					GetCmdArgString(sArg, sizeof(sArg));
				}
				if (IsBlocked(client))
				{
					if (StrEqual(sArg, "blue", false) || StrEqual(sArg, "red", false) || StringToInt(sArg) >= 2)
					{
						if (TeamsUnbalanced(false)) //allow clients to change teams during imbalances
						{
							return Plugin_Continue;
						}
					}
					HandleStacker(client);
					return Plugin_Handled;
					
				}				
				
				if (StrEqual(command, "spectate", false) || StringToInt(sArg) < 2 || StrContains(sArg, "spec", false) != -1)
				{
					if (GetConVarBool(cvar_ImbalancePrevent))
					{
						if (CheckSpecChange(client) || IsBlocked(client))
						{
							HandleStacker(client);
							return Plugin_Handled;
						}
					}
					else if (g_bNoSpec)
					{
						HandleStacker(client);
						return Plugin_Handled;
					}
					else if (g_bSelectSpectators)
					{
						g_aPlayers[client][iSpecChangeTime] = GetTime();
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

CheckExtensions()
{
	new String:sMod[14];
	GetGameFolderName(sMod, 14);
	
	if (!StrEqual(sMod, "TF", false))
	{
		SetFailState("This plugin only works on Team Fortress 2");
	}
	
	new String:sExtError[256];
	new iExtStatus;
	
	//check to see if client prefs is loaded and configured properly				
	iExtStatus = GetExtensionFileStatus("clientprefs.ext", sExtError, sizeof(sExtError));
	switch (iExtStatus)
	{
		case -1:
		{
			LogAction(-1, 0, "Optional extension clientprefs failed to load.");
		}
		case 0:
		{
			LogAction(-1, 0, "Optional extension clientprefs is loaded with errors.");
			LogAction(-1, 0, "Status reported was [%s].", sExtError);	
		}
		case -2:
		{
			LogAction(-1, 0, "Optional extension clientprefs is missing.");
		}
		case 1:
		{
			if (SQL_CheckConfig("clientprefs"))
			{
				g_bUseClientPrefs = true;
			}
			else
			{
				LogAction(-1, 0, "Optional extension clientprefs found, but no database entry is present");
			}
		}
	}	
	
	//now that we have checked for the clientprefs ext, see if we can use its natives
	if (g_bUseClientPrefs)
	{
		g_cookie_timeBlocked = RegClientCookie("time blocked", "time player was blocked", CookieAccess_Private);
		g_cookie_serverIp	= RegClientCookie("server_id", "ip of the server", CookieAccess_Private);
		g_cookie_teamIndex = RegClientCookie("team index", "index of the player's team", CookieAccess_Private);
		g_cookie_serverStartTime = RegClientCookie("start time", "time the plugin was loaded", CookieAccess_Private);
	}
}

public Action:cmd_AddBuddy(client, args)
{
	if (!g_bUseBuddySystem)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "BuddyDisabledError");
		
		return Plugin_Handled;
	}
	if (args == 1)
	{
		new String:target_name[MAX_NAME_LENGTH+1], String:arg[32], target_list[1], bool:tn_is_ml;
		GetCmdArgString(arg, sizeof(arg));
		if (ProcessTargetString(
			arg,
			client, 
			target_list, 
			MAXPLAYERS, 
			COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_MULTI,
			target_name,
			sizeof(target_name),
			tn_is_ml) == 1)
			AddBuddy(client, target_list[0]);
		else
		{
			ReplyToTargetError(client, COMMAND_TARGET_NONE);
		}
	}
	else if (!args)
	{
		ShowBuddyMenu(client);
	}
	else
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "BuddyArgError");
	}
	
	return Plugin_Handled;
}

public Action:cmd_Preference(client, args)
{
	if (!g_bHooked)
	{
	
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "EnableReply");
		return Plugin_Handled;
	}	
	
	if (!GetConVarBool(cvar_Preference))
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "PrefDisabled");
		
		return Plugin_Handled;
	}
	
	if (!args)
	{
		if (g_aPlayers[client][iTeamPreference] != 0)
		{
			if (g_aPlayers[client][iTeamPreference] == TEAM_RED)
			{
				ReplyToCommand(client, "RED");
			}
			else
			{
				ReplyToCommand(client, "BLU");
			}
			
			return Plugin_Handled;		
		}
	}
	
	decl String:Team[10];
	GetCmdArgString(Team, sizeof(Team));
	
	if (StrContains(Team, "red", false) != -1)
	{
		g_aPlayers[client][iTeamPreference] = TEAM_RED;
		ReplyToCommand(client, "RED");
		return Plugin_Handled;
	}
	
	if (StrContains(Team, "blu", false) != -1)
	{
		g_aPlayers[client][iTeamPreference] = TEAM_BLUE;
		ReplyToCommand(client, "BLU");
		return Plugin_Handled;
	}
	
	if (StrContains(Team, "clear", false) != -1)
	{
		g_aPlayers[client][iTeamPreference] = 0;
		ReplyToCommand(client, "CLEARED");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "Usage: sm_preference <TEAM|CLEAR>");
	return Plugin_Handled;
}

public OnPluginEnd() 
{
	if (g_bAutoBalance)
	{
		ServerCommand("mp_autoteambalance 1");
	}
}


public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	//if late, assume state = setup and check the timer ent
	if (late)
	{
		CreateTimer(1.0, Timer_load);
	}
		
	CreateNative("GS_IsClientTeamChangeBlocked", Native_GS_IsBlocked);
	CreateNative("TF2_GetRoundTimeLeft", TF2_GetRoundTimeLeft);
	MarkNativeAsOptional("HLXCE_GetPlayerData");
	MarkNativeAsOptional("QueryGameMEStats");
	MarkNativeAsOptional("RegClientCookie");
	MarkNativeAsOptional("SetClientCookie");
	MarkNativeAsOptional("GetClientCookie");
	RegPluginLibrary("gscramble");
	
	return APLRes_Success;
}

public Action:Timer_load(Handle:timer)
{
	g_RoundState = setup;
	CreateTimer(1.0, Timer_GetTime);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			g_iVoters++;
		}
	}
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
}

bool:IsBlocked(client)
{
	if (!g_bForceTeam)
	{
		return false;
	}
	
	if (g_bTeamsLocked)
	{
		new String:flags[32];
		GetConVarString(cvar_TeamswapAdmFlags, flags, sizeof(flags));
		
		if (IsAdmin(client, flags))
		{
			return false;
		}
		
		return true;
	}
	
	if (g_aPlayers[client][iBlockTime] > GetTime())
	{
		return true;
	}
	
	return false;
}

public Native_GS_IsBlocked(Handle:plugin, numParams)
{
	new client = GetNativeCell(1), initiator = GetNativeCell(2);
	
	if (!client || client > MaxClients || !IsClientInGame(client))
	{
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index");
	}
	
	if (IsBlocked(client))
	{
		if (initiator)
		{
			HandleStacker(client);
		}
		
		return true;
	}
	
	return false;
}

stock CreateVoteCommand()
{
	if (!g_bVoteCommandCreated)
	{
		decl String:sCommand[256];		
		GetConVarString(cvar_VoteCommand, sCommand, sizeof(sCommand));
		ExplodeString(sCommand, ",", g_sVoteCommands, 3, sizeof(g_sVoteCommands[]));
		
		for (new i; i < 3; i++)
		{
			if (strlen(g_sVoteCommands[i]) > 2)
			{
				g_bVoteCommandCreated = true;
				RegConsoleCmd(g_sVoteCommands[i], CMD_VoteTrigger);
			}
		}		
	}
}

public Action:CMD_VoteTrigger(client, args)
{
	if (!IsFakeClient(client))
	{
		AttemptScrambleVote(client);
	}
	
	return Plugin_Handled;
}

public OnConfigsExecuted()
{
	g_bUseGameMe = false;
	g_bUseHlxCe = false;
	
	if (GetFeatureStatus(FeatureType_Native, "HLXCE_GetPlayerData") == FeatureStatus_Available)
	{
		g_bUseHlxCe = true;
		
		LogMessage("HlxCe Available");
	}
	else
	{
		LogMessage("HlxCe Unavailable");
	}
	
	CreateVoteCommand();
	
	if (GetFeatureStatus(FeatureType_Native, "QueryGameMEStats") == FeatureStatus_Available)
	{
		g_bUseGameMe = true;
		
		LogMessage("GameMe Available");
	}
	else
	{
		g_bUseGameMe = false;
		
		LogMessage("GameMe Unavailavble");
	}
	
	decl String:sMapName[32];
	new bool:bAuto = false;
	
	GetCurrentMap(sMapName, 32);
	SetConVarString(cvar_Version, VERSION);

	//load load global values
	g_bSelectSpectators = GetConVarBool(cvar_SelectSpectators);
	g_bSilent = GetConVarBool(cvar_Silent);
	g_bAutoBalance = GetConVarBool(cvar_Balancer);
	g_bFullRoundOnly = GetConVarBool(cvar_FullRoundOnly);
	g_bForceTeam = GetConVarBool(cvar_ForceTeam);
	g_iForceTime = GetConVarInt(cvar_ForceTeam);
	g_iTeamworkProtection = GetConVarInt(cvar_TeamworkProtect);
	g_bAutoScramble = GetConVarBool(cvar_AutoScramble);
	GetConVarInt(cvar_MenuVoteEnd) ? (g_iDefMode = Scramble_Now) : (g_iDefMode = Scramble_Round);
	g_bNoSequentialScramble = GetConVarBool(cvar_NoSequentialScramble);
	g_bUseBuddySystem = GetConVarBool(cvar_BuddySystem);
	
	if (g_bUseClientPrefs)
	{
		g_bForceReconnect = GetConVarBool(cvar_ForceReconnect);
	}
	
	if (GetConVarBool(cvar_Enabled))
	{
		if (g_bAutoBalance)
		{
			if (GetConVarBool(FindConVar("mp_autoteambalance")))
			{
				LogAction(-1, 0, "set mp_autoteambalance to false");
				
				SetConVarBool(FindConVar("mp_autoteambalance"), false);
			}
		}
		if (!g_bHooked)
		{
			hook();
		}
	}
	else if (g_bHooked)
	{
		unHook();
	}
		
	g_bKothMode = false; 
	g_bArenaMode = false;
	
	if (GetConVarBool(cvar_AutoScramble) || GetConVarBool(cvar_AutoScrambleWinStreak))
	{
		bAuto = true;
	}
	
	if (GetConVarBool(cvar_AutoScrambleRoundCount))
	{
		bAuto = true;
		g_iRoundTrigger = GetConVarInt(cvar_AutoScrambleRoundCount);
	}
	
	
	//shut off tf2's built in auto-scramble
	//if gscramble's auto modes are enabled.
	if (bAuto && GetConVarBool(FindConVar("mp_scrambleteams_auto")))
	{
		SetConVarBool(FindConVar("mp_scrambleteams_auto"), false);
		LogMessage("Setting mp_scrambleteams_auto false");
	}
	
	if (GetConVarBool(cvar_Koth) && strncmp(sMapName, "koth_", 5, false) == 0)
	{
		g_bRedCapped = false;
		g_bBluCapped = false;
		g_bKothMode = true;
	}
	else if (strncmp(sMapName, "arena_", 6, false) == 0)
	{
		if (GetConVarBool(FindConVar("tf_arena_use_queue")))
		{
			if (g_bHooked)
			{
				LogAction(-1, 0, "Unhooking events since it's arena, and tf_arena_use_queue is enabled");
				
				unHook();
			}
			
			g_bArenaMode = true;
		}
	}
	
	if (!GetConVarBool(cvar_MenuIntegrate))
	{
		if (g_hAdminMenu != INVALID_HANDLE && g_Category != INVALID_TOPMENUOBJECT)
		{			
			RemoveFromTopMenu(g_hAdminMenu, g_Category);
			g_hAdminMenu = INVALID_HANDLE;
			g_Category = INVALID_TOPMENUOBJECT;
		}
	}
	
	if (g_hVoteAdTimer != INVALID_HANDLE)
	{
		KillTimer(g_hVoteAdTimer);
		g_hVoteAdTimer = INVALID_HANDLE;
	}
	
	new Float:fAd = GetConVarFloat(cvar_VoteAd);
	
	if (fAd > 0.0)
	{
		g_hVoteAdTimer = CreateTimer(fAd, Timer_VoteAd, _, TIMER_REPEAT);
	}
	
	if (GetConVarBool(cvar_BlockJointeam))
	{
		g_bBlockJointeam = true;
		SetConVarBool(FindConVar("mp_forceautoteam"), true);
	}
	else
	{
		g_bBlockJointeam = false;
	}
	
	#if defined GAMEME_INCLUDED
	if (g_bUseGameMe && e_ScrambleModes:GetConVarInt(cvar_SortMode) == gameMe_SkillChange)
	{
		StartSkillUpdates();
	}
	else
	{
		StopSkillUpdates();
	}
	#endif
}

public Action:Timer_VoteAd(Handle:timer)
{
	decl String:sVotes[120];
	if (strlen(g_sVoteCommands[0]))
	{
		Format(sVotes, sizeof(sVotes), "!%s", g_sVoteCommands[0]);
	}
	
	if (strlen(g_sVoteCommands[1]))
	{
		Format(sVotes, sizeof(sVotes), "%s, !%s", sVotes, g_sVoteCommands[1]);
	}
	
	if (strlen(g_sVoteCommands[2]))
	{
		Format(sVotes, sizeof(sVotes), "%s, or !%s", sVotes, g_sVoteCommands[2]);
	}
	
	if (strlen(sVotes))
	{
		PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteAd", sVotes);
	}
	
	return Plugin_Continue;
}

public handler_ConVarChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	new iNewValue = StringToInt(newValue);
	if (convar == cvar_Enabled)
	{
		new bool:teamBalance;
		
		if (!iNewValue && g_bHooked)
		{
			teamBalance = true;
			unHook();
		}
		else if (!g_bHooked)
		{
			teamBalance = false;
			hook();
		}
		
		if (GetConVarBool(cvar_Balancer))
		{		
			SetConVarBool(FindConVar("mp_autoteambalance"), teamBalance);	
			LogAction(0, -1, "set conVar mp_autoteambalance to %i.", teamBalance);
		}
	}
	
	#if defined GAMEME_INCLUDED
	if (convar == cvar_SortMode)
	{
		if (g_bUseGameMe && e_ScrambleModes:iNewValue == gameMe_SkillChange)
		{
			StartSkillUpdates();
		}
		else
		{
			StopSkillUpdates();
		}
	}
	#endif	
	
	if (convar == cvar_FullRoundOnly)
	{
		iNewValue == 1 ? (g_bFullRoundOnly = true) : (g_bFullRoundOnly = false);
	}
	
	if (convar == cvar_Balancer)
	{
		iNewValue == 1 ? (g_bAutoBalance = true) : (g_bAutoBalance = false);
	}
		
	if (convar == cvar_ForceTeam)
	{
		g_iForceTime = iNewValue;
		iNewValue == 1 ? (g_bForceTeam = true) : (g_bForceTeam = false);
	}
		
	if (convar == cvar_ForceReconnect && g_bUseClientPrefs)
	{
		iNewValue == 1 ? (g_bForceReconnect = true) : (g_bForceReconnect = false);
	}
	
	if (convar == cvar_TeamworkProtect)
	{
		g_iTeamworkProtection = iNewValue;
	}
	
	if (convar == cvar_AutoScramble)
	{
		iNewValue == 1  ? (g_bAutoScramble = true):(g_bAutoScramble = false);
	}
	
	if (convar == cvar_MenuVoteEnd)
	{
		iNewValue == 1 ? (g_iDefMode = Scramble_Now) : (g_iDefMode = Scramble_Round);
	}
	
	if (convar == cvar_NoSequentialScramble)
	{
		g_bNoSequentialScramble = iNewValue?true:false;
	}
}

#if defined GAMEME_INCLUDED
stock StartSkillUpdates()
{
	if (g_hGameMeUpdateTimer != INVALID_HANDLE)
	{
		return;
	}
	
	LogMessage("Starting gameMe data update timer");
	g_hGameMeUpdateTimer = CreateTimer(60.0, Timer_GameMeUpdater, _, TIMER_REPEAT);
	UpdateSessionSkill();
}

public Action:Timer_GameMeUpdater(Handle:timer)
{
	UpdateSessionSkill();
	return Plugin_Continue;
}

stock StopSkillUpdates()
{
	if (g_hGameMeUpdateTimer != INVALID_HANDLE)
	{
		KillTimer(g_hGameMeUpdateTimer);
		g_hGameMeUpdateTimer = INVALID_HANDLE;
	}
}


stock UpdateSessionSkill()
{
	if (GetFeatureStatus(FeatureType_Native, "QueryGameMEStats") == FeatureStatus_Available)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && !IsFakeClient(i))
			{
				QueryGameMEStats("playerinfo", i, QuerygameMEStatsCallback, 0);
			}
		}
	}
	else 
	{
		g_bUseGameMe = false;
	}
}
#endif

hook()
{
	LogAction(0, -1, "Hooking events.");
	HookEvent("teamplay_round_start", 		Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	HookEvent("teamplay_round_win", 		Event_RoundWin, EventHookMode_Post);
	HookEvent("teamplay_setup_finished", 	hook_Setup, EventHookMode_PostNoCopy);
	HookEvent("player_death", 				Event_PlayerDeath_Pre, EventHookMode_Pre);
	HookEvent("game_start", 				hook_Event_GameStart);
	HookEvent("teamplay_restart_round", 	hook_Event_TFRestartRound);
	HookEvent("player_team",				Event_PlayerTeam_Pre, EventHookMode_Pre);
	HookEvent("teamplay_round_stalemate",	hook_RoundStalemate, EventHookMode_PostNoCopy);
	HookEvent("teamplay_point_captured", 	hook_PointCaptured, EventHookMode_Post);
	HookEvent("object_destroyed", 			hook_ObjectDestroyed, EventHookMode_Post);
	HookEvent("teamplay_flag_event",		hook_FlagEvent, EventHookMode_Post);
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook_Class, false);
	AddGameLogHook(LogHook);
	
	HookEvent("teamplay_game_over", hook_GameEnd, EventHookMode_PostNoCopy);
	HookEvent("player_chargedeployed", hook_UberDeploy, EventHookMode_Post);
	HookEvent("player_sapped_object", hook_Sapper, EventHookMode_Post);
	HookEvent("medic_death", hook_MedicDeath, EventHookMode_Post);
	HookEvent("player_escort_score", hook_EscortScore, EventHookMode_Post);	
	HookEvent("teamplay_timer_time_added", TimerUpdateAdd, EventHookMode_Post);
	g_bHooked = true;
}

public Action:LogHook(const String:message[])
{
	if (g_bBlockDeath)
	{
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

unHook()
{
	LogAction(0, -1, "Unhooking events");
	UnhookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	UnhookEvent("teamplay_round_start", 		Event_RoundStart, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_round_win", 		Event_RoundWin, EventHookMode_Post);
	UnhookEvent("teamplay_setup_finished", 	hook_Setup, EventHookMode_PostNoCopy);
	UnhookEvent("player_death", 				Event_PlayerDeath_Pre, EventHookMode_Pre);
	UnhookEvent("game_start", 				hook_Event_GameStart);
	UnhookEvent("teamplay_restart_round", 	hook_Event_TFRestartRound);
	UnhookEvent("player_team",				Event_PlayerTeam_Pre, EventHookMode_Pre);
	UnhookEvent("teamplay_round_stalemate",	hook_RoundStalemate, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_point_captured", 	hook_PointCaptured, EventHookMode_Post);
	UnhookEvent("teamplay_game_over", hook_GameEnd, EventHookMode_PostNoCopy);
	UnhookEvent("object_destroyed", hook_ObjectDestroyed, EventHookMode_Post);
	UnhookEvent("teamplay_flag_event",		hook_FlagEvent, EventHookMode_Post);
	UnhookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook_Class, false);
	UnhookEvent("player_chargedeployed", hook_UberDeploy, EventHookMode_Post);
	UnhookEvent("player_sapped_object", hook_Sapper, EventHookMode_Post);
	UnhookEvent("medic_death", hook_MedicDeath, EventHookMode_Post);
	UnhookEvent("player_escort_score", hook_EscortScore, EventHookMode_Post);
	UnhookEvent("teamplay_timer_time_added", TimerUpdateAdd, EventHookMode_Post);

	g_bHooked = false;
}

/**
add protection to those killing fully charged medics
*/
public hook_MedicDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iTeamworkProtection && g_RoundState == normal && GetEventBool(event, "charged"))
	{
		AddTeamworkTime(GetClientOfUserId(GetEventInt(event, "userid")));
	}
}

public hook_EscortScore(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iTeamworkProtection && g_RoundState == normal)
	{
		AddTeamworkTime(GetEventInt(event, "player"));
	}
}
	
/**
add protection to those sapping buildings
*/
public hook_Sapper(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iTeamworkProtection && g_RoundState == normal)
	{
		AddTeamworkTime(GetClientOfUserId(GetEventInt(event, "userid")));
	}
}

/**
add protection to those deploying uber
*/	
public hook_UberDeploy(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iTeamworkProtection && g_RoundState == normal)
	{
		new medic = GetClientOfUserId(GetEventInt(event, "userid")), target = GetClientOfUserId(GetEventInt(event, "targetid"));
		
		AddTeamworkTime(medic);
		AddTeamworkTime(target);
	}
}

public hook_ObjectDestroyed(Handle:event, const String:name[], bool:dontBroadcast)
{
	/**
	adds teamwork protection if clients destroy a sentry
	*/
	if (g_iTeamworkProtection && g_RoundState == normal && GetEventInt(event, "objecttype") == 3)
	{
		new client = GetClientOfUserId(GetEventInt(event, "attacker")), assister = GetClientOfUserId(GetEventInt(event, "assister"));
		
		AddTeamworkTime(client);
		AddTeamworkTime(assister);	
	}
}

public hook_GameEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundState = mapEnding;
}

public hook_PointCaptured(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_iTeamworkProtection)
	{
		decl String:cappers[128];
		GetEventString(event, "cappers", cappers, sizeof(cappers));

		new len = strlen(cappers);
		for (new i = 0; i < len; i++)
		{
			AddTeamworkTime(cappers[i]);
		}
	}
	
	if (g_bKothMode)
	{
		GetEventInt(event, "team") == TEAM_RED ? (g_bRedCapped = true) : (g_bBluCapped = true);
	}
}

public hook_RoundStalemate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvar_ForceBalance) && g_aTeams[bImbalanced])
	{	
		BalanceTeams(true);	
	}
	
	g_RoundState = suddenDeath;
}

/**
add protection to those interacting with the CTF flag
*/	
public hook_FlagEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	new type = GetEventInt(event, "eventtype");
	
	switch (type)
	{
		case 1:
		{
			g_aPlayers[client][bHasFlag] = true;
		}
		default:
		{
			g_aPlayers[client][bHasFlag] = false;
		}
	}	
	
	AddTeamworkTime(GetEventInt(event, "player"));
}

public Action:Event_PlayerTeam_Pre(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bBlockDeath)
	{
		SetEventBroadcast(event, true);
		return Plugin_Continue;
	}
	
	CheckBalance(true);	
	return Plugin_Continue;
}	

public hook_Event_TFRestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iCompleteRounds = 0;	
}

public hook_Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_aTeams[iRedFrags] = 0;
	g_aTeams[iBluFrags] = 0;
	g_iCompleteRounds = 0;
	g_RoundState = preGame;
	g_aTeams[iRedWins] = 0;
	g_aTeams[iBluWins] = 0;
}

#if defined GAMEME_INCLUDED
public OnClientPutInServer(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	if (g_bUseGameMe && client > 0 && !IsFakeClient(client))
	{
		if (GetFeatureStatus(FeatureType_Native, "QueryGameMEStats") == FeatureStatus_Available)
		{
			QueryGameMEStats("playerinfo", client, QuerygameMEStatsCallback, 1);
		}
		else
		{
			g_bUseGameMe = false;
		}
	}
}
#endif

#if defined GAMEME_INCLUDED
public QuerygameMEStatsCallback(command, payload, client, &Handle: datapack)
{
	if ((client > 0) && (command == RAW_MESSAGE_CALLBACK_PLAYER))
	{
		new Handle: data = CloneHandle(datapack);
		ResetPack(data);
		g_aPlayers[client][iGameMe_Rank] = ReadPackCell(data);
		SetPackPosition(data, GetPackPosition(data)+1);
		g_aPlayers[client][iGameMe_Skill] = ReadPackCell(data);
		SetPackPosition(data, GetPackPosition(data)+28);
		g_aPlayers[client][iGameMe_gRank] = ReadPackCell(data);
		SetPackPosition(data, GetPackPosition(data)+1);
		g_aPlayers[client][iGameMe_gSkill] = ReadPackCell(data);
		SetPackPosition(data, GetPackPosition(data) -16);
		g_aPlayers[client][iGameMe_SkillChange] = ReadPackCell(data);
		CloseHandle(data);
	}
}
#endif

public OnClientDisconnect(client)
{
	if (IsFakeClient(client))
	{
		return;
	}
	
	g_aPlayers[client][bHasFlag] = false;
	if (g_aPlayers[client][bHasVoted] == true)
	{
		g_iVotes--;
		g_aPlayers[client][bHasVoted] = false;
	}
	
	g_iVoters--;	
	if (g_iVoters < 0)
	{
		g_iVoters = 0;	
	}
	
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
	g_aPlayers[client][iTeamPreference] = 0;
	
	if (GetConVarBool(cvar_AdminBlockVote) && g_aPlayers[client][bIsVoteAdmin])
	{
		g_iNumAdmins--;
	}
	
}

public Action:Event_PlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	CheckBalance(true);
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (client && !IsFakeClient(client))
	{		
		/**
		check to see if we should remember his info for disconnect
		reconnect team blocking
		*/
		if (g_bUseClientPrefs && g_bForceTeam && g_bForceReconnect && IsClientInGame(client) && IsValidTeam(client) && (g_bTeamsLocked || IsBlocked(client)))
		{
			decl String:blockTime[128], String:teamIndex[5], String:serverIp[50], String:serverPort[10], String:startTime[33];
			new iIndex;
			GetConVarString(FindConVar("hostip"), serverIp, sizeof(serverIp));
			GetConVarString(FindConVar("hostport"), serverPort, sizeof(serverPort));
			Format(serverIp, sizeof(serverIp), "%s%s", serverIp, serverPort);
			IntToString(GetTime(), blockTime, sizeof(blockTime));
			IntToString(g_iPluginStartTime, startTime, sizeof(startTime));
			
			if (g_iTeamIds[1] == GetClientTeam(client))
			{
				iIndex = 1;
			}
			
			IntToString(iIndex, teamIndex, sizeof(teamIndex));
			SetClientCookie(client, g_cookie_timeBlocked, blockTime);
			SetClientCookie(client, g_cookie_teamIndex, teamIndex);
			SetClientCookie(client, g_cookie_serverIp, serverIp);
			SetClientCookie(client, g_cookie_serverStartTime, startTime);
			LogAction(client, -1, "\"%L\" is team swap blocked, and is being saved.", client);
		}
		if (g_bUseBuddySystem)
		{
			for (new i = 1; i <= MaxClients; i++)
			{
				if (g_aPlayers[i][iBuddy] == client)
				{
					if (IsClientInGame(i))
					{
						PrintToChat(i, "\x01\x04[SM]\x01 %t", "YourBuddyLeft");
					}
					
					g_aPlayers[i][iBuddy] = 0;
				}
			}
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(IsFakeClient(client))
	{
		return;
	}
		
	if (GetConVarBool(cvar_Preference) && g_bAutoBalance && g_bHooked)
	{
		CreateTimer(25.0, Timer_PrefAnnounce, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_aPlayers[client][iBlockTime] = 0;
	g_aPlayers[client][iBalanceTime] = 0;
	g_aPlayers[client][iTeamworkTime] = 0;
	g_aPlayers[client][iFrags] = 0;
	g_aPlayers[client][iDeaths] = 0;
	g_aPlayers[client][bHasFlag] = false;
	g_aPlayers[client][iSpecChangeTime] = 0;
	
	if (GetConVarBool(cvar_AdminBlockVote) && CheckCommandAccess(client, "sm_scramblevote", ADMFLAG_BAN))
	{
		g_aPlayers[client][bIsVoteAdmin] = true;
		g_iNumAdmins++;
	}
	else 
	{
		g_aPlayers[client][bIsVoteAdmin] = false;
	}
	
	g_aPlayers[client][bHasVoted] = false;
	g_iVoters++;
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
}

#if defined HLXCE_INCLUDED
public HLXCE_OnClientReady(client)
{
	HLXCE_GetPlayerData(client);
}

public HLXCE_OnGotPlayerData(client, const PData[HLXCE_PlayerData])
{
	g_aPlayers[client][iHlxCe_Rank] = PData[PData_Rank];
	g_aPlayers[client][iHlxCe_Skill] = PData[PData_Skill];
}
#endif

public OnClientCookiesCached(client)
{
	if (!IsClientConnected(client) || IsFakeClient(client) || !g_bForceTeam || !g_bForceReconnect)
	{
		return;
	}
	
	g_aPlayers[client][iBlockWarnings] = 0;
	decl String:sStartTime[33];
	GetClientCookie(client, g_cookie_serverStartTime, sStartTime, sizeof(sStartTime));
	
	if (StringToInt(sStartTime) != g_iPluginStartTime)
	{
		return;
		/**
		bug out since the sessions dont match
		*/
	}
	
	decl String:time[32], iTime, String:clientServerIp[33], String:serverIp[100], String:serverPort[100];
	GetConVarString(FindConVar("hostip"), serverIp, sizeof(serverIp));
	GetConVarString(FindConVar("hostport"), serverPort, sizeof(serverPort));
	Format(serverIp, sizeof(serverIp), "%s%s", serverIp, serverPort);
	GetClientCookie(client, g_cookie_timeBlocked, time, sizeof(time));
	GetClientCookie(client, g_cookie_serverIp, clientServerIp, sizeof(clientServerIp));
	
	if ((iTime = StringToInt(time)) && strncmp(clientServerIp, serverIp, true) == 0)
	{
		if (iTime > g_iMapStartTime && (GetTime() - iTime) <= GetConVarInt(cvar_ForceTeam))
		{
			LogAction(client, -1, "\"%L\" is reconnect blocked", client);
			SetupTeamSwapBlock(client);
			CreateTimer(10.0, timer_Restore, GetClientUserId(client));
		}
	}   
}

public Action:Timer_PrefAnnounce(Handle:timer, any:id)
{
	new client;
	
	if ((client = GetClientOfUserId(id)))
	{
		PrintToChat(client, "\x01\x04[SM]\x01 %t", "PrefAnnounce");
	}
	
	return Plugin_Handled;
}

public Action:timer_Restore(Handle:timer, any:id)
{
	/**
	make sure that the client is still conneceted
	*/
	new client;
	
	if (!(client = GetClientOfUserId(id)) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	new String:sIndex[10], iIndex;
	GetClientCookie(client, g_cookie_teamIndex, sIndex, sizeof(sIndex));
	
	iIndex = StringToInt(sIndex);
	if (iIndex != 0 || iIndex != 1)
	{
		return Plugin_Handled;
	}
	
	if (GetClientTeam(client) != g_iTeamIds[iIndex])
	{
		ChangeClientTeam(client, g_iTeamIds[iIndex]);
		ShowVGUIPanel(client, "team", _, false);
		PrintToChat(client, "\x01\x04[SM]\x01 %t", "TeamRestore");
		TF2_SetPlayerClass(client, TFClass_Scout);
		LogAction(client, -1, "\"%L\" has had his/her old team restored after reconnecting.", client);
		RestoreMenuCheck(client, g_iTeamIds[iIndex]);
	}
	
	return Plugin_Handled;	
}

public OnMapStart()
{
	g_iMapStartTime = GetTime();
	/**
	* reset most of what we track with this plugin
	* team wins, frags, gamestate... ect
	*/
	g_bTeamsLocked = false;
	g_bScrambledThisRound = false;
	g_bScrambleOverride = false;
	g_iRoundTrigger = 0;
	g_aTeams[iRedFrags] = 0;
	g_aTeams[iBluFrags] = 0;
	g_iCompleteRounds = 0;
	g_bScrambleNextRound = false;
	g_aTeams[iRedWins] = 0;
	g_aTeams[iBluWins] = 0;
	g_RoundState = newGame;
	g_bWasFullRound = false;
	g_bPreGameScramble = false;
	g_bIsTimer = false;
	g_bPreGameScramble = false;
	g_iVotes = 0;
	PrecacheSound(SCRAMBLE_SOUND, true);
	PrecacheSound(EVEN_SOUND, true);
	
	if (g_hBalanceFlagTimer != INVALID_HANDLE)
	{
		KillTimer(g_hBalanceFlagTimer);
		g_hBalanceFlagTimer = INVALID_HANDLE;	
	}
	
	if (g_hForceBalanceTimer != INVALID_HANDLE)
	{
		KillTimer(g_hForceBalanceTimer);
		g_hForceBalanceTimer = INVALID_HANDLE;
	}
	
	g_hCheckTimer = INVALID_HANDLE;
	
	if (g_hScrambleNowPack != INVALID_HANDLE)
	{
		CloseHandle(g_hScrambleNowPack);
	}
	
	g_hScrambleNowPack = INVALID_HANDLE;
	g_iLastRoundWinningTeam = 0;
}

AddTeamworkTime(client)
{
	if (g_RoundState == normal && client && IsClientInGame(client) && !IsFakeClient(client))
	{
		g_aPlayers[client][iTeamworkTime] = GetTime()+g_iTeamworkProtection;
	}
}

public OnMapEnd()
{
	if (g_hScrambleDelay != INVALID_HANDLE)	
		KillTimer(g_hScrambleDelay);		
	g_hScrambleDelay = INVALID_HANDLE;	
}

public Action:TimerEnable(Handle:timer)
{
	g_bVoteAllowed = true;
	g_hVoteDelayTimer = INVALID_HANDLE;
	return Plugin_Handled;
}

public Action:cmd_ResetVotes(client, args)
{
	PerformVoteReset(client);
	return Plugin_Handled;
}

PerformVoteReset(client)
{
	LogAction(client, -1, "\"%L\" has reset all the public votes", client);
	ShowActivity(client, "%t", "AdminResetVotes");
	ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ResetReply", g_iVotes);
	
	for (new i = 1; i <= MaxClients; i++)
	{
		g_aPlayers[i][bHasVoted] = false;
	}
	
	g_iVotes = 0;
}

HandleStacker(client)
{
	if (g_aPlayers[client][iBlockWarnings] < 2) 
	{
		new String:clientName[MAX_NAME_LENGTH + 1];
		
		GetClientName(client, clientName, 32);
		LogAction(client, -1, "\"%L\" was blocked from changing teams", client);
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "BlockSwitchMessage");
		
		if (!g_bSilent)
		{
			PrintToChatAll("\x01\x04[SM]\x01 %t", "ShameMessage", clientName);
		}
		
		g_aPlayers[client][iBlockWarnings]++;
	}	
	
	if (GetConVarBool(cvar_Punish))	
	{
		SetupTeamSwapBlock(client);
	}
	
}

public Action:cmd_Balance(client, args) 
{
	PerformBalance(client);
	return Plugin_Handled;
}

PerformBalance(client)
{	
	if (g_bArenaMode)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ArenaReply");
		return;
	}
	
	if (!g_bHooked)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "EnableReply");
		return;
	}
	
	if (TeamsUnbalanced(false))
	{
		BalanceTeams(true);
		LogAction(client, -1, "\"%L\" performed the force balance command", client);
		ShowActivity(client, "%t", "AdminForceBalance");
	}
	else
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NoImbalnceReply");
	}
	
}

Float:GetAvgScoreDifference(team)
{
	new teamScores, otherScores, Float:otherAvg, Float:teamAvg;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		new entity = GetPlayerResourceEntity();
		new Totalscore = GetEntProp(entity, Prop_Send, "m_iScore", _, i); 
		
		if (IsClientInGame(i) && IsValidTeam(i))
		{
			if (GetClientTeam(i) == team)
			{
				teamScores += Totalscore; 
			}
			else
			{
				otherScores += Totalscore;
			}
		}
	}
	teamAvg = FloatDiv(float(teamScores),float(GetTeamClientCount(team)));
	otherAvg = FloatDiv(float(otherScores), float(GetTeamClientCount(team == TEAM_RED ? TEAM_BLUE : TEAM_RED)));
	
	if (otherAvg > teamAvg)
	{
		return 0.0;
	}
	
	return FloatAbs(teamAvg - otherAvg);
}

public Action:cmd_Scramble_Now(client, args)
{
	if (args > 3)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NowCommandReply");
		return Plugin_Handled;
	}
	
	new Float:fDelay = 5.0, bool:respawn = true, e_ScrambleModes:mode;
	
	if (args)
	{
		decl String:arg1[5];
		GetCmdArg(1, arg1, sizeof(arg1));
		
		if((fDelay = StringToFloat(arg1)) == 0.0)
		{
			ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NowCommandReply");
			return Plugin_Handled;
		}
		
		if (args > 1)
		{
			decl String:arg2[2];
			GetCmdArg(2, arg2, sizeof(arg2));
			if (!StringToInt(arg2))
				respawn = false;
		}
		
		if (args > 2)
		{
			decl String:arg3[2];
			GetCmdArg(3, arg3, sizeof(arg3));
			if ((mode = e_ScrambleModes:StringToInt(arg3)) > randomSort)
			{
				ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NowCommandReply");
				return Plugin_Handled;
			}
		}			
	}
	
	PerformScrambleNow(client, fDelay, respawn, mode);
	return Plugin_Handled;
}

stock PerformScrambleNow(client, Float:fDelay = 5.0, bool:respawn = false, e_ScrambleModes:mode = invalid)
{
	if (!g_bHooked)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "EnableReply");
		return;
	}
	
	if (g_bNoSequentialScramble && g_bScrambledThisRound)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ScrambledAlready");
		return;
	}
	
	if (g_bScrambleNextRound)
	{
		g_bScrambleNextRound = false;
		if (g_hScrambleDelay != INVALID_HANDLE)
		{
			KillTimer(g_hScrambleDelay);
			g_hScrambleDelay = INVALID_HANDLE;
		}
	}
	
	LogAction(client, -1, "\"%L\" performed the scramble command", client);
	ShowActivity(client, "%t", "AdminScrambleNow");
	StartScrambleDelay(fDelay, respawn, mode);
}

stock AttemptScrambleVote(client)
{	
	if (g_bArenaMode)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ArenaReply");
		return;
	}
	
	if (GetConVarBool(cvar_AdminBlockVote) && g_iNumAdmins > 0)
	{
		ReplyToCommand(client, "\x01x04[SM] %t", "AdminBlockVoteReply");
		return;
	}
	
	if (!g_bHooked)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "EnableReply");
		return;
	}	
	
	new bool:Override = false;
		
	if (!GetConVarBool(cvar_VoteEnable))
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "VoteDisabledReply");
		return;
	}
	
	if (g_bNoSequentialScramble && g_bScrambledThisRound)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ScrambledAlready");
		return;
	}
	
	if (!g_bVoteAllowed)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "VoteDelayedReply");
		return;
	}	
	
	if (g_iVotesNeeded - g_iVotes == 1 && GetConVarInt(cvar_VoteMode) == 1 && IsVoteInProgress())
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "Vote in Progress");
		return;
	}	
	
	if (GetConVarInt(cvar_MinPlayers) > g_iVoters)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NotEnoughPeopleVote");
		return;
	}	
	
	if (g_aPlayers[client][bHasVoted] == true)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "AlreadyVoted");
		return;
	}	
	
	if (g_bScrambleNextRound)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ScrambleReply");		
		return;
	}
	
	if (g_RoundState == normal && GetConVarBool(cvar_RoundTime) && g_bIsTimer && g_iVotesNeeded - g_iVotes == 1)
	{
		new iRoundLimit = GetConVarInt(cvar_RoundTime);
		if (g_iRoundTimer - iRoundLimit <= 0)
		{
			if (GetConVarBool(cvar_RoundTimeMode))
			{
				Override = true;
			}
			else
			{
				ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "VoteRoundTimeReply", iRoundLimit);
				return;
			}
		}
	}
	
	g_iVotes++;
	g_aPlayers[client][bHasVoted] = true;
	
	new String:clientName[MAX_NAME_LENGTH + 1];
	
	GetClientName(client, clientName, 32);
	PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteTallied", clientName, g_iVotes, g_iVotesNeeded);	
	
	if (g_iVotes >= g_iVotesNeeded && !g_bScrambleNextRound)
	{
		if (GetConVarInt(cvar_VoteMode) == 1)
		{
			StartScrambleVote(g_iDefMode);		
		}
		else if (GetConVarInt(cvar_VoteMode) == 0)
		{			
			g_bScrambleNextRound = true;
			PrintToChatAll("\x01\x04[SM]\x01 %t", "ScrambleRound");			
		}
		else if (!Override && GetConVarInt(cvar_VoteMode) == 2)
		{
			StartScrambleDelay(5.0, true);	
		}
		
		DelayPublicVoteTriggering();
	}
}	

public Action:cmd_Vote(client, args)
{
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "Vote in Progress");
		return Plugin_Handled;
	}	
	
	if (args < 1)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 Usage: sm_scramblevote <now/end>");
		return Plugin_Handled;
	}	
	
	decl String:arg[16];
	GetCmdArg(1, arg, sizeof(arg));

	new ScrambleTime:mode;
	if (StrEqual(arg, "now", false))
	{
		mode = Scramble_Now;
	}
	else if (StrEqual(arg, "end", false))
	{
		mode = Scramble_Round;
	}
	else
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "InvalidArgs");
		return Plugin_Handled;
	}
	
	PerformVote(client, mode);
	return Plugin_Handled;
}

PerformVote(client, ScrambleTime:mode)
{	
	if (g_bArenaMode)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ArenaReply");
		return;
	}
	
	if (!g_bHooked)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "EnableReply");
		return;
	}	
	
	if (GetConVarInt(cvar_MinPlayers) > g_iVoters)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NotEnoughPeopleVote");
		return;
	}	
	
	if (g_bScrambleNextRound)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ScrambleReply");
		return;
	}	
	
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "Vote in Progress");
		return;
	}
	
	if (!g_bVoteAllowed)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "VoteDelayedReply");
		return;
	}
	
	if (g_bNoSequentialScramble && g_bScrambledThisRound)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ScrambledAlready");
		return;
	}
	
	LogAction(client, -1, "\"%L\" has started a scramble vote", client);
	StartScrambleVote(mode, 20);
}

StartScrambleVote(ScrambleTime:mode, time=20)
{
	if (IsVoteInProgress())
	{
		PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteWillStart");
		CreateTimer(1.0, Timer_ScrambleVoteStarter, mode, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	DelayPublicVoteTriggering();
	g_hScrambleVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	
	new String:sTmpTitle[64];
	if (mode == Scramble_Now)
	{
		g_bScrambleAfterVote = true;
		Format(sTmpTitle, 64, "Scramble Teams Now?");
	}
	else
	{
		g_bScrambleAfterVote = false;
		Format(sTmpTitle, 64, "Scramble Teams Next Round?");
	}
	
	SetMenuTitle(g_hScrambleVoteMenu, sTmpTitle);
	AddMenuItem(g_hScrambleVoteMenu, "1", "Yes");
	AddMenuItem(g_hScrambleVoteMenu, "2", "No");
	SetMenuExitButton(g_hScrambleVoteMenu, false);
	VoteMenuToAll(g_hScrambleVoteMenu, time);
}

public Action:Timer_ScrambleVoteStarter(Handle:timer, any:mode)
{
	if (IsVoteInProgress())
	{
		return Plugin_Continue;
	}
	
	StartScrambleVote(mode, 15);
	
	return Plugin_Stop;
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	DelayPublicVoteTriggering();
	
	if (action == MenuAction_End)
	{
		CloseHandle(g_hScrambleVoteMenu);
		g_hScrambleVoteMenu = INVALID_HANDLE;
	}		
	
	if (action == MenuAction_VoteEnd)
	{	
		new m_votes, totalVotes;		
		GetMenuVoteInfo(param2, m_votes, totalVotes);
		
		if (param1 == 1)
		{
			m_votes = totalVotes - m_votes;
		}
		
		new Float:comp = FloatDiv(float(m_votes),float(totalVotes));
		new Float:comp2 = GetConVarFloat(cvar_Needed);
		
		if (comp >= comp2)
		{
			PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteWin", RoundToNearest(comp*100), totalVotes);	
			LogAction(-1 , 0, "%T", "VoteWin", LANG_SERVER, RoundToNearest(comp*100), totalVotes);	
			
			if (g_bScrambleAfterVote)
			{
				StartScrambleDelay(5.0, true);
			}
			else
			{
				if ((g_bFullRoundOnly && g_bWasFullRound) || !g_bFullRoundOnly)
				{
					g_bScrambleNextRound = true;
					PrintToChatAll("\x01\x04[SM]\x01 %t", "ScrambleStartVote");
				}			
			}
		}
		else
		{
			new against = 100 - RoundToNearest(comp*100);
			PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteFailed", against, totalVotes);
			LogAction(-1 , 0, "%T", "VoteFailed", LANG_SERVER, against, totalVotes);
		}
	}
}

DelayPublicVoteTriggering(bool:success = false)  // success means a scramble happened... longer delay
{
	if (GetConVarBool(cvar_VoteEnable))
	{
		for (new i = 0; i <= MaxClients; i++)	
		{
			g_aPlayers[i][bHasVoted] = false;
		}
		
		g_iVotes = 0;
		g_bVoteAllowed = false;
		
		if (g_hVoteDelayTimer != INVALID_HANDLE)
		{
			KillTimer(g_hVoteDelayTimer);
			g_hVoteDelayTimer = INVALID_HANDLE;
		}
		
		new Float:fDelay;
		if (success)
		{
			fDelay = GetConVarFloat(cvar_VoteDelaySuccess);
		}
		else
		{
			fDelay = GetConVarFloat(cvar_Delay);
		}
		
		g_hVoteDelayTimer = CreateTimer(fDelay, TimerEnable, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action:cmd_Scramble(client, args)
{
	SetupRoundScramble(client);
	return Plugin_Handled;
}

public Action:cmd_Cancel(client, args)
{
	PerformCancel(client);
	return Plugin_Handled;
}

PerformCancel(client)
{
	if (g_bScrambleNextRound || g_hScrambleDelay != INVALID_HANDLE)
	{
		g_bScrambleNextRound = false;
		
		if (g_hScrambleDelay != INVALID_HANDLE)
		{
			KillTimer(g_hScrambleDelay);
			g_hScrambleDelay = INVALID_HANDLE;
		}
		
		ShowActivity(client, "%t", "CancelScramble");
		LogAction(client, -1, "\"%L\" canceled the pending scramble", client);	
	}
	else if (g_RoundState == bonusRound && g_bAutoScramble)
	{
		if (g_bScrambleOverride)
		{
			g_bScrambleOverride = false;
			ShowActivity(client, "%t", "OverrideUnCheck");
			LogAction(client, -1, "\"%L\" un-blocked the autoscramble check for the next round.", client);
		}
		else
		{
		g_bScrambleOverride = true;
		ShowActivity(client, "%t", "OverrideCheck");
		LogAction(client, -1, "\"%L\" blocked the autoscramble check for the next round.", client);
		}
	}
	else
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NoScrambleReply");
		return;
	}
}

/**
	tirggered after an admin selects round scramble via menu or command
*/
SetupRoundScramble(client)
{
	if (!g_bHooked)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "EnableReply");
		return;
	}
	
	if (g_bNoSequentialScramble && g_bScrambledThisRound)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ScrambledAlready");
		return;
	}
	
	if (g_bScrambleNextRound)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ScrambleReply");
		return;
	}	
	
	g_bScrambleNextRound = true;
	ShowActivity(client, "%t", "ScrambleRound");
	LogAction(client, -1, "\"%L\" toggled a scramble for next round", client);
}

SwapPreferences()
{
	for (new i = 1; i <= MaxClients; i++)
	{	
		if (g_aPlayers[i][iTeamPreference] == TEAM_RED)
		{
			g_aPlayers[i][iTeamPreference] = TEAM_BLUE;
		}
		else if (g_aPlayers[i][iTeamPreference] == TEAM_BLUE)
		{
			g_aPlayers[i][iTeamPreference] = TEAM_RED;
		}
	}	
}

public Event_RoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	
	g_bTeamsLocked = false;
	g_bNoSpec = false;
	/**
	check to see if the previos round warrented a trigger
	moved to the start event to make checking for map ending uneeded
	*/
	g_bScrambleNextRound = ScrambleCheck();
	/**
	execute the trigger
	*/
	
	if (g_bScrambleNextRound)
	{
		new rounds = GetConVarInt(cvar_AutoScrambleRoundCount);
		
		if (rounds)
		{
			g_iRoundTrigger += rounds;
		}
		
		StartScrambleDelay(0.3);
	}
	else if (GetConVarBool(cvar_ForceBalance) && g_hForceBalanceTimer == INVALID_HANDLE)
	{
		g_hForceBalanceTimer = CreateTimer(0.2, Timer_ForceBalance);
	}
	
	/**
	dont reset the team frag counting if full round only is specified, and it was not a full round
	*/
	if ((g_bFullRoundOnly && g_bWasFullRound) || !g_bFullRoundOnly)
	{
		g_aTeams[iRedFrags] = 0;
		g_aTeams[iBluFrags] = 0;
	}
	
	if (g_RoundState == newGame)
	{
		g_RoundState = preGame;
		DelayPublicVoteTriggering();
		if (GetConVarBool(cvar_WaitScramble))
		{
			g_bPreGameScramble = true;
			g_bScrambleNextRound = true;
			PrintToChatAll("\x01\x04[SM]\x01 %t", "ScrambleRound");
		}
	}
	else if (g_RoundState == preGame)
	{
		g_RoundState = normal;
	}

	/**
	check the timer entity, and see if its in setup mode
	as well as get the round duration for the countdown
	*/
	if (g_RoundState != preGame)
	{
		CreateTimer(0.1, Timer_GetTime, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_iRoundStartTime = GetTime();
	g_iSpawnTime = g_iRoundStartTime;
	
	/**
	reset
	*/
	g_bScrambleOverride = false;
	g_bWasFullRound = false;
	g_bRedCapped = false;
	g_bBluCapped = false;
	g_bScrambledThisRound = false;
}

public Action:hook_Setup(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundState = normal;
	CreateTimer(1.0, Timer_GetTime, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStartTime = GetTime();
	
	if (g_aTeams[bImbalanced])
	{
		StartForceTimer();
	}
	
	return Plugin_Continue;
}

public Event_RoundWin(Handle:event, const String:name[], bool:dontBroadcast)
{	
	g_iRoundTimer = 0;
	
	if (GetConVarBool(cvar_ScrLockTeams))
	{
		g_bNoSpec = true;
	}
	
	g_RoundState = bonusRound;	
	g_bWasFullRound = false;	
	
	if (GetEventBool(event, "full_round"))
	{
		g_bWasFullRound = true;
		g_iCompleteRounds++;
	}
	else if (!GetConVarBool(cvar_FullRoundOnly))
	{
		g_iCompleteRounds++;
	}
	
	g_iLastRoundWinningTeam = GetEventInt(event, "team");
	
	if (g_hForceBalanceTimer != INVALID_HANDLE)
	{
		KillTimer(g_hForceBalanceTimer);
		g_hForceBalanceTimer = INVALID_HANDLE;
	}
	
	if (g_hBalanceFlagTimer != INVALID_HANDLE)
	{
		KillTimer(g_hBalanceFlagTimer);
		g_hBalanceFlagTimer = INVALID_HANDLE;
	}
}

public Action:Event_PlayerDeath_Pre(Handle:event, const String:name[], bool:dontBroadcast) 
{	
	new k_client = GetClientOfUserId(GetEventInt(event, "attacker"));
	new	v_client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	if (k_client && IsClientInGame(k_client) && k_client != v_client && g_bBlockDeath)
	{
		g_bBlockDeath = false;
	}
	
	if (g_bBlockDeath) 
	{
		return Plugin_Handled;
	}
	
	if (g_RoundState != normal || GetEventInt(event, "death_flags") & 32) 
	{
		return Plugin_Continue;	
	}
	
	if (IsOkToBalance() && g_bAutoBalance && g_aTeams[bImbalanced] && GetClientTeam(v_client) == GetLargerTeam())	
	{
		CreateTimer(0.1, timer_StartBalanceCheck, v_client, TIMER_FLAG_NO_MAPCHANGE);
	}
		
	if (!k_client || k_client == v_client || k_client > MaxClients)
	{
		return Plugin_Continue;
	}
	
	g_aPlayers[k_client][iFrags]++;
	g_aPlayers[v_client][iDeaths]++;
	GetClientTeam(k_client) == TEAM_RED ? (g_aTeams[iRedFrags]++) : (g_aTeams[iBluFrags]++);	
	
	return Plugin_Continue;
}

stock GetAbsValue(value1, value2)
{
	return RoundFloat(FloatAbs(FloatSub(float(value1), float(value2))));
}

bool:IsNotTopPlayer(client, team)  // this arranges teams based on their score, and checks to see if a client is among the top X players
{
	new iSize, iHighestScore;
	decl iScores[MAXPLAYERS+1][2];
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{		
			new entity = GetPlayerResourceEntity();
			new Totalscore = GetEntProp(entity, Prop_Send, "m_iTotalScore", _, i); 

			iScores[iSize][1] = 1 + Totalscore;
			iScores[iSize][0] = i;
			
			if (iScores[iSize][1] > iHighestScore)
			{
				iHighestScore = iScores[iSize][1];
			}
			
			iSize++;
		}
	}
	
	if (iHighestScore <= 10)
	{
		return true;
	}
	
	if (iSize < GetConVarInt(cvar_TopProtect) + 4)
	{
		return true;
	
	}
	SortCustom2D(iScores, iSize, SortScoreDesc);
	
	for (new i = 0; i < GetConVarInt(cvar_TopProtect); i++)
	{
		if (iScores[i][0] == client)
		{
			return false;
		}
	}
	
	return true;
}

bool:IsClientBuddy(client)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && g_aPlayers[i][iBuddy] == client)
		{
			if (GetClientTeam(client) == GetClientTeam(i))
			{
				LogAction(-1, 0, "Buddy detected for client %L", client);
				return true;
			}
		}
	}
	
	return false;
}

bool:IsValidTarget(client, e_ImmunityModes:mode)
{
	if (IsFakeClient(client))
	{
		if (mode != scramble && GetConVarBool(cvar_AbHumanOnly))
		{
			return false;
		}
		
		return true;
	}

	if ((mode == scramble && GetConVarBool(cvar_ScrambleDuelImmunity)) || mode == balance)
	{
		if (TF2_IsPlayerInDuel(client))
		{
			return false;
		}
	}
	
	// next check for buddies. if the buddy is on the wrong team, we skip the rest of the immunity checks
	if (g_bUseBuddySystem && mode == balance)
	{
		new buddy;
		
		if ((buddy = g_aPlayers[client][iBuddy]))
		{
			if (GetClientTeam(buddy) == GetClientTeam(client))
			{
				LogAction(-1, 0, "Flagging client %L invalid because of buddy preference", client);
				return false;
			}
			else if (IsValidTeam(g_aPlayers[client][iBuddy]))
			{
				LogAction(-1, 0, "Flagging client %L valid because of buddy preference", client);
				return true;				
			}
		}
		
		if (IsClientBuddy(client))
		{
			return false;
		}
	}
	
	new e_Protection:iImmunity, String:flags[32]; // living players are immune
	
	if (mode == scramble)
	{
		iImmunity = e_Protection:GetConVarInt(cvar_ScrambleImmuneMode); // living plyers are not immune from scramble
		GetConVarString(cvar_ScrambleAdmFlags, flags, sizeof(flags));
	}
	else
	{
		iImmunity = e_Protection:GetConVarInt(cvar_BalanceImmunity);
		GetConVarString(cvar_BalanceAdmFlags, flags, sizeof(flags));
	}
	
	/*
		override immunities when things like alive or buildings done matter
		if the round started within 10 seconds, override immunity too
	*/
	new iStart = GetTime() - g_iSpawnTime;
	
	if (iStart <= 10 || mode == scramble || (g_RoundState != normal && g_RoundState != setup))
	{
		if (iImmunity == both)
		{
			iImmunity = admin;
		}
		else if (iImmunity == uberAndBuildings)
		{
			return true;
		}
	}
	
	if (IsClientInGame(client) && IsValidTeam(client))
	{
		if (mode == balance && GetConVarInt(cvar_TopProtect) && !IsNotTopPlayer(client, GetClientTeam(client)))
		{
			return false;
		}
		
		if (iImmunity == none) // if no immunity mode set, don't check for it :p
		{
			return true;
		}
		
		switch (iImmunity)
		{
			case admin:
			{
				if (IsAdmin(client, flags))
					return false;			
			}
			case uberAndBuildings:
			{
				if (TF2_HasBuilding(client) || TF2_IsClientUberCharged(client) || TF2_IsClientUbered(client))
					return false;
			}
			case both:
			{
				if (IsAdmin(client, flags) || TF2_HasBuilding(client) || TF2_IsClientUberCharged(client) || TF2_IsClientUbered(client))
					return false;			
			}
		}
		return true;
	}
	
	if (IsValidSpectator(client))
	{
		return true;
	}
	
	return false;
}

stock bool:IsValidSpectator(client)
{
	if (!IsFakeClient(client))
	{
		if (g_bSelectSpectators)
		{
			if (GetClientTeam(client) == 1)
			{
				new iChangeTime = g_aPlayers[client][iSpecChangeTime];
				
				if (iChangeTime && (GetTime() - iChangeTime) < GetConVarInt(cvar_SelectSpectators))
				{
					return true;
				}
				
				new Float:fTime = GetClientTime(client);
				
				if (fTime <= 60.0)
				{
					return true;
				}
			}
		}
	}
	
	return false;
}
			
stock bool:IsAdmin(client, const String:flags[])
{
	new bits = GetUserFlagBits(client);	
	
	if (bits & ADMFLAG_ROOT)
	{
		return true;
	}
	
	new iFlags = ReadFlagString(flags);
	
	if (bits & iFlags)
	{
		return true;	
	}
	
	return false;
}

stock BlockAllTeamChange()
{
	if (GetConVarBool(cvar_LockTeamsFullRound))
	{
		g_bTeamsLocked = true; 
	}
	
	for (new i=1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsValidTeam(i) || IsFakeClient(i))
		{
			continue;
		}
		
		SetupTeamSwapBlock(i);
	}
}

SetupTeamSwapBlock(client)  /* blocks proper clients from spectating*/
{
	if (!g_bForceTeam)
	{
		return;
	}
	
	if (GetConVarBool(cvar_TeamSwapBlockImmunity))
	{
		if (IsClientInGame(client))
		{
			new String:flags[32];
			GetConVarString(cvar_TeamswapAdmFlags, flags, sizeof(flags));
			if (IsAdmin(client, flags))
				return;				
		}
	}
	
	g_aPlayers[client][iBlockTime] = GetTime() + g_iForceTime;
}

public Action:TimerStopSound(Handle:timer)	 // cuts off the sound after 1.7 secs so it only plays 'Lets even this out'
{
	for (new i=1; i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			StopSound(i, SNDCHAN_AUTO, EVEN_SOUND);
		}
	}
	
	return Plugin_Handled;
}

public Action:Timer_GetTime(Handle:timer)
{
	CheckBalance(true);
	g_iTimerEnt = FindEntityByClassname(-1, "team_round_timer");
	
	if (g_iTimerEnt != -1)
	{
		g_bIsTimer = true;
		new iState = GetEntProp(g_iTimerEnt, Prop_Send, "m_nState");
		
		if (!iState)		
		{
			g_RoundState = setup;
			return Plugin_Handled;
		}
		
		g_iRoundTimer = GetEntProp(g_iTimerEnt, Prop_Send, "m_nTimerLength") -2;
		
		if (g_hRoundTimeTick != INVALID_HANDLE)
		{
			KillTimer(g_hRoundTimeTick);
			g_hRoundTimeTick = INVALID_HANDLE;
		}
		
		if (g_RoundState == bonusRound || g_RoundState == setup)
		{
			g_RoundState = normal;
		}
		
		g_hRoundTimeTick = CreateTimer(1.0, Timer_Countdown, _, TIMER_REPEAT);
	}
	else
	{
		g_RoundState = normal;
		g_bIsTimer = false;
	}
	return Plugin_Handled;
}

public TimerUpdateAdd(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvar_RoundTime))
	{
		g_iRoundTimer += GetEventInt(event, "seconds_added");
		CheckBalance(true);
	}
}

public Action:Timer_Countdown(Handle:timer)
{
	g_iRoundTimer--;
	return Plugin_Continue;
}

/**
* Prioritize people based on active buildings, ubercharge, living/dead, or connection time
*/
stock GetPlayerPriority(client)
{
	if (IsFakeClient(client))
	{
		return 0;
	}
	
	if (TF2_IsPlayerInDuel(client))
	{
		return -10;
	}
	
	if (g_bUseBuddySystem)
	{
		if (g_aPlayers[client][iBuddy])
		{
			if (GetClientTeam(client) == GetClientTeam(g_aPlayers[client][iBuddy]))
			{
				return -10;
			}
			else if (IsValidTeam(g_aPlayers[client][iBuddy]))
			{
				return 10;
			}
		}
		
		if (IsClientBuddy(client))
		{
			return -2;
		}
	}
	
	new iPriority;
	
	if (IsClientInGame(client) && IsValidTeam(client))
	{
		if (g_aPlayers[client][iBalanceTime] > GetTime())
		{
			return -5;
		}
		
		if (g_aPlayers[client][iTeamworkTime] >= GetTime())
		{
			iPriority -= 3;
		}
		
		if (g_RoundState != bonusRound)
		{
			if (TF2_HasBuilding(client)||TF2_IsClientUberCharged(client)||TF2_IsClientUbered(client)|| !IsNotTopPlayer(client, GetClientTeam(client))||TF2_IsClientOnlyMedic(client))
			{
				return -10;
			}
			
			if (!IsPlayerAlive(client))
			{
				iPriority += 5;
			}
			else
			{
				if (g_aPlayers[client][bHasFlag])
				{
					iPriority -= 20;
				}
				
				iPriority -= 1;
			}
		}		
		/**
		make new clients more likely to get swapped
		*/
		if (GetClientTime(client) < 180)		
		{
			iPriority += 5;	
		}
	}
	
	return iPriority;
}

bool:IsValidTeam(client)
{
	new team = GetClientTeam(client);
	
	if (team == TEAM_RED || team == TEAM_BLUE)
	{
		return true;
	}
	
	return false;
}	

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))		
	{
		g_hAdminMenu = INVALID_HANDLE;
	}
	
	if (StrEqual(name, "hlxce-sm-api"))
	{
		g_bUseHlxCe = false;
	}
	
	if (StrEqual(name, "gameme", false))
	{
		g_bUseGameMe = false;
	}
}

public OnLibraryAdded(const String:name[])
{
	if (StrEqual(name, "hlxce-sm-api"))
	{
		if (GetFeatureStatus(FeatureType_Native, "HLXCE_GetPlayerData") == FeatureStatus_Available)
		{
			g_bUseHlxCe = true;
		}
	}
	if (StrEqual(name, "gameme"))
	{
		if (GetFeatureStatus(FeatureType_Native, "QueryGameMEStats") == FeatureStatus_Available)
		{
			g_bUseGameMe = true;
		}
	}
}

public SortScoreDesc(x[], y[], array[][], Handle:data)
{
    if (Float:x[1] > Float:y[1])
	{
        return -1;
	}
	else if (Float:x[1] < Float:y[1])
	{
		return 1;
	}
	
    return 0;
}

public SortScoreAsc(x[], y[], array[][], Handle:data)
{
    if (Float:x[1] > Float:y[1])
	{
        return 1;
	}
	else if (Float:x[1] < Float:y[1])
	{
		return -1;
	}
	
    return 0;
}

bool:CheckSpecChange(client)
{
	if (GetConVarBool(cvar_TeamSwapBlockImmunity))
	{
		new String:flags[32];
		
		GetConVarString(cvar_TeamswapAdmFlags, flags, sizeof(flags));
		
		if (IsAdmin(client, flags))
		{
			return false;
		}
	}
	new redSize = GetTeamClientCount(TEAM_RED), bluSize = GetTeamClientCount(TEAM_BLUE), difference;
	
	if (GetClientTeam(client) == TEAM_RED)
	{
		redSize -= 1;
	}
	else
	{
		bluSize -= 1;
	}
	
	difference = GetAbsValue(redSize, bluSize);
	
	if (difference >= GetConVarInt(cvar_BalanceLimit))
	{
		PrintToChat(client, "\x01\x04[SM]\x01 %t", "SpecChangeBlock");
		LogAction(client, -1, "Client \"%L\" is being blocked from swapping to spectate", client);
		return true;
	}
	
	return false;
}

public SortIntsAsc(x[], y[], array[][], Handle:data)		// this sorts everything in the info array ascending
{
    if (x[1] > y[1]) 
	{
		return 1;
	}
    else if (x[1] < y[1]) 
	{
		return -1;    
	}
	
    return 0;
}

public SortIntsDesc(x[], y[], array[][], Handle:data)		// this sorts everything in the info array descending
{
    if (x[1] > y[1]) 
	{
		return -1;
	}
    else if (x[1] < y[1]) 
	{
		return 1;   
	}		
	
    return 0;
}