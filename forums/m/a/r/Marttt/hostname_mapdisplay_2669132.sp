/**
// ====================================================================================================
Change Log:

1.0.2 (16-March-2021)
    - Fixed missing valid client check on reload command.

1.0.1 (20-November-2019)
    - Added support to {gamemode} and {GAMEMODE} tags. {GAMEMODE} will upper case the gamemode string. (e.g.: coop => COOP)
    - Updated the structure of the KeyValue file located at data folder.
    - Added "hostname" and "format" configs through a new section ("Host") in the KeyValue file to support Unicode texts (thanks to "water19753" for the report).

1.0.0 (07-October-2019)
    - Initial release.

// ====================================================================================================
*/

// ====================================================================================================
// Plugin Info - define
// ====================================================================================================
#define PLUGIN_NAME                   "[ANY] Hostname - Display Map Name"
#define PLUGIN_AUTHOR                 "Mart"
#define PLUGIN_DESCRIPTION            "Displays the specified map name in the hostname."
#define PLUGIN_VERSION                "1.0.1"
#define PLUGIN_URL                    "https://forums.alliedmods.net/showthread.php?t=319046"

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
#define CONFIG_FILENAME               "hostname_mapdisplay"

// ====================================================================================================
// Defines
// ====================================================================================================
#define KEYVALUE_FILENAME            "hostname_mapdisplay"
#define KEYVALUE_ROOTNAME            "Settings"
#define KEYVALUE_MAP                 "Map"
#define KEYVALUE_HOST                "Host"
#define KEYVALUE_HOST_HOSTNAME       "hostname"
#define KEYVALUE_HOST_FORMAT         "format"

// ====================================================================================================
// Plugin Cvar Handles
// ====================================================================================================
ConVar g_hCvar_MPGameMode;
ConVar g_hCvar_Enabled;
ConVar g_hCvar_HostName;
ConVar g_hCvar_HostNameFormat;
ConVar g_hCvar_MapNotFound;

// ====================================================================================================
// bool - Plugin Cvar Variables
// ====================================================================================================
bool g_bCvar_Enabled;
bool g_bCvar_MapNotFound;
bool g_bUseHostName_txt;
bool g_bUseHostNameFormat_txt;

// ====================================================================================================
// string - Plugin Cvar Variables
// ====================================================================================================
char g_sCvar_DefaultHostName[256];
char g_sCvar_CurrentGameMode[256];
char g_sCvar_CurrentGameModeUpper[256];
char g_sCvar_HostName[256];
char g_sCvar_HostNameFormat[256];
char g_sHostName_txt[256];
char g_sHostNameFormat_txt[256];
char g_sNewHostName[256];
char g_sMapDevName[256];
char g_sMapName[256];
char g_sDataPath[PLATFORM_MAX_PATH];

// ====================================================================================================
// Plugin Start
// ====================================================================================================
public void OnPluginStart()
{
    BuildPath(Path_SM, g_sDataPath, PLATFORM_MAX_PATH, "data/%s.txt", KEYVALUE_FILENAME);

    GetConVarString(FindConVar("hostname"), g_sCvar_DefaultHostName, sizeof(g_sCvar_DefaultHostName));
    g_hCvar_MPGameMode = FindConVar("mp_gamemode");

    CreateConVar("hostname_mapdisplay_version", PLUGIN_VERSION, PLUGIN_DESCRIPTION, CVAR_FLAGS_PLUGIN_VERSION);
    g_hCvar_Enabled        = CreateConVar("hostname_mapdisplay_enabled", "1", "Enables/Disables the plugin. 0 = Plugin OFF, 1 = Plugin ON.", CVAR_FLAGS, true, 0.0, true, 1.0);
    g_hCvar_HostName       = CreateConVar("hostname_mapdisplay_hostname", g_sCvar_DefaultHostName, "Hostname used by the {hostname} tag.\nNote: If the \"hostname\" attribute is set in the KeyValue file located at data folder, this cvar will be ignored.", CVAR_FLAGS);
    g_hCvar_HostNameFormat = CreateConVar("hostname_mapdisplay_format", "{hostname} | {GAMEMODE} | {mapname}", "Display format.\nAvailable tags: {hostname},{mapname},{gamemode},{GAMEMODE}\nNote: If the \"format\" attribute is set in the KeyValue file located at data folder, this cvar will be ignored.", CVAR_FLAGS);
    g_hCvar_MapNotFound    = CreateConVar("hostname_mapdisplay_mapnotfound", "0", "Enables/Disables the plugin when the map is not found in the KeyValue file located at data folder. 0 = OFF, 1 = ON (shows the map dev name).", CVAR_FLAGS, true, 0.0, true, 1.0);

    // Hook plugin ConVars change
    g_hCvar_MPGameMode.AddChangeHook(Event_ConVarChanged);
    g_hCvar_Enabled.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HostName.AddChangeHook(Event_ConVarChanged);
    g_hCvar_HostNameFormat.AddChangeHook(Event_ConVarChanged);
    g_hCvar_MapNotFound.AddChangeHook(Event_ConVarChanged);

    // Load plugin configs from .cfg
    AutoExecConfig(true, CONFIG_FILENAME);

    // Admin Commands
    RegAdminCmd("sm_hostname_mapdisplay_reload", CmdReload, ADMFLAG_ROOT, "Reloads the hostname based on a KeyValue file located at data folder.");
    RegAdminCmd("sm_print_cvars_hostname_mapdisplay", CmdPrintCvars, ADMFLAG_ROOT, "Prints the plugin related cvars and their respective values to the console.");
}

