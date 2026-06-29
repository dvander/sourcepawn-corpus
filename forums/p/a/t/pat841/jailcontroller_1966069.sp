/*
 * SourceMod jailController
 * by:Pat841 @ www.amitygaming.org
 *
 * This file is part of SM jailController.
 *
 * This program is free software; you can redistribute it and/or modify it under
 * the terms of the GNU General Public License, version 3.0, as published by the
 * Free Software Foundation.
 * 
 * This program is distributed in the hope that it will be useful, but WITHOUT
 * ANY WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS
 * FOR A PARTICULAR PURPOSE.  See the GNU General Public License for more
 * details.
 *
 * You should have received a copy of the GNU General Public License along with
 * this program.  If not, see <http://www.gnu.org/licenses/>
 * 
 * CREDITS:
 * 	- databomb: Used his VGUIMenu functions and used his code to inspire some concepts
 * 
 * KNOWN BUGS:
 * 	- None Currently
 * 
 * CHANGELOG:
 * 	
 * 	1.4.2
 * 		- Small bug fixes
 * 		- Fixed warden FIFO bug
 * 		- Fixed bug where current warden stayed in queue and could be picked
 * 
 * 	1.4.1
 * 		- Remove previous warden from queue on new warden
 * 		- Various bug fixes and improvements
 * 
 * 	1.4.0
 * 		- Fixed issue with warden FIFO
 * 		- Small bug fixes
 * 		- Added voicehook support and cvars
 * 	
 * 	1.3.3
 * 		- Minor bug fixes and improvements
 * 		- Fixed warden not being removed some times
 * 		- Fixed updater issue
 * 
 * 	1.3.2
 * 		- Many bug fixes and improvements
 * 		- Fixed warden glitch
 * 		- Removed admins immune to ratio swap, kept immune to team switch
 * 		- Fixed mute immunity
 * 		- Added freeday freekill protection
 * 
 * 	1.3.1
 * 		- Added cvar for last guard freekill protection
 * 		- Added sm_unqueue command to allow client to leave warden/guard queue
 * 
 * 	1.3
 * 		- Fixed another warden glitch
 * 		- Added cvar to punish free killers
 * 		- Added cvar for maximum number of free kills
 * 		- Added cvar for free kill punish type
 * 		- Various improvements
 * 		- Translations updated
 * 
 * 	1.2.2
 * 		- Added a timer to show commands panel
 * 		- Fixed some more small bugs
 * 
 * 	1.2.1
 * 		- Added some notifications
 * 		- Many various bug fixes
 * 		- Added translations
 * 
 * 	1.2
 * 		- Fixed some more errors coming up
 * 		- Added some extra checking
 * 		- Cleaned up code
 * 		- Added support for the updater plugin
 * 
 * 	1.1.5
 * 		- Fixed minor bugs
 * 		- Fixed some errors that were coming up
 * 		- Fixed remove warden bug
 * 		- Added translations
 * 
 * 	1.1.4
 * 		- Fixed guard and ratio issues
 * 		- Various bug fixes and improvements
 * 		- Added some translations
 * 
 * 	1.1.3
 * 		- Fixed bug where warden was not removed if joined T
 * 		- Various bug fixes and improvements
 * 
 * 	1.1.2
 * 		- Fixed bug where players in spec were respawned
 * 
 * 	1.1.1
 * 		- Added cvar to remove warden queue each round
 * 		- Added some new notifications
 * 		- Fixed bugs with giving warden to dead players
 * 		- Fixed various bugs
 * 		- Improved stability
 * 
 * 	1.1
 * 		- Added notification for warden rounds at start
 * 		- Added cvar to set warden color
 * 		- Added !jail and !jb menu command to help users
 * 		- Many bug fixes  and enhancements
 * 		- Removed beta status, moved to release
 * 
 * 	1.0.3
 * 		- Fixed an issue when giving warden and player left server
 * 		- Fixed an issue where the guard queue was empty
 * 
 * 	1.0.2
 * 		- Updated colors to work with CS:GO
 * 
 * 	1.0.1
 * 		- Added cvar to disable ratio management
 * 		- Minor bug fixes and improvements
 * 		- Added adminmenu.custom.txt
 * 
 * 	1.0
 * 		- Initial release.
 */
 
#define PLUGIN_VERSION "1.4.2"

#pragma semicolon 1

#define _DEBUG 0
#define UPDATE_URL    "http://pat841.amitygaming.org/jailcontroller/updater.txt"

#define REASON_ROUND_DRAW 9
#define REASON_GAME_COMMENCING 15
#define REASON_INVALID 20

#include <sourcemod>
#include <sdktools>
#include <clientprefs>
#include <adminmenu>
#include <cstrike>
#include <colors>
#undef REQUIRE_PLUGIN
#include <updater>
#include <voiceannounce_ex>
#define REQUIRE_PLUGIN

// Timer Handles
new Handle:hTimerAdvertise = INVALID_HANDLE;

// Array Handles
new Handle:hArrayWardens = INVALID_HANDLE;
new Handle:hArrayGuards = INVALID_HANDLE;
new Handle:hArrayBanned = INVALID_HANDLE;
new Handle:hArrayMuted = INVALID_HANDLE;
new Handle:hArrayVoted = INVALID_HANDLE;

// Cvar Handles
new Handle:cvarPluginEnabled = INVALID_HANDLE;
new Handle:cvarPluginAdvertise = INVALID_HANDLE;

new Handle:cvarAdminFlag = INVALID_HANDLE;

new Handle:cvarWardenSelect = INVALID_HANDLE;
new Handle:cvarWardenKeepQueue = INVALID_HANDLE;
new Handle:cvarWardenColorEnable = INVALID_HANDLE;
new Handle:cvarWardenColor = INVALID_HANDLE;
new Handle:cvarWardenRounds = INVALID_HANDLE;
new Handle:cvarWardenAnnounce = INVALID_HANDLE;
new Handle:cvarWardenDeath = INVALID_HANDLE;
new Handle:cvarWardenVoteOff = INVALID_HANDLE;
new Handle:cvarWardenVotePercent = INVALID_HANDLE;
new Handle:cvarWardenMuteGuards = INVALID_HANDLE;
new Handle:cvarWardenMuteTime = INVALID_HANDLE;
new Handle:cvarWardenVoiceHook = INVALID_HANDLE;

new Handle:cvarPunishEnabled = INVALID_HANDLE;
new Handle:cvarPunishKills = INVALID_HANDLE;
new Handle:cvarPunishType = INVALID_HANDLE;
new Handle:cvarPunishGuard = INVALID_HANDLE;

new Handle:cvarRatioEnabled = INVALID_HANDLE;
new Handle:cvarRatioSmall = INVALID_HANDLE;
new Handle:cvarRatioMedium = INVALID_HANDLE;
new Handle:cvarRatioLarge = INVALID_HANDLE;
new Handle:cvarRatioFull = INVALID_HANDLE;
new Handle:cvarRatioForceT = INVALID_HANDLE;
new Handle:cvarRatioShowClasses = INVALID_HANDLE;

// Global Handles
new Handle:hEnforceMPLimitTeams = INVALID_HANDLE;

// Cvar Globals
new bool:gPluginEnabled;
new bool:gPluginAdvertise;

new String:gAdminFlag[30];
new gAdminFlagBits = 0;

new bool:gWardenSelect;
new bool:gWardenKeepQueue;
new bool:gWardenColorEnable;
new gWardenColor[3];
new gWardenRounds;
new bool:gWardenAnnounce;
new bool:gWardenDeath;
new bool:gWardenVoteOff;
new gWardenVotePercent;
new bool:gWardenMuteGuards;
new Float:gWardenMuteTime;
new bool:gWardenVoiceHook;

new bool:gPunishEnabled;
new gPunishKills;
new gPunishType;
new bool:gPunishGuard;

new bool:gRatioEnabled;
new Float:gRatioSmall;
new Float:gRatioMedium;
new Float:gRatioLarge;
new Float:gRatioFull;
new bool:gRatioForceT;
new bool:gRatioShowClasses;

