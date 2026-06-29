#pragma semicolon 1

#define PLUGIN_VERSION		"1.0"


#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS

#define MAX_AUTHID_LENGTH	20

#include <sourcemod>
#include <sdktools>
#include <topmenus>
#include <menus>
#include <timers>
#include "cstrike.inc"

	public Plugin:myinfo = {
    name = "Steam id",
    author = "Linuxovore",
    description = "say steam id for SourceMod",
    version = PLUGIN_VERSION,
    url = "http://linuxovore.com/"
};


public OnPluginStart()
{	
    
	CreateConVar("sm_steam_id", PLUGIN_VERSION, "Say steam id", FCVAR_PLUGIN|FCVAR_NOTIFY|FCVAR_DONTRECORD);
}
//------------------------------------------------------------------------------------------------------------------------------------------


public OnClientPutInServer(client) {
	
	new String:name[64];
	decl String:steamid[32];
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthString(client, steamid, sizeof(steamid));
	PrintToChatAll("\x01 %s , Steam ID: \x04 %s \x01 join the game", name, steamid);
	
}

public OnClientDisconnect(client) {
	
	new String:name[64];
	decl String:steamid[32];
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthString(client, steamid, sizeof(steamid));
	PrintToChatAll("\x01 %s , Steam ID: \x04 %s \x01 leaves the games", name, steamid);
	
}