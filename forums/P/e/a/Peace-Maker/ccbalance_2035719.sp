#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <smlib>

#define NUM_TEAMS 4
#define PLUGIN_VERSION "1.1.1"

/* 
########################################################################
## config variables (global for now)
## These are the variables that you, the user, can configure. 
## The defaults behave very well, so unless you are trying to address
## a specific issue, it is recommended that these settings be left
## as-is.
##
## Thanks for trying the cC Team Balancer!
########################################################################
# set run_frequency to the frequency, in rounds, that you want the autobalancer
# to run.  The overall idea of this balancer is to be nonintrusive, so we 
# recommend run frequencies of somewhere between 3 and 5.
*/

#define RUN_FREQUENCY "4"

/*
# The wait_until_dead flag determines whether or not live players are swapped.  If
# you are running mani admin, it is perfectly safe and desirable to swap live players;
# they will not be slain and will be seamlessly be moved to the other team.
# if you are not running mani, however, the player will be killed (if they are 
# alive) to be moved to the other team, in which case the recommended setting
# is True.
# recommended to be set to False if you do have mani admin.
# recommended to be set to True if you do not have mani admin.
*/

#define WAIT_UNTIL_DEAD "0"

/*
# the balancer will do nothing until the min_player_count is reached.
*/
#define MIN_PLAYER_COUNT "6"

/*
# At balance time, if team strengths are already balanced to within this percent, 
# then no one is moved or swapped.  Recommended: 10.0
*/
#define ACCEPTABLE_STRENGTH_IMBALANCE "10.0"

/*
# At any round, if the team COUNTS are imbalanced by this percentage, a balancing
# is forced.  For example, if it is 7 vs. 5, that imbalance is 5/7*100 = 71%, which
# will cause a rebalancing to occur.  The default value is 84 percent, which forces
# a rebalance on a 24-player server if ever one team has 2 more than another.
*/
#define TEAM_IMBALANCE_PERCENTAGE_TRIGGER "84.0"

/*
# At any round, if the team STRENGTHS are imbalanced by this percentage, a balancing
# is forced.  Recommended: 60.0 percent (which means that one team is nearly twice
# as strong as the other)
*/
#define TEAM_STRENGTH_PERCENTAGE_TRIGGER "60.0"

/*
# A player gets immunity from swapping once they are swapped, and they keep that
# immunity for the rest of the map.  However, for maps that stay on for a very long
# time, the player loses this immunity, and may be swapped again, after
# cfg['lose_immunity_after'] rounds.  Recommended: 30.
*/
#define LOSE_IMMUNITY_AFTER "30"

/*
# This parameter determines how long a player is immune from swapping after just
# having joined.  This is to prevent player swaps as soon as they join.  
# Recommended: 3
*/
#define IMMUNE_FOR "3"

/*
# This parameter sets the maximum number of player swaps that are considered; on
# large servers, the amount of computation can get quite large, so we limit
# it with this parameter.  If the balancer is taking too long at end of round,
# turn this number down.
*/
#define MAX_SWAPS_CONSIDERED "100"

/*
# the verbosity can be set to 0 to 3, where 3 is a high level of printouts to
# console, and 0 completely silences the balancer.
*/
#define VERBOSE "3"

/*
# these are factors that are probably better left alone.  Basically, the idea is
# that a player's killrate will probably be better if switched to a stronger team,
# and worse if switched to a weaker team.  These factors determine how much better
# or worse the killrate will be.
#better_factor = 1.5 # originally proposed by sparty
#worse_factor = 0.85 # originally proposed by sparty
*/
#define BETTER_FACTOR "1.1"
#define WORSE_FACTOR "0.9"


/*
# how to inform a player that he/she has been swapped.  
# 0 - no notification
# 1 - notification with a colored overlay at spawn
# 2 - notification with a colored overlay at spawn, and a brief sound.
# 3 - notification with a colored overlay at spawn, sound, and a centered message.
*/
#define NOTIFY_TEAM_CHANGE "3"
// ########################################################################

enum ConVars {
	Handle:CV_run_frequency,
	Handle:CV_wait_until_dead,
	Handle:CV_min_player_count,
	Handle:CV_acceptable_strength_imbalance,
	Handle:CV_team_imbalance_percentage_trigger,
	Handle:CV_team_strength_percentage_trigger,
	Handle:CV_lose_immunity_after,
	Handle:CV_immune_for,
	Handle:CV_max_swaps_considered,
	Handle:CV_verbose,
	Handle:CV_better_factor,
	Handle:CV_worse_factor,
	Handle:CV_notify_team_change
}

enum Player {
	PL_userid,
	String:PL_name[MAX_NAME_LENGTH],
	String:PL_steamid[MAX_STEAMAUTH_LENGTH],
	PL_deaths,
	PL_kills,
	PL_rounds,
	PL_rounds_since_swap,
	PL_overall_deaths,
	PL_overall_kills,
	PL_overall_rounds,
	Float:PL_killrate,
	PL_rank,
	PL_team,
	PL_connected,
	PL_immune,
	bool:PL_init_done,
	PL_dead,
	bool:PL_changing_team
};

enum Merit {
	M_userid_t,
	M_userid_ct,
	M_desirability,
	Float:M_align,
	Float:M_score,
	Float:M_adjusted_score
}

/*
########################################################################
## global variables
########################################################################
*/

new g_iGlobalRounds;
new g_iBalancedOnRound = -1;
new bool:g_bMidGameLoad;
new g_iKillsTotal[NUM_TEAMS];
new g_iDeathsTotal[NUM_TEAMS];
new Handle:g_hPlayers;
new Handle:g_hPlayersUserIds;
new Handle:g_hDisconnectedPlayersUserIds;
new g_iRoundsInactive;

new Handle:g_hDatabase;
new cv[ConVars];
new Handle:g_hSetModelFromClass;

public Plugin:myinfo = 
{
	name = "cC Team Balancer",
	author = "*XYZ*SaYnt, ported to SM by Peace-Maker",
	description = "Team balancing solution for CSS",
	version = PLUGIN_VERSION,
	url = "http://addons.eventscripts.com/addons/view/ccbalance"
}

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:error[], err_max)
{
	g_bMidGameLoad = late;
	MarkNativeAsOptional("CS_UpdateClientModel");
}

