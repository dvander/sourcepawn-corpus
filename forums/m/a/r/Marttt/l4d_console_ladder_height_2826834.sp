/**
// ====================================================================================================
Change Log:

1.0.3 (30-May-2026)
    - Added sort by origin after height to make it easier to find duplicated ladders.

1.0.2 (09-February-2025)
    - Added origin column info. (thanks "HarryPotter" for sharing)

1.0.1 (16-August-2024)
    - Added model column info.

1.0.0 (15-August-2024)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[L4D1 & L4D2] Ladder List Height Info"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Output a table to the console with the current map original ladders list with their respective heights"
#define PLUGIN_VERSION                "1.0.3"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=348968"

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
#define CONFIG_FILENAME               "l4d_console_ladder_height"

// ====================================================================================================
// enum structs - Plugin Variables
// ====================================================================================================
PluginData plugin;

// ====================================================================================================
// enums / enum structs
// ====================================================================================================
enum struct LadderInfo
{
    int entity;
    int hammerid;
    char model[PLATFORM_MAX_PATH];
    float height;
    float mins[3];
    float maxs[3];
    float sizes[3];
    float origin[3];
}

/****************************************************************************************************/

enum struct PluginCvars
{
    ConVar l4d_console_ladder_height_version;
    ConVar l4d_console_ladder_height_enable;

