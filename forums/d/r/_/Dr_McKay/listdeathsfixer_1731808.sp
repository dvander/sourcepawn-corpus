#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name = "listdeaths exploit fixer",
	author = "Dr. McKay",
	description = "Fixes the listdeaths exploit",
	version = PLUGIN_VERSION,
	url = "http://www.doctormckay.com"
};

public OnPluginStart() {
	AddCommandListener(Command_ListDeaths, "listdeaths");
	CreateConVar("sm_listdeaths_fixer_version", PLUGIN_VERSION, "listdeaths Fixer Version", FCVAR_NOTIFY|FCVAR_CHEAT);
}

public Action:Command_ListDeaths(client, const String:command[], argc) {
	return Plugin_Handled;
}