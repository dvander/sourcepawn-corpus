/************************************************************************
*************************************************************************
gScramble
Description:
	Automatic scramble and balance script for TF2
*************************************************************************
*************************************************************************
This file is part of Simple SourceMod Plugins project.

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
File Information
$Id: gscramble.sp 132 2009-12-27 19:03:59Z goerge $
$Author: goerge $
$Revision: 132 $
$Date: 2009-12-27 12:03:59 -0700 (Sun, 27 Dec 2009) $
$LastChangedBy: goerge $
$LastChangedDate: 2009-12-27 12:03:59 -0700 (Sun, 27 Dec 2009) $
$URL: http://projects.mygsn.net/svn/simple-plugins/trunk/gScramble/addons/sourcemod/scripting/gscramble.sp $
$Copyright: (c) Simple SourceMod Plugins 2008-2009$
*************************************************************************
*************************************************************************
*/
#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#undef REQUIRE_EXTENSIONS
#include <clientprefs>
#define REQUIRE_EXTENSIONS

#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN

#define VERSION "2.4.53"
#define TEAM_RED 2
#define TEAM_BLUE 3
#define SCRAMBLE_SOUND "vo/announcer_am_teamscramble03.wav"
#define EVEN_SOUND		"vo/announcer_am_teamscramble01.wav"

#define VOTE_NAME		0
#define VOTE_NO 		"###no###"
#define VOTE_YES 		"###yes###"

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
	Handle:cvar_WinStreak			= INVALID_HANDLE,
	Handle:cvar_SortMode			= INVALID_HANDLE,
	Handle:cvar_AdminImmune			= INVALID_HANDLE,
	Handle:cvar_MenuVoteEnd			= INVALID_HANDLE,
	Handle:cvar_AutoscrambleVote	= INVALID_HANDLE,
	Handle:cvar_ScrambleAdminImmune	= INVALID_HANDLE,
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
	Handle:cvar_Rounds				= INVALID_HANDLE,
	Handle:cvar_ForceReconnect		= INVALID_HANDLE,
	Handle:cvar_TeamworkProtect		= INVALID_HANDLE,
	Handle:cvar_BalanceActionDelay	= INVALID_HANDLE,
	Handle:cvar_ForceBalanceTrigger = INVALID_HANDLE,
	Handle:cvar_NoSequentialScramble = INVALID_HANDLE,
	Handle:cvar_AdminBlockVote		= INVALID_HANDLE,
	Handle:cvar_BuddySystem 		= INVALID_HANDLE,
	Handle:cvar_ImbalancePrevent = INVALID_HANDLE,
	Handle:cvar_MenuIntegrate = INVALID_HANDLE;

new Handle:g_hAdminMenu 			= INVALID_HANDLE,
	Handle:g_hScrambleVoteMenu 		= INVALID_HANDLE,
	Handle:g_hScrambleNowPack		= INVALID_HANDLE;

/**
timer handles
*/
new Handle:g_hVoteDelayTimer 		= INVALID_HANDLE,
	Handle:g_hScrambleDelay			= INVALID_HANDLE,
	Handle:g_hRoundTimeTick 		= INVALID_HANDLE,
	Handle:g_hForceBalanceTimer			= INVALID_HANDLE,
	Handle:g_hBalanceFlagTimer		= INVALID_HANDLE,
	Handle:g_hCheckTimer 			= INVALID_HANDLE;
	
new Handle:g_cookie_timeBlocked 	= INVALID_HANDLE,
	Handle:g_cookie_teamIndex		= INVALID_HANDLE;

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
	bool:g_bAutoVote,
	bool:g_bUseBuddySystem,
	/**
	overrides the auto scramble check
	*/
	bool:g_bScrambleOverride;  // allows for the scramble check to be blocked by admin

new String:g_sVoteInfo[3][65],
	g_iTeamIds[2] = {TEAM_RED, TEAM_BLUE};

new	g_iMapStartTime,
	g_iRoundStartTime,
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
	bool:bImbalanced,
	iImbalanceFactor,
	iLargerTeam,
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
	iBuddy
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
	autoScramble,
	scramble,
	balance,
};

enum e_Protection
{
	none,
	admin,
	uberAndBuildings,
	both,
};

enum e_ScrambleModes
{
	invalid,
	random,
	score,
	scoreSqdPerMinute,
}

new e_RoundState:g_RoundState,
	ScrambleTime:g_iDefMode,
	g_aTeams[e_TeamInfo],
	g_aPlayers[MAXPLAYERS + 1][e_PlayerInfo];

new g_iTimerEnt;
new g_iRoundTimer;


public Plugin:myinfo = 
{
	name = "gScramble + Balance",
	author = "Goerge",
	description = "A comprehensive team management plugin.",
	version = VERSION,
	url = "http://www.fpsbanana.com"
};

