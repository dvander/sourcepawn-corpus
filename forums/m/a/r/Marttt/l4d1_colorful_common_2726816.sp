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
#define MAXENTITIES                   2048

#define ORIGINAL_COLOR                -2 // -2 cause some entities has "m_clrRender" = -1

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar l4d1_colorful_common_version;
    ConVar l4d1_colorful_common_enable;
    ConVar l4d1_colorful_common_color;

    void Init()
    {
        this.l4d1_colorful_common_version = CreateConVar("l4d1_colorful_common_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d1_colorful_common_enable  = CreateConVar("l4d1_colorful_common_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
        this.l4d1_colorful_common_color   = CreateConVar("l4d1_colorful_common_color", "random", "Common infected clothes color.\nUse \"random\" for random colors.\nUse three values between 0-255 separated by spaces (\"<0-255> <0-255> <0-255>\"), to apply a specific color.\nExamples:\nl4d1_colorful_common_color \"random\"\nl4d1_colorful_common_color \"255 0 0\"", CVAR_FLAGS);

        this.l4d1_colorful_common_enable.AddChangeHook(Event_ConVarChanged);
        this.l4d1_colorful_common_color.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool enabled;
    bool randomColor;
    int iColor[3];
    char sColor[12];

    int rendercolor[MAXENTITIES+1];

    void Init()
    {
        for (int entity = 0; entity < sizeof(this.rendercolor); entity++)
            this.rendercolor[entity] = ORIGINAL_COLOR;

        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enabled = this.cvars.l4d1_colorful_common_enable.BoolValue;
        this.cvars.l4d1_colorful_common_color.GetString(this.sColor, sizeof(this.sColor));
        TrimString(this.sColor);
        this.randomColor = StrEqual(this.sColor, "random", false);
        this.iColor = ConvertRGBToIntArray(this.sColor);
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_colorful_common_refresh", CmdColorRefresh, ADMFLAG_ROOT, "Refresh the common infected clothes color.");
        RegAdminCmd("sm_print_cvars_l4d1_colorful_common", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }

    void LateLoad()
    {
        int entity = INVALID_ENT_REFERENCE;
        while ((entity = FindEntityByClassname(entity, "infected")) != INVALID_ENT_REFERENCE)
        {
            if (this.enabled)
                SetCommonColor(entity);
            else
                ResetCommonColor(entity);
        }
    }
}

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
    plugin.Init();
}

/****************************************************************************************************/

public void OnPluginEnd()
{
    plugin.enabled = false;
    plugin.LateLoad();
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
    plugin.LateLoad();
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!plugin.enabled)
        return;

    if (entity < 0)
        return;

    if (StrEqual(classname, "infected"))
        SDKHook(entity, SDKHook_SpawnPost, OnSpawnPost);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    plugin.rendercolor[entity] = ORIGINAL_COLOR;
}

/****************************************************************************************************/

void OnSpawnPost(int entity)
{
    SetCommonColor(entity);
}

/****************************************************************************************************/

void SetCommonColor(int entity)
{
    if (plugin.rendercolor[entity] == ORIGINAL_COLOR)
        plugin.rendercolor[entity] = GetEntProp(entity, Prop_Send, "m_clrRender");

    if (plugin.randomColor)
        SetEntityRenderColor(entity, GetRandomInt(0, 255), GetRandomInt(0, 255), GetRandomInt(0, 255), 255);
    else
        SetEntityRenderColor(entity, plugin.iColor[0], plugin.iColor[1], plugin.iColor[2], 255);
}

/****************************************************************************************************/

void ResetCommonColor(int entity)
{
    if (plugin.rendercolor[entity] == ORIGINAL_COLOR)
        return;

    SetEntProp(entity, Prop_Send, "m_clrRender", plugin.rendercolor[entity]);
    plugin.rendercolor[entity] = ORIGINAL_COLOR;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdColorRefresh(int client, int args)
{
    plugin.LateLoad();

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------- Plugin Cvars (l4d1_colorful_common) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d1_colorful_common_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d1_colorful_common_enable : %b (%s)", plugin.enabled, plugin.enabled ? "true" : "false");
    PrintToConsole(client, "l4d1_colorful_common_color : \"%s\"", plugin.sColor);
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
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