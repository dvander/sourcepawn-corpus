#include <sourcemod>
#include <sdktools>

#pragma semicolon 1
#pragma newdecls required

char g_LastPlayerName[MAX_NAME_LENGTH];

public Plugin myinfo = 
{
	name = "Show Last Joiner",
	author = "stephen473",
	description = "A simple plugin for showing last joiner",
	version = "1.0",
	url = "steamcommunity.com/id/kHardy"
};

public void OnPluginStart()
{
	RegAdminCmd("sm_last", showlast, ADMFLAG_GENERIC);
}

public Action showlast(int client, int args)
{
	PrintToChat(client, "The player who joined was %s", g_LastPlayerName);
	return Plugin_Handled;
}

public void OnClientPutInServer(int client)
{
	GetClientName(client, g_LastPlayerName, sizeof(g_LastPlayerName));
}  
