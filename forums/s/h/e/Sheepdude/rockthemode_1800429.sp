/**
 * ==========================================================================
 * SourceMod RockTheMode CS:GO
 *
 * by Sheepdude
 *
 * SourceMod Forums Plugin Thread URL:
 * https://forums.alliedmods.net/showthread.php?t=196148
 *
 */

#include <sourcemod>
#pragma semicolon 1

#define PLUGIN_VERSION "1.1.4"

// Convar handles
new Handle:h_cvarVersion;
new Handle:h_cvarEnable;
new Handle:h_cvarNeeded;
new Handle:h_cvarMinPlayers;
new Handle:h_cvarInitDelay;
new Handle:h_cvarInitWindow;
new Handle:h_cvarInterval;
new Handle:h_cvarAllow[5];
new Handle:h_cvarGameType;
new Handle:h_cvarGameMode;
new Handle:h_cvarNMMEnable;		// Used for compatibility with NextMapMode plugin.

// Convar variables
new g_cvarEnable;				// Enables and disables the plugin.
new Float:g_cvarNeeded;			// Necessary votes before mode vote begins. (voters * percent_needed)
new g_cvarMinPlayers;			// Minimum number of players required to successfully rock the mode.
new Float:g_cvarInitDelay;		// Delay after map start during which rock the mode is disabled.
new Float:g_cvarInitWindow;		// Delay after map start during which rock the mode is enabled.
new Float:g_cvarInterval;		// Delay after a failed rock the mode vote before another vote can be called.
new bool:g_cvarAllow[5];		// Determines which modes are allowed to appear on the vote.

// Plugin variables
new String:g_NextMode[32];		// Name of the next mode.
new bool:g_CanRTM = false;		// True if RTM loaded map and is active.
new bool:g_WindowPassed;		// True if RTM voting window has passed. Used to disable RTM.
new g_SwitchedNMM;				// If RTM vote succeeded last map and NMM needs to be reenabled.
new g_Voters;					// Total voters connected. Doesn't include fake clients.
new g_Votes;					// Total number of "say rtm" votes
new g_VotesNeeded;				// Number of votes required to start a vote.
new bool:g_Voted[MAXPLAYERS+1];	// True if a player has voted.
new bool:g_InChange;			// True if the map is changing.
new g_GameType;					// 0 - Classic, 1 - Arsenal
new g_GameMode;					// 0 - Casual/Arms Race, 1 - Competitive/Demolition, 2 - Deathmatch

public Plugin:myinfo =
{
	name = "Rock The Mode",
	author = "Sheepdude",
	description = "Rock The Mode by popular vote for CS:GO",
	version = PLUGIN_VERSION,
	url = "http://www.clan-psycho.com"
};

/******
 *Load*
*******/

