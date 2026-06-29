#pragma semicolon 1

#define PLUGIN_VERSION		"1.0"


#undef REQUIRE_EXTENSIONS
#include <cstrike>
#define REQUIRE_EXTENSIONS


#include <sourcemod>


	public Plugin:myinfo = {
    name = "Steam id Rus",
    author = "Aftersoft",
    description = "Steam ID On Connect Rus SourceMod",
    version = PLUGIN_VERSION,
    url = "http://aftersoft.ru/"
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
	PrintToChatAll("\x01 %s , Steam ID: \x04 %s \x01 присоединился к игре", name, steamid);
	
}

public OnClientDisconnect(client) {
	
	new String:name[64];
	decl String:steamid[32];
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthString(client, steamid, sizeof(steamid));
	PrintToChatAll("\x01 %s , Steam ID: \x04 %s \x01 покинул игру.", name, steamid);
	
}