public OnPluginStart()
{
	cv[CV_run_frequency] = CreateConVar("ccb_run_frequency", RUN_FREQUENCY);
	cv[CV_wait_until_dead] = CreateConVar("ccb_wait_until_dead", WAIT_UNTIL_DEAD);
	cv[CV_min_player_count] = CreateConVar("ccb_min_player_count", MIN_PLAYER_COUNT);
	cv[CV_acceptable_strength_imbalance] = CreateConVar("ccb_acceptable_strength_imbalance", ACCEPTABLE_STRENGTH_IMBALANCE);
	cv[CV_team_imbalance_percentage_trigger] = CreateConVar("ccb_team_imbalance_percentage_trigger", TEAM_IMBALANCE_PERCENTAGE_TRIGGER);
	cv[CV_team_strength_percentage_trigger] = CreateConVar("ccb_team_strength_percentage_trigger", TEAM_STRENGTH_PERCENTAGE_TRIGGER);
	cv[CV_lose_immunity_after] = CreateConVar("ccb_lose_immunity_after", LOSE_IMMUNITY_AFTER);
	cv[CV_immune_for] = CreateConVar("ccb_immune_for", IMMUNE_FOR);
	cv[CV_max_swaps_considered] = CreateConVar("ccb_max_swaps_considered", MAX_SWAPS_CONSIDERED);
	cv[CV_verbose] = CreateConVar("ccb_verbose", VERBOSE);
	cv[CV_better_factor] = CreateConVar("ccb_better_factor", BETTER_FACTOR);
	cv[CV_worse_factor] = CreateConVar("ccb_worse_factor", WORSE_FACTOR);
	cv[CV_notify_team_change] = CreateConVar("ccb_notify_team_change", NOTIFY_TEAM_CHANGE);
	g_iRoundsInactive = GetConVarInt(cv[CV_run_frequency]) - 1;
	
	AutoExecConfig(true, "ccbalance");
	
	// initialize the database that we will use for persistent storage. 
	decl String:sError[128];
	g_hDatabase = SQLite_UseDatabase("ccbalance", sError, sizeof(sError));
	if(g_hDatabase == INVALID_HANDLE)
	{
		LogError("Unable to open sqlite database ccbalance. %s", sError);
	}
	else
	{
		new String:sQuery[] = "CREATE TABLE IF NOT EXISTS killrate (steamid TEXT,name TEXT DEFAULT 'unnamed',overall_kills TEXT DEFAULT '0',overall_deaths TEXT DEFAULT '0',overall_rounds TEXT DEFAULT '0')";
		if(!SQL_FastQuery(g_hDatabase, sQuery))
		{
			SQL_GetError(g_hDatabase, sError, sizeof(sError));
			LogError("Error creating killrate table. %s", sError);
			CloseHandle(g_hDatabase);
			g_hDatabase = INVALID_HANDLE;
		}
	}
	
	RegConsoleCmd("ccbstats", Cmd_ShowStats, "Shows team balance merit information");
	
	g_hPlayers = CreateTrie();
	
	// KTries are not iterable :(
	// Create arrays with userids in trie..
	g_hPlayersUserIds = CreateArray();
	g_hDisconnectedPlayersUserIds = CreateArray();
	
	HookEvent("round_start", Event_OnRoundStart);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_spawn", Event_OnPlayerSpawn);
	//HookEvent("player_connect", Event_OnPlayerConnect);
	HookEvent("player_activate", Event_OnPlayerActivate);
	HookEvent("player_changename", Event_OnPlayerChangeName);
	HookEvent("player_disconnect", Event_OnPlayerDisconnect);
	HookEvent("player_death", Event_OnPlayerDeath);
	
	if(g_bMidGameLoad)
		InGameInit();
	
	new Handle:hVersion = CreateConVar("ccb_version", PLUGIN_VERSION, "cC Balancer version", FCVAR_NOTIFY|FCVAR_DONTRECORD);
	SetConVarString(hVersion, PLUGIN_VERSION);
	
	if(GetFeatureStatus(FeatureType_Native, "CS_UpdateClientModel") != FeatureStatus_Available)
	{
		new Handle:hGameConfig = LoadGameConfigFile("ccbalance.games");
		if(hGameConfig == INVALID_HANDLE)
		{
			LogError("ccbalance.games.txt gamedata file not found. Players won't have the right model when switching while alive.");
			return;
		}
		
		StartPrepSDKCall(SDKCall_Player);
		PrepSDKCall_SetFromConf(hGameConfig, SDKConf_Signature, "SetModelFromClass");
		g_hSetModelFromClass = EndPrepSDKCall();
		if(g_hSetModelFromClass == INVALID_HANDLE)
			LogError("Couldn't find CCSPlayer::SetModelFromClass signature. Players won't have the right model when switching while alive.");
	}
}

public OnPluginEnd()
{
	FlushDatabase();
}

public OnConfigsExecuted()
{
	g_iRoundsInactive = GetConVarInt(cv[CV_run_frequency]) - 1;
}

stock Player_Dump(player[Player])
{
	LogMessage("Player %d: %s [%s]", player[PL_userid], player[PL_name], player[PL_steamid]);
	LogMessage("         : deaths=%d kills=%d rounds=%d killrate=%f", player[PL_deaths], player[PL_kills], player[PL_rounds], player[PL_killrate]);
	LogMessage("         : team=%d connected=%d immune=%s init_done=%s", player[PL_team], player[PL_connected], player[PL_immune], player[PL_init_done]);
}

Player_SetKillrate(player[Player], bool:from_overall)
{
	new k, r;
	if(player[PL_rounds] <= g_iRoundsInactive || from_overall)
	{
		k = player[PL_overall_kills];
		r = player[PL_overall_rounds];
	}
	else {
		k = player[PL_kills];
		r = player[PL_rounds];
	}
	if(r == 0)
		player[PL_killrate] = 0.75;
	else
		player[PL_killrate] = float(k)/float(r);
}

Player_AddRounds(player[Player], n)
{
	player[PL_rounds] += n;
	player[PL_overall_rounds] += n;
	player[PL_rounds_since_swap] += n;
}

Player_AddKill(player[Player])
{
	player[PL_kills] += 1;
	player[PL_overall_kills] += 1;
	g_iKillsTotal[player[PL_team]] += 1;
	// Player_SetKillrate(player, false);
}

Player_AddDeath(player[Player])
{
	player[PL_deaths] += 1;
	player[PL_overall_deaths] += 1;
	g_iDeathsTotal[player[PL_team]] += 1;
}

Player_UpdateDatabase(player[Player])
{
	if(!g_hDatabase)
		return;
	
	if(StrContains(player[PL_steamid], "PENDING BOT") != -1)
		return;
	
	// write player information into the database for cold storage
	decl String:sQuery[128];
	Format(sQuery, sizeof(sQuery), "SELECT steamid FROM killrate WHERE steamid='%s'", player[PL_steamid]);
	
	new Handle:hPack = CreateDataPack();
	WritePackString(hPack, player[PL_steamid]);
	WritePackString(hPack, player[PL_name]);
	WritePackCell(hPack, player[PL_overall_deaths]);
	WritePackCell(hPack, player[PL_overall_kills]);
	WritePackCell(hPack, player[PL_overall_rounds]);
	SQL_TQuery(g_hDatabase, SQL_CheckInsertPlayerKillrate, sQuery, hPack, DBPrio_High);
}

public SQL_CheckInsertPlayerKillrate(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		CloseHandle(data);
		LogError("Error checking for player existance in killrate table: %s", error);
		return;
	}
	
	// New player
	if(SQL_GetRowCount(hndl) == 0)
	{
		decl String:sQuery[128], String:sAuthId[MAX_STEAMAUTH_LENGTH];
		ResetPack(data);
		ReadPackString(data, sAuthId, sizeof(sAuthId));
		
		Format(sQuery, sizeof(sQuery), "INSERT INTO killrate (steamid) VALUES ('%s')", sAuthId);
		SQL_TQuery(g_hDatabase, SQL_HandleInsertPlayerKillrate, sQuery, data, DBPrio_High);
		return;
	}
	
	InsertPlayerKillrateToDatabase(data);
}

public SQL_HandleInsertPlayerKillrate(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		CloseHandle(data);
		LogError("Error inserting player into killrate table: %s", error);
		return;
	}
	
	InsertPlayerKillrateToDatabase(data);
}

