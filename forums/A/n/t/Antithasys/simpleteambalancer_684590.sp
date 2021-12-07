/* Simple Team Balancer
 *  By Antithasys
 *  http://www.mytf2.com
 *
 * Description:
 *			Balances teams based upon player count
 *			Player will not be balanced more than once in 5 (default) mins
 *			Buddy system tries to keep buddies together
 *			Ability to prioritize players
 *			Ability to force players to accept the new team
 *			Admins are immune
 *
 * 1.4.6
 * Natives now respawn players and allow unforced moves to spectator
 * No longer made the TF2 stocks required
 *
 * 1.4.5
 * Fixed flag event not using correct client id
 *
 * 1.4.4
 * Fixed timer creation not using the correct handle
 *
 * 1.4.3
 * Fixed datapacks not being created correctly
 *
 * 1.4.2
 * Fixed memory leak with open data handles on data timers
 * Flag carrier will no longer be switched
 * Balanced players are now respawned instantly
 * Added event hooks for DOD as first step to making it work for DOD
 * --I have not altered anything else, so there may be errors in log or it mite not work at all
 * --I would suggest stb_priorityplayers 0 and reporting any errors
 *
 * 1.4.1
 * Fixed error where players could be assigned to team 0 (again)
 *
 * 1.4.0
 * Removed convar stb_timeleft
 --Balancer now stops when there is 1 min left in the round
 * Forced players will now have correct team assignment after a team switch event
 * Added split second delay to switching players to try to prevent the team kill and unassigned messages
 * Fixed event hooks from stacking (This may have been the cause of the sudden stoppage)
 * Reconfigured some code and cleaned up some functions
 *
 * 1.3.6
 * Optimized code in hooked events
 *
 * 1.3.5
 * Fixed error where plugin was preventing the displaying of team join messages
 * Fixed error when enabled/disabled 
 *
 * 1.3.4
 * Added consolse variable to enable/disable the buddy system
 --If the buddy system is disabled, it will also prevent the start ads
 * Corrected error that prevented regular players from seeing the player menu in the buddy command
 * Removed balance event from native functions
 *
 * 1.3.3
 * Added console variable for dead only player switching
 --Setting to 1 will require someone on the bigger team to die and be "switchable" to balance the teams
 --This could mean long periods of inbalanced teams.  Use at your own risk
 * Added console variable to control a balance delay
 --This will delay the start of the autobalance once teams become inbalanced
 --Setting to 0 will start a balance right away
 --Dead players will not be scanned or switched until after this delay
 * Increased advertisement timer to 60 seconds after player enters
 * Changed phrase used to respond to buddy command
 * Changed description of stb_timeleft as it only works for MAP time left and not round time left
 * Added bot check and error reporting for the native functions
 * Corrected error in logic for team selection in native functions
 * Modified native code to not display balance message, but still fire events, when switching players
 *
 * 1.3.2
 * Added console variable to control how close to the end of the round to not issue a balance
 * Added Native functions in include file for external function calls
 * Added welcome advertisement for the buddy system
 --With stb_buddyrestriction 1 this will only be sent to admins/donators
 * Corrected error causing the server to crash when someone canceled out of the buddy menu
 *
 * 1.3.1
 * Renamed a few console variables and rewrote descriptions to more accuractly describe their current functions (server reboot required)
 * Updated simpleteambalancer.phrases.txt file to display more accurate messages
 * Added additional logic checks to prevent invalid team assignment
 * Removed addbalancebuddy command as it was no longer needed (replaced by buddy)
 * Corrected error in forced player code returning the wrong result
 * --This could have been the cause of the stuck in spectator problem
 *
 * 1.3.0
 * Added balance check to the end of roundstartdelay timer to help prevent an inbalance at the start of rounds
 * Added console variable to display log events
 * Corrected error in player and client assignment in the death event, dead players were not being switched as often as they should
 * Corrected error in priority player selection returning wrong result
 * Corrected error in the forcing code in the death event not forcing the player to the smaller team
 * Corrected error that still allowed dead engineers with buildings to be switched with stb_priorityenabled 1 (really, really this time)  (Thanks to bl4nk)
 * Corrected error when all players in game where admins causing an undesired loop
 * Corrected error allowing stb_unbalancelimit to be set to 0, min setting is now 1
 * Corrected error in balance timer not properly closing
 * Changed from KillTimer to CloseHandle to avoid unnecessary errors in the log
 * Cleaned up code and added some stock functions, it's now a bit easier to read
 *
 * 1.2.4
 * Added balance check back to death event to prevent multi-player inbalances
 * Added console variable for min uber level.  Setting to 0 will rarely switch a living medic
 *
 * 1.2.3
 * Balance event will no longer occur during sudden death
 *
 * 1.2.2
 * Corrected error that occured with client = 0 in death event
 * Corrected error that still allowed dead engineers with buildings to be switched with stb_priorityenabled 1 (really this time)
 *
 * 1.2.1
 * Corrected error that could switch a forced player when a player disconnects to the wrong team
 * Modified immunity code to always look for a root admin even if the admin didn't have the specified flag
 * Removed dead engineer building code as it was causing errors.  Dead engineers with buildings can still be switched
 *
 * 1.2.0
 * Added new buddy command as an alais of addbalancebuddy
 * Added new lockbuddy command to lock your buddy selection
 * Added console variable for switchback/forced time.
 * Corrected error that still caused queued clients to change team if plugin was disabled during game play
 * Corrected error that still allowed dead engineers with buildings to be switched with stb_priorityenabled 1
 * Modified on death event code to scan for switchable dead players while a balance is in progress, stopping a live players switch
 * Corrected error that allowed players to circumvent being forced to a team
 * --It now disallows changing to spectator during the force period if that would cause an inbalance
 * --If teams would not become unbalanced a forced players team change is permitted
 * --If during the force period the teams become unbalanced and the forced player is on the wrong team he is switched back
 *
 * 1.1.2
 * Fixed error in addbalancebuddy command with stb_buddyrestriction 1
 *
 * 1.1.1
 * Fixed error when buddy remained in list after disconnecting
 *
 * 1.1.0
 * Added buddy system that tries to keep people together
 * Added a buddy system console variable to enable it to general public
 * Added console variable to enable living player prioritization
 * Medic's with full ubers are given a lower priority (Thanks to Muridias)
 * Engineer's with buildings are given a lower priority  (Thanks to bl4nk)
 * Corrected small logic problems in player selection process
 *
 * 1.0.6
 * Fixed error when a balance could still occur after the teams were balanced by a joining player
 * Changed player selection code to perfer dead players, but still pick a live one if no dead players found
 *
 * 1.0.5
 * Added console variable to force the player to accept the balanced team
 * Fixed error when selected players could die and still have to wait the delay time to be switched
 *
 * 1.0.4
 * Optimized code when checking for the admin flag (Thanks to bl4nk, SAMURAI16)
 *
 * 1.0.3
 * Added console variable for admin flag so it can be set in the .cfg file (Thanks to bl4nk, SAMURAI16)
 *
 * 1.0.2
 * Fixed error in when changing the unbalance limit not also setting mp_teams_unbalance_limit
 *
 * 1.0.1
 * Added translation file support
 * If in Arena Mode balancer is bypassed
 *
 * 1.0.0
 * Initial Release
 *
 * Future Updates:
 *			None
 *
 * License
 * 			GNUv2
 */

#pragma semicolon 1

#include <sourcemod>
#include <sdktools>
#undef REQUIRE_PLUGIN
#include <tf2_stocks>
#include <adminmenu>

#define PLUGIN_VERSION "1.4.6"
#define MAX_STRING_LEN 255
#define TEAM_RED 2
#define TEAM_BLUE 3

