/*		
1.5	- attempts to check to see if the map is going to change before running an auto-scramble		
	New cvar:
	- gscramble_timeleft_skip "0" if there is this many minutes or less remaining, stop scrambling		
	- tweaked some timer values, and settings. 		
1.6  	
	- added command to force a team balance
	- added cvar to enable/disable pre-game scrambles
	- block people from spectating when the plugin joins their team based on cvar setting
	- cleaned up/removed some pointless code
	- option to force a team balance between rounds	
1.7
	- admin-started vote scramble menu vote
	- votemode for public g_iVotes. 0 = normal just chat triggering, 1 = triggers a menu vote
	- new cvars (seperate %'s for public votes, and menu votes)
	- cvar for admin flag who can start scramble votes
1.7.1
	- track consecutive wins for scramble
	- option to scramble only after a full round	
1.7.2
	- cleaned up some code
	- fixed an error with reading the admin flag cvars	
1.7.3
	- added gScramble admin menu category
	- fixed issue with force balance	
1.7.4
	- added option to restart the round after the 'now' command is used
	- blocked all spectating after a scramble	
1.7.5
	- attempts to save timeleft and team scores when the round is restarted as a result of scramble_now
	- Thank you MikeJS for the help :D	
1.7.6
	- fixed scramble now vote	
1.7.61
	- added [gs] tags to text
	- increased score resetting timer to 5 	
1.7.62
	- add full-round check to the vote callback
	- fix bug with round-end full round checking
	- got rid of that dumb stuff that doesnt let people have low vote percentages if they use min players	
1.7.63
	- fixed some reading of custom admin flags for menu commands
	- use ExtendMapTimeLimit for more accurate saving of the timeleft when round is restarted
	- still looking for how to control the spawn gates :(
	- fixed fucking up the join team messages D:<	
1.7.64
	- add new methods of scramling based on player score.	
	1.7.65
	- renamed global vars to be more easily read
	- made a float array so that players can be sorted based on score per minute instead of score per hour	
1.7.66
	- removed an old line of code for dubugging. Never worked anyway, but still dumb for leaving it in
	- fixed full-round-only checking for player votescrambles
	- pre-game scrambles now only use the random player sorting method	
1.7.67
	- more code cleanup and simplification (better functioning for spectate blocking i hope :)
	- option to make admins immune from spectating blocking	
1.7.68
	- while going thru the code on my cleanup expedition, noticed something that might mess up people's full-round-only settings.	
1.7.69
	- fix stupid bug that broke team balance thing	
1.7.70
	- Block player_death messages & death logging during a scramble. For those worried about their precious stats getting forked up. :)	
1.7.71
	- Added option to make public-triggered votes scramble now or at round end
	- Added delay to all scramble now triggers + message
	- Reads #of voters on && gets vote % on plugin start
	- command to reset public scramble votes
	- renamed cvars and commands to have gs_ prefix instead of gscramble (let it regenerate the config file)
	- re-ordered the cvars more logically 	
1.7.2 & 3
	- fixed a few typos
	- updated message when voting is delayed 
	- made all scrambles use the StartScrambleDelay function
	- renamed the commands again to be less stupid
	- arg typo that broke round & winlimit detection from scramble canceling
	- added proper resets to the game start event for when games get restarted (everyone leaving, mp_restartgame...)
	- argggg another typo, broke AutoScramble setting detection
1.7.74
    - with death events blocked, added center message to clients who's teams are changed during scramble
    - got rid of some more pointless stuff
    - fixed blocking death event during bonus round
    - sorry for all these updates, but i keep noticing things, and am never satisfied with the plugin :)
1.7.75
	- fix ANOTHER dumb typo with admin_falg cvar reading. :(
	- added check for the new arena_queue enable cvar
1.7.76
	- replace [gs] tags with [sm]
	- tweak forcebalance. works for me =\
	- fix scramble being able to be canceled after bonusround timer has started
1.7.77
	- add team_balance event firing to force balance
	- still works for me =\
1.7.78
	- AHAHAHAHAHAHAHA found the team balance error, never tested it with spectators. D:<
1.7.79
	- ROAR accidentally made it so it balanced ONLY people with reservation flag, fixed it D:<
1.7.8
	- enchance team change blocking so that all team changes are blocked if the client tries to use jointeam command.  
		team changes initaited by admin command, or by the server should not be affected. :)
	- fix 'invalid timer' error, hopefully
1.7.8.1
	- fix forcebalance not working if admins disable auto-scramble and win-streak scramble
1.7.8.2
	- couple more fixes. cvars were affecting things they should not have been
1.7.9
	- when force balance is used, prioritize dead people or people without a sentry or people without uber charged up
1.8.0
	- added option for autoscramble to start a scramblenow vote instead of doing a scramble
	- some other minor fixes and optimizations
	- renamed specblock cvar to more accurately describe what it's really doing (blocking team changes)
1.8.1
	- added immunity option for admins and reservation flag during scramble
	- added root admin flag check for immunity during team balance
	- renamed teamswitch cvar to be more specific with addition of scramble immunity cvar
1.8.2
	- add seperate cancel command that can cancel any pending scramble
	- simplified team join blocker code. just blocks jointeam command, people attempting to change teams no longer are killed
	- got rid of timers and handles for block period, now it just sees if the TimeBlocked - TimeASwapIsAttempted <= BlockTime
	- added option for admins to punish people trying to re-stack teams by adding time to their jointeam block period
	- added public message for when clients try to re-stack teams to discourage it
1.8.2.5
	- TRANSLATION SUPPORT YAY
1.8.2.6
	- fix votes not resetting after a failed vote
1.8.2.7
	- included client name in team change block logging
	- fixed scramble not resetting on map change
	- code refining
	- added logaction lines for SM logs, and admin logging if you use it :)
1.8.2.8
	- add tf_game_over hook to cancel scramble and blaance timers when the map is ending
	- increase balance delay so game_over hook can cancel it if the map's ending
	- i don't think there is a perfect way to detect the map ending before the game_over event fires. :(
1.8.29
	- move scramble trigger and balance trigger to the round_start event.  Now if the map is ending, there should never be a force balance or scramble.
	- required a new line in the translations, so better download that too
1.8.3
	- add disable cvar to disable the plugin and unhook events
	- jointeam isn't blocked if the teams are uneven
	- added cvar to make medics with ubers and engies with buildings immune from the scramble
	- code cleanup and optimize, and make it easier to manipulate, removed some pointless timers
	- danish translations from OziOn
	- changed some cvar desriptions to make more sense
	- add more log messages to keep track of what the plugin is doing (mostly for my debugging)
	- made the teams swap detection better and shorter (mostly antithsys's code). no longer need player_team hook
	- returns 0 priority if during the bonus round
1.8.31
	- testing automated balancer
	- re-add player_team hook to stop chat spam during scramble
	- add a function/cvar to protect the top X players on a team from being auto balanced
	- checks for the simple team manager plugin to attempt to block the sm_swapteam command
1.8.32
	- renamed convars to be more descriptive
	- added option to make admins or high priortiy players or no one immune to team balance/scramble
1.8.33
	- forgot to add the valid target checking to the autobalance, it was still hardcoded to protect admins
	- spanish translation from jack_wade, thanks!
1.8.34
	- add team change block to the player_team event
*/
#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <sdktools_sound>
#include <tf2>
#include <tf2_stocks>
#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN
#define VERSION "1.8.33"
#define TEAM_RED 2
#define TEAM_BLUE 3
#define TEAM_SPEC 1
#define TEAM_UNSIG 0
#define SCRAMBLE_SOUND 	"vo/announcer_am_teamscramble03.wav"
#define EVEN_SOUND		"vo/announcer_am_teamscramble01.wav"
#define VOTE_NAME		0
#define VOTE_NO 		"###no###"
#define VOTE_YES 		"###yes###"
new Handle:cvar_Steamroll 			= INVALID_HANDLE;
new Handle:cvar_Needed 				= INVALID_HANDLE;
new Handle:cvar_Delay 				= INVALID_HANDLE;
new Handle:cvar_MinPlayers 			= INVALID_HANDLE;
new Handle:cvar_MinAutoPlayers 		= INVALID_HANDLE;
new Handle:cvar_FragRatio 			= INVALID_HANDLE;
new Handle:cvar_AutoScramble 		= INVALID_HANDLE;
new Handle:cvar_VoteEnable 			= INVALID_HANDLE;
new Handle:cvar_TimeLeft 			= INVALID_HANDLE;
new Handle:cvar_BalanceFlag 		= INVALID_HANDLE;
new Handle:cvar_WaitScramble 		= INVALID_HANDLE;
new Handle:cvar_SpecBlock 			= INVALID_HANDLE;
new Handle:cvar_ForceBalance 		= INVALID_HANDLE;
new Handle:cvar_bonusRound 			= INVALID_HANDLE;
new Handle:cvar_SteamrollRatio 		= INVALID_HANDLE;
new Handle:cvar_VoteFlag			= INVALID_HANDLE;
new Handle:g_hScrambleVoteMenu 		= INVALID_HANDLE;
new Handle:cvar_VoteMode			= INVALID_HANDLE;
new Handle:cvar_PublicNeeded		= INVALID_HANDLE;
new Handle:cvar_FullRoundOnly		= INVALID_HANDLE;
new Handle:cvar_WinStreak			= INVALID_HANDLE;
new Handle:cvar_SortMode			= INVALID_HANDLE;
new Handle:cvar_AdminImmune			= INVALID_HANDLE;
new Handle:cvar_VoteEnd				= INVALID_HANDLE;
new Handle:cvar_AutoscrambleVote	= INVALID_HANDLE;
new Handle:cvar_ScrambleAdminImmune	= INVALID_HANDLE;
new Handle:cvar_Log					= INVALID_HANDLE;
new Handle:g_hVoteDelayTimer 			= INVALID_HANDLE;
new Handle:cvar_ScrambleNowFlag 		= INVALID_HANDLE;
new Handle:g_hScrambleDelay				= INVALID_HANDLE;
new Handle:cvar_Punish				= INVALID_HANDLE;
new Handle:cvar_Balancer			= INVALID_HANDLE;
new Handle:cvar_BalanceTime			= INVALID_HANDLE;
new Handle:cvar_TopProtect			= INVALID_HANDLE;
new Handle:cvar_BalanceLimit		= INVALID_HANDLE;
new Handle:cvar_BalanceImmunity		= INVALID_HANDLE;

