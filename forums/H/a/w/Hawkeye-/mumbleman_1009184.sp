/*
===============================================================================================================
Mumble Manager for Team Fortress 2

NAME		: MumbleMan.sp        
VERSION		: 1.0.3
AUTHOR		: Charles 'Hawkeye' Mabbott
DESCRIPTION	: Allows players to join a mumble server to team specific channels
REQUIREMENTS	: Sourcemod 1.2+

VERSION HISTORY	: 
	1.0.0	- First Public release
	1.0.1	- Autoupdate feature enabled
		- Multi-lingual translation support
	1.0.2	- Player team switch detection added
	1.0.3	- Added playername filter

NOTES
	URL Scheme for Mumble 1.2.0, not including version reference will enable 1.1 and down versions
	mumble://[USERNAME]:[PASSWORD]@[SERVERFQDN]:[PORT]/[CHANNELPATH](/?version=1.2.0)
===============================================================================================================

*/

#pragma semicolon 1
#include <sourcemod>

#define PLUGIN_VERSION "1.0.3"

#undef REQUIRE_PLUGIN
#include <autoupdate>

public Plugin:myinfo =
{
	name = "MumbleMan",
	author = "Hawkeye",
	description = "Allows players to join a mumble server to team specific channels",
	version = PLUGIN_VERSION,
	url = "http://forums.alliedmods.net/showthread.php?"
};

//----------------------------------------------------------------------------
//| Variables
//----------------------------------------------------------------------------

//ConVar Handles
new Handle:g_cvar_server;
new Handle:g_cvar_port;
new Handle:g_cvar_channelpath;
new Handle:g_cvar_clientversion;
new Handle:g_cvar_password;
new Handle:g_cvar_teamchannels;
new Handle:g_cvar_team1name;
new Handle:g_cvar_team2name;
new Handle:g_cvar_team3name;
new Handle:g_cvar_filterchars;

new mumbleStatus[MAXPLAYERS +1];

new String:mumble_server[64];
new String:mumble_port[8];
new String:mumble_password[15];
new String:mumble_channel[128];
new String:mumble_version[7];
new String:mumble_team1name[32];
new String:mumble_team2name[32];
new String:mumble_team3name[32];
new String:mumble_filterchar[128];

//----------------------------------------------------------------------------
//| Plugin start up
//----------------------------------------------------------------------------

public OnPluginStart()
{
	LoadTranslations("mumbleman.phrases");

	CreateConVar("mumbleman_version", PLUGIN_VERSION, "Mumble Manager version.", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);
	g_cvar_server = CreateConVar("mumbleman_server", "mumble.domain.tld", "FQDN of mumble server.", FCVAR_PLUGIN);
	g_cvar_port = CreateConVar("mumbleman_port", "64738", "Port of the mumble server.", FCVAR_PLUGIN);
	g_cvar_password = CreateConVar("mumbleman_password", "", "Passowrd for mumble server.", FCVAR_PLUGIN);
	g_cvar_channelpath = CreateConVar("mumbleman_channelpath", "Server", "Path to the base channel on the server.", FCVAR_PLUGIN);
	g_cvar_clientversion = CreateConVar("mumbleman_clientversion", "1.2.0", "Version of the Mumble client to use.", FCVAR_PLUGIN);
	g_cvar_teamchannels = CreateConVar("mumbleman_teamchannels", "0", "Whether team specific channels should be used.", FCVAR_PLUGIN);
	g_cvar_filterchars = CreateConVar("mumbleman_filterchars", "()[]{}", "Characters that should be filtered out of usernames.", FCVAR_PLUGIN);
	g_cvar_team1name = CreateConVar("mumbleman_team1name", "Spectator", "Name of Channel for Team 1.", FCVAR_PLUGIN);
	g_cvar_team2name = CreateConVar("mumbleman_team2name", "Team%20A", "Name of Channel for Team 2.", FCVAR_PLUGIN);
	g_cvar_team3name = CreateConVar("mumbleman_team3name", "Team%20B", "Name of Channel for Team 3.", FCVAR_PLUGIN);

	// Create a command to check the version of the plugin active
	RegAdminCmd("sm_mumbleman_version", Command_MumbleManVersion, ADMFLAG_GENERIC, "sm_mumbleman_version - shows version of plugin");
	
	RegConsoleCmd("sm_mumble", Command_JoinMumble);
	
	HookEvent("player_team", PlayerSwitchedTeams);
	AutoExecConfig(true);
}

public OnAllPluginsLoaded()
{ 
	if(LibraryExists("pluginautoupdate"))
	{ 
		AutoUpdate_AddPlugin("mumbleman.googlecode.com", "/svn/trunk/plugins.xml", PLUGIN_VERSION); 
	} 
}

public OnPluginEnd()
{
	if(LibraryExists("pluginautoupdate"))
	{ 
		AutoUpdate_RemovePlugin(); 
	} 
}

public OnMapStart()
{
}

public OnMapEnd()
{
}