/* PUBLIC CONVAR HANDLES */
new Handle:stb_enabled = INVALID_HANDLE;
new Handle:stb_buddyenabled = INVALID_HANDLE;
new Handle:stb_version = INVALID_HANDLE;
new Handle:stb_logactivity = INVALID_HANDLE;
new Handle:stb_logactivity2 = INVALID_HANDLE;
new Handle:stb_unbalancelimit = INVALID_HANDLE;
new Handle:stb_forcedenabled =  INVALID_HANDLE;
new Handle:stb_deadonly = INVALID_HANDLE;
new Handle:stb_priorityenabled = INVALID_HANDLE;
new Handle:stb_uberlevel = INVALID_HANDLE;
new Handle:stb_balancedelay = INVALID_HANDLE;
new Handle:stb_livingplayerswitchdelay = INVALID_HANDLE;
new Handle:stb_livingplayercheckdelay = INVALID_HANDLE;
new Handle:stb_roundstartdelay = INVALID_HANDLE;
new Handle:stb_switchbackforced = INVALID_HANDLE;
new Handle:stb_adminflag = INVALID_HANDLE;
new Handle:stb_buddyrestriction = INVALID_HANDLE;
new Handle:stb_convarcontrol = INVALID_HANDLE;
/* BUILT-IN CVARS HANDLES */
new Handle:stb_mp_autoteambalance = INVALID_HANDLE;
new Handle:stb_mp_teams_unbalance_limit = INVALID_HANDLE;
new Handle:TFGameModeArena = INVALID_HANDLE;
/* TIMER HANDLES */
new Handle:BalanceTimer = INVALID_HANDLE;
new Handle:LivingPlayerCheckTimer = INVALID_HANDLE;
new Handle:LivingPlayerTimer[MAXPLAYERS + 1];
new Handle:ForcedPlayerTimer[MAXPLAYERS + 1];
/* PLAYER ARRAYS */
new PlayersBuddy[MAXPLAYERS + 1];
new PlayersForcedTeam[MAXPLAYERS + 1];
new PlayersTeam[MAXPLAYERS + 1];
new bool:PlayerIsFlagCarrier[MAXPLAYERS + 1];
new bool:PlayerSwitched[MAXPLAYERS + 1];
new bool:PlayerBuddyLock[MAXPLAYERS + 1];
/* GLOBAL BOOLS */
new bool:IsEnabled = true;
new bool:PriorityPlayers = true;
new bool:BuddyRestriction = false;
new bool:LogActivity = false;
new bool:LogActivity2 = false;
new bool:DeadOnly = false;
new bool:ConVarControl = true;
new bool:BuddyEnabled = true;
new bool:BalanceInProgress = false;
new bool:RoundStart = false;
new bool:RoundEnd = false;
new bool:SuddenDeath = false;
new bool:IsHooked = false;
new bool:IsArenaMode = false;
new bool:TeamsSwitched = false;
new bool:ForcePlayers = true;
new bool:OutOfTime = false;
/* GLOBAL STRINGS/INTEGERS/FLOATS */
new String:GameType[40];
new maxclients, unbalancelimit, livingplayerswitchdelay, livingplayercheckdelay;
new roundstartdelay, switchbackforced, balancedelay;
new OldBlueScore, OldRedScore;
new Float:uberlevel;
new ownerOffset;

public Plugin:myinfo =
{
	name = "Simple Team Balancer",
	author = "Antithasys",
	description = "Balances teams based upon player count.",
	version = PLUGIN_VERSION,
	url = "http://www.mytf2.com"
}

public OnPluginStart()
{
	/* CREATE CONSOLE VARIABLES */
	stb_version = CreateConVar("simpleteambalancer_version", PLUGIN_VERSION, "Simple Team Balancer", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	stb_enabled = CreateConVar("stb_enabled", "1", "Enable or Disable Simple Team Balancer", _, true, 0.0, true, 1.0);
	stb_priorityenabled = CreateConVar("stb_priorityenabled", "1", "Enable or Disable the prioritization of living players", _, true, 0.0, true, 1.0);
	stb_buddyrestriction = CreateConVar("stb_buddyrestriction", "0", "Enable or Disable Admin Only buddy lists", _, true, 0.0, true, 1.0);
	stb_logactivity = CreateConVar("stb_logactivity", "0", "Enable or Disable the disaplying of events in the log", _, true, 0.0, true, 1.0);
	stb_logactivity2 = CreateConVar("stb_logactivity2", "0", "Enable or Disable the disaplying of detailed events in the log (WILL SPAM LOG)", _, true, 0.0, true, 1.0);
	stb_forcedenabled = CreateConVar("stb_forcedenabled", "1", "Enable or Disable forcing the player to accept the balanced team", _, true, 0.0, true, 1.0);	
	stb_deadonly = CreateConVar("stb_deadonly", "0", "Enable or Disable the switching of only dead players", _, true, 0.0, true, 1.0);
	stb_convarcontrol = CreateConVar("stb_convarcontrol", "1", "Enable or Disable the control of builtin console variables", _, true, 0.0, true, 1.0);
	stb_buddyenabled = CreateConVar("stb_buddyenabled", "1", "Enable or Disable the buddy system", _, true, 0.0, true, 1.0);	
	stb_unbalancelimit = CreateConVar("stb_unbalancelimit", "2", "Amount of players teams are ALLOWED to be unbalanced by", _, true, 1.0, true, 32.0);
	stb_balancedelay = CreateConVar("stb_balancedelay", "10", "Delay in seconds to start an autobalance");
	stb_livingplayerswitchdelay = CreateConVar("stb_livingplayerswitchdelay", "20", "Delay in seconds to switch living players once selected");
	stb_livingplayercheckdelay = CreateConVar("stb_livingplayercheckdelay", "10", "Delay in seconds to start checking living players once teams become unbalanced");
	stb_roundstartdelay = CreateConVar("stb_roundstartdelay", "15", "Delay in seconds to start balancing teams after the start of a round");
	stb_switchbackforced = CreateConVar("stb_switchbackforced", "300", "Amount of time in seconds to not switch a player twice and force the team if enabled");
	stb_uberlevel = CreateConVar("stb_uberlevel", "1.0", "Min uber level medic must have to have priority over other living players. Setting to 0 will rarely switch a living medic", _, true, 0.0, true, 1.0);
	stb_adminflag = CreateConVar("stb_adminflag", "a", "Admin flag to use for immunity.  Must be a in char format.");
	stb_mp_autoteambalance = FindConVar("mp_autoteambalance");
	stb_mp_teams_unbalance_limit = FindConVar("mp_teams_unbalance_limit");
	TFGameModeArena = FindConVar("tf_gamemode_arena");
	/* HOOK CONSOLE VARIABLES */
	HookConVarChange(stb_version, ConVarSettingsChanged);
	HookConVarChange(stb_enabled, ConVarSettingsChanged);
	HookConVarChange(stb_priorityenabled, ConVarSettingsChanged);
	HookConVarChange(stb_buddyrestriction, ConVarSettingsChanged);
	HookConVarChange(stb_logactivity, ConVarSettingsChanged);
	HookConVarChange(stb_logactivity2, ConVarSettingsChanged);
	HookConVarChange(stb_forcedenabled, ConVarSettingsChanged);
	HookConVarChange(stb_deadonly, ConVarSettingsChanged);
	HookConVarChange(stb_convarcontrol, ConVarSettingsChanged);
	HookConVarChange(stb_buddyenabled, ConVarSettingsChanged);
	HookConVarChange(stb_unbalancelimit, ConVarSettingsChanged);
	HookConVarChange(stb_balancedelay, ConVarSettingsChanged);
	HookConVarChange(stb_livingplayerswitchdelay, ConVarSettingsChanged);
	HookConVarChange(stb_livingplayercheckdelay, ConVarSettingsChanged);
	HookConVarChange(stb_roundstartdelay, ConVarSettingsChanged);
	HookConVarChange(stb_switchbackforced, ConVarSettingsChanged);
	HookConVarChange(stb_uberlevel, ConVarSettingsChanged);
	HookConVarChange(stb_mp_autoteambalance, ConVarSettingsChanged);
	HookConVarChange(stb_mp_teams_unbalance_limit, ConVarSettingsChanged);
	/* GET GAME TYPE */	
	GetGameFolderName(GameType, sizeof(GameType));
	/* CREATE CONSOLSE COMMANDS */
	RegConsoleCmd("sm_buddy", Command_AddBalanceBuddy, "Add a balance buddy");
	RegConsoleCmd("sm_lockbuddy", Command_LockBuddy, "Locks your balance buddy selection");
	/* LOAD TRANSLATIONS AND .CFG FILE */
	LoadTranslations ("simpleteambalancer.phrases");
	AutoExecConfig(true, "plugin.simpleteambalancer");
}

public bool:AskPluginLoad(Handle:myself, bool:late, String:error[], err_max)
{
	/* REGISTER NATIVES FOR OTHER PLUGINS */
   CreateNative("STB_MovePlayerUnForced", Native_STB_MovePlayerUnForced);
   CreateNative("STB_MovePlayerForced", Native_STB_MovePlayerForced);
   CreateNative("STB_RemoveForcedPlayer", Native_STB_RemoveForcedPlayer);
   CreateNative("STB_SetBalanceBuddies", Native_STB_SetBalanceBuddies);
   return true;
}

public OnConfigsExecuted()
{
	/* LOAD UP GLOBAL VARIABLES */
	IsEnabled = GetConVarBool(stb_enabled);
	BuddyEnabled = GetConVarBool(stb_buddyenabled);
	ForcePlayers = GetConVarBool(stb_forcedenabled);
	LogActivity = GetConVarBool(stb_logactivity);
	LogActivity2 = GetConVarBool(stb_logactivity2);
	DeadOnly = GetConVarBool(stb_deadonly);
	PriorityPlayers = GetConVarBool(stb_priorityenabled);
	BuddyRestriction = GetConVarBool(stb_buddyrestriction);
	ConVarControl = GetConVarBool(stb_convarcontrol);
	maxclients = GetMaxClients();
	uberlevel = GetConVarFloat(stb_uberlevel);
	unbalancelimit = GetConVarInt(stb_unbalancelimit);
	balancedelay = GetConVarInt(stb_balancedelay);
	livingplayerswitchdelay = GetConVarInt(stb_livingplayerswitchdelay);
	livingplayercheckdelay = GetConVarInt(stb_livingplayercheckdelay);
	roundstartdelay = GetConVarInt(stb_roundstartdelay);
	switchbackforced = GetConVarInt(stb_switchbackforced);
	ownerOffset = FindSendPropInfo("CBaseObject", "m_hBuilder");
	SetConVarString(stb_version, PLUGIN_VERSION);
	/* IF ENABLED HOOK THE EVENTS */
	if (IsEnabled && !IsHooked) {
		LogAction(-1, -1, "[STB] Hooking round end events for game: %s", GameType);
		HookEvent("player_death", HookPlayerDeath, EventHookMode_Post);
		HookEvent("player_team", HookPlayerChangeTeam, EventHookMode_Pre);
		HookEntityOutput("team_round_timer", "On1MinRemain", EntityOutput_TimeLeft);
		if(StrEqual(GameType, "dod")) {
			HookEvent("dod_round_start", HookRoundStart, EventHookMode_PostNoCopy);
			HookEvent("dod_round_win", HookRoundEnd, EventHookMode_Post);
		}
		else if(StrEqual(GameType, "tf")) {
			HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_PostNoCopy);
			HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
			HookEvent("teamplay_suddendeath_begin", HookSuddenDeathBegin, EventHookMode_PostNoCopy);
			HookEvent("teamplay_point_captured", HookControlPointCapture, EventHookMode_PostNoCopy);
			HookEvent("teamplay_flag_event", HookFlagEvent, EventHookMode_Post);
		}
		IsHooked = true;
		if (ConVarControl) {
			SetConVarInt(stb_mp_autoteambalance, 0);
			SetConVarInt(stb_mp_teams_unbalance_limit, unbalancelimit);
		}
		LogAction(0, -1, "[STB] Simple Team Balancer is loaded and enabled.");
	} else
		LogAction(0, -1, "[STB] Simple Team Balancer is loaded and disabled.");
	/* REPORT LOG ACTIVITY */
	if (IsEnabled && LogActivity)
		LogAction(0, -1, "[STB] Log Activity ENABLED.");
	else
		LogAction(0, -1, "[STB] Log Activity DISABLED.");
	if (IsEnabled && LogActivity2)
		LogAction(0, -1, "[STB] Detailed Log Activity ENABLED.");
	else
		LogAction(0, -1, "[STB] Detailed Log Activity DISABLED.");
		
}

