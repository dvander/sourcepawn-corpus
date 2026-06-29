/**
// ====================================================================================================
Change Log:

1.0.0 (24-December-2022)
    - Initial release.

// ====================================================================================================
*/

/**
if you want to do that through the stripper extension (http://www.bailopan.net/stripper/#install) instead a plugin,
add the following lines to the maps/c5m2_park.cfg file:

filter:
{
    "classname" "trigger_once"
    "filtername" "filter_tank"
    //"hammerid" "2317410"
}
{
    "classname" "filter_activator_infected_class"
    "targetname" "filter_tank"
    //"hammerid" "2317390"
}

modify:
{
    match:
    {
        "classname" "func_breakable"
        "targetname" "trailer_skylight"
        //"hammerid" "2317371"
    }
    replace:
    {
        //from "1" (Only Break on Trigger) to "0"
        "spawnflags" "0"
    }
}
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Breakable CEDA Trailer Window (c5m2_park)"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Turns the CEDA trailer upper window in c5m2_park map breakable by everyone, instead only by Tanks"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=341037"

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
#define CONFIG_FILENAME               "l4d_c5m2_ceda_window"

// ====================================================================================================
// Defines
// ====================================================================================================
#define DAMAGE_YES                    2

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bIs_c5m2_park;
bool g_bCvar_Enabled;

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
    CreateConVar("l4d_c5m2_ceda_window_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d_c5m2_ceda_window_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_tank_challenge", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    char mapName[11];
    GetCurrentMap(mapName, sizeof(mapName));
    g_bIs_c5m2_park = (StrEqual(mapName, "c5m2_park", false));
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
    OnConfigsExecuted();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
}

/****************************************************************************************************/

void LateLoad()
{
    if (!g_bIs_c5m2_park)
        return;

    if (!g_bCvar_Enabled)
        return;

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "trigger_once")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Remove_TriggerOnce, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "filter_activator_infected_class")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Remove_FilterActivatorInfectedClass, entity);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "func_breakable")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Fix_FuncBreakable, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bIs_c5m2_park)
        return;

    if (!g_bCvar_Enabled)
        return;

    if (StrEqual(classname, "trigger_once"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_TriggerOnce);
        return;
    }

    if (StrEqual(classname, "filter_activator_infected_class"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_FilterActivatorInfectedClass);
        return;
    }

    if (StrEqual(classname, "func_breakable"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_FuncBreakable);
        return;
    }

}

/****************************************************************************************************/

void OnSpawnPost_TriggerOnce(int entity)
{
    Remove_TriggerOnce(EntIndexToEntRef(entity));
}

/****************************************************************************************************/

void OnSpawnPost_FilterActivatorInfectedClass(int entity)
{
    Remove_FilterActivatorInfectedClass(entity);
}

/****************************************************************************************************/

void OnSpawnPost_FuncBreakable(int entity)
{
    Fix_FuncBreakable(EntIndexToEntRef(entity));
}

/****************************************************************************************************/

void Remove_TriggerOnce(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    char filtername[13];
    GetEntPropString(entity, Prop_Data, "m_iFilterName", filtername, sizeof(filtername));

    if (StrEqual(filtername, "filter_tank"))
        RemoveEntity(entity);
}

/****************************************************************************************************/

// Note: filter_activator_infected_class already is an entity reference (negative index)
void Remove_FilterActivatorInfectedClass(int entityRef)
{
    if (!IsValidEntity(entityRef))
        return;

    char targetname[13];
    GetEntPropString(entityRef, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, "filter_tank"))
        RemoveEntity(entityRef);
}

/****************************************************************************************************/

void Fix_FuncBreakable(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    char targetname[18];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, "trailer_skylight"))
    {
        SetEntProp(entity, Prop_Data, "m_spawnflags", 0);
        SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_YES);
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------- Plugin Cvars (l4d_c5m2_ceda_window) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_c5m2_ceda_window_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_c5m2_ceda_window_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    char mapName[64];
    GetCurrentMap(mapName, sizeof(mapName));
    PrintToConsole(client, "Map : %s", mapName);
    PrintToConsole(client, "Is \"c5m2_park\" (Parish Chapter 2) map? : %b (%s)", g_bIs_c5m2_park, g_bIs_c5m2_park ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}