InsertPlayerKillrateToDatabase(Handle:pack)
{
	ResetPack(pack);
	decl String:sName[MAX_NAME_LENGTH], String:sAuthId[MAX_STEAMAUTH_LENGTH];
	ReadPackString(pack, sAuthId, sizeof(sAuthId));
	ReadPackString(pack, sName, sizeof(sName));
	new iOverallDeaths = ReadPackCell(pack);
	new iOverallKills = ReadPackCell(pack);
	new iOverallRounds = ReadPackCell(pack);
	CloseHandle(pack);
	
	decl String:sQuery[512], String:sEscName[MAX_NAME_LENGTH*2+1];
	SQL_EscapeString(g_hDatabase, sName, sEscName, sizeof(sEscName));
	Format(sQuery, sizeof(sQuery), "UPDATE killrate SET name = ('%s') WHERE steamid='%s'", sEscName, sAuthId);
	SQL_TQuery(g_hDatabase, SQL_DoNothing, sQuery);
	Format(sQuery, sizeof(sQuery), "UPDATE killrate SET overall_deaths = ('%d') WHERE steamid='%s'", iOverallDeaths, sAuthId);
	SQL_TQuery(g_hDatabase, SQL_DoNothing, sQuery);
	Format(sQuery, sizeof(sQuery), "UPDATE killrate SET overall_kills = ('%d') WHERE steamid='%s'", iOverallKills, sAuthId);
	SQL_TQuery(g_hDatabase, SQL_DoNothing, sQuery);
	Format(sQuery, sizeof(sQuery), "UPDATE killrate SET overall_rounds = ('%d') WHERE steamid='%s'", iOverallRounds, sAuthId);
	SQL_TQuery(g_hDatabase, SQL_DoNothing, sQuery);
}

public SQL_DoNothing(Handle:owner, Handle:hndl, String:error[], any:data)
{
	if(hndl == INVALID_HANDLE)
	{
		LogError("Error executing query: %s", error);
		return;
	}
}

bool:Player_GetByUserId(iUserId, player[Player])
{
	decl String:sUserId[16];
	IntToString(iUserId, sUserId, sizeof(sUserId));
	return GetTrieArray(g_hPlayers, sUserId, player[0], _:Player);
}

Player_Save(player[Player], bool:bDisconnected)
{
	decl String:sUserId[16];
	IntToString(player[PL_userid], sUserId, sizeof(sUserId));
	SetTrieArray(g_hPlayers, sUserId, player[0], _:Player, true);
	
	// Remember that userid.
	if(!bDisconnected)
	{
		if(FindValueInArray(g_hPlayersUserIds, player[PL_userid]) == -1)
			PushArrayCell(g_hPlayersUserIds, player[PL_userid]);
	}
	else
	{
		if(FindValueInArray(g_hDisconnectedPlayersUserIds, player[PL_userid]) == -1)
			PushArrayCell(g_hDisconnectedPlayersUserIds, player[PL_userid]);
	}
}

Player_Delete(iUserId, bool:bDelete)
{
	new player[Player];
	Player_GetByUserId(iUserId, player);
	player[PL_connected] = 0;
	Player_Save(player, false);
	Player_Save(player, true);
	LogMessage("%s removed from balancer.", player[PL_name]);
	if(bDelete)
	{
		//decl String:sUserId[16];
		//IntToString(iUserId, sUserId, sizeof(sUserId));
		//RemoveFromTrie(g_hPlayers, sUserId);
		new iIndex = FindValueInArray(g_hPlayersUserIds, player[PL_userid]);
		if(iIndex != -1)
			RemoveFromArray(g_hPlayersUserIds, iIndex);
	}
}

InGameInit()
{
	// initialize the team balancer when the script is loaded mid-game
	for(new i=0;i<NUM_TEAMS;i++)
	{
		g_iKillsTotal[i] = 0;
		g_iDeathsTotal[i] = 0;
	}
	
	new iKills, iDeaths;
	for(new i=1;i<=MaxClients;i++)
	{
		if(!IsClientInGame(i) || (!IsClientAuthorized(i) && !IsFakeClient(i)))
			continue;
		
		new player[Player];
		player[PL_userid] = GetClientUserId(i);
		player[PL_team] = GetClientTeam(i);
		if(!GetClientAuthString(i, player[PL_steamid], MAX_STEAMAUTH_LENGTH))
			strcopy(player[PL_steamid], MAX_STEAMAUTH_LENGTH, "BOT");
		GetClientName(i, player[PL_name], MAX_NAME_LENGTH);
		player[PL_connected] = 1;
		Player_Save(player, false);
		
		InitKillrate(player[PL_userid], player[PL_steamid]);
		
		iKills = GetClientFrags(i);
		iDeaths = GetClientDeaths(i);
		
		if(player[PL_team] != 0)
		{
			g_iKillsTotal[player[PL_team]] += iKills;
			g_iDeathsTotal[player[PL_team]] += iDeaths;
		}
	}
	
	LogMessage("ingameinit:  T kill/death total is now %d %d", g_iKillsTotal[2], g_iDeathsTotal[2]);
	LogMessage("ingameinit: CT kill/death total is now %d %d", g_iKillsTotal[3], g_iDeathsTotal[3]);
	
	SetRank();
}

public OnMapStart()
{
	// EVENT: executes whenever the map starts.
	// Reset all of the counters and flags that we need to.
	
	PrecacheSound("common/warning.wav", true);
	
	g_iBalancedOnRound = -1;
	
	if(g_bMidGameLoad)
		return;
	
	// reset the team kill counts
	for(new i=0;i<NUM_TEAMS;i++)
	{
		g_iKillsTotal[i] = 0;
		g_iDeathsTotal[i] = 0;
	}
	
	new iSize = GetArraySize(g_hPlayersUserIds);
	new player[Player];
	for(new i=0;i<iSize;i++)
	{
		Player_GetByUserId(GetArrayCell(g_hPlayersUserIds, i), player);
		player[PL_immune] = 0;
		player[PL_kills] = 0;
		player[PL_deaths] = 0;
		player[PL_rounds] = 0;
		player[PL_rounds_since_swap] = 0;
		Player_Save(player, false);
		
		// all players need to be expunged on a map change.  We will pick them up 
		// again as they reconnect back.
		Player_Delete(player[PL_userid], false);
	}
	
	ClearArray(g_hPlayersUserIds);
	
	// any players that have disconnected have been moved to a temporary
	// list, waiting to have their data flushed to disk.  It is done here to
	// prevent any data writes from occuring in-game.
	FlushDatabase();
	
	// reset the round counter
	g_iGlobalRounds = 0;
}

public OnMapEnd()
{
	g_bMidGameLoad = false;
}

public Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	// EVENT: executes whenever a round starts
	// Increment the number of rounds that have been played for this map.
	g_iGlobalRounds += 1;
	
	// remove everyone's invulnerability
	for(new i=1;i<=MaxClients;i++)
	{
		if(IsClientInGame(i))
			SetEntProp(i, Prop_Send, "m_nHitboxSet", 0);
	}
}

public Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	// EVENT: executes whenever a round ends
	// Delay a little bit, and call the delayed_round_end function.
	CreateTimer(1.0, Timer_DelayedRoundEnd, GetEventInt(event, "reason"), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_DelayedRoundEnd(Handle:timer, any:reason)
{
	new Float:fStart = GetEngineTime();
	DelayedRoundEnd(reason);
	LogMessage("End of round processing took %f seconds", GetEngineTime()-fStart);
	return Plugin_Handled;
}

DelayedRoundEnd(iReason)
{
	/* 
	Round end processing.
    executes a second after round end, because of the delay in the round_end
    that we do above.
    
    Keep track of the number of rounds each player has played, and compute their
    kill rates.
    
    If it is time, spring into action and do some team balancing.
	*/
	
	new iSize = GetArraySize(g_hPlayersUserIds);
	new player[Player];
	
	// do the team balancing calculations here.
	if(iReason == _:CSRoundEnd_Draw || iReason == _:CSRoundEnd_GameStart)
	{
		// do nothing on rounds that end in a draw
		// do nothing for rounds that end for game commence
		
		for(new i=0;i<iSize;i++)
		{
			Player_GetByUserId(GetArrayCell(g_hPlayersUserIds, i), player);
			Player_AddRounds(player, -1);
			Player_Save(player, false);
		}
		g_iGlobalRounds -= 1;
		return;
	}
	else
	{
		for(new i=0;i<iSize;i++)
		{
			Player_GetByUserId(GetArrayCell(g_hPlayersUserIds, i), player);
			Player_SetKillrate(player, false);
			Player_Save(player, false);
		}
		
		// set everyone's rank, which is determined by their killrate.
		SetRank();
	}
	
	new iRunFrequency = GetConVarInt(cv[CV_run_frequency]);
	
	new iNumberOfT = GetTeamClientCount(2);
	new iNumberOfCT = GetTeamClientCount(3);
	new Float:st, Float:sct;
	ComputeTeamStrength(iRunFrequency, st, sct);
	
	LogVerbose(3, "Round %d: Team Strengths: T = %.2f | CT = %.2f.", g_iGlobalRounds, st, sct);
	
	// new iLastBalanceRound = g_iGlobalRounds - (g_iGlobalRounds%iRunFrequency);
	// new iNextBalanceRound = iLastBalanceRound + iRunFrequency;
	decl String:sReport[512];
	Format(sReport, sizeof(sReport), "Balancing in %d rounds.", iRunFrequency - g_iGlobalRounds%iRunFrequency);
	
	// if there are not enough players on the server, do not even
	// attempt to do any balancing.
	if((iNumberOfT + iNumberOfCT) < GetConVarInt(cv[CV_min_player_count]))
	{
		LogVerbose(3, "No team balancing done, because there are not enough players: %d required.", GetConVarInt(cv[CV_min_player_count]));
		return;
	}
	
	// after all of these calculations, we need to swap players if need be.
	new iBalanceThisRound = 0;
	new bool:bObeyImmunity = true;
	
	if((g_iGlobalRounds % iRunFrequency) == 0)
	{
		Format(sReport, sizeof(sReport), "Balancing this round.");
		iBalanceThisRound = 1;
	}
	
	
	if(iBalanceThisRound == 0)
	{
		if(!IsTeamNumberBalanced(iNumberOfT, iNumberOfCT))
		{
			Format(sReport, sizeof(sReport), "Imbalance in team counts.  Balancing this round.");
			iBalanceThisRound = 2;
			bObeyImmunity = false;
		}
		
		if(IsTeamStrengthOffKilter(st, sct))
		{
			Format(sReport, sizeof(sReport), "Severe imbalance in team strengths.  Balancing this round.");
			iBalanceThisRound = 2;
			bObeyImmunity = false;
		}
	}
	
	if(iBalanceThisRound == 1)
	{
		if(g_iGlobalRounds < g_iRoundsInactive && !g_bMidGameLoad)
			iBalanceThisRound = 0;
	}
	
	if(iBalanceThisRound == 1)
	{
		new Float:fBalancePercentage = FloatAbs(2*(st-sct)/(st+sct))*100.0;
		if(fBalancePercentage < GetConVarFloat(cv[CV_acceptable_strength_imbalance]))
		{
			Format(sReport, sizeof(sReport), "No balancing needed; the teams are balanced to %.1f percent.", fBalancePercentage);
			iBalanceThisRound = 0;
		}
	}
	
	if(iBalanceThisRound == 1)
	{
		if((g_iGlobalRounds - g_iBalancedOnRound) == 1)
		{
			Format(sReport, sizeof(sReport), "Teams were balanced last round, so balancing is skipped.");
			iBalanceThisRound = 0;
		}
	}
	
	LogVerbose(3, sReport);
	
	if(iBalanceThisRound > 0)
		DoBalance(st-sct, bObeyImmunity);
	
	// remove immunity for any player that has been playing for over cfg['lose_immunity_after']
	// rounds.
	iSize = GetArraySize(g_hPlayersUserIds);
	for(new i=0;i<iSize;i++)
	{
		Player_GetByUserId(GetArrayCell(g_hPlayersUserIds, i), player);
		if(player[PL_rounds_since_swap] >= GetConVarInt(cv[CV_lose_immunity_after]))
		{
			player[PL_immune] = 0;
			Player_Save(player, false);
		}
	}
}

public Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*
	EVENT: executed whenever a player joins a team
    Update our player data structures accordingly.
    Also keep track of the team kills and deaths accordingly.
	*/
	//1 = spec
	//2 = t
	//3 = ct
	new iUserId = GetEventInt(event, "userid");
	new iTeam = GetEventInt(event, "team");
	new iOldTeam = GetEventInt(event, "oldteam");
	// PrintToChatAll("TEAM %d", iUserId);
	if(iTeam != 0)
	{
		new player[Player];
		Player_Add(iUserId);
		Player_GetByUserId(iUserId, player);
		g_iKillsTotal[iTeam] += player[PL_kills];
		g_iDeathsTotal[iTeam] += player[PL_deaths];
		g_iKillsTotal[iOldTeam] -= player[PL_kills];
		g_iDeathsTotal[iOldTeam] -= player[PL_deaths];
		
		/*
		POSSIBLE ISSUE: need to think through what happens here....the ranking will
        get computed even when the round is not active....may be better to leave
        the rankings uncomputed until it is team balance time.
		*/
		// SetRank();
	}
}

public Event_OnPlayerSpawn(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*
	EVENT: executed whenever a player spawns
    Record the fact that the player played this round.
	*/
	
	new iUserId = GetEventInt(event, "userid");
	// PrintToChatAll("SPAWN %d", iUserId);
	new client = GetClientOfUserId(iUserId);
	if(!client)
		return;
	
	new String:sName[MAX_NAME_LENGTH], String:sAuthId[MAX_STEAMAUTH_LENGTH];
	GetClientName(client, sName, sizeof(sName));
	if(!GetClientAuthString(client, sAuthId, sizeof(sAuthId)))
		sAuthId[0] = '\0';
	
	Player_Add(iUserId, sName, sAuthId);
	new player[Player];
	if(Player_GetByUserId(iUserId, player))
	{
		Player_AddRounds(player, 1);
		new iTeam = GetClientTeam(client);
		player[PL_team] = iTeam;
		player[PL_dead] = !IsPlayerAlive(client);
		Player_Save(player, false);
		
		// this section of code performs the notification that the player
		// has changed teams.
		if(player[PL_changing_team])
		{
			player[PL_changing_team] = false;
			Player_Save(player, false);
			new iNotifyTeamChange = GetConVarInt(cv[CV_notify_team_change]);
			if(iNotifyTeamChange > 0)
			{
				if(iTeam == 2)
				{
					Client_ScreenFade(client, 1000, FFADE_OUT|FFADE_PURGE, 100, 255, 0, 0, 60);
					if(iNotifyTeamChange > 1)
						EmitSoundToClient(client, "common/warning.wav");
					if(iNotifyTeamChange > 2)
						PrintCenterText(client, "You have been switched to the T side.");
				}
				if(iTeam == 3)
				{
					Client_ScreenFade(client, 1000, FFADE_OUT|FFADE_PURGE, 100, 0, 0, 255, 60);
					if(iNotifyTeamChange > 1)
						EmitSoundToClient(client, "common/warning.wav");
					if(iNotifyTeamChange > 2)
						PrintCenterText(client, "You have been switched to the CT side.");
				}
			}
		}
	}
}

// the sequence of events is...connect, spawn, activate, team, team, spawn

