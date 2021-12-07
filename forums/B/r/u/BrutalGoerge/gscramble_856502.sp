/*		
1.5	- attempts to check to see if the map is going to change before running an auto-scramble		
	New cvar:
	- sm_gscramble_timeleft_skip "0" if there is this many minutes or less remaining, stop scrambling		
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
	- renamed cvars and commands to have sm_gs_ prefix instead of sm_gscramble (let it regenerate the config file)
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
#define VERSION "1.8.2.6"
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
new Handle:g_hScrambleDelayTimer				= INVALID_HANDLE;
new Handle:cvar_Punish				= INVALID_HANDLE;

new Handle:cvar_Arena							= INVALID_HANDLE;
new Handle:cvar_ArenaQueue			= INVALID_HANDLE;
new Handle:g_hAdminMenu 						= INVALID_HANDLE;

new bool:g_bScramble = false;		// triggers a scramble
new bool:g_bScrambling = false;		// true when scramble function is active
new bool:g_bVoteAllowed; 			// allows/disallows voting
new bool:g_bBonusRound; 			// toggles if the bonus round is active so that any scramble toggles happen instantly
new bool:g_bScrambleNow;			// if this is true, the scramble command will repsawn dead players
new bool:g_bVoteTimeAllowed = true; 	// menu votes
new bool:g_bWasFullRound = false;		// true if the last round was a full round
new bool:g_bPreGameScramble;

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
new g_iTeamPlayers;
new g_iSwitches;
new gamerules = -1;
new String:g_sLogFile[64];
new String:g_sVoteInfo[3][65];
new g_iFatTeam[MAXPLAYERS+1][2];
new bool:g_bHasVoted[MAXPLAYERS + 1];
new g_iBlockTime[MAXPLAYERS +1];
new g_iWins[4];
new bool:g_bLog;
new g_iBlockWarnings[MAXPLAYERS + 1];

public Plugin:myinfo = 
{
	name = "gScramble",
	author = "Goerge",
	description = "A comprehensive scramble plugin.",
	version = VERSION,
	url = "http://www.fpsbanana.com"
};

public OnPluginStart()
{	
	cvar_AdminImmune		= CreateConVar("sm_gs_teamswitch_immune",	"1",	"Sets if admins are immune from team swap blocking", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ScrambleAdminImmune = CreateConVar("sm_gs_scramble_immune", "0",		"Sets if admins are immune from being scrambled.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AutoScramble		= CreateConVar("sm_gs_auto_enable",		"1", 		"Enables/disables the automatic scrambling 0=off.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_AutoscrambleVote	= CreateConVar("sm_gs_autovote",		"0",		"Starts a scramble vote instead of scrambling at the end of a round", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_BalanceFlag 		= CreateConVar("sm_gs_flag_balance", 	"b", 		"Admin flag for those allowed to force a team balance", FCVAR_PLUGIN);
	cvar_ScrambleNowFlag 	= CreateConVar("sm_gs_flag_now", 		"n", 		"Admin flag for who has access to scramble teams now.", FCVAR_PLUGIN);
	cvar_VoteFlag			= CreateConVar("sm_gs_flag_vote",		"b",		"Admin flag for those allowed to start a scramble vote", FCVAR_PLUGIN);
	cvar_FullRoundOnly 		= CreateConVar("sm_gs_fullround_only",	"0",		"Auto-scramble only after a full round has completed.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ForceBalance 		= CreateConVar("sm_gs_force_balance",	"0", 		"Force a balance between each round. (If you use a custom team balance plugin that doesn't do this already, or you have the default one disabled)", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Log				= CreateConVar("sm_gs_logactivity",		"0",		"Log all activity of the plugin", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_MinAutoPlayers 	= CreateConVar("sm_gs_min_autoplayers", "12", 		"Minimum people connected before automatic scrambles are possible", FCVAR_PLUGIN, true, 0.0, false);
	cvar_FragRatio 			= CreateConVar("sm_gs_hfragratio", 		"2.0", 		"If a teams wins with a frag ratio greater than or equal to this setting, trigger a scramble", FCVAR_PLUGIN, true, 1.2, false);
	cvar_TimeLeft 			= CreateConVar("sm_gs_timeleft_skip",	"0", 		"If there is this many minutes or less remaining, stop autoscrambling", FCVAR_PLUGIN, true, 0.0, false);
	cvar_WaitScramble 		= CreateConVar("sm_gs_prescramble", 	"0", 		"If enabled, teams will scramble at the end of the 'waiting for players' period", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_VoteMode			= CreateConVar("sm_gs_public_votemode",	"0",		"For public chat votes: 0 = if enough triggers, enable scramble.  1 = if enough triggers, start menu vote to start a scramble", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_PublicNeeded		= CreateConVar("sm_gs_public_needed", 	"0.60",		"Percentage of people needing to trigger a scramble in chat.  If using votemode 1, I suggest you set this lower than 50%", FCVAR_PLUGIN, true, 0.05, true, 1.0);
	cvar_VoteEnable 		= CreateConVar("sm_gs_public_votes",	"1", 		"Enable/disable public voting", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Punish				= CreateConVar("sm_gs_punish_stackers", "0", 		"Punish clients trying to restack teams during the team-switch block period by adding time to when they are able to team swap again", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_SortMode			= CreateConVar("sm_gs_sort_mode",		"1",		"Player scramble sort mode.\n1 = Random\n2 = Player Score\n3 = Player Score Per Minute.\nThis controls how players get swapped during a scramble.", FCVAR_PLUGIN, true, 1.0, true, 3.0);
	cvar_SpecBlock 			= CreateConVar("sm_gs_changeblocktime",	"120", 		"Time after being swapped by a scramble where players aren't allowed to change teams", FCVAR_PLUGIN, true, 0.0, false);
	cvar_VoteEnd			= CreateConVar("sm_gs_vote_behavior",	"0",		"0 will trigger scramble for round end.\n1 will scramble teams after vote.", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_Needed 			= CreateConVar("sm_gs_vote_needed", 	"0.60", 	"Percentage of votes for the menu vote scramble needed.", FCVAR_PLUGIN, true, 0.05, true, 1.0);
	cvar_Delay 				= CreateConVar("sm_gs_vote_delay", 		"60.0", 	"Time after the map has started in which players can votescramble.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_MinPlayers 		= CreateConVar("sm_gs_vote_minplayers","6", 		"Minimum poeple connected before any voting will work.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_WinStreak			= CreateConVar("sm_gs_winstreak",		"0", 		"If set, it will scramble after a team wins X full rounds in a row", FCVAR_PLUGIN, true, 0.0, false);
	cvar_Steamroll 			= CreateConVar("sm_gs_wintime_limit", 	"120.0", 	"If a team wins in less time than this, and has a frag ratio greater than specified: perform an auto scramble.", FCVAR_PLUGIN, true, 0.0, false);
	cvar_SteamrollRatio 	= CreateConVar("sm_gs_wintime_ratio", 	"1.5", 		"Lower kill ratio for teams that win in less than the wintime_limit.", FCVAR_PLUGIN, true, 0.0, false);
	
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

	HookEvent("teamplay_round_start", 		hook_Start, EventHookMode_Post);
	HookEvent("teamplay_round_win", 		hook_Win, EventHookMode_Post);
	HookEvent("teamplay_setup_finished", 	hook_Setup, EventHookMode_Post);
	HookEvent("teamplay_win_panel", 		hook_Panel, EventHookMode_Post);
	HookEvent("player_death", 				hook_Death, EventHookMode_Pre);
	HookEvent("player_team", 				hook_Team, EventHookMode_Pre);
	HookEvent("game_start", 				hook_Event_GameStart);
	HookEventEx("teamplay_restart_round", 	hook_Event_TFRestartRound);
	HookConVarChange(cvar_Log, LogSettingChange);
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
	g_bHasVoted[client] = false;
	g_iVoters++;
	g_iVotesNeeded = RoundToFloor(float(g_iVoters) * GetConVarFloat(cvar_PublicNeeded));
}

public OnClientDisconnect(client)  // reset any vote the cient may have made
{
	if(IsFakeClient(client))
		return;		
	
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
	g_hScrambleDelayTimer = INVALID_HANDLE;
	g_iRedFrags = 0;
	g_iBluFrags = 0;
	g_iCompleteRrounds = 0;
	g_iRoundStarts = 0;
	
	g_iWins[TEAM_RED] = 0;
	g_iWins[TEAM_BLUE] = 0;
	
	g_iTeamPlayers = 0;
	g_iSwitches = 0;
	g_bWasFullRound = false;
	g_bPreGameScramble = false;
	
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
			if (g_iBlockWarnings[client] < 3) /* to cut the spam for people trying to swap over and over*/
			{
				PrintToChat(client, "[SM] %T", "BlockSwitchMessage", LANG_SERVER);
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
			
			return Plugin_Handled;
		}
	}
	return Plugin_Continue;
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
	if (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue))
	{
		ReplyToCommand(client, "[SM] %T", "ArenaReply", LANG_SERVER);
		return;
	}
	
	new iLargeTeam = GetTeamInfo(true);
	if(iLargeTeam)
	{
		BalanceTeams(true, iLargeTeam);
		if (g_bLog)
		{
			decl String:ClientName[64];
			if (!client)
				Format(ClientName, 64, "Console");
			else
				GetClientName(client, ClientName, 64);
			LogToFile(g_sLogFile, "%s forced a team balance.", ClientName);
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
		new swaps = 0;
		for (new i=0; swaps < (g_iTeamDifference / 2) || g_iFatSize < i; i++)
		{
			if (g_iFatTeam[i][0] && !(GetUserFlagBits(g_iFatTeam[i][0]) & (ADMFLAG_RESERVATION|ADMFLAG_ROOT)))
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
					SetEventInt(event, "team", team == TEAM_BLUE ? TEAM_RED : TEAM_BLUE);
					FireEvent(event);
				}
			}
		}		
	}
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
	if (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue))
	{
		ReplyToCommand(client, "[SM] %T", "ArenaReply", LANG_SERVER);
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
		if (g_hScrambleDelayTimer != INVALID_HANDLE)
		{
			KillTimer(g_hScrambleDelayTimer);
			g_hScrambleDelayTimer = INVALID_HANDLE;
		}
	}
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
		else // if the trigger happens during the bonusround, scramble ASAP
		{
			if(g_bBonusRound)
			{
				if (GetConVarBool(cvar_FullRoundOnly) && g_bWasFullRound)
					StartScrambleDelay(2.0, false, false);
				if (!GetConVarBool(cvar_FullRoundOnly))
					StartScrambleDelay(2.0, false, false);
			}
			else // else we'll settle for a scrambling at the end of the current round
			{
				g_bScramble = true;
				PrintToChatAll("[SM] %T", "ScrambleRound", LANG_SERVER);
				if (g_bLog)
					LogToFile(g_sLogFile, "Scramble initialized due to voting.");
			}
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
			PrintToChatAll("[SM] %T", "VoteFailed", LANG_SERVER);
			if (g_bLog)
				LogToFile(g_sLogFile, "Vote Scramble has Failed due to an insufficient amount of votes");
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
				if (GetConVarBool(cvar_FullRoundOnly) && g_bWasFullRound && g_bBonusRound)
				{
					StartScrambleDelay(2.0, false, false);
				}
				if (!GetConVarBool(cvar_FullRoundOnly) && g_bBonusRound)
				{
					StartScrambleDelay(2.0, false, false);
				}				
				if (!g_bBonusRound)
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

/*--------------------------------------------------------------- scramble command --------------------------------------*/
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
	if (g_bScramble || g_hScrambleDelayTimer != INVALID_HANDLE)
	{
		g_bScramble = false;
		if (g_hScrambleDelayTimer != INVALID_HANDLE)
		{
			KillTimer(g_hScrambleDelayTimer);
			g_hScrambleDelayTimer = INVALID_HANDLE;
		}
	}
	else
	{
		ReplyToCommand(client, "[SM] %T", "NoScrambleReply", LANG_SERVER);
		return;
	}	
	PrintToChatAll("[SM] %T", "CancelScramble", LANG_SERVER);
	if (g_bLog)
	{
		new String:clientName[32];
		GetClientName(client, clientName, sizeof(clientName));
		LogToFile(g_sLogFile, "%s canceled the pending scramble.", clientName);
	}
}

