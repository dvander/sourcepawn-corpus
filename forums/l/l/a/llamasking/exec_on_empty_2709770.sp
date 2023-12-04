#pragma semicolon 1
#include <sourcemod>

#pragma newdecls required
#pragma semicolon 1

//#define DEBUG
#define MAX_ID_STRING 6
#define VERSION       "1.7.3"

public Plugin myinfo =
{
    name        = "Execute on Empty",
    author      = "llamasking",
    description = "Executes a config whenever the server is empty.",
    version     = VERSION,
    url         = "https://github.com/llamasking/sourcemod-plugins",


}

ConVar g_enabled;    // Whether or not the plugin is on
ConVar g_config;     // Config file to load

int    g_players;                   // Player count
Handle g_clients;                   // List of clients connected
Handle g_timer = INVALID_HANDLE;    // Timer to exec config everyone leaves

//
public void OnPluginStart()
{
    // Create ConVars
    g_enabled = CreateConVar("sm_empty_enabled", "1", "Whether or not the plugin is enabled.", FCVAR_PROTECTED, true, 0.0, true, 1.0);
    g_config  = CreateConVar("sm_empty_config", "", "The config to run when the server emptys.", FCVAR_PROTECTED);
    CreateConVar("sm_empty_version", VERSION, "Plugin version.", FCVAR_NOTIFY);

    // Create table of IDs
    g_clients = CreateTrie();

    // Auto-generate config file if it's not there
    AutoExecConfig(true, "exec_on_empty.cfg");
}

public void OnClientAuthorized(int client, const char[] auth)
{
    char client_s[MAX_ID_STRING];

    // Filter fake clients
    if (!client || IsFakeClient(client) || StrEqual(auth, "BOT"))
        return;

    // Get player ID as a string
    IntToString(GetClientUserId(client), client_s, sizeof(client_s));

    // Check if player is already in the list of IDs
    if (SetTrieValue(g_clients, client_s, 1, false))
    {
        g_players++;
    }
}

public void OnClientDisconnect(int client)
{
    char client_s[MAX_ID_STRING];

    // Filter fake clients
    if (!client || IsFakeClient(client))
        return;

    // Get player ID as a string
    IntToString(GetClientUserId(client), client_s, sizeof(client_s));

    // Try to remove the player ID from the list of IDs
    if (RemoveFromTrie(g_clients, client_s))
    {
        g_players--;

        // If there are no players left in the server and plugin is enabled
        if ((g_players == 0))
        {
            // If you do this immediately, changing the map will run exec.
            g_timer = CreateTimer(2.5, ExecCfg);
        }
    }
}

// Prevent running if the map is changing.
public void OnMapEnd()
{
    // Prevent errors when everyone actually does leave.
    // IsValidHandle is deprecated but idk a good alternative.
    if (IsValidHandle(g_timer))
    {
        CloseHandle(g_timer);
    }
}

public Action ExecCfg(Handle timer)
{
    if (!GetConVarBool(g_enabled))
        return Plugin_Stop;

    char cfg[PLATFORM_MAX_PATH];

    GetConVarString(g_config, cfg, sizeof(cfg));
    ServerCommand("exec \"%s\"", cfg);

    return Plugin_Stop;
}
