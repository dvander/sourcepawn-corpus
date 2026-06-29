/*
teambalance.sp

Description:
	Team Balance Plugin for SourceMod
	
Credits:
	The SwitchTeams() function and associated sdktools calls were taken from SM Super Commands by pRED*
	The WeaponDrop() stuff was taken from GunGame:SM by team06
	Thanks to everyone in the scripting forum.  You guys have been super supportive of all my questions.

Versions:
	0.5
		* Initial Release
		
	0.6
		* Made announcement preferences more flexible
		
	0.7
		* Added checks of relative strength prior to switching
		* Removed the insert statement on player join
		* Changed the delete to a query followed by an insert/update
		* Make the insert/update in update setting threaded
		* Added german translation courtesy of -<[PAGC]>- Isias
		* Added russian translation courtesy of exvel
		
	0.8
		* Updated translations
		* Added optional support for team switching commands
		* Added additional error checking
		
	0.9
		* Updated the update stats and load stats calls to close the handles on failure
		* Update the updates stats function to use REPLACE
		* Updated the balancer so it deals with the case where the winning team is much larger but filled with crap players
		* Added sm_team_balance_maintain_size to force the balancer to balance if the teamsize are off
		* Updated the team balance text to green
		
	1.0
		* Added functionality to control and manage the joining of teams
		* Increased the recency of win/loss stats by changing ROUNDS_TO_SAVE from 10 to 6
		* Fixed array out of bounds errors
		* Fixed Native "GetPlayerWeaponSlot" reported: World not allowed
		
	1.1
		* Added team management menu
		* removed explicit KDR tracking
		* Added ability to get team balance stats
		* Fixed Native "GetPlayerWeaponSlot" reported: World not allowed..again
		
	2.0
		* Added MySQL support
		* Added admin command sm_tbdump
		* Added admin command sm_tbset
		* Added admin immunity for join control
		* Added admin immunity to the balancer
		* Added dump settings to team management menu
		* Added display stats to team management menu
		* Added fix for array out of bounds error
		* Fixed Native "GetPlayerWeaponSlot" reported: World not allowed..for the third time
		* Increased the priority of sm_team_balance_maintain_size
		* If sm_team_balance_new_join_rounds = 0, the new join pending condition is ignored
		* Removed KDR display when debug is on
		* Changed the default value of sm_team_balance_min_rounds to 2
		* Fixed spelling of of sm_team_balance_announce
		
	2.1
		* Fixed a bug in the switch player menu
		* Moved the the default location of config file
		* Added a feature for switch at round end
		* Added !tbswitchatend, !tbtbswitchnow and !tbswap for consistency
		* Changed menu command to !tbmenu for consistency
		* !swapteams and !teamswitch are deprecated and will be removed in the future
		
	2.1.1
		* Added the ability to navigate through the stats
		
	2.1.2
		* Fixed a bug with join immunity & admin immunity

	2.1.3
		* Fixed another bug with admin immunity
		
	2.2
		* Added sm_team_balance_min_balance_frequency
		* Changed the default value of new join rounds
		* Switched to OnClientPostAdminCheck
		* Added sm_team_balance_stop_spec
		* Added sm_team_balance_lock_teams
		* Added autoloading of config file
		* Added admin flags
		
	2.2.1
		* Updated spelling in CommandDump
		* Fixed admin immunity for the losing team
		
	2.2.2
		* Made it so admin immunity did not only switch admins
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "2.2.2"
#define MAX_FILE_LEN 80

#define KILLS 0
#define DEATHS 1
#define NUM_STATS 2

#define TEAMS_BALANCED 1
#define TEAMS_UNBALANCED 0
#define TEAM_BALANCE_PENDING 3

#define TERRORIST_TEAM 2
#define COUNTER_TERRORIST_TEAM 3
#define NO_TEAM -1
#define NUM_TEAMS 2

#define TERRORIST_INDEX 0
#define COUNTER_TERRORIST_INDEX 1

#define NUM_TEAM_INFOS 3
#define TOTAL_WINS 0
#define CONSECUTIVE_WINS 1
#define ROUND_SWITCH 2

#define ROUNDS_TO_SAVE 6

#define PENDING_MESSAGE 1
#define NOT_BALANCED_MESSAGE 2
#define BALANCED_MESSAGE 4
#define CANT_BALANCE_MESSAGE 8

#define STATS_PER_PANEL 8

#define SQLITE 0
#define MYSQL 1

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Team Balance",
	author = "dalto",
	description = "Team Balancer Plugin",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

// Global Variables
new	Handle:g_CvarVersion = INVALID_HANDLE;
new	Handle:g_CvarEnabled = INVALID_HANDLE;
new	Handle:g_CvarMinKills = INVALID_HANDLE;
new	Handle:g_CvarConsecutiveWins = INVALID_HANDLE;
new	Handle:g_CvarWinLossRatio = INVALID_HANDLE;
new	Handle:g_CvarRoundsNewJoin = INVALID_HANDLE;
new	Handle:g_CvarMinRounds = INVALID_HANDLE;
new	Handle:g_CvarSaveTime = INVALID_HANDLE;
new	Handle:g_CvarDefaultKDR = INVALID_HANDLE;
new	Handle:g_CvarAnnounce = INVALID_HANDLE;
new	Handle:g_CvarIncrement = INVALID_HANDLE;
new	Handle:g_CvarSingleMax = INVALID_HANDLE;
new	Handle:g_CvarCommands = INVALID_HANDLE;
new	Handle:g_CvarMaintainSize = INVALID_HANDLE;
new	Handle:g_CvarControlJoins = INVALID_HANDLE;
new	Handle:g_CvarDatabase = INVALID_HANDLE;
new	Handle:g_CvarJoinImmunity = INVALID_HANDLE;
new	Handle:g_CvarAdminImmunity = INVALID_HANDLE;
new	Handle:g_CvarMinBalance = INVALID_HANDLE;
new	Handle:g_CvarLockTeams = INVALID_HANDLE;
new	Handle:g_CvarStopSpec = INVALID_HANDLE;
new	Handle:g_CvarAdminFlags = INVALID_HANDLE;
new	Handle:g_CvarLockTime = INVALID_HANDLE;
new roundStats[NUM_TEAMS][ROUNDS_TO_SAVE];
new playerStats[MAXPLAYERS + 1][NUM_STATS];
new whoWonLast;
new teamInfo[NUM_TEAMS][NUM_TEAM_INFOS];
new roundNum;
new Handle:gameConf = INVALID_HANDLE;
new Handle:switchTeam = INVALID_HANDLE;
new Handle:setModel = INVALID_HANDLE;
new Handle:roundRespawn = INVALID_HANDLE;
new Handle:weaponDrop = INVALID_HANDLE;
new bool:balanceTeams;
new bool:lateLoaded;
new bool:forceBalance = false;
static const String:ctModels[4][] = {"models/player/ct_urban.mdl", "models/player/ct_gsg9.mdl", "models/player/ct_sas.mdl", "models/player/ct_gign.mdl"};
static const String:tModels[4][] = {"models/player/t_phoenix.mdl", "models/player/t_leet.mdl", "models/player/t_arctic.mdl", "models/player/t_guerilla.mdl"};
new Handle:sqlTeamBalanceStats = INVALID_HANDLE;
new bool:g_commandsHooked = false;
new g_panelPos[MAXPLAYERS + 1];
new g_playerList[MAXPLAYERS];
new String:g_playerListNames[MAXPLAYERS][40];
new g_playerCount;
new g_dbType;
new bool:g_switchNextRound[MAXPLAYERS + 1];
new g_balancedLast;
new g_teamList[MAXPLAYERS + 1];
new String:g_adminFlags[20];
new Handle:g_kv = INVALID_HANDLE;

// We need to capture if the plugin was late loaded so we can make sure initializations
// are handled properly
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	lateLoaded = late;
	return true;
}

public OnPluginStart()
{
	// Load the translations
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.teambalance");
	
	// Create the CVARs
	g_CvarVersion = CreateConVar("sm_team_balance_version", PLUGIN_VERSION, "Team Balance Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_CvarEnabled = CreateConVar("sm_team_balance_enable", "1", "Enables the Team Balance plugin, when disabled the plugin will still collect stats");
	g_CvarMinKills = CreateConVar("sm_team_balance_min_kd", "10", "The minimum number of kills + deaths in order to be given a real kdr");
	g_CvarAnnounce = CreateConVar("sm_team_balance_announce", "15", "Announcement preferences");
	g_CvarConsecutiveWins = CreateConVar("sm_team_balance_consecutive_wins", "4", "The number of consecutive wins required to declare the teams unbalanced");
	g_CvarWinLossRatio = CreateConVar("sm_team_balance_wlr", "0.55", "The win loss ratio required to declare the teams unbalanced");
	g_CvarRoundsNewJoin = CreateConVar("sm_team_balance_new_join_rounds", "0", "The number of rounds to delay team balancing when a new player joins the losing team");
	g_CvarMinRounds = CreateConVar("sm_team_balance_min_rounds", "2", "The minimum number of rounds before the team balancer starts");
	g_CvarSaveTime = CreateConVar("sm_team_balance_save_time", "672", "The number of hours to save stats for");
	g_CvarDefaultKDR = CreateConVar("sm_team_balance_def_kdr", "1.0", "The default kdr used until a real kdr is established");
	g_CvarIncrement = CreateConVar("sm_team_balance_increment", "5", "The increment for which additional players are balanced");
	g_CvarSingleMax = CreateConVar("sm_team_balance_single_max", "6", "The maximimum number of players on a team for which a single player is balanced");
	g_CvarCommands = CreateConVar("sm_team_balance_commands", "0", "A flag to say whether the team commands will be enabled");
	g_CvarMaintainSize = CreateConVar("sm_team_balance_maintain_size", "1", "A flag to say if the team size should be maintained");
	g_CvarControlJoins = CreateConVar("sm_team_balance_control_joins", "0", "If 1 this plugin fully manages who can join each team");
	g_CvarDatabase = CreateConVar("sm_team_balance_database", "", "The database configuration to use.  Empty for a local SQLite db");
	g_CvarJoinImmunity = CreateConVar("sm_team_balance_join_immunity", "0", "Set to 0 if admins should not be immune to join control");
	g_CvarAdminImmunity = CreateConVar("sm_team_balance_admin_immunity", "0", "0 to disable immunity.  WARNING: Enabling immunity SEVERELY limits the balancing algorithm");
	g_CvarMinBalance = CreateConVar("sm_team_balance_min_balance_frequency", "1", "This is the number of rounds to skip between balancing");
	g_CvarLockTeams = CreateConVar("sm_team_balance_lock_teams", "0", "Set to 1 if you want to force each player to stay in the teams assigned");
	g_CvarStopSpec = CreateConVar("sm_team_balance_stop_spec", "0", "Set to 1 if you don't want players who have already joined a team to be able to switch to spectator");
	g_CvarAdminFlags = CreateConVar("sm_team_balance_admin_flags", "", "The admin flags that admins who should have immunity must have one of");
	g_CvarLockTime = CreateConVar("sm_team_balance_lock_time", "15", "The number of minutes after disconnect before the team lock expires after disconnect");
	
	// Watch these cvar's for changes
	HookConVarChange(g_CvarAdminFlags, AdminFlagsChanged);
	
	// Execute the config file
	AutoExecConfig(true, "sm_teambalance");
	
	// SDK Calls for team switching and model setting
	// taken from SM Super Commands by pRED*
	gameConf = LoadGameConfigFile("teambalance.games");
	if(gameConf == INVALID_HANDLE)
	{
		SetFailState("gamedata/teambalance.games.txt not loadable");
	}

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "SwitchTeam");
	PrepSDKCall_AddParameter(SDKType_PlainOldData, SDKPass_Plain);
	switchTeam = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "SetModel");
	PrepSDKCall_AddParameter(SDKType_String, SDKPass_Pointer);
	setModel = EndPrepSDKCall();

	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "RoundRespawn");
	roundRespawn = EndPrepSDKCall();
	
	// This one was taken from GunGame:SM by team06
	StartPrepSDKCall(SDKCall_Player);
	PrepSDKCall_SetFromConf(gameConf, SDKConf_Signature, "CSWeaponDrop");
	PrepSDKCall_AddParameter(SDKType_CBaseEntity, SDKPass_Pointer);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	PrepSDKCall_AddParameter(SDKType_Bool, SDKPass_Plain);
	weaponDrop = EndPrepSDKCall();

	// Hook events and register commands as needed
	HookEvent("player_death", EventPlayerDeath);
	HookEvent("round_end", EventRoundEnd);
	HookEvent("round_start", EventRoundStart, EventHookMode_Pre);
	HookEvent("player_team", EventPlayerTeamChange);

	// Initialize the staistics database
	InitializeStats();

	RegConsoleCmd("jointeam", CommandJoinTeam);
	RegConsoleCmd("sm_tbstats", CommandKDR);
	RegAdminCmd("sm_tbmenu", TeamManagementMenu, ADMFLAG_CONVARS);
	RegAdminCmd("sm_tbdump", CommandDump, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tbset", CommandSet, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tbswitchatstart", CommandStartSwitch, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tbswitchnow", CommandTeamSwitch, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tbswap", CommandTeamSwap, ADMFLAG_GENERIC);
	
	g_kv=CreateKeyValues("LockExpiration");

	// if the plugin was loaded late we have a bunch of initialization that needs to be done
	if(lateLoaded)
	{
		// Next we need to whatever we would have done on each client
		for(new i = 1; i < GetMaxClients(); i++)
		{
			if(IsClientInGame(i))
			{
				LoadStats(i);
			}
		}
	}
}

// Map level initializations
public OnMapStart()
{
	MapStartInitializations();
}

// When a new client is authorized and putinserver we check to see if
// they have data that needs to be loaded
public OnClientPostAdminCheck(client)
{
	if(client && !IsFakeClient(client) && IsClientInGame(client))
	{
		decl String:steamId[30];
		// Get the users saved setting or create them if they don't exist
		GetClientAuthString(client, steamId, 20);
		KvRewind(g_kv);
		if(KvJumpToKey(g_kv, steamId))
		{
			if(GetTime() < KvGetNum(g_kv, "timestamp") + GetConVarInt(g_CvarLockTime) * 60)
			{
				g_teamList[client] = KvGetNum(g_kv, "team", 0);
				return;
			}
		}
		g_teamList[client] = 0;
	}

	LoadStats(client);
}

// When a user disconnects we need to put there stats into kvTDB
public OnClientDisconnect(client)
{
	new String:steamId[20];
	if(client && !IsFakeClient(client)) {
		GetClientAuthString(client, steamId, 20);
		KvRewind(g_kv);
		if(KvJumpToKey(g_kv, steamId, true))
		{
			KvSetNum(g_kv, "team", g_teamList[client]);
			KvSetNum(g_kv, "timestamp", GetTime());
		}
	}
	UpdateStats(client);
}

// The death event tracks player stats
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new attackerClient = GetClientOfUserId(attackerId);
	new victimClient = GetClientOfUserId(victimId);

	if(attackerClient && IsClientInGame(attackerClient))
	{
		playerStats[attackerClient][KILLS]++;
	}
	if(victimClient && IsClientInGame(victimClient))
	{
		playerStats[victimClient][DEATHS]++;
	}
}

// The GetTeamBalance function tries to determine if the teams are currently balanced
public GetTeamBalance()
{
	// If there have not been enough rounds or there has not been a winner yet than the team balance is pending
	if(whoWonLast == NO_TEAM || roundNum < GetConVarInt(g_CvarMinRounds))
	{
		return TEAM_BALANCE_PENDING;
	}

	if(roundNum < g_balancedLast + GetConVarInt(g_CvarMinBalance))
	{
		return TEAM_BALANCE_PENDING;
	}

	// check to see if we need to rebalance the teams for size
	if(GetConVarBool(g_CvarMaintainSize))
	{
		// Count the team sizes
		new teamCount[2];
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(IsClientInGame(i) && (GetClientTeam(i) == TERRORIST_TEAM || GetClientTeam(i) == COUNTER_TERRORIST_TEAM))
			{
				teamCount[GetTeamIndex(GetClientTeam(i))]++;
			}
		}
		if(teamCount[0] - teamCount[1] > 1 || teamCount[1] - teamCount[0] > 1)
		{
			forceBalance = true;
			return TEAMS_UNBALANCED;
		}
	}
	
	// Check to see if it is pending due to player join
	if(GetConVarInt(g_CvarRoundsNewJoin) && teamInfo[GetOtherTeam(GetTeamIndex(whoWonLast))][ROUND_SWITCH] > roundNum - GetConVarInt(g_CvarRoundsNewJoin))
	{
		return TEAM_BALANCE_PENDING;
	}

	// If the number of consecutive wins has been exceeded than the teams are not balanced
	if(teamInfo[GetTeamIndex(whoWonLast)][CONSECUTIVE_WINS] >= GetConVarInt(g_CvarConsecutiveWins))
	{
		return TEAMS_UNBALANCED;
	}
	
	// Check to see if we are below the minimum winn/loss ratio	
	if(float(teamInfo[GetOtherTeam(GetTeamIndex(whoWonLast))][TOTAL_WINS]) / float(teamInfo[GetTeamIndex(whoWonLast)][TOTAL_WINS]) < GetConVarFloat(g_CvarWinLossRatio))
	{
		return TEAMS_UNBALANCED;
	}

	// check to see if we need to rebalance the teams for size
	if(GetConVarBool(g_CvarMaintainSize))
	{
		// Count the team sizes
		new teamCount[2];
		for(new i = 1; i <= GetMaxClients(); i++)
		{
			if(IsClientInGame(i) && (GetClientTeam(i) == TERRORIST_TEAM || GetClientTeam(i) == COUNTER_TERRORIST_TEAM))
			{
				teamCount[GetTeamIndex(GetClientTeam(i))]++;
			}
		}
		if(teamCount[0] - teamCount[1] > 1 || teamCount[1] - teamCount[0] > 1)
		{
			forceBalance = true;
			return TEAMS_UNBALANCED;
		}
	}
	
	// If we are not unbalanced or pending then we must be balanced
	return TEAMS_BALANCED;
}

// In EventRoundEnd we update round stats, check to see if the teams are
// in balance and then take appropriate action
public EventRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new winner = GetEventInt(event, "winner");
	new reason = GetEventInt(event, "reason");
	
	// Make sure that we have a normal round end
	if(reason == 16)
	{
		return;
	}
	
	// Make sure that the winner is not something strange
	if(winner != TERRORIST_TEAM && winner != COUNTER_TERRORIST_TEAM)
	{
		return;
	}
	
	// Update the map statistics
	roundStats[GetTeamIndex(winner)][roundNum % ROUNDS_TO_SAVE] = 1;
	roundStats[GetTeamIndex(GetOtherTeam(winner))][roundNum % ROUNDS_TO_SAVE] = 0;
	// We need recent statistics for our win-loss-ratio comparison
	teamInfo[COUNTER_TERRORIST_INDEX][TOTAL_WINS] = 0;
	teamInfo[TERRORIST_INDEX][TOTAL_WINS] = 0;
	for(new i = 0; i < ROUNDS_TO_SAVE; i++)
	{
		teamInfo[COUNTER_TERRORIST_INDEX][TOTAL_WINS] += roundStats[COUNTER_TERRORIST_INDEX][i];
		teamInfo[TERRORIST_INDEX][TOTAL_WINS] += roundStats[TERRORIST_INDEX][i];
	}	

	// update whoWonLast and consecutive wins counts
	teamInfo[GetTeamIndex(winner)][CONSECUTIVE_WINS]++;
	if(whoWonLast != winner)
	{
		whoWonLast = winner;
		teamInfo[GetTeamIndex(GetOtherTeam(winner))][CONSECUTIVE_WINS] = 0;
	}
	
	if(GetConVarBool(g_CvarEnabled))
	{
		// Check to see if the teams are in balance and take action as needed
		switch(GetTeamBalance())
		{
			case TEAM_BALANCE_PENDING:
			{
				if(GetConVarInt(g_CvarAnnounce) & PENDING_MESSAGE)
				{
					PrintTranslatedToChatAll("pending");
				}
			}
			case TEAMS_BALANCED:
			{
				if(GetConVarInt(g_CvarAnnounce) & BALANCED_MESSAGE)
				{
					PrintTranslatedToChatAll("balanced");
				}
			}
			case TEAMS_UNBALANCED:
			{
				if(GetConVarInt(g_CvarAnnounce) & NOT_BALANCED_MESSAGE)
				{
					PrintTranslatedToChatAll("not balanced");
				}
				balanceTeams = true;
			}
		}
	}
		
		
	roundNum++;
}

// We need to track when someone joins a team to ensure that we are accounting
// for changes in team strength and not making swaps too frequently
public EventPlayerTeamChange(Handle:event, const String:name[], bool:dontBroadcast)
{
	new userid = GetEventInt(event, "userid");
	new team = GetEventInt(event, "team");
	new client = GetClientOfUserId(userid);
	if(client && team == COUNTER_TERRORIST_TEAM || team == TERRORIST_TEAM && IsClientInGame(client) && !IsFakeClient(client))
	{
		teamInfo[GetTeamIndex(team)][ROUND_SWITCH] = roundNum;
		g_teamList[client] = team;
	}
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(g_switchNextRound[i] && IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			SwitchTeam(i, GetOtherTeam(GetClientTeam(i)));
			g_switchNextRound[i] = false;
		}
	}
	
	if(balanceTeams)
	{
		if(!BalanceTeams() && GetConVarInt(g_CvarAnnounce) & CANT_BALANCE_MESSAGE)
		{
			PrintTranslatedToChatAll("unbalanceable");
		}
		balanceTeams = false;
		forceBalance = false;
	}
	
	// Update the player list
	g_playerCount = 0;
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i))
		{
			g_playerList[g_playerCount] = i;
			g_playerCount++;
		}
	}
	
	// Sort the player list by KDR
	SortCustom1D(g_playerList, g_playerCount, SortKDR);
	
	for(new i = 0; i < g_playerCount; i++)
	{
		GetClientName(g_playerList[i], g_playerListNames[i], sizeof(g_playerListNames[]));
	}
	
	return Plugin_Continue;
}


//  Balances the teams based on KDR
public bool:BalanceTeams()
{
	new arrayTeams[2][MAXPLAYERS];
	new switchArray[MAXPLAYERS];
	new bottomPlayer;
	new numPlayers;
	new clientToSwitch;
	decl String:buffer[40];

	// Put all the players into arrays by team
	new teamCount[2];
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) == TERRORIST_TEAM || GetClientTeam(i) == COUNTER_TERRORIST_TEAM))
		{
			arrayTeams[GetTeamIndex(GetClientTeam(i))][teamCount[GetTeamIndex(GetClientTeam(i))]] = i;
			teamCount[GetTeamIndex(GetClientTeam(i))]++;
		}
	}
	
	// Sort the arrays by KDR
	SortCustom1D(arrayTeams[TERRORIST_INDEX], teamCount[TERRORIST_INDEX], SortKDR);
	SortCustom1D(arrayTeams[COUNTER_TERRORIST_INDEX], teamCount[COUNTER_TERRORIST_INDEX], SortKDR);
	
	// If there is only one person on the winning team there is not much we can do to fix the situation
	if(teamCount[GetTeamIndex(whoWonLast)] <= 1  && !forceBalance)
	{
		return false;
	}
		
	// Decide how many people to switch
	if(teamCount[GetTeamIndex(whoWonLast)] - GetConVarInt(g_CvarSingleMax) <= 0)
	{
		numPlayers = 1;
	} else {
		numPlayers = ((teamCount[GetTeamIndex(whoWonLast)] - GetConVarInt(g_CvarSingleMax)) / GetConVarInt(g_CvarIncrement)) + 1;
	}
	
	if(teamCount[GetTeamIndex(whoWonLast)] - teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))] > numPlayers)
	{
		numPlayers = teamCount[GetTeamIndex(whoWonLast)] - teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))];
	}

	// The first player available for switching.  1 is the second best player on the team
	clientToSwitch = 1;

	// Check to make sure the switches we are doing are going to be positive changes
	new goodPlayers = 0;
	bottomPlayer = teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))] - 1;
	new Float:lowKDR = GetKDR(arrayTeams[GetTeamIndex(GetOtherTeam(whoWonLast))][bottomPlayer]);
	for(new i = 0; i < numPlayers; i++)
	{
		if(GetKDR(arrayTeams[GetTeamIndex(whoWonLast)][i + clientToSwitch]) > lowKDR)
		{
			goodPlayers++;
			if(bottomPlayer > 0)
			{
				bottomPlayer--;
				lowKDR = GetKDR(arrayTeams[GetTeamIndex(GetOtherTeam(whoWonLast))][bottomPlayer]);
			}
		}
	}
	
	// goodPlayers now contains a revised number of players to switch
	// if it is 0 than the teams are as balanced as possible without stacking
	numPlayers = goodPlayers;
	
	// check to make sure the winning team isn't significantly larger
	new minPlayers = RoundToCeil(float(teamCount[GetTeamIndex(whoWonLast)] - teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))]) / 2.0);
	if(numPlayers < minPlayers)
	{
		numPlayers = minPlayers;
	}

	if(numPlayers == 0 && !forceBalance)
	{
		return false;
	}
	
	// Set the switchArray to switched for all indexes after the last player
	for(new i = teamCount[GetTeamIndex(whoWonLast)]; i < MAXPLAYERS; i++)
	{
		switchArray[i] = 1;
	}
	
	// If admin immunity is one make admins immune
	for(new i = 0; i < teamCount[GetTeamIndex(whoWonLast)]; i++)
	{
		if(GetConVarBool(g_CvarAdminImmunity) && IsAdmin(arrayTeams[GetTeamIndex(whoWonLast)][i]))
		{
			switchArray[i] = 1;
		}
	}
	
	// Do the team switching
	new found = true;
	new switched = 0;
	for(new i = 0; i < numPlayers; i++)
	{
		// If we have already switched this player we need to switch someone else
		// so we keep getting the next lowest player until we find someone we have not switched
		while(switchArray[clientToSwitch] && found)
		{
			if(clientToSwitch < teamCount[GetTeamIndex(whoWonLast)] - 1)
			{
				clientToSwitch++;
			} else {
				clientToSwitch = 1;
			}
			if(GetConVarBool(g_CvarAdminImmunity))
			{
				found = false;
				for(new player = 1; player < MAXPLAYERS; player++)
				{
					if(switchArray[player] == 0)
					{
						found = true;
					}
				}
			}	
		}
			
		// Switch the team of the player on the winning team
		if(found)
		{
			SwitchTeam(arrayTeams[GetTeamIndex(whoWonLast)][clientToSwitch], GetOtherTeam(whoWonLast));
			switchArray[clientToSwitch] = 1;
			GetClientName(arrayTeams[GetTeamIndex(whoWonLast)][clientToSwitch], buffer, 30);
			switched++;
		
			// Decide who to switch next
			if(i % 2)
			{
				clientToSwitch -= GetConVarInt(g_CvarIncrement) - 1;
			} else {
				clientToSwitch += GetConVarInt(g_CvarIncrement);
			}
			
			if(clientToSwitch >= GetMaxClients()  || clientToSwitch <= 0)
			{
				clientToSwitch = 1;
			}
		}
	}
	
	// Find the worst player on the losing team
	bottomPlayer = teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))] - 1;
	
	// Adjust the team count for how many people were switched
	teamCount[GetTeamIndex(whoWonLast)] -= switched;
	teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))] += switched;
	
	// We remove the worse players from losing team to make the losing team no more than 
	// one client larger than the winning team.
	while(teamCount[GetTeamIndex(whoWonLast)] + 1 < teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))] && bottomPlayer >= 0)
	{
		if(!(GetConVarBool(g_CvarAdminImmunity) && IsAdmin(arrayTeams[GetTeamIndex(GetOtherTeam(whoWonLast))][bottomPlayer])))
		{
			SwitchTeam(arrayTeams[GetTeamIndex(GetOtherTeam(whoWonLast))][bottomPlayer], whoWonLast);
			teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))]--;
			teamCount[GetTeamIndex(whoWonLast)]++;
		}
		bottomPlayer--;
	}
	
	g_balancedLast = roundNum;
	return true;
}

// Finds the other team
// Accepts an index or a team
public GetOtherTeam(team)
{
	switch(team)
	{
		case 0:
			return 1;
		case 1:
			return 0;
		case 2:
			return 3;
		case 3:
			return 2;
	}
	return -1;
}

// Given a team id returns the matching index
public GetTeamIndex(team)
{
	return team - 2;
}

// The comparison function used in the sort routine in balance teams
// Use to sort an array of clients by KDR
public SortKDR(elem1, elem2, const array[], Handle:hndl)
{
	if(GetKDR(elem1) > GetKDR(elem2))
	{
		return -1;
	} else if(GetKDR(elem1) == GetKDR(elem2)) {
		return 0;
	} else {
		return 1;
	}
}

// Switches the team of a client and associated a random player model
// Also sends a message to let the player know they have been switched
// Based on the team switch command from SM Super Commands by pRED*
public SwitchTeam(client, team)
{
	// If the player has the bomb we need to drop it
	new bomb;
	bomb = GetPlayerWeaponSlot(client, 4);
	if(bomb != -1 && bomb)
	{
		SDKCall(weaponDrop, client, bomb, false, false);
	}
	
	// Switch the players team
	SDKCall(switchTeam, client, team);
	
	// Set a random model
	new random = GetRandomInt(0, 3);
	if(team == TERRORIST_TEAM)
	{
		SDKCall(setModel, client, tModels[random]);
		PrintCenterText(client, "%t", "t switch");
	} else if(team == COUNTER_TERRORIST_TEAM) {
		SDKCall(setModel, client, ctModels[random]);
		PrintCenterText(client, "%t", "ct switch");
	}
	
	// Respawn the player so they end up back at their own spawn point
	SDKCall(roundRespawn, client);
}

// Swaps the entirety of one team to another
public Action:CommandTeamSwap(client, args)
{
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) == TERRORIST_TEAM || GetClientTeam(i) == COUNTER_TERRORIST_TEAM))
		{
			SwitchTeam(i, GetOtherTeam(GetClientTeam(i)));
		}
	}
	return Plugin_Handled;
}

// Here we get a handle to the database and create it if it doesn't already exist
public InitializeStats()
{
	new String:error[255];
	decl String:connection[50];
	
	// g_CvarDatabase stores the default connection profile
	GetConVarString(g_CvarDatabase, connection, sizeof(connection));
	
	if(StrEqual(connection, ""))
	{
		// if connection is "" then we use the legacy sqlite db
		sqlTeamBalanceStats = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "team_balance", error, sizeof(error), true, 0);
	} else {
		// otherwise we use the record from the configuration
		sqlTeamBalanceStats = SQL_Connect(connection, true, error, sizeof(error)); 
	}
	if(sqlTeamBalanceStats == INVALID_HANDLE)
	{
		SetFailState(error);
	}
	
	decl String:driver[30];
	SQL_ReadDriver(sqlTeamBalanceStats, driver, sizeof(driver));
	if(StrEqual(driver, "sqlite"))
	{
		g_dbType = SQLITE;
	} else if(StrEqual(driver, "mysql")) {
		g_dbType = MYSQL;
	} else {
		SetFailState("Only MySQL and SQLite are currently supported");
	}
		
	SQL_LockDatabase(sqlTeamBalanceStats);
	if(g_dbType == SQLITE)
	{
		SQL_FastQuery(sqlTeamBalanceStats, "CREATE TABLE IF NOT EXISTS stats (steam_id TEXT, kills INTEGER, deaths INTEGER, kdr REAL, timestamp INTEGER);");
		SQL_FastQuery(sqlTeamBalanceStats, "CREATE UNIQUE INDEX IF NOT EXISTS stats_steam_id on stats (steam_id);");
	} else {
		SQL_FastQuery(sqlTeamBalanceStats, "CREATE TABLE IF NOT EXISTS stats (steam_id VARCHAR(50), kills INTEGER, deaths INTEGER, kdr FLOAT, timestamp INTEGER, PRIMARY KEY(steam_id));");
		if(SQL_GetError(sqlTeamBalanceStats, error, sizeof(error)))
		{
			SetFailState(error);
		}
	}
	SQL_UnlockDatabase(sqlTeamBalanceStats);
}

// Load the stats for a given client
public LoadStats(client)
{
	if(!client)
	{
		return;
	}
		
	new String:steamId[20];
	GetSteamId(client, steamId, sizeof(steamId));

	decl String:buffer[200];
	Format(buffer, sizeof(buffer), "SELECT kills, deaths, kdr, timestamp FROM stats WHERE steam_id = '%s'", steamId);
	SQL_TQuery(sqlTeamBalanceStats, LoadStatsCallback, buffer, client);
}

public LoadStatsCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogError("Update Stats SQL Error: %s", error);
		return;
	}
	
	new client = data;
	if(SQL_FetchRow(hndl))
	{
		if(SQL_FetchInt(hndl, 3) > GetTime() - GetConVarInt(g_CvarSaveTime) * 3600)
		{
			playerStats[client][KILLS] = SQL_FetchInt(hndl, 0);
			playerStats[client][DEATHS] = SQL_FetchInt(hndl, 1);
			return;
		}
	}
	playerStats[client][DEATHS] = 0;
	playerStats[client][KILLS] = 0;
}

// Updates the database for a single client
public UpdateStats(client)
{
	new String:steamId[20];
	new String:buffer[255];
	
	if(IsClientInGame(client))
	{
		GetSteamId(client, steamId, sizeof(steamId));

		Format(buffer, sizeof(buffer), "REPLACE INTO stats VALUES ('%s', %i, %i, %f, %i)", steamId, playerStats[client][KILLS], playerStats[client][DEATHS], GetKDR(client), GetTime());
		SQL_TQuery(sqlTeamBalanceStats, SQLErrorCheckCallback, buffer);
	}
}

// This is used during a threaded query that does not return data
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
	{
		LogError("Team Balance SQl Error: %s", error);
	}
}


// We actually want to track bot stats for our purposes
// so we give them fake steam id's
public GetSteamId(client, String:buffer[], bufferSize)
{
	if(!client)
	{
		return;
	}
		
	if(IsFakeClient(client))
	{
		GetClientName(client, buffer, bufferSize);
		return;
	}
	GetClientAuthString(client, buffer, bufferSize);
}

// I couldn't find a way to print a localized message to everyone
// so I wrote my own
public PrintTranslatedToChatAll(String:buffer[])
{
	// Print the message to all clients if g_CvarAnnounce is enabled
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			PrintToChat(i, "\x04[TEAM BALANCE]:%t", buffer);
		}
	}
}

// The initializations typically done in OnMapStart()
public MapStartInitializations()
{
	whoWonLast = NO_TEAM;
	teamInfo[TERRORIST_INDEX][CONSECUTIVE_WINS] = 0;
	teamInfo[TERRORIST_INDEX][ROUND_SWITCH] = 0;
	teamInfo[COUNTER_TERRORIST_INDEX][CONSECUTIVE_WINS] = 0;
	teamInfo[COUNTER_TERRORIST_INDEX][ROUND_SWITCH] = 0;
	for(new i = 0; i < ROUNDS_TO_SAVE; i++)
	{
		roundStats[COUNTER_TERRORIST_INDEX][i] = 0;
		roundStats[TERRORIST_INDEX][i] = 0;
	}
	roundNum = 1;
	balanceTeams = false;
	g_balancedLast = 0;
	Prune();
}

// Once the configs have executed we register the admin commands if appropriate
public OnConfigsExecuted()
{
	GetConVarString(g_CvarAdminFlags, g_adminFlags, sizeof(g_adminFlags));
	
	if(GetConVarBool(g_CvarCommands) && !g_commandsHooked)
	{
		RegAdminCmd("sm_swapteams", CommandTeamSwap, ADMFLAG_GENERIC);
		RegAdminCmd("sm_teamswitch", CommandTeamSwitch, ADMFLAG_GENERIC);
		g_commandsHooked = true;
	}
}

public Action:CommandTeamSwitch(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_teamswitch <player>");
		return Plugin_Handled;
	}

	new target;
	decl String:buffer[50];
	GetCmdArg(1, buffer, sizeof(buffer));	
	target = FindTarget(client, buffer, false, false);
	if(target && target != -1 && (GetClientTeam(target) == TERRORIST_TEAM || GetClientTeam(target) == COUNTER_TERRORIST_TEAM))
	{
		SwitchTeam(target, GetOtherTeam(GetClientTeam(target)));
	}

	return Plugin_Handled;
}

// We are hooking "jointeam" to manage the team joins
// we try to return plugin continue and let it do its thing if at all possible
public Action:CommandJoinTeam(client, args)
{
	if(!GetConVarBool(g_CvarControlJoins))
	{
		return Plugin_Continue;
	}

	if(args != 1)
	{
		return Plugin_Continue;
	}

	if(GetConVarBool(g_CvarJoinImmunity) && IsAdmin(client))
	{
		return Plugin_Continue;
	}

	decl String:teamString[3];
	GetCmdArg(1, teamString, sizeof(teamString));
	new team = StringToInt(teamString);
	
	// we need the players current team
	new curTeam = GetClientTeam(client);
	
	// Check for join spectator not allowed
	if(curTeam > 1 && team == 1 && GetConVarBool(g_CvarStopSpec))
	{
		PrintCenterText(client, "Only players who have not joined a team may spectate");
		return Plugin_Handled;
	}
	
	// Check for team locking concerns
	if(curTeam != 0 && GetConVarBool(g_CvarLockTeams) && team != 1 && g_teamList[client])
	{
		// if autojoin force them back onto their team
		if(team == 0)
		{
			ChangeClientTeam(client, g_teamList[client]);
			return Plugin_Handled;
		}
		
		// check to see if the team they are switching to is the same as their assigned team
		if(team != g_teamList[client])
		{
			PrintCenterText(client, "You cannot join that team");
			return Plugin_Handled;
		}
		
		// if we get to here it is safe
		return Plugin_Continue;
	}

	// We only want to get in the way of people joining these teams
	if(team != TERRORIST_TEAM && team != COUNTER_TERRORIST_TEAM)
	{
		return Plugin_Continue;
	}
	
	// Count the team sizes
	new teamCount[2];
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && (GetClientTeam(i) == TERRORIST_TEAM || GetClientTeam(i) == COUNTER_TERRORIST_TEAM))
		{
			teamCount[GetTeamIndex(GetClientTeam(i))]++;
		}
	}
	if(teamCount[GetTeamIndex(TERRORIST_TEAM)] > teamCount[GetTeamIndex(COUNTER_TERRORIST_TEAM)])
	{
		// The terrorist team is bigger so joining the CT's is fine
		if(team == COUNTER_TERRORIST_TEAM)
		{
			return Plugin_Continue;
		}
		
		if(curTeam == COUNTER_TERRORIST_TEAM)
		{
			PrintCenterText(client, "You are not allowed to join the stronger team");
			return Plugin_Handled;
		}
		PrintCenterText(client, "The admin is joining you to the Counter-Terrorist team");
		ChangeClientTeam(client, 3);
		return Plugin_Handled;
	} else if(teamCount[GetTeamIndex(TERRORIST_TEAM)] < teamCount[GetTeamIndex(COUNTER_TERRORIST_TEAM)]) {
		// The counter terrorist team is bigger so joining the T's is fine
		if(team == TERRORIST_TEAM)
		{
			return Plugin_Continue;
		}
		
		if(curTeam == TERRORIST_TEAM)
		{
			PrintCenterText(client, "You are not allowed to join the stronger team");
			return Plugin_Handled;
		}
		PrintCenterText(client, "The admin is joining you to the Terrorist team");
		ChangeClientTeam(client, 2);
		return Plugin_Handled;
	} else {
		// The teams are equal
		
		// if they are already on an existing team than they can't switch
		if(curTeam == TERRORIST_TEAM || curTeam == COUNTER_TERRORIST_TEAM)
		{
			PrintCenterText(client, "You are not allowed to switch to the other team right now");
			return Plugin_Handled;
		}

		// The teams are equal and we don't enough stats to know what it up so let them do what they want
		if(roundNum <= 2)
		{
			return Plugin_Continue;
		}
					
		// Count up the times the CT's have one in the last x rounds
		new ctWins;
		for(new i = 1; i <= 2; i++) {
			ctWins += roundStats[GetTeamIndex(COUNTER_TERRORIST_TEAM)][(roundNum - i) % ROUNDS_TO_SAVE];
		}
		
		// if the CT's are winning and the player is trying to join the CT's...they can't
		if(ctWins == 2 && team == 3)
		{
			PrintCenterText(client, "The admin is joining you to the Terrorist team");
			ChangeClientTeam(client, 2);
			return Plugin_Handled;
		}
			
		// If the T's are winning and the player is trying to join the CT team....he's screwed
		if(ctWins == 0 && team == 2)
		{
			PrintCenterText(client, "The admin is joining you to the Counter-Terrorist team");
			ChangeClientTeam(client, 3);
			return Plugin_Handled;
		}
		return Plugin_Continue;
	}
}

public Action:TeamManagementMenu(client, args)
{
	new Handle:menu = CreateMenu(TeamManagementMenuHandler);
	decl String:buffer[100];
	Format(buffer, sizeof(buffer), "%T", "team management menu", client);
	SetMenuTitle(menu, buffer);
	
	Format(buffer, sizeof(buffer), "%T", "swap teams", client);
	AddMenuItem(menu, "team menu item", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "switch player", client);
	AddMenuItem(menu, "team menu item", buffer);
	
	Format(buffer, sizeof(buffer), "%T", "switch player next", client);
	AddMenuItem(menu, "team menu item", buffer);
	
	if(GetConVarBool(g_CvarMaintainSize))
	{
		Format(buffer, sizeof(buffer), "%T", "maintain size off", client);
	} else {
		Format(buffer, sizeof(buffer), "%T", "maintain size on", client);
	}
	AddMenuItem(menu, "team menu item", buffer);
	
	if(GetConVarBool(g_CvarControlJoins))
	{
		Format(buffer, sizeof(buffer), "%T", "control joins off", client);
	} else {
		Format(buffer, sizeof(buffer), "%T", "control joins on", client);
	}
	AddMenuItem(menu, "team menu item", buffer);
	
	if(GetConVarBool(g_CvarEnabled))
	{
		Format(buffer, sizeof(buffer), "%T", "disable balancer", client);
	} else {
		Format(buffer, sizeof(buffer), "%T", "enable balancer", client);
	}
	AddMenuItem(menu, "team menu item", buffer);

	Format(buffer, sizeof(buffer), "%T", "display stats", client);
	AddMenuItem(menu, "team menu item", buffer);

	Format(buffer, sizeof(buffer), "%T", "dump settings", client);
	AddMenuItem(menu, "team menu item", buffer);
	
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 20);
 
	return Plugin_Handled;
}

//  This handles the selling
public TeamManagementMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)	{
		switch(param2)
		{
			// swap teams
			case 0:
			{
				CommandTeamSwap(param1, 0);
			}
			// switch player
			case 1:
			{
				SwitchPlayerMenu(param1);
				return;
			}
			// switch next round
			case 2:
			{
				SwitchPlayerMenu(param1, true);
				return;
			}
			// maintain size
			case 3:
			{
				SetConVarBool(g_CvarMaintainSize, FlipBool(GetConVarBool(g_CvarMaintainSize)));
			}
			// control joins
			case 4:
			{
				SetConVarBool(g_CvarControlJoins, FlipBool(GetConVarBool(g_CvarControlJoins)));
			}
			// disable/enable
			case 5:
			{
				SetConVarBool(g_CvarEnabled, FlipBool(GetConVarBool(g_CvarEnabled)));
			}
			// display stats
			case 6:
			{
				CommandKDR(param1, 0);
				return;
			}
			// dump settings
			case 7:
			{
				CommandDump(param1, 0);
			}
		}
		TeamManagementMenu(param1, 0);
	} else if(action == MenuAction_End)	{
		CloseHandle(menu);
	}
}

// Flips a bool
public bool:FlipBool(bool:current)
{
	if(current)
		return false;
	else
		return true;
}

SwitchPlayerMenu(client, bool:nextRound = false)
{
	new Handle:menu = CreateMenu(SwitchPlayerMenuHandler);
	decl String:buffer[100];
	decl String:clientString[4];
	if(nextRound)
	{
		Format(buffer, sizeof(buffer), "%T", "switch player next", client);
	} else {
		Format(buffer, sizeof(buffer), "%T", "switch player", client);
	}
	SetMenuTitle(menu, buffer);
	
	for(new i = 1; i <= GetMaxClients(); i++)
	{
		if(IsClientInGame(i) && GetClientTeam(i) > 1)
		{
			IntToString(i, clientString, sizeof(clientString));
			GetClientName(i, buffer, sizeof(buffer));
			if(nextRound)
			{
				Format(clientString, sizeof(clientString), "N%s", clientString);
			}
			AddMenuItem(menu, clientString, buffer);
		}
	}
	
	SetMenuExitButton(menu, true);

	DisplayMenu(menu, client, 20);
 
	return;
}

public SwitchPlayerMenuHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		new bool:nextRound = false;
		decl String:playerString[4];
		decl player;
		GetMenuItem(menu, param2, playerString, sizeof(playerString));
		if(playerString[0] == 'N')
		{
			nextRound = true;
			player = StringToInt(playerString[1]);
		} else {
			player = StringToInt(playerString);
		}
		if(player && IsClientInGame(player) && GetClientTeam(player) > 1)
		{
			if(nextRound)
			{
				g_switchNextRound[player] = true;
			} else {
				SwitchTeam(player, GetOtherTeam(GetClientTeam(player)));
			}
		}
		SwitchPlayerMenu(param1, nextRound);
	} else if(action == MenuAction_End)	{
		CloseHandle(menu);
	}
}

public Action:CommandKDR(client, args)
{
	if(client && IsClientInGame(client))
	{
		KDRPanel(client, 1);
	}
	
	return Plugin_Handled;
}

public Float:GetKDR(client)
{
	if(!client || !IsClientInGame(client))
	{
		return 0.0;
	}
	
	if(playerStats[client][KILLS] + playerStats[client][DEATHS] >= GetConVarInt(g_CvarMinKills)) {
		// Check for div by 0
		if(playerStats[client][DEATHS])
		{
			return float(playerStats[client][KILLS]) / float(playerStats[client][DEATHS]);
		} else {
			return float(playerStats[client][KILLS]);
		}
	}
	
	return GetConVarFloat(g_CvarDefaultKDR);
}

public KDRPanel(client, panelNumber)
{
	new Handle:panel = CreatePanel();
	decl String:buffer[512];
	Format(buffer, sizeof(buffer), "%T", "kdr panel", client);
	SetPanelTitle(panel, buffer);
	
	Format(buffer, sizeof(buffer), "%T\n", "internal stats", client);
	for(new i = 0 + (panelNumber - 1) * STATS_PER_PANEL; i < STATS_PER_PANEL * panelNumber; i++)
	{
		if(i < g_playerCount)
		{
			Format(	buffer,
					sizeof(buffer),
					"%s%i: %s - Kills: %i Deaths: %i KDR: %.2f\n",
					buffer,
					i + 1,
					g_playerListNames[i],
					playerStats[g_playerList[i]][KILLS],
					playerStats[g_playerList[i]][DEATHS],
					GetKDR(g_playerList[i]));
		}
	}
	
	DrawPanelItem(panel, buffer);
	if(panelNumber > 1)
	{
 		SetPanelCurrentKey(panel, 8);
 		DrawPanelItem(panel, "Previous");
	}		

 	if(panelNumber * STATS_PER_PANEL < GetClientCount())
 	{
 		SetPanelCurrentKey(panel, 9);
 		DrawPanelItem(panel, "Next");
 	}
	g_panelPos[client] = panelNumber;
 	
 	// Add an exit button
 	SetPanelCurrentKey(panel, 10);
 	DrawPanelItem(panel, "Exit");
	SendPanelToClient(panel, client, KDRPanelHandler, 20);

 
	CloseHandle(panel);
}

public KDRPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 8:
				KDRPanel(param1, g_panelPos[param1] - 1);
			case 9:
				KDRPanel(param1, g_panelPos[param1] + 1);
		}
	}
}

public Action:CommandDump(client, args)
{
	decl String:buffer[250];
	
	GetConVarString(g_CvarVersion, buffer, sizeof(buffer));
	ReplyToCommand(client, "sm_team_balance_version: %s", buffer);
	ReplyToCommand(client, "sm_team_balance_enable: %i", GetConVarInt(g_CvarEnabled));
	ReplyToCommand(client, "sm_team_balance_min_kd: %i", GetConVarInt(g_CvarMinKills));
	ReplyToCommand(client, "sm_team_balance_announce: %i", GetConVarInt(g_CvarAnnounce));
	ReplyToCommand(client, "sm_team_balance_consecutive_wins: %i", GetConVarInt(g_CvarConsecutiveWins));
	ReplyToCommand(client, "sm_team_balance_wlr: %f", GetConVarFloat(g_CvarWinLossRatio));
	ReplyToCommand(client, "sm_team_balance_new_join_rounds: %i", GetConVarInt(g_CvarRoundsNewJoin));
	ReplyToCommand(client, "sm_team_balance_min_rounds: %i", GetConVarInt(g_CvarMinRounds));
	ReplyToCommand(client, "sm_team_balance_save_time: %i", GetConVarInt(g_CvarSaveTime));
	ReplyToCommand(client, "sm_team_balance_def_kdr: %f", GetConVarFloat(g_CvarDefaultKDR));
	ReplyToCommand(client, "sm_team_balance_increment: %i", GetConVarInt(g_CvarIncrement));
	ReplyToCommand(client, "sm_team_balance_single_max: %i", GetConVarInt(g_CvarSingleMax));
	ReplyToCommand(client, "sm_team_balance_commands: %i", GetConVarInt(g_CvarCommands));
	ReplyToCommand(client, "sm_team_balance_maintain_size: %i", GetConVarInt(g_CvarMaintainSize));
	ReplyToCommand(client, "sm_team_balance_control_joins: %i", GetConVarInt(g_CvarControlJoins));
	GetConVarString(g_CvarDatabase, buffer, sizeof(buffer));
	ReplyToCommand(client, "sm_team_balance_database: %s", buffer);
	ReplyToCommand(client, "sm_team_balance_join_immunity: %i", GetConVarInt(g_CvarJoinImmunity));
	ReplyToCommand(client, "sm_team_balance_admin_immunity: %i", GetConVarInt(g_CvarAdminImmunity));
	GetConVarString(g_CvarAdminFlags, buffer, sizeof(buffer));
	ReplyToCommand(client, "sm_team_balance_admin_flags: %s", buffer);
	ReplyToCommand(client, "sm_team_balance_min_balance_frequency: %i", GetConVarInt(g_CvarMinBalance));
	ReplyToCommand(client, "sm_team_balance_lock_teams: %i", GetConVarInt(g_CvarLockTeams));
	ReplyToCommand(client, "sm_team_balance_lock_time: %i", GetConVarInt(g_CvarLockTime));
	ReplyToCommand(client, "sm_team_balance_stop_spec: %i", GetConVarInt(g_CvarStopSpec));

	return Plugin_Handled;
}

public Action:CommandSet(client, args)
{
	if(args != 3)
	{
		ReplyToCommand(client, "Usage: sm_tbset <player> <kills> <deaths>");
		return Plugin_Handled;
	}

	new target, kills, deaths;
	decl String:buffer[50];
	GetCmdArg(1, buffer, sizeof(buffer));	
	target = FindTarget(client, buffer, false, false);
	GetCmdArg(2, buffer, sizeof(buffer));
	kills = StringToInt(buffer);
	GetCmdArg(3, buffer, sizeof(buffer));
	deaths = StringToInt(buffer);
	
	if(target && target != -1)
	{
		playerStats[target][KILLS] = kills;
		playerStats[target][DEATHS] = deaths;
		GetClientName(target, buffer, sizeof(buffer));
		ReplyToCommand(client, "Set %s's stats to kills: %i, deaths: %i", buffer, playerStats[target][KILLS], playerStats[target][DEATHS]);
	} else {
		ReplyToCommand(client, "Target not found");
	}

	return Plugin_Handled;
}

public Action:CommandStartSwitch(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_tbswitchatstart <player>");
		return Plugin_Handled;
	}

	new target;
	decl String:buffer[50];
	GetCmdArg(1, buffer, sizeof(buffer));	
	target = FindTarget(client, buffer, false, false);
	if(target && target != -1 && (GetClientTeam(target) == TERRORIST_TEAM || GetClientTeam(target) == COUNTER_TERRORIST_TEAM))
	{
		g_switchNextRound[target] = true;
	}

	return Plugin_Handled;
}

bool:IsAdmin(client)
{
	// Null admin flags means any admin is allowed for backwards compatability
	if(StrEqual(g_adminFlags, ""))
	{
		return GetUserAdmin(client) == INVALID_ADMIN_ID ? false : true;
	}
	
	return (GetUserFlagBits(client) & ReadFlagString(g_adminFlags)) ? true : false;
}

public AdminFlagsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_adminFlags, sizeof(g_adminFlags), newValue);
}

public Prune()
{
	KvRewind(g_kv);
	if (!KvGotoFirstSubKey(g_kv))
	{
		return;
	}

	for(;;)
	{
		if(GetTime() > KvGetNum(g_kv, "timestamp") + GetConVarInt(g_CvarLockTime))
		{
			if (KvDeleteThis(g_kv) < 1)
			{
				break;
			}
		} else if (!KvGotoNextKey(g_kv)) {
			break;
		}	
	}
}