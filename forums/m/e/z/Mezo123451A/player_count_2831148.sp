// player_count_chat.sp

#include <sourcemod>
#include <sdktools>

#define MIN_INTERVAL 90.0
#define MAX_INTERVAL 180.0
#define PLUGIN_VERSION "1.0.1"
#define DEFAULT_MAX_PLAYERS 4

ConVar g_cvVersion;
ConVar g_cvMaxPlayers;
Handle g_Timer = INVALID_HANDLE;

public Plugin:myinfo = 
{
    name = "Player Count Chat",
    author = "Mezo123451A",
    description = "Announces the current player count in chat at random intervals",
    version = PLUGIN_VERSION,
    url = ""
};

public void OnPluginStart()
{
    // Create version ConVar
    g_cvVersion = CreateConVar("playercount_version", PLUGIN_VERSION, "Player Count Chat Version", FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY);
    
    // Get the server's max players ConVar
    g_cvMaxPlayers = FindConVar("sv_maxplayers");
    
    if(g_cvMaxPlayers == null)
    {
        LogError("Failed to find sv_maxplayers ConVar!");
        return;
    }
    
    // Set the version
    g_cvVersion.SetString(PLUGIN_VERSION);
    
    // Create config file
    AutoExecConfig(true, "plugin_playercount");
    
    // Start the initial timer
    CreateRandomTimer();
    
    // Hook map start event
    HookEvent("round_start", Event_RoundStart);
    
    // Log plugin start
    LogMessage("Player Count Chat v%s has been loaded.", PLUGIN_VERSION);
}

public void OnMapStart()
{
    // Ensure timer is running on map change
    if(g_Timer == INVALID_HANDLE)
    {
        CreateRandomTimer();
    }
}

public Action Event_RoundStart(Event event, const char[] name, bool dontBroadcast)
{
    // Ensure timer is running on round start
    if(g_Timer == INVALID_HANDLE)
    {
        CreateRandomTimer();
    }
    return Plugin_Continue;
}

public void CreateRandomTimer()
{
    // Kill existing timer if it exists
    if(g_Timer != INVALID_HANDLE)
    {
        KillTimer(g_Timer);
        g_Timer = INVALID_HANDLE;
    }
    
    float interval = GetRandomFloat(MIN_INTERVAL, MAX_INTERVAL);
    LogMessage("Setting timer for %.2f seconds", interval);
    g_Timer = CreateTimer(interval, Timer_AnnouncePlayerCount, _, TIMER_FLAG_NO_MAPCHANGE);
}

public Action:Timer_AnnouncePlayerCount(Handle:timer)
{
    g_Timer = INVALID_HANDLE;
    AnnouncePlayerCount();
    CreateRandomTimer();
    return Plugin_Stop;
}

public void AnnouncePlayerCount()
{
    // Get current player count (excluding bots)
    int playerCount = 0;
    for(int i = 1; i <= MaxClients; i++)
    {
        if(IsClientConnected(i) && !IsFakeClient(i))
        {
            playerCount++;
        }
    }
    
    // Get max slots from sv_maxplayers
    int maxSlots = g_cvMaxPlayers.IntValue;
    
    // Default to 4 players if sv_maxplayers is -1
    if(maxSlots <= 0)
    {
        maxSlots = DEFAULT_MAX_PLAYERS;
    }
    
    LogMessage("Announcing player count: %d/%d", playerCount, maxSlots);
    PrintToChatAll("\x01[\x04Player Count\x01] Current Players: \x04%d\x01/\x04%d", playerCount, maxSlots);
}

public void OnPluginEnd()
{
    // Clean up
    if(g_Timer != INVALID_HANDLE)
    {
        KillTimer(g_Timer);
        g_Timer = INVALID_HANDLE;
    }
    LogMessage("Player Count Chat v%s has been unloaded.", PLUGIN_VERSION);
}

public void OnMapEnd()
{
    // Clean up timer
    if(g_Timer != INVALID_HANDLE)
    {
        KillTimer(g_Timer);
        g_Timer = INVALID_HANDLE;
    }
}