// Globals
new gWardenCurrent;
new gWardenNext;
new gWardenPrevious;
new bool:gTeamsLocked;
new gRoundFirst = true;
new gRoundEnd = REASON_INVALID;
new gServerPlayers = 0;
new bool:gFreeDay;

// Counters
new cWardenRounds = 0;
new cWardenVotes = 0;
new cGuardKills[MAXPLAYERS + 1] = 0;
new cGuardsAlive = 0;

// Plugin Info
public Plugin:myinfo = 
{
	name = "jailController",
	author = "Pat841",
	description = "Manages many aspects of a jail server such as handling warden, managing the server ratio and supporting guard bans.",
	version = PLUGIN_VERSION,
	url = "http://www.amitygaming.org/"
};

public OnPluginStart ()
{
	// Hook Events
	HookEvent("player_team", Event_PlayerTeam);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("player_death", Event_PlayerDeath);
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("player_disconnect", Event_PlayerDisconnect);
	
	// Create ConVars
	CreateConVar("sm_jailcontroller_version", PLUGIN_VERSION, "jailController plugin version (unchangeable)", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	
	cvarPluginEnabled = CreateConVar("sm_jailcontroller_enabled", "1", "Enables or disables the plugin: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gPluginEnabled = true;
	
	cvarPluginAdvertise = CreateConVar("sm_jailcontroller_advertise", "1", "Enables or disables plugin advertisements: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gPluginAdvertise = true;
	
	cvarWardenSelect = CreateConVar("sm_jailcontroller_warden_select", "0", "How the plugin picks the next warden: 0 - FIFO, 1 - Randomly", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gWardenSelect = false;
	
	cvarWardenKeepQueue = CreateConVar("sm_jailcontroller_warden_keep_queue", "1", "Enables or disables keeping the warden queue between rounds: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gWardenKeepQueue = true;
	
	cvarWardenColorEnable = CreateConVar("sm_jailcontroller_warden_color_enable", "1", "Enables or disables coloring the warden: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gWardenColorEnable = true;
	
	cvarWardenColor = CreateConVar("sm_jailcontroller_warden_color", "125 150 250", "The model color to set the warden: 0 - Disabled", FCVAR_PLUGIN);
	gWardenColor[0] = 125;
	gWardenColor[1] = 150;
	gWardenColor[2] = 250;
	
	cvarWardenDeath = CreateConVar("sm_jailcontroller_warden_death", "1", "What happens when the warden dies: 0 - Pick a new warden, 1 - Round Freeday", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gWardenDeath = true;	
	
	cvarAdminFlag = CreateConVar("sm_jailcontroller_adminflag", "c", "Admins with this flag will be immune to mutes and ratio, and will be given access to admin commands: 1 - All admins, flag values: abcdefghijklmnopqrst");
	Format(gAdminFlag, sizeof(gAdminFlag), "z");
	
	cvarWardenRounds = CreateConVar("sm_jailcontroller_warden_rounds", "5", "Maximum number of rounds a player can be warden in a row: 0 - Unlimited, # - Rounds", FCVAR_PLUGIN, true, 0.0);
	gWardenRounds = 5;
	
	cvarWardenAnnounce = CreateConVar("sm_jailcontroller_warden_announce", "1", "Enables or disables announcing the new warden: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gWardenAnnounce = true;
	
	cvarWardenVoteOff = CreateConVar("sm_jailcontroller_warden_vote_off", "1", "Enables or disables players voting off a warden: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gWardenVoteOff = true;
	
	cvarWardenVoiceHook = CreateConVar("sm_jailcontroller_warden_voicehook", "1", "Enables or disables announcing when a warden speaks: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gWardenVoiceHook = true;
	
	cvarPunishEnabled = CreateConVar("sm_jailcontroller_punish_enabled", "1", "Enables or disables punishing freekillers: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gPunishEnabled = true;
	
	cvarPunishKills = CreateConVar("sm_jailcontroller_punish_kills", "8", "Maximum number of kills a guard (not warden) can have per round", FCVAR_PLUGIN, true, 0.0, true, 50.0);
	gPunishKills = 8;
	
	cvarPunishType = CreateConVar("sm_jailcontroller_punish_type", "0", "The punishment to deal on a guard: 0 - Slay, 1 - Kick, 2 - Ban", FCVAR_PLUGIN, true, 0.0, true, 50.0);
	gPunishType = 0;
	
	cvarPunishGuard = CreateConVar("sm_jailcontroller_punish_lastguard", "0", "Enables or disables punishing the last guard (last ct rule): 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gPunishGuard = false;
	
	cvarWardenVotePercent = CreateConVar("sm_jailcontroller_vote_percent", "60", "The percentage required to vote a warden off", FCVAR_PLUGIN, true, 25.0, true, 100.0);
	gWardenVotePercent = 60;
	
	cvarWardenMuteGuards = CreateConVar("sm_jailcontroller_mute_guards", "1", "Enables or disables muting all guards except for the warden: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gWardenMuteGuards = true;
	
	cvarWardenMuteTime = CreateConVar("sm_jailcontroller_mute_time", "15", "The number of seconds after a round starts to mute cts", FCVAR_PLUGIN, true, 1.0, true, 120.0);
	gWardenMuteTime = 15.0;
	
	cvarRatioEnabled = CreateConVar("sm_jailcontroller_ratio_enabled", "1", "Enables or disables ratio management: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gRatioEnabled = true;
	
	cvarRatioSmall = CreateConVar("sm_jailcontroller_ratio_small", "1.5", "The ratio to use when <=5 players in the server", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	gRatioSmall = 1.5;
	
	cvarRatioMedium = CreateConVar("sm_jailcontroller_ratio_medium", "1.667", "The ratio to use when <=10 players in the server", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	gRatioMedium = 1.667;
	
	cvarRatioLarge = CreateConVar("sm_jailcontroller_ratio_large", "1.75", "The ratio to use when <=15 players in the server", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	gRatioLarge = 1.75;
	
	cvarRatioFull = CreateConVar("sm_jailcontroller_ratio_full", "2.0", "The ratio to use when 15< players in the server", FCVAR_PLUGIN, true, 0.0, true, 10.0);
	gRatioFull = 2.0;
	
	cvarRatioForceT = CreateConVar("sm_jailcontroller_forcet", "1", "Enables or disables forcing players to terrorits on team join: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gRatioForceT = true;
	
	cvarRatioShowClasses = CreateConVar("sm_jailcontroller_show_classes", "0", "Enables or disables allowing model selection when put on team: 0 - Disabled, 1 - Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	gRatioShowClasses = false;
	
	// Hook Cvar Changes
	HookConVarChange(cvarPluginEnabled, HandleCvars);
	HookConVarChange(cvarPluginAdvertise, HandleCvars);
	HookConVarChange(cvarAdminFlag, HandleCvars);
	HookConVarChange(cvarWardenColorEnable, HandleCvars);
	HookConVarChange(cvarWardenSelect, HandleCvars);
	HookConVarChange(cvarWardenKeepQueue, HandleCvars);
	HookConVarChange(cvarWardenColor, HandleCvars);
	HookConVarChange(cvarWardenRounds, HandleCvars);
	HookConVarChange(cvarWardenAnnounce, HandleCvars);
	HookConVarChange(cvarWardenDeath, HandleCvars);
	HookConVarChange(cvarWardenVoteOff, HandleCvars);
	HookConVarChange(cvarWardenVotePercent, HandleCvars);
	HookConVarChange(cvarWardenMuteGuards, HandleCvars);
	HookConVarChange(cvarWardenMuteTime, HandleCvars);
	HookConVarChange(cvarWardenVoiceHook, HandleCvars);
	HookConVarChange(cvarPunishEnabled, HandleCvars);
	HookConVarChange(cvarPunishKills, HandleCvars);
	HookConVarChange(cvarPunishType, HandleCvars);
	HookConVarChange(cvarPunishGuard, HandleCvars);
	HookConVarChange(cvarRatioEnabled, HandleCvars);
	HookConVarChange(cvarRatioSmall, HandleCvars);
	HookConVarChange(cvarRatioMedium, HandleCvars);
	HookConVarChange(cvarRatioLarge, HandleCvars);
	HookConVarChange(cvarRatioFull, HandleCvars);
	HookConVarChange(cvarRatioForceT, HandleCvars);
	HookConVarChange(cvarRatioShowClasses, HandleCvars);
	
	// Register Commands
	RegConsoleCmd("sm_warden", Command_Warden);
	RegConsoleCmd("sm_retire", Command_Retire);
	RegConsoleCmd("sm_guard", Command_Guard);
	RegConsoleCmd("sm_unqueue", Command_UnQueue);
	RegConsoleCmd("sm_vkwarden", Command_VoteKickWarden);
	RegConsoleCmd("sm_jail", Command_SendJailPanel);
	RegConsoleCmd("sm_jb", Command_SendJailPanel);
	RegConsoleCmd("say", Command_Say);
	
	// Register Admin Commands
	RegAdminCmd("sm_clearwardens", Command_ClearWardens, ADMFLAG_CUSTOM4, "sm_clearwardens - Resets the warden queue");
	RegAdminCmd("sm_clearguards", Command_ClearGuards, ADMFLAG_CUSTOM4, "sm_clearguards - Resets the guard queue");
	RegAdminCmd("sm_removewarden", Command_RemoveWarden, ADMFLAG_CUSTOM4, "sm_removewarden - Removes the current warden");
	RegAdminCmd("sm_removeguard", Command_RemoveGuard, ADMFLAG_CUSTOM4, "sm_removeguard <player|#userid> - Removes the player from the guard queue");
	RegAdminCmd("sm_banguard", Command_BanGuard, ADMFLAG_CUSTOM4, "sm_banguard <player|#userid> - Bans the player from becoming a guard");
	RegAdminCmd("sm_clearguardbans", Command_ClearGuardBans, ADMFLAG_CUSTOM4, "sm_clearguardbans - Resets all guard bans");
	
	// Create Stacks
	hArrayWardens = CreateArray(1);
	hArrayGuards = CreateArray(1);
	hArrayBanned = CreateArray(1);
	hArrayMuted = CreateArray(1);
	hArrayVoted = CreateArray(1);
	
	// VGUIMenu Hook
	HookUserMessage(GetUserMessageId("VGUIMenu"),Hook_VGUIMenu,true);
	
	// Updater
	if (LibraryExists("updater"))
	{
	 	Updater_AddPlugin(UPDATE_URL);
	}
	
	// Command Listeners
	AddCommandListener(Listener_JoinTeam, "jointeam");
	
	// Load Translations
	LoadTranslations("common.phrases");
	LoadTranslations("jailcontroller.phrases");

	// Autoload Config
	AutoExecConfig(true, "jailcontroller");	
}

public OnLibraryAdded (const String:name[])
{
	if (StrEqual(name, "updater"))
	{
	 	Updater_AddPlugin(UPDATE_URL);
	}
}

#if defined _voiceannounceex_included_
public bool:OnClientSpeakingEx (client)
{
	if(gWardenVoiceHook && gWardenCurrent == client && IsClientInGame(client) && IsPlayerAlive(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		decl String:name[32];
		GetClientName(client, name, sizeof(name));
		PrintHintTextToAll("%T", "Voice Chat", LANG_SERVER, name);
	}
}
#endif

public OnMapStart ()
{
	// Globals
	gWardenCurrent = -1;
	gWardenNext = -1;
	gWardenPrevious = -1;
	gRoundFirst = true;
	gRoundEnd = REASON_INVALID;
	gServerPlayers = 0;
	gFreeDay = true;

	// Counters
	cWardenRounds = 0;
	cWardenVotes = 0;
	cGuardsAlive = 0;
	
	ClearArrays();
	
	// Show some support?
	if (gPluginEnabled && gPluginAdvertise)
	{
		hTimerAdvertise = CreateTimer(120.0, TimerAdvertisement, _, TIMER_REPEAT);
	}
	
	// Show help
	CreateTimer(300.0, TimerShowHelp, _, TIMER_REPEAT);
}

public OnMapEnd ()
{
	if (hTimerAdvertise != INVALID_HANDLE)
	{
		CloseHandle(hTimerAdvertise);
		hTimerAdvertise = INVALID_HANDLE;
	}
}

public OnConfigsExecuted ()
{
	// Get Cvars
	gPluginEnabled = GetConVarBool(cvarPluginEnabled);
	gPluginAdvertise = GetConVarBool(cvarPluginAdvertise);
	
	GetConVarString(cvarAdminFlag, gAdminFlag, sizeof(gAdminFlag));
	
	new String:color[30];
	GetConVarString(cvarWardenColor, color, sizeof(color));
	
	gWardenSelect = GetConVarBool(cvarWardenSelect);
	gWardenKeepQueue = GetConVarBool(cvarWardenKeepQueue);
	gWardenColorEnable = GetConVarBool(cvarWardenColorEnable);
	gWardenColor = SplitColorString(color);
	gWardenRounds = GetConVarInt(cvarWardenRounds);
	gWardenAnnounce = GetConVarBool(cvarWardenAnnounce);
	gWardenDeath = GetConVarBool(cvarWardenDeath);
	gWardenVoteOff = GetConVarBool(cvarWardenVoteOff);
	gWardenVotePercent = GetConVarInt(cvarWardenVotePercent);
	gWardenMuteGuards = GetConVarBool(cvarWardenMuteGuards);
	gWardenMuteTime = GetConVarFloat(cvarWardenMuteTime);
	gWardenVoiceHook = GetConVarBool(cvarWardenVoiceHook);
	
	gPunishEnabled = GetConVarBool(cvarPunishEnabled);
	gPunishKills = GetConVarInt(cvarPunishKills);
	gPunishType = GetConVarInt(cvarPunishType);
	gPunishGuard = GetConVarBool(cvarPunishGuard);
	
	gRatioEnabled = GetConVarBool(cvarRatioEnabled);
	gRatioSmall= GetConVarFloat(cvarRatioSmall);
	gRatioMedium = GetConVarFloat(cvarRatioMedium);
	gRatioLarge = GetConVarFloat(cvarRatioLarge);
	gRatioFull = GetConVarFloat(cvarRatioFull);
	gRatioForceT = GetConVarBool(cvarRatioForceT);
	gRatioShowClasses = GetConVarBool(cvarRatioShowClasses);
	
	// Enforce mp_limitteams
	hEnforceMPLimitTeams = FindConVar("mp_limitteams");
	if (gPluginEnabled && GetConVarInt(hEnforceMPLimitTeams) > 0)
	{
		SetConVarInt(hEnforceMPLimitTeams, 0);
	}
}

public OnAllPluginsLoaded ()
{
	if (!CColorAllowed(Color_Lightgreen))
	{
		if (CColorAllowed(Color_Lime))
		{
			CReplaceColor(Color_Lightgreen, Color_Lime);
		}
		else if (CColorAllowed(Color_Olive))
		{
			CReplaceColor(Color_Lightgreen, Color_Olive);
		}
	}
}

public bool:CheckImmune (client)
{
	if (GetUserFlagBits(client) & gAdminFlagBits)
	{
		return true;
	}
	return false;
}

// Events
public Event_PlayerTeam (Handle:event, const String:name[], bool:dontBroadcast)
{	
	//new teamNew = GetEventInt(event, "team");
	new teamOld = GetEventInt(event, "oldteam");
	new bool:disc = GetEventBool(event, "disconnect");
	new id = GetEventInt(event, "userid");
	new client = GetClientOfUserId(id);
	new index;
	
	if (teamOld == CS_TEAM_CT)
	{
		index = FindValueInArray(hArrayWardens, client);
		if (index != -1)
		{
			RemoveFromArray(hArrayWardens, index);
		}
		
		if (gWardenCurrent == client)
		{
			RemoveWarden();
		}
	}
	
	if (teamOld == CS_TEAM_T)
	{
		index = FindValueInArray(hArrayGuards, client);
		if (index != -1)
		{
			RemoveFromArray(hArrayGuards, index);
		}
	}
	
	if (disc)
	{
		RemoveClientArrays(client);
	}
}
public Event_RoundStart (Handle:event, const String:name[], bool:dontBroadcast)
{
	// Mute guards?
	if (gPluginEnabled && gWardenMuteGuards && !gRoundFirst)
	{
		ClearArray(hArrayMuted);
		new String:cmd[32];
		new uid;
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && !CheckImmune(i))
			{
				if (gWardenCurrent != i)
				{
					uid = GetClientUserId(i);
					Format(cmd, sizeof(cmd), "sm_mute #%d", uid);
					ServerCommand(cmd);
					PushArrayCell(hArrayMuted, i);
				}
			}
			cGuardKills[i] = 0;
		}
		
		// Ummute later on
		CreateTimer(gWardenMuteTime, TimerUnMuteGuards, _, TIMER_FLAG_NO_MAPCHANGE);
		
		new time = RoundFloat(gWardenMuteTime);
		
		CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Muted Guards", LANG_SERVER, time);
	}
	
	if (gPluginEnabled && !gRoundFirst)
	{
		gTeamsLocked = false;
		gFreeDay = false;
		
		CreateTimer(2.5, TimerRoundRespawn, _, TIMER_FLAG_NO_MAPCHANGE);
	}
	
	new rounds = gWardenRounds - cWardenRounds;
	
	if (gPluginEnabled && gWardenNext != -1 && rounds > 0)
	{
		SetWarden(gWardenNext);
		gWardenNext = -1;
	}
	
	// Make sure warden is still connected
	if (gPluginEnabled && gWardenCurrent != -1 && rounds > 0)
	{
		if (!IsClientInGame(gWardenCurrent) || GetClientTeam(gWardenCurrent) != CS_TEAM_CT)
		{
			RemoveWarden();
		}
	}
	
	if (gPluginEnabled && gWardenCurrent == -1 && rounds > 0 && GetArraySize(hArrayWardens) != 0 && !gWardenSelect)
	{
		GetNewWarden(true);
	}
	
	if (gPluginEnabled && gWardenCurrent != -1 && rounds > 0)
	{
		new String:cName[MAX_NAME_LENGTH+1];
		GetClientName(gWardenCurrent, cName, sizeof(cName));
		
		CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Current", LANG_SERVER, cName, rounds);
	}
	else if (gPluginEnabled && gWardenCurrent != -1 && rounds == 0)
	{
		CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Last Round", LANG_SERVER);
	}
	else if (gPluginEnabled && gWardenCurrent == -1)
	{
		CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "No Warden Start", LANG_SERVER);
	}
	
	// Save guard count
	cGuardsAlive = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && IsPlayerAlive(i))
		{
			cGuardsAlive += 1;
		}
	}
}

public Event_PlayerDeath (Handle:event, const String:name[], bool:dontBroadcast)
{
	new client = GetClientOfUserId(GetEventInt(event, "userid"));
	new killer = GetClientOfUserId(GetEventInt(event, "attacker"));
	
	// Is the player warden?
	if (gPluginEnabled && gWardenCurrent == client)
	{
		CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Dead", LANG_SERVER);
		
		// 0 - New Warden, 1 - Freeday
		if (gWardenDeath)
		{
			CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Dead Freeday", LANG_SERVER);
			gFreeDay = true;
		}
		else
		{
			new guards = 0;
			for (new i = 1; i <= MaxClients; i++)
			{
				if (IsClientInGame(i) && IsPlayerAlive(i) && GetClientTeam(i) == CS_TEAM_CT)
				{
					guards += 1;
				}
			}
			
			if (guards == 0)
			{
				CS_TerminateRound(0.0, CSRoundEnd_Draw, true);
			}
			else
			{
				GetNewWarden(true);
			}
		}
		
		cWardenRounds += 1;
	}
	
	// Last guard
	if (IsClientInGame(client) && GetClientTeam(client) == CS_TEAM_CT)
	{
		cGuardsAlive -= 1;
	}
	
	if (gPunishEnabled && killer && gWardenCurrent != killer && IsClientInGame(killer) && GetClientTeam(killer) == CS_TEAM_CT)
	{
		if (!gPunishGuard && (cGuardsAlive == 1 || gFreeDay))
		{
			return;
		}
		
		cGuardKills[killer] += 1;
		
		if (cGuardKills[killer] > gPunishKills)
		{
			new String:cmd[32];
			new id = GetClientUserId(killer);
			
			// Slay
			if (gPunishType == 0)
			{
				Format(cmd, sizeof(cmd), "sm_slay #%d", id);
				ServerCommand(cmd);
			}
			else if (gPunishType == 1)
			{
				Format(cmd, sizeof(cmd), "sm_kick #%d \"Freekilling is will not be tolerated.\"", id);
				ServerCommand(cmd);
			}
			else if (gPunishType == 2)
			{
				Format(cmd, sizeof(cmd), "sm_ban #%d \"Freekilling is will not be tolerated.\"", id);
				ServerCommand(cmd);
			}
		}
	}
}

public Event_RoundEnd (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (!gPluginEnabled)
	{
		return true;
	}
	
	if (gRatioEnabled)
	{
		gRoundEnd = GetEventInt(event, "reason");
		gTeamsLocked = true;
		gRoundFirst = false;
		
		gServerPlayers = 0;
		new guards, ts = 0;
		
		new Handle:aGuards = INVALID_HANDLE;
		new Handle:aTerrorists = INVALID_HANDLE;
		
		aGuards = CreateArray(1);
		aTerrorists = CreateArray(1);
		
		// Get number of players
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i))
			{
				if (GetClientTeam(i) == CS_TEAM_CT && gWardenNext != i)
				{
					PushArrayCell(aGuards, i);
					guards += 1;
					gServerPlayers += 1;
				}
				else if (GetClientTeam(i) == CS_TEAM_T)
				{
					PushArrayCell(aTerrorists, i);
					ts += 1;
					gServerPlayers += 1;
				}
			}
		}
		
		if (guards == 0)
		{
			gRoundFirst = true;
		}
		
		// Server empty?
		if (guards == 0 && ts == 0)
		{
			return true;
		}
		
		new targetT = 0;
		new Float:targetRatio;
		new Float:ratio;
		new Float:best = 10.1;
		
		// Get target ratio
		if (gServerPlayers <= 5)
		{
			targetRatio = gRatioSmall;
		}
		else if (gServerPlayers <= 10)
		{
			targetRatio = gRatioMedium;
		}
		else if (gServerPlayers <= 15)
		{
			targetRatio = gRatioLarge;
		}
		else
		{
			targetRatio = gRatioFull;
		}
		
		for (new i = 1; i <= (gServerPlayers - 1); i++)
		{
			ratio = FloatDiv(Float:i, (Float:gServerPlayers - Float:i));
			
			new Float:ratioGuess = FloatAbs(targetRatio - ratio);
			if (ratioGuess < best)
			{
				best = ratioGuess;
				targetT = i;
			}
		}
		
		new movesNeeded = 0;
		new clientToMove = 0;
		
		if (ts > targetT)
		{
			// Move T -> Guard
			movesNeeded = ts - targetT;
			
			for (new i = 0; i <= (movesNeeded - 1); i++)
			{
				new sizeT = GetArraySize(aTerrorists);
				// Check to see if there is a guard queue
				if (GetArraySize(hArrayGuards) == 0 && sizeT != 0)
				{
					// Nope, get random T
					if (GetArraySize(aTerrorists) != 0)
					{
						new random = GetRandomInt(0, (ts - 1));
						
						clientToMove = GetArrayCell(aTerrorists, random);
						RemoveFromArray(aTerrorists, random);
						
						CPrintToChat(clientToMove, "{olive}[{blue}jController{olive}] {green}%T", "Random to Guard", LANG_SERVER);
						CS_SwitchTeam(clientToMove, CS_TEAM_CT);
						
						ts -= 1;
					}
				}
				else if (GetArraySize(hArrayGuards) != 0)
				{
					// Get from queue
					clientToMove = GetArrayCell(hArrayGuards, 0);
					RemoveFromArray(hArrayGuards, 0);
					
					if (IsClientInGame(clientToMove))
					{
						CPrintToChat(clientToMove, "{olive}[{blue}jController{olive}] {green}%T", "Queue to Guard", LANG_SERVER);
						CS_SwitchTeam(clientToMove, CS_TEAM_CT);
						
						new index = FindValueInArray(aTerrorists, clientToMove);
						if (index != -1)
						{
							RemoveFromArray(aTerrorists, index);
						}
					}
				}
			}
		}
		else if (ts < targetT)
		{
			// Guard -> T
			movesNeeded = targetT - ts;
			
			for (new i = 0; i <= (movesNeeded - 1); i++)
			{
				if (GetArraySize(aGuards) != 0)
				{
					new random = GetRandomInt(0, (guards - 1));
					
					clientToMove = GetArrayCell(aGuards, random);
					RemoveFromArray(aGuards, random);
					
					CPrintToChat(clientToMove, "{olive}[{blue}jController{olive}] {green}%T", "Random to T", LANG_SERVER);
					CS_SwitchTeam(clientToMove, CS_TEAM_T);
					
					guards -= 1;
				}
			}
		}
	}
	
	// Handle Warden
	new rounds = gWardenRounds - cWardenRounds;
	if (rounds == -1 && GetArraySize(hArrayWardens) != 0)
	{
		GetNewWarden(false);
	}
	else if (rounds < 0)
	{
		RemoveWarden();
	}
	
	return true;
}

public Event_PlayerDisconnect (Handle:event, const String:name[], bool:dontBroadcast)
{
	if (gPluginEnabled)
	{
		new client = GetClientOfUserId(GetEventInt(event, "userid"));
		
		// Clear Arrays
		RemoveClientArrays(client);
		
		if (gWardenCurrent == client)
		{
			CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Disconnect", LANG_SERVER);
			
			// 0 - New Warden, 1 - Freeday
			if (gWardenDeath)
			{
				CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Dead Freeday", LANG_SERVER);
				gFreeDay = true;
				GetNewWarden(false);
			}
			else
			{
				GetNewWarden(true);
			}
		}
		
	}
}

// Commands
public Action:Command_Warden (client, args)
{
	if (gPluginEnabled && GetArraySize(hArrayWardens) == 0 && GetClientTeam(client) == CS_TEAM_CT && gWardenCurrent == -1)
	{
		SetWarden(client);
		
		new String:name[MAX_NAME_LENGTH+1];
		GetClientName(client, name, sizeof(name));
		
		if (gWardenAnnounce)
		{
			CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "New Warden Now", LANG_SERVER, name);
		}
	}
	else if (gPluginEnabled && FindValueInArray(hArrayWardens, client) == -1 && GetClientTeam(client) == CS_TEAM_CT)
	{
		PushArrayCell(hArrayWardens, client);
		CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Warden Add Queue", LANG_SERVER);
	}
	else if (gPluginEnabled && GetClientTeam(client) == CS_TEAM_CT)
	{
		CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Warden In Queue", LANG_SERVER);
	}
	
	return Plugin_Handled;
}

public Action:Command_Retire (client, args)
{
	if (gPluginEnabled && gWardenCurrent == client)
	{
		CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Retire", LANG_SERVER);
		
		// 0 - New Warden, 1 - Freeday
		if (gWardenDeath)
		{
			CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Dead Freeday", LANG_SERVER);
			gFreeDay = true;
			GetNewWarden(false);
		}
		else
		{
			GetNewWarden(true);
		}
	}
	else if (gPluginEnabled && GetClientTeam(client) == CS_TEAM_CT)
	{
		CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Not Warden", LANG_SERVER);
	}
	
	return Plugin_Handled;
}

public Action:Command_UnQueue (client, args)
{
	if (gPluginEnabled)
	{
		if (GetClientTeam(client) == CS_TEAM_T)
		{
			new index = FindValueInArray(hArrayGuards, client);
			if (index != -1)
			{
				RemoveFromArray(hArrayGuards, index);
				CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Removed From Queue", LANG_SERVER);
			}
			else
			{
				CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Not In Queue", LANG_SERVER);
			}
		}
		else if (GetClientTeam(client) == CS_TEAM_CT)
		{
			new index = FindValueInArray(hArrayWardens, client);
			if (index != -1)
			{
				RemoveFromArray(hArrayWardens, index);
				CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Removed From Queue", LANG_SERVER);
			}
			else
			{
				CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Not In Queue", LANG_SERVER);
			}
		}
	}
}

public Action:Command_Guard (client, args)
{
	if (gPluginEnabled && gRatioEnabled && FindValueInArray(hArrayGuards, client) == -1 && GetClientTeam(client) == CS_TEAM_T && FindValueInArray(hArrayBanned, client) == -1)
	{
		PushArrayCell(hArrayGuards, client);
		CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Guard Add Queue", LANG_SERVER);
	}
	else if (gPluginEnabled && gRatioEnabled &&  FindValueInArray(hArrayBanned, client) != -1)
	{
		CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Banned From Guards", LANG_SERVER);
	}
	else if (gPluginEnabled && gRatioEnabled &&  GetClientTeam(client) == CS_TEAM_T)
	{
		CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Warden In Queue", LANG_SERVER);
	}
	
	return Plugin_Handled;
}

public Action:Command_VoteKickWarden (client, args)
{
	if (gWardenVoteOff && gWardenCurrent != -1 && FindValueInArray(hArrayVoted, client) == -1)
	{
		new String:name[MAX_NAME_LENGTH+1];
		GetClientName(client, name, sizeof(name));
		
		new percent = GetPercent();
		
		cWardenVotes += 1;
		
		PushArrayCell(hArrayVoted, client);
		
		CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Votekick", LANG_SERVER, name, cWardenVotes, percent);
		
		if (cWardenVotes >= percent)
		{
			CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Votekicked", LANG_SERVER);
			
			GetNewWarden(true);
		}
	}
	else if (gWardenVoteOff && FindValueInArray(hArrayVoted, client) != -1)
	{
		CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "Warden Already Voted", LANG_SERVER);
	}
	else if (gWardenVoteOff)
	{
		CPrintToChat(client, "{olive}[{blue}jController{olive}] {green}%T", "No Warden", LANG_SERVER);
	}
	
	return Plugin_Handled;
}

public Action:Command_SendJailPanel (client, args)
{
	new Handle:panelJail = CreatePanel();
	
	SetPanelTitle(panelJail, "jController Commands:");
	
	DrawPanelText(panelJail, " ");
	DrawPanelText(panelJail, "!warden - Queue up for warden");
	DrawPanelText(panelJail, "!retire - Retire as warden");
	DrawPanelText(panelJail, "!guard - Queue up for guard");
	DrawPanelText(panelJail, "!unqueue - Removes you from the queue");
	DrawPanelText(panelJail, "!vkwarden - Votekick the warden");
	DrawPanelText(panelJail, "!jail - Displays this panel");
	DrawPanelText(panelJail, " ");
	DrawPanelText(panelJail, "0 - Exit");
	
	SendPanelToClient(panelJail, client, Handler_JailMenu, 20);
	
	CloseHandle(panelJail);
	
	return Plugin_Handled;
}

public Action:Command_Say (client, args)
{
	if (gPluginEnabled && gWardenCurrent == client && IsClientInGame(client) && IsClientInGame(client))
	{
		new String:text[128];
		new String:name[MAX_NAME_LENGTH+1];
		
		GetClientName(client, name, sizeof(name));
		GetCmdArgString(text, sizeof(text));
		
		ReplaceString(text, sizeof(text), "\"", "");
		
		CPrintToChatAll("{blue}[WARDEN] {green}%s:{blue} %s", name, text);
		
		return Plugin_Handled;
	}
	
	return Plugin_Continue;
}

public Action:Command_ClearWardens (client, args)
{
	ClearArray(hArrayWardens);
	
	ReplyToCommand(client, "[jController] Wardens cleared");
	
	return Plugin_Handled;
}

public Action:Command_ClearGuards (client, args)
{
	ClearArray(hArrayGuards);
	
	ReplyToCommand(client, "[jController] Guards cleared");
	
	return Plugin_Handled;
}

public Action:Command_RemoveWarden (client, args)
{
	CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Admin Removed", LANG_SERVER);
	
	// 0 - New Warden, 1 - Freeday
	if (gWardenDeath)
	{
		CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Warden Dead Freeday", LANG_SERVER);
		gFreeDay = true;
		GetNewWarden(false);
	}
	else
	{
		GetNewWarden(true);
	}
	
	ReplyToCommand(client, "[jController] Warden removed");
	
	return Plugin_Handled;
}

public Action:Command_RemoveGuard (client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[jController] Usage: sm_removeguard <player|#userid>");
		return Plugin_Handled;
	}
	else
	{
		decl String:arg[64];
		GetCmdArg(1, arg, sizeof(arg));
		
		new reason, targets[1], String:targetName[1], bool:tn_is_ml;
		reason = ProcessTargetString(arg, client, targets, sizeof(targets), COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), tn_is_ml);
		if (reason <= 0)
		{
			ReplyToTargetError(client, reason);
			
			return Plugin_Handled;
		}
		
		if (reason != 1)
		{
			return Plugin_Handled;
		}
		
		new target = targets[0];
		
		if (FindValueInArray(hArrayGuards, target) != -1)
		{
			RemoveFromArray(hArrayGuards, target);
		}
		
		ReplyToCommand(client, "[jController] Player removed from guard");
		
		if (GetClientTeam(target) == CS_TEAM_CT)
		{
			if (gWardenCurrent == target)
			{
				GetNewWarden(true);
			}
			
			CS_SwitchTeam(target, CS_TEAM_T);
			if (IsPlayerAlive(target))
			{
				CS_RespawnPlayer(target);
			}
		}
		else
		{
			ReplyToCommand(client, "[jController] Player is not a guard");
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_BanGuard (client, args)
{
	if (args != 1)
	{
		ReplyToCommand(client, "[jController] Usage: sm_banguard <player|#userid>");
		return Plugin_Handled;
	}
	else
	{
		decl String:arg[64];
		GetCmdArg(1, arg, sizeof(arg));
		
		new reason, targets[1], String:targetName[1], bool:tn_is_ml;
		reason = ProcessTargetString(arg, client, targets, sizeof(targets), COMMAND_FILTER_NO_MULTI | COMMAND_FILTER_NO_BOTS, targetName, sizeof(targetName), tn_is_ml);
		if (reason <= 0)
		{
			ReplyToTargetError(client, reason);
			
			return Plugin_Handled;
		}
		
		if (reason != 1)
		{
			return Plugin_Handled;
		}
		
		new target = targets[0];
		
		if (FindValueInArray(hArrayBanned, target) == -1)
		{
			PushArrayCell(hArrayBanned, target);
			
			ReplyToCommand(client, "[jController] Player banned from guard");
			
			if (GetClientTeam(target) == CS_TEAM_CT)
			{
				CS_SwitchTeam(target, CS_TEAM_T);
				if (IsPlayerAlive(target))
				{
					CS_RespawnPlayer(target);
				}
			}
		}
		else
		{
			ReplyToCommand(client, "[jController] Player is already banned");
		}
	}
	
	return Plugin_Handled;
}

public Action:Command_ClearGuardBans (client, args)
{
	ClearArray(hArrayBanned);
	
	ReplyToCommand(client, "[jController] Guard bans reset");
	
	return Plugin_Handled;
}

// Warden Functions
public GetNewWarden (bool:now)
{
	// Get players
	new Handle:aGuards = INVALID_HANDLE;
	aGuards = CreateArray(1);
	new countG = 0;
	
	// Remove current warden if in queue
	new index = FindValueInArray(hArrayWardens, gWardenCurrent);
	if (index != -1)
	{
		RemoveFromArray(hArrayWardens, index);
	}
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i) && GetClientTeam(i) == CS_TEAM_CT && gWardenPrevious != i)
		{
			PushArrayCell(aGuards, i);
			countG += 1;
		}
	}
	
	// 0 - FIFO, 1 - Randomly
	if (gWardenSelect || GetArraySize(hArrayWardens) == 0)
	{
		if (gWardenAnnounce)
		{
			CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Get Warden Random", LANG_SERVER);
		}
		PickWardenRandomly(now, aGuards, countG);
	}
	else
	{
		if (gWardenAnnounce)
		{
			CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Get Warden List", LANG_SERVER);
		}
		PickWardenFIFO(now, aGuards, countG);
	}
	
	return true;
}

public PickWardenRandomly (bool:now, Handle:aGuards, countG)
{
	new random;
	new String:name[MAX_NAME_LENGTH+1];
	
	// Warden died
	if (now)
	{
		// Lets get alive
		new Handle:alive = CloneArray(aGuards);
		new index;
		new aliveSize;
		
		for (new i = 1; i <= countG; i++)
		{
			if (!IsPlayerAlive(i))
			{
				index = FindValueInArray(alive, i);
				if (index != -1)
				{
					RemoveFromArray(alive, index);
				}
			}
		}
		
		// Get random alive player
		aliveSize = GetArraySize(alive);
		if (aliveSize != 0)
		{
			random = GetRandomInt(0, (aliveSize - 1));
			new warden = GetArrayCell(alive, random);
			
			if (gWardenAnnounce)
			{
				GetClientName(warden, name, sizeof(name));
				CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "New Warden Now", LANG_SERVER, name);
			}
			
			SetWarden(warden);
			
			return true;
		}
		else
		{
			CloseHandle(alive);
			CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "No Warden To Give", LANG_SERVER);
		}
	}
	
	if (!gWardenKeepQueue)
	{
		ClearArray(hArrayWardens);
	}
	
	if (countG == 0)
	{
		return -1;
	}
	
	// Nope, set next round
	random = GetRandomInt(0, (countG - 1));
	
	// Prevent swaping new warden
	gWardenNext = GetArrayCell(aGuards, random);
	
	if (gWardenAnnounce)
	{
		GetClientName(gWardenNext, name, sizeof(name));
		
		CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "New Warden Next", LANG_SERVER, name);
	}
	
	SetWarden(gWardenNext);
	
	return gWardenNext;
}

public PickWardenFIFO (bool:now, Handle:aGuards, countG)
{
	if (GetArraySize(hArrayWardens) == 0)
	{
		return PickWardenRandomly(now, aGuards, countG);
	}
	else
	{
		new String:name[MAX_NAME_LENGTH+1];
		
		// Warden died
		if (now)
		{
			// Lets get alive
			new Handle:alive = CloneArray(hArrayWardens);
			new index;
			new aliveSize;
			
			for (new i = 1; i <= countG; i++)
			{
				if (!IsPlayerAlive(i))
				{
					index = FindValueInArray(alive, i);
					if (index != -1)
					{
						RemoveFromArray(alive, index);
					}
				}
			}
			
			// Get next warden
			aliveSize = GetArraySize(alive);
			if (aliveSize != 0)
			{
				new warden = GetArrayCell(alive, 0);
				index = FindValueInArray(hArrayWardens, warden);
				RemoveFromArray(hArrayWardens, index);
				
				if (gWardenAnnounce)
				{
					GetClientName(warden, name, sizeof(name));
					CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "New Warden Now", LANG_SERVER, name);
				}
				
				SetWarden(warden);
				
				return true;
			}
			else
			{
				CloseHandle(alive);
				CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "No Warden To Give", LANG_SERVER);
			}
		}
		
		if (!gWardenKeepQueue)
		{
			ClearArray(hArrayWardens);
		}
		else
		{
			gWardenNext = GetArrayCell(hArrayWardens, 0);
			RemoveFromArray(hArrayWardens, 0);
			
			if (gWardenAnnounce)
			{
				GetClientName(gWardenNext, name, sizeof(name));
				
				CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "New Warden Next", LANG_SERVER, name);
			}
		}
		
		return true;
	}
}

public SetWarden (client)
{
	RemoveWarden();
	gWardenCurrent = client;
	if (gWardenColorEnable)
	{
		SetEntityRenderColor(client, gWardenColor[0], gWardenColor[1], gWardenColor[2], 255);
	}
	if (gWardenMuteGuards)
	{
		new String:cmd[32];
		new uid = GetClientUserId(client);
		Format(cmd, sizeof(cmd), "sm_unmute #%d", uid);
		ServerCommand(cmd);
	}
}

public RemoveWarden ()
{
	if (gWardenCurrent != -1)
	{
		gWardenPrevious = gWardenCurrent;
		gWardenCurrent = -1;
		cWardenRounds = 0;
		cWardenVotes = 0;
		ClearArray(hArrayVoted);
		if (gWardenColorEnable && IsClientInGame(gWardenPrevious) && !IsFakeClient(gWardenPrevious))
		{
			SetEntityRenderColor(gWardenPrevious, 0, 0, 0, 0);
		}
		
		// Remove from warden queue
		new index = FindValueInArray(hArrayWardens, gWardenPrevious);
		if (index != -1)
		{
			RemoveFromArray(hArrayWardens, index);
		}
	}
}

// Listeners
// Credit to databomb for most of this
public Action:Listener_JoinTeam (client, const String:command[], args)
{
	// Trigger map change?
	CreateTimer(0.3, TimerCheckDraw, _, TIMER_FLAG_NO_MAPCHANGE);
	
	// Make sure client is valid
	if(!gPluginEnabled || CheckImmune(client) || !client || !IsClientInGame(client) || IsFakeClient(client))
	{
		if (CheckImmune(client))
		{
			new adminIndex = FindValueInArray(hArrayGuards, client);
			if (adminIndex != -1)
			{
				RemoveFromArray(hArrayGuards, adminIndex);
			}
		}
		return Plugin_Continue;
	}
	
	// Get Target Team
	new String:teamString[3];
	GetCmdArg(1, teamString, sizeof(teamString));
	new teamTarget = StringToInt(teamString);
	
	new teamCurrent = GetClientTeam(client);
	
	if (gRatioEnabled && teamCurrent == teamTarget)
	{
		PrintCenterText(client, "%t", "Invalid Team Selection");
		return Plugin_Handled;
	}
	
	// Teams locked and game is in session
	if (gRatioEnabled && gTeamsLocked && gRoundEnd != REASON_INVALID && gRoundEnd != REASON_GAME_COMMENCING && gRoundEnd != REASON_ROUND_DRAW)
	{
		PrintCenterText(client, "%t", "Teams Currently Locked");
		SendTeamMenu(client);
		return Plugin_Handled;
	}
	
	// Is banned?
	if (FindValueInArray(hArrayBanned, client) != -1)
	{
		PrintCenterText(client, "%t", "Banned From Guards");
		SendTeamMenu(client);
		return Plugin_Handled;
	}
	
	// Allow one person to join at start
	if (gRatioEnabled && teamTarget == CS_TEAM_CT && gServerPlayers == 0 && gRoundFirst)
	{
		gServerPlayers += 1;
		return Plugin_Continue;
	}
	
	// Disable auto-join
	if (gRatioEnabled && teamTarget != CS_TEAM_T && teamTarget != CS_TEAM_CT && teamTarget != CS_TEAM_SPECTATOR)
	{
		PrintCenterText(client, "%t", "Auto-Join Disabled");
		SendTeamMenu(client);
		return Plugin_Handled;
	}
	
	// Make sure guard queue is empty
	if (gRatioEnabled && teamTarget == CS_TEAM_CT && GetArraySize(hArrayGuards) != 0)
	{
		PrintCenterText(client, "%t", "Queue Join Only");
		SendTeamMenu(client);
		return Plugin_Handled;
	}
	
	// Just joined?
	if (gRatioEnabled && gRatioForceT && teamTarget == CS_TEAM_CT && teamCurrent != CS_TEAM_T)
	{
		PrintCenterText(client, "%t", "Must Play T First");
		SendTeamMenu(client);
		return Plugin_Handled;
	}
	
	if (gRatioEnabled && !gRatioShowClasses)
	{
		new Handle:JoinClassPack = CreateDataPack();
		WritePackCell(JoinClassPack, client);
		WritePackCell(JoinClassPack, teamTarget);
		CreateTimer(0.0, Timer_ForceJoinClass, JoinClassPack);
	}
	
	return Plugin_Continue;
}

// Handlers
public Handler_JailMenu (Handle:menu, MenuAction:action, param1, param2)
{
	return;
}

// Timers
public Action:TimerAdvertisement (Handle:timer, any:client)
{
	CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Advertisement", LANG_SERVER);
}

public Action:TimerShowHelp (Handle:timer, any:client)
{
	CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Show Help", LANG_SERVER);
}

public Action:TimerUnMuteGuards (Handle:timer)
{
	new String:cmd[32];
	new uid, index;
	for (new i = 1; i <= MaxClients; i++)
	{
		index = FindValueInArray(hArrayMuted, i);
		if (index != -1)
		{
			uid = GetClientUserId(i);
			Format(cmd, sizeof(cmd), "sm_unmute #%d", uid);
			ServerCommand(cmd);
			RemoveFromArray(hArrayMuted, index);
		}
	}
	
	CPrintToChatAll("{olive}[{blue}jController{olive}] {green}%T", "Unmuted Guards", LANG_SERVER);
	
	return Plugin_Handled;
}

public Action:TimerCheckDraw (Handle:timer)
{
	// Make sure round is not in session
	if (!gTeamsLocked)
	{
		new guards = GetTeamClientCount(CS_TEAM_CT);
		new ts = GetTeamClientCount(CS_TEAM_T);
		
		new aliveGuards, aliveTs = 0;
		
		for (new i = 1; i <= MaxClients; i++)
		{
			if (IsClientInGame(i) && IsPlayerAlive(i))
			{
				if (GetClientTeam(i) == CS_TEAM_CT)
				{
					aliveGuards += 1;
				}
				else if (GetClientTeam(i) == CS_TEAM_T)
				{
					aliveTs += 1;
				}
			}
		}
		
		if ((guards > 0 && aliveGuards == 0) || (ts > 0 && aliveTs == 0))
		{
			CS_TerminateRound(0.0, CSRoundEnd_Draw, true);
		}
	}
	
	return Plugin_Handled;
}

public Action:TimerRoundRespawn (Handle:timer)
{
	for (new i = 1; i <= MaxClients; i++)
	{
	   if (IsClientInGame(i) && !IsPlayerAlive(i) && (GetClientTeam(i) == CS_TEAM_CT || GetClientTeam(i) == CS_TEAM_T))
	   {
			CS_RespawnPlayer(i);
	   }
	}
}

// Helpers
public HandleCvars (Handle:cvar, const String:oldValue[], const String:newValue[])
{
	// Ignore Same Values
	if (StrEqual(oldValue, newValue, true))
	{
		return;
	}
	
	// Convert to int
	new iNewValue = StringToInt(newValue);
	
	if (cvar == cvarPluginEnabled)
	{
		if (iNewValue != 1)
		{
			UnhookEvent("player_team", Event_PlayerTeam);
			UnhookEvent("round_start", Event_RoundStart);
			UnhookEvent("player_death", Event_PlayerDeath);
			UnhookEvent("round_end", Event_RoundEnd);
			UnhookEvent("player_disconnect", Event_PlayerDisconnect);
			AddCommandListener(Listener_JoinTeam, "jointeam");
			
			gPluginEnabled = false;
		}
		// Prevent re-hooking
		else if (iNewValue == 1 && gPluginEnabled)
		{
			HookEvent("player_team", Event_PlayerTeam);
			HookEvent("round_start", Event_RoundStart);
			HookEvent("player_death", Event_PlayerDeath);
			HookEvent("round_end", Event_RoundEnd);
			HookEvent("player_disconnect", Event_PlayerDisconnect);
			AddCommandListener(Listener_JoinTeam, "jointeam");
			
			gPluginEnabled = true;
		}
	}
	else if (cvar == cvarPluginAdvertise)
	{
		if (iNewValue != 1)
		{
			gPluginAdvertise = false;
		}
		else
		{
			gPluginAdvertise = true;
		}
	}
	else if (cvar == cvarAdminFlag)
	{
		Format(gAdminFlag, sizeof(gAdminFlag), newValue);
		RefreshFlags();
	}
	else if (cvar == cvarWardenSelect)
	{
		if (iNewValue != 1)
		{
			gWardenSelect = false;
		}
		else
		{
			gWardenSelect = true;
		}
	}
	else if (cvar == cvarWardenColorEnable)
	{
		if (iNewValue != 1)
		{
			gWardenColorEnable = false;
		}
		else
		{
			gWardenColorEnable = true;
		}
	}
	else if (cvar == cvarWardenColor)
	{
		gWardenColor = SplitColorString(newValue);
	}
	else if (cvar == cvarWardenRounds)
	{
		gWardenRounds = iNewValue;
	}
	else if (cvar == cvarWardenAnnounce)
	{
		if (iNewValue != 1)
		{
			gWardenAnnounce = false;
		}
		else
		{
			gWardenAnnounce = true;
		}
	}
	else if (cvar == cvarWardenDeath)
	{
		if (iNewValue != 1)
		{
			gWardenDeath = false;
		}
		else
		{
			gWardenDeath = true;
		}
	}
	else if (cvar == cvarWardenVoteOff)
	{
		if (iNewValue != 1)
		{
			gWardenVoteOff = false;
		}
		else
		{
			gWardenVoteOff = true;
		}
	}
	else if (cvar == cvarWardenVotePercent)
	{
		gWardenVotePercent = iNewValue;
	}
	else if (cvar == cvarWardenVoiceHook)
	{
		if (iNewValue != 1)
		{
			gWardenVoiceHook = false;
		}
		else
		{
			gWardenVoiceHook = true;
		}
	}
	else if (cvar == cvarWardenMuteGuards)
	{
		if (iNewValue != 1)
		{
			gWardenMuteGuards = false;
		}
		else
		{
			gWardenMuteGuards = true;
		}
	}
	else if (cvar == cvarWardenMuteTime)
	{
		gWardenMuteTime = StringToFloat(newValue);
	}
	else if (cvar == cvarPunishEnabled)
	{
		if (iNewValue != 1)
		{
			gPunishEnabled = false;
		}
		else
		{
			gPunishEnabled = true;
		}
	}
	else if (cvar == cvarPunishKills)
	{
		gPunishKills = StringToInt(newValue);
	}
	else if (cvar == cvarPunishType)
	{
		gPunishType = StringToInt(newValue);
	}
	else if (cvar == cvarPunishGuard)
	{
		if (iNewValue != 1)
		{
			gPunishGuard = false;
		}
		else
		{
			gPunishGuard = true;
		}
	}
	else if (cvar == cvarRatioEnabled)
	{
		if (iNewValue != 1)
		{
			gRatioEnabled = false;
		}
		else
		{
			gRatioEnabled = true;
		}
	}
	else if (cvar == cvarRatioSmall)
	{
		gRatioSmall = StringToFloat(newValue);
	}
	else if (cvar == cvarRatioMedium)
	{
		gRatioMedium = StringToFloat(newValue);
	}
	else if (cvar == cvarRatioLarge)
	{
		gRatioLarge = StringToFloat(newValue);
	}
	else if (cvar == cvarRatioFull)
	{
		gRatioFull = StringToFloat(newValue);
	}
	else if (cvar == cvarRatioForceT)
	{
		if (iNewValue != 1)
		{
			gRatioForceT = false;
		}
		else
		{
			gRatioForceT = true;
		}
	}
	else if (cvar == cvarRatioShowClasses)
	{
		if (iNewValue != 1)
		{
			gRatioShowClasses = false;
		}
		else
		{
			gRatioShowClasses = true;
		}
	}
}

public RefreshFlags ()
{
	if (StrEqual(gAdminFlag, "1"))
	{
		// Include all but reserved slot flag
		Format(gAdminFlag, sizeof(gAdminFlag), "bcdefghijklmnopqrstz");
	}
	gAdminFlagBits = ReadFlagString(gAdminFlag);
	
#if _DEBUG
	LogMessage("[jailController DEBUG] - Refreshed flags in RefreshFlags().");
#endif
	
	return true;
}

public GetPercent ()
{
	new percent = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientInGame(i))
		{
			percent += 1;
		}
	}
	return percent * gWardenVotePercent / 100;
}

