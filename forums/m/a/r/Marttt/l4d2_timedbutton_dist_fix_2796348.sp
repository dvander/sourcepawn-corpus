/**
// ====================================================================================================
Change Log:

1.0.1 (15-February-2023)
    - Fixed plugin not working with non-solid buttons. (thanks "Shao" for reporting)

1.0.0 (01-January-2023)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Timed Button Distance Exploit Fix"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Resets the button progress bar when the activator distance exceeds the maximum allowed"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=341119"

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
#define CONFIG_FILENAME               "l4d2_timedbutton_dist_fix"

// ====================================================================================================
// Defines
// ====================================================================================================
#define L4D2_USEACTION_TIMEDBUTTON    10

#define MAXENTITIES                   2048

// ====================================================================================================
// Game Cvars
// ====================================================================================================
ConVar g_hCvar_player_use_radius;

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bCvar_Enabled;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_player_use_radius;

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
bool ge_bValidRange[MAXENTITIES+1];

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
    g_hCvar_player_use_radius = FindConVar("player_use_radius");

    CreateConVar("l4d2_timedbutton_dist_fix_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d2_timedbutton_dist_fix_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_player_use_radius.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_timedbutton_dist_fix", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

void GetCvars()
{
    g_fCvar_player_use_radius = g_hCvar_player_use_radius.FloatValue;
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_bValidRange[entity] = false;
}

/****************************************************************************************************/

public void OnPlayerRunCmdPost(int client, int buttons)
{
    if (!g_bCvar_Enabled)
        return;

    if (!(buttons & IN_USE))
        return;

    if (client == -1)
        return;

    if (GetEntProp(client, Prop_Send, "m_iCurrentUseAction") != L4D2_USEACTION_TIMEDBUTTON)
        return;

    int target = GetEntPropEnt(client, Prop_Send, "m_useActionTarget");

    if (target == -1)
        return;

    float vPos[3];
    GetClientEyePosition(client, vPos);

    ge_bValidRange[target] = false;
    TR_EnumerateEntitiesSphere(vPos, g_fCvar_player_use_radius, PARTITION_NON_STATIC_EDICTS, TraceEntityEnumeratorFilter, target);

    if (!ge_bValidRange[target])
    {
        SetEntProp(client, Prop_Send, "m_useActionTarget", 0);
        SetEntProp(client, Prop_Send, "m_useActionOwner", 0);
        SetEntProp(client, Prop_Send, "m_iCurrentUseAction", 0);
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarStartTime", 0.0);
        SetEntPropFloat(client, Prop_Send, "m_flProgressBarDuration", 0.0);
    }
}

/****************************************************************************************************/

bool TraceEntityEnumeratorFilter(int entity, int target)
{
    if (entity == target)
    {
        ge_bValidRange[target] = true;
        return false; // after found, stop looping through entities
    }

    return true;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------- Plugin Cvars (l4d2_timedbutton_dist_fix) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_timedbutton_dist_fix_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_timedbutton_dist_fix_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "player_use_radius : %i", g_fCvar_player_use_radius);
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}