public OnMapStart()
{
	/* CHECK FOR ARENA MODE */
	if (GetConVarBool(TFGameModeArena)) {
		IsArenaMode = true;
		LogAction(0, -1, "[STB] Simple Team Balancer detected arena mode and will be bypassed");
	} else
		IsArenaMode = false;
	/* SET THE BUILT-IN CONVARS IF ENABLED */
	if (IsEnabled && ConVarControl) {
		SetConVarInt(stb_mp_autoteambalance, 0);
		SetConVarInt(stb_mp_teams_unbalance_limit, unbalancelimit);
	}
	return;
}

public OnMapEnd()
{
	/* RESET SAVED TEAM INFORMATION */
	ResetTeams();
	return;
}

public OnClientPostAdminCheck(client)
{
	/* MAKE SURE ITS A VALID CONNECTED CLIENT AND BUDDY SYSTEM IS ENABLED */
	if ((client == 0) 
	|| !IsEnabled 
	|| !IsClientConnected(client)
	|| !BuddyEnabled)
		return;
	/* MAKE SURE IF ITS SET FOR ADMINS ONLY THEY HAVE THE FLAGS */
	if (BuddyRestriction 
	&& !has_flags(client))
		return;
	/* START THE ADVERTISEMENT TIMER */
	CreateTimer (60.0, Timer_WelcomeAdvert, client);
}

public OnClientDisconnect(client)
{
	/* CALL STOCK FUNCTION TO CLEAUP FUNCTION */
	CleanUp(client);
	/* CLEANUP CLIENTS/PLAYERS BUDDY LIST*/
	new buddy = BuddySystem(client, _, true);
	if (buddy != 0) {
		BuddySystem(client);
		BuddySystem(buddy);
		PlayerBuddyLock[client] = false;
	}
	/* DETERMINE IF WE NEED A BALANCE */
	if (OkToBalance() 
	&& IsUnbalanced()
	&& !BalanceInProgress) {
		/* CHECK IF WE ARE FORCING PLAYERS */
		if (ForcePlayers) {
			/* SEE IF WE CAN FIND A FORCED PLAYER ON THE WRONG TEAM */
			new smallerteam = GetSmallerTeam();
			new player = FindAForcedPlayer(smallerteam);
			if (player != 0 && PlayersForcedTeam[player] != 0) {
				/* FOUND ONE */
				if (LogActivity)
					LogAction(0, client, "[STB] With a balance needed on a player disconnect a forced player was found on the wrong team and was switched.");
				/* CALL THE STOCK CHANGE TEAM FUNCTION */
				ChangePlayersTeam(player, PlayersForcedTeam[player]);
				return;
			}
		}
		/* NO BALANCE IN PROGRESS BUT BALANCE IS NEEDED */
		/* NOT FORCING PLAYERS OR NO FORCED PLAYER FOUND SO WE START A BALANCE */
		StartABalance();
	}
	return;
}

/* HOOKED EVENTS */