public OnPluginStart()
{
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
	
	cvar_ImbalancePrevent	= CreateConVar("gs_prevent_spec_imbalance", "0", "If set, block changes to spectate that result in a team imbalance", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_BuddySystem		= CreateConVar("gs_use_buddy_system", "0", "Allow players to choose buddies to try to keep them on the same team", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvar_TeamworkProtect	= CreateConVar("gs_teamwork_protect", "60",		"Time in seconds to protect a client from autobalance if they have recently captured a point, defended/touched intelligence, or assisted in or destroying an enemy sentry. 0 = disabled", FCVAR_PLUGIN, true, 0.0, false);
	cvar_ForceBalance 		= CreateConVar("gs_force_balance",	"0", 		"Force a balance between each round. (If you use a custom team balance plugin that doesn't do this already, or you have the default one disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AdminImmune		= CreateConVar("gs_teamswitch_immune",	"1",	"Sets if admins (root and ban) are immune from team swap blocking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ScrambleAdminImmune = CreateConVar("gs_scramble_immune", "0",		"Sets if admins and people with uber and engie buildings are immune from being scrambled.\n0 = no immunity\n1 = just admins\n2 = charged medics + engineers with buildings\n3 = admins + charged medics and engineers with buildings.", FCVAR_PLUGIN, true, 0.0, true, 3.0);
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
	cvar_SortMode			= CreateConVar("gs_sort_mode",		"0",		"Player scramble sort mode.\n1 = Random\n2 = Player Score\n3 = Player Score Per Minute.\nThis controls how players get swapped during a scramble.", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	cvar_SetupCharge		= CreateConVar("gs_setup_recharge",		"1",		"If a scramble-now happens during setup time, fill up any medic's uber-charge.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ForceTeam 			= CreateConVar("gs_changeblocktime",	"120", 		"Time after being swapped by a scramble where players aren't allowed to change teams", FCVAR_PLUGIN, true, 0.0, false);
	cvar_ForceReconnect		= CreateConVar("gs_check_reconnect",	"1",		"The plugin will check if people are reconnecting to the server to avoid being forced on a team.  Requires clientprefs", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MenuVoteEnd		= CreateConVar("gs_menu_votebehavior",	"0",		"0 =will trigger scramble for round end.\n1 = will scramble teams after vote.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Needed 			= CreateConVar("gs_menu_votesneeded", 	"0.60", 	"Percentage of votes for the menu vote scramble needed.", FCVAR_PLUGIN, true, 0.05, true, 1.0);
	cvar_Delay 				= CreateConVar("gs_vote_delay", 		"60.0", 	"Time in seconds after the map has started and after a failed vote in which players can votescramble.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_VoteDelaySuccess	= CreateConVar("gs_vote_delay2",		"300",		"Time in seconds after a successful scramble in which players can vote again.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_AdminBlockVote		= CreateConVar("gs_vote_adminblock",		"0",		"If set, publicly started votes are disabled when an admin is preset.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvar_MinPlayers 		= CreateConVar("gs_vote_minplayers",	"6", 		"Minimum poeple connected before any voting will work.", FCVAR_PLUGIN, true, 0.0, false);
	
	cvar_WinStreak			= CreateConVar("gs_winstreak",		"0", 		"If set, it will scramble after a team wins X full rounds in a row", FCVAR_PLUGIN, true, 0.0, false);
	cvar_Rounds				= CreateConVar("gs_scramblerounds", "0",		"If set, it will scramble every X full round", FCVAR_PLUGIN, true, 0.0, false, 1.0);
	
	cvar_AutoScramble		= CreateConVar("gs_autoscramble",	"1", 		"Enables/disables the automatic scrambling.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_FullRoundOnly 		= CreateConVar("gs_as_fullroundonly",	"0",		"Auto-scramble only after a full round has completed.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AutoscrambleVote	= CreateConVar("gs_as_vote",		"0",		"Starts a scramble vote instead of scrambling at the end of a round", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MinAutoPlayers 	= CreateConVar("gs_as_minplayers", "12", 		"Minimum people connected before automatic scrambles are possible", FCVAR_PLUGIN, true, 0.0, false);
	cvar_FragRatio 			= CreateConVar("gs_as_hfragratio", 		"2.0", 		"If a teams wins with a frag ratio greater than or equal to this setting, trigger a scramble", FCVAR_PLUGIN, true, 1.2, false);
	cvar_Steamroll 			= CreateConVar("gs_as_wintimelimit", 	"120.0", 	"If a team wins in less time, in seconds, than this, and has a frag ratio greater than specified: perform an auto scramble.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_SteamrollRatio 	= CreateConVar("gs_as_wintimeratio", 	"1.5", 		"Lower kill ratio for teams that win in less than the wintime_limit.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_AvgDiff			= CreateConVar("gs_as_playerscore_avgdiff", "10.0",	"If the average score difference for all players on each team is greater than this, then trigger a scramble.\n0 = skips this check", FCVAR_PLUGIN, true, 0.0, false);
	cvar_DominationDiff		= CreateConVar("gs_as_domination_diff",		"10",	"If a team has this many more dominations than the other team, then trigger a scramble.\n0 = skips this check", FCVAR_PLUGIN, true, 0.0, false);
	cvar_Koth				= CreateConVar("gs_as_koth_pointcheck",		"0",	"If enabled, trigger a scramble if a team never captures the point in koth mode.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvar_MenuIntegrate = CreateConVar("gs_admin_menu",			"1",  "Enable or disabled the automatic integration into the admin menu", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Version			= CreateConVar("sm_gscramble_version", VERSION, "Gscramble version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
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
	
	AutoExecConfig(true, "plugin.gscramble");	
	LoadTranslations("common.phrases");
	LoadTranslations("gscramble.phrases");
	
	CheckEstensions();
	
	new Handle:gTopMenu;
	if (LibraryExists("adminmenu") && ((gTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))	
		OnAdminMenuReady(gTopMenu);	
	g_iVoters = GetClientCount(false);
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
}

RegCommands()
{
	RegAdminCmd("sm_scrambleround", cmd_Scramble, ADMFLAG_BAN, "Scrambles at the end of the bonus round");
	RegAdminCmd("sm_cancel", 		cmd_Cancel, ADMFLAG_BAN, "Cancels any active scramble, and scramble timer.");
	RegAdminCmd("sm_resetvotes",	cmd_ResetVotes, ADMFLAG_BAN, "Resets all public votes.");
	RegAdminCmd("sm_scramble", 		cmd_Scramble_Now, ADMFLAG_BAN, "sm_scramble <delay> <respawn> <mode>");
	RegAdminCmd("sm_forcebalance",	cmd_Balance, ADMFLAG_BAN, "Forces a team balance if an imbalance exists.");
	RegAdminCmd("sm_scramblevote",	cmd_Vote, ADMFLAG_BAN, "Start a vote. sm_scramblevote <now/end>");
	
	AddCommandListener(CMD_Listener, "say");
	AddCommandListener(CMD_Listener, "say_team");
	AddCommandListener(CMD_Listener, "jointeam");
	AddCommandListener(CMD_Listener, "spectate");
	
	RegConsoleCmd("preference",		cmd_Preference);
	RegConsoleCmd("testau", 		Command_test);
	RegConsoleCmd("addbuddy", 		cmd_AddBuddy);
}

public Action:CMD_Listener(client, const String:command[], argc)
{
	if (StrEqual(command, "jointeam", false) || StrEqual(command, "spectate", false))
	{
		if (client && IsValidTeam(client))
		{
			new String:sArg[4] = "-1";
			if (argc)
			{
				GetCmdArgString(sArg, sizeof(sArg));
			}
			if (IsBlocked(client))
			{
				if (g_aTeams[bImbalanced] && (StrEqual(sArg, "blue", false) || StrEqual(sArg, "red", false) || StringToInt(sArg) >= 2))
				{
					/**
					allow clients to change teams during imbalances
					*/
					return Plugin_Continue;
				}
				HandleStacker(client);
				return Plugin_Handled;
			}
			if (GetConVarBool(cvar_ImbalancePrevent))
			{
				if (StrEqual(command, "spectate", false) || StringToInt(sArg) < 2 || StrContains(sArg, "spec", false) != -1)
				{
					if (CheckSpecChange(client))
					{
						HandleStacker(client);
						return Plugin_Handled;
					}
				}
			}
		}
	}
	else if (StrContains(command, "say", false) != -1)
	{
		if (!client)
		{
			return Plugin_Continue;
		}
		decl String:text[192];
		if (!GetCmdArgString(text, sizeof(text)))
		{
			return Plugin_Continue;
		}
		new startidx = 0;
		if(text[strlen(text)-1] == '"')
		{
			text[strlen(text)-1] = '\0';
			startidx = 1;
		}	
		new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);	
		if (strcmp(text[startidx], "votescramble", false) == 0 || 
			strcmp(text[startidx], "scramble", false) == 0)
		{
			AttemptScrambleVote(client);
		}
		SetCmdReplySource(old);		
		return Plugin_Continue;		
	}
	return Plugin_Continue;
}

CheckEstensions()
{
	new String:sMod[14];
	GetGameFolderName(sMod, 14);
	if (!StrEqual(sMod, "TF", false))
	{
		SetFailState("This plugin only works on Team Fortress 2");
	}
	new String:sExtError[256];
	/**
	check to see if client prefs is loaded and configured properly
	*/		
	new iExtStatus = GetExtensionFileStatus("clientprefs.ext", sExtError, sizeof(sExtError));
	if (iExtStatus == -1)
		LogAction(-1, 0, "Optional extension clientprefs failed to load.");	
	if (iExtStatus == 0)
	{
		LogAction(-1, 0, "Optional extension clientprefs is loaded with errors.");
		LogAction(-1, 0, "Status reported was [%s].", sExtError);	
	}
	else if (iExtStatus == -2)
		LogAction(-1, 0, "Optional extension clientprefs is missing.");
	else if (iExtStatus == 1)
	{
		if (SQL_CheckConfig("clientprefs"))		
			g_bUseClientPrefs = true;		
		else
			LogAction(-1, 0, "Optional extension clientprefs found, but no database entry is present");
	}
	
	/**
	now that we have checked for the clientprefs ext, see if we can use its natives
	*/
	if (g_bUseClientPrefs)
	{
		g_cookie_timeBlocked = RegClientCookie("time blocked", "time player was blocked", CookieAccess_Private);
		g_cookie_teamIndex = RegClientCookie("team index", "index of the player's team", CookieAccess_Private);
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
			ReplyToTargetError(client, COMMAND_TARGET_NONE);
	}
	else if (!args)
		ShowBuddyMenu(client);
	else
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "BuddyArgError");
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
				ReplyToCommand(client, "RED");
			else
				ReplyToCommand(client, "BLU");
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
		ServerCommand("mp_autoteambalance 1");
}

public Action:Command_test(client, args) 
{
    PrintToChatAll("Version %s", VERSION);
} 

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	/**
	if late, assume state = setup and check the timer ent
	*/
	if (late)
	{
		g_RoundState = setup;
		CreateTimer(1.0, Timer_GetTime);
	}
		
	CreateNative("GS_IsBlocked", Native_GS_IsBlocked);
	MarkNativeAsOptional("RegClientCookie");
	MarkNativeAsOptional("SetClientCookie");
	MarkNativeAsOptional("GetClientCookie");
	return APLRes_Success;
}

bool:IsBlocked(client)
{
	if (!g_bForceTeam)
		return false;

	if (g_aPlayers[client][iBlockTime] > GetTime())
		return true;
	return false;
}

public Native_GS_IsBlocked(Handle:plugin, numParams)
{
	new client = GetNativeCell(1),
		initiator = GetNativeCell(2);
	if (!client || client > MaxClients)
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index");
	if (IsBlocked(client))
	{
		if (initiator)
			HandleStacker(client);
		return true;
	}
	return false;
}

public OnConfigsExecuted()
{
	decl String:sMapName[32];
	GetCurrentMap(sMapName, 32);
	SetConVarString(cvar_Version, VERSION);
	/**
	load load global values
	*/
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
		g_bForceReconnect = GetConVarBool(cvar_ForceReconnect);
	
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
	
	if (GetConVarBool(cvar_Rounds))
		g_iRoundTrigger = GetConVarInt(cvar_Rounds);
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
		if (g_hAdminMenu != INVALID_HANDLE)
		{
			new TopMenuObject:ID = FindTopMenuCategory(g_hAdminMenu, "gScramble");
			if (ID != INVALID_TOPMENUOBJECT)
			{
				RemoveFromTopMenu(g_hAdminMenu, ID);
			}
		}
	}
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
	
	if (convar == cvar_FullRoundOnly)
		iNewValue == 1 ? (g_bFullRoundOnly = true) : (g_bFullRoundOnly = false);
	
	if (convar == cvar_Balancer)
		iNewValue == 1 ? (g_bAutoBalance = true) : (g_bAutoBalance = false);
		
	if (convar == cvar_ForceTeam)
	{
		g_iForceTime = iNewValue;
		iNewValue == 1 ? (g_bForceTeam = true) : (g_bForceTeam = false);
	}
		
	if (convar == cvar_ForceReconnect && g_bUseClientPrefs)
		iNewValue == 1 ? (g_bForceReconnect = true) : (g_bForceReconnect = false);
	if (convar == cvar_TeamworkProtect)
		g_iTeamworkProtection = iNewValue;
	if (convar == cvar_AutoScramble)
		iNewValue == 1  ? (g_bAutoScramble = true):(g_bAutoScramble = false);
	if (convar == cvar_MenuVoteEnd)
		iNewValue == 1 ? (g_iDefMode = Scramble_Now) : (g_iDefMode = Scramble_Round);
	if (convar == cvar_NoSequentialScramble)
		g_bNoSequentialScramble = iNewValue?true:false;
}

hook()
{
	LogAction(0, -1, "Hooking events.");
	HookEvent("teamplay_round_start", 		hook_Start, EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", 		hook_Win, EventHookMode_Post);
	HookEvent("teamplay_setup_finished", 	hook_Setup, EventHookMode_PostNoCopy);
	HookEvent("player_death", 				hook_Death, EventHookMode_Pre);
	HookEvent("game_start", 				hook_Event_GameStart);
	HookEvent("teamplay_restart_round", 	hook_Event_TFRestartRound);
	HookEvent("player_team",				hook_Event_player_team, EventHookMode_Pre);
	HookEvent("teamplay_round_stalemate",	hook_RoundStalemate, EventHookMode_PostNoCopy);
	HookEvent("teamplay_point_captured", 	hook_PointCaptured, EventHookMode_Post);
	HookEvent("object_destroyed", 			hook_ObjectDestroyed, EventHookMode_Post);
	HookEvent("teamplay_flag_event",		hook_FlagEvent, EventHookMode_Post);
	HookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook_Class, true);
	HookEvent("teamplay_game_over", hook_GameEnd, EventHookMode_PostNoCopy);
	HookEvent("player_chargedeployed", hook_UberDeploy, EventHookMode_Post);
	HookEvent("player_sapped_object", hook_Sapper, EventHookMode_Post);
	HookEvent("medic_death", hook_MedicDeath, EventHookMode_Post);
	HookEvent("player_escort_score", hook_EscortScore, EventHookMode_Post);	
	HookEvent("teamplay_timer_time_added", TimerUpdateAdd, EventHookMode_PostNoCopy);
	g_bHooked = true;
}

unHook()
{
	LogAction(0, -1, "Unhooking events");
	UnhookEvent("teamplay_round_start", 		hook_Start, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_round_win", 		hook_Win, EventHookMode_Post);
	UnhookEvent("teamplay_setup_finished", 	hook_Setup, EventHookMode_PostNoCopy);
	UnhookEvent("player_death", 				hook_Death, EventHookMode_Pre);
	UnhookEvent("game_start", 				hook_Event_GameStart);
	UnhookEvent("teamplay_restart_round", 	hook_Event_TFRestartRound);
	UnhookEvent("player_team",				hook_Event_player_team, EventHookMode_Pre);
	UnhookEvent("teamplay_round_stalemate",	hook_RoundStalemate, EventHookMode_PostNoCopy);
	UnhookEvent("teamplay_point_captured", 	hook_PointCaptured, EventHookMode_Post);
	UnhookEvent("teamplay_game_over", hook_GameEnd, EventHookMode_PostNoCopy);
	UnhookEvent("object_destroyed", hook_ObjectDestroyed, EventHookMode_Post);
	UnhookEvent("teamplay_flag_event",		hook_FlagEvent, EventHookMode_Post);
	UnhookUserMessage(GetUserMessageId("TextMsg"), UserMessageHook_Class, true);
	UnhookEvent("player_chargedeployed", hook_UberDeploy, EventHookMode_Post);
	UnhookEvent("player_sapped_object", hook_Sapper, EventHookMode_Post);
	UnhookEvent("medic_death", hook_MedicDeath, EventHookMode_Post);
	UnhookEvent("player_escort_score", hook_EscortScore, EventHookMode_Post);
	UnhookEvent("teamplay_timer_time_added", TimerUpdateAdd, EventHookMode_PostNoCopy);

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
		AddTeamworkTime(GetEventInt(event, "player"));
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
		new medic = GetClientOfUserId(GetEventInt(event, "userid")),
			target = GetClientOfUserId(GetEventInt(event, "targetid"));
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
		new client = GetClientOfUserId(GetEventInt(event, "attacker")),
			assister = GetClientOfUserId(GetEventInt(event, "assister"));
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
			AddTeamworkTime(cappers[i]);
	}
	
	if (g_bKothMode)
		GetEventInt(event, "team") == TEAM_RED ? (g_bRedCapped = true) : (g_bBluCapped = true);
}

public hook_RoundStalemate(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvar_ForceBalance) && g_aTeams[bImbalanced])		
		BalanceTeams(true);	
	g_RoundState = suddenDeath;
}

/**
add protection to those interacting with the CTF flag
*/	
public hook_FlagEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	AddTeamworkTime(GetEventInt(event, "player"));
}

public Action:hook_Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bBlockDeath)
	{
		if (!dontBroadcast)
		{
			new Handle:hEvent = CreateEvent("player_team"), String:clientName[MAX_NAME_LENGTH + 1], 
				userId = GetEventInt(event, "userid"), client = GetClientOfUserId(userId);
			if (hEvent != INVALID_HANDLE)
			{
				GetClientName(client, clientName, sizeof(clientName));
				SetEventInt(hEvent, "userid", userId);
				SetEventInt(hEvent, "team", GetEventInt(event, "team"));
				SetEventInt(hEvent, "oldteam", GetEventInt(event, "oldteam"));
				SetEventBool(hEvent, "disconnect", GetEventBool(event, "disconnect"));
				SetEventBool(hEvent, "autoteam", GetEventBool(event, "autoteam"));
				SetEventBool(hEvent, "silent", GetEventBool(event, "silent"));
				SetEventString(hEvent, "name", clientName);
				FireEvent(hEvent, true);
			}
		}
		return Plugin_Handled;
	}
	if (g_bAutoBalance)
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

public OnClientDisconnect(client)
{
	CheckBalance(true);
	if (IsFakeClient(client))
		return;
	if (g_aPlayers[client][bHasVoted] == true)
	{
		g_iVotes--;
		g_aPlayers[client][bHasVoted] = false;
	}
	g_iVoters--;	
	if (g_iVoters < 0)
		g_iVoters = 0;	
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
	g_aPlayers[client][iTeamPreference] = 0;
	
	if (GetConVarBool(cvar_AdminBlockVote) && g_aPlayers[client][bIsVoteAdmin])
		g_iNumAdmins--;
		
	if (g_bUseBuddySystem)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (g_aPlayers[i][iBuddy] == client)
			{
				if (IsClientInGame(i))
					PrintToChat(i, "\x01\x04[SM]\x01 %t", "YourBuddyLeft");
				g_aPlayers[i][iBuddy] = 0;
			}
		}
	}
	
	if (g_RoundState != mapEnding)
	{		
		/**
		check to see if we should remember his info for disconnect
		reconnect team blocking
		*/
		if (g_bUseClientPrefs && g_bForceTeam && g_bForceReconnect && IsClientInGame(client) && IsValidTeam(client) && IsBlocked(client))
		{
			new String:blockTime[128], String:teamIndex[2], iIndex = 0;
			IntToString(GetTime(), blockTime, sizeof(blockTime));
			if (g_iTeamIds[1] == GetClientTeam(client))
				iIndex = 1;
			IntToString(iIndex, teamIndex, sizeof(teamIndex));
			SetClientCookie(client, g_cookie_timeBlocked, blockTime);
			SetClientCookie(client, g_cookie_teamIndex, teamIndex);
			LogAction(client, -1, "\"%L\" is team swap blocked, and is being saved.", client);
		}
	}
}

public OnClientPostAdminCheck(client)
{
	if(IsFakeClient(client))
		return;
		
	if (GetConVarBool(cvar_Preference) && g_bAutoBalance && g_bHooked)
		CreateTimer(25.0, Timer_PrefAnnounce, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
	g_aPlayers[client][iBlockTime] = 0;
	g_aPlayers[client][iBalanceTime] = 0;
	g_aPlayers[client][iTeamworkTime] = 0;
	if (GetConVarBool(cvar_AdminBlockVote) && CheckCommandAccess(client, "sm_scramblevote", ADMFLAG_BAN))
	{
		g_aPlayers[client][bIsVoteAdmin] = true;
		g_iNumAdmins++;
	}
	else 
		g_aPlayers[client][bIsVoteAdmin] = false;
	
	g_aPlayers[client][bHasVoted] = false;
	g_iVoters++;
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
	
}

public OnClientCookiesCached(client)
{
	if (!IsClientConnected(client) || IsFakeClient(client) || !g_bForceTeam || !g_bForceReconnect)
		return;
		
	decl String:time[32], iTime;
	GetClientCookie(client, g_cookie_timeBlocked, time, sizeof(time));
	if ((iTime = StringToInt(time)))
	{
		if (iTime > g_iMapStartTime && (GetTime() - iTime) <= 180)
		{
			LogAction(client, -1, "\"%L\" is reconnect blocked", client);
			SetupTeamSwapBlock(client);
			CreateTimer(20.0, timer_Restore, GetClientUserId(client));
		}
	}   
}

public Action:Timer_PrefAnnounce(Handle:timer, any:id)
{
	new client;
	if ((client = GetClientOfUserId(id)))
		PrintToChat(client, "\x01\x04[SM]\x01 %t", "PrefAnnounce");
	return Plugin_Handled;
}

public Action:timer_Restore(Handle:timer, any:id)
{
	/**
	make sure that the client is still conneceted
	*/
	new client;
	if (!(client = GetClientOfUserId(id)) || !IsClientInGame(client))
		return Plugin_Handled;
		
	new String:sIndex[2], iIndex;
	GetClientCookie(client, g_cookie_teamIndex, sIndex, sizeof(sIndex));
	iIndex = StringToInt(sIndex);
	
	if (GetClientTeam(client) != g_iTeamIds[iIndex])
	{
		ChangeClientTeam(client, g_iTeamIds[iIndex]);
		ShowVGUIPanel(client, "team", _, false);
		PrintToChat(client, "\x01\x04[SM]\x01 %t", "TeamRestore");
		ShowVGUIPanel(client, g_iTeamIds[iIndex] == TEAM_BLUE ? "class_blue" : "class_red");
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
	g_bAutoVote = false;
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
	g_hBalanceFlagTimer = INVALID_HANDLE;
	g_hForceBalanceTimer = INVALID_HANDLE;
	g_hCheckTimer = INVALID_HANDLE;
	if (g_hScrambleNowPack != INVALID_HANDLE)
		CloseHandle(g_hScrambleNowPack);
	g_hScrambleNowPack = INVALID_HANDLE;
	g_iLastRoundWinningTeam = 0;
}

AddTeamworkTime(client)
{
	if (g_RoundState == normal && client && IsClientInGame(client) && !IsFakeClient(client))
		g_aPlayers[client][iTeamworkTime] = GetTime()+g_iTeamworkProtection;
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
	PerformReset(client);
	return Plugin_Handled;
}

PerformReset(client)
{
	LogAction(client, -1, "\"%L\" has reset all the public votes", client);
	ShowActivity(client, "%t", "AdminResetVotes");
	ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "ResetReply", g_iVotes);
	for (new i = 1; i <= MaxClients; i++)
		g_aPlayers[i][bHasVoted] = false;
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
		PrintToChatAll("\x01\x04[SM]\x01 %t", "ShameMessage", clientName);
		g_aPlayers[client][iBlockWarnings]++;
	}	
	if (GetConVarBool(cvar_Punish))	
		SetupTeamSwapBlock(client);
	
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
	
	if (g_aTeams[iLargerTeam])
	{
		BalanceTeams(true);
		LogAction(client, -1, "\"%L\" performed the force balance command", client);
		ShowActivity(client, "%t", "AdminForceBalance");
	}
	else
		ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NoImbalnceReply");
	
}

Float:GetAvgScoreDifference(team)
{
	new teamScores, otherScores, Float:otherAvg, Float:teamAvg;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsValidTeam(i))
		{
			if (GetClientTeam(i) == team)
				teamScores += TF2_GetPlayerResourceData(i, TFResource_TotalScore);
			else
				otherScores += TF2_GetPlayerResourceData(i, TFResource_TotalScore);
		}
	}
	teamAvg = float(teamScores) / float(GetTeamClientCount(team));
	otherAvg = float(otherScores) / float(GetTeamClientCount(team == TEAM_RED ? TEAM_BLUE : TEAM_RED));
	if (otherAvg > teamAvg)
		return 0.0;
	return FloatAbs(teamAvg - otherAvg);
}

BalanceTeams(bool:respawn=true)
{
	if (!TeamsUnbalanced())
	{
		return;
	}
	new team = g_aTeams[iLargerTeam], counter,
		smallTeam = team == TEAM_RED?TEAM_BLUE:TEAM_RED,
		swaps = g_aTeams[iImbalanceFactor] / 2;
	decl iFatTeam[GetTeamClientCount(team)][2];
	for (new i = 1; i <= MaxClients; i++) 
	{
		if (!IsClientInGame(i))
			continue;
		if (GetClientTeam(i) == team) 
		{
			if (GetConVarBool(cvar_Preference) && g_aPlayers[i][iTeamPreference] == smallTeam && !TF2_IsClientUbered(i))				
				iFatTeam[counter][1] = 3;			
			else if (IsValidTarget(i, e_ImmunityModes:balance))
				iFatTeam[counter][1] = GetPlayerPriority(i);
			else
				iFatTeam[counter][1] = -5;
			iFatTeam[counter][0] = i;
			counter++;
		}
	}	
	SortCustom2D(iFatTeam, counter, SortIntsDesc); // sort the array so low prio players are on the bottom
	g_bBlockDeath = true;	
	for (new i = 0; swaps-- > 0 && i < counter; i++)
	{
		if (iFatTeam[i][0])
		{
			new String:clientName[MAX_NAME_LENGTH + 1], String:sTeam[4];
			GetClientName(iFatTeam[i][0], clientName, 32);
			if (team == TEAM_RED)
				sTeam = "Blu";
			else
				sTeam = "Red";			
			ChangeClientTeam(iFatTeam[i][0], team == TEAM_BLUE ? TEAM_RED : TEAM_BLUE);
			PrintToChatAll("\x01\x04[SM]\x01 %t", "TeamChangedAll", clientName, sTeam);
			SetupTeamSwapBlock(iFatTeam[i][0]);
			LogAction(iFatTeam[i][0], -1, "\"%L\" has been force-balanced to %s.", iFatTeam[i][0], sTeam);			
			if (respawn)
				CreateTimer(0.5, Timer_BalanceSpawn, iFatTeam[i][0], TIMER_FLAG_NO_MAPCHANGE);
			if (!IsFakeClient(iFatTeam[i][0]))
			{				
				new Handle:event = CreateEvent("teamplay_teambalanced_player");
				SetEventInt(event, "player", iFatTeam[i][0]);
				g_aPlayers[iFatTeam[i][0]][iBalanceTime] = GetTime() + (GetConVarInt(cvar_BalanceTime) * 60);
				SetEventInt(event, "team", team == TEAM_BLUE ? TEAM_RED : TEAM_BLUE);
				FireEvent(event);
			}
		}
	}
	g_bBlockDeath = false;
	g_aTeams[iLargerTeam] = 0;
	g_aTeams[iImbalanceFactor] = 0;
	g_aTeams[bImbalanced] = false;
}

public Action:Timer_BalanceSpawn(Handle:timer, any:client)
{
	if (!IsPlayerAlive(client))
		TF2_RespawnPlayer(client);
	return Plugin_Handled;
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
			if ((mode = e_ScrambleModes:StringToInt(arg3)) > scoreSqdPerMinute)
			{
				ReplyToCommand(client, "\x01\x04[SM]\x01 %t", "NowCommandReply");
				return Plugin_Handled;
			}
		}			
	}
	PerformScrambleNow(client, fDelay, respawn, mode);
	return Plugin_Handled;
}

