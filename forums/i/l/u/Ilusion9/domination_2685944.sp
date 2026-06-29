#include <sourcemod>
#include <sdktools>
#pragma newdecls required

int g_ConsecutiveKills[MAXPLAYERS + 1][MAXPLAYERS + 1];

public void OnPluginStart()
{
    HookEvent("player_death", Event_PlayerDeath);
}

public void OnClientConnected(int client)
{
    for (int i = 1; i < MAXPLAYERS + 1; i++)
    {
        g_ConsecutiveKills[client][i] = 0;
        g_ConsecutiveKills[i][client] = 0;
    }
}

public void Event_PlayerDeath(Event event, const char[] name, bool dontBroadcast)
{
    if (IsWarmupPeriod())
    {
        return;
    }
    
    int victim = GetClientOfUserId(event.GetInt("userid"));    
    if (!victim)
    {
        return;
    }
    
    int attacker = GetClientOfUserId(event.GetInt("attacker"));
    if (!attacker || attacker == victim)
    {
        return;
    }

    bool revenge = g_ConsecutiveKills[victim][attacker] > 3;
    g_ConsecutiveKills[attacker][victim]++
    g_ConsecutiveKills[victim][attacker] = 0;
    
    if (revenge)
    {
        PrintToChat(attacker, "You revenged on %N!", victim);
        PrintToChat(victim, "%N has revenged on you!", attacker);
        return;
    }
    
    int consKills = g_ConsecutiveKills[attacker][victim];
    if (consKills == 4)
    {
        PrintToChat(victim, "%N is dominating you.", attacker);
        PrintToChat(attacker, "You are now dominating %N.", victim);
        return;
    }
    
    if (consKills > 4)
    {
        PrintToChat(victim, "%N is still dominating you.", attacker);
        PrintToChat(attacker, "You are still dominating %N.", victim);
    }
}

bool IsWarmupPeriod()
{
    return view_as<bool>(GameRules_GetProp("m_bWarmupPeriod"));
} 