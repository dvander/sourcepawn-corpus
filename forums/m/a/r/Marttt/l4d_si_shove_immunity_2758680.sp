/**
// ====================================================================================================
Change Log:

1.0.1 (09-February-2025)
    - Fixed SI not being able to move and use M2 while set with shove immunity and being shoved. (thanks "HarryPotter" for reporting and fixing)

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
#define PLUGIN_VERSION                "1.0.1"
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
#define TEAM_INFECTED                 3

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
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d_si_shove_immunity_version;
    ConVar l4d_si_shove_immunity_enable;
    ConVar l4d_si_shove_immunity_si;

    void Init()
    {
        this.l4d_si_shove_immunity_version = CreateConVar("l4d_si_shove_immunity_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d_si_shove_immunity_enable  = CreateConVar("l4d_si_shove_immunity_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        if (plugin.isLeft4Dead2)
            this.l4d_si_shove_immunity_si  = CreateConVar("l4d_si_shove_immunity_si", "127", "Which special infected should be immune to survivors shove.\n1 = SMOKER, 2 = BOOMER, 4 = HUNTER, 8 = SPITTER, 16 = JOCKEY, 32 = CHARGER, 64 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"127\", turns all SI immune to survivors shove.", CVAR_FLAGS, true, 0.0, true, 127.0);
        else
            this.l4d_si_shove_immunity_si  = CreateConVar("l4d_si_shove_immunity_si", "15", "Which special infected should be immune to survivors shove.\n1 = SMOKER, 2  = BOOMER, 4 = HUNTER, 8 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"15\", turns all SI immune to survivors shove.", CVAR_FLAGS, true, 0.0, true, 15.0);

        this.l4d_si_shove_immunity_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d_si_shove_immunity_si.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

// ====================================================================================================
// enum structs
// ====================================================================================================
enum struct PluginData
{
    PluginCvars cvars;

    bool isLeft4Dead2;
    bool left4dhooks;
    bool enable;
    int si;

    void Init()
    {
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.l4d_si_shove_immunity_enable.BoolValue;
        this.si = this.cvars.l4d_si_shove_immunity_si.IntValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_l4d_si_shove_immunity", Cmd_PrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }
}

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

    plugin.isLeft4Dead2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnLibraryAdded(const char[] name)
{
    if (!plugin.left4dhooks && StrEqual(name, "left4dhooks"))
        plugin.left4dhooks = true;
}

/****************************************************************************************************/

public void OnLibraryRemoved(const char[] name)
{
    if (plugin.left4dhooks && StrEqual(name, "left4dhooks"))
        plugin.left4dhooks = false;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    plugin.Init();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    plugin.GetCvarValues();
}

/****************************************************************************************************/

public Action L4D_OnShovedBySurvivor(int client, int victim, const float vecDir[3])
{
    if (!plugin.enable)
        return Plugin_Continue;

    if (GetZombieClassFlag(victim) & plugin.si)
        return Plugin_Handled;

    return Plugin_Continue;
}

/****************************************************************************************************/

// Besides named as L4D2 works on L4D1 as well
// Necessary to make SI being able to move and use M2 while set with shove immunity and being shoved
public Action L4D2_OnEntityShoved(int client, int entity, int weapon, float vecDir[3], bool bIsHighPounce)
{
    if (!plugin.enable)
        return Plugin_Continue;

    if (!IsValidClient(entity))
        return Plugin_Continue;

    if (GetClientTeam(entity) != TEAM_INFECTED)
        return Plugin_Continue;

    if (GetZombieClassFlag(entity) & plugin.si)
        return Plugin_Handled;

    return Plugin_Continue;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action Cmd_PrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_si_shove_immunity) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_si_shove_immunity_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_si_shove_immunity_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    if (plugin.isLeft4Dead2)
    {
        PrintToConsole(client, "l4d_si_shove_immunity_si : %i (SMOKER = %s | BOOMER = %s | HUNTER = %s | SPITTER = %s | JOCKEY = %s | CHARGER = %s | TANK = %s)", plugin.si,
        plugin.si & L4D2_FLAG_ZOMBIECLASS_SMOKER ? "true" : "false", plugin.si & L4D2_FLAG_ZOMBIECLASS_BOOMER ? "true" : "false", plugin.si & L4D2_FLAG_ZOMBIECLASS_HUNTER ? "true" : "false", plugin.si & L4D2_FLAG_ZOMBIECLASS_SPITTER ? "true" : "false",
        plugin.si & L4D2_FLAG_ZOMBIECLASS_JOCKEY ? "true" : "false", plugin.si & L4D2_FLAG_ZOMBIECLASS_CHARGER ? "true" : "false", plugin.si & L4D2_FLAG_ZOMBIECLASS_TANK ? "true" : "false");
    }
    else
    {
        PrintToConsole(client, "l4d_si_shove_immunity_si : %i (SMOKER = %s | BOOMER = %s | HUNTER = %s | TANK = %s)", plugin.si,
        plugin.si & L4D1_FLAG_ZOMBIECLASS_SMOKER ? "true" : "false", plugin.si & L4D1_FLAG_ZOMBIECLASS_BOOMER ? "true" : "false", plugin.si & L4D1_FLAG_ZOMBIECLASS_HUNTER ? "true" : "false", plugin.si & L4D1_FLAG_ZOMBIECLASS_TANK ? "true" : "false");
    }
    PrintToConsole(client, "");
    if (plugin.isLeft4Dead2)
    {
        PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
        PrintToConsole(client, "");
        PrintToConsole(client, "z_charger_allow_shove : %b (%s)", FindConVar("z_charger_allow_shove").BoolValue, FindConVar("z_charger_allow_shove").BoolValue ? "true" : "false");
        PrintToConsole(client, "");
    }
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "left4dhooks : %s", plugin.left4dhooks ? "true" : "false");
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

/****************************************************************************************************/

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

    if (plugin.isLeft4Dead2)
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