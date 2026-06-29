/**
// ====================================================================================================
Change Log:

1.0.0 (23-September-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Special Infected Shove Immunity"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Turns special infected immunes to survivors shove"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=334434"

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
#tryinclude <left4dhooks> // Download here: https://forums.alliedmods.net/showthread.php?t=321696

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
#define CONFIG_FILENAME               "l4d_si_shove_immunity"

// ====================================================================================================
// Defines
// ====================================================================================================
#define L4D2_ZOMBIECLASS_SMOKER       1
#define L4D2_ZOMBIECLASS_BOOMER       2
#define L4D2_ZOMBIECLASS_HUNTER       3
#define L4D2_ZOMBIECLASS_SPITTER      4
#define L4D2_ZOMBIECLASS_JOCKEY       5
#define L4D2_ZOMBIECLASS_CHARGER      6
#define L4D2_ZOMBIECLASS_TANK         8

#define L4D1_ZOMBIECLASS_SMOKER       1
#define L4D1_ZOMBIECLASS_BOOMER       2
#define L4D1_ZOMBIECLASS_HUNTER       3
#define L4D1_ZOMBIECLASS_TANK         5

#define L4D2_FLAG_ZOMBIECLASS_NONE    0
#define L4D2_FLAG_ZOMBIECLASS_SMOKER  1
#define L4D2_FLAG_ZOMBIECLASS_BOOMER  2
#define L4D2_FLAG_ZOMBIECLASS_HUNTER  4
#define L4D2_FLAG_ZOMBIECLASS_SPITTER 8
#define L4D2_FLAG_ZOMBIECLASS_JOCKEY  16
#define L4D2_FLAG_ZOMBIECLASS_CHARGER 32
#define L4D2_FLAG_ZOMBIECLASS_TANK    64

#define L4D1_FLAG_ZOMBIECLASS_NONE    0
#define L4D1_FLAG_ZOMBIECLASS_SMOKER  1
#define L4D1_FLAG_ZOMBIECLASS_BOOMER  2
#define L4D1_FLAG_ZOMBIECLASS_HUNTER  4
#define L4D1_FLAG_ZOMBIECLASS_TANK    8

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_SI;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bLeft4DHooks;
bool g_bCvar_Enabled;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_SI;

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

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnLibraryAdded(const char[] name)
{
    if (!g_bLeft4DHooks && StrEqual(name, "left4dhooks"))
        g_bLeft4DHooks = true;
}

/****************************************************************************************************/

