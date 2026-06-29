/**
// ====================================================================================================
Change Log:

1.0.0 (26-Decemeber-2021)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D2] Weapon Equip Glow"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Adds glow to equip items"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=335704"

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
#define CONFIG_FILENAME               "l4d2_weapon_equip_glow"
#define DATA_FILENAME                 "l4d2_weapon_equip_glow"

// ====================================================================================================
// Defines
// ====================================================================================================
#define FLAG_GASCAN_NORMAL            (1 << 0) // 1 | 01
#define FLAG_GASCAN_SCAVENGE          (1 << 1) // 2 | 10

#define CONFIG_ENABLE                 0
#define CONFIG_RANDOM                 1
#define CONFIG_R                      2
#define CONFIG_G                      3
#define CONFIG_B                      4
#define CONFIG_FLASHING               5
#define CONFIG_TYPE                   6
#define CONFIG_RANGEMIN               7
#define CONFIG_RANGEMAX               8
#define CONFIG_ARRAYSIZE              9

#define ENTITYGLOW_SET                0
#define ENTITYGLOW_TYPE               1
#define ENTITYGLOW_COLOROVERRIDE      2
#define ENTITYGLOW_FLASHING           3
#define ENTITYGLOW_RANGEMIN           4
#define ENTITYGLOW_RANGEMAX           5
#define ENTITYGLOW_ARRAYSIZE          6

#define MAXENTITIES                   2048

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;
ConVar g_hCvar_MinBrightness;
ConVar g_hCvar_GascanType;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bEventsHooked;
bool g_bCvar_Enabled;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
int g_iCvar_GascanType;

// ====================================================================================================
// float - Plugin Variables
// ====================================================================================================
float g_fCvar_MinBrightness;

// ====================================================================================================
// client - Plugin Variables
// ====================================================================================================
bool gc_bWeaponEquipHooked[MAXPLAYERS+1];

// ====================================================================================================
// entity - Plugin Variables
// ====================================================================================================
int ge_iConfig[MAXENTITIES+1][ENTITYGLOW_ARRAYSIZE];

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
StringMap g_smClassnameConfig;
StringMap g_smMeleeConfig;

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
    g_smClassnameConfig = new StringMap();
    g_smMeleeConfig = new StringMap();

    CreateConVar("l4d2_weapon_equip_glow_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled       = CreateConVar("l4d2_weapon_equip_glow_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_MinBrightness = CreateConVar("l4d2_weapon_equip_glow_min_brightness", "0.5", "Algorithm value to detect the glow minimum brightness for a random color (not accurate).", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_GascanType    = CreateConVar("l4d2_weapon_equip_glow_gascan_type", "3", "Which types of gascan should be affected by the plugin.\n0 = NONE, 1 = NORMAL, 2 = SCAVENGE, 3 = BOTH.\nAdd numbers greater than 0 for multiple options.\nExample: \"3\", enables for NORMAL and SCAVENGE gascans.", CVAR_FLAGS, true, 0.0, true, 3.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MinBrightness.AddChangeHook(Event_ConVarChanged);
    g_hCvar_GascanType.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_glowequipreload", CmdReload, ADMFLAG_ROOT, "Reload the glow equip configs.");
    RegAdminCmd("sm_print_cvars_l4d2_weapon_equip_glow", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_fCvar_MinBrightness = g_hCvar_MinBrightness.FloatValue;
    g_iCvar_GascanType = g_hCvar_GascanType.IntValue;
}

/****************************************************************************************************/

