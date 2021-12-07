/*
===============================================================================================================
MatchMod for Team Fortress 2

NAME		: MatchMod.sp        
VERSION		: 0.9.5
AUTHOR		: Charles 'Hawkeye' Mabbott
DESCRIPTION	: Faciliate the running of a league match
REQUIREMENTS	: Sourcemod 1.2+

VERSION HISTORY	: 
	0.9	- First Public release
	0.9.2	- Modified commands to use chat text hooks
		- Added ability to return to a idle configuration
		- Added commands to modify configs from client
		- Added PUG support in the example configs
	0.9.5	- Added CTF scoring
		- Added commands to change team names
===============================================================================================================

TODO:
 - Ready-up code as opposed to default F4 by anyone

 - Testing the bloody thing

*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks >


#define RED 0
#define BLU 1
#define TEAM_OFFSET 2
#define PLUGIN_VERSION "0.9.5"


#define MAX_PLAYER_ALLOWED 12
#define READY_LIST_PANEL_LIFETIME 10


public Plugin:myinfo =
{
	name = "MatchMod",
	author = "Hawkeye",
	description = "Facilitates competitive play for league formatted matches",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?t=102299"
};


//----------------------------------------------------------------------------
//| Variables
//----------------------------------------------------------------------------

//***********************************************
new bool:readyMode;
new readyStatus[MAXPLAYERS + 1];
new Handle:cvarReadyMinimum = INVALID_HANDLE;
new Handle:liveTimer;
new Handle:infoBegin;
//***********************************************



new bool:recording = false;
new bool:adscoring = false;
new bool:ctfscoring = false;
new Handle:g_cvar_adscoring = INVALID_HANDLE;
new Handle:g_cvar_ctfscoring = INVALID_HANDLE;
new Handle:g_cvar_alltalk = INVALID_HANDLE;
new Handle:g_cvar_maxpoints = INVALID_HANDLE;
new Handle:g_cvar_allowovertime = INVALID_HANDLE;
new Handle:g_cvar_allowhalf = INVALID_HANDLE;
new Handle:g_cvar_bluteamname = INVALID_HANDLE;
new Handle:g_cvar_redteamname = INVALID_HANDLE;
new Handle:g_cvar_hostnamepfx = INVALID_HANDLE;
new Handle:g_cvar_hostnamesfx = INVALID_HANDLE;
new Handle:g_cvar_servercfg = INVALID_HANDLE;
new Handle:g_cvar_servercfgot = INVALID_HANDLE;
new Handle:g_cvar_tvenable = INVALID_HANDLE;
new Handle:g_cvar_servercfgidle = INVALID_HANDLE;
new String:mm_tmaname[16];
new String:mm_tmbname[16];
new String:mm_tmpname[16];
new String:mm_hnpfx[16];
new String:mm_hnsfx[48];
new String:mm_svrcfg[64];
new String:mm_svrcfgot[64];
new String:mm_svrcfgidle[64];
new mm_tmascore = 0;
new mm_tmbscore = 0;
new mm_tmpscore = 0;
new mm_topscore = 0;
new mm_roundcount = 0;
new mm_allowhalf = 1;
new mm_allowovertime = 1;
new mm_state = 0;
new mm_recording = 0;

//----------------------------------------------------------------------------
//| Plugin start up
//----------------------------------------------------------------------------

public OnPluginStart()
{
	SetConVarString(CreateConVar("tf2_readyup_version", PLUGIN_VERSION, "version of ReadyUp for TF2", FCVAR_SPONLY | FCVAR_NOTIFY | FCVAR_PLUGIN), PLUGIN_VERSION);
	g_cvar_adscoring = CreateConVar("matchmod_adscoring", "0", "If server is in an Attack/Defend map.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvar_ctfscoring = CreateConVar("matchmod_ctfscoring", "0", "If server is in an CTF map.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvar_redteamname = CreateConVar("matchmod_redteamname", "RED", "Red team name.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvar_bluteamname = CreateConVar("matchmod_blueteamname", "BLU", "Blue team name.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	g_cvar_hostnamepfx = CreateConVar("matchmod_hostnamepfx", "|MatchMod|", "Hostname prefix as mod modifies hostname during the match.", FCVAR_PLUGIN);
	g_cvar_hostnamesfx = CreateConVar("matchmod_hostnamesfx", "Match Server", "Hostname suffix for when server is idle.", FCVAR_PLUGIN);
	g_cvar_servercfg = CreateConVar("matchmod_servercfg", "matchmod/matchmod_push.cfg", "Config file used for match rules.", FCVAR_PLUGIN);
	g_cvar_servercfgot = CreateConVar("matchmod_servercfgot", "matchmod/matchmod_push-overtime.cfg", "Config file used for overtime match rules.", FCVAR_PLUGIN);
	g_cvar_servercfgidle = CreateConVar("matchmod_servercfgidle", "matchmod/matchmod_dm.cfg", "Config file used for idle time.", FCVAR_PLUGIN);
	CreateConVar("matchmod_allowovertime", "1", "If matches should go into overtime.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("matchmod_allowhalf", "0", "If matches should have a 1st and 2nd half.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);
	CreateConVar("matchmod_maxpoints", "4", "Maximum score allowed in league rules.", FCVAR_PLUGIN|FCVAR_REPLICATED|FCVAR_NOTIFY);

//***********************************************
	cvarReadyMinimum = CreateConVar("mini_players", "8", "Mini # of players before we can ready up", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_NOTIFY);
	
	RegConsoleCmd("say", Command_Say);
	RegConsoleCmd("say_team", Command_Say);
	RegConsoleCmd("sm_ready", readyUp);
	RegConsoleCmd("sm_unready", readyDown);
	RegConsoleCmd("sm_notready", readyDown); //alias 
	RegConsoleCmd("tournament_readystate", cmd_block);
	RegConsoleCmd("tournament_teamname", cmd_block);

	RegAdminCmd("sm_begin_readyup", beginReadyUp, ADMFLAG_BAN, "sm_begin_readyup");
	RegAdminCmd("sm_stop_readyup" , StopReadyUp , ADMFLAG_BAN, "sm_stop_readyup ");
	RegAdminCmd("sm_start", ForceStart, ADMFLAG_BAN, "sm_start");
//***********************************************
	g_cvar_tvenable = FindConVar("tv_enable");
	mm_recording = GetConVarInt(g_cvar_tvenable);
	g_cvar_alltalk = FindConVar("sv_alltalk");

	// Team status updates
	HookEvent("tournament_stateupdate", TeamStateEvent, EventHookMode_Pre);

	// Game restart
	HookEvent("teamplay_restart_round", GameRestartEvent);

	// Win conditions met
	HookEvent("teamplay_game_over", GameOverEvent);

	// Round has been won
	HookEvent("teamplay_round_win", GameRoundWonEvent);

	// Scoreboard panel is displayed
	HookEvent("teamplay_win_panel", GameWinPanel);

	// Flag Captured Event
	HookEvent("ctf_flag_captured", FlagCapturedEvent);

	// Win conditions met
	HookEvent("tf_game_over", GameOverEvent);

	// Hook into mp_tournament_restart
	RegServerCmd("mp_tournament_restart", TournamentRestartHook);

	// Create a comand to begin the entire match process
	RegAdminCmd("sm_matchmod_config", Command_MatchModConfig, ADMFLAG_GENERIC, "sm_matchmod_config - Loads matchmod config files");

	// Create a comand to begin the entire match process
	RegAdminCmd("sm_matchmod_begin", Command_MatchModBegin, ADMFLAG_GENERIC, "sm_matchmod_begin - Begins match sequence.");

	// Create a comand to begin the entire match process
	RegAdminCmd("sm_matchmod_teamname", Command_MatchModTeam, ADMFLAG_GENERIC, "sm_matchmod_teamname - Assigns Team Names");

}

public OnMapStart()
{
	ResetVariables();

	// Check every 30secs if there are still players on the server
	CreateTimer(30.0, CheckPlayers, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
}

/**************************************
***************************************
******     START FROM HERE      *******
***************************************
**************************************/