SetupRoundScramble(client)
{
	if (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue))
	{
		ReplyToCommand(client, "[SM] %T", "ArenaReply", LANG_SERVER);
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
		
	if (g_bBonusRound)
	{
		StartScrambleDelay(2.0, false, false);
		if (g_bLog)
			LogToFile(g_sLogFile, "%s toggled a scramble during the BonusRound", ClientName);
	}
	else
	{
		g_bScramble = true;
		PrintToChatAll("[SM] %T", "ScrambleRound", LANG_SERVER);
		if (g_bLog)
			LogToFile(g_sLogFile, "%s toggled a round-end scramble.", ClientName);
	}
}

/*----------------------------------------------------------------------------------- team change hook -----------------*/
public Action:hook_Team(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetEventBool(event, "disconnect")) 
	{
		return Plugin_Continue;
	}
	
	if (g_bScrambling)
	{
		return Plugin_Handled;
	}
	
	new NewTeam = GetEventInt(event, "team"),
		OldTeam = GetEventInt(event, "oldteam");
		
	if (OldTeam == TEAM_SPEC || OldTeam == TEAM_UNSIG) 
	{
		// Don't throw people back onto unassigned or spec
		return Plugin_Continue;
	}
	
	new id = GetEventInt(event, "userid"),
		client = GetClientOfUserId(id);	
	if (IsFakeClient(client))
		return Plugin_Continue;
	
	if (g_bWasFullRound)
	{
		if (NewTeam == TEAM_RED || NewTeam == TEAM_BLUE)
			g_iSwitches++;
	}	
	return Plugin_Continue;
}

