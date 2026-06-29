#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// Declare ConVar handles
Handle bot_quota_cvar;
Handle bot_quota_mode_cvar;
Handle min_bots;
Handle max_bots;

public Plugin myinfo =
{
    name        = "[Bot Quota] Dynamic Management",
    author      = "+SyntX",
    description = "Keeps total players (humans + bots) at 10 until bot quota stabilizes at 4.",
    version     = "1.6",
    url         = "http://steamcommunity.com/id/SyntX34 && https://github.com/SyntX34"
};

public void OnPluginStart()
{
    bot_quota_cvar = FindConVar("bot_quota");
    bot_quota_mode_cvar = FindConVar("bot_quota_mode");

    min_bots = CreateConVar("sm_min_bots", "4", "Minimum bot quota when players are online.", FCVAR_NOTIFY);
    max_bots = CreateConVar("sm_max_bots", "10", "Bot quota when no players are online.", FCVAR_NOTIFY);

    // Set bot_quota_mode to normal to ensure we control bot spawning
    if (bot_quota_mode_cvar != null)
    {
        SetConVarString(bot_quota_mode_cvar, "normal");
    }

    CreateTimer(3.0, AdjustBots, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    
    AutoExecConfig(true, "bot_quota_manager");
    HookEvent("round_end", RoundEnd);
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

    // Log for debugging
    //PrintToServer("[DEBUG] AdjustBots: humanCount=%d, desiredBots=%d, maxAllowedBots=%d", humanCount, desiredBots, maxAllowedBots);

    SetConVarInt(bot_quota_cvar, desiredBots);

    return Plugin_Continue;
}

public void RoundEnd(Event event, const char[] name, bool dontBroadcast)
{
    BalanceBotTeams();
}

public void BalanceBotTeams()
{
    int team1Bots = 0;
    int team2Bots = 0;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (IsClientConnected(client) && IsClientInGame(client) && IsFakeClient(client))
        {
            int team = GetClientTeam(client);
            if (team == 2) // Assuming team 2 is T
            {
                team1Bots++;
            }
            else if (team == 3) // Assuming team 3 is CT
            {
                team2Bots++;
            }
        }
    }

    // Balance bots between teams
    int botDifference = team1Bots - team2Bots;

    //PrintToServer("[DEBUG] BalanceBotTeams: team1Bots=%d, team2Bots=%d", team1Bots, team2Bots);

    if (botDifference > 1) // More bots in T than CT
    {
        for (int client = 1; client <= MaxClients; client++)
        {
            if (IsClientConnected(client) && IsClientInGame(client) && IsFakeClient(client))
            {
                if (GetClientTeam(client) == 2) // Move a bot from T to CT
                {
                    ChangeClientTeam(client, 3);
                    botDifference--;
                    if (botDifference <= 1) break;
                }
            }
        }
    }
    else if (botDifference < -1) // More bots in CT than T
    {
        for (int client = 1; client <= MaxClients; client++)
        {
            if (IsClientConnected(client) && IsClientInGame(client) && IsFakeClient(client))
            {
                if (GetClientTeam(client) == 3) // Move a bot from CT to T
                {
                    ChangeClientTeam(client, 2);
                    botDifference++;
                    if (botDifference >= -1) break;
                }
            }
        }
    }
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
