#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR "xoxo^^"
#define PLUGIN_VERSION "NULL"

#include <sourcemod>
#include <sdktools>
#include <cstrike>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "UserID ClientTag",
	author = PLUGIN_AUTHOR,
	description = "Sets the user client tag to its userid.",
	version = PLUGIN_VERSION,
	url = "https://steamcommunity.com/id/bar36892/"
};

public void OnPluginStart() {
    CreateTimer(0.1, SetClients, _, TIMER_REPEAT);
}

public Action SetClients(Handle timer) {
    for (int i = 1; i <= MaxClients; i++)
        if(IsValidClient(i))
            SetUserID(i);
}

public void SetUserID(int client) {
    int UserID = GetClientUserId(client);
    char temp[32];
    Format(temp, sizeof(temp), "[#%d]", UserID);
    CS_SetClientClanTag(client, temp);
}

public bool IsValidClient(int client) {
    if (IsClientInGame(client) && IsClientConnected(client) && client > 0 && client <= MaxClients)
        return true;
    return false;
}