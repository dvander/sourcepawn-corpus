/**
// ====================================================================================================
Change Log:

1.0.0 (12-October-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Grenade Launcher World Hit Fix"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Makes the grenade launcher projectile explode when hit the world min/max instead of vanishing"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=327835"

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
#define CONFIG_FILENAME               "l4d2_gl_world_hit_fix"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_GL_PROJECTILE       "grenade_launcher_projectile"

#define ENTITY_WORLDSPAWN             0

#define DAMAGE_YES                    2

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
    CreateConVar("l4d2_gl_world_hit_fix_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d2_gl_world_hit_fix_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_gl_world_hit_fix", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
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
    while ((entity = FindEntityByClassname(entity, CLASSNAME_GL_PROJECTILE)) != INVALID_ENT_REFERENCE)
    {
        SDKHook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 'g')
        return;

    if (StrEqual(classname, CLASSNAME_GL_PROJECTILE))
        SDKHook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
}

/****************************************************************************************************/

public void OnStartTouchPost(int entity, int other)
{
    if (!g_bCvar_Enabled)
        return;

    if (other != ENTITY_WORLDSPAWN)
        return;

    SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_YES);
    SDKHooks_TakeDamage(entity, ENTITY_WORLDSPAWN, ENTITY_WORLDSPAWN, 0.0, DMG_GENERIC, -1, NULL_VECTOR, NULL_VECTOR);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d2_gl_world_hit_fix) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_gl_world_hit_fix_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_gl_world_hit_fix_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
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