new Handle:cvar_Arena							= INVALID_HANDLE;
new Handle:cvar_ArenaQueue			= INVALID_HANDLE;
new Handle:g_hAdminMenu 						= INVALID_HANDLE;
new Handle:cvar_Enabled				= INVALID_HANDLE;

new bool:g_bScramble = false;		// triggers a scramble
new bool:g_bScrambling = false;		// true when scramble function is active
new bool:g_bVoteAllowed; 			// allows/disallows voting
new bool:g_bBonusRound; 			// toggles if the bonus round is active so that any scramble toggles happen instantly
new bool:g_bScrambleNow;			// if this is true, the scramble command will repsawn dead players
new bool:g_bVoteTimeAllowed = true; 	// menu votes
new bool:g_bWasFullRound = false;		// true if the last round was a full round
new bool:g_bPreGameScramble;
new bool:g_bDisablePrioity; 

new g_iRoundStartTime;
new g_iTeamDifference;
new g_iVotes;
new g_iVoters;
new g_iVotesNeeded;
new g_iRedFrags;
new g_iBluFrags;
new g_iRedScore;
new g_iBluScore;
new g_iCompleteRrounds;
new g_iRoundStarts;
new g_iFatSize;
new gamerules = -1;
new String:g_sLogFile[64];
new String:g_sVoteInfo[3][65];
new g_iFatTeam[MAXPLAYERS+1][2];
new bool:g_bHasVoted[MAXPLAYERS + 1];
new g_iBlockTime[MAXPLAYERS +1];
new g_iWins[4];
new bool:g_bLog;
new g_iBlockWarnings[MAXPLAYERS + 1];
new bool:g_bHooked = false;
new g_iPlayersTeam[MAXPLAYERS +1]; // saves players teams from round to round to test to see if teams were swapped
new g_iBalanceTime[MAXPLAYERS +1];

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
	cvar_Enabled			= CreateConVar("gs_enabled", 		"1",		"Enable/disable the plugin and all its hooks.", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	cvar_Balancer		=	CreateConVar("gs_autobalance",	"0",	"Enable/disable the autobalance feature of this plugin.\nUse only if you have the built-in balancer disabled.", FCVAR_PLUGIN, true, 0.0, true, 1.0);	
	cvar_TopProtect	= CreateConVar("gs_ab_protect", "5",	"How many of the top players to protect on each team from autobalance.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_BalanceTime	= 	CreateConVar("gs_ab_balancetime",	"5",			"Time in minutes after a client is balanced in which they cannot be balanced again.", FCVAR_PLUGIN);
	cvar_BalanceLimit	=	CreateConVar("gs_ab_unbalancelimit",	"2",	"If one team has this many more players than the other, then consider the teams imbalanced.", FCVAR_PLUGIN);
	cvar_BalanceImmunity =	CreateConVar("gs_ab_immunity",			"0",	"Controls who is immune from auto-balance\n0 = no immunity\n1 = admins\n2 = engies with buildings\n3 = both admins and engies with buildings", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	
	cvar_ForceBalance 		= CreateConVar("gs_force_balance",	"0", 		"Force a balance between each round. (If you use a custom team balance plugin that doesn't do this already, or you have the default one disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AdminImmune		= CreateConVar("gs_teamswitch_immune",	"1",	"Sets if admins are immune from team swap blocking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ScrambleAdminImmune = CreateConVar("gs_scramble_immune", "0",		"Sets if admins and people with uber and engie buildings are immune from being scrambled.\n0 = no immunity\n1 = just admins\n2 = charged medics + engineers with buildings\n3 = admins + charged medics and engineers with buildings.", FCVAR_PLUGIN, true, 0.0, true, 3.0);
	cvar_BalanceFlag 		= CreateConVar("gs_flag_balance", 	"b", 		"Admin flag for those allowed to force a team balance", FCVAR_PLUGIN);
	cvar_ScrambleNowFlag 	= CreateConVar("gs_flag_now", 		"n", 		"Admin flag for who has access to scramble teams now.", FCVAR_PLUGIN);
	cvar_VoteFlag			= CreateConVar("gs_flag_vote",		"b",		"Admin flag for those allowed to start a scramble vote", FCVAR_PLUGIN);
	
	cvar_Log				= CreateConVar("gs_logactivity",		"0",		"Log all activity of the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	cvar_WaitScramble 		= CreateConVar("gs_prescramble", 	"0", 		"If enabled, teams will scramble at the end of the 'waiting for players' period", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_VoteMode			= CreateConVar("gs_public_votemode",	"0",		"For public chat votes: 0 = if enough triggers, enable scramble.  1 = if enough triggers, start menu vote to start a scramble", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_PublicNeeded		= CreateConVar("gs_public_triggers", 	"0.60",		"Percentage of people needing to trigger a scramble in chat.  If using votemode 1, I suggest you set this lower than 50%", FCVAR_PLUGIN, true, 0.05, true, 1.0);
	cvar_VoteEnable 		= CreateConVar("gs_public_votes",	"1", 		"Enable/disable public voting", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Punish				= CreateConVar("gs_punish_stackers", "0", 		"Punish clients trying to restack teams during the team-switch block period by adding time to when they are able to team swap again", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SortMode			= CreateConVar("gs_sort_mode",		"1",		"Player scramble sort mode.\n1 = Random\n2 = Player Score\n3 = Player Score Per Minute.\nThis controls how players get swapped during a scramble.", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	cvar_SpecBlock 			= CreateConVar("gs_changeblocktime",	"120", 		"Time after being swapped by a scramble where players aren't allowed to change teams", FCVAR_PLUGIN, true, 0.0, false);
	cvar_VoteEnd			= CreateConVar("gs_menu_votebehavior",	"0",		"0 will trigger scramble for round end.\n1 will scramble teams after vote.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Needed 			= CreateConVar("gs_menu_votesneeded", 	"0.60", 	"Percentage of votes for the menu vote scramble needed.", FCVAR_PLUGIN, true, 0.05, true, 1.0);
	cvar_Delay 				= CreateConVar("gs_vote_delay", 		"60.0", 	"Time in seconds after the map has started in which players can beging to votescramble.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_MinPlayers 		= CreateConVar("gs_vote_minplayers",	"6", 		"Minimum poeple connected before any voting will work.", FCVAR_PLUGIN, true, 0.0, false);
	
	cvar_WinStreak			= CreateConVar("gs_winstreak",		"0", 		"If set, it will scramble after a team wins X full rounds in a row", FCVAR_PLUGIN, true, 0.0, false);

	cvar_TimeLeft 			= CreateConVar("gs_as_timeleftstop",	"0", 		"If there is this many minutes or less remaining, stop autoscrambling", FCVAR_PLUGIN, true, 0.0, false);
	cvar_AutoScramble		= CreateConVar("gs_autoscramble",	"1", 		"Enables/disables the automatic scrambling.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_FullRoundOnly 		= CreateConVar("gs_as_fullroundonly",	"0",		"Auto-scramble only after a full round has completed.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AutoscrambleVote	= CreateConVar("gs_as_vote",		"0",		"Starts a scramble vote instead of scrambling at the end of a round", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MinAutoPlayers 	= CreateConVar("gs_as_minplayers", "12", 		"Minimum people connected before automatic scrambles are possible", FCVAR_PLUGIN, true, 0.0, false);
	cvar_FragRatio 			= CreateConVar("gs_as_hfragratio", 		"2.0", 		"If a teams wins with a frag ratio greater than or equal to this setting, trigger a scramble", FCVAR_PLUGIN, true, 1.2, false);
	cvar_Steamroll 			= CreateConVar("gs_as_wintimelimit", 	"120.0", 	"If a team wins in less time, in seconds, than this, and has a frag ratio greater than specified: perform an auto scramble.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_SteamrollRatio 	= CreateConVar("gs_as_wintimeratio", 	"1.5", 		"Lower kill ratio for teams that win in less than the wintime_limit.", FCVAR_PLUGIN, true, 0.0, false);	
	
	CreateConVar("sm_gscramble_version", VERSION, "Gscramble version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	cvar_bonusRound 	= FindConVar("mp_bonusroundtime");
	cvar_Arena 			= FindConVar("tf_gamemode_arena");
	cvar_ArenaQueue		= FindConVar("tf_arena_use_queue");
	
	RegAdminCmd("sm_scrambleround", 	cmd_Scramble, ADMFLAG_BAN, "Scrambles at the end of the bonus round");
	RegAdminCmd("sm_cancel", 			cmd_Cancel, ADMFLAG_BAN, "Cancels any active scramble, and scramble timer.");
	RegAdminCmd("sm_resetvotes",		cmd_ResetVotes, ADMFLAG_BAN, "Resets all public votes.");
	RegConsoleCmd("sm_scramblenow", 	cmd_Scramble_Now, "Scrambles NOW. sm_scramble_now <0/1> 1 restarts the round");
	RegConsoleCmd("sm_forcebalance",	cmd_Balance, "Forces a team balance if an imbalance exists.");
	RegConsoleCmd("sm_scramblevote",	cmd_Vote, "Start a vote. sm_scramblevote <now/end>");	
	RegConsoleCmd("say", 			command_Say);
	RegConsoleCmd("say_team", 		command_Say);
	RegConsoleCmd("jointeam",		cmd_JoinTeam);
	RegConsoleCmd("spectate", 		cmd_JoinSpec);
	
	HookConVarChange(cvar_Log, LogSettingChange);
	HookConVarChange(cvar_Enabled, EnabledChage);
	AutoExecConfig(true, "plugin.gscramble");
	
	LoadTranslations("common.phrases");
	LoadTranslations("gscramble.phrases");
	
	new Handle:gTopMenu;
	if (LibraryExists("adminmenu") && ((gTopMenu = GetAdminTopMenu()) != INVALID_HANDLE))
	{
		OnAdminMenuReady(gTopMenu);
	}
	BuildPath(Path_SM, g_sLogFile, sizeof(g_sLogFile), "logs/gscramble.log");
	
	for (new i = 1; i<=MaxClients;i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i))
			g_iVoters++;
	}
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
}

public LogSettingChange(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0) 
		g_bLog = false;
	else 
		g_bLog = true;
}

public OnConfigsExecuted()
{
	if (GetConVarBool(cvar_Enabled) && !g_bHooked)
	{
		HookEvent("teamplay_round_start", 		hook_Start, EventHookMode_Post);
		HookEvent("teamplay_round_win", 		hook_Win, EventHookMode_Post);
		HookEvent("teamplay_setup_finished", 	hook_Setup, EventHookMode_Post);
		HookEvent("player_death", 				hook_Death, EventHookMode_Pre);
		HookEvent("game_start", 				hook_Event_GameStart);
		HookEventEx("teamplay_restart_round", 	hook_Event_TFRestartRound);
		HookEvent("tf_game_over",				hook_Event_tf_game_over, EventHookMode_Pre);
		HookEvent("player_team",				hook_Event_player_team, EventHookMode_Pre);
		g_bHooked = true;	
	}	
}

public EnabledChage(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (StringToInt(newValue) == 0 && g_bHooked)
	{
		UnhookEvent("teamplay_round_start", 		hook_Start, EventHookMode_Post);
		UnhookEvent("teamplay_round_win", 		hook_Win, EventHookMode_Post);
		UnhookEvent("teamplay_setup_finished", 	hook_Setup, EventHookMode_Post);
		UnhookEvent("player_death", 				hook_Death, EventHookMode_Pre);
		UnhookEvent("game_start", 				hook_Event_GameStart);
		UnhookEvent("teamplay_restart_round", 	hook_Event_TFRestartRound);
		UnhookEvent("tf_game_over",				hook_Event_tf_game_over, EventHookMode_Pre);
		UnhookEvent("player_team",				hook_Event_player_team, EventHookMode_Pre);
		g_bHooked = false;
	}
	else if (!g_bHooked)
	{
		HookEvent("teamplay_round_start", 		hook_Start, EventHookMode_Post);
		HookEvent("teamplay_round_win", 		hook_Win, EventHookMode_Post);
		HookEvent("teamplay_setup_finished", 	hook_Setup, EventHookMode_Post);
		HookEvent("player_death", 				hook_Death, EventHookMode_Pre);
		HookEvent("game_start", 				hook_Event_GameStart);
		HookEventEx("teamplay_restart_round", 	hook_Event_TFRestartRound);
		HookEvent("tf_game_over",				hook_Event_tf_game_over, EventHookMode_Pre);
		HookEvent("player_team",				hook_Event_player_team, EventHookMode_Pre);
		g_bHooked = true;
	}
}
public Action:hook_Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bScrambling)
		return Plugin_Handled;
	
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if (g_iBlockTime[client] && IsValidTeam(client))
	{
		if (GetTime() - g_iBlockTime[client] <= GetConVarInt(cvar_SpecBlock ))		
		{		
			new	Handle:data;
			WritePackCell(data, client);
			WritePackCell(data, GetEventInt(event, "oldteam"));
			CreateDataTimer(0.5, Timer_SwapBack, data, TIMER_FLAG_NO_MAPCHANGE);			
			HandleStacker(client);			
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}	

public Action:Timer_SwapBack(Handle:timer, any:data)
{
	ResetPack(data);
	new client = ReadPackCell(data),
		team = ReadPackCell(data);
	ChangeClientTeam(client, team);
	return Plugin_Handled;
}

public hook_Event_TFRestartRound(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Game got restarted - reset our round count tracking */
	g_iCompleteRrounds = 0;	
}

public hook_Event_GameStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	/* Game got restarted - reset our round count tracking */
	g_iRedFrags = 0;
	g_iBluFrags = 0;
	g_iCompleteRrounds = 0;
	g_iRoundStarts = 0;
	
	g_iWins[TEAM_RED] = 0;
	g_iWins[TEAM_BLUE] = 0;
}

public OnClientConnected(client)
{
	if(IsFakeClient(client))
		return;
	g_iBlockTime[client] = 0;
	g_iBalanceTime[client] = 0;
	g_bHasVoted[client] = false;
	g_iVoters++;
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
}

public OnClientDisconnect(client)  // reset any vote the cient may have made
{
	if(IsFakeClient(client))
		return;		
	g_iPlayersTeam[client] = 0;
	g_iBlockTime[client] = 0;
	if(g_bHasVoted[client])
	{
		g_iVotes--;
	}
	
	g_iVoters--;
	
	if (g_iVoters < 0)
		g_iVoters = 0;
	
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
}

public OnMapStart()  // resets all the map/round globals && starts the vote-delay timer
{
	if (g_bLog)
	{
		new String:sMapName[32];
		GetCurrentMap(sMapName, 32);
		LogToFile(g_sLogFile, sMapName);
	}
	g_hScrambleDelay = INVALID_HANDLE;
	g_iRedFrags = 0;
	g_iBluFrags = 0;
	g_iCompleteRrounds = 0;
	g_iRoundStarts = 0;
	g_bScramble = false;
	g_iWins[TEAM_RED] = 0;
	g_iWins[TEAM_BLUE] = 0;

	g_bWasFullRound = false;
	g_bPreGameScramble = false;
	g_bDisablePrioity = false;
	
	gamerules = FindEntityByClassname(MaxClients+1, "tf_gamerules");
	if (gamerules==-1)
	{
		gamerules = CreateEntityByName("tf_gamerules");
	} 
	g_bBonusRound = false;
	g_iVotes = 0;
	PrecacheSound(SCRAMBLE_SOUND, true);
	PrecacheSound(EVEN_SOUND, true);	
	g_bVoteAllowed = false;
	g_bVoteTimeAllowed = false;	
	if (GetConVarBool(cvar_VoteEnable))
	{
		if (!GetConVarBool(cvar_Arena) || 
		(GetConVarBool(cvar_Arena) && !GetConVarBool(cvar_ArenaQueue)))
		{
		new delay = GetConVarInt(cvar_Delay);
		g_hVoteDelayTimer = CreateTimer(float(delay), TimerEnable, TIMER_FLAG_NO_MAPCHANGE);
		}
	}	
	if (GetConVarBool(cvar_Log))
		g_bLog = true;
	else
		g_bLog = false;
}

public OnMapEnd()
{
	if (g_hVoteDelayTimer != INVALID_HANDLE)
	{
		KillTimer(g_hVoteDelayTimer);
		g_hVoteDelayTimer = INVALID_HANDLE;
	}
}

public Action:TimerEnable(Handle:timer)
{
	g_bVoteAllowed = true; // menu vote
	g_bVoteTimeAllowed = true; // text vote
	
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
	if (g_bLog)
	{
		new String:Name[32];
		GetClientName(client, Name, 32);
		LogToFile(g_sLogFile, "%s reset all votes.", Name);
	}
	ReplyToCommand(client, "[SM] %T", "ResetReply", LANG_SERVER, g_iVotes);
	for (new i = 1; i <= MaxClients; i++)
		g_bHasVoted[i] = false;
	g_iVotes = 0;
}

public Action:cmd_JoinTeam(client, args) /* records the time client uses jointeam command, so that the team switch blocker knows it's the client trying to change team*/
{
	if (g_iBlockTime[client] && IsValidTeam(client))
	{
		if (GetTime() - g_iBlockTime[client] <= GetConVarInt(cvar_SpecBlock ))		
		{
			if (g_iBlockWarnings[client] < 1 && GetTeamInfo()) // doesn't block if there is a team imbalance < 1 cuz bad things might happen if that is spammed
			{	
				new String:arg[10];
				GetCmdArgString(arg, 10);
				if (StrEqual(arg, "red", false) || StrEqual(arg, "blue", false))
					return Plugin_Continue;
			}
			HandleStacker(client);			
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
}

public Action:cmd_JoinSpec(client, args)
{
	if (IsValidTeam(client) && GetTime() - g_iBlockTime[client] <= GetConVarInt(cvar_SpecBlock ))		
	{			
		HandleStacker(client);			
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

HandleStacker(client)
{
	if (g_iBlockWarnings[client] < 2) /* to cut the spam for people trying to swap over and over. warns the client twice*/
	{
		LogAction(client, -1, "\"%L\" was blocked from changing teams", client);
		ReplyToCommand(client, "[SM] %T", "BlockSwitchMessage", LANG_SERVER);
		new String:sName[32];
		GetClientName(client, sName, sizeof(sName));
		PrintToChatAll("[SM] %T", "ShameMessage", LANG_SERVER, sName);
		if (g_bLog && g_iBlockWarnings[client] == 0)
			LogToFile(g_sLogFile, "%T", "ShameMessage", LANG_SERVER, sName);
		g_iBlockWarnings[client]++;
	}
	
	if (GetConVarBool(cvar_Punish))
	{
		g_iBlockTime[client] = GetTime();
	}
}

public Action:cmd_Balance(client, args) /*forces team balance if one exists... the command*/
{
	decl String:flags[256];
	GetConVarString(cvar_BalanceFlag, flags, 256);
	new ibFlags = ReadFlagString(flags);
	
	if (!client || (GetUserFlagBits(client) & ibFlags) == ibFlags || GetUserFlagBits(client) & ADMFLAG_ROOT)
		PerformBalance(client);
	else 
		ReplyToCommand(client, "[SM] %T", "NotAllowedReply", LANG_SERVER);
	return Plugin_Handled;
}

PerformBalance(client) /*forces team balance if one exists... return checks*/
{
	if (!GetConVarBool(cvar_Enabled))
	{
		ReplyToCommand(client, "[SM] %T", "EnableReply", LANG_SERVER);
		return;
	}
	if (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue))
	{
		ReplyToCommand(client, "[SM] %T", "ArenaReply", LANG_SERVER);
		return;
	}
	new iLargeTeam = GetTeamInfo();
	if(iLargeTeam)
	{
		GetLargeTeam(iLargeTeam, true);
		BalanceTeams(true, iLargeTeam);
		if (g_bLog)
		{
			decl String:ClientName[64];
			if (!client)
				Format(ClientName, 64, "Console");
			else
				GetClientName(client, ClientName, 64);
			LogToFile(g_sLogFile, "%s forced a team balance.", ClientName);
			LogAction(client, -1, "\"%L\" performed the force balance command", client);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] %T", "NoImbalnceReply", LANG_SERVER);
		if (g_bLog)
		{
			decl String:ClientName[64];
			if (!client)
				Format(ClientName, 64, "Console");
			else
				GetClientName(client, ClientName, 64);
			LogToFile(g_sLogFile, "%s attempted a team balance, but no imbalance was detected.", ClientName);
		}
	}
}

BalanceTeams(bool:respawn, team) /*forces team balance if one exists... actual logic*/
{
	if (team)
	{
		g_bScrambling = true; 
		new swaps = 0;
		for (new i=0; swaps < (g_iTeamDifference / 2) || g_iFatSize < i; i++)
		{
			if (g_iFatTeam[i][0] && IsValidTarget(1,g_iFatTeam[i][0]))
			{
				new String:sName[32], String:sTeam[5];
				if (team == TEAM_RED)
					sTeam = "Blu";
				else
					sTeam = "Red";
				GetClientName(g_iFatTeam[i][0], sName, 32);
				ChangeClientTeam(g_iFatTeam[i][0], team == TEAM_BLUE ? TEAM_RED : TEAM_BLUE);
				PrintToChatAll("[SM] %T", "TeamChangedAll", LANG_SERVER, sName, sTeam);
				SetupTeamSwapBlock(g_iFatTeam[i][0]);
				if (respawn)
					CreateTimer(1.0, Timer_BalanceSpawn, g_iFatTeam[i][0], TIMER_FLAG_NO_MAPCHANGE);
				swaps++;
				if (!IsFakeClient(g_iFatTeam[i][0]))
				{
					new Handle:event = CreateEvent("teamplay_teambalanced_player");
					SetEventInt(event, "player", g_iFatTeam[i][0]);
					g_iBalanceTime[g_iFatTeam[i][0]] = GetTime();
					SetEventInt(event, "team", team == TEAM_BLUE ? TEAM_RED : TEAM_BLUE);
					FireEvent(event);
				}
			}
		}
	}
	g_bScrambling = false; 
}

public Action:Timer_BalanceSpawn(Handle:timer, any:client)
{
	TF2_RespawnPlayer(client);
	return Plugin_Handled;
}

public Action:cmd_Scramble_Now(client, args)
{
	decl String:flags[256];
	GetConVarString(cvar_ScrambleNowFlag, flags, 256);
	new ibFlags = ReadFlagString(flags);
		
	if (!client || (GetUserFlagBits(client) & ibFlags) == ibFlags || (GetUserFlagBits(client) & ADMFLAG_ROOT))
	{
		if (args < 1)
		{
			ReplyToCommand(client, "[SM] %T", "NowCommandReply", LANG_SERVER);
			return Plugin_Handled;
		}
		decl String:arg[65];
		GetCmdArg(1, arg, sizeof(arg));
		new restart; 
		StringToIntEx(arg, restart);
		
		if (restart != 1 && restart != 0)
		{
			ReplyToCommand(client, "[SM] %T", "NowCommandReply", LANG_SERVER);
			return Plugin_Handled;
		}
		
		if (restart)
		{
			PerformScrambleNow(client, true);
		}
		else
		{
			PerformScrambleNow(client, false);
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] %T", "NotAllowedReply", LANG_SERVER);
	}
	
	return Plugin_Handled;
}

PerformScrambleNow(client, bool:restart)
{
	if (!GetConVarBool(cvar_Enabled))
	{
		ReplyToCommand(client, "[SM] %T", "EnableReply", LANG_SERVER);
		return;
	}
	
	decl String:ClientName[64];
	
	if (!client)
		Format(ClientName, sizeof(ClientName), "Console");		
	else
		GetClientName(client, ClientName, sizeof(ClientName));
		
		
	if (g_bScramble)
	{
		g_bScramble = false;
		if (g_hScrambleDelay != INVALID_HANDLE)
		{
			KillTimer(g_hScrambleDelay);
			g_hScrambleDelay = INVALID_HANDLE;
		}
	}
	LogAction(client, -1, "\"%L\" performed the scramble now command", client);
	if (g_bLog)
		LogToFile(g_sLogFile, "%s has performed the Scramble Now command", ClientName);
	
	if (restart)
	{
		StartScrambleDelay(5.0, false, true);
	}
	else
	{
		StartScrambleDelay(5.0, true, false);
	}	
}

public Action:command_Say(client, args)
{
//why make new code when RTV already has it :D
	
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
		
	if (strcmp(text[startidx], "!scramble", false) == 0 || strcmp(text[startidx], "votescramble", false) == 0 || strcmp(text[startidx], "!votescramble", false) == 0)
	// only pansies use multi-line if's D:<
	{
		AttemptScramble(client);
	}
	
	SetCmdReplySource(old);
		
	return Plugin_Continue;		
}

AttemptScramble(client)
{
	if (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue))
	{
		ReplyToCommand(client, "[SM] %T", "ArenaReply", LANG_SERVER);
		return;
	}
		
	if (!GetConVarBool(cvar_VoteEnable))
	{
		ReplyToCommand(client, "[SM] %T", "VoteDisabledReply", LANG_SERVER);
		return;
	}
	
	if (!g_bVoteAllowed)
	{
		ReplyToCommand(client, "[SM] %T", "VoteDelayedReply", LANG_SERVER);
		return;
	}
	
	if (GetConVarBool(cvar_VoteMode) && IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %T", "Vote in Progress", LANG_SERVER);
		return;
	}
	
	if (GetConVarInt(cvar_MinPlayers) > g_iVoters)
	{
		ReplyToCommand(client, "[SM] %T", "NotEnoughPeopleVote", LANG_SERVER);
		return;
	}
	
	if (g_bHasVoted[client])
	{
		ReplyToCommand(client, "[SM] %T", "AlreadyVoted", LANG_SERVER);
		return;
	}
	
	if (g_bScramble)
	{
		ReplyToCommand(client, "[SM] %T", "ScrambleReply", LANG_SERVER);		
		return;
	}
	new String:name[64]; // OMG we made it through the returns, lets reward the client with a scramble vote
	GetClientName(client, name, sizeof(name));
	if (g_bLog)
		LogToFile(g_sLogFile, "registered vote with %i players. %i minimum players", g_iVoters, GetConVarInt(cvar_MinPlayers));
	g_iVotes++;
	g_bHasVoted[client] = true;
	
	PrintToChatAll("[SM] %T", "VoteTallied", LANG_SERVER, name, g_iVotes, g_iVotesNeeded);
	
	if (g_iVotes >= g_iVotesNeeded && !g_bScramble)
	{
		if (GetConVarBool(cvar_VoteMode))
		{
			g_hScrambleVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
			new String:sTmpTitle[64];
			if (GetConVarBool(cvar_VoteEnd))
			{
				Format(sTmpTitle, 64, "%T", "MenuScrambleNow", LANG_SERVER);
				SetMenuTitle(g_hScrambleVoteMenu, sTmpTitle);
			}
			else
			{
				Format(sTmpTitle, 64, "%T", "MenuScrambleRoundTitle", LANG_SERVER);
				SetMenuTitle(g_hScrambleVoteMenu, sTmpTitle);
			}
			AddMenuItem(g_hScrambleVoteMenu, VOTE_YES, "Yes");
			AddMenuItem(g_hScrambleVoteMenu, VOTE_NO, "No");
			SetMenuExitButton(g_hScrambleVoteMenu, false);
			VoteMenuToAll(g_hScrambleVoteMenu, 20);
			if (g_bLog)
				LogToFile(g_sLogFile, "Scramble vote initialized due to voting.");
		}
		else 
		{			
			g_bScramble = true;
			PrintToChatAll("[SM] %T", "ScrambleRound", LANG_SERVER);
			if (g_bLog)
				LogToFile(g_sLogFile, "Scramble initialized due to voting.");			
		}
	}
}	

public Action:cmd_Vote(client, args)
{
	decl String:flags[256];
	GetConVarString(cvar_VoteFlag, flags, 256);
	new ibFlags = ReadFlagString(flags);
	
	if (!client || (GetUserFlagBits(client) & ibFlags) == ibFlags || (GetUserFlagBits(client) & ADMFLAG_ROOT))
	{
	
		if (args < 1)
		{
			ReplyToCommand(client, "[SM] Usage: sm_scramblevote <now/end>");
			return Plugin_Handled;
		}
		
		decl String:arg[16];
		GetCmdArg(1, arg, sizeof(arg));
		g_bScrambleNow = false;
		
		if(StrEqual(arg, "now", true))
			g_bScrambleNow = true;
		else if(StrEqual(arg, "end", true))
			g_bScrambleNow = false;
		else
		{
			ReplyToCommand(client, "[SM] %T", "InvalidArgs", LANG_SERVER);
			return Plugin_Handled;
		}	
		PerformVote(client);	
	}
	else
		ReplyToCommand(client, "[SM] %T", "NotAllowedReply", LANG_SERVER);
	return Plugin_Handled;
}

PerformVote(client)
{
	if (!GetConVarBool(cvar_Enabled))
	{
		ReplyToCommand(client, "[SM] %T", "EnableReply", LANG_SERVER);
		return;
	}
	
	if (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue))
	{
		ReplyToCommand(client, "[SM] %T", "ArenaReply", LANG_SERVER);
		return;
	}
	
	if (GetConVarInt(cvar_MinPlayers) > g_iVoters)
	{
		ReplyToCommand(client, "[SM] %T", "NotEnoughPeopleVote", LANG_SERVER);
		return;
	}
	
	if (g_bScramble)
	{
		ReplyToCommand(client, "[SM] %T", "ScrambleReply", LANG_SERVER);
		return;
	}
	
	if (IsVoteInProgress())
	{
		ReplyToCommand(client, "[SM] %T", "Vote in Progress", LANG_SERVER);
		return;
	}
	
	if (!g_bVoteTimeAllowed)
	{
		ReplyToCommand(client, "[SM] %T", "VoteDelayedReply", LANG_SERVER);
		return;
	}
	
	decl String:ClientName[64];
	
	if (!client)
		Format(ClientName, sizeof(ClientName), "Console");		
	else
		GetClientName(client, ClientName, sizeof(ClientName));
	
	LogAction(client, -1, "\"%L\" has started a scramble vote", client);
	if(g_bScrambleNow)
	{
		if (g_bLog)
			LogToFile(g_sLogFile, "%s started a scramble now vote.", ClientName);
	}
	else
	{
		if (g_bLog)
			LogToFile(g_sLogFile, "%s started a round-end scramble vote.", ClientName);
		g_bScrambleNow = false;
	}
	
	g_hScrambleVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	
	new String:sTmpTitle[64];
	if (g_bScrambleNow)
	{
		Format(sTmpTitle, 64, "%T", "MenuScrambleNow", LANG_SERVER);
		SetMenuTitle(g_hScrambleVoteMenu, sTmpTitle);
	}
	else
	{
		Format(sTmpTitle, 64, "%T", "MenuScrambleRoundTitle", LANG_SERVER);
		SetMenuTitle(g_hScrambleVoteMenu, sTmpTitle);
	}
	AddMenuItem(g_hScrambleVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hScrambleVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hScrambleVoteMenu, false);
	VoteMenuToAll(g_hScrambleVoteMenu, 20);
}

StartSteamrollVote()
{
	if (IsVoteInProgress())
	{
		PrintToChatAll("[SM] %T", "VoteWillStart", LANG_SERVER);
		CreateTimer(1.0, Timer_SteamrollVoteStarter, _, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
		return;
	}
	g_hScrambleVoteMenu = CreateMenu(Handler_VoteCallback, MenuAction:MENU_ACTIONS_ALL);
	g_bScrambleNow = true;
	new String:sTmpTitle[64];
	Format(sTmpTitle, 64, "%T", "MenuScrambleNow", LANG_SERVER);
	SetMenuTitle(g_hScrambleVoteMenu, sTmpTitle);
	AddMenuItem(g_hScrambleVoteMenu, VOTE_YES, "Yes");
	AddMenuItem(g_hScrambleVoteMenu, VOTE_NO, "No");
	SetMenuExitButton(g_hScrambleVoteMenu, false);
	VoteMenuToAll(g_hScrambleVoteMenu, 20);
}

public Action:Timer_SteamrollVoteStarter(Handle:timer)
{
	if (IsVoteInProgress())
		return Plugin_Continue;
	else
	{
		StartSteamrollVote();
		return Plugin_Stop;
	}
}

public Handler_VoteCallback(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End)
	{
		VoteMenuClose();
	}
	
	else if (action == MenuAction_Display)
	{
		decl String:title[64];
		GetMenuTitle(menu, title, sizeof(title));
		
		decl String:buffer[255];
		Format(buffer, sizeof(buffer), "%s %s", title, g_sVoteInfo[VOTE_NAME]);

		new Handle:panel = Handle:param2;
		SetPanelTitle(panel, buffer);
	}
	
	else if (action == MenuAction_DisplayItem)
	{
		decl String:display[64];
		GetMenuItem(menu, param2, "", 0, _, display, sizeof(display));
	 
	 	if (strcmp(display, "VOTE_NO") == 0 || strcmp(display, "VOTE_YES") == 0)
	 	{
			decl String:buffer[255];
			Format(buffer, sizeof(buffer), "%s", display);
			return RedrawMenuItem(buffer);
		}
	}

	else if (action == MenuAction_VoteCancel && param1 == VoteCancel_NoVotes)
	{
		PrintToChatAll("[SM] %T", "No Votes Cast", LANG_SERVER);
	}	
	else if (action == MenuAction_VoteEnd)
	{
		g_bVoteTimeAllowed = false;
		g_bVoteAllowed = false;

		new Float:time = GetConVarFloat(cvar_Delay);
		new m_votes, totalVotes;
		
		GetMenuVoteInfo(param2, m_votes, totalVotes);
		
		new Float:comp = FloatDiv(float(m_votes),float(totalVotes));

		new Float:comp2 = GetConVarFloat(cvar_Needed);
		
		if (param1 == 1) // Votes of no wins
		{
			new Float:hundred = 100.00;
			new Float:percentage = FloatMul(comp,hundred);
			new percentage2 = RoundFloat(percentage);
			PrintToChatAll("[SM] %T", "VoteFailed", LANG_SERVER);
			PrintToChatAll("[SM] %T", "VotePercent", LANG_SERVER, percentage2, totalVotes);
			if (g_bLog)
				LogToFile(g_sLogFile, "Failed: %T", "VotePercent", LANG_SERVER, percentage2, totalVotes);
			CreateTimer(time, Timer_VoteTimer);
		}
		
		else if (comp >= comp2 && param1 == 0)
		{
			new Float:hundred = 100.00;
			new Float:percentage = FloatMul(comp,hundred);
			new percentage2 = RoundFloat(percentage);
			PrintToChatAll("[SM] %T", "VotePercent", LANG_SERVER, percentage2, totalVotes);
			if (g_bLog)
				LogToFile(g_sLogFile, "%T", "VotePercent", LANG_SERVER, percentage2, totalVotes);
			
			if (g_bScrambleNow || GetConVarBool(cvar_VoteEnd))
				StartScrambleDelay(5.0, true, false);
			else
			{
				if ((GetConVarBool(cvar_FullRoundOnly) && g_bWasFullRound) || !GetConVarBool(cvar_FullRoundOnly))
				{
					g_bScramble = true;
					PrintToChatAll("[SM] %T", "ScrambleStartVote", LANG_SERVER);
				}			
			}
		}
		else
		{
			new Float:hundred = 100.00;
			new Float:percentage = FloatMul(comp2,hundred);
			new percentage2 = RoundFloat(percentage);
			PrintToChatAll("[SM] %T", "NotEnoughVotes", LANG_SERVER, percentage2);
			if (g_bLog)
				LogToFile(g_sLogFile, "%T", "NotEnoughVotes", LANG_SERVER, percentage2);
			CreateTimer(time, Timer_VoteTimer);
		}
	}
	if (GetConVarBool(cvar_VoteEnable)) // reset votes since we don't want a new vote-trigger to happen again too quickly
	{
		for (new i = 0; i <= MaxClients; i++)
			g_bHasVoted[i] = false;
		// delay voting again
		g_bVoteAllowed = false;
		g_bVoteTimeAllowed = false;
		if (g_hVoteDelayTimer != INVALID_HANDLE)
			KillTimer(g_hVoteDelayTimer);
		g_hVoteDelayTimer = CreateTimer(GetConVarFloat(cvar_Delay), TimerEnable, TIMER_FLAG_NO_MAPCHANGE);
		g_iVotes = 0;
	}	
	return 0;
}

public Action:Timer_VoteTimer(Handle:timer)
{
	g_bVoteTimeAllowed = true;
	g_bVoteAllowed = true;
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
	if (g_bScramble || g_hScrambleDelay != INVALID_HANDLE)
	{
		g_bScramble = false;
		if (g_hScrambleDelay != INVALID_HANDLE)
		{
			KillTimer(g_hScrambleDelay);
			g_hScrambleDelay = INVALID_HANDLE;
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] %T", "NoScrambleReply", LANG_SERVER);
		return;
	}	
	PrintToChatAll("[SM] %T", "CancelScramble", LANG_SERVER);
	LogAction(client, -1, "\"%L\" canceled the pending scramble", client);
	if (g_bLog)
	{
		new String:clientName[32];
		GetClientName(client, clientName, sizeof(clientName));
		LogToFile(g_sLogFile, "%s canceled the pending scramble.", clientName);
	}
}

SetupRoundScramble(client)
{
	if (!GetConVarBool(cvar_Enabled))
	{
		ReplyToCommand(client, "[SM] %T", "EnableReply", LANG_SERVER);
		return;
	}
	
	if (g_bScramble)
	{
		ReplyToCommand(client, "[SM] %T", "ScrambleReply", LANG_SERVER);
		return;
	}
	
	decl String:ClientName[64];
	
	if (!client)
		Format(ClientName, 64, "Console");
	else
		GetClientName(client, ClientName, sizeof(ClientName));
	
	g_bScramble = true;
	PrintToChatAll("[SM] %T", "ScrambleRound", LANG_SERVER);
	LogAction(client, -1, "\"%L\" toggled a scramble for next round", client);
	if (g_bLog)
		LogToFile(g_sLogFile, "%s toggled a round-end scramble.", ClientName);

}

stock bool:DidTeamsSwitch()
{
	if (g_iRedScore != g_iBluScore) 
	{
		if (g_iBluScore != GetTeamScore(TEAM_BLUE) && g_iRedScore != GetTeamScore(TEAM_RED))
		{	
			if (g_bLog)
				LogToFile(g_sLogFile, "Score swap detected, returning true");
			return true;
		}
		else
			return false;
	} 
	else 
	{	
		new maxclients = GetMaxClients();
		new cteam, count;
		count = GetClientCount();
		for (new i = 1; i <= maxclients; i++) 
		{
			if (IsClientInGame(i) && g_iPlayersTeam[i]) 
			{
				if (IsValidTeam(i) && g_iPlayersTeam[i] != GetClientTeam(i) )
					cteam++;
			}
		}
		if ((float(cteam) / float(count)) > 0.70)
		{
			if (g_bLog)
				LogToFile(g_sLogFile, "Player swap ratio detected, returning true");
			return true;
		}
	}
	return false;
}

public Action:hook_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_bScramble)
		StartScrambleDelay(0.4, true, false);
	else
		g_bDisablePrioity = false;
	if (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue))   /* if arena, skip */
		return Plugin_Continue;
	if (!g_bScramble && GetConVarBool(cvar_ForceBalance))
	{
		new iTeam = GetTeamInfo();
		if (iTeam)
		{
			GetLargeTeam(iTeam, false);
			BalanceTeams(false, iTeam);
		}
	}		
	if (!GetConVarBool(cvar_AutoScramble) && !GetConVarBool(cvar_WinStreak))  
		return Plugin_Continue;
	
	if (g_bWasFullRound && g_iVoters >= GetConVarInt(cvar_MinAutoPlayers))  /* win-streak: swap the scores for the consecutive win counter if the teams were swapped*/
	{
		if (DidTeamsSwitch())
		{	
			new oldRed = g_iWins[TEAM_RED], oldBlu = g_iWins[TEAM_BLUE];
			g_iWins[TEAM_RED] = oldBlu;
			g_iWins[TEAM_BLUE] = oldRed;
			if (g_bLog)
				LogToFile(g_sLogFile, "Swapping scores due to team swap");
		}
	}
	g_bPreGameScramble = false;
	if (GetConVarBool(cvar_WaitScramble) && g_iRoundStarts == 0) /* sets up pre-game scramble*/
	{
		if (g_bLog)
			LogToFile(g_sLogFile, "Starting pre-game scramble");
		new Handle:cvar_WaitingTime = FindConVar("mp_waitingforplayers_time");
		
		new Float:delay = GetConVarFloat(cvar_WaitingTime) -0.5;
		if (delay < 0.0)
			delay = 0.0;
		StartScrambleDelay(delay, false, false);
		g_bPreGameScramble = true;
	}
	
	g_iRedFrags = 0;
	g_iBluFrags = 0;
	
	g_bBonusRound = false;
	g_iRoundStartTime = GetTime();
	g_iRoundStarts++;
	
	g_bWasFullRound = false;
	return Plugin_Continue;
}

public Action:hook_Setup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvar_AutoScramble) || (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue)))
		return Plugin_Continue;
		
	// get the start time of the round for the scteamroll detector
	g_iRoundStartTime = GetTime();
	return Plugin_Continue;
}

public Action:hook_Win(Handle:event, const String:name[], bool:dontBroadcast){	
		
	if (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue)) /* disabled if arena */
		return Plugin_Continue;
		
	if (!g_bScramble 
		&& !GetConVarBool(cvar_AutoScramble) 
		&& !GetConVarBool(cvar_WinStreak)
		&& GetConVarBool(cvar_ForceBalance)) /* disabled if autoscramble disabled, focebalance, and winstreak scrambling disabled */
		return Plugin_Continue;
	g_bDisablePrioity = true;
	g_bWasFullRound = false;
	
	if (GetEventBool(event, "full_round"))
	{
		g_bWasFullRound = true;
		g_iCompleteRrounds++;
		if (GetConVarBool(cvar_WinStreak))
		{
			new delay = GetConVarInt(cvar_bonusRound);
			CreateTimer((float(delay) - 0.5), timer_TeamSwap, TIMER_FLAG_NO_MAPCHANGE);
		}
	}
	g_bBonusRound = true;
		
	new winningTeam = GetEventInt(event, "team");	
	if (IsMapEnding() && g_bWasFullRound)
	{
		if (g_bScramble)
		{
			PrintToChatAll("[SM] %T", "MapEnding", LANG_SERVER);
			if (g_bLog)
				LogToFile(g_sLogFile, "Canceling active scramble due to map ending.");
			g_bScramble = false;
		}
		return Plugin_Continue;
	}
	
	if (!g_bScramble && GetConVarBool(cvar_WinStreak) && g_bWasFullRound && g_iVoters >= GetConVarInt(cvar_MinAutoPlayers))  /* win streak counter */
	{
		if (winningTeam == TEAM_RED && g_iWins[TEAM_BLUE] >= 1)
			g_iWins[TEAM_BLUE] = 0;
			
		if (winningTeam == TEAM_BLUE && g_iWins[TEAM_RED] >= 1)
			g_iWins[TEAM_RED] = 0;
			
		if (winningTeam == TEAM_RED)
			g_iWins[TEAM_RED]++;
			
		if (winningTeam == TEAM_BLUE)
			g_iWins[TEAM_BLUE]++;
			
		if (g_iWins[TEAM_RED] >= GetConVarInt(cvar_WinStreak) || g_iWins[TEAM_BLUE] >= GetConVarInt(cvar_WinStreak))
		{
			if (winningTeam == TEAM_RED)
			{
				if (g_bLog)
					LogToFile(g_sLogFile, "Red reached the win-streak scramble trigger.");
				PrintToChatAll("[SM] %T", "RedStreak", LANG_SERVER);
			}
			else
			{
				if (g_bLog)
					LogToFile(g_sLogFile, "Blu reached the win-streak scramble trigger.");
				PrintToChatAll("[SM] %T", "BluStreak", LANG_SERVER);
			}
			g_bScramble = true;
		}
	}	
	// check to see if auto-scramble should initiate	
	if (!g_bScramble && GetConVarBool(cvar_AutoScramble))
		AutoScrambleCheck(winningTeam);
	
	if (g_bScramble)
		PrintToChatAll("[SM] %T", "ScrambleRound", LANG_SERVER);

	return Plugin_Continue;
}

public Action:timer_TeamSwap(Handle:timer)
{
	g_iRedScore = GetTeamScore(TEAM_RED);
	g_iBluScore = GetTeamScore(TEAM_BLUE);
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && IsValidTeam(i))
		{
			g_iPlayersTeam[i] = GetClientTeam(i);
		}
	}
}


