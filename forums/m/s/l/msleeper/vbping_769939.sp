/*
-----------------------------------------------------------------------------
VERY BASIC HIGH PING KICKER - SOURCEMOD PLUGIN
-----------------------------------------------------------------------------
Code Written By msleeper (c) 2010
Visit http://www.msleeper.com/ for more info!
-----------------------------------------------------------------------------
This is a very simple high ping kicker that kicks players based on their ping
as reported by SourceMod. The ping is checked at a constant interval (default
of 20 seconds) and if their ping exceeds the max ping given, they are
internally given a warning. If a player exceeds the maximum number of
warnings, they are kicked from the server. That's it!

The plugin does take admin level into account, based on an immunity flag cvar.
Players with the RESERVED (default) or ROOT flags are immune to ping
balancing. You can also specify a grace period after a player connects before
they will be warned to compensate for first connect ping, as well as a
minimum number of players in the server before it starts kicking them. The
plugin will also apply this grace period after a map change before doing any
ping checking, again to allow all players to fully join and pings to
normalize.

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

-- 1.2 (5/19/09)
 . Added check to ignore fake clients/bots, which was throwing an error for
   HLTV users and L4D bots.
 . Changed the initial mapchange delay from 60 seconds to 90 seconds.
 . Added 2 cvars to handle public chat display message in addition to normal
   kick message sent to player. Left 4 Dead does not display disconnect
   messages in-game to the rest of the players, so it is advised to use this
   function if you want in-game kick announcements in L4D. The cvar can
   accept a chat variable, {NAME} case-sensitive, which will replace with the
   player in question's name. They are not required.
 . Added 2 cvars to handle player warning message when they are given
   warnings by the plugin. The cvar can accept 2 chat variables, {WARN} and
   {MAXWARN} case-sensitive, which will replace with their current warnings
   and the maximum warnings respectively. Neither are required.
 . Added player's playtime to debug output.
 . Reformatted debug command output.
 
-- 1.3 (10/1/09)
 . Fixed long standing bug with the wrong type of player flag being used. The
   plugin now properly uses the CUSTOM1 flag instead of the RESERVED flag.
   Again, sorry to everyone for not addressing this sooner!
 . Commented code further and cleaned up some unnecessary things.

-- 1.4 (7/15/10)
 . Increased default value and other changes to several cvars.
 . Changed plugin startup/mapchange delay from a static 90 seconds to the
   same value as individual player delay to improve plugin consistency.
 . Changed the way player playtime was handled, as the previous way was not
   using the correct value. New connecting players are now properly given a
   connection grace period.
 . Debug command changes have been made as well. Removed player playtime from
   debug message as it was also not using the correct value. Added a message
   to show connecting players as well as immune players.
 . Removed static CUSTOM1 immunity flag, and added cvar to control what flag
   grants immunity. Players with the ROOT flag are still always immune. The
   default immunity flag also changed back to RESERVED due to request.
 . Changed the way "minimum players" was calculated. Previously the plugin
   would not start working until the playercount was greater than the
   minimum. The plugin now properly starts if the playercount is equal to
   the minimum.
 . Changed the log output. Logging now only logs when players receive
   warnings and when they are kicked. There is no longer any immunity
   logging.
 . Fixed the plugin not properly updating the ping check rate when the rate
   is changed on the fly.
 . Generally just cleaned up code to benefit from some minor new features of
   SourceMod, and added further commenting and code consistency.
-----------------------------------------------------------------------------
*/

#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.4"

// Log path and player warning/grace period arrays
new String:Logfile[PLATFORM_MAX_PATH];
new PingWarnings[MAXPLAYERS + 1];
new PingDelay[MAXPLAYERS + 1];

// Timer handle for primary ping checking
new Handle:PingTimer = INVALID_HANDLE;

// Used to disable ping checking right after map change
new TimerCheck = false;

// Cvar handles
new Handle:cvar_MinTime = INVALID_HANDLE;
new Handle:cvar_MaxPing = INVALID_HANDLE;
new Handle:cvar_CheckRate = INVALID_HANDLE;
new Handle:cvar_MaxWarnings = INVALID_HANDLE;
new Handle:cvar_MinPlayers = INVALID_HANDLE;
new Handle:cvar_KickMsg = INVALID_HANDLE;
new Handle:cvar_LogActions = INVALID_HANDLE;
new Handle:cvar_ShowPublicKick = INVALID_HANDLE;
new Handle:cvar_KickMsgPublic = INVALID_HANDLE;
new Handle:cvar_ShowWarnings = INVALID_HANDLE;
new Handle:cvar_WarningMsg = INVALID_HANDLE;
new Handle:cvar_ImmunityFlag = INVALID_HANDLE;

// Plugin info
public Plugin:myinfo = 
{
	name = "Very Basic High Ping Kicker",
	author = "msleeper",
	description = "Simple ping check and autokick",
	version = PLUGIN_VERSION,
	url = "http://www.msleeper.com/"
};

