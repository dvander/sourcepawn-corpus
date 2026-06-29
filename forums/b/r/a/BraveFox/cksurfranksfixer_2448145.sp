#include <sourcemod>

#pragma semicolon 1
#pragma newdecls required

public Plugin myinfo = {
	name        = "CKSurf - Rank Fixer",
	author      = "BraveFox",
	description = "Fixes the score+ranks on cksurf servers",
	version     = "1.0",
	url         = ""
};

public void OnPluginStart()
{
}

public void OnClientPutInServer(int client)
{
    ServerCommand("sm_refreshprofile %N", client);
    ServerCommand("sm_refreshprofile %n", client);
    ServerCommand("sm_refreshprofile %s", client);
}