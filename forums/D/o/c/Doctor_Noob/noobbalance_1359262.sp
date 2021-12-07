/*
    Copyright 2010, Duck Soup Gaming.
    
    Portions copyright 2008-2010, Simple SourceMod Plugins.
    Portions copyright 2009, Shana Gitnick.

    NoobBalance is free software: you can redistribute it and/or modify
    it under the terms of the GNU General Public License as published by
    the Free Software Foundation, either version 3 of the License, or
    (at your option) any later version.

    NoobBalance is distributed in the hope that it will be useful,
    but WITHOUT ANY WARRANTY; without even the implied warranty of
    MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
    GNU General Public License for more details.

    You should have received a copy of the GNU General Public License
    along with NoobBalance.  If not, see <http://www.gnu.org/licenses/>.
*/

#pragma semicolon 1

#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define TEAM_SPECTATOR 1
#define TEAM_RED 2
#define TEAM_BLUE 3
 
#undef REQUIRE_PLUGIN
#include <adminmenu>
#define REQUIRE_PLUGIN


//Type definitions

enum GameState {
	map_loaded,
	waiting_for_players,
	humiliation,
	sudden_death,
	map_ending,
	setup,
	normal
};



//Global variables

new bool:plugin_enable = true;
new String:plugin_prefix[] = "\x04[\x03Balance\x04]\x01 ";
//new String:plugin_prefix[] = "\x03[\x01Balance\x03]\x01 ";

new bool:enable_votescramble = true;
new min_players_for_votescramble = 5;
new Float:votescramble_base_fraction = 0.30;
new Float:votescramble_fraction;

new num_scramble_votes = 0;
new bool:scramble_votes[MAXPLAYERS + 1];
new Float:scramble_delay_time = 5.0;	//time to delay the scramble after a successful vote

new client_team_locks[MAXPLAYERS + 1];
new autobalance_lock_time = 90;	//seconds to lock a player to their current team
new team_lock_increase_time = 15;	//seconds to extend the lock by if a player is caught by it
new bool:client_autoassigned[MAXPLAYERS + 1];

new Float:time_infinity = 1000000000000.0;	//a time larger than all other times GetGameTime() might return; 1e12 should do the job

new GameState:game_state = map_loaded;
new bool:round_is_timed = false;
new Float:round_end_time;

new bool:autobalance_enabled = true;
new bool:autobalance_active = false;
new Float:autobalance_check_rate = 3.0;	//check if teams are balanced every this many seconds
new Float:autobalance_min_wait = 1.0;
new Float:autobalance_min_round_time_left = 60.0;	//don't autobalance if there is less than this much time on the clock (TODO: adjust for KOTH?)
new Float:autobalance_force_delay = 45.0;	//force balance after this many seconds

new Float:autobalance_time_targets[MAXPLAYERS + 1];
new Handle:autobalance_timer = INVALID_HANDLE;

new engineer_building;	//holds the property for engineer buildings or something like that


//Globals to hold ConVar settings
new bool:reset_setup_timer = true;
new bool:attach_to_admin_menu = true;
new bool:duel_immunity = true;
new bool:can_lock_immune = false;
new immune_privs;

//Admin menu stuff
new Handle:admin_menu = INVALID_HANDLE; 
new TopMenuObject:NB_menu_category;

//Plugin information
public Plugin:myinfo =
{
	name = "NoobBalance",
	author = "Duck Soup Gaming",
	description = "Keeps teams of players in TF2 balanced by providing automatic and admin-triggered team management functionality",
	version = "1.0.0 RC2",
	url = "http://www.ducksoupgaming.com/"
};


//ConVar stuff

new Handle:CVar_EnableNoobBalance	= INVALID_HANDLE;
new Handle:CVar_EnableAutobalance	= INVALID_HANDLE;

new Handle:CVar_ResetSetupTimer		= INVALID_HANDLE;
new Handle:CVar_MaxTeamsImbalanceTime	= INVALID_HANDLE;
new Handle:CVar_TeamLockTime		= INVALID_HANDLE;
new Handle:CVar_LockExtendTime		= INVALID_HANDLE;
new Handle:CVar_MinRoundTimeRemaining	= INVALID_HANDLE;

new Handle:CVar_MinPlayersForVote	= INVALID_HANDLE;
new Handle:CVar_ScrambleVoteFraction	= INVALID_HANDLE;

new Handle:CVar_ImmunityAdminFlags	= INVALID_HANDLE;
new Handle:CVar_DuelImmunity		= INVALID_HANDLE;
new Handle:CVar_LockImmune		= INVALID_HANDLE;
	
new Handle:CVar_AdminMenuEntry		= INVALID_HANDLE;

stock LoadConVars()
{
	plugin_enable = GetConVarBool(CVar_EnableNoobBalance);
	autobalance_enabled = GetConVarBool(CVar_EnableAutobalance);
	attach_to_admin_menu = GetConVarBool(CVar_AdminMenuEntry);
	
	reset_setup_timer = GetConVarBool(CVar_ResetSetupTimer);
	autobalance_force_delay = GetConVarFloat(CVar_MaxTeamsImbalanceTime);
	autobalance_lock_time = GetConVarInt(CVar_TeamLockTime);
	team_lock_increase_time = GetConVarInt(CVar_LockExtendTime);
	autobalance_min_round_time_left = GetConVarFloat(CVar_MinRoundTimeRemaining);
		
	min_players_for_votescramble = GetConVarInt(CVar_MinPlayersForVote);
	votescramble_base_fraction = GetConVarFloat(CVar_ScrambleVoteFraction);
	if (min_players_for_votescramble > 0)
		enable_votescramble = true;
	else
		enable_votescramble = false;
	
	new String:flags_immune[32];
	GetConVarString(CVar_ImmunityAdminFlags, flags_immune, sizeof(flags_immune));
	immune_privs = ReadFlagString(flags_immune) | ADMFLAG_ROOT;
	
	duel_immunity = GetConVarBool(CVar_DuelImmunity);
	can_lock_immune = GetConVarBool(CVar_LockImmune);
}




















//Interfacing callbacks

