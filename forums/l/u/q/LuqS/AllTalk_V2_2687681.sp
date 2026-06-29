#include <sourcemod>
#include <sdktools>
#include <cstrike>

#define PREFIX " \x02[All Talk]\x01"
#define DEBUG

#pragma newdecls required
#pragma semicolon 1

bool g_bActive[MAXPLAYERS];

public Plugin myinfo = 
{
	name = "[TTT] All-Talk For Admins",
	author = "Natanel \"LuqS\"",
	description = "Allows admins to talk to the whole server when they are dead.",
	version = "1.0",
	url = "https://steamcommunity.com/id/LuqSGood"
};

public void OnPluginStart()
{
	if(GetEngineVersion() != Engine_CSGO)
		SetFailState("This plugin is for CSGO only.");

	RegAdminCmd("sm_at", Command_AllTalk, ADMFLAG_KICK, "Allowing the admin to toggle voice channels (between all server channel & dead channnel)");
	HookEvent("player_spawned", Event_PlayerRespawned);
}

public void OnClientDisconnect(int client)
{
    ToggleListen(client, false);
}

public Action Command_AllTalk(int client, int args)
{
    if(IsPlayerAlive(client))
    {
        PrintToChat(client, "%s You may only use this \x0Ecommand\x01 when you are \x04dead\x01.", PREFIX);
        return Plugin_Handled;
    }
    
    ToggleListen(client, !g_bActive[client]);

    PrintToChat(client, "%s All-Talk Power %s\x01.", PREFIX, g_bActive[client] ? "\x04ON" : "\x02OFF");
    return Plugin_Handled;
}

public Action Event_PlayerRespawned(Event event, const char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(event.GetInt("userid"));
    
    if (!IsValidClient(client))
    	return Plugin_Continue;

    if(g_bActive[client])
        ToggleListen(client, false);

    return Plugin_Continue;
}

void ToggleListen(int iTarget, bool bCanListen) 
{
	if (!IsValidClient(iTarget))
		return;

	g_bActive[iTarget] = bCanListen;

	for (int iCurrentClient = 1; iCurrentClient <= MaxClients; iCurrentClient++)
		if (IsClientInGame(iCurrentClient) && iCurrentClient != iTarget)
			SetListenOverride(iCurrentClient, iTarget, bCanListen ? Listen_Yes : Listen_Default);
}


// Checking if the sent client is valid based of the parmeters sent and other other functions.
stock bool IsValidClient(int client, bool bAllowBots = false, bool bAllowDead = true)
{
	if (!(1 <= client <= MaxClients) || !IsClientInGame(client) || IsClientSourceTV(client) || IsClientReplay(client) || (IsFakeClient(client) && !bAllowBots) || (!bAllowDead && !IsPlayerAlive(client)))
		return false;
	return true;
}