#pragma semicolon 1
#include <sourcemod>
#include <tf2>
#include <tf2_stocks>

#define TFCond_Custom 51

public Plugin myinfo =
{
    name = "Hide UberCharge in Respawn Room",
    author = "Your Name",
    description = "A Hidden UberCharge condition is imposed on all players who are in the spawn room.",
    version = "1.0",
    url = "http://yourwebsite.com"
};

public void OnPluginStart()
{
    HookEntityOutput("func_respawnroom", "OnStartTouch", OnStartTouch);
    HookEntityOutput("func_respawnroom", "OnEndTouch", OnEndTouch);
}

public void OnStartTouch(const char[] output, int caller, int activator, float delay)
{
    if (IsValidClient(activator))
    {
        TF2_AddCondition(activator, view_as<TFCond>(TFCond_Custom), -1.0);
    }
}

public void OnEndTouch(const char[] output, int caller, int activator, float delay)
{
    if (IsValidClient(activator))
    {
        TF2_RemoveCondition(activator, view_as<TFCond>(TFCond_Custom));
    }
}

bool IsValidClient(int client)
{
    return (client > 0 && client <= MaxClients && IsClientInGame(client) && IsPlayerAlive(client));
}