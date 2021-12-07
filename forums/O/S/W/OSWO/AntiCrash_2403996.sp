#pragma semicolon 1

#define DEBUG

#define PLUGIN_VERSION "1.00"

#include <sourcemod>
#include <sdktools>

int g_ClientChanges[MAXPLAYERS + 1];

public Plugin myinfo = 
{
	name = "Anti-Crash",
	author = "Oscar Wos (OSWO)",
	description = "Anti-Crash",
	version = PLUGIN_VERSION,
	url = "www.tangoworldwide.net"
};

public void OnPluginStart()
{
	CreateTimer(2.0, timer_check, _, TIMER_REPEAT);
}

public void OnClientSettingsChanged(int client)
{
	if (IsValidPlayer(client)) 
		g_ClientChanges[client]++;
}

public OnClientConnected(int client)
{
    g_ClientChanges[client] = 0;
}

public Action timer_check(Handle timer)
{
	for (int i = 1; i < MaxClients; i++)
	{
		if (IsValidPlayer(i))
		{
			if (g_ClientChanges[i] > 5)
			{
				char iName[64], iSteamID[64], iIP[64];
				GetClientName(i, iName, sizeof(iName));
				GetClientAuthId(i, AuthId_Engine, iSteamID, sizeof(iSteamID), true);
				GetClientIP(i, iIP, sizeof(iIP), true);
				
				LogToFileEx("addons/sourcemod/logs/Crash.txt", "Player: %s, ID: %s, IP: %s", iName, iSteamID, iIP);
				
				KickClient(i, "You're requesting too many Client Changes!");
			}
			
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