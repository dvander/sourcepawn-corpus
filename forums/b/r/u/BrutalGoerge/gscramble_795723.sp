/************************************************************************
*************************************************************************
gScramble (Modernized)
Description:
	Automatic scramble and balance script for TF2
*************************************************************************
*************************************************************************/

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>
#include <sdktools>

#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define VERSION "4.0.0"
#define TEAM_RED 2
#define TEAM_BLUE 3
#define SCRAMBLE_SOUND  "vo/announcer_am_teamscramble03.mp3"
#define EVEN_SOUND		"vo/announcer_am_teamscramble01.mp3"

// --- Global ConVars ---
ConVar cvar_Version, cvar_Steamroll, cvar_Needed, cvar_Delay, cvar_MinPlayers, cvar_MinAutoPlayers,
	cvar_FragRatio, cvar_AutoScramble, cvar_VoteEnable, cvar_WaitScramble, cvar_ForceTeam, cvar_ForceBalance,
	cvar_SteamrollRatio, cvar_VoteMode, cvar_PublicNeeded, cvar_FullRoundOnly, cvar_AutoScrambleWinStreak,
	cvar_SortMode, cvar_TeamSwapBlockImmunity, cvar_MenuVoteEnd, cvar_AutoscrambleVote, cvar_ScrambleImmuneMode,
	cvar_Punish, cvar_Balancer, cvar_BalanceTime, cvar_TopProtect, cvar_BalanceLimit, cvar_BalanceImmunity,
	cvar_Enabled, cvar_RoundTime, cvar_VoteDelaySuccess, cvar_RoundTimeMode, cvar_SetupCharge, cvar_MaxUnbalanceTime,
	cvar_AvgDiff, cvar_DominationDiff, cvar_Preference, cvar_SetupRestore, cvar_BalanceAdmFlags, cvar_ScrambleAdmFlags,
	cvar_TeamswapAdmFlags, cvar_Koth, cvar_AutoScrambleRoundCount, cvar_ForceReconnect, cvar_TeamworkProtect,
	cvar_BalanceActionDelay, cvar_ForceBalanceTrigger, cvar_NoSequentialScramble, cvar_AdminBlockVote,
	cvar_BuddySystem, cvar_ImbalancePrevent, cvar_MenuIntegrate, cvar_Silent, cvar_VoteCommand, cvar_VoteAd,
	cvar_BlockJointeam, cvar_TopSwaps, cvar_BalanceTimeLimit, cvar_ScrLockTeams, cvar_RandomSelections,
	cvar_PrintScrambleStats, cvar_ScrambleDuelImmunity, cvar_AbHumanOnly, cvar_LockTeamsFullRound,
	cvar_SelectSpectators, cvar_ProtectOnlyMedic, cvar_BalanceDuelImmunity, cvar_BalanceChargeLevel,
	cvar_ScrambleCheckImmune, cvar_BalanceImmunityCheck, cvar_OneScramblePerRound, cvar_ProgressDisable,
	cvar_AutoTeamBalance, cvar_TeamWorkFlagEvent, cvar_TeamWorkUber, cvar_TeamWorkMedicKill,
	cvar_TeamWorkCpTouch, cvar_TeamWorkCpCapture, cvar_TeamWorkPlaceSapper, cvar_TeamWorkBuildingKill,
	cvar_TeamWorkCpBlock, cvar_TeamWorkExtinguish, cvar_Volunteer, cvar_VolunteerTime, cvar_AutoScrambleEveryRound;

// --- Global Objects ---
TopMenu g_hAdminMenu;
Menu g_hScrambleVoteMenu;
DataPack g_hScrambleNowPack;

Handle g_hVoteDelayTimer, g_hScrambleDelay, g_hRoundTimeTick, g_hForceBalanceTimer,
	g_hBalanceFlagTimer, g_hCheckTimer, g_hVoteAdTimer;

Cookie g_cookie_timeBlocked, g_cookie_teamIndex, g_cookie_serverIp, g_cookie_serverStartTime;

// --- Global Variables ---
char g_sVoteCommands[3][65];
bool g_bScrambleNextRound = false, g_bVoteAllowed, g_bScrambleAfterVote, g_bWasFullRound = false,
	g_bPreGameScramble, g_bHooked = false, g_bIsTimer, g_bArenaMode, g_bKothMode, g_bRedCapped,
	g_bBluCapped, g_bFullRoundOnly, g_bAutoBalance, g_bForceTeam, g_bForceReconnect, g_bAutoScramble,
	g_bUseClientPrefs = false, g_bNoSequentialScramble, g_bScrambledThisRound, g_bBlockDeath,
	g_bUseBuddySystem, g_bSilent, g_bBlockJointeam, g_bNoSpec, g_bVoteCommandCreated, g_bTeamsLocked,
	g_bSelectSpectators, g_bScrambleOverride;

int g_iTeamIds[2] = {TEAM_RED, TEAM_BLUE};

int	g_iPluginStartTime, g_iMapStartTime, g_iRoundStartTime, g_iVotes, g_iVoters, g_iVotesNeeded,
	g_iCompleteRounds, g_iRoundTrigger, g_iForceTime, g_iLastRoundWinningTeam, g_iNumAdmins;

enum e_TeamInfo
{
	iRedFrags,
	iBluFrags,
	iRedScore,
	iBluScore,
	iRedWins,
	iBluWins,
	bImbalanced // Removed bool cast to allow any array usage safely
};

enum e_PlayerInfo
{
	iBalanceTime,
	bHasVoted,
	iBlockTime,
	iBlockWarnings,
	iTeamPreference,
	iTeamworkTime,
	bIsVoteAdmin,
	iBuddy,
	iFrags,
	iDeaths,
	bHasFlag,
	iSpecChangeTime
};

enum e_RoundState
{
	newGame,
	preGame,
	bonusRound,
	suddenDeath,
	mapEnding,
	setup,
	roundNormal // renamed from normal due to native shadowing
};

enum ScrambleTime
{
	Scramble_Now,
	Scramble_Round
};

enum e_ImmunityModes
{
	scramble,
	balance
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
	playerClass,
	randomSort
};

enum eTeamworkReasons
{
	flagEvent,
	medicKill,
	medicDeploy,
	buildingKill,
	placeSapper,
	controlPointCaptured,
	controlPointTouch,
	controlPointBlock,
	playerExtinguish
};

e_RoundState g_RoundState;
ScrambleTime g_iDefMode;

// Defined as 'any' to safely support the struct-like mixing of ints and booleans
any g_aTeams[e_TeamInfo];
any g_aPlayers[MAXPLAYERS + 1][e_PlayerInfo];

int g_iTimerEnt;
bool g_bRoundIsTimed = false;
float g_fRoundEndTime;

#include "gscramble/gscramble_menu_settings.sp"
#include "gscramble/gscramble_autoscramble.sp"
#include "gscramble/gscramble_autobalance.sp"
#include "gscramble/gscramble_tf2_extras.sp"

public Plugin myinfo = 
{
	name = "[TF2] gScramble",
	author = "Goerge (Modernized)",
	description = "Auto Managed team balancer/scrambler.",
	version = VERSION,
	url = "https://github.com/BrutalGoerge/tf2tmng"
};