/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public bool:OnClientConnect()
{
	if (readyMode) checkStatus();
	return true;
		
}

/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public OnClientDisconnect()
{
	if (readyMode) checkStatus();
}

/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public Action:cmd_block(client, args) {
	return (readyMode ? Plugin_Handled : Plugin_Continue);
}

/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public Action:Command_Say(client, args)
{


	
	if (args < 1 || !readyMode)
	{
		return Plugin_Continue;
	}
	
	decl String:sayWord[MAX_NAME_LENGTH];
	GetCmdArg(1, sayWord, sizeof(sayWord));
	
	new idx = StrContains(sayWord, "notready", false);
	if(idx == 1)
	{
	
		readyDown(client, args);
		return Plugin_Handled;
	}
	
	idx = StrContains(sayWord, "unready", false);
	if(idx == 1)
	{
	
		readyDown(client, args);
		return Plugin_Handled;
	}
	
	idx = StrContains(sayWord, "ready", false);
	if(idx == 1)
	{
	
		readyUp(client, args);
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public Action:readyUp(client, args)
{

	if( readyStatus[client])
	PrintToChat(client ,"\x04[ReadyUp]\x01your status Ready");
		
	if (!readyMode || readyStatus[client])	 return Plugin_Handled;	

	
	new realPlayers = CountInGameHumans();
	new minPlayers = GetConVarInt(cvarReadyMinimum);
	new team = GetClientTeam(client) - TEAM_OFFSET;
	
		
	if (team == RED || team == BLU)
	{

		decl String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
	

		if( realPlayers >= minPlayers)
		{
			PrintToChatAll("\x04[ReadyUp]\x01%s is \x03Ready.", name);
			readyStatus[client] = 1;
			DrawPanel(client);
		}
		else	PrintToChat(client ,"\x04[ReadyUp]\x01there are few player's here ,you can't start ReadyUp");	
	}
	checkStatus();	

	return Plugin_Handled;

}
/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public Action:readyDown(client, args)
{

	if( !readyStatus[client])
	PrintToChat(client ,"\x04[ReadyUp]\x01your status Not Ready");
		
	if (!readyMode || !readyStatus[client])	 return Plugin_Handled;	


	new realPlayers = CountInGameHumans();
	new minPlayers = GetConVarInt(cvarReadyMinimum);
	new team = GetClientTeam(client) - TEAM_OFFSET;
			
		
	if (team == RED || team == BLU)
	{

		decl String:name[MAX_NAME_LENGTH];
		GetClientName(client, name, sizeof(name));
	

		if( realPlayers >= minPlayers)
		{
			PrintToChatAll("\x04[ReadyUp]\x01%s is \x03Not Ready.", name);
			readyStatus[client] = 0;
			DrawPanel(client);

		}
			
		else	PrintToChat(client ,"\x04[ReadyUp]\x01there are few player's here ,you can't start ReadyUp");	
	}

	checkStatus();	

	return Plugin_Handled;
}
/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public Action:beginReadyUp(client, args)
{
	infoBegin = CreateTimer(20.0, infoBeginReadyUp, _, TIMER_REPEAT);
	readyOn();
	return Plugin_Handled;
}


/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public Action:StopReadyUp(client, args)
{
	KillTimer(infoBegin);
	readyoff();
	return Plugin_Handled;
}
/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public Action:ForceStart(client, args)
{

	if(!readyMode)
		return Plugin_Handled;

	PrintToChatAll("\x04[ReadyUp]\x01Match Going To Start After 10 Second, \x01To Abort x\04.notready");
	liveTimer = CreateTimer(10.0, startMatchCountDown);

	return Plugin_Handled;
}

/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public Action:infoBeginReadyUp(Handle:timer)
{
	PrintToChatAll("\x04[ReadyUp]\x01To Start Playing Change Your Stats \x03.ready / .notready");
}


/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
public Action:startMatchCountDown(Handle:timer)
{
	
	ServerCommand("mp_restartgame 5");
	KillTimer(infoBegin);
	readyoff();
}

/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
checkStatus()
{
	
	new humans, ready;
	decl i;
	new redCount,blueCount	;

	for (i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && !IsFakeClient(i))
		{
			humans++;
			if (readyStatus[i])
			{
				new team = GetClientTeam(i) - TEAM_OFFSET;
			
				if (team == RED)
					redCount++;

				if (team == BLU)
					blueCount++;

			} 
		}
	}


	ready = blueCount + redCount;


	if (humans == 0 || humans < GetConVarInt(cvarReadyMinimum))
		return;


	if (MAX_PLAYER_ALLOWED != ready)
			KillTimer(liveTimer);

	else if (MAX_PLAYER_ALLOWED == ready)
	{
		PrintToChatAll("\x04[ReadyUp]\x01Match Going To Start After 10 Second, \x01To Abort x\04.notready");
		liveTimer = CreateTimer(10.0, startMatchCountDown);
	}	


}
/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
CountInGameHumans()
{

	
	new i, realPlayers = 0;
	for(i = 1; i < MaxClients; i++)
	{
		if(IsClientInGame(i) && !IsFakeClient(i)) 
		
			realPlayers++;
		
	}
	return realPlayers;
}

/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
readyOn()
{
	readyMode = true;
}

/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/
readyoff()
{
	readyMode 	= false;


	for(new i = 1; i < MaxClients; i++)
		if(IsClientInGame(i) && !IsFakeClient(i)) 
			readyStatus[i] = 0;		

}

/*****************************************************************
**    Ready up for TF2						**
**								**
*****************************************************************/


public ReadyPanelHandler(Handle:menu, MenuAction:action, param1, param2)
{
}


public Action:DrawPanel(client)
{
	if (!readyMode) return Plugin_Handled;
		
	new numPlayers = 0;
	new numPlayers2 = 0;

	new i;

	new String:readyPlayers[1024];
	new String:name[MAX_NAME_LENGTH];

	new Handle:panel = CreatePanel();

	
	if (readyMode)
	{
		DrawPanelText(panel, ".READY.");

		for(i = 1; i <  MaxClients ; i++) 

			if(IsClientInGame(i) && !IsFakeClient(i)) 
			{
				GetClientName(i, name, sizeof(name));
				if(readyStatus[i]) 
				{
					numPlayers++;
					Format(readyPlayers, 1024, "->%d. %s", numPlayers, name);
					DrawPanelText(panel, readyPlayers);
				}
			}
	}

	if (readyMode)
	{
		DrawPanelText(panel, ".NOT READY.");

		for(i = 1; i <  MaxClients ; i++) 

			if(IsClientInGame(i) && !IsFakeClient(i)) 
			{
				GetClientName(i, name, sizeof(name));
				if(!readyStatus[i]) 
				{
					numPlayers2++;
					Format(readyPlayers, 1024, "->%d. %s", numPlayers2, name);
					DrawPanelText(panel, readyPlayers);				
				}
			}
	}


	DrawPanelText(panel,"-->  KSA_ScREaM Panel <--");			

	if (readyMode)
	{
		for(i = 1; i <  MaxClients ; i++) 
	
			if(IsClientInGame(i) && !IsFakeClient(i)) 

				SendPanelToClient(panel, i, ReadyPanelHandler, 10);
	}

	CloseHandle(panel);
 
	return Plugin_Handled;
}



/**************************************
***************************************
******        END  HERE         *******
***************************************
**************************************/






//----------------------------------------------------------------------------
//| Callbacks
//----------------------------------------------------------------------------

public Action:Command_MatchModTeam(client, args)
{
	if (args < 2)
	{
		ReplyToCommand(client, "[MatchMod] Usage: sm_matchmod_teamname <team> \"<name>\"");
		return Plugin_Handled;
	}
	decl String:assignteamname[32];
	decl String:assignteam[4];

	GetCmdArg(1, assignteam, sizeof(assignteam));
	GetCmdArg(2, assignteamname, sizeof(assignteamname));

	if (StrEqual(assignteam, "red", false) && StrEqual(assignteam, "blu", false))
	{
		ReplyToCommand(client, "[MatchMod] Invalid Team, team must be either red or blu.");
		return Plugin_Handled;
	}

	if (StrEqual(assignteam, "red", false))
	{
		SetConVarString(FindConVar("matchmod_redteamname"), assignteamname);
		ReplyToCommand(client, "[MatchMod] Red team assigned name %s.", assignteamname);
		return Plugin_Handled;
	}
	else if (StrEqual(assignteam, "blu", false))
	{
		SetConVarString(FindConVar("matchmod_blueteamname"), assignteamname);
		ReplyToCommand(client, "[MatchMod] Blue team assigned name %s.", assignteamname);
		return Plugin_Handled;
	}

	return Plugin_Handled;
}



//----------------------------------------------------------------------------
//| Action:Command_MatchModConfig(client, args)
//|
//| Duplicate of exec config function to allow delegated access
//| Forces configs to exist in cfg/matchmod
//----------------------------------------------------------------------------
public Action:Command_MatchModConfig(client, args)
{
	if (mm_state == 0)
	{
		if (args < 1)
		{
			ReplyToCommand(client, "[MatchMod] Usage: sm_matchmod_config <config>");
			return Plugin_Handled;
		}

		decl String:config[64] = "cfg/matchmod/";
		GetCmdArg(1, config[13], sizeof(config)-13);

		StrCat(config, 64, ".cfg");

		if (!FileExists(config))
		{
			ReplyToCommand(client, "[MatchMod] Config not found");
			return Plugin_Handled;
		}

		ServerCommand("exec \"%s\"", config[4]);
		ReplyToCommand(client, "[MatchMod] Executed Config");
	}

	return Plugin_Handled;
}


//----------------------------------------------------------------------------
//| Action:Command_MatchModBegin(client, args)
//|
//| Initializes MatchMod and moves into the Pre-game phase
//| Ignored if a match is currently in progress
//----------------------------------------------------------------------------
public Action:Command_MatchModBegin(client, args)
{
	if (mm_state == 0)
	{
		// Make sure tournament mode is firing, occasionally UI won't show
		ServerCommand("mp_tournament 1");

		ReplyToCommand(client, "[MatchMod] Beginning match sequence");

		mm_state++;
		
		ServerCommand("sm_begin_readyup");
		AdvanceMatchState();
	}
	
	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| GameWinPanel(Handle:event, const String:name[], bool:dontBroadcast)
//|
//| Using the Win panel to determine scores for Checkpoint, stopwatch
//| and Payload gametypes
//----------------------------------------------------------------------------
public GameWinPanel(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (mm_state == 0)
	{
		return;
	}

	new roundcomplete = GetEventInt(event, "round_complete");

	if (!adscoring && !ctfscoring)
	{
		new wteam = GetEventInt(event, "winning_team") - TEAM_OFFSET;

		if (wteam == 1)
		{
			mm_tmbscore++;
		}
		if (wteam == 0)
		{
			mm_tmascore++;
		}

		Scoring();

		if (mm_tmascore == mm_topscore || mm_tmbscore == mm_topscore)
		{
			EndMatch();
		}
		// Reset the variable to junk just in case
		wteam = 3;
		return;
	}
	if (adscoring && roundcomplete)
	{	
		mm_roundcount++;
		if (mm_roundcount == 2)
		{
			SwapTeams(true);
			return;
		}





		if (mm_roundcount == 3)
		{
			SwapTeams(false);


			new wteam = GetEventInt(event, "winning_team") - TEAM_OFFSET;

			if (wteam == 1)
			{
				mm_tmbscore++;
			}
			if (wteam == 0)
			{
				mm_tmascore++;
			}

			Scoring();
			return;
		}


		if (mm_roundcount == 4)
		{
			SwapTeams(true);
			return;
		}


		// Round Count over two we can assume its over and actually grab the score
		if (mm_roundcount > 4)
		{
			new wteam = GetEventInt(event, "winning_team") - TEAM_OFFSET;

			if (wteam == 1)
			{
				mm_tmbscore++;
			}
			if (wteam == 0)
			{
				mm_tmascore++;
			}

			Scoring();

			// Reset the variable to junk just in case
			wteam = 3;
			return;
		}
	}
}

public FlagCapturedEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (mm_state == 0)
	{
		return;
	}

	new wteam = GetEventInt(event, "capping_team") - TEAM_OFFSET;

	if (wteam == 1)
	{
		mm_tmbscore++;
	}
	if (wteam == 0)
	{
		mm_tmascore++;
	}

	Scoring();

	// Reset the variable to junk just in case
	wteam = 3;
	return;
}


//----------------------------------------------------------------------------
//| TeamStateEvent(Handle:event, const String:name[], bool:dontBroadcast)
//|
//| Prevents users from manually renaming teams if match is
//| is in progress
//----------------------------------------------------------------------------
public TeamStateEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (mm_state > 0)
	{
		new team = GetClientTeam(GetEventInt(event, "userid")) - TEAM_OFFSET;

		if (team == RED)
		{
			SetEventString(event, "newname", mm_tmaname);
		}
		if (team == BLU)
		{
			SetEventString(event, "newname", mm_tmbname);
		}

		SetEventBool(event, "namechange", false);
	}
}