PerformScrambleNow(client, Float:fDelay = 5.0, bool:respawn = false, e_ScrambleModes:mode = invalid)
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
	StartScrambleDelay(fDelay, false, respawn, mode);
}

AttemptScrambleVote(client)
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
				Override = true;
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
			StartScrambleVote(g_iDefMode);		
		else if (GetConVarInt(cvar_VoteMode) == 0)
		{			
			g_bScrambleNextRound = true;
			PrintToChatAll("\x01\x04[SM]\x01 %t", "ScrambleRound");			
		}
		else if (!Override && GetConVarInt(cvar_VoteMode) == 2)
			StartScrambleDelay(5.0, false, true);	
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
		mode = Scramble_Now;
	else if (StrEqual(arg, "end", false))
		mode = Scramble_Round;
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

StartScrambleVote(ScrambleTime:mode, time=20, bool:auto = false)
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
	AddMenuItem(g_hScrambleVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hScrambleVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hScrambleVoteMenu, false);
	VoteMenuToAll(g_hScrambleVoteMenu, time);
	if (auto)
		g_bAutoVote = true;
}

public Action:Timer_ScrambleVoteStarter(Handle:timer, any:mode)
{
	if (IsVoteInProgress())
		return Plugin_Continue;
	StartScrambleVote(mode, 15);
	return Plugin_Stop;
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	DelayPublicVoteTriggering();
	if (action == MenuAction_End)
		VoteMenuClose();	
	else if (action == MenuAction_Display)
	{
		decl String:title[64];
		GetMenuTitle(menu, title, sizeof(title));		
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%s %s", title, "");
		new Handle:panel = Handle:param2;
		SetPanelTitle(panel, buffer);
	}	
	else if (action == MenuAction_DisplayItem)
	{
		decl String:display[64];
		GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));	 
	 	if (strcmp(display, "VOTE_NO") == 0 || strcmp(display, "VOTE_YES") == 0)
	 	{
			decl String:title[64];
			GetMenuTitle(menu, title, sizeof(title));		
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%s %s", title, g_sVoteInfo[VOTE_NAME]);
			return RedrawMenuItem(buffer);
		}
	}
	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
		PrintToChatAll("\x01\x04[SM]\x01 %t", "No Votes Cast");	
	else if (action == MenuAction_VoteEnd)
	{	
		new m_votes, totalVotes;		
		GetMenuVoteInfo(param2, m_votes, totalVotes);		
		new Float:comp = FloatDiv(float(m_votes),float(totalVotes));
		new Float:comp2 = GetConVarFloat(cvar_Needed);		
		if (param1 == 1) // Votes of no wins
		{			
			PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteFailed", RoundToNearest(comp*100), totalVotes);
			LogAction(-1 , 0, "%T", "VoteFailed", LANG_SERVER, RoundToNearest(comp*100), totalVotes);
		}		
		else if (comp >= comp2 && param1 == 0)
		{
			PrintToChatAll("\x01\x04[SM]\x01 %t", "VoteWin", RoundToNearest(comp*100), totalVotes);		
			if (g_bScrambleAfterVote)
			{
				StartScrambleDelay(5.0, g_bAutoVote, true);
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
			PrintToChatAll("\x01\x04[SM]\x01 %t", "NotEnoughVotes", totalVotes);
		}
	}
	g_bAutoVote = false;
	return 0;
}

