/******************************************************************************
	WTSR: Woody's Tree Spectator Restriction
		(formerly called "[HL2DM] Spectator Restriction")
*******************************************************************************

This plugin restricts access to the console commands 'spectate' and 'jointeam'
to admins with the permission to execute a given command. The idea is, that
only admins with the appropriate permissions are allowed to spectate.
This plugin targets HL2DM, because MoggieX's 'Reserved Spectators/Teams' plugin
does not work there.

Console commands:
-	spectate:
		affected as described above
-	jointeam:
		affected as described above

CVARs:
-	wtsr_version:
		the plugin's version.
-	wtsr_admflags:
		a string of ASCII character admin flags (like "c" for "kick") that
		determines who can bypass the restriction.
		(default: "d", i.e. "ban")

Changelog:
-	1.0i
	-	interim version to remove SourceTV incompatibility
	-	clean up
-	1.0
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
******************************************************************************/

#pragma semicolon 1
#include <sourcemod>

#define SR_VERSION "1.0i"



/******************************************************************************

	G L O B A L   V A R S

******************************************************************************/

new Handle:g_cvarAdmFlags;



/******************************************************************************

	P L U G I N   I N F O

******************************************************************************/

public Plugin:myinfo =
{
	name = "WTSR: Woody's Tree Spectator Restriction",
	author = "Woody",
	description = "restricts access to the console commands 'spectate' and 'jointeam'",
	version = SR_VERSION,
	url = "http://woodystree.net/"
}



/******************************************************************************

	P U B L I C   F O R W A R D S

******************************************************************************/

public OnPluginStart()
{
	// Load translation files
	LoadTranslations("core.phrases");
	LoadTranslations("wtsr.phrases");
	
	// Create CVARs
	CreateConVar("wtsr_version", SR_VERSION, "the version of WTSR: Woody's Tree Spectator Restriction", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY);
	g_cvarAdmFlags = CreateConVar("wtsr_admflags", "d", "A string of ASCII character admin flags (like \"c\" for \"kick\") that determines who can bypass the restriction.");
	
	// Execute config file, create it if non-existent
	AutoExecConfig(true, "wtsr");

	// "Hook" existing console commands
	RegConsoleCmd("jointeam", Command_jointeam_spectate);
	RegConsoleCmd("spectate", Command_jointeam_spectate);
	
	// Hook team switch event to suppress team switch messages
	//HookEvent("player_team", Event_player_team, EventHookMode_Pre);
	HookEvent("player_team", Event_player_team, EventHookMode_Pre);
}



/******************************************************************************

	C A L L B A C K   F U N C T I O N S

******************************************************************************/

public Action:Command_jointeam_spectate(client, args)
{
	// Normal command handling if we are a fake client
	if (IsFakeClient(client))
		return Plugin_Continue;

	// Get client's access rights
	new clientFlagsBS = GetUserFlagBits(client);

	// Normal command handling if we have root rights
	if (clientFlagsBS & ADMFLAG_ROOT)
		return true;

	// Normal command handling if we have appropriate rights
	decl String:wtsrFlags[32];
	GetConVarString(g_cvarAdmFlags, wtsrFlags, sizeof(wtsrFlags));
	new wtsrFlagsBS = ReadFlagString(wtsrFlags);	
	if (clientFlagsBS & wtsrFlagsBS)
		return Plugin_Continue;

	// Stop command handling in any other case
	ReplyToCommand(client, "%t", "No Access");
	return Plugin_Handled;
}



public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Stop event handling so we do not see team switch messages
	return Plugin_Handled;
}