//----------------------------------------------------------------------------
//| GameRestartEvent(Handle:event, const Stringname[], bool:dontBroadcast)
//|
//| Handles the beginning of a match and moves into the next phase
//| to trigger logging/recording/alltalk events
//----------------------------------------------------------------------------
public GameRestartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (mm_state > 0)
	{
		AdvanceMatchState();
	}
}

//----------------------------------------------------------------------------
//| GameRoundWonEvent(Handle:event, const Stringname[], bool:dontBroadcast)
//|
//| This function may not be relevant at the end of it all
//----------------------------------------------------------------------------
public GameRoundWonEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (mm_state == 0)
	{
		return;
	}
}


//----------------------------------------------------------------------------
//| GameOverEvent(Handle:event, const Stringname[], bool:dontBroadcast)
//|
//| End of a round for whatever reason
//----------------------------------------------------------------------------
public GameOverEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	if (mm_state > 0)
	{
		AdvanceMatchState();
	}
}

//----------------------------------------------------------------------------
//| Action:TournamentRestartHook(args)
//|
//| Beginning of Round
//----------------------------------------------------------------------------
public Action:TournamentRestartHook(args)
{
	if (mm_state > 1)
	{
		mm_state = 7;
		ServerCommand("sm_stop_readyup");
		AdvanceMatchState();
	}
	return Plugin_Continue;
}