public Action:hook_Event_tf_game_over(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (g_hScrambleDelay != INVALID_HANDLE)
	{
		KillTimer(g_hScrambleDelay);
		g_hScrambleDelay = INVALID_HANDLE;
		LogToFile(g_sLogFile, "Canceled scramble due to map ending.");
	}
	return Plugin_Continue;
}

public Action:hook_Death(Handle:event, const String:name[], bool:dontBroadcast) /* ---------------------------------- player_death hook ------*/
{
	if ((!GetConVarBool(cvar_AutoScramble) && !GetConVarBool(cvar_Balancer))
		|| (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue)))
	{
		return Plugin_Continue;
	}
	if (!g_bScrambling && g_bBonusRound)
		return Plugin_Continue;
		
	if (g_bScrambling) /*hides all death events while the plugin is scrambling or balancing teams*/
	{
		return Plugin_Handled;
	}
	new killer = GetEventInt(event, "attacker"),
		k_client = GetClientOfUserId(killer),
		victim = GetEventInt(event, "userid"),
		v_client = GetClientOfUserId(victim);
	if (GetConVarBool(cvar_Balancer))
		CreateTimer(0.5, timer_StartBalanceCheck, v_client, TIMER_FLAG_NO_MAPCHANGE);
	
	if (!k_client ||
		k_client == v_client ||
		k_client > MaxClients)
		return Plugin_Continue;	// environemt check
	new team = GetClientTeam(k_client);
	if (team == TEAM_RED)
		g_iRedFrags++;
	else
		g_iBluFrags++;
	return Plugin_Continue;
}

