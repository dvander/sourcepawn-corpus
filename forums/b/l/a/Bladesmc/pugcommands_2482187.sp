/*
*	TODO LIST
*	1. Fix bugs and clean up code (lots fixed but there still may be more)	
* 	2. SEMI-IMPORTANT: Document code, this includes comments and formatting.
*	3. Restore backup rounds easily?											
* 	(could be done by using already existing round_end event				
*	and saving when it's called)											
* 																			
*	ONCE THESE TASKS HAVE BEEN COMPLETED, IT IS READY FOR PUBLISHING		
*																			
*	COMPLETED! :DD														
*	1. 	Ready up system														
*	2. 	Kniferound															
*	3. 	Cvars																
*	4. 	Pause system														
*	5. 	Admin commands														
*	6. 	Voting																
*	7. 	Able to force-start match without 10 players						
*	8. 	Hud hint															
*	9. Readysystem CVar														
*/

#include <sourcemod>
#include <sdktools>
#include <admin>
#include <timers>
#include <events>
#include <cstrike>
#include <sdkhooks>
#include <clientprefs>
#include <halflife>

#define TEAM_ONE 5
#define TEAM_TWO 6
#define SPECTATE 7

//ConVar g_WarmupPause;
ConVar g_RestartGame;
ConVar g_KnifeEnabled;
ConVar g_RequiredReadies;
ConVar g_RequiredReadiesForce;
ConVar g_ReadyOn;

/* Don't need these right now.
int iTeamOneSide;
int iTeamTwoSide;
bool lockTeams = false;
*/

bool alive[MAXPLAYERS + 1];

bool readyStatus[MAXPLAYERS + 1];
//int globalTeam[MAXPLAYERS + 1];
int readyCount = 0;
bool live = false;
int clientThatPaused;
int requiredReadies;
int requiredReadiesForceStart;
bool knifeRound = false;
int knifeWinner;
bool knifeVote = false;
int knifeVoteStay=0;
int knifeVoteSwitch=0;
bool clientVoteStatus[MAXPLAYERS + 1];
int knifeCVar;
int readyCVar;

public Plugin:myinfo = 
{
	name = "[10man] Pug System",
	author = "Bladesmc",
	description = "!pughelp",
	version = "2.1",
	url = "steamcommunity.com/id/bladesmc"
}