    void Init()
    {
        this.l4d_console_ladder_height_version = CreateConVar("l4d_console_ladder_height_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
        this.l4d_console_ladder_height_enable  = CreateConVar("l4d_console_ladder_height_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

        this.l4d_console_ladder_height_enable.AddChangeHook(Event_ConVarChanged);

        AutoExecConfig(true, CONFIG_FILENAME);
    }
}

/****************************************************************************************************/

enum struct PluginData
{
    PluginCvars cvars;

    bool enable;

    void Init()
    {
        this.cvars.Init();
        this.RegisterCmds();
    }

    void GetCvarValues()
    {
        this.enable = this.cvars.l4d_console_ladder_height_enable.BoolValue;
    }

    void RegisterCmds()
    {
        RegAdminCmd("sm_ladderlist", CmdLadderList, ADMFLAG_ROOT, "Output a table to the console with the current map original ladders list with their respective heights.");
        RegAdminCmd("sm_print_cvars_l4d_console_ladder_height", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
    }
}

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
}

/****************************************************************************************************/

public int SortAscByHeight(int index1, int index2, Handle array, Handle hndl)
{
    ArrayList list = view_as<ArrayList>(array);
    LadderInfo ladder1;
    LadderInfo ladder2;
    list.GetArray(index1, ladder1, sizeof(ladder1));
    list.GetArray(index2, ladder2, sizeof(ladder2));

    // First sort by height
    if (ladder1.height < ladder2.height)
        return -1;

    if (ladder1.height > ladder2.height)
        return 1;

    // Then sort by origin (x)
    if (ladder1.origin[0] < ladder2.origin[0])
        return -1;

    if (ladder1.origin[0] > ladder2.origin[0])
        return 1;

    // Then sort by origin (y)
    if (ladder1.origin[1] < ladder2.origin[1])
        return -1;

    if (ladder1.origin[1] > ladder2.origin[1])
        return 1;

    // Then sort by origin (z)
    if (ladder1.origin[2] < ladder2.origin[2])
        return -1;

    if (ladder1.origin[2] > ladder2.origin[2])
        return 1;

    // Then sort by entity
    if (ladder1.entity < ladder2.entity)
        return -1;

    if (ladder1.entity > ladder2.entity)
        return 1;

    return 0;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdLadderList(int client, int args)
{
    if (!plugin.enable)
    {
        PrintToConsole(client, "Plugin disabled");
        return Plugin_Handled;
    }

    char HEADER_ENTITY[] = "entity";
    char HEADER_HAMMERID[] = "hammerid";
    char HEADER_MODEL[] = "model";
    char HEADER_HEIGHT[] = "height";
    char HEADER_MINS[] = "mins (x y z)";
    char HEADER_MAXS[] = "maxs (x y z)";
    char HEADER_SIZES[] = "sizes (x y z)";
    char HEADER_ORIGIN[] = "origin (x y z)";

    int entityStrLenMax = strlen(HEADER_ENTITY);
    int hammeridStrLenMax = strlen(HEADER_HAMMERID);
    int modelStrLenMax = strlen(HEADER_MODEL);
    int heightStrLenMax = strlen(HEADER_HEIGHT);
    int minsStrLenMax[3] = { 3, 3, 3 }; // { "0.0", "0.0", "0.0" } (%0.1f)
    int maxsStrLenMax[3] = { 3, 3, 3 }; // { "0.0", "0.0", "0.0" } (%0.1f)
    int sizesStrLenMax[3] = { 3, 3, 3 }; // { "0.0", "0.0", "0.0" } (%0.1f)
    int originStrLenMax[3] = { 3, 3, 3 }; // { "0.0", "0.0", "0.0" } (%0.1f)

    ArrayList ladders = new ArrayList(sizeof(LadderInfo));
    int entity = INVALID_ENT_REFERENCE;
    while ((entity = FindEntityByClassname(entity, "func_simpleladder")) != INVALID_ENT_REFERENCE)
    {
        int hammerid = GetEntProp(entity, Prop_Data, "m_iHammerID");
        if (hammerid == 0)
            continue;

        LadderInfo ladder;
        ladder.entity = entity;
        ladder.hammerid = hammerid;
        GetEntPropString(entity, Prop_Data, "m_ModelName", ladder.model, sizeof(ladder.model));
        GetEntPropVector(entity, Prop_Send, "m_vecMins", ladder.mins);
        GetEntPropVector(entity, Prop_Send, "m_vecMaxs", ladder.maxs);
        SubtractVectors(ladder.maxs, ladder.mins, ladder.sizes);
        ladder.height = ladder.sizes[2];
        ladder.origin[0] = (ladder.mins[0] + ladder.maxs[0]) * 0.5;
        ladder.origin[1] = (ladder.mins[1] + ladder.maxs[1]) * 0.5;
        ladder.origin[2] = ladder.mins[2];
        ladders.PushArray(ladder, sizeof(ladder));

        entityStrLenMax = FormatMaxSize(entityStrLenMax, "%i", ladder.entity);
        hammeridStrLenMax = FormatMaxSize(hammeridStrLenMax, "%i", ladder.hammerid);
        modelStrLenMax = FormatMaxSizeString(modelStrLenMax, "%s", ladder.model);
        heightStrLenMax = FormatMaxSize(heightStrLenMax, "%0.1f", ladder.height);
        for (int i = 0; i < 3; i++)
        {
            minsStrLenMax[i] = FormatMaxSize(minsStrLenMax[i], "%0.1f", ladder.mins[i]);
            maxsStrLenMax[i] = FormatMaxSize(maxsStrLenMax[i], "%0.1f", ladder.maxs[i]);
            sizesStrLenMax[i] = FormatMaxSize(sizesStrLenMax[i], "%0.1f", ladder.sizes[i]);
            originStrLenMax[i] = FormatMaxSize(originStrLenMax[i], "%0.1f", ladder.origin[i]);
        }
    }

    if (ladders.Length == 0)
    {
        PrintToConsole(client, "No ladders found");
        delete ladders;

        return Plugin_Handled;
    }

    ladders.SortCustom(SortAscByHeight);

    char entityHeaderStrPad[12];
    char hammeridHeaderStrPad[12];
    char modelHeaderStrPad[12];
    char heightHeaderStrPad[14];
    char minsHeaderStrPad[42];
    char maxsHeaderStrPad[42];
    char sizesHeaderStrPad[42];
    char originHeaderStrPad[42];

    FormatPadString(entityHeaderStrPad, sizeof(entityHeaderStrPad), "%%%is", entityStrLenMax, HEADER_ENTITY);
    FormatPadString(hammeridHeaderStrPad, sizeof(hammeridHeaderStrPad), "%%%is", hammeridStrLenMax, HEADER_HAMMERID);
    FormatPadString(modelHeaderStrPad, sizeof(modelHeaderStrPad), "%%%is", modelStrLenMax, HEADER_MODEL);
    FormatPadString(heightHeaderStrPad, sizeof(heightHeaderStrPad), "%%%is", heightStrLenMax, HEADER_HEIGHT);
    FormatPadString(minsHeaderStrPad, sizeof(minsHeaderStrPad), "%%%is", minsStrLenMax[0] + 1 + minsStrLenMax[1] + 1 + minsStrLenMax[2], HEADER_MINS);
    FormatPadString(maxsHeaderStrPad, sizeof(maxsHeaderStrPad), "%%%is", maxsStrLenMax[0] + 1 + maxsStrLenMax[1] + 1 + maxsStrLenMax[2], HEADER_MAXS);
    FormatPadString(sizesHeaderStrPad, sizeof(sizesHeaderStrPad), "%%%is", sizesStrLenMax[0] + 1 + sizesStrLenMax[1] + 1 + sizesStrLenMax[2], HEADER_SIZES);
    FormatPadString(originHeaderStrPad, sizeof(originHeaderStrPad), "%%%is", originStrLenMax[0] + 1 + originStrLenMax[1] + 1 + originStrLenMax[2], HEADER_ORIGIN);

    char outputHeaderBuffer[250];
    FormatEx(outputHeaderBuffer, sizeof(outputHeaderBuffer), "| %s | %s | %s | %s | %s | %s | %s | %s |",
    entityHeaderStrPad, hammeridHeaderStrPad, modelHeaderStrPad, heightHeaderStrPad, minsHeaderStrPad, maxsHeaderStrPad, sizesHeaderStrPad, originHeaderStrPad);

    char separatorLine[250];
    FormatPadString(separatorLine, sizeof(separatorLine), "|%%%is|", strlen(outputHeaderBuffer)-2, "");
    ReplaceString(separatorLine, sizeof(separatorLine), " ", "-");

    PrintToConsole(client, "");
    PrintToConsole(client, separatorLine);
    PrintToConsole(client, outputHeaderBuffer);
    PrintToConsole(client, separatorLine);

    for (int ladderIndex = 0; ladderIndex < ladders.Length; ladderIndex++)
    {
        LadderInfo ladder;
        ladders.GetArray(ladderIndex, ladder, sizeof(ladder));

        char entityStrPad[12];
        char hammeridStrPad[12];
        char modelStrPad[12];
        char heightStrPad[14];
        char minsStrPad[3][14];
        char maxsStrPad[3][14];
        char sizesStrPad[3][14];
        char originStrPad[3][14];

        FormatPad(entityStrPad, sizeof(entityStrPad), "%%-%ii", entityStrLenMax, ladder.entity);
        FormatPad(hammeridStrPad, sizeof(hammeridStrPad), "%%%ii", hammeridStrLenMax, ladder.hammerid);
        FormatPadString(modelStrPad, sizeof(modelStrPad), "%%%is", modelStrLenMax, ladder.model);
        FormatPad(heightStrPad, sizeof(heightStrPad), "%%%i.1f", heightStrLenMax, ladder.height);
        for (int i = 0; i < 3; i++)
        {
            FormatPad(minsStrPad[i], sizeof(minsStrPad[]), "%%%i.1f", minsStrLenMax[i], ladder.mins[i]);
            FormatPad(maxsStrPad[i], sizeof(maxsStrPad[]), "%%%i.1f", maxsStrLenMax[i], ladder.maxs[i]);
            FormatPad(sizesStrPad[i], sizeof(sizesStrPad[]), "%%%i.1f", sizesStrLenMax[i], ladder.sizes[i]);
            FormatPad(originStrPad[i], sizeof(originStrPad[]), "%%%i.1f", originStrLenMax[i], ladder.origin[i]);
        }

        char outputBuffer[250];
        FormatEx(outputBuffer, sizeof(outputBuffer), "| %s | %s | %s | %s | %s %s %s | %s %s %s | %s %s %s | %s %s %s |",
        entityStrPad, hammeridStrPad, modelStrPad, heightStrPad, minsStrPad[0], minsStrPad[1], minsStrPad[2], maxsStrPad[0], maxsStrPad[1], maxsStrPad[2], sizesStrPad[0], sizesStrPad[1], sizesStrPad[2], originStrPad[0], originStrPad[1], originStrPad[2]);

        PrintToConsole(client, "%s", outputBuffer);
    }

    PrintToConsole(client, separatorLine);
    PrintToConsole(client, "");

    delete ladders;

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "-------------- Plugin Cvars (l4d_console_ladder_height) --------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "l4d_console_ladder_height_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "l4d_console_ladder_height_enable : %b (%s)", plugin.enable, plugin.enable ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
void FormatPad(char[] input, int maxlength, char[] format, int lenMax, any data)
{
    char buffer[250];
    FormatEx(buffer, sizeof(buffer), format, lenMax);
    FormatEx(input, maxlength, buffer, data);
}

/****************************************************************************************************/

void FormatPadString(char[] input, int maxlength, char[] format, int lenMax, char[] data)
{
    char buffer[250];
    FormatEx(buffer, sizeof(buffer), format, lenMax);
    FormatEx(input, maxlength, buffer, data);
}

/****************************************************************************************************/

int FormatMaxSize(int currentLen, char[] format, any data)
{
    char buffer[250];
    FormatEx(buffer, sizeof(buffer), format, data);
    int bufferLen = strlen(buffer);
    return (currentLen < bufferLen ? bufferLen : currentLen);
}

/****************************************************************************************************/

int FormatMaxSizeString(int currentLen, char[] format, char[] data)
{
    char buffer[250];
    FormatEx(buffer, sizeof(buffer), format, data);
    int bufferLen = strlen(buffer);
    return (currentLen < bufferLen ? bufferLen : currentLen);
}