public Action:timer_StartBalanceCheck(Handle:timer, any:client)
{
	new team = GetTeamInfo();
	if (!team)
		return Plugin_Handled;  // teaminfo returned 0
	if (GetClientTeam(client) != team)
		return Plugin_Handled;	// client isn't on the larger team
	new iBalanceSeconds = GetConVarInt(cvar_BalanceTime) * 60;
	if (g_iBalanceTime[client] && GetTime() - g_iBalanceTime[client] < iBalanceSeconds)
	{
		if (g_bLog)
			LogToFile(g_sLogFile, "Player ignored due to recent swap");
		return Plugin_Handled;  // client was too recently balanced
	}
	if (!IsValidTarget(1, client))
	{
		if (g_bLog)
			LogToFile(g_sLogFile, "Player ignored due priority setting");
		return Plugin_Handled;
	}	
	new iProtection = GetConVarInt(cvar_TopProtect);
	if (iProtection && GetTeamClientCount(team) > iProtection && !IsGoodChoice(client, team))
	{
		if (g_bLog)
			LogToFile(g_sLogFile, "Player ignored due to being in top X");
		return Plugin_Handled;
	}	
	new String:sName[32],
		String:sTeam[32];
	GetClientName(client, sName, 32);
	team = team == TEAM_RED ? TEAM_BLUE : TEAM_RED;  // changes team to the team we will be changing the client to
	if (team == TEAM_RED)
		sTeam = "RED";
	else
		sTeam = "BLU";
	if (g_bLog)
		LogToFile(g_sLogFile, "%T", "TeamChangedAll", LANG_SERVER, sName, sTeam);
	ChangeClientTeam(client, team);
	new Handle:event = CreateEvent("teamplay_teambalanced_player");
	SetEventInt(event, "player", client);
	SetEventInt(event, "team", team);
	SetupTeamSwapBlock(client);
	FireEvent(event);
	PrintToChatAll("[SM] %T", "TeamChangedAll", LANG_SERVER, sName, sTeam);
	return Plugin_Handled;
}

