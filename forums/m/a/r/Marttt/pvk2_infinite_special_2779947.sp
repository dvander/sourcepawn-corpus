/**
// ====================================================================================================
Change Log:

1.0.0 (22-May-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[PVK2] Infinite Special"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Fills the specials meter automatically for all clients"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=337876"

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
#define CONFIG_FILENAME               "pvk2_infinite_special"

// ====================================================================================================
// Game Cvars
// ====================================================================================================
ConVar g_hCvar_mp_disablespecial;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bCvar_mp_disablespecial;
bool g_bCvar_Enabled;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iSpecial;
int g_iMaxSpecial;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bSDKHooked[MAXPLAYERS+1];

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    char game[8];
    GetGameFolderName(game, sizeof(game));

    if (!StrEqual(game, "pvkii"))
    {
        strcopy(error, err_max, "This plugin only runs in \"Pirates, Vikings, and Knights II\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    LoadTranslations("common.phrases");

    g_hCvar_mp_disablespecial = FindConVar("mp_disablespecial");

    CreateConVar("pvk2_infinite_special_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("pvk2_infinite_special_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_mp_disablespecial.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_fullspecial", CmdFullSpecial, ADMFLAG_ROOT, "Fill the special bar for self (no args) or specified targets. Example: self -> sm_fullspecial / target -> sm_fullspecial @bots");
    RegAdminCmd("sm_print_cvars_pvk2_infinite_special", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    // Fix for when OnConfigsExecuted is not executed by SM in some games
    RequestFrame(OnConfigsExecuted);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    LateLoad();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_mp_disablespecial = g_hCvar_mp_disablespecial.BoolValue;
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bSDKHooked[client] = false;
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (gc_bSDKHooked[client])
        return;

    gc_bSDKHooked[client] = true;
    SDKHook(client, SDKHook_PreThink, OnPreThink);
}

/****************************************************************************************************/

void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }
}

/****************************************************************************************************/

void OnPreThink(int client)
{
    if (g_bCvar_mp_disablespecial)
        return;

    if (!g_bCvar_Enabled)
        return;

    FillSpecial(client);
}

/****************************************************************************************************/

void FillSpecial(int client)
{
    g_iSpecial = GetEntProp(client, Prop_Send, "m_iSpecial");
    g_iMaxSpecial = GetEntProp(client, Prop_Send, "m_iMaxSpecial");

    if (g_iSpecial != g_iMaxSpecial)
        SetEntProp(client, Prop_Send, "m_iSpecial", g_iMaxSpecial);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdFullSpecial(int client, int args)
{
    int target_count;
    int target_list[MAXPLAYERS];

    if (args == 0) // self
    {
        if (IsValidClient(client))
        {
            target_count = 1;
            target_list[0] = client;
        }
    }
    else // specified target
    {
        char arg1[MAX_TARGET_LENGTH];
        GetCmdArg(1, arg1, sizeof(arg1));

        char target_name[MAX_TARGET_LENGTH];
        bool tn_is_ml;

        if ((target_count = ProcessTargetString(
            arg1,
            client,
            target_list,
            sizeof(target_list),
            COMMAND_FILTER_ALIVE,
            target_name,
            sizeof(target_name),
            tn_is_ml)) <= 0)
        {
            ReplyToTargetError(client, target_count);
        }
    }

    for (int i = 0; i < target_count; i++)
    {
        FillSpecial(target_list[i]);
    }

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (pvk2_infinite_special) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "pvk2_infinite_special_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "pvk2_infinite_special_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "mp_disablespecial : %b (%s)", g_bCvar_mp_disablespecial, g_bCvar_mp_disablespecial ? "true" : "false");
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
 * @param client        Client index.
 * @return              True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}