DelayPublicVoteTriggering(bool:success = false)  // success means a scramble happened... longer delay
{
	if (GetConVarBool(cvar_VoteEnable))
	{
		for (new i = 0; i <= MaxClients; i++)	
			g_aPlayers[i][bHasVoted] = false;
		
		g_iVotes = 0;
		g_bVoteAllowed = false;
		if (g_hVoteDelayTimer != INVALID_HANDLE)
		{
			KillTimer(g_hVoteDelayTimer);
			g_hVoteDelayTimer = INVALID_HANDLE;
		}
		new Float:fDelay;
		if (success)
			fDelay = GetConVarFloat(cvar_VoteDelaySuccess);
		else
			fDelay = GetConVarFloat(cvar_Delay);
		g_hVoteDelayTimer = CreateTimer(fDelay, TimerEnable, TIMER_FLAG_NO_MAPCHANGE);
	}
}

VoteMenuClose()
{
	CloseHandle(g_hScrambleVoteMenu);
	g_hScrambleVoteMenu = INVALID_HANDLE;
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
			g_aPlayers[i][iTeamPreference] = TEAM_BLUE;
		else if (g_aPlayers[i][iTeamPreference] == TEAM_BLUE)
			g_aPlayers[i][iTeamPreference] = TEAM_RED;
	}	
}

public hook_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	/**
	check to see if the previos round warrented a trigger
	moved to the start event to make checking for map ending uneeded
	*/
	new bool:bOkayToCheck = false;
	if (!g_bScrambleNextRound && g_iVoters >= GetConVarInt(cvar_MinAutoPlayers))
	{
		if (g_RoundState == bonusRound)
		{
			if (g_bNoSequentialScramble)
			{
				if (!g_bScrambledThisRound)
					bOkayToCheck = true;
			}
			else
				bOkayToCheck = true;
		}
	}
	if (bOkayToCheck)
	{
		if (WinStreakCheck(g_iLastRoundWinningTeam) || (!g_bScrambleOverride && g_bAutoScramble && AutoScrambleCheck(g_iLastRoundWinningTeam)))
		{
			if (GetConVarBool(cvar_AutoscrambleVote))
				StartScrambleVote(g_iDefMode, 15, true);
			else			
				g_bScrambleNextRound = true;
		}		
	}
	/**
	execute the trigger
	*/
	if (g_bScrambleNextRound)
	{
		new rounds = GetConVarInt(cvar_Rounds);
		if (rounds)
			g_iRoundTrigger += rounds;
		StartScrambleDelay(0.5, false, true);
	}
	else if (GetConVarBool(cvar_ForceBalance))
		CreateTimer(0.2, Timer_ForceBalance);
	
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

	/**
	check the timer entity, and see if its in setup mode
	as well as get the round duration for the countdown
	*/
	CreateTimer(1.0, Timer_GetTime, TIMER_FLAG_NO_MAPCHANGE);	
	g_iRoundStartTime = GetTime();
	
	/**
	reset
	*/
	g_bScrambleOverride = false;
	g_bWasFullRound = false;
	g_bRedCapped = false;
	g_bBluCapped = false;
	g_bScrambledThisRound = false;
}

/**
	forces balance if teams stay unbalacned too long
*/
public Action:Timer_ForceBalance(Handle:timer)
{	
	if (TeamsUnbalanced())
		BalanceTeams(true);
	g_aTeams[bImbalanced] = false;
	g_hForceBalanceTimer = INVALID_HANDLE;
	return Plugin_Handled;
}