void LoadConfigs()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/%s.cfg", DATA_FILENAME);

    if (!FileExists(path))
    {
        SetFailState("Missing required data file on \"data/%s.cfg\", please re-download.", DATA_FILENAME);
        return;
    }

    KeyValues kv = new KeyValues(DATA_FILENAME);
    kv.ImportFromFile(path);

    g_smClassnameConfig.Clear();
    g_smMeleeConfig.Clear();

    int default_enable;
    int default_random;
    char default_color[16];
    int default_flashing;
    int default_type;
    int default_rangemin;
    int default_rangemax;

    int iColor[3];

    if (kv.JumpToKey("default"))
    {
        default_enable = kv.GetNum("enable", 0);
        default_random = kv.GetNum("random", 0);
        kv.GetString("color", default_color, sizeof(default_color), "255 255 255");
        default_flashing = kv.GetNum("flashing", 0);
        default_type = kv.GetNum("type", 0);
        default_rangemin = kv.GetNum("rangemin", 0);
        default_rangemax = kv.GetNum("rangemax", 0);
    }

    kv.Rewind();

    char section[64];
    int enable;
    int random;
    char color[16];
    int flashing;
    int type;
    int rangemin;
    int rangemax;

    int config[CONFIG_ARRAYSIZE];

    if (kv.JumpToKey("classnames"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                enable = kv.GetNum("enable", default_enable);
                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);
                flashing = kv.GetNum("flashing", default_flashing);
                type = kv.GetNum("type", default_type);
                rangemin = kv.GetNum("rangemin", default_rangemin);
                rangemax = kv.GetNum("rangemax", default_rangemax);

                iColor = ConvertRGBToIntArray(color);

                if (enable == 0)
                    continue;

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];
                config[CONFIG_FLASHING] = flashing;
                config[CONFIG_TYPE] = type;
                config[CONFIG_RANGEMIN] = rangemin;
                config[CONFIG_RANGEMAX] = rangemax;

                g_smClassnameConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    if (kv.JumpToKey("melees"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                enable = kv.GetNum("enable", default_enable);
                random = kv.GetNum("random", default_random);
                kv.GetString("color", color, sizeof(color), default_color);
                flashing = kv.GetNum("flashing", default_flashing);
                type = kv.GetNum("type", default_type);
                rangemin = kv.GetNum("rangemin", default_rangemin);
                rangemax = kv.GetNum("rangemax", default_rangemax);

                iColor = ConvertRGBToIntArray(color);

                if (enable == 0)
                    continue;

                config[CONFIG_ENABLE] = enable;
                config[CONFIG_RANDOM] = random;
                config[CONFIG_R] = iColor[0];
                config[CONFIG_G] = iColor[1];
                config[CONFIG_B] = iColor[2];
                config[CONFIG_FLASHING] = flashing;
                config[CONFIG_TYPE] = type;
                config[CONFIG_RANGEMIN] = rangemin;
                config[CONFIG_RANGEMAX] = rangemax;

                g_smMeleeConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    delete kv;
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();

    HookEvents();

    LateLoad();
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();

    HookEvents();
}

/****************************************************************************************************/

void LateLoad()
{
    LoadConfigs();

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
    if (gc_bWeaponEquipHooked[client])
        return;

    gc_bWeaponEquipHooked[client] = true;
    SDKHook(client, SDKHook_WeaponEquip, OnWeaponEquip);
    SDKHook(client, SDKHook_WeaponEquipPost, OnWeaponEquipPost);
}

/****************************************************************************************************/

public void OnClientDisconnect(int client)
{
    gc_bWeaponEquipHooked[client] = false;
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    ge_iConfig[entity][ENTITYGLOW_SET] = 0;
    ge_iConfig[entity][ENTITYGLOW_TYPE] = 0;
    ge_iConfig[entity][ENTITYGLOW_COLOROVERRIDE] = 0;
    ge_iConfig[entity][ENTITYGLOW_FLASHING] = 0;
    ge_iConfig[entity][ENTITYGLOW_RANGEMIN] = 0;
    ge_iConfig[entity][ENTITYGLOW_RANGEMAX] = 0;
}

/****************************************************************************************************/

void HookEvents()
{
    if (g_bCvar_Enabled && !g_bEventsHooked)
    {
        g_bEventsHooked = true;

        HookEvent("weapon_drop", Event_WeaponDrop);

        return;
    }

    if (!g_bCvar_Enabled && g_bEventsHooked)
    {
        g_bEventsHooked = false;

        UnhookEvent("weapon_drop", Event_WeaponDrop);

        return;
    }
}

/****************************************************************************************************/

Action OnWeaponEquip(int client, int weapon)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (!IsValidEntity(weapon))
        return Plugin_Continue;

    if (ge_iConfig[weapon][ENTITYGLOW_SET] == 1) // "take a break" bug fix
        return Plugin_Continue;

    int entity = weapon;

    ge_iConfig[entity][ENTITYGLOW_TYPE] = GetEntProp(entity, Prop_Send, "m_iGlowType");
    ge_iConfig[entity][ENTITYGLOW_COLOROVERRIDE] = GetEntProp(entity, Prop_Send, "m_glowColorOverride");
    ge_iConfig[entity][ENTITYGLOW_FLASHING] = GetEntProp(entity, Prop_Send, "m_bFlashing");
    ge_iConfig[entity][ENTITYGLOW_RANGEMIN] = GetEntProp(entity, Prop_Send, "m_nGlowRangeMin");
    ge_iConfig[entity][ENTITYGLOW_RANGEMAX] = GetEntProp(entity, Prop_Send, "m_nGlowRange");

    return Plugin_Continue;
}

/****************************************************************************************************/