// Here we go!
public OnPluginStart()
{
	// Plugin version public Cvar
	CreateConVar("sm_vbping_version", PLUGIN_VERSION, "Very Basic High Ping Kicker Version", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY|FCVAR_DONTRECORD);

	// Debug command to see who is going to get kicked
	RegConsoleCmd("sm_vbping_debug", cmd_Debug, "Displays player ping debug information");

	// Config Cvars
	cvar_MinTime = CreateConVar("sm_vbping_mintime",				"90",				"Minimum playtime before ping check begins", FCVAR_PLUGIN);
	cvar_MaxPing = CreateConVar("sm_vbping_maxping",				"250",				"Maximum player ping", FCVAR_PLUGIN, true, 1.0);
	cvar_CheckRate = CreateConVar("sm_vbping_checkrate",			"20.0",				"Period in seconds when rate is checked", FCVAR_PLUGIN, true, 1.0);
	cvar_MaxWarnings = CreateConVar("sm_vbping_maxwarnings",		"10",				"Number of warnings before kick", FCVAR_PLUGIN, true, 1.0);
	cvar_MinPlayers = CreateConVar("sm_vbping_minplayers",			"12",				"Minimum number of players before kicking", FCVAR_PLUGIN);
	cvar_LogActions = CreateConVar("sm_vbping_logactions",			"0",				"Log warning and kick actions. 0 = Disabled, 1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_ShowWarnings = CreateConVar("sm_vbping_showwarnings",		"1",				"Enable/disable warning messages. 0 = Disabled, 1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_WarningMsg = CreateConVar("sm_vbping_warningmsg",			"You will be kicked for excessive ping. You have {WARN} out of {MAXWARN} warnings.",				"Warning message sent to high ping client. {WARN} and {MAXWARN} converts to the warning count and max warnings respectively.", FCVAR_PLUGIN);
	cvar_KickMsg = CreateConVar("sm_vbping_kickmsg",				"You have been kicked due to excessive ping",				"Kick message sent to kicked client", FCVAR_PLUGIN);
	cvar_ShowPublicKick = CreateConVar("sm_vbping_showpublickick",	"0",				"Enable/disable public kick message. 0 = Disabled, 1 = Enabled", FCVAR_PLUGIN, true, 0.0, true, 1.0);
	cvar_KickMsgPublic = CreateConVar("sm_vbping_kickmsgpublic",	"{NAME} was been kicked due to excessive ping",				"Public kick message. {NAME} converts to the player's name.", FCVAR_PLUGIN);
	cvar_ImmunityFlag = CreateConVar("sm_vbping_immunityflag",		"a",				"SourceMod admin flag used to grant immunity to all ping checking/kicking", FCVAR_PLUGIN);

	// Hook changing of the ping checking rate cvar
	HookConVarChange(cvar_CheckRate, action_RateChanged);

	// Make that config!
	AutoExecConfig(true, "vbping");

	// Enable logging
	BuildPath(Path_SM, Logfile, sizeof(Logfile), "logs/vbping.log");

	// Start the timer
	PingTimer = CreateTimer(GetConVarFloat(cvar_CheckRate), timer_CheckPing, INVALID_HANDLE, TIMER_REPEAT);

	// Initialize everyone's warnings at 0
	new maxplayers = GetMaxClients();
	for (new i = 1; i <= maxplayers; i++)
	{
		PingWarnings[i] = 0;
		PingDelay[i] = true;
	}

	// Delay ping checking for 90 seconds to allow pings to normalize
	TimerCheck = true;
	CreateTimer(GetConVarFloat(cvar_MinTime), timer_EnableCheck);
}

// Reset all players' warnings to 0, grant all players connection immunity,
// and restart ping checking timer in case one is already running.

public OnMapStart()
{
	for (new i = 1; i <= MaxClients; i++)
	{
		PingWarnings[i] = 0;
		PingDelay[i] = true;
	}

	if (PingTimer == INVALID_HANDLE)
		PingTimer = CreateTimer(GetConVarFloat(cvar_CheckRate), timer_CheckPing, INVALID_HANDLE, TIMER_REPEAT);

	// Delay ping checking for 90 seconds to allow pings to normalize
	TimerCheck = true;
	CreateTimer(GetConVarFloat(cvar_MinTime), timer_EnableCheck);
}

// Print debug information
public Action:cmd_Debug(client, args)
{
	PrintToConsole(client, "[SM] Very Basic High Ping Kicker Debug");

	new Players = 0;
	new Float:Ping;

	// Admin flag immunity
	new String:Flag[16];
	GetConVarString(cvar_ImmunityFlag, Flag, sizeof(Flag));

	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			Players++;
			Ping = GetClientAvgLatency(i, NetFlow_Outgoing) * 1024;
			
			if ((GetUserFlagBits(i) & ReadFlagString(Flag)) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
				PrintToConsole(client, " . %-32N Ping: %-8.0f *IMMUNE*", i, Ping);
			else if (PingDelay[i])
				PrintToConsole(client, " . %-32N Ping: %-8.0f *CONNECTING*", i, Ping);
			else
				PrintToConsole(client, " . %-32N Ping: %-8.0f Warnings: %i", i, Ping, PingWarnings[i]);
		}
	}
	
	// If the number of players is less than the minimum set by the plugin, then report it.
	new MinPlayers = GetConVarInt(cvar_MinPlayers);
	if (Players < MinPlayers)
		PrintToConsole(client, "[SM] Minimum players not met! %i / %i", Players, MinPlayers);

	return Plugin_Handled;
}