public void OnPluginStart()
{
	CheckTranslation();
	cvar_Enabled			= CreateConVar("gs_enabled", 		"1",		"Enable/disable the plugin and all its hooks.", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	cvar_Balancer			= CreateConVar("gs_autobalance",	"0",	"Enable/disable the auto-balance feature of this plugin.\nUse only if you have the built-in balancer disabled.", 0, true, 0.0, true, 1.0);
	cvar_TopProtect			= CreateConVar("gs_ab_protect", "5",	"How many of the top players to protect on each team from auto-balance.", 0, true, 0.0, false);
	cvar_BalanceTime		= CreateConVar("gs_ab_balancetime",	"5",			"Time in minutes after a client is balanced in which they cannot be balanced again.", 0);
	cvar_BalanceLimit		= CreateConVar("gs_ab_unbalancelimit",	"2",	"If one team has this many more players than the other, then consider the teams imbalanced.", 0);
	cvar_BalanceImmunity 	= CreateConVar("gs_ab_immunity",			"2",	"Controls who is immune from auto-balance\n0 = no immunity\n1 = admins\n2 = engies with buildings\n3 = both admins and engies with buildings", 0, true, 0.0, true, 3.0);
	cvar_MaxUnbalanceTime	= CreateConVar("gs_ab_max_unbalancetime", "120", "Max time the teams are allowed to be unbalanced before a balanced is forced on living players.\n0 = disabled.", 0, true, 0.0, false);
	cvar_Preference			= CreateConVar("gs_ab_preference",		"1",	"Allow clients to tell the plugin what team they prefer.  When an auto-balance starts, if the client prefers the team, it overrides any immunity check.", 0, true, 0.0, true, 1.0);
	cvar_BalanceActionDelay = CreateConVar("gs_ab_actiondelay",		"5", 	"Time, in seconds after an imbalance is detected in which an imbalance is flagged, and possible swapping can occur", 0, true, 0.0, false);
	cvar_ForceBalanceTrigger = CreateConVar("gs_ab_forcetrigger",	"4",	"If teams become imbalanced by this many players, auto-force a balance", 0, true, 0.0, false);
	cvar_BalanceTimeLimit	= CreateConVar("gs_ab_timelimit", "0", 		"If there are this many seconds, or less, remaining in a round, stop auto-balancing", 0, true, 0.0, false);
	cvar_AbHumanOnly 		= CreateConVar("gs_ab_humanonly", "0", "Only auto-balance human players", 0, true, 0.0, true, 1.0);
	cvar_ProgressDisable	= CreateConVar("gs_ab_cartprogress_disable", ".90", "If the cart has reached this percentage of progress, then disable auto-balance", 0, true, 0.0, true, 1.0);
	cvar_BalanceDuelImmunity = CreateConVar("gs_ab_duel_immunity", "1", "Players in duels are immune from auto-balance", 0, true, 0.0, true, 1.0);
	cvar_ProtectOnlyMedic	= CreateConVar("gs_ab_protect_medic", "1", "A team's only medic will be immune from balancing", 0, true, 0.0, true, 1.0);
	cvar_BalanceChargeLevel = CreateConVar("gs_ab_protectmedic_chargelevel", "0.5", "Charge level to protect medics from auto balance", 0, true, 0.0, true, 1.0);
	cvar_BalanceImmunityCheck = CreateConVar("gs_balance_checkummunity_percent", "0.0", "Percentage of players immune from auto balance to start to ignore balance immunity check", 0, true, 0.0, true, 1.0);
	cvar_TeamWorkFlagEvent 	= CreateConVar("gs_ab_teamwork_flagevent", 		"30", "Time immunity from auto-balance to grant when a player touches/drops the ctf flag.", 	0, true, 0.0, false);
	cvar_TeamWorkUber		= CreateConVar("gs_ab_teamwork_uber_deploy", 	"30", "Time immunity from auto-balance to grant when a player becomes uber charged.", 			0, true, 0.0, false);
	cvar_TeamWorkMedicKill	= CreateConVar("gs_ab_teamwork_kill_medic", 	"30", "Time immunity from auto-balance to grant when a player kills a charged medic.", 			0, true, 0.0, false);
	cvar_TeamWorkCpTouch	= CreateConVar("gs_ab_teamwork_cp_touch", 		"30", "Time immunity from auto-balance to grant when a player touches a control point.", 		0, true, 0.0, false);
	cvar_TeamWorkCpCapture	= CreateConVar("gs_ab_teamwork_cp_capture", 	"30", "Time immunity from auto-balance to grant when a player captures a control point.", 		0, true, 0.0, false);
	cvar_TeamWorkPlaceSapper = CreateConVar("gs_ab_teamwork_sapper_place", 	"30", "Time immunity from auto-balance to grant when a spy places a sapper.", 					0, true, 0.0, false);
	cvar_TeamWorkBuildingKill= CreateConVar("gs_ab_teamwork_building_kill", "30", "Time immunity from auto-balance to grant when a player destroys a building.", 			0, true, 0.0, false);
	cvar_TeamWorkCpBlock	= CreateConVar("gs_ab_teamwork_cp_block",		"30", "Time immunity from auto-balance to grant when a player blocks a control point.",			0, true, 0.0, false);
	cvar_TeamWorkExtinguish	= CreateConVar("gs_ab_teamwork_extinguish",		"30", "Time immunity from auto-balance to grant when a player extinguishes a team-mate.",		0, true, 0.0, false);
	cvar_ImbalancePrevent	= CreateConVar("gs_prevent_spec_imbalance", "0", "If set, block changes to spectate that result in a team imbalance", 0, true, 0.0, true, 1.0);
	cvar_BuddySystem		= CreateConVar("gs_use_buddy_system", "0", "Allow players to choose buddies to try to keep them on the same team", 0, true, 0.0, true, 1.0);
	cvar_Volunteer			= CreateConVar("gs_ab_volunteer", "0", "Ask players of the larger team to volunteer to swap over.", 0, true, 0.0, true, 1.0);
	cvar_VolunteerTime		= CreateConVar("gs_ab_volunteer_time", "15", "Time in seconds the volunteer menu stays on screen.", 0, true, 10.0, true, 90.0);
	cvar_SelectSpectators = CreateConVar("gs_Select_spectators", "60", "During a scramble or force-balance, select spectators who have change to spectator in less time in seconds than this setting, 0 disables", 0, true, 0.0, false);
	cvar_TeamworkProtect	= CreateConVar("gs_teamwork_protect", "1",		"Enable/disable the teamwork protection feature.", 0, true, 0.0, true, 1.0);
	cvar_ForceBalance 		= CreateConVar("gs_force_balance",	"0", 		"Force a balance between each round.", 0, true, 0.0, true, 1.0);
	cvar_TeamSwapBlockImmunity = CreateConVar("gs_teamswitch_immune",	"1",	"Sets if admins (root and ban) are immune from team swap blocking", 0, true, 0.0, true, 1.0);
	cvar_ScrambleImmuneMode = CreateConVar("gs_scramble_immune", "0",		"Sets if admins and people with uber and engie buildings are immune from being scrambled.\n0 = no immunity\n1 = just admins\n2 = charged medics + engineers with buildings\n3 = admins + charged medics and engineers with buildings.", 0, true, 0.0, true, 3.0);
	cvar_SetupRestore		= CreateConVar("gs_setup_reset",	"1", 		"If a scramble happens during setup, restore the setup timer to its starting value", 0, true, 0.0, true, 1.0);
	cvar_ScrambleAdmFlags	= CreateConVar("gs_flags_scramble", "ab",		"Admin flags for scramble protection (if enabled)", 0);
	cvar_BalanceAdmFlags	= CreateConVar("gs_flags_balance",	"ab",		"Admin flags for balance protection (if enabled)", 0);
	cvar_TeamswapAdmFlags	= CreateConVar("gs_flags_teamswap", "bf",		"Admin flags for team swap block protection (if enabled)", 0);
	cvar_NoSequentialScramble = CreateConVar("gs_no_sequential_scramble", "1", "If set, then it will block auto-scrambling from happening two rounds in a row.", 0, true, 0.0, true, 1.0);
	cvar_WaitScramble 		= CreateConVar("gs_prescramble", 	"0", 		"If enabled, teams will scramble at the end of the 'waiting for players' period", 0, true, 0.0, true, 1.0);
	cvar_RoundTime			= CreateConVar("gs_public_roundtime", 	"0",		"If this many seconds or less is left on the round timer, then block public voting.\n0 = disabled.\nConfigure this with the roundtime_blockmode cvar.", 0, true, 0.0, false);
	cvar_RoundTimeMode		= CreateConVar("gs_public_roundtime_blockmode", "0", "How to handle the final public vote if there are less that X seconds left in the round.", 0, true, 0.0, true, 1.0);
	cvar_VoteMode			= CreateConVar("gs_public_votemode",	"0",		"For public chat votes\n0 = if enough triggers, enable scramble for next round.\n1 = if enough triggers, start menu vote to start a scramble\n2 = scramble teams right after the last trigger.", 0, true, 0.0, true, 2.0);
	cvar_PublicNeeded		= CreateConVar("gs_public_triggers", 	"0.60",		"Percentage of people needing to trigger a scramble in chat.", 0, true, 0.05, true, 1.0);
	cvar_VoteEnable 		= CreateConVar("gs_public_votes",	"1", 		"Enable/disable public voting", 0, true, 0.0, true, 1.0);
	cvar_Punish				= CreateConVar("gs_punish_stackers", "0", 		"Punish clients trying to restack teams", 0, true, 0.0, true, 1.0);
	cvar_SortMode			= CreateConVar("gs_sort_mode",		"1",		"Player scramble sort mode.\n1 = Random\n2 = Player Score\n3 = PSPM\n4 = KD\n5 = TopSwap\n13 = Class\n14 = Random Sort", 0, true, 1.0, true, 14.0);
	cvar_RandomSelections 	= CreateConVar("gs_random_selections", "0.55", "Percentage of players to swap during a random scramble", 0, true, 0.1, true, 0.80);
	cvar_TopSwaps			= CreateConVar("gs_top_swaps",		"5",		"Number of top players the top-swap scramble will switch", 0, true, 1.0, false);
	cvar_SetupCharge		= CreateConVar("gs_setup_fill_ubers",		"0",		"If a scramble-now happens during setup time, fill up any medic's uber-charge.", 0, true, 0.0, true, 1.0);
	cvar_ForceTeam 			= CreateConVar("gs_changeblocktime",	"120", 		"Time after being swapped by a scramble where players aren't allowed to change teams", 0, true, 0.0, false);
	cvar_ForceReconnect		= CreateConVar("gs_check_reconnect",	"1",		"The plugin will check if people are reconnecting to the server to avoid being forced on a team.  Requires clientprefs", 0, true, 0.0, true, 1.0);
	cvar_MenuVoteEnd		= CreateConVar("gs_menu_votebehavior",	"0",		"0 =will trigger scramble for round end.\n1 = will scramble teams after vote.", 0, true, 0.0, true, 1.0);
	cvar_Needed 			= CreateConVar("gs_menu_votesneeded", 	"0.60", 	"Percentage of votes for the menu vote scramble needed.", 0, true, 0.05, true, 1.0);
	cvar_Delay 				= CreateConVar("gs_vote_delay", 		"60.0", 	"Time in seconds after the map has started and after a failed vote in which players can votescramble.", 0, true, 0.0, false);
	cvar_VoteDelaySuccess	= CreateConVar("gs_vote_delay2",		"300",		"Time in seconds after a successful scramble in which players can vote again.", 0, true, 0.0, false);
	cvar_AdminBlockVote		= CreateConVar("gs_vote_adminblock",		"0",		"If set, publicly started votes are disabled when an admin is preset.", 0, true, 0.0, true, 1.0);
	cvar_MinPlayers 		= CreateConVar("gs_vote_minplayers",	"1", 		"Minimum poeple connected before any voting will work.", 0, true, 0.0, false);
	cvar_AutoScrambleWinStreak= CreateConVar("gs_winstreak",		"0", 		"If set, it will scramble after a team wins X full rounds in a row", 0, true, 0.0, false);
	cvar_AutoScrambleRoundCount= CreateConVar("gs_scramblerounds", "0",		"If set, it will scramble every X full round", 0, true, 0.0, false, 1.0);
	cvar_AutoScramble		= CreateConVar("gs_autoscramble",	"1", 		"Enables/disables the automatic scrambling.", 0, true, 0.0, true, 1.0);
	cvar_FullRoundOnly 		= CreateConVar("gs_as_fullroundonly",	"0",		"Auto-scramble only after a full round has completed.", 0, true, 0.0, true, 1.0);
	cvar_AutoscrambleVote	= CreateConVar("gs_as_vote",		"0",		"Starts a scramble vote instead of scrambling at the end of a round", 0, true, 0.0, true, 1.0);
	cvar_MinAutoPlayers 	= CreateConVar("gs_as_minplayers", "12", 		"Minimum people connected before automatic scrambles are possible", 0, true, 0.0, false);
	cvar_FragRatio 			= CreateConVar("gs_as_hfragratio", 		"2.0", 		"If a teams wins with a frag ratio greater than or equal to this setting, trigger a scramble.\nSetting this to 0 disables.", 0, true, 0.0, false);
	cvar_Steamroll 			= CreateConVar("gs_as_wintimelimit", 	"120.0", 	"If a team wins in less time, in seconds, than this, and has a frag ratio greater than specified: perform an auto scramble.", 0, true, 0.0, false);
	cvar_SteamrollRatio 	= CreateConVar("gs_as_wintimeratio", 	"1.5", 		"Lower kill ratio for teams that win in less than the wintime_limit.", 0, true, 0.0, false);
	cvar_AvgDiff			= CreateConVar("gs_as_playerscore_avgdiff", "10.0",	"If the average score difference for all players on each team is greater than this, then trigger a scramble.\n0 = skips this check", 0, true, 0.0, false);
	cvar_DominationDiff		= CreateConVar("gs_as_domination_diff",		"10",	"If a team has this many more dominations than the other team, then trigger a scramble.\n0 = skips this check", 0, true, 0.0, false);
	cvar_Koth				= CreateConVar("gs_as_koth_pointcheck",		"0",	"If enabled, trigger a scramble if a team never captures the point in koth mode.", 0, true, 0.0, true, 1.0);
	cvar_ScrLockTeams		= CreateConVar("gs_as_lockteamsbefore", "1", "If enabled, lock the teams between the scramble check and the actual scramble", 0, true, 0.0, true, 1.0);
	cvar_PrintScrambleStats = CreateConVar("gs_as_print_stats", "1", "If enabled, print the scramble stats", 0, true, 0.0, true, 1.0);
	cvar_ScrambleDuelImmunity = CreateConVar("gs_as_dueling_immunity", "0", "If set it 1, grant immunity to duelling players during a scramble", 0, true, 0.0, true, 1.0);
	cvar_LockTeamsFullRound	= CreateConVar("gs_as_lockteamsafter", "0", "If enabled, block team changes after a scramble for the entire next round", 0, true, 0.0, true, 1.0);
	cvar_ScrambleCheckImmune= CreateConVar("gs_scramble_checkummunity_percent", "0.0", "If this percentage or higher of the players are immune from scramble, ignore immunity", 0, true, 0.0, true, 1.0);
	cvar_Silent 			= CreateConVar("gs_silent", "0", 	"Disable most commen chat messages", 0, true, 0.0, true, 1.0);
	cvar_VoteCommand 		= CreateConVar("gs_vote_trigger",	"votescramble", "The trigger for starting a vote-scramble", 0);
	cvar_VoteAd				= CreateConVar("gs_vote_advertise", "500", "How often, in seconds, to advertise the vote command trigger.\n0 disables this", 0, true, 0.0, false);
	cvar_MenuIntegrate 		= CreateConVar("gs_admin_menu",			"1",  "Enable or disable the automatic integration into the admin menu", 0, true, 0.0, true, 1.0);
	cvar_BlockJointeam 		= CreateConVar("gs_block_jointeam",		"0", "If enabled, will block the use of the jointeam and spectate commands and force mp_forceautoteam enabled if it is not enabled", 0, true, 0.0, true, 1.0);
	cvar_OneScramblePerRound= CreateConVar("gs_onescrambleperround", "1", "If enabled, will only allow only allow one scramble per round", 0, true, 0.0, true, 1.0);
	cvar_AutoScrambleEveryRound = CreateConVar("gs_as_every_round", "0", "Force auto-scramble at the end of rounds. 0 = disabled, 1 = every round, 2 = every full round.", 0, true, 0.0, true, 2.0);
	cvar_Version			= CreateConVar("gscramble_version", VERSION, "Gscramble version", FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	RegCommands();
	
	cvar_ForceReconnect.AddChangeHook(handler_ConVarChange);
	cvar_ForceTeam.AddChangeHook(handler_ConVarChange);
	cvar_FullRoundOnly.AddChangeHook(handler_ConVarChange);	
	cvar_Enabled.AddChangeHook(handler_ConVarChange);
	cvar_AutoScramble.AddChangeHook(handler_ConVarChange);
	cvar_VoteMode.AddChangeHook(handler_ConVarChange);
	cvar_Balancer.AddChangeHook(handler_ConVarChange);
	cvar_NoSequentialScramble.AddChangeHook(handler_ConVarChange);
	cvar_SortMode.AddChangeHook(handler_ConVarChange);
	
	cvar_AutoTeamBalance = FindConVar("mp_autoteambalance");
	if (cvar_AutoTeamBalance != null)
	{
		cvar_AutoTeamBalance.AddChangeHook(handler_ConVarChange);
	}
	
	AutoExecConfig(true, "plugin.gscramble");
	LoadTranslations("common.phrases");
	LoadTranslations("gscramble.phrases.txt");
	CheckTranslation();
	CheckExtensions();	
		
	g_iVoters = GetClientCount(false);
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * cvar_PublicNeeded.FloatValue);
	g_bVoteCommandCreated = false;
	g_iPluginStartTime = GetTime();
}

public void OnAllPluginsLoaded()
{
	TopMenu gTopMenu;
	
	if (LibraryExists("adminmenu") && ((gTopMenu = GetAdminTopMenu()) != null))
	{	
		OnAdminMenuReady(gTopMenu);
	}
}

stock void CheckTranslation()
{
	char sPath[257];
	BuildPath(Path_SM, sPath, sizeof(sPath), "translations/gscramble.phrases.txt");
	
	if (!FileExists(sPath))
	{
		SetFailState("Translation file 'gscramble.phrases.txt' is missing.");
	}
}

void RegCommands()
{
	RegAdminCmd("sm_scrambleround", cmd_Scramble, ADMFLAG_GENERIC, "Scrambles at the end of the bonus round");
	RegAdminCmd("sm_cancel", 		cmd_Cancel, ADMFLAG_GENERIC, "Cancels any active scramble, and scramble timer.");
	RegAdminCmd("sm_resetvotes",	cmd_ResetVotes, ADMFLAG_GENERIC, "Resets all public votes.");
	RegAdminCmd("sm_scramble", 		cmd_Scramble_Now, ADMFLAG_GENERIC, "sm_scramble <delay> <respawn> <mode>");
	RegAdminCmd("sm_forcebalance",	cmd_Balance, ADMFLAG_GENERIC, "Forces a team balance if an imbalance exists.");
	RegAdminCmd("sm_scramblevote",	cmd_Vote, ADMFLAG_GENERIC, "Start a vote. sm_scramblevote <now/end>");
	
	AddCommandListener(CMD_Listener, "jointeam");
	AddCommandListener(CMD_Listener, "spectate");
	
	RegConsoleCmd("sm_preference", cmd_Preference);
	RegConsoleCmd("sm_addbuddy",   cmd_AddBuddy);
}

// -------------------------------------------------------------------------------------------------------------------------
// CMD_Listener (jointeam / spectate)
// Description: Intercepts client commands for switching teams or joining spectator.
// Used to enforce the gs_changeblocktime (preventing players from dodging a scramble) 
// and gs_prevent_spec_imbalance (preventing players from ruining team balance by joining spec).
// -------------------------------------------------------------------------------------------------------------------------
public Action CMD_Listener(int client, const char[] command, int argc)
{
	if (StrEqual(command, "jointeam", false) || StrEqual(command, "spectate", false))
	{
		if (client && !IsFakeClient(client))
		{	
			// If full team switching blocks are active
			if (g_bBlockJointeam)
			{
				// Check for admin override rights
				if (cvar_TeamSwapBlockImmunity.BoolValue)
				{				
					char flags[32];
					cvar_TeamswapAdmFlags.GetString(flags, sizeof(flags));
					if (IsAdmin(client, flags))
					{
						CheckBalance(true);
						return Plugin_Continue;
					}
				}
				
				// Allow switching strictly to fix an existing imbalance
				if (TeamsUnbalanced(false)) 
				{
					return Plugin_Continue;
				}
				
				// Block normal switches to Red/Blu
				if (GetClientTeam(client) >= 2)
				{
					PrintToChat(client, "\x01\x04[SM]\x01 %t", "BlockJointeam");
					LogAction(-1, client, "\"%L\" is being blocked from using the %s command due to setting", client, command);
					return Plugin_Handled;				
				}			
			}
			
			if (IsValidTeam(client))
			{
				char sArg[9];
				if (argc)
				{
					GetCmdArgString(sArg, sizeof(sArg));
				}
				
				// Verify if the player is just trying to fix an unbalanced server
				if (StrEqual(sArg, "blue", false) || StrEqual(sArg, "red", false) || StringToInt(sArg) >= 2)
				{
					if (TeamsUnbalanced(false)) 
					{
						return Plugin_Continue;
					}
				}
				
				// Check if the player is serving a block penalty from a recent scramble/balance
				if (IsBlocked(client))
				{
					HandleStacker(client);
					return Plugin_Handled;
				}
				
				// Prevent spec-dodging if it creates an imbalance
				if (StrEqual(command, "spectate", false) || StringToInt(sArg) < 2 || StrContains(sArg, "spec", false) != -1)
				{
					if (cvar_ImbalancePrevent.BoolValue)
					{
						// Simulates the team sizes if the player left. Blocks if the difference is too high.
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
						// Track exactly when they joined spec so they can be prioritized for force-balance
						g_aPlayers[client][iSpecChangeTime] = GetTime();
					}
				}
			}
		}
	}
	return Plugin_Continue;
}

// -------------------------------------------------------------------------------------------------------------------------
// CheckExtensions
// Description: Verifies the game is TF2 and prepares the ClientPrefs extension. 
// ClientPrefs handles "cookies" used to permanently tag players who disconnect 
// to avoid an autobalance, allowing the plugin to force them back to their old team upon returning.
// -------------------------------------------------------------------------------------------------------------------------
void CheckExtensions()
{
	char sMod[14];
	GetGameFolderName(sMod, sizeof(sMod));
	if (!StrEqual(sMod, "tf", false))
	{
		SetFailState("This plugin only works on Team Fortress 2");
	}
	
	char sExtError[256];
	int iExtStatus;
	iExtStatus = GetExtensionFileStatus("clientprefs.ext", sExtError, sizeof(sExtError));
	switch (iExtStatus)
	{
		case -1: LogAction(-1, 0, "Optional extension clientprefs failed to load.");
		case 0:
		{
			LogAction(-1, 0, "Optional extension clientprefs is loaded with errors.");
			LogAction(-1, 0, "Status reported was [%s].", sExtError);	
		}
		case -2: LogAction(-1, 0, "Optional extension clientprefs is missing.");
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
	
	// Register the tracking cookies
	if (g_bUseClientPrefs)
	{
		g_cookie_timeBlocked = new Cookie("time blocked", "time player was blocked", CookieAccess_Private);
		g_cookie_serverIp = new Cookie("server_id", "ip of the server", CookieAccess_Private);
		g_cookie_teamIndex = new Cookie("team index", "index of the player's team", CookieAccess_Private);
		g_cookie_serverStartTime = new Cookie("start time", "time the plugin was loaded", CookieAccess_Private);
	}
}

public Action cmd_AddBuddy(int client, int args)
{
	if (!g_bUseBuddySystem)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "BuddyDisabledError");
		return Plugin_Handled;
	}
	if (args == 1)
	{
		char target_name[MAX_NAME_LENGTH+1], arg[32];
		int target_list[1];
		bool tn_is_ml;
		GetCmdArgString(arg, sizeof(arg));
		
		if (ProcessTargetString(
			arg, client, target_list, MAXPLAYERS, 
			COMMAND_FILTER_NO_IMMUNITY|COMMAND_FILTER_NO_MULTI,
			target_name, sizeof(target_name), tn_is_ml) == 1)
		{
			AddBuddy(client, target_list[0]);
		}
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

public Action cmd_Preference(int client, int args)
{
	if (!g_bHooked)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "EnableReply");
		return Plugin_Handled;
	}	
	
	if (!cvar_Preference.BoolValue)
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
	
	char TeamStr[10];
	GetCmdArgString(TeamStr, sizeof(TeamStr));
	
	if (StrContains(TeamStr, "red", false) != -1)
	{
		g_aPlayers[client][iTeamPreference] = TEAM_RED;
		ReplyToCommand(client, "RED");
		return Plugin_Handled;
	}
	
	if (StrContains(TeamStr, "blu", false) != -1)
	{
		g_aPlayers[client][iTeamPreference] = TEAM_BLUE;
		ReplyToCommand(client, "BLU");
		return Plugin_Handled;
	}
	
	if (StrContains(TeamStr, "clear", false) != -1)
	{
		g_aPlayers[client][iTeamPreference] = 0;
		ReplyToCommand(client, "CLEARED");
		return Plugin_Handled;
	}
	
	ReplyToCommand(client, "Usage: sm_preference <TEAM|CLEAR>");
	return Plugin_Handled;
}