public OnPluginStart()
{
	// Translations
	LoadTranslations("rockthemode.phrases");
	LoadTranslations("basevotes.phrases");
	LoadTranslations("core.phrases");

	// Create convars
	h_cvarVersion = CreateConVar("sm_rtm_version", PLUGIN_VERSION, "Provides RTM Game Mode Voting for CS:GO", FCVAR_DONTRECORD|FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	h_cvarEnable = CreateConVar("sm_rtm_enable", "1", "Enable or disable plugin (1-enable, 0-disable)", FCVAR_NOTIFY, true, 0.0, true, 1.0);
	h_cvarNeeded = CreateConVar("sm_rtm_needed", "0.60", "Ratio of players needed to RockTheMode (Def. 60%)", 0, true, 0.05, true, 1.0);
	h_cvarMinPlayers = CreateConVar("sm_rtm_minplayers", "0", "Number of players required before RTM will be enabled", 0, true, 0.0);
	h_cvarInitDelay = CreateConVar("sm_rtm_initialdelay", "20.0", "Time (in seconds) before first RTM can be held", 0, true, 0.0);
	h_cvarInitWindow = CreateConVar("sm_rtm_initialwindow", "240.0", "Time (in seconds) after map start to disable RTM vote", 0, true, 0.00);
	h_cvarInterval = CreateConVar("sm_rtm_interval", "240.0", "Time (in seconds) after a failed RTM before another can be held", 0, true, 0.00);
	h_cvarAllow[0] = CreateConVar("sm_rtm_allow_casual", "1", "Does Casual appear in the vote (0-no, 1-yes)", 0, true, 0.0, true, 1.0);
	h_cvarAllow[1] = CreateConVar("sm_rtm_allow_competitive", "1", "Does Competitive appear in the vote (0-no, 1-yes)", 0, true, 0.0, true, 1.0);
	h_cvarAllow[2] = CreateConVar("sm_rtm_allow_armsrace", "1", "Does Arms Race appear in the vote (0-no, 1-yes)", 0, true, 0.0, true, 1.0);
	h_cvarAllow[3] = CreateConVar("sm_rtm_allow_demolition", "1", "Does Demolition appear in the vote (0-no, 1-yes)", 0, true, 0.0, true, 1.0);
	h_cvarAllow[4] = CreateConVar("sm_rtm_allow_deathmatch", "1", "Does DeathMatch appear on the vote (0-no, 1-yes)", 0, true, 0.0, true, 1.0);

	// Find convars
	h_cvarGameType = FindConVar("game_type");
	h_cvarGameMode = FindConVar("game_mode");
	
	// Convar hooks
	HookConVarChange(h_cvarVersion, OnConvarChanged);
	HookConVarChange(h_cvarEnable, OnConvarChanged);
	HookConVarChange(h_cvarNeeded, OnConvarChanged);
	HookConVarChange(h_cvarMinPlayers, OnConvarChanged);
	HookConVarChange(h_cvarInitDelay, OnConvarChanged);
	HookConVarChange(h_cvarInitWindow, OnConvarChanged);
	HookConVarChange(h_cvarInterval, OnConvarChanged);
	for(new i = 0; i <= 4; i++)
		HookConVarChange(h_cvarAllow[i], OnConvarChanged);

	// Console commands
	RegConsoleCmd("say", SayCmd);
	RegConsoleCmd("say_team", SayCmd);
	RegConsoleCmd("sm_rtm", RTMCmd);

	// Admin commands
	RegAdminCmd("sm_rtm_mode", ChangeModeCmd, ADMFLAG_CHANGEMAP, "Immediately changes the current game mode.");
	RegAdminCmd("sm_rtm_forcevote", ForceVoteCmd, ADMFLAG_CHANGEMAP, "Forces a Rockthemode vote.");

	// Execute configuration file
	AutoExecConfig(true, "rtm");
	UpdateAllConvars();
}

public OnAllPluginsLoaded()
{
	h_cvarNMMEnable = FindConVar("sm_nmm_enable");
}

/*********
 *Globals*
**********/

public OnMapStart()
{
	// If initial window is set, start a timer that disables rtm after the window has expired
	if(g_cvarInitWindow != 0)
		CreateTimer(g_cvarInitWindow, WindowTimer, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// Instantiate voter information
	g_Voters = 0;
	g_Votes = 0;
	g_VotesNeeded = 0;
	g_InChange = false;
	
	// For compatibility with NextMapMode plugin - reenables NMM if it was disabled by RTM last map
	if(h_cvarNMMEnable != INVALID_HANDLE && g_SwitchedNMM)
		SetConVarInt(h_cvarNMMEnable, 1);

	// Handle late load
	for(new i = 1; i <= MaxClients; i++)
		if(IsClientConnected(i))
			OnClientConnected(i);	
}

public OnMapEnd()
{
	// Reset data when the map ends
	g_CanRTM = false;
	g_WindowPassed = false;
	g_WindowPassed = false;
}

public OnConfigsExecuted()
{
	// Create a delay after which RTM will be enabled
	UpdateAllConvars();
	CreateTimer(g_cvarInitDelay, DelayTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

// When client connects, increase max voters and votes needed
public OnClientConnected(client)
{
	if(IsFakeClient(client))
		return;
	
	g_Voted[client] = false;
	g_Voters++;
	g_VotesNeeded = RoundToFloor(g_Voters * g_cvarNeeded);
}

// When client disconnects, decrease max voters and votes needed
public OnClientDisconnect(client)
{
	if(IsFakeClient(client))
		return;
	
	if(g_Voted[client])
		g_Votes--;
	g_Voters--;
	g_VotesNeeded = RoundToFloor(g_Voters * g_cvarNeeded);
	
	// Starts vote if a client disconnect cause vote count to exceed the needed ratio
	if( g_cvarEnable &&
		g_CanRTM &&
		g_Votes && 
		g_Voters && 
		g_Votes >= g_VotesNeeded ) 
		StartRTM();
}

/**********
 *Commands*
***********/

// Handler for "sm_rtm" console command
public Action:RTMCmd(client, args)
{
	if(!IsValidClient(client))	
		return Plugin_Handled;
	if(!g_CanRTM)
	{
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 %t", "RTM Not Allowed");
		return Plugin_Handled;
	}
	AttemptRTM(client);
	return Plugin_Handled;
}

// Handler for "say" command - checks for "rtm" or "rockthemode" in chat string
public Action:SayCmd(client, args)
{
	if(!IsValidClient(client))
		return Plugin_Continue;
	if(!g_CanRTM)
	{
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 %t", "RTM Not Allowed");
		return Plugin_Continue;
	}
	
	decl String:text[192];
	if(!GetCmdArgString(text, sizeof(text)))
		return Plugin_Continue;
	
	new startidx = 0;
	if(text[strlen(text)-1] == '"')
	{
		text[strlen(text)-1] = '\0';
		startidx = 1;
	}
	new ReplySource:old = SetCmdReplySource(SM_REPLY_TO_CHAT);
	
	// If client chat string matches "rtm" or "rockthemode", try to register their vote
	if(strcmp(text[startidx], "rtm", false) == 0 || strcmp(text[startidx], "rockthemode", false) == 0)
		AttemptRTM(client);
	
	SetCmdReplySource(old);
	return Plugin_Continue;	
}

// Handler for "sm_rtm_mode" admin command
public Action:ChangeModeCmd(client, args)
{
	if(args < 1)
	{
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 Usage: sm_rtm_mode <mode>");
		return Plugin_Handled;
	}
	
	if(IsVoteInProgress())
		return Plugin_Handled;
		
	if(!CheckCommandAccess(client, "sm_rtm", ADMFLAG_CHANGEMAP))
	{
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 %t", "No Access");
		return Plugin_Handled;
	}
	
	new String:argstring[256];
	GetCmdArgString(argstring, sizeof(argstring));
	SetMode(argstring);
	if(!StrEqual(g_NextMode, ""))
		RestartMap();
	return Plugin_Handled;
}

// Handler for "sm_rtm_forcevote" admin command
public Action:ForceVoteCmd(client, args)
{
	if(!CheckCommandAccess(client, "sm_rtm", ADMFLAG_CHANGEMAP))
	{
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 %t", "No Access");
		return Plugin_Handled;
	}
	StartRTM();
	return Plugin_Handled;
}

/***************
 *Rock the Mode*
****************/

// Attempt to register client vote
AttemptRTM(client)
{
	if(!g_cvarEnable)
	{
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 %t", "RTM Not Allowed");
		return;
	}	
	if(GetClientCount(true) < g_cvarMinPlayers)
	{
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 %t", "Minimal Players Not Met");
		return;			
	}
	if(g_Voted[client])
	{
		ReplyToCommand(client, "\x01\x0B\x04[SM]\x01 %t", "Already Voted", g_Votes, g_VotesNeeded);
		return;
	}	
	new String:name[64];
	GetClientName(client, name, sizeof(name));
	g_Votes++;
	g_Voted[client] = true;
	PrintToChatAll("\x01\x0B\x04[SM]\x01 %t", "RTM Requested", name, g_Votes, g_VotesNeeded);
	
	// Start rockthemode vote if registering the client vote caused the total votes to exceed the needed ratio
	if(g_Votes >= g_VotesNeeded)
		StartRTM();
}

// Starts the mode voting once enough client votes have been received
StartRTM()
{
	// Do not start vote if plugin is already changing map or if another sm vote is in progress
	if(g_InChange || IsVoteInProgress())
		return;
	
	// Create and display rockthemode vote menu
	DoVoteMenu();
	
	// Reset player votes and disallow voting for rockthemode until the delay interval has passed
	g_CanRTM = false;
	ResetRTM();
	CreateTimer(g_cvarInterval, DelayTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}
 
// Create the mode voting menu
DoVoteMenu()
{
	new Handle:menu = CreateMenu(VoteMenuHandler);
	SetMenuTitle(menu, "Choose a game mode:");
	if(g_cvarAllow[0])
		AddMenuItem(menu, "Casual", "Casual");
	if(g_cvarAllow[1])
		AddMenuItem(menu, "Competitive", "Competitive");
	if(g_cvarAllow[2])
		AddMenuItem(menu, "Arms Race", "Arms Race");
	if(g_cvarAllow[3])
		AddMenuItem(menu, "Demolition", "Demolition");
	if(g_cvarAllow[4])
		AddMenuItem(menu, "DeathMatch", "DeathMatch");
	
	// Do not vote if vote menu is empty
	if(!GetMenuItemCount(menu))
	{
		CloseHandle(menu);
		ResetRTM();
		return;
	}
	SetMenuExitButton(menu, false);
	VoteMenuToAll(menu, 20);
}

//Handler for the rockthemode vote menu
public VoteMenuHandler(Handle:menu, MenuAction:action, param1, param2) 
{
	// Close vote menu handle after the vote has stopped
	if(action == MenuAction_End) 
		CloseHandle(menu);
	
	// Handle the results of the vote
	else if(action == MenuAction_VoteEnd)
	{
		// Get vote winner and set the next map mode accordingly
		decl String:nextMode[16];
		GetMenuItem(menu, param1, nextMode, sizeof(nextMode));
		SetMode(nextMode);
		new votes;
		new totalVotes;
		GetMenuVoteInfo(param2, votes, totalVotes);
		new Float:percent = FloatDiv(float(votes), float(totalVotes));
		PrintToChatAll("\x01\x0B\x04[SM]\x01 %t", "Vote Successful", RoundToNearest(100.0 * percent), totalVotes);
		RestartMap();
	}
}

public RestartMap()
{
		// If current game mode won, don't change map and delay rockthemode vote
		if(GetConVarInt(h_cvarGameType) == g_GameType && GetConVarInt(h_cvarGameMode) == g_GameMode)
		{
			PrintToChatAll("\x01\x0B\x04[SM]\x01 No action required. Game mode is already %s.", g_NextMode);
			CreateTimer(GetConVarFloat(h_cvarInterval), DelayTimer, _, TIMER_FLAG_NO_MAPCHANGE);
			ResetRTM();
			return;
		}
		
		// For compability with NextMapMode plugin. If NMM is enabled, disable it.
		if(h_cvarNMMEnable != INVALID_HANDLE)
		{
			g_SwitchedNMM = GetConVarInt(h_cvarNMMEnable);
			SetConVarInt(h_cvarNMMEnable, 0);
		}
		
		// Change game mode and game type, then restart the map
		SetConVarInt(h_cvarGameType, g_GameType);
		SetConVarInt(h_cvarGameMode, g_GameMode);
		PrintToChatAll("\x01\x0B\x04[SM]\x01 %t", "Changing Modes", g_NextMode);
		CreateTimer(5.0, ChangeMapTimer, _, TIMER_FLAG_NO_MAPCHANGE);
}

// Resets client vote status once a rockthemode vote has been initiated
ResetRTM()
{
	g_Votes = 0;
	for (new i = 1; i <= MAXPLAYERS; i++)
		g_Voted[i] = false;
}

/*********
 *Helpers*
**********/

// Sets variables for the next mode based on either the vote winner or the admin argstring for sm_rtm_mode
SetMode(const String:nextMode[])
{
	g_GameType = 0;
	g_GameMode = 0;
	
	if(StrEqual(nextMode, "Casual", false))	
		g_NextMode = "Casual";
	else if(StrEqual(nextMode, "Competitive", false))
	{
		g_GameMode = 1;
		g_NextMode = "Competitive";
	}
	else if(StrEqual(nextMode, "Armsrace", false) || StrEqual(nextMode, "arms_race", false) || StrEqual(nextMode, "Arms Race", false))
	{
		g_GameType = 1;
		g_NextMode = "Arms Race";
	}
	else if(StrEqual(nextMode, "Demolition", false))
	{
		g_GameType = 1;
		g_GameMode = 1;
		g_NextMode = "Demolition";
	}
	else if(StrEqual(nextMode, "DeathMatch", false) || StrEqual(nextMode, "death_match", false) || StrEqual(nextMode, "Death Match", false))
	{
		g_GameType = 1;
		g_GameMode = 2;
		g_NextMode = "DeathMatch";
	}
	else
		g_NextMode = "";
}

/********
 *Timers*
*********/

// Disables rockthemode after the window time has passed
public Action:WindowTimer(Handle:timer)
{
	g_WindowPassed = true;
	g_CanRTM = false;
	return Plugin_Handled;
}

// Enables rockthemode after the initial delay has passed
public Action:DelayTimer(Handle:timer)
{
	if(!g_WindowPassed)
		g_CanRTM = true;
	return Plugin_Handled;
}

// Restarts the map
public Action:ChangeMapTimer(Handle:timer)
{
	g_InChange = true;
	new String:currentMap[32];
	if(GetCurrentMap(currentMap, sizeof(currentMap)))
		ForceChangeLevel(currentMap, "RTM changing mode manually");
	return Plugin_Handled;
}

/*********
 *Convars*
**********/

UpdateAllConvars()
{
	ResetConVar(h_cvarVersion);
	g_cvarEnable = GetConVarBool(h_cvarEnable);
	g_cvarNeeded = GetConVarFloat(h_cvarNeeded);
	g_cvarMinPlayers = GetConVarInt(h_cvarMinPlayers);
	g_cvarInitDelay = GetConVarFloat(h_cvarInitDelay);
	g_cvarInitWindow = GetConVarFloat(h_cvarInitWindow);
	g_cvarInterval = GetConVarFloat(h_cvarInterval);
	for(new i = 0; i <= 4; i++)
		g_cvarAllow[i] = GetConVarBool(h_cvarAllow[i]);
}

public OnConvarChanged(Handle:cvar, const String:oldVal[], const String:newVal[])
{
	UpdateAllConvars();
}

/********
 *Stocks*
*********/

stock IsValidClient(client)
{
	if(client > 0 && client <= MaxClients && IsClientConnected(client))
		return true;
	return false;
}