public void OnPluginStart()
{
	//REGISTER PLAYER COMMANDS
	/****************************************************
	* 													*
	* 	SIDENOTE: Comment out any lines that defines	*
	* 	a command if that command conflicts with		*
	* 	another command in your server.					*
	* 													*
	****************************************************/
	//READY
	RegConsoleCmd("sm_readyup", Command_Ready, "Ready up.");
	RegConsoleCmd("sm_ready", Command_Ready, "Ready up.");
	RegConsoleCmd("sm_r", Command_Ready, "Ready up.");
	//NOT READY
	RegConsoleCmd("sm_readydown", Command_NotReady, "Not ready.");
	RegConsoleCmd("sm_notready", Command_NotReady, "Not ready.");
	RegConsoleCmd("sm_unready", Command_NotReady, "Not ready.");
	RegConsoleCmd("sm_nr", Command_NotReady, "Not ready.");
	RegConsoleCmd("sm_ur", Command_NotReady, "Not ready.");
	//READY COUNT
	RegConsoleCmd("sm_readycount", Command_ReadyCount, "Print readyCount");
	RegConsoleCmd("sm_clientcount", Command_ClientCount, "Print client count");
	RegConsoleCmd("sm_rc", Command_ReadyCount, "Print readyCount");
	//STATUS
	RegConsoleCmd("sm_mystatus", Command_MyStatus, "Print player's ready status");
	RegConsoleCmd("sm_ms", Command_MyStatus, "Print player's ready status");
	//HELP
	RegConsoleCmd("sm_pugcommands", Command_PugHelp, "Print pug commands");
	RegConsoleCmd("sm_pughelp", Command_PugHelp, "Print pug commands");
	//PAUSE + UNPAUSE VOTE
	RegConsoleCmd("sm_pause", Command_PauseMatch, "Pause the match.");
	RegConsoleCmd("sm_p", Command_PauseMatch, "Pause the match.");
	RegConsoleCmd("sm_unpause", Command_UnPauseMatch, "Unpause the match.");
	RegConsoleCmd("sm_up", Command_UnPauseMatch, "Unpause the match.");
	RegConsoleCmd("sm_voteunpause", Command_UnpauseVote, "Starts a vote to unpause the match.");
	RegConsoleCmd("sm_vup", Command_UnpauseVote, "Starts a vote to unpause the match.");
	//VOTE START
	RegConsoleCmd("sm_votestart", Command_ForceStartVote, "Starts a vote to begin the match with less than 10 players.");
	RegConsoleCmd("sm_vs", Command_ForceStartVote, "Starts a vote to begin the match with less than 10 players.");
	
	
	
	//KNIFEROUND
	RegAdminCmd("sm_kniferound", Command_KnifeRound, ADMFLAG_CONVARS, "Kniferound");
	RegConsoleCmd("sm_stay", Command_VoteStay, "Vote to stay on your side");
	RegConsoleCmd("sm_switch", Command_VoteSwitch, "Vote to switch");
	
	//REGISTER ADMIN COMMANDS
	RegAdminCmd("sm_forcestart", Command_ForceStart, ADMFLAG_CONVARS, "Force match to start without all players.");
	RegAdminCmd("sm_notlive", Command_NotLive, ADMFLAG_CONVARS, "Force warmup.");
	RegAdminCmd("sm_forceunpause", Command_ForceUnpause, ADMFLAG_CONVARS, "Force unpause.");
	RegAdminCmd("sm_forceready", Command_ForceReady, ADMFLAG_CONVARS, "Force all players ready.");
	RegAdminCmd("sm_forceunready", Command_ForceUnReady, ADMFLAG_CONVARS, "Force all players unready.");
	RegAdminCmd("sm_sideswap", Command_ForceSideSwap, ADMFLAG_CONVARS, "Force all players to swap sides.");
	//RegAdminCmd("sm_lockteams", Command_LockTeams, ADMFLAG_CONVARS, "Force all players to remain on the same team.");
	
	//HOOKS
	HookEvent("round_end", Event_RoundEnd, EventHookMode_Post);
	HookEvent("player_spawned", Event_PlayerSpawned, EventHookMode_Post);
	//HookEvent("announce_phase_end", Event_Halftime, EventHookMode_Post);
	
	//CONVARS
	g_KnifeEnabled = CreateConVar("pug_kniferound",	//Cvar
	"1",												// Default
	"Enables or disables kniferound.",					// Description
	_,													// No flags
	true,												// Yes there is a minimum
	0.0,												// Minimum is 0
	true,												// Yes there is a maximum
	1.0);												// Maximum is 1
	g_RequiredReadies = CreateConVar("pug_requiredreadies", "10", "The required amount of ready players to start the match.");
	g_RequiredReadiesForce = CreateConVar("pug_requiredreadiesforce", "8", "The required amount of ready players to vote-start the match.");
	g_ReadyOn = CreateConVar("pug_readysystem",
	"1",
	"Enables/disables the ready system",
	_,													// No flags
	true,												// Yes there is a minimum
	0.0,												// Minimum is 0
	true,												// Yes there is a maximum
	1.0);												// Maximum is 1
	
	g_ReadyOn.AddChangeHook(Event_ReadyCVarChanged); // What to call when someone changes the readyCVar
	g_RequiredReadies.AddChangeHook(Event_RequiredReadiesChanged); // What to call when someone changes the Required Readies cvar
}

public void Event_ReadyCVarChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	if(StringToInt(newValue) == 1)
	{
		forceAllReadyStatus(false);
	} else if(StringToInt(newValue) == 0)
	{
		forceAllReadyStatus(true);
	}
}

public void Event_RequiredReadiesChanged(ConVar convar, char[] oldValue, char[] newValue)
{
	requiredReadies = g_RequiredReadies.IntValue;
	checkForAllReady();
}

public void OnGameFrame()
{	
	if(!live && !knifeRound && GetClientCount(false) >= 1)
	{
		for(int i = 1; i <= GetClientCount(false); i++)
		{
			if(readyStatus[i] && alive[i])
			{
				PrintHintText(i, "\t[PUG]\nYou are READY\n%d/%d ready (%d required)", readyCount, GetClientCount(false), requiredReadies);
			} else if(IsClientInGame(i) && alive[i]) {
				PrintHintText(i, "\t[PUG]\nYou are NOT READY\n%d/%d ready (%d required)", readyCount, GetClientCount(false), requiredReadies);
			}
		}
	}
}