public Event_OnPlayerConnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*
	EVENT: a player has connected. 
	Create a new instance of a player and add them to our dictionary.
	*/
	
	/*
	in the beginning, this is where player_adds were handled.  However, I think
	that this is causing nonexistant players to be added to our data structure,
	in the case that they connect but disconnect before actually entering
	the game.  player_activate should be capable of picking up all players.
	*/
	//decl String:sName[MAX_NAME_LENGTH], String:sAuthId[MAX_STEAMAUTH_LENGTH];
	//GetEventString(event, "name", sName, sizeof(sName));
	//GetEventString(event, "networkid", sAuthId, sizeof(sAuthId));
	//Player_Add(GetEventInt(event, "userid"), sName, sAuthId);
}

public OnClientAuthorized(client, const String:auth[])
{
	/*
	EVENT: executed when a player is validated (gets a steam id)
	*/
	//new iUserId = GetClientUserId(client);
	//LogMessage("VALIDATED %d", iUserId);
	
	// it was found that at this point, userid==''.  So this is not of much
	// use to us, unless we want to start looking up the steamid.
	
	//decl String:sName[MAX_NAME_LENGTH];
	//GetClientName(client, sName, sizeof(sName));
	//Player_Add(iUserId, sName, auth);
}

public Event_OnPlayerActivate(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*
	EVENT: executed when a player is activated
	We need to handle this event and add a player if they are not already added,
	to properly handle players through a map change.  During a map change, players
	do not disconnect, but are reactivated at the beginning of the map./
	*/
	
	decl String:sName[MAX_NAME_LENGTH];
	new iUserId = GetEventInt(event, "userid");
	new client = GetClientOfUserId(iUserId);
	if(!client)
		return;
	
	GetClientName(client, sName, sizeof(sName));
	Player_Add(iUserId, sName);
}

stock Player_Add(iUserId, String:sName[]="", String:sAuthId[]="")
{
	/*
	handle a player addition.  This may be called when the user is validated,
	or when the user is activated (either one).  We must be able to handle
	both cases, which is the purpose of the logic below.
	*/
	
	new client = GetClientOfUserId(iUserId);
	if(!client)
		return;
	
	new player[Player];
	if(!Player_GetByUserId(iUserId, player))
	{
		player[PL_connected] = 1;
		if(StrEqual(sName, ""))
			GetClientName(client, sName, MAX_NAME_LENGTH);
		strcopy(player[PL_name], MAX_NAME_LENGTH, sName);
		player[PL_userid] = iUserId;
		Player_Save(player, false);
		LogMessage("%s added to balancer.", sName);
	}
	if(!player[PL_init_done])
	{
		if(StrEqual(sAuthId, ""))
		{
			if(!GetClientAuthString(client, sAuthId, MAX_STEAMAUTH_LENGTH))
				strcopy(sAuthId, MAX_STEAMAUTH_LENGTH, "PENDING");
		}
		if(StrContains("PENDING", sAuthId, false) == -1)
		{
			InitKillrate(iUserId, sAuthId);
			Player_GetByUserId(iUserId, player);
			LogMessage("%s [%s] updated in balancer.  Kill rate of %.2f per round.", player[PL_name], sAuthId, player[PL_killrate]);
		}
	}
}

LogVerbose(verb, String:format[], any:...)
{
	decl String:string[4096];
	VFormat(string, sizeof(string), format, 3);
	
	if(GetConVarInt(cv[CV_verbose]) >= verb)
		PrintToChatAll("[cCB] %s", string);
	
	LogMessage(string);
}

InitKillrate(iUserId, const String:sAuthId[])
{
	// sets the steam ID and initial killrate for a player given by userid and steamid
	
	new player[Player];
	Player_GetByUserId(iUserId, player);
	
	strcopy(player[PL_steamid], MAX_STEAMAUTH_LENGTH, sAuthId);
	
	player[PL_overall_rounds] = 0;
	player[PL_overall_deaths] = 0;
	player[PL_overall_kills] = 0;
	
	// Initialize with 0, if database unavailable.
	if(!g_hDatabase)
	{
		Player_SetKillrate(player, true);
		player[PL_init_done] = true;
		Player_Save(player, false);
		return;
	}
	
	// use a database to initialize the player's killrate.
	decl String:sQuery[512];
	Format(sQuery, sizeof(sQuery), "SELECT overall_rounds, overall_deaths, overall_kills FROM killrate WHERE steamid = '%s'", sAuthId);
	SQL_LockDatabase(g_hDatabase);
	new Handle:hResult = SQL_Query(g_hDatabase, sQuery);
	if(hResult == INVALID_HANDLE)
	{
		decl String:sError[128];
		SQL_GetError(hResult, sError, sizeof(sError));
		LogError("Error fetching player %s [%s] killrate. %s", player[PL_name], sAuthId, sError);
	}
	else
	{
		if(SQL_FetchRow(hResult))
		{
			player[PL_overall_rounds] = SQL_FetchInt(hResult, 0);
			player[PL_overall_deaths] = SQL_FetchInt(hResult, 1);
			player[PL_overall_kills] = SQL_FetchInt(hResult, 2);
		}
		
		CloseHandle(hResult);
	}
	
	SQL_UnlockDatabase(g_hDatabase);
	
	Player_SetKillrate(player, true);
	player[PL_init_done] = true;
	Player_Save(player, false);
}

public Event_OnPlayerChangeName(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*
	keep the name in our data structure synced with the player's actual name
	*/
	
	decl String:sName[MAX_NAME_LENGTH];
	new iUserId = GetEventInt(event, "userid");
	GetEventString(event, "newname", sName, sizeof(sName));
	new player[Player];
	if(Player_GetByUserId(iUserId, player))
	{
		strcopy(player[PL_name], MAX_NAME_LENGTH, sName);
		Player_Save(player, false);
	}
}

public Event_OnPlayerDisconnect(Handle:event, const String:name[], bool:dontBroadcast)
{
	new iUserId = GetEventInt(event, "userid");
	if(FindValueInArray(g_hPlayersUserIds, iUserId) != -1)
	{
		Player_Delete(iUserId, true);
	}
}

FlushDatabase()
{
	// takes the list of players that we have moved to DisconnectedPlayers, and
	// writes out their data to the database.
	new iSize = GetArraySize(g_hDisconnectedPlayersUserIds);
	decl String:sUserId[16], iUserId;
	new player[Player];
	for(new i=0;i<iSize;i++)
	{
		iUserId = GetArrayCell(g_hDisconnectedPlayersUserIds, i);
		IntToString(iUserId, sUserId, sizeof(sUserId));
		Player_GetByUserId(iUserId, player);
		
		Player_UpdateDatabase(player);
		
		// If that player was only referenced in the disconnected list, free the memory.
		if(FindValueInArray(g_hPlayersUserIds, iUserId) == -1)
			RemoveFromTrie(g_hPlayers, sUserId);
	}
	ClearArray(g_hDisconnectedPlayersUserIds);
}

public Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	/*
	EVENT: executes every time a player dies.
	record a death and a kill.
	*/
	new iUserId = GetEventInt(event, "userid");
	new iAttacker = GetEventInt(event, "attacker");
	
	new player[Player];
	Player_GetByUserId(iUserId, player);
	player[PL_dead] = 1;
	Player_Save(player, false);
	
	// do not count suicides
	if(iUserId == iAttacker)
		return;
	
	Player_AddDeath(player);
	Player_Save(player, false);
	if(iAttacker > 0)
	{
		Player_GetByUserId(iAttacker, player);
		Player_AddKill(player);
		Player_Save(player, false);
	}
}

