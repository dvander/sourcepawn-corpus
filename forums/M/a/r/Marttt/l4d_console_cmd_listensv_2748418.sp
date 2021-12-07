/**
// ====================================================================================================
Change Log:

1.0.1 (31-May-2021)
    - Public release.

1.0.0 (11-May-2021)
    - Private release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Console Cmd As Host (Listen Server Only)"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Executes plugin commands from the console as if it were the host client index"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=332763"

// ====================================================================================================
// Plugin Info
// ====================================================================================================
public Plugin myinfo =
{
    name        = PLUGIN_NAME,
    author      = PLUGIN_AUTHOR,
    description = PLUGIN_DESCRIPTION,
    version     = PLUGIN_VERSION,
    url         = PLUGIN_URL
}

// ====================================================================================================
// Includes
// ====================================================================================================
#include <sourcemod>
#include <sdktools>
#include <sdkhooks>

// ====================================================================================================
// Pragmas
// ====================================================================================================
#pragma semicolon 1
#pragma newdecls required

// ====================================================================================================
// Cvar Flags
// ====================================================================================================
#define CVAR_FLAGS                    FCVAR_NOTIFY
#define CVAR_FLAGS_PLUGIN_VERSION     FCVAR_NOTIFY|FCVAR_DONTRECORD|FCVAR_SPONLY

// ====================================================================================================
// Filenames
// ====================================================================================================
#define CONFIG_FILENAME               "l4d_console_cmd_listensv"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
static ArrayList g_alCommands;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead && engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead\" and \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    g_alCommands = new ArrayList(ByteCountToCells(64));

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d_console_cmd_listensv_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled  = CreateConVar("l4d_console_cmd_listensv_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_console_cmd_listensv", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void LoadCommands()
{
    Handle hCmdIter = GetCommandIterator();
    char commandName[64];

    while (ReadCommandIterator(hCmdIter, commandName, sizeof(commandName)))
    {
        g_alCommands.PushString(commandName);
    }

    delete hCmdIter;
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    LoadCommands();

    GetCvars();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (IsDedicatedServer())
        return;

    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        AddCommandListener(ListenServerCommand, "");

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        RemoveCommandListener(ListenServerCommand, "");

        return;
    }
}

/****************************************************************************************************/

public Action ListenServerCommand(int client, const char[] command, int argc)
{
    if (client != 0)
        return Plugin_Continue;

    client = GetHostClient();

    if (!IsValidClient(client))
        return Plugin_Continue;

    if (!CommandExists(command))
        return Plugin_Continue;

    bool found;

    if (g_alCommands.FindString(command) != -1)
    {
        found = true;
    }
    else
    {
        Handle hCmdIter = GetCommandIterator();
        char commandName[64];

        while (ReadCommandIterator(hCmdIter, commandName, sizeof(commandName)))
        {
            if (g_alCommands.FindString(commandName) != -1)
                continue;

            g_alCommands.PushString(commandName);

            if (found)
                continue;

            if (StrEqual(command, commandName))
                found = true;
        }

        delete hCmdIter;
    }

    if (found)
    {
        char args[512];
        GetCmdArgString(args, sizeof(args));

        FakeClientCommand(client, "%s %s", command, args);
        return Plugin_Stop;
    }

    return Plugin_Continue;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------- Plugin Cvars (l4d_console_cmd_listensv) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_console_cmd_listensv_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_console_cmd_listensv_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "----------------------------------------------------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "IsDedicatedServer : %b (%s)", IsDedicatedServer(), IsDedicatedServer() ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client        Client index.
 * @return              True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client          Client index.
 * @return                True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}

/****************************************************************************************************/

/**
 * Returns the client index that is hosting the listen server.
 */
static int g_iEntTerrorPlayerManager = INVALID_ENT_REFERENCE;
public int GetHostClient()
{
    int entity = EntRefToEntIndex(g_iEntTerrorPlayerManager);

    if (entity == INVALID_ENT_REFERENCE)
        entity = FindEntityByClassname(-1, "terror_player_manager");

    if (entity == INVALID_ENT_REFERENCE)
    {
        g_iEntTerrorPlayerManager = INVALID_ENT_REFERENCE;
        return 0;
    }

    g_iEntTerrorPlayerManager = EntIndexToEntRef(entity);

    int offset = FindSendPropInfo("CTerrorPlayerResource", "m_listenServerHost");

    if (offset == -1)
        return 0;

    bool isHost[MAXPLAYERS+1];
    GetEntDataArray(entity, offset, isHost, MAXPLAYERS+1, 1);

    for (int client = 1; client <= MaxClients; client++)
    {
        if (isHost[client])
            return client;
    }

    return 0;
}