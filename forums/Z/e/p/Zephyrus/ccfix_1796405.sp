#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_NAME "Scoreboard Fix"
#define PLUGIN_AUTHOR "Zephyrus"
#define PLUGIN_DESCRIPTION "Plugin aiming to fix a scoreboard bug in CS:GO"
#define PLUGIN_VERSION "1.0"
#define PLUGIN_URL ""

new Handle:g_hHalfTime = INVALID_HANDLE;

public Plugin:myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public OnPluginStart()
{
	g_hHalfTime = FindConVar("mp_halftime");
}

public OnClientPutInServer(client)
{
	SendConVarValue(client, g_hHalfTime, "1");
}