/**
// ====================================================================================================
Change Log:

1.0.0 (25-December-2022)
    - Initial release.

// ====================================================================================================
*/

/**
if you want to do that through the stripper extension (http://www.bailopan.net/stripper/#install) instead a plugin,
add the following lines to the maps/c5m2_park.cfg file:

filter:
{
    "classname" "trigger_multiple"
    "targetname" "finale_decon_trigger"
    //"hammerid" "456409"
}
{
    "classname" "info_game_event_proxy"
    "targetname" "finale_decon_wait_hint"
    //"hammerid" "456481"
}
{
    "classname" "info_game_event_proxy"
    "targetname" "finale_decon_start_hint"
    //"hammerid" "456483"
}
{
    "classname" "logic_relay"
    "targetname" "finale_decon_hints_relay1"
    //"hammerid" "1760764"
}
{
    "classname" "logic_relay"
    "targetname" "finale_decon_hints_relay2"
    //"hammerid" "1760799"
}
{
    "classname" "logic_branch_listener"
    "targetname" "ceda_trailer_canopen_frontdoor_listener"
    //"hammerid" "1653451"
}
{
    "classname" "logic_branch"
    "targetname" "ceda_trailer_allinside_branch"
    //"hammerid" "1653460"
}
{
    "classname" "logic_branch"
    "targetname" "ceda_trailer_doorclosed_branch"
    //"hammerid" "1653547"
}

modify:
{
    match:
    {
        "classname" "prop_door_rotating"
        "targetname" "finale_cleanse_exit_door"
        //"hammerid" "1239243"
    }
    replace:
    {
        "spawnflags" "532480"
        //from "526336" (Start Unbreakable|Starts locked) to "524288" (Start Unbreakable|Use closes)
        "spawnflags" "532480"
        //from "40" to "200"
        "speed" "200"
        //from "180" to "90"
        "distance" "90"
    }
    insert:
    {
        "OnOpen" "finale_cleanse_entrance_door,Unlock,,0.1,-1"
    }
}
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Unlock CEDA Trailer (c5m2_park)"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Unlocks the CEDA trailer exit door in c5m2_park map to not be necessary to wait the whole team inside the trailer to unlock it"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=341040"

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
#define CONFIG_FILENAME               "l4d_c5m2_ceda_door_unlock"

// ====================================================================================================
// Defines
// ====================================================================================================
#define FLAG_USE_CLOSES               8192

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
    CreateConVar("l4d_c5m2_ceda_door_unlock_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d_c5m2_ceda_door_unlock_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

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
    while ((entity = FindEntityByClassname(entity, "trigger_multiple")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Remove_TriggerMultiple, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "info_game_event_proxy")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Remove_InfoGameEventProxy, EntIndexToEntRef(entity));
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "logic_relay")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(RemoveAndFix_LogicRelay, entity);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "logic_branch_listener")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Remove_LogicBranchListener, entity);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "logic_branch")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Remove_LogicBranch, entity);
    }

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Fix_PropDoorRotating, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bIs_c5m2_park)
        return;

    if (!g_bCvar_Enabled)
        return;

    if (StrEqual(classname, "trigger_multiple"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_TriggerMultiple);
        return;
    }

    if (StrEqual(classname, "info_game_event_proxy"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_InfoGameEventProxy);
        return;
    }

    if (StrEqual(classname, "logic_relay"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_LogicRelay);
        return;
    }

    if (StrEqual(classname, "logic_branch_listener"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_LogicBranchListener);
        return;
    }

    if (StrEqual(classname, "logic_branch"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_LogicBranch);
        return;
    }

    if (StrEqual(classname, "prop_door_rotating"))
    {
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost_PropDoorRotating);
        return;
    }
}

/****************************************************************************************************/

void OnSpawnPost_TriggerMultiple(int entity)
{
    Remove_TriggerMultiple(EntIndexToEntRef(entity));
}

/****************************************************************************************************/

void OnSpawnPost_InfoGameEventProxy(int entity)
{
    Remove_InfoGameEventProxy(EntIndexToEntRef(entity));
}

/****************************************************************************************************/

void OnSpawnPost_LogicRelay(int entity)
{
    RemoveAndFix_LogicRelay(entity);
}

/****************************************************************************************************/

