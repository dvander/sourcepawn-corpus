#pragma semicolon 1

#include <sourcemod>

#define PLUGIN_VERSION "1.0.0"


public Plugin:myinfo = 
{
	name = "Steam ID In Console On Connect",
	author = "Dr. McKay",
	description = "Displays a client's Steam ID in the server console when they connect.",
	version = PLUGIN_VERSION,
	url = "http://www.doctormckay.com"
}

public OnPluginStart()

{
	CreateConVar("sm_consolesteamid_version", PLUGIN_VERSION, "Steam ID In Console On Connect", FCVAR_PLUGIN|FCVAR_SPONLY|FCVAR_REPLICATED|FCVAR_NOTIFY);
}

public OnClientAuthorized(client, const String:auth[])
{
	decl String:ip[30]; // 17 is enough
	GetClientIP(client,ip,sizeof(ip),false);
	PrintToServer("Client \"%N\" [%s] (%s) authorized!", client, auth, ip);
}