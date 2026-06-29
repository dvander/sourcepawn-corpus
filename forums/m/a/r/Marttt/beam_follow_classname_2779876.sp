/**
// ====================================================================================================
Change Log:

1.0.0 (09-May-2022)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[ANY] Beam/Trail Follow by Classname"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Creates a beam that follow entities by classname"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=337859"

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
#define CONFIG_FILENAME               "beam_follow_classname"
#define DATA_FILENAME                 "beam_follow_classname"

// ====================================================================================================
// Defines
// ====================================================================================================
#define NO_HALO                       0

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bConfigsExecuted;
bool g_bCvar_Enabled;

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alBeamFollowing;

// ====================================================================================================
// StringMap - Plugin Variables
// ====================================================================================================
StringMap g_smClassnameConfig;

// ====================================================================================================
// enum structs
// ====================================================================================================
enum struct BeamSetup
{
    bool enable;
    char model[PLATFORM_MAX_PATH];
    int modelIndex;
    float lifeDuration;
    float widthStart;
    float widthEnd;
    int fadeDuration;
    bool randomColor;
    char color[12];
    int colorRGB[3];
    bool randomAlpha;
    int alpha;
}

// ====================================================================================================
// enum struct - Plugin Variables
// ====================================================================================================
BeamSetup defaultConfig;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public void OnPluginStart()
{
    g_alBeamFollowing = new ArrayList();
    g_smClassnameConfig = new StringMap();

    CreateConVar("beam_follow_classname_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("beam_follow_classname_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_beam_follow_config_reload", CmdReload, ADMFLAG_ROOT, "Reload the beam follow configs.");
    RegAdminCmd("sm_print_cvars_beam_follow_classname", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
    LoadConfigs(); // Refresh model index

    // Fix for when OnConfigsExecuted is not executed by SM in some games
    RequestFrame(OnConfigsExecuted);
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    if (g_bConfigsExecuted)
        return;

    g_bConfigsExecuted = true;

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

void LoadConfigs()
{
    g_smClassnameConfig.Clear();

    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), "data/%s.cfg", DATA_FILENAME);

    if (!FileExists(path))
    {
        SetFailState("Missing required data file on \"data/%s.cfg\", please re-download.", DATA_FILENAME);
        return;
    }

    KeyValues kv = new KeyValues(DATA_FILENAME);
    kv.ImportFromFile(path);

    if (kv.JumpToKey("default"))
    {
        defaultConfig.enable = (kv.GetNum("enable", 0) == 1);
        kv.GetString("model", defaultConfig.model, sizeof(defaultConfig.model), "");
        if (defaultConfig.model[0] != 0)
            defaultConfig.modelIndex = PrecacheModel(defaultConfig.model, true);
        defaultConfig.lifeDuration = kv.GetFloat("lifeDuration", 0.0);
        defaultConfig.widthStart = kv.GetFloat("widthStart", 0.0);
        defaultConfig.widthEnd = kv.GetFloat("widthEnd", 0.0);
        defaultConfig.fadeDuration = kv.GetNum("fadeDuration", 0);
        defaultConfig.randomColor = (kv.GetNum("randomColor", 0) == 1);
        kv.GetString("color", defaultConfig.color, sizeof(defaultConfig.color), "");
        defaultConfig.colorRGB = ConvertRGBToIntArray(defaultConfig.color);
        defaultConfig.randomAlpha = (kv.GetNum("randomAlpha", 0) == 1);
        defaultConfig.alpha = kv.GetNum("alpha", 0);
    }

    kv.Rewind();

    char section[64];
    bool enable;

    if (kv.JumpToKey("classnames"))
    {
        if (kv.GotoFirstSubKey())
        {
            do
            {
                enable = (kv.GetNum("enable", defaultConfig.enable) == 1);
                if (!enable)
                    continue;

                BeamSetup config;
                config.enable = enable;
                kv.GetString("model", config.model, sizeof(config.model), defaultConfig.model);
                if (config.model[0] != 0)
                    config.modelIndex = PrecacheModel(config.model, true);
                config.lifeDuration = kv.GetFloat("lifeDuration", defaultConfig.lifeDuration);
                config.widthStart = kv.GetFloat("widthStart", defaultConfig.widthStart);
                config.widthEnd = kv.GetFloat("widthEnd", defaultConfig.widthEnd);
                config.fadeDuration = kv.GetNum("fadeDuration", defaultConfig.fadeDuration);
                config.randomColor = (kv.GetNum("randomColor", defaultConfig.randomColor) == 1);
                kv.GetString("color", config.color, sizeof(config.color), defaultConfig.color);
                config.colorRGB = ConvertRGBToIntArray(config.color);
                config.randomAlpha = (kv.GetNum("randomAlpha", defaultConfig.randomAlpha) == 1);
                config.alpha = kv.GetNum("alpha", defaultConfig.alpha);

                kv.GetSectionName(section, sizeof(section));
                TrimString(section);
                StringToLowerCase(section);

                g_smClassnameConfig.SetArray(section, config, sizeof(config));
            } while (kv.GotoNextKey());
        }
    }

    kv.Rewind();

    delete kv;
}

/****************************************************************************************************/

void LateLoad()
{
    int entity;
    char classname[64];

    entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "*")) != INVALID_ENT_REFERENCE)
    {
        if (entity < 0)
            continue;

        GetEntityClassname(entity, classname, sizeof(classname));
        OnEntityCreated(entity, classname);
    }
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!g_bCvar_Enabled)
        return;

    if (entity < 0)
        return;

    CreateBeamFollow(entity, classname);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    int find = g_alBeamFollowing.FindValue(entity);

    if (find != -1)
        g_alBeamFollowing.Erase(find);
}

/****************************************************************************************************/

void CreateBeamFollow(int entity, const char[] classname)
{
    int find = g_alBeamFollowing.FindValue(entity);

    if (find != -1)
        return;

    BeamSetup config;
    g_smClassnameConfig.GetArray(classname, config, sizeof(config));

    if (!config.enable)
        return;

    int color[4];

    if (config.randomColor)
    {
        color[0] = GetRandomInt(0, 255);
        color[1] = GetRandomInt(0, 255);
        color[2] = GetRandomInt(0, 255);
    }
    else
    {
        color = config.colorRGB;
    }

    if (config.randomAlpha)
    {
        color[3] = GetRandomInt(0, 255);
    }
    else
    {
        color[3] = config.alpha;
    }

    g_alBeamFollowing.Push(entity);
    TE_SetupBeamFollow(entity, config.modelIndex, NO_HALO, config.lifeDuration, config.widthStart, config.widthEnd, config.fadeDuration, color);
    TE_SendToAll();
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdReload(int client, int args)
{
    LoadConfigs();

    LateLoad();

    if (IsValidClient(client))
        PrintToChat(client, "\x04[\x05Beam follow configs \x03reloaded\x04]");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (beam_follow_classname) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "beam_follow_classname_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "beam_follow_classname_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------------------- Array List -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "g_alBeamFollowing count : %i", g_alBeamFollowing.Length);
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