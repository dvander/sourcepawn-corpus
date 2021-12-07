/*
teambalance.sp

Description:
	Team Balance Plugin for SourceMod
	
Credits:
	The SwitchTeams() function and associated sdktools calls were taken from SM Super Commands by pRED*
	The WeaponDrop() stuff was taken from GunGame:SM by team06 - now replaced with SDKHooks_DropWeapon()
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
		* Added additional sError checking
		
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
		* Added team management hMenu
		* removed explicit KDR tracking
		* Added ability to get team balance stats
		* Fixed Native "GetPlayerWeaponSlot" reported: World not allowed..again
		
	2.0
		* Added MySQL support
		* Added admin command sm_tbdump
		* Added admin command sm_tbset
		* Added admin immunity for join control
		* Added admin immunity to the balancer
		* Added dump settings to team management hMenu
		* Added display stats to team management hMenu
		* Added fix for array out of bounds sError
		* Fixed Native "GetPlayerWeaponSlot" reported: World not allowed..for the third time
		* Increased the priority of sm_team_balance_maintain_size
		* If sm_team_balance_new_join_rounds = 0, the new join pending condition is ignored
		* Removed KDR display when debug is on
		* Changed the default value of sm_team_balance_min_rounds to 2
		* Fixed spelling of of sm_team_balance_announce
		
	2.1
		* Fixed a bug in the switch player hMenu
		* Moved the the default location of config file
		* Added a feature for switch at round end
		* Added !tbswitchatend, !tbtbswitchnow and !tbswap for consistency
		* Changed hMenu command to !tbmenu for consistency
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

	2.2.3
		* KkkkkkTzs fix bugg "Array index is out of bounds"
		* and fix two compiler warnings

	2.2.3b
		* KkkkkkTzs add sound and HintText for more Announce

	2.2.3c
		* KkkkkkTzs fix bugg MySql config not start up
		* and fix bugg "PrintHintText reported: Client x is not in game"
		
	2.2.4
		* Removed need for the SDKCalls SetModel, SetTeam, and roundRespawn
		
	2.3.0
		* Update designed to improve compatibility with CS:GO.
		  - Optimized plugin's usage of SteamIDs, Teams, & Names (cached values).
		  - Protected load query against disconnecting clients (pass userid vs client).
		  - Optimized several areas of code / fixed several logic flaws.
		  - Added protection against potential stat erasing under abnormal circumstances.
		  - Removed various comments throughout the code as they're distracting!
		  - Replaced depreciated ConnectCustom with SQLite_UseDatabase (should fix handle == 0 errors).
*/


#include <sourcemod>
#include <sdktools>
#include <sdkhooks>
#include <cstrike>

#pragma semicolon 1

#define PLUGIN_VERSION "2.2.5"
#define MAX_FILE_LEN 80

#define SOUND_CHANGE_TEAM	"npc/roller/mine/rmine_predetonate.wav"

#define KILLS 0
#define DEATHS 1
#define NUM_STATS 2

#define TEAMS_BALANCED 1
#define TEAMS_UNBALANCED 0
#define TEAM_BALANCE_PENDING 3

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

#define NOTIFY_SWITCH_DELAY 1.0

public Plugin:myinfo = 
{
	name = "Team Balance",
	author = "dalto, Twisted|Panda",
	description = "Team Balancer Plugin",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/"
};

new	Handle:g_hEnabled = INVALID_HANDLE;
new	Handle:g_hMinKills = INVALID_HANDLE;
new	Handle:g_hConsecutiveWins = INVALID_HANDLE;
new	Handle:g_hWinLossRatio = INVALID_HANDLE;
new	Handle:g_hRoundsNewJoin = INVALID_HANDLE;
new	Handle:g_hMinRounds = INVALID_HANDLE;
new	Handle:g_hSaveTime = INVALID_HANDLE;
new	Handle:g_hDefaultKDR = INVALID_HANDLE;
new	Handle:g_hAnnounce = INVALID_HANDLE;
new	Handle:g_hIncrement = INVALID_HANDLE;
new	Handle:g_hSingleMax = INVALID_HANDLE;
new	Handle:g_hCommands = INVALID_HANDLE;
new	Handle:g_hMaintainSize = INVALID_HANDLE;
new	Handle:g_hControlJoins = INVALID_HANDLE;
new	Handle:g_hDatabase = INVALID_HANDLE;
new	Handle:g_hJoinImmunity = INVALID_HANDLE;
new	Handle:g_hAdminImmunity = INVALID_HANDLE;
new	Handle:g_hMinBalance = INVALID_HANDLE;
new	Handle:g_hLockTeams = INVALID_HANDLE;
new	Handle:g_hStopSpec = INVALID_HANDLE;
new	Handle:g_hAdminFlags = INVALID_HANDLE;
new	Handle:g_hLockTime = INVALID_HANDLE;
new Handle:g_hConnection = INVALID_HANDLE;
new Handle:g_hTeamLocks = INVALID_HANDLE;
new g_iRoundStats[2][ROUNDS_TO_SAVE];
new g_iPlayerStats[MAXPLAYERS + 1][NUM_STATS];
new g_iTeamStats[2][NUM_TEAM_INFOS];

new g_iLastWinner, g_iCurrentRound, g_iPlayerCount, g_iDatabaseType, g_iLastBalance;
new bool:g_bBalanceTeams, bool:g_bLateLoad, bool:g_bForceBalance, bool:g_bHookedCommands;

new String:g_sAdminFlags[20];

new g_iPlayerList[MAXPLAYERS + 1];
new g_iPlayerTeam[MAXPLAYERS + 1];
new g_iTeamList[MAXPLAYERS + 1];
new g_iPanelPosition[MAXPLAYERS + 1];
new bool:g_bPlayerLoaded[MAXPLAYERS + 1];
new bool:g_switchNextRound[MAXPLAYERS + 1];
new String:g_sPlayerSteam[MAXPLAYERS + 1][32];
new String:g_sPlayerName[MAXPLAYERS + 1][32];

public APLRes:AskPluginLoad2(Handle:myself, bool:late, String:sError[], err_max)
{
	g_bLateLoad = late;
	return APLRes_Success;
}

