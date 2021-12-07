/**
// ====================================================================================================
Change Log:

1.0.3 (17-January-2021)
    - Picked up weapons no longer have the default glow. (thanks "SDArt" for reporting)
    - Added cvar to control glow on Machine Guns (50cal and minigun).

1.0.2 (08-January-2021)
    - Fixed glow not being applied to scavenge gascan when enabled. (thanks "a2121858" for reporting)

1.0.1 (05-January-2021)
    - Added cvar to delete spawner entities when its count reaches 0.
    - Fixed some prop_physics not glowing on drop.

1.0.0 (31-December-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Random Glow Item"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Gives a random glow to items on the map"
#define PLUGIN_VERSION                "1.0.3"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=329617"

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
#define CONFIG_FILENAME               "l4d2_random_glow_item"

// ====================================================================================================
// Defines
// ====================================================================================================
#define MODEL_GASCAN                  "models/props_junk/gascan001a.mdl"
#define MODEL_FUEL_BARREL             "models/props_industrial/barrel_fuel.mdl"
#define MODEL_PROPANECANISTER         "models/props_junk/propanecanister001a.mdl"
#define MODEL_OXYGENTANK              "models/props_equipment/oxygentank01.mdl"
#define MODEL_BARRICADE_GASCAN        "models/props_unique/wooden_barricade_gascans.mdl"
#define MODEL_GAS_PUMP                "models/props_equipment/gas_pump_nodebris.mdl"
#define MODEL_FIREWORKS_CRATE         "models/props_junk/explosive_box001.mdl"

#define MODEL_GNOME                   "models/props_junk/gnome.mdl"
#define MODEL_COLA                    "models/w_models/weapons/w_cola.mdl"

#define GLOW_TYPE_NONE                0

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_GlowColor;
static ConVar g_hCvar_GlowType;
static ConVar g_hCvar_GlowFlashing;
static ConVar g_hCvar_GlowMinDistance;
static ConVar g_hCvar_GlowMaxDistance;
static ConVar g_hCvar_GlowMinBrightness;
static ConVar g_hCvar_ScavengeGascan;
static ConVar g_hCvar_Cola;
static ConVar g_hCvar_MachineGun;
static ConVar g_hCvar_RemoveSpawner;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bEventsHooked;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_RandomGlowColor;
static bool   g_bCvar_GlowFlashing;
static bool   g_bCvar_ScavengeGascan;
static bool   g_bCvar_Cola;
static bool   g_bCvar_MachineGun;
static bool   g_bCvar_RemoveSpawner;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iModel_Gascan = -1;
static int    g_iCvar_GlowColor[3];
static int    g_iCvar_GlowType;
static int    g_iCvar_GlowMinDistance;
static int    g_iCvar_GlowMaxDistance;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
static float  g_fCvar_MinBrightness;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char   g_sCvar_GlowColor[12];

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
    CreateConVar("l4d2_random_glow_item_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled           = CreateConVar("l4d2_random_glow_item_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GlowColor         = CreateConVar("l4d2_random_glow_item_color", "random", "Item glow color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\"), to apply a specific color.\nExamples:\nl4d2_random_glow_item_color \"random\"\nl4d2_random_glow_item_color \"255 0 0\"", CVAR_FLAGS);
    g_hCvar_GlowType          = CreateConVar("l4d2_random_glow_item_type", "3", "Glow type.\n0 = OFF, 1 = OnUse (doesn't works), 2 = OnLookAt (doesn't works well for some entities), 3 = Constant (better results but visible through walls).", CVAR_FLAGS, true, 0.0, true, 3.0);
    g_hCvar_GlowFlashing      = CreateConVar("l4d2_random_glow_item_flashing", "0", "Add a flashing effect on glowing entities.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GlowMinDistance   = CreateConVar("l4d2_random_glow_item_min_distance", "0", "Minimum distance that the client must be from the entity to start glowing.\n0 = No minimum distance.", CVAR_FLAGS, true, 0.0);
    g_hCvar_GlowMaxDistance   = CreateConVar("l4d2_random_glow_item_max_distance", "0", "Maximum distance that the client can be away from the entity to start glowing.\n0 = No maximum distance.\n510 = Game default approximate distance.", CVAR_FLAGS, true, 0.0);
    g_hCvar_GlowMinBrightness = CreateConVar("l4d2_random_glow_item_min_brightness", "0.5", "Algorithm value to detect the glow minimum brightness for a random glow (not accurate).", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_ScavengeGascan    = CreateConVar("l4d2_random_glow_item_scavenge_gascan", "0", "Apply glow to scavenge gascans.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Cola              = CreateConVar("l4d2_random_glow_item_cola", "0", "Apply glow to cola.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_MachineGun        = CreateConVar("l4d2_random_glow_item_machine_gun", "1", "Apply glow to Machine Guns (50cal and minigun).\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_RemoveSpawner     = CreateConVar("l4d2_random_glow_item_remove_spawner", "1", "Delete *_spawn entities when its count reaches 0.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlowColor.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlowType.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlowFlashing.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlowMinDistance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlowMaxDistance.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GlowMinBrightness.AddChangeHook(Event_ConVarChanged);
    g_hCvar_ScavengeGascan.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Cola.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MachineGun.AddChangeHook(Event_ConVarChanged);
    g_hCvar_RemoveSpawner.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_entglowinfo", CmdEntGlowInfo, ADMFLAG_ROOT, "Outputs to the chat the glow info about the entity at your crosshair.");
    RegAdminCmd("sm_entglowrefresh", CmdEntGlowRefresh, ADMFLAG_ROOT, "Refresh the glow color of glowing entities.");
    RegAdminCmd("sm_print_cvars_l4d2_random_glow_item", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    g_iModel_Gascan = PrecacheModel(MODEL_GASCAN, true);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    g_bConfigLoaded = true;

    LateLoad();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    LateLoad();

    HookEvents(g_bCvar_Enabled);
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_hCvar_GlowColor.GetString(g_sCvar_GlowColor, sizeof(g_sCvar_GlowColor));
    TrimString(g_sCvar_GlowColor);
    StringToLowerCase(g_sCvar_GlowColor);
    g_bCvar_RandomGlowColor = StrEqual(g_sCvar_GlowColor, "random");
    g_iCvar_GlowColor = ConvertRGBToIntArray(g_sCvar_GlowColor);
    g_iCvar_GlowType = g_hCvar_GlowType.IntValue;
    g_bCvar_GlowFlashing = g_hCvar_GlowFlashing.BoolValue;
    g_iCvar_GlowMinDistance = g_hCvar_GlowMinDistance.IntValue;
    g_iCvar_GlowMaxDistance = g_hCvar_GlowMaxDistance.IntValue;
    g_fCvar_MinBrightness = g_hCvar_GlowMinBrightness.FloatValue;
    g_bCvar_ScavengeGascan = g_hCvar_ScavengeGascan.BoolValue;
    g_bCvar_Cola = g_hCvar_Cola.BoolValue;
    g_bCvar_MachineGun = g_hCvar_MachineGun.BoolValue;
    g_bCvar_RemoveSpawner = g_hCvar_RemoveSpawner.BoolValue;
}

/****************************************************************************************************/