void OnWeaponEquipPost(int client, int weapon)
{
    if (!g_bCvar_Enabled)
        return;

    if (!IsValidEntity(weapon))
        return;

    int entity = weapon;

    char classname[36];
    int config[CONFIG_ARRAYSIZE];

    GetEntityClassname(entity, classname, sizeof(classname));
    g_smClassnameConfig.GetArray(classname, config, sizeof(config));

    if (StrEqual(classname, "weapon_melee"))
    {
        if (config[CONFIG_ENABLE] == 0)
            return;

        int configEmpty[CONFIG_ARRAYSIZE];
        config = configEmpty;

        char melee[16];
        GetEntPropString(entity, Prop_Data, "m_strMapSetScriptName", melee, sizeof(melee));
        g_smMeleeConfig.GetArray(melee, config, sizeof(config));
    }

    if (StrEqual(classname, "weapon_gascan"))
    {
        if (IsScavengeGascan(entity))
        {
            if (!(g_iCvar_GascanType & FLAG_GASCAN_SCAVENGE))
                return;
        }
        else
        {
            if (!(g_iCvar_GascanType & FLAG_GASCAN_NORMAL))
                return;
        }
    }

    if (config[CONFIG_ENABLE] == 0)
        return;

    if (config[CONFIG_RANDOM] == 1)
    {
        int colorRandom[3];
        do
        {
            colorRandom[0] = GetRandomInt(0, 255);
            colorRandom[1] = GetRandomInt(0, 255);
            colorRandom[2] = GetRandomInt(0, 255);
        }
        while (GetRGB_Brightness(colorRandom) < g_fCvar_MinBrightness);

        config[CONFIG_R] = colorRandom[0];
        config[CONFIG_G] = colorRandom[1];
        config[CONFIG_B] = colorRandom[2];
    }

    if (ge_iConfig[entity][ENTITYGLOW_COLOROVERRIDE] != GetEntProp(entity, Prop_Send, "m_glowColorOverride"))
        ge_iConfig[entity][ENTITYGLOW_COLOROVERRIDE] = GetEntProp(entity, Prop_Send, "m_glowColorOverride");

    ge_iConfig[entity][ENTITYGLOW_SET] = 1;
    SetEntProp(entity, Prop_Send, "m_iGlowType", config[CONFIG_TYPE]);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", config[CONFIG_R] + (config[CONFIG_G] * 256) + (config[CONFIG_B] * 65536));
    SetEntProp(entity, Prop_Send, "m_bFlashing", config[CONFIG_FLASHING]);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", config[CONFIG_RANGEMIN]);
    SetEntProp(entity, Prop_Send, "m_nGlowRange", config[CONFIG_RANGEMAX]);
}

/****************************************************************************************************/

void Event_WeaponDrop(Event event, const char[] name, bool dontBroadcast)
{
    int entity = event.GetInt("propid");

    if (ge_iConfig[entity][ENTITYGLOW_SET] == 0)
        return;

    SetEntProp(entity, Prop_Send, "m_iGlowType", ge_iConfig[entity][ENTITYGLOW_TYPE]);
    SetEntProp(entity, Prop_Send, "m_glowColorOverride", ge_iConfig[entity][ENTITYGLOW_COLOROVERRIDE]);
    SetEntProp(entity, Prop_Send, "m_bFlashing", ge_iConfig[entity][ENTITYGLOW_FLASHING]);
    SetEntProp(entity, Prop_Send, "m_nGlowRangeMin", ge_iConfig[entity][ENTITYGLOW_RANGEMIN]);
    SetEntProp(entity, Prop_Send, "m_nGlowRange", ge_iConfig[entity][ENTITYGLOW_RANGEMAX]);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdReload(int client, int args)
{
    LateLoad();

    if (IsValidClient(client))
        PrintToChat(client, "\x04Glow equip configs reloaded.");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (l4d2_weapon_equip_glow) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d2_weapon_equip_glow_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d2_weapon_equip_glow_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d2_weapon_equip_glow_min_brightness : %.1f", g_fCvar_MinBrightness);
    PrintToConsole(client, "l4d2_weapon_equip_glow_gascan_type : %i (NORMAL = %s | SCAVENGE = %s)", g_iCvar_GascanType, g_iCvar_GascanType & FLAG_GASCAN_NORMAL ? "true" : "false", g_iCvar_GascanType & FLAG_GASCAN_SCAVENGE ? "true" : "false");
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
float GetRGB_Brightness(int[] rgb)
{
    int r = rgb[0];
    int g = rgb[1];
    int b = rgb[2];

    int cmax = (r > g) ? r : g;
    if (b > cmax) cmax = b;
    return cmax / 255.0;
}