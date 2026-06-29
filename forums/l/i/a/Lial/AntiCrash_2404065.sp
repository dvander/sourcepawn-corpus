#pragma semicolon 1

#include <sourcemod>
#include <sdktools>

int g_ClientChanges[MAXPLAYERS + 1];


public void OnPluginStart()
{
	CreateTimer(2.0, timer_check, _, TIMER_REPEAT);
}

public void OnClientSettingsChanged(int client)
{
	if (IsValidPlayer(client)) 
	{
		g_ClientChanges[client]++;
		if (g_ClientChanges[client] > 5)
			{
				char iName[64], iSteamID[64], iIP[64];
				GetClientName(client, iName, sizeof(iName));
				GetClientAuthId(client, AuthId_Engine, iSteamID, sizeof(iSteamID), true);
				GetClientIP(client, iIP, sizeof(iIP), true);
				
				LogToFileEx("addons/sourcemod/logs/Crash.txt", "Player: %s, ID: %s, IP: %s", iName, iSteamID, iIP);
				
				KickClient(client, "You're requesting too many Client Changes!");
			}
	}
}

public OnClientConnected(int client)
{
    g_ClientChanges[client] = 0;
}

public Action timer_check(Handle timer)
{
	for (int i = 1; i <= MaxClients; i++)
	{
		if (IsValidPlayer(i))
		{			
			g_ClientChanges[i] = 0;
		}
	}
}

stock bool IsValidPlayer(int client, bool alive = false)
{
    if(client >= 1 && client <= MaxClients && IsClientConnected(client) && IsClientInGame(client) && (alive == false || IsPlayerAlive(client)))
		return true;
		
    return false;
}