public void HookEvents(bool hook)
{
    if (hook && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("weapon_drop", Event_WeaponDrop);

        return;
    }

    if (!hook && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("weapon_drop", Event_WeaponDrop);

        return;
    }
}

/****************************************************************************************************/

public void LateLoad()
{
    for (int client = 1; client <= MaxClients; client++)
    {
        if (!IsClientInGame(client))
            continue;

        OnClientPutInServer(client);

        int weapon = GetEntPropEnt(client, Prop_Send, "m_hActiveWeapon");
        OnWeaponEquipPost(client, weapon);
    }

    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
    {
        char classname[64];
        GetEntityClassname(entity, classname, sizeof(classname));
        OnEntityCreated(entity, classname);
    }
}

/****************************************************************************************************/

public void OnClientPutInServer(int client)
{
    if (!g_bConfigLoaded)
        return;

    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

/****************************************************************************************************/

public void OnWeaponEquipPost(int client, int weapon)
{
    if (!g_bCvar_Enabled)
        return;

    if (!IsValidEntity(weapon))
        return;

    SetEntProp(weapon, Prop_Send, "m_iGlowType", GLOW_TYPE_NONE);
}

/****************************************************************************************************/

public void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("propid");
    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));
    OnEntityCreated(entity, classname);
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    if (StrContains(classname, "weapon_") == 0)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
        return;
    }

    if (StrContains(classname, "upgrade_") == 0)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
        return;
    }

    if (StrContains(classname, "_projectile") != -1)
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
        return;
    }

    if (StrEqual(classname, "survivor_death_model"))
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
        return;
    }

    if (g_bCvar_MachineGun && HasEntProp(entity, Prop_Send, "m_heat")) // CPropMinigun / CPropMachineGun
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
        return;
    }

    if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
    {
        RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
        return;
    }
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    int modelIndex = GetEntProp(entity, Prop_Send, "m_nModelIndex");

    if (modelIndex == g_iModel_Gascan)
    {
        if (!g_bCvar_ScavengeGascan && IsScavengeGascan(entity))
            return;
    }

    if (HasEntProp(entity, Prop_Send, "m_isCarryable")) // CPhysicsProp
    {
        char modelname[64];
        GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof(modelname));
        StringToLowerCase(modelname);

        bool propvalid;

        if (StrEqual(modelname, MODEL_GASCAN))
            propvalid = true;
        else if (StrEqual(modelname, MODEL_FUEL_BARREL))
            propvalid = true;
        else if (StrEqual(modelname, MODEL_PROPANECANISTER))
            propvalid = true;
        else if (StrEqual(modelname, MODEL_FIREWORKS_CRATE))
            propvalid = true;
        else if (StrEqual(modelname, MODEL_OXYGENTANK))
            propvalid = true;
        else if (StrEqual(modelname, MODEL_BARRICADE_GASCAN))
            propvalid = true;
        else if (StrEqual(modelname, MODEL_GAS_PUMP))
            propvalid = true;
        else if (StrEqual(modelname, MODEL_GNOME))
            propvalid = true;
        else if (g_bCvar_Cola && StrEqual(modelname, MODEL_COLA))
            propvalid = true;

        if (!propvalid)
            return;
    }
    else
    {
        if (HasEntProp(entity, Prop_Send, "m_hOwnerEntity"))
        {
            if (GetEntPropEnt(entity, Prop_Send, "m_hOwnerEntity") != -1)
            {
                SetEntProp(entity, Prop_Send, "m_iGlowType", GLOW_TYPE_NONE);
                return;
            }
        }
    }

    char classname[64];
    GetEntityClassname(entity, classname, sizeof(classname));

    int glowColor[3];

    if (g_bCvar_RandomGlowColor)
    {
        do
        {
            glowColor[0] = GetRandomInt(0,255);
            glowColor[1] = GetRandomInt(0,255);
            glowColor[2] = GetRandomInt(0,255);
        }
        while (GetRGB_Brightness(glowColor) < g_fCvar_MinBrightness);
    }
    else
    {
        glowColor[0] = g_iCvar_GlowColor[0];
        glowColor[1] = g_iCvar_GlowColor[1];
        glowColor[2] = g_iCvar_GlowColor[2];
    }

    if (HasEntProp(entity, Prop_Data, "m_itemCount")) // *_spawn entities
    {
        SDKHook(entity, SDKHook_UsePost, OnUsePost);

        int count = GetEntProp(entity, Prop_Data, "m_itemCount");

        SetEntProp(entity, Prop_Send, "m_iGlowType", count > 0 ? g_iCvar_GlowType : GLOW_TYPE_NONE);
    }
    else
    {
        SetEntProp(entity, Prop_Send, "m_iGlowType", g_iCvar_GlowType);
    }
    SetEntProp(entity, Prop_Send, "m_nGlowRange", g_iCvar_GlowMaxDistance);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", g_iCvar_GlowMinDistance);
    SetEntProp(entity, Prop_Send, "m_bFlashing", g_bCvar_GlowFlashing);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", glowColor[0] + (glowColor[1] * 256) + (glowColor[2] * 65536));
}

