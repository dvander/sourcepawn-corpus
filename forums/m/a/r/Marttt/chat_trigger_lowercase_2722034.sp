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
#define PLUGIN_DESCRIPTION            "Automatically converts chat triggers to lowercase"
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
ConVar g_hCvar_Enabled;

// ====================================================================================================
// bool - Plugin Variables
// ====================================================================================================
bool g_bConfigsExecuted;
bool g_bCvar_Enabled;

// ====================================================================================================
// string - Plugin Variables
// ====================================================================================================
char g_sChatInput[128];

// ====================================================================================================
// ArrayList - Plugin Variables
// ====================================================================================================
ArrayList g_alChatTrigger;

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public void OnPluginStart()
{
    g_alChatTrigger = new ArrayList();

    ParseCoreConfigFile();

    CreateConVar("chat_trigger_lowercase_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled = CreateConVar("chat_trigger_lowercase_enable", "1", "Enable/Disable the plugin.\n0 = Disable, 1 = Enable.", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_chat_trigger_lowercase_reload", CmdReload, ADMFLAG_ROOT, "Reload the chat triggers config.");
    RegAdminCmd("sm_print_cvars_chat_trigger_lowercase", CmdPrintCvars, ADMFLAG_ROOT, "Print the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnMapStart()
{
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
}

/****************************************************************************************************/

void Event_ConVarChanged(ConVar convar, const char[] oldValue, const char[] newValue)
{
    GetCvars();
}

/****************************************************************************************************/

void GetCvars()
{
    g_bCvar_Enabled = g_hCvar_Enabled.BoolValue;
}

/****************************************************************************************************/

public Action OnClientSayCommand(int client, const char[] command, const char[] sArgs)
{
    if (!g_bCvar_Enabled)
        return Plugin_Continue;

    if (!IsChatTriggerPrefix(sArgs[0]))
        return Plugin_Continue;

    strcopy(g_sChatInput, sizeof(g_sChatInput), sArgs);
    StringToLowerCase(g_sChatInput);

    if (StrEqual(g_sChatInput, sArgs))
        return Plugin_Continue;

    FakeClientCommandEx(client, "%s %s", command, g_sChatInput);

    return Plugin_Stop;
}

/****************************************************************************************************/

void ParseCoreConfigFile()
{
    char path[PLATFORM_MAX_PATH];
    BuildPath(Path_SM, path, sizeof(path), CONFIGS_CORE_FILENAME);

    if (!FileExists(path))
    {
        SetFailState("Missing required config file on \"%s\", please re-download.", CONFIGS_CORE_FILENAME);
        return;
    }

    int line;
    int col;

    g_alChatTrigger.Clear();

    SMCParser parser = new SMCParser();
    SMC_SetReaders(parser, INVALID_FUNCTION, CoreConfig_KeyValue, INVALID_FUNCTION);
    SMCError result = parser.ParseFile(path, line, col);
    delete parser;

    if (result != SMCError_Okay)
    {
        char error[128];
        SMC_GetErrorString(result, error, sizeof(error));
        SetFailState("%s on line %i, col %i of %s [%i]", error, line, col, path, result);
    }
}

/****************************************************************************************************/

SMCResult CoreConfig_KeyValue(Handle parser, const char[] key, const char[] value, bool key_quotes, bool value_quotes)
{
    if (StrEqual(key, "PublicChatTrigger") || StrEqual(key, "SilentChatTrigger"))
    {
        for (int i = 0; i < strlen(value); i++)
        {
            if (g_alChatTrigger.FindValue(value[i]) == -1)
                g_alChatTrigger.Push(value[i]);
        }
    }

    return SMCParse_Continue;
}

/****************************************************************************************************/

bool IsChatTriggerPrefix(int ascii)
{
    return (g_alChatTrigger.FindValue(ascii) != -1);
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdReload(int client, int args)
{
    ParseCoreConfigFile();

    if (IsValidClient(client))
        PrintToChat(client, "\x04[Chat triggers config reloaded]");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------- Plugin Cvars (chat_trigger_lowercase) ----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "chat_trigger_lowercase_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "chat_trigger_lowercase_enable : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "--------------------------- Chat Triggers ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "count : %i", g_alChatTrigger.Length);
    char chattrigger[2];
    for (int i = 0; i < g_alChatTrigger.Length; i++)
    {
        g_alChatTrigger.GetString(i, chattrigger, sizeof(chattrigger));
        PrintToConsole(client, "%s", chattrigger);
    }
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
 * @param client        Client index.
 * @return              True if client index is valid, false otherwise.
 */
bool IsValidClientIndex(int client)
{
    return (1 <= client <= MaxClients);
}

/****************************************************************************************************/

/**
 * Validates if is a valid client.
 *
 * @param client        Client index.
 * @return              True if client index is valid and client is in game, false otherwise.
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