public Action:hook_Setup(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_RoundState = normal;
	CreateTimer(1.0, Timer_GetTime, TIMER_FLAG_NO_MAPCHANGE);
	g_iRoundStartTime = GetTime();
	if (g_aTeams[bImbalanced])
		StartForceTimer();
	return Plugin_Continue;
}

StartForceTimer(bool:autoTigger = false)
{
	if (g_hForceBalanceTimer != INVALID_HANDLE)
		KillTimer(g_hForceBalanceTimer);
	g_hForceBalanceTimer = INVALID_HANDLE;
	new Float:fDelay;
	if (autoTigger)
		fDelay = 0.1;
	else if (g_RoundState == normal)
	{
		if (!(fDelay= GetConVarFloat(cvar_MaxUnbalanceTime)))
			return;
	}	
	g_hForceBalanceTimer = CreateTimer(fDelay, Timer_ForceBalance, TIMER_FLAG_NO_MAPCHANGE);
}

public hook_Win(Handle:event, const String:name[], bool:dontBroadcast)
{	
	g_RoundState = bonusRound;	
	g_bWasFullRound = false;	
	if (GetEventBool(event, "full_round"))
	{
		g_bWasFullRound = true;
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

bool:WinStreakCheck(winningTeam)
{
	if (g_bScrambleNextRound || !g_bWasFullRound)
		return false;
	if (GetConVarBool(cvar_Rounds) && g_iRoundTrigger == g_iCompleteRounds)
	{
		PrintToChatAll("\x01\x04[SM]\x01 %t", "RoundMessage");
		LogAction(0, -1, "Rount limit reached");
		return true;
	}
	if (!GetConVarBool(cvar_WinStreak))
		return false;
	if (winningTeam == TEAM_RED)
	{
		if (g_aTeams[iBluWins] >= 1)
			g_aTeams[iBluWins] = 0;	
		g_aTeams[iRedWins]++;
		if (g_aTeams[iRedWins] >= GetConVarInt(cvar_WinStreak))
		{
			PrintToChatAll("\x01\x04[SM]\x01 %t", "RedStreak");
			LogAction(0, -1, "Red win limit reached");
			return true;
		}
	}
	if (winningTeam == TEAM_BLUE)
	{
		if (g_aTeams[iRedWins] >= 1)
			g_aTeams[iRedWins] = 0;
		g_aTeams[iBluWins]++;
		if (g_aTeams[iBluWins] >= GetConVarInt(cvar_WinStreak))
		{
			PrintToChatAll("\x01\x04[SM]\x01 %t", "BluStreak");
			LogAction(0, -1, "Blu win limit reached");
			return true;
		}
	}
	return false;
}

public Action:hook_Death(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if (g_bBlockDeath) 
		return Plugin_Handled;
		
	if (g_RoundState != normal || GetEventInt(event, "death_flags") & 32) 
		return Plugin_Continue;
		
	new k_client = GetClientOfUserId(GetEventInt(event, "attacker"));
		
	new	v_client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_aTeams[bImbalanced] && g_bAutoBalance && GetClientTeam(v_client) == g_aTeams[iLargerTeam])	
		CreateTimer(0.1, timer_StartBalanceCheck, v_client, TIMER_FLAG_NO_MAPCHANGE);
		
	if (!k_client || k_client == v_client || k_client > MaxClients)
		return Plugin_Continue;
		
	GetClientTeam(k_client) == TEAM_RED ? (g_aTeams[iRedFrags]++) : (g_aTeams[iBluFrags]++);	
	return Plugin_Continue;
}

public Action:timer_StartBalanceCheck(Handle:timer, any:client)
{
	if (g_aTeams[bImbalanced] && BalancePlayer(client))
		CheckBalance(true);
	return Plugin_Handled;
}

bool:BalancePlayer(client)
{
	if (!TeamsUnbalanced())
	{
		return true;
	}
	
	new team, bool:overrider = false, iTime = GetTime();
	new big = g_aTeams[iLargerTeam];
	team = big == TEAM_RED?TEAM_BLUE:TEAM_RED;
	
	/**
	checks for preferences to override the client so 
	*/
	if (GetConVarBool(cvar_Preference))
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == big && g_aPlayers[client][iTeamPreference] == team)
			{
				overrider = true;
				client = i;
				break;
			}
		}
	}
	
	if (!overrider)
	{
		if (!IsValidTarget(client, balance) || GetPlayerPriority(client) < 0)
			return false;	
	}
	else if (IsPlayerAlive(client))
		CreateTimer(0.5, Timer_BalanceSpawn, client);
	new String:sName[MAX_NAME_LENGTH + 1], String:sTeam[32];
	GetClientName(client, sName, 32);
	team == TEAM_RED ? (sTeam = "RED") : (sTeam = "BLU");
	g_bBlockDeath = true;
	ChangeClientTeam(client, team);
	g_bBlockDeath = false;
	g_aPlayers[client][iBalanceTime] = iTime + (GetConVarInt(cvar_BalanceTime) * 60);
	if (!IsFakeClient(client))
	{
		new Handle:event = CreateEvent("teamplay_teambalanced_player");
		SetEventInt(event, "player", client);
		SetEventInt(event, "team", team);
		SetupTeamSwapBlock(client);
		FireEvent(event);
	}
	LogAction(client, -1, "\"%L\" has been auto-balanced to %s.", client, sTeam);
	PrintToChatAll("\x01\x04[SM]\x01 %t", "TeamChangedAll", sName, sTeam);
	g_aTeams[bImbalanced]=false;
	return true;
}

CheckBalance(bool:post=false)
{
	if (g_hCheckTimer != INVALID_HANDLE)
		return;
		
	if (post)
	{
		g_hCheckTimer = CreateTimer(0.1, timer_CheckBalance);
		return;
	}
	if (TeamsUnbalanced())
	{
		if ((g_RoundState == normal || g_RoundState == setup) && !g_aTeams[bImbalanced] && g_hBalanceFlagTimer == INVALID_HANDLE)
		{
			new delay = GetConVarInt(cvar_BalanceActionDelay);
			if (delay > 1)
			{
				PrintToChatAll("\x01\x04[SM]\x01 %t", "FlagBalance", delay);
			}
			g_hBalanceFlagTimer = CreateTimer(float(delay), timer_BalanceFlag);			
		}
		if (g_RoundState == preGame || g_RoundState == bonusRound)
		{
			if (g_hBalanceFlagTimer != INVALID_HANDLE)
			{
				KillTimer(g_hBalanceFlagTimer);
				g_hBalanceFlagTimer = INVALID_HANDLE;
			}
			g_aTeams[bImbalanced] = true;
		}
	}
	else
	{
		g_aTeams[bImbalanced] = false;
		if (g_hBalanceFlagTimer != INVALID_HANDLE)
		{
			KillTimer(g_hBalanceFlagTimer);
			g_hBalanceFlagTimer = INVALID_HANDLE;
		}
		
	}
}

stock bool:TeamsUnbalanced()
{
	new iDiff = GetAbsValue(GetTeamClientCount(TEAM_RED), GetTeamClientCount(TEAM_BLUE));
	new iForceLimit = GetConVarInt(cvar_ForceBalanceTrigger);
	new iBalanceLimit = GetConVarInt(cvar_BalanceLimit);
	
	if (iDiff >= iBalanceLimit)
	{
		if (iForceLimit > 1 && iDiff >= iForceLimit)
		{
			BalanceTeams(true);

			if (g_hBalanceFlagTimer != INVALID_HANDLE)
			{
				KillTimer(g_hBalanceFlagTimer);
				g_hBalanceFlagTimer = INVALID_HANDLE;
			}
			return false;
		}
		return true;
	}
	return false;
}

stock GetAbsValue(value1, value2)
{
	return RoundFloat(FloatAbs(FloatSub(float(value1), float(value2))));
}

/**
flags the teams as being unbalanced
*/
public Action:timer_BalanceFlag(Handle:timer)
{	
	if (TeamsUnbalanced())
	{
		StartForceTimer();
		g_aTeams[bImbalanced] = true;
	}
	g_hBalanceFlagTimer = INVALID_HANDLE;
	return Plugin_Handled;
}

public Action:timer_CheckBalance(Handle:timer)
{
	g_hCheckTimer = INVALID_HANDLE;
	CheckBalance();
	return Plugin_Handled;
}

bool:IsNotTopPlayer(client, team)  // this arranges teams based on their score, and checks to see if a client is among the top X players
{
	new iSize, iHighestScore;
	decl iScores[MAXPLAYERS+1][2];
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{
			iScores[iSize][1] = 1 + TF2_GetPlayerResourceData(i, TFResource_TotalScore);
			iScores[iSize][0] = i;
			if (iScores[iSize][1] > iHighestScore)
				iHighestScore = iScores[iSize][1];
			iSize++;
		}
	}
	if (iHighestScore <= 10)
		return true;
	if (iSize < GetConVarInt(cvar_TopProtect) + 4)
		return true;
	SortCustom2D(iScores, iSize, SortScoreDesc);
	for (new i = 0; i < GetConVarInt(cvar_TopProtect); i++)
	{
		if (iScores[i][0] == client)
			return false;
	}
	return true;
}

bool:AmISomeonesBuddy(client)
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
	// first check for buddies. if the buddy is on the wrong team, we skip the rest of the immunity checks
	if (g_bUseBuddySystem)
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
		if (AmISomeonesBuddy(client))
			return false;
	}
	new e_Protection:iImmunity, String:flags[32]; // living players are immune
	if (mode == scramble)
	{
		iImmunity = e_Protection:GetConVarInt(cvar_ScrambleAdminImmune); // living plyers are not immune from scramble
		GetConVarString(cvar_ScrambleAdmFlags, flags, sizeof(flags));
	}
	else
	{
		iImmunity = e_Protection:GetConVarInt(cvar_BalanceImmunity);
		GetConVarString(cvar_BalanceAdmFlags, flags, sizeof(flags));
	}
	
	/*
		override immunities when things like alive or buildings done matter
	*/
	if (mode == autoScramble || (g_RoundState != normal && g_RoundState != setup))
	{
		if (iImmunity == both)
			iImmunity = admin;
		else if (iImmunity == uberAndBuildings)
			return true;
	}
	
	if (IsClientInGame(client) && IsValidTeam(client))
	{
		if (iImmunity == none) // if no immunity mode set, don't check for it :p
			return true;
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
	return false;
}