public Action:hook_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue))   /* if arena, skip */
		return Plugin_Continue;
		
	if (!GetConVarBool(cvar_AutoScramble) && !GetConVarBool(cvar_WinStreak))  
		return Plugin_Continue;
	
	if (g_bWasFullRound && g_iVoters >= GetConVarInt(cvar_MinAutoPlayers))  /* win-streak: swap the scores for the consecutive win counter if the teams were swapped*/
	{
		new Float:switchRatio = float(g_iSwitches) / float(g_iTeamPlayers);
		if (switchRatio >= 0.80)
		{
			new oldRed = g_iWins[TEAM_RED], oldBlu = g_iWins[TEAM_BLUE];
			g_iWins[TEAM_RED] = oldBlu;
			g_iWins[TEAM_BLUE] = oldRed;
		}
	}
	g_bPreGameScramble = false;
	if (GetConVarBool(cvar_WaitScramble) && g_iRoundStarts == 0) /* sets up pre-game scramble*/
	{
		new Handle:cvar_WaitingTime = FindConVar("mp_waitingforplayers_time");
		
		new Float:delay = GetConVarFloat(cvar_WaitingTime) - 1.0;
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
	if (g_bWasFullRound)
		CreateTimer(1.0, Timer_FullRoundReset, _, TIMER_FLAG_NO_MAPCHANGE); 
	return Plugin_Continue;
}