public void handleWarmup()
{
	//FIND CONVARS
	g_RestartGame = FindConVar("mp_restartgame");
	//SET CONVARS
	requiredReadies = g_RequiredReadies.IntValue;
	/*
	for(int i = 1; i <= GetClientCount(); i++)
	{
		globalTeam[i] = 0;
	}
	*/
	
	//START WARMUP
	ServerCommand("mp_warmup_start");
	ServerCommand("mp_warmuptime 3600");
	ServerCommand("bot_kick");
	ServerCommand("sv_alltalk 1");
	ServerCommand("mp_warmup_pausetimer 1");
	live = false;
	//lockTeams = false;
	forceAllReadyStatus(false);
	PrintToChatAll("[PUG] Warmup started.");
}

public void checkForAllReady()
{
	if(readyCount >= requiredReadies)
	{
		PrintToChatAll("[PUG] All players are ready!");
		knifeCVar =  g_KnifeEnabled.IntValue;
		//PrintToChatAll("pug_kniferound: %d", knifeCVar);
		CreateTimer(5.0, Timer_StartMatch, knifeCVar);
	}
}

public int handleReady(bool action) 
{	
	if(live)
	{
		//Match is already live...
		return 0;
	}
	
	//Handle the ready count
	if(action) {
		readyCount++;
	} else if(!action) 
	{
		readyCount--;
	}
	//Print how many players are ready
	PrintToChatAll("[PUG] %d out of %d players ready! (%d required to start)", readyCount, GetClientCount(false), requiredReadies);
	ServerCommand("bot_kick");
	
	checkForAllReady();
	return 0;
}

//Starts the match. Timer is in place to give players 5 seconds after last player readies up.
public Action Timer_StartMatch(Handle timer, int knife)
{
	if(knife == 1)
	{
		startKnifeRound();
		//lockTheTeams();
	} else if(knife == 0)
	{
		startMatch();
		//lockTheTeams();
	} else 
	{
		PrintToChatAll("[PUG] pug_kniferound is not 0 or 1, going back to warmup!");
		handleWarmup();
	}
}
/* Don't need this right now...
void lockTheTeams()
{
	for(int i = 1; i <= GetClientCount(); i++) {
		if(GetClientTeam(i) == CS_TEAM_T)
		{
			globalTeam[i] = TEAM_ONE;
		} else if(GetClientTeam(i) == CS_TEAM_CT)
		{
			globalTeam[i] = TEAM_TWO;
		} else
		{
			globalTeam[i] = SPECTATE;
		}
	}
	iTeamOneSide = CS_TEAM_T;
	iTeamTwoSide = CS_TEAM_CT;
	lockTeams = true;
	PrintToChatAll("[PUG] Teams are locked!");
}
*/

//Start the match my dudes!
public void startMatch()
{
	ServerCommand("exec gamemode_competitive.cfg");
	ServerCommand("bot_kick");
	ServerCommand("mp_give_player_c4 1");
	ServerCommand("mp_round_restart_delay 7");

	//GO LIVE
	PrintToChatAll("[PUG] LIVE ON 3 RESTARTS!!!");
	PrintToChatAll("[PUG] LIVE ON 3 RESTARTS!!!");
	PrintToChatAll("[PUG] LIVE ON 3 RESTARTS!!!");
	
	ServerCommand("mp_warmup_end");
	CreateTimer(3.0, Timer_LiveOn3, _, TIMER_REPEAT);
	
	live = true;
}

//Start the knife round.
public void startKnifeRound()
{
	ServerCommand("mp_freezetime 5");
	ServerCommand("mp_t_default_secondary \"\" ");
	ServerCommand("mp_ct_default_secondary \"\" ");
	ServerCommand("mp_give_player_c4 0");
	ServerCommand("mp_buytime 0");
	ServerCommand("mp_maxmoney 0");
	ServerCommand("mp_round_restart_delay 0");
	ServerCommand("sv_alltalk 0");
	ServerCommand("mp_warmup_end");
	knifeRound = true;
	
	PrintToChatAll("[PUG] Knife for sides started!");
}