stock bool:IsGoodChoice(client, team)
{
	new iSize, iScores[MAXPLAYERS+1][2], iHighestScore;
	
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
	if (iHighestScore <= 5)
		return true;
	if (iSize < GetConVarInt(cvar_TopProtect) + 2)
		return true;
	SortCustom2D(iScores, iSize, SortScoreDesc);
	for (new i = 0; i < GetConVarInt(cvar_TopProtect); i++)
	{
		if (iScores[i][0] == client)
			return false;
	}
	return true;
}

bool:IsValidTarget(mode, client)/* controls who is immune from being scrambled */
{
	/* mode 0 = scramble immunity
	   mode 1 = balance immunity
	 */
	new iImmunity;
	if (mode == 0)
		iImmunity = GetConVarInt(cvar_ScrambleAdminImmune);
	else 
		iImmunity = GetConVarInt(cvar_BalanceImmunity);
	if (IsClientInGame(client) && IsValidTeam(client) && !IsFakeClient(client))
	{
		if (!iImmunity)
			return true;
		if (iImmunity == 3 && g_bBonusRound)
			iImmunity = 1;
		if (iImmunity == 1 || iImmunity == 3)
		{
			if (iImmunity == 3)
			{
				if (GetPlayerPriority(client) <= -1)
				return false;
			}
			if (GetUserFlagBits(client) & (ADMFLAG_ROOT|ADMFLAG_RESERVATION|ADMFLAG_GENERIC))
				return false;
		}
		if (iImmunity == 2)
		{
			if (GetPlayerPriority(client) <= -1)
				return false;
		}
		return true;
	}
	return false;
}