/****************************************************************************************************/

public void OnConfigsExecuted()
{
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
    g_hCvar_MPGameMode.GetString(g_sCvar_CurrentGameMode, sizeof(g_sCvar_CurrentGameMode));
    TrimString(g_sCvar_CurrentGameMode);
    String_ToUpper(g_sCvar_CurrentGameMode, g_sCvar_CurrentGameModeUpper, sizeof(g_sCvar_CurrentGameModeUpper));
    GetCurrentMap(g_sMapDevName, sizeof(g_sMapDevName));

    g_bCvar_Enabled = GetConVarBool(g_hCvar_Enabled);
    GetConVarString(g_hCvar_HostName, g_sCvar_HostName, sizeof(g_sCvar_HostName));
    TrimString(g_sCvar_HostName);
    GetConVarString(g_hCvar_HostNameFormat, g_sCvar_HostNameFormat, sizeof(g_sCvar_HostNameFormat));
    TrimString(g_sCvar_HostNameFormat);
    g_bCvar_MapNotFound = GetConVarBool(g_hCvar_MapNotFound);

    ChangeHostName();
}

/****************************************************************************************************/
void ChangeHostName()
{
    KeyValues kv = new KeyValues(KEYVALUE_ROOTNAME);
    kv.ImportFromFile(g_sDataPath);

    kv.JumpToKey(KEYVALUE_HOST);
    kv.GetString(KEYVALUE_HOST_HOSTNAME, g_sHostName_txt, sizeof(g_sHostName_txt));
    TrimString(g_sHostName_txt);
    kv.GetString(KEYVALUE_HOST_FORMAT, g_sHostNameFormat_txt, sizeof(g_sHostNameFormat_txt));
    TrimString(g_sHostNameFormat_txt);
    kv.GoBack();

    kv.JumpToKey(KEYVALUE_MAP);
    kv.GetString(g_sMapDevName, g_sMapName, sizeof(g_sMapName));
    delete kv;

    g_bUseHostName_txt = (g_sHostName_txt[0] != 0);
    g_bUseHostNameFormat_txt = (g_sHostNameFormat_txt[0] != 0);
    strcopy(g_sNewHostName, sizeof(g_sNewHostName), g_bUseHostNameFormat_txt ? g_sHostNameFormat_txt : g_sCvar_HostNameFormat);

    if (g_sMapName[0] != 0)
    {
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{hostname}", g_bUseHostName_txt ? g_sHostName_txt : g_sCvar_HostName, false);
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{mapname}", g_sMapName, false);
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{GAMEMODE}", g_sCvar_CurrentGameModeUpper, true);
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{gamemode}", g_sCvar_CurrentGameMode, false);
        ServerCommand("hostname %s", g_sNewHostName);
        return;
    }
    else if (g_bCvar_MapNotFound)
    {
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{hostname}", g_bUseHostName_txt ? g_sHostName_txt : g_sCvar_HostName, false);
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{mapname}", g_sMapDevName, false);
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{GAMEMODE}", g_sCvar_CurrentGameModeUpper, true);
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{gamemode}", g_sCvar_CurrentGameMode, false);
        ServerCommand("hostname %s", g_sNewHostName);
        return;
    }
    else
    {
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{hostname}", g_bUseHostName_txt ? g_sHostName_txt : g_sCvar_HostName, false);
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{mapname}", "", false);
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{GAMEMODE}", g_sCvar_CurrentGameModeUpper, true);
        ReplaceString(g_sNewHostName, sizeof(g_sNewHostName), "{gamemode}", g_sCvar_CurrentGameMode, false);
        ServerCommand("hostname %s", g_sNewHostName);
        return;
    }
}

