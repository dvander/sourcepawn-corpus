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
#define PLUGIN_NAME                   "[L4D1 & L4D2] Deadly Tank Hittables"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Increases the damage received from tank hittables to instant incap survivors"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=329780"

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
#define CONFIG_FILENAME               "l4d_deadly_tank_hittables"

// ====================================================================================================
// Defines
// ====================================================================================================
#define TEAM_SPECTATOR                1
#define TEAM_SURVIVOR                 2
#define TEAM_INFECTED                 3
#define TEAM_HOLDOUT                  4

#define FLAG_TEAM_NONE                (0 << 0) // 0 | 0000
#define FLAG_TEAM_SURVIVOR            (1 << 0) // 1 | 0001
#define FLAG_TEAM_INFECTED            (1 << 1) // 2 | 0010
#define FLAG_TEAM_SPECTATOR           (1 << 2) // 4 | 0100
#define FLAG_TEAM_HOLDOUT             (1 << 3) // 8 | 1000

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Team;
static ConVar g_hCvar_MinDamage;
static ConVar g_hCvar_Damage;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Team;
static bool   g_bCvar_MinDamage;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_Team;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_MinDamage;
static float  g_fCvar_Damage;

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
    CreateConVar("l4d_deadly_tank_hittables_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled   = CreateConVar("l4d_deadly_tank_hittables_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Team      = CreateConVar("l4d_deadly_tank_hittables_team", "1", "Plugin behaviour enabled for these teams.\n0 = NONE, 1 = SURVIVOR, 2 = INFECTED, 4 = SPECTATOR, 8 = HOLDOUT.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for SURVIVOR and INFECTED.", CVAR_FLAGS, true, 0.0, true, 15.0);
    g_hCvar_MinDamage = CreateConVar("l4d_deadly_tank_hittables_mindamage", "8.0", "Minimum damage necessary received from a prop_physics to apply deadly damage.", CVAR_FLAGS, true, 0.0);
    g_hCvar_Damage    = CreateConVar("l4d_deadly_tank_hittables_damage", "100.0", "Damage applied when fulfils all conditions.", CVAR_FLAGS, true, 0.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Team.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinDamage.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Damage.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_deadly_tank_hittables", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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
    g_iCvar_Team = g_hCvar_Team.IntValue;
    g_bCvar_Team = (g_iCvar_Team > 0);
    g_fCvar_MinDamage = g_hCvar_MinDamage.FloatValue;
    g_bCvar_MinDamage = (g_fCvar_MinDamage > 0.0);
    g_fCvar_Damage = g_hCvar_Damage.FloatValue;
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

    if (damage < g_fCvar_MinDamage)
        return Plugin_Continue;

    if (!IsValidEntityIndex(inflictor))
        return Plugin_Continue;

    if (!IsValidEntity(inflictor))
        return Plugin_Continue;

    if (!HasEntProp(inflictor, Prop_Send, "m_isCarryable")) // CPhysicsProp
        return Plugin_Continue;

    if (!IsValidClient(victim))
        return Plugin_Continue;

    if (!(GetTeamFlag(GetClientTeam(victim)) & g_iCvar_Team))
        return Plugin_Continue;

    damage = g_fCvar_Damage;
    return Plugin_Changed;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d_deadly_tank_hittables) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_deadly_tank_hittables_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_deadly_tank_hittables_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d_deadly_tank_hittables_team : %i (%s)", g_iCvar_Team, g_bCvar_Team ? "true" : "false");
    PrintToConsole(client, "l4d_deadly_tank_hittables_damage_check : %.2f (%s)", g_fCvar_MinDamage, g_bCvar_MinDamage ? "true" : "false");
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
 * Returns the team flag from a team.
 *
 * @param team          Team index.
 * @return              Team flag.
 */
int GetTeamFlag(int team)
{
    switch (team)
    {
        case TEAM_SURVIVOR:
            return FLAG_TEAM_SURVIVOR;
        case TEAM_INFECTED:
            return FLAG_TEAM_INFECTED;
        case TEAM_SPECTATOR:
            return FLAG_TEAM_SPECTATOR;
        case TEAM_HOLDOUT:
            return FLAG_TEAM_HOLDOUT;
        default:
            return FLAG_TEAM_NONE;
    }
}