
#include <sourcemod>

new bool:plugin_debug;
new lastRestartTime;

new Handle:cv_restartinterval;
new Handle:cv_checkinterval;
new Handle:cv_maxplayers;
new Handle:cv_debug;

new Handle:timer_checkrestart;

new String:kv_path[128];

#define KV_FILE "autoquit.kv"

#define WARNING_TIME 10.0

#define VERSION "2010-11-14b"


public Plugin:myinfo = 
{
	name = "Autoquit plugin",
	author = "novadenizen@gmail.com",
	description = "Makes a server quit (and presumably restart) after it empties",
	version = VERSION,
	url = "http://www.teaminterrobang.com"
}

public OnPluginStart()
{
	new cvflags = (FCVAR_PLUGIN | FCVAR_PROTECTED);
	cv_restartinterval = CreateConVar("sm_autoquit_restartinterval", "7200", "Seconds to wait before restarting again", cvflags);
	cv_checkinterval = CreateConVar("sm_autoquit_checkinterval", "600", "Seconds to wait between checking appropriateness for restart", cvflags);
	cv_maxplayers = CreateConVar("sm_autoquit_maxplayers", "0", "Server may restart with this many players or fewer");
	cv_debug = CreateConVar("sm_autoquit_debug", "0", "Debug flag for autoquit plugin", cvflags);
	
	CreateConVar("sm_autoquit_version", VERSION, "Public cvar for tracking", cvflags | FCVAR_NOTIFY);
	
	lastRestartTime = -1;
	timer_checkrestart = INVALID_HANDLE;
	BuildPath(Path_SM, kv_path, sizeof(kv_path), "data/%s", KV_FILE);
	AutoExecConfig();
	plugin_debug = false;
}



public OnConfigsExecuted() {
	plugin_debug = GetConVarBool(cv_debug);
	if (plugin_debug) {
		LogMessage("kv_path is %s", kv_path);
	}
	HookConVarChange(cv_restartinterval, timeParamChanged);
	HookConVarChange(cv_checkinterval, timeParamChanged);
	HookConVarChange(cv_debug, debugchanged);
	// setup the timer, but don't actually call checkRestart
	// don't want to restart while people are trying to come in
	setupTimer();
}

public debugchanged(Handle:cv, String:old[], String:newval[]) {
	plugin_debug = GetConVarBool(cv_debug);
	LogMessage("debug flag is now %d", plugin_debug);
}
	

public timeParamChanged(Handle:cv, String:oldval[], String:newval[]) {
	if (plugin_debug) {
		LogMessage("timeParamChanged()");
	}

	//in this case we want to reset the timer and perform the check
	setupTimer();
	PerformRestartCheck();		
}

public setupTimer() {
	if (timer_checkrestart != INVALID_HANDLE) {
		if (plugin_debug) {
			LogMessage("closing out old timer");
		}
		CloseHandle(timer_checkrestart);
	}
	new Float:interval = GetConVarFloat(cv_checkinterval);
	if (plugin_debug) {
		LogMessage("in setupTimer(), interval=%f", interval);
	}
	timer_checkrestart = CreateTimer(interval,
					timer_PerformRestartCheck, 
					INVALID_HANDLE,
					TIMER_REPEAT);
}


readLastRestartTime() {
	if (lastRestartTime != -1) return; // don't want to do this over and over again
	new Handle:kv = CreateKeyValues("root");
	new bool:success;
	success = FileToKeyValues(kv, kv_path);
	if (!success) {
		if (plugin_debug) {
			LogMessage("Reading kv was unsuccessful, creating a new one");	
		}
		saveNewRestartTime();
		success = FileToKeyValues(kv, kv_path);
	}
	new lastquit = KvGetNum(kv, "lastquit", 0); 
	if (plugin_debug) {
		new String:timebuf[50];
		FormatTime(timebuf, sizeof(timebuf), "%c", lastquit);
		LogMessage("KvGetNum returned %d (%s)", lastquit, timebuf);
	}
	CloseHandle(kv);
	lastRestartTime = lastquit;
	
}

saveNewRestartTime() {
	new Handle:kv = CreateKeyValues("root");
	new quittime = GetTime();
	KvSetNum(kv, "lastquit", GetTime());
	new bool:success;
	success = KeyValuesToFile(kv, kv_path);
	if (plugin_debug) {
		new String:timebuf[50];
		FormatTime(timebuf, sizeof(timebuf), "%c", quittime);
		LogMessage("saving new restart time of %d (%s)", quittime, timebuf);
		LogMessage("save success: %d", success);
	}
	CloseHandle(kv);	
}

public Action:timer_PerformRestartCheck(Handle:timer) {
	if (plugin_debug) {
		LogMessage("timer_PerformRestartCheck()");
	}
	PerformRestartCheck();
	return Plugin_Continue;
}


bool:isPlayingClient(client) {
        return client > 0 && client < MaxClients && IsClientInGame(client) && !IsFakeClient(client);
}

public countPlayers() {
	new numPlayers = 0;
	new i;
        for(i = 1; i < MaxClients; i++) {
                if (isPlayingClient(i)) {
                        numPlayers++;
                }
        }
	if (plugin_debug) {
		LogMessage("counted %d players on the server", numPlayers);
	}
	return numPlayers;
}

	
PerformRestartCheck() {
	if (plugin_debug) {
		LogMessage("PerformRestartCheck()");
	}
	readLastRestartTime();
	new restartinterval = GetConVarInt(cv_restartinterval); 
	new now = GetTime();
	if (plugin_debug) {
		LogMessage("now=%d, restartinterval=%d, lastRestartTime=%d",
			now, restartinterval, lastRestartTime);
	}
	if (lastRestartTime + restartinterval > now) {
		if (plugin_debug) {
			LogMessage("too early to restart");
		}
		return;
	}
	new maxplayers = GetConVarInt(cv_maxplayers);
	new curplayers = countPlayers();
	if (plugin_debug) {
		LogMessage("maxplayers=%d, curplayers=%d", maxplayers, curplayers);
	}
	if (curplayers > maxplayers) {
		if (plugin_debug) {
			LogMessage("would restart but too many players are in server");
		}
		return;
	} 

	// all conditions are met, so restart
	SetupRestart();
}

SetupRestart() {
	PrintCenterTextAll("Restarting server in %f seconds", WARNING_TIME);
	CreateTimer(WARNING_TIME, ActuallyRestart);
}

public Action:ActuallyRestart(Handle:timer) {
	PrintCenterTextAll("Restarting");
	LogAction(-1, -1, "Autoquit plugin is Restarting server");
	saveNewRestartTime();
	// this is just for debugging, really
	lastRestartTime = GetTime();	
	ServerCommand("quit");
	return Plugin_Continue;
}

