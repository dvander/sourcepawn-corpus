/**
// ====================================================================================================
Change Log:

1.0.3 (29-August-2022)
    - Added callvote changemission listener to ignore vote if map is blacklisted.

1.0.2 (28-August-2022)
    - Now automatically adds the changelevel maps to the whitelist.

1.0.1 (27-August-2022)
    - Fixed clients being kicked during mid-game map changes. (thanks "L4D2Noob" for reporting)
    - Faster and safer checks to change maps.

1.0.0 (25-August-2022)
    - Initial release. (thanks "zaviier" for requesting)

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Whitelist Map Changer"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Change the current map to a whitelist one if blacklisted"
#define PLUGIN_VERSION                "1.0.3"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=339261"

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
#define CONFIG_FILENAME               "l4d_whitelist_maps"
#define DATA_FILENAME                 "l4d_whitelist_maps"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MAX_MAP_LENGTH                64

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bForceChangeLevel;
bool g_bEventsHooked;
bool g_bCvar_Enabled;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fLastTimerCheck;

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alChangeLevelMaps;

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
StringMap g_smChangeMissionMaps;
StringMap g_smWhitelistMaps;

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
    g_alChangeLevelMaps = new ArrayList(ByteCountToCells(MAX_MAP_LENGTH));
    g_smChangeMissionMaps = new StringMap();
    g_smWhitelistMaps = new StringMap();

    BuildMaps();
    LoadConfigs();

    CreateConVar("l4d_whitelist_maps_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d_whitelist_maps_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_whitelist_maps_reload", CmdReload, ADMFLAG_ROOT, "Reload the whitelist maps configs.");
    RegAdminCmd("sm_print_cvars_l4d_whitelist_maps", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void BuildMaps()
{
    g_smChangeMissionMaps.Clear();
    g_smChangeMissionMaps.SetString("l4d2c1", "c1m1_hotel");
    g_smChangeMissionMaps.SetString("l4d2c2", "c2m1_highway");
    g_smChangeMissionMaps.SetString("l4d2c3", "c3m1_plankcountry");
    g_smChangeMissionMaps.SetString("l4d2c4", "c4m1_milltown_a");
    g_smChangeMissionMaps.SetString("l4d2c5", "c5m1_waterfront");
    g_smChangeMissionMaps.SetString("l4d2c6", "c6m1_riverbank");
    g_smChangeMissionMaps.SetString("l4d2c7", "c7m1_docks");
    g_smChangeMissionMaps.SetString("l4d2c8", "c8m1_apartment");
    g_smChangeMissionMaps.SetString("l4d2c9", "c9m1_alleys");
    g_smChangeMissionMaps.SetString("l4d2c10", "c10m1_caves");
    g_smChangeMissionMaps.SetString("l4d2c11", "c11m1_greenhouse");
    g_smChangeMissionMaps.SetString("l4d2c12", "c12m1_hilltop");
    g_smChangeMissionMaps.SetString("l4d2c13", "c13m1_alpinecreek");
    g_smChangeMissionMaps.SetString("l4d2c14", "c14m1_junkyard");
}

/****************************************************************************************************/

