#pragma semicolon 1

#define DEBUG

#define PLUGIN_AUTHOR ""
#define PLUGIN_VERSION "0.00"

#include <sourcemod>
#include <sdktools>

#pragma newdecls required

public Plugin myinfo = 
{
	name = "",
	author = PLUGIN_AUTHOR,
	description = "",
	version = PLUGIN_VERSION,
	url = ""
};

public void OnPluginStart()
{
	HookEvent("round_start", OnRoundStart);
}
public Action OnRoundStart(Event event, const char[] name, bool dontBroadcast)
{
	for (int i = 1; i <= MaxClients; i++) 
    { 
        if (IsClientInGame(i)&&!IsFakeClient(i))
        	RemoveExtraKnives(i);	
    }
}
public void RemoveExtraKnives(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 2);
   	while (weapon!= -1)
   	{
        RemovePlayerItem(client, weapon);
        weapon = GetPlayerWeaponSlot(client, 2);
    }
    	GivePlayerItem(client, "weapon_knife");
}	