scramble(bool:now, bool:restart)  // scramble logic
{
	new count = 0, i, bool:team, oldTeam = 0, iTeamChanges = 0;
	g_iWins[TEAM_RED] = 0;
	g_iWins[TEAM_BLUE] = 0;
	g_bScrambling = true;
	
	if (GetRandomInt(0,1))  // randomize what team gets the first player
		team = true;	
	if (GetConVarInt(cvar_SortMode) == 3 && !g_bPreGameScramble)  // sort the players based on their score-per-minute
	{
		if (g_bLog)
			LogToFile(g_sLogFile, "Using the score-per minute sort method");
		new Float:fScores[MaxClients+1][2];
		for (i=1; i<=MaxClients;i++)
		{
			if (IsValidTarget(0,i))
			{
				fScores[count][0] = float(i); 
				fScores[count][1] = 1 + float(TF2_GetPlayerResourceData(i, TFResource_TotalScore)) / (GetClientTime(i) / 60.0);
				count++;				
			}
		}
		SortCustom2D(_:fScores, count, SortScoreDesc_f);
		
		for(i = 0; i < count; i++) 
		{
			oldTeam = GetClientTeam(RoundFloat(fScores[i][0]));
			ChangeClientTeam(RoundFloat(fScores[i][0]), team ? TEAM_RED : TEAM_BLUE);
			team = !team;
			SetupTeamSwapBlock(RoundFloat(fScores[i][0]));
			if (GetClientTeam(RoundFloat(fScores[i][0])) != oldTeam)
			{
				PrintCenterText(RoundFloat(fScores[i][0]), "%T", "TeamChangedOne", LANG_SERVER); 
				iTeamChanges++;
			}
		}			
	}
	else if (GetConVarInt(cvar_SortMode) == 2 && !g_bPreGameScramble)  // sort the players based just on their score
	{
		if (g_bLog)
			LogToFile(g_sLogFile, "Using the score sort method");
		new iScores[MaxClients+1][2];		
		for (i=1; i<=MaxClients;i++)
		{
			if (IsValidTarget(0,i))
			{
				iScores[count][0] = i;
				iScores[count][1] = 1 + TF2_GetPlayerResourceData(i, TFResource_TotalScore);
				count++;
			}
		}		
		SortCustom2D(iScores, count, SortScoreDesc);
		for(i = 0; i < count; i++) 
		{
			oldTeam = GetClientTeam(iScores[i][0]);
			ChangeClientTeam(iScores[i][0], team ? TEAM_RED : TEAM_BLUE);
			team = !team;
			SetupTeamSwapBlock(iScores[i][0]);
			if (GetClientTeam(iScores[i][0]) != oldTeam)
			{
				PrintCenterText(iScores[i][0], "%T", "TeamChangedOne", LANG_SERVER);
				iTeamChanges++;
			}
		}		
	}
	else // use random mode
	{
		if (g_bLog)
			LogToFile(g_sLogFile, "Using the random sort method");
		if (g_bLog && g_bPreGameScramble)
			LogToFile(g_sLogFile, "Using the score sort method for pre-game scramble");
		new players[MaxClients+1];
		
		for(i = 1; i <= MaxClients; i++) 
		{
			if(IsValidTarget(0,i)) 
			{
				players[count++] = i;
			}
		}
		SortIntegers(players, count, Sort_Random); //randomize the array
			
		for(i = 0; i < count; i++)  // switch every other person
		{
			oldTeam = GetClientTeam(players[i]);
			ChangeClientTeam(players[i], team ? TEAM_RED : TEAM_BLUE);
			team = !team;
			SetupTeamSwapBlock(players[i]);
			if (GetClientTeam(players[i]) != oldTeam)
			{
				PrintCenterText(players[i], "%T", "TeamChangedOne", LANG_SERVER);
				iTeamChanges++;
			}
		}
	}
	if (g_bLog)
		LogToFile(g_sLogFile, "Scramble has changed %d clients' team.", iTeamChanges);
	EmitSoundToAll(SCRAMBLE_SOUND, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL); // TEAMS ARE BEING SCRAMBLED!
	if (GetConVarBool(cvar_VoteEnable)) // reset votes since we don't want a new vote-trigger to happen again too quickly
	{
		for (i = 0; i <= MaxClients; i++)
			g_bHasVoted[i] = false;
		// delay voting again
		g_bVoteAllowed = false;
		g_bVoteTimeAllowed = false;
		if (g_hVoteDelayTimer != INVALID_HANDLE)
			KillTimer(g_hVoteDelayTimer);
		g_hVoteDelayTimer = CreateTimer(GetConVarFloat(cvar_Delay), TimerEnable, TIMER_FLAG_NO_MAPCHANGE);
		g_iVotes = 0;
	}	
	if (g_bPreGameScramble)
	{
		PrintToChatAll("[SM] %T", "PregameScrambled", LANG_SERVER);
		g_bPreGameScramble = false;
	}
	else
		PrintToChatAll("[SM] %T", "Scrambled", LANG_SERVER);	
	g_bScramble = false;
	
	if (now) 				//scramble now command was used, so respawn dead players
	{
		CreateTimer(1.0, timerSpawn, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	if (restart)
	{
		new RedScore, BluScore, Handle:scores, TimeLeft;
		RedScore = GetTeamScore(TEAM_RED);
		BluScore = GetTeamScore(TEAM_BLUE);
		GetMapTimeLeft(TimeLeft);		
		CreateDataTimer(5.0, Timer_Scores, scores, TIMER_FLAG_NO_MAPCHANGE);
		WritePackCell(scores, RedScore);
		WritePackCell(scores, BluScore);
		WritePackCell(scores, TimeLeft);		
		ServerCommand("mp_restartround 1");
		if (g_bLog)
			LogToFile(g_sLogFile, "Round Restarted");
	}
	g_bDisablePrioity = false;
	g_bScrambling = false;
}

public Action:Timer_Scores(Handle:timer, any:pack)
{
	ResetPack(pack);
	new RedScore 		= ReadPackCell(pack),
		BluScore 		= ReadPackCell(pack),
		TimeLeft		= ReadPackCell(pack),
		Handle:cvar_TimeLimit = FindConVar("mp_timelimit");
	
	new duration = TimeLeft - (GetConVarInt(cvar_TimeLimit) * 60);
	if (duration > 0)
		duration *= -1;
	SetGameRulesScore(TEAM_RED, RedScore);
	SetGameRulesScore(TEAM_BLUE, BluScore);
	ExtendMapTimeLimit(duration);
	return Plugin_Handled;
}

AutoScrambleCheck(winningTeam)
{
	if (GetConVarBool(cvar_FullRoundOnly) && !g_bWasFullRound)
		return;
	
	new timeEnd = GetTime();
	new roundTime = timeEnd - g_iRoundStartTime;
	
	new totalFrags = g_iRedFrags + g_iBluFrags;
	new Float:ratio = 0.0;
	
	if (totalFrags >= 50)
	{						
		if (g_iRedFrags > g_iBluFrags)
			ratio = float(g_iRedFrags) / float(g_iBluFrags);
		else
			ratio = float(g_iBluFrags) / float(g_iRedFrags);				
	}	
	
	if (roundTime <= GetConVarInt(cvar_Steamroll) && ratio >= GetConVarFloat(cvar_SteamrollRatio))
	{
		new minutes = GetConVarInt(cvar_Steamroll) / 60;
		new seconds = GetConVarInt(cvar_Steamroll) % 60;
		
		if (winningTeam == TEAM_RED && g_iRedFrags > g_iBluFrags)		// more requiremens on the time-based scramble. Team has to in in less time than allowed
		{																// and that team has to have more frags than the other team
			if (GetConVarBool(cvar_AutoscrambleVote))
			{				
				StartSteamrollVote();
				PrintToChatAll("[SM] %T", "RedWinTimeVote", LANG_SERVER, minutes, seconds);
				if (g_bLog)
					LogToFile(g_sLogFile, "Red team won in less than %dm:%ds, enabling vote.", minutes, seconds);
			}
			else
			{
				PrintToChatAll("[SM] %T", "RedWinTimeScramble", LANG_SERVER, minutes, seconds);
				if (g_bLog)
					LogToFile(g_sLogFile, "Red team won in less than %dm:%ds, enabling scramble.", minutes, seconds);
				g_bScramble = true;
			}
		}
		
		if (winningTeam == TEAM_BLUE && g_iBluFrags > g_iRedFrags)  			
		{
			if (GetConVarBool(cvar_AutoscrambleVote))
			{				
				StartSteamrollVote();
				PrintToChatAll("[SM] %T", "BluWinTimeVote", LANG_SERVER, minutes, seconds);
				if (g_bLog)
					LogToFile(g_sLogFile, "Blu team won in less than %dm:%ds, enabling vote.", minutes, seconds);
			}
			else 
			{
				g_bScramble = true;
				PrintToChatAll("[SM] %T", "BluWinTimeScramble", LANG_SERVER, minutes, seconds);
				if (g_bLog)
					LogToFile(g_sLogFile, "Blu team won in less than %dm:%ds, enabling scramble.", minutes, seconds);
			}
		}
	}
	else if (ratio >= GetConVarFloat(cvar_FragRatio))
	{
		if (winningTeam == TEAM_RED && g_iRedFrags > g_iBluFrags)
		{
			if (GetConVarBool(cvar_AutoscrambleVote))
			{				
				StartSteamrollVote();
				PrintToChatAll("[SM] %T", "RedFragVote", LANG_SERVER, ratio);
				if (g_bLog)
					LogToFile(g_sLogFile, "Red got %f times as many kills as Blu. Enabling vote.", ratio);
			}
			else
			{
				g_bScramble = true;
				PrintToChatAll("[SM] %T", "RedFragScramble", LANG_SERVER, ratio);
				if (g_bLog)
					LogToFile(g_sLogFile, "Red got %f times as many kills as Blu. Enabling scramble.", ratio);
			}
		}			
		if (winningTeam == TEAM_BLUE && g_iBluFrags > g_iRedFrags)
		{
			if (GetConVarBool(cvar_AutoscrambleVote))
			{				
				StartSteamrollVote();
				PrintToChatAll("[SM] %T", "BluFragVote", LANG_SERVER, ratio);
				if (g_bLog)
					LogToFile(g_sLogFile, "Blu got %f times as many kills as Red. Enabling vote.", ratio);
			}
			else
			{
				g_bScramble = true;
				PrintToChatAll("[SM] %T", "BluFragScramble", LANG_SERVER, ratio);
				if (g_bLog)
					LogToFile(g_sLogFile, "Blu got %f times as many kills as Red. Enabling scramble.", ratio);
			}
		}
	}
}

SetGameRulesScore(team, score) /* THANKS MIKEJS FOR THIS!!*/
{
    SetVariantInt(score-GetTeamScore(team));
    AcceptEntityInput(gamerules, team==2?"AddRedTeamScore":"AddBlueTeamScore");
}  

public Action:timerSpawn(Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) 
			&& !IsFakeClient(i) 
			&& IsValidTeam(i) 
			&& !IsPlayerAlive(i)) 	// if the scramble now command was used, and players are dead, and on valid teams, respawn them.
		{
			TF2_RespawnPlayer(i);
		}
	}
	return Plugin_Handled;
}