public OnPluginStart()
{
	LoadTranslations("common.phrases");
	LoadTranslations("plugin.teambalance");
	CreateConVar("sm_team_balance_version", PLUGIN_VERSION, "Team Balance Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);

	g_hEnabled = CreateConVar("sm_team_balance_enable", "1", "Enables the Team Balance plugin, when disabled the plugin will still collect stats");
	g_hMinKills = CreateConVar("sm_team_balance_min_kd", "10", "The minimum number of kills + deaths in order to be given a real kdr");
	g_hAnnounce = CreateConVar("sm_team_balance_announce", "15", "Announcement preferences");
	g_hConsecutiveWins = CreateConVar("sm_team_balance_consecutive_wins", "4", "The number of consecutive wins required to declare the teams unbalanced");
	g_hWinLossRatio = CreateConVar("sm_team_balance_wlr", "0.55", "The win loss ratio required to declare the teams unbalanced");
	g_hRoundsNewJoin = CreateConVar("sm_team_balance_new_join_rounds", "0", "The number of rounds to delay team balancing when a new player joins the losing team");
	g_hMinRounds = CreateConVar("sm_team_balance_min_rounds", "2", "The minimum number of rounds before the team balancer starts");
	g_hSaveTime = CreateConVar("sm_team_balance_save_time", "672", "The number of hours to save stats for");
	g_hDefaultKDR = CreateConVar("sm_team_balance_def_kdr", "1.0", "The default kdr used until a real kdr is established");
	g_hIncrement = CreateConVar("sm_team_balance_increment", "5", "The increment for which additional players are balanced");
	g_hSingleMax = CreateConVar("sm_team_balance_single_max", "6", "The maximimum number of players on a team for which a single player is balanced");
	g_hCommands = CreateConVar("sm_team_balance_commands", "0", "A flag to say whether the team commands will be enabled");
	g_hMaintainSize = CreateConVar("sm_team_balance_maintain_size", "1", "A flag to say if the team size should be maintained");
	g_hControlJoins = CreateConVar("sm_team_balance_control_joins", "0", "If 1 this plugin fully manages who can join each team");
	g_hDatabase = CreateConVar("sm_team_balance_database", "", "The database configuration to use.  Empty for a local SQLite db");
	g_hJoinImmunity = CreateConVar("sm_team_balance_join_immunity", "0", "Set to 0 if admins should not be immune to join control");
	g_hAdminImmunity = CreateConVar("sm_team_balance_admin_immunity", "0", "0 to disable immunity.  WARNING: Enabling immunity SEVERELY limits the balancing algorithm");
	g_hMinBalance = CreateConVar("sm_team_balance_min_balance_frequency", "1", "This is the number of rounds to skip between balancing");
	g_hLockTeams = CreateConVar("sm_team_balance_lock_teams", "0", "Set to 1 if you want to force each player to stay in the teams assigned");
	g_hStopSpec = CreateConVar("sm_team_balance_stop_spec", "0", "Set to 1 if you don't want players who have already joined a team to be able to switch to spectator");
	g_hAdminFlags = CreateConVar("sm_team_balance_admin_flags", "", "The admin flags that admins who should have immunity must have one of");
	g_hLockTime = CreateConVar("sm_team_balance_lock_time", "15", "The number of minutes after disconnect before the team lock expires after disconnect");
	AutoExecConfig(true, "sm_teambalance");

	HookConVarChange(g_hAdminFlags, AdminFlagsChanged);

	HookEvent("player_death", Event_OnPlayerDeath);
	HookEvent("round_end", Event_OnRoundEnd);
	HookEvent("round_start", Event_OnRoundStart, EventHookMode_Pre);
	HookEvent("player_team", Event_OnPlayerTeam);
	HookEvent("player_changename", Event_OnPlayerName);
	RegConsoleCmd("jointeam", Command_Join);
	RegConsoleCmd("sm_tbstats", Command_Stats);

	RegAdminCmd("sm_tbmenu", TeamManagementMenu, ADMFLAG_CONVARS);
	RegAdminCmd("sm_tbdump", CommandDump, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tbset", CommandSet, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tbswitchatstart", CommandStartSwitch, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tbswitchnow", CommandTeamSwitch, ADMFLAG_GENERIC);
	RegAdminCmd("sm_tbswap", CommandTeamSwap, ADMFLAG_GENERIC);
	
	g_hTeamLocks = CreateKeyValues("LockExpiration");
}

public OnMapStart()
{
	PrecacheSound(SOUND_CHANGE_TEAM, true);
	decl String:sTemp[PLATFORM_MAX_PATH];
	Format(sTemp, PLATFORM_MAX_PATH, "sound/%s", SOUND_CHANGE_TEAM);
	AddFileToDownloadsTable(sTemp);

	MapStartInitializations();
}

public OnClientAuthorized(client, const String:auth[])
{
	if(client && IsClientInGame(client))
	{
		GetClientName(client, g_sPlayerName[client], sizeof(g_sPlayerName[]));
		if(IsFakeClient(client))
			strcopy(g_sPlayerSteam[client], sizeof(g_sPlayerSteam[]), g_sPlayerName[client]);
		else
			strcopy(g_sPlayerSteam[client], sizeof(g_sPlayerSteam[]), auth);
	}
}

public OnClientPostAdminCheck(client)
{
	if(client && !IsFakeClient(client) && IsClientInGame(client))
	{
		KvRewind(g_hTeamLocks);
		if(KvJumpToKey(g_hTeamLocks, g_sPlayerSteam[client]))
		{
			if(GetTime() < KvGetNum(g_hTeamLocks, "timestamp") + GetConVarInt(g_hLockTime) * 60)
			{
				g_iTeamList[client] = KvGetNum(g_hTeamLocks, "team", 0);
				return;
			}
		}

		g_iTeamList[client] = 0;
	}

	LoadClientStats(client);
}

public OnClientDisconnect(client)
{
	if(client && !IsFakeClient(client))
	{
		KvRewind(g_hTeamLocks);
		if(KvJumpToKey(g_hTeamLocks, g_sPlayerSteam[client], true))
		{
			KvSetNum(g_hTeamLocks, "team", g_iTeamList[client]);
			KvSetNum(g_hTeamLocks, "timestamp", GetTime());
		}
	}

	UpdateClientStats(client);
	g_bPlayerLoaded[client] = false;
}

public Action:Event_OnPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new victim = GetClientOfUserId(GetEventInt(event, "userid"));
	new attacker = GetClientOfUserId(GetEventInt(event, "attacker"));

	if(victim && IsClientInGame(victim))
		g_iPlayerStats[victim][DEATHS]++;

	if(attacker && attacker <= MaxClients && IsClientInGame(attacker))
		g_iPlayerStats[attacker][KILLS]++;

	return Plugin_Continue;
}


public Action:Event_OnPlayerName(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client))
		GetEventString(event, "newname", g_sPlayerName[client], sizeof(g_sPlayerName[]));
		
	return Plugin_Continue;
}

