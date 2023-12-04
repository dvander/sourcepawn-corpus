/**
// ====================================================================================================
Change Log:

1.0.1 (08-July-2023)
    - Refactored code.

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
#define PLUGIN_VERSION                "1.0.1"
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
#define ENTITY_WORLDSPAWN             0

#define DAMAGE_YES                    2

#define MAXENTITIES                   2048

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bOnStartTouchPostHooked[MAXENTITIES+1];

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d2_gl_world_hit_fix_version;
    ConVar l4d2_gl_world_hit_fix_enable;

    void Init()
    {
        this.l4d2_gl_world_hit_fix_version = CreateConVar("l4d2_gl_world_hit_fix_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d2_gl_world_hit_fix_enable  = CreateConVar("l4d2_gl_world_hit_fix_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.l4d2_gl_world_hit_fix_enable.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool enabled;

    void Init()
    {
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enabled = this.cvars.l4d2_gl_world_hit_fix_enable.BoolValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_l4d2_gl_world_hit_fix", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
    }
}

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

    LateLoad();
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "grenade_launcher_projectile")) != INVALID_ENT_REFERENCE)
    {
        plugin.enabled ? HookEntity(entity) : UnhookEntity(entity);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!plugin.enabled)
        return;

    if (entity < 0)
        return;

    if (StrEqual(classname, "grenade_launcher_projectile"))
        HookEntity(entity);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bOnStartTouchPostHooked[entity] = false;
}

/****************************************************************************************************/

void HookEntity(int entity)
{
    if (ge_bOnStartTouchPostHooked[entity])
        return;

    ge_bOnStartTouchPostHooked[entity] = true;
    SDKHook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
}

/****************************************************************************************************/

void UnhookEntity(int entity)
{
    if (!ge_bOnStartTouchPostHooked[entity])
        return;

    ge_bOnStartTouchPostHooked[entity] = false;
    SDKUnhook(entity, SDKHook_StartTouchPost, OnStartTouchPost);
}

/****************************************************************************************************/

void OnStartTouchPost(int entity, int other)
{
    if (!plugin.enabled)
        return;

    if (other != ENTITY_WORLDSPAWN)
        return;

    SetEntProp(entity, Prop_Data, "m_takedamage", DAMAGE_YES);
    SDKHooks_TakeDamage(entity, ENTITY_WORLDSPAWN, ENTITY_WORLDSPAWN, 0.0);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d2_gl_world_hit_fix) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_gl_world_hit_fix_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_gl_world_hit_fix_enable : %b (%s)", plugin.enabled, plugin.enabled ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}