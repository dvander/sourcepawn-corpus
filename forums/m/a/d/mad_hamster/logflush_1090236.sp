#include <sourcemod>
#include <sdktools>


#define PLUGIN_VERSION "1.01"

public Plugin:myinfo = {
	name = "Log flusher",
	author = "mad_hamster",
	description = "Periodically flushes the log file",
	version = PLUGIN_VERSION,
	url = "http://pro-css.co.il"
};


static Handle:logflush;
static Handle:sv_logflush;
static Handle:timer = INVALID_HANDLE;


public OnPluginStart() {
	CreateConVar("logflush_ver", PLUGIN_VERSION, "", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
	logflush    = CreateConVar("logflush", "600", "0 = disable logflush plugin. Anything else is the number of seconds between log flushes", FCVAR_PLUGIN);
	sv_logflush = FindConVar("sv_logflush");
	AutoExecConfig(); // create config file if doesn't exist
	HookConVarChange(logflush, refresh_timer);
	refresh_timer(logflush, "", "");
}



public refresh_timer(Handle:cvar, const String:oldval[], const String:newval[]) {
	if (timer != INVALID_HANDLE) {
		CloseHandle(timer);
		timer = INVALID_HANDLE;
	}

	if (GetConVarInt(logflush) > 0)
		timer = CreateTimer(GetConVarFloat(logflush), flush_log, _, TIMER_REPEAT);
}



public Action:flush_log(Handle:timer_) {
	if (GetConVarInt(sv_logflush) == 0) {
		SetConVarInt(sv_logflush, 1);
		LogToGame("[SM] Flushing log file..."); // this causes an actual flush
		SetConVarInt(sv_logflush, 0);
	}
}