// The GetTeamBalance function tries to determine if the teams are currently balanced
public GetTeamBalance()
{
	// If there have not been enough rounds or there has not been a winner yet than the team balance is pending
	if(g_iLastWinner == -1 || g_iCurrentRound < GetConVarInt(g_hMinRounds) || g_iCurrentRound < g_iLastBalance + GetConVarInt(g_hMinBalance))
		return TEAM_BALANCE_PENDING;

	// check to see if we need to rebalance the teams for size
	if(GetConVarBool(g_hMaintainSize))
	{
		// Count the team sizes
		new teamCount[2];
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && (g_iPlayerTeam[i] == CS_TEAM_T || g_iPlayerTeam[i] == CS_TEAM_CT))
			{
				teamCount[GetTeamIndex(g_iPlayerTeam[i])]++;
			}
		}

		if(teamCount[0] - teamCount[1] > 1 || teamCount[1] - teamCount[0] > 1)
		{
			g_bForceBalance = true;
			return TEAMS_UNBALANCED;
		}
	}
	
	// Check to see if it is pending due to player join
	if(GetConVarInt(g_hRoundsNewJoin) && g_iTeamStats[GetOtherTeam(GetTeamIndex(g_iLastWinner))][ROUND_SWITCH] > g_iCurrentRound - GetConVarInt(g_hRoundsNewJoin))
	{
		return TEAM_BALANCE_PENDING;
	}

	// If the number of consecutive wins has been exceeded than the teams are not balanced
	if(g_iTeamStats[GetTeamIndex(g_iLastWinner)][CONSECUTIVE_WINS] >= GetConVarInt(g_hConsecutiveWins))
	{
		return TEAMS_UNBALANCED;
	}
	
	// Check to see if we are below the minimum winn/loss ratio	
	if(float(g_iTeamStats[GetOtherTeam(GetTeamIndex(g_iLastWinner))][TOTAL_WINS]) / float(g_iTeamStats[GetTeamIndex(g_iLastWinner)][TOTAL_WINS]) < GetConVarFloat(g_hWinLossRatio))
	{
		return TEAMS_UNBALANCED;
	}

	// check to see if we need to rebalance the teams for size
	if(GetConVarBool(g_hMaintainSize))
	{
		// Count the team sizes
		new teamCount[2];
		for(new i = 1; i <= MaxClients; i++)
		{
			if(IsClientInGame(i) && (g_iPlayerTeam[i] == CS_TEAM_T || g_iPlayerTeam[i] == CS_TEAM_CT))
			{
				teamCount[GetTeamIndex(g_iPlayerTeam[i])]++;
			}
		}
		if(teamCount[0] - teamCount[1] > 1 || teamCount[1] - teamCount[0] > 1)
		{
			g_bForceBalance = true;
			return TEAMS_UNBALANCED;
		}
	}
	
	// If we are not unbalanced or pending then we must be balanced
	return TEAMS_BALANCED;
}

public Event_OnRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	new winner = GetEventInt(event, "winner");
	new reason = GetEventInt(event, "reason");
	
	if(reason == 16 || (winner != CS_TEAM_T && winner != CS_TEAM_CT))
		return;

	// Update the map statistics
	g_iRoundStats[GetTeamIndex(winner)][g_iCurrentRound % ROUNDS_TO_SAVE] = 1;
	g_iRoundStats[GetTeamIndex(GetOtherTeam(winner))][g_iCurrentRound % ROUNDS_TO_SAVE] = 0;
	// We need recent statistics for our win-loss-ratio comparison
	g_iTeamStats[COUNTER_TERRORIST_INDEX][TOTAL_WINS] = 0;
	g_iTeamStats[TERRORIST_INDEX][TOTAL_WINS] = 0;
	for(new i = 0; i < ROUNDS_TO_SAVE; i++)
	{
		g_iTeamStats[COUNTER_TERRORIST_INDEX][TOTAL_WINS] += g_iRoundStats[COUNTER_TERRORIST_INDEX][i];
		g_iTeamStats[TERRORIST_INDEX][TOTAL_WINS] += g_iRoundStats[TERRORIST_INDEX][i];
	}	

	// update g_iLastWinner and consecutive wins counts
	g_iTeamStats[GetTeamIndex(winner)][CONSECUTIVE_WINS]++;
	if(g_iLastWinner != winner)
	{
		g_iLastWinner = winner;
		g_iTeamStats[GetTeamIndex(GetOtherTeam(winner))][CONSECUTIVE_WINS] = 0;
	}
	
	if(GetConVarBool(g_hEnabled))
	{
		// Check to see if the teams are in balance and take action as needed
		switch(GetTeamBalance())
		{
			case TEAM_BALANCE_PENDING:
			{
				if(GetConVarInt(g_hAnnounce) & PENDING_MESSAGE)
				{
					PrintTranslatedToChatAll("pending");
				}
			}
			case TEAMS_BALANCED:
			{
				if(GetConVarInt(g_hAnnounce) & BALANCED_MESSAGE)
				{
					PrintTranslatedToChatAll("balanced");
				}
			}
			case TEAMS_UNBALANCED:
			{
				if(GetConVarInt(g_hAnnounce) & NOT_BALANCED_MESSAGE)
				{
					PrintTranslatedToChatAll("not balanced");
				}
				g_bBalanceTeams = true;
			}
		}
	}
		
		
	g_iCurrentRound++;
}

public Action:Event_OnPlayerTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	if(client && IsClientInGame(client))
	{
		g_iPlayerTeam[client] = GetEventInt(event, "team");
		
		if(client && IsClientInGame(client) && !IsFakeClient(client))
		{
			if(g_iPlayerTeam[client] >= CS_TEAM_T)
			{
				g_iTeamStats[GetTeamIndex(g_iPlayerTeam[client])][ROUND_SWITCH] = g_iCurrentRound;
				g_iTeamList[client] = g_iPlayerTeam[client];
			}
		}
	}
	
	return Plugin_Continue;
}

public Action:Event_OnRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	g_iPlayerCount = 0;
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i))
		{
			g_iPlayerList[g_iPlayerCount++] = i;

			if(g_switchNextRound[i] && g_iPlayerTeam[i] >= CS_TEAM_T)
			{
				SwitchTeam(i, GetOtherTeam(g_iPlayerTeam[i]));
				g_switchNextRound[i] = false;
			}
		}
	}
	
	if(g_bBalanceTeams)
	{
		if(!BalanceTeams() && GetConVarInt(g_hAnnounce) & CANT_BALANCE_MESSAGE)
			PrintTranslatedToChatAll("unbalanceable");
		
		g_bBalanceTeams = false;
		g_bForceBalance = false;
	}

	SortCustom1D(g_iPlayerList, g_iPlayerCount, SortKDR);
	
	return Plugin_Continue;
}

