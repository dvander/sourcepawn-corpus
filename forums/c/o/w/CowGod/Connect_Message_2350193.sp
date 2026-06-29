#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "Cow"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>
#include <geoip>

public Plugin myinfo = 
{
	name = "Connect Message", 
	author = PLUGIN_AUTHOR, 
	description = "When a player connects a message appears with their information", 
	version = PLUGIN_VERSION, 
	url = ""
};

public void OnClientPutInServer(client)
{
	char name[32],authid[64];
	
	GetClientName(client, name, sizeof(name));
	GetClientAuthId(client, AuthId_SteamID64, authid, sizeof(authid));
	
	PrintToChatAll("\x01[SM] \x04%s\x01 (\x05%s\x01) has joined the server.", name, authid);
} 