// ====================================================================================================
// Admin Commands
// ====================================================================================================
Action CmdReload(int client, int args)
{
    ChangeHostName();

    if (IsValidClient(client))
        PrintToChat(client, "*hostname_mapdisplay* KeyValue file reloaded.");

    return Plugin_Handled;
}

/****************************************************************************************************/

Action CmdPrintCvars(int client, int args)
{
    char g_sHostnameNow[256];
    GetConVarString(FindConVar("hostname"), g_sHostnameNow, sizeof(g_sHostnameNow));

    PrintToConsole(client, "");
    PrintToConsole(client, "======================================================================");
    PrintToConsole(client, "");
    PrintToConsole(client, "----------------- Plugin Cvars (hostname_mapdisplay) -----------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "hostname_mapdisplay_version : %s", PLUGIN_VERSION);
    PrintToConsole(client, "hostname_mapdisplay_enabled : %b (%s)", g_bCvar_Enabled, g_bCvar_Enabled ? "true" : "false");
    PrintToConsole(client, "hostname_mapdisplay_hostname : %s %s", g_sCvar_HostName, g_bUseHostName_txt ? "<ignored because of txt file>" : "");
    PrintToConsole(client, "hostname_mapdisplay_format : %s %s", g_sCvar_HostNameFormat, g_bUseHostNameFormat_txt ? "<ignored because of txt file>" : "");
    PrintToConsole(client, "hostname_mapdisplay_mapnotfound : %b (%s)", g_bCvar_MapNotFound, g_bCvar_MapNotFound ? "true" : "false");
    PrintToConsole(client, "");
    PrintToConsole(client, "---------------------------- Other Infos  ----------------------------");
    PrintToConsole(client, "");
    PrintToConsole(client, "mp_gamemode : %s", g_sCvar_CurrentGameMode);
    PrintToConsole(client, "Map : %s", g_sMapDevName);
    PrintToConsole(client, "Map name (txt) : %s", g_sMapName[0] == '\0' ? "<not found>" : g_sMapName);
    PrintToConsole(client, "Using txt hostname? : %b (%s)", g_bUseHostName_txt, g_bUseHostName_txt ? "true" : "false");
    PrintToConsole(client, "Hostname (txt) : %s", g_sHostName_txt[0] == '\0' ? "<empty>" : g_sHostName_txt);
    PrintToConsole(client, "Using txt hostname format? : %b (%s)", g_bUseHostNameFormat_txt, g_bUseHostNameFormat_txt ? "true" : "false");
    PrintToConsole(client, "Format (txt) : %s", g_sHostNameFormat_txt[0] == '\0' ? "<empty>" : g_sHostNameFormat_txt);
    PrintToConsole(client, "");
    PrintToConsole(client, "Hostname displaying as : %s", g_sHostnameNow);
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

// Code snippet from SMLIB
/**
 * Converts the whole String to upper case.
 * Only works with alphabetical characters (not öäü) because Sourcemod suxx !
 * The Output String can be the same as the Input String.
 *
 * @param input                Input String.
 * @param output            Output String.
 * @param size                Max Size of the Output String
 * @noreturn
 */
stock void String_ToUpper(const char[] input, char[] output, int size)
{
    size--;

    int i = 0;
    while (input[i] != '\0' && i < size) {
        output[i] = CharToUpper(input[i]);
        i++;
    }

    output[i] = '\0';
}