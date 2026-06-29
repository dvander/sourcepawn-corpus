#pragma semicolon 1

#define DEBUG

#include <sourcemod>
#include <sdktools>

#pragma newdecls required
int RemoveCounter[MAXPLAYERS + 1];
public Plugin myinfo = 
{
	name = "RemoveExtraKnives",
	author = "SheriF",
	description = "Auto strip extra knives on round start from all players",
	version = "1.1",
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
        if (IsClientInGame(i)&&!IsFakeClient(i)&&IsPlayerAlive(i))
        {
        	RemoveCounter[i] = 0;
        	RemoveExtraKnives(i);
		}
    }
}
public void RemoveExtraKnives(int client)
{
	int weapon = GetPlayerWeaponSlot(client, 2);
   	while (weapon!= -1)
   	{
        RemovePlayerItem(client, weapon);
        weapon = GetPlayerWeaponSlot(client, 2);
        RemoveCounter[client]++;
    }
    	if(RemoveCounter[client]>0)
    	GivePlayerItem(client, "weapon_knife");
}	
