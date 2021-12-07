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
*/


#include <sourcemod>
#include <sdktools>

#pragma semicolon 1

#define PLUGIN_VERSION "0.9beta"
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

#define ROUNDS_TO_SAVE 10

#define PENDING_MESSAGE 1
#define NOT_BALANCED_MESSAGE 2
#define BALANCED_MESSAGE 4
#define CANT_BALANCE_MESSAGE 8

// Plugin definitions
public Plugin:myinfo = 
{
	name = "Team Balance",
	author = "AMP",
	description = "Team Balancer Plugin",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net"
};

// Global Variables
new	Handle:cvarEnabled = INVALID_HANDLE;
new	Handle:cvarMinKills = INVALID_HANDLE;
new	Handle:cvarConsecutiveWins = INVALID_HANDLE;
new	Handle:cvarWinLossRatio = INVALID_HANDLE;
new	Handle:cvarRoundsNewJoin = INVALID_HANDLE;
new	Handle:cvarMinRounds = INVALID_HANDLE;
new	Handle:cvarSaveTime = INVALID_HANDLE;
new	Handle:cvarDefaultKDR = INVALID_HANDLE;
new	Handle:cvarAnnounce = INVALID_HANDLE;
new	Handle:cvarIncrement = INVALID_HANDLE;
new	Handle:cvarSingleMax = INVALID_HANDLE;
new	Handle:cvarCommands = INVALID_HANDLE;
new	Handle:cvarMaintainSize = INVALID_HANDLE;
new roundStats[NUM_TEAMS][ROUNDS_TO_SAVE];
new playerStats[MAXPLAYERS + 1][NUM_STATS];
new Float:playerKDR[MAXPLAYERS + 1];
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

// We need to capture if the plugin was late loaded so we can make sure initializations
// are handled properly
public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	lateLoaded = late;
	return true;
}

public OnPluginStart()
{
	// Before we do anything else lets make sure that the plugin is not disabled
	cvarEnabled = CreateConVar("sm_team_balance_enable", "1", "Enables the Team Balance plugin, when disabled the plugin will still collect stats");

	// Load the translations
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.teambalance");
	
	// Create the remainder of the CVARs
	CreateConVar("sm_team_balance_version", PLUGIN_VERSION, "Team Balance Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	cvarMinKills = CreateConVar("sm_team_balance_min_kd", "10", "The minimum number of kills + deaths in order to be given a real kdr");
	cvarAnnounce = CreateConVar("sm_team_balance_annouce", "15", "Announcement preferences");
	cvarConsecutiveWins = CreateConVar("sm_team_balance_consecutive_wins", "4", "The number of consecutive wins required to declare the teams unbalanced");
	cvarWinLossRatio = CreateConVar("sm_team_balance_wlr", "0.55", "The win loss ratio required to declare the teams unbalanced");
	cvarRoundsNewJoin = CreateConVar("sm_team_balance_new_join_rounds", "1", "The number of rounds to delay team balancing when a new player joins the losing team");
	cvarMinRounds = CreateConVar("sm_team_balance_min_rounds", "4", "The minimum number of rounds before the team balancer starts");
	cvarSaveTime = CreateConVar("sm_team_balance_save_time", "672", "The number of hours to save stats for");
	cvarDefaultKDR = CreateConVar("sm_team_balance_def_kdr", "1.0", "The default kdr used until a real kdr is established");
	cvarIncrement = CreateConVar("sm_team_balance_increment", "5", "The increment for which additional players are balanced");
	cvarSingleMax = CreateConVar("sm_team_balance_single_max", "6", "The maximimum number of players on a team for which a single player is balanced");
	cvarCommands = CreateConVar("sm_team_balance_commands", "0", "A flag to say whether the team commands will be enabled");
	cvarMaintainSize = CreateConVar("sm_team_balance_maintain_size", "0", "A flag to say if the team size should be maintained");
	
	// SDK Calls for team switching and model setting
	// taken from SM Super Commands by pRED*
	gameConf = LoadGameConfigFile("teambalance.games");
	if(gameConf == INVALID_HANDLE)
		SetFailState("gamedata/teambalance.games.txt not loadable");

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

	// if the plugin was loaded late we have a bunch of initialization that needs to be done
	if(lateLoaded) {
	    // First we need to do whatever we would have done at OnMapStart()
		MapStartInitializations();
			
		// Next we need to whatever we would have done as each client authorized
		new playersConnected = GetMaxClients();
		for(new i = 1; i < playersConnected; i++) {
			if(IsClientInGame(i))
				LoadStats(i);
		}
	}	    

}

// Map level initializations
public OnMapStart()
{
	MapStartInitializations();
}

// When a new client is authorized we check to see if
// they have data that needs to be loaded
public OnClientAuthorized(client, const String:auth[])
{
	LoadStats(client);
}

// When a user disconnects we need to put there stats into kvTDB
public OnClientDisconnect(client)
{
	UpdateStats(client);
}

// The death event tracks player stats
public EventPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victimId = GetEventInt(event, "userid");
	new attackerId = GetEventInt(event, "attacker");
	new attackerClient = GetClientOfUserId(attackerId);
	new victimClient = GetClientOfUserId(victimId);

	if(attackerClient) {
		playerStats[attackerClient][KILLS]++;
		if(playerStats[attackerClient][KILLS] + playerStats[attackerClient][DEATHS] >= GetConVarInt(cvarMinKills)) {
			// Check for div by 0
			if(playerStats[attackerClient][DEATHS])
				playerKDR[attackerClient] = float(playerStats[attackerClient][KILLS]) / float(playerStats[attackerClient][DEATHS]);
			else
				playerKDR[attackerClient] = float(playerStats[attackerClient][KILLS]);
		}
	}
	if(victimClient) {
		playerStats[victimClient][DEATHS]++;
		if(playerStats[victimClient][KILLS] + playerStats[victimClient][DEATHS] >= GetConVarInt(cvarMinKills))
			playerKDR[victimClient] = float(playerStats[victimClient][KILLS]) / float(playerStats[victimClient][DEATHS]);
	}
}

