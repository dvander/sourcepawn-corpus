/**
// ====================================================================================================
Change Log:

1.0.1 (18-August-2022)
    - Added L4D1 support. (thanks "HarryPotter" for reporting)

1.0.0 (13-August-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Display Equipments"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Configure which equipped items should display on clients back/belt."
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=339066"

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
#define CONFIG_FILENAME               "l4d_display_equipments"

// ====================================================================================================
// Defines
// ====================================================================================================
#define L4D1_AddonBits_None           (0 << 0) // 0
#define L4D1_AddonBits_Kit            (1 << 0) // 1
#define L4D1_AddonBits_Pills          (1 << 1) // 2
#define L4D1_AddonBits_PipeBomb       (1 << 2) // 4
#define L4D1_AddonBits_Molotov        (1 << 3) // 8
#define L4D1_AddonBits_Primary        (1 << 4) // 16
#define L4D1_AddonBits_Pistol         (1 << 5) // 32
#define L4D1_AddonBits_Dual           (1 << 6) // 64 // set when has dual pistols not active, but has no visual changes
//#define L4D1_AddonBits_Unknown        (1 << 7) // 128 // set when dual wield pistols, but has no visual changes
#define L4D1_AddonBits_Tongue         (1 << 9) // 512

#define L4D2_AddonBits_None           (0 << 0) // 0
#define L4D2_AddonBits_Primary        (1 << 0) // 1
#define L4D2_AddonBits_Secondary      (1 << 1) // 2
#define L4D2_AddonBits_Throwables     (1 << 2) // 4
#define L4D2_AddonBits_KitDefibPacks  (1 << 3) // 8
#define L4D2_AddonBits_PillsAdren     (1 << 4) // 16
#define L4D2_AddonBits_Tongue         (1 << 5) // 32
//#define L4D2_AddonBits_DefibUnknown   (1 << 6), // 64 // broken defib model, useless
#define L4D2_AddonBits_Diesel         (1 << 7) // 128 // usually visible in Hard Rain campaign

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_DisplayL4D1;
ConVar g_hCvar_DisplayL4D2;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bL4D2;
bool g_bCvar_Enabled;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_DisplayL4D1;
int g_iCvar_DisplayL4D2;
int iAddonBits;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bPostThinkPostHooked[MAXPLAYERS+1];

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

    g_bL4D2 = (engine == Engine_Left4Dead2);

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d_display_equipments_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled     = CreateConVar("l4d_display_equipments_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_DisplayL4D1 = CreateConVar("l4d1_display_equipments_display", "0", "[L4D1] Which equipped items should display on clients back/belt.\n0 = None, 1 = Kit, 2 = Pills, 4 = Pipe Bomb, 8 = Molotov, 16 = Primary Weapons, 32 = Pistols, 512 = Tongue.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 1023.0);
    g_hCvar_DisplayL4D2 = CreateConVar("l4d2_display_equipments_display", "0", "[L4D2] Which equipped items should display on clients back/belt.\n0 = None, 1 = Primary Weapons, 2 = Secondary Weapons, 4 = Throwables, 8 = Kit/Defib/Packs, 16 = Pills/Adren, 32 = Tongue, 128 = Diesel.\nAdd numbers greater than 0 for multiple options.", CVAR_FLAGS, true, 0.0, true, 255.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DisplayL4D1.AddChangeHook(Event_ConVarChanged);
    g_hCvar_DisplayL4D2.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_print_cvars_l4d_display_equipments", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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
    g_iCvar_DisplayL4D1 = g_hCvar_DisplayL4D1.IntValue;
    g_iCvar_DisplayL4D2 = g_hCvar_DisplayL4D2.IntValue;
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
    if (gc_bPostThinkPostHooked[client])
        return;

    gc_bPostThinkPostHooked[client] = true;
    SDKHook(client, SDKHook_PostThinkPost, g_bL4D2 ? OnPostThinkPostL4D2 : OnPostThinkPostL4D1);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bPostThinkPostHooked[client] = false;
}

/****************************************************************************************************/

void OnPostThinkPostL4D2(int client)
{
    if (!g_bCvar_Enabled)
        return;

    iAddonBits = GetEntProp(client, Prop_Send, "m_iAddonBits");

    if (iAddonBits == 0)
        return;

    if (g_iCvar_DisplayL4D2 == 0)
    {
         SetEntProp(client, Prop_Send, "m_iAddonBits", L4D2_AddonBits_None);
    }
    else
    {
        if (!(g_iCvar_DisplayL4D2 & L4D2_AddonBits_Primary))
            iAddonBits &= ~L4D2_AddonBits_Primary;

        if (!(g_iCvar_DisplayL4D2 & L4D2_AddonBits_Secondary))
            iAddonBits &= ~L4D2_AddonBits_Secondary;

        if (!(g_iCvar_DisplayL4D2 & L4D2_AddonBits_Throwables))
            iAddonBits &= ~L4D2_AddonBits_Throwables;

        if (!(g_iCvar_DisplayL4D2 & L4D2_AddonBits_KitDefibPacks))
            iAddonBits &= ~L4D2_AddonBits_KitDefibPacks;

        if (!(g_iCvar_DisplayL4D2 & L4D2_AddonBits_PillsAdren))
            iAddonBits &= ~L4D2_AddonBits_PillsAdren;

        if (!(g_iCvar_DisplayL4D2 & L4D2_AddonBits_Tongue))
            iAddonBits &= ~L4D2_AddonBits_Tongue;

        if (!(g_iCvar_DisplayL4D2 & L4D2_AddonBits_Diesel))
            iAddonBits &= ~L4D2_AddonBits_Diesel;

        SetEntProp(client, Prop_Send, "m_iAddonBits", iAddonBits);
    }
}

