#include <sourcemod>

#define FILE "ff2_events.log"
#define TIME_FORMAT "%H:%M:%S"
#define TIME_FORMAT_LENGTH 9

public Plugin:myinfo = 
{
	name = "FF2 Event Logging",
	author = "Powerlord",
	description = "Creates a log for Powerlord with certain event info",
	version = "1.0",
	url = "<- URL ->"
}

public OnPluginStart()
{
	HookEvent("teamplay_round_start", Event_Start);
	HookEvent("arena_round_start", Event_Start);
	HookEvent("teamplay_round_win", Event_Win);
	HookEvent("teamplay_win_panel", Event_Win);
	HookEvent("arena_win_panel", Event_Win);
}

public Event_Start(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:time[TIME_FORMAT_LENGTH];
	FormatTime(time, sizeof(time), TIME_FORMAT);
	LogToFile(FILE, "[%s] %s called", time, name);
}

public Event_Win(Handle:event, const String:name[], bool:dontBroadcast)
{
	decl String:time[TIME_FORMAT_LENGTH];
	FormatTime(time, sizeof(time), TIME_FORMAT);
	new winreason = GetEventInt(event, "winreason");
	LogToFile(FILE, "[%s] %n called with winreason %d", time, name, winreason);
}