public bool:BalanceTeams()
{
	new arrayTeams[2][MAXPLAYERS];
	new switchArray[MAXPLAYERS];
	new bottomPlayer, goodPlayers, numPlayers, clientToSwitch;

	// Put all the players into arrays by team
	new teamCount[2];
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && (g_iPlayerTeam[i] == CS_TEAM_T || g_iPlayerTeam[i] == CS_TEAM_CT))
		{
			arrayTeams[GetTeamIndex(g_iPlayerTeam[i])][teamCount[GetTeamIndex(g_iPlayerTeam[i])]] = i;
			teamCount[GetTeamIndex(g_iPlayerTeam[i])]++;
		}
	}
	
	// Sort the arrays by KDR
	SortCustom1D(arrayTeams[TERRORIST_INDEX], teamCount[TERRORIST_INDEX], SortKDR);
	SortCustom1D(arrayTeams[COUNTER_TERRORIST_INDEX], teamCount[COUNTER_TERRORIST_INDEX], SortKDR);
	
	// If there is only one person on the winning team there is not much we can do to fix the situation
	if(teamCount[GetTeamIndex(g_iLastWinner)] <= 1  && !g_bForceBalance)
	{
		return false;
	}
		
	// Decide how many people to switch
	if(teamCount[GetTeamIndex(g_iLastWinner)] - GetConVarInt(g_hSingleMax) <= 0)
		numPlayers = 1;
	else
		numPlayers = ((teamCount[GetTeamIndex(g_iLastWinner)] - GetConVarInt(g_hSingleMax)) / GetConVarInt(g_hIncrement)) + 1;
	
	if(teamCount[GetTeamIndex(g_iLastWinner)] - teamCount[GetTeamIndex(GetOtherTeam(g_iLastWinner))] > numPlayers)
		numPlayers = teamCount[GetTeamIndex(g_iLastWinner)] - teamCount[GetTeamIndex(GetOtherTeam(g_iLastWinner))];

	// The first player available for switching.  1 is the second best player on the team
	clientToSwitch = 1;

	// Check to make sure the switches we are doing are going to be positive changes
	bottomPlayer = teamCount[GetTeamIndex(GetOtherTeam(g_iLastWinner))] - 1;
	if (bottomPlayer < 0) 
		return false;

	new Float:lowKDR = GetClientKDR(arrayTeams[GetTeamIndex(GetOtherTeam(g_iLastWinner))][bottomPlayer]);
	for(new i = 0; i < numPlayers; i++)
	{
		if(GetClientKDR(arrayTeams[GetTeamIndex(g_iLastWinner)][i + clientToSwitch]) > lowKDR)
		{
			goodPlayers++;
			if(bottomPlayer > 0)
			{
				bottomPlayer--;
				lowKDR = GetClientKDR(arrayTeams[GetTeamIndex(GetOtherTeam(g_iLastWinner))][bottomPlayer]);
			}
		}
	}
	
	// goodPlayers now contains a revised number of players to switch
	// if it is 0 than the teams are as balanced as possible without stacking
	numPlayers = goodPlayers;
	
	// check to make sure the winning team isn't significantly larger
	new minPlayers = RoundToCeil(float(teamCount[GetTeamIndex(g_iLastWinner)] - teamCount[GetTeamIndex(GetOtherTeam(g_iLastWinner))]) / 2.0);
	if(numPlayers < minPlayers)
		numPlayers = minPlayers;

	if(numPlayers == 0 && !g_bForceBalance)
		return false;
	
	// Set the switchArray to switched for all indexes after the last player
	for(new i = teamCount[GetTeamIndex(g_iLastWinner)]; i < MAXPLAYERS; i++)
		switchArray[i] = 1;
	
	// If admin immunity is one make admins immune
	for(new i = 0; i < teamCount[GetTeamIndex(g_iLastWinner)]; i++)
		if(GetConVarBool(g_hAdminImmunity) && IsAdmin(arrayTeams[GetTeamIndex(g_iLastWinner)][i]))
			switchArray[i] = 1;

	
	// Do the team switching
	new found = true;
	new switched = 0;
	for(new i = 0; i < numPlayers; i++)
	{
		// If we have already switched this player we need to switch someone else
		// so we keep getting the next lowest player until we find someone we have not switched
		while(switchArray[clientToSwitch] && found)
		{
			if(clientToSwitch < teamCount[GetTeamIndex(g_iLastWinner)] - 1)
				clientToSwitch++;
			else
				clientToSwitch = 1;

			if(GetConVarBool(g_hAdminImmunity))
			{
				found = false;
				for(new player = 1; player < MAXPLAYERS; player++)
					if(switchArray[player] == 0)
						found = true;
			}	
		}
			
		// Switch the team of the player on the winning team
		if(found)
		{
			SwitchTeam(arrayTeams[GetTeamIndex(g_iLastWinner)][clientToSwitch], GetOtherTeam(g_iLastWinner));
			switchArray[clientToSwitch] = 1;
			switched++;
		
			// Decide who to switch next
			if(i % 2)
				clientToSwitch -= GetConVarInt(g_hIncrement) - 1;
			else
				clientToSwitch += GetConVarInt(g_hIncrement);
			
			if(clientToSwitch >= MaxClients  || clientToSwitch <= 0)
				clientToSwitch = 1;
		}
	}
	
	// Find the worst player on the losing team
	bottomPlayer = teamCount[GetTeamIndex(GetOtherTeam(g_iLastWinner))] - 1;
	if (bottomPlayer < 0) 
		return false;
	
	// Adjust the team count for how many people were switched
	teamCount[GetTeamIndex(g_iLastWinner)] -= switched;
	teamCount[GetTeamIndex(GetOtherTeam(g_iLastWinner))] += switched;
	
	// We remove the worse players from losing team to make the losing team no more than 
	// one client larger than the winning team.
	while(teamCount[GetTeamIndex(g_iLastWinner)] + 1 < teamCount[GetTeamIndex(GetOtherTeam(g_iLastWinner))] && bottomPlayer >= 0)
	{
		if(!(GetConVarBool(g_hAdminImmunity) && IsAdmin(arrayTeams[GetTeamIndex(GetOtherTeam(g_iLastWinner))][bottomPlayer])))
		{
			SwitchTeam(arrayTeams[GetTeamIndex(GetOtherTeam(g_iLastWinner))][bottomPlayer], g_iLastWinner);
			teamCount[GetTeamIndex(GetOtherTeam(g_iLastWinner))]--;
			teamCount[GetTeamIndex(g_iLastWinner)]++;
		}
		bottomPlayer--;
	}
	
	g_iLastBalance = g_iCurrentRound;
	return true;
}

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

