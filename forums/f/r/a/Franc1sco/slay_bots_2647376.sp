#pragma semicolon 1
#include <sourcemod>
#include <sdktools>

#pragma newdecls required // let's go new syntax!

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
}

// check for disconnect cases too
public void OnClientDisconnect(int iClient)
{
	if (!IsFakeClient(iClient) && AllHumansDead())
    {
        SlayBots();
    }
}

public Action Event_PlayerDeath(Handle event, char[] name, bool dontBroadcast)
{
    int client = GetClientOfUserId(GetEventInt(event, "userid"));
    
    if (!IsFakeClient(client) && AllHumansDead())
    {
        SlayBots();
    }
}

bool AllHumansDead()
{
    bool result = true;
    
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && !IsFakeClient(i) && IsPlayerAlive(i)) // Thanks Black-Rabbit
        {
            result = false;
        }
    }
    
    return result;
}

void SlayBots()
{
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i) && IsPlayerAlive(i))
        {
            ForcePlayerSuicide(i);
        }
    }
}  