/****************************************************************************************************/

public void OnUsePost(int entity, int activator, int caller, UseType type, float value)
{
    if (!g_bCvar_Enabled)
        return;

    if (!g_bCvar_RemoveSpawner)
        return;

    int count = GetEntProp(entity, Prop_Data, "m_itemCount");

    if (count == 0)
        AcceptEntityInput(entity, "Kill");
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdEntGlowInfo(int client, int args)
{
    if (!IsValidClient(client))
        return Plugin_Handled;

    int entity = GetClientAimTarget(client, false);

    if (!IsValidEntity(entity))
    {
        PrintToChat(client, "\x05Invalid target.");
        return Plugin_Handled;
    }

    if (!HasEntProp(entity, Prop_Send, "m_iGlowType"))
    {
        PrintToChat(client, "\x05Target has no glow property.");
        return Plugin_Handled;
    }

    int glowType = GetEntProp(entity, Prop_Send, "m_iGlowType");
    int glowRangeMin = GetEntProp(entity, Prop_Send, "m_nGlowRangeMin");
    int glowRangeMax = GetEntProp(entity, Prop_Send, "m_nGlowRange");
    int glowFlashing = GetEntProp(entity, Prop_Send, "m_bFlashing");

    int glowcolor = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
    int rgb[3];
    rgb[0] = ((glowcolor >> 16) & 0xFF);
    rgb[1] = ((glowcolor >> 8) & 0xFF);
    rgb[2] = ((glowcolor) & 0xFF);

    char classname[64];
    GetEntityClassname(entity, classname, sizeof classname);

    char modelname[64];
    GetEntPropString(entity, Prop_Data, "m_ModelName", modelname, sizeof modelname);

    PrintToChat(client, "\x05Index: \x03%i \x05Classname: \x03%s \x05Model: \x03%s \x05RGB Glow Color: \x03%i %i %i \x05Brightness: \x03%f \x05Type: \x03%i \x05Range(Min|Max): \x03%i|%i \x05Flashing: \x03%i", entity, classname, modelname, rgb[0], rgb[1], rgb[2], GetRGB_Brightness(rgb), glowType, glowRangeMin, glowRangeMax, glowFlashing);

    return Plugin_Handled;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdEntGlowRefresh(int client, int args)
{
    LateLoad();

    return Plugin_Handled;
}

/****************************************************************************************************/

public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d2_random_glow_item) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_random_glow_item_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_random_glow_item_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_random_glow_item_color : \"%s\"", g_sCvar_GlowColor);
    PrintToConsole(client, "l4d2_random_glow_item_type : %i (%s)", g_iCvar_GlowType, g_iCvar_GlowType > 0 ? "true" : "false");
    PrintToConsole(client, "l4d2_random_glow_item_flashing : %b (%s)", g_bCvar_GlowFlashing, g_bCvar_GlowFlashing ? "true" : "false");
    PrintToConsole(client, "l4d2_random_glow_item_min_distance : %i", g_iCvar_GlowMinDistance);
    PrintToConsole(client, "l4d2_random_glow_item_max_distance : %i", g_iCvar_GlowMaxDistance);
    PrintToConsole(client, "l4d2_random_glow_item_min_brightness : %.2f", g_fCvar_MinBrightness);
    PrintToConsole(client, "l4d2_random_glow_item_scavenge_gascan : %b (%s)", g_bCvar_ScavengeGascan, g_bCvar_ScavengeGascan ? "true" : "false");
    PrintToConsole(client, "l4d2_random_glow_item_cola : %b (%s)", g_bCvar_Cola, g_bCvar_Cola ? "true" : "false");
    PrintToConsole(client, "l4d2_random_glow_item_machine_gun : %b (%s)", g_bCvar_MachineGun, g_bCvar_MachineGun ? "true" : "false");
    PrintToConsole(client, "l4d2_random_glow_item_remove_spawner : %b (%s)", g_bCvar_RemoveSpawner, g_bCvar_RemoveSpawner ? "true" : "false");
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