stock bool:TF2_HasBuilding(client)
{
	if (TF2_ClientBuilding(client, "obj_*"))
		return true;
	return false;
}
			
stock bool:IsAdmin(client, const String:flags[])
{
	new bits = GetUserFlagBits(client);	
	if (bits & ADMFLAG_ROOT)
		return true;
	new iFlags = ReadFlagString(flags);
	if (bits & iFlags)
		return true;	
	return false;
}

Float:GetClientScrambleScore(client, e_ScrambleModes:mode)
{
	if (mode == score)
		return float(TF2_GetPlayerResourceData(client, TFResource_TotalScore));
	new Float:fScore = float(TF2_GetPlayerResourceData(client, TFResource_TotalScore));
	fScore *= fScore;
	if (!IsFakeClient(client))
		fScore /= (GetClientTime(client)/60);
	return fScore;	
}

/**
helps decide how many people to swap to the team opposite the team with more
immune clients
*/
stock ScramblePlayers(e_ImmunityModes:immuneMode, e_ScrambleModes:scrambleMode)
{
	new i, iCount, iRedImmune, iBluImmune, iSwaps, iTempTeam,
		bool:bRed, iImmuneTeam, iImmuneDiff, client;
	new iValidPlayers[GetClientCount()];
	
	/**
	Start of by getting a list of the valid players and finding out who are immune
	*/
	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsValidTeam(i))
		{
			if (IsValidTarget(i, immuneMode))
			{
				iValidPlayers[iCount++] = i;
			}
			else
				GetClientTeam(i) == TEAM_RED ? iRedImmune++ : iBluImmune++;
		}
	}
	SetRandomSeed(2);
	if (g_iLastRoundWinningTeam)
	{
		bRed = g_iLastRoundWinningTeam == TEAM_BLUE;
	}
	else
	{
		bRed = GetRandomInt(0,1) == 0;
	}
	/**
	handle imbalance in imune teams
	find out which team has more immune members than the other
	*/
	if (iRedImmune != iBluImmune)
	{
		if ((iImmuneDiff = iRedImmune - iBluImmune) > 0)
		{
			iImmuneTeam = TEAM_RED;
		}
		else
		{
			iImmuneDiff *= -1;
			iImmuneTeam = TEAM_BLUE;
		}
		bRed = iImmuneTeam == TEAM_BLUE;
	}
	
	/**
	setup the swapping
	*/
	if (scrambleMode != random)
	{
		new Float:scoreArray[iCount][2];
		for (i = 0; i < iCount; i++)
		{
			scoreArray[i][0] = float(iValidPlayers[i]);
			scoreArray[i][1] = GetClientScrambleScore(iValidPlayers[i], scrambleMode);
		}
		
		/** 
		sort by lowest score, and even the immune imbalance if it exists
		*/
		if (iImmuneTeam)
		{
			SortCustom2D(_:scoreArray, iCount, SortScoreAsc);
			for (i = 0; i < (iImmuneDiff / 2) && i < iCount; i++)
			{
				client = RoundFloat(scoreArray[i][0]);
				g_bBlockDeath = true;
				iTempTeam = GetClientTeam(client);
				ChangeClientTeam(client, bRed ? TEAM_RED:TEAM_BLUE);
				g_bBlockDeath = false;
				iSwaps++;
				if (iTempTeam != GetClientTeam(client))
				{
					PrintCenterText(client, "%t", "TeamChangedOne");
				}
			}
		}
		
		/** 
		now sort score descending 
		and copy the array into the integer one
		*/
		SortCustom2D(_:scoreArray, iCount, SortScoreDesc);
		for (i = 0; i < iCount; i++)
			iValidPlayers[i] = RoundFloat(scoreArray[i][0]);
			
	}
	
	if (scrambleMode == random)
	{
		SortIntegers(iValidPlayers, iCount, Sort_Random);
	}
	
	new iTemp = iSwaps;
	for (i = iTemp; i < iCount; i++)
	{
		client = iValidPlayers[i];
		g_bBlockDeath = true;
		iTempTeam = GetClientTeam(client);
		ChangeClientTeam(client, bRed ? TEAM_RED:TEAM_BLUE);
		g_bBlockDeath = false;
		iSwaps++;
		if (GetClientTeam(client) != iTempTeam)
		{
			PrintCenterText(client, "%t", "TeamChangedOne");
		}
	}

	
	
	LogMessage("Scramble changed %i client's teams", iSwaps); 
	BlockAllTeamChange();
}

stock BlockAllTeamChange()
{
	for (new i=1; i <= MaxClients; i++)
	{
		if (!IsClientInGame(i) || !IsValidTeam(i) || IsFakeClient(i))
		{
			continue;
		}
		else
		{
			SetupTeamSwapBlock(i);
		}
	}
}
		
public Action:timer_ScrambleDelay(Handle:timer, any:data)  // scramble logic
{
	g_hScrambleDelay = INVALID_HANDLE;
	g_bScrambleNextRound = false;
	g_bScrambledThisRound = true;
	new e_ImmunityModes:immuneMode = scramble;
	ResetPack(data);
	new iAuto = ReadPackCell(data),
		respawn = ReadPackCell(data),
		e_ScrambleModes:scrambleMode = e_ScrambleModes:ReadPackCell(data);
	if (iAuto)
		immuneMode = autoScramble;
	g_aTeams[iRedWins] = 0;
	g_aTeams[iBluWins] = 0;
	g_aTeams[bImbalanced] = false;	
	
	ScramblePlayers(immuneMode, scrambleMode);
	
	EmitSoundToAll(SCRAMBLE_SOUND, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL); // TEAMS ARE BEING SCRAMBLED!
	DelayPublicVoteTriggering(true);
	new bool:spawn = false;
	if (respawn || g_bPreGameScramble)
		spawn = true;
	CreateTimer(0.1, timer_AfterScramble, spawn, TIMER_FLAG_NO_MAPCHANGE);	
	if (g_bPreGameScramble)
	{
		PrintToChatAll("\x01\x04[SM]\x01 %t", "PregameScrambled");
		g_bPreGameScramble = false;
	}
	else
		PrintToChatAll("\x01\x04[SM]\x01 %t", "Scrambled");		
	if (g_bIsTimer && g_RoundState == setup && GetConVarBool(cvar_SetupRestore))
		TF2_ResetSetup();
	return Plugin_Handled;
}

TF2_ResetSetup()
{
	g_iTimerEnt = FindEntityByClassname(-1, "team_round_timer");
	new setupDuration = GetTime() - g_iRoundStartTime; 
	SetVariantInt(setupDuration);
	AcceptEntityInput(g_iTimerEnt, "AddTime");
	g_iRoundStartTime = GetTime();
}

bool:AutoScrambleCheck(winningTeam)
{
	if (g_bFullRoundOnly && !g_bWasFullRound)
		return false;
	if (g_bKothMode)
	{
		if (!g_bRedCapped || !g_bBluCapped)
		{
			decl String:team[3];
			g_bRedCapped ? (team = "BLU") : (team = "RED");
			PrintToChatAll("\x01\x04[SM]\x01 %t", "NoCapMessage", team);
			LogAction(0, -1, "%s did not cap a point on KOTH", team);
			return true;
		}
	}
	new totalFrags = g_aTeams[iRedFrags] + g_aTeams[iBluFrags],
		losingTeam = winningTeam == TEAM_RED ? TEAM_BLUE : TEAM_RED,
		dominationDiffVar = GetConVarInt(cvar_DominationDiff);
	if (dominationDiffVar && totalFrags > 20)
	{
		new winningDoms = TF2_GetTeamDominations(winningTeam),
			losingDoms = TF2_GetTeamDominations(losingTeam);
		if (winningDoms > losingDoms)
		{
			new teamDominationDiff = RoundFloat(FloatAbs(float(winningDoms) - float(losingDoms)));
			if (teamDominationDiff >= dominationDiffVar)
			{
				LogAction(0, -1, "domination difference detected");
				PrintToChatAll("\x01\x04[SM]\x01 %t", "DominationMessage");
				return true;
			}	
		}
	}
	new Float:iDiffVar = GetConVarFloat(cvar_AvgDiff);
	if (totalFrags > 20 && iDiffVar > 0.0 && GetAvgScoreDifference(winningTeam) >= iDiffVar)
	{
		LogAction(0, -1, "Average score diff detected");
		PrintToChatAll("\x01\x04[SM]\x01 %t", "RatioMessage");
		return true;
	}
	new winningFrags = winningTeam == TEAM_RED ? g_aTeams[iRedFrags] : g_aTeams[iBluFrags],
		losingFrags	= winningTeam == TEAM_RED ? g_aTeams[iBluFrags] : g_aTeams[iRedFrags],
		Float:ratio = float(winningFrags) / float(losingFrags),
		iSteamRollVar = GetConVarInt(cvar_Steamroll),
		roundTime = GetTime() - g_iRoundStartTime;
	if (iSteamRollVar && winningFrags > losingFrags && iSteamRollVar >= roundTime && ratio >= GetConVarFloat(cvar_SteamrollRatio))
	{
		new minutes = iSteamRollVar / 60;
		new seconds = iSteamRollVar % 60;				
		PrintToChatAll("\x01\x04[SM]\x01 %t", "WinTime", minutes, seconds);
		LogAction(0, -1, "steam roll detected");
		return true;		
	}
	new Float:iFragRatioVar = GetConVarFloat(cvar_FragRatio);
	if (totalFrags > 20 && winningFrags > losingFrags && iFragRatioVar > 0.0)	
	{		
		if (ratio >= iFragRatioVar)
		{	
			PrintToChatAll("\x01\x04[SM]\x01 %t", "FragDetection");
			LogAction(0, -1, "Frag ratio detected");
			return true;			
		}
	}
	return false;
}

