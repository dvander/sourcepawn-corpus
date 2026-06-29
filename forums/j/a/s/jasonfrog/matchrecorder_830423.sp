#include <sourcemod>

#define RED 0
#define BLU 1
#define TEAM_OFFSET 2


public Plugin:myinfo =
{
	name = "Match Recorder",
	author = "carbon",
	description = "Demos are automatically recorded in the tournament mode",
	version = "0.1",
	url = "http://www.funkd.org/"
};



//------------------------------------------------------------------------------
// Variables
//------------------------------------------------------------------------------

new bool:teamReadyState[2] = { false, false };
new bool:recordOnRestart = false;
new bool:recording = false;



//------------------------------------------------------------------------------
// Startup
//------------------------------------------------------------------------------

public OnPluginStart()
{
	// Team status updates
	HookEvent("tournament_stateupdate", TeamStateEvent);

	// Game restart
	HookEvent("teamplay_restart_round", GameRestartEvent);

	// Win conditions met
	HookEvent("teamplay_game_over", GameOverEvent);

	// Hook into mp_tournament_restart
	RegServerCmd("mp_tournament_restart", TournamentRestartHook);
}



//------------------------------------------------------------------------------
// Callbacks
//------------------------------------------------------------------------------

public TeamStateEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	new team = GetClientTeam(GetEventInt(event, "userid")) - TEAM_OFFSET;
	new bool:nameChange = GetEventBool(event, "namechange");
	new bool:readyState = GetEventBool(event, "readystate");

	if (!nameChange)
	{
		teamReadyState[team] = readyState;

		// If both teams are ready wait for round restart to start recording
		if (teamReadyState[RED] && teamReadyState[BLU])
		{
			recordOnRestart = true;
		}
		else
		{
			recordOnRestart = false;
		}
	}
}

public GameRestartEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	// Start recording only if both team are in ready state
	if (recordOnRestart)
	{
		StartRecording();
		recordOnRestart = false;
		teamReadyState[RED] = false;
		teamReadyState[BLU] = false;
	}
}

public GameOverEvent(Handle:event, const String:name[], bool:dontBroadcast)
{
	StopRecording();
}

public Action:TournamentRestartHook(args)
{
	// If mp_tournament_restart is called, stop recording
	if (recording)
	{
		StopRecording();
	}

	return Plugin_Continue;
}

public OnMapStart()
{
	ResetVariables();
	CreateTimer(30.0, CheckPlayers, 0, TIMER_REPEAT|TIMER_FLAG_NO_MAPCHANGE);
}

public OnMapEnd()
{
}

public Action:CheckPlayers(Handle:timer, any:useless) {
	if (recording)
	{
		for(new i=1;i<=MaxClients;i++) {
			if(IsClientConnected(i) && !IsFakeClient(i)) {
				return;
			}
		}
		StopRecording();
	}
}



//------------------------------------------------------------------------------
// Private functions
//------------------------------------------------------------------------------

ResetVariables()
{
	teamReadyState[RED] = false;
	teamReadyState[BLU] = false;
	recordOnRestart = false;
	recording = false;
}

StartRecording()
{
	if (recording)
	{
		PrintToChatAll("Already recording");
		return;
	}

	// Format the demo filename
	new String:timestamp[16];
	new String:map[16];
	new String:filename[40];
	new String:command[64];

	FormatTime(timestamp, 16, "%Y%m%d-%H%M");
	GetCurrentMap(map, 16);
	Format(filename, 40, "%s-%s.dem", timestamp, map);
	Format(command, 64, "tv_record %s", filename);

	// Start recording
	ServerCommand(command);

	PrintToChatAll("Recording started");
	recording = true;
}

StopRecording()
{
	if (recording)
	{
		// Stop recording
		ServerCommand("tv_stoprecord");

		PrintToChatAll("Recording stopped");

		recording = false;
	}
}