public Action Command_ForceReady(int client,  int args)
{
	forceAllReadyStatus(true);
}

public Action Command_ForceUnReady(int client,  int args)
{
	forceAllReadyStatus(false);
}

public Action Command_ForceSideSwap(int client,  int args)
{
	performSideSwap();
}

/*
public Action Command_LockTeams(int client,  int args)
{
	lockTheTeams();
}
*/

//Force-kniferound command, ignores pug_kniferound
public Action Command_KnifeRound(int client, int args)
{
	startKnifeRound();
	//lockTheTeams();
}

//Post-kniferound vote. Only works if executed during voting period and the client that called it is on the winning side.
public Action Command_VoteStay(int client, int args)
{
	if(knifeVote && !clientVoteStatus[client])
	{
		int team = GetClientTeam(client);
		if (team == knifeWinner) {
			clientVoteStatus[client] = true;
			knifeVoteStay++;
			PrintToChat(client, "[PUG] You have voted to stay.");
		} else {
			PrintToChat(client, "[PUG] You did not win the kniferound.");
		}
	}
}

//Post-kniferound vote. Only works if executed during voting period and the client that called it is on the winning side.
public Action Command_VoteSwitch(int client, int args)
{
	if(knifeVote && !clientVoteStatus[client])
	{
		int team = GetClientTeam(client);
		if (team == knifeWinner) {
			clientVoteStatus[client] = true;
			knifeVoteSwitch++;
			PrintToChat(client, "[PUG] You have voted to switch.");
		} else {
			PrintToChat(client, "[PUG] You did not win the kniferound.");
		}
	}
}

public Action Command_ClientCount(int client, int args)
{
	PrintToChatAll("[MATCH] There are %d clients in the server.", GetClientCount(false));
	return Plugin_Handled;
}

//Set the client's ready status to true, meaning they are ready to begin the match.
public Action Command_Ready(int client, int args)
{
	readyCVar = g_ReadyOn.IntValue;
	if(live)
	{
		//Match is already live...
		PrintToChat(client, "[PUG] The match is already live.");
		return Plugin_Handled;
	} else if(readyCVar == 0)
	{
		PrintToChat(client, "[PUG] The ready system is disabled. You are automatically ready.");
		return Plugin_Handled;
	}
	
	if(!readyStatus[client])
	{
		//They are not ready, so make them ready
		readyStatus[client] = true;
		handleReady(true);
		PrintToChat(client, "[PUG] You are now ready!");
		CS_SetClientClanTag(client, "[READY]"); 
	} else if(readyStatus[client])
	{
		//They are already ready, so tell them that they are already ready and set readyStatus to True just to be safe
		readyStatus[client] = true;
		PrintToChat(client, "[PUG] You are already ready!");
		CS_SetClientClanTag(client, "[READY]"); 
	} else
	{
		//In case there is some glitch in the system, they must have done !ready so just make them ready anyways
		readyStatus[client] = true;
		PrintToChat(client, "[PUG] You are now ready!");
		CS_SetClientClanTag(client, "[READY]"); 
	}
	//updateHud(client);
	//Commented to try to reduce the chat spam upon commands.
	//playerInfo(client);
	
	return Plugin_Handled;
}


//Set the client's ready status to false, meaning they are not ready to begin the match.
public Action Command_NotReady(int client, int args)
{
	readyCVar = g_ReadyOn.IntValue;
	if(live)
	{
		//Match is already live...
		PrintToChat(client, "[PUG] The match is already live.");
		return Plugin_Handled;
	} else if(readyCVar == 0)
	{
		PrintToChat(client, "[PUG] The ready system is disabled. You are automatically ready.");
		return Plugin_Handled;
	}
	
	if(readyStatus[client])
	{
		//They are ready, so make them unready
		readyStatus[client] = false;
		handleReady(false);
		PrintToChat(client, "[PUG] You are no longer ready!");
		CS_SetClientClanTag(client, "[NOT READY]");
	} else if(!readyStatus[client])
	{
		//They are already unready. Tell them this
		readyStatus[client] = false;
		PrintToChat(client, "[PUG] You are already not ready!");
		CS_SetClientClanTag(client, "[NOT READY]"); 
	} else
	{
		//Catch any errors by making sure that they are set to unready.
		readyStatus[client] = false;
		PrintToChat(client, "[PUG] You are not ready!");
		CS_SetClientClanTag(client, "[NOT READY]"); 
	}
	//Commented to try to reduce the chat spam upon commands.
	//playerInfo(client);
	//updateHud(client);
	
	return Plugin_Handled;
}