public Action:timer_AfterScramble(Handle:timer, any:spawn)
{
	
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "tf_ammo_pack")) != -1)
		AcceptEntityInput(iEnt, "Kill");
	TF2_RemoveRagdolls();
	
	if (spawn)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsValidTeam(i)	&& !IsPlayerAlive(i))
				TF2_RespawnPlayer(i);		
		}
	}
		
	if (g_RoundState == setup && GetConVarBool(cvar_SetupCharge))	
	{
		LogAction(0, -1, "Filling up medic cannons due to setting");
		for (new i= 1; i<=MaxClients; i++)
		{
			if (IsClientInGame(i) && IsValidTeam(i))
			{
				new TFClassType:class = TF2_GetPlayerClass(i);
				if (class == TFClass_Medic)
				{
					new index = GetPlayerWeaponSlot(i, 1);
					if (index)				
						SetEntPropFloat(index, Prop_Send, "m_flChargeLevel", 1.0);				
				}		
			}
		}
	}
	return Plugin_Handled;
}

SetupTeamSwapBlock(client)  /* blocks proper clients from spectating*/
{
	if (!g_bForceTeam)
		return;
	if (GetConVarBool(cvar_AdminImmune))
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
	g_aPlayers[client][iBlockWarnings] = 0;
}

stock StartScrambleDelay(Float:delay = 5.0, bool:auto = false, bool:respawn = false, e_ScrambleModes:mode = random)
{
	if (g_hScrambleDelay != INVALID_HANDLE)
	{
		KillTimer(g_hScrambleDelay);
		g_hScrambleDelay = INVALID_HANDLE;
	}
	if (mode == invalid)
		mode = e_ScrambleModes:GetConVarInt(cvar_SortMode);
	
	new Handle:data;
	g_hScrambleDelay = CreateDataTimer(delay, timer_ScrambleDelay, data, TIMER_FLAG_NO_MAPCHANGE);
	WritePackCell(data, auto);
	WritePackCell(data, respawn);
	WritePackCell(data, _:mode);
	if (delay == 0.0)
		delay = 1.0;	
	if (delay >= 2.0)
	{
		PrintToChatAll("\x01\x04[SM]\x01 %t", "ScrambleDelay", RoundFloat(delay));
		if (g_RoundState != bonusRound)
		{	
			EmitSoundToAll(EVEN_SOUND, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
			CreateTimer(1.7, TimerStopSound);
		}
	}
}

public Action:TimerStopSound(Handle:timer)	 // cuts off the sound after 1.7 secs so it only plays 'Lets even this out'
{
	for (new i=1; i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			StopSound(i, SNDCHAN_AUTO, EVEN_SOUND);
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
		new State = GetEntProp(g_iTimerEnt, Prop_Send, "m_nState");
		if (!State)		
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
		if (g_RoundState == setup)
			g_RoundState = normal;
		
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
		return 0;
	if (g_bUseBuddySystem)
	{
		if (g_aPlayers[client][iBuddy])
		{
			if (GetClientTeam(client) == GetClientTeam(g_aPlayers[client][iBuddy]))
				return -5;
			else if (IsValidTeam(g_aPlayers[client][iBuddy]))
				return 5;
		}
		if (AmISomeonesBuddy(client))
			return -2;
	}
	new iPriority;
	if (IsClientInGame(client) && IsValidTeam(client))
	{
		if (g_aPlayers[client][iBalanceTime] > GetTime())
			return -5;
				
		if (g_aPlayers[client][iTeamworkTime] >= GetTime())
			iPriority -= 3;
			
		if (g_RoundState != bonusRound)
		{
			if (TF2_HasBuilding(client)||TF2_IsClientUberCharged(client)||TF2_IsClientUbered(client)||
				!IsNotTopPlayer(client, GetClientTeam(client))||TF2_IsClientOnlyMedic(client))
				return -5;
			if (!IsPlayerAlive(client))
				iPriority += 2;
			else
				iPriority -= 1;
		}		
		/**
		make new clients more likely to get swapped
		*/
		if (GetClientTime(client) < 300)		
			iPriority += 1;	
	}
	return iPriority;
}

stock bool:TF2_IsClientUberCharged(client)
{
	if (!IsPlayerAlive(client))
		return false;
	new TFClassType:class = TF2_GetPlayerClass(client);
	if (class == TFClass_Medic)
	{			
		new iIdx = GetPlayerWeaponSlot(client, 1);
		if (iIdx > 0)
		{
			new Float:chargeLevel = GetEntPropFloat(iIdx, Prop_Send, "m_flChargeLevel");
			if (chargeLevel >= 0.40)	
			{
				return true;
			}
		}
	}
	return false;
}

stock bool:TF2_IsClientUbered(client)
{
	if (GetEntProp(client, Prop_Send, "m_nPlayerCond") & 32)
		return true;
	return false;
}

stock bool:TF2_ClientBuilding(client, const String:building[])
{
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, building)) != -1)
	{
		if (GetEntDataEnt2(iEnt, FindSendPropInfo("CBaseObject", "m_hBuilder")) == client)
			return true;
	}
	return false;
}

bool:IsValidTeam(client)
{
	new team = GetClientTeam(client);
	if (team == TEAM_RED || team == TEAM_BLUE)
		return true;
	return false;
}	

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))		
		g_hAdminMenu = INVALID_HANDLE;
}

public OnAdminMenuReady(Handle:topmenu)
{
	if (topmenu == g_hAdminMenu)
		return;
	g_hAdminMenu = topmenu;
	new TopMenuObject:menu_category = AddToTopMenu(g_hAdminMenu, "gScramble", TopMenuObject_Category, Handle_Category, INVALID_TOPMENUOBJECT);

	AddToTopMenu(g_hAdminMenu, "Start a Scramble", TopMenuObject_Item, AdminMenu_gScramble, menu_category, "sm_scrambleround", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "Start a Vote", TopMenuObject_Item, AdminMenu_gVote, menu_category, "sm_scrambleround", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "Reset Votes", TopMenuObject_Item, AdminMenu_gReset, menu_category, "sm_scramblevote", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "Force Team Balance", TopMenuObject_Item, AdminMenu_gBalance, menu_category, "sm_forcebalance", ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, "Cancel", TopMenuObject_Item, AdminMenu_gCancel, menu_category, "sm_cancel", ADMFLAG_BAN);
}

public Handle_Category(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	switch (action)
	{
		case TopMenuAction_DisplayTitle:
			Format( buffer, maxlength, "What do you want to do?" );
		case TopMenuAction_DisplayOption:
			Format(buffer, maxlength, "gScramble Commands");
	}
}

public AdminMenu_gCancel(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (g_bScrambleNextRound || g_hScrambleDelay != INVALID_HANDLE)		
			Format( buffer, maxlength, "Cancel (Pending Scramble)");
		else if (g_bAutoScramble && g_RoundState == bonusRound)
			Format( buffer, maxlength, "Cancel (Auto-Scramble Check)");
		else
			Format( buffer, maxlength, "Cancel (Nothing)");
	}
	else if( action == TopMenuAction_SelectOption)
		PerformCancel(param);
}

public AdminMenu_gBalance(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "Force-Balance Teams");
	else if( action == TopMenuAction_SelectOption)
		PerformBalance(param);
}

public AdminMenu_gReset(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "Reset Vote Triggers");
	else if( action == TopMenuAction_SelectOption)
		PerformReset(param);
}

public AdminMenu_gVote(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "Start a Scramble Vote");
	else if( action == TopMenuAction_SelectOption)
		ShowScrambleVoteMenu(param);
}

public AdminMenu_gScramble(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format( buffer, maxlength, "Start a Scramble");
	else if( action == TopMenuAction_SelectOption)
		ShowScrambleSelectionMenu(param);
}

/*******************************************
			tedious menu stuff
********************************************/

ShowScrambleVoteMenu(client)
{
	new Handle:scrambleVoteMenu = INVALID_HANDLE;
	scrambleVoteMenu = CreateMenu(Handle_ScrambleVote);
	
	SetMenuTitle(scrambleVoteMenu, "Choose a Method");
	SetMenuExitButton(scrambleVoteMenu, true);
	SetMenuExitBackButton(scrambleVoteMenu, true);
	AddMenuItem(scrambleVoteMenu, "round", "Vote for End-of-Round Scramble");
	AddMenuItem(scrambleVoteMenu, "now", "Vote for Scramble Now");
	DisplayMenu(scrambleVoteMenu, client, MENU_TIME_FOREVER);
}

ShowScrambleSelectionMenu(client)
{
	new Handle:scrambleMenu = INVALID_HANDLE;
	scrambleMenu = CreateMenu(Handle_Scramble);
	
	SetMenuTitle(scrambleMenu, "Choose a Method");
	SetMenuExitButton(scrambleMenu, true);
	SetMenuExitBackButton(scrambleMenu, true);
	AddMenuItem(scrambleMenu, "round", "Scramble Next Round");
	if (CheckCommandAccess(client, "sm_scramble", ADMFLAG_BAN))
		AddMenuItem(scrambleMenu, "now", "Scramble Teams Now");
	DisplayMenu(scrambleMenu, client, MENU_TIME_FOREVER);
}

public Handle_ScrambleVote(Handle:scrambleVoteMenu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new String:method[6], ScrambleTime:iMethod;
			GetMenuItem(scrambleVoteMenu, param2, method, sizeof(method));
			if (StrEqual(method, "round", true))
				iMethod = Scramble_Round;			
			else
				iMethod = Scramble_Now;
			PerformVote(client, iMethod);			
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack )
				RedisplayAdminMenu(g_hAdminMenu, client);
		}
		
		case MenuAction_End:
			CloseHandle(scrambleVoteMenu);	
	}
}

public Handle_Scramble(Handle:scrambleMenu, MenuAction:action, client, param2 )
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!param2)
				SetupRoundScramble(client);
			else
			{
				new Handle:scrambleNowMenu = INVALID_HANDLE;
				scrambleNowMenu = CreateMenu(Handle_ScrambleNow);
				
				SetMenuTitle(scrambleNowMenu, "Choose a Method");
				SetMenuExitButton(scrambleNowMenu, true);
				SetMenuExitBackButton(scrambleNowMenu, true);
				AddMenuItem(scrambleNowMenu, "5", "Delay 5 seconds");
				AddMenuItem(scrambleNowMenu, "15", "Delay 15 seconds");
				AddMenuItem(scrambleNowMenu, "30", "Delay 30 seconds");
				AddMenuItem(scrambleNowMenu, "60", "Delay 60 seconds");
				DisplayMenu(scrambleNowMenu, client, MENU_TIME_FOREVER);
			}
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack )
				RedisplayAdminMenu(g_hAdminMenu, client);
		}
		
		case MenuAction_End:
			CloseHandle(scrambleMenu);	
	}
}