// The GetTeamBalance function tries to determine if the teams are currently balanced
public GetTeamBalance()
{
	// If there have not been enough rounds or there has not been a winner yet than the team balance is pending
	if(whoWonLast == NO_TEAM || roundNum < GetConVarInt(cvarMinRounds))
		return TEAM_BALANCE_PENDING;

	// Check to see if it is pending due to player join
	if(teamInfo[GetOtherTeam(GetTeamIndex(whoWonLast))][ROUND_SWITCH] > roundNum - GetConVarInt(cvarRoundsNewJoin))
		return TEAM_BALANCE_PENDING;

	// If the number of consecutive wins has been exceeded than the teams are not balanced
	if(teamInfo[GetTeamIndex(whoWonLast)][CONSECUTIVE_WINS] >= GetConVarInt(cvarConsecutiveWins))
		return TEAMS_UNBALANCED;
	
	// Check to see if we are below the minimum winn/loss ratio	
	if(float(teamInfo[GetOtherTeam(GetTeamIndex(whoWonLast))][TOTAL_WINS]) / float(teamInfo[GetTeamIndex(whoWonLast)][TOTAL_WINS]) < GetConVarFloat(cvarWinLossRatio))
		return TEAMS_UNBALANCED;

	// check to see if we need to rebalance the teams for size
	if(GetConVarBool(cvarMaintainSize)) {
		// Count the team sizes
		new teamCount[2];
		for(new i = 1; i <= GetMaxClients(); i++) {
			if(IsClientInGame(i) && (GetClientTeam(i) == TERRORIST_TEAM || GetClientTeam(i) == COUNTER_TERRORIST_TEAM)) {
				teamCount[GetTeamIndex(GetClientTeam(i))]++;
			}
		}
		if(teamCount[0] - teamCount[1] > 1 || teamCount[1] - teamCount[0] > 1) {
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
		return;
	
	// Make sure that the winner is not something strange
	if(winner != TERRORIST_TEAM && winner != COUNTER_TERRORIST_TEAM)
		return;
	
	// Update the map statistics
	roundStats[GetTeamIndex(winner)][roundNum % 10] = 1;
	// We need recent statistics for our win-loss-ratio comparison
	teamInfo[COUNTER_TERRORIST_INDEX][TOTAL_WINS] = 0;
	teamInfo[TERRORIST_INDEX][TOTAL_WINS] = 0;
	for(new i = 0; i < ROUNDS_TO_SAVE; i++) {
		teamInfo[COUNTER_TERRORIST_INDEX][TOTAL_WINS] += roundStats[COUNTER_TERRORIST_INDEX][i];
		teamInfo[TERRORIST_INDEX][TOTAL_WINS] += roundStats[TERRORIST_INDEX][i];
	}	

	// update whoWonLast and consecutive wins counts
	teamInfo[GetTeamIndex(winner)][CONSECUTIVE_WINS]++;
	if(whoWonLast != winner) {
		whoWonLast = winner;
		teamInfo[GetTeamIndex(GetOtherTeam(winner))][CONSECUTIVE_WINS] = 0;
	}
	
	if(GetConVarBool(cvarEnabled)) {
		// Check to see if the teams are in balance and take action as needed
		switch(GetTeamBalance())
		{
			case TEAM_BALANCE_PENDING: {
				if(GetConVarInt(cvarAnnounce) & PENDING_MESSAGE)
					PrintTranslatedToChatAll("pending");
			}
			case TEAMS_BALANCED: {
				if(GetConVarInt(cvarAnnounce) & BALANCED_MESSAGE)
					PrintTranslatedToChatAll("balanced");
			}
			case TEAMS_UNBALANCED: {
				if(GetConVarInt(cvarAnnounce) & NOT_BALANCED_MESSAGE)
					PrintTranslatedToChatAll("not balanced");
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
	if(team == COUNTER_TERRORIST_TEAM || team == TERRORIST_TEAM && IsClientInGame(client) && !IsFakeClient(client))
		teamInfo[GetTeamIndex(team)][ROUND_SWITCH] = roundNum;
}

public Action:EventRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if(balanceTeams) {
		if(!BalanceTeams() && GetConVarInt(cvarAnnounce) & CANT_BALANCE_MESSAGE)
			PrintTranslatedToChatAll("unbalanceable");
		balanceTeams = false;
		forceBalance = false;
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
	for(new i = 1; i <= GetMaxClients(); i++) {
		if(IsClientInGame(i) && (GetClientTeam(i) == TERRORIST_TEAM || GetClientTeam(i) == COUNTER_TERRORIST_TEAM)) {
			arrayTeams[GetTeamIndex(GetClientTeam(i))][teamCount[GetTeamIndex(GetClientTeam(i))]] = i;
			teamCount[GetTeamIndex(GetClientTeam(i))]++;
		}
	}
	
	// Sort the arrays by KDR
	SortCustom1D(arrayTeams[TERRORIST_INDEX], teamCount[TERRORIST_INDEX], SortKDR);
	SortCustom1D(arrayTeams[COUNTER_TERRORIST_INDEX], teamCount[COUNTER_TERRORIST_INDEX], SortKDR);
	
	if(IsPluginDebugging(GetMyHandle())) {
		for(new i = 0; i < teamCount[COUNTER_TERRORIST_INDEX]; i++) {
			GetClientName(arrayTeams[COUNTER_TERRORIST_INDEX][i], buffer, 30);
			PrintToChatAll("CT: %s - %f", buffer, playerKDR[arrayTeams[COUNTER_TERRORIST_INDEX][i]]);
		}
		for(new i = 0; i < teamCount[TERRORIST_INDEX]; i++) {
			GetClientName(arrayTeams[TERRORIST_INDEX][i], buffer, 30);
			PrintToChatAll("T: %s - %f", buffer, playerKDR[arrayTeams[TERRORIST_INDEX][i]]);
		}
	}
	
	// If there is only one person on the winning team there is not much we can do to fix the situation
	if(teamCount[GetTeamIndex(whoWonLast)] <= 1  && !forceBalance)
		return false;
		
	// Decide how many people to switch
	if(teamCount[GetTeamIndex(whoWonLast)] - GetConVarInt(cvarSingleMax) <= 0)
		numPlayers = 1;
	else
		numPlayers = ((teamCount[GetTeamIndex(whoWonLast)] - GetConVarInt(cvarSingleMax)) / GetConVarInt(cvarIncrement)) + 1;
	
	if(teamCount[GetTeamIndex(whoWonLast)] - teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))] > numPlayers)
		numPlayers = teamCount[GetTeamIndex(whoWonLast)] - teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))];

	// The first player available for switching.  1 is the second best player on the team
	clientToSwitch = 1;

	// Check to make sure the switches we are doing are going to be positive changes
	new goodPlayers = 0;
	bottomPlayer = teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))] - 1;
	new Float:lowKDR = playerKDR[arrayTeams[GetTeamIndex(GetOtherTeam(whoWonLast))][bottomPlayer]];
	for(new i = 0; i < numPlayers; i++) {
		if(playerKDR[arrayTeams[GetTeamIndex(whoWonLast)][i + clientToSwitch]] > lowKDR) {
			goodPlayers++;
			if(bottomPlayer > 0) {
				bottomPlayer--;
				lowKDR = playerKDR[arrayTeams[GetTeamIndex(GetOtherTeam(whoWonLast))][bottomPlayer]];
			}
		}
	}
	
	// goodPlayers now contains a revised number of players to switch
	// if it is 0 than the teams are as balanced as possible without stacking
	numPlayers = goodPlayers;
	
	// check to make sure the winning team isn't significantly larger
	new minPlayers = RoundToCeil(float(teamCount[GetTeamIndex(whoWonLast)] - teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))]) / 2.0);
	if(numPlayers < minPlayers)
		numPlayers = minPlayers;

	if(numPlayers == 0 && !forceBalance)
		return false;
	
	// Do the team switching
	for(new i = 0; i < numPlayers; i++) {
		// If we have already switched this player we need to switch someone else
		// so we keep getting the next lowest player until we find someone we have not switched
		while(switchArray[clientToSwitch])
			if(clientToSwitch < teamCount[GetTeamIndex(whoWonLast)])
				clientToSwitch++;
			else
				clientToSwitch = 1;
			
		// Switch the team of the player on the winning team
		SwitchTeam(arrayTeams[GetTeamIndex(whoWonLast)][clientToSwitch], GetOtherTeam(whoWonLast));
		switchArray[clientToSwitch] = 1;
		GetClientName(arrayTeams[GetTeamIndex(whoWonLast)][clientToSwitch], buffer, 30);
		
		// Decide who to switch next
		if(i % 2)
			clientToSwitch -= GetConVarInt(cvarIncrement) - 1;
		else
			clientToSwitch += GetConVarInt(cvarIncrement);
	}
	
	// Find the worst player on the losing team
	bottomPlayer = teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))] - 1;
	
	// Adjust the team count for how many people were switched
	teamCount[GetTeamIndex(whoWonLast)] -= numPlayers;
	teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))] += numPlayers;
	
	// We remove the worse players from losing team to make the losing team no more than 
	// one client larger than the winning team.
	while(teamCount[GetTeamIndex(whoWonLast)] + 1 < teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))])
	{
		GetClientName(arrayTeams[GetTeamIndex(GetOtherTeam(whoWonLast))][bottomPlayer], buffer, 30);
		SwitchTeam(arrayTeams[GetTeamIndex(GetOtherTeam(whoWonLast))][bottomPlayer], whoWonLast);
		bottomPlayer--;
		teamCount[GetTeamIndex(GetOtherTeam(whoWonLast))]--;
		teamCount[GetTeamIndex(whoWonLast)]++;
	}
	
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
	if(playerKDR[elem1] > playerKDR[elem2])
		return -1;
	else if(playerKDR[elem1] == playerKDR[elem2])
		return 0;
	else
		return 1;
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
		SDKCall(weaponDrop, client, bomb, false, false);
	
	// Switch the players team
	SDKCall(switchTeam, client, team);
	
	// Set a random model
	new random = GetRandomInt(0, 3);
	if(team == TERRORIST_TEAM) {
		SDKCall(setModel, client, tModels[random]);
		PrintCenterText(client, "%t", "t switch");
	}
	else if(team == COUNTER_TERRORIST_TEAM) {
		SDKCall(setModel, client, ctModels[random]);
		PrintCenterText(client, "%t", "ct switch");
	}
	
	// Respawn the player so they end up back at their own spawn point
	SDKCall(roundRespawn, client);
}