public Action:HookPlayerDeath(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new String:weapon[MAX_STRING_LEN];
	GetEventString(event, "weapon", weapon, MAX_STRING_LEN);
	/* RETURN IF DEATH WAS NOT CAUSED BY A PLAYER */
	if (StrEqual(weapon, "world", false))
		return Plugin_Continue;
	/* CHECK IF BALANCE IS NEEDED */
	if (IsClientInGame(client)
	&& OkToBalance()
	&& IsUnbalanced()) {
		new smallerteam = GetSmallerTeam();
		new biggerteam = GetBiggerTeam();
		if (smallerteam == 0 || biggerteam == 0)
			return Plugin_Continue;
		/* CHECK IF BALANCE IS IN PROGRESS */
		if (BalanceInProgress) {
			if (LivingPlayerTimer[client] != INVALID_HANDLE) {
				CloseHandle(LivingPlayerTimer[client]);
				LivingPlayerTimer[client] = INVALID_HANDLE;
				if (LogActivity)
					LogAction(0, client, "[STB] With a balance in progress the queued living player died and was switched.");
				if (LivingPlayerCheckTimer != INVALID_HANDLE) {
					CloseHandle(LivingPlayerCheckTimer);
					LivingPlayerCheckTimer = INVALID_HANDLE;
					if (LogActivity)
						LogAction(0, client, "[STB] Living player check timer was not needed and was killed before the callback.");
				}
				/* CALL THE STOCK CHANGE TEAM FUNCTION */
				ChangePlayersTeam(client, PlayersForcedTeam[client]);
				return Plugin_Continue;
			}
			if (!has_flags(client)
			&& GetClientTeam(client) == biggerteam 
			&& PlayerSwitched[client] != true) {
				if (BuddySystem(client, _, true) != 0) {
					if (GetClientTeam(BuddySystem(client, _, true)) != GetClientTeam(client)) {
						if (LogActivity)
							LogAction(0, client, "[STB] With a balance in progress a buddy on the wrong team died and was switched.");
						if (LivingPlayerCheckTimer != INVALID_HANDLE) {
							CloseHandle(LivingPlayerCheckTimer);
							LivingPlayerCheckTimer = INVALID_HANDLE;
							if (LogActivity)
								LogAction(0, client, "[STB] Living player check timer was not needed and was killed before the callback.");
						}
						/* CALL THE STOCK CHANGE TEAM FUNCTION */
						ChangePlayersTeam(client, smallerteam);
						return Plugin_Continue;
					} else
						return Plugin_Continue;
				}
				if (PriorityPlayers && HasBuildingsBuilt(client))
					return Plugin_Continue;
				if (LogActivity)
					LogAction(0, client, "[STB] With a balance in progress a regular player died and was switched.");
				if (LivingPlayerCheckTimer != INVALID_HANDLE) {
					CloseHandle(LivingPlayerCheckTimer);
					LivingPlayerCheckTimer = INVALID_HANDLE;
					if (LogActivity)
						LogAction(0, client, "[STB] Living player check timer was not needed and was killed before the callback.");
				}
				PlayersForcedTeam[client] = smallerteam;
				/* CALL THE STOCK CHANGE TEAM FUNCTION */
				ChangePlayersTeam(client, smallerteam);
			}
		} else {
			/* NO BALANCE IN PROGRESS BUT BALANCE IS NEEDED */
			/* CHECK IF WE ARE FORCING PLAYERS */
			if (ForcePlayers) {
				/* SEE IF WE CAN FIND A FORCED PLAYER ON THE WRONG TEAM */
				new player = FindAForcedPlayer(smallerteam);
				if (player != 0 && PlayersForcedTeam[player] != 0) {
					/* FOUND ONE */
					LogAction(0, client, "[STB] With a balance needed a forced player died and was switched.");
					/* CALL THE STOCK CHANGE TEAM FUNCTION */
					ChangePlayersTeam(player, PlayersForcedTeam[player]);
					return Plugin_Continue;
				}
			}
			/* NOT FORCING PLAYERS OR NO FORCED PLAYER FOUND SO WE START A BALANCE */
			StartABalance();
		}
	}
	return Plugin_Continue;
}

public Action:HookPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new team = GetEventInt(event, "team");
	if (OkToBalance()) {
		new smallerteam = GetSmallerTeam();
		if (smallerteam == 0)
			return Plugin_Continue;
		if (PlayerSwitched[client]
		&& ForcePlayers 
		&& PlayersForcedTeam[client] == smallerteam
		&& team != smallerteam
		&& IsUnbalanced()) {
			if (LogActivity)
				LogAction(0, client, "[STB] A forced player tried to change teams making them inbalanced and was switched back.");
			ChangePlayersTeam(client, PlayersForcedTeam[client]);
		} else if (LivingPlayerTimer[client] != INVALID_HANDLE
		&& team == PlayersForcedTeam[client]
		&& BalanceInProgress) {
			CloseHandle(LivingPlayerTimer[client]);
			LivingPlayerTimer[client] = INVALID_HANDLE;
			if (LogActivity)
				LogAction(0, client, "[STB] A player accepted his balance before the delay and gets a reward.");
			if (LivingPlayerCheckTimer != INVALID_HANDLE) {
				CloseHandle(LivingPlayerCheckTimer);
				LivingPlayerCheckTimer = INVALID_HANDLE;
				if (LogActivity)
					LogAction(0, client, "[STB] Living player check timer was not needed and was killed before the callback.");
			}
			CleanUp(client);
			BalanceInProgress = false;
		} else if (IsUnbalanced() 
		&& !BalanceInProgress) {
			StartABalance();
		}
	}
	return Plugin_Continue;
}

public HookRoundStart(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (IsArenaMode)
		return;
	if (LogActivity)
			LogAction(0, -1, "[STB] Round Started");
	RoundStart = true;
	RoundEnd = false;
	SuddenDeath = false;
	OutOfTime = false;
	TeamsSwitched = DidTeamsSwitch();
	ResetTeams();
	if (TeamsSwitched) {
		if (LogActivity)
			LogAction(0, -1, "[STB] Teams were switched");
		SwitchForcedTeams();
	}
	CreateTimer(float(roundstartdelay), Timer_RoundStart);
	return;
}

public Action:HookRoundEnd(Handle:event, const String:name[], bool:dontBroadcast)
{
	RoundEnd = true;
	TeamsSwitched = false;
	OldBlueScore = GetTeamScore(TEAM_BLUE);
	OldRedScore = GetTeamScore(TEAM_RED);
	SavePlayersTeams();
	if (LogActivity)
		LogAction(0, -1, "[STB] Round Ended");
	return Plugin_Continue;
}

public HookSuddenDeathBegin(Handle:event, const String:name[], bool:dontBroadcast)
{
	SuddenDeath = true;
	return;
}

public HookControlPointCapture(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (OutOfTime)
		OutOfTime = false;
	return;
}

public Action:HookFlagEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetEventInt(event, "player");
	new flag_status = GetEventInt(event, "eventtype");
	if (!IsClientInGame(client))
		return;
	switch (flag_status)
	{
		case 1:
		//The flag was picked up
		{
			PlayerIsFlagCarrier[client] = true;
		}
		case 2:
		//The flag was capped
		{
			PlayerIsFlagCarrier[client] = false;
		}
		case 3:
		//The flag was defended
		{
			return;
		}
		case 4:
		//The flag was dropped
		{
			PlayerIsFlagCarrier[client] = false;
		}
	}
	return;
}

public EntityOutput_TimeLeft(const String:output[], caller, activator, Float:delay)
{
	OutOfTime = true;
	return;
}

/* COMMAND EVENTS */

