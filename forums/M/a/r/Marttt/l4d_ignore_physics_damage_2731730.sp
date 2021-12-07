/**
// ====================================================================================================
Change Log:

1.0.0 (07-January-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Ignore Physics Damage"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Ignores physics damage dealt to clients"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=329781"

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
#define CONFIG_FILENAME               "l4d_ignore_physics_damage"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

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
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Survivor;
static ConVar g_hCvar_SI;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bL4D2;
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Survivor;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_SI;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static float  g_fCvar_Survivor;
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

public void OnPluginStart()
{
    CreateConVar("l4d_ignore_physics_damage_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled  = CreateConVar("l4d_ignore_physics_damage_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Survivor = CreateConVar("l4d_ignore_physics_damage_survivor", "4.0", "Maximum physics damage to be ignored by all survivors.\n0 = OFF.", CVAR_FLAGS, true, 0.0);
    if (g_bL4D2)
        g_hCvar_SI   = CreateConVar("l4d_ignore_physics_damage_si", "64", "Which special infected should ignore physics damage.\n1 = SMOKER, 2 = BOOMER, 4 = HUNTER, 8 = SPITTER, 16 = JOCKEY, 32 = CHARGER, 64 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"127\", ignores physics damage on all SI.", CVAR_FLAGS, true, 0.0, true, 127.0);
    else
        g_hCvar_SI   = CreateConVar("l4d_ignore_physics_damage_si", "8", "Which special infected should ignore physics damage.\n1 = SMOKER, 2  = BOOMER, 4 = HUNTER, 8 = TANK.\nAdd numbers greater than 0 for multiple options.\nExample: \"15\", ignores physics damage on all SI.", CVAR_FLAGS, true, 0.0, true, 15.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Survivor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_SI.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_ignore_physics_damage", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_Survivor = g_hCvar_Survivor.FloatValue;
    g_bCvar_Survivor = (g_fCvar_Survivor > 0.0);
    g_iCvar_SI = g_hCvar_SI.IntValue;
}

/****************************************************************************************************/

public void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);
    }
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (!g_bConfigLoaded)
        return;

    SDKHook(client, SDKHook_OnTakeDamage, OnTakeDamage);
}

/****************************************************************************************************/

public Action OnTakeDamage(int victim, int &attacker, int &inflictor, float &damage, int &damagetype)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (damagetype != DMG_CRUSH)
        return Plugin_Continue;

    if (!IsValidEntityIndex(inflictor))
        return Plugin_Continue;

    if (!IsValidEntity(inflictor))
        return Plugin_Continue;

    if (!HasEntProp(inflictor, Prop_Send, "m_isCarryable")) // CPhysicsProp
        return Plugin_Continue;

    if (!IsValidClient(victim))
        return Plugin_Continue;

    switch (GetClientTeam(victim))
    {
        case TEAM_INFECTED:
        {
            if (!(GetZombieClassFlag(victim) & g_iCvar_SI))
                return Plugin_Continue;

            damage = 0.0;
            return Plugin_Changed;
        }
        case TEAM_SURVIVOR, TEAM_HOLDOUT:
        {
            if (!g_bCvar_Survivor)
                return Plugin_Continue;

            if (damage > g_fCvar_Survivor)
                return Plugin_Continue;

            damage = 0.0;
            return Plugin_Changed;
        }
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
    PrintToConsole(client, "-------------- Plugin Cvars (l4d_ignore_physics_damage) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_ignore_physics_damage_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_ignore_physics_damage_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_ignore_physics_damage_survivor : %.2f (%s)", g_fCvar_Survivor, g_bCvar_Survivor ? "true" : "false");
    PrintToConsole(client, "l4d_ignore_physics_damage_si : %i (%s)", g_iCvar_SI, g_iCvar_SI > 0 ? "true" : "false");
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
 * Validates if is a valid entity index (between MaxClients+1 and 2048).
 *
 * @param entity        Entity index.
 * @return              True if entity index is valid, false otherwise.
 */
bool IsValidEntityIndex(int entity)
{
    return (MaxClients+1 <= entity <= GetMaxEntities());
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