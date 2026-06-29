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
    description = "Keeps total players (humans + bots) based on user-defined limits.",
    version     = "1.7",
    url         = "http://steamcommunity.com/id/SyntX34 && https://github.com/SyntX34"
};

public void OnPluginStart()
{
    bot_quota_cvar = FindConVar("bot_quota");
    bot_quota_mode_cvar = FindConVar("bot_quota_mode");

    // Create dynamic ConVars for minimum and maximum bots
    min_bots = CreateConVar("sm_min_bots", "4", "Minimum bot quota when players are online.", FCVAR_NOTIFY);
    max_bots = CreateConVar("sm_max_bots", "10", "Maximum bot quota when no players are online.", FCVAR_NOTIFY);

    // Set bot_quota_mode to "normal" to respect manual adjustments
    if (bot_quota_mode_cvar != null)
    {
        SetConVarString(bot_quota_mode_cvar, "normal");
    }

    // Periodically adjust bots and hook into events
    CreateTimer(3.0, AdjustBots, _, TIMER_REPEAT | TIMER_FLAG_NO_MAPCHANGE);
    AutoExecConfig(true, "bot_quota_manager");
    HookEvent("round_end", RoundEnd);
}

public void OnMapStart()
{
    // Reinitialize bot quota settings when the map changes
    if (bot_quota_mode_cvar != null)
    {
        SetConVarString(bot_quota_mode_cvar, "normal");
    }

    if (bot_quota_cvar != null)
    {
        SetConVarInt(bot_quota_cvar, GetConVarInt(max_bots)); // Start with max_bots
    }

    // Trigger immediate bot adjustment
    AdjustBots(null, 0);
}

public Action AdjustBots(Handle timer, any:data)
{
    int humanCount = GetHumanPlayerCount();

    // Fetch user-defined min and max bot values
    int g_MinBots = GetConVarInt(min_bots);
    int g_MaxBots = GetConVarInt(max_bots);

    // Calculate the desired bot count dynamically
    int desiredBots = g_MaxBots - humanCount;

    if (humanCount >= (g_MaxBots - g_MinBots)) 
    {
        desiredBots = g_MinBots;
    }
    else
    {
        desiredBots = Max(g_MinBots, g_MaxBots - humanCount);
    }

    // Ensure the desired bot count respects server limits
    int maxAllowedBots = MaxClients - humanCount;
    desiredBots = Min(desiredBots, maxAllowedBots);

    // Set the calculated bot quota
    if (bot_quota_cvar != null)
    {
        SetConVarInt(bot_quota_cvar, desiredBots);
    }

    PrintToServer("[DEBUG] AdjustBots: humanCount=%d, desiredBots=%d, g_MinBots=%d, g_MaxBots=%d", humanCount, desiredBots, g_MinBots, g_MaxBots);

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
            if (team == 2) // Team T
            {
                team1Bots++;
            }
            else if (team == 3) // Team CT
            {
                team2Bots++;
            }
        }
    }

    PrintToServer("[DEBUG] BalanceBotTeams: team1Bots=%d, team2Bots=%d", team1Bots, team2Bots);

    // Ensure no team has more than 2 bots
    if (team1Bots > 2)
    {
        int botsToRemove = team1Bots - 2;
        for (int client = 1; client <= MaxClients && botsToRemove > 0; client++)
        {
            if (IsClientConnected(client) && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 2)
            {
                KickClient(client, "Too many bots on T team");
                botsToRemove--;
            }
        }
    }

    if (team2Bots > 2)
    {
        int botsToRemove = team2Bots - 2;
        for (int client = 1; client <= MaxClients && botsToRemove > 0; client++)
        {
            if (IsClientConnected(client) && IsClientInGame(client) && IsFakeClient(client) && GetClientTeam(client) == 3)
            {
                KickClient(client, "Too many bots on CT team");
                botsToRemove--;
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
            int team = GetClientTeam(client);
            if (team != 1) // Exclude spectators (assuming team 1 is spectators)
            {
                humanCount++;
            }
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