public GetTeamIndex(team)
{
	return team - 2;
}

public SortKDR(elem1, elem2, const array[], Handle:hndl)
{
	if(GetClientKDR(elem1) > GetClientKDR(elem2))
		return -1;

	if(GetClientKDR(elem1) == GetClientKDR(elem2))
		return 0;

	return 1;
}

public SwitchTeam(client, team)
{
	new iExplosive;
	if((iExplosive = GetPlayerWeaponSlot(client, 4)) != -1 && iExplosive)
		SDKHooks_DropWeapon(client, iExplosive);

	CS_SwitchTeam(client, team);
	switch(team)
	{
		case CS_TEAM_T:
		{
			PrintCenterText(client, "%t", "t switch");
			EmitSoundToClient(client, SOUND_CHANGE_TEAM);
		}
		case CS_TEAM_CT:
		{
			PrintCenterText(client, "%t", "ct switch");
			EmitSoundToClient(client, SOUND_CHANGE_TEAM);
		}
	}

	CreateTimer(0.0, Timer_RespawnPlayer, GetClientUserId(client), TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_RespawnPlayer(Handle:timer, any:data)
{
	new client = GetClientOfUserId(data);
	if(!client || !IsClientInGame(client))
		return;
		
	CS_RespawnPlayer(client);

	CreateTimer(NOTIFY_SWITCH_DELAY, Timer_NotifySwitch, data);
}

public Action:Timer_NotifySwitch(Handle:timer, any:data)
{
	new client = GetClientOfUserId(data);
	if(!client || !IsClientInGame(client))
		return;
		
	PrintHintText(client, "You have switched team");
	PrintToChatAll("%N has been automatically switched to the %s team.", client, g_iPlayerTeam[client] == CS_TEAM_T ? "Terrorist" : "Counter-Terrorist");
}

public Action:CommandTeamSwap(client, args)
{
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && (g_iPlayerTeam[i] == CS_TEAM_T || g_iPlayerTeam[i] == CS_TEAM_CT))
			SwitchTeam(i, GetOtherTeam(g_iPlayerTeam[i]));

	
	return Plugin_Handled;
}

InitializeStats()
{
	decl String:sError[255], String:sBuffer[50];
	GetConVarString(g_hDatabase, sBuffer, sizeof(sBuffer));

	if(StrEqual(sBuffer, ""))
		g_hConnection = SQLite_UseDatabase("team_balance", sError, sizeof(sError));
	else
		g_hConnection = SQL_Connect(sBuffer, true, sError, sizeof(sError)); 
	
	if(g_hConnection == INVALID_HANDLE)
		SetFailState("Team Balance: Connection Error (%s)", sError);

	SQL_ReadDriver(g_hConnection, sBuffer, sizeof(sBuffer));
	if(StrEqual(sBuffer, "sqlite"))
		g_iDatabaseType = SQLITE;
	else if(StrEqual(sBuffer, "mysql"))
		g_iDatabaseType = MYSQL;
	else
		SetFailState("Team Balance: Database.cfg Error (Only MySQL and SQLite are supported)");

	new bool:bState;
	SQL_LockDatabase(g_hConnection);
	if(g_iDatabaseType == SQLITE)
		bState = SQL_FastQuery(g_hConnection, "CREATE TABLE IF NOT EXISTS stats (steam_id TEXT, kills INTEGER, deaths INTEGER, kdr REAL, timestamp INTEGER);");
	else
		bState = SQL_FastQuery(g_hConnection, "CREATE TABLE IF NOT EXISTS stats (steam_id VARCHAR(50), kills INTEGER, deaths INTEGER, kdr FLOAT, timestamp INTEGER, PRIMARY KEY(steam_id));");
	if(!bState && SQL_GetError(g_hConnection, sError, sizeof(sError)))
		SetFailState("Team Balance: Creation Error (%s)", sError);
	SQL_UnlockDatabase(g_hConnection);

	if(g_bLateLoad)
	{
		for(new i = 1; i < MaxClients; i++)
			if(IsClientInGame(i))
				LoadClientStats(i);
				
		g_bLateLoad = false;
	}
}

LoadClientStats(client)
{
	decl String:sBuffer[100];
	Format(sBuffer, sizeof(sBuffer), "SELECT kills, deaths, kdr, timestamp FROM stats WHERE steam_id = '%s'", g_sPlayerSteam[client]);
	SQL_TQuery(g_hConnection, LoadStatsCallback, sBuffer, GetClientUserId(client));
}

public LoadStatsCallback(Handle:owner, Handle:hndl, const String:sError[], any:data)
{
	if(!StrEqual("", sError))
	{
		LogError("Update Stats SQL Error: %s", sError);
		return;
	}
	
	new client = GetClientOfUserId(data);
	if(!client || !IsClientInGame(client))
		return;

	g_bPlayerLoaded[client] = true;
	if(SQL_FetchRow(hndl))
	{
		if(SQL_FetchInt(hndl, 3) > GetTime() - GetConVarInt(g_hSaveTime) * 3600)
		{
			g_iPlayerStats[client][KILLS] = SQL_FetchInt(hndl, 0);
			g_iPlayerStats[client][DEATHS] = SQL_FetchInt(hndl, 1);

			return;
		}
	}

	g_iPlayerStats[client][DEATHS] = 0;
	g_iPlayerStats[client][KILLS] = 0;
}

UpdateClientStats(client)
{
	if(!g_bPlayerLoaded[client])
		return;

	decl String:sBuffer[192];
	Format(sBuffer, sizeof(sBuffer), "REPLACE INTO stats VALUES ('%s', %i, %i, %f, %i)", g_sPlayerSteam[client], g_iPlayerStats[client][KILLS], g_iPlayerStats[client][DEATHS], GetClientKDR(client), GetTime());
	SQL_TQuery(g_hConnection, SQLErrorCheckCallback, sBuffer, _);
}

public SQLErrorCheckCallback(Handle:owner, Handle:hndl, const String:sError[], any:data)
{
	if(!StrEqual("", sError))
	{
		LogError("Team Balance SQl Error: %s", sError);
	}
}

public PrintTranslatedToChatAll(String:sBuffer[])
{
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i))
		{
			PrintToChat(i, "\x04[TEAM BALANCE]:%t", sBuffer);
		}
	}
}