SetupTeamSwapBlock(client)  /* blocks proper clients from spectating*/
{
	if (GetConVarBool(cvar_AdminImmune))
	{
		if (IsClientInGame(client))
		{
			if (!(GetUserFlagBits(client) & (ADMFLAG_ROOT|ADMFLAG_BAN)))
				g_iBlockTime[client] = GetTime();					
		}
	}
	else
	{
		g_iBlockTime[client] = GetTime();
	}
	g_iBlockWarnings[client] = 0;
}

StartScrambleDelay(Float:delay, bool:now, bool:restart)
{
	new iNow = 0, iRestart = 0, iSender = 0;
	if (now)
		iNow = 1;
	if (restart)
		iRestart = 2;
	iSender = iNow + iRestart;
	if (g_hScrambleDelay != INVALID_HANDLE)
	{
		KillTimer(g_hScrambleDelay);
		g_hScrambleDelay = INVALID_HANDLE;
	}
	
	g_hScrambleDelay = CreateTimer(delay, Timer_ScrambleDelay, iSender, TIMER_FLAG_NO_MAPCHANGE);
	if (delay >= 2.0)
	{
		PrintToChatAll("[SM] %T", "ScrambleDelay", LANG_SERVER, RoundFloat(delay));
		if (!g_bBonusRound)
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

public Action:Timer_ScrambleDelay(Handle:timer, any:info)
{
	new	bool:now = false,
		bool:restart = false;
	if (info == 1)
		now = true;
	if (info == 2)
		restart = true;
	if (info == 3)
	{
		now = true;
		restart = true;
	}
	scramble(now, restart);
	g_hScrambleDelay = INVALID_HANDLE;
	return Plugin_Handled;
}

stock GetPlayerPriority(client) /* prioritizes players based on if they're alive, have buildings, or have uber charged*/
{
	if (g_bDisablePrioity)
		return 0;
	if (IsClientInGame(client) && IsValidTeam(client) && !IsFakeClient(client))
	{
		new bHasSentry[MAXPLAYERS+1],
			bHasTeleporter[MAXPLAYERS+1],
			bHasDispenser[MAXPLAYERS+1],
			MaxEntities = GetEntityCount(),
			String:strClassName[64],
			ownerOffset;
		for (new i=1;i <= MaxEntities; i++)
		{
			if (IsValidEntity(i))
			{
				if (strcmp(String:strClassName, "CObjectSentrygun", true) == 0)
					bHasSentry[GetEntDataEnt2(i, ownerOffset)] = 1;				
				else if (strcmp(String:strClassName, "CObjectTeleporter", true) == 0)
					bHasTeleporter[GetEntDataEnt2(i, ownerOffset)] = 1;
				else if (strcmp(String:strClassName, "CObjectDispenser", true) == 0)
					bHasDispenser[GetEntDataEnt2(i, ownerOffset)] = 1;
			}
		}
		if (bHasSentry[client])
			return -3;
		else if (bHasDispenser[client] || bHasTeleporter[client])
			return -2;
		else if (IsPlayerAlive(client))
		{
			if (TF2_GetPlayerClass(client) == TFClass_Medic)
			{
				new String:weaponName[64];
				if(StrEqual(weaponName, "tf_weapon_medigun"))  /*Antithasys code for finding uber level*/
				{
					new entityIndex = GetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
					new Float:chargeLevel = GetEntDataFloat(entityIndex, FindSendPropInfo("CWeaponMedigun", "m_flChargeLevel"));
					if (chargeLevel >= 0.55)
						return -2;
				}
			}
			return -1;
		}		
	}
	return 0;
}

GetTeamInfo() /* returns what team is larger, and puts that team into an array to be balanced later*/
{
	new iBluTeamSize = GetTeamClientCount(TEAM_BLUE),
		iRedTeamSize = GetTeamClientCount(TEAM_RED),
		iReturnTeam = 0,
		iDifference = GetConVarInt(cvar_BalanceLimit);
	if (iBluTeamSize == iRedTeamSize)
		return 0;
	g_iTeamDifference = 0;
		
	if (iRedTeamSize - iBluTeamSize >= iDifference)
	{
		iReturnTeam = TEAM_RED;
		g_iTeamDifference = iRedTeamSize - iBluTeamSize;
	}	
	else if (iBluTeamSize - iRedTeamSize >= iDifference)
	{
		iReturnTeam = TEAM_BLUE;
		g_iTeamDifference = iBluTeamSize - iRedTeamSize;
	}
	
	if (!iReturnTeam)
		return 0;
	return iReturnTeam;	
}

GetLargeTeam(team, bool:command)
{
	g_iFatSize = 0;
	for (new i = 1; i <= MaxClients; i++) 
	{
		if(IsClientInGame(i))
		{
			if(GetClientTeam(i) == team) 
			{
				g_iFatTeam[g_iFatSize][0] = i;
				if (command)
				{
					g_iFatTeam[g_iFatSize][1] = GetPlayerPriority(i);	
				}
				else 
					g_iFatTeam[g_iFatSize][1] = 0;
				g_iFatSize++;
			}
		}
	}
	if (command)
		SortCustom2D(g_iFatTeam, g_iFatSize, SortScoreDesc); // sort the array so low prio players are on the bottom	
}

bool:IsValidTeam(client) /*check to see if client is red or blue */
{
	new team = GetClientTeam(client);
	if (team == TEAM_RED || team == TEAM_BLUE)
		return true;
	return false;
}	

bool:IsMapEnding() /* i force poeple to specify the timeleft :( */
{
	new Handle: cvar_WinLimit = FindConVar("mp_winlimit"),
		Handle: cvar_MaxRounds = FindConVar("mp_maxrounds"),
		Handle: cvar_TimeLimit = FindConVar("mp_timelimit"),
		winLimit = GetConVarInt(cvar_WinLimit),
		maxRounds = GetConVarInt(cvar_MaxRounds),
		timeLimit = GetConVarInt(cvar_TimeLimit);
 	if (!winLimit && !timeLimit && !maxRounds)
		return false;		
	if (timeLimit)
	{
		new timeLeft;
		GetMapTimeLeft(timeLeft);		
		if ((timeLeft - GetConVarInt(cvar_TimeLeft) * 60) <= 0)
			return true;
	}	
	if (maxRounds)
	{
		if (g_iCompleteRrounds >= maxRounds)
			return true;
	}	
	if (winLimit)
	{
		if (g_iRedScore >= winLimit || g_iBluScore >= winLimit)
			return true;
	}
	return false;
}

public Handle_Category( Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength )
{
	switch( action )
	{
		case TopMenuAction_DisplayTitle:
			Format( buffer, maxlength, "What do you want to do?" );
		case TopMenuAction_DisplayOption:
			Format( buffer, maxlength, "gScramble Commands" );
	}
}

public OnLibraryRemoved(const String:name[])
{
	if (StrEqual(name, "adminmenu"))
	{	
		g_hAdminMenu = INVALID_HANDLE;
	}
}

public OnAdminMenuReady(Handle:topmenu)
{
	decl String:flags[256];
	GetConVarString(cvar_ScrambleNowFlag, flags, 256);
	new ibFlags = ReadFlagString(flags);
	
	decl String:b_flags[256];
	GetConVarString(cvar_BalanceFlag, b_flags, 256);
	new bFlags = ReadFlagString(b_flags);
	
	decl String:v_flags[256];
	GetConVarString(cvar_VoteFlag, v_flags, 256);
	new vFlags = ReadFlagString(v_flags);
			
	if (topmenu == g_hAdminMenu)
		return;
		
	g_hAdminMenu = topmenu;	
	
	new TopMenuObject:menu_category = AddToTopMenu(
	g_hAdminMenu,		// Menu
	"gScramble Commands",		// Name
	TopMenuObject_Category,	// Type
	Handle_Category,	// Callback
	INVALID_TOPMENUOBJECT	// Parent
	);
	
	if( menu_category == INVALID_TOPMENUOBJECT )
	{
		return;
	}		
	AddToTopMenu(g_hAdminMenu, 
		"gscramble",
		TopMenuObject_Item,
		AdminMenu_Scramble,
		menu_category,
		"gscramble",
		ADMFLAG_BAN);
	AddToTopMenu(g_hAdminMenu, 
		"gscramble_now",
		TopMenuObject_Item,
		AdminMenu_ScrambleNow,
		menu_category,
		"gscramble_now",
		ibFlags); // so that the cvar for admin flag works on the menu too. :D		
	AddToTopMenu(g_hAdminMenu, 
		"gscramble_balance",
		TopMenuObject_Item,
		AdminMenu_ScrambleBalance,
		menu_category,
		"gscramble_balance",
		bFlags);		
	AddToTopMenu(g_hAdminMenu, 
		"gscramble_vote_now",
		TopMenuObject_Item,
		AdminMenu_ScrambleVoteNow,
		menu_category,
		"gscramble_vote_now",
		vFlags);		
	AddToTopMenu(g_hAdminMenu, 
		"gscramble_vote_end",
		TopMenuObject_Item,
		AdminMenu_ScrambleVoteEnd,
		menu_category,
		"gscramble_vote_end",
		vFlags);
	AddToTopMenu(g_hAdminMenu, 
		"gscramble_scrambe_restart",
		TopMenuObject_Item,
		AdminMenu_ScrambleRestart,
		menu_category,
		"gscramble_scramble_restart",
		ibFlags);
	AddToTopMenu(g_hAdminMenu, 
		"gs_reset_votes",
		TopMenuObject_Item,
		AdminMenu_ScrambleReset,
		menu_category,
		"gs_reset_votes",
		ADMFLAG_BAN);
}

public AdminMenu_Scramble(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
	{
		if (g_bScramble || g_hScrambleDelay != INVALID_HANDLE)
			Format(buffer, maxlength, "%T", "MenuCancelTitle", LANG_SERVER);
		else
			Format(buffer, maxlength, "%T", "MenuScrambleRoundTitle", LANG_SERVER);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (g_bScramble || g_hScrambleDelay != INVALID_HANDLE)
			PerformCancel(param);
		else
			SetupRoundScramble(param);
	}
}

public AdminMenu_ScrambleNow(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "MenuScrambleNow", LANG_SERVER);
	else if (action == TopMenuAction_SelectOption)
	{
		PerformScrambleNow(param, false);
	}
}	

public AdminMenu_ScrambleBalance(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "MenuBalance", LANG_SERVER);
	else if (action == TopMenuAction_SelectOption)
	{
		PerformBalance(param);
	}
}

