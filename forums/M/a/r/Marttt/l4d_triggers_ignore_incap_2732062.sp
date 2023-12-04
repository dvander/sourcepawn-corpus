/**
// ====================================================================================================
Change Log:

1.0.1 (08-July-2023)
    - Refactored code.

1.0.0 (09-January-2021)
    - Initial release.

// ====================================================================================================
*/

/**
if you want to do that through the stripper extension (http://www.bailopan.net/stripper/#install) instead a plugin,
add the following lines to the global.cfg or to <map>.cfg file:

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
**/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Trigger Multiple Ignore Incapacitated"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Allow trigger_multiple entities to ignore incapacitated players to trigger"
#define PLUGIN_VERSION                "1.0.1"
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
#define ALLOWINCAPTOUCH_NO            0

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d_triggers_ignore_incap_version;
    ConVar l4d_triggers_ignore_incap_enable;

    void Init()
    {
        this.l4d_triggers_ignore_incap_version = CreateConVar("l4d_triggers_ignore_incap_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d_triggers_ignore_incap_enable  = CreateConVar("l4d_triggers_ignore_incap_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.l4d_triggers_ignore_incap_enable.AddChangeHook(Event_ConVarChanged);

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
        this.enabled = this.cvars.l4d_triggers_ignore_incap_enable.BoolValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_l4d_triggers_ignore_incap", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
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
    if (!plugin.enabled)
        return;

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "trigger_multiple")) != INVALID_ENT_REFERENCE)
    {
        RequestFrame(Frame_LateLoad, EntIndexToEntRef(entity));
    }
}

/****************************************************************************************************/

void Frame_LateLoad(int entityRef)
{
    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    OnSpawnPost(entity);
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!plugin.enabled)
        return;

    if (entity < 0)
        return;

    if (StrEqual(classname, "trigger_multiple"))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    SetEntProp(entity, Prop_Data, "m_bAllowIncapTouch", ALLOWINCAPTOUCH_NO);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------- Plugin Cvars (l4d_triggers_ignore_incap) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_triggers_ignore_incap_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_triggers_ignore_incap_enable : %b (%s)", plugin.enabled, plugin.enabled ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}