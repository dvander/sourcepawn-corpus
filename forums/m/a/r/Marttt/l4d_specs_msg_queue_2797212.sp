/**
// ====================================================================================================
Change Log:

1.0.1 (15-January-2023)
    - Public release.

1.0.0 (19-February-2021)
    - Private release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Spectators Name Message Queue"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Displays spectators names from time to time, sorted by longest time connected in server"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=341288"

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
#define CONFIG_FILENAME               "l4d_specs_msg_queue"
#define TRANSLATION_FILENAME          "l4d_specs_msg_queue.phrases"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_SPECTATOR                1

#define CALLER_SERVER_CONSOLE         0
#define CALLER_TIMER                  -1

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_TimerInterval;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bCvar_Enabled;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_TimerInterval;

// ====================================================================================================
// Timer - Plugin Variables
// ====================================================================================================
Handle g_tQueueMsg;

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

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    LoadPluginTranslations();

    CreateConVar("l4d_specs_msg_queue_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled       = CreateConVar("l4d_specs_msg_queue_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_TimerInterval = CreateConVar("l4d_specs_msg_queue_timer_interval", "60.0", "Interval in seconds that the queue message should output to everyone.", CVAR_FLAGS, true, 0.1);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_TimerInterval.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Public Commands
    RegConsoleCmd("sm_queue", CmdQueue, "Shows the current player queue.");

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_specs_msg_queue", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void LoadPluginTranslations()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, PLATFORM_MAX_PATH, "translations/%s.txt", TRANSLATION_FILENAME);
    if (FileExists(path))
        LoadTranslations(TRANSLATION_FILENAME);
    else
        SetFailState("Missing required translation file on \"translations/%s.txt\", please re-download.", TRANSLATION_FILENAME);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    delete g_tQueueMsg;
    if (g_bCvar_Enabled)
        g_tQueueMsg = CreateTimer(g_fCvar_TimerInterval, TimerQueue, _, TIMER_REPEAT);
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_TimerInterval = g_hCvar_TimerInterval.FloatValue;
}

/****************************************************************************************************/

Action TimerQueue(Handle timer)
{
    if (IsServerProcessing())
        GetQueue(CALLER_TIMER);

    return Plugin_Continue;
}

/****************************************************************************************************/

void GetQueue(int caller)
{
    int[][] specs = new int[MaxClients][2];
    int specsCount;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        if (IsFakeClient(client))
            continue;

        if (GetClientTeam(client) != TEAM_SPECTATOR)
            continue;

        specsCount++;
        specs[specsCount][0] = client;
        specs[specsCount][1] = RoundFloat(GetClientTime(client));
    }
    SortCustom2D(specs, specsCount, CustomSort);

    char buffer[512];
    for (int i = 0; i < MaxClients; i++)
    {
        if (specs[i][0] == 0)
            continue;

        if (buffer[0] == 0)
            FormatEx(buffer, sizeof(buffer), "%N", specs[i][0]);
        else
            Format(buffer, sizeof(buffer), "%s, %N", buffer, specs[i][0]);
    }

    if (buffer[0] == 0)
        return;

    switch (caller)
    {
        case CALLER_TIMER:
        {
            for (int client = 1; client <= MaxClients; client++)
            {
                if (!IsClientInGame(client))
                    continue;

                if (IsFakeClient(client))
                    continue;

                CPrintToChat(client, "%t", "Queue", buffer);
            }
        }
        case CALLER_SERVER_CONSOLE:
        {
            ReplyToCommand(caller, "%t", "Queue", buffer);
        }
        default: // Client Command
        {
            CPrintToChat(caller, "%t", "Queue", buffer);
        }
    }
}

/****************************************************************************************************/

int CustomSort(int[] elem1, int[] elem2, const int[][] array, Handle hndl)
{
    if (elem2[1] == 0)
        return -2;

    if (elem1[1] > elem2[1])
        return -1;

    if (elem1[1] < elem2[1])
        return 1;

    return 0;
}

// ====================================================================================================
// Public Commands
// ====================================================================================================
Action CmdQueue(int client, int args)
{
    GetQueue(client);

    return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d_specs_msg_queue) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_specs_msg_queue_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_specs_msg_queue_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_specs_msg_queue_timer_interval : %.1f", g_fCvar_TimerInterval);
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// colors.inc replacement (Thanks to Silvers)
// ====================================================================================================
/**
 * Prints a message to a specific client in the chat area.
 * Supports color tags.
 *
 * @param client        Client index.
 * @param message       Message (formatting rules).
 *
 * On error/Errors:     If the client is not connected an error will be thrown.
 */
void CPrintToChat(int client, char[] message, any ...)
{
    char buffer[512];
    SetGlobalTransTarget(client);
    VFormat(buffer, sizeof(buffer), message, 3);

    ReplaceString(buffer, sizeof(buffer), "{default}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{white}", "\x01");
    ReplaceString(buffer, sizeof(buffer), "{cyan}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{lightgreen}", "\x03");
    ReplaceString(buffer, sizeof(buffer), "{orange}", "\x04");
    ReplaceString(buffer, sizeof(buffer), "{green}", "\x04"); // Actually orange in L4D1/L4D2, but replicating colors.inc behaviour
    ReplaceString(buffer, sizeof(buffer), "{olive}", "\x05");

    PrintToChat(client, buffer);
}