public void OnLibraryRemoved(const char[] name)
{
    if (g_bLeft4DHooks && StrEqual(name, "left4dhooks"))
        g_bLeft4DHooks = false;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d_si_shove_immunity_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled       = CreateConVar("l4d_si_shove_immunity_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    if (g_bL4D2)
        g_hCvar_SI        = CreateConVar("l4d_si_shove_immunity_si", "127", "Which special infected should be immune to survivors shove.\n1 = SMOKER, 2 = BOOMER, 4 = HUNTER, 8 = SPITTER, 16 = JOCKEY, 32 = CHARGER, 64 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"127\", turns all SI immune to survivors shove.", CVAR_FLAGS, true, 0.0, true, 127.0);
    else
        g_hCvar_SI        = CreateConVar("l4d_si_shove_immunity_si", "8", "Which special infected should be immune to survivors shove.\n1 = SMOKER, 2  = BOOMER, 4 = HUNTER, 8 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"15\", turns all SI immune to survivors shove.", CVAR_FLAGS, true, 0.0, true, 15.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SI.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_si_shove_immunity", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_iCvar_SI = g_hCvar_SI.IntValue;
}

/****************************************************************************************************/

public Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDir[3])
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (GetZombieClassFlag(victim) & g_iCvar_SI)
        return Plugin_Handled;

    return Plugin_Continue;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_si_shove_immunity) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_si_shove_immunity_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_si_shove_immunity_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    if (g_bL4D2)
    {
        PrintToConsole(client, "l4d_si_shove_immunity_si : %i (SMOKER = %s | BOOMER = %s | HUNTER = %s | SPITTER = %s | JOCKEY = %s | CHARGER = %s | TANK = %s)", g_iCvar_SI,
        g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_SMOKER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_BOOMER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_HUNTER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_SPITTER ? "true" : "false",
        g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_JOCKEY ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_CHARGER ? "true" : "false", g_iCvar_SI & L4D2_FLAG_ZOMBIECLASS_TANK ? "true" : "false");
    }
    else
    {
        PrintToConsole(client, "l4d_si_shove_immunity_si : %i (SMOKER = %s | BOOMER = %s | HUNTER = %s | TANK = %s)", g_iCvar_SI,
        g_iCvar_SI & L4D1_FLAG_ZOMBIECLASS_SMOKER ? "true" : "false", g_iCvar_SI & L4D1_FLAG_ZOMBIECLASS_BOOMER ? "true" : "false", g_iCvar_SI & L4D1_FLAG_ZOMBIECLASS_HUNTER ? "true" : "false", g_iCvar_SI & L4D1_FLAG_ZOMBIECLASS_TANK ? "true" : "false");
    }
    PrintToConsole(client, "");
    if (g_bL4D2)
    {
        PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
        PrintToConsole(client, "");
        PrintToConsole(client, "z_charger_allow_shove : %b (%s)", FindConVar("z_charger_allow_shove").BoolValue, FindConVar("z_charger_allow_shove").BoolValue ? "true" : "false");
        PrintToConsole(client, "");
    }
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "left4dhooks : %s", g_bLeft4DHooks ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Gets the client L4D1/L4D2 zombie class id.
 *
 * @param client     Client index.
 * @return L4D1      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=WITCH, 5=TANK, 6=NOT INFECTED
 * @return L4D2      1=SMOKER, 2=BOOMER, 3=HUNTER, 4=SPITTER, 5=JOCKEY, 6=CHARGER, 7=WITCH, 8=TANK, 9=NOT INFECTED
 */
int GetZombieClass(int client)
{
    return (GetEntProp(client, Prop_Send, "m_zombieClass"));
}

/****************************************************************************************************/

/**
 * Returns the zombie class flag from a zombie class.
 *
 * @param client        Client index.
 * @return              Client zombie class flag.
 */
int GetZombieClassFlag(int client)
{
    int zombieClass = GetZombieClass(client);

    if (g_bL4D2)
    {
        switch (zombieClass)
        {
            case L4D2_ZOMBIECLASS_SMOKER:
                return L4D2_FLAG_ZOMBIECLASS_SMOKER;
            case L4D2_ZOMBIECLASS_BOOMER:
                return L4D2_FLAG_ZOMBIECLASS_BOOMER;
            case L4D2_ZOMBIECLASS_HUNTER:
                return L4D2_FLAG_ZOMBIECLASS_HUNTER;
            case L4D2_ZOMBIECLASS_SPITTER:
                return L4D2_FLAG_ZOMBIECLASS_SPITTER;
            case L4D2_ZOMBIECLASS_JOCKEY:
                return L4D2_FLAG_ZOMBIECLASS_JOCKEY;
            case L4D2_ZOMBIECLASS_CHARGER:
                return L4D2_FLAG_ZOMBIECLASS_CHARGER;
            case L4D2_ZOMBIECLASS_TANK:
                return L4D2_FLAG_ZOMBIECLASS_TANK;
            default:
                return L4D2_FLAG_ZOMBIECLASS_NONE;
        }
    }
    else
    {
        switch (zombieClass)
        {
            case L4D1_ZOMBIECLASS_SMOKER:
                return L4D1_FLAG_ZOMBIECLASS_SMOKER;
            case L4D1_ZOMBIECLASS_BOOMER:
                return L4D1_FLAG_ZOMBIECLASS_BOOMER;
            case L4D1_ZOMBIECLASS_HUNTER:
                return L4D1_FLAG_ZOMBIECLASS_HUNTER;
            case L4D1_ZOMBIECLASS_TANK:
                return L4D1_FLAG_ZOMBIECLASS_TANK;
            default:
                return L4D1_FLAG_ZOMBIECLASS_NONE;
        }
    }
}