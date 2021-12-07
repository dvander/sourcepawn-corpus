/******************************************************************************
	WTSR: Woody's Tree Spectator Restriction
*******************************************************************************

TODO

******************************************************************************/

#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#define PLUGIN_VERSION "2.0-alpha"

#define MAX_TEAM_NAME_LENGTH 32



/******************************************************************************

	G L O B A L   V A R S

******************************************************************************/

new Handle:g_cvarSpectateAdmflags;
new Handle:g_cvarJointeamAdmflags;
new Handle:g_cvarChangeteamAdmflags;
new Handle:g_cvarSupressMsgs;

new g_allowTeam[MAXPLAYERS + 1] = {-1, ...};



/******************************************************************************

	P L U G I N   I N F O

******************************************************************************/

public Plugin:myinfo =
{
	name = "WTSR: Woody's Tree Spectator Restriction",
	author = "Woody",
	description = "restricts access to the SPECTATOR team and provides an admin command to change a client's team",
	version = PLUGIN_VERSION,
	url = "http://woodystree.net/"
}



/******************************************************************************

	P U B L I C   F O R W A R D S

******************************************************************************/

public OnPluginStart()
{
	// Load translation files
	LoadTranslations("core.phrases");
	LoadTranslations("common.phrases");
	LoadTranslations("wtsr.phrases");
	
	// Create CVARs
	CreateConVar("wtsr_version", PLUGIN_VERSION, "the version of WTSR: Woody's Tree Spectator Restriction", FCVAR_NOTIFY|FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_DONTRECORD);
	g_cvarSpectateAdmflags = CreateConVar("wtsr_spectate_admflags", "d", "a string of admin flag characters that defines the required access rights for a client in order to join the SPECTATOR team");
	g_cvarJointeamAdmflags = CreateConVar("wtsr_jointeam_admflags", "d", "a string of admin flag characters that defines the required access rights for a client in order to use the jointeam command");
	g_cvarChangeteamAdmflags = CreateConVar("wtsr_changeteam_admflags", "z", "a string of admin flag characters that defines the required access rights for a client in order to use the changeteam command");
	g_cvarSupressMsgs = CreateConVar("wtsr_supress_msgs", "1", "show normal team switch messages if set to 0, supress messages otherwise");
	
	// Execute config file, create if non-existent
	AutoExecConfig(true, "wtsr");
	
	// "Hook" existing console commands jointeam and spectate
	RegConsoleCmd("jointeam", Command_jointeam);
	RegConsoleCmd("spectate", Command_spectate);
	
	// Register new console command changeteam
	RegConsoleCmd("changeteam", Command_changeteam, "change a client's team (usage: changeteam <#userid|name> <team>)");
	
	// Hook team switch event for message suppression
	HookEvent("player_team", Event_player_team, EventHookMode_Pre);
}



/******************************************************************************

	C A L L B A C K   F U N C T I O N S

******************************************************************************/

public Action:Command_jointeam(client, args)
{
	// Do checks only if we are not server console, i.e. client <> 0
	if (client)
	{
		// Normal command handling if we are fake client
		if (IsFakeClient(client))
			return Plugin_Continue;
		
		// Get client's access rights
		new clientFlags = GetUserFlagBits(client);
		
		// Normal command handling if we have root rights
		if (clientFlags & ADMFLAG_ROOT)
			return Plugin_Continue;
		
		// Get team argument
		decl String:sTeam[3];
		GetCmdArg(1, sTeam, sizeof(sTeam));
		new team = StringToInt(sTeam);
		
		// Normal command handling if we have been changed by someone else via 'changeteam' command
		if (team == g_allowTeam[client])
		{
			g_allowTeam[client] = -1;
			return Plugin_Continue;
		}
		
		// Get required access rights for jointeam command
		decl String:sJointeamAdmflags[32];
		GetConVarString(g_cvarJointeamAdmflags, sJointeamAdmflags, sizeof(sJointeamAdmflags));
		new jointeamAdmflags = ReadFlagString(sJointeamAdmflags);
		
		// Further checks if we have appropriate jointeam access rights
		if (!(jointeamAdmflags) || (clientFlags & jointeamAdmflags))
		{
			// Normal command handling if team is *not* SPECTATOR
			if (team != 1)
				return Plugin_Continue;
			
			// Get required access rights to spectate
			decl String:sSpectateAdmflags[32];
			GetConVarString(g_cvarSpectateAdmflags, sSpectateAdmflags, sizeof(sSpectateAdmflags));
			new spectateAdmflags = ReadFlagString(sSpectateAdmflags);
			
			// Normal command handling if we have appropriate spectate access rights
			if (spectateAdmflags || clientFlags & spectateAdmflags)
				return Plugin_Continue;
		}
		
		// Stop command handling in any other case
		ReplyToCommand(client, "%t", "No Access");
		return Plugin_Handled;
	}
	
	// Normal command handling if we are server console
	return Plugin_Continue;
}