/****************************************************************************************************/

void OnPostThinkPostL4D1(int client)
{
    if (!g_bCvar_Enabled)
        return;

    iAddonBits = GetEntProp(client, Prop_Send, "m_iAddonBits");

    if (iAddonBits == 0)
        return;

    if (g_iCvar_DisplayL4D1 == 0)
    {
         SetEntProp(client, Prop_Send, "m_iAddonBits", L4D1_AddonBits_None);
    }
    else
    {
        if (!(g_iCvar_DisplayL4D1 & L4D1_AddonBits_Kit))
            iAddonBits &= ~L4D1_AddonBits_Kit;

        if (!(g_iCvar_DisplayL4D1 & L4D1_AddonBits_Pills))
            iAddonBits &= ~L4D1_AddonBits_Pills;

        if (!(g_iCvar_DisplayL4D1 & L4D1_AddonBits_PipeBomb))
            iAddonBits &= ~L4D1_AddonBits_PipeBomb;

        if (!(g_iCvar_DisplayL4D1 & L4D1_AddonBits_Molotov))
            iAddonBits &= ~L4D1_AddonBits_Molotov;

        if (!(g_iCvar_DisplayL4D1 & L4D1_AddonBits_Primary))
            iAddonBits &= ~L4D1_AddonBits_Primary;

        if (!(g_iCvar_DisplayL4D1 & L4D1_AddonBits_Pistol))
            iAddonBits &= ~(L4D1_AddonBits_Pistol|L4D1_AddonBits_Dual);

        if (!(g_iCvar_DisplayL4D1 & L4D1_AddonBits_Tongue))
            iAddonBits &= ~L4D1_AddonBits_Tongue;

        SetEntProp(client, Prop_Send, "m_iAddonBits", iAddonBits);
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
    PrintToConsole(client, "--------------- Plugin Cvars (l4d_display_equipments) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_display_equipments_ver : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_display_equipments_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d1_display_equipments_display : %i (Kit = %s | Pills = %s | Pipe Bomb = %s | Molotov = %s | Primary Weapons = %s | Pistols = %s | Tongue = %s)", g_iCvar_DisplayL4D1,
    g_iCvar_DisplayL4D1 & L4D1_AddonBits_Kit ? "true" : "false", g_iCvar_DisplayL4D1 & L4D1_AddonBits_Pills ? "true" : "false", g_iCvar_DisplayL4D1 & L4D1_AddonBits_PipeBomb ? "true" : "false",
    g_iCvar_DisplayL4D1 & L4D1_AddonBits_Molotov ? "true" : "false", g_iCvar_DisplayL4D1 & L4D1_AddonBits_Primary ? "true" : "false", g_iCvar_DisplayL4D1 & L4D1_AddonBits_Pistol ? "true" : "false",
    g_iCvar_DisplayL4D1 & L4D1_AddonBits_Tongue ? "true" : "false");
    PrintToConsole(client, "l4d2_display_equipments_display : %i (Primary Weapons = %s | Secondary Weapons = %s | Throwables = %s | Kit/Defib/Packs = %s | Pills/Adrenaline = %s | Tongue = %s | Diesel = %s)", g_iCvar_DisplayL4D2,
    g_iCvar_DisplayL4D2 & L4D2_AddonBits_Primary ? "true" : "false", g_iCvar_DisplayL4D2 & L4D2_AddonBits_Secondary ? "true" : "false", g_iCvar_DisplayL4D2 & L4D2_AddonBits_Throwables ? "true" : "false",
    g_iCvar_DisplayL4D2 & L4D2_AddonBits_KitDefibPacks ? "true" : "false", g_iCvar_DisplayL4D2 & L4D2_AddonBits_PillsAdren ? "true" : "false", g_iCvar_DisplayL4D2 & L4D2_AddonBits_Tongue ? "true" : "false",
    g_iCvar_DisplayL4D2 & L4D2_AddonBits_Diesel ? "true" : "false");
    if (!g_bL4D2)
    {
        PrintToConsole(client, "");
        PrintToConsole(client, "---------------------------- Game Cvars  -----------------------------");
        PrintToConsole(client, "");
        PrintToConsole(client, "survivor_draw_addons : %i", FindConVar("survivor_draw_addons").IntValue);
    }
    PrintToConsole(client, "");
    PrintToConsole(client, "------------------------ Clients m_iAddonBits ------------------------");
    PrintToConsole(client, "");
    for (int target = 1; target <= MaxClients; target++)
    {
        if (!IsClientInGame(target))
            continue;

        PrintToConsole(client, "%N: %i", target, GetEntProp(target, Prop_Send, "m_iAddonBits"));
    }
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}