void OnSpawnPost_LogicBranchListener(int entity)
{
    Remove_LogicBranchListener(entity);
}

/****************************************************************************************************/

void OnSpawnPost_LogicBranch(int entity)
{
    Remove_LogicBranch(entity);
}

/****************************************************************************************************/

void OnSpawnPost_PropDoorRotating(int entity)
{
    Fix_PropDoorRotating(EntIndexToEntRef(entity));
}

/****************************************************************************************************/

void Remove_TriggerMultiple(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    char targetname[22];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, "finale_decon_trigger"))
        RemoveEntity(entity);
}

/****************************************************************************************************/

void Remove_InfoGameEventProxy(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    char targetname[25];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, "finale_decon_wait_hint"))
        RemoveEntity(entity);

    if (StrEqual(targetname, "finale_decon_start_hint"))
        RemoveEntity(entity);
}

/****************************************************************************************************/

// Note: logic_relay already is an entity reference (negative index)
void RemoveAndFix_LogicRelay(int entityRef)
{
    if (!IsValidEntity(entityRef))
        return;

    char targetname[32];
    GetEntPropString(entityRef, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, "finale_decon_hints_relay1"))
        RemoveEntity(entityRef);

    if (StrEqual(targetname, "finale_decon_hints_relay2"))
        RemoveEntity(entityRef);

    if (StrEqual(targetname, "finale_cleanse_exit_door_relay"))
        HookSingleEntityOutput(entityRef, "OnTrigger", OnTrigger_LogicRelay, true);
}

/****************************************************************************************************/

void OnTrigger_LogicRelay(const char[] output, int caller, int activator, float delay)
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "prop_door_rotating")) != INVALID_ENT_REFERENCE)
    {
        char targetname[30];
        GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

        if (StrEqual(targetname, "finale_cleanse_entrance_door"))
        {
            RequestFrame(OnNextFrame_LogicRelay, EntIndexToEntRef(entity));
            return;
        }
    }
}

/****************************************************************************************************/

void OnNextFrame_LogicRelay(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    AcceptEntityInput(entity, "Unlock");
}

/****************************************************************************************************/

// Note: logic_branch_listener already is an entity reference (negative index)
void Remove_LogicBranchListener(int entityRef)
{
    if (!IsValidEntity(entityRef))
        return;

    char targetname[41];
    GetEntPropString(entityRef, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, "ceda_trailer_canopen_frontdoor_listener"))
        RemoveEntity(entityRef);
}

/****************************************************************************************************/

// Note: logic_branch already is an entity reference (negative index)
void Remove_LogicBranch(int entityRef)
{
    if (!IsValidEntity(entityRef))
        return;

    char targetname[32];
    GetEntPropString(entityRef, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, "ceda_trailer_allinside_branch"))
        RemoveEntity(entityRef);

    if (StrEqual(targetname, "ceda_trailer_doorclosed_branch"))
        RemoveEntity(entityRef);
}

/****************************************************************************************************/

void Fix_PropDoorRotating(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    char targetname[26];
    GetEntPropString(entity, Prop_Data, "m_iName", targetname, sizeof(targetname));

    if (StrEqual(targetname, "finale_cleanse_exit_door"))
    {
        SetEntProp(entity, Prop_Send, "m_bLocked", 0);
        SetEntProp(entity, Prop_Send, "m_spawnflags", GetEntProp(entity, Prop_Send, "m_spawnflags") | FLAG_USE_CLOSES);
        SetEntPropFloat(entity, Prop_Data, "m_flSpeed", 200.0);
        SetEntPropFloat(entity, Prop_Data, "m_flDistance", 90.0);
        SetEntPropVector(entity, Prop_Data, "m_angRotationOpenForward", view_as<float>({ 0.0, 270.0, 0.0}));
        SetEntPropVector(entity, Prop_Data, "m_angRotationClosed", view_as<float>({ 0.0, 180.0, 0.0}));
        SetEntPropVector(entity, Prop_Data, "m_angRotationOpenBack", view_as<float>({ 0.0, 90.0, 0.0}));
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
    PrintToConsole(client, "------------- Plugin Cvars (l4d_c5m2_ceda_door_unlock) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_c5m2_ceda_door_unlock_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_c5m2_ceda_door_unlock_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
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