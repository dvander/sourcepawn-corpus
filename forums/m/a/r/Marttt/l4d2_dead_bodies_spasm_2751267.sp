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
#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_Interval;
ConVar g_hCvar_Count;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bCvar_Enabled;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_Count;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_Interval;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
int ge_iRepeatCount[MAXENTITIES+1];

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alPluginEntities;

// ====================================================================================================
// Timer - Plugin Variables
// ====================================================================================================
Handle g_tShockInterval;

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
    g_alPluginEntities = new ArrayList();

    CreateConVar("l4d2_dead_bodies_spasm_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled  = CreateConVar("l4d2_dead_bodies_spasm_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Interval = CreateConVar("l4d2_dead_bodies_spasm_interval", "1.0", "How often (in seconds) should apply a shock to the survivors dead bodies.", CVAR_FLAGS, true, 0.1);
    g_hCvar_Count    = CreateConVar("l4d2_dead_bodies_spasm_count", "0", "How many times should apply a shock to survivors dead bodies.\n0 = Unlimited.", CVAR_FLAGS, true, 0.0);

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

    LateLoad();
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
    g_fCvar_Interval = g_hCvar_Interval.FloatValue;
    g_iCvar_Count = g_hCvar_Count.IntValue;

    delete g_tShockInterval;
    if (g_bCvar_Enabled)
        g_tShockInterval = CreateTimer(g_fCvar_Interval, TimerShock, _, TIMER_REPEAT);
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "survivor_death_model")) != INVALID_ENT_REFERENCE)
    {
        AddEntityToArrayList(entity);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (entity < 0)
        return;

    if (StrEqual(classname, "survivor_death_model"))
        AddEntityToArrayList(entity);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_iRepeatCount[entity] = 0;

    int find = g_alPluginEntities.FindValue(EntIndexToEntRef(entity));
    if (find != -1)
        g_alPluginEntities.Erase(find);
}

/****************************************************************************************************/

void AddEntityToArrayList(int entity)
{
    if (g_alPluginEntities.FindValue(EntIndexToEntRef(entity)) == -1)
        g_alPluginEntities.Push(EntIndexToEntRef(entity));
}

/****************************************************************************************************/

Action TimerShock(Handle timer)
{
    int entity;

    for (int i = 0; i < g_alPluginEntities.Length; i++)
    {
        entity = EntRefToEntIndex(g_alPluginEntities.Get(i));

        if (entity == INVALID_ENT_REFERENCE)
            continue;

        if (g_iCvar_Count > 0)
        {
            if (ge_iRepeatCount[entity] >= g_iCvar_Count)
                continue;

            ge_iRepeatCount[entity]++;
            if (ge_iRepeatCount[entity] < 0) // int.MaxValue fix
                ge_iRepeatCount[entity] = 0;
        }

        AcceptEntityInput(entity, "Shock");
    }

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
    PrintToConsole(client, "--------------- Plugin Cvars (l4d2_dead_bodies_spasm) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_dead_bodies_spasm_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_dead_bodies_spasm_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_dead_bodies_spasm_interval : %.1f", g_fCvar_Interval);
    PrintToConsole(client, "l4d2_dead_bodies_spasm_count : %i", g_iCvar_Count);
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------------------- Array List -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "g_alPluginEntities count : %i", g_alPluginEntities.Length);
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}