//----------------------------------------------------------------------------
//| Callback functions
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
//| Action:Command_JoinMumble(client, args)
//|
//| Takes the client and send the defined mumble:// URL to join server/channel
//----------------------------------------------------------------------------
public Action:Command_JoinMumble(client, args) 
{
	if (client == 0)
	{
		ReplyToCommand(client, "[MumbleMan] %t", "Error_Console");
		return Plugin_Handled;
	}

	new team = GetClientTeam(client);
	
	ReplyToCommand(client, "\x04[MumbleMan]\x01 %t", "Joining_server");
	JoinMumble(client, team);
	mumbleStatus[client] = true;

			
	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| Action:Command_MumbleManVersion(client, args)
//|
//| Displays current version of mod to client
//----------------------------------------------------------------------------
public Action:Command_MumbleManVersion(client, args)
{
	ReplyToCommand(client, "\x04[MumbleMan]\x01 %t", "Version", PLUGIN_VERSION);
	return Plugin_Handled;
}

//----------------------------------------------------------------------------
//| OnClientDisconnect(client)
//|
//| When a client disconnects, force set is ready status to false
//----------------------------------------------------------------------------
public OnClientDisconnect(client)
{
	// clear the flag in case someone else connects as that client id later on
	mumbleStatus[client] = false;
}

//----------------------------------------------------------------------------
//| PlayerSwitchedTeams(Handle:event, const String:name[], bool:dontBroadcast)
//|
//| When a player changes team, check of they are in mumble and switch
//| channels accordingly
//----------------------------------------------------------------------------
public PlayerSwitchedTeams(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Get Client and Team from Event and pass to JoinMumble routine
	new tempclient = GetClientOfUserId(GetEventInt(event, "userid"));
	new tempteam = GetEventInt(event, "team");
	
	if (mumbleStatus[tempclient] && GetConVarBool(g_cvar_teamchannels))
	{
		JoinMumble(tempclient, tempteam);
	}
}

//----------------------------------------------------------------------------
//| Private functions
//----------------------------------------------------------------------------

//----------------------------------------------------------------------------
//| JoinMumble(client, team)
//|
//| Takes the given client and joins the appropriate channel
//----------------------------------------------------------------------------
JoinMumble(client, team)
{
	decl String:URL[256];
	decl String:nickName[64];

	GetFilteredClientName(client, nickName, sizeof(nickName));

	// This isn't fantastic to pull this everytime someone runs the command, but it makes sure were up to date with the cvars
	GetConVarString(g_cvar_server, mumble_server, sizeof(mumble_server));
	GetConVarString(g_cvar_port, mumble_port, sizeof(mumble_port));
	GetConVarString(g_cvar_password, mumble_password, sizeof(mumble_password));
	GetConVarString(g_cvar_channelpath, mumble_channel, sizeof(mumble_channel));
	GetConVarString(g_cvar_clientversion, mumble_version, sizeof(mumble_version));
	GetConVarString(g_cvar_team1name, mumble_team1name, sizeof(mumble_team1name));
	GetConVarString(g_cvar_team2name, mumble_team2name, sizeof(mumble_team2name));
	GetConVarString(g_cvar_team3name, mumble_team3name, sizeof(mumble_team3name));


	if (GetConVarBool(g_cvar_teamchannels))
	{
		if (team == 1)
		{
			Format(URL, sizeof(URL), "mumble://%s:%s@%s:%s/%s/%s/?version=%s", nickName, mumble_password, mumble_server, mumble_port, mumble_channel, mumble_team1name, mumble_version);
		}
		else if (team == 2)
		{
			Format(URL, sizeof(URL), "mumble://%s:%s@%s:%s/%s/%s/?version=%s", nickName, mumble_password, mumble_server, mumble_port, mumble_channel, mumble_team2name, mumble_version);
		}
		else if (team == 3)
		{
			Format(URL, sizeof(URL), "mumble://%s:%s@%s:%s/%s/%s/?version=%s", nickName, mumble_password, mumble_server, mumble_port, mumble_channel, mumble_team3name, mumble_version);
		}
	}
	else
	{
		Format(URL, sizeof(URL), "mumble://%s:%s@%s:%s/%s/?version=%s", nickName, mumble_password, mumble_server, mumble_port, mumble_channel, mumble_version);
	}

	ShowMOTDPanel(client, "", URL, MOTDPANEL_TYPE_URL);
	ShowVGUIPanel(client, "info", INVALID_HANDLE, false);
}

GetFilteredClientName(client, String:buffer[], size) {
	if (size == 0) {
		return;
	}

	decl String:clientName[64];
	GetClientName(client, clientName, sizeof(clientName));

	GetConVarString(g_cvar_filterchars, mumble_filterchar, sizeof(mumble_filterchar));
	
	new n=0;
	new buf_pos = 0;
	while (clientName[n] != '\0') {
		new x = 0;
		new invalid = false;
		while (mumble_filterchar[x] != '\0') {
			if (clientName[n] == mumble_filterchar[x]) {
				invalid = true;
				break;
			}
			
			++x;
		}
		
		if (!invalid) {
			buffer[buf_pos] = clientName[n];
			buf_pos++;
			
			if (buf_pos == size) {
				break;
			}
		}
		
		++n;
	}
	
	buffer[buf_pos] = '\0';
}