// Swaps the entirety of one team to another
public Action:CommandTeamSwap(client, args)
{
	new playersConnected = GetMaxClients();
	for(new i = 1; i <= playersConnected; i++) {
		if(IsClientInGame(i) && (GetClientTeam(i) == TERRORIST_TEAM || GetClientTeam(i) == COUNTER_TERRORIST_TEAM)) {
			SwitchTeam(i, GetOtherTeam(GetClientTeam(i)));
		}
	}
	return Plugin_Handled;
}

// Here we get a handle to the database and create it if it doesn't already exist
public InitializeStats()
{
	new String:error[255];
	sqlTeamBalanceStats = SQL_ConnectEx(SQL_GetDriver("sqlite"), "", "", "", "team_balance", error, sizeof(error), true, 0);
	if(sqlTeamBalanceStats == INVALID_HANDLE)
		SetFailState(error);
	SQL_LockDatabase(sqlTeamBalanceStats);
	SQL_FastQuery(sqlTeamBalanceStats, "CREATE TABLE IF NOT EXISTS stats (steam_id TEXT, kills INTEGER, deaths INTEGER, kdr REAL, timestamp INTEGER);");
	SQL_FastQuery(sqlTeamBalanceStats, "CREATE UNIQUE INDEX IF NOT EXISTS stats_steam_id on stats (steam_id);");
	SQL_UnlockDatabase(sqlTeamBalanceStats);
}