public MapStartInitializations()
{
	g_iLastWinner = -1;
	g_iTeamStats[TERRORIST_INDEX][CONSECUTIVE_WINS] = 0;
	g_iTeamStats[TERRORIST_INDEX][ROUND_SWITCH] = 0;
	g_iTeamStats[COUNTER_TERRORIST_INDEX][CONSECUTIVE_WINS] = 0;
	g_iTeamStats[COUNTER_TERRORIST_INDEX][ROUND_SWITCH] = 0;
	
	for(new i = 0; i < ROUNDS_TO_SAVE; i++)
	{
		g_iRoundStats[COUNTER_TERRORIST_INDEX][i] = 0;
		g_iRoundStats[TERRORIST_INDEX][i] = 0;
	}
	g_iCurrentRound = 1;
	g_bBalanceTeams = false;
	g_iLastBalance = 0;
	Prune();
}

// Once the configs have executed we register the admin commands if appropriate
public OnConfigsExecuted()
{
	InitializeStats();

	GetConVarString(g_hAdminFlags, g_sAdminFlags, sizeof(g_sAdminFlags));
	
	if(GetConVarBool(g_hCommands) && !g_bHookedCommands)
	{
		RegAdminCmd("sm_swapteams", CommandTeamSwap, ADMFLAG_GENERIC);
		RegAdminCmd("sm_teamswitch", CommandTeamSwitch, ADMFLAG_GENERIC);
		g_bHookedCommands = true;
	}
}

public Action:CommandTeamSwitch(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_teamswitch <player> | sm_tbswitchnow <player>");
		return Plugin_Handled;
	}

	decl String:sBuffer[50];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));	

	new target = FindTarget(client, sBuffer, false, false);
	if(target > 0 && (g_iPlayerTeam[target] == CS_TEAM_T || g_iPlayerTeam[target] == CS_TEAM_CT))
		SwitchTeam(target, GetOtherTeam(g_iPlayerTeam[target]));

	return Plugin_Handled;
}

public Action:Command_Join(client, args)
{
	if(!GetConVarBool(g_hControlJoins) || args != 1 || (GetConVarBool(g_hJoinImmunity) && IsAdmin(client)))
		return Plugin_Continue;

	decl String:sBuffer[3];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));
	new team = StringToInt(sBuffer);
	
	// Check for join spectator not allowed
	if(g_iPlayerTeam[client] >= CS_TEAM_T && team == 1 && GetConVarBool(g_hStopSpec))
	{
		PrintCenterText(client, "Only players who have not joined a team may spectate");
		return Plugin_Handled;
	}
	
	// Check for team locking concerns
	if(g_iPlayerTeam[client] != 0 && GetConVarBool(g_hLockTeams) && team != 1 && g_iTeamList[client])
	{
		// if autojoin force them back onto their team
		if(team == 0)
		{
			ChangeClientTeam(client, g_iTeamList[client]);
			return Plugin_Handled;
		}
		
		// check to see if the team they are switching to is the same as their assigned team
		if(team != g_iTeamList[client])
		{
			PrintCenterText(client, "You cannot join that team");
			return Plugin_Handled;
		}
		
		// if we get to here it is safe
		return Plugin_Continue;
	}

	// We only want to get in the way of people joining these teams
	if(team != CS_TEAM_T && team != CS_TEAM_CT)
	{
		return Plugin_Continue;
	}
	
	// Count the team sizes
	new teamCount[2];
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientInGame(i) && (g_iPlayerTeam[i] == CS_TEAM_T || g_iPlayerTeam[i] == CS_TEAM_CT))
			teamCount[GetTeamIndex(g_iPlayerTeam[i])]++;

	if(teamCount[GetTeamIndex(CS_TEAM_T)] > teamCount[GetTeamIndex(CS_TEAM_CT)])
	{
		// The terrorist team is bigger so joining the CT's is fine
		if(team == CS_TEAM_CT)
			return Plugin_Continue;
		
		if(g_iPlayerTeam[client] == CS_TEAM_CT)
		{
			PrintCenterText(client, "You are not allowed to join the stronger team");
			return Plugin_Handled;
		}

		PrintCenterText(client, "The admin is joining you to the Counter-Terrorist team");
		EmitSoundToClient(client, SOUND_CHANGE_TEAM);
		ChangeClientTeam(client, CS_TEAM_CT);

		return Plugin_Handled;
	} 
	else if(teamCount[GetTeamIndex(CS_TEAM_T)] < teamCount[GetTeamIndex(CS_TEAM_CT)])
	{
		// The counter terrorist team is bigger so joining the T's is fine
		if(team == CS_TEAM_T)
			return Plugin_Continue;
		
		if(g_iPlayerTeam[client] == CS_TEAM_T)
		{
			PrintCenterText(client, "You are not allowed to join the stronger team");
			return Plugin_Handled;
		}

		PrintCenterText(client, "The admin is joining you to the Terrorist team");
		EmitSoundToClient(client, SOUND_CHANGE_TEAM);
		ChangeClientTeam(client, CS_TEAM_T);

		return Plugin_Handled;
	} 
	else 
	{
		// The teams are equal
		// if they are already on an existing team than they can't switch
		if(g_iPlayerTeam[client] == CS_TEAM_T || g_iPlayerTeam[client] == CS_TEAM_CT)
		{
			PrintCenterText(client, "You are not allowed to switch to the other team right now");
			return Plugin_Handled;
		}

		// The teams are equal and we don't enough stats to know what it up so let them do what they want
		if(g_iCurrentRound <= 2)
			return Plugin_Continue;
					
		// Count up the times the CT's have one in the last x rounds
		new ctWins;
		for(new i = 1; i <= 2; i++)
			ctWins += g_iRoundStats[GetTeamIndex(CS_TEAM_CT)][(g_iCurrentRound - i) % ROUNDS_TO_SAVE];
		
		// if the CT's are winning and the player is trying to join the CT's...they can't
		if(ctWins == 2 && team == CS_TEAM_CT)
		{
			PrintCenterText(client, "The admin is joining you to the Terrorist team");
			EmitSoundToClient(client, SOUND_CHANGE_TEAM);
			ChangeClientTeam(client, CS_TEAM_T);

			return Plugin_Handled;
		}
			
		// If the T's are winning and the player is trying to join the CT team....he's screwed
		if(ctWins == 0 && team == CS_TEAM_T)
		{
			PrintCenterText(client, "The admin is joining you to the Counter-Terrorist team");
			EmitSoundToClient(client, SOUND_CHANGE_TEAM);
			ChangeClientTeam(client, CS_TEAM_CT);

			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public Action:TeamManagementMenu(client, args)
{
	new Handle:hMenu = CreateMenu(TeamManagementMenuHandler);
	decl String:sBuffer[100];
	Format(sBuffer, sizeof(sBuffer), "%T", "team management hMenu", client);
	SetMenuTitle(hMenu, sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "swap teams", client);
	AddMenuItem(hMenu, "team hMenu item", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "switch player", client);
	AddMenuItem(hMenu, "team hMenu item", sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T", "switch player next", client);
	AddMenuItem(hMenu, "team hMenu item", sBuffer);
	
	if(GetConVarBool(g_hMaintainSize))
		Format(sBuffer, sizeof(sBuffer), "%T", "maintain size off", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "maintain size on", client);
	AddMenuItem(hMenu, "team hMenu item", sBuffer);
	
	if(GetConVarBool(g_hControlJoins))
		Format(sBuffer, sizeof(sBuffer), "%T", "control joins off", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "control joins on", client);
	AddMenuItem(hMenu, "team hMenu item", sBuffer);
	
	if(GetConVarBool(g_hEnabled))
		Format(sBuffer, sizeof(sBuffer), "%T", "disable balancer", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "enable balancer", client);
	AddMenuItem(hMenu, "team hMenu item", sBuffer);

	Format(sBuffer, sizeof(sBuffer), "%T", "display stats", client);
	AddMenuItem(hMenu, "team hMenu item", sBuffer);

	Format(sBuffer, sizeof(sBuffer), "%T", "dump settings", client);
	AddMenuItem(hMenu, "team hMenu item", sBuffer);
	
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 20);
 
	return Plugin_Handled;
}

public TeamManagementMenuHandler(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			switch(param2)
			{
				case 0:
				{	// swap teams
					CommandTeamSwap(param1, 0);
				}
				case 1:
				{	// switch player
					SwitchPlayerMenu(param1);
					return;
				}
				case 2:
				{	// switch next round
					SwitchPlayerMenu(param1, true);
					return;
				}
				case 3:
				{	// maintain size
					SetConVarBool(g_hMaintainSize, Opposite(GetConVarBool(g_hMaintainSize)));
				}
				case 4:
				{	// control joins
					SetConVarBool(g_hControlJoins, Opposite(GetConVarBool(g_hControlJoins)));
				}
				case 5:
				{	// disable/enable
					SetConVarBool(g_hEnabled, Opposite(GetConVarBool(g_hEnabled)));
				}
				case 6:
				{	// display stats
					Command_Stats(param1, 0);
					return;
				}
				case 7:
				{	// dump settings
					CommandDump(param1, 0);
				}
			}

			TeamManagementMenu(param1, 0);
		}
		case MenuAction_End:
			CloseHandle(hMenu);
	}
}

