#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"

public Plugin:myinfo = {
	name        = "[ANY] No Ping Spam",
	author      = "Dr. McKay",
	description = "Prevents players from spamming the \"ping\" or \"status\" commands",
	version     = PLUGIN_VERSION,
	url         = "http://www.doctormckay.com"
};

new lastUsedTime[MAXPLAYERS + 1];

public OnPluginStart() {
	RegConsoleCmd("status", Command_Status);
	RegConsoleCmd("ping", Command_Status);
}

public Action:Command_Status(client, args) {
	if(lastUsedTime[client] > GetTime() - 10) {
		return Plugin_Handled;
	}
	lastUsedTime[client] = GetTime();
	return Plugin_Continue;
}