DoBalance(Float:fCurrentStrengthDifference, bool:bObeyImmunity)
{
	/*
	compute all merit scores of trading players and do the best trade
	*/
	
	new iNumberOfT = GetTeamClientCount(2);
	new iNumberOfCT = GetTeamClientCount(3);
	
	LogMessage("In dobalance.  n_ct = %d, n_t = %d", iNumberOfCT, iNumberOfT);
	
	new Handle:hMerit = CreateArray(_:Merit);
	
	LogMessage("In dobalance.  Computing player moves.");
	// compute all possible player moves.  We need to only allow moves that will
	// satisfy team-number-balance constraints.
	new iSize = GetArraySize(g_hPlayersUserIds);
	new player[Player];
	for(new i=0;i<iSize;i++)
	{
		Player_GetByUserId(GetArrayCell(g_hPlayersUserIds, i), player);
		if(GetClientOfUserId(player[PL_userid]) > 0)
		{
			player[PL_dead] = !IsPlayerAlive(GetClientOfUserId(player[PL_userid]));
			ComputeMeritMove(hMerit, player, iNumberOfT, iNumberOfCT, bObeyImmunity);
		}
	}
	
	// compute all possible swaps.  We only allow swaps if the current team counts
	// are within our allowed limits.  Otherwise, we work only with player moves
	// as computed above.
	new iSwapsConsidered = 0;
	if(IsTeamNumberBalanced(iNumberOfT, iNumberOfCT))
	{
		new playerT[Player], playerCT[Player];
		for(new t=0;t<iSize;t++)
		{
			Player_GetByUserId(GetArrayCell(g_hPlayersUserIds, t), playerT);
			if(playerT[PL_team] == 2)
			{
				for(new ct=0;ct<iSize;ct++)
				{
					Player_GetByUserId(GetArrayCell(g_hPlayersUserIds, ct), playerCT);
					if(playerCT[PL_team] == 3)
					{
						if(iSwapsConsidered >= GetConVarInt(cv[CV_max_swaps_considered]))
						{
							// Break both loops..
							t = iSize;
							break;
						}
						
						ComputeMeritSwap(hMerit, playerT, playerCT, bObeyImmunity);
						
						iSwapsConsidered++;
					}
				}
			}
			
			player[PL_dead] = !IsPlayerAlive(GetClientOfUserId(player[PL_userid]));
			ComputeMeritMove(hMerit, player, iNumberOfT, iNumberOfCT, bObeyImmunity);
		}
	}
	
	if(GetArraySize(hMerit) > 0)
	{
		// now that we have a list of merit objects, sort them from low to high.
		//SortADTArrayCustom(hMerit, ADT_SortByScore);
		
		new iRunFrequency = GetConVarInt(cv[CV_run_frequency]);
		
		// we need to "penalize" each merit score that involves the swap of immune
		// players.  The tricky part is figuring out how much to penalize the score.
		// From the numbers I've been observing, it seems reasonable to me to 
		// simply penalize 1/4 of a kill per projected round.  We might need to
		// tweak this number, but we will start with this.
		// so from this
		iSize = GetArraySize(hMerit);
		new merit[Merit];
		for(new i=0;i<iSize;i++)
		{
			GetArrayArray(hMerit, i, merit[0], _:Merit);
			merit[M_adjusted_score] = merit[M_score] + float(merit[M_desirability])*0.25*float(iRunFrequency);
			SetArrayArray(hMerit, i, merit[0], _:Merit);
		}
		
		// in one pass, figure out who has the best merit score.
		new iBest, Float:fTopScore = 10000.0;
		for(new i=0;i<iSize;i++)
		{
			GetArrayArray(hMerit, i, merit[0], _:Merit);
			if(merit[M_adjusted_score] < fTopScore)
			{
				fTopScore = merit[M_adjusted_score];
				iBest = i;
			}
		}
		
		LogMessage("%d merits computed.", iSize);
		
		// Skip to port out-commented debug output from eventscripts version (line 849)
		
		GetArrayArray(hMerit, iBest, merit[0], _:Merit);
		LogMessage("INFO: best align = %.1f, strengthdiff=%.1f", merit[M_align], fCurrentStrengthDifference);
		
		/*
		only do the swapping if:
			1) the new projected numbers are better than the current strength difference
			2) we are ignoring immunity, which means we have an exception condition in that
				the team numbers are off-kilter, or team strengths are severely off.
		*/
		if(!bObeyImmunity || merit[M_score] < 0.7*FloatAbs(fCurrentStrengthDifference))
		{
			// if the team adjustment makes a bad team worse, then dont do it.
			//if(merit[M_align]*fCurrentStrengthDifference < 0.0)
			
			new bool:bAvoidCompilerWarningWithIfTrue = true;
			if(bAvoidCompilerWarningWithIfTrue)
			{
				g_iBalancedOnRound = g_iGlobalRounds;
				
				// pick off the one with the lowest score; which is the best swap that we can possibly
				// do.  Swap those two players (or move, if the merit object tells us that's
				// what we need to do)
				new iUserIdCT = merit[M_userid_ct];
				new iUserIdT = merit[M_userid_t];
				
				ApplyTeamProtections(iUserIdCT, iUserIdT);
				
				if(iUserIdCT == 0)
				{
					Player_GetByUserId(iUserIdT, player);
					LogVerbose(2, "moving %s (T) to team CT.", player[PL_name]);
					SwapTeam(iUserIdT, 3);
					player[PL_immune] += 1;
					player[PL_rounds_since_swap] = 0;
					player[PL_changing_team] = true;
					Player_Save(player, false);
				}
				else if(iUserIdT == 0)
				{
					Player_GetByUserId(iUserIdCT, player);
					LogVerbose(2, "moving %s (CT) to team T.", player[PL_name]);
					SwapTeam(iUserIdCT, 2);
					player[PL_immune] += 1;
					player[PL_rounds_since_swap] = 0;
					player[PL_changing_team] = true;
					Player_Save(player, false);
				}
				else
				{
					new playerT[Player], playerCT[Player];
					Player_GetByUserId(iUserIdT, playerT);
					Player_GetByUserId(iUserIdCT, playerCT);
					LogVerbose(2, "swapping %s (T) and %s (CT)", playerT[PL_name], playerCT[PL_name]);
					SwapTeam(iUserIdT, 3);
					SwapTeam(iUserIdCT, 2);
					playerT[PL_immune] += 1;
					playerCT[PL_immune] += 1;
					playerT[PL_rounds_since_swap] = 0;
					playerCT[PL_rounds_since_swap] = 0;
					playerT[PL_changing_team] = true;
					playerCT[PL_changing_team] = true;
					Player_Save(playerT, false);
					Player_Save(playerCT, false);
				}
			}
			else
			{
				LogVerbose(2, "Team swap cancelled: moving players would worsen the situation.");
			}
		}
		else
		{
			LogVerbose(2, "Team swap cancelled: moving players would not help imbalance.");
		}
	}
	else
	{
		LogVerbose(2, "Unable to list any valid moves or swaps.");
	}
	
	CloseHandle(hMerit);
}

SwapTeam(iUserId, iTeam)
{
	// eventscript used Mani's ma_swapteam which calls CCSPlayer::SetModelFromClass to fix the model.
	new client = GetClientOfUserId(iUserId);
	CS_SwitchTeam(client, iTeam);
	if(GetFeatureStatus(FeatureType_Native, "CS_UpdateClientModel") != FeatureStatus_Available)
		CS_UpdateClientModel(client);
	else if(g_hSetModelFromClass != INVALID_HANDLE)
		SDKCall(g_hSetModelFromClass, client);
	//ChangeClientTeam(GetClientOfUserId(iUserId), iTeam);
}