bool:Opposite(bool:current)
{
	return !current;
}

SwitchPlayerMenu(client, bool:nextRound = false)
{
	decl String:sTemp[4], String:sBuffer[100];
	new Handle:hMenu = CreateMenu(SwitchPlayerMenuHandler);

	if(nextRound)
		Format(sBuffer, sizeof(sBuffer), "%T", "switch player next", client);
	else
		Format(sBuffer, sizeof(sBuffer), "%T", "switch player", client);

	SetMenuTitle(hMenu, sBuffer);
	for(new i = 1; i <= MaxClients; i++)
	{
		if(IsClientInGame(i) && g_iPlayerTeam[i] >= CS_TEAM_T)
		{
			IntToString(i, sTemp, sizeof(sTemp));
			if(nextRound)
				Format(sTemp, sizeof(sTemp), "N%s", sTemp);

			AddMenuItem(hMenu, sTemp, g_sPlayerName[i]);
		}
	}
	
	SetMenuExitButton(hMenu, true);
	DisplayMenu(hMenu, client, 20);
}

public SwitchPlayerMenuHandler(Handle:hMenu, MenuAction:action, param1, param2)
{
	switch(action)
	{
		case MenuAction_Select:
		{
			decl String:sBuffer[4];
			new client, bool:nextRound;
			GetMenuItem(hMenu, param2, sBuffer, sizeof(sBuffer));

			if(sBuffer[0] == 'N')
			{
				nextRound = true;
				client = StringToInt(sBuffer[1]);
			}
			else
				client = StringToInt(sBuffer);

			if(client && IsClientInGame(client) && g_iPlayerTeam[client] >= CS_TEAM_T)
			{
				if(nextRound)
					g_switchNextRound[client] = true;
				else
					SwitchTeam(client, GetOtherTeam(g_iPlayerTeam[client]));
			}

			SwitchPlayerMenu(param1, nextRound);
		}
		case MenuAction_End:
			CloseHandle(hMenu);
	}
}

public Action:Command_Stats(client, args)
{
	if(client && IsClientInGame(client))
		DisplayPanel_KDR(client, 1);
	
	return Plugin_Handled;
}

Float:GetClientKDR(client)
{
	if(!client || !IsClientInGame(client))
		return 0.0;
	
	if(g_iPlayerStats[client][KILLS] + g_iPlayerStats[client][DEATHS] >= GetConVarInt(g_hMinKills))
	{
		if(g_iPlayerStats[client][DEATHS])
			return float(g_iPlayerStats[client][KILLS]) / float(g_iPlayerStats[client][DEATHS]);
		else
			return float(g_iPlayerStats[client][KILLS]);
	}
	
	return GetConVarFloat(g_hDefaultKDR);
}

public DisplayPanel_KDR(client, panelNumber)
{
	new Handle:hPanel = CreatePanel();
	decl String:sBuffer[512];
	Format(sBuffer, sizeof(sBuffer), "%T", "kdr hPanel", client);
	SetPanelTitle(hPanel, sBuffer);
	
	Format(sBuffer, sizeof(sBuffer), "%T\n", "internal stats", client);
	for(new i = 0 + (panelNumber - 1) * STATS_PER_PANEL; i < STATS_PER_PANEL * panelNumber; i++)
		if(i < g_iPlayerCount)
			Format(sBuffer, sizeof(sBuffer), "%s%i: %s - Kills: %i Deaths: %i KDR: %.2f\n", sBuffer, i + 1, g_sPlayerName[i], g_iPlayerStats[g_iPlayerList[i]][KILLS], g_iPlayerStats[g_iPlayerList[i]][DEATHS], GetClientKDR(g_iPlayerList[i]));
	
	DrawPanelItem(hPanel, sBuffer);
	if(panelNumber > 1)
	{
 		SetPanelCurrentKey(hPanel, 8);
 		DrawPanelItem(hPanel, "Previous");
	}		

 	if(panelNumber * STATS_PER_PANEL < GetClientCount())
 	{
 		SetPanelCurrentKey(hPanel, 9);
 		DrawPanelItem(hPanel, "Next");
 	}

	g_iPanelPosition[client] = panelNumber;
 	SetPanelCurrentKey(hPanel, 10);
 	DrawPanelItem(hPanel, "Exit");
	SendPanelToClient(hPanel, client, PanelHandler_KDR, 20);
	CloseHandle(hPanel);
}

