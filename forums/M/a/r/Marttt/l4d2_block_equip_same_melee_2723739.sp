/**
// ====================================================================================================
Change Log:

1.0.2 (11-November-2020)
    - Fixed block by checking Slot 2 instead of active weapon.

1.0.1 (05-November-2020)
    - Added cvar to allow melees with different skins being equipped. (thanks "HarryPotter" for requesting)

1.0.0 (04-November-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Block Equipping Same Melee"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Prevents picking up an already equipped melee weapon"
#define PLUGIN_VERSION                "1.0.2"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328326"

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
#define CONFIG_FILENAME               "l4d2_block_equip_same_melee"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_CheckSkin;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_CheckSkin;

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
    CreateConVar("l4d2_block_equip_same_melee_ver", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled   = CreateConVar("l4d2_block_equip_same_melee_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_CheckSkin = CreateConVar("l4d2_block_equip_same_melee_check_skin", "0", "Check if both melees are the same but have different skins to allow being equipped. \n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_CheckSkin.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d2_block_equip_same_melee", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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
    g_bCvar_CheckSkin = g_hCvar_CheckSkin.BoolValue;
}

/****************************************************************************************************/

public void LateLoad()
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
    if (!g_bConfigLoaded)
        return;

    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

/****************************************************************************************************/

public Action OnWeaponCanUse(int client, int weapon)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (!IsValidEntity(weapon))
        return Plugin_Continue;

    if (!HasEntProp(weapon, Prop_Data, "m_strMapSetScriptName")) // CTerrorMeleeWeapon
        return Plugin_Continue;

    int entity = GetPlayerWeaponSlot(client, 1);

    if (!IsValidEntity(entity))
        return Plugin_Continue;

    if (!HasEntProp(entity, Prop_Data, "m_strMapSetScriptName")) // CTerrorMeleeWeapon
        return Plugin_Continue;

    char namePickupWeapon[16];
    GetEntPropString(weapon, Prop_Data, "m_strMapSetScriptName", namePickupWeapon, sizeof(namePickupWeapon));

    char nameEntityWeapon[16];
    GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", nameEntityWeapon, sizeof(nameEntityWeapon));

    if (!StrEqual(namePickupWeapon, nameEntityWeapon))
        return Plugin_Continue;

    if (!g_bCvar_CheckSkin)
        return Plugin_Handled;

    int pickupWeaponSkin = GetEntProp(weapon, Prop_Send, "m_nSkin");
    int entityWeaponSkin = GetEntProp(entity, Prop_Send, "m_nSkin");

    if (pickupWeaponSkin != entityWeaponSkin)
        return Plugin_Continue;

    return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------- Plugin Cvars (l4d2_block_equip_same_melee) -------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_block_equip_same_melee_ver : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_block_equip_same_melee_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_block_equip_same_melee_check_skin : %b (%s)", g_bCvar_CheckSkin, g_bCvar_CheckSkin ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
/**
 * Validates if is a valid client index.
 *
 * @param client          Client index.
 * @return                True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client          Client index.
 * @return                True if client index is valid and client is in game, false otherwise.
 */
bool IsValidClient(int client)
{
    return (IsValidClientIndex(client) && IsClientInGame(client));
}