public Handle_ScrambleNow(Handle:scrambleNowMenu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new Handle:respawnSelectMenu = INVALID_HANDLE;
			respawnSelectMenu = CreateMenu(Handle_RespawnMenu);
		
			if (g_hScrambleNowPack != INVALID_HANDLE)
				CloseHandle(g_hScrambleNowPack);
			g_hScrambleNowPack= CreateDataPack();
		
			SetMenuTitle(respawnSelectMenu, "Respawn Players After Scramble?");
			SetMenuExitButton(respawnSelectMenu, true);
			SetMenuExitBackButton(respawnSelectMenu, true);
		
			AddMenuItem(respawnSelectMenu, "Yep", "Yes");
			AddMenuItem(respawnSelectMenu, "Noep", "No");
			DisplayMenu(respawnSelectMenu, client, MENU_TIME_FOREVER);
			new String:delay[3];
			GetMenuItem(scrambleNowMenu, param2, delay, sizeof(delay));		
			WritePackFloat(g_hScrambleNowPack, StringToFloat(delay));
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack )
				RedisplayAdminMenu( g_hAdminMenu, client );
		}
	
		case MenuAction_End:
			CloseHandle(scrambleNowMenu);
	}
}

public Handle_RespawnMenu(Handle:scrambleResetMenu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			new respawn = !param2 ? 1 : 0 ;
			WritePackCell(g_hScrambleNowPack, respawn);
			
			new Handle:modeSelectMenu = INVALID_HANDLE;
			modeSelectMenu = CreateMenu(Handle_ModeMenu);
			
			SetMenuTitle(modeSelectMenu, "Select a scramble sort mode");
			SetMenuExitButton(modeSelectMenu, true);
			SetMenuExitBackButton(modeSelectMenu, true);
			
			AddMenuItem(modeSelectMenu, "1", "Random");
			AddMenuItem(modeSelectMenu, "2", "Player-Score");
			AddMenuItem(modeSelectMenu, "3", "Player-Score^2/Connect time (in minutes)");
			DisplayMenu(modeSelectMenu, client, MENU_TIME_FOREVER);
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				RedisplayAdminMenu( g_hAdminMenu, client);
		}
		
		case MenuAction_End:
			CloseHandle(scrambleResetMenu);
			
	}
}

public Handle_ModeMenu(Handle:modeMenu, MenuAction:action, client, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			ResetPack(g_hScrambleNowPack);
			new e_ScrambleModes:mode,
				Float:delay = ReadPackFloat(g_hScrambleNowPack),
				bool:respawn = ReadPackCell(g_hScrambleNowPack) ? true : false;
			mode = e_ScrambleModes:(param2+1);
			CloseHandle(g_hScrambleNowPack);
			g_hScrambleNowPack = INVALID_HANDLE;
			PerformScrambleNow(client, delay, respawn, mode);		
		}
		
		case MenuAction_Cancel:
		{
			if (param2 == MenuCancel_ExitBack)
				RedisplayAdminMenu( g_hAdminMenu, client);
		}
		
		case MenuAction_End:
			CloseHandle(modeMenu);
	}
}

public SortScoreDesc(x[], y[], array[][], Handle:data)
{
    if (Float:x[1] > Float:y[1])
        return -1;
	else if (Float:x[1] < Float:y[1])
		return 1;
    return 0;
}

public SortScoreAsc(x[], y[], array[][], Handle:data)
{
    if (Float:x[1] > Float:y[1])
        return 1;
	else if (Float:x[1] < Float:y[1])
		return -1;
    return 0;
}


stock TF2_GetPlayerDominations(client)
{
	new offset = FindSendPropInfo("CTFPlayerResource", "m_iActiveDominations"),
		ent = FindEntityByClassname(-1, "tf_player_manager");
	if (ent != -1)
		return GetEntData(ent, (offset + client*4), 4);	
	return 0;
}

stock TF2_GetTeamDominations(team)
{
	new dominations;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
			dominations += TF2_GetPlayerDominations(i);
	}
	return dominations;
}

stock bool:TF2_IsClientOnlyMedic(client)
{
	if (TFClassType:TF2_GetPlayerClass(client) != TFClass_Medic)
		return false;
	new clientTeam = GetClientTeam(client);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (i != client && IsClientInGame(i) && GetClientTeam(i) == clientTeam && TFClassType:TF2_GetPlayerClass(i) == TFClass_Medic)
			return false;
	}
	return true;
}

public Action:UserMessageHook_Class(UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init) 
{	
	if (!g_bHooked || g_RoundState != bonusRound)	
		return Plugin_Continue;
	new String:strMessage[50];
	BfReadString(bf, strMessage, sizeof(strMessage), true);
	if (StrContains(strMessage, "#TF_TeamsSwitched", true) != -1)
	{
		SwapPreferences();
		new oldRed = g_aTeams[iRedWins], oldBlu = g_aTeams[iBluWins];
		g_aTeams[iRedWins] = oldBlu;
		g_aTeams[iBluWins] = oldRed;
		g_iTeamIds[0] == TEAM_RED ? (g_iTeamIds[0] = TEAM_BLUE) :  (g_iTeamIds[0] = TEAM_RED);
		g_iTeamIds[1] == TEAM_RED ? (g_iTeamIds[1] = TEAM_BLUE) :  (g_iTeamIds[1] = TEAM_RED);
	}
	return Plugin_Continue;
}

stock TF2_RemoveRagdolls()
{
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "tf_ragdoll")) != -1)
		AcceptEntityInput(iEnt, "Kill");
}

	/**
	find anyone who was recently teamswapped as a result of our reconnecting person
	and ask if they want to get put back on their old team
	*/
	
void:RestoreMenuCheck(rejoinClient, team)
{
/**
find out who was the last one swapped
*/
	new client, iTemp;
	for (new i = 1; i<= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == team)
		{
			if (g_aPlayers[i][iBalanceTime] > GetTime() && g_aPlayers[i][iBalanceTime] > iTemp)
			{
				client = i;
				iTemp = g_aPlayers[i][iBalanceTime];
			}
		}
	}
	if (!client)
		return;
	decl String:name[MAX_NAME_LENGTH+1];
	GetClientName(rejoinClient, name, sizeof(name));
	
	PrintToChat(client, "\x01\x04[SM]\x01 %t", "RestoreInnocentTeam", name);
	
	new Handle:RestoreMenu = INVALID_HANDLE;
	RestoreMenu = CreateMenu(Handle_RestoreMenu);
	
	SetMenuTitle(RestoreMenu, "Retore your old team?");
	AddMenuItem(RestoreMenu, "yes", "Yes");
	AddMenuItem(RestoreMenu, "no", "No");
	DisplayMenu(RestoreMenu, client, 20);
}

AddBuddy(client, buddy)
{
	if (!client || !buddy || !IsClientInGame(client) || !IsClientInGame(buddy) || client == buddy)
		return;
	if (g_aPlayers[buddy][iBuddy])
	{
		PrintToChat(client, "\x01\x04[SM]\x01 %t", "AlreadyHasABuddy");
		return;
	}
	new String:clientName[MAX_NAME_LENGTH],
		String:buddyName[MAX_NAME_LENGTH];
	GetClientName(client, clientName, sizeof(clientName));
	GetClientName(buddy, buddyName, sizeof(buddyName));
	
	if (g_aPlayers[client][iBuddy])
		PrintToChat(g_aPlayers[client][iBuddy], "\x01\x04[SM]\x01 %t", "ChoseANewBuddy", clientName);
	
	g_aPlayers[client][iBuddy] = buddy;
	PrintToChat(buddy, "\x01\x04[SM]\x01 %t", "SomeoneAddedYou", clientName);
	PrintToChat(client, "\x01\x04[SM]\x01 %t", "AddedBuddy", buddyName);
}

ShowBuddyMenu(client)
{
	new Handle:menu = INVALID_HANDLE;
	menu = CreateMenu(BuddyMenuCallback);
	AddTargetsToMenu(menu,0);
	DisplayMenu(menu, client, MENU_TIME_FOREVER);
}

public BuddyMenuCallback(Handle:menu, MenuAction:action, client, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			new String:selection[10];
			GetMenuItem(menu, param2, selection, sizeof(selection));
			AddBuddy(client, GetClientOfUserId(StringToInt(selection)));			
		}
		
		case MenuAction_End:
			CloseHandle(menu);
	}
}

/**
 ask a client if they want to rejoin their old team when they get balanced due to a disconnecting player
 and that player reconnects and gets forced back to his old team
*/
public Handle_RestoreMenu(Handle:RestoreMenu, MenuAction:action, client, param2)
{
	switch (action)
	{
		case MenuAction_Select:
		{
			if (!param2)
			{
				decl String:name[MAX_NAME_LENGTH+1];
				GetClientName(client, name, sizeof(name));
				PrintToChatAll("\x01\x04[SM]\x01 %t", "RejoinMessage", name);
				g_bBlockDeath = true;
				CreateTimer(0.1, Timer_BalanceSpawn, client);
				ChangeClientTeam(client, GetClientTeam(client) == TEAM_RED ? TEAM_BLUE : TEAM_RED);
				g_bBlockDeath = false;
				g_aPlayers[client][iBalanceTime] = GetTime();
			}
		}
	
		case MenuAction_End:
			CloseHandle(RestoreMenu);
	}
}

bool:CheckSpecChange(client)
{
	if (GetConVarBool(cvar_AdminImmune))
	{
		new String:flags[32];
		GetConVarString(cvar_TeamswapAdmFlags, flags, sizeof(flags));
		if (IsAdmin(client, flags))
			return false;
	}
	new redSize = GetTeamClientCount(TEAM_RED),
		bluSize = GetTeamClientCount(TEAM_BLUE),
		difference;
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

public SortIntsDesc(x[], y[], array[][], Handle:data)		// this sorts everything in the info array descending
{
    if (x[1] > y[1]) 
		return -1;
    else if (x[1] < y[1]) 
		return 1;    
    return 0;
}