public void OnPluginEnd() 
{
	if (g_bAutoBalance)
	{
		ServerCommand("mp_autoteambalance 1");
	}
}

// -------------------------------------------------------------------------------------------------------------------------
// AskPluginLoad2 & Timer_load
// Description: Prepares the plugin if it was reloaded dynamically mid-game by a server admin.
// Rebuilds the voter pool and natively registers functions for external use.
// -------------------------------------------------------------------------------------------------------------------------
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
	if (late)
	{
		CreateTimer(1.0, Timer_load);
	}
		
	CreateNative("GS_IsClientTeamChangeBlocked", Native_GS_IsBlocked);
	MarkNativeAsOptional("RegClientCookie");
	MarkNativeAsOptional("SetClientCookie");
	MarkNativeAsOptional("GetClientCookie");
	RegPluginLibrary("gscramble");
	
	return APLRes_Success;
}

public Action Timer_load(Handle timer)
{
	g_RoundState = roundNormal;
	CreateTimer(1.0, Timer_GetTime);
	
	// Manually construct the total voter pool if loaded late
	updateVoters();
	return Plugin_Handled;
}

void updateVoters()
{
	g_iVoters = 0;
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			g_iVoters++;
		}
	}
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * cvar_PublicNeeded.FloatValue);
}