public OnPluginStart()
{
	//Set up cvars to load from the config file
	CVar_EnableNoobBalance		= CreateConVar("nbal_enable",			"1",	"Load the plugin", 											   FCVAR_NOTIFY|FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CVar_EnableAutobalance		= CreateConVar("nbal_enable_autobalance",	"1",	"Enable automatic balancing of teams; requires the built-in autobalancer to be disabled",				FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CVar_AdminMenuEntry		= CreateConVar("nbal_admin_menu_entry",		"1",	"Display an entry in the admin menu containing team balancing commands", 				   		FCVAR_PLUGIN, true, 0.0, true, 1.0);

	CVar_ResetSetupTimer		= CreateConVar("nbal_reset_setup",		"1",	"Reset the setup timer if a scramble occurs during setup",								FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CVar_MaxTeamsImbalanceTime	= CreateConVar("nbal_max_imbalance_time",	"45.0",	"Maximum number of seconds teams are allowed to remain imbalanced before an automatic force-balance (0 to disable)",	FCVAR_PLUGIN, true, 0.0, false);
	CVar_TeamLockTime		= CreateConVar("nbal_lock_time",		"90.0",	"Time to lock autobalanced players to their new team (0 to disable)",							FCVAR_PLUGIN, true, 0.0, false);
	CVar_LockExtendTime		= CreateConVar("nbal_lock_extend",		"15.0",	"Punish clients who try to return to their old team by adding this many seconds to their lock time (0 to disable)",	FCVAR_PLUGIN, true, 0.0, false);
	CVar_MinRoundTimeRemaining	= CreateConVar("nbal_min_round_time",		"60.0",	"Block autobalancing if the round has less than this much time remaining",						FCVAR_PLUGIN, true, 0.0, false);

	CVar_MinPlayersForVote		= CreateConVar("nbal_vote_minplayers",		"5",	"Minimum number of players required for the votescramble command to be enabled (0 to disable votescramble)",		FCVAR_PLUGIN, true, 0.0, false);
	CVar_ScrambleVoteFraction	= CreateConVar("nbal_vote_threshold",		"0.30",	"Fraction of players asking for votescramble needed to call a scramble vote",						FCVAR_PLUGIN, true, 0.0, true, 1.0);

	CVar_ImmunityAdminFlags		= CreateConVar("nbal_flags_immunity",		"ab",	"Admin flags to grant autobalance immunity",										FCVAR_PLUGIN);
	CVar_DuelImmunity		= CreateConVar("nbal_duel_immunity",		"1",	"Players in duels have temporary immunity to the autobalancer",								FCVAR_PLUGIN, true, 0.0, true, 1.0);
	CVar_LockImmune			= CreateConVar("nbal_lock_immune",		"0",	"Immune players can be locked to their team",										FCVAR_PLUGIN, true, 0.0, true, 1.0);
	
	AutoExecConfig(true, "plugin.noobbalance");
	LoadConVars();
	
	//If the plugin is supposed to be disabled, do our best to not attach to anything and bail now
	//(But, really, the plugin should not have been loaded in the first place if that was the goal)
	if (!plugin_enable) {
		attach_to_admin_menu = false;
		autobalance_enabled = false;
		enable_votescramble = false;
		return;
	}
	
	// If the admin menu has already been loaded, attach our menu to it
	new Handle:admin_menu_top = GetAdminTopMenu();
	if (LibraryExists("adminmenu") && (admin_menu_top != INVALID_HANDLE))
		OnAdminMenuReady(admin_menu_top);
	
	RegAdminCmd("sm_scramblenow",		Command_ScrambleNow,		ADMFLAG_GENERIC, "Scrambles teams immediately");
	RegAdminCmd("sm_scramblevote",		Command_CallScrambleVote,	ADMFLAG_GENERIC, "Calls a vote asking if teams should be scrambled");
	RegAdminCmd("sm_forcebalance",		Command_ForceBalance,		ADMFLAG_GENERIC, "Force-balances the teams now, ignoring immunity");
	RegAdminCmd("sm_toggleautobalance",	Command_ToggleAutobalance,	ADMFLAG_GENERIC, "Toggles the autobalancer on or off");
	RegAdminCmd("sm_stackteams",		Command_StackNow,		ADMFLAG_GENERIC, "(not implemented)");
	RegAdminCmd("sm_swapplayer",		Command_SwapPlayer,		ADMFLAG_GENERIC, "Swaps a player to the other team");
	RegAdminCmd("balancedebug",		Command_DumpDebugInformation,	ADMFLAG_GENERIC, "Dumps debug information about the balancing plugin's internals");
	
	//Attach to client commands that need to be watched
	AddCommandListener(NB_Listener_ScrambleVote, "say");
	AddCommandListener(NB_Listener_BalanceProtection, "jointeam");
	AddCommandListener(NB_Listener_BalanceProtection, "spectate");
	
	//Hook game events to make sure we know the current state of the game
	HookEvent("game_start", 		hook_game_start,	EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_start", 	hook_round_start,	EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_win", 	hook_round_win,		EventHookMode_PostNoCopy);
	HookEvent("teamplay_setup_finished", 	hook_setup_finished,	EventHookMode_PostNoCopy);
	HookEvent("teamplay_round_stalemate",	hook_round_stalemate,	EventHookMode_PostNoCopy);
	HookEvent("teamplay_game_over", 	hook_game_over,		EventHookMode_PostNoCopy);
	
	//Hook a couple timer events
	HookEvent("teamplay_timer_time_added",	hook_timer_time_added,	EventHookMode_PostNoCopy);
	
	//Make sure the vote record is empty
	ClearScrambleVotes();
	
	//Set this up once so we don't have to do it every time
	engineer_building = FindSendPropInfo("CBaseObject", "m_hBuilder");
	
	//Load some sounds
	PrecacheSound("vo/announcer_am_teamscramble01.wav", true);
	PrecacheSound("vo/announcer_am_teamscramble02.wav", true);
	PrecacheSound("vo/announcer_am_teamscramble03.wav", true);
}

public OnConfigsExecuted()
{
	LoadConVars();
}

public OnLibraryRemoved(const String:name[])
{
	//If the admin menu got disabled, make sure we don't try to use it
	if (StrEqual(name, "adminmenu"))
		admin_menu = INVALID_HANDLE;
}

public OnMapStart()
{
	game_state = map_loaded;
	
	//Clear the vote table and any team locks
	ClearScrambleVotes();
	ClearTeamLocks();
	
	//Reset the fraction of players needed for a votescramble to call a vote
	votescramble_fraction = votescramble_base_fraction;
	
	//Start the autobalance callback
	autobalance_timer = CreateTimer(autobalance_check_rate, CheckBalance, _, TIMER_REPEAT);
	
	//Start the timer check callback to run every now and then
	//	and make sure we still understand where we are in the game
	//	(Necessary because the round timer is painful to deal with)
	autobalance_timer = CreateTimer(15.0, CheckRoundTimer, _, TIMER_REPEAT);
}

public OnMapEnd()
{
	//Shut down the autobalance callback
	if (autobalance_timer != INVALID_HANDLE) {
		KillTimer(autobalance_timer);
		autobalance_timer = INVALID_HANDLE;
	}
	return;
}

public OnClientPostAdminCheck(client)
{
	if(IsFakeClient(client))
		return;
	
	//When clients connect, we need to make sure they are not locked to a team 
	//	because of the ill luck of the last guy to have that client slot
	//Also make them immune to the current autobalance cycle (if running)
	scramble_votes[client] = false;
	client_team_locks[client] = 0;
	autobalance_time_targets[client] = time_infinity;
	client_autoassigned[client] = true;	//err on the side of caution (necessary for mp_forceautoteam true)
}

public OnClientDisconnect(client)
{
	//Clear any team blocks and voting records for this client
	scramble_votes[client] = false;
	client_team_locks[client] = 0;
}








//Bits that respond to player commands

//Listen for "votescramble" or "scramble" as a client chat command
public Action:NB_Listener_ScrambleVote(client, const String:command[], argc)
{
	decl String:text[192];
	
	//Ensure the client is valid
	if (!client)
		return Plugin_Continue;
	
	//Grab the text of the say command
	if (!GetCmdArgString(text, sizeof(text))) {
		return Plugin_Continue;
	}
	
	//Make sure the text is not surrounded by double quotes
	new start = 0;
	new len = strlen(text);
	if(text[len-1] == '"') {
		text[len-1] = '\0';
		start = 1;
		len -= 2;
	}
	//also admit the !votescramble and !scramble forms of commands
	if(text[start] == '!') {
		start++;
		len--;
	}	
	if ((strcmp(text[start], "scramble", false) == 0) || (strcmp(text[start], "votescramble", false) == 0))
		TallyScrambleVote(client);
	
	return Plugin_Continue;	
}

//Block autobalanced players from rejoining their old team
public Action:NB_Listener_BalanceProtection(client, const String:command[], argc)
{
	//Check if the poor client has a team lock in place
	if ((can_lock_immune || !IsImmuneClient(client)) && (client_team_locks[client] > GetTime()) ) {
		PrintToChatAll("%s%N is trying to re-stack the teams. For shame!", plugin_prefix, client);
		client_team_locks[client] += team_lock_increase_time;
		return Plugin_Handled;
	} else {
		//If the client chose random team assignment, record that, so the autobalancer knows to be nice to them
		decl String:joinedteam[10];
		GetCmdArg(1, joinedteam, sizeof(joinedteam));
		if (!(strcmp(joinedteam, "0", false) && strcmp(joinedteam, "auto", false) && strcmp(joinedteam, "random", false)))
			client_autoassigned[client] = true;
		else
			client_autoassigned[client] = false;
		
		return Plugin_Continue;
	}
}















//Core functionality

stock TallyScrambleVote(client)
{
	new num_players = GetClientCount(true);
	new vote_threshold = RoundToFloor(num_players * votescramble_fraction);
	vote_threshold = (vote_threshold > 1) ? vote_threshold : 2;
	
	//Determine if we are currently accepting votes 
	if (num_players < min_players_for_votescramble) {
		PrintToChat(client, "%sScramble voting disabled: requires at least %d players.", plugin_prefix, min_players_for_votescramble);
		return;
	}
	if (!enable_votescramble) {
		PrintToChat(client, "%sScramble voting is currently not enabled.", plugin_prefix);
		return;
	}
	
	//Determine if this vote is valid
	//Also want to skip returning here if we somehow already have enough scramble votes (this can happen if, say, clients leave)
	if (scramble_votes[client] && num_scramble_votes < vote_threshold) {
		PrintToChat(client, "%sYou have already voted to scramble the teams.", plugin_prefix);
		return;
	}
	
	//Tally up the vote
	if ((++num_scramble_votes) >= vote_threshold) {
		//Enough votes to poll everyone, so do it
		ClearScrambleVotes();
		CallScrambleVote();
	} else {
		//Announce vote, and wait for enough to call a scramble
		scramble_votes[client] = true;
		PrintToChatAll("%s%N has called for a scramble vote. %d out of %d vote requests needed.", plugin_prefix, client, num_scramble_votes, vote_threshold);//TODO
	}
}


stock CallScrambleVote()
{
	if (IsVoteInProgress()) {
		CreateTimer(2.0, DelayedCallScrambleVote);
		return;
	}
	new Handle:scramble_vote_menu = CreateMenu(Handle_VoteMenu);
	SetVoteResultCallback(scramble_vote_menu, Handle_ScrambleVoteResults);
	SetMenuTitle(scramble_vote_menu, "Scramble teams now?");
	AddMenuItem(scramble_vote_menu, "Yes", "Yes");
	AddMenuItem(scramble_vote_menu, "No", "No");
	AddMenuItem(scramble_vote_menu, "Ignore", "Don't care");
	SetMenuExitButton(scramble_vote_menu, false);
	VoteMenuToAll(scramble_vote_menu, 15);
	return;
}

public Handle_ScrambleVoteResults(Handle:menu, num_votes, num_clients, const client_info[][2], num_items, const item_info[][2])
{
	new i, yes_votes, no_votes;
	
	//There is no real documentation on the item_info data structure, so try this semi-paranoid interpretation and pray for the best
	for(i = 0; i < num_items; i++) {
		switch(item_info[i][VOTEINFO_ITEM_INDEX]) {
		case 0:	//YES
			yes_votes = item_info[i][VOTEINFO_ITEM_VOTES];
		case 1:	//NO
			no_votes = item_info[i][VOTEINFO_ITEM_VOTES];
		}
	}
	if (yes_votes >= no_votes && yes_votes > 0) {
		PrintToChatAll("%sScramble vote succeeded (%d-%d).", plugin_prefix, yes_votes, no_votes);
		PrintToChatAll("%sTeams will scramble in %.0f seconds.", plugin_prefix, scramble_delay_time);
		CreateTimer(scramble_delay_time, DelayedScrambleTeams);
	} else {
		PrintToChatAll("%sScramble vote failed (%d-%d).", plugin_prefix, yes_votes, no_votes);
		//TODO: increase votescramble threshold
	}
}

public Handle_VoteMenu(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}

public Action:DelayedScrambleTeams(Handle:timer)
{
	ScrambleTeamsNow();
}

public Action:DelayedCallScrambleVote(Handle:timer)
{
	CallScrambleVote();
}











public Action:CheckBalance(Handle:timer)
{
	if (!autobalance_enabled)
		return Plugin_Continue;
	
	new bool:balanced = TeamsAreBalanced();
	
	if (!balanced && !autobalance_active && IsOKToStartAutobalance())
		AutobalanceStart();
	else if (autobalance_active && balanced)
		AutobalanceEnd();
	
	return Plugin_Continue;
}


stock bool:TeamsAreBalanced()
{
	new diff = GetTeamClientCount(TEAM_RED) - GetTeamClientCount(TEAM_BLUE);
	if ((diff > 1) || (diff < -1))
		return false;
	else
		return true;
}

public Action:TryForceBalanceTeams(Handle:timer)
{
	if (TeamsAreBalanced()) {
		return Plugin_Handled;
	} else {
		ForceBalanceTeamsNow();
		return Plugin_Handled;
	}
}


//Set up stuff to autobalance
stock AutobalanceStart()
{
	//Autobalance will move the first player to die after their time target to the other team
	//Time targets are individually chosen for each player based on:
	//	* Which team is winning: if a team is losing with more players, try to move low-scoring people
	//	* If a player is an Engineer with a building up, try not to move them
	//	* If a player is the only Medic on a team (or the other team has many more Medics), try not to move them
	//	* If a player chose their team intentionally, penalize them slightly (yay dickery)
	//	* If a player joined within the last few minutes, don't apply a score correction
	//	* If the team has lots of that class, try to get rid of that player
	//We must choose time targets for all players, since it is conceivable that balance could rapidly shift
	//	before the conclusion of an autobalance cycle, such that we need to be balancing in the other direction
	
	new red_class_count[10];
	new blu_class_count[10];
	new red_score=0, blu_score=0, red_players=0, blu_players=0;
	new i;
	new stronger_team;
	new Float:red_score_factor,Float:blu_score_factor;
	
	//Factor in player scores; most of this is either copied from or based on S. Gitnick's qautobalancer
	
	new Float:red_secs_played = 0.0;
	new Float:blu_secs_played = 0.0;
	new Float:map_time = GetGameTime();
	new Float:client_connected_time;
	new Float:connected_time[MAXPLAYERS+1];
	new Float:pps[MAXPLAYERS+1];
	new points;
	
	for(i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i))
			continue;
		
		client_connected_time = GetClientTime(i);
		if (client_connected_time > map_time)
			client_connected_time = map_time;
		connected_time[i] = client_connected_time;
		points = TF2_GetPlayerResourceData(i, TFResource_TotalScore);
		pps[i] = points/client_connected_time;
		
		switch(GetClientTeam(i)) {
		case TEAM_RED: {
			red_players++;
			red_class_count[TF2_GetPlayerClass(i)]++;
			red_score += points;
			red_secs_played += client_connected_time; }
		case TEAM_BLUE: {
			blu_players++;
			blu_class_count[TF2_GetPlayerClass(i)]++;
			blu_score += points;
			blu_secs_played += client_connected_time; }
		}
	}
	
	new Float:red_pps = red_score/red_secs_played;
	new Float:blu_pps = blu_score/blu_secs_played;
		
	//Decide which team is stronger
	//A better calculation would use the strength ratio to determine the score factors
	//It's probably easier to work out than this, but I can't be bothered to do that right now
	new Float:log_pps_ratio = CheapLog(red_pps / blu_pps);
	if (log_pps_ratio > 1.5) {	//RED has at least about 28% more points per second than BLU
		//RED is the stronger team
		stronger_team = TEAM_RED;
		if (red_players > blu_players) {
			//RED has more strength and more players: try to move stronger players to BLU
			red_score_factor =  1.0;
			blu_score_factor = -0.3;	//implies inversion of team size, so derate factor by half
		} else {
			//RED has more strength but fewer players: try to move weaker players to RED
			blu_score_factor = -0.6;
			red_score_factor =  0.5;	//implies inversion of team size, so derate factor by half
		}
	} else if (log_pps_ratio < -1.5) {	//BLU has at least about 28% more PPS than RED
		//BLU is the stronger team
		stronger_team = TEAM_BLUE;
		if (blu_players > red_players) {
			//BLU has more strength and more players: try to move stronger players to RED
			blu_score_factor =  1.0;
			red_score_factor = -0.3;	//implies inversion of team size, so derate factor by half
		} else {
			//BLU has more strength but fewer players: try to move weaker players to BLU
			red_score_factor = -0.6;
			blu_score_factor =  0.5;	//implies inversion of team size, so derate factor by half
		}
	} else {
		//No team is really dominant
		stronger_team = TEAM_SPECTATOR;
		red_score_factor = 0.0;
		blu_score_factor = 0.0;
	}
	
	//Okay, all the factors are set up; now calculate the target times
	new client_team;
	new Float:target_time;
	new Float:now = GetGameTime();
			
	for(i = 1; i <= MaxClients; i++) {
		if (!IsClientInGame(i) || IsFakeClient(i) || !IsValidTeam(i)) {
			autobalance_time_targets[i] = time_infinity;
			continue;
		}
		client_team = GetClientTeam(i);
		target_time = 5.0;	//base switch time
		
		//Score correction
		//Only apply if client has been connected for at least two minutes
		if (connected_time[i] >= 120.0) {
			//CheapLog(pps/team_pps) will range from -11 if the player has contributed nothing 
			//	to 16 if the player has 3x the PPS of the team as a whole, increasing from there
			//red_score_factor and blu_score_factor should have been chosen above to work appropriately with this range,
			//	giving a reduction of around 3 sec if the swap is desirable or increase of around 6 sec if undesirable
			//score_factor > 0 prefers stronger players for swap,
			//score_factor < 0 prefers weaker players for swap
			switch(client_team) {
			case TEAM_RED:
				target_time -= target_time*red_score_factor*CheapLog(pps[i]/red_pps);
			case TEAM_BLUE:
				target_time -= target_time*blu_score_factor*CheapLog(pps[i]/blu_pps);
			}
		}
		//After this target_time should be around 2 sec for a desirable swap or 10 sec for an undesirable one
		
		//Check their class, too
		new TFClassType:client_class = TF2_GetPlayerClass(i);
		new our_count, their_count;
		switch(client_team) {
			case TEAM_RED: {
				our_count = red_class_count[client_class];
				their_count = blu_class_count[client_class];
			}
			case TEAM_BLUE: {
				our_count = blu_class_count[client_class];
				their_count = red_class_count[client_class];
			}
		}
		switch(client_class) {
			case TFClass_Engineer: {
				if(ClientHasBuildings(i))
					target_time += 20.0;
			}
			case TFClass_Medic: {
				if ((our_count == 1) || ((their_count + 1) > our_count))
					target_time += 20.0;
			}
			case TFClass_Sniper: {
				if ((our_count > 2) && (client_team != stronger_team))
					target_time -= 5.0 * (our_count - 1);
			}
			default: {
				if ((our_count + 1) > their_count)
					target_time -= 5.0;
			}
		}
		
		//if a player has already been autobalanced this round, try not to swap them
		if (client_team_locks[i] > 0)
			target_time += 30.0;
		
		//if a player is immune to autobalance, try really hard not to swap them
		if (IsImmuneClient(i))
			target_time += 90.0;
			
		//if a player did not join their team randomly, punish them
		if (!client_autoassigned[i])
			target_time *= 0.6;
		
		target_time = (target_time >= autobalance_min_wait) ? target_time : autobalance_min_wait;
		
		autobalance_time_targets[i] = now + target_time;
	}
	
	//Register the on-death hook to do the dirty work
	HookEvent("player_death", TryAutobalanceDeadPlayer, EventHookMode_Post);
	autobalance_active = true;
	PrintToChatAll("%sTeams are currently imbalanced: arming the autobalancer!", plugin_prefix);
	
	//Ensure the teams get balanced eventually, no matter what
	if (autobalance_force_delay > 0.0)
		CreateTimer(autobalance_force_delay, TryForceBalanceTeams);
}



//When the autobalancer is done (or shut down early), call this
stock AutobalanceEnd()
{
	if (autobalance_active)
		UnhookEvent("player_death", TryAutobalanceDeadPlayer, EventHookMode_Post);
	autobalance_active = false;
}


public Action:TryAutobalanceDeadPlayer(Handle:event, const String:name[], bool:dontBroadcast)
{
	//First make sure teams are actually imbalanced
	//Not using the TeamsAreBalanced() function is a slight optimization here, 
	//	since we will need some of the same information if we have to balance 
	//	and I hate calling functions twice if I don't know how expensive they are
	//	(even if they look cheap)
	
	new diff = GetTeamClientCount(TEAM_RED) - GetTeamClientCount(TEAM_BLUE);
		
	if ((diff >= -1) && (diff <= 1)) {
		AutobalanceEnd();
		return;
	}
	
	new bigger_team = (diff > 0) ? TEAM_RED : TEAM_BLUE;
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	
	//Now see if this player should be balanced
	if ((GetClientTeam(client) == bigger_team) && (!IsFakeClient(client)) && (GetGameTime() >= autobalance_time_targets[client])) {
		AutobalanceClient(client, bigger_team ^ 0x01);	//lazy trick exploiting TEAM_RED = 0x02 and TEAM_BLUE = 0x03
		
		//If teams are now good, end autobalancing
		if (TeamsAreBalanced())
			AutobalanceEnd();
	}
}




stock AutobalanceClient(client, new_team)
{
	//Move the unlucky player
	ChangeClientTeam(client, new_team);
		
	//Let them know about their change in circumstances
	new Handle:autobalance_event = CreateEvent("teamplay_teambalanced_player");
	SetEventInt(autobalance_event, "player", client);
	SetEventInt(autobalance_event, "team", new_team);
	FireEvent(autobalance_event);
	
	PrintToChatAll("%s%N has been moved to %s to balance the teams.", plugin_prefix, client, (new_team == TEAM_RED ? "RED" : "BLU"));
	
	//And lock the poor bastard to their new team for autobalance_lock_time seconds
	//This should still be done even if team locking is not desired (autobalance_lock_time is 0), as
	//	it also records that player has been swapped in the past and we should try to swap someone else next time
	client_team_locks[client] = GetTime() + autobalance_lock_time;
	
	//Record this
	LogMessage("Moved %N to the other team.", client);
}



stock ForceBalanceTeamsNow()
{
/*	Force-balances teams, making sure they have the same player count.
	Procedure:
	1. Determine which team needs to lose players, and how many.
	2. Enumerate all players on that team who are not immune to autobalancing in a list.
	3. Shuffle that list.
	4. Move the first players in that list to the opposite team.
	5. Respawn the unlucky players.
	*/
	
	//The autobalancer won't have anything to do after we're done, so stop it
	AutobalanceEnd();
	
	decl valid_forcebalance_targets[MaxClients];
	new i, j, num_valid_targets, bigger_team, other_team, num_to_balance;
	new delta = GetTeamClientCount(TEAM_RED) - GetTeamClientCount(TEAM_BLUE);
	
	if (delta > 0) {
		//RED is the larger team
		bigger_team = TEAM_RED;
		other_team = TEAM_BLUE;
		num_to_balance = delta >> 1;
	} else {
		//BLU is the larger team
		bigger_team = TEAM_BLUE;
		other_team = TEAM_RED;
		num_to_balance = (-delta) >> 1;
	}
		
	if (num_to_balance > 0) {
		for(i = 1; i <= MaxClients; i++) {
			if(IsClientInGame(i) && (GetClientTeam(i) == bigger_team) && !IsImmuneClient(i))
				valid_forcebalance_targets[num_valid_targets++] = i;
		}
		
		//If we don't have enough valid targets, only balance as many players as we have targets
		num_to_balance = (num_valid_targets > num_to_balance) ? num_to_balance : num_valid_targets;
		if (num_to_balance > num_valid_targets) {
			decl String:balance_failed_message[256];
			Format(balance_failed_message, sizeof(balance_failed_message),
				"Unable to find enough valid targets to balance teams (have %d, need %d); manual action may be required.", 
				num_valid_targets, num_to_balance);
			NotifyAdmins(balance_failed_message);
			num_to_balance = num_valid_targets;
		}
			
		SortIntegers(valid_forcebalance_targets, num_valid_targets, Sort_Random);
			
		for(i = 0; i < num_to_balance; i++)
		{
			j = valid_forcebalance_targets[i];
			AutobalanceClient(j, other_team);
			TF2_RespawnPlayer(j);
		}
		LogMessage("Force-balanced teams.");
	} else {
		LogMessage("Force-balance: teams already balanced.");
	}
	
}

stock ScrambleTeamsNow()
{
/*  Scramble teams now.
	Procedure:
	1. Enumerate all valid clients in a list.
	2. Shuffle this list.
	3. Decide whether RED or BLU should get the first player (and a one-man advantage, for an odd number of players).
	4. Go through the list, alternately assigning players to RED and BLU. Swap them if necessary.
	5. Respawn everyone.
	*/
	
	//The autobalancer won't have anything to do after we're done, so stop it
	AutobalanceEnd();
	
	new i, j, num_players, current_team, player_team;
	decl valid_players[MaxClients];
	
	//TODO: Try to keep duelling players on their current teams
	
	for(i = 1; i <= MaxClients; i++) {
		if(IsClientInGame(i) && IsValidTeam(i))
			valid_players[num_players++] = i;
	}
	SortIntegers(valid_players, num_players, Sort_Random);
	
	//This and a few other lines below involving current_team exploit the binary 
	//	representation of TEAM_BLUE = 0x03 = 0b11 and TEAM_RED = 0x02 = 0b10
	current_team = (GetRandomInt(0, 1) & 0x01) | 0x02;
	
	for(i = 0; i < num_players; i++) {
		j = valid_players[i];
		player_team = GetClientTeam(j); 
		if(player_team != current_team)
			ChangeClientTeam(j, current_team);

		//Respawn everyone, not just those unlucky enough to be scrambled
		TF2_RespawnPlayer(j);
		
		//Put the next player on the other team
		current_team ^= 0x01;
	}
	
	//If we're in the setup round, reset the setup timer
	if (reset_setup_timer)
		TryResetSetupTimer();
	
	//If anyone has voted for a scramble, they got what they wanted -- clear votes
	ClearScrambleVotes();
	
	LogMessage("Randomized teams.");
	
	//Give the Announcer something to do, she *must* get bored constantly watching this carnage
	PlayScrambleSound();
}


stock StackTeamsNow()
{
	//TODO: write this
	//For now, admins can approximate its effect by manually moving Hungry or Termite to the other team
	return;
}

stock DoAdminPlayerSwap(admin, client)
{
	//Check validity of the provided player to swap
	if (!IsValidTeam(client) && CanUserTarget(admin, client)) {
		ReplyToCommand(admin, "Unable to swap %N.", client);
		return;
	}
	
	//Perform the swap
	new new_team = GetClientTeam(client) ^ 0x01;
	ChangeClientTeam(client, new_team);
	
	//Respawn the moved player
	TF2_RespawnPlayer(client);
	
	//Log it
	ShowActivity2(admin, plugin_prefix, "Swapped %N to %s.", client, (new_team == TEAM_RED ? "RED": "BLU"));
	LogMessage("%N: manually swapped %N to the other team.", admin, client);
	
	return;
}
















// Command callbacks

public Action:Command_ScrambleNow(client, argc)
{
	ShowActivity2(client, plugin_prefix, "Triggered a team scramble.");
	ScrambleTeamsNow();
	return Plugin_Handled;
}

public Action:Command_ForceBalance(client, argc)
{
	ShowActivity2(client, plugin_prefix, "Forcibly balanced the teams.");
	ForceBalanceTeamsNow();
	return Plugin_Handled;
}

public Action:Command_StackNow(client, argc)
{
	ShowActivity2(client, plugin_prefix, "Tried to stack the teams! For SHAME, abusive admin!");
	StackTeamsNow();
	return Plugin_Handled;
}

public Action:Command_CallScrambleVote(client, argc)
{
	ShowActivity2(client, plugin_prefix, "Called a vote to scramble teams.");
	
	//If anyone voted for a scramble, they got what they wanted, so clear votes
	ClearScrambleVotes();
	
	CallScrambleVote();
	return Plugin_Handled;
}

public Action:Command_ToggleAutobalance(client, argc)
{
	if (autobalance_enabled) {
		AutobalanceEnd();
		autobalance_enabled = false;
		ShowActivity2(client, plugin_prefix, "Disabled automatic balancing of teams.");
		LogMessage("%N disabled autobalancing.", client);
	} else {
		autobalance_enabled = true;
		ShowActivity2(client, plugin_prefix, "Enabled automatic balancing of teams.");
		LogMessage("%N enabled autobalancing.", client);
	}
	return Plugin_Handled;
}

public Action:Command_SwapPlayer(admin, argc)
{
	new String:target_player[64];
	new client;
	
	//If we got an argument (player to swap), make sure the issuing admin can target that player and try the swap
	//If an argument was not provided, pop up a menu to ask which player to swap
	if (argc >= 1 && GetCmdArg(1, target_player, sizeof(target_player))) {
		client = FindTarget(admin, target_player);
		if (client == -1) {
			ReplyToCommand(admin, "Unable to target '%s'.", target_player);
			return Plugin_Handled;
		}
		DoAdminPlayerSwap(admin, client);
	} else {
		new Handle:player_swap_menu = CreateMenu(Handle_PlayerSwapMenu);
		SetMenuTitle(player_swap_menu, "Choose a player to swap:");
		decl String:info[5];
		decl String:display[64];
		new i;
		for (i = 1; i <= MaxClients; i++) {
			if (!IsClientInGame(i) || IsFakeClient(i) || !IsValidTeam(i) || !CanUserTarget(admin, i))
				continue;
			Format(info, 5, "%d", i);
			Format(display, 64, "%N (%s)", i, (GetClientTeam(i) == TEAM_RED) ? "RED" : "BLU");
			AddMenuItem(player_swap_menu, info, display);
		}
		
		DisplayMenu(player_swap_menu, admin, MENU_TIME_FOREVER);
	}
	return Plugin_Handled;
}

//Callback for the menu that displays potential swap targets
public Handle_PlayerSwapMenu(Handle:menu, MenuAction:action, admin, menu_param)
{
	switch(action){
	case MenuAction_Select: {
		decl String:target_string[5];
		GetMenuItem(menu, menu_param, target_string, sizeof(target_string));
		DoAdminPlayerSwap(admin, StringToInt(target_string));
		}
	case MenuAction_Cancel: 
		if(menu_param == MenuCancel_ExitBack)
			RedisplayAdminMenu(admin_menu, admin);
	case MenuAction_End:
		CloseHandle(menu);
	}
}




















// Admin menu attachment and handling

public OnAdminMenuReady(Handle:top_menu)
{
	// Block this from being called twice, and make sure we're supposed to attach to the menu
	if (top_menu == admin_menu || !attach_to_admin_menu) 
		return;
	
	admin_menu = top_menu;
 
	NB_menu_category = AddToTopMenu(admin_menu, "Team Balance Commands", TopMenuObject_Category, NB_MH_Category, INVALID_TOPMENUOBJECT);
	AddToTopMenu(admin_menu, "Scramble teams now",	TopMenuObject_Item, 	NB_MH_ScrambleNow,	NB_menu_category, "sm_scramblenow", 	ADMFLAG_GENERIC);
	AddToTopMenu(admin_menu, "Call scramble vote",	TopMenuObject_Item, 	NB_MH_CallVoteNow,	NB_menu_category, "sm_scramblevote", 	ADMFLAG_GENERIC);
	AddToTopMenu(admin_menu, "Force-balance teams",	TopMenuObject_Item, 	NB_MH_ForceBalance,	NB_menu_category, "sm_forcebalance", 	ADMFLAG_GENERIC);
	AddToTopMenu(admin_menu, "Swap player team",	TopMenuObject_Item, 	NB_MH_SwapPlayer,	NB_menu_category, "sm_swapplayer", 	ADMFLAG_GENERIC);
	AddToTopMenu(admin_menu, "Toggle autobalancer",	TopMenuObject_Item, 	NB_MH_ToggleAuto, 	NB_menu_category, "sm_toggleautobalance", 	ADMFLAG_GENERIC);
	AddToTopMenu(admin_menu, "Stack teams now",	TopMenuObject_Item, 	NB_MH_StackNow, 	NB_menu_category, "sm_stackteams", 	ADMFLAG_GENERIC);
}

public NB_MH_Category(Handle:top_menu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
	switch(action) {
	case TopMenuAction_DisplayTitle:
		Format(buffer, maxlength, "Team Balance Commands:");
	case TopMenuAction_DisplayOption:
		Format(buffer, maxlength, "Team Balance Commands");
	}
}

public NB_MH_ScrambleNow(Handle:top_menu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
	switch(action) {
	case TopMenuAction_DisplayOption:
		Format(buffer, maxlength, "Scramble teams now");
	case TopMenuAction_SelectOption:
		Command_ScrambleNow(client, 0);
	}
}
public NB_MH_CallVoteNow(Handle:top_menu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
	switch(action) {
	case TopMenuAction_DisplayOption:
		Format(buffer, maxlength, "Call scramble vote");
	case TopMenuAction_SelectOption:
		Command_CallScrambleVote(client, 0);
	}
}
public NB_MH_ForceBalance(Handle:top_menu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
	switch(action) {
	case TopMenuAction_DisplayOption:
		Format(buffer, maxlength, "Force-balance teams");
	case TopMenuAction_SelectOption:
		Command_ForceBalance(client, 0);
	}
}
public NB_MH_SwapPlayer(Handle:top_menu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
	switch(action) {
	case TopMenuAction_DisplayOption:
		Format(buffer, maxlength, "Swap player team");
	case TopMenuAction_SelectOption:
		Command_SwapPlayer(client, 0);
	}
}
public NB_MH_ToggleAuto(Handle:top_menu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
	switch(action) {
	case TopMenuAction_DisplayOption:
		switch(autobalance_enabled) {
		case true:
			Format(buffer, maxlength, "Disable autobalancer");
		case false:
			Format(buffer, maxlength, "Enable autobalancer");
		default:
			Format(buffer, maxlength, "Toggle autobalancer");
		}
	case TopMenuAction_SelectOption:
		Command_ToggleAutobalance(client, 0);
	}
}
public NB_MH_StackNow(Handle:top_menu, TopMenuAction:action, TopMenuObject:object_id, client, String:buffer[], maxlength) {
	switch(action) {
	case TopMenuAction_DisplayOption:
		Format(buffer, maxlength, "Stack teams now (not implemented)");
	case TopMenuAction_SelectOption:
		Command_StackNow(client, 0);
	}
}










//Utility functions

stock bool:IsValidTeam(client)
{
	new team = GetClientTeam(client);
	//if (team == TEAM_RED || team == TEAM_BLUE)
	if (!((team >> 1) ^ 0x01))
		return true;
	return false;
}

stock TryResetSetupTimer()
{
	new round_timer = FindEntityByClassname(-1, "team_round_timer");

	//See if this is a timed round; if not, we can't be in setup
	if (round_timer != -1) {
		new timer_state = GetEntProp(round_timer, Prop_Send, "m_nState");
		//RT_STATE_SETUP = 0 defines the setup phase of the timer
		if (timer_state == 0) {
			//We're in the setup round. Reset the round timer:
			new setup_round_length = GetEntProp(round_timer, Prop_Send, "m_nSetupTimeLength");
			SetVariantInt(setup_round_length);
			AcceptEntityInput(round_timer, "SetTime");
			
			//We know we're definitely in the setup phase
			//(checking if game_state==setup is not used instead of the ugly timer check as it's not 100% accurate)
			game_state = setup;
		}
	}
}

stock NotifyAdmins(String:message[])
{
	for (new i = 1; i <= MaxClients; i++) {
		if (IsClientInGame(i) && (CheckCommandAccess(i, "sm_scramblenow", ADMFLAG_GENERIC)))
			PrintToChat(i, "%s%s", plugin_prefix, message);
	}
}


stock ClearScrambleVotes()
{
	//Reset votescramble tallying
	new i;
	num_scramble_votes = 0;
	for(i = 1; i <= MaxClients; i++)
		scramble_votes[i] = false;
}

stock ClearTeamLocks()
{
	new i;
	for(i = 1; i <= MaxClients; i++)
		client_team_locks[i] = 0;
}

//Determine if a client is immune to the autobalancer
stock bool:IsImmuneClient(client)
{		
	if (IsFakeClient(client))
		return false;
		
	new client_privs = GetUserFlagBits(client);
	
	if (client_privs & immune_privs)
		return true;
	
	//Uncomment this block to enable duel immunity
	//Requires SourceMod newer than 1.3.6 (built on or after mid-November 2010)
	/*//Players in duels are immune
	if (duel_immunity && TF2_IsPlayerInDuel(i))
		return true;*/
	
	return false;
}

//Check if a client has any active engineer buildings
stock bool:ClientHasBuildings(client)
{
	new iEnt = -1;
	while ((iEnt = FindEntityByClassname(iEnt, "obj_*")) != -1) {
		if (GetEntDataEnt2(iEnt, engineer_building) == client)
			return true;
	}
	return false;
}

//Check if we can start autobalancing now or we should wait
stock bool:IsOKToStartAutobalance()
{
	//logic here with is_maybe_OK is a little convoluted, because the compiler whines 
	//	if I leave parts of the switch empty
	//	(even if I just want to head to the bottom of it)
	//	and it whines if I don't use the variable...
	//so I have to do something semi-useful
	
	new bool:is_maybe_OK = false;
	
	switch(game_state) {
	case setup:
		is_maybe_OK = true;	//continue
	case normal:
		is_maybe_OK = true;	//continue
	default:
		return false;
	}
	
	if (round_is_timed && (GetGameTime() > (round_end_time - autobalance_min_round_time_left)) && is_maybe_OK)
		return false;
	
	return true;
}

stock PlayScrambleSound()
{
	new i = GetRandomInt(1, 3);
	switch(i) {
	case 1:
		EmitSoundToAll("vo/announcer_am_teamscramble01.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	case 2:
		EmitSoundToAll("vo/announcer_am_teamscramble02.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	case 3:
		EmitSoundToAll("vo/announcer_am_teamscramble03.wav", SOUND_FROM_PLAYER, SNDCHAN_AUTO, SNDLEVEL_NORMAL);
	}
}













//Dealing with the round timer (PAINFUL!)
stock GetRoundTimerInformation()
{
	new round_timer = -1;
	new Float:best_end_time = time_infinity;
	new Float:timer_end_time;
	new bool:found_valid_timer = false;
	new bool:timer_is_disabled = true;
	new bool:timer_is_paused = true;

	while ( (round_timer = FindEntityByClassname(round_timer, "team_round_timer")) != -1) {
		//Make sure this timer is enabled
		timer_is_paused = bool:GetEntProp(round_timer, Prop_Send, "m_bTimerPaused");
		timer_is_disabled = bool:GetEntProp(round_timer, Prop_Send, "m_bIsDisabled");
		
		//End time is what we're interested in... fortunately, it works
		// (getting the current time remaining does NOT work as of late November 2010)
		timer_end_time = GetEntPropFloat(round_timer, Prop_Send, "m_flTimerEndTime");
		/*PrintToChatAll("Round timer: endtime=%.1f (end in %.1f s), paused=%d, disabled=%d",
			thisEndTime,
			thisEndTime - GetGameTime(), 
			timer_is_paused, 
			timer_is_disabled);*/
		
		if (!timer_is_paused && !timer_is_disabled && (timer_end_time <= best_end_time || !found_valid_timer)) {
			best_end_time = timer_end_time;
			found_valid_timer = true;
		}
	}

	if (found_valid_timer) {
		round_end_time = best_end_time;
		round_is_timed = true;
		/*new Float:currentTime = GetGameTime();
		PrintToChatAll("this round IS timed, current=%f, remaining=%f, end=%f", currentTime, bestEndTime - currentTime, bestEndTime);*/
	} else {
		/*PrintToChatAll("this round is NOT timed");*/
		round_is_timed = false;
		
		//if we thought we were in setup, we can't be; setup is timed
		//we must have moved on to the game proper:
		if (game_state == setup)
			game_state = normal;
	}
}

public hook_timer_time_added(Handle:event, const String:name[], bool:dontBroadcast)
{
	GetRoundTimerInformation();
}

public Action:CheckRoundTimer(Handle:timer)
{
	GetRoundTimerInformation();
	return Plugin_Continue;
}





//Hooks to tell us when the game state changes
public hook_game_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	game_state = waiting_for_players;
}

public hook_round_start(Handle:event, const String:name[], bool:dontBroadcast)
{
	switch(game_state) {
	case map_loaded:
		game_state = waiting_for_players;
	case waiting_for_players:
		game_state = setup;
	}
	
	GetRoundTimerInformation();
}

public hook_setup_finished(Handle:event, const String:name[], bool:dontBroadcast)
{
	game_state = normal;
	
	GetRoundTimerInformation();
	/*//Recheck things just before we're due to turn off autobalance
	CreateTimer(round_end_time - 1.0 - autobalance_min_round_time_left, CheckRoundTimer);*/
}

public hook_round_win(Handle:event, const String:name[], bool:dontBroadcast)
{	
	game_state = humiliation;	
}

public hook_round_stalemate(Handle:event, const String:name[], bool:dontBroadcast)
{
	game_state = sudden_death;
}

public hook_game_over(Handle:event, const String:name[], bool:dontBroadcast)
{
	game_state = map_ending;
}














//Real utility functions

stock Float:CheapLog(Float:x)
{
	//A cheap and cheerful approximation to 6*ln x
	return (((2*x - 9)*x) + 18)*x - 11;
}

stock BoolToChar(bool:b)
{
	if (b)
		return 'T';
	else
		return 'F';
}


//Debug dump command
public Action:Command_DumpDebugInformation(client, argc)
{
	//report on the current status of the autobalancer
	if (autobalance_enabled) {
		if (autobalance_active)
			ReplyToCommand(client, "The autobalancer is currently enabled and active.");
		else 
			ReplyToCommand(client, "The autobalancer is currently enabled and inactive.");
	} else {
		ReplyToCommand(client, "The autobalancer is currently disabled.");
	}
	
	switch(game_state) {
		case map_loaded:
			ReplyToCommand(client, "The current game state is MAP_LOADED.");
		case waiting_for_players:
			ReplyToCommand(client, "The current game state is WAITING_FOR_PLAYERS.");
		case humiliation:
			ReplyToCommand(client, "The current game state is HUMILIATION.");
		case sudden_death:
			ReplyToCommand(client, "The current game state is SUDDEN_DEATH.");
		case map_ending:
			ReplyToCommand(client, "The current game state is MAP_ENDING.");
		case setup:
			ReplyToCommand(client, "The current game state is SETUP.");
		case normal:
			ReplyToCommand(client, "The current game state is NORMAL.");
	}
	
	new Float:current_time = GetGameTime();
	ReplyToCommand(client, "The current game time is %f.", current_time);
	if (round_is_timed)
		ReplyToCommand(client, "This round is timed, due to end at %.1f (in %.1f s). Autobalance disabled after %.1f (OK = %c).", round_end_time, round_end_time - current_time, round_end_time - autobalance_min_round_time_left, BoolToChar(IsOKToStartAutobalance()));
	else 
		ReplyToCommand(client, "This round is not timed.");
	
	if (enable_votescramble) {
		new num_players = GetClientCount(true);
		if (num_players >= min_players_for_votescramble)
			ReplyToCommand(client, "Scramble voting is currently enabled. Have %d votes, require %d of %d to call a scramble vote.", num_scramble_votes, RoundToFloor(num_players * votescramble_fraction), num_players);
		else
			ReplyToCommand(client, "Scramble voting is currently enabled, but inactive: only %d players of the %d required.", num_players, min_players_for_votescramble);
	} else {
		ReplyToCommand(client, "Scramble voting is currently disabled.");
	}

	ReplyToCommand(client, "Client status:");
	new i;
	if (autobalance_active) {
		for(i = 1; i <= MaxClients; i++) {
			ReplyToCommand(client, "Client=%d [%L], Team=%d, Immune=%c, AutoAssigned=%c, YouCanSwap=%c, ScrambleVote=%c, TeamLock=%d, Target=%.1f", 
			i, i, GetClientTeam(i), BoolToChar(IsImmuneClient(i)), BoolToChar(client_autoassigned[i]), BoolToChar(CanUserTarget(client,i)), BoolToChar(scramble_votes[i]), client_team_locks[i], autobalance_time_targets[i]);
		}
	} else {
		for(i = 1; i <= MaxClients; i++) {
			ReplyToCommand(client, "Client=%d [%L], Team=%d, Immune=%c, AutoAssigned=%c, YouCanSwap=%c, ScrambleVote=%c, TeamLock=%d", 
			i, i, GetClientTeam(i), BoolToChar(IsImmuneClient(i)), BoolToChar(client_autoassigned[i]), BoolToChar(CanUserTarget(client,i)), BoolToChar(scramble_votes[i]), client_team_locks[i]);
		}
	}
	ReplyToCommand(client, "Current time for: Locks=%d, Balance_Targets=%.1f.", GetTime(), GetGameTime());
	
	return Plugin_Handled;
}
