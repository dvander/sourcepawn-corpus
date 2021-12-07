#pragma semicolon 1

#define PLUGIN_AUTHOR "Classic"
#define PLUGIN_VERSION "1.0"

#include <sourcemod>
#include <sdktools>
#include <tf2>
#include <tf2_stocks>
#include <sdkhooks>

public Plugin myinfo = 
{
	name = "[TF2] Teammate Outlines",
	author = PLUGIN_AUTHOR,
	description = "Enable outlines that are onli visible for teammates.",
	version = PLUGIN_VERSION,
	url = ""
};

public OnClientPutInServer(client)
{
	SDKHook(client, SDKHook_SetTransmit, Hook_SetTransmit);
}

public Action:Hook_SetTransmit(entity, client)
{
    if(IsValidAliveClient(entity) && IsValidAliveClient(client))
    {
        if (GetClientTeam(entity) == GetClientTeam(client))
        {
           SetEntProp(entity, Prop_Send, "m_bGlowEnabled", 1);	
        }
        else
        {
           SetEntProp(entity, Prop_Send, "m_bGlowEnabled", 0);	
        }
    }
    return Plugin_Continue;
}

stock bool IsValidAliveClient(int client)
{
	if(client < 0 || client > MaxClients || !IsClientConnected(client) ||	!IsClientInGame(client) || !IsPlayerAlive(client))
			return false;
	return true;
}