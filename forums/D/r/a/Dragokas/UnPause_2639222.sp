#define PLUGIN_VERSION		"0.1"

#pragma semicolon 1
#pragma newdecls required

#include <sourcemod>

public Plugin myinfo = {
	name = "UnPause",
	author = "Dragokas",
	description = "UnPause the game when player is trying to connect",
	version = PLUGIN_VERSION,
	url = "https://github.com/dragokas"
}

public void OnPluginStart() {
	CreateConVar("sm_unpause_version", PLUGIN_VERSION, "Plugin version", FCVAR_DONTRECORD);
	AddCommandListener(Listener_Pause, "pause");
}

public Action Listener_Pause(int client, char[] command, int args)
{
	return  Plugin_Stop;
}