public Action:Timer_FullRoundReset(Handle:timer)
{
	g_bWasFullRound = false;
	return Plugin_Handled;
}

public Action:hook_Setup(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvar_AutoScramble) || (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue)))
		return Plugin_Continue;
		
	// get the start time of the round for the scteamroll detector
	g_iRoundStartTime = GetTime();
	return Plugin_Continue;
}

public Action:hook_Panel(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!GetConVarBool(cvar_AutoScramble) || (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue)))
		return Plugin_Continue;
		
	g_iRedScore = GetEventInt(event, "red_score");
	g_iBluScore = GetEventInt(event, "blu_score");
	
	return Plugin_Continue;
}

public Action:timerTeamSwap(Handle:timer)
{
	g_iTeamPlayers = 0;
	g_iSwitches = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && !IsFakeClient(i) && IsValidTeam(i))
			g_iTeamPlayers++;
	}
	return Plugin_Continue;
}

/* ----------------------------------------------------------------------------------------------- teamplay_round_win hook --*/
public Action:hook_Win(Handle:event, const String:name[], bool:dontBroadcast){	
		
	if (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue)) /* disabled if arena */
		return Plugin_Continue;
		
	if (!g_bScramble 
		&& !GetConVarBool(cvar_AutoScramble) 
		&& !GetConVarBool(cvar_WinStreak)
		&& GetConVarBool(cvar_ForceBalance)) /* disabled if autoscramble disabled, focebalance, and winstreak scrambling disabled */
		return Plugin_Continue;
	
	g_bWasFullRound = false;
	
	if (GetEventBool(event, "full_round"))
	{
		g_bWasFullRound = true;
		g_iCompleteRrounds++;
		new delay = GetConVarInt(cvar_bonusRound);
		CreateTimer((float(delay) - 0.3), timerTeamSwap, TIMER_FLAG_NO_MAPCHANGE);
	}
	g_bBonusRound = true;
		
	new winningTeam = GetEventInt(event, "team");	
	/* if it was a full round, and the map is about to end, we don't allow it to autoscramble	
		this also though let scrambles happen during minirounds like in dustbowl in goldrush if the timeleft = 0, but the attacking team continues to win rounds */	
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

	if (!g_bScramble && GetConVarBool(cvar_ForceBalance)) /* if no scramble, and force balance active, balnce this */
	{
		new balance_delay = GetConVarInt(cvar_bonusRound) - 1;
		if (balance_delay <=5)
			balance_delay = 5;
		CreateTimer(float(balance_delay) + 0.7, TimerBalance, TIMER_FLAG_NO_MAPCHANGE);
	}	
	
	if (g_bScramble)
	{
		new delay = GetConVarInt(cvar_bonusRound); 		// makes it scramble right before the new round starts, best time in my opinion :D
		if (delay <= 0) 								// make sure bonusround there is at least 5 seconds of bonusround no matter what, i believe
			delay = 5;
		StartScrambleDelay((float(delay) - 0.2), false, false);
	}
	return Plugin_Continue;
}

