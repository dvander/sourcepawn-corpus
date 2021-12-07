/*
===============================================================================================================
MatchMod for Team Fortress 2

NAME			: MatchMod.sp        
VERSION			: 1.1.9
AUTHOR			: Charles 'Hawkeye' Mabbott
DESCRIPTION		: Faciliate the running of a league match
REQUIREMENTS	: Sourcemod 1.2+

VERSION HISTORY	: 
	0.9		- First Public release
	0.9.2	- Modified commands to use chat text hooks
			- Added ability to return to a idle configuration
			- Added commands to modify configs from client
			- Added PUG support in the example configs
	0.9.5	- Added CTF scoring
			- Added commands to change team names
	0.9.6	- Code optimations
			- Moved SourceTV check to gametime as opposed to plugin load
			- Added ability to change map after sequence has begun to allow for weapon whitelist to be utilized
			- Added filter to reduce console spam
	0.9.7   - Added Autoupdate support
	0.9.8	- Added support for players to assign their own teamnames until 1st half begins
	1.0.0	- Added ReadyUp Support
	1.0.1	- Bugfixes from Scream
			- Timelimit reached was adding to CP scores when it shouldn't
			- Ready-up panel displaying to spectators
	1.0.2	- Ready-up bug fixed that prevented ready-up for the second half and overtime
	1.0.3	- Blocking tournament_readystate command while Ready-Up is enabled
	1.0.4	- Modified mp_winlimit during second half to not matter to match how rules are interpreted
			- Changed Panel to only display of sm_readystatus is used.
	1.0.5	- Modified scoring routine to cleaning handle King of the Flag
	1.0.6	- Modified CTF scoring slightly to allow matches to end at flag captures
	1.0.7	- Reconfigured mp_tournament_restart hook to allow its usage to ensure UI is active without stopping
			   the match in progress until the start of the 1st half. This allows league configs to have the
			   tournament_restart command in them without breaking the mod.
			- Modified some of the scoring message to be in the hintbox and not in chat
	1.0.8	- Modified Scoring notification to be delayed
	1.0.9	- Hooked ServerName variables to detect when changes occur
			- Added ServerOp defined flag to access admin features
			- Reorganized code, cleaned up section
			- Modified Announcer to be a bit easer to see
	1.1.0	- Added map autodetection and configuration using the matchmod_league CVAR
	1.1.1	- Modified Final Score wording to make the final results clearer
			- Added Logging of Admin commands to Sourcemod Log and SMActivity functions
	1.1.2	- Added Localization support
			- Modified PUG configs to allow standard tournament UI
			- Removed a couple unused functions
	1.1.3	- Added a prematch/postmatch cfg execution to allow server admins to load/unload plugins
			- Added Admin Menu API intgeration of some of the base functions
	1.1.4	- Added tf2lobby.com integration
			- Removed the adscoring an ctfscoring CVARs, this is now handled as part of the map detection
	1.1.5	- Moved teamname CVARs to auto config file
			- Created new !match/!scrim command to quickly get matches up and running
	1.1.6	- Moved 15 second warning to center text
			- added !extend command to allow teams to quickly extend scrims
			- Extended logging to cover all admin commands
	1.1.7	- Added size to Hostname prefix to accomodate longer server names
			- Modified some of the CVARs to not replicate what doesn't need to be replicated
			- Added autodetection of arena map type
			- Added ability to define where STVs will be saved
			- SDKHooks is now an optional extension
			- If SDKHooks is present, the Game Description will be changed to reflect the league config
			- Added CVAR matchmod_public to allow for configurations that allow public to access some commands
			- Added CVAR matchmod_stvfolder to define where the STVs will be saved relativeto /TF2 folder
			- Added CVAR matchmod_description to allow the shortcut configs to define the STV prefix and the
			   the modified game description
	1.1.8	- Expanded map auto-detection to cover arena, territory control, and bball
			- Added support for Arena game type to the scoring routines 
			- Added support for Territory Control to the scoring routines
			- Removed CVAR matchmod_public and matchmod_admflag
			- Modified all commands so the standard override options will work
			- Added damage output statistics to the server logs for parsers
	1.1.9	- Added Item pick-ups to log files
			- Added pauses to log files
			- Added player specific heals to the log files
			- Added sm_6v6 and sm_9v9
			- Modified sm_scrim to pull the matchmod_league CVAR to determine what configs to RunAdminCacheChecks
			- Removed sm_matchmod_begin
===============================================================================================================
*/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "1.1.9"

#define RED 0
#define BLU 1
#define TEAM_OFFSET 2
#undef REQUIRE_PLUGIN
#include <adminmenu>
#include <autoupdate>
#undef REQUIRE_EXTENSIONS
#include <sdkhooks>

public Plugin:myinfo =
{
	name = "MatchMod",
	author = "Hawkeye",
	description = "Facilitates competitive play for league formatted matches",
	version = PLUGIN_VERSION,
	url = "http://matchmod.net"
};


//----------------------------------------------------------------------------
//| Variables
//----------------------------------------------------------------------------

new bool:recording = false;
new bool:adscoring = false;
new bool:ctfscoring = false;
new bool:arenascoring = false;
new bool:tcscoring = false;
new bool:readyup = false;
new bool:readyenabled = false;
new bool:redforce = false;
new bool:redallowforce = false;
new bool:redready = false;
new bool:bluforce = false;
new bool:bluallowforce = false;
new bool:bluready = false;
new bool:readystart = false;
new bool:isLobby = false;
new bool:isPaused = false;
new readyStatus[MAXPLAYERS + 1]; 
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
new Handle:g_cvar_readyenable = INVALID_HANDLE;
new Handle:g_cvar_minred = INVALID_HANDLE;
new Handle:g_cvar_reqred = INVALID_HANDLE;
new Handle:g_cvar_minblu = INVALID_HANDLE;
new Handle:g_cvar_reqblu = INVALID_HANDLE;
new Handle:g_cvar_temptime = INVALID_HANDLE;
new Handle:g_cvar_league = INVALID_HANDLE;
new Handle:g_cvar_description = INVALID_HANDLE;
new Handle:g_cvar_stvfolder = INVALID_HANDLE;
new Handle:hAdminMenu = INVALID_HANDLE;
new Handle:liveTime = INVALID_HANDLE;
new String:mm_tmaname[16];
new String:mm_tmbname[16];
new String:mm_tmpname[16];
new String:mm_hnpfx[48];
new String:mm_hnsfx[48];
new String:mm_svrcfg[64];
new String:mm_svrcfgot[64];
new String:mm_svrcfgidle[64];
new String:mm_maptype[10];
new String:mm_lobbyid[10];
new String:mm_gamedesc[64];
new mm_tmascore = 0;
new mm_tmbscore = 0;
new mm_tmpscore = 0;
new mm_topscore = 0;
new mm_roundcount = 0;
new mm_allowhalf = 1;
new mm_allowovertime = 1;
new mm_state = 0;
new mm_recording = 0;
new mm_minred = 0;
new mm_minblu = 0;
new mm_reqred = 0;
new mm_reqblu = 0;
new mm_mintmp = 0;
new mm_reqtmp = 0;
new mm_temptime = 0;
new Float:mm_bonustime = 10.0;

//----------------------------------------------------------------------------
//| Plugin start up
//----------------------------------------------------------------------------