public Action:Command_AddBalanceBuddy(client, args)
{
	if (client == 0) {
		ReplyToCommand(client, "[SM] %T", "PlayerLevelCmd", LANG_SERVER);
		return Plugin_Handled;
	}
	if (!IsEnabled || !BuddyEnabled) {
		ReplyToCommand(client, "[SM] %T", "CmdDisabled", LANG_SERVER);
		return Plugin_Handled;
	}
	if (BuddyRestriction) {
		if (!has_flags(client)) {
			ReplyToCommand(client, "[SM] %T", "RestrictedBuddy", LANG_SERVER);
			return Plugin_Handled;
		}
	}
	decl String:playeruserid[MAX_STRING_LEN];
	GetCmdArg(1, playeruserid, MAX_STRING_LEN);
	new player = GetClientOfUserId(StringToInt(playeruserid));
	if (!player || !IsClientInGame(player) || client == player) {
		if (client == player) {
			PrintHintText(client, "%T", "SelectSelf", LANG_SERVER);
		}
		ReplyToCommand(client, "[SM] Usage: buddy <userid>");
		new Handle:playermenu = BuildPlayerMenu();
		DisplayMenu(playermenu, client, MENU_TIME_FOREVER);	
	} else {
		decl String:cName[MAX_STRING_LEN];
		decl String:bName[MAX_STRING_LEN];
		GetClientName(client, cName, MAX_STRING_LEN);
		GetClientName(player, bName, MAX_STRING_LEN);
		if (PlayerBuddyLock[player]) {
			ReplyToCommand(client, "[SM] %T", "PlayerLockedBuddyMsg", LANG_SERVER, bName);
			return Plugin_Handled;
		}
		BuddySystem(client, player);
		PrintHintText(client, "%T", "BuddyMsg", LANG_SERVER, bName);
		PrintHintText(player, "%T", "BuddyMsg", LANG_SERVER, cName);
	}
	return Plugin_Handled;	
}

public Action:Command_LockBuddy(client, args)
{
	if (client == 0) {
		ReplyToCommand(client, "[SM] %T", "PlayerLevelCmd", LANG_SERVER);
		return Plugin_Handled;
	}
	if (!IsEnabled) {
		ReplyToCommand(client, "[SM] %T", "CmdDisabled", LANG_SERVER);
		return Plugin_Handled;
	}
	if (BuddyRestriction) {
		if (!has_flags(client)) {
			ReplyToCommand(client, "[SM] %T", "RestrictedBuddy", LANG_SERVER);
			return Plugin_Handled;
		}
	}
	if (PlayerBuddyLock[client]) {
		PlayerBuddyLock[client] = false;
		PrintHintText(client, "%T", "BuddyLockMsgDisabled", LANG_SERVER);
	} else {
		PlayerBuddyLock[client] = true;
		PrintHintText(client, "%T", "BuddyLockMsgEnabled", LANG_SERVER);
	}
	return Plugin_Handled;
}

/* STOCK FUNCTIONS */

stock bool:IsUnbalanced()
{
	if (LogActivity2)
		LogAction(0, -1, "[STB] Checking if teams are unbalanced");
	new rtCount = GetTeamClientCount(TEAM_RED);
	new btCount = GetTeamClientCount(TEAM_BLUE);
	new Float:ubCount = FloatAbs(float(btCount - rtCount));
	if (ubCount > float(unbalancelimit)) {
		if (LogActivity2)
			LogAction(0, -1, "[STB] Teams are unbalanced");
		return true;
	}
	if (LogActivity2)
		LogAction(0, -1, "[STB] Teams are not unbalanced");
	return false;
}

stock bool:OkToBalance()
{
	if (LogActivity2)
		LogAction(0, -1, "[STB] Checking if OK to balance.");
	new bool:result = false;
	if (IsEnabled
	&& !RoundStart
	&& !RoundEnd
	&& !IsArenaMode
	&& !SuddenDeath
	&& !OutOfTime) {
		if (LogActivity2) {
			LogAction(0, -1, "[STB] Passed IF statement");
			LogAction(0, -1, "[STB] Now checking admins");
		}
		for (new i = 1; i <= maxclients; i++) {
			if (IsClientInGame(i) && !has_flags(i)) {
				if (LogActivity2) {
					LogAction(0, -1, "[STB] Found at least 1 non-admin");
					LogAction(0, -1, "[STB] OK to balance");
				}
				result = true;
				break;
			}
		}
		if (!result && LogActivity2)
			LogAction(0, -1, "[STB] All admins online");
	}
	if (!result && LogActivity2)
		LogAction(0, -1, "[STB] Not OK to balance");
	return result;
}

stock StartABalance()
{
	if (BalanceTimer != INVALID_HANDLE) {
		if (!IsUnbalanced() || !OkToBalance()) {
			BalanceTimer = INVALID_HANDLE;
			CloseHandle(BalanceTimer);
			BalanceInProgress = false;
			if (LogActivity)
				LogAction(0, -1, "[STB] Balance delay timer was not needed and was killed before the callback.");
			return;
		} else
			return;
	}
	PrintToChatAll("[SM] %T", "UnBalanced", LANG_SERVER);
	if (balancedelay == 0) {
		if (LogActivity)
			LogAction(0, -1, "[STB] Balance is now in progress.");
		BalanceInProgress = true;
		BalanceTimer = INVALID_HANDLE;
		if (!DeadOnly) {
			if (LogActivity)
				LogAction(0, -1, "[STB] Now scanning dead players.");
			StartALivingPlayerTimer();
		} else {
			if (LogActivity)
				LogAction(0, -1, "[STB] Only scanning dead players.");
		}
		return;
	}
	BalanceTimer = CreateTimer(float(balancedelay), Timer_BalanceTeams, _, TIMER_FLAG_NO_MAPCHANGE);
	if (LogActivity)
		LogAction(0, -1, "[STB] Teams are unbalanced.  Balance delay timer started.");
	return;
}

stock StartALivingPlayerTimer()
{
	if (LivingPlayerCheckTimer != INVALID_HANDLE) {
		LivingPlayerCheckTimer = INVALID_HANDLE;
		CloseHandle(LivingPlayerCheckTimer);
		if (LogActivity)
			LogAction(0, -1, "[STB] Living player balance delay timer detected and was closed for current process.");
	}	
	if (LogActivity)
		LogAction(0, -1, "[STB] Living player balance delay timer started.");
	LivingPlayerCheckTimer = CreateTimer(float(livingplayercheckdelay), Timer_LivingPlayerCheck, _, TIMER_FLAG_NO_MAPCHANGE);
	return;
}

stock FindSwitchableDeadPlayer(biggerteam)
{
	new player = 0;
	for (new i = 1; i <= maxclients; i++) {
		if (!IsClientInGame(i) 
		|| has_flags(i) 
		|| GetClientTeam(i) != biggerteam 
		|| PlayerSwitched[i] == true 
		|| IsPlayerAlive(i)) {
			continue;
		} else {
			if (BuddySystem(i, _, true) != 0) {
				if (GetClientTeam(BuddySystem(i, _, true)) != GetClientTeam(i)) {
					if (LogActivity)
						LogAction(0, -1, "[STB] With a balance in progress a buddy on the wrong team was found dead in the scan and was switched.");
					player = i;
					break;
				} else {
					if (LogActivity)
						LogAction(0, -1, "[STB] With a balance in progress a buddy on the right team was found and skipped.");
					continue;
				}
			} else {
				if (PriorityPlayers && HasBuildingsBuilt(i))
					continue;
				player = i;
				break;
			}
		}
	}
	return player;
}

stock FindSwitchableCustomPlayer(biggerteam)
{
	new player = 0;
	for (new i = 1; i <= maxclients; i++) {
		if (!IsClientInGame(i) 
		|| has_flags(i) 
		|| GetClientTeam(i) != biggerteam 
		|| PlayerSwitched[i]
		|| PlayerIsFlagCarrier[i]
		|| HasUber(i)
		|| HasBuildingsBuilt(i)) {
			continue;
		} else {
			if (BuddySystem(i, _, true) != 0) {
				if (GetClientTeam(BuddySystem(i, _, true)) != GetClientTeam(i)) {
					if (LogActivity)
						LogAction(0, -1, "[STB] With a balance in progress a buddy on the wrong team was found alive in the scan and was switched.");
					player = i;
					break;
				} else {
					if (LogActivity)
						LogAction(0, -1, "[STB] With a balance in progress a buddy on the right team was found and skipped.");
					continue;
				}
			}
			player = i;
			break;
		}
	}
	return player;
}

stock FindAForcedPlayer(smallerteam)
{
	new player = 0;
	for (new i = 1; i <= maxclients; i++) {
		if (IsClientInGame(i) 
		&& PlayersForcedTeam[i] != 0
		&& GetClientTeam(i) != PlayersForcedTeam[i]
		&& PlayersForcedTeam[i] == smallerteam) {
			player = i;
			break;
		} else {
			continue;
		}
	}
	return player;
}

