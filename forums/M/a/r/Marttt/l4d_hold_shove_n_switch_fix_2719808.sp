/**
// ====================================================================================================
Change Log:

1.0.2 (16-October-2020)
    - Performance tweaks on OnPlayerRunCmd.

1.0.1 (15-October-2020)
    - Fixed a bug preventing bots to heal. (thanks "Alex Alcalá" for reporting)
    - Removed bots from OnPlayerRunCmd.
    - Added L4D1 support.

1.0.0 (01-October-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Hold Shove and Switch Fix"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Fixes a bug that prevents a client from continuing to shove when the weapon is switched while still holding down the shove button (M2)"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=327640"

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
#define CONFIG_FILENAME               "l4d_hold_shove_n_switch_fix"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bCvar_Enabled;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bWeaponSwitchPostHooked[MAXPLAYERS+1];
bool gc_bWeaponSwitched[MAXPLAYERS+1];

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
    CreateConVar("l4d_hold_shove_n_switch_fix_ver", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d_hold_shove_n_switch_fix_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_hold_shove_n_switch_fix", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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

    LateLoad();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
}

/****************************************************************************************************/

void LateLoad()
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
    if (IsFakeClient(client))
        return;

    if (gc_bWeaponSwitchPostHooked[client])
        return;

    gc_bWeaponSwitchPostHooked[client] = true;
    SDKHook(client, SDKHook_WeaponSwitchPost, OnWeaponSwitchPost);

    OnWeaponSwitchPost(client, -1);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bWeaponSwitchPostHooked[client] = false;
    gc_bWeaponSwitched[client] = false;
}

/****************************************************************************************************/

void OnWeaponSwitchPost(int client, int weapon)
{
    if (!g_bCvar_Enabled)
        return;

    gc_bWeaponSwitched[client] = true;
}

/****************************************************************************************************/

public Action OnPlayerRunCmd(int client, int &buttons)
{
    if (client < 0)
        return Plugin_Continue;

    if (!gc_bWeaponSwitched[client])
        return Plugin_Continue;

    gc_bWeaponSwitched[client] = false;
    buttons &= ~IN_ATTACK2;

    return Plugin_Changed;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------- Plugin Cvars (l4d_hold_shove_n_switch_fix) -------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_hold_shove_n_switch_fix_ver : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_hold_shove_n_switch_fix_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}