SplitColorString(const String:colors[])
{
	decl _iColors[3], String:_sBuffer[3][4];
	ExplodeString(colors, " ", _sBuffer, 3, 4);
	for(new i = 0; i <= 2; i++)
		_iColors[i] = StringToInt(_sBuffer[i]);
	
	return _iColors;
}

public RemoveClientArrays (client)
{
	new index = FindValueInArray(hArrayWardens, client);
	if (index != -1)
	{
		RemoveFromArray(hArrayWardens, index);
	}
	index = FindValueInArray(hArrayGuards, client);
	if (index != -1)
	{
		RemoveFromArray(hArrayGuards, index);
	}
	index = FindValueInArray(hArrayBanned, client);
	if (index != -1)
	{
		RemoveFromArray(hArrayBanned, index);
	}
	index = FindValueInArray(hArrayMuted, client);
	if (index != -1)
	{
		RemoveFromArray(hArrayMuted, index);
	}
	
	return true;
}

// Credit for these few functions goes to databomb
public Action:Timer_ForceJoinClass (Handle:timer, Handle:JoinClassPack)
{
	ResetPack(JoinClassPack);
	new client = ReadPackCell(JoinClassPack);
	new team = ReadPackCell(JoinClassPack);
	
	if (team == CS_TEAM_T)
	{
		FakeClientCommand(client, "joinclass 3");
	}
	else if (team == CS_TEAM_CT)
	{
		FakeClientCommand(client, "joinclass 5");
	}
	
	CloseHandle(JoinClassPack);
}