stock ChangePlayersTeam(client, unbalancedteam)
{
	if (ForcedPlayerTimer[client] != INVALID_HANDLE) {
		CloseHandle(ForcedPlayerTimer[client]);
		ForcedPlayerTimer[client] = INVALID_HANDLE;
		if (LogActivity)
			LogAction(0, client, "[STB] Had to kill a forced player timer because we switched him again.");
	}
	new Handle:pack = CreateDataPack();
	WritePackCell(pack, client);
	WritePackCell(pack, unbalancedteam);
	CreateTimer(0.1, Timer_TeamSwitch, pack, TIMER_FLAG_NO_MAPCHANGE);
}

stock BuddySystem(client, buddy = 0, bool:check = false)
{
	if (check) {
		new iclient = PlayersBuddy[client];
		new ibuddy = PlayersBuddy[buddy];
		if (iclient == 0 || ibuddy == 0 || iclient != ibuddy) {
			return 0;
		} else {
			return iclient;
		}
	} else {
		PlayersBuddy[client] = buddy;
		PlayersBuddy[buddy] = client;
	}
	return 0;
}

stock CleanUp(client)
{
	PlayersForcedTeam[client] = 0;
	PlayerSwitched[client] = false;
	PlayerIsFlagCarrier[client] = false;
	if (ForcedPlayerTimer[client] != INVALID_HANDLE) {
		CloseHandle(ForcedPlayerTimer[client]);
		ForcedPlayerTimer[client] = INVALID_HANDLE;
		if (LogActivity)
			LogAction(0, client, "[STB] Had to kill a forced player timer.");
	}
	if (LivingPlayerTimer[client] != INVALID_HANDLE) {
		CloseHandle(LivingPlayerTimer[client]);
		LivingPlayerTimer[client] = INVALID_HANDLE;
		if (LogActivity)
			LogAction(0, client, "[STB] Had to kill a living player timer.");
	}
	return;
}

stock bool:IsSwitchablePlayer(client, biggerteam)
{
	if (!IsClientInGame(client)
		|| has_flags(client)
		|| PlayerIsFlagCarrier[client]
		|| GetClientTeam(client) != biggerteam
		|| PlayerSwitched[client])	{
		return false;
	} else {
		return true;
	}
}

stock bool:HasUber(client)
{
	new Float:chargeLevel;
	decl String:weaponName[32];
	GetClientWeapon(client, weaponName, sizeof(weaponName));
	if(TF2_GetPlayerClass(client) == TFClass_Medic){
		if(StrEqual(weaponName, "tf_weapon_medigun" )){
			new entityIndex = GetEntDataEnt2(client, FindSendPropInfo("CTFPlayer", "m_hActiveWeapon"));
			chargeLevel = GetEntDataFloat(entityIndex, FindSendPropInfo("CWeaponMedigun", "m_flChargeLevel"));
			if (chargeLevel >= uberlevel) {
				if (LogActivity2)
					LogAction(0, client, "[STB] Found a medic with a uber and skipped him.");
				return true;
			}
		}
	}
	return false;
}

stock bool:HasBuildingsBuilt(client)
{
	new maxentities = GetMaxEntities();
	for (new i = maxclients + 1; i <= maxentities; i++)
	{
		if (!IsValidEntity(i))
			continue;
		decl String:netclass[32];
		GetEntityNetClass(i, netclass, sizeof(netclass));
		if (strcmp(netclass, "CObjectSentrygun") == 0 
		|| strcmp(netclass, "CObjectTeleporter") == 0 
		|| strcmp(netclass, "CObjectDispenser") == 0) {
			if (GetEntDataEnt2(i, ownerOffset) == client) {
				if (LogActivity2)
					LogAction(0, client, "[STB] Found an engineer with buildings and skipped him.");
				return true;
			}
		}
	}
	return false;
}

stock bool:has_flags(id)
{
	decl String:flags[MAX_STRING_LEN];
	GetConVarString(stb_adminflag, flags, MAX_STRING_LEN);
	new ibFlags = ReadFlagString(flags);
	if ((GetUserFlagBits(id) & ibFlags) == ibFlags) {
	return true;
	}
	if (GetUserFlagBits(id) & ADMFLAG_ROOT) {
		return true;
	}
	return false;
}

stock GetSmallerTeam()
{
	new rtCount = GetTeamClientCount(TEAM_RED);
	new btCount = GetTeamClientCount(TEAM_BLUE);
	if (rtCount < btCount)
		return TEAM_RED;
	else if (rtCount > btCount)
		return TEAM_BLUE;
	else if (rtCount == btCount)
		return 0;
	return 0;
}

stock GetBiggerTeam()
{
	new rtCount = GetTeamClientCount(TEAM_RED);
	new btCount = GetTeamClientCount(TEAM_BLUE);
	if (rtCount > btCount)
		return TEAM_RED;
	else if (rtCount < btCount)
		return TEAM_BLUE;
	else if (rtCount == btCount)
		return 0;
	return 0;
}

stock SavePlayersTeams()
{
	for (new i = 1; i <= maxclients; i++) {
		if (IsClientInGame(i))
			PlayersTeam[i] = GetClientTeam(i);
	}
}

stock ResetTeams()
{
	for (new i = 1; i <= maxclients; i++) {
		PlayersTeam[i] = 0;
	}
}

stock bool:DidTeamsSwitch()
{
	if (OldBlueScore != OldRedScore) {
		if (OldBlueScore != GetTeamScore(TEAM_BLUE)
		&& OldRedScore != GetTeamScore(TEAM_RED))
			return true;
		else
			return false;
	} else {
		new cteam, count;
		count = GetClientCount();
		if (count == 0)
			return false;
		for (new i = 1; i <= maxclients; i++) {
			if (IsClientInGame(i) && PlayersTeam[i] != 0) {
				if (PlayersTeam[i] != GetClientTeam(i))
					cteam++;
			}
		}
		if ((cteam / count) > 0.60)
			return true;
	}
	return false;
}

stock SwitchForcedTeams()
{
	for (new i = 1; i <= maxclients; i++) {
		if (PlayersForcedTeam[i] != 0) {
			if (PlayersForcedTeam[i] == TEAM_RED)
				PlayersForcedTeam[i] = TEAM_BLUE;
			else if (PlayersForcedTeam[i] == TEAM_BLUE)
				PlayersForcedTeam[i] = TEAM_RED;
		}
	}
	return;
}

/* NATIVE FUNCTIONS */