ApplyTeamProtections(iUserId1, iUserId2)
{
	new bool:bProtect;
	if(iUserId1 > 0 && IsPlayerAlive(GetClientOfUserId(iUserId1)))
		bProtect = true;
	if(iUserId2 > 0 && IsPlayerAlive(GetClientOfUserId(iUserId2)))
		bProtect = true;
	
	if(bProtect)
	{
		for(new i=1;i<=MaxClients;i++)
		{
			if(IsClientInGame(i) && IsPlayerAlive(i))
				Invulnerable(i);
		}
	}
}

ComputeMeritMove(Handle:hMerit, p[Player], iNumberOfT, iNumberOfCT, bool:bObeyImmunity)
{
	/*
	compute the merit of moving a single player
	*/
	
	// if this player is alive, dont allow him to be swapped
	if(GetConVarBool(cv[CV_wait_until_dead]) && !p[PL_dead])
		return;
	
	// absolutely dont allow anyone in the immunity list to be moved or swapped.
	if(CheckCommandAccess(GetClientOfUserId(p[PL_userid]), "ccb_immunity", ADMFLAG_KICK, true))
		return;
	
	// if this player already has been swapped this map, then dont allow him to be
	// swapped again.
	if(bObeyImmunity && p[PL_immune] > 0)
		return;
	
	// if this player has only played a small number of rounds, dont allow him to be
	// swapped.
	if(bObeyImmunity && p[PL_rounds] <= GetConVarInt(cv[CV_immune_for]))
		return;
	
	new merit[Merit];
	
	//new iTotalTKills = g_iKillsTotal[2];
	//new iTotalCTKills = g_iKillsTotal[3];
	
	new iRunFrequency = GetConVarInt(cv[CV_run_frequency]);
	new Float:st, Float:sct;
	ComputeTeamStrength(iRunFrequency, st, sct);
	
	new Float:fCTFactor, Float:fTFactor;
	if(sct < st)
	{
		//if(iTotalCTKills < iTotalTKills) {
		fCTFactor = GetConVarFloat(cv[CV_better_factor]);
		fTFactor = GetConVarFloat(cv[CV_worse_factor]);
	}
	else
	{
		fTFactor = GetConVarFloat(cv[CV_better_factor]);
		fCTFactor = GetConVarFloat(cv[CV_worse_factor]);
	}
	
	// compute projection of moving this player.
	if(p[PL_team] == 2)
	{
		// player is a T, would be moving them to CT
		new iProposedNumberOfT = iNumberOfT - 1;
		new iProposedNumberOfCT = iNumberOfCT + 1;
		new Float:fKillrate = p[PL_killrate] * fTFactor;
		merit[M_userid_t] = p[PL_userid];
		new Float:fTProjection = fKillrate * float(iRunFrequency);
		//new Float:fTLoss = 0.0; // should I project a little loss here?
		if(IsTeamNumberMoreBalanced(iNumberOfT, iNumberOfCT, iProposedNumberOfT, iProposedNumberOfCT) || IsTeamNumberBalanced(iProposedNumberOfT, iProposedNumberOfCT))
		{
			// merit[M_align] = (iTotalTKills-p[PL_kills]-fTLoss) - (iTotalCTKills+p[PL_kills]+fTProjection);
			// merit[M_align] = (st-p[PL_kills]-fTLoss) - (sct+p[PL_kills] + fTProjection);
			merit[M_align] = (st-p[PL_killrate]*float(iRunFrequency)) - (sct + fTProjection);
			merit[M_score] = FloatAbs(merit[M_align]);
			merit[M_desirability] = p[PL_immune];
			PushArrayArray(hMerit, merit[0], _:Merit);
		}
	}
	
	if(p[PL_team] == 3)
	{
		// player is a CT, would be moving them to T
		new iProposedNumberOfT = iNumberOfT + 1;
		new iProposedNumberOfCT = iNumberOfCT - 1;
		new Float:fKillrate = p[PL_killrate] * fCTFactor;
		merit[M_userid_ct] = p[PL_userid];
		new Float:fCTProjection = fKillrate * float(iRunFrequency);
		//new Float:fCTLoss = 0.0; // should I project a little loss here?
		if(IsTeamNumberMoreBalanced(iNumberOfT, iNumberOfCT, iProposedNumberOfT, iProposedNumberOfCT) || IsTeamNumberBalanced(iProposedNumberOfT, iProposedNumberOfCT))
		{
			// merit[M_align] = (iTotalTKills+p[PL_kills]+fCTLoss) - (iTotalCTKills-p[PL_kills]-fCTLoss);
			// merit[M_align] = (st+p[PL_kills]+fCTProjection) - (sct-p[PL_kills] - fCTLoss);
			merit[M_align] = (st+fCTProjection) - (sct - p[PL_killrate]*float(iRunFrequency));
			merit[M_score] = FloatAbs(merit[M_align]);
			merit[M_desirability] = p[PL_immune];
			PushArrayArray(hMerit, merit[0], _:Merit);
		}
	}
}

Float:ComputeTeamNumberImbalance(nt, nct)
{
	/*
	Returns a number from 0...1 that indicates the amount of imbalance.
    A perfect balance is 1.0.  Horrible balance is 0.0.
	*/
	// Avoid division by zero.
	if(nt == 0 || nct == 0)
		return 0.0;
	return float(Math_Min(nt,nct))/float(Math_Max(nt,nct))*100.0;
}

bool:IsTeamStrengthOffKilter(Float:st, Float:sct)
{
	new Float:percentage = 0.0;
	// Avoid division by zero.
	if(st != 0.0 && sct != 0.0)
		percentage = Math_Min(st, sct)/Math_Max(st, sct)*100.0;
	if(percentage < GetConVarFloat(cv[CV_team_strength_percentage_trigger]))
		return true;
	else
		return false;
}

bool:IsTeamNumberBalanced(nt, nct)
{
	// The team numbers are considered balanced if they are above the percentage
	// threshhold OR if there is only a difference of 1 between the two team
	// counts.
	
	if(Math_Abs(nt-nct) == 1)
		return true;
	
	new Float:p = ComputeTeamNumberImbalance(nt, nct);
	if(p > GetConVarFloat(cv[CV_team_imbalance_percentage_trigger]))
		return true;
	else
		return false;
}

IsTeamNumberMoreBalanced(nt, nct, ntnew, nctnew)
{
	/*
	Answers the question of whether or not the teams are getting more balanced
    or less balanced as a result of changing the team numbers.
	*/
	
	new Float:p    = ComputeTeamNumberImbalance(nt, nct);
	new Float:pnew = ComputeTeamNumberImbalance(ntnew, nctnew);
	
	if(pnew > p)
		return true;
	else
		return false;
}

