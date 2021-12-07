/**
// ====================================================================================================
Change Log:

1.0.1 (06-March-2021)
    - Fixed "random" as color parameter not working sometimes. (thanks "KadabraZz" for reporting)
    - Added better conversion logic on color string cvar.
    - Added late load after convar change.

1.0.0 (30-November-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1] Colorful Common Infected Clothes"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Adds more colors to the clothes of the common infected"
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328901"

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
#define CONFIG_FILENAME               "l4d1_colorful_common"

// ====================================================================================================
// Defines
// ====================================================================================================
#define CLASSNAME_INFECTED            "infected"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Color;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_RandomColor;

// ====================================================================================================
// int - Plugin Variables
// ====================================================================================================
static int    g_iCvar_Color[3];

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char   g_sCvar_Color[12];

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public APLRes AskPluginLoad2(Handle myself, bool late, char[] error, int err_max)
{
    EngineVersion engine = GetEngineVersion();

    if (engine != Engine_Left4Dead)
    {
        strcopy(error, err_max, "This plugin only runs in \"Left 4 Dead 1\" game");
        return APLRes_SilentFailure;
    }

    return APLRes_Success;
}

/****************************************************************************************************/

public void OnPluginStart()
{
    CreateConVar("l4d1_colorful_common_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("l4d1_colorful_common_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Color   = CreateConVar("l4d1_colorful_common_color", "random", "Common infected clothes color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\"), to apply a specific color.\nExamples:\nl4d1_colorful_common_color \"random\"\nl4d1_colorful_common_color \"255 0 0\"", CVAR_FLAGS);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Color.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_colorful_common_refresh", CmdColorRefresh, ADMFLAG_ROOT, "Refresh the common infected clothes color.");
    RegAdminCmd("sm_print_cvars_l4d1_colorful_common", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
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

    LateLoad();
}

/****************************************************************************************************/

public void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
    g_hCvar_Color.GetString(g_sCvar_Color, sizeof(g_sCvar_Color));
    TrimString(g_sCvar_Color);
    StringToLowerCase(g_sCvar_Color);
    g_bCvar_RandomColor = StrEqual(g_sCvar_Color, "random");
    g_iCvar_Color = ConvertRGBToIntArray(g_sCvar_Color);
}

/****************************************************************************************************/

public void LateLoad()
{
    int entity;

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, CLASSNAME_INFECTED)) != INVALID_ENT_REFERENCE)
    {
       OnSpawnPost(entity);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bConfigLoaded)
        return;

    if (!IsValidEntityIndex(entity))
        return;

    if (classname[0] != 'i')
        return;

    if (StrEqual(classname, CLASSNAME_INFECTED))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnSpawnPost(int entity)
{
    RequestFrame(OnNextFrame, EntIndexToEntRef(entity));
}

/****************************************************************************************************/

public void OnNextFrame(int entityRef)
{
    if (!g_bCvar_Enabled)
        return;

    int entity = EntRefToEntIndex(entityRef);

    if (entity == INVALID_ENT_REFERENCE)
        return;

    if (g_bCvar_RandomColor)
        SetEntityRenderColor(entity, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
    else
        SetEntityRenderColor(entity, g_iCvar_Color[0], g_iCvar_Color[1], g_iCvar_Color[2], 200);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdColorRefresh(int client, int args)
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
    PrintToConsole(client, "---------------- Plugin Cvars (l4d1_colorful_common) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d1_colorful_common_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d1_colorful_common_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "l4d1_colorful_common_color : \"%s\"", g_sCvar_Color);
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