// Initialize client's warnings to 0 when they connect and grant them
// connection grace period.

public OnClientPostAdminCheck(client)
{
	PingWarnings[client] = 0;
	PingDelay[client] = true;
	CreateTimer(GetConVarFloat(cvar_MinTime), timer_ExpirePingDelay, client);
}

// Enable ping checking again, after the map change delay.
public Action:timer_EnableCheck(Handle:timer)
{
	TimerCheck = false;

	for (new i = 1; i <= MaxClients; i++)
	{
		PingWarnings[i] = 0;
		PingDelay[i] = false;
	}
}

// Enable ping checking after client has connected and their
// grace period has expired.

public Action:timer_ExpirePingDelay(Handle:timer, any:client)
{
	PingDelay[client] = false;
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

// Check the ping!
public Action:timer_CheckPing(Handle:timer)
{
	// If the map has recently changed, quit all ping checking
	if (TimerCheck)
		return;

	new String:Message[512];
	new String:SteamID[64];
	new String:Name[MAX_NAME_LENGTH];
	new Float:Ping;

	// Admin flag immunity
	new String:Flag[16];
	GetConVarString(cvar_ImmunityFlag, Flag, sizeof(Flag));

	// First, let's get a count of the players in-game.
	new Players = 0;
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
			Players++;
	}

	// If the number of players is less than the minimum set by the plugin,
	// then quit out.

	if (Players < GetConVarInt(cvar_MinPlayers))
		return;

	// Perform the actual ping checking and warn issuing.
	for (new i = 1; i <= MaxClients; i++)
	{
		if (IsClientConnected(i) && IsClientInGame(i) && !IsFakeClient(i))
		{
			// If the client has been connected for less time than the
			// minimum set by the plugin, ignore them.

			if (PingDelay[i])
				continue;

			GetClientAuthString(i, SteamID, sizeof(SteamID));
			GetClientName(i, Name, sizeof(Name));

			// If the client has exceeded the number of warnings, kick them.
			// This is done before giving a warnings, so they are not warned
			// their final time, and then kicked for it.

			if (PingWarnings[i] >= GetConVarInt(cvar_MaxWarnings))
			{
				GetConVarString(cvar_KickMsg, Message, sizeof(Message));
				KickClient(i, Message);

				if (GetConVarBool(cvar_ShowPublicKick))
				{
					GetConVarString(cvar_KickMsgPublic, Message, sizeof(Message));
					ReplaceString(Message, sizeof(Message), "{NAME}", Name, true);
					PrintToChatAll("%s", Message);
				}

				if (GetConVarBool(cvar_LogActions))
					LogToFile(Logfile, "%N [%s] has been kicked, excessive ping warnings (%i)", i, SteamID, PingWarnings[i]);

				PingWarnings[i] = 0;
				continue;
			}

			// If the client's ping exceedes the maximum set by the plugin,
			// give them a warning.

			Ping = GetClientAvgLatency(i, NetFlow_Outgoing) * 1024;
			if (Ping > GetConVarInt(cvar_MaxPing))
			{
				// If the client has the immunity or ROOT flag, ignore them
				if ((GetUserFlagBits(i) & ReadFlagString(Flag)) || (GetUserFlagBits(i) & ADMFLAG_ROOT))
					continue;

				// If not, then give them the warning
				PingWarnings[i] = PingWarnings[i] + 1;

				// Tell the player they received a ping warning
				if (GetConVarBool(cvar_ShowWarnings))
				{
					new String:tmp[32];
					GetConVarString(cvar_WarningMsg, Message, sizeof(Message));

					IntToString(PingWarnings[i], tmp, sizeof(tmp));
					ReplaceString(Message, sizeof(Message), "{WARN}", tmp, true);

					GetConVarString(cvar_MaxWarnings, tmp, sizeof(tmp));
					ReplaceString(Message, sizeof(Message), "{MAXWARN}", tmp, true);

					PrintToChat(i, "%s", Message);
				}

				// Log the warning to the ping log
				if (GetConVarBool(cvar_LogActions))
					LogToFile(Logfile, "%N has %i ping warning (Ping: %f)", i, PingWarnings[i], Ping);
			}
		}
	}
}
