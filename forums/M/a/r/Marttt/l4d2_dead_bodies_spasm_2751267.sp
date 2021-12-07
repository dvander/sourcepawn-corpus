/**
// ====================================================================================================
Change Log:

1.0.0 (27-June-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Survivors Dead Bodies Spasm"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Apply a constant shock to the survivors dead bodies"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=333236"

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
#define CONFIG_FILENAME               "l4d2_dead_bodies_spasm"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_SURVIVOR_DEATH_MODEL         "survivor_death_model"

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Interval;
static ConVar g_hCvar_Count;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Count;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_Count;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_Interval;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
static int    ge_iRepeatCount[MAXENTITIES+1];

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead2)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 2\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d2_dead_bodies_spasm_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled  = CreateConVar("l4d2_dead_bodies_spasm_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Interval = CreateConVar("l4d2_dead_bodies_spasm_interval", "1.0", "How often (in seconds) should apply a shock to the survivors dead bodies.", CVAR_FLAGS, true, 0.1);
    g_hCvar_Count    = CreateConVar("l4d2_dead_bodies_spasm_count", "0", "How many times should should apply a shock to the survivors dead bodies.\n0 = Unlimited", CVAR_FLAGS, true, 0.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Interval.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Count.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_dead_bodies_spasm", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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
    g_fCvar_Interval = g_hCvar_Interval.FloatValue;
    g_iCvar_Count = g_hCvar_Count.IntValue;
    g_bCvar_Count = (g_iCvar_Count > 0);
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_SURVIVOR_DEATH_MODEL)) != INVALID_ENT_REFERENCE)
    {
       CreateTimer(g_fCvar_Interval, TimerShock, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 's' && classname[1] != 'u') // survivor_death_model
        return;

    if (StrEqual(classname, CLASSNAME_SURVIVOR_DEATH_MODEL))
        CreateTimer(g_fCvar_Interval, TimerShock, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    ge_iRepeatCount[entity] = 0;
}

/****************************************************************************************************/

public Action TimerShock(Handle timer, int entityRef)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    CreateTimer(g_fCvar_Interval, TimerShock, EntIndexToEntRef(entity), TIMER_FLAG_NO_MAPCHANGE);

    if (g_bCvar_Count && ge_iRepeatCount[entity] >= g_iCvar_Count)
        return;

    AcceptEntityInput(entity, "Shock");
    ge_iRepeatCount[entity]++;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d2_dead_bodies_spasm) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_dead_bodies_spasm_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_dead_bodies_spasm_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_dead_bodies_spasm_interval : %.2f", g_fCvar_Interval);
    PrintToConsole(client, "l4d2_dead_bodies_spasm_count : %i (%s)", g_iCvar_Count, g_bCvar_Count ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
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
