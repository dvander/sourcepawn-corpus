/**
// ====================================================================================================
Change Log:

1.0.0 (20-October-2020)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[ANY] Chat Trigger to Lower Case"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Auto converts chat triggers to lower case"
#define PLUGIN_VERSION                "1.0.0"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=328004"

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
#define CONFIG_FILENAME               "chat_trigger_lowercase"
#define CONFIGS_CORE_FILENAME         "configs/core.cfg"

// ====================================================================================================
// Plugin Cvars
// ====================================================================================================
static ConVar g_hCvar_Enabled;
static ConVar g_hCvar_Trim;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
static bool   g_bConfigLoaded;
static bool   g_bCvar_Enabled;
static bool   g_bCvar_Trim;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
static char g_sChatTriggerPrefix[2][32];

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public void OnPluginStart()
{
    CreateConVar("chat_trigger_lowercase_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("chat_trigger_lowercase_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_Trim    = CreateConVar("chat_trigger_lowercase_trim", "1", "Trim (remove whitespaces) the text when it starts with a chat trigger.\n0 = OFF, 1 = ON.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Trim.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    ParseCoreConfigFile();

    // Admin Commands
    RegAdminCmd("sm_print_cvars_chat_trigger_lowercase", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
    GetCvars();
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
    g_bCvar_Trim = g_hCvar_Trim.BoolValue;

    g_bConfigLoaded = true;
}

/****************************************************************************************************/

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if (!g_bConfigLoaded)
        return Plugin_Continue;

    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    char input[128];
    strcopy(input, sizeof(input), sArgs);

    if (g_bCvar_Trim)
        TrimString(input);

    if (IsPrefix(input[0]))
        StringToLowerCase(input);

    if (StrEqual(input, sArgs))
        return Plugin_Continue;

    FakeClientCommandEx(client, "%s %s", command, input);
    return Plugin_Stop;
}

// ====================================================================================================
// Thanks to Silvers and Dragokas
// ====================================================================================================
bool ParseCoreConfigFile()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), CONFIGS_CORE_FILENAME);

    SMCParser parser = new SMCParser();
    SMC_SetReaders(parser, INVALID_FUNCTION, CoreConfig_KeyValue, INVALID_FUNCTION);

    int line = 0;
    int col = 0;
    SMCError result = parser.ParseFile(path, line, col);
    delete parser;

    if (result != SMCError_Okay)
    {
        char error[128];
        SMC_GetErrorString(result, error, sizeof error);
        SetFailState("%s on line %i, col %i of %s [%i]", error, line, col, path, result);
    }
    return (result == SMCError_Okay);
}

/****************************************************************************************************/

public SMCResult CoreConfig_KeyValue(Handle parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
    if (StrEqual(key, "PublicChatTrigger"))
    {
        strcopy(g_sChatTriggerPrefix[0], sizeof(g_sChatTriggerPrefix[]), value);
        return SMCParse_Continue;
    }

    if (StrEqual(key, "SilentChatTrigger"))
    {
        strcopy(g_sChatTriggerPrefix[1], sizeof(g_sChatTriggerPrefix[]), value);
        return SMCParse_Continue;
    }
    return SMCParse_Continue;
}

/****************************************************************************************************/

bool IsPrefix(int ascii)
{
    for (int i = 0; i < sizeof(g_sChatTriggerPrefix); i++)
    {
        for (int c = 0; c < sizeof(g_sChatTriggerPrefix[]); c++)
        {
            if (ascii == g_sChatTriggerPrefix[i][c])
                return true;
        }
    }
    return false;
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
public Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (chat_trigger_lowercase) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "chat_trigger_lowercase_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "chat_trigger_lowercase_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "chat_trigger_lowercase_trim : %b (%s)", g_bCvar_Trim, g_bCvar_Trim ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");

    return Plugin_Handled;
}

// ====================================================================================================
// Helpers
// ====================================================================================================
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