public Action:Command_spectate(client, args)
{
	// Do checks only if we are not server console, i.e. client <> 0
	if (client)
	{
		// Normal command handling if we are fake client
		if (IsFakeClient(client))
			return Plugin_Continue;
		
		// Get client's access rights
		new clientFlags = GetUserFlagBits(client);
		
		// Normal command handling if we have root rights
		if (clientFlags & ADMFLAG_ROOT)
			return Plugin_Continue;
		
		// Get required access rights to spectate
		decl String:sSpectateAdmflags[32];
		GetConVarString(g_cvarSpectateAdmflags, sSpectateAdmflags, sizeof(sSpectateAdmflags));
		new spectateAdmflags = ReadFlagString(sSpectateAdmflags);
		
		// Normal command handling if we have appropriate spectate access rights
		if (!(spectateAdmflags) || (clientFlags & spectateAdmflags))
			return Plugin_Continue;
		
		// Stop command handling in any other case
		ReplyToCommand(client, "%t", "No Access");
		return Plugin_Handled;
	}
	
	// Normal command handling if we are server console
	return Plugin_Continue;
}



public Action:Command_changeteam(client, args)
{
	// Get client's access rights
	decl clientFlags;
	if (client)
		clientFlags = GetUserFlagBits(client);
	else
		clientFlags = ADMFLAG_ROOT;
	
	// Get required access rights for changeteam command
	decl String:sChangeteamAdmflags[32];
	GetConVarString(g_cvarChangeteamAdmflags, sChangeteamAdmflags, sizeof(sChangeteamAdmflags));
	new changeteamAdmflags = ReadFlagString(sChangeteamAdmflags);
	
	// Normal command handling if we have appropriate changeteam access rights
	if ((clientFlags & ADMFLAG_ROOT) || (clientFlags & changeteamAdmflags))
	{
		// Print changeteam usage if number of args <> 2
		if (args != 2)
		{
			ReplyToCommand(client, "%t", "changeteam usage");
			return Plugin_Handled;
		}
		
		// Get target argument
		decl String:sTarget[MAX_NAME_LENGTH];
		GetCmdArg(1, sTarget, sizeof(sTarget));
		new target = FindTarget(0, sTarget, true);
		if (target == -1)
		{
			ReplyToCommand(client, "%t", "changeteam invalid target");
			return Plugin_Handled;
		}
		
		// Get team argument
		decl String:sTeam[3];
		GetCmdArg(2, sTeam, sizeof(sTeam));
		new team = StringToInt(sTeam);
		if ((team < 0) || (team >= GetTeamCount() - 1))
		{
			ReplyToCommand(client, "%t", "changeteam invalid team");
			return Plugin_Handled;
		}
		
		// Get client name (i.e. the one who issued the command)
		decl String:sClientName[MAX_NAME_LENGTH];
		if (client)
		{
			if (!GetClientName(client, sClientName, sizeof(sClientName)))
				sClientName = "\x03UNKNOWN\x04";
		}
		else
			sClientName = "\x03CONSOLE\x04";
		
		// Get team name
		decl String:sTeamName[MAX_TEAM_NAME_LENGTH];
		GetTeamName(team, sTeamName, sizeof(sTeamName));
		
		// Initiate team change
		g_allowTeam[target] = team;
		FakeClientCommandEx(target, "jointeam %i", team);
		PrintToChat(target, "\x01\x04%t", "changeteam target message", sTeamName, sClientName);
	}
	else
	{
		// No access to command in any other case
		ReplyToCommand(client, "%t", "No Access");
	}
	return Plugin_Handled;
}



public Action:Event_player_team(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Get content of message supression cvar
	new supressMsgs = GetConVarInt(g_cvarSupressMsgs);
	
	// Stop event handling if message supression is activated, normal event handling otherwise
	if (supressMsgs)
		return Plugin_Handled;
	else
		return Plugin_Continue;
}