// -------------------------------------------------------------------------------------------------------------------------
// IsBlocked & HandleStacker
// Description: Determines if a client is currently restricted from swapping teams
// based on active scrambles, or active post-scramble cooldowns. HandleStacker applies warnings
// and potentially punishes players actively trying to bypass the lock to stack a team.
// -------------------------------------------------------------------------------------------------------------------------
bool IsBlocked(int client)
{
	if (!g_bForceTeam) return false;
	
	if (g_bTeamsLocked)
	{
		char flags[32];
		cvar_TeamswapAdmFlags.GetString(flags, sizeof(flags));
		
		if (IsAdmin(client, flags)) return false;
		
		return true;
	}
	
	if (g_aPlayers[client][iBlockTime] > GetTime()) return true;
	
	return false;
}

void HandleStacker(int client)
{
	// Give them two grace warnings before fully locking them down
	if (g_aPlayers[client][iBlockWarnings] < 2) 
	{
		char clientName[MAX_NAME_LENGTH + 1];
		GetClientName(client, clientName, 32);
		LogAction(client, -1, "\"%L\" was blocked from changing teams", client);
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "BlockSwitchMessage");
		
		if (!g_bSilent)
		{
			PrintToChatAll("\x01\x04[SM]\x01 %t", "ShameMessage", clientName);
		}
		
		g_aPlayers[client][iBlockWarnings]++;
	}	
	
	// Add punishment time onto their block timer if configured
	if (cvar_Punish.BoolValue)	
	{
		SetupTeamSwapBlock(client);
	}
}

