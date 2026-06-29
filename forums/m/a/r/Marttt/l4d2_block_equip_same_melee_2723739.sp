/**
// ====================================================================================================
Change Log:

1.0.3 (08-July-2023)
    - Refactored code.

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
#define PLUGIN_VERSION                "1.0.3"
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
// client - Plugin Variables
// ====================================================================================================
bool gc_bOnWeaponCanUseHooked[MAXPLAYERS+1];

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d2_block_equip_same_melee_ver;
    ConVar l4d2_block_equip_same_melee_enable;
    ConVar l4d2_block_equip_same_melee_check_skin;

    void Init()
    {
        this.l4d2_block_equip_same_melee_ver        = CreateConVar("l4d2_block_equip_same_melee_ver", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d2_block_equip_same_melee_enable     = CreateConVar("l4d2_block_equip_same_melee_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d2_block_equip_same_melee_check_skin = CreateConVar("l4d2_block_equip_same_melee_check_skin", "1", "Check if both melees are the same but have different skins to allow being equipped. \n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.l4d2_block_equip_same_melee_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d2_block_equip_same_melee_check_skin.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool enabled;
    bool checkSkin;

    void Init()
    {
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enabled = this.cvars.l4d2_block_equip_same_melee_enable.BoolValue;
        this.checkSkin = this.cvars.l4d2_block_equip_same_melee_check_skin.BoolValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_print_cvars_l4d2_block_equip_same_melee", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
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
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        plugin.enabled ? HookClient(client) : UnhookClient(client);
    }
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (!plugin.enabled)
        return;

    HookClient(client);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bOnWeaponCanUseHooked[client] = false;
}

/****************************************************************************************************/

void HookClient(int client)
{
    if (gc_bOnWeaponCanUseHooked[client])
        return;

    gc_bOnWeaponCanUseHooked[client] = true;
    SDKHook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

/****************************************************************************************************/

void UnhookClient(int client)
{
    if (!gc_bOnWeaponCanUseHooked[client])
        return;

    gc_bOnWeaponCanUseHooked[client] = false;
    SDKUnhook(client, SDKHook_WeaponCanUse, OnWeaponCanUse);
}

/****************************************************************************************************/

Action OnWeaponCanUse(int client, int weapon)
{
    if (!IsValidEntity(weapon))
        return Plugin_Continue;

    int entity = GetPlayerWeaponSlot(client, 1);

    if (!IsValidEntity(entity))
        return Plugin_Continue;

    char classname[36];
    GetEntityClassname(entity, classname, sizeof(classname));

    if (!StrEqual(classname, "weapon_melee"))
        return Plugin_Continue;

    if (GetEntProp(weapon, Prop_Send, "m_iWorldModelIndex") != GetEntProp(entity, Prop_Send, "m_iWorldModelIndex"))
        return Plugin_Continue;

    if (plugin.checkSkin && GetEntProp(weapon, Prop_Send, "m_nSkin") != GetEntProp(entity, Prop_Send, "m_nSkin"))
        return Plugin_Continue;

    return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "------------- Plugin Cvars (l4d2_block_equip_same_melee) -------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_block_equip_same_melee_ver : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_block_equip_same_melee_enable : %b (%s)", plugin.enabled, plugin.enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_block_equip_same_melee_check_skin : %b (%s)", plugin.checkSkin, plugin.checkSkin ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}