/**
// ====================================================================================================
Change Log:

1.0.1 (09-February-2025)
    - Compatibility update for SM 1.12.

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
#define PLUGIN_VERSION                "1.0.1"
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
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct PluginCvars
{
    ConVar beam_follow_classname_version;
    ConVar beam_follow_classname_enable;

    void Init()
    {
        this.beam_follow_classname_version = CreateConVar("beam_follow_classname_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.beam_follow_classname_enable  = CreateConVar("beam_follow_classname_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.beam_follow_classname_enable.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

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

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;
    BeamSetup defaultConfig;

    ArrayList alBeamFollowing;
    StringMap smClassnameConfig;

    bool configsExecuted;
    bool enable;

    void Init()
    {
        this.cvars.Init();
        this.alBeamFollowing = new ArrayList();
        this.smClassnameConfig = new StringMap();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.beam_follow_classname_enable.BoolValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_beam_follow_config_reload", Cmd_Reload, ADMFLAG_ROOT, "Reload the beam follow configs.");
        RegAdminCmd("sm_print_cvars_beam_follow_classname", Cmd_PrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }

    void LoadConfigs()
    {
        this.smClassnameConfig.Clear();

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
            this.defaultConfig.enable = (kv.GetNum("enable", 0) == 1);
            kv.GetString("model", this.defaultConfig.model, sizeof(BeamSetup::model), "");
            if (this.defaultConfig.model[0] != 0)
                this.defaultConfig.modelIndex = PrecacheModel(this.defaultConfig.model, true);
            this.defaultConfig.lifeDuration = kv.GetFloat("lifeDuration", 0.0);
            this.defaultConfig.widthStart = kv.GetFloat("widthStart", 0.0);
            this.defaultConfig.widthEnd = kv.GetFloat("widthEnd", 0.0);
            this.defaultConfig.fadeDuration = kv.GetNum("fadeDuration", 0);
            this.defaultConfig.randomColor = (kv.GetNum("randomColor", 0) == 1);
            kv.GetString("color", this.defaultConfig.color, sizeof(BeamSetup::color), "");
            this.defaultConfig.colorRGB = ConvertRGBToIntArray(this.defaultConfig.color);
            this.defaultConfig.randomAlpha = (kv.GetNum("randomAlpha", 0) == 1);
            this.defaultConfig.alpha = kv.GetNum("alpha", 0);
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
                    enable = (kv.GetNum("enable", this.defaultConfig.enable) == 1);
                    if (!enable)
                        continue;

                    BeamSetup config;
                    config.enable = enable;
                    kv.GetString("model", config.model, sizeof(config.model), this.defaultConfig.model);
                    if (config.model[0] != 0)
                        config.modelIndex = PrecacheModel(config.model, true);
                    config.lifeDuration = kv.GetFloat("lifeDuration", this.defaultConfig.lifeDuration);
                    config.widthStart = kv.GetFloat("widthStart", this.defaultConfig.widthStart);
                    config.widthEnd = kv.GetFloat("widthEnd", this.defaultConfig.widthEnd);
                    config.fadeDuration = kv.GetNum("fadeDuration", this.defaultConfig.fadeDuration);
                    config.randomColor = (kv.GetNum("randomColor", this.defaultConfig.randomColor) == 1);
                    kv.GetString("color", config.color, sizeof(config.color), this.defaultConfig.color);
                    config.colorRGB = ConvertRGBToIntArray(config.color);
                    config.randomAlpha = (kv.GetNum("randomAlpha", this.defaultConfig.randomAlpha) == 1);
                    config.alpha = kv.GetNum("alpha", this.defaultConfig.alpha);

                    kv.GetSectionName(section, sizeof(section));
                    TrimString(section);
                    StringToLowerCase(section);

                    this.smClassnameConfig.SetArray(section, config, sizeof(config));
                } while (kv.GotoNextKey());
            }
        }

        kv.Rewind();

        delete kv;
    }

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

    void CreateBeamFollow(int entity, const char[] classname)
    {
        int find = this.alBeamFollowing.FindValue(entity);

        if (find != -1)
            return;

        BeamSetup config;
        this.smClassnameConfig.GetArray(classname, config, sizeof(config));

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
            color[0] = config.colorRGB[0];
            color[1] = config.colorRGB[1];
            color[2] = config.colorRGB[2];
        }

        if (config.randomAlpha)
        {
            color[3] = GetRandomInt(0, 255);
        }
        else
        {
            color[3] = config.alpha;
        }

        this.alBeamFollowing.Push(entity);
        TE_SetupBeamFollow(entity, config.modelIndex, NO_HALO, config.lifeDuration, config.widthStart, config.widthEnd, config.fadeDuration, color);
        TE_SendToAll();
    }
}

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public void OnPluginStart()
{
    plugin.Init();
}

/****************************************************************************************************/

public void OnMapStart()
{
    plugin.LoadConfigs(); // Refresh model index

    // Fix for when OnConfigsExecuted is not executed by SM in some games
    RequestFrame(OnConfigsExecuted);
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    OnConfigsExecuted();
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    if (plugin.configsExecuted)
        return;

    plugin.configsExecuted = true;
    plugin.GetCvarValues();
    plugin.LateLoad();
}

/****************************************************************************************************/

public void OnEntityCreated(int entity, const char[] classname)
{
    if (!plugin.enable)
        return;

    if (entity < 0)
        return;

    plugin.CreateBeamFollow(entity, classname);
}

/****************************************************************************************************/

public void OnEntityDestroyed(int entity)
{
    if (entity < 0)
        return;

    int find = plugin.alBeamFollowing.FindValue(entity);

    if (find != -1)
        plugin.alBeamFollowing.Erase(find);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action Cmd_Reload(int client, int args)
{
    plugin.LoadConfigs();
    plugin.LateLoad();

    if (IsValidClient(client))
        PrintToChat(client, "\x04[\x05Beam follow configs \x03reloaded\x04]");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action Cmd_PrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (beam_follow_classname) ---------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "beam_follow_classname_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "beam_follow_classname_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------------------- Array List -----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "plugin.alBeamFollowing count : %i", plugin.alBeamFollowing.Length);
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