public Action:TimerBalance(Handle:timer)
{
	g_bScrambling = true; /* block death event.. */
	BalanceTeams(false, GetTeamInfo(false));
	g_bScrambling = false;
	return Plugin_Handled;
}

public Action:hook_Death(Handle:event, const String:name[], bool:dontBroadcast) /* ---------------------------------- player_death hook ------*/
{
	if (!GetConVarBool(cvar_AutoScramble) || (GetConVarBool(cvar_Arena) && GetConVarBool(cvar_ArenaQueue)))
		return Plugin_Continue;
	if (!g_bScrambling && g_bBonusRound)
		return Plugin_Continue;
		
	if (g_bScrambling) /*hides all death events while the plugin is scrambling*/
	{
		return Plugin_Handled;
	}
	new killer = GetEventInt(event, "attacker"),
		k_client = GetClientOfUserId(killer),
		victim = GetEventInt(event, "userid"),
		v_client = GetClientOfUserId(victim);
	
	if (!k_client)
	{
		return Plugin_Continue;	// environemt check
	}
	if (k_client == v_client)
	{
		return Plugin_Continue; 	// suicide check
	}	
	new team = GetClientTeam(k_client);
	if (team == TEAM_RED)
		g_iRedFrags++;
	else
		g_iBluFrags++;
	return Plugin_Continue;
}