//PRINT  ClientID and ReadyStatus
public void playerInfo(int client)
{
	if(readyStatus[client])
	{
		PrintToChat(client, "[PUG] Client id: %d, Ready Status: ready.", client);
	} else {
		PrintToChat(client, "[PUG] Client id: %d, Ready Status: not ready.", client);
	}
}


//FORCESTART
public Action Command_ForceStart(int client, int args)
{
	if(live)
	{
		//Match is already live...
		PrintToChat(client, "[PUG] The match is already live.");
		return Plugin_Handled;
		
	}
	
	knifeCVar =  g_KnifeEnabled.IntValue;
	PrintToChatAll("pug_kniferound: %d", knifeCVar);
	if(knifeCVar == 1)
	{
		startKnifeRound();
	} else if(knifeCVar == 0)
	{
		startMatch();
	}
	
	//lockTheTeams();
	
	return Plugin_Handled;
}

//FORCE WARMUP
public Action Command_NotLive(int client, int args)
{
	handleWarmup();
}

public Action Command_ReadyCount(int client, int args)
{
	if(live)
	{
		//Match is already live...
		PrintToChat(client, "[PUG] The match is already live.");
		return Plugin_Handled;
		
	}
	requiredReadies = g_RequiredReadies.IntValue;
	PrintToChatAll("[PUG] There are %d out of %d players ready! (%d required)", readyCount, GetClientCount(false), requiredReadies);
	
	return Plugin_Handled;
}

public Action Command_MyStatus(int client, int args)
{
	if(live)
	{
		//Match is already live...
		PrintToChat(client, "[PUG] The match is already live.");
		return Plugin_Handled;
		
	}
	
	if(readyStatus[client])
	{
		PrintToChat(client, "[PUG] Your ready status is: ready.");
	} else
	{
		PrintToChat(client, "[PUG] Your ready status is: not ready.");
	}
	
	//PrintToChat(client, "[PUG] Global Team: %d; Current Team: %d", globalTeam[client], GetClientTeam(client));
	return Plugin_Handled;
}

public Action Command_PugHelp(int client, int args)
{
	if(GetUserAdmin(client) != INVALID_ADMIN_ID)
	{
		PrintToChat(client, "[PUG] Admin commands are: !forcestart, !notlive, !forceunpause");
	}
	PrintToChatAll("[PUG] Available admin commands are: !ready, !unready, !readycount, !mystatus, !pause, !unpause (if you paused the match), !voteunpause");
	
	return Plugin_Handled;
}


public Action Command_PauseMatch(int client, int args)
{
	if(!live)
	{
		//Match is not live
		PrintToChat(client, "[PUG] You cannot do that right now.");
		return Plugin_Handled;
		
	}
	clientThatPaused = client;
	ServerCommand("mp_pause_match");
	PrintToChatAll("[PUG] Match has been set to pause during freezetime. Match can only be unpaused by the player that paused the match, an admin can force-unpause, or players can vote to unpause the match.");
	
	return Plugin_Handled;
}

public Action Command_UnPauseMatch(int client, int args)
{
	//TODO: Implement unpause
	if(!live)
	{
		//Match is not live...
		PrintToChat(client, "[PUG] You cannot do that right now.");
		return Plugin_Handled;
		
	}
	
	if(client == clientThatPaused)
	{
		ServerCommand("mp_unpause_match");
		PrintToChatAll("[PUG] Match has been unpaused!");
		clientThatPaused = 0;
	} else
	{
		PrintToChat(client, "[PUG] You did not pause this match. If the player that paused it refuses to unpause it, then please notify an admin or type !voteunpause");
	}
	
	return Plugin_Handled;
}

public Action Command_ForceUnpause(int client, int args)
{
	//TODO: Implement force unpause
	ServerCommand("mp_unpause_match");
	PrintToChatAll("[PUG] Admin has force-unpaused the match!");
}

