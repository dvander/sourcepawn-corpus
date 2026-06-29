#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "cow"
#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "clientcommand",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnClientPutInServer(int client)
{
	FakeClientCommand(client, ".setup");
}