/****************************************************************************************************/

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

/****************************************************************************************************/

/**
 * Returns if is a scavenge gascan based on its skin.
 * Works in L4D2 only.
 *
 * @param entity        Entity index.
 * @return              True if gascan skin is greater than 0 (default).
 */
bool IsScavengeGascan(int entity)
{
    int skin = GetEntProp(entity, Prop_Send, "m_nSkin");

    return skin > 0;
}

/****************************************************************************************************/

/**
 * Converts the string to lower case.
 *
 * @param input         Input string.
 */
void StringToLowerCase(char[] input)
{
    for (int i = 0; i < strlen(input); i++)
    {
        input[i] = CharToLower(input[i]);
    }
}

/****************************************************************************************************/

/**
 * Returns the integer array value of a RGB string.
 * Format: Three values between 0-255 separated by spaces. "<0-255> <0-255> <0-255>"
 * Example: "255 255 255"
 *
 * @param sColor        RGB color string.
 * @return              Integer array (int[3]) value of the RGB string or {0,0,0} if not in specified format.
 */
int[] ConvertRGBToIntArray(char[] sColor)
{
    int color[3];

    if (sColor[0] == 0)
        return color;

    char sColors[3][4];
    int count = ExplodeString(sColor, " ", sColors, sizeof(sColors), sizeof(sColors[]));

    switch (count)
    {
        case 1:
        {
            color[0] = StringToInt(sColors[0]);
        }
        case 2:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
        }
        case 3:
        {
            color[0] = StringToInt(sColors[0]);
            color[1] = StringToInt(sColors[1]);
            color[2] = StringToInt(sColors[2]);
        }
    }

    return color;
}

/****************************************************************************************************/

/**
 * Source: https://stackoverflow.com/a/12216661
 * Returns the RGB brightness of a RGB integer array value.
 *
 * @param rgb           RGB integer array (int[3]).
 * @return              Brightness float value between 0.0 and 1.0.
 */
public float GetRGB_Brightness(int[] rgb)
{
    int r = rgb[0];
    int g = rgb[1];
    int b = rgb[2];

    int cmax = (r > g) ? r : g;
    if (b > cmax) cmax = b;
    return cmax / 255.0;
}