void LoadConfigs()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/%s.cfg", DATA_FILENAME);

    if (!FileExists(path))
    {
        SetFailState("Missing required data file on \"data/%s.cfg\", please re-download.", DATA_FILENAME);
        return;
    }

    KeyValues kv = new KeyValues(DATA_FILENAME);
    kv.ImportFromFile(path);

    g_alChangeLevelMaps.Clear();
    g_smWhitelistMaps.Clear();

    char mapName[MAX_MAP_LENGTH];
    int enable;

    if (kv.JumpToKey("changelevel"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                enable = kv.GetNum("enable", 0);
                if (enable == 0)
                    continue;

                kv.GetSectionName(mapName, sizeof(mapName));
                StringToLowerCase(mapName);
                g_alChangeLevelMaps.PushString(mapName);
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    if (kv.JumpToKey("whitelist"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                enable = kv.GetNum("enable", 0);
                if (enable == 0)
                    continue;

                kv.GetSectionName(mapName, sizeof(mapName));
                StringToLowerCase(mapName);
                g_smWhitelistMaps.SetString(mapName, "");
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    delete kv;

    // Just in case someone forgets to add the changelevel map to the whitelist
    for (int i = 0; i < g_alChangeLevelMaps.Length; i++)
    {
        g_alChangeLevelMaps.GetString(i, mapName, sizeof(mapName));
        g_smWhitelistMaps.SetString(mapName, "");
    }
}

/****************************************************************************************************/

public void OnMapStart()
{
    g_bForceChangeLevel = false;

    char mapName[MAX_MAP_LENGTH];
    GetCurrentMap(mapName, sizeof(mapName));
    StringToLowerCase(mapName);

    if (g_smWhitelistMaps.GetString(mapName, mapName, sizeof(mapName)))
        return;

    if (g_alChangeLevelMaps.Length == 0)
        return;

    g_bForceChangeLevel = true;
    g_fLastTimerCheck = GetGameTime();

    CreateTimer(15.0, TimerForceChangeLevel, g_fLastTimerCheck, TIMER_FLAG_NO_MAPCHANGE); // Automatically changes the map if no humans clients are found
}

/****************************************************************************************************/

public void OnMapEnd()
{
    g_bForceChangeLevel = false;
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    HookEvents();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();

    LateLoad();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        AddCommandListener(CallVoteListener, "callvote");

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        RemoveCommandListener(CallVoteListener, "callvote");

        return;
    }
}

/****************************************************************************************************/

void LateLoad()
{
    OnMapStart();
    RequestFrame(CheckHumanClients);
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (IsFakeClient(client))
        return;

    RequestFrame(CheckHumanClients);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    if (IsFakeClient(client))
        return;

    RequestFrame(CheckHumanClients); // Need wait a frame cause IsClientConnected still true
}

/****************************************************************************************************/

public Action CallVoteListener(int client, char[] command, int args)
{
    if (args < 2)
        return Plugin_Continue;

    if (g_alChangeLevelMaps.Length == 0)
        return Plugin_Continue;

    char arg1[15];
    GetCmdArg(1, arg1, sizeof(arg1));
    StringToLowerCase(arg1);

    if (!StrEqual(arg1, "changemission"))
        return Plugin_Continue;

    char arg2[9];
    GetCmdArg(2, arg2, sizeof(arg2));
    StringToLowerCase(arg2);

    char mapName[MAX_MAP_LENGTH];
    if (!g_smChangeMissionMaps.GetString(arg2, mapName, sizeof(mapName)))
        return Plugin_Continue;

    if (g_smWhitelistMaps.GetString(mapName, mapName, sizeof(mapName)))
        return Plugin_Continue;

    return Plugin_Handled;
}

/****************************************************************************************************/

void CheckHumanClients()
{
    if (!g_bCvar_Enabled)
         return;

    if (!g_bForceChangeLevel)
        return;

    bool hasHumans;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientConnected(client))
            continue;

        if (IsFakeClient(client))
            continue;

        if (!IsClientInGame(client)) // Still loading
            return;

        hasHumans = true;
    }

    if (hasHumans)
        TryForceChangeLevel();
}

/****************************************************************************************************/

Action TimerForceChangeLevel(Handle timer, float time)
{
    if (!g_bCvar_Enabled)
        return Plugin_Stop;

    if (!g_bForceChangeLevel)
        return Plugin_Stop;

    if (time != g_fLastTimerCheck)
        return Plugin_Stop;

    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientConnected(client))
            continue;

        if (!IsFakeClient(client))
            return Plugin_Stop;
    }

    TryForceChangeLevel();

    return Plugin_Stop;
}

/****************************************************************************************************/

void TryForceChangeLevel()
{
    char mapName[MAX_MAP_LENGTH];
    g_alChangeLevelMaps.GetString(GetRandomInt(0, g_alChangeLevelMaps.Length-1), mapName, sizeof(mapName));

    if (IsDedicatedServer()) // Only works on dedicated server
        ForceChangeLevel(mapName, "blacklisted map found on l4d_whitelist_maps plugin");
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdReload(int client, int args)
{
    LoadConfigs();

    LateLoad();

    if (IsValidClient(client))
        PrintToChat(client, "\x04Whitelist maps configs reloaded.");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (l4d_whitelist_maps) ------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_whitelist_maps_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_whitelist_maps_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "IsDedicatedServer : %b (%s)", IsDedicatedServer(), IsDedicatedServer() ? "true" : "false");
    char mapName[MAX_MAP_LENGTH];
    GetCurrentMap(mapName, sizeof(mapName));
    StringToLowerCase(mapName);
    PrintToConsole(client, "Map : %s", mapName);
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
 * @param client          Client index.
 * @return                True if client index is valid, false otherwise.
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
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}