/*
=============================================================================
WTSR: Woody's Tree Spectator Restriction
	(formerly called "[HL2DM] Spectator Restriction")
=============================================================================

This plugin restricts access to the console commands 'spectate' and
'jointeam' to admins with the permission to execute a given command. The idea
is, that only admins with the appropriate permissions are allowed to
spectate.
This plugin targets HL2DM, because MoggieX's 'Reserved Spectators/Teams'
plugin does not work with it.

Console commands:
-	spectate:
		affected as described above
-	jointeam <1|2>:
		affected as described above

CVARs:
-	wtsr_version:
		the plugin's version.
-	wtsr_admflags:
		a string of ASCII character admin flags (like "c" for "kick") that
		determines who can bypass the restriction.
		(default: "d", i.e. "ban")

Testing platform:
-	Linux SRCDS 1.0.0.19
-	Metamod:Source 1.8.5
-	SourceMod 1.3.6

Changelog:
-	1.00
	-	changed cvar '_admcmd' to '_admgflags', i.e. now checking against
		flags
	-	removed cvar '_enable'
	-	clean up
	-	renamed to WTSR
-	0.82
	-	refurbishment
	-	added suppression of team switch messages
- 	0.815
	-	general redesign
	-	renamed CVARs
	-	added 'AutoExecConfig()'
	-	added translation support (translations: en, de)
	-	workaround for 'colour problem' with Mästerkatten's 'Spawn & Chat
		Protection'
- 	0.42
	-	Initial release
=============================================================================
*/
#pragma semicolon 1
#include <sourcemod>

// Define constants
#define SR_VERSION "1.00"

// Define translation phrases
#define SR_TRANSL_LOG_ACCESS_DENIED "log_access_denied"
#define SR_TRANSL_REPLY_ACCESS_DENIED "reply_access_denied"
#define SR_TRANSL_REPLY_SPECTATE_USAGE "reply_spectate_usage"
#define SR_TRANSL_REPLY_JOINTEAM_USAGE "reply_jointeam_usage"



// Define global variables
new Handle:g_cvarAdmFlags;



public Plugin:myinfo = {
	// Set plugin info
	name = "WTSR: Woody's Tree Spectator Restriction",
	author = "Woody",
	description = "restricts access to the console commands 'spectate' and 'jointeam'",
	version = SR_VERSION,
	url = "http://woodystree.net/"
}



public OnPluginStart() {
	// Load translation files
	LoadTranslations("common.phrases");
	LoadTranslations("wtsr.phrases");
	
	// Create CVARs
	CreateConVar("wtsr_version", SR_VERSION, "the version of WTSR: Woody's Tree Spectator Restriction", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	g_cvarAdmFlags = CreateConVar("wtsr_admflags", "d", "A string of ASCII character admin flags (like \"c\" for \"kick\") that determines who can bypass the restriction.");
	
	// Execute config file, create it if non-existent
	AutoExecConfig(true, "wtsr");

	// Get flags for admin command from cvar
	decl String:stringAdmFlags[32];
	GetConVarString(g_cvarAdmFlags, stringAdmFlags, sizeof(stringAdmFlags));
	new admFlags = ReadFlagString(stringAdmFlags);
	
	// "Hook" existing console commands as admin commands
	RegAdminCmd("jointeam", Command_jointeam, admFlags);
	RegAdminCmd("spectate", Command_spectate, admFlags);
	
	// Hook team switch event to suppress team switch messages
	HookEvent("player_team", Event_player_team, EventHookMode_Pre);
}



public Action:Command_jointeam(clientIndex, argumentCount) {
	// Check if no. of arguments is 1
	if (argumentCount != 1) {
		// NO: print usage and stop!
		ReplyToCommand(clientIndex, "%t", SR_TRANSL_REPLY_JOINTEAM_USAGE);
		return Plugin_Handled;
	}
	// Get team argument
	new String:teamString[32];
	GetCmdArg(1, teamString, sizeof(teamString));
	new teamIndex = StringToInt(teamString);
	// Check team argument
	if (teamIndex == 1) {
		// Team argument is Spectator
		return Plugin_Continue;
	} else if (teamIndex == 2) {
		// Team argument is Unassigned
		// "Normalize" colour, just in case the client was protected by Spawn & Chat Protection
		SetEntityRenderColor(clientIndex, 255, 255, 255, 0);
		return Plugin_Continue;
	} else {
		// Team argument is not valid within HL2DM: print usage and stop!
		ReplyToCommand(clientIndex, "%t", SR_TRANSL_REPLY_JOINTEAM_USAGE);
		return Plugin_Handled;
	}
}



public Action:Command_spectate(clientIndex, argumentCount) {
	// Check if no. of arguments is zero
	if (argumentCount != 0) {
		//NO: print usage and stop!
		ReplyToCommand(clientIndex, "%t", SR_TRANSL_REPLY_SPECTATE_USAGE);
		return Plugin_Handled;
	}
	return Plugin_Continue;
}



public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast) {
	new clientIndex = GetClientOfUserId(GetEventInt(event, "userid"));
	if(clientIndex != 0) {
		return Plugin_Handled;
	}
	return Plugin_Continue;
}

