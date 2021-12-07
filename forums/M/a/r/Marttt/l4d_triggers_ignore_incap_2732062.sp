/**
// ====================================================================================================
Change Log:

1.0.0 (09-January-2021)
    - Initial release.

// ====================================================================================================
*/

/**
if you want to do that through the stripper extension (http://www.bailopan.net/stripper/#install) instead a plugin,
add the following lines to the global.cfg or to <mapname>.cfg file:

modify:
{
    match:
    {
        "classname" "trigger_multiple"
    }
    replace:
    {
        "allowincap" "0"
    }
}
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Trigger Multiple Ignore Incapacitated"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Allow trigger_multiple entities to ignore incapacitated players to trigger"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=329848"

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
#define CONFIG_FILENAME               "l4d_triggers_ignore_incap"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_TRIGGER_MULTIPLE    "trigger_multiple"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;

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
    CreateConVar("l4d_triggers_ignore_incap_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d_triggers_ignore_incap_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_triggers_ignore_incap", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
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
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_TRIGGER_MULTIPLE)) != INVALID_ENT_REFERENCE)
    {
        OnSpawnPost(entity);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 't')
        return;

    if (StrEqual(classname, CLASSNAME_TRIGGER_MULTIPLE))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
    RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    SetEntProp(entity, Prop_Data, "m_bAllowIncapTouch", 0);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------- Plugin Cvars (l4d_triggers_ignore_incap) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_triggers_ignore_incap_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_triggers_ignore_incap_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
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