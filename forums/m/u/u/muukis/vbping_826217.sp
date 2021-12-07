/*
-----------------------------------------------------------------------------
VERY BASIC HIGH PING KICKER - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By msleeper (c) 2009
Visit http://www.msleeper.com/ for more info!
-----------------------------------------------------------------------------
This is a very simple high ping kicker that kicks players based on their ping
as reported by SourceMod. The ping is checked at a constant interval (default
of 20 seconds) and if their ping exceeds the max ping given, they are
internally given a warning. If a player exceeds the maximum number of
warnings, they are kicked from the server. That's it.

The plugin does take admin level into account, players with the CUSTOM1 or
ROOT flags are immune to ping balancing. You can also specify a grace period
before a player will be warned to compensate for first connect ping when a
player first joins, and also a minimum number of players in the server before
it starts kicking them. It also waits 60 seconds after a map change before
doing any ping checking, again to allow all players to fully join and pings
to normalize.

Thank you and enjoy!
- msleeper
-----------------------------------------------------------------------------
Version History

-- 1.0 (2/26/09)
 . Initial release!

-- 1.1 (2/27/09)
 . Added current ping as reported by the plugin to the debug command.
 . Changed the way ping is gathered to lower the margin of error in ping
   checking.

-- 1.1.1 (5/15/09)
 . Small modifications by muukis
-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.1.1"

// Log var and player warning array
new String:Logfile[256];
new PingWarnings[MAXPLAYERS + 1];

// Timer handle
new Handle:PingTimer = INVALID_HANDLE;

// Used to ignore checking right after map changes
new TimerCheck = false;

// Cvar handles
new Handle:cvar_MinTime = INVALID_HANDLE;
new Handle:cvar_MaxPing = INVALID_HANDLE;
new Handle:cvar_CheckRate = INVALID_HANDLE;
new Handle:cvar_MaxWarnings = INVALID_HANDLE;
new Handle:cvar_MinPlayers = INVALID_HANDLE;
new Handle:cvar_KickMsg = INVALID_HANDLE;
new Handle:cvar_PublicKickMsg = INVALID_HANDLE;
new Handle:cvar_LogActions = INVALID_HANDLE;

// Plugin info
public Plugin:myinfo = 
{
	name = "Very Basic High Ping Kicker",
	author = "msleeper (modified by muukis)",
	description = "Simple ping check and autokick",
	version = PLUGIN_VERSION,
	url = "http://www.msleeper.com/"
};

// Here we go!
public OnPluginStart()
{
	// Plugin version public Cvar
	CreateConVar("sm_vbping_version", PLUGIN_VERSION, "Ping Kick plugin Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Debug command to see who is going to get kicked
	RegConsoleCmd("sm_vbping_debug", cmd_Debug);

	// Config Cvars
	cvar_MinTime = CreateConVar("sm_vbping_mintime", "60", "Minimum playtime before ping check begins", FCVAR_PLUGIN);
	cvar_MaxPing = CreateConVar("sm_vbping_maxping", "200", "Maximum player ping", FCVAR_PLUGIN, true, 1.0);
	cvar_CheckRate = CreateConVar("sm_vbping_checkrate", "20.0", "Period in seconds when rate is checked", FCVAR_PLUGIN, true, 10.0);
	cvar_MaxWarnings = CreateConVar("sm_vbping_maxwarnings", "10", "Number of warnings before kick", FCVAR_PLUGIN, true, 3.0);
	cvar_MinPlayers = CreateConVar("sm_vbping_minplayers", "20", "Minimum number of players before kicking", FCVAR_PLUGIN);
	cvar_KickMsg = CreateConVar("sm_vbping_kickmsg", "You have been kicked due to excessive ping", "Kick message", FCVAR_PLUGIN);
	cvar_PublicKickMsg = CreateConVar("sm_vbping_publickickmsg", "Player <PLAYERNAME> has been kicked due to excessive ping", "Public kick message (keyword \"<PLAYERNAME>\" will be replaced with the player name)", FCVAR_PLUGIN);
	cvar_LogActions = CreateConVar("sm_vbping_logactions", "0", "Log warning and kicks, 0 = Off, 1 = On", FCVAR_PLUGIN, true, 0.0, true, 1.0);

	// Make that config!
	AutoExecConfig(true, "vbping");

	// Enable logging
	BuildPath(Path_SM, Logfile, sizeof(Logfile), "logs/vbping.log");

	// Start the timer
	PingTimer = CreateTimer(GetConVarFloat(cvar_CheckRate), timer_CheckPing, INVALID_HANDLE, TIMER_REPEAT);

	// Initialize everyone's warnings at 0
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
		PingWarnings[i] = 0;

	TimerCheck = true;
	CreateTimer(60.0, timer_EnableCheck);
}

// Reset all players' warnings to 0 on map start, and close any existing
// timer on map start, just in case one exists.

public OnMapStart()
{
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
		PingWarnings[i] = 0;

	if (PingTimer == INVALID_HANDLE)
		PingTimer = CreateTimer(GetConVarFloat(cvar_CheckRate), timer_CheckPing, INVALID_HANDLE, TIMER_REPEAT);

	TimerCheck = true;
	CreateTimer(60.0, timer_EnableCheck);
}

// Print debug information.

public Action:cmd_Debug(client, args)
{
	PrintToConsole(client, "[SM] Basic High Ping Kick Debug");

	new String:Name[64];
	new Players = 0;
	new Float:Ping;

	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			Players++;
			GetClientName(i, Name, sizeof(Name));
			Ping = GetClientAvgLatency(i, NetFlow_Outgoing) * 1024;

			if ((GetUserFlagBits(i) & ADMFLAG_CUSTOM1) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
				PrintToConsole(client, " . %s - Ping: %f - *Immune*", Name, Ping);
			else
				PrintToConsole(client, " . %s - Ping: %f - %i Warnings", Name, Ping, PingWarnings[i]);
		}
	}
	
	// If the number of players is less than the minimum set by the plugin,
	// then report it.

	new MinPlayers = GetConVarInt(cvar_MinPlayers);
	if (Players <= MinPlayers)
		PrintToConsole(client, "[SM] Minimum players not met! %i / %i", Players, MinPlayers);

	return Plugin_Handled;
}

// Initialize client's warnings to 0 when they connect.

public OnClientPostAdminCheck(client)
{
	PingWarnings[client] = 0;
}

// Enable checking again, after the map change delay

public Action:timer_EnableCheck(Handle:timer)
{
	TimerCheck = false;
}

// Restart the timer if the rate of change is altered after the plugin has
// began running.

public action_RateChanged(Handle:convar, const String:oldValue[], const String:newValue[])
{
	if (convar == cvar_CheckRate)
	{
		CloseHandle(PingTimer);

		new NewTime = StringToInt(newValue);
		PingTimer = CreateTimer(float(NewTime), timer_CheckPing, INVALID_HANDLE, TIMER_REPEAT);
	}
}

PlayerCounter()
{
	new counter = 0;
	
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			counter++;
		}
	}
	
	return counter;
}

// Check the ping!
public Action:timer_CheckPing(Handle:timer)
{
	if (TimerCheck)
		return;

	new String:Message[512];
	new String:PublicMessage[512];
	new String:Name[64];
	new String:SteamID[64];
	new Float:Ping;
	new Float:Time;

	// First, let's get a count of the players in-game.

	new Players = PlayerCounter();

	// If the number of players is less than the minimum set by the plugin,
	// then quit out.

	if (Players < GetConVarInt(cvar_MinPlayers))
		return;

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			Time = GetClientTime(i);
			GetClientAuthString(i, SteamID, sizeof(SteamID));
			GetClientName(i, Name, sizeof(Name));

			// If the client has been connected for less time than the
			// minimum set by the plugin, ignore them.

			if (Time < GetConVarInt(cvar_MinTime))
				continue;

			// If the client has exceeded the number of warnings, kick them.
			// This is done before giving a warnings, so they are not warned
			// their final time, and then kicked for it.

			if (PingWarnings[i] >= GetConVarInt(cvar_MaxWarnings))
			{
				GetConVarString(cvar_KickMsg, Message, sizeof(Message));
				KickClient(i, Message);

				GetConVarString(cvar_PublicKickMsg, PublicMessage, sizeof(PublicMessage));
				TrimString(PublicMessage);
				if (strlen(PublicMessage) > 0)
				{
					Format(PublicMessage, sizeof(PublicMessage), "\x04[\x03SM\x04] \x01%s", PublicMessage);
					if (ReplaceString(PublicMessage, sizeof(PublicMessage), "<PLAYERNAME>", "\x05<PLAYERNAME>\x01", false) > 0)
						ReplaceString(PublicMessage, sizeof(PublicMessage), "<PLAYERNAME>", Name);
					PrintToChatAll(PublicMessage);
				}
				
				if (GetConVarBool(cvar_LogActions))
					LogToFile(Logfile, "%s [%s] has been kicked, excessive ping warnings (%i)", Name, SteamID, PingWarnings[i]);

				PingWarnings[i] = 0;
				continue;
			}

			// If the client's ping exceedes the maximum set by the plugin,
			// give them a warning.

			Ping = GetClientAvgLatency(i, NetFlow_Outgoing) * 1024;
			if (Ping > GetConVarInt(cvar_MaxPing))
			{
				// If the client has the CUSTOM1 or ROOT flag, ignore them.

				if ((GetUserFlagBits(i) & ADMFLAG_RESERVATION) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
				{
					if (GetConVarBool(cvar_LogActions))
						LogToFile(Logfile, "%s ignored, Reserved Flag met", Name);

					continue;
				}

				PingWarnings[i] = PingWarnings[i] + 1;

				if (GetConVarBool(cvar_LogActions))
					LogToFile(Logfile, "%s has %i ping warning (Ping: %f)", Name, PingWarnings[i], Ping);
			}
		}
	}
}