bool:IsValidScrambleTarget(client)
{
	if (IsClientInGame(client) && IsValidTeam(client) && !IsFakeClient(client))
	{
		if (GetConVarBool(cvar_ScrambleAdminImmune))
		{
			if (GetUserFlagBits(client) & (ADMFLAG_ROOT|ADMFLAG_RESERVATION|ADMFLAG_GENERIC))
				return false;
			else return true;
		}			
		else
			return true;
	}
	else 
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
		new Float:fScores[MaxClients+1][2];
		for (i=1; i<=MaxClients;i++)
		{
			if (IsValidScrambleTarget(i))
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
		new iScores[MaxClients+1][2];
		
		for (i=1; i<=MaxClients;i++)
		{
			if (IsValidScrambleTarget(i))
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
		new players[MaxClients+1];
		
		for(i = 1; i <= MaxClients; i++) 
		{
			if(IsValidScrambleTarget(i)) 
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
		PrintToChatAll("[SM] %T", "DeadSpawn", LANG_SERVER);
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
			if (GetUserFlagBits(client) & (ADMFLAG_ROOT|ADMFLAG_BAN))
			{}
			else
			{
				g_iBlockTime[client] = GetTime();
			}			
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
	if (g_hScrambleDelayTimer != INVALID_HANDLE)
	{
		KillTimer(g_hScrambleDelayTimer);
		g_hScrambleDelayTimer = INVALID_HANDLE;
	}
	
	g_hScrambleDelayTimer = CreateTimer(delay, Timer_ScrambleDelay, iSender, TIMER_FLAG_NO_MAPCHANGE);
	PrintToChatAll("[SM] %T", "ScrambleDelay", LANG_SERVER, RoundFloat(delay));
	if (delay >= 2.0 && !g_bBonusRound)
	{
		EmitSoundToAll(EVEN_SOUND, SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
		CreateTimer(1.7, TimerStopSound);
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
	g_hScrambleDelayTimer = INVALID_HANDLE;
	return Plugin_Handled;
}

GetTeamInfo(bool:command) /* returns what team is larger, and puts that team into an array to be balanced later*/
{
	new iBluTeamSize = 0,
		iRedTeamSize = 0,
		bHasSentry[MAXPLAYERS+1],
		iReturnTeam = 0,
		MaxEntities = GetEntityCount(),
		String:strClassName[64],
		ownerOffset;

	g_iTeamDifference = 0;
	g_iFatSize = 0;
	
	/* Get the team sizes */	
	for (new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			if (GetClientTeam(i) == TEAM_RED)
				iRedTeamSize++;
			else if (GetClientTeam(i) == TEAM_BLUE)
				iBluTeamSize++;
		}
	}
	
	if (iRedTeamSize - iBluTeamSize < -1)
	{
		iReturnTeam = TEAM_BLUE;
		g_iTeamDifference = iBluTeamSize - iRedTeamSize;
	}
	
	if(iBluTeamSize - iRedTeamSize < -1)
	{
		iReturnTeam = TEAM_RED;
		g_iTeamDifference = iRedTeamSize - iBluTeamSize;
	}
	
	if (!iReturnTeam)
		return 0;
	
	if (command) /* find out who has sentries*/
	{
		for (new i=1;i <= MaxEntities; i++)
		{
			if (IsValidEntity(i))
			{
				if (strcmp(String:strClassName, "CObjectSentrygun", true) == 0)
				{
					bHasSentry[GetEntDataEnt2(i, ownerOffset)] = -1;					
				}
			}
		}
	}
	
	if (iReturnTeam) // put larger team in array
	{
		for (new i = 1; i <= MaxClients; i++) 
		{
			if(IsClientInGame(i))
			{
				if(GetClientTeam(i) == iReturnTeam) 
				{
					g_iFatTeam[g_iFatSize][0] = i;
					if (command)
					{
						if (IsPlayerAlive(i))
						{
							g_iFatTeam[g_iFatSize][1] = -1;
							if (TF2_GetPlayerClass(i) == TFClass_Medic)
							{
								new String:weaponName[64];
								if(StrEqual(weaponName, "tf_weapon_medigun"))  /*Antithasys code for finding uber level*/
								{
									new entityIndex = GetEntDataEnt2(i, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
									new Float:chargeLevel = GetEntDataFloat(entityIndex, FindSendPropInfo("CWeaponMedigun", "m_flChargeLevel"));
									if (chargeLevel >= 0.55)
										g_iFatTeam[g_iFatSize][1] = -2;
								}
							}
						}
						if (bHasSentry[i])
							g_iFatTeam[g_iFatSize][1] = -3;	
					}
					g_iFatSize++;
				}
			}
		}
		if (command)
			SortCustom2D(g_iFatTeam, g_iFatSize, SortScoreDesc);  // sort the array so low prio players are on the bottom
	}
	return iReturnTeam;	
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
			Format( buffer, maxlength, "What do you want to do? :D" );
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
		if (g_bScramble || g_hScrambleDelayTimer != INVALID_HANDLE)
			Format(buffer, maxlength, "%T", "MenuCancelTitle", LANG_SERVER);
		else
			Format(buffer, maxlength, "%T", "MenuScrambleRoundTitle", LANG_SERVER);
	}
	else if (action == TopMenuAction_SelectOption)
	{
		if (g_bScramble || g_hScrambleDelayTimer != INVALID_HANDLE)
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