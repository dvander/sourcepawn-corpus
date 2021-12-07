#pragma semicolon 1

#include <sourcemod>
#include <sdktools_functions>

#define FLAGFIX_VERSION "0.9"

#define TEAM_UNASSIGNED 	0
#define TEAM_SPEC		1
#define TEAM_RED 		2
#define TEAM_BLUE 		3

public Plugin:myinfo = 
{
	name = "Flag Exploit Fixes",
	author = "Kevin_b_er",
	description = "Fixes flag exploits",
	version = FLAGFIX_VERSION,
	url = "www.brothersofchaos.com"
};

/*		License:  GNU General Public License version 3
  *	
  *		Credits:
  *		EnigmatiK of Intel Timer for flag carrier detection logic from said plugin.
  *		Kigen for an else case of GetClientAuthString.
  *		
  */

new bool:is_CTF;  				// Is capture the flag game?
new Handle:enabled_flag;		// Server controlled enabler for plugin
new redRunner = 0;				// RED player holding BLU flag
new bluRunner = 0;              // BLU player holding RED flag


public OnPluginStart()
{
	CreateConVar("flagfix_ver", FLAGFIX_VERSION, "Flag Exploit Fixer Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY );
	enabled_flag = CreateConVar("flagfix_enabled", "1", "Enable Flag Exploit Fixer", FCVAR_PLUGIN|FCVAR_SPONLY );
	is_CTF = false;
}

public OnConfigsExecuted()
{
	new String:mapname[6];
	new bool:was_CTF = is_CTF;
	
	/* Reset runners */
	redRunner = 0;
	bluRunner = 0;
	
	GetCurrentMap(mapname, sizeof(mapname));
	/* The map is a CTF map if the map begins with "ctf_" */
	is_CTF = GetConVarBool(enabled_flag) && ( strlen(mapname) > 4 ) && (strncmp(mapname, "ctf_", 4, false) == 0);
	
	/* Hook the event in CTF games when enabled */
	if( !was_CTF && is_CTF )
		{
		HookEvent("teamplay_flag_event", FlagEvent);
		HookEvent("player_team", HookPlayerChangeTeam, EventHookMode_Pre);
		}
	else if( was_CTF && !is_CTF )
		{
		UnhookEvent("teamplay_flag_event", FlagEvent);
		UnhookEvent("player_team", HookPlayerChangeTeam, EventHookMode_Pre);
		}
}


public Action:HookPlayerChangeTeam(Handle:event, const String:name[], bool:dontBroadcast)
{
if( !is_CTF || !GetConVarBool(enabled_flag) )
	{
	/* Shouldn't happen, but in the event a leftover event comes through, bail */
	return Plugin_Continue;
	}

new client = GetClientOfUserId(GetEventInt(event, "userid"));
new team = GetEventInt(event, "team");
new oldteam = GetEventInt(event, "oldteam");
new bool:connected = client ? IsClientConnected(client) : false;
new bool:isbeingkicked = connected && IsClientInKickQueue(client);


if( isbeingkicked )
	{
	return Plugin_Continue;
	}

if( connected )
	{
	if(    ( team == TEAM_UNASSIGNED ) && ( oldteam != TEAM_UNASSIGNED ) 
		&& (( client == redRunner ) || ( client == bluRunner )) )
		{
		decl String:PlayerName[64]; 
		decl String:authString[64];

		GetClientName(client, PlayerName, 64);
		if ( !GetClientAuthString(client, authString, 64) )
			{
			strcopy(authString, 64, "STEAM_ID_PENDING");
			}

		FakeClientCommand(client, "dropitem");
		ForcePlayerSuicide(client);
		KickClient(client, "Cannot carry flag into spec");
		
		LogMessage("\"%s<%s>\" attempted flag exploit and was kicked.", PlayerName, authString );
		}

	/* Patch other plugins forcing a client onto spec team, which causes the same bug.
	 * Don't kick the player as they are not neccessarily responsible for this, the server owner/admins are.
	 */
	if( team == TEAM_SPEC )
		{
		FakeClientCommand(client, "dropitem");
		}
	}

return Plugin_Continue;
}

/* Don't move the intel to the initial spec location (camera viewpoint when you first join the server) 
 * when the flag carrier disconnects */
public OnClientDisconnect(client)
{
FakeClientCommand(client, "dropitem");

return;
}

/* Flag event taken largely from Intel Timer, by EnigmatiK
 * Thanks! 
 */
public Action:FlagEvent(Handle:event, const String:name[], bool:dontBroadcast) 
{
	if( !GetConVarBool(enabled_flag) ) 
		{
		return Plugin_Continue;
		}
	
	new type = GetEventInt(event, "eventtype"); // 1 = pickup, 2 = cap, 4 = drop
	new user = GetEventInt(event, "player");
	if( type < 3 ) // pickup or cap; remember player (on pickup) 
		{ 
		if( type == 1 )
			{
			new team = GetClientTeam(user);
			if( team == 2 ) redRunner = user;
			if( team == 3 ) bluRunner = user;
			}
		}
	else if( type == 4 ) // dropped
		{ 
		if (user == redRunner)
			{
			redRunner = 0;
			} 
		else if (user == bluRunner) 
			{
			bluRunner = 0;
			}
	}
	
	return Plugin_Continue;
}