// Load the stats for a given client
public LoadStats(client)
{
	if(!client)
		return;
		
	new String:steamId[20];
	GetSteamId(client, steamId, sizeof(steamId));

	decl String:buffer[200];
	Format(buffer, sizeof(buffer), "SELECT kills, deaths, kdr, timestamp FROM stats WHERE steam_id = '%s'", steamId);
	SQL_TQuery(sqlTeamBalanceStats, LoadStatsCallback, buffer, client);
}

public LoadStatsCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error)) {
		LogError("Update Stats SQL Error: %s", error);
		return;
	}
	
	new client = data;
	if(SQL_FetchRow(hndl)) {
		if(SQL_FetchInt(hndl, 3) > GetTime() - GetConVarInt(cvarSaveTime) * 3600) {
			playerStats[client][KILLS] = SQL_FetchInt(hndl, 0);
			playerStats[client][DEATHS] = SQL_FetchInt(hndl, 1);
			playerKDR[client] = SQL_FetchFloat(hndl, 2);
		} else {
			playerStats[client][DEATHS] = 0;
			playerStats[client][KILLS] = 0;
			playerKDR[client] = GetConVarFloat(cvarDefaultKDR);
		}				
	}
	else {
		playerStats[client][DEATHS] = 0;
		playerStats[client][KILLS] = 0;
		playerKDR[client] = GetConVarFloat(cvarDefaultKDR);
	}
}