//UNPAUSE VOTE
public int Handle_UnpauseVoteMenu(Menu menu, MenuAction action, int param1,int param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		delete menu;
	} else if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			ServerCommand("mp_unpause_match");
			PrintToChatAll("[PUG] Players have voted to unpause the match!");
		} else
		{
			PrintToChatAll("[PUG] Players have voted to remain paused!");
		}
	}
}

public Action Command_UnpauseVote(int client, int args)
{
	if(!live)
	{
		//Match is already live...
		PrintToChat(client, "[PUG] The match is not live.");
		return Plugin_Handled;
		
	}
	
	if (IsVoteInProgress())
	{
		return Plugin_Handled;
	}

	Menu menu = new Menu(Handle_UnpauseVoteMenu);
	menu.SetTitle("Unpause match?");
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
	
	return Plugin_Handled;
}


//FORCE START VOTE
public int Handle_ForceStartVoteMenu(Menu menu, MenuAction action, int param1,int param2)
{
	if (action == MenuAction_End)
	{
		/* This is called after VoteEnd */
		delete menu;
	} else if (action == MenuAction_VoteEnd) {
		/* 0=yes, 1=no */
		if (param1 == 0)
		{
			knifeCVar = g_KnifeEnabled.IntValue;
			PrintToChatAll("pug_kniferound: %d", knifeCVar);
			if(knifeCVar == 1)
			{
				startKnifeRound();
			} else if(knifeCVar == 0)
			{
				startMatch();
			}
			PrintToChatAll("[PUG] Players have voted to start the match with less than 10 players!");
			//lockTheTeams();
		} else
		{
			requiredReadies = g_RequiredReadies.IntValue;
			PrintToChatAll("[PUG] Players have voted to wait until there are %d players!", requiredReadies);
		}
	}
}

public Action Command_ForceStartVote(int client, int args)
{
	requiredReadiesForceStart = g_RequiredReadiesForce.IntValue;
	if(live)
	{
		//Match is already live...
		PrintToChat(client, "[PUG] The match is already live.");
		return Plugin_Handled;
		
	} else if(GetClientCount(false) < requiredReadiesForceStart)
	{
		PrintToChat(client, "[PUG] There are not enough players to force-start the match!");
		return Plugin_Handled;
	}
	
	if (IsVoteInProgress())
	{
		return Plugin_Handled;
	}

	Menu menu = new Menu(Handle_ForceStartVoteMenu);
	menu.SetTitle("Start the match without full teams?");
	menu.AddItem("yes", "Yes");
	menu.AddItem("no", "No");
	menu.ExitButton = false;
	menu.DisplayVoteToAll(20);
	
	return Plugin_Handled;
}

public void OnClientDisconnect(int client)
{
	readyStatus[client] = false;
	PrintToChatAll("There are %d clients in the server.", GetClientCount(false));
}

public void OnClientConnected(int client)
{
	if(GetClientCount(false) == 0)
	{
		handleWarmup();
	}
	
	CreateTimer(10.0, Timer_PlayerJoined, client);
}

public Action Timer_LiveOn3(Handle timer)
{
	// Create a global variable visible only in the local scope (this function).
	static int numRestarted = 1;

	if (numRestarted > 3) 
	{
		numRestarted = 0;
		PrintToChatAll("[PUG] LIVE!!!");
		PrintToChatAll("[PUG] LIVE!!!");
		PrintToChatAll("[PUG] LIVE!!!");
		return Plugin_Stop;
	}
	PrintToChatAll("[PUG] Restarting in 1 second. (%d/3)", numRestarted);
	//g_RestartGame.SetConVarInt(1);
	SetConVarInt(g_RestartGame, 1);
	numRestarted++;

	return Plugin_Continue;
}

/* Don't need this right now.
public Action Event_Halftime(Event event, const char[] name, bool dontBroadcast)
{
	iTeamOneSide = CS_TEAM_CT;
	iTeamTwoSide = CS_TEAM_T;
}
*/