//----------------------------------------------------------------------------
//| Action:CheckPlayers(Handle:timer, any:useless)
//|
//| Checks if players are still in server every 30 seconds
//| Written by jasonfrog for Match Recorder plugin
//----------------------------------------------------------------------------
public Action:CheckPlayers(Handle:timer, any:useless)
{
	if (mm_state > 0)
	{
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientConnected(i) && !IsFakeClient(i))
			{
				return;
			}
		}

		HardEndMatch();
	}
}

//----------------------------------------------------------------------------
//| Private functions
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
//| ResetVariable()
//|
//| Flags all variables to initial state and removes
//| the notify flag changes performed
//----------------------------------------------------------------------------
ResetVariables()
{
	// Reset all variables to default
	mm_tmascore = 0;
	mm_tmbscore = 0;
	mm_tmpscore = 0;
	mm_state = 0;
	mm_roundcount = 0;
	adscoring = false;
	ctfscoring = false;
	recording = false;
	SetNotifyFlag(g_cvar_alltalk);
}

//----------------------------------------------------------------------------
//| StartRecording() - based from matchrecorder plugin
//|
//| Formats name of recording and starts recording
//----------------------------------------------------------------------------
StartRecording()
{
	if (mm_recording)
	{
		if (recording)
		{
			PrintToChatAll("\x04[MatchMod]\x01 Already recording");
			return;
		}

		// Format the demo filename
		new String:timestamp[64];
		new String:map[16];
		new String:filename[40];
		new String:command[64];

		FormatTime(timestamp, 64, "%Y-%m-%d-%Hh%Mm");
		GetCurrentMap(map, 16);
		Format(filename, 40, "%s_%s.dem", timestamp, map);
		Format(command, 64, "tv_record %s", filename);

		// Start recording
		PrintToChatAll("\x04[MatchMod]\x01 Recording started");
		ServerCommand(command);

		recording = true;
	}
}