public int Native_GS_IsBlocked(Handle plugin, int numParams)
{
	int client = GetNativeCell(1);
	int initiator = GetNativeCell(2);
	
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

stock void CreateVoteCommand()
{
	if (!g_bVoteCommandCreated)
	{
		char sCommand[256];		
		cvar_VoteCommand.GetString(sCommand, sizeof(sCommand));
		ExplodeString(sCommand, ",", g_sVoteCommands, 3, sizeof(g_sVoteCommands[]));
		for (int i=0; i < 3; i++)
		{
			if (strlen(g_sVoteCommands[i]) > 2)
			{
				g_bVoteCommandCreated = true;
				RegConsoleCmd(g_sVoteCommands[i], CMD_VoteTrigger);
			}
		}		
	}
}

public Action CMD_VoteTrigger(int client, int args)
{
	if (!IsFakeClient(client))
	{
		AttemptScrambleVote(client);
	}
	return Plugin_Handled;
}

public void OnConfigsExecuted()
{
	CreateVoteCommand();
	
	char sMapName[32];
	bool bAuto = false;
	GetCurrentMap(sMapName, 32);
	cvar_Version.SetString(VERSION);

	g_bSelectSpectators = cvar_SelectSpectators.BoolValue;
	g_bSilent = cvar_Silent.BoolValue;
	g_bAutoBalance = cvar_Balancer.BoolValue;
	g_bFullRoundOnly = cvar_FullRoundOnly.BoolValue;
	g_bForceTeam = cvar_ForceTeam.BoolValue;
	g_iForceTime = cvar_ForceTeam.IntValue;
	g_bAutoScramble = cvar_AutoScramble.BoolValue;
	cvar_MenuVoteEnd.IntValue ? (g_iDefMode = Scramble_Now) : (g_iDefMode = Scramble_Round);
	g_bNoSequentialScramble = cvar_NoSequentialScramble.BoolValue;
	g_bUseBuddySystem = cvar_BuddySystem.BoolValue;
	
	if (g_bUseClientPrefs)
	{
		g_bForceReconnect = cvar_ForceReconnect.BoolValue;
	}
	
	if (cvar_Enabled.BoolValue)
	{
		if (g_bAutoBalance)
		{
			if (FindConVar("mp_autoteambalance").BoolValue)
			{
				LogAction(-1, 0, "set mp_autoteambalance to false");
				FindConVar("mp_autoteambalance").SetBool(false);
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
	
	if (cvar_AutoScramble.BoolValue || cvar_AutoScrambleWinStreak.BoolValue)
	{
		bAuto = true;
	}
	
	if (cvar_AutoScrambleRoundCount.BoolValue)
	{
		bAuto = true;
		g_iRoundTrigger = cvar_AutoScrambleRoundCount.IntValue;
	}
	
	if (bAuto)
	{
		if (FindConVar("mp_scrambleteams_auto").BoolValue)
		{
			FindConVar("mp_scrambleteams_auto").SetBool(false);
			LogMessage("Setting mp_scrambleteams_auto false");
		}
		if (FindConVar("sv_vote_issue_scramble_teams_allowed").BoolValue)
		{
			FindConVar("sv_vote_issue_scramble_teams_allowed").SetBool(false);
			LogMessage("Setting 'sv_vote_issue_scramble_teams_allowed' to '0'");
		}
	}
	
	if (cvar_Koth.BoolValue && strncmp(sMapName, "koth_", 5, false) == 0)
	{
		g_bRedCapped = false;
		g_bBluCapped = false;
		g_bKothMode = true;
	}
	else if (strncmp(sMapName, "arena_", 6, false) == 0)
	{
		if (FindConVar("tf_arena_use_queue").BoolValue)
		{
			if (g_bHooked)
			{
				LogAction(-1, 0, "Unhooking events since it's arena, and tf_arena_use_queue is enabled");
				unHook();
			}
			g_bArenaMode = true;
		}
	}
	
	if (!cvar_MenuIntegrate.BoolValue)
	{
		if (g_hAdminMenu != null && g_Category != INVALID_TOPMENUOBJECT)
		{			
			RemoveFromTopMenu(g_hAdminMenu, g_Category);
			g_hAdminMenu = null;
			g_Category = INVALID_TOPMENUOBJECT;
		}
	}
	
	if (g_hVoteAdTimer != null)
	{
		KillTimer(g_hVoteAdTimer);
		g_hVoteAdTimer = null;
	}
	
	float fAd = cvar_VoteAd.FloatValue;
	if (fAd > 0.0)
	{
		g_hVoteAdTimer = CreateTimer(fAd, Timer_VoteAd, _, TIMER_REPEAT);
	}
	
	if (cvar_BlockJointeam.BoolValue)
	{
		g_bBlockJointeam = true;
		FindConVar("mp_forceautoteam").SetBool(true);
	}
	else
	{
		g_bBlockJointeam = false;
	}
}

public Action Timer_VoteAd(Handle timer)
{
	char sVotes[120];
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

public void handler_ConVarChange(ConVar convar, const char[] oldValue, const char[] newValue)
{
	int iNewValue = StringToInt(newValue);
	if (convar == cvar_Enabled)
	{
		bool teamBalance;
		
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
		
		if (cvar_Balancer.BoolValue)
		{		
			FindConVar("mp_autoteambalance").SetBool(teamBalance);	
			LogAction(0, -1, "set conVar mp_autoteambalance to %i.", teamBalance);
		}
	}
	
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
	
	if (convar == cvar_AutoTeamBalance)
	{
		if (g_bHooked && g_bAutoBalance)
		{
			if (StringToInt(newValue))
			{
				LogMessage("Something tried to enable the built in balancer with gs_autobalance still enabled.");
				convar.SetBool(false);
				LogAction(0, -1, "Setting mp_autoteambalance back to 0");
			}
		}
	}
}

void hook()
{
	LogAction(0, -1, "Hooking events.");
	HookEvent("teamplay_round_start", 		Event_RoundStart, EventHookMode_PostNoCopy);
	HookEvent("player_disconnect", Event_PlayerDisconnect, EventHookMode_Post);
	HookEvent("teamplay_round_win", 		Event_RoundWin, EventHookMode_Post);
	HookEvent("teamplay_round_active",		Event_RoundActive);
	HookEvent("teamplay_pre_round_time_left", Event_SetupActive);
	HookEvent("teamplay_setup_finished", 	hook_Setup, EventHookMode_PostNoCopy);
	HookEvent("player_death", 				Event_PlayerDeath_Pre, EventHookMode_Pre);
	HookEvent("game_start", 				hook_Event_GameStart);
	HookEvent("teamplay_restart_round", 	hook_Event_TFRestartRound);
	HookEvent("player_team",				Event_PlayerTeam_Pre, EventHookMode_Pre);
	HookEvent("teamplay_round_stalemate",	hook_RoundStalemate, EventHookMode_PostNoCopy);
	HookEvent("teamplay_point_captured", 	hook_PointCaptured, EventHookMode_Post);
	HookEvent("object_destroyed", 			hook_ObjectDestroyed, EventHookMode_Post);
	HookEvent("teamplay_flag_event",		hook_FlagEvent, EventHookMode_Post);
	HookEvent("teamplay_pre_round_time_left",hookPreRound, EventHookMode_PostNoCopy);
	HookEvent("teamplay_capture_blocked", Event_capture_blocked);
	HookEvent("player_extinguished", Event_player_extinguished);
	
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook_Class, false);
	AddGameLogHook(LogHook);
	
	HookEvent("teamplay_game_over", hook_GameEnd, EventHookMode_PostNoCopy);
	HookEvent("player_chargedeployed", hook_UberDeploy, EventHookMode_Post);
	HookEvent("player_sapped_object", hook_Sapper, EventHookMode_Post);
	HookEvent("medic_death", hook_MedicDeath, EventHookMode_Post);
	HookEvent("controlpoint_endtouch", hook_EndTouch, EventHookMode_Post);	
	HookEvent("teamplay_timer_time_added", TimerUpdateAdd, EventHookMode_PostNoCopy);
	g_bHooked = true;
}

public Action LogHook(const char[] message)
{
	if (g_bBlockDeath)
	{
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

void unHook()
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
	RemoveGameLogHook(LogHook);
	
	UnhookEvent("player_chargedeployed", hook_UberDeploy, EventHookMode_Post);
	UnhookEvent("player_sapped_object", hook_Sapper, EventHookMode_Post);
	UnhookEvent("medic_death", hook_MedicDeath, EventHookMode_Post);
	UnhookEvent("controlpoint_endtouch", hook_EndTouch, EventHookMode_Post);
	UnhookEvent("teamplay_timer_time_added", TimerUpdateAdd, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_pre_round_time_left",hookPreRound, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_capture_blocked", Event_capture_blocked);
	UnhookEvent("player_extinguished", Event_player_extinguished);
	UnhookEvent("teamplay_round_active",		Event_RoundActive);
	UnhookEvent("teamplay_pre_round_time_left", Event_SetupActive);

	g_bHooked = false;
}

public void Event_SetupActive(Event event, const char[] name, bool dontBroadcast)
{
	g_RoundState = setup;
}

public void Event_RoundActive(Event event, const char[] name, bool dontBroadcast)
{
	g_RoundState = roundNormal;
}

// -------------------------------------------------------------------------------------------------------------------------
// Teamwork Interaction Hooks
// Description: The following functions handle objective play. When a player actively contributes 
// to the map objective (capping points, sapping, dropping ubers, healing), they are granted 
// temporary immunity from autobalance via the AddTeamworkTime function.
// -------------------------------------------------------------------------------------------------------------------------
public void Event_player_extinguished(Event event, const char[] name, bool dontBroadcast)
{
	int healer = GetClientOfUserId(event.GetInt("healer"));
	int victim = GetClientOfUserId(event.GetInt("victim"));
	if (!healer || !victim) return;
	AddTeamworkTime(healer, playerExtinguish);
}

public void Event_capture_blocked(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("blocker");
	if (client && g_RoundState == roundNormal)
	{
		AddTeamworkTime(client, controlPointBlock);
	}
}

public void hook_MedicDeath(Event event, const char[] name, bool dontBroadcast)
{
	if (g_RoundState == roundNormal && event.GetBool("charged"))
	{
		AddTeamworkTime(GetClientOfUserId(event.GetInt("userid")), medicKill);
	}
}

public void hookPreRound(Event event, const char[] name, bool dontBroadcast)
{
	g_RoundState = preGame;
}

public void hook_EndTouch(Event event, const char[] name, bool dontBroadcast)
{
	if (g_RoundState == roundNormal)
	{
		AddTeamworkTime(event.GetInt("player"), controlPointTouch);
	}
}
	
public void hook_Sapper(Event event, const char[] name, bool dontBroadcast)
{
	if (g_RoundState == roundNormal)
	{
		AddTeamworkTime(GetClientOfUserId(event.GetInt("userid")), placeSapper);
	}
}

public void hook_UberDeploy(Event event, const char[] name, bool dontBroadcast)
{
	if (g_RoundState == roundNormal)
	{
		int medic = GetClientOfUserId(event.GetInt("userid")), target = GetClientOfUserId(event.GetInt("targetid"));
		AddTeamworkTime(medic, medicDeploy);
		AddTeamworkTime(target, medicDeploy);
	}
}

public void hook_ObjectDestroyed(Event event, const char[] name, bool dontBroadcast)
{
	if (g_RoundState == roundNormal && event.GetInt("objecttype") == 3)
	{
		int client = GetClientOfUserId(event.GetInt("attacker")), assister = GetClientOfUserId(event.GetInt("assister"));
		AddTeamworkTime(client, buildingKill);
		AddTeamworkTime(assister, buildingKill);	
	}
}

public void hook_GameEnd(Event event, const char[] name, bool dontBroadcast)
{
	g_RoundState = mapEnding;
}

public void hook_PointCaptured(Event event, const char[] name, bool dontBroadcast)
{
	if (cvar_BalanceTimeLimit.BoolValue)
		GetRoundTimerInformation(true);
	if (cvar_TeamworkProtect.BoolValue)
	{
		char cappers[128];
		event.GetString("cappers", cappers, sizeof(cappers));

		int len = strlen(cappers);
		for (int i = 0; i < len; i++)
		{
			AddTeamworkTime(cappers[i], controlPointCaptured);
		}
	}
	
	if (g_bKothMode)
	{
		event.GetInt("team") == TEAM_RED ? (g_bRedCapped = true) : (g_bBluCapped = true);
	}
}

public void hook_RoundStalemate(Event event, const char[] name, bool dontBroadcast)
{
	if (cvar_ForceBalance.BoolValue && g_aTeams[bImbalanced])
	{	
		BalanceTeams(true);	
	}
	
	g_RoundState = suddenDeath;
}

public void hook_FlagEvent(Event event, const char[] name, bool dontBroadcast)
{
	int client = event.GetInt("player");
	int type = event.GetInt("eventtype");
	
	switch (type)
	{
		case 1: g_aPlayers[client][bHasFlag] = true;
		default: g_aPlayers[client][bHasFlag] = false;
	}	
	AddTeamworkTime(event.GetInt("player"), flagEvent);
}

public Action Event_PlayerTeam_Pre(Event event, const char[] name, bool dontBroadcast)
{
	if (g_bBlockDeath)
	{
		event.BroadcastDisabled = true;
		return Plugin_Continue;
	}
	CheckBalance(true);	
	return Plugin_Continue;
}	

public void hook_Event_TFRestartRound(Event event, const char[] name, bool dontBroadcast)
{
	g_iCompleteRounds = 0;	
}

public void hook_Event_GameStart(Event event, const char[] name, bool dontBroadcast)
{
	g_aTeams[iRedFrags] = 0;
	g_aTeams[iBluFrags] = 0;
	g_iCompleteRounds = 0;
	g_RoundState = preGame;
	g_aTeams[iRedWins] = 0;
	g_aTeams[iBluWins] = 0;
}

public void OnClientDisconnect(int client)
{
	if (IsFakeClient(client)) return;
	
	g_aPlayers[client][bHasFlag] = false;
	if (g_aPlayers[client][bHasVoted] == true)
	{
		g_iVotes--;
		g_aPlayers[client][bHasVoted] = false;
	}
	
	updateVoters();
	g_aPlayers[client][iTeamPreference] = 0;
	
	if (cvar_AdminBlockVote.BoolValue && g_aPlayers[client][bIsVoteAdmin])
	{
		g_iNumAdmins--;
	}
}

// -------------------------------------------------------------------------------------------------------------------------
// Event_PlayerDisconnect & OnClientCookiesCached
// Description: Core of the anti-dodge system. If a player is locked on a team (due to a recent autobalance or scramble)
// and disconnects, their steamid, ip, and current team are stored. If they return within the block time, 
// they are forced right back onto the team they tried to escape from.
// -------------------------------------------------------------------------------------------------------------------------
public Action Event_PlayerDisconnect(Event event, const char[] name, bool dontBroadcast)
{
	CheckBalance(true);
	int client = GetClientOfUserId(event.GetInt("userid"));
	if (client && !IsFakeClient(client))
	{		
		if (g_bUseClientPrefs && g_bForceTeam && g_bForceReconnect && IsClientInGame(client) && IsValidTeam(client) && (g_bTeamsLocked || IsBlocked(client)))
		{
			char blockTime[128], teamIndex[5], serverIp[50], serverPort[10], startTime[33];
			int iIndex;
			
			FindConVar("hostip").GetString(serverIp, sizeof(serverIp));
			FindConVar("hostport").GetString(serverPort, sizeof(serverPort));
			Format(serverIp, sizeof(serverIp), "%s%s", serverIp, serverPort);
			IntToString(GetTime(), blockTime, sizeof(blockTime));
			IntToString(g_iPluginStartTime, startTime, sizeof(startTime));
			
			if (g_iTeamIds[1] == GetClientTeam(client))
			{
				iIndex = 1;
			}
			
			IntToString(iIndex, teamIndex, sizeof(teamIndex));
			if (AreClientCookiesCached(client))
			{
				g_cookie_timeBlocked.Set(client, blockTime);
				g_cookie_teamIndex.Set(client, teamIndex);
				g_cookie_serverIp.Set(client, serverIp);
				g_cookie_serverStartTime.Set(client, startTime);
			}
			LogAction(client, -1, "\"%L\" is team swap blocked, and is being saved.", client);
		}
		if (g_bUseBuddySystem)
		{
			for (int i = 1; i <= MaxClients; i++)
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
	return Plugin_Continue;
}

public void OnClientPostAdminCheck(int client)
{
	if(IsFakeClient(client)) return;
		
	if (cvar_Preference.BoolValue && g_bAutoBalance && g_bHooked)
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
	
	if (cvar_AdminBlockVote.BoolValue && CheckCommandAccess(client, "sm_scramblevote", ADMFLAG_BAN))
	{
		g_aPlayers[client][bIsVoteAdmin] = true;
		g_iNumAdmins++;
	}
	else 
	{
		g_aPlayers[client][bIsVoteAdmin] = false;
	}
	
	g_aPlayers[client][bHasVoted] = false;
	updateVoters();
}

public void OnClientCookiesCached(int client)
{
	if (!IsClientConnected(client) || IsFakeClient(client) || !g_bForceTeam || !g_bForceReconnect)
	{
		return;
	}
	
	g_aPlayers[client][iBlockWarnings] = 0;
	char sStartTime[33];
	g_cookie_serverStartTime.Get(client, sStartTime, sizeof(sStartTime));
	
	if (StringToInt(sStartTime) != g_iPluginStartTime) return;
	
	char timeStr[32], clientServerIp[33], serverIp[100], serverPort[100];
	int iTime;
	FindConVar("hostip").GetString(serverIp, sizeof(serverIp));
	FindConVar("hostport").GetString(serverPort, sizeof(serverPort));
	Format(serverIp, sizeof(serverIp), "%s%s", serverIp, serverPort);
	
	g_cookie_timeBlocked.Get(client, timeStr, sizeof(timeStr));
	g_cookie_serverIp.Get(client, clientServerIp, sizeof(clientServerIp));
	
	if ((iTime = StringToInt(timeStr)) && strncmp(clientServerIp, serverIp, strlen(serverIp), true) == 0)
	{
		if (iTime > g_iMapStartTime && (GetTime() - iTime) <= cvar_ForceTeam.IntValue)
		{
			LogAction(client, -1, "\"%L\" is reconnect blocked", client);
			SetupTeamSwapBlock(client);
			CreateTimer(10.0, timer_Restore, GetClientUserId(client));
		}
	}   
}

public Action Timer_PrefAnnounce(Handle timer, any id)
{
	int client;
	if ((client = GetClientOfUserId(id)))
	{
		PrintToChat(client, "\x01\x04[SM]\x01 %t", "PrefAnnounce");
	}
	return Plugin_Handled;
}

public Action timer_Restore(Handle timer, any id)
{
	int client;
	if (!(client = GetClientOfUserId(id)) || !IsClientInGame(client))
	{
		return Plugin_Handled;
	}
	
	char sIndex[10]; int iIndex;
	g_cookie_teamIndex.Get(client, sIndex, sizeof(sIndex));
	iIndex = StringToInt(sIndex);
	
	if (iIndex != 0 && iIndex != 1) return Plugin_Handled;
	
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

void AddTeamworkTime(int client, eTeamworkReasons reason)
{
	if (!cvar_TeamworkProtect.BoolValue) return;
	if (g_RoundState == roundNormal && client && IsClientInGame(client) && !IsFakeClient(client))
	{
		int iTime;
		switch (reason)
		{
			case flagEvent: iTime = cvar_TeamWorkFlagEvent.IntValue;
			case medicKill: iTime = cvar_TeamWorkMedicKill.IntValue;
			case medicDeploy: iTime = cvar_TeamWorkUber.IntValue;
			case buildingKill: iTime = cvar_TeamWorkBuildingKill.IntValue;
			case placeSapper: iTime = cvar_TeamWorkPlaceSapper.IntValue;
			case controlPointCaptured: iTime = cvar_TeamWorkCpCapture.IntValue;
			case controlPointTouch: iTime = cvar_TeamWorkCpTouch.IntValue;
			case controlPointBlock: iTime = cvar_TeamWorkCpBlock.IntValue;
			case playerExtinguish: iTime = cvar_TeamWorkExtinguish.IntValue;
		}
		g_aPlayers[client][iTeamworkTime] = GetTime()+iTime;
	}
}

public void OnMapStart()
{
	g_iMapStartTime = GetTime();
	g_iImmunityDisabledWarningTime = 0;
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
	
	if (g_hBalanceFlagTimer != null)
	{
		KillTimer(g_hBalanceFlagTimer);
		g_hBalanceFlagTimer = null;	
	}
	if (g_hForceBalanceTimer != null)
	{
		KillTimer(g_hForceBalanceTimer);
		g_hForceBalanceTimer = null;
	}
	g_hCheckTimer = null;
	if (g_hScrambleNowPack != null)
	{
		delete g_hScrambleNowPack;
	}
	g_hScrambleNowPack = null;
	g_iLastRoundWinningTeam = 0;
}

public void OnMapEnd()
{
	if (g_hScrambleDelay != null) KillTimer(g_hScrambleDelay);		
	g_hScrambleDelay = null;	
}

public Action TimerEnable(Handle timer)
{
	g_bVoteAllowed = true;
	g_hVoteDelayTimer = null;
	return Plugin_Handled;
}

public Action cmd_ResetVotes(int client, int args)
{
	PerformVoteReset(client);
	return Plugin_Handled;
}

void PerformVoteReset(int client)
{
	LogAction(client, -1, "\"%L\" has reset all the public votes", client);
	ShowActivity(client, "%t", "AdminResetVotes");
	ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ResetReply", g_iVotes);
	
	for (int i = 1; i <= MaxClients; i++)
	{
		g_aPlayers[i][bHasVoted] = false;
	}
	g_iVotes = 0;
}

public Action cmd_Balance(int client, int args) 
{
	PerformBalance(client);
	return Plugin_Handled;
}

void PerformBalance(int client)
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

float GetAvgScoreDifference(int team)
{
	int teamScores, otherScores;
	float otherAvg, teamAvg;
	
	for (int i = 1; i <= MaxClients; i++)
	{
		int entity = GetPlayerResourceEntity();
		int Totalscore = GetEntProp(entity, Prop_Send, "m_iScore", _, i); 
		
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
	teamAvg = float(teamScores) / float(GetTeamClientCount(team));
	otherAvg = float(otherScores) / float(GetTeamClientCount(team == TEAM_RED ? TEAM_BLUE : TEAM_RED));
	
	if (otherAvg > teamAvg)
	{
		return 0.0;
	}
	return FloatAbs(teamAvg - otherAvg);
}

public Action cmd_Scramble_Now(int client, int args)
{
	if (args > 3)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NowCommandReply");
		return Plugin_Handled;
	}
	
	float fDelay = 5.0; bool respawn = true; e_ScrambleModes mode;
	
	if (args)
	{
		char arg1[5];
		GetCmdArg(1, arg1, sizeof(arg1));
		if((fDelay = StringToFloat(arg1)) == 0.0)
		{
			ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NowCommandReply");
			return Plugin_Handled;
		}
		
		if (args > 1)
		{
			char arg2[2];
			GetCmdArg(2, arg2, sizeof(arg2));
			if (!StringToInt(arg2)) respawn = false;
		}
		
		if (args > 2)
		{
			char arg3[2];
			GetCmdArg(3, arg3, sizeof(arg3));
			if ((mode = view_as<e_ScrambleModes>(StringToInt(arg3))) > randomSort)
			{
				ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NowCommandReply");
				return Plugin_Handled;
			}
		}			
	}
	
	PerformScrambleNow(client, fDelay, respawn, mode);
	return Plugin_Handled;
}

stock void PerformScrambleNow(int client, float fDelay = 5.0, bool respawn = false, e_ScrambleModes mode = invalid)
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
		if (g_hScrambleDelay != null)
		{
			KillTimer(g_hScrambleDelay);
			g_hScrambleDelay = null;
		}
	}
	
	LogAction(client, -1, "\"%L\" performed the scramble command", client);
	ShowActivity(client, "%t", "AdminScrambleNow");
	StartScrambleDelay(fDelay, respawn, mode);
}

// -------------------------------------------------------------------------------------------------------------------------
// AttemptScrambleVote
// Description: Validates and processes a chat trigger (e.g., !scramble). Calculates if the required
// threshold of voters has been reached based on g_iVotesNeeded. Allows overriding the round timer
// block if configured in cvars.
// -------------------------------------------------------------------------------------------------------------------------
stock void AttemptScrambleVote(int client)
{	
	if (g_bArenaMode)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ArenaReply");
		return;
	}
	if (cvar_AdminBlockVote.BoolValue && g_iNumAdmins > 0)
	{
		ReplyToCommand(client, "\x01x04[SM] %t", "AdminBlockVoteReply");
		return;
	}
	if (!g_bHooked)
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "EnableReply");
		return;
	}	
	
	bool Override = false;
	if (!cvar_VoteEnable.BoolValue)
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
	if (g_iVotesNeeded - g_iVotes == 1 && cvar_VoteMode.IntValue == 1 && IsVoteInProgress())
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "Vote in Progress");
		return;
	}	
	if (cvar_MinPlayers.IntValue > g_iVoters)
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
	if (g_RoundState == roundNormal && g_bRoundIsTimed && cvar_RoundTime.BoolValue && g_bIsTimer && g_iVotesNeeded - g_iVotes == 1)
	{
		int iRoundLimit = cvar_RoundTime.IntValue;
		if (RoundFloat((g_fRoundEndTime - GetGameTime())) - iRoundLimit <= 0)
		{
			if (cvar_RoundTimeMode.BoolValue)
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
	
	char clientName[MAX_NAME_LENGTH + 1];
	GetClientName(client, clientName, 32);
	PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteTallied", clientName, g_iVotes, g_iVotesNeeded);
	
	if (g_iVotes >= g_iVotesNeeded && !g_bScrambleNextRound)
	{
		if (cvar_VoteMode.IntValue == 1)
		{
			StartScrambleVote(g_iDefMode);		
		}
		else if (cvar_VoteMode.IntValue == 0)
		{			
			g_bScrambleNextRound = true;
			if (!g_bSilent)
				PrintToChatAll("\x01\x04[SM]\x01 %t", "ScrambleRound");
		}
		else if (!Override && cvar_VoteMode.IntValue == 2)
		{
			StartScrambleDelay(5.0, true);	
		}
		DelayPublicVoteTriggering();
	}
}	

public Action cmd_Vote(int client, int args)
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
	
	char arg[16];
	GetCmdArg(1, arg, sizeof(arg));
	ScrambleTime mode;
	
	if (StrEqual(arg, "now", false)) mode = Scramble_Now;
	else if (StrEqual(arg, "end", false)) mode = Scramble_Round;
	else
	{
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "InvalidArgs");
		return Plugin_Handled;
	}
	
	PerformVote(client, mode);
	return Plugin_Handled;
}

void PerformVote(int client, ScrambleTime mode)
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
	if (cvar_MinPlayers.IntValue > g_iVoters)
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

void StartScrambleVote(ScrambleTime mode, int time=20)
{
	if (IsVoteInProgress())
	{
		PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteWillStart");
		CreateTimer(1.0, Timer_ScrambleVoteStarter, mode, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	
	DelayPublicVoteTriggering();
	g_hScrambleVoteMenu = new Menu(Handler_VoteCallback, view_as<MenuAction>(MENU_ACTIONS_ALL));
	
	char sTmpTitle[64];
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
	
	g_hScrambleVoteMenu.SetTitle(sTmpTitle);
	g_hScrambleVoteMenu.AddItem("1", "Yes");
	g_hScrambleVoteMenu.AddItem("2", "No");
	g_hScrambleVoteMenu.ExitButton = false;
	g_hScrambleVoteMenu.DisplayVoteToAll(time);
}

public Action Timer_ScrambleVoteStarter(Handle timer, any mode)
{
	if (IsVoteInProgress())
	{
		return Plugin_Continue;
	}
	
	StartScrambleVote(view_as<ScrambleTime>(mode), 15);
	return Plugin_Stop;
}

public int Handler_VoteCallback(Menu menu, MenuAction action, int param1, int param2)
{
	DelayPublicVoteTriggering();
	
	if (action == MenuAction_End)
	{
		delete g_hScrambleVoteMenu;
		g_hScrambleVoteMenu = null;
	}		
	
	if (action == MenuAction_VoteEnd)
	{	
		int i_winningVotes, i_totalVotes;
		GetMenuVoteInfo(param2, i_winningVotes, i_totalVotes);
		
		if (param1 == 1)
		{
			i_winningVotes = i_totalVotes - i_winningVotes;
		}
		
		float comp = float(i_winningVotes) / float(i_totalVotes);
		float comp2 = cvar_Needed.FloatValue;
		if (comp >= comp2)
		{
			PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteWin", RoundToNearest(comp*100.0), i_totalVotes);	
			LogAction(-1 , 0, "%T", "VoteWin", LANG_SERVER, RoundToNearest(comp*100.0), i_totalVotes);	
			
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
			int against = 100 - RoundToNearest(comp*100.0);
			PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteFailed", against, i_totalVotes);
			LogAction(-1 , 0, "%T", "VoteFailed", LANG_SERVER, against, i_totalVotes);
		}
	}
	return 0;
}

void DelayPublicVoteTriggering(bool success = false)
{
	if (cvar_VoteEnable.BoolValue)
	{
		for (int i = 0; i <= MaxClients; i++)	
		{
			g_aPlayers[i][bHasVoted] = false;
		}
		
		g_iVotes = 0;
		g_bVoteAllowed = false;
		
		if (g_hVoteDelayTimer != null)
		{
			KillTimer(g_hVoteDelayTimer);
			g_hVoteDelayTimer = null;
		}
		
		float fDelay;
		if (success)
		{
			fDelay = cvar_VoteDelaySuccess.FloatValue;
		}
		else
		{
			fDelay = cvar_Delay.FloatValue;
		}
		
		g_hVoteDelayTimer = CreateTimer(fDelay, TimerEnable, TIMER_FLAG_NO_MAPCHANGE);
	}
}

public Action cmd_Scramble(int client, int args)
{
	SetupRoundScramble(client);
	return Plugin_Handled;
}

public Action cmd_Cancel(int client, int args)
{
	PerformCancel(client);
	return Plugin_Handled;
}

void PerformCancel(int client)
{
	if (g_bScrambleNextRound || g_hScrambleDelay != null)
	{
		g_bScrambleNextRound = false;
		
		if (g_hScrambleDelay != null)
		{
			KillTimer(g_hScrambleDelay);
			g_hScrambleDelay = null;
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

void SetupRoundScramble(int client)
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

void SwapPreferences()
{
	for (int i = 1; i <= MaxClients; i++)
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

// -------------------------------------------------------------------------------------------------------------------------
// Event_RoundStart
// Description: Instead of processing scrambles during RoundEnd (which often interrupts map changes), 
// logic processing is done here. Checks if a scramble was scheduled or triggered by a winstreak,
// then applies the delay. Also handles resetting tracking data for the incoming round.
// -------------------------------------------------------------------------------------------------------------------------
public void Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
	g_bTeamsLocked = false;
	g_bNoSpec = false;
	g_bScrambleNextRound = ScrambleCheck();
	
	if (g_bScrambleNextRound)
	{
		int rounds = cvar_AutoScrambleRoundCount.IntValue;
		if (rounds) g_iRoundTrigger += rounds;
		StartScrambleDelay(0.3);
	}
	else if (cvar_ForceBalance.BoolValue && g_hForceBalanceTimer == null)
	{
		g_hForceBalanceTimer = CreateTimer(0.2, Timer_ForceBalance);
	}
	
	if ((g_bFullRoundOnly && g_bWasFullRound) || !g_bFullRoundOnly)
	{
		g_aTeams[iRedFrags] = 0;
		g_aTeams[iBluFrags] = 0;
	}
	
	if (g_RoundState == newGame)
	{
		g_RoundState = preGame;
		DelayPublicVoteTriggering();
		if (cvar_WaitScramble.BoolValue)
		{
			g_bPreGameScramble = true;
			g_bScrambleNextRound = true;
			if (!g_bSilent)
				PrintToChatAll("\x01\x04[SM]\x01 %t", "ScrambleRound");
		}
	}
	else if (g_RoundState == preGame)
	{
		g_RoundState = roundNormal;
	}

	if (g_RoundState != preGame)
	{
		CreateTimer(0.5, Timer_GetTime, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	g_iRoundStartTime = GetTime();
	g_bScrambleOverride = false;
	g_bWasFullRound = false;
	g_bRedCapped = false;
	g_bBluCapped = false;
	g_bScrambledThisRound = false;
}

public Action hook_Setup(Event event, const char[] name, bool dontBroadcast)
{
	g_RoundState = roundNormal;
	CreateTimer(0.5, Timer_GetTime, TIMER_FLAG_NO_MAPCHANGE);
	
	if (g_aTeams[bImbalanced])
	{
		StartForceTimer();
	}
	return Plugin_Continue;
}

public void Event_RoundWin(Event event, const char[] name, bool dontBroadcast)
{	
	if (cvar_ScrLockTeams.BoolValue)
	{
		g_bNoSpec = true;
	}
	
	g_RoundState = bonusRound;	
	g_bWasFullRound = false;
	
	if (event.GetBool("full_round"))
	{
		g_bWasFullRound = true;
		g_iCompleteRounds++;
	}
	else if (!cvar_FullRoundOnly.BoolValue)
	{
		g_iCompleteRounds++;
	}
	
	g_iLastRoundWinningTeam = event.GetInt("team");
	
	if (g_hForceBalanceTimer != null)
	{
		KillTimer(g_hForceBalanceTimer);
		g_hForceBalanceTimer = null;
	}
	if (g_hRoundTimeTick != null)
	{
		KillTimer(g_hRoundTimeTick);
		g_hRoundTimeTick = null;
	}
	if (g_hBalanceFlagTimer != null)
	{
		KillTimer(g_hBalanceFlagTimer);
		g_hBalanceFlagTimer = null;
	}
}

// -------------------------------------------------------------------------------------------------------------------------
// Event_PlayerDeath_Pre
// Description: Core hook for balancing logic. This tallies frags for KD scramble modes, but more importantly,
// checks if an imbalance currently exists on the server. If so, it waits a fraction of a second and fires 
// a timer to potentially move this freshly-dead player to the smaller team.
// -------------------------------------------------------------------------------------------------------------------------
public Action Event_PlayerDeath_Pre(Event event, const char[] name, bool dontBroadcast) 
{
	if (g_bBlockDeath) 
	{
		return Plugin_Handled;
	}
	
	int k_client = GetClientOfUserId(event.GetInt("attacker"));
	int	v_client = GetClientOfUserId(event.GetInt("userid"));
	
	if (k_client && IsClientInGame(k_client) && k_client != v_client && g_bBlockDeath)
	{
		g_bBlockDeath = false;
	}
	
	if (g_RoundState != roundNormal || event.GetInt("death_flags") & 32) 
	{
		return Plugin_Continue;
	}
	
	if (g_bAutoBalance && IsOkToBalance() && g_aTeams[bImbalanced] && GetClientTeam(v_client) == GetLargerTeam())	
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
	CheckBalance(true);
	
	return Plugin_Continue;
}

stock int GetAbsValue(int value1, int value2)
{
	return RoundFloat(FloatAbs(float(value1) - float(value2)));
}

// -------------------------------------------------------------------------------------------------------------------------
// IsNotTopPlayer
// Description: Pulls all clients on a team, sorts them by score, and checks if the provided
// client falls within the top 'X' spots defined by cvar_TopProtect. MVP players are spared from 
// autobalance to prevent angering the players hard-carrying the team.
// -------------------------------------------------------------------------------------------------------------------------
bool IsNotTopPlayer(int client, int team) 
{
	int iSize, iHighestScore;
	int iScores[MAXPLAYERS+1][2];
	
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{		
			int entity = GetPlayerResourceEntity();
			int Totalscore = GetEntProp(entity, Prop_Send, "m_iTotalScore", _, i); 

			iScores[iSize][1] = 1 + Totalscore;
			iScores[iSize][0] = i;
			if (iScores[iSize][1] > iHighestScore)
			{
				iHighestScore = iScores[iSize][1];
			}
			iSize++;
		}
	}
	
	if (iHighestScore <= 10) return true;
	if (iSize < cvar_TopProtect.IntValue + 4) return true;
	
	SortCustom2D(iScores, iSize, SortScoreDesc);
	
	for (int i = 0; i < cvar_TopProtect.IntValue; i++)
	{
		if (iScores[i][0] == client)
		{
			return false;
		}
	}
	return true;
}

bool IsClientBuddy(int client)
{
	for (int i = 1; i <= MaxClients; i++)
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

// -------------------------------------------------------------------------------------------------------------------------
// IsValidTarget
// Description: Checks if a player is legally allowed to be scrambled/balanced.
// Players dueling, holding setup logic, building nests, or covered by specific admin flags
// are skipped. If too many players are immune, the admin checks are forcibly bypassed.
// -------------------------------------------------------------------------------------------------------------------------
bool IsValidTarget(int client)
{
	if (cvar_ScrambleDuelImmunity.BoolValue)
	{
		if (TF2_IsPlayerInDuel(client)) return false;
	}
	
	e_Protection iImmunity; 
	char flags[32]; 

	iImmunity = view_as<e_Protection>(cvar_ScrambleImmuneMode.IntValue);
	if (iImmunity == none) return true;
	
	cvar_ScrambleAdmFlags.GetString(flags, sizeof(flags));	
	
	if (g_RoundState == setup || g_RoundState == bonusRound) return true;
	if (GetTime() - g_iRoundStartTime <= 10) return true;
		
	if (IsClientInGame(client) && IsValidTeam(client))
	{
		if (iImmunity == none) return true;
		
		bool bCheckAdmin = false, bCheckUberBuild = false;
		switch (iImmunity)
		{
			case admin: bCheckAdmin = true;
			case uberAndBuildings: bCheckUberBuild = true;
			case both: { bCheckAdmin = true; bCheckUberBuild = true; }
		}
		
		if (bCheckUberBuild)
		{
			if (TF2_HasBuilding(client) || TF2_IsClientUberCharged(client) || TF2_IsClientUbered(client))
			{
				return false;
			}
		}
			
		if (bCheckAdmin)
		{
			bool bSkip = false;
			float fPercent = cvar_ScrambleCheckImmune.FloatValue;
			if (fPercent > 0.0)
			{
				int iImmune, iTotal, iTargets;
				for (int i = 1; i <= MaxClients; i++)
				{
					if (IsClientInGame(i) && IsValidTeam(i))
					{
						if (IsAdmin(i, flags)) iImmune++;
						else iTargets++;
					}
				}
				if (iImmune)
				{
					iTotal = iImmune + iTargets;
					if (float(iImmune) / float(iTotal) >= fPercent)
						bSkip = true;
				}
			}
			if (!bSkip && IsAdmin(client, flags)) return false;
		}
		return true;
	}
	
	if (IsValidSpectator(client)) return true;
	return false;
}

stock bool IsValidSpectator(int client)
{
	if (!IsFakeClient(client))
	{
		if (g_bSelectSpectators)
		{
			if (GetClientTeam(client) == 1)
			{
				int iChangeTime = g_aPlayers[client][iSpecChangeTime];
				if (iChangeTime && (GetTime() - iChangeTime) < cvar_SelectSpectators.IntValue)
				{
					return true;
				}
				float fTime = GetClientTime(client);
				if (fTime <= 60.0) return true;
			}
		}
	}
	return false;
}
			
bool IsAdmin(int client, const char[] flags)
{
	int bits = GetUserFlagBits(client);	
	if (bits & ADMFLAG_ROOT) return true;
	int iFlags = ReadFlagString(flags);
	if (bits & iFlags) return true;	
	return false;
}

stock void BlockAllTeamChange()
{
	if (cvar_LockTeamsFullRound.BoolValue)
	{
		g_bTeamsLocked = true;
	}
	for (int i=1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsValidTeam(i) || IsFakeClient(i)) continue;
		SetupTeamSwapBlock(i);
	}
}

void SetupTeamSwapBlock(int client)
{
	if (!g_bForceTeam) return;
	
	if (cvar_TeamSwapBlockImmunity.BoolValue)
	{
		if (IsClientInGame(client))
		{
			char flags[32];
			cvar_TeamswapAdmFlags.GetString(flags, sizeof(flags));
			if (IsAdmin(client, flags)) return;
		}
	}
	g_aPlayers[client][iBlockTime] = GetTime() + g_iForceTime;
}

public Action TimerStopSound(Handle timer)
{
	for (int i=1; i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
		{
			StopSound(i, SNDCHAN_AUTO, EVEN_SOUND);
		}
	}
	return Plugin_Handled;
}

public Action Timer_GetTime(Handle timer)
{
	CheckBalance(true);
	GetRoundTimerInformation();
	if (g_hRoundTimeTick != null)
	{		
		g_hRoundTimeTick = CreateTimer(15.0, Timer_Countdown, _, TIMER_REPEAT);
	}
	return Plugin_Handled;
}

public void TimerUpdateAdd(Event event, const char[] name, bool dontBroadcast)
{
	if (cvar_BalanceTimeLimit.IntValue > 0)
	{
		GetRoundTimerInformation();
		CheckBalance(true);
	}
}

public Action Timer_Countdown(Handle timer)
{
	GetRoundTimerInformation();
	return Plugin_Continue;
}

public void OnLibraryRemoved(const char[] name)
{
	if (StrEqual(name, "adminmenu"))		
	{
		g_hAdminMenu = null;
	}
}

public void OnLibraryAdded(const char[] name) {}

public int SortScoreDesc(int[] x, int[] y, const int[][] array, Handle data)
{
	float score1 = view_as<float>(x[1]);
	float score2 = view_as<float>(y[1]);
	if (score1 > score2) return -1;
	else if (score1 < score2) return 1;
	return 0;
}

public int SortScoreAsc(int[] x, int[] y, const int[][] array, Handle data)
{
	float score1 = view_as<float>(x[1]);
	float score2 = view_as<float>(y[1]);
	if (score1 > score2) return 1;
	else if (score1 < score2) return -1;
	return 0;
}

// -------------------------------------------------------------------------------------------------------------------------
// CheckSpecChange
// Description: Prevents players from ruining team balance. It simulates what the teams would look
// like if the specified client left their team to join spectators. If the hypothetical gap
// exceeds the cvar_BalanceLimit, the player is barred from going spectator.
// -------------------------------------------------------------------------------------------------------------------------
bool CheckSpecChange(int client)
{
	if (cvar_TeamSwapBlockImmunity.BoolValue)
	{
		char flags[32];
		cvar_TeamswapAdmFlags.GetString(flags, sizeof(flags));
		if (IsAdmin(client, flags)) return false;
	}
	int redSize = GetTeamClientCount(TEAM_RED), bluSize = GetTeamClientCount(TEAM_BLUE), difference;
	if (GetClientTeam(client) == TEAM_RED) redSize -= 1;
	else bluSize -= 1;
	
	difference = GetAbsValue(redSize, bluSize);
	if (difference >= cvar_BalanceLimit.IntValue)
	{
		PrintToChat(client, "\x01\x04[SM]\x01 %t", "SpecChangeBlock");
		LogAction(client, -1, "Client \"%L\" is being blocked from swapping to spectate", client);
		return true;
	}
	return false;
}

public int SortIntsAsc(int[] x, int[] y, const int[][] array, Handle data)
{
	if (x[1] > y[1]) return 1;
	else if (x[1] < y[1]) return -1;    
	return 0;
}

public int SortIntsDesc(int[] x, int[] y, const int[][] array, Handle data)
{
	if (x[1] > y[1]) return -1;
	else if (x[1] < y[1]) return 1;   
	return 0;
}