ComputeMeritSwap(Handle:hMerit, playerT[Player], playerCT[Player], bool:bObeyImmunity)
{
	/*
	compute the merit of swapping two players
	*/
	
	
	if(GetConVarBool(cv[CV_wait_until_dead]))
		if(!playerT[PL_dead] || !playerCT[PL_dead])
			return;
		
	// absolutely dont allow anyone in the immunity list to be moved or swapped.
	if(CheckCommandAccess(GetClientOfUserId(playerT[PL_userid]), "ccb_immunity", ADMFLAG_KICK, true))
		return;
	if(CheckCommandAccess(GetClientOfUserId(playerCT[PL_userid]), "ccb_immunity", ADMFLAG_KICK, true))
		return;
	
	if(bObeyImmunity)
	{
		// dont allow a player that has already been swapped to be swapped again.
		if(playerT[PL_immune] > 0 || playerCT[PL_immune] > 0)
			return;
		
		// if this player has only played a small number of rounds, dont allow him to be
		// swapped.
		new iImmuneFor = GetConVarInt(cv[CV_immune_for]);
		if(playerT[PL_rounds] <= iImmuneFor || playerCT[PL_rounds] <= iImmuneFor)
			return;
	}
	
	new m[Merit];
	//new iTotalTKills = g_iKillsTotal[2];
	//new iTotalCTKills = g_iKillsTotal[3];
	
	new iRunFrequency = GetConVarInt(cv[CV_run_frequency]);
	new Float:sct, Float:st;
	ComputeTeamStrength(iRunFrequency, st, sct);
	
	new Float:fCTFactor, Float:fTFactor;
	if(sct < st)
	{
		//if(iTotalCTKills < iTotalTKills) {
		fCTFactor = GetConVarFloat(cv[CV_better_factor]);
		fTFactor = GetConVarFloat(cv[CV_worse_factor]);
	}
	else
	{
		fTFactor = GetConVarFloat(cv[CV_better_factor]);
		fCTFactor = GetConVarFloat(cv[CV_worse_factor]);
	}
	
	// compute projection of trading these two players
	new Float:fKillrate = playerT[PL_killrate] * fTFactor;
	new Float:fTProjection = fKillrate * iRunFrequency;
	
	fKillrate = playerCT[PL_killrate] * fCTFactor;
	new Float:fCTProjection = fKillrate * iRunFrequency;
	
	m[M_userid_t] = playerT[PL_userid];
	m[M_userid_ct] = playerCT[PL_userid];
	m[M_align] = (st-playerT[PL_killrate]*iRunFrequency+fCTProjection) - (sct-playerCT[PL_killrate]*iRunFrequency+fTProjection);
	m[M_score] = FloatAbs(m[M_align]);
	m[M_desirability] = playerT[PL_immune] + playerCT[PL_immune];
	
	PushArrayArray(hMerit, m[0], _:Merit);
}

public Action:Cmd_ShowStats(client, args)
{
	new Handle:hT, Handle:hCT;
	SortedPlayerLists(hT, hCT);
	new Float:t_mom, Float:ct_mom;
	ComputeTeamMomentum(GetConVarInt(cv[CV_run_frequency]), t_mom, ct_mom);
	
	
	PrintToConsole(client, "===========================================================");
	PrintToConsole(client, "Cans Crew Balancer Statistics");
	PrintToConsole(client, "===========================================================");
	PrintToConsole(client, "Total Kills (T) : %d", g_iKillsTotal[2]);
	PrintToConsole(client, "Total Kills (CT): %d", g_iKillsTotal[3]);
	PrintToConsole(client, "TEAM STRENGTH (T) : %.2f", t_mom);
	PrintToConsole(client, "TEAM STRENGTH (CT): %.2f", ct_mom);
	PrintToConsole(client, "-----------------------------------------------------------");
	PrintToConsole(client, "%4s %5s %-30s %3s %3s %3s %s %s", "Rank","ID","Name","K","D","Rnd","KillRate","Swaps");
	PrintToConsole(client, "-----------------------------------------------------------");
	PrintToConsole(client, "Terrorists:");
	
	new iSize = GetArraySize(hT);
	new player[Player];
	for(new i=0;i<iSize;i++)
	{
		GetArrayArray(hT, i, player[0], _:Player);
		ShowStat(client, player);
	}
	CloseHandle(hT);
	
	PrintToConsole(client, "Counter Terrorists:");
	
	iSize = GetArraySize(hCT);
	for(new i=0;i<iSize;i++)
	{
		GetArrayArray(hCT, i, player[0], _:Player);
		ShowStat(client, player);
	}
	CloseHandle(hCT);
	
	Client_Reply(client, "{G}[cCB] ccbstat results are displayed in the console.");
	
	return Plugin_Handled;
}

ComputeTeamMomentum(nrounds_forward, &Float:mt, &Float:mct)
{
	// computes the team momentums, meaning the number of kills that they are
	// expected to achieve over the next nrounds_forward rounds.
	mt = 0.0;
	mct = 0.0;
	
	new iSize = GetArraySize(g_hPlayersUserIds);
	new player[Player];
	for(new i=0;i<iSize;i++)
	{
		Player_GetByUserId(GetArrayCell(g_hPlayersUserIds, i), player);
		
		if(player[PL_team] == 2)
			mt += player[PL_killrate]*float(nrounds_forward);
		else if(player[PL_team] == 3)
			mct += player[PL_killrate]*float(nrounds_forward);
	}
}

ComputeTeamStrength(nrounds_forward, &Float:mt, &Float:mct)
{
	// compute the team strength...the kills projected for each team at the end
	// of nrounds_forward rounds.
	ComputeTeamMomentum(nrounds_forward, mt, mct);
	
	// mt += float(g_iKillsTotal[2]);
	// mct += float(g_iKillsTotal[3]);
}

ShowStat(client,x[Player])
{
	PrintToConsole(client, "%4d %5d %-30s %3d %3d %3d %.2f %d", x[PL_rank], x[PL_userid], x[PL_name], x[PL_kills], x[PL_deaths], x[PL_rounds], x[PL_killrate], x[PL_immune]);
}

SortedPlayerLists(&Handle:hTs, &Handle:hCTs)
{
	hTs = CreateArray(_:Player);
	hCTs = CreateArray(_:Player);
	
	new iSize = GetArraySize(g_hPlayersUserIds);
	new player[Player];
	for(new i=0;i<iSize;i++)
	{
		Player_GetByUserId(GetArrayCell(g_hPlayersUserIds, i), player);
		if(player[PL_team] == 2)
			PushArrayArray(hTs, player[0], _:Player);
		else if(player[PL_team] == 3)
			PushArrayArray(hCTs, player[0], _:Player);
	}
	
	// Sort descending by killrate
	SortADTArrayCustom(hTs, ADT_SortByKillrate);
	SortADTArrayCustom(hCTs, ADT_SortByKillrate);
}

public ADT_SortByKillrate(index1, index2, Handle:array, Handle:hndl)
{
	new player1[Player], player2[Player];
	GetArrayArray(array, index1, player1[0], _:Player);
	GetArrayArray(array, index2, player2[0], _:Player);
	
	return RoundToCeil(player2[PL_killrate] - player1[PL_killrate]);
}

SetRank()
{
	new Handle:hT, Handle:hCT;
	SortedPlayerLists(hT, hCT);
	
	// assign the ranks
	new iSize = GetArraySize(hT);
	new player[Player], globalPlayer[Player];
	for(new i=0;i<iSize;i++)
	{
		GetArrayArray(hT, i, player[0], _:Player);
		Player_GetByUserId(player[PL_userid], globalPlayer);
		globalPlayer[PL_rank] = i+1;
		Player_Save(globalPlayer, false);
	}
	CloseHandle(hT);
	
	iSize = GetArraySize(hCT);
	for(new i=0;i<iSize;i++)
	{
		GetArrayArray(hCT, i, player[0], _:Player);
		Player_GetByUserId(player[PL_userid], globalPlayer);
		globalPlayer[PL_rank] = i+1;
		Player_Save(globalPlayer, false);
	}
	CloseHandle(hCT);
}

Invulnerable(client)
{
	// I have to boost the health along with removing the hitboxes, because
	// the knife still does damage.
	SetEntProp(client, Prop_Send, "m_iHealth", 1000);
	SetEntProp(client, Prop_Send, "m_nHitboxSet", 2);
}