//----------------------------------------------------------------------------
//| StopRecording() - from matchrecorder plugin
//|
//| Stops recording
//----------------------------------------------------------------------------
StopRecording()
{
	// Stop recording
	CreateTimer(5.0, StopRecordHandle);
	recording = false;
	PrintToChatAll("\x04[MatchMod]\x01 Recording stopped");
}

//----------------------------------------------------------------------------
//| StopRecording() - Delay To Stop Record 5 Second
//|
//| Stops recording
//----------------------------------------------------------------------------


public Action:StopRecordHandle(Handle:timer)
{
	ServerCommand("tv_stoprecord");
}



//----------------------------------------------------------------------------
//| DisableAlltalk()
//|
//| Disables Alltalk - sv_alltalk 0
//----------------------------------------------------------------------------
DisableAlltalk()
{
	PrintToChatAll("\x04[MatchMod]\x01 Alltalk disabled");
	SetConVarInt(g_cvar_alltalk, 0);
}

//----------------------------------------------------------------------------
//| EnableAlltalk()
//|
//| Enables Alltalk - sv_alltalk 1
//----------------------------------------------------------------------------
EnableAlltalk()
{
	PrintToChatAll("\x04[MatchMod]\x01 Alltalk Enabled");
	SetConVarInt(g_cvar_alltalk, 1);
}