public PanelHandler_KDR(Handle:hMenu, MenuAction:action, param1, param2)
{
	if(action == MenuAction_Select)
	{
		switch(param2)
		{
			case 8:
				DisplayPanel_KDR(param1, g_iPanelPosition[param1] - 1);
			case 9:
				DisplayPanel_KDR(param1, g_iPanelPosition[param1] + 1);
		}
	}
}

public Action:CommandDump(client, args)
{
	decl String:sBuffer[250];

	ReplyToCommand(client, "sm_team_balance_enable: %i", GetConVarInt(g_hEnabled));
	ReplyToCommand(client, "sm_team_balance_min_kd: %i", GetConVarInt(g_hMinKills));
	ReplyToCommand(client, "sm_team_balance_announce: %i", GetConVarInt(g_hAnnounce));
	ReplyToCommand(client, "sm_team_balance_consecutive_wins: %i", GetConVarInt(g_hConsecutiveWins));
	ReplyToCommand(client, "sm_team_balance_wlr: %f", GetConVarFloat(g_hWinLossRatio));
	ReplyToCommand(client, "sm_team_balance_new_join_rounds: %i", GetConVarInt(g_hRoundsNewJoin));
	ReplyToCommand(client, "sm_team_balance_min_rounds: %i", GetConVarInt(g_hMinRounds));
	ReplyToCommand(client, "sm_team_balance_save_time: %i", GetConVarInt(g_hSaveTime));
	ReplyToCommand(client, "sm_team_balance_def_kdr: %f", GetConVarFloat(g_hDefaultKDR));
	ReplyToCommand(client, "sm_team_balance_increment: %i", GetConVarInt(g_hIncrement));
	ReplyToCommand(client, "sm_team_balance_single_max: %i", GetConVarInt(g_hSingleMax));
	ReplyToCommand(client, "sm_team_balance_commands: %i", GetConVarInt(g_hCommands));
	ReplyToCommand(client, "sm_team_balance_maintain_size: %i", GetConVarInt(g_hMaintainSize));
	ReplyToCommand(client, "sm_team_balance_control_joins: %i", GetConVarInt(g_hControlJoins));
	GetConVarString(g_hConnection, sBuffer, sizeof(sBuffer));
	ReplyToCommand(client, "sm_team_balance_database: %s", sBuffer);
	ReplyToCommand(client, "sm_team_balance_join_immunity: %i", GetConVarInt(g_hJoinImmunity));
	ReplyToCommand(client, "sm_team_balance_admin_immunity: %i", GetConVarInt(g_hAdminImmunity));
	GetConVarString(g_hAdminFlags, sBuffer, sizeof(sBuffer));
	ReplyToCommand(client, "sm_team_balance_admin_flags: %s", sBuffer);
	ReplyToCommand(client, "sm_team_balance_min_balance_frequency: %i", GetConVarInt(g_hMinBalance));
	ReplyToCommand(client, "sm_team_balance_lock_teams: %i", GetConVarInt(g_hLockTeams));
	ReplyToCommand(client, "sm_team_balance_lock_time: %i", GetConVarInt(g_hLockTime));
	ReplyToCommand(client, "sm_team_balance_stop_spec: %i", GetConVarInt(g_hStopSpec));

	return Plugin_Handled;
}

public Action:CommandSet(client, args)
{
	if(args != 3)
	{
		ReplyToCommand(client, "Usage: sm_tbset <player> <kills> <deaths>");
		return Plugin_Handled;
	}

	decl String:sBuffer[50];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));	
	new target = FindTarget(client, sBuffer, false, false);
	GetCmdArg(2, sBuffer, sizeof(sBuffer));
	new kills = StringToInt(sBuffer);
	GetCmdArg(3, sBuffer, sizeof(sBuffer));
	new deaths = StringToInt(sBuffer);
	
	if(target > 0)
	{
		g_iPlayerStats[target][KILLS] = kills;
		g_iPlayerStats[target][DEATHS] = deaths;
		ReplyToCommand(client, "Set %s's stats to kills: %i, deaths: %i", g_sPlayerName[target], g_iPlayerStats[target][KILLS], g_iPlayerStats[target][DEATHS]);
	}
	else 
		ReplyToCommand(client, "Target not found");

	return Plugin_Handled;
}

public Action:CommandStartSwitch(client, args)
{
	if(args != 1)
	{
		ReplyToCommand(client, "Usage: sm_tbswitchatstart <player>");
		return Plugin_Handled;
	}

	decl String:sBuffer[50];
	GetCmdArg(1, sBuffer, sizeof(sBuffer));	
	new target = FindTarget(client, sBuffer, false, false);
	if(target > 0 && (g_iPlayerTeam[target] == CS_TEAM_T || g_iPlayerTeam[target] == CS_TEAM_CT))
		g_switchNextRound[target] = true;

	return Plugin_Handled;
}

bool:IsAdmin(client)
{
	if(StrEqual(g_sAdminFlags, ""))
		return GetUserAdmin(client) == INVALID_ADMIN_ID ? false : true;

	return (GetUserFlagBits(client) & ReadFlagString(g_sAdminFlags)) ? true : false;
}

public AdminFlagsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	strcopy(g_sAdminFlags, sizeof(g_sAdminFlags), newValue);
}

public Prune()
{
	KvRewind(g_hTeamLocks);
	if (!KvGotoFirstSubKey(g_hTeamLocks))
		return;

	new iStopWhining;
	while(!iStopWhining)
	{
		if(GetTime() > KvGetNum(g_hTeamLocks, "timestamp") + GetConVarInt(g_hLockTime))
		{
			if (KvDeleteThis(g_hTeamLocks) < 1)
				break;
		} 
		else if (!KvGotoNextKey(g_hTeamLocks))
			break;
	}
}