public Native_STB_MovePlayerUnForced(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new team = GetNativeCell(2);
	if (IsFakeClient(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Bots are not supported");
	if (client < 1 || client > GetMaxClients())
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	if (!IsClientConnected(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	if (GetClientTeam(client) == team)
		return false;
	CleanUp(client);
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);
	return true;
}

public Native_STB_MovePlayerForced(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new team = GetNativeCell(2);
	if (IsFakeClient(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Bots are not supported");
	if (client < 1 || client > GetMaxClients())
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	if (!IsClientConnected(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	if (team != TEAM_RED && team != TEAM_BLUE)
		return ThrowNativeError(SP_ERROR_NATIVE, "Team %d is not a valid team", team);
	if (GetClientTeam(client) == team)
		return false;
	if (ForcedPlayerTimer[client] != INVALID_HANDLE) {
		CloseHandle(ForcedPlayerTimer[client]);
		ForcedPlayerTimer[client] = INVALID_HANDLE;
		if (LogActivity)
			LogAction(0, client, "[STB] Had to kill a forced player timer because a native call switched him again.");
	}
	ChangeClientTeam(client, team);
	TF2_RespawnPlayer(client);
	PlayersForcedTeam[client] = team;
	PlayerSwitched[client] = true;
	ForcedPlayerTimer[client] = CreateTimer(float(switchbackforced), Timer_DontSwitchAgain, client, TIMER_FLAG_NO_MAPCHANGE);
	return true;
}

public Native_STB_RemoveForcedPlayer(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	if (IsFakeClient(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Bots are not supported");
	if (client < 1 || client > GetMaxClients())
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	if (!IsClientConnected(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	CleanUp(client);
	return true;
}

public Native_STB_SetBalanceBuddies(Handle:plugin, numParams)
{
	new client = GetNativeCell(1);
	new player = GetNativeCell(2);
	if (IsFakeClient(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Bots are not supported");
	if (client < 1 || client > GetMaxClients())
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid client index (%d)", client);
	if (!IsClientConnected(client))
		return ThrowNativeError(SP_ERROR_NATIVE, "Client %d is not connected", client);
	if (player < 0 || player > GetMaxClients())
		return ThrowNativeError(SP_ERROR_NATIVE, "Invalid player index (%d)", player);
	if (player > 1 && !IsClientConnected(player))
		return ThrowNativeError(SP_ERROR_NATIVE, "Player %d is not connected", player);
	if (player != 0) {
		BuddySystem(client, player);
		BuddySystem(player, client);
	} else
		BuddySystem(client, player);
	return true;
}

/* TIMER FUNCTIONS */

public Action:Timer_BalanceTeams(Handle:timer, any:client)
{
	if (!IsUnbalanced() || !OkToBalance()) {
		BalanceInProgress = false;
		if (LogActivity)
			LogAction(0, -1, "[STB] Balance delay timer was not needed and died.");
		BalanceTimer = INVALID_HANDLE;
		return Plugin_Handled;
	}
	if (LogActivity)
		LogAction(0, -1, "[STB] Teams are still unbalanced.  Balance is now in progress.");
	BalanceInProgress = true;
	BalanceTimer = INVALID_HANDLE;
	if (!DeadOnly) {
		if (LogActivity)
			LogAction(0, -1, "[STB] Now scanning dead players.");
		StartALivingPlayerTimer();
	} else {
		if (LogActivity)
			LogAction(0, -1, "[STB] Only scanning dead players.");
	}
	return Plugin_Handled;
}

public Action:Timer_LivingPlayerCheck(Handle:timer, any:client)
{
	if (!IsUnbalanced() || !OkToBalance()) {
		BalanceInProgress = false;
		if (LogActivity)
			LogAction(0, -1, "[STB] Living player balance delay timer was not needed and died.");
		LivingPlayerCheckTimer = INVALID_HANDLE;
		return Plugin_Handled;
	}
	new smallerteam = GetSmallerTeam();
	new biggerteam = GetBiggerTeam();
	if (smallerteam == 0 || biggerteam == 0)
		return Plugin_Handled;
	new Handle:pack = CreateDataPack();
	new player = FindSwitchableDeadPlayer(biggerteam);
	if (player != 0) {
		if (LogActivity)
			LogAction(0, player, "[STB] Found a dead player after the scan.");
		ChangePlayersTeam(player, smallerteam);
		LivingPlayerCheckTimer = INVALID_HANDLE;
		return Plugin_Handled;
	}
	if (PriorityPlayers) {
		player = FindSwitchableCustomPlayer(biggerteam);
	}
	if (player == 0) {
		do {
			player = GetRandomInt(1, maxclients);
		} while (!IsSwitchablePlayer(player, biggerteam));
		if (LogActivity)
			LogAction(0, player, "[STB] Found a random living player.");
	} else {
		if (LogActivity)
			LogAction(0, player, "[STB] Found a custom living player.");
	}
	PlayersForcedTeam[client] = smallerteam;
	if (!IsPlayerAlive(player)) {
		ChangePlayersTeam(player, smallerteam);
		LivingPlayerCheckTimer = INVALID_HANDLE;
		return Plugin_Handled;
	} else {
		PrintHintText(player, "%T", "PlayerMessage", LANG_SERVER, livingplayerswitchdelay);
		if (LogActivity)
			LogAction(0, player, "[STB] Living player placed on a timer.");
		WritePackCell(pack, player);
		WritePackCell(pack, smallerteam);
		LivingPlayerTimer[player] = CreateTimer(float(livingplayerswitchdelay), Timer_LivingPlayerSwitch, pack, TIMER_FLAG_NO_MAPCHANGE);
	}
	LivingPlayerCheckTimer = INVALID_HANDLE;
	return Plugin_Handled;
}

public Action:Timer_LivingPlayerSwitch(Handle:timer, Handle:pack)
{
	new client, unbalancedteam;
	ResetPack(pack);
	client = ReadPackCell(pack);
	unbalancedteam = ReadPackCell(pack);
	CloseHandle(pack);
	if (!IsUnbalanced() 
	|| !IsClientConnected(client) 
	|| !OkToBalance()
	|| PlayerIsFlagCarrier[client]) {
		BalanceInProgress = false;
		PlayersForcedTeam[client] = 0;
		LivingPlayerTimer[client] = INVALID_HANDLE;
		if (LogActivity)
			if (PlayerIsFlagCarrier[client])
				LogAction(0, client, "[STB] Living player became flag carrier, balance restarted.");
			else
				LogAction(0, client, "[STB] Living player timer was not needed and died.");
		return Plugin_Handled;
	}
	if (LogActivity)
		LogAction(0, client, "[STB] Living player was switched.");
	LivingPlayerTimer[client] = INVALID_HANDLE;
	ChangePlayersTeam(client, unbalancedteam);
	return Plugin_Handled;
}

public Action:Timer_TeamSwitch(Handle:timer, Handle:pack)
{
	new client, unbalancedteam;
	ResetPack(pack);
	client = ReadPackCell(pack);
	unbalancedteam = ReadPackCell(pack);
	CloseHandle(pack);
	if (unbalancedteam == 0) {
		if (LogActivity)
			LogAction(0, client, "[STB] Balance failed due to invalid team number %i", unbalancedteam);
		return;
	}
	ChangeClientTeam(client, unbalancedteam);
	TF2_RespawnPlayer(client);
	decl String:playername[MAX_STRING_LEN];
	GetClientName(client, playername, MAX_STRING_LEN);
	if (LogActivity)
		LogAction(0, client, "[STB] Changed %s to team %i.", playername, unbalancedteam);
	PrintToChatAll("[SM] %T", "BalanceMessage", LANG_SERVER, playername);
	new Handle:event = CreateEvent("teamplay_teambalanced_player");
	SetEventInt(event, "player", client);
	SetEventInt(event, "team", unbalancedteam);
	FireEvent(event);
	PlayerSwitched[client] = true;
	ForcedPlayerTimer[client] = CreateTimer(float(switchbackforced), Timer_DontSwitchAgain, client, TIMER_FLAG_NO_MAPCHANGE);
	BalanceInProgress = false;
	if (LogActivity)
		LogAction(0, client, "[STB] Balance finished.");
	return;
}

public Action:Timer_RoundStart(Handle:timer, any:client)
{
	RoundStart = false;
	if (OkToBalance()
	&& IsUnbalanced()
	&& !BalanceInProgress) {
		StartABalance();
	}
	return Plugin_Handled;
}

public Action:Timer_DontSwitchAgain(Handle:timer, any:client)
{
	PlayerSwitched[client] = false;
	PlayersForcedTeam[client] = 0;
	ForcedPlayerTimer[client] = INVALID_HANDLE;
	return Plugin_Handled;
}

public Action:Timer_WelcomeAdvert(Handle:timer, any:client)
{
	if (IsClientConnected(client) && IsClientInGame(client)) {
		PrintToChat (client, "\x01\x04[STB]\x01 %T", "BuddyWelcomeMsg1", LANG_SERVER);
		PrintToChat (client, "\x01\x04[STB]\x01 %T", "BuddyWelcomeMsg2", LANG_SERVER);
		PrintToChat (client, "\x01\x04[STB]\x01 %T", "BuddyWelcomeMsg3", LANG_SERVER);
	}
	return Plugin_Handled;
}

/* CONSOLE VARIABLE CHANGE EVENT */

public ConVarSettingsChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == stb_enabled) {
		if (StringToInt(newValue) == 0) {
			if (!IsHooked) {
				LogAction(-1, -1, "[STB] Hooking round events for game: %s", GameType);
				HookEvent("player_death", HookPlayerDeath, EventHookMode_Post);
				HookEvent("player_team", HookPlayerChangeTeam, EventHookMode_Pre);
				HookEntityOutput("team_round_timer", "On1MinRemain", EntityOutput_TimeLeft);
				if(StrEqual(GameType, "dod")) {
					HookEvent("dod_round_start", HookRoundStart, EventHookMode_PostNoCopy);
					HookEvent("dod_round_win", HookRoundEnd, EventHookMode_Post);
				}
				else if(StrEqual(GameType, "tf")) {
					HookEvent("teamplay_round_start", HookRoundStart, EventHookMode_PostNoCopy);
					HookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
					HookEvent("teamplay_suddendeath_begin", HookSuddenDeathBegin, EventHookMode_PostNoCopy);
					HookEvent("teamplay_point_captured", HookControlPointCapture, EventHookMode_PostNoCopy);
					HookEvent("teamplay_flag_event", HookFlagEvent, EventHookMode_Post);
				}
				IsHooked = true;
			}
			if (ConVarControl) {
				SetConVarInt(stb_mp_autoteambalance, 0);
				SetConVarInt(stb_mp_teams_unbalance_limit, unbalancelimit);
			}
			IsEnabled = true;
			PrintToChatAll("[SM] %T", "Enabled", LANG_SERVER);
			LogAction(0, -1, "[SimpleTeamBalancer] Enabled");
		} else {
			LogAction(-1, -1, "[STB] Unhooking round events for game: %s", GameType);
			UnhookEvent("player_death", HookPlayerDeath, EventHookMode_Post);
			UnhookEvent("player_team", HookPlayerChangeTeam, EventHookMode_Pre);
			UnhookEntityOutput("team_round_timer", "On1MinRemain", EntityOutput_TimeLeft);
			if(StrEqual(GameType, "dod")) {
				UnhookEvent("dod_round_start", HookRoundStart, EventHookMode_PostNoCopy);
				UnhookEvent("dod_round_win", HookRoundEnd, EventHookMode_Post);
			}
			else if(StrEqual(GameType, "tf")) {
				UnhookEvent("teamplay_round_start", HookRoundStart, EventHookMode_PostNoCopy);
				UnhookEvent("teamplay_round_win", HookRoundEnd, EventHookMode_Post);
				UnhookEvent("teamplay_suddendeath_begin", HookSuddenDeathBegin, EventHookMode_PostNoCopy);
				UnhookEvent("teamplay_point_captured", HookControlPointCapture, EventHookMode_PostNoCopy);
				UnhookEvent("teamplay_flag_event", HookFlagEvent, EventHookMode_Post);
			}
			IsHooked = false;
			IsEnabled = false;
			PrintToChatAll("[SM] %T", "Disabled", LANG_SERVER);
			LogAction(0, -1, "[SimpleTeamBalancer] Disabled");
		}
	}
	else if (convar == stb_logactivity) {
		if (StringToInt(newValue) == 0) {
			LogActivity = false;
			LogAction(0, -1, "[STB] Log Activity DISABLED.");
		} else {
			LogActivity = true;
			LogAction(0, -1, "[STB] Log Activity ENABLED.");
		}
	}
	else if (convar == stb_logactivity2) {
		if (StringToInt(newValue) == 0) {
			LogActivity = false;
			LogAction(0, -1, "[STB] Detailed Log Activity DISABLED.");
		} else {
			LogActivity = true;
			LogAction(0, -1, "[STB] Detailed Log Activity ENABLED.");
		}
	}
	else if (convar == stb_convarcontrol) {
		if (StringToInt(newValue) == 0)
			ConVarControl = false;
		else
			ConVarControl = true;
		if (ConVarControl && IsEnabled) {
			SetConVarInt(stb_mp_autoteambalance, 0);
			SetConVarInt(stb_mp_teams_unbalance_limit, unbalancelimit);
		}
	}
	else if (convar == stb_deadonly) {
		if (StringToInt(newValue) == 0)
			DeadOnly = false;
		else
			DeadOnly = true;
	}
	else if (convar == stb_priorityenabled) {
		if (StringToInt(newValue) == 0)
			PriorityPlayers = false;
		else
			PriorityPlayers = true;
	}
	else if (convar == stb_forcedenabled) {
		if (StringToInt(newValue) == 0)
			ForcePlayers = false;
		else
			ForcePlayers = true;
	}
	else if (convar == stb_buddyenabled) {
		if (StringToInt(newValue) == 0)
			BuddyEnabled = false;
		else
			BuddyEnabled = true;
	}
	else if (convar == stb_buddyrestriction) {
		if (StringToInt(newValue) == 0)
			BuddyRestriction = false;
		else
			BuddyRestriction = true;
	}
	else if (convar == stb_unbalancelimit) {
		unbalancelimit = StringToInt(newValue);
		if (ConVarControl && IsEnabled)
			SetConVarInt(stb_mp_teams_unbalance_limit, unbalancelimit);
	}
	else if (convar == stb_balancedelay)
		balancedelay = StringToInt(newValue);
	else if (convar == stb_roundstartdelay)
		roundstartdelay = StringToInt(newValue);
	else if (convar == stb_livingplayerswitchdelay)
		livingplayerswitchdelay = StringToInt(newValue);
	else if (convar == stb_livingplayercheckdelay)
		livingplayercheckdelay = StringToInt(newValue);
	else if (convar == stb_uberlevel)
		uberlevel = StringToFloat(newValue);
	else if (convar == stb_switchbackforced)
		switchbackforced = StringToInt(newValue);
	else if (convar == stb_adminflag)
		SetConVarString(stb_adminflag, newValue);
	else if (convar == stb_version)
		SetConVarString(stb_version, PLUGIN_VERSION);
	else if (convar == stb_mp_autoteambalance) {
		if (ConVarControl && IsEnabled)
			SetConVarInt(stb_mp_autoteambalance, 0);
	}
	else if (convar == stb_mp_teams_unbalance_limit) {
		if (ConVarControl && IsEnabled)
			SetConVarInt(stb_mp_teams_unbalance_limit, unbalancelimit);
	}
	
}

/* MENU CODE */

stock Handle:BuildPlayerMenu()
{
	new Handle:menu = CreateMenu(Menu_SelectPlayer);
	AddTargetsToMenu(menu, 0, true, false);
	SetMenuTitle(menu, "Select A Player:");
	SetMenuExitButton(menu, true);
	return menu;
}

public Menu_SelectPlayer(Handle:menu, MenuAction:action, param1, param2)
{
	if (action == MenuAction_Select) {
		new String:selection[MAX_STRING_LEN];
		GetMenuItem(menu, param2, selection, MAX_STRING_LEN);
		new buddy = GetClientOfUserId(StringToInt(selection));
		if (param1 == buddy) {
			PrintHintText(param1, "%T", "SelectSelf", LANG_SERVER);
		} else if (!IsClientInGame(buddy)) {
			PrintHintText(param1, "%T", "BuddyGone", LANG_SERVER);
		} else {
			decl String:cName[MAX_STRING_LEN];
			decl String:bName[MAX_STRING_LEN];
			GetClientName(param1, cName, MAX_STRING_LEN);
			GetClientName(buddy, bName, MAX_STRING_LEN);
			if (!PlayerBuddyLock[buddy]) {
				BuddySystem(param1, buddy);
				PrintHintText(param1, "%T", "BuddyMsg", LANG_SERVER, bName);
				PrintHintText(buddy, "%T", "BuddyMsg", LANG_SERVER, cName);
			} else
				PrintHintText(param1, "%T", "PlayerLockedBuddyMsg", LANG_SERVER, bName);
		}
	} else if (action == MenuAction_End) {
		CloseHandle(menu);
	}
}