//----------------------------------------------------------------------------
//| DisableLogging()
//|
//| Closes the server log
//----------------------------------------------------------------------------
DisableLogging()
{
	// PrintToChatAll("\x04[MatchMod]\x01 Saving match log");
	ServerCommand("log off");
}

//----------------------------------------------------------------------------
//| EnableLogging()
//|
//| Opens the server log
//----------------------------------------------------------------------------
EnableLogging()
{
	// PrintToChatAll("\x04[MatchMod]\x01 Starting match log");
	ServerCommand("log on");
}

//----------------------------------------------------------------------------
//| UnsetNotifyFlag(Handle:hndl)
//|
//| Removes the FCVAR_NOTIFY flag from a given handle
//----------------------------------------------------------------------------
UnsetNotifyFlag(Handle:hndl)
{
	new flags = GetConVarFlags(hndl);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(hndl, flags);
}

//----------------------------------------------------------------------------
//| SetNotifyFlag(Handle:hndl)
//|
//| Adds the FCVAR_NOTIFY flag to a given handle
//----------------------------------------------------------------------------
SetNotifyFlag(Handle:hndl)
{
	new flags = GetConVarFlags(hndl);
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(hndl, flags);
}


//----------------------------------------------------------------------------
//| ServerName() - need Optimization
//|
//| Creates a new hostname string and set the CVAR
//----------------------------------------------------------------------------
ServerName()
{
	new String:hostname[64];

	GetConVarString(g_cvar_hostnamepfx, mm_hnpfx, sizeof(mm_hnpfx));
	GetConVarString(g_cvar_hostnamesfx, mm_hnsfx, sizeof(mm_hnsfx));

	if (mm_state == 0)
	{
			Format(hostname, 64, "%s ", mm_hnsfx);
	}
	else if (mm_state == 2 || mm_state == 1)
	{
			Format(hostname, 64, "%s ", mm_hnsfx);
	}
	else
	{
		if (mm_tmascore == mm_tmbscore)
		{
			Format(hostname, 64, "%s ", mm_hnsfx);
		}

		if (mm_tmascore > mm_tmbscore)
		{
			Format(hostname, 64, "%s ", mm_hnsfx);
		}

		if (mm_tmascore < mm_tmbscore)
		{
			Format(hostname, 64, "%s ", mm_hnsfx);
		}
	}
	SetConVarString(FindConVar("hostname"), hostname);
}

//----------------------------------------------------------------------------
//| SwapTeams(bool:nameonly)
//|
//| Switches all the variables/cvars of the two teams
//----------------------------------------------------------------------------
SwapTeams(bool:nameonly)
{
	PrintToChatAll("\x04[MatchMod]\x01 Swapping teams");

	// Swaps the scores for tracking
	mm_tmpscore = mm_tmascore;
	mm_tmascore = mm_tmbscore;
	mm_tmbscore = mm_tmpscore;
	mm_tmpscore = 0;

	// Swap team names for Play by play
	strcopy(mm_tmpname, sizeof(mm_tmpname), mm_tmaname);
	strcopy(mm_tmaname, sizeof(mm_tmaname), mm_tmbname);
	strcopy(mm_tmbname, sizeof(mm_tmbname), mm_tmpname);

	if (!nameonly)
	{
		for (new client=1; client <= MaxClients; client++)
		{
			if (IsClientInGame(client) && (GetClientTeam(client) == 2))
			{
				ChangeClientTeam(client, 1);
				ChangeClientTeam(client, 3);
			}
			else if (IsClientInGame(client) && (GetClientTeam(client) == 3))
			{
				ChangeClientTeam(client, 1);
				ChangeClientTeam(client, 2);
			}
		}
	}
}