public OnPluginStart() {

	LoadTranslations("matchmod.phrases");
	LoadTranslations("core.phrases");
	
	CreateConVar("MatchMod_version", PLUGIN_VERSION, "MatchMod version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvar_redteamname = CreateConVar("matchmod_redteamname", "RED", "Red team name.", FCVAR_PLUGIN);
	g_cvar_bluteamname = CreateConVar("matchmod_blueteamname", "BLU", "Blue team name.", FCVAR_PLUGIN);
	g_cvar_hostnamepfx = CreateConVar("matchmod_hostnamepfx", "|MatchMod|", "Hostname prefix as mod modifies hostname during the match.", FCVAR_PLUGIN);
	g_cvar_hostnamesfx = CreateConVar("matchmod_hostnamesfx", "Match Server", "Hostname suffix for when server is idle.", FCVAR_PLUGIN);
	g_cvar_readyenable = CreateConVar("matchmod_readyenable", "1", "If full ready up mode is enabled.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_cvar_minred = CreateConVar("matchmod_minred", "5", "Minimum players on red team required to start a match.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_cvar_reqred = CreateConVar("matchmod_reqred", "6", "Amount where teams will automatically ready without confirmation.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_cvar_minblu = CreateConVar("matchmod_minblu", "5", "Minimum players on red team required to start a match.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_cvar_reqblu = CreateConVar("matchmod_reqblu", "6", "Amount where teams will automatically ready without confirmation.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_cvar_servercfg = CreateConVar("matchmod_servercfg", "pug/push.cfg", "Config file used for match rules.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_cvar_servercfgot = CreateConVar("matchmod_servercfgot", "pug/push-overtime.cfg", "Config file used for overtime match rules.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_cvar_servercfgidle = CreateConVar("matchmod_servercfgidle", "server.cfg", "Config file used for idle time.", FCVAR_PLUGIN);
	g_cvar_league = CreateConVar("matchmod_league", "pug", "Default league that matchmod should use when detecting map types.", FCVAR_PLUGIN);
	g_cvar_description = CreateConVar("matchmod_description", "MatchMod", "Controls the Game Desciption override text and STV prefix.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	g_cvar_stvfolder = CreateConVar("matchmod_stvfolder", "", "Specifies the folder to save STVs to, Relative to the tf folder.", FCVAR_PLUGIN);
	CreateConVar("matchmod_allowovertime", "1", "If matches should go into overtime.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	CreateConVar("matchmod_allowhalf", "1", "If matches should have a 1st and 2nd half.", FCVAR_PLUGIN|FCVAR_DONTRECORD);
	CreateConVar("matchmod_maxpoints", "5", "Maximum score allowed in league rules.", FCVAR_PLUGIN|FCVAR_DONTRECORD);

	g_cvar_tvenable = FindConVar("tv_enable");
	g_cvar_alltalk = FindConVar("sv_alltalk");

	// Game restart
	HookEvent("teamplay_restart_round", GameRestartEvent);

	// Win conditions met
	HookEvent("teamplay_game_over", GameOverEvent);

	// Scoreboard panel is displayed
	HookEvent("teamplay_win_panel", GameWinPanel);
	
	// Scoreboard panel is displayed
	HookEvent("arena_win_panel", GameWinPanel);

	// Display scoring summary to players at start of round
	HookEvent("teamplay_round_active", Scoring);

	// Display scoring summary to players at start of round
	HookEvent("arena_round_start", Scoring);

	// Flag Captured Event
	HookEvent("ctf_flag_captured", FlagCapturedEvent);

	// Win conditions met
	HookEvent("tf_game_over", GameOverEvent);

	// Hook countdown for Prematch Cfg execution
	HookEvent("teamplay_round_restart_seconds", PreMatch);
	
	// Hook item pickup to add to server logs for parsers
	HookEvent("item_pickup", ItemPickup);

	// Hook player hurt to add Damage output to the server logs for parsers
	HookEvent("player_hurt", PlayerHurt);
	
	// Hook player healed to add Heals per player to the server logs for parsers
	HookEvent("player_healed", PlayerHealed);

	// Hook player spawned to add spawns per player to the server logs for parsers
	HookEvent("player_spawn", PlayerSpawned);

	// Hook into mp_tournament_restart
	RegServerCmd("mp_tournament_restart", TournamentRestartHook);
	
	// Track Pauses in the Logs
	AddCommandListener(Listener_Pause, "pause");

	// Register the say command so I can detect if a lobby or match starts
	RegConsoleCmd("say", Command_Say);
	
	// Create a command to end the match in progress
	RegConsoleCmd("sm_matchmod_end", Command_MatchModEnd);

	// Create a command to define team names for match process
	RegConsoleCmd("sm_matchmod_teamname", Command_MatchModTeam);

	// Create a command to check the version of the plugin active
	RegConsoleCmd("sm_matchmod_version", Command_MatchModVersion);

	// Allow standard users to modify the matchmod teamname
	RegConsoleCmd("sm_readystatus", Command_MatchModReadyStatus);

	// Allow standard users to modify the matchmod teamname
	RegConsoleCmd("sm_teamname", Command_MatchModTeamname);

	// Allow standard users to modify the matchmod teamname
	RegConsoleCmd("sm_ready", Command_MatchModReady);

	// Allow standard users to modify the matchmod teamname
	RegConsoleCmd("sm_notready", Command_MatchModNotReady);

	// Allow standard users to modify the matchmod teamname
	RegConsoleCmd("sm_unready", Command_MatchModNotReady);

	// If minimum players are ready allow team to begin shorthanded
	RegConsoleCmd("sm_start", Command_MatchModForceStart);

	// Start a match with a quick shortcut
	RegConsoleCmd("sm_match", Command_MatchModMatch);
	
	// Start a scrim with a quick shortcut
	RegConsoleCmd("sm_scrim", Command_MatchModScrim);

	// Start a scrim with a quick shortcut
	RegConsoleCmd("sm_pug", Command_MatchModScrim);

	// Start a scrim with a quick shortcut
	RegConsoleCmd("sm_6v6", Command_MatchMod6v6);

	// Start a scrim with a quick shortcut
	RegConsoleCmd("sm_9v9", Command_MatchMod9v9);

	// Start a scrim with a quick shortcut
	RegConsoleCmd("sm_score", Command_MatchModScore);
	
	// Extend a Round
	RegConsoleCmd("sm_extend", Command_Extend);
	
	AutoExecConfig(true);
	
	new Handle:topmenu;
	if (LibraryExists("adminmenu") && ((topmenu = GetAdminTopMenu()) != INVALID_HANDLE)) {
		OnAdminMenuReady(topmenu);
	}
}

public OnAllPluginsLoaded() { 
	// If Auotupdate is there, use it
	if(LibraryExists("pluginautoupdate")) { 
		AutoUpdate_AddPlugin("matchmod.googlecode.com", "/svn/trunk/plugins.xml", PLUGIN_VERSION); 
	}
}

public OnLibraryRemoved(const String:name[]) {

	if (StrEqual(name, "adminmenu")) {
		hAdminMenu = INVALID_HANDLE;
	}
}

public OnPluginEnd() {
	if(LibraryExists("pluginautoupdate")) { 
		AutoUpdate_RemovePlugin(); 
	} 
}

public Action:OnGetGameDescription(String:gameDesc[64])
{
	// if it has no value, we are not overriding anything
	if (mm_state > 0)
	{
		Format(gameDesc, sizeof(gameDesc), "%s match in progress", mm_gamedesc);
		return Plugin_Changed;
	}
	
	return Plugin_Continue;
}

public OnMapStart() {
	ResetVariables();
}

public OnMapEnd() {
}

// Original Map detection was written by Berni.
public OnConfigsExecuted() {
	new iEnt = -1, String:mapname[32], String:league[8], bool:attackPoint = true;
	GetCurrentMap(mapname, sizeof(mapname));
	if (strncmp(mapname, "cp_", 3, false) == 0) {
		new iTeam;
		while ((iEnt = FindEntityByClassname(iEnt, "team_control_point")) != -1) {
			iTeam = GetEntProp(iEnt, Prop_Send, "m_iTeamNum");
			/**
			* If there is a blu CP or a neutral CP, then it's not an attack/defend map
			*
			**/
			if (iTeam != 2) {
				strcopy(mm_maptype, sizeof(mm_maptype), "push");
				adscoring = true;
				tcscoring = false;
				ctfscoring = false;
				attackPoint = false;
				break;
			}
		}
		if (attackPoint) {
			strcopy(mm_maptype, sizeof(mm_maptype), "stopwatch");
			adscoring = false;
			ctfscoring = false;
			tcscoring = false;
		}
	}
	else if (strncmp(mapname, "bball_", 6, false) == 0) {
		strcopy(mm_maptype, sizeof(mm_maptype), "ctf");
		adscoring = false;
		arenascoring = false;
		ctfscoring = true;
		tcscoring = false;
	}
	else if (strncmp(mapname, "ctf_", 4, false) == 0) {
		strcopy(mm_maptype, sizeof(mm_maptype), "ctf");
		adscoring = false;
		arenascoring = false;
		ctfscoring = true;
		tcscoring = false;
	}
	else if (strncmp(mapname, "koth_", 5, false) == 0) {
		strcopy(mm_maptype, sizeof(mm_maptype), "koth");
		adscoring = false;
		arenascoring = false;
		ctfscoring = false;
		tcscoring = false;
	}
	else if (strncmp(mapname, "pl_", 3, false) == 0) {
		strcopy(mm_maptype, sizeof(mm_maptype), "stopwatch");
		adscoring = true;
		arenascoring = false;
		ctfscoring = false;
		tcscoring = false;
	}
	else if (strncmp(mapname, "plr_", 4, false) == 0) {
		strcopy(mm_maptype, sizeof(mm_maptype), "plr");
		adscoring = false;
		arenascoring = false;
		ctfscoring = false;
		tcscoring = false;
	}
	else if (strncmp(mapname, "arena_", 6, false) == 0) {
		strcopy(mm_maptype, sizeof(mm_maptype), "arena");
		adscoring = false;
		arenascoring = true;
		ctfscoring = false;
		tcscoring = false;
	}
	else if (strncmp(mapname, "tc_", 3, false) == 0) {
		strcopy(mm_maptype, sizeof(mm_maptype), "tc");
		adscoring = false;
		arenascoring = false;
		ctfscoring = false;
		tcscoring = true;
	}
	else {
		strcopy(mm_maptype, sizeof(mm_maptype), "push");
		adscoring = false;
		ctfscoring = false;
	}
	GetConVarString(g_cvar_league, league, sizeof(league));

	new String:config[64];
	Format(config, sizeof(config), "matchmod/%s-%s", league, mm_maptype);

	ServerCommand("exec \"%s\"", config);

}

//----------------------------------------------------------------------------
//| Callbacks
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
//| Action:Listener_Pause(client, const String:command[], args)
//|
//| Used to allow tracking of pauses in the logs and display a visual command
//----------------------------------------------------------------------------
public Action:Listener_Pause(client, const String:command[], args)
{

	if(mm_state == 3 || mm_state == 5 || mm_state == 7)
	{
		isPaused = !isPaused;
	
		if (isPaused) {
			LogToGame("World triggered \"Game_Paused\"");
			ShowActivity2(client, "[MatchMod] ", "Paused the game");
			LogAction(client, -1, "\"%L\" has paused the game.", client);
		}
		else {
			LogToGame("World triggered \"Game_Unpaused\"");
			ShowActivity2(client, "[MatchMod] ", "Unpaused the game");
			LogAction(client, -1, "\"%L\" has unpaused the game.", client);
		}
	}
	
	return Plugin_Continue;
}

//----------------------------------------------------------------------------
//| Action:Command_Extend(client, args)
//|
//| Used to allow teams to quickly extend the time limit
//----------------------------------------------------------------------------
public Action:Command_Extend(client, args) {

	new String:arg[4];
	new origtime;
	new newtime;
	new extendtime;
	
	if (CheckCommandAccess(client, "sm_extend", ADMFLAG_RESERVATION, true)) {
		origtime = GetConVarInt(FindConVar("mp_timelimit"));
		GetCmdArg(1, arg, sizeof(arg));
		newtime = StringToInt(arg);
		extendtime = origtime + newtime;
		ServerCommand("mp_timelimit %i", extendtime);
		ShowActivity2(client, "[MatchMod] ", "Has extended the round");
		LogAction(client, -1, "\"%L\" has extended the round.", client);
	}
	else {
		ReplyToCommand(client, "[MatchMod] %t", "No Access");
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| Action:Command_Say(client, args)
//|
//| Used to detect a Lobby or Match
//----------------------------------------------------------------------------
public Action:Command_Say(client, args) {

	decl String:keyLobby[32];
	
	if (client == 0) {
		new String:lobbystuff[4][10];
		GetCmdArg(1, keyLobby, sizeof(keyLobby));
		ExplodeString(keyLobby, " ",lobbystuff,sizeof(lobbystuff),sizeof(lobbystuff[]));
		
		if (StrEqual(lobbystuff[0], "lobbyId", false)) {
			/* It's a Lobby */
			isLobby = true;
			strcopy(mm_lobbyid, sizeof(mm_lobbyid), lobbystuff[1]);
			mm_topscore = 99;
			mm_allowovertime = 0;
			mm_allowhalf = 0;
			Format(mm_gamedesc, sizeof(mm_gamedesc), "TF2Lobby.com");
			mm_recording = GetConVarInt(g_cvar_tvenable);
			ServerCommand("sm_matchmod_teamname red RED");
			ServerCommand("sm_matchmod_teamname blue BLU");
			readyenabled = false;
			GetConVarString(g_cvar_servercfgidle, mm_svrcfgidle, sizeof(mm_svrcfgidle));
			UnsetNotifyFlag(g_cvar_alltalk);
			UnsetNotifyFlag(FindConVar("mp_tournament"));
			UnsetNotifyFlag(FindConVar("mp_timelimit"));
			UnsetNotifyFlag(FindConVar("mp_winlimit"));
			UnsetNotifyFlag(FindConVar("mp_match_end_at_timelimit"));
			mm_state = 2;
		}
	}

	return Plugin_Continue;
}

//----------------------------------------------------------------------------
//| Action:Command_MatchModMatch(client, args)
//|
//| Quick shortcut to begin a match to a particular league rules
//----------------------------------------------------------------------------
public Action:Command_MatchModMatch(client, args) {

	if (CheckCommandAccess(client, "sm_match", ADMFLAG_RESERVATION, true)) {
		if (args < 2) {
			ReplyToCommand(client, "[MatchMod] Usage: sm_match <league> <password>");
			return Plugin_Handled;
		}		

		decl String:league[10];
		decl String:config[64];
		decl String:password[64];

		GetCmdArg(1, league, sizeof(league));		

		Format(config, sizeof(config), "cfg/matchmod/%s-%s.cfg", league, mm_maptype);

		if (!FileExists(config)) {
			ReplyToCommand(client, "[MatchMod] %t", "Match config not found");
			return Plugin_Handled;
		}
		else {
			ServerCommand("exec \"%s\"", config[4]);
			ReplyToCommand(client, "[MatchMod] %t", "Match config executed");
		}

		GetCmdArg(2, password, sizeof(password));
		ServerCommand("sv_password %s", password);

		ShowActivity2(client, "[MatchMod] ", "Began a match with %s rules", league);
		LogAction(client, -1, "\"%L\" has begun a match with %s rules.", client, league);
	
		CreateTimer(3.0, startSequence);
	}
	else {
		ReplyToCommand(client, "[MatchMod] %t", "No Access");
	}

	return Plugin_Handled;
}


//----------------------------------------------------------------------------
//| Action:Command_MatchModScrim(client, args)
//|
//| Quick shortcut to begin a scrim
//----------------------------------------------------------------------------
public Action:Command_MatchModScrim(client, args) {

	if (CheckCommandAccess(client, "sm_scrim", ADMFLAG_RESERVATION, true)) {
		if (args < 1) {
			ReplyToCommand(client, "[MatchMod] Usage: sm_scrim <password>");
			return Plugin_Handled;
		}		

		decl String:password[64];
		decl String:config[64];
		decl String:league[10];

		GetConVarString(g_cvar_league, league, sizeof(league));
		
		Format(config, sizeof(config), "cfg/matchmod/%s-%s.cfg", league, mm_maptype);

		if (!FileExists(config)) {
			ReplyToCommand(client, "[MatchMod] %t", "Match config not found");
			return Plugin_Handled;
		}
		else {
			ServerCommand("exec \"%s\"", config[4]);
			ReplyToCommand(client, "[MatchMod] %t", "Match config executed");
		}

		GetCmdArg(1, password, sizeof(password));
		ServerCommand("sv_password %s", password);

		ShowActivity2(client, "[MatchMod] ", "Began a scrim");
		LogAction(client, -1, "\"%L\" has begun a scrim.", client);
		
		CreateTimer(3.0, startSequence);			
	}
	else {
		ReplyToCommand(client, "[MatchMod] %t", "No Access");
	}

	return Plugin_Handled;
}


//----------------------------------------------------------------------------
//| Action:Command_MatchMod6v6(client, args)
//|
//| Quick shortcut to begin a scrim
//----------------------------------------------------------------------------
public Action:Command_MatchMod6v6(client, args) {

	if (CheckCommandAccess(client, "sm_6v6", ADMFLAG_RESERVATION, true)) {
		if (args < 1) {
			ReplyToCommand(client, "[MatchMod] Usage: sm_6v6 <password>");
			return Plugin_Handled;
		}		

		decl String:password[64];
		decl String:config[64];

		Format(config, sizeof(config), "cfg/matchmod/6v6-%s.cfg", mm_maptype);

		if (!FileExists(config)) {
			ReplyToCommand(client, "[MatchMod] %t", "Match config not found");
			return Plugin_Handled;
		}
		else {
			ServerCommand("exec \"%s\"", config[4]);
			ReplyToCommand(client, "[MatchMod] %t", "Match config executed");
		}

		GetCmdArg(1, password, sizeof(password));
		ServerCommand("sv_password %s", password);

		ShowActivity2(client, "[MatchMod] ", "Began a scrim");
		LogAction(client, -1, "\"%L\" has begun a scrim.", client);
		
		CreateTimer(3.0, startSequence);			
	}
	else {
		ReplyToCommand(client, "[MatchMod] %t", "No Access");
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| Action:Command_MatchMod9v9(client, args)
//|
//| Quick shortcut to begin a scrim
//----------------------------------------------------------------------------
public Action:Command_MatchMod9v9(client, args) {

	if (CheckCommandAccess(client, "sm_9v9", ADMFLAG_RESERVATION, true)) {
		if (args < 1) {
			ReplyToCommand(client, "[MatchMod] Usage: sm_9v9 <password>");
			return Plugin_Handled;
		}		

		decl String:password[64];
		decl String:config[64];

		Format(config, sizeof(config), "cfg/matchmod/9v9-%s.cfg", mm_maptype);

		if (!FileExists(config)) {
			ReplyToCommand(client, "[MatchMod] %t", "Match config not found");
			return Plugin_Handled;
		}
		else {
			ServerCommand("exec \"%s\"", config[4]);
			ReplyToCommand(client, "[MatchMod] %t", "Match config executed");
		}

		GetCmdArg(1, password, sizeof(password));
		ServerCommand("sv_password %s", password);

		ShowActivity2(client, "[MatchMod] ", "Began a scrim");
		LogAction(client, -1, "\"%L\" has begun a scrim.", client);
		
		CreateTimer(3.0, startSequence);			
	}
	else {
		ReplyToCommand(client, "[MatchMod] %t", "No Access");
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| Action:Command_MatchModScore(client, args)
//|
//| Quick shortcut to begin a scrim
//----------------------------------------------------------------------------
public Action:Command_MatchModScore(client, args) {
	new String:playbyplay[128];
	
	if (mm_tmascore == mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score tied", LANG_SERVER, mm_tmascore, mm_tmbscore);
	}
	else if (mm_tmascore > mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score lead", LANG_SERVER, mm_tmaname, mm_tmascore, mm_tmbscore);
	}
	else if (mm_tmascore < mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score lead", LANG_SERVER, mm_tmbname, mm_tmbscore, mm_tmascore);
	}

	ReplyToCommand(client, playbyplay);
	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| Action:startSequence(Handle:timer)
//|
//| Timer used to ensure configs fired before sequence begins
//----------------------------------------------------------------------------
public Action:startSequence(Handle:timer) {
	mm_state++;
	AdvanceMatchState();
}

//----------------------------------------------------------------------------
//| Action:endSequence(Handle:timer)
//|
//| Timer used to delay STV a bit at match end instead of a hard stop
//----------------------------------------------------------------------------
public Action:endSequence(Handle:timer) {
	StopRecording();
}


//----------------------------------------------------------------------------
//| Action:Command_MatchModVersion(client, args)
//|
//| Displays current version of mod to client
//----------------------------------------------------------------------------
public Action:Command_MatchModVersion(client, args) {

	if (CheckCommandAccess(client, "sm_extend", ADMFLAG_RESERVATION, true)) {
		ReplyToCommand(client, "[MatchMod] %t", "Version", PLUGIN_VERSION);
	}
	else {
		ReplyToCommand(client, "[MatchMod] %t", "No Access");
	}

	return Plugin_Handled;
}



//----------------------------------------------------------------------------
//| Action:Command_MatchModTeamname(client, args)
//|
//| Allows players to rename their team until beginning of 1st half
//----------------------------------------------------------------------------
public Action:Command_MatchModTeamname(client, args) {
	if (args < 1) {
		ReplyToCommand(client, "[MatchMod] Usage: sm_teamname \"<name>\"");
		return Plugin_Handled;
	}

	if (mm_state < 3) {
		decl String:assignteamname[32];

		new team = GetClientTeam(client) - TEAM_OFFSET;

		GetCmdArg(1, assignteamname, sizeof(assignteamname));

		if (team == BLU) {
			strcopy(mm_tmbname, sizeof(mm_tmbname), assignteamname);
			SetConVarString(FindConVar("matchmod_blueteamname"), assignteamname);
			SetConVarString(FindConVar("mp_tournament_blueteamname"), assignteamname);
			ReplyToCommand(client, "[MatchMod] %t", "Blue name assigned", assignteamname);
			ShowActivity2(client, "[MatchMod] ", "Has named the Blue team %s", assignteamname);
			LogAction(client, -1, "\"%L\" has named the blue team %s.", client, assignteamname);
		}
		else if (team == RED) {
			strcopy(mm_tmaname, sizeof(mm_tmaname), assignteamname);
			SetConVarString(FindConVar("matchmod_redteamname"), assignteamname);
			SetConVarString(FindConVar("mp_tournament_redteamname"), assignteamname);
			ReplyToCommand(client, "[MatchMod] %t", "Red name assigned", assignteamname);
			ShowActivity2(client, "[MatchMod] ", "Has named the Red team %s", assignteamname);
			LogAction(client, -1, "\"%L\" has named the red team %s.", client, assignteamname);
		}

		ServerName();
	}
	else {
		ReplyToCommand(client, "[MatchMod] %t", "Cannot name");
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| Action:Command_MatchModTeam(client, args)
//|
//| Allows admin to rename either team until beginning of 1st half
//----------------------------------------------------------------------------
public Action:Command_MatchModTeam(client, args) {
	if (args < 2) {
		ReplyToCommand(client, "[MatchMod] Usage: sm_matchmod_teamname <team> \"<name>\"");
		return Plugin_Handled;
	}
	if (CheckCommandAccess(client, "sm_matchmod_teamname", ADMFLAG_RESERVATION, true)) {
		if (mm_state < 3) {
			decl String:assignteamname[32];
			decl String:assignteam[4];

			GetCmdArg(1, assignteam, sizeof(assignteam));
			GetCmdArg(2, assignteamname, sizeof(assignteamname));

			if (StrEqual(assignteam, "red", false) && StrEqual(assignteam, "blu", false)) {
				ReplyToCommand(client, "[MatchMod] %t", "Invalid Team");
				return Plugin_Handled;
			}

			if (StrEqual(assignteam, "red", false)) {
				strcopy(mm_tmaname, sizeof(mm_tmaname), assignteamname);
				SetConVarString(FindConVar("matchmod_redteamname"), assignteamname);
				SetConVarString(FindConVar("mp_tournament_redteamname"), assignteamname);
				ReplyToCommand(client, "[MatchMod] %t", "Red name assigned", assignteamname);
				ShowActivity2(client, "[MatchMod] ", "Assigned Red team name to %s", assignteamname);
				LogAction(client, -1, "\"%L\" has assigned the Red team name to %s.", client, assignteamname);
			}
			else if (StrEqual(assignteam, "blu", false)) {
				strcopy(mm_tmbname, sizeof(mm_tmbname), assignteamname);
				SetConVarString(FindConVar("matchmod_blueteamname"), assignteamname);
				SetConVarString(FindConVar("mp_tournament_blueteamname"), assignteamname);
				ReplyToCommand(client, "[MatchMod] %t", "Blue name assigned", assignteamname);
				ShowActivity2(client, "[MatchMod] ", "Assigned Blue team name to %s", assignteamname);
				LogAction(client, -1, "\"%L\" has assigned the Blue team name to %s.", client, assignteamname);
			}

			ServerName();
			return Plugin_Handled;
		}
	}

	return Plugin_Handled;
}


public PreMatch(Handle:event, const String:name[], bool:dontBroadcast) {
	if (mm_state == 0) {
		return;
	}
	
	ExecPreMatch();
	return;
}

//----------------------------------------------------------------------------
//| GameWinPanel(Handle:event, const String:name[], bool:dontBroadcast)
//|
//| Using the Win panel to determine scores for Checkpoint, stopwatch
//| and Payload gametypes
//----------------------------------------------------------------------------
public GameWinPanel(Handle:event, const String:name[], bool:dontBroadcast) {
	if (mm_state == 0) {
		return;
	}

	if (mm_state == 3 || mm_state == 5 || mm_state == 7) {
	
		new roundcomplete = GetEventInt(event, "round_complete");

		if (!adscoring && !ctfscoring && !arenascoring && !tcscoring) {
			new winreason = GetEventInt(event, "winreason");    //Reason: 1=CP 3=Flag 4=defended 5=Stalemate/Death like below.
			new wteam = GetEventInt(event, "winning_team") - TEAM_OFFSET;

			if (winreason == 1) {
				if (wteam == 1) {
					mm_tmbscore++;
				}
				else if (wteam == 0) {
					mm_tmascore++;
				}
			}

			if (mm_tmascore == mm_topscore || mm_tmbscore == mm_topscore) {
				EndMatch();
			}
			// Reset the variable to junk just in case
			wteam = 3;
			return;
		}
		else if (arenascoring) {
			new wteam = GetEventInt(event, "winning_team") - TEAM_OFFSET;

			if (wteam == 1) {
				mm_tmbscore++;
			}
			else if (wteam == 0) {
				mm_tmascore++;
			}

			if (mm_tmascore == mm_topscore || mm_tmbscore == mm_topscore) {
				EndMatch();
			}
			// Reset the variable to junk just in case
			wteam = 3;
			return;
		}
		else if (adscoring && roundcomplete) {	
			mm_roundcount++;
			if (mm_roundcount == 2) {
				SwapTeams(true);
				return;
			}

			// Round Count over two we can assume its over and actually grab the score
			if (mm_roundcount > 2) {
				new wteam = GetEventInt(event, "winning_team") - TEAM_OFFSET;

				if (wteam == 1) {
					mm_tmbscore++;
				}
				else if (wteam == 0) {
					mm_tmascore++;
				}

				// Reset the variable to junk just in case
				wteam = 3;
				return;
			}
		}
		else if (tcscoring && roundcomplete) {	

			new wteam = GetEventInt(event, "winning_team") - TEAM_OFFSET;

			if (wteam == 1) {
				mm_tmbscore++;
			}
			else if (wteam == 0) {
				mm_tmascore++;
			}

			// Reset the variable to junk just in case
			wteam = 3;
			return;
		}
	}
}


//----------------------------------------------------------------------------
//| PlayerHealed(Handle:event, const String:name[], bool:dontBroadcast)
//|
//| Allows us to add player specific healing to the server logs for parsers
//| Credit: Thanks Cinq
//----------------------------------------------------------------------------
public PlayerHealed(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(mm_state == 3 || mm_state == 5 || mm_state == 7)
    {
		decl String:patientName[32];
		decl String:healerName[32];
		decl String:patientSteamId[64];
		decl String:healerSteamId[64];
		decl String:patientTeam[64];
		decl String:healerTeam[64];		// Silly medic healing a spy

		new patientId = GetEventInt(event, "patient");
		new healerId = GetEventInt(event, "healer");
		new patient = GetClientOfUserId(patientId);
		new healer = GetClientOfUserId(healerId);
		new amount = GetEventInt(event, "amount");

		GetClientAuthString(patient, patientSteamId, sizeof(patientSteamId));
		GetClientName(patient, patientName, sizeof(patientName));
		GetClientAuthString(healer, healerSteamId, sizeof(healerSteamId));
		GetClientName(healer, healerName, sizeof(healerName));
		new teamindex = GetClientTeam(patient);
		if(teamindex == 2)
		{
			patientTeam = "Red";
		}
		else if(teamindex == 3)
		{
			patientTeam = "Blue";
		}
		else
		{
			patientTeam = "undefined";
		}
		new teamindex2 = GetClientTeam(healer);
		if(teamindex2 == 2)
		{
			healerTeam = "Red";
		}
		else if(teamindex2 == 3)
		{
			healerTeam = "Blue";
		}
		else
		{
			healerTeam = "undefined";
		}
		LogToGame("\"%s<%d><%s><%s>\" triggered \"healed\" against \"%s<%d><%s><%s>\" (healing \"%d\")",
			healerName,
			healerId,
			healerSteamId,
			healerTeam,
			patientName,
			patientId,
			patientSteamId,
			patientTeam,
			amount);
	}
}

//----------------------------------------------------------------------------
//| PlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
//|
//| Allows us to add player class info to the server logs for parsers
//| Credit: Thanks Cinq
//----------------------------------------------------------------------------
public PlayerSpawned(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(mm_state == 3 || mm_state == 5 || mm_state == 7)
    {
		decl String:clientname[32];
		decl String:steamid[64];
		decl String:team[64];
		new String:classes[10][64] = {
				"undefined",
				"scout",
				"sniper",
				"soldier",
				"demoman",
				"medic",
				"heavyweapons",
				"pyro",
				"spy",
				"engineer"
		};

		new user = GetClientOfUserId(GetEventInt(event, "userid"));
		new clss = GetEventInt(event, "class");
		GetClientAuthString(user, steamid, sizeof(steamid));
		GetClientName(user, clientname, sizeof(clientname));
		new teamindex = GetClientTeam(user);
		if(teamindex == 2)
		{
			team = "Red";
		}
		else if(teamindex == 3)
		{
			team = "Blue";
		}
		else
		{
			team = "undefined";
		}
		LogToGame("\"%s<%d><%s><%s>\" spawned as \"%s\"",
			clientname,
			user,
			steamid,
			team,
			classes[clss]);	
	}
}

//----------------------------------------------------------------------------
//| PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
//|
//| Allows us to add damage output to the server logs for parsers
//| Credit: Thanks Cinq
//----------------------------------------------------------------------------
public PlayerHurt(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(mm_state == 3 || mm_state == 5 || mm_state == 7)
    {
        decl String:clientname[32];
        decl String:steamid[64];
        decl String:team[64];

        new userid = GetClientOfUserId(GetEventInt(event, "userid"));
        new attackerid = GetEventInt(event, "attacker");
        new attacker = GetClientOfUserId(attackerid);
        new damage = GetEventInt(event, "damageamount");
        if(userid != attacker && attacker != 0)
        {
            GetClientAuthString(attacker, steamid, sizeof(steamid));
            GetClientName(attacker, clientname, sizeof(clientname));
            new teamindex = GetClientTeam(attacker);
            if(teamindex == 2)
            {
                team = "Red";
            }
            else if(teamindex == 3)
            {
                team = "Blue";
            }
            else
            {
                team = "undefined";
            }
            LogToGame("\"%s<%d><%s><%s>\" triggered \"damage\" %d",
                clientname,
                attackerid,
                steamid,
                team,
                damage);
        }
    }
}

//----------------------------------------------------------------------------
//| ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
//|
//| Allows us to add item pickups to the server logs for parsers
//| Credit: Thanks Annuit<sp?>
//----------------------------------------------------------------------------
public ItemPickup(Handle:event, const String:name[], bool:dontBroadcast)
{
    if(mm_state == 3 || mm_state == 5 || mm_state == 7)
    {
		decl String:playerName[32];
		decl String:playerSteamId[64];
		decl String:playerTeam[64];
		decl String:item[64];

		new playerId = GetEventInt(event, "userid");
		new player = GetClientOfUserId(playerId);
		GetClientAuthString(player, playerSteamId, sizeof(playerSteamId));
		GetClientName(player, playerName, sizeof(playerName));
		new teamindex = GetClientTeam(player);
		if(teamindex == 2)
		{
			playerTeam = "Red";
		}
		else if(teamindex == 3)
		{
			playerTeam = "Blue";
		}
		else
		{
			playerTeam = "undefined";
		}
		GetEventString(event, "item", item, sizeof(item));

		LogToGame("\"%s<%d><%s><%s>\" picked up item \"%s\"",
			playerName,
			playerId,
			playerSteamId,
			playerTeam,
			item);
	}
}

//----------------------------------------------------------------------------
//| FlagCapturedEvent(Handle:event, const String:name[], bool:dontBroadcast)
//|
//| Tracks when the flag is captured and adds the appriopriate score
//----------------------------------------------------------------------------
public FlagCapturedEvent(Handle:event, const String:name[], bool:dontBroadcast) {
	if (mm_state == 0) {
		return;
	}

	new wteam = GetEventInt(event, "capping_team") - TEAM_OFFSET;

	if (wteam == 1) {
		mm_tmbscore++;
	}
	if (wteam == 0) {
		mm_tmascore++;
	}

	ScorePrivate();
	
	if (mm_tmascore == mm_topscore || mm_tmbscore == mm_topscore) {
		EndMatch();
	}

	// Reset the variable to junk just in case
	wteam = 3;
	return;
}

//----------------------------------------------------------------------------
//| GameRestartEvent(Handle:event, const Stringname[], bool:dontBroadcast)
//|
//| Handles the beginning of a match and moves into the next phase
//| to trigger logging/recording/alltalk events
//----------------------------------------------------------------------------
public GameRestartEvent(Handle:event, const String:name[], bool:dontBroadcast) {
	if (mm_state > 0) {
		AdvanceMatchState();
	}
}

//----------------------------------------------------------------------------
//| GameOverEvent(Handle:event, const Stringname[], bool:dontBroadcast)
//|
//| End of a round for whatever reason
//----------------------------------------------------------------------------
public GameOverEvent(Handle:event, const String:name[], bool:dontBroadcast) {
	if (mm_state > 0) {
		AdvanceMatchState();
	}
}


//----------------------------------------------------------------------------
//| OnClientDisconnect(client)
//|
//| When a client disconnects, force set is ready status to false
//----------------------------------------------------------------------------
public OnClientDisconnect(client) {
	if (readyup) {
		readyStatus[client] = false;
		checkStatus();
	}
}

//----------------------------------------------------------------------------
//| Action:TournamentRestartHook(args)
//|
//| Beginning of Round
//----------------------------------------------------------------------------
public Action:TournamentRestartHook(args) {
	if (mm_state > 2) {
		mm_state = 7;
		AdvanceMatchState();
	}
	return Plugin_Continue;
}

//----------------------------------------------------------------------------
//| Action:Command_MatchModEnd(client, args)
//|
//| Ends the match sequence
//----------------------------------------------------------------------------
public Action:Command_MatchModEnd(client, args) {
	if (mm_state > 0) {
		if (CheckCommandAccess(client, "sm_matchmod_end", ADMFLAG_RESERVATION, true)) {
			ShowActivity2(client, "[MatchMod] ", "Ending match sequence");
			LogAction(client, -1, "\"%L\" has ended the match sequence", client);
			mm_state = 7;
			AdvanceMatchState();
		}
	}
	return Plugin_Handled;
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
ResetVariables() {
	// Reset all variables to default
	mm_tmascore = 0;
	mm_tmbscore = 0;
	mm_tmpscore = 0;
	mm_state = 0;
	mm_roundcount = 0;
	mm_recording = 0;
	recording = false;
	adscoring = false;
	ctfscoring = false;
	arenascoring = false;
	tcscoring = false;
	readyup = false;
	readyenabled = false;
	redforce = false;
	redallowforce = false;
	redready = false;
	bluforce = false;
	bluallowforce = false;
	bluready = false;
	readystart = false;
	isLobby = false;
	isPaused = false;
	SetNotifyFlag(g_cvar_alltalk);
	SetNotifyFlag(FindConVar("mp_tournament"));
	SetNotifyFlag(FindConVar("mp_timelimit"));
	SetNotifyFlag(FindConVar("mp_winlimit"));
	SetNotifyFlag(FindConVar("mp_match_end_at_timelimit"));
}

//----------------------------------------------------------------------------
//| StartRecording() - based from matchrecorder plugin
//|
//| Formats name of recording and starts recording
//----------------------------------------------------------------------------
StartRecording() {
	if (mm_recording) {
		if (recording) {
			PrintToChatAll("\x04[MatchMod]\x01 %T", "Already recording", LANG_SERVER);
			return;
		}

		// Format the demo filename
		new String:timestamp[64];
		new String:map[16];
		new String:filename[128];
		new String:command[128];
		new String:folder[48];
		new String:path[128];
		new String:league[16];
		
		GetConVarString(g_cvar_description, league, sizeof(league));
		GetConVarString(g_cvar_stvfolder, folder, sizeof(folder));
		
		if (!DirExists(folder)) {
			CreateDirectory(folder, 511);
		}
		
		if (isLobby) {
			GetCurrentMap(map, 16);
			Format(command, sizeof(command), "tv_record Lobby-%s_%s_%s_%s", mm_lobbyid, map, mm_tmaname, mm_tmbname);
			Format(path, sizeof(path), "%s/", folder);
			if (strlen(path) < 2) {
				Format(command, sizeof(command), "tv_record Lobby-%s_%s_%s_%s", mm_lobbyid, map, mm_tmaname, mm_tmbname);
			}
			else {
				Format(command, sizeof(command), "tv_record %sLobby-%s_%s_%s_%s", path, mm_lobbyid, map, mm_tmaname, mm_tmbname);
			}
		}
		else {
			FormatTime(timestamp, 64, "%m-%d-%Hh%Mm");
			GetCurrentMap(map, 16);
			Format(filename, sizeof(filename), "%s-%s_%s_%s_%s", league, timestamp, map, mm_tmaname, mm_tmbname);
			ReplaceString(filename, sizeof(filename), " ", "-");
			Format(path, sizeof(path), "%s/", folder);
			if (strlen(path) < 2) {
				Format(command, sizeof(command), "tv_record %s", filename);
			}
			else {
				Format(command, sizeof(command), "tv_record %s%s", path, filename);
			}
		}
		// Start recording
		PrintToChatAll("\x04[MatchMod]\x01 %T", "Recording start", LANG_SERVER);
		ServerCommand(command);

		recording = true;
	}
}

//----------------------------------------------------------------------------
//| StopRecording() - from matchrecorder plugin
//|
//| Stops recording
//----------------------------------------------------------------------------
StopRecording() {
	// Stop recording
	if (recording) {
		ServerCommand("tv_stoprecord");
		recording = false;
		PrintToChatAll("\x04[MatchMod]\x01 %T", "Recording stop", LANG_SERVER);
	}
}

//----------------------------------------------------------------------------
//| DisableLogging()
//|
//| Closes the server log
//----------------------------------------------------------------------------
DisableAlltalk() {
	// PrintToChatAll("\x04[MatchMod]\x01 %T", "Disable log", LANG_SERVER);
	SetConVarInt(FindConVar("sv_alltalk"), 0);
}

//----------------------------------------------------------------------------
//| EnableLogging()
//|
//| Opens the server log
//----------------------------------------------------------------------------
EnableAlltalk() {
	// PrintToChatAll("\x04[MatchMod]\x01 %T", "Enable log", LANG_SERVER);
	SetConVarInt(FindConVar("sv_alltalk"), 1);
}

//----------------------------------------------------------------------------
//| DisableLogging()
//|
//| Closes the server log
//----------------------------------------------------------------------------
DisableLogging() {
	// PrintToChatAll("\x04[MatchMod]\x01 %T", "Disable log", LANG_SERVER);
	ServerCommand("log off");
}

//----------------------------------------------------------------------------
//| EnableLogging()
//|
//| Opens the server log
//----------------------------------------------------------------------------
EnableLogging() {
	// PrintToChatAll("\x04[MatchMod]\x01 %T", "Enable log", LANG_SERVER);
	ServerCommand("log on");
}

//----------------------------------------------------------------------------
//| UnsetNotifyFlag(Handle:hndl)
//|
//| Removes the FCVAR_NOTIFY flag from a given handle
//----------------------------------------------------------------------------
UnsetNotifyFlag(Handle:hndl) {
	new flags = GetConVarFlags(hndl);
	flags &= ~FCVAR_NOTIFY;
	SetConVarFlags(hndl, flags);
}

//----------------------------------------------------------------------------
//| SetNotifyFlag(Handle:hndl)
//|
//| Adds the FCVAR_NOTIFY flag to a given handle
//----------------------------------------------------------------------------
SetNotifyFlag(Handle:hndl) {
	new flags = GetConVarFlags(hndl);
	flags |= FCVAR_NOTIFY;
	SetConVarFlags(hndl, flags);
}


//----------------------------------------------------------------------------
//| SwapTeams(bool:nameonly)
//|
//| Switches all the variables/cvars of the two teams
//----------------------------------------------------------------------------
SwapTeams(bool:nameonly) {
	PrintToChatAll("\x04[MatchMod]\x01 %T", "Swap teams", LANG_SERVER);

	// Swaps the scores for tracking
	mm_tmpscore = mm_tmascore;
	mm_tmascore = mm_tmbscore;
	mm_tmbscore = mm_tmpscore;
	mm_tmpscore = 0;

	// Swap ready up rules
	mm_mintmp = mm_minred;
	mm_minred = mm_minblu;
	mm_minblu = mm_mintmp;
	mm_mintmp = 0;

	mm_reqtmp = mm_reqred;
	mm_reqred = mm_reqblu;
	mm_reqblu = mm_reqtmp;
	mm_reqtmp = 0;


	// Swap team names for Play by play
	strcopy(mm_tmpname, sizeof(mm_tmpname), mm_tmaname);
	strcopy(mm_tmaname, sizeof(mm_tmaname), mm_tmbname);
	strcopy(mm_tmbname, sizeof(mm_tmbname), mm_tmpname);

	if (!nameonly) {
		for (new client=1; client <= MaxClients; client++) {
			if (IsClientInGame(client) && (GetClientTeam(client) == 2)) {
				ChangeClientTeam(client, 1);
				ChangeClientTeam(client, 3);
			}
			else if (IsClientInGame(client) && (GetClientTeam(client) == 3)) {
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
//| set internal variables accordingly
//----------------------------------------------------------------------------
InitializeVariables() {
	decl String:teamname[16];

	g_cvar_maxpoints = FindConVar("matchmod_maxpoints");
	mm_topscore = GetConVarInt(g_cvar_maxpoints);

	g_cvar_allowovertime = FindConVar("matchmod_allowovertime");
	mm_allowovertime = GetConVarInt(g_cvar_allowovertime);

	g_cvar_allowhalf = FindConVar("matchmod_allowhalf");
	mm_allowhalf = GetConVarInt(g_cvar_allowhalf);

	mm_recording = GetConVarInt(g_cvar_tvenable);
	mm_bonustime = GetConVarFloat(FindConVar("mp_bonusroundtime"));
	
	GetConVarString(g_cvar_description, mm_gamedesc, sizeof(mm_gamedesc));	
	GetConVarString(g_cvar_servercfg, mm_svrcfg, sizeof(mm_svrcfg));
	GetConVarString(g_cvar_servercfgot, mm_svrcfgot, sizeof(mm_svrcfgot));
	GetConVarString(g_cvar_servercfgidle, mm_svrcfgidle, sizeof(mm_svrcfgidle));

	GetConVarString(g_cvar_bluteamname, teamname, sizeof(teamname));
	SetConVarString(FindConVar("mp_tournament_blueteamname"), teamname);
	strcopy(mm_tmbname, sizeof(mm_tmbname), teamname);
	GetConVarString(g_cvar_redteamname, teamname, sizeof(teamname));
	SetConVarString(FindConVar("mp_tournament_redteamname"), teamname);
	strcopy(mm_tmaname, sizeof(mm_tmaname), teamname);

	readyenabled = GetConVarBool(g_cvar_readyenable);
	mm_minred = GetConVarInt(g_cvar_minred);
	mm_reqred = GetConVarInt(g_cvar_reqred);
	mm_minblu = GetConVarInt(g_cvar_minblu);
	mm_reqblu = GetConVarInt(g_cvar_reqblu);

	// Remove the notify flag on a few commands
	UnsetNotifyFlag(g_cvar_alltalk);
	UnsetNotifyFlag(FindConVar("mp_tournament"));
	UnsetNotifyFlag(FindConVar("mp_timelimit"));
	UnsetNotifyFlag(FindConVar("mp_winlimit"));
	UnsetNotifyFlag(FindConVar("mp_match_end_at_timelimit"));

}

//----------------------------------------------------------------------------
//| EndMatch()
//|
//| Allows the plugin to stop a match prematurely when the
//| scorelimit is reached
//----------------------------------------------------------------------------
EndMatch() {
	ServerCommand("mp_tournament_restart");
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

	if (mm_state == 0) {
		return;
	}

	// Pre-game
	else if (mm_state == 1) {
		PrintToChatAll("\x04[MatchMod]\x01 %T", "Begin pregame", LANG_SERVER);
		InitializeVariables();
		ExecRegulation();
		ServerName();
		if (readyenabled) {
			StartReady();
		}

		// Advance mm_state so match progresses next run
		mm_state++;

		return;
	}

	// 1st Half
	else if (mm_state == 2) {
		if (readyenabled) {
			EndReady();
		}
		PrintToChatAll("\x04[MatchMod]\x01 %T", "Begin first half", LANG_SERVER);
		SetScoreboardNames();
		DisableAlltalk();
		EnableLogging();
		StartRecording();
		mm_roundcount = 1;
		
		PrintCenterTextAll("%T", "Match live", LANG_SERVER);

		// Advance mm_state so match progresses next run
		if (mm_allowhalf == 1) {
			mm_state++;
		}
		else {
			if (mm_allowovertime == 1) {
				mm_state = 5;
			}
			else {
				mm_state = 7;
			}
		}
		ServerName();

		return;
	}

	// Half-Time
	else if (mm_state == 3) {
		PrintToChatAll("\x04[MatchMod]\x01 %T", "End first half", LANG_SERVER);
		PrintCenterTextAll("%T", "Half time", LANG_SERVER);
		ScoreIntermission();
		EnableAlltalk();
		
		// Swap teams
		SwapTeams(false);

		// Kickoff Readyup
		if (readyenabled) {
			StartReady();
		}

		// Advance mm_state so match progresses next run
		mm_state++;

		ServerName();

		return;
	}

	// Second Half
	else if (mm_state == 4) {
		if (readyenabled) {
			EndReady();
		}
		PrintToChatAll("\x04[MatchMod]\x01 %T", "Begin second half", LANG_SERVER);
		SetScoreboardNames();
		if (adscoring) {
			SwapTeams(true);
		}
		if (!adscoring && !ctfscoring) {
			// Match should ONLY end if actual score limit hit, or timelimit, not interim setting of cfg
			SetConVarInt(FindConVar("mp_winlimit"), 0);
		}
		DisableAlltalk();
		mm_roundcount = 1;

		PrintCenterTextAll("%T", "Match live", LANG_SERVER);

		// Advance mm_state so match progresses next run
		mm_state++;
		ServerName();

		return;
	}

	// Post-Game
	else if (mm_state == 5) {
		EnableAlltalk();

		if (mm_tmascore == mm_tmbscore && mm_allowovertime == 1) {
			EnableAlltalk();
			PrintToChatAll("\x04[MatchMod]\x01 %T", "End regulation", LANG_SERVER);
			PrintToChatAll("\x04[MatchMod]\x01 %T", "Teams tied", LANG_SERVER);
			PrintCenterTextAll("%T", "Prepare overtime", LANG_SERVER);

			// Swap teams
			SwapTeams(false);

			// Set Overtime rules
			ExecOvertime();

			if (readyenabled) {
				StartReady();
			}

			// Advance mm_state so match progresses next run
			mm_state++;
			ServerName();
		}
		else {
			PrintToChatAll("\x04[MatchMod]\x01 %T", "End Game", LANG_SERVER);
			DisableLogging();
			CreateTimer(mm_bonustime, endSequence);
			EnableAlltalk();
			ExecIdle();
			FinalScore();
			ResetVariables();
			if (readyenabled) {
				EndReady();
			}
			ServerName();
		}

		return;
	}

	// Overtime
	else if (mm_state == 6) {
		if (readyup) {
			EndReady();
		}
		PrintToChatAll("\x04[MatchMod]\x01 %T", "Begin overtime", LANG_SERVER);
		SetScoreboardNames();
		if (adscoring) {
			SwapTeams(true);
		}
		DisableAlltalk();
		mm_roundcount = 1;

		PrintCenterTextAll("%T", "Match live", LANG_SERVER);

		// Advance mm_state so match progresses next run
		mm_state++;

		ServerName();

		return;
	}

	// Final
	else if (mm_state == 7) {
		DisableLogging();
		CreateTimer(mm_bonustime, endSequence);
		EnableAlltalk();
		ExecIdle();
		FinalScore();
		ResetVariables();
		if (readyenabled) {
			EndReady();
		}
		ServerName();
		ExecPostMatch();

		return;
	}
}

/* 
---------------------------------------------------------------------------------------------------------
Server Name Functions

The following functions handle the dynamic server naming
---------------------------------------------------------------------------------------------------------
*/


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

	if (mm_state == 0) {
		Format(hostname, 64, "%s %s", mm_hnpfx, mm_hnsfx);
	}
	else if (mm_state == 2 || mm_state == 1) {
		Format(hostname, 64, "%T", "Server pregame", LANG_SERVER, mm_hnpfx, mm_tmaname, mm_tmbname);
	}
	else {
		if (mm_tmascore == mm_tmbscore) {
			Format(hostname, 64, "%T", "Server tied", LANG_SERVER, mm_hnpfx);
		}
		else if (mm_tmascore > mm_tmbscore) {
			Format(hostname, 64, "%T", "Server leads", LANG_SERVER, mm_hnpfx, mm_tmaname, mm_tmascore, mm_tmbscore);
		}
		else if (mm_tmascore < mm_tmbscore) {
			Format(hostname, 64, "%T", "Server leads", LANG_SERVER, mm_hnpfx, mm_tmbname, mm_tmbscore, mm_tmascore);
		}
	}
	SetConVarString(FindConVar("hostname"), hostname);
}



/* 
---------------------------------------------------------------------------------------------------------
Ready Up

The following functions handle the enhanced ready up features of MatchMod
---------------------------------------------------------------------------------------------------------
*/


//----------------------------------------------------------------------------
//| Action:OnClientCommand(client, args)
//|
//| Used to block certain client commands for the ready up phase
//----------------------------------------------------------------------------
public Action:OnClientCommand(client, args) {
	new String:cmd[30];
	GetCmdArg(0, cmd, sizeof(cmd));
 
	if (StrEqual(cmd, "tournament_teamname") && readyup) {
		/* Disable UI from changing teamnames */
		new String:name[30];
		GetCmdArg(1, name, sizeof(name));
		new team = GetClientTeam(client) - TEAM_OFFSET;

		if (team == RED) {
			ServerCommand("sm_matchmod_teamname red %s", name);
		}
		else if (team == BLU) {
			ServerCommand("sm_matchmod_teamname blue %s", name);
		}
		return Plugin_Handled;
	}
	else if (StrEqual(cmd, "tournament_readystate") && readyup) {
		/* Disable the UI from readying up the teams */
		return Plugin_Handled;
	}

	/* If we didn't specify it above, carry on */ 
	return Plugin_Continue;
}

//----------------------------------------------------------------------------
//| Action:Command_MatchModForceStart(client, args)
//|
//| Allows a team to start match shorthanded
//----------------------------------------------------------------------------
public Action:Command_MatchModForceStart(client, args) {
	if (readyup) {

		new team = GetClientTeam(client) - TEAM_OFFSET;

		if (team == RED && redallowforce) {
			redforce = true;
			ReplyToCommand(client, "[MatchMod] %t", "Force ready red");
		}
		else if (team == BLU && bluallowforce) {
			bluforce = true;
			ReplyToCommand(client, "[MatchMod] %t", "Force ready blue");
		}
		checkStatus();
	}
	else {
		ReplyToCommand(client, "[MatchMod] %t", "Force ready no");
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| Action:Command_MatchModReadyStatus(client, args)
//|
//| Displays Panel of status of all players to player that called it
//----------------------------------------------------------------------------
public Action:Command_MatchModReadyStatus(client, args) {
	if (readyup) {
		DrawPanel(client);
	}

	return Plugin_Handled;
}


//----------------------------------------------------------------------------
//| Action:Command_MatchModReady(client, args)
//|
//| Sets the player to a ready state
//----------------------------------------------------------------------------
public Action:Command_MatchModReady(client, args) {
	if (readyup) {
		new String:name[MAX_NAME_LENGTH];

		if (readyStatus[client]) {
			ReplyToCommand(client, "[MatchMod] %t", "Ready already");
		}
		else {
			readyStatus[client] = true;
			ReplyToCommand(client, "[MatchMod] %t", "Ready now");
			GetClientName(client, name, sizeof(name));
			PrintToChatAll("\x04[MatchMod]\x01 %T", "Ready up", LANG_SERVER, name);
		}
	
		checkStatus();

		return Plugin_Handled;
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| Action:Command_MatchModNotReady(client, args)
//|
//| Sets the player to a not ready state
//----------------------------------------------------------------------------
public Action:Command_MatchModNotReady(client, args) {
	if (readyup) {
		new String:name[MAX_NAME_LENGTH];

		if (!readyStatus[client]) {
			ReplyToCommand(client, "[MatchMod] %t", "Ready not already");
		}
		else {
			readyStatus[client] = false;
			ReplyToCommand(client, "[MatchMod] %t", "Ready not now");
			GetClientName(client, name, sizeof(name));
			PrintToChatAll("\x04[MatchMod]\x01 %T", "Ready down", LANG_SERVER, name);
		}

		checkStatus();

		return Plugin_Handled;
	}

	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| Action:startRound(Handle:timer)
//|
//| Start the round after sucessful readyup
//----------------------------------------------------------------------------
public Action:startRound(Handle:timer) {
	ServerCommand("mp_restartgame 5");
}

//----------------------------------------------------------------------------
//| ReadyPanelHandler(Handle:menu, ManuAction:action, param1, param2)
//|
//| Required handler for Panel
//----------------------------------------------------------------------------
public ReadyPanelHandler(Handle:menu, MenuAction:action, param1, param2) {
}

//----------------------------------------------------------------------------
//| Action:DrawPanel(client)
//|
//| Draws a panel displaying who is ready and who is not
//----------------------------------------------------------------------------
public Action:DrawPanel(client) {
	if (!readyup) return Plugin_Handled;
		
	new numPlayers = 0;
	new numPlayers2 = 0;

	new i;

	new String:readyPlayers[1024];
	new String:name[MAX_NAME_LENGTH];

	new Handle:panel = CreatePanel();

	
	if (readyup) {
		DrawPanelText(panel, "Ready");

		for(i = 1; i <  MaxClients ; i++) 

			if(IsClientInGame(i) && !IsFakeClient(i)) {
				new team = GetClientTeam(i) - TEAM_OFFSET;
				if (team == RED || team == BLU) {
					GetClientName(i, name, sizeof(name));
					if(readyStatus[i]) {
						numPlayers++;
						Format(readyPlayers, 1024, "->%d. %s", numPlayers, name);
						DrawPanelText(panel, readyPlayers);
					}
				}
			}
	}

	DrawPanelText(panel, " ");

	if (readyup) {
		DrawPanelText(panel, "Not Ready");

		for(i = 1; i <  MaxClients ; i++) 

			if(IsClientInGame(i) && !IsFakeClient(i)) {
				new team = GetClientTeam(i) - TEAM_OFFSET;
		                if (team == RED || team == BLU) {
					GetClientName(i, name, sizeof(name));
					if(!readyStatus[i]) {
						numPlayers2++;
						Format(readyPlayers, 1024, "->%d. %s", numPlayers2, name);
						DrawPanelText(panel, readyPlayers);				
					}
				}
			}
	}

	if (readyup) {
		SendPanelToClient(panel, client, ReadyPanelHandler, 10);
	}

	CloseHandle(panel);
 
	return Plugin_Handled;
}


//----------------------------------------------------------------------------
//| StartReady()
//|
//| Start the ready up phase
//----------------------------------------------------------------------------
StartReady() {
	readyup = true;

	readystart = false;
	redforce = false;
	redallowforce = false;
	redready = false;
	bluforce = false;
	bluallowforce = false;
	bluready = false;

	PrintToChatAll("\x04[MatchMod]\x01 %T", "Begin ready up", LANG_SERVER);
}

//----------------------------------------------------------------------------
//| EndReady()
//|
//| End the ready up phase
//----------------------------------------------------------------------------
EndReady() {
	readyup = false;
	readystart = false;
	redforce = false;
	redready = false;
	redallowforce = false;
	bluforce = false;
	bluready = false;
	bluallowforce = false;

	for(new i = 1; i < MaxClients; i++) {
		readyStatus[i] = false;
	}
}

//----------------------------------------------------------------------------
//| checkStatus()
//|
//| Check status of all players and decide an action
//----------------------------------------------------------------------------
checkStatus() {
	decl i;
	new redCount, blueCount;

	if (readyup) {
		for (i = 1; i <= MaxClients; i++) {
			if (IsClientConnected(i) && !IsFakeClient(i)) {
				if (readyStatus[i]) {
					new team = GetClientTeam(i) - TEAM_OFFSET;

					if (team == RED) {
						redCount++;
					}

					if (team == BLU) {
						blueCount++;
					}
				}
			}
		}

		if (redCount >= mm_minred && redCount < mm_reqred) {
			// Red has minimum but not automatic ready
			if (!redforce) {
				PrintToChatAll("\x04[MatchMod]\x01 %T", "Red team minimum", LANG_SERVER);
				PrintToChatAll("\x04[MatchMod]\x01 %T", "Red can start", LANG_SERVER);
				redready = false;
				redallowforce = true;
			}
		}
		else if (redCount >= mm_reqred) {
			// Red has achieved automatic ready count
			if (!redready) {
				PrintToChatAll("\x04[MatchMod]\x01 %T", "Red team ready", LANG_SERVER);
				redready = true;
			}
		}
		else if (redCount < mm_minred) {
			redforce = false;
			redallowforce = false;
		}

		if (blueCount >= mm_minblu && blueCount < mm_reqblu) {
			// Blu has minimum but not automatic ready
			if (!bluforce) {
				PrintToChatAll("\x04[MatchMod]\x01 %T", "Blue team minimum", LANG_SERVER);
				PrintToChatAll("\x04[MatchMod]\x01 %T", "Blue can start", LANG_SERVER);
				bluready = false;
				bluallowforce = true;
			}
		}
		else if (blueCount >= mm_reqblu) {
			// blu has achieved automatic ready count
			if (!bluready) {
				PrintToChatAll("\x04[MatchMod]\x01 %T", "Blue team ready", LANG_SERVER);
				bluready = true;
			}
		}
		else if (blueCount < mm_minblu) {
			bluforce = false;
			bluallowforce = false;
		}

		if ((bluready || bluforce) && (redready || redforce)) {
			// Here we go
			if (!readystart) {
				readystart = true;
				liveTime = CreateTimer(10.0, startRound);
				PrintCenterTextAll("%T", "Match in 15", LANG_SERVER);
			}
		}
		else if  ((!bluready || !bluforce) && (!redready || !redforce)) {
			// Stop it all
			if (readystart) {
				PrintToChatAll("\x04[MatchMod]\x01 %T", "Start aborted", LANG_SERVER);
				KillTimer(liveTime);
				readystart = false;
			}
		}

	}
}

/* 
---------------------------------------------------------------------------------------------------------
Executing Config Files

The following functions handle the execution of config files (Regulation, Overtime, Idle and shortcut)
---------------------------------------------------------------------------------------------------------
*/

//----------------------------------------------------------------------------
//| ExecOvertime()
//|
//| Executes the Overtime rules config file
//----------------------------------------------------------------------------
ExecOvertime() {
	// Sets the overtime regulations
	PrintToChatAll("\x04[MatchMod]\x01 %T", "Config overtime", LANG_SERVER);
	ServerCommand("exec %s", mm_svrcfgot);
}

//----------------------------------------------------------------------------
//| ExecIdle()
//|
//| Executes the Idle rules config file
//----------------------------------------------------------------------------
ExecIdle() {
	// Sets the idle regulations
	PrintToChatAll("\x04[MatchMod]\x01 %T", "Config idle", LANG_SERVER);
	ServerCommand("exec %s", mm_svrcfgidle);
}

//----------------------------------------------------------------------------
//| ExecRegulation()
//|
//| Executes the regulation rules config file
//----------------------------------------------------------------------------
ExecRegulation() {
	// Sets the regulation
	PrintToChatAll("\x04[MatchMod]\x01 %T", "Config match", LANG_SERVER);
	ServerCommand("exec %s", mm_svrcfg);
}

//----------------------------------------------------------------------------
//| ExecPreMatch()
//|
//| Executes the prematch config, used to unload some plugins (TF2DM for example)
//----------------------------------------------------------------------------
ExecPreMatch() {
	ServerCommand("exec matchmod/prematch.cfg");
}

//----------------------------------------------------------------------------
//| ExecPostMatch()
//|
//| Executes the postmatch config, used to restore plugin configs to normal
//----------------------------------------------------------------------------
ExecPostMatch() {
	ServerCommand("exec matchmod/postmatch.cfg");
}
/* 
---------------------------------------------------------------------------------------------------------
Scoring and Announcer

The following functions handle the announcer and score displays
---------------------------------------------------------------------------------------------------------
*/

//----------------------------------------------------------------------------
//| SetScoreboardNames()
//|
//| Resets the Scoreboard names to actual names
//----------------------------------------------------------------------------
SetScoreboardNames() {
	SetConVarString(FindConVar("mp_tournament_redteamname"), mm_tmaname);
	SetConVarString(FindConVar("mp_tournament_blueteamname"), mm_tmbname);
}

//----------------------------------------------------------------------------
//| Scoring()
//|
//| Based on given scenarios, produce the play by play string
//----------------------------------------------------------------------------
public Scoring(Handle:event, const String:name[], bool:dontBroadcast) {
	if (mm_state == 3 || mm_state == 5 || mm_state == 7) {
		new String:playbyplay[128];
		new String:remainingtime[256];

		g_cvar_temptime = FindConVar("mp_timelimit");
		mm_temptime = GetConVarInt(g_cvar_temptime);

		new timeleft;

		if (mm_temptime >= 1) {
			GetMapTimeLeft(timeleft);

			Format(remainingtime, 256, "%d:%02d", (timeleft / 60), (timeleft % 60));

			Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Time remaining", LANG_SERVER, remainingtime);
			PrintToChatAll(playbyplay);
		}

		if (!tcscoring) {
			if (mm_tmascore == mm_tmbscore) {
				Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score tied", LANG_SERVER, mm_tmascore, mm_tmbscore);
			}
			else if (mm_tmascore > mm_tmbscore) {
				Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score lead", LANG_SERVER, mm_tmaname, mm_tmascore, mm_tmbscore);
			}
			else if (mm_tmascore < mm_tmbscore) {
				Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score lead", LANG_SERVER, mm_tmbname, mm_tmbscore, mm_tmascore);
			}

			PrintToChatAll(playbyplay);
		}
		ServerName();
	}
}

//----------------------------------------------------------------------------
//| ScoreIntermission()
//|
//| Based on given scenarios, produce the play by play string
//| used when entering Halftime and Postgame
//----------------------------------------------------------------------------
ScorePrivate() {
	new String:playbyplay[128];
	new String:remainingtime[256];

	g_cvar_temptime = FindConVar("mp_timelimit");
	mm_temptime = GetConVarInt(g_cvar_temptime);

	new timeleft;

	if (mm_temptime >= 1) {
		GetMapTimeLeft(timeleft);

		Format(remainingtime, 256, "%d:%02d", (timeleft / 60), (timeleft % 60));

		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Time remaining", LANG_SERVER, remainingtime);
		PrintToChatAll(playbyplay);
	}
	
	if (mm_tmascore == mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score tied", LANG_SERVER, mm_tmascore, mm_tmbscore);
	}
	else if (mm_tmascore > mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score lead", LANG_SERVER, mm_tmaname, mm_tmascore, mm_tmbscore);
	}
	else if (mm_tmascore < mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score lead", LANG_SERVER, mm_tmbname, mm_tmbscore, mm_tmascore);
	}

	PrintToChatAll(playbyplay);
	ServerName();
}

//----------------------------------------------------------------------------
//| ScoreIntermission()
//|
//| Based on given scenarios, produce the play by play string
//| used when entering Halftime and Postgame
//----------------------------------------------------------------------------
ScoreIntermission() {
	new String:playbyplay[128];
	
	if (mm_tmascore == mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score tied", LANG_SERVER, mm_tmascore, mm_tmbscore);
	}
	else if (mm_tmascore > mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score lead", LANG_SERVER, mm_tmaname, mm_tmascore, mm_tmbscore);
	}
	else if (mm_tmascore < mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score lead", LANG_SERVER, mm_tmbname, mm_tmbscore, mm_tmascore);
	}

	PrintToChatAll(playbyplay);
}

//----------------------------------------------------------------------------
//| FinalScore()
//|
//| Declares a winner and posts the play by play statement
//----------------------------------------------------------------------------
FinalScore() {
	new String:playbyplay[128];

	if (mm_tmascore == mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score final tied", LANG_SERVER);
	}
	else if (mm_tmascore > mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score final", LANG_SERVER, mm_tmaname, mm_tmascore, mm_tmbscore);
	}
	else if (mm_tmascore < mm_tmbscore) {
		Format(playbyplay, sizeof(playbyplay), "\x04[MatchMod]\x01 %T", "Score final", LANG_SERVER, mm_tmbname, mm_tmbscore, mm_tmascore);
	}

	PrintToChatAll(playbyplay);
}

/*
---------------------------------------------------------------------------------------------------------
Admin Menu Integration

The following functions handle the admin menu features
---------------------------------------------------------------------------------------------------------
*/

public OnAdminMenuReady(Handle:topmenu) {

	if (topmenu == hAdminMenu) {
		return;
	}

	hAdminMenu = topmenu;
	new TopMenuObject:matchmod_commands = AddToTopMenu(hAdminMenu, "MatchMod Commands", TopMenuObject_Category, Category_Handler, INVALID_TOPMENUOBJECT);


	if (matchmod_commands == INVALID_TOPMENUOBJECT)
	{
		/* Shit Broke*/
		return;
	}
	
	AddToTopMenu(hAdminMenu, "sm_matchmod_begin", TopMenuObject_Item, Menu_Handler, matchmod_commands, "sm_matchmod_begin", ADMFLAG_RESERVATION);
	AddToTopMenu(hAdminMenu, "sm_matchmod_end", TopMenuObject_Item, Menu_Handler, matchmod_commands, "sm_matchmod_end", ADMFLAG_RESERVATION);
	
}


public Category_Handler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {

	if (action == TopMenuAction_DisplayTitle) {
		Format(buffer, maxlength, "MatchMod Commands:");
	}
	else if (action == TopMenuAction_DisplayOption) {
		Format(buffer, maxlength, "MatchMod Commands");
	}
}

public Menu_Handler(Handle:topmenu, TopMenuAction:action, TopMenuObject:object_id, param, String:buffer[], maxlength) {

	new String:obj_str[64];
	GetTopMenuObjName(topmenu, object_id, obj_str, sizeof(obj_str));

	if (action == TopMenuAction_DisplayOption) {
		if (StrEqual(obj_str, "sm_matchmod_begin")) {
			Format(buffer, maxlength, "Begin Match");
		}
		else if (StrEqual(obj_str, "sm_matchmod_end")) {
			Format(buffer, maxlength, "End Match");
		}	
	}
	else if (action == TopMenuAction_SelectOption) {
		if (StrEqual(obj_str, "sm_matchmod_begin")) {
			ServerCommand("sm_matchmod_begin");
		}
		else if (StrEqual(obj_str, "sm_matchmod_end")) {
			if (mm_state > 2) {
				ServerCommand("mp_tournament_restart");
			}
			else if (mm_state > 0 && mm_state < 3) {
				ServerCommand("sm_matchmod_end");
			}
		}	
	}
}