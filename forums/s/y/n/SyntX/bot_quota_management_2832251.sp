#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// Declare ConVar handles
Handle bot_quota_cvar;
Handle min_bots;
Handle max_bots;

public Plugin myinfo =
{
    name        = "[Bot Quota] Dynamic Management",
    author      = "+SyntX",
    description = "Keeps total players (humans + bots) at 10 until bot quota stabilizes at 4.",
    version     = "1.5",
    url         = "http://steamcommunity.com/id/SyntX34 && https://github.com/SyntX34"
};

public void OnPluginStart()
{
    bot_quota_cvar = FindConVar("bot_quota");

    min_bots = CreateConVar("sm_min_bots", "4", "Minimum bot quota when players are online.", FCVAR_NOTIFY);
    max_bots = CreateConVar("sm_max_bots", "10", "Bot quota when no players are online.", FCVAR_NOTIFY);

    CreateTimer(3.0, AdjustBots, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    AutoExecConfig(true, "bot_quota_manager");
}

public Action AdjustBots(Handle timer, any:data)
{
    int humanCount = GetHumanPlayerCount();

    int g_MinBots = GetConVarInt(min_bots);
    int g_MaxBots = GetConVarInt(max_bots);

    int desiredBots = g_MaxBots - humanCount;

    if (humanCount >= 6) 
    {
        desiredBots = g_MinBots;
    }
    else
    {
        desiredBots = Max(g_MinBots, 10 - humanCount);
    }

    int maxAllowedBots = MaxClients - humanCount;
    desiredBots = Min(desiredBots, maxAllowedBots);

    SetConVarInt(bot_quota_cvar, desiredBots);

    return Plugin_Continue;
}

public int GetHumanPlayerCount()
{
    int humanCount = 0;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientConnected(client) && IsClientInGame(client) && !IsFakeClient(client))
        {
            humanCount++;
        }
    }

    return humanCount;
}

public int Max(int a, int b)
{
    return (a > b) ? a : b;
}

public int Min(int a, int b)
{
    return (a < b) ? a : b;
}
