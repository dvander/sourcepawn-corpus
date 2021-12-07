#pragma semicolon 1
#include <sourcemod>

#define LOG_FILE "eventdebug.log"

#define PLUGIN_VERSION "1.0"

public Plugin:myinfo =
{
	name = "LogUpload Event Debug",
	author = "Nikki",
	description = "Logs certain game events to file in an attempt to figure out issues with other plugins",
	version = PLUGIN_VERSION,
	url = "http://nikkii.us"
};


public OnPluginStart() {
	LogToFileEx(LOG_FILE, "Plugin loading");
	
	// Events for round status
	HookEvent("teamplay_round_active", LogEvent);
	HookEvent("teamplay_round_win", LogEvent);
	HookEvent("teamplay_setup_finished", LogEvent);
	HookEvent("teamplay_restart_round", LogEvent);
	
	// Events for game end
	HookEvent("teamplay_game_over", LogEvent);
	HookEvent("tf_game_over", LogEvent);
	
	// Hook for 'log' command
	AddCommandListener(Listener_Log, "log");
}

public OnPluginEnd() {
	LogToFileEx(LOG_FILE, "Plugin unloading");
}

public OnMapStart() {
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));
	LogToFileEx(LOG_FILE, "Map started: %s", map);
}

public OnMapEnd() {
	decl String:map[128];
	GetCurrentMap(map, sizeof(map));
	LogToFileEx(LOG_FILE, "Map ended: %s", map);
}

public LogEvent(Handle:event, const String:name[], bool:dontBroadcast) {
	LogToFileEx(LOG_FILE, "Event was triggered : \"%s\"", name);
}

public Action:Listener_Log(client, const String:command[], args) {
	if(args == 0) {
		LogToFileEx(LOG_FILE, "Log status was checked");
	} else if(args == 1) {
		decl String:temp[10];
		GetCmdArgString(temp, sizeof(temp));
		LogToFileEx(LOG_FILE, "Log status was changed to \"%s\"", temp);
	}
	return Plugin_Continue;
}