public Action:Hook_VGUIMenu (UserMsg:msg_id, Handle:bf, const players[], playersNum, bool:reliable, bool:init)
{
	new String:sPanelName[10];
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbReadString(bf, "name", sPanelName, sizeof(sPanelName));
	}
	else
	{
		BfReadString(bf, sPanelName, sizeof(sPanelName));
	}

	// find any class panels
	if(StrContains(sPanelName, "class") != -1)
	{
		new bShow = BfReadByte(bf);
		if(bShow)
		{
			// hide class screen
			return Plugin_Handled;
		}
	}
	
	return Plugin_Continue;
}

public SendTeamMenu (client)
{
	new clients[1];
	new Handle:bf;
	clients[0] = client;
	bf = StartMessage("VGUIMenu", clients, 1);
	
	if (GetUserMessageType() == UM_Protobuf)
	{
		PbSetString(bf, "name", "team");
		PbSetBool(bf, "show", true);
	}
	else
	{
		BfWriteString(bf, "team"); // panel name
		BfWriteByte(bf, 1); // bShow
		BfWriteByte(bf, 0); // count
	}
	
	EndMessage();
	
	return true;
}

// Stack Management
public ClearArrays ()
{
	ClearArray(hArrayWardens);
	ClearArray(hArrayGuards);
	ClearArray(hArrayBanned);
	ClearArray(hArrayMuted);
	ClearArray(hArrayVoted);
	
	return true;
}