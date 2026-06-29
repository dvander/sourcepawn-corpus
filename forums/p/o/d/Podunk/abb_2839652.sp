#pragma semicolon 1

#define ABB_PLUGIN    "[TF2] Advanced Bot Balance"
#define ABB_VERSION   "1.0"
#define ABB_AUTHOR    "Podunk"
#define ABB_DESC      "Advanced control over the number of bots"

ConVar g_abb_extra_slack;
ConVar g_abb_reaction_time;
ConVar g_abb_min_usedslots;
ConVar g_abb_add_command;
ConVar g_abb_remove_command;
ConVar g_abb_min_open_slots;
ConVar g_abb_lingering_bots;

public Plugin myinfo =
{
    name = ABB_PLUGIN,
    author = ABB_AUTHOR,
    description = ABB_DESC,
    version = ABB_VERSION,
    url = "none"
};

public void OnPluginStart()
{
    g_abb_extra_slack = CreateConVar("abb_extra_slack", "3",
        "If the (# of lingering bots in play) > (abb_extra_slack), ABB will start kicking bots " ...
        "(1 per cycle). This setting is great because it allows the server population to " ...
        "come down gradually. ABB uses extra bot slack to supplement the leaving humans, " ...
        "while keeping the server pop smooth.",
        FCVAR_NOTIFY, true, 0.0, true, 100.0);

    g_abb_lingering_bots = CreateConVar("abb_lingering_bots", "1",
        "ABB tries to keep this many bots in play at all times " ...
        "(if there are [abb_min_usedslots] number of humans in play). " ...
        "Used right, this can improve your server pop drastically.",
        FCVAR_NOTIFY, true, 0.0, true, 100.0);

    g_abb_reaction_time = CreateConVar("abb_reaction_time", "60.0",
        "Time in seconds between every check and balance cycle. " ...
        "If ABB does need to add/remove bots, it will add/remove 1 bot per cycle.",
        FCVAR_NOTIFY, true, 0.0);

    g_abb_min_usedslots = CreateConVar("abb_min_usedslots", "10",
        "Minimum (human+bots) slots used on the server. ABB will add bots if there's " ...
        "less than the minimum total slots taken - until the min is reached. " ...
        "This setting is great for keeping players company during off hours.",
        FCVAR_NOTIFY, true, 0.0, true, 100.0);

    g_abb_add_command = CreateConVar("abb_add_command", "tf_bot_add",
        "Server command to add a bot to your server, with any extra parameters needed. " ...
        "The default works for TF2 Nextbots.",
        FCVAR_NOTIFY);

    g_abb_remove_command = CreateConVar("abb_remove_command", "tf_bot_kick",
        "Command to kick a bot (used as a base; bot name is handled internally). " ...
        "The default works for TF2 Nextbots.",
        FCVAR_NOTIFY);

    g_abb_min_open_slots = CreateConVar("abb_min_open_slots", "1",
        "The minimum open slots on the server. ABB will kick a bot if more open slots are needed " ...
        "and there is a bot to kick. Prevents humans from being unable to connect due to full server.",
        FCVAR_NOTIFY, true, 0.0, true, 100.0);

    // Start the first timer (non-repeating)
    CreateTimer(GetConVarFloat(g_abb_reaction_time), Timer_Tick);
}

public Action Timer_Tick(Handle timer)
{
    int humanCount = 0, botCount = 0;
    int maxPlayers = MaxClients;
    float reactionTime = GetConVarFloat(g_abb_reaction_time);
    int minUsedSlots = GetConVarInt(g_abb_min_usedslots);
    int extraSlack = GetConVarInt(g_abb_extra_slack);
    int minOpenSlots = GetConVarInt(g_abb_min_open_slots);
    int lingeringBots = GetConVarInt(g_abb_lingering_bots);

    // Count humans and bots
    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i))
        {
            if (IsFakeClient(i))
                botCount++;
            else
                humanCount++;
        }
    }

    // Kick a bot if we need more open slots and there is a bot to kick
    if (botCount > 0 && humanCount + botCount > maxPlayers - minOpenSlots)
    {
        KickBot();
    }
    // Add a bot if there's less than the minimum total slots taken
    else if (humanCount + botCount < minUsedSlots)
    {
        AddBot();
    }
    // Add a bot if there are fewer bots than lingering bots and slots are available
    else if (botCount < lingeringBots && humanCount + botCount < maxPlayers - minOpenSlots)
    {
        AddBot();
    }
    // Kick a bot if there are too many, but allow some slack
    else if (botCount > extraSlack && humanCount + botCount > minUsedSlots)
    {
        KickBot();
    }

    // Create a new timer with the current reactionTime
    CreateTimer(reactionTime, Timer_Tick);

    return Plugin_Continue;
}

void AddBot()
{
    char cmd[64];
    GetConVarString(g_abb_add_command, cmd, sizeof(cmd));
    LogAction(0, -1, "[ABB]: Executing add command: %s", cmd);
    ServerCommand("%s", cmd);
}

void KickBot()
{
    // Find a random bot
    int bot = TF2_GetRandomBot();
    if (bot <= 0) return; // No bots to kick

    char botName[64];
    GetClientName(bot, botName, sizeof(botName));
    char cmd[128];
    GetConVarString(g_abb_remove_command, cmd, sizeof(cmd));
    Format(cmd, sizeof(cmd), "%s \"%s\"", cmd, botName);
    LogAction(0, bot, "[ABB]: Executing kick command: %s", cmd);
    ServerCommand("%s", cmd);
}

// Helper function to get a random bot
int TF2_GetRandomBot()
{
    int[] bots = new int[MaxClients];
    int botCount = 0;

    for (int i = 1; i <= MaxClients; i++)
    {
        if (IsClientInGame(i) && IsFakeClient(i))
        {
            bots[botCount++] = i;
        }
    }

    if (botCount == 0) return 0;
    return bots[GetRandomInt(0, botCount - 1)];
}