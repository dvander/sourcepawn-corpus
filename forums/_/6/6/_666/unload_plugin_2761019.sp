#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

char PLUGIN[32] = "discord_api";

public Plugin myinfo = {
	name = "unload_plugin",
	author = "Nullifidian",
	description = "unload_plugin",
	version = "1.0",
	url = ""
};

int g_iTime;
char ga_sLogFilePath[PLATFORM_MAX_PATH];

public void OnPluginStart() {
	g_iTime = GetTime();
	BuildPath(Path_SM, ga_sLogFilePath, sizeof(ga_sLogFilePath), "logs/unload_plugin.log");
	HookEvent("game_end", Event_GameEnd, EventHookMode_PostNoCopy);
}

public void Event_GameEnd(Event event, const char[] name, bool dontBroadcast) {
	int iTime = GetTime();
	if (((iTime - g_iTime) / 3600) >= 6) {	//unload every 6 hours
		g_iTime = iTime;
		LogToFile(ga_sLogFilePath,"Executing cmd: sm plugins unload %s", PLUGIN);
		ServerCommand("sm plugins unload %s", PLUGIN);
	}
}