public AdminMenu_ScrambleVoteNow(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "MenuNowVote", LANG_SERVER);
	else if (action == TopMenuAction_SelectOption)
	{
		g_bScrambleNow = true;
		PerformVote(param);
	}
}

public AdminMenu_ScrambleVoteEnd(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "MenuRoundVote", LANG_SERVER);
	else if (action == TopMenuAction_SelectOption)
	{
		g_bScrambleNow = false;
		PerformVote(param);
	}
}

public AdminMenu_ScrambleRestart(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "MenuScrambleRestart", LANG_SERVER);
	else if (action == TopMenuAction_SelectOption)
	{
		PerformScrambleNow(param, true);
	}
}

public AdminMenu_ScrambleReset(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength)
{
	if (action == TopMenuAction_DisplayOption)
		Format(buffer, maxlength, "%T", "MenuResetVotes", LANG_SERVER, g_iVotes);
	else if (action == TopMenuAction_SelectOption)
	{
		PerformReset(param);
	}
}

public SortScoreDesc(x[], y[], array[][], Handle:data)		// this sorts everything in the info array descending
{
    if (x[1] > y[1]) 
		return -1;
    else if (x[1] < y[1]) 
		return 1;    
    return 0;
}

public SortScoreDesc_f(x[], y[], array[][], Handle:data)	// same thing, but for an array of floats
{
    if (Float:x[1] > Float:y[1])
        return -1;
	else if (Float:x[1] < Float:y[1])
		return 1;
    return 0;
}  
// never inteneded it to get this long