// Updates the database for a single client
public UpdateStats(client)
{
	new String:steamId[20];
	new String:buffer[255];
	
	if(IsClientInGame(client)) {
		GetSteamId(client, steamId, sizeof(steamId));

		Format(buffer, sizeof(buffer), "REPLACE INTO stats VALUES ('%s', %i, %i, %f, %i)", steamId, playerStats[client][KILLS], playerStats[client][DEATHS], playerKDR[client], GetTime());
		SQL_TQuery(sqlTeamBalanceStats, SQLErrorCheckCallback, buffer);
	}
}

// This is used during a threaded query that does not return data
public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:error[], any:data)
{
	if(!StrEqual("", error))
		LogError("Team Balance SQl Error: %s", error);
}


// We actually want to track bot stats for our purposes
// so we give them fake steam id's
public GetSteamId(client, String:buffer[], bufferSize)
{
	if(!client)
		return;
		
	if(IsFakeClient(client))
		GetClientName(client, buffer, bufferSize);
	else
		GetClientAuthString(client, buffer, bufferSize);
}

// I couldn't find a way to print a localized message to everyone
// so I wrote my own
public PrintTranslatedToChatAll(String:buffer[])
{
	// Print the message to all clients if cvarAnnounce is enabled
	new playersConnected = GetMaxClients();
	for(new i = 1; i <= playersConnected; i++) {
		if(IsClientInGame(i) && !IsFakeClient(i))
			PrintToChat(i, "\x04[TEAM BALANCE]:%t", buffer);
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
	for(new i = 0; i < ROUNDS_TO_SAVE; i++) {
		roundStats[COUNTER_TERRORIST_INDEX][i] = 0;
		roundStats[TERRORIST_INDEX][i] = 0;
	}
	roundNum = 1;
	balanceTeams = false;
}

// Once the configs have executed we register the admin commands if appropriate
public OnConfigsExecuted()
{
	if(GetConVarBool(cvarCommands)) {
		RegAdminCmd("sm_swapteams", CommandTeamSwap, ADMFLAG_GENERIC);
		RegAdminCmd("sm_teamswitch", CommandTeamSwitch, ADMFLAG_GENERIC);
	}
}

// This is called when the sm_last command is executed
public Action:CommandTeamSwitch(client, args)
{
	if(args != 1) {
		ReplyToCommand(client, "Usage: sm_teamswitch <player>");
		return Plugin_Handled;
	}

	new target;
	decl String:buffer[50];
	GetCmdArg(1, buffer, sizeof(buffer));	
	target = FindTarget(client, buffer, false, false);
	if(target && target != -1 && (GetClientTeam(target) == TERRORIST_TEAM || GetClientTeam(target) == COUNTER_TERRORIST_TEAM))
		SwitchTeam(target, GetOtherTeam(GetClientTeam(target)));

	return Plugin_Handled;
}