//EVENT_ROUND_END
public Action Event_RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
	int winner = event.GetInt("winner");
	//PrintToChatAll("%d", winner);
	
	if(knifeRound)
	{
		knifeVote = true;
		if(winner == CS_TEAM_T)
		{
			//T Side won the kniferound
			knifeWinner = CS_TEAM_T;
		} else if(winner == CS_TEAM_CT)
		{
			//CT won the kniferound
			knifeWinner = CS_TEAM_CT;
		}  else
		{
			PrintToChatAll("Could not get kniferound winner, going back to warmup.");
			handleWarmup();
		}
		knifeRound = false;
		
		for (int i = 1; i <= GetClientCount(false); i++) {
			int team = GetClientTeam(i);
			if (team == winner) {
				PrintToChat(i, "[PUG] Your team won the knife round. You have 15 seconds to vote. Type !stay or !switch to cast your vote.");
			} else {
				PrintToChat(i, "[PUG] Your team lost the knife round. The other team has 15 seconds to vote.");
			}
		}
		ServerCommand("mp_restartgame 15");
		CreateTimer(15.0, Timer_KnifeVote);
	}
	/*
	if(lockTeams)
	{
		for(int i = 1; i <= GetClientCount(false); i++)
		{
			int team = globalTeam[i];
			int correctTeam;
			if(team == TEAM_ONE) {
				correctTeam = iTeamOneSide;
			} else if(team == TEAM_TWO) {
				correctTeam = iTeamTwoSide;
			}
			
			int currentTeam = GetClientTeam(i);
			if(currentTeam != correctTeam)
			{
				ChangeClientTeam(i, correctTeam);
			}
		}
	}
	*/
}

public Action Event_PlayerSpawned(Event event, const char[] name, bool dontBroadcast)
{
	ServerCommand("bot_kick");
	int clnt = GetClientOfUserId(event.GetInt("userid"));
	
	if(!readyStatus[clnt])
	{
		CreateTimer(0.1, Timer_InitClanTagFalse, clnt);
	} else if(readyStatus[clnt])
	{
		CreateTimer(0.1, Timer_InitClanTagTrue, clnt);
	}
	
	alive[clnt] = true;
}

public void performSideSwap()
{
	for (int i = 1; i <= GetClientCount(false); i++)
	{
		int team = GetClientTeam(i);
		
		if (team == CS_TEAM_T)
		{
			ChangeClientTeam(i, CS_TEAM_CT);
		} else if (team == CS_TEAM_CT)
		{
			ChangeClientTeam(i, CS_TEAM_T);
		}
	}
	
	ServerCommand("bot_kick");
}

public Action Timer_KnifeVote(Handle timer)
{
	knifeVote = false;
	knifeRound = false;
	if(knifeVoteStay < knifeVoteSwitch)
	{
		performSideSwap();
		//iTeamOneSide = CS_TEAM_CT;
		//iTeamTwoSide = CS_TEAM_T;
	}
	
	knifeVoteStay = 0;
	knifeVoteSwitch = 0;
	
	for(int i = 1; i <= GetClientCount(false);  i++)
	{
		clientVoteStatus[i] = false;
		CS_SetClientClanTag(i, "");
	}
	
	startMatch();
	
	return Plugin_Continue;
}

public Action Timer_InitClanTagFalse(Handle timer, int client)
{
	if(alive[client])
	{
		CS_SetClientClanTag(client, "[NOT READY]");
	}
}

public Action Timer_InitClanTagTrue(Handle timer, int client)
{
	if(alive[client])
	{
		CS_SetClientClanTag(client, "[READY]");
	}
}

public Action Timer_PlayerJoined(Handle timer, int client)
{
	
	PrintToChatAll("[PUG] There are %d clients in the server.", GetClientCount(false));
	readyCVar = g_ReadyOn.IntValue;
	
	if(readyCVar == 0)
	{
		PrintToChat(client, "[PUG] The ready system is disabled. You are automatically ready.");
		handleReady(true);
		readyStatus[client] = true;
	} else if(readyCVar == 1)
	{
		readyStatus[client] = false;
		//updateHud(client);
	}
}

void forceAllReadyStatus(bool arg)
{
	if(arg)
	{
		for(int i = 1; i <= GetClientCount(false);  i++)
		{
			if(!readyStatus[i])
			{
				readyStatus[i] = true;
				CS_SetClientClanTag(i, "[READY]");
				handleReady(true);
			}
		}
	} else if(!arg)
	{
		for(int i = 1; i <= GetClientCount(false);  i++)
		{
			if(readyStatus[i])
			{
				readyStatus[i] = false;
				CS_SetClientClanTag(i, "[NOT READY]");
				handleReady(false);
			}
		}
	}
}