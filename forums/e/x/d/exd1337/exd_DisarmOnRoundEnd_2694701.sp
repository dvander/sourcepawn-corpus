#pragma semicolon 1

#define DEBUG

#define PLUGIN_NAME "RmvWeaponOnRoundEnd"
#define PLUGIN_AUTHOR "exd"
#define PLUGIN_VERSION "1.51"
#define PLUGIN_DESCRIPTION "Remove all weapons of all players when round end"
#define PLUGIN_URL "https://steamcommunity.com/id/exd1337/"

#include <sourcemod>
#include <sdktools>
#include <cstrike>
#include <entity>

#pragma newdecls required

//GLOBAL VARIABLES
int gB_IsRoundOver = false;

public Plugin myinfo = 
{
	name = PLUGIN_NAME,
	author = PLUGIN_AUTHOR,
	description = PLUGIN_DESCRIPTION,
	version = PLUGIN_VERSION,
	url = PLUGIN_URL
};

public void OnPluginStart()
{
	HookEvent("round_end", Event_RoundEnd);
	HookEvent("round_start", Event_RoundStart);
	HookEvent("item_pickup", Event_ItemPickUp);
}

public void Event_RoundStart(Handle event, char[] name, bool dontBroadcast)
{
	gB_IsRoundOver = false;
}

public void Event_RoundEnd(Handle event, char[] name, bool dontBroadcast)
{
	CreateTimer(1.0, timer_WaitToRoundEnd);
	gB_IsRoundOver = true;
}

public void Event_ItemPickUp(Handle event, char[] name, bool dontBroadcast)
{
	if (gB_IsRoundOver)
	{
		for (int s = 0; s <= 4; s++)
		{
			EmptySlot(GetClientOfUserId(GetEventInt(event, "userid")), s);
		}
	}
}

public Action timer_WaitToRoundEnd(Handle timer, any client)
{
	for (int iClient = 1; iClient <= MaxClients; iClient++)
	{
		if (IsClientInGame(iClient))
		{
			for (int iSlot = 0; iSlot <= 4; iSlot++)
			{
				EmptySlot(iClient, iSlot);
			}
		}
	}
}

stock void EmptySlot(int client, int slot)
{
    int item;
    while((item = GetPlayerWeaponSlot(client, slot)) != -1)
    {
        RemovePlayerItem(client, item);
        RemoveEntity(item);
    }
}