//----------------------------------------------------------------------------
//| InitializeVariables
//|
//| Once the match mode is turned on, check all the CVARS and
//| pull set internal variables accordingly
//----------------------------------------------------------------------------
InitializeVariables()
{
	decl String:teamname[16];

	g_cvar_maxpoints = FindConVar("matchmod_maxpoints");
	mm_topscore = GetConVarInt(g_cvar_maxpoints);

	g_cvar_allowovertime = FindConVar("matchmod_allowovertime");
	mm_allowovertime = GetConVarInt(g_cvar_allowovertime);

	adscoring = GetConVarBool(g_cvar_adscoring);
	ctfscoring = GetConVarBool(g_cvar_ctfscoring);

	g_cvar_allowhalf = FindConVar("matchmod_allowhalf");
	mm_allowhalf = GetConVarInt(g_cvar_allowhalf);
	
	GetConVarString(g_cvar_servercfg, mm_svrcfg, sizeof(mm_svrcfg));
	GetConVarString(g_cvar_servercfgot, mm_svrcfgot, sizeof(mm_svrcfgot));
	GetConVarString(g_cvar_servercfgidle, mm_svrcfgidle, sizeof(mm_svrcfgidle));

	GetConVarString(g_cvar_bluteamname, teamname, sizeof(teamname));
	SetConVarString(FindConVar("mp_tournament_blueteamname"), teamname);
	strcopy(mm_tmbname, sizeof(mm_tmbname), teamname);
	GetConVarString(g_cvar_redteamname, teamname, sizeof(teamname));
	SetConVarString(FindConVar("mp_tournament_redteamname"), teamname);
	strcopy(mm_tmaname, sizeof(mm_tmaname), teamname);

	// Remove the notify flag since we will display our own warnings when it changes
	UnsetNotifyFlag(g_cvar_alltalk);
}

//----------------------------------------------------------------------------
//| Scoring()
//|
//| Based on given scenarios, produce the play by play string
//----------------------------------------------------------------------------
Scoring()
{
	new String:playbyplay[64];
	new String:remainingtime[256];

	new timeleft;

	GetMapTimeLeft(timeleft);

	Format(remainingtime, 256, "%d:%02d", (timeleft / 60), (timeleft % 60));

	if (!adscoring)
	{
		Format(playbyplay, 64, "\x04[MatchMod]\x01 About %s remaining in the round", remainingtime);
		PrintToChatAll(playbyplay);
	}

	if (mm_tmascore == mm_tmbscore)
	{
		Format(playbyplay, 64, "\x04[MatchMod]\x01 Teams are tied %d-%d", mm_tmascore, mm_tmbscore);
	}

	if (mm_tmascore > mm_tmbscore)
	{
		Format(playbyplay, 64, "\x04[MatchMod]\x01 %s leads %d-%d", mm_tmaname, mm_tmascore, mm_tmbscore);
	}

	if (mm_tmascore < mm_tmbscore)
	{
		Format(playbyplay, 64, "\x04[MatchMod]\x01 %s leads %d-%d", mm_tmbname, mm_tmbscore, mm_tmascore);
	}

	PrintToChatAll(playbyplay);
	ServerName();
}

//----------------------------------------------------------------------------
//| ScoreIntermissions()
//|
//| Based on given scenarios, produce the play by play string
//| used when entering Halftime and Postgame
//----------------------------------------------------------------------------
ScoreIntermission()
{
	new String:playbyplay[64];

	if (mm_tmascore == mm_tmbscore)
	{
		Format(playbyplay, 64, "\x04[MatchMod]\x01 Teams are tied %d-%d", mm_tmascore, mm_tmbscore);
	}

	if (mm_tmascore > mm_tmbscore)
	{
		Format(playbyplay, 64, "\x04[MatchMod]\x01 %s leads %d-%d", mm_tmaname, mm_tmascore, mm_tmbscore);
	}

	if (mm_tmascore < mm_tmbscore)
	{
		Format(playbyplay, 64, "\x04[MatchMod]\x01 %s leads %d-%d", mm_tmbname, mm_tmbscore, mm_tmascore);
	}

	PrintToChatAll(playbyplay);
}

//----------------------------------------------------------------------------
//| FinalScore()
//|
//| Declares a winner and posts the play by play statement
//----------------------------------------------------------------------------
FinalScore()
{
	new String:playbyplay[64];

	if (mm_tmascore == mm_tmbscore)
	{
		Format(playbyplay, 64, "\x04[MatchMod]\x01 The teams have fought to a draw");
	}

	if (mm_tmascore > mm_tmbscore)
	{
		Format(playbyplay, 64, "\x04[MatchMod]\x01 %s has won the match", mm_tmaname);
	}

	if (mm_tmascore < mm_tmbscore)
	{
		Format(playbyplay, 64, "\x04[MatchMod]\x01 %s has won the match", mm_tmbname);
	}

	PrintToChatAll(playbyplay);

}

//----------------------------------------------------------------------------
//| ExecOvertime()
//|
//| Executes the Overtime rules config file
//----------------------------------------------------------------------------
ExecOvertime()
{
	// Sets the overtime regulations
	PrintToChatAll("\x04[MatchMod]\x01 Configuring Overtime");
	ServerCommand("exec %s", mm_svrcfgot);
}

//----------------------------------------------------------------------------
//| ExecIdle()
//|
//| Executes the Idle rules config file
//----------------------------------------------------------------------------
ExecIdle()
{
	// Sets the idle regulations
	//PrintToChatAll("\x04[MatchMod]\x01 Configuring Idle config");
	ServerCommand("exec %s", mm_svrcfgidle);
}

//----------------------------------------------------------------------------
//| ExecRegulation()
//|
//| Executes the regulation rules config file
//----------------------------------------------------------------------------
ExecRegulation()
{
	// Sets the regulation
	PrintToChatAll("\x04[MatchMod]\x01 Configuring Regulation");
	ServerCommand("exec %s", mm_svrcfg);
}


//----------------------------------------------------------------------------
//| EndMatch()
//|
//| Allows the plugin to stop a match prematurely when the
//| scorelimit is reached
//----------------------------------------------------------------------------
EndMatch()
{
	ServerCommand("mp_tournament_restart");
}

//----------------------------------------------------------------------------
//| HardEndmatch()
//|
//| Whacks all variables and pretends nothing was ever
//| really going on
//----------------------------------------------------------------------------
HardEndMatch()
{
	if (mm_state > 0)
	{
		StopRecording();
		DisableLogging();
		EnableAlltalk();
		ResetVariables();
		ServerName();
		ExecIdle();
	}

}

//----------------------------------------------------------------------------
//| AdvanceMatchState()
//|
//| When called, will take a match through the various phases
//| such as pregame, 1st half, 2nd half, post game and
//| overtime. 
//----------------------------------------------------------------------------
AdvanceMatchState()
{

	if (mm_state == 0)
	{
		return;
	}

	// Pre-game
	if (mm_state == 1)
	{
		PrintToChatAll("\x04[MatchMod]\x01 Beginning Pre-game");
		InitializeVariables();
		ExecRegulation();
		ServerName();

		// Advance mm_state so match progresses next run
		mm_state++;

		return;
	}

	// 1st Half
	if (mm_state == 2)
	{
		PrintToChatAll("\x04[MatchMod]\x01  Match Live!");
		DisableAlltalk();
		EnableLogging();
		StartRecording();
		mm_roundcount = 1;
		PrintCenterTextAll("MATCH LIVE");

		// Advance mm_state so match progresses next run
		if (mm_allowhalf == 1)
		{
			mm_state++;
		}
		else
		{
			if (mm_allowovertime == 1)
			{
				mm_state = 5;
			}
			else
			{
				mm_state = 7;
			}
		}
		ServerName();

		return;
	}

	// Half-Time
	if (mm_state == 3)
	{
		PrintToChatAll("\x04[MatchMod]\x01 Match Live!");
		PrintCenterTextAll("HALF TIME");
		ScoreIntermission();
		EnableAlltalk();
		
		// Swap teams
		SwapTeams(false);

		// Kickoff Readyup

		// Advance mm_state so match progresses next run
		mm_state++;

		ServerName();

		return;
	}

	// Second Half
	if (mm_state == 4)
	{
		PrintToChatAll("\x04[MatchMod]\x01 Beginning 2nd Half");
		if (adscoring)
  		{
			SwapTeams(false);
		}
		DisableAlltalk();
		mm_roundcount = 1;

		PrintCenterTextAll("MATCH LIVE");

		// Advance mm_state so match progresses next run
		mm_state++;
		ServerName();

		return;
	}

	// Post-Game
	if (mm_state == 5)
	{
		PrintToChatAll("\x04[MatchMod]\x01 Ending regulation");
		EnableAlltalk();

		if (mm_tmascore == mm_tmbscore && mm_allowovertime == 1)
		{
			EnableAlltalk();
			PrintToChatAll("\x04[MatchMod]\x01 Teams are tied. Prepare for overtime");
			PrintCenterTextAll("PREPARE FOR OVERTIME");

			// Swap teams
			//SwapTeams(false);

			// Set Overtime rules
			ExecOvertime();

			// Advance mm_state so match progresses next run
			mm_state++;
			ServerName();
		}
		else
		{
			FinalScore();
			DisableLogging();
			StopRecording();
			EnableAlltalk();
			ResetVariables();
			ServerName();
			ExecIdle();
		}

		return;
	}

	// Overtime
	if (mm_state == 6)
	{
		PrintToChatAll("\x04[MatchMod]\x01 Match Live!");
		if (adscoring)
  		{
			SwapTeams(false);
		}
		DisableAlltalk();
		mm_roundcount = 1;

		PrintCenterTextAll("MATCH LIVE");

		// Advance mm_state so match progresses next run
		mm_state++;

		ServerName();

		return;
	}

	// Final
	if (mm_state == 7)
	{
		FinalScore();
		DisableLogging();
		StopRecording();
		EnableAlltalk();
		ResetVariables();
		ServerName();
		ExecIdle();

		return;
	}
}

